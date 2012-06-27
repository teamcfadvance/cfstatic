<cfcomponent hint="utilities for comparing datatypes (queries, structs)" output="false">


	<cffunction name="compareQueries" access="public" output="false" returntype="struct" description="compares 2 queries, cell by cell, and fails if differences exist">
    	<cfargument name="query1" type="query" required="true"/>
    	<cfargument name="query2" type="query" required="true"/>

		<cfscript>
			var columnName = "";
			var row = 1;
			var col = 1;
			var query1RecordCount = query1.RecordCount;
			var query2RecordCount = query2.RecordCount;
			var columnNames = listToArray(query1.ColumnList);
			var numCols = arrayLen(columnNames);
			var query1ColumnValue = ""; var query2ColumnValue = "";
			var query1ColumnList = listSort(query1.ColumnList, "textnocase", "asc");
			var query2ColumnList = listSort(query2.ColumnList, "textnocase", "asc");
			var rowsToDelete = "";
			var mismatches = structNew();

			mismatches.message = "";
			mismatches.success = true;
			mismatches.ColumnListsMatch = query1ColumnList eq query2ColumnList;
			mismatches.RecordCountsMatch = query1RecordCount eq query2RecordCount;
			mismatches.QueryIsComparable = mismatches.ColumnListsMatch;
			mismatches.Query1MismatchValues = "";
			mismatches.Query2MismatchValues = "";

			if( NOT mismatches.ColumnListsMatch ){
				mismatches.message = "Column lists do not match. ";
				mismatches.success = false;
				return mistmatches;
			}

			for( row = 1; row LTE query1RecordCount; row=row+1 ){
				for( col = 1; col LTE numCols; col=col+1 ){
					columnName = columnNames[col];
					query1ColumnValue = query1[columnName][row];
					if( row LTE query2RecordCount ){
						query2ColumnValue = query2[columnName][row];
					} else {
						mismatches.success = false;
						query2ColumnValue = "";
					}

					if( query1ColumnValue NEQ query2ColumnValue ){
						if( NOT structKeyExists( mismatches, "row #row#" ) ){
							mismatches["row #row#"] = structNew();
						}
						mismatches.success = false;
						mismatches.message = "Data mismatch. ";
						mismatches["row #row#"]["column #columnName#"] = structNew();
						mismatches["row #row#"]["column #columnName#"].query1Value = query1ColumnValue;
						mismatches["row #row#"]["column #columnName#"].actual = query2ColumnValue;
						mismatches.Query1MismatchValues = listAppend( mismatches.Query1MismatchValues, "row #row# column #columnName#: #query1ColumnValue#", "#chr(10)#" );
						mismatches.Query2MismatchValues = listAppend( mismatches.Query2MismatchValues, "row #row# column #columnName#: #query2ColumnValue#", "#chr(10)#" );
					}
				}
			}
			//now get all rows that exist in the second query but not the first
			if( query2RecordCount GT query1RecordCount ){
				mismatches.success = false;
				mismatches.message = mismatches.message & "Query 2 was longer than query 1. ";
				for( row=1; row LTE query1RecordCount; row=row+1 ){
					rowsToDelete = listAppend( rowsToDelete, row );
				}
				mismatches.Query2AdditionalRows = QueryDeleteRows( query2, rowsToDelete );
				mismatches.Query2MismatchValues = listAppend( mismatches.Query2MismatchValues, "Query2 had #mismatches.Query2AdditionalRows.RecordCount# additional row(s)", "#chr(10)#" );

			}
			return mismatches;
        </cfscript>
    </cffunction>

	<cffunction name="compareStructs" output="false" access="public" returntype="any" hint="compares two structures, key by key, and fails if differences exist">
		<cfargument name="struct1" type="struct" required="true"/>
		<cfargument name="struct2" type="struct" required="true"/>

		<cfargument name="path" type="string" required="false" intent="private" default="" hint="don't touch this, sucker"/>

		<cfscript>
			var key = "";
			var struct1Value = "";
			var struct2Value = "";
			var queryCompareResult = "";
			var structCompareResult = "";
			var arrayCompareResult = "";
			var thisPath = arguments.path;
			var mismatches = structNew();

			mismatches.message = "";
			mismatches.success = true;
			mismatches.UniqueToStruct1 = listCompare( structKeyList(struct1), structKeyList(struct2) );
			mismatches.UniqueToStruct2 = listCompare( structKeyList(struct2), structKeyList(struct1) );
			mismatches.mismatches = structNew();
			mismatches.Struct1MismatchValues = "";
			mismatches.Struct2MismatchValues = "";

			if( mismatches.UniqueToStruct1 & mismatches.UniqueToStruct2 neq "" ){
				mismatches.success = false;
				mismatches.message = "Keys do not match. ";
				mismatches.Struct1MismatchValues = listAppend( mismatches.Struct1MismatchValues, "Keys unique to Struct 1: #mismatches.UniqueToStruct1#", "#chr(10)#");
				mismatches.Struct2MismatchValues = listAppend( mismatches.Struct2MismatchValues, "Keys unique to Struct 2: #mismatches.UniqueToStruct2#", "#chr(10)#");
			}

			//only compare keys that exist in both structs; the check above will flag the compare as a failure if the key lists do not match
			for( key in struct1 ){
				if( structKeyExists( struct2, key )){

					thisPath = thisPath & "[ ""#key#"" ]";
					struct1Value = struct1[key];
					struct2Value = struct2[key];

					if( isSimpleValue( struct1Value ) AND isSimpleValue( struct2Value ) ){
						if( struct1Value neq struct2Value ){
							mismatches.success = false;
							mismatches.mismatches[thisPath] = structNew();
							mismatches.mismatches[thisPath].Struct1Value = struct1Value;
							mismatches.mismatches[thisPath].Struct2Value = struct2Value;
							mismatches.Struct1MismatchValues = listAppend( mismatches.Struct1MismatchValues, "Structure path #thisPath#: #struct1Value#", "#chr(10)#" );
							mismatches.Struct2MismatchValues = listAppend( mismatches.Struct2MismatchValues, "Structure path #thisPath#: #struct2Value#", "#chr(10)#" );
						}
					} else if( isQuery( struct1Value ) AND isQuery( struct2Value ) ){
						queryCompareResult = compareQueries( struct1Value, struct2Value );
						if( NOT queryCompareResult.success ){
							mismatches.success = false;
							mismatches.mismatches[thisPath] = queryCompareResult;
							mismatches.Struct1MismatchValues = listAppend( mismatches.Struct1MismatchValues, "Structure path #thisPath#, Query Compare Result: #queryCompareResult.Query1MismatchValues#", "#chr(10)#" );
							mismatches.Struct2MismatchValues = listAppend( mismatches.Struct2MismatchValues, "Structure path #thisPath#, Query Compare Result: #queryCompareResult.Query2MismatchValues#", "#chr(10)#" );
						}
					} else if( isStruct( struct1Value ) AND isStruct( struct2Value ) ){
						structCompareResult = compareStructs( struct1Value, struct2Value, thisPath );
						if( NOT structCompareResult.success ){
							mismatches.success = false;
							mismatches.mismatches[thisPath] = structCompareResult;
							mismatches.Struct1MismatchValues = listAppend( mismatches.Struct1MismatchValues, "#structCompareResult.Struct1MismatchValues#", "#chr(10)#" );
							mismatches.Struct2MismatchValues = listAppend( mismatches.Struct2MismatchValues, "#structCompareResult.Struct2MismatchValues#", "#chr(10)#" );
						}
					} else if ( isArray( struct1Value ) AND isArray( struct2Value ) ) {
						arrayCompareResult = compareArrays( struct1Value, struct2Value );
						if( NOT arrayCompareResult.success ){
							mismatches.success = false;
							mismatches.mismatches[thisPath] = arrayCompareResult;
							mismatches.Struct1MismatchValues = listAppend( mismatches.Struct1MismatchValues, "#arrayCompareResult.Array1MismatchValues#", "#chr(10)#" );
							mismatches.Struct2MismatchValues = listAppend( mismatches.Struct2MismatchValues, "#arrayCompareResult.Array2MismatchValues#", "#chr(10)#" );
						}
					} else {
						mismatches.message = "Not sure how to compare these datatypes at path #thisPath#. File a bug with a patch. ";
						mismatches.success = false;
					}

					thisPath = arguments.path;
				}
			}
			return mismatches;
        </cfscript>
	</cffunction>

	<cffunction name="compareArrays" output="false" access="public" returntype="any" hint="">
    	<cfargument name="array1" type="array" required="true"/>
    	<cfargument name="array2" type="array" required="true"/>

		<cfscript>
			var row = 1;
			var array1Len = arrayLen(array1);
			var array2Len = arrayLen(array2);
			var array1Value = ""; var array2Value = "";
			var mismatches = structNew();
			var loopTotal = min( array1Len, array2Len );

			var queryCompareResult = ""; var structCompareResult = ""; var arrayCompareResult = "";

			mismatches.message = "";
			mismatches.success = true;
			mismatches.LengthsMatch = array1Len eq array2Len;
			mismatches.Array1MismatchValues = "";
			mismatches.Array2MismatchValues = "";

			for( row = 1; row LTE loopTotal; row=row+1 ){

				array1Value = array1[row];
				array2Value = array2[row];
				if( isSimpleValue( array1Value ) AND isSimpleValue( array2Value ) ){
					if( array1Value NEQ array2Value ){
						mismatches["row #row#"] = structNew();

						mismatches.success = false;
						mismatches.message = "Data mismatch. ";
						mismatches["row #row#"].array1Value = array1Value;
						mismatches["row #row#"].array2Value = array2Value;
						mismatches.Array1MismatchValues = listAppend( mismatches.Array1MismatchValues, "row #row#: #array1Value#", "#chr(10)#" );
						mismatches.Array2MismatchValues = listAppend( mismatches.Array2MismatchValues, "row #row#: #array2Value#", "#chr(10)#" );
					}
				} else if ( isQuery( array1Value ) AND isQuery( array2Value ) ){
					queryCompareResult = compareQueries( array1Value, array2Value );
					if( NOT queryCompareResult.success ){
						mismatches.success = false;
						mismatches["row #row#"] = queryCompareResult;
						mismatches.Array1MismatchValues = listAppend( mismatches.Array1MismatchValues, "Row #row#, Query Compare Result: #queryCompareResult.Query1MismatchValues#", "#chr(10)#" );
						mismatches.Array2MismatchValues = listAppend( mismatches.Array2MismatchValues, "Row #row#, Query Compare Result: #queryCompareResult.Query2MismatchValues#", "#chr(10)#" );
					}
				} else if ( isStruct( array1Value ) AND isStruct( array2Value ) ){
					structCompareResult = compareStructs( array1Value, array2Value );
					if( NOT structCompareResult.success ){
						mismatches.success = false;
						mismatches["row #row#"] = structCompareResult;
						mismatches.Array1MismatchValues = listAppend( mismatches.Array1MismatchValues, "Row #row#, Struct Compare Result: #structCompareResult.Struct1MismatchValues#", "#chr(10)#" );
						mismatches.Array2MismatchValues = listAppend( mismatches.Array2MismatchValues, "Row #row#, Struct Compare Result: #structCompareResult.Struct2MismatchValues#", "#chr(10)#" );
					}
				} else if ( isArray(array1Value) AND isArray(array2Value) ){
					arrayCompareResult = compareArrays( array1Value, array2Value );
					if( NOT arrayCompareResult.success ){
						mismatches.success = false;
						mismatches["row #row#"] = arrayCompareResult;
						mismatches.Array1MismatchValues = listAppend( mismatches.Array1MismatchValues, "Row #row#, Array Compare Result: #arrayCompareResult.Array1MismatchValues#", "#chr(10)#" );
						mismatches.Array2MismatchValues = listAppend( mismatches.Array2MismatchValues, "Row #row#, Array Compare Result: #arrayCompareResult.Array2MismatchValues#", "#chr(10)#" );
					}
				} else {
					mismatches.message = "Not sure how to compare these datatypes at row #row#. File a bug with a patch. ";
					mismatches.success = false;
				}

			}

			if( array1Len GT array2Len ){
				mismatches.success = false;
				mismatches.message = mismatches.message & " Array 1 was longer than array 2. ";
				mismatches.Array1AdditionalRows = array1.sublist( array2Len, array1Len );
				mismatches.Array1MismatchValues = listAppend( mismatches.Array1MismatchValues, "Array 1 had #Array1Len-Array2Len# additional row(s)", "#chr(10)#" );
			}

			if( array2Len GT array1Len ){
				mismatches.success = false;
				mismatches.message = mismatches.message & " Array 2 was longer than array 1. ";
				mismatches.Array2AdditionalRows = array2.sublist( array1Len, array2Len );//TODO: TEST THIS!!!
				mismatches.Array2MismatchValues = listAppend( mismatches.Array2MismatchValues, "Array 2 had #Array2Len-Array1Len# additional row(s)", "#chr(10)#" );
			}

			return mismatches;
        </cfscript>

    </cffunction>



	<cfscript>
	/**
		THANKS RAY

	 * Removes rows from a query.
	 * Added var col = "";
	 * No longer using Evaluate. Function is MUCH smaller now.
	 *
	 * @param Query      Query to be modified
	 * @param Rows      Either a number or a list of numbers
	 * @return This function returns a query.
	 * @author Raymond Camden (ray@camdenfamily.com)
	 * @version 2, October 11, 2001
	 */
	function QueryDeleteRows(Query,Rows) {
	    var tmp = QueryNew(Query.ColumnList);
	    var i = 1;
	    var x = 1;

	    for(i=1;i lte Query.recordCount; i=i+1) {
	        if(not ListFind(Rows,i)) {
	            QueryAddRow(tmp,1);
	            for(x=1;x lte ListLen(tmp.ColumnList);x=x+1) {
	                QuerySetCell(tmp, ListGetAt(tmp.ColumnList,x), query[ListGetAt(tmp.ColumnList,x)][i]);
	            }
	        }
	    }
	    return tmp;
	}
	</cfscript>

	<!---
	THANKS ROB
	 Compares one list against another to find the elements in the first list that don't exist in the second list.
	 v2 mod by Scott Coldwell

	 @param List1      Full list of delimited values. (Required)
	 @param List2      Delimited list of values you want to compare to List1. (Required)
	 @param Delim1      Delimiter used for List1.  Default is the comma. (Optional)
	 @param Delim2      Delimiter used for List2.  Default is the comma. (Optional)
	 @param Delim3      Delimiter to use for the list returned by the function.  Default is the comma. (Optional)
	 @return Returns a delimited list of values.
	 @author Rob Brooks-Bilson (rbils@amkor.com)
	 @version 2, June 25, 2009
	--->
	<cffunction name="listCompare" output="false" returnType="string">
	       <cfargument name="list1" type="string" required="true" />
	       <cfargument name="list2" type="string" required="true" />
	       <cfargument name="delim1" type="string" required="false" default="," />
	       <cfargument name="delim2" type="string" required="false" default="," />
	       <cfargument name="delim3" type="string" required="false" default="," />

	       <cfset var list1Array = ListToArray(lCase(arguments.List1),Delim1) />
	       <cfset var list2Array = ListToArray(lcase(arguments.List2),Delim2) />

	       <!--- Remove the subset List2 from List1 to get the diff --->
	       <cfset list1Array.removeAll(list2Array) />

	       <!--- Return in list format --->
	       <cfreturn ArrayToList(list1Array, Delim3) />
	</cffunction>

</cfcomponent>