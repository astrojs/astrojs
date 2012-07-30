fs        = require('fs')
fd        = require('path')
cs        = require('coffee-script')
stitch    = require('stitch')
strata    = require('strata')
optimist  = require('optimist')
{spawn}   = require('child_process')
Template  = require('./template')
ansi      = require('./ansi')

argv = optimist.usage([
  '  usage: astrojs COMMAND',
  '    new      create a new project template',
  '    class    generate a class template and associated test template',
  '    server   start a dynamic development server',
  '    build    serialize application to disk'
].join("\n"))
.alias('p', 'port')
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
      return false unless fd.existsSync(fd.join(root, f))
    return true
  
  # Get the project name from package.json.  It is assumed this function is called from a project
  # directory.
  @getProjectName: ->
    packagePath = fd.join(process.cwd(), "package")
    metadata = require(packagePath)
    return metadata["name"]
  
  @getDependencies: ->
    metadata = require(packagePath)
    
  
  constructor: ->
    
  new: (name) ->
    template = __dirname + "/../templates/module"
    values =
      name: AstroJS.camelize fd.basename(name)
      
    name = fd.normalize(name)

    # Create parent dir
    throw (name + " already exists") if fd.existsSync(name)
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
    @klassSpec(name)
  
  klassSpec: (name) ->
    return unless fd.existsSync(fd.join('test', 'specs'))
    template = fd.join(__dirname, '..', 'templates', 'spec.class.coffee')
    values =
      name: AstroJS.camelize(fd.basename(name))
    path = fd.join('test', 'specs', "#{name}.coffee")
    (new Template(template, path, values)).write()
  
  server: ->
    console.log ansi('\tstarting server', 'green')
    name    = AstroJS.getProjectName()
    curdir  = process.cwd()
    port    = if argv['port']? then argv['port'] else 8000

    # Strata web server
    strata.use strata.commonLogger
    strata.use strata.contentType, 'text/html'
    strata.use strata.contentLength
    strata.use strata.file, curdir
    
    # Specify paths that will be accessed during development
    strata.get '/module.js', (env, callback) ->
      console.log ansi('\tbuilding module', 'green')
      
      coffee = spawn('coffee', ['-c', '-o', 'lib', 'src'])
      coffee.stderr.on 'data', ->
        process.stderr.write data.toString()
      coffee.stdout.on "data", (data) ->
        console.log data.toString()
      coffee.on 'exit', (code) ->
        if code is 0
          pkg = stitch.createPackage(paths: [fd.join(curdir, 'lib')])
          pkg.compile (err, source) ->
            throw err if err
            callback 200,
              'Content-Type': 'text/javascript'
            , source

    strata.get '/specs.js', (env, callback) ->
      console.log ansi('\tbuilding specs', 'green')
      coffee = spawn('coffee', ['-c', '-o', 'test/specs', 'test/specs'])
      coffee.stderr.on 'data', ->
        process.stderr.write data.toString()
      coffee.stdout.on 'data', (data) ->
        console.log data.toString()
      coffee.on 'exit', (code) ->
        if code is 0
          files = fs.readdirSync(fd.join('test', 'specs'))
          source = ""
          for f in files
            if f.match /\.js$/i
              currentFile = fd.join('test', 'specs', f)
              source += fs.readFileSync(currentFile)
          callback 200,
            "Content-Type": "text/javascript"
          , source

    # Server defaults to test directory
    strata.use strata.file, './test', ['SpecRunner.html']
    strata.run
      port: port
  
  build: ->
    name = AstroJS.getProjectName()
    curdir = process.cwd()
    
    coffee = spawn('coffee', ['-c', '-o', 'lib', 'src'])
    coffee.stderr.on "data", ->
      process.stderr.write data.toString()
    coffee.stdout.on 'data', (data) ->
      console.log data.toString()
    coffee.on 'exit', (code) ->
      if code is 0
        main = fd.join(curdir, 'lib', "#{name}.js")
        temp = fd.join(curdir, 'lib', "#{name}_tmp.js")
        
        # Call Stitch to handle dependencies and package library
        pkg = stitch.createPackage
          paths: [fd.join(curdir, 'lib')]
        pkg.compile (err, source) ->
          libpath = fd.join(curdir, 'lib', "#{name}_tmp.js")
          fs.writeFile libpath, source, (err) ->
            throw err if err
            fs.renameSync temp, main
            console.log ansi("\tcompiled #{name}", 'green')
  
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
      else
        help()

module.exports = AstroJS