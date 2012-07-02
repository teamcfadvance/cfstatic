<cfcomponent hint="makes private methods testable" output="false">

	<cfset cu = createObject("component","ComponentUtils")>
	<cfset blender = createObject("component","ComponentBlender")>

	<cfset lineSep = cu.getLineSeparator()>
	<cfset dirSep = cu.getSeparator()>


	<cffunction name="makePublic" access="public" hint="creates a public method proxy for the indicated private method for the passed-in object" returntype="any">

		<cfargument name="ObjectUnderTest" required="true" type="any" hint="an instance of the object with a private method to be proxied">
		<cfargument name="privateMethodName" required="true" type="string" hint="name of the private method to be proxied">
		<cfargument name="proxyMethodName" required="false" type="string" default="" hint="name of the proxy method name to be used; if not passed, defaults to the name of the private method prefixed with an underscore">

		<cfset var md = getMetadata(ObjectUnderTest)>
		<cfset var methodStruct = findMethodStruct(md,privateMethodName)>
		<cfset var output = "">
		<cfset var cfcode = "">
		<cfset var file = "">
		<cfset var cfcnotation = "">
		<cfset var dir = getDirectoryFromPath(getCurrentTemplatePath()) & dirSep & "generated" & dirSep>
		<cfset var proxy = "">
		<cfset var s_args = "">
		<cfset var componentReturnTag = "return">
		<cfset var renamedExistingMethod = arguments.privateMethodName & "_mxunitproxy">

		<cfif StructIsEmpty(methodStruct)>
			<cfthrow message="Attempting to make public proxy for private method: method named #privateMethodName# did not exist in object of type #md.name#">
		</cfif>

		<cfif NOT len(trim(proxyMethodName))>
			<cfset arguments.proxyMethodName = "#privateMethodName#">
		</cfif>

		<cfset cfcnotation = arguments.proxyMethodName & "_#createUUID()#">
		<cfset file = cfcnotation & ".cfc">
		<cfif StructKeyExists(methodStruct,"returntype") and methodStruct.returntype eq "void">
			<cfset componentReturnTag = "set">
		</cfif>

		<cfset handleDirectoryCreate(dir)>

		<!--- NOTE: see https://github.com/mxunit/mxunit/issues/12 --->
		<!---<cfset s_argTags = constructArgumentsTags(methodStruct)>--->

		<!--- generate a CFC that contains a public method. this method will call the private method we want to call --->
		<cfoutput>
		<cfsavecontent variable="output">
		<%cfcomponent extends="#md.name#"%>

		<%cffunction name="#arguments.proxyMethodName#" access="public"%>
			<!---#s_argTags#--->
			<%cf#componentReturnTag# #renamedExistingMethod#(argumentCollection=arguments)%>
		<%/cffunction%>

		<%/cfcomponent%>
		</cfsavecontent>
		</cfoutput>
		<cfset cfcode = replace(output,"%","","all")>
		<cfset handleFileCreate(dir & file, cfcode)>

		<!--- now, create an instance of that generated object --->
		<cfset proxy = handleObjectCreate(cfcnotation)>

		<!--- NOTE: all of this rejiggering is so that we can call the private method directly rather than having to call a differently-named proxy method! --->

		<!--- move the current privateMethod into a newly named method --->
		<cfset blender._mixinAll(arguments.ObjectUnderTest,blender)>
		<cfset arguments.ObjectUnderTest._mixin(renamedExistingMethod,arguments.ObjectUnderTest._getComponentVariable(privateMethodName))>
		<!--- inject that function's proxy method into the object passed in; now we can call this new method, which will call the private method --->
		<cfset arguments.ObjectUnderTest._mixin(arguments.proxyMethodName,proxy[arguments.proxyMethodName])>

		<!--- cleanup; i doubt this will be enough so we'll need some way of periodically cleaning out that directory I suspect --->
		<cfset handleFileDelete(dir & file)>
		<cfreturn ObjectUnderTest>
	</cffunction>

	<cffunction name="findMethodStruct" returntype="struct" access="private" hint="returns the metadata struct for a given method name">
		<cfargument name="metadata" required="true" type="struct" hint="a structure returned from getMetadata">
		<cfargument name="methodName" required="true" type="string" hint="the method to search for">

		<cfset var methodStruct = StructNew()>
		<cfset var i = 1>

		<cfif structKeyExists(metadata, "functions")>
			<cfloop from="1" to="#ArrayLen(metadata.functions)#" index="i">
				<cfif metadata.functions[i].name eq arguments.methodName>
					<cfreturn metadata.functions[i]>
				</cfif>
			</cfloop>
			<!--- If we get here, we haven't found the function; check superclasses --->
			<cfif structKeyExists(metadata, "extends")>
				<cfreturn findMethodStruct(metadata.extends, methodName) />
			</cfif>
		<cfelse> <!--- Check superclasses, if any --->
			<cfif structKeyExists(metadata, "extends")>
				<cfreturn findMethodStruct(metadata.extends, methodName) />
			</cfif>
		</cfif>

		<cfreturn methodStruct>

	</cffunction>

	<cffunction name="constructArgumentsTags" returntype="string" access="private" hint="creates the cfargument tags, the method call to the private method, and the return statement for the component">
		<cfargument name="privateMethodStruct" type="struct" hint="the structure of metadata for the private method under consideration">
		<cfset var strArgTags = "">
		<cfset var thisParamString = "">
		<cfset var thisTagString = "">
		<cfset var a_params = privateMethodStruct.Parameters>
		<cfset var p = 1>
		<cfset var pCount = ArrayLen(a_params)>

		<cfloop from="1" to="#pCount#" index="p">
			<cfparam name="a_params[p].required" default="false">
			<cfset thisTagString = "<cfargument name='#a_params[p].name#' required='#a_params[p].required#'">
			<cfif structKeyExists(a_params[p], 'default')>
				 <cfset thisTagString = thisTagString & " default='#a_params[p].default#'">
			</cfif>
			<cfset thisTagString = thisTagString & ">">
			<cfset thisParamString = a_params[p].name & " = arguments.#a_params[p].name#">
			<cfset strArgTags = ListAppend(strArgTags, thisTagString, lineSep)>
		</cfloop>
		<cfreturn strArgTags>
	</cffunction>

	<cffunction name="handleDirectoryCreate" output="false" access="public" returntype="any" hint="">
		<cfargument name="dir" type="string" required="true"/>
		<cfif not DirectoryExists(dir)>
			<cfdirectory action="create" directory="#dir#">
		</cfif>
	</cffunction>

	<cffunction name="handleFileCreate" output="false" access="public" returntype="any" hint="">
		<cfargument name="fullFilePath" type="string" required="true"/>
		<cfargument name="output" type="string" required="true"/>
		<cffile action="write" file="#fullFilePath#" output="#output#">
	</cffunction>

	<cffunction name="handleFileDelete" output="false" access="public" returntype="any" hint="">
		<cfargument name="fullFilePath" type="string" required="true"/>
		<cffile action="delete" file="#fullFilePath#">
	</cffunction>

	<cffunction name="handleObjectCreate" output="false" access="public" returntype="any" hint="">
		<cfargument name="cfcname" type="string" required="true"/>
		<cfreturn createObject("component","mxunit.framework.generated.#cfcname#")>
	</cffunction>

</cfcomponent>