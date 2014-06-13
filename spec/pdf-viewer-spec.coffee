describe "PDF Viewer Directive", ->
  element = null
  scope = null
  $compile = null

  beforeEach angular.mock.module('angular-pdf-viewer')
  beforeEach(inject((_$compile_, $rootScope) ->
    scope = $rootScope
    $compile = _$compile_
    return
  ))

  describe 'a basic directive', ->
    beforeEach ->
      # element = $compile("<div pdf-viewer src='sample.pdf'></div>")
      # scope.$digest()


