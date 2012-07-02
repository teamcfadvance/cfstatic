<cfcomponent output="false">
<cfscript>
 this.mocks = [];
 invocations = chr(0);
 expectations = [];//(1);
 index = 1;
 mr = createObject('component','MockRegistry');
 exceptionType = 'mxunit.exception.AssertionFailedError';


 function onMissingMethod(target,args){
    var id = mr.id(target,args);
    var expectation = {};
    expectation['id'] = id;
    expectation['name'] = target;
    expectation['args'] = args;
    expectations[index] = expectation;
    index++; //Note: expectations[index++] fails in Railo
    return this;
 }

 function getOrderedList(){
  return orderedList;
 }

 function verify(){
   var expectations = getExpectations();
   var invocations  = getInvocations();
   var orderedList  = valueList( invocations.method );
   var currentExpectation = '';
   var currentExpectationTime = '';
   var nextExpectation = '';
   var nextExpectationTime = '';
   var numberOfExpectations = expectations.size();
   var i=1;

   for(i=1; i <= numberOfExpectations; i++){
	        currentExpectation = expectations[i];
	        //debug(currentExpectation);
	        if(!exists(currentExpectation['id'])){
	          _$throw(exceptionType,'#currentExpectation["name"]#() not found in invocation list.',
	                                'To Do: Print list of methods' );
	        }

	       if(i < numberOfExpectations) {
	          nextExpectation = expectations [i+1];
	          if(!exists(nextExpectation['id'])){
	           _$throw(exceptionType,'#nextExpectation["name"]#() not found in invocation list.',
	                                 'To Do: Print list of methods' );
	          }

           currentExpectationTime = getInvocationTime(currentExpectation['id']);
	         nextExpectationTime = getInvocationTime(nextExpectation['id']);

	         if(currentExpectationTime > nextExpectationTime ) {
	           _$throw(exceptionType, 'Expectation Failure : #currentExpectation["name"]#() invoked AFTER #nextExpectation["name"]#().',
	                                  'Actual invocation sequence was "#printPrettyOrderedList(orderedList)#", but expectations were defined as #prettyPrintExpectations()#' );
	         }

	        }
	     }//end for

	  return this;
	 }

  function init(){
		for(item in arguments){
	    this.mocks[item] =   arguments[item];
	   }
	  invocations = merge();
    return this;
  }

  function getInvocations(){
    return invocations;
  }

  function getExpectations(){
   return expectations;
  }

  function merge(){
    var i = 1;
    var s = '';
    for(i; i <= this.mocks.size(); i++){
      t1 = 'q_#i#';
      t2 = 'q2_#i#';
      'q_#i#' = this.mocks[i]._$getRegistry().invocationRecord;
      'q2_#i#' = this.mocks[i]._$getRegistry().getRegistry();
       s &= 'select * from q_#i#, q2_#i#' & chr(10);
       s &= 'where q_#i#.id = q2_#i#.id ' & chr(10);
      if(i != this.mocks.size()) s &= ' union ' & chr(10);
    }
    s &= 'order by [time] asc' & chr(0);
    invocations = _$query(s);
    return invocations;
  }


 function printPrettyOrderedList(list){
  var s = '';
  var i = 1;
  for(i; i <= listLen(list); i++){
     s &= listGetAt(list,i) & '()';
     if(i < listLen(list) ) s &= ',';
  }
  return s;
 }

 function prettyPrintExpectations(){
  var item = '';
  var s = '';
  var expect = {};
  var i = 1;
  for(i; i <= expectations.size(); i++){
   expect = expectations[i];
   s &= expect['name'] & '()';
   if(i < expectations.size() ) s &= ',';
  }
  return s;
 }

</cfscript>

<cffunction name="exists" returntype="boolean">
  <cfargument name="id" type="string" />
  <cfset var q = ''>
  <cfquery name="q" dbtype="query" maxrows="1">
    select count(*) as cnt
    from invocations where id = '#id#'
  </cfquery>
  <cfreturn q.cnt eq 1 >
</cffunction>

<cffunction name="_$query" access="private">
  <cfargument name="qs" type="string" />
  <cfset var q = ''>
  <cfquery name="q" dbtype="query">
     #qs#
  </cfquery>
  <cfreturn q>
</cffunction>

<cffunction name="getInvocationTime" >
  <cfargument name="id" type="string">
  <cfset var q = ''>
  <cfquery name="q" dbtype="query" maxrows="1">
    select [time] from invocations where id = '#id#'
  </cfquery>
  <cfreturn q['time'] />
</cffunction>

<cffunction name="_$throw">
	<cfargument name="type" required="false" default="mxunit.exception.AssertionFailedError">
	<cfargument name="message" required="false" default="failed behaviour">
	<cfargument name="detail" required="false" default="Details details ...">
  <cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#" />
</cffunction>

</cfcomponent>