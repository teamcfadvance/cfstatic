<cfcomponent output="false" extends="org.cfstatic.util.Base" hint="I am a CF wrapper to the YuiCompressor jar">

	<cffunction name="init" access="public" returntype="org.cfstatic.util.LessCompiler" output="false" hint="Constructor, taking a javaloader instance preloaded with the path to the Less Compiler jar.">
		<cfargument name="javaloader" type="any" required="true" hint="An instance of the javaloader with class path of Less Compiler jar preloaded." />
		<cfscript>
			if(StructKeyExists(arguments, 'javaloader')){
				super._setJavaLoader(arguments.javaloader);
			}

			_setLessEngine( $loadJavaClass('com.asual.lesscss.LessEngine') );

			return this;
		</cfscript>
	</cffunction>
	
	<cffunction name="compile" access="public" returntype="string" output="false">
		<cfargument name="filePath" type="string" required="true" />
		
		<cfscript>
			var file     = "";
			var compiled = "";
			
			// ensure file has no special chars that LESS chokes on
			_cleanFile(arguments.filePath);

			// load a java file object for the less engine
			file = CreateObject('java', 'java.io.File').init( arguments.filePath );

			// attempt less compilation
			try {
				compiled = _getLessEngine().compile( file );				
			} catch( any e ){
				$throw('org.cfstatic.util.LessCompiler.badLESS', e.message, e.detail);
			}

			// cleanup and return
			file = "";
			return compiled;
		</cfscript>
	</cffunction>

	<cffunction name="_cleanFile" access="private" returntype="void" output="false" hint="I ensure the file does not have any special characters that the LESS engine might choke on">
		<cfargument name="file" type="string" required="true" hint="Full path to the file to clean"/>
		<cfscript>
			var lastModified = $fileLastModified(arguments.file);

			// simply read and write the file using CF, should clean it up enough for LESS
			$fileWrite( arguments.file, $fileRead(arguments.file) );

			// set the original last modified date back
			FileSetLastModified( arguments.file, lastModified );
		</cfscript>
	</cffunction>

	<cffunction name="_getLessEngine" access="private" returntype="any" output="false">
		<cfreturn _LessEngine>
	</cffunction>
	<cffunction name="_setLessEngine" access="private" returntype="void" output="false">
		<cfargument name="LessEngine" type="any" required="true" />
		<cfset _LessEngine = arguments.LessEngine />
	</cffunction>
</cfcomponent>