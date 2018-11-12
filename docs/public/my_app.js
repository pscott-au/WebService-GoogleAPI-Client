var blank_method_spec = {
      base_url: '',
      parameterOrder: [],
      parameters: [{name: '', description: '', type: '', location: '', required: ''}],
      scopes: []
    };

function endpoint_selected( api_endpoint )
{
  if ( api_endpoint !== 'Select an API End-Point')
  {
    // https://blog.garstasio.com/you-dont-need-jquery/ajax/
    var xhr = new XMLHttpRequest();
    xhr.open('GET', 'endpoint_detail?method_name=' + api_endpoint );
    xhr.onload = function() {
        if (xhr.status === 200) {
            // alert('API DETAIL ' + xhr.responseText);
            var res = JSON.parse(xhr.responseText);
            console.log( res );
            app.method_spec = res;
        }
        else {
            alert('Request failed.  Returned status of ' + xhr.status);
        }
    };
    xhr.send();

  }
  
}

function api_selected( api_id)
{

  document.getElementById("methods-list").selectedIndex = 0;

  // https://blog.garstasio.com/you-dont-need-jquery/ajax/
  var xhr = new XMLHttpRequest();
  xhr.open('GET', 'api_detail?api_id=' + api_id );
  xhr.onload = function() {
      if (xhr.status === 200) {
          // alert('API DETAIL ' + xhr.responseText);
          var res = JSON.parse(xhr.responseText);
          console.log( res );
          app.api_spec = res;
          app.method_spec = blank_method_spec;
          //'Select an API End-Point'




      }
      else {
          alert('Request failed.  Returned status of ' + xhr.status);
      }
  };
  xhr.send();
  
}

Vue.component('todo-item', {
  // The todo-item component now accepts a
  // "prop", which is like a custom attribute.
  // This prop is called todo.
  props: ['todo'],
  template: '<li>{{ todo.text }}</li>'
});



var app = new Vue({
  el: '#app',
  data: {
    method_spec: blank_method_spec,
    api_spec: {
      api: {
        canonicalName: "Ad Experience Report",
        description: "Views Ad Experience Report data, and gets a list of sites that have a significant number of annoying ads.",
        discoveryVersion: "v1",
        icons: {
          x16: "http://www.google.com/images/icons/product/search-16.gif",
          x32: "http://www.google.com/images/icons/product/search-32.gif"
        }
      }
    },
    message: 'Hello Vue!',
  }
})
