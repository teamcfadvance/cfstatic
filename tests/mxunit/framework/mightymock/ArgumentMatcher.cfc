<cfcomponent output="false">
<cfscript>

  /*
  Requirement: Matches both the order or name of arguments. This is
  accomplished by understanding how the method being mocked is invoked
  by the component under tests; e.g.,

  script:
  function doSomething(foo,bar){
    obj.theMethod(foo,bar);
  }
  This is invoked using positional style and can be mocked like this:
  mock.theMethod( '{string}','{query}' ).returns(''); or
  mock.theMethod( foo='{string}', bar='{query}' ).returns(''); or
  It's more reliable to use named parameters as argumentcollection is
  an unordered map.

  CFML
  <cffunction name="doSomething">
	 <cfargument name="foo" />
	 <cfargument name="bar" />
	 <cfinvoke object="obj" method="theMethod"
	 					              foo="#foo#" bar="#bar#" />
	</cffunction>

   The above should be mocked using named parameter syntax to ensure
   argument matching:

   mock.theMethod( foo='{string}', bar='{query}' ).returns('');
*/

  function match(literal,pattern){
    var i = 0;
    var argType = '';
    var element = '';
    var key = '';
    var oArg = '';
    var flag = false;
    var oStringVal = '';
    var literalKeyString = structKeyArray(literal).toString();
    var patternKeyString = structKeyArray(pattern).toString();
    var patternArgValues = arguments.pattern.values().toArray();

   //maybe a wildcard
   if(pattern.size() == 1){
     flag = patternContainsWildCard( pattern,'{*}' );
     if(flag) return flag;
     flag = patternContainsWildCard( pattern,'{+}' );
     if(literal.size() && flag) return flag; //make sure there's at least one arg
   }

 //Validation ... extract method
   if( literal.size() != pattern.size() ){
     $throw('MismatchedArgumentNumberException',
            'Different number of parameters.',
            'Make sure the same number of paramters are passed in.');
   }
 //i fear this is downright wrong
 //literal.equals(pattern)
 if(literal.equals(pattern)){
  	 /*the above expression is failing sometimes. argh*/
  	  $throw('NamedArgumentConflictException',
          'Different parameter type definition.',
          'It appears that you defined a mock using named or ordered arguments, but attempted to invoke it otherwise. Please use either named or ordered argument, but not both.');
   }

   for(key in literal){
     element = literal[key];
     oArg = patternArgValues[++i];
     if(oArg == '{any}') continue; //allow for 'ANY' type
     argType = getArgumentType(element);
     if( argType != oArg ) {
       if(isObject(element)){
        oStringVal = 'cfc or java class';
       }
       else{
        oStringVal = element.toString();
       }
      $throw('MismatchedArgumentPatternException',
             'Was looking at "#key# = #oStringVal#" and trying to match it to type: #oArg.toString()#',
             'Make sure the component being mocked matches parameter patterns, e.g., struct={struct}');
     }
   }

    return true;
  }



/*
  there's probably a better way to look up the type ...
*/
  function getArgumentType(arg){
   if (isDate(arg)) return '{date}';
   if (isObject(arg)) return '{object}';
   if (isStruct(arg)) return '{struct}';
   if (isCustomFunction(arg)) return '{udf}';
   if (isNumeric(arg)) return '{numeric}';
   if (isArray(arg)) return '{array}';
   if (isQuery(arg)) return '{query}';
   if (isXML(arg)) return '{xml}';
   if (isBoolean(arg)) return '{boolean}';
   if (isBinary(arg)) return '{binary}';
   if (isImage(arg)) return '{image}';
   return '{string}';
   $throw('UnknownTypeException', 'Unknown type for #arg.toString()#'); //probably dead code here.
  }


  function patternContainsWildCard(pattern, wildcard){
    var results = structFindValue(pattern,wildcard);
    return arrayLen(results) > 0;
  }
	</cfscript>




<cffunction name="$throw">
	<cfargument name="type" required="false" default="mxunit.exception.AssertionFailedError">
	<cfargument name="message" required="false" default="failed behaviour">
	<cfargument name="detail" required="false" default="Details details ...">
  <cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#" />
</cffunction>

</cfcomponent>