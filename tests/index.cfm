<cfscript>
	rf = createObject("component","mxunit.framework.RemoteFacade");
	tests = rf.getComponentMethods("tests.integration.org.cfstatic.CfStaticTest");
	ArraySort( tests, "text" );

	data = StructNew();
	data.testRoot = "integration/org/cfstatic/CfStaticTest.cfc?method=runtestremote&output=json&testmethod=";
	application.cfstatic.includeData( data );
</cfscript>

<cfsetting enablecfoutputonly="true" />
<cfcontent reset="true" /><cfoutput><!doctype html>
<html lang="en">
	<head>
		<meta charset="utf-8">
		<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
		<title>CfStatic: Test Suite Runner</title>
		<meta name="author" content="Dominic Watson">
		#application.cfstatic.renderIncludes( 'css' )#
	</head>
	<body>
		<div id="container">
			<h1>CfStatic: Test Suite Runner<br />===========================</h1>
			<p> Please report problems at <a href="https://github.com/DominicWatson/cfstatic/issues">GitHub</a>. Click on a test for more details.</p>
			<p> -----------------------------------------------------<br />
				Running test <span id="test-number">0</span> of #arrayLen(tests)#. Pass: <span id="pass-count">0</span>, Fail: <span id="fail-count">0</span>, Error: <span id="error-count">0</span> <br />
				-----------------------------------------------------
			</p>
			<table>
				<cfloop array="#tests#" index="test">
					<tr class="test">
						<td class="test-name"><a href="integration/org/cfstatic/CfStaticTest.cfc?method=runtestremote&amp;output=html&amp;testmethod=#test#">#test#</a></td>
						<td class="test-result">&nbsp;</td>
					</tr>
				</cfloop>
			</table>
		</div>

		#application.cfstatic.renderIncludes( 'js' )#
	</body>
</html></cfoutput>