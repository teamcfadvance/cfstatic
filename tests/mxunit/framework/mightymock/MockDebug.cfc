<cfcomponent output="false">
<!---
    to do: pretty print info about the currently mocked object


What's important to print?

Name of Object being mocked,
Is it a spy?
Is it simple or type safe?
What are the registered behaviors?
What has been invoked?


Idea: Display tree:
 Mock Name: foo.bar
      Registered Mock Methods (query):
         Method Name:
         ID:
         Parameters
            For each param in args, print name,value
         Type:
         Returns:
         Throws:
         Time Registered

      Invocaction Record:
         ID:
         Parameters
            For each param in args, print name,value
         Matched Patter:
         Status:
         Time:


verbose: above plus + display raw

Must be fast!
--->
<cfscript>


function debug(mock,verbose){
 var mockBug = {};
 var registry = mock._$getRegistry();
 structInsert(mockBug," MockName", mock.getMocked().name );
 structInsert(mockBug, 'Mocked Methods', registry.getRegistry());
 structInsert(mockBug, 'Invocation Records', registry.invocationRecord);
 structInsert(mockBug, 'Returns and Throws Data' , registry.registryDataMap);
 structInsert(mockBug, 'Method Arguments' , registry.argMap);
 return mockBug;
}

function printRegistryDebug(reg) {

}
</cfscript>
</cfcomponent>