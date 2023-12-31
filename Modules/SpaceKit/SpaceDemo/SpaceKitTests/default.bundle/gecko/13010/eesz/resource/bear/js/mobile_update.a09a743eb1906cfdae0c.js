/******/ (function(modules) { // webpackBootstrap
/******/ 	// install a JSONP callback for chunk loading
/******/ 	function webpackJsonpCallback(data) {
/******/ 		var chunkIds = data[0];
/******/ 		var moreModules = data[1];
/******/ 		var executeModules = data[2];
/******/
/******/ 		// add "moreModules" to the modules object,
/******/ 		// then flag all "chunkIds" as loaded and fire callback
/******/ 		var moduleId, chunkId, i = 0, resolves = [];
/******/ 		for(;i < chunkIds.length; i++) {
/******/ 			chunkId = chunkIds[i];
/******/ 			if(installedChunks[chunkId]) {
/******/ 				resolves.push(installedChunks[chunkId][0]);
/******/ 			}
/******/ 			installedChunks[chunkId] = 0;
/******/ 		}
/******/ 		for(moduleId in moreModules) {
/******/ 			if(Object.prototype.hasOwnProperty.call(moreModules, moduleId)) {
/******/ 				modules[moduleId] = moreModules[moduleId];
/******/ 			}
/******/ 		}
/******/ 		if(parentJsonpFunction) parentJsonpFunction(data);
/******/
/******/ 		while(resolves.length) {
/******/ 			resolves.shift()();
/******/ 		}
/******/
/******/ 		// add entry modules from loaded chunk to deferred list
/******/ 		deferredModules.push.apply(deferredModules, executeModules || []);
/******/
/******/ 		// run deferred modules when all chunks ready
/******/ 		return checkDeferredModules();
/******/ 	};
/******/ 	function checkDeferredModules() {
/******/ 		var result;
/******/ 		for(var i = 0; i < deferredModules.length; i++) {
/******/ 			var deferredModule = deferredModules[i];
/******/ 			var fulfilled = true;
/******/ 			for(var j = 1; j < deferredModule.length; j++) {
/******/ 				var depId = deferredModule[j];
/******/ 				if(installedChunks[depId] !== 0) fulfilled = false;
/******/ 			}
/******/ 			if(fulfilled) {
/******/ 				deferredModules.splice(i--, 1);
/******/ 				result = __webpack_require__(__webpack_require__.s = deferredModule[0]);
/******/ 			}
/******/ 		}
/******/ 		return result;
/******/ 	}
/******/
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// object to store loaded and loading chunks
/******/ 	// undefined = chunk not loaded, null = chunk preloaded/prefetched
/******/ 	// Promise = chunk loading, 0 = chunk loaded
/******/ 	var installedChunks = {
/******/ 		10: 0
/******/ 	};
/******/
/******/ 	var deferredModules = [];
/******/
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId]) {
/******/ 			return installedModules[moduleId].exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			i: moduleId,
/******/ 			l: false,
/******/ 			exports: {}
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.l = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;
/******/
/******/ 	// define getter function for harmony exports
/******/ 	__webpack_require__.d = function(exports, name, getter) {
/******/ 		if(!__webpack_require__.o(exports, name)) {
/******/ 			Object.defineProperty(exports, name, { enumerable: true, get: getter });
/******/ 		}
/******/ 	};
/******/
/******/ 	// define __esModule on exports
/******/ 	__webpack_require__.r = function(exports) {
/******/ 		if(typeof Symbol !== 'undefined' && Symbol.toStringTag) {
/******/ 			Object.defineProperty(exports, Symbol.toStringTag, { value: 'Module' });
/******/ 		}
/******/ 		Object.defineProperty(exports, '__esModule', { value: true });
/******/ 	};
/******/
/******/ 	// create a fake namespace object
/******/ 	// mode & 1: value is a module id, require it
/******/ 	// mode & 2: merge all properties of value into the ns
/******/ 	// mode & 4: return value when already ns object
/******/ 	// mode & 8|1: behave like require
/******/ 	__webpack_require__.t = function(value, mode) {
/******/ 		if(mode & 1) value = __webpack_require__(value);
/******/ 		if(mode & 8) return value;
/******/ 		if((mode & 4) && typeof value === 'object' && value && value.__esModule) return value;
/******/ 		var ns = Object.create(null);
/******/ 		__webpack_require__.r(ns);
/******/ 		Object.defineProperty(ns, 'default', { enumerable: true, value: value });
/******/ 		if(mode & 2 && typeof value != 'string') for(var key in value) __webpack_require__.d(ns, key, function(key) { return value[key]; }.bind(null, key));
/******/ 		return ns;
/******/ 	};
/******/
/******/ 	// getDefaultExport function for compatibility with non-harmony modules
/******/ 	__webpack_require__.n = function(module) {
/******/ 		var getter = module && module.__esModule ?
/******/ 			function getDefault() { return module['default']; } :
/******/ 			function getModuleExports() { return module; };
/******/ 		__webpack_require__.d(getter, 'a', getter);
/******/ 		return getter;
/******/ 	};
/******/
/******/ 	// Object.prototype.hasOwnProperty.call
/******/ 	__webpack_require__.o = function(object, property) { return Object.prototype.hasOwnProperty.call(object, property); };
/******/
/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "//s3.pstatp.com/eesz/resource/bear/";
/******/
/******/ 	var jsonpArray = window["webpackJsonp"] = window["webpackJsonp"] || [];
/******/ 	var oldJsonpFunction = jsonpArray.push.bind(jsonpArray);
/******/ 	jsonpArray.push = webpackJsonpCallback;
/******/ 	jsonpArray = jsonpArray.slice();
/******/ 	for(var i = 0; i < jsonpArray.length; i++) webpackJsonpCallback(jsonpArray[i]);
/******/ 	var parentJsonpFunction = oldJsonpFunction;
/******/
/******/
/******/ 	// add entry module to deferred list
/******/ 	deferredModules.push([1563,4,7]);
/******/ 	// run deferred modules when ready
/******/ 	return checkDeferredModules();
/******/ })
/************************************************************************/
/******/ ({

/***/ 1563:
/***/ (function(module, exports, __webpack_require__) {

module.exports = __webpack_require__(1564);


/***/ }),

/***/ 1564:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


var _sdkCompatibleHelper = __webpack_require__(45);

var _sendCollector = __webpack_require__(1565);

var _sendCollector2 = _interopRequireDefault(_sendCollector);

var _getAllUrlParams = __webpack_require__(231);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

window._sendCollector = _sendCollector2.default;
(0, _sendCollector2.default)('enter');

// 判断2.1 飞书是够有版本号
var isIOS = window.navigator.userAgent.match(/iphone/i);
var host = window.location.hostname.split('.');
var isLarksuite = host[host.length - 2] === 'larksuite';
var href = isLarksuite ? 'https://www.larksuite.com/download' : 'https://lark.bytedance.net/';

if (!isIOS) {
  var appVersion = (0, _sdkCompatibleHelper.getAppVersion)();
  if (appVersion) {
    var curVersion = appVersion.split('.');
    var version = parseInt(curVersion[0] + curVersion[1]);
    href = version > 23 ? 'lark://inner/mine/about' : href;
  }
}
document.addEventListener('DOMContentLoaded', function (event) {
  if (isNoSupport()) {
    renderNoSupportHtml();
  } else {
    renderUpdateHtml();
  }
});

function renderUpdateHtml() {
  document.querySelector('.upgrade-img').style.display = 'inline-block';
  var upgradeRemind = 'Your app version is too low, this feature is temporarily unavailable,\n   please upgrade to the latest version.';
  var upgradeBtn = 'Upgrade it now';
  var _html = '<p class=\'upgrade-info\'>' + (window.TTI18N && window.TTI18N['docs.mobile.upgrade_info'] || upgradeRemind) + '</p><a href=' + href + ' class=\'upgrade-btn\' onclick=\'window._sendCollector()\'>' + (window.TTI18N && window.TTI18N['docs.mobile.upgrade_btn'] || upgradeBtn) + '</a>';
  var node = document.createElement('div');
  node.innerHTML = _html;
  document.body.append(node);
}
function renderNoSupportHtml() {
  document.querySelector('.noSupportImg').style.display = 'inline-block';
  var defaultTip = 'The feature is not available in the mobile version，please visit it on the web side.';
  var tip = '<div class="noSupport">' + (window.TTI18N && window.TTI18N['docs.mobile.nosupport_info'] || defaultTip) + '</div>';
  var node = document.createElement('div');
  node.innerHTML = tip;
  document.body.append(node);
}
function isNoSupport() {
  var refer = (0, _getAllUrlParams.getAllUrlParams)().refer;
  var result = false;
  var suiteTypes = ['slide'];
  // eslint-disable-next-line no-useless-escape
  var noSupportSuite = new RegExp('(' + suiteTypes.join('|') + ')\\/([^/?#]+)\\/*').exec(refer);
  if (noSupportSuite) {
    result = true;
  }
  return result;
}

/***/ }),

/***/ 1565:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _get2 = __webpack_require__(83);

var _get3 = _interopRequireDefault(_get2);

var _bytedTeaSdk = __webpack_require__(674);

var _bytedTeaSdk2 = _interopRequireDefault(_bytedTeaSdk);

var _constants = __webpack_require__(5);

var _abTestHelper = __webpack_require__(583);

var _browserHelper = __webpack_require__(27);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

var _i18nHelper = __webpack_require__(222);

var _envHelper = __webpack_require__(147);

var _networkHelper = __webpack_require__(113);

var _appHelper = __webpack_require__(543);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var IOS = _constants.platform.IOS,
    ANDRORID = _constants.platform.ANDRORID,
    MAC = _constants.platform.MAC,
    WINDOWS = _constants.platform.WINDOWS;

var browser = _browserHelper2.default;
var osMap = {
  'Android': ANDRORID,
  'iOS': IOS,
  'macOS': MAC,
  'Windows': WINDOWS
};
function getOSName(os) {
  return osMap[os] || os || 'web';
}
function getWebVersion(type) {
  var version = (0, _get3.default)(window, 'rv_rev') || '';
  var _dateStr = version.substr(version.indexOf('-') + 1);
  var position = _dateStr.indexOf('-', _dateStr.indexOf('-') + 1);
  if (type === 'date') {
    return _dateStr.slice(0, position) || 0;
  }
  if (type === 'timestamp') {
    return parseInt(_dateStr.substr(position + 1), 10) || 0;
  }

  return '-1';
}
function getPlatForm() {
  if (browser.isFeed) return 'lark';
  if (browser.isLark) return 'lark';
  if (browser.isDocs) return 'doc_app';
  return 'web';
}
function initCollector() {
  var init = {
    app_id: (0, _appHelper.isOverSea)() ? 1662 : 1229,
    channel: (0, _appHelper.isOverSea)() ? 'va' : 'cn'
  };
  var config = {
    _staging_flag: !(0, _networkHelper.isOnlineEnv)() ? 1 : 0,
    // user_unique_id: encryptTea(window.User.suid),
    app_name: 'docs',
    // browser: opt.browser,
    browser_version: _browserHelper2.default.version,
    os_name: getOSName(_browserHelper2.default.osname || 'default'),
    device_model: getOSName(_browserHelper2.default.osname || 'default'),
    os_version: (_browserHelper2.default.osversion || 0).toString(),
    'custom.platform': getPlatForm(),
    'custom.browser': _browserHelper2.default.name,
    'custom.browser_version': _browserHelper2.default.version,
    'custom.browser_kernel': _browserHelper2.default.version,
    'custom.app_form': browser.isFeed ? 'docs_feed' : (0, _envHelper.isAnnouncement)() ? 'open_doc' : '',
    app_language: (0, _i18nHelper.getLanguage)(),
    ab_version: (0, _abTestHelper.getABVersionName)(),
    // tenant_id: encryptTea(window.User.tenantId)|| '',
    // department_id: window.User.departmentId || '-1',
    web_version_date: getWebVersion('date'),
    web_version_timestamp: getWebVersion('timestamp'),
    gray_scale: (0, _get3.default)(window, 'scm.branch', '')
  };
  _bytedTeaSdk2.default.init(init);
  _bytedTeaSdk2.default.config(config);
  _bytedTeaSdk2.default.send();
}
initCollector();
function sendCollector(action) {
  (0, _bytedTeaSdk2.default)('operate_webpage', {
    action: action || 'click-upgrade',
    'web-address': 'upgrade'
  });
}

exports.default = sendCollector;

/***/ })

/******/ });
//# sourceMappingURL=https://s3.pstatp.com/eesz/resource/bear/js/mobile_update.a09a743eb1906cfdae0c.js.map