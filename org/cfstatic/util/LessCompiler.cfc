<cfcomponent output="false" extends="org.cfstatic.util.Base" hint="I am a CF wrapper to the YuiCompressor jar">

	<cffunction name="init" access="public" returntype="org.cfstatic.util.LessCompiler" output="false" hint="Constructor, taking a javaloader instance preloaded with the path to the Less Compiler jar.">
		<cfargument name="javaloader" type="any" required="true" hint="An instance of the javaloader with class path of Less Compiler jar preloaded." />

		<cfscript>
			if ( StructKeyExists( arguments, 'javaloader' ) ) {
				super._setJavaLoader( javaloader );
			}

			_setLessEngine( $loadJavaClass( 'com.asual.lesscss.LessEngine' ) );

			return this;
		</cfscript>
	</cffunction>

	<cffunction name="compile" access="public" returntype="string" output="false">
		<cfargument name="filePath"    type="string" required="true"             />
		<cfargument name="lessGlobals" type="string" required="false" default="" />

		<cfscript>
			var file     = "";
			var compiled = "";
			var tmpFile  = getDirectoryFromPath( filePath ) & $createTemporaryFilename( "less" );
			var content  = _injectLessGlobalsAsImports( filePath, lessGlobals );

			$fileWrite( tmpFile, content  );
			file = CreateObject( 'java', 'java.io.File' ).init( tmpFile );

			try {
				compiled = _getLessEngine().compile( file );
			} catch( any e ){
				file = "";
				$fileDelete( tmpFile );
				$throw(  type    = 'org.cfstatic.util.LessCompiler.badLESS'
					   , message = "LESS error when compiling #ListLast(filePath, '/\')#. Message: #e.message#"
					   , detail  = e.detail );
			}

			file = "";
			$fileDelete( tmpFile );
			return compiled;
		</cfscript>
	</cffunction>

<!--- private utility --->
	<cffunction name="_injectLessGlobalsAsImports" access="private" returntype="string" output="false">
		<cfargument name="filePath"    type="string" required="true" />
		<cfargument name="lessGlobals" type="string" required="true" />

		<cfscript>
			var globals      = ListToArray( lessGlobals );
			var relative     = "";
			var imports      = "";
			var fileIsGlobal = ListFindNoCase( lessGlobals, filePath );
			var i            = 0;

			if ( not fileIsGlobal ) {
				for( i=1; i LTE ArrayLen( globals ); i++ ){
					globals[i] = $ensureFullFilePath( globals[i] );
					if ( not FileExists( globals[i] ) ) {
						$throw( "org.cfstatic.util.LessCompiler.missingGlobal", "Could not find LESS global, '#globals[i]#'" );
					}

					relative = $calculateRelativePath( filePath, globals[i] );
					imports = ListAppend( imports, "@import url('#relative#');", $newLine() );
				}
			}

			return imports & $newline() & $fileRead( filePath );
		</cfscript>
	</cffunction>

	<cffunction name="_getLessEngine" access="private" returntype="any" output="false">
		<cfreturn _LessEngine>
	</cffunction>
	<cffunction name="_setLessEngine" access="private" returntype="void" output="false">
		<cfargument name="LessEngine" type="any" required="true" />
		<cfset _LessEngine = LessEngine />
	</cffunction>
</cfcomponent>