<cfcomponent displayname="MockFactoryFactory" output="false" hint="Fetches mock frameworks for tests. Test writers should not have to deal with this object directly. Use mock(...) instead">
	
	<cfset variables.componentUtils = createObject("component","ComponentUtils") />
	<cfset variables.Factory = 'mxunit.framework.mightymock.MightyMock' />
	<cfset variables.mockFactoryInfo = chr(0) />
	
	<cffunction name="MockFactoryFactory">
		<cfargument name="frameworkName" required="false" default="" />
		<cfset variables.mockFactoryInfo = findMockFactory(arguments.frameworkName)  />
		<cfset setFactory(variables.mockFactoryInfo.factoryPath) />
		<cfif Len(variables.mockFactoryInfo.constructorName)>
			<cfif StructCount(variables.mockFactoryInfo.constructorArgs)>
				<cfinvoke component="#variables.Factory#" method="#variables.mockFactoryInfo.constructorName#" argumentcollection="#variables.mockFactoryInfo.constructorArgs#" />
			<cfelse>
				<cfinvoke component="#variables.Factory#" method="#variables.mockFactoryInfo.constructorName#" />
			</cfif>
		</cfif>
		<cfreturn this />
	</cffunction>

	<cfscript>
		
		function findMockFactory(frameworkName){
			var fw_inf = chr(0);
			try{
			  fw_inf = variables.componentUtils.getMockFactoryInfo(arguments.frameworkName);
			} catch(expression e){
				_$throw("org.mxunit.exception.MockFrameworkNotRegisteredException", "Mock framework '#arguments.frameworkName#' appears not to be registered.", "Make sure '#arguments.frameworkName#' is installed and registered in mxunit-config.xml.");			
			}
		  return fw_inf;
		}

		
		//injectable for cleaner design and testing
		function setFactory( mockPath ){
		   try {
		    variables.Factory = createObject("component", mockPath );
		   } catch(Any e){ //bug. not catching any exception for createObject
				_$throw("org.mxunit.exception.MockFrameworkNotInstalledException", "Mock framework '#arguments.mockPath#' appears not to be installed.", "Make sure '#arguments.mockPath#' is installed and registered correctly in mxunit-config.xml.");			
			}
		}

		
		function getFactory() {
			return variables.Factory;
		}

		
		function getConfig(name) {
			return variables.mockFactoryInfo[name];
		}
			
	</cfscript>	



<cffunction name="_$throw">
  <cfargument name="type">
  <cfargument name="message">
  <cfargument name="detail">
  <cfthrow type="#type#" message="#message#" detail="#detail#" />
</cffunction>

</cfcomponent>