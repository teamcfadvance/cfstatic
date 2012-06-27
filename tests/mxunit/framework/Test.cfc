<cfcomponent displayname="Test Interface" hint="Abstract Class or Interface">
 <!--- 
  How can we implement an interface in CFMX?
  --->
	<cffunction name="Test">
	 <cfthrow type="mxunit.exception.CannotInstantiateException" 
	          message="This is an interface and cannot be instantiated directly" />
	</cffunction>
	
	<cffunction name="run" returntype="void">
		<cfthrow type="mxunit.exception.CannotInstantiateException" 
	           message="This is an interface method and cannot be instantiated directly" 
						 detail="Please implement this in the class that is realizing this interface" />
	
	</cffunction>

</cfcomponent>
