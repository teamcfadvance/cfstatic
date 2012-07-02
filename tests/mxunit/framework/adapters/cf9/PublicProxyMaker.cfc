<cfcomponent extends="mxunit.framework.PublicProxyMaker">

	<cffunction name="handleDirectoryCreate" output="false" access="public" returntype="any" hint="">
		<cfargument name="dir" type="string" required="true"/>
	</cffunction>

	<cffunction name="handleFileCreate" output="false" access="public" returntype="any" hint="">
		<cfargument name="fullFilePath" type="string" required="true"/>
		<cfargument name="output" type="string" required="true"/>
		<cfset var filename = getFileFromPath(fullFilePath)>
		<cffile action="write" file="ram:///#filename#" output="#output#">
	</cffunction>

	<cffunction name="handleFileDelete" output="false" access="public" returntype="any" hint="">
		<cfargument name="fullFilePath" type="string" required="true"/>
		<cfset var filename = getFileFromPath(fullFilePath)>
		<cffile action="delete" file="ram:///#filename#">
	</cffunction>

	<cffunction name="handleObjectCreate" output="false" access="public" returntype="any" hint="">
		<cfargument name="cfcname" type="string" required="true"/>
		<cfreturn createObject("component","inmemory.#cfcname#")>
	</cffunction>
</cfcomponent>
