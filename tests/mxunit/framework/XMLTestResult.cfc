<!---
 Extension of TestResult

 --->
 <cfcomponent displayname="XMLTestResult" output="no" extends="TestResult" hint="Responsible for generating XML representation of a TestResult">
   <cfparam name="this.testRuns" type="numeric" default="0" />
   <cfparam name="this.failures" type="numeric" default="0" />
   <cfparam name="this.errors" type="numeric" default="0" />
   <cfparam name="this.successes" type="numeric" default="0" />
   <cfparam name="this.totalExecutionTime" type="numeric" default="0" />


   <cfparam name="this.resultsXML" type="string" default='<?xml version="1.0" encoding="UTF-8"?>' />


   <cfparam name="tempTestCase" type="any" default="" />
   <cfparam name="tempTestComponent" type="any" default="" />
   <cfparam name="this.closeCalls" default="0" type="numeric" />

 <cffunction name="XmlTestResult" hint="Constructor" access="public" returntype="XMLTestResult">
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
   <cfset buildXmlresults(arguments.testResults.getResults()) />
   <cfreturn  this />
 </cffunction>



 <cffunction name="getXMLDomResults" access="public" returntype="xml" output="false" hint="Returns an XML DOM representation of the TestResult">
   <cfset var dom= "" />
   <cfset dom = xmlParse(this.resultsXML) />
   <cfreturn dom />
 </cffunction>


 <cffunction name="getXMLResults" access="public" returntype="string" output="false" hint="Returns an XML String representation of the TestResult">
   <!--- <cfinvoke method="buildXmlResults" /> --->
   <cfset var dom= "" />
   <cfset dom = this.resultsXML />
   <cfreturn dom />
 </cffunction>

 <!--- Temporary method for transforming XML ... --->
  <cffunction name="getHtmlResults" access="public" returntype="any"  output="false">
    <cfargument name="xsltStyleSheet" required="no" default="#getXslt()#" />
    <cfinvoke method="closeResults" />
        <!--- for debugging ... --->
        <!--- <cfreturn this.resultsXML /> --->

    <cfreturn xmlTransform(this.resultsXML, xsltStyleSheet) />
  </cffunction>


<!---
To Do: Add debug data [12.16.07::bill]
 --->
 <cffunction name="buildXmlResults" access="public" output="false" returntype="void" hint="Builds the XML string based upon the given TestResult array">
   <cfargument name="results" type="array" required="true" />
   <cfset var i= "" />
  <cfscript>
   this.resultsXML = this.resultsXML & '<test_results hostname="#cgi.remote_host#" tests="#this.testRuns#" failures="#this.failures#" errors="#this.errors#" timestamp="#now()#" time="#this.totalExecutionTime#">';
   for(i = 1; i lte arrayLen(arguments.results); i = i + 1){
	   testResults = arguments.results[i];
	   this.resultsXML = this.resultsXML & '<test_case number="#testResults.number#" component="#testResults.component#" testname="#testResults.testname#">';
	   this.resultsXML = this.resultsXML & '<date><![CDATA[#testResults.dateTime#]]></date>';
	   this.resultsXML = this.resultsXML & '<time><![CDATA[#testResults.time#]]></time>';
	   this.resultsXML = this.resultsXML & '<results>';
	   this.resultsXML = this.resultsXML & "<trace>";
	   this.resultsXML = this.resultsXML & "<![CDATA[#testResults.trace#]]>";
	   this.resultsXML = this.resultsXML & "</trace> ";
	   this.resultsXML = this.resultsXML & '<message><![CDATA[#testResults.testStatus#]]></message>';
	   if( listFindNoCase("Failed,Error",testResults.testStatus)){
	   	this.resultsXML = this.resultsXML & '<exception><![CDATA[#testResults.error.type#: #testResults.error.message#]]></exception>';
	   	this.resultsXML = this.resultsXML & '<error><![CDATA[#printStackTrace(testResults.error)#]]></error>'; //
	   }
	   else {
	   	 this.resultsXML = this.resultsXML & '<error><![CDATA[]]></error>'; //
	   }

	   this.resultsXML = this.resultsXML & '<content><![CDATA[#testResults.content#]]></content>';
	   this.resultsXML = this.resultsXML & '</results>';
	   this.resultsXML = this.resultsXML & '</test_case>';
   }
   this.resultsXML = this.resultsXML & '</test_results>';
  </cfscript>
</cffunction>


<!---

 bill - 8.21.07 using this to print out tag stack trace ....
--->
<cffunction name="printStackTrace" access="public" returntype="string">
  <cfargument name="exception" type="any">
  <cfset var e = arguments.exception>
  <cfset var tArray= "">
  <cfset var i= "">
  <cfset var stackTrace= "">

  <cfparam name="e.type" default="mxunit.exception.GenericException">
  <cfparam name="cfcatch.extendedinfo" default="No extended info available.">

  <cfsavecontent variable="stackTrace">
    <cfoutput>
    <xmp>
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
    </xmp>
   </cfoutput>
  </cfsavecontent>
  <cfreturn stackTrace  />
</cffunction>



<cffunction name="constructTagContextElements" output="false" access="public" returntype="string" hint="returns the error's tagcontext formatted as xml">
	<cfargument name="exception" type="any">
	<cfset var tc = exception.tagcontext>
	<cfset var i = 1>
	<cfset var xmlReturn = "">
	<cfset var sep = createObject("java","java.lang.System").getProperty("file.separator")>
	<cfset var mxunitpath = "mxunit#sep#framework">
	<cfoutput>
	<cfsavecontent variable="xmlReturn">
	<cfloop from="1" to="#ArrayLen(tc)#" index="i">
		<cfif tc[i].template neq "<generated>"
			AND not findNoCase("Assert.cfc",tc[i].template)
			AND tc[i].line GT 0>
			<trace>
				<file>#xmlFormat(tc[i].template)#</file>
				<line>#tc[i].line#</line>
			</trace>
		</cfif>
	</cfloop>
	</cfsavecontent>
	</cfoutput>
	<cfreturn xmlReturn>
</cffunction>



<cffunction name="getXslt" access="public" hint="Basic XSL for outputting html" returntype="string">
 <cfset var querystring = normalizeQueryString(URL,"jq")>
 <cfset var xsl= "">
 <cfset querystring = XMLFormat(queryString)>
<cfset  xsl =
 '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" indent="yes"/>


<!-- **********************************************************************
 Render header and footer
     ********************************************************************** -->
<xsl:template match="/">
 <html>
  <head>
  <title>Test Results [#dateformat(now() , "mm/dd/yy")# #timeFormat(now(),"medium")#] [#cgi.REMOTE_ADDR#]</title>
   <style>
      body  {
        font-family: verdana, arial, helvetica, sans-serif;
        background-color: ##FFFFFF;
        font-size: 12px;
        margin-top: 10px;
        margin-left: 10px;
      }

      table {
        font-size: 11px;
        font-family: Verdana, arial, helvetica, sans-serif;
        width: 90%;
      }

      th {
        padding: 6px;
        font-size: 12px;
        background-color: ##cccccc;
      }

      td {
        padding: 6px;
        background-color: ##eeeeee;
        vertical-align : top;
      }

      code {
        color: ##000099 ;
      }
	  ##modelink{font-size: 10pt; font-family: Verdana; position:absolute; padding: 10px;}
      </style>
      <script>
      <![CDATA[


      function swap(id){
       el = document.getElementById("h_" + id);
      //alert("h_" + id)
       if(el.style.visibility == "visible"){
        el.style.visibility = "hidden";
        el.style.display = "none";
        document.getElementById(id).innerHTML = "+ Expand Stacktrace";
       }
       else {
        el.style.visibility = "visible";
        el.style.display = "block";
        document.getElementById(id).innerHTML = "- Collapse Stacktrace";
       }

      }

       function swapContent(id){
       //alert(id);
       el = document.getElementById("g_" + id);
       if(el.style.visibility == "visible"){
        el.style.visibility = "hidden";
        el.style.display = "none";
        document.getElementById(id).innerHTML = "+ Expand";
       }
       else {
        el.style.visibility = "visible";
        el.style.display = "block";
        document.getElementById(id).innerHTML = "- Collapse";
       }

      }

      ]]>
      </script>
  </head>
  <body style="font-family: arial, helvetica, sans-serif;">
	<div id="modelink">
		(<a href="?#queryString#">view pretty html</a>)
	</div>
   <H2 align="center">Test Results</H2>
   <xsl:call-template name="summary" />
   <xsl:apply-templates />
  </body>
 </html>
</xsl:template>




<xsl:template match="/test_results">
<div align="center">
<table border="1">
  <tbody>
    <tr>
    <th>No.</th>
      <th>Date/Time</th>
      <th>Component.Method()</th>
      <th>Result</th>
      <th>Speed</th>
      <th>Details</th>
      <th>Trace</th>
      <th>Generated</th>
    </tr>
    <xsl:apply-templates select="test_case">
      <xsl:sort select="@component" />
 	  <xsl:sort select="@testname" />
 	</xsl:apply-templates>
  </tbody>
</table>
</div>
</xsl:template>

<xsl:template match="/test_results/test_case">


<!-- Alternating colors overridden by new style selectors (1/26/07) -->
<xsl:variable name="bgcolor">
  <xsl:choose>
   <xsl:when test="position() mod 2 = 0">F5F5F5</xsl:when>
   <xsl:otherwise>white</xsl:otherwise>
  </xsl:choose>
 </xsl:variable>
 <xsl:variable name="linkroot">#getContextRoot()#/<xsl:value-of select="translate(@component, ''.'', ''/'')"/>.cfc?method=runtestremote&amp;output=html</xsl:variable>

 <tr bgcolor="{$bgcolor}" valign="top">
  <xsl:variable name="rowid" select="@number" />
  <td><xsl:value-of select="@number" />.</td>
  <td><xsl:value-of select="date" /></td>
  <td align="left" nowrap="true">
      <a href="{$linkroot}" title="View TestCase results: {@component}"><xsl:value-of select="@component" /></a>.<a href="{$linkroot}&amp;testmethod={@testname}" title="View individual test result for: {@testname}()"><xsl:value-of select="@testname" /></a>()</td>
  <td>
  <xsl:variable name="failed" select="results/message" />
  <xsl:choose>
    <xsl:when test="$failed = ''Failed''">
     <strong style="color:blue"><xsl:value-of select="results/message" /></strong>
    </xsl:when>
	<xsl:when test="$failed = ''Error''">
     <strong style="color:darkred"><xsl:value-of select="results/message" /></strong>
    </xsl:when>
    <xsl:otherwise>
      <span style="color:green"><xsl:value-of select="results/message" /></span>
    </xsl:otherwise>
  </xsl:choose>
  </td>
  <td><xsl:value-of select="time" />  ms</td>
  <td><strong><xsl:value-of select="results/exception" /></strong><br />
      <xsl:if test="string-length(results/exception) &gt; 0">
	      <div id="{$rowid}" onclick="swap(this.id)" style="visibility:visible;cursor:default;color:darkred">+ Expand Stacktrace</div>
	      <div id="h_{$rowid}" style="visibility:none;display:none">
	      <xsl:value-of select="results/error" disable-output-escaping="yes" />
	      <xsl:if test="string-length(results/usermessage) &gt; 0">
	        <p>User Message: <xsl:value-of select="results/usermessage" /></p>
	      </xsl:if>
	      </div>
      </xsl:if>
      </td>
      <!-- add a space -->
  <td><xsl:value-of select="results/trace" />&##160;</td>
  <td>&##160;
       <xsl:if test="string-length(results/content) &gt; 0">
	      <div id="c{$rowid}" onclick="swapContent(this.id)" style="visibility:visible;cursor:default;color:green">+ Expand</div>
	      <div id="g_c{$rowid}" style="visibility:none;display:none">
	      <xsl:value-of select="results/content" disable-output-escaping="yes" />
	      </div>
      </xsl:if>



  </td>
</tr>
</xsl:template>

<xsl:template name="summary">
<div align="center">
 [<strong>Failures: </strong>
 <span  style="color:blue; font-weight:bold"><xsl:value-of select="count(/test_results/test_case/results[message=''Failed''])" />
 </span>]
 <span style="width:1em;"></span>
[<strong>Errors: </strong>
 <span  style="color:darkred; font-weight:bold"><xsl:value-of select="count(/test_results/test_case/results[message=''Error''])" />
 </span>]
 <span style="width:1em;"></span>
 [<strong>Successes: </strong>
 <span  style="color:green; font-weight:bold"><xsl:value-of select="count(/test_results/test_case/results[message=''Passed''])" />
 </span>]
 </div>
</xsl:template>

</xsl:stylesheet>' /><!--- End xsl assignment --->


 <cfreturn xsl />

 </cffunction>




 </cfcomponent>
