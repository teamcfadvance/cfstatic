<!---
 Extension of TestResult
 --->
 <cfcomponent displayname="QueryTestResult" output="true" extends="TestResult" hint="Responsible for generating CFQuery representation of a TestResult">
  <cfparam name="this.testResults" type="any" default="" /> 


 <cffunction name="QueryTestResult" hint="Constructor" access="public" returntype="QueryTestResult">
   <cfargument name="testResults" type="TestResult" required="false" />
   <cfset this.testRuns = arguments.testResults.testRuns />
   <cfset this.failures = arguments.testResults.testFailures />
   <cfset this.errors = arguments.testResults.testErrors />
   <cfset this.successes = arguments.testResults.testSuccesses />
   <cfset this.totalExecutionTime = arguments.testResults.totalExecutionTime /> 
   <cfset this.testResults = arguments.testResults.results />
   <cfreturn  this />
 </cffunction>



 <cffunction name="getQueryResults" access="public" returntype="any" output="true" hint="Returns a CFQuery representation of the TestResult">
   <cfscript>
    var i = 1;
    var q = queryNew( StructKeyList(this.testResults[i]) );
    for (i = 1; i lte arraylen(this.testResults); i = i + 1){
    queryAddRow(q);
     for(test in this.testResults[i]){
      querySetCell(q, test, this.testResults[i][test]);
     } 
    }
    return q;   
   </cfscript>
 </cffunction>



 </cfcomponent>