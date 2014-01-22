<cfcomponent output="false" extends="org.cfstatic.util.Base" hint="I am an abstract representation of a collection of packages (directories). I manage dealing with the collection as one, providing methods such as getting all the content of the packages in the correct order and getting the last modified date of the entire collection.">

<!--- properties --->
	<cfscript>
		_rootDirectory	= "";
		_rootUrl		= "";
		_minifiedUrl	= "";
		_fileType		= "";
		_packages		= StructNew();
		_ordered		= ArrayNew(1);
		_cacheBust      = true;
		_includePattern = ".*";
		_excludePattern = "";
	</cfscript>

<!--- constructor --->
	<cffunction name="init" access="public" returntype="org.cfstatic.core.PackageCollection" output="false" hint="I am the constructor">
		<cfargument name="rootDirectory"  type="string"  required="true" />
		<cfargument name="rootUrl"        type="string"  required="true" />
		<cfargument name="minifiedUrl"    type="string"  required="true" />
		<cfargument name="fileType"       type="string"  required="true" />
		<cfargument name="cacheBust"      type="boolean" required="true" />
		<cfargument name="includePattern" type="string"  required="true" />
		<cfargument name="excludePattern" type="string"  required="true" />
		<cfargument name="dependencies"   type="struct"  required="true" />
		<cfargument name="outputDir"      type="string"  required="true" />

		<cfscript>
			_setRootDirectory ( rootDirectory  );
			_setRootUrl       ( rootUrl        );
			_setMinifiedUrl   ( minifiedUrl    );
			_setFileType      ( fileType       );
			_setCacheBust     ( cacheBust      );
			_setIncludePattern( includePattern );
			_setExcludePattern( excludePattern );

			_loadFromFiles(
				  dependencies = dependencies
				, outputDir    = outputDir
			);

			return this;
		</cfscript>
	</cffunction>

<!--- public methods --->
	<cffunction name="getContent" access="public" returntype="string" output="false" hint="I return the file content of the entire collection, in the correct order.">
		<cfargument name="includeExternals" type="boolean" required="false" default="true" hint="Whether or not to download external dependencies and include them in the returned collection string" />

		<cfscript>
			var str      = $getStringBuffer();
			var packages = getOrdered();
			var i        = 0;

			for( i=1; i LTE ArrayLen(packages); i++ ){
				if ( includeExternals OR packages[i] NEQ 'external' ) {
					str.append( getPackage( packages[i] ).getContent() );
				}
			}

			return str.toString();
		</cfscript>
	</cffunction>

	<cffunction name="renderIncludes" access="public" returntype="string" output="false" hint="I render the collection's html includes">
		<cfargument name="minification"      type="string"  required="true" />
		<cfargument name="downloadExternals" type="boolean" required="true" />
		<cfargument name="includePackages"   type="array"   required="false" default="#ArrayNew(1)#" />
		<cfargument name="includeFiles"      type="array"   required="false" default="#ArrayNew(1)#" />

		<cfscript>
			var str              = $getStringBuffer();
			var included         = false;
			var minify           = "";
			var packages         = "";
			var i                = "";
			var src              = "";
			var media            = "";
			var ie               = "";
			var shouldBeRendered = "";

			switch( minification ){
				case 'none': case 'file': case 'package':
					packages = getOrdered();
					for( i=1; i LTE ArrayLen( packages ); i++ ){
						shouldBeRendered = not ArrayLen( includePackages ) or includePackages.contains( JavaCast('string', packages[i]) );

						if ( shouldBeRendered ) {
							if ( packages[i] EQ 'external' and not downloadExternals ) {
								minify = 'none';
							} else {
								minify = minification;
							}

							str.append( getPackage( packages[i] ).renderIncludes( minification = minify, includeFiles = includeFiles ) );
						}
					}
					break;

				case 'all':
					if ( not downloadExternals and _packageExists('external') ) {
						str.append( getPackage('external').renderIncludes( minification='none' ) );
					}

					src = "#_getMinifiedUrl()#/#getMinifiedFileName()#";
					ie  = _getIeRestriction();

					if ( _getFileType() EQ 'css' ) {
						media = _getCssMedia();
						str.append( $renderCssInclude( src, media, ie ) );
					} else {
						str.append( $renderJsInclude( src, ie ) );
					}
					break;
			}

			return str.toString();
		</cfscript>
	</cffunction>

	<cffunction name="getPackage" access="public" returntype="Package" output="false" hint="I return the package object wihtin the collection with the given package name">
		<cfargument name="packageName" type="string" required="true" />

		<cfreturn _packages[packageName] />
	</cffunction>

	<cffunction name="getOrdered" access="public" returntype="array" output="false" hint="I return an array of package names that are in the correct order based on their dependencies">
		<cfscript>
			if ( ArrayLen( _ordered ) NEQ StructCount( _packages ) ) {
				_orderPackages();
			}

			return _ordered;
		</cfscript>
	</cffunction>

	<cffunction name="getMinifiedFileName" access="public" returntype="string" output="false" hint="I return the name of the file that this collection should use when being minified as a whole">
		<cfscript>
			var filename = "#_getFileType()#.min";

			if ( _getCacheBust() ) {
				filename = $listAppend(filename, Hash( getContent() ), '.');
			}

			return $listAppend( filename, _getFileType(), '.' );
		</cfscript>
	</cffunction>

	<cffunction name="getLastModified" access="public" returntype="date" output="false" hint="I return the last modified date of the entire collection (based on the latest modified date of all the child packages)">
		<cfscript>
			var packages     = getOrdered();
			var fileModified = "";
			var lastModified = "1900-01-01";
			var i            = 0;

			for( i=1; i LTE ArrayLen(packages); i++ ){
				fileModified = getPackage( packages[i] ).getLastModified();

				if ( lastModified LT fileModified ) {
					lastModified = fileModified;
				}
			}

			return lastModified;
		</cfscript>
	</cffunction>

<!--- private methods --->
	<cffunction name="_loadFromFiles" access="private" returntype="void" output="false" hint="I instantiate the collection by looking through all files in the collection's root directory">
		<cfargument name="dependencies" type="struct" required="true" />
		<cfargument name="outputDir"    type="string" required="true" />

		<cfscript>
			var files = $directoryList( _getRootDirectory(), '*.#_getFileType()#' );
			var i     = 0;

			for( i=1; i lte files.recordCount; i++ ){
				if ( $normalizeUnixAndWindowsPaths( files.directory[i] ) neq outputDir ) {
					_addStaticFile(
						  path         = $normalizeUnixAndWindowsPaths( files.directory[i] & '/' & files.name[i] )
					    , dependencies = dependencies
					);
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="_addStaticFile" access="private" returntype="void" output="false" hint="I add a static file to the collection">
		<cfargument name="path"         type="string" required="true" />
		<cfargument name="dependencies" type="struct" required="true" />

		<cfscript>
			var packageName     = "";
			var package         = "";
			var file            = "";

			if ( $shouldFileBeIncluded( path, _getIncludePattern(), _getExcludePattern() ) ) {
				packageName = _getPackageNameFromPath( path );

				if ( not _packageExists( packageName ) ) {
					_addPackage( packageName );
				}
				package = getPackage( packageName );

				if ( not package.staticFileExists( path ) ) {
					package.addStaticFile( path );
					file = package.getStaticFile( path );

					_addDependentFiles( file, dependencies );
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="_addDependentFiles" access="private" returntype="void" output="false">
		<cfargument name="file"         type="any"    required="true" />
		<cfargument name="dependencies" type="struct" required="true" />

		<cfscript>
			var dependencyArray = _getFileDependencies( file, dependencies );
			var dependency      = "";
			var package         = "";
			var i               = "";

			for( i=1; i LTE ArrayLen( dependencyArray ); i++ ){
				dependency = _getFullPathOfFileDependency( dependencyArray[i] );
				package    = _getPackageNameFromPath( dependency );

				try {
					_addStaticFile( dependency, dependencies );
				} catch( application e ) {
					if ( $normalizeUnixAndWindowsPaths( e.message ) contains dependency ) {
						$throw(
							  type    = "org.cfstatic.missingDependency"
							, message = "CFStatic Error: Could not find local dependency."
							, detail  = "The dependency, '#dependencyArray[i]#', could not be found or downloaded. CFStatic is expecting to find it at #dependency#. The dependency is declared in '#file.getPath()#'"
						);
					} else {
						$throw( argumentCollection = e ); // (rethrow)
					}
				}

				file.addDependency( getPackage( package ).getStaticFile( dependency ) );
			}

			_setConditionalDependencies( file, dependencies );
		</cfscript>
	</cffunction>

	<cffunction name="_getFileDependencies" access="private" returntype="array" output="false">
		<cfargument name="file"         type="any"    required="true" />
		<cfargument name="dependencies" type="struct" required="true" />

		<cfscript>
			var dependencyArray = file.getProperty( 'depends', ArrayNew(1), 'array' );
			var path            = file.getPath();

			if ( StructCount( dependencies ) and StructKeyExists( dependencies.regular, path ) ) {
				dependencyArray = $ArrayMerge( dependencyArray, dependencies.regular[ path ] );
			}

			return dependencyArray;
		</cfscript>
	</cffunction>

	<cffunction name="_setConditionalDependencies" access="private" returntype="void" output="false">
		<cfargument name="file"         type="any"    required="true" />
		<cfargument name="dependencies" type="struct" required="true" />

		<cfscript>
			var path = file.getPath();

			if ( StructCount( dependencies ) and StructKeyExists( dependencies.conditional, path ) ) {
				file.setConditionalDependencies( dependencies.conditional[ path ] );
			}
		</cfscript>
	</cffunction>

	<cffunction name="_getFullPathOfFileDependency" access="private" returntype="string" output="false">
		<cfargument name="urlFullOrRelativePath" type="string" required="true" />

		<cfscript>
			var fullPath = "";

			if ( $isUrl( urlFullOrRelativePath ) or _dependencyIsFullPath( urlFullOrRelativePath ) ) {
				fullPath = urlFullOrRelativePath;
			} else {
				fullPath = _getRootdirectory() & urlFullOrRelativePath;
			}

			return $appendCompiledFileTypeToFilePath( Trim( fullPath ) );
		</cfscript>
	</cffunction>

	<cffunction name="_getPackageNameFromPath" access="private" returntype="string" output="false" hint="I calculate a unique package name given a full file path">
		<cfargument name="path"	type="string"	required="true" />

		<cfscript>
			var packageName = "";

			if ( $isUrl( path) ){
				return 'external';
			}

			packageName = $listDeleteLast( ReplaceNoCase(path, _getRootdirectory(), '' ), '/' ) & '/';
			if ( Right( packageName, 1 ) NEQ '/' ) {
				packageName &= '/';
			}
			return packageName;
		</cfscript>
	</cffunction>

	<cffunction name="_newPackage" access="private" returntype="Package" output="false" hint="Instanciates a new package object (for adding to the collection)">
		<cfargument name="packageName" type="string" required="true" />

		<cfscript>
			var rootUrl = _getRootUrl();
			if ( packageName NEQ 'external' ){
				rootUrl = rootUrl & packageName;
			}

			return CreateObject( 'component', 'Package' ).init( packageName, rootUrl, _getMinifiedUrl(), _getFileType(), _getCacheBust() );
		</cfscript>
	</cffunction>

	<cffunction name="_addPackage" access="private" returntype="void" output="false" hint="Adds a package to the collection">
		<cfargument name="packageName" type="string" required="true" />

		<cfset _packages[ packageName ] = _newPackage( packageName ) />
	</cffunction>

	<cffunction name="_packageExists" access="private" returntype="boolean" output="false" hint="I return whether or not the given package exists within the collection">
		<cfargument name="packageName" type="string" required="true" />

		<cfreturn StructKeyExists( _packages, packageName ) />
	</cffunction>

	<cffunction name="_orderPackages" access="private" returntype="void" output="false" hint="I calculate the order of packages, based on their dependencies. I cache this order locally.">
		<cfscript>
			var packages = StructKeyArray( _getPackages() );
			var i		 = "";

			ArraySort( packages, 'text' );
			for( i=1; i LTE ArrayLen(packages); i=i+1 ){
				_addPackageToOrderedList( packages[i] );
			}
		</cfscript>
	</cffunction>

	<cffunction name="_addPackageToOrderedList" access="private" returntype="void" output="false" hint="I am a utility method for ordering packages, adding individual packages, preceded by their dependencies to an array">
		<cfargument name="packageName" type="string" required="true" />

		<cfscript>
			var package      = getPackage( packageName );
			var dependencies = package.getDependencies();
			var i            = 0;

			// first, add any *internal* dependencies
			ArraySort( dependencies, 'text' );

			for( i=1; i LTE ArrayLen( dependencies ); i++ ){
				_addPackageToOrderedList( dependencies[i] );
			}

			// now add the file if not added already
			if ( not ListFind( ArrayToList( _ordered ), packageName ) ) {
				ArrayAppend( _ordered, packageName );
			}
		</cfscript>
	</cffunction>

	<cffunction name="_getIeRestriction" access="private" returntype="string" output="false" hint="I get the Internet explorer version 'restriction' for the entire package collection. All static files within a single package collection should have the same restriction (when minifiying all together), an exception will be thrown otherwise.">
		<cfscript>
			var packages      = getOrdered();
			var ieRestriction = "";
			var i             = 0;

			if ( ArrayLen( packages ) ) {
				ieRestriction = getPackage( packages[1] ).getIeRestriction();
				for( i=2; i LTE ArrayLen(packages); i++ ) {
					if ( ieRestriction NEQ getPackage( packages[i] ).getIeRestriction() ) {
						$throw( type="cfstatic.PackageCollection.badConfig", message="There was an error compiling the #_getFileType()# min file, not all files define the same IE restriction." );
					}
				}
			}

			return ieRestriction;
		</cfscript>
	</cffunction>

	<cffunction name="_getCssMedia" access="private" returntype="string" output="false" hint="I get the target media of the css files entire package collection. All static files within a single package collections should have the same media (when minifiying all together), an exception will be thrown otherwise.">
		<cfscript>
			var packages = getOrdered();
			var media    = "";
			var i        = 0;

			if ( ArrayLen( packages ) ) {
				media = getPackage( packages[1] ).getCssMedia();
				for( i=2; i LTE ArrayLen( packages ); i++ ) {
					if ( media NEQ getPackage( packages[i] ).getCssMedia() ) {
						$throw( type="cfstatic.PackageCollection.badConfig", message="There was an error compiling the #_getFileType()# min file, not all files define the same CSS media." );
					}
				}
			}

			return media;
		</cfscript>
	</cffunction>

	<cffunction name="_dependencyIsFullPath" access="private" returntype="boolean" output="false">
		<cfargument name="dependency" type="string" required="true" />

		<cfscript>
			var rootDir = _getRootDirectory();

			return Left( dependency, Len( rootDir ) ) EQ rootDir;
		</cfscript>
	</cffunction>

<!--- accessors --->
	<cffunction name="_setRootDirectory" access="private" returntype="void" output="false">
		<cfargument name="rootDirectory" required="true" type="string" />
		<cfset _rootDirectory = rootDirectory />
	</cffunction>
	<cffunction name="_getRootDirectory" access="private" returntype="string" output="false">
		<cfreturn _rootDirectory />
	</cffunction>

	<cffunction name="_setRootUrl" access="private" returntype="void" output="false">
		<cfargument name="rootUrl" required="true" type="string" />
		<cfset _rootUrl = rootUrl />
	</cffunction>
	<cffunction name="_getRootUrl" access="private" returntype="string" output="false">
		<cfreturn _rootUrl />
	</cffunction>

	<cffunction name="_setMinifiedUrl" access="private" returntype="void" output="false">
		<cfargument name="minifiedUrl" required="true" type="string" />
		<cfset _minifiedUrl = minifiedUrl />
	</cffunction>
	<cffunction name="_getMinifiedUrl" access="private" returntype="string" output="false">
		<cfreturn _minifiedUrl />
	</cffunction>

	<cffunction name="_setFileType" access="private" returntype="void" output="false">
		<cfargument name="fileType" required="true" type="string" />
		<cfset _fileType = fileType />
	</cffunction>
	<cffunction name="_getFileType" access="private" returntype="string" output="false">
		<cfreturn _fileType />
	</cffunction>

	<cffunction name="_getPackages" access="private" returntype="struct" output="false">
		<cfreturn _packages />
	</cffunction>

	<cffunction name="_getCacheBust" access="private" returntype="boolean" output="false">
		<cfreturn _cacheBust>
	</cffunction>
	<cffunction name="_setCacheBust" access="private" returntype="void" output="false">
		<cfargument name="cacheBust" type="boolean" required="true" />
		<cfset _cacheBust = cacheBust />
	</cffunction>

	<cffunction name="_getIncludePattern" access="private" returntype="string" output="false">
		<cfreturn _includePattern>
	</cffunction>
	<cffunction name="_setIncludePattern" access="private" returntype="void" output="false">
		<cfargument name="includePattern" type="string" required="true" />
		<cfset _includePattern = includePattern />
	</cffunction>

	<cffunction name="_getExcludePattern" access="private" returntype="string" output="false">
		<cfreturn _excludePattern>
	</cffunction>
	<cffunction name="_setExcludePattern" access="private" returntype="void" output="false">
		<cfargument name="excludePattern" type="string" required="true" />
		<cfset _excludePattern = excludePattern />
	</cffunction>

</cfcomponent>