<cfcomponent output="false">	
	<cfscript>
		this.name = "cfstatictests_" & hash(GetCurrenttemplatepath());
		
		this.mappings['/mxunit']        = ExpandPath('./mxunit');
		this.mappings['/mockbox']       = ExpandPath('./mockbox');
		this.mappings['/org/cfstatic']  = ExpandPath('../org/cfstatic');
		this.mappings['/tests']         = ExpandPath('./');
	</cfscript>
</cfcomponent>