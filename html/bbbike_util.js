// (c) 2007,2013 Slaven Rezic. All rights reserved.

// NOTE: this is duplicated in newstreetform.tpl.html
function get_and_set_email_author_from_cookie(frm) {
  if (document.cookie) {
    var cookies = document.cookie.split(/;\s*/);
    for (var i=0; i<cookies.length; i++) {
      if (cookies[i].match(/^mapserver_comment=(.*)/)) {
        var arr = RegExp.$1.split("&");
        for(var j=0; j<arr.length/2; j++) {
          var key = arr[j*2];
	  var val = arr[j*2+1];
	  val = val.replace(/%40/g, "@");
	  val = val.replace(/%20/g, " ");
  	  if (key == "email" || key == "author") {
	    frm.elements[key].value = val;
	  }
  	}
	break;
      }
    }
  }
}

// Local variables:
// c-basic-offset: 2
// End:
