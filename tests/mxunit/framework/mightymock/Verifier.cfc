<cfcomponent output="false">
<cfscript>
 //change as needed
 exceptionType = 'mxunit.exception.AssertionFailedError';



function doVerify(verifyMethod, target, args, expected, mockreg){
  switch(verifyMethod){
    case 'verify':
      return verify(expected, target, args, mockreg);
    break;

	case 'verifyTimes':
      return verifyTimes(expected, target, args, mockreg);
    break;
    
    case 'verifyAtLeast':
      return verifyAtLeast(expected, target, args, mockreg);
    break;
    
    case 'verifyAtMost':
      return verifyAtMost(expected, target, args, mockreg);
    break;
    
    case 'verifyNever':
      return verifyNever(target, args, mockreg);
    break;
    
    case 'verifyOnce':
      return verifyOnce(target, args, mockreg);
    break;
    
    default:
     _$throw('InvalidVerificationException','Method #verifyMethod# was not found', 'Make sure the method exists.');
    break;
  }
}



 function verify(expected,target,args,mockreg){
   var actualCount = _$getActual(target,args, mockreg);
   var details = '';
   var isOk = actualCount == expected;
     
     if(!isOk){
       calls = mockreg.getInvocationRecordsById(target,args).recordCount;
       details = _$buildMessage('verify(#expected#)',target, args, expected, mockreg);
       _$throw(exceptionType,'Mock verification failed. ',details);
     }
     return isOk;
 }


function _$getActual(target,args,mockreg){
  var rows = mockreg.getInvocationRecordsById(target,args);
  return rows.recordCount;
}


 function verifyNever(target, args, mockreg){
     var actualCount = _$getActual(target,args, mockreg);
     var details = '';
     var isOk = actualCount == 0;
     
     if(!isOk){
       calls = mockreg.getInvocationRecordsById(target,args).recordCount;
       details = _$buildMessage('verifyNever()',target, args, 0, mockreg);
       _$throw(exceptionType,'Mock verification failed. ',details);
     }
     return isOk;
 }

  function verifyAtMost(expected, target, args, mockreg){
     var actualCount = _$getActual(target,args, mockreg);
     var details = '';
     var isOk = actualCount <= expected;
     
     if(!isOk){
       calls = mockreg.getInvocationRecordsById(target,args).recordCount;
       details = _$buildMessage('verifyAtMost(#expected#)',target, args, expected, mockreg);
       _$throw(exceptionType,'Mock verification failed. ',details);
     }
     return isOk;
 }

  function verifyAtLeast(expected, target, args, mockreg){
     var actualCount = _$getActual(target,args, mockreg);
     var details = '';
     var isOk = actualCount >= expected;
     
     if(!isOk){
       calls = mockreg.getInvocationRecordsById(target,args).recordCount;
       details = _$buildMessage('verifyAtLeast(#expected#)',target, args, expected, mockreg);
       _$throw(exceptionType,'Mock verification failed. ',details);
     }
     return isOk;
 }

 function verifyOnce(target, args, mockreg){
     var actualCount = _$getActual(target,args, mockreg);
     var details = '';
     var isOk = actualCount == 1;
     
     if(!isOk){
       calls = mockreg.getInvocationRecordsById(target,args).recordCount;
       details = _$buildMessage('verifyOnce()',target, args, 1, mockreg);
       _$throw(exceptionType,'Mock verification failed. ',details);
     }
     return isOk;
 }


 function verifyTimes(expected, target, args, mockreg){
     var actualCount = _$getActual(target,args, mockreg);
     var details = '';
     var isOk = actualCount == expected;
     
     if(!isOk){
       calls = mockreg.getInvocationRecordsById(target,args).recordCount;
       details = _$buildMessage('verifyTimes(#expected#)',target, args, expected, mockreg);
       _$throw(exceptionType,'Mock verification failed. ',details);
     }
     return isOk;
 }


 function _$buildMessage(rule, target, args, expected, mockreg){
  var calls = mockreg.getInvocationRecordsById(target,args).recordCount;
  var details = '';
  details &= 'Expected #target#( w/#args.size()# arguments ) to be verfied using rule "#rule#" ';
  details &=  ': , but #target#(...) was called #calls# time(s).';
  
  return details;
  
 }


</cfscript>


<cffunction name="_$throw">
	<cfargument name="type" required="false" default="mxunit.exception.AssertionFailedError">
	<cfargument name="message" required="false" default="failed behaviour">
	<cfargument name="detail" required="false" default="Details details ...">
  <cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#" />
</cffunction>
</cfcomponent>