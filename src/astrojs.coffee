fs        = require 'fs'
fd        = require 'path'
{spawn}   = require 'child_process'

cs        = require 'coffee-script'
strata    = require 'strata'
optimist  = require 'optimist'
UglifyJS  = require 'uglify-js'
groc      = require 'groc'

Template  = require './template'
ansi      = require './ansi'


argv = optimist.usage([
  '  usage: astrojs COMMAND',
  '    new      create a new astrojs project template',
  '    class    generate a class template and associated test template',
  '    server   start a local development server',
  '    build    build the module (this is an alias for `cake build`)'
].join("\n"))
.alias('p', 'port')
.alias('m', 'minify')
.argv

help = ->
  optimist.showHelp()
  process.exit()
  
class AstroJS
  @exec: (command) ->
    (new @).exec(command)
  
  @expandPath: (path, dir) ->
    path = dir + path if fd.basename(path) is path
    fd.normalize path
  
  @camelize: (str) ->
      str.replace(/-|_+(.)?/g, (match, chr) ->
        (if chr then chr.toUpperCase() else "")
      ).replace /^(.)?/, (match, chr) ->
        (if chr then chr.toUpperCase() else "")
  
  # Check if in project directory
  @inProjectDirectory: ->
    files = ['index.js', 'package.json', 'src', 'lib']
    root = process.cwd()
    for f in files
      unless fs.existsSync(fd.join(root, f))
        console.log ansi('\tastrojs must be run from within a project directory', 'red')
        return false
    return true
  
  # Get the project name from package.json.  It is assumed this function is called from a project
  # directory.
  @getProjectName: ->
    packagePath = fd.join(process.cwd(), "package")
    metadata = require(packagePath)
    return metadata["name"]
  
  @getDependencies: ->
    metadata = require(packagePath)
  
  # Generate a new project template
  new: (name) ->
    template = __dirname + "/../templates/module"
    values =
      name: AstroJS.camelize fd.basename(name)
      
    name = fd.normalize(name)

    # Create parent dir
    throw (name + " already exists") if fs.existsSync(name)
    fs.mkdirSync name, 0o0775
    (new Template(template, name, values)).write()

    # Rename module.coffee to the package name
    main = fd.join(name, "src", "main.coffee")
    proj = fd.join(name, "src", values.name + ".coffee")
    fs.rename main, proj
  
  klass: (name) ->
    template = fd.join(__dirname, '..', 'templates', 'class.coffee')
    project = AstroJS.getProjectName()
    values =
      name: AstroJS.camelize(fd.basename(name))
      project: project
    path = fd.join('src', "#{name}.coffee")
    (new Template(template, path, values)).write()
    @klassSpec(project, name)
  
  klassSpec: (project, name) ->
    return unless fs.existsSync(fd.join('test', 'specs'))
    template = fd.join(__dirname, '..', 'templates', 'spec.class.coffee')
    values =
      name: AstroJS.camelize(fd.basename(name))
      project: project
    path = fd.join('test', 'specs', "#{name}.coffee")
    (new Template(template, path, values)).write()
  
  # Spin up a local server for testing
  server: =>
    name    = AstroJS.getProjectName()
    curdir  = process.cwd()
    port    = if argv['port']? then argv['port'] else 8000
    minify  = if argv['minify']? then true else false
    
    root = process.cwd()
    pkg = require fd.join(root, 'package.json')
    console.log ansi("Running astrojs 0.1.2", 'yellow')
    
    # Strata web server
    strata.use strata.commonLogger
    strata.use strata.contentType, 'text/html'
    strata.use strata.contentLength
    strata.use strata.file, curdir

    # Build the library on request
    strata.get '/module.js', (env, callback) =>
      
      unless pkg['_dependencyOrder']?
        process.stderr.write "ERROR: The dependency order must be specified in package.json\n"
        return
      
      order = pkg['_dependencyOrder']
      coffeeSource = ""
      for dep in order
        currentFile = fd.join(root, 'src', "#{dep}.coffee")
        coffeeSource += fs.readFileSync(currentFile)
        coffeeSource += "\n"
      source = cs.compile(coffeeSource)
      
      # Minify code if flag is specified
      if minify
        opts =
          fromString: true
          mangle: true
        result = UglifyJS.minify(source, opts)
        source = result.code
      
      callback 200,
        "Content-Type": "text/javascript"
      , source

    # Build the specs on request
    strata.get '/specs.js', (env, callback) ->
      
      # Concatenate coffeescript specs
      coffeeSource = ""
      files = fs.readdirSync(fd.join('test', 'specs'))
      for f in files
        continue unless f.match /\.coffee$/i
        currentFile = fd.join('test', 'specs', f)
        coffeeSource += fs.readFileSync(currentFile)
      
      # Compile coffeescript
      source = cs.compile(coffeeSource)
      
      callback 200,
        "Content-Type": "text/javascript"
      , source

    # Server defaults to test directory
    strata.use strata.file, './test', ['SpecRunner.html']
    strata.run
      port: port
  
  # Build the project
  build: -> spawn 'cake', ['build']
  
  # Generate documentation using groc
  docs: ->
    # Check if in project directory
    return unless AstroJS.inProjectDirectory()
    
    name = AstroJS.getProjectName()
    console.log ansi("\tGenerating documentation for #{name}", 'green')
    
    grocJob = spawn('groc', ['README.md', 'src/*.coffee'])
    grocJob.stderr.on "data", (data) ->
      process.stderr.write data.toString()
    grocJob.stdout.on 'data', (data) ->
      console.log data.toString()
    grocJob.on 'exit', (code) ->
      console.log ansi("\tcreated documention for #{name}", 'green')
  
  exec: (command = argv._[0]) ->
    name = argv._[1]
    switch command
      when 'new'
        help() unless name
        @['new'](name)
      when 'class'
        help() unless name
        @['klass'](name)
      when 'server'
        @['server']()
      when 'build'
        @['build']()
      when 'docs'
        @['docs']()
      else
        help()

module.exports = AstroJS