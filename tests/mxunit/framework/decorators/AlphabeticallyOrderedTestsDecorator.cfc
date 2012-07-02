<cfcomponent extends="mxunit.framework.TestDecorator" output="false" hint="Orders tests alphabetically">

	<cffunction name="getRunnableMethods" output="false" access="public" returntype="any" hint="">
    	<cfset var methods = getTarget().getRunnableMethods()>
    	<cfset arraySort(methods, "text", "asc" )>
    	<cfreturn methods>
    </cffunction>

</cfcomponent>