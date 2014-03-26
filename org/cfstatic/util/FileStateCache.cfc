<cfcomponent output="false" extends="org.cfstatic.util.Base">

<!--- constructor --->
	<cffunction name="init" access="public" returntype="any" output="false">
		<cfargument name="stateFilePath" type="any" required="true" default="" />

		<cfscript>
			_setStateFilePath( stateFilePath );

			_loadState();

			return this;
		</cfscript>
	</cffunction>

<!--- public methods --->
	<cffunction name="getFileState" access="public" returntype="struct" output="false">
		<cfargument name="filePath" type="string" required="true" />

		<cfscript>
			var state = _getState();

			if ( StructKeyExists( state, filePath ) and IsStruct( state[ filePath ] ) ) {
				return state[ filePath ];
			}

			return {};
		</cfscript>
	</cffunction>

	<cffunction name="setFileState" access="public" returntype="void" output="false">
		<cfargument name="filePath"  type="string" required="true" />
		<cfargument name="fileState" type="struct" required="true" />

		<cfscript>
			var state = _getState();
			state[ filePath ] = fileState;
		</cfscript>
	</cffunction>

	<cffunction name="saveState" access="public" returntype="void" output="false">
		<cfscript>
			$fileWrite( _getStateFilePath(), SerializeJson( _getState() ) );
		</cfscript>
	</cffunction>

<!--- private helpers --->
	<cffunction name="_loadState" access="private" returntype="void" output="false">
		<cfscript>
			var stateFile    = _getStateFilePath();
			var fileContents = "";
			var state        = {};

			if ( FileExists( stateFile ) ) {
				fileContents = $fileRead( stateFile );

				try {
					state = DeserializeJson( fileContents );
				} catch( any e ) {
					state = {};
				}
			}

			_setState( state );
		</cfscript>
	</cffunction>

<!--- getters and setters --->
	<cffunction name="_getStateFilePath" access="private" returntype="string" output="false">
		<cfreturn _stateFilePath>
	</cffunction>
	<cffunction name="_setStateFilePath" access="private" returntype="void" output="false">
		<cfargument name="stateFilePath" type="string" required="true" />
		<cfset _stateFilePath = $normalizeUnixAndWindowsPaths( $ensureFullFilePath( stateFilePath ) ) />
	</cffunction>

	<cffunction name="_getState" access="public" returntype="struct" output="false">
		<cfreturn _state>
	</cffunction>
	<cffunction name="_setState" access="private" returntype="void" output="false">
		<cfargument name="state" type="struct" required="true" />
		<cfset _state = state />
	</cffunction>

</cfcomponent>