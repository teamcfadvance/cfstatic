/**
 * Test Runner JS Enhancements
 */
;(function($){
	container = '';
	
	var visibleTestResults = (function () {
		var cookieName = 'mxunit';
		
		if (readCookie(cookieName) == null) {
			createCookie(cookieName, 'fep');
		}
		
		return {
			'isVisbile'  : function (type) { return readCookie(cookieName).search(type.charAt(0)) != -1; }                                      
			, 'show'     : function (type) { createCookie(cookieName, readCookie(cookieName) + type.charAt(0)); this.updateUI(type);}   
			, 'hide'     : function (type) { createCookie(cookieName, readCookie(cookieName).replace(type.charAt(0), '')); this.updateUI(type);}     
			, 'toggle'   : function (type) { this.isVisbile(type) ? this.hide(type) : this.show(type); } 
			, 'updateUI' : function (type) {  
				var v = this.isVisbile(type);
				$('tr.' + type, container).toggle(v); 
				$('.summary .' + type + ' a', container).toggleClass('active', v);      
				$('table.results>tbody:not(:has(>tr:visible))', container).parent().prev().andSelf().hide();
				$('table.results>tbody:has(>tr:visible)', container).parent().prev().andSelf().show();
			}
		}
	})();
	
	$(function(){
		container = $('.mxunitResults');
		 
		$('#bug').tipsy({fade:false,gravity:'e'});
		$('a[rel="tipsy"]').tipsy({fade:true,gravity:'s'});
		$('.menu_item').tipsy({fade:true,gravity:'n',delayIn:2400});
		$('#sparkcontainer').tipsy({fade:true,gravity:'s'});
		$('.mxunittestsparks').sparkline( 'html', {type: 'tristate', height:'22px', barWidth: 1.1, colorMap: {'1': "#50B516", '-1': "#0781FA", '-2': "#DB1414"} } );

		
		// Make the table into a grid
		$('table.results', container).tablesorter({
			headers: { 
				3: {
					sorter: 'digit' 
				}
			}
		});
		
		// Add the active toggle for the filters
		$('.summary a', container)
			.addClass('active')
			.click(function() {
				
				// Find what type of filter we are on
				type = $(this).parent().attr('className');
				
				// Toggle all the matching tests
				toggleTests(type);
				
				return false;
			});
		
		// Hide the tag contexts by default
		contexts = $('table.tagcontext').hide();
		
		// Add the ability to toggle individual contexts
		$('<p />')
			.append($('<a />', {
				click: function() {
					// Find context directly after the link
					nextContext = $(this).parent().next();
					
					nextContext.toggle();
					
					return false;
				},
				href: '#',
				text: 'Toggle Stack Trace'
			}))
			.insertBefore(contexts);
		
		// Create a toggle link for the error context
		toggleContext = $('<li />', {})
			.append($('<a />', {
					click: function() {
						contexts.toggle();
						
						return false;
					},
					href: '#',
					text: 'Toggle Stack Traces'
				}));
		
		// Append the toggle option
		toggleContext.appendTo($('.summary ul', container));     
		
        visibleTestResults.updateUI('passed');                                   
        visibleTestResults.updateUI('failed');                                   
        visibleTestResults.updateUI('error');                                   
    	
	});
	
	function toggleTests( type ) {
		debug('Toggling: ' + type); 
		visibleTestResults.toggle(type);
	} 
	
     
	// Cookie functions from http://www.quirksmode.org/js/cookies.html 
	function createCookie(name,value,days) {
		if (days) {
			var date = new Date();
			date.setTime(date.getTime()+(days*24*60*60*1000));
			var expires = "; expires="+date.toGMTString();
		}
		else var expires = "";
		document.cookie = name+"="+value+expires+"; path=/";
	}

	function readCookie(name) {
		var nameEQ = name + "=";
		var ca = document.cookie.split(';');
		for(var i=0;i < ca.length;i++) {
			var c = ca[i];
			while (c.charAt(0)==' ') c = c.substring(1,c.length);
			if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
		}
		return null;
	}
	
	function debug(s) {
		if (typeof window !== "undefined" && typeof window.console !== "undefined" && typeof window.console.debug !== "undefined") {
			window.console.log(s);
		} else {
			//alert(s);
		}
	}
	
	
	
	
	
})(jQuery);
