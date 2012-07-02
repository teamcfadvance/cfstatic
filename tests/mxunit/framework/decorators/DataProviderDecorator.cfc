<!---
Provides dataprovider functionality to test cases.

Looks at the test method for "mxunit:dataprovider" or "dataprovider" annotation and, if found, runs
the test method
for each member of the data provider
 --->
<cfcomponent extends="mxunit.framework.TestDecorator" output="false">

	<!--- Represents the context, or scope of the method's cfc under test --->
	<cfset variables.context = '' />
	<cfset variables.methodCallInfo = '' />

	<cffunction name="invokeTestMethod" access="public" returntype="string" output="false">
		<cfargument name="methodName" hint="the name of the method to invoke" type="string" required="Yes"/>
		<cfargument name="args" hint="Optional set of arguments" type="struct" required="No"/>

		<cfset var dpName = getAnnotation(methodName, "dataprovider")/>
		<cfset var outputOfTest = "">
		<cfif len(dpName)>
			<!---<cflog text="inside dataproviderdecorator....  running dataprovider named #dpName#">--->

			<cfset variables.context = getVariablesScope() />

			<cfsavecontent variable="outputOfTest">
				<cfset runDataProvider(methodName, dpName)>
			</cfsavecontent>

			<cfreturn outputOfTest>
		<cfelse>
			<cfreturn getTarget().invokeTestMethod(argumentCollection=arguments)/>
		</cfif>

	</cffunction>

	<cffunction name="runDataProvider" access="private" hint="Main entry point. Delegates to specific datatype handler">
		<cfargument name="methodName" type="any" required="true"/>
		<cfargument name="dataProvider" type="any" required="true" hint="Name of object to iterate"/>

		<cfset var provider = ''/>

		<cftry>
			<cfset provider = context[arguments.dataprovider]/>
		<cfcatch type="coldfusion.runtime.UndefinedElementException">
			<!--- Make sure simple numeric data passes, which would not be in variables scope --->
			<cfif not isNumeric(dataProvider)>
				<cfset _$throw()/>
			</cfif>
		</cfcatch>
		</cftry>

		<cfif isQuery(provider)>
			<cfset runQueryDataProvider(methodName, dataProvider)>
		<cfelseif isArray(provider)>
			<cfset runArrayDataProvider(methodName, dataProvider)>
		<cfelseif isStruct(provider)>
			<cfset runStructDataProvider(methodName, dataProvider)>
		<cfelseif isNumeric(provider) or isNumeric(dataProvider)>
			<cfset runNumericDataProvider(methodName, dataProvider)>
		<cfelseif fileExists(provider)>
			<cfset runFileDataProvider(methodName, dataProvider)>
		<cfelseif fileExists(expandPath(provider))>
			<cfset runFileDataProvider(methodName, expandPath(provider))>
		<cfelseif isSimpleValue(provider)>
			<cfset runListDataProvider(methodName, dataProvider)>
		<cfelseif isStruct(provider)>
			<cfset runStructDataProvider(methodName, dataProvider)>

		<cfelse>
			<cfthrow type="mxunit.exception.InvalidDataProviderException"
			         message="The dataprovider specified is not of a supported type"
			         detail="The supported types are query, array, numeric, file, and list"/>
		</cfif>
	</cffunction>

	<cffunction name="runStructDataProvider" access="public">
		<cfargument name="methodName" type="any" required="true"/>
		<cfargument name="dataProvider" type="any" required="true" hint="Name of a query"/>

		<cfscript>
			var method = getMethod(arguments.methodName);
			var structName = '';
			var structObject = '';
			var key = '';
			var item = 1;
			var args = structNew();
			var temp = structNew();
		</cfscript>

		<cfif not arrayLen(getMetaData(method).parameters)>
			<cfthrow type="mxunit.exception.MissingDataProviderArgumentException"
			         message="You must specify a  <cfargument...> when using the dataprovider annotation in your test."
			         detail="Usage: <cffunction mxunit:dataprovider ...> <cfargument name=""theStruct"" />">
		</cfif>

		<cfscript>
			structName = getMetaData(method).parameters[1].name;
			structObject = context[dataProvider];
			//args[structName] = structObject;
		</cfscript>

		<cfloop collection="#structObject#" item="item">
			<cfset temp = structNew() />
			     <cfset temp[item] = structObject[item]>
			     <cfset args[structName] = temp>
			     <cfset _$invoke(methodName, args)>
		</cfloop>
	</cffunction>

	<cffunction name="runNumericDataProvider" access="public">
		<cfargument name="methodName" type="any" required="true"/>
		<cfargument name="dataProvider" type="any" required="true" hint="Name of a query"/>

		<cfscript>
			var method = getMethod(arguments.methodName);
			var index = 1;
			var idxName = 1;
			var count = 0;
			var args = structNew();
			if(NOT arrayLen(getMetaData(method).parameters))
			{
				_$throw(type="mxunit.exception.MissingDataProviderArgumentException",
			         message="You must specify a  <cfargument...> when using the dataprovider annotation in your test.",
			         detail="Usage: <cffunction mxunit:dataprovider ...> <cfargument name=""index"" />");
			}
			idxName = getMetaData(method).parameters[1].name;
			try
			{
				count = context[dataProvider];//account for variable names vs. raw int values
			}
			catch(any e)
			{
				count = dataProvider;
			}
			args[idxName] = 0;
			for(i = 1; i LTE count; i = i + 1)
			{
				args[idxName] = i;
				_$invoke(arguments.methodName, args);
			}
		</cfscript>

	</cffunction>

	<cffunction name="runListDataProvider" access="public">
		<cfargument name="methodName" type="any" required="true"/>
		<cfargument name="dataProvider" type="any" required="true" hint="Name of a query"/>

		<cfscript>
			var method = getMethod(arguments.methodName);
			var listItemName = '';
			var listItem = '';
			var item = 1;
			var args = structNew();
			var listLength = 1;
			var toArray = "";
			if(NOT arrayLen(getMetaData(method).parameters))
			{
				_$throw(type="mxunit.exception.MissingDataProviderArgumentException",
			         message="You must specify a  <cfargument...> when using the dataprovider annotation in your test.",
			         detail="Usage: <cffunction mxunit:dataprovider ...> <cfargument name=""listItem"" />");
			}
			listItemName = getMetaData(method).parameters[1].name;
			listObject = context[dataProvider];
			args[listItemName] = '';
			toArray = listToArray(listObject, ",;:/\");
			listLength = arrayLen(toArray);
			if(listLength eq 0)
				_$throw(message="List DataProvider #dataProvider# did not contain any elements");
			for(item = 1; item LTE listLength; item = item + 1)
			{
				args[listItemName] = toArray[item];
				_$invoke(arguments.methodName, args);
			}
		</cfscript>

	</cffunction>

	<cffunction name="runArrayDataProvider" access="public">
		<cfargument name="methodName" type="any" required="true"/>
		<cfargument name="dataProvider" type="any" required="true" hint="Name of an array"/>

		<cfscript>
			var method = getMethod(arguments.methodName);
			var i = 1;
			var args = structNew();
			var params = getMetaData(method).parameters;
			var index = iif(arrayLen(params) eq 2, de("params[2]"), de("index"));
			var itemName = "item";

			if(not arraylen(params))
			{
				_$throw(type="mxunit.exception.MissingDataProviderArgumentException",
			         message="You must specify a  <cfargument...> when using the dataprovider annotation in your test.",
			         detail="Usage: <cffunction mxunit:dataprovider ...> <cfargument name=""arrayName"" /><cfargument name=""index"" />");
			}
			itemName = params[1].name;//could make optional
			arrayObject = context[dataProvider];
			if(ArrayLen(arrayObject) eq 0)
				_$throw(message="Array DataProvider #dataProvider# did not contain any elements");
			for(i = 1; i LTE ArrayLen(arrayObject); i = i + 1)
			{
				args[itemName] = arrayObject[i];
				args[index] = i;
				_$invoke(arguments.methodName, args);
			}
		</cfscript>

	</cffunction>

	<!---
	   Note that datprovider can be a string or a query object. But, as of
	   ColdFusion 8, you must use constants in custom cffunction attributes.
	   no can do this mxunit:dataprovider="#myData#". must do this:
	    mxunit:dataprovider="myData"
	   --->

	<cffunction name="runQueryDataProvider" access="public" hint="runner for DataProvider-driven tests">
		<cfargument name="methodName" type="any" required="true"/>
		<cfargument name="dataProvider" type="any" required="true" hint="Name of a query"/>

		<cfscript>
			var localQuery = '';
			var tempQ = '';

			//NOTE: was duplicating query, but probably is not needed
			//as were are not altering the query object, but the cursor
			//is altered. This might have an effect on threaded tests.
			if(isQuery(dataProvider))
			{
				localQuery = dataProvider;
			}
			else
			{
				localQuery = variables.context[dataProvider];
			}
			localQuery = duplicate(localQuery);//we MUST do this; otherwise, the query cannot be reused
			if(not isQuery(localQuery))
				_$throw(message="DataProvider #dataProvider# was not a query");
			if(not localQuery.RecordCount)
				_$throw(message="Query DataProvider #dataProvider# did not contain any rows");
			while(localQuery.next())
			{
				invokeComponentForQueryProvider(methodName, getTopRow(localQuery));
				//This fails on Railo-different Java interface than ColdFusion
				localQuery.removeRows(javacast('int', localQuery.getRow() - 1), javacast('int', 1));
				localQuery.beforefirst();
			}
		</cfscript>

	</cffunction>

	<cffunction name="runFileDataProvider" access="public"
	            hint="runner for File-based DataProvider-driven tests">
		<cfargument name="methodName" type="any" required="true"/>
		<cfargument name="dataProvider" type="any" required="true" hint="Name of a file"/>

		<cfscript>
			var providerFile = context[dataProvider];
			var extension = listLast(providerFile, ".");
			var poi = createObject("component", "mxunit.framework.POIUtility").init();
			var csv = createObject("component", "mxunit.framework.CSVUtility");
			var readResult = "";
			if(extension eq "xls")
			{
				readResult = poi.readExcel(providerFile, true, 0);
				runQueryDataProvider(methodName, readResult.Query);
			}
			else if(extension eq "csv")
			{
				readResult = csv.readCSV(providerFile, true);
				runQueryDataProvider(methodName, readResult.Query);
			}
			else
			{
				_$throw(message="In this case, #extension# is not currently a supported file-based dataprovider");
			}
		</cfscript>

	</cffunction>

	<cffunction name="getTopRow" access="private">
		<cfargument name="theQuery" type="query"/>
		<cfset var q = "">
		<cfquery name="q" maxrows="1" dbtype="query">
			select * from arguments.thequery
		</cfquery>
		<cfreturn q/>
	</cffunction>

	<!--- Handles query invocations only --->

	<cffunction name="invokeComponentForQueryProvider" access="private">
		<cfargument name="methodName" type="string" required="true"/>
		<cfargument name="query" type="query" required="true"/>

		<cfscript>
			var args = structNew();
			var localVar = '';
			var method = getMethod(arguments.methodName);
			var queryName = '';
			if(NOT arrayLen(getMetaData(method).parameters))
			{
				_$throw(type="mxunit.exception.MissingDataProviderArgumentException",
			         message="You must specify a  <cfargument...> when using the dataprovider annotation in your test.",
			         detail="Usage: <cffunction mxunit:dataprovider ...> <cfargument name=""queryName"" />");
			}

			queryName = getMetaData(method).parameters[1].name;
			args[queryName] = arguments.query;
			_$invoke(arguments.methodName, args);
		</cfscript>

	</cffunction>

	<cffunction name="_$throw">
		<cfargument name="type" required="false"
		            default="mxunit.exception.InvalidDataProviderReferenceException"/>
		<cfargument name="message" required="false" default="Invalid DataProvider specified. "/>
		<cfargument name="detail" required="false"
		            default="This usually happens if the name of your dataprovider is wrong or you are passing in something other than a string. "/>

		<cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#"/>
	</cffunction>

	<cffunction name="_$invoke" access="private">
		<cfargument name="methodName"/>
		<cfargument name="args"/>

		<cfreturn getTarget().invokeTestMethod(argumentCollection=arguments)/>
	</cffunction>

	<cffunction name="getMethod" access="private">
		<cfargument name="methodName" type="string" required="true"/>
		<cfscript>
			var target = getBaseTarget();
			return target[arguments.methodName];
        </cfscript>
	</cffunction>

</cfcomponent>