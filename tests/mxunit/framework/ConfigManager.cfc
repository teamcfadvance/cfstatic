<cfcomponent displayname="ConfigManager" hint="Controlls data retrieved from mxunit-confg.xml" output="false">
  <cfparam name="this.configXml" type="any" default="#xmlNew()#" />

  <cffunction name="ConfigManager" access="public" output="true" returntype="ConfigManager" hint="Constructor">
    <cfset var md = getMetadata(this) />
    <cfset var configFilePath = "#getDirectoryfromPath(md.path)#/mxunit-config.xml" />
	<cfset var config= "">
    <cftry>
     <!--- Check for file --->
     <cfif fileexists(configFilePath)>
      <!--- Open File --->
      <cffile action="read" file="#configFilePath#" variable="config">
     <cfelse>
      <cflog file="mxunit" type="error" application="true" text="The mxunit-config.xml file was not found::Make sure this file is available to the application" />
      <cfthrow type="mxunit.exception.ConfigFileNotFoundException" message="The mxunit-config.xml file was not found" detail="Make sure this file is available to the application" />
     </cfif>
     <!--- parse XML --->
     <cfset this.configXml = xmlParse(config) />
     <!--- Loop over enabled config elements and call addAssertDecorator --->
     <cfcatch type="any">
      <!--- Ruh-row, Raggie! --->
      <cfthrow object="#cfcatch#">
      <cflog file="mxunit" type="error" application="false" text="#cfcatch.message#::#cfcatch.detail#">
     </cfcatch>
    </cftry>
    <cfreturn this />
  </cffunction>


 <cffunction name="getConfigElement" access="remote" output="false" returntype="array" hint="Given a type and name, returns the first matching XML element node.">
    <cfargument name="type" type="string" required="true" />
    <cfargument name="name" type="string" required="true" />
    <cfset var element = xmlSearch(this.configXml,"/mxunit-config/config-element[@type='#arguments.type#' and @name='#arguments.name#']") />
    <cfreturn element />
  </cffunction>


  <!---
    Given a configElement type and name, returns the *first* XML text value. This assumes there is only one such element
   --->
  <cffunction name="getConfigElementValue" access="remote" output="false" returntype="String" hint="Given a type and name, returns the first matching XML element value.">
    <cfargument name="type" type="string" required="true" />
    <cfargument name="name" type="string" required="true" />
    <cfset var element = xmlSearch(this.configXml,"/mxunit-config/config-element[@type='#arguments.type#' and @name='#arguments.name#']") />
    <cfreturn element[1].xmlAttributes["value"] />
  </cffunction>


  <cffunction name="getConfigElements" access="remote" output="false" returntype="array" hint="Given an XPath expression, return an array of matching config elements">
    <cfargument name="xpath" type="string" required="true" />
	<cfset var elements= "">
    <cfoutput>#arguments.xpath#</cfoutput>
    <cfset elements = xmlSearch(this.configXml,"#arguments.xpath#") />
    <cfreturn elements />
  </cffunction>

  <cffunction name="getConfigElementAttributeCollection" access="remote" output="false" returntype="any" hint="Given a type and name, returns all of the attributes in a struct, omitting the type and name.">
    <cfargument name="type" type="string" required="true" />
    <cfargument name="name" type="string" required="true" />
    <cfset var element = xmlSearch(this.configXml,"/mxunit-config/config-element[@type='#arguments.type#' and @name='#arguments.name#']") />
	<cfset var attribs = element[1].xmlAttributes />
	<cfset structDelete(attribs,"name") />
	<cfset structDelete(attribs,"type") />
    <cfreturn attribs />
  </cffunction>

</cfcomponent>