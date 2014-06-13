app = angular.module('angular-pdf-viewer', [])

app.provider "pdfViewerDefaults", ->
  {
    options: {
      translations: {
        nextPage: "&rarr;"
        previousPage: "&larr;"
        zoomIn: "+"
        zoomOut: "-"
        page: "Page"
        loading: "Loading..."
        download: "Download"
      }
      showTitle: true
      showDownloadLink: true
    }
    $get: ->
      @options

    set: (keyOrHash, value) ->
      if typeof(keyOrHash) == 'object'
        for k, v of keyOrHash
          @options[k] = v
      else
        @options[keyOrHash] = value
  }
  
app.directive "pdfViewer", ["$window", "$sce", "pdfViewerDefaults", ($window, $sce, pdfViewerDefaults) ->
  {
    restrict: 'A'
    scope: {
      src: '@'
    }
    replace: true
    link: (scope, element, attrs) ->
      # Initialize Variables
      pdf = null
      canvas = null
      context = null
      scope.scale = 1.5
      scope.isLoading = true

      # Configure Options
      scope.showDownloadLink = if (attrs.showDownloadLink == 'true') then true else pdfViewerDefaults.showDownloadLink
      scope.showTitle = if (attrs.showTitle == 'true') then true else pdfViewerDefaults.showTitle
      scope.translations = pdfViewerDefaults.translations

      for key, value of scope.translations
        if typeof value == "string"
          scope.translations[key] = $sce.trustAsHtml(value)

      # Initialize Directive
      init = ->
        console.log 'init'
        scope.title = scope.src
        scope.useEmbedded = (browserSupportsPdfJS() == false)
        console.log "use embedded?", scope.useEmbedded
        if scope.useEmbedded
          setupEmbeddedObject()
        else
          setupPdfJs()

      # Embedded Object Setup
      setupEmbeddedObject = ->
        scope.embeddedWidth = attrs.embeddedWidth || 850
        scope.embeddedHeight = attrs.embeddedHeight || 700
        scope.isLoading = false
        # window.onEmbeddedLoad = ->
        #   console.log "loaded!"
        setTimeout(
          -> element.find(".pdf-viewer-embedded-object").on('load', -> console.log 'load!')
          200
        )

      # PDF.js Setup & Render Code
      # =====================================================
      setupPdfJs = ->
        console.log 'setup!'
        canvas = document.getElementById("pdf-viewer-canvas")
        context = canvas.getContext('2d')
        PDFJS.disableWorker = false
        scope.pageNum = 1
        scope.pageCount = 1
        console.log 'get!'
        console.log scope.src
        scope.isLoading = false
        PDFJS.getDocument(scope.src).then((_pdf) ->
          pdf = _pdf
          scope.$apply ->
            scope.pageCount = _pdf.numPages
          renderPage()
        )
        scope.$watch 'pageNum', (newVal, oldVal) ->
          scope.pageNumRequested = newVal
          renderPage() if (newVal != oldVal)
        scope.$watch 'scale', (newVal, oldVal) ->
          renderPage() if (newVal != oldVal)

      renderPage = ->
        if !isValidPageNum(scope.pageNum)
          scope.pageNum = 1
        else
          console.log 'rendering page', scope.pageNum
          pdf.getPage(scope.pageNum).then(
            (page) ->
              console.log 'got the page'
              viewport = page.getViewport(scope.scale)
              canvas.height = viewport.height
              canvas.width = viewport.width
              page.render({
                canvasContext: context,
                viewport: viewport
              })
            (err) -> console.error(err)
          )
        return

      browserSupportsPdfJS = ->
        true

      isValidPageNum = (num) -> angular.isNumber(num) && num > 0 && num <= scope.pageCount

      # Non PDF.js Related Watches
      # =====================================================
      scope.$watch 'src', (newVal, oldVal) ->
        if newVal? && (newVal != oldVal)
          init()
      # =====================================================

      # PDF.js VIEW ACTIONS
      # =====================================================
      scope.zoomIn = -> scope.scale += 0.2 unless scope.scale > 3
      scope.zoomOut = -> scope.scale -= 0.2 unless scope.scale <= 0.7
      scope.nextPage = -> scope.pageNum += 1 if isValidPageNum(scope.pageNum + 1)
      scope.prevPage = -> scope.pageNum -= 1 if isValidPageNum(scope.pageNum - 1)
      scope.firstPage = -> scope.pageNum = 1
      scope.lastPage = -> scope.pageNum = scope.pageCount
      scope.goToPage = (num) ->
        num = parseInt(num)
        if num? && isValidPageNum(num)
          scope.pageNum = num
        else
          scope.pageNumRequested = scope.pageNum
      # =====================================================

      init() if scope.src

    template: """
                <div class='pdf-viewer'>
                  <div class='pdf-viewer-loading' ng-show='isLoading'>Loading...</div>
                  <div ng-show='!isLoading'>
                    <div class='pdf-viewer-toolbar'>
                      <div class='pdf-viewer-toolbar-left' ng-hide='useEmbedded'>
                        <button class='pdf-toolbar-btn' ng-click='prevPage()' ng-bind-html='translations.previousPage' ng-disabled='pageNum <= 1'></button>
                        <button class='pdf-toolbar-btn' ng-click='nextPage()' ng-bind-html='translations.nextPage' ng-disabled='pageNum >= pageCount'></button>
                        <form class='pdf-viewer-toolbar-page' ng-submit='goToPage(pageNumRequested)'>
                          <span>Page:</span>
                          <input type='text' ng-model='pageNumRequested' ng-blur='goToPage(pageNumRequested)'>
                          <span>of {{pageCount}}</span>
                        </form>
                      </div>
                      <div class='pdf-viewer-toolbar-center'>
                        <strong ng-if='showTitle' ng-bind='title'></strong>
                      </div>
                      <div class='pdf-viewer-toolbar-right'>
                        <div class='pdf-viewer-toolbar-wrapper' ng-hide='useEmbedded'>
                          <span>Zoom: {{scale * 100.0 | number:0}}% </span>
                          <button class='pdf-toolbar-btn' ng-click='zoomOut()' ng-bind-html='translations.zoomOut'></button>
                          <button class='pdf-toolbar-btn' ng-click='zoomIn()' ng-bind-html='translations.zoomIn'></button>
                        </div>
                        <button class='pdf-tooblar-btn' ng-click='download()' ng-bind-html='translations.download'></button>
                      </div>
                    </div>
                    <div class='pdf-viewer-container'>
                      <canvas id='pdf-viewer-canvas' ng-hide='useEmbedded' class='pdf-viewer-canvas'></canvas>
                      <object class='pdf-viewer-embedded-object' ng-if='useEmbedded' ng-show='src' class='pdf-viewer-embedded' ng-cloak data='{{src}}' type='application/pdf' width='{{embeddedWidth}}' height='{{embeddedHeight}}'>
                    </div>
                  </div>
                </div>
              """
  }
]
