<cfcomponent output="false">
<!---
 Mimics the cfdirectory, action=&quot;list&quot; command.
 Updated with final CFMX var code.
 Fixed a bug where the filter wouldn't show dirs.

 @param directory 	 The directory to list. (Required)
 @param filter 	 Optional filter to apply. (Optional)
 @param sort 	 Sort to apply. (Optional)
 @param recurse 	 Recursive directory list. Defaults to false. (Optional)
 @return Returns a query.
 @author Raymond Camden (ray@camdenfamily.com)
 @version 2, April 8, 2004
--->
<cffunction name="directoryList"  returnType="query">
	<cfargument name="directory" type="string" required="true">
	<cfargument name="filter" type="string" required="false" default="">
	<cfargument name="sort" type="string" required="false" default="type">
	<cfargument name="recurse" type="boolean" required="false" default="false">
	<!--- temp vars --->
	<cfargument name="dirInfo" type="query" required="false">
	<cfargument name="thisDir" type="query" required="false">
	<cfset var path="">
    <cfset var temp="">
	<cfset arguments.filter = replace(arguments.filter,"*","%","all")>
	<cfif not recurse>
		<cfdirectory name="temp" directory="#directory#" sort="#sort#">
		<!--- filter out hidden files and dirs --->
		<cfquery dbtype="query" name="temp">
		select * from temp
		where name not like '.%'
		<cfif len(arguments.filter)>
		and (name like '#arguments.filter#' or type = 'Dir')
		</cfif>
		</cfquery>
		<cfreturn temp>
	<cfelse>
		<!--- We loop through until done recursing drive --->
		<cfif not isDefined("arguments.dirInfo")>
			<cfset arguments.dirInfo = queryNew("attributes,datelastmodified,mode,name,size,type,directory")>
		</cfif>
		<cfset arguments.thisDir = this.directoryList(directory,arguments.filter,sort,false)>
		<cfif server.os.name contains "Windows">
			<cfset path = "\">
		<cfelse>
			<cfset path = "/">
		</cfif>
		<cfloop query="arguments.thisDir">
				<cfset queryAddRow(arguments.dirInfo)>
				<cfset querySetCell(arguments.dirInfo,"attributes",attributes)>
				<cfset querySetCell(arguments.dirInfo,"datelastmodified",datelastmodified)>
				<cfset querySetCell(arguments.dirInfo,"mode",mode)>
				<cfset querySetCell(arguments.dirInfo,"name",name)>
				<cfset querySetCell(arguments.dirInfo,"size",size)>
				<cfset querySetCell(arguments.dirInfo,"type",type)>
				<cfset querySetCell(arguments.dirInfo,"directory",directory)>
				<cfif type is "dir">
					<!--- go deep! --->
					<cfset this.directoryList(directory & path & name,arguments.filter,sort,true,arguments.dirInfo)>
				</cfif>
		</cfloop>
		<cfreturn arguments.dirInfo>
	</cfif>
</cffunction>
</cfcomponent>