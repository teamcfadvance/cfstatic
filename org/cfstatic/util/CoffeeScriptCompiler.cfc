<cfcomponent output="false" extends="org.cfstatic.util.Base" hint="I am a CF wrapper to the YuiCompressor jar">

	<cffunction name="init" access="public" returntype="org.cfstatic.util.CoffeeScriptCompiler" output="false" hint="Constructor, taking a javaloader instance preloaded with the path to the Less Compiler jar.">
		<cfargument name="javaloader" type="any" required="true" hint="An instance of the javaloader with class path of Less Compiler jar preloaded." />
		<cfscript>
			if(StructKeyExists(arguments, 'javaloader')){
				super._setJavaLoader(arguments.javaloader);
			}

			_setCoffeeScriptEngine( $loadJavaClass('org.jcoffeescript.JCoffeeScriptCompiler') );

			return this;
		</cfscript>
	</cffunction>
	
	<cffunction name="compile" access="public" returntype="string" output="false">
		<cfargument name="filePath"    type="string" required="true"             />

		<cfscript>
			var fileContent = $fileRead( arguments.filePath );
			var compileBare = Right( arguments.filePath, 11 ) EQ 'bare.coffee';

			try {
				return _getCoffeeScriptEngine().compile( fileContent, compileBare );
			} catch ( any e ) {
				$throw( 'org.cfstatic.util.CoffeeScriptCompiler.badCoffee', 'There was a problem with your coffee-script file, #ListLast(arguments.filePath, "\/")#. Message: #e.message#', e.detail );
			}
		</cfscript>
	</cffunction>

<!--- private utility --->
	<cffunction name="_getCoffeeScriptEngine" access="private" returntype="any" output="false">
		<cfargument name="bare" type="boolean" required="false" default="false" />
		<cfreturn _coffeeScriptEngine />
	</cffunction>

	<cffunction name="_setCoffeeScriptEngine" access="private" returntype="void" output="false">
		<cfargument name="coffeeScriptEngine" type="any" required="true" />

		<cfset _coffeeScriptEngine = arguments.coffeeScriptEngine />
	</cffunction>
</cfcomponent>