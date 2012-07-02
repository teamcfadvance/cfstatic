;(function($) {
	examples = {
		TestCase: {
			test: 'mxunit.tests.framework.AssertTest',
			componentPath: ''
		},
		TestSuite: {
			test: 'mxunit.tests.framework.fixture.ATestSuite',
			componentPath: ''
		},
		Directory: {
			test: '/mxunit/tests/samples',
			componentPath: 'mxunit.tests.samples'
		}
	};
	
	$test = $('#test');
	$componentPath = $('#componentPath');
	
	$examples = $('<p>Examples: <a href="#">TestCase</a> <a href="#">TestSuite</a> <a href="#">Directory</a></p>');
	
	$('a', $examples).click(function() {
		option = examples[$(this).html()];
		
		$test.val(option.test);
		$componentPath.val(option.componentPath);
		
		return false;
	});
	
	$('#btnRun').before( $examples );
	
	$('#btnClear').click( function(){
		$('.mxunitResults').html('');
	} );
})(jQuery);
