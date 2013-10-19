<cfcomponent output="false" extends="org.cfstatic.util.Base"  hint="I am an abstract representation of a single static file. I provide methods such as getting the content of the file and getting the last modified date of the file.">

<!--- properties --->
	<cfscript>
		_path                    = "";
		_url                     = "";
		_minifiedUrl             = "";
		_fileType                = "";
		_cacheBust               = true;
		_dependencies            = ArrayNew(1);
		_properties              = StructNew();
		_lastModified            = CreateDateTime(1900,1,1,0,0,0);
		_conditionalDependencies = ArrayNew(1);
	</cfscript>

<!--- constructor --->
	<cffunction name="init" access="public" returntype="StaticFile" output="false" hint="I am the constructor">
		<cfargument name="path"        type="string"  required="true" />
		<cfargument name="packageName" type="string"  required="true" />
		<cfargument name="fileUrl"     type="string"  required="true" />
		<cfargument name="minifiedUrl" type="string"  required="true" />
		<cfargument name="fileType"    type="string"  required="true" />
		<cfargument name="cacheBust"   type="boolean" required="true" />

		<cfscript>
			_setPath       ( path                                                   );
			_setPackageName( packageName                                            );
			_setUrl        ( fileUrl                                                );
			_setCacheBust  ( cacheBust                                              );
			_setMinifiedUrl( $listAppend( minifiedUrl, getMinifiedFileName(), '/' ) );
			_setFileType   ( fileType                                               );

			if (_isLocal() ) {
				_parseProperties();
			}

			return this;
		</cfscript>
	</cffunction>

<!--- public methods --->
	<cffunction name="addDependency" access="public" returntype="void" output="false" hint="I allow calling code to add a dependency to me. i.e. another static file on which I depend.">
		<cfargument name="dependency" required="true" type="StaticFile" />
		<cfset ArrayAppend( _dependencies, dependency ) />
	</cffunction>

	<cffunction name="getDependencies" access="public" returntype="array" output="false"  hint="I return an array, in the correct order, of all the file''s dependencies">
		<cfargument name="recursive"           type="boolean" required="false" default="false" />
		<cfargument name="includeConditionals" type="boolean" required="false" default="true"  />

		<cfscript>
			var final        = ArrayNew(1);
			var added        = StructNew();
			var deep         = "";
			var conditionals = "";
			var i            = 0;
			var n            = 0;

			for( i=1; i LTE ArrayLen( _dependencies ); i++ ){
				if ( recursive ) {
					deep = _dependencies[i].getDependencies( true );
					for( n=1; n LTE ArrayLen( deep ); n++ ){
						if ( not StructKeyExists( added, deep[n].getPath() ) ) {
							ArrayAppend( final, deep[n] );
							added[ deep[n].getPath() ] = true;
						}
					}
				}
				if ( not StructKeyExists( added, _dependencies[i].getPath() ) ) {
					ArrayAppend( final, _dependencies[i] );
					added[ _dependencies[i].getPath() ] = true;
				}
			}
			if ( not includeConditionals ) {
				conditionals = ArrayToList( _getConditionalDependencies() );
				for( i=ArrayLen( final ); i GT 0 ; i-- ){
					if ( ListFindNoCase( conditionals, final[i].getPath() ) ) {
						ArrayDeleteAt( final, i );
					}
				}
			}

			return _bubbleSort( final );
		</cfscript>
	</cffunction>

	<cffunction name="getProperty" access="public" returntype="any" output="false" hint="I return the value of a given property for the file. Properties are defined in static files using javadoc notation (a property being equivalent to a javadoc attribute). Calling code can force the returned value to be simple or an array (for when single or multiple values are expected). Calling code may also define a default value should the property not exist.">
		<cfargument name="propertyName"type="string" required="true" />
		<cfargument name="defaultValue"type="any"    required="false" default="" />
		<cfargument name="forceType"   type="string" required="false" default="any" />

		<cfscript>
			var prop = "";
			var arr  = "";

			if ( not StructKeyExists( _properties, propertyName ) ) {
				return defaultValue;
			}

			prop = _properties[ propertyName ];
			if ( IsArray( prop ) and forceType eq 'string' ) {
				return prop[1];
			}
			if ( not IsArray( prop ) and forceType Eq 'array' ) {
				arr = ArrayNew(1);
				ArrayAppend( arr, prop );
				return arr;
			}

			return prop;
		</cfscript>
	</cffunction>

	<cffunction name="getContent" access="public" returntype="string" output="false" hint="I return the content of the file (through a local file read when a local file and http get when an external file)">
		<cfscript>
			if ( _isLocal() ) {
				return $fileRead( getPath() );
			}

			return $httpGet( getPath() );
		</cfscript>
	</cffunction>

	<cffunction name="renderInclude" access="public" returntype="string" output="false" hint="I return the html needed to include the file">
		<cfargument name="minified" type="boolean" required="true" hint="Whether or not to refer to the minified or non-minified file when rendering the html include"/>

		<cfscript>
			var media = getProperty( 'media', 'all', 'string' );
			var ie    = getProperty( 'IE', '', 'string' );
			var src   = iif( minified, DE( _getMinifiedUrl() ), DE( _getUrl() ) );

			if ( _getFileType() EQ 'css' ) {
				return $renderCssInclude( src, media, ie );

			} else {
				return $renderJsInclude( src, ie );
			}
		</cfscript>
	</cffunction>

	<cffunction name="getMinifiedFileName" access="public" returntype="string" output="false" hint="I return the filename to be used when this file is minified">
		<cfscript>
			var packageName = getPackageName();
			var filename    = "";
			var path        = getPath();
			var ext         = ListLast(path, '.');

			if ( packageName EQ '/' ) {
				filename = ListLast( path, '\/' );
			} else {
				filename = "#ListChangeDelims( packageName, '.', '/' )#.#ListLast( path, '\/' )#";
			}

			filename = $listDeleteLast( filename, '.' );
			filename = $listAppend( filename, 'min', '.' );
			if ( _getCacheBust() ) {
				filename    = $listAppend(filename, Hash( getContent() ), '.');
			}

			return $listAppend( filename, ext, '.' );
		</cfscript>
	</cffunction>

	<cffunction name="getlastModified" access="public" returntype="date" output="false" hint="I return the last modified date of the static file">
		<cfscript>
			if ( _isLocal() ) {
				return $fileLastModified( getPath() );
			}
			return '1900-01-01 00:00:00';
		</cfscript>
	</cffunction>

	<cffunction name="setConditionalDependencies" access="public" returntype="void" output="false">
		<cfargument name="conditionals" type="array" required="true" />

		<cfset _conditionalDependencies = conditionals />
	</cffunction>

<!--- private methods --->
	<cffunction name="_parseProperties" access="private" returntype="void" output="false" hint="I read the file's content and parse it's javadoc comments to calculate properties and dependencies">
		<cfscript>
			var content   = $fileRead( getPath() );
			var metaBlock = $reSearch( '/\*\*(.*?)\*/', content ); // grab the first entire block of meta comments
			var meta      = "";
			var i         = 1;
			var tmp       = "";
			var prop      = "";
			var value     = "";

			_properties = StructNew();

			if ( StructKeyExists( metaBlock, '$1' ) ) {
				content = metaBlock.$1[1] & '*/';
				meta    = $reSearch( '\*.*?@([A-Za-z0-9]+?) (.*?)\*', content ); // search for the attributes and their values
				if ( StructKeyExists( meta, '$1' ) and StructKeyExists( meta, '$2' ) ) {
					for( i=1; i LTE ArrayLen(meta.$1); i++ ){
						prop  = meta.$1[i];
						value = Trim( meta.$2[i] );

						if ( StructKeyExists( _properties, prop ) ) {
							if ( not IsArray( _properties[prop] ) ) {
								tmp = _properties[prop];
								_properties[prop] = ArrayNew(1);
								ArrayAppend( _properties[prop], tmp );
							}
							ArrayAppend( _properties[prop], value );

						} else {
							_properties[ prop ] = value;
						}
					}
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="_isLocal" access="private" returntype="boolean" output="false" hint="Returns whether or not the file is a local file">
		<cfreturn not $isUrl( getPath() ) />
	</cffunction>

	<cffunction name="_bubbleSort" access="private" returntype="array" output="false">
		<cfargument name="fileArray" type="array" required="true" />

		<cfscript>
			var sortingHappened = false;
			var i               = 0;
			var tmp             = "";

			while( sortingHappened ) {
				sortingHappened = false;
				for( i=1; i LT ArrayLen( fileArray ); i++ ) {
					if ( fileArray[i].getPath() GT fileArray[i+1].getPath() ) {
						sortingHappened = true;
						tmp             = fileArray[i];
						fileArray[i]    = fileArray[i+1];
						fileArray[i+1]  = tmp;
					}
				}
			}

			return fileArray;
		</cfscript>
	</cffunction>

<!--- accessors --->
	<cffunction name="_setPath" access="private" returntype="void" output="false">
		<cfargument name="path" required="true" type="string" />
		<cfset _path = path />
	</cffunction>
	<cffunction name="getPath" access="public" returntype="string" output="false">
		<cfreturn _path />
	</cffunction>

	<cffunction name="_setPackageName" access="private" returntype="void" output="false">
		<cfargument name="packageName" required="true" type="string" />
		<cfset _packageName = packageName />
	</cffunction>
	<cffunction name="getPackageName" access="public" returntype="string" output="false">
		<cfreturn _packageName />
	</cffunction>

	<cffunction name="_setUrl" access="private" returntype="void" output="false">
		<cfargument name="fileUrl" required="true" type="string" />
		<cfset _url = fileUrl />
	</cffunction>
	<cffunction name="_getUrl" access="private" returntype="string" output="false">
		<cfreturn _url />
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

	<cffunction name="_getCacheBust" access="private" returntype="boolean" output="false">
		<cfreturn _cacheBust>
	</cffunction>
	<cffunction name="_setCacheBust" access="private" returntype="void" output="false">
		<cfargument name="cacheBust" type="boolean" required="true" />
		<cfset _cacheBust = cacheBust />
	</cffunction>

	<cffunction name="_getConditionalDependencies" access="private" returntype="array" output="false">
		<cfreturn _conditionalDependencies	/>
	</cffunction>
</cfcomponent>