<cfcomponent extends="mxunit.framework.TestCase" output="false">

<!--- setup, teardown, etc --->
	<cffunction name="setup" access="public" returntype="void" output="false">
		<cfscript>
			super.setup();
			cfstatic = createObject('component', 'org.cfstatic.CfStatic');
			rootDir = _getResourcePath();
		</cfscript>	
	</cffunction>

	<cffunction name="teardown" access="public" returntype="void" output="false">
		<cfscript>
			_cleanUpMinifiedFiles();
			super.teardown();
			rootDir = "";
			cfstatic = "";
		</cfscript>
	</cffunction>

<!--- tests --->
	<cffunction name="t01_cfstatic_shouldThrowError_whenMixedMediaInPackage" returntype="void">
		<cfscript>
			var failed = false;
			rootDir &= 'badFiles/mixedMediaInPackage/';

			cfstatic.init(
				  staticDirectory = rootDir
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
			rootDir &= 'badFiles/mixedIeInPackage/';

			cfstatic.init(
				  staticDirectory = rootDir
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
			rootDir &= 'badFiles/mixedMediaInAll/';

			cfstatic.init(
				  staticDirectory = rootDir
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
			rootDir &= 'badFiles/mixedIeInAll/';
			cfstatic.init(
				  staticDirectory = rootDir
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

	<cffunction name="t05_cfstatic_shouldThrowError_whenCompilingBadJavaScript" returntype="void">
		<cfscript>
			var failed = false;
			rootDir &= 'badFiles/badJavaScript/';
			try {
				cfstatic.init(
					  staticDirectory = rootDir
					, staticUrl       = "/any/old/thing"
				);
							
			} catch ( "org.cfstatic.util.YuiCompressor.badJs" e ) {
				failed = true;

				AssertEquals("There was an error compressing your javascript: 'Error at line 10 (char 18): syntax error'. Please see the error detail for the problematic javascript source.", e.message);
			}			
			
			Assert(failed);
		</cfscript>	
	</cffunction>

	<cffunction name="t06_cfstatic_shouldThrowError_whenMissingDependencies" returntype="void">
		<cfscript>
			var failed = false;

			rootDir &= 'badFiles/missingDependencies/';
			
			try {
				cfstatic.init(
					  staticDirectory = rootDir
					, staticUrl       = "/any/old/thing"
				);
			} catch ( "org.cfstatic.missingDependency" e ) {
				failed = true;

				AssertEquals("CFStatic Error: Could not find local dependency.", e.message);
				Assert(find("The dependency, '/core/layout.less', could not be found or downloaded.", e.detail) EQ 1);
				Assert(find("/css/other/somePage.less.css", e.detail));
			}			
			
			Assert(failed);
		</cfscript>	
	</cffunction>

	<cffunction name="t07_cfstatic_shouldConcatenateAndMinifyAllFilesToOne_whenInAllMinifyMode" returntype="void">
		<cfscript>
			var minFolder = "";
			var expectedFolder = "";
			
			rootDir &= 'goodFiles/simpleAllMode/';


			cfstatic.init(
				  staticDirectory = rootDir
				, staticUrl       = "/any/old/thing"
				, minifyMode      = "all"
			);

			minFolder      = rootDir & 'min';
			expectedFolder = rootDir & 'expectedOutput/withoutExternals';
			
			Assert( _areFoldersEqual(expectedFolder, minFolder) );
			
			_cleanUpMinifiedFiles();
			cfstatic.init(
				  staticDirectory   = rootDir
				, staticUrl         = "/any/old/thing"
				, minifyMode        = "all"
				, downloadExternals = true
			);
			expectedFolder = rootDir & 'expectedOutput/withExternals';
			
			Assert( _areFoldersEqual(expectedFolder, minFolder) );
		</cfscript>
	</cffunction>

<!--- private --->
	<cffunction name="_getResourcePath" access="private" returntype="string" output="false">
		<cfreturn '/tests/integration/resources/' />
	</cffunction>

	<cffunction name="_cleanUpMinifiedFiles" access="private" returntype="void" output="false">
		<cfset var dir   = rootDir & 'min' />
		<cfset var files = "" />
		<cfif DirectoryExists(dir)>
			<cfdirectory action="list" directory="#dir#" name="files" />
			<cfloop query="files">
			     <cffile action="delete" file="#directory#\#name#" />
			</cfloop>
		</cfif>
	</cffunction>

	<cffunction name="_areFoldersEqual" access="private" returntype="boolean" output="false">
		<cfargument name="folder1" type="string" required="true" hint=""/>
		<cfargument name="folder2" type="string" required="true" hint=""/>

		<cfset var files = "" />
		<cfset var file1 = "" />
		<cfset var file2 = "" />


		<cfdirectory action="list" directory="#arguments.folder1#" name="files"/>
		<cfloop query="files">
			<cfset file1 = ListAppend(arguments.folder1, files.name, '/') />
			<cfset file2 = ListAppend(arguments.folder2, files.name, '/') />
			
			<cfif not FileExists( file2 ) or _fileCheckSum(file1) NEQ _fileCheckSum(file2)>
				<cfreturn false />
			</cfif>
		</cfloop>
		
		<cfreturn true />
	</cffunction>

	<cffunction name="_fileChecksum" access="private" returntype="string" output="false">
		<cfargument name="filePath" type="string" required="true" />
		
		<cfset var content = "" />
		<cffile action="read" file="#arguments.filePath#" variable="content" />

		<cfreturn Hash(content) />
	</cffunction>
	
</cfcomponent>