<cfparam name="url.showdebugoutput" default="false">
<cfsetting showdebugoutput="#url.showdebugoutput#" />

<cfparam name="url.test" default="" />
<cfparam name="url.componentPath" default="" />

<cfset pathBase = '../' />
<cfset title = '#url.test# - Runner' />

<cfinclude template="#pathBase#resources/theme/header.cfm" />

<cfset testToRun = url.test />

<!--- Add the js for the runner --->
<cfset arrayAppend(scripts, 'runner.js') />

<cfoutput>
	<form id="runnerForm" action="index.cfm" method="get">
		<div class="grid_8">
			<div>
				<label for="test">
					TestCase, TestSuite, or Directory: <br />
					<input type="text" id="test" name="test" value="#testToRun#" size="60" />
				</label>
			</div>
		</div>

		<div class="grid_4">
			<div>
				<label for="componentPath">
					(<code>componentPath</code> if Directory):<br />
					<input type="text" id="componentPath" name="componentPath" value="#url.componentPath#" size="30" />
				</label>
			</div>
		</div>

		<div class="grid_12 align-center">
			<input type="submit" value="Run Tests" id="btnRun">
			<input type="reset" value="Clear" id="btnClear" />
		</div>

		<div class="clear"><!-- clear --></div>
	</form>
</cfoutput>

<cfif testToRun NEQ "">
	<cfinvoke component="HtmlRunner" method="run" test="#testToRun#" componentPath="#url.componentPath#" />
</cfif>

<cfinclude template="#pathBase#resources/theme/footer.cfm" />
