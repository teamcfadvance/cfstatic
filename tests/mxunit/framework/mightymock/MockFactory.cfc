<cfcomponent displayname="MockFactory" output="false">

	<cffunction name="init">
		<cfscript>
			return this;
		</cfscript>
	</cffunction>
	
	<cffunction name="createMock">
		<cfargument name="mocked" required="false" default="" />
		<cfargument name="mockType" required="false" default="fast" />
		<cfswitch expression="#arguments.mockType#">
			<cfcase value="fast">
				<cfreturn createObject("component","MightyMock").init(arguments.mocked) />
			</cfcase>
			<cfcase value="typeSafe">
				<cfreturn createObject("component","MightyMock").init(arguments.mocked,true) />
			</cfcase>
			<cfcase value="partial">
				<cfthrow type="MightyMock.MockFactory.partialMocksNotImplemented" message="Partial mocks are not available via MightyMock yet." />
			</cfcase>
		</cfswitch>
	</cffunction>

</cfcomponent>
