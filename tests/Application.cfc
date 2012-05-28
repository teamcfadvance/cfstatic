<cfcomponent output="false">
	<cfscript>
		this.name = "cfstatictests_" & hash(GetCurrenttemplatepath());

		root = GetDirectoryFromPath(GetCurrentTemplatePath());

		this.mappings['/mxunit']        = '#root#../mxunit';
		this.mappings['/org/cfstatic']  = '#root#../org/cfstatic';
		this.mappings['/tests']         = Left(root, Len(root)-1); // remove trailing slash - breaks openBDs ExpandPath() method...
	</cfscript>
</cfcomponent>