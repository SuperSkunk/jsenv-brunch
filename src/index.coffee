_ = require 'lodash'
vm = require 'vm'
Module = require("module").Module
coffee = require 'coffee-script'
sysPath = require 'path'

module.exports = class JsenvCompiler
  brunchPlugin: yes
  type: 'javascript'
  pattern: /\.(js|coffee)env$/

  constructor: (@config) ->
    null

  compile: (data, path, callback) ->

    # don't mess with the global var
    vars = _.clone process.env

    # add extra data from brunch configuration
    if @config.plugins?.jsenv?.data?
      _.merge vars, @config.plugins.jsenv.data

    try
      if sysPath.extname(path) == '.coffeeenv'
        data = coffee.compile(data, bare: yes)

      parsed = vm.runInNewContext(
        "module.exports = #{data}",
        @generateSandbox(),
        path
      )

      if typeof parsed == "function"
        envHash = parsed(vars)
      else
        envHash = parsed
        for key of envHash when vars[key]
          envHash[key] = vars[key]

      result =  "module.exports = " + JSON.stringify(envHash)

    catch err
      error = err
    finally
      callback error, result

  # generate the sandboxed context for the generated code
  generateSandbox: ->

    # take the path from the plugin configuration or take the app root.
    rootOfContext = @config.plugins.jsenv.rootOfContext ? @config.paths.root

    sandbox =
      module:
        exports: undefined
      require: (filepath) =>
        path = sysPath.resolve sysPath.join(rootOfContext, filepath)
        require path
