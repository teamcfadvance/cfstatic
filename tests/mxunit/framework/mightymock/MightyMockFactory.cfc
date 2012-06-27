<cfcomponent output="false">
 <cfscript>
  mocks = [];


  function init(){
    return this;
  }



  function create(){
  	//create basic mock with no name info
    if(arguments.size() eq 0 )  return createObject('component','MightyMock').init();
    //create basic mock with a name for reference/debugging
    if(arguments.size() eq 1 )  return createObject('component','MightyMock').init(arguments[1]);
    //create type-safe mock.
    if(arguments.size() eq 2 )  return createObject('component','MightyMock').init(arguments[1],arguments[2]);
    //create a type-safe mock and a spy
    //if(arguments.size() eq 3 )  return createObject('component','MightyMock').init(arguments[1],arguments[2],arguments[3]);
  }

  function createSpy(name) {
    return createObject('component','MightyMock').createSpy(arguments.name);
  }

  function listMocks(){
   return arrayToList(mocks);
  }
 </cfscript>

</cfcomponent>