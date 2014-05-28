describe "Sample Directive", ->
  element = null
  scope = null
  $compile = null

  beforeEach angular.mock.module('sample-directive-module')
  beforeEach(inject((_$compile_, $rootScope) ->
    scope = $rootScope
    $compile = _$compile_
    return
  ))

  describe 'an empty directive', ->
    beforeEach ->
      element = $compile("<div sample-directive='hello world'></div>")(scope)
      scope.$digest()

    it 'is an h1', ->
      expect($(element).is("h1")).toBeTruthy()

    it 'has the right text', ->
      expect($(element).text()).toEqual("hello world")
