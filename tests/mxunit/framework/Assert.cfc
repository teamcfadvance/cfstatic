<!---
Assert.cfc

Main component for performing assertions.

 --->
<cfcomponent displayname="Assert"
             hint="Main component for asserting state. You will not instantiate this component directly - the framework makes it available for your TestCases. Use this to see what assertions are available and note that it can easily be extended using the Assert.addDecortor() method or by editing the mxunit-config.xml file, following the examples therein.">

	<cfset variables.componentUtils = createObject("component", "ComponentUtils")>

	<cfset variables.testStyle = "default">

	<!--- A Note on these two class variables: We need a way to bus expected and actual values from equality assertions into the TestResult
	for a given test function; This is 'the simplest way that works' and is safe because tests in a testcase are synchronous;
	 if in the future we were to support asynchronous test function runs *within a test case*, this would break down--->
	<cfset variables.expected = "">
	<cfset variables.actual = "">

	<cffunction name="getExpected">
		<cfreturn expected>
	</cffunction>

	<cffunction name="getActual">
		<cfreturn actual>
	</cffunction>


	<cffunction name="clearClassVariables" access="public">
		<cfset variables.expected = "">
		<cfset variables.actual = "">
	</cffunction>

  <!--- Constructor;  named init instead of Assert because BlueDragon has a built-in
assert function and thus mxunit won't run on BD unless we do this --->
  <cffunction name="init" access="remote" returntype="Assert" hint="Constructor">
		
    <cfset addAssertDecorators() />
    <!---
    Leave this out for now ...
    <cfscript>
      //Load the JavaLoader and classes once
      this.paths = arrayNew(1);
	    //init to generic null objects
	    this.loader = createObject("java","java.lang.Object");
	    this.comparator = createObject("java","java.lang.Object");
	    this.paths[1] = expandPath("#this.installRoot#/mxunit/framework/lib/mxunit-ext.jar");
			this.loader = createObject("component", "mxunit.framework.JavaLoader").init(this.paths);
	    this.comparator = this.loader.create("CompareObjects").init();
	   </cfscript> --->
    <cfreturn this />
   <!--- Read from config file for assertion packages to add. If file is not found, ignore. --->
  </cffunction>

<!--- Utility for dynamically adding assertion behaviors at runtime --->
<!--- Given a component, adds all existing methods to the current VARIABLES and THIS scope --->
 <cffunction name="addAssertDecorator" access="public" returntype="void" static="true" hint="Method used to dynamically add additional custom assertions at runtime. ">
   <cfargument name="decoratorName" type="string" hint="The fully qualied name of the assertion component to add; e.g., org.mycompany.MyAssertionComponent" />
   <cfargument name="overrideBehaviors" type="string" required="false" default="false" hint="Tells the framework whether or not to override any existing behaviors. For example, if your org.mycompany.MyAssertionComponent component has an assertTrue() and overridBehaviors is set to TRUE, the mxunit framework will use the new assertTrue() method and not it's own." />
   <cfset var decorator = "" />
   <cfset var functions = "" />
   <cfset var i= "">

   <cftry>
   	

   <cfset decorator = createObject("component", arguments.decoratorName) />

   <cfset functions = getMetadata(decorator).functions>
    <!--- <cfdump var="#functions#">
  <cfoutput>#decoratorName# = #arraylen(functions)#</cfoutput>--->
   <cfloop from="1" to="#arrayLen(functions)#"  index="i">

	  <cfparam name="functions[#i#].access" default="public">
      <cfif NOT listFindNoCase("package,private", functions[i].access)>
        <cfif arguments.overrideBehaviors is "true">
          <cfset "variables.#functions[i].name#" = evaluate("decorator.#functions[i].name#") />
          <cfset "this.#functions[i].name#" = evaluate("decorator.#functions[i].name#") />
          <cfelse>
            <!--- Only write the function to the scope if it does not exist --->
            <cfif not structKeyExists(variables, functions[i].name)>
              <cfset "variables.#functions[i].name#" = evaluate("decorator.#functions[i].name#") />
              <cfset "this.#functions[i].name#" = evaluate("decorator.#functions[i].name#") />
            </cfif>
        </cfif>
      </cfif>

  </cfloop>
  <cfcatch type="coldfusion.runtime.CfJspPage$NoSuchTemplateException">
    <cfthrow type="mxunit.exception.NamedDecoratorNotFoundException" message="The Decorator, #arguments.decoratorName# , was not found."
            detail="Make sure the component is located correctly in the mxunit framework." />
    <cflog file="mxunit" type="error" application="false" text="#cfcatch.message#::#cfcatch.detail#">
  </cfcatch>
  </cftry>
 </cffunction>



  <cffunction name="addAssertDecorators" access="public" returntype="void" static="true" hint="Loads any assertions defined in mxunt-config.xml at runtime.">
   <cfset var elements          = createObject("java","java.lang.Object") />
   <cfset var assertPackageName = createObject("java","java.lang.String") />
   <cfset var overrideDefaultBehaviors = createObject("java","java.lang.String") />
   <cfset var assertionExtensionXpath =  "/mxunit-config/config-element[@type='assertionExtension' and @autoload='true']"  />
   <cfset var configMgr = createObject("component","ConfigManager").ConfigManager() />
   <cfset var i= "">
   <cftry>
     <cfset elements = configMgr.getConfigElements(assertionExtensionXpath) />
     <cfloop from="1" to="#arrayLen(elements)#" index="i">
       <cfset assertPackageName = elements[i].xmlAttributes.path />
       <cfset overrideDefaultBehaviors = elements[i].xmlAttributes.override />
       <cfset addAssertDecorator(assertPackageName, overrideDefaultBehaviors) />
     </cfloop>
   <cfcatch type="mxunit.exception.NamedDecoratorNotFoundException">
     <!--- No worries, mon --->
     <cflog file="mxunit" type="error" application="false" text="#cfcatch.message#::#cfcatch.detail#">
     <cfthrow type="mxunit.exception.AssertionLoadingException" message="Failed to load external Assertion packages. See mxunit-default-log for details." detail="See mxunit-default-log for details.">
   </cfcatch>
   <cfcatch type="any">
     <!--- Ruh-row, Raggie! --->
     <cfthrow object="#cfcatch#">
     <cflog file="mxunit" type="error" application="false" text="#cfcatch.message#::#cfcatch.detail#">
   </cfcatch>
  </cftry>
 </cffunction>




  <!--- convenience (sort of...maybe) for enabling users of cfunit to convert their stuff without terrible pain. a test case would need to use setTestStyle('cfunit') in the constructor or setUp method of a test --->
  <cffunction name="setTestStyle" access="public" hint="Sets the current test style.">
    <cfargument name="TestStyle" type="string" required="true" hint="Use 'default' to have the framework behave like cfcunit with respect to arguments; otherwise, pass 'cfunit' to behave like cfunit (i.e. for certain assertions, the message is the first arg). This only affects assertEquals and assertTrue">
    <cfset variables.TestStyle = arguments.TestStyle>
  </cffunction>

  <cffunction name="getTestStyle" access="public" output="false" hint="returns the current test style">
    <cfreturn variables.TestStyle>
  </cffunction>

  <cffunction name="fail" access="public" returntype="void" static="true" hint="Fails a test with the given MESSAGE.">
   <cfargument name="message" required="true" type="string" hint="Custom message to print in the failure."  />
   <cfset var mess = "">
	 <cfif arguments.message is ''>
			<cfset mess = "mxunit test failure">
	 <cfelse>
		  <cfset mess = arguments.message />
	 </cfif>
   <cfthrow type="mxunit.exception.AssertionFailedError" message="#mess#" />
  </cffunction>

	<cffunction name="failEquals" access="private" returntype="void" static="true" hint="Fails the test and prints the expected and actual values to the failure message">
     <cfargument name="expected" type="any" required="yes" hint="The expected string value"  />
	   <cfargument name="actual"   type="any" required="yes" hint="The actual string value" />
	   <cfargument name="message" required="false" default="This test failed" hint="Custom message to print in the failure." />
	   <!---<cfset arguments = normalizeArguments("equals",arguments)>   --->
	    <cfthrow type="mxunit.exception.AssertionFailedError" message="#arguments.message#:: Expected [#getStringValue(arguments.expected)#] BUT RECEIVED [#getStringValue(arguments.actual)#]. These values should not be the same. " />
   </cffunction>

  <cffunction name="failNotEquals" access="private" returntype="void" static="true" hint="Fails the test and prints the expected and actual values to the failure message">
    <cfargument name="expected" type="any" required="yes" hint="The expected string value"  />
    <cfargument name="actual"   type="any" required="yes" hint="The actual string value" />
    <cfargument name="message" required="false" default="This test failed" hint="Custom message to print in the failure." />
    <cfargument name="caseSensitive" required="false" default="false" hint="Whether or not to print values in original case." />
    <!---<cfset arguments = normalizeArguments("equals",arguments)>  --->
		<cfif isSimpleValue(expected) AND isSimpleValue(actual)>
			<cfset variables.expected = arguments.expected>
			<cfset variables.actual = arguments.actual>
		</cfif>
	    <cfthrow type="mxunit.exception.AssertionFailedError" message="#arguments.message#:: Expected [#getStringValue(arguments.expected,arguments.caseSensitive)#] BUT RECEIVED [#getStringValue(arguments.actual,arguments.caseSensitive)#]. These values should be the same. " />
	  </cffunction>

 <cffunction name="getStringValue" returntype="string" access="public" hint="Attempts to return string representation of OBJ. Tests to see if object has toString or stringValue methods to be used for comparison and returns that string if present">
  <cfargument name="obj" type="any" required="yes" hint="Any object" />
  <cfargument name="caseSensitive" type="boolean" required="false" default="false" hint="If set to TRUE returns the original string unaltered. Default is to return the string in lowercase" />
  <cfset var val = "" />
  <!--- Just try to get a string representation --->
  <cftry>
	<cfif IsQuery(arguments.obj)>
		<cfwddx action="cfml2wddx" input="#arguments.obj#" output="val">
		<cfelse>
		<cfset val = obj.toString()>
	</cfif>
  <cfcatch type="any">
    <cftry>
       <cfset val = obj.stringValue()>
       <cfcatch type="any">
         <!--- This works but maybe should be more elegant --->
         <!--- If we cannot get a string representation, assign a unique one to it --->
        <cfset val = "Component=" & getMetaData(obj).name />
      </cfcatch>
    </cftry>
    </cfcatch>
  </cftry>
  <cfif arguments.caseSensitive>
   <cfreturn val />
  <cfelse>
   <cfreturn lcase(val) />
  </cfif>

  </cffunction>

<cffunction name="getHashCode" returntype="string" access="public" hint="Attempts to return hashCode representation of OBJ. Returns 0 for deep structs and component name or, if defined, the stringValue() representation of the component.">
  <cfargument name="obj" type="any" required="yes" hint="Any object" />
   <cfset var val = -1 />
  <cftry>
   <cfset val = obj.hashCode()>
   <!--- If this fails, it's a CFC, so,try to get string value instead --->
  <cfcatch type="any">
    <cftry>
       <cfset val = obj.stringValue()>
       <cfcatch type="any">
         <!--- This works but maybe should be more elegant --->
         <!--- If we cannot get a string representation, assign a unique one to it --->
        <cfset val = "Component=" & getMetaData(obj).name />
      </cfcatch>
    </cftry>
    </cfcatch>
  </cftry>
  <cfreturn val />
  </cffunction>



  <cffunction name="assertEquals" access="public" returntype="void" hint="Core assertion that compares the values the EXPECTED and ACTUAL parameters. Throws mxunit.exception.AssertionFailedError.">
    <cfargument name="expected" type="any" required="yes" hint="The expected object to compare."  />
    <cfargument name="actual"   type="any" required="yes" hint="The actual object to compare."  />
	  <cfargument name="message"  type="string" required="no" default="" hint="Optional custom message to display if comparison fails." />

	  <cfset var expectedStringValue = "">
	  <cfset var actualStringValue = "">
	  <cfset arguments = normalizeArguments("equals",arguments)>
	  <cfset expectedStringValue = getStringValue(arguments.expected) />
	  <cfset actualStringValue = getStringValue(arguments.actual) />
    <cfscript>

		if( isStruct( expected ) AND isStruct( actual ) ){
			assertStructEquals( expected, actual, message );
			return;
		}

		if( isQuery( expected ) AND isQuery( actual ) ){
			assertQueryEquals( expected, actual, message );
			return;
		}

		if( isArray(expected) AND isArray( actual ) ){
			assertArrayEquals( expected, actual, message );
			return;
		}

		if (isNumeric(arguments.expected) AND isnumeric(arguments.actual) AND arguments.expected eq arguments.actual){
			return;
		}
		if (expectedStringValue is "" AND actualStringValue is ""){
			return;
		}
		if (expectedStringValue is not "" AND expectedStringValue.equals(actualStringValue)){
			return;
		}
		failNotEquals(expectedStringValue, actualStringValue, arguments.message);
    </cfscript>
  </cffunction>


<cffunction name="assertNotEquals" access="public" returntype="void" hint="Core assertion that compares the values the EXPECTED and ACTUAL parameters. Throws mxunit.exception.AssertionFailedError.">
    <cfargument name="expected" type="any" required="yes" hint="The expected object to compare."  />
    <cfargument name="actual"   type="any" required="yes" hint="The actual object to compare."  />
	  <cfargument name="message"  type="string" required="no" default="" hint="Optional custom message to display if comparison fails." />

	   <cfset var expectedStringValue = "">
	   <cfset var actualStringValue = "">
	   <cfset arguments = normalizeArguments("equals",arguments)>
	   <cfset expectedStringValue = getStringValue(arguments.expected) />
	   <cfset actualStringValue = getStringValue(arguments.actual) />
	   <cfscript>
		   if (isNumeric(arguments.expected) AND isnumeric(arguments.actual) AND arguments.expected eq arguments.actual){
		     failEquals(expectedStringValue, actualStringValue, arguments.message);
		   }
		   if (expectedStringValue is "" AND actualStringValue is ""){
		     failEquals(expectedStringValue, actualStringValue, arguments.message);
		     }
		   if (expectedStringValue is not "" AND expectedStringValue.equals(actualStringValue)){
		     failEquals(expectedStringValue, actualStringValue,arguments.message);
		   }
		   return;
	 </cfscript>
   </cffunction>


  <cffunction name="assertEqualsCase" access="public" returntype="void" hint="Core assertion that compares the values the EXPECTED and ACTUAL parameters. Throws mxunit.exception.AssertionFailedError. This is case sensitive.">
    <cfargument name="expected" type="any" required="yes" hint="The expected object to compare."  />
    <cfargument name="actual"   type="any" required="yes" hint="The actual object to compare."  />
	  <cfargument name="message"  type="string" required="no" default="" hint="Optional custom message to display if comparison fails." />

	  <cfset var expectedStringValue = "">
	  <cfset var actualStringValue = "">
	  <cfset arguments = normalizeArguments("equals",arguments)>
	  <cfset expectedStringValue = getStringValue(arguments.expected, true) />
	  <cfset actualStringValue = getStringValue(arguments.actual, true) />
    <cfscript>
		  if (isNumeric(arguments.expected) AND isnumeric(arguments.actual) AND arguments.expected eq arguments.actual){
		    return;
		  }
		    if (expectedStringValue is "" AND actualStringValue is ""){
		    return;
		    }
		  if (expectedStringValue is not "" AND expectedStringValue.equals(actualStringValue)){
		    return;
		  }
		  failNotEquals(expectedStringValue, actualStringValue, arguments.message, true); //last arg is caseSensitive flag
    </cfscript>
  </cffunction>

  	<cffunction name="assertQueryEquals" access="public" output="false" returntype="void" description="compares 2 queries, cell by cell, and fails if differences exist">
    	<cfargument name="expected" type="query" required="true"/>
    	<cfargument name="actual" type="query" required="true"/>
		<cfargument name="message" type="string" required="false" default=""/>

		<cfset var compareResult = "">
		<cfinvoke component="DataCompare" method="compareQueries" query1="#expected#" query2="#actual#" returnvariable="compareResult">

		<cfif not compareResult.success>
			<cfset debug(compareResult)>
			<cfset assertEquals( compareResult.Query1MismatchValues, compareResult.Query2MismatchValues, "Expected queries to match but they did not. See debug output for a visual display of the differences. #compareResult.Message#. #arguments.message#" )>
		</cfif>
    </cffunction>

    <cffunction name="assertStructEquals" output="false" access="public" returntype="any" hint="compares two structures, key by key, and fails if differences exist">
    	<cfargument name="expected" type="struct" required="true"/>
    	<cfargument name="actual" type="struct" required="true"/>
		<cfargument name="message" type="string" required="false" default=""/>

		<cfset var compareResult = "">
		<cfinvoke component="DataCompare" method="compareStructs" struct1="#expected#" struct2="#actual#" returnvariable="compareResult">

		<cfif not compareResult.success>
			<cfset debug(compareResult)>
			<cfset assertEquals( compareResult.Struct1MismatchValues, compareResult.Struct2MismatchValues, "Expected Structures to match but did not. See debug output for a visual display of the differences. #compareResult.message# #arguments.message#")>
		</cfif>
    </cffunction>

    <cffunction name="assertArrayEquals" output="false" access="public" returntype="any" hint="compares two arrays, element by element, and fails if differences exist">
    	<cfargument name="expected" type="array" required="true"/>
    	<cfargument name="actual" type="array" required="true"/>
		<cfargument name="message" type="string" required="false" default=""/>

		<cfset var compareResult = "">
		<cfinvoke component="DataCompare" method="compareArrays" array1="#expected#" array2="#actual#" returnvariable="compareResult">
		<cfif not compareResult.success>
			<cfset debug(compareResult)>
			<cfset assertEquals( compareResult.array1MismatchValues, compareResult.array2MismatchValues, "Expected arrays to match but did not. See debug output for a visual display of the differences. #compareResult.message#. #arguments.message#")>
		</cfif>
    </cffunction>

  <cffunction name="assertTrue" access="public" returntype="boolean" hint="Core assertion that tests the CONDITION and throws mxunit.exception.AssertionFailedError on failure">
  	<cfargument name="condition" required="yes" type="string" hint="The condition to test. Note that expressions containing CFCs may likely fail">
    <cfargument name="message" required="no" default="" type="string"  hint="Optional custom message to display if comparison fails.">
    <!---
     Caveat: If the user is passing in an expression that contains CFC
     object comparisons, it will fail. The only way to address this would
     be to parse the expression being entered. So, if a comparison is being
     performed, assertEquals should be used.
    --->
  	<cfset arguments = normalizeArguments("true",arguments)>

     <cfif not arguments.condition>
      <cfinvoke method="fail" message="#arguments.message#" />
    </cfif>
    <cfreturn true>
   </cffunction>



	<cffunction name="assertFalse" access="public">
	  <cfargument name="condition" required="yes" type="string">
	  <cfargument name="message" required="no" default="" type="string">
 	  <cfset arguments = normalizeArguments("true",arguments)>
	  <cfif arguments.condition>
	    <cfset fail(arguments.message)>
	  </cfif>
	</cffunction>


  <cffunction name="assertSame" access="public" output="false">
    <cfargument name="expected" required="yes" type="any" />
    <cfargument name="actual" required="yes" type="any" />
    <cfargument name="message" required="no" default="The two objects do not refer to the same instance." type="string">

    <cfscript>
      var system = createObject("java", "java.lang.System");
      var expect = system.identityHashCode(arguments.expected);
      var act = system.identityHashCode(arguments.actual);
      //Arrays are passed by value in CF ...
      if(isArray(arguments.expected) or isArray(arguments.actual)){
      throwWrapper("mxunit.exception.CannotCompareArrayReferenceException","Cannot compare array references in ColdFusion","Arrays in ColdFusion are passed by value. To compare instances, you may wrap the array in a struct and compare those.");
      }
      if(expect eq act){
        return;
      }
	 fail(arguments.message);
	 </cfscript>

  </cffunction>


  <cffunction name="assertNotSame" access="public">
    <cfargument name="expected" required="yes" type="any" />
    <cfargument name="actual" required="yes" type="any" />
    <cfargument name="message" required="no" default="The two objects refer to the same instance." type="string">

    <cfscript>
      var system = createObject("java", "java.lang.System");
      var expect = system.identityHashCode(arguments.expected);
      var act = system.identityHashCode(arguments.actual);
      //Arrays are passed by value in CF ...
      if(isArray(arguments.expected) or isArray(arguments.actual)){
        throwWrapper("mxunit.exception.CannotCompareArrayReferenceException","Cannot compare array references in ColdFusion","Arrays in ColdFusion are passed by value. To compare instances, you may wrap the array in a struct and compare those.");
      }
      if(not expect eq act){
        return;
      }
     fail(arguments.message);
    </cfscript>
  </cffunction>

 <!---
  Returned THIS for method chaining. Not sure if that will provide any value ...
  --->
  <cffunction name="assert" access="public" hint="Basic assertion. Same effect as assertTrue()">
    <cfargument name="condition" required="yes" type="string" hint="The condition to test. Note that expressions containing CFCs may likely fail">
    <cfargument name="message" required="no" default="" type="string"  hint="Optional custom message to display if comparison fails.">
    <cfset assertTrue(condition,message) />
    <cfreturn this />
  </cffunction>

  <cffunction name="throwWrapper" returntype="void">
    <cfargument name="type" type="string" required="true" />
    <cfargument name="message" type="string" required="true" />
    <cfargument name="detail" type="string" required="true" />
    <cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#" />
  </cffunction>


  <cffunction name="normalizeArguments" access="private" hint="Used by framework and is merely a convenience for cfunit style tests and their assertEquals and assertTrue methods" returntype="struct">
    <cfargument name="AssertType" required="true" type="string">
    <cfargument name="Args" required="true" type="struct">
    <cfset var s_args = StructNew()>

    <cfif variables.TestStyle eq "default">
      <cfreturn args>
    </cfif>

    <cfswitch expression="#Arguments.AssertType#">
      <cfcase value="equals">
        <!--- this is the diciest one of them and we'll get it wrong if they use named args! --->

        <cfset s_args.expected = args.actual>
        <cfset s_args.actual = args.message>
        <cfset s_args.message = args.expected>

      </cfcase>
      <cfcase value="true">
        <!--- this attempts to ensure that if they are using named arguments that this doesn't go mucking it up --->
        <cfif isBoolean(args.condition) and not isBoolean(args.message)>
          <cfset s_args = args>
        <cfelse>
          <cfset s_args.message = args.condition>
          <cfset s_args.condition = args.message>
        </cfif>

      </cfcase>

      <cfdefaultcase>
        <cfreturn args>
      </cfdefaultcase>
    </cfswitch>

    <cfreturn s_args>
  </cffunction>





</cfcomponent>