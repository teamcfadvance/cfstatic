---
layout: default
title: Full Usage Guide
---

# {{ page.title }}

1. [Preparing your static files](#preparation)
2. [Configuration](#configuration)
3. [API Usage](#useage)
4. [LESS](#less)
5. [CoffeeScript](#coffeescript)

<a id="preparation"></a>
## Preparing your static files

In order for CfStatic to render static includes in the correct order and satisfy dependencies, it must know how your static files relate to each other. It offers three ways in which to do this:

1. [JavaDoc style documentation](#javadoc) in each file
2. [Plain text 'dependencies' file](#dependency-file)
3. File and folder name ordering

All three methods may be used. Dependencies declared in JavaDoc style comments and in the dependencies file will be merged. When there is no dependency information, CfStatic will use the file and folder names for ordering of includes.

The JavaDoc style commenting system also allows you to specify other processing instructions for CfStatic, not available in the dependencies file (see below).

<a id="javadoc"></a>
### JavaDoc style comments

JavaDoc comments look like this and must be present at the top of your files for CfStatic to process them:

{% highlight js %}
/**
 * Note the slash and double star to start the
 * comments. The first paragraph of text
 * within the comment block is a free-text
 * description (i.e. this text). CfStatic will
 * ignore this description but it can/should be
 * used to document your code. Key value pair
 * properties are then defined using the @
 * symbol:
 *
 * @property property value
 * @property another property value
 * @anotherproperty yet another property value
 */
{% endhighlight %}

CfStatic makes use of the following properties:

#### @depends
Used to indicate a file dependency (see below), e.g. `@depends /core/jquery.js`

#### @minified
Used to indicate that a file is already minified (do `@minified true`), CfStatic will not then re-minify the file

####@ie
Used to indicate an Internet Explorer restriction for the file, e.g. `@ie LTE IE 8`

####@media
For CSS files only, used to indicate the target media for the CSS file, e.g. `@media print`


### Documenting dependencies

Core to the correct running of CfStatic is the use of the @depends property to document dependencies between your files; CfStatic uses this information to ensure all necessary files are included in your page, and in the correct order. Dependencies can be either local or external, e.g. `@depends http://someurl.com/somejs.js` is an external dependency, `@depends /jqueryplugins/tooltip.js` is a local dependency.

Local dependencies have a path that starts at the root folder of the type of file you are dealing with. i.e. If your javascript files all live at `/webroot/static/js/`, and the file `/webroot/static/js/plugins/myplugin.js` has a dependency on `/webroot/static/js/core/jquery.js`, that dependency would be written like so: `@depends /core/jquery.js`.

#### Already minified files

Some of your local files may already have been minified or you may not want certain files to be minified by CfStatic. By setting the **@minified** property to true (i.e. `@minified true`), CfStatic will *not* put the file through the minifier. The file will still be renamed and moved to the output directory however.

#### Internet Explorer specific includes

These can be declared using the **@ie** property and static files with this property set will be wrapped in Conditional Comments when output as includes. Examples:

{% highlight js %}
/**
 * This is my IE 6 only print stylesheet
 *
 * @ie IE 6
 * @media print
 * @depends /core/layout.css
 */
{% endhighlight %}

{% highlight js %}
/**
 * This is my IE 8 and below stylesheet
 *
 * @ie LT IE 8
 * @depends /core/layout.css
 */
{% endhighlight %}

Example output:

{% highlight html %}
<!--[if LT IE 8]><link rel="stylesheet" href="/assets/min/core.ie67.min.201206211653.css" media="all" charset="utf-8" /><![endif]-->
{% endhighlight %}

See here for conditional comment reference:

[http://msdn.microsoft.com/en-us/library/ms537512(v=vs.85).aspx](http://msdn.microsoft.com/en-us/library/ms537512\(v=vs.85\).aspx)

<a id="dependency-file"></a>
### Dependency file

The dependency file can be used to document dependencies only. This has some advantages over the javadoc style approach:

1. Not having to repeat dependency definitions in every file. For instance, if you want to upgrade jquery, you have only one dependency definition to change
2. Documenting dependencies between external resources

An example javascript dependency file (the syntax is the same for css dependencies):

{% highlight sh %}
##
# This file details dependencies between
# javascript files.
#
# Indented files have dependencies on the
# unindented file(s) above them. Dependent
# files marked with (conditional), only depend
# on the file above when it is already included
# in the request and can be included without
# the dependency.
##

http://ajax.googleapis.com/ajax/libs/jquery/1.6.4/jquery.min.js
    http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.18/jquery-ui.min.js
    *.js

http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.18/jquery-ui.min.js
    /folder/some.js
    /core/bootstrap.js
    /ui-pages/*.js

/core/bootstrap.js
    /folder/*.js
    /ui-pages/*.js
    /shared/*.js

/folder/some.js
    /folder/some-more.js

/shared/swfLoader/swfLoader.js
    /folder/some.js

/shared/jqGrid/locales/*.js
    /shared/jqGrid/jqGrid.js (conditional)

/shared/jqGrid/jqGrid.js
    /folder/some-more.js
{% endhighlight %}

### Configuring CfStatic to use the dependency file

Use the two configuration options, `jsDependencyFile` and `cssDependencyFile` to point CfStatic to your dependency files. The files themselves can be called anything you like. My current preference is for `dependency.info` placed in the root of both js and css directories, for example:

{% highlight cfm %}
<cfscript>
application.cfstatic = CreateObject( org.cfstatic.CfStatic' ).init(
    staticDirectory   = ExpandPath('./static')
  , staticUrl         = "/static/"
  , jsDependencyFile  = ExpandPath( './static/js/dependency.info' )
  , cssDependencyFile = ExpandPath( './static/css/dependency.info' )
);
</cfscript>
{% endhighlight %}

### Syntax of the dependencies file

#### Comments

Lines beginning with a # are ignored by the parser. Empty lines are also ignored.

#### Indentation

Paths to files that are declared *unindented* are treated as *dependencies*. Their *dependents* are defined by subsequent paths that *are* indented. Only one level of indentation is processed, i.e. all depths of indentation are treated the same. For example:

{% highlight sh %}
# core.js is dependent on jquery.js
/core/jquery.js
    /core/core.js

# both tools.js and api.js are dependent on core.js
# note that api.js is not dependent on tools.js because
# only one level of indentation is processed
/core/core.js
    /core/tools.js
      /core/api.js

{% endhighlight %}

#### Wildcard mappings

Wildcard mappings may be used to declare multiple dependents and dependencies. For example:

{% highlight sh %}
# all css and less files depend on reset.less
/core/reset.less
    *.css
    *.less

# all .less files beginning with fubar-
# depend on fubarcore.less
/fubar/fubarcore.less
    /fubar/fubar-*.less

# all files under the fubar folder
# depend on all core files
/core/*.*
    /fubar/*.*
{% endhighlight %}

#### Conditional dependencies

A conditional dependency is one in which 'resource a' is dependent on 'resource b' *only when 'resource b' is included*. This means that 'resource a' can be included without 'resource b', but when 'resource b' is included, it will always be rendered before 'resource a'.

To declare a dependant as conditional, you append `(conditional)` to the file path. For example:

{% highlight sh %}
/shared/jqGrid/locales/*.js
    /shared/jqGrid/jqGrid.js (conditional)
{% endhighlight %}

This is a perfect example of this kind of dependency. `jqGrid.js` is dependent on *a* locale file but which one must be determined at request time. Without the `(conditional)` instruction, all locales would be included on every request. So now, you can include the user's locale at request time and know that it will always be included before jqGrid.js:

{% highlight cfm %}
<cfscript>
cfstatic.include( '/js/shared/jqGrid/jqGrid.js' )
        .include( '/js/shared/jqGrid/locales/#session.user.locale#.js' );
</cfscript>
{% endhighlight %}

<a id="configuration"></a>
## Configuration

### Argument reference

The CfStatic init() method takes the following arguments. Do not be alarmed at the number of them, only two are mandatory, the rest have sensible defaults:

<table class="config-table">
    <tr>
        <th>staticDirectory:</th>
        <td>Full path to the directory in which static files reside (e.g. /webroot/static/)</td>
    </tr>
    <tr>
        <th>staticUrl:</th>
        <td>Url that maps to the static directory (e.g. http://mysite.com/static or /static)</td>
    </tr>
    <tr>
        <th>jsDirectory:</th>
        <td>Relative path to the directoy in which javascript files reside. Relative to static path. Default is 'js'</td>
    </tr>
    <tr>
        <th>cssDirectory:</th>
        <td>Relative path to the directoy in which css files reside. Relative to static path. Default is 'css'</td>
    </tr>
    <tr>
        <th>outputDirectory:</th>
        <td>Relative path to the directory in which minified files will be output. Relative to static path. Default is 'min'</td>
    </tr>
    <tr>
        <th>minifyMode:</th>
        <td>The minify mode. Options are: 'none', 'file', 'package' or 'all'. Default is 'package'.</td>
    </tr>
    <tr>
        <th>downloadExternals:</th>
        <td>If set to true, CfStatic will download and minify any external dependencies (e.g. http://code.jquery.com/jquery-1.6.1.min,js). Default = false</td>
    </tr>
    <tr>
        <th>debugAllowed:</th>
        <td>Whether or not debug is allowed. Defaulting to true, even though this may seem like a dev setting. No real extra load is made on the server by a user making use of debug mode and it is useful by default. Default = true.</td>
    </tr>
    <tr>
        <th>debugKey:</th>
        <td>URL parameter name used to invoke debugging (if enabled). Default = 'debug'</td>
    </tr>
    <tr>
        <th>debugPassword:</th>
        <td>URL parameter value used to invoke debugging (if enabled). Default = 'true'</td>
    </tr>
    <tr>
        <th>forceCompilation:</th>
        <td>Whether or not to check for updated files before compiling (true = do not check). Default = false.</td>
    </tr>
    <tr>
        <th>checkForUpdates:</th>
        <td>Whether or not to attempt recompilation on every request. Default = false</td>
    </tr>
    <tr>
        <th>includeAllByDefault:</th>
        <td>Whether or not to include all static files in a request when the .include() method is never called (default = true) *0.2.2*</td>
    </tr>
    <tr>
        <th>embedCssImages:</th>
        <td>Either 'none', 'all' or a regular expression to select css images that should be embedded in css files as base64 encoded strings, e.g. '\.gif$' for only gifs or '.*' for all images (default = 'none') *0.3.0*</td>
    </tr>
    <tr>
        <th>includePattern:</th>
        <td>Regex pattern indicating css and javascript files to be included in CfStatic's processing. Defaults to .* (all) *0.4.0*</td>
    </tr>
    <tr>
        <th>excludePattern:</th>
        <td>Regex pattern indicating css and javascript files to be excluded from CfStatic's processing. Defaults to blank (exclude none) *0.4.0*</td>
    </tr>
    <tr>
        <th>outputCharset:</th>
        <td>Character set to use when writing outputted minified files *0.4.0*</td>
    </tr>
    <tr>
        <th>javaLoaderScope:</th>
        <td>The scope in which instances of JavaLoader libraries for the compilers should be persisted, either 'application' or 'server' (default is 'server' to prevent JavaLoader memory leaks). You may need to use 'application' in a shared hosting environment *0.4.1*</td>
    </tr>
    <tr>
        <th>lessGlobals:</th>
        <td>Comma separated list of .LESS files to import when processing all .LESS files. Files will be included in the order of the list *0.4.2*</td>
    </tr>
    <tr>
        <th>jsDataVariable:</th>
        <td>JavaScript variable name that will contain any data passed to the .includeData() method, default is 'cfrequest' *0.6.0*</td>
    </tr>
    <tr>
        <th>jsDependencyFile:</th>
        <td>Text file describing the dependencies between javascript files *0.6.0*</td>
    </tr>
    <tr>
        <th>cssDependencyFile:</th>
        <td>Text file describing the dependencies between css files *0.6.0*</td>
    </tr>
    <tr>
        <th>throwOnMissingInclude:</th>
        <td>Whether or not to throw an error by default when the include() method is passed a resource that does not exist. Default is `false` (no error will be thrown). *0.7.0*</td>
    </tr>
</table>


### Configuring static paths and URLS
The minimal setup, ready for production, involves declaring your root static directory and the url that maps to it. This assumes that you have 'js', 'css' and 'min' folders beneath your 'staticDirectory'. For example, consider the following directory structure:

    ./
    ../
    includes/
        css/
        js/
        min/
    Application.cfc

The minimal configuration might look like this:

{% highlight cfm %}
<cfscript>
application.cfstatic = CreateObject('org.cfstatic.CfStatic').init(
      staticDirectory = ExpandPath('/includes')
    , staticUrl       = "/includes"
);
</cfscript>
{% endhighlight %}

Another example, this time with non-default folder names for the static files, and css and javascript having a folder to themselves in the root:

    ./
    ../
    styles/
    javascript/
    compiled/
    index.cfm
    Application.cfc

In this case, your configuration might look like:

**Application.cfc**

{% highlight cfm %}
<cfscript>
application.cfstatic = CreateObject('org.cfstatic.CfStatic').init(
      staticDirectory = ExpandPath('./')
    , staticUrl       = "/"
    , jsDirectory     = 'javascript'
    , cssDirectory    = 'styles'
    , outputDirectory = 'compiled'
);
</cfscript>
{% endhighlight %}

### Minify modes

Minify modes control how CfStatic minifies your files. The options are:

* **None**: no minification (i.e. only use CfStatic for the request inclusion and dependency handling framework )
* **File**: files are minified but not concatenated in any way
* **Package** (default): files are minified and concatenated in packages (all files in the same folder are considered a package)
* **All**: files are minified and concatenated into a single JavaScript file and a single CSS file

Use the *minifyMode* argument to set this behaviour. For a more in-depth look at minify modes, see my blog post here:

[http://fusion.dominicwatson.co.uk/2011/09/understanding-the-package-minify-mode-in-cfstatic.html](http://fusion.dominicwatson.co.uk/2011/09/understanding-the-package-minify-mode-in-cfstatic.html)

### External dependencies

External dependencies can be declared in your static files with `@depends http://www.somsite.com/somefile.js`. CfStatic can either download these dependencies for local minification and concatenation, or it can simply output an include to reference the file remotely. This might be a good idea for popular libraries hosted on CDNs such as jQuery. However, if you're creating an intranet application, it may be wise to ensure that all files are served from your own server.

Use the *downloadExternals* argument to set this behaviour.

### Debug mode

By default, you can make CfStatic output includes for your source files rather than the minified files, by providing the url parameter, `debug=false`. You can turn this behaviour off altogether with the *debugAllowed* argument, or you can set the url parameter name and value with the *debugKey* and *debugPassword* parameters.

### Monitoring for updates

CfStatic can be set up to monitor your static files for changes, recompiling when it finds them. This is really useful for local development though is turned *off* by default. Use the *checkForUpdates* argument to set this behaviour.

Also by default, CfStatic will *not* recompile on instantiation if it finds that there have been no changes to your files. You can change this behaviour, forcing recompiling on instantiation (e.g. on application start), by using the *forceCompilation* argument.

A combination of the two arguments, e.g. `checkForUpdates=true` and `forceCompilation=true`, will force recompiling on every request.

### Including all files by default (from 0.2.2)

Out of the box, CfStatic will include *all* your static files if you never use the .include() method to specifically pick files to include (i.e. you just do .renderIncludes()). You can change this behaviour by setting `includeAllByDefault` to false.


### Embedding CSS Images (from 0.3.0)

The `embedCssImages` option allows you to instruct CfStatic to embed CSS images as data URIs in the compiled CSS files (see <http://en.wikipedia.org/wiki/Data_URI_scheme>).

The default option of '`none`' performs no image embedding. Passing '`all`' will instruct CfStatic to embed *all* CSS images. Finally, you can pass a regular expression to specify which images will be chosen for embedding.

For more information, see the blog post here:

[http://fusion.dominicwatson.co.uk/2012/01/cfstatic---embedding-css-images.html](http://fusion.dominicwatson.co.uk/2012/01/cfstatic---embedding-css-images.html)

### Excluding resources from the engine (from 0.4.0)

For whatever reason, you may wish to have CfStatic overlook certain CSS, LESS or JavaScript files. From *0.4.0* there are two arguments that will allow you to do just that, `includePattern` and `excludePattern`. By combining these two arguments that both accept regex patterns, you can have full control over what CfStatic will include. For example, you may wish to exclude some Global LESS files:

      includePattern = '.*'
    , excludePattern = '.*/lessGlobals/.*'

Or only include any resources under a `raw` folder that do not contain an underscore:

      includePattern = '.*/raw/.*'
    , excludePattern = '.*_.*'


<a id="useage"></a>
## API Useage

Once you have configured CfStatic and marked up your static files with the appropriate dependency documentation, you arrive at the pleasing point of having very little left to do. The CfStatic API provides 4 public methods:

1. **include( *resource*, *[throwOnMissing]* )**: used to instruct CfStatic that a particular file or package (folder) is required for this request
2. **includeData( *data* )**: used to output data to a JavaScript variable when the javascript is rendered
3. **renderIncludes( *[type]* )**: used to render the CSS or JavaScript includes
4. **getIncludeUrl( *[type]*, *[resource]*, *[throwOnMissing]* )**: used to retrieve the compiled URL of a given type and resource


### Include( *required string resource*, *[boolean throwOnMissing]* )

You can use this method to include an entire package (folder) or a single file in the requested page. Paths start at the root static directory, so the following are all valid:

{% highlight cfm %}
<cfscript>
// include the layout.css file
cfStatic.include('/css/core/layout.css');

// include the 'core' css package (note the trailing slash
// on the directory name)
cfStatic.include('/css/core/');

// include a bunch of js packages and files, chaining the
// method call
cfStatic.include('/js/core/')
        .include('/js/core/ie-only/')
        .include('/js/plugins/timers.js')
        .include('/js/pagespecific/homepage/');
</cfscript>
{% endhighlight %}

#### The throwOnMissing argument / Including non existent packages or files

The `throwOnMissing` argument is not required and will default to whatever the [configuration](#configuration) option, `throwOnMissingInclude`, is set to. The default, production ready setting is `false` (no errors will be thrown). If true, an error will be thrown if you attempt to include a resource that does not exist.

By setting this option to `false`, or simply sticking with the default, CfStatic will *not* throw an error when you attempt to include a resource that does not exist. This allows you to create dynamic includes based on any rules you like. For instance, you might want to try to include page specific css when it is available, something like:

{% highlight cfm %}
<cfscript>
// where request.pageName is some variable set by your application:
cfStatic.include(
      resource       = '/css/pageSpecific/#request.pageName#/'
    , throwOnMissing = false
);
</cfscript>

{% endhighlight %}

You can then include page specific css by convention; creating directories and files that match the naming convention of your pages / modules / framework events, etc.

*Prior to **0.7.0**, the `throwOnMissing` argument was not available and CfStatic would never throw an error on missing include.*


#### Don't worry about the order

You can include your static files in any order you like and you can include the same files multiple times; CfStatic will take care of rendering them in the correct order and once each only.


### IncludeData( *required struct data* )

You can use the IncludeData method to make CF data available to your JavaScript. The following example illustrates its usage:

**someColdFusionFile.cfm**

{% highlight cfm %}
<cfscript>
data                    = StructNew();
data['userColorChoice'] = session.user.prefs.colorChoice;
data['fu']              = 'bar';
data.watchMyCase        = 'sensitive isn't it?';

cfStatic.includeData( data )
        .includeData( {bar="fu"} ); // you can chain me too
</cfscript>
{% endhighlight %}

**Outputted JavaScript before all includes**

{% highlight js %}
    var cfrequest = {
         "userColorChoice" : "#FF99FF"
       , "fu"              : "bar"
       , "WATCHMYCASE"     : "sensitive isn't it?"
       , "BAR"             : "fu"
    };

    // you now have access to cfrequest.userColorChoice, etc. from within your javacsript
{% endhighlight %}

#### Beware of case sensitivity

JavaScript is case sensitive and ColdFusion uppercases all struct keys that are not declared using array notation. Hopefully, the example above illustrates this.

### RenderIncludes( *[string type]* )

This method returns the necessary html to include your static files. The type argument is optional and should be set to either 'CSS' or 'JS' when passed. Here are a couple of examples:

**ExampleLayout1.cfm**

{% highlight cfm %}
    <html>
        <head>
            ...
            <!-- render all css and js includes (css first) -->
            #cfStatic.renderIncludes()#
        </head>
        <body>
            ...
        </body>
    </html>
{% endhighlight %}

**ExampleLayout2.cfm**
{% highlight cfm %}
    <html>
        <head>
            ...
            <!-- render css in the head of the page -->
            #cfStatic.renderIncludes('css')#
        </head>
        <body>
            ...
            <!-- render js at the bottom of the page -->
            #cfStatic.renderIncludes('js')#
        </body>
    </html>
{% endhighlight %}

The rendered output will look something like this:

{% highlight html %}
<link rel="stylesheet" href="/assets/min/core.min.201208282132.css" media="all" charset="utf-8" />
<!--[if ie]><link rel="stylesheet" href="/assets/min/core.ie.min.201206211653.css" media="all" charset="utf-8" /><![endif]-->
<link rel="stylesheet" href="/assets/min/core.mobile.min.201208121923.css" media="handheld" charset="utf-8" />
<script type="text/javascript" src="/assets/min/core.min.201208121914.js" charset="utf-8"></script>
<script type="text/javascript" src="/assets/min/plugins.jquery.min.201208121919.js" charset="utf-8"></script>
{% endhighlight %}

Notice the timestamps included in the filenames. These represent the lastest last modified date of any of the files that were compiled into the single minified file. This means that you *never* have to worry about users needing to clear their cache for changed CSS or JavaScript files. Conversly, if you deploy changes to one or two static files and not to the rest, your users may still use cached content for those files that have not changed (this is good).

### GetIncludeUrl( required string *[type]*, required string *[resource]*, boolean *[throwOnMissing]* )

You can use this method to get the compiled URL of a given resource (an entire package (folder) or a single file in the requested page). Paths start at the directory of the specified type, so the following are all valid:

{% highlight cfm %}
<cfscript>
// get the url of the layout.css file
includeUrl = cfStatic.getIncludeUrl( 'css', '/core/layout.css' );

// get the 'core' js package url (note the trailing slash
// on the directory name)
includeUrl = cfStatic.getIncludeUrl( 'js', '/core/' );

</cfscript>
{% endhighlight %}

<a id="less"></a>
## LESS CSS

If you've not heard of LESS CSS, head on over to [http://lesscss.org/](http://lesscss.org/) and fall to your knees in humble awe (and get all coder giddy).

In CfStatic, simply create .less files with LESS css in them in exactly the same way you create .css files for CfStatic. CfStatic will take your .less files and compile them as css, saving the output to `yourfile.less.css`. It will then minify that compiled css file in accordance with the rules you configure.

Additionaly, you can configure 'less globals'. These globals will be imported into every single LESS file before compiling, saving you from repeating yourself by using `@import url( ..\mygloballessdefinitions.less )` in every file.

<a id="coffeescript"></a>
## CoffeeScript

CfStatic will compile any `.coffee` files in your JavaScript directories, converting them to JavaScript files with the `.coffee.js` extension. A couple of things to note:

### Formatting of JavaDoc comments
JS comments are not valid CoffeeScript. To markup your CoffeeScript files ready for CfStatic, use the following format:

{% highlight js %}
###*
* This is my coffeescript file, its really neat.
*
* @depends /some/file.coffee.js
*
###
{% endhighlight %}

### Bare mode
By default, CoffeeScript will wrap the compiled `.js` in an anonymous function call to ensure no leaked variables:

{% highlight js %}
(function(){
    // your compiled js here
})();
{% endhighlight %}

If you do not want this behaviour, CoffeeScript offers a "bare mode" switch so that the anonymous function wrapper is not included (which they do not recommend). In CfStatic, simply name your CoffeeScript files with the `.bare.coffee` extension to have them compiled in bare mode.