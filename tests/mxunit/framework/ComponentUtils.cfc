<cfcomponent name="mxunit.framework.ComponentUtils" output="false" hint="Internal component not generally used outside the framework">

	<cfset sep = getSeparator() />

	<cffunction name="ComponentUtils" returnType="ComponentUtils" hint="Constructor"><cfreturn this /></cffunction>

	<cffunction name="isFrameworkTemplate" returntype="boolean" hint="whether the passed in template is part of the mxunit framework">
		<cfargument name="template" type="string" required="true" />
		<!--- braindead simple.... is anything more than this necessary? --->
		<cfreturn refindNoCase("mxunit(.*?)[/\\](trunk[/\\])?framework",template) />
	</cffunction>


	<cffunction name="getSeparator" returntype="string" hint="Returns file.separator as seen by OS.">
		<cfreturn createObject("java","java.lang.System").getProperty("file.separator") />
	</cffunction>


	<cffunction name="getLineSeparator" returntype="string" hint="Returns file.separator as seen by OS.">
		<cfreturn createObject("java","java.lang.System").getProperty("line.separator") />
	</cffunction>


	<cffunction name="getInstallRoot" returnType="string" access="public">
		<cfscript>
			var root = expandPath("/");
			var mxunit = 0;

			//shortcut of the usual case of a virtualhost / alias on the web root
			if(fileExists(expandPath("/mxunit/framework/mxunit-config.xml")))
			{
				return getContextRoot() &  "/mxunit";
			}
		</cfscript>

		<!--- check for the a physical directory --->
		<cfdirectory action="list" directory="#root#" recurse="true" name="mxunit" filter="mxunit-config.xml">

		<cfif mxunit.RecordCount eq 0>
			<cfif mxunit.RecordCount eq 0>
				<cfthrow message="Could not find mxunit in the web root" />
			</cfif>
		</cfif>

		<cfscript>
			root = replaceNoCase("#mxunit.directory#/#mxunit.name#", root,"");
			root = getDirectoryFromPath(root);

			root = getContextRoot() &  "/" &  left(root, (Len(root) - Len("/framework/")));

			return root;
		</cfscript>
	</cffunction>

	<cffunction name="getComponentRoot" returnType="string" access="public">
		<cfargument name="fullPath" type="string" required="false" default="" hint="Test Hook." />
		<cfscript>
			// Use the mxunit-config.xml to handle install location in case of weird behavior
			// or if user wants custom configuration
			var cm = createObject("component","ConfigManager").ConfigManager();
			var userConfig = cm.getConfigElement("userConfig","componentRoot");
			var mxUnitRoot = userConfig[1].xmlAttributes["value"];
			var override = userConfig[1].xmlAttributes["override"];

			var i = 1;//loop index
			var sep = ".";
			var package = arrayNew(1); //list
			var installRoot = "";
			//We know THIS "should" always be in mxunt.framework.ComponentUtils
			var md = getMetaData(this);
			var name = md.name;

			//Inject fullPath argument for testing
			if(len(arguments.fullPath)) {
			  name = arguments.fullPath;
			}

			//Workaround for Mac/Apache configs that do not return
			//fully qualified names for getMetaData()
			if(name is "ComponentUtils" OR name is "" OR name is "."){
				//use the userConfig/componentRoot element value in mxunit-config.xml
				return(mxunitRoot);
			}

			//If user needs to override default install location.
			// Note name is "override" is an injected test hook.
			if(name is "override" OR override){
			  return(mxunitRoot);
			}

			package = listToArray(name,".");
			for(i; i lte arrayLen(package)-2; i = i + 1){
			  installRoot = installRoot & package[i] & sep;
			 }
			return left(installRoot, len(installRoot)-1);
		</cfscript>
	</cffunction>


	<cffunction name="dump">
		<cfargument name="o" />
		<cfdump var="#arguments.o#" />
	</cffunction>

	<cffunction name="hasJ2EEContext">
		<cfreturn getContextRootPath() is not "">
	</cffunction>

	<cffunction name="getContextRootComponent">
		<cfset var rootComponent = "" />
		<cfset var ctx = getContextRootPath() />
		<cfif hasJ2EEContext()>
			<!--- This last  "." worries me. Under what circumstance will this not be true? --->
			<cfset rootComponent = right(ctx,len(ctx)-1) &  "." />
		</cfif>
		<cfreturn  rootComponent />
	</cffunction>


	<cffunction name="getContextRootPath">
		<cfset var ctx= "" />
		<cfset ctx = getPageContext().getRequest().getContextPath() />
		<cfreturn ctx />
	</cffunction>


	<cffunction name="isCfc" hint="Determines whether or not the given object is a ColdFusion component; Author: Nathan Dintenfass ">
		<cfargument name="objectToCheck" />
		<cfscript>
			//get the meta data of the object we're inspecting
			var metaData = getMetaData(arguments.objectToCheck);
			//if it's an object, let's try getting the meta Data
			if(isObject(arguments.objectToCheck)){
			    //if it has a type, and that type is "component", then it's a component
			    if(structKeyExists(metaData,"type") AND metaData.type is "component"){
			        return true;
			    }
			}
			//if we've gotten here, it must not have been a contentObject
			return false;
		</cfscript>
	</cffunction>


	<cffunction name="getMockFactoryInfo" returnType="any" access="public">
		<cfargument name="factoryName" required="false" default="" />
		<cfscript>
			// Using the mxunit-config.xml to store the mock factory config
			var cm = createObject("component","ConfigManager").ConfigManager();
			var mockFactoryInfo = StructNew();
			if (not Len(arguments.factoryName)) {
			 arguments.factoryName = cm.getConfigElementValue("mockingFramework","name");
			}
			mockFactoryInfo.factoryPath = cm.getConfigElementValue(arguments.factoryName,"factoryPath");
			mockFactoryInfo.createMockMethodName = cm.getConfigElementValue(arguments.factoryName,"createMockMethodName");
			mockFactoryInfo.createMockStringArgumentName = cm.getConfigElementValue(arguments.factoryName,"createMockStringArgumentName");
			mockFactoryInfo.createMockObjectArgumentName = cm.getConfigElementValue(arguments.factoryName,"createMockObjectArgumentName");
			mockFactoryInfo.constructorName = cm.getConfigElementValue(arguments.factoryName,"constructorName");
			mockFactoryInfo.constructorArgs = cm.getConfigElementAttributeCollection(arguments.factoryName,"constructorArgs");
			return mockFactoryInfo;
		</cfscript>
	</cffunction>
	
	<cffunction name="objectIsTypeOf" output="false" access="public" returntype="boolean" hint="returns true if the object 'type' as reported by getMetadata() matches the object's type or if the object is in the inheritance tree of the type">    
		<cfargument name="object" required="yes" type="any" />
		<cfargument name="type" required="yes" type="string" />
		<cfset var md = getMetaData(object)>
		<cfset var oType = md.name>
		<cfset var ancestry = buildInheritanceTree(md) />

		<cfreturn listFindNoCase(ancestry, arguments.type)>
    </cffunction>

	<cffunction name="buildInheritanceTree" access="public" returntype="string">
		<cfargument name="metaData" type="struct" />
		<cfargument name="accumulator" type="string" required="false" default=""/>

		<cfscript>
			var key = "";

			if( structKeyExists(arguments.metadata,"name") AND listFindNoCase(accumulator,arguments.metaData.name) eq 0 ){
				accumulator =  accumulator & arguments.metaData.name & ",";
			}

			if(structKeyExists(arguments.metaData,"extends")){
				//why, oh why, is the structure different for interfaces vs. extends? For F**k's sake!
				if( structKeyExists( metadata.extends, "name" ) ){
					accumulator = buildInheritanceTree(metaData.extends, accumulator);
				}else{
					accumulator = buildInheritanceTree(metadata.extends[ structKeyList(metadata.extends) ], accumulator);
				}
			}

			if(structKeyExists(arguments.metaData,"implements")){
				for(key in arguments.metadata.implements){
					accumulator = buildInheritanceTree(metaData.implements[ key ], accumulator);
				}
			}

			return  accumulator;
		</cfscript>

	</cffunction>

</cfcomponent>
