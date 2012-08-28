---
layout: default
title: Quick Start Guide
---

# {{ page.title }}

1. [Download and install](#install)
2. [Create an instance of CfStatic](#create-instance)
3. [Configure dependencies](#configure-dependencies)
4. [Include static resources in your request](#include-resources)
5. [Render includes](#render-includes)

<a id="install"></a>
## Download and install

Choose a download from the [downloads page](downloads.html) and download it. Unzip the contents of the download to some directory on your machine and create a mapping to the `org/cfstatic` directory. The logical path of the mapping should be `/org/cfstatic`.

<a id="create-instance"></a>
## Create an instance of CfStatic

CfStatic is designed to be a singleton so you will want to store the instance of CfStatic in a cacheable scope (i.e. the application scope). For example:

{% highlight cfm %}
<cfscript>
application.cfstatic = CreateObject( 'org.cfstatic.CfStatic' ).init(
    staticDirectory = ExpandPath('./static')
  , staticUrl       = "/static/"
);
</cfscript>
{% endhighlight %}

For more detail, see [configuring cfstatic](full-guide.html#configuration).

<a id="configure-dependencies"></a>
## Configure dependencies

In order for CfStatic to render static includes in the correct order and satisfy dependencies, it must know how your static files relate to each other. It offers three ways in which to do this:

1. JavaDoc style documentation in each file
2. Plain text 'dependencies' file
3. File and folder name ordering

All three methods may be used. Dependencies declared in JavaDoc style comments and in the dependencies file will be merged. When there is no dependency information, CfStatic will use the file and folder names for ordering of includes.

#### JavaDoc example:
{% highlight js %}
/**
 * myplugin does this and that...
 *
 * @depends http://ajax.googleapis.com/ajax/libs/jquery/1.6.4/jquery.min.js
 * @depends /core/jquery.ui.js
 * @depends /core/api.js
 * @author joe bloggs
 */
(function($){
     // my plugin code here...
})(jQuery);
{% endhighlight %}

See an in-depth explanation in the [full guide](full-guide.html#javadoc).

#### Dependency file example:
{% highlight sh %}
##
# This file details dependencies between
# javascript files.
#
# Indented files have dependencies on the
# unindented file(s) above them. Dependent
# files marked with (conditional), only depend
# on the file above when it is already included
# in the request and can be included without
# the dependency.
##

http://ajax.googleapis.com/ajax/libs/jquery/1.6.4/jquery.min.js
    http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.18/jquery-ui.min.js
    *.js

http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.18/jquery-ui.min.js
    /folder/some.js
    /core/bootstrap.js
    /ui-pages/*.js

/core/bootstrap.js
    /folder/*.js
    /ui-pages/*.js
    /shared/*.js

/folder/some.js
    /folder/some-more.js

/shared/swfLoader/swfLoader.js
    /folder/some.js

/shared/jqGrid/locales/*.js
    /shared/jqGrid/jqGrid.js (conditional)

/shared/jqGrid/jqGrid.js
    /folder/some-more.js
{% endhighlight %}

See an in-depth explanation in the [full guide](full-guide.html#dependency-file).

<a id="include-resources"></a>
## Include static resources in your request

For example:

{% highlight cfm %}
<cfscript>
application.cfstatic
    .include( '/js/core/someJs.js' )
    .include( '/js/some/more.js' )
    .include( '/js/wholefolder/' )
    .include( '/css/core/' )
    .include( '/css/print/print.css' )
    .include( '/css/pages/#request.pageName#' )
    .includeData( someStructToBeAvailableToJs );
</cfscript>
{% endhighlight %}

You can make as many `include` and `includeData` calls in your request as you wish, and in any order. Note that both methods are chainable. CfStatic will take care of removing duplicates, including dependent files and rendering the includes in the correct order.

<a id="render-includes"></a>
## Render the includes

{% highlight cfm %}
<html>
    <head>
        ...
        #application.cfstatic.renderIncludes( 'css' )#
    </head>
    <body>
        ...
        #application.cfstatic.renderIncludes( 'js' )#
    </body>
</html>
{% endhighlight %}

Or, to render both CSS and JS includes at once:

{% highlight cfm %}
<html>
    <head>
        ...
        #application.cfstatic.renderIncludes()#
    </head>
    ...
{% endhighlight %}

And that is CfStatic in a nutshell. See the [full useage guide](full-guide.html) for full useage details, including how to process `.less` and `.coffee` files.