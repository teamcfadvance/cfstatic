<cfcomponent output="false" extends="org.cfstatic.util.Base" hint="I provide an api for taking css and replacing its relative image paths with full image paths complete with cache busters based on the images last modified date">

<!--- constructor --->
	<cffunction name="init" access="public" returntype="any" output="false" hint="I am the constructor of the parser. I take the base path and url of the css files, used to calculate full paths from relative paths.">
    	<cfargument name="baseCssUrl" type="string" required="true" />
		<cfargument name="baseCssPath" type="string" required="true" />

    	<cfscript>
    		_setBaseCssUrl( baseCssUrl );
    		_setBaseCssPath( baseCssPath );

    		return this;
    	</cfscript>
    </cffunction>

<!--- public methods --->
	<cffunction name="parse" access="public" returntype="string" output="false" hint="I take a css input string (and path to the css file) and return css with full image paths and cachebusters">
		<cfargument name="source"           type="string"  required="true" />
		<cfargument name="filePath"         type="string"  required="true" />
		<cfargument name="embedImagesRegex" type="string"  required="true" />
		<cfargument name="addCachebusters"  type="boolean" required="true" />

		<cfscript>
			var originalCss     = source;
			var finalCss        = originalCss;
			var imageReferences = $reSearch('url\((.+?)\)', originalCss);
			var img             = "";
			var i               = 0;
			var fullUrl         = "";
			var base64Encoded   = "";
			var imageMimeType   = "";

			if ( StructKeyExists( imageReferences, '$1') and ArrayLen( imageReferences.$1 ) ) {
				imageReferences = imageReferences.$1;

				for( i=1; i LTE ArrayLen( imageReferences ); i++ ) {
					// remove quotes around url() image paths (there's probably a neater regex way to do it but hey)
					img = Replace(Replace( imageReferences[i], '"', '', 'all'), "'", "", "all" );

					if ( embedImagesRegex EQ 'all' or ( embedImagesRegex NEQ 'none' and ReFindNoCase( embedImagesRegex, img ) ) ) {
						base64Encoded = _calculateBase64String( img, filePath );
						imageMimeType = _calculateMimeType( img );
						finalCss      = Replace( finalCss, 'url(#imageReferences[i]#)', 'url(data:#imageMimeType#;base64,#base64Encoded#)', 'all' );

					} else {
						fullUrl  = _calculateFullUrl( img, filePath, addCachebusters );
						finalCss = Replace( finalCss, 'url(#imageReferences[i]#)', 'url(#fullUrl#)', 'all' );
					}
				}
			}

			return finalCss;
		</cfscript>
    </cffunction>

<!--- private methods --->
	<cffunction name="_calculateFullUrl" access="public" returntype="string" output="false" hint="I calculate the full path from a relative image path, appending a cachebuster based on the last modified date of the image file">
		<cfargument name="relativeUrl"     type="string"  required="true" />
		<cfargument name="cssFilePath"     type="string"  required="true" />
		<cfargument name="addCachebusters" type="boolean" required="true" />

		<cfscript>
			var fullUrl           = relativeUrl;
			var lastModified      = "";
			var cssFileUrl        = "";
			var found             = true;
			var nTraversals       = 0;
			var imagePath         = "";
			var imageLastModified = "";
			var cacheBuster       = "";
			var i                 = 0;

			// ignore non relative paths
			if ( Left( relativeUrl, 1 ) NEQ '/' AND NOT ReFindNoCase( '^(http|https)://', relativeUrl ) AND NOT ReFindNoCase( '^data:.*?;base64,', relativeUrl ) ) {
				cssFileUrl = _getBaseCssUrl() & Replace( GetDirectoryFromPath( cssFilePath ), _getBaseCssPath(), '' );

				// figure out how to traverse the url
				while( found ){
					found = false;
					if ( Left( relativeUrl, (nTraversals+1) * 3 ) EQ RepeatString( '../', nTraversals+1 ) ) {
						nTraversals++;
						found = true;
					}
				}
				for( i=1; i LTE nTraversals; i++ ){
					cssFileUrl = ListDeleteAt( cssFileUrl, ListLen( cssFileUrl, '/' ), '/' );
				}

				// build the full url without relative paths
				if ( nTraversals ){
					fullUrl = $listAppend( cssFileUrl, Replace( relativeUrl, RepeatString( '../', nTraversals ), '' ), '/' );
				} else {
					fullUrl = $listAppend( cssFileUrl, relativeUrl, '/' );
				}

				// calculate a cache buster if we can
				if ( addCachebusters ) {
					imagePath = $listAppend( getDirectoryFromPath( cssFilePath ), relativeUrl, '/' );
					if ( FileExists( imagePath ) ){
						imageLastModified = $fileLastModified( imagePath );
						cacheBuster = DateFormat( imageLastModified, 'yyyymmdd' ) & TimeFormat( imageLastModified, 'hhmmss' );
						fullUrl = fullUrl & '?' & cacheBuster;
					}
				}
			}

			return fullUrl;
		</cfscript>
    </cffunction>

    <cffunction name="_calculateBase64String" access="private" returntype="string" output="false">
		<cfargument name="relativeUrl" type="string" required="true" />
		<cfargument name="cssFilePath" type="string" required="true" />

		<cfscript>
			var imagePath = $listAppend( getDirectoryFromPath( cssFilePath ), relativeUrl, '/' );
			if (FileExists( imagePath ) ) {
				return $fileReadBinary( path=imagePath, convertToBase64=true );
			}

			return "";
		</cfscript>
    </cffunction>

    <cffunction name="_calculateMimeType" access="private" returntype="string" output="false">
    	<cfargument name="imagePath" type="string" required="true" />

    	<cfscript>
    		switch( ListLast( imagePath, '.' ) ){
    			case 'gif':
    				return 'image/gif';
    			case 'png':
    				return 'image/png';
    			default:
    				return 'image/jpeg';
    		}
    	</cfscript>
    </cffunction>

<!--- accessors --->
	<cffunction name="_getBaseCssPath" access="private" returntype="string" output="false">
    	<cfreturn _baseCssPath />
    </cffunction>
    <cffunction name="_setBaseCssPath" access="private" returntype="void" output="false">
    	<cfargument name="baseCssPath" type="string" required="true" />
    	<cfset _baseCssPath = baseCssPath />
    </cffunction>

	<cffunction name="_getBaseCssUrl" access="private" returntype="string" output="false">
    	<cfreturn _baseCssUrl />
    </cffunction>
    <cffunction name="_setBaseCssUrl" access="private" returntype="void" output="false">
    	<cfargument name="baseCssUrl" type="string" required="true" />
    	<cfset _baseCssUrl = baseCssUrl />
    </cffunction>

</cfcomponent>
