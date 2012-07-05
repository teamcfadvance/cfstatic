( function( $ ){
	$('document').ready( function(){
		var uriRoot       = cfrequest.TESTROOT || ""
		  , currentTest   = 0
		  , $tests        = $(".test")
		  , $testCount    = $("#test-number")
		  , $passCount    = $("#pass-count")
		  , $failCount    = $("#fail-count")
		  , $errorCount   = $("#error-count");

		var getCurrentTest = function(){
			return $tests.length > currentTest && $( $tests.get( currentTest ) );
		}

		var runTest = function() {
			var $test         = getCurrentTest()
			  , testMethod    = ""
			  , url           = "";

			var processResult = function( result ) {
				var testStatus = result.length && ( result[0].TESTSTATUS || result[0].testStatus );

				$test.removeClass( ".test-running" );
				if ( testStatus ) {
					$test
						.addClass( testStatus )
						.find( ".test-result" )
							.html( testStatus );

					switch( testStatus ) {
						case "Passed" : $passCount.html( parseInt( $passCount.html() )+1 ); break;
						case "Failed" : $failCount.html( parseInt( $failCount.html() )+1 ); break;
						default : $errorCount.html( parseInt( $errorCount.html() )+1 ); break;
					}
				} else {
					$test
						.addClass( "processing-error" )
						.find( ".test-result" )
							.html( "Processing Error" );
				}

				currentTest++;
				runTest();
			};

			if ( $test ){
				testMethod = $test.find(".test-name").text();
				url        = uriRoot + testMethod;

				$test.addClass( ".test-running" );
				$testCount.html( currentTest+1 );

				$.ajax( {
					  cache    : false
					, dataType : "json"
					, success  : processResult
					, error    : processResult
					, url      : url
				} );
			}
		};

		runTest();
	} );
} )( jQuery );