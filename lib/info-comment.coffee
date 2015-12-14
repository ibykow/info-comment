{CompositeDisposable} = require 'atom'
{Range} = require 'text-buffer'
_ = require 'underscore-plus'
{OnigRegExp} = require 'oniguruma'

module.exports =
  languages: [
    "ActionScript",
    "AutoHotkey",
    "C",
    "C++",
    "C#",
    "D",
    "Go",
    "Java",
    "JavaScript",
    "Objective-C",
    "PHP",
    "PL/I",
    "Rust",
    "Scala",
    "SASS",
    "SQL",
    "Swift",
    "Visual Prolog",
    "CSS"
  ]
  config:
    languages:
      type: 'array'
      default: ["Your language", "Another language"]
      items:
        type: 'string'
    midString:
      type: 'string'
      default: ' * '
    leaveTopBlank:
      type: 'boolean'
      default: true

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'info-comment:toggle': => @toggle()

  deactivate: ->
    @subscriptions.dispose()

  toggle: ->
    editor = atom.workspace.getActiveTextEditor()

    return unless editor?

    @languages = @languages.concat atom.config.get('info-comment.languages')
    grammar = editor.getGrammar().name

    if grammar not in @languages
      console.log grammar, "does not use '/* */' block comments as far as we know"
      console.log "If you want to use it anyway, add your language to the config"
      console.log "Supported languages:", @languages...
      return      

    selection = editor.getLastSelection()
    [startRow, endRow] = selection.getBufferRowRange()

    startString = '/* '
    midString = atom.config.get('info-comment.midString') ? ' * '
    endString = ' */'

    buffer = editor.buffer

    [startRegex, midRegex] = init(startString, midString)

    commentState = [buffer, startRegex, midRegex, endString, startRow, endRow]
    uncommentState = [editor, buffer, startString, startRegex, midString,
      midRegex, endString, startRow, endRow]

    shouldUncomment = startRegex.testSync(buffer.lineForRow(startRow))

    if shouldUncomment then uncomment(commentState) else comment(uncommentState)


getIndentLengthForBufferRow = (buffer, row, regex) ->
  buffer.lineForRow(row).match(regex)?[0].length

insertToBufferRowAtIndent = (buffer, row, string, indentString, indentRegex) ->
  indentLength = getIndentLengthForBufferRow(buffer, row, indentRegex)
  if indentLength
    buffer.insert([row, indentLength], string)
  else
    buffer.setTextInRange([[row, 0], [row, indentString.length]],
      indentString + string)

clearBufferRow = (buffer, row) ->
  buffer.setTextInRange([[row, 0], [row, buffer.lineLengthForRow(row)]], '')

init = (startString, midString) ->
  # Prepare start and mid regexs
  commentStartRegexString =
    _.escapeRegExp(startString).replace(/(\s+)$/, '(?:$1)?')
  commentStartRegex = new OnigRegExp("^(\\s*)(#{commentStartRegexString})")
  commentMidRegexString =
    _.escapeRegExp(midString).replace(/(\s+)$/, '(?:$1)?')
  commentMidRegex = new OnigRegExp("^(\\s*)(#{commentMidRegexString})")
  [commentStartRegex, commentMidRegex]

uncomment = (commentState) ->
  [buffer, startRegex, midRegex, endString, startRow, endRow] = commentState

  commentEndRegexString =
    _.escapeRegExp(endString).replace(/^(\s+)/, '(?:$1)?')

  commentEndRegex = new OnigRegExp("(#{commentEndRegexString})(\\s*)$")

  startMatch = startRegex.searchSync(buffer.lineForRow(startRow))
  endMatch = commentEndRegex.searchSync(buffer.lineForRow(endRow))

  if not endMatch
    endRow++
    endMatch = commentEndRegex.searchSync(buffer.lineForRow(endRow))

  if startMatch and endMatch
    # Deal with single row selections
    if startMatch is endMatch
      buffer.transact ->
        columnStart = startMatch[1].length
        columnEnd = columnStart + startMatch[2].length
        buffer.setTextInRange([[startRow, columnStart],
          [startRow, columnEnd]], "")

        endLength = buffer.lineLengthForRow(endRow) - endMatch[2].length
        endColumn = endLength - endMatch[1].length
        buffer.setTextInRange([[endRow, endColumn],
          [endRow, endLength]], "")
      return

    # Deal with multi-row selections
    buffer.transact ->
      # Remove the startString
      columnStart = startMatch[1].length
      columnEnd = columnStart + startMatch[2].length

      buffer.setTextInRange([[startRow, columnStart],
        [startRow, columnEnd]], "")

      # Trim or delete the startRow if blank
      if buffer.isRowBlank(startRow)
        if atom.config.get('info-comment.leaveTopBlank')
          buffer.deleteRow(startRow)
          startRow--
          endRow--
        else
          clearBufferRow(buffer, startRow)

      # Remove the endString
      endLength = buffer.lineLengthForRow(endRow) - endMatch[2].length
      endColumn = endLength - endMatch[1].length

      buffer.setTextInRange([[endRow, endColumn], [endRow, endLength]], "")

      if buffer.isRowBlank(endRow)
        buffer.deleteRow(endRow)

      # Remove midStrings
      for row in [startRow + 1..endRow - 1] by 1
        if match = midRegex.searchSync(buffer.lineForRow(row))
          columnStart = match[1].length
          columnEnd = columnStart + match[2].length
          buffer.setTextInRange([[row, columnStart], [row, columnEnd]], '')
          if buffer.isRowBlank(row)
              clearBufferRow(buffer, row)

comment = (uncommentState) ->
  [editor, buffer, startString, startRegex, midString, midRegex, endString,
    startRow, endRow] = uncommentState

  # Deal with single row comments
  if startRow is endRow
    buffer.transact ->
      indentLength = getIndentLengthForBufferRow(buffer, startRow, /^\s*/)
      buffer.insert([startRow, indentLength], startString)
      buffer.insert([endRow, buffer.lineLengthForRow(endRow)],
        endString)
    return

  # Prepare indentString and indentRegex
  indent = editor.languageMode.minIndentLevelForRowRange(startRow, endRow)
  indentString = editor.buildIndentString(indent)
  tabLength = editor.getTabLength()
  indentRegex = new RegExp("(\t|[ ]{#{tabLength}}){#{Math.floor(indent)}}")

  # Set the comment
  buffer.transact ->
    # Deal with the first line
    if atom.config.get('info-comment.leaveTopBlank')
      buffer.insert([startRow, 0], '\n')
      buffer.setTextInRange([[startRow, 0],
        [startRow, indentString.length]], indentString + startString)
      endRow++
    else
      insertToBufferRowAtIndent(buffer, startRow, startString,
        indentString, indentRegex)

    endRow++

    # Deal with the last line
    buffer.insert([endRow, 0], '\n')
    buffer.setTextInRange([[endRow, 0],
      [endRow, indentString.length]], indentString + endString)

    # Deal with the remaining lines
    for row in [startRow + 1..endRow - 1] by 1
      insertToBufferRowAtIndent(buffer, row, midString, indentString,
        indentRegex)
