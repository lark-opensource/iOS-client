(window["webpackJsonp"] = window["webpackJsonp"] || []).push([[15],{

/***/ 1952:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _class, _temp, _initialiseProps; /**
                                      * Created by jinlei.chen on 2017/10/17.
                                      */


var _$rjquery = __webpack_require__(552);

var _const = __webpack_require__(1651);

var _underscore = __webpack_require__(1633);

var _each2 = __webpack_require__(749);

var _each3 = _interopRequireDefault(_each2);

var _string = __webpack_require__(1761);

var _singleLineHelper = __webpack_require__(1763);

var _bowser = __webpack_require__(73);

var _bowser2 = _interopRequireDefault(_bowser);

var _util = __webpack_require__(1653);

var _setImgCopyOutLink = __webpack_require__(2033);

var _tea = __webpack_require__(42);

var _clipboardHelper = __webpack_require__(1833);

var _commentable = __webpack_require__(1700);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var maxImgHeight = 500;

var ImageView = (_temp = _class = function () {
  (0, _createClass3.default)(ImageView, null, [{
    key: 'initAce',
    value: function initAce(ace) {
      ImageView.ace = ace;
    }
  }, {
    key: 'destroy',
    value: function destroy() {
      ImageView.ace = null;
    }
  }]);

  function ImageView(uuid) {
    (0, _classCallCheck3.default)(this, ImageView);

    _initialiseProps.call(this);

    this.ace = ImageView.ace;
    this.uuid = uuid;
  }

  /**
   * 本地图片预览
   * 在上传至服务器之前就先显示图片
   * @param {File} file
   */


  (0, _createClass3.default)(ImageView, [{
    key: 'performImagePreviewer',
    value: function performImagePreviewer(attrs) {
      var ace = this.ace;


      ace.editorInfo.ace_fastIncorp();

      var editorInfo = ace.editorInfo;

      var rep = editorInfo.ace_getRep();
      var selStart = rep.selStart || [1, 0];
      var selEnd = rep.selEnd || [1, 0];
      var text = (0, _singleLineHelper.getSingleLineText)(rep, { selStart: selStart, selEnd: selEnd });

      if ((0, _util.isListLine)(rep.zoneId, selStart[0], editorInfo) && text.slice(0, 1) !== '\n') {
        text = '\n' + text;
      }

      var splitStr = ' ';
      var strArray = (0, _string.getSplitStringArray)(text, splitStr);
      var ops = strArray.map(function (str, index) {
        return {
          start: selStart,
          end: index === 0 ? selEnd : selStart,
          newText: str,
          attributes: str === splitStr ? attrs : []
        };
      });
      editorInfo.ace_performDocumentReplaceMultiRangeWithAttributes(rep.zoneId, ops);
      // editorInfo.ace_performDocumentReplaceRangeWithAttributes(selStart, selEnd, text, attrs);
    }
  }, {
    key: 'createDataURL',
    value: function createDataURL(file) {
      return new Promise(function (resolve, reject) {
        var reader = new FileReader();

        reader.readAsDataURL(file);
        reader.onload = function (e) {
          resolve(e.target.result);
        };

        reader.onerror = function (e) {
          reject(e);
        };
      });
    }
  }, {
    key: 'setImageRectByDirection',


    /**
     * 设置图片的宽高
     * @param {string} direction
     * @param {number} imgW
     * @param {number} imgH
     * @param {number} moveX
     * @param {number} moveY
     * @param {number} left
     * @param {number} top
     * @param {number} imageMaxWidth
     */
    value: function setImageRectByDirection(direction, imgW, imgH, moveX, moveY, left, top, imageMaxWidth) {
      // 将 diff 作为高度差
      var diffY = (0, _util.computeImgScalingDiff)(direction, moveX, moveY);
      if (diffY === 0) {
        return;
      }

      var _computeImgScalingFin = (0, _util.computeImgScalingFinalSize)({ width: imgW, height: imgH }, diffY, imageMaxWidth),
          width = _computeImgScalingFin.width,
          height = _computeImgScalingFin.height;
      // 没变化则不设置样式


      if (width === imgW && height === imgH) {
        return;
      }
      this.setImageStyle(width, height);
    }
  }, {
    key: 'setImageStyle',
    value: function setImageStyle(width, height) {
      var id = 'image-upload-image-' + this.uuid;

      var styleId = id + '-rect-style';
      (0, _$rjquery.$)('#' + styleId).remove();
      (0, _$rjquery.$)('body').append('\n    <style id=' + styleId + '>\n        #' + id + '{\n            width:' + (width + 4) + 'px!important;\n            height:' + (height + 4) + 'px!important;\n        }\n        #' + id + ' img{\n            width:' + width + 'px!important;\n            height:' + height + 'px!important;\n            cursor: default;\n        }\n    </style>\n  ');
    }

    /**
     * 将图片的style 生成changeset
     * @param id
     * @param ace
     * @param rep
     */

  }, {
    key: 'applyImageStyle',
    value: function applyImageStyle(id) {
      var ace = this.ace,
          uuid = this.uuid;
      var editorInfo = ace.editorInfo;

      var $container = (0, _$rjquery.$)('#' + id);
      var zone = editorInfo.dom.zoneOfRootNode(editorInfo.dom.rootNodeOfZoneContaining($container.get(0)));
      var $image = $container.find('img');
      if ($container.length) {
        var rep = editorInfo.ace_getReps()[zone];
        var width = $image.width();
        // 计算图片调整之前的宽度
        var oldWidth = 0;
        try {
          oldWidth = parseInt($image.attr('style').split(';')[0].match(/\d+/)[0]);
        } catch (e) {
          ;
        }
        var height = $image.height();
        var src = encodeURIComponent($image.attr('data-src'));

        var values = ['src=' + src + '&uuid=' + uuid + '&pluginName=' + _const.pluginName + '&height=' + height + 'px&width=' + width + 'px'];

        var line = rep.selStart[0];
        var lineEntry = rep.lines.atIndex(line);
        var textLen = lineEntry.text.length;
        var selStart = [line, lineEntry.lineMarker];
        var selEnd = [line, textLen];
        var attrs = editorInfo.ace_getAttributesOnSelection(zone, {
          selStart: selStart,
          selEnd: selEnd
        }, false);
        var changeAttrs = {
          author: editorInfo.ace_getAuthor(),
          'image-uploaded': values[0],
          'image-placeholder': ''
        };
        var hasChanged = {};
        var changedAttrs = (0, _underscore.reduce)(attrs.attribs, function (memo, attr) {
          var attrName = attr[0];
          var attrValue = attr[1];
          if (!(0, _underscore.isUndefined)(changeAttrs[attrName])) {
            if (!hasChanged[attrName]) {
              attrValue = changeAttrs[attrName];
              hasChanged[attrName] = true;
            } else {
              return memo;
            }
          }

          if (attrName === 'gallery') {
            attrValue = JSON.parse(attrValue).items;
            // 遍历gallery items更新对应item的宽高
            attrValue.forEach(function (item) {
              if (item.uuid === uuid) {
                item.width = width + 'px';
                item.height = height + 'px';
              }
              attrValue = JSON.stringify({
                items: attrValue
              });
            });
          }

          memo.push([attrName, attrValue]);
          return memo;
        }, []);

        editorInfo.ace_callWithAce(function () {
          // 不能调用设置attr 改attr能实现功能，但是由于changeset不会更改， undomodel不起作用
          // todo fix undomodel 改attrs不起作用的bug
          // documentAttributeManager.setAttributesOnRange(rep.selStart, [rep.selEnd[0], rep.selEnd[1] + 1], attrs);
          editorInfo.ace_performDocumentReplaceRangeWithAttributes(zone, selStart, selEnd, ' ', changedAttrs);
          editorInfo.ace_getObserver().withoutRecordingMutations(function () {
            (0, _$rjquery.$)('#' + id + '-rect-style').remove();
          });
        }, 'performImageStyle', true);

        (0, _tea.collectSuiteEvent)('click_image_zoom', {
          zoom_status: oldWidth === 0 ? '' : width > oldWidth ? 'zoom_in' : 'zoom_out'
        });
      }
    }

    /**
     * 删除预览图
     */

  }, {
    key: 'replacePlaceholderWidthImage',
    value: function replacePlaceholderWidthImage(attrs) {
      var ace = this.ace,
          uuid = this.uuid;

      var editorInfo = ace.editorInfo;
      var dom = (0, _$rjquery.$)('#container-wrap-' + _const.uploadPrefix + '-image-' + uuid).closest('.image-previewer').get(0);
      editorInfo.fastIncorp();
      var sel = editorInfo.ace_domToRep(dom);

      if (!sel) {
        return;
      }
      var selStart = sel.selStart,
          selEnd = sel.selEnd;

      var zone = editorInfo.dom.zoneOfdom(dom);
      var lineEntry = editorInfo.ace_getRep().lines.atIndex(selStart[0]) || {};
      var text = lineEntry.text;

      editorInfo.ace_performDocumentReplaceRangeWithAttributes(zone, selStart, [selEnd[0], text.length], ' ', attrs);
    }

    /**
     * 删除所有的图片占位dom
     * @param ace
     */

  }, {
    key: 'calcImageRect',
    value: function calcImageRect(src) {
      return new Promise(function (resolve, reject) {
        var image = new Image();
        var loaded = false;
        // android image load的过程十分久 毛估大于4M就直接100
        if (_bowser2.default.android && src.length > 4 * 1000 * 1000) {
          return resolve({ width: '100%', height: 'auto' });
        }
        image.src = src;

        // 给图片加载添加一个超时
        setTimeout(function () {
          if (!loaded) {
            reject(new Error({ type: 'timeout' }));
          }
        }, _const.IMAGE_LOAD_TIMEOUT);

        image.onload = function () {
          var width = image.width,
              height = image.height;
          var natrualWidth = width,
              natrualHeight = height;

          var maxWidth = window.innerHeight;
          var scale = parseInt(natrualWidth, 10) / parseInt(natrualHeight, 10);
          loaded = true;

          if (width > maxWidth) {
            return resolve({
              width: '100%',
              height: 'auto',
              natrualWidth: parseInt(natrualWidth, 10) + 'px',
              natrualHeight: parseInt(natrualHeight, 10) + 'px',
              scale: scale
            });
          }

          if (height > maxImgHeight) {
            width = maxImgHeight / height * width;
            height = maxImgHeight;
          }

          resolve({
            width: parseInt(width, 10) + 'px',
            height: parseInt(height, 10) + 'px',
            natrualWidth: parseInt(natrualWidth, 10) + 'px',
            natrualHeight: parseInt(natrualHeight, 10) + 'px',
            scale: scale
          });
        };

        image.onerror = function (e) {
          loaded = true;
          reject(e);
        };
      });
    }
  }], [{
    key: 'clearImagePreviewer',
    value: function clearImagePreviewer(dom) {
      var ace = ImageView.ace;

      var editorInfo = ace.editorInfo;
      editorInfo.ace_callWithAce(function () {
        // 应该有更合理的获取rep的方法
        var sel = editorInfo.ace_domToRep(dom);
        if (!sel) {
          return;
        }
        var lineEntry = editorInfo.ace_getReps()[sel.selStart[2] || 0].lines.atIndex(sel.selStart[0]) || {};
        var text = lineEntry.text,
            lineNode = lineEntry.lineNode;

        var zone = editorInfo.dom.zoneOfRootNode(editorInfo.dom.rootNodeOfZoneContaining(lineNode));
        editorInfo.ace_performDocumentReplaceRange(zone, sel.selStart, [sel.selEnd[0], text.length], '');
      }, 'uploadImageFail', true);
    }
  }, {
    key: 'setImageEditable',
    value: function setImageEditable(editable) {
      var imageNodes = Array.prototype.slice.call(document.querySelectorAll('#innerdocbody .image-container'));
      for (var i = 0, length = imageNodes.length; i < length; i++) {
        var node = imageNodes[i];
        if (node.getAttribute('contenteditable') !== editable) {
          node.setAttribute('contenteditable', editable);
        }
      }
    }
  }, {
    key: 'setImageReadWrite',
    value: function setImageReadWrite() {
      ImageView.setImageEditable(true);
    }
  }, {
    key: 'setImageReadOnly',
    value: function setImageReadOnly() {
      ImageView.setImageEditable(false);
    }
  }, {
    key: 'clearAllImagePreviewer',
    value: function clearAllImagePreviewer() {
      var $placeholderListDom = (0, _$rjquery.$)('.image-previewer');

      (0, _underscore.forEach)($placeholderListDom, function (dom) {
        ImageView.clearImagePreviewer(dom);
      });
    }
  }, {
    key: 'hasGalleryChooseStyle',
    value: function hasGalleryChooseStyle() {
      return (0, _$rjquery.$)('#galleryTempStyle').length > 0;
    }
  }, {
    key: 'hasImageChooseStyle',
    value: function hasImageChooseStyle() {
      return (0, _$rjquery.$)('#imageTempStyle').length > 0;
    }
  }, {
    key: 'getChosenImgContainer',
    value: function getChosenImgContainer() {
      var $imageTempStyle = (0, _$rjquery.$)('#imageTempStyle');
      if ($imageTempStyle.length === 0) {
        return (0, _$rjquery.$)(null);
      }
      var id = $imageTempStyle.data('id');
      return (0, _$rjquery.$)('#' + id);
    }
  }, {
    key: 'getChosenGalleryContainer',
    value: function getChosenGalleryContainer() {
      var $imageTempStyle = (0, _$rjquery.$)('#galleryTempStyle');
      if ($imageTempStyle.length === 0) {
        return null;
      }
      var id = $imageTempStyle.data('id');
      return (0, _$rjquery.$)('#' + id);
    }
  }, {
    key: 'removeImageChooseStyle',
    value: function removeImageChooseStyle(e) {
      (0, _$rjquery.$)('#imageTempStyle').remove();
    }
  }, {
    key: 'setRangeOnCloneImage',
    value: function setRangeOnCloneImage(imgDom, evt) {
      var editorInfo = ImageView.ace.editorInfo;

      var $imgClone = (0, _$rjquery.$)(imgDom).clone(false);
      $imgClone && (0, _setImgCopyOutLink.setImgCopyOutLink)($imgClone);
      (0, _setImgCopyOutLink.requestToSetImageOutLink)();
      return ImageView.getCopyImgLineHandler(editorInfo, imgDom, evt);
    }

    /**
     * 复制剪切 .image-upload-copycontainer 时，复制图片所在的一整行 div. 若为gallery, 则只复制特定item
     *
     * @param {EditorInfo} editorInfo
     * @param {HTMLImageElement} imgDom
     */

  }, {
    key: 'getCopyImgLineHandler',
    value: function getCopyImgLineHandler(editorInfo, imgDom, e) {
      var $imgLine = (0, _$rjquery.$)(imgDom).closest('.ace-line');
      var galleryJSON = $imgLine.find('.image-uploaded').attr('data-ace-gallery-json');
      if ($imgLine.length === 0) {
        return;
      }
      e.preventDefault();
      e.stopImmediatePropagation();
      var copyHTML = void 0;
      if (galleryJSON) {
        // 让contentCollector收集为 gallery类型
        var div = document.createElement('div');
        var gallery = JSON.parse(galleryJSON);
        var itemIndex = (0, _$rjquery.$)(imgDom).closest('.image-container-wrap').attr('data-gallery-index');
        gallery.items = [gallery.items[itemIndex]];
        var classList = (0, _$rjquery.$)(imgDom).parents('.image-uploaded')[0].classList;
        (0, _each3.default)(classList, function (className) {
          if (/comment-/.test(className) && !/gallery/.test(className) && !gallery.items[0].comments.includes(className)) {
            gallery.items[0].comments.push(className);
          }
        });
        var comments = gallery.items[0].comments.join(' ');
        div.className = 'image-uploaded ' + comments + ' gallery';
        div.setAttribute('data-ace-gallery-json', JSON.stringify(gallery));
        div.appendChild(imgDom.cloneNode(1));
        if (e && e.type === 'cut') {
          copyHTML = (0, _commentable.addDocTokenToHTML)(editorInfo, div.outerHTML);
        } else {
          copyHTML = div.outerHTML;
        }
      } else {
        if (e && e.type === 'cut') {
          copyHTML = (0, _commentable.addDocTokenToHTML)(editorInfo, $imgLine.get(0).outerHTML);
        } else {
          copyHTML = $imgLine.get(0).outerHTML;
        }
      }
      var clipboardData = e.originalEvent.clipboardData || window.clipboardData;
      _clipboardHelper.clipboardDataHelper.setData(clipboardData, { text: '\n', html: copyHTML });
    }

    /**
     * 图片选择时添加style
     * @param id
     */

  }, {
    key: 'addImageChooseStyle',
    value: function addImageChooseStyle(id) {
      if (!ImageView.ace) return;
      var editorInfo = ImageView.ace.editorInfo;

      var editorStatus = editorInfo.getEditStatus();
      var resizeAble = void 0;
      var zoomInCursor = editorStatus ? '' : 'cursor: zoom-in;cursor:-webkit-zoom-in;';
      if (editorStatus && !_bowser2.default.mobile) {
        resizeAble = true;
      }

      (0, _$rjquery.$)('#imageTempStyle').remove();
      // ImageView.setImageReadOnly();
      (0, _$rjquery.$)('body').append('\n    <style id="imageTempStyle" data-id="' + id + '">\n    #innerdocbody #' + id + ' img {\n        /* border: 2px solid #3799FF !important; */\n        outline: 2px solid #0070e0;\n        outline-offset: -2px;\n      ' + zoomInCursor + '\n    }\n    #innerdocbody #' + id + ' .n-icon-dragable {\n        display:' + (resizeAble ? 'block' : 'none') + ';\n    }\n    <style>\n  ');
    }
  }, {
    key: 'addGalleryChoosedStyle',
    value: function addGalleryChoosedStyle(id) {
      if (!ImageView.ace) return;
      var editorInfo = ImageView.ace.editorInfo;

      var editorStatus = editorInfo.getEditStatus();
      var zoomInCursor = editorStatus ? '' : 'cursor: zoom-in;cursor:-webkit-zoom-in;';
      (0, _$rjquery.$)('#galleryTempStyle').remove();
      (0, _$rjquery.$)('body').append('\n    <style id="galleryTempStyle" data-id="' + id + '">\n    #innerdocbody #' + id + ' img {\n      /* border: 2px solid #0070e0 !important;\n         box-shadow: 0 0 0 2px #0070e0;\n         border: 0; */\n      outline: 2px solid #0070e0;\n      outline-offset: -2px;\n      ' + zoomInCursor + '\n    }\n    </style>\n    ');
    }
  }, {
    key: 'removeGalleryChoosedStyle',
    value: function removeGalleryChoosedStyle() {
      (0, _$rjquery.$)('#galleryTempStyle').remove();
    }
  }, {
    key: 'updateProgressStyle',
    value: function updateProgressStyle(uuid, percentage) {
      var containerId = _const.uploadPrefix + '-holder-' + uuid;
      (0, _$rjquery.$)('#' + containerId + '-style').remove();

      (0, _$rjquery.$)('body').append('\n    <style id="' + containerId + '-style">\n      #' + containerId + ' .upload-progress-bar{\n        width:' + percentage * 100 + '%!important;\n      }\n      #' + containerId + '::after{\n        content: "' + t('etherpad.uploaded_tips') + ' ' + parseInt(percentage * 100) + '%"!important;\n      }\n    </style>');
    }
  }]);
  return ImageView;
}(), _class.IMAGE_READWRITE_ID = 'image-read-write-style', _initialiseProps = function _initialiseProps() {
  var _this = this;

  this.updateProgressStyle = function (percentage) {
    var uuid = _this.uuid;
    ImageView.updateProgressStyle(uuid, percentage);
  };
}, _temp);
exports.default = ImageView;
;
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(25)))

/***/ }),

/***/ 1953:
/***/ (function(module, exports) {

module.exports = window.navigator.msPointerEnabled;

/***/ }),

/***/ 3820:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _dec, _class, _class2, _temp, _initialiseProps; /**
                                                     * @fileoverview 图片上传
                                                     */
// eslint-disable-next-line


var _decode = __webpack_require__(3821);

var _decode2 = _interopRequireDefault(_decode);

__webpack_require__(1972);

var _sendCollectorData = __webpack_require__(1597);

var _sendCollectorData2 = _interopRequireDefault(_sendCollectorData);

var _constants = __webpack_require__(1602);

var _utils = __webpack_require__(1831);

var _const = __webpack_require__(1651);

var _const2 = __webpack_require__(1652);

var _get2 = __webpack_require__(83);

var _get3 = _interopRequireDefault(_get2);

var _some2 = __webpack_require__(785);

var _some3 = _interopRequireDefault(_some2);

var _forEach2 = __webpack_require__(343);

var _forEach3 = _interopRequireDefault(_forEach2);

var _utils2 = __webpack_require__(1632);

var _util = __webpack_require__(1653);

var _hotkeyHelper = __webpack_require__(1596);

var _uploader = __webpack_require__(3822);

var _uploader2 = _interopRequireDefault(_uploader);

var _image_view = __webpack_require__(1952);

var _image_view2 = _interopRequireDefault(_image_view);

var _events = __webpack_require__(3823);

var _events2 = _interopRequireDefault(_events);

var _$rjquery = __webpack_require__(552);

var _uploadCreator = __webpack_require__(1847);

var _tea = __webpack_require__(42);

var _tea2 = _interopRequireDefault(_tea);

var _shortCut = __webpack_require__(3831);

var _dom = __webpack_require__(1682);

var _browserHelper = __webpack_require__(27);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

var _pure = __webpack_require__(1639);

var _pure2 = _interopRequireDefault(_pure);

var _sdkCompatibleHelper = __webpack_require__(45);

var _string = __webpack_require__(163);

var _task = __webpack_require__(3832);

var _toast = __webpack_require__(554);

var _toast2 = _interopRequireDefault(_toast);

var _bytedXEditor = __webpack_require__(299);

var _onboarding = __webpack_require__(314);

var _onboarding2 = __webpack_require__(130);

var _constants2 = __webpack_require__(5);

var _eventEmitter = __webpack_require__(110);

var _eventEmitter2 = _interopRequireDefault(_eventEmitter);

var _apiUrls = __webpack_require__(307);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// 当图片width=100%时，loading蒙版的高度计算比例
// 以Mac为基础，outerHeight / outerWidth得到
var HEIGHT_RATE = 0.625;
var ImageDecodeWorker = new _decode2.default();
var imageUploadPool = {};
var messageHandleQueue = [];
ImageDecodeWorker.onmessage = function (res) {
  messageHandleQueue.forEach(function (handle) {
    handle(res);
  });
};

function addMessageHandle(handle) {
  messageHandleQueue.push(handle);
}

function removeMessageHandle(handle) {
  for (var i = 0, len = messageHandleQueue.length; i < len; i++) {
    if (messageHandleQueue[i] === handle) {
      messageHandleQueue.splice(i, 1);
      break;
    }
  }
}

function cancelEvent(e) {
  e.preventDefault();
}

var ImageUpload = (_dec = (0, _pure2.default)(['initEvent', 'markNodeClean', 'initImageView', 'initUploader', 'log', 'reset', 'aceKeyEvent']), _dec(_class = (_temp = _class2 = function () {
  function ImageUpload(_ref) {
    var _ref$editor = _ref.editor,
        editor = _ref$editor === undefined ? undefined : _ref$editor,
        _ref$needInit = _ref.needInit,
        needInit = _ref$needInit === undefined ? true : _ref$needInit,
        _ref$containerCls = _ref.containerCls,
        containerCls = _ref$containerCls === undefined ? '' : _ref$containerCls,
        galleryComment = _ref.galleryComment,
        firstScreenRenderEnd = _ref.firstScreenRenderEnd;
    (0, _classCallCheck3.default)(this, ImageUpload);

    _initialiseProps.call(this);

    if (editor && needInit) {
      this.aceInitialized('', Object.assign({ editorInfo: editor }, editor));
    } else if (editor) {
      this.ace = editor;
      this.editorInfo = editor;
    }
    this.galleryComment = galleryComment;
    this.firstScreenRenderEnd = firstScreenRenderEnd;
    this.commentRenderQueue = [];
    this.containerCls = containerCls !== '' ? containerCls + ' ' : containerCls;
    this.decodeImages = {};
    imageUploadPool[this.pluginId] = this;
    this.editable = false;
    this.tasks = {};
  }

  (0, _createClass3.default)(ImageUpload, [{
    key: '_handleMsgFromWorker',
    value: function _handleMsgFromWorker(data) {
      var _this2 = this;

      var uuid = data.uuid,
          imgBase64 = data.imgBase64,
          err = data.err,
          msg = data.msg;

      var $container = (0, _$rjquery.$)(this.containerCls + '#container-wrap-' + _const.uploadPrefix + '-image-' + uuid);

      if (!this.decodeImages[uuid]) return;
      if (!$container.length) return;

      var $parent = $container.parents('div[id^=magicdomid]');
      var $img = $container.find('img');
      var hasError = false;

      $img.on('error', function (e) {
        if (hasError) {
          _this2.handleAfterImgLoaded({ uuid: uuid });
          return;
        };
        hasError = true;

        var originSrc = $img.attr('data-src');
        _this2.setSrcWithoutRecord($img, originSrc);
        _this2.markNodeClean($parent[0]);

        _this2.log('dev_stability_image_base64_error', {
          origin_src: originSrc,
          file_id: (0, _tea.getEncryToken)(),
          file_type: (0, _tea.getFileType)()
        });
      });

      $img.on('load', function () {
        _this2.handleAfterImgLoaded({ uuid: uuid });
      });

      if (err) {
        // 发生错误，降级处理，调用原接口
        var originSrc = $img.attr('data-src');
        this.setSrcWithoutRecord($img, originSrc);
        this.log('dev_stability_image_decrypt_base64_error', {
          msg: JSON.stringify(msg),
          origin_src: originSrc,
          file_id: (0, _tea.getEncryToken)(),
          file_type: (0, _tea.getFileType)()
        });
      } else {
        this.setSrcWithoutRecord($img, imgBase64);
      }

      // 取消 loading 动画
      this.editorInfo && this.editorInfo.getObserver().withoutRecordingMutations(function () {
        var dynamicFlex = $container.find('.image-container').attr('data-dynamicFlex');
        var flexStyle = 'width:100%;' + 'padding-top:' + (0, _util.toFixedNumber)(1 / dynamicFlex * 100, 4) + '%;height:0;';
        var imgFlexStyle = 'height: 100% !important;position: absolute;left: 0;top: 0;';
        var imgContainerWidth = $container.parents('.gallery').find('img').length > 1 ? flexStyle : '';
        $container.find('.image-container').attr('style', imgContainerWidth);
        imgContainerWidth && $container.find('img').attr('style', imgFlexStyle);
        $container.find('i.image-loading').remove();
      });

      this.decodeImages[uuid].finished = true;

      if ($parent[0]) {
        this.markNodeClean($parent[0]);
      }
    }
    // init

  }, {
    key: 'initImageView',
    value: function initImageView(ace) {
      _image_view2.default.initAce(ace);
    }
  }, {
    key: 'initUploader',
    value: function initUploader(ace) {
      this.uploader = new _uploader2.default(ace, this);
      this.trigger = this.uploader.uploader.open;
    }
  }, {
    key: 'initEvent',
    value: function initEvent(ace) {
      _events2.default.bind(ace, this);
      _eventEmitter2.default.on(_constants2.events.MOBILE.DOCS.CREATE_SUCCESS, this.handleDocTokenChange);
    }
    // 将attributes映射下
    // linestylefilter, key, value

    /**
     * 粘贴 之后 将光标focus到下一行
     * @param name
     * @param arg
     */

    // 创建行的时候 根据某个class来映射html

  }, {
    key: 'markNodeClean',
    value: function markNodeClean(node) {
      this.editorInfo && this.editorInfo.ace_markNodeClean(node);
    }
  }, {
    key: 'log',
    value: function log(name, params) {
      (0, _tea2.default)(name, params);
    }
    // TODO 有没有可能不使用这个 hook

  }, {
    key: 'isImagePreviewerLine',
    value: function isImagePreviewerLine(lineNum) {
      var rep = this.editorInfo.ace_getRep();
      if (lineNum < 0 || lineNum > rep.lines.length() - 1) {
        return false;
      }

      var html = (0, _get3.default)(rep.lines.atIndex(lineNum), 'lineNode.innerHTML');

      if (html && html.indexOf('image-previewer') > -1) {
        return true;
      }

      return false;
    }
    // 处理只读模式下图片复制的问题,将复制逻辑提出来

  }, {
    key: 'aceBeforeCopy',
    value: function aceBeforeCopy(hook, e) {
      var rep = this.editorInfo.ace_getRep();
      var lineNum = rep.selStart[0];
      var selStart = rep.selStart,
          selEnd = rep.selEnd;

      var thisLineIsImage = (0, _util.isImageLine)(rep, lineNum);

      if (thisLineIsImage && selStart[0] === selEnd[0]) {
        var $img = this.getImageSel();
        if ($img.length) {
          _image_view2.default.setRangeOnCloneImage($img.get(0), e);
        }
      }
    }
  }, {
    key: 'aceCut',
    value: function aceCut(hookName, context) {
      var rep = context.rep;
      var lineNum = rep.selStart[0];
      this.doCut(rep, lineNum, this.editorInfo, context);
    }
  }, {
    key: 'aceKeyEvent',
    value: function aceKeyEvent(hook, context) {
      var evt = context.evt,
          padShortcutEnabled = context.padShortcutEnabled,
          isTypeForSpecialKey = context.isTypeForSpecialKey,
          editorInfo = context.editorInfo;
      var which = evt.which,
          type = evt.type,
          keyCode = evt.keyCode;


      if (type !== 'keydown') return false;

      // 如果图片处于放大模式则禁掉所有默认行为
      if (_events2.default.pcImageViewerShown()) {
        evt.preventDefault();
        return;
      }

      var key = String.fromCharCode(which).toLowerCase();
      var RETURN = _const2.KEYS.RETURN,
          BACKSPACE = _const2.KEYS.BACKSPACE;


      if (!(key === 'c' || key === 'x' || keyCode === RETURN || keyCode === BACKSPACE)) {
        if (_browserHelper2.default.isAndroid && this.isThisLineImage(editorInfo)) {
          // 延时处理是因为 keydown 的时候中文还未处理成功。
          setTimeout(function () {
            (0, _$rjquery.$)('.gallery-drop-hint').text('');
          });
        }
        return false;
      }

      if (isTypeForSpecialKey && keyCode === BACKSPACE && padShortcutEnabled.delete && this.isThisLineImage(editorInfo)) {
        var rep = editorInfo.getRep();
        return this.doDelete(rep, editorInfo, evt, context);
      }

      if (isTypeForSpecialKey && keyCode === RETURN && padShortcutEnabled.return && this.isThisLineImage(editorInfo)) {
        evt.preventDefault();
        var _rep = editorInfo.getRep();
        this.doReturn(_rep, editorInfo);
        return true;
      }
      return false;
    }

    // fastincorp不能在每次keyup的时候调用 否则导致移动端的操作栈不停的被undoModule合成一个

    // beforePasteInsert = (name, context) => {
    //   const { rep, editorInfo, insertHtml } = context;
    //   editorInfo.ace_inCallStackIfNecessary('startNewLine', () => {
    //     // 当前鼠标focus到image中，需要添加回车，光标前置一行
    //     // 之所以这么做，是因为cc不会收集single_line内部html，无法变成新的一行，会造成html进入image的div中
    //     if (!/image-uploaded/.test(insertHtml) || !isImageLine(rep, rep.selStart[0])) return;
    //
    //     editorInfo.fastIncorp();
    //     editorInfo.ace_performDocumentReplaceRange(rep.zoneId, rep.selStart, rep.selStart, '\n');
    //
    //     const point = [rep.selStart[0] - 1, 0];
    //     editorInfo.selection.setWithSelection(rep.zoneId, point, point, false);
    //     editorInfo.ace_updateBrowserSelectionFromRep();
    //   });
    // }

  }, {
    key: 'handleDragStart',
    value: function handleDragStart(e) {
      // 目前没有处理drag操作，阻止
      e.preventDefault();
    }

    // 首屏渲染完成

  }, {
    key: 'sendMessageError',
    value: function sendMessageError(hook, context) {
      if (this.galleryComment) {
        this.galleryComment.changeSetCommitWatcher.sendMessageError(hook, context);
      }
    }
  }, {
    key: 'handleClientMessage_ACCEPT_COMMIT',
    value: function handleClientMessage_ACCEPT_COMMIT(hook, context) {
      if (this.galleryComment) {
        this.galleryComment.changeSetCommitWatcher.handleClientMessage_ACCEPT_COMMIT(hook, context);
      }
    }
  }, {
    key: 'handleClientMessage_ERROR',
    value: function handleClientMessage_ERROR(hook, context) {
      if (this.galleryComment) {
        this.galleryComment.changeSetCommitWatcher.handleClientMessage_ERROR(hook, context);
      }
    }
  }, {
    key: 'reset',
    value: function reset() {
      var _this3 = this;

      if (this.galleryComment) {
        this.galleryComment.destroy();
      }
      _image_view2.default.destroy();
      _events2.default.unbind();
      (0, _uploadCreator.destroyUploader)();
      _eventEmitter2.default.off(_constants2.events.MOBILE.DOCS.CREATE_SUCCESS, this.handleDocTokenChange);
      removeMessageHandle(this.handleMsgFromWorker);

      var _iteratorNormalCompletion = true;
      var _didIteratorError = false;
      var _iteratorError = undefined;

      try {
        for (var _iterator = Object.keys(imageUploadPool)[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
          var prop = _step.value;

          delete imageUploadPool[prop];
        }
      } catch (err) {
        _didIteratorError = true;
        _iteratorError = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion && _iterator.return) {
            _iterator.return();
          }
        } finally {
          if (_didIteratorError) {
            throw _iteratorError;
          }
        }
      }

      var editorInfo = this.ace.editorInfo;

      var innerdoc = editorInfo.ace_getInnerContainer();
      (0, _$rjquery.$)(innerdoc).undelegate('.image-uploaded img', 'dragstart', this.handleDragStart);
      // 清理未完成的任务
      Object.keys(this.tasks).forEach(function (key) {
        var taskData = _this3.tasks[key];
        taskData.task && taskData.task.abort();
      });

      this.tasks = {};
      editorInfo.off('galleryImageChoosed', this.handleGalleryItemsChoosed);
    }
  }]);
  return ImageUpload;
}(), _initialiseProps = function _initialiseProps() {
  var _this4 = this;

  this.className = 'ImageUpload';
  this.pluginId = (0, _utils2.genUUID)();

  this.searchStringRange = function (hook, context) {
    var attributeMap = context.attributeMap;

    if (attributeMap.gallery || attributeMap['image-placeholder'] || attributeMap['image-uploaded'] || attributeMap['image-previewer']) {
      context.isSearchable = false;
    }
  };

  this.handleMsgFromWorker = function (res) {
    _this4.editorInfo.getObserver().withoutRecordingMutations(function () {
      var data = {};

      if (_browserHelper2.default.isIE || !(0, _util.isSupportCoder)()) {
        data = JSON.parse(res.data);
      } else {
        var dec = new TextDecoder();
        data = JSON.parse(dec.decode(res.data));
      }

      var _this = imageUploadPool[data.pluginId];
      _this4._handleMsgFromWorker.call(_this, data);
    });
  };

  this.handleAfterImgLoaded = function (_ref2) {
    var uuid = _ref2.uuid;

    var $div = (0, _$rjquery.$)('#image-upload-image-' + uuid);
    if ($div.length) {
      var _$div$offset = $div.offset(),
          top = _$div$offset.top;

      var editorInfo = _this4.editorInfo;

      editorInfo && editorInfo.call('afterImgLoaded', { top: top });

      // 如果是上传图片，需要滚动一下
      // 否则不用， 不然会导致滚动到第一行
      var needToIgnore = _this4[_const.uploadPrefix + '-ignore-' + uuid];
      if (needToIgnore) {
        delete _this4[_const.uploadPrefix + '-ignore-' + uuid];
        editorInfo.scrollVerticallyBySelectionPosition();
      }
    }
  };

  this.collectCommentQuote = function (hookName, _ref3) {
    var node = _ref3.node,
        attributes = _ref3.attributes;

    if (node && (0, _get3.default)(node, 'children[0].className', '').indexOf('image-uploaded') > -1 || attributes && (0, _some3.default)(attributes, function (item) {
      return item.indexOf('image-uploaded') > -1 || item.indexOf('gallery') > -1;
    })) {
      return '[' + t('editorbar.image') + ']';
    }
  };

  this.collectCommentTargetType = function (hookName, _ref4) {
    var node = _ref4.node;

    // 给打点用的
    if ((0, _get3.default)(node, 'children[0].className', '').indexOf('image-uploaded') > -1) {
      return 'image';
    }
  };

  this.regist = function (editor) {
    editor.registerAceCommand(_hotkeyHelper.INSERT_IMAGE, function (cmd, editorInfo, options, _ref5) {
      var source = _ref5.source;

      _this4.execInsertImage(source);
    });
    addMessageHandle(_this4.handleMsgFromWorker);
  };

  this.aceInitialized = function (name, ace) {
    _this4.ace = ace;
    _this4.editorInfo = ace.editorInfo;
    _this4.initUploader(ace);
    _this4.initImageView(ace);
    _this4.initEvent(ace);
    _this4.regist(_this4.editorInfo);
    // Firefox 下图片不显示默认的缩放控件
    if (_browserHelper2.default.firefox) {
      document.execCommand('enableObjectResizing', false, false);
    }
    // 标记当前perform的图片，第一次resize不会重新reload
    _this4.editorInfo.on(_const.MARK_DECODE_IMAGE, _this4.markDecodeImage);

    // 移动端第一次进入需要绑定事件
    _this4.pluginReadOnly();
  };

  this.markDecodeImage = function (uuid) {
    if (!_this4.decodeImages) return;
    _this4.decodeImages[uuid] = {
      finished: true
    };
  };

  this.isDisabled = function () {
    _this4.decodeImages = {};
  };

  this.aceAttribsToClasses = function (name, args) {
    var key = args.key,
        value = args.value;

    // 只处理这个插件需要关注的key

    if ((0, _util.isImageUploadPlugin)(value) || new RegExp('"pluginName":"imageUpload"').test(value)) {
      return ['key=' + key + '&' + value];
    }

    if (key === 'imaexecInsertImagegefulexecInsertImagelscreen') {
      return ['image-full-screen'];
    }
  };

  this.execInsertImage = function (source) {
    _this4.trigger();
    (0, _sendCollectorData2.default)('insertimage', _constants.OP_ADD, source);
  };

  this.collectContentImage = function (name, context) {
    if (!_this4.ace) return;
    var editorInfo = _this4.ace.editorInfo;
    // 处理mac 13.2以下，系统截图问题
    // https://jira.bytedance.com/browse/DOCS-481
    // paste的clipboardData拿不到内容，粘贴后为 <img src="blob:http:xxxx"/>

    var node = context.node,
        cc = context.cc,
        state = context.state;

    var src = node.getAttribute('data-src') || node.src;
    if (/^blob:/ig.test(src)) {
      var root = editorInfo.ace_getInnerContainer();
      root.dispatchEvent(new CustomEvent('custom-compatible-safari-paste', { detail: src }));
      // 如果是blob，不用设置下一行
      return;
    }

    setTimeout(function () {
      var rep = editorInfo.ace_getRep();
      var maxLines = rep.lines.length() - 1;

      var nextLine = rep.selStart[0] + 1;
      if (nextLine > maxLines) {
        nextLine = maxLines;
      }
      editorInfo.selection.setWithSelection(rep.zoneId, [nextLine, 0], [nextLine, 0], false);
      editorInfo.ace_updateBrowserSelectionFromRep(true);
      _image_view2.default.removeImageChooseStyle();
      _image_view2.default.removeGalleryChoosedStyle();
    });

    if (/^file/ig.test(src)) {
      return;
    }

    var uuid = node.dataset.uuid ? node.dataset.uuid : (0, _string.randomString)(10);
    var width = node.width || node.style.width || '';
    var height = node.height || node.style.height || '';

    // 如果已经存在该uuid，重新生成一个
    if ((0, _$rjquery.$)('[data-uuid=' + uuid + ']').length > 0) {
      uuid = uuid + new Date().getTime();
    }
    var text = cc.lines.textOfLine(cc.lines.length() - 1);
    if (text && text.length > 0) {
      // 如果image前面有字符 startNewLine
      cc.startNewLine(state);
    }
    var taskId = void 0;
    var task = void 0;
    if (_this4.editable && /^data:/.test(src)) {
      if (taskId) {
        // 清理旧的taskId
        delete _this4.tasks[taskId];
      }

      taskId = (0, _string.randomString)(10);
      var taskData = { src: src };
      if (!cc.forPaste) {
        task = new _task.Base64Task(src);
        taskData.task = task;
      }
      _this4.tasks[taskId] = taskData;
      src = '';
    } else {
      taskId = node.getAttribute('data-task') || '';
    }
    var value = void 0;
    if (taskId) {
      value = '&uuid=' + uuid + '&pluginName=imageUpload&height=' + height + '&width=' + width + '&taskId=' + taskId;
      state.imageUploaded = ['image-previewer', value];
    } else {
      value = 'src=' + encodeURIComponent(src) + '&uuid=' + uuid + '&pluginName=imageUpload&height=' + height + '&width=' + width;
      state.imageUploaded = ['image-uploaded', value];
    }
    cc._recalcAttribString(state);
    cc.lines.appendText(' ', state.attribString);
    // 如果有下载任务，则开始下载
    if (!task) {
      return;
    }
    task.start().success(function (data) {
      var rep = editorInfo.ace_getRep();
      var docUrl = data.url,
          cdn_url = data.cdn_url,
          thumbnail_cdn_url = data.thumbnail_cdn_url,
          webp_thumbnail_cdn_url = data.webp_thumbnail_cdn_url,
          decrypt_key = data.decrypt_key;

      editorInfo.ace_callWithAce(function () {
        editorInfo.fastIncorp();
        var values = [(0, _util.createQueryString)({
          src: encodeURIComponent(docUrl),
          uuid: uuid,
          pluginName: _const.pluginName,
          height: height,
          width: width,
          decrypt_key: decrypt_key,
          cdn_url: cdn_url,
          thumbnail_cdn_url: thumbnail_cdn_url,
          webp_thumbnail_cdn_url: webp_thumbnail_cdn_url,
          taskId: taskId
        })];
        var attrs = [['image-uploaded', values]];
        var dom = (0, _$rjquery.$)('.image-previewer [data-task="' + taskId + '"]').closest('.image-previewer').get(0);
        var sel = editorInfo.ace_domToRep(dom);
        if (!sel) {
          return;
        }
        sel.selEnd[1] = sel.selEnd[1] + 1;
        editorInfo.ace_performDocumentReplaceRangeWithAttributes(rep.zoneId, sel.selStart, sel.selEnd, ' ', attrs);
      }, 'base64toImage', true);
    }).fail(function (e) {
      _toast2.default.show({
        type: 'error',
        closable: true,
        content: t('etherpad.upload_failed')
      });
      delete _this4.tasks[taskId];
      var dom = (0, _$rjquery.$)('.image-previewer [data-task="' + taskId + '"]').closest('.image-previewer').get(0);
      _image_view2.default.clearImagePreviewer(dom);
    }).progress(function (progress) {
      _image_view2.default.updateProgressStyle(uuid, progress);
    });
  };

  this.aceSelectionChanged = function (name, arg) {
    var rep = arg.rep;

    var lineNum = rep.selStart[0];
    var lineNode = rep.lines.atIndex(lineNum).lineNode;
    var $img = (0, _$rjquery.$)(lineNode).find('img');
    _image_view2.default.removeImageChooseStyle();
    _image_view2.default.removeGalleryChoosedStyle();
    if ($img.length === 1) {
      var id = (0, _$rjquery.$)(lineNode).find('.image-container').attr('id');
      _image_view2.default.addImageChooseStyle(id);
      if (!(0, _dom.isElementInViewport)(lineNode)) {
        // 图片如果不在视口，将图片调转到视口
        lineNode.scrollIntoView();
      }
    } else if ($img.length > 1) {
      _image_view2.default.addGalleryChoosedStyle(_this4.selectedGalleryItemId);
    }
  };

  this.aceCreateDomLine = function (name, context) {
    var spanClass = context.spanClass;
    if (new RegExp('"pluginName":"imageUpload"').test(spanClass)) {
      if (/key=gallery/.test(spanClass)) {
        // context.editable = false;
        // 展示图片
        var matcher = spanClass.match(/key=gallery[\S]+/);
        var galleryAttribs = matcher ? matcher[0] : '';
        var galleryItemsJSONString = galleryAttribs.split('&')[1];
        var galleryItems = JSON.parse(galleryItemsJSONString).items;
        var res = galleryItems.map(function (item, index) {
          var width = item.width,
              attachmentId = item.attachmentId,
              uuid = item.uuid;

          var src = decodeURIComponent(item.src);
          var pointsHTML = galleryItems.length === 1 ? _const.POINTS.map(function (pointID) {
            // 不包含 c (=center) 的点，即四个角的点
            if (!pointID.includes('c')) {
              return '<span class="point ' + pointID + ' n-icon-dragable"></span>';
            } else {
              return '<span class="point ' + pointID + '"></span>';
            }
          }).join('') : '';
          var keyReg = /\/file\/f\/(\w*)\//;
          var res = src.match(keyReg);
          var supportOfflineEdit = (0, _sdkCompatibleHelper.isSupportOfflineEdit)();
          var needToIgnore = _this4[_const.uploadPrefix + '-ignore-' + uuid];
          // 离线化/截图服务 不使用图片前端解密
          var needTodecode = res && !_this4.decodeImages[uuid] && !supportOfflineEdit && !(0, _shortCut.isShortCut)();
          var itemsCount = galleryItems.length;
          var GuideSelector = '';
          if (_this4.shouldShowGuide) {
            GuideSelector = 'data-selector="galleryUserGuide"';
            _this4.shouldShowGuide = false;
          }

          if (needTodecode) {
            _this4.workerPostMsg(item, res[1], src);
          }

          var isSupportOfflineIosApp = _browserHelper2.default.ios && supportOfflineEdit;
          // ios app将协议替换成docsource
          src = isSupportOfflineIosApp ? src.replace(/https?:/, location.protocol) : src;
          // 兼容老图片url  host//file/xxx
          src = src.replace(/\/\/file/, '/file');

          var editorInfo = _this4.editorInfo;

          var isLoaded = _this4.decodeImages[uuid] && _this4.decodeImages[uuid].finished;
          // !!hack 没有editorInfo的时候，就是在历史记录里面
          var containerBox = editorInfo ? editorInfo.ace_getInnerContainer() : document.querySelector('.doc-history-revert__content.innerdocbody') || document.querySelector('.history-list');
          var docWidth = containerBox.offsetWidth;
          var isInHistory = editorInfo.pure;
          var mask = ('\n          <div class="history-deleted-mask" style="z-index: 1">\n            <div class="history-deleted-mask_text">' + t('history.deleted') + '</div>\n          </div>').trim();
          var style = (width === '100%' || parseInt(width) >= docWidth) && !isLoaded && !needToIgnore && needTodecode ? 'style="width:' + docWidth + 'px;height:' + docWidth * HEIGHT_RATE + 'px"' : '';
          // 非 worker 请求不需要loading
          var shouldShowLoading = !isLoaded && !needToIgnore && needTodecode && !isInHistory;
          var loading = shouldShowLoading ? '<i class="image-loading layout-main-cross-center"><em></em></i>' : '';
          // 兼容其他情况
          var imageSrc = !needTodecode ? 'src=\'' + src + '\'' : '';
          // 防止 IE 下图片出现缩放控件
          var notContentEditableOnIE = _browserHelper2.default.modernIE ? 'contenteditable="false"' : '';
          var comments = item.comments.join(' ') || '';
          var dynamicFlex = itemsCount > 1 ? (0, _util.toFixedNumber)(item.scale, 4) : 1;
          var multiImgs = itemsCount > 1 ? 'multi-images' : '';
          // 移动端gallery禁止长按选中文字效果
          // const unselectable = !browser.isMobile ? 'user-select:none;-webkit-user-select:none;' : '';
          var flexStyle = itemsCount > 1 ? 'style="flex: ' + dynamicFlex + ' 1 0%;max-width: 100%; width: auto !important;' + '"' : '';
          var flexImgStyle = flexStyle && 'height: 100% !important;position: absolute;left: 0;top: 0;position: absolute;left: 0;top: 0;';
          var flexImgContainerStyle = 'style="width:100%;' + 'padding-top:' + (0, _util.toFixedNumber)(1 / dynamicFlex * 100, 4) + '%;height:0;"';
          // 标签之间请勿换行, 会导致选中图片时anchorNode为文字
          return '<div draggable="false" id="container-wrap-' + _const.uploadPrefix + '-image-' + uuid + '"\n            class="image-container-wrap" data-faketext=" "\n            ' + notContentEditableOnIE + ' ' + attachmentId + '\n            data-gallery-index=' + index + ' ' + flexStyle + '><div id=\'' + _const.uploadPrefix + '-image-' + uuid + '\'\n            class=\'image-container ' + comments + ' ' + multiImgs + '\' ' + (style || flexStyle && flexImgContainerStyle) + '\n            data-dynamicFlex=' + item.scale + '\n            >' + loading + (isInHistory ? mask : '') + '<img data-uuid="' + uuid + '"\n            data-src="' + src + '" ' + imageSrc + ' ' + GuideSelector + '\n        style=\'' + (flexImgStyle || 'width:' + width) + '\'/>' + pointsHTML + '</div></div>';
        });
        context.spanClass += ' image-uploaded';
        context.attributes['data-ace-gallery-json'] = galleryItemsJSONString;
        context.rawHtml = '<div class="gallery">' + _this4.generateDropImageHint('edge-left') + res.join(_this4.generateDropImageHint('middle')) + _this4.generateDropImageHint('edge-right') + '</div>';
      }
    }
    if ((0, _util.isImageUploadPlugin)(spanClass)) {
      // context.editable = false;
      context.lineClass += ' single-line';
      // 之前上传的cls pluginName 换行了
      spanClass = spanClass.replace(/pluginName=imageUpload\s*/, 'pluginName=imageUpload');

      var _matcher = spanClass.match(/key=image-[\S]+/);
      var uploadAttrs = _matcher ? _matcher[0] : '';
      var attrsObj = (0, _utils.toObj)(uploadAttrs);

      // 如果是完成 map成img标签 展示图片
      if (attrsObj.key === 'image-uploaded') {
        var width = attrsObj.width;

        var src = void 0;
        try {
          src = decodeURIComponent(attrsObj.src);
        } catch (e) {
          console.error('Failed to decode base64 image:', e);
          src = '';
        }
        var uuid = attrsObj.uuid;
        var taskId = attrsObj.taskId;

        if (!uuid) {
          // Word导入Docs后的图片数据异常，导致无法获取正确的uuid
          var reg = /uuid=([\w\d-]*)/;
          var _res2 = spanClass.match(reg);
          if (_res2) {
            attrsObj.uuid = uuid = _res2[1];
          }
        }

        var pointsHTML = _const.POINTS.map(function (pointID) {
          // 不包含 c (=center) 的点，即四个角的点
          if (!pointID.includes('c')) {
            return '<span class="point ' + pointID + ' n-icon-dragable"></span>';
          } else {
            return '<span class="point ' + pointID + '"></span>';
          }
        }).join('');
        var keyReg = /\/file\/f\/(\w*)\//;
        var _res = src.match(keyReg);
        var supportOfflineEdit = (0, _sdkCompatibleHelper.isSupportOfflineEdit)();
        var needToIgnore = _this4[_const.uploadPrefix + '-ignore-' + uuid];
        // 获取存储的base64数据
        var taskData = taskId ? _this4.tasks[taskId] || {} : {};
        var base64Src = taskData.src || '';
        // 清理缓存
        taskId && delete _this4.tasks[taskId];
        // 离线化/截图服务 不使用图片前端解密
        var needTodecode = !base64Src && _res && !_this4.decodeImages[uuid] && !supportOfflineEdit && !(0, _shortCut.isShortCut)();
        if (needTodecode) {
          _this4.workerPostMsg(attrsObj, _res[1], src);
        }

        var isSupportOfflineIosApp = _browserHelper2.default.ios && supportOfflineEdit && isDocsPictureUrl(src);
        // ios app将协议替换成docsource
        src = isSupportOfflineIosApp ? src.replace(/https?:/, location.protocol) : src;

        var editorInfo = _this4.editorInfo;

        var isLoaded = _this4.decodeImages[uuid] && _this4.decodeImages[uuid].finished;
        // !!hack 没有editorInfo的时候，就是在历史记录里面
        // 之前是没有editorInfo, 现在历史记录用editor渲染，但是是pure, 可以用这个进行判断
        // const isInHistory = !editorInfo;
        var isInHistory = editorInfo.pure;
        var containerBox = !isInHistory ? editorInfo.ace_getInnerContainer() : document.querySelector('.doc-history-revert__content.innerdocbody, .history-list');
        var docWidth = containerBox.offsetWidth;
        var mask = ('\n<div class="history-deleted-mask">\n  <div class="history-deleted-mask_text">' + t('history.deleted') + '</div>\n</div>').trim();
        var shouldShowLoading = !isLoaded && !needToIgnore && needTodecode && !isInHistory;

        var style = (width === '100%' || parseInt(width) >= docWidth) && shouldShowLoading ? 'style="width:' + docWidth + 'px;height:' + docWidth * HEIGHT_RATE + 'px"' : '';
        // 非 worker 请求不需要loading
        var loading = shouldShowLoading ? '<i class="image-loading layout-main-cross-center"><em></em></i>' : '';
        // 兼容其他情况
        var imageSrc = !needTodecode ? 'src=' + (base64Src || src) : '';
        // 防止 IE 下图片出现缩放控件
        var notContentEditableOnIE = _browserHelper2.default.modernIE ? 'contenteditable="false"' : '';
        context.spanClass += ' image-uploaded';
        context.rawHtml = '<div draggable="false" id="container-wrap-' + _const.uploadPrefix + '-image-' + uuid + '"\n          class="image-container-wrap" data-faketext="' + context.text + '"\n          ' + notContentEditableOnIE + '><div id=\'' + _const.uploadPrefix + '-image-' + uuid + '\'\n          class=\'image-container\'' + style + '>' + loading + (isInHistory ? mask : '') + '<img data-uuid=' + uuid + '\n          data-src="' + src + '" ' + imageSrc + '\n          style=\'width:' + width + ';\'/>' + pointsHTML + '</div></div>';
      }

      // 图片预览
      if (attrsObj.key === 'image-previewer') {
        var _uuid = attrsObj.uuid,
            _width = attrsObj.width;

        var _taskId = attrsObj.taskId;
        var _pointsHTML = _const.POINTS.map(function (item) {
          if (item === 'br') {
            return '<span class="point ' + item + ' n-icon-dragable"></span>';
          } else {
            return '<span class="point ' + item + '"></span>';
          }
        }).join('');

        var _taskData = _taskId ? _this4.tasks[_taskId] || {} : {};
        var _base64Src = _taskData.src || _this4[_const.uploadPrefix + '-base64-src-' + _uuid];
        var _src = _base64Src ? 'src=' + _base64Src : '';
        delete _this4[_const.uploadPrefix + '-base64-src-' + _uuid];

        var placeholder = '<div class=\'placeholder-wrap layout-main-cross-center\'><div\n                                id=\'' + _const.uploadPrefix + '-holder-' + _uuid + '\'\n                                class=\'upload-progress flex\' contenteditable=\'false\'><span\n                                class=\'upload-progress-bar\' contenteditable=\'false\'></span>';
        var dataTask = _taskId ? 'data-task=' + _taskId : '';
        context.spanClass += ' image-previewer';
        context.rawHtml = '<div draggable="false" id="container-wrap-' + _const.uploadPrefix + '-image-' + _uuid + '"\n        class="image-container-wrap"><div id=\'' + _const.uploadPrefix + '-image-' + _uuid + '\'\n        class=\'image-container\'><img data-uuid=' + _uuid + ' ' + _src + ' ' + dataTask + '\n        style=\'width:' + _width + ';\'/>' + _pointsHTML + placeholder + '</div></div></div></div>';
      }
    }
  };

  this.generateDropImageHint = function (direction) {
    return '<div class="gallery-drop-hint-container ignore-collect gallery-drop-hint-container-col"\n    data-faketext=" "\n    ><div class="gallery-drop-hint gallery-drop-hint-' + direction + '"\n    aria-hidden="true" role="presentation" data-faketext=" "></div></div>';
  };

  this.setSrcWithoutRecord = function ($img, src) {
    if (!_this4.editorInfo) {
      return $img.attr('src', src);
    }

    _this4.editorInfo.getObserver().withoutRecordingMutations(function () {
      $img.attr('src', src);
      var $parent = $img.parents('div[id^=magicdomid]');
      if ($parent[0]) {
        _this4.markNodeClean($parent[0]);
      }
    });
  };

  this.onMount = function (hook, context) {
    (0, _$rjquery.$)(context.editor.ace_getInnerContainer()).find('.image-container > img[src]').each(function (index, element) {
      _this4._bindImageCompleteEvent((0, _$rjquery.$)(element));
    });
    if (_this4.galleryComment) {
      _this4.galleryComment.onMount();
    }
  };

  this.processAfterInsertNode = function (hook, context) {
    var $lineNode = (0, _$rjquery.$)(context.entry.lineNode);
    var $img = $lineNode.find('.image-container > img[src]');
    if ($img.length) {
      _this4._bindImageCompleteEvent($img);
    }
    // 防止 IE 下图片那行出现缩放控件
    if (_browserHelper2.default.isIE && $lineNode.has('.image-container img').length > 0) {
      $lineNode.off('mscontrolselect', cancelEvent);
      $lineNode.on('mscontrolselect', cancelEvent);
    }
  };

  this._bindImageCompleteEvent = function ($img) {
    var fn = function fn(e) {
      var uuid = (0, _$rjquery.$)(e.target).data('uuid');
      _this4.handleAfterImgLoaded({ uuid: uuid });
    };
    $img.on('load', fn);
    $img.on('error', fn);
  };

  this.workerPostMsg = function (attrsObj, key, originSrc) {
    var uuid = attrsObj.uuid,
        cu = attrsObj.cdn_url,
        tcu = attrsObj.thumbnail_cdn_url,
        wtcu = attrsObj.webp_thumbnail_cdn_url,
        decryptKey = attrsObj.decrypt_key;


    _this4.decodeImages[uuid] = { finished: false };

    var url = _browserHelper2.default.mobile && (0, _util.toUndefined)(wtcu) || (0, _util.toUndefined)(tcu) || (0, _util.toUndefined)(cu);

    if (_browserHelper2.default.isIE || !(0, _util.isSupportCoder)()) {
      ImageDecodeWorker.postMessage(JSON.stringify({ key: key, uuid: uuid, url: url, decryptKey: decryptKey, pluginId: _this4.pluginId }));
    } else {
      var enc = new TextEncoder();
      var buf = enc.encode(JSON.stringify({
        key: key,
        uuid: uuid,
        url: url,
        decryptKey: decryptKey,
        pluginId: _this4.pluginId,
        apiPrefix: _apiUrls.API_PREFIX
      }));
      ImageDecodeWorker.postMessage(buf.buffer, [buf.buffer]);
    }

    _this4.log('dev_stability_image_base64', {
      origin_src: originSrc,
      file_id: (0, _tea.getEncryToken)(),
      file_type: (0, _tea.getFileType)()
    });
  };

  this.linesWillReplace = function (hook, _ref6) {
    var oldLineEntries = _ref6.oldLineEntries,
        newLineEntries = _ref6.newLineEntries;

    // 跳过初始化
    // TODO 使用 editor 后就可以去掉了
    if (oldLineEntries[0] && oldLineEntries[0].key === 'magicdomid1') {
      return;
    }

    (0, _forEach3.default)(newLineEntries, function (_ref7) {
      var lineNode = _ref7.lineNode;

      var $container = (0, _$rjquery.$)(lineNode).find('.image-uploaded .image-container-wrap');
      // gallery存在多个images情况,因此多加一层遍历
      (0, _forEach3.default)($container, function (node) {
        var newEntryId = (0, _$rjquery.$)(node).attr('id');
        var hasSet = false;
        var $img = (0, _$rjquery.$)(node).find('img');
        var matches = newEntryId.match(/image-upload-image-(.*)/);
        if (matches) {
          var uuid = matches[1];
          if (_this4.decodeImages[uuid] && !_this4.decodeImages[uuid].finished) {
            return;
          }
        }

        (0, _forEach3.default)(oldLineEntries, function (oldEntry) {
          if (hasSet) return;
          var $oldImg = (0, _$rjquery.$)(oldEntry.lineNode).find('#' + newEntryId + ' img');
          var oldSrc = $oldImg.length && $oldImg.attr('src');
          if (oldSrc) {
            hasSet = true;
            _this4.setSrcWithoutRecord($img, oldSrc);
            _this4.markNodeClean(lineNode);
          }
        });

        // undo redo时，oldLineEntries可能没有img，直接降级处理
        if (!hasSet) {
          _this4.setSrcWithoutRecord($img, $img.attr('data-src'));
        }
      });
    });
  };

  this.aceAfterCompositionEnd = function () {
    // TODO 将下面的 $('.gallery-drop-hint').text(''); 移到这里，就不需要 setTimeout
    // 目前是因为 editor 那边的 bug， 没有调用这个 hook
  };

  this.isThisLineImage = function (editorInfo) {
    // fastIncorp之后才能用rep上的数据。
    editorInfo.fastIncorp();
    var rep = editorInfo.ace_getRep();
    var lineNum = rep.selStart[0];
    return (0, _util.isImageLine)(rep, lineNum);
  };

  this.setSelectionOnImage = function (lineNum) {
    var editorInfo = _this4.editorInfo;

    var rep = editorInfo.getRep();
    editorInfo.inCallStackIfNecessary('imageFocus', function () {
      var start = new _bytedXEditor.Position(rep.zoneId, lineNum, 0);
      var end = new _bytedXEditor.Position(rep.zoneId, lineNum, 1);
      editorInfo.selection.set({ start: start, end: end });
      editorInfo.selection.internalUpdateSelectionFromRep(true);
    });
  };

  this.doReturn = function (rep, editorInfo) {
    var lineNum = rep.selStart[0];
    var lineEntry = rep.lines.atIndex(lineNum);

    var selStart = [lineNum, lineEntry.text.length];
    var selEnd = [lineNum, lineEntry.text.length];
    // 临时改下选区 让selectionChange生效
    // rep.selStart = selStart;
    // rep.selEnd = selEnd;
    editorInfo.ace_performDocumentReplaceRange(rep.zoneId, selStart, selEnd, '\n');
    editorInfo.selection.setWithSelection(rep.zoneId, [lineNum + 1, 0], [lineNum + 1, 0], false);
    editorInfo.ace_updateBrowserSelectionFromRep();
  };

  this.aceCutReplaceSelection = function (hook, context) {
    var attrs = _this4.editorInfo.getAttributesOnLine('0', context.rep.selStart[0]);
    var hasGallery = void 0;
    attrs.forEach(function (attr) {
      if (attr[0] === 'gallery') {
        hasGallery = true;
      }
    });
    if (hasGallery) return true;
  };

  this.doCut = function (rep, lineNum, editorInfo, context) {
    var $img = _this4.getImageSel();
    if ($img.length) {
      var evt = context.e;
      evt.preventDefault();
      var deleteItemId = '#' + (0, _$rjquery.$)('#galleryTempStyle').attr('data-id');
      var IndexOfDeleteItem = (0, _$rjquery.$)(deleteItemId).closest('.image-container-wrap').attr('data-gallery-index');
      _image_view2.default.setRangeOnCloneImage($img.get(0), evt);
      document.execCommand('cut');
      // 触发 selectionchange
      if (!editorInfo.spliceGalleryItemsAtLine(rep.zoneId, lineNum, parseInt(IndexOfDeleteItem), 1)) {
        _this4.performDelete(lineNum, context);
      }
    }
  };

  this.doDelete = function (rep, editorInfo, evt, context) {
    // android 删除图片不会清理菜单，手动触发
    _sdkCompatibleHelper.isSupportCustomMenu && _eventEmitter2.default.trigger(_constants2.events.MOBILE.CONTEXT_MENU.closeContextMenu);
    var selStart = rep.selStart,
        selEnd = rep.selEnd;

    var lineNum = selStart[0];
    var lineEntry = rep.lines.atIndex(lineNum);
    var prevLine = lineNum - 1;
    var thisLineIsImage = (0, _util.isImageLine)(rep, lineNum);
    var thisLineIsImagePreviewer = _this4.isImagePreviewerLine(lineNum);
    var thisPreLineIsImagePreviewer = _this4.isImagePreviewerLine(lineNum - 1);
    // 光标处于行首 且上一行为image  pc选中上一行 mobile 删除上一行的图片
    if (selStart[1] === 0 && selEnd[1] === 0 && !thisPreLineIsImagePreviewer && (0, _util.isImageLine)(rep, prevLine)) {
      context.preventOtherHooksHandle = true;
      var prevLineNode = (0, _get3.default)(rep.lines.atIndex(prevLine), 'lineNode');
      var imgCount = (0, _$rjquery.$)(prevLineNode).find('img').length;
      if (_browserHelper2.default.isMobile) {
        // this.performDelete(prevLine, context);
        if (!editorInfo.spliceGalleryItemsAtLine(rep.zoneId, prevLine, imgCount - 1, 1, null, false)) {
          _this4.performDelete(prevLine, context);
        }
        evt.preventDefault();
        return true;
      } else {
        var $choosenImg = (0, _$rjquery.$)((0, _$rjquery.$)(prevLineNode).find('img')[imgCount - 1]);
        _this4.selectedGalleryItemId = (0, _$rjquery.$)($choosenImg).parents('.image-container').attr('id');
        // 加timeout 否则会导致caretLine更新 删除错行
        setTimeout(function () {
          $choosenImg.click();
        });
      }
      var isThisLineIsText = (0, _get3.default)(lineEntry, 'text.length') > 0 && !thisLineIsImage;
      var isLastLine = selStart[0] === selEnd[0] && selStart[0] === rep.lines.length() - 1;

      // 如果本行有其他内容 则不要将本行与图片那行内容合并 否则光标移动有问题 || 如果为最后一行 则不要删除
      if (isThisLineIsText || isLastLine) {
        evt.preventDefault();
        return true;
      }
    }

    // 上传一张图片，还在加载过程中将其删除
    if (selStart[1] === 0 && selEnd[1] === 0 && thisPreLineIsImagePreviewer && !thisLineIsImage) {
      _this4.performDelete(lineNum - 1, context);
      evt.preventDefault();
      return true;
    }

    if (thisLineIsImage || thisLineIsImagePreviewer) {
      var deleteItemId = '#' + (0, _$rjquery.$)('#galleryTempStyle').attr('data-id');
      var $imgContainerWrap = (0, _$rjquery.$)(deleteItemId).closest('.image-container-wrap');
      var IndexOfDeleteItem = $imgContainerWrap.attr('data-gallery-index');
      if (!editorInfo.spliceGalleryItemsAtLine(rep.zoneId, lineNum, parseInt(IndexOfDeleteItem), 1, null, true)) {
        _this4.performDelete(lineNum, context);
      }
      (0, _$rjquery.$)('.comment-line-popup').removeClass('comment-line-popup_active');
      evt.preventDefault();
      return true;
    }

    if (thisLineIsImagePreviewer && prevLine === 0) {
      // 如果第二行有张图片，第三行是图片的placehoder,当第二行图片删掉
      // 则光标定位在第三行的placeholder的前面，在按删除键placeholder就会跑到第一行标题中
      // 处理成光标在placehoder且前面一行是标题行，则光标定位在标题行的末尾
      var preLineEntry = rep.lines.atIndex(prevLine);
      var sel = [prevLine, preLineEntry.text.length];
      rep.selStart = rep.selEnd = sel;
      editorInfo.ace_updateBrowserSelectionFromRep();
    }
  };

  this.aceAfterPaste = function (name, context) {
    var e = context.e;

    var clipboardData = e.originalEvent.clipboardData || window.clipboardData;
    if (!clipboardData) {
      return;
    }
    var items = clipboardData.items || null;
    if (items) {
      for (var i = 0, len = items.length; i < len; i++) {
        if (items[i].kind === 'file') {
          var file = items[i].getAsFile();
          if (items[i].kind === 'file' && file.size > _const.IMAGE_MAX_SIZE) {
            _this4.uploader && (_this4.uploader.pasteOverSized = true);
            return;
          }
        }
      }
    }
    var files = clipboardData.files || null;
    if (!items && files) {
      for (var _i = 0, _len = files.length; _i < _len; _i++) {
        if (files[_i].size > _const.IMAGE_MAX_SIZE) {
          _this4.uploader && (_this4.uploader.pasteOverSized = true);
          return;
        }
      }
    }
    // 目前禁止选中图片后粘贴内容上去
    var rep = context.rep;

    if (rep.selStart[0] === rep.selEnd[0] && (0, _util.isImageLine)(rep, rep.selStart[0])) context.html = null;
  };

  this.afterPasteInsert = function (name, context) {
    // note: 插入一行图片后，新起一行并更新光标。
    var editorInfo = context.editorInfo;

    var rep = editorInfo.getRep();
    var curLine = rep.selStart[0];
    if (editorInfo.ace_isImageLine(rep.zoneId, curLine) && context.html) {
      var lineLen = rep.lines.atIndex(curLine).text.length;
      editorInfo.ace_performDocumentReplaceRangeWithAttributes(rep.zoneId, [curLine, lineLen], [curLine, lineLen], '\n', []);
      editorInfo.ace_updateBrowserSelectionFromRep();
    }
  };

  this.performDelete = function (lineNum, context) {
    var editorInfo = _this4.editorInfo;

    var rep = editorInfo.ace_getRep();
    var lineEntry = rep.lines.atIndex(lineNum);
    var preLine = lineNum - 1 >= 0 ? lineNum - 1 : 0;
    var preLineEntry = rep.lines.atIndex(preLine);
    if (lineEntry) {
      var textLen = lineEntry.text.length;
      context.preventOtherHooksHandle = true;
      if (!lineNum) {
        // 某些极端情况图片会在标题
        editorInfo.ace_performDocumentReplaceRange(rep.zoneId, [lineNum, 0], [lineNum, textLen], '');
        return;
      }
      editorInfo.ace_performDocumentReplaceRange(rep.zoneId, [preLine, preLineEntry.text.length], [lineNum, textLen], '');
    }
  };

  this.getImageSel = function () {
    var imgContainer = _image_view2.default.getChosenGalleryContainer() || _image_view2.default.getChosenImgContainer();
    return (0, _$rjquery.$)(imgContainer).find('img');
  };

  this.handleGalleryItemsChoosed = function (imageId) {
    _this4.selectedGalleryItemId = imageId;
    if (_this4.galleryComment) {
      _this4.galleryComment.setSelectedImageUUID(_this4.selectedGalleryItemIdToImageUUID(imageId));
    }
  };

  this.selectedGalleryItemIdToImageUUID = function (galleryItemId) {
    return galleryItemId && galleryItemId.replace('image-upload-image-', '');
  };

  this.handleRemoveImageChooseStyle = function () {
    _image_view2.default.removeImageChooseStyle();
    _image_view2.default.removeGalleryChoosedStyle();
  };

  this.pluginReadOnly = function (hook, context) {
    var editorInfo = _this4.ace.editorInfo;

    _this4.editable = false;
    var innerdoc = editorInfo.ace_getInnerContainer();
    // 阻止无编辑权限时拖动图片，有可能被拖到其他dom上，被dirtycheck检测到,产生cs
    (0, _$rjquery.$)(innerdoc).undelegate('.image-uploaded img', 'dragstart', _this4.handleDragStart);
    (0, _$rjquery.$)(innerdoc).delegate('.image-uploaded img', 'dragstart', _this4.handleDragStart);
    editorInfo.off('galleryImageChoosed', _this4.handleGalleryItemsChoosed);
    editorInfo.on('galleryImageChoosed', _this4.handleGalleryItemsChoosed);
    editorInfo.off('galleryImageUnselect', _this4.handleRemoveImageChooseStyle);
    editorInfo.on('galleryImageUnselect', _this4.handleRemoveImageChooseStyle);
  };

  this.pluginReadWrite = function (hook, context) {
    var editorInfo = _this4.ace.editorInfo;

    _this4.editable = true;
    var innerdoc = editorInfo.ace_getInnerContainer();
    (0, _$rjquery.$)(innerdoc).undelegate('.image-uploaded img', 'dragstart', _this4.handleDragStart);
    editorInfo.on('galleryImageChoosed', _this4.handleGalleryItemsChoosed);
    editorInfo.on('imageUploadSuccess', _this4.handleImageUploaded);
    editorInfo.on('galleryImageUnselect', _this4.handleRemoveImageChooseStyle);
  };

  this.handleImageUploaded = function () {
    if (!_this4.editorInfo.pure && _this4.shouldShowGuide === undefined && !_browserHelper2.default.isMobile) {
      _this4.shouldShowGuide = true;
      setTimeout(function () {
        (0, _onboarding.addSteps)(_onboarding2.STEP_TYPES.gallery_image_guide);
      }, 200);
    }
  };

  this.changesetApply = function () {
    // 老版本客户端不支持图片协同
    if (_this4.galleryComment) {
      _this4.galleryComment.changesetApply();
    }
  };

  this.editorRenderEnd = function () {
    _this4.firstScreenRenderEnd = true;
    _this4.commentRenderQueue && _this4.commentRenderQueue.forEach(function (func) {
      return func();
    });
  };

  this.blockRenderAsyncNodesLoaded = function () {
    if (_this4.galleryComment) {
      if (_this4.firstScreenRenderEnd) {
        _this4.galleryComment.blockRenderAsyncNodesLoaded();
      } else {
        // 首屏还没有渲染完成，延迟处理图片评论
        _this4.commentRenderQueue.push(function () {
          setTimeout(function () {
            _this4.galleryComment.blockRenderAsyncNodesLoaded();
          }, 50);
        });
      }
    }
  };

  this.handleDocTokenChange = function () {
    if (_this4.galleryComment) {
      _this4.galleryComment.updateServiceToken();
    }
  };
}, _temp)) || _class);
exports.default = ImageUpload;
;

function isDocsPictureUrl(url) {
  var isDocsUrl = /\/file\/f\/(\w*)\//.test(url);
  return isDocsUrl;
}
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(25)))

/***/ }),

/***/ 3821:
/***/ (function(module, exports, __webpack_require__) {

module.exports = function() {
  return __webpack_require__(783)("/******/ (function(modules) { // webpackBootstrap\n/******/ \t// The module cache\n/******/ \tvar installedModules = {};\n/******/\n/******/ \t// The require function\n/******/ \tfunction __webpack_require__(moduleId) {\n/******/\n/******/ \t\t// Check if module is in cache\n/******/ \t\tif(installedModules[moduleId]) {\n/******/ \t\t\treturn installedModules[moduleId].exports;\n/******/ \t\t}\n/******/ \t\t// Create a new module (and put it into the cache)\n/******/ \t\tvar module = installedModules[moduleId] = {\n/******/ \t\t\ti: moduleId,\n/******/ \t\t\tl: false,\n/******/ \t\t\texports: {}\n/******/ \t\t};\n/******/\n/******/ \t\t// Execute the module function\n/******/ \t\tmodules[moduleId].call(module.exports, module, module.exports, __webpack_require__);\n/******/\n/******/ \t\t// Flag the module as loaded\n/******/ \t\tmodule.l = true;\n/******/\n/******/ \t\t// Return the exports of the module\n/******/ \t\treturn module.exports;\n/******/ \t}\n/******/\n/******/\n/******/ \t// expose the modules object (__webpack_modules__)\n/******/ \t__webpack_require__.m = modules;\n/******/\n/******/ \t// expose the module cache\n/******/ \t__webpack_require__.c = installedModules;\n/******/\n/******/ \t// define getter function for harmony exports\n/******/ \t__webpack_require__.d = function(exports, name, getter) {\n/******/ \t\tif(!__webpack_require__.o(exports, name)) {\n/******/ \t\t\tObject.defineProperty(exports, name, { enumerable: true, get: getter });\n/******/ \t\t}\n/******/ \t};\n/******/\n/******/ \t// define __esModule on exports\n/******/ \t__webpack_require__.r = function(exports) {\n/******/ \t\tif(typeof Symbol !== 'undefined' && Symbol.toStringTag) {\n/******/ \t\t\tObject.defineProperty(exports, Symbol.toStringTag, { value: 'Module' });\n/******/ \t\t}\n/******/ \t\tObject.defineProperty(exports, '__esModule', { value: true });\n/******/ \t};\n/******/\n/******/ \t// create a fake namespace object\n/******/ \t// mode & 1: value is a module id, require it\n/******/ \t// mode & 2: merge all properties of value into the ns\n/******/ \t// mode & 4: return value when already ns object\n/******/ \t// mode & 8|1: behave like require\n/******/ \t__webpack_require__.t = function(value, mode) {\n/******/ \t\tif(mode & 1) value = __webpack_require__(value);\n/******/ \t\tif(mode & 8) return value;\n/******/ \t\tif((mode & 4) && typeof value === 'object' && value && value.__esModule) return value;\n/******/ \t\tvar ns = Object.create(null);\n/******/ \t\t__webpack_require__.r(ns);\n/******/ \t\tObject.defineProperty(ns, 'default', { enumerable: true, value: value });\n/******/ \t\tif(mode & 2 && typeof value != 'string') for(var key in value) __webpack_require__.d(ns, key, function(key) { return value[key]; }.bind(null, key));\n/******/ \t\treturn ns;\n/******/ \t};\n/******/\n/******/ \t// getDefaultExport function for compatibility with non-harmony modules\n/******/ \t__webpack_require__.n = function(module) {\n/******/ \t\tvar getter = module && module.__esModule ?\n/******/ \t\t\tfunction getDefault() { return module['default']; } :\n/******/ \t\t\tfunction getModuleExports() { return module; };\n/******/ \t\t__webpack_require__.d(getter, 'a', getter);\n/******/ \t\treturn getter;\n/******/ \t};\n/******/\n/******/ \t// Object.prototype.hasOwnProperty.call\n/******/ \t__webpack_require__.o = function(object, property) { return Object.prototype.hasOwnProperty.call(object, property); };\n/******/\n/******/ \t// __webpack_public_path__\n/******/ \t__webpack_require__.p = \"//s3.pstatp.com/eesz/resource/bear/\";\n/******/\n/******/\n/******/ \t// Load entry module and return exports\n/******/ \treturn __webpack_require__(__webpack_require__.s = 12);\n/******/ })\n/************************************************************************/\n/******/ ([\n/* 0 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory();\n\t}\n\telse {}\n}(this, function () {\n\n\t/**\n\t * CryptoJS core components.\n\t */\n\tvar CryptoJS = CryptoJS || (function (Math, undefined) {\n\t    /*\n\t     * Local polyfil of Object.create\n\t     */\n\t    var create = Object.create || (function () {\n\t        function F() {};\n\n\t        return function (obj) {\n\t            var subtype;\n\n\t            F.prototype = obj;\n\n\t            subtype = new F();\n\n\t            F.prototype = null;\n\n\t            return subtype;\n\t        };\n\t    }())\n\n\t    /**\n\t     * CryptoJS namespace.\n\t     */\n\t    var C = {};\n\n\t    /**\n\t     * Library namespace.\n\t     */\n\t    var C_lib = C.lib = {};\n\n\t    /**\n\t     * Base object for prototypal inheritance.\n\t     */\n\t    var Base = C_lib.Base = (function () {\n\n\n\t        return {\n\t            /**\n\t             * Creates a new object that inherits from this object.\n\t             *\n\t             * @param {Object} overrides Properties to copy into the new object.\n\t             *\n\t             * @return {Object} The new object.\n\t             *\n\t             * @static\n\t             *\n\t             * @example\n\t             *\n\t             *     var MyType = CryptoJS.lib.Base.extend({\n\t             *         field: 'value',\n\t             *\n\t             *         method: function () {\n\t             *         }\n\t             *     });\n\t             */\n\t            extend: function (overrides) {\n\t                // Spawn\n\t                var subtype = create(this);\n\n\t                // Augment\n\t                if (overrides) {\n\t                    subtype.mixIn(overrides);\n\t                }\n\n\t                // Create default initializer\n\t                if (!subtype.hasOwnProperty('init') || this.init === subtype.init) {\n\t                    subtype.init = function () {\n\t                        subtype.$super.init.apply(this, arguments);\n\t                    };\n\t                }\n\n\t                // Initializer's prototype is the subtype object\n\t                subtype.init.prototype = subtype;\n\n\t                // Reference supertype\n\t                subtype.$super = this;\n\n\t                return subtype;\n\t            },\n\n\t            /**\n\t             * Extends this object and runs the init method.\n\t             * Arguments to create() will be passed to init().\n\t             *\n\t             * @return {Object} The new object.\n\t             *\n\t             * @static\n\t             *\n\t             * @example\n\t             *\n\t             *     var instance = MyType.create();\n\t             */\n\t            create: function () {\n\t                var instance = this.extend();\n\t                instance.init.apply(instance, arguments);\n\n\t                return instance;\n\t            },\n\n\t            /**\n\t             * Initializes a newly created object.\n\t             * Override this method to add some logic when your objects are created.\n\t             *\n\t             * @example\n\t             *\n\t             *     var MyType = CryptoJS.lib.Base.extend({\n\t             *         init: function () {\n\t             *             // ...\n\t             *         }\n\t             *     });\n\t             */\n\t            init: function () {\n\t            },\n\n\t            /**\n\t             * Copies properties into this object.\n\t             *\n\t             * @param {Object} properties The properties to mix in.\n\t             *\n\t             * @example\n\t             *\n\t             *     MyType.mixIn({\n\t             *         field: 'value'\n\t             *     });\n\t             */\n\t            mixIn: function (properties) {\n\t                for (var propertyName in properties) {\n\t                    if (properties.hasOwnProperty(propertyName)) {\n\t                        this[propertyName] = properties[propertyName];\n\t                    }\n\t                }\n\n\t                // IE won't copy toString using the loop above\n\t                if (properties.hasOwnProperty('toString')) {\n\t                    this.toString = properties.toString;\n\t                }\n\t            },\n\n\t            /**\n\t             * Creates a copy of this object.\n\t             *\n\t             * @return {Object} The clone.\n\t             *\n\t             * @example\n\t             *\n\t             *     var clone = instance.clone();\n\t             */\n\t            clone: function () {\n\t                return this.init.prototype.extend(this);\n\t            }\n\t        };\n\t    }());\n\n\t    /**\n\t     * An array of 32-bit words.\n\t     *\n\t     * @property {Array} words The array of 32-bit words.\n\t     * @property {number} sigBytes The number of significant bytes in this word array.\n\t     */\n\t    var WordArray = C_lib.WordArray = Base.extend({\n\t        /**\n\t         * Initializes a newly created word array.\n\t         *\n\t         * @param {Array} words (Optional) An array of 32-bit words.\n\t         * @param {number} sigBytes (Optional) The number of significant bytes in the words.\n\t         *\n\t         * @example\n\t         *\n\t         *     var wordArray = CryptoJS.lib.WordArray.create();\n\t         *     var wordArray = CryptoJS.lib.WordArray.create([0x00010203, 0x04050607]);\n\t         *     var wordArray = CryptoJS.lib.WordArray.create([0x00010203, 0x04050607], 6);\n\t         */\n\t        init: function (words, sigBytes) {\n\t            words = this.words = words || [];\n\n\t            if (sigBytes != undefined) {\n\t                this.sigBytes = sigBytes;\n\t            } else {\n\t                this.sigBytes = words.length * 4;\n\t            }\n\t        },\n\n\t        /**\n\t         * Converts this word array to a string.\n\t         *\n\t         * @param {Encoder} encoder (Optional) The encoding strategy to use. Default: CryptoJS.enc.Hex\n\t         *\n\t         * @return {string} The stringified word array.\n\t         *\n\t         * @example\n\t         *\n\t         *     var string = wordArray + '';\n\t         *     var string = wordArray.toString();\n\t         *     var string = wordArray.toString(CryptoJS.enc.Utf8);\n\t         */\n\t        toString: function (encoder) {\n\t            return (encoder || Hex).stringify(this);\n\t        },\n\n\t        /**\n\t         * Concatenates a word array to this word array.\n\t         *\n\t         * @param {WordArray} wordArray The word array to append.\n\t         *\n\t         * @return {WordArray} This word array.\n\t         *\n\t         * @example\n\t         *\n\t         *     wordArray1.concat(wordArray2);\n\t         */\n\t        concat: function (wordArray) {\n\t            // Shortcuts\n\t            var thisWords = this.words;\n\t            var thatWords = wordArray.words;\n\t            var thisSigBytes = this.sigBytes;\n\t            var thatSigBytes = wordArray.sigBytes;\n\n\t            // Clamp excess bits\n\t            this.clamp();\n\n\t            // Concat\n\t            if (thisSigBytes % 4) {\n\t                // Copy one byte at a time\n\t                for (var i = 0; i < thatSigBytes; i++) {\n\t                    var thatByte = (thatWords[i >>> 2] >>> (24 - (i % 4) * 8)) & 0xff;\n\t                    thisWords[(thisSigBytes + i) >>> 2] |= thatByte << (24 - ((thisSigBytes + i) % 4) * 8);\n\t                }\n\t            } else {\n\t                // Copy one word at a time\n\t                for (var i = 0; i < thatSigBytes; i += 4) {\n\t                    thisWords[(thisSigBytes + i) >>> 2] = thatWords[i >>> 2];\n\t                }\n\t            }\n\t            this.sigBytes += thatSigBytes;\n\n\t            // Chainable\n\t            return this;\n\t        },\n\n\t        /**\n\t         * Removes insignificant bits.\n\t         *\n\t         * @example\n\t         *\n\t         *     wordArray.clamp();\n\t         */\n\t        clamp: function () {\n\t            // Shortcuts\n\t            var words = this.words;\n\t            var sigBytes = this.sigBytes;\n\n\t            // Clamp\n\t            words[sigBytes >>> 2] &= 0xffffffff << (32 - (sigBytes % 4) * 8);\n\t            words.length = Math.ceil(sigBytes / 4);\n\t        },\n\n\t        /**\n\t         * Creates a copy of this word array.\n\t         *\n\t         * @return {WordArray} The clone.\n\t         *\n\t         * @example\n\t         *\n\t         *     var clone = wordArray.clone();\n\t         */\n\t        clone: function () {\n\t            var clone = Base.clone.call(this);\n\t            clone.words = this.words.slice(0);\n\n\t            return clone;\n\t        },\n\n\t        /**\n\t         * Creates a word array filled with random bytes.\n\t         *\n\t         * @param {number} nBytes The number of random bytes to generate.\n\t         *\n\t         * @return {WordArray} The random word array.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var wordArray = CryptoJS.lib.WordArray.random(16);\n\t         */\n\t        random: function (nBytes) {\n\t            var words = [];\n\n\t            var r = (function (m_w) {\n\t                var m_w = m_w;\n\t                var m_z = 0x3ade68b1;\n\t                var mask = 0xffffffff;\n\n\t                return function () {\n\t                    m_z = (0x9069 * (m_z & 0xFFFF) + (m_z >> 0x10)) & mask;\n\t                    m_w = (0x4650 * (m_w & 0xFFFF) + (m_w >> 0x10)) & mask;\n\t                    var result = ((m_z << 0x10) + m_w) & mask;\n\t                    result /= 0x100000000;\n\t                    result += 0.5;\n\t                    return result * (Math.random() > .5 ? 1 : -1);\n\t                }\n\t            });\n\n\t            for (var i = 0, rcache; i < nBytes; i += 4) {\n\t                var _r = r((rcache || Math.random()) * 0x100000000);\n\n\t                rcache = _r() * 0x3ade67b7;\n\t                words.push((_r() * 0x100000000) | 0);\n\t            }\n\n\t            return new WordArray.init(words, nBytes);\n\t        }\n\t    });\n\n\t    /**\n\t     * Encoder namespace.\n\t     */\n\t    var C_enc = C.enc = {};\n\n\t    /**\n\t     * Hex encoding strategy.\n\t     */\n\t    var Hex = C_enc.Hex = {\n\t        /**\n\t         * Converts a word array to a hex string.\n\t         *\n\t         * @param {WordArray} wordArray The word array.\n\t         *\n\t         * @return {string} The hex string.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var hexString = CryptoJS.enc.Hex.stringify(wordArray);\n\t         */\n\t        stringify: function (wordArray) {\n\t            // Shortcuts\n\t            var words = wordArray.words;\n\t            var sigBytes = wordArray.sigBytes;\n\n\t            // Convert\n\t            var hexChars = [];\n\t            for (var i = 0; i < sigBytes; i++) {\n\t                var bite = (words[i >>> 2] >>> (24 - (i % 4) * 8)) & 0xff;\n\t                hexChars.push((bite >>> 4).toString(16));\n\t                hexChars.push((bite & 0x0f).toString(16));\n\t            }\n\n\t            return hexChars.join('');\n\t        },\n\n\t        /**\n\t         * Converts a hex string to a word array.\n\t         *\n\t         * @param {string} hexStr The hex string.\n\t         *\n\t         * @return {WordArray} The word array.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var wordArray = CryptoJS.enc.Hex.parse(hexString);\n\t         */\n\t        parse: function (hexStr) {\n\t            // Shortcut\n\t            var hexStrLength = hexStr.length;\n\n\t            // Convert\n\t            var words = [];\n\t            for (var i = 0; i < hexStrLength; i += 2) {\n\t                words[i >>> 3] |= parseInt(hexStr.substr(i, 2), 16) << (24 - (i % 8) * 4);\n\t            }\n\n\t            return new WordArray.init(words, hexStrLength / 2);\n\t        }\n\t    };\n\n\t    /**\n\t     * Latin1 encoding strategy.\n\t     */\n\t    var Latin1 = C_enc.Latin1 = {\n\t        /**\n\t         * Converts a word array to a Latin1 string.\n\t         *\n\t         * @param {WordArray} wordArray The word array.\n\t         *\n\t         * @return {string} The Latin1 string.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var latin1String = CryptoJS.enc.Latin1.stringify(wordArray);\n\t         */\n\t        stringify: function (wordArray) {\n\t            // Shortcuts\n\t            var words = wordArray.words;\n\t            var sigBytes = wordArray.sigBytes;\n\n\t            // Convert\n\t            var latin1Chars = [];\n\t            for (var i = 0; i < sigBytes; i++) {\n\t                var bite = (words[i >>> 2] >>> (24 - (i % 4) * 8)) & 0xff;\n\t                latin1Chars.push(String.fromCharCode(bite));\n\t            }\n\n\t            return latin1Chars.join('');\n\t        },\n\n\t        /**\n\t         * Converts a Latin1 string to a word array.\n\t         *\n\t         * @param {string} latin1Str The Latin1 string.\n\t         *\n\t         * @return {WordArray} The word array.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var wordArray = CryptoJS.enc.Latin1.parse(latin1String);\n\t         */\n\t        parse: function (latin1Str) {\n\t            // Shortcut\n\t            var latin1StrLength = latin1Str.length;\n\n\t            // Convert\n\t            var words = [];\n\t            for (var i = 0; i < latin1StrLength; i++) {\n\t                words[i >>> 2] |= (latin1Str.charCodeAt(i) & 0xff) << (24 - (i % 4) * 8);\n\t            }\n\n\t            return new WordArray.init(words, latin1StrLength);\n\t        }\n\t    };\n\n\t    /**\n\t     * UTF-8 encoding strategy.\n\t     */\n\t    var Utf8 = C_enc.Utf8 = {\n\t        /**\n\t         * Converts a word array to a UTF-8 string.\n\t         *\n\t         * @param {WordArray} wordArray The word array.\n\t         *\n\t         * @return {string} The UTF-8 string.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var utf8String = CryptoJS.enc.Utf8.stringify(wordArray);\n\t         */\n\t        stringify: function (wordArray) {\n\t            try {\n\t                return decodeURIComponent(escape(Latin1.stringify(wordArray)));\n\t            } catch (e) {\n\t                throw new Error('Malformed UTF-8 data');\n\t            }\n\t        },\n\n\t        /**\n\t         * Converts a UTF-8 string to a word array.\n\t         *\n\t         * @param {string} utf8Str The UTF-8 string.\n\t         *\n\t         * @return {WordArray} The word array.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var wordArray = CryptoJS.enc.Utf8.parse(utf8String);\n\t         */\n\t        parse: function (utf8Str) {\n\t            return Latin1.parse(unescape(encodeURIComponent(utf8Str)));\n\t        }\n\t    };\n\n\t    /**\n\t     * Abstract buffered block algorithm template.\n\t     *\n\t     * The property blockSize must be implemented in a concrete subtype.\n\t     *\n\t     * @property {number} _minBufferSize The number of blocks that should be kept unprocessed in the buffer. Default: 0\n\t     */\n\t    var BufferedBlockAlgorithm = C_lib.BufferedBlockAlgorithm = Base.extend({\n\t        /**\n\t         * Resets this block algorithm's data buffer to its initial state.\n\t         *\n\t         * @example\n\t         *\n\t         *     bufferedBlockAlgorithm.reset();\n\t         */\n\t        reset: function () {\n\t            // Initial values\n\t            this._data = new WordArray.init();\n\t            this._nDataBytes = 0;\n\t        },\n\n\t        /**\n\t         * Adds new data to this block algorithm's buffer.\n\t         *\n\t         * @param {WordArray|string} data The data to append. Strings are converted to a WordArray using UTF-8.\n\t         *\n\t         * @example\n\t         *\n\t         *     bufferedBlockAlgorithm._append('data');\n\t         *     bufferedBlockAlgorithm._append(wordArray);\n\t         */\n\t        _append: function (data) {\n\t            // Convert string to WordArray, else assume WordArray already\n\t            if (typeof data == 'string') {\n\t                data = Utf8.parse(data);\n\t            }\n\n\t            // Append\n\t            this._data.concat(data);\n\t            this._nDataBytes += data.sigBytes;\n\t        },\n\n\t        /**\n\t         * Processes available data blocks.\n\t         *\n\t         * This method invokes _doProcessBlock(offset), which must be implemented by a concrete subtype.\n\t         *\n\t         * @param {boolean} doFlush Whether all blocks and partial blocks should be processed.\n\t         *\n\t         * @return {WordArray} The processed data.\n\t         *\n\t         * @example\n\t         *\n\t         *     var processedData = bufferedBlockAlgorithm._process();\n\t         *     var processedData = bufferedBlockAlgorithm._process(!!'flush');\n\t         */\n\t        _process: function (doFlush) {\n\t            // Shortcuts\n\t            var data = this._data;\n\t            var dataWords = data.words;\n\t            var dataSigBytes = data.sigBytes;\n\t            var blockSize = this.blockSize;\n\t            var blockSizeBytes = blockSize * 4;\n\n\t            // Count blocks ready\n\t            var nBlocksReady = dataSigBytes / blockSizeBytes;\n\t            if (doFlush) {\n\t                // Round up to include partial blocks\n\t                nBlocksReady = Math.ceil(nBlocksReady);\n\t            } else {\n\t                // Round down to include only full blocks,\n\t                // less the number of blocks that must remain in the buffer\n\t                nBlocksReady = Math.max((nBlocksReady | 0) - this._minBufferSize, 0);\n\t            }\n\n\t            // Count words ready\n\t            var nWordsReady = nBlocksReady * blockSize;\n\n\t            // Count bytes ready\n\t            var nBytesReady = Math.min(nWordsReady * 4, dataSigBytes);\n\n\t            // Process blocks\n\t            if (nWordsReady) {\n\t                for (var offset = 0; offset < nWordsReady; offset += blockSize) {\n\t                    // Perform concrete-algorithm logic\n\t                    this._doProcessBlock(dataWords, offset);\n\t                }\n\n\t                // Remove processed words\n\t                var processedWords = dataWords.splice(0, nWordsReady);\n\t                data.sigBytes -= nBytesReady;\n\t            }\n\n\t            // Return processed words\n\t            return new WordArray.init(processedWords, nBytesReady);\n\t        },\n\n\t        /**\n\t         * Creates a copy of this object.\n\t         *\n\t         * @return {Object} The clone.\n\t         *\n\t         * @example\n\t         *\n\t         *     var clone = bufferedBlockAlgorithm.clone();\n\t         */\n\t        clone: function () {\n\t            var clone = Base.clone.call(this);\n\t            clone._data = this._data.clone();\n\n\t            return clone;\n\t        },\n\n\t        _minBufferSize: 0\n\t    });\n\n\t    /**\n\t     * Abstract hasher template.\n\t     *\n\t     * @property {number} blockSize The number of 32-bit words this hasher operates on. Default: 16 (512 bits)\n\t     */\n\t    var Hasher = C_lib.Hasher = BufferedBlockAlgorithm.extend({\n\t        /**\n\t         * Configuration options.\n\t         */\n\t        cfg: Base.extend(),\n\n\t        /**\n\t         * Initializes a newly created hasher.\n\t         *\n\t         * @param {Object} cfg (Optional) The configuration options to use for this hash computation.\n\t         *\n\t         * @example\n\t         *\n\t         *     var hasher = CryptoJS.algo.SHA256.create();\n\t         */\n\t        init: function (cfg) {\n\t            // Apply config defaults\n\t            this.cfg = this.cfg.extend(cfg);\n\n\t            // Set initial values\n\t            this.reset();\n\t        },\n\n\t        /**\n\t         * Resets this hasher to its initial state.\n\t         *\n\t         * @example\n\t         *\n\t         *     hasher.reset();\n\t         */\n\t        reset: function () {\n\t            // Reset data buffer\n\t            BufferedBlockAlgorithm.reset.call(this);\n\n\t            // Perform concrete-hasher logic\n\t            this._doReset();\n\t        },\n\n\t        /**\n\t         * Updates this hasher with a message.\n\t         *\n\t         * @param {WordArray|string} messageUpdate The message to append.\n\t         *\n\t         * @return {Hasher} This hasher.\n\t         *\n\t         * @example\n\t         *\n\t         *     hasher.update('message');\n\t         *     hasher.update(wordArray);\n\t         */\n\t        update: function (messageUpdate) {\n\t            // Append\n\t            this._append(messageUpdate);\n\n\t            // Update the hash\n\t            this._process();\n\n\t            // Chainable\n\t            return this;\n\t        },\n\n\t        /**\n\t         * Finalizes the hash computation.\n\t         * Note that the finalize operation is effectively a destructive, read-once operation.\n\t         *\n\t         * @param {WordArray|string} messageUpdate (Optional) A final message update.\n\t         *\n\t         * @return {WordArray} The hash.\n\t         *\n\t         * @example\n\t         *\n\t         *     var hash = hasher.finalize();\n\t         *     var hash = hasher.finalize('message');\n\t         *     var hash = hasher.finalize(wordArray);\n\t         */\n\t        finalize: function (messageUpdate) {\n\t            // Final message update\n\t            if (messageUpdate) {\n\t                this._append(messageUpdate);\n\t            }\n\n\t            // Perform concrete-hasher logic\n\t            var hash = this._doFinalize();\n\n\t            return hash;\n\t        },\n\n\t        blockSize: 512/32,\n\n\t        /**\n\t         * Creates a shortcut function to a hasher's object interface.\n\t         *\n\t         * @param {Hasher} hasher The hasher to create a helper for.\n\t         *\n\t         * @return {Function} The shortcut function.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var SHA256 = CryptoJS.lib.Hasher._createHelper(CryptoJS.algo.SHA256);\n\t         */\n\t        _createHelper: function (hasher) {\n\t            return function (message, cfg) {\n\t                return new hasher.init(cfg).finalize(message);\n\t            };\n\t        },\n\n\t        /**\n\t         * Creates a shortcut function to the HMAC's object interface.\n\t         *\n\t         * @param {Hasher} hasher The hasher to use in this HMAC helper.\n\t         *\n\t         * @return {Function} The shortcut function.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var HmacSHA256 = CryptoJS.lib.Hasher._createHmacHelper(CryptoJS.algo.SHA256);\n\t         */\n\t        _createHmacHelper: function (hasher) {\n\t            return function (message, key) {\n\t                return new C_algo.HMAC.init(hasher, key).finalize(message);\n\t            };\n\t        }\n\t    });\n\n\t    /**\n\t     * Algorithm namespace.\n\t     */\n\t    var C_algo = C.algo = {};\n\n\t    return C;\n\t}(Math));\n\n\n\treturn CryptoJS;\n\n}));\n\n/***/ }),\n/* 1 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory, undef) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0), __webpack_require__(2));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t/**\n\t * Cipher core components.\n\t */\n\tCryptoJS.lib.Cipher || (function (undefined) {\n\t    // Shortcuts\n\t    var C = CryptoJS;\n\t    var C_lib = C.lib;\n\t    var Base = C_lib.Base;\n\t    var WordArray = C_lib.WordArray;\n\t    var BufferedBlockAlgorithm = C_lib.BufferedBlockAlgorithm;\n\t    var C_enc = C.enc;\n\t    var Utf8 = C_enc.Utf8;\n\t    var Base64 = C_enc.Base64;\n\t    var C_algo = C.algo;\n\t    var EvpKDF = C_algo.EvpKDF;\n\n\t    /**\n\t     * Abstract base cipher template.\n\t     *\n\t     * @property {number} keySize This cipher's key size. Default: 4 (128 bits)\n\t     * @property {number} ivSize This cipher's IV size. Default: 4 (128 bits)\n\t     * @property {number} _ENC_XFORM_MODE A constant representing encryption mode.\n\t     * @property {number} _DEC_XFORM_MODE A constant representing decryption mode.\n\t     */\n\t    var Cipher = C_lib.Cipher = BufferedBlockAlgorithm.extend({\n\t        /**\n\t         * Configuration options.\n\t         *\n\t         * @property {WordArray} iv The IV to use for this operation.\n\t         */\n\t        cfg: Base.extend(),\n\n\t        /**\n\t         * Creates this cipher in encryption mode.\n\t         *\n\t         * @param {WordArray} key The key.\n\t         * @param {Object} cfg (Optional) The configuration options to use for this operation.\n\t         *\n\t         * @return {Cipher} A cipher instance.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var cipher = CryptoJS.algo.AES.createEncryptor(keyWordArray, { iv: ivWordArray });\n\t         */\n\t        createEncryptor: function (key, cfg) {\n\t            return this.create(this._ENC_XFORM_MODE, key, cfg);\n\t        },\n\n\t        /**\n\t         * Creates this cipher in decryption mode.\n\t         *\n\t         * @param {WordArray} key The key.\n\t         * @param {Object} cfg (Optional) The configuration options to use for this operation.\n\t         *\n\t         * @return {Cipher} A cipher instance.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var cipher = CryptoJS.algo.AES.createDecryptor(keyWordArray, { iv: ivWordArray });\n\t         */\n\t        createDecryptor: function (key, cfg) {\n\t            return this.create(this._DEC_XFORM_MODE, key, cfg);\n\t        },\n\n\t        /**\n\t         * Initializes a newly created cipher.\n\t         *\n\t         * @param {number} xformMode Either the encryption or decryption transormation mode constant.\n\t         * @param {WordArray} key The key.\n\t         * @param {Object} cfg (Optional) The configuration options to use for this operation.\n\t         *\n\t         * @example\n\t         *\n\t         *     var cipher = CryptoJS.algo.AES.create(CryptoJS.algo.AES._ENC_XFORM_MODE, keyWordArray, { iv: ivWordArray });\n\t         */\n\t        init: function (xformMode, key, cfg) {\n\t            // Apply config defaults\n\t            this.cfg = this.cfg.extend(cfg);\n\n\t            // Store transform mode and key\n\t            this._xformMode = xformMode;\n\t            this._key = key;\n\n\t            // Set initial values\n\t            this.reset();\n\t        },\n\n\t        /**\n\t         * Resets this cipher to its initial state.\n\t         *\n\t         * @example\n\t         *\n\t         *     cipher.reset();\n\t         */\n\t        reset: function () {\n\t            // Reset data buffer\n\t            BufferedBlockAlgorithm.reset.call(this);\n\n\t            // Perform concrete-cipher logic\n\t            this._doReset();\n\t        },\n\n\t        /**\n\t         * Adds data to be encrypted or decrypted.\n\t         *\n\t         * @param {WordArray|string} dataUpdate The data to encrypt or decrypt.\n\t         *\n\t         * @return {WordArray} The data after processing.\n\t         *\n\t         * @example\n\t         *\n\t         *     var encrypted = cipher.process('data');\n\t         *     var encrypted = cipher.process(wordArray);\n\t         */\n\t        process: function (dataUpdate) {\n\t            // Append\n\t            this._append(dataUpdate);\n\n\t            // Process available blocks\n\t            return this._process();\n\t        },\n\n\t        /**\n\t         * Finalizes the encryption or decryption process.\n\t         * Note that the finalize operation is effectively a destructive, read-once operation.\n\t         *\n\t         * @param {WordArray|string} dataUpdate The final data to encrypt or decrypt.\n\t         *\n\t         * @return {WordArray} The data after final processing.\n\t         *\n\t         * @example\n\t         *\n\t         *     var encrypted = cipher.finalize();\n\t         *     var encrypted = cipher.finalize('data');\n\t         *     var encrypted = cipher.finalize(wordArray);\n\t         */\n\t        finalize: function (dataUpdate) {\n\t            // Final data update\n\t            if (dataUpdate) {\n\t                this._append(dataUpdate);\n\t            }\n\n\t            // Perform concrete-cipher logic\n\t            var finalProcessedData = this._doFinalize();\n\n\t            return finalProcessedData;\n\t        },\n\n\t        keySize: 128/32,\n\n\t        ivSize: 128/32,\n\n\t        _ENC_XFORM_MODE: 1,\n\n\t        _DEC_XFORM_MODE: 2,\n\n\t        /**\n\t         * Creates shortcut functions to a cipher's object interface.\n\t         *\n\t         * @param {Cipher} cipher The cipher to create a helper for.\n\t         *\n\t         * @return {Object} An object with encrypt and decrypt shortcut functions.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var AES = CryptoJS.lib.Cipher._createHelper(CryptoJS.algo.AES);\n\t         */\n\t        _createHelper: (function () {\n\t            function selectCipherStrategy(key) {\n\t                if (typeof key == 'string') {\n\t                    return PasswordBasedCipher;\n\t                } else {\n\t                    return SerializableCipher;\n\t                }\n\t            }\n\n\t            return function (cipher) {\n\t                return {\n\t                    encrypt: function (message, key, cfg) {\n\t                        return selectCipherStrategy(key).encrypt(cipher, message, key, cfg);\n\t                    },\n\n\t                    decrypt: function (ciphertext, key, cfg) {\n\t                        return selectCipherStrategy(key).decrypt(cipher, ciphertext, key, cfg);\n\t                    }\n\t                };\n\t            };\n\t        }())\n\t    });\n\n\t    /**\n\t     * Abstract base stream cipher template.\n\t     *\n\t     * @property {number} blockSize The number of 32-bit words this cipher operates on. Default: 1 (32 bits)\n\t     */\n\t    var StreamCipher = C_lib.StreamCipher = Cipher.extend({\n\t        _doFinalize: function () {\n\t            // Process partial blocks\n\t            var finalProcessedBlocks = this._process(!!'flush');\n\n\t            return finalProcessedBlocks;\n\t        },\n\n\t        blockSize: 1\n\t    });\n\n\t    /**\n\t     * Mode namespace.\n\t     */\n\t    var C_mode = C.mode = {};\n\n\t    /**\n\t     * Abstract base block cipher mode template.\n\t     */\n\t    var BlockCipherMode = C_lib.BlockCipherMode = Base.extend({\n\t        /**\n\t         * Creates this mode for encryption.\n\t         *\n\t         * @param {Cipher} cipher A block cipher instance.\n\t         * @param {Array} iv The IV words.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var mode = CryptoJS.mode.CBC.createEncryptor(cipher, iv.words);\n\t         */\n\t        createEncryptor: function (cipher, iv) {\n\t            return this.Encryptor.create(cipher, iv);\n\t        },\n\n\t        /**\n\t         * Creates this mode for decryption.\n\t         *\n\t         * @param {Cipher} cipher A block cipher instance.\n\t         * @param {Array} iv The IV words.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var mode = CryptoJS.mode.CBC.createDecryptor(cipher, iv.words);\n\t         */\n\t        createDecryptor: function (cipher, iv) {\n\t            return this.Decryptor.create(cipher, iv);\n\t        },\n\n\t        /**\n\t         * Initializes a newly created mode.\n\t         *\n\t         * @param {Cipher} cipher A block cipher instance.\n\t         * @param {Array} iv The IV words.\n\t         *\n\t         * @example\n\t         *\n\t         *     var mode = CryptoJS.mode.CBC.Encryptor.create(cipher, iv.words);\n\t         */\n\t        init: function (cipher, iv) {\n\t            this._cipher = cipher;\n\t            this._iv = iv;\n\t        }\n\t    });\n\n\t    /**\n\t     * Cipher Block Chaining mode.\n\t     */\n\t    var CBC = C_mode.CBC = (function () {\n\t        /**\n\t         * Abstract base CBC mode.\n\t         */\n\t        var CBC = BlockCipherMode.extend();\n\n\t        /**\n\t         * CBC encryptor.\n\t         */\n\t        CBC.Encryptor = CBC.extend({\n\t            /**\n\t             * Processes the data block at offset.\n\t             *\n\t             * @param {Array} words The data words to operate on.\n\t             * @param {number} offset The offset where the block starts.\n\t             *\n\t             * @example\n\t             *\n\t             *     mode.processBlock(data.words, offset);\n\t             */\n\t            processBlock: function (words, offset) {\n\t                // Shortcuts\n\t                var cipher = this._cipher;\n\t                var blockSize = cipher.blockSize;\n\n\t                // XOR and encrypt\n\t                xorBlock.call(this, words, offset, blockSize);\n\t                cipher.encryptBlock(words, offset);\n\n\t                // Remember this block to use with next block\n\t                this._prevBlock = words.slice(offset, offset + blockSize);\n\t            }\n\t        });\n\n\t        /**\n\t         * CBC decryptor.\n\t         */\n\t        CBC.Decryptor = CBC.extend({\n\t            /**\n\t             * Processes the data block at offset.\n\t             *\n\t             * @param {Array} words The data words to operate on.\n\t             * @param {number} offset The offset where the block starts.\n\t             *\n\t             * @example\n\t             *\n\t             *     mode.processBlock(data.words, offset);\n\t             */\n\t            processBlock: function (words, offset) {\n\t                // Shortcuts\n\t                var cipher = this._cipher;\n\t                var blockSize = cipher.blockSize;\n\n\t                // Remember this block to use with next block\n\t                var thisBlock = words.slice(offset, offset + blockSize);\n\n\t                // Decrypt and XOR\n\t                cipher.decryptBlock(words, offset);\n\t                xorBlock.call(this, words, offset, blockSize);\n\n\t                // This block becomes the previous block\n\t                this._prevBlock = thisBlock;\n\t            }\n\t        });\n\n\t        function xorBlock(words, offset, blockSize) {\n\t            // Shortcut\n\t            var iv = this._iv;\n\n\t            // Choose mixing block\n\t            if (iv) {\n\t                var block = iv;\n\n\t                // Remove IV for subsequent blocks\n\t                this._iv = undefined;\n\t            } else {\n\t                var block = this._prevBlock;\n\t            }\n\n\t            // XOR blocks\n\t            for (var i = 0; i < blockSize; i++) {\n\t                words[offset + i] ^= block[i];\n\t            }\n\t        }\n\n\t        return CBC;\n\t    }());\n\n\t    /**\n\t     * Padding namespace.\n\t     */\n\t    var C_pad = C.pad = {};\n\n\t    /**\n\t     * PKCS #5/7 padding strategy.\n\t     */\n\t    var Pkcs7 = C_pad.Pkcs7 = {\n\t        /**\n\t         * Pads data using the algorithm defined in PKCS #5/7.\n\t         *\n\t         * @param {WordArray} data The data to pad.\n\t         * @param {number} blockSize The multiple that the data should be padded to.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     CryptoJS.pad.Pkcs7.pad(wordArray, 4);\n\t         */\n\t        pad: function (data, blockSize) {\n\t            // Shortcut\n\t            var blockSizeBytes = blockSize * 4;\n\n\t            // Count padding bytes\n\t            var nPaddingBytes = blockSizeBytes - data.sigBytes % blockSizeBytes;\n\n\t            // Create padding word\n\t            var paddingWord = (nPaddingBytes << 24) | (nPaddingBytes << 16) | (nPaddingBytes << 8) | nPaddingBytes;\n\n\t            // Create padding\n\t            var paddingWords = [];\n\t            for (var i = 0; i < nPaddingBytes; i += 4) {\n\t                paddingWords.push(paddingWord);\n\t            }\n\t            var padding = WordArray.create(paddingWords, nPaddingBytes);\n\n\t            // Add padding\n\t            data.concat(padding);\n\t        },\n\n\t        /**\n\t         * Unpads data that had been padded using the algorithm defined in PKCS #5/7.\n\t         *\n\t         * @param {WordArray} data The data to unpad.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     CryptoJS.pad.Pkcs7.unpad(wordArray);\n\t         */\n\t        unpad: function (data) {\n\t            // Get number of padding bytes from last byte\n\t            var nPaddingBytes = data.words[(data.sigBytes - 1) >>> 2] & 0xff;\n\n\t            // Remove padding\n\t            data.sigBytes -= nPaddingBytes;\n\t        }\n\t    };\n\n\t    /**\n\t     * Abstract base block cipher template.\n\t     *\n\t     * @property {number} blockSize The number of 32-bit words this cipher operates on. Default: 4 (128 bits)\n\t     */\n\t    var BlockCipher = C_lib.BlockCipher = Cipher.extend({\n\t        /**\n\t         * Configuration options.\n\t         *\n\t         * @property {Mode} mode The block mode to use. Default: CBC\n\t         * @property {Padding} padding The padding strategy to use. Default: Pkcs7\n\t         */\n\t        cfg: Cipher.cfg.extend({\n\t            mode: CBC,\n\t            padding: Pkcs7\n\t        }),\n\n\t        reset: function () {\n\t            // Reset cipher\n\t            Cipher.reset.call(this);\n\n\t            // Shortcuts\n\t            var cfg = this.cfg;\n\t            var iv = cfg.iv;\n\t            var mode = cfg.mode;\n\n\t            // Reset block mode\n\t            if (this._xformMode == this._ENC_XFORM_MODE) {\n\t                var modeCreator = mode.createEncryptor;\n\t            } else /* if (this._xformMode == this._DEC_XFORM_MODE) */ {\n\t                var modeCreator = mode.createDecryptor;\n\t                // Keep at least one block in the buffer for unpadding\n\t                this._minBufferSize = 1;\n\t            }\n\n\t            if (this._mode && this._mode.__creator == modeCreator) {\n\t                this._mode.init(this, iv && iv.words);\n\t            } else {\n\t                this._mode = modeCreator.call(mode, this, iv && iv.words);\n\t                this._mode.__creator = modeCreator;\n\t            }\n\t        },\n\n\t        _doProcessBlock: function (words, offset) {\n\t            this._mode.processBlock(words, offset);\n\t        },\n\n\t        _doFinalize: function () {\n\t            // Shortcut\n\t            var padding = this.cfg.padding;\n\n\t            // Finalize\n\t            if (this._xformMode == this._ENC_XFORM_MODE) {\n\t                // Pad data\n\t                padding.pad(this._data, this.blockSize);\n\n\t                // Process final blocks\n\t                var finalProcessedBlocks = this._process(!!'flush');\n\t            } else /* if (this._xformMode == this._DEC_XFORM_MODE) */ {\n\t                // Process final blocks\n\t                var finalProcessedBlocks = this._process(!!'flush');\n\n\t                // Unpad data\n\t                padding.unpad(finalProcessedBlocks);\n\t            }\n\n\t            return finalProcessedBlocks;\n\t        },\n\n\t        blockSize: 128/32\n\t    });\n\n\t    /**\n\t     * A collection of cipher parameters.\n\t     *\n\t     * @property {WordArray} ciphertext The raw ciphertext.\n\t     * @property {WordArray} key The key to this ciphertext.\n\t     * @property {WordArray} iv The IV used in the ciphering operation.\n\t     * @property {WordArray} salt The salt used with a key derivation function.\n\t     * @property {Cipher} algorithm The cipher algorithm.\n\t     * @property {Mode} mode The block mode used in the ciphering operation.\n\t     * @property {Padding} padding The padding scheme used in the ciphering operation.\n\t     * @property {number} blockSize The block size of the cipher.\n\t     * @property {Format} formatter The default formatting strategy to convert this cipher params object to a string.\n\t     */\n\t    var CipherParams = C_lib.CipherParams = Base.extend({\n\t        /**\n\t         * Initializes a newly created cipher params object.\n\t         *\n\t         * @param {Object} cipherParams An object with any of the possible cipher parameters.\n\t         *\n\t         * @example\n\t         *\n\t         *     var cipherParams = CryptoJS.lib.CipherParams.create({\n\t         *         ciphertext: ciphertextWordArray,\n\t         *         key: keyWordArray,\n\t         *         iv: ivWordArray,\n\t         *         salt: saltWordArray,\n\t         *         algorithm: CryptoJS.algo.AES,\n\t         *         mode: CryptoJS.mode.CBC,\n\t         *         padding: CryptoJS.pad.PKCS7,\n\t         *         blockSize: 4,\n\t         *         formatter: CryptoJS.format.OpenSSL\n\t         *     });\n\t         */\n\t        init: function (cipherParams) {\n\t            this.mixIn(cipherParams);\n\t        },\n\n\t        /**\n\t         * Converts this cipher params object to a string.\n\t         *\n\t         * @param {Format} formatter (Optional) The formatting strategy to use.\n\t         *\n\t         * @return {string} The stringified cipher params.\n\t         *\n\t         * @throws Error If neither the formatter nor the default formatter is set.\n\t         *\n\t         * @example\n\t         *\n\t         *     var string = cipherParams + '';\n\t         *     var string = cipherParams.toString();\n\t         *     var string = cipherParams.toString(CryptoJS.format.OpenSSL);\n\t         */\n\t        toString: function (formatter) {\n\t            return (formatter || this.formatter).stringify(this);\n\t        }\n\t    });\n\n\t    /**\n\t     * Format namespace.\n\t     */\n\t    var C_format = C.format = {};\n\n\t    /**\n\t     * OpenSSL formatting strategy.\n\t     */\n\t    var OpenSSLFormatter = C_format.OpenSSL = {\n\t        /**\n\t         * Converts a cipher params object to an OpenSSL-compatible string.\n\t         *\n\t         * @param {CipherParams} cipherParams The cipher params object.\n\t         *\n\t         * @return {string} The OpenSSL-compatible string.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var openSSLString = CryptoJS.format.OpenSSL.stringify(cipherParams);\n\t         */\n\t        stringify: function (cipherParams) {\n\t            // Shortcuts\n\t            var ciphertext = cipherParams.ciphertext;\n\t            var salt = cipherParams.salt;\n\n\t            // Format\n\t            if (salt) {\n\t                var wordArray = WordArray.create([0x53616c74, 0x65645f5f]).concat(salt).concat(ciphertext);\n\t            } else {\n\t                var wordArray = ciphertext;\n\t            }\n\n\t            return wordArray.toString(Base64);\n\t        },\n\n\t        /**\n\t         * Converts an OpenSSL-compatible string to a cipher params object.\n\t         *\n\t         * @param {string} openSSLStr The OpenSSL-compatible string.\n\t         *\n\t         * @return {CipherParams} The cipher params object.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var cipherParams = CryptoJS.format.OpenSSL.parse(openSSLString);\n\t         */\n\t        parse: function (openSSLStr) {\n\t            // Parse base64\n\t            var ciphertext = Base64.parse(openSSLStr);\n\n\t            // Shortcut\n\t            var ciphertextWords = ciphertext.words;\n\n\t            // Test for salt\n\t            if (ciphertextWords[0] == 0x53616c74 && ciphertextWords[1] == 0x65645f5f) {\n\t                // Extract salt\n\t                var salt = WordArray.create(ciphertextWords.slice(2, 4));\n\n\t                // Remove salt from ciphertext\n\t                ciphertextWords.splice(0, 4);\n\t                ciphertext.sigBytes -= 16;\n\t            }\n\n\t            return CipherParams.create({ ciphertext: ciphertext, salt: salt });\n\t        }\n\t    };\n\n\t    /**\n\t     * A cipher wrapper that returns ciphertext as a serializable cipher params object.\n\t     */\n\t    var SerializableCipher = C_lib.SerializableCipher = Base.extend({\n\t        /**\n\t         * Configuration options.\n\t         *\n\t         * @property {Formatter} format The formatting strategy to convert cipher param objects to and from a string. Default: OpenSSL\n\t         */\n\t        cfg: Base.extend({\n\t            format: OpenSSLFormatter\n\t        }),\n\n\t        /**\n\t         * Encrypts a message.\n\t         *\n\t         * @param {Cipher} cipher The cipher algorithm to use.\n\t         * @param {WordArray|string} message The message to encrypt.\n\t         * @param {WordArray} key The key.\n\t         * @param {Object} cfg (Optional) The configuration options to use for this operation.\n\t         *\n\t         * @return {CipherParams} A cipher params object.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var ciphertextParams = CryptoJS.lib.SerializableCipher.encrypt(CryptoJS.algo.AES, message, key);\n\t         *     var ciphertextParams = CryptoJS.lib.SerializableCipher.encrypt(CryptoJS.algo.AES, message, key, { iv: iv });\n\t         *     var ciphertextParams = CryptoJS.lib.SerializableCipher.encrypt(CryptoJS.algo.AES, message, key, { iv: iv, format: CryptoJS.format.OpenSSL });\n\t         */\n\t        encrypt: function (cipher, message, key, cfg) {\n\t            // Apply config defaults\n\t            cfg = this.cfg.extend(cfg);\n\n\t            // Encrypt\n\t            var encryptor = cipher.createEncryptor(key, cfg);\n\t            var ciphertext = encryptor.finalize(message);\n\n\t            // Shortcut\n\t            var cipherCfg = encryptor.cfg;\n\n\t            // Create and return serializable cipher params\n\t            return CipherParams.create({\n\t                ciphertext: ciphertext,\n\t                key: key,\n\t                iv: cipherCfg.iv,\n\t                algorithm: cipher,\n\t                mode: cipherCfg.mode,\n\t                padding: cipherCfg.padding,\n\t                blockSize: cipher.blockSize,\n\t                formatter: cfg.format\n\t            });\n\t        },\n\n\t        /**\n\t         * Decrypts serialized ciphertext.\n\t         *\n\t         * @param {Cipher} cipher The cipher algorithm to use.\n\t         * @param {CipherParams|string} ciphertext The ciphertext to decrypt.\n\t         * @param {WordArray} key The key.\n\t         * @param {Object} cfg (Optional) The configuration options to use for this operation.\n\t         *\n\t         * @return {WordArray} The plaintext.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var plaintext = CryptoJS.lib.SerializableCipher.decrypt(CryptoJS.algo.AES, formattedCiphertext, key, { iv: iv, format: CryptoJS.format.OpenSSL });\n\t         *     var plaintext = CryptoJS.lib.SerializableCipher.decrypt(CryptoJS.algo.AES, ciphertextParams, key, { iv: iv, format: CryptoJS.format.OpenSSL });\n\t         */\n\t        decrypt: function (cipher, ciphertext, key, cfg) {\n\t            // Apply config defaults\n\t            cfg = this.cfg.extend(cfg);\n\n\t            // Convert string to CipherParams\n\t            ciphertext = this._parse(ciphertext, cfg.format);\n\n\t            // Decrypt\n\t            var plaintext = cipher.createDecryptor(key, cfg).finalize(ciphertext.ciphertext);\n\n\t            return plaintext;\n\t        },\n\n\t        /**\n\t         * Converts serialized ciphertext to CipherParams,\n\t         * else assumed CipherParams already and returns ciphertext unchanged.\n\t         *\n\t         * @param {CipherParams|string} ciphertext The ciphertext.\n\t         * @param {Formatter} format The formatting strategy to use to parse serialized ciphertext.\n\t         *\n\t         * @return {CipherParams} The unserialized ciphertext.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var ciphertextParams = CryptoJS.lib.SerializableCipher._parse(ciphertextStringOrParams, format);\n\t         */\n\t        _parse: function (ciphertext, format) {\n\t            if (typeof ciphertext == 'string') {\n\t                return format.parse(ciphertext, this);\n\t            } else {\n\t                return ciphertext;\n\t            }\n\t        }\n\t    });\n\n\t    /**\n\t     * Key derivation function namespace.\n\t     */\n\t    var C_kdf = C.kdf = {};\n\n\t    /**\n\t     * OpenSSL key derivation function.\n\t     */\n\t    var OpenSSLKdf = C_kdf.OpenSSL = {\n\t        /**\n\t         * Derives a key and IV from a password.\n\t         *\n\t         * @param {string} password The password to derive from.\n\t         * @param {number} keySize The size in words of the key to generate.\n\t         * @param {number} ivSize The size in words of the IV to generate.\n\t         * @param {WordArray|string} salt (Optional) A 64-bit salt to use. If omitted, a salt will be generated randomly.\n\t         *\n\t         * @return {CipherParams} A cipher params object with the key, IV, and salt.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var derivedParams = CryptoJS.kdf.OpenSSL.execute('Password', 256/32, 128/32);\n\t         *     var derivedParams = CryptoJS.kdf.OpenSSL.execute('Password', 256/32, 128/32, 'saltsalt');\n\t         */\n\t        execute: function (password, keySize, ivSize, salt) {\n\t            // Generate random salt\n\t            if (!salt) {\n\t                salt = WordArray.random(64/8);\n\t            }\n\n\t            // Derive key and IV\n\t            var key = EvpKDF.create({ keySize: keySize + ivSize }).compute(password, salt);\n\n\t            // Separate key and IV\n\t            var iv = WordArray.create(key.words.slice(keySize), ivSize * 4);\n\t            key.sigBytes = keySize * 4;\n\n\t            // Return params\n\t            return CipherParams.create({ key: key, iv: iv, salt: salt });\n\t        }\n\t    };\n\n\t    /**\n\t     * A serializable cipher wrapper that derives the key from a password,\n\t     * and returns ciphertext as a serializable cipher params object.\n\t     */\n\t    var PasswordBasedCipher = C_lib.PasswordBasedCipher = SerializableCipher.extend({\n\t        /**\n\t         * Configuration options.\n\t         *\n\t         * @property {KDF} kdf The key derivation function to use to generate a key and IV from a password. Default: OpenSSL\n\t         */\n\t        cfg: SerializableCipher.cfg.extend({\n\t            kdf: OpenSSLKdf\n\t        }),\n\n\t        /**\n\t         * Encrypts a message using a password.\n\t         *\n\t         * @param {Cipher} cipher The cipher algorithm to use.\n\t         * @param {WordArray|string} message The message to encrypt.\n\t         * @param {string} password The password.\n\t         * @param {Object} cfg (Optional) The configuration options to use for this operation.\n\t         *\n\t         * @return {CipherParams} A cipher params object.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var ciphertextParams = CryptoJS.lib.PasswordBasedCipher.encrypt(CryptoJS.algo.AES, message, 'password');\n\t         *     var ciphertextParams = CryptoJS.lib.PasswordBasedCipher.encrypt(CryptoJS.algo.AES, message, 'password', { format: CryptoJS.format.OpenSSL });\n\t         */\n\t        encrypt: function (cipher, message, password, cfg) {\n\t            // Apply config defaults\n\t            cfg = this.cfg.extend(cfg);\n\n\t            // Derive key and other params\n\t            var derivedParams = cfg.kdf.execute(password, cipher.keySize, cipher.ivSize);\n\n\t            // Add IV to config\n\t            cfg.iv = derivedParams.iv;\n\n\t            // Encrypt\n\t            var ciphertext = SerializableCipher.encrypt.call(this, cipher, message, derivedParams.key, cfg);\n\n\t            // Mix in derived params\n\t            ciphertext.mixIn(derivedParams);\n\n\t            return ciphertext;\n\t        },\n\n\t        /**\n\t         * Decrypts serialized ciphertext using a password.\n\t         *\n\t         * @param {Cipher} cipher The cipher algorithm to use.\n\t         * @param {CipherParams|string} ciphertext The ciphertext to decrypt.\n\t         * @param {string} password The password.\n\t         * @param {Object} cfg (Optional) The configuration options to use for this operation.\n\t         *\n\t         * @return {WordArray} The plaintext.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var plaintext = CryptoJS.lib.PasswordBasedCipher.decrypt(CryptoJS.algo.AES, formattedCiphertext, 'password', { format: CryptoJS.format.OpenSSL });\n\t         *     var plaintext = CryptoJS.lib.PasswordBasedCipher.decrypt(CryptoJS.algo.AES, ciphertextParams, 'password', { format: CryptoJS.format.OpenSSL });\n\t         */\n\t        decrypt: function (cipher, ciphertext, password, cfg) {\n\t            // Apply config defaults\n\t            cfg = this.cfg.extend(cfg);\n\n\t            // Convert string to CipherParams\n\t            ciphertext = this._parse(ciphertext, cfg.format);\n\n\t            // Derive key and other params\n\t            var derivedParams = cfg.kdf.execute(password, cipher.keySize, cipher.ivSize, ciphertext.salt);\n\n\t            // Add IV to config\n\t            cfg.iv = derivedParams.iv;\n\n\t            // Decrypt\n\t            var plaintext = SerializableCipher.decrypt.call(this, cipher, ciphertext, derivedParams.key, cfg);\n\n\t            return plaintext;\n\t        }\n\t    });\n\t}());\n\n\n}));\n\n/***/ }),\n/* 2 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory, undef) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0), __webpack_require__(6), __webpack_require__(7));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t(function () {\n\t    // Shortcuts\n\t    var C = CryptoJS;\n\t    var C_lib = C.lib;\n\t    var Base = C_lib.Base;\n\t    var WordArray = C_lib.WordArray;\n\t    var C_algo = C.algo;\n\t    var MD5 = C_algo.MD5;\n\n\t    /**\n\t     * This key derivation function is meant to conform with EVP_BytesToKey.\n\t     * www.openssl.org/docs/crypto/EVP_BytesToKey.html\n\t     */\n\t    var EvpKDF = C_algo.EvpKDF = Base.extend({\n\t        /**\n\t         * Configuration options.\n\t         *\n\t         * @property {number} keySize The key size in words to generate. Default: 4 (128 bits)\n\t         * @property {Hasher} hasher The hash algorithm to use. Default: MD5\n\t         * @property {number} iterations The number of iterations to perform. Default: 1\n\t         */\n\t        cfg: Base.extend({\n\t            keySize: 128/32,\n\t            hasher: MD5,\n\t            iterations: 1\n\t        }),\n\n\t        /**\n\t         * Initializes a newly created key derivation function.\n\t         *\n\t         * @param {Object} cfg (Optional) The configuration options to use for the derivation.\n\t         *\n\t         * @example\n\t         *\n\t         *     var kdf = CryptoJS.algo.EvpKDF.create();\n\t         *     var kdf = CryptoJS.algo.EvpKDF.create({ keySize: 8 });\n\t         *     var kdf = CryptoJS.algo.EvpKDF.create({ keySize: 8, iterations: 1000 });\n\t         */\n\t        init: function (cfg) {\n\t            this.cfg = this.cfg.extend(cfg);\n\t        },\n\n\t        /**\n\t         * Derives a key from a password.\n\t         *\n\t         * @param {WordArray|string} password The password.\n\t         * @param {WordArray|string} salt A salt.\n\t         *\n\t         * @return {WordArray} The derived key.\n\t         *\n\t         * @example\n\t         *\n\t         *     var key = kdf.compute(password, salt);\n\t         */\n\t        compute: function (password, salt) {\n\t            // Shortcut\n\t            var cfg = this.cfg;\n\n\t            // Init hasher\n\t            var hasher = cfg.hasher.create();\n\n\t            // Initial values\n\t            var derivedKey = WordArray.create();\n\n\t            // Shortcuts\n\t            var derivedKeyWords = derivedKey.words;\n\t            var keySize = cfg.keySize;\n\t            var iterations = cfg.iterations;\n\n\t            // Generate key\n\t            while (derivedKeyWords.length < keySize) {\n\t                if (block) {\n\t                    hasher.update(block);\n\t                }\n\t                var block = hasher.update(password).finalize(salt);\n\t                hasher.reset();\n\n\t                // Iterations\n\t                for (var i = 1; i < iterations; i++) {\n\t                    block = hasher.finalize(block);\n\t                    hasher.reset();\n\t                }\n\n\t                derivedKey.concat(block);\n\t            }\n\t            derivedKey.sigBytes = keySize * 4;\n\n\t            return derivedKey;\n\t        }\n\t    });\n\n\t    /**\n\t     * Derives a key from a password.\n\t     *\n\t     * @param {WordArray|string} password The password.\n\t     * @param {WordArray|string} salt A salt.\n\t     * @param {Object} cfg (Optional) The configuration options to use for this computation.\n\t     *\n\t     * @return {WordArray} The derived key.\n\t     *\n\t     * @static\n\t     *\n\t     * @example\n\t     *\n\t     *     var key = CryptoJS.EvpKDF(password, salt);\n\t     *     var key = CryptoJS.EvpKDF(password, salt, { keySize: 8 });\n\t     *     var key = CryptoJS.EvpKDF(password, salt, { keySize: 8, iterations: 1000 });\n\t     */\n\t    C.EvpKDF = function (password, salt, cfg) {\n\t        return EvpKDF.create(cfg).compute(password, salt);\n\t    };\n\t}());\n\n\n\treturn CryptoJS.EvpKDF;\n\n}));\n\n/***/ }),\n/* 3 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t(function () {\n\t    // Shortcuts\n\t    var C = CryptoJS;\n\t    var C_lib = C.lib;\n\t    var WordArray = C_lib.WordArray;\n\t    var C_enc = C.enc;\n\n\t    /**\n\t     * Base64 encoding strategy.\n\t     */\n\t    var Base64 = C_enc.Base64 = {\n\t        /**\n\t         * Converts a word array to a Base64 string.\n\t         *\n\t         * @param {WordArray} wordArray The word array.\n\t         *\n\t         * @return {string} The Base64 string.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var base64String = CryptoJS.enc.Base64.stringify(wordArray);\n\t         */\n\t        stringify: function (wordArray) {\n\t            // Shortcuts\n\t            var words = wordArray.words;\n\t            var sigBytes = wordArray.sigBytes;\n\t            var map = this._map;\n\n\t            // Clamp excess bits\n\t            wordArray.clamp();\n\n\t            // Convert\n\t            var base64Chars = [];\n\t            for (var i = 0; i < sigBytes; i += 3) {\n\t                var byte1 = (words[i >>> 2]       >>> (24 - (i % 4) * 8))       & 0xff;\n\t                var byte2 = (words[(i + 1) >>> 2] >>> (24 - ((i + 1) % 4) * 8)) & 0xff;\n\t                var byte3 = (words[(i + 2) >>> 2] >>> (24 - ((i + 2) % 4) * 8)) & 0xff;\n\n\t                var triplet = (byte1 << 16) | (byte2 << 8) | byte3;\n\n\t                for (var j = 0; (j < 4) && (i + j * 0.75 < sigBytes); j++) {\n\t                    base64Chars.push(map.charAt((triplet >>> (6 * (3 - j))) & 0x3f));\n\t                }\n\t            }\n\n\t            // Add padding\n\t            var paddingChar = map.charAt(64);\n\t            if (paddingChar) {\n\t                while (base64Chars.length % 4) {\n\t                    base64Chars.push(paddingChar);\n\t                }\n\t            }\n\n\t            return base64Chars.join('');\n\t        },\n\n\t        /**\n\t         * Converts a Base64 string to a word array.\n\t         *\n\t         * @param {string} base64Str The Base64 string.\n\t         *\n\t         * @return {WordArray} The word array.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var wordArray = CryptoJS.enc.Base64.parse(base64String);\n\t         */\n\t        parse: function (base64Str) {\n\t            // Shortcuts\n\t            var base64StrLength = base64Str.length;\n\t            var map = this._map;\n\t            var reverseMap = this._reverseMap;\n\n\t            if (!reverseMap) {\n\t                    reverseMap = this._reverseMap = [];\n\t                    for (var j = 0; j < map.length; j++) {\n\t                        reverseMap[map.charCodeAt(j)] = j;\n\t                    }\n\t            }\n\n\t            // Ignore padding\n\t            var paddingChar = map.charAt(64);\n\t            if (paddingChar) {\n\t                var paddingIndex = base64Str.indexOf(paddingChar);\n\t                if (paddingIndex !== -1) {\n\t                    base64StrLength = paddingIndex;\n\t                }\n\t            }\n\n\t            // Convert\n\t            return parseLoop(base64Str, base64StrLength, reverseMap);\n\n\t        },\n\n\t        _map: 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/='\n\t    };\n\n\t    function parseLoop(base64Str, base64StrLength, reverseMap) {\n\t      var words = [];\n\t      var nBytes = 0;\n\t      for (var i = 0; i < base64StrLength; i++) {\n\t          if (i % 4) {\n\t              var bits1 = reverseMap[base64Str.charCodeAt(i - 1)] << ((i % 4) * 2);\n\t              var bits2 = reverseMap[base64Str.charCodeAt(i)] >>> (6 - (i % 4) * 2);\n\t              words[nBytes >>> 2] |= (bits1 | bits2) << (24 - (nBytes % 4) * 8);\n\t              nBytes++;\n\t          }\n\t      }\n\t      return WordArray.create(words, nBytes);\n\t    }\n\t}());\n\n\n\treturn CryptoJS.enc.Base64;\n\n}));\n\n/***/ }),\n/* 4 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t(function (Math) {\n\t    // Shortcuts\n\t    var C = CryptoJS;\n\t    var C_lib = C.lib;\n\t    var WordArray = C_lib.WordArray;\n\t    var Hasher = C_lib.Hasher;\n\t    var C_algo = C.algo;\n\n\t    // Constants table\n\t    var T = [];\n\n\t    // Compute constants\n\t    (function () {\n\t        for (var i = 0; i < 64; i++) {\n\t            T[i] = (Math.abs(Math.sin(i + 1)) * 0x100000000) | 0;\n\t        }\n\t    }());\n\n\t    /**\n\t     * MD5 hash algorithm.\n\t     */\n\t    var MD5 = C_algo.MD5 = Hasher.extend({\n\t        _doReset: function () {\n\t            this._hash = new WordArray.init([\n\t                0x67452301, 0xefcdab89,\n\t                0x98badcfe, 0x10325476\n\t            ]);\n\t        },\n\n\t        _doProcessBlock: function (M, offset) {\n\t            // Swap endian\n\t            for (var i = 0; i < 16; i++) {\n\t                // Shortcuts\n\t                var offset_i = offset + i;\n\t                var M_offset_i = M[offset_i];\n\n\t                M[offset_i] = (\n\t                    (((M_offset_i << 8)  | (M_offset_i >>> 24)) & 0x00ff00ff) |\n\t                    (((M_offset_i << 24) | (M_offset_i >>> 8))  & 0xff00ff00)\n\t                );\n\t            }\n\n\t            // Shortcuts\n\t            var H = this._hash.words;\n\n\t            var M_offset_0  = M[offset + 0];\n\t            var M_offset_1  = M[offset + 1];\n\t            var M_offset_2  = M[offset + 2];\n\t            var M_offset_3  = M[offset + 3];\n\t            var M_offset_4  = M[offset + 4];\n\t            var M_offset_5  = M[offset + 5];\n\t            var M_offset_6  = M[offset + 6];\n\t            var M_offset_7  = M[offset + 7];\n\t            var M_offset_8  = M[offset + 8];\n\t            var M_offset_9  = M[offset + 9];\n\t            var M_offset_10 = M[offset + 10];\n\t            var M_offset_11 = M[offset + 11];\n\t            var M_offset_12 = M[offset + 12];\n\t            var M_offset_13 = M[offset + 13];\n\t            var M_offset_14 = M[offset + 14];\n\t            var M_offset_15 = M[offset + 15];\n\n\t            // Working varialbes\n\t            var a = H[0];\n\t            var b = H[1];\n\t            var c = H[2];\n\t            var d = H[3];\n\n\t            // Computation\n\t            a = FF(a, b, c, d, M_offset_0,  7,  T[0]);\n\t            d = FF(d, a, b, c, M_offset_1,  12, T[1]);\n\t            c = FF(c, d, a, b, M_offset_2,  17, T[2]);\n\t            b = FF(b, c, d, a, M_offset_3,  22, T[3]);\n\t            a = FF(a, b, c, d, M_offset_4,  7,  T[4]);\n\t            d = FF(d, a, b, c, M_offset_5,  12, T[5]);\n\t            c = FF(c, d, a, b, M_offset_6,  17, T[6]);\n\t            b = FF(b, c, d, a, M_offset_7,  22, T[7]);\n\t            a = FF(a, b, c, d, M_offset_8,  7,  T[8]);\n\t            d = FF(d, a, b, c, M_offset_9,  12, T[9]);\n\t            c = FF(c, d, a, b, M_offset_10, 17, T[10]);\n\t            b = FF(b, c, d, a, M_offset_11, 22, T[11]);\n\t            a = FF(a, b, c, d, M_offset_12, 7,  T[12]);\n\t            d = FF(d, a, b, c, M_offset_13, 12, T[13]);\n\t            c = FF(c, d, a, b, M_offset_14, 17, T[14]);\n\t            b = FF(b, c, d, a, M_offset_15, 22, T[15]);\n\n\t            a = GG(a, b, c, d, M_offset_1,  5,  T[16]);\n\t            d = GG(d, a, b, c, M_offset_6,  9,  T[17]);\n\t            c = GG(c, d, a, b, M_offset_11, 14, T[18]);\n\t            b = GG(b, c, d, a, M_offset_0,  20, T[19]);\n\t            a = GG(a, b, c, d, M_offset_5,  5,  T[20]);\n\t            d = GG(d, a, b, c, M_offset_10, 9,  T[21]);\n\t            c = GG(c, d, a, b, M_offset_15, 14, T[22]);\n\t            b = GG(b, c, d, a, M_offset_4,  20, T[23]);\n\t            a = GG(a, b, c, d, M_offset_9,  5,  T[24]);\n\t            d = GG(d, a, b, c, M_offset_14, 9,  T[25]);\n\t            c = GG(c, d, a, b, M_offset_3,  14, T[26]);\n\t            b = GG(b, c, d, a, M_offset_8,  20, T[27]);\n\t            a = GG(a, b, c, d, M_offset_13, 5,  T[28]);\n\t            d = GG(d, a, b, c, M_offset_2,  9,  T[29]);\n\t            c = GG(c, d, a, b, M_offset_7,  14, T[30]);\n\t            b = GG(b, c, d, a, M_offset_12, 20, T[31]);\n\n\t            a = HH(a, b, c, d, M_offset_5,  4,  T[32]);\n\t            d = HH(d, a, b, c, M_offset_8,  11, T[33]);\n\t            c = HH(c, d, a, b, M_offset_11, 16, T[34]);\n\t            b = HH(b, c, d, a, M_offset_14, 23, T[35]);\n\t            a = HH(a, b, c, d, M_offset_1,  4,  T[36]);\n\t            d = HH(d, a, b, c, M_offset_4,  11, T[37]);\n\t            c = HH(c, d, a, b, M_offset_7,  16, T[38]);\n\t            b = HH(b, c, d, a, M_offset_10, 23, T[39]);\n\t            a = HH(a, b, c, d, M_offset_13, 4,  T[40]);\n\t            d = HH(d, a, b, c, M_offset_0,  11, T[41]);\n\t            c = HH(c, d, a, b, M_offset_3,  16, T[42]);\n\t            b = HH(b, c, d, a, M_offset_6,  23, T[43]);\n\t            a = HH(a, b, c, d, M_offset_9,  4,  T[44]);\n\t            d = HH(d, a, b, c, M_offset_12, 11, T[45]);\n\t            c = HH(c, d, a, b, M_offset_15, 16, T[46]);\n\t            b = HH(b, c, d, a, M_offset_2,  23, T[47]);\n\n\t            a = II(a, b, c, d, M_offset_0,  6,  T[48]);\n\t            d = II(d, a, b, c, M_offset_7,  10, T[49]);\n\t            c = II(c, d, a, b, M_offset_14, 15, T[50]);\n\t            b = II(b, c, d, a, M_offset_5,  21, T[51]);\n\t            a = II(a, b, c, d, M_offset_12, 6,  T[52]);\n\t            d = II(d, a, b, c, M_offset_3,  10, T[53]);\n\t            c = II(c, d, a, b, M_offset_10, 15, T[54]);\n\t            b = II(b, c, d, a, M_offset_1,  21, T[55]);\n\t            a = II(a, b, c, d, M_offset_8,  6,  T[56]);\n\t            d = II(d, a, b, c, M_offset_15, 10, T[57]);\n\t            c = II(c, d, a, b, M_offset_6,  15, T[58]);\n\t            b = II(b, c, d, a, M_offset_13, 21, T[59]);\n\t            a = II(a, b, c, d, M_offset_4,  6,  T[60]);\n\t            d = II(d, a, b, c, M_offset_11, 10, T[61]);\n\t            c = II(c, d, a, b, M_offset_2,  15, T[62]);\n\t            b = II(b, c, d, a, M_offset_9,  21, T[63]);\n\n\t            // Intermediate hash value\n\t            H[0] = (H[0] + a) | 0;\n\t            H[1] = (H[1] + b) | 0;\n\t            H[2] = (H[2] + c) | 0;\n\t            H[3] = (H[3] + d) | 0;\n\t        },\n\n\t        _doFinalize: function () {\n\t            // Shortcuts\n\t            var data = this._data;\n\t            var dataWords = data.words;\n\n\t            var nBitsTotal = this._nDataBytes * 8;\n\t            var nBitsLeft = data.sigBytes * 8;\n\n\t            // Add padding\n\t            dataWords[nBitsLeft >>> 5] |= 0x80 << (24 - nBitsLeft % 32);\n\n\t            var nBitsTotalH = Math.floor(nBitsTotal / 0x100000000);\n\t            var nBitsTotalL = nBitsTotal;\n\t            dataWords[(((nBitsLeft + 64) >>> 9) << 4) + 15] = (\n\t                (((nBitsTotalH << 8)  | (nBitsTotalH >>> 24)) & 0x00ff00ff) |\n\t                (((nBitsTotalH << 24) | (nBitsTotalH >>> 8))  & 0xff00ff00)\n\t            );\n\t            dataWords[(((nBitsLeft + 64) >>> 9) << 4) + 14] = (\n\t                (((nBitsTotalL << 8)  | (nBitsTotalL >>> 24)) & 0x00ff00ff) |\n\t                (((nBitsTotalL << 24) | (nBitsTotalL >>> 8))  & 0xff00ff00)\n\t            );\n\n\t            data.sigBytes = (dataWords.length + 1) * 4;\n\n\t            // Hash final blocks\n\t            this._process();\n\n\t            // Shortcuts\n\t            var hash = this._hash;\n\t            var H = hash.words;\n\n\t            // Swap endian\n\t            for (var i = 0; i < 4; i++) {\n\t                // Shortcut\n\t                var H_i = H[i];\n\n\t                H[i] = (((H_i << 8)  | (H_i >>> 24)) & 0x00ff00ff) |\n\t                       (((H_i << 24) | (H_i >>> 8))  & 0xff00ff00);\n\t            }\n\n\t            // Return final computed hash\n\t            return hash;\n\t        },\n\n\t        clone: function () {\n\t            var clone = Hasher.clone.call(this);\n\t            clone._hash = this._hash.clone();\n\n\t            return clone;\n\t        }\n\t    });\n\n\t    function FF(a, b, c, d, x, s, t) {\n\t        var n = a + ((b & c) | (~b & d)) + x + t;\n\t        return ((n << s) | (n >>> (32 - s))) + b;\n\t    }\n\n\t    function GG(a, b, c, d, x, s, t) {\n\t        var n = a + ((b & d) | (c & ~d)) + x + t;\n\t        return ((n << s) | (n >>> (32 - s))) + b;\n\t    }\n\n\t    function HH(a, b, c, d, x, s, t) {\n\t        var n = a + (b ^ c ^ d) + x + t;\n\t        return ((n << s) | (n >>> (32 - s))) + b;\n\t    }\n\n\t    function II(a, b, c, d, x, s, t) {\n\t        var n = a + (c ^ (b | ~d)) + x + t;\n\t        return ((n << s) | (n >>> (32 - s))) + b;\n\t    }\n\n\t    /**\n\t     * Shortcut function to the hasher's object interface.\n\t     *\n\t     * @param {WordArray|string} message The message to hash.\n\t     *\n\t     * @return {WordArray} The hash.\n\t     *\n\t     * @static\n\t     *\n\t     * @example\n\t     *\n\t     *     var hash = CryptoJS.MD5('message');\n\t     *     var hash = CryptoJS.MD5(wordArray);\n\t     */\n\t    C.MD5 = Hasher._createHelper(MD5);\n\n\t    /**\n\t     * Shortcut function to the HMAC's object interface.\n\t     *\n\t     * @param {WordArray|string} message The message to hash.\n\t     * @param {WordArray|string} key The secret key.\n\t     *\n\t     * @return {WordArray} The HMAC.\n\t     *\n\t     * @static\n\t     *\n\t     * @example\n\t     *\n\t     *     var hmac = CryptoJS.HmacMD5(message, key);\n\t     */\n\t    C.HmacMD5 = Hasher._createHmacHelper(MD5);\n\t}(Math));\n\n\n\treturn CryptoJS.MD5;\n\n}));\n\n/***/ }),\n/* 5 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t(function (undefined) {\n\t    // Shortcuts\n\t    var C = CryptoJS;\n\t    var C_lib = C.lib;\n\t    var Base = C_lib.Base;\n\t    var X32WordArray = C_lib.WordArray;\n\n\t    /**\n\t     * x64 namespace.\n\t     */\n\t    var C_x64 = C.x64 = {};\n\n\t    /**\n\t     * A 64-bit word.\n\t     */\n\t    var X64Word = C_x64.Word = Base.extend({\n\t        /**\n\t         * Initializes a newly created 64-bit word.\n\t         *\n\t         * @param {number} high The high 32 bits.\n\t         * @param {number} low The low 32 bits.\n\t         *\n\t         * @example\n\t         *\n\t         *     var x64Word = CryptoJS.x64.Word.create(0x00010203, 0x04050607);\n\t         */\n\t        init: function (high, low) {\n\t            this.high = high;\n\t            this.low = low;\n\t        }\n\n\t        /**\n\t         * Bitwise NOTs this word.\n\t         *\n\t         * @return {X64Word} A new x64-Word object after negating.\n\t         *\n\t         * @example\n\t         *\n\t         *     var negated = x64Word.not();\n\t         */\n\t        // not: function () {\n\t            // var high = ~this.high;\n\t            // var low = ~this.low;\n\n\t            // return X64Word.create(high, low);\n\t        // },\n\n\t        /**\n\t         * Bitwise ANDs this word with the passed word.\n\t         *\n\t         * @param {X64Word} word The x64-Word to AND with this word.\n\t         *\n\t         * @return {X64Word} A new x64-Word object after ANDing.\n\t         *\n\t         * @example\n\t         *\n\t         *     var anded = x64Word.and(anotherX64Word);\n\t         */\n\t        // and: function (word) {\n\t            // var high = this.high & word.high;\n\t            // var low = this.low & word.low;\n\n\t            // return X64Word.create(high, low);\n\t        // },\n\n\t        /**\n\t         * Bitwise ORs this word with the passed word.\n\t         *\n\t         * @param {X64Word} word The x64-Word to OR with this word.\n\t         *\n\t         * @return {X64Word} A new x64-Word object after ORing.\n\t         *\n\t         * @example\n\t         *\n\t         *     var ored = x64Word.or(anotherX64Word);\n\t         */\n\t        // or: function (word) {\n\t            // var high = this.high | word.high;\n\t            // var low = this.low | word.low;\n\n\t            // return X64Word.create(high, low);\n\t        // },\n\n\t        /**\n\t         * Bitwise XORs this word with the passed word.\n\t         *\n\t         * @param {X64Word} word The x64-Word to XOR with this word.\n\t         *\n\t         * @return {X64Word} A new x64-Word object after XORing.\n\t         *\n\t         * @example\n\t         *\n\t         *     var xored = x64Word.xor(anotherX64Word);\n\t         */\n\t        // xor: function (word) {\n\t            // var high = this.high ^ word.high;\n\t            // var low = this.low ^ word.low;\n\n\t            // return X64Word.create(high, low);\n\t        // },\n\n\t        /**\n\t         * Shifts this word n bits to the left.\n\t         *\n\t         * @param {number} n The number of bits to shift.\n\t         *\n\t         * @return {X64Word} A new x64-Word object after shifting.\n\t         *\n\t         * @example\n\t         *\n\t         *     var shifted = x64Word.shiftL(25);\n\t         */\n\t        // shiftL: function (n) {\n\t            // if (n < 32) {\n\t                // var high = (this.high << n) | (this.low >>> (32 - n));\n\t                // var low = this.low << n;\n\t            // } else {\n\t                // var high = this.low << (n - 32);\n\t                // var low = 0;\n\t            // }\n\n\t            // return X64Word.create(high, low);\n\t        // },\n\n\t        /**\n\t         * Shifts this word n bits to the right.\n\t         *\n\t         * @param {number} n The number of bits to shift.\n\t         *\n\t         * @return {X64Word} A new x64-Word object after shifting.\n\t         *\n\t         * @example\n\t         *\n\t         *     var shifted = x64Word.shiftR(7);\n\t         */\n\t        // shiftR: function (n) {\n\t            // if (n < 32) {\n\t                // var low = (this.low >>> n) | (this.high << (32 - n));\n\t                // var high = this.high >>> n;\n\t            // } else {\n\t                // var low = this.high >>> (n - 32);\n\t                // var high = 0;\n\t            // }\n\n\t            // return X64Word.create(high, low);\n\t        // },\n\n\t        /**\n\t         * Rotates this word n bits to the left.\n\t         *\n\t         * @param {number} n The number of bits to rotate.\n\t         *\n\t         * @return {X64Word} A new x64-Word object after rotating.\n\t         *\n\t         * @example\n\t         *\n\t         *     var rotated = x64Word.rotL(25);\n\t         */\n\t        // rotL: function (n) {\n\t            // return this.shiftL(n).or(this.shiftR(64 - n));\n\t        // },\n\n\t        /**\n\t         * Rotates this word n bits to the right.\n\t         *\n\t         * @param {number} n The number of bits to rotate.\n\t         *\n\t         * @return {X64Word} A new x64-Word object after rotating.\n\t         *\n\t         * @example\n\t         *\n\t         *     var rotated = x64Word.rotR(7);\n\t         */\n\t        // rotR: function (n) {\n\t            // return this.shiftR(n).or(this.shiftL(64 - n));\n\t        // },\n\n\t        /**\n\t         * Adds this word with the passed word.\n\t         *\n\t         * @param {X64Word} word The x64-Word to add with this word.\n\t         *\n\t         * @return {X64Word} A new x64-Word object after adding.\n\t         *\n\t         * @example\n\t         *\n\t         *     var added = x64Word.add(anotherX64Word);\n\t         */\n\t        // add: function (word) {\n\t            // var low = (this.low + word.low) | 0;\n\t            // var carry = (low >>> 0) < (this.low >>> 0) ? 1 : 0;\n\t            // var high = (this.high + word.high + carry) | 0;\n\n\t            // return X64Word.create(high, low);\n\t        // }\n\t    });\n\n\t    /**\n\t     * An array of 64-bit words.\n\t     *\n\t     * @property {Array} words The array of CryptoJS.x64.Word objects.\n\t     * @property {number} sigBytes The number of significant bytes in this word array.\n\t     */\n\t    var X64WordArray = C_x64.WordArray = Base.extend({\n\t        /**\n\t         * Initializes a newly created word array.\n\t         *\n\t         * @param {Array} words (Optional) An array of CryptoJS.x64.Word objects.\n\t         * @param {number} sigBytes (Optional) The number of significant bytes in the words.\n\t         *\n\t         * @example\n\t         *\n\t         *     var wordArray = CryptoJS.x64.WordArray.create();\n\t         *\n\t         *     var wordArray = CryptoJS.x64.WordArray.create([\n\t         *         CryptoJS.x64.Word.create(0x00010203, 0x04050607),\n\t         *         CryptoJS.x64.Word.create(0x18191a1b, 0x1c1d1e1f)\n\t         *     ]);\n\t         *\n\t         *     var wordArray = CryptoJS.x64.WordArray.create([\n\t         *         CryptoJS.x64.Word.create(0x00010203, 0x04050607),\n\t         *         CryptoJS.x64.Word.create(0x18191a1b, 0x1c1d1e1f)\n\t         *     ], 10);\n\t         */\n\t        init: function (words, sigBytes) {\n\t            words = this.words = words || [];\n\n\t            if (sigBytes != undefined) {\n\t                this.sigBytes = sigBytes;\n\t            } else {\n\t                this.sigBytes = words.length * 8;\n\t            }\n\t        },\n\n\t        /**\n\t         * Converts this 64-bit word array to a 32-bit word array.\n\t         *\n\t         * @return {CryptoJS.lib.WordArray} This word array's data as a 32-bit word array.\n\t         *\n\t         * @example\n\t         *\n\t         *     var x32WordArray = x64WordArray.toX32();\n\t         */\n\t        toX32: function () {\n\t            // Shortcuts\n\t            var x64Words = this.words;\n\t            var x64WordsLength = x64Words.length;\n\n\t            // Convert\n\t            var x32Words = [];\n\t            for (var i = 0; i < x64WordsLength; i++) {\n\t                var x64Word = x64Words[i];\n\t                x32Words.push(x64Word.high);\n\t                x32Words.push(x64Word.low);\n\t            }\n\n\t            return X32WordArray.create(x32Words, this.sigBytes);\n\t        },\n\n\t        /**\n\t         * Creates a copy of this word array.\n\t         *\n\t         * @return {X64WordArray} The clone.\n\t         *\n\t         * @example\n\t         *\n\t         *     var clone = x64WordArray.clone();\n\t         */\n\t        clone: function () {\n\t            var clone = Base.clone.call(this);\n\n\t            // Clone \"words\" array\n\t            var words = clone.words = this.words.slice(0);\n\n\t            // Clone each X64Word object\n\t            var wordsLength = words.length;\n\t            for (var i = 0; i < wordsLength; i++) {\n\t                words[i] = words[i].clone();\n\t            }\n\n\t            return clone;\n\t        }\n\t    });\n\t}());\n\n\n\treturn CryptoJS;\n\n}));\n\n/***/ }),\n/* 6 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t(function () {\n\t    // Shortcuts\n\t    var C = CryptoJS;\n\t    var C_lib = C.lib;\n\t    var WordArray = C_lib.WordArray;\n\t    var Hasher = C_lib.Hasher;\n\t    var C_algo = C.algo;\n\n\t    // Reusable object\n\t    var W = [];\n\n\t    /**\n\t     * SHA-1 hash algorithm.\n\t     */\n\t    var SHA1 = C_algo.SHA1 = Hasher.extend({\n\t        _doReset: function () {\n\t            this._hash = new WordArray.init([\n\t                0x67452301, 0xefcdab89,\n\t                0x98badcfe, 0x10325476,\n\t                0xc3d2e1f0\n\t            ]);\n\t        },\n\n\t        _doProcessBlock: function (M, offset) {\n\t            // Shortcut\n\t            var H = this._hash.words;\n\n\t            // Working variables\n\t            var a = H[0];\n\t            var b = H[1];\n\t            var c = H[2];\n\t            var d = H[3];\n\t            var e = H[4];\n\n\t            // Computation\n\t            for (var i = 0; i < 80; i++) {\n\t                if (i < 16) {\n\t                    W[i] = M[offset + i] | 0;\n\t                } else {\n\t                    var n = W[i - 3] ^ W[i - 8] ^ W[i - 14] ^ W[i - 16];\n\t                    W[i] = (n << 1) | (n >>> 31);\n\t                }\n\n\t                var t = ((a << 5) | (a >>> 27)) + e + W[i];\n\t                if (i < 20) {\n\t                    t += ((b & c) | (~b & d)) + 0x5a827999;\n\t                } else if (i < 40) {\n\t                    t += (b ^ c ^ d) + 0x6ed9eba1;\n\t                } else if (i < 60) {\n\t                    t += ((b & c) | (b & d) | (c & d)) - 0x70e44324;\n\t                } else /* if (i < 80) */ {\n\t                    t += (b ^ c ^ d) - 0x359d3e2a;\n\t                }\n\n\t                e = d;\n\t                d = c;\n\t                c = (b << 30) | (b >>> 2);\n\t                b = a;\n\t                a = t;\n\t            }\n\n\t            // Intermediate hash value\n\t            H[0] = (H[0] + a) | 0;\n\t            H[1] = (H[1] + b) | 0;\n\t            H[2] = (H[2] + c) | 0;\n\t            H[3] = (H[3] + d) | 0;\n\t            H[4] = (H[4] + e) | 0;\n\t        },\n\n\t        _doFinalize: function () {\n\t            // Shortcuts\n\t            var data = this._data;\n\t            var dataWords = data.words;\n\n\t            var nBitsTotal = this._nDataBytes * 8;\n\t            var nBitsLeft = data.sigBytes * 8;\n\n\t            // Add padding\n\t            dataWords[nBitsLeft >>> 5] |= 0x80 << (24 - nBitsLeft % 32);\n\t            dataWords[(((nBitsLeft + 64) >>> 9) << 4) + 14] = Math.floor(nBitsTotal / 0x100000000);\n\t            dataWords[(((nBitsLeft + 64) >>> 9) << 4) + 15] = nBitsTotal;\n\t            data.sigBytes = dataWords.length * 4;\n\n\t            // Hash final blocks\n\t            this._process();\n\n\t            // Return final computed hash\n\t            return this._hash;\n\t        },\n\n\t        clone: function () {\n\t            var clone = Hasher.clone.call(this);\n\t            clone._hash = this._hash.clone();\n\n\t            return clone;\n\t        }\n\t    });\n\n\t    /**\n\t     * Shortcut function to the hasher's object interface.\n\t     *\n\t     * @param {WordArray|string} message The message to hash.\n\t     *\n\t     * @return {WordArray} The hash.\n\t     *\n\t     * @static\n\t     *\n\t     * @example\n\t     *\n\t     *     var hash = CryptoJS.SHA1('message');\n\t     *     var hash = CryptoJS.SHA1(wordArray);\n\t     */\n\t    C.SHA1 = Hasher._createHelper(SHA1);\n\n\t    /**\n\t     * Shortcut function to the HMAC's object interface.\n\t     *\n\t     * @param {WordArray|string} message The message to hash.\n\t     * @param {WordArray|string} key The secret key.\n\t     *\n\t     * @return {WordArray} The HMAC.\n\t     *\n\t     * @static\n\t     *\n\t     * @example\n\t     *\n\t     *     var hmac = CryptoJS.HmacSHA1(message, key);\n\t     */\n\t    C.HmacSHA1 = Hasher._createHmacHelper(SHA1);\n\t}());\n\n\n\treturn CryptoJS.SHA1;\n\n}));\n\n/***/ }),\n/* 7 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t(function () {\n\t    // Shortcuts\n\t    var C = CryptoJS;\n\t    var C_lib = C.lib;\n\t    var Base = C_lib.Base;\n\t    var C_enc = C.enc;\n\t    var Utf8 = C_enc.Utf8;\n\t    var C_algo = C.algo;\n\n\t    /**\n\t     * HMAC algorithm.\n\t     */\n\t    var HMAC = C_algo.HMAC = Base.extend({\n\t        /**\n\t         * Initializes a newly created HMAC.\n\t         *\n\t         * @param {Hasher} hasher The hash algorithm to use.\n\t         * @param {WordArray|string} key The secret key.\n\t         *\n\t         * @example\n\t         *\n\t         *     var hmacHasher = CryptoJS.algo.HMAC.create(CryptoJS.algo.SHA256, key);\n\t         */\n\t        init: function (hasher, key) {\n\t            // Init hasher\n\t            hasher = this._hasher = new hasher.init();\n\n\t            // Convert string to WordArray, else assume WordArray already\n\t            if (typeof key == 'string') {\n\t                key = Utf8.parse(key);\n\t            }\n\n\t            // Shortcuts\n\t            var hasherBlockSize = hasher.blockSize;\n\t            var hasherBlockSizeBytes = hasherBlockSize * 4;\n\n\t            // Allow arbitrary length keys\n\t            if (key.sigBytes > hasherBlockSizeBytes) {\n\t                key = hasher.finalize(key);\n\t            }\n\n\t            // Clamp excess bits\n\t            key.clamp();\n\n\t            // Clone key for inner and outer pads\n\t            var oKey = this._oKey = key.clone();\n\t            var iKey = this._iKey = key.clone();\n\n\t            // Shortcuts\n\t            var oKeyWords = oKey.words;\n\t            var iKeyWords = iKey.words;\n\n\t            // XOR keys with pad constants\n\t            for (var i = 0; i < hasherBlockSize; i++) {\n\t                oKeyWords[i] ^= 0x5c5c5c5c;\n\t                iKeyWords[i] ^= 0x36363636;\n\t            }\n\t            oKey.sigBytes = iKey.sigBytes = hasherBlockSizeBytes;\n\n\t            // Set initial values\n\t            this.reset();\n\t        },\n\n\t        /**\n\t         * Resets this HMAC to its initial state.\n\t         *\n\t         * @example\n\t         *\n\t         *     hmacHasher.reset();\n\t         */\n\t        reset: function () {\n\t            // Shortcut\n\t            var hasher = this._hasher;\n\n\t            // Reset\n\t            hasher.reset();\n\t            hasher.update(this._iKey);\n\t        },\n\n\t        /**\n\t         * Updates this HMAC with a message.\n\t         *\n\t         * @param {WordArray|string} messageUpdate The message to append.\n\t         *\n\t         * @return {HMAC} This HMAC instance.\n\t         *\n\t         * @example\n\t         *\n\t         *     hmacHasher.update('message');\n\t         *     hmacHasher.update(wordArray);\n\t         */\n\t        update: function (messageUpdate) {\n\t            this._hasher.update(messageUpdate);\n\n\t            // Chainable\n\t            return this;\n\t        },\n\n\t        /**\n\t         * Finalizes the HMAC computation.\n\t         * Note that the finalize operation is effectively a destructive, read-once operation.\n\t         *\n\t         * @param {WordArray|string} messageUpdate (Optional) A final message update.\n\t         *\n\t         * @return {WordArray} The HMAC.\n\t         *\n\t         * @example\n\t         *\n\t         *     var hmac = hmacHasher.finalize();\n\t         *     var hmac = hmacHasher.finalize('message');\n\t         *     var hmac = hmacHasher.finalize(wordArray);\n\t         */\n\t        finalize: function (messageUpdate) {\n\t            // Shortcut\n\t            var hasher = this._hasher;\n\n\t            // Compute HMAC\n\t            var innerHash = hasher.finalize(messageUpdate);\n\t            hasher.reset();\n\t            var hmac = hasher.finalize(this._oKey.clone().concat(innerHash));\n\n\t            return hmac;\n\t        }\n\t    });\n\t}());\n\n\n}));\n\n/***/ }),\n/* 8 */\n/***/ (function(module, exports) {\n\nvar g;\n\n// This works in non-strict mode\ng = (function() {\n\treturn this;\n})();\n\ntry {\n\t// This works if eval is allowed (see CSP)\n\tg = g || Function(\"return this\")() || (1, eval)(\"this\");\n} catch (e) {\n\t// This works if the window reference is available\n\tif (typeof window === \"object\") g = window;\n}\n\n// g can still be undefined, but nothing to do about it...\n// We return undefined, instead of nothing here, so it's\n// easier to handle this case. if(!global) { ...}\n\nmodule.exports = g;\n\n\n/***/ }),\n/* 9 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory, undef) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0), __webpack_require__(5), __webpack_require__(13), __webpack_require__(14), __webpack_require__(3), __webpack_require__(4), __webpack_require__(6), __webpack_require__(10), __webpack_require__(15), __webpack_require__(11), __webpack_require__(16), __webpack_require__(17), __webpack_require__(18), __webpack_require__(7), __webpack_require__(19), __webpack_require__(2), __webpack_require__(1), __webpack_require__(20), __webpack_require__(21), __webpack_require__(22), __webpack_require__(23), __webpack_require__(24), __webpack_require__(25), __webpack_require__(26), __webpack_require__(27), __webpack_require__(28), __webpack_require__(29), __webpack_require__(30), __webpack_require__(31), __webpack_require__(32), __webpack_require__(33), __webpack_require__(34), __webpack_require__(35));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\treturn CryptoJS;\n\n}));\n\n/***/ }),\n/* 10 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t(function (Math) {\n\t    // Shortcuts\n\t    var C = CryptoJS;\n\t    var C_lib = C.lib;\n\t    var WordArray = C_lib.WordArray;\n\t    var Hasher = C_lib.Hasher;\n\t    var C_algo = C.algo;\n\n\t    // Initialization and round constants tables\n\t    var H = [];\n\t    var K = [];\n\n\t    // Compute constants\n\t    (function () {\n\t        function isPrime(n) {\n\t            var sqrtN = Math.sqrt(n);\n\t            for (var factor = 2; factor <= sqrtN; factor++) {\n\t                if (!(n % factor)) {\n\t                    return false;\n\t                }\n\t            }\n\n\t            return true;\n\t        }\n\n\t        function getFractionalBits(n) {\n\t            return ((n - (n | 0)) * 0x100000000) | 0;\n\t        }\n\n\t        var n = 2;\n\t        var nPrime = 0;\n\t        while (nPrime < 64) {\n\t            if (isPrime(n)) {\n\t                if (nPrime < 8) {\n\t                    H[nPrime] = getFractionalBits(Math.pow(n, 1 / 2));\n\t                }\n\t                K[nPrime] = getFractionalBits(Math.pow(n, 1 / 3));\n\n\t                nPrime++;\n\t            }\n\n\t            n++;\n\t        }\n\t    }());\n\n\t    // Reusable object\n\t    var W = [];\n\n\t    /**\n\t     * SHA-256 hash algorithm.\n\t     */\n\t    var SHA256 = C_algo.SHA256 = Hasher.extend({\n\t        _doReset: function () {\n\t            this._hash = new WordArray.init(H.slice(0));\n\t        },\n\n\t        _doProcessBlock: function (M, offset) {\n\t            // Shortcut\n\t            var H = this._hash.words;\n\n\t            // Working variables\n\t            var a = H[0];\n\t            var b = H[1];\n\t            var c = H[2];\n\t            var d = H[3];\n\t            var e = H[4];\n\t            var f = H[5];\n\t            var g = H[6];\n\t            var h = H[7];\n\n\t            // Computation\n\t            for (var i = 0; i < 64; i++) {\n\t                if (i < 16) {\n\t                    W[i] = M[offset + i] | 0;\n\t                } else {\n\t                    var gamma0x = W[i - 15];\n\t                    var gamma0  = ((gamma0x << 25) | (gamma0x >>> 7))  ^\n\t                                  ((gamma0x << 14) | (gamma0x >>> 18)) ^\n\t                                   (gamma0x >>> 3);\n\n\t                    var gamma1x = W[i - 2];\n\t                    var gamma1  = ((gamma1x << 15) | (gamma1x >>> 17)) ^\n\t                                  ((gamma1x << 13) | (gamma1x >>> 19)) ^\n\t                                   (gamma1x >>> 10);\n\n\t                    W[i] = gamma0 + W[i - 7] + gamma1 + W[i - 16];\n\t                }\n\n\t                var ch  = (e & f) ^ (~e & g);\n\t                var maj = (a & b) ^ (a & c) ^ (b & c);\n\n\t                var sigma0 = ((a << 30) | (a >>> 2)) ^ ((a << 19) | (a >>> 13)) ^ ((a << 10) | (a >>> 22));\n\t                var sigma1 = ((e << 26) | (e >>> 6)) ^ ((e << 21) | (e >>> 11)) ^ ((e << 7)  | (e >>> 25));\n\n\t                var t1 = h + sigma1 + ch + K[i] + W[i];\n\t                var t2 = sigma0 + maj;\n\n\t                h = g;\n\t                g = f;\n\t                f = e;\n\t                e = (d + t1) | 0;\n\t                d = c;\n\t                c = b;\n\t                b = a;\n\t                a = (t1 + t2) | 0;\n\t            }\n\n\t            // Intermediate hash value\n\t            H[0] = (H[0] + a) | 0;\n\t            H[1] = (H[1] + b) | 0;\n\t            H[2] = (H[2] + c) | 0;\n\t            H[3] = (H[3] + d) | 0;\n\t            H[4] = (H[4] + e) | 0;\n\t            H[5] = (H[5] + f) | 0;\n\t            H[6] = (H[6] + g) | 0;\n\t            H[7] = (H[7] + h) | 0;\n\t        },\n\n\t        _doFinalize: function () {\n\t            // Shortcuts\n\t            var data = this._data;\n\t            var dataWords = data.words;\n\n\t            var nBitsTotal = this._nDataBytes * 8;\n\t            var nBitsLeft = data.sigBytes * 8;\n\n\t            // Add padding\n\t            dataWords[nBitsLeft >>> 5] |= 0x80 << (24 - nBitsLeft % 32);\n\t            dataWords[(((nBitsLeft + 64) >>> 9) << 4) + 14] = Math.floor(nBitsTotal / 0x100000000);\n\t            dataWords[(((nBitsLeft + 64) >>> 9) << 4) + 15] = nBitsTotal;\n\t            data.sigBytes = dataWords.length * 4;\n\n\t            // Hash final blocks\n\t            this._process();\n\n\t            // Return final computed hash\n\t            return this._hash;\n\t        },\n\n\t        clone: function () {\n\t            var clone = Hasher.clone.call(this);\n\t            clone._hash = this._hash.clone();\n\n\t            return clone;\n\t        }\n\t    });\n\n\t    /**\n\t     * Shortcut function to the hasher's object interface.\n\t     *\n\t     * @param {WordArray|string} message The message to hash.\n\t     *\n\t     * @return {WordArray} The hash.\n\t     *\n\t     * @static\n\t     *\n\t     * @example\n\t     *\n\t     *     var hash = CryptoJS.SHA256('message');\n\t     *     var hash = CryptoJS.SHA256(wordArray);\n\t     */\n\t    C.SHA256 = Hasher._createHelper(SHA256);\n\n\t    /**\n\t     * Shortcut function to the HMAC's object interface.\n\t     *\n\t     * @param {WordArray|string} message The message to hash.\n\t     * @param {WordArray|string} key The secret key.\n\t     *\n\t     * @return {WordArray} The HMAC.\n\t     *\n\t     * @static\n\t     *\n\t     * @example\n\t     *\n\t     *     var hmac = CryptoJS.HmacSHA256(message, key);\n\t     */\n\t    C.HmacSHA256 = Hasher._createHmacHelper(SHA256);\n\t}(Math));\n\n\n\treturn CryptoJS.SHA256;\n\n}));\n\n/***/ }),\n/* 11 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory, undef) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0), __webpack_require__(5));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t(function () {\n\t    // Shortcuts\n\t    var C = CryptoJS;\n\t    var C_lib = C.lib;\n\t    var Hasher = C_lib.Hasher;\n\t    var C_x64 = C.x64;\n\t    var X64Word = C_x64.Word;\n\t    var X64WordArray = C_x64.WordArray;\n\t    var C_algo = C.algo;\n\n\t    function X64Word_create() {\n\t        return X64Word.create.apply(X64Word, arguments);\n\t    }\n\n\t    // Constants\n\t    var K = [\n\t        X64Word_create(0x428a2f98, 0xd728ae22), X64Word_create(0x71374491, 0x23ef65cd),\n\t        X64Word_create(0xb5c0fbcf, 0xec4d3b2f), X64Word_create(0xe9b5dba5, 0x8189dbbc),\n\t        X64Word_create(0x3956c25b, 0xf348b538), X64Word_create(0x59f111f1, 0xb605d019),\n\t        X64Word_create(0x923f82a4, 0xaf194f9b), X64Word_create(0xab1c5ed5, 0xda6d8118),\n\t        X64Word_create(0xd807aa98, 0xa3030242), X64Word_create(0x12835b01, 0x45706fbe),\n\t        X64Word_create(0x243185be, 0x4ee4b28c), X64Word_create(0x550c7dc3, 0xd5ffb4e2),\n\t        X64Word_create(0x72be5d74, 0xf27b896f), X64Word_create(0x80deb1fe, 0x3b1696b1),\n\t        X64Word_create(0x9bdc06a7, 0x25c71235), X64Word_create(0xc19bf174, 0xcf692694),\n\t        X64Word_create(0xe49b69c1, 0x9ef14ad2), X64Word_create(0xefbe4786, 0x384f25e3),\n\t        X64Word_create(0x0fc19dc6, 0x8b8cd5b5), X64Word_create(0x240ca1cc, 0x77ac9c65),\n\t        X64Word_create(0x2de92c6f, 0x592b0275), X64Word_create(0x4a7484aa, 0x6ea6e483),\n\t        X64Word_create(0x5cb0a9dc, 0xbd41fbd4), X64Word_create(0x76f988da, 0x831153b5),\n\t        X64Word_create(0x983e5152, 0xee66dfab), X64Word_create(0xa831c66d, 0x2db43210),\n\t        X64Word_create(0xb00327c8, 0x98fb213f), X64Word_create(0xbf597fc7, 0xbeef0ee4),\n\t        X64Word_create(0xc6e00bf3, 0x3da88fc2), X64Word_create(0xd5a79147, 0x930aa725),\n\t        X64Word_create(0x06ca6351, 0xe003826f), X64Word_create(0x14292967, 0x0a0e6e70),\n\t        X64Word_create(0x27b70a85, 0x46d22ffc), X64Word_create(0x2e1b2138, 0x5c26c926),\n\t        X64Word_create(0x4d2c6dfc, 0x5ac42aed), X64Word_create(0x53380d13, 0x9d95b3df),\n\t        X64Word_create(0x650a7354, 0x8baf63de), X64Word_create(0x766a0abb, 0x3c77b2a8),\n\t        X64Word_create(0x81c2c92e, 0x47edaee6), X64Word_create(0x92722c85, 0x1482353b),\n\t        X64Word_create(0xa2bfe8a1, 0x4cf10364), X64Word_create(0xa81a664b, 0xbc423001),\n\t        X64Word_create(0xc24b8b70, 0xd0f89791), X64Word_create(0xc76c51a3, 0x0654be30),\n\t        X64Word_create(0xd192e819, 0xd6ef5218), X64Word_create(0xd6990624, 0x5565a910),\n\t        X64Word_create(0xf40e3585, 0x5771202a), X64Word_create(0x106aa070, 0x32bbd1b8),\n\t        X64Word_create(0x19a4c116, 0xb8d2d0c8), X64Word_create(0x1e376c08, 0x5141ab53),\n\t        X64Word_create(0x2748774c, 0xdf8eeb99), X64Word_create(0x34b0bcb5, 0xe19b48a8),\n\t        X64Word_create(0x391c0cb3, 0xc5c95a63), X64Word_create(0x4ed8aa4a, 0xe3418acb),\n\t        X64Word_create(0x5b9cca4f, 0x7763e373), X64Word_create(0x682e6ff3, 0xd6b2b8a3),\n\t        X64Word_create(0x748f82ee, 0x5defb2fc), X64Word_create(0x78a5636f, 0x43172f60),\n\t        X64Word_create(0x84c87814, 0xa1f0ab72), X64Word_create(0x8cc70208, 0x1a6439ec),\n\t        X64Word_create(0x90befffa, 0x23631e28), X64Word_create(0xa4506ceb, 0xde82bde9),\n\t        X64Word_create(0xbef9a3f7, 0xb2c67915), X64Word_create(0xc67178f2, 0xe372532b),\n\t        X64Word_create(0xca273ece, 0xea26619c), X64Word_create(0xd186b8c7, 0x21c0c207),\n\t        X64Word_create(0xeada7dd6, 0xcde0eb1e), X64Word_create(0xf57d4f7f, 0xee6ed178),\n\t        X64Word_create(0x06f067aa, 0x72176fba), X64Word_create(0x0a637dc5, 0xa2c898a6),\n\t        X64Word_create(0x113f9804, 0xbef90dae), X64Word_create(0x1b710b35, 0x131c471b),\n\t        X64Word_create(0x28db77f5, 0x23047d84), X64Word_create(0x32caab7b, 0x40c72493),\n\t        X64Word_create(0x3c9ebe0a, 0x15c9bebc), X64Word_create(0x431d67c4, 0x9c100d4c),\n\t        X64Word_create(0x4cc5d4be, 0xcb3e42b6), X64Word_create(0x597f299c, 0xfc657e2a),\n\t        X64Word_create(0x5fcb6fab, 0x3ad6faec), X64Word_create(0x6c44198c, 0x4a475817)\n\t    ];\n\n\t    // Reusable objects\n\t    var W = [];\n\t    (function () {\n\t        for (var i = 0; i < 80; i++) {\n\t            W[i] = X64Word_create();\n\t        }\n\t    }());\n\n\t    /**\n\t     * SHA-512 hash algorithm.\n\t     */\n\t    var SHA512 = C_algo.SHA512 = Hasher.extend({\n\t        _doReset: function () {\n\t            this._hash = new X64WordArray.init([\n\t                new X64Word.init(0x6a09e667, 0xf3bcc908), new X64Word.init(0xbb67ae85, 0x84caa73b),\n\t                new X64Word.init(0x3c6ef372, 0xfe94f82b), new X64Word.init(0xa54ff53a, 0x5f1d36f1),\n\t                new X64Word.init(0x510e527f, 0xade682d1), new X64Word.init(0x9b05688c, 0x2b3e6c1f),\n\t                new X64Word.init(0x1f83d9ab, 0xfb41bd6b), new X64Word.init(0x5be0cd19, 0x137e2179)\n\t            ]);\n\t        },\n\n\t        _doProcessBlock: function (M, offset) {\n\t            // Shortcuts\n\t            var H = this._hash.words;\n\n\t            var H0 = H[0];\n\t            var H1 = H[1];\n\t            var H2 = H[2];\n\t            var H3 = H[3];\n\t            var H4 = H[4];\n\t            var H5 = H[5];\n\t            var H6 = H[6];\n\t            var H7 = H[7];\n\n\t            var H0h = H0.high;\n\t            var H0l = H0.low;\n\t            var H1h = H1.high;\n\t            var H1l = H1.low;\n\t            var H2h = H2.high;\n\t            var H2l = H2.low;\n\t            var H3h = H3.high;\n\t            var H3l = H3.low;\n\t            var H4h = H4.high;\n\t            var H4l = H4.low;\n\t            var H5h = H5.high;\n\t            var H5l = H5.low;\n\t            var H6h = H6.high;\n\t            var H6l = H6.low;\n\t            var H7h = H7.high;\n\t            var H7l = H7.low;\n\n\t            // Working variables\n\t            var ah = H0h;\n\t            var al = H0l;\n\t            var bh = H1h;\n\t            var bl = H1l;\n\t            var ch = H2h;\n\t            var cl = H2l;\n\t            var dh = H3h;\n\t            var dl = H3l;\n\t            var eh = H4h;\n\t            var el = H4l;\n\t            var fh = H5h;\n\t            var fl = H5l;\n\t            var gh = H6h;\n\t            var gl = H6l;\n\t            var hh = H7h;\n\t            var hl = H7l;\n\n\t            // Rounds\n\t            for (var i = 0; i < 80; i++) {\n\t                // Shortcut\n\t                var Wi = W[i];\n\n\t                // Extend message\n\t                if (i < 16) {\n\t                    var Wih = Wi.high = M[offset + i * 2]     | 0;\n\t                    var Wil = Wi.low  = M[offset + i * 2 + 1] | 0;\n\t                } else {\n\t                    // Gamma0\n\t                    var gamma0x  = W[i - 15];\n\t                    var gamma0xh = gamma0x.high;\n\t                    var gamma0xl = gamma0x.low;\n\t                    var gamma0h  = ((gamma0xh >>> 1) | (gamma0xl << 31)) ^ ((gamma0xh >>> 8) | (gamma0xl << 24)) ^ (gamma0xh >>> 7);\n\t                    var gamma0l  = ((gamma0xl >>> 1) | (gamma0xh << 31)) ^ ((gamma0xl >>> 8) | (gamma0xh << 24)) ^ ((gamma0xl >>> 7) | (gamma0xh << 25));\n\n\t                    // Gamma1\n\t                    var gamma1x  = W[i - 2];\n\t                    var gamma1xh = gamma1x.high;\n\t                    var gamma1xl = gamma1x.low;\n\t                    var gamma1h  = ((gamma1xh >>> 19) | (gamma1xl << 13)) ^ ((gamma1xh << 3) | (gamma1xl >>> 29)) ^ (gamma1xh >>> 6);\n\t                    var gamma1l  = ((gamma1xl >>> 19) | (gamma1xh << 13)) ^ ((gamma1xl << 3) | (gamma1xh >>> 29)) ^ ((gamma1xl >>> 6) | (gamma1xh << 26));\n\n\t                    // W[i] = gamma0 + W[i - 7] + gamma1 + W[i - 16]\n\t                    var Wi7  = W[i - 7];\n\t                    var Wi7h = Wi7.high;\n\t                    var Wi7l = Wi7.low;\n\n\t                    var Wi16  = W[i - 16];\n\t                    var Wi16h = Wi16.high;\n\t                    var Wi16l = Wi16.low;\n\n\t                    var Wil = gamma0l + Wi7l;\n\t                    var Wih = gamma0h + Wi7h + ((Wil >>> 0) < (gamma0l >>> 0) ? 1 : 0);\n\t                    var Wil = Wil + gamma1l;\n\t                    var Wih = Wih + gamma1h + ((Wil >>> 0) < (gamma1l >>> 0) ? 1 : 0);\n\t                    var Wil = Wil + Wi16l;\n\t                    var Wih = Wih + Wi16h + ((Wil >>> 0) < (Wi16l >>> 0) ? 1 : 0);\n\n\t                    Wi.high = Wih;\n\t                    Wi.low  = Wil;\n\t                }\n\n\t                var chh  = (eh & fh) ^ (~eh & gh);\n\t                var chl  = (el & fl) ^ (~el & gl);\n\t                var majh = (ah & bh) ^ (ah & ch) ^ (bh & ch);\n\t                var majl = (al & bl) ^ (al & cl) ^ (bl & cl);\n\n\t                var sigma0h = ((ah >>> 28) | (al << 4))  ^ ((ah << 30)  | (al >>> 2)) ^ ((ah << 25) | (al >>> 7));\n\t                var sigma0l = ((al >>> 28) | (ah << 4))  ^ ((al << 30)  | (ah >>> 2)) ^ ((al << 25) | (ah >>> 7));\n\t                var sigma1h = ((eh >>> 14) | (el << 18)) ^ ((eh >>> 18) | (el << 14)) ^ ((eh << 23) | (el >>> 9));\n\t                var sigma1l = ((el >>> 14) | (eh << 18)) ^ ((el >>> 18) | (eh << 14)) ^ ((el << 23) | (eh >>> 9));\n\n\t                // t1 = h + sigma1 + ch + K[i] + W[i]\n\t                var Ki  = K[i];\n\t                var Kih = Ki.high;\n\t                var Kil = Ki.low;\n\n\t                var t1l = hl + sigma1l;\n\t                var t1h = hh + sigma1h + ((t1l >>> 0) < (hl >>> 0) ? 1 : 0);\n\t                var t1l = t1l + chl;\n\t                var t1h = t1h + chh + ((t1l >>> 0) < (chl >>> 0) ? 1 : 0);\n\t                var t1l = t1l + Kil;\n\t                var t1h = t1h + Kih + ((t1l >>> 0) < (Kil >>> 0) ? 1 : 0);\n\t                var t1l = t1l + Wil;\n\t                var t1h = t1h + Wih + ((t1l >>> 0) < (Wil >>> 0) ? 1 : 0);\n\n\t                // t2 = sigma0 + maj\n\t                var t2l = sigma0l + majl;\n\t                var t2h = sigma0h + majh + ((t2l >>> 0) < (sigma0l >>> 0) ? 1 : 0);\n\n\t                // Update working variables\n\t                hh = gh;\n\t                hl = gl;\n\t                gh = fh;\n\t                gl = fl;\n\t                fh = eh;\n\t                fl = el;\n\t                el = (dl + t1l) | 0;\n\t                eh = (dh + t1h + ((el >>> 0) < (dl >>> 0) ? 1 : 0)) | 0;\n\t                dh = ch;\n\t                dl = cl;\n\t                ch = bh;\n\t                cl = bl;\n\t                bh = ah;\n\t                bl = al;\n\t                al = (t1l + t2l) | 0;\n\t                ah = (t1h + t2h + ((al >>> 0) < (t1l >>> 0) ? 1 : 0)) | 0;\n\t            }\n\n\t            // Intermediate hash value\n\t            H0l = H0.low  = (H0l + al);\n\t            H0.high = (H0h + ah + ((H0l >>> 0) < (al >>> 0) ? 1 : 0));\n\t            H1l = H1.low  = (H1l + bl);\n\t            H1.high = (H1h + bh + ((H1l >>> 0) < (bl >>> 0) ? 1 : 0));\n\t            H2l = H2.low  = (H2l + cl);\n\t            H2.high = (H2h + ch + ((H2l >>> 0) < (cl >>> 0) ? 1 : 0));\n\t            H3l = H3.low  = (H3l + dl);\n\t            H3.high = (H3h + dh + ((H3l >>> 0) < (dl >>> 0) ? 1 : 0));\n\t            H4l = H4.low  = (H4l + el);\n\t            H4.high = (H4h + eh + ((H4l >>> 0) < (el >>> 0) ? 1 : 0));\n\t            H5l = H5.low  = (H5l + fl);\n\t            H5.high = (H5h + fh + ((H5l >>> 0) < (fl >>> 0) ? 1 : 0));\n\t            H6l = H6.low  = (H6l + gl);\n\t            H6.high = (H6h + gh + ((H6l >>> 0) < (gl >>> 0) ? 1 : 0));\n\t            H7l = H7.low  = (H7l + hl);\n\t            H7.high = (H7h + hh + ((H7l >>> 0) < (hl >>> 0) ? 1 : 0));\n\t        },\n\n\t        _doFinalize: function () {\n\t            // Shortcuts\n\t            var data = this._data;\n\t            var dataWords = data.words;\n\n\t            var nBitsTotal = this._nDataBytes * 8;\n\t            var nBitsLeft = data.sigBytes * 8;\n\n\t            // Add padding\n\t            dataWords[nBitsLeft >>> 5] |= 0x80 << (24 - nBitsLeft % 32);\n\t            dataWords[(((nBitsLeft + 128) >>> 10) << 5) + 30] = Math.floor(nBitsTotal / 0x100000000);\n\t            dataWords[(((nBitsLeft + 128) >>> 10) << 5) + 31] = nBitsTotal;\n\t            data.sigBytes = dataWords.length * 4;\n\n\t            // Hash final blocks\n\t            this._process();\n\n\t            // Convert hash to 32-bit word array before returning\n\t            var hash = this._hash.toX32();\n\n\t            // Return final computed hash\n\t            return hash;\n\t        },\n\n\t        clone: function () {\n\t            var clone = Hasher.clone.call(this);\n\t            clone._hash = this._hash.clone();\n\n\t            return clone;\n\t        },\n\n\t        blockSize: 1024/32\n\t    });\n\n\t    /**\n\t     * Shortcut function to the hasher's object interface.\n\t     *\n\t     * @param {WordArray|string} message The message to hash.\n\t     *\n\t     * @return {WordArray} The hash.\n\t     *\n\t     * @static\n\t     *\n\t     * @example\n\t     *\n\t     *     var hash = CryptoJS.SHA512('message');\n\t     *     var hash = CryptoJS.SHA512(wordArray);\n\t     */\n\t    C.SHA512 = Hasher._createHelper(SHA512);\n\n\t    /**\n\t     * Shortcut function to the HMAC's object interface.\n\t     *\n\t     * @param {WordArray|string} message The message to hash.\n\t     * @param {WordArray|string} key The secret key.\n\t     *\n\t     * @return {WordArray} The HMAC.\n\t     *\n\t     * @static\n\t     *\n\t     * @example\n\t     *\n\t     *     var hmac = CryptoJS.HmacSHA512(message, key);\n\t     */\n\t    C.HmacSHA512 = Hasher._createHmacHelper(SHA512);\n\t}());\n\n\n\treturn CryptoJS.SHA512;\n\n}));\n\n/***/ }),\n/* 12 */\n/***/ (function(module, exports, __webpack_require__) {\n\n\"use strict\";\n\n\nObject.defineProperty(exports, \"__esModule\", {\n    value: true\n});\n\nvar _cryptoJs = __webpack_require__(9);\n\nvar _cryptoJs2 = _interopRequireDefault(_cryptoJs);\n\nvar _jsBase = __webpack_require__(36);\n\nvar _bowser = __webpack_require__(41);\n\nvar _bowser2 = _interopRequireDefault(_bowser);\n\nvar _encU8array = __webpack_require__(43);\n\nvar _encU8array2 = _interopRequireDefault(_encU8array);\n\nvar _es6Promise = __webpack_require__(44);\n\nfunction _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }\n\nvar isIE = _bowser2.default.msie || _bowser2.default.msedge;\nvar API_URL = '/api/file/get';\nvar apiURL = '';\nvar ctx = self;\nvar _self = self;\nvar isSupportCoder = _self.TextEncoder && _self.TextDecoder;\nvar dec = !isIE && isSupportCoder ? new TextDecoder() : {};\nvar enc = !isIE && isSupportCoder ? new TextEncoder() : {};\nctx.onmessage = function (evt) {\n    var dataString = void 0;\n    if (isIE) {\n        dataString = evt.data;\n    } else {\n        dataString = dec.decode(new Uint8Array(evt.data));\n    }\n\n    var _JSON$parse = JSON.parse(dataString),\n        key = _JSON$parse.key,\n        uuid = _JSON$parse.uuid,\n        url = _JSON$parse.url,\n        decryptKey = _JSON$parse.decryptKey,\n        pluginId = _JSON$parse.pluginId,\n        apiPrefix = _JSON$parse.apiPrefix;\n\n    apiURL = apiPrefix + API_URL;\n    if (!url || !decryptKey) {\n        requestKey(key).then(function (res) {\n            var data = void 0;\n            try {\n                data = JSON.parse(res.data);\n            } catch (e) {\n                return throwError(e, key, uuid, pluginId);\n            }\n            if (data.code !== 0) {\n                return throwError(data.msg, key, uuid, pluginId);\n            }\n            var _data$data = data.data,\n                decryptKey = _data$data.decrypt_key,\n                cu = _data$data.cdn_url,\n                tcu = _data$data.thumbnail_cdn_url,\n                wcu = _data$data.webp_cdn_url,\n                wtcu = _data$data.webp_thumbnail_cdn_url;\n\n            var url = _bowser2.default.mobile && (wtcu || wcu) || tcu || cu;\n            try {\n                var decoded = base64ToArrayBuffer(decryptKey);\n                actionRequestCDN(url, decoded, uuid, key, pluginId);\n            } catch (e) {\n                return throwError(e, key, uuid, pluginId);\n            }\n        }).catch(function (e) {\n            return throwError(e, key, uuid, pluginId);\n        });\n    } else {\n        try {\n            var decoded = base64ToArrayBuffer(decryptKey);\n            actionRequestCDN(url, decoded, uuid, key, pluginId);\n        } catch (e) {\n            return throwError(e, key, uuid, pluginId);\n        }\n    }\n};\nfunction process(buffer, key) {\n    var keyBv = new Uint8Array(key);\n    var keyWA = _encU8array2.default.parse(keyBv);\n    var iv = buffer.slice(0, 16);\n    var ivBv = new Uint8Array(iv);\n    var ivWA = _encU8array2.default.parse(ivBv);\n    buffer = buffer.slice(16);\n    var bufferBv = new Uint8Array(buffer);\n    var contentWA = _encU8array2.default.parse(bufferBv);\n    var dcBase64String = contentWA.toString(_cryptoJs2.default.enc.Base64);\n    var decrypted = _cryptoJs2.default.AES.decrypt(dcBase64String, keyWA, {\n        iv: ivWA,\n        mode: _cryptoJs2.default.mode.CBC,\n        padding: _cryptoJs2.default.pad.NoPadding\n    });\n    var d64 = decrypted.toString(_cryptoJs2.default.enc.Base64);\n    return d64;\n}\nfunction requestKey(key) {\n    return request(apiURL, { params: { key: key } });\n}\nfunction requestCDN(url) {\n    return request(url, { responseType: 'arraybuffer', params: { t: new Date().getTime() } });\n}\nfunction actionRequestCDN(url, decoded, uuid, key, pluginId) {\n    requestCDN(url).then(function (responce) {\n        var d64 = process(responce.data, decoded);\n        var msg = {\n            uuid: uuid,\n            key: key,\n            imgBase64: 'data:image/png;base64,' + d64,\n            pluginId: pluginId\n        };\n        if (isIE) {\n            return ctx.postMessage(JSON.stringify(msg));\n        }\n        var buf = enc.encode(JSON.stringify(msg));\n        ctx.postMessage(buf.buffer, [buf.buffer]);\n    }).catch(function (e) {\n        return throwError(e, key, uuid, pluginId);\n    });\n}\nfunction base64ToArrayBuffer(base64) {\n    var binaryString = _jsBase.Base64.atob(base64);\n    var len = binaryString.length;\n    var bytes = new Uint8Array(len);\n    for (var i = 0; i < len; i++) {\n        bytes[i] = binaryString.charCodeAt(i);\n    }\n    return bytes;\n}\nfunction request(url, options) {\n    return new _es6Promise.Promise(function (resolve, reject) {\n        var responseType = options.responseType,\n            params = options.params;\n\n        var query = createQueryString(params);\n        var xhr = new XMLHttpRequest();\n        xhr.open('get', url + '?' + query);\n        if (responseType) {\n            xhr.responseType = responseType;\n        }\n        // 5s 超时\n        xhr.timeout = 5000;\n        xhr.onreadystatechange = function () {\n            if (xhr.readyState === 4) {\n                if (xhr.status === 200) {\n                    resolve({ data: xhr.response });\n                } else {\n                    reject({ data: xhr.response });\n                }\n            }\n        };\n        xhr.onerror = function () {\n            reject({ data: xhr.response });\n        };\n        xhr.send(null);\n    });\n}\nfunction createQueryString(obj) {\n    var res = '';\n    for (var key in obj) {\n        res += key + '=' + obj[key] + '&';\n    }\n    return res.slice(0, res.length - 1);\n}\nfunction throwError(msg, key, uuid, pluginId) {\n    var data = { err: true, msg: msg, key: key, uuid: uuid, pluginId: pluginId };\n    if (isIE) {\n        return ctx.postMessage(JSON.stringify(data));\n    }\n    var buf = enc.encode(JSON.stringify(data));\n    return ctx.postMessage(buf.buffer, [buf.buffer]);\n}\nexports.default = {};\n\n/***/ }),\n/* 13 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t(function () {\n\t    // Check if typed arrays are supported\n\t    if (typeof ArrayBuffer != 'function') {\n\t        return;\n\t    }\n\n\t    // Shortcuts\n\t    var C = CryptoJS;\n\t    var C_lib = C.lib;\n\t    var WordArray = C_lib.WordArray;\n\n\t    // Reference original init\n\t    var superInit = WordArray.init;\n\n\t    // Augment WordArray.init to handle typed arrays\n\t    var subInit = WordArray.init = function (typedArray) {\n\t        // Convert buffers to uint8\n\t        if (typedArray instanceof ArrayBuffer) {\n\t            typedArray = new Uint8Array(typedArray);\n\t        }\n\n\t        // Convert other array views to uint8\n\t        if (\n\t            typedArray instanceof Int8Array ||\n\t            (typeof Uint8ClampedArray !== \"undefined\" && typedArray instanceof Uint8ClampedArray) ||\n\t            typedArray instanceof Int16Array ||\n\t            typedArray instanceof Uint16Array ||\n\t            typedArray instanceof Int32Array ||\n\t            typedArray instanceof Uint32Array ||\n\t            typedArray instanceof Float32Array ||\n\t            typedArray instanceof Float64Array\n\t        ) {\n\t            typedArray = new Uint8Array(typedArray.buffer, typedArray.byteOffset, typedArray.byteLength);\n\t        }\n\n\t        // Handle Uint8Array\n\t        if (typedArray instanceof Uint8Array) {\n\t            // Shortcut\n\t            var typedArrayByteLength = typedArray.byteLength;\n\n\t            // Extract bytes\n\t            var words = [];\n\t            for (var i = 0; i < typedArrayByteLength; i++) {\n\t                words[i >>> 2] |= typedArray[i] << (24 - (i % 4) * 8);\n\t            }\n\n\t            // Initialize this word array\n\t            superInit.call(this, words, typedArrayByteLength);\n\t        } else {\n\t            // Else call normal init\n\t            superInit.apply(this, arguments);\n\t        }\n\t    };\n\n\t    subInit.prototype = WordArray;\n\t}());\n\n\n\treturn CryptoJS.lib.WordArray;\n\n}));\n\n/***/ }),\n/* 14 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t(function () {\n\t    // Shortcuts\n\t    var C = CryptoJS;\n\t    var C_lib = C.lib;\n\t    var WordArray = C_lib.WordArray;\n\t    var C_enc = C.enc;\n\n\t    /**\n\t     * UTF-16 BE encoding strategy.\n\t     */\n\t    var Utf16BE = C_enc.Utf16 = C_enc.Utf16BE = {\n\t        /**\n\t         * Converts a word array to a UTF-16 BE string.\n\t         *\n\t         * @param {WordArray} wordArray The word array.\n\t         *\n\t         * @return {string} The UTF-16 BE string.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var utf16String = CryptoJS.enc.Utf16.stringify(wordArray);\n\t         */\n\t        stringify: function (wordArray) {\n\t            // Shortcuts\n\t            var words = wordArray.words;\n\t            var sigBytes = wordArray.sigBytes;\n\n\t            // Convert\n\t            var utf16Chars = [];\n\t            for (var i = 0; i < sigBytes; i += 2) {\n\t                var codePoint = (words[i >>> 2] >>> (16 - (i % 4) * 8)) & 0xffff;\n\t                utf16Chars.push(String.fromCharCode(codePoint));\n\t            }\n\n\t            return utf16Chars.join('');\n\t        },\n\n\t        /**\n\t         * Converts a UTF-16 BE string to a word array.\n\t         *\n\t         * @param {string} utf16Str The UTF-16 BE string.\n\t         *\n\t         * @return {WordArray} The word array.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var wordArray = CryptoJS.enc.Utf16.parse(utf16String);\n\t         */\n\t        parse: function (utf16Str) {\n\t            // Shortcut\n\t            var utf16StrLength = utf16Str.length;\n\n\t            // Convert\n\t            var words = [];\n\t            for (var i = 0; i < utf16StrLength; i++) {\n\t                words[i >>> 1] |= utf16Str.charCodeAt(i) << (16 - (i % 2) * 16);\n\t            }\n\n\t            return WordArray.create(words, utf16StrLength * 2);\n\t        }\n\t    };\n\n\t    /**\n\t     * UTF-16 LE encoding strategy.\n\t     */\n\t    C_enc.Utf16LE = {\n\t        /**\n\t         * Converts a word array to a UTF-16 LE string.\n\t         *\n\t         * @param {WordArray} wordArray The word array.\n\t         *\n\t         * @return {string} The UTF-16 LE string.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var utf16Str = CryptoJS.enc.Utf16LE.stringify(wordArray);\n\t         */\n\t        stringify: function (wordArray) {\n\t            // Shortcuts\n\t            var words = wordArray.words;\n\t            var sigBytes = wordArray.sigBytes;\n\n\t            // Convert\n\t            var utf16Chars = [];\n\t            for (var i = 0; i < sigBytes; i += 2) {\n\t                var codePoint = swapEndian((words[i >>> 2] >>> (16 - (i % 4) * 8)) & 0xffff);\n\t                utf16Chars.push(String.fromCharCode(codePoint));\n\t            }\n\n\t            return utf16Chars.join('');\n\t        },\n\n\t        /**\n\t         * Converts a UTF-16 LE string to a word array.\n\t         *\n\t         * @param {string} utf16Str The UTF-16 LE string.\n\t         *\n\t         * @return {WordArray} The word array.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var wordArray = CryptoJS.enc.Utf16LE.parse(utf16Str);\n\t         */\n\t        parse: function (utf16Str) {\n\t            // Shortcut\n\t            var utf16StrLength = utf16Str.length;\n\n\t            // Convert\n\t            var words = [];\n\t            for (var i = 0; i < utf16StrLength; i++) {\n\t                words[i >>> 1] |= swapEndian(utf16Str.charCodeAt(i) << (16 - (i % 2) * 16));\n\t            }\n\n\t            return WordArray.create(words, utf16StrLength * 2);\n\t        }\n\t    };\n\n\t    function swapEndian(word) {\n\t        return ((word << 8) & 0xff00ff00) | ((word >>> 8) & 0x00ff00ff);\n\t    }\n\t}());\n\n\n\treturn CryptoJS.enc.Utf16;\n\n}));\n\n/***/ }),\n/* 15 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory, undef) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0), __webpack_require__(10));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t(function () {\n\t    // Shortcuts\n\t    var C = CryptoJS;\n\t    var C_lib = C.lib;\n\t    var WordArray = C_lib.WordArray;\n\t    var C_algo = C.algo;\n\t    var SHA256 = C_algo.SHA256;\n\n\t    /**\n\t     * SHA-224 hash algorithm.\n\t     */\n\t    var SHA224 = C_algo.SHA224 = SHA256.extend({\n\t        _doReset: function () {\n\t            this._hash = new WordArray.init([\n\t                0xc1059ed8, 0x367cd507, 0x3070dd17, 0xf70e5939,\n\t                0xffc00b31, 0x68581511, 0x64f98fa7, 0xbefa4fa4\n\t            ]);\n\t        },\n\n\t        _doFinalize: function () {\n\t            var hash = SHA256._doFinalize.call(this);\n\n\t            hash.sigBytes -= 4;\n\n\t            return hash;\n\t        }\n\t    });\n\n\t    /**\n\t     * Shortcut function to the hasher's object interface.\n\t     *\n\t     * @param {WordArray|string} message The message to hash.\n\t     *\n\t     * @return {WordArray} The hash.\n\t     *\n\t     * @static\n\t     *\n\t     * @example\n\t     *\n\t     *     var hash = CryptoJS.SHA224('message');\n\t     *     var hash = CryptoJS.SHA224(wordArray);\n\t     */\n\t    C.SHA224 = SHA256._createHelper(SHA224);\n\n\t    /**\n\t     * Shortcut function to the HMAC's object interface.\n\t     *\n\t     * @param {WordArray|string} message The message to hash.\n\t     * @param {WordArray|string} key The secret key.\n\t     *\n\t     * @return {WordArray} The HMAC.\n\t     *\n\t     * @static\n\t     *\n\t     * @example\n\t     *\n\t     *     var hmac = CryptoJS.HmacSHA224(message, key);\n\t     */\n\t    C.HmacSHA224 = SHA256._createHmacHelper(SHA224);\n\t}());\n\n\n\treturn CryptoJS.SHA224;\n\n}));\n\n/***/ }),\n/* 16 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory, undef) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0), __webpack_require__(5), __webpack_require__(11));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t(function () {\n\t    // Shortcuts\n\t    var C = CryptoJS;\n\t    var C_x64 = C.x64;\n\t    var X64Word = C_x64.Word;\n\t    var X64WordArray = C_x64.WordArray;\n\t    var C_algo = C.algo;\n\t    var SHA512 = C_algo.SHA512;\n\n\t    /**\n\t     * SHA-384 hash algorithm.\n\t     */\n\t    var SHA384 = C_algo.SHA384 = SHA512.extend({\n\t        _doReset: function () {\n\t            this._hash = new X64WordArray.init([\n\t                new X64Word.init(0xcbbb9d5d, 0xc1059ed8), new X64Word.init(0x629a292a, 0x367cd507),\n\t                new X64Word.init(0x9159015a, 0x3070dd17), new X64Word.init(0x152fecd8, 0xf70e5939),\n\t                new X64Word.init(0x67332667, 0xffc00b31), new X64Word.init(0x8eb44a87, 0x68581511),\n\t                new X64Word.init(0xdb0c2e0d, 0x64f98fa7), new X64Word.init(0x47b5481d, 0xbefa4fa4)\n\t            ]);\n\t        },\n\n\t        _doFinalize: function () {\n\t            var hash = SHA512._doFinalize.call(this);\n\n\t            hash.sigBytes -= 16;\n\n\t            return hash;\n\t        }\n\t    });\n\n\t    /**\n\t     * Shortcut function to the hasher's object interface.\n\t     *\n\t     * @param {WordArray|string} message The message to hash.\n\t     *\n\t     * @return {WordArray} The hash.\n\t     *\n\t     * @static\n\t     *\n\t     * @example\n\t     *\n\t     *     var hash = CryptoJS.SHA384('message');\n\t     *     var hash = CryptoJS.SHA384(wordArray);\n\t     */\n\t    C.SHA384 = SHA512._createHelper(SHA384);\n\n\t    /**\n\t     * Shortcut function to the HMAC's object interface.\n\t     *\n\t     * @param {WordArray|string} message The message to hash.\n\t     * @param {WordArray|string} key The secret key.\n\t     *\n\t     * @return {WordArray} The HMAC.\n\t     *\n\t     * @static\n\t     *\n\t     * @example\n\t     *\n\t     *     var hmac = CryptoJS.HmacSHA384(message, key);\n\t     */\n\t    C.HmacSHA384 = SHA512._createHmacHelper(SHA384);\n\t}());\n\n\n\treturn CryptoJS.SHA384;\n\n}));\n\n/***/ }),\n/* 17 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory, undef) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0), __webpack_require__(5));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t(function (Math) {\n\t    // Shortcuts\n\t    var C = CryptoJS;\n\t    var C_lib = C.lib;\n\t    var WordArray = C_lib.WordArray;\n\t    var Hasher = C_lib.Hasher;\n\t    var C_x64 = C.x64;\n\t    var X64Word = C_x64.Word;\n\t    var C_algo = C.algo;\n\n\t    // Constants tables\n\t    var RHO_OFFSETS = [];\n\t    var PI_INDEXES  = [];\n\t    var ROUND_CONSTANTS = [];\n\n\t    // Compute Constants\n\t    (function () {\n\t        // Compute rho offset constants\n\t        var x = 1, y = 0;\n\t        for (var t = 0; t < 24; t++) {\n\t            RHO_OFFSETS[x + 5 * y] = ((t + 1) * (t + 2) / 2) % 64;\n\n\t            var newX = y % 5;\n\t            var newY = (2 * x + 3 * y) % 5;\n\t            x = newX;\n\t            y = newY;\n\t        }\n\n\t        // Compute pi index constants\n\t        for (var x = 0; x < 5; x++) {\n\t            for (var y = 0; y < 5; y++) {\n\t                PI_INDEXES[x + 5 * y] = y + ((2 * x + 3 * y) % 5) * 5;\n\t            }\n\t        }\n\n\t        // Compute round constants\n\t        var LFSR = 0x01;\n\t        for (var i = 0; i < 24; i++) {\n\t            var roundConstantMsw = 0;\n\t            var roundConstantLsw = 0;\n\n\t            for (var j = 0; j < 7; j++) {\n\t                if (LFSR & 0x01) {\n\t                    var bitPosition = (1 << j) - 1;\n\t                    if (bitPosition < 32) {\n\t                        roundConstantLsw ^= 1 << bitPosition;\n\t                    } else /* if (bitPosition >= 32) */ {\n\t                        roundConstantMsw ^= 1 << (bitPosition - 32);\n\t                    }\n\t                }\n\n\t                // Compute next LFSR\n\t                if (LFSR & 0x80) {\n\t                    // Primitive polynomial over GF(2): x^8 + x^6 + x^5 + x^4 + 1\n\t                    LFSR = (LFSR << 1) ^ 0x71;\n\t                } else {\n\t                    LFSR <<= 1;\n\t                }\n\t            }\n\n\t            ROUND_CONSTANTS[i] = X64Word.create(roundConstantMsw, roundConstantLsw);\n\t        }\n\t    }());\n\n\t    // Reusable objects for temporary values\n\t    var T = [];\n\t    (function () {\n\t        for (var i = 0; i < 25; i++) {\n\t            T[i] = X64Word.create();\n\t        }\n\t    }());\n\n\t    /**\n\t     * SHA-3 hash algorithm.\n\t     */\n\t    var SHA3 = C_algo.SHA3 = Hasher.extend({\n\t        /**\n\t         * Configuration options.\n\t         *\n\t         * @property {number} outputLength\n\t         *   The desired number of bits in the output hash.\n\t         *   Only values permitted are: 224, 256, 384, 512.\n\t         *   Default: 512\n\t         */\n\t        cfg: Hasher.cfg.extend({\n\t            outputLength: 512\n\t        }),\n\n\t        _doReset: function () {\n\t            var state = this._state = []\n\t            for (var i = 0; i < 25; i++) {\n\t                state[i] = new X64Word.init();\n\t            }\n\n\t            this.blockSize = (1600 - 2 * this.cfg.outputLength) / 32;\n\t        },\n\n\t        _doProcessBlock: function (M, offset) {\n\t            // Shortcuts\n\t            var state = this._state;\n\t            var nBlockSizeLanes = this.blockSize / 2;\n\n\t            // Absorb\n\t            for (var i = 0; i < nBlockSizeLanes; i++) {\n\t                // Shortcuts\n\t                var M2i  = M[offset + 2 * i];\n\t                var M2i1 = M[offset + 2 * i + 1];\n\n\t                // Swap endian\n\t                M2i = (\n\t                    (((M2i << 8)  | (M2i >>> 24)) & 0x00ff00ff) |\n\t                    (((M2i << 24) | (M2i >>> 8))  & 0xff00ff00)\n\t                );\n\t                M2i1 = (\n\t                    (((M2i1 << 8)  | (M2i1 >>> 24)) & 0x00ff00ff) |\n\t                    (((M2i1 << 24) | (M2i1 >>> 8))  & 0xff00ff00)\n\t                );\n\n\t                // Absorb message into state\n\t                var lane = state[i];\n\t                lane.high ^= M2i1;\n\t                lane.low  ^= M2i;\n\t            }\n\n\t            // Rounds\n\t            for (var round = 0; round < 24; round++) {\n\t                // Theta\n\t                for (var x = 0; x < 5; x++) {\n\t                    // Mix column lanes\n\t                    var tMsw = 0, tLsw = 0;\n\t                    for (var y = 0; y < 5; y++) {\n\t                        var lane = state[x + 5 * y];\n\t                        tMsw ^= lane.high;\n\t                        tLsw ^= lane.low;\n\t                    }\n\n\t                    // Temporary values\n\t                    var Tx = T[x];\n\t                    Tx.high = tMsw;\n\t                    Tx.low  = tLsw;\n\t                }\n\t                for (var x = 0; x < 5; x++) {\n\t                    // Shortcuts\n\t                    var Tx4 = T[(x + 4) % 5];\n\t                    var Tx1 = T[(x + 1) % 5];\n\t                    var Tx1Msw = Tx1.high;\n\t                    var Tx1Lsw = Tx1.low;\n\n\t                    // Mix surrounding columns\n\t                    var tMsw = Tx4.high ^ ((Tx1Msw << 1) | (Tx1Lsw >>> 31));\n\t                    var tLsw = Tx4.low  ^ ((Tx1Lsw << 1) | (Tx1Msw >>> 31));\n\t                    for (var y = 0; y < 5; y++) {\n\t                        var lane = state[x + 5 * y];\n\t                        lane.high ^= tMsw;\n\t                        lane.low  ^= tLsw;\n\t                    }\n\t                }\n\n\t                // Rho Pi\n\t                for (var laneIndex = 1; laneIndex < 25; laneIndex++) {\n\t                    // Shortcuts\n\t                    var lane = state[laneIndex];\n\t                    var laneMsw = lane.high;\n\t                    var laneLsw = lane.low;\n\t                    var rhoOffset = RHO_OFFSETS[laneIndex];\n\n\t                    // Rotate lanes\n\t                    if (rhoOffset < 32) {\n\t                        var tMsw = (laneMsw << rhoOffset) | (laneLsw >>> (32 - rhoOffset));\n\t                        var tLsw = (laneLsw << rhoOffset) | (laneMsw >>> (32 - rhoOffset));\n\t                    } else /* if (rhoOffset >= 32) */ {\n\t                        var tMsw = (laneLsw << (rhoOffset - 32)) | (laneMsw >>> (64 - rhoOffset));\n\t                        var tLsw = (laneMsw << (rhoOffset - 32)) | (laneLsw >>> (64 - rhoOffset));\n\t                    }\n\n\t                    // Transpose lanes\n\t                    var TPiLane = T[PI_INDEXES[laneIndex]];\n\t                    TPiLane.high = tMsw;\n\t                    TPiLane.low  = tLsw;\n\t                }\n\n\t                // Rho pi at x = y = 0\n\t                var T0 = T[0];\n\t                var state0 = state[0];\n\t                T0.high = state0.high;\n\t                T0.low  = state0.low;\n\n\t                // Chi\n\t                for (var x = 0; x < 5; x++) {\n\t                    for (var y = 0; y < 5; y++) {\n\t                        // Shortcuts\n\t                        var laneIndex = x + 5 * y;\n\t                        var lane = state[laneIndex];\n\t                        var TLane = T[laneIndex];\n\t                        var Tx1Lane = T[((x + 1) % 5) + 5 * y];\n\t                        var Tx2Lane = T[((x + 2) % 5) + 5 * y];\n\n\t                        // Mix rows\n\t                        lane.high = TLane.high ^ (~Tx1Lane.high & Tx2Lane.high);\n\t                        lane.low  = TLane.low  ^ (~Tx1Lane.low  & Tx2Lane.low);\n\t                    }\n\t                }\n\n\t                // Iota\n\t                var lane = state[0];\n\t                var roundConstant = ROUND_CONSTANTS[round];\n\t                lane.high ^= roundConstant.high;\n\t                lane.low  ^= roundConstant.low;;\n\t            }\n\t        },\n\n\t        _doFinalize: function () {\n\t            // Shortcuts\n\t            var data = this._data;\n\t            var dataWords = data.words;\n\t            var nBitsTotal = this._nDataBytes * 8;\n\t            var nBitsLeft = data.sigBytes * 8;\n\t            var blockSizeBits = this.blockSize * 32;\n\n\t            // Add padding\n\t            dataWords[nBitsLeft >>> 5] |= 0x1 << (24 - nBitsLeft % 32);\n\t            dataWords[((Math.ceil((nBitsLeft + 1) / blockSizeBits) * blockSizeBits) >>> 5) - 1] |= 0x80;\n\t            data.sigBytes = dataWords.length * 4;\n\n\t            // Hash final blocks\n\t            this._process();\n\n\t            // Shortcuts\n\t            var state = this._state;\n\t            var outputLengthBytes = this.cfg.outputLength / 8;\n\t            var outputLengthLanes = outputLengthBytes / 8;\n\n\t            // Squeeze\n\t            var hashWords = [];\n\t            for (var i = 0; i < outputLengthLanes; i++) {\n\t                // Shortcuts\n\t                var lane = state[i];\n\t                var laneMsw = lane.high;\n\t                var laneLsw = lane.low;\n\n\t                // Swap endian\n\t                laneMsw = (\n\t                    (((laneMsw << 8)  | (laneMsw >>> 24)) & 0x00ff00ff) |\n\t                    (((laneMsw << 24) | (laneMsw >>> 8))  & 0xff00ff00)\n\t                );\n\t                laneLsw = (\n\t                    (((laneLsw << 8)  | (laneLsw >>> 24)) & 0x00ff00ff) |\n\t                    (((laneLsw << 24) | (laneLsw >>> 8))  & 0xff00ff00)\n\t                );\n\n\t                // Squeeze state to retrieve hash\n\t                hashWords.push(laneLsw);\n\t                hashWords.push(laneMsw);\n\t            }\n\n\t            // Return final computed hash\n\t            return new WordArray.init(hashWords, outputLengthBytes);\n\t        },\n\n\t        clone: function () {\n\t            var clone = Hasher.clone.call(this);\n\n\t            var state = clone._state = this._state.slice(0);\n\t            for (var i = 0; i < 25; i++) {\n\t                state[i] = state[i].clone();\n\t            }\n\n\t            return clone;\n\t        }\n\t    });\n\n\t    /**\n\t     * Shortcut function to the hasher's object interface.\n\t     *\n\t     * @param {WordArray|string} message The message to hash.\n\t     *\n\t     * @return {WordArray} The hash.\n\t     *\n\t     * @static\n\t     *\n\t     * @example\n\t     *\n\t     *     var hash = CryptoJS.SHA3('message');\n\t     *     var hash = CryptoJS.SHA3(wordArray);\n\t     */\n\t    C.SHA3 = Hasher._createHelper(SHA3);\n\n\t    /**\n\t     * Shortcut function to the HMAC's object interface.\n\t     *\n\t     * @param {WordArray|string} message The message to hash.\n\t     * @param {WordArray|string} key The secret key.\n\t     *\n\t     * @return {WordArray} The HMAC.\n\t     *\n\t     * @static\n\t     *\n\t     * @example\n\t     *\n\t     *     var hmac = CryptoJS.HmacSHA3(message, key);\n\t     */\n\t    C.HmacSHA3 = Hasher._createHmacHelper(SHA3);\n\t}(Math));\n\n\n\treturn CryptoJS.SHA3;\n\n}));\n\n/***/ }),\n/* 18 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t/** @preserve\n\t(c) 2012 by Cédric Mesnil. All rights reserved.\n\n\tRedistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:\n\n\t    - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.\n\t    - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.\n\n\tTHIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.\n\t*/\n\n\t(function (Math) {\n\t    // Shortcuts\n\t    var C = CryptoJS;\n\t    var C_lib = C.lib;\n\t    var WordArray = C_lib.WordArray;\n\t    var Hasher = C_lib.Hasher;\n\t    var C_algo = C.algo;\n\n\t    // Constants table\n\t    var _zl = WordArray.create([\n\t        0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15,\n\t        7,  4, 13,  1, 10,  6, 15,  3, 12,  0,  9,  5,  2, 14, 11,  8,\n\t        3, 10, 14,  4,  9, 15,  8,  1,  2,  7,  0,  6, 13, 11,  5, 12,\n\t        1,  9, 11, 10,  0,  8, 12,  4, 13,  3,  7, 15, 14,  5,  6,  2,\n\t        4,  0,  5,  9,  7, 12,  2, 10, 14,  1,  3,  8, 11,  6, 15, 13]);\n\t    var _zr = WordArray.create([\n\t        5, 14,  7,  0,  9,  2, 11,  4, 13,  6, 15,  8,  1, 10,  3, 12,\n\t        6, 11,  3,  7,  0, 13,  5, 10, 14, 15,  8, 12,  4,  9,  1,  2,\n\t        15,  5,  1,  3,  7, 14,  6,  9, 11,  8, 12,  2, 10,  0,  4, 13,\n\t        8,  6,  4,  1,  3, 11, 15,  0,  5, 12,  2, 13,  9,  7, 10, 14,\n\t        12, 15, 10,  4,  1,  5,  8,  7,  6,  2, 13, 14,  0,  3,  9, 11]);\n\t    var _sl = WordArray.create([\n\t         11, 14, 15, 12,  5,  8,  7,  9, 11, 13, 14, 15,  6,  7,  9,  8,\n\t        7, 6,   8, 13, 11,  9,  7, 15,  7, 12, 15,  9, 11,  7, 13, 12,\n\t        11, 13,  6,  7, 14,  9, 13, 15, 14,  8, 13,  6,  5, 12,  7,  5,\n\t          11, 12, 14, 15, 14, 15,  9,  8,  9, 14,  5,  6,  8,  6,  5, 12,\n\t        9, 15,  5, 11,  6,  8, 13, 12,  5, 12, 13, 14, 11,  8,  5,  6 ]);\n\t    var _sr = WordArray.create([\n\t        8,  9,  9, 11, 13, 15, 15,  5,  7,  7,  8, 11, 14, 14, 12,  6,\n\t        9, 13, 15,  7, 12,  8,  9, 11,  7,  7, 12,  7,  6, 15, 13, 11,\n\t        9,  7, 15, 11,  8,  6,  6, 14, 12, 13,  5, 14, 13, 13,  7,  5,\n\t        15,  5,  8, 11, 14, 14,  6, 14,  6,  9, 12,  9, 12,  5, 15,  8,\n\t        8,  5, 12,  9, 12,  5, 14,  6,  8, 13,  6,  5, 15, 13, 11, 11 ]);\n\n\t    var _hl =  WordArray.create([ 0x00000000, 0x5A827999, 0x6ED9EBA1, 0x8F1BBCDC, 0xA953FD4E]);\n\t    var _hr =  WordArray.create([ 0x50A28BE6, 0x5C4DD124, 0x6D703EF3, 0x7A6D76E9, 0x00000000]);\n\n\t    /**\n\t     * RIPEMD160 hash algorithm.\n\t     */\n\t    var RIPEMD160 = C_algo.RIPEMD160 = Hasher.extend({\n\t        _doReset: function () {\n\t            this._hash  = WordArray.create([0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0]);\n\t        },\n\n\t        _doProcessBlock: function (M, offset) {\n\n\t            // Swap endian\n\t            for (var i = 0; i < 16; i++) {\n\t                // Shortcuts\n\t                var offset_i = offset + i;\n\t                var M_offset_i = M[offset_i];\n\n\t                // Swap\n\t                M[offset_i] = (\n\t                    (((M_offset_i << 8)  | (M_offset_i >>> 24)) & 0x00ff00ff) |\n\t                    (((M_offset_i << 24) | (M_offset_i >>> 8))  & 0xff00ff00)\n\t                );\n\t            }\n\t            // Shortcut\n\t            var H  = this._hash.words;\n\t            var hl = _hl.words;\n\t            var hr = _hr.words;\n\t            var zl = _zl.words;\n\t            var zr = _zr.words;\n\t            var sl = _sl.words;\n\t            var sr = _sr.words;\n\n\t            // Working variables\n\t            var al, bl, cl, dl, el;\n\t            var ar, br, cr, dr, er;\n\n\t            ar = al = H[0];\n\t            br = bl = H[1];\n\t            cr = cl = H[2];\n\t            dr = dl = H[3];\n\t            er = el = H[4];\n\t            // Computation\n\t            var t;\n\t            for (var i = 0; i < 80; i += 1) {\n\t                t = (al +  M[offset+zl[i]])|0;\n\t                if (i<16){\n\t\t            t +=  f1(bl,cl,dl) + hl[0];\n\t                } else if (i<32) {\n\t\t            t +=  f2(bl,cl,dl) + hl[1];\n\t                } else if (i<48) {\n\t\t            t +=  f3(bl,cl,dl) + hl[2];\n\t                } else if (i<64) {\n\t\t            t +=  f4(bl,cl,dl) + hl[3];\n\t                } else {// if (i<80) {\n\t\t            t +=  f5(bl,cl,dl) + hl[4];\n\t                }\n\t                t = t|0;\n\t                t =  rotl(t,sl[i]);\n\t                t = (t+el)|0;\n\t                al = el;\n\t                el = dl;\n\t                dl = rotl(cl, 10);\n\t                cl = bl;\n\t                bl = t;\n\n\t                t = (ar + M[offset+zr[i]])|0;\n\t                if (i<16){\n\t\t            t +=  f5(br,cr,dr) + hr[0];\n\t                } else if (i<32) {\n\t\t            t +=  f4(br,cr,dr) + hr[1];\n\t                } else if (i<48) {\n\t\t            t +=  f3(br,cr,dr) + hr[2];\n\t                } else if (i<64) {\n\t\t            t +=  f2(br,cr,dr) + hr[3];\n\t                } else {// if (i<80) {\n\t\t            t +=  f1(br,cr,dr) + hr[4];\n\t                }\n\t                t = t|0;\n\t                t =  rotl(t,sr[i]) ;\n\t                t = (t+er)|0;\n\t                ar = er;\n\t                er = dr;\n\t                dr = rotl(cr, 10);\n\t                cr = br;\n\t                br = t;\n\t            }\n\t            // Intermediate hash value\n\t            t    = (H[1] + cl + dr)|0;\n\t            H[1] = (H[2] + dl + er)|0;\n\t            H[2] = (H[3] + el + ar)|0;\n\t            H[3] = (H[4] + al + br)|0;\n\t            H[4] = (H[0] + bl + cr)|0;\n\t            H[0] =  t;\n\t        },\n\n\t        _doFinalize: function () {\n\t            // Shortcuts\n\t            var data = this._data;\n\t            var dataWords = data.words;\n\n\t            var nBitsTotal = this._nDataBytes * 8;\n\t            var nBitsLeft = data.sigBytes * 8;\n\n\t            // Add padding\n\t            dataWords[nBitsLeft >>> 5] |= 0x80 << (24 - nBitsLeft % 32);\n\t            dataWords[(((nBitsLeft + 64) >>> 9) << 4) + 14] = (\n\t                (((nBitsTotal << 8)  | (nBitsTotal >>> 24)) & 0x00ff00ff) |\n\t                (((nBitsTotal << 24) | (nBitsTotal >>> 8))  & 0xff00ff00)\n\t            );\n\t            data.sigBytes = (dataWords.length + 1) * 4;\n\n\t            // Hash final blocks\n\t            this._process();\n\n\t            // Shortcuts\n\t            var hash = this._hash;\n\t            var H = hash.words;\n\n\t            // Swap endian\n\t            for (var i = 0; i < 5; i++) {\n\t                // Shortcut\n\t                var H_i = H[i];\n\n\t                // Swap\n\t                H[i] = (((H_i << 8)  | (H_i >>> 24)) & 0x00ff00ff) |\n\t                       (((H_i << 24) | (H_i >>> 8))  & 0xff00ff00);\n\t            }\n\n\t            // Return final computed hash\n\t            return hash;\n\t        },\n\n\t        clone: function () {\n\t            var clone = Hasher.clone.call(this);\n\t            clone._hash = this._hash.clone();\n\n\t            return clone;\n\t        }\n\t    });\n\n\n\t    function f1(x, y, z) {\n\t        return ((x) ^ (y) ^ (z));\n\n\t    }\n\n\t    function f2(x, y, z) {\n\t        return (((x)&(y)) | ((~x)&(z)));\n\t    }\n\n\t    function f3(x, y, z) {\n\t        return (((x) | (~(y))) ^ (z));\n\t    }\n\n\t    function f4(x, y, z) {\n\t        return (((x) & (z)) | ((y)&(~(z))));\n\t    }\n\n\t    function f5(x, y, z) {\n\t        return ((x) ^ ((y) |(~(z))));\n\n\t    }\n\n\t    function rotl(x,n) {\n\t        return (x<<n) | (x>>>(32-n));\n\t    }\n\n\n\t    /**\n\t     * Shortcut function to the hasher's object interface.\n\t     *\n\t     * @param {WordArray|string} message The message to hash.\n\t     *\n\t     * @return {WordArray} The hash.\n\t     *\n\t     * @static\n\t     *\n\t     * @example\n\t     *\n\t     *     var hash = CryptoJS.RIPEMD160('message');\n\t     *     var hash = CryptoJS.RIPEMD160(wordArray);\n\t     */\n\t    C.RIPEMD160 = Hasher._createHelper(RIPEMD160);\n\n\t    /**\n\t     * Shortcut function to the HMAC's object interface.\n\t     *\n\t     * @param {WordArray|string} message The message to hash.\n\t     * @param {WordArray|string} key The secret key.\n\t     *\n\t     * @return {WordArray} The HMAC.\n\t     *\n\t     * @static\n\t     *\n\t     * @example\n\t     *\n\t     *     var hmac = CryptoJS.HmacRIPEMD160(message, key);\n\t     */\n\t    C.HmacRIPEMD160 = Hasher._createHmacHelper(RIPEMD160);\n\t}(Math));\n\n\n\treturn CryptoJS.RIPEMD160;\n\n}));\n\n/***/ }),\n/* 19 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory, undef) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0), __webpack_require__(6), __webpack_require__(7));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t(function () {\n\t    // Shortcuts\n\t    var C = CryptoJS;\n\t    var C_lib = C.lib;\n\t    var Base = C_lib.Base;\n\t    var WordArray = C_lib.WordArray;\n\t    var C_algo = C.algo;\n\t    var SHA1 = C_algo.SHA1;\n\t    var HMAC = C_algo.HMAC;\n\n\t    /**\n\t     * Password-Based Key Derivation Function 2 algorithm.\n\t     */\n\t    var PBKDF2 = C_algo.PBKDF2 = Base.extend({\n\t        /**\n\t         * Configuration options.\n\t         *\n\t         * @property {number} keySize The key size in words to generate. Default: 4 (128 bits)\n\t         * @property {Hasher} hasher The hasher to use. Default: SHA1\n\t         * @property {number} iterations The number of iterations to perform. Default: 1\n\t         */\n\t        cfg: Base.extend({\n\t            keySize: 128/32,\n\t            hasher: SHA1,\n\t            iterations: 1\n\t        }),\n\n\t        /**\n\t         * Initializes a newly created key derivation function.\n\t         *\n\t         * @param {Object} cfg (Optional) The configuration options to use for the derivation.\n\t         *\n\t         * @example\n\t         *\n\t         *     var kdf = CryptoJS.algo.PBKDF2.create();\n\t         *     var kdf = CryptoJS.algo.PBKDF2.create({ keySize: 8 });\n\t         *     var kdf = CryptoJS.algo.PBKDF2.create({ keySize: 8, iterations: 1000 });\n\t         */\n\t        init: function (cfg) {\n\t            this.cfg = this.cfg.extend(cfg);\n\t        },\n\n\t        /**\n\t         * Computes the Password-Based Key Derivation Function 2.\n\t         *\n\t         * @param {WordArray|string} password The password.\n\t         * @param {WordArray|string} salt A salt.\n\t         *\n\t         * @return {WordArray} The derived key.\n\t         *\n\t         * @example\n\t         *\n\t         *     var key = kdf.compute(password, salt);\n\t         */\n\t        compute: function (password, salt) {\n\t            // Shortcut\n\t            var cfg = this.cfg;\n\n\t            // Init HMAC\n\t            var hmac = HMAC.create(cfg.hasher, password);\n\n\t            // Initial values\n\t            var derivedKey = WordArray.create();\n\t            var blockIndex = WordArray.create([0x00000001]);\n\n\t            // Shortcuts\n\t            var derivedKeyWords = derivedKey.words;\n\t            var blockIndexWords = blockIndex.words;\n\t            var keySize = cfg.keySize;\n\t            var iterations = cfg.iterations;\n\n\t            // Generate key\n\t            while (derivedKeyWords.length < keySize) {\n\t                var block = hmac.update(salt).finalize(blockIndex);\n\t                hmac.reset();\n\n\t                // Shortcuts\n\t                var blockWords = block.words;\n\t                var blockWordsLength = blockWords.length;\n\n\t                // Iterations\n\t                var intermediate = block;\n\t                for (var i = 1; i < iterations; i++) {\n\t                    intermediate = hmac.finalize(intermediate);\n\t                    hmac.reset();\n\n\t                    // Shortcut\n\t                    var intermediateWords = intermediate.words;\n\n\t                    // XOR intermediate with block\n\t                    for (var j = 0; j < blockWordsLength; j++) {\n\t                        blockWords[j] ^= intermediateWords[j];\n\t                    }\n\t                }\n\n\t                derivedKey.concat(block);\n\t                blockIndexWords[0]++;\n\t            }\n\t            derivedKey.sigBytes = keySize * 4;\n\n\t            return derivedKey;\n\t        }\n\t    });\n\n\t    /**\n\t     * Computes the Password-Based Key Derivation Function 2.\n\t     *\n\t     * @param {WordArray|string} password The password.\n\t     * @param {WordArray|string} salt A salt.\n\t     * @param {Object} cfg (Optional) The configuration options to use for this computation.\n\t     *\n\t     * @return {WordArray} The derived key.\n\t     *\n\t     * @static\n\t     *\n\t     * @example\n\t     *\n\t     *     var key = CryptoJS.PBKDF2(password, salt);\n\t     *     var key = CryptoJS.PBKDF2(password, salt, { keySize: 8 });\n\t     *     var key = CryptoJS.PBKDF2(password, salt, { keySize: 8, iterations: 1000 });\n\t     */\n\t    C.PBKDF2 = function (password, salt, cfg) {\n\t        return PBKDF2.create(cfg).compute(password, salt);\n\t    };\n\t}());\n\n\n\treturn CryptoJS.PBKDF2;\n\n}));\n\n/***/ }),\n/* 20 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory, undef) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0), __webpack_require__(1));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t/**\n\t * Cipher Feedback block mode.\n\t */\n\tCryptoJS.mode.CFB = (function () {\n\t    var CFB = CryptoJS.lib.BlockCipherMode.extend();\n\n\t    CFB.Encryptor = CFB.extend({\n\t        processBlock: function (words, offset) {\n\t            // Shortcuts\n\t            var cipher = this._cipher;\n\t            var blockSize = cipher.blockSize;\n\n\t            generateKeystreamAndEncrypt.call(this, words, offset, blockSize, cipher);\n\n\t            // Remember this block to use with next block\n\t            this._prevBlock = words.slice(offset, offset + blockSize);\n\t        }\n\t    });\n\n\t    CFB.Decryptor = CFB.extend({\n\t        processBlock: function (words, offset) {\n\t            // Shortcuts\n\t            var cipher = this._cipher;\n\t            var blockSize = cipher.blockSize;\n\n\t            // Remember this block to use with next block\n\t            var thisBlock = words.slice(offset, offset + blockSize);\n\n\t            generateKeystreamAndEncrypt.call(this, words, offset, blockSize, cipher);\n\n\t            // This block becomes the previous block\n\t            this._prevBlock = thisBlock;\n\t        }\n\t    });\n\n\t    function generateKeystreamAndEncrypt(words, offset, blockSize, cipher) {\n\t        // Shortcut\n\t        var iv = this._iv;\n\n\t        // Generate keystream\n\t        if (iv) {\n\t            var keystream = iv.slice(0);\n\n\t            // Remove IV for subsequent blocks\n\t            this._iv = undefined;\n\t        } else {\n\t            var keystream = this._prevBlock;\n\t        }\n\t        cipher.encryptBlock(keystream, 0);\n\n\t        // Encrypt\n\t        for (var i = 0; i < blockSize; i++) {\n\t            words[offset + i] ^= keystream[i];\n\t        }\n\t    }\n\n\t    return CFB;\n\t}());\n\n\n\treturn CryptoJS.mode.CFB;\n\n}));\n\n/***/ }),\n/* 21 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory, undef) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0), __webpack_require__(1));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t/**\n\t * Counter block mode.\n\t */\n\tCryptoJS.mode.CTR = (function () {\n\t    var CTR = CryptoJS.lib.BlockCipherMode.extend();\n\n\t    var Encryptor = CTR.Encryptor = CTR.extend({\n\t        processBlock: function (words, offset) {\n\t            // Shortcuts\n\t            var cipher = this._cipher\n\t            var blockSize = cipher.blockSize;\n\t            var iv = this._iv;\n\t            var counter = this._counter;\n\n\t            // Generate keystream\n\t            if (iv) {\n\t                counter = this._counter = iv.slice(0);\n\n\t                // Remove IV for subsequent blocks\n\t                this._iv = undefined;\n\t            }\n\t            var keystream = counter.slice(0);\n\t            cipher.encryptBlock(keystream, 0);\n\n\t            // Increment counter\n\t            counter[blockSize - 1] = (counter[blockSize - 1] + 1) | 0\n\n\t            // Encrypt\n\t            for (var i = 0; i < blockSize; i++) {\n\t                words[offset + i] ^= keystream[i];\n\t            }\n\t        }\n\t    });\n\n\t    CTR.Decryptor = Encryptor;\n\n\t    return CTR;\n\t}());\n\n\n\treturn CryptoJS.mode.CTR;\n\n}));\n\n/***/ }),\n/* 22 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory, undef) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0), __webpack_require__(1));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t/** @preserve\n\t * Counter block mode compatible with  Dr Brian Gladman fileenc.c\n\t * derived from CryptoJS.mode.CTR\n\t * Jan Hruby jhruby.web@gmail.com\n\t */\n\tCryptoJS.mode.CTRGladman = (function () {\n\t    var CTRGladman = CryptoJS.lib.BlockCipherMode.extend();\n\n\t\tfunction incWord(word)\n\t\t{\n\t\t\tif (((word >> 24) & 0xff) === 0xff) { //overflow\n\t\t\tvar b1 = (word >> 16)&0xff;\n\t\t\tvar b2 = (word >> 8)&0xff;\n\t\t\tvar b3 = word & 0xff;\n\n\t\t\tif (b1 === 0xff) // overflow b1\n\t\t\t{\n\t\t\tb1 = 0;\n\t\t\tif (b2 === 0xff)\n\t\t\t{\n\t\t\t\tb2 = 0;\n\t\t\t\tif (b3 === 0xff)\n\t\t\t\t{\n\t\t\t\t\tb3 = 0;\n\t\t\t\t}\n\t\t\t\telse\n\t\t\t\t{\n\t\t\t\t\t++b3;\n\t\t\t\t}\n\t\t\t}\n\t\t\telse\n\t\t\t{\n\t\t\t\t++b2;\n\t\t\t}\n\t\t\t}\n\t\t\telse\n\t\t\t{\n\t\t\t++b1;\n\t\t\t}\n\n\t\t\tword = 0;\n\t\t\tword += (b1 << 16);\n\t\t\tword += (b2 << 8);\n\t\t\tword += b3;\n\t\t\t}\n\t\t\telse\n\t\t\t{\n\t\t\tword += (0x01 << 24);\n\t\t\t}\n\t\t\treturn word;\n\t\t}\n\n\t\tfunction incCounter(counter)\n\t\t{\n\t\t\tif ((counter[0] = incWord(counter[0])) === 0)\n\t\t\t{\n\t\t\t\t// encr_data in fileenc.c from  Dr Brian Gladman's counts only with DWORD j < 8\n\t\t\t\tcounter[1] = incWord(counter[1]);\n\t\t\t}\n\t\t\treturn counter;\n\t\t}\n\n\t    var Encryptor = CTRGladman.Encryptor = CTRGladman.extend({\n\t        processBlock: function (words, offset) {\n\t            // Shortcuts\n\t            var cipher = this._cipher\n\t            var blockSize = cipher.blockSize;\n\t            var iv = this._iv;\n\t            var counter = this._counter;\n\n\t            // Generate keystream\n\t            if (iv) {\n\t                counter = this._counter = iv.slice(0);\n\n\t                // Remove IV for subsequent blocks\n\t                this._iv = undefined;\n\t            }\n\n\t\t\t\tincCounter(counter);\n\n\t\t\t\tvar keystream = counter.slice(0);\n\t            cipher.encryptBlock(keystream, 0);\n\n\t            // Encrypt\n\t            for (var i = 0; i < blockSize; i++) {\n\t                words[offset + i] ^= keystream[i];\n\t            }\n\t        }\n\t    });\n\n\t    CTRGladman.Decryptor = Encryptor;\n\n\t    return CTRGladman;\n\t}());\n\n\n\n\n\treturn CryptoJS.mode.CTRGladman;\n\n}));\n\n/***/ }),\n/* 23 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory, undef) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0), __webpack_require__(1));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t/**\n\t * Output Feedback block mode.\n\t */\n\tCryptoJS.mode.OFB = (function () {\n\t    var OFB = CryptoJS.lib.BlockCipherMode.extend();\n\n\t    var Encryptor = OFB.Encryptor = OFB.extend({\n\t        processBlock: function (words, offset) {\n\t            // Shortcuts\n\t            var cipher = this._cipher\n\t            var blockSize = cipher.blockSize;\n\t            var iv = this._iv;\n\t            var keystream = this._keystream;\n\n\t            // Generate keystream\n\t            if (iv) {\n\t                keystream = this._keystream = iv.slice(0);\n\n\t                // Remove IV for subsequent blocks\n\t                this._iv = undefined;\n\t            }\n\t            cipher.encryptBlock(keystream, 0);\n\n\t            // Encrypt\n\t            for (var i = 0; i < blockSize; i++) {\n\t                words[offset + i] ^= keystream[i];\n\t            }\n\t        }\n\t    });\n\n\t    OFB.Decryptor = Encryptor;\n\n\t    return OFB;\n\t}());\n\n\n\treturn CryptoJS.mode.OFB;\n\n}));\n\n/***/ }),\n/* 24 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory, undef) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0), __webpack_require__(1));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t/**\n\t * Electronic Codebook block mode.\n\t */\n\tCryptoJS.mode.ECB = (function () {\n\t    var ECB = CryptoJS.lib.BlockCipherMode.extend();\n\n\t    ECB.Encryptor = ECB.extend({\n\t        processBlock: function (words, offset) {\n\t            this._cipher.encryptBlock(words, offset);\n\t        }\n\t    });\n\n\t    ECB.Decryptor = ECB.extend({\n\t        processBlock: function (words, offset) {\n\t            this._cipher.decryptBlock(words, offset);\n\t        }\n\t    });\n\n\t    return ECB;\n\t}());\n\n\n\treturn CryptoJS.mode.ECB;\n\n}));\n\n/***/ }),\n/* 25 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory, undef) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0), __webpack_require__(1));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t/**\n\t * ANSI X.923 padding strategy.\n\t */\n\tCryptoJS.pad.AnsiX923 = {\n\t    pad: function (data, blockSize) {\n\t        // Shortcuts\n\t        var dataSigBytes = data.sigBytes;\n\t        var blockSizeBytes = blockSize * 4;\n\n\t        // Count padding bytes\n\t        var nPaddingBytes = blockSizeBytes - dataSigBytes % blockSizeBytes;\n\n\t        // Compute last byte position\n\t        var lastBytePos = dataSigBytes + nPaddingBytes - 1;\n\n\t        // Pad\n\t        data.clamp();\n\t        data.words[lastBytePos >>> 2] |= nPaddingBytes << (24 - (lastBytePos % 4) * 8);\n\t        data.sigBytes += nPaddingBytes;\n\t    },\n\n\t    unpad: function (data) {\n\t        // Get number of padding bytes from last byte\n\t        var nPaddingBytes = data.words[(data.sigBytes - 1) >>> 2] & 0xff;\n\n\t        // Remove padding\n\t        data.sigBytes -= nPaddingBytes;\n\t    }\n\t};\n\n\n\treturn CryptoJS.pad.Ansix923;\n\n}));\n\n/***/ }),\n/* 26 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory, undef) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0), __webpack_require__(1));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t/**\n\t * ISO 10126 padding strategy.\n\t */\n\tCryptoJS.pad.Iso10126 = {\n\t    pad: function (data, blockSize) {\n\t        // Shortcut\n\t        var blockSizeBytes = blockSize * 4;\n\n\t        // Count padding bytes\n\t        var nPaddingBytes = blockSizeBytes - data.sigBytes % blockSizeBytes;\n\n\t        // Pad\n\t        data.concat(CryptoJS.lib.WordArray.random(nPaddingBytes - 1)).\n\t             concat(CryptoJS.lib.WordArray.create([nPaddingBytes << 24], 1));\n\t    },\n\n\t    unpad: function (data) {\n\t        // Get number of padding bytes from last byte\n\t        var nPaddingBytes = data.words[(data.sigBytes - 1) >>> 2] & 0xff;\n\n\t        // Remove padding\n\t        data.sigBytes -= nPaddingBytes;\n\t    }\n\t};\n\n\n\treturn CryptoJS.pad.Iso10126;\n\n}));\n\n/***/ }),\n/* 27 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory, undef) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0), __webpack_require__(1));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t/**\n\t * ISO/IEC 9797-1 Padding Method 2.\n\t */\n\tCryptoJS.pad.Iso97971 = {\n\t    pad: function (data, blockSize) {\n\t        // Add 0x80 byte\n\t        data.concat(CryptoJS.lib.WordArray.create([0x80000000], 1));\n\n\t        // Zero pad the rest\n\t        CryptoJS.pad.ZeroPadding.pad(data, blockSize);\n\t    },\n\n\t    unpad: function (data) {\n\t        // Remove zero padding\n\t        CryptoJS.pad.ZeroPadding.unpad(data);\n\n\t        // Remove one more byte -- the 0x80 byte\n\t        data.sigBytes--;\n\t    }\n\t};\n\n\n\treturn CryptoJS.pad.Iso97971;\n\n}));\n\n/***/ }),\n/* 28 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory, undef) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0), __webpack_require__(1));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t/**\n\t * Zero padding strategy.\n\t */\n\tCryptoJS.pad.ZeroPadding = {\n\t    pad: function (data, blockSize) {\n\t        // Shortcut\n\t        var blockSizeBytes = blockSize * 4;\n\n\t        // Pad\n\t        data.clamp();\n\t        data.sigBytes += blockSizeBytes - ((data.sigBytes % blockSizeBytes) || blockSizeBytes);\n\t    },\n\n\t    unpad: function (data) {\n\t        // Shortcut\n\t        var dataWords = data.words;\n\n\t        // Unpad\n\t        var i = data.sigBytes - 1;\n\t        while (!((dataWords[i >>> 2] >>> (24 - (i % 4) * 8)) & 0xff)) {\n\t            i--;\n\t        }\n\t        data.sigBytes = i + 1;\n\t    }\n\t};\n\n\n\treturn CryptoJS.pad.ZeroPadding;\n\n}));\n\n/***/ }),\n/* 29 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory, undef) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0), __webpack_require__(1));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t/**\n\t * A noop padding strategy.\n\t */\n\tCryptoJS.pad.NoPadding = {\n\t    pad: function () {\n\t    },\n\n\t    unpad: function () {\n\t    }\n\t};\n\n\n\treturn CryptoJS.pad.NoPadding;\n\n}));\n\n/***/ }),\n/* 30 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory, undef) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0), __webpack_require__(1));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t(function (undefined) {\n\t    // Shortcuts\n\t    var C = CryptoJS;\n\t    var C_lib = C.lib;\n\t    var CipherParams = C_lib.CipherParams;\n\t    var C_enc = C.enc;\n\t    var Hex = C_enc.Hex;\n\t    var C_format = C.format;\n\n\t    var HexFormatter = C_format.Hex = {\n\t        /**\n\t         * Converts the ciphertext of a cipher params object to a hexadecimally encoded string.\n\t         *\n\t         * @param {CipherParams} cipherParams The cipher params object.\n\t         *\n\t         * @return {string} The hexadecimally encoded string.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var hexString = CryptoJS.format.Hex.stringify(cipherParams);\n\t         */\n\t        stringify: function (cipherParams) {\n\t            return cipherParams.ciphertext.toString(Hex);\n\t        },\n\n\t        /**\n\t         * Converts a hexadecimally encoded ciphertext string to a cipher params object.\n\t         *\n\t         * @param {string} input The hexadecimally encoded string.\n\t         *\n\t         * @return {CipherParams} The cipher params object.\n\t         *\n\t         * @static\n\t         *\n\t         * @example\n\t         *\n\t         *     var cipherParams = CryptoJS.format.Hex.parse(hexString);\n\t         */\n\t        parse: function (input) {\n\t            var ciphertext = Hex.parse(input);\n\t            return CipherParams.create({ ciphertext: ciphertext });\n\t        }\n\t    };\n\t}());\n\n\n\treturn CryptoJS.format.Hex;\n\n}));\n\n/***/ }),\n/* 31 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory, undef) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0), __webpack_require__(3), __webpack_require__(4), __webpack_require__(2), __webpack_require__(1));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t(function () {\n\t    // Shortcuts\n\t    var C = CryptoJS;\n\t    var C_lib = C.lib;\n\t    var BlockCipher = C_lib.BlockCipher;\n\t    var C_algo = C.algo;\n\n\t    // Lookup tables\n\t    var SBOX = [];\n\t    var INV_SBOX = [];\n\t    var SUB_MIX_0 = [];\n\t    var SUB_MIX_1 = [];\n\t    var SUB_MIX_2 = [];\n\t    var SUB_MIX_3 = [];\n\t    var INV_SUB_MIX_0 = [];\n\t    var INV_SUB_MIX_1 = [];\n\t    var INV_SUB_MIX_2 = [];\n\t    var INV_SUB_MIX_3 = [];\n\n\t    // Compute lookup tables\n\t    (function () {\n\t        // Compute double table\n\t        var d = [];\n\t        for (var i = 0; i < 256; i++) {\n\t            if (i < 128) {\n\t                d[i] = i << 1;\n\t            } else {\n\t                d[i] = (i << 1) ^ 0x11b;\n\t            }\n\t        }\n\n\t        // Walk GF(2^8)\n\t        var x = 0;\n\t        var xi = 0;\n\t        for (var i = 0; i < 256; i++) {\n\t            // Compute sbox\n\t            var sx = xi ^ (xi << 1) ^ (xi << 2) ^ (xi << 3) ^ (xi << 4);\n\t            sx = (sx >>> 8) ^ (sx & 0xff) ^ 0x63;\n\t            SBOX[x] = sx;\n\t            INV_SBOX[sx] = x;\n\n\t            // Compute multiplication\n\t            var x2 = d[x];\n\t            var x4 = d[x2];\n\t            var x8 = d[x4];\n\n\t            // Compute sub bytes, mix columns tables\n\t            var t = (d[sx] * 0x101) ^ (sx * 0x1010100);\n\t            SUB_MIX_0[x] = (t << 24) | (t >>> 8);\n\t            SUB_MIX_1[x] = (t << 16) | (t >>> 16);\n\t            SUB_MIX_2[x] = (t << 8)  | (t >>> 24);\n\t            SUB_MIX_3[x] = t;\n\n\t            // Compute inv sub bytes, inv mix columns tables\n\t            var t = (x8 * 0x1010101) ^ (x4 * 0x10001) ^ (x2 * 0x101) ^ (x * 0x1010100);\n\t            INV_SUB_MIX_0[sx] = (t << 24) | (t >>> 8);\n\t            INV_SUB_MIX_1[sx] = (t << 16) | (t >>> 16);\n\t            INV_SUB_MIX_2[sx] = (t << 8)  | (t >>> 24);\n\t            INV_SUB_MIX_3[sx] = t;\n\n\t            // Compute next counter\n\t            if (!x) {\n\t                x = xi = 1;\n\t            } else {\n\t                x = x2 ^ d[d[d[x8 ^ x2]]];\n\t                xi ^= d[d[xi]];\n\t            }\n\t        }\n\t    }());\n\n\t    // Precomputed Rcon lookup\n\t    var RCON = [0x00, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36];\n\n\t    /**\n\t     * AES block cipher algorithm.\n\t     */\n\t    var AES = C_algo.AES = BlockCipher.extend({\n\t        _doReset: function () {\n\t            // Skip reset of nRounds has been set before and key did not change\n\t            if (this._nRounds && this._keyPriorReset === this._key) {\n\t                return;\n\t            }\n\n\t            // Shortcuts\n\t            var key = this._keyPriorReset = this._key;\n\t            var keyWords = key.words;\n\t            var keySize = key.sigBytes / 4;\n\n\t            // Compute number of rounds\n\t            var nRounds = this._nRounds = keySize + 6;\n\n\t            // Compute number of key schedule rows\n\t            var ksRows = (nRounds + 1) * 4;\n\n\t            // Compute key schedule\n\t            var keySchedule = this._keySchedule = [];\n\t            for (var ksRow = 0; ksRow < ksRows; ksRow++) {\n\t                if (ksRow < keySize) {\n\t                    keySchedule[ksRow] = keyWords[ksRow];\n\t                } else {\n\t                    var t = keySchedule[ksRow - 1];\n\n\t                    if (!(ksRow % keySize)) {\n\t                        // Rot word\n\t                        t = (t << 8) | (t >>> 24);\n\n\t                        // Sub word\n\t                        t = (SBOX[t >>> 24] << 24) | (SBOX[(t >>> 16) & 0xff] << 16) | (SBOX[(t >>> 8) & 0xff] << 8) | SBOX[t & 0xff];\n\n\t                        // Mix Rcon\n\t                        t ^= RCON[(ksRow / keySize) | 0] << 24;\n\t                    } else if (keySize > 6 && ksRow % keySize == 4) {\n\t                        // Sub word\n\t                        t = (SBOX[t >>> 24] << 24) | (SBOX[(t >>> 16) & 0xff] << 16) | (SBOX[(t >>> 8) & 0xff] << 8) | SBOX[t & 0xff];\n\t                    }\n\n\t                    keySchedule[ksRow] = keySchedule[ksRow - keySize] ^ t;\n\t                }\n\t            }\n\n\t            // Compute inv key schedule\n\t            var invKeySchedule = this._invKeySchedule = [];\n\t            for (var invKsRow = 0; invKsRow < ksRows; invKsRow++) {\n\t                var ksRow = ksRows - invKsRow;\n\n\t                if (invKsRow % 4) {\n\t                    var t = keySchedule[ksRow];\n\t                } else {\n\t                    var t = keySchedule[ksRow - 4];\n\t                }\n\n\t                if (invKsRow < 4 || ksRow <= 4) {\n\t                    invKeySchedule[invKsRow] = t;\n\t                } else {\n\t                    invKeySchedule[invKsRow] = INV_SUB_MIX_0[SBOX[t >>> 24]] ^ INV_SUB_MIX_1[SBOX[(t >>> 16) & 0xff]] ^\n\t                                               INV_SUB_MIX_2[SBOX[(t >>> 8) & 0xff]] ^ INV_SUB_MIX_3[SBOX[t & 0xff]];\n\t                }\n\t            }\n\t        },\n\n\t        encryptBlock: function (M, offset) {\n\t            this._doCryptBlock(M, offset, this._keySchedule, SUB_MIX_0, SUB_MIX_1, SUB_MIX_2, SUB_MIX_3, SBOX);\n\t        },\n\n\t        decryptBlock: function (M, offset) {\n\t            // Swap 2nd and 4th rows\n\t            var t = M[offset + 1];\n\t            M[offset + 1] = M[offset + 3];\n\t            M[offset + 3] = t;\n\n\t            this._doCryptBlock(M, offset, this._invKeySchedule, INV_SUB_MIX_0, INV_SUB_MIX_1, INV_SUB_MIX_2, INV_SUB_MIX_3, INV_SBOX);\n\n\t            // Inv swap 2nd and 4th rows\n\t            var t = M[offset + 1];\n\t            M[offset + 1] = M[offset + 3];\n\t            M[offset + 3] = t;\n\t        },\n\n\t        _doCryptBlock: function (M, offset, keySchedule, SUB_MIX_0, SUB_MIX_1, SUB_MIX_2, SUB_MIX_3, SBOX) {\n\t            // Shortcut\n\t            var nRounds = this._nRounds;\n\n\t            // Get input, add round key\n\t            var s0 = M[offset]     ^ keySchedule[0];\n\t            var s1 = M[offset + 1] ^ keySchedule[1];\n\t            var s2 = M[offset + 2] ^ keySchedule[2];\n\t            var s3 = M[offset + 3] ^ keySchedule[3];\n\n\t            // Key schedule row counter\n\t            var ksRow = 4;\n\n\t            // Rounds\n\t            for (var round = 1; round < nRounds; round++) {\n\t                // Shift rows, sub bytes, mix columns, add round key\n\t                var t0 = SUB_MIX_0[s0 >>> 24] ^ SUB_MIX_1[(s1 >>> 16) & 0xff] ^ SUB_MIX_2[(s2 >>> 8) & 0xff] ^ SUB_MIX_3[s3 & 0xff] ^ keySchedule[ksRow++];\n\t                var t1 = SUB_MIX_0[s1 >>> 24] ^ SUB_MIX_1[(s2 >>> 16) & 0xff] ^ SUB_MIX_2[(s3 >>> 8) & 0xff] ^ SUB_MIX_3[s0 & 0xff] ^ keySchedule[ksRow++];\n\t                var t2 = SUB_MIX_0[s2 >>> 24] ^ SUB_MIX_1[(s3 >>> 16) & 0xff] ^ SUB_MIX_2[(s0 >>> 8) & 0xff] ^ SUB_MIX_3[s1 & 0xff] ^ keySchedule[ksRow++];\n\t                var t3 = SUB_MIX_0[s3 >>> 24] ^ SUB_MIX_1[(s0 >>> 16) & 0xff] ^ SUB_MIX_2[(s1 >>> 8) & 0xff] ^ SUB_MIX_3[s2 & 0xff] ^ keySchedule[ksRow++];\n\n\t                // Update state\n\t                s0 = t0;\n\t                s1 = t1;\n\t                s2 = t2;\n\t                s3 = t3;\n\t            }\n\n\t            // Shift rows, sub bytes, add round key\n\t            var t0 = ((SBOX[s0 >>> 24] << 24) | (SBOX[(s1 >>> 16) & 0xff] << 16) | (SBOX[(s2 >>> 8) & 0xff] << 8) | SBOX[s3 & 0xff]) ^ keySchedule[ksRow++];\n\t            var t1 = ((SBOX[s1 >>> 24] << 24) | (SBOX[(s2 >>> 16) & 0xff] << 16) | (SBOX[(s3 >>> 8) & 0xff] << 8) | SBOX[s0 & 0xff]) ^ keySchedule[ksRow++];\n\t            var t2 = ((SBOX[s2 >>> 24] << 24) | (SBOX[(s3 >>> 16) & 0xff] << 16) | (SBOX[(s0 >>> 8) & 0xff] << 8) | SBOX[s1 & 0xff]) ^ keySchedule[ksRow++];\n\t            var t3 = ((SBOX[s3 >>> 24] << 24) | (SBOX[(s0 >>> 16) & 0xff] << 16) | (SBOX[(s1 >>> 8) & 0xff] << 8) | SBOX[s2 & 0xff]) ^ keySchedule[ksRow++];\n\n\t            // Set output\n\t            M[offset]     = t0;\n\t            M[offset + 1] = t1;\n\t            M[offset + 2] = t2;\n\t            M[offset + 3] = t3;\n\t        },\n\n\t        keySize: 256/32\n\t    });\n\n\t    /**\n\t     * Shortcut functions to the cipher's object interface.\n\t     *\n\t     * @example\n\t     *\n\t     *     var ciphertext = CryptoJS.AES.encrypt(message, key, cfg);\n\t     *     var plaintext  = CryptoJS.AES.decrypt(ciphertext, key, cfg);\n\t     */\n\t    C.AES = BlockCipher._createHelper(AES);\n\t}());\n\n\n\treturn CryptoJS.AES;\n\n}));\n\n/***/ }),\n/* 32 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory, undef) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0), __webpack_require__(3), __webpack_require__(4), __webpack_require__(2), __webpack_require__(1));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t(function () {\n\t    // Shortcuts\n\t    var C = CryptoJS;\n\t    var C_lib = C.lib;\n\t    var WordArray = C_lib.WordArray;\n\t    var BlockCipher = C_lib.BlockCipher;\n\t    var C_algo = C.algo;\n\n\t    // Permuted Choice 1 constants\n\t    var PC1 = [\n\t        57, 49, 41, 33, 25, 17, 9,  1,\n\t        58, 50, 42, 34, 26, 18, 10, 2,\n\t        59, 51, 43, 35, 27, 19, 11, 3,\n\t        60, 52, 44, 36, 63, 55, 47, 39,\n\t        31, 23, 15, 7,  62, 54, 46, 38,\n\t        30, 22, 14, 6,  61, 53, 45, 37,\n\t        29, 21, 13, 5,  28, 20, 12, 4\n\t    ];\n\n\t    // Permuted Choice 2 constants\n\t    var PC2 = [\n\t        14, 17, 11, 24, 1,  5,\n\t        3,  28, 15, 6,  21, 10,\n\t        23, 19, 12, 4,  26, 8,\n\t        16, 7,  27, 20, 13, 2,\n\t        41, 52, 31, 37, 47, 55,\n\t        30, 40, 51, 45, 33, 48,\n\t        44, 49, 39, 56, 34, 53,\n\t        46, 42, 50, 36, 29, 32\n\t    ];\n\n\t    // Cumulative bit shift constants\n\t    var BIT_SHIFTS = [1,  2,  4,  6,  8,  10, 12, 14, 15, 17, 19, 21, 23, 25, 27, 28];\n\n\t    // SBOXes and round permutation constants\n\t    var SBOX_P = [\n\t        {\n\t            0x0: 0x808200,\n\t            0x10000000: 0x8000,\n\t            0x20000000: 0x808002,\n\t            0x30000000: 0x2,\n\t            0x40000000: 0x200,\n\t            0x50000000: 0x808202,\n\t            0x60000000: 0x800202,\n\t            0x70000000: 0x800000,\n\t            0x80000000: 0x202,\n\t            0x90000000: 0x800200,\n\t            0xa0000000: 0x8200,\n\t            0xb0000000: 0x808000,\n\t            0xc0000000: 0x8002,\n\t            0xd0000000: 0x800002,\n\t            0xe0000000: 0x0,\n\t            0xf0000000: 0x8202,\n\t            0x8000000: 0x0,\n\t            0x18000000: 0x808202,\n\t            0x28000000: 0x8202,\n\t            0x38000000: 0x8000,\n\t            0x48000000: 0x808200,\n\t            0x58000000: 0x200,\n\t            0x68000000: 0x808002,\n\t            0x78000000: 0x2,\n\t            0x88000000: 0x800200,\n\t            0x98000000: 0x8200,\n\t            0xa8000000: 0x808000,\n\t            0xb8000000: 0x800202,\n\t            0xc8000000: 0x800002,\n\t            0xd8000000: 0x8002,\n\t            0xe8000000: 0x202,\n\t            0xf8000000: 0x800000,\n\t            0x1: 0x8000,\n\t            0x10000001: 0x2,\n\t            0x20000001: 0x808200,\n\t            0x30000001: 0x800000,\n\t            0x40000001: 0x808002,\n\t            0x50000001: 0x8200,\n\t            0x60000001: 0x200,\n\t            0x70000001: 0x800202,\n\t            0x80000001: 0x808202,\n\t            0x90000001: 0x808000,\n\t            0xa0000001: 0x800002,\n\t            0xb0000001: 0x8202,\n\t            0xc0000001: 0x202,\n\t            0xd0000001: 0x800200,\n\t            0xe0000001: 0x8002,\n\t            0xf0000001: 0x0,\n\t            0x8000001: 0x808202,\n\t            0x18000001: 0x808000,\n\t            0x28000001: 0x800000,\n\t            0x38000001: 0x200,\n\t            0x48000001: 0x8000,\n\t            0x58000001: 0x800002,\n\t            0x68000001: 0x2,\n\t            0x78000001: 0x8202,\n\t            0x88000001: 0x8002,\n\t            0x98000001: 0x800202,\n\t            0xa8000001: 0x202,\n\t            0xb8000001: 0x808200,\n\t            0xc8000001: 0x800200,\n\t            0xd8000001: 0x0,\n\t            0xe8000001: 0x8200,\n\t            0xf8000001: 0x808002\n\t        },\n\t        {\n\t            0x0: 0x40084010,\n\t            0x1000000: 0x4000,\n\t            0x2000000: 0x80000,\n\t            0x3000000: 0x40080010,\n\t            0x4000000: 0x40000010,\n\t            0x5000000: 0x40084000,\n\t            0x6000000: 0x40004000,\n\t            0x7000000: 0x10,\n\t            0x8000000: 0x84000,\n\t            0x9000000: 0x40004010,\n\t            0xa000000: 0x40000000,\n\t            0xb000000: 0x84010,\n\t            0xc000000: 0x80010,\n\t            0xd000000: 0x0,\n\t            0xe000000: 0x4010,\n\t            0xf000000: 0x40080000,\n\t            0x800000: 0x40004000,\n\t            0x1800000: 0x84010,\n\t            0x2800000: 0x10,\n\t            0x3800000: 0x40004010,\n\t            0x4800000: 0x40084010,\n\t            0x5800000: 0x40000000,\n\t            0x6800000: 0x80000,\n\t            0x7800000: 0x40080010,\n\t            0x8800000: 0x80010,\n\t            0x9800000: 0x0,\n\t            0xa800000: 0x4000,\n\t            0xb800000: 0x40080000,\n\t            0xc800000: 0x40000010,\n\t            0xd800000: 0x84000,\n\t            0xe800000: 0x40084000,\n\t            0xf800000: 0x4010,\n\t            0x10000000: 0x0,\n\t            0x11000000: 0x40080010,\n\t            0x12000000: 0x40004010,\n\t            0x13000000: 0x40084000,\n\t            0x14000000: 0x40080000,\n\t            0x15000000: 0x10,\n\t            0x16000000: 0x84010,\n\t            0x17000000: 0x4000,\n\t            0x18000000: 0x4010,\n\t            0x19000000: 0x80000,\n\t            0x1a000000: 0x80010,\n\t            0x1b000000: 0x40000010,\n\t            0x1c000000: 0x84000,\n\t            0x1d000000: 0x40004000,\n\t            0x1e000000: 0x40000000,\n\t            0x1f000000: 0x40084010,\n\t            0x10800000: 0x84010,\n\t            0x11800000: 0x80000,\n\t            0x12800000: 0x40080000,\n\t            0x13800000: 0x4000,\n\t            0x14800000: 0x40004000,\n\t            0x15800000: 0x40084010,\n\t            0x16800000: 0x10,\n\t            0x17800000: 0x40000000,\n\t            0x18800000: 0x40084000,\n\t            0x19800000: 0x40000010,\n\t            0x1a800000: 0x40004010,\n\t            0x1b800000: 0x80010,\n\t            0x1c800000: 0x0,\n\t            0x1d800000: 0x4010,\n\t            0x1e800000: 0x40080010,\n\t            0x1f800000: 0x84000\n\t        },\n\t        {\n\t            0x0: 0x104,\n\t            0x100000: 0x0,\n\t            0x200000: 0x4000100,\n\t            0x300000: 0x10104,\n\t            0x400000: 0x10004,\n\t            0x500000: 0x4000004,\n\t            0x600000: 0x4010104,\n\t            0x700000: 0x4010000,\n\t            0x800000: 0x4000000,\n\t            0x900000: 0x4010100,\n\t            0xa00000: 0x10100,\n\t            0xb00000: 0x4010004,\n\t            0xc00000: 0x4000104,\n\t            0xd00000: 0x10000,\n\t            0xe00000: 0x4,\n\t            0xf00000: 0x100,\n\t            0x80000: 0x4010100,\n\t            0x180000: 0x4010004,\n\t            0x280000: 0x0,\n\t            0x380000: 0x4000100,\n\t            0x480000: 0x4000004,\n\t            0x580000: 0x10000,\n\t            0x680000: 0x10004,\n\t            0x780000: 0x104,\n\t            0x880000: 0x4,\n\t            0x980000: 0x100,\n\t            0xa80000: 0x4010000,\n\t            0xb80000: 0x10104,\n\t            0xc80000: 0x10100,\n\t            0xd80000: 0x4000104,\n\t            0xe80000: 0x4010104,\n\t            0xf80000: 0x4000000,\n\t            0x1000000: 0x4010100,\n\t            0x1100000: 0x10004,\n\t            0x1200000: 0x10000,\n\t            0x1300000: 0x4000100,\n\t            0x1400000: 0x100,\n\t            0x1500000: 0x4010104,\n\t            0x1600000: 0x4000004,\n\t            0x1700000: 0x0,\n\t            0x1800000: 0x4000104,\n\t            0x1900000: 0x4000000,\n\t            0x1a00000: 0x4,\n\t            0x1b00000: 0x10100,\n\t            0x1c00000: 0x4010000,\n\t            0x1d00000: 0x104,\n\t            0x1e00000: 0x10104,\n\t            0x1f00000: 0x4010004,\n\t            0x1080000: 0x4000000,\n\t            0x1180000: 0x104,\n\t            0x1280000: 0x4010100,\n\t            0x1380000: 0x0,\n\t            0x1480000: 0x10004,\n\t            0x1580000: 0x4000100,\n\t            0x1680000: 0x100,\n\t            0x1780000: 0x4010004,\n\t            0x1880000: 0x10000,\n\t            0x1980000: 0x4010104,\n\t            0x1a80000: 0x10104,\n\t            0x1b80000: 0x4000004,\n\t            0x1c80000: 0x4000104,\n\t            0x1d80000: 0x4010000,\n\t            0x1e80000: 0x4,\n\t            0x1f80000: 0x10100\n\t        },\n\t        {\n\t            0x0: 0x80401000,\n\t            0x10000: 0x80001040,\n\t            0x20000: 0x401040,\n\t            0x30000: 0x80400000,\n\t            0x40000: 0x0,\n\t            0x50000: 0x401000,\n\t            0x60000: 0x80000040,\n\t            0x70000: 0x400040,\n\t            0x80000: 0x80000000,\n\t            0x90000: 0x400000,\n\t            0xa0000: 0x40,\n\t            0xb0000: 0x80001000,\n\t            0xc0000: 0x80400040,\n\t            0xd0000: 0x1040,\n\t            0xe0000: 0x1000,\n\t            0xf0000: 0x80401040,\n\t            0x8000: 0x80001040,\n\t            0x18000: 0x40,\n\t            0x28000: 0x80400040,\n\t            0x38000: 0x80001000,\n\t            0x48000: 0x401000,\n\t            0x58000: 0x80401040,\n\t            0x68000: 0x0,\n\t            0x78000: 0x80400000,\n\t            0x88000: 0x1000,\n\t            0x98000: 0x80401000,\n\t            0xa8000: 0x400000,\n\t            0xb8000: 0x1040,\n\t            0xc8000: 0x80000000,\n\t            0xd8000: 0x400040,\n\t            0xe8000: 0x401040,\n\t            0xf8000: 0x80000040,\n\t            0x100000: 0x400040,\n\t            0x110000: 0x401000,\n\t            0x120000: 0x80000040,\n\t            0x130000: 0x0,\n\t            0x140000: 0x1040,\n\t            0x150000: 0x80400040,\n\t            0x160000: 0x80401000,\n\t            0x170000: 0x80001040,\n\t            0x180000: 0x80401040,\n\t            0x190000: 0x80000000,\n\t            0x1a0000: 0x80400000,\n\t            0x1b0000: 0x401040,\n\t            0x1c0000: 0x80001000,\n\t            0x1d0000: 0x400000,\n\t            0x1e0000: 0x40,\n\t            0x1f0000: 0x1000,\n\t            0x108000: 0x80400000,\n\t            0x118000: 0x80401040,\n\t            0x128000: 0x0,\n\t            0x138000: 0x401000,\n\t            0x148000: 0x400040,\n\t            0x158000: 0x80000000,\n\t            0x168000: 0x80001040,\n\t            0x178000: 0x40,\n\t            0x188000: 0x80000040,\n\t            0x198000: 0x1000,\n\t            0x1a8000: 0x80001000,\n\t            0x1b8000: 0x80400040,\n\t            0x1c8000: 0x1040,\n\t            0x1d8000: 0x80401000,\n\t            0x1e8000: 0x400000,\n\t            0x1f8000: 0x401040\n\t        },\n\t        {\n\t            0x0: 0x80,\n\t            0x1000: 0x1040000,\n\t            0x2000: 0x40000,\n\t            0x3000: 0x20000000,\n\t            0x4000: 0x20040080,\n\t            0x5000: 0x1000080,\n\t            0x6000: 0x21000080,\n\t            0x7000: 0x40080,\n\t            0x8000: 0x1000000,\n\t            0x9000: 0x20040000,\n\t            0xa000: 0x20000080,\n\t            0xb000: 0x21040080,\n\t            0xc000: 0x21040000,\n\t            0xd000: 0x0,\n\t            0xe000: 0x1040080,\n\t            0xf000: 0x21000000,\n\t            0x800: 0x1040080,\n\t            0x1800: 0x21000080,\n\t            0x2800: 0x80,\n\t            0x3800: 0x1040000,\n\t            0x4800: 0x40000,\n\t            0x5800: 0x20040080,\n\t            0x6800: 0x21040000,\n\t            0x7800: 0x20000000,\n\t            0x8800: 0x20040000,\n\t            0x9800: 0x0,\n\t            0xa800: 0x21040080,\n\t            0xb800: 0x1000080,\n\t            0xc800: 0x20000080,\n\t            0xd800: 0x21000000,\n\t            0xe800: 0x1000000,\n\t            0xf800: 0x40080,\n\t            0x10000: 0x40000,\n\t            0x11000: 0x80,\n\t            0x12000: 0x20000000,\n\t            0x13000: 0x21000080,\n\t            0x14000: 0x1000080,\n\t            0x15000: 0x21040000,\n\t            0x16000: 0x20040080,\n\t            0x17000: 0x1000000,\n\t            0x18000: 0x21040080,\n\t            0x19000: 0x21000000,\n\t            0x1a000: 0x1040000,\n\t            0x1b000: 0x20040000,\n\t            0x1c000: 0x40080,\n\t            0x1d000: 0x20000080,\n\t            0x1e000: 0x0,\n\t            0x1f000: 0x1040080,\n\t            0x10800: 0x21000080,\n\t            0x11800: 0x1000000,\n\t            0x12800: 0x1040000,\n\t            0x13800: 0x20040080,\n\t            0x14800: 0x20000000,\n\t            0x15800: 0x1040080,\n\t            0x16800: 0x80,\n\t            0x17800: 0x21040000,\n\t            0x18800: 0x40080,\n\t            0x19800: 0x21040080,\n\t            0x1a800: 0x0,\n\t            0x1b800: 0x21000000,\n\t            0x1c800: 0x1000080,\n\t            0x1d800: 0x40000,\n\t            0x1e800: 0x20040000,\n\t            0x1f800: 0x20000080\n\t        },\n\t        {\n\t            0x0: 0x10000008,\n\t            0x100: 0x2000,\n\t            0x200: 0x10200000,\n\t            0x300: 0x10202008,\n\t            0x400: 0x10002000,\n\t            0x500: 0x200000,\n\t            0x600: 0x200008,\n\t            0x700: 0x10000000,\n\t            0x800: 0x0,\n\t            0x900: 0x10002008,\n\t            0xa00: 0x202000,\n\t            0xb00: 0x8,\n\t            0xc00: 0x10200008,\n\t            0xd00: 0x202008,\n\t            0xe00: 0x2008,\n\t            0xf00: 0x10202000,\n\t            0x80: 0x10200000,\n\t            0x180: 0x10202008,\n\t            0x280: 0x8,\n\t            0x380: 0x200000,\n\t            0x480: 0x202008,\n\t            0x580: 0x10000008,\n\t            0x680: 0x10002000,\n\t            0x780: 0x2008,\n\t            0x880: 0x200008,\n\t            0x980: 0x2000,\n\t            0xa80: 0x10002008,\n\t            0xb80: 0x10200008,\n\t            0xc80: 0x0,\n\t            0xd80: 0x10202000,\n\t            0xe80: 0x202000,\n\t            0xf80: 0x10000000,\n\t            0x1000: 0x10002000,\n\t            0x1100: 0x10200008,\n\t            0x1200: 0x10202008,\n\t            0x1300: 0x2008,\n\t            0x1400: 0x200000,\n\t            0x1500: 0x10000000,\n\t            0x1600: 0x10000008,\n\t            0x1700: 0x202000,\n\t            0x1800: 0x202008,\n\t            0x1900: 0x0,\n\t            0x1a00: 0x8,\n\t            0x1b00: 0x10200000,\n\t            0x1c00: 0x2000,\n\t            0x1d00: 0x10002008,\n\t            0x1e00: 0x10202000,\n\t            0x1f00: 0x200008,\n\t            0x1080: 0x8,\n\t            0x1180: 0x202000,\n\t            0x1280: 0x200000,\n\t            0x1380: 0x10000008,\n\t            0x1480: 0x10002000,\n\t            0x1580: 0x2008,\n\t            0x1680: 0x10202008,\n\t            0x1780: 0x10200000,\n\t            0x1880: 0x10202000,\n\t            0x1980: 0x10200008,\n\t            0x1a80: 0x2000,\n\t            0x1b80: 0x202008,\n\t            0x1c80: 0x200008,\n\t            0x1d80: 0x0,\n\t            0x1e80: 0x10000000,\n\t            0x1f80: 0x10002008\n\t        },\n\t        {\n\t            0x0: 0x100000,\n\t            0x10: 0x2000401,\n\t            0x20: 0x400,\n\t            0x30: 0x100401,\n\t            0x40: 0x2100401,\n\t            0x50: 0x0,\n\t            0x60: 0x1,\n\t            0x70: 0x2100001,\n\t            0x80: 0x2000400,\n\t            0x90: 0x100001,\n\t            0xa0: 0x2000001,\n\t            0xb0: 0x2100400,\n\t            0xc0: 0x2100000,\n\t            0xd0: 0x401,\n\t            0xe0: 0x100400,\n\t            0xf0: 0x2000000,\n\t            0x8: 0x2100001,\n\t            0x18: 0x0,\n\t            0x28: 0x2000401,\n\t            0x38: 0x2100400,\n\t            0x48: 0x100000,\n\t            0x58: 0x2000001,\n\t            0x68: 0x2000000,\n\t            0x78: 0x401,\n\t            0x88: 0x100401,\n\t            0x98: 0x2000400,\n\t            0xa8: 0x2100000,\n\t            0xb8: 0x100001,\n\t            0xc8: 0x400,\n\t            0xd8: 0x2100401,\n\t            0xe8: 0x1,\n\t            0xf8: 0x100400,\n\t            0x100: 0x2000000,\n\t            0x110: 0x100000,\n\t            0x120: 0x2000401,\n\t            0x130: 0x2100001,\n\t            0x140: 0x100001,\n\t            0x150: 0x2000400,\n\t            0x160: 0x2100400,\n\t            0x170: 0x100401,\n\t            0x180: 0x401,\n\t            0x190: 0x2100401,\n\t            0x1a0: 0x100400,\n\t            0x1b0: 0x1,\n\t            0x1c0: 0x0,\n\t            0x1d0: 0x2100000,\n\t            0x1e0: 0x2000001,\n\t            0x1f0: 0x400,\n\t            0x108: 0x100400,\n\t            0x118: 0x2000401,\n\t            0x128: 0x2100001,\n\t            0x138: 0x1,\n\t            0x148: 0x2000000,\n\t            0x158: 0x100000,\n\t            0x168: 0x401,\n\t            0x178: 0x2100400,\n\t            0x188: 0x2000001,\n\t            0x198: 0x2100000,\n\t            0x1a8: 0x0,\n\t            0x1b8: 0x2100401,\n\t            0x1c8: 0x100401,\n\t            0x1d8: 0x400,\n\t            0x1e8: 0x2000400,\n\t            0x1f8: 0x100001\n\t        },\n\t        {\n\t            0x0: 0x8000820,\n\t            0x1: 0x20000,\n\t            0x2: 0x8000000,\n\t            0x3: 0x20,\n\t            0x4: 0x20020,\n\t            0x5: 0x8020820,\n\t            0x6: 0x8020800,\n\t            0x7: 0x800,\n\t            0x8: 0x8020000,\n\t            0x9: 0x8000800,\n\t            0xa: 0x20800,\n\t            0xb: 0x8020020,\n\t            0xc: 0x820,\n\t            0xd: 0x0,\n\t            0xe: 0x8000020,\n\t            0xf: 0x20820,\n\t            0x80000000: 0x800,\n\t            0x80000001: 0x8020820,\n\t            0x80000002: 0x8000820,\n\t            0x80000003: 0x8000000,\n\t            0x80000004: 0x8020000,\n\t            0x80000005: 0x20800,\n\t            0x80000006: 0x20820,\n\t            0x80000007: 0x20,\n\t            0x80000008: 0x8000020,\n\t            0x80000009: 0x820,\n\t            0x8000000a: 0x20020,\n\t            0x8000000b: 0x8020800,\n\t            0x8000000c: 0x0,\n\t            0x8000000d: 0x8020020,\n\t            0x8000000e: 0x8000800,\n\t            0x8000000f: 0x20000,\n\t            0x10: 0x20820,\n\t            0x11: 0x8020800,\n\t            0x12: 0x20,\n\t            0x13: 0x800,\n\t            0x14: 0x8000800,\n\t            0x15: 0x8000020,\n\t            0x16: 0x8020020,\n\t            0x17: 0x20000,\n\t            0x18: 0x0,\n\t            0x19: 0x20020,\n\t            0x1a: 0x8020000,\n\t            0x1b: 0x8000820,\n\t            0x1c: 0x8020820,\n\t            0x1d: 0x20800,\n\t            0x1e: 0x820,\n\t            0x1f: 0x8000000,\n\t            0x80000010: 0x20000,\n\t            0x80000011: 0x800,\n\t            0x80000012: 0x8020020,\n\t            0x80000013: 0x20820,\n\t            0x80000014: 0x20,\n\t            0x80000015: 0x8020000,\n\t            0x80000016: 0x8000000,\n\t            0x80000017: 0x8000820,\n\t            0x80000018: 0x8020820,\n\t            0x80000019: 0x8000020,\n\t            0x8000001a: 0x8000800,\n\t            0x8000001b: 0x0,\n\t            0x8000001c: 0x20800,\n\t            0x8000001d: 0x820,\n\t            0x8000001e: 0x20020,\n\t            0x8000001f: 0x8020800\n\t        }\n\t    ];\n\n\t    // Masks that select the SBOX input\n\t    var SBOX_MASK = [\n\t        0xf8000001, 0x1f800000, 0x01f80000, 0x001f8000,\n\t        0x0001f800, 0x00001f80, 0x000001f8, 0x8000001f\n\t    ];\n\n\t    /**\n\t     * DES block cipher algorithm.\n\t     */\n\t    var DES = C_algo.DES = BlockCipher.extend({\n\t        _doReset: function () {\n\t            // Shortcuts\n\t            var key = this._key;\n\t            var keyWords = key.words;\n\n\t            // Select 56 bits according to PC1\n\t            var keyBits = [];\n\t            for (var i = 0; i < 56; i++) {\n\t                var keyBitPos = PC1[i] - 1;\n\t                keyBits[i] = (keyWords[keyBitPos >>> 5] >>> (31 - keyBitPos % 32)) & 1;\n\t            }\n\n\t            // Assemble 16 subkeys\n\t            var subKeys = this._subKeys = [];\n\t            for (var nSubKey = 0; nSubKey < 16; nSubKey++) {\n\t                // Create subkey\n\t                var subKey = subKeys[nSubKey] = [];\n\n\t                // Shortcut\n\t                var bitShift = BIT_SHIFTS[nSubKey];\n\n\t                // Select 48 bits according to PC2\n\t                for (var i = 0; i < 24; i++) {\n\t                    // Select from the left 28 key bits\n\t                    subKey[(i / 6) | 0] |= keyBits[((PC2[i] - 1) + bitShift) % 28] << (31 - i % 6);\n\n\t                    // Select from the right 28 key bits\n\t                    subKey[4 + ((i / 6) | 0)] |= keyBits[28 + (((PC2[i + 24] - 1) + bitShift) % 28)] << (31 - i % 6);\n\t                }\n\n\t                // Since each subkey is applied to an expanded 32-bit input,\n\t                // the subkey can be broken into 8 values scaled to 32-bits,\n\t                // which allows the key to be used without expansion\n\t                subKey[0] = (subKey[0] << 1) | (subKey[0] >>> 31);\n\t                for (var i = 1; i < 7; i++) {\n\t                    subKey[i] = subKey[i] >>> ((i - 1) * 4 + 3);\n\t                }\n\t                subKey[7] = (subKey[7] << 5) | (subKey[7] >>> 27);\n\t            }\n\n\t            // Compute inverse subkeys\n\t            var invSubKeys = this._invSubKeys = [];\n\t            for (var i = 0; i < 16; i++) {\n\t                invSubKeys[i] = subKeys[15 - i];\n\t            }\n\t        },\n\n\t        encryptBlock: function (M, offset) {\n\t            this._doCryptBlock(M, offset, this._subKeys);\n\t        },\n\n\t        decryptBlock: function (M, offset) {\n\t            this._doCryptBlock(M, offset, this._invSubKeys);\n\t        },\n\n\t        _doCryptBlock: function (M, offset, subKeys) {\n\t            // Get input\n\t            this._lBlock = M[offset];\n\t            this._rBlock = M[offset + 1];\n\n\t            // Initial permutation\n\t            exchangeLR.call(this, 4,  0x0f0f0f0f);\n\t            exchangeLR.call(this, 16, 0x0000ffff);\n\t            exchangeRL.call(this, 2,  0x33333333);\n\t            exchangeRL.call(this, 8,  0x00ff00ff);\n\t            exchangeLR.call(this, 1,  0x55555555);\n\n\t            // Rounds\n\t            for (var round = 0; round < 16; round++) {\n\t                // Shortcuts\n\t                var subKey = subKeys[round];\n\t                var lBlock = this._lBlock;\n\t                var rBlock = this._rBlock;\n\n\t                // Feistel function\n\t                var f = 0;\n\t                for (var i = 0; i < 8; i++) {\n\t                    f |= SBOX_P[i][((rBlock ^ subKey[i]) & SBOX_MASK[i]) >>> 0];\n\t                }\n\t                this._lBlock = rBlock;\n\t                this._rBlock = lBlock ^ f;\n\t            }\n\n\t            // Undo swap from last round\n\t            var t = this._lBlock;\n\t            this._lBlock = this._rBlock;\n\t            this._rBlock = t;\n\n\t            // Final permutation\n\t            exchangeLR.call(this, 1,  0x55555555);\n\t            exchangeRL.call(this, 8,  0x00ff00ff);\n\t            exchangeRL.call(this, 2,  0x33333333);\n\t            exchangeLR.call(this, 16, 0x0000ffff);\n\t            exchangeLR.call(this, 4,  0x0f0f0f0f);\n\n\t            // Set output\n\t            M[offset] = this._lBlock;\n\t            M[offset + 1] = this._rBlock;\n\t        },\n\n\t        keySize: 64/32,\n\n\t        ivSize: 64/32,\n\n\t        blockSize: 64/32\n\t    });\n\n\t    // Swap bits across the left and right words\n\t    function exchangeLR(offset, mask) {\n\t        var t = ((this._lBlock >>> offset) ^ this._rBlock) & mask;\n\t        this._rBlock ^= t;\n\t        this._lBlock ^= t << offset;\n\t    }\n\n\t    function exchangeRL(offset, mask) {\n\t        var t = ((this._rBlock >>> offset) ^ this._lBlock) & mask;\n\t        this._lBlock ^= t;\n\t        this._rBlock ^= t << offset;\n\t    }\n\n\t    /**\n\t     * Shortcut functions to the cipher's object interface.\n\t     *\n\t     * @example\n\t     *\n\t     *     var ciphertext = CryptoJS.DES.encrypt(message, key, cfg);\n\t     *     var plaintext  = CryptoJS.DES.decrypt(ciphertext, key, cfg);\n\t     */\n\t    C.DES = BlockCipher._createHelper(DES);\n\n\t    /**\n\t     * Triple-DES block cipher algorithm.\n\t     */\n\t    var TripleDES = C_algo.TripleDES = BlockCipher.extend({\n\t        _doReset: function () {\n\t            // Shortcuts\n\t            var key = this._key;\n\t            var keyWords = key.words;\n\n\t            // Create DES instances\n\t            this._des1 = DES.createEncryptor(WordArray.create(keyWords.slice(0, 2)));\n\t            this._des2 = DES.createEncryptor(WordArray.create(keyWords.slice(2, 4)));\n\t            this._des3 = DES.createEncryptor(WordArray.create(keyWords.slice(4, 6)));\n\t        },\n\n\t        encryptBlock: function (M, offset) {\n\t            this._des1.encryptBlock(M, offset);\n\t            this._des2.decryptBlock(M, offset);\n\t            this._des3.encryptBlock(M, offset);\n\t        },\n\n\t        decryptBlock: function (M, offset) {\n\t            this._des3.decryptBlock(M, offset);\n\t            this._des2.encryptBlock(M, offset);\n\t            this._des1.decryptBlock(M, offset);\n\t        },\n\n\t        keySize: 192/32,\n\n\t        ivSize: 64/32,\n\n\t        blockSize: 64/32\n\t    });\n\n\t    /**\n\t     * Shortcut functions to the cipher's object interface.\n\t     *\n\t     * @example\n\t     *\n\t     *     var ciphertext = CryptoJS.TripleDES.encrypt(message, key, cfg);\n\t     *     var plaintext  = CryptoJS.TripleDES.decrypt(ciphertext, key, cfg);\n\t     */\n\t    C.TripleDES = BlockCipher._createHelper(TripleDES);\n\t}());\n\n\n\treturn CryptoJS.TripleDES;\n\n}));\n\n/***/ }),\n/* 33 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory, undef) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0), __webpack_require__(3), __webpack_require__(4), __webpack_require__(2), __webpack_require__(1));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t(function () {\n\t    // Shortcuts\n\t    var C = CryptoJS;\n\t    var C_lib = C.lib;\n\t    var StreamCipher = C_lib.StreamCipher;\n\t    var C_algo = C.algo;\n\n\t    /**\n\t     * RC4 stream cipher algorithm.\n\t     */\n\t    var RC4 = C_algo.RC4 = StreamCipher.extend({\n\t        _doReset: function () {\n\t            // Shortcuts\n\t            var key = this._key;\n\t            var keyWords = key.words;\n\t            var keySigBytes = key.sigBytes;\n\n\t            // Init sbox\n\t            var S = this._S = [];\n\t            for (var i = 0; i < 256; i++) {\n\t                S[i] = i;\n\t            }\n\n\t            // Key setup\n\t            for (var i = 0, j = 0; i < 256; i++) {\n\t                var keyByteIndex = i % keySigBytes;\n\t                var keyByte = (keyWords[keyByteIndex >>> 2] >>> (24 - (keyByteIndex % 4) * 8)) & 0xff;\n\n\t                j = (j + S[i] + keyByte) % 256;\n\n\t                // Swap\n\t                var t = S[i];\n\t                S[i] = S[j];\n\t                S[j] = t;\n\t            }\n\n\t            // Counters\n\t            this._i = this._j = 0;\n\t        },\n\n\t        _doProcessBlock: function (M, offset) {\n\t            M[offset] ^= generateKeystreamWord.call(this);\n\t        },\n\n\t        keySize: 256/32,\n\n\t        ivSize: 0\n\t    });\n\n\t    function generateKeystreamWord() {\n\t        // Shortcuts\n\t        var S = this._S;\n\t        var i = this._i;\n\t        var j = this._j;\n\n\t        // Generate keystream word\n\t        var keystreamWord = 0;\n\t        for (var n = 0; n < 4; n++) {\n\t            i = (i + 1) % 256;\n\t            j = (j + S[i]) % 256;\n\n\t            // Swap\n\t            var t = S[i];\n\t            S[i] = S[j];\n\t            S[j] = t;\n\n\t            keystreamWord |= S[(S[i] + S[j]) % 256] << (24 - n * 8);\n\t        }\n\n\t        // Update counters\n\t        this._i = i;\n\t        this._j = j;\n\n\t        return keystreamWord;\n\t    }\n\n\t    /**\n\t     * Shortcut functions to the cipher's object interface.\n\t     *\n\t     * @example\n\t     *\n\t     *     var ciphertext = CryptoJS.RC4.encrypt(message, key, cfg);\n\t     *     var plaintext  = CryptoJS.RC4.decrypt(ciphertext, key, cfg);\n\t     */\n\t    C.RC4 = StreamCipher._createHelper(RC4);\n\n\t    /**\n\t     * Modified RC4 stream cipher algorithm.\n\t     */\n\t    var RC4Drop = C_algo.RC4Drop = RC4.extend({\n\t        /**\n\t         * Configuration options.\n\t         *\n\t         * @property {number} drop The number of keystream words to drop. Default 192\n\t         */\n\t        cfg: RC4.cfg.extend({\n\t            drop: 192\n\t        }),\n\n\t        _doReset: function () {\n\t            RC4._doReset.call(this);\n\n\t            // Drop\n\t            for (var i = this.cfg.drop; i > 0; i--) {\n\t                generateKeystreamWord.call(this);\n\t            }\n\t        }\n\t    });\n\n\t    /**\n\t     * Shortcut functions to the cipher's object interface.\n\t     *\n\t     * @example\n\t     *\n\t     *     var ciphertext = CryptoJS.RC4Drop.encrypt(message, key, cfg);\n\t     *     var plaintext  = CryptoJS.RC4Drop.decrypt(ciphertext, key, cfg);\n\t     */\n\t    C.RC4Drop = StreamCipher._createHelper(RC4Drop);\n\t}());\n\n\n\treturn CryptoJS.RC4;\n\n}));\n\n/***/ }),\n/* 34 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory, undef) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0), __webpack_require__(3), __webpack_require__(4), __webpack_require__(2), __webpack_require__(1));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t(function () {\n\t    // Shortcuts\n\t    var C = CryptoJS;\n\t    var C_lib = C.lib;\n\t    var StreamCipher = C_lib.StreamCipher;\n\t    var C_algo = C.algo;\n\n\t    // Reusable objects\n\t    var S  = [];\n\t    var C_ = [];\n\t    var G  = [];\n\n\t    /**\n\t     * Rabbit stream cipher algorithm\n\t     */\n\t    var Rabbit = C_algo.Rabbit = StreamCipher.extend({\n\t        _doReset: function () {\n\t            // Shortcuts\n\t            var K = this._key.words;\n\t            var iv = this.cfg.iv;\n\n\t            // Swap endian\n\t            for (var i = 0; i < 4; i++) {\n\t                K[i] = (((K[i] << 8)  | (K[i] >>> 24)) & 0x00ff00ff) |\n\t                       (((K[i] << 24) | (K[i] >>> 8))  & 0xff00ff00);\n\t            }\n\n\t            // Generate initial state values\n\t            var X = this._X = [\n\t                K[0], (K[3] << 16) | (K[2] >>> 16),\n\t                K[1], (K[0] << 16) | (K[3] >>> 16),\n\t                K[2], (K[1] << 16) | (K[0] >>> 16),\n\t                K[3], (K[2] << 16) | (K[1] >>> 16)\n\t            ];\n\n\t            // Generate initial counter values\n\t            var C = this._C = [\n\t                (K[2] << 16) | (K[2] >>> 16), (K[0] & 0xffff0000) | (K[1] & 0x0000ffff),\n\t                (K[3] << 16) | (K[3] >>> 16), (K[1] & 0xffff0000) | (K[2] & 0x0000ffff),\n\t                (K[0] << 16) | (K[0] >>> 16), (K[2] & 0xffff0000) | (K[3] & 0x0000ffff),\n\t                (K[1] << 16) | (K[1] >>> 16), (K[3] & 0xffff0000) | (K[0] & 0x0000ffff)\n\t            ];\n\n\t            // Carry bit\n\t            this._b = 0;\n\n\t            // Iterate the system four times\n\t            for (var i = 0; i < 4; i++) {\n\t                nextState.call(this);\n\t            }\n\n\t            // Modify the counters\n\t            for (var i = 0; i < 8; i++) {\n\t                C[i] ^= X[(i + 4) & 7];\n\t            }\n\n\t            // IV setup\n\t            if (iv) {\n\t                // Shortcuts\n\t                var IV = iv.words;\n\t                var IV_0 = IV[0];\n\t                var IV_1 = IV[1];\n\n\t                // Generate four subvectors\n\t                var i0 = (((IV_0 << 8) | (IV_0 >>> 24)) & 0x00ff00ff) | (((IV_0 << 24) | (IV_0 >>> 8)) & 0xff00ff00);\n\t                var i2 = (((IV_1 << 8) | (IV_1 >>> 24)) & 0x00ff00ff) | (((IV_1 << 24) | (IV_1 >>> 8)) & 0xff00ff00);\n\t                var i1 = (i0 >>> 16) | (i2 & 0xffff0000);\n\t                var i3 = (i2 << 16)  | (i0 & 0x0000ffff);\n\n\t                // Modify counter values\n\t                C[0] ^= i0;\n\t                C[1] ^= i1;\n\t                C[2] ^= i2;\n\t                C[3] ^= i3;\n\t                C[4] ^= i0;\n\t                C[5] ^= i1;\n\t                C[6] ^= i2;\n\t                C[7] ^= i3;\n\n\t                // Iterate the system four times\n\t                for (var i = 0; i < 4; i++) {\n\t                    nextState.call(this);\n\t                }\n\t            }\n\t        },\n\n\t        _doProcessBlock: function (M, offset) {\n\t            // Shortcut\n\t            var X = this._X;\n\n\t            // Iterate the system\n\t            nextState.call(this);\n\n\t            // Generate four keystream words\n\t            S[0] = X[0] ^ (X[5] >>> 16) ^ (X[3] << 16);\n\t            S[1] = X[2] ^ (X[7] >>> 16) ^ (X[5] << 16);\n\t            S[2] = X[4] ^ (X[1] >>> 16) ^ (X[7] << 16);\n\t            S[3] = X[6] ^ (X[3] >>> 16) ^ (X[1] << 16);\n\n\t            for (var i = 0; i < 4; i++) {\n\t                // Swap endian\n\t                S[i] = (((S[i] << 8)  | (S[i] >>> 24)) & 0x00ff00ff) |\n\t                       (((S[i] << 24) | (S[i] >>> 8))  & 0xff00ff00);\n\n\t                // Encrypt\n\t                M[offset + i] ^= S[i];\n\t            }\n\t        },\n\n\t        blockSize: 128/32,\n\n\t        ivSize: 64/32\n\t    });\n\n\t    function nextState() {\n\t        // Shortcuts\n\t        var X = this._X;\n\t        var C = this._C;\n\n\t        // Save old counter values\n\t        for (var i = 0; i < 8; i++) {\n\t            C_[i] = C[i];\n\t        }\n\n\t        // Calculate new counter values\n\t        C[0] = (C[0] + 0x4d34d34d + this._b) | 0;\n\t        C[1] = (C[1] + 0xd34d34d3 + ((C[0] >>> 0) < (C_[0] >>> 0) ? 1 : 0)) | 0;\n\t        C[2] = (C[2] + 0x34d34d34 + ((C[1] >>> 0) < (C_[1] >>> 0) ? 1 : 0)) | 0;\n\t        C[3] = (C[3] + 0x4d34d34d + ((C[2] >>> 0) < (C_[2] >>> 0) ? 1 : 0)) | 0;\n\t        C[4] = (C[4] + 0xd34d34d3 + ((C[3] >>> 0) < (C_[3] >>> 0) ? 1 : 0)) | 0;\n\t        C[5] = (C[5] + 0x34d34d34 + ((C[4] >>> 0) < (C_[4] >>> 0) ? 1 : 0)) | 0;\n\t        C[6] = (C[6] + 0x4d34d34d + ((C[5] >>> 0) < (C_[5] >>> 0) ? 1 : 0)) | 0;\n\t        C[7] = (C[7] + 0xd34d34d3 + ((C[6] >>> 0) < (C_[6] >>> 0) ? 1 : 0)) | 0;\n\t        this._b = (C[7] >>> 0) < (C_[7] >>> 0) ? 1 : 0;\n\n\t        // Calculate the g-values\n\t        for (var i = 0; i < 8; i++) {\n\t            var gx = X[i] + C[i];\n\n\t            // Construct high and low argument for squaring\n\t            var ga = gx & 0xffff;\n\t            var gb = gx >>> 16;\n\n\t            // Calculate high and low result of squaring\n\t            var gh = ((((ga * ga) >>> 17) + ga * gb) >>> 15) + gb * gb;\n\t            var gl = (((gx & 0xffff0000) * gx) | 0) + (((gx & 0x0000ffff) * gx) | 0);\n\n\t            // High XOR low\n\t            G[i] = gh ^ gl;\n\t        }\n\n\t        // Calculate new state values\n\t        X[0] = (G[0] + ((G[7] << 16) | (G[7] >>> 16)) + ((G[6] << 16) | (G[6] >>> 16))) | 0;\n\t        X[1] = (G[1] + ((G[0] << 8)  | (G[0] >>> 24)) + G[7]) | 0;\n\t        X[2] = (G[2] + ((G[1] << 16) | (G[1] >>> 16)) + ((G[0] << 16) | (G[0] >>> 16))) | 0;\n\t        X[3] = (G[3] + ((G[2] << 8)  | (G[2] >>> 24)) + G[1]) | 0;\n\t        X[4] = (G[4] + ((G[3] << 16) | (G[3] >>> 16)) + ((G[2] << 16) | (G[2] >>> 16))) | 0;\n\t        X[5] = (G[5] + ((G[4] << 8)  | (G[4] >>> 24)) + G[3]) | 0;\n\t        X[6] = (G[6] + ((G[5] << 16) | (G[5] >>> 16)) + ((G[4] << 16) | (G[4] >>> 16))) | 0;\n\t        X[7] = (G[7] + ((G[6] << 8)  | (G[6] >>> 24)) + G[5]) | 0;\n\t    }\n\n\t    /**\n\t     * Shortcut functions to the cipher's object interface.\n\t     *\n\t     * @example\n\t     *\n\t     *     var ciphertext = CryptoJS.Rabbit.encrypt(message, key, cfg);\n\t     *     var plaintext  = CryptoJS.Rabbit.decrypt(ciphertext, key, cfg);\n\t     */\n\t    C.Rabbit = StreamCipher._createHelper(Rabbit);\n\t}());\n\n\n\treturn CryptoJS.Rabbit;\n\n}));\n\n/***/ }),\n/* 35 */\n/***/ (function(module, exports, __webpack_require__) {\n\n;(function (root, factory, undef) {\n\tif (true) {\n\t\t// CommonJS\n\t\tmodule.exports = exports = factory(__webpack_require__(0), __webpack_require__(3), __webpack_require__(4), __webpack_require__(2), __webpack_require__(1));\n\t}\n\telse {}\n}(this, function (CryptoJS) {\n\n\t(function () {\n\t    // Shortcuts\n\t    var C = CryptoJS;\n\t    var C_lib = C.lib;\n\t    var StreamCipher = C_lib.StreamCipher;\n\t    var C_algo = C.algo;\n\n\t    // Reusable objects\n\t    var S  = [];\n\t    var C_ = [];\n\t    var G  = [];\n\n\t    /**\n\t     * Rabbit stream cipher algorithm.\n\t     *\n\t     * This is a legacy version that neglected to convert the key to little-endian.\n\t     * This error doesn't affect the cipher's security,\n\t     * but it does affect its compatibility with other implementations.\n\t     */\n\t    var RabbitLegacy = C_algo.RabbitLegacy = StreamCipher.extend({\n\t        _doReset: function () {\n\t            // Shortcuts\n\t            var K = this._key.words;\n\t            var iv = this.cfg.iv;\n\n\t            // Generate initial state values\n\t            var X = this._X = [\n\t                K[0], (K[3] << 16) | (K[2] >>> 16),\n\t                K[1], (K[0] << 16) | (K[3] >>> 16),\n\t                K[2], (K[1] << 16) | (K[0] >>> 16),\n\t                K[3], (K[2] << 16) | (K[1] >>> 16)\n\t            ];\n\n\t            // Generate initial counter values\n\t            var C = this._C = [\n\t                (K[2] << 16) | (K[2] >>> 16), (K[0] & 0xffff0000) | (K[1] & 0x0000ffff),\n\t                (K[3] << 16) | (K[3] >>> 16), (K[1] & 0xffff0000) | (K[2] & 0x0000ffff),\n\t                (K[0] << 16) | (K[0] >>> 16), (K[2] & 0xffff0000) | (K[3] & 0x0000ffff),\n\t                (K[1] << 16) | (K[1] >>> 16), (K[3] & 0xffff0000) | (K[0] & 0x0000ffff)\n\t            ];\n\n\t            // Carry bit\n\t            this._b = 0;\n\n\t            // Iterate the system four times\n\t            for (var i = 0; i < 4; i++) {\n\t                nextState.call(this);\n\t            }\n\n\t            // Modify the counters\n\t            for (var i = 0; i < 8; i++) {\n\t                C[i] ^= X[(i + 4) & 7];\n\t            }\n\n\t            // IV setup\n\t            if (iv) {\n\t                // Shortcuts\n\t                var IV = iv.words;\n\t                var IV_0 = IV[0];\n\t                var IV_1 = IV[1];\n\n\t                // Generate four subvectors\n\t                var i0 = (((IV_0 << 8) | (IV_0 >>> 24)) & 0x00ff00ff) | (((IV_0 << 24) | (IV_0 >>> 8)) & 0xff00ff00);\n\t                var i2 = (((IV_1 << 8) | (IV_1 >>> 24)) & 0x00ff00ff) | (((IV_1 << 24) | (IV_1 >>> 8)) & 0xff00ff00);\n\t                var i1 = (i0 >>> 16) | (i2 & 0xffff0000);\n\t                var i3 = (i2 << 16)  | (i0 & 0x0000ffff);\n\n\t                // Modify counter values\n\t                C[0] ^= i0;\n\t                C[1] ^= i1;\n\t                C[2] ^= i2;\n\t                C[3] ^= i3;\n\t                C[4] ^= i0;\n\t                C[5] ^= i1;\n\t                C[6] ^= i2;\n\t                C[7] ^= i3;\n\n\t                // Iterate the system four times\n\t                for (var i = 0; i < 4; i++) {\n\t                    nextState.call(this);\n\t                }\n\t            }\n\t        },\n\n\t        _doProcessBlock: function (M, offset) {\n\t            // Shortcut\n\t            var X = this._X;\n\n\t            // Iterate the system\n\t            nextState.call(this);\n\n\t            // Generate four keystream words\n\t            S[0] = X[0] ^ (X[5] >>> 16) ^ (X[3] << 16);\n\t            S[1] = X[2] ^ (X[7] >>> 16) ^ (X[5] << 16);\n\t            S[2] = X[4] ^ (X[1] >>> 16) ^ (X[7] << 16);\n\t            S[3] = X[6] ^ (X[3] >>> 16) ^ (X[1] << 16);\n\n\t            for (var i = 0; i < 4; i++) {\n\t                // Swap endian\n\t                S[i] = (((S[i] << 8)  | (S[i] >>> 24)) & 0x00ff00ff) |\n\t                       (((S[i] << 24) | (S[i] >>> 8))  & 0xff00ff00);\n\n\t                // Encrypt\n\t                M[offset + i] ^= S[i];\n\t            }\n\t        },\n\n\t        blockSize: 128/32,\n\n\t        ivSize: 64/32\n\t    });\n\n\t    function nextState() {\n\t        // Shortcuts\n\t        var X = this._X;\n\t        var C = this._C;\n\n\t        // Save old counter values\n\t        for (var i = 0; i < 8; i++) {\n\t            C_[i] = C[i];\n\t        }\n\n\t        // Calculate new counter values\n\t        C[0] = (C[0] + 0x4d34d34d + this._b) | 0;\n\t        C[1] = (C[1] + 0xd34d34d3 + ((C[0] >>> 0) < (C_[0] >>> 0) ? 1 : 0)) | 0;\n\t        C[2] = (C[2] + 0x34d34d34 + ((C[1] >>> 0) < (C_[1] >>> 0) ? 1 : 0)) | 0;\n\t        C[3] = (C[3] + 0x4d34d34d + ((C[2] >>> 0) < (C_[2] >>> 0) ? 1 : 0)) | 0;\n\t        C[4] = (C[4] + 0xd34d34d3 + ((C[3] >>> 0) < (C_[3] >>> 0) ? 1 : 0)) | 0;\n\t        C[5] = (C[5] + 0x34d34d34 + ((C[4] >>> 0) < (C_[4] >>> 0) ? 1 : 0)) | 0;\n\t        C[6] = (C[6] + 0x4d34d34d + ((C[5] >>> 0) < (C_[5] >>> 0) ? 1 : 0)) | 0;\n\t        C[7] = (C[7] + 0xd34d34d3 + ((C[6] >>> 0) < (C_[6] >>> 0) ? 1 : 0)) | 0;\n\t        this._b = (C[7] >>> 0) < (C_[7] >>> 0) ? 1 : 0;\n\n\t        // Calculate the g-values\n\t        for (var i = 0; i < 8; i++) {\n\t            var gx = X[i] + C[i];\n\n\t            // Construct high and low argument for squaring\n\t            var ga = gx & 0xffff;\n\t            var gb = gx >>> 16;\n\n\t            // Calculate high and low result of squaring\n\t            var gh = ((((ga * ga) >>> 17) + ga * gb) >>> 15) + gb * gb;\n\t            var gl = (((gx & 0xffff0000) * gx) | 0) + (((gx & 0x0000ffff) * gx) | 0);\n\n\t            // High XOR low\n\t            G[i] = gh ^ gl;\n\t        }\n\n\t        // Calculate new state values\n\t        X[0] = (G[0] + ((G[7] << 16) | (G[7] >>> 16)) + ((G[6] << 16) | (G[6] >>> 16))) | 0;\n\t        X[1] = (G[1] + ((G[0] << 8)  | (G[0] >>> 24)) + G[7]) | 0;\n\t        X[2] = (G[2] + ((G[1] << 16) | (G[1] >>> 16)) + ((G[0] << 16) | (G[0] >>> 16))) | 0;\n\t        X[3] = (G[3] + ((G[2] << 8)  | (G[2] >>> 24)) + G[1]) | 0;\n\t        X[4] = (G[4] + ((G[3] << 16) | (G[3] >>> 16)) + ((G[2] << 16) | (G[2] >>> 16))) | 0;\n\t        X[5] = (G[5] + ((G[4] << 8)  | (G[4] >>> 24)) + G[3]) | 0;\n\t        X[6] = (G[6] + ((G[5] << 16) | (G[5] >>> 16)) + ((G[4] << 16) | (G[4] >>> 16))) | 0;\n\t        X[7] = (G[7] + ((G[6] << 8)  | (G[6] >>> 24)) + G[5]) | 0;\n\t    }\n\n\t    /**\n\t     * Shortcut functions to the cipher's object interface.\n\t     *\n\t     * @example\n\t     *\n\t     *     var ciphertext = CryptoJS.RabbitLegacy.encrypt(message, key, cfg);\n\t     *     var plaintext  = CryptoJS.RabbitLegacy.decrypt(ciphertext, key, cfg);\n\t     */\n\t    C.RabbitLegacy = StreamCipher._createHelper(RabbitLegacy);\n\t}());\n\n\n\treturn CryptoJS.RabbitLegacy;\n\n}));\n\n/***/ }),\n/* 36 */\n/***/ (function(module, exports, __webpack_require__) {\n\n/* WEBPACK VAR INJECTION */(function(global) {var __WEBPACK_AMD_DEFINE_ARRAY__, __WEBPACK_AMD_DEFINE_RESULT__;/*\n *  base64.js\n *\n *  Licensed under the BSD 3-Clause License.\n *    http://opensource.org/licenses/BSD-3-Clause\n *\n *  References:\n *    http://en.wikipedia.org/wiki/Base64\n */\n;(function (global, factory) {\n     true\n        ? module.exports = factory(global)\n        : undefined\n}((\n    typeof self !== 'undefined' ? self\n        : typeof window !== 'undefined' ? window\n        : typeof global !== 'undefined' ? global\n: this\n), function(global) {\n    'use strict';\n    // existing version for noConflict()\n    var _Base64 = global.Base64;\n    var version = \"2.4.3\";\n    // if node.js, we use Buffer\n    var buffer;\n    if (typeof module !== 'undefined' && module.exports) {\n        try {\n            buffer = __webpack_require__(37).Buffer;\n        } catch (err) {}\n    }\n    // constants\n    var b64chars\n        = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';\n    var b64tab = function(bin) {\n        var t = {};\n        for (var i = 0, l = bin.length; i < l; i++) t[bin.charAt(i)] = i;\n        return t;\n    }(b64chars);\n    var fromCharCode = String.fromCharCode;\n    // encoder stuff\n    var cb_utob = function(c) {\n        if (c.length < 2) {\n            var cc = c.charCodeAt(0);\n            return cc < 0x80 ? c\n                : cc < 0x800 ? (fromCharCode(0xc0 | (cc >>> 6))\n                                + fromCharCode(0x80 | (cc & 0x3f)))\n                : (fromCharCode(0xe0 | ((cc >>> 12) & 0x0f))\n                   + fromCharCode(0x80 | ((cc >>>  6) & 0x3f))\n                   + fromCharCode(0x80 | ( cc         & 0x3f)));\n        } else {\n            var cc = 0x10000\n                + (c.charCodeAt(0) - 0xD800) * 0x400\n                + (c.charCodeAt(1) - 0xDC00);\n            return (fromCharCode(0xf0 | ((cc >>> 18) & 0x07))\n                    + fromCharCode(0x80 | ((cc >>> 12) & 0x3f))\n                    + fromCharCode(0x80 | ((cc >>>  6) & 0x3f))\n                    + fromCharCode(0x80 | ( cc         & 0x3f)));\n        }\n    };\n    var re_utob = /[\\uD800-\\uDBFF][\\uDC00-\\uDFFFF]|[^\\x00-\\x7F]/g;\n    var utob = function(u) {\n        return u.replace(re_utob, cb_utob);\n    };\n    var cb_encode = function(ccc) {\n        var padlen = [0, 2, 1][ccc.length % 3],\n        ord = ccc.charCodeAt(0) << 16\n            | ((ccc.length > 1 ? ccc.charCodeAt(1) : 0) << 8)\n            | ((ccc.length > 2 ? ccc.charCodeAt(2) : 0)),\n        chars = [\n            b64chars.charAt( ord >>> 18),\n            b64chars.charAt((ord >>> 12) & 63),\n            padlen >= 2 ? '=' : b64chars.charAt((ord >>> 6) & 63),\n            padlen >= 1 ? '=' : b64chars.charAt(ord & 63)\n        ];\n        return chars.join('');\n    };\n    var btoa = global.btoa ? function(b) {\n        return global.btoa(b);\n    } : function(b) {\n        return b.replace(/[\\s\\S]{1,3}/g, cb_encode);\n    };\n    var _encode = buffer ?\n        buffer.from && buffer.from !== Uint8Array.from ? function (u) {\n            return (u.constructor === buffer.constructor ? u : buffer.from(u))\n                .toString('base64')\n        }\n        :  function (u) {\n            return (u.constructor === buffer.constructor ? u : new  buffer(u))\n                .toString('base64')\n        }\n        : function (u) { return btoa(utob(u)) }\n    ;\n    var encode = function(u, urisafe) {\n        return !urisafe\n            ? _encode(String(u))\n            : _encode(String(u)).replace(/[+\\/]/g, function(m0) {\n                return m0 == '+' ? '-' : '_';\n            }).replace(/=/g, '');\n    };\n    var encodeURI = function(u) { return encode(u, true) };\n    // decoder stuff\n    var re_btou = new RegExp([\n        '[\\xC0-\\xDF][\\x80-\\xBF]',\n        '[\\xE0-\\xEF][\\x80-\\xBF]{2}',\n        '[\\xF0-\\xF7][\\x80-\\xBF]{3}'\n    ].join('|'), 'g');\n    var cb_btou = function(cccc) {\n        switch(cccc.length) {\n        case 4:\n            var cp = ((0x07 & cccc.charCodeAt(0)) << 18)\n                |    ((0x3f & cccc.charCodeAt(1)) << 12)\n                |    ((0x3f & cccc.charCodeAt(2)) <<  6)\n                |     (0x3f & cccc.charCodeAt(3)),\n            offset = cp - 0x10000;\n            return (fromCharCode((offset  >>> 10) + 0xD800)\n                    + fromCharCode((offset & 0x3FF) + 0xDC00));\n        case 3:\n            return fromCharCode(\n                ((0x0f & cccc.charCodeAt(0)) << 12)\n                    | ((0x3f & cccc.charCodeAt(1)) << 6)\n                    |  (0x3f & cccc.charCodeAt(2))\n            );\n        default:\n            return  fromCharCode(\n                ((0x1f & cccc.charCodeAt(0)) << 6)\n                    |  (0x3f & cccc.charCodeAt(1))\n            );\n        }\n    };\n    var btou = function(b) {\n        return b.replace(re_btou, cb_btou);\n    };\n    var cb_decode = function(cccc) {\n        var len = cccc.length,\n        padlen = len % 4,\n        n = (len > 0 ? b64tab[cccc.charAt(0)] << 18 : 0)\n            | (len > 1 ? b64tab[cccc.charAt(1)] << 12 : 0)\n            | (len > 2 ? b64tab[cccc.charAt(2)] <<  6 : 0)\n            | (len > 3 ? b64tab[cccc.charAt(3)]       : 0),\n        chars = [\n            fromCharCode( n >>> 16),\n            fromCharCode((n >>>  8) & 0xff),\n            fromCharCode( n         & 0xff)\n        ];\n        chars.length -= [0, 0, 2, 1][padlen];\n        return chars.join('');\n    };\n    var atob = global.atob ? function(a) {\n        return global.atob(a);\n    } : function(a){\n        return a.replace(/[\\s\\S]{1,4}/g, cb_decode);\n    };\n    var _decode = buffer ?\n        buffer.from && buffer.from !== Uint8Array.from ? function(a) {\n            return (a.constructor === buffer.constructor\n                    ? a : buffer.from(a, 'base64')).toString();\n        }\n        : function(a) {\n            return (a.constructor === buffer.constructor\n                    ? a : new buffer(a, 'base64')).toString();\n        }\n        : function(a) { return btou(atob(a)) };\n    var decode = function(a){\n        return _decode(\n            String(a).replace(/[-_]/g, function(m0) { return m0 == '-' ? '+' : '/' })\n                .replace(/[^A-Za-z0-9\\+\\/]/g, '')\n        );\n    };\n    var noConflict = function() {\n        var Base64 = global.Base64;\n        global.Base64 = _Base64;\n        return Base64;\n    };\n    // export Base64\n    global.Base64 = {\n        VERSION: version,\n        atob: atob,\n        btoa: btoa,\n        fromBase64: decode,\n        toBase64: encode,\n        utob: utob,\n        encode: encode,\n        encodeURI: encodeURI,\n        btou: btou,\n        decode: decode,\n        noConflict: noConflict\n    };\n    // if ES5 is available, make Base64.extendString() available\n    if (typeof Object.defineProperty === 'function') {\n        var noEnum = function(v){\n            return {value:v,enumerable:false,writable:true,configurable:true};\n        };\n        global.Base64.extendString = function () {\n            Object.defineProperty(\n                String.prototype, 'fromBase64', noEnum(function () {\n                    return decode(this)\n                }));\n            Object.defineProperty(\n                String.prototype, 'toBase64', noEnum(function (urisafe) {\n                    return encode(this, urisafe)\n                }));\n            Object.defineProperty(\n                String.prototype, 'toBase64URI', noEnum(function () {\n                    return encode(this, true)\n                }));\n        };\n    }\n    //\n    // export Base64 to the namespace\n    //\n    if (global['Meteor']) { // Meteor.js\n        Base64 = global.Base64;\n    }\n    // module.exports and AMD are mutually exclusive.\n    // module.exports has precedence.\n    if (typeof module !== 'undefined' && module.exports) {\n        module.exports.Base64 = global.Base64;\n    }\n    else if (true) {\n        // AMD. Register as an anonymous module.\n        !(__WEBPACK_AMD_DEFINE_ARRAY__ = [], __WEBPACK_AMD_DEFINE_RESULT__ = (function(){ return global.Base64 }).apply(exports, __WEBPACK_AMD_DEFINE_ARRAY__),\n\t\t\t\t__WEBPACK_AMD_DEFINE_RESULT__ !== undefined && (module.exports = __WEBPACK_AMD_DEFINE_RESULT__));\n    }\n    // that's it!\n    return {Base64: global.Base64}\n}));\n\n/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(8)))\n\n/***/ }),\n/* 37 */\n/***/ (function(module, exports, __webpack_require__) {\n\n\"use strict\";\n/* WEBPACK VAR INJECTION */(function(global) {/*!\n * The buffer module from node.js, for the browser.\n *\n * @author   Feross Aboukhadijeh <feross@feross.org> <http://feross.org>\n * @license  MIT\n */\n/* eslint-disable no-proto */\n\n\n\nvar base64 = __webpack_require__(38)\nvar ieee754 = __webpack_require__(39)\nvar isArray = __webpack_require__(40)\n\nexports.Buffer = Buffer\nexports.SlowBuffer = SlowBuffer\nexports.INSPECT_MAX_BYTES = 50\n\n/**\n * If `Buffer.TYPED_ARRAY_SUPPORT`:\n *   === true    Use Uint8Array implementation (fastest)\n *   === false   Use Object implementation (most compatible, even IE6)\n *\n * Browsers that support typed arrays are IE 10+, Firefox 4+, Chrome 7+, Safari 5.1+,\n * Opera 11.6+, iOS 4.2+.\n *\n * Due to various browser bugs, sometimes the Object implementation will be used even\n * when the browser supports typed arrays.\n *\n * Note:\n *\n *   - Firefox 4-29 lacks support for adding new properties to `Uint8Array` instances,\n *     See: https://bugzilla.mozilla.org/show_bug.cgi?id=695438.\n *\n *   - Chrome 9-10 is missing the `TypedArray.prototype.subarray` function.\n *\n *   - IE10 has a broken `TypedArray.prototype.subarray` function which returns arrays of\n *     incorrect length in some situations.\n\n * We detect these buggy browsers and set `Buffer.TYPED_ARRAY_SUPPORT` to `false` so they\n * get the Object implementation, which is slower but behaves correctly.\n */\nBuffer.TYPED_ARRAY_SUPPORT = global.TYPED_ARRAY_SUPPORT !== undefined\n  ? global.TYPED_ARRAY_SUPPORT\n  : typedArraySupport()\n\n/*\n * Export kMaxLength after typed array support is determined.\n */\nexports.kMaxLength = kMaxLength()\n\nfunction typedArraySupport () {\n  try {\n    var arr = new Uint8Array(1)\n    arr.__proto__ = {__proto__: Uint8Array.prototype, foo: function () { return 42 }}\n    return arr.foo() === 42 && // typed array instances can be augmented\n        typeof arr.subarray === 'function' && // chrome 9-10 lack `subarray`\n        arr.subarray(1, 1).byteLength === 0 // ie10 has broken `subarray`\n  } catch (e) {\n    return false\n  }\n}\n\nfunction kMaxLength () {\n  return Buffer.TYPED_ARRAY_SUPPORT\n    ? 0x7fffffff\n    : 0x3fffffff\n}\n\nfunction createBuffer (that, length) {\n  if (kMaxLength() < length) {\n    throw new RangeError('Invalid typed array length')\n  }\n  if (Buffer.TYPED_ARRAY_SUPPORT) {\n    // Return an augmented `Uint8Array` instance, for best performance\n    that = new Uint8Array(length)\n    that.__proto__ = Buffer.prototype\n  } else {\n    // Fallback: Return an object instance of the Buffer class\n    if (that === null) {\n      that = new Buffer(length)\n    }\n    that.length = length\n  }\n\n  return that\n}\n\n/**\n * The Buffer constructor returns instances of `Uint8Array` that have their\n * prototype changed to `Buffer.prototype`. Furthermore, `Buffer` is a subclass of\n * `Uint8Array`, so the returned instances will have all the node `Buffer` methods\n * and the `Uint8Array` methods. Square bracket notation works as expected -- it\n * returns a single octet.\n *\n * The `Uint8Array` prototype remains unmodified.\n */\n\nfunction Buffer (arg, encodingOrOffset, length) {\n  if (!Buffer.TYPED_ARRAY_SUPPORT && !(this instanceof Buffer)) {\n    return new Buffer(arg, encodingOrOffset, length)\n  }\n\n  // Common case.\n  if (typeof arg === 'number') {\n    if (typeof encodingOrOffset === 'string') {\n      throw new Error(\n        'If encoding is specified then the first argument must be a string'\n      )\n    }\n    return allocUnsafe(this, arg)\n  }\n  return from(this, arg, encodingOrOffset, length)\n}\n\nBuffer.poolSize = 8192 // not used by this implementation\n\n// TODO: Legacy, not needed anymore. Remove in next major version.\nBuffer._augment = function (arr) {\n  arr.__proto__ = Buffer.prototype\n  return arr\n}\n\nfunction from (that, value, encodingOrOffset, length) {\n  if (typeof value === 'number') {\n    throw new TypeError('\"value\" argument must not be a number')\n  }\n\n  if (typeof ArrayBuffer !== 'undefined' && value instanceof ArrayBuffer) {\n    return fromArrayBuffer(that, value, encodingOrOffset, length)\n  }\n\n  if (typeof value === 'string') {\n    return fromString(that, value, encodingOrOffset)\n  }\n\n  return fromObject(that, value)\n}\n\n/**\n * Functionally equivalent to Buffer(arg, encoding) but throws a TypeError\n * if value is a number.\n * Buffer.from(str[, encoding])\n * Buffer.from(array)\n * Buffer.from(buffer)\n * Buffer.from(arrayBuffer[, byteOffset[, length]])\n **/\nBuffer.from = function (value, encodingOrOffset, length) {\n  return from(null, value, encodingOrOffset, length)\n}\n\nif (Buffer.TYPED_ARRAY_SUPPORT) {\n  Buffer.prototype.__proto__ = Uint8Array.prototype\n  Buffer.__proto__ = Uint8Array\n  if (typeof Symbol !== 'undefined' && Symbol.species &&\n      Buffer[Symbol.species] === Buffer) {\n    // Fix subarray() in ES2016. See: https://github.com/feross/buffer/pull/97\n    Object.defineProperty(Buffer, Symbol.species, {\n      value: null,\n      configurable: true\n    })\n  }\n}\n\nfunction assertSize (size) {\n  if (typeof size !== 'number') {\n    throw new TypeError('\"size\" argument must be a number')\n  } else if (size < 0) {\n    throw new RangeError('\"size\" argument must not be negative')\n  }\n}\n\nfunction alloc (that, size, fill, encoding) {\n  assertSize(size)\n  if (size <= 0) {\n    return createBuffer(that, size)\n  }\n  if (fill !== undefined) {\n    // Only pay attention to encoding if it's a string. This\n    // prevents accidentally sending in a number that would\n    // be interpretted as a start offset.\n    return typeof encoding === 'string'\n      ? createBuffer(that, size).fill(fill, encoding)\n      : createBuffer(that, size).fill(fill)\n  }\n  return createBuffer(that, size)\n}\n\n/**\n * Creates a new filled Buffer instance.\n * alloc(size[, fill[, encoding]])\n **/\nBuffer.alloc = function (size, fill, encoding) {\n  return alloc(null, size, fill, encoding)\n}\n\nfunction allocUnsafe (that, size) {\n  assertSize(size)\n  that = createBuffer(that, size < 0 ? 0 : checked(size) | 0)\n  if (!Buffer.TYPED_ARRAY_SUPPORT) {\n    for (var i = 0; i < size; ++i) {\n      that[i] = 0\n    }\n  }\n  return that\n}\n\n/**\n * Equivalent to Buffer(num), by default creates a non-zero-filled Buffer instance.\n * */\nBuffer.allocUnsafe = function (size) {\n  return allocUnsafe(null, size)\n}\n/**\n * Equivalent to SlowBuffer(num), by default creates a non-zero-filled Buffer instance.\n */\nBuffer.allocUnsafeSlow = function (size) {\n  return allocUnsafe(null, size)\n}\n\nfunction fromString (that, string, encoding) {\n  if (typeof encoding !== 'string' || encoding === '') {\n    encoding = 'utf8'\n  }\n\n  if (!Buffer.isEncoding(encoding)) {\n    throw new TypeError('\"encoding\" must be a valid string encoding')\n  }\n\n  var length = byteLength(string, encoding) | 0\n  that = createBuffer(that, length)\n\n  var actual = that.write(string, encoding)\n\n  if (actual !== length) {\n    // Writing a hex string, for example, that contains invalid characters will\n    // cause everything after the first invalid character to be ignored. (e.g.\n    // 'abxxcd' will be treated as 'ab')\n    that = that.slice(0, actual)\n  }\n\n  return that\n}\n\nfunction fromArrayLike (that, array) {\n  var length = array.length < 0 ? 0 : checked(array.length) | 0\n  that = createBuffer(that, length)\n  for (var i = 0; i < length; i += 1) {\n    that[i] = array[i] & 255\n  }\n  return that\n}\n\nfunction fromArrayBuffer (that, array, byteOffset, length) {\n  array.byteLength // this throws if `array` is not a valid ArrayBuffer\n\n  if (byteOffset < 0 || array.byteLength < byteOffset) {\n    throw new RangeError('\\'offset\\' is out of bounds')\n  }\n\n  if (array.byteLength < byteOffset + (length || 0)) {\n    throw new RangeError('\\'length\\' is out of bounds')\n  }\n\n  if (byteOffset === undefined && length === undefined) {\n    array = new Uint8Array(array)\n  } else if (length === undefined) {\n    array = new Uint8Array(array, byteOffset)\n  } else {\n    array = new Uint8Array(array, byteOffset, length)\n  }\n\n  if (Buffer.TYPED_ARRAY_SUPPORT) {\n    // Return an augmented `Uint8Array` instance, for best performance\n    that = array\n    that.__proto__ = Buffer.prototype\n  } else {\n    // Fallback: Return an object instance of the Buffer class\n    that = fromArrayLike(that, array)\n  }\n  return that\n}\n\nfunction fromObject (that, obj) {\n  if (Buffer.isBuffer(obj)) {\n    var len = checked(obj.length) | 0\n    that = createBuffer(that, len)\n\n    if (that.length === 0) {\n      return that\n    }\n\n    obj.copy(that, 0, 0, len)\n    return that\n  }\n\n  if (obj) {\n    if ((typeof ArrayBuffer !== 'undefined' &&\n        obj.buffer instanceof ArrayBuffer) || 'length' in obj) {\n      if (typeof obj.length !== 'number' || isnan(obj.length)) {\n        return createBuffer(that, 0)\n      }\n      return fromArrayLike(that, obj)\n    }\n\n    if (obj.type === 'Buffer' && isArray(obj.data)) {\n      return fromArrayLike(that, obj.data)\n    }\n  }\n\n  throw new TypeError('First argument must be a string, Buffer, ArrayBuffer, Array, or array-like object.')\n}\n\nfunction checked (length) {\n  // Note: cannot use `length < kMaxLength()` here because that fails when\n  // length is NaN (which is otherwise coerced to zero.)\n  if (length >= kMaxLength()) {\n    throw new RangeError('Attempt to allocate Buffer larger than maximum ' +\n                         'size: 0x' + kMaxLength().toString(16) + ' bytes')\n  }\n  return length | 0\n}\n\nfunction SlowBuffer (length) {\n  if (+length != length) { // eslint-disable-line eqeqeq\n    length = 0\n  }\n  return Buffer.alloc(+length)\n}\n\nBuffer.isBuffer = function isBuffer (b) {\n  return !!(b != null && b._isBuffer)\n}\n\nBuffer.compare = function compare (a, b) {\n  if (!Buffer.isBuffer(a) || !Buffer.isBuffer(b)) {\n    throw new TypeError('Arguments must be Buffers')\n  }\n\n  if (a === b) return 0\n\n  var x = a.length\n  var y = b.length\n\n  for (var i = 0, len = Math.min(x, y); i < len; ++i) {\n    if (a[i] !== b[i]) {\n      x = a[i]\n      y = b[i]\n      break\n    }\n  }\n\n  if (x < y) return -1\n  if (y < x) return 1\n  return 0\n}\n\nBuffer.isEncoding = function isEncoding (encoding) {\n  switch (String(encoding).toLowerCase()) {\n    case 'hex':\n    case 'utf8':\n    case 'utf-8':\n    case 'ascii':\n    case 'latin1':\n    case 'binary':\n    case 'base64':\n    case 'ucs2':\n    case 'ucs-2':\n    case 'utf16le':\n    case 'utf-16le':\n      return true\n    default:\n      return false\n  }\n}\n\nBuffer.concat = function concat (list, length) {\n  if (!isArray(list)) {\n    throw new TypeError('\"list\" argument must be an Array of Buffers')\n  }\n\n  if (list.length === 0) {\n    return Buffer.alloc(0)\n  }\n\n  var i\n  if (length === undefined) {\n    length = 0\n    for (i = 0; i < list.length; ++i) {\n      length += list[i].length\n    }\n  }\n\n  var buffer = Buffer.allocUnsafe(length)\n  var pos = 0\n  for (i = 0; i < list.length; ++i) {\n    var buf = list[i]\n    if (!Buffer.isBuffer(buf)) {\n      throw new TypeError('\"list\" argument must be an Array of Buffers')\n    }\n    buf.copy(buffer, pos)\n    pos += buf.length\n  }\n  return buffer\n}\n\nfunction byteLength (string, encoding) {\n  if (Buffer.isBuffer(string)) {\n    return string.length\n  }\n  if (typeof ArrayBuffer !== 'undefined' && typeof ArrayBuffer.isView === 'function' &&\n      (ArrayBuffer.isView(string) || string instanceof ArrayBuffer)) {\n    return string.byteLength\n  }\n  if (typeof string !== 'string') {\n    string = '' + string\n  }\n\n  var len = string.length\n  if (len === 0) return 0\n\n  // Use a for loop to avoid recursion\n  var loweredCase = false\n  for (;;) {\n    switch (encoding) {\n      case 'ascii':\n      case 'latin1':\n      case 'binary':\n        return len\n      case 'utf8':\n      case 'utf-8':\n      case undefined:\n        return utf8ToBytes(string).length\n      case 'ucs2':\n      case 'ucs-2':\n      case 'utf16le':\n      case 'utf-16le':\n        return len * 2\n      case 'hex':\n        return len >>> 1\n      case 'base64':\n        return base64ToBytes(string).length\n      default:\n        if (loweredCase) return utf8ToBytes(string).length // assume utf8\n        encoding = ('' + encoding).toLowerCase()\n        loweredCase = true\n    }\n  }\n}\nBuffer.byteLength = byteLength\n\nfunction slowToString (encoding, start, end) {\n  var loweredCase = false\n\n  // No need to verify that \"this.length <= MAX_UINT32\" since it's a read-only\n  // property of a typed array.\n\n  // This behaves neither like String nor Uint8Array in that we set start/end\n  // to their upper/lower bounds if the value passed is out of range.\n  // undefined is handled specially as per ECMA-262 6th Edition,\n  // Section 13.3.3.7 Runtime Semantics: KeyedBindingInitialization.\n  if (start === undefined || start < 0) {\n    start = 0\n  }\n  // Return early if start > this.length. Done here to prevent potential uint32\n  // coercion fail below.\n  if (start > this.length) {\n    return ''\n  }\n\n  if (end === undefined || end > this.length) {\n    end = this.length\n  }\n\n  if (end <= 0) {\n    return ''\n  }\n\n  // Force coersion to uint32. This will also coerce falsey/NaN values to 0.\n  end >>>= 0\n  start >>>= 0\n\n  if (end <= start) {\n    return ''\n  }\n\n  if (!encoding) encoding = 'utf8'\n\n  while (true) {\n    switch (encoding) {\n      case 'hex':\n        return hexSlice(this, start, end)\n\n      case 'utf8':\n      case 'utf-8':\n        return utf8Slice(this, start, end)\n\n      case 'ascii':\n        return asciiSlice(this, start, end)\n\n      case 'latin1':\n      case 'binary':\n        return latin1Slice(this, start, end)\n\n      case 'base64':\n        return base64Slice(this, start, end)\n\n      case 'ucs2':\n      case 'ucs-2':\n      case 'utf16le':\n      case 'utf-16le':\n        return utf16leSlice(this, start, end)\n\n      default:\n        if (loweredCase) throw new TypeError('Unknown encoding: ' + encoding)\n        encoding = (encoding + '').toLowerCase()\n        loweredCase = true\n    }\n  }\n}\n\n// The property is used by `Buffer.isBuffer` and `is-buffer` (in Safari 5-7) to detect\n// Buffer instances.\nBuffer.prototype._isBuffer = true\n\nfunction swap (b, n, m) {\n  var i = b[n]\n  b[n] = b[m]\n  b[m] = i\n}\n\nBuffer.prototype.swap16 = function swap16 () {\n  var len = this.length\n  if (len % 2 !== 0) {\n    throw new RangeError('Buffer size must be a multiple of 16-bits')\n  }\n  for (var i = 0; i < len; i += 2) {\n    swap(this, i, i + 1)\n  }\n  return this\n}\n\nBuffer.prototype.swap32 = function swap32 () {\n  var len = this.length\n  if (len % 4 !== 0) {\n    throw new RangeError('Buffer size must be a multiple of 32-bits')\n  }\n  for (var i = 0; i < len; i += 4) {\n    swap(this, i, i + 3)\n    swap(this, i + 1, i + 2)\n  }\n  return this\n}\n\nBuffer.prototype.swap64 = function swap64 () {\n  var len = this.length\n  if (len % 8 !== 0) {\n    throw new RangeError('Buffer size must be a multiple of 64-bits')\n  }\n  for (var i = 0; i < len; i += 8) {\n    swap(this, i, i + 7)\n    swap(this, i + 1, i + 6)\n    swap(this, i + 2, i + 5)\n    swap(this, i + 3, i + 4)\n  }\n  return this\n}\n\nBuffer.prototype.toString = function toString () {\n  var length = this.length | 0\n  if (length === 0) return ''\n  if (arguments.length === 0) return utf8Slice(this, 0, length)\n  return slowToString.apply(this, arguments)\n}\n\nBuffer.prototype.equals = function equals (b) {\n  if (!Buffer.isBuffer(b)) throw new TypeError('Argument must be a Buffer')\n  if (this === b) return true\n  return Buffer.compare(this, b) === 0\n}\n\nBuffer.prototype.inspect = function inspect () {\n  var str = ''\n  var max = exports.INSPECT_MAX_BYTES\n  if (this.length > 0) {\n    str = this.toString('hex', 0, max).match(/.{2}/g).join(' ')\n    if (this.length > max) str += ' ... '\n  }\n  return '<Buffer ' + str + '>'\n}\n\nBuffer.prototype.compare = function compare (target, start, end, thisStart, thisEnd) {\n  if (!Buffer.isBuffer(target)) {\n    throw new TypeError('Argument must be a Buffer')\n  }\n\n  if (start === undefined) {\n    start = 0\n  }\n  if (end === undefined) {\n    end = target ? target.length : 0\n  }\n  if (thisStart === undefined) {\n    thisStart = 0\n  }\n  if (thisEnd === undefined) {\n    thisEnd = this.length\n  }\n\n  if (start < 0 || end > target.length || thisStart < 0 || thisEnd > this.length) {\n    throw new RangeError('out of range index')\n  }\n\n  if (thisStart >= thisEnd && start >= end) {\n    return 0\n  }\n  if (thisStart >= thisEnd) {\n    return -1\n  }\n  if (start >= end) {\n    return 1\n  }\n\n  start >>>= 0\n  end >>>= 0\n  thisStart >>>= 0\n  thisEnd >>>= 0\n\n  if (this === target) return 0\n\n  var x = thisEnd - thisStart\n  var y = end - start\n  var len = Math.min(x, y)\n\n  var thisCopy = this.slice(thisStart, thisEnd)\n  var targetCopy = target.slice(start, end)\n\n  for (var i = 0; i < len; ++i) {\n    if (thisCopy[i] !== targetCopy[i]) {\n      x = thisCopy[i]\n      y = targetCopy[i]\n      break\n    }\n  }\n\n  if (x < y) return -1\n  if (y < x) return 1\n  return 0\n}\n\n// Finds either the first index of `val` in `buffer` at offset >= `byteOffset`,\n// OR the last index of `val` in `buffer` at offset <= `byteOffset`.\n//\n// Arguments:\n// - buffer - a Buffer to search\n// - val - a string, Buffer, or number\n// - byteOffset - an index into `buffer`; will be clamped to an int32\n// - encoding - an optional encoding, relevant is val is a string\n// - dir - true for indexOf, false for lastIndexOf\nfunction bidirectionalIndexOf (buffer, val, byteOffset, encoding, dir) {\n  // Empty buffer means no match\n  if (buffer.length === 0) return -1\n\n  // Normalize byteOffset\n  if (typeof byteOffset === 'string') {\n    encoding = byteOffset\n    byteOffset = 0\n  } else if (byteOffset > 0x7fffffff) {\n    byteOffset = 0x7fffffff\n  } else if (byteOffset < -0x80000000) {\n    byteOffset = -0x80000000\n  }\n  byteOffset = +byteOffset  // Coerce to Number.\n  if (isNaN(byteOffset)) {\n    // byteOffset: it it's undefined, null, NaN, \"foo\", etc, search whole buffer\n    byteOffset = dir ? 0 : (buffer.length - 1)\n  }\n\n  // Normalize byteOffset: negative offsets start from the end of the buffer\n  if (byteOffset < 0) byteOffset = buffer.length + byteOffset\n  if (byteOffset >= buffer.length) {\n    if (dir) return -1\n    else byteOffset = buffer.length - 1\n  } else if (byteOffset < 0) {\n    if (dir) byteOffset = 0\n    else return -1\n  }\n\n  // Normalize val\n  if (typeof val === 'string') {\n    val = Buffer.from(val, encoding)\n  }\n\n  // Finally, search either indexOf (if dir is true) or lastIndexOf\n  if (Buffer.isBuffer(val)) {\n    // Special case: looking for empty string/buffer always fails\n    if (val.length === 0) {\n      return -1\n    }\n    return arrayIndexOf(buffer, val, byteOffset, encoding, dir)\n  } else if (typeof val === 'number') {\n    val = val & 0xFF // Search for a byte value [0-255]\n    if (Buffer.TYPED_ARRAY_SUPPORT &&\n        typeof Uint8Array.prototype.indexOf === 'function') {\n      if (dir) {\n        return Uint8Array.prototype.indexOf.call(buffer, val, byteOffset)\n      } else {\n        return Uint8Array.prototype.lastIndexOf.call(buffer, val, byteOffset)\n      }\n    }\n    return arrayIndexOf(buffer, [ val ], byteOffset, encoding, dir)\n  }\n\n  throw new TypeError('val must be string, number or Buffer')\n}\n\nfunction arrayIndexOf (arr, val, byteOffset, encoding, dir) {\n  var indexSize = 1\n  var arrLength = arr.length\n  var valLength = val.length\n\n  if (encoding !== undefined) {\n    encoding = String(encoding).toLowerCase()\n    if (encoding === 'ucs2' || encoding === 'ucs-2' ||\n        encoding === 'utf16le' || encoding === 'utf-16le') {\n      if (arr.length < 2 || val.length < 2) {\n        return -1\n      }\n      indexSize = 2\n      arrLength /= 2\n      valLength /= 2\n      byteOffset /= 2\n    }\n  }\n\n  function read (buf, i) {\n    if (indexSize === 1) {\n      return buf[i]\n    } else {\n      return buf.readUInt16BE(i * indexSize)\n    }\n  }\n\n  var i\n  if (dir) {\n    var foundIndex = -1\n    for (i = byteOffset; i < arrLength; i++) {\n      if (read(arr, i) === read(val, foundIndex === -1 ? 0 : i - foundIndex)) {\n        if (foundIndex === -1) foundIndex = i\n        if (i - foundIndex + 1 === valLength) return foundIndex * indexSize\n      } else {\n        if (foundIndex !== -1) i -= i - foundIndex\n        foundIndex = -1\n      }\n    }\n  } else {\n    if (byteOffset + valLength > arrLength) byteOffset = arrLength - valLength\n    for (i = byteOffset; i >= 0; i--) {\n      var found = true\n      for (var j = 0; j < valLength; j++) {\n        if (read(arr, i + j) !== read(val, j)) {\n          found = false\n          break\n        }\n      }\n      if (found) return i\n    }\n  }\n\n  return -1\n}\n\nBuffer.prototype.includes = function includes (val, byteOffset, encoding) {\n  return this.indexOf(val, byteOffset, encoding) !== -1\n}\n\nBuffer.prototype.indexOf = function indexOf (val, byteOffset, encoding) {\n  return bidirectionalIndexOf(this, val, byteOffset, encoding, true)\n}\n\nBuffer.prototype.lastIndexOf = function lastIndexOf (val, byteOffset, encoding) {\n  return bidirectionalIndexOf(this, val, byteOffset, encoding, false)\n}\n\nfunction hexWrite (buf, string, offset, length) {\n  offset = Number(offset) || 0\n  var remaining = buf.length - offset\n  if (!length) {\n    length = remaining\n  } else {\n    length = Number(length)\n    if (length > remaining) {\n      length = remaining\n    }\n  }\n\n  // must be an even number of digits\n  var strLen = string.length\n  if (strLen % 2 !== 0) throw new TypeError('Invalid hex string')\n\n  if (length > strLen / 2) {\n    length = strLen / 2\n  }\n  for (var i = 0; i < length; ++i) {\n    var parsed = parseInt(string.substr(i * 2, 2), 16)\n    if (isNaN(parsed)) return i\n    buf[offset + i] = parsed\n  }\n  return i\n}\n\nfunction utf8Write (buf, string, offset, length) {\n  return blitBuffer(utf8ToBytes(string, buf.length - offset), buf, offset, length)\n}\n\nfunction asciiWrite (buf, string, offset, length) {\n  return blitBuffer(asciiToBytes(string), buf, offset, length)\n}\n\nfunction latin1Write (buf, string, offset, length) {\n  return asciiWrite(buf, string, offset, length)\n}\n\nfunction base64Write (buf, string, offset, length) {\n  return blitBuffer(base64ToBytes(string), buf, offset, length)\n}\n\nfunction ucs2Write (buf, string, offset, length) {\n  return blitBuffer(utf16leToBytes(string, buf.length - offset), buf, offset, length)\n}\n\nBuffer.prototype.write = function write (string, offset, length, encoding) {\n  // Buffer#write(string)\n  if (offset === undefined) {\n    encoding = 'utf8'\n    length = this.length\n    offset = 0\n  // Buffer#write(string, encoding)\n  } else if (length === undefined && typeof offset === 'string') {\n    encoding = offset\n    length = this.length\n    offset = 0\n  // Buffer#write(string, offset[, length][, encoding])\n  } else if (isFinite(offset)) {\n    offset = offset | 0\n    if (isFinite(length)) {\n      length = length | 0\n      if (encoding === undefined) encoding = 'utf8'\n    } else {\n      encoding = length\n      length = undefined\n    }\n  // legacy write(string, encoding, offset, length) - remove in v0.13\n  } else {\n    throw new Error(\n      'Buffer.write(string, encoding, offset[, length]) is no longer supported'\n    )\n  }\n\n  var remaining = this.length - offset\n  if (length === undefined || length > remaining) length = remaining\n\n  if ((string.length > 0 && (length < 0 || offset < 0)) || offset > this.length) {\n    throw new RangeError('Attempt to write outside buffer bounds')\n  }\n\n  if (!encoding) encoding = 'utf8'\n\n  var loweredCase = false\n  for (;;) {\n    switch (encoding) {\n      case 'hex':\n        return hexWrite(this, string, offset, length)\n\n      case 'utf8':\n      case 'utf-8':\n        return utf8Write(this, string, offset, length)\n\n      case 'ascii':\n        return asciiWrite(this, string, offset, length)\n\n      case 'latin1':\n      case 'binary':\n        return latin1Write(this, string, offset, length)\n\n      case 'base64':\n        // Warning: maxLength not taken into account in base64Write\n        return base64Write(this, string, offset, length)\n\n      case 'ucs2':\n      case 'ucs-2':\n      case 'utf16le':\n      case 'utf-16le':\n        return ucs2Write(this, string, offset, length)\n\n      default:\n        if (loweredCase) throw new TypeError('Unknown encoding: ' + encoding)\n        encoding = ('' + encoding).toLowerCase()\n        loweredCase = true\n    }\n  }\n}\n\nBuffer.prototype.toJSON = function toJSON () {\n  return {\n    type: 'Buffer',\n    data: Array.prototype.slice.call(this._arr || this, 0)\n  }\n}\n\nfunction base64Slice (buf, start, end) {\n  if (start === 0 && end === buf.length) {\n    return base64.fromByteArray(buf)\n  } else {\n    return base64.fromByteArray(buf.slice(start, end))\n  }\n}\n\nfunction utf8Slice (buf, start, end) {\n  end = Math.min(buf.length, end)\n  var res = []\n\n  var i = start\n  while (i < end) {\n    var firstByte = buf[i]\n    var codePoint = null\n    var bytesPerSequence = (firstByte > 0xEF) ? 4\n      : (firstByte > 0xDF) ? 3\n      : (firstByte > 0xBF) ? 2\n      : 1\n\n    if (i + bytesPerSequence <= end) {\n      var secondByte, thirdByte, fourthByte, tempCodePoint\n\n      switch (bytesPerSequence) {\n        case 1:\n          if (firstByte < 0x80) {\n            codePoint = firstByte\n          }\n          break\n        case 2:\n          secondByte = buf[i + 1]\n          if ((secondByte & 0xC0) === 0x80) {\n            tempCodePoint = (firstByte & 0x1F) << 0x6 | (secondByte & 0x3F)\n            if (tempCodePoint > 0x7F) {\n              codePoint = tempCodePoint\n            }\n          }\n          break\n        case 3:\n          secondByte = buf[i + 1]\n          thirdByte = buf[i + 2]\n          if ((secondByte & 0xC0) === 0x80 && (thirdByte & 0xC0) === 0x80) {\n            tempCodePoint = (firstByte & 0xF) << 0xC | (secondByte & 0x3F) << 0x6 | (thirdByte & 0x3F)\n            if (tempCodePoint > 0x7FF && (tempCodePoint < 0xD800 || tempCodePoint > 0xDFFF)) {\n              codePoint = tempCodePoint\n            }\n          }\n          break\n        case 4:\n          secondByte = buf[i + 1]\n          thirdByte = buf[i + 2]\n          fourthByte = buf[i + 3]\n          if ((secondByte & 0xC0) === 0x80 && (thirdByte & 0xC0) === 0x80 && (fourthByte & 0xC0) === 0x80) {\n            tempCodePoint = (firstByte & 0xF) << 0x12 | (secondByte & 0x3F) << 0xC | (thirdByte & 0x3F) << 0x6 | (fourthByte & 0x3F)\n            if (tempCodePoint > 0xFFFF && tempCodePoint < 0x110000) {\n              codePoint = tempCodePoint\n            }\n          }\n      }\n    }\n\n    if (codePoint === null) {\n      // we did not generate a valid codePoint so insert a\n      // replacement char (U+FFFD) and advance only 1 byte\n      codePoint = 0xFFFD\n      bytesPerSequence = 1\n    } else if (codePoint > 0xFFFF) {\n      // encode to utf16 (surrogate pair dance)\n      codePoint -= 0x10000\n      res.push(codePoint >>> 10 & 0x3FF | 0xD800)\n      codePoint = 0xDC00 | codePoint & 0x3FF\n    }\n\n    res.push(codePoint)\n    i += bytesPerSequence\n  }\n\n  return decodeCodePointsArray(res)\n}\n\n// Based on http://stackoverflow.com/a/22747272/680742, the browser with\n// the lowest limit is Chrome, with 0x10000 args.\n// We go 1 magnitude less, for safety\nvar MAX_ARGUMENTS_LENGTH = 0x1000\n\nfunction decodeCodePointsArray (codePoints) {\n  var len = codePoints.length\n  if (len <= MAX_ARGUMENTS_LENGTH) {\n    return String.fromCharCode.apply(String, codePoints) // avoid extra slice()\n  }\n\n  // Decode in chunks to avoid \"call stack size exceeded\".\n  var res = ''\n  var i = 0\n  while (i < len) {\n    res += String.fromCharCode.apply(\n      String,\n      codePoints.slice(i, i += MAX_ARGUMENTS_LENGTH)\n    )\n  }\n  return res\n}\n\nfunction asciiSlice (buf, start, end) {\n  var ret = ''\n  end = Math.min(buf.length, end)\n\n  for (var i = start; i < end; ++i) {\n    ret += String.fromCharCode(buf[i] & 0x7F)\n  }\n  return ret\n}\n\nfunction latin1Slice (buf, start, end) {\n  var ret = ''\n  end = Math.min(buf.length, end)\n\n  for (var i = start; i < end; ++i) {\n    ret += String.fromCharCode(buf[i])\n  }\n  return ret\n}\n\nfunction hexSlice (buf, start, end) {\n  var len = buf.length\n\n  if (!start || start < 0) start = 0\n  if (!end || end < 0 || end > len) end = len\n\n  var out = ''\n  for (var i = start; i < end; ++i) {\n    out += toHex(buf[i])\n  }\n  return out\n}\n\nfunction utf16leSlice (buf, start, end) {\n  var bytes = buf.slice(start, end)\n  var res = ''\n  for (var i = 0; i < bytes.length; i += 2) {\n    res += String.fromCharCode(bytes[i] + bytes[i + 1] * 256)\n  }\n  return res\n}\n\nBuffer.prototype.slice = function slice (start, end) {\n  var len = this.length\n  start = ~~start\n  end = end === undefined ? len : ~~end\n\n  if (start < 0) {\n    start += len\n    if (start < 0) start = 0\n  } else if (start > len) {\n    start = len\n  }\n\n  if (end < 0) {\n    end += len\n    if (end < 0) end = 0\n  } else if (end > len) {\n    end = len\n  }\n\n  if (end < start) end = start\n\n  var newBuf\n  if (Buffer.TYPED_ARRAY_SUPPORT) {\n    newBuf = this.subarray(start, end)\n    newBuf.__proto__ = Buffer.prototype\n  } else {\n    var sliceLen = end - start\n    newBuf = new Buffer(sliceLen, undefined)\n    for (var i = 0; i < sliceLen; ++i) {\n      newBuf[i] = this[i + start]\n    }\n  }\n\n  return newBuf\n}\n\n/*\n * Need to make sure that buffer isn't trying to write out of bounds.\n */\nfunction checkOffset (offset, ext, length) {\n  if ((offset % 1) !== 0 || offset < 0) throw new RangeError('offset is not uint')\n  if (offset + ext > length) throw new RangeError('Trying to access beyond buffer length')\n}\n\nBuffer.prototype.readUIntLE = function readUIntLE (offset, byteLength, noAssert) {\n  offset = offset | 0\n  byteLength = byteLength | 0\n  if (!noAssert) checkOffset(offset, byteLength, this.length)\n\n  var val = this[offset]\n  var mul = 1\n  var i = 0\n  while (++i < byteLength && (mul *= 0x100)) {\n    val += this[offset + i] * mul\n  }\n\n  return val\n}\n\nBuffer.prototype.readUIntBE = function readUIntBE (offset, byteLength, noAssert) {\n  offset = offset | 0\n  byteLength = byteLength | 0\n  if (!noAssert) {\n    checkOffset(offset, byteLength, this.length)\n  }\n\n  var val = this[offset + --byteLength]\n  var mul = 1\n  while (byteLength > 0 && (mul *= 0x100)) {\n    val += this[offset + --byteLength] * mul\n  }\n\n  return val\n}\n\nBuffer.prototype.readUInt8 = function readUInt8 (offset, noAssert) {\n  if (!noAssert) checkOffset(offset, 1, this.length)\n  return this[offset]\n}\n\nBuffer.prototype.readUInt16LE = function readUInt16LE (offset, noAssert) {\n  if (!noAssert) checkOffset(offset, 2, this.length)\n  return this[offset] | (this[offset + 1] << 8)\n}\n\nBuffer.prototype.readUInt16BE = function readUInt16BE (offset, noAssert) {\n  if (!noAssert) checkOffset(offset, 2, this.length)\n  return (this[offset] << 8) | this[offset + 1]\n}\n\nBuffer.prototype.readUInt32LE = function readUInt32LE (offset, noAssert) {\n  if (!noAssert) checkOffset(offset, 4, this.length)\n\n  return ((this[offset]) |\n      (this[offset + 1] << 8) |\n      (this[offset + 2] << 16)) +\n      (this[offset + 3] * 0x1000000)\n}\n\nBuffer.prototype.readUInt32BE = function readUInt32BE (offset, noAssert) {\n  if (!noAssert) checkOffset(offset, 4, this.length)\n\n  return (this[offset] * 0x1000000) +\n    ((this[offset + 1] << 16) |\n    (this[offset + 2] << 8) |\n    this[offset + 3])\n}\n\nBuffer.prototype.readIntLE = function readIntLE (offset, byteLength, noAssert) {\n  offset = offset | 0\n  byteLength = byteLength | 0\n  if (!noAssert) checkOffset(offset, byteLength, this.length)\n\n  var val = this[offset]\n  var mul = 1\n  var i = 0\n  while (++i < byteLength && (mul *= 0x100)) {\n    val += this[offset + i] * mul\n  }\n  mul *= 0x80\n\n  if (val >= mul) val -= Math.pow(2, 8 * byteLength)\n\n  return val\n}\n\nBuffer.prototype.readIntBE = function readIntBE (offset, byteLength, noAssert) {\n  offset = offset | 0\n  byteLength = byteLength | 0\n  if (!noAssert) checkOffset(offset, byteLength, this.length)\n\n  var i = byteLength\n  var mul = 1\n  var val = this[offset + --i]\n  while (i > 0 && (mul *= 0x100)) {\n    val += this[offset + --i] * mul\n  }\n  mul *= 0x80\n\n  if (val >= mul) val -= Math.pow(2, 8 * byteLength)\n\n  return val\n}\n\nBuffer.prototype.readInt8 = function readInt8 (offset, noAssert) {\n  if (!noAssert) checkOffset(offset, 1, this.length)\n  if (!(this[offset] & 0x80)) return (this[offset])\n  return ((0xff - this[offset] + 1) * -1)\n}\n\nBuffer.prototype.readInt16LE = function readInt16LE (offset, noAssert) {\n  if (!noAssert) checkOffset(offset, 2, this.length)\n  var val = this[offset] | (this[offset + 1] << 8)\n  return (val & 0x8000) ? val | 0xFFFF0000 : val\n}\n\nBuffer.prototype.readInt16BE = function readInt16BE (offset, noAssert) {\n  if (!noAssert) checkOffset(offset, 2, this.length)\n  var val = this[offset + 1] | (this[offset] << 8)\n  return (val & 0x8000) ? val | 0xFFFF0000 : val\n}\n\nBuffer.prototype.readInt32LE = function readInt32LE (offset, noAssert) {\n  if (!noAssert) checkOffset(offset, 4, this.length)\n\n  return (this[offset]) |\n    (this[offset + 1] << 8) |\n    (this[offset + 2] << 16) |\n    (this[offset + 3] << 24)\n}\n\nBuffer.prototype.readInt32BE = function readInt32BE (offset, noAssert) {\n  if (!noAssert) checkOffset(offset, 4, this.length)\n\n  return (this[offset] << 24) |\n    (this[offset + 1] << 16) |\n    (this[offset + 2] << 8) |\n    (this[offset + 3])\n}\n\nBuffer.prototype.readFloatLE = function readFloatLE (offset, noAssert) {\n  if (!noAssert) checkOffset(offset, 4, this.length)\n  return ieee754.read(this, offset, true, 23, 4)\n}\n\nBuffer.prototype.readFloatBE = function readFloatBE (offset, noAssert) {\n  if (!noAssert) checkOffset(offset, 4, this.length)\n  return ieee754.read(this, offset, false, 23, 4)\n}\n\nBuffer.prototype.readDoubleLE = function readDoubleLE (offset, noAssert) {\n  if (!noAssert) checkOffset(offset, 8, this.length)\n  return ieee754.read(this, offset, true, 52, 8)\n}\n\nBuffer.prototype.readDoubleBE = function readDoubleBE (offset, noAssert) {\n  if (!noAssert) checkOffset(offset, 8, this.length)\n  return ieee754.read(this, offset, false, 52, 8)\n}\n\nfunction checkInt (buf, value, offset, ext, max, min) {\n  if (!Buffer.isBuffer(buf)) throw new TypeError('\"buffer\" argument must be a Buffer instance')\n  if (value > max || value < min) throw new RangeError('\"value\" argument is out of bounds')\n  if (offset + ext > buf.length) throw new RangeError('Index out of range')\n}\n\nBuffer.prototype.writeUIntLE = function writeUIntLE (value, offset, byteLength, noAssert) {\n  value = +value\n  offset = offset | 0\n  byteLength = byteLength | 0\n  if (!noAssert) {\n    var maxBytes = Math.pow(2, 8 * byteLength) - 1\n    checkInt(this, value, offset, byteLength, maxBytes, 0)\n  }\n\n  var mul = 1\n  var i = 0\n  this[offset] = value & 0xFF\n  while (++i < byteLength && (mul *= 0x100)) {\n    this[offset + i] = (value / mul) & 0xFF\n  }\n\n  return offset + byteLength\n}\n\nBuffer.prototype.writeUIntBE = function writeUIntBE (value, offset, byteLength, noAssert) {\n  value = +value\n  offset = offset | 0\n  byteLength = byteLength | 0\n  if (!noAssert) {\n    var maxBytes = Math.pow(2, 8 * byteLength) - 1\n    checkInt(this, value, offset, byteLength, maxBytes, 0)\n  }\n\n  var i = byteLength - 1\n  var mul = 1\n  this[offset + i] = value & 0xFF\n  while (--i >= 0 && (mul *= 0x100)) {\n    this[offset + i] = (value / mul) & 0xFF\n  }\n\n  return offset + byteLength\n}\n\nBuffer.prototype.writeUInt8 = function writeUInt8 (value, offset, noAssert) {\n  value = +value\n  offset = offset | 0\n  if (!noAssert) checkInt(this, value, offset, 1, 0xff, 0)\n  if (!Buffer.TYPED_ARRAY_SUPPORT) value = Math.floor(value)\n  this[offset] = (value & 0xff)\n  return offset + 1\n}\n\nfunction objectWriteUInt16 (buf, value, offset, littleEndian) {\n  if (value < 0) value = 0xffff + value + 1\n  for (var i = 0, j = Math.min(buf.length - offset, 2); i < j; ++i) {\n    buf[offset + i] = (value & (0xff << (8 * (littleEndian ? i : 1 - i)))) >>>\n      (littleEndian ? i : 1 - i) * 8\n  }\n}\n\nBuffer.prototype.writeUInt16LE = function writeUInt16LE (value, offset, noAssert) {\n  value = +value\n  offset = offset | 0\n  if (!noAssert) checkInt(this, value, offset, 2, 0xffff, 0)\n  if (Buffer.TYPED_ARRAY_SUPPORT) {\n    this[offset] = (value & 0xff)\n    this[offset + 1] = (value >>> 8)\n  } else {\n    objectWriteUInt16(this, value, offset, true)\n  }\n  return offset + 2\n}\n\nBuffer.prototype.writeUInt16BE = function writeUInt16BE (value, offset, noAssert) {\n  value = +value\n  offset = offset | 0\n  if (!noAssert) checkInt(this, value, offset, 2, 0xffff, 0)\n  if (Buffer.TYPED_ARRAY_SUPPORT) {\n    this[offset] = (value >>> 8)\n    this[offset + 1] = (value & 0xff)\n  } else {\n    objectWriteUInt16(this, value, offset, false)\n  }\n  return offset + 2\n}\n\nfunction objectWriteUInt32 (buf, value, offset, littleEndian) {\n  if (value < 0) value = 0xffffffff + value + 1\n  for (var i = 0, j = Math.min(buf.length - offset, 4); i < j; ++i) {\n    buf[offset + i] = (value >>> (littleEndian ? i : 3 - i) * 8) & 0xff\n  }\n}\n\nBuffer.prototype.writeUInt32LE = function writeUInt32LE (value, offset, noAssert) {\n  value = +value\n  offset = offset | 0\n  if (!noAssert) checkInt(this, value, offset, 4, 0xffffffff, 0)\n  if (Buffer.TYPED_ARRAY_SUPPORT) {\n    this[offset + 3] = (value >>> 24)\n    this[offset + 2] = (value >>> 16)\n    this[offset + 1] = (value >>> 8)\n    this[offset] = (value & 0xff)\n  } else {\n    objectWriteUInt32(this, value, offset, true)\n  }\n  return offset + 4\n}\n\nBuffer.prototype.writeUInt32BE = function writeUInt32BE (value, offset, noAssert) {\n  value = +value\n  offset = offset | 0\n  if (!noAssert) checkInt(this, value, offset, 4, 0xffffffff, 0)\n  if (Buffer.TYPED_ARRAY_SUPPORT) {\n    this[offset] = (value >>> 24)\n    this[offset + 1] = (value >>> 16)\n    this[offset + 2] = (value >>> 8)\n    this[offset + 3] = (value & 0xff)\n  } else {\n    objectWriteUInt32(this, value, offset, false)\n  }\n  return offset + 4\n}\n\nBuffer.prototype.writeIntLE = function writeIntLE (value, offset, byteLength, noAssert) {\n  value = +value\n  offset = offset | 0\n  if (!noAssert) {\n    var limit = Math.pow(2, 8 * byteLength - 1)\n\n    checkInt(this, value, offset, byteLength, limit - 1, -limit)\n  }\n\n  var i = 0\n  var mul = 1\n  var sub = 0\n  this[offset] = value & 0xFF\n  while (++i < byteLength && (mul *= 0x100)) {\n    if (value < 0 && sub === 0 && this[offset + i - 1] !== 0) {\n      sub = 1\n    }\n    this[offset + i] = ((value / mul) >> 0) - sub & 0xFF\n  }\n\n  return offset + byteLength\n}\n\nBuffer.prototype.writeIntBE = function writeIntBE (value, offset, byteLength, noAssert) {\n  value = +value\n  offset = offset | 0\n  if (!noAssert) {\n    var limit = Math.pow(2, 8 * byteLength - 1)\n\n    checkInt(this, value, offset, byteLength, limit - 1, -limit)\n  }\n\n  var i = byteLength - 1\n  var mul = 1\n  var sub = 0\n  this[offset + i] = value & 0xFF\n  while (--i >= 0 && (mul *= 0x100)) {\n    if (value < 0 && sub === 0 && this[offset + i + 1] !== 0) {\n      sub = 1\n    }\n    this[offset + i] = ((value / mul) >> 0) - sub & 0xFF\n  }\n\n  return offset + byteLength\n}\n\nBuffer.prototype.writeInt8 = function writeInt8 (value, offset, noAssert) {\n  value = +value\n  offset = offset | 0\n  if (!noAssert) checkInt(this, value, offset, 1, 0x7f, -0x80)\n  if (!Buffer.TYPED_ARRAY_SUPPORT) value = Math.floor(value)\n  if (value < 0) value = 0xff + value + 1\n  this[offset] = (value & 0xff)\n  return offset + 1\n}\n\nBuffer.prototype.writeInt16LE = function writeInt16LE (value, offset, noAssert) {\n  value = +value\n  offset = offset | 0\n  if (!noAssert) checkInt(this, value, offset, 2, 0x7fff, -0x8000)\n  if (Buffer.TYPED_ARRAY_SUPPORT) {\n    this[offset] = (value & 0xff)\n    this[offset + 1] = (value >>> 8)\n  } else {\n    objectWriteUInt16(this, value, offset, true)\n  }\n  return offset + 2\n}\n\nBuffer.prototype.writeInt16BE = function writeInt16BE (value, offset, noAssert) {\n  value = +value\n  offset = offset | 0\n  if (!noAssert) checkInt(this, value, offset, 2, 0x7fff, -0x8000)\n  if (Buffer.TYPED_ARRAY_SUPPORT) {\n    this[offset] = (value >>> 8)\n    this[offset + 1] = (value & 0xff)\n  } else {\n    objectWriteUInt16(this, value, offset, false)\n  }\n  return offset + 2\n}\n\nBuffer.prototype.writeInt32LE = function writeInt32LE (value, offset, noAssert) {\n  value = +value\n  offset = offset | 0\n  if (!noAssert) checkInt(this, value, offset, 4, 0x7fffffff, -0x80000000)\n  if (Buffer.TYPED_ARRAY_SUPPORT) {\n    this[offset] = (value & 0xff)\n    this[offset + 1] = (value >>> 8)\n    this[offset + 2] = (value >>> 16)\n    this[offset + 3] = (value >>> 24)\n  } else {\n    objectWriteUInt32(this, value, offset, true)\n  }\n  return offset + 4\n}\n\nBuffer.prototype.writeInt32BE = function writeInt32BE (value, offset, noAssert) {\n  value = +value\n  offset = offset | 0\n  if (!noAssert) checkInt(this, value, offset, 4, 0x7fffffff, -0x80000000)\n  if (value < 0) value = 0xffffffff + value + 1\n  if (Buffer.TYPED_ARRAY_SUPPORT) {\n    this[offset] = (value >>> 24)\n    this[offset + 1] = (value >>> 16)\n    this[offset + 2] = (value >>> 8)\n    this[offset + 3] = (value & 0xff)\n  } else {\n    objectWriteUInt32(this, value, offset, false)\n  }\n  return offset + 4\n}\n\nfunction checkIEEE754 (buf, value, offset, ext, max, min) {\n  if (offset + ext > buf.length) throw new RangeError('Index out of range')\n  if (offset < 0) throw new RangeError('Index out of range')\n}\n\nfunction writeFloat (buf, value, offset, littleEndian, noAssert) {\n  if (!noAssert) {\n    checkIEEE754(buf, value, offset, 4, 3.4028234663852886e+38, -3.4028234663852886e+38)\n  }\n  ieee754.write(buf, value, offset, littleEndian, 23, 4)\n  return offset + 4\n}\n\nBuffer.prototype.writeFloatLE = function writeFloatLE (value, offset, noAssert) {\n  return writeFloat(this, value, offset, true, noAssert)\n}\n\nBuffer.prototype.writeFloatBE = function writeFloatBE (value, offset, noAssert) {\n  return writeFloat(this, value, offset, false, noAssert)\n}\n\nfunction writeDouble (buf, value, offset, littleEndian, noAssert) {\n  if (!noAssert) {\n    checkIEEE754(buf, value, offset, 8, 1.7976931348623157E+308, -1.7976931348623157E+308)\n  }\n  ieee754.write(buf, value, offset, littleEndian, 52, 8)\n  return offset + 8\n}\n\nBuffer.prototype.writeDoubleLE = function writeDoubleLE (value, offset, noAssert) {\n  return writeDouble(this, value, offset, true, noAssert)\n}\n\nBuffer.prototype.writeDoubleBE = function writeDoubleBE (value, offset, noAssert) {\n  return writeDouble(this, value, offset, false, noAssert)\n}\n\n// copy(targetBuffer, targetStart=0, sourceStart=0, sourceEnd=buffer.length)\nBuffer.prototype.copy = function copy (target, targetStart, start, end) {\n  if (!start) start = 0\n  if (!end && end !== 0) end = this.length\n  if (targetStart >= target.length) targetStart = target.length\n  if (!targetStart) targetStart = 0\n  if (end > 0 && end < start) end = start\n\n  // Copy 0 bytes; we're done\n  if (end === start) return 0\n  if (target.length === 0 || this.length === 0) return 0\n\n  // Fatal error conditions\n  if (targetStart < 0) {\n    throw new RangeError('targetStart out of bounds')\n  }\n  if (start < 0 || start >= this.length) throw new RangeError('sourceStart out of bounds')\n  if (end < 0) throw new RangeError('sourceEnd out of bounds')\n\n  // Are we oob?\n  if (end > this.length) end = this.length\n  if (target.length - targetStart < end - start) {\n    end = target.length - targetStart + start\n  }\n\n  var len = end - start\n  var i\n\n  if (this === target && start < targetStart && targetStart < end) {\n    // descending copy from end\n    for (i = len - 1; i >= 0; --i) {\n      target[i + targetStart] = this[i + start]\n    }\n  } else if (len < 1000 || !Buffer.TYPED_ARRAY_SUPPORT) {\n    // ascending copy from start\n    for (i = 0; i < len; ++i) {\n      target[i + targetStart] = this[i + start]\n    }\n  } else {\n    Uint8Array.prototype.set.call(\n      target,\n      this.subarray(start, start + len),\n      targetStart\n    )\n  }\n\n  return len\n}\n\n// Usage:\n//    buffer.fill(number[, offset[, end]])\n//    buffer.fill(buffer[, offset[, end]])\n//    buffer.fill(string[, offset[, end]][, encoding])\nBuffer.prototype.fill = function fill (val, start, end, encoding) {\n  // Handle string cases:\n  if (typeof val === 'string') {\n    if (typeof start === 'string') {\n      encoding = start\n      start = 0\n      end = this.length\n    } else if (typeof end === 'string') {\n      encoding = end\n      end = this.length\n    }\n    if (val.length === 1) {\n      var code = val.charCodeAt(0)\n      if (code < 256) {\n        val = code\n      }\n    }\n    if (encoding !== undefined && typeof encoding !== 'string') {\n      throw new TypeError('encoding must be a string')\n    }\n    if (typeof encoding === 'string' && !Buffer.isEncoding(encoding)) {\n      throw new TypeError('Unknown encoding: ' + encoding)\n    }\n  } else if (typeof val === 'number') {\n    val = val & 255\n  }\n\n  // Invalid ranges are not set to a default, so can range check early.\n  if (start < 0 || this.length < start || this.length < end) {\n    throw new RangeError('Out of range index')\n  }\n\n  if (end <= start) {\n    return this\n  }\n\n  start = start >>> 0\n  end = end === undefined ? this.length : end >>> 0\n\n  if (!val) val = 0\n\n  var i\n  if (typeof val === 'number') {\n    for (i = start; i < end; ++i) {\n      this[i] = val\n    }\n  } else {\n    var bytes = Buffer.isBuffer(val)\n      ? val\n      : utf8ToBytes(new Buffer(val, encoding).toString())\n    var len = bytes.length\n    for (i = 0; i < end - start; ++i) {\n      this[i + start] = bytes[i % len]\n    }\n  }\n\n  return this\n}\n\n// HELPER FUNCTIONS\n// ================\n\nvar INVALID_BASE64_RE = /[^+\\/0-9A-Za-z-_]/g\n\nfunction base64clean (str) {\n  // Node strips out invalid characters like \\n and \\t from the string, base64-js does not\n  str = stringtrim(str).replace(INVALID_BASE64_RE, '')\n  // Node converts strings with length < 2 to ''\n  if (str.length < 2) return ''\n  // Node allows for non-padded base64 strings (missing trailing ===), base64-js does not\n  while (str.length % 4 !== 0) {\n    str = str + '='\n  }\n  return str\n}\n\nfunction stringtrim (str) {\n  if (str.trim) return str.trim()\n  return str.replace(/^\\s+|\\s+$/g, '')\n}\n\nfunction toHex (n) {\n  if (n < 16) return '0' + n.toString(16)\n  return n.toString(16)\n}\n\nfunction utf8ToBytes (string, units) {\n  units = units || Infinity\n  var codePoint\n  var length = string.length\n  var leadSurrogate = null\n  var bytes = []\n\n  for (var i = 0; i < length; ++i) {\n    codePoint = string.charCodeAt(i)\n\n    // is surrogate component\n    if (codePoint > 0xD7FF && codePoint < 0xE000) {\n      // last char was a lead\n      if (!leadSurrogate) {\n        // no lead yet\n        if (codePoint > 0xDBFF) {\n          // unexpected trail\n          if ((units -= 3) > -1) bytes.push(0xEF, 0xBF, 0xBD)\n          continue\n        } else if (i + 1 === length) {\n          // unpaired lead\n          if ((units -= 3) > -1) bytes.push(0xEF, 0xBF, 0xBD)\n          continue\n        }\n\n        // valid lead\n        leadSurrogate = codePoint\n\n        continue\n      }\n\n      // 2 leads in a row\n      if (codePoint < 0xDC00) {\n        if ((units -= 3) > -1) bytes.push(0xEF, 0xBF, 0xBD)\n        leadSurrogate = codePoint\n        continue\n      }\n\n      // valid surrogate pair\n      codePoint = (leadSurrogate - 0xD800 << 10 | codePoint - 0xDC00) + 0x10000\n    } else if (leadSurrogate) {\n      // valid bmp char, but last char was a lead\n      if ((units -= 3) > -1) bytes.push(0xEF, 0xBF, 0xBD)\n    }\n\n    leadSurrogate = null\n\n    // encode utf8\n    if (codePoint < 0x80) {\n      if ((units -= 1) < 0) break\n      bytes.push(codePoint)\n    } else if (codePoint < 0x800) {\n      if ((units -= 2) < 0) break\n      bytes.push(\n        codePoint >> 0x6 | 0xC0,\n        codePoint & 0x3F | 0x80\n      )\n    } else if (codePoint < 0x10000) {\n      if ((units -= 3) < 0) break\n      bytes.push(\n        codePoint >> 0xC | 0xE0,\n        codePoint >> 0x6 & 0x3F | 0x80,\n        codePoint & 0x3F | 0x80\n      )\n    } else if (codePoint < 0x110000) {\n      if ((units -= 4) < 0) break\n      bytes.push(\n        codePoint >> 0x12 | 0xF0,\n        codePoint >> 0xC & 0x3F | 0x80,\n        codePoint >> 0x6 & 0x3F | 0x80,\n        codePoint & 0x3F | 0x80\n      )\n    } else {\n      throw new Error('Invalid code point')\n    }\n  }\n\n  return bytes\n}\n\nfunction asciiToBytes (str) {\n  var byteArray = []\n  for (var i = 0; i < str.length; ++i) {\n    // Node's code seems to be doing this and not & 0x7F..\n    byteArray.push(str.charCodeAt(i) & 0xFF)\n  }\n  return byteArray\n}\n\nfunction utf16leToBytes (str, units) {\n  var c, hi, lo\n  var byteArray = []\n  for (var i = 0; i < str.length; ++i) {\n    if ((units -= 2) < 0) break\n\n    c = str.charCodeAt(i)\n    hi = c >> 8\n    lo = c % 256\n    byteArray.push(lo)\n    byteArray.push(hi)\n  }\n\n  return byteArray\n}\n\nfunction base64ToBytes (str) {\n  return base64.toByteArray(base64clean(str))\n}\n\nfunction blitBuffer (src, dst, offset, length) {\n  for (var i = 0; i < length; ++i) {\n    if ((i + offset >= dst.length) || (i >= src.length)) break\n    dst[i + offset] = src[i]\n  }\n  return i\n}\n\nfunction isnan (val) {\n  return val !== val // eslint-disable-line no-self-compare\n}\n\n/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(8)))\n\n/***/ }),\n/* 38 */\n/***/ (function(module, exports, __webpack_require__) {\n\n\"use strict\";\n\n\nexports.byteLength = byteLength\nexports.toByteArray = toByteArray\nexports.fromByteArray = fromByteArray\n\nvar lookup = []\nvar revLookup = []\nvar Arr = typeof Uint8Array !== 'undefined' ? Uint8Array : Array\n\nvar code = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'\nfor (var i = 0, len = code.length; i < len; ++i) {\n  lookup[i] = code[i]\n  revLookup[code.charCodeAt(i)] = i\n}\n\n// Support decoding URL-safe base64 strings, as Node.js does.\n// See: https://en.wikipedia.org/wiki/Base64#URL_applications\nrevLookup['-'.charCodeAt(0)] = 62\nrevLookup['_'.charCodeAt(0)] = 63\n\nfunction getLens (b64) {\n  var len = b64.length\n\n  if (len % 4 > 0) {\n    throw new Error('Invalid string. Length must be a multiple of 4')\n  }\n\n  // Trim off extra bytes after placeholder bytes are found\n  // See: https://github.com/beatgammit/base64-js/issues/42\n  var validLen = b64.indexOf('=')\n  if (validLen === -1) validLen = len\n\n  var placeHoldersLen = validLen === len\n    ? 0\n    : 4 - (validLen % 4)\n\n  return [validLen, placeHoldersLen]\n}\n\n// base64 is 4/3 + up to two characters of the original data\nfunction byteLength (b64) {\n  var lens = getLens(b64)\n  var validLen = lens[0]\n  var placeHoldersLen = lens[1]\n  return ((validLen + placeHoldersLen) * 3 / 4) - placeHoldersLen\n}\n\nfunction _byteLength (b64, validLen, placeHoldersLen) {\n  return ((validLen + placeHoldersLen) * 3 / 4) - placeHoldersLen\n}\n\nfunction toByteArray (b64) {\n  var tmp\n  var lens = getLens(b64)\n  var validLen = lens[0]\n  var placeHoldersLen = lens[1]\n\n  var arr = new Arr(_byteLength(b64, validLen, placeHoldersLen))\n\n  var curByte = 0\n\n  // if there are placeholders, only get up to the last complete 4 chars\n  var len = placeHoldersLen > 0\n    ? validLen - 4\n    : validLen\n\n  for (var i = 0; i < len; i += 4) {\n    tmp =\n      (revLookup[b64.charCodeAt(i)] << 18) |\n      (revLookup[b64.charCodeAt(i + 1)] << 12) |\n      (revLookup[b64.charCodeAt(i + 2)] << 6) |\n      revLookup[b64.charCodeAt(i + 3)]\n    arr[curByte++] = (tmp >> 16) & 0xFF\n    arr[curByte++] = (tmp >> 8) & 0xFF\n    arr[curByte++] = tmp & 0xFF\n  }\n\n  if (placeHoldersLen === 2) {\n    tmp =\n      (revLookup[b64.charCodeAt(i)] << 2) |\n      (revLookup[b64.charCodeAt(i + 1)] >> 4)\n    arr[curByte++] = tmp & 0xFF\n  }\n\n  if (placeHoldersLen === 1) {\n    tmp =\n      (revLookup[b64.charCodeAt(i)] << 10) |\n      (revLookup[b64.charCodeAt(i + 1)] << 4) |\n      (revLookup[b64.charCodeAt(i + 2)] >> 2)\n    arr[curByte++] = (tmp >> 8) & 0xFF\n    arr[curByte++] = tmp & 0xFF\n  }\n\n  return arr\n}\n\nfunction tripletToBase64 (num) {\n  return lookup[num >> 18 & 0x3F] +\n    lookup[num >> 12 & 0x3F] +\n    lookup[num >> 6 & 0x3F] +\n    lookup[num & 0x3F]\n}\n\nfunction encodeChunk (uint8, start, end) {\n  var tmp\n  var output = []\n  for (var i = start; i < end; i += 3) {\n    tmp =\n      ((uint8[i] << 16) & 0xFF0000) +\n      ((uint8[i + 1] << 8) & 0xFF00) +\n      (uint8[i + 2] & 0xFF)\n    output.push(tripletToBase64(tmp))\n  }\n  return output.join('')\n}\n\nfunction fromByteArray (uint8) {\n  var tmp\n  var len = uint8.length\n  var extraBytes = len % 3 // if we have 1 byte left, pad 2 bytes\n  var parts = []\n  var maxChunkLength = 16383 // must be multiple of 3\n\n  // go through the array every three bytes, we'll deal with trailing stuff later\n  for (var i = 0, len2 = len - extraBytes; i < len2; i += maxChunkLength) {\n    parts.push(encodeChunk(\n      uint8, i, (i + maxChunkLength) > len2 ? len2 : (i + maxChunkLength)\n    ))\n  }\n\n  // pad the end with zeros, but make sure to not forget the extra bytes\n  if (extraBytes === 1) {\n    tmp = uint8[len - 1]\n    parts.push(\n      lookup[tmp >> 2] +\n      lookup[(tmp << 4) & 0x3F] +\n      '=='\n    )\n  } else if (extraBytes === 2) {\n    tmp = (uint8[len - 2] << 8) + uint8[len - 1]\n    parts.push(\n      lookup[tmp >> 10] +\n      lookup[(tmp >> 4) & 0x3F] +\n      lookup[(tmp << 2) & 0x3F] +\n      '='\n    )\n  }\n\n  return parts.join('')\n}\n\n\n/***/ }),\n/* 39 */\n/***/ (function(module, exports) {\n\nexports.read = function (buffer, offset, isLE, mLen, nBytes) {\n  var e, m\n  var eLen = (nBytes * 8) - mLen - 1\n  var eMax = (1 << eLen) - 1\n  var eBias = eMax >> 1\n  var nBits = -7\n  var i = isLE ? (nBytes - 1) : 0\n  var d = isLE ? -1 : 1\n  var s = buffer[offset + i]\n\n  i += d\n\n  e = s & ((1 << (-nBits)) - 1)\n  s >>= (-nBits)\n  nBits += eLen\n  for (; nBits > 0; e = (e * 256) + buffer[offset + i], i += d, nBits -= 8) {}\n\n  m = e & ((1 << (-nBits)) - 1)\n  e >>= (-nBits)\n  nBits += mLen\n  for (; nBits > 0; m = (m * 256) + buffer[offset + i], i += d, nBits -= 8) {}\n\n  if (e === 0) {\n    e = 1 - eBias\n  } else if (e === eMax) {\n    return m ? NaN : ((s ? -1 : 1) * Infinity)\n  } else {\n    m = m + Math.pow(2, mLen)\n    e = e - eBias\n  }\n  return (s ? -1 : 1) * m * Math.pow(2, e - mLen)\n}\n\nexports.write = function (buffer, value, offset, isLE, mLen, nBytes) {\n  var e, m, c\n  var eLen = (nBytes * 8) - mLen - 1\n  var eMax = (1 << eLen) - 1\n  var eBias = eMax >> 1\n  var rt = (mLen === 23 ? Math.pow(2, -24) - Math.pow(2, -77) : 0)\n  var i = isLE ? 0 : (nBytes - 1)\n  var d = isLE ? 1 : -1\n  var s = value < 0 || (value === 0 && 1 / value < 0) ? 1 : 0\n\n  value = Math.abs(value)\n\n  if (isNaN(value) || value === Infinity) {\n    m = isNaN(value) ? 1 : 0\n    e = eMax\n  } else {\n    e = Math.floor(Math.log(value) / Math.LN2)\n    if (value * (c = Math.pow(2, -e)) < 1) {\n      e--\n      c *= 2\n    }\n    if (e + eBias >= 1) {\n      value += rt / c\n    } else {\n      value += rt * Math.pow(2, 1 - eBias)\n    }\n    if (value * c >= 2) {\n      e++\n      c /= 2\n    }\n\n    if (e + eBias >= eMax) {\n      m = 0\n      e = eMax\n    } else if (e + eBias >= 1) {\n      m = ((value * c) - 1) * Math.pow(2, mLen)\n      e = e + eBias\n    } else {\n      m = value * Math.pow(2, eBias - 1) * Math.pow(2, mLen)\n      e = 0\n    }\n  }\n\n  for (; mLen >= 8; buffer[offset + i] = m & 0xff, i += d, m /= 256, mLen -= 8) {}\n\n  e = (e << mLen) | m\n  eLen += mLen\n  for (; eLen > 0; buffer[offset + i] = e & 0xff, i += d, e /= 256, eLen -= 8) {}\n\n  buffer[offset + i - d] |= s * 128\n}\n\n\n/***/ }),\n/* 40 */\n/***/ (function(module, exports) {\n\nvar toString = {}.toString;\n\nmodule.exports = Array.isArray || function (arr) {\n  return toString.call(arr) == '[object Array]';\n};\n\n\n/***/ }),\n/* 41 */\n/***/ (function(module, exports, __webpack_require__) {\n\n/*!\n * Bowser - a browser detector\n * https://github.com/ded/bowser\n * MIT License | (c) Dustin Diaz 2015\n */\n\n!function (root, name, definition) {\n  if (typeof module != 'undefined' && module.exports) module.exports = definition()\n  else if (true) __webpack_require__(42)(name, definition)\n  else {}\n}(this, 'bowser', function () {\n  /**\n    * See useragents.js for examples of navigator.userAgent\n    */\n\n  var t = true\n\n  function detect(ua) {\n\n    function getFirstMatch(regex) {\n      var match = ua.match(regex);\n      return (match && match.length > 1 && match[1]) || '';\n    }\n\n    function getSecondMatch(regex) {\n      var match = ua.match(regex);\n      return (match && match.length > 1 && match[2]) || '';\n    }\n\n    var iosdevice = getFirstMatch(/(ipod|iphone|ipad)/i).toLowerCase()\n      , likeAndroid = /like android/i.test(ua)\n      , android = !likeAndroid && /android/i.test(ua)\n      , nexusMobile = /nexus\\s*[0-6]\\s*/i.test(ua)\n      , nexusTablet = !nexusMobile && /nexus\\s*[0-9]+/i.test(ua)\n      , chromeos = /CrOS/.test(ua)\n      , silk = /silk/i.test(ua)\n      , sailfish = /sailfish/i.test(ua)\n      , tizen = /tizen/i.test(ua)\n      , webos = /(web|hpw)os/i.test(ua)\n      , windowsphone = /windows phone/i.test(ua)\n      , samsungBrowser = /SamsungBrowser/i.test(ua)\n      , windows = !windowsphone && /windows/i.test(ua)\n      , mac = !iosdevice && !silk && /macintosh/i.test(ua)\n      , linux = !android && !sailfish && !tizen && !webos && /linux/i.test(ua)\n      , edgeVersion = getSecondMatch(/edg([ea]|ios)\\/(\\d+(\\.\\d+)?)/i)\n      , versionIdentifier = getFirstMatch(/version\\/(\\d+(\\.\\d+)?)/i)\n      , tablet = /tablet/i.test(ua) && !/tablet pc/i.test(ua)\n      , mobile = !tablet && /[^-]mobi/i.test(ua)\n      , xbox = /xbox/i.test(ua)\n      , result\n\n    if (/opera/i.test(ua)) {\n      //  an old Opera\n      result = {\n        name: 'Opera'\n      , opera: t\n      , version: versionIdentifier || getFirstMatch(/(?:opera|opr|opios)[\\s\\/](\\d+(\\.\\d+)?)/i)\n      }\n    } else if (/opr\\/|opios/i.test(ua)) {\n      // a new Opera\n      result = {\n        name: 'Opera'\n        , opera: t\n        , version: getFirstMatch(/(?:opr|opios)[\\s\\/](\\d+(\\.\\d+)?)/i) || versionIdentifier\n      }\n    }\n    else if (/SamsungBrowser/i.test(ua)) {\n      result = {\n        name: 'Samsung Internet for Android'\n        , samsungBrowser: t\n        , version: versionIdentifier || getFirstMatch(/(?:SamsungBrowser)[\\s\\/](\\d+(\\.\\d+)?)/i)\n      }\n    }\n    else if (/coast/i.test(ua)) {\n      result = {\n        name: 'Opera Coast'\n        , coast: t\n        , version: versionIdentifier || getFirstMatch(/(?:coast)[\\s\\/](\\d+(\\.\\d+)?)/i)\n      }\n    }\n    else if (/yabrowser/i.test(ua)) {\n      result = {\n        name: 'Yandex Browser'\n      , yandexbrowser: t\n      , version: versionIdentifier || getFirstMatch(/(?:yabrowser)[\\s\\/](\\d+(\\.\\d+)?)/i)\n      }\n    }\n    else if (/ucbrowser/i.test(ua)) {\n      result = {\n          name: 'UC Browser'\n        , ucbrowser: t\n        , version: getFirstMatch(/(?:ucbrowser)[\\s\\/](\\d+(?:\\.\\d+)+)/i)\n      }\n    }\n    else if (/mxios/i.test(ua)) {\n      result = {\n        name: 'Maxthon'\n        , maxthon: t\n        , version: getFirstMatch(/(?:mxios)[\\s\\/](\\d+(?:\\.\\d+)+)/i)\n      }\n    }\n    else if (/epiphany/i.test(ua)) {\n      result = {\n        name: 'Epiphany'\n        , epiphany: t\n        , version: getFirstMatch(/(?:epiphany)[\\s\\/](\\d+(?:\\.\\d+)+)/i)\n      }\n    }\n    else if (/puffin/i.test(ua)) {\n      result = {\n        name: 'Puffin'\n        , puffin: t\n        , version: getFirstMatch(/(?:puffin)[\\s\\/](\\d+(?:\\.\\d+)?)/i)\n      }\n    }\n    else if (/sleipnir/i.test(ua)) {\n      result = {\n        name: 'Sleipnir'\n        , sleipnir: t\n        , version: getFirstMatch(/(?:sleipnir)[\\s\\/](\\d+(?:\\.\\d+)+)/i)\n      }\n    }\n    else if (/k-meleon/i.test(ua)) {\n      result = {\n        name: 'K-Meleon'\n        , kMeleon: t\n        , version: getFirstMatch(/(?:k-meleon)[\\s\\/](\\d+(?:\\.\\d+)+)/i)\n      }\n    }\n    else if (windowsphone) {\n      result = {\n        name: 'Windows Phone'\n      , osname: 'Windows Phone'\n      , windowsphone: t\n      }\n      if (edgeVersion) {\n        result.msedge = t\n        result.version = edgeVersion\n      }\n      else {\n        result.msie = t\n        result.version = getFirstMatch(/iemobile\\/(\\d+(\\.\\d+)?)/i)\n      }\n    }\n    else if (/msie|trident/i.test(ua)) {\n      result = {\n        name: 'Internet Explorer'\n      , msie: t\n      , version: getFirstMatch(/(?:msie |rv:)(\\d+(\\.\\d+)?)/i)\n      }\n    } else if (chromeos) {\n      result = {\n        name: 'Chrome'\n      , osname: 'Chrome OS'\n      , chromeos: t\n      , chromeBook: t\n      , chrome: t\n      , version: getFirstMatch(/(?:chrome|crios|crmo)\\/(\\d+(\\.\\d+)?)/i)\n      }\n    } else if (/edg([ea]|ios)/i.test(ua)) {\n      result = {\n        name: 'Microsoft Edge'\n      , msedge: t\n      , version: edgeVersion\n      }\n    }\n    else if (/vivaldi/i.test(ua)) {\n      result = {\n        name: 'Vivaldi'\n        , vivaldi: t\n        , version: getFirstMatch(/vivaldi\\/(\\d+(\\.\\d+)?)/i) || versionIdentifier\n      }\n    }\n    else if (sailfish) {\n      result = {\n        name: 'Sailfish'\n      , osname: 'Sailfish OS'\n      , sailfish: t\n      , version: getFirstMatch(/sailfish\\s?browser\\/(\\d+(\\.\\d+)?)/i)\n      }\n    }\n    else if (/seamonkey\\//i.test(ua)) {\n      result = {\n        name: 'SeaMonkey'\n      , seamonkey: t\n      , version: getFirstMatch(/seamonkey\\/(\\d+(\\.\\d+)?)/i)\n      }\n    }\n    else if (/firefox|iceweasel|fxios/i.test(ua)) {\n      result = {\n        name: 'Firefox'\n      , firefox: t\n      , version: getFirstMatch(/(?:firefox|iceweasel|fxios)[ \\/](\\d+(\\.\\d+)?)/i)\n      }\n      if (/\\((mobile|tablet);[^\\)]*rv:[\\d\\.]+\\)/i.test(ua)) {\n        result.firefoxos = t\n        result.osname = 'Firefox OS'\n      }\n    }\n    else if (silk) {\n      result =  {\n        name: 'Amazon Silk'\n      , silk: t\n      , version : getFirstMatch(/silk\\/(\\d+(\\.\\d+)?)/i)\n      }\n    }\n    else if (/phantom/i.test(ua)) {\n      result = {\n        name: 'PhantomJS'\n      , phantom: t\n      , version: getFirstMatch(/phantomjs\\/(\\d+(\\.\\d+)?)/i)\n      }\n    }\n    else if (/slimerjs/i.test(ua)) {\n      result = {\n        name: 'SlimerJS'\n        , slimer: t\n        , version: getFirstMatch(/slimerjs\\/(\\d+(\\.\\d+)?)/i)\n      }\n    }\n    else if (/blackberry|\\bbb\\d+/i.test(ua) || /rim\\stablet/i.test(ua)) {\n      result = {\n        name: 'BlackBerry'\n      , osname: 'BlackBerry OS'\n      , blackberry: t\n      , version: versionIdentifier || getFirstMatch(/blackberry[\\d]+\\/(\\d+(\\.\\d+)?)/i)\n      }\n    }\n    else if (webos) {\n      result = {\n        name: 'WebOS'\n      , osname: 'WebOS'\n      , webos: t\n      , version: versionIdentifier || getFirstMatch(/w(?:eb)?osbrowser\\/(\\d+(\\.\\d+)?)/i)\n      };\n      /touchpad\\//i.test(ua) && (result.touchpad = t)\n    }\n    else if (/bada/i.test(ua)) {\n      result = {\n        name: 'Bada'\n      , osname: 'Bada'\n      , bada: t\n      , version: getFirstMatch(/dolfin\\/(\\d+(\\.\\d+)?)/i)\n      };\n    }\n    else if (tizen) {\n      result = {\n        name: 'Tizen'\n      , osname: 'Tizen'\n      , tizen: t\n      , version: getFirstMatch(/(?:tizen\\s?)?browser\\/(\\d+(\\.\\d+)?)/i) || versionIdentifier\n      };\n    }\n    else if (/qupzilla/i.test(ua)) {\n      result = {\n        name: 'QupZilla'\n        , qupzilla: t\n        , version: getFirstMatch(/(?:qupzilla)[\\s\\/](\\d+(?:\\.\\d+)+)/i) || versionIdentifier\n      }\n    }\n    else if (/chromium/i.test(ua)) {\n      result = {\n        name: 'Chromium'\n        , chromium: t\n        , version: getFirstMatch(/(?:chromium)[\\s\\/](\\d+(?:\\.\\d+)?)/i) || versionIdentifier\n      }\n    }\n    else if (/chrome|crios|crmo/i.test(ua)) {\n      result = {\n        name: 'Chrome'\n        , chrome: t\n        , version: getFirstMatch(/(?:chrome|crios|crmo)\\/(\\d+(\\.\\d+)?)/i)\n      }\n    }\n    else if (android) {\n      result = {\n        name: 'Android'\n        , version: versionIdentifier\n      }\n    }\n    else if (/safari|applewebkit/i.test(ua)) {\n      result = {\n        name: 'Safari'\n      , safari: t\n      }\n      if (versionIdentifier) {\n        result.version = versionIdentifier\n      }\n    }\n    else if (iosdevice) {\n      result = {\n        name : iosdevice == 'iphone' ? 'iPhone' : iosdevice == 'ipad' ? 'iPad' : 'iPod'\n      }\n      // WTF: version is not part of user agent in web apps\n      if (versionIdentifier) {\n        result.version = versionIdentifier\n      }\n    }\n    else if(/googlebot/i.test(ua)) {\n      result = {\n        name: 'Googlebot'\n      , googlebot: t\n      , version: getFirstMatch(/googlebot\\/(\\d+(\\.\\d+))/i) || versionIdentifier\n      }\n    }\n    else {\n      result = {\n        name: getFirstMatch(/^(.*)\\/(.*) /),\n        version: getSecondMatch(/^(.*)\\/(.*) /)\n     };\n   }\n\n    // set webkit or gecko flag for browsers based on these engines\n    if (!result.msedge && /(apple)?webkit/i.test(ua)) {\n      if (/(apple)?webkit\\/537\\.36/i.test(ua)) {\n        result.name = result.name || \"Blink\"\n        result.blink = t\n      } else {\n        result.name = result.name || \"Webkit\"\n        result.webkit = t\n      }\n      if (!result.version && versionIdentifier) {\n        result.version = versionIdentifier\n      }\n    } else if (!result.opera && /gecko\\//i.test(ua)) {\n      result.name = result.name || \"Gecko\"\n      result.gecko = t\n      result.version = result.version || getFirstMatch(/gecko\\/(\\d+(\\.\\d+)?)/i)\n    }\n\n    // set OS flags for platforms that have multiple browsers\n    if (!result.windowsphone && (android || result.silk)) {\n      result.android = t\n      result.osname = 'Android'\n    } else if (!result.windowsphone && iosdevice) {\n      result[iosdevice] = t\n      result.ios = t\n      result.osname = 'iOS'\n    } else if (mac) {\n      result.mac = t\n      result.osname = 'macOS'\n    } else if (xbox) {\n      result.xbox = t\n      result.osname = 'Xbox'\n    } else if (windows) {\n      result.windows = t\n      result.osname = 'Windows'\n    } else if (linux) {\n      result.linux = t\n      result.osname = 'Linux'\n    }\n\n    function getWindowsVersion (s) {\n      switch (s) {\n        case 'NT': return 'NT'\n        case 'XP': return 'XP'\n        case 'NT 5.0': return '2000'\n        case 'NT 5.1': return 'XP'\n        case 'NT 5.2': return '2003'\n        case 'NT 6.0': return 'Vista'\n        case 'NT 6.1': return '7'\n        case 'NT 6.2': return '8'\n        case 'NT 6.3': return '8.1'\n        case 'NT 10.0': return '10'\n        default: return undefined\n      }\n    }\n\n    // OS version extraction\n    var osVersion = '';\n    if (result.windows) {\n      osVersion = getWindowsVersion(getFirstMatch(/Windows ((NT|XP)( \\d\\d?.\\d)?)/i))\n    } else if (result.windowsphone) {\n      osVersion = getFirstMatch(/windows phone (?:os)?\\s?(\\d+(\\.\\d+)*)/i);\n    } else if (result.mac) {\n      osVersion = getFirstMatch(/Mac OS X (\\d+([_\\.\\s]\\d+)*)/i);\n      osVersion = osVersion.replace(/[_\\s]/g, '.');\n    } else if (iosdevice) {\n      osVersion = getFirstMatch(/os (\\d+([_\\s]\\d+)*) like mac os x/i);\n      osVersion = osVersion.replace(/[_\\s]/g, '.');\n    } else if (android) {\n      osVersion = getFirstMatch(/android[ \\/-](\\d+(\\.\\d+)*)/i);\n    } else if (result.webos) {\n      osVersion = getFirstMatch(/(?:web|hpw)os\\/(\\d+(\\.\\d+)*)/i);\n    } else if (result.blackberry) {\n      osVersion = getFirstMatch(/rim\\stablet\\sos\\s(\\d+(\\.\\d+)*)/i);\n    } else if (result.bada) {\n      osVersion = getFirstMatch(/bada\\/(\\d+(\\.\\d+)*)/i);\n    } else if (result.tizen) {\n      osVersion = getFirstMatch(/tizen[\\/\\s](\\d+(\\.\\d+)*)/i);\n    }\n    if (osVersion) {\n      result.osversion = osVersion;\n    }\n\n    // device type extraction\n    var osMajorVersion = !result.windows && osVersion.split('.')[0];\n    if (\n         tablet\n      || nexusTablet\n      || iosdevice == 'ipad'\n      || (android && (osMajorVersion == 3 || (osMajorVersion >= 4 && !mobile)))\n      || result.silk\n    ) {\n      result.tablet = t\n    } else if (\n         mobile\n      || iosdevice == 'iphone'\n      || iosdevice == 'ipod'\n      || android\n      || nexusMobile\n      || result.blackberry\n      || result.webos\n      || result.bada\n    ) {\n      result.mobile = t\n    }\n\n    // Graded Browser Support\n    // http://developer.yahoo.com/yui/articles/gbs\n    if (result.msedge ||\n        (result.msie && result.version >= 10) ||\n        (result.yandexbrowser && result.version >= 15) ||\n\t\t    (result.vivaldi && result.version >= 1.0) ||\n        (result.chrome && result.version >= 20) ||\n        (result.samsungBrowser && result.version >= 4) ||\n        (result.firefox && result.version >= 20.0) ||\n        (result.safari && result.version >= 6) ||\n        (result.opera && result.version >= 10.0) ||\n        (result.ios && result.osversion && result.osversion.split(\".\")[0] >= 6) ||\n        (result.blackberry && result.version >= 10.1)\n        || (result.chromium && result.version >= 20)\n        ) {\n      result.a = t;\n    }\n    else if ((result.msie && result.version < 10) ||\n        (result.chrome && result.version < 20) ||\n        (result.firefox && result.version < 20.0) ||\n        (result.safari && result.version < 6) ||\n        (result.opera && result.version < 10.0) ||\n        (result.ios && result.osversion && result.osversion.split(\".\")[0] < 6)\n        || (result.chromium && result.version < 20)\n        ) {\n      result.c = t\n    } else result.x = t\n\n    return result\n  }\n\n  var bowser = detect(typeof navigator !== 'undefined' ? navigator.userAgent || '' : '')\n\n  bowser.test = function (browserList) {\n    for (var i = 0; i < browserList.length; ++i) {\n      var browserItem = browserList[i];\n      if (typeof browserItem=== 'string') {\n        if (browserItem in bowser) {\n          return true;\n        }\n      }\n    }\n    return false;\n  }\n\n  /**\n   * Get version precisions count\n   *\n   * @example\n   *   getVersionPrecision(\"1.10.3\") // 3\n   *\n   * @param  {string} version\n   * @return {number}\n   */\n  function getVersionPrecision(version) {\n    return version.split(\".\").length;\n  }\n\n  /**\n   * Array::map polyfill\n   *\n   * @param  {Array} arr\n   * @param  {Function} iterator\n   * @return {Array}\n   */\n  function map(arr, iterator) {\n    var result = [], i;\n    if (Array.prototype.map) {\n      return Array.prototype.map.call(arr, iterator);\n    }\n    for (i = 0; i < arr.length; i++) {\n      result.push(iterator(arr[i]));\n    }\n    return result;\n  }\n\n  /**\n   * Calculate browser version weight\n   *\n   * @example\n   *   compareVersions(['1.10.2.1',  '1.8.2.1.90'])    // 1\n   *   compareVersions(['1.010.2.1', '1.09.2.1.90']);  // 1\n   *   compareVersions(['1.10.2.1',  '1.10.2.1']);     // 0\n   *   compareVersions(['1.10.2.1',  '1.0800.2']);     // -1\n   *\n   * @param  {Array<String>} versions versions to compare\n   * @return {Number} comparison result\n   */\n  function compareVersions(versions) {\n    // 1) get common precision for both versions, for example for \"10.0\" and \"9\" it should be 2\n    var precision = Math.max(getVersionPrecision(versions[0]), getVersionPrecision(versions[1]));\n    var chunks = map(versions, function (version) {\n      var delta = precision - getVersionPrecision(version);\n\n      // 2) \"9\" -> \"9.0\" (for precision = 2)\n      version = version + new Array(delta + 1).join(\".0\");\n\n      // 3) \"9.0\" -> [\"000000000\"\", \"000000009\"]\n      return map(version.split(\".\"), function (chunk) {\n        return new Array(20 - chunk.length).join(\"0\") + chunk;\n      }).reverse();\n    });\n\n    // iterate in reverse order by reversed chunks array\n    while (--precision >= 0) {\n      // 4) compare: \"000000009\" > \"000000010\" = false (but \"9\" > \"10\" = true)\n      if (chunks[0][precision] > chunks[1][precision]) {\n        return 1;\n      }\n      else if (chunks[0][precision] === chunks[1][precision]) {\n        if (precision === 0) {\n          // all version chunks are same\n          return 0;\n        }\n      }\n      else {\n        return -1;\n      }\n    }\n  }\n\n  /**\n   * Check if browser is unsupported\n   *\n   * @example\n   *   bowser.isUnsupportedBrowser({\n   *     msie: \"10\",\n   *     firefox: \"23\",\n   *     chrome: \"29\",\n   *     safari: \"5.1\",\n   *     opera: \"16\",\n   *     phantom: \"534\"\n   *   });\n   *\n   * @param  {Object}  minVersions map of minimal version to browser\n   * @param  {Boolean} [strictMode = false] flag to return false if browser wasn't found in map\n   * @param  {String}  [ua] user agent string\n   * @return {Boolean}\n   */\n  function isUnsupportedBrowser(minVersions, strictMode, ua) {\n    var _bowser = bowser;\n\n    // make strictMode param optional with ua param usage\n    if (typeof strictMode === 'string') {\n      ua = strictMode;\n      strictMode = void(0);\n    }\n\n    if (strictMode === void(0)) {\n      strictMode = false;\n    }\n    if (ua) {\n      _bowser = detect(ua);\n    }\n\n    var version = \"\" + _bowser.version;\n    for (var browser in minVersions) {\n      if (minVersions.hasOwnProperty(browser)) {\n        if (_bowser[browser]) {\n          if (typeof minVersions[browser] !== 'string') {\n            throw new Error('Browser version in the minVersion map should be a string: ' + browser + ': ' + String(minVersions));\n          }\n\n          // browser version and min supported version.\n          return compareVersions([version, minVersions[browser]]) < 0;\n        }\n      }\n    }\n\n    return strictMode; // not found\n  }\n\n  /**\n   * Check if browser is supported\n   *\n   * @param  {Object} minVersions map of minimal version to browser\n   * @param  {Boolean} [strictMode = false] flag to return false if browser wasn't found in map\n   * @param  {String}  [ua] user agent string\n   * @return {Boolean}\n   */\n  function check(minVersions, strictMode, ua) {\n    return !isUnsupportedBrowser(minVersions, strictMode, ua);\n  }\n\n  bowser.isUnsupportedBrowser = isUnsupportedBrowser;\n  bowser.compareVersions = compareVersions;\n  bowser.check = check;\n\n  /*\n   * Set our detect method to the main bowser object so we can\n   * reuse it to test other user agents.\n   * This is needed to implement future tests.\n   */\n  bowser._detect = detect;\n\n  /*\n   * Set our detect public method to the main bowser object\n   * This is needed to implement bowser in server side\n   */\n  bowser.detect = detect;\n  return bowser\n});\n\n\n/***/ }),\n/* 42 */\n/***/ (function(module, exports) {\n\nmodule.exports = function() {\n\tthrow new Error(\"define cannot be used indirect\");\n};\n\n\n/***/ }),\n/* 43 */\n/***/ (function(module, exports, __webpack_require__) {\n\n\"use strict\";\n\n\nObject.defineProperty(exports, \"__esModule\", {\n    value: true\n});\n\nvar _cryptoJs = __webpack_require__(9);\n\nvar _cryptoJs2 = _interopRequireDefault(_cryptoJs);\n\nfunction _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }\n\nexports.default = {\n    stringify: function stringify(wordArray) {\n        // Shortcuts\n        var words = wordArray.words;\n        var sigBytes = wordArray.sigBytes;\n        // Convert\n        var u8 = new Uint8Array(sigBytes);\n        for (var i = 0; i < sigBytes; i++) {\n            var byte = words[i >>> 2] >>> 24 - i % 4 * 8 & 0xff;\n            u8[i] = byte;\n        }\n        return u8;\n    },\n    parse: function parse(u8arr) {\n        // Shortcut\n        var len = u8arr.length;\n        // Convert\n        var words = new Array();\n        for (var i = 0; i < len; i++) {\n            words[i >>> 2] |= (u8arr[i] & 0xff) << 24 - i % 4 * 8;\n        }\n        return _cryptoJs2.default.lib.WordArray.create(words, len);\n    }\n};\n\n/***/ }),\n/* 44 */\n/***/ (function(module, exports, __webpack_require__) {\n\n/* WEBPACK VAR INJECTION */(function(process, global) {/*!\n * @overview es6-promise - a tiny implementation of Promises/A+.\n * @copyright Copyright (c) 2014 Yehuda Katz, Tom Dale, Stefan Penner and contributors (Conversion to ES6 API by Jake Archibald)\n * @license   Licensed under MIT license\n *            See https://raw.githubusercontent.com/stefanpenner/es6-promise/master/LICENSE\n * @version   v4.2.4+314e4831\n */\n\n(function (global, factory) {\n\t true ? module.exports = factory() :\n\tundefined;\n}(this, (function () { 'use strict';\n\nfunction objectOrFunction(x) {\n  var type = typeof x;\n  return x !== null && (type === 'object' || type === 'function');\n}\n\nfunction isFunction(x) {\n  return typeof x === 'function';\n}\n\n\n\nvar _isArray = void 0;\nif (Array.isArray) {\n  _isArray = Array.isArray;\n} else {\n  _isArray = function (x) {\n    return Object.prototype.toString.call(x) === '[object Array]';\n  };\n}\n\nvar isArray = _isArray;\n\nvar len = 0;\nvar vertxNext = void 0;\nvar customSchedulerFn = void 0;\n\nvar asap = function asap(callback, arg) {\n  queue[len] = callback;\n  queue[len + 1] = arg;\n  len += 2;\n  if (len === 2) {\n    // If len is 2, that means that we need to schedule an async flush.\n    // If additional callbacks are queued before the queue is flushed, they\n    // will be processed by this flush that we are scheduling.\n    if (customSchedulerFn) {\n      customSchedulerFn(flush);\n    } else {\n      scheduleFlush();\n    }\n  }\n};\n\nfunction setScheduler(scheduleFn) {\n  customSchedulerFn = scheduleFn;\n}\n\nfunction setAsap(asapFn) {\n  asap = asapFn;\n}\n\nvar browserWindow = typeof window !== 'undefined' ? window : undefined;\nvar browserGlobal = browserWindow || {};\nvar BrowserMutationObserver = browserGlobal.MutationObserver || browserGlobal.WebKitMutationObserver;\nvar isNode = typeof self === 'undefined' && typeof process !== 'undefined' && {}.toString.call(process) === '[object process]';\n\n// test for web worker but not in IE10\nvar isWorker = typeof Uint8ClampedArray !== 'undefined' && typeof importScripts !== 'undefined' && typeof MessageChannel !== 'undefined';\n\n// node\nfunction useNextTick() {\n  // node version 0.10.x displays a deprecation warning when nextTick is used recursively\n  // see https://github.com/cujojs/when/issues/410 for details\n  return function () {\n    return process.nextTick(flush);\n  };\n}\n\n// vertx\nfunction useVertxTimer() {\n  if (typeof vertxNext !== 'undefined') {\n    return function () {\n      vertxNext(flush);\n    };\n  }\n\n  return useSetTimeout();\n}\n\nfunction useMutationObserver() {\n  var iterations = 0;\n  var observer = new BrowserMutationObserver(flush);\n  var node = document.createTextNode('');\n  observer.observe(node, { characterData: true });\n\n  return function () {\n    node.data = iterations = ++iterations % 2;\n  };\n}\n\n// web worker\nfunction useMessageChannel() {\n  var channel = new MessageChannel();\n  channel.port1.onmessage = flush;\n  return function () {\n    return channel.port2.postMessage(0);\n  };\n}\n\nfunction useSetTimeout() {\n  // Store setTimeout reference so es6-promise will be unaffected by\n  // other code modifying setTimeout (like sinon.useFakeTimers())\n  var globalSetTimeout = setTimeout;\n  return function () {\n    return globalSetTimeout(flush, 1);\n  };\n}\n\nvar queue = new Array(1000);\nfunction flush() {\n  for (var i = 0; i < len; i += 2) {\n    var callback = queue[i];\n    var arg = queue[i + 1];\n\n    callback(arg);\n\n    queue[i] = undefined;\n    queue[i + 1] = undefined;\n  }\n\n  len = 0;\n}\n\nfunction attemptVertx() {\n  try {\n    var vertx = Function('return this')().require('vertx');\n    vertxNext = vertx.runOnLoop || vertx.runOnContext;\n    return useVertxTimer();\n  } catch (e) {\n    return useSetTimeout();\n  }\n}\n\nvar scheduleFlush = void 0;\n// Decide what async method to use to triggering processing of queued callbacks:\nif (isNode) {\n  scheduleFlush = useNextTick();\n} else if (BrowserMutationObserver) {\n  scheduleFlush = useMutationObserver();\n} else if (isWorker) {\n  scheduleFlush = useMessageChannel();\n} else if (browserWindow === undefined && \"function\" === 'function') {\n  scheduleFlush = attemptVertx();\n} else {\n  scheduleFlush = useSetTimeout();\n}\n\nfunction then(onFulfillment, onRejection) {\n  var parent = this;\n\n  var child = new this.constructor(noop);\n\n  if (child[PROMISE_ID] === undefined) {\n    makePromise(child);\n  }\n\n  var _state = parent._state;\n\n\n  if (_state) {\n    var callback = arguments[_state - 1];\n    asap(function () {\n      return invokeCallback(_state, child, callback, parent._result);\n    });\n  } else {\n    subscribe(parent, child, onFulfillment, onRejection);\n  }\n\n  return child;\n}\n\n/**\n  `Promise.resolve` returns a promise that will become resolved with the\n  passed `value`. It is shorthand for the following:\n\n  ```javascript\n  let promise = new Promise(function(resolve, reject){\n    resolve(1);\n  });\n\n  promise.then(function(value){\n    // value === 1\n  });\n  ```\n\n  Instead of writing the above, your code now simply becomes the following:\n\n  ```javascript\n  let promise = Promise.resolve(1);\n\n  promise.then(function(value){\n    // value === 1\n  });\n  ```\n\n  @method resolve\n  @static\n  @param {Any} value value that the returned promise will be resolved with\n  Useful for tooling.\n  @return {Promise} a promise that will become fulfilled with the given\n  `value`\n*/\nfunction resolve$1(object) {\n  /*jshint validthis:true */\n  var Constructor = this;\n\n  if (object && typeof object === 'object' && object.constructor === Constructor) {\n    return object;\n  }\n\n  var promise = new Constructor(noop);\n  resolve(promise, object);\n  return promise;\n}\n\nvar PROMISE_ID = Math.random().toString(36).substring(2);\n\nfunction noop() {}\n\nvar PENDING = void 0;\nvar FULFILLED = 1;\nvar REJECTED = 2;\n\nvar TRY_CATCH_ERROR = { error: null };\n\nfunction selfFulfillment() {\n  return new TypeError(\"You cannot resolve a promise with itself\");\n}\n\nfunction cannotReturnOwn() {\n  return new TypeError('A promises callback cannot return that same promise.');\n}\n\nfunction getThen(promise) {\n  try {\n    return promise.then;\n  } catch (error) {\n    TRY_CATCH_ERROR.error = error;\n    return TRY_CATCH_ERROR;\n  }\n}\n\nfunction tryThen(then$$1, value, fulfillmentHandler, rejectionHandler) {\n  try {\n    then$$1.call(value, fulfillmentHandler, rejectionHandler);\n  } catch (e) {\n    return e;\n  }\n}\n\nfunction handleForeignThenable(promise, thenable, then$$1) {\n  asap(function (promise) {\n    var sealed = false;\n    var error = tryThen(then$$1, thenable, function (value) {\n      if (sealed) {\n        return;\n      }\n      sealed = true;\n      if (thenable !== value) {\n        resolve(promise, value);\n      } else {\n        fulfill(promise, value);\n      }\n    }, function (reason) {\n      if (sealed) {\n        return;\n      }\n      sealed = true;\n\n      reject(promise, reason);\n    }, 'Settle: ' + (promise._label || ' unknown promise'));\n\n    if (!sealed && error) {\n      sealed = true;\n      reject(promise, error);\n    }\n  }, promise);\n}\n\nfunction handleOwnThenable(promise, thenable) {\n  if (thenable._state === FULFILLED) {\n    fulfill(promise, thenable._result);\n  } else if (thenable._state === REJECTED) {\n    reject(promise, thenable._result);\n  } else {\n    subscribe(thenable, undefined, function (value) {\n      return resolve(promise, value);\n    }, function (reason) {\n      return reject(promise, reason);\n    });\n  }\n}\n\nfunction handleMaybeThenable(promise, maybeThenable, then$$1) {\n  if (maybeThenable.constructor === promise.constructor && then$$1 === then && maybeThenable.constructor.resolve === resolve$1) {\n    handleOwnThenable(promise, maybeThenable);\n  } else {\n    if (then$$1 === TRY_CATCH_ERROR) {\n      reject(promise, TRY_CATCH_ERROR.error);\n      TRY_CATCH_ERROR.error = null;\n    } else if (then$$1 === undefined) {\n      fulfill(promise, maybeThenable);\n    } else if (isFunction(then$$1)) {\n      handleForeignThenable(promise, maybeThenable, then$$1);\n    } else {\n      fulfill(promise, maybeThenable);\n    }\n  }\n}\n\nfunction resolve(promise, value) {\n  if (promise === value) {\n    reject(promise, selfFulfillment());\n  } else if (objectOrFunction(value)) {\n    handleMaybeThenable(promise, value, getThen(value));\n  } else {\n    fulfill(promise, value);\n  }\n}\n\nfunction publishRejection(promise) {\n  if (promise._onerror) {\n    promise._onerror(promise._result);\n  }\n\n  publish(promise);\n}\n\nfunction fulfill(promise, value) {\n  if (promise._state !== PENDING) {\n    return;\n  }\n\n  promise._result = value;\n  promise._state = FULFILLED;\n\n  if (promise._subscribers.length !== 0) {\n    asap(publish, promise);\n  }\n}\n\nfunction reject(promise, reason) {\n  if (promise._state !== PENDING) {\n    return;\n  }\n  promise._state = REJECTED;\n  promise._result = reason;\n\n  asap(publishRejection, promise);\n}\n\nfunction subscribe(parent, child, onFulfillment, onRejection) {\n  var _subscribers = parent._subscribers;\n  var length = _subscribers.length;\n\n\n  parent._onerror = null;\n\n  _subscribers[length] = child;\n  _subscribers[length + FULFILLED] = onFulfillment;\n  _subscribers[length + REJECTED] = onRejection;\n\n  if (length === 0 && parent._state) {\n    asap(publish, parent);\n  }\n}\n\nfunction publish(promise) {\n  var subscribers = promise._subscribers;\n  var settled = promise._state;\n\n  if (subscribers.length === 0) {\n    return;\n  }\n\n  var child = void 0,\n      callback = void 0,\n      detail = promise._result;\n\n  for (var i = 0; i < subscribers.length; i += 3) {\n    child = subscribers[i];\n    callback = subscribers[i + settled];\n\n    if (child) {\n      invokeCallback(settled, child, callback, detail);\n    } else {\n      callback(detail);\n    }\n  }\n\n  promise._subscribers.length = 0;\n}\n\nfunction tryCatch(callback, detail) {\n  try {\n    return callback(detail);\n  } catch (e) {\n    TRY_CATCH_ERROR.error = e;\n    return TRY_CATCH_ERROR;\n  }\n}\n\nfunction invokeCallback(settled, promise, callback, detail) {\n  var hasCallback = isFunction(callback),\n      value = void 0,\n      error = void 0,\n      succeeded = void 0,\n      failed = void 0;\n\n  if (hasCallback) {\n    value = tryCatch(callback, detail);\n\n    if (value === TRY_CATCH_ERROR) {\n      failed = true;\n      error = value.error;\n      value.error = null;\n    } else {\n      succeeded = true;\n    }\n\n    if (promise === value) {\n      reject(promise, cannotReturnOwn());\n      return;\n    }\n  } else {\n    value = detail;\n    succeeded = true;\n  }\n\n  if (promise._state !== PENDING) {\n    // noop\n  } else if (hasCallback && succeeded) {\n    resolve(promise, value);\n  } else if (failed) {\n    reject(promise, error);\n  } else if (settled === FULFILLED) {\n    fulfill(promise, value);\n  } else if (settled === REJECTED) {\n    reject(promise, value);\n  }\n}\n\nfunction initializePromise(promise, resolver) {\n  try {\n    resolver(function resolvePromise(value) {\n      resolve(promise, value);\n    }, function rejectPromise(reason) {\n      reject(promise, reason);\n    });\n  } catch (e) {\n    reject(promise, e);\n  }\n}\n\nvar id = 0;\nfunction nextId() {\n  return id++;\n}\n\nfunction makePromise(promise) {\n  promise[PROMISE_ID] = id++;\n  promise._state = undefined;\n  promise._result = undefined;\n  promise._subscribers = [];\n}\n\nfunction validationError() {\n  return new Error('Array Methods must be provided an Array');\n}\n\nvar Enumerator = function () {\n  function Enumerator(Constructor, input) {\n    this._instanceConstructor = Constructor;\n    this.promise = new Constructor(noop);\n\n    if (!this.promise[PROMISE_ID]) {\n      makePromise(this.promise);\n    }\n\n    if (isArray(input)) {\n      this.length = input.length;\n      this._remaining = input.length;\n\n      this._result = new Array(this.length);\n\n      if (this.length === 0) {\n        fulfill(this.promise, this._result);\n      } else {\n        this.length = this.length || 0;\n        this._enumerate(input);\n        if (this._remaining === 0) {\n          fulfill(this.promise, this._result);\n        }\n      }\n    } else {\n      reject(this.promise, validationError());\n    }\n  }\n\n  Enumerator.prototype._enumerate = function _enumerate(input) {\n    for (var i = 0; this._state === PENDING && i < input.length; i++) {\n      this._eachEntry(input[i], i);\n    }\n  };\n\n  Enumerator.prototype._eachEntry = function _eachEntry(entry, i) {\n    var c = this._instanceConstructor;\n    var resolve$$1 = c.resolve;\n\n\n    if (resolve$$1 === resolve$1) {\n      var _then = getThen(entry);\n\n      if (_then === then && entry._state !== PENDING) {\n        this._settledAt(entry._state, i, entry._result);\n      } else if (typeof _then !== 'function') {\n        this._remaining--;\n        this._result[i] = entry;\n      } else if (c === Promise$1) {\n        var promise = new c(noop);\n        handleMaybeThenable(promise, entry, _then);\n        this._willSettleAt(promise, i);\n      } else {\n        this._willSettleAt(new c(function (resolve$$1) {\n          return resolve$$1(entry);\n        }), i);\n      }\n    } else {\n      this._willSettleAt(resolve$$1(entry), i);\n    }\n  };\n\n  Enumerator.prototype._settledAt = function _settledAt(state, i, value) {\n    var promise = this.promise;\n\n\n    if (promise._state === PENDING) {\n      this._remaining--;\n\n      if (state === REJECTED) {\n        reject(promise, value);\n      } else {\n        this._result[i] = value;\n      }\n    }\n\n    if (this._remaining === 0) {\n      fulfill(promise, this._result);\n    }\n  };\n\n  Enumerator.prototype._willSettleAt = function _willSettleAt(promise, i) {\n    var enumerator = this;\n\n    subscribe(promise, undefined, function (value) {\n      return enumerator._settledAt(FULFILLED, i, value);\n    }, function (reason) {\n      return enumerator._settledAt(REJECTED, i, reason);\n    });\n  };\n\n  return Enumerator;\n}();\n\n/**\n  `Promise.all` accepts an array of promises, and returns a new promise which\n  is fulfilled with an array of fulfillment values for the passed promises, or\n  rejected with the reason of the first passed promise to be rejected. It casts all\n  elements of the passed iterable to promises as it runs this algorithm.\n\n  Example:\n\n  ```javascript\n  let promise1 = resolve(1);\n  let promise2 = resolve(2);\n  let promise3 = resolve(3);\n  let promises = [ promise1, promise2, promise3 ];\n\n  Promise.all(promises).then(function(array){\n    // The array here would be [ 1, 2, 3 ];\n  });\n  ```\n\n  If any of the `promises` given to `all` are rejected, the first promise\n  that is rejected will be given as an argument to the returned promises's\n  rejection handler. For example:\n\n  Example:\n\n  ```javascript\n  let promise1 = resolve(1);\n  let promise2 = reject(new Error(\"2\"));\n  let promise3 = reject(new Error(\"3\"));\n  let promises = [ promise1, promise2, promise3 ];\n\n  Promise.all(promises).then(function(array){\n    // Code here never runs because there are rejected promises!\n  }, function(error) {\n    // error.message === \"2\"\n  });\n  ```\n\n  @method all\n  @static\n  @param {Array} entries array of promises\n  @param {String} label optional string for labeling the promise.\n  Useful for tooling.\n  @return {Promise} promise that is fulfilled when all `promises` have been\n  fulfilled, or rejected if any of them become rejected.\n  @static\n*/\nfunction all(entries) {\n  return new Enumerator(this, entries).promise;\n}\n\n/**\n  `Promise.race` returns a new promise which is settled in the same way as the\n  first passed promise to settle.\n\n  Example:\n\n  ```javascript\n  let promise1 = new Promise(function(resolve, reject){\n    setTimeout(function(){\n      resolve('promise 1');\n    }, 200);\n  });\n\n  let promise2 = new Promise(function(resolve, reject){\n    setTimeout(function(){\n      resolve('promise 2');\n    }, 100);\n  });\n\n  Promise.race([promise1, promise2]).then(function(result){\n    // result === 'promise 2' because it was resolved before promise1\n    // was resolved.\n  });\n  ```\n\n  `Promise.race` is deterministic in that only the state of the first\n  settled promise matters. For example, even if other promises given to the\n  `promises` array argument are resolved, but the first settled promise has\n  become rejected before the other promises became fulfilled, the returned\n  promise will become rejected:\n\n  ```javascript\n  let promise1 = new Promise(function(resolve, reject){\n    setTimeout(function(){\n      resolve('promise 1');\n    }, 200);\n  });\n\n  let promise2 = new Promise(function(resolve, reject){\n    setTimeout(function(){\n      reject(new Error('promise 2'));\n    }, 100);\n  });\n\n  Promise.race([promise1, promise2]).then(function(result){\n    // Code here never runs\n  }, function(reason){\n    // reason.message === 'promise 2' because promise 2 became rejected before\n    // promise 1 became fulfilled\n  });\n  ```\n\n  An example real-world use case is implementing timeouts:\n\n  ```javascript\n  Promise.race([ajax('foo.json'), timeout(5000)])\n  ```\n\n  @method race\n  @static\n  @param {Array} promises array of promises to observe\n  Useful for tooling.\n  @return {Promise} a promise which settles in the same way as the first passed\n  promise to settle.\n*/\nfunction race(entries) {\n  /*jshint validthis:true */\n  var Constructor = this;\n\n  if (!isArray(entries)) {\n    return new Constructor(function (_, reject) {\n      return reject(new TypeError('You must pass an array to race.'));\n    });\n  } else {\n    return new Constructor(function (resolve, reject) {\n      var length = entries.length;\n      for (var i = 0; i < length; i++) {\n        Constructor.resolve(entries[i]).then(resolve, reject);\n      }\n    });\n  }\n}\n\n/**\n  `Promise.reject` returns a promise rejected with the passed `reason`.\n  It is shorthand for the following:\n\n  ```javascript\n  let promise = new Promise(function(resolve, reject){\n    reject(new Error('WHOOPS'));\n  });\n\n  promise.then(function(value){\n    // Code here doesn't run because the promise is rejected!\n  }, function(reason){\n    // reason.message === 'WHOOPS'\n  });\n  ```\n\n  Instead of writing the above, your code now simply becomes the following:\n\n  ```javascript\n  let promise = Promise.reject(new Error('WHOOPS'));\n\n  promise.then(function(value){\n    // Code here doesn't run because the promise is rejected!\n  }, function(reason){\n    // reason.message === 'WHOOPS'\n  });\n  ```\n\n  @method reject\n  @static\n  @param {Any} reason value that the returned promise will be rejected with.\n  Useful for tooling.\n  @return {Promise} a promise rejected with the given `reason`.\n*/\nfunction reject$1(reason) {\n  /*jshint validthis:true */\n  var Constructor = this;\n  var promise = new Constructor(noop);\n  reject(promise, reason);\n  return promise;\n}\n\nfunction needsResolver() {\n  throw new TypeError('You must pass a resolver function as the first argument to the promise constructor');\n}\n\nfunction needsNew() {\n  throw new TypeError(\"Failed to construct 'Promise': Please use the 'new' operator, this object constructor cannot be called as a function.\");\n}\n\n/**\n  Promise objects represent the eventual result of an asynchronous operation. The\n  primary way of interacting with a promise is through its `then` method, which\n  registers callbacks to receive either a promise's eventual value or the reason\n  why the promise cannot be fulfilled.\n\n  Terminology\n  -----------\n\n  - `promise` is an object or function with a `then` method whose behavior conforms to this specification.\n  - `thenable` is an object or function that defines a `then` method.\n  - `value` is any legal JavaScript value (including undefined, a thenable, or a promise).\n  - `exception` is a value that is thrown using the throw statement.\n  - `reason` is a value that indicates why a promise was rejected.\n  - `settled` the final resting state of a promise, fulfilled or rejected.\n\n  A promise can be in one of three states: pending, fulfilled, or rejected.\n\n  Promises that are fulfilled have a fulfillment value and are in the fulfilled\n  state.  Promises that are rejected have a rejection reason and are in the\n  rejected state.  A fulfillment value is never a thenable.\n\n  Promises can also be said to *resolve* a value.  If this value is also a\n  promise, then the original promise's settled state will match the value's\n  settled state.  So a promise that *resolves* a promise that rejects will\n  itself reject, and a promise that *resolves* a promise that fulfills will\n  itself fulfill.\n\n\n  Basic Usage:\n  ------------\n\n  ```js\n  let promise = new Promise(function(resolve, reject) {\n    // on success\n    resolve(value);\n\n    // on failure\n    reject(reason);\n  });\n\n  promise.then(function(value) {\n    // on fulfillment\n  }, function(reason) {\n    // on rejection\n  });\n  ```\n\n  Advanced Usage:\n  ---------------\n\n  Promises shine when abstracting away asynchronous interactions such as\n  `XMLHttpRequest`s.\n\n  ```js\n  function getJSON(url) {\n    return new Promise(function(resolve, reject){\n      let xhr = new XMLHttpRequest();\n\n      xhr.open('GET', url);\n      xhr.onreadystatechange = handler;\n      xhr.responseType = 'json';\n      xhr.setRequestHeader('Accept', 'application/json');\n      xhr.send();\n\n      function handler() {\n        if (this.readyState === this.DONE) {\n          if (this.status === 200) {\n            resolve(this.response);\n          } else {\n            reject(new Error('getJSON: `' + url + '` failed with status: [' + this.status + ']'));\n          }\n        }\n      };\n    });\n  }\n\n  getJSON('/posts.json').then(function(json) {\n    // on fulfillment\n  }, function(reason) {\n    // on rejection\n  });\n  ```\n\n  Unlike callbacks, promises are great composable primitives.\n\n  ```js\n  Promise.all([\n    getJSON('/posts'),\n    getJSON('/comments')\n  ]).then(function(values){\n    values[0] // => postsJSON\n    values[1] // => commentsJSON\n\n    return values;\n  });\n  ```\n\n  @class Promise\n  @param {Function} resolver\n  Useful for tooling.\n  @constructor\n*/\n\nvar Promise$1 = function () {\n  function Promise(resolver) {\n    this[PROMISE_ID] = nextId();\n    this._result = this._state = undefined;\n    this._subscribers = [];\n\n    if (noop !== resolver) {\n      typeof resolver !== 'function' && needsResolver();\n      this instanceof Promise ? initializePromise(this, resolver) : needsNew();\n    }\n  }\n\n  /**\n  The primary way of interacting with a promise is through its `then` method,\n  which registers callbacks to receive either a promise's eventual value or the\n  reason why the promise cannot be fulfilled.\n   ```js\n  findUser().then(function(user){\n    // user is available\n  }, function(reason){\n    // user is unavailable, and you are given the reason why\n  });\n  ```\n   Chaining\n  --------\n   The return value of `then` is itself a promise.  This second, 'downstream'\n  promise is resolved with the return value of the first promise's fulfillment\n  or rejection handler, or rejected if the handler throws an exception.\n   ```js\n  findUser().then(function (user) {\n    return user.name;\n  }, function (reason) {\n    return 'default name';\n  }).then(function (userName) {\n    // If `findUser` fulfilled, `userName` will be the user's name, otherwise it\n    // will be `'default name'`\n  });\n   findUser().then(function (user) {\n    throw new Error('Found user, but still unhappy');\n  }, function (reason) {\n    throw new Error('`findUser` rejected and we're unhappy');\n  }).then(function (value) {\n    // never reached\n  }, function (reason) {\n    // if `findUser` fulfilled, `reason` will be 'Found user, but still unhappy'.\n    // If `findUser` rejected, `reason` will be '`findUser` rejected and we're unhappy'.\n  });\n  ```\n  If the downstream promise does not specify a rejection handler, rejection reasons will be propagated further downstream.\n   ```js\n  findUser().then(function (user) {\n    throw new PedagogicalException('Upstream error');\n  }).then(function (value) {\n    // never reached\n  }).then(function (value) {\n    // never reached\n  }, function (reason) {\n    // The `PedgagocialException` is propagated all the way down to here\n  });\n  ```\n   Assimilation\n  ------------\n   Sometimes the value you want to propagate to a downstream promise can only be\n  retrieved asynchronously. This can be achieved by returning a promise in the\n  fulfillment or rejection handler. The downstream promise will then be pending\n  until the returned promise is settled. This is called *assimilation*.\n   ```js\n  findUser().then(function (user) {\n    return findCommentsByAuthor(user);\n  }).then(function (comments) {\n    // The user's comments are now available\n  });\n  ```\n   If the assimliated promise rejects, then the downstream promise will also reject.\n   ```js\n  findUser().then(function (user) {\n    return findCommentsByAuthor(user);\n  }).then(function (comments) {\n    // If `findCommentsByAuthor` fulfills, we'll have the value here\n  }, function (reason) {\n    // If `findCommentsByAuthor` rejects, we'll have the reason here\n  });\n  ```\n   Simple Example\n  --------------\n   Synchronous Example\n   ```javascript\n  let result;\n   try {\n    result = findResult();\n    // success\n  } catch(reason) {\n    // failure\n  }\n  ```\n   Errback Example\n   ```js\n  findResult(function(result, err){\n    if (err) {\n      // failure\n    } else {\n      // success\n    }\n  });\n  ```\n   Promise Example;\n   ```javascript\n  findResult().then(function(result){\n    // success\n  }, function(reason){\n    // failure\n  });\n  ```\n   Advanced Example\n  --------------\n   Synchronous Example\n   ```javascript\n  let author, books;\n   try {\n    author = findAuthor();\n    books  = findBooksByAuthor(author);\n    // success\n  } catch(reason) {\n    // failure\n  }\n  ```\n   Errback Example\n   ```js\n   function foundBooks(books) {\n   }\n   function failure(reason) {\n   }\n   findAuthor(function(author, err){\n    if (err) {\n      failure(err);\n      // failure\n    } else {\n      try {\n        findBoooksByAuthor(author, function(books, err) {\n          if (err) {\n            failure(err);\n          } else {\n            try {\n              foundBooks(books);\n            } catch(reason) {\n              failure(reason);\n            }\n          }\n        });\n      } catch(error) {\n        failure(err);\n      }\n      // success\n    }\n  });\n  ```\n   Promise Example;\n   ```javascript\n  findAuthor().\n    then(findBooksByAuthor).\n    then(function(books){\n      // found books\n  }).catch(function(reason){\n    // something went wrong\n  });\n  ```\n   @method then\n  @param {Function} onFulfilled\n  @param {Function} onRejected\n  Useful for tooling.\n  @return {Promise}\n  */\n\n  /**\n  `catch` is simply sugar for `then(undefined, onRejection)` which makes it the same\n  as the catch block of a try/catch statement.\n  ```js\n  function findAuthor(){\n  throw new Error('couldn't find that author');\n  }\n  // synchronous\n  try {\n  findAuthor();\n  } catch(reason) {\n  // something went wrong\n  }\n  // async with promises\n  findAuthor().catch(function(reason){\n  // something went wrong\n  });\n  ```\n  @method catch\n  @param {Function} onRejection\n  Useful for tooling.\n  @return {Promise}\n  */\n\n\n  Promise.prototype.catch = function _catch(onRejection) {\n    return this.then(null, onRejection);\n  };\n\n  /**\n    `finally` will be invoked regardless of the promise's fate just as native\n    try/catch/finally behaves\n  \n    Synchronous example:\n  \n    ```js\n    findAuthor() {\n      if (Math.random() > 0.5) {\n        throw new Error();\n      }\n      return new Author();\n    }\n  \n    try {\n      return findAuthor(); // succeed or fail\n    } catch(error) {\n      return findOtherAuther();\n    } finally {\n      // always runs\n      // doesn't affect the return value\n    }\n    ```\n  \n    Asynchronous example:\n  \n    ```js\n    findAuthor().catch(function(reason){\n      return findOtherAuther();\n    }).finally(function(){\n      // author was either found, or not\n    });\n    ```\n  \n    @method finally\n    @param {Function} callback\n    @return {Promise}\n  */\n\n\n  Promise.prototype.finally = function _finally(callback) {\n    var promise = this;\n    var constructor = promise.constructor;\n\n    return promise.then(function (value) {\n      return constructor.resolve(callback()).then(function () {\n        return value;\n      });\n    }, function (reason) {\n      return constructor.resolve(callback()).then(function () {\n        throw reason;\n      });\n    });\n  };\n\n  return Promise;\n}();\n\nPromise$1.prototype.then = then;\nPromise$1.all = all;\nPromise$1.race = race;\nPromise$1.resolve = resolve$1;\nPromise$1.reject = reject$1;\nPromise$1._setScheduler = setScheduler;\nPromise$1._setAsap = setAsap;\nPromise$1._asap = asap;\n\n/*global self*/\nfunction polyfill() {\n  var local = void 0;\n\n  if (typeof global !== 'undefined') {\n    local = global;\n  } else if (typeof self !== 'undefined') {\n    local = self;\n  } else {\n    try {\n      local = Function('return this')();\n    } catch (e) {\n      throw new Error('polyfill failed because global object is unavailable in this environment');\n    }\n  }\n\n  var P = local.Promise;\n\n  if (P) {\n    var promiseToString = null;\n    try {\n      promiseToString = Object.prototype.toString.call(P.resolve());\n    } catch (e) {\n      // silently ignored\n    }\n\n    if (promiseToString === '[object Promise]' && !P.cast) {\n      return;\n    }\n  }\n\n  local.Promise = Promise$1;\n}\n\n// Strange compat..\nPromise$1.polyfill = polyfill;\nPromise$1.Promise = Promise$1;\n\nreturn Promise$1;\n\n})));\n\n\n\n//# sourceMappingURL=es6-promise.map\n\n/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(45), __webpack_require__(8)))\n\n/***/ }),\n/* 45 */\n/***/ (function(module, exports) {\n\n// shim for using process in browser\nvar process = module.exports = {};\n\n// cached from whatever global is present so that test runners that stub it\n// don't break things.  But we need to wrap it in a try catch in case it is\n// wrapped in strict mode code which doesn't define any globals.  It's inside a\n// function because try/catches deoptimize in certain engines.\n\nvar cachedSetTimeout;\nvar cachedClearTimeout;\n\nfunction defaultSetTimout() {\n    throw new Error('setTimeout has not been defined');\n}\nfunction defaultClearTimeout () {\n    throw new Error('clearTimeout has not been defined');\n}\n(function () {\n    try {\n        if (typeof setTimeout === 'function') {\n            cachedSetTimeout = setTimeout;\n        } else {\n            cachedSetTimeout = defaultSetTimout;\n        }\n    } catch (e) {\n        cachedSetTimeout = defaultSetTimout;\n    }\n    try {\n        if (typeof clearTimeout === 'function') {\n            cachedClearTimeout = clearTimeout;\n        } else {\n            cachedClearTimeout = defaultClearTimeout;\n        }\n    } catch (e) {\n        cachedClearTimeout = defaultClearTimeout;\n    }\n} ())\nfunction runTimeout(fun) {\n    if (cachedSetTimeout === setTimeout) {\n        //normal enviroments in sane situations\n        return setTimeout(fun, 0);\n    }\n    // if setTimeout wasn't available but was latter defined\n    if ((cachedSetTimeout === defaultSetTimout || !cachedSetTimeout) && setTimeout) {\n        cachedSetTimeout = setTimeout;\n        return setTimeout(fun, 0);\n    }\n    try {\n        // when when somebody has screwed with setTimeout but no I.E. maddness\n        return cachedSetTimeout(fun, 0);\n    } catch(e){\n        try {\n            // When we are in I.E. but the script has been evaled so I.E. doesn't trust the global object when called normally\n            return cachedSetTimeout.call(null, fun, 0);\n        } catch(e){\n            // same as above but when it's a version of I.E. that must have the global object for 'this', hopfully our context correct otherwise it will throw a global error\n            return cachedSetTimeout.call(this, fun, 0);\n        }\n    }\n\n\n}\nfunction runClearTimeout(marker) {\n    if (cachedClearTimeout === clearTimeout) {\n        //normal enviroments in sane situations\n        return clearTimeout(marker);\n    }\n    // if clearTimeout wasn't available but was latter defined\n    if ((cachedClearTimeout === defaultClearTimeout || !cachedClearTimeout) && clearTimeout) {\n        cachedClearTimeout = clearTimeout;\n        return clearTimeout(marker);\n    }\n    try {\n        // when when somebody has screwed with setTimeout but no I.E. maddness\n        return cachedClearTimeout(marker);\n    } catch (e){\n        try {\n            // When we are in I.E. but the script has been evaled so I.E. doesn't  trust the global object when called normally\n            return cachedClearTimeout.call(null, marker);\n        } catch (e){\n            // same as above but when it's a version of I.E. that must have the global object for 'this', hopfully our context correct otherwise it will throw a global error.\n            // Some versions of I.E. have different rules for clearTimeout vs setTimeout\n            return cachedClearTimeout.call(this, marker);\n        }\n    }\n\n\n\n}\nvar queue = [];\nvar draining = false;\nvar currentQueue;\nvar queueIndex = -1;\n\nfunction cleanUpNextTick() {\n    if (!draining || !currentQueue) {\n        return;\n    }\n    draining = false;\n    if (currentQueue.length) {\n        queue = currentQueue.concat(queue);\n    } else {\n        queueIndex = -1;\n    }\n    if (queue.length) {\n        drainQueue();\n    }\n}\n\nfunction drainQueue() {\n    if (draining) {\n        return;\n    }\n    var timeout = runTimeout(cleanUpNextTick);\n    draining = true;\n\n    var len = queue.length;\n    while(len) {\n        currentQueue = queue;\n        queue = [];\n        while (++queueIndex < len) {\n            if (currentQueue) {\n                currentQueue[queueIndex].run();\n            }\n        }\n        queueIndex = -1;\n        len = queue.length;\n    }\n    currentQueue = null;\n    draining = false;\n    runClearTimeout(timeout);\n}\n\nprocess.nextTick = function (fun) {\n    var args = new Array(arguments.length - 1);\n    if (arguments.length > 1) {\n        for (var i = 1; i < arguments.length; i++) {\n            args[i - 1] = arguments[i];\n        }\n    }\n    queue.push(new Item(fun, args));\n    if (queue.length === 1 && !draining) {\n        runTimeout(drainQueue);\n    }\n};\n\n// v8 likes predictible objects\nfunction Item(fun, array) {\n    this.fun = fun;\n    this.array = array;\n}\nItem.prototype.run = function () {\n    this.fun.apply(null, this.array);\n};\nprocess.title = 'browser';\nprocess.browser = true;\nprocess.env = {};\nprocess.argv = [];\nprocess.version = ''; // empty string to avoid regexp issues\nprocess.versions = {};\n\nfunction noop() {}\n\nprocess.on = noop;\nprocess.addListener = noop;\nprocess.once = noop;\nprocess.off = noop;\nprocess.removeListener = noop;\nprocess.removeAllListeners = noop;\nprocess.emit = noop;\nprocess.prependListener = noop;\nprocess.prependOnceListener = noop;\n\nprocess.listeners = function (name) { return [] }\n\nprocess.binding = function (name) {\n    throw new Error('process.binding is not supported');\n};\n\nprocess.cwd = function () { return '/' };\nprocess.chdir = function (dir) {\n    throw new Error('process.chdir is not supported');\n};\nprocess.umask = function() { return 0; };\n\n\n/***/ })\n/******/ ]);\n//# sourceMappingURL=https://s3.pstatp.com/eesz/resource/bear/js/767d6b6c14850a18a41f.worker.js.map", __webpack_require__.p + "767d6b6c14850a18a41f.worker.js");
};

/***/ }),

/***/ 3822:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _class, _temp, _initialiseProps;

var _utils = __webpack_require__(1632);

var _util = __webpack_require__(1653);

var _const = __webpack_require__(1651);

var _image_view = __webpack_require__(1952);

var _image_view2 = _interopRequireDefault(_image_view);

var _$rjquery = __webpack_require__(552);

var _uploadCreator = __webpack_require__(1847);

var _uploadCreator2 = _interopRequireDefault(_uploadCreator);

var _sdkCompatibleHelper = __webpack_require__(45);

var _browserHelper = __webpack_require__(27);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

var _common = __webpack_require__(19);

var _suiteHelper = __webpack_require__(52);

var _offlineEditHelper = __webpack_require__(220);

var _logger = __webpack_require__(305);

var _logger2 = _interopRequireDefault(_logger);

var _generateHeadersHelper = __webpack_require__(347);

var _modalHelper = __webpack_require__(747);

var _repHelper = __webpack_require__(1681);

var _toast = __webpack_require__(554);

var _toast2 = _interopRequireDefault(_toast);

var _tea = __webpack_require__(42);

var _tea2 = _interopRequireDefault(_tea);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Uploader = (_temp = _class = function Uploader(ace, imageUploadInstance) {
  var _this = this;

  (0, _classCallCheck3.default)(this, Uploader);

  _initialiseProps.call(this);

  this.uploader = Uploader.uploader;
  this.editorInfo = ace.editorInfo;
  this.ace = ace;
  this.imageUploadInstance = imageUploadInstance;
  this.pasteOverSized = false;
  var events = ['beforeFileQueued', 'uploadStart', 'uploadProgress', 'uploadSuccess', 'uploadError', 'filesQueued', 'uploadBeforeSend'];
  this.extensions = 'gif,jpg,jpeg,bmp,png'; // 支持图片类型
  this.imageViews = {}; // 保存imageView的实例 可以上传多个img
  this.imageAttrs = {}; // 保存图片属性
  this.imageViewCalcPromise = {}; // 保存计算rect的promise
  this.readImgPromise = {};
  this.allFileList = [];
  this.filesUUID = [];
  this.uploader = (0, _uploadCreator2.default)(ace);
  events.forEach(function (evtName) {
    _this.uploader.on(_this.extensions, evtName, _this[evtName]);
  });
}, _class.threads = 10, _initialiseProps = function _initialiseProps() {
  var _this2 = this;

  this.handleTeaLog = function (uplaodStatus, fileSize, fileName) {
    var fileType = fileName.split('.').pop() || 'unknown';
    (0, _tea2.default)('mention_drag_upload', {
      upload_status: uplaodStatus || 'fail',
      mention_file_length: fileSize,
      mention_file_type: fileType,
      file_id: (0, _tea.getEncryToken)(),
      file_type: (0, _tea.getFileType)()
    });
  };

  this.uploadBeforeSend = function (block, data, headers, imageSrc) {
    Object.assign(headers, (0, _generateHeadersHelper.generateHeaders)());
    _this2.performImageViewer(block.file, imageSrc);
  };

  this.uploadStart = function () {
    var token = (0, _suiteHelper.getToken)();
    var url = encodeURI('/api/file/upload/');
    _this2.uploader.option('server', url);
    _this2.uploader.option('formData', { token: token, obj_type: _common.NUM_SUITE_TYPE.DOC });
  };

  this.performImageViewer = function (file, imageSrc) {
    var uuid = file.uuid = (0, _utils.genUUID)();
    var imageView = _this2.imageViews[file.uuid] = new _image_view2.default(file.uuid);
    var imageAttrs = _this2.imageAttrs;
    var editorInfo = _this2.ace.editorInfo;


    (0, _repHelper.restoreRepsIfNeeded)(editorInfo);
    // iOS 在点击上传图片之后， 弹起键盘的高度设置不准确， 粗略设置一个
    window._currentViewHeight = window.innerHeight / 2 - 50;

    _this2.imageViewCalcPromise[uuid] = new Promise(function (resolve, reject) {
      _this2.readImgPromise[uuid] = imageView.createDataURL(file.source.source).then(function (src) {
        imageView.calcImageRect(src).then(function (rect) {
          editorInfo.ace_callWithAce(function () {
            var height = rect.height,
                width = rect.width,
                natrualWidth = rect.natrualWidth,
                natrualHeight = rect.natrualHeight,
                scale = rect.scale;

            imageAttrs[uuid] = {
              height: height,
              width: width,
              src: src,
              natrualWidth: natrualWidth,
              natrualHeight: natrualHeight,
              scale: scale
            };

            resolve(imageAttrs[uuid]);
            // 避免 base64 src 上传，通过 ImageUpload 传递
            // android 平台的大图7M左右在src base64写为innerHTML的时候要花掉600ms，造成页面不可交互
            // 因此换为传过来的nativeUrl
            _this2.imageUploadInstance[_const.uploadPrefix + '-base64-src-' + uuid] = imageSrc || src;

            var values = [(0, _util.createQueryString)({
              uuid: uuid,
              pluginName: _const.pluginName,
              height: height,
              width: width
            })];
            var attrs = [['image-previewer', values]];
            imageView.performImagePreviewer(attrs);
            _this2.updateCursor();
          }, 'uploadImageSuc', true);
        }, function () {
          _this2.showAlertForLoadTimeout();
        });
        return src;
      }, function (e) {
        _this2.showAlertForLoadTimeout();
      });
    });
  };

  this.uploadProgress = function (file, percentage) {
    _this2.imageViews[file.uuid].updateProgressStyle(percentage);
  };

  this.deleteImageView = function (uuid) {
    if (_this2.imageViews[uuid]) {
      delete _this2.imageAttrs[uuid];
      delete _this2.imageViews[uuid];
    }
  };

  this.uploadSuccess = function (file, res) {
    var ace = _this2.ace,
        imageViews = _this2.imageViews,
        imageAttrs = _this2.imageAttrs;
    var editorInfo = ace.editorInfo;

    var noUrl = res.data && !res.data.url;
    if (res.code !== 0 && noUrl) {
      _this2.uploadError(file, res.msg);
      return;
    }
    var uuid = file.uuid;
    var _res$data = res.data,
        url = _res$data.url,
        cdn_url = _res$data.cdn_url,
        thumbnail_cdn_url = _res$data.thumbnail_cdn_url,
        webp_thumbnail_cdn_url = _res$data.webp_thumbnail_cdn_url,
        decrypt_key = _res$data.decrypt_key;

    _this2.imageViewCalcPromise[uuid].then(function () {
      var imageView = imageViews[uuid];
      var imageAttr = imageAttrs[uuid];
      // todo 优化这个尺寸计算逻辑，从本地图片取数据，直接置灰预览图
      // 标记当前perform的图片，第一次resize不会重新reload
      editorInfo.call(_const.MARK_DECODE_IMAGE, uuid);
      // 直接perform
      editorInfo.ace_callWithAce(function () {
        var _ref = imageAttr || {},
            _ref$height = _ref.height,
            height = _ref$height === undefined ? 'auto' : _ref$height,
            _ref$width = _ref.width,
            width = _ref$width === undefined ? '100%' : _ref$width,
            natrualWidth = _ref.natrualWidth,
            natrualHeight = _ref.natrualHeight,
            scale = _ref.scale;

        // 绕过图片解密


        _this2.imageUploadInstance[_const.uploadPrefix + '-ignore-' + uuid] = true;

        var values = JSON.stringify({
          items: [{
            attachmentId: 'attachment-id-' + uuid,
            type: 'image',
            // innerZone: ''    后续特性: 图片下方描述所在的zone
            src: encodeURIComponent(url),
            pluginName: _const.pluginName,
            uuid: uuid,
            natrualWidth: natrualWidth,
            natrualHeight: natrualHeight,
            decrypt_key: decrypt_key,
            cdn_url: cdn_url,
            thumbnail_cdn_url: thumbnail_cdn_url,
            webp_thumbnail_cdn_url: webp_thumbnail_cdn_url,
            height: height,
            width: width,
            scale: scale,
            comments: [],
            isDragging: false
          }]
        });
        var attribs = [['gallery', values], ['author', editorInfo.ace_getAuthor()]];
        editorInfo.call('imageUploadSuccess');
        imageView.replacePlaceholderWidthImage(attribs);
      }, 'uploadImageSuc', true);
      _this2.deleteImageView(uuid);
      (0, _util.handleTeaLog)('success', file.size, file.name);
    });
  };

  this.uploadError = function (file, reason) {
    _toast2.default.show({
      type: 'error',
      closable: true,
      content: t('etherpad.upload_failed')
    });
    if (file) {
      var dom = (0, _$rjquery.$)('#' + _const.uploadPrefix + '-image-' + file.uuid).closest('.image-previewer').get(0);
      _image_view2.default.clearImagePreviewer(dom);
      _this2.deleteImageView(file.uuid);
      (0, _util.handleTeaLog)('fail', file.size, file.name);
    }
  };

  this.updateCursor = function () {
    _this2.updateCursorTimeout && clearTimeout(_this2.updateCursorTimeout);
    _this2.updateCursorTimeout = setTimeout(function () {
      var rep = _this2.editorInfo.ace_getRep();
      var maxLines = rep.lines.length() - 1;
      var nextLine = rep.selStart[0] + 1;

      if (nextLine > maxLines) {
        nextLine = maxLines;
      }

      // rep.selStart = [nextLine, 0];
      // rep.selEnd = [nextLine, 0];
      _this2.editorInfo.selection.setWithSelection(rep.zoneId, [nextLine, 0], [nextLine, 0], false);
      _this2.editorInfo.ace_updateBrowserSelectionFromRep(true);
      _image_view2.default.removeImageChooseStyle();
    });
  };

  this.beforeFileQueued = function (file) {
    if (_this2.pasteOverSized) {
      _toast2.default.show({
        type: 'error',
        closable: true,
        content: t('etherpad.upload_noallow_paste')
      });
      return false;
    }
    if (file.size > _const.IMAGE_MAX_SIZE) {
      _toast2.default.show({
        type: 'error',
        closable: true,
        content: t('etherpad.upload_failed_than_size')
      });
      return false;
    }
    // const debug = false;
    var uploadStart = _this2.uploadStart,
        uploadBeforeSend = _this2.uploadBeforeSend,
        uploadProgress = _this2.uploadProgress,
        uploadSuccess = _this2.uploadSuccess,
        uploader = _this2.uploader;

    if ((0, _sdkCompatibleHelper.isSupportOfflineEdit)()) {
      file.uuid = (0, _utils.genUUID)();
      var param = {
        token: (0, _suiteHelper.getToken)(),
        type: file.type,
        size: file.size,
        doc_url: location.href
      };
      if (_browserHelper2.default.android) {
        param.name = file.name;
        console.info('setFileData called');
        console.time('start img');
        // android 的设置callback速度远比js用file生成预览图快
        // 因此android平台用callback里面的url去做预览
        param.callback = function (res) {
          if (res && res.code === 0 && res.data && res.data.file_url) {
            var headers = {
              'Content-Type': 'multipart/form-data'
            };
            console.timeEnd('start img');
            file.nativeImgUrl = res.data.file_url;

            uploadStart();
            uploadBeforeSend({ file: file }, {}, headers, res.data.file_url);
            uploadProgress(file, 1);
            uploadSuccess(file, { data: { url: res.data.file_url } });
            console.info('setFileData callback then setData');
            (0, _offlineEditHelper.setData)({
              key: res.data.file_url,
              data: {
                key: res.data.file_url,
                data: {
                  url: location.origin + uploader.option('server'),
                  method: 'POST',
                  file_url: res.data.file_url,
                  token: (0, _suiteHelper.getToken)(), // 文档token：e.g. "H3wdqb2TOxKRfDcSOULLce"
                  doc_url: location.href,
                  type: file.type, //  "image/jpeg"
                  size: file.size, // 文件大小(byte)  e.g.  5083673
                  multiparts: Object.assign({
                    file: res.data.file_url
                  }, uploader.option('formData')),
                  headers: headers
                }
              }
            });
          }
        };
        window.lark.biz.util.setFileData(param);
      } else {
        // ios
        var key = new Date().getTime() + '_' + file.name;
        param.name = key;
        param.key = key;
        param.keyGened = true;
        var headers = {
          'Content-Type': 'multipart/form-data'
        };
        uploadStart();
        uploadBeforeSend({ file: file }, {}, headers);
        var uuid = file.uuid;
        _this2.readImgPromise[uuid] && _this2.readImgPromise[uuid].then(function (src) {
          param.data = src;
          param.type = 'image_base64';
          _logger2.default.info('set image base64 data');
          (0, _offlineEditHelper.setData)(param).then(function (ret) {
            var imgUri = 'docsource://com.bytedance.ee.bear/' + param.token + '/' + key;
            file.nativeImgUrl = imgUri;
            uploadProgress(file, 1);
            uploadSuccess(file, { data: { url: imgUri } });

            _logger2.default.info('set image upload params data');
            (0, _offlineEditHelper.setData)({
              key: imgUri,
              data: {
                key: imgUri,
                data: {
                  url: (location.origin + uploader.option('server')).replace('docsource', 'https'),
                  method: 'POST',
                  file_url: imgUri,
                  token: (0, _suiteHelper.getToken)(), // 文档token：e.g. "H3wdqb2TOxKRfDcSOULLce"
                  doc_url: location.href,
                  type: file.type, //  "image/jpeg"
                  size: file.size, // 文件大小(byte)  e.g.  5083673
                  multiparts: Object.assign({
                    type: file.type, //  "image/jpeg"
                    size: file.size, // 文件大小(byte)  e.g.  5083673
                    file: key
                  }, uploader.option('formData'))
                  // headers: headers,
                }
              }
            });
          });
        });
      }
      return false;
    }
    return true;
  };

  this.showAlertForLoadTimeout = function () {
    (0, _modalHelper.showAlert)('', t('etherpad.load_timeout'));
  };
}, _temp);
exports.default = Uploader;
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(25)))

/***/ }),

/***/ 3823:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _slicedToArray2 = __webpack_require__(111);

var _slicedToArray3 = _interopRequireDefault(_slicedToArray2);

var _image_view = __webpack_require__(1952);

var _image_view2 = _interopRequireDefault(_image_view);

var _pinchzoom = __webpack_require__(3824);

var _pinchzoom2 = _interopRequireDefault(_pinchzoom);

var _underscore = __webpack_require__(1633);

var _isEqual2 = __webpack_require__(748);

var _isEqual3 = _interopRequireDefault(_isEqual2);

var _forEach = __webpack_require__(343);

var _forEach2 = _interopRequireDefault(_forEach);

var _const = __webpack_require__(1651);

var _$rjquery = __webpack_require__(552);

var _sdkCompatibleHelper = __webpack_require__(45);

var _browserHelper = __webpack_require__(27);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

var _dragImageInfo = __webpack_require__(3830);

var _dragImageInfo2 = _interopRequireDefault(_dragImageInfo);

var _utils = __webpack_require__(1831);

var _string = __webpack_require__(163);

var _tea = __webpack_require__(42);

var _tea2 = _interopRequireDefault(_tea);

var _onboarding = __webpack_require__(314);

var _onboarding2 = __webpack_require__(130);

var _common = __webpack_require__(19);

var _constants = __webpack_require__(5);

var _eventEmitter = __webpack_require__(110);

var _eventEmitter2 = _interopRequireDefault(_eventEmitter);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var ace = void 0,
    editorInfo = void 0;
var pcImageViewer = void 0;
var imageUploadInstance = void 0; // 用于拖拽后重新分配uuid, 并跳过图片解密, 解决离线时拖拽导致相同uuid

function isFocusOnThisImage(e) {
  // 通过样式模板 ID 来判断图片是否在选中高亮状态
  return editorInfo && (0, _$rjquery.$)('style[data-id=' + e.target.parentNode.id + ']').length;
}

function setCursorOnImg(e, context) {
  e.preventDefault();
  e.stopPropagation();
  var point = editorInfo.selection.getPositionForNode(e.target);
  var $image = (0, _$rjquery.$)(context).find('.image-container');
  if ($image.length) {
    var lineNum = $image.parents('[id^=magicdomid]').index();
    var rep = editorInfo.ace_getReps()[point.zone];
    var lineMarker = rep.lines.atIndex(lineNum).lineMarker;
    var domRep = {
      selStart: [lineNum, lineMarker],
      selEnd: [lineNum, lineMarker],
      zoneId: '0'
    };
    var imageTaget = (0, _$rjquery.$)(e.target).closest('.image-container');
    editorInfo.call('galleryImageChoosed', imageTaget.attr('id'));

    if (imageTaget && imageTaget[0]) {
      // 请求客户端展示自定义菜单
      var scrollY = window.scrollY;

      var _imageTaget$0$getBoun = imageTaget[0].getBoundingClientRect(),
          left = _imageTaget$0$getBoun.left,
          top = _imageTaget$0$getBoun.top,
          right = _imageTaget$0$getBoun.right,
          bottom = _imageTaget$0$getBoun.bottom;

      _eventEmitter2.default.trigger(_constants.events.MOBILE.CONTEXT_MENU.showDocContextMenu, [{
        left: left, top: top + scrollY, right: right, bottom: bottom + scrollY
      }]);
    }

    // hack 点到评论 list 失焦再点回来导致 rep 不变
    // 稍微变一下 selEnd 再变回来，触发 selectionchange
    if ((0, _isEqual3.default)(rep.selStart, domRep.selStart) && (0, _isEqual3.default)(rep.selEnd, domRep.selEnd)) {
      editorInfo.ace_inCallStackIfNecessary('click', function () {
        var tempSelEnd = [domRep.selEnd[0], domRep.selEnd[1] + 1];
        editorInfo.ace_performSelectionChange(rep.zoneId, domRep.selStart, tempSelEnd);
      });
    }
    editorInfo.ace_inCallStackIfNecessary('click', function () {
      editorInfo.ace_performSelectionChange(rep.zoneId, domRep.selStart, domRep.selEnd);
    });
    rep.selStart = domRep.selStart;
    rep.selEnd = domRep.selEnd;
    editorInfo.ace_focus((0, _$rjquery.$)('.etherpad-container-wrapper').scrollTop());
    editorInfo.selection.setWithSelection(rep.zoneId, rep.selStart, rep.selEnd, false);
    editorInfo.ace_updateBrowserSelectionFromRep(true);
  }
}

/**
 * 处理resize的handle
 * @returns {{handleMouseDown: handleMouseDown, handleMouseMove: handleMouseMove, handleMouseUp: handleMouseUp}}
 */
function handleImageResize() {
  var canDrag = false;
  var imageWidth = void 0,
      imageHeight = void 0;
  var pointX = void 0,
      pointY = void 0;
  var diffX = void 0,
      diffY = void 0;
  var left = void 0,
      top = void 0;
  var $image = void 0;
  var id = void 0;
  var direction = void 0;
  var isMoved = false;
  var imageMaxWidth = void 0;
  var resizeImageLineKey = void 0;
  var imageView = void 0;

  function handleMouseDown(e) {
    resizeImageLineKey = null;
    $image = (0, _$rjquery.$)(e.target).siblings('img');
    if ($image.closest('.gallery').find('.image-container') > 1) return;
    resizeImageLineKey = null;
    var $container = $image.parent();
    left = $container.get(0).offsetLeft;
    top = $container.get(0).offsetTop;
    direction = (0, _underscore.find)(e.target.className.split(' '), function (item) {
      return _const.POINTS.indexOf(item) > -1;
    });
    id = $image.parent().attr('id');
    imageWidth = $image.width();
    imageHeight = $image.height();
    imageMaxWidth = $image.parents('.image-uploaded').width();
    canDrag = true;
    imageView = new _image_view2.default($image.data('uuid'));
    pointX = e.pageX;
    pointY = e.pageY;

    e.preventDefault();
    return false;
  }

  function handleMouseMove(e) {
    var pageX = e.pageX,
        pageY = e.pageY,
        target = e.target;

    if (!canDrag) {
      return;
    }
    var zoneId = editorInfo && editorInfo.dom.zoneOfdom(target);
    diffX = pageX - pointX;
    diffY = pageY - pointY;
    isMoved = true;
    imageView.setImageRectByDirection(direction, imageWidth, imageHeight, diffX, diffY, left, top, imageMaxWidth);
    if (!resizeImageLineKey) {
      var _target = e.target;
      while (_target && _target !== document) {
        if (_target.id && /magicdomid/.test(_target.id)) {
          break;
        }
        _target = _target.parentNode;
      }
      resizeImageLineKey = _target && _target.id;
    }
    editorInfo && editorInfo.hooks.callAll('handleImageResize', { lineKey: resizeImageLineKey, zoneId: zoneId });
  }

  function handleMouseUp(e) {
    resizeImageLineKey = null;
    (0, _$rjquery.$)('#' + id + '-container-style').remove();
    canDrag = false;

    if (isMoved) {
      imageView.applyImageStyle(id);
    }
    isMoved = false;
  }

  return { handleMouseDown: handleMouseDown, handleMouseMove: handleMouseMove, handleMouseUp: handleMouseUp };
}

function _handleMobileClickImg(e, editorInfo) {
  var id = 'img-modal-ele';
  var imgSrc = e.target.getAttribute('data-src');
  var _modalImg = '<img src="' + imgSrc + '" id=' + id + '/>';
  var oDiv = document.createElement('div');

  if ((0, _sdkCompatibleHelper.isSupportPreview)()) {
    var imageList = [];
    (0, _$rjquery.$)('.image-container img').each(function () {
      var src = (0, _$rjquery.$)(this).attr('data-src');
      if (src) {
        imageList.push({
          title: '',
          src: src
        });
      }
    });

    // 分块渲染时，未渲染的图片也需要加上
    if (_common.USE_BLOCK_RENDER && editorInfo.blockRender && !editorInfo.blockRender.allRenderred) {
      var rep = editorInfo.getRep();
      var other = getImagesfromApool(rep.apool, imageList.length);
      imageList = imageList.concat(other);
    }

    var image = {
      title: '',
      src: imgSrc
    };

    window.lark.biz.util.openImg({
      image: image,
      image_list: imageList
    });
  } else {
    (0, _$rjquery.$)('#' + id).remove();
    var $modalImg = (0, _$rjquery.$)(_modalImg);
    oDiv.className = 'img-modal-container layout-row layout-main-center layout-cross-center';
    (0, _$rjquery.$)(oDiv).css({
      right: 0,
      bottom: 0,
      top: 0,
      left: 0,
      position: 'fixed'
    });
    (0, _$rjquery.$)(oDiv).append($modalImg);
    (0, _$rjquery.$)('body').css({ overflow: 'hidden', height: '100%' }).append(oDiv);
    var _handleTouch = handleTouch(oDiv);
    (0, _$rjquery.$)(oDiv).on('touchstart', _handleTouch);
    (0, _$rjquery.$)(oDiv).on('touchend', _handleTouch);

    $modalImg.on('load', function () {
      setTimeout(function () {
        new _pinchzoom2.default($modalImg.get(0)); // eslint-disable-line
      });
    });
  }
}
var handleMobileClickImg = (0, _underscore.throttle)(_handleMobileClickImg, 30);

function getImagesfromApool(apool) {
  var start = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 0;
  var numToAttrib = apool.numToAttrib;

  var res = [];
  var startIndex = 0;

  for (var key in numToAttrib) {
    var attr = numToAttrib[key];
    if (attr[0] === 'image-uploaded') {
      if (startIndex < start) {
        startIndex++;
        continue;
      }

      var reg = /src=([\d\w%.:/]*)/;
      var matches = attr[1].match(reg);

      if (!matches) continue;

      res.push({
        title: '',
        src: decodeURIComponent(matches[1]).replace(/\/\/file/, '/file') // 兼容老图片url  host//file/xxx,
      });
    }
  }

  return res;
}

function handleTouch(oDiv) {
  var touchStartTime = void 0;
  return function (e) {
    if (e.type === 'touchstart') {
      touchStartTime = new Date().getTime();
    } else if (touchStartTime && new Date().getTime() - touchStartTime <= 100) {
      (0, _$rjquery.$)(oDiv).remove();
      (0, _$rjquery.$)('body').css({ overflow: 'auto', height: 'auto' });
      var outerDocEl = editorInfo.ace_getContainerBox();
      // hack
      // 键盘弹起时预览图片，关闭后，页面下方会留下padding，直接设置为空无效...
      (0, _$rjquery.$)(outerDocEl).css('padding-bottom', '1px');
    }
  };
}

function handleModify() {
  return function (e) {
    var editStatus = editorInfo.getEditStatus();

    if (!editStatus) {
      e.preventDefault();
      e.stopImmediatePropagation();
      return false;
    }
  };
}

function handleMobileImgTouch() {
  var moved = false; // 防误触
  var touchStartTime = void 0;
  var previewImage = function previewImage(that, e, editorInfo) {
    (0, _$rjquery.$)(editorInfo.ace_getInnerContainer()).blur();
    // listening in appEditControl.js
    // 本可以用blur事件，但是会导致图片上传无法调起键盘，故改用自定义事件
    (0, _$rjquery.$)('body').triggerHandler('innerDomBlur');
    handleMobileClickImg.call(that, e, editorInfo);
  };
  return function (editorInfo, e) {
    if (e.type === 'touchstart') {
      moved = false;
      touchStartTime = new Date().getTime();
    } else if (e.type === 'touchmove') {
      moved = true;
    } else if (!moved && touchStartTime && new Date().getTime() - touchStartTime <= 100) {
      e.preventDefault();
      if (e.isTrigger) return;
      /**
       * Doc 单击图片为选中；选中图片再次点击，则进入图片查看器
       */
      if (isFocusOnThisImage(e)) {
        previewImage(this, e, editorInfo);
      } else {
        // https://jira.bytedance.com/browse/DM-2371 Android出现点击图片页面发生异常滚动的case
        setTimeout(function () {
          setCursorOnImg(e, e.currentTarget);
        }, 100);
      }
    }
  };
}

exports.default = {
  handleResizeMove: (0, _underscore.throttle)(handleImageResize, 16),
  handleResizeDown: handleImageResize,
  handleResizeUp: handleImageResize,
  pcImageViewerShown: function pcImageViewerShown() {
    if (!pcImageViewer) return false;
    return pcImageViewer.isShown;
  },
  handleRemoveImageChoose: function handleRemoveImageChoose(e) {
    var innerContainer = '#' + editorInfo.ace_getInnerContainer().id;
    // 如果点击在这些元素上，则不取消选中样式
    var whitelist = [
    // 图片本身
    innerContainer + ' img', innerContainer + ' .image-container',
    // 工具栏
    '#editbar-text',
    // 图片查看器
    '.viewer-container'];
    if ((0, _$rjquery.$)(e.target).closest(whitelist.join(',')).length > 0) {
      return;
    }
    _image_view2.default.removeImageChooseStyle();
  },
  handleDragImage: function handleDragImage(e) {
    _browserHelper2.default.isMobile || e.preventDefault();
    if (!editorInfo.isContentEditable()) return;
    this.dragImageInfo = new _dragImageInfo2.default();
    var dragImageInfo = this.dragImageInfo;
    var $img = (0, _$rjquery.$)(e.target);
    // 存储相关信息
    dragImageInfo.galleryJSONData = $img.closest('.image-uploaded').attr('data-ace-gallery-json');
    dragImageInfo.originIndex = dragImageInfo.galleryJSONData && dragImageInfo.getItemGalleryIndex(e.target);
    // 兼容旧图片数据
    if (!dragImageInfo.galleryJSONData) {
      dragImageInfo.galleryJSONData = this.compatImageToGallery($img, editorInfo);
      dragImageInfo.compatMode = true;
      dragImageInfo.originIndex = 0;
    }
    dragImageInfo.originGallery = dragImageInfo.getGalleryData();
    dragImageInfo.originPosition = editorInfo.selection.getPositionForNode(e.target);
    dragImageInfo.editorPadding = this.calcEditorPadding();
    dragImageInfo.cachedGalleryItemData = dragImageInfo.getItems()[this.dragImageInfo.originIndex];
    dragImageInfo.isDraging = true;
    // 禁止接收和发送changeset, 拖拽结束后再进行合并
    editorInfo.plugins.client.disable();
    // 更新选区至拖拽初始行
    this.updateSelectionToGallery(dragImageInfo);
    // 初始化光标
    this.initDragCursor(dragImageInfo, e);
    // 应用图片拖拽样式
    this.changeOpacity(dragImageInfo, true);
    // 若拖拽为单行多图中的某张图片
    if (dragImageInfo.originGallery.items.length > 1) {
      var containerId = (0, _$rjquery.$)(e.target).closest('.image-container').attr('id');
      _image_view2.default.addGalleryChoosedStyle(containerId);
      editorInfo.call('galleryImageChoosed', containerId);
    }
    (0, _onboarding.removeSteps)(_onboarding2.STEP_TYPES.gallery_image_guide);
  },
  /**
   * 如果未进入拖拽状态 || 目标行为标题行，则退出
   * 一、同一行
   * 二、不同行(1.拖至gallery行 2.拖至文字行)
   */
  handleDragMove: function handleDragMove(e) {
    if (!this.dragImageInfo) return;
    if (this.dragImageInfo.isCommitting) return;
    this.hideSelectionPopup();
    var dragImageInfo = this.dragImageInfo;
    this.scrollIfNeccessary(e, this.dragImageInfo);
    var cursorTarget = this.getCursorTarget(dragImageInfo, e);
    if (dragImageInfo.isDraging && (0, _$rjquery.$)('#innerdocbody').find(cursorTarget).length) {
      this.removeUnderline();
      // 鼠标指向元素的 Position
      var positionOfTarget = editorInfo.selection.getPositionForNode(cursorTarget);
      // 如果为图片，则可用于判断拖动元素和拖拽指向的元素为同一元素
      dragImageInfo.isDropToSameLine = positionOfTarget.line === dragImageInfo.originPosition.line && positionOfTarget.zone === dragImageInfo.originPosition.zone;
      dragImageInfo.currentPosition = positionOfTarget;
      // 鼠标指向为图片行
      if (this.isImageLine(positionOfTarget)) {
        if (this.isCursorAtBottom(e.originalEvent, cursorTarget)) {
          // 单行多图某张图片放到当前行底部
          if (dragImageInfo.isDropToSameLine && dragImageInfo.originGallery.items.length > 1) {
            var currentPosition = dragImageInfo.currentPosition;
            dragImageInfo.currentPosition.line = Math.min(editorInfo.getRep(currentPosition.zone).lines.length() - 1, currentPosition.line);
          }
          dragImageInfo.currentGallery = null;
          dragImageInfo.isDropToSameLine = null;
          this.removeImageHint();
          this.addUnderLineOnNode(cursorTarget, positionOfTarget);
        } else {
          var dropHintIndex = this.getDropHintIndex(cursorTarget, e.originalEvent);
          // 目标行只有一行图片时
          var cursorTargetIndex = void 0;
          if ((0, _$rjquery.$)(cursorTarget).find('img').length <= 1) {
            cursorTargetIndex = 0;
          } else {
            cursorTargetIndex = Math.floor((dropHintIndex + 1) / 2);
          }
          var img = (0, _$rjquery.$)(cursorTarget).find('img').get(cursorTargetIndex);
          var isSameElement = img && (0, _$rjquery.$)(img).attr('data-uuid') === dragImageInfo.originGallery.items[dragImageInfo.originIndex].uuid;
          if (isSameElement) {
            this.removeImageHint();
            this.stepApplyChangeWhenDrop(dragImageInfo);
            return;
          }
          // 鼠标指向元素的gallery信息
          var targetStringifyJSON = (0, _$rjquery.$)(img).closest('.image-uploaded').attr('data-ace-gallery-json') || this.compatImageToGallery((0, _$rjquery.$)(img), editorInfo);
          dragImageInfo.currentGallery = JSON.parse(targetStringifyJSON);
          if (dragImageInfo.currentGallery.items.length >= 3 && !dragImageInfo.isDropToSameLine) {
            this.stepApplyChangeWhenDrop(dragImageInfo);
            return;
          }
          // 不同行拖拽至图片行
          if (dragImageInfo.currentGallery.items.length < 3 && !dragImageInfo.isDropToSameLine) {
            dragImageInfo.insertIndex = dropHintIndex;
          } else if (dragImageInfo.isDropToSameLine) {
            if (dropHintIndex - 1 === dragImageInfo.originIndex || dropHintIndex === dragImageInfo.originIndex) {
              this.removeImageHint();
              this.stepApplyChangeWhenDrop(dragImageInfo);
              return;
            }
            // 图片同行交换位置
            dragImageInfo.insertIndex = Math.floor((dropHintIndex + 1) / 2);
          }
          this.removeImageHint();
          this.addGalleryHintAtIndex(cursorTarget, dropHintIndex);
        }
      } else {
        // 光标拖至文本行
        this.removeImageHint();
        this.addUnderLineOnNode(cursorTarget, positionOfTarget);
        dragImageInfo.currentGallery = null;
      }
    }
  },
  handleDropImage: function handleDropImage(e) {
    var _this = this;

    if (!this.dragImageInfo) return;
    if (this.dragImageInfo.isCommitting) return;
    e.preventDefault();
    // 移除所有拖拽提示
    this.removeUnderline();
    this.removeImageHint();
    this.removeDragCursor();
    // 取消自动滚动timer
    this.clearScrollTimer(this.dragImageInfo);
    this.dragImageInfo.isCommitting = true;
    // 若原本评论选区包含gallery, 保留该评论
    this.holdCommentAttrIfNecessary(this.dragImageInfo);
    // 原图片设置回正常样式
    this.changeOpacity(this.dragImageInfo, false);
    var focusPosition = void 0; // 拖拽结束后focus位置
    var eventType = void 0; // 打点事件
    var animationTime = void 0; // 动画时间 -> 决定多久后 performChange
    // 相同行
    if (this.dragImageInfo.isDropToSameLine && this.dragImageInfo.version !== 1) {
      // 修改原行attribs
      var gallery = this.dragImageInfo.currentGallery;
      // 对应item 位置互换
      var temp = gallery.items[this.dragImageInfo.insertIndex];
      var targetNewUuid = void 0;
      gallery.items[this.dragImageInfo.insertIndex] = gallery.items[this.dragImageInfo.originIndex];
      gallery.items[this.dragImageInfo.originIndex] = temp;
      // 重设图片uuid
      gallery.items.forEach(function (item, index) {
        _this.resetUuidToObject(item);
        if (index === _this.dragImageInfo.insertIndex) targetNewUuid = item.uuid;
      });
      var currentPosition = this.dragImageInfo.currentPosition;
      focusPosition = {
        line: currentPosition.line,
        zone: currentPosition.zone
      };
      var currentLineEntry = editorInfo.getRep(currentPosition.zone).lines.atIndex(currentPosition.line);
      var currentGalleryAttribs = editorInfo.ace_getAttributesOnSelection(currentPosition.zone, {
        selStart: [currentPosition.line, 0],
        selEnd: [currentPosition.line, currentLineEntry.text.length]
      }, false);
      currentGalleryAttribs.attribs.forEach(function (keyPairs, index) {
        var key = keyPairs[0];
        var value = keyPairs[1];
        if (key === 'gallery') {
          // 在原始行gallery属性添加对应的item
          value = JSON.stringify(gallery);
          currentGalleryAttribs.attribs[index] = [key, value];
        }
      });
      editorInfo.ace_callWithAce(function () {
        editorInfo.ace_performDocumentReplaceRangeWithAttributes(currentPosition.zone, [currentPosition.line, 0], [currentPosition.line, currentLineEntry.text.length], ' ', currentGalleryAttribs.attribs);
      }, 'dropImageEvent', true);
      eventType = 'drag_left_right';
      animationTime = 200;
      this.flexItemAnimation((0, _$rjquery.$)('#container-wrap-image-upload-image-' + targetNewUuid).get(0), 'in', true, animationTime);
      editorInfo.call('galleryImageChoosed', 'image-upload-image-' + targetNewUuid);
    } else if (this.dragImageInfo.currentGallery) {
      // 不同行
      // 拖至图片行
      if (this.dragImageInfo.currentGallery.items.length < 3) {
        console.log('drop image');
        this.dragImageInfo.currentGallery.items.splice(this.dragImageInfo.insertIndex, 0, this.dragImageInfo.cachedGalleryItemData);
        // 重设图片uuid
        this.dragImageInfo.currentGallery.items.forEach(function (item) {
          _this.resetUuidToObject(item);
        });
        var originPosition = this.dragImageInfo.originPosition;
        var _currentPosition = this.dragImageInfo.currentPosition;
        var _currentLineEntry = editorInfo.getRep(_currentPosition.zone).lines.atIndex(_currentPosition.line);
        var originlineEntry = editorInfo.getRep(originPosition.zone).lines.atIndex(originPosition.line);
        focusPosition = {
          line: _currentPosition.line,
          zone: _currentPosition.zone
        };
        editorInfo.inCallStackIfNecessary('dropImageEvent', function () {
          // 改变目标行数据结构,生成新dom
          editorInfo.ace_performDocumentReplaceRangeWithAttributes(_currentPosition.zone, [_currentPosition.line, 0], [_currentPosition.line, _currentLineEntry.text.length], ' ', [['gallery', JSON.stringify(_this.dragImageInfo.currentGallery)]]);
          if (_this.dragImageInfo.originGallery.items.length === 1) {
            // 移除旧行
            editorInfo.ace_performDocumentReplaceRangeWithAttributes(originPosition.zone, [originPosition.line, 0], [originPosition.line, originlineEntry.text.length], '');
          } else if (_this.dragImageInfo.originGallery.items.length > 1) {
            // 原行对应item移除
            editorInfo.spliceGalleryItemsAtLine(originPosition.zone, originPosition.line, _this.dragImageInfo.originIndex, 1);
          }
        });
        // 给对应index图片加选中状态
        var newLineNode = editorInfo.getRep(_currentPosition.zone).lines.atIndex(focusPosition.line).lineNode;
        var imageContainer = (0, _$rjquery.$)(newLineNode).find('.image-container')[this.dragImageInfo.insertIndex];
        var containerId = (0, _$rjquery.$)(imageContainer).attr('id');
        editorInfo.call('galleryImageChoosed', containerId);
        eventType = 'drag_become_parallel';
        animationTime = 200;
        this.flexItemAnimation(imageContainer.parentNode, 'in', true, animationTime);
      }
    } else if (!this.dragImageInfo.currentGallery && this.dragImageInfo.currentPosition) {
      // 拖拽的目标行为普通文字行
      var _originPosition = this.dragImageInfo.originPosition;
      var _currentPosition2 = this.dragImageInfo.currentPosition;
      var targetLineNum = _currentPosition2.line;
      var originLineNum = _originPosition.line;
      var currentPosLineEntry = editorInfo.getRep(_currentPosition2.zone).lines.atIndex(targetLineNum);
      this.resetUuidToObject(this.dragImageInfo.cachedGalleryItemData);
      var originItemGallery = JSON.stringify({
        items: [this.dragImageInfo.cachedGalleryItemData]
      });
      var removeLineNum = this.computeRemoveLineNum(_originPosition, _currentPosition2);
      focusPosition = {
        line: targetLineNum + 1,
        zone: _currentPosition2.zone
      };
      // 若原始行的 items 个数为 1 则原始行会被删除. 往下拖时，focusPos.line需要减少，否则 选区focus至图片下一行
      if (this.dragImageInfo.originGallery.items.length === 1 && targetLineNum > originLineNum && _originPosition.zone === _currentPosition2.zone) {
        focusPosition.line--;
      }
      var originLineNode = editorInfo.getRep(_originPosition.zone).lines.atIndex(originLineNum).lineNode;
      if ((0, _$rjquery.$)(originLineNode).find('img').length > 1) {
        animationTime = 150;
        this.flexItemAnimation(editorInfo.getChoosedImage().parentNode, 'out', false, animationTime);
      } else {
        animationTime = 0;
      }
      setTimeout(function () {
        editorInfo.ace_callWithAce(function () {
          // 插入行为最后一行
          if (targetLineNum + 1 === editorInfo.getRep(_currentPosition2.zone).alines.length) {
            editorInfo.performDocumentReplaceRange(_currentPosition2.zone, [targetLineNum, currentPosLineEntry.text.length], [targetLineNum, currentPosLineEntry.text.length], '\n');
          } else {
            // 在目标行行首插入换行符， 即新建空行
            editorInfo.performDocumentReplaceRange(_currentPosition2.zone, [targetLineNum + 1, 0], [targetLineNum + 1, 0], '\n');
          }
          editorInfo.ace_performDocumentReplaceRangeWithAttributes(_currentPosition2.zone, [targetLineNum + 1, 0], [targetLineNum + 1, 0], ' ', [['gallery', originItemGallery]]);

          if (!_this.dragImageInfo.compatMode) {
            // 原gallery item减少 || 删除旧行
            editorInfo.spliceGalleryItemsAtLine(_originPosition.zone, removeLineNum, _this.dragImageInfo.originIndex, 1);
          } else {
            // 图片为旧数据结构, 则只可能一行一图。 拖动结束后将其删除即可
            editorInfo.performDelete(removeLineNum);
          }
        }, 'dropImageEvent', true);
        eventType = 'drag_up_down';
      }, animationTime);
    }
    setTimeout(function () {
      _this.dragImageInfo = null;
      editorInfo.plugins.client.enable();
      _this.collectDragEvent(eventType);
      if (!focusPosition) return;
      // 触发selectionchange, 选中图片
      editorInfo.ace_inCallStackIfNecessary('dropImage', function () {
        editorInfo.ace_performSelectionChange(focusPosition.zone, [focusPosition.line, 0], [focusPosition.line, 0]);
      });
      editorInfo.ace_updateBrowserSelectionFromRep();
      // 滚动视图至拖拽目标行
      setTimeout(function () {
        var focusNode = editorInfo.getRep(focusPosition.zone).lines.atIndex(focusPosition.line).lineNode;
        // if (!this.isNodeInViewPort(focusNode)) {
        //   const scrollContainer = this.getScrollContainer(editorInfo);
        //   const top = $(focusNode).parents('.ace-line').length
        //     ? $(focusNode).parents('.ace-line').position().top : $(focusNode).position().top;
        //   scrollContainer.scrollTop = top - window.innerHeight + e.clientY;
        // }
        focusNode.scrollIntoViewIfNeeded();
        _this.reShowSelectionPopup();
      });
    }, animationTime);
  },
  stepApplyChangeWhenDrop: function stepApplyChangeWhenDrop(dragImageInfo) {
    dragImageInfo.currentGallery = null;
    dragImageInfo.isDropToSameLine = null;
    dragImageInfo.currentPosition = null;
  },
  holdCommentAttrIfNecessary: function holdCommentAttrIfNecessary(dragImageInfo) {
    var originPosition = dragImageInfo.originPosition,
        currentPosition = dragImageInfo.currentPosition;

    if (!originPosition) return;
    var originlineEntry = editorInfo.getRep(originPosition.zone).lines.atIndex(originPosition.line);
    var lineAttrs = editorInfo.ace_getAttributesOnSelection(originPosition.zone, {
      selStart: [originPosition.line, 0],
      selEnd: [originPosition.line, originlineEntry.text.length]
    }, false);
    var lineCommentAttrs = [];
    lineAttrs.attribs.forEach(function (_ref) {
      var _ref2 = (0, _slicedToArray3.default)(_ref, 2),
          key = _ref2[0],
          value = _ref2[1];

      key.indexOf('comment-') > -1 && lineCommentAttrs.push(key);
    });
    /* eslint-disable */
    // 若评论大块内容包括gallery， 拖动时需携带评论
    dragImageInfo.cachedGalleryItemData.comments = Array.from(new Set(dragImageInfo.cachedGalleryItemData.comments.concat(lineCommentAttrs)));
    if (!currentPosition || !dragImageInfo.currentGallery) return;
    // 目标行
    var currentLineEntry = editorInfo.getRep(currentPosition.zone).lines.atIndex(currentPosition.line);
    var currentLineAttrs = editorInfo.ace_getAttributesOnSelection(currentPosition.zone, {
      selStart: [currentPosition.line, 0],
      selEnd: [currentPosition.line, currentLineEntry.text.length]
    }, false);
    lineCommentAttrs = [];
    currentLineAttrs.attribs.forEach(function (_ref3) {
      var _ref4 = (0, _slicedToArray3.default)(_ref3, 2),
          key = _ref4[0],
          value = _ref4[1];

      key.indexOf('comment-') > -1 && lineCommentAttrs.push(key);
    });
    lineCommentAttrs.length && dragImageInfo.currentGallery.items.forEach(function (item, index) {
      item.comments = item.comments.concat(lineCommentAttrs);
      // 去重
      dragImageInfo.currentGallery.items[index].comments = Array.from(new Set(item.comments));
    });
    /* eslint-enable */
  },
  collectDragEvent: function collectDragEvent(eventType) {
    // 打点
    (0, _tea2.default)('client_edit_all_event', {
      'file_id': (0, _tea.getEncryToken)(),
      'file_type': (0, _tea.getFileType)(),
      'client_edit_all_event_type': 'image_edit',
      'client_edit_all_event_subtype': eventType
    });
  },
  hideSelectionPopup: function hideSelectionPopup() {
    var selectionPopup = (0, _$rjquery.$)('.selection-popup');
    var larkPopup = (0, _$rjquery.$)('.comment-line-popup');
    if (selectionPopup.length) {
      selectionPopup.get(0).classList.remove('selection-popup--visible');
    } else if (larkPopup.length) {
      larkPopup.get(0).classList.remove('comment-line-popup_active');
    }
  },
  reShowSelectionPopup: function reShowSelectionPopup() {
    var selectionPopup = (0, _$rjquery.$)('.selection-popup');
    var larkPopup = (0, _$rjquery.$)('.comment-line-popup');
    if (selectionPopup.length) {
      selectionPopup.get(0).classList.add('selection-popup--visible');
    } else if (larkPopup.length) {
      larkPopup.get(0).classList.add('comment-line-popup_active');
    }
  },
  isNodeInViewPort: function isNodeInViewPort(node) {
    var rect = node.getBoundingClientRect();
    return rect.top > 0 && rect.bottom < window.innerHeight;
  },
  resetUuidToObject: function resetUuidToObject(object) {
    var uuid = (0, _string.randomString)(10);
    object.uuid = uuid;
    imageUploadInstance[_const.uploadPrefix + '-ignore-' + uuid] = true;
    imageUploadInstance.decodeImages[uuid] = { finished: true };
  },
  updateSelectionToGallery: function updateSelectionToGallery(dragImageInfo) {
    // 更新选区
    editorInfo.ace_inCallStackIfNecessary('dropImage', function () {
      editorInfo.ace_performSelectionChange(dragImageInfo.originPosition.zone, [dragImageInfo.originPosition.line, 0], [dragImageInfo.originPosition.line, 0]);
    });
    editorInfo.ace_updateBrowserSelectionFromRep();
  },
  calcEditorPadding: function calcEditorPadding() {
    // innerdocbody.x + 1 即可获取到对应行
    return Math.max(0, (0, _$rjquery.$)('#innerdocbody').get(0).getBoundingClientRect().left);
  },
  changeOpacity: function changeOpacity(dragImageInfo, status) {
    var uuid = dragImageInfo.originGallery.items[dragImageInfo.originIndex].uuid;
    var $imgContainer = (0, _$rjquery.$)('#image-upload-image-' + uuid);
    editorInfo.getObserver().withoutRecordingMutations(function () {
      $imgContainer.css({
        opacity: status ? 0.5 : 1
      });
      if (dragImageInfo.originPosition.zone !== '0') {
        $imgContainer.closest('.ace-table-wrapper-outer ').find('.ace-table-toolbars').css({
          'opacity': status ? 0 : ''
        });
      }
    });
  },
  flexItemAnimation: function flexItemAnimation(node, status, shouldAddTimer, delay) {
    editorInfo.getObserver().withoutRecordingMutations(function () {
      node.classList.add('gallery-item-animate-' + status);
    });
    shouldAddTimer && setTimeout(function () {
      editorInfo.getObserver().withoutRecordingMutations(function () {
        node.classList.remove('gallery-item-animate-' + status);
      });
    }, delay);
  },
  scrollIfNeccessary: function scrollIfNeccessary(evt, dragImageInfo) {
    var _this2 = this;

    // PC或mobile导航栏
    var navigationBarHeight = (0, _$rjquery.$)('.navigation-bar-wrapper').height() || 50;
    var DELTA = Math.max(30, window.innerHeight / 10);
    var pageY = evt.originalEvent.pageY - window.pageYOffset;
    var needScrollDown = window.innerHeight - pageY < DELTA;
    var needScrollUp = pageY - navigationBarHeight < DELTA;
    if ((needScrollDown || needScrollUp) && !dragImageInfo.scrollTimerId && !dragImageInfo.isCommitting) {
      dragImageInfo.scrollTimerId = setInterval(function () {
        if (_browserHelper2.default.isMobile) {
          var delta = needScrollUp ? -2 : 2;
          window.scrollBy(0, delta);
        } else {
          var scrollDom = _this2.getScrollContainer(editorInfo);
          var originTop = scrollDom.scrollTop;
          scrollDom.scrollTop = needScrollUp ? originTop - 3 : originTop + 3;
        }
        _this2.removeUnderline();
      }, 15);
    } else if (!needScrollDown && !needScrollUp && dragImageInfo.scrollTimerId) {
      this.removeImageHint();
      this.clearScrollTimer(dragImageInfo);
    }
  },
  clearScrollTimer: function clearScrollTimer(dragImageInfo) {
    if (!dragImageInfo.scrollTimerId) return;
    window.clearInterval(dragImageInfo.scrollTimerId);
    dragImageInfo.scrollTimerId = null;
  },
  getScrollContainer: function getScrollContainer(editor) {
    var props = editor.getProps();
    var docbody = editor.getDocBody();
    var container = docbody.parentNode;
    if (props && props.scroller) {
      container = (0, _$rjquery.$)(docbody).parents(props.scroller).get(0);
    }
    return container;
  },
  isImageLine: function isImageLine(_ref5) {
    var line = _ref5.line,
        zone = _ref5.zone;

    var rep = editorInfo.ace_getRep(zone);
    var imageAttrib = rep.attributeManager.findAttributeOnLine(line, 'image-uploaded') || rep.attributeManager.findAttributeOnLine(line, 'gallery');
    return imageAttrib !== '';
  },
  getCursorTarget: function getCursorTarget(dragImageInfo, evt) {
    // 移动端偏移量
    var pageY = evt.originalEvent.pageY - window.pageYOffset;
    var pageX = evt.originalEvent.pageX - window.pageXOffset;
    // 获取当前拖拽目标行元素
    var offset = _browserHelper2.default.isMobile ? 1 : 45;
    var cursorTarget = document.elementFromPoint(dragImageInfo.editorPadding + offset, pageY);
    cursorTarget = (0, _$rjquery.$)(cursorTarget).closest('.ace-line').get(0);
    if ((0, _$rjquery.$)(cursorTarget).parents('.ace-table').length) {
      cursorTarget = (0, _$rjquery.$)(cursorTarget.parentElement).parents('.ace-line').get(0);
    }
    var table = (0, _$rjquery.$)(cursorTarget).find('.ace-table-wrapper');
    var res = void 0;
    if (table.length) {
      // 在table中
      var tables = table.get(0).querySelectorAll('td.ace-table-cell');
      for (var i = 0; i < tables.length; i++) {
        var tableRect = tables[i].getBoundingClientRect();
        if (tableRect.width < 100 && this.isCursorInRect(pageX, pageY, tableRect)) {
          this.hideDragCursor();
          // 移动端无法通过e.target获得
          res = _browserHelper2.default.isMobile ? document.elementFromPoint(pageX, pageY) : evt.target;
        } else if (this.isCursorInRect(pageX, pageY, tableRect)) {
          this.reShowDragCursor();
          this.updateDragCursorPos(evt.originalEvent.pageX, evt.originalEvent.pageY);
          res = document.elementFromPoint(Math.max(0, pageX - 50), pageY);
          // if (this.isCursorAtBottom(evt.originalEvent, table.get(0))) {
          //   res = table.get(0);
          // } else
          if (!tables[i].contains(res)) {
            res = tables[i];
          }
        }
        // 如果拖拽至某个cell, 拖拽位置没有行,即在最后一行下方, 则设置为最后一行
        if (res) {
          var aceLine = res.getElementsByClassName('ace-line');
          res = aceLine.length ? aceLine[aceLine.length - 1] : (0, _$rjquery.$)(res).closest('.ace-line').get(0);
          res = (0, _$rjquery.$)(res).closest('.ace-line').get(0);
          return res;
        }
      }
    }
    // 指向table, 但不在任何一个table cell中
    res = cursorTarget;
    this.reShowDragCursor();
    this.updateDragCursorPos(evt.originalEvent.pageX, evt.originalEvent.pageY);
    // 若为代码块则插入至代码块后方
    if ((0, _$rjquery.$)(cursorTarget).find('code').length && (0, _$rjquery.$)(cursorTarget).next().find('code').length) {
      return null;
    }
    return res;
  },
  isCursorInRect: function isCursorInRect(pageX, pageY, rect) {
    return pageX > rect.left && pageX < rect.right && pageY > rect.top && pageY < rect.bottom;
  },
  addUnderLineOnNode: function addUnderLineOnNode(node, _ref6) {
    var zone = _ref6.zone;
    var editorInfo = _image_view2.default.ace.editorInfo;

    var editorStatus = editorInfo.getEditStatus();
    var nodeId = (0, _$rjquery.$)(node).closest('.ace-line').attr('id');
    if (!editorStatus) return;
    if ((0, _$rjquery.$)('.underLine-' + nodeId).length !== 0) return;
    var mainZoneStyle = '\n    #innerdocbody #' + nodeId + ':after {\n      content: \' \';\n      display: block;\n      position: absolute;\n      width: calc(100% - 40px);\n      height: 2px;\n      padding-bottom: 0;\n      background-color: #0070e0;\n    }';
    var tableStyle = '\n    #innerdocbody #' + nodeId + ' {\n      border-bottom: 2px solid #0070e0;\n    }';
    var style = zone === '0' ? mainZoneStyle : tableStyle;
    (0, _$rjquery.$)('body').append('\n      <style id="galleryUnderlineStyle" class=\'underLine-' + nodeId + '\'>\n      ' + style + '\n      .mobile #innerdocbody #' + nodeId + ' {\n        border-width: 2px !important;\n      }\n      </style>\n      ');
  },
  removeUnderline: function removeUnderline() {
    (0, _$rjquery.$)('#galleryUnderlineStyle').remove();
  },
  addGalleryHintAtIndex: function addGalleryHintAtIndex(lineNode, dropHintIndex) {
    var editorInfo = _image_view2.default.ace.editorInfo;

    var editorStatus = editorInfo.getEditStatus();
    var enable = void 0;
    if (editorStatus && !_browserHelper2.default.isMobile) {
      enable = true;
    }
    if (!enable) return;
    editorInfo.getObserver().withoutRecordingMutations(function () {
      var hintNode = lineNode.getElementsByClassName('gallery-drop-hint')[dropHintIndex];
      if (hintNode) {
        hintNode.classList.add('gallery-drop-hint-visible');
        var items = (0, _$rjquery.$)(hintNode).closest('.ace-line').find('.image-container-wrap');
        (0, _forEach2.default)(items, function (item, index) {
          var direction = index < dropHintIndex ? 'left' : 'right';
          item.classList.add('gallery-item-scoot-' + direction);
        });
      } else {
        // 拖拽至旧图片时, drop hint
        var imageContainer = lineNode.getElementsByClassName('image-container')[0];
        var direction = dropHintIndex === 0 ? 'right' : 'left';
        imageContainer.classList.add('gallery-item-scoot-' + direction);
        imageContainer.parentNode.classList.add('compat-gallery-drop-hint-scoot-' + direction);
      }
    });
  },
  removeImageHint: function removeImageHint() {
    editorInfo.getObserver().withoutRecordingMutations(function () {
      var hintNode = document.getElementsByClassName('gallery-drop-hint-visible')[0];
      if (hintNode) {
        hintNode.classList.remove('gallery-drop-hint-visible');
        var items = (0, _$rjquery.$)(hintNode).parents('.ace-line').find('.image-container-wrap');
        (0, _forEach2.default)(items, function (item) {
          item.classList.remove('gallery-item-scoot-left');
          item.classList.remove('gallery-item-scoot-right');
        });
      } else {
        // 拖拽至旧图片时, drop hint
        if ((0, _$rjquery.$)('.gallery-item-scoot-left').length) {
          var node = (0, _$rjquery.$)('.gallery-item-scoot-left').get(0);
          node.classList.remove('gallery-item-scoot-left');
          node.parentNode.classList.remove('compat-gallery-drop-hint-scoot-left');
        } else if ((0, _$rjquery.$)('.gallery-item-scoot-right').length) {
          var _node = (0, _$rjquery.$)('.gallery-item-scoot-right').get(0);
          _node.classList.remove('gallery-item-scoot-right');
          _node.parentNode.classList.remove('compat-gallery-drop-hint-scoot-right');
        }
      }
    });
  },
  compatImageToGallery: function compatImageToGallery($img, editorInfo) {
    // 兼容旧image
    var spanClass = $img.closest('.image-uploaded').attr('class');
    var matcher = spanClass.match(/key=image-[\S]+/);
    var uploadAttrs = matcher ? matcher[0] : '';
    var attrsObj = (0, _utils.toObj)(uploadAttrs);
    var dragStartPos = editorInfo.selection.getPositionForNode($img.get(0));
    var imgAttribs = editorInfo.ace_getAttributesOnPosition(dragStartPos.zone, dragStartPos.line, dragStartPos.col);
    var imgRect = $img.get(0).getBoundingClientRect();
    var comments = [];
    imgAttribs.forEach(function (item) {
      var key = item[0];
      if (editorInfo.hasCommentAttr(key)) {
        comments.push(key);
      }
    });
    return JSON.stringify({
      items: [{
        attachmentId: 'attachment-id-' + attrsObj.uuid,
        type: 'image',
        // innerZone: ''    后续特性: 图片下方描述所在的zone
        src: attrsObj.src,
        pluginName: attrsObj.pluginName,
        uuid: attrsObj.uuid,
        naturalWidth: attrsObj.width,
        naturalHeight: attrsObj.height,
        decrypt_key: attrsObj.decrypt_key,
        cdn_url: attrsObj.cdn_url,
        thumbnail_cdn_url: attrsObj.thumbnail_cdn_url,
        webp_thumbnail_cdn_url: attrsObj.webp_thumbnail_cdn_url,
        height: imgRect.height + 'px',
        width: imgRect.width + 'px',
        scale: imgRect.width / imgRect.height,
        comments: comments
      }]
    });
  },
  isCursorAtBottom: function isCursorAtBottom(evt, node) {
    var rect = node.getBoundingClientRect();
    return evt.pageY < rect.bottom && evt.pageY > rect.bottom - rect.height / 10;
  },
  getDropHintIndex: function getDropHintIndex(lineNode, evt) {
    var cursorPos = {
      x: evt.pageX,
      y: evt.pageY
    };
    var galleryJSON = (0, _$rjquery.$)(lineNode).find('.image-uploaded').attr('data-ace-gallery-json');
    var gallery = galleryJSON && JSON.parse(galleryJSON);
    // 若无gallery, 则代表鼠标指向的为旧数据结构, 则数量只可能为 1
    var itemCount = gallery ? gallery.items.length : 1;
    var lineWidth = (0, _$rjquery.$)(lineNode).width();
    var lineOffsetLeft = (0, _$rjquery.$)(lineNode).offset().left;
    var s = Math.max(0, Math.min(cursorPos.x - lineOffsetLeft, lineWidth - 1));
    var insertIndex = Math.floor(s / lineWidth * (itemCount + 1));
    console.log(insertIndex);
    return insertIndex;
  },
  // 初始化拖拽光标
  initDragCursor: function initDragCursor(dragImageInfo, evt) {
    var dragCursor = document.createElement('div');
    dragCursor.className = 'drag-cursor';
    var cloneImage = (0, _$rjquery.$)(evt.target).clone(1);
    cloneImage[0].className = '';
    cloneImage.addClass('gallery-item').attr('style', '');
    cloneImage.attr('unselectable', 'true');
    cloneImage.attr('contenteditable', 'false');
    cloneImage.css({
      'user-select': 'none',
      'cursor': 'grabbing'
    });
    dragCursor.appendChild(cloneImage[0]);
    dragImageInfo.dragCursor = dragCursor;
    (0, _$rjquery.$)(dragImageInfo.dragCursor).css({
      top: evt.originalEvent.pageY,
      left: evt.originalEvent.pageX
    });
    (0, _$rjquery.$)(dragImageInfo.dragCursor).appendTo(document.body);
  },
  // 更新光标位置
  updateDragCursorPos: function updateDragCursorPos(pageX, pageY) {
    (0, _$rjquery.$)('.drag-cursor').css({
      top: pageY,
      left: pageX
    });
  },
  hideDragCursor: function hideDragCursor() {
    (0, _$rjquery.$)('.drag-cursor').css({
      display: 'none'
    });
  },
  reShowDragCursor: function reShowDragCursor() {
    (0, _$rjquery.$)('.drag-cursor').css({
      display: ''
    });
  },
  removeDragCursor: function removeDragCursor() {
    (0, _$rjquery.$)('.drag-cursor').remove();
  },
  handleAndroidScroll: function handleAndroidScroll(e) {
    if (this.dragImageInfo && this.dragImageInfo.isDraging) {
      e.preventDefault();
      window.scrollBy(0, 0);
    }
  },
  computeRemoveLineNum: function computeRemoveLineNum(originPosition, currentPosition) {
    var _ref7 = [originPosition.line, currentPosition.line],
        originLineNum = _ref7[0],
        targetLineNum = _ref7[1];

    if (originPosition.zone !== currentPosition.zone) {
      return originLineNum;
    } else {
      // hack 相等的情况则为单行多图中的某张图片拖动至当前行下方
      return targetLineNum >= originLineNum ? originLineNum : originLineNum + 1;
    }
  },

  unbind: function unbind() {
    // 移动端点击图片的preview PC端加选中样式
    var innerContainer = editorInfo.ace_getInnerContainer();
    (0, _$rjquery.$)(innerContainer).off('touchstart', '.image-uploaded', this._handleMobileImgTouch);
    (0, _$rjquery.$)(innerContainer).off('touchmove', '.image-uploaded', this._handleMobileImgTouch);
    (0, _$rjquery.$)(innerContainer).off('touchend', '.image-uploaded', this._handleMobileImgTouch);

    // 取消选中图片样式
    (0, _$rjquery.$)(innerContainer).off('click', this.handleRemoveImageChoose);

    (0, _$rjquery.$)(document).off('mousemove', this.handleResizeMove);
    (0, _$rjquery.$)(document).off('mousedown', '.point', this.handleResizeDown);
    (0, _$rjquery.$)(document).off('mouseup', this.handleResizeUp);
    (0, _$rjquery.$)(innerContainer).off('paste dragenter dragover dragleave drop', this.modifyHandle);
    (0, _$rjquery.$)(document).off('beforeunload unload load', _image_view2.default.clearAllImagePreviewer);

    this.modifyHandle = null;
    ace = null;
    editorInfo = null;
  },
  bind: function bind(_ace, uploadInstance) {
    ace = _ace;
    editorInfo = ace.editorInfo;
    imageUploadInstance = uploadInstance;
    var resizeHandles = handleImageResize();
    this.handleResizeMove = (0, _underscore.throttle)(resizeHandles.handleMouseMove, 16);
    this.handleResizeDown = resizeHandles.handleMouseDown;
    this.handleResizeUp = resizeHandles.handleMouseUp;
    this.modifyHandle = handleModify();

    this._hanldeDragMoveImage = (0, _underscore.throttle)(this.handleDragMove.bind(this), 16);

    // 移动端点击图片的preview
    // 当光标位于图片时，点击toolbar会触发click事件导致图片被预览
    var innerContainer = editorInfo.ace_getInnerContainer();
    this._handleMobileImgTouch = handleMobileImgTouch().bind(this, editorInfo);
    (0, _$rjquery.$)(innerContainer).on('touchstart', '.image-uploaded', this._handleMobileImgTouch);
    (0, _$rjquery.$)(innerContainer).on('touchmove', '.image-uploaded', this._handleMobileImgTouch);
    (0, _$rjquery.$)(innerContainer).on('touchend', '.image-uploaded', this._handleMobileImgTouch);

    // 取消选中图片样式
    (0, _$rjquery.$)(innerContainer).on('click', this.handleRemoveImageChoose);

    (0, _$rjquery.$)(document).on('mousemove', this.handleResizeMove);
    (0, _$rjquery.$)(document).on('mousedown', '.point', this.handleResizeDown);
    (0, _$rjquery.$)(document).on('mouseup', this.handleResizeUp);
    (0, _$rjquery.$)(innerContainer).on('paste dragenter dragover dragleave drop', this.modifyHandle);
    (0, _$rjquery.$)(document).on('beforeunload unload', _image_view2.default.clearAllImagePreviewer);
  }
};

/***/ }),

/***/ 3824:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/**
 * PinchZoom: Support pinching and zooming on an element.
 *
 * @codingstandard ftlabs-jsv2
 * @copyright The Financial Times Limited [All rights reserved]
 */

/*jshint node:true*/



module.exports = PinchZoom;
module.exports.PinchZoom = PinchZoom;


/**
 * Master constructor for a pinch/zoom handler on an image.
 * By default, the parent element will be used as the container in which to constrain the image;
 * specify this.containerNode to override this.
 *
 * Images will be initially displayed at to-fit size, using a scale transform for speed.
 *
 * TODO:RB:20111130: While this could be extended to other elements using a 3d transform (scale),
 * rendering within that element would be blurry, so doesn't seem worth implementing at the moment.
 *
 * TODO:RB:20111201: Additional elements - pinch-zoom instruction and zoom controls - rely on parent
 * page to style them...
 */
function PinchZoom(image, containerNode, options) {

	var defaultConfig = {
            maxScale:           2.5,
            hardScaleLimit:     false,
            stepZoomIncrement:  0.25,
            animationDuration:  0.5,   // (seconds)
            zoomControlClass:   'pinchzoomcontrol',
            zoomControlMessage: 'Drag image to pan; pinch to zoom',
			zoomControlText: {
				zoomin:  '+',
				zoomout: '-'
			}
		},

		Listeners = __webpack_require__(3825),

		cssPrefix = __webpack_require__(3826);

	// Ensure this is an instantiated object, enabling eg. require('pinchzoom')(image, ...)
	if (!(this instanceof PinchZoom)) return new PinchZoom(image, containerNode, options);

	if (!(image instanceof HTMLImageElement) || !image.parentNode) {
		throw new TypeError('PinchZoom requires an Image node which is inserted in the DOM');
	}

	this.config = __webpack_require__(3827)(defaultConfig, options);
	if (!this.config.zoomControlText || !this.config.zoomControlText.zoomin || !this.config.zoomControlText.zoomout) {
		throw new TypeError('zoomControlText must be an object in the form {zoomin: "+", zoomout: "-"}.');
	}

	this.cssTransform                = cssPrefix.transform;
	this.cssTransformOrigin          = this.cssTransform + 'Origin';
	this.cssTransitionProperty       = cssPrefix.transition + 'Property';
	this.cssTransitionTimingFunction = cssPrefix.transition + 'TimingFunction';
	this.cssTransitionDuration       = cssPrefix.transition + 'Duration';
	this.trackPointerEvents          = __webpack_require__(1953);
	this.multitouchSupport           = __webpack_require__(3828);

	this.image               = image;
	this.imageStyle          = this.image.style;
	this.containerNode       = containerNode || this.image.parentNode;
	this.listeners           = new Listeners(this.containerNode, this);
	this.documentListeners   = new Listeners(document, this);

	this.imageDimensions     = { w: this.image.naturalWidth, h: this.image.naturalHeight };
	this.offset              = { x: 0, y: 0, savedX: 0, savedY: 0 };
	this.roundFactor         = window.devicePixelRatio || 1;

	this.activeInputs        = { length: 0 };
	this.allowClickEvent     = true;
	this.trackingInput       = false;
	this.capturedInputs      = {};

	this.animationTimeout    = false;
	this.mouseWheelThrottle  = false;

	// Set and reset base styles on the image
	this.imageStyle.position                     = 'absolute';
	this.imageStyle.top                          = 0;
	this.imageStyle.left                         = 0;
	this.imageStyle.height                       = 'auto';
	this.imageStyle.width                        = 'auto';
	this.imageStyle.maxWidth                     = 'none';
	this.imageStyle.maxHeight                    = 'none';
	this.imageStyle[this.cssTransformOrigin]          = '0 0';
	this.imageStyle[this.cssTransitionProperty]       = 'scale, translate';
	this.imageStyle[this.cssTransitionTimingFunction] = 'ease-out';

	this.update();

	if (this.trackPointerEvents) {
		this.listeners.bind('MSPointerDown', 'onPointerDown');
		this.listeners.bind('MSPointerMove', 'onPointerMove');
		this.listeners.bind('MSPointerUp', 'onPointerUp');
		this.listeners.bind('MSPointerCancel', 'onPointerCancel');
	} else if (this.multitouchSupport) {
		this.listeners.bind('touchstart', 'onTouchStart');
		this.listeners.bind('touchmove', 'onTouchMove');
		this.listeners.bind('touchend', 'onTouchEnd');
		this.listeners.bind('touchcancel', 'onTouchCancel');
	} else {
		this.listeners.bind('mousewheel', 'onMouseWheel');
		this.listeners.bind('DOMMouseScroll', 'onMouseWheel');
		this.listeners.bind('mousedown', 'onMouseDown');
	}
	this.listeners.bind('click', 'onClick');
}


/* TOUCH INPUT HANDLERS */

PinchZoom.prototype.onTouchStart = function(event) {
	var i, l, eachTouch, newIdentifier;

	// Ignore touches past the second
	if (this.activeInputs.length >= 2) {
		return;
	}

	// Record initial event details
	for (i = 0, l = event.targetTouches.length; i < l; i++) {
		eachTouch = event.targetTouches[i];
		if (this.activeInputs.length >= 2 || this.activeInputs[eachTouch.identifier] !== undefined) {
			continue;
		}

		this.activeInputs[eachTouch.identifier] = {
			originX: eachTouch.clientX,
			originY: eachTouch.clientY,
			lastX: false,
			lastY: false,
			time: event.timeStamp
		};
		this.activeInputs.length++;
		newIdentifier = eachTouch.identifier;
	}

	// Process the events as appropriate
	this.processInputStart(newIdentifier);

	event.preventDefault();
	event.stopPropagation();
};

PinchZoom.prototype.onTouchMove = function(event) {
	var i, l, eachTouch, trackedTouch;

	if (!this.activeInputs.length) {
		return;
	}

	// Update touch event movements
	for (i = 0, l = event.touches.length; i < l; i++) {
		eachTouch = event.touches[i];
		if (this.activeInputs[eachTouch.identifier] === undefined) {
			continue;
		}

		trackedTouch = this.activeInputs[eachTouch.identifier];
		trackedTouch.lastX = eachTouch.clientX;
		trackedTouch.lastY = eachTouch.clientY;
		trackedTouch.time = event.timeStamp;
	}

	// Trigger an element update in response to the move
	this.processInputMove();

	event.preventDefault();
	event.stopPropagation();
};

PinchZoom.prototype.onTouchEnd = function(event) {
	var i, l, eachTouch, touchesDeleted = 0;

	for (i = 0, l = event.changedTouches.length; i < l; i++) {
		eachTouch = event.changedTouches[i];
		if (this.activeInputs[eachTouch.identifier] !== undefined) {
			delete this.activeInputs[eachTouch.identifier];
			this.releaseCapture(eachTouch.identifier);
			touchesDeleted++;
		}
	}
	this.activeInputs.length -= touchesDeleted;

	// If no touches were deleted, no further action required
	if (touchesDeleted === 0) {
		return;
	}

	// Reset the origins of the remaining touches to allow changes to take
	// effect correctly
	for (i in this.activeInputs) {
		if (this.activeInputs.hasOwnProperty(i)) {
			eachTouch = this.activeInputs[i];
			if (typeof eachTouch !== 'object' || eachTouch.lastX === false) {
				continue;
			}
			eachTouch.originX = eachTouch.lastX;
			eachTouch.originY = eachTouch.lastY;
		}
	}

	// If there are no touches remaining, clean up
	if (!this.activeInputs.length) {
		this.processInputEnd();
	}
};

PinchZoom.prototype.onTouchCancel = function() {
	var i;

	if (!this.activeInputs.length) {
		return;
	}

	for (i in this.activeInputs) {
		if (this.activeInputs.hasOwnProperty(i)) {
			if (i === 'length') {
				continue;
			}
			delete this.activeInputs[i];
		}
	}
	this.activeInputs.length = 0;
	this.processInputEnd();
};


/* MOUSE INPUT HANDLERS */

PinchZoom.prototype.onMouseDown = function(event) {

	// Don't track the right mouse buttons
	if (event.button && event.button === 2) return;

	this.activeInputs.click = {
		originX: event.clientX,
		originY: event.clientY,
		lastX: false,
		lastY: false,
		time: event.timeStamp
	};
	this.activeInputs.length = 1;

	// Add move & up handlers to the *document* to allow handling outside the element
	this.documentListeners.bind('mousemove', 'onMouseMove');
	this.documentListeners.bind('mouseup', 'onMouseUp');

	event.preventDefault();
	this.processInputStart(false);
};

PinchZoom.prototype.onMouseMove = function(event) {
	if (!this.activeInputs.length) {
		return;
	}

	this.activeInputs.click.lastX = event.clientX;
	this.activeInputs.click.lastY = event.clientY;
	this.activeInputs.click.time = event.timeStamp;

	this.processInputMove();

	this.allowClickEvent = false;
	event.preventDefault();
};

PinchZoom.prototype.onMouseUp = function() {
	if (!this.activeInputs.length) {
		return;
	}

	this.documentListeners.unbind('mousemove', 'onMouseMove');
	this.documentListeners.unbind('mouseup', 'onMouseUp');

	delete this.activeInputs.click;
	this.activeInputs.length = 0;

	this.processInputEnd();
};

PinchZoom.prototype.onMouseWheel = function(event) {

	var self = this;

	if (this.mouseWheelThrottle) {
		return;
	}

	this.mouseWheelThrottle = window.setTimeout(function _cancelThrottle() {
		self.mouseWheelThrottle = null;
	}, 200);

	if (event.wheelDelta > 0) {
		this.stepZoom('in');
	} else if (event.wheelDelta < 0) {
		this.stepZoom('out');
	}

	event.stopPropagation();
	event.preventDefault();
	return false;
};


/* POINTER INPUT HANDLERS */

PinchZoom.prototype.onPointerDown = function(event) {

	// Ignore pointers past the second
	if (this.activeInputs.length >= 2) {
		return;
	}

	// Track the pointer
	this.activeInputs[event.pointerId] = {
		originX: event.clientX,
		originY: event.clientY,

		// COMPLEX:MA:20120528 Set the last position to be the same as the origin
		// otherwise the calculations in processInputMove fail. (redmine #7923)
		lastX: event.clientX,
		lastY: event.clientY,
		time: event.timeStamp
	};
	this.activeInputs.length++;

	// Process the events as appropriate
	this.processInputStart(event.pointerId);
};

PinchZoom.prototype.onPointerMove = function(event) {
	var trackedTouch;
	if (this.activeInputs[event.pointerId] === undefined) {
		return;
	}

	// Update this tracked move
	trackedTouch = this.activeInputs[event.pointerId];
	trackedTouch.lastX = event.clientX;
	trackedTouch.lastY = event.clientY;
	trackedTouch.time = event.timeStamp;

	// Prevent clicks after a small move
	if (this.allowClickEvent) {
		if ((Math.abs(trackedTouch.originX - trackedTouch.lastX) > 2) || (Math.abs(trackedTouch.originY - trackedTouch.lastY) > 2)) {
			this.allowClickEvent = false;
		}
	}

	// Trigger an element update in response to the move
	this.processInputMove();

	event.preventDefault();
};

PinchZoom.prototype.onPointerUp = function(event) {
	var i, eachTouch;

	if (this.activeInputs[event.pointerId] === undefined) {
		return;
	}

	delete this.activeInputs[event.pointerId];
	this.activeInputs.length--;
	this.releaseCapture(event.pointerId);

	// Reset the origins of the remaining touches to allow changes to take
	// effect correctly
	for (i in this.activeInputs) {
		if (this.activeInputs.hasOwnProperty(i)) {
			eachTouch = this.activeInputs[i];
			if (typeof eachTouch !== 'object' || eachTouch.lastX === false) {
				continue;
			}
			eachTouch.originX = eachTouch.lastX;
			eachTouch.originY = eachTouch.lastY;
		}
	}

	// If there are no touches remaining, clean up
	if (!this.activeInputs.length) {
		this.processInputEnd();
	}
};

PinchZoom.prototype.onPointerCancel = function() {
	var i;

	if (!this.activeInputs.length) {
		return;
	}

	for (i in this.activeInputs) {
		if (this.activeInputs.hasOwnProperty(i)) {
			if (i === 'length') {
				continue;
			}
			delete this.activeInputs[i];
		}
	}

	this.activeInputs.length = 0;

	this.processInputEnd();
};


PinchZoom.prototype.captureInput = function(identifier) {
	if (identifier === false || this.capturedInputs.identifier) {
		return;
	}

	// Capture pointers on IE 10+
	if (this.trackPointerEvents) {
		this.containerNode.msSetPointerCapture(identifier);
		this.listeners.bind('MSLostPointerCapture', 'onPointerCancel');
	}

	this.capturedInputs[identifier] = true;
};

PinchZoom.prototype.releaseCapture = function(identifier) {
	if (identifier === false || !this.capturedInputs.identifier) {
		return;
	}

	if (this.trackPointerEvents) {
		this.listeners.unbind('MSLostPointerCapture', 'onPointerCancel');
		this.containerNode.msReleasePointerCapture(identifier);
	}

	delete this.capturedInputs[identifier];
};

PinchZoom.prototype.releaseAllCapturedInputs = function() {
	var i;

	for (i in this.capturedInputs) {
		if (this.capturedInputs.hasOwnProperty(i)) {
			this.releaseCapture(i);
			delete this.capturedInputs[i];
		}
	}
};

/**
 * Input-triggered click
 */
PinchZoom.prototype.onClick = function(event) {
	if (!this.allowClickEvent) {
		event.stopPropagation();
		event.preventDefault(true);
		return false;
	}
	return true;
};

/**
 * A click on the + or - buttons
 */
PinchZoom.prototype.onStepZoomClick = function(direction, event) {

	this.stepZoom(direction);

	event.stopPropagation();
	event.preventDefault();
	return false;
};








/* POSITIONING */

PinchZoom.prototype.updateDimensions = function() {

	var style  = window.getComputedStyle(this.containerNode),
		width  = this.containerNode.offsetWidth,
		height = this.containerNode.offsetHeight,
		tp     = parseInt(style.paddingTop, 10),
		lp     = parseInt(style.paddingLeft, 10),
		bp     = parseInt(style.paddingBottom, 10),
		rp     = parseInt(style.paddingRight, 10),
		tb     = parseInt(style.borderTopWidth, 10),
		lb     = parseInt(style.borderLeftWidth, 10),
		bb     = parseInt(style.borderBottomWidth, 10),
		rb     = parseInt(style.borderRightWidth, 10);

	this.containerDimensions = {
		tp: tp,
		lp: lp,
		bp: bp,
		rp: rp,
		tb: tb,
		lb: lb,
		bb: bb,
		rb: rb,
		w:  width - lp - rp - lb - rb,
		h:  height - tp - bp - tb - bb
	};

	// Set scale to fit
	this.scale      = Math.min(1.0, this.containerDimensions.w / this.imageDimensions.w, this.containerDimensions.h / this.imageDimensions.h);
	this.scaleSaved = this.scale;
};

PinchZoom.prototype.updatePosition = function() {

	var x, y;

	// Begin with the current offsets
	x = this.offset.x;
	y = this.offset.y;

	// Modify by the original container's padding
	x += this.containerDimensions.lp;
	y += this.containerDimensions.tp;

	// Modify so that a position of 0,0 will be centered in the container;
	// the CSS style rules will result in a top-left basis for simplicity.
	x += (this.containerDimensions.w - (this.imageDimensions.w * this.scale)) / 2;
	y += (this.containerDimensions.h - (this.imageDimensions.h * this.scale)) / 2;

	// Amend with the current scale factor and round to nearest pixel
	x = Math.round(x / this.scale * this.roundFactor) / this.roundFactor;
	y = Math.round(y / this.scale * this.roundFactor) / this.roundFactor;

	// Render
	this.imageStyle[this.cssTransform] = 'scale('+this.scale+') translate3d(' + x + 'px,' + y + 'px,0)';
};

PinchZoom.prototype.updatePositionWithAnimationDuration = function() {

	var self = this;

	this.imageStyle[this.cssTransitionDuration] = this.config.animationDuration + 's';
	this.updatePosition();
	this.animationTimeout = window.setTimeout(function() {
		self.imageStyle[this.cssTransitionDuration] = '0s';
		self.animationTimeout = false;
	}, this.config.animationDuration * 1000);
};

/**
 * Process the start of a touch-like input, starting the image move
 * or changing to a zoom/pan as appropriate.
 */
PinchZoom.prototype.processInputStart = function(identifier) {
	var i, eachTouch;

	// Start a move if approprate
	if (!this.trackingInput) {

		this.trackingInput = true;
		this.allowClickEvent = true;
		this.offset.x = 0;
		this.offset.y = 0;
		this.imageStyle[this.cssTransitionDuration] = '0s';

	// For subsequent touches, reset all drag origins to the current position to allow
	// multitouch to alter behaviour correctly
	} else {
		for (i in this.activeInputs) {
			if (this.activeInputs.hasOwnProperty(i)) {
				eachTouch = this.activeInputs[i];
				if (typeof eachTouch !== 'object' || eachTouch.lastX === false) {
					continue;
				}

				eachTouch.originX = eachTouch.lastX;
				eachTouch.originY = eachTouch.lastY;
			}
		}

		this.offset.savedX = this.offset.x;
		this.offset.savedY = this.offset.y;
		this.scaleSaved = this.scale;
	}

	// Capture each input if appropriate
	this.captureInput(identifier);
};

// During movements, update the position according to event position changes, possibly
// including multiple points
PinchZoom.prototype.processInputMove = function() {

	var e1, e2, k;

	if (!this.trackingInput) {
		return;
	}

	// Work out a new image scale if there's multiple touches
	if (this.activeInputs.length === 2) {
		for (k in this.activeInputs) {
			if (this.activeInputs.hasOwnProperty(k)) {
				if (k === 'length') {
					continue;
				}
				if (!e1) {
					e1 = this.activeInputs[k];
				} else {
					e2 = this.activeInputs[k];
				}
			}
		}
		var originalDistance = Math.sqrt(Math.pow(e2.originX - e1.originX, 2) + Math.pow(e2.originY - e1.originY, 2));
		var newDistance = Math.sqrt(Math.pow(e2.lastX - e1.lastX, 2) + Math.pow(e2.lastY - e1.lastY, 2));

		this.scale = this.scaleSaved * (newDistance / originalDistance);
		if (this.config.hardScaleLimit) {
			this.scale = Math.min(this.config.maxScale, this.scale);
		}
	}

	// Work out a new image offset position
	var totalX = 0;
	var totalY = 0;
	for (k in this.activeInputs) {
		if (this.activeInputs.hasOwnProperty(k)) {
			if (k === 'length') {
				continue;
			}
			totalX += this.activeInputs[k].lastX - this.activeInputs[k].originX;
			totalY += this.activeInputs[k].lastY - this.activeInputs[k].originY;
		}
	}
	this.offset.x = this.offset.savedX + (totalX / this.activeInputs.length);
	this.offset.y = this.offset.savedY + (totalY / this.activeInputs.length);
	this.updatePosition();
};

// At the end of moves, snap the scale or position back to within bounds if appropriate
PinchZoom.prototype.processInputEnd = function() {
	if (!this.trackingInput) {
		return;
	}

	this.offset.savedX = this.offset.x;
	this.offset.savedY = this.offset.y;
	this.scaleSaved = this.scale;
	this.trackingInput = false;

	// Snap back scale
	var targetScale = Math.max(this.scale, Math.min(1.0, this.containerDimensions.w/this.imageDimensions.w, this.containerDimensions.h/this.imageDimensions.h));
	if (targetScale > this.config.maxScale) targetScale = this.config.maxScale;

	// Snap back position.
	var pos = {
		imageX: Math.ceil(this.imageDimensions.w * targetScale / 2),
		imageY: Math.ceil(this.imageDimensions.h * targetScale / 2),
		containerX: Math.ceil(this.containerDimensions.w / 2),
		containerY: Math.ceil(this.containerDimensions.h / 2),
		offsetX: Math.ceil(this.offset.x / targetScale),
		offsetY: Math.ceil(this.offset.y / targetScale)
	};

	// If the image is smaller in width than the container, recenter; otherwise, move edges out
	if (this.imageDimensions.w * targetScale <= this.containerDimensions.w) {
		this.offset.x = 0;
	} else if (pos.containerX + pos.offsetX > pos.imageX) {
		this.offset.x = Math.round((pos.imageX - pos.containerX) * targetScale);
	} else if (pos.containerX > pos.offsetX + pos.imageX) {
		this.offset.x = Math.round((pos.containerX - pos.imageX) * targetScale);
	}

	// Do the same for height
	if (this.imageDimensions.h * targetScale <= this.containerDimensions.h) {
		this.offset.y = 0;
	} else if (pos.containerY + pos.offsetY > pos.imageY) {
		this.offset.y = Math.round((pos.imageY - pos.containerY) * targetScale);
	} else if (pos.containerY > pos.offsetY + pos.imageY) {
		this.offset.y = Math.round((pos.containerY - pos.imageY) * targetScale);
	}

	// If nothing has changed, no snap required
	if (targetScale === this.scale && this.offset.savedX === this.offset.x && this.offset.savedY === this.offset.y) {
		return;
	}
	this.scaleSaved = this.scale = targetScale;
	this.offset.savedX = this.offset.x;
	this.offset.savedY = this.offset.y;

	this.updatePositionWithAnimationDuration();
	this.releaseAllCapturedInputs();
};

PinchZoom.prototype.stepZoom = function(direction) {
	if (direction === 'out') {
		this.scale = Math.max(Math.min(1.0, this.containerDimensions.w/this.imageDimensions.w, this.containerDimensions.h/this.imageDimensions.h), this.scale - this.config.stepZoomIncrement);
	} else {
		this.scale = Math.min(this.config.maxScale, this.scale + this.config.stepZoomIncrement);
	}
	this.scaleSaved = this.scale;

	this.updatePositionWithAnimationDuration();
};

/**
 * Zoom in to the image by one step
 */
PinchZoom.prototype.zoomIn = function() {
	return this.stepZoom('in');
};

/**
 * Zoom out of the image by one step
 */
PinchZoom.prototype.zoomOut = function() {
	return this.stepZoom('out');
};

/**
 * Creates controls in the supplied element.
 */
PinchZoom.prototype.addControlsTo = function(anEle) {

	var singleZoomControlClass = this.config.zoomControlClass + ' ' + this.config.zoomControlClass + '_zoom';

	if (!anEle || !anEle.appendChild) throw new TypeError('addControlsTo requires a valid DOM node');

	if (!this.zoomControls) {

		this.zoomControls = document.createElement('DIV');
		this.zoomControls.className = this.config.zoomControlClass + 's';
		if (this.multitouchSupport) {

			// TODO: this needs testing
			if (this.config.zoomControlMessage) this.zoomControls.innerHTML = '<div class="' + this.config.zoomControlClass + '_message">' + this.config.zoomControlMessage + '</div>';
		} else {
			this.zoomControls.innerHTML = '<button class="' + singleZoomControlClass + 'out">' + this.config.zoomControlText.zoomout + '</button>' +
											'<button class="' + singleZoomControlClass + 'in">' + this.config.zoomControlText.zoomin + '</button>';
			this.zoomControls.getElementsByClassName(singleZoomControlClass + 'out')[0].addEventListener('click', this.onStepZoomClick.bind(this, 'out'), false);
			this.zoomControls.getElementsByClassName(singleZoomControlClass + 'in')[0].addEventListener('click', this.onStepZoomClick.bind(this, 'in'), false);
		}
	}

	anEle.appendChild(this.zoomControls);
};

/**
 * Unbinds all event listeners to prevent circular references preventing
 * items from being deallocated, and clean up references to dom elements.
 */
PinchZoom.prototype.destroy = function() {

	this.listeners.unbindAll();
	this.documentListeners.unbindAll();

	this.containerNode     =
	this.image             =
	this.zoomControls      =
	this.listeners         =
	this.documentListeners = null;

};

PinchZoom.prototype.update = function() {

	if (!this.containerNode) {
		return false;
	}

	this.updateDimensions();
	this.updatePosition();
};










/***/ }),

/***/ 3825:
/***/ (function(module, exports) {

module.exports = Listeners;

function Listeners(el, obj) {
    this.el        = el;
    this.obj       = obj;
    this._bindings = {};
}
Listeners.prototype.bind = function(type, method) {
	this.el.addEventListener(type, this.addBinding(type, method));
};
Listeners.prototype.unbind = function(type, method) {
	this.el.removeEventListener(type, this._bindings[type][method]);
};
Listeners.prototype.addBinding = function(type, method) {
	this._bindings[type] = this._bindings[type] || {};
	this._bindings[type][method] = this.obj[method].bind(this.obj);
	return this._bindings[type][method];
};
Listeners.prototype.unbindAll = function() {
	var type, method;
	for (type in this._bindings) {
		for (method in this._bindings[type]) {
			this.unbind(type, method);
		}
	}
};


/***/ }),

/***/ 3826:
/***/ (function(module, exports) {

var prefix = (window.opera && Object.prototype.toString.call(window.opera) === '[object Opera]') ? 'o' :
					(document.documentElement.style.hasOwnProperty('MozAppearance')) ? 'Moz' :
					(document.documentElement.style.hasOwnProperty('WebkitAppearance')) ? 'webkit' :
					(typeof navigator.cpuClass === 'string') ? 'ms' : '';

module.exports = {
	transform:  (prefix ? prefix + 'T' : 't') + 'ransform',
	transition: (prefix ? prefix + 'T' : 't') + 'ransition'
};

/***/ }),

/***/ 3827:
/***/ (function(module, exports) {

module.exports = function(defaults, options) {

	var obj = {},
		i;

	options = Object(options);

	for (i in defaults) {
		if (defaults.hasOwnProperty(i)) {
			obj[i] = (options[i] === undefined) ? defaults[i] : options[i];
		}
	}

	return obj;
};

/***/ }),

/***/ 3828:
/***/ (function(module, exports, __webpack_require__) {

// Determine whether multitouch is supported.
// There appears to be no nice programmatic way to detect this.  Devices which support multitouch include
// iOS, Android 3.0+, PlayBook, but not WebOS.  Across these devices it therefore tracks SVG support
// accurately - use this test, which might be overly generous on future devices, but works on current devices.


module.exports = __webpack_require__(1953) ? (window.navigator.msMaxTouchPoints && window.navigator.msMaxTouchPoints > 1) :
							(__webpack_require__(3829) && document.implementation.hasFeature('http://www.w3.org/TR/SVG11/feature#BasicStructure', '1.1'));


/***/ }),

/***/ 3829:
/***/ (function(module, exports, __webpack_require__) {

module.exports = !__webpack_require__(1953) && window.ontouchstart !== undefined;

/***/ }),

/***/ 3830:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _$rjquery = __webpack_require__(552);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var DragImageInfo = function DragImageInfo() {
    var _this = this;

    (0, _classCallCheck3.default)(this, DragImageInfo);

    // getItemGalleryIndex: (node: any) => number;
    // getGalleryData: () => GalleryInterface;
    // getItems: () => GalleryItem[];
    this.getItemGalleryIndex = function (node) {
        return parseInt((0, _$rjquery.$)(node).closest('[data-gallery-index]').attr('data-gallery-index'), 10);
    };
    this.getGalleryData = function () {
        return JSON.parse(_this.galleryJSONData);
    };
    this.getItems = function () {
        return _this.getGalleryData().items;
    };
};

exports.default = DragImageInfo;

/***/ }),

/***/ 3831:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.isShortCut = isShortCut;
// 是否为截图服务
function isShortCut() {
  return (/shortcut=true/.test(location.search)
  );
}

/***/ }),

/***/ 3832:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.Base64Task = undefined;

var _regenerator = __webpack_require__(12);

var _regenerator2 = _interopRequireDefault(_regenerator);

var _asyncToGenerator2 = __webpack_require__(99);

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _common = __webpack_require__(19);

var _generateHeadersHelper = __webpack_require__(347);

var _browserHelper = __webpack_require__(27);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

var _util = __webpack_require__(1653);

var _suiteHelper = __webpack_require__(52);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Base64Task = exports.Base64Task = function () {
    function Base64Task(src) {
        (0, _classCallCheck3.default)(this, Base64Task);

        this.src = src;
        this.aborted = false;
    }

    (0, _createClass3.default)(Base64Task, [{
        key: 'start',
        value: function start() {
            this._start();
            return this;
        }
    }, {
        key: 'success',
        value: function success(fn) {
            this.successHandler = fn;
            return this;
        }
    }, {
        key: 'fail',
        value: function fail(fn) {
            this.errorHandler = fn;
            return this;
        }
    }, {
        key: 'abort',
        value: function abort() {
            this.aborted = true;
            this.xhr && this.xhr.abort();
        }
    }, {
        key: 'progress',
        value: function progress(fn) {
            this.progressHandler = fn;
            return this;
        }
    }, {
        key: '_start',
        value: function () {
            var _ref = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee() {
                var src, file, url, data;
                return _regenerator2.default.wrap(function _callee$(_context) {
                    while (1) {
                        switch (_context.prev = _context.next) {
                            case 0:
                                _context.prev = 0;
                                src = this.src;
                                _context.next = 4;
                                return base64SrcToFile(src);

                            case 4:
                                file = _context.sent;

                                if (!this.aborted) {
                                    _context.next = 7;
                                    break;
                                }

                                return _context.abrupt('return');

                            case 7:
                                if (file) {
                                    _context.next = 9;
                                    break;
                                }

                                throw new Error('fail to convert base64 to file');

                            case 9:
                                url = '/api/file/upload/';
                                _context.next = 12;
                                return this.uploadImage(url, file, this.progressHandler.bind(this));

                            case 12:
                                data = _context.sent;

                                if (!this.aborted) {
                                    _context.next = 15;
                                    break;
                                }

                                return _context.abrupt('return');

                            case 15:
                                this.successHandler(data);
                                _context.next = 23;
                                break;

                            case 18:
                                _context.prev = 18;
                                _context.t0 = _context['catch'](0);

                                if (!this.aborted) {
                                    _context.next = 22;
                                    break;
                                }

                                return _context.abrupt('return');

                            case 22:
                                this.errorHandler(_context.t0);

                            case 23:
                            case 'end':
                                return _context.stop();
                        }
                    }
                }, _callee, this, [[0, 18]]);
            }));

            function _start() {
                return _ref.apply(this, arguments);
            }

            return _start;
        }()
    }, {
        key: 'uploadImage',
        value: function uploadImage(url, file, progressHandler) {
            var _this = this;

            return new Promise(function (resolve, reject) {
                var fd = new FormData();
                var token = (0, _suiteHelper.getToken)();
                fd.append('token', token);
                fd.append('obj_type', _common.NUM_SUITE_TYPE.DOC.toString(10));
                fd.append('type', file.type);
                fd.append('lastModifiedDate', file.lastModifiedDate || '');
                fd.append('size', file.size.toString(10));
                fd.append('name', file.name);
                fd.append('file', file, isNotModernBrowser() ? file.name : undefined);
                var xhr = new XMLHttpRequest();
                xhr.open('POST', url, true);
                var headers = (0, _generateHeadersHelper.generateHeaders)();
                Object.keys(headers).forEach(function (key) {
                    return xhr.setRequestHeader(key, headers[key]);
                });
                xhr.send(fd);
                xhr.onreadystatechange = function () {
                    if (xhr.readyState !== 4) {
                        return;
                    }
                    if (xhr.status !== 200) {
                        reject(new Error('fail to upload'));
                        return;
                    }
                    var resp = JSON.parse(xhr.responseText);
                    if (resp.code !== 0) {
                        (0, _util.handleTeaLog)('fail', file.size, file.name);
                        reject(new Error(resp.msg));
                        return;
                    }
                    (0, _util.handleTeaLog)('success', file.size, file.name);
                    resolve(resp.data);
                };
                xhr.onerror = function () {
                    (0, _util.handleTeaLog)('fail', file.size, file.name);
                    reject(new Error('fail to upload'));
                };
                xhr.onprogress = function (event) {
                    var progress = event.loaded / (event.total || file.size);
                    progressHandler(progress);
                };
                _this.xhr = xhr;
            });
        }
    }]);
    return Base64Task;
}();

function base64SrcToFile(src) {
    if (src.indexOf('data:') !== 0) {
        return;
    }
    try {
        var reg = /^data:image\/([a-z-+.]+);base64,([\S]+)/;
        var result = reg.exec(src);
        if (result === null) {
            return;
        }
        // Edge只能手动转换
        var fileType = result[1];
        if (isNotModernBrowser()) {
            var blob = b64toBlob(result[2], result[1]);
            // edge无法new出File，只能用Blob替代
            blob.name = 'image.' + result[1];
            return blob;
        }
        return fetch(src).then(function (res) {
            return res.blob();
        }).then(function (blob) {
            return new File([blob], 'file-' + Date.now() + '.' + fileType, { type: 'image/' + fileType });
        }).catch(function (e) {
            console.log(e);
        });
    } catch (e) {
        console.error(e);
    }
    return;
}
function b64toBlob(b64Data, contentType, sliceSize) {
    contentType = contentType || '';
    sliceSize = sliceSize || 512;
    var byteCharacters = atob(b64Data);
    var byteArrays = [];
    for (var offset = 0; offset < byteCharacters.length; offset += sliceSize) {
        var slice = byteCharacters.slice(offset, offset + sliceSize);
        var byteNumbers = new Array(slice.length);
        for (var i = 0; i < slice.length; i++) {
            byteNumbers[i] = slice.charCodeAt(i);
        }
        var byteArray = new Uint8Array(byteNumbers);
        byteArrays.push(byteArray);
    }
    var blob = new Blob(byteArrays, { type: contentType });
    return blob;
}
function isNotModernBrowser() {
    return _browserHelper2.default.isEdge || _browserHelper2.default.isIE;
}

/***/ })

}]);
//# sourceMappingURL=https://s3.pstatp.com/eesz/resource/bear/js/image-upload.97a969fe4904a461a67a.js.map