<cfcomponent hint="simple utility for creating query from a CSV file. This is meant as a testing utility, not as a bullet-proof component for production code">

	<cffunction name="readCSV" access="public" returntype="struct" output="false" hint="converts a CSV File into a Query">
		<cfargument name="filePath" required="true" type="string" hint="full path to file">
		<cfargument name="hasHeaderRow" required="false" type="boolean" default="false" hint="whether the first row is a header row. If so, the values in the first row will be used as column names; otherwise, columns will be derived">
		<cfargument name="rowDelimiter" required="false" type="string" default="#chr(10)#" hint="string used to delimit rows. chr(10) is default">
		<cfargument name="columnDelimiter" required="false" type="string" default="," hint="string used to delimit columns; ',' is default">
		<cfset var q = "">
		<cfset var result = StructNew()>
		<cfset var contents = ""><cfset var firstRow = ""><cfset var rowCount = ""><cfset var rowIndex = 1><cfset var startRow = 1>
		<cfset var thisRowContent = ""><cfset var colIndex = 1>
		<cffile action="read" file="#filePath#" variable="contents">
		<cfset firstRow = listFirst(contents,rowDelimiter)>
		<cfset firstRow = getColumnList(firstRow,hasHeaderRow,columnDelimiter)>
		<cfset result.ColumnNames = ListToArray(firstRow)>
		<cfset q = QueryNew(firstRow)>
		<cfif hasHeaderRow>
			<cfset startRow = 2>
		</cfif>
		<cfloop from="#startRow#" to="#ListLen(contents,rowDelimiter)#" index="rowIndex">
			<cfset thisRowContent = listGetAt(contents,rowIndex,rowDelimiter)>
			<cfset queryAddRow(q)>
			<cfloop from="1" to="#ListLen(thisRowContent,columnDelimiter)#" index="colIndex">
				<cfset querySetCell(q,listGetAt(firstRow,colIndex), listGetAt(thisRowContent,colIndex,columnDelimiter).trim() )>
			</cfloop>
		</cfloop>
		<cfset result.Query = q>
		<cfreturn result>
	</cffunction>
	
	<cffunction name="readCSVToArray" output="false" access="public" returntype="array" hint="returns a 2D array of data">
		<cfargument name="filePath" required="true" type="string" hint="full path to file">
		<cfargument name="hasHeaderRow" required="false" type="boolean" default="false" hint="whether the first row is a header row. If so, the values in the first row will be used as column names; otherwise, columns will be derived">
		<cfargument name="rowDelimiter" required="false" type="string" default="#chr(10)#" hint="string used to delimit rows. chr(10) is default">
		<cfargument name="columnDelimiter" required="false" type="string" default="," hint="string used to delimit columns; ',' is default">
		<cfscript>
		var result = readCSV(filePath=arguments.filePath, hasHeaderRow=arguments.hasHeaderRow,rowDelimiter=arguments.rowDelimiter,columnDelimiter=arguments.columnDelimiter);
		var q = result.query; var cols = result.columnNames;
		var col = ""; var row = ""; var a = ArrayNew(2);
		for(row=1; row LTE q.RecordCount; row=row+1){
			for(col=1; col LTE ArrayLen(cols); col=col+1){
				a[row][col] = q[ cols[col] ][row];
			}			
		}
		return a;
		</cfscript>
	</cffunction>

	<cffunction name="getColumnList" access="private" returntype="string">
		<cfargument name="csvRow" type="string" required="true">
		<cfargument name="isHeaderRow" required="true">
		<cfargument name="columnDelimiter" required="true">
		<cfset var cols = ""><cfset var col = "">
		<cfset csvRow = listChangeDelims(csvRow,",",columnDelimiter)>
		<cfif isHeaderRow>
			<cfreturn csvRow.trim()>
		</cfif>
		<cfloop from="1" to="#ListLen(csvRow)#" index="col">
			<cfset cols = listAppend(cols,"Column#col#")>
		</cfloop>
		<cfreturn cols>
	</cffunction>
</cfcomponent>