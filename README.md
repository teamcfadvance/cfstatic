CFStatic is a framework for the inclusion and packaging of CSS and JavaScript files for CFML 
applications by Dominic Watson (http://fusion.dominicwatson.co.uk/).

CFStatic takes care of:
-----------------------

* Minifying your CSS and JavaScript
* Compiling your CoffeeScript and LESS CSS
* Including your CSS and JavaScript in the correct order, with all dependencies satisfied
* Adding sensible cachebusters to CSS image paths and CSS and JavaScript includes

Key features:
-------------

* Minifies your files for you using YuiCompressor
* Compiles your LESS CSS for you
* Compiles your CoffeeScript for you
* Dependency configuration through JavaDoc style documentation
* Easy, zero-code, switching between inclusion of raw source files and minified files
* Small API, only 4 public methods (including the constructor)
* Three minify modes (All, Package and File)
* Built for production; no need for CSS and JavaScript file packaging in your build scripts, 
  code can be put in production
* Minified files are saved to disk, CF is not involved in serving the files

Documentation
-------------

https://github.com/DominicWatson/cfstatic/wiki


Other resources
---------------

Authors Blog : http://fusion.dominicwatson.co.uk/categories/CfStatic/

Source       : https://github.com/DominicWatson/cfstatic/

Issues       : https://github.com/DominicWatson/cfstatic/issues/