<cfcomponent hint="utility for reading version information" output="false">
	
	<cffunction name="getVersionInfo" output="false" access="public" returntype="struct" hint="returns a struct containing VersionNumber and VersionDate keys">
		<cfset var versionFilePath = getVersionFilePath()>
		<cfset var props = createObject("java","java.util.Properties")>
		<cfset var fis = createObject("java","java.io.FileInputStream")>
		<cfset var result = StructNew()>
		<cfset fis.init(versionFilePath)>
		<cfset props.load(fis)>
		<cfset result.VersionDate = props.getProperty("build.date")>
		<cfset result.VersionNumber = props.getProperty("build.major") & "." & props.getProperty("build.minor") & "." & props.getProperty("build.buildnum")>
		<cfreturn result>
		
	</cffunction>
		
	<cffunction name="getVersionFilePath" access="private">
		<!--- can't use expandpath because it doesn't work correctly when accessed remotely (i.e. from plugin) --->
		<cfset var propDir = getDirectoryFromPath(getCurrentTemplatePath())>
		<cfset propDir = reverse(listRest(reverse(propDir),"\/")) & "/buildprops/">
		<cfreturn propDir & "version.properties">
	</cffunction>
		
</cfcomponent>