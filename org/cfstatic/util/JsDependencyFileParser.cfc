<cfcomponent output="false" extends="org.cfstatic.util.Base" hint="I provide an interface for parsing the CfStatic JS Dependency file">

	<cffunction name="parse" access="public" returntype="struct" output="false">
		<cfargument name="filePath" type="string" required="true" />
		<cfargument name="jsDir"    type="string" required="true" />

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
							  files      = files
							, dependents = _discoverFilesFromWildCardMapping( Trim(line), jsDir )
						);
						lastLineIsParent = false;
					} else {
						files = _addDependencies(
							  files           = files
							, dependencies    = _discoverFilesFromWildCardMapping( Trim(line), jsDir )
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
			if ( not Len(Trim(line)) ) {
				return true;
			}

			return Left(line, 1) EQ '##';
		</cfscript>
	</cffunction>

	<cffunction name="_isChild" access="private" returntype="boolean" output="false">
		<cfargument name="line" type="string" required="true" />

		<cfreturn ReFind( "\s", Left( line, 1 ) ) />
	</cffunction>

	<cffunction name="_addDependencies" access="private" returntype="array" output="false">
		<cfargument name="files"           type="array"   required="true" />
		<cfargument name="dependencies"    type="array"   required="true" />
		<cfargument name="isNewDependency" type="boolean" required="true" />

		<cfscript>
			var dependency = StructNew();

			if ( isNewDependency ) {
				dependency['dependencies'] = ArrayNew(1)
				dependency['dependents']   = ArrayNew(1);

				ArrayAppend( files, dependency );
			}

			$ArrayMerge( files[ ArrayLen( files ) ].dependencies, dependencies );

			return files;
		</cfscript>
	</cffunction>

	<cffunction name="_addDependents" access="private" returntype="array" output="false">
		<cfargument name="files"      type="array" required="true" />
		<cfargument name="dependents" type="array" required="true" />

		<cfscript>
			$ArrayMerge( files[ ArrayLen( files ) ].dependents, dependents )

			return files;
		</cfscript>
	</cffunction>

	<cffunction name="_discoverFilesFromWildCardMapping" access="private" returntype="array" output="false">
		<cfargument name="wildCardMapping" type="string" required="true" />
		<cfargument name="jsDir"           type="string" required="true" />

		<cfscript>
			var returnArray = ArrayNew(1);
			var fullPath    = $ListAppend( jsDir, wildCardMapping, '/' );
			var dir         = GetDirectoryFromPath( fullPath );
			var filter      = Trim( ListLast( fullPath, '/' ) );
			var files       = "";
			var i           = 0;

			if ( $isUrl( wildCardMapping ) ) {
				ArrayAppend( returnArray, wildCardMapping );

			} else {
				files = $directoryList( dir, filter, true );

				for( i=1; i LTE files.recordCount; i=i+1 ){
					ArrayAppend( returnArray, $ListAppend( files.directory[i], files.name[i], '/' ) );
				}

				ArraySort( returnArray, 'text' );
			}

			if ( not ArrayLen( returnArray ) ) {
				$throw(  type    = "org.cfstatic.util.JsDependencyFileParser.missingDependency"
					   , message = "Your js dependency file has a bad file path / wildcard mapping"
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
			var dependents       = "";

			for( i=1; i LTE ArrayLen( dependencyArray ); i=i+1 ){
				dependents   = dependencyArray[i].dependents;
				dependencies = dependencyArray[i].dependencies;

				for( n=1; n LTE ArrayLen( dependents ); n=n+1 ){
					if ( not StructKeyExists( dependencyStruct, dependents[n] ) ) {
						dependencyStruct[ dependents[n] ] = ArrayNew();
					}

					dependencyStruct[ dependents[n] ] = $ArrayMerge( dependencyStruct[ dependents[n] ], dependencies );
				}
			}

			return dependencyStruct;
		</cfscript>
	</cffunction>
</cfcomponent>
