_ = require 'underscore-plus'
{OnigRegExp} = require 'oniguruma'


# Module

module.exports =
  # Prepare start and mid regexs
  init: (startString, midString) ->
    commentStartRegexString =
      _.escapeRegExp(startString).replace(/(\s+)$/, '(?:$1)?')

    commentStartRegex = new OnigRegExp("^(\\s*)(#{commentStartRegexString})")

    commentMidRegexString =
      _.escapeRegExp(midString).replace(/(\s+)$/, '(?:$1)?')

    commentMidRegex = new OnigRegExp("^(\\s*)(#{commentMidRegexString})")

    return [commentStartRegex, commentMidRegex]


  # Uncomment a selection
  uncomment: (commentState) ->
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

  # Comment the selection
  comment: (uncommentState) ->
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


# Utility Functions

# Returns the indentation length for the current buffer
getIndentLengthForBufferRow = (buffer, row, regex) ->
  buffer.lineForRow(row).match(regex)?[0].length

# Insert a string into the buffer at the current row
insertToBufferRowAtIndent = (buffer, row, string, indentString, indentRegex) ->
  indentLength = getIndentLengthForBufferRow(buffer, row, indentRegex)
  if indentLength
    buffer.insert([row, indentLength], string)
  else
    buffer.setTextInRange([[row, 0], [row, indentString.length]],
    indentString + string)


# Clear the buffer
clearBufferRow = (buffer, row) ->
  buffer.setTextInRange([[row, 0], [row, buffer.lineLengthForRow(row)]], '')
