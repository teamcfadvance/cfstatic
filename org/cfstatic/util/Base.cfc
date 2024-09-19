<cfcomponent output="false" hint="I am a base class providing common utility methods for all components. All CfStatic components extend me">

<!--- utility methods --->
	<cffunction name="$throw" access="private" returntype="void" output="false" hint="I throw an error">
		<cfargument name="type"         type="string" required="false" default="CfMinify.error" />
		<cfargument name="message"      type="string" required="false" />
		<cfargument name="detail"       type="string" required="false" />
		<cfargument name="errorCode"    type="string" required="false" />
		<cfargument name="extendedInfo" type="string" required="false" />

		<cfthrow attributeCollection="#arguments#" />
	</cffunction>

	<cffunction name="$directoryList" access="private" returntype="query" output="false" hint="I return a query of files and subdirectories for a given directory">
		<cfargument name="directory" type="string"  required="true"                 />
		<cfargument name="filter"    type="string"  required="false" default="*.*"  />
		<cfargument name="recurse"   type="boolean" required="false" default="true" />

		<cfset var result = QueryNew('') />

		<cfif DirectoryExists( directory )>
			<cfdirectory
				action    = "list"
				directory = "#directory#"
				filter    = "#filter#"
				recurse   = "#recurse#"
				name      = "result"
			/>
		</cfif>

		<cfreturn result />
	</cffunction>

	<cffunction name="$directoryClean" access="private" returntype="void" output="false" hint="I delete all the files in a directory">
		<cfargument name="directory"    type="string" required="true"/>
		<cfargument name="excludeFiles" type="string" required="false" default="" hint="list of filenames to ignore in the cleaning" />
		<cfargument name="fileTypes"    type="string" required="false" default="" />

		<cfset var files = $directoryList( directory=directory, recurse=false ) />
		<cfloop query="files">
			<cfif files.type EQ 'File' and not ListFind( excludeFiles, files.name ) and (not Len( fileTypes ) or ListFindNoCase( fileTypes, ListLast( files.name, '.') ) )>
				<cffile action="delete" file="#files.directory#/#files.name#" />
			</cfif>
		</cfloop>
	</cffunction>

	<cffunction name="$directoryCreate" access="public" returntype="any" output="false">
		<cfargument name="directory" type="string" required="true" />

		<cfdirectory action="create" directory="#directory#" />
	</cffunction>

	<cffunction name="$fileRead" access="private" returntype="string" output="false" hint="I return the content of the given file (path)">
		<cfargument name="path" type="string" required="true" />

		<cfset var content = "" />
		<cffile action="read" file="#path#" variable="content" />
		<cfreturn content />
	</cffunction>

	<cffunction name="$fileReadBinary" access="private" returntype="string" output="false" hint="I return the content of the given file (path)">
		<cfargument name="path"            type="string"  required="true" />
		<cfargument name="convertToBase64" type="boolean" required="false" default="false" />

		<cfset var content = "" />
		<cffile action="readBinary" file="#path#" variable="content" />
		<cfif convertToBase64>
			<cfreturn toBase64(content) />
		<cfelse>
			<cfreturn content />
		</cfif>
	</cffunction>

	<cffunction name="$fileWrite" access="private" returntype="void" output="false" hint="I write the passed content to the given file (path)">
		<cfargument name="path"    type="string" required="true" />
		<cfargument name="content" type="string" required="true" />
		<cfargument name="charset" type="string" required="false" default="utf-8" />

		<cffile action="write" file="#path#" output="#content#" addnewline="false" charset="#charset#" />
	</cffunction>

	<cffunction name="$fileLastModified" access="private" returntype="date" output="false" hint="I return the last modified date of the given file (path)">
		<cfargument name="filePath" type="string" required="true" />

		<cfscript>
			var jFile        = CreateObject("java", "java.io.File").init( filePath );
			var lastmodified = CreateObject("java","java.util.Date").init( jFile.lastModified() );

			return lastModified;
		</cfscript>
	</cffunction>

	<cffunction name="$fileDelete" access="private" returntype="void" output="false">
		<cfargument name="path" type="string" required="true" />

		<cffile action="delete" file="#path#" />
	</cffunction>

	<cffunction name="$reSearch" access="private" returntype="struct" output="false" hint="I perform a Regex search and return a struct of arrays containing pattern match information. Each key represents the position of a match, i.e. $1, $2, etc. Each key contains an array of matches.">
		<cfargument name="regex" type="string" required="true" />
		<cfargument name="text"  type="string" required="true" />

		<cfscript>
			var finalStruct  = StructNew();
			var pos    = 1;
			var result = ReFindNoCase( regex, text, pos, true );
			var i      = 0;

			while( ArrayLen( result.pos ) GT 1 ) {
				for( i=2; i LTE ArrayLen( result.pos ); i++ ){
					if ( not StructKeyExists( finalStruct, '$#i-1#' ) ) {
						finalStruct[ '$#i-1#' ] = ArrayNew(1);
					}
					ArrayAppend( finalStruct[ '$#i-1#' ], Mid( text, result.pos[i], result.len[i] ) );
				}
				pos = result.pos[2] + 1;
				result	= ReFindNoCase( regex, text, pos, true );
			};

			return finalStruct;
		</cfscript>
	</cffunction>

	<cffunction name="$isUrl" access="private" returntype="boolean" output="false" hint="I return whether or not the passed string is a url (based on a very crude regex, do not use for any stringent url checking)">
		<cfargument name="stringToCheck" type="string" required="true" />

		<cfscript>
			var URLRegEx = "^(http|https)://.*"; // very rough, we don't care for any more precision
			return ReFindNoCase( URLRegEx, stringToCheck );
		</cfscript>
	</cffunction>

	<cffunction name="$httpGet" access="private" returntype="string" output="false" hint="I attempt to get and return the content of the passed url over http.">
		<cfargument name="urlToGet" type="string" required="true" />

		<cfhttp url="#urlToGet#" method="get" />
		<cfreturn cfhttp.filecontent />
	</cffunction>

	<cffunction name="$listDeleteLast" access="private" returntype="string" output="false" hint="I delete the last member of the passed string, returning the result of the deletion.">
		<cfargument name="list" type="string" required="true" />
		<cfargument name="delimiter" type="string" required="false" default="," />

		<cfscript>
			if ( not Len( list ) ) {
				return "";
			}
			return ListDeleteAt( list, ListLen( list, delimiter ), delimiter );
		</cfscript>
	</cffunction>

	<cffunction name="$listAppend" access="private" returntype="string" output="false" hint="I override listAppend, ensuring that, when a list already contains its delimiter at the end, a duplicate delimiter is not appended">
		<cfargument name="list"      type="string" required="true"              />
		<cfargument name="value"     type="string" required="true"              />
		<cfargument name="delimiter" type="string" required="false" default="," />

		<cfscript>
			var delimiterAlreadyOnEnd = Right( list, Len( delimiter ) ) eq delimiter;
			var isEmptyList           = not Len( list );

			if ( delimiterAlreadyOnEnd or isEmptyList ) {
				return list & value;
			}

			return list & delimiter & value;
		</cfscript>
	</cffunction>


	<cffunction name="$renderCssInclude" access="private" returntype="string" output="false" hint="I return the html necessary to include the given css file">
		<cfargument name="src"           type="string" required="true"                  />
		<cfargument name="media"         type="string" required="true"                  />
		<cfargument name="ieConditional" type="string" required="false" default=""      />

		<cfreturn $renderIeConditional( '<link rel="stylesheet" href="#src#" media="#media#" />', ieConditional ) & $newline() />
	</cffunction>

	<cffunction name="$renderJsInclude" access="private" returntype="string" output="false" hint="I return the html nevessary to include the given javascript file">
		<cfargument name="src"           type="string" required="true"                  />
		<cfargument name="ieConditional" type="string" required="false" default=""      />
		<cfargument name="async" 		 type="string" required="false" default="false" />
		<cfargument name="defer" 		 type="string" required="false" default="false" />

		<cfreturn $renderIeConditional( '<script type="text/javascript" src="#src#" #arguments.async EQ "true" ? "async" : ""# #arguments.defer EQ "true" ? "defer" : ""# ></script>', ieConditional ) & $newline() />
	</cffunction>

	<cffunction name="$extractUrlFromRenderedInclude" access="private" returntype="string" output="false">
		<cfargument name="renderedInclude" type="string" required="true" />

		<cfscript>
			var regex    = '^.*?(href|src)="(.*?)".*$';
			var replaced = ReReplaceNoCase( renderedInclude, regex, "\2" );

			if ( replaced == renderedInclude ) {
				return "";
			}

			return replaced;
		</cfscript>
	</cffunction>

	<cffunction name="$generateCacheBuster" access="private" returntype="string" output="false" hint="I return a cachebuster string for a given date">
		<cfargument name="dateLastModified" type="date" required="false" default="#Now()#" />

		<cfreturn DateFormat( dateLastModified, 'yyyymmdd' ) & TimeFormat( dateLastModified, 'hhmmss' ) />
	</cffunction>

	<cffunction name="$renderIeConditional" access="private" returntype="string" output="false" hint="I wrap an html include string with IE conditional statements when necessary, returning the result">
		<cfargument name="include"       type="string" required="true" />
		<cfargument name="ieConditional" type="string" required="true" />

		<cfif Trim( ieConditional ) eq "!IE">
			<cfreturn '<!--[if #ieConditional#]>-->
#include#
<!-- <![endif]-->' />
		<cfelseif Len( Trim( ieConditional ) )>
			<cfreturn '<!--[if #ieConditional#]>#include#<![endif]-->' />
		</cfif>

		<cfreturn include />
	</cffunction>

	<cffunction name="$loadJavaClass" access="private" returntype="any" output="false" hint="I isntanciate and return a java object">
		<cfargument name="className" type="string" required="true" />

		<cfreturn _getJavaLoader().create( className ) />
	</cffunction>

	<cffunction name="$arrayMerge" access="private" returntype="array" output="false" hint="I add all the elemnts of one array to another, returning the result">
		<cfargument name="arr1" type="array" required="true" />
		<cfargument name="arr2" type="array" required="true" />

		<cfscript>
			var i = 0;

			for( i=1; i LTE ArrayLen(arr2); i++ ){
				ArrayAppend( arr1, arr2[i] );
			}

			return arr1;
		</cfscript>
	</cffunction>

	<cffunction name="$normalizeUnixAndWindowsPaths" access="private" returntype="string" output="false">
		<cfargument name="path" type="string" required="true" />

		<cfreturn Replace( path, '\', '/', 'all' ) />
	</cffunction>

	<cffunction name="$shouldFileBeIncluded" access="private" returntype="boolean" output="false">
		<cfargument name="filePath"       type="string" required="true" />
		<cfargument name="includePattern" type="string" required="true" />
		<cfargument name="excludePattern" type="string" required="true" />

		<cfscript>
			filepath = $normalizeUnixAndWindowsPaths(filepath);

			if ( $isTemporaryFileName( filePath ) ) {
				return false;
			}

			if ( Len( Trim( includePattern ) ) AND NOT ReFindNoCase( includePattern, filePath ) ) {
				return false;
			}

			if ( Len( Trim( excludePattern ) ) AND ReFindNoCase( excludePattern, filePath ) ) {
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
			var basePathArray     = ListToArray( GetDirectoryFromPath( basePath ), "\/" );
			var relativePathArray = ListToArray( relativePath, "\/" );
			var finalPath         = ArrayNew(1);
			var pathStart         = 0;
			var i                 = 0;

			/* Define the starting path (path in common) */
			for ( i=1; i LTE ArrayLen( basePathArray ); i=i+1 ) {
				if ( basePathArray[i] NEQ relativePathArray[i] ) {
					pathStart = i;
					break;
				}
			}

			if ( pathStart EQ 0 ) {
				ArrayAppend( finalPath, "." );
				pathStart = ArrayLen( basePathArray );
			}

			/* Build the prefix for the relative path (../../etc.) */
			for ( i=ArrayLen( basePathArray ) - pathStart; i GTE 0; i=i-1 ) {
				if ( ArrayLen( finalPath ) and finalPath[1] eq "." ) {
					ArrayDeleteAt( finalPath, 1 );
				}
				ArrayAppend( finalPath, ".." );
			}

			/* Build the relative path */
			for ( i=pathStart; i LTE ArrayLen(relativePathArray); i=i+1 ) {
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

			for( i=1; i LTE ListLen(list); i++ ){
				listStruct[ ListGetAt(list, i) ] = 0;
			}

			return StructKeyList( listStruct );
		</cfscript>
	</cffunction>

	<cffunction name="$ensureFullDirectoryPath" access="private" returntype="string" output="false">
		<cfargument name="dir" type="string" required="true" />
		<cfscript>
			if ( directoryExists( ExpandPath( dir ) ) ) {
				return ExpandPath( dir );
			}
			return dir;
		</cfscript>
	</cffunction>

	<cffunction name="$ensureFullFilePath" access="private" returntype="string" output="false">
		<cfargument name="file" type="string" required="true" />

		<cfscript>
			if ( fileExists( ExpandPath( file ) ) ) {
				return ExpandPath( file );
			}
			return file;
		</cfscript>
	</cffunction>

	<cffunction name="$getStringBuffer" access="private" returntype="any" output="false">
		<cfreturn CreateObject("java","java.lang.StringBuffer") />
	</cffunction>

	<cffunction name="$appendCompiledFileTypeToFilePath" access="private" returntype="string" output="false">
		<cfargument name="filePath" type="string" required="true" />

		<cfscript>
			switch( ListLast( filePath, "." ) ){
				case "coffee" : return filePath & ".js";
				case "less"   : return filePath & ".css";
				default       : return filePath;
			}
		</cfscript>
	</cffunction>

	<cffunction name="$createTemporaryFilename" access="private" returntype="string" output="false">
		<cfargument name="extension" type="string" required="true" />

		<cfreturn ".tmp." & Hash( CreateUUId() ) & "." & LCase( extension ) />
	</cffunction>

	<cffunction name="$isTemporaryFileName" access="private" returntype="boolean" output="false">
		<cfargument name="filePath"  type="string" required="true" />

		<cfreturn ReFind( "/\.tmp\.[0-9A-F]{32}\.[a-z0-9]+$", filePath ) />
	</cffunction>

<!--- accessors --->
	<cffunction name="_setJavaLoader" access="private" returntype="void" output="false">
		<cfargument name="javaLoader" required="true" type="any" />

		<cfset _javaLoader = javaLoader />
	</cffunction>
	<cffunction name="_getJavaLoader" access="private" returntype="any" output="false">
		<cfreturn _javaLoader />
	</cffunction>

</cfcomponent>