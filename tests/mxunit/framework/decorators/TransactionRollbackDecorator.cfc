<cfcomponent hint="Wraps the test in a transaction rollback" extends="mxunit.framework.TestDecorator" output="false">

	<cffunction name="invokeTestMethod"	access="public" returntype="string" output="false" >
		<cfargument name="methodName" hint="the name of the method to invoke" type="string" required="Yes">
		<cfargument name="args" hint="Optional set of arguments" type="struct" required="No" default="#StructNew()#">
		<cfset var result = "">
		<cftransaction action="begin">
			<cfset result = getTarget().invokeTestMethod(arguments.methodName, arguments.args) />
			<cftransaction action="rollback" />
		</cftransaction>

		<cfreturn result/>
	</cffunction>

</cfcomponent>