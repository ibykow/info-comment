u = require './info-comment-util'
{CompositeDisposable} = require 'atom'

module.exports =
  subscriptions: null

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
    leaveTopBlank:
      default: true
      type: 'boolean'
    midString:
      type: 'string'
      default: ' * '

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

    [startRegex, midRegex] = u.init(startString, midString)

    commentState = [buffer, startRegex, midRegex, endString, startRow, endRow]
    uncommentState = [editor, buffer, startString, startRegex, midString,
      midRegex, endString, startRow, endRow]

    shouldUncomment = startRegex.testSync(buffer.lineForRow(startRow))

    if shouldUncomment then u.uncomment(commentState)
    else u.comment(uncommentState)
