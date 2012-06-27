<cfcomponent name="mxunit.framework.HamcrestAssert" extends="Assert" output="false" hint="Not Implemented! R/D component testing Hamcrest style assertions to support Descriptive-based test writing.">
<!--- Extend Assert in order to use fail and toStringValue --->

<cffunction name="HamcrestAssert" extends="Assert" access="public" hint="Constructor">
  <cfargument name="whatever" type="any"><!--- any --->
 <!---  <cfset var obj = whatever /> --->
  <!--- <cfset this = obj /> --->
  <cfreturn this />
 </cffunction>
<!---   --->
  <cfparam name="this.firstComparableObject" type="any" default="" />
  
	<cffunction name="assertThat" access="public" output="true" returnType="void" static="true" >
    <cfargument name="obj1" type="any" required="true">
    <cfargument name="obj2" type="any" required="true">
		<cfset this.firstComparableObject = getStringValue(obj1) />
    <!--- 
      Since this extends Assert, we can delegate the core assertion behavior to Assert 
      and use the matcher to return correct values for comparisons
    --->
    <cfset assertEquals(this.firstComparableObject, obj2.stringRepresentation, obj2.getDescription() ) />
	</cffunction>
 
 <cffunction name="doContains">
  
 </cffunction>
 
  
  <!--- Temp --->
  <cffunction name="assertThis" access="public" output="false" returntype="Any">
		<!--- TODO: Implement Method --->
		<cfreturn "aserting this" />
	</cffunction>
</cfcomponent>