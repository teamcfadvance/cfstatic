component{
	this.name = 'CfStatic Travis CI Test suite';

	root = GetDirectoryFromPath( GetCurrentTemplatePath() );

	this.mappings['/mxunit'] = root & "../../../mxunit";
	this.mappings['/tests']  = root & "../";

	this.mappings['/org/cfstatic']  = root & "../../org/cfstatic";
	this.mappings['/tmp']           = GetTempDirectory();
}