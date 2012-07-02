<cfcomponent hint="Assertions for XML and well formed HTML" output="false" extends="Assert">


 <cffunction name="assertXpath" access="public" returntype="any">
   <cfargument name="xpath" type="String" hint="string representing an
xpath expression" required="true" />
   <cfargument name="data" hint="String or URL to search" required="true"
type="any"  />
   <!--- To Do: Maybe TEXT can also accepts regular expressions? --->
   <cfargument name="text" type="string" required="false" default=""
hint="The text to match against the xpath expression. If omitted, this
assertion returns true if any elements of the xpath epxression are found." />
   <cfargument name="message" type="string" required="false" hint="The
mssage to display when this assertion fails" default="The XPath expression,
#arguments.xpath#, did not match the data." />
   <cfset var dom = "" />
   <cfset var isUrl= "" />
   <cfset var results = "" />

      <cftry>
       <!---
        Note:
        SSL Not supported. Workaround is to use another http client
        and pass in a string.

        To Do: allow pass in of org.xml.sax.InputSource
       --->

       <cfset isUrl = refindNoCase("^(http[s]*|file)://.+",data)>
       <cfif isXMLDoc(arguments.data)>
               <cfset dom = arguments.data />
       <cfelse>
               <cfset dom = buildXmlDom(arguments.data,isUrl) />
       </cfif>
	
       <cfset results = xmlSearch(dom,arguments.xpath)>
       <cfif len(arguments.text) gt 0>
         <cfset assertEquals(arguments.text, results[1].xmlText, message) />
       </cfif>
       <cfif arrayLen(results) lt 1>
         <cfset fail(message) />
       </cfif>
	
       <cfreturn results />
      <cfcatch type="any">
       <cfthrow object="#cfcatch#">
      </cfcatch>
     </cftry>
 </cffunction>


   <cffunction name="buildXmlDom" access="public" static="true" returntype="any" hint="Experimental!">
    <cfargument name="data" type="any" required="true" hint="A string that needs to be parsed into an XML DOM Object.">
    <cfargument name="isUrl" type="boolean" required="false" default="false" hint="Flag that determines whether or not the data argument is a URL as opposed to a string.">
    <cfscript>
     var root =  componentUtils.getComponentRoot();
     var dom = xmlNew();
     var paths = arrayNew(1);
     var loader = "";
     var bais = "";
     var doc = "" ;
     var builder = "";
     var readBuffer = "";
     var soup = "";
     paths[1] = expandPath("/#root#/framework/lib/tagsoup-1.2.jar");
     paths[2] = expandPath("/#root#/framework/lib/xom-1.2.6.jar");
     loader = createObject("component", "/#root#/framework/javaloader/JavaLoader").init(paths);
     soup = loader.create("org.ccil.cowan.tagsoup.Parser").init();
     soup.setFeature("http://xml.org/sax/features/namespace-prefixes", false);
     soup.setFeature("http://xml.org/sax/features/namespaces", false);
     
     doc = loader.create("nu.xom.Document");
     builder = loader.create("nu.xom.Builder").init(soup);

     if(not isUrl){
       readBuffer = CreateObject("java","java.lang.String").init(data).getBytes();
       bais = createobject("java","java.io.ByteArrayInputStream").init(readBuffer);
       doc = builder.build(bais);
     } else {
       doc = builder.build(data); //load the doc from the url. Nice!
     }
     
     // Removing the xmlns since xmlSearch is not liking it being there
     dom = xmlParse(replace(doc.toXml(), ' xmlns="http://www.w3.org/1999/xhtml"', ''));
     
     return dom;
    </cfscript>
  </cffunction>


  <!---
   This was needed because JTidy did not handle script tag well.
   It's left here as a regex reference.
   --->
  <cffunction name="wrapScriptTagInCDATA" returnType="string" hint="Regular Expression util wrapper. Wraps script tag in CDATA section for xml parsing.">
    <cfargument name="html" type="string" required="true" hint="Wraps the internal contents of script tags with a CDATA section. Workaround for JTidy lack." />
    <cfset var sregx = "(<script\b[^>]*>)(.*?)(</script>)" />
    <cfset var retVal = rereplaceNoCase(arguments.html,sregx,"\1//<![CDATA[ \2 // ]]> \3","all") />
    <cfreturn retVal />
  </cffunction>

   <cffunction name="isWrapped" returnType="boolean">
    <cfargument name="html" type="string" required="true" hint="Wraps the internal contents of script tags with a CDATA section. Workaround for JTidy lack." />
    <cfset var sregx = "(<script\b[^>]*>)(.*?<!\[CDATA.*?)(\]\]>.*?</script>)" />
    <cfset var retVal = refindNoCase(sregx,arguments.html) />
    <cfreturn retVal gt 0 />
  </cffunction>


</cfcomponent>
