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
			StructClear(request);
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
				, debugKey        = "doNotLetMxUnitDebugScrewTests"
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
				, debugKey        = "doNotLetMxUnitDebugScrewTests"
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
				, debugKey        = "doNotLetMxUnitDebugScrewTests"
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
				, debugKey        = "doNotLetMxUnitDebugScrewTests"
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
					, debugKey        = "doNotLetMxUnitDebugScrewTests"
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
					, debugKey        = "doNotLetMxUnitDebugScrewTests"
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
				, debugKey        = "doNotLetMxUnitDebugScrewTests"
			);

			minFolder      = rootDir & 'min';
			expectedFolder = rootDir & 'expectedOutput/withoutExternals';
			
			_assertFoldersAreEqual(expectedFolder, minFolder);
			
			_cleanUpMinifiedFiles();
			cfstatic.init(
				  staticDirectory   = rootDir
				, staticUrl         = "/any/old/thing"
				, minifyMode        = "all"
				, downloadExternals = true
				, debugKey        = "doNotLetMxUnitDebugScrewTests"
			);
			expectedFolder = rootDir & 'expectedOutput/withExternals';
			
			_assertFoldersAreEqual(expectedFolder, minFolder);
		</cfscript>
	</cffunction>

	<cffunction name="t08_cfstatic_shouldConcatenateAndMinifyFilesInFolders_whenInPackageMinifyMode" returntype="void">
		<cfscript>
			var minFolder = "";
			var expectedFolder = "";
			
			rootDir &= 'goodFiles/standardFolders/';


			cfstatic.init(
				  staticDirectory = rootDir
				, staticUrl       = "/any/old/thing"
				, minifyMode      = "package"
				, debugKey        = "doNotLetMxUnitDebugScrewTests"
			);

			minFolder      = rootDir & 'min';
			expectedFolder = rootDir & 'expectedOutput/packageMode';
			
			_assertFoldersAreEqual(expectedFolder, minFolder);
		</cfscript>	
	</cffunction>

	<cffunction name="t09_cfstatic_shoulThrowFriendlyErrorWhenBadLESSSyntax" returntype="void">
		<cfscript>
			var failed = false;

			rootDir &= 'badFiles/badLESS/';
			try {
				cfstatic.init(
					  staticDirectory = rootDir
					, staticUrl       = "/any/old/thing"
				);
							
			} catch ( "org.cfstatic.util.LessCompiler.badLESS" e ) {
				failed = true;
			}
			
			Assert(failed);
		</cfscript>	
	</cffunction>

	<cffunction name="t10_renderIncludes_shouldOutputAllIncludes_whenIncludeNeverCalledInAllMode" returntype="void">
		<cfscript>
			var renderedOutput = "";
			var expectedOutput = "";
			var outputHtmlRoot = rootDir & 'renderedIncludes/';

			rootDir &= 'goodFiles/simpleAllMode/';

			expectedOutput = _fileRead( outputHtmlRoot & 'all_includes_all_mode.html' );
			cfstatic.init(
				  staticDirectory = rootDir
				, staticUrl       = "/assets"
				, minifyMode      = "all"
				, debugKey        = "doNotLetMxUnitDebugScrewTests"
			);
			renderedOutput = cfstatic.renderIncludes();
			AssertEquals( _cleanupRenderedOutput(expectedOutput), _cleanupRenderedOutput( renderedOutput ) );
		</cfscript>
	</cffunction>

	<cffunction name="t11_renderIncludes_shouldOutputAllIncludes_whenIncludeNeverCalledInPackageMode" returntype="void">
		<cfscript>
			var renderedOutput = "";
			var expectedOutput = "";
			var outputHtmlRoot = rootDir & 'renderedIncludes/';

			rootDir &= 'goodFiles/standardFolders/';

			expectedOutput = _fileRead( outputHtmlRoot & 'all_includes_package_mode.html' );
			cfstatic.init(
				  staticDirectory = rootDir
				, staticUrl       = "/assets"
				, minifyMode      = "package"
				, debugKey        = "doNotLetMxUnitDebugScrewTests"
			);
			renderedOutput = cfstatic.renderIncludes();
			AssertEquals( _cleanupRenderedOutput(expectedOutput), _cleanupRenderedOutput( renderedOutput ) );
		</cfscript>
	</cffunction>
	
	<cffunction name="t12_renderIncludes_shouldOutputAllIncludes_whenIncludeNeverCalledInFileMode" returntype="void">
		<cfscript>
			var renderedOutput = "";
			var expectedOutput = "";
			var outputHtmlRoot = rootDir & 'renderedIncludes/';

			rootDir &= 'goodFiles/standardFolders/';

			expectedOutput = _fileRead( outputHtmlRoot & 'all_includes_file_mode.html' );
			cfstatic.init(
				  staticDirectory = rootDir
				, staticUrl       = "/assets"
				, minifyMode      = "file"
				, debugKey        = "doNotLetMxUnitDebugScrewTests"
			);
			renderedOutput = cfstatic.renderIncludes();
			AssertEquals( _cleanupRenderedOutput(expectedOutput), _cleanupRenderedOutput( renderedOutput ) );
		</cfscript>
	</cffunction>

	<cffunction name="t13_renderIncludes_shouldOutputAllIncludesFromOriginalLocations_whenIncludeNeverCalledInNoneMode" returntype="void">
		<cfscript>
			var renderedOutput = "";
			var expectedOutput = "";
			var outputHtmlRoot = rootDir & 'renderedIncludes/';

			rootDir &= 'goodFiles/standardFolders/';

			expectedOutput = _fileRead( outputHtmlRoot & 'all_includes_none_mode.html' );
			cfstatic.init(
				  staticDirectory = rootDir
				, staticUrl       = "/assets"
				, minifyMode      = "none"
				, debugKey        = "doNotLetMxUnitDebugScrewTests"
			);
			renderedOutput = cfstatic.renderIncludes();
			AssertEquals( _cleanupRenderedOutput(expectedOutput), _cleanupRenderedOutput( renderedOutput ) );			
		</cfscript>
	</cffunction>

	<cffunction name="t14_renderIncludes_shouldRenderNothing_whenIncludeAllByDefaultIsSetToFalse_allMode" returntype="void">
		<cfscript>
			rootDir &= 'goodFiles/simpleAllMode/';
			cfstatic.init(
				  staticDirectory     = rootDir
				, staticUrl           = "/assets"
				, minifyMode          = "file"
				, debugKey            = "doNotLetMxUnitDebugScrewTests"
				, includeAllByDefault = false
			);
			AssertEquals( "", cfstatic.renderIncludes() );
		</cfscript>	
	</cffunction>

	<cffunction name="t15_renderIncludes_shouldOnlyRenderIncludedFilesAndTheirDependencies" returntype="void">
		<cfscript>
			var renderedOutput = "";
			var expectedOutput = "";
			var outputHtmlRoot = rootDir & 'renderedIncludes/';

			rootDir &= 'goodFiles/standardFolders/';

			expectedOutput = _fileRead( outputHtmlRoot & 'selected_css_includes_file_mode.html' );
			cfstatic.init(
				  staticDirectory = rootDir
				, staticUrl       = "/assets"
				, minifyMode      = "file"
				, debugKey        = "doNotLetMxUnitDebugScrewTests"
			);
			cfstatic.include('/css/less/testing.less');

			renderedOutput = cfstatic.renderIncludes('css');
			AssertEquals( _cleanupRenderedOutput(expectedOutput), _cleanupRenderedOutput( renderedOutput ) );
		</cfscript>	
	</cffunction>

	<cffunction name="t16_renderIncludes_shouldRenderSourceFiles_whenDebugKeyAndPasswordFoundInUrl" returntype="void">
		<cfscript>
			var renderedOutput = "";
			var expectedOutput = "";
			var outputHtmlRoot = rootDir & 'renderedIncludes/';

			rootDir &= 'goodFiles/standardFolders/';

			expectedOutput = _fileRead( outputHtmlRoot & 'selected_raw_includes_package_mode.html' );
			cfstatic.init(
				  staticDirectory = rootDir
				, staticUrl       = "/assets"
				, minifyMode      = "package"
				, debugKey        = "doNotLetMxUnitDebugScrewTests"
				, debugPassword   = "thisIsATest"
			);
			url.doNotLetMxUnitDebugScrewTests = "thisIsATest";

			cfstatic.include('/css/someFolder/')
			        .include('/js/core/');

			renderedOutput = cfstatic.renderIncludes();
			structDelete(url, 'doNotLetMxUnitDebugScrewTests');

			AssertEquals( _cleanupRenderedOutput(expectedOutput), _cleanupRenderedOutput( renderedOutput ) );
		</cfscript>	
	</cffunction>

	<cffunction name="t17_renderIncludes_shouldOnlyRenderJs_whenOnlyJsRequested" returntype="void">
		<cfscript>
			var renderedOutput = "";
			var expectedOutput = "";
			var outputHtmlRoot = rootDir & 'renderedIncludes/';

			rootDir &= 'goodFiles/simpleAllMode/';

			expectedOutput = _fileRead( outputHtmlRoot & 'js_only_includes_all_mode.html' );
			cfstatic.init(
				  staticDirectory = rootDir
				, staticUrl       = "/assets"
				, minifyMode      = "all"
				, debugKey        = "doNotLetMxUnitDebugScrewTests"
			);

			cfstatic.include('/css/someFolder/')
			        .include('/js/core/');

			renderedOutput = cfstatic.renderIncludes('js');

			AssertEquals( _cleanupRenderedOutput(expectedOutput), _cleanupRenderedOutput( renderedOutput ) );
		</cfscript>	
	</cffunction>

	<cffunction name="t18_renderIncludes_shouldOnlyRenderCss_whenOnlyCssRequested" returntype="void">
		<cfscript>
			var renderedOutput = "";
			var expectedOutput = "";
			var outputHtmlRoot = rootDir & 'renderedIncludes/';

			rootDir &= 'goodFiles/simpleAllMode/';

			expectedOutput = _fileRead( outputHtmlRoot & 'css_only_includes_all_mode.html' );
			cfstatic.init(
				  staticDirectory = rootDir
				, staticUrl       = "/assets"
				, minifyMode      = "all"
				, debugKey        = "doNotLetMxUnitDebugScrewTests"
			);

			cfstatic.include('/css/someFolder/')
			        .include('/js/core/');

			renderedOutput = cfstatic.renderIncludes('css');

			AssertEquals( _cleanupRenderedOutput(expectedOutput), _cleanupRenderedOutput( renderedOutput ) );
		</cfscript>	
	</cffunction>

	<cffunction name="t19_renderIncludes_shouldRenderJsVariablesBeforeJsIncludes_whenIncludeDataUsed" returntype="void">
		<cfscript>
			var renderedOutput = "";
			var expectedOutput = "";
			var outputHtmlRoot = rootDir & 'renderedIncludes/';
			var dataToInclude  = StructNew();

			rootDir &= 'goodFiles/simpleAllMode/';

			expectedOutput = _fileRead( outputHtmlRoot & 'all_includes_plus_data_all_mode.html' );
			cfstatic.init(
				  staticDirectory = rootDir
				, staticUrl       = "/assets"
				, minifyMode      = "all"
				, debugKey        = "doNotLetMxUnitDebugScrewTests"
			);

			dataToInclude['someKey']          = ListToArray("1,2,3,4,7,8,9");
			dataToInclude.anotherKey          = StructNew();
			dataToInclude.anotherKey['fubar'] = "hello world";
			dataToInclude.yetAnotherKey       = false;

			cfstatic.includeData( dataToInclude )
			        .include('/css/someFolder/')
			        .include('/js/core/');

			renderedOutput = cfstatic.renderIncludes();

			AssertEqualsCase( _cleanupRenderedOutput(expectedOutput), _cleanupRenderedOutput( renderedOutput ) );
		</cfscript>
	</cffunction>

	<cffunction name="t20_renderIncludes_shouldUseConfiguredCharset" returntype="void">
		<cfscript>
			var renderedOutput = "";
			var expectedOutput = "";
			var outputHtmlRoot = rootDir & 'renderedIncludes/';
			var dataToInclude  = StructNew();

			rootDir &= 'goodFiles/standardFolders/';

			expectedOutput = _fileRead( outputHtmlRoot & 'all_includes_package_mode_utf16.html' );
			cfstatic.init(
				  staticDirectory = rootDir
				, staticUrl       = "/assets"
				, minifyMode      = "package"
				, debugKey        = "doNotLetMxUnitDebugScrewTests"
				, outputCharset   = "utf-16"
			);
			dataToInclude['someKey']          = ListToArray("1,2,3,4,7,8,9");
			dataToInclude.anotherKey          = StructNew();
			dataToInclude.anotherKey['fubar'] = "hello world";
			dataToInclude.yetAnotherKey       = false;

			renderedOutput = cfstatic.includeData( dataToInclude ).renderIncludes();
			AssertEqualsCase( _cleanupRenderedOutput(expectedOutput), _cleanupRenderedOutput( renderedOutput ) );
		</cfscript>	
	</cffunction>

	<cffunction name="t21_javaLoaders_shouldBeCachedInSessionScopeByDefault" returntype="void">
		<cfscript>
			if( StructKeyExists(server, '_cfstaticJavaloaders_v2') ){
				server['_theOldSwitcheroo'] = server['_cfstaticJavaloaders_v2'];
			}

			StructDelete(application, '_cfstaticJavaloaders_v2');
			StructDelete(server     , '_cfstaticJavaloaders_v2');

			cfstatic.init(
				  staticDirectory = rootDir
				, staticUrl       = "/assets"
			);
			AssertFalse( StructKeyExists( application, '_cfstaticJavaloaders_v2' ), "The javaloaders for CfStatic were loaded into the application scope, even when told to be put in the server scope" );
			Assert( StructKeyExists( server, '_cfstaticJavaloaders_v2' ), "The javaloaders for CfStatic were not loaded into the server scope, even when asked" );
			Assert( StructCount( server['_cfstaticJavaloaders_v2'] ), "The javaloaders for CfStatic were not loaded into the server scope" );
		
			
			if( StructKeyExists(server, '_theOldSwitcheroo') ){
				server['_cfstaticJavaloaders_v2'] = server['_theOldSwitcheroo'];
				StructDelete(server, '_theOldSwitcheroo');
			}
		</cfscript>
	</cffunction>

	<cffunction name="t22_settingJavaScopeToApplication_shouldCacheJavaLoadersInApplicationScope" returntype="void">
		<cfscript>
			if( StructKeyExists(server, '_cfstaticJavaloaders_v2') ){
				server['_theOldSwitcheroo'] = server['_cfstaticJavaloaders_v2'];
			}

			StructDelete(application, '_cfstaticJavaloaders_v2');
			StructDelete(server     , '_cfstaticJavaloaders_v2');

			cfstatic.init(
				  staticDirectory = rootDir
				, staticUrl       = "/assets"
				, javaLoaderScope = "application"
			);

			AssertFalse( StructKeyExists( server, '_cfstaticJavaloaders_v2' ), "The javaloaders for CfStatic were loaded into the server scope, even when told to be put in the application scope" );
			Assert( StructKeyExists( application, '_cfstaticJavaloaders_v2' ), "The javaloaders for CfStatic were not loaded into the application scope, even when asked" );
			Assert( StructCount( application['_cfstaticJavaloaders_v2'] ), "The javaloaders for CfStatic were not loaded into the application scope" );
		
			
			if( StructKeyExists(server, '_theOldSwitcheroo') ){
				server['_cfstaticJavaloaders_v2'] = server['_theOldSwitcheroo'];
				StructDelete(server, '_theOldSwitcheroo');
			}
		</cfscript>	
	</cffunction>

	<cffunction name="t23_settingLessGlobals_shouldHaveThemIncludedWithAllLessFiles" returntype="void">
		<cfscript>
			var minFolder = "";
			var expectedFolder = "";
			var globals = "";
			
			rootDir &= 'goodFiles/lessIncludesTest/';

			globals = ListAppend( globals, ExpandPath(rootDir & 'css/less/globals/global1.less') );
			globals = ListAppend( globals, ExpandPath(rootDir & 'css/less/globals/global2.less') );
			globals = ListAppend( globals, ExpandPath(rootDir & 'globals/more.less') );

			try {
				cfstatic.init(
					  staticDirectory = rootDir
					, staticUrl       = "/any/old/thing"
					, minifyMode      = "all"
					, lessGlobals     =  globals
					, debugKey        = "doNotLetMxUnitDebugScrewTests"
				);
			} catch( "org.cfstatic.util.LessCompiler.badLESS" e ) {
				fail( "CfStatic failed to include global LESS files" );
			}

			minFolder      = rootDir & 'min';
			expectedFolder = rootDir & 'expectedOutput';
			
			_assertFoldersAreEqual(expectedFolder, minFolder);
		</cfscript>	
	</cffunction>

	<cffunction name="t24_settingLessGlobals_shouldThrowError_whenOneOrMoreOfTheGlobalsDoesNotExist" returntype="void">
		<cfscript>
			var minFolder      = "";
			var expectedFolder = "";
			var failed         = false;
			
			rootDir &= 'goodFiles/lessIncludesTest/';

			try {
				cfstatic.init(
					  staticDirectory = rootDir
					, staticUrl       = "/any/old/thing"
					, minifyMode      = "all"
					, lessGlobals     = ExpandPath(rootDir & 'css/less/globals/global1.less') & ',/non/existing/less/file.less'
					, debugKey        = "doNotLetMxUnitDebugScrewTests"
				);
			} catch( "org.cfstatic.util.LessCompiler.missingGlobal" e ) {
				failed = ( e.message EQ "Could not find LESS global, '/non/existing/less/file.less'" );
			}

			Assert( failed, "CfStatic did not throw an appropriate error when an invalid LESS global was supplied");
		</cfscript>	
	</cffunction>

	<cffunction name="t25_coffeescript_shouldBeCompiledToJs" returntype="void">
		<cfscript>
			var jsFolder       = "";
			var expectedFolder = "";
			
			rootDir &= 'goodFiles/coffee-script/';

			cfstatic.init(
				  staticDirectory = rootDir
				, staticUrl       = "/any/old/thing"
				, minifyMode      = "none"
				, debugKey        = "doNotLetMxUnitDebugScrewTests"
			);

			jsFolder       = rootDir & 'js';
			expectedFolder = rootDir & 'expectedOutput';
			
			_assertFoldersAreEqual(expectedFolder, jsFolder);
		</cfscript>	
	</cffunction>

	<cffunction name="t26_coffeescript_shouldNotCompileWithAnonymousFunctionWrapper_whenFileNameIsLikeBareDotCoffee" returntype="void">
		<cfscript>
			var jsFolder       = "";
			var expectedFolder = "";
			
			rootDir &= 'goodFiles/coffee-script-with-bareness/';

			cfstatic.init(
				  staticDirectory = rootDir
				, staticUrl       = "/any/old/thing"
				, minifyMode      = "none"
				, debugKey        = "doNotLetMxUnitDebugScrewTests"
			);

			jsFolder       = rootDir & 'js';
			expectedFolder = rootDir & 'expectedOutput';
			
			_assertFoldersAreEqual(expectedFolder, jsFolder);
		</cfscript>	
	</cffunction>

<!--- private helpers --->
	<cffunction name="_getResourcePath" access="private" returntype="string" output="false">
		<cfreturn '/tests/integration/resources/' />
	</cffunction>

	<cffunction name="_cleanUpMinifiedFiles" access="private" returntype="void" output="false">
		<cfset var dir   = rootDir & 'min' />
		<cfset var files = "" />
		
		<!--- min files --->
		<cfif DirectoryExists(dir)>
			<cfdirectory action="list" directory="#dir#" name="files" />
			<cfloop query="files">
				<cfif ListFindNoCase('js,css', ListLast(name, '.'))>
			    	<cffile action="delete" file="#directory#/#name#" />
			    </cfif>
			</cfloop>
		</cfif>

		<!--- compiled less files --->
		<cfdirectory action="list" directory="#rootDir#" filter="*.less.css" recurse="true" name="files" />
		<cfloop query="files">
			<cfif type EQ "file">
				<cffile action="delete" file="#directory#/#name#" />
			</cfif>
		</cfloop>

		<!--- compiled coffee-script files--->
		<cfdirectory action="list" directory="#rootDir#/js" filter="*.coffee.js" recurse="true" name="files" />
		<cfloop query="files">
			<cfif type EQ "file">
				<cffile action="delete" file="#directory#/#name#" />
			</cfif>
		</cfloop>
	</cffunction>

	<cffunction name="_assertFoldersAreEqual" access="private" returntype="void" output="false">
		<cfargument name="folder1" type="string" required="true" hint=""/>
		<cfargument name="folder2" type="string" required="true" hint=""/>

		<cfset var files1 = "" />
		<cfset var files2 = "" />
		<cfset var file1 = "" />
		<cfset var file2 = "" />
		<cfset var subDir = "" />

		<cfif DirectoryExists( ExpandPath( arguments.folder1 ) )>
			<cfset arguments.folder1 = ExpandPath( arguments.folder1 ) />
		</cfif>
		<cfif DirectoryExists( ExpandPath( arguments.folder2 ) )>
			<cfset arguments.folder2 = ExpandPath( arguments.folder2 ) />
		</cfif>

		<cfdirectory action="list" directory="#arguments.folder1#" name="files1" recurse="true" />
		<cfdirectory action="list" directory="#arguments.folder2#" name="files2" recurse="true" />

		<cfloop query="files1">
			<cfif files1.type EQ 'file'>
				<cfset file1 = ListAppend(files1.directory, files1.name, '/') />
				<cfset file2 = _findEquivalentFileThatMayHaveDifferentTimestamp(files1.name, ValueList(files2.name)) />

				<cfset Assert( file2 NEQ "", "The two folders did not contain the same files. Folder 1: #ValueList(files1.name)#. Folder 2: #ValueList(files2.name)#") />
				<cfset subFolder = ReplaceNoCase( files1.directory, folder1, '' ) />
				<cfset file2 = ListAppend( arguments.folder2 & subFolder, file2 , '/' ) />

				<cfset AssertEquals( _fileCheckSum(file1), _fileCheckSum(file2), 'The checksums of the #files1.name# files were not equal') />
			</cfif>
		</cfloop>
	</cffunction>

	<cffunction name="_fileChecksum" access="private" returntype="string" output="false">
		<cfargument name="filePath" type="string" required="true" />
		
		<cfreturn Hash( _fileRead( arguments.filePath ) ) />
	</cffunction>

	<cffunction name="_fileRead" access="private" returntype="string" output="false">
		<cfargument name="filePath" type="string" required="true" />
		
		<cfset var content = "" />
		<cffile action="read" file="#arguments.filePath#" variable="content" />

		<cfreturn content />
	</cffunction>

	<cffunction name="_findEquivalentFileThatMayHaveDifferentTimestamp" access="private" returntype="string" output="false">
		<cfargument name="fileName"           type="string" required="true" />
		<cfargument name="equivalentFileList" type="any"    required="true" />

		<cfset var equivFile        = "" />
		<cfset var strippedFileName = _removeTimeStampFromFileNames(arguments.fileName) />
		<cfloop list="#arguments.equivalentFileList#" index="equivFile">
			<cfif _removeTimeStampFromFileNames(equivFile) EQ strippedFileName>
				<cfreturn equivFile />
			</cfif>
		</cfloop>

		<cfreturn "" />
	</cffunction>

	<cffunction name="_removeTimeStampFromFileNames" access="private" returntype="string" output="false">
		<cfargument name="fileName" type="string" required="true" />

		<cfreturn ReReplace( arguments.fileName, '\.[0-9]{14}', "", "all" ) />
	</cffunction>

	<cffunction name="_removeNewLines" access="private" returntype="string" output="false">
		<cfargument name="stringWithNewLines" type="string" required="true" />

		<cfreturn Replace( Replace( stringWithNewLines, Chr(10), '', 'all' ), Chr(13), '', 'all' ) />
	</cffunction>

	<cffunction name="_cleanupRenderedOutput" access="private" returntype="string" output="false">
		<cfargument name="renderedOutput" type="string" required="true" />

		<cfreturn _removeNewLines( _removeTimeStampFromFileNames( arguments.renderedOutput ) ) />
	</cffunction>
	
</cfcomponent>