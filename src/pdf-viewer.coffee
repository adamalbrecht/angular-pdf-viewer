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
      console.log "link!"
      # Setup options
      scope.showDownloadLink = if (attrs.showDownloadLink == 'true') then true else pdfViewerDefaults.showDownloadLink
      scope.translations = pdfViewerDefaults.translations
      for key, value of scope.translations
        if typeof value == "string"
          scope.translations[key] = $sce.trustAsHtml(value)

      init = ->
        scope.title = scope.src
        console.log 'init'
        scope.scale = 1.5
        scope.isLoading = false
        scope.useEmbedded = (browserSupportsPdfJS() == false)
        canvas = document.getElementById("pdf-viewer-canvas")
        context = canvas.getContext('2d')
        # window = angular.element($window)

        # PDFJS.disableWorker = true
        scope.pageNum = 1

        console.log "Getting the doc", scope.src
        # scope.isLoading = false
        PDFJS.getDocument(scope.src).then((pdf) ->
          scope.isLoading = false
          console.log "Got the doc!"
          pdf.getPage(1).then((page) ->
            viewport = page.getViewport(scope.scale)
            canvas.height = viewport.height
            canvas.width = viewport.width

            page.render({
              canvasContext: context,
              viewport: viewport
            })
          )
        )
        return


      browserSupportsPdfJS = ->
        true

      scope.$watch 'src', (newVal, oldVal) ->
        if newVal? && (newVal != oldVal)
          console.log "WATCH INIT"
          init()
      init() if scope.src

    controller: ["$scope", ($scope) ->
      $scope.zoomIn = -> console.log "Zoom In"
      $scope.zoomOut = -> console.log "Zoom Out"
      $scope.firstPage = -> console.log "Last Page"
      $scope.lastPage = -> console.log "Last Page"
    ]
    template: """
                <div class='pdf-viewer'>
                  <div class='pdf-viewer-loading' ng-show='isLoading'>Loading...</div>
                  <div ng-show='!isLoading'>
                    <div class='pdf-viewer-toolbar' ng-show='!useEmbedded'>
                      <div class='pdf-viewer-toolbar-left'>
                        <button class='pdf-toolbar-btn' ng-click='prevPage()' ng-bind-html='translations.previousPage'></button>
                        <button class='pdf-toolbar-btn' ng-click='nextPage()' ng-bind-html='translations.nextPage'></button>
                        <div class='pdf-viewer-toolbar-page'>
                          <span>Page:</span>
                          <input type='text' ng-model='pageNum'>
                          <span ng-show='pageCount'>of {{pageCount}}</span>
                        </div>
                      </div>
                      <div class='pdf-viewer-toolbar-center'>
                        <strong ng-if='showTitle' ng-bind='title'></strong>
                      </div>
                      <div class='pdf-viewer-toolbar-right'>
                        <span>Zoom: {{scale * 100.0}}% </span>
                        <button class='pdf-toolbar-btn' ng-click='zoomOut()' ng-bind-html='translations.zoomOut'></button>
                        <button class='pdf-toolbar-btn' ng-click='zoomIn()' ng-bind-html='translations.zoomIn'></button>
                        <button class='pdf-tooblar-btn' ng-click='download()' ng-bind-html='translations.download'></button>
                      </div>
                    </div>
                    <div class='pdf-viewer-container'>
                      <canvas id='pdf-viewer-canvas' ng-show='!useEmbedded' class='pdf-viewer-canvas'></canvas>
                      <object ng-if='useEmbedded' ng-show='src' class='pdf-viewer-embedded' ng-cloak data='{{src}}' type='application/pdf' width='{{width}}' height='{{height}}'>
                    </div>
                  </div>
                </div>
              """
  }
]
