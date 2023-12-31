(window["webpackJsonp"] = window["webpackJsonp"] || []).push([[9],{

/***/ 1563:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _container = __webpack_require__(3005);

var _container2 = _interopRequireDefault(_container);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = _container2.default;

/***/ }),

/***/ 1594:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.isImageUploadPlugin = isImageUploadPlugin;
exports.isListLine = isListLine;
exports.createQueryString = createQueryString;
exports.toUndefined = toUndefined;
exports.isSupportCoder = isSupportCoder;
exports.computeImgScalingDiff = computeImgScalingDiff;
exports.computeWhRatio = computeWhRatio;
exports.computeImgScalingFinalSize = computeImgScalingFinalSize;
exports.handleTeaLog = handleTeaLog;
exports.toFixedNumber = toFixedNumber;
exports.isGalleryInSelection = isGalleryInSelection;
exports.isGalleryInRange = isGalleryInRange;
exports.isImageLine = isImageLine;

var _const = __webpack_require__(1604);

var _find2 = __webpack_require__(376);

var _find3 = _interopRequireDefault(_find2);

var _math = __webpack_require__(1748);

var _tea = __webpack_require__(47);

var _tea2 = _interopRequireDefault(_tea);

var _dom = __webpack_require__(1609);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * Created by jinlei.chen on 2017/8/2.
 */
function isImageUploadPlugin(value) {
    return new RegExp('pluginName=' + _const.pluginName).test(value);
}
function isListLine(zoneId, lineNum, editorInfo) {
    var lineAttrs = editorInfo.ace_getAllAttributesOnLine(zoneId, lineNum);
    var isList = (0, _find3.default)(lineAttrs, function (item) {
        return item[0] === 'list';
    });
    return !!isList;
}
function createQueryString(obj) {
    var res = '';
    for (var key in obj) {
        res += key + '=' + obj[key] + '&';
    }
    return res.slice(0, res.length - 1);
}
function toUndefined(str) {
    return str === undefined || str === 'undefined' || str === 'null' ? undefined : str;
}
function isSupportCoder() {
    var win = window;
    return typeof win.TextEncoder === 'function' && typeof win.TextDecoder === 'function';
}
/**
 * 计算图像缩放前后的高度差
 *
 * @param {string}  pointID  拖的是哪个点
 * @param {number}  moveX    鼠标水平移动距离，向右移动为正
 * @param {number}  moveY    鼠标垂直移动距离，向下移动为正
 */
function computeImgScalingDiff(pointID, moveX, moveY) {
    // IE 下的 String 没有实现 Symbol.iterator
    var yID = pointID[0];
    var xID = pointID[1];
    // 如果拖的是上面的点，则向下拖动表示缩小，缩小距离取 moveY 的负值
    var diffY = yID === 't' ? -moveY : moveY;
    // 如果拖的是左边的点，则向右拖动表示缩小，缩小距离取 moveX 的负值
    var diffX = xID === 'l' ? -moveX : moveX;
    // diffX、diffY 同时表示放大或缩小时，取绝对值最大的
    var diff = 0;
    if (diffX > 0 && diffY > 0) {
        diff = Math.max(diffX, diffY);
    } else if (diffX < 0 && diffY < 0) {
        diff = -Math.max(-diffX, -diffY);
    } else {
        // 否则，取和。这样缩放时不会卡顿
        diff = diffX + diffY;
    }
    return diff;
}
/**
 * 计算图片的宽高比
 */
function computeWhRatio(size) {
    return (0, _math.accDiv)(size.width, size.height);
}
/**
 * 计算图片拖拽缩放后的最终大小
 */
function computeImgScalingFinalSize(original, diffY, maxWidth) {
    var whRatio = computeWhRatio(original);
    var diffX = (0, _math.accMul)(diffY, whRatio);
    var newWidth = (0, _math.accAdd)(original.width, diffX);
    var newHeight = (0, _math.accAdd)(original.height, diffY);
    // 如果是缩小
    if (diffY < 0) {
        // 如果原来的图像就太小，则不允许再缩小
        if (original.width < _const.MIN_RECT || original.height < _const.MIN_RECT) {
            return original;
        }
        // 从大于 MIN_RECT -> 小于 MIN_RECT 时，高度设为 MIN_RECT
        if (newHeight < _const.MIN_RECT) {
            newHeight = _const.MIN_RECT;
            newWidth = (0, _math.accMul)(newHeight, whRatio);
        }
        // 从大于 MIN_RECT -> 小于 MIN_RECT 时，宽度设为 MIN_RECT
        if (newWidth < _const.MIN_RECT) {
            newWidth = _const.MIN_RECT;
            newHeight = (0, _math.accDiv)(newWidth, whRatio);
        }
    }
    // newWidth 取整
    newWidth = Math.round(newWidth);
    // 宽度一定不能大于最大宽度
    if (newWidth > maxWidth) {
        newWidth = Math.ceil(maxWidth);
        newHeight = (0, _math.accDiv)(newWidth, whRatio);
    }
    return {
        width: newWidth,
        height: Math.round(newHeight)
    };
}
function handleTeaLog(uploadStatus, fileSize, fileName) {
    var fileType = fileName.split('.').pop() || 'unknown';
    (0, _tea2.default)('mention_drag_upload', {
        upload_status: uploadStatus || 'fail',
        mention_file_length: fileSize,
        mention_file_type: fileType,
        file_id: (0, _tea.getEncryToken)(),
        file_type: (0, _tea.getFileType)()
    });
}
function toFixedNumber(num, precision) {
    return parseFloat(Number(num).toFixed(precision));
}
/**
 * 选区是否是Gallery图片（.closest('.gallery')）或老格式图片（.closest('.image-container-wrap'))
 * @param selection
 */
function isGalleryInSelection(selection) {
    if (!selection) {
        return false;
    }
    var anchorNode = selection.anchorNode;
    return anchorNode && ((0, _dom.parents)(anchorNode, 'image-container-wrap') || (0, _dom.parents)(anchorNode, 'gallery'));
}
/**
 * 选区是否是Gallery图片
 * @param range
 */
function isGalleryInRange(range) {
    if (!range) {
        return false;
    }
    var anchorNode = range.startContainer;
    return anchorNode && anchorNode.nodeType === Node.ELEMENT_NODE && anchorNode.closest('.image-container-wrap,.gallery');
}
/**
 * 这一行是图片
 * @param lineNum
 * @returns {boolean}
 */
function isImageLine(rep, lineNum) {
    if (lineNum < 0 || lineNum > rep.lines.length() - 1) {
        return false;
    }
    // table 内理论上可能包含任何class，因此判断linetype不应该使用html.indexOf(class)
    var imageAttrib = rep.attributeManager.findAttributeOnLine(lineNum, 'image-uploaded') || rep.attributeManager.findAttributeOnLine(lineNum, 'gallery');
    return imageAttrib !== '';
}

/***/ }),

/***/ 1599:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
/**
 * Created by jinlei.chen on 2017/10/20.
 */

// 按键
var KEYS = exports.KEYS = {
  RETURN: 13,
  LEFT: 37,
  UP: 38,
  RIGHT: 39,
  DOWN: 40,
  SPACE: 32,
  ESC: 27,
  BACKSPACE: 8,
  AT: 50,
  A: 65
};

var PERMISSIONS = exports.PERMISSIONS = {
  MODIFY_SHARE_REWRITE: 8, // 可分享，可编辑，可评论
  MODIFY: 4, // 可编辑
  COMMENT: 2, // 可评论
  READ: 1, // 只读
  NONE: 0 // 无权限
};

/***/ }),

/***/ 1604:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
var uploadPrefix = exports.uploadPrefix = 'image-upload';
var pluginName = exports.pluginName = 'imageUpload';
var MIN_RECT = exports.MIN_RECT = 20; // 最小的缩放尺寸
var containerPaddingTop = exports.containerPaddingTop = 10;
var POINTS = exports.POINTS = ['tl', 'tc', 'tr', 'cr', 'br', 'bc', 'bl', 'lc'];
var IMAGE_LOAD_TIMEOUT = exports.IMAGE_LOAD_TIMEOUT = 90 * 1000; // 90s加载图片超时
var IMAGE_MAX_SIZE = exports.IMAGE_MAX_SIZE = 1024 * 1024 * 20;
var MARK_DECODE_IMAGE = exports.MARK_DECODE_IMAGE = 'mark_decode_image';
var UPLOAD_URL = exports.UPLOAD_URL = '/api/file/upload/';

/***/ }),

/***/ 1609:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.addClass = addClass;
exports.removeClass = removeClass;
exports.queryDom = queryDom;
exports.hasClass = hasClass;
exports.hasClassPrefix = hasClassPrefix;
exports.createStylesheet = createStylesheet;
exports.removeNode = removeNode;
exports.parents = parents;
exports.queryParents = queryParents;
exports.pxToNum = pxToNum;
exports.isInViewport = isInViewport;
exports.getlineguid = getlineguid;
exports.prev = prev;
exports.next = next;
exports.isElementInViewport = isElementInViewport;
function addClass(elem) {
    for (var _len = arguments.length, cls = Array(_len > 1 ? _len - 1 : 0), _key = 1; _key < _len; _key++) {
        cls[_key - 1] = arguments[_key];
    }

    // ie 下 svg 只能通过 setAttribute
    if (!elem.classList) {
        if (!elem.getAttribute) return;
        var classes = elem.getAttribute('class') || '';
        var newClasses = classes.split(' ').filter(function (c) {
            return !cls.includes(c);
        }).concat(cls).join(' ');
        elem.setAttribute('class', newClasses);
    } else {
        // ie 不支持 add 多参数
        cls.forEach(function (c) {
            return elem.classList.add(c);
        });
    }
}
function removeClass(elem) {
    for (var _len2 = arguments.length, cls = Array(_len2 > 1 ? _len2 - 1 : 0), _key2 = 1; _key2 < _len2; _key2++) {
        cls[_key2 - 1] = arguments[_key2];
    }

    if (!elem.classList) {
        if (!elem.getAttribute) return;
        var classes = elem.getAttribute('class') || '';
        var newClasses = classes.split(' ').filter(function (c) {
            return !cls.includes(c);
        }).join(' ');
        elem.setAttribute('class', newClasses);
    } else {
        cls.forEach(function (c) {
            return elem.classList.remove(c);
        });
    }
}
function queryDom(selector) {
    var elem = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : document;

    return elem.querySelector(selector);
}
function hasClass(elem, cls) {
    if (!elem.classList) {
        if (!elem.getAttribute) return false;
        var classes = elem.getAttribute('class') || '';
        return classes.split(' ').some(function (c) {
            return c === cls;
        });
    } else {
        return elem.classList.contains(cls);
    }
}
function hasClassPrefix(elem, cls) {
    if (!elem.classList) {
        if (!elem.getAttribute) return false;
        var classes = elem.getAttribute('class') || '';
        return classes.split(' ').some(function (c) {
            return c.indexOf(cls) === 0;
        });
    } else {
        return Array.from(elem.classList).some(function (c) {
            return c.indexOf(cls) === 0;
        });
    }
}
function createStylesheet(str) {
    var style = document.createElement('style');
    style.type = 'text/css';
    style.appendChild(document.createTextNode(str));
    return style;
}
function removeNode(node) {
    if (!node) {
        return;
    }
    var parent = node.parentNode;
    parent && parent.removeChild(node);
}
function parents(node, cls) {
    while (node) {
        if (hasClass(node, cls)) {
            return true;
        }
        node = node.parentNode;
    }
    return false;
}
function queryParents(node, cls) {
    while (node) {
        if (hasClass(node, cls)) {
            return node;
        }
        node = node.parentNode;
    }
    return null;
}
function pxToNum(px) {
    if (!px) {
        return 0;
    }
    return parseInt(px, 10);
}
function isInViewport(node) {
    var rect = node.getBoundingClientRect();
    return rect.top >= 0 && rect.left >= 0 && rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) && rect.right <= (window.innerWidth || document.documentElement.clientWidth);
}
function getlineguid(classList) {
    for (var i = 0; i < classList.length; i++) {
        var cls = classList[i];
        if (/^lineguid-/.test(cls)) {
            return cls.split('lineguid-')[1];
        }
    }
}
function prev(elem) {
    return elem.previousElementSibling || elem.previousSibling;
}
function next(elem) {
    return elem.nextElementSibling || elem.nextSibling;
}
function isElementInViewport(el) {
    var rect = el.getBoundingClientRect();
    var windowHeight = window.innerHeight || document.documentElement.clientHeight;
    var windowWidth = window.innerWidth || document.documentElement.clientWidth;
    var vertInView = rect.top <= windowHeight && rect.top + rect.height >= 0;
    var horInView = rect.left <= windowWidth && rect.left + rect.width >= 0;
    return vertInView && horInView;
}

/***/ }),

/***/ 1619:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.MindNoteEvent = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _forEach2 = __webpack_require__(1627);

var _forEach3 = _interopRequireDefault(_forEach2);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * MindNote事件中心，事件中心的触发源有多个点，本地编辑操作、远端消息、组件通信等等
 */
var MindNoteEvent = exports.MindNoteEvent = undefined;
(function (MindNoteEvent) {
  /**
   * 文档加载完成（本地）
   */
  MindNoteEvent["LOADED"] = "LOADED";
  /**
   * 服务端收到的change事件（远端）
   */
  MindNoteEvent["CHANGE_SERVER"] = "CHANGE_SERVER";
  /**
   * 客户端产生的change事件（本地）
   */
  MindNoteEvent["CHANGE_CLIENT"] = "CHANGE_CLIENT";
  /**
   * 保存事件（本地）
   */
  MindNoteEvent["SAVING"] = "SAVING";
  /**
   * 保存成功事件（本地）
   */
  MindNoteEvent["SAVED"] = "SAVED";
  /**
   * 用户进入事件（远端）
   */
  MindNoteEvent["USER_ENTER"] = "USER_ENTER";
  /**
   * 用户离开事件（远端）
   */
  MindNoteEvent["USER_LEAVE"] = "USER_LEAVE";
  /**
   * 服务端收到的cursor事件（远端）
   */
  MindNoteEvent["CURSOR_SERVER"] = "CURSOR_SERVER";
  /**
   * 客户端产生的cursor事件（本地）
   */
  MindNoteEvent["CURSOR_CLIENT"] = "CURSOR_CLIENT";
  /**
   * 当用户的文档权限变更（远端）
   */
  MindNoteEvent["PERMISSION_CHANGE"] = "PERMISSION_CHANGE";
  /**
   * 当前房间发生了变化（远端）
   */
  MindNoteEvent["ROOM_CHANGE"] = "ROOM_CHANGE";
  /**
   * 当前用户的编辑权限变更（远端）
   */
  MindNoteEvent["EDITABLE_CHANGE"] = "EDITABLE_CHANGE";
  /**
   * 当前用户发生翻页钻取事件（本地）
   */
  MindNoteEvent["DRILL"] = "DRILL";
  /**
   * 打开演示模式（组件通信）
   */
  MindNoteEvent["OPEN_PRESENTATION"] = "OPEN_PRESENTATION";
  /**
   * 打开思维导图模式（组件通信）
   */
  MindNoteEvent["OPEN_MINDMAP"] = "OPEN_MINDMAP";
  /**
   * 错误
   */
  MindNoteEvent["ERROR"] = "ERROR";
  MindNoteEvent["MIND_MAP_EXPORT"] = "MIND_MAP_EXPORT";
})(MindNoteEvent || (exports.MindNoteEvent = MindNoteEvent = {}));
/**
 * 思维笔记事件源，这个事件源主要是用来IO层与视图层和交互层的互相通信
 */

var MindNoteContext = function () {
  function MindNoteContext() {
    (0, _classCallCheck3.default)(this, MindNoteContext);

    this.handlerMap = {};
  }

  (0, _createClass3.default)(MindNoteContext, [{
    key: "bind",
    value: function bind(type, handler) {
      var handlers = this.handlerMap[type];
      if (!handlers) {
        this.handlerMap[type] = [handler];
      } else {
        handlers.push(handler);
      }
    }
  }, {
    key: "unbind",
    value: function unbind(type, handler) {
      var handlers = this.handlerMap[type];
      if (handlers) {
        var index = handlers.findIndex(function (val) {
          return val === handler;
        });
        if (index !== -1) {
          handlers.splice(index, index + 1);
        }
      }
    }
  }, {
    key: "trigger",
    value: function trigger(type, e) {
      var handlers = this.handlerMap[type];
      if (handlers) {
        (0, _forEach3.default)(handlers, function (v) {
          v(e);
        });
      }
    }
  }], [{
    key: "getInstance",
    value: function getInstance() {
      if (!MindNoteContext.mindNoteContext) {
        MindNoteContext.mindNoteContext = new MindNoteContext();
      }
      return MindNoteContext.mindNoteContext;
    }
  }]);
  return MindNoteContext;
}();

exports.default = MindNoteContext;

/***/ }),

/***/ 1647:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.deleteMenu = exports.commentMenu = exports.pasteMenu = exports.copyMenu = exports.cutMenu = exports.selectAllMenu = exports.selectMenu = exports.DELETE_ID = exports.COMMENT_ID = exports.PASTE_ID = exports.COPY_ID = exports.CUT_ID = exports.SELECT_ALL_ID = exports.SELECT_ID = undefined;

var _uppercaseTitleHelper = __webpack_require__(1667);

// 菜单顺序：「选择、全选、剪切、复制、粘贴、评论」
var SELECT_ID = exports.SELECT_ID = 'SELECT';
var SELECT_ALL_ID = exports.SELECT_ALL_ID = 'SELECT_ALL';
var CUT_ID = exports.CUT_ID = 'CUT';
var COPY_ID = exports.COPY_ID = 'COPY';
var PASTE_ID = exports.PASTE_ID = 'PASTE';
var COMMENT_ID = exports.COMMENT_ID = 'COMMENT';
var DELETE_ID = exports.DELETE_ID = 'DELETE';
// menus
var selectMenu = exports.selectMenu = {
    id: SELECT_ID,
    text: (0, _uppercaseTitleHelper.uppercaseTitleHelper)(t('mobile.menu.select'))
};
var selectAllMenu = exports.selectAllMenu = {
    id: SELECT_ALL_ID,
    text: (0, _uppercaseTitleHelper.uppercaseTitleHelper)(t('mobile.menu.select_all'))
};
var cutMenu = exports.cutMenu = {
    id: CUT_ID,
    text: (0, _uppercaseTitleHelper.uppercaseTitleHelper)(t('mobile.menu.cut'))
};
var copyMenu = exports.copyMenu = {
    id: COPY_ID,
    text: (0, _uppercaseTitleHelper.uppercaseTitleHelper)(t('mobile.menu.copy'))
};
var pasteMenu = exports.pasteMenu = {
    id: PASTE_ID,
    text: (0, _uppercaseTitleHelper.uppercaseTitleHelper)(t('mobile.menu.paste'))
};
var commentMenu = exports.commentMenu = {
    id: COMMENT_ID,
    text: (0, _uppercaseTitleHelper.uppercaseTitleHelper)(t('mobile.menu.comment'))
};
var deleteMenu = exports.deleteMenu = {
    id: DELETE_ID,
    text: (0, _uppercaseTitleHelper.uppercaseTitleHelper)(t('mobile.menu.delete'))
};
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 1648:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
var selectNetworkState = exports.selectNetworkState = function selectNetworkState(state) {
  return state.appState.networkState;
};

/***/ }),

/***/ 1656:
/***/ (function(module, exports, __webpack_require__) {

/* WEBPACK VAR INJECTION */(function(process, global) {/*!
 * @overview es6-promise - a tiny implementation of Promises/A+.
 * @copyright Copyright (c) 2014 Yehuda Katz, Tom Dale, Stefan Penner and contributors (Conversion to ES6 API by Jake Archibald)
 * @license   Licensed under MIT license
 *            See https://raw.githubusercontent.com/stefanpenner/es6-promise/master/LICENSE
 * @version   v4.2.4+314e4831
 */

(function (global, factory) {
	 true ? module.exports = factory() :
	undefined;
}(this, (function () { 'use strict';

function objectOrFunction(x) {
  var type = typeof x;
  return x !== null && (type === 'object' || type === 'function');
}

function isFunction(x) {
  return typeof x === 'function';
}



var _isArray = void 0;
if (Array.isArray) {
  _isArray = Array.isArray;
} else {
  _isArray = function (x) {
    return Object.prototype.toString.call(x) === '[object Array]';
  };
}

var isArray = _isArray;

var len = 0;
var vertxNext = void 0;
var customSchedulerFn = void 0;

var asap = function asap(callback, arg) {
  queue[len] = callback;
  queue[len + 1] = arg;
  len += 2;
  if (len === 2) {
    // If len is 2, that means that we need to schedule an async flush.
    // If additional callbacks are queued before the queue is flushed, they
    // will be processed by this flush that we are scheduling.
    if (customSchedulerFn) {
      customSchedulerFn(flush);
    } else {
      scheduleFlush();
    }
  }
};

function setScheduler(scheduleFn) {
  customSchedulerFn = scheduleFn;
}

function setAsap(asapFn) {
  asap = asapFn;
}

var browserWindow = typeof window !== 'undefined' ? window : undefined;
var browserGlobal = browserWindow || {};
var BrowserMutationObserver = browserGlobal.MutationObserver || browserGlobal.WebKitMutationObserver;
var isNode = typeof self === 'undefined' && typeof process !== 'undefined' && {}.toString.call(process) === '[object process]';

// test for web worker but not in IE10
var isWorker = typeof Uint8ClampedArray !== 'undefined' && typeof importScripts !== 'undefined' && typeof MessageChannel !== 'undefined';

// node
function useNextTick() {
  // node version 0.10.x displays a deprecation warning when nextTick is used recursively
  // see https://github.com/cujojs/when/issues/410 for details
  return function () {
    return process.nextTick(flush);
  };
}

// vertx
function useVertxTimer() {
  if (typeof vertxNext !== 'undefined') {
    return function () {
      vertxNext(flush);
    };
  }

  return useSetTimeout();
}

function useMutationObserver() {
  var iterations = 0;
  var observer = new BrowserMutationObserver(flush);
  var node = document.createTextNode('');
  observer.observe(node, { characterData: true });

  return function () {
    node.data = iterations = ++iterations % 2;
  };
}

// web worker
function useMessageChannel() {
  var channel = new MessageChannel();
  channel.port1.onmessage = flush;
  return function () {
    return channel.port2.postMessage(0);
  };
}

function useSetTimeout() {
  // Store setTimeout reference so es6-promise will be unaffected by
  // other code modifying setTimeout (like sinon.useFakeTimers())
  var globalSetTimeout = setTimeout;
  return function () {
    return globalSetTimeout(flush, 1);
  };
}

var queue = new Array(1000);
function flush() {
  for (var i = 0; i < len; i += 2) {
    var callback = queue[i];
    var arg = queue[i + 1];

    callback(arg);

    queue[i] = undefined;
    queue[i + 1] = undefined;
  }

  len = 0;
}

function attemptVertx() {
  try {
    var vertx = Function('return this')().require('vertx');
    vertxNext = vertx.runOnLoop || vertx.runOnContext;
    return useVertxTimer();
  } catch (e) {
    return useSetTimeout();
  }
}

var scheduleFlush = void 0;
// Decide what async method to use to triggering processing of queued callbacks:
if (isNode) {
  scheduleFlush = useNextTick();
} else if (BrowserMutationObserver) {
  scheduleFlush = useMutationObserver();
} else if (isWorker) {
  scheduleFlush = useMessageChannel();
} else if (browserWindow === undefined && "function" === 'function') {
  scheduleFlush = attemptVertx();
} else {
  scheduleFlush = useSetTimeout();
}

function then(onFulfillment, onRejection) {
  var parent = this;

  var child = new this.constructor(noop);

  if (child[PROMISE_ID] === undefined) {
    makePromise(child);
  }

  var _state = parent._state;


  if (_state) {
    var callback = arguments[_state - 1];
    asap(function () {
      return invokeCallback(_state, child, callback, parent._result);
    });
  } else {
    subscribe(parent, child, onFulfillment, onRejection);
  }

  return child;
}

/**
  `Promise.resolve` returns a promise that will become resolved with the
  passed `value`. It is shorthand for the following:

  ```javascript
  let promise = new Promise(function(resolve, reject){
    resolve(1);
  });

  promise.then(function(value){
    // value === 1
  });
  ```

  Instead of writing the above, your code now simply becomes the following:

  ```javascript
  let promise = Promise.resolve(1);

  promise.then(function(value){
    // value === 1
  });
  ```

  @method resolve
  @static
  @param {Any} value value that the returned promise will be resolved with
  Useful for tooling.
  @return {Promise} a promise that will become fulfilled with the given
  `value`
*/
function resolve$1(object) {
  /*jshint validthis:true */
  var Constructor = this;

  if (object && typeof object === 'object' && object.constructor === Constructor) {
    return object;
  }

  var promise = new Constructor(noop);
  resolve(promise, object);
  return promise;
}

var PROMISE_ID = Math.random().toString(36).substring(2);

function noop() {}

var PENDING = void 0;
var FULFILLED = 1;
var REJECTED = 2;

var TRY_CATCH_ERROR = { error: null };

function selfFulfillment() {
  return new TypeError("You cannot resolve a promise with itself");
}

function cannotReturnOwn() {
  return new TypeError('A promises callback cannot return that same promise.');
}

function getThen(promise) {
  try {
    return promise.then;
  } catch (error) {
    TRY_CATCH_ERROR.error = error;
    return TRY_CATCH_ERROR;
  }
}

function tryThen(then$$1, value, fulfillmentHandler, rejectionHandler) {
  try {
    then$$1.call(value, fulfillmentHandler, rejectionHandler);
  } catch (e) {
    return e;
  }
}

function handleForeignThenable(promise, thenable, then$$1) {
  asap(function (promise) {
    var sealed = false;
    var error = tryThen(then$$1, thenable, function (value) {
      if (sealed) {
        return;
      }
      sealed = true;
      if (thenable !== value) {
        resolve(promise, value);
      } else {
        fulfill(promise, value);
      }
    }, function (reason) {
      if (sealed) {
        return;
      }
      sealed = true;

      reject(promise, reason);
    }, 'Settle: ' + (promise._label || ' unknown promise'));

    if (!sealed && error) {
      sealed = true;
      reject(promise, error);
    }
  }, promise);
}

function handleOwnThenable(promise, thenable) {
  if (thenable._state === FULFILLED) {
    fulfill(promise, thenable._result);
  } else if (thenable._state === REJECTED) {
    reject(promise, thenable._result);
  } else {
    subscribe(thenable, undefined, function (value) {
      return resolve(promise, value);
    }, function (reason) {
      return reject(promise, reason);
    });
  }
}

function handleMaybeThenable(promise, maybeThenable, then$$1) {
  if (maybeThenable.constructor === promise.constructor && then$$1 === then && maybeThenable.constructor.resolve === resolve$1) {
    handleOwnThenable(promise, maybeThenable);
  } else {
    if (then$$1 === TRY_CATCH_ERROR) {
      reject(promise, TRY_CATCH_ERROR.error);
      TRY_CATCH_ERROR.error = null;
    } else if (then$$1 === undefined) {
      fulfill(promise, maybeThenable);
    } else if (isFunction(then$$1)) {
      handleForeignThenable(promise, maybeThenable, then$$1);
    } else {
      fulfill(promise, maybeThenable);
    }
  }
}

function resolve(promise, value) {
  if (promise === value) {
    reject(promise, selfFulfillment());
  } else if (objectOrFunction(value)) {
    handleMaybeThenable(promise, value, getThen(value));
  } else {
    fulfill(promise, value);
  }
}

function publishRejection(promise) {
  if (promise._onerror) {
    promise._onerror(promise._result);
  }

  publish(promise);
}

function fulfill(promise, value) {
  if (promise._state !== PENDING) {
    return;
  }

  promise._result = value;
  promise._state = FULFILLED;

  if (promise._subscribers.length !== 0) {
    asap(publish, promise);
  }
}

function reject(promise, reason) {
  if (promise._state !== PENDING) {
    return;
  }
  promise._state = REJECTED;
  promise._result = reason;

  asap(publishRejection, promise);
}

function subscribe(parent, child, onFulfillment, onRejection) {
  var _subscribers = parent._subscribers;
  var length = _subscribers.length;


  parent._onerror = null;

  _subscribers[length] = child;
  _subscribers[length + FULFILLED] = onFulfillment;
  _subscribers[length + REJECTED] = onRejection;

  if (length === 0 && parent._state) {
    asap(publish, parent);
  }
}

function publish(promise) {
  var subscribers = promise._subscribers;
  var settled = promise._state;

  if (subscribers.length === 0) {
    return;
  }

  var child = void 0,
      callback = void 0,
      detail = promise._result;

  for (var i = 0; i < subscribers.length; i += 3) {
    child = subscribers[i];
    callback = subscribers[i + settled];

    if (child) {
      invokeCallback(settled, child, callback, detail);
    } else {
      callback(detail);
    }
  }

  promise._subscribers.length = 0;
}

function tryCatch(callback, detail) {
  try {
    return callback(detail);
  } catch (e) {
    TRY_CATCH_ERROR.error = e;
    return TRY_CATCH_ERROR;
  }
}

function invokeCallback(settled, promise, callback, detail) {
  var hasCallback = isFunction(callback),
      value = void 0,
      error = void 0,
      succeeded = void 0,
      failed = void 0;

  if (hasCallback) {
    value = tryCatch(callback, detail);

    if (value === TRY_CATCH_ERROR) {
      failed = true;
      error = value.error;
      value.error = null;
    } else {
      succeeded = true;
    }

    if (promise === value) {
      reject(promise, cannotReturnOwn());
      return;
    }
  } else {
    value = detail;
    succeeded = true;
  }

  if (promise._state !== PENDING) {
    // noop
  } else if (hasCallback && succeeded) {
    resolve(promise, value);
  } else if (failed) {
    reject(promise, error);
  } else if (settled === FULFILLED) {
    fulfill(promise, value);
  } else if (settled === REJECTED) {
    reject(promise, value);
  }
}

function initializePromise(promise, resolver) {
  try {
    resolver(function resolvePromise(value) {
      resolve(promise, value);
    }, function rejectPromise(reason) {
      reject(promise, reason);
    });
  } catch (e) {
    reject(promise, e);
  }
}

var id = 0;
function nextId() {
  return id++;
}

function makePromise(promise) {
  promise[PROMISE_ID] = id++;
  promise._state = undefined;
  promise._result = undefined;
  promise._subscribers = [];
}

function validationError() {
  return new Error('Array Methods must be provided an Array');
}

var Enumerator = function () {
  function Enumerator(Constructor, input) {
    this._instanceConstructor = Constructor;
    this.promise = new Constructor(noop);

    if (!this.promise[PROMISE_ID]) {
      makePromise(this.promise);
    }

    if (isArray(input)) {
      this.length = input.length;
      this._remaining = input.length;

      this._result = new Array(this.length);

      if (this.length === 0) {
        fulfill(this.promise, this._result);
      } else {
        this.length = this.length || 0;
        this._enumerate(input);
        if (this._remaining === 0) {
          fulfill(this.promise, this._result);
        }
      }
    } else {
      reject(this.promise, validationError());
    }
  }

  Enumerator.prototype._enumerate = function _enumerate(input) {
    for (var i = 0; this._state === PENDING && i < input.length; i++) {
      this._eachEntry(input[i], i);
    }
  };

  Enumerator.prototype._eachEntry = function _eachEntry(entry, i) {
    var c = this._instanceConstructor;
    var resolve$$1 = c.resolve;


    if (resolve$$1 === resolve$1) {
      var _then = getThen(entry);

      if (_then === then && entry._state !== PENDING) {
        this._settledAt(entry._state, i, entry._result);
      } else if (typeof _then !== 'function') {
        this._remaining--;
        this._result[i] = entry;
      } else if (c === Promise$1) {
        var promise = new c(noop);
        handleMaybeThenable(promise, entry, _then);
        this._willSettleAt(promise, i);
      } else {
        this._willSettleAt(new c(function (resolve$$1) {
          return resolve$$1(entry);
        }), i);
      }
    } else {
      this._willSettleAt(resolve$$1(entry), i);
    }
  };

  Enumerator.prototype._settledAt = function _settledAt(state, i, value) {
    var promise = this.promise;


    if (promise._state === PENDING) {
      this._remaining--;

      if (state === REJECTED) {
        reject(promise, value);
      } else {
        this._result[i] = value;
      }
    }

    if (this._remaining === 0) {
      fulfill(promise, this._result);
    }
  };

  Enumerator.prototype._willSettleAt = function _willSettleAt(promise, i) {
    var enumerator = this;

    subscribe(promise, undefined, function (value) {
      return enumerator._settledAt(FULFILLED, i, value);
    }, function (reason) {
      return enumerator._settledAt(REJECTED, i, reason);
    });
  };

  return Enumerator;
}();

/**
  `Promise.all` accepts an array of promises, and returns a new promise which
  is fulfilled with an array of fulfillment values for the passed promises, or
  rejected with the reason of the first passed promise to be rejected. It casts all
  elements of the passed iterable to promises as it runs this algorithm.

  Example:

  ```javascript
  let promise1 = resolve(1);
  let promise2 = resolve(2);
  let promise3 = resolve(3);
  let promises = [ promise1, promise2, promise3 ];

  Promise.all(promises).then(function(array){
    // The array here would be [ 1, 2, 3 ];
  });
  ```

  If any of the `promises` given to `all` are rejected, the first promise
  that is rejected will be given as an argument to the returned promises's
  rejection handler. For example:

  Example:

  ```javascript
  let promise1 = resolve(1);
  let promise2 = reject(new Error("2"));
  let promise3 = reject(new Error("3"));
  let promises = [ promise1, promise2, promise3 ];

  Promise.all(promises).then(function(array){
    // Code here never runs because there are rejected promises!
  }, function(error) {
    // error.message === "2"
  });
  ```

  @method all
  @static
  @param {Array} entries array of promises
  @param {String} label optional string for labeling the promise.
  Useful for tooling.
  @return {Promise} promise that is fulfilled when all `promises` have been
  fulfilled, or rejected if any of them become rejected.
  @static
*/
function all(entries) {
  return new Enumerator(this, entries).promise;
}

/**
  `Promise.race` returns a new promise which is settled in the same way as the
  first passed promise to settle.

  Example:

  ```javascript
  let promise1 = new Promise(function(resolve, reject){
    setTimeout(function(){
      resolve('promise 1');
    }, 200);
  });

  let promise2 = new Promise(function(resolve, reject){
    setTimeout(function(){
      resolve('promise 2');
    }, 100);
  });

  Promise.race([promise1, promise2]).then(function(result){
    // result === 'promise 2' because it was resolved before promise1
    // was resolved.
  });
  ```

  `Promise.race` is deterministic in that only the state of the first
  settled promise matters. For example, even if other promises given to the
  `promises` array argument are resolved, but the first settled promise has
  become rejected before the other promises became fulfilled, the returned
  promise will become rejected:

  ```javascript
  let promise1 = new Promise(function(resolve, reject){
    setTimeout(function(){
      resolve('promise 1');
    }, 200);
  });

  let promise2 = new Promise(function(resolve, reject){
    setTimeout(function(){
      reject(new Error('promise 2'));
    }, 100);
  });

  Promise.race([promise1, promise2]).then(function(result){
    // Code here never runs
  }, function(reason){
    // reason.message === 'promise 2' because promise 2 became rejected before
    // promise 1 became fulfilled
  });
  ```

  An example real-world use case is implementing timeouts:

  ```javascript
  Promise.race([ajax('foo.json'), timeout(5000)])
  ```

  @method race
  @static
  @param {Array} promises array of promises to observe
  Useful for tooling.
  @return {Promise} a promise which settles in the same way as the first passed
  promise to settle.
*/
function race(entries) {
  /*jshint validthis:true */
  var Constructor = this;

  if (!isArray(entries)) {
    return new Constructor(function (_, reject) {
      return reject(new TypeError('You must pass an array to race.'));
    });
  } else {
    return new Constructor(function (resolve, reject) {
      var length = entries.length;
      for (var i = 0; i < length; i++) {
        Constructor.resolve(entries[i]).then(resolve, reject);
      }
    });
  }
}

/**
  `Promise.reject` returns a promise rejected with the passed `reason`.
  It is shorthand for the following:

  ```javascript
  let promise = new Promise(function(resolve, reject){
    reject(new Error('WHOOPS'));
  });

  promise.then(function(value){
    // Code here doesn't run because the promise is rejected!
  }, function(reason){
    // reason.message === 'WHOOPS'
  });
  ```

  Instead of writing the above, your code now simply becomes the following:

  ```javascript
  let promise = Promise.reject(new Error('WHOOPS'));

  promise.then(function(value){
    // Code here doesn't run because the promise is rejected!
  }, function(reason){
    // reason.message === 'WHOOPS'
  });
  ```

  @method reject
  @static
  @param {Any} reason value that the returned promise will be rejected with.
  Useful for tooling.
  @return {Promise} a promise rejected with the given `reason`.
*/
function reject$1(reason) {
  /*jshint validthis:true */
  var Constructor = this;
  var promise = new Constructor(noop);
  reject(promise, reason);
  return promise;
}

function needsResolver() {
  throw new TypeError('You must pass a resolver function as the first argument to the promise constructor');
}

function needsNew() {
  throw new TypeError("Failed to construct 'Promise': Please use the 'new' operator, this object constructor cannot be called as a function.");
}

/**
  Promise objects represent the eventual result of an asynchronous operation. The
  primary way of interacting with a promise is through its `then` method, which
  registers callbacks to receive either a promise's eventual value or the reason
  why the promise cannot be fulfilled.

  Terminology
  -----------

  - `promise` is an object or function with a `then` method whose behavior conforms to this specification.
  - `thenable` is an object or function that defines a `then` method.
  - `value` is any legal JavaScript value (including undefined, a thenable, or a promise).
  - `exception` is a value that is thrown using the throw statement.
  - `reason` is a value that indicates why a promise was rejected.
  - `settled` the final resting state of a promise, fulfilled or rejected.

  A promise can be in one of three states: pending, fulfilled, or rejected.

  Promises that are fulfilled have a fulfillment value and are in the fulfilled
  state.  Promises that are rejected have a rejection reason and are in the
  rejected state.  A fulfillment value is never a thenable.

  Promises can also be said to *resolve* a value.  If this value is also a
  promise, then the original promise's settled state will match the value's
  settled state.  So a promise that *resolves* a promise that rejects will
  itself reject, and a promise that *resolves* a promise that fulfills will
  itself fulfill.


  Basic Usage:
  ------------

  ```js
  let promise = new Promise(function(resolve, reject) {
    // on success
    resolve(value);

    // on failure
    reject(reason);
  });

  promise.then(function(value) {
    // on fulfillment
  }, function(reason) {
    // on rejection
  });
  ```

  Advanced Usage:
  ---------------

  Promises shine when abstracting away asynchronous interactions such as
  `XMLHttpRequest`s.

  ```js
  function getJSON(url) {
    return new Promise(function(resolve, reject){
      let xhr = new XMLHttpRequest();

      xhr.open('GET', url);
      xhr.onreadystatechange = handler;
      xhr.responseType = 'json';
      xhr.setRequestHeader('Accept', 'application/json');
      xhr.send();

      function handler() {
        if (this.readyState === this.DONE) {
          if (this.status === 200) {
            resolve(this.response);
          } else {
            reject(new Error('getJSON: `' + url + '` failed with status: [' + this.status + ']'));
          }
        }
      };
    });
  }

  getJSON('/posts.json').then(function(json) {
    // on fulfillment
  }, function(reason) {
    // on rejection
  });
  ```

  Unlike callbacks, promises are great composable primitives.

  ```js
  Promise.all([
    getJSON('/posts'),
    getJSON('/comments')
  ]).then(function(values){
    values[0] // => postsJSON
    values[1] // => commentsJSON

    return values;
  });
  ```

  @class Promise
  @param {Function} resolver
  Useful for tooling.
  @constructor
*/

var Promise$1 = function () {
  function Promise(resolver) {
    this[PROMISE_ID] = nextId();
    this._result = this._state = undefined;
    this._subscribers = [];

    if (noop !== resolver) {
      typeof resolver !== 'function' && needsResolver();
      this instanceof Promise ? initializePromise(this, resolver) : needsNew();
    }
  }

  /**
  The primary way of interacting with a promise is through its `then` method,
  which registers callbacks to receive either a promise's eventual value or the
  reason why the promise cannot be fulfilled.
   ```js
  findUser().then(function(user){
    // user is available
  }, function(reason){
    // user is unavailable, and you are given the reason why
  });
  ```
   Chaining
  --------
   The return value of `then` is itself a promise.  This second, 'downstream'
  promise is resolved with the return value of the first promise's fulfillment
  or rejection handler, or rejected if the handler throws an exception.
   ```js
  findUser().then(function (user) {
    return user.name;
  }, function (reason) {
    return 'default name';
  }).then(function (userName) {
    // If `findUser` fulfilled, `userName` will be the user's name, otherwise it
    // will be `'default name'`
  });
   findUser().then(function (user) {
    throw new Error('Found user, but still unhappy');
  }, function (reason) {
    throw new Error('`findUser` rejected and we're unhappy');
  }).then(function (value) {
    // never reached
  }, function (reason) {
    // if `findUser` fulfilled, `reason` will be 'Found user, but still unhappy'.
    // If `findUser` rejected, `reason` will be '`findUser` rejected and we're unhappy'.
  });
  ```
  If the downstream promise does not specify a rejection handler, rejection reasons will be propagated further downstream.
   ```js
  findUser().then(function (user) {
    throw new PedagogicalException('Upstream error');
  }).then(function (value) {
    // never reached
  }).then(function (value) {
    // never reached
  }, function (reason) {
    // The `PedgagocialException` is propagated all the way down to here
  });
  ```
   Assimilation
  ------------
   Sometimes the value you want to propagate to a downstream promise can only be
  retrieved asynchronously. This can be achieved by returning a promise in the
  fulfillment or rejection handler. The downstream promise will then be pending
  until the returned promise is settled. This is called *assimilation*.
   ```js
  findUser().then(function (user) {
    return findCommentsByAuthor(user);
  }).then(function (comments) {
    // The user's comments are now available
  });
  ```
   If the assimliated promise rejects, then the downstream promise will also reject.
   ```js
  findUser().then(function (user) {
    return findCommentsByAuthor(user);
  }).then(function (comments) {
    // If `findCommentsByAuthor` fulfills, we'll have the value here
  }, function (reason) {
    // If `findCommentsByAuthor` rejects, we'll have the reason here
  });
  ```
   Simple Example
  --------------
   Synchronous Example
   ```javascript
  let result;
   try {
    result = findResult();
    // success
  } catch(reason) {
    // failure
  }
  ```
   Errback Example
   ```js
  findResult(function(result, err){
    if (err) {
      // failure
    } else {
      // success
    }
  });
  ```
   Promise Example;
   ```javascript
  findResult().then(function(result){
    // success
  }, function(reason){
    // failure
  });
  ```
   Advanced Example
  --------------
   Synchronous Example
   ```javascript
  let author, books;
   try {
    author = findAuthor();
    books  = findBooksByAuthor(author);
    // success
  } catch(reason) {
    // failure
  }
  ```
   Errback Example
   ```js
   function foundBooks(books) {
   }
   function failure(reason) {
   }
   findAuthor(function(author, err){
    if (err) {
      failure(err);
      // failure
    } else {
      try {
        findBoooksByAuthor(author, function(books, err) {
          if (err) {
            failure(err);
          } else {
            try {
              foundBooks(books);
            } catch(reason) {
              failure(reason);
            }
          }
        });
      } catch(error) {
        failure(err);
      }
      // success
    }
  });
  ```
   Promise Example;
   ```javascript
  findAuthor().
    then(findBooksByAuthor).
    then(function(books){
      // found books
  }).catch(function(reason){
    // something went wrong
  });
  ```
   @method then
  @param {Function} onFulfilled
  @param {Function} onRejected
  Useful for tooling.
  @return {Promise}
  */

  /**
  `catch` is simply sugar for `then(undefined, onRejection)` which makes it the same
  as the catch block of a try/catch statement.
  ```js
  function findAuthor(){
  throw new Error('couldn't find that author');
  }
  // synchronous
  try {
  findAuthor();
  } catch(reason) {
  // something went wrong
  }
  // async with promises
  findAuthor().catch(function(reason){
  // something went wrong
  });
  ```
  @method catch
  @param {Function} onRejection
  Useful for tooling.
  @return {Promise}
  */


  Promise.prototype.catch = function _catch(onRejection) {
    return this.then(null, onRejection);
  };

  /**
    `finally` will be invoked regardless of the promise's fate just as native
    try/catch/finally behaves
  
    Synchronous example:
  
    ```js
    findAuthor() {
      if (Math.random() > 0.5) {
        throw new Error();
      }
      return new Author();
    }
  
    try {
      return findAuthor(); // succeed or fail
    } catch(error) {
      return findOtherAuther();
    } finally {
      // always runs
      // doesn't affect the return value
    }
    ```
  
    Asynchronous example:
  
    ```js
    findAuthor().catch(function(reason){
      return findOtherAuther();
    }).finally(function(){
      // author was either found, or not
    });
    ```
  
    @method finally
    @param {Function} callback
    @return {Promise}
  */


  Promise.prototype.finally = function _finally(callback) {
    var promise = this;
    var constructor = promise.constructor;

    return promise.then(function (value) {
      return constructor.resolve(callback()).then(function () {
        return value;
      });
    }, function (reason) {
      return constructor.resolve(callback()).then(function () {
        throw reason;
      });
    });
  };

  return Promise;
}();

Promise$1.prototype.then = then;
Promise$1.all = all;
Promise$1.race = race;
Promise$1.resolve = resolve$1;
Promise$1.reject = reject$1;
Promise$1._setScheduler = setScheduler;
Promise$1._setAsap = setAsap;
Promise$1._asap = asap;

/*global self*/
function polyfill() {
  var local = void 0;

  if (typeof global !== 'undefined') {
    local = global;
  } else if (typeof self !== 'undefined') {
    local = self;
  } else {
    try {
      local = Function('return this')();
    } catch (e) {
      throw new Error('polyfill failed because global object is unavailable in this environment');
    }
  }

  var P = local.Promise;

  if (P) {
    var promiseToString = null;
    try {
      promiseToString = Object.prototype.toString.call(P.resolve());
    } catch (e) {
      // silently ignored
    }

    if (promiseToString === '[object Promise]' && !P.cast) {
      return;
    }
  }

  local.Promise = Promise$1;
}

// Strange compat..
Promise$1.polyfill = polyfill;
Promise$1.Promise = Promise$1;

return Promise$1;

})));



//# sourceMappingURL=es6-promise.map

/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(277), __webpack_require__(84)))

/***/ }),

/***/ 1666:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _container = __webpack_require__(1757);

var _container2 = _interopRequireDefault(_container);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = _container2.default;

/***/ }),

/***/ 1667:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

/**
 * 处理首字母大写
 * 支持多词转换
 * eg: comment => Comment
 */
var uppercaseTitleHelper = exports.uppercaseTitleHelper = function uppercaseTitleHelper(s) {
  return s.toLowerCase().split(/\s+/).map(function (item, index) {
    return item.slice(0, 1).toUpperCase() + item.slice(1);
  }).join(' ');
};

/***/ }),

/***/ 1669:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.MENU_LOOKUP_TABLE = exports.TEMPLATE_ID = exports.TOUTIAOQUAN_TEMPLATE_TEXT = exports.ICONS = exports.MINDNOTE = exports.EDIT_SAVE = exports.SAVE = exports.EDIT_DISABLE = exports.EDIT = exports.COPY_URL = exports.SHARE_TO_TOU_TIAO_QUAN = exports.SHARE_TO_LARK = exports.MORE_OPERATE_DISABLE = exports.MORE_OPERATE = exports.SHARE_DISABLE = exports.SHARE = undefined;

var _defineProperty2 = __webpack_require__(11);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _reduce2 = __webpack_require__(160);

var _reduce3 = _interopRequireDefault(_reduce2);

var _MENU_LOOKUP_TABLE;

var _iconHelper = __webpack_require__(750);

var _base64Helper = __webpack_require__(740);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var SHARE = exports.SHARE = 'SHARE';
var SHARE_DISABLE = exports.SHARE_DISABLE = 'SHARE_DISABLE';
var MORE_OPERATE = exports.MORE_OPERATE = 'MORE_OPERATE'; // 更多 icon
var MORE_OPERATE_DISABLE = exports.MORE_OPERATE_DISABLE = 'MORE_OPERATE_DISABLE'; // 更多 icon 置灰

var SHARE_TO_LARK = exports.SHARE_TO_LARK = 'share_to_lark';
var SHARE_TO_TOU_TIAO_QUAN = exports.SHARE_TO_TOU_TIAO_QUAN = 'share_to_toutiao';

var COPY_URL = exports.COPY_URL = 'copy_link';

var EDIT = exports.EDIT = 'EDIT';
var EDIT_DISABLE = exports.EDIT_DISABLE = 'EDIT_DISABLE';
var SAVE = exports.SAVE = 'SAVE';
var EDIT_SAVE = exports.EDIT_SAVE = 'EDIT_SAVE';

var MINDNOTE = exports.MINDNOTE = 'MINDNOTE';

var ICONS = exports.ICONS = (0, _reduce3.default)([EDIT, SAVE, SHARE, MORE_OPERATE, MINDNOTE], function (memo, icon) {
  memo[icon] = (0, _iconHelper.getHeaderIcon)(icon);
  return memo;
}, {});

var TOUTIAOQUAN_TEMPLATE_TEXT = exports.TOUTIAOQUAN_TEMPLATE_TEXT = t('mobile.user_survey');
var TEMPLATE_ID = exports.TEMPLATE_ID = 'chunjie';

var getIcon = function getIcon(id, iconName) {
  var disabled = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : false;

  var status = disabled ? 'disable' : 'normal';
  return {
    id: id,
    disabled: disabled,
    imageBase64: (0, _base64Helper.transformBase64)(ICONS[iconName][status])
  };
};

var MENU_LOOKUP_TABLE = exports.MENU_LOOKUP_TABLE = (_MENU_LOOKUP_TABLE = {}, (0, _defineProperty3.default)(_MENU_LOOKUP_TABLE, SHARE, getIcon(SHARE, SHARE)), (0, _defineProperty3.default)(_MENU_LOOKUP_TABLE, SHARE_DISABLE, getIcon(SHARE, SHARE, true)), (0, _defineProperty3.default)(_MENU_LOOKUP_TABLE, MORE_OPERATE, getIcon(MORE_OPERATE, MORE_OPERATE)), (0, _defineProperty3.default)(_MENU_LOOKUP_TABLE, MORE_OPERATE_DISABLE, getIcon(MORE_OPERATE, MORE_OPERATE, true)), (0, _defineProperty3.default)(_MENU_LOOKUP_TABLE, MINDNOTE, getIcon(MINDNOTE, MINDNOTE)), (0, _defineProperty3.default)(_MENU_LOOKUP_TABLE, EDIT, getIcon(EDIT, EDIT)), (0, _defineProperty3.default)(_MENU_LOOKUP_TABLE, EDIT_SAVE, getIcon(EDIT, SAVE)), (0, _defineProperty3.default)(_MENU_LOOKUP_TABLE, EDIT_DISABLE, getIcon(EDIT, EDIT, true)), _MENU_LOOKUP_TABLE);
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 1670:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _MindNoteContext = __webpack_require__(1619);

var _MindNoteContext2 = _interopRequireDefault(_MindNoteContext);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = _MindNoteContext2.default;

/***/ }),

/***/ 1705:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.fixShareUrl = fixShareUrl;
exports.reload = reload;

var _browserHelper = __webpack_require__(34);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function fixShareUrl(url) {
    if (url) {
        return url.replace(/docsource:/, 'https:');
    }
    return url;
}
function reload() {
    if (_browserHelper2.default.isAndroid) {
        window.clear && window.clear();
        window.replace && window.replace(location.pathname + location.search + location.hash);
    } else {
        location.reload(true);
    }
}

/***/ }),

/***/ 1706:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = undefined;

var _regenerator = __webpack_require__(13);

var _regenerator2 = _interopRequireDefault(_regenerator);

var _asyncToGenerator2 = __webpack_require__(99);

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _isEqual2 = __webpack_require__(501);

var _isEqual3 = _interopRequireDefault(_isEqual2);

var _noop2 = __webpack_require__(383);

var _noop3 = _interopRequireDefault(_noop2);

var _class, _temp;
/* eslint-disable */


var _react = __webpack_require__(1);

var _constants = __webpack_require__(1669);

var _propTypes = __webpack_require__(0);

var _propTypes2 = _interopRequireDefault(_propTypes);

var _share = __webpack_require__(1766);

var _share2 = _interopRequireDefault(_share);

var _eventEmitter = __webpack_require__(272);

var _eventEmitter2 = _interopRequireDefault(_eventEmitter);

var _events = __webpack_require__(273);

var _events2 = _interopRequireDefault(_events);

var _offlineCreateHelper = __webpack_require__(379);

var _sdkCompatibleHelper = __webpack_require__(82);

var _tea = __webpack_require__(47);

var _urlHelper = __webpack_require__(184);

var _suiteHelper = __webpack_require__(60);

var _mindNoteContext = __webpack_require__(1670);

var _mindNoteContext2 = _interopRequireDefault(_mindNoteContext);

var _MindNoteContext = __webpack_require__(1619);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var PARTIAL_LOADING_STATUS_CHANGE = 'PARTIAL_LOADING_STATUS_CHANGE';

var AppHeader = (_temp = _class = function (_PureComponent) {
  (0, _inherits3.default)(AppHeader, _PureComponent);

  function AppHeader(props) {
    var _this2 = this;

    (0, _classCallCheck3.default)(this, AppHeader);

    var _this = (0, _possibleConstructorReturn3.default)(this, (AppHeader.__proto__ || Object.getPrototypeOf(AppHeader)).call(this, props));

    _this.handleWindowUnload = function () {
      _this.setMenu([], (0, _noop3.default)());
    };

    _this.getNodeToken = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee() {
      var _this$props, onLine, getTokenInfo, token, type, _ref2, items;

      return _regenerator2.default.wrap(function _callee$(_context) {
        while (1) {
          switch (_context.prev = _context.next) {
            case 0:
              console.log('isPreventGetTokenInfo');
              console.log(_sdkCompatibleHelper.isPreventGetTokenInfo);

              if (!(_sdkCompatibleHelper.isPreventGetTokenInfo || (0, _suiteHelper.isMindNote)())) {
                _context.next = 4;
                break;
              }

              return _context.abrupt('return');

            case 4:
              _this$props = _this.props, onLine = _this$props.onLine, getTokenInfo = _this$props.getTokenInfo;

              if (!(onLine && !_this.nodeToken)) {
                _context.next = 13;
                break;
              }

              token = (0, _suiteHelper.getToken)();
              type = (0, _suiteHelper.suiteType)() === 'doc' ? 2 : 3;
              _context.next = 10;
              return getTokenInfo(token, type);

            case 10:
              _ref2 = _context.sent;
              items = _ref2.payload.items;
              // doc 2 sheet 3
              _this.nodeToken = items.length ? items[0] : null;

            case 13:
              return _context.abrupt('return', _this.nodeToken);

            case 14:
            case 'end':
              return _context.stop();
          }
        }
      }, _callee, _this2);
    }));

    _this.handleMenuClick = function (data) {
      if (!data || !data.id) {
        return;
      }

      var editor = _this.props.editor;

      var clickedItem = _this.__items.find(function (item) {
        return item.id === data.id;
      });
      var itemDisabled = clickedItem.disabled;

      if (itemDisabled) {
        return;
      }
      // 派发clickMenu事件
      editor && editor.call('clickMenu');
      if (_sdkCompatibleHelper.isSupportClickToEdit) {
        // 触发 appEditControl.js 中 setReadMode 方法。
        _eventEmitter2.default.trigger(_events2.default.MOBILE.COMMON.END_EDIT, [{ reportEvent: data.id === _constants.SHARE ? 'click_share' : 'click_file_manage' }]);
      }

      switch (data.id) {
        case _constants.EDIT:
          _this.handleEditClick(data);
          break;
        case _constants.SHARE:
          _this.handleShareClick(data);
          break;
        case _constants.MORE_OPERATE:
          // todo 加统计
          _this.handleMoreOperateClick(data);
          break;
        default:
          break;
      }
    };

    _this.handleEditClick = function (data) {
      var editor = _this.props.editor;

      if (editor && editor.isEditing()) {
        _eventEmitter2.default.trigger(_events2.default.MOBILE.COMMON.END_EDIT);

        (0, _tea.collectSuiteEvent)('finish_edit', {
          template_id: _this.props.isTemplate ? _constants.TEMPLATE_ID : ''
        });
      } else {
        _eventEmitter2.default.trigger(_events2.default.MOBILE.COMMON.BEGIN_EDIT);

        (0, _tea.collectSuiteEvent)('start_edit', {
          template_id: _this.props.isTemplate ? _constants.TEMPLATE_ID : ''
        });
      }
      _this.setHeaderMenu();
    };

    _this.handleShareClick = function (data) {
      var _this$props2 = _this.props,
          currentNote = _this$props2.currentNote,
          isTemplate = _this$props2.isTemplate,
          editor = _this$props2.editor;

      var share = _share2.default.create({
        currentNote: currentNote,
        isTemplate: isTemplate,
        defaultTitle: t('common.unnamed_document')
      });
      return share.handleShareClick(editor);
    };

    _this.handleMoreOperateClick = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee2() {
      var nodeToken;
      return _regenerator2.default.wrap(function _callee2$(_context2) {
        while (1) {
          switch (_context2.prev = _context2.next) {
            case 0:
              if (_sdkCompatibleHelper.isSupportClickToEdit) {
                _context2.next = 2;
                break;
              }

              return _context2.abrupt('return', _this.handleShareClick());

            case 2:
              nodeToken = _this.nodeToken;

              if (nodeToken) {
                _context2.next = 7;
                break;
              }

              _context2.next = 6;
              return _this.getNodeToken();

            case 6:
              nodeToken = _context2.sent;

            case 7:
              window.lark.biz.util.more(nodeToken);

            case 8:
            case 'end':
              return _context2.stop();
          }
        }
      }, _callee2, _this2);
    }));

    _this.isEditable = function () {
      var _this$props3 = _this.props,
          onLine = _this$props3.onLine,
          hasWritePermission = _this$props3.hasWritePermission;

      return onLine && hasWritePermission || (0, _offlineCreateHelper.isOfflineCreateDoc)();
    };

    _this.setHeaderMenu = function (disable) {
      var _this$props4 = _this.props,
          onLine = _this$props4.onLine,
          messageShowing = _this$props4.messageShowing,
          editor = _this$props4.editor;

      var editIcon = _constants.EDIT;
      var shareIcon = _constants.SHARE;
      var moreOperateIcon = _constants.MORE_OPERATE;
      var mindNoteIcon = null;
      /**
       * 是否全量兼容单击进入编辑态
       * 1. 是： 图标为 分享 和 更多
       * 2. 否： 图片为 编辑 和 更多， 点击更多的操作为分享
       */
      if (_sdkCompatibleHelper.isSupportClickToEdit) {
        if (!onLine || (0, _offlineCreateHelper.isOfflineCreateDoc)()) {
          shareIcon = _constants.SHARE_DISABLE;
          moreOperateIcon = _constants.MORE_OPERATE_DISABLE;
        }
        editIcon = null;
      } else {
        if (editor && editor.isEditing()) {
          editIcon = _constants.EDIT_SAVE;
        }
        if (!_this.isEditable() || messageShowing) {
          editIcon = _constants.EDIT_DISABLE;
        }
        if (!onLine) {
          editIcon = _constants.EDIT_DISABLE;
          moreOperateIcon = _constants.MORE_OPERATE_DISABLE;
        }
        // sheet 中没有 editor， Lark1.16 之前 sheet 没有编辑按钮
        if (!editor) {
          editIcon = null;
        }
        shareIcon = null;
      }

      var hanlder = _this.handleMenuClick;
      if (disable) {
        shareIcon = _constants.SHARE_DISABLE;
        moreOperateIcon = _constants.MORE_OPERATE_DISABLE;
        hanlder = _noop3.default;
      }

      // 最佳实践内不显示右上角的按钮。
      if ((0, _urlHelper.parseQuery)(window.location.search).tt) {
        editIcon = null;
        shareIcon = null;
        moreOperateIcon = null;
        hanlder = _noop3.default;
      }
      // 思维笔记
      if ((0, _suiteHelper.isMindNote)()) {
        editIcon = null;
        shareIcon = _constants.SHARE;
        mindNoteIcon = _constants.MINDNOTE;
        hanlder = function hanlder(data) {
          if (data.id === _constants.MINDNOTE) {
            var mindNoteContext = _mindNoteContext2.default.getInstance();
            mindNoteContext.trigger(_MindNoteContext.MindNoteEvent.OPEN_MINDMAP);
            window.lark.biz.util.toggleTitlebar({
              states: 0
            });
            document.querySelector('html').classList.add('openMap');
          } else {
            _this.handleMenuClick(data);
          }
        };
      }
      var menu = [];
      [editIcon, mindNoteIcon, shareIcon, moreOperateIcon].forEach(function (item) {
        item && menu.push(_constants.MENU_LOOKUP_TABLE[item]);
      });

      _this.setMenu(menu, hanlder);
    };

    _this.setMenu = function (items, onClick) {
      if ((0, _isEqual3.default)(_this.__items, items)) {
        return;
      }

      _this.__items = items;

      window.lark.biz.navigation.setMenu({
        items: items,
        onSuccess: function onSuccess(data) {
          onClick(data);
        }
      });
    };

    _this.__items = [];
    _this.nodeToken = null;
    return _this;
  }

  (0, _createClass3.default)(AppHeader, [{
    key: 'componentDidMount',
    value: function componentDidMount() {
      window.addEventListener('unload', this.handleWindowUnload);
      this.getNodeToken();
      this.setHeaderMenu();
      _eventEmitter2.default.on(_events2.default.MOBILE.DOCS.CREATE_SUCCESS, this.setHeaderMenu);
      if (!_sdkCompatibleHelper.isSupportClickToEdit) {
        // 都是热更新惹的祸
        _eventEmitter2.default.on(_events2.default.MOBILE.COMMON.SET_MENU, this.setHeaderMenu);
      }
      // 分块 loading 按钮置灰
      this.props.editor && this.props.editor.on(PARTIAL_LOADING_STATUS_CHANGE, this.setHeaderMenu);
    }
  }, {
    key: 'componentDidUpdate',
    value: function componentDidUpdate() {
      this.getNodeToken();
      this.setHeaderMenu();
    }
  }, {
    key: 'componentWillUnmount',
    value: function componentWillUnmount() {
      this.setMenu([], (0, _noop3.default)());
      window.removeEventListener('unload', this.handleWindowUnload);
      if (!_sdkCompatibleHelper.isSupportClickToEdit) {
        _eventEmitter2.default.off(_events2.default.MOBILE.COMMON.SET_MENU, this.setHeaderMenu);
      }
      _eventEmitter2.default.off(_events2.default.MOBILE.DOCS.CREATE_SUCCESS, this.setHeaderMenu);
      this.props.editor && this.props.editor.off(PARTIAL_LOADING_STATUS_CHANGE, this.setHeaderMenu);
    }

    // 设置header图标

  }, {
    key: 'render',
    value: function render() {
      return null;
    }
  }]);
  return AppHeader;
}(_react.PureComponent), _class.propTypes = {
  currentNote: _propTypes2.default.object,
  isTemplate: _propTypes2.default.bool,
  onLine: _propTypes2.default.bool,
  editor: _propTypes2.default.object,
  getTokenInfo: _propTypes2.default.func,
  messageShowing: _propTypes2.default.bool,
  hasWritePermission: _propTypes2.default.bool
}, _temp);
exports.default = AppHeader;
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 1748:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.accAdd = accAdd;
exports.accSub = accSub;
exports.accMul = accMul;
exports.accDiv = accDiv;
/**
 * Created by jinlei.chen on 2017/10/24.
 */

/**
 ** 加法函数，用来得到精确的加法结果
 ** 说明：javascript的加法结果会有误差，在两个浮点数相加的时候会比较明显。这个函数返回较为精确的加法结果。
 ** 调用：accAdd(arg1,arg2)
 ** 返回值：arg1加上arg2的精确结果
 **/

/* eslint-disable */
function accAdd(arg1, arg2) {
  var r1 = void 0,
      r2 = void 0,
      m = void 0,
      c = void 0;
  try {
    r1 = arg1.toString().split('.')[1].length;
  } catch (e) {
    r1 = 0;
  }
  try {
    r2 = arg2.toString().split('.')[1].length;
  } catch (e) {
    r2 = 0;
  }
  c = Math.abs(r1 - r2);
  m = Math.pow(10, Math.max(r1, r2));
  if (c > 0) {
    var cm = Math.pow(10, c);
    if (r1 > r2) {
      arg1 = Number(arg1.toString().replace('.', ''));
      arg2 = Number(arg2.toString().replace('.', '')) * cm;
    } else {
      arg1 = Number(arg1.toString().replace('.', '')) * cm;
      arg2 = Number(arg2.toString().replace('.', ''));
    }
  } else {
    arg1 = Number(arg1.toString().replace('.', ''));
    arg2 = Number(arg2.toString().replace('.', ''));
  }
  return (arg1 + arg2) / m;
}

/**
 ** 减法函数，用来得到精确的减法结果
 ** 说明：javascript的减法结果会有误差，在两个浮点数相减的时候会比较明显。这个函数返回较为精确的减法结果。
 ** 调用：accSub(arg1,arg2)
 ** 返回值：arg1加上arg2的精确结果
 **/
function accSub(arg1, arg2) {
  var r1 = void 0,
      r2 = void 0,
      m = void 0,
      n = void 0;
  try {
    r1 = arg1.toString().split('.')[1].length;
  } catch (e) {
    r1 = 0;
  }
  try {
    r2 = arg2.toString().split('.')[1].length;
  } catch (e) {
    r2 = 0;
  }
  m = Math.pow(10, Math.max(r1, r2)); // 动态控制精度长度
  n = r1 >= r2 ? r1 : r2;
  return ((arg1 * m - arg2 * m) / m).toFixed(n);
}
/**
 ** 乘法函数，用来得到精确的乘法结果
 ** 说明：javascript的乘法结果会有误差，在两个浮点数相乘的时候会比较明显。这个函数返回较为精确的乘法结果。
 ** 调用：accMul(arg1,arg2)
 ** 返回值：arg1乘以 arg2的精确结果
 **/
function accMul(arg1, arg2) {
  var m = 0;
  var s1 = arg1.toString();
  var s2 = arg2.toString();
  try {
    m += s1.split('.')[1].length;
  } catch (e) {
    /* empty catch */
  }
  try {
    m += s2.split('.')[1].length;
  } catch (e) {
    /* empty catch */
  }
  return Number(s1.replace('.', '')) * Number(s2.replace('.', '')) / Math.pow(10, m);
}

/**
 ** 除法函数，用来得到精确的除法结果
 ** 说明：javascript的除法结果会有误差，在两个浮点数相除的时候会比较明显。这个函数返回较为精确的除法结果。
 ** 调用：accDiv(arg1,arg2)
 ** 返回值：arg1除以arg2的精确结果
 **/
function accDiv(arg1, arg2) {
  var t1 = 0;
  var t2 = 0;
  var r1 = void 0,
      r2 = void 0;
  try {
    t1 = arg1.toString().split('.')[1].length;
  } catch (e) {
    /* empty catch */
  }
  try {
    t2 = arg2.toString().split('.')[1].length;
  } catch (e) {
    /* empty catch */
  }
  r1 = Number(arg1.toString().replace('.', ''));
  r2 = Number(arg2.toString().replace('.', ''));
  return r1 / r2 * Math.pow(10, t2 - t1);
}

/***/ }),

/***/ 1757:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _user = __webpack_require__(56);

var _reactRedux = __webpack_require__(238);

var _Watermark = __webpack_require__(1758);

var _Watermark2 = _interopRequireDefault(_Watermark);

var _user2 = __webpack_require__(527);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var mapStateToProps = function mapStateToProps(state) {
    return {
        currentUser: (0, _user.selectCurrentUser)(state)
    };
};
var mapDispatchToProps = {
    fetchCurrentUser: _user2.fetchCurrentUser
};
exports.default = (0, _reactRedux.connect)(mapStateToProps, mapDispatchToProps)(_Watermark2.default);

/***/ }),

/***/ 1758:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _propTypes = __webpack_require__(0);

var _propTypes2 = _interopRequireDefault(_propTypes);

var _userHelper = __webpack_require__(61);

var _watermarkHelper = __webpack_require__(1759);

var _watermark = __webpack_require__(1760);

var _watermark2 = _interopRequireDefault(_watermark);

__webpack_require__(1761);

var _get2 = __webpack_require__(81);

var _get3 = _interopRequireDefault(_get2);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var currentMark = '';
/**
 * 可能会有多个地方使用评论组件，在水印信息不更新的情况下保证只有一次样式注入
 */
function renderWatermarkStyle(platform, currentUser) {
    /* 如果当前user不存在，或者不是头条租户，则不渲染 */
    if (!currentUser.get('id')) {
        return;
    }
    var user = {
        name: currentUser.get('name'),
        mobile: currentUser.get('mobile'),
        email: currentUser.get('email')
    };
    var mark = (0, _watermarkHelper.getMark)(user);
    if (mark === currentMark) return; // 水印信息没更新，不需要重复渲染
    currentMark = mark;
    if (platform === 'web') {
        (0, _watermark2.default)(mark, {
            selector: '.watermark-wrapper-' + platform,
            type: 'canvas'
        });
    } else if (platform === 'mobile') {
        var ratio = document.documentElement.offsetWidth / 375;
        var fontSize = 14 * ratio;
        var gap = 80 * ratio;
        (0, _watermark2.default)(mark, {
            selector: '.watermark-wrapper-' + platform,
            fontSize: fontSize,
            gap: gap,
            type: 'canvas'
        });
    }
}
/**
 * 给 Docs 文档打水印
 */

var Watermark = function (_React$Component) {
    (0, _inherits3.default)(Watermark, _React$Component);

    function Watermark(props) {
        (0, _classCallCheck3.default)(this, Watermark);

        var _this = (0, _possibleConstructorReturn3.default)(this, (Watermark.__proto__ || Object.getPrototypeOf(Watermark)).call(this, props));

        _this.isNeedRendWatermark = function () {
            // 头条用户和每日优鲜显示水印，其他租户不显示水印
            var tenantId = (0, _get3.default)(window, 'User.tenantId');
            return _this.state.isBytedanceUser || tenantId === '6636599569817796867' || tenantId === '2';
        };
        _this.state = {
            isBytedanceUser: (0, _userHelper.getIsBytedanceUser)()
        };
        return _this;
    }
    /**
     * 由于mobile端没有触发获取user信息的请isBytedanceUser求，如果组件初始化后view为null则触发action
     */


    (0, _createClass3.default)(Watermark, [{
        key: 'componentDidMount',
        value: function componentDidMount() {
            var _props = this.props,
                platform = _props.platform,
                currentUser = _props.currentUser,
                fetchCurrentUser = _props.fetchCurrentUser;
            /* 移动端没有user数据，需要拉取一次 */

            if (platform === 'mobile' && currentUser.size <= 0) {
                fetchCurrentUser();
            }
            if (this.isNeedRendWatermark()) {
                renderWatermarkStyle(platform, currentUser);
            }
        }
        /**
         * 若多次dispatch的user信息一样，则不进行重复操作
         *
         * @param {object} nextProps
         */

    }, {
        key: 'shouldComponentUpdate',
        value: function shouldComponentUpdate(nextProps) {
            if (!nextProps.currentUser) {
                return false;
            }
            if (this.props.currentUser && nextProps.currentUser.get('id') === this.props.currentUser.get('id')) {
                return false;
            }
            return true;
        }
    }, {
        key: 'componentDidUpdate',
        value: function componentDidUpdate() {
            if (this.isNeedRendWatermark()) {
                renderWatermarkStyle(this.props.platform, this.props.currentUser);
            }
        }
    }, {
        key: 'render',
        value: function render() {
            if (this.isNeedRendWatermark()) {
                return _react2.default.createElement("div", { className: 'watermark-wrapper-' + this.props.platform });
            }
            return null;
        }
    }]);
    return Watermark;
}(_react2.default.Component);

Watermark.propTypes = {
    /**
     * @type {Imutable} User info
     */
    currentUser: _propTypes2.default.object,
    /**
     * @type {string} web | mobile
     */
    platform: _propTypes2.default.string,
    fetchCurrentUser: _propTypes2.default.func
};
Watermark.defaultProps = {
    platform: 'web'
};
exports.default = Watermark;

/***/ }),

/***/ 1759:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
/**
 * 通过用户信息获取水印文字，如果mobile存在，则取mobile，否则取邮箱前缀。
 *
 * @param {object} user
 */
var getMark = exports.getMark = function getMark(user) {
    var mark = '';
    var name = user.name;
    var mobile = user.mobile;
    var email = user.email;
    var subMobile = '';
    var subEmail = '';
    if (mobile && mobile.length >= 4) {
        subMobile = mobile.substring(mobile.length - 4, mobile.length);
    }
    if (email) {
        var matchs = email.match(/.+(?=@)/);
        subEmail = matchs ? matchs[0] : '';
    }
    switch (true) {
        // 如果mobile存在，且总长度<25
        case subMobile && getActualLength(name + subMobile) < 25:
            mark = name + ' ' + subMobile;
            break;
        // 如果mobile存在，且总长度>=25
        case subMobile && getActualLength(name + subMobile) >= 25:
            mark = name.substring(0, 17) + '... ' + subMobile;
            break;
        // 如果name+email<25
        case getActualLength(name + subEmail) < 25:
            mark = name + ' ' + subEmail;
            break;
        // 如果name和email长度都>=25
        case getActualLength(name) > 25 && getActualLength(subEmail) > 25:
            mark = subEmail.substring(0, 22) + '...';
            break;
        // 如果name+email>=25，且name<=25,且email>25
        case getActualLength(name) <= 25 && getActualLength(subEmail) > 25:
            mark = name;
            break;
        default:
            mark = subEmail;
    }
    return mark;
};
/**
 * 获取真实的8位长度，这是由于浏览器在进行渲染的时候，8位的字符算作0.5个font，16位字符算作一个font。
 *
 * @param {string} str
 */
var getActualLength = exports.getActualLength = function getActualLength(str) {
    var length = 0;
    for (var index = 0; index < str.length; index++) {
        var e = str[index];
        if (e.codePointAt(0) >= 256) {
            length += 2;
        } else {
            length += 1;
        }
    }
    return length;
};

/***/ }),

/***/ 1761:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 1766:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = undefined;

var _defineProperty2 = __webpack_require__(11);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _find2 = __webpack_require__(376);

var _find3 = _interopRequireDefault(_find2);

var _class, _temp;

var _constants = __webpack_require__(1669);

var _tea = __webpack_require__(47);

var _getTemplateAbstract = __webpack_require__(1767);

var _getAllUrlParams = __webpack_require__(384);

var _offlineCreateHelper = __webpack_require__(379);

var _urlHelper = __webpack_require__(1705);

var _networkStateHelper = __webpack_require__(181);

var _networkHelper = __webpack_require__(121);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var fid = (0, _getAllUrlParams.getAllUrlParams)().fid || '';

var Share = (_temp = _class = function () {
  function Share() {
    var _this = this;

    (0, _classCallCheck3.default)(this, Share);

    this.setCurrentNote = function (currentNote) {
      _this.currentNote = currentNote;
    };

    this.setDefaultTitle = function (title) {
      _this.defaultTitle = title;
    };

    this.setIsTemplate = function (isTemplate) {
      _this.isTemplate = isTemplate;
    };

    this.getTitle = function () {
      var currentNote = _this.currentNote,
          defaultTitle = _this.defaultTitle;

      var title = currentNote && (currentNote.get('title') || currentNote.get('name'));

      return title || defaultTitle;
    };

    this.getDefaultText = function (editor) {
      var text = '';

      if (_this.isTemplate) {
        text = '' + (0, _getTemplateAbstract.getAbstract)(editor);
      }

      return text;
    };

    this.getTopic = function () {
      var text = '';

      if (_this.isTemplate) {
        text = _constants.TOUTIAOQUAN_TEMPLATE_TEXT;
      }

      return text;
    };

    this.handleShareClick = function (editor) {
      if (editor) {
        var docContainer = editor.getInnerContainer();
        docContainer && docContainer.blur();
      }

      if ((0, _offlineCreateHelper.isOfflineCreateDoc)() || !(0, _networkStateHelper.isOnLine)()) {
        return;
      }

      (0, _tea.collectSuiteEvent)('click_share_btn', {
        template_id: _this.isTemplate ? _constants.TEMPLATE_ID : ''
      });

      // 域名更换，租户域名私有化。如果在新域名下，优先使用后台返回的文档固有的url
      var url = _networkHelper.pathPrefix && _this.currentNote && _this.currentNote.get('url');
      if (!url) {
        url = (0, _urlHelper.fixShareUrl)(window.location.href);
      }
      window.lark.biz.util.share({
        title: _this.getTitle(),
        content: _this.getDefaultText(editor),
        topic: _this.getTopic(editor),
        url: url,
        feed_id: fid,
        onSuccess: _this.handleSharePopupClick
      });
    };

    this.handleSharePopupClick = function (data) {
      var _ID_TO_PLATFORM;

      var ID_TO_PLATFORM = (_ID_TO_PLATFORM = {}, (0, _defineProperty3.default)(_ID_TO_PLATFORM, _constants.SHARE_TO_LARK, 'lark'), (0, _defineProperty3.default)(_ID_TO_PLATFORM, _constants.SHARE_TO_TOU_TIAO_QUAN, 'toutiao_circle'), (0, _defineProperty3.default)(_ID_TO_PLATFORM, _constants.COPY_URL, 'copy'), _ID_TO_PLATFORM);
      (0, _find3.default)([_constants.SHARE_TO_LARK, _constants.SHARE_TO_TOU_TIAO_QUAN, _constants.COPY_URL], function (id) {
        if (id === data.id) {
          _this.collectShareEvent(ID_TO_PLATFORM[id]);
          return true;
        }
      });
    };

    this.collectShareEvent = function (toPlatform) {
      (0, _tea.collectSuiteEvent)('share', {
        to_platform: toPlatform,
        template_id: _this.isTemplate ? _constants.TEMPLATE_ID : ''
      });
    };
  }

  (0, _createClass3.default)(Share, null, [{
    key: 'create',
    value: function create(_ref) {
      var currentNote = _ref.currentNote,
          defaultTitle = _ref.defaultTitle,
          isTemplate = _ref.isTemplate;

      var share = new Share();
      share.setCurrentNote(currentNote);
      share.setDefaultTitle(defaultTitle);
      share.setIsTemplate(isTemplate);
      return share;
    }
  }]);
  return Share;
}(), _class.disable = function () {
  window.lark.biz.util.share({
    enable: false
  });
}, _class.enable = function () {
  window.lark.biz.util.share({
    enable: true
  });
}, _temp);
exports.default = Share;

/***/ }),

/***/ 1767:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getAbstract = getAbstract;
function getAbstract(ace) {
  var rep = ace.getRep();
  var textArray = rep.alltext.split('\n');
  var repLen = rep.lines.length();
  var firstTime = true;
  var context = '';

  for (var i = 0; i < repLen; i++) {
    // 找到摘要那一行
    var _context = '';
    if (ace.getAttributeOnLine(rep.zoneId, i, 'template') === 'abstract') {
      _context += '◇' + textArray[i] + '\n';
      var start = i;
      var end = i;
      for (var j = i + 1; j < repLen; j++) {
        var attrbiute = ace.getAttributeOnLine(rep.zoneId, j, 'template');
        if (attrbiute === 'block') {
          end = j;
          i = j;
          break;
        }
        if (attrbiute === 'abstract' && j - i !== 1) {
          end = j;
          i = j - 1;
          break;
        }
      }
      for (var range = start; range < end; range++) {
        if (ace.getAttributeOnLine(rep.zoneId, range, 'template') !== 'abstract' && textArray[range] !== ' ') {
          var list = ace.getAttributeOnLine(rep.zoneId, range, 'list');
          if (firstTime && list && list.indexOf('done') > -1) {
            _context += (firstTime ? '-' : '') + textArray[range] + (firstTime ? '\n' : '    ');
            _context = _context.replace('（请注明）', '').replace('(Please clarify here)', '');
          } else if (!list) {
            _context += (firstTime ? '-' : '') + textArray[range] + (firstTime ? '\n' : '    ');
          }
        }
      }
      if (_context.length > 1000) {
        _context = _context.substr(0, 995) + '...\n';
      } else {
        if (!firstTime) {
          _context += '\n';
        }
      }
      firstTime = false;
    }
    context += _context;
  }
  return context.replace(/\*/g, '');
};

/***/ }),

/***/ 1768:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _context_menu = __webpack_require__(1769);

var _context_menu2 = _interopRequireDefault(_context_menu);

var _custom_context_menu = __webpack_require__(1770);

var _custom_context_menu2 = _interopRequireDefault(_custom_context_menu);

var _sdkCompatibleHelper = __webpack_require__(82);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = _sdkCompatibleHelper.isSupportCustomMenu ? _custom_context_menu2.default : _context_menu2.default;

/***/ }),

/***/ 1769:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _noop2 = __webpack_require__(383);

var _noop3 = _interopRequireDefault(_noop2);

var _react = __webpack_require__(1);

var _uppercaseTitleHelper = __webpack_require__(1667);

var _networkStateHelper = __webpack_require__(181);

var _eventEmitter = __webpack_require__(272);

var _eventEmitter2 = _interopRequireDefault(_eventEmitter);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var COMMENT_ID = 'COMMENT';

var isPrevent = false;

var AppContextMenu = function (_Component) {
  (0, _inherits3.default)(AppContextMenu, _Component);

  function AppContextMenu() {
    var _ref;

    var _temp, _this, _ret;

    (0, _classCallCheck3.default)(this, AppContextMenu);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = (0, _possibleConstructorReturn3.default)(this, (_ref = AppContextMenu.__proto__ || Object.getPrototypeOf(AppContextMenu)).call.apply(_ref, [this].concat(args))), _this), _this.handleSelectionChange = function () {
      try {
        var selection = window.getSelection();
        // todo 有时间查证具体原因
        // ios下有奇怪的bug 插入mention(其他操作也可能)后selection正确
        // 当点击输入栏上的中文输入时 selection被magic更新为前一个状态的selection
        // 期间没有人调用addRange
        if (selection && selection.rangeCount > 0) {
          _this.oldRange = window.getSelection().getRangeAt(0);
        };
      } catch (e) {
        // 因此抛error时恢复为oldrange
        window.getSelection().removeAllRanges();
        window.getSelection().addRange(_this.oldRange);
      }
    }, _this.setContextMenu = function () {
      if (!(0, _networkStateHelper.isOnLine)()) {
        return;
      }

      if (isPrevent) {
        return;
      }

      window.lark.biz.navigation.setContextMenu({
        items: [{
          id: COMMENT_ID,
          text: (0, _uppercaseTitleHelper.uppercaseTitleHelper)(t('common.comment'))
        }],
        onSuccess: function onSuccess(data) {
          window.getSelection().removeAllRanges();
          window.getSelection().addRange(_this.oldRange);
          if (data && data.id) {
            _eventEmitter2.default.trigger('clickFromContextMenu', [{
              id: data.id,
              operationtype: 'popup'
            }]);
          }
        }
      });
    }, _this.clearContextMenu = function () {
      window.lark.biz.navigation.setContextMenu({
        items: [],
        onSuccess: _noop3.default
      });
    }, _temp), (0, _possibleConstructorReturn3.default)(_this, _ret);
  }

  (0, _createClass3.default)(AppContextMenu, [{
    key: 'componentDidMount',
    value: function componentDidMount(nextProps) {
      _eventEmitter2.default.on('setContextMenu', this.setContextMenu);
      _eventEmitter2.default.on('clearContextMenu', this.clearContextMenu);

      window.addEventListener('sheet_in_doc:sheetSelect', this.handleSheetSelectChange);

      document.addEventListener('selectionchange', this.handleSelectionChange);

      // 替移动端背锅
      this.clearContextMenu();
    }
  }, {
    key: 'componentWillUnmount',
    value: function componentWillUnmount() {
      _eventEmitter2.default.off('setContextMenu', this.setContextMenu);
      _eventEmitter2.default.off('clearContextMenu', this.clearContextMenu);

      window.removeEventListener('sheet_in_doc:sheetSelect', this.handleSheetSelectChange);

      document.removeEventListener('selectionchange', this.handleSelectionChange);

      this.clearContextMenu();
    }
  }, {
    key: 'handleSheetSelectChange',
    value: function handleSheetSelectChange(e) {
      var isSelect = e.detail.isSelect;


      isPrevent = isSelect;
    }
  }, {
    key: 'render',
    value: function render() {
      return null;
    }
  }]);
  return AppContextMenu;
}(_react.Component);

exports.default = AppContextMenu;
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 1770:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _defineProperty2 = __webpack_require__(11);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _debounce2 = __webpack_require__(67);

var _debounce3 = _interopRequireDefault(_debounce2);

var _noop3 = __webpack_require__(508);

var _noop4 = _interopRequireDefault(_noop3);

var _react = __webpack_require__(1);

var _eventEmitter = __webpack_require__(272);

var _eventEmitter2 = _interopRequireDefault(_eventEmitter);

var _events = __webpack_require__(273);

var _events2 = _interopRequireDefault(_events);

var _const = __webpack_require__(1599);

var _browserHelper = __webpack_require__(34);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

var _suiteHelper = __webpack_require__(60);

var _constants = __webpack_require__(1647);

var _utils = __webpack_require__(1771);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var AppContextMenu = function (_PureComponent) {
    (0, _inherits3.default)(AppContextMenu, _PureComponent);

    function AppContextMenu() {
        (0, _classCallCheck3.default)(this, AppContextMenu);

        var _this = (0, _possibleConstructorReturn3.default)(this, (AppContextMenu.__proto__ || Object.getPrototypeOf(AppContextMenu)).apply(this, arguments));

        _this.isEditing = function () {
            var editor = _this.props.editor;

            return editor && editor.isEditing();
        };
        _this.showCustomContextMenu = function (position) {
            window.lark.biz.navigation.showCustomContextMenu({ position: position });
        };
        _this.closeCustomContextMenu = function (position) {
            // android提供了closeCustomContextMenu接口
            window.lark.biz.navigation.closeCustomContextMenu();
        };
        _this._getCustomContextMenu = function () {
            var _this$props = _this.props,
                onLine = _this$props.onLine,
                commentable = _this$props.commentable;

            var options = {
                isEditing: _this.isEditing(),
                isOnline: onLine,
                commentable: commentable
            };
            var items = (0, _utils.getContextMenu)(options);
            console.info('customContextmenu items ' + JSON.stringify(items));
            return items;
        };
        // iOS 双击需要触发一次 selectionchange
        _this.setCustomContextMenu = (0, _debounce3.default)(function () {
            if ((0, _suiteHelper.isMindNote)()) {
                // 思维笔记
            } else if (_this.selectionNotValid()) {
                return;
            }
            var items = _this._getCustomContextMenu();
            window.lark.biz.navigation.setCustomContextMenu({
                items: items,
                onSuccess: _this.onContextMenuClick
            });
        }, 34);
        _this.requestCustomContextMenu = function () {
            // 如果是点击了 sheet， 不做任何处理
            // sheet 有相关逻辑
            if (_this.isPrevent) return;
            window.lark.biz.navigation.onContextMenuClick = _this.onContextMenuClick;
            var items = _this._getCustomContextMenu();
            return {
                items: items,
                onSuccess: 'window.lark.biz.navigation.onContextMenuClick'
            };
        };
        _this.onContextMenuClick = function (data) {
            if (!(data && data.id)) return;
            var id = data.id;
            _eventEmitter2.default.trigger('clickFromContextMenu', [{
                id: id,
                operationtype: 'popup'
            }]);
            if (id === _constants.DELETE_ID) {
                return _this.handleDeleteMenuClick();
            }
            _this.callNativeMenuClick(id);
        };
        _this.handleDeleteMenuClick = function () {
            // mock键盘删除，解决安卓无法选中图片进行删除的问题
            var event = new KeyboardEvent('keydown', {
                key: 'Backspace',
                keyCode: _const.KEYS.BACKSPACE
            });
            var innerdocbody = document.getElementById('innerdocbody');
            innerdocbody && innerdocbody.dispatchEvent(event);
        };
        _this.handleSelectAllClick = function () {
            document.execCommand('selectAll');
        };
        _this.callNativeMenuClick = function (id) {
            if (_browserHelper2.default.isAndroid && id === _constants.SELECT_ALL_ID) {
                _eventEmitter2.default.trigger(_events2.default.MOBILE.CONTEXT_MENU.onSelectAll);
                return _this.handleSelectAllClick();
            }
            _this.mapIdToNativeFunction(id);
        };
        _this.mapIdToNativeFunction = function (id) {
            var _fn;

            var fn = (_fn = {}, (0, _defineProperty3.default)(_fn, _constants.COPY_ID, 'Copy'), (0, _defineProperty3.default)(_fn, _constants.CUT_ID, 'Cut'), (0, _defineProperty3.default)(_fn, _constants.PASTE_ID, 'Paste'), (0, _defineProperty3.default)(_fn, _constants.SELECT_ID, 'Select'), (0, _defineProperty3.default)(_fn, _constants.SELECT_ALL_ID, 'SelectAll'), _fn);
            window.lark.biz.navigation['handle' + fn[id] + 'MenuClick']();
            if (id === _constants.COPY_ID) {
                setTimeout(function () {
                    window.lark.biz.selection.clearSelectionExcludeCursor();
                }, 50);
            }
        };
        return _this;
    }

    (0, _createClass3.default)(AppContextMenu, [{
        key: 'componentDidMount',
        value: function componentDidMount() {
            window.lark.biz.navigation.requestCustomContextMenu = this.requestCustomContextMenu;
            _eventEmitter2.default.on(_events2.default.MOBILE.CONTEXT_MENU.showDocContextMenu, this.showCustomContextMenu);
            _eventEmitter2.default.on(_events2.default.MOBILE.CONTEXT_MENU.closeContextMenu, this.closeCustomContextMenu);
            document.addEventListener('selectionchange', this.setCustomContextMenu);
            window.addEventListener('sheet_in_doc:sheetSelect', this.handleSheetSelectChange);
        }
    }, {
        key: 'componentWillUnmount',
        value: function componentWillUnmount() {
            window.lark.biz.navigation.requestCustomContextMenu = _noop4.default;
            window.lark.biz.navigation.onContextMenuClick = _noop4.default;
            _eventEmitter2.default.off(_events2.default.MOBILE.CONTEXT_MENU.showDocContextMenu, this.showCustomContextMenu);
            _eventEmitter2.default.off(_events2.default.MOBILE.CONTEXT_MENU.closeContextMenu, this.closeCustomContextMenu);
            document.removeEventListener('selectionchange', this.setCustomContextMenu);
            window.removeEventListener('sheet_in_doc:sheetSelect', this.handleSheetSelectChange);
        }
    }, {
        key: 'handleSheetSelectChange',
        value: function handleSheetSelectChange(e) {
            var isSelect = e.detail.isSelect;

            this.isPrevent = isSelect;
        }
    }, {
        key: 'selectionNotValid',
        value: function selectionNotValid() {
            var anchorNode = window.getSelection().anchorNode;
            if (!anchorNode) return false;
            var container = document.getElementById('innerdocbody');
            // docbody 外的也是不合法的
            if (!container || !container.contains(anchorNode)) {
                return true;
            }
            var ret = false;
            while (anchorNode && container !== anchorNode) {
                if (anchorNode.classList && anchorNode.classList.contains && anchorNode.classList.contains('sheet')) {
                    ret = true;
                    break;
                }
                anchorNode = anchorNode.parentNode;
            }
            return ret;
        }
    }, {
        key: 'render',
        value: function render() {
            return null;
        }
    }]);
    return AppContextMenu;
}(_react.PureComponent);

exports.default = AppContextMenu;

/***/ }),

/***/ 1771:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.getContextMenu = exports._isSelectAnRange = undefined;

var _unionBy2 = __webpack_require__(1772);

var _unionBy3 = _interopRequireDefault(_unionBy2);

var _browserHelper = __webpack_require__(34);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

var _envHelper = __webpack_require__(183);

var _constants = __webpack_require__(1647);

var _util = __webpack_require__(1594);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * @returns boolean 判断当前是否有选取
 */
var _isSelectAnRange = exports._isSelectAnRange = function _isSelectAnRange() {
    var selection = window.getSelection();
    // 选中图片type是Caret
    if ((0, _util.isGalleryInSelection)(selection)) return true;
    return !!(selection.rangeCount && selection.type === 'Range');
};
/**
 * 设置选择按钮
 * @param menus Menus
 * @param isSelectAnRange boolean
 */
var setSelectMenu = function setSelectMenu(menus, isSelectAnRange) {
    _browserHelper2.default.isIOS && (isSelectAnRange || menus.unshift(_constants.selectMenu));
};
/**
 * 设置剪切按钮
 * @param menus Menus
 * @param isSelectAnRange boolean
 * @param isEditing boolean
 */
var setCutMenu = function setCutMenu(menus, isSelectAnRange, isEditing) {
    isSelectAnRange && isEditing && menus.push(_constants.cutMenu);
};
/**
 * 设置复制按钮
 * @param menus Menus
 * @param isSelectAnRange boolean
 */
var setCopyMenu = function setCopyMenu(menus, isSelectAnRange) {
    isSelectAnRange && menus.push(_constants.copyMenu);
};
/**
 * 设置粘贴按钮
 * @param menus Menus
 * @param isEditing boolean
 */
var setPasteMenu = function setPasteMenu(menus, isEditing) {
    isEditing && menus.push(_constants.pasteMenu);
};
/**
 * 设置评论按钮
 * @param menus Menus
 * @param isSelectAnRange {boolean}
 * @param options GetContextMenuOptions
 */
var setCommentMenu = function setCommentMenu(menus, isSelectAnRange, options) {
    var isOnline = options.isOnline,
        commentable = options.commentable;

    isOnline && commentable && isSelectAnRange && !(0, _envHelper.isAnnouncement)() && menus.push(_constants.commentMenu);
};
/**
 * 自定义菜单: https://jira.bytedance.com/browse/DM-2130
 * 菜单顺序：「选择、全选、剪切、复制、粘贴、评论」
 */
var getContextMenu = exports.getContextMenu = function getContextMenu(options) {
    var isEditing = options.isEditing;

    var menus = [];
    var isGallery = (0, _util.isGalleryInSelection)(window.getSelection());
    var isSelectAnRange = isGallery || _isSelectAnRange();
    console.info('customContextmenu options ' + JSON.stringify(Object.assign({}, options, { isSelectAnRange: isSelectAnRange })));
    // iOS 阅读态， 在图片上 暂时禁掉全选
    // Android 继续留着
    if (!(_browserHelper2.default.isIOS && !isEditing && isGallery)) {
        menus.push(_constants.selectAllMenu);
    }
    if (!isGallery) {
        setCutMenu(menus, isSelectAnRange, isEditing);
        setSelectMenu(menus, isSelectAnRange);
        setCopyMenu(menus, isSelectAnRange);
        setPasteMenu(menus, isEditing);
    }
    setCommentMenu(menus, isSelectAnRange, options);
    return (0, _unionBy3.default)(menus, 'id');
};

/***/ }),

/***/ 1772:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _baseFlatten_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(1655);
/* harmony import */ var _baseIteratee_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(186);
/* harmony import */ var _baseRest_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(1602);
/* harmony import */ var _baseUniq_js__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(519);
/* harmony import */ var _isArrayLikeObject_js__WEBPACK_IMPORTED_MODULE_4__ = __webpack_require__(1629);
/* harmony import */ var _last_js__WEBPACK_IMPORTED_MODULE_5__ = __webpack_require__(518);







/**
 * This method is like `_.union` except that it accepts `iteratee` which is
 * invoked for each element of each `arrays` to generate the criterion by
 * which uniqueness is computed. Result values are chosen from the first
 * array in which the value occurs. The iteratee is invoked with one argument:
 * (value).
 *
 * @static
 * @memberOf _
 * @since 4.0.0
 * @category Array
 * @param {...Array} [arrays] The arrays to inspect.
 * @param {Function} [iteratee=_.identity] The iteratee invoked per element.
 * @returns {Array} Returns the new array of combined values.
 * @example
 *
 * _.unionBy([2.1], [1.2, 2.3], Math.floor);
 * // => [2.1, 1.2]
 *
 * // The `_.property` iteratee shorthand.
 * _.unionBy([{ 'x': 1 }], [{ 'x': 2 }, { 'x': 1 }], 'x');
 * // => [{ 'x': 1 }, { 'x': 2 }]
 */
var unionBy = Object(_baseRest_js__WEBPACK_IMPORTED_MODULE_2__[/* default */ "a"])(function(arrays) {
  var iteratee = Object(_last_js__WEBPACK_IMPORTED_MODULE_5__[/* default */ "a"])(arrays);
  if (Object(_isArrayLikeObject_js__WEBPACK_IMPORTED_MODULE_4__[/* default */ "a"])(iteratee)) {
    iteratee = undefined;
  }
  return Object(_baseUniq_js__WEBPACK_IMPORTED_MODULE_3__[/* default */ "a"])(Object(_baseFlatten_js__WEBPACK_IMPORTED_MODULE_0__[/* default */ "a"])(arrays, 1, _isArrayLikeObject_js__WEBPACK_IMPORTED_MODULE_4__[/* default */ "a"], true), Object(_baseIteratee_js__WEBPACK_IMPORTED_MODULE_1__[/* default */ "a"])(iteratee, 2));
});

/* harmony default export */ __webpack_exports__["default"] = (unionBy);


/***/ }),

/***/ 1773:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _toString_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(283);


/** Used to generate unique IDs. */
var idCounter = 0;

/**
 * Generates a unique ID. If `prefix` is given, the ID is appended to it.
 *
 * @static
 * @since 0.1.0
 * @memberOf _
 * @category Util
 * @param {string} [prefix=''] The value to prefix the ID with.
 * @returns {string} Returns the unique ID.
 * @example
 *
 * _.uniqueId('contact_');
 * // => 'contact_104'
 *
 * _.uniqueId();
 * // => '105'
 */
function uniqueId(prefix) {
  var id = ++idCounter;
  return Object(_toString_js__WEBPACK_IMPORTED_MODULE_0__[/* default */ "a"])(prefix) + id;
}

/* harmony default export */ __webpack_exports__["default"] = (uniqueId);


/***/ }),

/***/ 1812:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
/**
 * 客户端发出的错误码
 */
var ClientErrorCode = exports.ClientErrorCode = undefined;
(function (ClientErrorCode) {
  /**
   * 未知错误
   */
  ClientErrorCode["UNKNOWN"] = "F0001";
  /**
   * 请求超时
   */
  ClientErrorCode["REQUEST_TIMEOUT"] = "F2001";
  /**
   * 不合法的响应数据
   */
  ClientErrorCode["RESPONSE_INVALID"] = "F2002";
  /**
   * 响应数据不符合预期
   */
  ClientErrorCode["RESPONSE_UNEXPECTED"] = "F2003";
  /**
   * 不合法的 operation
   */
  ClientErrorCode["INVALID_OPERATION"] = "F3001";
  /**
   * 应用 action 失败
   */
  ClientErrorCode["APPLY_ACTION_FAILED"] = "F3002";
  /**
   * 本地文档版本与服务器最新版本差距超过阈值
   */
  ClientErrorCode["REVISION_MAX_GAP_EXCEED"] = "F3003";
  /**
   * 不合法的 model 数据
   */
  ClientErrorCode["MODEL_INVALID_DATA"] = "F4001";
})(ClientErrorCode || (exports.ClientErrorCode = ClientErrorCode = {}));
/**
 * 错误类型
 */
var ErrorType = exports.ErrorType = undefined;
(function (ErrorType) {
  /**
   * 未知错误
   */
  ErrorType["UNKNOWN"] = "UNKNOWN";
  /**
   * 请求出错
   */
  ErrorType["REQUEST_ERROR"] = "REQUEST_ERROR";
  /**
   * 响应出错
   */
  ErrorType["RESPONSE_ERROR"] = "RESPONSE_ERROR";
  /**
   * 协同错误
   */
  ErrorType["COLLABORATION_ERROR"] = "COLLABORATION_ERROR";
  /**
   * model 数据错误
   */
  ErrorType["MODEL_ERROR"] = "MODEL_ERROR";
  /**
   * 服务端返回的 Error
   */
  ErrorType["SERVER_ERROR"] = "SERVER_ERROR";
})(ErrorType || (exports.ErrorType = ErrorType = {}));

/***/ }),

/***/ 1813:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* WEBPACK VAR INJECTION */(function(t, clearImmediate, setImmediate) {/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "MindNoteEvent", function() { return MindNoteEvent; });
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "TipMessageType", function() { return TipMessageType; });
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "MindNoteEnvironment", function() { return MindNoteEnvironment; });
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "Actions", function() { return Actions; });
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "InputActionTypes", function() { return InputActionTypes; });
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "PureActions", function() { return PureActions; });
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "EditActions", function() { return EditActions; });
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "ExecuteType", function() { return ExecuteType; });
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "CursorType", function() { return CursorType; });
/* harmony import */ var jquery__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(1720);
/* harmony import */ var jquery__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(jquery__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var blueimp_md5__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(522);
/* harmony import */ var blueimp_md5__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(blueimp_md5__WEBPACK_IMPORTED_MODULE_1__);
/* harmony import */ var lodash_es__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(2083);
/* harmony import */ var lodash_es__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(182);
/* harmony import */ var lodash_es__WEBPACK_IMPORTED_MODULE_4__ = __webpack_require__(1725);
/* harmony import */ var lodash_es__WEBPACK_IMPORTED_MODULE_5__ = __webpack_require__(1627);
/* harmony import */ var lodash_es__WEBPACK_IMPORTED_MODULE_6__ = __webpack_require__(66);
/* harmony import */ var lodash_es__WEBPACK_IMPORTED_MODULE_7__ = __webpack_require__(39);
/* harmony import */ var lodash_es__WEBPACK_IMPORTED_MODULE_8__ = __webpack_require__(141);
/* harmony import */ var lodash_es__WEBPACK_IMPORTED_MODULE_9__ = __webpack_require__(287);
/* harmony import */ var lodash_es__WEBPACK_IMPORTED_MODULE_10__ = __webpack_require__(1682);
/* harmony import */ var _bdeefe_watermark__WEBPACK_IMPORTED_MODULE_11__ = __webpack_require__(1760);
/* harmony import */ var file_saver__WEBPACK_IMPORTED_MODULE_12__ = __webpack_require__(3015);
/* harmony import */ var file_saver__WEBPACK_IMPORTED_MODULE_12___default = /*#__PURE__*/__webpack_require__.n(file_saver__WEBPACK_IMPORTED_MODULE_12__);
/* harmony import */ var react_dom__WEBPACK_IMPORTED_MODULE_13__ = __webpack_require__(21);
/* harmony import */ var react_dom__WEBPACK_IMPORTED_MODULE_13___default = /*#__PURE__*/__webpack_require__.n(react_dom__WEBPACK_IMPORTED_MODULE_13__);
/* harmony import */ var react__WEBPACK_IMPORTED_MODULE_14__ = __webpack_require__(1);
/* harmony import */ var react__WEBPACK_IMPORTED_MODULE_14___default = /*#__PURE__*/__webpack_require__.n(react__WEBPACK_IMPORTED_MODULE_14__);
/* eslint-disable */








var MindNoteEvent;
(function (MindNoteEvent) {
    /**
     * 文档加载完成
     */
    MindNoteEvent["LOADED"] = "LOADED";
    /**
     * 用户编辑事件
     */
    MindNoteEvent["EDIT"] = "EDIT";
    /**
     * 文档发生改动事件
     */
    MindNoteEvent["CHANGE"] = "CHANGE";
    /**
     * 翻页钻取事件
     */
    MindNoteEvent["DRILL"] = "DRILL";
    /**
     * 当用户发生编辑添加图片行为
     * @description 这是一个零时的解决方案，不一定是长期的
     */
    MindNoteEvent["ADD_IMAGE"] = "ADD_IMAGE";
    /**
     * 若当前翻页的节点或其祖先节点被删除所触发的事件
     * @description 此时编辑器会回退到根节点
     */
    MindNoteEvent["DRILL_REMOVED"] = "DRILL_REMOVED";
    /**
     * 思维导图打开事件
     */
    MindNoteEvent["MIND_MAP_OPEN"] = "MIND_MAP_OPEN";
    /**
     * 思维导图关闭事件
     */
    MindNoteEvent["MIND_MAP_CLOSE"] = "MIND_MAP_CLOSE";
    /**
     * 思维导图导出事件，data参数格式：{name: string, base64Data: string}
     * @type {string}
     */
    MindNoteEvent["MIND_MAP_EXPORT"] = "MIND_MAP_EXPORT";
    /**
     * 演示模式打开事件
     */
    MindNoteEvent["PRESENTATION_OPEN"] = "PRESENTATION_OPEN";
    /**
     * 演示模式关闭事件
     */
    MindNoteEvent["PRESENTATION_CLOSE"] = "PRESENTATION_CLOSE";
    /**
     * 文档标题发生变化
     */
    MindNoteEvent["TITLE_CHANGE"] = "TITLE_CHANGE";
    /**
     * 需要弹出提醒信息事件
     * @type {string}
     */
    MindNoteEvent["TIP_MESSAGE"] = "TIP_MESSAGE";
    /**
     * 预览图片
     * @type {string}
     */
    MindNoteEvent["PREVIEW_IMAGE"] = "PREVIEW_IMAGE";
    /**
     * 节点的点击事件
     * @type {string}
     */
    MindNoteEvent["NODE_CLICK"] = "NODE_CLICK";
    /*
     * 输入框的focus事件
     * @type {string}
     */
    MindNoteEvent["INPUT_FOCUS"] = "INPUT_FOCUS";
})(MindNoteEvent || (MindNoteEvent = {}));
var TipMessageType;
(function (TipMessageType) {
    /**
     * 复制成功
     */
    TipMessageType["COPY_SUCCESS"] = "COPY_SUCCESS";
})(TipMessageType || (TipMessageType = {}));

var MindNoteEnvironment;
(function (MindNoteEnvironment) {
    MindNoteEnvironment["PC"] = "pc";
    MindNoteEnvironment["APP"] = "app";
})(MindNoteEnvironment || (MindNoteEnvironment = {}));

/**
 * Action 类型
 */
var Actions;
(function (Actions) {
    Actions["CREATE"] = "create";
    Actions["UPDATE"] = "update";
    Actions["DELETE"] = "delete";
    Actions["STRUCTURE_CHANGE"] = "structureChanged";
    Actions["SETTING_CHANGE"] = "settingChanged";
    Actions["TITLE_CHANGE"] = "nameChanged";
    Actions["INPUT"] = "INPUT";
})(Actions || (Actions = {}));
/**
 * input 类型
 */
var InputActionTypes;
(function (InputActionTypes) {
    InputActionTypes["NOTE"] = "note";
    InputActionTypes["TEXT"] = "text";
})(InputActionTypes || (InputActionTypes = {}));
/**
 * 对文档内容不会发生改变的操作
 */
var PureActions;
(function (PureActions) {
    PureActions["DRILL"] = "drill";
})(PureActions || (PureActions = {}));
var EditActions;
(function (EditActions) {
    EditActions["BLUR"] = "blur";
    EditActions["INDENT"] = "indent";
    EditActions["OUTDENT"] = "outdent";
    EditActions["NOTE"] = "note";
    EditActions["DELETE"] = "delete";
    EditActions["FINISH"] = "finish";
    EditActions["BOLD"] = "bold";
    EditActions["ITALIC"] = "italic";
    EditActions["UNDERLINE"] = "underline";
    EditActions["HEADING"] = "heading";
})(EditActions || (EditActions = {}));
/**
 * 执行 action 类型
 */
var ExecuteType;
(function (ExecuteType) {
    /**
     * 执行服务端发来的 action
     */
    ExecuteType["SERVER"] = "SERVER";
    /**
     * 执行 redo action
     */
    ExecuteType["REDO"] = "REDO";
    /**
     * 支持 undo action
     */
    ExecuteType["UNDO"] = "UNDO";
})(ExecuteType || (ExecuteType = {}));

/**
 * 光标类型
 */
var CursorType;
(function (CursorType) {
    CursorType["TEXT"] = "TEXT";
    CursorType["NOTE"] = "NOTE";
    CursorType["NODE"] = "NODE";
    CursorType["DRILL"] = "DRILL";
})(CursorType || (CursorType = {}));

var State = /** @class */ (function () {
    function State(props) {
        this.readonly = false;
        this.props = props;
    }
    State.prototype.getEditorProps = function () {
        return this.props;
    };
    return State;
}());

var lastGenerateIdTime = 0;
/**
 * 创建新的id，全局唯一
 */
function newId(id) {
    lastGenerateIdTime++;
    return blueimp_md5__WEBPACK_IMPORTED_MODULE_1___default()(lastGenerateIdTime + (id || '0') + Date.now() + Math.random());
}
/**
 * 递归调用
 * @param arr
 * @param func
 */
function recursive(arr, func) {
    if (!arr) {
        return;
    }
    /**
     * 递归的执行算法
     */
    var executeRecursive = function (item, parent, index, parentIndex, level, path) {
        if (jquery__WEBPACK_IMPORTED_MODULE_0___default.a.isArray(item)) {
            path = Object(lodash_es__WEBPACK_IMPORTED_MODULE_2__["default"])(path);
            path.push(index);
            for (var ai = 0; ai < item.length; ai++) {
                var childPath = Object(lodash_es__WEBPACK_IMPORTED_MODULE_2__["default"])(path);
                childPath.push(ai);
                executeRecursive(item[ai], parent, ai, parentIndex, level, childPath);
            }
        }
        else {
            path = Object(lodash_es__WEBPACK_IMPORTED_MODULE_2__["default"])(path);
            path.push(index);
            if (false === func(item, parent, index, parentIndex, level, Object(lodash_es__WEBPACK_IMPORTED_MODULE_2__["default"])(path))) {
                // 如果某一次方法，返回了false，不再递归其子节点
                return;
            }
            if (item.children && item.children.length > 0) {
                // 递归创建子节点
                for (var ci = 0; ci < item.children.length; ci++) {
                    var child = item.children[ci];
                    var childPath = Object(lodash_es__WEBPACK_IMPORTED_MODULE_2__["default"])(path);
                    childPath.push('children');
                    executeRecursive(child, item, ci, index, level + 1, childPath);
                }
            }
        }
    };
    for (var i = 0; i < arr.length; i++) {
        var item = arr[i];
        executeRecursive(item, null, i, 0, 0, []);
    }
}
function copy(obj) {
    return jquery__WEBPACK_IMPORTED_MODULE_0___default.a.extend(true, {}, obj);
}
/**
 * 是否有子节点
 * @param node
 */
function hasChildren(node) {
    return node.children && node.children.length > 0;
}
/**
 * 光标移到最后
 */
function moveCursorEnd(content) {
    focus(content);
    if (content.text() === '') {
        return;
    }
    if (window.getSelection) {
        // var sel = window.getSelection();//创建range
        // sel.selectAllChildren(editor);//range 选择obj下所有子内容
        // sel.collapseToEnd();//光标移至最后
        var length_1 = content.text().length;
        setCursorPosition(content, { start: length_1, end: length_1 });
    }
}
function getTextNodes(editor) {
    editor = editor[0];
    var childNodes = editor.childNodes;
    var textNodes = [];
    // 获取所有的文本节点
    function buildTextNodes(nodes) {
        for (var i = 0; i < nodes.length; i++) {
            var node = nodes[i];
            if (node.nodeName === '#text') {
                textNodes.push(node);
            }
            else if (node.childNodes && node.childNodes.length > 0) {
                buildTextNodes(node.childNodes);
            }
        }
    }
    buildTextNodes(childNodes);
    return textNodes;
}
/**
 * 设置光标的位置
 * @param content 内容输入框
 * @param position 位置的索引
 */
function setCursorPosition(content, position) {
    focus(content);
    if (content.text() === '') {
        return;
    }
    if (!position) {
        return;
    }
    var textNodes = getTextNodes(content);
    if (window.getSelection) {
        // 开始查找光标应该在哪个元素上
        // 光标开始节点、结束节点、开始位置、结束位置
        var startNode = void 0;
        var endNode = void 0;
        var startOffset = 0;
        var endOffset = 0;
        var currentIndex = 0;
        for (var i = 0; i < textNodes.length; i++) {
            var textNode = textNodes[i];
            var textLength = textNode.nodeValue.length;
            if (position.start >= currentIndex && position.start <= currentIndex + textLength) {
                // 在当前行上
                startNode = textNode;
                startOffset = position.start - currentIndex;
                if (!position.end) {
                    break;
                }
            }
            if (position.end && position.end >= currentIndex && position.end <= currentIndex + textLength) {
                // 在当前行上
                endNode = textNode;
                endOffset = position.end - currentIndex;
                break;
            }
            currentIndex += textLength;
        }
        if (startNode || endNode) {
            // 重新设置选区
            var range = document.createRange();
            if (startNode) {
                range.setStart(startNode, startOffset);
            }
            if (endNode) {
                range.setEnd(endNode, endOffset);
            }
            var selection = window.getSelection();
            selection.removeAllRanges();
            selection.addRange(range);
        }
    }
}
/**
 * 获取光标位置
 */
function getCursorPosition() {
    var result = {
        start: 0,
        end: 0,
    };
    var selection = window.getSelection();
    if (selection.rangeCount === 0) {
        return result;
    }
    var range = selection.getRangeAt(0);
    var startNode = range.startContainer;
    var startObj = jquery__WEBPACK_IMPORTED_MODULE_0___default()(startNode);
    // 查找输入容器
    var contentEditor;
    if (startObj.is('div[contenteditable]')) {
        contentEditor = startObj;
    }
    else {
        contentEditor = startObj.parents('div[contenteditable]');
    }
    if (contentEditor.length === 0) {
        return result;
    }
    var preCaretRange = range.cloneRange();
    preCaretRange.selectNodeContents(contentEditor[0]);
    preCaretRange.setEnd(range.startContainer, range.startOffset);
    result.start = preCaretRange.toString().length;
    preCaretRange.setEnd(range.endContainer, range.endOffset);
    result.end = preCaretRange.toString().length;
    return result;
}
/**
 * 让输入框获取焦点
 * 不是直接的调用focus()，因为在safari或iOS webview中，界面会晃动
 * @param editor
 */
function focus(editor) {
    if (navigator.platform) {
        var plat = navigator.platform.toLowerCase();
        if (plat === 'iphone' || plat === 'ipad') {
            if (!editor.length) {
                // 并不是jquery元素
                editor = jquery__WEBPACK_IMPORTED_MODULE_0___default()(editor);
            }
            var range = document.createRange();
            range.setStart(editor[0], 0);
            var selection = window.getSelection();
            selection.removeAllRanges();
            selection.addRange(range);
            return;
        }
    }
    editor.focus();
}
/**
 * 获取一个锚的光标信息
 * @param $target 当前光标的锚点
 * @param $parent 文本的容器（容器必须包含锚点）
 * @param offset 在当前锚点中的定位
 * @description 只适用于当前的编辑区域结构
 * @todo 优化算法，达到获取光标定位的通用性
 */
function getCursorOffset($target, $parent, offset) {
    var prevNode = null;
    /* 若目标节点是编辑区域直接子节点 */
    if ($target.parent().is($parent)) {
        prevNode = $target.get(0).previousSibling;
        /* 若目标节点是编辑区域中的样式填充节点 */
    }
    else if ($target.parent().parent().is($parent)) {
        prevNode = $target.parent().get(0).previousSibling;
    }
    while (prevNode != null) {
        if (prevNode instanceof Text) {
            offset += prevNode.wholeText.length;
        }
        else if (prevNode instanceof HTMLElement) {
            offset += prevNode.innerText.length;
        }
        prevNode = prevNode.previousSibling;
    }
    return offset;
}
/**
 * 获取内容编辑器
 * @param nodeId
 */
function getContentById(nodeId) {
    return jquery__WEBPACK_IMPORTED_MODULE_0___default()('#' + nodeId).children('.content-wrapper').children('.content');
}
/**
 * 获取内容
 * @param nodeDom
 */
function getContentByNode(nodeDom) {
    return nodeDom.children('.content-wrapper').children('.content');
}
/**
 * 获取节点容器
 * @param nodeId
 */
function getNodeContainer(nodeId) {
    return jquery__WEBPACK_IMPORTED_MODULE_0___default()('#' + nodeId);
}
/**
 * 取消选择
 */
function removeSelection() {
    window.getSelection().removeAllRanges();
}
/**
 * html转成文本
 * @param html
 * @returns {*}
 */
function htmlToText(html) {
    // 使用parseHTML创建元素，可以保证内部的动态内容不会被触发，如<img src=x onerror=alert(1)/>
    // parseHTML结果为原生DOM数组
    var tempContainer = jquery__WEBPACK_IMPORTED_MODULE_0___default.a.parseHTML('<div></div>');
    tempContainer = tempContainer[0];
    tempContainer.innerHTML = html;
    return tempContainer.innerText;
}
/**
 * 格式化时间
 * @param time
 * @returns {string}
 */
function formatTime(time) {
    var d = new Date(time);
    var month = d.getMonth() + 1;
    if (month < 10) {
        month = '0' + month;
    }
    var day = d.getDate();
    if (day < 10) {
        day = '0' + day;
    }
    var hours = d.getHours();
    if (hours < 10) {
        hours = '0' + hours;
    }
    var minutes = d.getMinutes();
    if (minutes < 10) {
        minutes = '0' + minutes;
    }
    return d.getFullYear() + '-' + month + '-' + day + ' ' + hours + ':' + minutes;
}
function dataURItoBlob(dataURI) {
    var imageData = atob(dataURI.split(',')[1]);
    // Use typed arrays to convert the binary data to a Blob
    var arraybuffer = new ArrayBuffer(imageData.length);
    var view = new Uint8Array(arraybuffer);
    for (var i = 0; i < imageData.length; i++) {
        view[i] = imageData.charCodeAt(i) & 0xff;
    }
    var blob;
    try {
        // This is the recommended method:
        blob = new Blob([arraybuffer], { type: 'image/png' });
    }
    catch (e) {
        // The BlobBuilder API has been deprecated in favour of Blob, but older
        // browsers don't know about the Blob constructor
        // IE10 also supports BlobBuilder, but since the `Blob` constructor
        //  also works, there's no need to add `MSBlobBuilder`.
        var win = window;
        var bb = void 0;
        if (win.WebKitBlobBuilder) {
            bb = new win.WebKitBlobBuilder();
        }
        else {
            bb = new win.MozBlobBuilder();
        }
        bb.append(arraybuffer);
        blob = bb.getBlob('image/png'); // <-- Here's the Blob
    }
    return blob;
}
/**
 * 计算节点的字符数量
 * @param nodes 节点集合
 * @param containChildren 是否处理子节点
 */
function countNodeWords(nodes, containChildren) {
    // 将text和note拼接
    var result = {
        wordCount: 0,
        nodeCount: 0,
    };
    var text = '';
    function executeNode(node) {
        text += htmlToText(node.text) + '，';
        if (node.note) {
            text += htmlToText(node.note) + '，';
        }
        result.nodeCount++;
    }
    if (containChildren) {
        recursive(nodes, function (node) {
            executeNode(node);
        });
    }
    else {
        jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(nodes, function (index, node) {
            executeNode(node);
        });
    }
    result.wordCount = textCount(text);
    return result;
}
/**
 *
 * 对文本进行处理并计算出数量
 * @param text
 * @returns {Number}
 */
function textCount(text) {
    // 处理至少连续2个的特殊符号，替换为一个中文逗号
    text = text.replace(/[\~|\`|\!|\@|\#|\$|\%|\^|\&|\*|\(|\)|\-|\_|\+|\=|\||\\|\[|\]|\{|\}|\;|\:|\"|\'|\,|\<|\.|\>|\/|\?]{2,}/, '，');
    // 处理空格替换为中文逗号
    text = text.replace(/[ ]/g, '，');
    // 处理单一的特殊符号替换成一个中文逗号
    var pattern = new RegExp('[`~!$*^()=|{}:;,\\[\\]<>/?~！@#￥&（）——|{}……【】·；：”“。，、_?％ % 「」『』]');
    var rs = '';
    for (var i = 0; i < text.length; i++) {
        rs = rs + text.substr(i, 1).replace(pattern, '，');
    }
    // 处理英文字符数字，连续字母、数字、英文符号视为一个单词
    rs = rs.replace(/[\x00-\xff]/g, 'm');
    // 合并字符m，连续字母、数字、英文符号视为一个单词
    rs = rs.replace(/m+/g, '好');
    // 将中文逗号去掉
    rs = rs.replace(/，+/g, '');
    return rs.length;
}

/**
 * Created by morris on 16/5/6.
 * 文档实体对象
 */
var Model = /** @class */ (function () {
    function Model(editorId, define, name, root) {
        this.modelId = '';
        this.name = '';
        // 根节点
        this.rootNode = null;
        // 文档完整定义
        this.define = {
            nodes: []
        };
        // 每个节点映射
        this.mapping = {};
        this.modelId = editorId;
        if (define) {
            this.define = define;
        }
        if (name) {
            this.name = name;
        }
        if (root) {
            this.rootNode = root;
        }
    }
    Model.prototype.getModelId = function () {
        return this.modelId;
    };
    Model.prototype.setName = function (name) {
        this.name = name;
    };
    Model.prototype.getName = function () {
        return this.name;
    };
    Model.prototype.setDefine = function (def) {
        if (def) {
            var me = this;
            me.define = def;
            if (!me.define.nodes) {
                me.define.nodes = [];
            }
            me.buildMapping();
        }
    };
    Model.prototype.getDefine = function () {
        return this.define;
    };
    /**
     * 设置定义
     * @param nodes 节点数组
     */
    Model.prototype.setNodes = function (nodes) {
        if (nodes) {
            this.define.nodes = nodes;
            this.buildMapping();
        }
    };
    /**
     * 设置根节点
     * @param nodeId
     */
    Model.prototype.setRootNode = function (nodeId) {
        if (!nodeId) {
            this.rootNode = null;
        }
        else {
            this.rootNode = this.getById(nodeId);
        }
        return this.rootNode;
    };
    Model.prototype.getRootNode = function () {
        return this.rootNode;
    };
    Model.prototype.setSetting = function (name, value) {
        this.define[name] = value;
    };
    /**
     * 构建mapping
     */
    Model.prototype.buildMapping = function () {
        var _this = this;
        this.mapping = {};
        recursive(this.define.nodes, function (node, parentNode, index, parentIndex, level, path) {
            path.unshift('nodes');
            _this.mapping[node.id] = {
                node: node,
                parentId: parentNode ? parentNode.id : null,
                index: index,
                path: path
            };
        });
    };
    Model.prototype.getMapping = function () {
        return this.mapping;
    };
    /**
     * OT-JSON与内置消息适配器，通过一个节点的id获取一个一个节点的path
     * @param id 节点ID，非节点操作为null
     */
    Model.prototype.getPath = function (id) {
        var path = [];
        var currentId = id;
        while (currentId !== null) {
            var nodeSet = this.mapping[currentId];
            /* 若节点的setting为空，则抛出异常 */
            if (!nodeSet) {
                throw new Error('Null id error!');
            }
            path.unshift(nodeSet.index);
            currentId = nodeSet.parentId;
            /* 若为null，则代表是根节点，否则是常规节点 */
            if (currentId === null) {
                path.unshift('nodes');
            }
            else {
                path.unshift('children');
            }
        }
        return path;
    };
    /**
     * OT-JSON与内置消息的适配器，通过path来获取节点信息
     * @param path 节点path
     */
    Model.prototype.getNodeSet = function (path) {
        var node = Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(this.define, path);
        var nodeSet = this.mapping[node.id];
        /* 若path不正确，则抛异常 */
        if (!nodeSet) {
            throw new Error('Invalid path: ' + path.join('.'));
        }
        return Object(lodash_es__WEBPACK_IMPORTED_MODULE_4__["default"])(nodeSet);
    };
    /**
     * 获取节点总数
     */
    Model.prototype.getCount = function () {
        var count = Object.keys(this.mapping).length;
        if (!count) {
            count = 0;
        }
        return count;
    };
    /**
     * 通过id获取节点
     * @param id
     * @returns {*}
     */
    Model.prototype.getById = function (id) {
        var nodeMapping = this.mapping[id];
        if (nodeMapping) {
            return nodeMapping.node;
        }
        return null;
    };
    /**
     * 获取节点的mapping信息
     * @param {string} nodeId
     * @returns {NodeSet}
     */
    Model.prototype.getMappingById = function (nodeId) {
        return this.mapping[nodeId];
    };
    /**
     * 获取父节点
     * @param id
     */
    Model.prototype.getParent = function (id) {
        var nodeMapping = this.mapping[id];
        if (!nodeMapping) {
            // 节点已经已经不存在
            return null;
        }
        var parentId = nodeMapping.parentId;
        if (parentId) {
            return this.getById(parentId);
        }
        else {
            return null;
        }
    };
    /**
     * 判断 A 节点 是否包含 B 节点，包括等于
     * @param parentId 父级节点
     * @param childId 子节点
     */
    Model.prototype.contains = function (parentId, childId) {
        var nodeId = childId;
        while (nodeId && nodeId !== parentId) {
            var node = this.getParent(nodeId);
            nodeId = node ? node.id : '';
        }
        return nodeId && nodeId === parentId;
    };
    /**
     * 获取父级数组
     * @param nodeId
     */
    Model.prototype.getParentArray = function (nodeId) {
        var parentNode = this.getParent(nodeId);
        var targetArr;
        if (parentNode == null) {
            targetArr = this.define.nodes;
        }
        else {
            // 添加到父节点的children中
            targetArr = parentNode.children;
        }
        return targetArr;
    };
    /**
     * 获取节点在数组中的索引
     * @param nodeId
     */
    Model.prototype.getNodeIndex = function (nodeId) {
        var nodeMapping = this.mapping[nodeId];
        if (nodeMapping) {
            return nodeMapping.index;
        }
        return -1;
    };
    /**
     * 获取节点在数组中的索引
     * @param targetArr
     * @param nodeId
     */
    Model.prototype.getNodeIndexInArray = function (targetArr, nodeId) {
        // 查看当前节点在父数组中的索引
        for (var i = 0; i < targetArr.length; i++) {
            if (targetArr[i].id === nodeId) {
                // 是当前节点，进行删除
                return i;
            }
        }
        return -1;
    };
    /**
     * 添加节点
     * @param nodeStructures 多个节点的结构每个包含parentId，node，index
     */
    Model.prototype.addNodes = function (nodeStructures) {
        var me = this;
        jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(nodeStructures, function (index, structure) {
            var targetArr = me.define.nodes;
            if (structure.parentId) {
                var parentNode = me.getById(structure.parentId);
                if (!parentNode) {
                    // 如果本地没有元素的父节点，忽略
                    return true; // return true = continue;
                }
                if (!parentNode.children) {
                    parentNode.children = [];
                }
                targetArr = parentNode.children;
            }
            targetArr.splice(structure.index, 0, copy(structure.node));
            me.buildMapping();
        });
    };
    /**
     * 在前边添加子节点
     * @param targetId
     * @param nodes
     */
    Model.prototype.prependChildren = function (targetId, nodes) {
        var targetNode = this.getById(targetId);
        if (!targetNode.children) {
            targetNode.children = [];
        }
        jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(nodes, function (index, node) {
            node.modified = new Date().getTime();
            targetNode.children.splice(index, 0, node);
        });
        this.buildMapping();
    };
    /**
     * 在某一节点后边追加同级节点
     * @param targetId
     * @param nodes
     */
    Model.prototype.appendAfter = function (targetId, nodes) {
        var me = this;
        // 添加同级节点
        // 看需要添加到哪个位置
        var targetArr = me.getParentArray(targetId);
        var nodeIndex = me.getNodeIndex(targetId);
        // 在当前节点索引位置后边插入
        jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(nodes, function (i, node) {
            nodeIndex++;
            node.modified = new Date().getTime();
            targetArr.splice(nodeIndex, 0, node);
        });
        me.buildMapping();
    };
    /**
     * 创建新节点
     * @returns {{id: *, text: string}}
     */
    Model.prototype.createNode = function () {
        var id = this.newId();
        return {
            id: id,
            text: '',
            children: [],
            images: [],
            modified: new Date().getTime()
        };
    };
    /**
     * 创建前置同级节点
     * @param nodeId 目标节点的id
     * @param content 新建节点的内容
     */
    Model.prototype.createPrevious = function (nodeId, content) {
        var me = this;
        var newNode = me.createNode();
        if (content) {
            newNode.text = content;
        }
        var node = me.getById(nodeId);
        if (node.color) {
            newNode.color = node.color;
        }
        if (node.heading) {
            newNode.heading = node.heading;
        }
        // 添加同级节点
        // 要添加到的目标数组
        var targetArr = me.getParentArray(nodeId);
        // 看需要添加到哪个位置
        var index = me.getNodeIndex(nodeId);
        // 在当前节点索引位置前边插入
        targetArr.splice(index, 0, newNode);
        me.buildMapping();
        return newNode;
    };
    /**
     * 创建同级节点
     * @param nodeId 目标节点的id
     */
    Model.prototype.createNext = function (nodeId) {
        var me = this;
        var newNode = me.createNode();
        var node = me.getById(nodeId);
        if (node.color) {
            newNode.color = node.color;
        }
        if (node.heading) {
            newNode.heading = node.heading;
        }
        // 添加同级节点
        // 要添加到的目标数组
        var targetArr = me.getParentArray(nodeId);
        // 看需要添加到哪个位置
        var index = me.getNodeIndex(nodeId);
        // 在当前节点索引位置后边插入
        index++;
        targetArr.splice(index, 0, newNode);
        me.buildMapping();
        return newNode;
    };
    /**
     * 创建第一个子节点
     */
    Model.prototype.createFirstChild = function () {
        var me = this;
        var newNode = me.createNode();
        // 添加同级节点
        var targetArr = me.define.nodes;
        if (me.rootNode != null) {
            if (!me.rootNode.children) {
                me.rootNode.children = [];
            }
            targetArr = me.rootNode.children;
        }
        targetArr.splice(0, 0, newNode);
        me.buildMapping();
        return newNode;
    };
    /**
     * 创建第一个子节点
     * @param nodeId
     * @param content 新建节点的内容
     */
    Model.prototype.createChild = function (nodeId, content) {
        var me = this;
        var newNode = me.createNode();
        if (content) {
            newNode.text = content;
        }
        // 添加子级节点
        var node = me.getById(nodeId);
        if (node.color) {
            newNode.color = node.color;
        }
        if (node.heading) {
            newNode.heading = node.heading;
        }
        if (node.children == null) {
            node.children = [];
        }
        node.children.splice(0, 0, newNode);
        me.buildMapping();
        return newNode;
    };
    /**
     * 缩进node
     * @param nodeId 节点id
     * @return 添加到的父节点，如果不能调整，返回null
     */
    Model.prototype.indentNode = function (nodeId) {
        var node = this.getById(nodeId);
        node.modified = new Date().getTime();
        // 要从中删除的目标数组
        var targetArr = this.getParentArray(nodeId);
        var index = this.getNodeIndex(nodeId);
        if (index > 0) {
            // 不是第一个节点，那就放到前一个节点的children中
            var targetNode = targetArr[index - 1];
            if (!targetNode.children) {
                targetNode.children = [];
            }
            targetNode.children.push(node);
            // 同时删除自己
            targetArr.splice(index, 1);
            this.buildMapping();
            return targetNode;
        }
        return null;
    };
    /**
     * 回退node
     * @param nodeId 节点id
     * @return 添加到的父节点，如果不能调整，返回null
     */
    Model.prototype.outdentNode = function (nodeId) {
        var me = this;
        if (me.isRootSubNode(nodeId)) {
            // 是根节点，不能回退
            return null;
        }
        var parent = me.getParent(nodeId);
        var node = me.getById(nodeId);
        if (parent == null) {
            // 是根节点，不处理
            return null;
        }
        node.modified = new Date().getTime();
        // 把节点的从当前数组中删除
        me.removeNode(parent.children, nodeId);
        // 再向上查找一级
        var targetArr = me.getParentArray(parent.id);
        // 父级在爷级的索引
        var index = me.getNodeIndex(parent.id);
        targetArr.splice(index + 1, 0, node);
        me.buildMapping();
        return parent;
    };
    /**
     * 删除节点
     * @param nodeId
     */
    Model.prototype.deleteNode = function (nodeId) {
        var node = this.getById(nodeId);
        if (!node) {
            return;
        }
        // 要从中删除的目标数组
        var targetArr = this.getParentArray(nodeId);
        this.removeNode(targetArr, nodeId);
        this.buildMapping();
    };
    /**
     * 删除多个节点
     * @param nodeIds
     */
    Model.prototype.deleteNodes = function (nodeIds) {
        var me = this;
        if (!jquery__WEBPACK_IMPORTED_MODULE_0___default.a.isArray(nodeIds)) {
            nodeIds = [nodeIds];
        }
        jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(nodeIds, function (index, nodeId) {
            // 要从中删除的目标数组
            var targetArr = me.getParentArray(nodeId);
            // 查看当前节点在父数组中的索引，删除它，因为节点的索引可能会发生变化，所以每次都重新查找
            for (var i = 0; i < targetArr.length; i++) {
                if (targetArr[i].id === nodeId) {
                    // 是当前节点，进行删除
                    targetArr.splice(i, 1);
                }
            }
        });
        me.buildMapping();
    };
    /**
     * 从父节点中删除
     * @param parentArr
     * @param nodeId
     */
    Model.prototype.removeNode = function (parentArr, nodeId) {
        var index = this.getNodeIndexInArray(parentArr, nodeId);
        if (index >= 0) {
            parentArr.splice(index, 1);
        }
    };
    /**
     * 移动节点
     * @param nodeId
     * @param targetId
     * @param type 移动类型，在前还是在后，prev | next
     */
    Model.prototype.moveNode = function (nodeId, targetId, type) {
        var me = this;
        // 先删除，在查看目标的节点的索引，因为目标节点和当前节点可能是同一组
        var nodeParentArray = this.getParentArray(nodeId);
        me.removeNode(nodeParentArray, nodeId);
        // 使用重新遍历父级数组的形式取索引，因为如果两个节点在同一级的时候，索引会发生变化，不能取mapping中的index
        var targetArr = me.getParentArray(targetId);
        var index = me.getNodeIndexInArray(targetArr, targetId);
        var node = me.getById(nodeId);
        if (type === 'next') {
            index++;
        }
        node.modified = new Date().getTime();
        targetArr.splice(index, 0, node);
        me.buildMapping();
    };
    /**
     * 移动多个节点
     * @param nodeId
     * @param targetId
     * @param type 移动类型，在前还是在后，prev | next
     */
    Model.prototype.moveNodes = function (nodes, targetId, type) {
        var me = this;
        jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(nodes, function (nodeIndex, node) {
            // 先删除，在查看目标的节点的索引，因为目标节点和当前节点可能是同一组
            var nodeId = node.id;
            var nodeParentArray = me.getParentArray(nodeId);
            me.removeNode(nodeParentArray, nodeId);
            var targetArr = me.getParentArray(targetId);
            // 使用重新遍历父级数组的形式取索引，因为如果两个节点在同一级的时候，索引会发生变化，不能取mapping中的index
            var targetIndex = me.getNodeIndexInArray(targetArr, targetId);
            if (type === 'next') {
                targetIndex = targetIndex + nodeIndex + 1;
            }
            node.modified = new Date().getTime();
            targetArr.splice(targetIndex, 0, node);
        });
        me.buildMapping();
    };
    /**
     * 重新设置节点位置
     * @param parentId
     * @param index
     * @param nodeId
     */
    Model.prototype.relocateNode = function (parentId, index, nodeId) {
        var me = this;
        var node = me.getById(nodeId);
        var targetArr;
        if (parentId) {
            var parentNode = me.getById(parentId);
            if (!parentNode) {
                // 有可能parent已经不存在，比如协同消息未到达时，本地进行了删除
                return;
            }
            // 添加到父节点的children中
            if (!parentNode.children) {
                parentNode.children = [];
            }
            targetArr = parentNode.children;
        }
        else {
            targetArr = this.define.nodes;
        }
        node.modified = new Date().getTime();
        targetArr.splice(index, 0, node);
    };
    /**
     * 更新节点
     * @param node
     */
    Model.prototype.update = function (node) {
        var nodeMapping = this.mapping[node.id];
        var target = nodeMapping.node;
        if (!target) {
            // 被更新的节点可能已经不存在
            return;
        }
        jquery__WEBPACK_IMPORTED_MODULE_0___default.a.extend(true, target, node);
        if (!node.images) {
            // 有可能要更新的节点图片不存在，这时候extend不会修改images字段，手动执行删除
            delete target.images;
        }
        else {
            target.images = node.images;
        }
        // 因为node中可能不存在finish和collapsed属性，所以特殊处理一下
        if (!node.finish) {
            target.finish = false;
        }
        if (!node.collapsed) {
            target.collapsed = false;
        }
        node.modified = new Date().getTime();
        this.buildMapping();
    };
    /**
     * 创建新的id
     */
    Model.prototype.newId = function () {
        return newId(this.modelId);
    };
    /**
     * 是否是顶级节点
     * @param nodeId
     */
    Model.prototype.isTopLevel = function (nodeId) {
        var me = this;
        var parentNode = me.getParent(nodeId);
        return parentNode == null || (me.rootNode != null && me.rootNode.id === nodeId);
    };
    /**
     * 是否是根节点
     * @param nodeId
     */
    Model.prototype.isRootNode = function (nodeId) {
        var me = this;
        return me.rootNode != null && me.rootNode.id === nodeId;
    };
    /**
     * 是否是一级
     * @param nodeId
     */
    Model.prototype.isRootSubNode = function (nodeId) {
        var me = this;
        var parent = me.getParent(nodeId);
        if (me.rootNode != null) {
            return parent != null && parent.id === me.rootNode.id;
        }
        else if (parent == null) {
            return true;
        }
        return false;
    };
    /**
     * 获取全部主节点，也就是在列表中的第一级节点
     */
    Model.prototype.getRootSubNodes = function () {
        var me = this;
        var rootNode = me.rootNode;
        if (rootNode == null) {
            return me.define.nodes;
        }
        else {
            return rootNode.children ? rootNode.children : [];
        }
    };
    /**
     * 获取当前的路径
     */
    Model.prototype.getDir = function () {
        var result = [];
        var currentNode = this.rootNode;
        if (currentNode != null) {
            while (true) {
                // 层级向上查找，并往数组后边push
                var parentNode = this.getParent(currentNode.id);
                if (parentNode == null) {
                    break;
                }
                result.push(parentNode);
                currentNode = parentNode;
            }
            result.reverse();
        }
        return result;
    };
    /**
     * 获取前面的节点（同级或父级）
     */
    Model.prototype.getPrevNode = function (nodeId) {
        var me = this;
        var nodeIndex = me.getNodeIndex(nodeId);
        if (nodeIndex > 0) {
            // 同级上一个
            var targetArr = me.getParentArray(nodeId);
            return targetArr ? targetArr[nodeIndex - 1] : null;
        }
        else {
            // 父级 node
            return this.getParent(nodeId);
        }
    };
    /**
     * 获取前边的同级节点
     * @param nodeId
     * @returns {*}
     */
    Model.prototype.getPrevSibling = function (nodeId) {
        var me = this;
        var nodeIndex = me.getNodeIndex(nodeId);
        if (nodeIndex > 0) {
            var targetArr = me.getParentArray(nodeId);
            return targetArr[nodeIndex - 1];
        }
    };
    /**
     * 获取后边的同级节点
     * @param nodeId
     * @returns {*}
     */
    Model.prototype.getNextSibling = function (nodeId) {
        var me = this;
        var nodeIndex = me.getNodeIndex(nodeId);
        var targetArr = me.getParentArray(nodeId);
        if (nodeIndex < targetArr.length - 1) {
            return targetArr[nodeIndex + 1];
        }
    };
    return Model;
}());

/*! *****************************************************************************
Copyright (c) Microsoft Corporation. All rights reserved.
Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at http://www.apache.org/licenses/LICENSE-2.0

THIS CODE IS PROVIDED ON AN *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY IMPLIED
WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR PURPOSE,
MERCHANTABLITY OR NON-INFRINGEMENT.

See the Apache Version 2.0 License for specific language governing permissions
and limitations under the License.
***************************************************************************** */

var __assign = function() {
    __assign = Object.assign || function __assign(t) {
        for (var s, i = 1, n = arguments.length; i < n; i++) {
            s = arguments[i];
            for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p)) t[p] = s[p];
        }
        return t;
    };
    return __assign.apply(this, arguments);
};

var SourceEvent;
(function (SourceEvent) {
    /**
     * 本地发生编辑
     */
    SourceEvent["DOC_CHANGED"] = "DOC_CHANGED";
    /**
     * 执行远端消息
     */
    SourceEvent["MESSAGE_EXECUTED"] = "MESSAGE_EXECUTED";
    /**
     * 文档标题改变
     */
    SourceEvent["TITLE_CHANGED"] = "TITLE_CHANGED";
    /**
     * 翻页钻取
     */
    SourceEvent["DRILLED"] = "DRILLED";
    /**
     * drill某个节后后，节点被其他人删除了
     * @type {string}
     */
    SourceEvent["DRILL_REMOVED"] = "DRILL_REMOVED";
    /**
     * 思维导图打开事件
     */
    SourceEvent["MIND_MAP_OPEN"] = "MIND_MAP_OPEN";
    /**
     * 思维导图关闭事件
     */
    SourceEvent["MIND_MAP_CLOSE"] = "MIND_MAP_CLOSE";
    /**
     * 思维导图导出事件，data参数格式：{name: string, base64Data: string}
     * @type {string}
     */
    SourceEvent["MIND_MAP_EXPORT"] = "MIND_MAP_EXPORT";
    /**
     * 打开一个连接的事件，会把url地址作为data参数传入
     * @type {string}
     */
    SourceEvent["LINK_OPEN"] = "LINK_OPEN";
    /**
     * 添加图片事件
     * @type {string}
     */
    SourceEvent["ADD_IMAGE"] = "ADD_IMAGE";
    /**
     * 需要弹出提醒信息事件
     * @type {string}
     */
    SourceEvent["TIP_MESSAGE"] = "TIP_MESSAGE";
    /**
     * 预览图片
     * @type {string}
     */
    SourceEvent["PREVIEW_IMAGE"] = "PREVIEW_IMAGE";
    /**
     * 节点的点击事件
     * @type {string}
     */
    SourceEvent["NODE_CLICK"] = "NODE_CLICK";
    /*
     * 输入框的focus事件
     * @type {string}
     */
    SourceEvent["INPUT_FOCUS"] = "INPUT_FOCUS";
})(SourceEvent || (SourceEvent = {}));
/**
 * 复制一个节点，忽略children
 * @param node
 * @returns {{}}
 */
function copy$1(node) {
    var result = {};
    for (var key in node) {
        if (key === 'images') {
            // 数组类型的字段要深度拷贝
            if (node.images && node.images.length > 0) {
                result.images = [];
                jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(node.images, function (index, img) {
                    result.images.push(jquery__WEBPACK_IMPORTED_MODULE_0___default.a.extend({}, img));
                });
            }
            else {
                result.images = [];
            }
        }
        else if (key !== 'children') {
            result[key] = node[key];
        }
    }
    return result;
}
/**
 * Created by morris on 16/5/11.
 * 事件相关
 */
var EventSource = /** @class */ (function () {
    function EventSource(model, selectHolder, state, viewport) {
        this.handlers = {};
        // 记录每一个节点的定义状态，和model的对象引用是分开的
        // 用来再更新时，获取到节点的之前状态
        this.mapping = {};
        this.nodeDefaults = {
            text: '',
            note: '',
            modified: 0,
            finish: false,
            collapsed: false,
            color: '',
            heading: 0
        };
        this.model = model;
        this.selectHolder = selectHolder;
        this.state = state;
        this.viewport = viewport;
        this.initEventListeners();
    }
    /**
     * 通过id获取
     * @param nodeId
     * @returns {*|{}}
     */
    EventSource.prototype.getNodeById = function (nodeId) {
        return copy$1(this.mapping[nodeId].node);
    };
    /**
     * 获取mapping
     * @param nodeId
     */
    EventSource.prototype.getMappingById = function (nodeId) {
        return copy(this.mapping[nodeId]);
    };
    /**
     * 设置节点
     * @param nodes
     */
    EventSource.prototype.setNodes = function (nodes) {
        var _this = this;
        if (!nodes || nodes.length === 0) {
            return;
        }
        this.mapping = {};
        recursive(nodes, function (node, parent, indexNum, parentIndex, level, path) {
            path.unshift('nodes');
            _this.mapping[node.id] = {
                node: copy$1(node),
                parentId: parent ? parent.id : null,
                index: indexNum,
                path: path
            };
        });
    };
    /**
     * 触发事件
     * @param eventName
     * @param data
     * @param extendData 扩展数据
     */
    EventSource.prototype.trigger = function (eventName, data, extendData) {
        Object(lodash_es__WEBPACK_IMPORTED_MODULE_5__["default"])(this.handlers[eventName], function (handler) {
            if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_6__["default"])(handler)) {
                handler(data, extendData);
            }
        });
    };
    /**
     * 监听事件
     * @param eventName
     * @param handler
     */
    EventSource.prototype.on = function (eventName, handler) {
        var handlers = this.handlers[eventName];
        if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_7__["default"])(handlers)) {
            handlers.push(handler);
        }
        else {
            this.handlers[eventName] = [handler];
        }
    };
    /**
     * 从model中同步对象定义
     */
    EventSource.prototype.synchronizeModel = function () {
        var nodes = this.model.getDefine().nodes;
        this.setNodes(nodes);
    };
    /**
     * 文档变化时
     */
    EventSource.prototype.documentChanged = function () {
        this.synchronizeModel();
    };
    /**
     * 管理wrapper，交给外部注册的监听器
     */
    EventSource.prototype.manageWrapper = function () {
        this.trigger('wrapper-changed');
    };
    /**
     * 管理节点的展开收缩图标
     */
    EventSource.prototype.managerToggle = function () {
        var leafClass = 'mindnote-leaf';
        this.viewport.paper.find('.node').addClass(leafClass);
        this.viewport.paper.find('.children').each(function () {
            var childrenContainer = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            if (childrenContainer.children().length > 0) {
                childrenContainer.parent().removeClass(leafClass);
            }
        });
    };
    /**
     * 构建删除的消息
     * @param deletedNodes
     */
    EventSource.prototype.getDeleteAction = function (deletedNodes) {
        var _this = this;
        var result = {
            name: 'delete',
            deleted: []
        };
        Object(lodash_es__WEBPACK_IMPORTED_MODULE_5__["default"])(deletedNodes, function (node) {
            var nodeMapping = _this.getMappingById(node.id);
            // 因为需要包含children，从model中取
            nodeMapping.node = node;
            result.deleted.push(nodeMapping);
        });
        return result;
    };
    /**
     * 构建更新的消息
     * @param updatedNodes
     * @param updateData
     */
    EventSource.prototype.getUpdateAction = function (updatedNodes, updateData) {
        var _this = this;
        var result = {
            name: 'update',
            updated: []
        };
        // copy一下，目的是去掉children属性
        updateData = copy$1(updateData);
        Object(lodash_es__WEBPACK_IMPORTED_MODULE_5__["default"])(updatedNodes, function (node) {
            var originalNode = _this.getNodeById(node.id);
            var original = { id: node.id };
            Object(lodash_es__WEBPACK_IMPORTED_MODULE_5__["default"])(Object(lodash_es__WEBPACK_IMPORTED_MODULE_8__["default"])(updateData), function (key) {
                if (key !== 'children') {
                    if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_9__["default"])(originalNode[key])) {
                        original[key] = _this.nodeDefaults[key];
                    }
                    else {
                        original[key] = originalNode[key];
                    }
                }
            });
            result.updated.push({
                updated: __assign({ id: node.id }, updateData),
                original: original,
                path: _this.mapping[node.id].path
            });
        });
        return result;
    };
    EventSource.prototype.popDocChangeActions = function (actions) {
        if (!this.state.readonly) {
            this.trigger(SourceEvent.DOC_CHANGED, actions);
        }
    };
    /**
     * 初始化自带的监听器
     */
    EventSource.prototype.initEventListeners = function () {
        var _this = this;
        /**
         * 打开一页后的事件
         */
        this.on('opened', function () {
            _this.manageWrapper();
        });
        /**
         * 创建后事件
         */
        this.on('created', function (data) {
            var actions = [];
            if (data.updated) {
                // 如果删除的同时发生了更新，则添加更新的动作
                var updateAction = _this.getUpdateAction(data.updated, data.updateData);
                actions.push(updateAction);
            }
            // 创建后要先调用documentChanged来同步model，因为要获取最新的mapping
            _this.documentChanged();
            _this.manageWrapper();
            _this.managerToggle();
            // 发送创建消息
            var createdNodes = data.created;
            var messageNodes = [];
            jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(createdNodes, function (index, node) {
                var messageNode = _this.getMappingById(node.id);
                messageNode.node = _this.model.getById(node.id);
                messageNodes.push(messageNode);
            });
            var createAction = {
                name: 'create',
                created: messageNodes
            };
            if (data.cursor) {
                createAction.cursor = data.cursor;
            }
            actions.push(createAction);
            actions = Object(lodash_es__WEBPACK_IMPORTED_MODULE_4__["default"])(actions);
            _this.popDocChangeActions(actions);
        });
        /**
         * 节点删除后的事件
         */
        this.on('deleted', function (data) {
            var actions = [];
            // 删除的消息
            var deleteAction = _this.getDeleteAction(data.deleted);
            if (_this.selectHolder.getSelectIds().length > 0) {
                deleteAction.selected = _this.selectHolder.getSelectIds();
            }
            actions.push(deleteAction);
            if (data.updated) {
                // 如果删除的同时发生了更新，则添加更新的动作
                // 如在节点内容最前按backspace，本节点删除，同时将本节点的内容合并到上一节点
                var updateAction = _this.getUpdateAction(data.updated, data.updateData);
                actions.push(updateAction);
            }
            actions = Object(lodash_es__WEBPACK_IMPORTED_MODULE_4__["default"])(actions);
            _this.documentChanged();
            _this.manageWrapper();
            _this.managerToggle();
            _this.popDocChangeActions(actions);
        });
        /**
         * 节点更新后节点，设置属性(合并、完成)
         * @param updateData 扩展属性，修改的属性-值
         */
        this.on('updated', function (data, updateData) {
            var updateAction = _this.getUpdateAction(data.updated, updateData);
            if (_this.selectHolder.getSelectIds().length > 0) {
                updateAction.selected = _this.selectHolder.getSelectIds();
            }
            var actions = [updateAction];
            _this.documentChanged();
            _this.popDocChangeActions(actions);
        });
        /**
         * 节点文本更新后
         * @description text 更新走 input action，不用发 update action
         */
        this.on('updateText', function (data, updateData) {
            _this.documentChanged();
        });
        /**
         * 结构发生变化事件，indent、outdent、拖动节点
         */
        this.on('structureChanged', function (data) {
            // 发送变化的消息
            var changedNodes = data.changed;
            var messageNodes = [];
            jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(changedNodes, function (index, node) {
                var nodeMapping = _this.model.getMappingById(node.id);
                var parentNode = _this.model.getParent(node.id);
                var original = _this.getMappingById(node.id);
                var changedMessage = {
                    changed: {
                        parentId: parentNode ? parentNode.id : null,
                        index: nodeMapping.index,
                        node: node,
                        path: nodeMapping.path
                    },
                    original: __assign({}, original, { node: __assign({}, node, original.node) })
                };
                messageNodes.push(changedMessage);
            });
            var actions = [];
            if (data.updated) {
                // 如果同时发生了更新，则添加更新的动作，比如缩进时，新的父节点自动展开了
                var updateAction = _this.getUpdateAction(data.updated, data.updateData);
                actions.push(updateAction);
            }
            var action = {
                name: 'structureChanged',
                changed: messageNodes
            };
            if (data.cursor) {
                action.cursor = data.cursor;
            }
            if (_this.selectHolder.getSelectIds().length > 0) {
                action.selected = _this.selectHolder.getSelectIds();
            }
            actions.push(action);
            actions = Object(lodash_es__WEBPACK_IMPORTED_MODULE_4__["default"])(actions);
            _this.documentChanged();
            _this.managerToggle();
            _this.popDocChangeActions(actions);
        });
        /**
         * 翻页钻取事件
         */
        this.on('drilled', function (data) {
            _this.manageWrapper();
            // 发送钻取消息
            var action = {
                name: 'drill',
                from: data.from,
                to: data.to
            };
            _this.trigger(SourceEvent.DRILLED, action);
        });
        /**
         * change 事件，redo/undo
         */
        this.on('changed', function (messages) {
            _this.documentChanged();
            _this.manageWrapper();
            _this.managerToggle();
        });
        /**
         * 配置发生变化事件
         */
        this.on('settingChanged', function (data) {
            _this.documentChanged();
            // 只抛出事件，本地消息队列不做记录
            var action = {
                name: 'settingChanged',
                changed: data.changed,
                original: data.original
            };
            _this.popDocChangeActions([action]);
        });
        /**
         * 标题发生了变化
         */
        this.on('nameChanged', function (data) {
            _this.trigger(SourceEvent.TITLE_CHANGED, data);
        });
        /**
         * 其他编辑消息处理后，与model进行同步
         * 否则本地再操作变化的节点时，NodeHolder会没有，导致异常情况
         */
        this.on('messageExecuted', function () {
            _this.synchronizeModel();
            _this.manageWrapper();
            _this.managerToggle();
            _this.trigger(SourceEvent.MESSAGE_EXECUTED);
        });
        /**
         * 编辑器状态发生了变化，目前只有只读状态
         */
        this.on('editorStateChanged', function () {
            _this.manageWrapper();
            _this.managerToggle();
        });
    };
    return EventSource;
}());

/**
 * 是否是微信内置浏览器
 */
/**
 * 是否是手机
 * @returns {boolean}
 */
function isMobile() {
    var agent = window.navigator.userAgent;
    var keywords = ['Android', 'iPhone', 'iPod', 'iPad', 'Windows Phone', 'BlackBerry', 'MQQBrowser'];
    if (agent.indexOf('Windows NT') < 0 && agent.indexOf('Macintosh') < 0) {
        // 排除 Windows Mac 桌面系统
        for (var i = 0; i < keywords.length; i++) {
            var keyword = keywords[i];
            if (agent.indexOf(keyword) >= 0) {
                return true;
            }
        }
    }
    return false;
}
/**
 * 是否是火狐浏览器
 */
function isFirefox() {
    var ua = navigator.userAgent.toLowerCase();
    return ua.indexOf('firefox') > 0;
}
function isChrome() {
    var ua = navigator.userAgent.toLowerCase();
    return ua.indexOf('chrome') > 0 || ua.indexOf('chromium') > 0;
}
function isSafari() {
    var ua = navigator.userAgent.toLowerCase();
    return ua.indexOf('safari') > 0 && ua.indexOf('version') > 0 && ua.indexOf('chrome') < 0 && ua.indexOf('chromium') < 0;
}
function isIE() {
    var ua = navigator.userAgent.toLowerCase();
    return ua.indexOf('msie') > 0 || (ua.indexOf('rv:') > 0 && ua.indexOf('trident') > 0) || ua.indexOf('edge') > 0;
}
function isEdge() {
    var ua = navigator.userAgent.toLowerCase();
    return ua.indexOf('edge') > 0;
}
function isMac() {
    var platform = navigator.platform;
    return platform.toLowerCase().indexOf('mac') >= 0;
}

/**
 * 功能键是哪个，用来区分不同的操作系统
 */
var environment = {
    metaKey: 'ctrlKey',
    metaKeyText: 'Ctrl',
    downEvent: 'mousedown',
    moveEvent: 'mousemove',
    upEvent: 'mouseup',
    isMac: isMac(),
    isIE: isIE(),
    isEdge: isEdge(),
    isFirefox: isFirefox(),
    isMobile: isMobile(),
    isWebkit: isChrome() || isSafari(),
};
var platform = navigator.platform;
if (platform.toLowerCase().indexOf('mac') >= 0) {
    // mac系统
    environment.metaKey = 'metaKey';
    environment.metaKeyText = '⌘';
}
if (environment.isMobile) {
    environment.downEvent = 'touchstart';
    environment.moveEvent = 'touchmove';
    environment.upEvent = 'touchend';
}

var Engine = /** @class */ (function () {
    function Engine(model, imageUploading, state, painter, viewport, eventSource) {
        var _this = this;
        this.model = model;
        this.viewport = viewport;
        this.paper = viewport.paper;
        this.state = state;
        this.wrapper = viewport.nodeWrapper;
        this.painter = painter;
        this.eventSource = eventSource;
        this.imageUploading = imageUploading;
        this.scrollContainer = viewport.scrollContainer;
        this.eventSource.on('wrapper-changed', function () {
            _this.manageWrapper();
        });
    }
    /**
     * 打开文档
     * @param definition
     * @param {string} name
     */
    Engine.prototype.open = function (definition, name) {
        if (name) {
            this.setName(name);
        }
        if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_9__["default"])(definition) || Object(lodash_es__WEBPACK_IMPORTED_MODULE_9__["default"])(definition.nodes)) {
            definition = { nodes: [] };
        }
        var nodes = definition.nodes;
        this.model.setDefine(definition);
        this.eventSource.setNodes(nodes);
        this.painter.renderPaper();
        if (!environment.isMobile) {
            this.viewport.nameContainer.find('input').focus();
        }
        this.eventSource.trigger('opened');
    };
    Engine.prototype.getWrapper = function () {
        return this.wrapper;
    };
    Engine.prototype.getPainter = function () {
        return this.painter;
    };
    /**
     * 获取节点定义对象
     * @param nodeId
     * @returns {*}
     */
    Engine.prototype.getNode = function (nodeId) {
        return this.model.getById(nodeId);
    };
    /**
     * 是否允许新建
     */
    Engine.prototype.allowCreateNew = function (nodeCount) {
        return true;
    };
    /**
     * 创建前边的节点
     * @param nodeId
     * @param nodeContent 当前节点的文本
     * @param prevContent 前置节点的文本
     */
    Engine.prototype.createPrevious = function (nodeId, nodeContent, prevContent) {
        if (!this.allowCreateNew(1)) {
            return;
        }
        var targetNode = this.model.getById(nodeId);
        var eventData = {
            cursor: {
                id: nodeId,
                position: getCursorPosition()
            }
        };
        if (nodeContent) {
            targetNode.text = nodeContent;
            // 更新当前节点内容
            this.model.update(targetNode);
            eventData.updated = [targetNode];
            eventData.updateData = { text: nodeContent };
        }
        var newNode = this.model.createPrevious(nodeId, prevContent);
        this.painter.renderPrevious(nodeId, newNode);
        var nodeEditor = getContentById(nodeId);
        nodeEditor.html(nodeContent);
        if (!prevContent) {
            moveCursorEnd(getContentById(newNode.id));
        }
        else {
            focus(getContentById(nodeId));
        }
        eventData.created = [newNode];
        this.eventSource.trigger('created', eventData);
    };
    /**
     * 创建后边的节点
     * @param nodeId 目标节点的id
     */
    Engine.prototype.createNext = function (nodeId) {
        if (!this.allowCreateNew(1)) {
            return;
        }
        var newNode;
        var rootNode = this.getRootNode();
        if (rootNode && nodeId === rootNode.id) {
            // 添加为第一个子节点
            newNode = this.model.createChild(nodeId, '');
            this.painter.renderFirstChild(nodeId, newNode);
        }
        else {
            var targetNode = this.model.getById(nodeId);
            if (!htmlToText(targetNode.text) && !this.model.isRootSubNode(nodeId) && !this.model.getNextSibling(nodeId)) {
                this.outdentNode(nodeId);
                return;
            }
            if (!targetNode.collapsed && hasChildren(targetNode)) {
                // 添加为第一个子节点
                newNode = this.model.createChild(nodeId, '');
                this.painter.renderFirstChild(nodeId, newNode);
            }
            else {
                // 在后边添加同级节点
                newNode = this.model.createNext(nodeId);
                this.painter.renderNext(nodeId, newNode);
            }
        }
        var newNodeContainer = getContentById(newNode.id);
        focus(newNodeContainer);
        var eventData = {
            cursor: {
                id: nodeId,
                position: getCursorPosition()
            },
            created: [newNode]
        };
        this.eventSource.trigger('created', eventData);
    };
    /**
     * 创建根节点后边的节点
     */
    Engine.prototype.createRootNext = function () {
        var newNode = this.model.createFirstChild();
        this.painter.renderNode(newNode, false);
        focus(getContentById(newNode.id));
        var eventData = {
            created: [newNode]
        };
        this.eventSource.trigger('created', eventData);
    };
    /**
     * 创建后边的一堆节点
     */
    Engine.prototype.appendNextNodes = function (targetId, nodes) {
        var _this = this;
        if (nodes.length === 0) {
            return;
        }
        var me = this;
        // 进行了创建的节点，是一维的数组结构
        var createdNodes = [];
        var lastId = '';
        var targetNode = this.model.getById(targetId);
        recursive(nodes, function (node) {
            node.id = _this.model.newId();
            if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_9__["default"])(node.children)) {
                node.children = [];
            }
            if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_9__["default"])(node.images)) {
                node.images = [];
            }
            lastId = node.id;
        });
        Object(lodash_es__WEBPACK_IMPORTED_MODULE_5__["default"])(nodes, function (node) {
            createdNodes.push(node);
        });
        var eventData = {
            created: createdNodes
        };
        if (this.model.isRootNode(targetId)
            || (targetNode.children && targetNode.children.length > 0)) {
            // 有子节点，将这些节点放到此节点的子节点中
            this.model.prependChildren(targetId, nodes);
            // 重新绘制子节点
            me.painter.renderChildren(targetId);
        }
        else {
            // 在当前节点后边追加同级
            if (htmlToText(targetNode.text) === '' && !targetNode.note) {
                // 当前节点内容为空的情况下，将第一个节点的内容复制到当前节点
                var firstNode = nodes[0];
                firstNode.id = targetId;
                this.model.update(firstNode);
                // 先重绘自己，再绘制子节点
                me.painter.refreshNode(firstNode);
                me.painter.renderChildren(firstNode.id);
                eventData.updated = [firstNode];
                eventData.updateData = firstNode;
                // 删除第一个节点
                nodes.splice(0, 1);
                createdNodes.splice(0, 1);
                // 第一个节点的子节点，为新建出来的节点
                if (firstNode.children && firstNode.children.length > 0) {
                    var childIndex = firstNode.children.length - 1;
                    while (childIndex >= 0) {
                        var createdChild = firstNode.children[childIndex];
                        createdNodes.unshift(createdChild);
                        childIndex--;
                    }
                }
            }
            // 在此节点后边同级追加
            this.model.appendAfter(targetId, nodes);
            var afterId = targetId;
            // 重新绘制全部
            var index = 0;
            while (index < nodes.length) {
                var newNode = nodes[index];
                me.painter.renderNext(afterId, newNode);
                me.painter.renderChildren(newNode.id);
                afterId = newNode.id;
                index++;
            }
        }
        // 定位光标
        var lastContent = getContentById(lastId);
        if (lastContent.is(':visible')) {
            moveCursorEnd(lastContent);
        }
        // 最终抛出事件
        this.eventSource.trigger('created', eventData);
    };
    /**
     * 复制节点
     * @param nodeId
     */
    Engine.prototype.copyNode = function (nodeId) {
        var _this = this;
        var me = this;
        var sourceNode = this.model.getById(nodeId);
        if (!me.allowCreateNew(1)) {
            return;
        }
        // 构建新的对象
        var newNode = copy(sourceNode);
        var newArray = [newNode];
        recursive(newArray, function (node) {
            node.id = _this.model.newId();
        });
        // 在此节点后边同级追加
        this.model.appendAfter(nodeId, newArray);
        me.painter.renderNext(nodeId, newNode);
        me.painter.renderChildren(newNode.id);
        var eventData = {
            created: newArray
        };
        this.eventSource.trigger('created', eventData);
        focus(getContentById(newNode.id));
    };
    /**
     * 删除节点
     * @param nodeId
     * @param prevId 上一节点id
     * @param preValue 上一内容
     * @param preNote 上一节点的备注
     */
    Engine.prototype.deleteNode = function (nodeId, prevId, preValue, preNote) {
        var deleted = this.model.getById(nodeId);
        this.model.deleteNode(nodeId);
        var eventData = {
            deleted: [deleted]
        };
        if (preValue && prevId) {
            var prevNode = this.model.getById(prevId);
            // 如果被删除的节点有图片，合并到上一个节点
            if (deleted.images) {
                if (!prevNode.images) {
                    prevNode.images = [];
                }
                prevNode.images = prevNode.images.concat(deleted.images);
            }
            // 如果有内容，合并到前一节点
            if (preValue && prevId) {
                prevNode.text = preValue;
                if (preNote) {
                    prevNode.note = preNote;
                }
            }
            // 更新内容
            this.model.update(prevNode);
            eventData.updated = [prevNode];
            eventData.updateData = prevNode;
            this.painter.refreshNode(prevNode);
        }
        getNodeContainer(nodeId).remove();
        this.eventSource.trigger('deleted', eventData);
    };
    /**
     * 直接删除节点
     * @param nodeIds
     */
    Engine.prototype.deleteNodeDirectly = function (nodeIds) {
        var _this = this;
        if (!jquery__WEBPACK_IMPORTED_MODULE_0___default.a.isArray(nodeIds)) {
            nodeIds = [nodeIds];
        }
        if (nodeIds.length === 0) {
            return;
        }
        var firstId = nodeIds[0];
        var prev = this.toPrevNode(firstId, false);
        if (prev == null && nodeIds.length === 1) {
            // 只有一个节点的情况下，向下控制光标
            this.toNextNode(firstId, true);
        }
        var deleted = [];
        jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(nodeIds, function (index, id) {
            var node = _this.model.getById(id);
            deleted.push(node);
            // 执行删除
            _this.model.deleteNode(id);
            getNodeContainer(id).remove();
        });
        var eventData = {
            deleted: deleted
        };
        this.eventSource.trigger('deleted', eventData);
    };
    /**
     * 缩进node
     * @param nodeId
     */
    Engine.prototype.indentNode = function (nodeId) {
        var parentNode = this.model.indentNode(nodeId);
        if (parentNode != null) {
            var cursorPos = getCursorPosition();
            // 改变了父级关系，重构dom结构
            var parentDom = getNodeContainer(parentNode.id);
            var eventData = {};
            if (parentNode.collapsed) {
                // 目标的父节点收缩了，让其展开
                parentNode.collapsed = false;
                parentDom.removeClass('collapsed');
                eventData.updated = [parentNode];
                eventData.updateData = { collapsed: false };
            }
            var target = parentDom.children('.children');
            if (target.length === 0) {
                target = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="children"></div>').appendTo(parentDom);
            }
            var nodeContainer = getNodeContainer(nodeId);
            nodeContainer.appendTo(target);
            var editor = getContentById(nodeId);
            // 重新设置光标位置
            setCursorPosition(editor, cursorPos);
            var node = this.model.getById(nodeId);
            eventData.changed = [node];
            eventData.cursor = {
                id: nodeId,
                position: cursorPos
            };
            this.eventSource.trigger('structureChanged', eventData);
        }
    };
    /**
     * 缩进多个node
     * @param nodes 树形的节点结构
     */
    Engine.prototype.indentNodes = function (nodes) {
        var _this = this;
        var eventData = {
            updated: [],
            changed: []
        };
        jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(nodes, function (index, node) {
            var nodeId = node.id;
            var parentNode = _this.model.indentNode(nodeId);
            if (parentNode != null) {
                // 改变了父级关系，重构dom结构
                var parentDom = getNodeContainer(parentNode.id);
                if (parentNode.collapsed) {
                    // 目标的父节点收缩了，让其展开
                    parentNode.collapsed = false;
                    parentDom.removeClass('collapsed');
                    eventData.updated.push(parentNode);
                    eventData.updateData = { collapsed: false };
                }
                var target = parentDom.children('.children');
                if (target.length === 0) {
                    target = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="children"></div>').appendTo(parentDom);
                }
                var nodeContainer = getNodeContainer(nodeId);
                nodeContainer.appendTo(target);
                eventData.changed.push(node);
            }
        });
        if (eventData.changed.length > 0) {
            this.eventSource.trigger('structureChanged', eventData);
        }
    };
    /**
     * 回退node
     * @param nodeId
     */
    Engine.prototype.outdentNode = function (nodeId) {
        var parentNode = this.model.outdentNode(nodeId);
        if (parentNode != null) {
            var cursorPos = getCursorPosition();
            // 改变了父级关系，重构dom结构
            var parentDom = getNodeContainer(parentNode.id);
            var nodeContainer = getNodeContainer(nodeId);
            parentDom.after(nodeContainer);
            var editor = getContentById(nodeId);
            // 重新设置光标位置
            setCursorPosition(editor, cursorPos);
            var node = this.model.getById(nodeId);
            var eventData = {
                changed: [node],
                cursor: {
                    id: nodeId,
                    position: cursorPos
                }
            };
            this.eventSource.trigger('structureChanged', eventData);
        }
    };
    /**
     * 回退多个node
     * @param nodes 树形的节点结构
     */
    Engine.prototype.outdentNodes = function (nodes) {
        var eventData = {
            changed: []
        };
        // 倒着去执行
        var lastIndex = nodes.length - 1;
        var index = lastIndex;
        while (index >= 0) {
            var node = nodes[index];
            var nodeId = node.id;
            var parentNode = this.model.outdentNode(nodeId);
            if (parentNode != null) {
                // 改变了父级关系，重构dom结构
                var parentDom = getNodeContainer(parentNode.id);
                var nodeContainer = getNodeContainer(nodeId);
                parentDom.after(nodeContainer);
                // 正序的索引，添加事件信息，要正着添加
                var ascIndex = lastIndex - index;
                var ascNode = nodes[ascIndex];
                eventData.changed.push(ascNode);
            }
            index--;
        }
        if (eventData.changed.length > 0) {
            this.eventSource.trigger('structureChanged', eventData);
        }
    };
    /**
     * 移动节点
     * @param nodeId 被移动节点id
     * @param targetId 目标节点id
     * @param type 移动类型，在前还是在后，prev | next
     */
    Engine.prototype.moveNode = function (nodeId, targetId, type) {
        var nodeDom = getNodeContainer(nodeId);
        if (type === 'prev') {
            getNodeContainer(targetId).before(nodeDom);
        }
        else {
            getNodeContainer(targetId).after(nodeDom);
        }
        this.model.moveNode(nodeId, targetId, type);
        focus(getContentById(nodeId));
        var node = this.model.getById(nodeId);
        var eventData = {
            changed: [node]
        };
        this.eventSource.trigger('structureChanged', eventData);
    };
    /**
     * 移动节点
     * @param nodes 被移动的多个节点集合
     * @param targetId 目标节点id
     * @param type 移动类型，在前还是在后，prev | next
     */
    Engine.prototype.moveNodes = function (nodes, targetId, type) {
        var targetContainer = getNodeContainer(targetId);
        if (type === 'prev') {
            var index = 0;
            while (index < nodes.length) {
                var node = nodes[index];
                var nodeDom = getNodeContainer(node.id);
                targetContainer.before(nodeDom);
                index++;
            }
        }
        else {
            // 往后边添加，要倒序添加
            var index = nodes.length - 1;
            while (index >= 0) {
                var node = nodes[index];
                var nodeDom = getNodeContainer(node.id);
                targetContainer.after(nodeDom);
                index--;
            }
        }
        this.model.moveNodes(nodes, targetId, type);
        var eventData = {
            changed: nodes
        };
        this.eventSource.trigger('structureChanged', eventData);
    };
    /**
     * 获取前边节点的id
     * @param nodeId
     */
    Engine.prototype.getPrevNodeId = function (nodeId) {
        var nodeContainer = getNodeContainer(nodeId);
        var result;
        var prev = nodeContainer.prev('.node');
        if (prev.length > 0) {
            result = prev.find('.content:visible:last').data('id');
        }
        else {
            // 没有上一级，就寻找父级
            if (!this.model.isRootNode(nodeId)) {
                var parent_1 = this.model.getParent(nodeId);
                if (parent_1 != null) {
                    result = parent_1.id;
                }
            }
        }
        return result;
    };
    /**
     * 向上一个节点
     * @param nodeId
     * @param isEnd 光标是否跳到最后
     */
    Engine.prototype.toPrevNode = function (nodeId, isEnd) {
        var result;
        var prevNodeId = this.getPrevNodeId(nodeId);
        if (prevNodeId) {
            result = getContentById(prevNodeId);
            if (isEnd) {
                moveCursorEnd(result);
            }
            else {
                var cursorPos = getCursorPosition();
                if (cursorPos.start === 0) {
                    setCursorPosition(result, { start: 0 });
                }
                else {
                    moveCursorEnd(result);
                }
            }
        }
        return result;
    };
    /**
     * 向上移动当前节点
     * @param nodeId 被移动节点的id
     */
    Engine.prototype.moveNodePrev = function (nodeId) {
        var prevNodeId = this.getPrevNodeId(nodeId);
        if (prevNodeId && !this.model.isRootNode(prevNodeId)) {
            this.moveNode(nodeId, prevNodeId, 'prev');
        }
    };
    /**
     * 获取后边节点的id
     * @param nodeId
     * @param ignoreChildren 是否忽略子节点
     * @returns {*}
     */
    Engine.prototype.getNextNodeId = function (nodeId, ignoreChildren) {
        var nodeContainer = getNodeContainer(nodeId);
        var result;
        var next = null;
        if (!ignoreChildren) {
            // 先查找子节点
            next = nodeContainer.find('.node:visible:eq(0)');
        }
        if (next == null || next.length === 0) {
            // 没有子节点了，查找同级
            next = nodeContainer.next('.node:visible');
        }
        if (next == null || next.length > 0) {
            result = next.attr('id');
        }
        else {
            // 向父级一层层查找，每一层父级的下边的相邻节点
            var currentId = nodeId;
            while (true) {
                var parentNode = this.model.getParent(currentId);
                if (parentNode == null) {
                    break;
                }
                var parentContainer = getNodeContainer(parentNode.id);
                next = parentContainer.next('.node');
                if (next.length > 0) {
                    result = next.attr('id');
                    break;
                }
                currentId = parentNode.id;
            }
        }
        return result;
    };
    /**
     * 光标向下一个节点
     * @param nodeId
     * @param ignoreChildren 是否忽略子节点
     */
    Engine.prototype.toNextNode = function (nodeId, ignoreChildren) {
        if (ignoreChildren == null) {
            ignoreChildren = false;
        }
        var nextNodeId = this.getNextNodeId(nodeId, ignoreChildren);
        var result;
        if (nextNodeId) {
            result = getContentById(nextNodeId);
            var cursorPos = getCursorPosition();
            if (cursorPos.start === 0) {
                setCursorPosition(result, { start: 0 });
            }
            else {
                moveCursorEnd(result);
            }
        }
        return result;
    };
    /**
     * 向下移动当前节点
     * @param nodeId 被移动节点的id
     */
    Engine.prototype.moveNodeNext = function (nodeId) {
        var nextNodeId = this.getNextNodeId(nodeId, true);
        if (nextNodeId) {
            var targetId = nextNodeId;
            var moveType = 'next';
            var nextNode = this.model.getById(nextNodeId);
            if (true !== nextNode.collapsed && nextNode.children && nextNode.children.length > 0) {
                // 没有闭合，并且有子节点的话，就在第一个子节点前边
                targetId = nextNode.children[0].id;
                moveType = 'prev';
            }
            this.moveNode(nodeId, targetId, moveType);
        }
    };
    /**
     * 向下移动多个节点
     * @param nodes 多个节点的集合
     */
    Engine.prototype.moveNodesNext = function (nodes) {
        var lastNodeId = nodes[nodes.length - 1].id;
        var nextNodeId = this.getNextNodeId(lastNodeId, true);
        if (nextNodeId) {
            var targetId = nextNodeId;
            var moveType = 'next';
            var nextNode = this.model.getById(nextNodeId);
            if (true !== nextNode.collapsed && nextNode.children && nextNode.children.length > 0) {
                // 没有闭合，并且有子节点的话，就在第一个子节点前边
                targetId = nextNode.children[0].id;
                moveType = 'prev';
            }
            this.moveNodes(nodes, targetId, moveType);
        }
    };
    /**
     * 完成节点
     * @param nodeId
     */
    Engine.prototype.toggleFinishNode = function (nodeId) {
        var node = this.model.getById(nodeId);
        node.finish = (node.finish ? false : true);
        this.model.update(node);
        getNodeContainer(nodeId).toggleClass('finished');
        var eventData = {
            updated: [node]
        };
        this.eventSource.trigger('updated', eventData, { finish: node.finish });
        return node.finish;
    };
    /**
     * 设置多个或一个节点的完成状态
     * @param nodeIds
     * @param value
     */
    Engine.prototype.setFinishNode = function (nodeIds, value) {
        var _this = this;
        if (!jquery__WEBPACK_IMPORTED_MODULE_0___default.a.isArray(nodeIds)) {
            nodeIds = [nodeIds];
        }
        var updated = [];
        jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(nodeIds, function (index, id) {
            var node = _this.model.getById(id);
            node.finish = value;
            _this.model.update(node);
            if (value) {
                getNodeContainer(id).addClass('finished');
            }
            else {
                getNodeContainer(id).removeClass('finished');
            }
            updated.push(node);
        });
        var eventData = {
            updated: updated
        };
        this.eventSource.trigger('updated', eventData, { finish: value });
    };
    /**
     * 闭合展开节点
     * @param nodeId
     */
    Engine.prototype.toggleExpand = function (nodeId) {
        var node = this.model.getById(nodeId);
        if (!node.children || node.children.length === 0) {
            // 没有子节点
            return false;
        }
        node.collapsed = (node.collapsed ? false : true);
        this.model.update(node);
        var container = getNodeContainer(nodeId);
        container.toggleClass('collapsed');
        var eventData = {
            updated: [node]
        };
        this.eventSource.trigger('updated', eventData, { collapsed: node.collapsed });
        return node.collapsed;
    };
    /**
     * 展开收缩全部
     */
    Engine.prototype.toggleExpandAll = function () {
        var _this = this;
        var rootNode = this.model.getRootNode();
        var nodes;
        if (rootNode == null) {
            nodes = this.model.getDefine().nodes;
        }
        else {
            nodes = rootNode.children;
        }
        if (!nodes || nodes.length === 0) {
            return;
        }
        var updated = [];
        var collapsedCount = this.wrapper.find('.node.collapsed').length;
        var collapsedState = (collapsedCount === 0);
        // 有收缩的，就全部展开
        recursive(nodes, function (node) {
            var container = getNodeContainer(node.id);
            if (node.children && node.children.length > 0) {
                if (collapsedCount > 0 && node.collapsed) {
                    // 全部展开
                    node.collapsed = collapsedState;
                    container.removeClass('collapsed');
                }
                if (collapsedCount === 0) {
                    // 全部收缩
                    node.collapsed = collapsedState;
                    container.addClass('collapsed');
                }
                _this.model.update(node);
                updated.push(node);
            }
        });
        var eventData = {
            updated: updated
        };
        this.eventSource.trigger('updated', eventData, { collapsed: collapsedState });
    };
    /**
     * 是否允许设置样式
     * @returns {boolean}
     */
    Engine.prototype.allowNodeStyle = function () {
        return true;
    };
    /**
     * 设置节点属性
     * @param nodeIds
     * @param name 属性名称
     * @param value 属性值
     */
    Engine.prototype.setNodeAttr = function (nodeIds, name, value) {
        var _this = this;
        var me = this;
        if (!me.allowNodeStyle()) {
            return false;
        }
        if (!jquery__WEBPACK_IMPORTED_MODULE_0___default.a.isArray(nodeIds)) {
            nodeIds = [nodeIds];
        }
        var cursorPos = getCursorPosition();
        var updated = [];
        jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(nodeIds, function (index, id) {
            var node = _this.model.getById(id);
            node[name] = value;
            _this.model.update(node);
            me.painter.refreshNode(node);
            updated.push(node);
        });
        var eventData = {
            updated: updated
        };
        if (nodeIds.length === 1) {
            // 在ios下需要重置光标
            try {
                var editor = getContentById(nodeIds[0]);
                setCursorPosition(editor, cursorPos);
            }
            catch (e) {
                // ignore
            }
        }
        var extendData = {};
        extendData[name] = value;
        this.eventSource.trigger('updated', eventData, extendData);
        return true;
    };
    /**
     * 更新文本
     * @param nodeId
     * @param text
     * @param type note | text
     */
    Engine.prototype.updateText = function (nodeId, text, type) {
        var node = this.model.getById(nodeId);
        if (node != null) {
            var updateData = {};
            if (type === 'note') {
                node.note = text;
                updateData.note = text;
            }
            else {
                node.text = text;
                updateData.text = text;
            }
            this.model.update(node);
            var eventData = {
                updated: [node]
            };
            this.eventSource.trigger('updateText', eventData, updateData);
        }
    };
    /**
     * 钻取节点
     * @param nodeId
     * @param withoutEvent 不抛出事件
     */
    Engine.prototype.drillNode = function (nodeId, withoutEvent) {
        if (nodeId) {
            var targetNode = this.model.getById(nodeId);
            if (!targetNode) {
                // 目标节点不存在，不能执行drill
                return;
            }
        }
        if (this.model.getRootNode() != null && nodeId === this.model.getRootNode().id) {
            // 相同，不执行
            return;
        }
        var eventData = {
            from: this.model.getRootNode() ? this.model.getRootNode().id : null,
            to: nodeId ? nodeId : null
        };
        var me = this;
        this.model.setRootNode(nodeId);
        me.painter.renderPaper();
        this.refreshDrillDir();
        if (!withoutEvent) {
            this.eventSource.trigger('drilled', eventData);
        }
        if (!environment.isMobile) {
            var scrollable = this.scrollContainer;
            var currentTop = scrollable.scrollTop() || 0;
            var paperTop = me.paper.position().top;
            if (currentTop > paperTop) {
                scrollable.scrollTop(paperTop);
            }
        }
        else {
            this.scrollContainer.scrollTop(0);
        }
    };
    /**
     * 刷新进入节点后的导航
     */
    Engine.prototype.refreshDrillDir = function () {
        var me = this;
        var rootNode = me.getRootNode();
        var dirContainer = this.viewport.dir;
        if (rootNode == null) {
            dirContainer.hide();
            this.viewport.nameContainer.show();
        }
        else {
            var dirDom = this.viewport.dir;
            dirDom.show();
            this.viewport.nameContainer.hide();
            var dir = this.model.getDir();
            dirDom.empty().append("<span class=\"item\">" + t('mindnote.editor.home') + "</span><span class=\"arrow\"></span>");
            for (var i = 0; i < dir.length; i++) {
                var item = dir[i];
                var dirItem = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<span class="item">' + htmlToText(item.text) + '</span>').appendTo(dirDom);
                dirItem.data('node-id', item.id);
                dirDom.append('<span class="arrow"></span>');
            }
        }
        dirContainer.off().on('click', '.item', function (clickEvent) {
            clickEvent.preventDefault();
            var item = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            var nodeId = item.data('node-id');
            me.drillNode(nodeId, false);
        });
    };
    /**
     * 向后钻取
     */
    Engine.prototype.backDrillNode = function () {
        var rootNode = this.model.getRootNode();
        if (rootNode != null) {
            var currentRootId = rootNode.id;
            var nodeId = null;
            var dir = this.model.getDir();
            if (dir.length > 0) {
                nodeId = dir[dir.length - 1].id;
            }
            this.drillNode(nodeId, false);
            moveCursorEnd(getContentById(currentRootId));
        }
    };
    /**
     * 获取根节点
     * @returns {null|*}
     */
    Engine.prototype.getRootNode = function () {
        return this.model.getRootNode();
    };
    /**
     * 设置标题
     * @param {string} name
     */
    Engine.prototype.setName = function (name) {
        this.model.setName(name);
        this.viewport.nameContainer.find('input').val(name);
        // $('.doc-name').text(name);
    };
    /**
     * 编辑标题
     * @param name
     */
    Engine.prototype.editName = function (name) {
        var action = {
            name: 'nameChanged',
            original: this.model.getName(),
            title: name,
        };
        this.model.setName(name);
        jquery__WEBPACK_IMPORTED_MODULE_0___default()('.doc-name').text(name);
        this.eventSource.trigger('nameChanged', action);
    };
    /**
     * 提供给UI获取文档标题
     * @returns {string}
     */
    Engine.prototype.getName = function () {
        return this.model.getName();
    };
    /**
     * 获取文档定义
     */
    Engine.prototype.getDocumentDefine = function () {
        return this.model.getDefine();
    };
    /**
     * 设置文档的配置
     */
    Engine.prototype.setSetting = function (name, value) {
        var changeData = {
            changed: {},
            original: {}
        };
        changeData.changed[name] = value;
        changeData.original[name] = this.model.getDefine()[name];
        this.model.setSetting(name, value);
        this.eventSource.trigger('settingChanged', changeData);
    };
    /**
     * 插入图片
     * @param nodeId
     * @param image
     */
    Engine.prototype.insertImage = function (nodeId, image) {
        var me = this;
        var updated = [];
        var node = this.model.getById(nodeId);
        if (!node) {
            return false;
        }
        if (!node.images) {
            node.images = [];
        }
        if (!image.id) {
            image.id = newId(this.model.getModelId());
        }
        node.images.push(image);
        this.model.update(node);
        this.imageUploading.remove(image.id);
        me.painter.refreshNode(node);
        updated.push(node);
        var eventData = {
            updated: updated
        };
        this.eventSource.trigger('updated', eventData, { images: node.images });
    };
    /**
     * 插入上传中的图片，不会触发保存
     * @param nodeId
     * @param image
     */
    Engine.prototype.insertUploadingImage = function (nodeId, image) {
        image = Object(lodash_es__WEBPACK_IMPORTED_MODULE_2__["default"])(image);
        // 标识正在上传中
        image.uploading = true;
        if (!image.id) {
            image.id = newId(this.model.getModelId());
        }
        this.imageUploading.add(nodeId, image);
        var node = this.model.getById(nodeId);
        // 刷新节点，会绘制出正在上传中的图片
        this.painter.refreshNode(node);
    };
    /**
     * 删除正在上传中的图片，用于上传失败后
     * @param imageId
     */
    Engine.prototype.removeUploadingImage = function (imageId) {
        var nodeId = this.imageUploading.remove(imageId);
        if (nodeId) {
            var node = this.model.getById(nodeId);
            // 刷新节点，会绘制出正在上传中的图片
            this.painter.refreshNode(node);
        }
    };
    /**
     * 缩放某个图片
     * @param nodeId
     * @param imageIndex
     * @param width
     */
    Engine.prototype.resizeImage = function (nodeId, imageIndex, width) {
        var updated = [];
        var node = this.model.getById(nodeId);
        if (!node || !node.images || node.images.length <= imageIndex) {
            return false;
        }
        node.images[imageIndex].w = width;
        this.model.update(node);
        updated.push(node);
        var eventData = {
            updated: updated
        };
        this.eventSource.trigger('updated', eventData, { images: node.images });
    };
    /**
     * 删除图片
     * @param nodeId
     * @param imageId
     */
    Engine.prototype.removeImageById = function (nodeId, imageId) {
        var node = this.model.getById(nodeId);
        if (node.images && node.images.length > 0) {
            var i = 0;
            while (i < node.images.length) {
                var img = node.images[i];
                if (img.id === imageId) {
                    this.removeImage(nodeId, i);
                    i++;
                    return;
                }
            }
        }
    };
    /**
     * 删除图片
     * @param nodeId
     * @param imageIndex
     */
    Engine.prototype.removeImage = function (nodeId, imageIndex) {
        var updated = [];
        var node = this.model.getById(nodeId);
        if (!node || !node.images || node.images.length <= imageIndex) {
            return false;
        }
        node.images.splice(imageIndex, 1);
        this.model.update(node);
        this.painter.refreshNode(node);
        updated.push(node);
        var eventData = {
            updated: updated
        };
        this.eventSource.trigger('updated', eventData, { images: node.images });
    };
    /**
     * 节点是否可以缩进或回退
     * @param nodeId
     * @param type indent 或者 outdent
     */
    Engine.prototype.canIndent = function (nodeId, type) {
        if (type === 'indent') {
            var index = this.model.getNodeIndex(nodeId);
            return index > 0;
        }
        else {
            if (this.model.isRootSubNode(nodeId)) {
                // 是根节点，不能回退
                return false;
            }
            var parent_2 = this.model.getParent(nodeId);
            return parent_2 != null;
        }
    };
    /**
     * 设置只读状态
     * @param readonly
     */
    Engine.prototype.setReadOnly = function (readonly) {
        // 将只读状态保存在全局state中，
        // 很多操作也会根据此状态来进行控制
        // 包括圆点菜单，多选后的菜单，wrapper的加号控制（新建第一个节点），全局设置（思维导图），撤销恢复，相关快捷键操作
        this.state.readonly = readonly;
        var editableProp = 'contenteditable';
        var paper = this.paper;
        var undoRedoButtons = jquery__WEBPACK_IMPORTED_MODULE_0___default()('.action-undo, .action-redo');
        var nameInput = this.viewport.nameContainer.find('input');
        if (readonly) {
            // 只读
            paper.find('div[' + editableProp + ']').removeAttr(editableProp);
            nameInput.attr('readonly', 'readonly');
            jquery__WEBPACK_IMPORTED_MODULE_0___default()('.menu-container').hide(); // 让所有菜单隐藏
            undoRedoButtons.hide(); // 隐藏撤销恢复
            paper.addClass('readonly'); // 目的是让note可以自动收缩
            this.viewport.controlHolder.find('.mind-item-readonly-hide').hide();
        }
        else {
            // 激活所有输入框
            paper.find('.content').attr(editableProp, 'true');
            paper.find('.note').attr(editableProp, 'true');
            nameInput.removeAttr('readonly');
            undoRedoButtons.show(); // 显示撤销恢复
            paper.removeClass('readonly'); // 目的是让note可以自动收缩
            this.viewport.controlHolder.find('.mind-item-readonly-hide').show();
        }
        // TODO 如果当前正在查看分享窗口，要关闭
        // $('#share-dlg').dlg('close');
        this.eventSource.trigger('editorStateChanged');
    };
    Engine.prototype.getReadOnly = function () {
        return this.state.readonly;
    };
    /**
     * 发出预览图片的消息
     * @param {string} nodeId
     * @param {string} imageId
     */
    Engine.prototype.previewImage = function (nodeId, imageId) {
        var nodes = this.model.getDefine().nodes;
        var data = {
            index: 0,
            imageList: []
        };
        var totalIndex = 0;
        recursive(nodes, function (node) {
            if (node.images) {
                Object(lodash_es__WEBPACK_IMPORTED_MODULE_5__["default"])(node.images, function (img) {
                    if (node.id === nodeId && img.id === imageId) {
                        data.index = totalIndex;
                    }
                    data.imageList.push(img);
                    totalIndex++;
                });
            }
        });
        this.eventSource.trigger(SourceEvent.PREVIEW_IMAGE, data);
    };
    /**
     * 管理画布
     */
    Engine.prototype.manageWrapper = function () {
        var nodes = this.wrapper.find('.node:not(.root-node)');
        this.wrapper.find('.mindnote-placeholder').remove();
        this.wrapper.off('click.firstNode');
        var engine = this;
        if (nodes.length === 0 && !this.state.readonly) {
            this.wrapper.append('<span class="mindnote-placeholder">' + this.state.getEditorProps().contentPlaceholder + '</span>');
            this.wrapper.on('click.firstNode', function (e) {
                // 在根节点的主题或标题上点击，不生效
                var target = jquery__WEBPACK_IMPORTED_MODULE_0___default()(e.target);
                if (target.hasClass('content') || target.hasClass('note')) {
                    return;
                }
                target = target.parent();
                if (target.hasClass('content') || target.hasClass('note')) {
                    return;
                }
                engine.createRootNext();
            });
        }
        var nodeCountLabel = jquery__WEBPACK_IMPORTED_MODULE_0___default()('#node-count-text');
        if (nodeCountLabel.length > 0) {
            nodeCountLabel.text(Object.keys(this.model.getMapping()).length);
        }
    };
    return Engine;
}());

/**
 * 是否有子节点
 * @param nodeId
 * @returns {boolean}
 */
function hasChildren$1(nodeId) {
    return jquery__WEBPACK_IMPORTED_MODULE_0___default()('#' + nodeId).children('.children').children('.node').length > 0;
}
/**
 * 获取第一个子节点
 * @param nodeId
 */
function getFirstChild(nodeId) {
    return jquery__WEBPACK_IMPORTED_MODULE_0___default()('#' + nodeId).children('.children').children('.node:eq(0)');
}

var EditorOperate = /** @class */ (function () {
    function EditorOperate(editorUI, selector, engine, textEditor, state, imageEditor, viewport, eventSource, model) {
        this.editorUI = editorUI;
        this.engine = engine;
        this.textEditor = textEditor;
        this.selector = selector;
        this.state = state;
        this.imageEditor = imageEditor;
        this.viewport = viewport;
        this.eventSource = eventSource;
        this.model = model;
    }
    EditorOperate.prototype.init = function () {
        this.initDocument();
        this.initNameEdit();
        this.initTextEdit();
        this.initHotKey();
        this.initSwipeIndent();
    };
    /**
     * 初始化文本编辑
     */
    EditorOperate.prototype.initTextEdit = function () {
        var _this = this;
        // 初始化文本编辑
        this.textEditor.init({
            // input
            onPopAction: function (action) {
                var nodeSet = _this.model.getMappingById(action.id);
                if (nodeSet) {
                    var inputAction = __assign({}, action, { path: nodeSet.path });
                    _this.eventSource.trigger(SourceEvent.DOC_CHANGED, [inputAction]);
                }
            },
            onChange: function (nodeId, text, editType) {
                _this.engine.updateText(nodeId, text, editType);
            },
            onPasteMultiNodes: function (targetId, nodes) {
                _this.engine.appendNextNodes(targetId, nodes);
            }
        });
    };
    /**
     * 初始化文档
     */
    EditorOperate.prototype.initDocument = function () {
        var me = this;
        jquery__WEBPACK_IMPORTED_MODULE_0___default()(document).on('mousedown.mindnote-global', function (e) {
            me.selector.cancel(e.target);
        });
    };
    /**
     * 编辑标题
     */
    EditorOperate.prototype.initNameEdit = function () {
        var enterDownValue;
        var me = this;
        this.viewport.nameContainer.find('input').on('input propertychange', function () {
            var name = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).val();
            if (jquery__WEBPACK_IMPORTED_MODULE_0___default.a.trim(name) === '') {
                name = '';
            }
            if (name === me.engine.getName()) {
                return;
            }
            me.engine.editName(name);
        }).on('focus', function () {
            if (jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).val() === '') {
                jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).val('');
            }
        }).on('keydown', function (e) {
            if (e.keyCode === 13) {
                // 记录回车按下的值
                enterDownValue = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).val() || '';
            }
        }).on('keyup', function (e) {
            if (e.keyCode === 40 || (e.keyCode === 13 && jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).val() === enterDownValue)) {
                // 如果回车抬起和回车按下的值是一样的，才执行，因为在输入法状态，回车是直接输入英文
                // 不能直接使用keydown事件来处理，因为focus子元素后，会出现换行
                var paper = me.viewport.paper;
                var firstContent = paper.find('.content:first');
                if (firstContent.length === 0) {
                    // 没有主题，回车，创建第一个节点
                    me.engine.createRootNext();
                }
                else {
                    // 有主题，让第一个主题focus
                    moveCursorEnd(firstContent);
                }
            }
        });
    };
    /**
     * 初始化快捷键
     */
    EditorOperate.prototype.initHotKey = function () {
        var paper = this.viewport.paper;
        var metaKey = environment.metaKey;
        var me = this;
        // 快捷键相关
        paper.on('keydown.content', '.content', function (e) {
            if (me.state.readonly) {
                return;
            }
            var content = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            var id = content.data('id');
            var container = getNodeContainer(id);
            var code = e.keyCode;
            var cursorPosition = null;
            if (code === 13) {
                e.preventDefault();
                if (e[metaKey]) {
                    // 按了command或者ctrl，完成节点
                    var finished = me.engine.toggleFinishNode(id);
                    if (finished) {
                        me.engine.toNextNode(id, false);
                    }
                }
                else if (e.shiftKey) {
                    // Shift + Enter, 编辑备注
                    me.editorUI.editNote(id);
                }
                else if (e.altKey) {
                    // alt + 回车 插入图片
                    me.imageEditor.insert(id);
                }
                else {
                    // Enter, 增加同级
                    me.editorUI.createNext(id);
                }
            }
            else if (code === 46) {
                // delete向右删除，如果光标到了当前行的最后边，删除下一个节点
                cursorPosition = getCursorPosition();
                if (cursorPosition.start === cursorPosition.end
                    && cursorPosition.end === content.text().length) {
                    var nextNode = container.next('.node');
                    if (nextNode.length > 0) {
                        e.preventDefault();
                        var nextId = nextNode.attr('id');
                        if (!hasChildren$1(nextId)) ;
                    }
                }
            }
            else if (code === 8) {
                if (e[metaKey] && e.shiftKey) {
                    e.preventDefault();
                    me.engine.deleteNodeDirectly(id);
                    return;
                }
                // Backspace, 删除
                if (hasChildren$1(id) || container.hasClass('root-node')) {
                    // 有子节点，或者是根节点，不能删
                    return;
                }
                cursorPosition = getCursorPosition();
                if (content.text() === '' || (cursorPosition.start === 0 && cursorPosition.end === 0)) {
                    e.preventDefault();
                    // 没内容，直接删除
                    me.editorUI.deleteNode(id);
                }
            }
            else if (code === 9) {
                e.preventDefault();
                if (e.shiftKey) {
                    // shift + Tab，回退
                    me.engine.outdentNode(id);
                }
                else {
                    // Tab, 缩进一级
                    me.engine.indentNode(id);
                }
            }
            else if (code === 37 && !e.metaKey && !e.ctrlKey && !e.shiftKey) {
                // 向左，如果光标到了当前行的最前边，则移动到上一节点的最后边
                cursorPosition = getCursorPosition().start;
                if (cursorPosition === 0) {
                    var preNodeContent = me.engine.toPrevNode(id, false);
                    if (preNodeContent) {
                        moveCursorEnd(preNodeContent);
                        e.preventDefault();
                    }
                }
            }
            else if (code === 38) {
                if (e.shiftKey && e[metaKey]) {
                    // cmd + shift + 向上，向上移动节点
                    e.preventDefault();
                    me.engine.moveNodePrev(id);
                }
                else if (!e.shiftKey) {
                    // 光标向上
                    if ((content.height() || 0) > parseInt(content.css('line-height'))) {
                        // 有多行的情况，光标在前边，才向上
                        cursorPosition = getCursorPosition().start;
                        if (cursorPosition !== 0) {
                            return;
                        }
                    }
                    e.preventDefault();
                    me.engine.toPrevNode(id, false);
                }
            }
            else if (code === 39 && !e.metaKey && !e.ctrlKey && !e.shiftKey) {
                // 向右，如果光标到了当前行的最后边，则移动到下一节点的最前边
                cursorPosition = getCursorPosition();
                if (cursorPosition.start === cursorPosition.end
                    && cursorPosition.end === content.text().length) {
                    var nextNodeContent = me.engine.toNextNode(id, false);
                    if (nextNodeContent) {
                        setCursorPosition(nextNodeContent, { start: 0 });
                        e.preventDefault();
                    }
                }
            }
            else if (code === 40) {
                if (e.shiftKey && e[metaKey]) {
                    // cmd + shift + 向下，向下移动节点
                    e.preventDefault();
                    me.engine.moveNodeNext(id);
                }
                else if (!e.shiftKey) {
                    // 光标向下
                    if ((content.height() || 0) > parseInt(content.css('line-height'))) {
                        // 有多行的情况，光标在最后，才向下
                        cursorPosition = getCursorPosition().end;
                        if (cursorPosition < content.text().length) {
                            return;
                        }
                    }
                    e.preventDefault();
                    me.engine.toNextNode(id, false);
                }
            }
            else if (code === 68 && e[metaKey]) {
                // cmd + d 复用
                e.preventDefault();
                me.engine.copyNode(id);
            }
            else if (code === 221 && e[metaKey]) {
                e.preventDefault();
                // cmd + ] 钻取
                me.engine.drillNode(id, false);
            }
            else if (code === 219 && e[metaKey]) {
                e.preventDefault();
                // cmd + [ 返回一级
                me.engine.backDrillNode();
            }
            else if ((code === 190 || code === 110) && (e.metaKey || e.altKey) && !e.shiftKey) {
                // cmd + . 展开、收缩，110是小键盘
                // windows下是alt + .
                // 在windows10下，按键码竟然是229
                e.preventDefault();
                me.engine.toggleExpand(id);
            }
            else if (code >= 49 && code <= 52 && e.altKey) {
                // cmd + shift + 1 2 3 4，设置标题样式
                e.preventDefault();
                var heading = code - 48;
                if (heading >= 4) {
                    heading = 0;
                }
                me.engine.setNodeAttr(id, 'heading', heading);
            }
            else if (code >= 97 && code <= 100 && e.altKey) {
                // cmd + shift + （小键盘）1 2 3 4，设置标题样式
                e.preventDefault();
                var heading = code - 96;
                if (heading >= 4) {
                    heading = 0;
                }
                me.engine.setNodeAttr(id, 'heading', heading);
            }
            // else if (code === 68 && e.altKey) {
            // 	e.preventDefault();
            // 	me.engine.setNodeAttr(id, 'color', '#333333');
            // } else if (code === 82 && e.altKey) {
            // 	e.preventDefault();
            // 	me.engine.setNodeAttr(id, 'color', '#dc2d1e');
            // } else if (code === 89 && e.altKey) {
            // 	e.preventDefault();
            // 	me.engine.setNodeAttr(id, 'color', '#ffaf38');
            // } else if (code === 71 && e.altKey) {
            // 	e.preventDefault();
            // 	me.engine.setNodeAttr(id, 'color', '#75c940');
            // } else if (code === 66 && e.altKey) {
            // 	e.preventDefault();
            // 	me.engine.setNodeAttr(id, 'color', '#3da8f5');
            // } else if (code === 80 && e.altKey) {
            // 	e.preventDefault();
            // 	me.engine.setNodeAttr(id, 'color', '#797ec9');
            // }
        });
        // 全局快捷键，绑定到document上
        jquery__WEBPACK_IMPORTED_MODULE_0___default()(document).on('keydown.mindnote-hotkey', function (e) {
            var code = e.keyCode;
            var target = jquery__WEBPACK_IMPORTED_MODULE_0___default()(e.target);
            var targetIsInput = target.is('input') || target.is('textarea');
            if (code === 83 && e[metaKey]) {
                // 阻止cmd + s保存网页
                e.preventDefault();
            }
            else if (code === 191 && e[metaKey]) {
                // cmd + ? 打开快捷键
                // Dock.toggle();
                e.preventDefault();
            }
            else if ((code === 190 || code === 110) && (e.metaKey || e.altKey) && e.shiftKey) {
                // cmd + shift + . 展开、收缩全部
                // 在windows10下，alt + shift + .
                me.engine.toggleExpandAll();
                e.preventDefault();
            }
            else if (e.keyCode === 8) {
                // 回退
                if (!targetIsInput && !target.is('.content, .note')) {
                    e.preventDefault();
                }
            }
            else if (e.keyCode === 27) {
                // esc 取消选择
                me.selector.cancel();
            }
        });
        // 在编辑备注时的特殊快捷键
        paper.on('keydown.hotkey_note', '.note', function (e) {
            if (me.state.readonly) {
                return;
            }
            var note = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            var id = note.parent().attr('id') || '';
            var code = e.keyCode;
            var targetContent;
            var cursorPosition;
            if (code === 38) {
                cursorPosition = getCursorPosition().start;
                if (cursorPosition === 0) {
                    e.preventDefault();
                    // 向上，让节点选中
                    getContentById(id).focus();
                }
            }
            else if (code === 40) {
                cursorPosition = getCursorPosition().end;
                if (cursorPosition >= note.text().length) {
                    e.preventDefault();
                    // 向下
                    me.engine.toNextNode(id, false);
                }
            }
            else if (code === 8) {
                // Backspace, 删除
                var value = htmlToText(note.text());
                if (value === '') {
                    e.preventDefault();
                    // 没文本才可以删除
                    me.engine.updateText(id, '', 'note');
                    targetContent = getContentById(id);
                    moveCursorEnd(targetContent);
                    // 不需要删除他，因为会触发他的blur，会对他进行删除
                    if (note.length > 0) {
                        note.remove();
                    }
                }
            }
            else if (code === 13 && e.shiftKey) {
                // shift + enter, 返回节点
                e.preventDefault();
                var content = getContentById(id);
                moveCursorEnd(content);
            }
        });
    };
    /**
     * 通过滑动来修改缩进
     */
    EditorOperate.prototype.initSwipeIndent = function () {
        if (!environment.isMobile) {
            return;
        }
        var activeDistance = 40;
        var activeDistanceV = 15;
        var paper = this.viewport.paper;
        var me = this;
        // 快捷键相关
        paper.on(environment.downEvent + '.swipe', '.content', function (downE) {
            if (me.state.readonly) {
                return;
            }
            var target = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            var targetId = target.data('id');
            var downPosEvent = downE;
            if (downE.originalEvent.touches) {
                // 移动端的拖动
                downPosEvent = downE.originalEvent.touches[0];
            }
            paper.on(environment.moveEvent + '.swipe', function (moveE) {
                var movePosEvent = moveE;
                if (moveE.originalEvent.touches) {
                    // 移动端的拖动
                    movePosEvent = moveE.originalEvent.touches[0];
                }
                if (Math.abs(movePosEvent.pageY - downPosEvent.pageY) < activeDistanceV
                    && Math.abs(movePosEvent.pageX - downPosEvent.pageX) > activeDistance) {
                    // 达到执行范围，执行
                    if (movePosEvent.pageX < downPosEvent.pageX) {
                        me.engine.outdentNode(targetId);
                    }
                    else {
                        me.engine.indentNode(targetId);
                    }
                    paper.trigger(environment.upEvent + '.swipe');
                }
            });
            paper.on(environment.upEvent + '.swipe', function (upE) {
                paper.off(environment.moveEvent + '.swipe');
                paper.off(environment.upEvent + '.swipe');
            });
        });
    };
    return EditorOperate;
}());

function tooltip($node) {
    return function (options) {
        var defaults = {
            position: 'bottom',
            pointTo: null // 指向哪个元素
        };
        options = __assign({}, defaults, options);
        jquery__WEBPACK_IMPORTED_MODULE_0___default()($node).each(function () {
            var item = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            item.data('title', item.attr('title') || '');
            item.removeAttr('title');
            var eName = 'mouseenter.tooltip';
            item.off(eName).on(eName, function () {
                var target = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
                if (!target.data('title') || target.hasClass('active')) {
                    // 没有标题，后去处于某种激活状态，取消
                    return;
                }
                var timeout = setTimeout(function () {
                    jquery__WEBPACK_IMPORTED_MODULE_0___default()('.common-tip').remove();
                    var tipBox = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="common-tip"></div>').appendTo('body');
                    tipBox.addClass(options.position);
                    tipBox.text(target.data('title'));
                    tipBox.show();
                    var pointTo = options.pointTo || target;
                    if (options.position === 'right') {
                        tipBox.css({
                            left: pointTo.offset().left + pointTo.outerWidth() + 6,
                            top: pointTo.offset().top - (jquery__WEBPACK_IMPORTED_MODULE_0___default()(document).scrollTop() || 0) + pointTo.outerHeight() / 2 - (tipBox.outerHeight() || 0) / 2
                        });
                    }
                    else {
                        tipBox.css({
                            left: pointTo.offset().left + pointTo.outerWidth() / 2 - (tipBox.outerWidth() || 0) / 2,
                            top: pointTo.offset().top - (jquery__WEBPACK_IMPORTED_MODULE_0___default()(document).scrollTop() || 0) + pointTo.outerHeight() + 6
                        });
                    }
                }, 300);
                target.off('mouseleave.tooltip').on('mouseleave.tooltip', function () {
                    jquery__WEBPACK_IMPORTED_MODULE_0___default()('.common-tip').remove();
                    clearTimeout(timeout);
                });
                target.off('mousedown.tooltip').on('mousedown.tooltip', function () {
                    jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).trigger('mouseleave.tooltip');
                });
            });
        });
    };
}

var Dragger = /** @class */ (function () {
    function Dragger(model, engine, selector, viewport, state) {
        this.autoScrollTimer = null;
        this.autoScrollStep = 7;
        this.autoScrollSpeed = 25;
        // 边界的偏移量
        this.boundaryOffset = 50;
        this.model = model;
        this.engine = engine;
        this.selector = selector;
        this.paper = viewport.paper;
        this.scroller = viewport.scrollContainer;
        this.viewport = viewport;
        this.state = state;
    }
    /**
     * 重置拖动
     */
    Dragger.prototype.resetDrag = function () {
        this.selectedNodes = null;
        this.special = {};
        this.dragControl = null;
        this.dragWrapper = null;
        this.dragCount = 0;
        this.dropPosition = [];
        this.dropResult = null;
    };
    Dragger.prototype.addToSpecial = function (nodeId, key, value) {
        if (!this.special[nodeId]) {
            this.special[nodeId] = {};
        }
        var nodeSpecial = this.special[nodeId];
        nodeSpecial[key] = value;
    };
    /**
     * 设置一些节点的特例情况
     */
    Dragger.prototype.setSpecial = function () {
        var _this = this;
        // 递归处理，所有被选中的节点都排除
        recursive(this.selectedNodes, function (node) {
            _this.dragCount++;
            _this.addToSpecial(node.id, 'exclude', true);
        });
        var firstContainer = getNodeContainer(this.selectedNodes[0].id);
        var lastContainer = getNodeContainer(this.selectedNodes[this.selectedNodes.length - 1].id);
        // 相邻的后边节点不响应prev
        var nextNode = lastContainer.next('.node');
        if (nextNode.length) {
            var nextId = nextNode.attr('id');
            this.addToSpecial(nextId, 'excludePrev', true);
        }
        // 相邻的其那边节点，不响应next
        var prevNode = firstContainer.prev('.node');
        if (prevNode.length > 0) {
            var prevId = prevNode.attr('id');
            this.prevNodeId = prevId;
            if (!hasChildren$1(prevId) || prevNode.hasClass('collapsed')) {
                // 上边的节点，没有子节点，不可以响应next
                prevId = prevNode.attr('id');
                this.addToSpecial(prevId, 'excludeNext', true);
            }
        }
        // 如果是第一个子节点，那他的父节点也不能响应next
        if (prevNode.length === 0 && firstContainer.parent().is('.children')) {
            var parentNode = firstContainer.parent().parent();
            var parentId = parentNode.attr('id');
            this.addToSpecial(parentId, 'excludeNext', true);
        }
        var rootNode = this.engine.getRootNode();
        if (rootNode) {
            this.addToSpecial(rootNode.id, 'excludePrev', true);
            this.addToSpecial(rootNode.id, 'excludeNext', true);
        }
    };
    /**
     * 每次拖动，初始化相关组件
     */
    Dragger.prototype.initControls = function () {
        // 开始构建相关的dom
        this.dragControl = this.viewport.controlHolder.find('.mindnote-drag-control');
        this.dragWrapper = this.viewport.controlHolder.find('.mindnote-bullet-drag-wrapper');
        if (this.dragControl.length === 0) {
            this.dragControl = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="mindnote-drag-control"></div>').appendTo(this.viewport.controlHolder);
            this.dragWrapper = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="mindnote-bullet-drag-wrapper"><div class="bullet"></div></div>').appendTo(this.dragControl);
            // 添加一个遮罩，阻止拖动过程中，会选择文字
            jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div id="bullet-drag-mask"></div>').appendTo(this.dragControl);
        }
        // 添加多个圆点，最多4个
        this.dragWrapper.children('.children').remove();
        var bulletIndex = 1;
        while (bulletIndex < this.dragCount && bulletIndex <= 4) {
            var bullet = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="bullet children"></div>').appendTo(this.dragWrapper);
            bulletIndex++;
            bullet.css({
                'z-index': -bulletIndex,
                'opacity': 1 - bulletIndex * 0.18
            });
        }
        jquery__WEBPACK_IMPORTED_MODULE_0___default()('.menu-container').hide();
        this.dragControl.show();
        jquery__WEBPACK_IMPORTED_MODULE_0___default()('.mindnote-drop-line').remove();
    };
    /**
     * 初始化所有可以放置节点的坐标
     */
    Dragger.prototype.initDropPosition = function () {
        var scrollerTop = this.scroller.scrollTop() || 0;
        var me = this;
        this.paper.find('.node:visible').each(function () {
            var nodeDom = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            var nodeId = nodeDom.attr('id');
            var content = getContentById(nodeId);
            var nodeSpecial = me.special[nodeId];
            if (!(nodeSpecial && nodeSpecial.exclude)) {
                // 在滚动条为0的情况下的绝对坐标
                var nodeOffset = content.offset();
                var nodeTop = nodeOffset.top;
                nodeTop += scrollerTop;
                var nodeHeight = content.outerHeight();
                var imageList = nodeDom.children('.attach-image-list');
                if (imageList.length) {
                    nodeHeight += imageList.outerHeight();
                }
                var noteEditor = nodeDom.children('.note');
                if (noteEditor.length) {
                    nodeHeight += noteEditor.outerHeight();
                }
                var nodeHalf = nodeHeight / 2;
                if (!nodeSpecial || !nodeSpecial.excludePrev) {
                    // 没有排除上级
                    var prevPosition = {
                        id: nodeId,
                        y: nodeTop,
                        h: nodeHalf,
                        type: 'prev'
                    };
                    me.dropPosition.push(prevPosition);
                }
                if (!nodeSpecial || !nodeSpecial.excludeNext) {
                    // 没有排除下级
                    var pos = {
                        id: nodeId,
                        y: nodeTop + nodeHalf,
                        h: nodeHalf,
                        type: 'next'
                    };
                    me.dropPosition.push(pos);
                    // 如果有子节点，那么再构建一个响应，响应可以放在这个节点的后边，位置在children元素最下边
                    if (hasChildren$1(nodeId) && nodeId !== me.prevNodeId) {
                        var childPos = {
                            id: nodeId,
                            y: nodeTop + nodeDom.height() - 4,
                            h: 4,
                            type: 'next',
                            afterChildren: true
                        };
                        me.dropPosition.push(childPos);
                    }
                }
            }
        });
    };
    /**
     * 通过鼠标的Y坐标，查找可以放置的位置
     * @param currentY
     */
    Dragger.prototype.findDrop = function (currentY) {
        currentY += this.scroller.scrollTop();
        var result = null;
        jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(this.dropPosition, function (index, pos) {
            if (currentY >= pos.y && currentY < pos.y + pos.h) {
                result = pos;
                // break;
                return false;
            }
        });
        jquery__WEBPACK_IMPORTED_MODULE_0___default()('.mindnote-drop-line').remove();
        if (result) {
            var targetNodeDom = getNodeContainer(result.id);
            var lineWidth = (targetNodeDom.width() || 0) - 14;
            var targetOffset = targetNodeDom.offset();
            var left = targetOffset.left + 14;
            var top_1;
            if (result.afterChildren) {
                top_1 = result.y + result.h - 1;
            }
            else if (result.type === 'prev') {
                top_1 = result.y - 1;
            }
            else {
                top_1 = result.y + result.h - 1;
                if (hasChildren$1(result.id) && !targetNodeDom.hasClass('collapsed')) {
                    // 在这个节点的下边，并且有子节点，那就放到他第一个子节点
                    var firstChild = getFirstChild(result.id);
                    result = {
                        type: 'prev',
                        id: firstChild.attr('id')
                    };
                    lineWidth -= 31;
                    left += 31;
                }
            }
            var dropLine = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="mindnote-drop-line"></div>').appendTo(this.dragControl);
            dropLine.css({
                'width': lineWidth,
                'top': top_1 - (this.scroller.scrollTop() || 0),
                'left': left
            });
        }
        this.dropResult = result;
    };
    /**
     * 设置拖动时的样式
     */
    Dragger.prototype.setDragStyle = function () {
        this.selectedNodes = this.selector.getNodes();
        if (this.selectedNodes.length === 0) {
            // 没有发生选择的情况下，视当前拖动的元素为选择元素
            var sourceNode = this.model.getById(this.sourceId);
            this.selectedNodes = [sourceNode];
            // 加深背景色
            getNodeContainer(this.sourceId).addClass('node-dragging');
        }
    };
    Dragger.prototype.clearDragStyle = function () {
        jquery__WEBPACK_IMPORTED_MODULE_0___default()('.node-dragging').removeClass('node-dragging mobile-active');
    };
    /**
     * 拖动时开始初始化
     */
    Dragger.prototype.initDrag = function () {
        this.setDragStyle();
        // 设置特例
        this.setSpecial();
        this.initControls();
        this.initDropPosition();
    };
    /**
     * 初始化拖动
     */
    Dragger.prototype.init = function () {
        var me = this;
        /**
         * 开始拖动
         * @param downE
         * @param source
         */
        function beginDrag(downE, source) {
            if (downE.button === 2) {
                // 按的右键，不处理
                return;
            }
            me.resetDrag();
            var downPosEvent = downE;
            if (downE.originalEvent.touches) {
                // 移动端的拖动
                downPosEvent = downE.originalEvent.touches[0];
            }
            var offset = {
                x: downPosEvent.pageX - source.offset().left,
                y: downPosEvent.pageY - source.offset().top
            };
            if (!environment.isMobile) {
                // 通过坐标计算是否是点在了圆点上，因为可能是点在了菜单上，也会冒泡到圆点上
                if (offset.x < 0 || offset.x > 16 || offset.y > 16) {
                    return;
                }
            }
            jquery__WEBPACK_IMPORTED_MODULE_0___default()('body').addClass('select-disable').on('selectstart', function () {
                return false;
            });
            var sourceContainer = getNodeContainer(me.sourceId);
            // 记录是否发生了拖动，来判断是点击还是拖动操作
            var dragged = false;
            if (sourceContainer.hasClass('selected')) {
                // 已经被选中了，进行多个拖动，阻止取消选择
                downE.stopPropagation();
            }
            var doc = jquery__WEBPACK_IMPORTED_MODULE_0___default()(document);
            doc.on(environment.moveEvent + '.drag_node', function (moveE) {
                var movePosEvent = moveE;
                if (moveE.originalEvent.touches) {
                    // 移动端的拖动
                    movePosEvent = moveE.originalEvent.touches[0];
                }
                if (environment.isMobile) {
                    // 手机端要阻止默认的事件，防止页面滚动，无法准确拖动
                    moveE.preventDefault();
                }
                if (movePosEvent.clientY > (jquery__WEBPACK_IMPORTED_MODULE_0___default()(window).height() || 0) - me.boundaryOffset) {
                    // 拖动到了页面底部
                    me.autoScroll(1);
                }
                else if (movePosEvent.clientY < me.boundaryOffset) {
                    // 拖动到了页面顶部
                    me.autoScroll(-1);
                }
                else {
                    clearInterval(me.autoScrollTimer);
                    me.autoScrollTimer = null;
                }
                if (!dragged) {
                    if (Math.abs(movePosEvent.pageX - downPosEvent.pageX) < 5
                        && Math.abs(movePosEvent.pageY - downPosEvent.pageY) < 5) {
                        return;
                    }
                    dragged = true;
                    // 开始初始化拖动
                    me.initDrag();
                }
                me.dragWrapper.css({
                    left: movePosEvent.clientX - offset.x,
                    top: movePosEvent.clientY - offset.y
                });
                me.findDrop(movePosEvent.clientY);
            });
            doc.on(environment.upEvent + '.drag_node', function () {
                doc.off(environment.moveEvent + '.drag_node');
                doc.off(environment.upEvent + '.drag_node');
                doc.off('keydown.drag_node');
                if (me.dragControl) {
                    me.dragControl.hide();
                }
                jquery__WEBPACK_IMPORTED_MODULE_0___default()('body').removeClass('select-disable').off('selectstart');
                me.clearDragStyle();
                var sourceId = sourceContainer.attr('id');
                if (!dragged && !environment.isMobile) {
                    // 移动端，不根据拖动的情况来进行内钻
                    if (me.selector.getNodes().length === 0) {
                        me.engine.drillNode(sourceId, false);
                    }
                }
                else if (me.dropResult) {
                    me.engine.moveNodes(me.selectedNodes, me.dropResult.id, me.dropResult.type);
                }
                clearInterval(me.autoScrollTimer);
                me.autoScrollTimer = null;
                me.resetDrag();
            });
            // ESC取消
            doc.on('keydown.drag_node', function (downEvent) {
                if (downEvent.keyCode === 27) {
                    me.dropResult = null;
                    dragged = true;
                    jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).trigger(environment.upEvent + '.drag_node');
                }
            });
        }
        // 只读状态，mousedown失效，通过click来控制drill行为
        me.paper.on('click.readonly_drill_node', '.bullet', function () {
            if (me.state.readonly) {
                var source = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
                me.sourceId = source.data('id');
                me.engine.drillNode(me.sourceId, false);
            }
        });
        // 圆点可以拖动
        me.paper.on(environment.downEvent + '.drag_node', '.bullet', function (downE) {
            var source = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            me.sourceId = source.data('id');
            if (me.state.readonly) {
                return;
            }
            if (environment.isMobile) {
                downE.preventDefault();
                // 手机端采用延迟启用拖动的方式，直接启用，可能在滑动整个页面的时候，触发了拖动
                var upEvent_1 = environment.upEvent + '.drag_delay';
                var moveEvent_1 = environment.moveEvent + '.drag_delay';
                var doc_1 = jquery__WEBPACK_IMPORTED_MODULE_0___default()(document);
                var delayTimer_1 = null;
                // 清除长按拖动前的等待
                var cancelDragWaiting_1 = function () {
                    clearTimeout(delayTimer_1);
                    source.off(upEvent_1);
                    doc_1.off(moveEvent_1);
                    doc_1.off(upEvent_1);
                };
                // 手机端立即设置点中效果
                me.setDragStyle();
                var downPosEvent_1 = downE;
                if (downE.originalEvent.touches) {
                    // 移动端的拖动
                    downPosEvent_1 = downE.originalEvent.touches[0];
                }
                // 启动长按的等待
                delayTimer_1 = setTimeout(function () {
                    // 可以开始拖动
                    cancelDragWaiting_1();
                    // 做一个小动画提示
                    var animateCls = 'mobile-active';
                    getNodeContainer(me.sourceId).addClass(animateCls);
                    // 隐藏键盘
                    var focusNode = me.paper.find('div:focus, input:focus');
                    if (focusNode) {
                        focusNode.blur();
                        window.getSelection().removeAllRanges();
                    }
                    beginDrag(downE, source);
                }, 300);
                // 移动事件，判断是否要取消拖动长按的等待
                // 如果发生了一定偏移量的拖动，就取消拖动，并取消点击
                doc_1.on(moveEvent_1, function (moveE) {
                    var movePosEvent = moveE;
                    if (moveE.originalEvent.touches) {
                        // 移动端的拖动
                        movePosEvent = moveE.originalEvent.touches[0];
                    }
                    if (Math.abs(movePosEvent.pageX - downPosEvent_1.pageX) > 10
                        || Math.abs(movePosEvent.pageY - downPosEvent_1.pageY) > 10) {
                        me.clearDragStyle();
                        cancelDragWaiting_1();
                    }
                });
                // 为了确保事件被卸载，在up的时候再执行一次
                doc_1.on(upEvent_1, function () {
                    me.clearDragStyle();
                    cancelDragWaiting_1();
                });
                // 直接点击进行钻取
                source.on(upEvent_1, function () {
                    cancelDragWaiting_1();
                    var sourceId = source.data('id');
                    setTimeout(function () {
                        // 加一点延迟，否则会触发新渲染的内容的点击，导致让内容focus或者创建了新节点
                        me.engine.drillNode(sourceId, false);
                    }, 100);
                });
            }
            else {
                beginDrag(downE, source);
            }
        });
    };
    /**
     * 让页面自动滚动
     * @param direction
     */
    Dragger.prototype.autoScroll = function (direction) {
        var _this = this;
        if (!this.autoScrollTimer) {
            this.autoScrollTimer = setInterval(function () {
                var curTop = _this.scroller.scrollTop() || 0;
                var nextTop = direction > 0 ? curTop + _this.autoScrollStep : curTop - _this.autoScrollStep;
                _this.scroller.scrollTop(nextTop);
            }, this.autoScrollSpeed);
        }
    };
    return Dragger;
}());

var default_1 = /** @class */ (function () {
    function default_1(name, size) {
        var _a;
        this.icons = (_a = {},
            _a[IconSet.PLUS] = '<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 21 21">' +
                '<path fill="currentColor" fill-rule="evenodd" d="M9,10 L9,4.5 C9,4.22385763 9.22385763,4 9.5,4 L10.5,4 C10.7761424,4 11,4.22385763 11,4.5 L11,10 L16.5,10 C16.7761424,10 17,10.2238576 17,10.5 L17,11.5 C17,11.7761424 16.7761424,12 16.5,12 L11,12 L11,17.5 C11,17.7761424 10.7761424,18 10.5,18 L9.5,18 C9.22385763,18 9,17.7761424 9,17.5 L9,12 L3.5,12 C3.22385763,12 3,11.7761424 3,11.5 L3,10.5 C3,10.2238576 3.22385763,10 3.5,10 L9,10 Z"/>' +
                '</svg>',
            _a[IconSet.MINUS] = '<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 21 21">' +
                '<rect fill="currentColor" width="14" height="2" x="3" y="10" fill-rule="evenodd" rx="1"/>' +
                '</svg>',
            _a[IconSet.ZOOM_IN] = '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 512 512">' +
                '<path fill="currentColor" d="M216.243 37.334q36.341 0 69.498 14.21t57.074 38.127 38.127 57.074 14.21 69.499q0 31.216-10.172 59.791t-28.964 51.871l112.905 112.75q5.746 5.746 5.746 14.132 0 8.541-5.668 14.21t-14.21 5.668q-8.387 0-14.132-5.746l-112.75-112.905q-23.296 18.791-51.871 28.964t-59.791 10.172q-36.341 0-69.499-14.21t-57.074-38.127-38.127-57.074-14.21-69.499 14.21-69.499 38.127-57.074 57.074-38.127 69.499-14.21zM216.243 77.091q-28.266 0-54.046 11.026t-44.416 29.663-29.663 44.417-11.026 54.046 11.026 54.046 29.663 44.416 44.416 29.663 54.046 11.026 54.046-11.026 44.416-29.663 29.663-44.416 11.026-54.046-11.026-54.046-29.663-44.416-44.416-29.663-54.046-11.026zM216.243 136.727q8.231 0 14.055 5.824t5.824 14.055v39.757h39.757q8.231 0 14.055 5.824t5.824 14.055-5.824 14.055-14.055 5.824h-39.757v39.758q0 8.231-5.824 14.055t-14.055 5.824-14.055-5.824-5.824-14.055v-39.757h-39.757q-8.231 0-14.055-5.824t-5.824-14.055 5.824-14.055 14.055-5.824h39.757v-39.757q0-8.231 5.824-14.055t14.055-5.824z"></path>' +
                '</svg>',
            _a[IconSet.ZOOM_OUT] = '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 512 512">' +
                '<path fill="currentColor" d="M216.243 37.334q36.341 0 69.498 14.21t57.074 38.127 38.127 57.074 14.21 69.499q0 31.216-10.172 59.791t-28.964 51.871l112.905 112.75q5.746 5.746 5.746 14.132 0 8.541-5.668 14.21t-14.21 5.668q-8.387 0-14.132-5.746l-112.75-112.905q-23.296 18.791-51.871 28.964t-59.791 10.172q-36.341 0-69.499-14.21t-57.074-38.127-38.127-57.074-14.21-69.499 14.21-69.499 38.127-57.074 57.074-38.127 69.499-14.21zM216.243 77.091q-28.266 0-54.046 11.026t-44.416 29.663-29.663 44.417-11.026 54.046 11.026 54.046 29.663 44.416 44.416 29.663 54.046 11.026 54.046-11.026 44.416-29.663 29.663-44.416 11.026-54.046-11.026-54.046-29.663-44.416-44.416-29.663-54.046-11.026zM156.606 196.363h119.272q8.231 0 14.055 5.824t5.824 14.055-5.824 14.055-14.055 5.824h-119.272q-8.231 0-14.055-5.824t-5.824-14.055 5.824-14.055 14.055-5.824z"></path>' +
                '</svg>',
            _a[IconSet.MAGIC] = '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 512 512">\n' +
                '<path fill="currentColor" d="M135.964 105.954l-60.018-60.018h-30.009v30.009l60.018 60.018zM165.973 15.928h30.009v60.018h-30.009zM286.009 165.973h60.018v30.009h-60.018zM316.018 75.945v-30.009h-30.009l-60.018 60.018 30.009 30.009zM15.928 165.973h60.018v30.009h-60.018zM165.973 286.009h30.009v60.018h-30.009zM45.937 286.009v30.009h30.009l60.018-60.018-30.009-30.009zM489.508 429.49l-298.271-298.271c-8.754-8.754-23.076-8.754-31.829 0l-28.189 28.189c-8.754 8.754-8.754 23.076 0 31.829l298.271 298.271c8.753 8.753 23.076 8.753 31.829 0l28.189-28.189c8.753-8.753 8.753-23.076 0-31.829zM240.995 271.005l-90.027-90.027 30.009-30.009 90.027 90.027-30.009 30.009z"></path>\n' +
                '</svg>',
            _a[IconSet.DOWNLOAD] = '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 512 512">\n' +
                '<path fill="currentColor" d="M369.771 187.738h-68.262v-136.525h-91.017v136.525h-68.262l113.771 113.771 113.771-113.771zM468.478 336.367c-4.778-5.097-36.656-39.206-45.758-48.103-6.030-5.894-14.654-9.511-23.71-9.511h-39.979l69.719 68.125h-80.641c-2.321 0-4.414 1.183-5.461 3.026l-18.567 42.619h-136.161l-18.567-42.619c-1.047-1.843-3.162-3.026-5.461-3.026h-80.641l69.696-68.125h-39.957c-9.033 0-17.657 3.618-23.71 9.511-9.102 8.919-40.98 43.028-45.758 48.103-11.127 11.854-17.248 21.298-14.335 32.971l12.765 69.947c2.913 11.695 15.723 21.298 28.488 21.298h371.165c12.765 0 25.575-9.602 28.488-21.298l12.765-69.947c2.866-11.673-3.231-21.116-14.38-32.971z"></path>\n' +
                '</svg>',
            _a[IconSet.BUTTERFLY] = '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 512 512">\n' +
                '<path fill="currentColor" d="M511.632 96.226v0c-3.375-10.892-20.971-17.816-39.817-19.689-23.164-2.319-52.794 2.505-78.569 13.197-19.578 8.122-37.716 18.231-56.361 32.896-29.323 23.048-44.856 41.598-52.711 51.96-6.347 8.369-7.697 17.918-13.521 22.316-0.294-2.206 0.49-8.014-3.298-10.215-1.115-0.647-2.368-1.395-3.627-2.13 1.418-5.852 8.752-33.962 20.52-50.088 14.296-19.625 30.275-30.859 32.356-32.15 2.528-1.595 5.213-1.718 6.974-2.82 1.337-0.829 2.228-4.489 1.496-4.891-2.716-1.485-5.733 1.725-7.612 3.768-1.981 2.165-22.709 16.365-35.389 34.851-11.852 17.264-19.325 44.868-20.67 50.061-2.219-1.189-4.255-2.108-5.399-2.108-1.031 0-2.782 0.749-4.714 1.739-1.548-6.013-8.977-33.029-20.566-49.947-12.683-18.48-33.416-32.429-35.399-34.595-1.857-2.043-4.883-5.253-7.591-3.768-0.762 0.4 0.138 4.062 1.476 4.891 1.775 1.102 4.438 1.225 6.984 2.82 2.069 1.29 18.042 12.279 32.346 31.889 11.524 15.798 18.781 43.27 20.447 49.952-1.506 0.859-3.034 1.762-4.363 2.526-3.753 2.202-2.981 8.012-3.288 10.215-5.253-2.82-9.488-15.105-17.179-26.501-8.173-12.161-19.716-24.727-49.017-47.775-18.681-14.662-36.804-24.774-56.373-32.896-25.775-10.694-55.415-15.517-78.579-13.197-18.87 1.876-36.486 8.799-39.819 19.689-2.588 8.447 8.977 34.648 19.698 49.868 7.971 11.316 9.636 24.393 12.574 37.296 4.193 18.44 11.801 45.956 32.708 52.8 19.144 6.292 56.56-5.024 56.56-5.024s0.821 6.7-11.744 11.729c-13.077 5.239-20.133 13.407-27.658 27.656-6.757 12.781-12.141 29.918-12.141 37.487 0 11.733 2.93 15.923 2.496 21.368-0.508 6.74 1.889 13.409 6.516 18.435 5.191 5.689 3.129 10.686 5.447 16.974 2.090 5.681 10.261 10.271 10.261 10.271s-0.924 12.857 8.386 21.373c7.521 6.906 16.045 11.418 21.584 16.329 5.634 5.041 9.846 9.026 21.986 11.327 6.998 1.329 11.325 12.717 25.98 11.882 15.906-0.91 15.865-0.265 25.999-4.413 16.322-6.696 23.623-38.304 30.575-68.829 5.464-23.897 9.645-38.725 16.87-43.743-2.050 13.988 1.011 37.233 1.011 37.233s-2.217 11.933-0.171 13.986c-0.946 6.131 0.956 14.519 1.993 14.312 0.425 5.010 3.038 14.122 6.711 14.122 3.67 0 6.292-9.114 6.692-14.122 1.064 0.207 2.941-8.179 2.005-14.312 2.041-2.052-0.167-13.986-0.167-13.986s2.824-21.827 0.945-37.542c6.452 3.288 11.471 20.156 16.917 44.052 6.971 30.526 14.262 62.134 30.603 68.829 10.111 4.149 10.083-0.065 25.978 0.842 14.666 0.837 18.986-13.038 25.978-14.351 12.161-2.308 16.352-6.286 21.998-11.319 5.564-4.923 14.041-9.43 21.598-16.341 9.275-8.519 8.363-21.38 8.363-21.38s8.215-4.606 10.293-10.269c2.27-6.283 0.222-11.285 5.423-16.971 4.614-5.022 7.024-11.695 6.493-18.433-0.413-5.45 2.536-9.643 2.536-21.368 0-7.567-5.401-18.662-12.182-31.443-7.533-14.249-14.56-22.416-27.643-27.656-12.565-5.029-11.729-11.729-11.729-11.729s37.378 11.315 56.583 5.024c20.877-6.844 28.497-34.36 32.678-52.8 2.938-12.903 4.614-25.982 12.571-37.296 10.695-15.222 22.292-41.422 19.693-49.868z"></path>\n' +
                '</svg>',
            _a[IconSet.IMAGE] = '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 512 512">\n' +
                '<path fill="currentColor" d="M460.8 60.8h-409.6c-14.157 0-25.6 11.443-25.6 25.6v307.2c0 14.131 11.443 25.6 25.6 25.6h409.6c14.157 0 25.6-11.469 25.6-25.6v-307.2c0-14.131-11.443-25.6-25.6-25.6zM339.2 150.4c17.664 0 32 14.336 32 32s-14.336 32-32 32-32-14.336-32-32 14.336-32 32-32zM102.4 342.4l84.838-195.047 96.487 156.211 82.714-41.088 43.161 79.923h-307.2z"></path>\n' +
                '</svg>',
            _a[IconSet.MOON] = '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 421 512">\n' +
                '<path fill="currentColor" d="M349.631 363.808q-14.303 2.384-29.137 2.384-48.209 0-89.266-23.84t-64.897-64.897-23.84-89.266q0-50.858 27.548-94.564-53.242 15.894-87.014 60.659t-33.773 101.716q0 34.435 13.509 65.824t36.157 54.036 54.036 36.157 65.824 13.509q38.144 0 72.447-16.291t58.407-45.428zM403.403 341.293q-24.899 53.772-75.095 85.956t-109.531 32.184q-41.322 0-78.936-16.158t-64.897-43.441-43.441-64.897-16.158-78.936q0-40.528 15.231-77.479t41.322-63.97 62.38-43.573 76.817-18.145q11.655-0.53 16.158 10.331 4.768 10.86-3.973 19.072-22.78 20.661-34.833 48.076t-12.053 57.877q0 39.203 19.337 72.314t52.447 52.447 72.314 19.337q31.257 0 60.394-13.509 10.861-4.768 19.072 3.443 3.709 3.709 4.635 9.007t-1.192 10.065z"></path>\n' +
                '</svg>',
            _a[IconSet.SUN] = '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 512 512">\n' +
                '<path fill="currentColor" d="M256 136q32.656 0 60.235 16.094t43.672 43.672 16.094 60.234-16.094 60.235-43.672 43.672-60.235 16.094-60.234-16.094-43.672-43.672-16.094-60.235 16.094-60.234 43.672-43.672 60.234-16.094zM128.813 363.188q8.281 0 14.141 5.938t5.859 14.219q0 8.125-5.938 14.063l-28.281 28.281q-5.938 5.938-14.063 5.938-8.281 0-14.141-5.86t-5.859-14.141q0-8.438 5.781-14.219l28.281-28.281q5.938-5.938 14.219-5.938zM256 416q8.281 0 14.141 5.86t5.86 14.141v40q0 8.281-5.86 14.141t-14.141 5.86-14.141-5.86-5.859-14.141v-40q0-8.281 5.859-14.141t14.141-5.86zM36 236h40q8.281 0 14.141 5.859t5.859 14.141-5.859 14.141-14.141 5.86h-40q-8.282 0-14.141-5.86t-5.86-14.141 5.86-14.141 14.141-5.859zM256 176q-33.125 0-56.563 23.438t-23.438 56.563 23.438 56.563 56.563 23.438 56.563-23.438 23.438-56.563-23.438-56.563-56.563-23.438zM383.344 363.188q8.125 0 14.063 5.938l28.281 28.281q5.938 5.938 5.938 14.219 0 8.125-5.938 14.063t-14.063 5.938q-8.281 0-14.219-5.938l-28.281-28.281q-5.781-5.781-5.781-14.063t5.86-14.219 14.141-5.938zM100.531 80.375q8.125 0 14.063 5.938l28.281 28.281q5.938 5.938 5.938 14.063 0 8.281-5.859 14.141t-14.141 5.859q-8.438 0-14.219-5.781l-28.281-28.281q-5.781-5.781-5.781-14.219 0-8.281 5.859-14.141t14.141-5.859zM256 16q8.281 0 14.141 5.86t5.86 14.141v40q0 8.281-5.86 14.141t-14.141 5.859-14.141-5.859-5.859-14.141v-40q0-8.282 5.859-14.141t14.141-5.86zM436 236h40q8.281 0 14.141 5.859t5.86 14.141-5.86 14.141-14.141 5.86h-40q-8.281 0-14.141-5.86t-5.86-14.141 5.86-14.141 14.141-5.859zM411.625 80.375q8.125 0 14.063 5.938t5.938 14.063q0 8.281-5.938 14.219l-28.281 28.281q-5.781 5.781-14.063 5.781-8.594 0-14.297-5.703t-5.704-14.297q0-8.281 5.781-14.063l28.281-28.281q5.938-5.938 14.219-5.938z"></path>\n' +
                '</svg>',
            _a[IconSet.CHEVRON_LEFT] = '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 512 512">\n' +
                '<path fill="currentColor" d="M120.060 266.632c-0.276-0.536-0.725-0.983-0.967-1.536-4.748-9.879-3.194-21.966 5.215-29.91l190.631-180.302c10.395-9.826 26.783-9.359 36.627 1.020 9.825 10.395 9.375 26.782-1.020 36.626l-171.046 161.807 170.37 164.208c10.293 9.931 10.603 26.318 0.675 36.626-5.077 5.286-11.863 7.926-18.651 7.926-6.474 0-12.951-2.416-17.976-7.252l-188.903-182.065c-0.364-0.361-0.501-0.862-0.864-1.24-0.277-0.262-0.569-0.45-0.846-0.728-1.469-1.536-2.246-3.418-3.247-5.18v0z"></path>\n' +
                '</svg>',
            _a[IconSet.MENU] = '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 512 512">\n' +
                '<path fill="currentColor" d="M64.032 115.2h383.935v44.8h-383.935v-44.8zM64.032 236.8h383.935v44.8h-383.935v-44.8zM64.032 352h383.935v44.8h-383.935v-44.8z"></path>\n' +
                '</svg>',
            _a[IconSet.FINISH] = '<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 24 24">\n' +
                '<path fill="currentColor" d="M12,21 C7.02943725,21 3,16.9705627 3,12 C3,7.02943725 7.02943725,3 12,3 C16.9705627,3 21,7.02943725 21,12 C21,16.9705627 16.9705627,21 12,21 Z M12,19 C15.8659932,19 19,15.8659932 19,12 C19,8.13400675 15.8659932,5 12,5 C8.13400675,5 5,8.13400675 5,12 C5,15.8659932 8.13400675,19 12,19 Z M15.6513752,8.67082536 L16.382506,9.34749775 C16.5818164,9.53196244 16.5974429,9.84179291 16.417704,10.0453753 L11.4090365,15.7187275 C11.2262734,15.9257353 10.9103016,15.9453895 10.7032937,15.7626263 C10.7032517,15.7625892 10.7032097,15.7625521 10.7031677,15.762515 L7.717111,13.1241718 C7.51189088,12.9428641 7.49069451,12.6302101 7.66956579,12.4228629 L8.32023591,11.6686076 C8.50061177,11.4595163 8.81633726,11.4362379 9.02542853,11.6166138 C9.0278636,11.6187144 9.03027833,11.6208385 9.03267241,11.6229857 L10.7331526,13.1481373 C10.8359387,13.2403255 10.9939966,13.2317343 11.0861849,13.1289483 C11.0870005,13.1280389 11.0878094,13.1271236 11.0886116,13.1262024 L14.9346777,8.70942939 C15.1160213,8.50117681 15.4318513,8.47936272 15.6401039,8.66070624 C15.6439119,8.66402218 15.6476694,8.6673956 15.6513752,8.67082536 Z"/>\n' +
                '</svg>',
            _a[IconSet.PEN_OUTLINE] = '<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 24 24">\n' +
                '<path fill="currentColor" d="M7.52154419,14.3203126 L14.3219258,7.97885415 C14.5238835,7.7905255 14.8402731,7.80157407 15.0286018,8.00353182 L15.7106001,8.73488552 C15.8989288,8.93684327 15.8878802,9.25323291 15.6859225,9.44156155 L4.82055788,19.573678 C4.61860013,19.7620066 4.30221049,19.750958 4.11388185,19.5490003 L3.43188349,18.8176466 C3.40516515,18.7889947 3.38245974,18.7580396 3.36374308,18.7254737 C3.20123243,18.5919281 3.06761788,18.4248621 2.97286452,18.2342406 L1.24956975,14.767377 C1.14850641,14.5640613 1.09491676,14.3404559 1.09284057,14.1134168 L0.981121623,1.89654267 C0.97354627,1.06815018 1.63895003,0.390464343 2.46734252,0.382888989 C2.47420062,0.382836727 2.47420062,0.382836727 2.48105891,0.382826275 L5.92546154,0.382826275 C6.74853707,0.382826275 7.41787241,1.04606877 7.42539883,1.86910988 L7.53715728,14.0903041 C7.53786318,14.167497 7.53260797,14.2443875 7.52154419,14.3203126 Z M3.00589779,4.59676212 C3.01403389,4.59656666 3.02219407,4.59646836 3.0303772,4.59646836 L5.45025592,4.59646836 L5.43001296,2.38282627 L2.98565214,2.38282627 L3.00589779,4.59676212 Z M3.02418421,6.59644959 L3.0917053,13.9801267 L4.31607263,16.4432656 L5.53614514,13.9887668 L5.46854521,6.59646836 L3.0303772,6.59646836 C3.0283114,6.59646836 3.02624707,6.5964621 3.02418421,6.59644959 Z" transform="rotate(43 5.444 19.021)"/>\n' +
                '</svg>',
            _a[IconSet.IMAGE_OUTLINE] = '<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 24 24">\n' +
                '<path fill="currentColor" d="M17,11.7614023 L17,7 L7,7 L7,13.2613965 L7.56253285,12.6519859 C8.4322495,11.7097929 9.85451931,11.5317985 10.9296037,12.2306034 C11.2234826,12.4216246 11.6096155,12.3883346 11.8664634,12.1498329 L13.7212973,10.4274872 C14.3283633,9.86378302 15.27746,9.89893475 15.8411642,10.5060008 L17,11.7614023 Z M17,14.7100309 L14.7147171,12.2343078 L13.2273656,13.6154199 C12.2985888,14.4778555 10.9023098,14.5982344 9.83962703,13.9074906 C9.58180145,13.739904 9.24071424,13.7825904 9.03213974,14.0085462 L7,16.2100309 L7,17 L17,17 L17,14.7100309 Z M6,5 L18,5 C18.5522847,5 19,5.44771525 19,6 L19,18 C19,18.5522847 18.5522847,19 18,19 L6,19 C5.44771525,19 5,18.5522847 5,18 L5,6 C5,5.44771525 5.44771525,5 6,5 Z M9,10 C8.44771525,10 8,9.55228475 8,9 C8,8.44771525 8.44771525,8 9,8 C9.55228475,8 10,8.44771525 10,9 C10,9.55228475 9.55228475,10 9,10 Z"/>\n' +
                '</svg>',
            _a[IconSet.EXPORT] = '<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 24 24">\n' +
                '<path fill="currentColor" d="M20.7074804,12.7066928 L20.7088136,12.7080241 L20.5120916,12.9050338 L20.4169006,13.0016632 L20.4156001,13.0016666 L18.055266,15.3654536 C17.8601466,15.5608584 17.5435642,15.5610898 17.3481594,15.3659705 L16.640536,14.6593807 C16.4451312,14.4642613 16.4448998,14.1476789 16.6400191,13.9522741 L17.5818713,13.0090441 L11.5147054,13.0248396 C11.2386108,13.0255622 11.0141877,12.8023642 11.013399,12.5262697 L11.0104222,11.5262742 C11.0096333,11.2501329 11.2328505,11.0256367 11.5089918,11.0248478 L17.5878553,11.0074816 L16.6496213,10.0718057 C16.4540928,9.87681032 16.4536606,9.56022812 16.648656,9.3646996 L17.3541008,8.65732614 C17.5490962,8.46179762 17.8656784,8.46136544 18.0612069,8.65636084 C18.0614393,8.65659264 18.0616715,8.65682466 18.0619035,8.65705691 L21.0517526,11.6505222 C21.2457796,11.8447839 21.2468632,12.1591597 21.0541801,12.3547543 L20.7074804,12.7066928 Z M8,18 L12.5,18 C12.7761424,18 13,18.2238576 13,18.5 L13,19.5 C13,19.7761424 12.7761424,20 12.5,20 L7.5,20 C6.67157288,20 6,19.3284271 6,18.5 L6,5.5 C6,4.67157288 6.67157288,4 7.5,4 L12.5,4 C12.7761424,4 13,4.22385763 13,4.5 L13,5.5 C13,5.77614237 12.7761424,6 12.5,6 L8,6 L8,18 Z"/>\n' +
                '</svg>',
            _a[IconSet.DELETE] = '<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 24 24">\n' +
                '<path fill="currentColor" fill-rule="evenodd" d="M15,5 L15,14.5 C15,15.3284271 14.3284271,16 13.5,16 L4.5,16 C3.67157288,16 3,15.3284271 3,14.5 L3,5 L0.5,5 C0.223857625,5 3.38176876e-17,4.77614237 0,4.5 L0,3.5 C-3.38176876e-17,3.22385763 0.223857625,3 0.5,3 L17.5,3 C17.7761424,3 18,3.22385763 18,3.5 L18,4.5 C18,4.77614237 17.7761424,5 17.5,5 L15,5 Z M13,5 L5,5 L5,14 L13,14 L13,5 Z M5.5,0 L12.5,0 C12.7761424,-5.07265313e-17 13,0.223857625 13,0.5 L13,1.5 C13,1.77614237 12.7761424,2 12.5,2 L5.5,2 C5.22385763,2 5,1.77614237 5,1.5 L5,0.5 C5,0.223857625 5.22385763,5.07265313e-17 5.5,0 Z" transform="translate(3 4)"/>\n' +
                '</svg>',
            _a[IconSet.HEADING1] = '<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 24 24">\n' +
                '<path fill="currentColor" fill-rule="evenodd" d="M6,11 L11,11 L11,5.5 C11,5.22385763 11.2238576,5 11.5,5 L12.5,5 C12.7761424,5 13,5.22385763 13,5.5 L13,18.5 C13,18.7761424 12.7761424,19 12.5,19 L11.5,19 C11.2238576,19 11,18.7761424 11,18.5 L11,13 L6,13 L6,18.5 C6,18.7761424 5.77614237,19 5.5,19 L4.5,19 C4.22385763,19 4,18.7761424 4,18.5 L4,5.5 C4,5.22385763 4.22385763,5 4.5,5 L5.5,5 C5.77614237,5 6,5.22385763 6,5.5 L6,11 Z M16.3191609,13.2262431 L15.5,13.2262431 L15.5,11.5 L16.1893661,11.3514644 C16.5508383,11.2610963 16.9387737,11.1013582 17.3436375,10.8766795 C17.767548,10.6176231 18.107311,10.3543068 18.3736532,10.076867 L18.554,10 L19.86,10 L19.86,19.068 L18,19.068 L17.956,12.4622425 C17.4901956,12.7918316 16.9454178,13.0459571 16.3191609,13.2262431 Z"/>\n' +
                '</svg>',
            _a[IconSet.HEADING2] = '<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 24 24">\n' +
                '<path fill="currentColor" fill-rule="evenodd" d="M6,11 L11,11 L11,5.5 C11,5.22385763 11.2238576,5 11.5,5 L12.5,5 C12.7761424,5 13,5.22385763 13,5.5 L13,18.5 C13,18.7761424 12.7761424,19 12.5,19 L11.5,19 C11.2238576,19 11,18.7761424 11,18.5 L11,13 L6,13 L6,18.5 C6,18.7761424 5.77614237,19 5.5,19 L4.5,19 C4.22385763,19 4,18.7761424 4,18.5 L4,5.5 C4,5.22385763 4.22385763,5 4.5,5 L5.5,5 C5.77614237,5 6,5.22385763 6,5.5 L6,11 Z M20.476,17.264 L20.476,19 L14,19 L14,18.75 C14,17.806858 14.3022094,16.9934646 14.9130777,16.3062674 C15.2438025,15.9246618 15.9185611,15.3854712 16.9272339,14.6927737 C17.4352966,14.3393388 17.8204483,14.0223293 18.058853,13.7722412 C18.3937624,13.3941176 18.56,12.9956751 18.56,12.582 C18.56,12.1863829 18.4564322,11.9003384 18.2702717,11.7233839 C18.0727246,11.5446509 17.762219,11.452 17.322,11.452 C16.8700612,11.452 16.5499963,11.597484 16.3305796,11.8964554 C16.1054945,12.1829273 15.9742382,12.6477935 15.9518407,13.2749229 L15.9432308,13.516 L14.0448555,13.516 L14.0480195,13.2628752 C14.0607989,12.2405252 14.360133,11.4133332 14.9525316,10.7823651 C15.5652574,10.1044556 16.3771132,9.764 17.37,9.764 C18.2570959,9.764 19.0004981,10.0248429 19.5901682,10.549015 C20.1732642,11.0791022 20.464,11.7596884 20.464,12.594 C20.464,13.3939174 20.1582478,14.125771 19.5567638,14.7925796 C19.2170027,15.1566094 18.6299213,15.6102631 17.7353516,16.2108888 C17.1412554,16.6015274 16.7158081,16.9554504 16.4591053,17.264 L20.476,17.264 Z"/>\n' +
                '</svg>',
            _a[IconSet.HEADING3] = '<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 24 24">\n' +
                '<path fill="currentColor" fill-rule="evenodd" d="M6,11 L11,11 L11,5.5 C11,5.22385763 11.2238576,5 11.5,5 L12.5,5 C12.7761424,5 13,5.22385763 13,5.5 L13,18.5 C13,18.7761424 12.7761424,19 12.5,19 L11.5,19 C11.2238576,19 11,18.7761424 11,18.5 L11,13 L6,13 L6,18.5 C6,18.7761424 5.77614237,19 5.5,19 L4.5,19 C4.22385763,19 4,18.7761424 4,18.5 L4,5.5 C4,5.22385763 4.22385763,5 4.5,5 L5.5,5 C5.77614237,5 6,5.22385763 6,5.5 L6,11 Z M20.2643045,14.611909 C20.5940946,14.9829229 20.7594521,15.4617709 20.7594521,16.026 C20.7594521,16.8871255 20.4547758,17.6024526 19.8482642,18.1562088 C19.2213363,18.7178317 18.4040213,19 17.4134521,19 C16.4681928,19 15.691561,18.7530376 15.1046541,18.2574262 C14.4517951,17.7090246 14.0851843,16.9037901 14.0081523,15.8766975 L13.988,15.608 L15.9248188,15.608 L15.9352162,15.8471407 C15.9569094,16.3460843 16.1042464,16.7093462 16.3827163,16.9580172 C16.6371322,17.1920799 16.973929,17.312 17.4014521,17.312 C17.8773488,17.312 18.247994,17.1798119 18.5086754,16.9292233 C18.7415204,16.6963783 18.8554521,16.4224574 18.8554521,16.086 C18.8554521,15.6731278 18.7344041,15.3826126 18.501406,15.1980553 C18.2703224,15.0054856 17.9111648,14.908 17.4014521,14.908 L16.5514521,14.908 L16.5514521,13.352 L17.4014521,13.352 C17.8523663,13.352 18.181273,13.259495 18.3907543,13.0881858 C18.5849837,12.9217035 18.6874521,12.6667239 18.6874521,12.318 C18.6874521,11.9682244 18.5951811,11.7198025 18.4267543,11.5598142 C18.2256932,11.3874761 17.910609,11.296 17.4734521,11.296 C17.0241194,11.296 16.7015605,11.3985187 16.4740783,11.6061442 C16.2388447,11.8119736 16.0968551,12.1365213 16.0543774,12.5931558 L16.0332757,12.82 L14.1537523,12.82 L14.1763157,12.5492386 C14.2542638,11.6138611 14.6001035,10.8830302 15.2193612,10.3671477 C15.801496,9.84969447 16.552822,9.596 17.4614521,9.596 C18.3864411,9.596 19.1457869,9.81990967 19.71927,10.2761095 C20.2985396,10.7476081 20.5914521,11.3974024 20.5914521,12.21 C20.5914521,13.0477077 20.2380219,13.676061 19.556569,14.0703749 C19.8460655,14.2175973 20.0832104,14.3978165 20.2643045,14.611909 Z"/>\n' +
                '</svg>',
            _a[IconSet.PEN] = '<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 24 24">\n' +
                '<path fill="currentColor" d="M14.3255436,4.06202364 L16.7651686,5.44914702 C16.9897298,5.57682821 17.0666702,5.85961199 16.9370197,6.08076228 L12.6613515,13.3739479 L9.40851816,11.5244501 L13.6841864,4.23126444 C13.8138369,4.01011414 14.1009823,3.93434245 14.3255436,4.06202364 Z M8.9390121,12.3253062 L12.1918454,14.174804 L11.2528333,15.7765161 C10.806269,15.527085 10.5045013,15.4474548 10.3475303,15.5376255 C10.1905593,15.6277963 10.0340572,15.7819212 9.87802421,16 L8,16 C8.38736209,15.4401498 8.58161243,15.0343143 8.582751,14.7824935 C8.58388958,14.5306726 8.38963924,14.2455143 8,13.9270183 L8.9390121,12.3253062 Z M5.5,17.0297727 L18.5,17.0297727 C18.7761424,17.0297727 19,17.2536303 19,17.5297727 L19,18.5297727 C19,18.8059151 18.7761424,19.0297727 18.5,19.0297727 L5.5,19.0297727 C5.22385763,19.0297727 5,18.8059151 5,18.5297727 L5,17.5297727 C5,17.2536303 5.22385763,17.0297727 5.5,17.0297727 Z"/>\n' +
                '</svg>',
            _a[IconSet.SIZE_FIT] = '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 512 512">\n' +
                '<path fill="currentColor" d="M467.627 452.267h-426.666v-375.466h426.666v375.466zM75.094 418.134h358.4v-307.2h-358.4v307.2z"></path>\n' +
                '<path fill="currentColor" d="M401.067 384h-85.334v-34.134h51.2v-51.2h34.134z"></path>\n' +
                '<path fill="currentColor" d="M401.067 230.4h-34.134v-51.2h-51.2v-34.133h85.334z"></path>\n' +
                '<path fill="currentColor" d="M196.267 384h-85.334v-85.334h34.134v51.2h51.2z"></path>\n' +
                '<path fill="currentColor" d="M145.066 230.4h-34.133v-85.333h85.334v34.133h-51.2z"></path>\n' +
                '</svg>',
            _a[IconSet.SIZE_ORIGINAL] = '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 512 512">\n' +
                '<path fill="currentColor" d="M402.774 384h-295.253v-238.934h293.546v238.934zM141.654 349.866h225.28v-170.667h-225.28v170.667z"></path>\n' +
                '<path fill="currentColor" d="M469.334 194.56h-34.133v-85.334h-85.334v-34.133h119.466z"></path>\n' +
                '<path fill="currentColor" d="M76.8 194.56h-34.133v-119.466h119.466v34.133h-85.334z"></path>\n' +
                '<path fill="currentColor" d="M469.334 452.267h-119.466v-34.133h85.334v-85.334h34.134z"></path>\n' +
                '<path fill="currentColor" d="M162.133 452.267h-119.466v-119.466h34.133v85.334h85.334z"></path>\n' +
                '</svg>',
            _a[IconSet.CLOSE] = '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 512 512">\n' +
                '<path fill="currentColor" d="M430.933 110.933l-29.866-29.867-145.067 140.8-145.066-140.8-29.867 29.867 140.8 145.066-140.8 145.067 29.867 29.866 145.066-140.8 145.067 140.8 29.866-29.866-140.8-145.067z"></path>\n' +
                '</svg>',
            _a);
        this.name = name;
        this.size = size;
    }
    default_1.prototype.toString = function () {
        var svg = this.icons[this.name];
        var reg = new RegExp('{size}', 'g');
        return svg.replace(reg, this.size.toString());
    };
    return default_1;
}());
var IconSet;
(function (IconSet) {
    IconSet["PLUS"] = "plus";
    IconSet["MINUS"] = "minus";
    IconSet["ZOOM_IN"] = "zoom_in";
    IconSet["ZOOM_OUT"] = "zoom_out";
    IconSet["MAGIC"] = "magic";
    IconSet["DOWNLOAD"] = "download";
    IconSet["BUTTERFLY"] = "butterfly";
    IconSet["IMAGE"] = "image";
    IconSet["MOON"] = "moon";
    IconSet["SUN"] = "sun";
    IconSet["CHEVRON_LEFT"] = "chevron_left";
    IconSet["MENU"] = "menu";
    IconSet["FINISH"] = "finish";
    IconSet["PEN_OUTLINE"] = "pen_outline";
    IconSet["IMAGE_OUTLINE"] = "image_outline";
    IconSet["EXPORT"] = "export";
    IconSet["DELETE"] = "delete";
    IconSet["HEADING1"] = "heading1";
    IconSet["HEADING2"] = "heading2";
    IconSet["HEADING3"] = "heading3";
    IconSet["PEN"] = "pen";
    IconSet["SIZE_ORIGINAL"] = "size_original";
    IconSet["SIZE_FIT"] = "size_fit";
    IconSet["CLOSE"] = "CLOSE";
})(IconSet || (IconSet = {}));

/**
 * 将字符串复制到剪贴板
 * @param str
 * @param successHandler 成功事件
 * @param errorHandler 错误事件
 */
function copy$2(str, successHandler, errorHandler) {
    // 正在复制则退出，避免循环调用
    if (jquery__WEBPACK_IMPORTED_MODULE_0___default()('#copy-img').length) {
        return;
    }
    var copyResult;
    var win = window;
    if (win.clipboardData) { // Internet Explorer
        win.clipboardData.setData('text', str);
        copyResult = true;
    }
    else {
        var copyImg = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div id="copy-img" contenteditable="true">' + str + '</div>').appendTo('body');
        copyImg.css({
            position: 'fixed',
            left: -500,
            top: -100,
        });
        var range = document.createRange();
        range.selectNodeContents(copyImg[0]);
        var selection = window.getSelection();
        selection.removeAllRanges();
        selection.addRange(range);
        try {
            copyResult = document.execCommand('copy');
        }
        catch (err) {
            copyResult = false;
        }
        window.getSelection().removeAllRanges();
        copyImg.remove();
    }
    if (copyResult) {
        successHandler();
    }
    else {
        errorHandler();
    }
}
/**
 * 解析幕布剪贴板的内容
 * @param str 剪贴板中的字符串
 * @return str
 */
function parse(str) {
    if (str.indexOf('mubu_clipboard:') === 0) {
        return JSON.parse(str.substring(15));
    }
    return null;
}
/**
 * 是否是幕布的剪贴板内容
 * @param str
 */
function isMubuClipboardText(str) {
    return str && str.indexOf('mubu_clipboard:') === 0;
}

var KeyCode;
(function (KeyCode) {
    KeyCode[KeyCode["BackSpace"] = 8] = "BackSpace";
    KeyCode[KeyCode["Tab"] = 9] = "Tab";
    KeyCode[KeyCode["Clear"] = 12] = "Clear";
    KeyCode[KeyCode["Enter"] = 13] = "Enter";
    KeyCode[KeyCode["Shift"] = 16] = "Shift";
    KeyCode[KeyCode["Ctrl"] = 17] = "Ctrl";
    KeyCode[KeyCode["Alt"] = 18] = "Alt";
    KeyCode[KeyCode["Esc"] = 27] = "Esc";
    KeyCode[KeyCode["Space"] = 32] = "Space";
    KeyCode[KeyCode["PageUp"] = 33] = "PageUp";
    KeyCode[KeyCode["PageDown"] = 34] = "PageDown";
    KeyCode[KeyCode["End"] = 35] = "End";
    KeyCode[KeyCode["Home"] = 36] = "Home";
    KeyCode[KeyCode["Left"] = 37] = "Left";
    KeyCode[KeyCode["Up"] = 38] = "Up";
    KeyCode[KeyCode["Right"] = 39] = "Right";
    KeyCode[KeyCode["Down"] = 40] = "Down";
    KeyCode[KeyCode["Delete"] = 46] = "Delete";
    KeyCode[KeyCode["Digit0"] = 48] = "Digit0";
    KeyCode[KeyCode["Digit9"] = 57] = "Digit9";
    KeyCode[KeyCode["A"] = 65] = "A";
    KeyCode[KeyCode["B"] = 66] = "B";
    KeyCode[KeyCode["C"] = 67] = "C";
    KeyCode[KeyCode["D"] = 68] = "D";
    KeyCode[KeyCode["E"] = 69] = "E";
    KeyCode[KeyCode["F"] = 70] = "F";
    KeyCode[KeyCode["G"] = 71] = "G";
    KeyCode[KeyCode["H"] = 72] = "H";
    KeyCode[KeyCode["I"] = 73] = "I";
    KeyCode[KeyCode["J"] = 74] = "J";
    KeyCode[KeyCode["K"] = 75] = "K";
    KeyCode[KeyCode["L"] = 76] = "L";
    KeyCode[KeyCode["M"] = 77] = "M";
    KeyCode[KeyCode["N"] = 78] = "N";
    KeyCode[KeyCode["O"] = 79] = "O";
    KeyCode[KeyCode["P"] = 80] = "P";
    KeyCode[KeyCode["Q"] = 81] = "Q";
    KeyCode[KeyCode["R"] = 82] = "R";
    KeyCode[KeyCode["S"] = 83] = "S";
    KeyCode[KeyCode["T"] = 84] = "T";
    KeyCode[KeyCode["U"] = 85] = "U";
    KeyCode[KeyCode["V"] = 86] = "V";
    KeyCode[KeyCode["W"] = 87] = "W";
    KeyCode[KeyCode["X"] = 88] = "X";
    KeyCode[KeyCode["Y"] = 89] = "Y";
    KeyCode[KeyCode["Z"] = 90] = "Z";
    KeyCode[KeyCode["Meta"] = 91] = "Meta";
    KeyCode[KeyCode["Numpad0"] = 96] = "Numpad0";
    KeyCode[KeyCode["Numpad9"] = 105] = "Numpad9";
    KeyCode[KeyCode["F11"] = 122] = "F11";
    KeyCode[KeyCode["\\"] = 220] = "\\";
    KeyCode[KeyCode["Ime"] = 229] = "Ime";
})(KeyCode || (KeyCode = {}));
var MouseButton;
(function (MouseButton) {
    /* 左键 */
    MouseButton[MouseButton["Primary"] = 0] = "Primary";
    /* 中建 */
    MouseButton[MouseButton["Auxiliary"] = 1] = "Auxiliary";
    /* 右键 */
    MouseButton[MouseButton["Secondary"] = 2] = "Secondary";
})(MouseButton || (MouseButton = {}));

/**
 * Created by morris on 2017/7/12.
 * 图片预览组件
 */
var ImagePreview = /** @class */ (function () {
    function ImagePreview(engine, viewport, state) {
        this.engine = engine;
        this.viewport = viewport;
        this.state = state;
    }
    /**
     * 初始化预览
     */
    ImagePreview.prototype.initPreview = function () {
        var papers = this.viewport.paper;
        var me = this;
        // 最小宽度
        var minWidth = 50;
        var img;
        var eventNameSpace = '.mindnote-preview-image';
        /**
         * 初始化图片预览
         */
        papers.on('click' + eventNameSpace, '.attach-img', function (clickEvent) {
            var target = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            var imgWrapper = target.parent();
            if (me.state.getEditorProps().env === MindNoteEnvironment.APP) {
                // APP调用engine，给外部发消息
                var nodeId = target.data('nodeid');
                var imageId = imgWrapper.parent().attr('fid');
                me.engine.previewImage(nodeId, imageId);
                return;
            }
            if (imgWrapper.hasClass('active') || target.hasClass('readonly')) {
                // 已经被选中，再次点击为查看大图
                var nodeId = target.data('nodeid');
                var imageId = imgWrapper.parent().attr('fid');
                me.engine.previewImage(nodeId, imageId);
            }
            else {
                jquery__WEBPACK_IMPORTED_MODULE_0___default()('.image-wrapper.active').removeClass('active');
                imgWrapper.addClass('active');
                var win = jquery__WEBPACK_IMPORTED_MODULE_0___default()(window);
                win.off(eventNameSpace);
                win.on('keydown' + eventNameSpace, function (e) {
                    if (e.keyCode === KeyCode.BackSpace || e.keyCode === KeyCode.Delete) {
                        imgWrapper.find('.attach-remove').trigger('click');
                    }
                });
                jquery__WEBPACK_IMPORTED_MODULE_0___default()(window).on('copy' + eventNameSpace, function (e) {
                    imgWrapper.find('.attach-copy').trigger('click');
                });
                jquery__WEBPACK_IMPORTED_MODULE_0___default()(window).on('cut' + eventNameSpace, function (e) {
                    imgWrapper.find('.attach-copy').trigger('click');
                    imgWrapper.find('.attach-remove').trigger('click');
                });
            }
        });
        /**
         * 按下拖动按钮时 绑定全局的抬起事件 和 编辑区域的移动事件
         */
        papers.on('mousedown' + eventNameSpace, '.attach-resize', function () {
            img = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).parent().find('img');
            var nodeId = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).data('nodeid');
            var nodeIndex = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).parent().parent().index();
            // 禁止选中文字
            jquery__WEBPACK_IMPORTED_MODULE_0___default()('body').addClass('select-disable').on('selectstart', function () {
                return false;
            });
            jquery__WEBPACK_IMPORTED_MODULE_0___default()(window).on('mouseup' + eventNameSpace, function () {
                var imgWidth = img.width();
                me.engine.resizeImage(nodeId, nodeIndex, imgWidth);
                jquery__WEBPACK_IMPORTED_MODULE_0___default()(window).off('mouseup' + eventNameSpace).off('mousemove' + eventNameSpace);
                jquery__WEBPACK_IMPORTED_MODULE_0___default()('body').removeClass('select-disable').off('selectstart');
            });
            jquery__WEBPACK_IMPORTED_MODULE_0___default()(window).on('mousemove' + eventNameSpace, function (e) {
                var newW = Math.round(e.pageX - img.offset().left);
                if (newW <= minWidth) {
                    newW = minWidth;
                }
                img.width(newW);
            });
        });
        /**
         * 删除图片
         */
        papers.on('click.remove-img', '.attach-remove', function () {
            var target = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            var nodeId = target.data('nodeid');
            var imageIndex = target.parent().parent().prevAll('div:not(.uploading)').length;
            me.engine.removeImage(nodeId, imageIndex);
        });
        /**
         * 复制图片
         */
        papers.on('click.remove-img', '.attach-copy', function () {
            var target = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            var nodeId = target.data('nodeid');
            var imageIndex = target.parent().parent().prevAll('div:not(.uploading)').length;
            var node = me.engine.getNode(nodeId);
            var imageObj = node.images[imageIndex];
            var clipboardData = {
                type: 'image',
                data: imageObj
            };
            var str = 'mubu_clipboard:' + JSON.stringify(clipboardData);
            var success = function () {
                // $.toast('复制成功，您可以到相应的主题下进行粘贴');
            };
            var error = function () {
                // $.toast('复制失败，无法访问您的剪贴板');
            };
            copy$2(str, success, error);
        });
        /**
         * 阻止冒泡
         */
        papers.on('mousedown' + eventNameSpace, '.image-wrapper', function (clickEvent) {
            clickEvent.stopPropagation();
        });
        jquery__WEBPACK_IMPORTED_MODULE_0___default()('body').on('mousedown' + eventNameSpace, function () {
            me.viewport.paper.find('.image-wrapper.active').removeClass('active');
            var win = jquery__WEBPACK_IMPORTED_MODULE_0___default()(window);
            win.off(eventNameSpace);
        });
    };
    /**
     * 编辑器中图片点击预览的遮罩层
     * @param url
     * @deprecated 这个方法目前已废弃，web端接入统一的图片查看器，移动端使用native查看器
     */
    ImagePreview.prototype.preview = function (url) {
        // // 设置鼠标移动显示停止2秒后隐藏
        // let timer: any;
        // function operationHide() {
        // 	clearTimeout(timer);
        // 	timer = setTimeout(function() {
        // 		$('.operation').fadeOut(300);
        // 	}, 1600);
        // }
        // operationHide();
        // function autoHide() {
        // 	$('.operation').show();
        // 	operationHide();
        // }
        // const doc = $(document);
        // // 鼠标移动
        // doc.on('mousemove.operationHide', function() {
        // 	autoHide();
        // });
        // // 移上时 关闭全局的移动事件
        // doc.on('mousemove.operationOver', '.operation', function(e) {
        // 	e.stopPropagation();
        // 	clearTimeout(timer);
        // });
        // let mask: any = $('.doc-img-preview-mask');
        // mask.remove();
        // // 创建dom
        // if (mask.length === 0) {
        // 	const zoomInIcon = new Icon(IconSet.ZOOM_IN, 20);
        // 	const zoomOutIcon = new Icon(IconSet.ZOOM_OUT, 20);
        // 	const fitIcon = new Icon(IconSet.SIZE_FIT, 20);
        // 	const originalIcon = new Icon(IconSet.SIZE_ORIGINAL, 20);
        // 	const closeIcon = new Icon(IconSet.CLOSE, 20);
        // 	mask = $(
        // 		'<div class="doc-img-preview-mask">' +
        // 		'<div class="doc-img-preview-holder">' +
        // 		'<div id="append-img"></div>' +
        // 		'</div>' +
        // 		'<div class="close">' +
        // 		closeIcon.toString() +
        // 		'</div>' +
        // 		'<div class="operation">' +
        // 		'<span title="放大" id="operation-add">' + zoomInIcon.toString() + '</span>' +
        // 		'<span title="缩小" id="operation-narrow">' + zoomOutIcon.toString() + '</span>' +
        // 		'<span title="实际大小" id="operation-original">' + originalIcon.toString() + '</span>' +
        // 		'<span title="适应屏幕" id="operation-adapt">' + fitIcon.toString() + '</span>' +
        // 		'</div>' +
        // 		'</div>'
        // 	);
        // 	const docObj: any = document;
        // 	const fullscreenElement =
        // 		docObj.fullscreenElement
        // 		|| docObj.mozFullscreenElement
        // 		|| docObj.webkitFullscreenElement;
        // 	if (fullscreenElement) {
        // 		// 如果当前是全屏状态，不执行
        // 		return;
        // 	} else {
        // 		$('body').append(mask);
        // 	}
        // }
        // // 图片容器
        // const holder = mask.find('.doc-img-preview-holder');
        // let imgH = 0;
        // let imgW = 0;
        // // 添加加载图
        // holder.append('<div class="icon icon-spinner" id="loading"></div>');
        // mask.show();
        // const img: any = new Image();
        // holder.find('#append-img').append(img);
        // // 图片加载完成显示图片
        // const imgObj: any = holder.find('img');
        // // 滚动条长度
        // let scrollLengthY = 0;
        // let scrollLengthX = 0;
        // const win: any = $(window);
        // imgObj.on('load', function() {
        // 	holder.html(img);
        // 	imgH = imgObj.height();
        // 	imgW = imgObj.width();
        // 	scrollLengthX = imgW - win.width();
        // 	scrollLengthY = imgH - win.height();
        // 	adapt();
        // 	imgStyle();
        // });
        // img.src = url;
        // // 图片节点
        // const imgS  = imgObj;
        // function imgStyle() {
        // 	const isWidth = imgS.width() > win.width();
        // 	const isHeight = imgS.height() > win.height();
        // 	if (isWidth && isHeight) {
        // 		imgS.css({
        // 			'top' : 0,
        // 			'left' : 0,
        // 			'transform': 'translate(0,0)'
        // 		});
        // 	} else if (isHeight) {
        // 		imgS.css({
        // 			'left' : '50%',
        // 			'top' : '0',
        // 			'transform': 'translate(-50%,0)'
        // 		});
        // 	} else if (isWidth) {
        // 		imgS.css({
        // 			'left' : 0,
        // 			'top' : '50%',
        // 			'transform': 'translate(0,-50%)'
        // 		});
        // 	} else {
        // 		imgS.css({
        // 			'top' : '50%',
        // 			'left' : '50%',
        // 			'transform': 'translate(-50%,-50%)'
        // 		});
        // 	}
        // }
        // /**
        //  * 变化后的滚动条位置
        //  * @zoom 传入操作名称
        //  */
        // let scrollT = 0;
        // let scrollL = 0;
        // function zoom(op: any) {
        // 	const windowH = win.height();
        // 	const windowW = win.width();
        // 	const maskTop = mask.scrollTop();
        // 	const maskLeft = mask.scrollLeft();
        // 	// 点击放大后Y轴的滚动值
        // 	const addTop = scrollLengthY * ((windowH / scrollLengthY) * 1.3) * ((windowH * 1.3 - windowH) / 2 / (windowH * 1.3));
        // 	// 点击缩小后Y轴的滚动值
        // 	const narrowTop = scrollLengthY * ((windowH / scrollLengthY) / 1.3) * ((windowH - windowH / 1.3) / 2 / (windowH / 1.3));
        // 	// 点击放大后X轴的滚动值
        // 	const addLeft = scrollLengthX * ((windowW / scrollLengthX) * 1.3) * ((windowW * 1.3 - windowW) / 2 / (windowW * 1.3));
        // 	// 点击缩小后X轴的滚动值
        // 	const narrowLeft = scrollLengthX * ((windowW / scrollLengthX) / 1.3) * ((windowW - windowW / 1.3) / 2 / (windowW / 1.3));
        // 	// 最大最小倍数的宽
        // 	const maxW = imgW * multipleMax;
        // 	const minW = imgW * multipleMin;
        // 	// 放大后的滚动值
        // 	if (op === 'add') {
        // 		scrollT = mask.scrollTop();
        // 		scrollL = mask.scrollLeft();
        // 		$('#operation-add').siblings().find('i').css('color', '#777');
        // 		if (maxW > imgS.width()) {
        // 			imgS.height(imgS.height() * 1.3);
        // 			imgS.width(imgS.width() * 1.3);
        // 			mask.scrollTop(maskTop * 1.3 + addTop);
        // 			mask.scrollLeft(maskLeft * 1.3 + addLeft);
        // 			if (imgS.height() > windowH) {
        // 				scrollT = scrollT * 1.3  - addTop;
        // 				scrollT = scrollT * (imgH / imgS.height());
        // 			} else if (imgS.width() > windowW) {
        // 				scrollL = scrollL * 1.3 + addLeft;
        // 				scrollL = scrollL * (imgW / imgS.width());
        // 			}
        // 		} else {
        // 			btnChange('add');
        // 		}
        // 	} else if (op === 'narrow') {
        // 		scrollT = mask.scrollTop();
        // 		scrollL = mask.scrollLeft();
        // 		$('#operation-narrow').siblings().find('i').css('color', '#777');
        // 		if (minW < imgS.width()) {
        // 			imgS.width(imgS.width() / 1.3);
        // 			imgS.height(imgS.height() / 1.3);
        // 			mask.scrollTop(maskTop / 1.3 - narrowTop );
        // 			mask.scrollLeft(maskLeft / 1.3 - narrowLeft);
        // 			if (imgS.height() > windowH) {
        // 				scrollT = scrollT / 1.3 + narrowTop  + narrowTop;
        // 				scrollT = scrollT * (imgH / imgS.height());
        // 			} else if (imgS.width() > windowW) {
        // 				scrollL = scrollL / 1.3 - narrowLeft;
        // 				scrollL = scrollL * (imgW / imgS.width());
        // 			}
        // 		} else {
        // 			btnChange('narrow');
        // 		}
        // 	} else if (op === 'original') {
        // 		if (imgS.height() > windowH || imgS.width() > windowW) {
        // 			mask.scrollTop(scrollT);
        // 			mask.scrollLeft(scrollL);
        // 		} else {
        // 			mask.scrollTop(0);
        // 			mask.scrollLeft(0);
        // 		}
        // 	}
        // }
        // /**
        //  * 传入按钮名
        //  * @param op
        //  */
        // function btnChange(op: any) {
        // 	if (op === 'add') {
        // 		const operationAdd = $('#operation-add');
        // 		operationAdd.find('i').css('color', '#ccc');
        // 	} else if (op === 'narrow') {
        // 		const operationNarrow = $('#operation-narrow');
        // 		operationNarrow.find('i').css('color', '#ccc');
        // 	} else if (op === 'original') {
        // 		const operationOriginal = $('#operation-original');
        // 		operationOriginal.find('i').css('color', '#ccc');
        // 		operationOriginal.siblings().find('i').css('color', '#777');
        // 	} else if (op === 'adapt') {
        // 		const operationAdapt = $('#operation-adapt');
        // 		operationAdapt.find('i').css('color', '#ccc');
        // 		operationAdapt.siblings().find('i').css('color', '#777');
        // 	}
        // }
        // // 图片的操作
        // const multipleMax = 2.5;
        // const multipleMin = 0.4;
        // // 放大
        // $('#operation-add').on('click', function() {
        // 	zoom('add');
        // 	imgStyle();
        // });
        // // 缩小
        // $('#operation-narrow').on('click', function() {
        // 	zoom('narrow');
        // 	imgStyle();
        // });
        // // 原图
        // $('#operation-original').on('click', function() {
        // 	imgS.width(imgW);
        // 	imgS.height(imgH);
        // 	imgStyle();
        // 	zoom('original');
        // 	btnChange('original');
        // });
        // // 适应
        // $('#operation-adapt').on('click', function() {
        // 	adapt();
        // 	imgStyle();
        // 	btnChange('adapt');
        // });
        // /**
        //  * 图片适应页面
        //  */
        // function adapt() {
        // 	// 适应页面的宽高
        // 	const adaptW = win.width() - 100 ;
        // 	const adaptH = win.height() - 100 ;
        // 	if (imgW > adaptW || imgH > adaptH) {
        // 		if (imgW / adaptW > imgH / adaptH) {
        // 			imgS.width(adaptW);
        // 			imgS.height(imgH * adaptW / imgW);
        // 		} else if (imgW / adaptW === imgH / adaptH) {
        // 			imgS.width(adaptW);
        // 			imgS.height(imgH * adaptW / imgW);
        // 		} else {
        // 			imgS.height(adaptH);
        // 			imgS.width(imgW * adaptH / imgH);
        // 		}
        // 	} else {
        // 		imgS.width(imgW);
        // 		imgS.height(imgH);
        // 	}
        // }
        // // 点击遮罩层关闭
        // mask.on('click', function() {
        // 	mask.hide();
        // 	mask.remove();
        // 	$(document).off('mousemove.operationHide');
        // 	$(document).off('keydown.hide-preview');
        // });
        // mask.on('click', 'img', function(e: any) {
        // 	e.stopPropagation();
        // });
        // mask.on('click', '.operation', function(e: any) {
        // 	e.stopPropagation();
        // });
        // // 如果遮罩层显示了按esc 退出
        // $(document).off('keydown.hide-preview').on('keydown.hide-preview', function(e) {
        // 	if (e.keyCode === 27) {
        // 		mask.trigger('click');
        // 	}
        // });
    };
    return ImagePreview;
}());

//XRegExp 3.0.0 <xregexp.com> MIT License
var XRegExp=function(a){function u(a,d,e,f,g){var h;if(a[c]={captureNames:d},g)return a;if(a.__proto__)a.__proto__=b.prototype;else for(h in b.prototype)a[h]=b.prototype[h];return a[c].source=e,a[c].flags=f?f.split('').sort().join(''):f,a;}function v(a){return e.replace.call(a,/([\s\S])(?=[\s\S]*\1)/g,'');}function w(d,f){if(!b.isRegExp(d))throw new TypeError('Type RegExp expected');var g=d[c]||{},h=y(d),i='',j='',k=null,l=null;return f=f||{},f.removeG&&(j+='g'),f.removeY&&(j+='y'),j&&(h=e.replace.call(h,new RegExp('['+j+']+','g'),'')),f.addG&&(i+='g'),f.addY&&(i+='y'),i&&(h=v(h+i)),f.isInternalOnly||(g.source!==a&&(k=g.source),null!=g.flags&&(l=i?v(g.flags+i):g.flags)),d=u(new RegExp(d.source,h),z(d)?g.captureNames.slice(0):null,k,l,f.isInternalOnly);}function x(a){return parseInt(a,16);}function y(a){return q?a.flags:e.exec.call(/\/([a-z]*)$/i,RegExp.prototype.toString.call(a))[1];}function z(a){return !(!a[c]||!a[c].captureNames);}function A(a){return parseInt(a,10).toString(16);}function B(a,b){var d,c=a.length;for(d=0;c>d;++d)if(a[d]===b)return d;return -1;}function C(a,b){return s.call(a)==='[object '+b+']';}function D(a,b,c){return e.test.call(c.indexOf('x')>-1?/^(?:\s+|#.*|\(\?#[^)]*\))*(?:[?*+]|{\d+(?:,\d*)?})/:/^(?:\(\?#[^)]*\))*(?:[?*+]|{\d+(?:,\d*)?})/,a.slice(b));}function E(a){for(;a.length<4;)a='0'+a;return a;}function F(a,b){var c;if(v(b)!==b)throw new SyntaxError('Invalid duplicate regex flag '+b);for(a=e.replace.call(a,/^\(\?([\w$]+)\)/,function(a,c){if(e.test.call(/[gy]/,c))throw new SyntaxError('Cannot use flag g or y in mode modifier '+a);return b=v(b+c),'';}),c=0;c<b.length;++c)if(!r[b.charAt(c)])throw new SyntaxError('Unknown regex flag '+b.charAt(c));return {pattern:a,flags:b};}function G(a){var c={};return C(a,'String')?(b.forEach(a,/[^\s,]+/,function(a){c[a]=!0;}),c):a;}function H(a){if(!/^[\w$]$/.test(a))throw new Error('Flag must be a single character A-Za-z0-9_$');r[a]=!0;}function I(a,c,d,e,f){for(var k,l,g=i.length,h=a.charAt(d),j=null;g--;)if(l=i[g],!(l.leadChar&&l.leadChar!==h||l.scope!==e&&'all'!==l.scope||l.flag&&-1===c.indexOf(l.flag))&&(k=b.exec(a,l.regex,d,'sticky'))){j={matchLength:k[0].length,output:l.handler.call(f,k,e,c),reparse:l.reparse};break;}return j;}function J(a){d.astral=a;}function K(a){RegExp.prototype.exec=(a?f:e).exec,RegExp.prototype.test=(a?f:e).test,String.prototype.match=(a?f:e).match,String.prototype.replace=(a?f:e).replace,String.prototype.split=(a?f:e).split,d.natives=a;}function L(a){if(null==a)throw new TypeError('Cannot convert null or undefined to object');return a;}var b,t,c='xregexp',d={astral:!1,natives:!1},e={exec:RegExp.prototype.exec,test:RegExp.prototype.test,match:String.prototype.match,replace:String.prototype.replace,split:String.prototype.split},f={},g={},h={},i=[],j='default',k='class',l={'default':/\\(?:0(?:[0-3][0-7]{0,2}|[4-7][0-7]?)?|[1-9]\d*|x[\dA-Fa-f]{2}|u(?:[\dA-Fa-f]{4}|{[\dA-Fa-f]+})|c[A-Za-z]|[\s\S])|\(\?[:=!]|[?*+]\?|{\d+(?:,\d*)?}\??|[\s\S]/,'class':/\\(?:[0-3][0-7]{0,2}|[4-7][0-7]?|x[\dA-Fa-f]{2}|u(?:[\dA-Fa-f]{4}|{[\dA-Fa-f]+})|c[A-Za-z]|[\s\S])|[\s\S]/},m=/\$(?:{([\w$]+)}|(\d\d?|[\s\S]))/g,n=e.exec.call(/()??/,'')[1]===a,o=function(){var a=!0;try{}catch(b){a=!1;}return a;}(),p=function(){var a=!0;try{}catch(b){a=!1;}return a;}(),q=/a/.flags!==a,r={g:!0,i:!0,m:!0,u:o,y:p},s={}.toString;return b=function(c,d){var n,o,p,q,r,f={hasNamedCapture:!1,captureNames:[]},g=j,i='',m=0;if(b.isRegExp(c)){if(d!==a)throw new TypeError('Cannot supply flags when copying a RegExp');return w(c);}if(c=c===a?'':String(c),d=d===a?'':String(d),b.isInstalled('astral')&&-1===d.indexOf('A')&&(d+='A'),h[c]||(h[c]={}),!h[c][d]){for(n=F(c,d),q=n.pattern,r=n.flags;m<q.length;){do n=I(q,r,m,g,f),n&&n.reparse&&(q=q.slice(0,m)+n.output+q.slice(m+n.matchLength));while(n&&n.reparse);n?(i+=n.output,m+=n.matchLength||1):(o=b.exec(q,l[g],m,'sticky')[0],i+=o,m+=o.length,'['===o&&g===j?g=k:']'===o&&g===k&&(g=j));}h[c][d]={pattern:e.replace.call(i,/\(\?:\)(?=\(\?:\))|^\(\?:\)|\(\?:\)$/g,''),flags:e.replace.call(r,/[^gimuy]+/g,''),captures:f.hasNamedCapture?f.captureNames:null};}return p=h[c][d],u(new RegExp(p.pattern,p.flags),p.captures,c,d);},b.prototype=new RegExp,b.version='3.0.0',b.addToken=function(a,c,d){d=d||{};var g,f=d.optionalFlags;if(d.flag&&H(d.flag),f)for(f=e.split.call(f,''),g=0;g<f.length;++g)H(f[g]);i.push({regex:w(a,{addG:!0,addY:p,isInternalOnly:!0}),handler:c,scope:d.scope||j,flag:d.flag,reparse:d.reparse,leadChar:d.leadChar}),b.cache.flush('patterns');},b.cache=function(a,c){return g[a]||(g[a]={}),g[a][c]||(g[a][c]=b(a,c));},b.cache.flush=function(a){'patterns'===a?h={}:g={};},b.escape=function(a){return e.replace.call(L(a),/[-[\]{}()*+?.,\\^$|#\s]/g,'\\$&');},b.exec=function(a,b,d,e){var i,j,g='g',h=!1;return h=p&&!!(e||b.sticky&&e!==!1),h&&(g+='y'),b[c]=b[c]||{},j=b[c][g]||(b[c][g]=w(b,{addG:!0,addY:h,removeY:e===!1,isInternalOnly:!0})),j.lastIndex=d=d||0,i=f.exec.call(j,a),e&&i&&i.index!==d&&(i=null),b.global&&(b.lastIndex=i?j.lastIndex:0),i;},b.forEach=function(a,c,d){for(var g,e=0,f=-1;g=b.exec(a,c,e);)d(g,++f,a,c),e=g.index+(g[0].length||1);},b.globalize=function(a){return w(a,{addG:!0});},b.install=function(a){a=G(a),!d.astral&&a.astral&&J(!0),!d.natives&&a.natives&&K(!0);},b.isInstalled=function(a){return !!d[a];},b.isRegExp=function(a){return '[object RegExp]'===s.call(a);},b.match=function(a,b,d){var h,i,f=b.global&&'one'!==d||'all'===d,g=(f?'g':'')+(b.sticky?'y':'')||'noGY';return b[c]=b[c]||{},i=b[c][g]||(b[c][g]=w(b,{addG:!!f,addY:!!b.sticky,removeG:'one'===d,isInternalOnly:!0})),h=e.match.call(L(a),i),b.global&&(b.lastIndex='one'===d&&h?h.index+h[0].length:0),f?h||[]:h&&h[0];},b.matchChain=function(a,c){return function d(a,e){var i,f=c[e].regex?c[e]:{regex:c[e]},g=[],h=function(a){if(f.backref){if(!(a.hasOwnProperty(f.backref)||+f.backref<a.length))throw new ReferenceError('Backreference to undefined group: '+f.backref);g.push(a[f.backref]||'');}else g.push(a[0]);};for(i=0;i<a.length;++i)b.forEach(a[i],f.regex,h);return e!==c.length-1&&g.length?d(g,e+1):g;}([a],0);},b.replace=function(a,d,e,g){var l,h=b.isRegExp(d),i=d.global&&'one'!==g||'all'===g,j=(i?'g':'')+(d.sticky?'y':'')||'noGY',k=d;return h?(d[c]=d[c]||{},k=d[c][j]||(d[c][j]=w(d,{addG:!!i,addY:!!d.sticky,removeG:'one'===g,isInternalOnly:!0}))):i&&(k=new RegExp(b.escape(String(d)),'g')),l=f.replace.call(L(a),k,e),h&&d.global&&(d.lastIndex=0),l;},b.replaceEach=function(a,c){var d,e;for(d=0;d<c.length;++d)e=c[d],a=b.replace(a,e[0],e[1],e[2]);return a;},b.split=function(a,b,c){return f.split.call(L(a),b,c);},b.test=function(a,c,d,e){return !!b.exec(a,c,d,e);},b.uninstall=function(a){a=G(a),d.astral&&a.astral&&J(!1),d.natives&&a.natives&&K(!1);},b.union=function(a,d){var i,j,k,m,f=/(\()(?!\?)|\\([1-9]\d*)|\\[\s\S]|\[(?:[^\\\]]|\\[\s\S])*]/g,g=[],h=0,l=function(a,b,c){var d=j[h-i];if(b){if(++h,d)return '(?<'+d+'>';}else if(c)return '\\'+(+c+i);return a;};if(!C(a,'Array')||!a.length)throw new TypeError('Must provide a nonempty array of patterns to merge');for(m=0;m<a.length;++m)k=a[m],b.isRegExp(k)?(i=h,j=k[c]&&k[c].captureNames||[],g.push(e.replace.call(b(k.source).source,f,l))):g.push(b.escape(k));return b(g.join('|'),d);},f.exec=function(b){var g,h,i,d=this.lastIndex,f=e.exec.apply(this,arguments);if(f){if(!n&&f.length>1&&B(f,'')>-1&&(h=w(this,{removeG:!0,isInternalOnly:!0}),e.replace.call(String(b).slice(f.index),h,function(){var c,b=arguments.length;for(c=1;b-2>c;++c)arguments[c]===a&&(f[c]=a);})),this[c]&&this[c].captureNames)for(i=1;i<f.length;++i)g=this[c].captureNames[i-1],g&&(f[g]=f[i]);this.global&&!f[0].length&&this.lastIndex>f.index&&(this.lastIndex=f.index);}return this.global||(this.lastIndex=d),f;},f.test=function(a){return !!f.exec.call(this,a);},f.match=function(a){var c;if(b.isRegExp(a)){if(a.global)return c=e.match.apply(this,arguments),a.lastIndex=0,c;}else a=new RegExp(a);return f.exec.call(a,L(this));},f.replace=function(d,f){var h,i,j,g=b.isRegExp(d);return g?(d[c]&&(i=d[c].captureNames),h=d.lastIndex):d+='',j=C(f,'Function')?e.replace.call(String(this),d,function(){var c,b=arguments;if(i)for(b[0]=new String(b[0]),c=0;c<i.length;++c)i[c]&&(b[0][i[c]]=b[c+1]);return g&&d.global&&(d.lastIndex=b[b.length-2]+b[0].length),f.apply(a,b);}):e.replace.call(null==this?this:String(this),d,function(){var a=arguments;return e.replace.call(String(f),m,function(b,c,d){var e;if(c){if(e=+c,e<=a.length-3)return a[e]||'';if(e=i?B(i,c):-1,0>e)throw new SyntaxError('Backreference to undefined group '+b);return a[e+1]||'';}if('$'===d)return '$';if('&'===d||0===+d)return a[0];if('`'===d)return a[a.length-1].slice(0,a[a.length-2]);if('\''===d)return a[a.length-1].slice(a[a.length-2]+a[0].length);if(d=+d,!isNaN(d)){if(d>a.length-3)throw new SyntaxError('Backreference to undefined group '+b);return a[d]||'';}throw new SyntaxError('Invalid token '+b);});}),g&&(d.global?d.lastIndex=0:d.lastIndex=h),j;},f.split=function(c,d){if(!b.isRegExp(c))return e.split.apply(this,arguments);var j,f=String(this),g=[],h=c.lastIndex,i=0;return d=(d===a?-1:d)>>>0,b.forEach(f,c,function(a){a.index+a[0].length>i&&(g.push(f.slice(i,a.index)),a.length>1&&a.index<f.length&&Array.prototype.push.apply(g,a.slice(1)),j=a[0].length,i=a.index+j);}),i===f.length?(!e.test.call(c,'')||j)&&g.push(''):g.push(f.slice(i)),c.lastIndex=h,g.length>d?g.slice(0,d):g;},t=b.addToken,t(/\\([ABCE-RTUVXYZaeg-mopqyz]|c(?![A-Za-z])|u(?![\dA-Fa-f]{4}|{[\dA-Fa-f]+})|x(?![\dA-Fa-f]{2}))/,function(a,b){if('B'===a[1]&&b===j)return a[0];throw new SyntaxError('Invalid escape '+a[0]);},{scope:'all',leadChar:'\\'}),t(/\\u{([\dA-Fa-f]+)}/,function(a,b,c){var d=x(a[1]);if(d>1114111)throw new SyntaxError('Invalid Unicode code point '+a[0]);if(65535>=d)return '\\u'+E(A(d));if(o&&c.indexOf('u')>-1)return a[0];throw new SyntaxError('Cannot use Unicode code point above \\u{FFFF} without flag u');},{scope:'all',leadChar:'\\'}),t(/\[(\^?)]/,function(a){return a[1]?'[\\s\\S]':'\\b\\B';},{leadChar:'['}),t(/\(\?#[^)]*\)/,function(a,b,c){return D(a.input,a.index+a[0].length,c)?'':'(?:)';},{leadChar:'('}),t(/\s+|#.*/,function(a,b,c){return D(a.input,a.index+a[0].length,c)?'':'(?:)';},{flag:'x'}),t(/\./,function(){return '[\\s\\S]';},{flag:'s',leadChar:'.'}),t(/\\k<([\w$]+)>/,function(a){var b=isNaN(a[1])?B(this.captureNames,a[1])+1:+a[1],c=a.index+a[0].length;if(!b||b>this.captureNames.length)throw new SyntaxError('Backreference to undefined group '+a[0]);return '\\'+b+(c===a.input.length||isNaN(a.input.charAt(c))?'':'(?:)');},{leadChar:'\\'}),t(/\\(\d+)/,function(a,b){if(!(b===j&&/^[1-9]/.test(a[1])&&+a[1]<=this.captureNames.length)&&'0'!==a[1])throw new SyntaxError('Cannot use octal escape or backreference to undefined group '+a[0]);return a[0];},{scope:'all',leadChar:'\\'}),t(/\(\?P?<([\w$]+)>/,function(a){if(!isNaN(a[1]))throw new SyntaxError('Cannot use integer as capture name '+a[0]);if('length'===a[1]||'__proto__'===a[1])throw new SyntaxError('Cannot use reserved word as capture name '+a[0]);if(B(this.captureNames,a[1])>-1)throw new SyntaxError('Cannot use same name for multiple groups '+a[0]);return this.captureNames.push(a[1]),this.hasNamedCapture=!0,'(';},{leadChar:'('}),t(/\((?!\?)/,function(a,b,c){return c.indexOf('n')>-1?'(?:':(this.captureNames.push(null),'(');},{optionalFlags:'n',leadChar:'('}),b;}();

// NOTE FROM MIKE: this is a concatenation of the following XRegExp
// addons: unicode-base.js, unicode-categories.js (with all categories
// other than 'L' and 'Nd' removed to save space), and
// unicode-scripts.js.

/*!
	* XRegExp Unicode Base 3.0.0
	* <http://xregexp.com/>
	* Steven Levithan (c) 2008-2015 MIT License
	*/

/**
 * Adds base support for Unicode matching:
 * - Adds syntax `\p{..}` for matching Unicode tokens. Tokens can be inverted using `\P{..}` or
 *   `\p{^..}`. Token names ignore case, spaces, hyphens, and underscores. You can omit the brackets
 *   for token names that are a single letter (e.g. `\pL` or `PL`).
 * - Adds flag A (astral), which enables 21-bit Unicode support.
 * - Adds the `XRegExp.addUnicodeData` method used by other addons to provide character data.
 *
 * Unicode Base relies on externally provided Unicode character data. Official addons are available
 * to provide data for Unicode categories, scripts, blocks, and properties.
 *
 * @requires XRegExp
 */
(function(XRegExp) {

	// Storage for Unicode data
	var unicode = {};

	/* ==============================
		* Private functions
		* ============================== */

	// Generates a token lookup name: lowercase, with hyphens, spaces, and underscores removed
	function normalize(name) {
		return name.replace(/[- _]+/g, '').toLowerCase();
	}

	// Adds leading zeros if shorter than four characters
	function pad4(str) {
		while (str.length < 4) {
			str = '0' + str;
		}
		return str;
	}

	// Converts a hexadecimal number to decimal
	function dec(hex) {
		return parseInt(hex, 16);
	}

	// Converts a decimal number to hexadecimal
	function hex(dec) {
		return parseInt(dec, 10).toString(16);
	}

	// Gets the decimal code of a literal code unit, \xHH, \uHHHH, or a backslash-escaped literal
	function charCode(chr) {
		var esc = /^\\[xu](.+)/.exec(chr);
		return esc ?
			dec(esc[1]) :
			chr.charCodeAt(chr.charAt(0) === '\\' ? 1 : 0);
	}

	// Inverts a list of ordered BMP characters and ranges
	function invertBmp(range) {
		var output = '',
			lastEnd = -1,
			start;
		XRegExp.forEach(range, /(\\x..|\\u....|\\?[\s\S])(?:-(\\x..|\\u....|\\?[\s\S]))?/, function(m) {
			start = charCode(m[1]);
			if (start > (lastEnd + 1)) {
				output += '\\u' + pad4(hex(lastEnd + 1));
				if (start > (lastEnd + 2)) {
					output += '-\\u' + pad4(hex(start - 1));
				}
			}
			lastEnd = charCode(m[2] || m[1]);
		});
		if (lastEnd < 0xFFFF) {
			output += '\\u' + pad4(hex(lastEnd + 1));
			if (lastEnd < 0xFFFE) {
				output += '-\\uFFFF';
			}
		}
		return output;
	}

	// Generates an inverted BMP range on first use
	function cacheInvertedBmp(slug) {
		var prop = 'b!';
		return unicode[slug][prop] || (
			unicode[slug][prop] = invertBmp(unicode[slug].bmp)
		);
	}

	// Combines and optionally negates BMP and astral data
	function buildAstral(slug, isNegated) {
		var item = unicode[slug],
			combined = '';
		if (item.bmp && !item.isBmpLast) {
			combined = '[' + item.bmp + ']' + (item.astral ? '|' : '');
		}
		if (item.astral) {
			combined += item.astral;
		}
		if (item.isBmpLast && item.bmp) {
			combined += (item.astral ? '|' : '') + '[' + item.bmp + ']';
		}
		// Astral Unicode tokens always match a code point, never a code unit
		return isNegated ?
			'(?:(?!' + combined + ')(?:[\uD800-\uDBFF][\uDC00-\uDFFF]|[\0-\uFFFF]))' :
			'(?:' + combined + ')';
	}

	// Builds a complete astral pattern on first use
	function cacheAstral(slug, isNegated) {
		var prop = isNegated ? 'a!' : 'a=';
		return unicode[slug][prop] || (
			unicode[slug][prop] = buildAstral(slug, isNegated)
		);
	}

	/* ==============================
		* Core functionality
		* ============================== */

	/*
		* Add Unicode token syntax: \p{..}, \P{..}, \p{^..}. Also add astral mode (flag A).
		*/
	XRegExp.addToken(
		// Use `*` instead of `+` to avoid capturing `^` as the token name in `\p{^}`
		/\\([pP])(?:{(\^?)([^}]*)}|([A-Za-z]))/,
		function(match, scope, flags) {
			var ERR_DOUBLE_NEG = 'Invalid double negation ',
				ERR_UNKNOWN_NAME = 'Unknown Unicode token ',
				ERR_UNKNOWN_REF = 'Unicode token missing data ',
				ERR_ASTRAL_ONLY = 'Astral mode required for Unicode token ',
				ERR_ASTRAL_IN_CLASS = 'Astral mode does not support Unicode tokens within character classes',
				// Negated via \P{..} or \p{^..}
				isNegated = match[1] === 'P' || !!match[2],
				// Switch from BMP (0-FFFF) to astral (0-10FFFF) mode via flag A
				isAstralMode = flags.indexOf('A') > -1,
				// Token lookup name. Check `[4]` first to avoid passing `undefined` via `\p{}`
				slug = normalize(match[4] || match[3]),
				// Token data object
				item = unicode[slug];

			if (match[1] === 'P' && match[2]) {
				throw new SyntaxError(ERR_DOUBLE_NEG + match[0]);
			}
			if (!unicode.hasOwnProperty(slug)) {
				throw new SyntaxError(ERR_UNKNOWN_NAME + match[0]);
			}

			// Switch to the negated form of the referenced Unicode token
			if (item.inverseOf) {
				slug = normalize(item.inverseOf);
				if (!unicode.hasOwnProperty(slug)) {
					throw new ReferenceError(ERR_UNKNOWN_REF + match[0] + ' -> ' + item.inverseOf);
				}
				item = unicode[slug];
				isNegated = !isNegated;
			}

			if (!(item.bmp || isAstralMode)) {
				throw new SyntaxError(ERR_ASTRAL_ONLY + match[0]);
			}
			if (isAstralMode) {
				if (scope === 'class') {
					throw new SyntaxError(ERR_ASTRAL_IN_CLASS);
				}

				return cacheAstral(slug, isNegated);
			}

			return scope === 'class' ?
				(isNegated ? cacheInvertedBmp(slug) : item.bmp) :
				(isNegated ? '[^' : '[') + item.bmp + ']';
		},
		{
			scope: 'all',
			optionalFlags: 'A',
			leadChar: '\\'
		}
	);

	/**
	 * Adds to the list of Unicode tokens that XRegExp regexes can match via `\p` or `\P`.
	 *
	 * @memberOf XRegExp
	 * @param {Array} data Objects with named character ranges. Each object may have properties `name`,
	 *   `alias`, `isBmpLast`, `inverseOf`, `bmp`, and `astral`. All but `name` are optional, although
	 *   one of `bmp` or `astral` is required (unless `inverseOf` is set). If `astral` is absent, the
	 *   `bmp` data is used for BMP and astral modes. If `bmp` is absent, the name errors in BMP mode
	 *   but works in astral mode. If both `bmp` and `astral` are provided, the `bmp` data only is used
	 *   in BMP mode, and the combination of `bmp` and `astral` data is used in astral mode.
	 *   `isBmpLast` is needed when a token matches orphan high surrogates *and* uses surrogate pairs
	 *   to match astral code points. The `bmp` and `astral` data should be a combination of literal
	 *   characters and `\xHH` or `\uHHHH` escape sequences, with hyphens to create ranges. Any regex
	 *   metacharacters in the data should be escaped, apart from range-creating hyphens. The `astral`
	 *   data can additionally use character classes and alternation, and should use surrogate pairs to
	 *   represent astral code points. `inverseOf` can be used to avoid duplicating character data if a
	 *   Unicode token is defined as the exact inverse of another token.
	 * @example
	 *
	 * // Basic use
	 * XRegExp.addUnicodeData([{
 *   name: 'XDigit',
 *   alias: 'Hexadecimal',
 *   bmp: '0-9A-Fa-f'
 * }]);
	 * XRegExp('\\p{XDigit}:\\p{Hexadecimal}+').test('0:3D'); // -> true
	 */
	XRegExp.addUnicodeData = function(data) {
		var ERR_NO_NAME = 'Unicode token requires name',
			ERR_NO_DATA = 'Unicode token has no character data ',
			item,
			i;

		for (i = 0; i < data.length; ++i) {
			item = data[i];
			if (!item.name) {
				throw new Error(ERR_NO_NAME);
			}
			if (!(item.inverseOf || item.bmp || item.astral)) {
				throw new Error(ERR_NO_DATA + item.name);
			}
			unicode[normalize(item.name)] = item;
			if (item.alias) {
				unicode[normalize(item.alias)] = item;
			}
		}

		// Reset the pattern cache used by the `XRegExp` constructor, since the same pattern and
		// flags might now produce different results
		XRegExp.cache.flush('patterns');
	};

}(XRegExp));

/*!
	* XRegExp Unicode Categories 3.0.0
	* <http://xregexp.com/>
	* Steven Levithan (c) 2010-2015 MIT License
	* Unicode data provided by Mathias Bynens <http://mathiasbynens.be/>
	*/

/**
 * Adds support for Unicode's general categories. E.g., `\p{Lu}` or `\p{Uppercase Letter}`. See
 * category descriptions in UAX #44 <http://unicode.org/reports/tr44/#GC_Values_Table>. Token names
 * are case insensitive, and any spaces, hyphens, and underscores are ignored.
 *
 * Uses Unicode 8.0.0.
 *
 * @requires XRegExp, Unicode Base
 */
(function(XRegExp) {

	if (!XRegExp.addUnicodeData) {
		throw new ReferenceError('Unicode Base must be loaded before Unicode Categories');
	}

	XRegExp.addUnicodeData([
		{
			name: 'L',
			alias: 'Letter',
			bmp: 'A-Za-z\xAA\xB5\xBA\xC0-\xD6\xD8-\xF6\xF8-\u02C1\u02C6-\u02D1\u02E0-\u02E4\u02EC\u02EE\u0370-\u0374\u0376\u0377\u037A-\u037D\u037F\u0386\u0388-\u038A\u038C\u038E-\u03A1\u03A3-\u03F5\u03F7-\u0481\u048A-\u052F\u0531-\u0556\u0559\u0561-\u0587\u05D0-\u05EA\u05F0-\u05F2\u0620-\u064A\u066E\u066F\u0671-\u06D3\u06D5\u06E5\u06E6\u06EE\u06EF\u06FA-\u06FC\u06FF\u0710\u0712-\u072F\u074D-\u07A5\u07B1\u07CA-\u07EA\u07F4\u07F5\u07FA\u0800-\u0815\u081A\u0824\u0828\u0840-\u0858\u08A0-\u08B4\u0904-\u0939\u093D\u0950\u0958-\u0961\u0971-\u0980\u0985-\u098C\u098F\u0990\u0993-\u09A8\u09AA-\u09B0\u09B2\u09B6-\u09B9\u09BD\u09CE\u09DC\u09DD\u09DF-\u09E1\u09F0\u09F1\u0A05-\u0A0A\u0A0F\u0A10\u0A13-\u0A28\u0A2A-\u0A30\u0A32\u0A33\u0A35\u0A36\u0A38\u0A39\u0A59-\u0A5C\u0A5E\u0A72-\u0A74\u0A85-\u0A8D\u0A8F-\u0A91\u0A93-\u0AA8\u0AAA-\u0AB0\u0AB2\u0AB3\u0AB5-\u0AB9\u0ABD\u0AD0\u0AE0\u0AE1\u0AF9\u0B05-\u0B0C\u0B0F\u0B10\u0B13-\u0B28\u0B2A-\u0B30\u0B32\u0B33\u0B35-\u0B39\u0B3D\u0B5C\u0B5D\u0B5F-\u0B61\u0B71\u0B83\u0B85-\u0B8A\u0B8E-\u0B90\u0B92-\u0B95\u0B99\u0B9A\u0B9C\u0B9E\u0B9F\u0BA3\u0BA4\u0BA8-\u0BAA\u0BAE-\u0BB9\u0BD0\u0C05-\u0C0C\u0C0E-\u0C10\u0C12-\u0C28\u0C2A-\u0C39\u0C3D\u0C58-\u0C5A\u0C60\u0C61\u0C85-\u0C8C\u0C8E-\u0C90\u0C92-\u0CA8\u0CAA-\u0CB3\u0CB5-\u0CB9\u0CBD\u0CDE\u0CE0\u0CE1\u0CF1\u0CF2\u0D05-\u0D0C\u0D0E-\u0D10\u0D12-\u0D3A\u0D3D\u0D4E\u0D5F-\u0D61\u0D7A-\u0D7F\u0D85-\u0D96\u0D9A-\u0DB1\u0DB3-\u0DBB\u0DBD\u0DC0-\u0DC6\u0E01-\u0E30\u0E32\u0E33\u0E40-\u0E46\u0E81\u0E82\u0E84\u0E87\u0E88\u0E8A\u0E8D\u0E94-\u0E97\u0E99-\u0E9F\u0EA1-\u0EA3\u0EA5\u0EA7\u0EAA\u0EAB\u0EAD-\u0EB0\u0EB2\u0EB3\u0EBD\u0EC0-\u0EC4\u0EC6\u0EDC-\u0EDF\u0F00\u0F40-\u0F47\u0F49-\u0F6C\u0F88-\u0F8C\u1000-\u102A\u103F\u1050-\u1055\u105A-\u105D\u1061\u1065\u1066\u106E-\u1070\u1075-\u1081\u108E\u10A0-\u10C5\u10C7\u10CD\u10D0-\u10FA\u10FC-\u1248\u124A-\u124D\u1250-\u1256\u1258\u125A-\u125D\u1260-\u1288\u128A-\u128D\u1290-\u12B0\u12B2-\u12B5\u12B8-\u12BE\u12C0\u12C2-\u12C5\u12C8-\u12D6\u12D8-\u1310\u1312-\u1315\u1318-\u135A\u1380-\u138F\u13A0-\u13F5\u13F8-\u13FD\u1401-\u166C\u166F-\u167F\u1681-\u169A\u16A0-\u16EA\u16F1-\u16F8\u1700-\u170C\u170E-\u1711\u1720-\u1731\u1740-\u1751\u1760-\u176C\u176E-\u1770\u1780-\u17B3\u17D7\u17DC\u1820-\u1877\u1880-\u18A8\u18AA\u18B0-\u18F5\u1900-\u191E\u1950-\u196D\u1970-\u1974\u1980-\u19AB\u19B0-\u19C9\u1A00-\u1A16\u1A20-\u1A54\u1AA7\u1B05-\u1B33\u1B45-\u1B4B\u1B83-\u1BA0\u1BAE\u1BAF\u1BBA-\u1BE5\u1C00-\u1C23\u1C4D-\u1C4F\u1C5A-\u1C7D\u1CE9-\u1CEC\u1CEE-\u1CF1\u1CF5\u1CF6\u1D00-\u1DBF\u1E00-\u1F15\u1F18-\u1F1D\u1F20-\u1F45\u1F48-\u1F4D\u1F50-\u1F57\u1F59\u1F5B\u1F5D\u1F5F-\u1F7D\u1F80-\u1FB4\u1FB6-\u1FBC\u1FBE\u1FC2-\u1FC4\u1FC6-\u1FCC\u1FD0-\u1FD3\u1FD6-\u1FDB\u1FE0-\u1FEC\u1FF2-\u1FF4\u1FF6-\u1FFC\u2071\u207F\u2090-\u209C\u2102\u2107\u210A-\u2113\u2115\u2119-\u211D\u2124\u2126\u2128\u212A-\u212D\u212F-\u2139\u213C-\u213F\u2145-\u2149\u214E\u2183\u2184\u2C00-\u2C2E\u2C30-\u2C5E\u2C60-\u2CE4\u2CEB-\u2CEE\u2CF2\u2CF3\u2D00-\u2D25\u2D27\u2D2D\u2D30-\u2D67\u2D6F\u2D80-\u2D96\u2DA0-\u2DA6\u2DA8-\u2DAE\u2DB0-\u2DB6\u2DB8-\u2DBE\u2DC0-\u2DC6\u2DC8-\u2DCE\u2DD0-\u2DD6\u2DD8-\u2DDE\u2E2F\u3005\u3006\u3031-\u3035\u303B\u303C\u3041-\u3096\u309D-\u309F\u30A1-\u30FA\u30FC-\u30FF\u3105-\u312D\u3131-\u318E\u31A0-\u31BA\u31F0-\u31FF\u3400-\u4DB5\u4E00-\u9FD5\uA000-\uA48C\uA4D0-\uA4FD\uA500-\uA60C\uA610-\uA61F\uA62A\uA62B\uA640-\uA66E\uA67F-\uA69D\uA6A0-\uA6E5\uA717-\uA71F\uA722-\uA788\uA78B-\uA7AD\uA7B0-\uA7B7\uA7F7-\uA801\uA803-\uA805\uA807-\uA80A\uA80C-\uA822\uA840-\uA873\uA882-\uA8B3\uA8F2-\uA8F7\uA8FB\uA8FD\uA90A-\uA925\uA930-\uA946\uA960-\uA97C\uA984-\uA9B2\uA9CF\uA9E0-\uA9E4\uA9E6-\uA9EF\uA9FA-\uA9FE\uAA00-\uAA28\uAA40-\uAA42\uAA44-\uAA4B\uAA60-\uAA76\uAA7A\uAA7E-\uAAAF\uAAB1\uAAB5\uAAB6\uAAB9-\uAABD\uAAC0\uAAC2\uAADB-\uAADD\uAAE0-\uAAEA\uAAF2-\uAAF4\uAB01-\uAB06\uAB09-\uAB0E\uAB11-\uAB16\uAB20-\uAB26\uAB28-\uAB2E\uAB30-\uAB5A\uAB5C-\uAB65\uAB70-\uABE2\uAC00-\uD7A3\uD7B0-\uD7C6\uD7CB-\uD7FB\uF900-\uFA6D\uFA70-\uFAD9\uFB00-\uFB06\uFB13-\uFB17\uFB1D\uFB1F-\uFB28\uFB2A-\uFB36\uFB38-\uFB3C\uFB3E\uFB40\uFB41\uFB43\uFB44\uFB46-\uFBB1\uFBD3-\uFD3D\uFD50-\uFD8F\uFD92-\uFDC7\uFDF0-\uFDFB\uFE70-\uFE74\uFE76-\uFEFC\uFF21-\uFF3A\uFF41-\uFF5A\uFF66-\uFFBE\uFFC2-\uFFC7\uFFCA-\uFFCF\uFFD2-\uFFD7\uFFDA-\uFFDC',
			astral: '\uD86E[\uDC00-\uDC1D\uDC20-\uDFFF]|\uD86D[\uDC00-\uDF34\uDF40-\uDFFF]|\uD869[\uDC00-\uDED6\uDF00-\uDFFF]|\uD803[\uDC00-\uDC48\uDC80-\uDCB2\uDCC0-\uDCF2]|\uD83A[\uDC00-\uDCC4]|\uD801[\uDC00-\uDC9D\uDD00-\uDD27\uDD30-\uDD63\uDE00-\uDF36\uDF40-\uDF55\uDF60-\uDF67]|\uD800[\uDC00-\uDC0B\uDC0D-\uDC26\uDC28-\uDC3A\uDC3C\uDC3D\uDC3F-\uDC4D\uDC50-\uDC5D\uDC80-\uDCFA\uDE80-\uDE9C\uDEA0-\uDED0\uDF00-\uDF1F\uDF30-\uDF40\uDF42-\uDF49\uDF50-\uDF75\uDF80-\uDF9D\uDFA0-\uDFC3\uDFC8-\uDFCF]|\uD80D[\uDC00-\uDC2E]|\uD87E[\uDC00-\uDE1D]|\uD81B[\uDF00-\uDF44\uDF50\uDF93-\uDF9F]|[\uD80C\uD840-\uD868\uD86A-\uD86C\uD86F-\uD872][\uDC00-\uDFFF]|\uD805[\uDC80-\uDCAF\uDCC4\uDCC5\uDCC7\uDD80-\uDDAE\uDDD8-\uDDDB\uDE00-\uDE2F\uDE44\uDE80-\uDEAA\uDF00-\uDF19]|\uD81A[\uDC00-\uDE38\uDE40-\uDE5E\uDED0-\uDEED\uDF00-\uDF2F\uDF40-\uDF43\uDF63-\uDF77\uDF7D-\uDF8F]|\uD809[\uDC80-\uDD43]|\uD802[\uDC00-\uDC05\uDC08\uDC0A-\uDC35\uDC37\uDC38\uDC3C\uDC3F-\uDC55\uDC60-\uDC76\uDC80-\uDC9E\uDCE0-\uDCF2\uDCF4\uDCF5\uDD00-\uDD15\uDD20-\uDD39\uDD80-\uDDB7\uDDBE\uDDBF\uDE00\uDE10-\uDE13\uDE15-\uDE17\uDE19-\uDE33\uDE60-\uDE7C\uDE80-\uDE9C\uDEC0-\uDEC7\uDEC9-\uDEE4\uDF00-\uDF35\uDF40-\uDF55\uDF60-\uDF72\uDF80-\uDF91]|\uD835[\uDC00-\uDC54\uDC56-\uDC9C\uDC9E\uDC9F\uDCA2\uDCA5\uDCA6\uDCA9-\uDCAC\uDCAE-\uDCB9\uDCBB\uDCBD-\uDCC3\uDCC5-\uDD05\uDD07-\uDD0A\uDD0D-\uDD14\uDD16-\uDD1C\uDD1E-\uDD39\uDD3B-\uDD3E\uDD40-\uDD44\uDD46\uDD4A-\uDD50\uDD52-\uDEA5\uDEA8-\uDEC0\uDEC2-\uDEDA\uDEDC-\uDEFA\uDEFC-\uDF14\uDF16-\uDF34\uDF36-\uDF4E\uDF50-\uDF6E\uDF70-\uDF88\uDF8A-\uDFA8\uDFAA-\uDFC2\uDFC4-\uDFCB]|\uD804[\uDC03-\uDC37\uDC83-\uDCAF\uDCD0-\uDCE8\uDD03-\uDD26\uDD50-\uDD72\uDD76\uDD83-\uDDB2\uDDC1-\uDDC4\uDDDA\uDDDC\uDE00-\uDE11\uDE13-\uDE2B\uDE80-\uDE86\uDE88\uDE8A-\uDE8D\uDE8F-\uDE9D\uDE9F-\uDEA8\uDEB0-\uDEDE\uDF05-\uDF0C\uDF0F\uDF10\uDF13-\uDF28\uDF2A-\uDF30\uDF32\uDF33\uDF35-\uDF39\uDF3D\uDF50\uDF5D-\uDF61]|\uD808[\uDC00-\uDF99]|\uD83B[\uDE00-\uDE03\uDE05-\uDE1F\uDE21\uDE22\uDE24\uDE27\uDE29-\uDE32\uDE34-\uDE37\uDE39\uDE3B\uDE42\uDE47\uDE49\uDE4B\uDE4D-\uDE4F\uDE51\uDE52\uDE54\uDE57\uDE59\uDE5B\uDE5D\uDE5F\uDE61\uDE62\uDE64\uDE67-\uDE6A\uDE6C-\uDE72\uDE74-\uDE77\uDE79-\uDE7C\uDE7E\uDE80-\uDE89\uDE8B-\uDE9B\uDEA1-\uDEA3\uDEA5-\uDEA9\uDEAB-\uDEBB]|\uD806[\uDCA0-\uDCDF\uDCFF\uDEC0-\uDEF8]|\uD811[\uDC00-\uDE46]|\uD82F[\uDC00-\uDC6A\uDC70-\uDC7C\uDC80-\uDC88\uDC90-\uDC99]|\uD82C[\uDC00\uDC01]|\uD873[\uDC00-\uDEA1]'
		},
		{
			name: 'Nd',
			alias: 'Decimal_Number',
			bmp: '0-9\u0660-\u0669\u06F0-\u06F9\u07C0-\u07C9\u0966-\u096F\u09E6-\u09EF\u0A66-\u0A6F\u0AE6-\u0AEF\u0B66-\u0B6F\u0BE6-\u0BEF\u0C66-\u0C6F\u0CE6-\u0CEF\u0D66-\u0D6F\u0DE6-\u0DEF\u0E50-\u0E59\u0ED0-\u0ED9\u0F20-\u0F29\u1040-\u1049\u1090-\u1099\u17E0-\u17E9\u1810-\u1819\u1946-\u194F\u19D0-\u19D9\u1A80-\u1A89\u1A90-\u1A99\u1B50-\u1B59\u1BB0-\u1BB9\u1C40-\u1C49\u1C50-\u1C59\uA620-\uA629\uA8D0-\uA8D9\uA900-\uA909\uA9D0-\uA9D9\uA9F0-\uA9F9\uAA50-\uAA59\uABF0-\uABF9\uFF10-\uFF19',
			astral: '\uD801[\uDCA0-\uDCA9]|\uD835[\uDFCE-\uDFFF]|\uD805[\uDCD0-\uDCD9\uDE50-\uDE59\uDEC0-\uDEC9\uDF30-\uDF39]|\uD806[\uDCE0-\uDCE9]|\uD804[\uDC66-\uDC6F\uDCF0-\uDCF9\uDD36-\uDD3F\uDDD0-\uDDD9\uDEF0-\uDEF9]|\uD81A[\uDE60-\uDE69\uDF50-\uDF59]'
		}
	]);

}(XRegExp));

/*!
	* XRegExp Unicode Scripts 3.0.0
	* <http://xregexp.com/>
	* Steven Levithan (c) 2010-2015 MIT License
	* Unicode data provided by Mathias Bynens <http://mathiasbynens.be/>
	*/

/**
 * Adds support for all Unicode scripts. E.g., `\p{Latin}`. Token names are case insensitive, and
 * any spaces, hyphens, and underscores are ignored.
 *
 * Uses Unicode 8.0.0.
 *
 * @requires XRegExp, Unicode Base
 */
(function(XRegExp) {

	if (!XRegExp.addUnicodeData) {
		throw new ReferenceError('Unicode Base must be loaded before Unicode Scripts');
	}

	XRegExp.addUnicodeData([
		{
			name: 'Ahom',
			astral: '\uD805[\uDF00-\uDF19\uDF1D-\uDF2B\uDF30-\uDF3F]'
		},
		{
			name: 'Anatolian_Hieroglyphs',
			astral: '\uD811[\uDC00-\uDE46]'
		},
		{
			name: 'Arabic',
			bmp: '\u0600-\u0604\u0606-\u060B\u060D-\u061A\u061E\u0620-\u063F\u0641-\u064A\u0656-\u066F\u0671-\u06DC\u06DE-\u06FF\u0750-\u077F\u08A0-\u08B4\u08E3-\u08FF\uFB50-\uFBC1\uFBD3-\uFD3D\uFD50-\uFD8F\uFD92-\uFDC7\uFDF0-\uFDFD\uFE70-\uFE74\uFE76-\uFEFC',
			astral: '\uD803[\uDE60-\uDE7E]|\uD83B[\uDE00-\uDE03\uDE05-\uDE1F\uDE21\uDE22\uDE24\uDE27\uDE29-\uDE32\uDE34-\uDE37\uDE39\uDE3B\uDE42\uDE47\uDE49\uDE4B\uDE4D-\uDE4F\uDE51\uDE52\uDE54\uDE57\uDE59\uDE5B\uDE5D\uDE5F\uDE61\uDE62\uDE64\uDE67-\uDE6A\uDE6C-\uDE72\uDE74-\uDE77\uDE79-\uDE7C\uDE7E\uDE80-\uDE89\uDE8B-\uDE9B\uDEA1-\uDEA3\uDEA5-\uDEA9\uDEAB-\uDEBB\uDEF0\uDEF1]'
		},
		{
			name: 'Armenian',
			bmp: '\u0531-\u0556\u0559-\u055F\u0561-\u0587\u058A\u058D-\u058F\uFB13-\uFB17'
		},
		{
			name: 'Avestan',
			astral: '\uD802[\uDF00-\uDF35\uDF39-\uDF3F]'
		},
		{
			name: 'Balinese',
			bmp: '\u1B00-\u1B4B\u1B50-\u1B7C'
		},
		{
			name: 'Bamum',
			bmp: '\uA6A0-\uA6F7',
			astral: '\uD81A[\uDC00-\uDE38]'
		},
		{
			name: 'Bassa_Vah',
			astral: '\uD81A[\uDED0-\uDEED\uDEF0-\uDEF5]'
		},
		{
			name: 'Batak',
			bmp: '\u1BC0-\u1BF3\u1BFC-\u1BFF'
		},
		{
			name: 'Bengali',
			bmp: '\u0980-\u0983\u0985-\u098C\u098F\u0990\u0993-\u09A8\u09AA-\u09B0\u09B2\u09B6-\u09B9\u09BC-\u09C4\u09C7\u09C8\u09CB-\u09CE\u09D7\u09DC\u09DD\u09DF-\u09E3\u09E6-\u09FB'
		},
		{
			name: 'Bopomofo',
			bmp: '\u02EA\u02EB\u3105-\u312D\u31A0-\u31BA'
		},
		{
			name: 'Brahmi',
			astral: '\uD804[\uDC00-\uDC4D\uDC52-\uDC6F\uDC7F]'
		},
		{
			name: 'Braille',
			bmp: '\u2800-\u28FF'
		},
		{
			name: 'Buginese',
			bmp: '\u1A00-\u1A1B\u1A1E\u1A1F'
		},
		{
			name: 'Buhid',
			bmp: '\u1740-\u1753'
		},
		{
			name: 'Canadian_Aboriginal',
			bmp: '\u1400-\u167F\u18B0-\u18F5'
		},
		{
			name: 'Carian',
			astral: '\uD800[\uDEA0-\uDED0]'
		},
		{
			name: 'Caucasian_Albanian',
			astral: '\uD801[\uDD30-\uDD63\uDD6F]'
		},
		{
			name: 'Chakma',
			astral: '\uD804[\uDD00-\uDD34\uDD36-\uDD43]'
		},
		{
			name: 'Cham',
			bmp: '\uAA00-\uAA36\uAA40-\uAA4D\uAA50-\uAA59\uAA5C-\uAA5F'
		},
		{
			name: 'Cherokee',
			bmp: '\u13A0-\u13F5\u13F8-\u13FD\uAB70-\uABBF'
		},
		{
			name: 'Common',
			bmp: '\0-\x40\\x5B-\x60\\x7B-\xA9\xAB-\xB9\xBB-\xBF\xD7\xF7\u02B9-\u02DF\u02E5-\u02E9\u02EC-\u02FF\u0374\u037E\u0385\u0387\u0589\u0605\u060C\u061B\u061C\u061F\u0640\u06DD\u0964\u0965\u0E3F\u0FD5-\u0FD8\u10FB\u16EB-\u16ED\u1735\u1736\u1802\u1803\u1805\u1CD3\u1CE1\u1CE9-\u1CEC\u1CEE-\u1CF3\u1CF5\u1CF6\u2000-\u200B\u200E-\u2064\u2066-\u2070\u2074-\u207E\u2080-\u208E\u20A0-\u20BE\u2100-\u2125\u2127-\u2129\u212C-\u2131\u2133-\u214D\u214F-\u215F\u2189-\u218B\u2190-\u23FA\u2400-\u2426\u2440-\u244A\u2460-\u27FF\u2900-\u2B73\u2B76-\u2B95\u2B98-\u2BB9\u2BBD-\u2BC8\u2BCA-\u2BD1\u2BEC-\u2BEF\u2E00-\u2E42\u2FF0-\u2FFB\u3000-\u3004\u3006\u3008-\u3020\u3030-\u3037\u303C-\u303F\u309B\u309C\u30A0\u30FB\u30FC\u3190-\u319F\u31C0-\u31E3\u3220-\u325F\u327F-\u32CF\u3358-\u33FF\u4DC0-\u4DFF\uA700-\uA721\uA788-\uA78A\uA830-\uA839\uA92E\uA9CF\uAB5B\uFD3E\uFD3F\uFE10-\uFE19\uFE30-\uFE52\uFE54-\uFE66\uFE68-\uFE6B\uFEFF\uFF01-\uFF20\uFF3B-\uFF40\uFF5B-\uFF65\uFF70\uFF9E\uFF9F\uFFE0-\uFFE6\uFFE8-\uFFEE\uFFF9-\uFFFD',
			astral: '\uD83E[\uDC00-\uDC0B\uDC10-\uDC47\uDC50-\uDC59\uDC60-\uDC87\uDC90-\uDCAD\uDD10-\uDD18\uDD80-\uDD84\uDDC0]|\uD82F[\uDCA0-\uDCA3]|\uD835[\uDC00-\uDC54\uDC56-\uDC9C\uDC9E\uDC9F\uDCA2\uDCA5\uDCA6\uDCA9-\uDCAC\uDCAE-\uDCB9\uDCBB\uDCBD-\uDCC3\uDCC5-\uDD05\uDD07-\uDD0A\uDD0D-\uDD14\uDD16-\uDD1C\uDD1E-\uDD39\uDD3B-\uDD3E\uDD40-\uDD44\uDD46\uDD4A-\uDD50\uDD52-\uDEA5\uDEA8-\uDFCB\uDFCE-\uDFFF]|\uDB40[\uDC01\uDC20-\uDC7F]|\uD83D[\uDC00-\uDD79\uDD7B-\uDDA3\uDDA5-\uDED0\uDEE0-\uDEEC\uDEF0-\uDEF3\uDF00-\uDF73\uDF80-\uDFD4]|\uD800[\uDD00-\uDD02\uDD07-\uDD33\uDD37-\uDD3F\uDD90-\uDD9B\uDDD0-\uDDFC\uDEE1-\uDEFB]|\uD834[\uDC00-\uDCF5\uDD00-\uDD26\uDD29-\uDD66\uDD6A-\uDD7A\uDD83\uDD84\uDD8C-\uDDA9\uDDAE-\uDDE8\uDF00-\uDF56\uDF60-\uDF71]|\uD83C[\uDC00-\uDC2B\uDC30-\uDC93\uDCA0-\uDCAE\uDCB1-\uDCBF\uDCC1-\uDCCF\uDCD1-\uDCF5\uDD00-\uDD0C\uDD10-\uDD2E\uDD30-\uDD6B\uDD70-\uDD9A\uDDE6-\uDDFF\uDE01\uDE02\uDE10-\uDE3A\uDE40-\uDE48\uDE50\uDE51\uDF00-\uDFFF]'
		},
		{
			name: 'Coptic',
			bmp: '\u03E2-\u03EF\u2C80-\u2CF3\u2CF9-\u2CFF'
		},
		{
			name: 'Cuneiform',
			astral: '\uD809[\uDC00-\uDC6E\uDC70-\uDC74\uDC80-\uDD43]|\uD808[\uDC00-\uDF99]'
		},
		{
			name: 'Cypriot',
			astral: '\uD802[\uDC00-\uDC05\uDC08\uDC0A-\uDC35\uDC37\uDC38\uDC3C\uDC3F]'
		},
		{
			name: 'Cyrillic',
			bmp: '\u0400-\u0484\u0487-\u052F\u1D2B\u1D78\u2DE0-\u2DFF\uA640-\uA69F\uFE2E\uFE2F'
		},
		{
			name: 'Deseret',
			astral: '\uD801[\uDC00-\uDC4F]'
		},
		{
			name: 'Devanagari',
			bmp: '\u0900-\u0950\u0953-\u0963\u0966-\u097F\uA8E0-\uA8FD'
		},
		{
			name: 'Duployan',
			astral: '\uD82F[\uDC00-\uDC6A\uDC70-\uDC7C\uDC80-\uDC88\uDC90-\uDC99\uDC9C-\uDC9F]'
		},
		{
			name: 'Egyptian_Hieroglyphs',
			astral: '\uD80C[\uDC00-\uDFFF]|\uD80D[\uDC00-\uDC2E]'
		},
		{
			name: 'Elbasan',
			astral: '\uD801[\uDD00-\uDD27]'
		},
		{
			name: 'Ethiopic',
			bmp: '\u1200-\u1248\u124A-\u124D\u1250-\u1256\u1258\u125A-\u125D\u1260-\u1288\u128A-\u128D\u1290-\u12B0\u12B2-\u12B5\u12B8-\u12BE\u12C0\u12C2-\u12C5\u12C8-\u12D6\u12D8-\u1310\u1312-\u1315\u1318-\u135A\u135D-\u137C\u1380-\u1399\u2D80-\u2D96\u2DA0-\u2DA6\u2DA8-\u2DAE\u2DB0-\u2DB6\u2DB8-\u2DBE\u2DC0-\u2DC6\u2DC8-\u2DCE\u2DD0-\u2DD6\u2DD8-\u2DDE\uAB01-\uAB06\uAB09-\uAB0E\uAB11-\uAB16\uAB20-\uAB26\uAB28-\uAB2E'
		},
		{
			name: 'Georgian',
			bmp: '\u10A0-\u10C5\u10C7\u10CD\u10D0-\u10FA\u10FC-\u10FF\u2D00-\u2D25\u2D27\u2D2D'
		},
		{
			name: 'Glagolitic',
			bmp: '\u2C00-\u2C2E\u2C30-\u2C5E'
		},
		{
			name: 'Gothic',
			astral: '\uD800[\uDF30-\uDF4A]'
		},
		{
			name: 'Grantha',
			astral: '\uD804[\uDF00-\uDF03\uDF05-\uDF0C\uDF0F\uDF10\uDF13-\uDF28\uDF2A-\uDF30\uDF32\uDF33\uDF35-\uDF39\uDF3C-\uDF44\uDF47\uDF48\uDF4B-\uDF4D\uDF50\uDF57\uDF5D-\uDF63\uDF66-\uDF6C\uDF70-\uDF74]'
		},
		{
			name: 'Greek',
			bmp: '\u0370-\u0373\u0375-\u0377\u037A-\u037D\u037F\u0384\u0386\u0388-\u038A\u038C\u038E-\u03A1\u03A3-\u03E1\u03F0-\u03FF\u1D26-\u1D2A\u1D5D-\u1D61\u1D66-\u1D6A\u1DBF\u1F00-\u1F15\u1F18-\u1F1D\u1F20-\u1F45\u1F48-\u1F4D\u1F50-\u1F57\u1F59\u1F5B\u1F5D\u1F5F-\u1F7D\u1F80-\u1FB4\u1FB6-\u1FC4\u1FC6-\u1FD3\u1FD6-\u1FDB\u1FDD-\u1FEF\u1FF2-\u1FF4\u1FF6-\u1FFE\u2126\uAB65',
			astral: '\uD800[\uDD40-\uDD8C\uDDA0]|\uD834[\uDE00-\uDE45]'
		},
		{
			name: 'Gujarati',
			bmp: '\u0A81-\u0A83\u0A85-\u0A8D\u0A8F-\u0A91\u0A93-\u0AA8\u0AAA-\u0AB0\u0AB2\u0AB3\u0AB5-\u0AB9\u0ABC-\u0AC5\u0AC7-\u0AC9\u0ACB-\u0ACD\u0AD0\u0AE0-\u0AE3\u0AE6-\u0AF1\u0AF9'
		},
		{
			name: 'Gurmukhi',
			bmp: '\u0A01-\u0A03\u0A05-\u0A0A\u0A0F\u0A10\u0A13-\u0A28\u0A2A-\u0A30\u0A32\u0A33\u0A35\u0A36\u0A38\u0A39\u0A3C\u0A3E-\u0A42\u0A47\u0A48\u0A4B-\u0A4D\u0A51\u0A59-\u0A5C\u0A5E\u0A66-\u0A75'
		},
		{
			name: 'Han',
			bmp: '\u2E80-\u2E99\u2E9B-\u2EF3\u2F00-\u2FD5\u3005\u3007\u3021-\u3029\u3038-\u303B\u3400-\u4DB5\u4E00-\u9FD5\uF900-\uFA6D\uFA70-\uFAD9',
			astral: '\uD86E[\uDC00-\uDC1D\uDC20-\uDFFF]|[\uD840-\uD868\uD86A-\uD86C\uD86F-\uD872][\uDC00-\uDFFF]|\uD86D[\uDC00-\uDF34\uDF40-\uDFFF]|\uD87E[\uDC00-\uDE1D]|\uD869[\uDC00-\uDED6\uDF00-\uDFFF]|\uD873[\uDC00-\uDEA1]'
		},
		{
			name: 'Hangul',
			bmp: '\u1100-\u11FF\u302E\u302F\u3131-\u318E\u3200-\u321E\u3260-\u327E\uA960-\uA97C\uAC00-\uD7A3\uD7B0-\uD7C6\uD7CB-\uD7FB\uFFA0-\uFFBE\uFFC2-\uFFC7\uFFCA-\uFFCF\uFFD2-\uFFD7\uFFDA-\uFFDC'
		},
		{
			name: 'Hanunoo',
			bmp: '\u1720-\u1734'
		},
		{
			name: 'Hatran',
			astral: '\uD802[\uDCE0-\uDCF2\uDCF4\uDCF5\uDCFB-\uDCFF]'
		},
		{
			name: 'Hebrew',
			bmp: '\u0591-\u05C7\u05D0-\u05EA\u05F0-\u05F4\uFB1D-\uFB36\uFB38-\uFB3C\uFB3E\uFB40\uFB41\uFB43\uFB44\uFB46-\uFB4F'
		},
		{
			name: 'Hiragana',
			bmp: '\u3041-\u3096\u309D-\u309F',
			astral: '\uD82C\uDC01|\uD83C\uDE00'
		},
		{
			name: 'Imperial_Aramaic',
			astral: '\uD802[\uDC40-\uDC55\uDC57-\uDC5F]'
		},
		{
			name: 'Inherited',
			bmp: '\u0300-\u036F\u0485\u0486\u064B-\u0655\u0670\u0951\u0952\u1AB0-\u1ABE\u1CD0-\u1CD2\u1CD4-\u1CE0\u1CE2-\u1CE8\u1CED\u1CF4\u1CF8\u1CF9\u1DC0-\u1DF5\u1DFC-\u1DFF\u200C\u200D\u20D0-\u20F0\u302A-\u302D\u3099\u309A\uFE00-\uFE0F\uFE20-\uFE2D',
			astral: '\uD834[\uDD67-\uDD69\uDD7B-\uDD82\uDD85-\uDD8B\uDDAA-\uDDAD]|\uD800[\uDDFD\uDEE0]|\uDB40[\uDD00-\uDDEF]'
		},
		{
			name: 'Inscriptional_Pahlavi',
			astral: '\uD802[\uDF60-\uDF72\uDF78-\uDF7F]'
		},
		{
			name: 'Inscriptional_Parthian',
			astral: '\uD802[\uDF40-\uDF55\uDF58-\uDF5F]'
		},
		{
			name: 'Javanese',
			bmp: '\uA980-\uA9CD\uA9D0-\uA9D9\uA9DE\uA9DF'
		},
		{
			name: 'Kaithi',
			astral: '\uD804[\uDC80-\uDCC1]'
		},
		{
			name: 'Kannada',
			bmp: '\u0C81-\u0C83\u0C85-\u0C8C\u0C8E-\u0C90\u0C92-\u0CA8\u0CAA-\u0CB3\u0CB5-\u0CB9\u0CBC-\u0CC4\u0CC6-\u0CC8\u0CCA-\u0CCD\u0CD5\u0CD6\u0CDE\u0CE0-\u0CE3\u0CE6-\u0CEF\u0CF1\u0CF2'
		},
		{
			name: 'Katakana',
			bmp: '\u30A1-\u30FA\u30FD-\u30FF\u31F0-\u31FF\u32D0-\u32FE\u3300-\u3357\uFF66-\uFF6F\uFF71-\uFF9D',
			astral: '\uD82C\uDC00'
		},
		{
			name: 'Kayah_Li',
			bmp: '\uA900-\uA92D\uA92F'
		},
		{
			name: 'Kharoshthi',
			astral: '\uD802[\uDE00-\uDE03\uDE05\uDE06\uDE0C-\uDE13\uDE15-\uDE17\uDE19-\uDE33\uDE38-\uDE3A\uDE3F-\uDE47\uDE50-\uDE58]'
		},
		{
			name: 'Khmer',
			bmp: '\u1780-\u17DD\u17E0-\u17E9\u17F0-\u17F9\u19E0-\u19FF'
		},
		{
			name: 'Khojki',
			astral: '\uD804[\uDE00-\uDE11\uDE13-\uDE3D]'
		},
		{
			name: 'Khudawadi',
			astral: '\uD804[\uDEB0-\uDEEA\uDEF0-\uDEF9]'
		},
		{
			name: 'Lao',
			bmp: '\u0E81\u0E82\u0E84\u0E87\u0E88\u0E8A\u0E8D\u0E94-\u0E97\u0E99-\u0E9F\u0EA1-\u0EA3\u0EA5\u0EA7\u0EAA\u0EAB\u0EAD-\u0EB9\u0EBB-\u0EBD\u0EC0-\u0EC4\u0EC6\u0EC8-\u0ECD\u0ED0-\u0ED9\u0EDC-\u0EDF'
		},
		{
			name: 'Latin',
			bmp: 'A-Za-z\xAA\xBA\xC0-\xD6\xD8-\xF6\xF8-\u02B8\u02E0-\u02E4\u1D00-\u1D25\u1D2C-\u1D5C\u1D62-\u1D65\u1D6B-\u1D77\u1D79-\u1DBE\u1E00-\u1EFF\u2071\u207F\u2090-\u209C\u212A\u212B\u2132\u214E\u2160-\u2188\u2C60-\u2C7F\uA722-\uA787\uA78B-\uA7AD\uA7B0-\uA7B7\uA7F7-\uA7FF\uAB30-\uAB5A\uAB5C-\uAB64\uFB00-\uFB06\uFF21-\uFF3A\uFF41-\uFF5A'
		},
		{
			name: 'Lepcha',
			bmp: '\u1C00-\u1C37\u1C3B-\u1C49\u1C4D-\u1C4F'
		},
		{
			name: 'Limbu',
			bmp: '\u1900-\u191E\u1920-\u192B\u1930-\u193B\u1940\u1944-\u194F'
		},
		{
			name: 'Linear_A',
			astral: '\uD801[\uDE00-\uDF36\uDF40-\uDF55\uDF60-\uDF67]'
		},
		{
			name: 'Linear_B',
			astral: '\uD800[\uDC00-\uDC0B\uDC0D-\uDC26\uDC28-\uDC3A\uDC3C\uDC3D\uDC3F-\uDC4D\uDC50-\uDC5D\uDC80-\uDCFA]'
		},
		{
			name: 'Lisu',
			bmp: '\uA4D0-\uA4FF'
		},
		{
			name: 'Lycian',
			astral: '\uD800[\uDE80-\uDE9C]'
		},
		{
			name: 'Lydian',
			astral: '\uD802[\uDD20-\uDD39\uDD3F]'
		},
		{
			name: 'Mahajani',
			astral: '\uD804[\uDD50-\uDD76]'
		},
		{
			name: 'Malayalam',
			bmp: '\u0D01-\u0D03\u0D05-\u0D0C\u0D0E-\u0D10\u0D12-\u0D3A\u0D3D-\u0D44\u0D46-\u0D48\u0D4A-\u0D4E\u0D57\u0D5F-\u0D63\u0D66-\u0D75\u0D79-\u0D7F'
		},
		{
			name: 'Mandaic',
			bmp: '\u0840-\u085B\u085E'
		},
		{
			name: 'Manichaean',
			astral: '\uD802[\uDEC0-\uDEE6\uDEEB-\uDEF6]'
		},
		{
			name: 'Meetei_Mayek',
			bmp: '\uAAE0-\uAAF6\uABC0-\uABED\uABF0-\uABF9'
		},
		{
			name: 'Mende_Kikakui',
			astral: '\uD83A[\uDC00-\uDCC4\uDCC7-\uDCD6]'
		},
		{
			name: 'Meroitic_Cursive',
			astral: '\uD802[\uDDA0-\uDDB7\uDDBC-\uDDCF\uDDD2-\uDDFF]'
		},
		{
			name: 'Meroitic_Hieroglyphs',
			astral: '\uD802[\uDD80-\uDD9F]'
		},
		{
			name: 'Miao',
			astral: '\uD81B[\uDF00-\uDF44\uDF50-\uDF7E\uDF8F-\uDF9F]'
		},
		{
			name: 'Modi',
			astral: '\uD805[\uDE00-\uDE44\uDE50-\uDE59]'
		},
		{
			name: 'Mongolian',
			bmp: '\u1800\u1801\u1804\u1806-\u180E\u1810-\u1819\u1820-\u1877\u1880-\u18AA'
		},
		{
			name: 'Mro',
			astral: '\uD81A[\uDE40-\uDE5E\uDE60-\uDE69\uDE6E\uDE6F]'
		},
		{
			name: 'Multani',
			astral: '\uD804[\uDE80-\uDE86\uDE88\uDE8A-\uDE8D\uDE8F-\uDE9D\uDE9F-\uDEA9]'
		},
		{
			name: 'Myanmar',
			bmp: '\u1000-\u109F\uA9E0-\uA9FE\uAA60-\uAA7F'
		},
		{
			name: 'Nabataean',
			astral: '\uD802[\uDC80-\uDC9E\uDCA7-\uDCAF]'
		},
		{
			name: 'New_Tai_Lue',
			bmp: '\u1980-\u19AB\u19B0-\u19C9\u19D0-\u19DA\u19DE\u19DF'
		},
		{
			name: 'Nko',
			bmp: '\u07C0-\u07FA'
		},
		{
			name: 'Ogham',
			bmp: '\u1680-\u169C'
		},
		{
			name: 'Ol_Chiki',
			bmp: '\u1C50-\u1C7F'
		},
		{
			name: 'Old_Hungarian',
			astral: '\uD803[\uDC80-\uDCB2\uDCC0-\uDCF2\uDCFA-\uDCFF]'
		},
		{
			name: 'Old_Italic',
			astral: '\uD800[\uDF00-\uDF23]'
		},
		{
			name: 'Old_North_Arabian',
			astral: '\uD802[\uDE80-\uDE9F]'
		},
		{
			name: 'Old_Permic',
			astral: '\uD800[\uDF50-\uDF7A]'
		},
		{
			name: 'Old_Persian',
			astral: '\uD800[\uDFA0-\uDFC3\uDFC8-\uDFD5]'
		},
		{
			name: 'Old_South_Arabian',
			astral: '\uD802[\uDE60-\uDE7F]'
		},
		{
			name: 'Old_Turkic',
			astral: '\uD803[\uDC00-\uDC48]'
		},
		{
			name: 'Oriya',
			bmp: '\u0B01-\u0B03\u0B05-\u0B0C\u0B0F\u0B10\u0B13-\u0B28\u0B2A-\u0B30\u0B32\u0B33\u0B35-\u0B39\u0B3C-\u0B44\u0B47\u0B48\u0B4B-\u0B4D\u0B56\u0B57\u0B5C\u0B5D\u0B5F-\u0B63\u0B66-\u0B77'
		},
		{
			name: 'Osmanya',
			astral: '\uD801[\uDC80-\uDC9D\uDCA0-\uDCA9]'
		},
		{
			name: 'Pahawh_Hmong',
			astral: '\uD81A[\uDF00-\uDF45\uDF50-\uDF59\uDF5B-\uDF61\uDF63-\uDF77\uDF7D-\uDF8F]'
		},
		{
			name: 'Palmyrene',
			astral: '\uD802[\uDC60-\uDC7F]'
		},
		{
			name: 'Pau_Cin_Hau',
			astral: '\uD806[\uDEC0-\uDEF8]'
		},
		{
			name: 'Phags_Pa',
			bmp: '\uA840-\uA877'
		},
		{
			name: 'Phoenician',
			astral: '\uD802[\uDD00-\uDD1B\uDD1F]'
		},
		{
			name: 'Psalter_Pahlavi',
			astral: '\uD802[\uDF80-\uDF91\uDF99-\uDF9C\uDFA9-\uDFAF]'
		},
		{
			name: 'Rejang',
			bmp: '\uA930-\uA953\uA95F'
		},
		{
			name: 'Runic',
			bmp: '\u16A0-\u16EA\u16EE-\u16F8'
		},
		{
			name: 'Samaritan',
			bmp: '\u0800-\u082D\u0830-\u083E'
		},
		{
			name: 'Saurashtra',
			bmp: '\uA880-\uA8C4\uA8CE-\uA8D9'
		},
		{
			name: 'Sharada',
			astral: '\uD804[\uDD80-\uDDCD\uDDD0-\uDDDF]'
		},
		{
			name: 'Shavian',
			astral: '\uD801[\uDC50-\uDC7F]'
		},
		{
			name: 'Siddham',
			astral: '\uD805[\uDD80-\uDDB5\uDDB8-\uDDDD]'
		},
		{
			name: 'SignWriting',
			astral: '\uD836[\uDC00-\uDE8B\uDE9B-\uDE9F\uDEA1-\uDEAF]'
		},
		{
			name: 'Sinhala',
			bmp: '\u0D82\u0D83\u0D85-\u0D96\u0D9A-\u0DB1\u0DB3-\u0DBB\u0DBD\u0DC0-\u0DC6\u0DCA\u0DCF-\u0DD4\u0DD6\u0DD8-\u0DDF\u0DE6-\u0DEF\u0DF2-\u0DF4',
			astral: '\uD804[\uDDE1-\uDDF4]'
		},
		{
			name: 'Sora_Sompeng',
			astral: '\uD804[\uDCD0-\uDCE8\uDCF0-\uDCF9]'
		},
		{
			name: 'Sundanese',
			bmp: '\u1B80-\u1BBF\u1CC0-\u1CC7'
		},
		{
			name: 'Syloti_Nagri',
			bmp: '\uA800-\uA82B'
		},
		{
			name: 'Syriac',
			bmp: '\u0700-\u070D\u070F-\u074A\u074D-\u074F'
		},
		{
			name: 'Tagalog',
			bmp: '\u1700-\u170C\u170E-\u1714'
		},
		{
			name: 'Tagbanwa',
			bmp: '\u1760-\u176C\u176E-\u1770\u1772\u1773'
		},
		{
			name: 'Tai_Le',
			bmp: '\u1950-\u196D\u1970-\u1974'
		},
		{
			name: 'Tai_Tham',
			bmp: '\u1A20-\u1A5E\u1A60-\u1A7C\u1A7F-\u1A89\u1A90-\u1A99\u1AA0-\u1AAD'
		},
		{
			name: 'Tai_Viet',
			bmp: '\uAA80-\uAAC2\uAADB-\uAADF'
		},
		{
			name: 'Takri',
			astral: '\uD805[\uDE80-\uDEB7\uDEC0-\uDEC9]'
		},
		{
			name: 'Tamil',
			bmp: '\u0B82\u0B83\u0B85-\u0B8A\u0B8E-\u0B90\u0B92-\u0B95\u0B99\u0B9A\u0B9C\u0B9E\u0B9F\u0BA3\u0BA4\u0BA8-\u0BAA\u0BAE-\u0BB9\u0BBE-\u0BC2\u0BC6-\u0BC8\u0BCA-\u0BCD\u0BD0\u0BD7\u0BE6-\u0BFA'
		},
		{
			name: 'Telugu',
			bmp: '\u0C00-\u0C03\u0C05-\u0C0C\u0C0E-\u0C10\u0C12-\u0C28\u0C2A-\u0C39\u0C3D-\u0C44\u0C46-\u0C48\u0C4A-\u0C4D\u0C55\u0C56\u0C58-\u0C5A\u0C60-\u0C63\u0C66-\u0C6F\u0C78-\u0C7F'
		},
		{
			name: 'Thaana',
			bmp: '\u0780-\u07B1'
		},
		{
			name: 'Thai',
			bmp: '\u0E01-\u0E3A\u0E40-\u0E5B'
		},
		{
			name: 'Tibetan',
			bmp: '\u0F00-\u0F47\u0F49-\u0F6C\u0F71-\u0F97\u0F99-\u0FBC\u0FBE-\u0FCC\u0FCE-\u0FD4\u0FD9\u0FDA'
		},
		{
			name: 'Tifinagh',
			bmp: '\u2D30-\u2D67\u2D6F\u2D70\u2D7F'
		},
		{
			name: 'Tirhuta',
			astral: '\uD805[\uDC80-\uDCC7\uDCD0-\uDCD9]'
		},
		{
			name: 'Ugaritic',
			astral: '\uD800[\uDF80-\uDF9D\uDF9F]'
		},
		{
			name: 'Vai',
			bmp: '\uA500-\uA62B'
		},
		{
			name: 'Warang_Citi',
			astral: '\uD806[\uDCA0-\uDCF2\uDCFF]'
		},
		{
			name: 'Yi',
			bmp: '\uA000-\uA48C\uA490-\uA4C6'
		}
	]);

}(XRegExp));


var WORD_CHARS = '\\p{L}';
var WORD_CHARS_PLUS_DIGITS = WORD_CHARS + '\\p{Nd}';
var TEXT_ENTITY_BOUNDARY_CHARS = '[(),.!?\';:（），。！？“”"；：\\/\\[\\]\\u200B]';	// \u200B 是回车后的空白符

var h = XRegExp('://|\\.([a-z]{2}[a-z]*)(?=$|[^.\\-' + WORD_CHARS_PLUS_DIGITS + ']|\\.$|\\.[^' + WORD_CHARS_PLUS_DIGITS + '])', 'ig')
	, f = '[' + WORD_CHARS_PLUS_DIGITS + ']([' + WORD_CHARS_PLUS_DIGITS + '\\-_]*[' + WORD_CHARS_PLUS_DIGITS + '])?'
	, n = XRegExp('^' + f + '(\\.' + f + ')*$', 'i')
	, l = XRegExp('[' + WORD_CHARS_PLUS_DIGITS + '.\\-_]', 'i');
f = WORD_CHARS_PLUS_DIGITS + '\\/\\:#?&%=~;$@\\-_+!*\'(){}';
var q = XRegExp('^([' + (f + '.,') + ']*[' + f + '])', 'i')
	, o = {
		AD:true,
		AE:true,
		AERO:true,
		AI:true,
		APP:true,
		ASIA:true,
		BD:true,
		BE:true,
		BIZ:true,
		BLOG:true,
		BT:true,
		BY:true,
		CA:true,
		CAT:true,
		CC:true,
		CD:true,
		CG:true,
		CH:true,
		CLOUD:true,
		CLUB:true,
		CM:true,
		CN:true,
		CO:true,
		COM:true,
		COOP:true,
		CV:true,
		CZ:true,
		DE:true,
		DJ:true,
		DK:true,
		DM:true,
		DO:true,
		DRIVE:true,
		EDU:true,
		EG:true,
		ER:true,
		ES:true,
		ET:true,
		EU:true,
		FM:true,
		FO:true,
		FR:true,
		GA:true,
		GD:true,
		GE:true,
		GF:true,
		GG:true,
		GH:true,
		GI:true,
		GM:true,
		GN:true,
		GOV:true,
		GP:true,
		GQ:true,
		GT:true,
		HK:true,
		HR:true,
		HT:true,
		HU:true,
		ID:true,
		IDV:true,
		IE:true,
		IL:true,
		IM:true,
		IN:true,
		INC:true,
		INFO:true,
		INT:true,
		IO:true,
		IQ:true,
		IR:true,
		IS:true,
		IT:true,
		JM:true,
		JO:true,
		JOBS:true,
		JP:true,
		KE:true,
		KG:true,
		KH:true,
		KI:true,
		KM:true,
		KP:true,
		KR:true,
		KW:true,
		KY:true,
		LA:true,
		LI:true,
		LINK:true,
		LIVE:true,
		LK:true,
		MA:true,
		MC:true,
		MD:true,
		ME:true,
		MG:true,
		MIL:true,
		MM:true,
		MN:true,
		MO:true,
		MOBI:true,
		MS:true,
		MT:true,
		MU:true,
		MUSEUM:true,
		MV:true,
		MX:true,
		MY:true,
		NAME:true,
		NC:true,
		NE:true,
		NET:true,
		NEWS:true,
		NF:true,
		NG:true,
		NGO:true,
		NI:true,
		NL:true,
		NO:true,
		OM:true,
		ORG:true,
		PA:true,
		PG:true,
		PH:true,
		PK:true,
		PL:true,
		PM:true,
		PN:true,
		POST:true,
		PR:true,
		PRO:true,
		PS:true,
		PW:true,
		RE:true,
		SC:true,
		SD:true,
		SH:true,
		SHOP:true,
		SI:true,
		SITE:true,
		SN:true,
		SO:true,
		SR:true,
		ST:true,
		STORE:true,
		TD:true,
		TEL:true,
		TG:true,
		TH:true,
		TK:true,
		TL:true,
		TM:true,
		TODAY:true,
		TRAVEL:true,
		TT:true,
		TV:true,
		TW:true,
		UK:true,
		US:true,
		VC:true,
		VIP:true,
		WOW:true,
		WTF:true,
		XYZ:true,
	}
	, c = /[a-z0-9-\+.]/i
	;

function a(p) {
	return c.test(p);
}
function e(p) {
	return c.test(p);
}

function j(p) {
	if (p.charAt(p.length - 1) === ')') {
		var v = p.substring(0, p.length - 1)
			, r = 0;
		for (var i = 0; i < v.length; i++) {
			var x = v.charAt(i);
			if (x === '(')
				r++;
			else
				x === ')' && r > 0 && r--;
		}
		if (r === 0)
			return v;
	}
	return p;
}

function isDigit(d) {
	return !isNaN(d);
}

function isOnlyDigits(d) {
	for (var j = 0; j < d.length; j++)if (!isDigit(d.charAt(j)))return false;
	return true;
}

function forEachUrl(p, handler) {
	for (h.lastIndex = 0; ; ) {
		var r = h.exec(p);
		if (r == null)
			break;
		var x = r[0], u = r.index, b;
		if (x === '://') {
			for (b = u = u; b > 0 && e(p.charAt(b - 1)); )
				b--;
			for (; b < u && !a(p.charAt(b)); )
				b++;
			if (b === u)
				continue;
			if (p.substring(b, u).match(/^javascript$/i) !== null)
				continue;
			var s = u + x.length;
			r = q.exec(p.substring(s));
			if (r === null)
				continue;
			x = r[0];
			x = j(x);
			u = true;
			b = b;
			x = s + x.length;
		} else {
			if (!(r[1].toUpperCase()in o))
				continue;
			for (s = r = u; s > 0 && l.test(p.charAt(s - 1)); )
				s--;
			u = p.substring(s, r);
			if (!n.test(u))
				continue;
			u = false;
			b = s;
			x = r + x.length;
			if (x === p.length || p.charAt(x) !== '/')
				x = x;
			else {
				r = q.exec(p.substring(x));
				s = r[0];
				s = j(s);
				x = x + s.length;
			}
		}
		s = p.substring(b, x);
		var lastChar = '';
		if (b > 0) {
			lastChar = p.substring(b - 1, b);
		}
		if (lastChar != '@' || s.indexOf('://') > 0) {
			handler(b, s, u);
		}
		h.lastIndex = x;
	}
}

var tagChar = '#';
var tagDesc = '[' + WORD_CHARS_PLUS_DIGITS + '][' + WORD_CHARS_PLUS_DIGITS + '\\-_]*(:(' + c + '))*';
var tagReg = XRegExp('(^|\\s|' + TEXT_ENTITY_BOUNDARY_CHARS + ')([' + tagChar + '](' + tagDesc + '))(?=$|\\s|' + TEXT_ENTITY_BOUNDARY_CHARS + ')', 'ig');

function forEachTag(r, x, u) {
	if (u === undefined)
		u = true;
	var b = null;
	if (u) {
		b = Array(r.length);
		this.forEachUrl(r, function(t, y) {
			for (var A = t; A < t + y.length; A++)
				b[A] = true;
		});
	}
	for (tagReg.lastIndex = 0; ; ) {
		var s = tagReg.exec(r);
		if (s == null)
			break;
		var m = s[2];
		s = s.index + s[1].length;
		if (!(u && b[s] === true)) {
			if (isDigit(m.charAt(1))) {
				var w = m.substring(1);
				if (w.length < 4 && isOnlyDigits(w))
					continue;
			}
			x(s, m);
		}
	}
}

var ContentText = /** @class */ (function () {
    function ContentText(editor, plainText, formatFlags) {
        /**
         * 内容的样式标识配置
         */
        this.formatFlagConfig = {
            bold: {
                flag: 2,
            },
            italic: {
                flag: 4,
            },
            underline: {
                flag: 8,
            },
        };
        /**
         * 对应不同flag的样式class
         */
        this.formatFlagStyles = {
            2: 'bold',
            4: 'italic',
            6: 'bold italic',
            8: 'underline',
            10: 'bold underline',
            12: 'italic underline',
            14: 'bold italic underline',
        };
        this.editor = editor;
        if (plainText === undefined && formatFlags === undefined) {
            this.plainText = '';
            this.formatFlags = [];
            this.buildFormatFlags(editor[0], true);
        }
        else {
            this.plainText = plainText;
            this.formatFlags = formatFlags;
        }
    }
    ContentText.prototype.getPlainText = function () {
        return this.plainText;
    };
    ContentText.prototype.escapeText = function (text) {
        return text.replace(/&/g, '&amp;').replace(/>/g, '&gt;').replace(/</g, '&lt;');
    };
    /**
     * 构建内容的样式标识
     * @param domNode
     * @param isContainer 是否是顶级编辑器
     * @param flag 标识数字
     */
    ContentText.prototype.buildFormatFlags = function (domNode, isContainer, flag) {
        flag |= 0;
        if (domNode.nodeType === 3) {
            // 是文本元素
            var text = domNode.nodeValue;
            this.plainText += text;
            for (var j = 0, len = text.length; j < len; j++) {
                this.formatFlags.push(flag);
            }
        }
        else {
            // 不是文本元素，一直递归查找
            if (!isContainer && domNode.className) {
                var nodeClass = (domNode.className + '').split(' ');
                for (var c = 0; c < nodeClass.length; c++) {
                    var clsName = nodeClass[c];
                    if (clsName in this.formatFlagConfig) {
                        // 实际是一个相加的运算
                        flag |= this.formatFlagConfig[clsName].flag;
                    }
                }
            }
            var childNodes = domNode.childNodes;
            for (var index = 0, count = childNodes.length; index < count; index++) {
                var childNode = childNodes[index];
                this.buildFormatFlags(childNode, false, flag);
            }
        }
    };
    /**
     * 是否处于某个样式flag中
     * @param flagName
     * @param position
     */
    ContentText.prototype.inTextFormatFlag = function (flagName, position) {
        var flag = this.formatFlagConfig[flagName].flag;
        // 是否是要删除样式
        var inFlag = true;
        if (position.start === position.end) {
            var flagIndex = position.start;
            if (flagIndex > 0 && this.formatFlags.length > 0) {
                flagIndex--;
            }
            inFlag = ((this.formatFlags[flagIndex] & flag) !== 0);
        }
        else {
            for (var index = position.start; index < position.end; index++) {
                if ((this.formatFlags[index] & flag) === 0) {
                    // 如果当前样式不包含要设置的样式，执行添加
                    inFlag = false;
                    break;
                }
            }
        }
        return inFlag;
    };
    /**
     * 切换样式标识
     * @param flagName
     * @param position
     */
    ContentText.prototype.toggleTextFormatFlag = function (flagName, position) {
        var flag = this.formatFlagConfig[flagName].flag;
        // 是否是要删除样式
        var isRemoveFlag = this.inTextFormatFlag(flagName, position);
        for (var index = position.start; index < position.end; index++) {
            if (isRemoveFlag) {
                this.formatFlags[index] &= ~flag;
            }
            else {
                this.formatFlags[index] |= flag;
            }
        }
    };
    /**
     * 获取内容html
     */
    ContentText.prototype.getContentHtml = function () {
        var charIndex = 0;
        var result = '';
        var contentTags = [];
        forEachUrl(this.plainText, function (start, content, protocol) {
            contentTags.push({
                type: 'url',
                spanStart: start,
                spanLength: content.length,
                urlContainsProtocol: protocol,
            });
        });
        forEachTag(this.plainText, function (start, content) {
            contentTags.push({
                type: 'tag',
                spanStart: start,
                spanLength: content.length,
            });
        }, false);
        contentTags.sort(function (ba, ga) {
            if (ba.spanStart === ga.spanStart) {
                return 0;
            }
            return ba.spanStart < ga.spanStart ? -1 : 1;
        });
        for (var tagIndex = 0, tagLength = contentTags.length; tagIndex < tagLength; tagIndex++) {
            var tag = contentTags[tagIndex];
            var startIndex = tag.spanStart;
            if (!(startIndex < charIndex)) {
                result += this.formatFragment(charIndex, startIndex);
                charIndex = startIndex + tag.spanLength;
                var innerContent = void 0;
                switch (tag.type) {
                    case 'url': {
                        var linkAddress = this.plainText.substring(startIndex, charIndex);
                        if (!tag.urlContainsProtocol) {
                            linkAddress = 'http://' + linkAddress;
                        }
                        innerContent = this.formatFragment(startIndex, charIndex);
                        result += '<a class="content-link" target="_blank" rel="noreferrer" href="' + linkAddress + '">' + innerContent + '</a>';
                        break;
                    }
                    case 'tag': {
                        innerContent = this.formatFragment(startIndex, charIndex);
                        result += '<span class="tag">' + innerContent + '</span>';
                        break;
                    }
                }
            }
        }
        result += this.formatFragment(charIndex, this.plainText.length);
        return result;
    };
    /**
     * 格式化文本内的某一个片段
     * @param start 开始的字符索引
     * @param end 结束的字符索引
     */
    ContentText.prototype.formatFragment = function (start, end) {
        var result = '';
        for (var index = start; index < end;) {
            var beginIndex = index;
            var fragmentFlag = this.formatFlags[index] | 0;
            // 向后找样式相同的字符，合并成一个片段
            while (index < end && this.formatFlags[index] === fragmentFlag) {
                index++;
            }
            var fragText = this.plainText.substring(beginIndex, index);
            fragText = this.escapeText(fragText);
            if (fragmentFlag === 0) {
                result += fragText;
            }
            else {
                var styles = this.formatFlagStyles[fragmentFlag];
                result += '<span class="' + styles + '">' + fragText + '</span>';
            }
        }
        return result;
    };
    /**
     * 以一个区间分隔内容
     * @param start 区间的开始索引
     * @param end 区间的结束索引
     */
    ContentText.prototype.split = function (start, end) {
        var plainText = this.plainText;
        var flags = this.formatFlags;
        var text1 = plainText.substring(0, start);
        var text2 = plainText.substring(end, plainText.length);
        var flag1 = flags.slice(0, start);
        var flag2 = flags.slice(end, flags.length);
        return [
            new ContentText(this.editor, text1, flag1),
            new ContentText(this.editor, text2, flag2),
        ];
    };
    return ContentText;
}());

/**
 * Created by morris on 16/5/6.
 * UI模块
 */
var EditorUI = /** @class */ (function () {
    function EditorUI(model, engine, state, selector, imageEditor, textEditor, viewport, eventSource) {
        this.engine = engine;
        this.state = state;
        this.selector = selector;
        this.editorOperate = new EditorOperate(this, selector, engine, textEditor, state, imageEditor, viewport, eventSource, model);
        this.dragger = new Dragger(model, engine, selector, viewport, this.state);
        this.imageEditor = imageEditor;
        this.viewport = viewport;
        this.textEditor = textEditor;
        this.eventSource = eventSource;
        var preview = new ImagePreview(this.engine, this.viewport, state);
        preview.initPreview();
        // 初始化图片上传组件
        this.imageEditor.init({
            onInsertCopy: function (data) {
                var imageData = {
                    id: data.id,
                    uri: data.uri,
                    ow: data.ow,
                    oh: data.oh
                };
                if (data.w) {
                    imageData.w = data.w;
                }
                engine.insertImage(data.nodeId, imageData);
            }
        });
    }
    /**
     * 初始化入口
     */
    EditorUI.prototype.init = function () {
        var _this = this;
        this.initMenu();
        this.editorOperate.init();
        this.dragger.init();
        this.selector.init();
        this.imageEditor.initImageDrop();
        this.initToolkit();
        this.viewport.paper.on('click.click-message', '.content,.note', function () {
            _this.eventSource.trigger(SourceEvent.NODE_CLICK);
        });
        if (environment.isMobile) {
            this.viewport.paper.addClass('mobile-style');
        }
    };
    /**
     * 打开文档
     * @param definition
     * @param {string} name
     */
    EditorUI.prototype.openDocument = function (definition, name) {
        this.engine.open(definition, name);
    };
    /**
     *	初始化bullet菜单
     */
    EditorUI.prototype.initMenu = function () {
        var paper = this.viewport.paper;
        var menuTimeout;
        var modifyTipTimeout;
        var me = this;
        var hideMenu = function (bullet) {
            bullet.children('.menu-container').hide();
            clearTimeout(menuTimeout);
            clearTimeout(modifyTipTimeout);
            var nodeId = bullet.data('id');
            var container = getNodeContainer(nodeId);
            container.removeClass('active');
            bullet.children('.modified-hotspot').empty().hide();
        };
        // 菜单
        paper.on('mouseenter', '.bullet', function () {
            if (environment.isMobile) {
                // 移动端不需要这个菜单，否则有的时候点击可能会增加了选中样式
                return;
            }
            var bullet = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            if (bullet.hasClass('selecting')) {
                return;
            }
            var nodeId = bullet.data('id');
            var container = getNodeContainer(nodeId);
            if (container.hasClass('selected')) {
                // 被选择的时候，不出现菜单
                return;
            }
            clearTimeout(menuTimeout);
            clearTimeout(modifyTipTimeout);
            var targetNode = me.engine.getNode(nodeId);
            if (targetNode.modified || jquery__WEBPACK_IMPORTED_MODULE_0___default.a.trim(targetNode.text) || jquery__WEBPACK_IMPORTED_MODULE_0___default.a.trim(targetNode.note)) {
                var modifiedTip = bullet.children('.modified-hotspot');
                if (modifiedTip.length === 0) {
                    modifiedTip = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="modified-hotspot"></div>').appendTo(bullet);
                    modifiedTip.on('mouseleave', function () {
                        jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).empty();
                        clearTimeout(modifyTipTimeout);
                    });
                }
                modifiedTip.show();
            }
            else {
                bullet.children('.modified-hotspot').remove();
            }
            if (me.state.readonly) {
                // 当前是只读状态
                return;
            }
            menuTimeout = setTimeout(function () {
                var menu = bullet.children('.menu-container');
                if (menu.length === 0) {
                    var iconSize = 24;
                    var finishIcon = new default_1(IconSet.FINISH, iconSize);
                    var noteIcon = new default_1(IconSet.PEN_OUTLINE, iconSize);
                    var imageIcon = new default_1(IconSet.IMAGE_OUTLINE, iconSize);
                    // const exportIcon = new Icon(IconSet.EXPORT, iconSize);
                    var deleteIcon = new default_1(IconSet.DELETE, iconSize);
                    var h1Icon = new default_1(IconSet.HEADING1, iconSize);
                    var h2Icon = new default_1(IconSet.HEADING2, iconSize);
                    var h3Icon = new default_1(IconSet.HEADING3, iconSize);
                    // const penIcon = new Icon(IconSet.PEN, iconSize);
                    var metaKeyText = environment.metaKeyText;
                    var menuHtml = '<div class="menu-container"><div class="action-menu mindnote-menu"><ul>' +
                        '<li class="item action finish" data-action="finish" title="' + metaKeyText + ' + Enter"><span class="icon-wrapper">' + finishIcon.toString() + ("</span><span class=\"menu-text\">" + t('mindnote.editor.finish') + "</span></li>") +
                        '<li class="item action" data-action="edit-note" title="Shift + Enter"><span class="icon-wrapper">' + noteIcon.toString() + ("</span>" + t('mindnote.editor.edit_note') + "</li>") +
                        '<li class="item action" data-action="insert-image" title="Alt + Enter"><span class="icon-wrapper">' + imageIcon.toString() + ("</span>" + t('mindnote.editor.add_image') + "</li>") +
                        '<li class="split"></li>' +
                        // '<li class="item action" data-action="export"><span class="icon-wrapper">' + exportIcon.toString() + '</span>导出</li>' +
                        '<li class="item action" data-action="delete" title="' + metaKeyText + ' + Shift + Backspace"><span class="icon-wrapper">' + deleteIcon.toString() + ("</span>" + t('mindnote.editor.delete') + "</li>") +
                        '<li class="split"></li>' +
                        '<li class="heading-list">' +
                        '<span class="heading" data-level="1" title="Alt + 1">' + h1Icon.toString() + '</span>' +
                        '<span class="heading" data-level="2" title="Alt + 2">' + h2Icon.toString() + '</span>' +
                        '<span class="heading" data-level="3" title="Alt + 3">' + h3Icon.toString() + '</span>' +
                        // '<span class="heading" data-level="0" title="Alt + 4">' + penIcon.toString() + '</span>' +
                        '</li>' +
                        // '<li class="color-list"><div></div></li>' +
                        '</ul></div></div>';
                    menu = jquery__WEBPACK_IMPORTED_MODULE_0___default()(menuHtml).appendTo(bullet);
                    var colors = [
                        { value: '#333333', title: 'Alt + D（Default）' },
                        { value: '#dc2d1e', title: 'Alt + R（Red）' },
                        { value: '#ffaf38', title: 'Alt + Y（Yellow）' },
                        { value: '#75c940', title: 'Alt + G（Green）' },
                        { value: '#3da8f5', title: 'Alt + B（Blue）' },
                        { value: '#797ec9', title: 'Alt + P（Purple）' }
                    ];
                    var colorList_1 = menu.find('.color-list > div');
                    jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(colors, function (index, color) {
                        colorList_1.append('<span class="color-item" title="' + color.title + '" data-color="' + color.value + '" style="background:' + color.value + '"></span>');
                    });
                    var tipOption = {
                        position: 'right'
                    };
                    tooltip(menu.find('li[title]'))(tipOption);
                    var headingOption = {
                        position: 'right',
                        pointTo: menu.find('.heading-list')
                    };
                    tooltip(menu.find('.heading'))(headingOption);
                    var colorOption = {
                        position: 'right',
                        pointTo: menu.find('.color-list')
                    };
                    tooltip(menu.find('.color-item'))(colorOption);
                }
                menu.find('heading').removeClass('active');
                var heading = 0;
                if (targetNode.heading) {
                    heading = targetNode.heading;
                }
                menu.find('heading').removeClass('active');
                menu.find('.heading[data-level=' + heading + ']').addClass('active');
                if (container.hasClass('finished')) {
                    menu.find('.finish .menu-text').text(t('mindnote.editor.activate'));
                }
                else {
                    menu.find('.finish .menu-text').text(t('mindnote.editor.finish'));
                }
                menu.show();
                // 绑定菜单项事件
                menu.off().on('click', '.action', function (e) {
                    e.stopPropagation();
                    var action = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).data('action');
                    doAction(container, action);
                    hideMenu(bullet);
                });
                menu.find('.heading').off('click').on('click', function () {
                    var target = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
                    var level = parseInt(target.data('level'));
                    if (target.hasClass('active')) {
                        level = 0;
                    }
                    var success = me.engine.setNodeAttr(nodeId, 'heading', level);
                    if (!success) {
                        hideMenu(bullet);
                    }
                    menu.find('.heading').removeClass('active');
                    if (level === 0) {
                        target.removeClass('active');
                    }
                    else {
                        target.addClass('active');
                    }
                });
                menu.find('.color-item').off('click').on('click', function () {
                    var color = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).data('color');
                    var success = me.engine.setNodeAttr(nodeId, 'color', color);
                    if (!success) {
                        hideMenu(bullet);
                    }
                });
                container.addClass('active');
            }, 500);
        });
        paper.on('mouseleave', '.bullet', function () {
            var bullet = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            hideMenu(bullet);
        });
        /**
         * 编辑时间提示
         */
        paper.on('mouseenter', '.modified-hotspot', function () {
            var spot = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            var nodeId = spot.parent().data('id');
            modifyTipTimeout = setTimeout(function () {
                var targetNode = me.engine.getNode(nodeId);
                var content = '';
                if (targetNode.modified) {
                    content += t('mindnote.editor.edited_at') + ' ' + formatTime(targetNode.modified);
                }
                if (jquery__WEBPACK_IMPORTED_MODULE_0___default.a.trim(targetNode.text) || jquery__WEBPACK_IMPORTED_MODULE_0___default.a.trim(targetNode.text)) {
                    if (content) {
                        content += '<br>';
                    }
                    var countResult = countNodeWords([targetNode], false);
                    content += t('mindnote.editor.item_words') + countResult.wordCount;
                }
                if (content) {
                    spot.append('<div>' + content + '</div>');
                }
            }, 1200);
        });
        /**
         * 执行菜单项
         * @param container
         * @param action
         */
        var doAction = function (container, action) {
            var nodeId = container.attr('id');
            if (action === 'finish') {
                me.engine.toggleFinishNode(nodeId);
            }
            else if (action === 'delete') {
                me.engine.deleteNodeDirectly(nodeId);
            }
            else if (action === 'edit-note') {
                me.editNote(nodeId);
            }
            else if (action === 'copy') {
                me.engine.copyNode(nodeId);
            }
            else if (action === 'export') ;
            else if (action === 'insert-image') {
                me.imageEditor.insert(nodeId);
            }
        };
        // 控制展开收缩等小操作
        paper.on('click', '.toggle', function (e) {
            var wrapper = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).parent();
            var container = wrapper.parent();
            var expandNodeId = container.attr('id');
            me.engine.toggleExpand(expandNodeId);
            e.stopPropagation();
        });
    };
    /**
     * 删除节点
     * @param {string} nodeId
     */
    EditorUI.prototype.deleteNode = function (nodeId) {
        var container = getNodeContainer(nodeId);
        var currentContent = getContentById(nodeId);
        var text = jquery__WEBPACK_IMPORTED_MODULE_0___default.a.trim(currentContent.text());
        var currentNoteDom = container.children('.note');
        var currentNoteText = jquery__WEBPACK_IMPORTED_MODULE_0___default.a.trim(currentNoteDom.text());
        if (text === '' && currentNoteText === '') {
            // 没内容，直接删除
            this.engine.toPrevNode(nodeId, true);
            this.engine.deleteNode(nodeId);
        }
        else {
            // 有内容，查看同级上一节点有没有子节点，是否可以合并
            var prevNode = container.prev('.node');
            var prevId = prevNode.attr('id');
            if (prevNode.length === 0 || hasChildren$1(prevId)) {
                // 没有同级上一个节点或者上一节点有子主题，不能删除
                return;
            }
            var preNoteDom = prevNode.children('.note');
            var preNoteText = preNoteDom.text();
            if (preNoteText !== '') {
                // 前边节点有备注，不能合并
                return;
            }
            // 判断使用哪个节点的备注
            var preNote = currentNoteDom.html();
            // 设置合并节点的内容并格式化
            var preId = prevNode.attr('id');
            var preContent = getContentById(preId);
            var preEnd = preContent.text().length;
            preContent.append(currentContent.html());
            var formatValue = this.textEditor.formatText(preContent);
            // 可以合并
            this.engine.deleteNode(nodeId, preId, formatValue, preNote);
            // 把光标设置到上一节点原来结尾的位置
            setCursorPosition(preContent, { start: preEnd });
        }
    };
    /**
     * 创建同一级
     * @param nodeId
     */
    EditorUI.prototype.createNext = function (nodeId) {
        var rootNode = this.engine.getRootNode();
        if (rootNode && nodeId === rootNode.id) {
            this.engine.createNext(rootNode.id);
            return;
        }
        var content = getContentById(nodeId);
        var cursorPosition = getCursorPosition();
        var split = this.textEditor.getSplitHtml(content, cursorPosition);
        if (htmlToText(split[1]) === '') {
            // 没有选择文本，并且光标在文本最后
            this.engine.createNext(nodeId);
        }
        else {
            // 创建节点的文本
            // 当前节点的文本
            this.engine.createPrevious(nodeId, split[1], split[0]);
        }
    };
    /**
     * 添加备注
     * @param nodeId 节点id
     */
    EditorUI.prototype.editNote = function (nodeId) {
        var container = jquery__WEBPACK_IMPORTED_MODULE_0___default()('#' + nodeId);
        var note = container.children('.note');
        var exists = true;
        if (note.length === 0) {
            exists = false;
            note = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="note" contenteditable>\u200B</div>');
            var imageList = container.children('.attach-image-list');
            if (imageList.length > 0) {
                // 如果存在图片，在图片后边添加
                imageList.after(note);
            }
            else {
                container.children('.content-wrapper').after(note);
            }
        }
        focus(note);
        moveCursorEnd(note);
        if (!exists) {
            note.text('');
        }
    };
    /**
     * 初始化底部工具箱
     */
    EditorUI.prototype.initToolkit = function () {
        if (!environment.isMobile) {
            return;
        }
        var paper = this.viewport.paper;
        var me = this;
        // 给RN发消息，以控制工具栏
        paper.on('focus.toolkit', '.content', function () {
            var target = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            var focusNodeId = target.data('id');
            var node = me.engine.getNode(focusNodeId);
            var canIndent = me.engine.canIndent(node.id, 'indent');
            var canOutdent = me.engine.canIndent(node.id, 'outdent');
            var data = {
                type: 'content',
                node: node,
                canIndent: canIndent,
                canOutdent: canOutdent
            };
            me.eventSource.trigger(SourceEvent.INPUT_FOCUS, data);
        });
        paper.on('focus.toolkit', '.note', function () {
            var data = {
                type: 'note',
            };
            me.eventSource.trigger(SourceEvent.INPUT_FOCUS, data);
        });
        this.viewport.paperHeader.find('input').on('focus.toolkit', function () {
            var data = {
                type: 'title',
            };
            me.eventSource.trigger(SourceEvent.INPUT_FOCUS, data);
        });
    };
    EditorUI.prototype.executeEditAction = function (actionObj) {
        var paper = this.viewport.paper;
        var focusNode = paper.find('.content:focus');
        var actionName = actionObj.action;
        if (focusNode) {
            var focusNodeId = focusNode.data('id');
            if (actionName === EditActions.BLUR) {
                focusNode.blur();
                window.getSelection().removeAllRanges();
            }
            else if (actionName === EditActions.INDENT) {
                this.engine.indentNode(focusNodeId);
            }
            else if (actionName === EditActions.OUTDENT) {
                this.engine.outdentNode(focusNodeId);
            }
            else if (actionName === EditActions.NOTE) {
                this.editNote(focusNodeId);
            }
            else if (actionName === EditActions.DELETE) {
                this.engine.deleteNodeDirectly(focusNodeId);
            }
            else if (actionName === EditActions.FINISH) {
                this.engine.toggleFinishNode(focusNodeId);
            }
            else if (actionName === EditActions.BOLD || actionName === EditActions.ITALIC || actionName === EditActions.UNDERLINE) {
                this.textEditor.executeFormatAction(focusNode, actionName);
            }
            else if (actionName === EditActions.HEADING) {
                var node = this.engine.getNode(focusNodeId);
                if (node) {
                    var headingValue = actionObj.value;
                    if (headingValue === node.heading) {
                        headingValue = 0;
                    }
                    this.engine.setNodeAttr(focusNodeId, 'heading', headingValue);
                }
            }
        }
    };
    EditorUI.prototype.getFocusNode = function () {
        var focusNode = this.viewport.paper.find('.content:focus');
        if (focusNode.length === 0) {
            return null;
        }
        var focusNodeId = focusNode.data('id');
        var node = this.engine.getNode(focusNodeId);
        var cursorPosition = getCursorPosition();
        var contentText = new ContentText(focusNode);
        var bold = contentText.inTextFormatFlag('bold', cursorPosition);
        var italic = contentText.inTextFormatFlag('italic', cursorPosition);
        var underline = contentText.inTextFormatFlag('underline', cursorPosition);
        return {
            bold: bold,
            italic: italic,
            underline: underline,
            node: node
        };
    };
    return EditorUI;
}());

/**
 * Created by morris on 16/9/4.
 * 选择情况的暂存器，
 * 因为多个模块需要使用选择器的选中内容
 * 会出现循环依赖的问题。所以单独抽一个模块保存
 */
var SelectHolder = /** @class */ (function () {
    function SelectHolder() {
        this.selectedIds = [];
        this.selectNodes = [];
    }
    SelectHolder.prototype.setSelectIds = function (ids) {
        this.selectedIds = ids;
    };
    SelectHolder.prototype.setSelectNodes = function (nodes) {
        this.selectNodes = nodes;
    };
    SelectHolder.prototype.getSelectIds = function () {
        return this.selectedIds;
    };
    SelectHolder.prototype.getSelectNodes = function () {
        return this.selectNodes;
    };
    SelectHolder.prototype.clear = function () {
        this.selectedIds = [];
        this.selectNodes = [];
    };
    return SelectHolder;
}());

/**
 * Created by morris on 2017/12/26.
 * 图片上传中状态保存对象
 */
var ImageUploading = /** @class */ (function () {
    function ImageUploading() {
        this.imageUploading = {};
    }
    /**
     * 添加一个正在上传中的图片对象
     * @param nodeId
     * @param image
     */
    ImageUploading.prototype.add = function (nodeId, image) {
        var targetArr = this.imageUploading[nodeId];
        if (!targetArr) {
            targetArr = [];
        }
        targetArr.push(image);
        this.imageUploading[nodeId] = targetArr;
    };
    /**
     * 获取一个节点下正在上传的图片
     * @param nodeId
     * @returns {*|Array}
     */
    ImageUploading.prototype.getByNodeId = function (nodeId) {
        return this.imageUploading[nodeId] || [];
    };
    /**
     * 删除一个节点下正在上传的图片
     * @param imageId
     * @returns {*|Array}
     */
    ImageUploading.prototype.remove = function (imageId) {
        var _this = this;
        var nodeIds = Object.keys(this.imageUploading);
        var result = null;
        var matched = false;
        jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(nodeIds, function (index, nodeId) {
            var targetArr = _this.imageUploading[nodeId];
            if (targetArr) {
                jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(targetArr, function (nodeIndex, image) {
                    if (image.id === imageId) {
                        targetArr.splice(nodeIndex, 1);
                        matched = true;
                        result = nodeId;
                        // break;
                        return false;
                    }
                });
                if (matched) {
                    // break;
                    return false;
                }
            }
        });
        return result;
    };
    return ImageUploading;
}());

/**
 * 计算出两个字符串的差异，并抽象成操作符
 * @param str1 原始字符串
 * @param str2 更新字符串
 */
function diff(str1, str2) {
    /* 若两个字符串完全相等，则无操作符 */
    if (str1 === str2) {
        return null;
    }
    var len1Start = 0;
    var len2Start = 0;
    /* 从前向后找，找到第一个不相等的位置 */
    while (str1[len1Start] === str2[len2Start]) {
        len1Start += 1;
        len2Start += 1;
    }
    var len1End = str1.length;
    var len2End = str2.length;
    /* 从后向前找，找到第一个不相等的位置 */
    while (str1[len1End] === str2[len2End]) {
        if (len1End === len1Start || len2End === len2Start) {
            break;
        }
        len1End -= 1;
        len2End -= 1;
    }
    if (len1Start === len1End && str1.length < str2.length) {
        return {
            offset: len1Start,
            remove: '',
            insert: str2.substring(len2Start, len2End),
        };
    }
    if (len2Start === len2End && str1.length > str2.length) {
        return {
            offset: len1Start,
            remove: str1.substring(len1Start, len1End),
            insert: '',
        };
    }
    return {
        offset: len1Start,
        remove: str1.substring(len1Start, len1End + 1),
        insert: str2.substring(len2Start, len2End + 1),
    };
}
/**
 * 从两个字符串的更新操作，计算出光标的新位置
 * @param str1 原始字符串
 * @param str2 更新字符串
 * @param cursor 原始光标位置
 */
function diffCursor(str1, str2, cursor) {
    /* 获取两个字符串的差异 */
    var change = diff(str1, str2);
    /* 若无差异，则直接重置原始值 */
    if (change === null) {
        return cursor;
    }
    var _a = cursor[0], startOffset = _a === void 0 ? 0 : _a, _b = cursor[1], endOffset = _b === void 0 ? 0 : _b;
    /* 若修改的坐标小于等于起止坐标 */
    if (change.offset <= startOffset) {
        /* 计算本次修改对start光标定位的实际偏移量 */
        var moveOffset = change.insert.length - change.remove.length;
        if (moveOffset > 0) {
            /* 若是增加字符，则直接向前偏移 */
            startOffset += moveOffset;
        }
        else {
            /* 实际的偏移位置是当前光标位置距离change.offset和修改偏移量的最小值 */
            var realOffset = Math.min(startOffset - change.offset, Math.abs(moveOffset));
            startOffset -= realOffset;
        }
    }
    /* 若修改的坐标小于等于终止坐标 */
    if (change.offset <= endOffset) {
        /* 计算本次修改对start光标定位的实际偏移量 */
        var moveOffset = change.insert.length - change.remove.length;
        if (moveOffset > 0) {
            /* 若是增加字符，则直接向前偏移 */
            endOffset += moveOffset;
        }
        else {
            /* 实际的偏移位置是当前光标位置距离change.offset和修改偏移量的最小值 */
            var realOffset = Math.min(endOffset - change.offset, Math.abs(moveOffset));
            endOffset -= realOffset;
        }
    }
    return [startOffset, endOffset];
}

var EnginePainter = /** @class */ (function () {
    function EnginePainter(mod, uploadingHolder, nodePainter, viewport, state) {
        this.model = mod;
        this.imageUploading = uploadingHolder;
        this.nodePainter = nodePainter;
        this.wrapper = viewport.nodeWrapper;
        this.viewport = viewport;
        this.state = state;
    }
    EnginePainter.prototype.renderPaper = function () {
        var _this = this;
        var rootNode = this.model.getRootNode();
        var nodes;
        if (rootNode == null) {
            nodes = this.model.getDefine().nodes;
        }
        else {
            nodes = [rootNode];
        }
        this.wrapper.empty();
        if (nodes && nodes.length > 0) {
            // 绘制节点
            recursive(nodes, function (node) {
                _this.renderNode(node);
            });
            var firstContent = jquery__WEBPACK_IMPORTED_MODULE_0___default()('.content:first');
            if (firstContent.length && !environment.isMobile) {
                moveCursorEnd(firstContent);
            }
        }
    };
    /**
     * 更新文档title
     * @param {string} title
     */
    EnginePainter.prototype.setTitle = function (title) {
        if (!jquery__WEBPACK_IMPORTED_MODULE_0___default.a.trim(title)) {
            title = '';
        }
        var input = this.viewport.nameContainer.find('input').get(0);
        var oText = input.value;
        var prevStart = input.selectionStart || 0;
        var prevEnd = input.selectionEnd || 0;
        input.value = title;
        var _a = diffCursor(oText, title, [prevStart, prevEnd]), nextStart = _a[0], nextEnd = _a[1];
        input.setSelectionRange(nextStart, nextEnd);
    };
    /**
     * 刷新节点，用户节点更新时
     * @param node
     */
    EnginePainter.prototype.refreshNode = function (node) {
        var container = jquery__WEBPACK_IMPORTED_MODULE_0___default()('#' + node.id);
        if (container.length === 0) {
            // 节点不存在，可能已经被删除了，或者当前处于drill的状态
            return;
        }
        if (node.finish) {
            container.addClass('finished');
        }
        else {
            container.removeClass('finished');
        }
        if (node.collapsed) {
            container.addClass('collapsed');
        }
        else {
            container.removeClass('collapsed');
        }
        var wrapper = container.children('.content-wrapper');
        wrapper.removeClass('heading0 heading1 heading2 heading3');
        if (node.heading) {
            wrapper.addClass('heading' + node.heading);
        }
        var content = getContentByNode(container);
        if (node.color && node.color !== '#333333') {
            content.css('color', node.color);
        }
        else {
            content.css('color', '');
        }
        this.resetHtml(content, node.text || '');
        // 管理图片
        if ((node.images && node.images.length > 0) || this.imageUploading.getByNodeId(node.id).length > 0) {
            // 本身存在图片，或者有正在上传的图片
            this.nodePainter.renderNodeImages(node, container);
        }
        else {
            container.children('.attach-image-list').remove();
        }
        // 管理备注
        var noteEditor = container.children('.note');
        if (!node.note) {
            noteEditor.remove();
        }
        else {
            if (noteEditor.length === 0) {
                noteEditor = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="note" spellcheck="false"></div>');
                if (false === this.state.readonly) {
                    noteEditor.attr('contenteditable', 'true');
                }
                var imageList = container.children('.attach-image-list');
                if (imageList.length > 0) {
                    // 如果存在图片，在图片后边添加
                    imageList.after(noteEditor);
                }
                else {
                    container.children('.content-wrapper').after(noteEditor);
                }
            }
            this.resetHtml(noteEditor, node.note);
        }
    };
    /**
     * 创建节点的dom对象
     */
    EnginePainter.prototype.createNodeDom = function (node, readonly) {
        return this.nodePainter.render(node, readonly, this.model.isRootNode(node.id));
    };
    /**
     * 绘制节点
     * @param node
     * @param append 是否是在后边追加
     */
    EnginePainter.prototype.renderNode = function (node, append) {
        if (append == null) {
            append = true;
        }
        var target;
        var nodeDom = this.createNodeDom(node, false);
        var isTopLevel = this.model.isTopLevel(node.id);
        if (isTopLevel) {
            target = this.wrapper;
            if (this.model.isRootNode(node.id)) {
                nodeDom.addClass('root-node');
            }
        }
        else {
            var parentNode = this.model.getParent(node.id);
            var parentDom = jquery__WEBPACK_IMPORTED_MODULE_0___default()('#' + parentNode.id);
            target = parentDom.children('.children');
            if (target.length === 0) {
                target = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="children"></div>').appendTo(parentDom);
            }
        }
        if (append) {
            target.append(nodeDom);
        }
        else {
            target.prepend(nodeDom);
        }
    };
    /**
     * 在某一位置插入节点
     * @param parentId
     * @param index
     * @param node
     */
    EnginePainter.prototype.insertNode = function (parentId, index, node, rootNode) {
        var target = this.wrapper;
        if (parentId) {
            var parentDom = getNodeContainer(parentId);
            if (parentDom.length === 0) {
                // 父元素不存在，可能进入了drill状态，或者在本地已经被删除了
                return;
            }
            target = parentDom.children('.children');
            if (target.length === 0) {
                target = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="children"></div>').appendTo(parentDom);
            }
        }
        else if (rootNode != null) {
            // 当前进入了某个节点，而现在需要insert一个顶级节点，直接不处理
            // 否则会添加到现在的wrapper中，位置不对
            return;
        }
        var nodeDom = this.createNodeDom(node, false);
        if (index === 0) {
            // 第一个
            target.prepend(nodeDom);
        }
        else {
            target.children('.node:eq(' + (index - 1) + ')').after(nodeDom);
        }
    };
    /**
     * 在当前节点前边绘制节点
     * @param currentId
     * @param node
     */
    EnginePainter.prototype.renderPrevious = function (currentId, node) {
        var currentDom = getNodeContainer(currentId);
        var nodeDom = this.createNodeDom(node, false);
        currentDom.before(nodeDom);
    };
    /**
     * 在当前节点后边绘制节点
     * @param currentId
     * @param nextNode
     */
    EnginePainter.prototype.renderNext = function (currentId, nextNode) {
        var currentDom = getNodeContainer(currentId);
        var nodeDom = this.createNodeDom(nextNode, false);
        currentDom.after(nodeDom);
    };
    /**
     * 绘制第一个子节点
     * @param currentId
     * @param nextNode
     */
    EnginePainter.prototype.renderFirstChild = function (currentId, nextNode) {
        var parentDom = getNodeContainer(currentId);
        var target = parentDom.children('.children');
        if (target.length === 0) {
            target = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="children"></div>').appendTo(parentDom);
        }
        var nodeDom = this.createNodeDom(nextNode, false);
        target.prepend(nodeDom);
    };
    /**
     * 绘制全部子节点
     * @param nodeId
     */
    EnginePainter.prototype.renderChildren = function (nodeId) {
        var _this = this;
        var node = this.model.getById(nodeId);
        if (!node.children) {
            return;
        }
        var parentDom = getNodeContainer(nodeId);
        var target = parentDom.children('.children');
        if (target.length === 0) {
            target = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="children"></div>').appendTo(parentDom);
        }
        target.empty();
        // 绘制节点
        recursive(node.children, function (child) {
            _this.renderNode(child);
        });
    };
    /**
     * 删除节点
     * @param {Node} node
     */
    EnginePainter.prototype.removeNode = function (node) {
        getNodeContainer(node.id).remove();
    };
    /**
     * 重设节点内容，并且还原光标
     * @param $node 重设节点
     * @param html html内容
     */
    EnginePainter.prototype.resetHtml = function ($node, html) {
        var oText = $node.text();
        var selection = window.getSelection();
        if (!selection.anchorNode) {
            $node.html(html);
            return;
        }
        var oRange = selection.getRangeAt(0);
        var startOffset = getCursorOffset($node, jquery__WEBPACK_IMPORTED_MODULE_0___default()(oRange.startContainer), oRange.startOffset);
        var endOffset = getCursorOffset($node, jquery__WEBPACK_IMPORTED_MODULE_0___default()(oRange.endContainer), oRange.endOffset);
        $node.html(html);
        /* 若光标不在更新区域，则直接返回 */
        if (!$node.get(0).contains(oRange.startContainer)) {
            return;
        }
        var cText = $node.text();
        var _a = diffCursor(oText, cText, [startOffset, endOffset]), start = _a[0], end = _a[1];
        setCursorPosition($node, {
            start: start,
            end: end,
        });
    };
    return EnginePainter;
}());

var tagWhiteList = 'b,i,u,span,a';
var attributeWhiteList = {
    b: [],
    i: [],
    u: [],
    span: ['class'],
    a: ['class', 'href', 'ref', 'target'],
};
/**
 * 处理一个元素中的内容，保证其内容的安全性
 */
function makeContentSafe(contentContainer) {
    // 过滤掉不允许的标签
    contentContainer.find('*:not(' + tagWhiteList + ')').remove();
    // 过滤不允许的属性
    contentContainer.find(tagWhiteList).each(function () {
        var tag = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
        var tagElement = tag[0];
        var tagName = tagElement.tagName.toLowerCase();
        var tagAttrWhiteList = attributeWhiteList[tagName];
        // 元素的所有属性
        var attrNames = Object(lodash_es__WEBPACK_IMPORTED_MODULE_10__["default"])(tagElement.attributes, function (attr) {
            return attr.name;
        });
        Object(lodash_es__WEBPACK_IMPORTED_MODULE_5__["default"])(attrNames, function (attrName) {
            if (tagAttrWhiteList.indexOf(attrName) < 0) {
                // 此属性不在白名单范围中
                tag.removeAttr(attrName);
            }
        });
    });
    contentContainer.find('a').each(function () {
        var link = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
        // 替换掉所有空白字符
        var href = link.attr('href');
        if (href && href.replace(/\s/g, '').toLowerCase().indexOf('javascript:') >= 0) {
            link.removeAttr('href');
        }
    });
}

/**
 * 构建节点
 * @param node
 * @param container
 */
function buildNode(node, container) {
    var nodeDom = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<li></li>').appendTo(container);
    var contentHtmlDom = jquery__WEBPACK_IMPORTED_MODULE_0___default.a.parseHTML('<span class="content mubu-node">' + node.text + '</span>');
    var contentDom = jquery__WEBPACK_IMPORTED_MODULE_0___default()(contentHtmlDom);
    makeContentSafe(contentDom);
    nodeDom.append(contentDom);
    // 必须要给链接设置颜色，否则pdf中就是蓝色
    if (node.finish) {
        contentDom.addClass('finished');
        contentDom.css('text-decoration', 'line-through');
        nodeDom.css('color', '#a0a0a0');
        nodeDom.find('.content-link').css('color', '#a0a0a0');
    }
    else if (node.color) {
        contentDom.css({
            color: node.color,
        });
        contentDom.attr('color', node.color);
    }
    var lineHeight = 22;
    var minHeight = 22;
    var fontSize = 14;
    if (node.heading) {
        if (node.heading === 1) {
            lineHeight = 32;
            minHeight = 32;
            fontSize = 24;
        }
        else if (node.heading === 2) {
            lineHeight = 28;
            minHeight = 28;
            fontSize = 21;
        }
        else if (node.heading === 3) {
            lineHeight = 24;
            minHeight = 24;
            fontSize = 18;
        }
        contentDom.attr('heading', node.heading);
    }
    nodeDom.css({
        'line-height': lineHeight + 'px',
    });
    contentDom.css({
        'line-height': lineHeight + 'px',
        'min-height': minHeight + 'px',
        'font-size': fontSize + 'px',
    });
    if (node.collapsed) {
        nodeDom.addClass('collapsed');
        contentDom.addClass('collapsed');
    }
    if (node.images && node.images.length > 0) {
        contentDom.attr('images', encodeURIComponent(JSON.stringify(node.images)));
        jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(node.images, function (index, img) {
            var imgUrl = img.uri;
            var imgObj = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<img src="' + imgUrl + '" style="max-width: 720px;" class="attach-img"/>');
            if (img.w) {
                imgObj.css('width', img.w);
            }
            var imgContainer = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div style="padding: 3px 0"></div>');
            imgContainer.append(imgObj);
            nodeDom.append(imgContainer);
        });
    }
    if (node.note) {
        var note = node.note.replace(new RegExp('\n', 'gm'), '<br/>');
        var noteHtmlDom = jquery__WEBPACK_IMPORTED_MODULE_0___default.a.parseHTML('<span class="note">' + note + '</span>');
        var noteDom = jquery__WEBPACK_IMPORTED_MODULE_0___default()(noteHtmlDom);
        makeContentSafe(noteDom);
        nodeDom.append('<br/>');
        nodeDom.append(noteDom);
    }
    // 构建子节点
    if (node.children && node.children.length > 0) {
        var childrenContainer_1 = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<ul class="children" style="list-style-type: disc;"></ul>').appendTo(nodeDom);
        jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(node.children, function (index, child) {
            buildNode(child, childrenContainer_1);
        });
    }
}
function convertToHtml(nodes) {
    var wrapper = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div></div>');
    var container = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<ul></ul>').appendTo(wrapper);
    // 构建内容
    if (nodes) {
        jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(nodes, function (index, node) {
            buildNode(node, container);
        });
    }
    // 设置样式，样式必须要设置在行内
    wrapper.find('ul').css({
        'list-style': 'disc',
        'list-style-position': 'outside',
    });
    wrapper.find('.content').css({
        display: 'inline-block',
        'vertical-align': 'top',
    });
    wrapper.find('.note').css({
        display: 'inline-block',
        color: '#888',
        'line-height': '18px',
        'min-height': '18px',
        'font-size': '13px',
        'padding-bottom': '2px',
    });
    wrapper.find('.children').css({
        'padding-bottom': '4px',
    });
    wrapper.find('.bold').css({
        'font-weight': 'bold',
    });
    wrapper.find('.underline').css({
        'text-decoration': 'underline',
    });
    wrapper.find('.italic').css({
        'font-style': 'italic',
    });
    wrapper.find('.tag').css({
        'text-decoration': 'underline',
        opacity: '0.6',
        color: 'inherit',
    });
    wrapper.find('.content-link').css({
        'text-decoration': 'underline',
        opacity: '0.6',
        color: 'inherit',
    });
    return wrapper.html();
}
var nodeCount = 0;
/**
 * html结构转成node定义
 * @param html
 */
function htmlToNode(html) {
    var result = [];
    nodeCount = 0;
    var container = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div></div>');
    if (html.indexOf('<body') >= 0 && html.indexOf('</body>') >= 0) {
        html = jquery__WEBPACK_IMPORTED_MODULE_0___default()(html).find('body').html();
    }
    container.html(html);
    // 如果有export-wrapper的节点，则是copy的幕布的内容，IE下copy的时候，会把外面的的这个div也复制上，所以这里获取他里边的内容
    var wrapper = container.find('.export-wrapper');
    if (wrapper.length) {
        html = wrapper.html();
    }
    container.html(html);
    if (container.find('.mubu-node').length > 0) {
        // 是幕布格式的html，执行幕布转换
        // 用于文档内的复制与粘贴
        if (container.children('.content').length > 0) {
            // 根目录就存在content了，说明没copy上最外层的ul，手动套一层
            container.html('<ul><li>' + html + '</li></ul>');
        }
        container.find('.content-link').removeAttr('style');
        var rootList = container.children('ul').children('li');
        buildMubuNode(rootList, result);
    }
    else if (container.find('.node').length > 0
        && container.find('.content-wrapper').length > 0
        && container.find('.bullet-wrapper').length > 0
        && container.find('.content[data-id]').length > 0) {
        // 是幕布文档格式的html，执行幕布转换
        if (container.children('.content-wrapper').length > 0) {
            // 根目录就存在content了，说明没copy上最外层的node，手动套一层
            container.html('<div class="node">' + html + '</div>');
        }
        container.find('.content-link').removeAttr('style');
        var rootList = container.children('.node');
        buildMubuDocNode(rootList, result);
    }
    else if (container.find('.name[data-wfid]').length > 0) {
        // 是workflowy的内容
        if (container.children('.name').length > 0) {
            // 根目录就存在content了，说明没copy上最外层的ul，手动套一层
            container.html('<ul><li>' + html + '</li></ul>');
        }
        var rootList = container.children('ul').children('li');
        buildWorkflowyNode(rootList, result);
    }
    else {
        buildNormalNode(container, result);
        // 对html文本进行转义
        recursive(result, function (resultNode) {
            resultNode.text = jquery__WEBPACK_IMPORTED_MODULE_0___default.a.trim(resultNode.text
                .replace(new RegExp('<', 'g'), '&lt;')
                .replace(new RegExp('>', 'g'), '&gt;'));
        });
    }
    if (nodeCount === 0) {
        html = html.replace(/<br>/g, '\n').replace(/<br\/>/g, '\n');
        container.html(html);
        // 没有被html格式化成多个节点，用换行符分隔
        var lines = container.text().split('\n');
        if (lines.length > 0) {
            result = [];
            jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(lines, function (index, line) {
                if (jquery__WEBPACK_IMPORTED_MODULE_0___default.a.trim(line) !== '') {
                    nodeCount++;
                    result.push({
                        text: line,
                    });
                }
            });
        }
        // 对html文本进行转义
        recursive(result, function (resultNode) {
            resultNode.text = jquery__WEBPACK_IMPORTED_MODULE_0___default.a.trim(resultNode.text
                .replace(new RegExp('<', 'g'), '&lt;')
                .replace(new RegExp('>', 'g'), '&gt;'));
        });
    }
    return {
        size: nodeCount,
        nodes: result,
    };
}
/**
 * 递归转换幕布导出格式的节点
 * 同样适用于对于文档内容的粘贴与复制
 * @param list
 * @param targetArr
 */
function buildMubuNode(list, targetArr) {
    list.each(function () {
        var item = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
        var contentBox = item.children('.content');
        var content = contentBox.html() || '';
        var nodeObj = {
            text: content,
        };
        var noteDom = item.children('.note');
        if (noteDom.length > 0 && noteDom.text() !== '') {
            nodeObj.note = noteDom.html();
        }
        if (contentBox.hasClass('finished')) {
            nodeObj.finish = true;
        }
        if (contentBox.hasClass('collapsed')) {
            nodeObj.collapsed = true;
        }
        if (contentBox.attr('heading')) {
            var heading = parseInt(contentBox.attr('heading'));
            if (heading) {
                nodeObj.heading = heading;
            }
        }
        if (contentBox.attr('color')) {
            nodeObj.color = contentBox.attr('color');
        }
        if (contentBox.attr('images')) {
            nodeObj.images = JSON.parse(decodeURIComponent(contentBox.attr('images')));
        }
        targetArr.push(nodeObj);
        nodeCount++;
        var childrenContainer = item.children('ul');
        if (childrenContainer.length > 0) {
            var childrenItems = childrenContainer.children('li');
            if (childrenItems.length > 0) {
                nodeObj.children = [];
                buildMubuNode(childrenItems, nodeObj.children);
            }
        }
    });
}
/**
 * 递归转换幕布源文档格式的html
 * @param list
 * @param targetArr
 */
function buildMubuDocNode(list, targetArr) {
    list.each(function () {
        var item = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
        var contentWrapper = item.children('.content-wrapper');
        var contentBox = contentWrapper.children('.content');
        var content = contentBox.html();
        var nodeObj = {
            text: content,
        };
        var noteDom = item.children('.note');
        if (noteDom.length > 0 && noteDom.text() !== '') {
            nodeObj.note = noteDom.html();
        }
        if (item.hasClass('finished')) {
            nodeObj.finish = true;
        }
        if (item.hasClass('collapsed')) {
            nodeObj.collapsed = true;
        }
        if (contentWrapper.hasClass('heading1')) {
            nodeObj.heading = 1;
        }
        if (contentWrapper.hasClass('heading2')) {
            nodeObj.heading = 2;
        }
        if (contentWrapper.hasClass('heading3')) {
            nodeObj.heading = 3;
        }
        if (contentWrapper.attr('color')) {
            nodeObj.color = contentWrapper.attr('color');
        }
        var imageList = item.children('.attach-image-list');
        if (imageList.length > 0) {
            nodeObj.images = [];
            imageList.children('.attach-image-item').each(function () {
                var imgDefStr = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).attr('def');
                if (imgDefStr) {
                    var imgDef = JSON.parse(decodeURIComponent(imgDefStr));
                    nodeObj.images.push(imgDef);
                }
            });
        }
        targetArr.push(nodeObj);
        nodeCount++;
        var childrenContainer = item.children('.children');
        if (childrenContainer.length > 0) {
            var childrenItems = childrenContainer.children('.node');
            if (childrenItems.length > 0) {
                nodeObj.children = [];
                buildMubuDocNode(childrenItems, nodeObj.children);
            }
        }
    });
}
/**
 * 递归转换workflowy的节点
 * @param list
 * @param targetArr
 */
function buildWorkflowyNode(list, targetArr) {
    list.each(function () {
        var item = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
        var content = item.children('.name');
        var text = content.text();
        var nodeObj = {
            text: text,
        };
        var noteDom = item.children('.note');
        if (noteDom.length > 0 && noteDom.text() !== '') {
            nodeObj.note = noteDom.text();
        }
        if (content.hasClass('done')) {
            nodeObj.finish = true;
        }
        targetArr.push(nodeObj);
        nodeCount++;
        var childrenContainer = item.children('ul');
        if (childrenContainer.length > 0) {
            var childrenItems = childrenContainer.children('li');
            if (childrenItems.length > 0) {
                nodeObj.children = [];
                buildWorkflowyNode(childrenItems, nodeObj.children);
            }
        }
    });
}
var blockSelector = 'div,p,ul,ol,li,pre,h1,h2,h3,h4,h5,h6,blockquote,table,tbody,tr';
function buildNormalNode(container, targetArr) {
    var childNodes = container[0].childNodes;
    var newLine = true;
    for (var i = 0; i < childNodes.length; i++) {
        var childNode = childNodes[i];
        var $childNode = jquery__WEBPACK_IMPORTED_MODULE_0___default()(childNode);
        var isBlock = $childNode.is(blockSelector);
        if (isBlock) {
            if ($childNode.is('li')) {
                // 是列表项目，判断下级
                var nextLevel = $childNode.children('ul,ol');
                if (nextLevel.length > 0) {
                    var copy$$1 = jquery__WEBPACK_IMPORTED_MODULE_0___default()(childNode).clone();
                    // 克隆一份，获取内容
                    copy$$1.children('ul,ol').nextAll().remove();
                    copy$$1.children('ul,ol').remove();
                    var eleText = copy$$1.text();
                    var item = {
                        text: eleText,
                        children: [],
                    };
                    targetArr.push(item);
                    nodeCount++;
                    copy$$1.empty().append(nextLevel);
                    buildNormalNode(copy$$1, item.children);
                }
                else {
                    buildNormalNode($childNode, targetArr);
                }
            }
            else if ($childNode.is('tr')) {
                // 如果是table的tr，给每列中间加一个/t分隔文本
                $childNode.children('td').each(function (index) {
                    if (index !== 0) {
                        jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).prepend('\t');
                    }
                });
                buildNormalNode($childNode, targetArr);
            }
            else {
                buildNormalNode($childNode, targetArr);
            }
            newLine = true;
        }
        else if ($childNode.is('br')) {
            newLine = true;
        }
        else {
            var eleText = $childNode.text().replace(/\n/g, '');
            if (eleText) {
                if (newLine) {
                    if (jquery__WEBPACK_IMPORTED_MODULE_0___default.a.trim(eleText)) {
                        // 如果是新的行的开始，如果全是空格，也不添加
                        var item = {
                            text: eleText,
                        };
                        nodeCount++;
                        targetArr.push(item);
                        newLine = false;
                    }
                }
                else {
                    // 不是新的一行，向前追加内容
                    targetArr[targetArr.length - 1].text += eleText;
                    newLine = false;
                }
            }
        }
    }
}

/**
 * Created by morris on 16/8/18.
 * 实现说明：
 * 用content元素来响应鼠标
 * 通过坐标的计算来判断选中了哪些主题
 * 选中的样式添加到节点上
 */
var Selector = /** @class */ (function () {
    function Selector(model, engine, state, selectHolder, viewport) {
        // 当前所有主题的，保存到一个数组中
        this.nodeArray = [];
        // 每一个节点的索引
        this.nodeIndex = {};
        // 选中的id数组
        this.selected = [];
        // 选中的节点对象，树形结构
        this.selectedNodes = [];
        // 是否全部完成了
        this.allFinished = true;
        this.allHeading = 0;
        this.totalIndex = 0;
        this.operateEvent = 'keydown.selector-operate';
        this.model = model;
        this.engine = engine;
        this.selectHolder = selectHolder;
        this.state = state;
        this.wrapper = viewport.nodeWrapper;
        this.viewport = viewport;
    }
    Selector.prototype.initNodes = function () {
        this.totalIndex = 0;
        this.nodeArray = [];
        this.nodeIndex = {};
        var nodes = this.model.getRootSubNodes();
        this.addNodeArray(nodes);
    };
    Selector.prototype.addNodeArray = function (nodes) {
        var me = this;
        if (nodes && nodes.length > 0) {
            jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(nodes, function (index, node) {
                me.nodeArray.push(node);
                me.nodeIndex[node.id] = me.totalIndex;
                if (node.id === me.sourceId) {
                    me.sourceIndex = me.totalIndex;
                }
                me.totalIndex++;
                if (!node.collapsed && node.children) {
                    me.addNodeArray(node.children);
                }
            });
        }
    };
    /**
     * 查找节点
     * 用户鼠标框选
     * @param currentY 当前鼠标Y坐标
     */
    Selector.prototype.findSelectByPosition = function (currentY) {
        var sourcePosition = this.sourceBeginTarget.offset();
        this.selected = [];
        var i;
        var testNode;
        var selfDistance = 5; // 距离自己多远，就认为选中了自己
        var siblingsDistance = 10; // 进入到旁边元素多远，就认为选中了旁边的元素
        if (currentY < sourcePosition.top - selfDistance) {
            // 鼠标在源元素的上边，向上查找
            for (i = this.sourceIndex - 1; i >= 0; i--) {
                testNode = this.nodeArray[i];
                var nodeContainer = getNodeContainer(testNode.id);
                var contentBottom = nodeContainer.offset().top;
                var contentWrapper = nodeContainer.children('.content-wrapper');
                contentBottom += contentWrapper.outerHeight();
                var noteEditor = nodeContainer.children('.note');
                if (noteEditor.length) {
                    contentBottom += noteEditor.outerHeight();
                }
                var imageList = nodeContainer.children('.attach-image-list');
                if (imageList.length) {
                    contentBottom += imageList.outerHeight();
                }
                if (currentY < contentBottom - siblingsDistance) {
                    // 在范围内
                    this.selected.push(testNode.id);
                }
                else {
                    break;
                }
            }
            this.selected.reverse();
            this.selected.push(this.sourceId);
        }
        else if (currentY > sourcePosition.top + this.sourceBeginTarget.outerHeight() + selfDistance) {
            // 鼠标在源元素的下边，向下查找
            for (i = this.sourceIndex + 1; i < this.nodeArray.length; i++) {
                testNode = this.nodeArray[i];
                var contentDom = getContentById(testNode.id);
                var contentTop = contentDom.offset().top;
                if (currentY > contentTop + siblingsDistance) {
                    // 在范围内
                    this.selected.push(testNode.id);
                }
                else {
                    break;
                }
            }
            // 将自己插入到最前边
            this.selected.splice(0, 0, this.sourceId);
        }
        this.setSelected();
    };
    /**
     * 查找sourceId到目标id范围中的所有节点
     * 用于shift + 鼠标多选
     */
    Selector.prototype.findSelectByRange = function (targetId) {
        this.initNodes();
        this.selected = [];
        var sourceIndex = this.nodeIndex[this.sourceId];
        var targetIndex = this.nodeIndex[targetId];
        var beginIndex = Math.min(sourceIndex, targetIndex);
        var endIndex = Math.max(sourceIndex, targetIndex);
        while (beginIndex <= endIndex) {
            this.selected.push(this.nodeArray[beginIndex].id);
            beginIndex++;
        }
        this.setSelected();
        this.selectChanged();
    };
    /**
     * 全选
     */
    Selector.prototype.selectAll = function () {
        this.initNodes();
        if (this.nodeArray.length) {
            this.sourceId = this.nodeArray[0].id;
        }
        this.selected = [];
        var me = this;
        jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(this.nodeArray, function (index, node) {
            me.selected.push(node.id);
        });
        this.setSelected();
        this.selectChanged();
    };
    /**
     * 选中同级元素
     * @param type 正负值，标示向前还是向后
     */
    Selector.prototype.selectSiblings = function (type) {
        if (this.selected.length === 0) {
            // 首先source为选中，后边的处理逻辑就可以都按已经有选中的情况处理了
            this.selected = [this.sourceId];
            this.setSelected();
        }
        else {
            var firstId = this.selected[0];
            if (type < 0) {
                // 向上
                if (firstId === this.sourceId && this.selectedNodes.length > 1) {
                    // 说明当前已经向下选择，去除最后一个节点的选择
                    this.selectedNodes.splice(this.selectedNodes.length - 1, 1);
                    this.setSelectedByNodes();
                }
                else {
                    // 向上选择
                    var firstIndex = this.nodeIndex[firstId];
                    var prependIds = []; // 向上添加选中的节点id
                    if (this.model.isRootSubNode(firstId)) {
                        // 第一个节点已经是顶级节点，向上查找顶级节点
                        var prevNode = this.model.getPrevSibling(firstId);
                        if (prevNode) {
                            prependIds.push(prevNode.id);
                        }
                    }
                    else if (firstIndex > 0) {
                        // 直接向上添加一个节点
                        prependIds.push(this.nodeArray[firstIndex - 1].id);
                    }
                    if (prependIds.length) {
                        this.selected = prependIds.concat(this.selected);
                        this.setSelected();
                    }
                }
            }
            else {
                // 向下
                if (firstId !== this.sourceId) {
                    // 说明当前已经向上选择，去除第一个节点的选择
                    if (this.selectedNodes.length > 1) {
                        // 选中了多个根节点，直接删除根节点
                        this.selectedNodes.splice(0, 1);
                        this.setSelectedByNodes();
                    }
                    else if (this.selectedNodes.length === 1) {
                        // 选中第一个子节点到source节点中间的内容
                        this.findSelectByRange(this.selectedNodes[0].children[0].id);
                        return;
                    }
                }
                else {
                    // 执行向下选择
                    var lastId = this.selectedNodes[this.selectedNodes.length - 1].id;
                    var lastIndex = this.nodeIndex[lastId];
                    var appendIds = []; // 向上添加选中的节点id
                    var nextNode = this.model.getNextSibling(lastId);
                    if (nextNode) {
                        appendIds.push(nextNode.id);
                    }
                    else if (lastIndex < this.nodeArray.length - 1) {
                        // 直接向下添加一个节点
                        appendIds.push(this.nodeArray[lastIndex + 1].id);
                    }
                    if (appendIds.length) {
                        this.selected = this.selected.concat(appendIds);
                        this.setSelected();
                    }
                }
            }
        }
        this.selectChanged();
    };
    /**
     * 设置选中样式，构造选中的节点对象
     */
    Selector.prototype.setSelected = function () {
        var me = this;
        me.allFinished = true;
        jquery__WEBPACK_IMPORTED_MODULE_0___default()('.node.selected').removeClass('selected');
        me.selectedNodes = [];
        jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(me.selected, function (ind, nodeId) {
            getNodeContainer(nodeId).addClass('selected');
            var node = me.model.getById(nodeId);
            // node 可能已经在协同中被删除了
            if (!node) {
                return;
            }
            if (me.model.isRootSubNode(nodeId)) {
                // 是顶级节点，就添加
                me.selectedNodes.push(node);
            }
            else {
                // 如果父节点没被选中，视其因为第一级节点
                var parentNode = me.model.getParent(nodeId);
                if (me.selected.indexOf(parentNode.id) < 0) {
                    me.selectedNodes.push(node);
                }
            }
        });
        // 重新计算selected，因为选择主节点后，要包括所有子节点，包括没在框选范围内的子节点
        me.selected = [];
        var index = 0;
        recursive(me.selectedNodes, function (node) {
            me.selected.push(node.id);
            if (!node.finish) {
                me.allFinished = false;
            }
            var nodeHeading = (node.heading || 0);
            if (index === 0) {
                me.allHeading = nodeHeading;
            }
            else {
                if (nodeHeading !== me.allHeading) {
                    me.allHeading = -1;
                }
            }
            index++;
        });
    };
    /**
     * 设置选中样式，构造选中的节点对象
     */
    Selector.prototype.setSelectedByNodes = function () {
        var me = this;
        me.allFinished = true;
        jquery__WEBPACK_IMPORTED_MODULE_0___default()('.node.selected').removeClass('selected');
        // 重新计算selected，因为选择主节点后，要包括所有子节点，包括没在框选范围内的子节点
        me.selected = [];
        recursive(me.selectedNodes, function (node) {
            me.selected.push(node.id);
            if (!node.finish) {
                me.allFinished = false;
            }
            getNodeContainer(node.id).addClass('selected');
        });
    };
    /**
     * 创建菜单
     */
    Selector.prototype.createMenu = function () {
        var me = this;
        if (me.state.readonly) {
            return;
        }
        // 创建菜单
        this.viewport.paper.find('.mindnote-selector-menu').remove();
        if (me.selected.length > 1) {
            var firstId = this.selected[0];
            var firstContainer = getNodeContainer(firstId);
            var menu = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="mindnote-selector-menu mindnote-menu action-menu"></div>').appendTo(firstContainer);
            menu.show();
            var metaKeyText = environment.metaKeyText;
            var iconSize = 24;
            var finishIcon = new default_1(IconSet.FINISH, iconSize);
            // const exportIcon = new Icon(IconSet.EXPORT, iconSize);
            var deleteIcon = new default_1(IconSet.DELETE, iconSize);
            var h1Icon = new default_1(IconSet.HEADING1, iconSize);
            var h2Icon = new default_1(IconSet.HEADING2, iconSize);
            var h3Icon = new default_1(IconSet.HEADING3, iconSize);
            // const penIcon = new Icon(IconSet.PEN, iconSize);
            var list_1 = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<ul>' +
                ("<li class=\"item finish\" title=\"" + metaKeyText + " + Enter\"><span class=\"icon-wrapper\">" + finishIcon.toString() + "</span><span class=\"menu-text\">" + t('mindnote.editor.finish') + "</span></li>") +
                // '<li class="item export"><span class="icon-wrapper">' + exportIcon.toString() + '</span>导出</li>' +
                '<li class="split"></li>' +
                ("<li class=\"item delete\" title=\"Backspace\"><span class=\"icon-wrapper\">" + deleteIcon.toString() + "</span>" + t('mindnote.editor.delete') + "</li>") +
                '<li class="split"></li>' +
                '<li class="heading-list">' +
                '<span class="heading" data-level="1" title="Alt + 1">' + h1Icon.toString() + '</span>' +
                '<span class="heading" data-level="2" title="Alt + 2">' + h2Icon.toString() + '</span>' +
                '<span class="heading" data-level="3" title="Alt + 3">' + h3Icon.toString() + '</span>' +
                // '<span class="heading" data-level="0" title="Alt + 4">' + penIcon.toString() + '</span>' +
                '</li>' +
                // '<li class="split"></li>' +
                // '<li class="color-list"><div></div></li>' +
                '<li class="split"></li>' +
                '</ul>');
            var colors = [
                { value: '#333333', title: 'Alt + D（Default）' },
                { value: '#dc2d1e', title: 'Alt + R（Red）' },
                { value: '#ffaf38', title: 'Alt + Y（Yellow）' },
                { value: '#75c940', title: 'Alt + G（Green）' },
                { value: '#3da8f5', title: 'Alt + B（Blue）' },
                { value: '#797ec9', title: 'Alt + P（Purple）' }
            ];
            var colorList_1 = list_1.find('.color-list > div');
            jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(colors, function (index, color) {
                colorList_1.append('<span class="color-item" title="' + color.title + '" data-color="' + color.value + '" style="background:' + color.value + '"></span>');
            });
            list_1.appendTo(menu);
            if (me.allFinished) {
                menu.find('.finish .menu-text').text(t('mindnote.editor.activate'));
            }
            menu.find('heading').removeClass('active');
            if (me.allHeading >= 0) {
                menu.find('.heading[data-level=' + me.allHeading + ']').addClass('active');
            }
            // TODO tooltip
            // list.find('li[title]').tooltip({
            // 	position: 'right'
            // });
            //
            // const headingOption = {
            // 	position: 'right',
            // 	pointTo: list.find('.heading-list')
            // };
            // list.find('.heading').tooltip(headingOption);
            //
            // const colorOption = {
            // 	position: 'right',
            // 	pointTo: list.find('.color-list')
            // };
            // list.find('.color-item').tooltip(colorOption);
            list_1.on('mousedown', function (e) {
                e.stopPropagation();
                e.preventDefault();
            });
            list_1.find('.finish').on('click', function () {
                me.toggleFinish();
                me.setCopyContent();
            });
            list_1.find('.delete').on('click', function (e) {
                // 阻止冒泡的目的是：如果全选删除的情况下，click会触发wrapper的click，创建出第一个节点
                e.stopPropagation();
                me.delete();
            });
            list_1.find('.export').on('click', function () {
                me.doExport();
            });
            list_1.find('.heading').on('click', function () {
                var target = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
                var level = parseInt(target.data('level'));
                if (target.hasClass('active')) {
                    level = 0;
                }
                me.setNodeAttr('heading', level);
                me.setCopyContent();
                list_1.find('.heading').removeClass('active');
                if (level === 0) {
                    target.removeClass('active');
                }
                else {
                    target.addClass('active');
                }
            });
            list_1.find('.color-item').on('click', function () {
                var color = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).data('color');
                me.setNodeAttr('color', color);
                me.setCopyContent();
            });
            var _a = countNodeWords(me.selectedNodes, true), nodeCount = _a.nodeCount, wordCount = _a.wordCount;
            menu.append("<div class=\"character-count\">" + t('mindnote.editor.selected_items', nodeCount, nodeCount > 1 ? 's' : '') + "</div>");
            menu.append("<div class=\"character-count\">" + t('mindnote.editor.selected_words', wordCount, wordCount > 1 ? 's' : '') + "</div>");
        }
    };
    /**
     * 构建被复制的内容
     */
    Selector.prototype.setCopyContent = function () {
        jquery__WEBPACK_IMPORTED_MODULE_0___default()('.cp-content').remove();
        this.copyContainer = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<iframe class="cp-content" src="" contenteditable="true" designMode="on"></iframe>').appendTo('body');
        var copyWin = this.copyContainer[0].contentWindow;
        var copyDoc = this.copyContainer[0].contentDocument || copyWin.document;
        copyDoc.designMode = 'on';
        copyDoc.contentEditable = true;
        copyDoc.write('<html>' +
            '<head>' +
            '<style>' +
            'body{font-family: \'Helvetica Neue\',\'Hiragino Sans GB\',\'WenQuanYi Micro Hei\',\'Microsoft Yahei\',sans-serif;}' +
            '</style>' +
            '</head>' +
            '<body></body>' +
            '</html>');
        if (environment.isFirefox) {
            // 否则火狐下一直加载
            copyDoc.close();
        }
        var copyBody = copyDoc.body;
        jquery__WEBPACK_IMPORTED_MODULE_0___default()(copyBody).empty();
        var contentWrapper = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="export-wrapper"></div>').appendTo(copyBody);
        var html = convertToHtml(this.selectedNodes);
        contentWrapper.append(html);
        removeSelection();
        var range = copyDoc.createRange();
        range.selectNode(jquery__WEBPACK_IMPORTED_MODULE_0___default()(copyBody).children()[0]);
        copyWin.getSelection().addRange(range);
        copyWin.focus();
        jquery__WEBPACK_IMPORTED_MODULE_0___default()(copyDoc).off().on('keydown', function (e) {
            if (!(e[environment.metaKey] && (e.keyCode === 67 || e.keyCode === 88))) {
                // 除复制和剪切以后，都阻止默认
                e.preventDefault();
            }
            // 将快捷键透传给父窗口
            var eventData = {
                keyCode: e.keyCode,
                shiftKey: e.shiftKey,
                ctrlKey: e.ctrlKey,
                metaKey: e.metaKey,
                altKey: e.altKey
            };
            var event = jquery__WEBPACK_IMPORTED_MODULE_0___default.a.Event('keydown', eventData);
            jquery__WEBPACK_IMPORTED_MODULE_0___default()(document).trigger(event);
        }).on('cut', function () {
            var event = jquery__WEBPACK_IMPORTED_MODULE_0___default.a.Event('cut');
            jquery__WEBPACK_IMPORTED_MODULE_0___default()(document).trigger(event);
        });
    };
    /**
     * 选择变化后
     */
    Selector.prototype.selectChanged = function () {
        var me = this;
        this.createMenu();
        var wrapper = this.wrapper;
        var currentFocus = wrapper.find('.content:focus, .note:focus');
        if (currentFocus.length) {
            currentFocus.blur();
        }
        if (this.selected.length > 0) {
            this.setCopyContent();
            jquery__WEBPACK_IMPORTED_MODULE_0___default()(document).off('cut.selector').on('cut.selector', function () {
                if (me.state.readonly) {
                    return;
                }
                // 多选剪切，程序删除，延迟一下，否则立即删除，就复制不到内容了
                setTimeout(function () {
                    me.delete();
                }, 100);
            });
            jquery__WEBPACK_IMPORTED_MODULE_0___default()(document).off(me.operateEvent).on(me.operateEvent, function (e) {
                if (me.state.readonly) {
                    return;
                }
                var code = e.keyCode;
                if (code === 13) {
                    if (e[environment.metaKey] && !e.shiftKey) {
                        // cmd + enter 完成多条
                        e.preventDefault();
                        me.toggleFinish();
                        me.setCopyContent();
                    }
                }
                else if (code === 9) {
                    e.preventDefault();
                    if (e.shiftKey) {
                        // shift + Tab，回退
                        me.engine.outdentNodes(me.selectedNodes);
                    }
                    else {
                        // Tab, 缩进一级
                        me.engine.indentNodes(me.selectedNodes);
                    }
                    me.setCopyContent();
                }
                else if (code >= 49 && code <= 52 && e.altKey) {
                    // cmd + shift + 1 2 3 4，设置标题样式
                    e.preventDefault();
                    var heading = code - 48;
                    if (heading >= 4) {
                        heading = 0;
                    }
                    me.setNodeAttr('heading', heading);
                    me.setCopyContent();
                }
                else if (code >= 97 && code <= 100 && e.altKey) {
                    // cmd + shift + （小键盘）1 2 3 0，设置标题样式
                    e.preventDefault();
                    var heading = code - 96;
                    if (heading >= 4) {
                        heading = 0;
                    }
                    me.setNodeAttr('heading', heading);
                    me.setCopyContent();
                }
                else if (code === 8 || code === 46) {
                    // 删除
                    var target = jquery__WEBPACK_IMPORTED_MODULE_0___default()(e.target);
                    if (!target.is('input') && !target.is('textarea') && !target.is('.content, .note')) {
                        e.preventDefault();
                        me.delete();
                    }
                }
                // else if (code === 68 && e.altKey) {
                // 	e.preventDefault();
                // 	me.setNodeAttr('color', '#333333');
                // } else if (code === 82 && e.altKey) {
                // 	e.preventDefault();
                // 	me.setNodeAttr('color', '#dc2d1e');
                // } else if (code === 89 && e.altKey) {
                // 	e.preventDefault();
                // 	me.setNodeAttr('color', '#ffaf38');
                // } else if (code === 71 && e.altKey) {
                // 	e.preventDefault();
                // 	me.setNodeAttr('color', '#75c940');
                // } else if (code === 66 && e.altKey) {
                // 	e.preventDefault();
                // 	me.setNodeAttr('color', '#3da8f5');
                // } else if (code === 80 && e.altKey) {
                // 	e.preventDefault();
                // 	me.setNodeAttr('color', '#797ec9');
                // }
            });
        }
        me.selectHolder.setSelectIds(me.selected);
        me.selectHolder.setSelectNodes(me.selectedNodes);
    };
    Selector.prototype.getEditorId = function (editor) {
        if (editor.hasClass('note')) {
            return editor.parent().attr('id');
        }
        else {
            return editor.data('id');
        }
    };
    Selector.prototype.init = function () {
        var me = this;
        var wrapper = this.wrapper;
        var contentSelector = '.content'; // 应用于shift+上下多选
        var editorSelector = '.content, .note'; // 应用于全选和框选，和shift多选
        // 绑定键盘快捷键选择相关
        jquery__WEBPACK_IMPORTED_MODULE_0___default()(document).on('keydown.selector', function (downE) {
            var target = jquery__WEBPACK_IMPORTED_MODULE_0___default()(downE.target);
            if (target.is('input') || target.is('textarea')) {
                return;
            }
            var code = downE.keyCode;
            if (code === 65 && downE[environment.metaKey]) {
                // cmd + a 全选
                if (me.selected.length > 0) {
                    me.selectAll();
                    downE.preventDefault();
                    return;
                }
                if (target.is(editorSelector)) {
                    // 在主题输入框中，如果已经全部选择了文本，执行全选
                    var cursor = getCursorPosition();
                    if (cursor.start === 0 && cursor.end === target.text().length) {
                        // 文字全选了，执行全部条目的全选
                        me.selectAll();
                        downE.preventDefault();
                    }
                }
                else if (!target.is('input') && !target.is('textarea')) {
                    // 不是在输入框中，阻止全部选择文本
                    downE.preventDefault();
                }
            }
            else if (code === 38 || code === 40) {
                // 向上向下
                if (downE[environment.metaKey] && downE.shiftKey) {
                    // 应该是上下移动节点
                    if (me.selectedNodes.length > 0) {
                        if (code === 38) {
                            // 向上移动
                            var prevNodeId = me.engine.getPrevNodeId(me.selectedNodes[0].id);
                            if (prevNodeId && !me.model.isRootNode(prevNodeId)) {
                                me.engine.moveNodes(me.selectedNodes, prevNodeId, 'prev');
                            }
                        }
                        else {
                            // 向下移动
                            me.engine.moveNodesNext(me.selectedNodes);
                        }
                    }
                }
                else if (downE.shiftKey) {
                    // shift + 上下，进行内容选择
                    var direction = code - 39;
                    if (me.selected.length > 0) {
                        me.selectSiblings(direction);
                        return;
                    }
                    if (target.is(contentSelector)) {
                        // 在主题输入框中，如果已经全部选择了文本，执行全选
                        var cursor = getCursorPosition();
                        if ((cursor.start === 0 && direction < 0)
                            || (cursor.end === target.text().length && direction > 0)) {
                            // 再输入状态下，光标已经到了起点，开始选择
                            me.sourceId = me.getEditorId(target);
                            me.initNodes();
                            me.selectSiblings(direction);
                        }
                    }
                }
                else {
                    // 没有按任何的组合键
                    if (me.selected.length > 0) {
                        me.cancel();
                        if (code === 38) {
                            me.engine.toPrevNode(me.sourceId, false);
                        }
                        else {
                            me.engine.toNextNode(me.sourceId, false);
                        }
                    }
                }
            }
        });
        // 开始绑定鼠标操作事件
        wrapper.on('mousedown.selector', editorSelector, function (downE) {
            if (downE.button === 2) {
                // 按的右键，不处理
                return;
            }
            var mouseTarget = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            me.sourceBeginTarget = mouseTarget;
            var clickId = me.getEditorId(mouseTarget);
            if (downE.shiftKey) {
                // 按着shift多选
                if (me.selected.length === 0) {
                    // 当前没有选择，设置sourceId
                    // 获取之前focus的元素
                    var currentFocus = wrapper.find('.content:focus, .note:focus');
                    if (currentFocus.length === 0) {
                        // 既没有选择，也没有当前的焦点元素，不执行任何操作
                        return;
                    }
                    if (me.model.isRootNode(me.sourceId) || me.model.isRootNode(clickId)) {
                        return;
                    }
                    me.sourceId = me.getEditorId(currentFocus);
                }
                if (me.sourceId !== clickId) {
                    downE.stopPropagation();
                    downE.preventDefault();
                    me.findSelectByRange(clickId);
                }
                return;
            }
            me.sourceId = clickId;
            if (me.model.isRootNode(me.sourceId)) {
                return;
            }
            // 标示圆点不响应
            jquery__WEBPACK_IMPORTED_MODULE_0___default()('.bullet').addClass('selecting');
            var begin = false; // 是否开始
            me.selected = [];
            me.selectedNodes = [];
            me.viewport.paper.find('.mindnote-selector-menu').remove();
            jquery__WEBPACK_IMPORTED_MODULE_0___default()(document).on('mousemove.selector', function (moveE) {
                var currentY = moveE.pageY;
                if (!begin) {
                    // 未开始，判断是否开始
                    var sourcePosition = mouseTarget.offset();
                    var bottomBounding = sourcePosition.top + mouseTarget.outerHeight();
                    if (currentY < sourcePosition.top
                        || currentY > bottomBounding) {
                        // Y坐标已经超出了元素本身，开始选择多条
                        me.initNodes();
                        begin = true;
                    }
                }
                if (!begin) {
                    return;
                }
                // 开始查找选中了哪些几点
                me.findSelectByPosition(currentY);
            });
            jquery__WEBPACK_IMPORTED_MODULE_0___default()(document).on('mouseup.selector', function () {
                jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).off('mousemove.selector').off('mouseup.selector');
                jquery__WEBPACK_IMPORTED_MODULE_0___default()('.bullet.selecting').removeClass('selecting');
                if (me.selected.length > 0) {
                    me.selectChanged();
                }
            });
        });
    };
    Selector.prototype.cancel = function (srcElement) {
        var me = this;
        jquery__WEBPACK_IMPORTED_MODULE_0___default()('.node.selected').removeClass('selected');
        me.nodeArray = [];
        me.nodeIndex = {};
        // util.removeSelection();
        me.viewport.paper.find('.mindnote-selector-menu').remove();
        me.selected = [];
        me.selectedNodes = [];
        if (me.copyContainer) {
            var copyWin = me.copyContainer[0].contentWindow;
            var copyDoc = me.copyContainer[0].contentDocument || copyWin.document;
            if (environment.isIE) {
                me.copyContainer.remove();
                me.copyContainer = null;
                // 如果是IE，取消后，再次执行一次focus，否则无法编辑
                if (srcElement) {
                    if (jquery__WEBPACK_IMPORTED_MODULE_0___default()(srcElement).is('[contenteditable]')) {
                        moveCursorEnd(jquery__WEBPACK_IMPORTED_MODULE_0___default()(srcElement));
                    }
                }
            }
            else {
                var copyBody = copyDoc.body;
                jquery__WEBPACK_IMPORTED_MODULE_0___default()(copyBody).empty();
            }
        }
        jquery__WEBPACK_IMPORTED_MODULE_0___default()(document).off('cut.selector').off(me.operateEvent);
        me.selectHolder.clear();
    };
    Selector.prototype.getIds = function () {
        return this.selected;
    };
    Selector.prototype.getNodes = function () {
        return this.selectedNodes;
    };
    Selector.prototype.delete = function () {
        var topIds = [];
        jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(this.selectedNodes, function (index, node) {
            topIds.push(node.id);
        });
        this.engine.deleteNodeDirectly(topIds);
        this.cancel();
    };
    Selector.prototype.toggleFinish = function () {
        this.allFinished = !this.allFinished;
        this.engine.setFinishNode(this.selected, this.allFinished);
        var finishMenu = this.viewport.paper.find('.mindnote-selector-menu').find('.finish');
        if (this.allFinished) {
            finishMenu.find('.menu-text').text(t('mindnote.editor.activate'));
        }
        else {
            finishMenu.find('.menu-text').text(t('mindnote.editor.finish'));
        }
    };
    Selector.prototype.doExport = function () {
        // TODO 执行批量导出
        // const def = {nodes: this.selectedNodes};
        // this.exporter.export(def);
        // this.cancel();
    };
    /**
     * 设置选中状态
     * @param ids
     */
    Selector.prototype.setSelectedIds = function (ids) {
        this.selected = ids;
        this.setSelected();
        this.selectChanged();
    };
    /**
     * 设置节点属性
     * @param name
     * @param value
     */
    Selector.prototype.setNodeAttr = function (name, value) {
        this.engine.setNodeAttr(this.selected, name, value);
    };
    return Selector;
}());

/**
 * Created by apple on 17/3/5.
 * 图片编辑器模块
 */
var ImageEditor = /** @class */ (function () {
    function ImageEditor(editorId, eventSource) {
        this.editorId = editorId;
        this.eventSource = eventSource;
    }
    ImageEditor.prototype.init = function (options) {
        this.editorOptions = options;
    };
    /**
     * 笔记插入图片的方法
     * @param nodeId 父元素的nodeId
     */
    ImageEditor.prototype.insert = function (nodeId) {
        var imageId = newId(this.editorId);
        var data = {
            id: nodeId,
            imageId: imageId
        };
        this.eventSource.trigger(SourceEvent.ADD_IMAGE, data);
    };
    /**
     * 文本是否是图片名，类似xxxxx.png
     * @param text
     * @returns {*|boolean}
     * @deprecated 此处本用来检测无法上传图片时给予 Tip，但是目前暂无无法上传的 case
     */
    ImageEditor.prototype.textIsImage = function (text) {
        return text && text.length > 4 &&
            (text.indexOf('.png') === text.length - 4 ||
                text.indexOf('.jpg') === text.length - 4 ||
                text.indexOf('.gif') === text.length - 4 ||
                text.indexOf('.jpeg') === text.length - 5);
    };
    /**
     * 读取剪贴板里的图片
     * @param nodeId
     * @param clipboardData
     * @param clipboardText 剪贴板中的文本
     * @return boolean 是否剪贴板中包含图片，并且成功读取出了图片
     */
    ImageEditor.prototype.readClipboardImage = function (nodeId, clipboardData, clipboardText) {
        if (clipboardText) {
            // 优先解析一下是否是复制的幕布图片
            var clipboardJson = parse(clipboardText);
            if (clipboardJson && clipboardJson.type === 'image') {
                var imageData = clipboardJson.data;
                var extendData = __assign({ 'nodeId': nodeId }, imageData, { id: newId(this.editorId) });
                this.editorOptions.onInsertCopy(extendData);
                return true;
            }
        }
        if (clipboardData) {
            var items = clipboardData.items;
            for (var i = 0, l = items.length; i < l; i++) {
                var item = items[i];
                if (item.kind === 'file' && /image/.test(item.type)) {
                    var file = item.getAsFile();
                    if (file) {
                        return this.readImage(file, { 'nodeId': nodeId }, false);
                    }
                }
            }
        }
        return false;
    };
    /**
     * 读取图片
     * @param item
     * @param extendData {Object} 扩展数据
     * @property extendData.nodeId 添加到的笔记节点id，可空
     * @property extendData.x 图片x坐标，可空
     * @property extendData.y 图片y坐标，可空
     * @param tipError 是否提示无法读取，可空
     *
     * @returns {boolean}
     */
    ImageEditor.prototype.readImage = function (item, extendData, tipError) {
        var _this = this;
        if (typeof FileReader === 'undefined' && tipError !== false) {
            /* TODO 浏览器不支持 Tip */
            return false;
        }
        var me = this;
        var reader = new FileReader();
        reader.onload = function (e) {
            var base64Url = e.target.result;
            var data = {
                id: extendData.nodeId,
                imageId: newId(me.editorId),
                base64Data: base64Url
            };
            _this.eventSource.trigger(SourceEvent.ADD_IMAGE, data);
        };
        reader.readAsDataURL(item);
        return true;
    };
    /**
     *	信息提示框
     * @param info 传入提示信息
     * @param keep 是否保持提示
     */
    ImageEditor.prototype.uploadTip = function (info, keep) {
        jquery__WEBPACK_IMPORTED_MODULE_0___default()('.img-upload-tip').remove();
        var uploadTip = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="img-upload-tip">' + info + '</div>').appendTo('body');
        if (!keep) {
            setTimeout(function () {
                uploadTip.fadeOut(200, function () {
                    uploadTip.remove();
                });
            }, 2500);
        }
    };
    /**
     * 关闭上传提示
     */
    ImageEditor.prototype.closeUploadTip = function () {
        jquery__WEBPACK_IMPORTED_MODULE_0___default()('.img-upload-tip').remove();
    };
    /**
     * 初始化图片拖入
     */
    ImageEditor.prototype.initImageDrop = function () {
        var containerCls = 'content';
        var me = this;
        this.initDropImage({
            onDragOver: function (e) {
                if (!jquery__WEBPACK_IMPORTED_MODULE_0___default()(e.target).hasClass(containerCls)) {
                    e.preventDefault();
                }
                me.uploadTip(t('mindnote.editor.drag_img'), true);
            },
            onDragLeave: function () {
                me.closeUploadTip();
            },
            onDrop: function (e) {
                me.closeUploadTip();
                return jquery__WEBPACK_IMPORTED_MODULE_0___default()(e.target).hasClass(containerCls);
            }
        });
    };
    /**
     * 初始化图片的拖动
     * @param options {Object}
     * @property options.onDragOver {function}
     * @property options.onDragLeave {function}
     * @property options.onDrop {function}
     */
    ImageEditor.prototype.initDropImage = function (options) {
        var body = jquery__WEBPACK_IMPORTED_MODULE_0___default()('body');
        var me = this;
        body.on('dragstart.mindnote', function (e) {
            // 阻止页面内的拖动
            e.preventDefault();
            return false;
        });
        body.on('dragover.mindnote', function (e) {
            options.onDragOver(e);
        });
        body.on('drop.mindnote', function (e) {
            e.preventDefault();
            if (options.onDrop(e)) {
                // 正确拖放到了一个节点主题上
                try {
                    if (e.originalEvent.dataTransfer.files.length === 0) {
                        return;
                    }
                    var dropImg = e.originalEvent.dataTransfer.files[0];
                    var error = void 0;
                    var accept = [
                        'image/jpg', 'image/jpeg', 'image/png', 'image/x-png', 'image/gif'
                    ];
                    var index = jquery__WEBPACK_IMPORTED_MODULE_0___default.a.inArray(dropImg.type, accept);
                    if (index === -1) {
                        error = t('mindnote.editor.img_valid_type');
                    }
                    else if (dropImg.size > 1024 * 1024 * 3) {
                        // 校验大小
                        error = t('mindnote.editor.img_size_tip');
                    }
                    if (error) {
                        me.uploadTip(error);
                    }
                    else {
                        var nodeId = jquery__WEBPACK_IMPORTED_MODULE_0___default()(e.target).data('id');
                        var data = {
                            nodeId: nodeId,
                            x: e.pageX,
                            y: e.pageY
                        };
                        me.readImage(dropImg, data);
                    }
                }
                catch (ex) {
                    me.uploadTip(t('mindnote.editor.img_process_failed'));
                }
            }
        });
        body.on('dragleave.mindnote', function (e) {
            options.onDragLeave(e);
        });
    };
    return ImageEditor;
}());

var config = {
    freeTopicCount: 200,
    saveDelayMills: 1500,
    overQueueSaveDelayMills: 500,
    features: {
        exportPng: false,
    },
    /**
     * 获取查看高级版的链接地址
     * @returns {string}
     */
    getAboutProLink: function () {
        return '/about/pro';
    },
    /**
     * 初始化立即升级的按钮
     */
    initUpgradeBtn: function (btn) {
        btn.attr({
            href: '/upgrade',
            target: '_blank',
        });
    },
    /**
     * 进入思维导图事件
     */
    onOpenMind: null,
    /**
     * 关闭思维导图事件
     */
    onCloseMind: null,
    /**
     * 是否需要延迟重新定位思维导图
     * 桌面版需要，因为mac下缩放窗口会有一个延迟
     */
    delayRelocateMindMap: false,
    /**
     * 打开文档内的链接
     * @param link
     */
    openLink: function (link) {
        var args = [];
        for (var _i = 1; _i < arguments.length; _i++) {
            args[_i - 1] = arguments[_i];
        }
        var url = link.attr('href');
        var win = window.open(url, '_blank');
        win.focus();
    },
    /**
     * 当发生文档变化事件
     * @param events
     */
    onPopChangeEvent: function (e) {
        // dispatcher.trigger(IOEvent.CHANGE_CLIENT, e);
    },
    /**
     * 发生钻取事件
     * @param e
     */
    onDrillEvent: function (e) {
        // dispatcher.trigger(IOEvent.DRILL, e);
    },
    /**
     * 根据图片的资源key获取到完整路径
     * @param uri
     */
    getImageURL: function (uri) {
        return uri;
    },
};

var TextEditor = /** @class */ (function () {
    function TextEditor(imageEditor, viewport) {
        this.preventBlur = false;
        // 每一次输入开始时的光标位置
        this.startCursorOffset = null;
        // 每一次开始输入时的内容
        this.startContent = '';
        this.isInternetExplorer = environment.isIE && !environment.isEdge;
        this.imageEditor = imageEditor;
        this.viewport = viewport;
    }
    TextEditor.prototype.init = function (opt) {
        this.options = opt;
        this.initTextEdit();
    };
    TextEditor.prototype.createContentText = function (editor) {
        return new ContentText(editor);
    };
    /**
     * 重新格式化一个输入框中的内容
     * @param editor
     * @returns {*}
     */
    TextEditor.prototype.formatText = function (editor) {
        var cText = new ContentText(editor);
        var html = cText.getContentHtml();
        editor.html(html);
        return html;
    };
    /**
     * 以一个区间分隔内容
     * @param editor 编辑器
     * @param position 区间的索引位置
     */
    TextEditor.prototype.getSplitHtml = function (editor, position) {
        var cText = new ContentText(editor);
        var splitResult = cText.split(position.start, position.end);
        return [
            splitResult[0].getContentHtml(),
            splitResult[1].getContentHtml(),
        ];
    };
    /**
     * 在外围某些操作后，要重置inputAction事件，比如撤销
     * 否则后边的继续输入，可能inputAction已经在队列中不存在
     * @type {resetInputAction}
     */
    TextEditor.prototype.resetInputAction = function () {
        this.startCursorOffset = null;
        this.startContent = '';
    };
    /**
     * 暴露给外部接口调用，手机app中的底部菜单
     * @type {executeFormatAction}
     */
    /**
     * 设置文字的样式
     * @param editor
     * @param action
     */
    TextEditor.prototype.executeFormatAction = function (editor, action) {
        var position = getCursorPosition();
        // 重置输入操作，创建新的action
        this.resetInputAction();
        // 保存光标位置，与开始时的内容
        this.startCursorOffset = position;
        this.startContent = editor.html();
        var contentText = new ContentText(editor);
        var setPosition = position;
        if (position.start === position.end) {
            // 不是多选文字的情况下，全部设置
            setPosition = { start: 0, end: contentText.getPlainText().length };
        }
        contentText.toggleTextFormatFlag(action, setPosition);
        editor.html(contentText.getContentHtml());
        setCursorPosition(editor, position);
        this.textChanged(editor, true);
    };
    TextEditor.prototype.startListenTextChange = function (editor) {
        var _this = this;
        var startContent = editor.html();
        this.stopListenTextChange();
        this.textChangeListener = setInterval(function () {
            var newContent = editor.html();
            if (newContent !== startContent) {
                _this.updateContentHtmlAfterUserEdit(editor);
                startContent = newContent;
            }
        }, 5);
    };
    TextEditor.prototype.stopListenTextChange = function () {
        var args = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            args[_i] = arguments[_i];
        }
        clearInterval(this.textChangeListener);
    };
    /**
     * 初始化文字编辑
     */
    TextEditor.prototype.initTextEdit = function () {
        var paper = this.viewport.paper;
        var editorSelector = '.content, .note';
        var linkClickEvent = environment.isMobile ? 'touchend' : 'click';
        var me = this;
        paper.on('input.edit', editorSelector, function (e) {
            if (!e.originalEvent.isComposing) {
                // 在输入法输入状态下，不执行更新
                me.updateContentHtmlAfterUserEdit(jquery__WEBPACK_IMPORTED_MODULE_0___default()(this));
            }
        }).on('compositionstart.edit', editorSelector, function () {
            // 在IE下，因为不支持input事件，在开始输入法的片段输入时，停止监听
            if (me.isInternetExplorer) {
                me.stopListenTextChange(jquery__WEBPACK_IMPORTED_MODULE_0___default()(this));
            }
        }).on('compositionend.edit', editorSelector, function () {
            me.updateContentHtmlAfterUserEdit(jquery__WEBPACK_IMPORTED_MODULE_0___default()(this));
            // 在IE下，因为不支持input事件，在开始输入法的片段完成时，重启监听
            if (me.isInternetExplorer) {
                me.startListenTextChange(jquery__WEBPACK_IMPORTED_MODULE_0___default()(this));
            }
        }).on('focus.edit', editorSelector, function () {
            if (me.isInternetExplorer) {
                me.startListenTextChange(jquery__WEBPACK_IMPORTED_MODULE_0___default()(this));
            }
            var nodeId = me.getEditorId(jquery__WEBPACK_IMPORTED_MODULE_0___default()(this));
            var container = getNodeContainer(nodeId);
            // 让子节点的线条高亮显示
            var clsName = 'focus-active';
            jquery__WEBPACK_IMPORTED_MODULE_0___default()('.' + clsName).removeClass(clsName);
            container.addClass(clsName);
            if (nodeId === me.focusNodeId) {
                // 如果是相同的，不进行处理，因为比如加粗等操作，会重新设置光标，会触发focus
                return;
            }
            me.resetInputAction();
            me.focusNodeId = nodeId;
        }).on('blur.edit', editorSelector, function () {
            if (me.isInternetExplorer) {
                me.stopListenTextChange();
            }
            if (me.preventBlur) {
                return;
            }
            var editor = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            var nodeId = me.getEditorId(editor);
            getNodeContainer(nodeId).removeClass('focus-active');
            if (editor.hasClass('note') && jquery__WEBPACK_IMPORTED_MODULE_0___default.a.trim(editor.text()) === '') {
                editor.remove();
            }
            me.resetInputAction();
            me.focusNodeId = null;
        }).on('keydown.edit', editorSelector, function (e) {
            var code = e.keyCode;
            var metaKey = environment.metaKey;
            if ((code === 90 || code === 89) && e[metaKey]) {
                // 按的是撤销、恢复相关的，不执行textChanged
                e.preventDefault();
                return;
            }
            var editor = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            if (me.startCursorOffset == null) {
                // 设置每一次输入开始时的状态
                me.startCursorOffset = getCursorPosition();
                me.startContent = editor.html();
            }
            if (code === 13
                && !e.altKey
                && !e.shiftKey
                && !e[metaKey]
                && editor.hasClass('note')) {
                // 在备注回车时，使用\n换行
                e.preventDefault();
                var selection = window.getSelection();
                var range = selection.getRangeAt(0);
                // var textDom = document.createTextNode('\n\u00a0');
                var textDom = document.createTextNode('\n\u200B');
                range.deleteContents();
                range.insertNode(textDom);
                // 创建新的range，使得TextRange可以移动到正确的位置
                var newRange = document.createRange();
                newRange.setStart(textDom, 1);
                newRange.setEnd(textDom, 2);
                newRange.collapse(true);
                selection.removeAllRanges();
                selection.addRange(newRange);
                // 更新一下内容
                me.updateContentHtmlAfterUserEdit(editor);
            }
            // 快捷键
            if (e[metaKey]) {
                if (code === 66) {
                    // cmd + B
                    e.preventDefault();
                    me.executeFormatAction(editor, 'bold');
                }
                else if (code === 73) {
                    // cmd + I
                    e.preventDefault();
                    me.executeFormatAction(editor, 'italic');
                }
                else if (code === 85) {
                    // cmd + U
                    e.preventDefault();
                    me.executeFormatAction(editor, 'underline');
                }
            }
        }).on('paste.edit', editorSelector, function (e) {
            me.updateContentHtmlAfterPaste(jquery__WEBPACK_IMPORTED_MODULE_0___default()(this), e);
        }).on(linkClickEvent + '.open-link', '.content-link', function (e) {
            var target = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            if (config.openLink) {
                config.openLink(target, e);
            }
        });
        if (environment.isMobile) {
            paper.on('click.open-link', '.content-link', function (e) {
                e.preventDefault();
            });
        }
    };
    /**
     * 获取编辑器对应的节点id
     * @param editor
     * @returns {*}
     */
    TextEditor.prototype.getEditorId = function (editor) {
        if (editor.hasClass('note')) {
            return editor.parent().attr('id');
        }
        else {
            return editor.data('id');
        }
    };
    /**
     * 内容发生变化时，进行保存
     * @param editor 发生的编辑器元素
     * @param newAction 是否是新操作，比如粘贴，B I U等
     */
    TextEditor.prototype.textChanged = function (editor, newAction) {
        var text = editor.html();
        var isNote = editor.hasClass('note');
        var nodeId = this.getEditorId(editor);
        if (isNote) {
            if (jquery__WEBPACK_IMPORTED_MODULE_0___default.a.trim(editor.text()) === '') {
                // 没有内容了，对描述的text进行清空
                text = '';
            }
        }
        var editType = (isNote ? InputActionTypes.NOTE : InputActionTypes.TEXT);
        // 发生了编辑，添加撤销input事件
        var cursorPos = getCursorPosition();
        if (this.options.onPopAction) {
            this.options.onPopAction({
                name: Actions.INPUT,
                id: nodeId,
                type: editType,
                // 外面会填充这个 path
                path: [],
                prevContent: this.startContent,
                prevPos: this.startCursorOffset,
                nextContent: text,
                nextPos: cursorPos,
            });
        }
        this.startContent = text;
        this.startCursorOffset = cursorPos;
        if (this.options.onChange) {
            this.options.onChange(nodeId, text, editType);
        }
        if (newAction) {
            // 新消息，不执行setTimeout继续收集，并且重置
            this.resetInputAction();
            return;
        }
    };
    /**
     * 用户输入后自动格式化
     * @param editor
     */
    TextEditor.prototype.updateContentHtmlAfterUserEdit = function (editor) {
        // 用户输入的原内容
        var inputHtml = editor.html();
        // 经过计算处理后的html内容
        var contentText = new ContentText(editor);
        var formatContent = contentText.getContentHtml();
        var isChanged = true;
        if (this.isInternetExplorer || environment.isFirefox) {
            // 在IE和Firefox下不能直接比较html内容，要放到同样的div中去判断
            var temp = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div></div>');
            temp.html(inputHtml);
            // 在Firefox下，正常输入，可能会多出br
            temp.find('br').remove();
            var a = temp.html();
            temp.html(formatContent);
            isChanged = (a !== temp.html());
        }
        else {
            isChanged = (inputHtml !== formatContent);
        }
        if (isChanged) {
            var position = getCursorPosition();
            editor.html(formatContent);
            setCursorPosition(editor, position);
        }
        this.textChanged(editor);
    };
    /**
     * 用户粘贴后处理
     * @param sourceInput 输入源
     * @param e 粘贴事件
     */
    TextEditor.prototype.updateContentHtmlAfterPaste = function (sourceInput, e) {
        // 先获取一下剪贴板里的内容
        var text = null;
        var clipboardData = (e.originalEvent || e).clipboardData;
        var targetId = this.getEditorId(sourceInput);
        var win = window;
        if (win.clipboardData && win.clipboardData.getData) {
            // IE
            text = win.clipboardData.getData('text');
        }
        else {
            text = clipboardData.getData('text/plain');
        }
        if (!text || this.imageEditor.textIsImage(text) || isMubuClipboardText(text)) {
            // 当剪切板无内容，或者内容以图片后缀结束时，检查是否有图片
            // 因为office系列，会把内容文字和内容图片，同时存于剪贴板中
            var isPasteImage = this.imageEditor.readClipboardImage(targetId, clipboardData, text);
            if (isPasteImage) {
                e.preventDefault();
                return;
            }
        }
        if (!text) {
            // 剪贴板没有内容
            return;
        }
        // 因为粘贴时会触发blur，可能会删除note的输入框，所以阻止一下
        this.preventBlur = true;
        // 重置输入操作，创建新的action
        this.resetInputAction();
        // 保存光标位置，与开始时的内容
        this.startCursorOffset = getCursorPosition();
        this.startContent = sourceInput.html();
        var isContentEditor = sourceInput.hasClass('content');
        var pasteHolder = jquery__WEBPACK_IMPORTED_MODULE_0___default()('#paste-holder');
        if (pasteHolder.length === 0) {
            pasteHolder = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div id="paste-holder" contenteditable></div>').appendTo(this.viewport.controlHolder);
        }
        pasteHolder.empty().show();
        // 为防止在手机中，由于切换光标位置导致的页面晃动，将pasteHolder放到输入框的位置
        pasteHolder.css({
            top: sourceInput.offset().top,
            left: sourceInput.offset().left,
        });
        // 重新设置选区到响应粘贴的容器中
        var newRange = document.createRange();
        newRange.setStart(pasteHolder[0], 0);
        var selection = window.getSelection();
        selection.removeAllRanges();
        selection.addRange(newRange);
        function getPastedContent() {
            var _this = this;
            if (pasteHolder.text() === '') {
                // 如果当前内容是空，继续20毫秒后刷新，因为粘贴后会有一个延迟，不确定什么时候会完成
                setTimeout(function () {
                    getPastedContent.call(_this);
                }, 20);
                return;
            }
            pasteHolder.hide();
            // 删除无用的或危险标签
            pasteHolder.find('noscript, script, style, link, img').remove();
            var contentHtml = pasteHolder.html();
            // 内容的纯文本是直接取剪切板里的内容，会自动包括\n换行符
            // 已经粘贴完成，开始组织内容
            // 解析html内容
            if (isContentEditor) {
                // 是在主题中粘贴，可以粘贴出多个节点
                var convertedNodes = htmlToNode(contentHtml);
                var pasteMultiNodes = false;
                if (convertedNodes.size > 1) {
                    pasteMultiNodes = true;
                }
                else if (convertedNodes.size === 1) {
                    var converted = convertedNodes.nodes[0];
                    if (converted.images || converted.note) {
                        // 当节点有图片或者描述，也当做节点进行粘贴
                        pasteMultiNodes = true;
                    }
                }
                if (pasteMultiNodes) {
                    // 多个节点才有意思，单个节点，就是普通文本粘贴的形式
                    if (this.options.onPasteMultiNodes) {
                        this.options.onPasteMultiNodes(targetId, convertedNodes.nodes);
                    }
                    return;
                }
            }
            var cText = new ContentText(sourceInput);
            var splitResult = cText.split(this.startCursorOffset.start, this.startCursorOffset.end);
            if (isContentEditor) {
                pasteHolder.html(jquery__WEBPACK_IMPORTED_MODULE_0___default.a.trim(pasteHolder.html()).replace(/\n/g, ' '));
            }
            else {
                pasteHolder.find('div,p,li').append('\n');
                var lineBreak = pasteHolder.find('br');
                lineBreak.after('\n');
                lineBreak.remove();
            }
            var pasteContentText = new ContentText(pasteHolder);
            // 合并三个ContentText对象
            var merged = this.mergeContentText(sourceInput, [splitResult[0], pasteContentText, splitResult[1]]);
            var newContent = merged.getContentHtml();
            if (!isContentEditor) {
                // 可能会存在多个连续的换行符，替换成一个
                var reg = new RegExp('\n\+', 'g');
                newContent = newContent.replace(reg, '\n');
            }
            sourceInput.html(newContent);
            // 粘贴后，重新管理标签
            var newCursor = {
                start: this.startCursorOffset.start + pasteContentText.getPlainText().length,
            };
            setCursorPosition(sourceInput, newCursor);
            this.textChanged(sourceInput, true);
        }
        this.preventBlur = false;
        getPastedContent.call(this);
    };
    /**
     * 合并多个ContentText对象
     * @param editor 最终合并的editor对象
     * @param textArray
     */
    TextEditor.prototype.mergeContentText = function (editor, textArray) {
        var plainText = '';
        var formatFlags = [];
        for (var i = 0, len = textArray.length; i < len; i++) {
            var cText = textArray[i];
            plainText += cText.plainText;
            formatFlags = formatFlags.concat(cText.formatFlags);
        }
        return new ContentText(editor, plainText, formatFlags);
    };
    return TextEditor;
}());

function never(x) {
    console.error('Unexcepted action: ', x);
}
var MessageRunner = /** @class */ (function () {
    function MessageRunner(engine, model, selector, eventSource) {
        this.engine = engine;
        this.model = model;
        this.selector = selector;
        this.eventSource = eventSource;
    }
    /**
     * 调整结构
     * @param changed 发生变化的结构定义
     * @param type 类型 undo || redo
     */
    MessageRunner.prototype.changeStructures = function (changed, type) {
        var changedContainer = [];
        var rootNode = this.engine.getRootNode();
        var rootNodeChanged = false;
        var isRootNode = function (node) {
            return (rootNode && rootNode.id === node.id);
        };
        var me = this;
        // 先全部删除，否则如果存在多个同级的元素时，会互相受影响
        jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(changed, function (index, changedNode) {
            var nodeId = changedNode.changed.node.id;
            var nodeContainer = getNodeContainer(nodeId);
            // !操作model，先从之前的父级数组中删除
            var node = me.model.getById(nodeId);
            var isRoot = isRootNode(node);
            if (node && nodeContainer.length > 0 && !isRoot) {
                // 如果不是rootNode，才进行删除
                nodeContainer.remove();
                changedContainer.push(nodeContainer);
            }
            else {
                changedContainer.push(null);
            }
            if (node) {
                // 有可能node已经不存在，比如协同消息未到达时，本地进行了删除
                var currentParentArr = me.model.getParentArray(nodeId);
                me.model.removeNode(currentParentArr, nodeId);
                if (isRootNode(node)) {
                    // 如果当前进入的root节点被移动了，那要刷新导航目录
                    rootNodeChanged = true;
                }
            }
        });
        // 再次重新开始插入
        jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(changed, function (index, changedNode) {
            var to;
            if (type === 'undo') {
                to = changedNode.original;
            }
            else {
                to = changedNode.changed;
            }
            var node = me.model.getById(to.node.id);
            if (!node) {
                // 如果当前节点已经不存在，有可能在本地进行了删除
                // continue
                return true;
            }
            var target = me.engine.getWrapper();
            var relocateModel = true;
            if (to.parentId) {
                var parentNode = me.model.getById(to.parentId);
                if (!parentNode) {
                    relocateModel = false;
                    target = null;
                }
                else {
                    var parentDom = getNodeContainer(to.parentId);
                    if (parentDom.length) {
                        target = parentDom.children('.children');
                        if (target.length === 0) {
                            target = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="children"></div>').appendTo(parentDom);
                        }
                    }
                    else {
                        // 父元素DOM在页面中不存在，有两种情况，1. 父节点在本地被删除了。2. 当前处于drill状态，进入了其他节点
                        target = null;
                    }
                }
            }
            else if (rootNode) {
                // 当移动到了根节点，但是当前已经进入了某个节点，不会进行渲染
                target = null;
            }
            if (target != null) {
                var nodeContainer = changedContainer[index];
                if (nodeContainer == null || nodeContainer.length === 0) {
                    // 节点不用存在，有可能是当前进入了其他节点，而此节点并没有展示
                    // 此时需要创建一个新的节点DOM，并添加进去
                    nodeContainer = me.engine.getPainter().createNodeDom(node, false);
                }
                if (to.index === 0) {
                    // 第一个
                    target.prepend(nodeContainer);
                }
                else {
                    target.children('.node:eq(' + (to.index - 1) + ')').after(nodeContainer);
                }
            }
            if (relocateModel) {
                // 调整数据结构
                me.model.relocateNode(to.parentId, to.index, to.node.id);
            }
        });
        me.model.buildMapping();
        if (rootNodeChanged) {
            me.engine.refreshDrillDir();
        }
    };
    /**
     * undo
     * @deprecated 不会调用，undo 抽到外面了，留着如果新的 undo 出了 bug 看看原来的逻辑
     */
    MessageRunner.prototype.undo = function () {
        var message = [];
        if (message == null) {
            return;
        }
        var me = this;
        jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(message, function (index, action) {
            if (action.name === 'input') {
                // 撤销输入指令
                var type = action.type;
                var node = me.model.getById(action.id);
                if (!node) {
                    // 已经找不到node，continue
                    return true;
                }
                var content = void 0;
                if (type === 'note') {
                    content = getNodeContainer(action.id).children('.note');
                    if (action.startContent === '') {
                        content.remove();
                    }
                    else if (content.length === 0) {
                        // 创建note
                        content = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="note" contenteditable spellcheck="false"></div>');
                        getContentById(action.id).parent().after(content);
                    }
                    node.note = action.startContent;
                }
                else {
                    content = getContentById(action.id);
                    node.text = action.startContent;
                }
                content.html(action.startContent);
                setCursorPosition(content, action.startPos);
                me.model.update(node);
            }
            else if (action.name === 'create') {
                // 撤销创建指令
                var deleteNodeIds_1 = [];
                jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(action.created, function (i, created) {
                    var nodeId = created.node.id;
                    getNodeContainer(nodeId).remove();
                    deleteNodeIds_1.push(nodeId);
                });
                // 一次性删除model
                me.model.deleteNodes(deleteNodeIds_1);
                if (action.cursor) {
                    var cursorContent = getContentById(action.cursor.id);
                    setCursorPosition(cursorContent, action.cursor.position);
                }
            }
            else if (action.name === 'delete') {
                // 撤销删除指令
                me.model.addNodes(action.deleted);
                // 绘制节点
                var lastNode_1;
                jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(action.deleted, function (i, struct) {
                    me.engine.getPainter().insertNode(struct.parentId, struct.index, struct.node, me.model.getRootNode());
                    me.engine.getPainter().renderChildren(struct.node.id);
                    lastNode_1 = struct.node;
                });
                var lastContent = getContentById(lastNode_1.id);
                if (lastContent.is(':visible')) {
                    moveCursorEnd(lastContent);
                }
            }
            else if (action.name === 'update') {
                // 重新刷新绘制节点
                if (action.updated.length > 0) {
                    var lastNode_2;
                    jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(action.updated, function (i, updateNode) {
                        me.model.update(updateNode.original);
                        // 重新获取node，进行刷新
                        var newNode = me.model.getById(updateNode.original.id);
                        me.engine.getPainter().refreshNode(newNode);
                        lastNode_2 = updateNode.original;
                    });
                    focus(getContentById(lastNode_2.id));
                }
            }
            else if (action.name === 'structureChanged') {
                // 重新调整结构
                me.changeStructures(action.changed, 'undo');
                if (action.cursor) {
                    var cursorContent = getContentById(action.cursor.id);
                    setCursorPosition(cursorContent, action.cursor.position);
                }
                else {
                    var lastNode = action.changed[action.changed.length - 1].changed.node;
                    focus(getContentById(lastNode.id));
                }
            }
            else if (action.name === 'drill') {
                // 重新调整结构
                me.engine.drillNode(action.from, true);
            }
            try {
                var selected = action.selected;
                if (selected && selected.length) {
                    me.selector.setSelectedIds(selected);
                }
                else {
                    me.selector.cancel();
                }
            }
            catch (e) {
                // 有时可能处理出错，如：恢复多选后删除的操作
            }
        });
        // 触发事件
        me.eventSource.trigger('undid', message);
    };
    /**
     * redo
     * @deprecated 不会调用，redo 抽到外面了，留着如果新的 redo 出了 bug 看看原来的逻辑
     */
    MessageRunner.prototype.redo = function () {
        var message = [];
        if (message == null) {
            return;
        }
        var me = this;
        jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(message, function (index, action) {
            if (action.name === 'input') {
                // 恢复输入指令
                var type = action.type;
                var node = me.model.getById(action.id);
                if (!node) {
                    // 已经找不到node，continue
                    return true;
                }
                var content = void 0;
                if (type === 'note') {
                    content = getNodeContainer(action.id).children('.note');
                    if (action.endContent === '') {
                        content.remove();
                    }
                    else if (content.length === 0) {
                        // 创建note
                        content = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="note" contenteditable spellcheck="false"></div>');
                        getContentById(action.id).parent().after(content);
                    }
                    node.note = action.endContent;
                }
                else {
                    content = getContentById(action.id);
                    node.text = action.endContent;
                }
                content.html(action.endContent);
                setCursorPosition(content, action.endPos);
                me.model.update(node);
            }
            else if (action.name === 'create') {
                // 恢复创建指令
                me.model.addNodes(action.created);
                // 绘制节点
                var lastNode_3;
                jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(action.created, function (i, struct) {
                    me.engine.getPainter().insertNode(struct.parentId, struct.index, struct.node, me.model.getRootNode());
                    me.engine.getPainter().renderChildren(struct.node.id);
                    lastNode_3 = struct.node;
                });
                var lastContent = getContentById(lastNode_3.id);
                if (lastContent.is(':visible')) {
                    moveCursorEnd(lastContent);
                }
            }
            else if (action.name === 'delete') {
                // 恢复删除指令
                var deleteNodeIds_2 = [];
                jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(action.deleted, function (i, created) {
                    var nodeId = created.node.id;
                    getNodeContainer(nodeId).remove();
                    deleteNodeIds_2.push(nodeId);
                });
                // 一次性删除model
                me.model.deleteNodes(deleteNodeIds_2);
            }
            else if (action.name === 'update') {
                // 重新刷新绘制节点
                if (action.updated.length > 0) {
                    var lastNode_4;
                    jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(action.updated, function (i, updateNode) {
                        me.model.update(updateNode.updated);
                        // 重新获取node，进行刷新
                        var newNode = me.model.getById(updateNode.updated.id);
                        me.engine.getPainter().refreshNode(newNode);
                        lastNode_4 = updateNode.updated;
                    });
                    focus(getContentById(lastNode_4.id));
                }
            }
            else if (action.name === 'structureChanged') {
                // 重新调整结构
                me.changeStructures(action.changed, 'redo');
                if (action.cursor) {
                    var cursorContent = getContentById(action.cursor.id);
                    setCursorPosition(cursorContent, action.cursor.position);
                }
                else {
                    var lastNode = action.changed[action.changed.length - 1].changed.node;
                    focus(getContentById(lastNode.id));
                }
            }
            else if (action.name === 'drill') {
                // 重新调整结构
                me.engine.drillNode(action.to, true);
            }
            try {
                var selected = action.selected;
                if (selected && selected.length) {
                    me.selector.setSelectedIds(selected);
                }
                else {
                    me.selector.cancel();
                }
            }
            catch (e) {
                // 有时可能处理出错，如：恢复多选后删除的操作
            }
        });
        // 触发事件
        me.eventSource.trigger('redid', message);
    };
    MessageRunner.prototype.executeMessage = function (actions, type) {
        var me = this;
        var isRedoOrUndo = type === ExecuteType.REDO || type === ExecuteType.UNDO;
        Object(lodash_es__WEBPACK_IMPORTED_MODULE_5__["default"])(actions, function (action) {
            switch (action.name) {
                case Actions.CREATE:
                    me.model.addNodes(action.created);
                    Object(lodash_es__WEBPACK_IMPORTED_MODULE_5__["default"])(action.created, function (nodeSet) {
                        me.engine.getPainter().insertNode(nodeSet.parentId, nodeSet.index, nodeSet.node, me.model.getRootNode());
                        me.engine.getPainter().renderChildren(nodeSet.node.id);
                    });
                    // redo/undo 创建一个节点时，光标移动到节点末尾（创建多个节点时，是多选节点，不用在这处理）
                    if (action.created.length === 1 && isRedoOrUndo) {
                        var content = getContentById(action.created[action.created.length - 1].node.id);
                        if (content.is(':visible')) {
                            moveCursorEnd(content);
                        }
                    }
                    break;
                case Actions.UPDATE:
                    Object(lodash_es__WEBPACK_IMPORTED_MODULE_5__["default"])(action.updated, function (updateInfo) {
                        var updated = updateInfo.updated;
                        var oldNode = me.model.getById(updated.id);
                        // 有可能node已经在本地被删除
                        if (oldNode) {
                            var newNode = __assign({}, oldNode, updated);
                            me.model.update(newNode);
                            me.engine.getPainter().refreshNode(newNode);
                        }
                    });
                    break;
                case Actions.DELETE:
                    var rootNode_1 = me.engine.getRootNode();
                    // 上一个节点
                    var beforeNode = action.deleted.length
                        ? me.model.getPrevNode(action.deleted[0].node.id)
                        : '';
                    var rootNodeDeleted_1 = false;
                    Object(lodash_es__WEBPACK_IMPORTED_MODULE_5__["default"])(action.deleted, function (deleted) {
                        var node = deleted.node;
                        if (rootNode_1 && me.model.contains(node.id, rootNode_1.id)) {
                            // 如果删除的节点包含当前的根节点，那要回到首页
                            rootNodeDeleted_1 = true;
                        }
                        me.model.deleteNode(node.id);
                        me.engine.getPainter().removeNode(node);
                    });
                    if (rootNodeDeleted_1) {
                        me.engine.drillNode(null, true);
                        me.eventSource.trigger(SourceEvent.DRILL_REMOVED);
                    }
                    // 发生了删除，重置选区
                    me.resetSelection();
                    // redo/undo 中删除，光标移动到上一个节点最后
                    if (beforeNode && (type === ExecuteType.REDO || type === ExecuteType.UNDO)) {
                        var content = getContentById(beforeNode.id);
                        if (content.is(':visible')) {
                            moveCursorEnd(content);
                        }
                    }
                    break;
                case Actions.STRUCTURE_CHANGE:
                    me.changeStructures(action.changed);
                    break;
                case Actions.SETTING_CHANGE:
                    var setting = action.changed;
                    for (var key in setting) {
                        if (setting.hasOwnProperty(key)) {
                            var value = setting[key];
                            var define = me.model.getDefine();
                            define[key] = value;
                        }
                    }
                    break;
                // 暂时不需要处理 input action，update 处理了就行
                case Actions.INPUT:
                    break;
                default:
                    never(action);
                    break;
            }
        });
        // 抛出事件
        me.eventSource.trigger('messageExecuted');
    };
    /**
     * 重置selector的选区
     */
    MessageRunner.prototype.resetSelection = function () {
        var _this = this;
        // 重置选区
        var currentSelection = this.selector.getIds();
        if (currentSelection && currentSelection.length > 0) {
            var newSelection_1 = Object(lodash_es__WEBPACK_IMPORTED_MODULE_2__["default"])(currentSelection);
            Object(lodash_es__WEBPACK_IMPORTED_MODULE_5__["default"])(currentSelection, function (id) {
                var node = _this.model.getById(id);
                if (!node) {
                    var idIndex = newSelection_1.indexOf(id);
                    newSelection_1.splice(idIndex, 1);
                }
            });
            if (currentSelection.length !== newSelection_1.length) {
                this.selector.setSelectedIds(newSelection_1);
            }
        }
    };
    return MessageRunner;
}());

var NodePainter = /** @class */ (function () {
    function NodePainter(state, imageUploading, imageHolder) {
        this.state = state;
        this.imageUploading = imageUploading;
        this.imageholder = imageHolder;
    }
    NodePainter.prototype.render = function (node, readonly, isRoot) {
        var nodeContainer = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div id="' + node.id + '" class="node"></div>');
        if (node.finish) {
            nodeContainer.addClass('finished');
        }
        if (node.collapsed && !isRoot) {
            nodeContainer.addClass('collapsed');
        }
        var contentWrapper = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="content-wrapper"></div>').appendTo(nodeContainer);
        // hotspot 是为了整行能响应鼠标，为了前边的展开、收缩图标能够在文字前边时也能出现
        contentWrapper.append('<div class="content-hotspot"></div>');
        // dot 元素是为了在打印的时候，也能打出圆点
        var bulletWrapper = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="bullet-wrapper"><div class="bullet" data-id="' + node.id + '"><div class="dot"></div></div></div>');
        contentWrapper.append(bulletWrapper);
        if (environment.isMobile) {
            bulletWrapper.children('.bullet').append('<div class="bullet-hotspot"></div>');
        }
        // 使用parseHTML创建元素，可以保证内部的动态内容不会被触发，如<img src=x onerror=alert(1)/>
        // parseHTML结果为原生DOM数组
        var contentEditor = jquery__WEBPACK_IMPORTED_MODULE_0___default.a.parseHTML('<div class="content" data-id="' + node.id + '" spellcheck="false" autocapitalize="off">' + node.text + '</div>');
        contentEditor = jquery__WEBPACK_IMPORTED_MODULE_0___default()(contentEditor);
        // 确保其中内容的安全性
        makeContentSafe(contentEditor);
        contentWrapper.append(contentEditor);
        if (!(true === readonly || true === this.state.readonly)) {
            contentEditor.attr('contenteditable', true);
        }
        if (node.heading) {
            contentWrapper.addClass('heading' + node.heading);
        }
        if (node.color && node.color !== '#333333') {
            contentEditor.css('color', node.color);
            contentWrapper.attr('color', node.color);
        }
        else {
            contentEditor.css('color', '');
        }
        this.renderNodeImages(node, nodeContainer, readonly);
        if (node.note) {
            var noteEditor = jquery__WEBPACK_IMPORTED_MODULE_0___default.a.parseHTML('<div class="note" spellcheck="false" autocapitalize="off">' + node.note + '</div>');
            noteEditor = jquery__WEBPACK_IMPORTED_MODULE_0___default()(noteEditor);
            // 确保其中内容的安全性
            makeContentSafe(noteEditor);
            nodeContainer.append(noteEditor);
            if (!(true === readonly || true === this.state.readonly)) {
                noteEditor.attr('contenteditable', true);
            }
        }
        if (!node.children || node.children.length === 0) {
            // 没有子节点，标识为叶子节点
            nodeContainer.addClass('mindnote-leaf');
        }
        // 展开收缩
        // 有子节点，立刻出现展开、收缩图标
        var toggle = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="action-icon toggle"></div>').appendTo(contentWrapper);
        var plusIcon = new default_1(IconSet.PLUS, 20);
        toggle.append(plusIcon.toString());
        var minusIcon = new default_1(IconSet.MINUS, 20);
        toggle.append(minusIcon.toString());
        return nodeContainer;
    };
    /**
     * 绘制节点的图片
     * @param node
     * @param nodeContainer 节点的容器
     * @param readonly 是否是只读状态
     */
    NodePainter.prototype.renderNodeImages = function (node, nodeContainer, readonly) {
        var images = node.images || [];
        var uploading = this.imageUploading.getByNodeId(node.id);
        images = images.concat(uploading);
        if (images.length > 0) {
            var imageContainer_1 = nodeContainer.children('.attach-image-list');
            if (imageContainer_1.length === 0) {
                var contentContainer = nodeContainer.children('.content-wrapper');
                imageContainer_1 = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="attach-image-list"></div>');
                contentContainer.after(imageContainer_1);
            }
            else {
                // 删除已经不存在的
                var currentImageIds_1 = [];
                jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(images, function (index, img) {
                    // 20171226之前的版本，没有id这个字段，用uri来判断，暂且认为用户不会再同一节点下添加相同的图片
                    var imgId = img.id || img.uri;
                    currentImageIds_1.push(imgId);
                });
                imageContainer_1.children('.attach-image-item').each(function () {
                    var item = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
                    var fid = item.attr('fid');
                    if (currentImageIds_1.indexOf(fid) < 0) {
                        // 不存在了，执行删除
                        item.remove();
                    }
                });
            }
            var me_1 = this;
            // 重新绘制
            jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(images, function (index, img) {
                // 20171226之前的版本，没有id这个字段，用uri来判断，暂且认为用户不会再同一节点下添加相同的图片
                var imgId = img.id || img.uri;
                var imgItem = imageContainer_1.children('div[fid="' + imgId + '"]');
                if (imgItem.length) {
                    // continue
                    // 已经存在，不重新创建
                    // 但是要修改uploading状态
                    if (!img.uploading) {
                        imgItem.removeClass('uploading');
                        me_1.imageholder.remove(img.id);
                        imgItem.attr('def', encodeURIComponent(JSON.stringify(img)));
                    }
                    if (img.w) {
                        imgItem.find('img').css('width', img.w);
                    }
                    return true;
                }
                imgItem = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div fid="' + imgId + '" class="attach-image-item"></div>');
                var imgItemWrapper = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="image-wrapper"></div>').appendTo(imgItem);
                var imgObj = jquery__WEBPACK_IMPORTED_MODULE_0___default()("<img data-nodeid=\"" + node.id + "\" ondragstart=\"return false\" class=\"attach-img loading\"/>");
                if (img.w) {
                    imgObj.css('width', img.w);
                }
                imgItemWrapper.append(imgObj);
                if (!(true === readonly || true === me_1.state.readonly)) {
                    imgItemWrapper.append("<div class=\"action attach-remove\" title=\"" + t('mindnote.editor.delete') + "\" data-nodeid=\"" + node.id + "\"></div>" +
                        ("<div class=\"action attach-copy\" title=\"" + t('mindnote.editor.copy') + "\" data-nodeid=\"" + node.id + "\"></div>") +
                        ("<div class=\"action attach-resize\" data-nodeid=\"" + node.id + "\"></div>"));
                }
                else {
                    imgObj.addClass('readonly');
                }
                if (index === 0) {
                    imageContainer_1.prepend(imgItem);
                }
                else {
                    var preImageItem = imageContainer_1.children('.attach-image-item:eq(' + (index - 1) + ')');
                    preImageItem.after(imgItem);
                }
                if (img.uploading) {
                    // 正在上传中，直接渲染
                    imgObj.on('load', function () {
                        var holder = me_1.imageholder.get(img.id);
                        if (holder) {
                            var progressWidth = holder.getProps().width || 0;
                            var imgWidth = imgObj.width() || 0;
                            /* 若图片的宽度小于默认的进度条宽度，则取75% */
                            if (imgWidth <= progressWidth) {
                                holder.update({ width: imgWidth * 0.75 });
                            }
                            holder.appendTo(imgItemWrapper);
                        }
                    });
                    imgItem.addClass('uploading'); // 标示此图片正在上传中
                    imgObj.removeClass('loading').attr('src', img.uri);
                    return;
                }
                imgItem.attr('def', encodeURIComponent(JSON.stringify(img)));
                var loadingSpinner = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="image-spinner"></div>');
                var spinnerWidth = img.w || img.ow;
                loadingSpinner.css('width', spinnerWidth);
                imgItemWrapper.append(loadingSpinner);
                // setTimeout的目的在于，立即取宽度，会无法获取，很诡异的问题
                setTimeout(function () {
                    loadingSpinner.css({
                        height: img.oh / img.ow * loadingSpinner.width(),
                    }).append('<div class="spinner-text">' +
                        '<div class="loader"></div>' +
                        ("<div>" + t('mindnote.editor.image_loding') + "</div>") +
                        '</div>');
                    imgObj.on('load', function () {
                        jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).removeClass('loading');
                        // 图片显示出来后
                        loadingSpinner.remove();
                    });
                    if (config.getImageURL) {
                        var imgFetch = config.getImageURL(img.uri);
                        if (typeof imgFetch === 'string') {
                            // 直接返回了
                            imgObj.attr('src', imgFetch);
                        }
                        else {
                            // 回返回一个promise对象
                            imgFetch.then(function (url) {
                                imgObj.attr('src', url);
                            });
                        }
                    }
                }, 0);
            });
        }
    };
    return NodePainter;
}());

/**
 * 初始化视图区域
 */
var Viewport = /** @class */ (function () {
    function Viewport(props) {
        var paperContainer = props.root;
        this.paper = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="mindnote-paper"></div>').appendTo(paperContainer);
        this.paperHeader = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="mindnote-header"></div>').appendTo(this.paper);
        this.nameContainer = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="mindnote-name"></div>').appendTo(this.paperHeader);
        this.nameContainer.append('<input type="text" placeholder="' + props.titlePlaceholder + '" maxlength="200"/>');
        this.dir = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="mindnote-dir"></div>').appendTo(this.paperHeader);
        this.nodeWrapper = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="mindnote-tree mindnote-wrapper"></div>').appendTo(this.paper);
        this.controlHolder = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="mindnote-control-holder"></div>').appendTo(paperContainer);
        this.demoScreen = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="mindnote-demo-screen"></div>').appendTo(paperContainer);
        // 获取scrollContainer
        this.scrollContainer = jquery__WEBPACK_IMPORTED_MODULE_0___default()('body');
        var element = paperContainer;
        while (true) {
            var parentElement = jquery__WEBPACK_IMPORTED_MODULE_0___default()(element).parent();
            if (parentElement[0].tagName.toLowerCase() === 'body') {
                this.scrollContainer = jquery__WEBPACK_IMPORTED_MODULE_0___default()(window);
                break;
            }
            if (parentElement.length === 0) {
                break;
            }
            var overflow = getComputedStyle(parentElement[0]).overflowY;
            if (overflow === 'auto' || overflow === 'scroll') {
                this.scrollContainer = parentElement;
                break;
            }
            element = parentElement;
        }
    }
    return Viewport;
}());

var Lifecycle = /** @class */ (function () {
    function Lifecycle(state) {
        this.state = state;
    }
    Lifecycle.prototype.destroy = function () {
        jquery__WEBPACK_IMPORTED_MODULE_0___default()(document).off('.drag_node').off('.mindnote-global').off('.mindnote-hotkey').off('.selector');
        jquery__WEBPACK_IMPORTED_MODULE_0___default()('body').off('.mindnote').off('.mindnote-preview-image');
        jquery__WEBPACK_IMPORTED_MODULE_0___default()(this.state.getEditorProps().root).empty();
        jquery__WEBPACK_IMPORTED_MODULE_0___default()(window).off('.mindnote-preview-image');
    };
    return Lifecycle;
}());

var themes = {
    default: {
        lineColor: '#d9d9d9',
        bgColor: '#393c41'
    },
    classic: {
        lineColor: '#ced6da',
        bgColor: '#e6eef2'
    },
    blueprint: {
        lineColor: '#ccf0fb',
        bgColor: '#00b5ed',
        bgImage: 'iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAIAAAAC64paAAABuUlEQVQ4y0VUi27EIAzL//9MS0vLtbft9pL2MaXc3b5giZ0wCSEaArEdU5Gvp9weNn885Nps/XKXd0R+fuXtLq8YusXFJzJviNj3pcnWJFdZThkPyaekasF0yN4sMleby2kJw2FDc6YqdndGqn5vmPfmkfX0PJ7U3SniI64wDCuuzLh+R4YOBi1+WuUZxzRhRU09qVtGUkN6q3LQkALW9YxtjSdU0OyMMYACOeowzpqRY5vHFGQBFjsGkAsKzsgpgGOwVdghrp+rz6k61B0oSGoJCRh3ztSgk9nATYMLRCKKDdnr6aQSMg02mbCa7lEYKt+ZLyEbjxGgfD/9MAmz/gpWOeDoASrH+kNchz4DWKpehMxz9X4Swhxqs1t0jnGmn6bYJlt2khXGw+WgbFtzLYwzNegG6Cb1AyESR4kcq6wmSWGGApJcE3AJM9NtXTPq4n2+tv8mX0IVykM/ExrJp7jCnh7F7L5hhZ7n3QrYpL1AYHu9dIgbqMajQ88Z5C7nElrMrDxEhyhvd/J4eEv6U+PbHCLHWkWe5fTsHCYnBVbmn6D7n2uTqvtGM/hXoau46L+O3mc64tL+ACwpi9fme+GxAAAAAElFTkSuQmCC'
    },
    f1: {
        lineColor: '#595959',
        bgColor: '#dfdfdf',
        bgImage: 'iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAIAAADZrBkAAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyhpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuNi1jMTM4IDc5LjE1OTgyNCwgMjAxNi8wOS8xNC0wMTowOTowMSAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENDIDIwMTcgKE1hY2ludG9zaCkiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6OTdEMUQwM0NGQzM1MTFFODg2QTNERjMyNjc4NUQ3QUEiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6OTdEMUQwM0RGQzM1MTFFODg2QTNERjMyNjc4NUQ3QUEiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDo5N0QxRDAzQUZDMzUxMUU4ODZBM0RGMzI2Nzg1RDdBQSIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDo5N0QxRDAzQkZDMzUxMUU4ODZBM0RGMzI2Nzg1RDdBQSIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/Ps9LsPsAAABdSURBVHjaxNGxDcAwCARADOy/IKsAiZWI7yLZLshXLrB0D8PM6ImqUuWqiEhEjAoGmI5y+E2/bJk5Ve8bA+7+C3LLhkbNyHnNdRsaNSO3bNh2M5KZ121o1Iu8BRgA6GJo2uYS8pIAAAAASUVORK5CYII='
    },
    fresh: {
        lineColor: '#dfcef2',
        bgColor: '#fff'
    },
    fruit: {
        lineColor: '#ced1d1',
        bgColor: '#fff'
    },
    nature: {
        lineColor: '#c8ae9f',
        bgColor: '#e4cfc4'
    },
    vanilla: {
        lineColor: '#dcce9f',
        bgColor: '#f6f0c1',
        bgImage: 'iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAIAAAAC64paAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyhpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuNi1jMTM4IDc5LjE1OTgyNCwgMjAxNi8wOS8xNC0wMTowOTowMSAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENDIDIwMTcgKE1hY2ludG9zaCkiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6OTdEMUQwNDBGQzM1MTFFODg2QTNERjMyNjc4NUQ3QUEiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6OTk1MUVGNDhGQzM3MTFFODg2QTNERjMyNjc4NUQ3QUEiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDo5N0QxRDAzRUZDMzUxMUU4ODZBM0RGMzI2Nzg1RDdBQSIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDo5N0QxRDAzRkZDMzUxMUU4ODZBM0RGMzI2Nzg1RDdBQSIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/Pg4ePsIAAAK6SURBVHjaLJTrbtNAEIXnsnbShLQgQEL85Pl5MKSKS0mbJvbuDN+4RNbGsedy5pwz0fPjd7N9iqhN0c/qdxLDp4cY17E+WdvzRm1WnUR486JiEQvB7sfm7UH9lHET203tY4yL+pwaon0+fBvj2fydZET/Sw+f3pHfpk+iHusfG/1v5lCdM14pQRPJzo23D5GcDzKuhHo7pcr2/JDjVXJ4uzdr96oN0OZHqogYbekW4yxJzCVyyXEGaqFTzbRqILyUtkE6izWt/AM41XY5rpwRrwRQPWuWnekx+ovkDQhCIXL49ulz5krzGK9eoeBsKWEGliXW3wZmOgtD7QS2xMWZLqDu2tdHaJC3buMCvJTBOyglzufP+n+oEHrUJwtsipnd+fTR/ETn6g95NVJm9rH83M5H0kb/436KuBUFgG0fMm+taKAPTIwlq8XxLZ/f6lPEi0/EdUD12482f0o1AjZqJtukvxRsbdSWN0rjWr3RLEehjY5J2v4r0GJ9qonUmKhhqRJzEykqZ5HRtR00ta8/fXof+EQ386GouLUj3SBfxq1hHbWD6i4TYSi3V07BYmvbfYEhSIE/93uYV2mRK9Mq+cWXHymJvTCZqnPCCsLWYOuviE0egNYTJdN0RjnzBykP2IGRGExRkn65bKxutXxXOseFe5iRWhEf9dPKKhTq6y+ems01MKvDeLmwA6WklpC1RuOZUBQCgdt+s1AXm8uVIUSf3FmpZ9BmDbz4dD/607ahizqkOPzTQMsjaLkv2CUXZLBSSFK47kxwf3DVeuTNDDjbqmX38tkC55uduhWGIOJQxHA/GHKt1Q+cmMUI21qIOsyXHYRaXoO290TjCojpG5jdJrhsgveadv296Vf/JKCq9aCQsfxL1Pay8cDrUDIILbdWfkI1CXiTi/6VI8ZQ6kf6O1bJ/k+AAQCpkxE+Hwcm2QAAAABJRU5ErkJggg=='
    },
    pro: {
        lineColor: '#828c96',
        bgColor: '#b4bcc3'
    },
    rose: {
        lineColor: '#c28c9f',
        bgColor: '#f9c8d9'
    }
};

var WatermarkColor;
(function (WatermarkColor) {
    WatermarkColor["LIGHT"] = "rgba(0, 0, 0, .04)";
    WatermarkColor["DARK"] = "rgba(255, 255, 255, .04)";
})(WatermarkColor || (WatermarkColor = {}));
/**
 * 在 Lark 的水印基础上封装的水印组件
 */
var Watermark = /** @class */ (function () {
    /**
     * 初始化水印实例
     * @param className 样式名
     * @param text 水印文字
     * @param opts 参数
     */
    function Watermark(className, text, opts) {
        this.selector = '.' + className;
        this.text = text;
        this.wm = new _bdeefe_watermark__WEBPACK_IMPORTED_MODULE_11__["default"](text, __assign({}, opts, { type: 'canvas', selector: this.selector }));
    }
    Watermark.prototype.update = function (opts) {
        this.wm.update(this.text, __assign({}, opts, { selector: this.selector }));
    };
    Watermark.prototype.destroy = function () {
        this.wm.destroy();
    };
    return Watermark;
}());

/**
 * 下载大文件blob
 * @param blob
 */
function downloadBlob(blob, fileName) {
    Object(file_saver__WEBPACK_IMPORTED_MODULE_12__["saveAs"])(blob, fileName);
    // if (window.navigator.msSaveOrOpenBlob) {
    // 	navigator.msSaveBlob(blob, fileName);
    // }
}

/**
 * 思维笔记导出模块
 */
var MinderExporter = /** @class */ (function () {
    function MinderExporter(minder, state, eventSource) {
        this.resultW = 0;
        this.resultH = 0;
        this.resultSize = 0;
        this.resultScale = 1;
        this.zoom = 1;
        this.fontFamily = '"Helvetica Neue", -apple-system, BlinkMacSystemFont, "Segoe UI", "PingFang SC", Roboto, "Microsoft YaHei", "Source Han Sans SC", "Noto Sans CJK SC", "Myriad Pro", "Hiragino Sans", "Yu Gothic", "Lucida Grande", sans-serif';
        this.freemindDownloading = false;
        this.imageDownloading = false;
        this.minder = minder;
        this.state = state;
        this.eventSource = eventSource;
    }
    MinderExporter.prototype.drawMindImage = function () {
        if (this.imageDownloading) {
            return;
        }
        this.wrapper = this.minder.getMindMap();
        this.resultW = this.wrapper.width();
        this.resultH = this.wrapper.height();
        var topicCount = this.wrapper.find('.topic:visible').length;
        this.resultSize = this.resultW * this.resultH;
        if (topicCount > 2000 || this.resultSize > 80000000) {
            // 不允许导出图片
            // $.alert({
            // 	title: '无法导出',
            // 	content: '思维导图尺寸太大，不能导出图片，图片最多支持2000条主题，您可以：<div>1. 折叠不重要的主题</div><div>2. 点击某一子主题，进入主题后，导出相应的主题</div>'
            // });
            return;
        }
        if (this.resultSize <= 8000000) {
            // 800w像素内的图片，可以保存两倍
            this.resultScale = 2;
        }
        else if (this.resultSize <= 20000000) {
            this.resultScale = 1.5;
        }
        else {
            this.resultScale = 1;
        }
        if (isMobile()) {
            // 手机端要全屏遮罩一下
            jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div id="mind-export-indicator"><div class="loader"></div></div>').appendTo('body');
        }
        jquery__WEBPACK_IMPORTED_MODULE_0___default()('#mind-download-image').text(t('mindnote.editor.exporting'));
        this.imageDownloading = true;
        this.canvas = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<canvas></canvas>').appendTo('body');
        this.canvas.attr({
            width: this.resultW * this.resultScale,
            height: this.resultH * this.resultScale
        });
        this.ctx = this.canvas[0].getContext('2d');
        this.wrapperOffset = this.wrapper.offset();
        this.ctx.save();
        this.ctx.scale(this.resultScale, this.resultScale);
        // 准备，画一个背景
        var bgHolder = jquery__WEBPACK_IMPORTED_MODULE_0___default()('#mind-bg-holder');
        var bgImg = bgHolder.children('img');
        if (bgImg.length) {
            // 背景图片平铺
            this.ctx.fillStyle = this.ctx.createPattern(bgImg[0], 'repeat');
        }
        else {
            this.ctx.fillStyle = bgHolder.data('color');
        }
        this.ctx.fillRect(0, 0, this.resultW, this.resultH);
        // 第一步，先画线
        this.drawLinkers();
        this.ctx.restore(); // 重置回未缩放状态
        this.drawAfterReady();
    };
    /**
     * 绘制导出的图片中的连接线
     */
    MinderExporter.prototype.drawLinkers = function () {
        var me = this;
        this.wrapper.find('.linker-container:visible').each(function () {
            var lineContainer = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            var line = lineContainer.children('svg');
            var offset = line.offset();
            // 相对于容器的坐标
            var left = (offset.left - me.wrapperOffset.left) / me.zoom;
            var top = (offset.top - me.wrapperOffset.top) / me.zoom;
            me.ctx.save();
            me.ctx.translate(left, top);
            var path = lineContainer.attr('path-d');
            var reg = /[A-Z]/g; // 匹配任意字母
            var matches = path.match(reg);
            var points = path.split(reg);
            var actionIndex = 0;
            me.ctx.beginPath();
            jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(points, function (index, point) {
                point = jquery__WEBPACK_IMPORTED_MODULE_0___default.a.trim(point);
                if (point) {
                    var action = matches[actionIndex];
                    if (action === 'M') {
                        var movePoint = point.split(',');
                        me.ctx.moveTo(movePoint[0], movePoint[1]);
                    }
                    else if (action === 'L') {
                        var lineToPoint = point.split(',');
                        me.ctx.lineTo(lineToPoint[0], lineToPoint[1]);
                    }
                    else if (action === 'C') {
                        var curvePoints = point.split(' ');
                        var control1 = curvePoints[0].split(',');
                        var control2 = curvePoints[1].split(',');
                        var endPoint = curvePoints[2].split(',');
                        me.ctx.bezierCurveTo(control1[0], control1[1], control2[0], control2[1], endPoint[0], endPoint[1]);
                    }
                    else if (action === 'Q') {
                        var quaPoints = point.split(' ');
                        var qua1 = quaPoints[0].split(',');
                        var quaEnd = quaPoints[1].split(',');
                        me.ctx.quadraticCurveTo(qua1[0], qua1[1], quaEnd[0], quaEnd[1]);
                    }
                    actionIndex++;
                }
            });
            me.ctx.strokeStyle = line.attr('stroke');
            me.ctx.lineWidth = parseInt(line.attr('stroke-width'));
            me.ctx.stroke();
            // 还原位移
            me.ctx.restore();
        });
    };
    /**
     * 基础工作准备好后，背景画好，连线都画好后
     * 继续绘制其他内容
     */
    MinderExporter.prototype.drawAfterReady = function () {
        var me = this;
        this.ctx.scale(this.resultScale, this.resultScale);
        this.ctx.save();
        // 第二步，绘制展开收缩的图标，因为他的z级别是在线上边，主题下边
        var icons = this.wrapper.find('.tp-expand-box:visible');
        icons.each(function () {
            me.ctx.save();
            var icon = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            var offset = icon.offset();
            // 相对于容器的坐标
            var left = (offset.left - me.wrapperOffset.left) / me.zoom;
            var top = (offset.top - me.wrapperOffset.top) / me.zoom;
            var iconWidth = icon.width();
            if (iconWidth > 12) {
                // 如果宽度大于12，说明是左右有线的一级主题后边的图标，要画一条线
                var lineColor = icon.css('background-color');
                me.ctx.strokeStyle = lineColor;
                me.ctx.lineWidth = 2;
                me.ctx.beginPath();
                me.ctx.moveTo(left, top + 1);
                me.ctx.lineTo(left + iconWidth, top + 1);
                me.ctx.stroke();
                // 图标的位置向右移动2像素
                left += 3.5;
            }
            // 展开收缩
            me.ctx.beginPath();
            var radius = 6;
            me.ctx.beginPath();
            var center = { x: left + radius, y: top + 1 };
            me.ctx.arc(center.x, center.y, radius, Math.PI * 2, false);
            me.ctx.fillStyle = '#fff';
            me.ctx.fill();
            me.ctx.strokeStyle = '#888';
            me.ctx.lineWidth = 1.6;
            me.ctx.beginPath();
            me.ctx.moveTo(center.x - 3, center.y);
            me.ctx.lineTo(center.x + 3, center.y);
            me.ctx.stroke();
            if (icon.parents('.tp-container').hasClass('collapsed')) {
                me.ctx.beginPath();
                me.ctx.moveTo(center.x, center.y - 3);
                me.ctx.lineTo(center.x, center.y + 3);
                me.ctx.stroke();
            }
            me.ctx.restore();
        });
        // 第三步，绘制块节点，包括中心主题和分支主题
        var topics = me.wrapper.find('.topic-text.root, .topic-text.sub');
        topics.each(function () {
            me.ctx.save();
            var topic = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            var bgColor = topic.css('background-color');
            var borderWidth = parseInt(topic.css('border-left-width'));
            me.ctx.fillStyle = bgColor;
            var offset = topic.offset();
            // 相对于容器的坐标
            var left = (offset.left - me.wrapperOffset.left) / me.zoom;
            var top = (offset.top - me.wrapperOffset.top) / me.zoom;
            var width = topic.outerWidth();
            var height = topic.outerHeight();
            var radius = topic.hasClass('sub') ? 6 : 10;
            me.ctx.beginPath();
            me.ctx.moveTo(left + radius, top);
            me.ctx.lineTo(left + width - radius, top);
            me.ctx.quadraticCurveTo(left + width, top, left + width, top + radius);
            me.ctx.lineTo(left + width, top + height - radius);
            me.ctx.quadraticCurveTo(left + width, top + height, left + width - radius, top + height);
            me.ctx.lineTo(left + radius, top + height);
            me.ctx.quadraticCurveTo(left, top + height, left, top + height - radius);
            me.ctx.lineTo(left, top + radius);
            me.ctx.quadraticCurveTo(left, top, left + radius, top);
            me.ctx.closePath();
            me.ctx.fill();
            if (borderWidth > 0) {
                me.ctx.strokeStyle = topic.css('border-left-color');
                me.ctx.lineWidth = borderWidth;
                me.ctx.stroke();
            }
            me.ctx.restore();
        });
        // 第四步，绘制文字
        var allTopics = me.wrapper.find('.topic-text:visible');
        allTopics.each(function () {
            me.ctx.save();
            var topic = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            var offset = topic.offset();
            // 计算开始写字的坐标
            var left = (offset.left - me.wrapperOffset.left) / me.zoom;
            var top = (offset.top - me.wrapperOffset.top) / me.zoom;
            var paddingLeft = 0;
            var paddingTop = 0;
            var lineHeight = 20;
            var fontSize = '14px';
            if (topic.hasClass('root')) {
                paddingLeft = 25;
                paddingTop = 10;
                lineHeight = 36;
                fontSize = '24px';
            }
            else if (topic.hasClass('sub')) {
                paddingLeft = 15;
                paddingTop = 6;
                lineHeight = 27;
                fontSize = '16px';
            }
            var borderWidth = parseInt(topic.css('border-left-width'));
            var defaultFont = fontSize + ' ' + me.fontFamily;
            me.ctx.textBaseline = 'middle';
            me.ctx.fillStyle = topic.css('color');
            var temp = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div></div>');
            temp.html(topic.html());
            var textNodes = temp[0].childNodes;
            var beginX = left + paddingLeft;
            var currentX = 0;
            var currentY = top + paddingTop + lineHeight / 2;
            if (borderWidth) {
                currentY += borderWidth;
                beginX += borderWidth;
            }
            var maxWidth = 500;
            if (textNodes.length > 0) {
                for (var i = 0; i < textNodes.length; i++) {
                    // 此处要忽略掉描述节点
                    var node = textNodes[i];
                    var text = void 0;
                    me.ctx.save();
                    var font = defaultFont;
                    if (node.nodeName === '#text') {
                        text = node.textContent;
                    }
                    else {
                        node = jquery__WEBPACK_IMPORTED_MODULE_0___default()(node);
                        text = node.text();
                        if (node.hasClass('bold')) {
                            font = 'bold ' + font;
                        }
                        if (node.hasClass('italic')) {
                            font = 'italic ' + font;
                        }
                    }
                    me.ctx.font = font;
                    var textWidth = me.ctx.measureText(text).width;
                    if (currentX + textWidth > maxWidth) {
                        // 开始换行，一个字符一个字符的绘制
                        for (var wi = 0; wi < text.length; wi++) {
                            var ch = text[wi];
                            var chWidth = me.ctx.measureText(ch).width;
                            if (currentX + chWidth > maxWidth) {
                                // 超出，重新换行
                                currentY += lineHeight;
                                currentX = 0;
                            }
                            me.ctx.fillText(ch, currentX + beginX, currentY);
                            currentX += chWidth;
                        }
                    }
                    else {
                        me.ctx.fillText(text, currentX + beginX, currentY);
                        currentX += textWidth;
                    }
                    me.ctx.restore();
                }
            }
            if (topic.children('.topic-note').length) {
                // 包括备注，绘制一个小图标
                currentX += 5;
                if (currentX + 18 > maxWidth) {
                    currentY += lineHeight;
                    currentX = 0;
                }
                // 展开收缩
                me.ctx.beginPath();
                var radius = 9;
                me.ctx.beginPath();
                var center = { x: currentX + beginX + 9, y: currentY };
                me.ctx.arc(center.x, center.y, radius, Math.PI * 2, false);
                me.ctx.fillStyle = '#fff6cc';
                me.ctx.fill();
                me.ctx.strokeStyle = '#4f575d';
                me.ctx.lineWidth = 1.2;
                var lineBeginX = center.x - 5;
                var lineEndX = center.x + 5;
                me.ctx.beginPath();
                me.ctx.moveTo(lineBeginX, center.y - 3);
                me.ctx.lineTo(lineEndX, center.y - 3);
                me.ctx.moveTo(lineBeginX, center.y);
                me.ctx.lineTo(lineEndX, center.y);
                me.ctx.moveTo(lineBeginX, center.y + 3);
                me.ctx.lineTo(lineEndX, center.y + 3);
                me.ctx.stroke();
            }
            me.ctx.restore();
        });
        // 第五步，绘制文档内图片
        var attachImages = me.wrapper.find('.attach-img');
        attachImages.each(function () {
            var imgItem = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            if (imgItem.is(':visible') && !imgItem.hasClass('loading')) {
                var offset = imgItem.offset();
                // 相对于容器的坐标
                var left = (offset.left - me.wrapperOffset.left) / me.zoom;
                var top_1 = (offset.top - me.wrapperOffset.top) / me.zoom;
                var width = imgItem.width();
                var height = imgItem.height();
                me.ctx.drawImage(imgItem[0], left, top_1, width, height);
            }
        });
        var downloadName = this.getDownloadName();
        downloadName += '.png';
        var resultBase64 = me.canvas[0].toDataURL('image/png');
        me.canvas.remove();
        jquery__WEBPACK_IMPORTED_MODULE_0___default()('#mind-download-image').text(t('mindnote.editor.image'));
        jquery__WEBPACK_IMPORTED_MODULE_0___default()('#mind-export-indicator').remove();
        me.imageDownloading = false;
        if (this.state.getEditorProps().env === MindNoteEnvironment.APP) {
            var data = {
                name: downloadName,
                base64Data: resultBase64
            };
            this.eventSource.trigger(SourceEvent.MIND_MAP_EXPORT, data);
        }
        else {
            // PC端直接下载
            var blob = dataURItoBlob(resultBase64);
            downloadBlob(blob, downloadName);
        }
    };
    MinderExporter.prototype.getDownloadName = function () {
        var downloadName = this.wrapper.find('.topic-text.root').text();
        if (!downloadName) {
            downloadName = t('mindnote.editor.mind_export_name');
        }
        if (downloadName.length > 25) {
            downloadName = downloadName.substr(0, 25);
        }
        return downloadName;
    };
    /**
     * 构建FreeMind节点
     * @param node
     * @param container
     * @param position
     */
    MinderExporter.prototype.buildFreeMindNode = function (node, container, position) {
        var outline = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<node>\n</node>').appendTo(container);
        var text = node.text;
        outline.attr('TEXT', htmlToText(text));
        outline.attr('ID', node.id);
        if (position) {
            // 如果包含position参数，说明是顶级分支主题，气泡样式
            outline.attr('STYLE', 'bubble');
            outline.attr('POSITION', position);
        }
        else {
            outline.attr('STYLE', 'fork');
        }
        // 构建子节点
        var me = this;
        if (node.children && node.children.length > 0) {
            jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(node.children, function (index, child) {
                me.buildFreeMindNode(child, outline);
            });
        }
        outline.append('\t\t');
    };
    /**
     * 导出思维导图图片
     */
    MinderExporter.prototype.exportMindImage = function (z) {
        this.zoom = z;
        this.drawMindImage();
    };
    /**
     * 导出FreeMind
     * @param nodes
     * @param structure
     * @returns {string}
     */
    MinderExporter.prototype.exportFreeMind = function (nodes, structure) {
        if (this.freemindDownloading) {
            return;
        }
        this.freemindDownloading = true;
        this.wrapper = this.minder.getMindMap();
        var container = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div></div>');
        var rootNode = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<node></node>').appendTo(container);
        rootNode.attr('ID', 'root');
        rootNode.attr('TEXT', this.wrapper.find('.topic-text.root').text());
        // 构建内容
        var me = this;
        if (nodes) {
            jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(nodes, function (index, node) {
                var position = structure;
                if (structure === 'org' || structure === 'default') {
                    if (index + 1 > Math.ceil(nodes.length / 2)) {
                        position = 'left';
                    }
                    else {
                        position = 'right';
                    }
                }
                me.buildFreeMindNode(node, rootNode, position);
            });
        }
        container.find('node').after('\n');
        container.find('node').before('\t\t');
        var outlineXml = container.html();
        var xmlContent = '<map>\n' +
            outlineXml +
            '</map>';
        // 属性转为大写，因为结果会自动小写，processon无法识别小写属性
        xmlContent = xmlContent.replace(new RegExp('text=', 'g'), 'TEXT=')
            .replace(new RegExp('id=', 'g'), 'ID=')
            .replace(new RegExp('style=', 'g'), 'STYLE=')
            .replace(new RegExp('position=', 'g'), 'POSITION=');
        var blob = new Blob([xmlContent], { type: 'text/xml' });
        downloadBlob(blob, this.getDownloadName() + '.mm');
        this.freemindDownloading = false;
    };
    return MinderExporter;
}());

function ThemeToWatermarkColor(theme) {
    switch (theme) {
        case 'default':
            return WatermarkColor.DARK;
        case 'classic':
            return WatermarkColor.LIGHT;
        default:
            return WatermarkColor.LIGHT;
    }
}
var Minder = /** @class */ (function () {
    function Minder(state, engine, eventSource, viewport) {
        /**
         * 是否已经打开
         */
        this.opened = false;
        this.nodeMapping = {}; // 节点的映射
        this.docName = '';
        this.rootId = '';
        this.zoom = 1;
        this.mapMargin = 0;
        // 是否自动收缩子主题，在节点数量太多的情况下，会自动收缩
        this.subTopicAutoCollapsed = false;
        // 移动端状态栏的高度，在手机上，statusBar的高度，会影响导航栏的位置
        this.statusBarSpacing = 0;
        // 是否延迟定位思维导图，因为移动端需要进行隐藏statusBar，navigator等行为，所以要延迟一下，优化体验
        this.delayRelocateMindMap = false;
        this.asyncDrawing = false;
        this.wm = null;
        this.state = state;
        this.engine = engine;
        this.eventSource = eventSource;
        this.mapMargin = Math.max(Math.max(screen.width, screen.height) / 2, 800);
        this.delayRelocateMindMap = this.state.getEditorProps().delayRelocateMindMap;
        this.statusBarSpacing = this.state.getEditorProps().statusBarSpacing;
        this.minderExporter = new MinderExporter(this, state, eventSource);
        this.viewport = viewport;
    }
    Minder.prototype.close = function () {
        jquery__WEBPACK_IMPORTED_MODULE_0___default()('.mind-exit-btn').trigger('click');
    };
    Minder.prototype.getMindMap = function () {
        return this.mindMap;
    };
    /**
     * 执行打开思维导图
     * @param def
     * @param {string} title
     * @param {string} rootNodeId
     */
    Minder.prototype.open = function (def, title, rootNodeId, watermark) {
        var _this = this;
        // 避免重复初始化
        if (this.opened) {
            return;
        }
        if (navigator.appName === 'Microsoft Internet Explorer'
            && navigator.appVersion.toLowerCase().indexOf('msie 9.0') >= 0) {
            // IE9不支持flex，需要特殊处理，Holy shit!!!!!!
            // $.alert({
            // 	title: '请升级您的浏览器',
            // 	content: '您正在使用低版本的IE浏览器，无法查看思维导图。<br>' +
            // 	'请升级您的浏览器，或查看当前处于否是兼容模式或低版本仿真模式。<br>' +
            // 	'<a target="_blank" href="/browser" class="link">查看推荐浏览器</a>'
            // });
            return;
        }
        var defaults = {
            structure: 'default',
            theme: 'default'
        };
        this.definition = jquery__WEBPACK_IMPORTED_MODULE_0___default.a.extend(true, defaults, def);
        this.nodeMapping = {};
        if (this.definition.nodes && this.definition.nodes.length > 0) {
            // 绘制节点
            recursive(this.definition.nodes, function (node, parentNode) {
                _this.nodeMapping[node.id] = {
                    node: node,
                    parent: parentNode ? parentNode : null
                };
            });
        }
        // 判断是否太大
        if (this.isTooLarge(rootNodeId)) {
            return;
        }
        this.docName = title;
        this.rootId = rootNodeId;
        // 触发事件
        this.eventSource.trigger(SourceEvent.MIND_MAP_OPEN);
        if (environment.isMobile) {
            this.zoom = 0.7;
        }
        else {
            this.zoom = 1;
        }
        var themeConfig = themes;
        this.currentTheme = themeConfig[this.definition.theme];
        jquery__WEBPACK_IMPORTED_MODULE_0___default()('#mind-screen').remove();
        this.mindScreen = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div id="mind-screen"></div>').appendTo(this.viewport.controlHolder);
        var dataId = Date.now();
        this.mindCanvas = jquery__WEBPACK_IMPORTED_MODULE_0___default()("<div class=\"mind-canvas\"></div>").appendTo(this.mindScreen);
        var className = "mindnote-map-watermark__" + dataId;
        jquery__WEBPACK_IMPORTED_MODULE_0___default()("<div class=\"mindnote-map-watermark " + className + "\"></div>").appendTo(this.mindCanvas);
        if (watermark) {
            var color = ThemeToWatermarkColor(this.definition.theme);
            this.wm = new Watermark(className, watermark, { color: color });
        }
        if (environment.isMobile) {
            this.mindScreen.addClass('mobile-style');
        }
        this.mindMap = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="mind-map"></div>').appendTo(this.mindCanvas);
        var mindMenu = this.initMenu();
        if (this.delayRelocateMindMap) {
            mindMenu.hide();
        }
        this.draw();
        this.refreshDir();
        this.initOperate();
        this.mindScreen.css('opacity', 1);
        this.autoTip();
        this.mindScreen.on('keydown', function (e) {
            e.stopPropagation();
        });
        if (this.delayRelocateMindMap) {
            setTimeout(function () {
                _this.locateMap();
                mindMenu.fadeIn(200);
                _this.mindMap.css('opacity', 1);
            }, 400);
        }
        else {
            this.mindMap.css('opacity', 1);
        }
        this.opened = true;
    };
    /**
     * 自动小提示
     */
    Minder.prototype.autoTip = function () {
        var _this = this;
        if (!environment.isMobile && !(localStorage && localStorage.mindTip)) {
            if (localStorage) {
                localStorage.mindTip = true;
            }
            setTimeout(function () {
                jquery__WEBPACK_IMPORTED_MODULE_0___default()('.mind-tip').remove();
                var tip = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="mind-tip"></div>');
                _this.mindScreen.append(tip);
                tip.append("<div class=\"header\">" + t('mindnote.editor.tips') + "</div>");
                tip.append("<div class=\"body\">" + t('mindnote.editor.click_item_tips') + "</div>");
                tip.append("<div class=\"footer\"><span class=\"close\">" + t('mindnote.editor.got_it') + "</span></div>");
                tip.find('.close').on('click', function () {
                    tip.fadeOut();
                });
                tip.fadeIn();
                setTimeout(function () {
                    tip.fadeOut();
                }, 15000);
            }, 1500);
        }
        if (this.subTopicAutoCollapsed) {
            setTimeout(function () {
                var collapseTip = jquery__WEBPACK_IMPORTED_MODULE_0___default()("<div class=\"mind-collapsed-tip\">" + t('mindnote.editor.content_oversized') + "</div>").appendTo(_this.viewport.controlHolder);
                collapseTip.fadeIn();
                setTimeout(function () {
                    collapseTip.fadeOut(function () {
                        collapseTip.remove();
                    });
                }, 4000);
            }, 1500);
        }
    };
    /**
     * 初始化菜单
     */
    Minder.prototype.initMenu = function () {
        var _this = this;
        var iconSize = 17;
        var menu = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="mind-menu"></div>').appendTo(this.viewport.controlHolder);
        var list = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<ul class="menu-list"></ul>');
        menu.append(list);
        var zoomInIcon = new default_1(IconSet.ZOOM_IN, iconSize);
        var zoomIn = jquery__WEBPACK_IMPORTED_MODULE_0___default()("<li title=\"" + t('mindnote.editor.zoom_in') + "\">" + zoomInIcon.toString() + "</li>");
        list.append(zoomIn);
        zoomIn.on('click', function () {
            var changePercent = 0.2;
            if (_this.zoom < 1) {
                changePercent = 0.15;
            }
            _this.zoomMap(changePercent);
            _this.hidePanel();
        });
        var zoomOutIcon = new default_1(IconSet.ZOOM_OUT, iconSize);
        var zoomOut = jquery__WEBPACK_IMPORTED_MODULE_0___default()("<li title=\"" + t('mindnote.editor.zoom_out') + "\">" + zoomOutIcon.toString() + "</li>");
        list.append(zoomOut);
        zoomOut.on('click', function () {
            var changePercent = 0.2;
            // 包含1
            if (_this.zoom <= 1) {
                changePercent = 0.15;
            }
            _this.zoomMap(-changePercent);
            _this.hidePanel();
        });
        if (!this.state.readonly) {
            var magicIcon = new default_1(IconSet.MAGIC, iconSize);
            var setting = jquery__WEBPACK_IMPORTED_MODULE_0___default()("<li class=\"mind-item-readonly-hide\" title=\"" + t('mindnote.editor.structure_and_style') + "\" panel=\"style\">" + magicIcon.toString() + "</li>");
            list.append(setting);
            var me_1 = this;
            setting.on('click', function () {
                if (jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).hasClass('active')) {
                    me_1.hidePanel();
                }
                else {
                    me_1.showPanel('style');
                }
            });
        }
        if (environment.isMobile) {
            menu.addClass('mobile-style');
            if (this.state.getEditorProps().env === MindNoteEnvironment.APP) {
                menu.addClass('app-style');
            }
        }
        if (!environment.isMobile || this.state.getEditorProps().env === 'app') {
            // PC版和app里，可以导出图片
            var downloadIcon = new default_1(IconSet.DOWNLOAD, iconSize);
            var download = jquery__WEBPACK_IMPORTED_MODULE_0___default()("<li title=\"" + t('') + "\" panel=\"export\">" + downloadIcon.toString() + "</li>");
            list.append(download);
            download.on('click', function () {
                if (_this.state.getEditorProps().env === 'app') {
                    // 手机端直接导出图片
                    _this.exportImage();
                }
                else {
                    _this.showPanel('export');
                }
            });
        }
        var exit = jquery__WEBPACK_IMPORTED_MODULE_0___default()("<li title=\"" + t('mindnote.editor.exit') + "\" class=\"mind-exit-btn\">" + t('mindnote.editor.exit') + "</li>");
        list.append(exit);
        exit.on('click', function () {
            _this.opened = false;
            _this.mindScreen.css('opacity', 0);
            menu.remove();
            // 触发事件
            _this.eventSource.trigger(SourceEvent.MIND_MAP_CLOSE);
            _this.mindMap = null;
            _this.clearSyncChildrenLinker();
            setTimeout(function () {
                _this.mindScreen.remove();
                if (_this.wm) {
                    _this.wm.destroy();
                }
            }, 400);
            jquery__WEBPACK_IMPORTED_MODULE_0___default()(document).off('keydown.mind');
            jquery__WEBPACK_IMPORTED_MODULE_0___default()(document).off('mousedown.mind-panel');
        });
        menu.on('mousedown', function (e) {
            e.stopPropagation();
        });
        this.initPanel();
        jquery__WEBPACK_IMPORTED_MODULE_0___default()(document).on('keydown.mind', function (e) {
            if (e.keyCode === 27) {
                // esc退出
                exit.trigger('click');
            }
            else if (e.keyCode === 219) {
                // 阻止ctrl + [
                e.preventDefault();
            }
        });
        return menu;
    };
    /**
     * 初始化面板
     */
    Minder.prototype.initPanel = function () {
        var _this = this;
        var themePanel = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="mind-panel style-panel"></div>').appendTo(this.mindScreen);
        themePanel.append("<div class=\"panel-title\">" + t('mindnote.editor.structure') + "</div>");
        var structBox = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<ul class="panel-box struct-panel"></ul>').appendTo(themePanel);
        structBox.append('<li class="default" data-st="default"><div></div></li>');
        structBox.append('<li class="right" data-st="right"><div></div></li>');
        structBox.append('<li class="left" data-st="left"><div></div></li>');
        structBox.append('<li class="org" data-st="org"><div></div></li>');
        themePanel.append("<div class=\"panel-title\">" + t('mindnote.editor.style') + "</div>");
        var themeBox = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<ul class="panel-box theme-panel"></ul>').appendTo(themePanel);
        Object(lodash_es__WEBPACK_IMPORTED_MODULE_5__["default"])(Object(lodash_es__WEBPACK_IMPORTED_MODULE_8__["default"])(themes), function (key) {
            themeBox.append('<li class="' + key + '" data-th="' + key + '"></li>');
        });
        structBox.find('.' + this.definition.structure).addClass('active');
        themeBox.find('.' + this.definition.theme).addClass('active');
        var me = this;
        structBox.find('li').on('click', function () {
            if (!me.state.readonly) {
                var st = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).data('st');
                me.engine.setSetting('structure', st);
                structBox.find('.active').removeClass('active');
                jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).addClass('active');
                me.setStructure(st);
            }
        });
        themeBox.find('li').on('click', function () {
            if (!me.state.readonly) {
                var th = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).data('th');
                me.engine.setSetting('theme', th);
                themeBox.find('.active').removeClass('active');
                jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).addClass('active');
                me.setTheme(th);
            }
        });
        themePanel.append('<div class="arrow"></div>');
        themePanel.on('mousedown', function (e) {
            e.stopPropagation();
        });
        // 导出面板
        var exportPanel = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="mind-panel export-panel"><div class="arrow"></div></div>').appendTo(this.mindScreen);
        var butterflyIcon = new default_1(IconSet.BUTTERFLY, 24);
        var imageIcon = new default_1(IconSet.IMAGE, 24);
        exportPanel.append('<div class="export-select">' +
            ("<div class=\"export-item freemind\" title=\"" + t('mindnote.editor.freemind_tips') + "\">") +
            '<div class="mark">' +
            butterflyIcon.toString() +
            '</div>' +
            '<div class="title download-freemind">FreeMind</div>' +
            '</div>' +
            '<div class="export-item image">' +
            '<div class="mark">' +
            imageIcon.toString() +
            '</div>' +
            ("<div id=\"mind-download-image\" class=\"title download-image\">" + t('mindnote.editor.image') + "</div>") +
            '</div>' +
            '</div>');
        exportPanel.on('mousedown', function (e) {
            e.stopPropagation();
        });
        exportPanel.find('.image').on('click', function () {
            _this.exportImage();
        });
        exportPanel.find('.freemind').on('click', function () {
            var nodes;
            if (_this.rootId == null) {
                nodes = _this.definition.nodes;
            }
            else {
                var rootNode = _this.nodeMapping[_this.rootId].node;
                nodes = rootNode.children;
            }
            _this.minderExporter.exportFreeMind(nodes, _this.definition.structure);
        });
        // exportPanel.find('.freemind').tooltip();
    };
    /**
     * 执行导出图片
     */
    Minder.prototype.exportImage = function () {
        if (this.asyncDrawing) {
            // $.alert({
            // 	title: '请等待',
            // 	content: '您的思维导图仍在绘制中，请等待绘制完成后再进行导出。'
            // });
            return;
        }
        this.minderExporter.exportMindImage(this.zoom);
    };
    /**
     * 打开某个面板
     */
    Minder.prototype.showPanel = function (name) {
        var _this = this;
        this.hidePanel();
        this.mindScreen.find('.mind-menu').find('li[panel=' + name + ']').addClass('active');
        this.mindScreen.children('.mind-panel').hide();
        var panel = this.mindScreen.children('.' + name + '-panel').show();
        jquery__WEBPACK_IMPORTED_MODULE_0___default()(document).on('mousedown.mind-panel', function () {
            _this.hidePanel();
        });
        jquery__WEBPACK_IMPORTED_MODULE_0___default()('.download-freemind').text('FreeMind');
        jquery__WEBPACK_IMPORTED_MODULE_0___default()('#mind-download-image').text(t('mindnote.editor.image'));
        // 控制样式面板的高度
        if (name === 'style' && environment.isMobile) {
            // 窗口的可利用空间
            var windowSpace = (jquery__WEBPACK_IMPORTED_MODULE_0___default()(window).height() || 0) - 110;
            if (windowSpace > 565) {
                panel.height('auto');
            }
            else {
                panel.height(windowSpace - 20);
            }
        }
    };
    Minder.prototype.hidePanel = function () {
        this.mindScreen.children('.mind-panel').hide();
        jquery__WEBPACK_IMPORTED_MODULE_0___default()(document).off('mousedown.mind-panel');
        this.mindScreen.children('.mind-menu').find('.active').removeClass('active');
    };
    /**
     * 设置结构
     * @param sturct
     */
    Minder.prototype.setStructure = function (sturct) {
        this.definition.structure = sturct;
        this.draw();
    };
    Minder.prototype.setTheme = function (th) {
        this.definition.theme = th;
        var themeConfig = themes;
        this.currentTheme = themeConfig[this.definition.theme];
        this.draw(false);
        if (this.wm) {
            var color = ThemeToWatermarkColor(th);
            this.wm.update({ color: color });
        }
    };
    Minder.prototype.resetCanvas = function () {
        // 必须设置一个宽度，否则缩放后，外围的宽度，比mindMap实际宽度还小，会挤的变形
        this.mindMap.css({
            'width': this.mindMap.width() + 20,
            'top': this.mapMargin,
            'left': this.mapMargin
        });
        this.mindCanvas.css({
            width: this.mindMap.width() * this.zoom + this.mapMargin,
            height: this.mindMap.height() * this.zoom + this.mapMargin,
            'padding-top': this.mapMargin,
            'padding-left': this.mapMargin
        });
    };
    /**
     * 执行绘制
     * @param relocate 是否重新定位视图
     */
    Minder.prototype.draw = function (relocate) {
        var _this = this;
        if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_9__["default"])(relocate)) {
            relocate = true;
        }
        this.mindCanvas.attr('class', 'mind-canvas theme-' + this.definition.theme);
        // 添加一个背景图片，导出时直接使用
        jquery__WEBPACK_IMPORTED_MODULE_0___default()('#mind-bg-holder').remove();
        var bgHolder = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div id="mind-bg-holder"></div>').appendTo(this.mindScreen);
        bgHolder.data('color', this.currentTheme.bgColor);
        var backgroundImage = this.currentTheme.bgImage;
        if (backgroundImage) {
            var bgImg = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<img/>').appendTo(bgHolder);
            bgImg.attr('src', 'data:image/png;base64,' + backgroundImage);
            this.mindCanvas.css({
                'background-image': 'url(data:image/png;base64,' + backgroundImage + ')',
                'background-repeat': 'repeat'
            });
        }
        else {
            this.mindCanvas.css({
                'background-image': 'none'
            });
        }
        // 先设置到无限大
        this.mindCanvas.css({
            'width': 20000,
            'height': 20000,
            'background-color': this.currentTheme.bgColor
        });
        this.mindMap.css('width', 'auto');
        this.mindMap.empty();
        if (this.definition.structure && this.definition.structure === 'org') {
            this.mindMap.addClass('struct-org');
        }
        else {
            this.mindMap.removeClass('struct-org');
        }
        this.mindMap.css('transform', 'scale(' + this.zoom + ')');
        var partCenter = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="tp-part"></div>').appendTo(this.mindMap);
        // 先绘制中心节点
        var centralTopic = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="tp-container"><div class="tp-box"><div class="topic central"></div></div></div>');
        var topicEle = centralTopic.find('.topic');
        // 使用parseHTML创建元素，可以保证内部的动态内容不会被触发，如<img src=x onerror=alert(1)/>
        // parseHTML结果为原生DOM数组
        var centralTopicText = jquery__WEBPACK_IMPORTED_MODULE_0___default.a.parseHTML('<div class="topic-text root theme-' + this.definition.theme + '"></div>');
        centralTopicText = centralTopicText[0];
        var nodes;
        if (this.rootId == null) {
            nodes = this.definition.nodes;
            // 使用text赋值，避免xss
            centralTopicText.innerText = this.docName || this.state.getEditorProps().titlePlaceholder;
        }
        else {
            var rootNode = this.nodeMapping[this.rootId].node;
            nodes = rootNode.children;
            centralTopicText.innerHTML = rootNode.text;
            centralTopicText = jquery__WEBPACK_IMPORTED_MODULE_0___default()(centralTopicText);
            makeContentSafe(centralTopicText);
            topicEle.data('topic', this.rootId);
        }
        topicEle.append(centralTopicText);
        centralTopic.appendTo(partCenter);
        var struct = this.definition.structure;
        if (struct === 'default') {
            // 左右布局
            var totalCount_1 = 0;
            // 先数一下有多少个节点
            recursive(nodes, function () {
                totalCount_1++;
            });
            // 计算从哪个id开始，换到左边去
            var turnLeftFrom_1 = '';
            var overHalf_1 = false; // 是否已经超过了一半
            var currentIndex_1 = 0;
            recursive(nodes, function (node, parentNode) {
                currentIndex_1++;
                if (!overHalf_1 && (parentNode == null || parentNode.id === _this.rootId)) {
                    // 根节点
                    if (currentIndex_1 > Math.ceil(totalCount_1 / 2)) {
                        // 已经超过了一半，放到左边
                        turnLeftFrom_1 = node.id;
                        overHalf_1 = true;
                    }
                }
            });
            // 添加part
            var currentPart_1 = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="tp-part right"></div>').appendTo(this.mindMap);
            var partName_1 = 'right';
            recursive(nodes, function (node, parentNode) {
                if (node.id === turnLeftFrom_1) {
                    // 已经超过了一半，放到左边
                    currentPart_1 = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="tp-part left"></div>').prependTo(_this.mindMap);
                    partName_1 = 'left';
                }
                return _this.drawTopic(node, currentPart_1, partName_1);
            });
        }
        else if (struct === 'org') {
            partCenter.addClass('org-root');
            var currentPart_2 = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="org-part"></div>').appendTo(this.mindMap);
            var partName_2 = struct;
            recursive(nodes, function (node) {
                return _this.drawTopic(node, currentPart_2, partName_2);
            });
        }
        else {
            // 左布局 或者 右布局
            var currentPart_3;
            if (struct === 'right') {
                currentPart_3 = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="tp-part right"></div>').appendTo(this.mindMap);
            }
            else {
                currentPart_3 = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="tp-part left"></div>').prependTo(this.mindMap);
            }
            var partName_3 = struct;
            recursive(nodes, function (node) {
                return _this.drawTopic(node, currentPart_3, partName_3);
            });
        }
        this.resetCanvas();
        this.drawMainLinker();
        if (relocate) {
            this.locateMap();
        }
        // 定位之后，异步绘制子节点连线
        this.asyncDrawChildrenLinker(nodes);
    };
    /**
     * 绘制节点
     * @param topic
     */
    Minder.prototype.drawTopic = function (topic, part, partName) {
        var topicDom = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="tp-container" id="tp-' + topic.id + '"><div class="tp-box"><div class="topic"></div></div></div>');
        topicDom.addClass(partName);
        var target;
        var parentNode = this.nodeMapping[topic.id].parent;
        var className;
        if (parentNode == null || (this.rootId && this.rootId === parentNode.id)) {
            // 一级节点
            target = part;
            className = 'sub';
            topicDom.addClass('main-container').data('topic', topic.id);
        }
        else {
            var parentDom = this.mindMap.find('#tp-' + parentNode.id);
            target = parentDom.children('.tp-children');
            className = 'child';
            if (target.length === 0) {
                target = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="tp-children"></div>').appendTo(parentDom);
            }
        }
        var topicEle = topicDom.find('.topic');
        topicEle.data('topic', topic.id);
        var topicText = jquery__WEBPACK_IMPORTED_MODULE_0___default.a.parseHTML('<div class="topic-text theme-' + this.definition.theme + ' ' + className + '">' + topic.text + '</div>');
        topicText = jquery__WEBPACK_IMPORTED_MODULE_0___default()(topicText);
        makeContentSafe(topicText);
        topicEle.append(topicText);
        if (topic.note) {
            var icon = new default_1(IconSet.MENU, 14);
            var noteDom = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="topic-note">' + icon.toString() + '</div>');
            noteDom.data('topic', topic.id);
            noteDom.appendTo(topicText);
        }
        // 绘制图片
        if (topic.images && topic.images.length > 0) {
            var imageContainer_1 = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="attach-image-list"></div>');
            topicText.append(imageContainer_1);
            jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(topic.images, function (index, img) {
                var imgItem = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="attach-image-item"></div>');
                var imgItemWrapper = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="image-wrapper"></div>').appendTo(imgItem);
                var imgObj = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<img class="attach-img loading" uri="' + img.uri + '"/>');
                // 提前计算图片尺寸并预设值好，否则在图片未加载成功的时候，会影响高度的判断，从而影响布局
                var imageWidth = img.w || img.ow;
                if (imageWidth > 500) {
                    imageWidth = 500;
                }
                var imageHeight = Math.round(imageWidth / img.ow * img.oh);
                imgObj.css({
                    width: imageWidth,
                    height: imageHeight
                });
                imgItemWrapper.append(imgObj);
                imageContainer_1.append(imgItem);
                var loadingSpinner = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="image-spinner">' +
                    '<div class="spinner-text">' +
                    '<div class="loader"></div>' +
                    ("<div>" + t('mindnote.editor.image_loding') + "</div></div>") +
                    '</div>');
                loadingSpinner.css({
                    width: imageWidth,
                    height: imageHeight
                });
                imgItemWrapper.append(loadingSpinner);
                imgObj.on('load', function () {
                    jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).removeClass('loading');
                    loadingSpinner.remove();
                });
                imgObj.attr('src', img.uri);
            });
        }
        target.append(topicDom);
        if (topic.collapsed || topic.autoCollapsed) {
            topicDom.addClass('collapsed');
            return false;
        }
        return true;
    };
    /**
     * 缩放
     * @param changed 变化比例
     */
    Minder.prototype.zoomMap = function (changed) {
        var newZoom = this.zoom + changed;
        var aroundPoint = {
            x: (jquery__WEBPACK_IMPORTED_MODULE_0___default()(window).width() || 0) / 2,
            y: (jquery__WEBPACK_IMPORTED_MODULE_0___default()(window).height() || 0) / 2
        };
        var mapAroundPoint = {
            x: (this.mindScreen.scrollLeft() + aroundPoint.x - this.mapMargin) / this.zoom,
            y: (this.mindScreen.scrollTop() + aroundPoint.y - this.mapMargin) / this.zoom
        };
        this.setMapZoom(newZoom, mapAroundPoint, aroundPoint);
    };
    /**
     * 设置脑图的缩放值
     * @param newZoomScale 新的缩放值
     * @param mapAroundPoint 围绕的点
     * @param screenPoint 围绕的点
     */
    Minder.prototype.setMapZoom = function (newZoomScale, mapAroundPoint, screenPoint) {
        if (newZoomScale > 5) {
            newZoomScale = 5;
        }
        if (newZoomScale < 0.3) {
            newZoomScale = 0.3;
        }
        // 先设置到无限大
        this.mindCanvas.css({
            width: 20000,
            height: 20000
        });
        this.mindMap.css('width', 'auto');
        this.zoom = newZoomScale;
        if (!isMobile()) {
            var tipper_1 = jquery__WEBPACK_IMPORTED_MODULE_0___default()('#mind-zoom-tip');
            if (tipper_1.length === 0) {
                tipper_1 = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div id="mind-zoom-tip"></div>').appendTo('.mind-menu');
            }
            tipper_1.text(Math.round(this.zoom * 100) + '%');
            tipper_1.show();
            clearTimeout(this.zoomTipTimer);
            this.zoomTipTimer = setTimeout(function () {
                tipper_1.fadeOut(150);
            }, 1000);
        }
        this.mindMap.css('transform', 'scale(' + this.zoom + ')');
        this.resetCanvas();
        this.mindScreen.scrollLeft(mapAroundPoint.x * this.zoom + this.mapMargin - screenPoint.x);
        this.mindScreen.scrollTop(mapAroundPoint.y * this.zoom + this.mapMargin - screenPoint.y);
    };
    /**
     * 绘制主的连接线
     */
    Minder.prototype.drawMainLinker = function () {
        var _this = this;
        jquery__WEBPACK_IMPORTED_MODULE_0___default()('.main-linker').remove();
        var nodes;
        if (this.rootId == null) {
            nodes = this.definition.nodes;
        }
        else {
            var rootNode = this.nodeMapping[this.rootId].node;
            nodes = rootNode.children;
        }
        if (!nodes || nodes.length === 0) {
            return;
        }
        var centralTopic = jquery__WEBPACK_IMPORTED_MODULE_0___default()('.topic.central');
        var centralPos = centralTopic.position();
        var center = {
            x: centralPos.left / this.zoom + (centralTopic.outerWidth() || 0) / 2
        };
        if (this.definition.structure === 'org') {
            // 组织机构，从底部连
            center.y = centralPos.top / this.zoom + (centralTopic.outerHeight() || 0);
        }
        else {
            center.y = centralPos.top / this.zoom + (centralTopic.outerHeight() || 0) / 2;
        }
        // 绘制节点的连线
        var drawNodeLinker = function (node) {
            var topicContainer = jquery__WEBPACK_IMPORTED_MODULE_0___default()('#tp-' + node.id);
            if (topicContainer.length === 0) {
                return true;
            }
            var linkerBox = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="linker-container main-linker"></div>');
            var topicBox = topicContainer.children('.tp-box');
            var topicPos = topicBox.position();
            if (_this.definition.structure === 'org') {
                // 绘制组织结构布局的折线
                // 计算主题相对于画图中心的坐标
                var pos = {
                    x: topicPos.left / _this.zoom + (topicBox.width() || 0) / 2 - center.x,
                    y: topicPos.top / _this.zoom - center.y
                };
                var linker = {
                    y: 0,
                    h: pos.y
                };
                var lineBeginX = void 0;
                var lineEndX = void 0;
                if (pos.x > 0) {
                    linker.x = 0;
                    linker.w = pos.x;
                    lineBeginX = 0;
                    lineEndX = linker.w;
                }
                else {
                    linker.x = pos.x;
                    linker.w = Math.abs(pos.x);
                    lineBeginX = linker.w;
                    lineEndX = 0;
                }
                var domWidth = linker.w > 2 ? linker.w : 2;
                var domHeight = linker.h > 2 ? linker.h : 2;
                linkerBox.css({
                    left: center.x + linker.x + 1,
                    top: center.y + linker.y,
                    width: domWidth,
                    height: domHeight
                });
                linkerBox.appendTo(_this.mindMap);
                var pathStr = 'M' + lineBeginX + ',0' +
                    ' L' + lineBeginX + ',' + linker.h / 2 +
                    ' L' + lineEndX + ',' + linker.h / 2 +
                    ' L' + lineEndX + ',' + linker.h;
                var svg = '<svg xmlns="http://www.w3.org/2000/svg" width="' + domWidth + '" height="' + domHeight
                    + '" '
                    + 'stroke="' + _this.currentTheme.lineColor + '" '
                    + 'stroke-width="2px" '
                    + 'fill="none" '
                    + 'version="1.1">'
                    + '<g>'
                    + '<path d="' + pathStr + '"></path>'
                    + '</g>'
                    + '</svg>';
                linkerBox.append(svg).attr('path-d', pathStr);
            }
            else {
                // 计算主题相对于画图中心的坐标
                var pos = {
                    x: topicPos.left / _this.zoom - center.x,
                    y: topicPos.top / _this.zoom - center.y + (topicBox.outerHeight() || 0) / 2
                };
                var linker = {};
                if (pos.x > 0) {
                    linker.x = 0;
                    linker.w = pos.x;
                }
                else {
                    linker.x = pos.x + (topicBox.width() || 0);
                    linker.w = Math.abs(pos.x + (topicBox.width() || 0));
                }
                linker.h = Math.abs(pos.y);
                // 确定连接线画布的y坐标，和绘制路径中起点和终点的y坐标
                var path = {};
                if (pos.y > 0) {
                    linker.y = 0;
                    if (pos.x > 0) {
                        path.y1 = 0;
                        path.y2 = linker.h;
                    }
                    else {
                        path.y1 = linker.h;
                        path.y2 = 0;
                    }
                }
                else {
                    linker.y = pos.y;
                    if (pos.x > 0) {
                        path.y1 = linker.h;
                        path.y2 = 0;
                    }
                    else {
                        path.y1 = 0;
                        path.y2 = linker.h;
                    }
                }
                var domWidth = linker.w > 2 ? linker.w : 2;
                var domHeight = linker.h > 2 ? linker.h : 2;
                linkerBox.css({
                    left: center.x + linker.x,
                    top: center.y + linker.y - 1,
                    width: domWidth,
                    height: domHeight
                });
                linkerBox.appendTo(_this.mindMap);
                var pathStr = 'M0,' + path.y1;
                if (pos.x > 0) {
                    pathStr += ' C0' + ',' + linker.h / 2 + ' ' +
                        linker.w / 2 + ',' + path.y2 + ' ' +
                        linker.w + ',' + path.y2;
                }
                else {
                    pathStr += ' C' + linker.w / 2 + ',' + path.y1 + ' ' +
                        linker.w + ',' + linker.h / 2 + ' ' +
                        linker.w + ',' + path.y2;
                }
                var svg = '<svg  xmlns="http://www.w3.org/2000/svg" width="' + domWidth + '" height="' + domHeight
                    + '" '
                    + 'stroke="' + _this.currentTheme.lineColor + '" '
                    + 'stroke-width="2px" '
                    + 'fill="none" '
                    + 'version="1.1">'
                    + '<g>'
                    + '<path d="' + pathStr + '"></path>'
                    + '</g>'
                    + '</svg>';
                linkerBox.append(svg).attr('path-d', pathStr);
            }
        };
        jquery__WEBPACK_IMPORTED_MODULE_0___default.a.each(nodes, function (index, node) {
            drawNodeLinker(node);
        });
    };
    Minder.prototype.clearSyncChildrenLinker = function () {
        if (environment.isMobile) {
            clearTimeout(this.asyncChildrenLinker);
        }
        else {
            clearImmediate(this.asyncChildrenLinker);
        }
    };
    /**
     * 异步绘制子节点的连线
     */
    Minder.prototype.asyncDrawChildrenLinker = function (nodes) {
        var _this = this;
        this.clearSyncChildrenLinker();
        if (!nodes || nodes.length === 0) {
            return;
        }
        var rootOffset = jquery__WEBPACK_IMPORTED_MODULE_0___default()('.topic.central').offset();
        // 先排列子节点的绘制顺序，视图区域中的优先绘制
        var ranged = [];
        var index = nodes.length - 1;
        while (index >= 0) {
            var node = nodes[index];
            var nodeItem = this.mindMap.find('#tp-' + node.id);
            var offset = nodeItem.offset();
            // 勾股定理，计算距离
            node.distance = Math.sqrt(Math.pow(offset.left - rootOffset.left, 2) + Math.pow(offset.top - rootOffset.top, 2));
            ranged.push(node);
            index--;
        }
        ranged.sort(function (a, b) {
            return a.distance - b.distance;
        });
        // 排列好，开始异步绘制
        var drawIndex = 0;
        this.asyncDrawing = true;
        var doAsyncDraw = function () {
            if (_this.mindMap == null) {
                // 当mindMap为null时，说明已经退出了，不在继续异步绘制
                return false;
            }
            // 每一步画10次
            var stepMax = drawIndex + 10;
            for (var stepIndex = drawIndex; stepIndex < ranged.length && stepIndex < stepMax; stepIndex++) {
                var drawNode = ranged[drawIndex];
                _this.drawChildrenLinker(drawNode);
                drawIndex++;
            }
            if (drawIndex < ranged.length) {
                if (environment.isMobile) {
                    _this.asyncChildrenLinker = setTimeout(function () {
                        doAsyncDraw();
                    }, 0.5);
                }
                else {
                    _this.asyncChildrenLinker = setImmediate(function () {
                        doAsyncDraw();
                    });
                }
                return true;
            }
            else {
                // 完成异步绘制
                _this.asyncDrawing = false;
                return false;
            }
        };
        doAsyncDraw();
    };
    /**
     * 绘制一个子节点的连线
     * @param topic
     */
    Minder.prototype.drawChildrenLinker = function (topic) {
        if (!topic.children || topic.children.length === 0) {
            return;
        }
        var container = jquery__WEBPACK_IMPORTED_MODULE_0___default()('#tp-' + topic.id);
        var topicBox = container.children('.tp-box');
        var topicDom = topicBox.children('.topic');
        var childrenBox = container.children('.tp-children');
        // 删除已有的，重新创建
        childrenBox.children('.linker-container').remove();
        topicDom.children('.tp-expand-box').remove();
        // 添加收缩、展开的图标
        var expandBox = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="tp-expand-box"><div class="tp-expand-ico" data-topic="' + topic.id + '"></div></div>').appendTo(topicDom);
        var fromY;
        var parentNode = this.nodeMapping[topic.id].parent;
        if (parentNode == null || (this.rootId && this.rootId === parentNode.id)) {
            // 如果是分支主题
            fromY = (childrenBox.height() || 0) / 2;
            if (this.definition.structure === 'org') {
                expandBox.css({
                    top: (topicBox.height() || 0) + 6,
                    left: 12
                });
            }
            else {
                expandBox.css('top', (topicBox.height() || 0) / 2 - 1);
            }
        }
        else {
            // 子主题，在下边
            fromY = (childrenBox.height() || 0) / 2 + (topicBox.height() || 0) / 2 - 4;
            expandBox.css('top', (topicBox.height() || 0) - 5);
        }
        expandBox.css('background', this.currentTheme.lineColor);
        var me = this;
        expandBox.children().on('click', function () {
            me.toggleTopic(jquery__WEBPACK_IMPORTED_MODULE_0___default()(this));
        });
        if (topic.collapsed || topic.autoCollapsed) {
            return;
        }
        if (this.definition.structure === 'org') {
            fromY = 0;
        }
        for (var i = 0; i < topic.children.length; i++) {
            // 开始绘制与一个子元素之间的连线
            var child = topic.children[i];
            var cContainer = jquery__WEBPACK_IMPORTED_MODULE_0___default()('#tp-' + child.id);
            var cBox = cContainer.children('.tp-box');
            var linkerBox = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="linker-container children-linker"></div>').appendTo(childrenBox);
            var toY = cBox.position().top / this.zoom + (cBox.height() || 0) - 4;
            var radiusSize = 8; // 圆角的尺寸
            // 元素的宽高
            var linkerHeight = Math.abs(toY - fromY);
            linkerHeight = linkerHeight > 2 ? linkerHeight : 2;
            var topicWidth = cBox.width() || 0;
            var linkerWidth = topicWidth + radiusSize;
            linkerWidth = linkerWidth > 2 ? linkerWidth : 2;
            // 连线元素的Y坐标
            var linkerY = Math.min(fromY, toY);
            linkerBox.css('top', linkerY);
            // 绘制一个曲线
            var beginY = fromY - linkerY;
            var endY = toY - linkerY;
            var beginX = 0;
            var endX = linkerWidth;
            if (container.hasClass('left')) {
                // 在左边
                beginX = linkerWidth;
                endX = 0;
            }
            var pathStr = 'M' + beginX + ',' + beginY;
            if (Math.abs(toY - fromY) >= radiusSize) {
                var lineEndY = void 0;
                if (toY < fromY) {
                    // 终点在起点上方，子主题在父主题上方，曲线方向改变
                    lineEndY = endY + radiusSize;
                }
                else {
                    lineEndY = endY - radiusSize;
                }
                pathStr += ' L' + beginX + ',' + lineEndY;
            }
            var cornerEndX = endX < beginX ? beginX - radiusSize : beginX + radiusSize;
            pathStr += ' Q' + beginX + ',' + endY + ' ' + cornerEndX + ',' + endY;
            pathStr += ' L' + endX + ',' + endY;
            var svg = '<svg xmlns="http://www.w3.org/2000/svg" width="' + linkerWidth + '" height="' + linkerHeight
                + '" '
                + 'stroke="' + this.currentTheme.lineColor + '" '
                + 'stroke-width="2px" '
                + 'fill="none" '
                + 'version="1.1">'
                + '<g>'
                + '<path d="' + pathStr + '"></path>'
                + '</g>'
                + '</svg>';
            linkerBox.append(svg).attr('path-d', pathStr);
            // 绘制下一级
            this.drawChildrenLinker(child);
        }
    };
    /**
     * 设置脑图位置
     */
    Minder.prototype.locateMap = function () {
        var win = jquery__WEBPACK_IMPORTED_MODULE_0___default()(window);
        var root = jquery__WEBPACK_IMPORTED_MODULE_0___default()('.topic.central');
        var rootPos = root.position();
        var mapWidth = this.mindMap.width() * this.zoom;
        var mapHeight = this.mindMap.height() * this.zoom;
        if (mapWidth < win.width()) {
            // 屏幕可以放下，让整张图在屏幕中间
            this.mindScreen.scrollLeft(mapWidth / 2 + this.mapMargin - win.width() / 2);
        }
        else {
            var rootWidth = (root.outerWidth() || 0) * this.zoom;
            if (this.definition.structure === 'left') {
                this.mindScreen.scrollLeft(rootPos.left + rootWidth + this.mapMargin - win.width() + 80);
            }
            else if (this.definition.structure === 'right') {
                this.mindScreen.scrollLeft(rootPos.left + this.mapMargin - 80);
            }
            else {
                this.mindScreen.scrollLeft(rootPos.left + rootWidth / 2 + this.mapMargin - win.width() / 2);
            }
        }
        if (mapHeight < win.height()) {
            // 屏幕可以放下
            this.mindScreen.scrollTop(mapHeight / 2 + this.mapMargin - win.height() / 2);
        }
        else {
            var rootHeight = (root.outerHeight() || 0) * this.zoom;
            if (this.definition.structure === 'org') {
                this.mindScreen.scrollTop(rootPos.top + this.mapMargin - 80);
            }
            else {
                this.mindScreen.scrollTop(rootPos.top + rootHeight / 2 + this.mapMargin - win.height() / 2);
            }
        }
    };
    /**
     * 切换主题的展开/收缩
     * @param expandBtn
     */
    Minder.prototype.toggleTopic = function (expandBtn) {
        var _this = this;
        // 重新设置为很大，不影响绘制
        this.mindCanvas.css({
            width: 20000,
            height: 20000
        });
        this.mindMap.css('width', 'auto');
        // 找到主分支主题，从它开始重新绘制连线
        var mainContainer = expandBtn.parents('.main-container');
        var mainId = mainContainer.data('topic');
        var mainTopic = this.nodeMapping[mainId].node;
        var currentId = expandBtn.data('topic');
        var currentTopic = this.nodeMapping[currentId].node;
        var currentCollapsed = (currentTopic.collapsed || currentTopic.autoCollapsed);
        currentTopic.collapsed = !currentCollapsed;
        delete currentTopic.autoCollapsed;
        var topicContainer = jquery__WEBPACK_IMPORTED_MODULE_0___default()('#tp-' + currentId);
        var topicBox = topicContainer.children('.tp-box');
        // 记录当时的位移情况
        var originalBoxOffset = topicBox.offset();
        if (topicContainer.children('.tp-children').length === 0) {
            var part_1 = 'org';
            if (topicContainer.hasClass('left')) {
                part_1 = 'left';
            }
            else if (topicContainer.hasClass('right')) {
                part_1 = 'right';
            }
            recursive(currentTopic.children, function (topic) {
                return _this.drawTopic(topic, null, part_1);
            });
        }
        topicContainer.toggleClass('collapsed');
        // 重新设置尺寸
        this.resetCanvas();
        this.drawMainLinker();
        this.drawChildrenLinker(mainTopic);
        var newBoxOffset = topicBox.offset();
        var newBoxPos = {
            left: newBoxOffset.left + this.mindScreen.scrollLeft(),
            top: newBoxOffset.top + this.mindScreen.scrollTop()
        };
        // 根据新的情况，重新设置位置
        this.mindScreen.scrollLeft(newBoxPos.left - originalBoxOffset.left);
        this.mindScreen.scrollTop(newBoxPos.top - originalBoxOffset.top);
    };
    /**
     * 初始化操作
     */
    Minder.prototype.initOperate = function () {
        // 初始化拖动，这里只试用PC端，因为移动端默认就是拖动调整位置
        var me = this;
        this.mindScreen.on('mousedown', function (downE) {
            var downPosEvent = downE;
            if (downE.originalEvent.touches) {
                downPosEvent = downE.originalEvent.touches[0];
            }
            jquery__WEBPACK_IMPORTED_MODULE_0___default()('.topic-note-menu').remove();
            // 初始时的位置
            var originalLeft = me.mindScreen.scrollLeft();
            var originalTop = me.mindScreen.scrollTop();
            jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).on('mousemove', function (moveE) {
                var movePosEvent = moveE;
                var originalEvent = moveE.originalEvent;
                if (originalEvent.touches) {
                    movePosEvent = originalEvent.touches[0];
                }
                var offset = {
                    left: movePosEvent.pageX - downPosEvent.pageX,
                    top: movePosEvent.pageY - downPosEvent.pageY
                };
                me.mindScreen.scrollLeft(originalLeft - offset.left);
                me.mindScreen.scrollTop(originalTop - offset.top);
            });
            jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).on('mouseup', function () {
                jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).off('mouseup').off('mousemove');
            });
        });
        this.mindScreen.on('click', function () {
            jquery__WEBPACK_IMPORTED_MODULE_0___default()('.topic-note-menu').remove();
        });
        // 点击主题进行钻取
        this.mindScreen.on(environment.downEvent, '.topic-text', function (downE) {
            var downPosEvent = downE;
            if (downE.originalEvent.touches) {
                downPosEvent = downE.originalEvent.touches[0];
            }
            var target = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            target.off().on(environment.upEvent, function (upE) {
                var upPosEvent = upE;
                var originalEvent = upE.originalEvent;
                if (originalEvent.changedTouches) {
                    upPosEvent = originalEvent.changedTouches[0];
                }
                if (Math.abs(upPosEvent.pageX - downPosEvent.pageX) > 10
                    || Math.abs(upPosEvent.pageY - downPosEvent.pageY) > 10) {
                    // 发生了拖动，不处理
                    return;
                }
                var topicId = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).parent().data('topic');
                me.drillTopic(topicId);
            });
            me.mindScreen.on(environment.upEvent, function () {
                target.off(environment.upEvent);
            });
        });
        this.mindScreen.on(environment.downEvent, '.topic-note', function (downE) {
            downE.stopPropagation();
        });
        // 点击显示备注
        this.mindScreen.on('click', '.topic-note', function (downE) {
            downE.stopPropagation();
            var target = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            var topicId = target.data('topic');
            var topic = me.nodeMapping[topicId].node;
            jquery__WEBPACK_IMPORTED_MODULE_0___default()('.topic-note-menu').remove();
            var menu = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="topic-note-menu"></div>').appendTo(me.mindMap);
            jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="arrow"></div>').appendTo(menu);
            var noteContent = jquery__WEBPACK_IMPORTED_MODULE_0___default.a.parseHTML('<div class="note-text">' + topic.note + '</div>');
            noteContent = jquery__WEBPACK_IMPORTED_MODULE_0___default()(noteContent);
            makeContentSafe(noteContent);
            menu.append(noteContent);
            var targetOffset = target.offset();
            menu.css({
                left: targetOffset.left / me.zoom - me.mindMap.offset().left / me.zoom - (menu.outerWidth() || 0) / 2 + 9,
                top: targetOffset.top / me.zoom - me.mindMap.offset().top / me.zoom + 30
            });
            menu.on(environment.downEvent, function (menuDownE) {
                menuDownE.stopPropagation();
            });
        });
        // 点击链接
        this.mindScreen.on(environment.downEvent, '.content-link', function (downE) {
            if (me.state.getEditorProps().env !== MindNoteEnvironment.PC) {
                downE.stopPropagation();
            }
        });
        this.mindScreen.on('click', '.content-link', function (downE) {
            if (me.state.getEditorProps().env !== MindNoteEnvironment.PC) {
                downE.stopPropagation();
                downE.preventDefault();
                var href = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).attr('href');
                me.eventSource.trigger(SourceEvent.LINK_OPEN, href);
            }
        });
        // 移动端双指缩放
        this.mindScreen.on('touchstart', function (e) {
            var touches = e.originalEvent.touches;
            if (touches.length === 2) {
                e.preventDefault();
                // 两个手指头
                var beginZoom_1 = me.zoom;
                var begin1 = { x: touches[0].pageX, y: touches[0].pageY };
                var begin2 = { x: touches[1].pageX, y: touches[1].pageY };
                var beginDistance_1 = me.measureDistance(begin1, begin2);
                var screenPoint = {
                    x: (begin1.x + begin2.x) / 2,
                    y: (begin1.y + begin2.y) / 2
                };
                var mapAroundPoint_1 = {
                    x: (me.mindScreen.scrollLeft() + screenPoint.x - me.mapMargin) / beginZoom_1,
                    y: (me.mindScreen.scrollTop() + screenPoint.y - me.mapMargin) / beginZoom_1
                };
                me.mindScreen.on('touchmove.scale', function (moveE) {
                    var moveTouches = moveE.originalEvent.touches;
                    var move1 = { x: moveTouches[0].pageX, y: moveTouches[0].pageY };
                    var move2 = { x: moveTouches[1].pageX, y: moveTouches[1].pageY };
                    var moveDistance = me.measureDistance(move1, move2);
                    var newZoomScale = moveDistance / beginDistance_1 * beginZoom_1;
                    var touchMovePoint = {
                        x: (move1.x + move2.x) / 2,
                        y: (move1.y + move2.y) / 2
                    };
                    me.setMapZoom(newZoomScale, mapAroundPoint_1, touchMovePoint);
                });
                me.mindScreen.on('touchend.scale', function () {
                    me.mindScreen.off('touchmove.scale').off('touchend.scale');
                });
            }
        });
    };
    /**
     * 测量两个点的距离
     * @param p1
     * @param p2
     * @returns {number}
     */
    Minder.prototype.measureDistance = function (p1, p2) {
        var h = p2.y - p1.y;
        var w = p2.x - p1.x;
        return Math.sqrt(Math.pow(h, 2) + Math.pow(w, 2));
    };
    Minder.prototype.drillTopic = function (topicId) {
        if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_9__["default"])(topicId)) {
            topicId = null;
        }
        if (topicId !== this.rootId) {
            if (this.isTooLarge(topicId, 'drill')) {
                return;
            }
            this.rootId = topicId;
            this.draw();
            this.mindMap.hide();
            this.mindMap.fadeIn();
            this.refreshDir();
        }
    };
    /**
     * 判断思维导图是否太大
     */
    Minder.prototype.isTooLarge = function (viewRootId, enterWay) {
        var viewNodes = this.definition.nodes;
        if (viewRootId) {
            var rootMapping = this.nodeMapping[viewRootId];
            if (rootMapping) {
                // 当前打开某个分支节点，重新开始计数
                viewNodes = [rootMapping.node];
            }
        }
        var autoCollapseCount = environment.isMobile ? 100 : 800;
        var maxCount = environment.isMobile ? 260 : 1500;
        var nodeCount = 0;
        recursive(viewNodes, function (node) {
            nodeCount++;
            if (node.collapsed) {
                return false;
            }
        });
        function autoCollapseNodes(collapseByLevel) {
            nodeCount = 0;
            recursive(viewNodes, function (node) {
                node.autoCollapsed = false;
            });
            recursive(viewNodes, function (node, parent, index, parentIndex, level) {
                nodeCount++;
                if (node.collapsed) {
                    return false;
                }
                if (level === collapseByLevel) {
                    node.autoCollapsed = true;
                    return false;
                }
            });
        }
        this.subTopicAutoCollapsed = false;
        // 开始自动收缩
        // 先收缩第三级
        if (nodeCount > autoCollapseCount) {
            autoCollapseNodes(2);
            this.subTopicAutoCollapsed = true;
        }
        // 再收缩第二级
        if (nodeCount > autoCollapseCount) {
            autoCollapseNodes(1);
        }
        // 再收缩第一级
        if (nodeCount > autoCollapseCount) {
            autoCollapseNodes(0);
        }
        if (nodeCount > maxCount) {
            // 文档太大，不能打开
            // let tipContent;
            // if (enterWay === 'drill') {
            // 	tipContent = '所选分支主题下内容太多，无法浏览思维导图，';
            // } else {
            // 	tipContent = '此文档主题条目太多，无法浏览思维导图，';
            // }
            // $.alert({
            // 	title: '无法查看思维导图',
            // 	content: '<div style="max-width: 340px;">' + tipContent +
            // 	'您可以：<div>1. 折叠不重要的主题</div><div>2. 点击某一子主题，进入主题后，导出相应的主题</div>' +
            // 	'<div style="color: #777;margin-top: 10px;">思维导图最多能显示' + maxCount + '条主题。</div>' +
            // 	'</div>'
            // });
            return true;
        }
        return false;
    };
    /**
     * 刷新路径
     */
    Minder.prototype.refreshDir = function () {
        var dirDom = this.mindScreen.find('.mind-dir');
        if (dirDom.length === 0) {
            dirDom = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="mind-dir"></div>').appendTo(this.mindScreen);
        }
        if (!this.rootId) {
            dirDom.hide();
            return;
        }
        var dir = [];
        var currentNodeId = this.rootId;
        if (currentNodeId) {
            while (true) {
                // 层级向上查找，并往数组后边push
                var parentNode = this.nodeMapping[currentNodeId].parent;
                if (parentNode == null) {
                    break;
                }
                dir.push(parentNode);
                currentNodeId = parentNode.id;
            }
            dir.reverse();
        }
        dirDom.empty().show();
        var me = this;
        if (environment.isMobile) {
            dirDom.css('top', 20 + this.statusBarSpacing);
            var backId_1 = null;
            if (dir.length > 0) {
                var previous = dir[dir.length - 1];
                backId_1 = previous.id;
            }
            var backIcon = new default_1(IconSet.CHEVRON_LEFT, 14);
            var btn = jquery__WEBPACK_IMPORTED_MODULE_0___default()("<div class=\"back-btn\">" + backIcon.toString() + t('mindnote.editor.up_level') + "</div>").appendTo(dirDom);
            btn.on('click', function () {
                me.drillTopic(backId_1);
            });
        }
        else {
            var rootDir = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="item"><div class="dir-text"></div></div>').appendTo(dirDom);
            rootDir.find('.dir-text').text(me.docName || this.state.getEditorProps().titlePlaceholder);
            for (var i = 0; i < dir.length; i++) {
                var item = dir[i];
                var dirItem = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="item"><div class="dir-text">' + htmlToText(item.text) + '</div></div>').appendTo(dirDom);
                dirItem.data('node-id', item.id);
            }
            dirDom.off().on('click', '.item', function () {
                var item = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
                var topicId = item.data('node-id');
                me.drillTopic(topicId);
            });
        }
        dirDom.off(environment.downEvent).on(environment.downEvent, function (downE) {
            downE.stopPropagation();
        });
    };
    return Minder;
}());

var DemoPlayer = /** @class */ (function () {
    function DemoPlayer(nodePainter) {
        /**
         * 是否已经进入了演示模式
         */
        this.opened = false;
        this.rootId = null;
        this.zoom = 1;
        this.fullscreenEvent = 'webkitfullscreenchange msfullscreenchange mozfullscreenchange fullscreenchange';
        /**
         * 演示模式水印
         */
        this.wm = null;
        /**
         * 当前的亮度
         */
        this.mode = 'light';
        this.nodePainter = nodePainter;
    }
    /**
     * 进入全屏
     * @param element
     */
    DemoPlayer.prototype.launchFullscreen = function () {
        var element = this.screenElement[0];
        var requestFullscreen = element.requestFullscreen
            || element.mozRequestFullScreen
            || element.webkitRequestFullscreen
            || element.msRequestFullscreen;
        if (requestFullscreen) {
            requestFullscreen.call(element);
            this.opened = true;
        }
    };
    /**
     * 退出全屏
     */
    DemoPlayer.prototype.exitFullscreen = function () {
        var doc = document;
        var exitFullscreen = doc.exitFullscreen
            || doc.mozCancelFullScreen
            || doc.webkitExitFullscreen
            || doc.msExitFullscreen;
        if (exitFullscreen) {
            exitFullscreen.call(doc);
            this.opened = false;
        }
    };
    DemoPlayer.prototype.refreshView = function () {
        var _this = this;
        this.treeElement.empty();
        var nodes;
        if (this.rootId == null) {
            nodes = this.definition.nodes;
        }
        else {
            var rootNode = this.nodeMapping[this.rootId].node;
            nodes = [rootNode];
        }
        if (nodes && nodes.length > 0) {
            // 绘制节点
            recursive(nodes, function (node) {
                _this.renderNode(node);
            });
        }
        this.refreshDir();
        this.initOperate();
    };
    DemoPlayer.prototype.renderNode = function (node) {
        var isRoot = node.id === this.rootId;
        var nodeDom = this.nodePainter.render(node, true, isRoot);
        var target;
        var parentNode = this.nodeMapping[node.id].parent;
        if (parentNode == null || (this.rootId && this.rootId === node.id)) {
            target = this.treeElement;
            if (node.id === this.rootId) {
                nodeDom.addClass('root-node');
            }
        }
        else {
            var parentDom = this.treeElement.find('#' + parentNode.id);
            target = parentDom.children('.children');
            if (target.length === 0) {
                target = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<div class="children"></div>').appendTo(parentDom);
            }
        }
        target.append(nodeDom);
    };
    /**
     * 刷新路径
     */
    DemoPlayer.prototype.refreshDir = function () {
        var dirDom = this.screenElement.find('.mindnote-dir');
        if (dirDom.length === 0) {
            return;
        }
        if (!this.rootId) {
            dirDom.hide();
            return;
        }
        var dir = [];
        var currentNodeId = this.rootId;
        if (currentNodeId) {
            while (true) {
                // 层级向上查找，并往数组后边push
                var parentNode = this.nodeMapping[currentNodeId].parent;
                if (parentNode == null) {
                    break;
                }
                dir.push(parentNode);
                currentNodeId = parentNode.id;
            }
            dir.reverse();
        }
        dirDom.empty().show().append("<span class=\"item\">" + t('mindnote.editor.home') + "</span><span class=\"arrow\"></span>");
        for (var i = 0; i < dir.length; i++) {
            var item = dir[i];
            var dirItem = jquery__WEBPACK_IMPORTED_MODULE_0___default()('<span class="item">' + htmlToText(item.text) + '</span>').appendTo(dirDom);
            dirItem.data('node-id', item.id);
            dirDom.append('<span class="arrow"></span>');
        }
        var me = this;
        dirDom.off().on('click', '.item', function () {
            var item = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            var nodeId = item.data('node-id');
            me.rootId = nodeId;
            me.refreshView();
        });
    };
    /**
     * 绑定一些事件
     */
    DemoPlayer.prototype.initOperate = function () {
        var me = this;
        this.treeElement.find('.bullet').off().on('click', function () {
            // 钻取
            var nodeId = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).data('id');
            me.rootId = nodeId;
            me.refreshView();
        });
        var nodeList = this.treeElement.find('.content-wrapper');
        // 菜单
        nodeList.off().on('click', '.toggle', function () {
            var wrapper = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this).parent();
            var container = wrapper.parent();
            container.toggleClass('collapsed');
        });
    };
    /**
     * 缩放
     * @param changed 变化比例
     */
    DemoPlayer.prototype.zoomDocument = function (changed) {
        if (this.zoom >= 3 && changed > 0) {
            return;
        }
        if (this.zoom <= 0.6 && changed < 0) {
            return;
        }
        this.zoom += changed;
        this.zoom = Math.round(this.zoom * 10) / 10;
        var demoWrapper = this.screenElement.find('.demo-wrapper');
        if (isFirefox()) {
            demoWrapper.css('transform', 'scale(' + this.zoom + ')');
        }
        else {
            demoWrapper.css('zoom', this.zoom);
        }
    };
    /**
     * 设置文档的缩放值
     */
    DemoPlayer.prototype.setZoomScale = function () {
        var demoWrapper = this.screenElement.find('.demo-wrapper');
        if (isFirefox()) {
            demoWrapper.css('transform', 'scale(' + this.zoom + ')');
        }
        else {
            demoWrapper.css('zoom', this.zoom);
        }
    };
    /**
     * 初始化菜单操作
     */
    DemoPlayer.prototype.resetMenu = function () {
        var menu = this.screenElement.find('.demo-menu');
        if (menu.length === 0) {
            return;
        }
        var nightModeClass = 'night-mode';
        if (this.screenElement.hasClass(nightModeClass)) {
            var sunIcon = new default_1(IconSet.SUN, 20);
            menu.find('.demo-mode').html(sunIcon.toString());
        }
        else {
            var moonIcon = new default_1(IconSet.MOON, 20);
            menu.find('.demo-mode').html(moonIcon.toString());
        }
        var me = this;
        menu.find('li').off();
        menu.find('.demo-mode').on('click', function () {
            var btn = jquery__WEBPACK_IMPORTED_MODULE_0___default()(this);
            me.screenElement.toggleClass(nightModeClass);
            if (me.screenElement.hasClass(nightModeClass)) {
                var sunIcon = new default_1(IconSet.SUN, 20);
                btn.html(sunIcon.toString());
                this.mode = 'night';
            }
            else {
                var moonIcon = new default_1(IconSet.MOON, 20);
                btn.html(moonIcon.toString());
                this.mode = 'light';
            }
            /* 更新水印的模式 */
            if (me.wm) {
                var color = this.mode === 'light' ? WatermarkColor.LIGHT : WatermarkColor.DARK;
                me.wm.update({ color: color });
            }
        });
        menu.find('.demo-zoomin').on('click', function () {
            me.zoomDocument(0.2);
        });
        menu.find('.demo-zoomout').on('click', function () {
            me.zoomDocument(-0.2);
            me.screenElement.find('.demo-wrapper').css('zoom', me.zoom);
        });
        menu.find('.demo-exit').on('click', function () {
            me.exitFullscreen();
        });
    };
    /**
     * 开始播放
     */
    DemoPlayer.prototype.play = function (def, screenEle, name, rId, watermark) {
        // 已经打开了
        if (this.opened) {
            return;
        }
        /* 若需要显示水印，且没有初始化，则初始化实例 */
        if (watermark && !this.wm) {
            var color = this.mode === 'light' ? WatermarkColor.LIGHT : WatermarkColor.DARK;
            this.wm = new Watermark('mindnote-demo-watermark', watermark, {
                color: color
            });
            /* 若无水印，且组件未销毁 */
        }
        else if (!watermark && this.wm) {
            this.wm.destroy();
        }
        this.zoom = 1.5;
        this.rootId = rId;
        var eventName = 'keydown.demo';
        jquery__WEBPACK_IMPORTED_MODULE_0___default()(document).off(eventName).on(eventName, function (e) {
            // 阻止ctrl + [
            if (e.keyCode === 219) {
                e.preventDefault();
            }
        });
        var me = this;
        jquery__WEBPACK_IMPORTED_MODULE_0___default()(document).off(me.fullscreenEvent).on(me.fullscreenEvent, function () {
            me.screenElement.toggle();
            if (!me.screenElement.is(':visible')) {
                // 退出了全屏
                me.opened = false;
                me.treeElement.empty();
                jquery__WEBPACK_IMPORTED_MODULE_0___default()(document).off(eventName);
                me.screenElement.find('.opening').remove();
                jquery__WEBPACK_IMPORTED_MODULE_0___default()(document).off(me.fullscreenEvent);
            }
        });
        me.screenElement = screenEle;
        me.screenElement.append("<div class=\"opening\">" + t('mindnote.editor.opening') + "...</div>");
        me.launchFullscreen();
        setTimeout(function () {
            me.open(def, screenEle, name);
            me.screenElement.find('.opening').remove();
        }, 100);
    };
    /**
     * 打开
     * @param def 文档的定义
     */
    DemoPlayer.prototype.open = function (def, screenEle, name) {
        var _this = this;
        this.definition = jquery__WEBPACK_IMPORTED_MODULE_0___default.a.extend(true, {}, def);
        this.screenElement = screenEle;
        this.initDom();
        this.nodeMapping = {};
        if (this.definition.nodes && this.definition.nodes.length > 0) {
            // 绘制节点
            recursive(this.definition.nodes, function (node, parentNode) {
                _this.nodeMapping[node.id] = {
                    node: node,
                    parent: parentNode ? parentNode : null
                };
            });
        }
        this.screenElement.find('.title').text(name);
        this.treeElement = this.screenElement.find('.mindnote-tree');
        if (this.treeElement.length === 0) {
            return;
        }
        this.setZoomScale();
        this.refreshView();
        this.resetMenu();
    };
    /**
     * 在阅读状态下进入全屏演示
     */
    DemoPlayer.prototype.readingPlay = function () {
        // 已经打开了
        if (this.opened) {
            return;
        }
        this.zoom = 1.5;
        this.setZoomScale();
        var me = this;
        jquery__WEBPACK_IMPORTED_MODULE_0___default()(document).off(this.fullscreenEvent).on(this.fullscreenEvent, function () {
            me.screenElement.toggleClass('reading');
            if (me.screenElement.hasClass('reading')) {
                // 退出了全屏，重置缩放值
                me.opened = false;
                me.zoom = 1;
                me.screenElement.removeClass('night-mode');
                me.setZoomScale();
                jquery__WEBPACK_IMPORTED_MODULE_0___default()(document).off(me.fullscreenEvent);
            }
        });
        me.launchFullscreen();
    };
    DemoPlayer.prototype.getRootId = function () {
        return this.rootId;
    };
    DemoPlayer.prototype.initDom = function () {
        var moonIcon = new default_1(IconSet.MOON, 20);
        var zoomInIcon = new default_1(IconSet.ZOOM_IN, 20);
        var zoomOutIcon = new default_1(IconSet.ZOOM_OUT, 20);
        this.screenElement.empty().append('<div class="scrollable">' +
            '<div class="mindnote-demo-watermark"></div>' +
            '<div class="demo-wrapper">' +
            '<div class="header">' +
            '<div class="title"></div>' +
            '<div class="mindnote-dir"></div>' +
            '</div>' +
            '<div class="mindnote-tree"></div>' +
            '</div>' +
            '</div>' +
            '<div class="demo-menu">' +
            '<ul class="menu-list">' +
            '<li class="demo-mode">' +
            moonIcon.toString() +
            '</li>' +
            '<li class="demo-zoomin">' +
            zoomInIcon.toString() +
            '</li>' +
            '<li class="demo-zoomout">' +
            zoomOutIcon.toString() +
            '</li>' +
            '<li class="demo-exit">' +
            t('mindnote.editor.exit') +
            '</li>' +
            '</ul>' +
            '</div>');
    };
    return DemoPlayer;
}());

/**
 * 进度条组件
 * @param props
 */
var Progress = function (props) {
    return (Object(react__WEBPACK_IMPORTED_MODULE_14__["createElement"])("div", { className: "mindnote-upload-progress__outer", style: {
            width: props.width,
            height: props.height,
            borderRadius: props.height / 2
        } },
        Object(react__WEBPACK_IMPORTED_MODULE_14__["createElement"])("div", { className: "mindnote-upload-progress__inner", style: { width: props.value * 100 + "%" } })));
};
Progress.defaultProps = {
    width: 200,
    height: 10,
    value: 0,
};

var ProgressHolder = /** @class */ (function () {
    function ProgressHolder(props) {
        this.container = document.createElement('div');
        this.container.setAttribute('class', 'mindnote-image-holder');
        this.props = __assign({}, Progress.defaultProps, props);
        this.render(this.props);
    }
    /**
     * Append 进某一个节点下面
     * @param target 目标节点
     */
    ProgressHolder.prototype.appendTo = function (target) {
        jquery__WEBPACK_IMPORTED_MODULE_0___default()(this.container).appendTo(target);
        return this;
    };
    /**
     * 获取 DOM 节点
     */
    ProgressHolder.prototype.get = function () {
        return this.container;
    };
    ProgressHolder.prototype.getProps = function () {
        return this.props;
    };
    ProgressHolder.prototype.update = function (props) {
        this.props = __assign({}, this.props, props);
        this.render(this.props);
    };
    ProgressHolder.prototype.destroy = function () {
        Object(react_dom__WEBPACK_IMPORTED_MODULE_13__["unmountComponentAtNode"])(this.container);
        jquery__WEBPACK_IMPORTED_MODULE_0___default()(this.container).remove();
    };
    ProgressHolder.prototype.render = function (props) {
        Object(react_dom__WEBPACK_IMPORTED_MODULE_13__["render"])(Object(react__WEBPACK_IMPORTED_MODULE_14__["createElement"])(Progress, __assign({}, props)), this.container);
    };
    return ProgressHolder;
}());

var ImageHolder = /** @class */ (function () {
    function ImageHolder() {
        this.progressMap = {};
    }
    /**
     * 创建一个 ProgressHolder
     * @param id 图片ID
     */
    ImageHolder.prototype.create = function (id) {
        var progressHolder = new ProgressHolder();
        this.progressMap[id] = progressHolder;
        return progressHolder;
    };
    /**
     * 获取一个 ProgressHolder
     * @param id 图片ID
     */
    ImageHolder.prototype.get = function (id) {
        var progressHolder = this.progressMap[id];
        if (progressHolder) {
            return progressHolder;
        }
        return null;
    };
    /**
     * 移除一个 ProgressHolder
     * @param id 图片ID
     */
    ImageHolder.prototype.remove = function (id) {
        var progressHolder = this.progressMap[id];
        if (progressHolder) {
            progressHolder.destroy();
            delete this.progressMap[id];
        }
    };
    return ImageHolder;
}());

var Editor = /** @class */ (function () {
    /**
     * 思维笔记编辑器构造函数
     * @param props 编辑器参数
     */
    function Editor(props) {
        var _this = this;
        /**
         * 图片上传组件，用于管理上传的holder
         */
        this.imageHolder = new ImageHolder();
        this.handlerMap = {};
        this.getPath = function (id) {
            return _this.model.getPath(id);
        };
        this.getNodeSet = function (path) {
            return _this.model.getNodeSet(path);
        };
        this.binder = function (type) {
            return function () {
                var args = [];
                for (var _i = 0; _i < arguments.length; _i++) {
                    args[_i] = arguments[_i];
                }
                var handlers = _this.handlerMap[type];
                if (handlers) {
                    Object(lodash_es__WEBPACK_IMPORTED_MODULE_5__["default"])(handlers, function (v) {
                        v.apply(void 0, args);
                    });
                }
            };
        };
        this.viewport = new Viewport(props);
        this.state = new State(props);
        this.model = new Model(props.id);
        this.selectHolder = new SelectHolder();
        this.imageUploading = new ImageUploading();
        this.lifecycle = new Lifecycle(this.state);
        this.eventSource = new EventSource(this.model, this.selectHolder, this.state, this.viewport);
        this.nodePainter = new NodePainter(this.state, this.imageUploading, this.imageHolder);
        this.enginePainter = new EnginePainter(this.model, this.imageUploading, this.nodePainter, this.viewport, this.state);
        this.engine = new Engine(this.model, this.imageUploading, this.state, this.enginePainter, this.viewport, this.eventSource);
        this.selector = new Selector(this.model, this.engine, this.state, this.selectHolder, this.viewport);
        this.imageEditor = new ImageEditor(props.id, this.eventSource);
        this.textEditor = new TextEditor(this.imageEditor, this.viewport);
        this.messageRunner = new MessageRunner(this.engine, this.model, this.selector, this.eventSource);
        this.editorUI = new EditorUI(this.model, this.engine, this.state, this.selector, this.imageEditor, this.textEditor, this.viewport, this.eventSource);
        this.minder = new Minder(this.state, this.engine, this.eventSource, this.viewport);
        this.demoPlayer = new DemoPlayer(this.nodePainter);
        this.editorUI.init();
    }
    Editor.prototype.open = function (props) {
        this.editorUI.openDocument(props.data, props.title);
        this.eventSource.on(SourceEvent.DOC_CHANGED, this.binder(MindNoteEvent.EDIT));
        this.eventSource.on(SourceEvent.MESSAGE_EXECUTED, this.binder(MindNoteEvent.CHANGE));
        this.eventSource.on(SourceEvent.DRILLED, this.binder(MindNoteEvent.DRILL));
        this.eventSource.on(SourceEvent.DRILL_REMOVED, this.binder(MindNoteEvent.DRILL_REMOVED));
        this.eventSource.on(SourceEvent.TITLE_CHANGED, this.binder(MindNoteEvent.TITLE_CHANGE));
        this.eventSource.on(SourceEvent.MIND_MAP_CLOSE, this.binder(MindNoteEvent.MIND_MAP_CLOSE));
        this.eventSource.on(SourceEvent.MIND_MAP_EXPORT, this.binder(MindNoteEvent.MIND_MAP_EXPORT));
        this.eventSource.on(SourceEvent.ADD_IMAGE, this.binder(MindNoteEvent.ADD_IMAGE));
        this.eventSource.on(SourceEvent.TIP_MESSAGE, this.binder(MindNoteEvent.TIP_MESSAGE));
        this.eventSource.on(SourceEvent.PREVIEW_IMAGE, this.binder(MindNoteEvent.PREVIEW_IMAGE));
        this.eventSource.on(SourceEvent.NODE_CLICK, this.binder(MindNoteEvent.NODE_CLICK));
        this.eventSource.on(SourceEvent.INPUT_FOCUS, this.binder(MindNoteEvent.INPUT_FOCUS));
    };
    Editor.prototype.destroy = function () {
        this.lifecycle.destroy();
    };
    Editor.prototype.addEventListener = function (type, callback) {
        var handlers = this.handlerMap[type];
        if (!handlers) {
            this.handlerMap[type] = [callback];
        }
        else {
            handlers.push(callback);
        }
    };
    Editor.prototype.removeEventListener = function (type, callback) {
        var handlers = this.handlerMap[type];
        if (handlers) {
            var index = handlers.findIndex(function (val) {
                return val === callback;
            });
            if (index !== -1) {
                handlers.splice(index, index + 1);
            }
        }
    };
    Editor.prototype.execute = function (actions, type) {
        this.messageRunner.executeMessage(actions, type);
        // redo/undo 后，不能再合并之前的 input 操作
        if (type === ExecuteType.REDO || type === ExecuteType.UNDO) {
            this.textEditor.resetInputAction();
            this.eventSource.trigger('changed', actions);
        }
    };
    /**
     * 设置光标
     * @param cursorInfo 光标信息
     */
    Editor.prototype.setCursor = function (cursorInfo) {
        switch (cursorInfo.type) {
            // 单/多选节点
            case CursorType.NODE: {
                if (cursorInfo.selected.length) {
                    // 多选节点
                    this.selector.setSelectedIds(cursorInfo.selected);
                }
                else {
                    this.selector.cancel();
                }
                break;
            }
            // 节点文本
            case CursorType.TEXT: {
                var content = getContentById(cursorInfo.id);
                if (content.is(':visible')) {
                    setCursorPosition(content, cursorInfo.nextPos);
                }
                break;
            }
            // 节点描述
            case CursorType.NOTE: {
                var content = getNodeContainer(cursorInfo.id).children('.note');
                if (content.is(':visible')) {
                    setCursorPosition(content, cursorInfo.nextPos);
                }
                break;
            }
            // 翻页
            case CursorType.DRILL: {
                this.engine.drillNode(cursorInfo.to, true);
                break;
            }
        }
    };
    Editor.prototype.openMindMap = function (watermark) {
        var rootNode = this.model.getRootNode();
        var rootId = rootNode ? rootNode.id : null;
        this.minder.open(this.model.getDefine(), this.model.getName(), rootId, watermark);
    };
    Editor.prototype.openPresentation = function (watermark) {
        var rootNode = this.model.getRootNode();
        var rootId = rootNode ? rootNode.id : null;
        this.demoPlayer.play(this.model.getDefine(), this.viewport.demoScreen, this.model.getName(), rootId, watermark);
    };
    Editor.prototype.export = function () {
        throw new Error('Method not implemented.');
    };
    Editor.prototype.getEditable = function () {
        return !this.engine.getReadOnly();
    };
    Editor.prototype.setEditable = function (editable) {
        this.engine.setReadOnly(!editable);
    };
    Editor.prototype.setTitle = function (title) {
        this.model.setName(title);
        this.engine.getPainter().setTitle(title);
    };
    Editor.prototype.getTitle = function () {
        return this.model.getName();
    };
    Editor.prototype.addImage = function (nodeId, image) {
        var _this = this;
        var holder = this.imageHolder.create(image.id);
        this.engine.insertUploadingImage(nodeId, image);
        return {
            onProgress: function (value) {
                holder.update({ value: value });
            },
            onSuccess: function (src) {
                // 上传完成
                image.uri = src;
                _this.engine.insertImage(nodeId, image);
            },
            onError: function (e) {
                _this.engine.removeUploadingImage(image.id);
            }
        };
    };
    /**
     * 删除图片
     * @param {string} nodeId
     * @param {string} imageId
     */
    Editor.prototype.removeImage = function (nodeId, imageId) {
        this.engine.removeImageById(nodeId, imageId);
    };
    /**
     * 执行一个编辑指令，如indent、加粗，一般通过移动端的toolbar触发
     */
    Editor.prototype.executeEditAction = function (action) {
        this.editorUI.executeEditAction(action);
    };
    Editor.prototype.getFocusNode = function () {
        return this.editorUI.getFocusNode();
    };
    return Editor;
}());

/* harmony default export */ __webpack_exports__["default"] = (Editor);

//# sourceMappingURL=index.js.map

/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28), __webpack_require__(726).clearImmediate, __webpack_require__(726).setImmediate))

/***/ }),

/***/ 1842:
/***/ (function(module, exports) {

/* (ignored) */

/***/ }),

/***/ 1843:
/***/ (function(module, exports) {

/* (ignored) */

/***/ }),

/***/ 1861:
/***/ (function(module, exports) {

/* (ignored) */

/***/ }),

/***/ 1864:
/***/ (function(module, exports) {

/* (ignored) */

/***/ }),

/***/ 2042:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
var StatusCode = exports.StatusCode = undefined;
(function (StatusCode) {
  /**
   * 请求成功
   */
  StatusCode[StatusCode["SUCCESS"] = 0] = "SUCCESS";
  /**
   * 请求失败
   */
  StatusCode[StatusCode["FAILED"] = 1] = "FAILED";
  /**
   * 参数错误
   */
  StatusCode[StatusCode["INVALID_PARAM"] = 2] = "INVALID_PARAM";
  /**
   * 找不到资源
   */
  StatusCode[StatusCode["NOT_FOUND"] = 3] = "NOT_FOUND";
  /**
   * 没有访问权限
   */
  StatusCode[StatusCode["FORBIDDEN"] = 4] = "FORBIDDEN";
  /**
   * 未登陆
   */
  StatusCode[StatusCode["LOGIN_REQUIRED"] = 5] = "LOGIN_REQUIRED";
  /**
   * 数据太多，没法一次返回
   */
  StatusCode[StatusCode["LIMIT_EXCEED"] = 6] = "LIMIT_EXCEED";
  /**
   * 资源已被删除
   */
  StatusCode[StatusCode["OBJECT_DELETED"] = 7] = "OBJECT_DELETED";
  /**
   * 用户请求的changeset数量超过限制
   */
  StatusCode[StatusCode["CHANGESET_LIMIT_EXCEED"] = 1001] = "CHANGESET_LIMIT_EXCEED";
  /**
   * member_id不在session中
   */
  StatusCode[StatusCode["NOT_IN_SESSION"] = 1003] = "NOT_IN_SESSION";
  /**
   * 提交效验失败
   */
  StatusCode[StatusCode["CHAGESET_INVALID"] = 1005] = "CHAGESET_INVALID";
  /**
   * 内部错误，就是后端挂了
   */
  StatusCode[StatusCode["INTERNAL_ERROR"] = 1006] = "INTERNAL_ERROR";
  /**
   * 消息不合法
   */
  StatusCode[StatusCode["INVALID_MESSAGE"] = 1007] = "INVALID_MESSAGE";
  /**
   * 算法处理失败，后端崩了
   */
  StatusCode[StatusCode["SYNC_FAILED"] = 1008] = "SYNC_FAILED";
  /**
   * 文档太旧
   */
  StatusCode[StatusCode["VERSION_TOO_OLD"] = 1010] = "VERSION_TOO_OLD";
  /**
   * 没有编辑权限
   */
  StatusCode[StatusCode["WRITE_PERMISSION_DENIED"] = 1012] = "WRITE_PERMISSION_DENIED";
  /**
   * 没有评论权限
   */
  StatusCode[StatusCode["COMMENT_PERMISSION_DENIED"] = 1013] = "COMMENT_PERMISSION_DENIED";
  /**
   * 依赖服务异常，后端挂了
   */
  StatusCode[StatusCode["SERVICE_ERROR"] = 1015] = "SERVICE_ERROR";
  /**
   * 数据库存储冲突，后端竞争出错
   */
  StatusCode[StatusCode["DATABASE_CONFLICT"] = 1021] = "DATABASE_CONFLICT";
  /**
   * 请求频繁
   */
  StatusCode[StatusCode["SERVER_BUSY"] = 9998] = "SERVER_BUSY";
})(StatusCode || (exports.StatusCode = StatusCode = {}));
var EngineType = exports.EngineType = undefined;
(function (EngineType) {
  /**
   * 思维笔记相关消息
   */
  EngineType["MIND_NOTE"] = "MINDNOTE";
  /**
   * Room 相关消息，进房、离房、心跳等
   */
  EngineType["COLLABROOM"] = "COLLABROOM";
  /**
   * 权限通知
   */
  EngineType["NOTIFY"] = "NOTIFY";
})(EngineType || (exports.EngineType = EngineType = {}));
/**
 * 二级消息类型，上行：客户端推给服务端，下行：服务端推给客户端，双工：客户端和服务端都会推
 */
var MessageType = exports.MessageType = undefined;
(function (MessageType) {
  /**
   * 新用户进房（下行）
   */
  MessageType["USER_NEWINFO"] = "USER_NEWINFO";
  /**
   * 用户离房（下行）
   */
  MessageType["USER_LEAVE"] = "USER_LEAVE";
  /**
   * 初始化数据（双工）
   */
  MessageType["CLIENT_VARS"] = "CLIENT_VARS";
  /**
   * 广播光标（双工）
   */
  MessageType["ENGAGEMENT_CURSOR"] = "ENGAGEMENT_CURSOR";
  /**
   * 广播光标ACK（下行）
   */
  MessageType["ACCEPT_ENGAGEMENT_CURSOR"] = "ACCEPT_ENGAGEMENT_CURSOR";
  /**
   * 进房成功（下行）
   */
  MessageType["ACCEPT_WATCH"] = "ACCEPT_WATCH";
  /**
   * Changeset ACK（下行）
   */
  MessageType["ACCEPT_COMMIT"] = "ACCEPT_COMMIT";
  /**
   * 远端推送的新 Changeset（下行）
   */
  MessageType["NEW_CHANGES"] = "NEW_CHANGES";
  /**
   * 本地产生的 Changeset（上行）
   */
  MessageType["USER_CHANGES"] = "USER_CHANGES";
  /**
   * 查询频道（上行）
   */
  MessageType["MESSAGE_CHANNEL"] = "MESSAGE_CHANNEL";
  /**
   * 房间所有成员信息（下行）
   */
  MessageType["ROOM_MEMBERS"] = "ROOM_MEMBERS";
  /**
   * 权限变更（这个变更消息是一个历史消息，用于文件夹相关的操作）
   */
  MessageType["PERMISSION_CHANGE"] = "PERMISSION_CHANGE";
  /**
   * 文档中的权限变更消息
   */
  MessageType["OBJ_PERMISSION_CHANGE"] = "OBJ_PERMISSION_CHANGE";
  /**
   * 错误（下行）
   */
  MessageType["ERROR"] = "ERROR";
})(MessageType || (exports.MessageType = MessageType = {}));
/**
 * 查询频道
 */
var MessageChannel = exports.MessageChannel = undefined;
(function (MessageChannel) {
  /**
   * 文档权限频道
   */
  MessageChannel["PERMISSION_CHANNEL"] = "obj_permission_channel";
  /**
   * 文档引擎查询频道
   */
  MessageChannel["ENGINE_CHANNEL"] = "engine_channel";
  /**
   * 房间信息查询频道
   */
  MessageChannel["MEMBER_CHANNEL"] = "member_channel";
  /**
   * 评论版本信息
   */
  MessageChannel["COMMENT_CHANNEL"] = "comment_channel";
})(MessageChannel || (exports.MessageChannel = MessageChannel = {}));

/***/ }),

/***/ 2043:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.MoiraeKeys = undefined;

var _mapValues2 = __webpack_require__(3014);

var _mapValues3 = _interopRequireDefault(_mapValues2);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * moirae 打点 key 前缀
 */
var PREFIX = 'ee.docs.mindnote.';
/**
 * moirae 打点 key 列表，不含前缀
 */
var KEYS = {
  /**
   * sync 请求
   */
  SYNC_REQUEST: 'sync_request',
  /**
   * sync 请求失败
   */
  SYNC_REQUEST_FAILED: 'sync_request_fail',
  /**
   * transform 失败
   */
  TRANSFORM_FAILED: 'transform_fail',
  /**
   * apply 本地 operation 失败
   */
  APPLY_CLIENT_OP_FAILED: 'apply_client_op_fail',
  /**
   * apply 远端 operation 失败
   */
  APPLY_SERVER_OP_FAILED: 'apply_server_op_fail',
  /**
   * 拉取缺失版本
   */
  FETCH_MISS_CHANGESET: 'fetch_miss_changeset',
  /**
   * 上传图片失败
   */
  UPLOAD_IMAGE_FAILED: 'upload_image_fail'
};
/**
 * moirae 打点 key 列表，包含前缀
 */
var MoiraeKeys = exports.MoiraeKeys = (0, _mapValues3.default)(KEYS, function (key) {
  return '' + PREFIX + key;
});

/***/ }),

/***/ 2044:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
/**
 * 错误提示类型
 */
var ErrorAlertType = exports.ErrorAlertType = undefined;
(function (ErrorAlertType) {
  /**
   * toast 提醒
   */
  ErrorAlertType["TOAST"] = "TOAST";
  /**
   * 弹窗提醒
   */
  ErrorAlertType["DIALOG"] = "DIALOG";
})(ErrorAlertType || (exports.ErrorAlertType = ErrorAlertType = {}));
/**
 * 弹窗按钮类型
 */
var ButtonType = exports.ButtonType = undefined;
(function (ButtonType) {
  ButtonType["DEFAULT"] = "default";
  ButtonType["PRIMARY"] = "primary";
  ButtonType["WARN"] = "warn";
})(ButtonType || (exports.ButtonType = ButtonType = {}));

/***/ }),

/***/ 2045:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.assertNever = assertNever;
/**
 * 断言不应该出现的类型
 */
function assertNever(x) {
  console.error(x + " is not a never type");
}

/***/ }),

/***/ 3005:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _reactRedux = __webpack_require__(238);

var _reactRouterDom = __webpack_require__(278);

var _Mindnote = __webpack_require__(3006);

var _Mindnote2 = _interopRequireDefault(_Mindnote);

var _suite = __webpack_require__(69);

var _network = __webpack_require__(1648);

var _suite2 = __webpack_require__(241);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var mapDispatchToProps = {
    fetchMobileCurrentSuite: _suite2.fetchMobileCurrentSuite,
    getTokenInfo: _suite2.getTokenInfo
};
var mapStateToProps = function mapStateToProps(state) {
    return {
        curSuiteToken: (0, _suite.selectCurrentSuiteToken)(state),
        curSuite: (0, _suite.selectCurrentSuiteByObjToken)(state),
        onLine: (0, _network.selectNetworkState)(state).connected,
        clientVars: {}
    };
};
exports.default = (0, _reactRouterDom.withRouter)((0, _reactRedux.connect)(mapStateToProps, mapDispatchToProps)(_Mindnote2.default));

/***/ }),

/***/ 3006:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _mindNote = __webpack_require__(3007);

var _mindNote2 = _interopRequireDefault(_mindNote);

var _react = __webpack_require__(1);

var React = _interopRequireWildcard(_react);

var _watermark = __webpack_require__(1666);

var _watermark2 = _interopRequireDefault(_watermark);

var _header = __webpack_require__(1706);

var _header2 = _interopRequireDefault(_header);

var _app_context_menu = __webpack_require__(1768);

var _app_context_menu2 = _interopRequireDefault(_app_context_menu);

var _common = __webpack_require__(19);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// import AppSelectionControl from '$m_components/app_control_manager/appSelectControl';
var MindNote = function (_React$Component) {
    (0, _inherits3.default)(MindNote, _React$Component);

    function MindNote(props) {
        (0, _classCallCheck3.default)(this, MindNote);
        return (0, _possibleConstructorReturn3.default)(this, (MindNote.__proto__ || Object.getPrototypeOf(MindNote)).call(this, props));
    }

    (0, _createClass3.default)(MindNote, [{
        key: 'componentDidMount',
        value: function componentDidMount() {
            console.info('mindnote wrap mount');
            var curSuiteToken = this.props.curSuiteToken;
            var fetchMobileCurrentSuite = this.props.fetchMobileCurrentSuite;

            fetchMobileCurrentSuite(curSuiteToken, _common.NUM_FILE_TYPE.MINDNOTE);
        }
    }, {
        key: 'render',
        value: function render() {
            var _props = this.props,
                curSuite = _props.curSuite,
                onLine = _props.onLine,
                getTokenInfo = _props.getTokenInfo,
                curSuiteToken = _props.curSuiteToken;

            return React.createElement("div", { className: "mindnote-main-wrap", id: "mindnote-main" }, React.createElement(_watermark2.default, { platform: "mobile" }), React.createElement(_header2.default, { currentNote: curSuite, onLine: onLine, getTokenInfo: getTokenInfo, isTemplate: false }), React.createElement(_app_context_menu2.default, null), React.createElement(_mindNote2.default, null));
        }
    }]);
    return MindNote;
}(React.Component);
// import AppContextMenu from './app_context_menu';


exports.default = MindNote;

/***/ }),

/***/ 3007:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _container = __webpack_require__(3008);

var _container2 = _interopRequireDefault(_container);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = _container2.default;

window.native = window.native || {};
window.native.mindnote = window.native.mindnote || {};

/***/ }),

/***/ 3008:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _reactRedux = __webpack_require__(238);

var _permissionHelper = __webpack_require__(274);

var _suite = __webpack_require__(69);

var _user = __webpack_require__(56);

var _share = __webpack_require__(375);

var _suite2 = __webpack_require__(241);

var _MindNote = __webpack_require__(3009);

var _MindNote2 = _interopRequireDefault(_MindNote);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var mapStateToProps = function mapStateToProps(state) {
    return {
        user: (0, _user.selectCurrentUser)(state).toJSON(),
        token: (0, _suite.selectCurrentSuiteToken)(state),
        suite: (0, _suite.selectCurrentSuiteByObjToken)(state),
        permission: (0, _permissionHelper.getUserPermissions)((0, _share.selectCurrentPermission)(state))
    };
};
var mapDispatchToProps = {
    updateTitle: _suite2.updateTitle,
    syncNoteMeta: _suite2.syncNoteMeta
};
exports.default = (0, _reactRedux.connect)(mapStateToProps, mapDispatchToProps)(_MindNote2.default);

/***/ }),

/***/ 3009:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.NoteMetaSyncTypes = undefined;

var _regenerator = __webpack_require__(13);

var _regenerator2 = _interopRequireDefault(_regenerator);

var _asyncToGenerator2 = __webpack_require__(99);

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _uniqueId2 = __webpack_require__(1773);

var _uniqueId3 = _interopRequireDefault(_uniqueId2);

var _isEqual2 = __webpack_require__(301);

var _isEqual3 = _interopRequireDefault(_isEqual2);

var _debounce2 = __webpack_require__(67);

var _debounce3 = _interopRequireDefault(_debounce2);

var _reduce2 = __webpack_require__(753);

var _reduce3 = _interopRequireDefault(_reduce2);

var _react = __webpack_require__(1);

var React = _interopRequireWildcard(_react);

var _sync = __webpack_require__(3010);

var _sync2 = _interopRequireDefault(_sync);

var _editor = __webpack_require__(1813);

var _editor2 = _interopRequireDefault(_editor);

var _mindNoteContext = __webpack_require__(1670);

var _mindNoteContext2 = _interopRequireDefault(_mindNoteContext);

var _MindNoteContext = __webpack_require__(1619);

var _bytedOtJson = __webpack_require__(1726);

var _bytedOtJson2 = _interopRequireDefault(_bytedOtJson);

var _errorHandler = __webpack_require__(3016);

var _errorHandler2 = _interopRequireDefault(_errorHandler);

var _adapter = __webpack_require__(3021);

var _error = __webpack_require__(1812);

var _common = __webpack_require__(19);

var _toastHelper = __webpack_require__(381);

var _toast = __webpack_require__(500);

var _toast2 = _interopRequireDefault(_toast);

var _permissionHelper = __webpack_require__(274);

var _moirae = __webpack_require__(378);

var _moirae2 = _interopRequireDefault(_moirae);

var _moirae3 = __webpack_require__(2043);

__webpack_require__(3026);

__webpack_require__(3027);

var _plugins = __webpack_require__(3028);

var _plugins2 = _interopRequireDefault(_plugins);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var NoteMetaSyncTypes = exports.NoteMetaSyncTypes = undefined;
// import { ENTITY_TYPE } from '$common/constants/common';

(function (NoteMetaSyncTypes) {
    /**
     * 当前客户端正在提交数据
     */
    NoteMetaSyncTypes["USER_CHANGES"] = "USER_CHANGES";
    /**
     * 编辑数据已经提交成功
     */
    NoteMetaSyncTypes["ACCEPT_COMMIT"] = "ACCEPT_COMMIT";
    /**
     * 同步远端的数据
     */
    NoteMetaSyncTypes["NEW_CHANGES"] = "NEW_CHANGES";
})(NoteMetaSyncTypes || (exports.NoteMetaSyncTypes = NoteMetaSyncTypes = {}));
/**
 * MindNote 入口组件
 */

var MindNote = function (_React$Component) {
    (0, _inherits3.default)(MindNote, _React$Component);

    function MindNote(props) {
        (0, _classCallCheck3.default)(this, MindNote);

        var _this = (0, _possibleConstructorReturn3.default)(this, (MindNote.__proto__ || Object.getPrototypeOf(MindNote)).call(this, props));

        _this.mindNoteContext = _mindNoteContext2.default.getInstance();
        _this.handleCloseMap = function (data) {
            window.lark.biz.util.toggleTitlebar({
                states: 1
            });
            document.querySelector('html').classList.remove('openMap');
        };
        _this.handleSave2Image = function (data) {
            window.lark.biz.util.save2Image({
                name: data.name,
                data: data.base64Data
            }, function (data) {
                if (data.code === '1') {
                    (0, _toastHelper.showToast)({
                        type: 0,
                        message: t('mobile.save_img_success'),
                        duration: 3
                    });
                } else {
                    (0, _toastHelper.showToast)({
                        type: 1,
                        message: t('mobile.save_img_failed'),
                        duration: 3
                    });
                }
            });
        };
        _this.nodeClick = function () {
            if (_this.permission.editable && !_this.hasEditNotice) {
                _this.hasEditNotice = true;
                (0, _toastHelper.showToast)({
                    type: 3,
                    message: t('mindnote.mobile.editnotice'),
                    duration: 2
                });
            }
        };
        _this.previewImage = function (data) {
            console.log(data);
            data['imageList'] = data['imageList'] || [];
            var imageList = [];
            var image = {
                title: '',
                src: location.origin + data['imageList'][data.index].uri,
                uuid: data['imageList'][data.index].id
            };
            data.imageList.forEach(function (element) {
                var item = {
                    title: '',
                    src: location.origin + element.uri,
                    uuid: element.id
                };
                imageList.push(item);
            });
            window.lark.biz.util.openImg({
                image: image,
                image_list: imageList
            });
        };
        /**
         * 选择图片上传
         */
        _this.handleUploadImage = function (_ref) {
            // this.imageUploader.selectImage({
            //   id,
            //   imageId,
            //   base64Data,
            //   uploadCallback: (id: string, image: Image, uploadHandler: Promise<string>) => {
            //     this.editor.addImage(id, image, uploadHandler);
            //   },
            // });

            var id = _ref.id,
                imageId = _ref.imageId,
                base64Data = _ref.base64Data;
        };
        _this.handleDrill = function (e) {
            _this.mindNoteContext.trigger(_MindNoteContext.MindNoteEvent.DRILL, e);
        };
        /**
         * 编辑器本地操作
         */
        _this.handleClientChange = function (actions) {
            try {
                /* 将编辑器原始消息转换成OT-JSON格式 */
                var ops = (0, _reduce3.default)(actions, function (prev, action) {
                    var op = (0, _adapter.actionToOperation)(action, _this.snapshot);
                    return prev.concat(op);
                }, []);
                _this.snapshot.apply(ops);
                _this.mindNoteContext.trigger(_MindNoteContext.MindNoteEvent.CHANGE_CLIENT, ops);
            } catch (error) {
                _moirae2.default.count(_moirae3.MoiraeKeys.APPLY_CLIENT_OP_FAILED);
                _moirae2.default.ravenCatch(error);
                console.error(error);
                _this.mindNoteContext.trigger(_MindNoteContext.MindNoteEvent.ERROR, {
                    type: _error.ErrorType.COLLABORATION_ERROR,
                    code: _error.ClientErrorCode.APPLY_ACTION_FAILED
                });
            }
        };
        /**
         * 远端推送的change
         */
        _this.handleServerChange = function (ops) {
            try {
                /* 将OT-JSON格式的消息转换成编辑器消息 */
                var actions = (0, _reduce3.default)(ops, function (prev, op) {
                    /**
                     * 注意此处需要对每个op单独应用，因为如果有一组带层级结构的创建，在父节点没有被创建出来的时候，无法获取父节点的 NodeSet
                     */
                    var action = (0, _adapter.operationToAction)(op, _this.snapshot);
                    _this.snapshot.apply([op]);
                    return prev.concat(action);
                }, []);
                console.info('Receive:', actions);
                _this.editor.execute(actions);
                // 更新文档 meta
                _this.props.syncNoteMeta({
                    type: NoteMetaSyncTypes.NEW_CHANGES
                });
            } catch (error) {
                _moirae2.default.count(_moirae3.MoiraeKeys.APPLY_SERVER_OP_FAILED);
                _moirae2.default.ravenCatch(error);
                console.error(error);
                _this.mindNoteContext.trigger(_MindNoteContext.MindNoteEvent.ERROR, {
                    type: _error.ErrorType.COLLABORATION_ERROR,
                    code: _error.ClientErrorCode.APPLY_ACTION_FAILED
                });
            }
        };
        /**
         * 编辑器里面标题更新后，要更新meta
         */
        _this.handleTitleChange = function (e) {
            var _this$props = _this.props,
                token = _this$props.token,
                updateTitle = _this$props.updateTitle,
                syncTabTitle = _this$props.syncTabTitle;

            updateTitle({
                token: token,
                type: _common.NUM_SUITE_TYPE.MINDNOTE,
                title: e.title
            }).then(function () {
                syncTabTitle({
                    token: token,
                    type: _common.NUM_SUITE_TYPE.MINDNOTE,
                    title: e.title
                });
            });
        };
        /**
         * 点击演示模式
         */
        _this.handleOpenPresentation = function () {
            _this.editor.openPresentation();
        };
        /**
         * 点击思维导图
         */
        _this.handleOpenMindMap = function () {
            _this.editor.openMindMap();
        };
        _this.handleSaving = function () {
            _this.props.syncNoteMeta({
                type: NoteMetaSyncTypes.USER_CHANGES
            });
        };
        _this.handleSaved = function () {
            _this.props.syncNoteMeta({
                type: NoteMetaSyncTypes.ACCEPT_COMMIT
            });
        };
        /**
         * 若当前用户正在翻页钻取的节点内，且节点被协同删除
         */
        _this.handleDrillRemoved = function () {
            _toast2.default.show({
                key: 'MINDNOTE_DRILL_REMOVED',
                type: 'info',
                content: t('mindnote.drill.removed'),
                duration: 3000,
                closable: true
            });
        };
        // this.sync = new Sync({
        //   objToken: this.props.token,
        //   userId: this.props.user.id,
        // });
        _this.handleTitleChange = (0, _debounce3.default)(_this.handleTitleChange, 500);
        window.Mind = _this;
        return _this;
    }

    (0, _createClass3.default)(MindNote, [{
        key: 'componentDidMount',
        value: function componentDidMount() {
            console.info('mindnote mount');
            this.plugins = new _plugins2.default();
            this.start(this.props);
            window.lark.biz.navigation.setTitle({ title: '' });
        }
    }, {
        key: 'componentWillReceiveProps',
        value: function componentWillReceiveProps(nextProps) {
            var _this2 = this;

            /**
             * 创建新文档时 token 会变化，销毁重新实例化。
             * 若 token 不存在，则代表回退到文件夹页面
             */
            if (nextProps.token && nextProps.token !== this.props.token && this.editor) {
                this.stop().then(function () {
                    _this2.start(nextProps);
                });
            }
            /**
             * 用户权限变化
             * 前置条件，token 存在且相等
             */
            if (nextProps.token && nextProps.token === this.props.token && !(0, _isEqual3.default)(nextProps.permission, this.props.permission)) {
                // 触发时可能还没初始化
                if (this.editor) {
                    // this.editor.setEditable(nextProps.permission.editable);
                    this.editor.setEditable(false); // 一期不支持编辑；
                }
                // if (this.cursorPlugin) {
                //   this.cursorPlugin.setEditable(nextProps.permission.editable);
                // }
            }
        }
        /**
         * 此组件是编辑器的挂载点，所以默认不进行任何更新，如果存在有状态的组件，请放在子组件中
         */

    }, {
        key: 'shouldComponentUpdate',
        value: function shouldComponentUpdate() {
            return false;
        }
    }, {
        key: 'componentWillUnmount',
        value: function componentWillUnmount() {
            this.stop();
            this.plugins.destroy();
        }
        /**
         * 启动协同编辑器
         * @description 注意调用 start 时的生命周期，props 使用注入的方式防止生命周期的问题
         * @async
         */

    }, {
        key: 'start',
        value: function () {
            var _ref2 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee(props) {
                var clientVars, permissionSum, permission;
                return _regenerator2.default.wrap(function _callee$(_context) {
                    while (1) {
                        switch (_context.prev = _context.next) {
                            case 0:
                                this.sync = new _sync2.default({
                                    objToken: props.token,
                                    userId: props.user.id
                                });
                                // this.cursorPlugin = new CursorPlugin({
                                //   $paper: $(this.paperRef as HTMLElement),
                                //   $container: $(this.cursorRef as HTMLElement),
                                //   context: this.mindNoteContext,
                                //   user: props.user,
                                // });
                                console.info('---start');
                                console.info(new Date().getTime());

                                if (!this.sync.io.getStockObj) {
                                    _context.next = 6;
                                    break;
                                }

                                _context.next = 6;
                                return this.sync.io.getStockObj();

                            case 6:
                                console.info(new Date().getTime());
                                console.info('---end');
                                _context.next = 10;
                                return this.sync.start();

                            case 10:
                                clientVars = _context.sent;

                                /**
                                 * 从 ClientVars 中取权限的和
                                 * @description 注意此处的权限需要从clientVars中取，因为explorer获取权限的生命周期不一样
                                 */
                                permissionSum = (0, _reduce3.default)(clientVars.permissions, function (prev, curr) {
                                    return prev + curr;
                                }, 0);
                                permission = (0, _permissionHelper.permission2Booleans)(permissionSum);

                                this.permission = permission;
                                this.editor = new _editor2.default({
                                    root: this.paperRef,
                                    id: props.user.id + ':' + this.sync.getMemberId() + ':' + (0, _uniqueId3.default)('editor'),
                                    titlePlaceholder: t('common.unnamed_mindnote'),
                                    contentPlaceholder: t('mindnote.content.placeholder'),
                                    env: _editor.MindNoteEnvironment.APP,
                                    delayRelocateMindMap: true,
                                    statusBarSpacing: 34
                                });
                                // 给 editor 和 cursor 设置权限
                                // this.editor.setEditable(permission.editable);
                                // this.cursorPlugin.setEditable(permission.editable);
                                /* 注册 editor 以及 content 中的事件 */
                                this.editor.addEventListener(_editor.MindNoteEvent.EDIT, this.handleClientChange);
                                this.editor.addEventListener(_editor.MindNoteEvent.TITLE_CHANGE, this.handleTitleChange);
                                this.editor.addEventListener(_editor.MindNoteEvent.DRILL_REMOVED, this.handleDrillRemoved);
                                this.editor.addEventListener(_editor.MindNoteEvent.DRILL, this.handleDrill);
                                this.editor.addEventListener(_editor.MindNoteEvent.ADD_IMAGE, this.handleUploadImage);
                                this.editor.addEventListener(_editor.MindNoteEvent.MIND_MAP_EXPORT, this.handleSave2Image);
                                this.editor.addEventListener(_editor.MindNoteEvent.MIND_MAP_CLOSE, this.handleCloseMap);
                                this.editor.addEventListener(_editor.MindNoteEvent.PREVIEW_IMAGE, this.previewImage);
                                this.editor.addEventListener(_editor.MindNoteEvent.NODE_CLICK, this.nodeClick);
                                this.mindNoteContext.bind(_MindNoteContext.MindNoteEvent.CHANGE_SERVER, this.handleServerChange);
                                this.mindNoteContext.bind(_MindNoteContext.MindNoteEvent.OPEN_PRESENTATION, this.handleOpenPresentation);
                                this.mindNoteContext.bind(_MindNoteContext.MindNoteEvent.OPEN_MINDMAP, this.handleOpenMindMap);
                                this.mindNoteContext.bind(_MindNoteContext.MindNoteEvent.SAVING, this.handleSaving);
                                this.mindNoteContext.bind(_MindNoteContext.MindNoteEvent.SAVED, this.handleSaved);
                                /* 初始化副本 */
                                this.snapshot = new _bytedOtJson2.default(null, clientVars.collab_client_vars);
                                window.Snapshot = this.snapshot;
                                /**
                                 * 打开文档
                                 * @description 初始化编辑器是一个同步操作，所以插件初始化放在下面👇即可
                                 */
                                this.editor.open({
                                    token: props.token,
                                    data: clientVars.collab_client_vars,
                                    title: clientVars.title
                                });
                                // this.cursorPlugin.init();
                                this.editor.setEditable(false);
                                // 图片上传插件
                                // this.imageUploader = new ImageUploader(this.props.token, this.mindNoteContext);

                            case 33:
                            case 'end':
                                return _context.stop();
                        }
                    }
                }, _callee, this);
            }));

            function start(_x) {
                return _ref2.apply(this, arguments);
            }

            return start;
        }()
        /**
         * 关闭协同编辑器
         * @async
         */

    }, {
        key: 'stop',
        value: function () {
            var _ref3 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee2() {
                return _regenerator2.default.wrap(function _callee2$(_context2) {
                    while (1) {
                        switch (_context2.prev = _context2.next) {
                            case 0:
                                /* 注销 editor 以及 content 中的事件 */
                                this.editor.removeEventListener(_editor.MindNoteEvent.EDIT, this.handleClientChange);
                                this.editor.removeEventListener(_editor.MindNoteEvent.TITLE_CHANGE, this.handleTitleChange);
                                this.editor.removeEventListener(_editor.MindNoteEvent.DRILL_REMOVED, this.handleDrillRemoved);
                                this.editor.removeEventListener(_editor.MindNoteEvent.DRILL, this.handleDrill);
                                this.editor.removeEventListener(_editor.MindNoteEvent.ADD_IMAGE, this.handleUploadImage);
                                this.editor.removeEventListener(_editor.MindNoteEvent.MIND_MAP_EXPORT, this.handleSave2Image);
                                this.editor.removeEventListener(_editor.MindNoteEvent.MIND_MAP_CLOSE, this.handleCloseMap);
                                this.editor.removeEventListener(_editor.MindNoteEvent.PREVIEW_IMAGE, this.previewImage);
                                this.editor.removeEventListener(_editor.MindNoteEvent.NODE_CLICK, this.nodeClick);
                                this.mindNoteContext.unbind(_MindNoteContext.MindNoteEvent.CHANGE_SERVER, this.handleServerChange);
                                this.mindNoteContext.unbind(_MindNoteContext.MindNoteEvent.OPEN_PRESENTATION, this.handleOpenPresentation);
                                this.mindNoteContext.unbind(_MindNoteContext.MindNoteEvent.OPEN_MINDMAP, this.handleOpenMindMap);
                                this.mindNoteContext.unbind(_MindNoteContext.MindNoteEvent.SAVING, this.handleSaving);
                                this.mindNoteContext.unbind(_MindNoteContext.MindNoteEvent.SAVED, this.handleSaved);
                                _context2.next = 16;
                                return this.sync.stop();

                            case 16:
                                // this.cursorPlugin.destroy();
                                this.editor.destroy();
                                // this.imageUploader.destroy();

                            case 17:
                            case 'end':
                                return _context2.stop();
                        }
                    }
                }, _callee2, this);
            }));

            function stop() {
                return _ref3.apply(this, arguments);
            }

            return stop;
        }()
    }, {
        key: 'render',
        value: function render() {
            var _this3 = this;

            var minHeight = window.innerHeight - 90;
            return React.createElement("div", { className: "mindnote-main", style: { minHeight: minHeight } }, React.createElement(_errorHandler2.default, { context: this.mindNoteContext }), React.createElement("div", { className: "mindnote-box", ref: function ref(_ref4) {
                    return _this3.scrollRef = _ref4;
                } }, React.createElement("div", { className: "mindnote-root" }, React.createElement("div", { className: "mindnote-root-paper", ref: function ref(_ref5) {
                    return _this3.paperRef = _ref5;
                } }))));
        }
    }]);
    return MindNote;
}(React.Component);

exports.default = MindNote;
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3010:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _Sync = __webpack_require__(3011);

var _Sync2 = _interopRequireDefault(_Sync);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = _Sync2.default;

/***/ }),

/***/ 3011:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.ReadyState = exports.CLIENT_VARS = undefined;

var _defineProperty2 = __webpack_require__(11);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _regenerator = __webpack_require__(13);

var _regenerator2 = _interopRequireDefault(_regenerator);

var _asyncToGenerator2 = __webpack_require__(99);

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var _objectWithoutProperties2 = __webpack_require__(26);

var _objectWithoutProperties3 = _interopRequireDefault(_objectWithoutProperties2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _forEach2 = __webpack_require__(1627);

var _forEach3 = _interopRequireDefault(_forEach2);

var _map2 = __webpack_require__(1682);

var _map3 = _interopRequireDefault(_map2);

var _cloneDeep2 = __webpack_require__(1725);

var _cloneDeep3 = _interopRequireDefault(_cloneDeep2);

var _unset2 = __webpack_require__(3012);

var _unset3 = _interopRequireDefault(_unset2);

var _get2 = __webpack_require__(182);

var _get3 = _interopRequireDefault(_get2);

var _hideLoadingHelper = __webpack_require__(280);

var _util = __webpack_require__(542);

var _$constants = __webpack_require__(4);

var _sliApiMap = __webpack_require__(387);

var _offlineEditHelper = __webpack_require__(377);

var _io = __webpack_require__(717);

var _io2 = __webpack_require__(743);

var _bytedOtJson = __webpack_require__(1726);

var _bytedOtJson2 = _interopRequireDefault(_bytedOtJson);

var _types = __webpack_require__(2042);

var _memberHelper = __webpack_require__(737);

var _mindNoteContext = __webpack_require__(1670);

var _mindNoteContext2 = _interopRequireDefault(_mindNoteContext);

var _MindNoteContext = __webpack_require__(1619);

var _sync = __webpack_require__(140);

var _error = __webpack_require__(1812);

var _async = __webpack_require__(3013);

var _moirae = __webpack_require__(378);

var _moirae2 = _interopRequireDefault(_moirae);

var _moirae3 = __webpack_require__(2043);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var CLIENT_VARS = exports.CLIENT_VARS = 'MINDNOTE_CLIENT_VARS';
var ReadyState = exports.ReadyState = undefined;
(function (ReadyState) {
    ReadyState[ReadyState["READY"] = 0] = "READY";
    ReadyState[ReadyState["SUBMITTING"] = 1] = "SUBMITTING";
})(ReadyState || (exports.ReadyState = ReadyState = {}));
/**
 * 头像的type
 */
var MEMBER_TYPE = 'MindNote';
/**
 * 本地与服务端版本最大差值，超过则提示刷新
 */
var MISS_VERSION_THRESHOLD = 100;
/**
 * 发送 userChange 与 cursorInfo 的节流时间，毫秒
 */
var REQUEST_THROTTLE_TIME = 300;

var Sync = function () {
    function Sync(props) {
        var _this = this;

        (0, _classCallCheck3.default)(this, Sync);

        this.io = (0, _io2.IOCreator)().getInstance({});
        this.mindNoteContext = _mindNoteContext2.default.getInstance();
        /**
         * 当前文档的版本
         * @description 远端存储的 changset 记录的版本为应用之后文档的版本，即+1
         */
        this.version = -1;
        /**
         * 当前网络通道的状态
         */
        this.readyState = ReadyState.READY;
        /**
         * Changeset 缓存池，缓存发出去但还没有收到 ACK 的 Changeset
         * @description 当发送出一组 Changeset 后，需先进入缓存池，若 ACK 中有超前的版本，需与缓存池中的 Changeset 做OT
         */
        this.changesetCache = [];
        /**
         * 待发送的 Changeset
         * @description 当一组 Changeset 发送到服务端还未收到 ACK 时，这时不允许发送新的 Changeset，需先进入缓冲池，待 ACK 收到时再发送。
         */
        this.changesetQueue = [];
        /**
         * 是否收到了 clientVars
         * @description 收到 clientVars 之前，不要更新心跳版本
         */
        this.receivedClientVars = false;
        /**
         * IO 层有个问题，若通过文档 token 进入页面，则会触发两次watch，IO 层每次连接的时候，内部会触发一次 watch
         */
        this.isWatched = false;
        /**
         * 处理远端的消息
         */
        this.handleMessage = function (message) {
            var data = message.data;
            switch (data.type) {
                case _types.MessageType.NEW_CHANGES:
                    /* 若字段为0，则代表没有溢出 */
                    if (data.over_size === 0) {
                        _this.handleNewChange(data);
                    } else {
                        _this.fetchMissChangsets(_this.version + 1, data.version);
                    }
                    break;
                case _types.MessageType.ENGAGEMENT_CURSOR:
                    _this.mindNoteContext.trigger(_MindNoteContext.MindNoteEvent.CURSOR_SERVER, data);
                    break;
                case _types.MessageType.USER_NEWINFO:
                    var entities = data.entities,
                        _data = (0, _objectWithoutProperties3.default)(data, ['entities']);

                    var users = (0, _get3.default)(entities, 'users', {});
                    var userInfo = Object.assign(_data, users[_data.user_id]);
                    (0, _memberHelper.handleUserNewInfo)(MEMBER_TYPE, userInfo);
                    _this.syncMemberBaseRev(data.version);
                    _this.mindNoteContext.trigger(_MindNoteContext.MindNoteEvent.USER_ENTER, userInfo);
                    break;
                case _types.MessageType.USER_LEAVE:
                    (0, _memberHelper.handleUserLeave)(MEMBER_TYPE, data);
                    _this.syncMemberBaseRev(data.version);
                    _this.mindNoteContext.trigger(_MindNoteContext.MindNoteEvent.USER_LEAVE, data);
                    break;
                default:
                    break;
            }
        };
        /**
         * Watch 成功之后再拉取 members 信息
         */
        this.handleAcceptWatch = function (ack) {
            if (!_this.isWatched) {
                _this.fetchRoomMembers();
                _this.isWatched = true;
            }
        };
        /**
         * 收到远端新 Change 消息
         * @description 由于上行消息和下行的消息都用了统一的格式，所以ops里面会是一个数组，在远端主动推送中，理论上ops中只有一个
         * 元素，外层version和op的version也是唯一对其的，如果有例外，则是后端的BUG
         */
        this.handleNewChange = function (data) {
            /* 若此条消息版本已经过时，则丢弃 */
            if (data.version <= _this.version) {
                return;
            } else if (data.version === _this.version + 1) {
                /* 若此条消息的版本与当前版本连续，则直接应用 */
                _this.apply(data.ops[0].operations);
            } else if (data.version > _this.version + 1) {
                /* 若版本超出了连续的值，值需要拉取缺失的版本 */
                _this.fetchMissChangsets(_this.version + 1, data.version);
            }
        };
        /**
         * 客户端产生编辑消息
         * @param 被转换后的 ops
         */
        this.handleClientChange = function (ops) {
            /**
             * 先压如缓冲队列而不是缓存队列
             * @description 此处发送的时候需要 compose 聚合一次，90%以上的情况可能都是 update 操作
             */
            _this.changesetQueue = _bytedOtJson2.default.compose(_this.changesetQueue, ops);
            /* 然后再尝试冲洗 */
            _this.flush();
        };
        /**
         * 客户端产生光标消息
         * @param cursorInfo 光标信息
         */
        this.handleClientCursor = function (cursorInfo) {
            var cursorRequest = {
                type: _types.MessageType.ENGAGEMENT_CURSOR,
                token: _this.props.objToken,
                memberId: _this.getMemberId(),
                cursor_info: cursorInfo,
                user_id: _this.props.userId
            };
            _this.request(cursorRequest, _io.Channel.socket);
        };
        /**
         * 处理 engine 心跳信息
         */
        this.handleEngineChannelMessage = function (version, oldVersion) {
            /* 如果没有收到clientVars的时候不处理 */
            if (!_this.receivedClientVars) {
                return;
            }
            // 本地与服务端版本差异过大，提示刷新
            if (version - oldVersion > MISS_VERSION_THRESHOLD) {
                _this.mindNoteContext.trigger(_MindNoteContext.MindNoteEvent.ERROR, {
                    code: _error.ClientErrorCode.REVISION_MAX_GAP_EXCEED,
                    type: _error.ErrorType.COLLABORATION_ERROR
                });
                return;
            }
            _this.fetchMissChangsets(_this.version + 1, version);
        };
        /**
         * 处理 member 心跳信息
         */
        this.handleMemberChannelMessage = function () {
            _this.fetchRoomMembers();
        };
        this.props = props;
        this.entity = {
            type: _types.EngineType.MIND_NOTE,
            token: props.objToken
        };
    }
    /**
     * 启动 Sync 层，注册 IO 通道，拉取并返回 ClientVars
     * @async
     */


    (0, _createClass3.default)(Sync, [{
        key: 'start',
        value: function () {
            var _ref = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee() {
                var clientVars, clientVarsRequest;
                return _regenerator2.default.wrap(function _callee$(_context) {
                    while (1) {
                        switch (_context.prev = _context.next) {
                            case 0:
                                /* 注册 IO 层 */
                                this.io.watch(this.entity);
                                this.io.register(this.entity, {
                                    message: {
                                        handler: this.handleMessage,
                                        filter: this.entity
                                    },
                                    heartbeats: Object.assign({}, (0, _sync.getHeartbeatsOption)(), {
                                        engine_channel: {
                                            callback: this.handleEngineChannelMessage
                                        },
                                        member_channel: {
                                            callback: this.handleMemberChannelMessage
                                        }
                                    }),
                                    acceptWatchHandler: this.handleAcceptWatch
                                });
                                /* 注册默认版本号，用于初始化判定 */
                                this.syncEngineBaseRev(-1);
                                /* 注册客户端操作事件 */
                                this.mindNoteContext.bind(_MindNoteContext.MindNoteEvent.CHANGE_CLIENT, this.handleClientChange);
                                this.mindNoteContext.bind(_MindNoteContext.MindNoteEvent.CURSOR_CLIENT, this.handleClientCursor);
                                /* 从模板里尝试获取 clientVars */
                                clientVars = (0, _get3.default)(window, ['DATA', 'clientVars', 'data']);

                                if (clientVars) {
                                    _context.next = 13;
                                    break;
                                }

                                clientVarsRequest = {
                                    type: _types.MessageType.CLIENT_VARS,
                                    token: this.props.objToken
                                };
                                _context.next = 10;
                                return this.request(clientVarsRequest);

                            case 10:
                                clientVars = _context.sent;
                                _context.next = 14;
                                break;

                            case 13:
                                (0, _unset3.default)(window, ['DATA', 'clientVars']);

                            case 14:
                                /* 记录当前文档的版本 */
                                this.version = clientVars.version;
                                /* 设置收到 clientVars 标志 */
                                this.receivedClientVars = true;
                                /* 设置心跳版本 */
                                this.syncEngineBaseRev(this.version);
                                return _context.abrupt('return', clientVars);

                            case 18:
                            case 'end':
                                return _context.stop();
                        }
                    }
                }, _callee, this);
            }));

            function start() {
                return _ref.apply(this, arguments);
            }

            return start;
        }()
        /**
         * 注销 IO 通道，并发送 Unwatch 操作
         * @async
         */

    }, {
        key: 'stop',
        value: function () {
            var _ref2 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee2() {
                return _regenerator2.default.wrap(function _callee2$(_context2) {
                    while (1) {
                        switch (_context2.prev = _context2.next) {
                            case 0:
                                /* 注销 IO 通道 */
                                this.io.unRegister(this.entity);
                                /* 注销客户端事件 */
                                this.mindNoteContext.unbind(_MindNoteContext.MindNoteEvent.CHANGE_CLIENT, this.handleClientChange);
                                this.mindNoteContext.unbind(_MindNoteContext.MindNoteEvent.CURSOR_CLIENT, this.handleClientCursor);
                                // 重置协作者列表
                                (0, _memberHelper.handleResetMembers)(MEMBER_TYPE, this.entity.token);

                            case 4:
                            case 'end':
                                return _context2.stop();
                        }
                    }
                }, _callee2, this);
            }));

            function stop() {
                return _ref2.apply(this, arguments);
            }

            return stop;
        }()
        /**
         * 获取 IO memberId
         */

    }, {
        key: 'getMemberId',
        value: function getMemberId() {
            if (this._memberId) return this._memberId;
            if (!this.io.getMemberId()) {
                console.info('-----随机_memberId');
                this._memberId = (0, _util.getDeviceId)(new Date().valueOf());
                return this._memberId;
            }
            this._memberId = this.io.getMemberId();
            return this._memberId;
        }
        /**
         * 请求消息，并效验返回的状态码
         * @param data 请求消息体
         * @param channel 消息通道，默认为 http
         * @async
         */

    }, {
        key: 'request',
        value: function () {
            var _ref3 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee3(data) {
                var channel = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : _io.Channel.http;
                var response;
                return _regenerator2.default.wrap(function _callee3$(_context3) {
                    while (1) {
                        switch (_context3.prev = _context3.next) {
                            case 0:
                                _context3.prev = 0;

                                // 统计请求次数，用于计算失败率
                                _moirae2.default.count(_moirae3.MoiraeKeys.SYNC_REQUEST);
                                _context3.next = 4;
                                return this.autoRetryRequest(data, channel);

                            case 4:
                                response = _context3.sent;

                                if (!(response.code !== 0 || response.data.code !== _types.StatusCode.SUCCESS)) {
                                    _context3.next = 7;
                                    break;
                                }

                                throw response;

                            case 7:
                                (0, _hideLoadingHelper.hideLoading)();
                                return _context3.abrupt('return', response.data);

                            case 11:
                                _context3.prev = 11;
                                _context3.t0 = _context3['catch'](0);

                                // 统计请求失败次数
                                _moirae2.default.count(_moirae3.MoiraeKeys.SYNC_REQUEST_FAILED);
                                _moirae2.default.ravenCatch(_context3.t0);
                                this.mindNoteContext.trigger(_MindNoteContext.MindNoteEvent.ERROR, {
                                    type: _error.ErrorType.SERVER_ERROR,
                                    code: _context3.t0.code
                                });
                                (0, _hideLoadingHelper.hideLoading)();
                                console.log(_context3.t0);
                                throw new Error(_context3.t0.msg);

                            case 19:
                            case 'end':
                                return _context3.stop();
                        }
                    }
                }, _callee3, this, [[0, 11]]);
            }));

            function request(_x) {
                return _ref3.apply(this, arguments);
            }

            return request;
        }()
        /**
         * 自动重试请求
         * @param data 请求数据
         * @param channel 请求通道
         * @param retry 重试次数
         * @description Pandora 中有些错误码是需要自动重试的，这里枚举了所有需要重试的错误码进行重试操作
         */

    }, {
        key: 'requestByhttp',
        value: function requestByhttp(payload) {
            var memberId = this.getMemberId();
            this.promise = (0, _offlineEditHelper.fetch)(_$constants.apiUrls.POST_RCE_MESSAGE + '?member_id=' + memberId, {
                key: CLIENT_VARS,
                headers: (0, _defineProperty3.default)({
                    'Content-Type': 'application/json'
                }, _sliApiMap.X_COMMAND, _sliApiMap.API_RCE_PANDORA),
                priority: 9,
                noStore: true,
                readStore: true,
                body: {
                    type: payload.type,
                    data: Object.assign({}, payload.data, {
                        member_id: memberId,
                        user_ticket: this.io.getTicket(),
                        base_rev: 0
                    }),
                    version: payload.version || 0,
                    req_id: payload.req_id || 1
                }
            });
            return this.promise;
        }
    }, {
        key: 'autoRetryRequest',
        value: function () {
            var _ref4 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee4(data) {
                var channel = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : _io.Channel.http;
                var retry = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : 3;
                var response;
                return _regenerator2.default.wrap(function _callee4$(_context4) {
                    while (1) {
                        switch (_context4.prev = _context4.next) {
                            case 0:
                                response = void 0;

                                if (!(channel === _io.Channel.socket)) {
                                    _context4.next = 7;
                                    break;
                                }

                                _context4.next = 4;
                                return this.io.request({
                                    type: _types.EngineType.MIND_NOTE,
                                    data: data
                                });

                            case 4:
                                response = _context4.sent;
                                _context4.next = 10;
                                break;

                            case 7:
                                _context4.next = 9;
                                return this.requestByhttp({
                                    type: _types.EngineType.MIND_NOTE,
                                    data: data
                                });

                            case 9:
                                response = _context4.sent;

                            case 10:
                                if (!(retry <= 0)) {
                                    _context4.next = 12;
                                    break;
                                }

                                return _context4.abrupt('return', response);

                            case 12:
                                if (!(response.code === _types.StatusCode.SERVICE_ERROR || response.code === _types.StatusCode.SERVER_BUSY || response.data.code === _types.StatusCode.SERVICE_ERROR || response.data.code === _types.StatusCode.SERVER_BUSY || response.data.code === _types.StatusCode.DATABASE_CONFLICT)) {
                                    _context4.next = 16;
                                    break;
                                }

                                _context4.next = 15;
                                return (0, _async.sleep)(3 / retry * 1000);

                            case 15:
                                return _context4.abrupt('return', this.autoRetryRequest(data, _io.Channel.http, retry - 1));

                            case 16:
                                return _context4.abrupt('return', response);

                            case 17:
                            case 'end':
                                return _context4.stop();
                        }
                    }
                }, _callee4, this);
            }));

            function autoRetryRequest(_x3) {
                return _ref4.apply(this, arguments);
            }

            return autoRetryRequest;
        }()
        /**
         * 冲洗缓冲区和缓存区，检查当前缓存的 op 状态，并发送给服务端
         * @description 注意 flush 操作中如果要修改逻辑则一定要确认不会被 throttle 影响，目前 flush 操作一定是保证上一次
         * flush 完成时才会触发第二次逻辑，所以 throttle 本身不会影响 flush
         * @async
         */

    }, {
        key: 'flush',
        value: function () {
            var _ref5 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee5() {
                var userChangeRequest, data;
                return _regenerator2.default.wrap(function _callee5$(_context5) {
                    while (1) {
                        switch (_context5.prev = _context5.next) {
                            case 0:
                                if (!(this.changesetQueue.length > 0 && this.readyState === ReadyState.READY)) {
                                    _context5.next = 10;
                                    break;
                                }

                                /* 更新状态 */
                                this.readyState = ReadyState.SUBMITTING;
                                /* 派发事件 */
                                this.mindNoteContext.trigger(_MindNoteContext.MindNoteEvent.SAVING);
                                this.changesetCache = this.changesetQueue;
                                this.changesetQueue = [];
                                /* 发送消息 */
                                userChangeRequest = {
                                    type: _types.MessageType.USER_CHANGES,
                                    token: this.props.objToken,
                                    operations: (0, _cloneDeep3.default)(this.changesetCache),
                                    version: this.version
                                };
                                _context5.next = 8;
                                return this.request(userChangeRequest, _io.Channel.socket);

                            case 8:
                                data = _context5.sent;

                                /* 若版本号连续，则接受 */
                                if (data.version === this.version + 1) {
                                    this.accept();
                                    /* 若版本号超出，则拉取缺失的changeset */
                                } else if (data.version > this.version + 1) {
                                    this.fetchMissChangsets(this.version + 1, data.version);
                                }

                            case 10:
                            case 'end':
                                return _context5.stop();
                        }
                    }
                }, _callee5, this);
            }));

            function flush() {
                return _ref5.apply(this, arguments);
            }

            return flush;
        }()
        /**
         * 成功收到 ACK
         */

    }, {
        key: 'accept',
        value: function accept() {
            /* 更新状态 */
            this.readyState = ReadyState.READY;
            /* 派发事件 */
            this.mindNoteContext.trigger(_MindNoteContext.MindNoteEvent.SAVED);
            /* 清空缓存队列 */
            this.changesetCache = [];
            /* 版本+1 */
            this.version = this.version + 1;
            /* 更新心跳版本 */
            this.syncEngineBaseRev(this.version);
            /* 接收后继续尝试冲洗 */
            this.flush();
        }
        /**
         * 转换 ops
         * @param localOps 客户端产生的 ops
         * @param serverOps 服务端发来的 ops
         * @description
         * server = apply(apply(initial, serverOps), transform(localOps, serverOps, left))
         * local = apply(apply(initial, localOps), transform(serverOps, localOps, right))
         * 最终, server === local
         * 即:
         * applyToServer = transform(localOps, serverOps, left)
         * applyToLocal = transform(serverOps, localOps, right)
         */

    }, {
        key: 'transform',
        value: function transform(localOps, serverOps) {
            try {
                return {
                    /**
                     * 要在远端运用的 ops
                     */
                    applyToServer: _bytedOtJson2.default.transform(localOps, serverOps, _bytedOtJson.TransformType.LEFT),
                    /**
                     * 要在本地运用的 ops
                     */
                    applyToLocal: _bytedOtJson2.default.transform(serverOps, localOps, _bytedOtJson.TransformType.RIGHT)
                };
            } catch (err) {
                // 统计 transform 失败次数
                _moirae2.default.count(_moirae3.MoiraeKeys.TRANSFORM_FAILED);
                _moirae2.default.ravenCatch(err);
                this.mindNoteContext.trigger(_MindNoteContext.MindNoteEvent.ERROR, {
                    type: _error.ErrorType.COLLABORATION_ERROR,
                    code: _error.ClientErrorCode.TRANSFORM_FAILED
                });
                throw err;
            }
        }
        /**
         * 应用一组 Changeset
         * @param ops 应用的 ops
         */

    }, {
        key: 'apply',
        value: function apply(ops) {
            var serverOps = ops;
            // 转换 cache ops
            var res = this.transform(this.changesetCache, serverOps);
            this.changesetCache = res.applyToServer;
            serverOps = res.applyToLocal;
            // 转换 queue ops
            res = this.transform(this.changesetQueue, serverOps);
            this.changesetQueue = res.applyToServer;
            serverOps = res.applyToLocal;
            /* 抛出change事件 */
            this.mindNoteContext.trigger(_MindNoteContext.MindNoteEvent.CHANGE_SERVER, serverOps);
            /* 版本+1 */
            this.version = this.version + 1;
            /* 更新心跳版本 */
            this.syncEngineBaseRev(this.version);
        }
        /**
         * 更新 engine_channel 心跳版本
         * @param revision 新版本号
         */

    }, {
        key: 'syncEngineBaseRev',
        value: function syncEngineBaseRev(revision) {
            this.syncBaseRev(_types.MessageChannel.ENGINE_CHANNEL, revision);
        }
        /**
         * 更新 member_channel 心跳版本
         * @param revision 新版本号
         */

    }, {
        key: 'syncMemberBaseRev',
        value: function syncMemberBaseRev(revision) {
            var _entity = this.entity,
                type = _entity.type,
                token = _entity.token;

            var entityHeartbeat = this.io.getHeartbeatInfo(type, token) || {};
            var memberHeartBeat = entityHeartbeat.member_channel;
            if (!memberHeartBeat) return;
            var curVersion = memberHeartBeat.version;
            var nextVersion = curVersion + 1;
            if (revision === nextVersion) {
                this.syncBaseRev(_types.MessageChannel.MEMBER_CHANNEL, revision);
                return;
            }
            /**
             * 人数超过 150 人，就延后到心跳时去拉
             * 避免出现极端情况下频繁拉取，把后台拉挂
             */
            var members = (0, _memberHelper.getSuiteMembers)(type, token);
            if (revision > nextVersion && members.length < 150) {
                this.fetchRoomMembers();
            }
        }
        /**
         * 更新 channel 心跳版本
         * @param channel channel
         * @param revision 新版本号
         */

    }, {
        key: 'syncBaseRev',
        value: function syncBaseRev(channel, revision) {
            /* 未收到ClientVar，且版本不是初始化标志版本，则不更新 */
            if (!this.receivedClientVars && revision !== -1) {
                return;
            }
            var _entity2 = this.entity,
                type = _entity2.type,
                token = _entity2.token;

            this.io.setHeartbeatVersion({ type: type, token: token }, channel, revision);
        }
        /**
         * 获取房间成员
         * @async
         */

    }, {
        key: 'fetchRoomMembers',
        value: function () {
            var _ref6 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee6() {
                var data, response, users, members;
                return _regenerator2.default.wrap(function _callee6$(_context6) {
                    while (1) {
                        switch (_context6.prev = _context6.next) {
                            case 0:
                                _context6.prev = 0;
                                data = {
                                    type: _types.MessageType.MESSAGE_CHANNEL,
                                    name: _types.MessageChannel.MEMBER_CHANNEL,
                                    token: this.props.objToken
                                };
                                /* 异步获取 */

                                _context6.next = 4;
                                return this.request(data);

                            case 4:
                                response = _context6.sent;
                                users = response.entities.users;
                                /* 后端返回的 member 数据不一致，这里要把数据 merge 一下 */

                                members = (0, _map3.default)(response.members, function (memberInfo) {
                                    return Object.assign({}, memberInfo, users[memberInfo.user_id]);
                                });
                                /* 这里会交给 member 相关的 action 处理 */

                                (0, _memberHelper.handleMembersMessage)(MEMBER_TYPE, {
                                    token: response.token,
                                    members: members
                                });
                                /* 更新心跳版本 */
                                this.syncBaseRev(_types.MessageChannel.MEMBER_CHANNEL, response.version);
                                _context6.next = 15;
                                break;

                            case 11:
                                _context6.prev = 11;
                                _context6.t0 = _context6['catch'](0);

                                this.mindNoteContext.trigger(_MindNoteContext.MindNoteEvent.ERROR, {
                                    type: _error.ErrorType.RESPONSE_ERROR,
                                    code: _types.StatusCode.FAILED
                                });
                                console.error(_context6.t0);

                            case 15:
                            case 'end':
                                return _context6.stop();
                        }
                    }
                }, _callee6, this, [[0, 11]]);
            }));

            function fetchRoomMembers() {
                return _ref6.apply(this, arguments);
            }

            return fetchRoomMembers;
        }()
        /**
         * 拉取缺失的 Changesets
         * @param from 起始版本，起始版本应该为当前 version + 1
         * @param to 终止版本
         * @description 默认我们在调用中，拉取的 ops 中的 version 最小值应该不大于当前的 version + 1
         * @async
         */

    }, {
        key: 'fetchMissChangsets',
        value: function () {
            var _ref7 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee7(from, to) {
                var _this2 = this;

                var data, response;
                return _regenerator2.default.wrap(function _callee7$(_context7) {
                    while (1) {
                        switch (_context7.prev = _context7.next) {
                            case 0:
                                data = {
                                    type: _types.MessageType.NEW_CHANGES,
                                    token: this.props.objToken,
                                    rev_list: [from + '-' + to]
                                };
                                // 打点统计 fetch miss 次数

                                _moirae2.default.count(_moirae3.MoiraeKeys.FETCH_MISS_CHANGESET);
                                _context7.next = 4;
                                return this.request(data);

                            case 4:
                                response = _context7.sent;

                                /* 应用 changesets */
                                (0, _forEach3.default)(response.ops, function (changeset) {
                                    if (changeset.version === _this2.version + 1) {
                                        /* 有逻辑的操作全部转成string，防止number与string不兼容 */
                                        if (changeset.member_id + '' === _this2.getMemberId() + '') {
                                            /* 接收ACK */
                                            _this2.accept();
                                        } else {
                                            _this2.apply(changeset.operations || []);
                                        }
                                    }
                                });

                            case 6:
                            case 'end':
                                return _context7.stop();
                        }
                    }
                }, _callee7, this);
            }));

            function fetchMissChangsets(_x6, _x7) {
                return _ref7.apply(this, arguments);
            }

            return fetchMissChangsets;
        }()
    }]);
    return Sync;
}();

exports.default = Sync;

/***/ }),

/***/ 3012:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _baseUnset_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(2070);


/**
 * Removes the property at `path` of `object`.
 *
 * **Note:** This method mutates `object`.
 *
 * @static
 * @memberOf _
 * @since 4.0.0
 * @category Object
 * @param {Object} object The object to modify.
 * @param {Array|string} path The path of the property to unset.
 * @returns {boolean} Returns `true` if the property is deleted, else `false`.
 * @example
 *
 * var object = { 'a': [{ 'b': { 'c': 7 } }] };
 * _.unset(object, 'a[0].b.c');
 * // => true
 *
 * console.log(object);
 * // => { 'a': [{ 'b': {} }] };
 *
 * _.unset(object, ['a', '0', 'b', 'c']);
 * // => true
 *
 * console.log(object);
 * // => { 'a': [{ 'b': {} }] };
 */
function unset(object, path) {
  return object == null ? true : Object(_baseUnset_js__WEBPACK_IMPORTED_MODULE_0__[/* default */ "a"])(object, path);
}

/* harmony default export */ __webpack_exports__["default"] = (unset);


/***/ }),

/***/ 3013:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.sleep = sleep;
/**
 * 睡眠操作
 * @param 睡眠时间（单位：ms）
 */
function sleep(time) {
    return new Promise(function (resolve) {
        setTimeout(function () {
            resolve();
        }, time);
    });
}

/***/ }),

/***/ 3014:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _baseAssignValue_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(516);
/* harmony import */ var _baseForOwn_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(341);
/* harmony import */ var _baseIteratee_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(186);




/**
 * Creates an object with the same keys as `object` and values generated
 * by running each own enumerable string keyed property of `object` thru
 * `iteratee`. The iteratee is invoked with three arguments:
 * (value, key, object).
 *
 * @static
 * @memberOf _
 * @since 2.4.0
 * @category Object
 * @param {Object} object The object to iterate over.
 * @param {Function} [iteratee=_.identity] The function invoked per iteration.
 * @returns {Object} Returns the new mapped object.
 * @see _.mapKeys
 * @example
 *
 * var users = {
 *   'fred':    { 'user': 'fred',    'age': 40 },
 *   'pebbles': { 'user': 'pebbles', 'age': 1 }
 * };
 *
 * _.mapValues(users, function(o) { return o.age; });
 * // => { 'fred': 40, 'pebbles': 1 } (iteration order is not guaranteed)
 *
 * // The `_.property` iteratee shorthand.
 * _.mapValues(users, 'age');
 * // => { 'fred': 40, 'pebbles': 1 } (iteration order is not guaranteed)
 */
function mapValues(object, iteratee) {
  var result = {};
  iteratee = Object(_baseIteratee_js__WEBPACK_IMPORTED_MODULE_2__[/* default */ "a"])(iteratee, 3);

  Object(_baseForOwn_js__WEBPACK_IMPORTED_MODULE_1__[/* default */ "a"])(object, function(value, key, object) {
    Object(_baseAssignValue_js__WEBPACK_IMPORTED_MODULE_0__[/* default */ "a"])(result, key, iteratee(value, key, object));
  });
  return result;
}

/* harmony default export */ __webpack_exports__["default"] = (mapValues);


/***/ }),

/***/ 3015:
/***/ (function(module, exports, __webpack_require__) {

/* WEBPACK VAR INJECTION */(function(global) {var __WEBPACK_AMD_DEFINE_FACTORY__, __WEBPACK_AMD_DEFINE_ARRAY__, __WEBPACK_AMD_DEFINE_RESULT__;(function(a,b){if(true)!(__WEBPACK_AMD_DEFINE_ARRAY__ = [], __WEBPACK_AMD_DEFINE_FACTORY__ = (b),
				__WEBPACK_AMD_DEFINE_RESULT__ = (typeof __WEBPACK_AMD_DEFINE_FACTORY__ === 'function' ?
				(__WEBPACK_AMD_DEFINE_FACTORY__.apply(exports, __WEBPACK_AMD_DEFINE_ARRAY__)) : __WEBPACK_AMD_DEFINE_FACTORY__),
				__WEBPACK_AMD_DEFINE_RESULT__ !== undefined && (module.exports = __WEBPACK_AMD_DEFINE_RESULT__));else {}})(this,function(){"use strict";function b(a,b){return"undefined"==typeof b?b={autoBom:!1}:"object"!=typeof b&&(console.warn("Depricated: Expected third argument to be a object"),b={autoBom:!b}),b.autoBom&&/^\s*(?:text\/\S*|application\/xml|\S*\/\S*\+xml)\s*;.*charset\s*=\s*utf-8/i.test(a.type)?new Blob(["\uFEFF",a],{type:a.type}):a}function c(b,c,d){var e=new XMLHttpRequest;e.open("GET",b),e.responseType="blob",e.onload=function(){a(e.response,c,d)},e.onerror=function(){console.error("could not download file")},e.send()}function d(a){var b=new XMLHttpRequest;return b.open("HEAD",a,!1),b.send(),200<=b.status&&299>=b.status}function e(a){try{a.dispatchEvent(new MouseEvent("click"))}catch(c){var b=document.createEvent("MouseEvents");b.initMouseEvent("click",!0,!0,window,0,0,0,80,20,!1,!1,!1,!1,0,null),a.dispatchEvent(b)}}var f="object"==typeof window&&window.window===window?window:"object"==typeof self&&self.self===self?self:"object"==typeof global&&global.global===global?global:void 0,a=f.saveAs||"object"!=typeof window||window!==f?function(){}:"download"in HTMLAnchorElement.prototype?function(b,g,h){var i=f.URL||f.webkitURL,j=document.createElement("a");g=g||b.name||"download",j.download=g,j.rel="noopener","string"==typeof b?(j.href=b,j.origin===location.origin?e(j):d(j.href)?c(b,g,h):e(j,j.target="_blank")):(j.href=i.createObjectURL(b),setTimeout(function(){i.revokeObjectURL(j.href)},4E4),setTimeout(function(){e(j)},0))}:"msSaveOrOpenBlob"in navigator?function(f,g,h){if(g=g||f.name||"download","string"!=typeof f)navigator.msSaveOrOpenBlob(b(f,h),g);else if(d(f))c(f,g,h);else{var i=document.createElement("a");i.href=f,i.target="_blank",setTimeout(function(){e(i)})}}:function(a,b,d,e){if(e=e||open("","_blank"),e&&(e.document.title=e.document.body.innerText="downloading..."),"string"==typeof a)return c(a,b,d);var g="application/octet-stream"===a.type,h=/constructor/i.test(f.HTMLElement)||f.safari,i=/CriOS\/[\d]+/.test(navigator.userAgent);if((i||g&&h)&&"object"==typeof FileReader){var j=new FileReader;j.onloadend=function(){var a=j.result;a=i?a:a.replace(/^data:[^;]*;/,"data:attachment/file;"),e?e.location.href=a:location=a,e=null},j.readAsDataURL(a)}else{var k=f.URL||f.webkitURL,l=k.createObjectURL(a);e?e.location=l:location.href=l,e=null,setTimeout(function(){k.revokeObjectURL(l)},4E4)}};f.saveAs=a.saveAs=a,"undefined"!=typeof module&&(module.exports=a)});

//# sourceMappingURL=FileSaver.min.js.map
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(84)))

/***/ }),

/***/ 3016:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _ErrorHandler = __webpack_require__(3017);

var _ErrorHandler2 = _interopRequireDefault(_ErrorHandler);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = _ErrorHandler2.default;

/***/ }),

/***/ 3017:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _bytedSpark = __webpack_require__(1680);

var _toast = __webpack_require__(500);

var _toast2 = _interopRequireDefault(_toast);

var _MindNoteContext = __webpack_require__(1619);

var _types = __webpack_require__(2044);

var _manager = __webpack_require__(3018);

var _type = __webpack_require__(2045);

__webpack_require__(3020);

var _modalHelper = __webpack_require__(722);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var TOAST_KEY = '__mindnote_net_state__';
var CLASS_PREFIX = 'mindnote-error-handler';

var ErrorHandler = function (_React$PureComponent) {
    (0, _inherits3.default)(ErrorHandler, _React$PureComponent);

    function ErrorHandler(props) {
        (0, _classCallCheck3.default)(this, ErrorHandler);

        var _this = (0, _possibleConstructorReturn3.default)(this, (ErrorHandler.__proto__ || Object.getPrototypeOf(ErrorHandler)).call(this, props));

        _this.state = {
            visiable: false,
            config: {
                title: '',
                message: '',
                buttons: []
            }
        };
        _this.offlineHandler = function () {
            _toast2.default.error({
                key: TOAST_KEY,
                closable: true,
                /* 不自动关闭 */
                duration: 0,
                content: t('common.disconnected_tips')
            });
        };
        _this.onlineHandler = function () {
            _toast2.default.remove(TOAST_KEY);
        };
        _this.errorHandler = function (error) {
            var config = (0, _manager.getErrorAlertConfig)(error);
            switch (config.type) {
                // 弹窗
                case _types.ErrorAlertType.DIALOG:
                    {
                        var btns = [];
                        config.buttons.forEach(function (item) {
                            var obj = {
                                text: item.text,
                                onPress: item.onClick
                            };
                            btns.push(obj);
                        });
                        (0, _modalHelper.showAlert)(config.title, config.message, btns);
                        break;
                    }
                // toast 提醒
                case _types.ErrorAlertType.TOAST:
                    {
                        _this.showToast(config.title);
                        break;
                    }
                default:
                    {
                        (0, _type.assertNever)(config.type);
                        break;
                    }
            }
        };
        _this.closeDialog = function () {
            _this.setState({
                visiable: false
            });
        };
        _this.bindEvents();
        return _this;
    }

    (0, _createClass3.default)(ErrorHandler, [{
        key: 'componentWillUnmount',
        value: function componentWillUnmount() {
            this.unbindEvents();
        }
    }, {
        key: 'bindEvents',
        value: function bindEvents() {
            this.props.context.bind(_MindNoteContext.MindNoteEvent.ERROR, this.errorHandler);
            window.addEventListener('offline', this.offlineHandler);
            window.addEventListener('online', this.onlineHandler);
        }
    }, {
        key: 'unbindEvents',
        value: function unbindEvents() {
            this.props.context.unbind(_MindNoteContext.MindNoteEvent.ERROR, this.errorHandler);
            window.removeEventListener('offline', this.offlineHandler);
            window.removeEventListener('online', this.onlineHandler);
        }
    }, {
        key: 'getButtonClickHandler',
        value: function getButtonClickHandler(onClick) {
            var _this2 = this;

            if (!onClick) {
                return this.closeDialog;
            }
            return function () {
                var result = onClick();
                /* 返回 false 则不关闭弹窗，默认关闭 */
                if (result !== false) {
                    _this2.closeDialog();
                }
            };
        }
    }, {
        key: 'showToast',
        value: function showToast(text) {
            _toast2.default.error({
                content: text
            });
        }
    }, {
        key: 'renderFooter',
        value: function renderFooter(buttons) {
            var _this3 = this;

            return _react2.default.createElement("div", { className: CLASS_PREFIX + '--footer' }, buttons.map(function (button, index) {
                return _react2.default.createElement(_bytedSpark.Button, { key: index, type: button.type, onClick: _this3.getButtonClickHandler(button.onClick) }, button.text);
            }));
        }
    }, {
        key: 'render',
        value: function render() {
            return null;
            var _state = this.state,
                visiable = _state.visiable,
                config = _state.config;

            var footer = this.renderFooter(config.buttons);
            return _react2.default.createElement(_bytedSpark.Dialog, { className: CLASS_PREFIX, visible: visiable, title: config.title, onClose: this.closeDialog, footer: footer, center: true, escCancel: false, closeble: false, maskClick: false, width: 400, zIndex: 3000 }, config.message);
        }
    }]);
    return ErrorHandler;
}(_react2.default.PureComponent);

exports.default = ErrorHandler;
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3018:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.getErrorAlertConfig = getErrorAlertConfig;

var _types = __webpack_require__(2042);

var _error = __webpack_require__(1812);

var _types2 = __webpack_require__(2044);

var _feedbackHelper = __webpack_require__(3019);

/**
 * 弹窗标题
 */
var ErrorTitle = {
    SERVER_ERROR: t('error.server'),
    PERMISSION_ERROR: t('error.no_permission'),
    COLLABORATION_ERROR: t('common.prompt'),
    MODEL_ERROR: t('common.prompt'),
    NET_ERROR: t('mindnote.network_abnormal'),
    UNKNOWN_ERROR: t('request.unknown_mistake'),
    COMMON_ERROR: t('common.prompt')
};
/**
 * 刷新按钮，严重错误必须刷新网页
 */
var RELOAD_BUTTON = {
    text: t('common.confirm'),
    type: _types2.ButtonType.PRIMARY,
    onClick: function onClick() {
        window.reload();
        return true;
    }
};
/**
 * 联系我们按钮，打开 lark 值班号
 */
var CONTACT_US_BUTTON = {
    text: t('common.contact'),
    type: _types2.ButtonType.DEFAULT,
    onClick: function onClick() {
        (0, _feedbackHelper.clickFeedBack)();
        /* 不用关闭弹窗，方便用户截图 */
        return false;
    }
};
/**
 * 按错误码处理错误
 */
function getErrorConfigByCode(error) {
    switch (error.code) {
        // 权限相关问题
        case _types.StatusCode.COMMENT_PERMISSION_DENIED:
        case _types.StatusCode.WRITE_PERMISSION_DENIED:
        case _types.StatusCode.FORBIDDEN:
        case _types.StatusCode.LOGIN_REQUIRED:
        case _types.StatusCode.NOT_IN_SESSION:
            return {
                type: _types2.ErrorAlertType.DIALOG,
                title: ErrorTitle.PERMISSION_ERROR,
                message: t('mindnote.permission_error', error.code),
                buttons: [RELOAD_BUTTON]
            };
        // 协同相关问题
        case _types.StatusCode.CHAGESET_INVALID:
        case _types.StatusCode.SYNC_FAILED:
        case _types.StatusCode.CHANGESET_LIMIT_EXCEED:
        case _error.ClientErrorCode.APPLY_ACTION_FAILED:
        case _error.ClientErrorCode.INVALID_OPERATION:
            return {
                type: _types2.ErrorAlertType.DIALOG,
                title: ErrorTitle.COLLABORATION_ERROR,
                message: t('mindnote.colla_error', error.code),
                buttons: [RELOAD_BUTTON]
            };
        // 文档被删除
        case _types.StatusCode.OBJECT_DELETED:
        case _types.StatusCode.NOT_FOUND:
            return {
                type: _types2.ErrorAlertType.DIALOG,
                title: ErrorTitle.SERVER_ERROR,
                message: t('mindnote.deleted_tip'),
                buttons: [RELOAD_BUTTON]
            };
        // 客户端版本过旧
        case _types.StatusCode.VERSION_TOO_OLD:
        case _error.ClientErrorCode.REVISION_MAX_GAP_EXCEED:
            return {
                type: _types2.ErrorAlertType.DIALOG,
                title: ErrorTitle.COLLABORATION_ERROR,
                message: t('mindnote.version_too_old'),
                buttons: [RELOAD_BUTTON]
            };
        // 请求超时
        case _error.ClientErrorCode.REQUEST_TIMEOUT:
            return {
                type: _types2.ErrorAlertType.TOAST,
                title: ErrorTitle.NET_ERROR
            };
        // 服务端响应数据异常
        case _error.ClientErrorCode.RESPONSE_INVALID:
            return {
                type: _types2.ErrorAlertType.DIALOG,
                title: ErrorTitle.SERVER_ERROR,
                message: t('mindnote.server_api_error', error.code),
                buttons: [CONTACT_US_BUTTON, RELOAD_BUTTON]
            };
        // model 数据错误
        case _error.ClientErrorCode.RESPONSE_UNEXPECTED:
        case _error.ClientErrorCode.MODEL_INVALID_DATA:
            return {
                type: _types2.ErrorAlertType.DIALOG,
                title: ErrorTitle.MODEL_ERROR,
                message: t('mindnote.server_api_error', error.code),
                buttons: [CONTACT_US_BUTTON, RELOAD_BUTTON]
            };
        // 未知错误码
        case _error.ClientErrorCode.UNKNOWN:
            return {
                type: _types2.ErrorAlertType.DIALOG,
                title: ErrorTitle.UNKNOWN_ERROR,
                message: t('mindnote.unknown_error', error.code),
                buttons: [CONTACT_US_BUTTON, RELOAD_BUTTON]
            };
        default:
            return null;
    }
}
/**
 * 按错误类型处理错误
 */
function getErrorConfigByType(error) {
    switch (error.type) {
        // 服务端错误
        case _error.ErrorType.SERVER_ERROR:
        case _error.ErrorType.RESPONSE_ERROR:
            return {
                type: _types2.ErrorAlertType.DIALOG,
                title: ErrorTitle.SERVER_ERROR,
                message: t('mindnote.server_api_error', error.code),
                buttons: [CONTACT_US_BUTTON, RELOAD_BUTTON]
            };
        // 未知类型错误
        case _error.ErrorType.UNKNOWN:
        default:
            return {
                type: _types2.ErrorAlertType.DIALOG,
                title: ErrorTitle.UNKNOWN_ERROR,
                message: t('mindnote.unknown_error', error.code),
                buttons: [CONTACT_US_BUTTON, RELOAD_BUTTON]
            };
    }
}
function getErrorAlertConfig(error) {
    // 针对错误码的错误处理
    var config = getErrorConfigByCode(error);
    // 按类型错误处理
    if (!config) {
        config = getErrorConfigByType(error);
    }
    return config;
}
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3019:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.clickFeedBack = undefined;

var _bindedActions = __webpack_require__(392);

var _bindedActions2 = _interopRequireDefault(_bindedActions);

var _apiUrls = __webpack_require__(243);

var _toast = __webpack_require__(500);

var _toast2 = _interopRequireDefault(_toast);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var clickFeedBack = exports.clickFeedBack = function clickFeedBack() {
    var concatChatId = _bindedActions2.default.fetchDocsCustomerServiceChatId();
    concatChatId.then(function (res) {
        var chatId = res.payload && res.payload.chat_id;
        location.href = _apiUrls.LARK_CHAT_SCHEMA + chatId;
    }).catch(function (e) {
        _toast2.default.error({
            content: t('feedback.additional_fail')
        });
    });
};
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3020:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3021:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _actionToOperation = __webpack_require__(3022);

Object.keys(_actionToOperation).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _actionToOperation[key];
    }
  });
});

var _operationToAction = __webpack_require__(3023);

Object.keys(_operationToAction).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _operationToAction[key];
    }
  });
});

/***/ }),

/***/ 3022:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _every2 = __webpack_require__(3254);

var _every3 = _interopRequireDefault(_every2);

var _keys2 = __webpack_require__(141);

var _keys3 = _interopRequireDefault(_keys2);

var _forEach2 = __webpack_require__(1627);

var _forEach3 = _interopRequireDefault(_forEach2);

var _map2 = __webpack_require__(1682);

var _map3 = _interopRequireDefault(_map2);

var _isEqual2 = __webpack_require__(301);

var _isEqual3 = _interopRequireDefault(_isEqual2);

var _has2 = __webpack_require__(754);

var _has3 = _interopRequireDefault(_has2);

exports.actionToOperation = actionToOperation;

var _editor = __webpack_require__(1813);

var _type = __webpack_require__(2045);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * 把 action 转为 ot operation
 * @param action action
 * @param model ot model
 * @throws action type 不支持时会抛出错误
 */
function actionToOperation(action, model) {
    switch (action.name) {
        case _editor.Actions.CREATE:
            {
                return createActionToOpeartion(action, model);
            }
        case _editor.Actions.DELETE:
            {
                return deleteActionToOperation(action, model);
            }
        case _editor.Actions.UPDATE:
            {
                return updateActionToOpeartion(action, model);
            }
        case _editor.Actions.STRUCTURE_CHANGE:
            {
                return moveActionToOpeartion(action, model);
            }
        case _editor.Actions.SETTING_CHANGE:
            {
                return settingActionToOperation(action, model);
            }
        default:
            {
                (0, _type.assertNever)(action);
                throw new Error('Unknown action');
            }
    }
}
/**
 * 生成更新 object 的 ot operation
 * @param updated 新 object
 * @param model ot model
 * @param pathPrefix path 前缀
 * @returns oi od operation 数组
 */
function updateObjectHelper(updated, original, pathPrefix) {
    var ops = [];
    // updated key 比对 original key，处理增加的 key
    (0, _forEach3.default)((0, _keys3.default)(updated), function (key) {
        if (!(0, _has3.default)(original, key)) {
            // 新增 key
            ops.push({
                p: pathPrefix.concat([key]),
                action: {
                    oi: updated[key]
                }
            });
        } else if (!(0, _isEqual3.default)(updated[key], original[key])) {
            // 更新 key 值
            ops.push({
                p: pathPrefix.concat([key]),
                action: {
                    od: original[key],
                    oi: updated[key]
                }
            });
        }
    });
    return ops;
}
/**
 * CreateAction 转为 li operation
 * @param action CreateAction
 * @param model ot model
 * @returns li operation 数组
 */
function createActionToOpeartion(action, model) {
    return (0, _map3.default)(action.created, function (nodeSetting) {
        return {
            p: nodeSetting.path,
            action: {
                li: nodeSetting.node
            }
        };
    });
}
/**
 * DeleteAction 转为 ld operation
 * @param action DeleteAction
 * @param model ot model
 * @returns ld operation 数组
 */
function deleteActionToOperation(action, model) {
    return (0, _map3.default)(action.deleted, function (nodeSetting) {
        return {
            p: nodeSetting.path,
            action: {
                ld: model.get(nodeSetting.path)
            }
        };
    })
    // 从后往前删除
    .reverse();
}
/**
 * UpdateAction 转为 oi od operation
 * @param action UpdateAction
 * @param model ot model
 * @returns oi od operation 数组
 */
function updateActionToOpeartion(action, model) {
    var ops = [];
    (0, _forEach3.default)(action.updated, function (act) {
        // 比对 key 值，转为 oi od operation
        ops = ops.concat(updateObjectHelper(act.updated, model.get(act.path), act.path));
    });
    return ops;
}
/**
 * StructureChangeAction 转为 lm 或 li ld operation
 * @description 同级移动时转为 lm，跨级移动转为 li ld
 * @param action StructureChangeAction
 * @param model ot model
 * @returns lm 或 li ld operation 数组
 */
function moveActionToOpeartion(action, model) {
    var ops = [];
    // 纯同级移动则用 lm
    var useLmOperation = (0, _every3.default)(action.changed, function (act) {
        return act.changed.parentId === act.original.parentId;
    });
    if (useLmOperation) {
        (0, _forEach3.default)(action.changed, function (act) {
            if (act.changed.index < act.original.index) {
                // 顺序上移
                ops.push({
                    p: act.original.path,
                    action: {
                        lm: act.changed.index
                    }
                });
            } else {
                // 倒序下移
                ops.unshift({
                    p: act.original.path,
                    action: {
                        lm: act.changed.index
                    }
                });
            }
        });
    } else {
        // 纯跨级移动或者同时存在同级和跨级移动（多选拖动）时，用 ld li
        (0, _forEach3.default)(action.changed, function (act, index) {
            // 先从后往前删除
            ops.unshift({
                p: act.original.path,
                action: {
                    ld: model.get(act.original.path)
                }
            });
            // 然后从前往后增加
            ops.push({
                p: act.changed.path,
                action: {
                    li: act.changed.node
                }
            });
        });
    }
    return ops;
}
/**
 * SettingChangeAction 转为 oi od operation
 * @description 每个 key 值的变化，转为一个 oi od operation
 * @param action SettingChangeAction
 * @param model ot model
 * @returns oi od operation 数组
 */
function settingActionToOperation(action, model) {
    return updateObjectHelper(action.changed, model.get([]), []);
}

/***/ }),

/***/ 3023:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _defineProperty2 = __webpack_require__(11);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _isString2 = __webpack_require__(63);

var _isString3 = _interopRequireDefault(_isString2);

var _isInteger2 = __webpack_require__(3024);

var _isInteger3 = _interopRequireDefault(_isInteger2);

var _has2 = __webpack_require__(754);

var _has3 = _interopRequireDefault(_has2);

exports.operationToAction = operationToAction;

var _types = __webpack_require__(3025);

var _editor = __webpack_require__(1813);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * 把 ot operation 转为 action
 * @param operation ot operation
 * @param model ot model
 * @throws path 或 type 有误时会抛错
 * @returns action
 */
function operationToAction(operation, model) {
    var type = getOperationType(operation);
    switch (type) {
        case _types.Operations.CREATE:
            {
                return createOperationToAction(operation, model);
            }
        case _types.Operations.DELETE:
            {
                return deleteOperationToAction(operation, model);
            }
        case _types.Operations.UPDATE:
            {
                return updateOperationToAction(operation, model);
            }
        case _types.Operations.MOVE:
            {
                return moveOperationToAction(operation, model);
            }
        case _types.Operations.SETTING:
            {
                return settingOperationToAction(operation);
            }
        default:
            {
                throw new Error('Unknown operation');
            }
    }
}
/**
 * 检测 ot operation 的类型
 * @param operation ot operation
 * @returns operation 类型
 */
function getOperationType(operation) {
    var action = operation.action;

    if ((0, _has3.default)(action, 'od') || (0, _has3.default)(action, 'oi')) {
        // path 长度为 1 就是 setting change，否则认为是 update node
        return operation.p.length > 1 ? _types.Operations.UPDATE : _types.Operations.SETTING;
    }
    // 创建 node
    if ((0, _has3.default)(action, 'li')) {
        return _types.Operations.CREATE;
    }
    // 删除 node
    if ((0, _has3.default)(action, 'ld')) {
        return _types.Operations.DELETE;
    }
    // 移动 node
    if ((0, _has3.default)(action, 'lm')) {
        return _types.Operations.MOVE;
    }
    // 不支持的 operation
    return _types.Operations.UNKNOWN;
}
/**
 * 通过 path 获取 parent 和 index，补齐为 nodeSet
 * @description 创建 node 时需要这样，因为此时 model 上还没有此 node
 * @param p path
 * @param model ot model
 * @param node node
 * @throws path 不符合要求时会抛错
 */
function getNodeSetting(p, model, node) {
    // 这里 p 应该是 [..., 'children | nodes', 'index'], 强校验
    var path = Array.from(p);
    var index = path.pop();
    var childKey = path.pop();
    if (!(0, _isInteger3.default)(index) || index < 0 || childKey !== 'nodes' && childKey !== 'children') {
        throw new Error('Invalid path for node setting');
    }
    return {
        // 父级 node 的 path 为空，则没父级，设为 null
        parentId: path.length !== 0 ? model.get(path).id : null,
        index: index,
        node: node || model.get(p),
        path: p
    };
}
/**
 * 检查 object 的 key 是不是合法的，不是则报错
 * @param key object key
 * @throws key 不合法时报错
 */
function throwIfKeyInvalid(key) {
    if (!(0, _isString3.default)(key) || key === '') {
        throw new Error('Invalid object key');
    }
}
/**
 * li operation 转为 CreateAction
 * @param operation ot operation: li
 * @param model ot model
 */
function createOperationToAction(operation, model) {
    var node = operation.action.li;
    return {
        name: _editor.Actions.CREATE,
        created: [getNodeSetting(operation.p, model, node)]
    };
}
/**
 * ld operation 转为 DeleteAction
 * @param operation ot operation: ld
 * @param model ot model
 */
function deleteOperationToAction(operation, model) {
    return {
        name: _editor.Actions.DELETE,
        deleted: [getNodeSetting(operation.p, model)]
    };
}
/**
 * oi od operation 转为 UpdateAction
 * @param operation ot operation: oi od
 * @param model ot model
 * @throws path 不合法时会抛错
 */
function updateOperationToAction(operation, model) {
    // p 应为 【..., 'nodes | children', index, key】
    if (operation.p.length < 3) {
        throw new Error('Invalid path for node update');
    }
    var path = Array.from(operation.p);
    var key = path.pop();
    throwIfKeyInvalid(key);
    var original = model.get(path);
    return {
        name: _editor.Actions.UPDATE,
        updated: [{
            path: path,
            updated: Object.assign({}, original, (0, _defineProperty3.default)({}, key, operation.action.oi)),
            original: original
        }]
    };
}
/**
 * lm operation 转为 StructureChangeAction
 * @param operation ot operation: lm
 * @param model ot model
 */
function moveOperationToAction(operation, model) {
    var newIndex = operation.action.lm;
    var original = getNodeSetting(operation.p, model);
    // path 应该是 【..., 'nodes | children', index】
    var newPath = Array.from(operation.p);
    newPath.pop(); // 旧的 index
    newPath.push(newIndex); // 新的 index
    return {
        name: _editor.Actions.STRUCTURE_CHANGE,
        changed: [{
            changed: Object.assign({}, original, {
                index: newIndex,
                path: newPath
            }),
            original: original
        }]
    };
}
/**
 * oi od operation 转为 SettingChangeAction
 * @param operation ot operation: oi od
 * @throws path 不符合要去时会抛错
 */
function settingOperationToAction(operation) {
    // path 应该是 ['theme'] 或 ['structure'] 等
    if (operation.p.length !== 1) {
        throw new Error('Invalid path for setting');
    }
    var key = operation.p[0];
    throwIfKeyInvalid(key);
    return {
        name: _editor.Actions.SETTING_CHANGE,
        changed: (0, _defineProperty3.default)({}, key, operation.action.oi),
        original: (0, _defineProperty3.default)({}, key, operation.action.od)
    };
}

/***/ }),

/***/ 3024:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _toInteger_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(521);


/**
 * Checks if `value` is an integer.
 *
 * **Note:** This method is based on
 * [`Number.isInteger`](https://mdn.io/Number/isInteger).
 *
 * @static
 * @memberOf _
 * @since 4.0.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is an integer, else `false`.
 * @example
 *
 * _.isInteger(3);
 * // => true
 *
 * _.isInteger(Number.MIN_VALUE);
 * // => false
 *
 * _.isInteger(Infinity);
 * // => false
 *
 * _.isInteger('3');
 * // => false
 */
function isInteger(value) {
  return typeof value == 'number' && value == Object(_toInteger_js__WEBPACK_IMPORTED_MODULE_0__[/* default */ "a"])(value);
}

/* harmony default export */ __webpack_exports__["default"] = (isInteger);


/***/ }),

/***/ 3025:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
var Operations = exports.Operations = undefined;
(function (Operations) {
    Operations["CREATE"] = "CREATE";
    Operations["DELETE"] = "DELETE";
    Operations["UPDATE"] = "UPDATE";
    Operations["MOVE"] = "MOVE";
    Operations["SETTING"] = "SETTING";
    Operations["UNKNOWN"] = "UNKNOWN";
})(Operations || (exports.Operations = Operations = {}));

/***/ }),

/***/ 3026:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3027:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3028:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _index = __webpack_require__(3029);

var _index2 = _interopRequireDefault(_index);

var _index3 = __webpack_require__(3030);

var _index4 = _interopRequireDefault(_index3);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Plugin = function Plugin() {
    var _this = this;

    (0, _classCallCheck3.default)(this, Plugin);

    this.init = function () {
        _this.statistics = new _index2.default();
        _this.screenshot = new _index4.default();
    };
    this.destroy = function () {
        _this.statistics.destroy();
    };
    console.log('init plugin');
    this.init();
};

exports.default = Plugin;

/***/ }),

/***/ 3029:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _tea = __webpack_require__(47);

var _offline = __webpack_require__(137);

var _suiteHelper = __webpack_require__(60);

var _$constants = __webpack_require__(4);

var _eventEmitter = __webpack_require__(272);

var _eventEmitter2 = _interopRequireDefault(_eventEmitter);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var editorInfo = void 0;

var Statistics = function Statistics(editor) {
  var _this = this;

  (0, _classCallCheck3.default)(this, Statistics);

  this.init = function () {
    _this.destroy();
    _eventEmitter2.default.on(_$constants.events.MOBILE.DOCS.Statistics.fetchClientVarsEnd, fetchClientVarsEnd);
    _eventEmitter2.default.on(_$constants.events.MOBILE.DOCS.Statistics.fetchClientVarsStart, fetchClientVarsStart);
    _eventEmitter2.default.on(_$constants.events.MOBILE.DOCS.Statistics.renderEnd, renderEnd);
    _eventEmitter2.default.on(_$constants.events.MOBILE.DOCS.Statistics.fetchClientVarDelete, fetchClientVarDelete);
  };

  this.destroy = function () {
    _eventEmitter2.default.off(_$constants.events.MOBILE.DOCS.Statistics.fetchClientVarsEnd, fetchClientVarsEnd);
    _eventEmitter2.default.off(_$constants.events.MOBILE.DOCS.Statistics.fetchClientVarsStart, fetchClientVarsStart);
    _eventEmitter2.default.off(_$constants.events.MOBILE.DOCS.Statistics.renderEnd, renderEnd);
    _eventEmitter2.default.off(_$constants.events.MOBILE.DOCS.Statistics.fetchClientVarDelete, fetchClientVarDelete);
  };

  this.init();
};

exports.default = Statistics;
;

var normalData = {
  docs_result_key: 'other',
  docs_result_code: 0
};
var fetchClientVarsEnd = function fetchClientVarsEnd(data) {
  var token = (0, _suiteHelper.getToken)();
  var recordData = _offline.REPORTDATA[token];
  // 防止重复打点，REPORTDATA[token + '-' + 'fetchClientVarsStart']有开始后才打点，新建文档的时候token会不一样，所以加上这个判断；
  if (_offline.REPORTDATA[token + '-' + 'fetchClientVarsEnd'] || !_offline.REPORTDATA[token + '-' + 'fetchClientVarsStart']) return;
  var endTime = new Date().getTime();
  _offline.REPORTDATA[token + '-' + 'fetchClientVarsEnd'] = 1;
  _offline.REPORTDATA[token + '-' + 'docs_result_code'] = data.docs_result_code;
  _offline.REPORTDATA[token + '-' + 'startTime_renderDocStart'] = endTime;
  recordData.time_fetchClientVars = endTime - (_offline.REPORTDATA[token + '-' + 'startTime_fetchClientVarsStart'] || 0);
  var sendData = {
    data: Object.assign({
      stage: 'pull_data',
      file_id: (0, _tea.getEncryToken)()
    }, normalData, recordData, data),
    event_type: 3
  };
  console.info('fileopen pull_data_end: ' + JSON.stringify(sendData));
  window.lark.biz.statistics.sendEvent(sendData);
  if (!data.docs_result_code) {
    // 没有异常
    var renderDocData = {
      data: {
        stage: 'render_doc',
        file_id: (0, _tea.getEncryToken)()
      },
      event_type: 2
    };
    _offline.REPORTDATA[token + '-' + 'render_doc_start'] = 1;
    console.info('fileopen render_doc_start: ' + JSON.stringify(renderDocData));
    window.lark.biz.statistics.sendEvent(renderDocData);
  } else if (data.docs_result_code < 0) {
    var _sendData = {
      result_code: data.docs_result_code,
      data: Object.assign({}, recordData)
    };
    console.info('fileopen failEvent: ' + JSON.stringify(_sendData));
    window.lark.biz.util.failEvent(_sendData);
  }
};
var fetchClientVarsStart = function fetchClientVarsStart(data) {
  var token = (0, _suiteHelper.getToken)();
  var recordData = _offline.REPORTDATA[token] || {};
  var sendData = {
    data: Object.assign({
      stage: 'pull_data',
      file_id: (0, _tea.getEncryToken)()
    }, recordData),
    event_type: 2
  };
  // 默认为doc
  if (!sendData.data.file_type) {
    sendData.data.file_type = 'doc';
  }
  if (_offline.REPORTDATA[token + '-' + 'fetchClientVarsStart']) return;
  _offline.REPORTDATA[token + '-' + 'fetchClientVarsStart'] = 1;
  var endTime = new Date().getTime();
  _offline.REPORTDATA[token + '-' + 'startTime_fetchClientVarsStart'] = endTime;
  _offline.REPORTDATA[token + '-' + 'time_beforefetchClientVars'] = endTime - (_offline.REPORTDATA[token + '-' + 'startTime_openfile'] || 0);
  console.info('fileopen pull_data_start: ' + JSON.stringify(sendData));
  window.lark && window.lark.biz.statistics.sendEvent(sendData);
  try {
    console.info('scm: ' + JSON.stringify(window.scm));
    var newScm = {};
    for (var i in window.scm) {
      newScm['scm_' + i] = window.scm[i];
    }
    window.lark.biz.statistics.reportEvent({
      event_name: 'scm',
      data: Object.assign({}, newScm)
    });
  } catch (e) {
    console.log(e);
  }
};

var renderEnd = function renderEnd() {
  var data = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};

  var token = (0, _suiteHelper.getToken)();
  var recordData = _offline.REPORTDATA[token];
  if (_offline.REPORTDATA[token + '-' + 'render_doc_end'] || !_offline.REPORTDATA[token + '-' + 'fetchClientVarsStart']) return;
  _offline.REPORTDATA[token + '-' + 'render_doc_end'] = 1;
  var endTime = new Date().getTime();
  recordData.time_renderDoc = endTime - (_offline.REPORTDATA[token + '-' + 'startTime_renderDocStart'] || 0);
  recordData.time_fileopen = endTime - (_offline.REPORTDATA[token + '-' + 'startTime_openfile'] || 0);
  recordData.time_beforefetchClientVars = _offline.REPORTDATA[token + '-' + 'time_beforefetchClientVars'];
  window.lark.biz.statistics.sendEvent({
    data: Object.assign({}, recordData, {
      file_id: (0, _tea.getEncryToken)()
    }),
    event_type: 1 // doc visible for user
  });
  var sendData = {
    data: Object.assign({
      stage: 'render_doc'
    }, recordData, normalData, data, {
      isBlockRender: editorInfo && editorInfo.blockRender && editorInfo.blockRender.getUsageState ? editorInfo.blockRender.getUsageState() : false,
      file_id: (0, _tea.getEncryToken)()
    }),
    event_type: 3
  };
  window.lark.biz.statistics.sendEvent(sendData);
  console.info('fileopen render_doc_end: ' + JSON.stringify(sendData));
  // log空白文档秒开率,特殊上报；
  var captureData = Object.assign({}, recordData, window.EDITOR_RENDER_LOG || {}, _offline.REPORTDATA['editor'], {
    file_id: (0, _tea.getEncryToken)()
  });
  console.info('-----------fileopen-------------');
  console.info(JSON.stringify(captureData));
  if (recordData.text_length === 2) {
    window.Raven && window.Raven.captureMessage('fileopen:blank file', {
      level: 'info',
      tags: {
        reporter: 'statistics',
        scm: JSON.stringify(window.scm || {})
      },
      extra: Object.assign({}, captureData)
    });
  }
};
var fetchClientVarDelete = function fetchClientVarDelete(command) {
  var token = (0, _suiteHelper.getToken)();
  // 解决DM-1674。
  if (command !== 'doClear') {
    if (_offline.REPORTDATA[token + '-' + 'fetchClientVarsStart'] && !_offline.REPORTDATA[token + '-' + 'fetchClientVarsEnd']) return;
    if (_offline.REPORTDATA[token + '-' + 'render_doc_start'] && !_offline.REPORTDATA[token + '-' + 'render_doc_end']) return;
  }
  (0, _offline.resetREPORTDATA)();
};

/***/ }),

/***/ 3030:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

__webpack_require__(3031);

var _waitLoader = __webpack_require__(3032);

var _logger = __webpack_require__(380);

var _logger2 = _interopRequireDefault(_logger);

var _browserHelper = __webpack_require__(34);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var bodyClassName = '';
var timeOut = null;
var hasRuned = null;

var ScreenShot = function ScreenShot(editor) {
  (0, _classCallCheck3.default)(this, ScreenShot);
  this.className = 'ScreenShot';

  this.init = function () {
    window.native.screenshot = function (state) {
      if (state === 0) {
        beforeScreenshot();
        screenReady();
      } else {
        afterScreenshot();
      }
    };
  };

  this.init();
};

exports.default = ScreenShot;

function screenReady(that) {
  hasRuned = false;
  (0, _waitLoader.waitAllLoad)().then(function () {
    timeOut = setTimeout(function () {
      clearTimeout(timeOut);
      !hasRuned && window.lark.biz.doc.screenshotReady({ success: true });
      hasRuned = true;
    }, 20);
  });
  timeOut = setTimeout(function () {
    // 10s超时
    clearTimeout(timeOut);
    if (!hasRuned) {
      window.lark.biz.doc.screenshotReady({ success: false });
      hasRuned = true;
      _logger2.default.info('导出长图超时显示');
    }
  }, 10000);
}
function beforeScreenshot() {
  var body = document.getElementsByTagName('body')[0];
  bodyClassName = body.className;
  if (bodyClassName.indexOf('screenshoting') === -1) {
    body.className = bodyClassName + ' screenshoting';
  }
  initFooter();
}
function afterScreenshot(editor) {
  var body = document.getElementsByTagName('body')[0];
  body.className = bodyClassName;
  hasRuned = true;
}
function initFooter() {
  var domFooter = document.getElementById('screen-footer-wrap');
  if (!domFooter) {
    var footerHtml = '<div class="screen-footer-wrap" id="screen-footer-wrap">\n        <div class="screenFooterContent">\n        ' + (_browserHelper2.default.isDocsSDK ? t('mobile.screenshot.notify') : t('mobile.screenshot.notify_docsapp')) + '\n        </div>\n      </div>';
    var elem = document.createElement('div');
    elem.innerHTML = footerHtml;
    document.getElementById('mindnote-main').appendChild(elem);
    domFooter = document.getElementById('screen-footer-wrap');
  }
}
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3031:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3032:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


var _es6Promise = __webpack_require__(1656);

var _es6Promise2 = _interopRequireDefault(_es6Promise);

var _logger = __webpack_require__(380);

var _logger2 = _interopRequireDefault(_logger);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// import _each from 'lodash/each';
// const AttributePool = require('$etherpad/static/js/AttributePool');
var container = '.mindnote-paper';
window.allSheetIds = [];
var duration = 500;
function waitAllLoad() {
  if (isMindnote()) {
    return _es6Promise2.default.all([waitFirstScreenImageLoaded(), waitFirstScreenMentionLoaded()]).then(function () {
      return { code: 0 };
    });
  }
}

function waitFirstScreenImageLoaded() {
  return new _es6Promise2.default(function (resolve, reject) {
    var images = document.querySelectorAll(container + ' img');
    var allImageNum = images.length;
    var loadedNum = 0;
    var isReject = false;
    if (images) {
      for (var i = 0; i < allImageNum; i++) {
        var img = images[i];
        if (!img.complete) {
          img.onload = function () {
            loadedNum++;
            if (loadedNum === allImageNum) {
              resolve({});
            }
          };
          img.onerror = function () {
            if (!isReject) {
              var reason = 'image loaded fail';
              postError({ reason: reason });
              reject(new Error(reason));
            }
          };
        } else {
          loadedNum++;
        }
      }
    }
    if (loadedNum === allImageNum) {
      resolve({});
    }
  });
}

// function waitSheetLoaded() {
//   return new Promise(function (resolve, reject) {
//     let checkTimes = 0;
//     const maxCheckTimes = 250;
//     // 轮训是否首屏SheetLoaded都渲染完了
//     setTimeout(function checkSheetLoaded() {
//       checkTimes++;
//       if (checkTimes > maxCheckTimes) {
//         return ({ code: -1 });
//       }
//       if (isSheetLoaded()) {
//         resolve({});
//       } else {
//         setTimeout(checkSheetLoaded, duration);
//       }
//     }, duration);
//   });
// }
// function isSheetLoaded() {
//   const canvasList = document.querySelectorAll('.spreadsheet-canvas');
//   if (canvasList) {
//     const sheetLoaded = document.querySelectorAll('.spread-loaded') || [];
//     if (sheetLoaded.length === canvasList.length) {
//       let result = true;
//       for (const i in canvasList) {
//         if (canvasList[i].width === 0) {
//           result = false;
//         }
//       }
//       return result;
//     }
//   } else {
//     return false;
//   }
// }
function waitFirstScreenMentionLoaded() {
  return new _es6Promise2.default(function (resolve, reject) {
    var checkTimes = 0;
    var maxCheckTimes = 250;
    // 轮训是否首屏mention都渲染完了
    setTimeout(function checkMentionLoaded() {
      checkTimes++;
      if (checkTimes > maxCheckTimes) {
        return postError({ reason: 'mention loaded time out' });
      }
      if (isMentionLoaded()) {
        resolve({});
      } else {
        setTimeout(checkMentionLoaded, duration);
      }
    }, duration);
  });
}

function isMentionLoaded() {
  var chatMentions = document.querySelectorAll('.mention-type_5');
  var firstScreenMentions = chatMentions;
  for (var i = 0, len = firstScreenMentions.length; i < len; i++) {
    var mention = firstScreenMentions[i];
    var title = mention.querySelector('.mention-chat-tit').innerText;
    if (!title) {
      return false;
    }
  }
  return true;
}
function postError(param) {
  _logger2.default.info(param);
}

function isMindnote() {
  return (/\/mindnote\//.test(location.href)
  );
}

module.exports = {
  waitAllLoad: waitAllLoad
};

/***/ }),

/***/ 3254:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);

// CONCATENATED MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/lodash-es/_arrayEvery.js
/**
 * A specialized version of `_.every` for arrays without support for
 * iteratee shorthands.
 *
 * @private
 * @param {Array} [array] The array to iterate over.
 * @param {Function} predicate The function invoked per iteration.
 * @returns {boolean} Returns `true` if all elements pass the predicate check,
 *  else `false`.
 */
function arrayEvery(array, predicate) {
  var index = -1,
      length = array == null ? 0 : array.length;

  while (++index < length) {
    if (!predicate(array[index], index, array)) {
      return false;
    }
  }
  return true;
}

/* harmony default export */ var _arrayEvery = (arrayEvery);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/lodash-es/_baseEach.js + 1 modules
var _baseEach = __webpack_require__(302);

// CONCATENATED MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/lodash-es/_baseEvery.js


/**
 * The base implementation of `_.every` without support for iteratee shorthands.
 *
 * @private
 * @param {Array|Object} collection The collection to iterate over.
 * @param {Function} predicate The function invoked per iteration.
 * @returns {boolean} Returns `true` if all elements pass the predicate check,
 *  else `false`
 */
function baseEvery(collection, predicate) {
  var result = true;
  Object(_baseEach["a" /* default */])(collection, function(value, index, collection) {
    result = !!predicate(value, index, collection);
    return result;
  });
  return result;
}

/* harmony default export */ var _baseEvery = (baseEvery);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/lodash-es/_baseIteratee.js + 9 modules
var _baseIteratee = __webpack_require__(186);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/lodash-es/isArray.js
var isArray = __webpack_require__(39);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/lodash-es/_isIterateeCall.js
var _isIterateeCall = __webpack_require__(1719);

// CONCATENATED MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/lodash-es/every.js






/**
 * Checks if `predicate` returns truthy for **all** elements of `collection`.
 * Iteration is stopped once `predicate` returns falsey. The predicate is
 * invoked with three arguments: (value, index|key, collection).
 *
 * **Note:** This method returns `true` for
 * [empty collections](https://en.wikipedia.org/wiki/Empty_set) because
 * [everything is true](https://en.wikipedia.org/wiki/Vacuous_truth) of
 * elements of empty collections.
 *
 * @static
 * @memberOf _
 * @since 0.1.0
 * @category Collection
 * @param {Array|Object} collection The collection to iterate over.
 * @param {Function} [predicate=_.identity] The function invoked per iteration.
 * @param- {Object} [guard] Enables use as an iteratee for methods like `_.map`.
 * @returns {boolean} Returns `true` if all elements pass the predicate check,
 *  else `false`.
 * @example
 *
 * _.every([true, 1, null, 'yes'], Boolean);
 * // => false
 *
 * var users = [
 *   { 'user': 'barney', 'age': 36, 'active': false },
 *   { 'user': 'fred',   'age': 40, 'active': false }
 * ];
 *
 * // The `_.matches` iteratee shorthand.
 * _.every(users, { 'user': 'barney', 'active': false });
 * // => false
 *
 * // The `_.matchesProperty` iteratee shorthand.
 * _.every(users, ['active', false]);
 * // => true
 *
 * // The `_.property` iteratee shorthand.
 * _.every(users, 'active');
 * // => false
 */
function every(collection, predicate, guard) {
  var func = Object(isArray["default"])(collection) ? _arrayEvery : _baseEvery;
  if (guard && Object(_isIterateeCall["a" /* default */])(collection, predicate, guard)) {
    predicate = undefined;
  }
  return func(collection, Object(_baseIteratee["a" /* default */])(predicate, 3));
}

/* harmony default export */ var lodash_es_every = __webpack_exports__["default"] = (every);


/***/ })

}]);
//# sourceMappingURL=https://s3.pstatp.com/eesz/resource/bear/js/mindnote.2688deae310aae8822c9.js.map