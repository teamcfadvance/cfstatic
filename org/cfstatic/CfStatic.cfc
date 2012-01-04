<cfcomponent output="false" hint="I am the CfMinify api component. Instantiate me with configuration options and use my include(), includeData() and renderIncludes() methods to awesomely manage your static includes" extends="org.cfstatic.util.Base">

<!--- private properties --->
	<cfscript>
		_staticDirectory     = "";
		_staticUrl           = "";
		_jsDirectory         = "js";
		_cssDirectory        = "css";
		_outputDirectory     = "min";
		_minifyMode          = "package";
		_downloadExternals   = false;
		_addCacheBusters     = true;
		_debugAllowed        = true;
		_debugKey            = "debug";
		_debugPassword       = true;
		_forceCompilation    = false;
		_checkForUpdates     = false;
		_includeAllByDefault = true;
		_embedCssImages      = "none";

		_jsPackages			= "";
		_cssPackages		= "";
		_yuiCompressor		= "";
		_lessCompiler		= "";
		_cssImageParser		= "";
		_includeMapping		= StructNew();
		_includeMapping.js	= StructNew();
		_includeMapping.css	= StructNew();
	</cfscript>

<!--- constructor --->
	<cffunction name="init" access="public" returntype="CfStatic" output="false" hint="I am the constructor for CfStatic. Pass in your CfStatic configuration options to me.">
		<cfargument name="staticDirectory"     type="string"  required="true"                    hint="Full path to the directoy in which static files reside" />
		<cfargument name="staticUrl"           type="string"  required="true"                    hint="Url that maps to the static directory" />
		<cfargument name="jsDirectory"         type="string"  required="false" default="js"      hint="Relative path to the directoy in which javascript files reside. Relative to static path." />
		<cfargument name="cssDirectory"        type="string"  required="false" default="css"     hint="Relative path to the directoy in which css files reside. Relative to static path." />
		<cfargument name="outputDirectory"     type="string"  required="false" default="min"     hint="Relative path to the directory in which minified files will be output. Relative to static path." />
		<cfargument name="minifyMode"          type="string"  required="false" default="package" hint="The minify mode. Options are: 'none', 'file', 'package' or 'all'." />
		<cfargument name="downloadExternals"   type="boolean" required="false" default="false"   hint="If set to true, CfMinify will download and minify locally any external dependencies (e.g. http://code.jquery.com/jquery-1.6.1.min.js)" />
		<cfargument name="addCacheBusters"     type="boolean" required="false" default="true"    hint="If set to true (default), CfStatic will use last modified date as part of generated minified filenames"/>
		<cfargument name="debugAllowed"        type="boolean" required="false" default="true"    hint="Whether or not debug is allowed. Defaulting to true, even though this may seem like a dev setting. No real extra load is made on the server by a user making use of debug mode and it is useful by default." />
		<cfargument name="debugKey"            type="string"  required="false" default="debug"   hint="URL parameter name used to invoke debugging (if enabled)" />
		<cfargument name="debugPassword"       type="string"  required="false" default="true"    hint="URL parameter value used to invoke debugging (if enabled)" />
		<cfargument name="forceCompilation"    type="boolean" required="false" default="false"   hint="Whether or not to check for updated files before compiling" />
		<cfargument name="checkForUpdates"     type="boolean" required="false" default="false"   hint="Whether or not to attempt a recompile every request. Useful in development, should absolutely not be enabled in production." />
		<cfargument name="includeAllByDefault" type="boolean" required="false" default="true"    hint="Whether or not to include all static files in a request when the .include() method is never called" />
		<cfargument name="embedCssImages"      type="string"  required="false" default="none"    hint="Either 'none', 'all' or a regular expression to select css images that should be embedded in css files as base64 encoded strings, e.g. '\.gif$' for only gifs or '.*' for all images"/>

		<cfscript>
			// if we are given a relative or mapped path, ensure we have the full path
			if(directoryExists(ExpandPath(arguments.staticDirectory))){
				arguments.staticDirectory = ExpandPath(arguments.staticDirectory);
			}

			// ensure easy windows / unix compatibility
			arguments.staticDirectory = $samifyUnixAndWindowsPaths( arguments.staticDirectory );

			// set config options
			_setRootDirectory		( arguments.staticDirectory );
			_setJsDirectory			( arguments.jsDirectory		);
			_setCssDirectory		( arguments.cssDirectory	);
			_setOutputDirectory		( $listAppend(arguments.staticDirectory, arguments.outputDirectory, '/') );
			_setJsUrl				( $listAppend(arguments.staticUrl,		arguments.jsDirectory, '/')		);
			_setCssUrl				( $listAppend(arguments.staticUrl,		arguments.cssDirectory, '/')	);
			_setMinifiedUrl			( $listAppend(arguments.staticUrl,		arguments.outputDirectory, '/')	);
			_setMinifyMode			( arguments.minifyMode 			);
			_setDownloadExternals	( arguments.downloadExternals	);
			_setDebugAllowed		( arguments.debugAllowed		);
			_setDebugKey			( arguments.debugKey			);
			_setDebugPassword		( arguments.debugPassword		);
			_setForceCompilation	( arguments.forceCompilation	);
			_setCheckForUpdates		( arguments.checkForUpdates		);
			_setAddCacheBusters		( arguments.addCacheBusters     );
			_setIncludeAllByDefault ( arguments.includeAllByDefault );
			_setEmbedCssImages      ( arguments.embedCssImages      );

			// instantiate any compilers we are using and compile the static resources
			_loadCompilers();
			_processStaticFiles();

			// return reference to self
			return this;
		</cfscript>
	</cffunction>

<!--- public methods --->
	<cffunction name="include" access="public" returntype="CfStatic" output="false" hint="I am the include() method. Call me on each request to specify that a static resource should be included in the requested page. I return a reference to the cfstatic object and can therefore be chained. e.g. cfstatic.include('/css/core/').include('/css/homepage/homepage.css');">
		<cfargument name="resource" type="string" required="true" hint="A url path, relative to the base static url, specifiying a static file or entire static package. e.g. '/css/core/layout.css' to include a single file, or '/css/core/' to include all files in the core css package." />
		<cfscript>
			// we do not do any calculation here, simply build an array of resources. We calculate dependencies, min files, etc. in renderIncludes()
			var includes = _getRequestIncludes();

			// add .css to .less includes
			if(ListLast(arguments.resource, '.') EQ 'less'){
				arguments.resource = arguments.resource & '.css';
			}

			ArrayAppend(includes, arguments.resource);

			_setRequestIncludes(includes);

			return this; // so that we can chain includes
		</cfscript>
	</cffunction>

	<cffunction name="includeData" access="public" returntype="CfStatic" output="false" hint="I am the includeData() method. Call me on each request to make ColdFusion data available to your javascript code. Data passed in to this method (as a struct) will be output as a global javascript variable named 'cfrequest'. So, if you pass in a structure like so: {siteroot='/mysite/', dataurl='/mysite/getdata'}, you will have 'cfrequest.siteroot' and cfrequest.dataurl as variables available to any javascript files included with cfstatic.">
		<cfargument name="data" type="struct" required="true" hint="Data to be outputted as javascript variables. All keys in this structure will then be available to your javascript, in an object named 'cfrequest'." />

		<cfscript>
			var currentData = _getRequestData();

			StructAppend(currentData, arguments.data);
			_setRequestData(currentData);

			return this; // so that we can chain includes
		</cfscript>
    </cffunction>

	<cffunction name="renderIncludes" access="public" returntype="string" output="false" hint="I am the renderIncludes() method. I return the html required for including all the static resources needed for the requested page. If no includes have been specified, I include *all* static resources.">
		<cfargument name="type" type="string" required="false" hint="Either 'js' or 'css'. the type of include to render. If I am not specified, the method will render both css and javascript (css first)" />
		<cfargument name="debugMode" type="boolean" required="false" default="#_getDebugAllowed() and StructKeyExists(url, _getDebugKey()) and url[_getDebugKey()] EQ _getDebugPassword()#" hint="Whether or not to render the source files (as opposed to the compiled files). You should use the debug url parameter (see cfstatic config options) rather than manually setting this argument, but it is included here should you need it." />

		<cfscript>
			var str				= CreateObject("java","java.lang.StringBuffer");
			var minification 	= iif(arguments.debugMode, DE('none'), DE(_getMinifyMode()));
			var filters			= "";

			if( not StructKeyExists(arguments, 'type') OR arguments.type EQ 'css' ){
				filters = _getRequestIncludeFilters( type = 'css' );

				if( (ArrayLen(filters.packages) + ArrayLen(filters.files)) or _getIncludeAllByDefault() ){
					str.append( _getCssPackages().renderincludes( minification, _getDownloadExternals(), filters.packages, filters.files ) );
				}
			}
			if( not StructKeyExists(arguments, 'type') OR arguments.type EQ 'js' ){
				str.append( _renderRequestData() );

				filters = _getRequestIncludeFilters( type = 'js' );
				if( (ArrayLen(filters.packages) + ArrayLen(filters.files)) or _getIncludeAllByDefault() ){
					str.append( _getJsPackages().renderincludes( minification, _getDownloadExternals(), filters.packages, filters.files ) );
				}
			}

			return str.toString();
		</cfscript>
	</cffunction>

<!--- private methods --->
	<cffunction name="_processStaticFiles" access="private" returntype="void" output="false" hint="I call all the methods that do the grunt work of cfstatic (processing all the file metadata, caching relationships and compiling files)">
		<cfscript>
			// compile any less css files before having them picked up by the css packager
			_compileLess();

			// process the directories to calculate all file metadata and dependencies
			_setJsPackages			( _packageDirectory( $listAppend(_getRootDirectory(), _getJsDirectory(), '/' )	, _getJsUrl(), _getMinifiedUrl(), 'js') );
			_setCssPackages			( _packageDirectory( $listAppend(_getRootDirectory(), _getCssDirectory(), '/' ), _getCssUrl(), _getMinifiedUrl(), 'css') );

			// calculate mappings between include paths and minified files and their dependencies (used to speed up includes)
			_calculateMappings();

			// compile files
			_compile();
		</cfscript>
	</cffunction>

	<cffunction name="_packageDirectory" access="private" returntype="org.cfstatic.core.PackageCollection" output="false" hint="I take a directory and return a processed PackageCollection object (with stored metadata about the packages and files within it)">
		<cfargument name="rootDirectory"	type="string" required="true" />
		<cfargument name="rootUrl"			type="string" required="true" />
		<cfargument name="minifiedUrl"		type="string" required="true" />
		<cfargument name="fileType"			type="string" required="true" />

		<cfreturn CreateObject('component', 'org.cfstatic.core.PackageCollection').init( arguments.rootDirectory, arguments.rootUrl, arguments.minifiedUrl, arguments.fileType, _getAddCacheBusters() ) />
	</cffunction>

	<cffunction name="_calculateMappings" access="private" returntype="void" output="false" hint="I calculate the include mappings. The mappings are a quick referenced storage of a given 'include' string that a coder might use to include a package or file that is mapped to the resultant set of packages and files that it might need to include given its dependencies. These mappings then negate the need to calculate dependencies on every request (making cfstatic super fast).">
		<cfscript>
			var collection		= "";
			var packages		= "";
			var package			= "";
			var files			= "";
			var file			= "";
			var dependencies	= "";
			var i				= "";
			var n				= "";
			var x				= "";
			var type			= "";
			var rootDir			= "";
			var types			= ListToArray("js,css");
			var mappings		= StructNew();
			var include			= "";
			var pkgInclude		= "";

			// silly little loop to repeat code for both js and css
			for(type=1; type LTE 2; type++){
				mappings = StructNew();

				if(types[type] EQ 'js'){
					collection	= _getJsPackages();
					rootDir		= _getJsDirectory();
				} else {
					collection	= _getCssPackages();
					rootDir		= _getCssDirectory();
				}

				// loop over packages in our js or css package collection
				packages = collection.getOrdered();
				for(i=1; i LTE ArrayLen(packages); i++){
					package = collection.getPackage(packages[i]);

					// figure out the include name that coder will use to include it
					if(packages[i] EQ "external"){
						include = "external";
					} else {
						include = "/#rootDir##packages[i]#";
					}

					// setup the mapping structure for it
					mappings[include] = StructNew();
					mappings[include].packages = ArrayNew(1);
					mappings[include].files = ArrayNew(1);

					// add the package itself to the list of packages for the include
					ArrayAppend( mappings[include].packages, packages[i]);

					// get the packages dependency packages and add them to the list of packages
					dependencies = package.getDependencies( recursive = true );
					for(n=1; n LTE ArrayLen(dependencies); n++){
						ArrayAppend( mappings[include].packages, dependencies[n]);
					}
				}

				// finish calculating all the package mappings before looping over them all again
				// to calculate the file mappings (we can make use of the already figured out package mappings, follow?)
				for(i=1; i LTE ArrayLen(packages); i++){
					package = collection.getPackage(packages[i]);
					files = package.getOrdered();

					// loop over the package files
					for(n=1; n LTE ArrayLen(files); n++){
						file = package.getStaticFile(files[n]);

						// figure out the include name that coder will use to include the file
						if(packages[i] EQ "external"){
							include = files[n];
							pkgInclude = "external";
						} else {
							include = "/#rootDir##packages[i]##ListLast(files[n], '/')#";
							pkgInclude = "/#rootDir##packages[i]#";
						}

						// setup the mapping structure for it
						mappings[include] = StructNew();
						mappings[include].packages = mappings[pkgInclude].packages; // for a start, we can add the mappings for the package already
						mappings[include].files = ArrayNew(1);

						// add the file itself
						ArrayAppend( mappings[include].files, files[n]);

						// add all the file's dependencies
						dependencies = file.getDependencies( recursive = true );
						for(x=1; x LTE ArrayLen(dependencies); x++){
							ArrayAppend( mappings[include].files, dependencies[x].getPath() );
						}
					}
				}

				// finally, persist the mappings for the life of this object
				_setIncludeMappings( mappings, types[type] );
			}
		</cfscript>
	</cffunction>

	<cffunction name="_getRequestIncludeFilters" access="private" returntype="struct" output="false" hint="I return a list of static files / packages that need to be included in this request">
		<cfargument name="type" type="string" required="true" hint="The type of static file, either 'js' or 'css'" />

		<cfscript>
			var includes		= _getRequestIncludes();
			var mappings		= _getIncludeMappings( arguments.type );
			var filters			= StructNew();
			var i				= 0;

			filters.packages	= ArrayNew(1);
			filters.files		= ArrayNew(1);

			// loop over the includes and add their precalculated mappings of lists of dependencies, etc.
			for(i=1; i LTE ArrayLen(includes); i++){
				if(StructKeyExists(mappings, includes[i])){
					filters.packages = $arrayMerge( filters.packages, mappings[includes[i]].packages );
					filters.files = $arrayMerge( filters.files, mappings[includes[i]].files );
				}
			}

			filters.packages = $arrayRemoveDuplicates( filters.packages );
			filters.files = $arrayRemoveDuplicates( filters.files );

			return filters;
		</cfscript>
	</cffunction>

	<cffunction name="_loadCompilers" access="private" returntype="void" output="false" hint="I instantiate all the compilers used by cfstatic">
		<cfscript>
			var jarsForYui		  = ArrayNew(1);
			var jarsForLess		  = ArrayNew(1);

			// put javaloader instances in server scope due to memory leak issues
			if( not StructKeyExists(server, '_cfstaticJavaloaders') ){
				jarsForYui[1]  = ExpandPath('/org/cfstatic/lib/yuiCompressor/yuicompressor-2.4.6.jar');
				jarsForYui[2]  = ExpandPath('/org/cfstatic/lib/cfstatic.jar');
				jarsForLess[1] = ExpandPath('/org/cfstatic/lib/less/lesscss-engine-1.1.4.jar');

				server['_cfstaticJavaloaders'] = StructNew();
				server['_cfstaticJavaloaders'].yui  = CreateObject('component','org.cfstatic.lib.javaloader.JavaLoader').init( jarsForYui  );
				server['_cfstaticJavaloaders'].less = CreateObject('component','org.cfstatic.lib.javaloader.JavaLoader').init( jarsForLess );
			}

			_setYuiCompressor ( CreateObject('component','org.cfstatic.util.YuiCompressor' ).init( server['_cfstaticJavaloaders'].yui  ) );
			_setLessCompiler  ( CreateObject('component','org.cfstatic.util.LessCompiler'  ).init( server['_cfstaticJavaloaders'].less ) );
			_setCssImageParser( CreateObject('component','org.cfstatic.util.CssImageParser').init( _getCssUrl(), $listAppend(_getRootDirectory(), _getCssDirectory(), '/' ) ) );
		</cfscript>
	</cffunction>

	<cffunction name="_compile" access="private" returntype="void" output="false" hint="I instantiate the compiling of static files, using different methods depending on the value of the 'minifyMode' config option (passed to the constructor)">
		<cfscript>
			switch(_getMinifyMode()){
				case 'file':
					_compileFiles();
					break;

				case 'package':
					_compilePackages();
					break;

				case 'all':
					_compileAll();
					break;
			}
		</cfscript>
	</cffunction>

	<cffunction name="_compileLess" access="public" returntype="void" output="false">
		<cfscript>
			var cssDir = $listAppend(_getRootdirectory(), _getCssdirectory(), '/');
			var files  = $directoryList(cssDir, '*.less');
			var i      = 0;
			var file   = "";
			var target = "";

			for(i=1; i LTE files.recordCount; i++){
				file = $listAppend(files.directory[i], files.name[i], '/');
				target = file & '.css';

				if(not fileExists(target) or $fileLastModified(target) LT $fileLastModified(file)){
					$fileWrite( target, _getLesscompiler().compile( file ) );

					// set the last modified date of the generated css file to be that of the LESS file
					FileSetLastModified( target, $fileLastModified(file) );
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="_compileAll" access="private" returntype="void" output="false" hint="I compile all the js files into a single minified js file and all the css files into a single css file.">
		<cfscript>
			var packages	= "";
			var package		= "";
			var files		= "";
			var file		= "";
			var content		= CreateObject("java","java.lang.StringBuffer");
			var i			= "";
			var n			= "";
			var filePath	= "";
			var fileName	= "";

			// js
			if( _compilationNecessary(_getJsPackages() ) ){
				packages		= _getJsPackages().getOrdered();
				for(i=1; i LTE ArrayLen(packages); i++){
					package		= _getJsPackages().getPackage(packages[i]);
					files			= package.getOrdered();
					for(n=1; n LTE ArrayLen(files); n++){
						file		= package.getStaticFile( files[n] );
						content.append( _compileJsFile( file ) );
					}
				}

				fileName	= _getJsPackages().getMinifiedFileName();
				filePath	= $listAppend( _getOutputDirectory(), filename, '/' );
				$fileWrite(filePath, content.toString());
			}

			// css
			content		= CreateObject("java","java.lang.StringBuffer");
			if( _compilationNecessary(_getCssPackages() ) ){
				packages		= _getCssPackages().getOrdered();
				for(i=1; i LTE ArrayLen(packages); i++){
					package		= _getCssPackages().getPackage(packages[i]);
					files		= package.getOrdered();
					for(n=1; n LTE ArrayLen(files); n++){
						file		= package.getStaticFile( files[n] );
						content.append( _compileCssFile( file ) );
					}
				}

				fileName	= _getCssPackages().getMinifiedFileName();
				filePath	= $listAppend( _getOutputDirectory(), filename, '/' );
				$fileWrite(filePath, content.toString());
			}

			$directoryClean( directory=_getOutputDirectory(), excludeFiles=ListAppend( _getJsPackages().getMinifiedFileName(), _getCssPackages().getMinifiedFileName() ) );
		</cfscript>
	</cffunction>

	<cffunction name="_compilePackages" access="private" returntype="void" output="false" hint="I compile all the js and css files into a single file per package (directory containing files)">
		<cfscript>
			var packages		= "";
			var package			= "";
			var files			= "";
			var file 			= "";
			var content			= "";
			var i				= "";
			var n				= "";
			var filePath		= "";
			var fileName		= "";
			var fileList        = "";

			// js
			packages		= _getJsPackages().getOrdered();
			for(i=1; i LTE ArrayLen(packages); i++){
				content			= CreateObject("java","java.lang.StringBuffer");
				package		= _getJsPackages().getPackage(packages[i]);
				if( (_getDownloadexternals() OR packages[i] NEQ 'external') AND _compilationNecessary( package ) ){

					files			= package.getOrdered();
					for(n=1; n LTE ArrayLen(files); n++){
						file		= package.getStaticFile( files[n] );
						content.append( _compileJsFile( file ) );
					}

					fileName	= package.getMinifiedFileName();
					filePath	= $listAppend( _getOutputDirectory(), filename, '/' );
					$fileWrite(filePath, content.toString());
				}

				fileList = ListAppend(fileList, package.getMinifiedFileName());
			}

			// css
			packages		= _getCssPackages().getOrdered();
			for(i=1; i LTE ArrayLen(packages); i++){
				content			= CreateObject("java","java.lang.StringBuffer");
				package		= _getCssPackages().getPackage(packages[i]);
				if( ( _compilationNecessary( package ) ) AND (_getDownloadexternals() OR packages[i] NEQ 'external') ){
					files			= package.getOrdered();
					for(n=1; n LTE ArrayLen(files); n++){
						file		= package.getStaticFile( files[n] );
						content.append( _compileCssFile( file ) );
					}

					fileName	= package.getMinifiedFileName();
					filePath	= $listAppend( _getOutputDirectory(), filename, '/' );
					$fileWrite(filePath, content.toString());
				}

				fileList = ListAppend(fileList, package.getMinifiedFileName());
			}

			$directoryClean( directory=_getOutputDirectory(), excludeFiles=fileList );
		</cfscript>
	</cffunction>

	<cffunction name="_compileFiles" access="private" returntype="void" output="false" hint="I compile all the js and css files, compiling each single source file as a single compiled file.">
		<cfscript>
			var packages	= "";
			var package		= "";
			var files		= "";
			var file		= "";
			var content		= "";
			var i			= "";
			var n			= "";
			var filePath	= "";
			var fileName	= "";
			var fileList    = "";

			// js
			packages		= _getJsPackages().getOrdered();
			for(i=1; i LTE ArrayLen(packages); i++){
				package			= _getJsPackages().getPackage(packages[i]);
				if(_getDownloadexternals() OR packages[i] NEQ 'external'){
					files			= package.getOrdered();
					for(n=1; n LTE ArrayLen(files); n++){
						file		= package.getStaticFile( files[n] );

						if(  _compilationNecessary( file ) ){
							content		= _compileJsFile( file );
							fileName	= file.getMinifiedFileName();
							filePath	= $listAppend( _getOutputDirectory(), filename, '/' );
							$fileWrite(filePath, content);
						}
						fileList = ListAppend(fileList, file.getMinifiedFileName());
					}
				}
			}

			// css
			packages		= _getCssPackages().getOrdered();
			for(i=1; i LTE ArrayLen(packages); i++){
				if(_getDownloadexternals() OR packages[i] NEQ 'external'){
					package			= _getCssPackages().getPackage(packages[i]);
					files			= package.getOrdered();
					for(n=1; n LTE ArrayLen(files); n++){
						file		= package.getStaticFile( files[n] );

						if(  _compilationNecessary( file ) ){
							content		= _compileCssFile( file );
							fileName	= file.getMinifiedFileName();
							filePath	= $listAppend( _getOutputDirectory(), filename, '/' );
							$fileWrite(filePath, content);
						}
						fileList = ListAppend(fileList, file.getMinifiedFileName());
					}
				}
			}

			$directoryClean( directory=_getOutputDirectory(), excludeFiles=fileList );
		</cfscript>
	</cffunction>

	<cffunction name="_compileJsFile" access="private" returntype="string" output="false" hint="I compile a single js file, returning the compiled string">
		<cfargument name="file" type="org.cfstatic.core.StaticFile" required="true" hint="The staticFile object representing the javascript file to compile" />

		<cfscript>
			// if the file is minified already, just return its content
			if( arguments.file.getProperty('minified', 'false', 'string') ){
				return arguments.file.getContent();
			}

			// else, return compressed version
			return _getYuiCompressor().compressJs( arguments.file.getContent() );
		</cfscript>
    </cffunction>

	<cffunction name="_compileCssFile" access="private" returntype="string" output="false" hint="I compile a single css file, returning the compiled string">
		<cfargument name="file" type="org.cfstatic.core.StaticFile" required="true" hint="The staticFile object representing the css file to compile" />

		<cfscript>
			var content = arguments.file.getContent();

			// compress using yui compressor (if not already minified)
			if( not arguments.file.getProperty('minified', 'false', 'string') ){
				content = _getYuiCompressor().compressCss( content );
			}

			// parse relative image paths
			content	= _getCssImageParser().parse( content, arguments.file.getPath(), _getEmbedCssImages() );

			return content;
		</cfscript>
    </cffunction>

	<cffunction name="_compilationNecessary" access="private" returntype="boolean" output="false" hint="I calculate whether or not compilation is neccessary for the given file, package or packageCollection object. The desicion is based on the presence of a compiled file and the last modified dates of the compiled file and source files. Compilation can also be forced with the forceCompilation config option.">
		<cfargument name="collectionPackageOrFile" type="any" required="true" hint="This could be either a staticFile, package or packageCollection" />

		<cfscript>
			var minFile = $listAppend(_getOutputDirectory(), arguments.collectionPackageOrFile.getMinifiedFileName(), '/');

			// if we've been told to, we ought to...
			if( _getForceCompilation() ){
				return true;
			}

			// if the minified file does not exist already we ought to compile
			if(not fileExists(minFile)){
				return true;
			}

			// otherwise, if the minified file has not been modified since the last modification to the source file(s), we ought to compile
			return $fileLastModified(minFile) LT arguments.collectionPackageOrFile.getLastModified();
		</cfscript>
	</cffunction>

	<cffunction name="_renderRequestData" access="private" returntype="string" output="false" hint="I render any data set for the request as a javascript variable">
		<cfscript>
			var data = _getRequestData();
			if(StructIsEmpty(data)){
				return "";
			}

			return '<script type="text/javascript">var cfrequest = #SerializeJson(data)#</script>';
		</cfscript>
    </cffunction>

	<cffunction name="_setRequestIncludes" access="private" returntype="void" output="false" hint="I set the array of includes for this request">
		<cfargument name="requestIncludes" required="true" type="array" />
		<cfset request['_cfstaticIncludes'] = arguments.requestIncludes />
	</cffunction>
	<cffunction name="_getRequestIncludes" access="private" returntype="array" output="false" hint="I get the array of includes for this request">
		<cfscript>
			if(not StructKeyExists(request, '_cfstaticIncludes')){
				_setupRequest();
			}

			return request['_cfstaticIncludes'];
		</cfscript>
	</cffunction>

	<cffunction name="_setRequestData" access="private" returntype="void" output="false" hint="I set the structure of data to be rendered as javascript variables for this request">
    	<cfargument name="requestData" type="struct" required="true" />
    	<cfset request['_cfstaticData'] = arguments.requestData />
    </cffunction>
	<cffunction name="_getRequestData" access="private" returntype="struct" output="false" hint="I get the structure of data to be rendered as javascript variables for this request">
    	<cfscript>
    		if(not StructKeyExists(request, '_cfstaticData')){
				_setupRequest();
			}

			return request['_cfstaticData'];
		</cfscript>
    </cffunction>

	<cffunction name="_setupRequest" access="public" returntype="void" output="false" hint="I setup all the skeleton data for a new request. I also check to see whether or not we should attempt to recompile all the static files (dev mode)">
		<cfscript>
			// set skeleton data
			_setRequestIncludes(ArrayNew(1));
			_setRequestData( StructNew() );

			// check whether or not we should try to recompile
			if(_getCheckForUpdates()){
				_processStaticFiles();
			}
		</cfscript>
    </cffunction>

<!--- plain old instance property accessors (private) --->
	<cffunction name="_getRootDirectory" access="private" returntype="string" output="false">
    	<cfreturn _rootDirectory />
    </cffunction>
    <cffunction name="_setRootDirectory" access="private" returntype="void" output="false">
    	<cfargument name="rootDirectory" type="string" required="true" />
    	<cfset _rootDirectory = arguments.rootDirectory />
    </cffunction>

	<cffunction name="_setJsDirectory" access="private" returntype="void" output="false">
		<cfargument name="jsDirectory" required="true" type="string" />
		<cfset _jsDirectory = arguments.jsDirectory />
	</cffunction>
	<cffunction name="_getJsDirectory" access="private" returntype="string" output="false">
		<cfreturn _jsDirectory />
	</cffunction>

	<cffunction name="_setJsUrl" access="private" returntype="void" output="false">
		<cfargument name="jsUrl" required="true" type="string" />
		<cfset _jsUrl = arguments.jsUrl />
	</cffunction>
	<cffunction name="_getJsUrl" access="private" returntype="string" output="false">
		<cfreturn _jsUrl />
	</cffunction>

	<cffunction name="_setCssDirectory" access="private" returntype="void" output="false">
		<cfargument name="cssDirectory" required="true" type="string" />
		<cfset _cssDirectory = arguments.cssDirectory />
	</cffunction>
	<cffunction name="_getCssDirectory" access="private" returntype="string" output="false">
		<cfreturn _cssDirectory />
	</cffunction>

	<cffunction name="_setCssUrl" access="private" returntype="void" output="false">
		<cfargument name="cssUrl" required="true" type="string" />
		<cfset _cssUrl = arguments.cssUrl />
	</cffunction>
	<cffunction name="_getCssUrl" access="private" returntype="string" output="false">
		<cfreturn _cssUrl />
	</cffunction>

	<cffunction name="_setOutputDirectory" access="private" returntype="void" output="false">
		<cfargument name="outputDirectory" required="true" type="string" />
		<cfset _outputDirectory = arguments.outputDirectory />
	</cffunction>
	<cffunction name="_getOutputDirectory" access="private" returntype="string" output="false">
		<cfreturn _outputDirectory />
	</cffunction>

	<cffunction name="_setMinifiedUrl" access="private" returntype="void" output="false">
		<cfargument name="minifiedUrl" required="true" type="string" />
		<cfset _minifiedUrl = arguments.minifiedUrl />
	</cffunction>
	<cffunction name="_getMinifiedUrl" access="private" returntype="string" output="false">
		<cfreturn _minifiedUrl />
	</cffunction>

	<cffunction name="_setMinifyMode" access="private" returntype="void" output="false">
		<cfargument name="minifyMode" required="true" type="string" />
		<cfset _minifyMode = arguments.minifyMode />
	</cffunction>
	<cffunction name="_getMinifyMode" access="private" returntype="string" output="false">
		<cfreturn _minifyMode />
	</cffunction>

	<cffunction name="_setDownloadExternals" access="private" returntype="void" output="false">
		<cfargument name="downloadExternals" required="true" type="boolean" />
		<cfset _downloadExternals = arguments.downloadExternals />
	</cffunction>
	<cffunction name="_getDownloadExternals" access="private" returntype="boolean" output="false">
		<cfreturn _downloadExternals />
	</cffunction>

	<cffunction name="_setDebugAllowed" access="private" returntype="void" output="false">
		<cfargument name="debugAllowed" required="true" type="boolean" />
		<cfset _debugAllowed = arguments.debugAllowed />
	</cffunction>
	<cffunction name="_getDebugAllowed" access="private" returntype="boolean" output="false">
		<cfreturn _debugAllowed />
	</cffunction>

	<cffunction name="_setDebugKey" access="private" returntype="void" output="false">
		<cfargument name="debugKey" required="true" type="string" />
		<cfset _debugKey = arguments.debugKey />
	</cffunction>
	<cffunction name="_getDebugKey" access="private" returntype="string" output="false">
		<cfreturn _debugKey />
	</cffunction>

	<cffunction name="_setDebugPassword" access="private" returntype="void" output="false">
		<cfargument name="debugPassword" required="true" type="string" />
		<cfset _debugPassword = arguments.debugPassword />
	</cffunction>
	<cffunction name="_getDebugPassword" access="private" returntype="string" output="false">
		<cfreturn _debugPassword />
	</cffunction>

	<cffunction name="_setForceCompilation" access="private" returntype="void" output="false">
		<cfargument name="forceCompilation" required="true" type="boolean" />
		<cfset _forceCompilation = arguments.forceCompilation />
	</cffunction>
	<cffunction name="_getForceCompilation" access="private" returntype="boolean" output="false">
		<cfreturn _forceCompilation />
	</cffunction>

	<cffunction name="_getCheckForUpdates" access="private" returntype="boolean" output="false">
    	<cfreturn _checkForUpdates />
    </cffunction>
    <cffunction name="_setCheckForUpdates" access="private" returntype="void" output="false">
    	<cfargument name="checkForUpdates" type="boolean" required="true" />
    	<cfset _checkForUpdates = arguments.checkForUpdates />
    </cffunction>

	<cffunction name="_setJsPackages" access="private" returntype="void" output="false">
		<cfargument name="jsPackages" required="true" type="org.cfstatic.core.PackageCollection" />
		<cfset _jsPackages = arguments.jsPackages />
	</cffunction>
	<cffunction name="_getJsPackages" access="private" returntype="org.cfstatic.core.PackageCollection" output="false">
		<cfreturn _jsPackages />
	</cffunction>

	<cffunction name="_setCssPackages" access="private" returntype="void" output="false">
		<cfargument name="cssPackages" required="true" type="org.cfstatic.core.PackageCollection" />
		<cfset _cssPackages = arguments.cssPackages />
	</cffunction>
	<cffunction name="_getCssPackages" access="private" returntype="org.cfstatic.core.PackageCollection" output="false">
		<cfreturn _cssPackages />
	</cffunction>

	<cffunction name="_setYuiCompressor" access="private" returntype="void" output="false">
		<cfargument name="yuiCompressor" required="true" type="any" />
		<cfset _yuiCompressor = arguments.yuiCompressor />
	</cffunction>
	<cffunction name="_getYuiCompressor" access="private" returntype="any" output="false">
		<cfreturn _yuiCompressor />
	</cffunction>

	<cffunction name="_setLessCompiler" access="private" returntype="void" output="false">
		<cfargument name="lessCompiler" required="true" type="any" />
		<cfset _lessCompiler = arguments.lessCompiler />
	</cffunction>
	<cffunction name="_getLessCompiler" access="private" returntype="any" output="false">
		<cfreturn _lessCompiler />
	</cffunction>

	<cffunction name="_setCssImageParser" access="private" returntype="void" output="false">
		<cfargument name="cssImageParser" required="true" type="any" />
		<cfset _cssImageParser = arguments.cssImageParser />
	</cffunction>
	<cffunction name="_getCssImageParser" access="private" returntype="any" output="false">
		<cfreturn _cssImageParser />
	</cffunction>

	<cffunction name="_setIncludeMappings" access="private" returntype="void" output="false">
		<cfargument name="includeMappings" required="true" type="struct" />
		<cfargument name="type" type="string" required="true" />

		<cfset _includeMappings[arguments.type] = arguments.includeMappings />
	</cffunction>
	<cffunction name="_getIncludeMappings" access="private" returntype="struct" output="false">
		<cfargument name="type" type="string" required="true" />
		<cfreturn _includeMappings[arguments.type] />
	</cffunction>

	<cffunction name="_getAddCacheBusters" access="private" returntype="boolean" output="false">
		<cfreturn _addCacheBusters>
	</cffunction>
	<cffunction name="_setAddCacheBusters" access="private" returntype="void" output="false">
		<cfargument name="addCacheBusters" type="boolean" required="true" />
		<cfset _addCacheBusters = arguments.addCacheBusters />
	</cffunction>

	<cffunction name="_getIncludeAllByDefault" access="private" returntype="boolean" output="false">
		<cfreturn _includeAllByDefault>
	</cffunction>
	<cffunction name="_setIncludeAllByDefault" access="private" returntype="void" output="false">
		<cfargument name="includeAllByDefault" type="boolean" required="true" />
		<cfset _includeAllByDefault = arguments.includeAllByDefault />
	</cffunction>

	<cffunction name="_getEmbedCssImages" access="private" returntype="string" output="false">
		<cfreturn _embedCssImages>
	</cffunction>
	<cffunction name="_setEmbedCssImages" access="private" returntype="void" output="false">
		<cfargument name="embedCssImages" type="string" required="true" />
		<cfset _embedCssImages = arguments.embedCssImages />
	</cffunction>
</cfcomponent>