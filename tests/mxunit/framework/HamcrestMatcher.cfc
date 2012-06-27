<cfcomponent diaplyname="HamcrestMatcher" hint="Generates Matcher Objects used by the HamcrestAssert component. R/D ... do not use in production" output="false">
	<cfparam name="this.description" type="string" default="" />
	<cfparam name="this.stringRepresentation" type="string" default="" />
	<cfparam name="this.numericRepresentation" type="numeric" default="0" />
  <cfparam name="this.matcherName" type="string" default="" />
  <!--- <cfparam name="" type="" default="" /> --->
<!---
Constructor not wanted as this component and methods we want to be as 
static as possible. How can we do this in CF?
 --->
<cffunction name="describeTo" access="public">
  <cfargument name="description" type="string" required="true">
  <cfset this.description = arguments.description />
</cffunction>
<cffunction name="representTo" access="public" returnTYpe="void">
  <cfargument name="subject" type="any" required="true">
  <cfset this.stringRepresentation = toString(subject) />
  <!--- <cfreturn this.stringRepresentation > --->
</cffunction>

<cffunction name="getDescription" access="public" returnType="string">
  <cfreturn this.description />
</cffunction>

<cffunction name="isEqualTo" output="true" access="public" returntype="any" static="true">
  <cfargument name="subject" type="any" required="true" hint="The subject of the matcher." />
  <cfset this.describeTo(" is not equal to ") />
  <!--- 
   Use the getStringValue from Assert. Since this matcher is added 
   by the decorator mechanism we can do this. But what are the
   design implications? Cohesion vs. Coupling ...
   --->
  <cfset this.representTo(getStringValue(subject)) />
  <cfreturn this /><!--- Return the entire matcher --->
</cffunction>

<cffunction name="containsTheString" output="true" access="public" returntype="any" static="true">
  <cfargument name="subject" type="any" required="true" hint="The subject of the matcher." />
  <cfset this.describeTo(" does not contain the string ") />
  <!--- 
   Use the getStringValue from Assert. Since this matcher is added 
   by the decorator mechanism we can do this. But what are the
   design implications? Cohesion vs. Coupling ...
   --->
  <cfset this.representTo(getStringValue(subject)) />
  <cfreturn this /><!--- Return the entire matcher --->
</cffunction>

  
  <!---  
    Core 
		to do: anything - always matches, useful if you don't care what the object under test is 
		to do: describedAs - decorator to adding custom failure description 
		to do: is - decorator to improve readability - see "Sugar", below 
		Logical 
		to do: allOf - matches if all matchers match, short circuits (like Java &&) 
		to do: anyOf - matches if any matchers match, short circuits (like Java ||) 
		to do: not - matches if the wrapped matcher doesn't match and vice versa 
		Object 
		ok: equalTo - test object equality using Object.equals 
		to do: hasToString - test Object.toString 
		to do: instanceOf, isCompatibleType - test type 
		to do: notNullValue, nullValue - test for null 
		to do: sameInstance - test object identity 
		Beans 
		to do: hasProperty - test JavaBeans properties 
		Collections 
		to do: array - test an array's elements against an array of matchers 
		to do: hasEntry, hasKey, hasValue - test a map contains an entry, key or value 
		to do: hasItem, hasItems - test a collection contains elements 
		to do: hasItemInArray - test an array contains an element 
		Number 
		to do: closeTo - test floating point values are close to a given value 
		to do: greaterThan, greaterThanOrEqualTo, lessThan, lessThanOrEqualTo - test ordering 
		Text 
		to do: equalToIgnoringCase - test string equality ignoring case 
		to do: equalToIgnoringWhiteSpace - test string equality ignoring differences in runs of whitespace 
		to do: containsString, endsWith, startsWith - test string matching 
   --->


</cfcomponent>