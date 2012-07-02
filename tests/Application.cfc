<cfcomponent output="false">
	<cfsetting requesttimeout="600" />

	<cfscript>
		this.name = "cfstatictests_" & hash(GetCurrenttemplatepath());

		root = GetDirectoryFromPath(GetCurrentTemplatePath());

		this.mappings['/mxunit']        = '#root#mxunit';
		this.mappings['/org/cfstatic']  = '#root#../org/cfstatic';
		this.mappings['/tests']         = Left(root, Len(root)-1); // remove trailing slash - breaks openBDs ExpandPath() method...
	</cfscript>

	<cffunction name="onApplicationStart" access="public" returntype="void" output="false">
		<cfscript>
			application.cfstatic = _initCfStatic();
		</cfscript>
	</cffunction>

	<cffunction name="_initCfStatic" access="private" returntype="any" output="false">
		<cfreturn CreateObject( "component", "org.cfstatic.CfStatic" ).init(
			  staticDirectory  = ExpandPath( "/tests/static" )
			, staticUrl        = "static"
			, jsDependencyFile = ExpandPath( "/tests/static/js/dependencies.readme" )
			, checkForUpdates  = true
		) />
	</cffunction>

	<cffunction name="onRequestStart" access="public" returntype="boolean" output="false">
		<cfscript>
			onApplicationStart();

			return true;
		</cfscript>
	</cffunction>
</cfcomponent>