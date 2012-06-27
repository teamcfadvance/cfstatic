<cfcomponent output="false" name="BubbleSort" >
	<cffunction name="SortArrayOfStructs" returntype="Array" access="public" output="false" hint="I sort an array of structs" >
		<cfargument name="theArray" type="Array" required="true"  />
		<cfargument name="theKey" type="String" required="true"  />
		<cfargument name="isNumber" type="Boolean" required="false" default="false" />
		<cfscript>
			var temp = "";
			var sorted = true;
			var i = 1;
			var x = 1;
			var len = arrayLen(theArray);
			var value1 = "";
			var value2 = ""; 

			for(i = 1; i lte len; i = i + 1){

				sorted = true;

				for(x = 1; x lte len - 1; x = x + 1){

					if(isNumber){
						if(isNumeric(theArray[x + 1][theKey])){
							value1 = lsParseNumber(theArray[x + 1][theKey]);
						}
						else{
							value1 = 9999;
						}
						
						if(isNumeric(theArray[x][theKey])){
							value2 =  lsParseNumber(theArray[x][theKey]);
						}
						else{
							value2 = 9999;
						}
					}
					else{
						value1 = theArray[x + 1][theKey];
						value2 - theArray[x][theKey];
					}

					if(value1 lt value2){

						temp = theArray[x];
						theArray[x] = theArray[x + 1];
						theArray[x + 1] =  temp;

						sorted = false;
					}
				}

				if(sorted){
					break;
				}
			}

			return theArray;
		</cfscript>
	</cffunction>
</cfcomponent>