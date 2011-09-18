<cfcomponent extends="tests.BaseTestCase" output="false">

<!--- setup, teardown, etc --->
	<cffunction name="setup" access="public" returntype="void" output="false">
		<cfscript>
			cfstatic = getTestTarget('org.cfstatic.CfStatic');
		</cfscript>	
	</cffunction>
	
	<cffunction name="teardown" access="public" returntype="void" output="false">
		cfstatic = "";
	</cffunction>

<!--- tests --->
	<cffunction name="t01_cfstatic_shouldThrowError_whenMixedMediaInPackage" returntype="void">
		<cfscript>
			var failed = false;
			
			cfstatic.init(
				  staticDirectory = _getResourcePath() & 'badFiles/mixedMediaInPackage/'
				, staticUrl       = "/any/old/thing"
				, minifyMode      = "package"
			);
						
			try {
				cfstatic.renderIncludes();
				
			} catch ( "cfstatic.Package.badConfig" e ) {
				failed = true;
			}			
			
			Assert(failed);
		</cfscript>	
	</cffunction>
	
	<cffunction name="t02_cfstatic_shouldThrowError_whenMixedIeConstraintInPackage" returntype="void">
		<cfscript>
			var failed = false;
			
			cfstatic.init(
				  staticDirectory = _getResourcePath() & 'badFiles/mixedIeInPackage/'
				, staticUrl       = "/any/old/thing"
				, minifyMode      = "package"
			);
			try {
				cfstatic.renderIncludes();
				
			} catch ( "cfstatic.Package.badConfig" e ) {
				failed = true;
			}			
			
			Assert(failed);
		</cfscript>	
	</cffunction>

	<cffunction name="t03_cfstatic_shouldThrowError_whenMixedMediaAndUsingMinifyAllMode" returntype="void">
		<cfscript>
			var failed = false;
			
			cfstatic.init(
				  staticDirectory = _getResourcePath() & 'badFiles/mixedMediaInAll/'
				, staticUrl       = "/any/old/thing"
				, minifyMode      = "all"
			);
			
			try {
				cfstatic.renderIncludes();
			} catch ( "cfstatic.PackageCollection.badConfig" e ) {
				failed = true;
			}				
			Assert(failed);
			
		</cfscript>	
	</cffunction>
	
	<cffunction name="t04_cfstatic_shouldThrowError_whenMixedIeConstraintAndUsingMinifyAllMode" returntype="void">
		<cfscript>
			var failed = false;
			
			cfstatic.init(
				  staticDirectory = _getResourcePath() & 'badFiles/mixedIeInAll/'
				, staticUrl       = "/any/old/thing"
				, minifyMode      = "all"
			);
			
			try {
				cfstatic.renderIncludes();
				
			} catch ( "cfstatic.PackageCollection.badConfig" e ) {
				failed = true;
			}			
			
			Assert(failed);
		</cfscript>	
	</cffunction>

<!--- private --->
	<cffunction name="_getResourcePath" access="private" returntype="string" output="false">
		<cfreturn '/tests/integration/resources/' />
	</cffunction>
</cfcomponent>