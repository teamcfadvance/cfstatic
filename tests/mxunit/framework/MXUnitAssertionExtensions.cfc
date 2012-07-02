<!---
 Extends the base Assertions ... assertEquals and AssertTrue ...
 --->
<cfcomponent displayname="MXUnitAssertionExtensions" extends="Assert" output="false" hint="Extends core mxunit assertions.">

	
	
	<cfparam name="request.__mxunitInheritanceTree__" type="string" default="" />

	<cffunction name="assertIsXMLDoc" access="public" returntype="boolean">
		<cfargument name="xml" required="yes" type="any" />
		<cfargument name="message" required="no" default="The test result is not a valid ColdFusion XML DOC object." type="string">

		<cfset assertTrue(isXMLDoc(arguments.xml),arguments.message)>

		<cfreturn true>

	</cffunction>

	<cffunction name="assertIsEmptyArray" access="public" returntype="boolean">
		<cfargument name="a" required="yes" type="any" />
		<cfargument name="message" required="no" default="The test result is NOT an empty ARRAY. It has #ArrayLen(arguments.a)# elements" type="string">

		<cfset assertEquals(0,ArrayLen(arguments.a),arguments.message)>

		<cfreturn true>

	</cffunction>

	<cffunction name="assertIsArray" access="public" returntype="boolean">
		<cfargument name="a" required="yes" type="any" />
		<cfargument name="message" type="string" required="false" default="The test result is not a valid ColdFusion ARRAY."/>

		<cfset assertTrue(isArray(arguments.a),arguments.message)>

		<cfreturn true>

	</cffunction>

	<cffunction name="assertIsEmptyQuery" access="public" returntype="boolean">
		<cfargument name="q" required="yes" type="any" />
		<cfargument name="message" type="string" required="false" default="There should be 0 records returned but there were #arguments.q.recordcount#"/>

		<cfset assertEquals(0,arguments.q.recordcount,arguments.message)>

		<cfreturn true>

	</cffunction>

	<cffunction name="assertIsQuery" access="public" returntype="boolean">
		<cfargument name="q" required="yes" type="any" />
		<cfargument name="message" type="string" required="false" default="The test result is not a valid ColdFusion QUERY."/>

		<cfset assertTrue(isQuery(arguments.q),arguments.message)>

		<cfreturn true>

	</cffunction>

	<cffunction name="assertIsStruct" access="public" returntype="boolean">
		<cfargument name="struct" required="yes" type="any" />
		<cfargument name="message" type="string" required="false" default="The test result is not a valid ColdFusion STRUCTURE."/>

		<cfset assertTrue(isStruct(arguments.struct),arguments.message)>

		<cfreturn true>

	</cffunction>

	<cffunction name="assertIsEmptyStruct" access="public" returntype="boolean">
		<cfargument name="struct" required="yes" type="any" />
		<cfargument name="message" type="string" required="false" default="The test result is NOT an empty STRUCTURE. It has #StructCount(arguments.struct)# top-level keys"/>

		<cfset assertEquals(0,StructCount(arguments.Struct),arguments.message)>

		<cfreturn true>

	</cffunction>

	<cffunction name="assertIsEmpty" access="public" returntype="boolean">
		<cfargument name="o" required="yes" type="String" />
		<cfargument name="message" type="string" required="false" default="The test result is NOT EMPTY. It is [#o#]"/>

		<cfset assertEquals("",o,arguments.message)>

		<cfreturn true>

	</cffunction>

	<cffunction name="assertIsDefined" access="public" returntype="boolean">
		<cfargument name="o" required="yes" type="any" />
		<cfargument name="message" type="string" required="false" default="The value [#arguments.o#] is NOT DEFINED"/>

		<cfset assertTrue( isDefined(evaluate("arguments.o")) , arguments.message )>

		<cfreturn true>

	</cffunction>

	<cffunction name="assertIsTypeOf" access="public" returntype="boolean" hint="returns true if 'type' argument matches the object's type or if the object is in the inheritance tree of the type.">
		<cfargument name="o" required="yes" type="any" />
		<cfargument name="type" required="yes" type="string" />
		
		<cfif NOT componentUtils.objectIsTypeOf( o, type )>
			<cfset fail( "The object [#getMetadata(o).name#] is not of type #arguments.type#. Searched inheritance tree: [#componentUtils.buildInheritanceTree(getMetadata(o))#]" )>
		</cfif>

		<cfreturn true>

	</cffunction>

	<cffunction name="assertIsExactTypeOf" output="false" access="public" returntype="boolean" hint="returns true if 'type' argument matches exactly the object's type. inheritance tree is not considered">
		<cfargument name="o" required="yes" type="any" />
		<cfargument name="type" required="yes" type="string" />

		<cfset var oType = getMetaData(o).name>

		<cfif oType neq arguments.type>
			<cfset failNotEquals(arguments.type,oType,"The object [#oType#] is not of exact type #arguments.type#")>
		</cfif>

		<cfreturn true>

	</cffunction>

	<cffunction name="assertEqualsWithTolerance" access="public" returntype="boolean" output="false" hint="returns true of actual and expected are within a certain tolerance(epsilon) of each other. good for comparing floating point values.">
		<cfargument name="expected" type="any" required="yes" hint="The expected object to compare." />
		<cfargument name="actual" type="any" required="yes" hint="The actual object to compare." />
		<cfargument name="tolerance" type="numeric" required="yes" hint="">
		<cfargument name="message" type="string" required="false" default="" hint="Optional custom message to display if comparison fails." />

		<cfset var err = 0 />

		<cfif isNumeric(arguments.expected) and isNumeric(arguments.actual)>
			<cfset err = ABS(arguments.expected - arguments.actual) />
			<cfif err gt arguments.tolerance>
				<cfset failNotEquals(arguments.expected, arguments.actual, arguments.message) />
			</cfif>
		</cfif>

		<cfreturn true />

	</cffunction>

</cfcomponent>