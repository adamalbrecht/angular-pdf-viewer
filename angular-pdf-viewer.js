var app;
app = angular.module('angular-pdf-viewer', []);
app.provider('pdfViewerDefaults', function () {
  return {
    options: {
      translations: {
        nextPage: '&rarr;',
        previousPage: '&larr;',
        zoomIn: '+',
        zoomOut: '-',
        page: 'Page',
        loading: 'Loading...',
        download: 'Download'
      },
      showTitle: true,
      showDownloadLink: true
    },
    $get: function () {
      return this.options;
    },
    set: function (keyOrHash, value) {
      var k, v, _results;
      if (typeof keyOrHash === 'object') {
        _results = [];
        for (k in keyOrHash) {
          v = keyOrHash[k];
          _results.push(this.options[k] = v);
        }
        return _results;
      } else {
        return this.options[keyOrHash] = value;
      }
    }
  };
});
app.factory('pdfJsBrowserSupport', function () {
  var getBrowser;
  getBrowser = function () {
    var M, agent, tem;
    tem = null;
    agent = navigator.userAgent;
    M = agent.match(/(opera|chrome|safari|firefox|msie|trident(?=\/))\/?\s*(\d+)/i) || [];
    if (/trident/i.test(M[1])) {
      tem = /\brv[ :]+(\d+)/g.exec(ua) || [];
      return 'IE ' + (tem[1] || '');
    }
    if (M[1] === 'Chrome') {
      tem = agent.match(/\bOPR\/(\d+)/);
      if (tem !== null) {
        return 'Opera ' + tem[1];
      }
    }
    M = M[2] ? [
      M[1],
      M[2]
    ] : [
      navigator.appName,
      navigator.appVersion,
      '-?'
    ];
    if ((tem = agent.match(/version\/(\d+)/i)) !== null) {
      M.splice(1, 1, tem[1]);
    }
    return M.join(' ');
  };
  return {
    get: getBrowser,
    isSupported: function (_this) {
      return function () {
        var browser;
        browser = getBrowser();
        return browser.indexOf('msie') === -1;
      };
    }(this)
  };
});
app.directive('pdfViewer', [
  '$window',
  '$sce',
  'pdfViewerDefaults',
  'pdfJsBrowserSupport',
  function ($window, $sce, pdfViewerDefaults, pdfJsBrowserSupport) {
    return {
      restrict: 'A',
      scope: { src: '@' },
      replace: true,
      link: function (scope, element, attrs) {
        var canvas, context, init, isValidPageNum, key, pdf, renderPage, setupEmbeddedObject, setupPdfJs, value, _ref;
        pdf = null;
        canvas = null;
        context = null;
        scope.zoom = 100;
        scope.isLoading = true;
        scope.showDownloadLink = attrs.showDownloadLink === 'true' ? true : pdfViewerDefaults.showDownloadLink;
        scope.showTitle = attrs.showTitle === 'true' ? true : pdfViewerDefaults.showTitle;
        scope.translations = pdfViewerDefaults.translations;
        _ref = scope.translations;
        for (key in _ref) {
          value = _ref[key];
          if (typeof value === 'string') {
            scope.translations[key] = $sce.trustAsHtml(value);
          }
        }
        init = function () {
          console.log('init');
          scope.title = scope.src;
          scope.useEmbedded = pdfJsBrowserSupport.isSupported() === false;
          console.log('use embedded?', scope.useEmbedded);
          if (scope.useEmbedded) {
            return setupEmbeddedObject();
          } else {
            return setupPdfJs();
          }
        };
        setupEmbeddedObject = function () {
          scope.embeddedWidth = attrs.embeddedWidth || 850;
          scope.embeddedHeight = attrs.embeddedHeight || 700;
          scope.isLoading = false;
          return setTimeout(function () {
            return element.find('.pdf-viewer-embedded-object').on('load', function () {
              return console.log('load!');
            });
          }, 200);
        };
        setupPdfJs = function () {
          console.log('setup!');
          canvas = document.getElementById('pdf-viewer-canvas');
          context = canvas.getContext('2d');
          PDFJS.disableWorker = false;
          scope.pageNum = 1;
          scope.pageCount = 1;
          console.log('get!');
          console.log(scope.src);
          scope.isLoading = false;
          PDFJS.getDocument(scope.src).then(function (_pdf) {
            pdf = _pdf;
            scope.$apply(function () {
              return scope.pageCount = _pdf.numPages;
            });
            return renderPage();
          });
          scope.$watch('pageNum', function (newVal, oldVal) {
            scope.pageNumRequested = newVal;
            if (newVal !== oldVal) {
              return renderPage();
            }
          });
          return scope.$watch('zoom', function (newVal, oldVal) {
            if (newVal !== oldVal) {
              return renderPage();
            }
          });
        };
        renderPage = function () {
          if (!isValidPageNum(scope.pageNum)) {
            scope.pageNum = 1;
          } else {
            console.log('rendering page', scope.pageNum);
            pdf.getPage(scope.pageNum).then(function (page) {
              var viewport;
              console.log('got the page');
              viewport = page.getViewport(scope.zoom * 0.015);
              canvas.height = viewport.height;
              canvas.width = viewport.width;
              return page.render({
                canvasContext: context,
                viewport: viewport
              });
            }, function (err) {
              return console.error(err);
            });
          }
        };
        isValidPageNum = function (num) {
          return angular.isNumber(num) && num > 0 && num <= scope.pageCount;
        };
        scope.$watch('src', function (newVal, oldVal) {
          if (newVal != null && newVal !== oldVal) {
            return init();
          }
        });
        scope.zoomIn = function () {
          if (!(scope.zoom > 200)) {
            return scope.zoom += 10;
          }
        };
        scope.zoomOut = function () {
          if (!(scope.zoom <= 30)) {
            return scope.zoom -= 10;
          }
        };
        scope.nextPage = function () {
          if (isValidPageNum(scope.pageNum + 1)) {
            return scope.pageNum += 1;
          }
        };
        scope.prevPage = function () {
          if (isValidPageNum(scope.pageNum - 1)) {
            return scope.pageNum -= 1;
          }
        };
        scope.firstPage = function () {
          return scope.pageNum = 1;
        };
        scope.lastPage = function () {
          return scope.pageNum = scope.pageCount;
        };
        scope.goToPage = function (num) {
          num = parseInt(num);
          if (num != null && isValidPageNum(num)) {
            return scope.pageNum = num;
          } else {
            return scope.pageNumRequested = scope.pageNum;
          }
        };
        if (scope.src) {
          return init();
        }
      },
      template: '<div class=\'pdf-viewer\'>\n  <div class=\'pdf-viewer-loading\' ng-show=\'isLoading\'>Loading...</div>\n  <div ng-show=\'!isLoading\'>\n    <div class=\'pdf-viewer-toolbar\'>\n      <div class=\'pdf-viewer-toolbar-left\' ng-hide=\'useEmbedded\'>\n        <a href=\'\' class=\'pdf-viewer-toolbar-btn\' ng-click=\'prevPage()\' ng-bind-html=\'translations.previousPage\' ng-disabled=\'pageNum <= 1\'></a>\n        <a href=\'\' class=\'pdf-viewer-toolbar-btn\' ng-click=\'nextPage()\' ng-bind-html=\'translations.nextPage\' ng-disabled=\'pageNum >= pageCount\'></a>\n        <form class=\'pdf-viewer-toolbar-page\' ng-submit=\'goToPage(pageNumRequested)\'>\n          <span>Page:</span>\n          <input type=\'text\' ng-model=\'pageNumRequested\' ng-blur=\'goToPage(pageNumRequested)\'>\n          <span>of {{pageCount}}</span>\n        </form>\n      </div>\n      <div class=\'pdf-viewer-toolbar-center\'>\n        <strong ng-if=\'showTitle\' ng-bind=\'title\'></strong>\n      </div>\n      <div class=\'pdf-viewer-toolbar-right\'>\n        <div class=\'pdf-viewer-toolbar-wrapper\' ng-hide=\'useEmbedded\'>\n          <span>Zoom: {{zoom}}% </span>\n          <a href=\'\' class=\'pdf-viewer-toolbar-btn\' ng-click=\'zoomOut()\' ng-bind-html=\'translations.zoomOut\'></a>\n          <a href=\'\' class=\'pdf-viewer-toolbar-btn\' ng-click=\'zoomIn()\' ng-bind-html=\'translations.zoomIn\'></a>\n        </div>\n        <a class=\'pdf-viewer-toolbar-btn\' download=\'{{src}}\' href=\'{{src}}\' target="_blank" ng-bind-html=\'translations.download\'></a>\n      </div>\n    </div>\n    <div class=\'pdf-viewer-container\'>\n      <canvas id=\'pdf-viewer-canvas\' ng-hide=\'useEmbedded\' class=\'pdf-viewer-canvas\'></canvas>\n      <object class=\'pdf-viewer-embedded-object\' ng-if=\'useEmbedded\' ng-show=\'src\' class=\'pdf-viewer-embedded\' ng-cloak data=\'{{src}}\' type=\'application/pdf\' width=\'{{embeddedWidth}}\' height=\'{{embeddedHeight}}\'>\n    </div>\n  </div>\n</div>'
    };
  }
]);