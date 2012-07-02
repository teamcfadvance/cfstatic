<cfparam name="title" default="Unit Test Framework and Eclipse Plugin for CFML engines" />
<cfparam name="pathBase" default="./" />

<cfset scripts = arrayNew(1) />
<cfset arrayAppend(scripts, pathBase & 'resources/jquery/jquery.min.js') />
<cfset arrayAppend(scripts, pathBase & 'resources/jquery/jquery-ui.min.js') />
<cfset arrayAppend(scripts, pathBase & 'resources/jquery/tablesorter/jquery.tablesorter.js') />
<cfset arrayAppend(scripts, pathBase & 'resources/jquery/tipsy/javascripts/jquery.tipsy.js') />
<cfset arrayAppend(scripts, pathBase & 'resources/jquery/jquery.runner.js') />
<cfset arrayAppend(scripts, pathBase & 'resources/jquery/jquery.sparkline.min.js') />

<cfset context = getDirectoryFromPath(expandPath(pathBase)) />

<!--- Find out the version of MXUnit --->
<cfset fileStream = createObject('java', 'java.io.FileInputStream') />
<cfset resourceBundle = createObject('java', 'java.util.PropertyResourceBundle') />
<cfset fileStream.init(context & 'buildprops/version.properties') />
<cfset resourceBundle.init(fileStream) />

<cfset version = resourceBundle.handleGetObject('build.major') & '.' />
<cfset version = version & resourceBundle.handleGetObject('build.minor') & '.' />
<cfset version = version & resourceBundle.handleGetObject('build.buildnum') />

<cfset fileStream.close() />

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
	<title><cfoutput>#title#</cfoutput> - MXUnit</title>
	
	<meta name="keywords" value="coldfusion unit testing test cfml cfmx xunit developer framework quality assurance open source community free" />
	
	
	<link rel="stylesheet" type="text/css" href="<cfoutput>#pathBase#</cfoutput>resources/theme/960.css">
	<link rel="stylesheet" type="text/css" href="<cfoutput>#pathBase#</cfoutput>resources/jquery/tablesorter/green/style.css">
	<link rel="stylesheet" type="text/css" href="<cfoutput>#pathBase#</cfoutput>resources/theme/styles.css">
	<link rel="stylesheet" type="text/css" href="<cfoutput>#pathBase#</cfoutput>resources/theme/results.css">
	<link rel="stylesheet" type="text/css" href="<cfoutput>#pathBase#</cfoutput>resources/jquery/tipsy/stylesheets/tipsy.css">

</head>
<body>
	<div class="container_12">
		<div class="pageHeader">
			<div class="grid_3">
				<a href="<cfoutput>#pathBase#</cfoutput>index.cfm">
					<img src="<cfoutput>#pathBase#</cfoutput>images/MXUnit-Small.png" alt="Get rid of those pesky bugs.">
				</a>
			</div>
			
			<div class="grid_9">
				<ul class="nav horizontal">
					<li><a class="menu_item" href="<cfoutput>#pathBase#</cfoutput>doc/" title="Local API Documentation">Local API</a></li>
					<li><a class="menu_item" href="http://wiki.mxunit.org/" title="Documentation, Tutorials, etc.">Docs</a></li>
					<li><a class="menu_item" href="<cfoutput>#pathBase#</cfoutput>samples/samples.cfm" title="Sample tests">Samples</a></li>
					<li><a class="menu_item" href="http://mxunit.org/blog" title="MXUnit Blog">Blog</a></li>
					<li><a class="menu_item" href="<cfoutput>#pathBase#</cfoutput>runner/index.cfm" title="Simple HTML Test Runner">Test Runner</a></li>
					<li><a class="menu_item" href="<cfoutput>#pathBase#</cfoutput>generator/index.cfm" title="Generate tests from existing code">Stub Generator</a></li>
					<li><a class="menu_item" href="http://groups.google.com/group/mxunit/topics" title="MXUnit Google Group">Help</a></li>
				</ul>
			</div>
			
			<div class="clear"><!-- clear --></div>
		</div>
		
		<div id="content">