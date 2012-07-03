<cfcomponent output="false" hint="I am a base class providing common utility methods for all components. All CfStatic components extend me">

<!--- properties --->
	<cfscript>
		_javaLoader		= "";
		_useJavaLoader	= false;
	</cfscript>

<!--- utility methods --->
	<cffunction name="$throw" access="private" returntype="void" output="false" hint="I throw an error">
		<cfargument name="type"			type="string" required="false" default="CfMinify.error" />
		<cfargument name="message"		type="string" required="false" />
		<cfargument name="detail"		type="string" required="false" />
		<cfargument name="errorCode"	type="string" required="false" />
		<cfargument name="extendedInfo"	type="string" required="false" />

		<cfthrow attributeCollection="#arguments#" />
	</cffunction>

	<cffunction name="$directoryList" access="private" returntype="query" output="false" hint="I return a query of files and subdirectories for a given directory">
		<cfargument name="directory"	type="string" required="true"					/>
		<cfargument name="filter"		type="string" required="false"	default="*.*"	/>
		<cfargument name="recurse"		type="boolean" required="false"	default="true"	/>

		<cfset var result = QueryNew('') />

		<cfif DirectoryExists( arguments.directory )>
			<cfdirectory	action="list"
							directory="#arguments.directory#"
							filter="#arguments.filter#"
							recurse="#arguments.recurse#"
							name="result" />
		</cfif>

		<cfreturn result />
	</cffunction>

	<cffunction name="$directoryClean" access="private" returntype="void" output="false" hint="I delete all the files in a directory">
		<cfargument name="directory" type="string" required="true"/>
		<cfargument name="excludeFiles" type="string" required="false" default="" hint="list of filenames to ignore in the cleaning" />
		<cfargument name="fileTypes" type="string" required="false" default="" />

		<cfset var files = $directoryList( directory=arguments.directory, recurse=false ) />
		<cfloop query="files">
			<cfif files.type EQ 'File' and not ListFind(arguments.excludeFiles, files.name) and (not Len(arguments.fileTypes) or ListFindNoCase(arguments.fileTypes, ListLast(files.name, '.')))>
				<cffile action="delete" file="#files.directory#/#files.name#" />
			</cfif>
		</cfloop>
	</cffunction>

	<cffunction name="$directoryCreate" access="public" returntype="any" output="false">
		<cfargument name="directory" type="string" required="true" />

		<cfdirectory action="create" directory="#arguments.directory#" />
	</cffunction>

	<cffunction name="$fileRead" access="private" returntype="string" output="false" hint="I return the content of the given file (path)">
		<cfargument name="path" type="string" required="true" />

		<cfset var content = "" />
		<cffile action="read" file="#arguments.path#" variable="content" />
		<cfreturn content />
	</cffunction>

	<cffunction name="$fileReadBinary" access="private" returntype="string" output="false" hint="I return the content of the given file (path)">
		<cfargument name="path" type="string" required="true" />
		<cfargument name="convertToBase64" type="boolean" required="false" default="false" />

		<cfset var content = "" />
		<cffile action="readBinary" file="#arguments.path#" variable="content" />
		<cfif arguments.convertToBase64>
			<cfreturn toBase64(content) />
		<cfelse>
			<cfreturn content />
		</cfif>
	</cffunction>

	<cffunction name="$fileWrite" access="private" returntype="void" output="false" hint="I write the passed content to the given file (path)">
		<cfargument name="path"    type="string" required="true" />
		<cfargument name="content" type="string" required="true" />
		<cfargument name="charset" type="string" required="false" default="utf-8" />

		<cffile action="write" file="#arguments.path#" output="#arguments.content#" addnewline="false" charset="#arguments.charset#" />
	</cffunction>

	<cffunction name="$fileLastModified" access="private" returntype="date" output="false" hint="I return the last modified date of the given file (path)">
		<cfargument name="filePath" type="string" required="true" />

		<cfscript>
			var jFile			= CreateObject("java", "java.io.File").init( arguments.filePath );
			var lastmodified	= CreateObject("java","java.util.Date").init( jFile.lastModified() );

			return lastModified;
		</cfscript>
	</cffunction>

	<cffunction name="$fileDelete" access="private" returntype="void" output="false">
		<cfargument name="path" type="string" required="true" />

		<cffile action="delete" file="#arguments.path#" />
	</cffunction>

	<cffunction name="$reSearch" access="private" returntype="struct" output="false" hint="I perform a Regex search and return a struct of arrays containing pattern match information. Each key represents the position of a match, i.e. $1, $2, etc. Each key contains an array of matches.">
		<cfargument name="regex"	type="string"	required="true" />
		<cfargument name="text"		type="string"	required="true" />

		<cfscript>
			var final 	= StructNew();
			var pos		= 1;
			var result	= ReFindNoCase( arguments.regex, arguments.text, pos, true );
			var i		= 0;

			while( ArrayLen(result.pos) GT 1 ) {
				for(i=2; i LTE ArrayLen(result.pos); i++){
					if(not StructKeyExists(final, '$#i-1#')){
						final['$#i-1#'] = ArrayNew(1);
					}
					ArrayAppend(final['$#i-1#'], Mid(arguments.text, result.pos[i], result.len[i]));
				}
				pos = result.pos[2] + 1;
				result	= ReFindNoCase( arguments.regex, arguments.text, pos, true );
			} ;

			return final;
		</cfscript>
	</cffunction>

	<cffunction name="$isUrl" access="private" returntype="boolean" output="false" hint="I return whether or not the passed string is a url (based on a very crude regex, do not use for any stringent url checking)">
		<cfargument name="stringToCheck" type="string" required="true" />
		<cfscript>
			var URLRegEx = "^(http|https)://.*"; // very rough, we don't care for any more precision
			return ReFindNoCase(URLRegEx, stringToCheck);
		</cfscript>
	</cffunction>

	<cffunction name="$httpGet" access="private" returntype="string" output="false" hint="I attempt to get and return the content of the passed url over http.">
		<cfargument name="url" type="string" required="true" />

		<cfhttp url="#arguments.url#" method="get" />
		<cfreturn cfhttp.filecontent />
	</cffunction>

	<cffunction name="$listDeleteLast" access="private" returntype="string" output="false" hint="I delete the last member of the passed string, returning the result of the deletion.">
		<cfargument name="list" type="string" required="true" />
		<cfargument name="delimiter" type="string" required="false" default="," />

		<cfscript>
			if(not Len(list)){
				return "";
			}
			return ListDeleteAt( arguments.list, ListLen(arguments.list, arguments.delimiter), arguments.delimiter);
		</cfscript>
	</cffunction>

	<cffunction name="$listAppend" access="private" returntype="string" output="false" hint="I override listAppend, ensuring that, when a list already contains its delimiter at the end, a duplicate delimiter is not appended">
		<cfargument name="list" type="string" required="true" />
		<cfargument name="value" type="string" required="true" />
		<cfargument name="delimiter" type="string" required="false" default="," />

		<cfscript>
			var delimiterAlreadyOnEnd = Right( arguments.list, Len( arguments.delimiter ) ) eq arguments.delimiter;
			var isEmptyList           = not Len( arguments.list );

			if ( delimiterAlreadyOnEnd or isEmptyList ) {
				return arguments.list & arguments.value;
			}

			return arguments.list & arguments.delimiter & arguments.value;
		</cfscript>
	</cffunction>


	<cffunction name="$renderCssInclude" access="private" returntype="string" output="false" hint="I return the html necessary to include the given css file">
		<cfargument name="src" type="string" required="true" />
		<cfargument name="media" type="string" required="true" />
		<cfargument name="ieConditional" type="string" required="false" default="" />
		<cfargument name="charset" type="string" required="false" default="utf-8" />

		<cfreturn $renderIeConditional('<link rel="stylesheet" href="#arguments.src#" media="#arguments.media#" charset="#arguments.charset#" />', arguments.ieConditional) & $newline() />
	</cffunction>

	<cffunction name="$renderJsInclude" access="private" returntype="string" output="false" hint="I return the html nevessary to include the given javascript file">
		<cfargument name="src" type="string" required="true" />
		<cfargument name="ieConditional" type="string" required="false" default="" />
		<cfargument name="charset" type="string" required="false" default="utf-8" />

		<cfreturn $renderIeConditional( '<script type="text/javascript" src="#arguments.src#" charset="#arguments.charset#"></script>', arguments.ieConditional ) & $newline() />
	</cffunction>

	<cffunction name="$generateCacheBuster" access="private" returntype="string" output="false" hint="I return a cachebuster string for a given date">
		<cfargument name="dateLastModified" type="date" required="false" default="#Now()#" />

		<cfreturn DateFormat(arguments.dateLastModified, 'yyyymmdd') & TimeFormat(arguments.dateLastModified, 'hhmmss') />
	</cffunction>

	<cffunction name="$renderIeConditional" access="private" returntype="string" output="false" hint="I wrap an html include string with IE conditional statements when necessary, returning the result">
		<cfargument name="include" type="string" required="true" />
		<cfargument name="ieConditional" type="string" required="true" />

		<cfif Len(Trim(arguments.ieConditional))>
			<cfreturn '<!--[if #arguments.ieConditional#]>#arguments.include#<![endif]-->' />
		</cfif>

		<cfreturn arguments.include />
	</cffunction>

	<cffunction name="$loadJavaClass" access="private" returntype="any" output="false" hint="I isntanciate and return a java object">
		<cfargument name="className" type="string" required="true" />
		<cfscript>
			if(_getUseJavaLoader()){
				return _getJavaLoader().create(arguments.className);
			}

			return CreateObject('java', arguments.className);
		</cfscript>
	</cffunction>

	<cffunction name="$arrayRemoveDuplicates" access="private" returntype="array" output="false" hint="I remove duplicate elements from an array">
		<cfargument name="theArray" type="array" required="true" />

		<cfscript>
			var noDupes	= StructNew();
			var i		= ArrayLen(arguments.theArray);

			for(i=i; i GT 0; i--){
				noDupes[ arguments.theArray[i] ] = "";
			}

			return StructKeyArray(noDupes);
		</cfscript>
	</cffunction>

	<cffunction name="$arrayMerge" access="private" returntype="array" output="false" hint="I add all the elemnts of one array to another, returning the result">
		<cfargument name="arr1" type="array" required="true" />
		<cfargument name="arr2" type="array" required="true" />

		<cfscript>
			var i = 0;

			for(i=1; i LTE ArrayLen(arguments.arr2); i++){
				ArrayAppend(arguments.arr1, arguments.arr2[i]);
			}

			return arr1;
		</cfscript>
	</cffunction>

	<cffunction name="$overloadedArguments" access="private" returntype="any" output="false" hint="I allow simple function overloading in CF.">
		<cfargument name="typeCombinations" type="array"  required="true" hint="An array of comma separated lists indicating acceptable types of arguments" />
		<cfargument name="variableMappings" type="array"  required="true" hint="For each type combination there must be a corresponding variable mapping. i.e. a variable name for each of the typed arguments." />
		<cfargument name="args"             type="struct" required="true" hint="The arguments themselves" />

		<cfscript>
			var i        = "";
			var n        = "";
			var combo    = "";
			var varnames = "";
			var type     = "";
			var matched  = "";
			var result   = StructNew();

			if(ArrayLen(arguments.typeCombinations) NEQ ArrayLen(arguments.variableMappings)){
				$throw('$overloadedArguments.mismatchedMappings');
			}

			for(i=1; i LTE ArrayLen(arguments.typeCombinations); i++){
				combo    = ListToArray(arguments.typeCombinations[i]);
				varnames = ListToArray(arguments.variableMappings[i]);

				if(ArrayLen(combo) NEQ ArrayLen(varnames)){
					$throw('$overloadedArguments.mismatchedMappings');
				}

				if(ArrayLen(combo) EQ StructCount(arguments.args)){
					matched = true;
					for(n=1; n LTE ArrayLen(combo); n++){
						type = combo[n];
						if(not StructKeyExists(arguments.args, n) or not $isType(arguments.args[n], type)){
							matched = false;
						}
					}
					if(matched){
						for(n=1; n LTE ArrayLen(varnames); n++){
							result[varnames[n]] = arguments.args[n];
						}
						break;
					}
				}
			}

			return result;
		</cfscript>
	</cffunction>

	<cffunction name="$isType" access="private" returntype="boolean" output="false" hint="I return true when the passed variable is of the type, 'type'; false otherwise">
		<cfargument name="variable" type="any" required="true" />
		<cfargument name="type"     type="string" required="true" />

		<cfscript>
			switch(arguments.type){
				case 'any':
					return true;
				case 'numeric':
					return IsNumeric(arguments.variable);
				case 'struct':
					return IsStruct(arguments.variable);
				case 'array':
					return IsArray(arguments.variable);
				case 'date':
					return IsDate(arguments.variable);
				case 'query':
					return IsQuery(arguments.variable);
				case 'xml':
					return IsXml(arguments.variable);
				case 'boolean':
					return IsBoolean(arguments.variable);
				case 'string':
					return IsSimpleValue(arguments.variable);
				default:
					return IsInstanceOf(arguments.variable, arguments.type);
			}
		</cfscript>
	</cffunction>

	<cffunction name="$normalizeUnixAndWindowsPaths" access="private" returntype="string" output="false">
		<cfargument name="path" type="string" required="true" />

		<cfreturn Replace( arguments.path, '\', '/', 'all' ) />
	</cffunction>

	<cffunction name="$shouldFileBeIncluded" access="private" returntype="boolean" output="false">
		<cfargument name="filePath"       type="string" required="true" />
		<cfargument name="includePattern" type="string" required="true" />
		<cfargument name="excludePattern" type="string" required="true" />
		<cfscript>
			filepath = $normalizeUnixAndWindowsPaths(filepath);
			if ( Len(Trim(arguments.includePattern)) AND NOT ReFindNoCase(arguments.includePattern, arguments.filePath) ) {
				return false;
			}

			if ( Len(Trim(arguments.excludePattern)) AND ReFindNoCase(arguments.excludePattern, arguments.filePath) ) {
				return false;
			}

			return true;
		</cfscript>
	</cffunction>

	<cffunction name="$newline" access="private" returntype="string" output="false">
		<cfreturn Chr(13) & Chr(10) />
	</cffunction>

	<cffunction name="$calculateRelativePath" access="private" returntype="string" output="false">
		<cfargument name="basePath"     type="string" required="true" />
		<cfargument name="relativePath" type="string" required="true" />

		<cfscript>
			var basePathArray     = ListToArray( GetDirectoryFromPath( arguments.basePath ), "\/" );
			var relativePathArray = ListToArray( arguments.relativePath, "\/" );
			var finalPath         = ArrayNew(1);
			var pathStart         = 0;
			var i                 = 0;

			/* Define the starting path (path in common) */
			for (i = 1; i LTE ArrayLen(basePathArray); i = i + 1) {
				if (basePathArray[i] NEQ relativePathArray[i]) {
					pathStart = i;
					break;
				}
			}

			if ( pathStart EQ 0 ) {
				ArrayAppend( finalPath, "." );
				pathStart = ArrayLen(basePathArray);
			}

			/* Build the prefix for the relative path (../../etc.) */
			for ( i = ArrayLen(basePathArray) - pathStart; i GTE 0; i=i-1 ) {
				ArrayAppend( finalPath, ".." );
			}

			/* Build the relative path */
			for ( i = pathStart; i LTE ArrayLen(relativePathArray); i=i+1 ) {
				ArrayAppend( finalPath, relativePathArray[i] );
			}

			return ArrayToList( finalPath, "/" );
		</cfscript>
	</cffunction>

	<cffunction name="$uniqueList" access="private" returntype="string" output="false">
		<cfargument name="list" type="string" required="true" />

		<cfscript>
			var listStruct = StructNew();
			var i          = 1;
			for( i=1; i LTE ListLen(arguments.list); i++ ){
				listStruct[ ListGetAt(arguments.list, i) ] = 0;
			}

			return StructKeyList( listStruct );
		</cfscript>
	</cffunction>

	<cffunction name="$ensureFullDirectoryPath" access="private" returntype="string" output="false">
		<cfargument name="dir" type="string" required="true" />
		<cfscript>
			if ( directoryExists( ExpandPath( arguments.dir ) ) ) {
				return ExpandPath( arguments.dir );
			}
			return arguments.dir;
		</cfscript>
	</cffunction>

	<cffunction name="$ensureFullFilePath" access="private" returntype="string" output="false">
		<cfargument name="file" type="string" required="true" />

		<cfscript>
			if ( fileExists( ExpandPath( arguments.file ) ) ) {
				return ExpandPath( arguments.file );
			}
			return arguments.file;
		</cfscript>
	</cffunction>

	<cffunction name="$getStringBuffer" access="private" returntype="any" output="false">
		<cfreturn CreateObject("java","java.lang.StringBuffer") />
	</cffunction>

	<cffunction name="$orderedStructNew" access="private" returntype="struct" output="false">
		<cfreturn CreateObject( "java", "java.util.LinkedHashMap" ).init() />
	</cffunction>

<!--- accessors --->
	<cffunction name="_setJavaLoader" access="private" returntype="void" output="false">
		<cfargument name="javaLoader" required="true" type="any" />
		<cfscript>
			_javaLoader = arguments.javaLoader;
			_setUseJavaLoader(true);
		</cfscript>
	</cffunction>
	<cffunction name="_getJavaLoader" access="private" returntype="any" output="false">
		<cfreturn _javaLoader />
	</cffunction>

	<cffunction name="_setUseJavaLoader" access="private" returntype="void" output="false">
		<cfargument name="useJavaLoader" required="true" type="boolean" />
		<cfset _useJavaLoader = arguments.useJavaLoader />
	</cffunction>
	<cffunction name="_getUseJavaLoader" access="private" returntype="boolean" output="false">
		<cfreturn _useJavaLoader />
	</cffunction>
</cfcomponent>