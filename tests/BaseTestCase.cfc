<cfcomponent extends="mxunit.framework.TestCase" output="false">

<!--- setup, teardown, etc --->
	<cffunction name="setup" access="public" returntype="void" output="false">
	
	</cffunction>
	
	<cffunction name="teardown" access="public" returntype="void" output="false">
	
	</cffunction>

<!--- private helpers --->
	<cffunction name="getMockBox" access="private" returntype="mockbox.system.testing.MockBox" output="false">
		<cfscript>
			if( not StructKeyExists(variables, '_mockbox') ){
				_mockBox = CreateObject('component', 'mockbox.system.testing.MockBox').init();
			}
			return _mockBox;
		</cfscript>
	</cffunction>

</cfcomponent>