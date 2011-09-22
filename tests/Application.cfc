<cfcomponent output="false">	
	<cfscript>
		this.name = "cfstatictests_" & hash(GetCurrenttemplatepath());
		
		root = GetDirectoryFromPath(GetCurrentTemplatePath());

		this.mappings['/mxunit']        = '#root#../mxunit';
		this.mappings['/mockbox']       = '#root#mockbox';
		this.mappings['/org/cfstatic']  = '#root#../org/cfstatic';
		this.mappings['/tests']         = root;
	</cfscript>
</cfcomponent>