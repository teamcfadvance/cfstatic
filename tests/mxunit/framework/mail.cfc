<!--- 
	This is the main email utility component.
--->

<cfcomponent displayname="mxunit.framework.mail">
	<cfproperty name="password" required="false" type="string" />
	<cfproperty name="port" required="false" type="string" default="110" />
	<cfproperty name="server" required="true" type="string" />
	<cfproperty name="ssl" required="false" type="boolean" default="false" />
	<cfproperty name="username" required="true" type="string" />
	
	<cffunction name="init" access="public" output="false" returntype="mxunit.framework.mail">
		<cfargument name="server" required="true" type="string" />
		<cfargument name="port" required="false" default="110" type="string" />
		<cfargument name="username" required="true" type="string" />
		<cfargument name="ssl" required="false" type="boolean" default="false" />
		<cfset variables.instance = structNew() />
		
		<cfscript>
			setServer   ( arguments.server   );
			setPort     ( arguments.port     );
			setUsername ( arguments.username );
			setSsl      ( arguments.ssl      );
			setPassword ( arguments.password );
			
			javaSystem = createObject("java", "java.lang.System");
			javaSystemProps = javaSystem.getProperties();
			javaSystemProps.setProperty("mail.pop3.port", getPort());
			javaSystemProps.setProperty("mail.pop3.socketFactory.port", getPort());
			if (getSsl())
			{
				javaSystemProps.setProperty("mail.pop3.socketFactory.class", "javax.net.ssl.SSLSocketFactory");
			} else {
				javaSystemProps.setProperty("mail.pop3.socketFactory.class", "javax.net.SocketFactory");
			}
			
			return this;
		</cfscript>
	</cffunction>
	
	<cffunction name="storeHeaders" access="public" output="false" returntype="void">
		
	</cffunction>
	
	<cffunction name="getPassword" access="public" output="false" returntype="string">
		<cfreturn variables.instance.password />
		
	</cffunction>
	
	<cffunction name="getPort" access="public" output="false" returntype="string">
		<cfreturn variables.instance.port />
		
	</cffunction>	
	
	<cffunction name="getServer" access="public" output="false" returntype="string">
		<cfreturn variables.instance.server />
		
	</cffunction>
	
	<cffunction name="getSsl" access="public" output="false" returntype="string">
		<cfreturn variables.instance.ssl />
		
	</cffunction>
	
	<cffunction name="getUsername" access="public" output="false" returntype="string">
		<cfreturn variables.instance.username />
		
	</cffunction>
	
	<cffunction name="setPort" access="public" output="false" returntype="void">
		<cfargument name="port" required="true" type="string" />
		<cfset variables.instance.port = arguments.port />
	</cffunction>
	
	<cffunction name="setPassword" access="public" output="false" returntype="void">
		<cfargument name="password" required="true" type="string" />
		<cfset variables.instance.password = arguments.password />
	</cffunction>
	
	<cffunction name="setServer" access="public" output="false" returntype="void">
		<cfargument name="server" required="true" type="string" />
		<cfset variables.instance.server = arguments.server />
	</cffunction>
	
	<cffunction name="setSsl" access="public" output="false" returntype="void">
		<cfargument name="ssl" required="true" type="string" />
		<cfset variables.instance.ssl = arguments.ssl />
	</cffunction>
	
	<cffunction name="setUsername" access="public" output="false" returntype="void">
		<cfargument name="username" required="true" type="string" />
		<cfset variables.instance.username = arguments.username />
	</cffunction>
	
	<cffunction name="print" access="public" output="false" returntype="struct">
		<cfreturn variables.instance />
		
	</cffunction>
	
</cfcomponent>