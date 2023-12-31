/******/ (function(modules) { // webpackBootstrap
/******/     // The module cache
/******/     var installedModules = {};
/******/
/******/     // The require function
/******/     function __webpack_require__(moduleId) {
/******/
/******/         // Check if module is in cache
/******/         if(installedModules[moduleId]) {
/******/             return installedModules[moduleId].exports;
/******/         }
/******/         // Create a new module (and put it into the cache)
/******/         var module = installedModules[moduleId] = {
/******/             i: moduleId,
/******/             l: false,
/******/             exports: {}
/******/         };
/******/
/******/         // Execute the module function
/******/         modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/         // Flag the module as loaded
/******/         module.l = true;
/******/
/******/         // Return the exports of the module
/******/         return module.exports;
/******/     }
/******/
/******/
/******/     // expose the modules object (__webpack_modules__)
/******/     __webpack_require__.m = modules;
/******/
/******/     // expose the module cache
/******/     __webpack_require__.c = installedModules;
/******/
/******/     // define getter function for harmony exports
/******/     __webpack_require__.d = function(exports, name, getter) {
/******/         if(!__webpack_require__.o(exports, name)) {
/******/             Object.defineProperty(exports, name, { enumerable: true, get: getter });
/******/         }
/******/     };
/******/
/******/     // define __esModule on exports
/******/     __webpack_require__.r = function(exports) {
/******/         if(typeof Symbol !== 'undefined' && Symbol.toStringTag) {
/******/             Object.defineProperty(exports, Symbol.toStringTag, { value: 'Module' });
/******/         }
/******/         Object.defineProperty(exports, '__esModule', { value: true });
/******/     };
/******/
/******/     // create a fake namespace object
/******/     // mode & 1: value is a module id, require it
/******/     // mode & 2: merge all properties of value into the ns
/******/     // mode & 4: return value when already ns object
/******/     // mode & 8|1: behave like require
/******/     __webpack_require__.t = function(value, mode) {
/******/         if(mode & 1) value = __webpack_require__(value);
/******/         if(mode & 8) return value;
/******/         if((mode & 4) && typeof value === 'object' && value && value.__esModule) return value;
/******/         var ns = Object.create(null);
/******/         __webpack_require__.r(ns);
/******/         Object.defineProperty(ns, 'default', { enumerable: true, value: value });
/******/         if(mode & 2 && typeof value != 'string') for(var key in value) __webpack_require__.d(ns, key, function(key) { return value[key]; }.bind(null, key));
/******/         return ns;
/******/     };
/******/
/******/     // getDefaultExport function for compatibility with non-harmony modules
/******/     __webpack_require__.n = function(module) {
/******/         var getter = module && module.__esModule ?
/******/             function getDefault() { return module['default']; } :
/******/             function getModuleExports() { return module; };
/******/         __webpack_require__.d(getter, 'a', getter);
/******/         return getter;
/******/     };
/******/
/******/     // Object.prototype.hasOwnProperty.call
/******/     __webpack_require__.o = function(object, property) { return Object.prototype.hasOwnProperty.call(object, property); };
/******/
/******/     // __webpack_public_path__
/******/     __webpack_require__.p = "";
/******/
/******/
/******/     // Load entry module and return exports
/******/     return __webpack_require__(__webpack_require__.s = 0);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
// ESM COMPAT FLAG
__webpack_require__.r(__webpack_exports__);

// EXPORTS
__webpack_require__.d(__webpack_exports__, "LKNativeAvatar", function() { return /* reexport */ lk_native_avatar_LKNativeAvatar; });

// CONCATENATED MODULE: ./src/utils.js
const ua = window.navigator.userAgent.toLowerCase();

const _isAndroid = /android/.test(ua); // android终端


const _isIOS = /ipad|iphone|ipod/.test(ua); // ios终端


function isAndroid() {
  return _isAndroid;
}
function isIOS() {
  return _isIOS;
}
const fibonacci = function () {
  let cache = [0, 1];
  return function _fibonacci(n) {
    return typeof cache[n] === 'number' ? cache[n] : cache[n] = _fibonacci(n - 1) + _fibonacci(n - 2);
  };
}();
function hyphenate(str) {
  return str.replace(/\B([A-Z])/g, '-$1').toLowerCase();
}
function utils_camelCased(str) {
  return str.replace(/-([a-z])/g, g => g[1].toUpperCase());
}
function nextTick(fn) {
  if (window.Promise) {
    window.Promise.resolve().then(fn);
  } else {
    setTimeout(fn, 0);
  }
}
// CONCATENATED MODULE: ./src/event-bus.js
/* harmony default export */ var event_bus = (document.createDocumentFragment());
// CONCATENATED MODULE: ./src/jsbridge.js


let callbackMap = {};
let uniqueId = 1;
/**
* lark bridge规则下的调用invoke方式，用于组件通用事件
*/

function bridgeInvoke(methodName, data = {}, callback) {
  invoke('nativeTagAction', {
    methodName,
    data
  }, callback);
}
/*
* 用于自定义组件自己定义的接口
*/

function dispatchAction(methodName, data = {}, callback) {
  invoke('dispatchAction', {
    methodName,
    data
  }, callback);
}

function invoke(handlerName, data, callback) {
  callback = callback || noop;
  const callbackID = 'cb_' + uniqueId++ + '_' + new Date().getTime();
  let message = {
    apiName: handlerName,
    data,
    callbackID
  };
  callbackMap[callbackID] = callback;
  console.info('nc:invoke', message);

  if (isAndroid()) {
    window.Lark_Bridge && window.Lark_Bridge.invokeNative(JSON.stringify(message));
  } else {
    window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.invokeNative && window.webkit.messageHandlers.invokeNative.postMessage(message);
  }
}

let insertData = [];
let insertCallbacks = {};
let rid = null;
function invokeInsertNativeTag(data, callback) {
  insertData.push(data);
  insertCallbacks[data.id] = callback;
  rid && window.cancelAnimationFrame(rid);
  rid = window.requestAnimationFrame(() => {
    if (!insertData.length) {
      return;
    }

    const insertCallbacksForResponse = insertCallbacks;
    bridgeInvoke('insertNativeTag', {
      data: [...insertData]
    }, res => {
      if (Object.keys(res).length == 0) {
        return;
      }

      for (let key of Object.keys(res)) {
        let cb = insertCallbacksForResponse[key];
        let result = res[key];

        if (cb) {
          cb({
            result
          });
        }
      }
    });
    insertData.length = 0;
    insertCallbacks.length = 0;
  });
} // Lark的新webview使用

(function () {
  class CallBackHandler {
    nativeCallBack(response) {
      const {
        callbackID,
        data
      } = response;
      let callback = callbackMap[callbackID];

      if (!callback) {
        return;
      }

      callback(data);
      delete callbackMap[callbackID];
    }

  }

  window.LarkWebViewJavaScriptBridge = new CallBackHandler();
})();
/*
 * 客户端抛过来的事件
 */


window.onLKNativeRenderComponentEvent = function (data) {
  const {
    action,
    id,
    params
  } = data;
  event_bus.dispatchEvent(new CustomEvent('nativeComponentActon', {
    'detail': data
  }));
};
// CONCATENATED MODULE: ./src/base-element.js
class BaseElement extends HTMLElement {
  getProperty(name) {
    const staticProperties = this.constructor.properties;

    if (typeof staticProperties[name] === 'function') {
      return staticProperties[name](this);
    }

    return this.getAttribute(name);
  }

}
// CONCATENATED MODULE: ./src/native.js
function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }





const State = {
  Inited: 0,
  Inserting: 1,
  Inserted: 2,
  InsertError: 3
};

function generateId() {
  // 和native定义好了查找view的规则
  let id = (~~(Math.random() * 0xffffff)).toString(16);

  while (id.length < 6) {
    id = '0' + id;
  }

  return id;
}

;
class native_NativeElement extends BaseElement {
  updateStyleProperties() {
    const style = window.getComputedStyle(this);
    this.cachedStyleProperties = {
      borderRadius: style.borderRadius,
      // 圆角
      objectFit: style.objectFit || 'fill',
      // 布局
      backgroundColor: style.backgroundColor // 背景色

    };
    return this.cachedStyleProperties;
  }

  static get properties() {
    return {};
  } // 更新的属性


  static get observedAttributes() {
    const attrs = Object.keys(this.properties).map(hyphenate);
    return ['style', 'class', ...attrs];
  }

  constructor() {
    super();

    _defineProperty(this, "_id", "");

    _defineProperty(this, "counter", 0);

    _defineProperty(this, "tagName", this.tagName.toLowerCase());

    _defineProperty(this, "state", State.Inited);

    _defineProperty(this, "acionHandler", customEvent => {
      const {
        action,
        id,
        params
      } = customEvent.detail;

      if (id == this._id) {
        this.dispatchEvent(new CustomEvent(action, {
          'detail': params
        }));
      }
    });

    _defineProperty(this, "cachedStyleProperties", {});

    _defineProperty(this, "cachedAttributes", []);

    this._id = generateId();
  } // 因为样式修改，需要js手动去调用插入。


  manuallyInserToNative() {
    if (this.state == State.Inserted) {
      // 已经插入成功的不允许再插入
      return;
    }

    nextTick(() => this.insertToNative());
  } // 手动删除节点，供外部使用接口


  manuallyRemoveToNative() {
    nextTick(() => this.removeToNative());
  } // 插入方法


  insertToNative() {
    if (this.offsetParent === null) {
      // 被隐藏了。
      this.state == State.InsertError;
      return;
    }

    this.state = State.Inserting; // 获取所有property

    this.updateStyleProperties();
    let data = { ...this.cachedStyleProperties
    };
    const staticProperties = this.constructor.properties;
    Object.keys(staticProperties).forEach(name => {
      data[name] = this.getProperty(name);
    });

    const _insertToNative = () => {
      invokeInsertNativeTag({
        id: this._id,
        tagName: this.tagName,
        data
      }, res => {
        this.counter++;

        if (res.result === 0) {
          this.state = State.Inserted;
          return;
        }

        if (this.counter > 10) {
          this.state = State.InsertError;
          return;
        }

        const nextTime = fibonacci(this.counter) * 40;
        setTimeout(_insertToNative, nextTime);
      });
    };

    _insertToNative();

    this.cachedAttributes = [];
  } // 更新属性方法


  updateToNative() {
    if (this.state < State.Inserted || this.state === State.InsertError || !this.cachedAttributes.length) {
      return;
    }

    let needUpdateStyle = false;
    let data = {};
    this.cachedAttributes.forEach(attrName => {
      if (['class', 'style'].indexOf(attrName) > -1) {
        needUpdateStyle = true;
        return;
      }

      const name = camelCased(attrName);
      data[name] = this.getProperty(name);
    });

    if (needUpdateStyle) {
      this.updateStyleProperties();
    }

    bridgeInvoke('updateNativeTag', {
      data: [{
        id: this._id,
        tagName: this.tagName,
        data: { ...data,
          ...this.cachedStyleProperties
        }
      }]
    }, res => {
      const {
        respTime,
        recvTime
      } = res;
    }); // 清除 cachedAttributes

    this.cachedAttributes = [];
  }

  removeToNative() {
    bridgeInvoke('removeNativeTag', {
      data: [{
        id: this._id,
        tagName: this.tagName
      }]
    }, res => {
      const {
        respTime,
        recvTime
      } = res;
    });
    this.state = State.Inited;
    this.cachedAttributes = [];
  } // 生命周期


  connectedCallback() {
    // 这个地方的作用是创建innerHtml。我们是通过这种方式去定位到具体的scrollview
    this.buildInnerHTML(); // 这里调用接口告诉客户端，将本标签替换为Native视图
    // 延迟调插入，避免有数据更新没有一起发送

    nextTick(() => this.insertToNative());
    event_bus.addEventListener('nativeComponentActon', this.acionHandler);
  }

  disconnectedCallback() {
    // 这里调用接口告诉客户端，将native视图移除
    this.innerHTML = '';
    this.removeToNative();
    event_bus.removeEventListener('nativeComponentActon', this.acionHandler);
  }

  attributeChangedCallback(attrName, oldVal, newVal) {
    // 属性更改，这里需要告诉客户端属性发生修改。
    if (this.firstChild) {
      return;
    }

    this.cachedAttributes.push(attrName);
    nextTick(() => this.updateToNative());
  }

  buildInnerHTML() {
    if (isIOS()) {
      // 构造 native wkCompositingView 对应的 dom 结构
      // 这里不用 template string 的原因是html里不能有空格，否则被 pre 标签包裹的标签会受到影响
      this.innerHTML = [`<native-element-inner style="-webkit-overflow-scrolling:touch;overflow:scroll;width:100%;height:100%;display:block;user-select:none; background: #${this._id}01">`, '<div style="width: 100%; height:100%; margin-top: 1px"></div>', '</native-element-inner>'].join('');
    } else {
      this.innerHTML = `<div tt-render-in-browser="${this._id}" style="width:100%;height:100%;user-select:none;"></div>`;
    }
  }

}
// CONCATENATED MODULE: ./src/lk-native-avatar/lk-native-avatar.js

class lk_native_avatar_LKNativeAvatar extends native_NativeElement {
  static get properties() {
    return {
      entityid: el => el.getAttribute('entityid'),
      avatarkey: el => el.getAttribute('avatarkey'),
      name: el => el.getAttribute('name')
    };
  }

}
// CONCATENATED MODULE: ./index.js



function registerCustomComponent() {
  console.log(lk_native_avatar_LKNativeAvatar);
  customElements.define('lk-native-avatar', lk_native_avatar_LKNativeAvatar);
}

(function () {
  registerCustomComponent();
})();

/***/ })
/******/ ]);
