/**
 * I am some javascript with an error. YuiCompressor will choke on this and CfStatic
 * should through a useful error
 * 
 * @depends http://ajax.googleapis.com/ajax/libs/jquery/1.6.4/jquery.min.js
 */

(function($){
	$('*[title]').each(function(){
		this.tooltip(),; // note the bad comma
	});
})(jQuery);