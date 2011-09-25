
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
		<cfargument name="packageName" type="string" required="true" />
		<cfargument name="rootUrl" type="string" required="true" />
		<cfargument name="minifiedUrl" type="string" required="true" />
		<cfargument name="fileType" type="string" required="true" />
		<cfargument name="cacheBust"    type="boolean" required="true" />
		
		<cfscript>
			_setPackageName( arguments.packageName );
			_setRootUrl( arguments.rootUrl );
			_setMinifiedUrl( arguments.minifiedUrl );
			_setFileType( arguments.fileType );
			_setCacheBust( arguments.cacheBust );
			
			return this;
		</cfscript>
	</cffunction>

<!--- public methods --->
	<cffunction name="addStaticFile" access="public" returntype="void" output="false" hint="I add a static file to the package">
		<cfargument name="path" required="true" type="string" />
		
		<cfset _staticFiles[arguments.path] = _newStaticfile(arguments.path) />
	</cffunction>

	<cffunction name="getStaticFile" access="public" returntype="StaticFile" output="false" hint="I return the static file object for the given file path">
		<cfargument name="path" required="true" type="string" />
		
		<cfreturn _staticFiles[arguments.path] />
	</cffunction>
	
	<cffunction name="staticFileExists" access="public" returntype="boolean" output="false" hint="I return whether or not the given static file exists within this package">
		<cfargument name="path" required="true" type="string" />
		
		<cfreturn StructKeyExists(_staticFiles, arguments.path) />
	</cffunction>

	<cffunction name="getDependencies" access="public" returntype="array" output="false" hint="I return an array of other packages (package names) that this package depends on">
		<cfscript>
			var pkgDependencies		= ArrayNew(1);
			var files				= _getStaticFiles();
			var file				= "";
			var fileDependencies	= "";
			var i					= "";
			
			for( file in files ){
				fileDependencies = files[file].getDependencies( true );
				for(i=1; i LTE ArrayLen(fileDependencies); i++){
					if(fileDependencies[i].getPackageName() NEQ _getPackageName()){
						if(not ListFind(ArrayToList(pkgDependencies), fileDependencies[i].getPackageName() )){
							ArrayAppend( pkgDependencies,  fileDependencies[i].getPackageName());
						}
					}
				}
			}
			return pkgDependencies;
		</cfscript>
	</cffunction>
	
	<cffunction name="getContent" access="public" returntype="string" output="false" hint="I return the content of all the static files within this package (in the correct order)">
		<cfscript>
			var str		= CreateObject("java","java.lang.StringBuffer");
			var files	= getOrdered(); 
			var i		= 0;
			
			for(i=1; i LTE ArrayLen(files); i++){
				str.append( getStaticFile(files[i]).getContent() );
			}
			
			return str.toString();
		</cfscript>
	</cffunction>
	
	<cffunction name="renderIncludes" access="public" returntype="string" output="false" hint="I return the html include string required to include this package">
		<cfargument name="minification" type="string" required="true" hint="Mode of minification, this will effect how the includes are rendered. Either 'package', 'file' or 'none'" />
		<cfargument name="includeFiles" type="array" required="false" default="#ArrayNew(1)#" hint="Only include the files in this array. If empty, include *all* files." />

		<cfscript>
			var str			= "";
			var files		= "";
			var i			= "";
			var src			= "";
			var media		= "";
			var ie			= "";

			switch(arguments.minification){
				case 'none': case 'file':
					str = CreateObject("java","java.lang.StringBuffer");
					files = getOrdered();
					for(i=1; i LTE ArrayLen(files); i++){
						if(not ArrayLen(arguments.includeFiles) or arguments.includeFiles.contains(JavaCast('string', files[i]))){
							str.append( getStaticFile(files[i]).renderInclude( minified = (arguments.minification EQ 'file') ) );
						}
					}
					return str.toString();

				case 'package':
					src			= "#_getMinifiedUrl()#/#getMinifiedFileName()#";
					ie			= getIeRestriction();
					
					if(_getFileType() EQ 'css'){
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
			var files			= getOrdered();
			var fileModified	= "";
			var i				= 0;
			var lastModified	= "1900-01-01";
			
			for(i=1; i LTE ArrayLen(files); i++){
				fileModified	= getStaticFile(files[i]).getLastModified();
				if(lastModified LT fileModified){
					lastModified = fileModified;
				}
			}
			
			return lastModified;
		</cfscript>
	</cffunction>

	<cffunction name="getIeRestriction" access="public" returntype="string" output="false" hint="I get the IE explorer version 'restriction' for the entire package. All static files within a single package should have the same restriction, an exception will be thrown otherwise.">
		<cfscript>
			var files			= getOrdered();
			var ieRestriction	= "";
			var i				= 0;
			
			if(ArrayLen(files)){
				ieRestriction = getStaticFile( files[1] ).getProperty('ie');
				for(i=2; i LTE ArrayLen(files); i++){
					if(ieRestriction NEQ getStaticFile( files[i] ).getProperty('ie')){
						$throw( type="cfstatic.Package.badConfig", message="There was an error compiling the package, '#_getPackageName()#', not all files define the same IE restriction." );
					}
				}
			}
			
			return ieRestriction;
		</cfscript>
	</cffunction>
	
	<cffunction name="getCssMedia" access="public" returntype="string" output="false" hint="I get the target media of the css files for the entire package. All static files within a single package should have the same media (when minifiying all together), an exception will be thrown otherwise.">
		<cfscript>
			var files	= getOrdered();
			var media	= "";
			var i		= 0;
			
			if(ArrayLen(files)){
				media = getStaticFile( files[1] ).getProperty('media', 'all', 'string');
				for(i=2; i LTE ArrayLen(files); i++){
					if(media NEQ getStaticFile( files[i] ).getProperty('media', 'all', 'string')){
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

			if(_getPackageName() EQ '/'){
				filename = "root.min";
			} else {
				filename = "#ListChangeDelims(_getPackageName(), '.', '/')#.min";
			}

			if(_getCacheBust()){
				filename    = $listAppend(filename, $generateCacheBuster( getLastModified() ), '.');
			}

			return $listAppend( filename, _getFileType(), '.');
		</cfscript>
	</cffunction>

	<cffunction name="getOrdered" access="public" returntype="array" output="false" hint="I return an array of the packages files (the filenames) in the correct order, based on their dependencies">
		<cfscript>
			if(ArrayLen(_ordered) NEQ StructCount(_staticFiles)){
				_orderfiles();
			}
			
			return _ordered;
		</cfscript>
	</cffunction>

<!--- private methods --->
	<cffunction name="_newStaticFile" access="private" returntype="StaticFile" output="false" hint="I return an instanciated staticFile object based on the supplied file path">
		<cfargument name="path" type="string" required="true" />
		
		<cfscript>
			var fileUrl = "";
			var minifiedUrl = "";
			
			if($isUrl(arguments.path)){
				fileUrl = arguments.path;
			} else {
				fileUrl = _getRootUrl() & ListLast(arguments.path, '/');
			}
			
			return CreateObject('component', 'org.cfstatic.core.StaticFile').init( Trim(arguments.path), _getPackageName(), fileUrl, _getMinifiedUrl(), _getFileType(), _getCacheBust() );
		</cfscript>
	</cffunction>
	
	<cffunction name="_orderFiles" access="private" returntype="void" output="false" hint="I order all the static files within this package, cacheing the order locally">
		<cfscript>
			var files	= _getStaticFiles();
			var file	= "";

			for( file in files ){
				_addFileToOrderedList( file );
			}
		</cfscript>
	</cffunction>

	<cffunction name="_addFileToOrderedList" access="private" returntype="void" output="false" hint="I am a utility method for creating the ordered list of files. I work by adding each file in turn but first adding all the file's dependencies">
		<cfargument name="filePath" type="string" required="true" />
		
		<cfscript>
			var file			= getStaticFile( arguments.filePath );
			var dependencies	= file.getDependencies( true );
			var i				= 0;
			
			// first, add any *internal* dependencies
			for( i=1; i LTE ArrayLen(dependencies); i++ ){
				if(dependencies[i].getPackageName() EQ _getPackageName()){
					_addFileToOrderedList( dependencies[i].getPath() );
				}
			}
			
			// now add the file if not added already
			if( not ListFind(ArrayToList(_ordered), arguments.filePath) ){
				ArrayAppend( _ordered, arguments.filePath );
			}
		</cfscript>
	</cffunction>

<!--- accessors --->
	<cffunction name="_setPackageName" access="private" returntype="void" output="false">
		<cfargument name="packageName" required="true" type="string" />
		<cfset _packageName = arguments.packageName />
	</cffunction>
	<cffunction name="_getPackageName" access="private" returntype="string" output="false">
		<cfreturn _packageName />
	</cffunction>
	
	<cffunction name="_setRootUrl" access="private" returntype="void" output="false">
		<cfargument name="rootUrl" required="true" type="string" />
		<cfset _rootUrl = arguments.rootUrl />
	</cffunction>
	<cffunction name="_getRootUrl" access="private" returntype="string" output="false">
		<cfreturn _rootUrl />
	</cffunction>
	
	<cffunction name="_setMinifiedUrl" access="private" returntype="void" output="false">
		<cfargument name="minifiedUrl" required="true" type="string" />
		<cfset _minifiedUrl = arguments.minifiedUrl />
	</cffunction>
	<cffunction name="_getMinifiedUrl" access="private" returntype="string" output="false">
		<cfreturn _minifiedUrl />
	</cffunction>
	
	<cffunction name="_setFileType" access="private" returntype="void" output="false">
		<cfargument name="fileType" required="true" type="string" />
		<cfset _fileType = arguments.fileType />
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
		<cfset _cacheBust = arguments.cacheBust />
	</cffunction>

</cfcomponent>