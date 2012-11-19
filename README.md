astrojs
=======

astrojs is a project to develop and consolidate javascript libraries for astronomical applications.  Similar to the [astropy](http://www.astropy.org/) project, astrojs attempts to gather useful libraries under a single namespace so they may become shared resources to the astronomical community.  There are many codes floating around the web, which if they were consolidated in a central location, would be of much greater value.

If you have a javascript resource that you would like to share, please contact [Amit Kapadia](amit@zooniverse.org).

astrojs module
--------------
This module provides a scaffold and convenience functions for developing under the javascript astro namespace.  It is most useful when developing astrojs libraries using the [coffeescript](coffeescript.org) language.  A future release will support development for pure javascript.  There are four functions available from the command line.

    astrojs new [project name]
    astrojs class [class name]
    astrojs server
    astrojs build

### installation
The astrojs module is built using [NodeJS](http://nodejs.org/).  Why Node?  Node is another flavor of javascript, javascript that runs server side.  A Node module may be developed and run in a similar why to any other scripting language, such as python.  As this is a javascript initiative, any utilities should be developed in javascript.  If Node is not installed, please refer to its documentation and [downloads](http://nodejs.org/download/) page.

Upon installation of Node a package manager called [NPM](npmjs.org) will be available.  The astrojs module is available via the Node Packaged Modules service.  To install the astrojs module run

    npm install astrojs -g

This will install astrojs globally, and it will function as a command line utility.  (It most likely needs to be run using sudo).

### creating an astrojs project
To create an astrojs project run

    astrojs new [project name]

This will generate the following project files under a directory named by `[project name]`:

    Cakefile
    index.js
    lib/
    package.json
    README.md
    src/
      |----[project name].coffee
    test/
      |----favicon.ico
      |----lib/jasmine-html.js
      |----lib/jasmine.css
      |----lib/jasmine.js
      |----lib/MIT.LICENSE
      |----SpecRunner.html
      |----specs/

### generating a new class
Javascript is a prototype-based language, however a class-like structure can be emulated using particular development patterns.  Use of this modules means that the developer is adopting a module pattern for library development.  Executing

    astrojs new [class name]

from within an astrojs project directory will generate template code for a new class and test functions.

### starting a local development server
Development always requires testing.  When developing an astrojs module, it is encouraged to test all functionality.  Frequently a local testing server is needed.  Calling

    astrojs server
    
will spin up a local testing server at [http://0.0.0.0:8000](http://0.0.0.0:8000).  This is useful when unit tests require data that must be accessed on the same domain as the script (e.g. ajax requests to json or binary files).

### building an astrojs project
This module encourages development to occur in a modular fashion.  Often development of libraries can quickly become overwhelming.  Good practice encourages codes to be modulated into separate files, however this requires a build step when delivering the final javascript library.  Calling

    astrojs build

concatenates all files in the `src` directory, and provides the final product in the `lib` directory.  It is important to specify the dependency order using the key `_dependencyOrder` in package.json.

### example
For an example of using this module for development, please refer to the [fitsjs](https://github.com/astrojs/fitsjs) library.
