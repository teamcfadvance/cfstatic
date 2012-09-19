<cfcomponent output="false" extends="org.cfstatic.util.Base" hint="I am a CF wrapper to the YuiCompressor jar">

	<cffunction name="init" access="public" returntype="org.cfstatic.util.YuiCompressor" output="false" hint="Constructor, taking a javaloader instance preloaded with the path to the YuiCompressor jar.">
		<cfargument name="javaloader" type="any" required="false" hint="An instance of the javaloader with class path of Yui Compressor jar preloaded. Optional." />

		<cfscript>
			if ( StructKeyExists( arguments, 'javaloader' ) ) {
				super._setJavaLoader( javaloader );
			}
			return this;
		</cfscript>
	</cffunction>

	<cffunction name="compressCss" access="public" returntype="string" output="false" hint="I take a css input string and return a compressed version.">
		<cfargument name="source" type="string" required="true" />

		<cfscript>
			var input		= CreateObject( 'java','java.io.StringReader' ).init( source );
			var output		= CreateObject( 'java','java.io.StringWriter' ).init();
			var compressor	= $loadJavaClass( 'com.yahoo.platform.yui.compressor.CssCompressor' ).init( input );
			var compressed	= "";

			compressor.compress( output, JavaCast( 'int', -1 ) );
			compressed = output.toString();

			output.close();
			input.close();

			return compressed;
		</cfscript>
	</cffunction>

	<cffunction name="compressJs" access="public" returntype="string" output="false" hint="I take a js input string and return a compressed version.">
		<cfargument name="source"                type="string"  required="true" />
		<cfargument name="linebreak"             type="numeric" required="false" default="-1" />
		<cfargument name="munge"                 type="boolean" required="false" default="true" />
		<cfargument name="verbose"               type="boolean" required="false" default="false" />
		<cfargument name="preserveAllSemiColons" type="boolean" required="false" default="false" />
		<cfargument name="disableOptimizations"  type="boolean" required="false" default="false" />

		<cfscript>
			var input      = $loadJavaClass( 'java.io.StringReader' ).init( source );
			var output     = $loadJavaClass( 'java.io.StringWriter' ).init();
			var reporter   = $loadJavaClass( 'org.cfstatic.SimpleErrorReporter' ).init();
			var errorMsg   = "";
			var compressor = "";
			var compressed = "";

			try {
				compressor = $loadJavaClass( 'com.yahoo.platform.yui.compressor.JavaScriptCompressor' ).init( input, reporter );
				compressor.compress(
					  output
					, javaCast( 'int'    , linebreak             )
					, javaCast( 'boolean', munge                 )
					, javaCast( 'boolean', verbose               )
					, javaCast( 'boolean', preserveAllSemiColons )
					, javaCast( 'boolean', disableOptimizations  )
				);

			} catch( any e ) {
				if ( e.type EQ 'org.mozilla.javascript.EvaluatorException' ) {
					errorMsg = e.message;
				} else if ( IsDefined( 'e.cause.cause.type' ) and e.cause.cause.type EQ "org.mozilla.javascript.EvaluatorException" ) {
					errorMsg = e.cause.cause.message;
				}

				if ( Len( errorMsg ) ) {
					$throw(
						  type    = "org.cfstatic.util.YuiCompressor.badJs"
						, message = "There was an error compressing your javascript: '#errorMsg#'. Please see the error detail for the problematic javascript source."
						, detail  = source
					);
				}

				$throw( argumentCollection = e );
			}

			compressed = output.toString();

			output.close();
			input.close();

			return compressed;
		</cfscript>
	</cffunction>
</cfcomponent>