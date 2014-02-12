<cfcomponent output="false" hint="I am the CfMinify api component. Instantiate me with configuration options and use my include(), includeData() and renderIncludes() methods to awesomely manage your static includes" extends="org.cfstatic.util.Base">

<!--- constructor --->
	<cffunction name="init" access="public" returntype="any" output="false" hint="I am the constructor for CfStatic. Pass in your CfStatic configuration options to me.">
		<cfargument name="staticDirectory"       type="string"  required="true"                      hint="Full path to the directoy in which static files reside" />
		<cfargument name="staticUrl"             type="string"  required="true"                      hint="Url that maps to the static directory" />
		<cfargument name="jsDirectory"           type="string"  required="false" default="js"        hint="Relative path to the directoy in which javascript files reside. Relative to static path." />
		<cfargument name="cssDirectory"          type="string"  required="false" default="css"       hint="Relative path to the directoy in which css files reside. Relative to static path." />
		<cfargument name="outputDirectory"       type="string"  required="false" default="min"       hint="Relative path to the directory in which minified files will be output. Relative to static path." />
		<cfargument name="minifyMode"            type="string"  required="false" default="package"   hint="The minify mode. Options are: 'none', 'file', 'package' or 'all'." />
		<cfargument name="downloadExternals"     type="boolean" required="false" default="false"     hint="If set to true, CfMinify will download and minify locally any external dependencies (e.g. http://code.jquery.com/jquery-1.6.1.min.js)" />
		<cfargument name="addCacheBusters"       type="boolean" required="false" default="true"      hint="If set to true (default), CfStatic will use HD5 checksum as part of generated minified filenames"/>
		<cfargument name="addImageCacheBusters"  type="boolean" required="false" default="true"      hint="If set to true (default), CfStatic will use last modified date of css images as part of the css image incdle"/>
		<cfargument name="debugAllowed"          type="boolean" required="false" default="true"      hint="Whether or not debug is allowed. Defaulting to true, even though this may seem like a dev setting. No real extra load is made on the server by a user making use of debug mode and it is useful by default." />
		<cfargument name="debugKey"              type="string"  required="false" default="debug"     hint="URL parameter name used to invoke debugging (if enabled)" />
		<cfargument name="debugPassword"         type="string"  required="false" default="true"      hint="URL parameter value used to invoke debugging (if enabled)" />
		<cfargument name="debug"                 type="boolean" required="false" default="false"     hint="Whether or not to start CfStatic in debug mode (regardless of other debug options). This is a permanent switch." />
		<cfargument name="forceCompilation"      type="boolean" required="false" default="false"     hint="Whether or not to check for updated files before compiling" />
		<cfargument name="checkForUpdates"       type="boolean" required="false" default="false"     hint="Whether or not to attempt a recompile every request. Useful in development, should absolutely not be enabled in production." />
		<cfargument name="includeAllByDefault"   type="boolean" required="false" default="true"      hint="Whether or not to include all static files in a request when the .include() method is never called" />
		<cfargument name="embedCssImages"        type="string"  required="false" default="none"      hint="Either 'none', 'all' or a regular expression to select css images that should be embedded in css files as base64 encoded strings, e.g. '\.gif$' for only gifs or '.*' for all images"/>
		<cfargument name="includePattern"        type="string"  required="false" default=".*"        hint="Regex pattern indicating css and javascript files to be included in CfStatic's processing. Defaults to .* (all)" />
		<cfargument name="excludePattern"        type="string"  required="false" default=""          hint="Regex pattern indicating css and javascript files to be excluded from CfStatic's processing. Defaults to blank (exclude none)" />
		<cfargument name="outputCharset"         type="string"  required="false" default="utf-8"     hint="Character set to use when writing outputted minified files" />
		<cfargument name="javaLoaderScope"       type="string"  required="false" default="server"    hint="The scope in which instances of JavaLoader libraries for the compilers should be persisted, either 'application' or 'server' (default is 'server' to prevent JavaLoader memory leaks)" />
		<cfargument name="lessGlobals"           type="string"  required="false" default=""          hint="Comma separated list of .LESS files to import when processing all .LESS files. Files will be included in the order of the list" />
		<cfargument name="jsDataVariable"        type="string"  required="false" default="cfrequest" hint="JavaScript variable name that will contain any data passed to the .includeData() method" />
		<cfargument name="jsDependencyFile"      type="string"  required="false" default=""          hint="Text file describing the dependencies between javascript files" />
		<cfargument name="cssDependencyFile"     type="string"  required="false" default=""          hint="Text file describing the dependencies between css files" />
		<cfargument name="throwOnMissingInclude" type="boolean" required="false" default="false"     hint="Whether or not to throw an error by default when the include() method is passed a resource that does not exist. The default is false (no error will be thrown)" />

		<cfscript>
			_setProperties( argumentCollection = arguments );
			_loadCompilers( javaLoaderScope = javaLoaderScope );
			_processStaticFiles();

			return this;
		</cfscript>
	</cffunction>

<!--- public methods --->
	<cffunction name="include" access="public" returntype="any" output="false" hint="I am the include() method. Call me on each request to specify that a static resource should be included in the requested page. I return a reference to the cfstatic object and can therefore be chained. e.g. cfstatic.include('/css/core/').include('/css/homepage/homepage.css');">
		<cfargument name="resource"       type="string"  required="true"                                          hint="A url path, relative to the base static url, specifiying a static file or entire static package. e.g. '/css/core/layout.css' to include a single file, or '/css/core/' to include all files in the core css package." />
		<cfargument name="throwOnMissing" type="boolean" required="false" default="#_getThrowOnMissingInclude()#" hint="If set to true and the resource does not exist, an informative error will be thrown. Defaults to false (no error will be thrown)" />

		<cfscript>
			var includes = _getRequestIncludes();
			var include  = _appendFileTypesToSpecialIncludes( resource );

			if ( arguments.throwOnMissing and not _resourceExists( arguments.resource ) ) {
				$throw( type="cfstatic.missing.include", message="CfStatic include() error: The requested include, [#arguments.resource#], does not exist." );
			}

			ArrayAppend( includes, include );

			_setRequestIncludes( includes );

			return _chainable();
		</cfscript>
	</cffunction>

	<cffunction name="includeData" access="public" returntype="any" output="false" hint="I am the includeData() method. Call me on each request to make ColdFusion data available to your javascript code. Data passed in to this method (as a struct) will be output as a global javascript variable named 'cfrequest'. So, if you pass in a structure like so: {siteroot='/mysite/', dataurl='/mysite/getdata'}, you will have 'cfrequest.siteroot' and cfrequest.dataurl as variables available to any javascript files included with cfstatic.">
		<cfargument name="data" type="struct" required="true" hint="Data to be outputted as javascript variables. All keys in this structure will then be available to your javascript, in an object named 'cfrequest'." />

		<cfscript>
			StructAppend( _getRequestData(), data );

			return _chainable();
		</cfscript>
    </cffunction>

	<cffunction name="renderIncludes" access="public" returntype="string" output="false" hint="I am the renderIncludes() method. I return the html required for including all the static resources needed for the requested page. If no includes have been specified, I include *all* static resources.">
		<cfargument name="type"      type="string"  required="false" hint="Either 'js' or 'css'. the type of include to render. If I am not specified, the method will render both css and javascript (css first)" />
		<cfargument name="debugMode" type="boolean" required="false" default="#_isDebugOnForRequest()#" hint="Whether or not to render the source files (as opposed to the compiled files). You should use the debug url parameter (see cfstatic config options) rather than manually setting this argument, but it is included here should you need it." />

		<cfscript>
			var filters      = "";
			var renderCache  = "";
			var buffer       = $getStringBuffer();
			var needToRender = "";
			var includeAll   = "";
			var types        = ListToArray( 'css,js' );
			var i            = 0;
			var n            = 0;

			for( i=1; i LTE ArrayLen( types ); i++ ){
				needToRender = not StructKeyExists( arguments, "type" ) or type eq types[i];

				if ( needToRender ) {
					if ( types[i] EQ 'js' ) {
						buffer.append( _renderRequestData() );
					}

					filters = _getRequestIncludeFilters( types[i], debugMode );

					if ( _anythingToRender( filters ) ) {
						renderCache = _getRenderedIncludeCache( types[i], debugMode )._ordered;
						includeAll  = not ArrayLen( filters ) and _getIncludeAllByDefault();

						if ( includeAll ){
							buffer.append( ArrayToList( renderCache, $newline() ) );

						} else {
							for( n=1; n LTE ArrayLen( filters ); n=n+1 ){
								buffer.append( renderCache[ filters[ n ] ] );
							}
						}
					}

					_clearRequestData( types[i] );
				}
			}

			return buffer.toString();
		</cfscript>
	</cffunction>

<!--- private methods --->
	<cffunction name="_setProperties" access="private" returntype="void" output="false">
		<cfargument name="staticDirectory"       type="string"  required="true"                      hint="Full path to the directoy in which static files reside" />
		<cfargument name="staticUrl"             type="string"  required="true"                      hint="Url that maps to the static directory" />
		<cfargument name="jsDirectory"           type="string"  required="false" default="js"        hint="Relative path to the directoy in which javascript files reside. Relative to static path." />
		<cfargument name="cssDirectory"          type="string"  required="false" default="css"       hint="Relative path to the directoy in which css files reside. Relative to static path." />
		<cfargument name="outputDirectory"       type="string"  required="false" default="min"       hint="Relative path to the directory in which minified files will be output. Relative to static path." />
		<cfargument name="minifyMode"            type="string"  required="false" default="package"   hint="The minify mode. Options are: 'none', 'file', 'package' or 'all'." />
		<cfargument name="downloadExternals"     type="boolean" required="false" default="false"     hint="If set to true, CfMinify will download and minify locally any external dependencies (e.g. http://code.jquery.com/jquery-1.6.1.min.js)" />
		<cfargument name="addCacheBusters"       type="boolean" required="false" default="true"      hint="If set to true (default), CfStatic will use last modified date as part of generated minified filenames"/>
		<cfargument name="addImageCacheBusters"  type="boolean" required="false" default="true"      hint="If set to true (default), CfStatic will use last modified date of css images as part of the css image incdle"/>
		<cfargument name="debugAllowed"          type="boolean" required="false" default="true"      hint="Whether or not debug is allowed. Defaulting to true, even though this may seem like a dev setting. No real extra load is made on the server by a user making use of debug mode and it is useful by default." />
		<cfargument name="debugKey"              type="string"  required="false" default="debug"     hint="URL parameter name used to invoke debugging (if enabled)" />
		<cfargument name="debugPassword"         type="string"  required="false" default="true"      hint="URL parameter value used to invoke debugging (if enabled)" />
		<cfargument name="debug"                 type="boolean" required="false" default="false"     hint="Whether or not to start CfStatic in debug mode (regardless of other debug options). This is a permanent switch." />
		<cfargument name="forceCompilation"      type="boolean" required="false" default="false"     hint="Whether or not to check for updated files before compiling" />
		<cfargument name="checkForUpdates"       type="boolean" required="false" default="false"     hint="Whether or not to attempt a recompile every request. Useful in development, should absolutely not be enabled in production." />
		<cfargument name="includeAllByDefault"   type="boolean" required="false" default="true"      hint="Whether or not to include all static files in a request when the .include() method is never called" />
		<cfargument name="embedCssImages"        type="string"  required="false" default="none"      hint="Either 'none', 'all' or a regular expression to select css images that should be embedded in css files as base64 encoded strings, e.g. '\.gif$' for only gifs or '.*' for all images"/>
		<cfargument name="includePattern"        type="string"  required="false" default=".*"        hint="Regex pattern indicating css and javascript files to be included in CfStatic's processing. Defaults to .* (all)" />
		<cfargument name="excludePattern"        type="string"  required="false" default=""          hint="Regex pattern indicating css and javascript files to be excluded from CfStatic's processing. Defaults to blank (exclude none)" />
		<cfargument name="outputCharset"         type="string"  required="false" default="utf-8"     hint="Character set to use when writing outputted minified files" />
		<cfargument name="lessGlobals"           type="string"  required="false" default=""          hint="Comma separated list of .LESS files to import when processing all .LESS files. Files will be included in the order of the list" />
		<cfargument name="jsDataVariable"        type="string"  required="false" default="cfrequest" hint="JavaScript variable name that will contain any data passed to the .includeData() method" />
		<cfargument name="jsDependencyFile"      type="string"  required="false" default=""          hint="Text file describing the dependencies between javascript files" />
		<cfargument name="cssDependencyFile"     type="string"  required="false" default=""          hint="Text file describing the dependencies between css files" />
		<cfargument name="throwOnMissingInclude" type="boolean" required="false" default="false"     hint="Whether or not to throw an error by default when the include() method is passed a resource that does not exist. The default is false (no error will be thrown)" />

		<cfscript>
			var rootDir = $normalizeUnixAndWindowsPaths( $ensureFullDirectoryPath( staticDirectory ) );

			_setRootDirectory        ( rootDir                                      );
			_setJsDirectory          ( jsDirectory                                  );
			_setCssDirectory         ( cssDirectory                                 );
			_setOutputDirectory      ( $listAppend(rootDir  , outputDirectory, '/') );
			_setJsUrl                ( $listAppend(staticUrl, jsDirectory    , '/') );
			_setCssUrl               ( $listAppend(staticUrl, cssDirectory   , '/') );
			_setMinifiedUrl          ( $listAppend(staticUrl, outputDirectory, '/') );
			_setMinifyMode           ( minifyMode                                   );
			_setDownloadExternals    ( downloadExternals                            );
			_setDebugAllowed         ( debugAllowed                                 );
			_setDebugKey             ( debugKey                                     );
			_setDebugPassword        ( debugPassword                                );
			_setDebug                ( debug                                        );
			_setForceCompilation     ( forceCompilation                             );
			_setCheckForUpdates      ( checkForUpdates                              );
			_setAddCacheBusters      ( addCacheBusters                              );
			_setAddImageCacheBusters ( addImageCacheBusters                         );
			_setIncludeAllByDefault  ( includeAllByDefault                          );
			_setEmbedCssImages       ( embedCssImages                               );
			_setIncludePattern       ( includePattern                               );
			_setExcludePattern       ( excludePattern                               );
			_setOutputCharset        ( outputCharset                                );
			_setLessGlobals          ( lessGlobals                                  );
			_setJsDataVariable       ( jsDataVariable                               );
			_setJsDependencyFile     ( jsDependencyFile                             );
			_setCssDependencyFile    ( cssDependencyFile                            );
			_setThrowOnMissingInclude( throwOnMissingInclude                        );
		</cfscript>
	</cffunction>

	<cffunction name="_processStaticFiles" access="private" returntype="void" output="false" hint="I call all the methods that do the grunt work of cfstatic (processing all the file metadata, caching relationships and compiling files)">
		<cfscript>
			var jsDir  = $listAppend( _getRootDirectory(), _getJsDirectory() , '/' );
			var cssDir = $listAppend( _getRootDirectory(), _getCssDirectory(), '/' );
		</cfscript>
		<cflock type="exclusive" name="cfstatic-processing-#_getRootDirectory()#" timeout="1" throwontimeout="false">
			<cfscript>
				_clearoutTemporaryLessFiles();
				_scanForImportedLessFiles();
				_compileLess();
				_compileCoffeeScript();

				_setJsPackages ( _packageDirectory( jsDir , _getJsUrl() , _getMinifiedUrl(), 'js' , _getDependenciesFromFile( 'js'  ) ) );
				_setCssPackages( _packageDirectory( cssDir, _getCssUrl(), _getMinifiedUrl(), 'css', _getDependenciesFromFile( 'css' ) ) );

				_cacheRenderedIncludes();
				_cacheIncludeMappings();
				_compileCssAndJavascript();

				if( _getCheckForUpdates() ) {
					_setFileStateCache( _getFileState() );
				}
			</cfscript>
		</cflock>
	</cffunction>

	<cffunction name="_packageDirectory" access="private" returntype="org.cfstatic.core.PackageCollection" output="false" hint="I take a directory and return a processed PackageCollection object (with stored metadata about the packages and files within it)">
		<cfargument name="rootDirectory" type="string" required="true"                          />
		<cfargument name="rootUrl"       type="string" required="true"                          />
		<cfargument name="minifiedUrl"   type="string" required="true"                          />
		<cfargument name="fileType"      type="string" required="true"                          />
		<cfargument name="dependencies"  type="struct" required="false" default="#StructNew()#" />

		<cfreturn CreateObject('component', 'org.cfstatic.core.PackageCollection').init(
			  rootDirectory  = rootDirectory
			, rootUrl        = rootUrl
			, minifiedUrl    = minifiedUrl
			, fileType       = fileType
			, cacheBust      = _getAddCacheBusters()
			, includePattern = _getIncludePattern()
			, excludePattern = _getExcludePattern()
			, dependencies   = dependencies
			, outputDir      = _getOutputDirectory()
		) />
	</cffunction>

	<cffunction name="_cacheIncludeMappings" access="private" returntype="void" output="false" hint="I calculate the include mappings. The mappings are a quick referenced storage of a given 'include' string that a coder might use to include a package or file that is mapped to the resultant set of packages and files that it might need to include given its dependencies. These mappings then negate the need to calculate dependencies on every request (making cfstatic super fast).">
		<cfscript>
			var mappings    = StructNew();
			var jsPackages  = _getJsPackages().getOrdered();
			var cssPackages = _getCssPackages().getOrdered();
			var i           = 0;

			for( i=1; i LTE ArrayLen( jsPackages ); i=i+1 ){
				mappings = _getIncludeMappingsForPackage( jsPackages[i], 'js', mappings );
			}
			_setIncludeMappings( mappings, 'js' );

			mappings = StructNew();
			for( i=1; i LTE ArrayLen( cssPackages ); i=i+1 ){
				mappings = _getIncludeMappingsForPackage( cssPackages[i], 'css', mappings );
			}
			_setIncludeMappings( mappings, 'css' );
		</cfscript>
	</cffunction>

	<cffunction name="_getIncludeMappingsForPackage" access="private" returntype="struct" output="false">
		<cfargument name="packageName" type="string" required="true" />
		<cfargument name="packageType" type="string" required="true" />
		<cfargument name="mappings"    type="struct" required="true" />

		<cfscript>
			var package      = _getPackage( packageName, packageType );
			var include      = packageName;
			var rootDir      = iif( packageType EQ 'css', DE( _getCssDirectory() ), DE( _getJsDirectory() ) );
			var dependencies = package.getDependencies( includeConditionals=false );
			var files        = package.getOrdered();
			var i            = 0;

			if ( include NEQ 'externals' ) {
				include = '/' & rootDir & include;
			}

			mappings[ include ]          = StructNew();
			mappings[ include ].packages = ArrayNew(1);
			mappings[ include ].files    = ArrayNew(1);

			ArrayAppend( mappings[ include ].packages, packageName );

			for( i=1; i LTE ArrayLen(dependencies); i++ ){
				ArrayAppend( mappings[ include ].packages, dependencies[i] );
			}

			for( i=1; i LTE ArrayLen( files ); i++ ){
				mappings = _getIncludeMappingsForFile(
					  filePath   = files[i]
					, file       = package.getStaticFile( files[i] )
					, pkgInclude = include
					, mappings   = mappings
				);
			}

			return mappings;
		</cfscript>
	</cffunction>

	<cffunction name="_getIncludeMappingsForFile" access="private" returntype="struct" output="false">
		<cfargument name="filePath"   type="string" required="true" />
		<cfargument name="file"       type="any"    required="true" />
		<cfargument name="pkgInclude" type="string" required="true" />
		<cfargument name="mappings"   type="struct" required="true" />

		<cfscript>
			var include      = filePath;
			var dependencies = file.getDependencies( recursive = true, includeConditionals = false );
			var i            = 1;

			if ( pkgInclude NEQ 'externals' ) {
				include = pkgInclude & ListLast( include, '/' );
			}

			mappings[include]          = StructNew();
			mappings[include].packages = mappings[pkgInclude].packages;
			mappings[include].files    = ArrayNew(1);

			ArrayAppend( mappings[include].files   , filePath );
			ArrayAppend( mappings[pkgInclude].files, filePath );

			for( i=1; i LTE ArrayLen( dependencies ); i++ ){
				ArrayAppend( mappings[include].files   , dependencies[i].getPath() );
				ArrayAppend( mappings[pkgInclude].files, dependencies[i].getPath() );
			}

			return mappings;
		</cfscript>
	</cffunction>

	<cffunction name="_getRequestIncludeFilters" access="private" returntype="array" output="false">
		<cfargument name="type"      type="string"  required="true"  hint="The type of static file, either 'js' or 'css'" />
		<cfargument name="debugMode" type="boolean" required="false" default="false" />
		<cfscript>
			var includes = _getRequestIncludes();
			var mappings = _getIncludeMappings( type );
			var filters  = StructNew();
			var fileMode = debugMode or ListFindNoCase( "file,none", _getMinifyMode() );
			var allMode    = not debugMode and _getMinifyMode() eq "all";
			var renderCache = _getRenderedIncludeCache( type, debugMode );
			var files    = "";
			var i        = 0;
			var n        = 0;

			for( i=1; i LTE ArrayLen( includes ); i++ ){

				if ( StructKeyExists( mappings, includes[i] ) ) {
					if ( fileMode ) {
						files = mappings[includes[i]].files;
					} else {
						files = mappings[includes[i]].packages;
					}

					for( n=1; n LTE ArrayLen( files ); n++ ){
						if ( allMode ){
							filters[ renderCache[ "/" ] ] = 1;
						} else {
							filters[ renderCache[ files[n] ] ] = 1;
						}
					}
				}
			}

			filters = StructKeyArray( filters );
			arraySort( filters, "numeric" );

			return filters;
		</cfscript>
	</cffunction>

	<cffunction name="_cacheRenderedIncludes" access="private" returntype="void" output="false">
		<cfscript>
			_setupRenderedIncludeCache();

			switch( _getMinifyMode() ){
				case 'all'     : _cacheRenderedIncludesForAllMode()    ; break;
				case 'package' : _cacheRenderedIncludesForPackageMode(); break;
				default        : _cacheRenderedIncludesForFileMode()   ; break;
			}

			_cacheRenderedIncludesForFileMode( debug = true );
		</cfscript>
	</cffunction>

	<cffunction name="_cacheRenderedIncludesForAllMode" access="private" returntype="void" output="false">
		<cfscript>
			_addRenderedIncludeToCache( 'js',  '/', _getJsPackages().renderIncludes(
				  minification      = _getMinifyMode()
				, downloadExternals = _getDownloadExternals()
			)  );
			_addRenderedIncludeToCache( 'css', '/', _getCssPackages().renderIncludes(
				  minification      = _getMinifyMode()
				, downloadExternals = _getDownloadExternals()
			) );
		</cfscript>
	</cffunction>

	<cffunction name="_cacheRenderedIncludesForPackageMode" access="private" returntype="void" output="false">
		<cfscript>
			var collection = "";
			var packages   = "";
			var package    = "";
			var types      = ListToArray("js,css");
			var minifyMode = "";
			var type       = "";
			var i          = 0;
			var n          = 0;

			for( n=1; n LTE ArrayLen( types ); n=n+1 ){
				type = types[n];

				if ( type EQ 'js' ) {
					collection = _getJsPackages();
				} else {
					collection = _getCssPackages();
				}
				packages = collection.getOrdered();


				for( i=1; i LTE ArrayLen( packages ); i=i+1 ){
					package = collection.getPackage( packages[i] );

					if ( packages[i] EQ 'external' and not _getDownloadExternals() ){
						minifyMode = 'none';
					} else {
						minifyMode = _getMinifyMode();
					}

					_addRenderedIncludeToCache( type, packages[i], package.renderIncludes(
						minification = minifyMode
					) );
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="_cacheRenderedIncludesForFileMode" access="private" returntype="void" output="false">
		<cfargument name="debug" type="boolean" required="false" default="false" />

		<cfscript>
			var types      = ListToArray("js,css");
			var type       = "";
			var collection = "";
			var packages   = "";
			var package    = "";
			var files      = "";
			var file       = "";
			var i          = 0;
			var n          = 0;
			var x          = 0;
			var minified   = iif( debug, DE( false ), DE( _getMinifyMode() EQ 'file' ) );

			for( n=1; n LTE ArrayLen( types ); n=n+1 ){
				type = types[n];

				if ( type EQ 'js' ) {
					collection = _getJsPackages();
				} else {
					collection = _getCssPackages();
				}
				packages = collection.getOrdered();
				for( i=1; i LTE ArrayLen( packages ); i=i+1 ){
					package = collection.getPackage( packages[i] );
					files   = package.getOrdered();

					for( x=1; x LTE ArrayLen( files ); x=x+1 ) {
						file        = package.getStaticFile( files[x] );

						_addRenderedIncludeToCache(
							  type     = type
							, path     = files[x]
							, debug    = debug
							, rendered = file.renderInclude(
								minified  = minified and ( packages[i] neq 'external' or _getDownloadExternals() )
							)
						);
					}
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="_getFileState" access="private" returntype="string" output="false">
		<cfscript>
			var jsDir             = $listAppend( _getRootDirectory(), _getJsDirectory() , '/' );
			var cssDir            = $listAppend( _getRootDirectory(), _getCssDirectory(), '/' );
			var jsFiles           = $directoryList( jsDir  );
			var cssFiles          = $directoryList( cssDir );
			var jsDependencyFile  = $ensureFullFilePath( _getJsDependencyFile() );
			var cssDependencyFile = $ensureFullFilePath( _getJsDependencyFile() );
			var state             = StructNew();
			var ext               = "";
			var path              = "";
			var i                 = 0;
			var included          = "";

			for( i=1; i LTE jsFiles.recordCount; i++ ){
				ext      = ListLast( jsFiles.name[i], '.' );
				path     = $normalizeUnixAndWindowsPaths( $listAppend( jsFiles.directory[i], jsFiles.name[i], '/' ) );
				included = ListFindNoCase( "js,coffee", ext ) and $shouldFileBeIncluded( path, _getIncludePattern(), _getExcludePattern() );
				if ( included ) {
					state[path] = jsFiles.dateLastModified[i];
				}
			}

			for( i=1; i LTE cssFiles.recordCount; i++ ){
				ext      = ListLast( cssFiles.name[i], '.' );
				path     = $normalizeUnixAndWindowsPaths( $listAppend( cssFiles.directory[i], cssFiles.name[i], '/' ) );
				included = ListFindNoCase( "css,less", ext ) and $shouldFileBeIncluded( path, _getIncludePattern(), _getExcludePattern() );
				if ( included ) {
					state[path] = cssFiles.dateLastModified[i];
				}
			}

			if ( Len( Trim( jsDependencyFile ) ) and FileExists( jsDependencyFile ) ) {
				state[ jsDependencyFile ] = $fileLastModified( jsDependencyFile );
			}
			if ( Len( Trim( cssDependencyFile ) ) and FileExists( cssDependencyFile ) ) {
				state[ cssDependencyFile ] = $fileLastModified( cssDependencyFile );
			}



			return Hash( SerializeJson( state ) );
		</cfscript>
	</cffunction>

	<cffunction name="_filesHaveChanged" access="private" returntype="boolean" output="false">
		<cfreturn _getFileStateCache() NEQ _getFileState() />
	</cffunction>


	<cffunction name="_loadCompilers" access="private" returntype="void" output="false" hint="I instantiate all the compilers used by cfstatic">
		<cfargument name="javaLoaderScope" type="string" required="false" default="server" hint="The scope should the compilers be persisted">

		<cfscript>
			var jlScope    = server;
			var jlScopeKey = "_cfstaticJavaLoaders_v2";

			if ( javaLoaderScope EQ 'application' ){
			    jlScope = application;
			}

			if ( not StructKeyExists( jlScope, jlScopeKey ) ) {
				jlScope[ jlScopeKey ] = _loadJavaLoaders();
			}

			_setYuiCompressor         ( CreateObject('component','org.cfstatic.util.YuiCompressor'       ).init( jlScope[jlScopeKey].yui                                      ) );
			_setLessCompiler          ( CreateObject('component','org.cfstatic.util.LessCompiler'        ).init( jlScope[jlScopeKey].less                                     ) );
			_setCoffeeScriptCompiler  ( CreateObject('component','org.cfstatic.util.CoffeeScriptCompiler').init( jlScope[jlScopeKey].coffee                                   ) );
			_setCssImageParser        ( CreateObject('component','org.cfstatic.util.CssImageParser'      ).init( _getCssUrl(), $listAppend(_getRootDirectory(), _getCssDirectory(), '/' ) ) );
		</cfscript>
	</cffunction>

	<cffunction name="_loadJavaLoaders" access="private" output="false">
		<cfscript>
			var jarsForYui          = ArrayNew(1);
			var jarsForLess         = ArrayNew(1);
			var jarsForCoffee       = ArrayNew(1);
			var cfstaticJavaloaders = StructNew();

			jarsForYui[1]    = ExpandPath('/org/cfstatic/lib/yuiCompressor/yuicompressor-2.4.7.jar');
			jarsForYui[2]    = ExpandPath('/org/cfstatic/lib/cfstatic.jar');
			jarsForLess[1]   = ExpandPath('/org/cfstatic/lib/less/lesscss-engine-1.4.2.jar');
			jarsForCoffee[1] = ExpandPath('/org/cfstatic/lib/jcoffeescript/jcoffeescript-1.3.3.jar');

			cfstaticJavaloaders.yui    = CreateObject('component','org.cfstatic.lib.javaloader.JavaLoader').init( jarsForYui    );
			cfstaticJavaloaders.less   = CreateObject('component','org.cfstatic.lib.javaloader.JavaLoader').init( jarsForLess   );
			cfstaticJavaloaders.coffee = CreateObject('component','org.cfstatic.lib.javaloader.JavaLoader').init( jarsForCoffee );

		 	return cfstaticJavaloaders;
		</cfscript>
	</cffunction>

	<cffunction name="_compileCssAndJavascript" access="private" returntype="void" output="false" hint="I instantiate the compiling of static files, using different methods depending on the value of the 'minifyMode' config option (passed to the constructor)">
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
			var cssDir          = $listAppend(_getRootdirectory(), _getCssdirectory(), '/');
			var files           = $directoryList(cssDir, '*.less');
			var globalsModified = _getLessGlobalsLastModified();
			var i               = 0;
			var file            = "";
			var target          = "";
			var compiled        = "";
			var needsCompiling  = "";
			var lastModified    = "";

			for( i=1; i LTE files.recordCount; i++ ){
				file = $normalizeUnixAndWindowsPaths( $listAppend( files.directory[i], files.name[i], '/') );
				if ( $shouldFileBeIncluded( file, _getIncludePattern(), _getExcludePattern() ) ){
					target         = file & '.css';
					lastModified   = $fileLastModified(target);
					needsCompiling = ( _getForceCompilation() or not fileExists(target) or lastModified LT globalsModified or lastModified LT $fileLastModified(file) );
					if ( needsCompiling ){
						compiled = _getLesscompiler().compile( file, _getLessGlobals() );

						$fileWrite( target, compiled, _getOutputCharset() );
					}
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="_compileCoffeeScript" access="public" returntype="void" output="false">
		<cfscript>
			var jsDir           = $listAppend(_getRootdirectory(), _getJsdirectory(), '/');
			var files           = $directoryList(jsDir, '*.coffee');
			var i               = 0;
			var file            = "";
			var target          = "";
			var compiled        = "";
			var needsCompiling  = "";

			for( i=1; i LTE files.recordCount; i++ ){
				file = $normalizeUnixAndWindowsPaths( $listAppend(files.directory[i], files.name[i], '/') );
				if ( $shouldFileBeIncluded( file, _getIncludePattern(), _getExcludePattern() ) ){
					target         = file & '.js';
					needsCompiling = ( _getForceCompilation() or not fileExists(target) or $fileLastModified(target) LT $fileLastModified(file) );
					if ( needsCompiling ){
						compiled = _getCoffeeScriptCompiler().compile( file );

						$fileWrite( target, Trim(compiled), _getOutputCharset() );
					}
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
			var content		= $getStringBuffer();
			var i			= "";
			var n			= "";
			var filePath	= "";
			var fileName	= "";

			if ( _compilationNecessary(_getJsPackages() ) ) {
				packages = _getJsPackages().getOrdered();
				for( i=1; i LTE ArrayLen( packages ); i++ ){
					if ( _getDownloadexternals() OR packages[i] NEQ 'external' ) {
						package = _getJsPackages().getPackage(packages[i]);
						files	= package.getOrdered();

						for( n=1; n LTE ArrayLen(files); n++ ){
							file = package.getStaticFile( files[n] );
							content.append( _compileJsFile( file ) );
						}
					}
				}

				fileName = _getJsPackages().getMinifiedFileName();
				filePath = $listAppend( _getOutputDirectory(), filename, '/' );
				$fileWrite( filePath, content.toString(), _getOutputCharset() );
			}

			content	= $getStringBuffer();
			if ( _compilationNecessary(_getCssPackages() ) ) {
				packages = _getCssPackages().getOrdered();
				for( i=1; i LTE ArrayLen(packages); i++ ){
					package	= _getCssPackages().getPackage(packages[i]);
					files	= package.getOrdered();

					for( n=1; n LTE ArrayLen(files); n++ ){
						file = package.getStaticFile( files[n] );
						content.append( _compileCssFile( file ) );
					}
				}

				fileName = _getCssPackages().getMinifiedFileName();
				filePath = $listAppend( _getOutputDirectory(), filename, '/' );
				$fileWrite( filePath, content.toString(), _getOutputCharset() );
			}

			$directoryClean( directory=_getOutputDirectory(), excludeFiles=ListAppend( _getJsPackages().getMinifiedFileName(), _getCssPackages().getMinifiedFileName() ), fileTypes="css,js" );
		</cfscript>
	</cffunction>

	<cffunction name="_compilePackages" access="private" returntype="void" output="false" hint="I compile all the js and css files into a single file per package (directory containing files)">
		<cfscript>
			var packages = "";
			var package  = "";
			var files    = "";
			var file     = "";
			var content  = "";
			var i        = "";
			var n        = "";
			var filePath = "";
			var fileName = "";
			var fileList = "";

			packages = _getJsPackages().getOrdered();
			for( i=1; i LTE ArrayLen(packages); i++ ){
				content  = $getStringBuffer();
				package  = _getJsPackages().getPackage( packages[i] );
				fileName = package.getMinifiedFileName();

				if ( ( _getDownloadexternals() OR packages[i] NEQ 'external' ) AND _compilationNecessary( package ) ) {
					files = package.getOrdered();

					for( n=1; n LTE ArrayLen(files); n++ ){
						file = package.getStaticFile( files[n] );
						content.append( _compileJsFile( file ) );
					}

					filePath = $listAppend( _getOutputDirectory(), filename, '/' );
					$fileWrite(filePath, content.toString(), _getOutputCharset() );
				}

				fileList = ListAppend( fileList, package.getMinifiedFileName() );
			}

			packages = _getCssPackages().getOrdered();
			for( i=1; i LTE ArrayLen(packages); i++ ){
				content  = $getStringBuffer();
				package	 = _getCssPackages().getPackage(packages[i]);
				fileName = package.getMinifiedFileName();

				if ( ( _compilationNecessary( package ) ) AND ( _getDownloadexternals() OR packages[i] NEQ 'external' ) ) {
					files = package.getOrdered();

					for( n=1; n LTE ArrayLen(files); n++ ){
						file = package.getStaticFile( files[n] );
						content.append( _compileCssFile( file ) );
					}

					filePath = $listAppend( _getOutputDirectory(), filename, '/' );
					$fileWrite( filePath, content.toString(), _getOutputCharset() );
				}

				fileList = ListAppend( fileList, package.getMinifiedFileName() );
			}

			$directoryClean( directory=_getOutputDirectory(), excludeFiles=fileList, fileTypes="css,js" );
		</cfscript>
	</cffunction>

	<cffunction name="_compileFiles" access="private" returntype="void" output="false" hint="I compile all the js and css files, compiling each single source file as a single compiled file.">
		<cfscript>
			var packages = "";
			var package  = "";
			var files    = "";
			var file     = "";
			var content  = "";
			var i        = "";
			var n        = "";
			var filePath = "";
			var fileName = "";
			var fileList = "";

			packages = _getJsPackages().getOrdered();
			for( i=1; i LTE ArrayLen(packages); i++ ){
				if ( _getDownloadexternals() OR packages[i] NEQ 'external' ) {
					package = _getJsPackages().getPackage(packages[i]);
					files   = package.getOrdered();

					for( n=1; n LTE ArrayLen(files); n++ ){
						file     = package.getStaticFile( files[n] );
						fileName = file.getMinifiedFileName();

						if ( _compilationNecessary( file ) ) {
							content	 = _compileJsFile( file );
							filePath = $listAppend( _getOutputDirectory(), filename, '/' );
							$fileWrite( filePath, content, _getOutputCharset() );
						}
						fileList = ListAppend( fileList, fileName );
					}
				}
			}

			packages = _getCssPackages().getOrdered();
			for( i=1; i LTE ArrayLen(packages); i++ ){
				if ( _getDownloadexternals() OR packages[i] NEQ 'external' ) {
					package = _getCssPackages().getPackage(packages[i]);
					files   = package.getOrdered();

					for( n=1; n LTE ArrayLen(files); n++ ){
						file     = package.getStaticFile( files[n] );
						fileName = file.getMinifiedFileName();

						if ( _compilationNecessary( file ) ) {
							content  = _compileCssFile( file );
							filePath = $listAppend( _getOutputDirectory(), filename, '/' );
							$fileWrite( filePath, content, _getOutputCharset() );
						}
						fileList = ListAppend( fileList, fileName );
					}
				}
			}

			$directoryClean( directory=_getOutputDirectory(), excludeFiles=fileList, fileTypes="js,css" );
		</cfscript>
	</cffunction>

	<cffunction name="_compileJsFile" access="private" returntype="string" output="false" hint="I compile a single js file, returning the compiled string">
		<cfargument name="file" type="org.cfstatic.core.StaticFile" required="true" hint="The staticFile object representing the javascript file to compile" />

		<cfscript>
			var alreadyMinified = file.getProperty('minified', 'false', 'string');

			if ( alreadyMinified ) {
				return file.getContent();
			}

			return _getYuiCompressor().compressJs( file.getContent() );
		</cfscript>
    </cffunction>

	<cffunction name="_compileCssFile" access="private" returntype="string" output="false" hint="I compile a single css file, returning the compiled string">
		<cfargument name="file" type="org.cfstatic.core.StaticFile" required="true" hint="The staticFile object representing the css file to compile" />

		<cfscript>
			var content         = file.getContent();
			var alreadyMinified = file.getProperty('minified', 'false', 'string');

			if ( not alreadyMinified ) {
				content = _getYuiCompressor().compressCss( content );
			}
			content	= _getCssImageParser().parse(
				  source           = content
				, filePath         = file.getPath()
				, embedImagesRegex = _getEmbedCssImages()
				, addCachebusters  = _getAddImageCacheBusters()
			);

			return content;
		</cfscript>
    </cffunction>

	<cffunction name="_compilationNecessary" access="private" returntype="boolean" output="false" hint="I calculate whether or not compilation is neccessary for the given file, package or packageCollection object. The desicion is based on the presence of a compiled file and the last modified dates of the compiled file and source files. Compilation can also be forced with the forceCompilation config option.">
		<cfargument name="collectionPackageOrFile" type="any" required="true" hint="This could be either a staticFile, package or packageCollection" />

		<cfscript>
			var minFile = $listAppend( _getOutputDirectory(), collectionPackageOrFile.getMinifiedFileName(), '/' );

			if ( _getForceCompilation() ) {
				return true;
			}

			if ( not fileExists(minFile) ) {
				return true;
			}

			return $fileLastModified( minFile ) LT collectionPackageOrFile.getLastModified();
		</cfscript>
	</cffunction>

	<cffunction name="_renderRequestData" access="private" returntype="string" output="false" hint="I render any data set for the request as a javascript variable">
		<cfscript>
			var data = _getRequestData();
			if ( StructIsEmpty(data) ) {
				return "";
			}

			return '<script type="text/javascript">var #_getJsDataVariable()# = #SerializeJson(data)#</script>' & $newline();
		</cfscript>
    </cffunction>

	<cffunction name="_setRequestIncludes" access="private" returntype="void" output="false" hint="I set the array of includes for this request">
		<cfargument name="requestIncludes" required="true" type="array" />
		<cfset request['_cfstaticIncludes'] = requestIncludes />
	</cffunction>
	<cffunction name="_getRequestIncludes" access="private" returntype="array" output="false" hint="I get the array of includes for this request">
		<cfscript>
			if ( not StructKeyExists(request, '_cfstaticIncludes') ) {
				_setupRequest();
			}

			return request['_cfstaticIncludes'];
		</cfscript>
	</cffunction>

	<cffunction name="_setRequestData" access="private" returntype="void" output="false" hint="I set the structure of data to be rendered as javascript variables for this request">
    	<cfargument name="requestData" type="struct" required="true" />
    	<cfset request['_cfstaticData'] = requestData />
    </cffunction>
	<cffunction name="_getRequestData" access="private" returntype="struct" output="false" hint="I get the structure of data to be rendered as javascript variables for this request">
    	<cfscript>
    		if ( not StructKeyExists(request, '_cfstaticData') ) {
				_setupRequest();
			}

			return request['_cfstaticData'];
		</cfscript>
    </cffunction>

	<cffunction name="_setupRequest" access="public" returntype="void" output="false" hint="I setup all the skeleton data for a new request. I also check to see whether or not we should attempt to recompile all the static files (dev mode)">
		<cfscript>
			_setRequestIncludes( ArrayNew(1) );
			_setRequestData    ( StructNew() );

			if ( _getCheckForUpdates() and _filesHaveChanged() ) {
				_processStaticFiles();
			}
		</cfscript>
    </cffunction>

    <cffunction name="_clearRequestData" access="private" returntype="void" output="false">
    	<cfargument name="type" type="string" required="true" />

    	<cfscript>
    		var includes   = _getRequestIncludes();
    		var i          = 0;
    		var rootDir    = '/' & iif( type EQ 'css', DE( _getCssDirectory() ), DE( _getJsDirectory() ) ) & '/';
    		var rootDirLen = Len( rootDir );

    		if ( type EQ 'js' ) {
    			_setRequestData( StructNew() );
    		}

    		for( i=ArrayLen( includes ); i GTE 1 ; i=i-1 ){
    			if ( Left( includes[i], rootDirLen ) EQ rootDir ) {
    				ArrayDeleteAt( includes, i );
    			}
    		}

    		_setRequestIncludes( includes );
    	</cfscript>
    </cffunction>

    <cffunction name="_appendFileTypesToSpecialIncludes" access="private" returntype="string" output="false">
    	<cfargument name="includedFile" type="string" required="true" />

    	<cfscript>
    		var ext = ListLast( includedFile, '.' );

    		switch( ext ){
    			case "less"   : return includedFile & '.css';
    			case "coffee" : return includedFile & '.js';
    		}

    		return includedFile;
    	</cfscript>
    </cffunction>

    <cffunction name="_chainable" access="private" returntype="any" output="false">
    	<cfreturn this />
    </cffunction>

    <cffunction name="_anythingToRender" access="private" returntype="boolean" output="false">
    	<cfargument name="filters" type="array" required="true" />

    	<cfreturn _getIncludeAllByDefault() or ArrayLen( filters ) />
    </cffunction>

    <cffunction name="_getDependenciesFromFile" access="private" returntype="struct" output="false">
    	<cfargument name="type" type="string" required="true" hint="js|css" />

    	<cfscript>
    		var dependencyFile = "";
    		var dependencies   = StructNew();
    		var rootDir        = "";

    		if ( type eq 'css' ) {
    			dependencyFile = _getCssDependencyFile();
    			rootDir        = $ListAppend( _getRootDirectory(), _getCssdirectory(), '/' );
    		} else {
    			dependencyFile = _getJsDependencyFile();
    			rootDir        = $ListAppend( _getRootDirectory(), _getJsdirectory(), '/' );
    		}

    		if ( Len(Trim( dependencyFile ) ) ) {
    			dependencies = CreateObject( 'component', 'org.cfstatic.util.DependencyFileParser' ).parse( dependencyFile, rootDir );
    		}

    		return dependencies;
    	</cfscript>
    </cffunction>

    <cffunction name="_setupRenderedIncludeCache" access="private" returntype="void" output="false">
    	<cfscript>
    		_renderedIncludeCache     = StructNew();
    		_renderedIncludeCache.js  = StructNew();
    		_renderedIncludeCache.css = StructNew();

    		_renderedIncludeCache.debug = StructNew();
    		_renderedIncludeCache.debug.js  = StructNew();
    		_renderedIncludeCache.debug.css = StructNew();

    		_renderedIncludeCache.js['_ordered']        = ArrayNew(1);
    		_renderedIncludeCache.css['_ordered']       = ArrayNew(1);
    		_renderedIncludeCache.debug.js['_ordered']  = ArrayNew(1);
    		_renderedIncludeCache.debug.css['_ordered'] = ArrayNew(1);
    	</cfscript>
    </cffunction>

    <cffunction name="_addRenderedIncludeToCache" access="private" returntype="void" output="false">
    	<cfargument name="type"     type="string"  required="true"                  />
    	<cfargument name="path"     type="string"  required="true"                  />
    	<cfargument name="rendered" type="string"  required="true"                  />
    	<cfargument name="debug"    type="boolean" required="false" default="false" />

    	<cfscript>
    		var node = "";
    		if ( debug ) {
    			node = _renderedIncludeCache.debug[ type ];
    		} else {
    			node = _renderedIncludeCache[ type ];
    		}

    		ArrayAppend( node['_ordered'], rendered );
    		node[ path ] = ArrayLen( node['_ordered'] );
    	</cfscript>
    </cffunction>

    <cffunction name="_getRenderedIncludeCache" access="private" returntype="struct" output="false">
    	<cfargument name="type"  type="string"  required="true"                  />
    	<cfargument name="debug" type="boolean" required="false" default="false" />

    	<cfscript>
    		if ( debug ) {
    			return _renderedIncludeCache.debug[ type ];
    		}

    		return _renderedIncludeCache[ type ];
    	</cfscript>
    </cffunction>

    <cffunction name="_isDebugOnForRequest" access="private" returntype="boolean" output="false">

    	<cfscript>
    		// configured (permanent) debugging
    		if ( _getDebug() ) {
    			return true;
    		}

    		// request level debugging
    		if ( _getDebugAllowed() ) {
    			return StructKeyExists(url, _getDebugKey()) and url[_getDebugKey()] EQ _getDebugPassword();
    		}

    		return false;
    	</cfscript>
    </cffunction>

<!--- plain old instance property accessors (private) --->
	<cffunction name="_getRootDirectory" access="private" returntype="string" output="false">
    	<cfreturn _rootDirectory />
    </cffunction>
    <cffunction name="_setRootDirectory" access="private" returntype="void" output="false">
    	<cfargument name="rootDirectory" type="string" required="true" />
    	<cfset _rootDirectory = rootDirectory />
    </cffunction>

	<cffunction name="_setJsDirectory" access="private" returntype="void" output="false">
		<cfargument name="jsDirectory" required="true" type="string" />
		<cfset _jsDirectory = jsDirectory />
	</cffunction>
	<cffunction name="_getJsDirectory" access="private" returntype="string" output="false">
		<cfreturn _jsDirectory />
	</cffunction>

	<cffunction name="_setJsUrl" access="private" returntype="void" output="false">
		<cfargument name="jsUrl" required="true" type="string" />
		<cfset _jsUrl = jsUrl />
	</cffunction>
	<cffunction name="_getJsUrl" access="private" returntype="string" output="false">
		<cfreturn _jsUrl />
	</cffunction>

	<cffunction name="_setCssDirectory" access="private" returntype="void" output="false">
		<cfargument name="cssDirectory" required="true" type="string" />
		<cfset _cssDirectory = cssDirectory />
	</cffunction>
	<cffunction name="_getCssDirectory" access="private" returntype="string" output="false">
		<cfreturn _cssDirectory />
	</cffunction>

	<cffunction name="_setCssUrl" access="private" returntype="void" output="false">
		<cfargument name="cssUrl" required="true" type="string" />
		<cfset _cssUrl = cssUrl />
	</cffunction>
	<cffunction name="_getCssUrl" access="private" returntype="string" output="false">
		<cfreturn _cssUrl />
	</cffunction>

	<cffunction name="_setOutputDirectory" access="private" returntype="void" output="false">
		<cfargument name="outputDirectory" required="true" type="string" />

		<cfscript>
			if ( not directoryExists( outputDirectory ) ) {
				try {
					$directoryCreate( outputDirectory );
				} catch( "java.io.IOException" e ) {
					$throw(  type    = "org.cfstatic.CfStatic.badOutputDir"
					       , message = "The output directory, '#outputDirectory#', does not exist and could not be created by CfStatic."
					       , detail  = e.detail
					);

				} catch( Application e ) {
					if ( e.message EQ "The specified directory #outputDirectory# could not be created." ) {
						failed = true;

						$throw(  type    = "org.cfstatic.CfStatic.badOutputDir"
						       , message = "The output directory, '#outputDirectory#', does not exist and could not be created by CfStatic."
						       , detail  = e.detail
						);
					}
				}
			}

			_outputDirectory = outputDirectory;
		</cfscript>
	</cffunction>
	<cffunction name="_getOutputDirectory" access="private" returntype="string" output="false">
		<cfreturn _outputDirectory />
	</cffunction>

	<cffunction name="_setMinifiedUrl" access="private" returntype="void" output="false">
		<cfargument name="minifiedUrl" required="true" type="string" />
		<cfset _minifiedUrl = minifiedUrl />
	</cffunction>
	<cffunction name="_getMinifiedUrl" access="private" returntype="string" output="false">
		<cfreturn _minifiedUrl />
	</cffunction>

	<cffunction name="_setMinifyMode" access="private" returntype="void" output="false">
		<cfargument name="minifyMode" required="true" type="string" />
		<cfset _minifyMode = minifyMode />
	</cffunction>
	<cffunction name="_getMinifyMode" access="private" returntype="string" output="false">
		<cfreturn _minifyMode />
	</cffunction>

	<cffunction name="_setDownloadExternals" access="private" returntype="void" output="false">
		<cfargument name="downloadExternals" required="true" type="boolean" />
		<cfset _downloadExternals = downloadExternals />
	</cffunction>
	<cffunction name="_getDownloadExternals" access="private" returntype="boolean" output="false">
		<cfreturn _downloadExternals />
	</cffunction>

	<cffunction name="_setDebugAllowed" access="private" returntype="void" output="false">
		<cfargument name="debugAllowed" required="true" type="boolean" />
		<cfset _debugAllowed = debugAllowed />
	</cffunction>
	<cffunction name="_getDebugAllowed" access="private" returntype="boolean" output="false">
		<cfreturn _debugAllowed />
	</cffunction>

	<cffunction name="_setDebugKey" access="private" returntype="void" output="false">
		<cfargument name="debugKey" required="true" type="string" />
		<cfset _debugKey = debugKey />
	</cffunction>
	<cffunction name="_getDebugKey" access="private" returntype="string" output="false">
		<cfreturn _debugKey />
	</cffunction>

	<cffunction name="_setDebugPassword" access="private" returntype="void" output="false">
		<cfargument name="debugPassword" required="true" type="string" />
		<cfset _debugPassword = debugPassword />
	</cffunction>
	<cffunction name="_getDebugPassword" access="private" returntype="string" output="false">
		<cfreturn _debugPassword />
	</cffunction>

	<cffunction name="_getDebug" access="private" returntype="boolean" output="false">
		<cfreturn _debug>
	</cffunction>
	<cffunction name="_setDebug" access="private" returntype="void" output="false">
		<cfargument name="debug" type="boolean" required="true" />
		<cfset _debug = debug />
	</cffunction>

	<cffunction name="_setForceCompilation" access="private" returntype="void" output="false">
		<cfargument name="forceCompilation" required="true" type="boolean" />
		<cfset _forceCompilation = forceCompilation />
	</cffunction>
	<cffunction name="_getForceCompilation" access="private" returntype="boolean" output="false">
		<cfreturn _forceCompilation />
	</cffunction>

	<cffunction name="_getCheckForUpdates" access="private" returntype="boolean" output="false">
    	<cfreturn _checkForUpdates />
    </cffunction>
    <cffunction name="_setCheckForUpdates" access="private" returntype="void" output="false">
    	<cfargument name="checkForUpdates" type="boolean" required="true" />
    	<cfset _checkForUpdates = checkForUpdates />
    </cffunction>

	<cffunction name="_setJsPackages" access="private" returntype="void" output="false">
		<cfargument name="jsPackages" required="true" type="org.cfstatic.core.PackageCollection" />
		<cfset _jsPackages = jsPackages />
	</cffunction>
	<cffunction name="_getJsPackages" access="private" returntype="org.cfstatic.core.PackageCollection" output="false">
		<cfreturn _jsPackages />
	</cffunction>

	<cffunction name="_setCssPackages" access="private" returntype="void" output="false">
		<cfargument name="cssPackages" required="true" type="org.cfstatic.core.PackageCollection" />
		<cfset _cssPackages = cssPackages />
	</cffunction>
	<cffunction name="_getCssPackages" access="private" returntype="org.cfstatic.core.PackageCollection" output="false">
		<cfreturn _cssPackages />
	</cffunction>

	<cffunction name="_getThrowOnMissingInclude" access="private" returntype="boolean" output="false">
		<cfreturn _throwOnMissingInclude>
	</cffunction>
	<cffunction name="_setThrowOnMissingInclude" access="private" returntype="void" output="false">
		<cfargument name="throwOnMissingInclude" type="boolean" required="true" />
		<cfset _throwOnMissingInclude = arguments.throwOnMissingInclude />
	</cffunction>

	<cffunction name="_clearPackageObjects" access="private" returntype="void" output="false">
		<cfscript>
			_jsPackages  = "";
			_cssPackages = "";
		</cfscript>
	</cffunction>

	<cffunction name="_getPackage" access="private" returntype="any" output="false">
		<cfargument name="packageName" type="string" required="true" />
		<cfargument name="packageType" type="string" required="true" />

		<cfscript>
			var pkgCollection = "";
			if ( packageType EQ 'css' ) {
				pkgCollection = _getCssPackages();
			} else {
				pkgCollection = _getJsPackages();
			}

			return pkgCollection.getPackage( packageName );
		</cfscript>
	</cffunction>

	<cffunction name="_setYuiCompressor" access="private" returntype="void" output="false">
		<cfargument name="yuiCompressor" required="true" type="any" />
		<cfset _yuiCompressor = yuiCompressor />
	</cffunction>
	<cffunction name="_getYuiCompressor" access="private" returntype="any" output="false">
		<cfreturn _yuiCompressor />
	</cffunction>

	<cffunction name="_setLessCompiler" access="private" returntype="void" output="false">
		<cfargument name="lessCompiler" required="true" type="any" />
		<cfset _lessCompiler = lessCompiler />
	</cffunction>
	<cffunction name="_getLessCompiler" access="private" returntype="any" output="false">
		<cfreturn _lessCompiler />
	</cffunction>

	<cffunction name="_getCoffeeScriptCompiler" access="private" returntype="any" output="false">
		<cfreturn _CoffeeScriptCompiler>
	</cffunction>
	<cffunction name="_setCoffeeScriptCompiler" access="private" returntype="void" output="false">
		<cfargument name="CoffeeScriptCompiler" type="any" required="true" />
		<cfset _CoffeeScriptCompiler = CoffeeScriptCompiler />
	</cffunction>

	<cffunction name="_setCssImageParser" access="private" returntype="void" output="false">
		<cfargument name="cssImageParser" required="true" type="any" />
		<cfset _cssImageParser = cssImageParser />
	</cffunction>
	<cffunction name="_getCssImageParser" access="private" returntype="any" output="false">
		<cfreturn _cssImageParser />
	</cffunction>

	<cffunction name="_setIncludeMappings" access="private" returntype="void" output="false">
		<cfargument name="includeMappings" required="true" type="struct" />
		<cfargument name="type" type="string" required="true" />

		<cfset _includeMappings[type] = includeMappings />
	</cffunction>
	<cffunction name="_getIncludeMappings" access="private" returntype="struct" output="false">
		<cfargument name="type" type="string" required="true" />
		<cfreturn _includeMappings[type] />
	</cffunction>

	<cffunction name="_getAddCacheBusters" access="private" returntype="boolean" output="false">
		<cfreturn _addCacheBusters />
	</cffunction>
	<cffunction name="_setAddCacheBusters" access="private" returntype="void" output="false">
		<cfargument name="addCacheBusters" type="boolean" required="true" />
		<cfset _addCacheBusters = addCacheBusters />
	</cffunction>

	<cffunction name="_getAddImageCacheBusters" access="private" returntype="boolean" output="false">
		<cfreturn _addImageCacheBusters>
	</cffunction>
	<cffunction name="_setAddImageCacheBusters" access="private" returntype="void" output="false">
		<cfargument name="addImageCacheBusters" type="boolean" required="true" />
		<cfset _addImageCacheBusters = arguments.addImageCacheBusters />
	</cffunction>

	<cffunction name="_getIncludeAllByDefault" access="private" returntype="boolean" output="false">
		<cfreturn _includeAllByDefault />
	</cffunction>
	<cffunction name="_setIncludeAllByDefault" access="private" returntype="void" output="false">
		<cfargument name="includeAllByDefault" type="boolean" required="true" />
		<cfset _includeAllByDefault = includeAllByDefault />
	</cffunction>

	<cffunction name="_getEmbedCssImages" access="private" returntype="string" output="false">
		<cfreturn _embedCssImages />
	</cffunction>
	<cffunction name="_setEmbedCssImages" access="private" returntype="void" output="false">
		<cfargument name="embedCssImages" type="string" required="true" />
		<cfset _embedCssImages = embedCssImages />
	</cffunction>

	<cffunction name="_getIncludePattern" access="private" returntype="string" output="false">
		<cfreturn _includePattern />
	</cffunction>
	<cffunction name="_setIncludePattern" access="private" returntype="void" output="false">
		<cfargument name="includePattern" type="string" required="true" />
		<cfset _includePattern = includePattern />
	</cffunction>

	<cffunction name="_getExcludePattern" access="private" returntype="string" output="false">
		<cfreturn _excludePattern />
	</cffunction>
	<cffunction name="_setExcludePattern" access="private" returntype="void" output="false">
		<cfargument name="excludePattern" type="string" required="true" />
		<cfset _excludePattern = excludePattern />
	</cffunction>

	<cffunction name="_getOutputCharset" access="private" returntype="any" output="false">
		<cfreturn _outputCharset />
	</cffunction>
	<cffunction name="_setOutputCharset" access="private" returntype="void" output="false">
		<cfargument name="outputCharset" type="any" required="true" />
		<cfset _outputCharset = outputCharset />
	</cffunction>

	<cffunction name="_getJsDataVariable" access="private" returntype="any" output="false">
		<cfreturn _JsDataVariable>
	</cffunction>
	<cffunction name="_setJsDataVariable" access="private" returntype="void" output="false">
		<cfargument name="JsDataVariable" type="any" required="true" />
		<cfset _JsDataVariable = JsDataVariable />
	</cffunction>

	<cffunction name="_getJsDependencyFile" access="private" returntype="string" output="false">
		<cfreturn _JsDependencyFile>
	</cffunction>
	<cffunction name="_setJsDependencyFile" access="private" returntype="void" output="false">
		<cfargument name="JsDependencyFile" type="string" required="true" />
		<cfset _JsDependencyFile = JsDependencyFile />
	</cffunction>

	<cffunction name="_getCssDependencyFile" access="private" returntype="string" output="false">
		<cfreturn _cssDependencyFile>
	</cffunction>
	<cffunction name="_setCssDependencyFile" access="private" returntype="void" output="false">
		<cfargument name="cssDependencyFile" type="string" required="true" />
		<cfset _cssDependencyFile = cssDependencyFile />
	</cffunction>

	<cffunction name="_getFileStateCache" access="private" returntype="string" output="false">
		<cfreturn _fileStateCache />
	</cffunction>
	<cffunction name="_setFileStateCache" access="private" returntype="void" output="false">
		<cfargument name="fileStateCache" type="string" required="true" />
		<cfset _fileStateCache = fileStateCache />
	</cffunction>

	<cffunction name="_getLessGlobals" access="private" returntype="string" output="false">
		<cfreturn _lessGlobals>
	</cffunction>

	<cffunction name="_setLessGlobals" access="private" returntype="void" output="false">
		<cfargument name="lessGlobals" type="string" required="true" />
		<cfset _lessGlobals = $normalizeUnixAndWindowsPaths( lessGlobals ) />
	</cffunction>

	<cffunction name="_clearoutTemporaryLessFiles" access="private" returntype="void" output="false">
		<cfscript>
			var cssDir = $listAppend(_getRootdirectory(), _getCssdirectory(), '/');
			var files  = $directoryList( cssDir, '*.less' );
			var file   = "";
			var i      = "";

			for( i=1; i LTE files.recordCount; i++ ){
				file = $normalizeUnixAndWindowsPaths( $listAppend( files.directory[i], files.name[i], '/') );
				if ( $isTemporaryFileName( file ) ) {
					$fileDelete( file );
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="_scanForImportedLessFiles" access="private" returntype="any" output="false">
		<cfscript>
			var cssDir        = $listAppend(_getRootdirectory(), _getCssdirectory(), '/');
			var files         = $directoryList(cssDir, '*.less');
			var globals       = ListToArray( _getLessGlobals() );
			var i             = 0;
			var file          = "";
			var imports       = "";
			var importStruct  = "";


			for( i=1; i LTE files.recordCount; i++ ){
				file    = $normalizeUnixAndWindowsPaths( $listAppend( files.directory[i], files.name[i], '/') );
				if ( not $isTemporaryFileName( file ) ) {
					imports = ListAppend( imports, _readLessImports( file ) );
				}
			}

			for( i=1; i LTE ArrayLen(globals); i++ ) {
				imports = ListAppend( imports, _readLessImports( globals[i] ) );
			}

			_lessImports = $uniqueList( imports );
		</cfscript>
	</cffunction>

	<cffunction name="_readLessImports" access="private" returntype="string" output="false">
		<cfargument name="filePath" type="string" required="true" />

		<cfscript>
			var searchResults = "";
			var imports       = "";
			var importPath    = "";
			var i             = 0;

			if ( fileExists( filePath ) ){
				searchResults = $reSearch( '@import url\((.+?)\)', $fileRead( filePath ) );

				if ( StructKeyExists( searchResults, "$1" ) ) {
					for( i=1; i LTE ArrayLen(searchResults.$1); i++){
						importPath = Replace( searchResults.$1[i], '"', '', 'all' );
						importPath = Replace( importPath, "'", '', 'all' );
						importPath = getDirectoryFromPath(filePath) & Trim(importPath);
						imports = ListAppend(imports, importPath);
						imports = ListAppend(imports, _readLessImports(importPath));
					}
				}
			}

			return imports;
		</cfscript>
	</cffunction>

	<cffunction name="_getLessGlobalsLastModified" access="private" returntype="date" output="false">
		<cfscript>
			var globals      = ListToArray( ListAppend(_getLessGlobals(), _lessImports) );
			var lastModified = "1900-01-01";
			var fileModified = "";
			var i            = 0;

			for( i=1; i LTE ArrayLen(globals); i++ ) {
				fileModified = $fileLastModified( globals[i] );
				if ( fileModified GT lastModified ){
					lastModified = fileModified;
				}
			}

			return lastModified;
		</cfscript>
	</cffunction>

	<cffunction name="_resourceExists" access="private" returntype="boolean" output="false">
		<cfargument name="resource" type="string" required="true" />

		<cfreturn StructKeyExists( _getIncludeMappings( 'js' ), arguments.resource ) or StructKeyExists( _getIncludeMappings( 'css' ), arguments.resource ) />
	</cffunction>
</cfcomponent>