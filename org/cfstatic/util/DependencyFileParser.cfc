<cfcomponent output="false" extends="org.cfstatic.util.Base" hint="I provide an interface for parsing the CfStatic Dependency file">

	<cfset _setConditionalToken( '(conditional)' ) />

	<cffunction name="parse" access="public" returntype="struct" output="false">
		<cfargument name="filePath" type="string" required="true" />
		<cfargument name="rootDir"  type="string" required="true" />

		<cfscript>
			var fileContent      = $fileRead( $ensureFullFilePath( filePath ) );
			var lineNumber       = 0;
			var line             = "";
			var lastLineIsParent = false;
			var files            = ArrayNew(1);

			for( lineNumber=1; lineNumber LTE ListLen( fileContent, $newLine() ); lineNumber++ ){
				line = ListGetAt( fileContent, lineNumber, $newLine() );

				if ( not _isIgnorable( line ) ) {

					if ( _isChild( line ) ) {
						files = _addDependents(
							  files       = files
							, dependents  = _discoverFilesFromWildCardMapping( Trim( ListFirst( line, ' ' ) ), rootDir )
							, conditional = _isConditional( line )
						);
						lastLineIsParent = false;
					} else {
						files = _addDependencies(
							  files           = files
							, dependencies    = _discoverFilesFromWildCardMapping( Trim( ListFirst( line, ' ' ) ), rootDir )
							, isNewDependency =  not lastLineIsParent
						);

						lastLineIsParent = true;
					}
				}
			}

			return _dependencyArrayToStruct( files );
		</cfscript>
	</cffunction>

	<cffunction name="_isIgnorable" access="private" returntype="boolean" output="false">
		<cfargument name="line" type="string" required="true" />

		<cfscript>
			if ( not Len( Trim( line ) ) ) {
				return true;
			}

			return Left( line, 1 ) EQ '##';
		</cfscript>
	</cffunction>

	<cffunction name="_isChild" access="private" returntype="boolean" output="false">
		<cfargument name="line" type="string" required="true" />

		<cfreturn ReFind( "\s", Left( line, 1 ) ) />
	</cffunction>

	<cffunction name="_isConditional" access="private" returntype="boolean" output="false">
		<cfargument name="line" type="string" required="true" />

		<cfscript>
			var hasTwoTokens           = ListLen ( Trim( line ), ' ' ) EQ 2;
			var lastTokenIsConditional = ListLast( Trim( line ), ' ' ) EQ _getConditionalToken();

			return hasTwoTokens and lastTokenIsConditional;
		</cfscript>
	</cffunction>

	<cffunction name="_addDependencies" access="private" returntype="array" output="false">
		<cfargument name="files"           type="array"   required="true" />
		<cfargument name="dependencies"    type="array"   required="true" />
		<cfargument name="isNewDependency" type="boolean" required="true" />

		<cfscript>
			var dependency = StructNew();

			if ( isNewDependency ) {
				dependency['dependencies']          = ArrayNew(1);
				dependency['dependents']            = ArrayNew(1);
				dependency['conditionalDependents'] = ArrayNew(1);

				ArrayAppend( files, dependency );
			}

			files[ ArrayLen( files ) ].dependencies = $ArrayMerge( files[ ArrayLen( files ) ].dependencies, dependencies );

			return files;
		</cfscript>
	</cffunction>

	<cffunction name="_addDependents" access="private" returntype="array" output="false">
		<cfargument name="files"       type="array"   required="true" />
		<cfargument name="dependents"  type="array"   required="true" />
		<cfargument name="conditional" type="boolean" required="true" />
		<cfscript>
			files[ ArrayLen( files ) ].dependents = $ArrayMerge( files[ ArrayLen( files ) ].dependents, dependents );

			if ( conditional ) {
				files[ ArrayLen( files ) ].conditionalDependents = $ArrayMerge( files[ ArrayLen( files ) ].conditionalDependents, dependents );
			}

			return files;
		</cfscript>
	</cffunction>

	<cffunction name="_discoverFilesFromWildCardMapping" access="private" returntype="array" output="false">
		<cfargument name="wildCardMapping" type="string" required="true" />
		<cfargument name="rootDir"           type="string" required="true" />

		<cfscript>
			var returnArray = ArrayNew(1);
			var fullPath    = $ListAppend( rootDir, wildCardMapping, '/' );
			var dir         = GetDirectoryFromPath( fullPath );
			var filter      = Trim( ListLast( fullPath, '/' ) );
			var files       = "";
			var i           = 0;

			if ( $isUrl( wildCardMapping ) ) {
				ArrayAppend( returnArray, wildCardMapping );

			} else {
				files = $directoryList( dir, filter, true );

				for( i=1; i LTE files.recordCount; i=i+1 ){
					ArrayAppend( returnArray, $normalizeUnixAndWindowsPaths( $ListAppend( files.directory[i], files.name[i], '/' ) ) );
				}

				ArraySort( returnArray, 'text' );
			}

			if ( not ArrayLen( returnArray ) ) {
				$throw(  type    = "org.cfstatic.util.DependencyFileParser.missingDependency"
					   , message = "Your dependency file has a bad file path / wildcard mapping"
					   , detail  = "The dependency, '#wildCardMapping#', failed to match any files." );
			}

			return returnArray;
		</cfscript>
	</cffunction>

	<cffunction name="_dependencyArrayToStruct" access="private" returntype="struct" output="false">
		<cfargument name="dependencyArray" type="array" required="true" />

		<cfscript>
			var i                = 0;
			var n                = 0;
			var dependencyStruct = StructNew();
			var dependencies     = "";
			var dependenciesList = "";
			var dependents       = "";
			var dependent        = "";
			var conditionals     = "";

			dependencyStruct.regular     = StructNew();
			dependencyStruct.conditional = StructNew();


			for( i=1; i LTE ArrayLen( dependencyArray ); i=i+1 ){
				dependents       = dependencyArray[i].dependents;
				dependencies     = dependencyArray[i].dependencies;
				dependenciesList = ArrayToList( dependencies );
				conditionals     = dependencyArray[i].conditionalDependents;

				for( n=1; n LTE ArrayLen( dependents ); n=n+1 ){
					dependent = $appendCompiledFileTypeToFilePath( dependents[n] );
					if ( not ListFindNoCase( dependenciesList, dependent ) and not ListFindNoCase( dependenciesList, dependents[n] ) ) {
						if ( not StructKeyExists( dependencyStruct.regular, dependent ) ) {
							dependencyStruct.regular[ dependent ] = ArrayNew(1);
						}

						dependencyStruct.regular[ dependent ] = $ArrayMerge( dependencyStruct.regular[ dependent ], dependencies );
					}
				}
				for( n=1; n LTE ArrayLen( conditionals ); n=n+1 ){
					dependent = $appendCompiledFileTypeToFilePath( dependents[n] );
					if ( not ListFindNoCase( dependenciesList, dependent ) and not ListFindNoCase( dependenciesList, dependents[n] ) ) {
						if ( not StructKeyExists( dependencyStruct.conditional, dependent ) ) {
							dependencyStruct.conditional[ dependent ] = ArrayNew(1);
						}

						dependencyStruct.conditional[ dependent ] = $ArrayMerge( dependencyStruct.conditional[ dependent ], dependencies );
					}
				}
			}
			return dependencyStruct;
		</cfscript>
	</cffunction>

	<cffunction name="_getConditionalToken" access="private" returntype="any" output="false">
		<cfreturn _conditionalToken>
	</cffunction>
	<cffunction name="_setConditionalToken" access="private" returntype="void" output="false">
		<cfargument name="conditionalToken" type="any" required="true" />
		<cfset _conditionalToken = conditionalToken />
	</cffunction>
</cfcomponent>
