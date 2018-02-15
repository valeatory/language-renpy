
path = require 'path'
fs = require 'fs'
cp = require 'child_process'

is_busy = false
navigation_data = null

sample_suggestion =
  text: 'Sample Suggestion: ok' # OR
  #snippet: 'someText(${1:myArg})'
  displayText: 'Sample Suggestion' # (optional)
  #replacementPrefix: 'renpy' # (optional)
  type: 'value' # (optional)
  #leftLabel: '' # (optional)
  #leftLabelHTML: '' # (optional)
  #rightLabel: '' # (optional)
  #rightLabelHTML: '' # (optional)
  #className: '' # (optional)
  #iconHTML: '' # (optional)
  description: 'Just a sample suggestion' # (optional)
  #descriptionMoreURL: '' # (optional)
  #characterMatchIndices: [0, 1, 2] # (optional)

get_sample = (prefix) ->
  if prefix == 'renpy' then sample_suggestion else []

get_labels = (prefix) ->
  suggestions = []
  if prefix.startsWith('call') or prefix.startsWith('jump')
    cmd = if prefix.startsWith('call') then 'call ' else 'jump '
    labels = navigation_data.location.label
    console.log labels
    for label in Object.keys(labels)
      suggestions.push(
        text: cmd+label
        displayText: label
        rightLabel: 'Label at: '+labels[label][0]+':'+labels[label][1]
        iconHTML: '<i class="icon-tag"></i>'
        type: 'tag'
      )
  console.info suggestions
  return suggestions

generate_navigation = (project) ->
  is_busy = true
  renpy = renpy_executable()
  if renpy
    proj = atom.config.get('language-renpy.projectsPath')
    dest = path.join(path.dirname(renpy), 'tmp', project, 'navigation.json')
    if not fs.existsSync(path.dirname(dest))
      fs.mkdirSync(path.dirname(dest)) # TODO: add mkdir recursive
    cmd = ['--json-dump', dest, path.join(proj, project), 'quit']
    console.log cmd
    ex = cp.execFile(renpy, cmd, (error, stdout, stderr) ->
      unless stderr
        navigation_data = require dest
        console.log navigation_data
        is_busy = false
    )
  else
    is_busy = false

update_projects_path = ->
  is_busy = true
  console.log 'Updating projects path'
  atom.notifications.addInfo('Looking for projects directory...')
  renpy = renpy_executable()
  if renpy
    cmd = [path.dirname(renpy), 'get_projects_directory']
    ex = cp.execFile(renpy, cmd, (error, stdout, stderr) ->
      unless stderr
        atom.config.set('language-renpy.projectsPath', stdout.trim())
        atom.notifications.addSuccess('Projects directory found: '+stdout.trim())
        is_busy = false
    )
  else
    is_busy = false

renpy_executable = ->
  renpy = atom.config.get('language-renpy.renpyExecutable')
  if fs.existsSync renpy
    return renpy
  atom.notifications.addError('Ren\'Py Executable was not found/defined.')
  return false

module.exports =
  selector: '.source.renpy'
  disableForSelector: '.source.renpy .comment'
  #inclusionPriority: 1
  #excludeLowerPriority: true
  suggestionPriority: 2
  #filterSuggestions: true

  getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix, activatedManually}) ->
    new Promise (resolve) ->
      suggestions = []
      if not is_busy
        if atom.config.get('language-renpy.useAutocompleteProvider')
          if atom.config.get('language-renpy.projectsPath') == ''
            update_projects_path()
          else if navigation_data == null
            generate_navigation("tutorial") # hard-coded yet
          else
            suggestions = suggestions.concat(
              get_sample(prefix), # debug stuff
              get_labels(prefix)
            )
      resolve(suggestions)