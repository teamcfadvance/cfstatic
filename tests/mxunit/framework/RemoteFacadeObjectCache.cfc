<cfcomponent hint="Mechanism for managing a cache of objects. This is nice to have since the remote facade runs its tests method-at-a-time. Without a cache, you'd incur all the overhead of constructing the Test object(s) multiple times, which is not ideal.">

	<cfset storageScope = "server">
	<cfset initializeSuitePool()>

	<cffunction name="initializeSuitePool" access="public" returntype="struct">
		<cfreturn structGet("#storageScope#.MXUnitRemoteTestSuites")>
	</cffunction>

	<cffunction name="getSuitePool" access="public" hint="returns the pool struct" returntype="struct">
		<!--- THIS IS TEMPORARY!!! keeping this here until the structget bug is fixed in railo; then, revert to:

		<cfreturn initializeSuitePool()>

		 --->
		<cfreturn server.MXUnitRemoteTestSuites>
	</cffunction>

	<cffunction name="getSuitePoolCount" access="public" returntype="numeric" hint="returns the number of TestRun items in the pool">
		<cfreturn StructCount(getSuitePool())>
	</cffunction>

	<cffunction name="PurgeSuitePool" access="public" returntype="numeric">
		<cfset StructClear(getSuitePool())>
		<cfreturn getSuitePoolCount()>
	</cffunction>

	<cffunction name="startTestRun" access="public" returntype="string">
		<cfset var TestRunKey = createUUID()>
		<cfset initializeTestRunCache(TestRunKey)>
		<cflog file="mxunit" text="Initializing cache with key #TestRunKey#">
		<cfreturn TestRunKey>
	</cffunction>

	<cffunction name="initializeTestRunCache" access="private">
		<cfargument name="TestRunKey" type="string" required="true" hint="the key returned from startTestRun; used for managing the pool of components">

		<cfset var thisRun = StructNew()>
		<cfset thisRun.Components = StructNew()>
		<cfset thisRun.StartTime = now()>
		<cfset thisRun.LastAccessed = now()>
		<cfset StructInsert(getSuitePool(),TestRunKey,thisRun)>

		<cflog file="mxunit" text="Initialized TestRun with key #TestRunKey#">
	</cffunction>

	<cffunction name="getObject" access="public" returntype="any">
		<cfargument name="componentName" type="String" required="true">
		<cfargument name="TestRunKey" type="string" required="true" hint="the key returned from startTestRun; used for managing the pool of components">
		<cfset var obj = "">
		<cfset var pool = getSuitePool()>
		<cfif len(TestRunKey)>
			<!--- could only ever happen if a purgeStaleTests() hit from a separate eclipse process while another TestRun was very long running. See explanation in the purgeStaleTests method --->
			<cfif NOT StructKeyExists(pool,TestRunKey)>
				<cfset initializeTestRunCache(TestRunKey)>
			</cfif>

			<cfif NOT StructKeyExists(pool[TestRunKey].Components,componentName)>
				<cfset pool[TestRunKey].Components[componentName] = createObject("component", componentName).TestCase()>
				<!---  <cflog file="mxunit" text="key is #TestRunKey#; component is #componentName#">  --->
			</cfif>
			<cfset obj = pool[TestRunKey].Components[componentName]>
			<cfset pool[TestRunKey].LastAccessed = now()>
		<cfelse>
			<cfset obj = createObject("component", componentName).init()>
		</cfif>
		<cfreturn obj>
	</cffunction>

	<cffunction name="endTestRun" access="public" returntype="string" hint="ensures proper cleanup">
		<cfargument name="TestRunKey" type="string" required="true" hint="the key returned from startTestRun; used for managing the pool of components">
		<cfset var initialCount = getSuitePoolCount()>
		<cfset StructDelete(getSuitePool(),TestRunKey)>
		<cflog file="mxunit" text="RemoteSuiteCount: initial #initialCount#; now: #getSuitePoolCount()#">
		<cfset purgeStaleTests()>

		<cfreturn "">
	</cffunction>

	<cffunction name="purgeStaleTests" access="public" returntype="numeric" hint="cleans up long-running tests. This is simply overwrought prudence to ensure that very anomalous behavior doesn't result in a build-up of cruft in the server scope. The remote facade is designed to run start, execute, and cleanup independently of one another precisely to prevent catastrophic test errors from leaving a dirty cache. But one never knows what might happen">
		<cfargument name="NumMinutes" type="numeric" required="false" default="10" hint="Number of minutes a TestRun (which comprises multiple objects potentially) can remain in the cache after its LastAccessed value">
		<!--- now let's think about this: in order for a TestRun to go unaccessed for this long, a single test method would have to take this long, and
		some other mxunit plugin process would need to be running from within eclipse and execute tests on the same server. This would happen in an
		environment where a shared server is used and multiple people are running tests from within eclipse against that server (like a dev server). In this
		unlikely event where you have a test that runs this long, the effect of removing an object from the cache is that, on the next method run for
		the same test key, the cache for that key would simply be recreated --->
		<cfset var TestRun = "">
		<cfset var compareTime = now()>
		<cfset var lastAccessed = "">
		<cfset var purged = 0>
		<cfset var pool = getSuitePool()>
		<cfloop collection="#pool#" item="TestRun">
			<cfset lastAccessed = pool[TestRun].LastAccessed>
			<cfif DateDiff("n",lastAccessed,compareTime) GT NumMinutes>
				<cfset StructDelete(pool,TestRun)>
				<cfset purged = purged + 1>
				<cflog file="mxunit" text="Removing TestSuite with key #TestRun# from object cache. Last Accessed at #lastAccessed#">
			</cfif>
		</cfloop>
		<cfreturn purged>
	</cffunction>


</cfcomponent>