<!---
	Extension of TestResult
--->
<cfcomponent displayname="HTMLTestResult" output="true"	extends="TestResult" hint="Responsible for generating HTML representation of a TestResult">
	<cfparam name="this.testResults" type="any" default="" />


	<cffunction name="HTMLTestResult" hint="Constructor" access="public" returntype="HTMLTestResult">
		<cfargument name="testResults" type="TestResult" required="false" />

		<cfset this.testRuns = arguments.testResults.testRuns />
		<cfset this.failures = arguments.testResults.testFailures />
		<cfset this.errors = arguments.testResults.testErrors />
		<cfset this.successes = arguments.testResults.testSuccesses />
		<cfset this.totalExecutionTime = arguments.testResults.totalExecutionTime />
		<cfset this.testResults = arguments.testResults.results />
		<cfset this.installRoot = createObject("component","ComponentUtils").getInstallRoot() />
    <cfset totalBad = this.failures+this.errors />
    <cfif totalBad eq 0 >
      <cfset this.sucessRatio = 1 />
     <cfelse>
      <cfset this.sucessRatio = 1-(totalBad/this.testRuns) />
    </cfif>

    <!---
    iif( this.failures+this.errors eq 0, 1, this.failures+this.errors )
    double prod = 0.0;
        double errorsAndFailures = (double) this.totalErrors + (double) this.totalFailures;
        if (this.totalTestRuns > 0) {
            prod = (errorsAndFailures / (double) this.totalTestRuns);
        }
        return (1 - prod);

     --->
		<cfreturn this />
	</cffunction>



	<!--- bill : 3.7.10

			Todo: Make sure it works with no external CSS or JavaScript. Maybe redirect to old XMLResult if JS is not enabled?
			Todo: Filter should work with components. That is, when filtering results of a TestSuite, if suite
			      doesn't contain filter items (empty) it should not display.

   --->

	<cffunction name="printResources" access="public" output="true" hint="Prints CSS and JavaScript refs for stylizing">
 		<cfargument name="mxunit_root" required="no" default="./mxunit" hint="Location in the webroot where MXUnit is installed." />
		<cfargument name="test_title" required="false" default="MXUnit Test Results" offhint="An HTML title to display for this test" />
			<link rel="stylesheet" type="text/css" href="#mxunit_root#/resources/theme/styles.css">
			<link rel="stylesheet" type="text/css" href="#mxunit_root#/resources/jquery/tablesorter/green/style.css">
			<link rel="stylesheet" type="text/css" href="#mxunit_root#/resources/theme/results.css">
			<link rel="stylesheet" type="text/css" href="#mxunit_root#/resources/jquery/tipsy/stylesheets/tipsy.css">

			<script type="text/javascript" src="#mxunit_root#/resources/jquery/jquery.min.js"></script>
			<script type="text/javascript" src="#mxunit_root#/resources/jquery/jquery-ui.min.js"></script>
			<script type="text/javascript" src="#mxunit_root#/resources/jquery/jquery.sparkline.min.js"></script>
			<script type="text/javascript" src="#mxunit_root#/resources/jquery/tablesorter/jquery.tablesorter.js"></script>
			<script type="text/javascript" src="#mxunit_root#/resources/jquery/tipsy/javascripts/jquery.tipsy.js"></script>
			<script type="text/javascript" src="#mxunit_root#/resources/jquery/jquery.runner.js"></script>

      <title>#test_title#</title>
	</cffunction>

	<cffunction name="getHtmlResults" access="public" returntype="string" output="false" hint="Returns a stylized HTML representation of the TestResult">
		<cfargument name="mxunit_root" required="no" default="#this.installRoot#" hint="Location in the webroot where MXUnit is installed." />
		<cfargument name="test_title" required="false" default="MXUnit Test Results" hint="An HTML title to display for this test">

		<cfset var result = "" />
		<cfset var temp = "" />

		<cfsavecontent variable="result">
			<cfset printResources(mxunit_root,test_title) />
			<cfoutput>#trim(getRawHtmlResults(mxunit_root))#</cfoutput>
		</cfsavecontent>

		<cfreturn result>
	</cffunction>

	<cffunction name="getRawHtmlResults" access="public" returntype="string" output="false" hint="Returns a _raw_ HTML representation of the TestResult">
		<cfargument name="mxunit_root" required="no" default="#this.installRoot#" hint="Location in the webroot where MXUnit is installed." />

		<cfset var result = "" />
		<cfset var classname = "" />
		<cfset var i = "" />
		<cfset var k = "" />
		<cfset var isNewComponent = false />
		<cfset var tableHead = '' />
		<cfset var theme = "pass" />
		<cfset var debugMessage = "Run with verbose debug output." />
		<cfset var toggledUrl = "" />

		<cfif this.successes neq this.testRuns>
			<cfset theme = "fail" />
		</cfif>

		<cfsavecontent variable="tableHead">
			<thead>
				<tr>
					<th class="test">Test</th>
					<th class="error">Error Info</th>
					<th class="output">Output</th>
					<th class="result">Result</th>
					<th class="speed">Speed</th>
				</tr>
			</thead>
		</cfsavecontent>

		<cfsavecontent variable="result">
			<cfoutput>
				<div class="mxunitResults">
					<div class="summary">
						<ul class="nav horizontal">
							<li class="failed">
								<a href="##" rel="tipsy" title="Filter by Failures">#this.failures# Failures</a>
							</li>
							<li class="error">
								<a href="##" rel="tipsy" title="Filter by Errors">#this.errors# Errors</a>
							</li>
							<li class="passed">
								<a href="##" rel="tipsy" title="Filter by Successes">#this.successes# Successes</a>
							</li>
						</ul>

						<!-- brain no working, but this does --->
						<cfif find('debug=true',cgi.QUERY_STRING)>
							<cfset toggledUrl = cgi.SCRIPT_NAME & '?' & replace(cgi.QUERY_STRING,'debug=true','debug=false') />
							<cfset bugMessage = 'Run without debug output.' />
						<cfelseif find('debug=false',cgi.QUERY_STRING)>
							<cfset toggledUrl = cgi.SCRIPT_NAME  & '?' & replace(cgi.QUERY_STRING,'debug=false','debug=true')  />
							<cfset bugMessage = 'Run with verbose debug output.' />
						<cfelse>
							<cfset toggledUrl = cgi.SCRIPT_NAME  & '?' & cgi.QUERY_STRING & '&debug=true'  />
							<cfset bugMessage = 'Run with verbose debug output.' />
						</cfif>

						<div id="bugjar">
							<a id="bug" href="#toggledUrl#" rel="tipsy" title="#bugMessage#"><img border="0" height="24" align="absmiddle" src="#mxunit_root#/images/bug_green.gif"></a>
						</div>

						<div id="sparkcontainer" rel="tipsy" title="#this.testRuns# tests in #this.totalExecutionTime#ms. Success ratio #int(this.sucessRatio*100)#%">
							<span class="mxunittestsparks">
								Replace this in HTMLTestResult <cfscript>
									//generate data for sparkline
									for(i=1;i lte this.failures;i=i+1){
										writeoutput(-1 & ",");
									}
									for(i=1;i lte this.errors;i=i+1){
										writeoutput(-2 & ",");
									}
									for(i=1;i lte this.successes;i=i+1){
										writeoutput(1 & ",");
									}

									i=1;
								</cfscript>
							</span>
						</div>

						<div class="clear"><!-- clear --></div>
					</div>

					<cfloop from="1" to="#ArrayLen(this.testResults)#" index="i">
						<!--- Check if we are on a new component --->
						<cfset isNewComponent = classname neq this.testResults[i].component />

						<cfif isNewComponent>
							<!--- If this is not the first component close the previous one --->
							<cfif classname neq ''>
									</tbody>
								</table>
							</cfif>
							<cfset classname = this.testResults[i].component>
							<!--- printing incorrect results for MXUnitInstallTest.cfc - could be engine bug --->
							<cfset classtesturl = CGI.CONTEXT_PATH & "/" & Replace(this.testResults[i].component, ".", "/", "all") & ".cfc?method=runtestremote&amp;output=html">

							<h3><a href="#classtesturl#" title="Run all tests in #this.testResults[i].component#">#this.testResults[i].component#</a></h3>

							<table class="results tablesorter #theme#">
								#tableHead#
								<tbody>
						</cfif>

						<tr class="#lCase(this.testResults[i].TestStatus)#">
							<td class="test">
								<a href="#classtesturl#&amp;testmethod=#this.testResults[i].TestName#" title="only run the #this.testResults[i].TestName# test">#this.testResults[i].TestName#</a>
							</td>
							<td class="error">
								#renderErrorStruct(this.testResults[i].Error)#
							</td>
							<td class="output">
								<cfif find('debug=true',cgi.QUERY_STRING)>
									<cfif ArrayLen(this.testResults[i].Debug)>
										<cfloop from="1" to="#ArrayLen(this.testResults[i].Debug)#" index="k">
											<cfif IsSimpleValue(this.testResults[i].Debug[k].var)>
												#this.testResults[i].Debug[k].var#<br />
											<cfelse>
												<cfdump attributecollection="#this.testResults[i].Debug[k]#">
											</cfif>
										</cfloop>
									</cfif>
								</cfif>
							</td>
							<td class="result">
								#this.testResults[i].TestStatus#
							</td>
							<td class="speed">
								#this.testResults[i].Time# ms
							</td>
						</tr>
					</cfloop>
						</tbody>
					</table>
				</div>
			</cfoutput>
		</cfsavecontent>

		<cfreturn Trim(result) />
	</cffunction>

	<cffunction name="renderErrorStruct" output="false" returntype="string" access="private" hint="I render a coldfusion error struct as HTML">
		<cfargument name="ErrorCollection" required="true" type="any">

		<cfset var result = "" />
		<cfset var i = 0 />
		<cfset var template = "" />
		<cfset var line = "" />

		<cfif NOT IsSimpleValue(arguments.ErrorCollection)>
			<cfsavecontent variable="result">
				<cfoutput>
					<cfif Left(arguments.ErrorCollection.Message, 2) neq "::">
						<strong>#Replace(arguments.ErrorCollection.Message,"::","<br />")#</strong> <br />
						<pre style="width:100%;">#arguments.ErrorCollection.Detail#</pre>
					<cfelse>
						#arguments.ErrorCollection.Message#
					</cfif>

					<table class="tagcontext">
						<cfloop from="1" to="#ArrayLen(arguments.ErrorCollection.TagContext)#" index="i">
							<cfset template = arguments.ErrorCollection.TagContext[i].template />
							<cfset line = arguments.ErrorCollection.TagContext[i].line />
							<tr>
								<td>
									#template# (<a href="txmt://open/?url=file://#template#&line=#line#" title="Open this in TextMate">#line#</a>)
								</td>
							</tr>
						</cfloop>
					</table>
				</cfoutput>
			</cfsavecontent>
		</cfif>

		<cfreturn result />
	</cffunction>
</cfcomponent>
