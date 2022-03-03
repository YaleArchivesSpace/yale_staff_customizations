/* 
  using javascript rather than jQuery to set the ead3 checkbox to true because there's a version change issue in jQuery (from .attr to .prop) that we don't want to worry about.
  */
//  
$(document).bind("loadedrecordform.aspace", function (event, $container) {    
    var ead3_elem = document.getElementById("ead3");
    if (ead3_elem != null && ead3_elem.type === "checkbox") {ead3_elem.checked = true;}
      });
