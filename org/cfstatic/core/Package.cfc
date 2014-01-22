<cfcomponent output="false" extends="org.cfstatic.util.Base" hint="I am an abstract representation of a single package, a directory that contains static files that can be packaged together. I provide methods such as getting all the content of the files in the correct order and getting the last modified date of the entire package.">

<!--- properties --->
	<cfscript>
		_staticFiles	= StructNew();
		_ordered		= ArrayNew(1);
		_fileType		= "";
		_packageName	= "";
		_cacheBust		= true;
	</cfscript>

<!--- constructor --->
	<cffunction name="init" access="public" returntype="Package" output="false" hint="I am the constructor">
		<cfargument name="packageName" type="string"  required="true" />
		<cfargument name="rootUrl"     type="string"  required="true" />
		<cfargument name="minifiedUrl" type="string"  required="true" />
		<cfargument name="fileType"    type="string"  required="true" />
		<cfargument name="cacheBust"   type="boolean" required="true" />

		<cfscript>
			_setPackageName( packageName );
			_setRootUrl    ( rootUrl     );
			_setMinifiedUrl( minifiedUrl );
			_setFileType   ( fileType    );
			_setCacheBust  ( cacheBust   );

			return this;
		</cfscript>
	</cffunction>

<!--- public methods --->
	<cffunction name="addStaticFile" access="public" returntype="void" output="false" hint="I add a static file to the package">
		<cfargument name="path" required="true" type="string" />

		<cfset _staticFiles[ path ] = _newStaticfile( path ) />
	</cffunction>

	<cffunction name="getStaticFile" access="public" returntype="StaticFile" output="false" hint="I return the static file object for the given file path">
		<cfargument name="path" required="true" type="string" />

		<cfreturn _staticFiles[ path ] />
	</cffunction>

	<cffunction name="staticFileExists" access="public" returntype="boolean" output="false" hint="I return whether or not the given static file exists within this package">
		<cfargument name="path" required="true" type="string" />

		<cfreturn StructKeyExists( _staticFiles, path ) />
	</cffunction>

	<cffunction name="getDependencies" access="public" returntype="array" output="false" hint="I return an array of other packages (package names) that this package depends on">
		<cfargument name="includeConditionals" type="boolean" required="false" default="true" />

		<cfscript>
			var pkgDependencies  = ArrayNew(1);
			var files            = _getStaticFiles();
			var file             = "";
			var fileDependencies = "";
			var i                = "";

			for( file in files ){
				fileDependencies = files[file].getDependencies( true, includeConditionals );
				for( i=1; i LTE ArrayLen( fileDependencies ); i++ ){
					if ( fileDependencies[i].getPackageName() NEQ _getPackageName() ) {
						if ( not ListFind( ArrayToList( pkgDependencies ), fileDependencies[i].getPackageName() ) ) {
							ArrayAppend( pkgDependencies,  fileDependencies[i].getPackageName() );
						}
					}
				}
			}
			return pkgDependencies;
		</cfscript>
	</cffunction>

	<cffunction name="getContent" access="public" returntype="string" output="false" hint="I return the content of all the static files within this package (in the correct order)">
		<cfscript>
			var str   = $getStringBuffer();
			var files = getOrdered();
			var i     = 0;

			for( i=1; i LTE ArrayLen(files); i++ ){
				str.append( getStaticFile( files[i] ).getContent() );
			}

			return str.toString();
		</cfscript>
	</cffunction>

	<cffunction name="renderIncludes" access="public" returntype="string" output="false" hint="I return the html include string required to include this package">
		<cfargument name="minification" type="string" required="true" hint="Mode of minification, this will effect how the includes are rendered. Either 'package', 'file' or 'none'" />
		<cfargument name="includeFiles" type="array"  required="false" default="#ArrayNew(1)#" hint="Only include the files in this array. If empty, include *all* files." />

		<cfscript>
			var str              = "";
			var files            = "";
			var i                = "";
			var src              = "";
			var media            = "";
			var ie               = "";
			var shouldBeRendered = "";

			switch( minification ){
				case 'none': case 'file':
					str   = $getStringBuffer();
					files = getOrdered();

					for( i=1; i LTE ArrayLen( files ); i++ ){
						shouldBeRendered = not ArrayLen( includeFiles ) or includeFiles.contains( JavaCast('string', files[i] ) );
						if ( shouldBeRendered ) {
							str.append( getStaticFile( files[i] ).renderInclude( minified = (minification EQ 'file') ) );
						}
					}
					return str.toString();

				case 'package':
					src = "#_getMinifiedUrl()#/#getMinifiedFileName()#";
					ie  = getIeRestriction();

					if ( _getFileType() EQ 'css' ) {
						media = getCssMedia();
						return $renderCssInclude( src, media, ie );
					} else {
						return $renderJsInclude( src, ie );
					}
					break;
			}
		</cfscript>
	</cffunction>

	<cffunction name="getLastModified" access="public" returntype="date" output="false" hint="I get the last modified date of the entire package, based on the latest modified date of all the package's files">
		<cfscript>
			var files        = getOrdered();
			var fileModified = "";
			var i            = 0;
			var lastModified = "1900-01-01";

			for( i=1; i LTE ArrayLen(files); i++ ){
				fileModified = getStaticFile( files[i] ).getLastModified();
				if ( lastModified LT fileModified ) {
					lastModified = fileModified;
				}
			}

			return lastModified;
		</cfscript>
	</cffunction>

	<cffunction name="getIeRestriction" access="public" returntype="string" output="false" hint="I get the IE explorer version 'restriction' for the entire package. All static files within a single package should have the same restriction, an exception will be thrown otherwise.">
		<cfscript>
			var files         = getOrdered();
			var ieRestriction = "";
			var i             = 0;

			if ( ArrayLen( files ) ) {
				ieRestriction = getStaticFile( files[1] ).getProperty('ie');
				for( i=2; i LTE ArrayLen(files); i++ ){
					if ( ieRestriction NEQ getStaticFile( files[i] ).getProperty('ie') ) {
						$throw( type="cfstatic.Package.badConfig", message="There was an error compiling the package, '#_getPackageName()#', not all files define the same IE restriction." );
					}
				}
			}

			return ieRestriction;
		</cfscript>
	</cffunction>

	<cffunction name="getCssMedia" access="public" returntype="string" output="false" hint="I get the target media of the css files for the entire package. All static files within a single package should have the same media (when minifiying all together), an exception will be thrown otherwise.">
		<cfscript>
			var files = getOrdered();
			var media = "";
			var i     = 0;

			if ( ArrayLen( files ) ) {
				media = getStaticFile( files[1] ).getProperty( 'media', 'all', 'string' );
				for( i=2; i LTE ArrayLen(files); i++ ){
					if ( media NEQ getStaticFile( files[i] ).getProperty( 'media', 'all', 'string' ) ) {
						$throw( type="cfstatic.Package.badConfig", message="There was an error compiling the package, '#_getPackageName()#', not all files define the same css media" );
					}
				}
			}

			return media;
		</cfscript>
	</cffunction>

	<cffunction name="getMinifiedFileName" access="public" returntype="string" output="false" hint="I get the filename to be used when minifying the entire package">
		<cfscript>
			var filename = "";

			if ( _getPackageName() EQ '/' ) {
				filename = "root.min";
			} else {
				filename = "#ListChangeDelims( _getPackageName(), '.', '/' )#.min";
			}

			if( _getCacheBust() ){
				filename    = $listAppend(filename, Hash( getContent() ), '.');
			}

			return $listAppend( filename, _getFileType(), '.' );
		</cfscript>
	</cffunction>

	<cffunction name="getOrdered" access="public" returntype="array" output="false" hint="I return an array of the packages files (the filenames) in the correct order, based on their dependencies">
		<cfscript>
			if( ArrayLen( _ordered ) NEQ StructCount( _staticFiles ) ) {
				_orderfiles();
			}

			return _ordered;
		</cfscript>
	</cffunction>

<!--- private methods --->
	<cffunction name="_newStaticFile" access="private" returntype="StaticFile" output="false" hint="I return an instanciated staticFile object based on the supplied file path">
		<cfargument name="path" type="string" required="true" />

		<cfscript>
			var fileUrl     = "";
			var minifiedUrl = "";

			if ( $isUrl( path ) ) {
				fileUrl = path;
			} else {
				fileUrl = _getRootUrl() & ListLast( path, '/' );
			}

			return CreateObject( 'component', 'org.cfstatic.core.StaticFile' ).init( Trim(path), _getPackageName(), fileUrl, _getMinifiedUrl(), _getFileType(), _getCacheBust() );
		</cfscript>
	</cffunction>

	<cffunction name="_orderFiles" access="private" returntype="void" output="false" hint="I order all the static files within this package, cacheing the order locally">
		<cfscript>
			var files = StructKeyArray( _getStaticFiles() );
			var i     = "";

			ArraySort( files, 'text' );
			for( i=1; i LTE ArrayLen(files); i=i+1 ){
				_addFileToOrderedList( files[i] );
			}
		</cfscript>
	</cffunction>

	<cffunction name="_addFileToOrderedList" access="private" returntype="void" output="false" hint="I am a utility method for creating the ordered list of files. I work by adding each file in turn but first adding all the file's dependencies">
		<cfargument name="filePath" type="string" required="true" />

		<cfscript>
			var file         = getStaticFile( filePath );
			var dependencies = file.getDependencies( true );
			var i            = 0;

			for( i=1; i LTE ArrayLen( dependencies ); i++ ){
				if ( dependencies[i].getPackageName() EQ _getPackageName() ) {
					_addFileToOrderedList( dependencies[i].getPath() );
				}
			}

			if ( not ListFind( ArrayToList( _ordered ), filePath ) ) {
				ArrayAppend( _ordered, filePath );
			}
		</cfscript>
	</cffunction>

<!--- accessors --->
	<cffunction name="_setPackageName" access="private" returntype="void" output="false">
		<cfargument name="packageName" required="true" type="string" />
		<cfset _packageName = packageName />
	</cffunction>
	<cffunction name="_getPackageName" access="private" returntype="string" output="false">
		<cfreturn _packageName />
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

	<cffunction name="_getStaticFiles" access="private" returntype="struct" output="false">
		<cfreturn _staticFiles />
	</cffunction>

	<cffunction name="_getCacheBust" access="private" returntype="boolean" output="false">
		<cfreturn _cacheBust>
	</cffunction>
	<cffunction name="_setCacheBust" access="private" returntype="void" output="false">
		<cfargument name="cacheBust" type="boolean" required="true" />
		<cfset _cacheBust = cacheBust />
	</cffunction>

</cfcomponent>