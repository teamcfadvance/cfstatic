<!---
 Extension of TestResult

 --->
 <cfcomponent displayname="TextTestResult" output="no" extends="TestResult" hint="Responsible for generating plain text representation of a TestResult">
   <cfparam name="this.testRuns" type="numeric" default="0" />
   <cfparam name="this.failures" type="numeric" default="0" />
   <cfparam name="this.errors" type="numeric" default="0" />
   <cfparam name="this.successes" type="numeric" default="0" />
   <cfparam name="this.totalExecutionTime" type="numeric" default="0" />


   <cfparam name="this.resultsText" type="string" default='' />


   <cfparam name="tempTestCase" type="any" default="" />
   <cfparam name="tempTestComponent" type="any" default="" />
   <cfparam name="this.closeCalls" default="0" type="numeric" />

 <cffunction name="init" hint="Constructor" access="public" returntype="TextTestResult" output="false">
   <cfargument name="testResults" type="TestResult" required="false" />
   <!--- Get the array from the TestResult object --->
   <!--- Should be able to avoid this contstructor and get the
         results object from the super ... super.results ???

       --->
   <!--- <cfdump var="#arguments.testResults#"> --->
   <cfset this.testRuns = arguments.testResults.testRuns />
   <cfset this.failures = arguments.testResults.testFailures />
   <cfset this.errors = arguments.testResults.testErrors />
   <cfset this.successes = arguments.testResults.testSuccesses />
   <cfset this.totalExecutionTime = arguments.testResults.totalExecutionTime />
   <cfset buildTextResults(arguments.testResults.getQueryResults()) />
   <cfreturn  this />
 </cffunction>

  <cffunction name="getTextResults" access="public" returntype="any"  output="false">
    <cfset var ret = 'text results' />
    <cfreturn this.resultsText />
  </cffunction>


<!---
To Do: Add debug data [12.16.07::bill]
 --->
 <cffunction name="buildTextResults" access="public" output="false" returntype="void" hint="Builds the XML string based upon the given TestResult array">
   <cfargument name="results" type="query" required="true" />

   <cfscript>
    var builder = createObject('java', 'java.lang.StringBuilder');
    var lf = chr(10);
    var linesep = '-------------------------------------------------------------------------------------------------#lf#';
    builder.append('MXUnit Test Results. Run date: #dateFormat(now(),"mm/dd/yy hh:mm:ss")##lf#');
    builder.append(linesep);
    </cfscript>

    <cfoutput query="results">
      <cfset builder.append('Test: #component#.#testname#() #lf#') />
      <cfset builder.append('Status: #teststatus# #lf#  #lf#') />
      <cfif len(error)>
	     <cfset builder.append( "Failure: #error[2]# #lf# #lf#") />
			<cfif teststatus eq 'Error'>
			  <cfset builder.append('Error: #lf# #printStackTrace(error)#  #lf#') />
			</cfif>
			
		</cfif>
	   <cfset builder.append('*Trace/Debug:  #lf# #trace#  #lf#') />	
      <cfset builder.append(linesep) />
    </cfoutput>
    <cfscript>
      builder.append(lf);
      builder.append("Test Runs:" & this.testRuns & lf);
      builder.append("Successes:" & this.successes & lf);
      builder.append("Failures:" & this.failures & lf);
      builder.append("Errors:" & this.errors & lf);
      builder.append("Execution Time:" & this.totalExecutionTime/1000 & lf);
      this.resultsText = builder.toString();
   </cfscript>

  </cffunction>


<!---

 bill - 8.21.07 using this to print out tag stack trace ....
--->
<cffunction name="printStackTrace" access="public" returntype="string" output="false">
  <cfargument name="exception" type="any">
  <cfset var e = arguments.exception>
  <cfset var tArray= "">
  <cfset var i= "">
  <cfset var stackTrace= "">

  <cfparam name="e.type" default="mxunit.exception.GenericException">
  <cfparam name="cfcatch.extendedinfo" default="No extended info available.">

  <cfsavecontent variable="stackTrace">
    <cfoutput>
    Exception Type: #e.type# |
    Message: #e.message#  |
    Detail: #e.detail#  |
    (error code: #e.errorcode#) |

    Tag Stack Trace:  |
    <cfset tArray = e.tagContext>
    <cfloop from="1" to="#arrayLen(tArray)#" index="i">
      #tArray[i].template#
       Line Number: #tArray[i].line#
       Column: #tArray[i].column#  |
    </cfloop>
   </cfoutput>
  </cfsavecontent>
  <cfreturn stackTrace  />
</cffunction>



<cffunction name="constructTagContextElements" output="false" access="public" returntype="string" hint="returns the error's tagcontext formatted as xml">
	<cfargument name="exception" type="any">
	<cfset var tc = exception.tagcontext>
	<cfset var i = 1>
	<cfset var ret = "">
	<cfset var sep = createObject("java","java.lang.System").getProperty("file.separator")>
	<cfset var mxunitpath = "mxunit#sep#framework">
	<cfoutput>
	<cfsavecontent variable="ret">
	<cfloop from="1" to="#ArrayLen(tc)#" index="i">
		<cfif tc[i].template neq "<generated>"
			AND not findNoCase("Assert.cfc",tc[i].template)
			AND tc[i].line GT 0>
			trace:
				file: #tc[i].template#</file>
				line: #tc[i].line#</line>
		</cfif>
	</cfloop>
	</cfsavecontent>
	</cfoutput>
	<cfreturn ret>
</cffunction>



 </cfcomponent>
