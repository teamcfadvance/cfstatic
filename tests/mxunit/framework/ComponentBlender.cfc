<cfcomponent hint="utilities for mixins and other goodness">

	<!--- these are prefixed with an underscore to avoid collisions in other objects where  'real' method names like 'mixin' exist'--->

	<cffunction name="_MixinAll" access="public">
		<cfargument name="objReceiver" required="true" hint="the object to receive the functions">
		<cfargument name="objGiver" required="true" hint="the object whose functions will be mixed in">
		<cfargument name="includedMethods" required="false" default="" hint="pass a list of methods; otherwise, all are included">
		<cfset var md = getMetadata(objGiver)>
		<cfset var a_functions = md.functions>
		<cfset var fn = 1>

		<cfset arguments.objReceiver._Mixin = _Mixin>
		<cfset arguments.objGiver._getComponentVariable = _getComponentVariable>

		<cfloop from="1" to="#ArrayLen(a_functions)#" index="fn">
			<cfif (arguments.includedMethods eq "" OR listFindNoCase(arguments.includedMethods,a_functions[fn].name))>
				<cfset arguments.objReceiver._Mixin(a_functions[fn].name, arguments.objGiver._getComponentVariable(a_functions[fn].name))>
			</cfif>
		</cfloop>
	</cffunction>

	<cffunction name="_Mixin" access="public">
		<cfargument name="propertyName" type="string" required="true">
		<cfargument name="property" type="any" required="true">
		<cfargument name="ignoreIfExisting" type="boolean" required="false" default="true">
		<cfif StructKeyExists(variables,propertyName) AND arguments.ignoreIfExisting>
			<cfset this[propertyName] = property>
			<cfreturn>
		</cfif>
		<cfset variables[propertyName] = property>
		<cfset this[propertyName] = property>
	</cffunction>

	<cffunction name="_copyToNewName" output="false" access="public" returntype="any" hint="">
		<cfargument name="propertyName" type="string" required="true"/>
		<cfargument name="newPropertyName" type="string" required="true"/>
		<cfargument name="ignoreIfExisting" type="boolean" required="false" default="true">

		<cfif ignoreIfExisting AND structKeyExists( variables, newPropertyName )>
			<cfreturn>
		</cfif>
		<cfif structKeyExists( variables, propertyName )>
			<cfset variables[newPropertyName] = variables[propertyName]>
		</cfif>
    </cffunction>


	<cffunction name="_MixinProperty" access="public">
		<cfargument name="propertyName" type="string" required="true">
		<cfargument name="property" type="any" required="true">
		<cfargument name="scope" type="string" default="" required="false" hint="what scope should this be put in? if not passed, will be put into this and variables">
		<cfif len(arguments.scope)>
			<cfset "#arguments.scope#.#arguments.propertyName#" = arguments.property>
		<cfelse>
			<cfset _mixin(propertyName,property,false)>
		</cfif>

	</cffunction>

	<cffunction name="_CopyToThisScope" access="public">
		<cfargument name="propertyName" type="string" required="true">
		<cfargument name="nameInThisScope" type="any" required="true">
		<cfset this[nameInThisScope] = variables[propertyName]>
	</cffunction>

	<cffunction name="_IsComponentVariableDefined" access="public" returntype="boolean">
		<cfargument name="varname" type="string" required="true">
		<cfif StructKeyExists(variables,varname)>
			<cfreturn true>
		<cfelse>
			<cfreturn false>
		</cfif>
	</cffunction>

	<cffunction name="_getComponentVariable" access="public" returntype="any">
		<cfargument name="varname" type="string" required="true">
		<cfreturn variables[varname]>
	</cffunction>

	<cffunction name="_getComponentVariables" access="public" returntype="struct">
		<cfreturn variables>
	</cffunction>

</cfcomponent>