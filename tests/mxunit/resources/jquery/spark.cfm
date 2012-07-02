 <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" 
    "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
    <script type="text/javascript" src="jquery.min.js"></script>
    <script type="text/javascript" src="jquery.sparkline.min.js"></script>
    <script type="text/javascript">
    $(function() {
        var myvalues = [10,8,5,7,4,4,1];
        $('.dynamicsparkline').sparkline(myvalues, {height:'100px',width:'300px'});
    });
    </script>
</head>
<body>
<div style="height:100px;width:400px;overflow:auto;border:1px solid black;position: relative">
          Testing Header
          <br/>
          <span class="dynamicsparkline">Loading..</span>
          <br/>
          Testing Footer
</div>
</body>
</html>
