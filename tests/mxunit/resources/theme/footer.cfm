		<div class="grid_12 pageFooter">
			<a href="MIT-License.txt" title="MIT License">
				&copy;<cfoutput>#year(now())# MXUnit.org - v<cfoutput>#version#</cfoutput></cfoutput>
			</a>
		</div>
		
		<div class="clear"><!-- clear --></div>
	</div>
	
	<!--- Check for custom scripts --->
	<cfif arrayLen(scripts)>
		<cfoutput>
			<cfloop from="1" to="#arrayLen(scripts)#" index="i">
				<script type="text/javascript" src="#scripts[i]#"></script>
			</cfloop>
		</cfoutput>
	</cfif>
</body>
</html>
