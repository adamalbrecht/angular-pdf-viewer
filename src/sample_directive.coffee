app = angular.module("sample-directive-module", [])

app.directive "sampleDirective", ->
  {
    restrict: "EA"
    replace: true
    link: (scope, elem, attrs) ->
      scope.myText = attrs.sampleDirective
    template: "<h1>{{myText}}</h1>"
  }
