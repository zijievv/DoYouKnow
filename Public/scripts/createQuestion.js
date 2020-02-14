// On page load, send a GET request to `/api/categories`.
// Gets all the categories in the app.
$.ajax({
  url: "/api/categories/",
  type: "GET",
  contentType: "application/json; charset=utf-8"
}).then(function (response) {
  var dataToReturn = [];
  for (var i=0; i<response.length; i++) {
    var tagToTransform = response[i];
    var newTag = { 
      id: tagToTransform["name"],
      text: tagToTransform["name"]
    };
    dataToReturn.push(newTag);
  }
  $("#categories").select2({
    placeholder: "Select Categories for the Question",
    tags: true,
    tokenSeparators: [','],
    data: dataToReturn
  });
});
