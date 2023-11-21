/**
 * I am a CF wrapper to the ClosureCompiler jar to use as the default rather than YUI
 * set the option <code>useGoogleClosure = true</code> when initialising cfstatic. To use
 * on an individual file add the annotation <code>@ecma6 true</code> eg
 * <pre><code>
 *
 * see https://blog.bolinfest.com/2009/11/calling-closure-compiler-from-java.html
 * and https://github.com/google/closure-compiler/blob/master/src/com/google/javascript/jscomp/CommandLineRunner.java
 */
component extends="org.cfstatic.util.Base" {

	/**
	 * Constructor, taking a javaloader instance preloaded with the path to the Google Closure Compiler jar.
	 *
	 * @javaloader An instance of the javaloader with class path of Closure Compiler jar preloaded. Optional.
	 */
	public org.cfstatic.util.ClosureCompiler function init(any javaLoader){
		if ( arguments.keyExists("javaLoader") ) {
			super._setJavaLoader( javaLoader );
		}
		return this;
	}

	/**
	 * I take a js input string and return a compressed version.
	 *
	 * @string the JavaScript String to compile
	 */
	public string function compressJs(required string source){

		var compiler = $loadJavaClass( 'com.google.javascript.jscomp.Compiler' ).init();
		var options = $loadJavaClass( 'com.google.javascript.jscomp.CompilerOptions' ).init();
		var compilationLevel = $loadJavaClass( 'com.google.javascript.jscomp.CompilationLevel').fromString("SIMPLE_OPTIMIZATIONS");

		try{
			options.setEnvironment(options.Environment.valueOf("BROWSER"));
			options.setEmitUseStrict(false);
			options.setOutputCharset(new java("java.nio.charset.StandardCharsets").UTF_8);
			compilationLevel.setOptionsForCompilationLevel(options);
			// To get the complete set of externs, the logic in CompilerRunner.getDefaultExterns() should be used here.
			var externals = $loadJavaClass( 'com.google.javascript.jscomp.SourceFile' ).fromCode("externs.js","function alert(x) {}");
			// The dummy input name "input.js" is used here so that any warnings or errors will cite line numbers in terms of input.js.
			var rawJs =  $loadJavaClass( 'com.google.javascript.jscomp.SourceFile' ).fromCode("input.js", arguments.source);
			// compiler.compile returns a com.google.javascript.jscomp.Result but we do not need it
			compiler.compile(externals, rawJs, options);
		} catch(any e){
			writeDump(e, "console");
			$throw( argumentCollection = e );
		}
		// The compiler is responsible for generating the compiled code; it is not accessible via the Result.
		return compiler.toSource();
	}
}