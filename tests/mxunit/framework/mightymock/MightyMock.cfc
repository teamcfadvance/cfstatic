<cfcomponent output="false">
	<cfscript>

/*------------------------------------------------------------------------------
      Public API. Any method NOT prefixed with _$ are considered public.
      All other methods are readily available, but will likely produce
      unexpected behavior if not used correctly.
------------------------------------------------------------------------------*/


/*------------------------------------------------------------------------------
                    Creational Methods - init() ... create()
------------------------------------------------------------------------------*/
 function init(){
   var proxyVars = '';
   /*
    Make "fast mock" and bypass scope acrobatics.
   */
   if( arguments.size() eq 0 ) {
     mocked.name = 'Undefined MightyMock Object';
     return this;
   };

   if( arguments.size() eq 1){
	 if (isObject(arguments[1])) {
		return createTypeSafeMock(arguments[1]);
	 } else {
	    mocked.name = arguments[1];
	    return this;
	 }
   }

   /*
     Make a type safe mock.
   */
   if( arguments.size() eq 2 ) {
	    return createTypeSafeMock(arguments[1]);
  }
 }


 //Clears all methods in object to be mocked.
 function createTypeSafeMock(mockee){
     var proxy = 0;
	try{
	 if (not IsObject(mockee)) {
	 	proxy = createObject('component', mockee);
     	mocked.name = mockee;
	 } else {
	 	proxy = mockee;
      	mocked.name = getMetaData(mockee).name;
	 }

     proxy.snif = _$snif; //sniffer for variables scope
     proxyVars = proxy.snif();

     structClear(proxyVars);
     structClear(proxy);
     proxy.variables = proxyVars;


	/* Need to write to THIS and VARIABLES scope because some weird scoping
	   issue when invoking a variable-scoped method from within another
	   method, CF sees this as undefined.
	   Ex: this works normally:
	   function foo(){
	    return bar();
	   }

	   But if copying both foo and bar to another component:
	   newCfc.foo = foo;
	   newCfc.bar = bar;

	   calling foo() fails with undefined bar exception. However, if we
	   do this:
	   newCfc.foo = foo;
	   newCfc.variables.foo = foo;
	   newCfc.bar = bar;
	   newCfc.variables.bar = bar;
	   All is well ...


*/

     		proxy.RETURNS = RETURNS ;
			proxy._$SETSTATE = _$SETSTATE;
			proxy.variables._$SETSTATE = _$SETSTATE;
			proxy.DEBUGMOCK =  DEBUGMOCK;
			proxy.variables.DEBUGMOCK =  DEBUGMOCK;
			proxy._$GETPREVIOUSSTATE  =  _$GETPREVIOUSSTATE;
			proxy.variables._$GETPREVIOUSSTATE  =  _$GETPREVIOUSSTATE;
			proxy.MOCK = MOCK;
			proxy.variables.MOCK = MOCK;
			proxy.VERIFYATLEAST=VERIFYATLEAST;
			proxy.variables.VERIFYATLEAST=VERIFYATLEAST;
			proxy.THROWS = THROWS ;
			proxy.variables.THROWS = THROWS ;
			proxy._$INVOKEMOCK = _$INVOKEMOCK;
			proxy.variables._$INVOKEMOCK = _$INVOKEMOCK;
			proxy.VERIFYONCE = VERIFYONCE;
			proxy.variables.VERIFYONCE = VERIFYONCE;
			proxy.variables.CURRENTMETHOD=CURRENTMETHOD;
			proxy._$THROW = _$THROW;
			proxy.variables._$THROW = _$THROW;
			proxy.variables.STATES = STATES;
			proxy.variables.PREVIOUSSTATE = PREVIOUSSTATE;
			proxy.VERIFYNEVER = VERIFYNEVER;
			proxy.variables.VERIFYNEVER = VERIFYNEVER;
			proxy.variables.TEMPRULE =TEMPRULE;
			proxy.variables.CURRENTSTATE = variables.CURRENTSTATE;
			proxy._$DEBUGREG = _$DEBUGREG ;
			proxy.variables._$DEBUGREG = _$DEBUGREG;
			proxy.variables.REGISTRY = REGISTRY;
			proxy._$GETSTATE =_$GETSTATE;
			proxy.RESET = RESET;
			proxy.variables.RESET = RESET;
			proxy.ONMISSINGMETHOD  = ONMISSINGMETHOD;
			proxy.VERIFYATMOST=VERIFYATMOST;
			proxy.variables.VERIFYATMOST=VERIFYATMOST;
			proxy.variables.MATCHER = MATCHER;
			proxy.variables.SPY= SPY;
			proxy.variables.VERIFIER = VERIFIER;
			proxy.REGISTER = REGISTER;
			proxy.variables.REGISTER = REGISTER;
			proxy._$DEBUGINVOKE = _$DEBUGINVOKE;
			proxy._$DUMP = _$DUMP;
			proxy.VERIFY = VERIFY;
			proxy.variables.VERIFY = VERIFY;
			proxy.VERIFYTIMES = VERIFYTIMES;
			proxy.variables.VERIFYTIMES = VERIFYTIMES;
			proxy._$GETREGISTRY = _$GETREGISTRY;
			proxy.variables._$GETREGISTRY = _$GETREGISTRY;
			proxy.GETMOCKED = GETMOCKED;
			proxy.variables.GETMOCKED = GETMOCKED;
			proxy.MOCKED = MOCKED;
			proxy.variables.MOCKED = MOCKED;
			proxy._$DUMP = _$DUMP;
			proxy.variables._$DUMP = _$DUMP;
			proxy.when = when;
			proxy.variables.when = when;

     return proxy;
	 }
	 catch (coldfusion.runtime.CfJspPage$NoSuchTemplateException e){
	     _$throw('InvalidMockException',e.getMessage(),e.getDetail());
	 }

 }


/*--------------------------------------------------------------------
             * * * * Behavioral Methods * * * *

       				Main entry points.

--------------------------------------------------------------------*/

 function onMissingMethod(missingMethodName,missingMethodArguments){
   var tempMock = chr(0);
   var temp = '';

   missingMethodArguments = createObject('java','java.util.TreeMap').init(missingMethodArguments);

   if( currentState == 'verifying'){
      verifier.doVerify(tempRule[1], missingMethodName, missingMethodArguments, tempRule[2], registry );
      _$setState('idle');
      return this;
   }

   else if(!registry.exists(missingMethodName,missingMethodArguments)) {

     if (!registry.isPattern(missingMethodArguments)){ //pee-yew!
      try{
       //To Do: record the literal and invoke pattern behavior
       //Record both if they exist. This will help for lookups
       tempMock = registry.findByPattern(missingMethodName,missingMethodArguments);
       return _$invokeMock(tempMock['missingMethodName'],tempMock['missingMethodArguments']);
      }
      catch(MismatchedArgumentPatternException e){
       // If we get here, it's because we're registering the method
       // the first time
       //_$rethrow(e);
      }
     }

   //Now we try to register the mock.
     _$setState('registering');
     registry.register(missingMethodName,missingMethodArguments); //could return id
     currentMethod['name'] = missingMethodName;
     currentMethod['missingMethodArguments'] = missingMethodArguments;
     // what logic can we implement to simply return '' if not mocked? _AND_
     // implement chaining?
     return this;
   }

   else{
    _$setState('executing');
    currentMethod = {};
    try{
     retval = _$invokeMock(missingMethodName,missingMethodArguments);
    }
    catch(UnmockedBehaviorException e){
      retval = chr(0);
    }

    return retval;
   }

   return chr(0);
 }

//--------------------------------------------------------------------------------------//





/*--------------------------------------------------------------------


--------------------------------------------------------------------*/
  function when(){
    _$setState('registering');
    return this;
  }


  function returns(){
   var arg = '';
   _$setState('idle');
   if( arguments.size() ) arg = arguments[1];
   registry.updateRegistry(currentMethod['name'],currentMethod['missingMethodArguments'],'returns',arg);
   return this;
  }

  function throws(type){
   registry.updateRegistry(currentMethod['name'],currentMethod['missingMethodArguments'],'throws',type);
   return this;
  }




/*-------------------------------------------------------------------------------------
                            Method  Verifications
-------------------------------------------------------------------------------------*/

  function verify(){
    var count = 1;
    _$setState('verifying');
    tempRule[1] = 'verify';
    if(arguments.size()) count = arguments[1];
    tempRule[2] = count;
    return this;
  }

  //Could put all this into onMissingMethod?
  function verifyTimes(count){
    _$setState('verifying');
    tempRule[1] = 'verifyTimes';
    tempRule[2] = arguments.count;
    return this;
  }
  function verifyAtLeast(count){
    _$setState('verifying');
    tempRule[1] = 'verifyAtLeast';
    tempRule[2] = arguments.count;
    return this;
  }
  function verifyAtMost(count){
     _$setState('verifying');
    tempRule[1] = 'verifyAtMost';
    tempRule[2] = arguments.count;
    return this;
  }
  function verifyOnce(){
    _$setState('verifying');
    tempRule[1] = 'verifyOnce';
    tempRule[2] = 1;
    return this;
  }
  function verifyNever(){
     _$setState('verifying');
    tempRule[1] = 'verifyNever';
    tempRule[2] = 0;
    return this;
  }


/*------------------------------------------------------------------------------
                                Utils
------------------------------------------------------------------------------*/

 function debugMock(){
   var verbose = true;
   if(arguments.size()) verbose = arguments[1];
    return createObject('component', 'MockDebug').debug(this,verbose);
  }


  function reset(){
    registry.reset();
	  _$setState('idle');
    currentMethod = {};
    //getMetaData(this).name = 'MightyMock';
    //getMetaData(this).fullname = 'MightyMock';
    return this;
  }

  function register(){
   _$setState('registering');
   return this;
  }

  function mock(){
   _$setState('registering');
   return this;
  }


/*------------------------------------------------------------------------------
                                Private API.
------------------------------------------------------------------------------*/


//sniffer hook into another object's variables scope
 function _$snif(){
  return variables;
 }

  function _$invokeMock(target,args){
    var behavior = registry.getRegisteredBehavior(target,args);

    if(behavior == 'returns') return registry.getReturnsData(target,args);
    if(behavior == 'throws')  _$throw(registry.getReturnsData(target,args));

  }

  function _$debugReg(){
    return registry.getRegistry();
  }

  function _$debugInvoke(){
    return registry.invocationRecord;
  }

  function _$getRegistry(){
   return registry;
  }

  function _$setState(state){
  	previousState = currentState;
    currentState = state;
  }

  function _$getState(){
   return currentState;
  }

  function _$getPreviousState(){
   return previousState;
  }


  function _$getSpy(){
   return spy;
  }


 function getMocked() {
  return mocked; //returns
 }

/*------------------------------------------------------------------------------
                          Private Instance Members
------------------------------------------------------------------------------*/
variables.registry = createObject('component','MockRegistry');
matcher = createObject('component','ArgumentMatcher');
verifier = createObject('component','Verifier');

mocked = {};      //meta data about the object being mocked
spy = chr(0);     //reference to the real object being mocked

tempRule = [];    //tech debt for verfier


states = [
 'idle',          // mock is waiting to be invoked
 'registering',   // mock is registering methods
 'executing',     // mock is executing a mocked method
 'verifying',      // mock is verifying behavior
 'error'          // problem
];

currentState = states[1];
previousState = '';

currentMethod = {};

</cfscript>



<cffunction name="_$dump">
  <cfset var i = 0 />
  <cfloop from="1" to="#arrayLen(arguments)#" index="i">
   <cfdump var="#arguments[i]#">
  </cfloop>
</cffunction>

<cffunction name="_$throw">
	<cfargument name="type" required="false" default="mxunit.exception.AssertionFailedError">
	<cfargument name="message" required="false" default="Failed Mock Behaviour">
	<cfargument name="detail" required="false" default="">
  <cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#" />
</cffunction>

<cffunction name="_$rethrow">
	<cfargument name="e" >
  <cfthrow object="#e#" />
</cffunction>


</cfcomponent>