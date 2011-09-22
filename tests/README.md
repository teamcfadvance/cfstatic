CfStatic Tests
--------------

These tests rely on MXUnit (<http://mxunit.org/>).

The Application.cfc is setup to map MXUnit to a directory above the tests/ directory, i.e.

	/org
		/cfstatic
		...
	/tests
		/integration
		Application.cfc
		...
	/mxunit
		...