(window["webpackJsonp"] = window["webpackJsonp"] || []).push([[6],{

/***/ 1855:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "Icon", function() { return Icon; });
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "Button", function() { return Button; });
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "TextField", function() { return TextField; });
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "Select", function() { return Select; });
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "Popover", function() { return Popover; });
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "Tooltip", function() { return Tooltip; });
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "Dialog", function() { return Dialog$1; });
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "Breadcrumb", function() { return Breadcrumb; });
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "Menu", function() { return Menu; });
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "Dropdown", function() { return Dropdown; });
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "ContextMenu", function() { return ContextMenu; });
/* harmony import */ var react__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(1);
/* harmony import */ var react__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(react__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var prop_types__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(2);
/* harmony import */ var prop_types__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(prop_types__WEBPACK_IMPORTED_MODULE_1__);
/* harmony import */ var classnames__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(137);
/* harmony import */ var classnames__WEBPACK_IMPORTED_MODULE_2___default = /*#__PURE__*/__webpack_require__.n(classnames__WEBPACK_IMPORTED_MODULE_2__);
/* harmony import */ var lodash_es__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(109);
/* harmony import */ var lodash_es__WEBPACK_IMPORTED_MODULE_4__ = __webpack_require__(409);
/* harmony import */ var lodash_es__WEBPACK_IMPORTED_MODULE_5__ = __webpack_require__(352);
/* harmony import */ var lodash_es__WEBPACK_IMPORTED_MODULE_6__ = __webpack_require__(1576);
/* harmony import */ var lodash_es__WEBPACK_IMPORTED_MODULE_7__ = __webpack_require__(116);
/* harmony import */ var lodash_es__WEBPACK_IMPORTED_MODULE_8__ = __webpack_require__(1425);
/* harmony import */ var lodash_es__WEBPACK_IMPORTED_MODULE_9__ = __webpack_require__(124);
/* harmony import */ var lodash_es__WEBPACK_IMPORTED_MODULE_10__ = __webpack_require__(21);
/* harmony import */ var lodash_es__WEBPACK_IMPORTED_MODULE_11__ = __webpack_require__(264);
/* harmony import */ var lodash_es__WEBPACK_IMPORTED_MODULE_12__ = __webpack_require__(3879);
/* harmony import */ var lodash_es__WEBPACK_IMPORTED_MODULE_13__ = __webpack_require__(115);
/* harmony import */ var lodash_es__WEBPACK_IMPORTED_MODULE_14__ = __webpack_require__(365);
/* harmony import */ var lodash_es__WEBPACK_IMPORTED_MODULE_15__ = __webpack_require__(777);
/* harmony import */ var react_dom__WEBPACK_IMPORTED_MODULE_16__ = __webpack_require__(46);
/* harmony import */ var react_dom__WEBPACK_IMPORTED_MODULE_16___default = /*#__PURE__*/__webpack_require__.n(react_dom__WEBPACK_IMPORTED_MODULE_16__);
/* harmony import */ var bowser__WEBPACK_IMPORTED_MODULE_17__ = __webpack_require__(72);
/* harmony import */ var bowser__WEBPACK_IMPORTED_MODULE_17___default = /*#__PURE__*/__webpack_require__.n(bowser__WEBPACK_IMPORTED_MODULE_17__);
/* eslint-disable */









var _typeof = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) { return typeof obj; } : function (obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; };

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
/* global Reflect, Promise */

var _extendStatics = function extendStatics(d, b) {
    _extendStatics = Object.setPrototypeOf || { __proto__: [] } instanceof Array && function (d, b) {
        d.__proto__ = b;
    } || function (d, b) {
        for (var p in b) {
            if (b.hasOwnProperty(p)) d[p] = b[p];
        }
    };
    return _extendStatics(d, b);
};

function __extends(d, b) {
    _extendStatics(d, b);
    function __() {
        this.constructor = d;
    }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
}

var _assign = function __assign() {
    _assign = Object.assign || function __assign(t) {
        for (var s, i = 1, n = arguments.length; i < n; i++) {
            s = arguments[i];
            for (var p in s) {
                if (Object.prototype.hasOwnProperty.call(s, p)) t[p] = s[p];
            }
        }
        return t;
    };
    return _assign.apply(this, arguments);
};



function __decorate(decorators, target, key, desc) {
    var c = arguments.length,
        r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc,
        d;
    if ((typeof Reflect === "undefined" ? "undefined" : _typeof(Reflect)) === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);else for (var i = decorators.length - 1; i >= 0; i--) {
        if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    }return c > 3 && r && Object.defineProperty(target, key, r), r;
}

var _extends = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Add = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends({ width: "16", height: "16", viewBox: "0 0 16 16", xmlns: "http://www.w3.org/2000/svg" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { d: "M7 7V3a1 1 0 1 1 2 0v4h4a1 1 0 0 1 0 2H9v4a1 1 0 0 1-2 0V9H3a1 1 0 1 1 0-2h4z", fill: "currentColor", fillRule: "evenodd" }));
});

var _extends$1 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$1(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Arrowright = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$1(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$1({ xmlns: "http://www.w3.org/2000/svg", width: "16", height: "16", viewBox: "0 0 451.846 451.847", fill: "currentColor" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { d: "M345.441 248.292L151.154 442.573c-12.359 12.365-32.397 12.365-44.75 0-12.354-12.354-12.354-32.391 0-44.744L278.318 225.92 106.409 54.017c-12.354-12.359-12.354-32.394 0-44.748 12.354-12.359 32.391-12.359 44.75 0l194.287 194.284c6.177 6.18 9.262 14.271 9.262 22.366 0 8.099-3.091 16.196-9.267 22.373z" }));
});

var _extends$2 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$2(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Checkcircledark = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$2(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$2({ width: "16", height: "16", viewBox: "0 0 16 16", xmlns: "http://www.w3.org/2000/svg" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { d: "M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14zM4.166 7.162a.358.358 0 1 0-.506.506l3.318 3.318 5.362-5.361a.358.358 0 1 0-.506-.506L6.978 9.974 4.166 7.162z", fillRule: "nonzero", fill: "#707473" }));
});

var _extends$3 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$3(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Checkcircle = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$3(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$3({ width: "16", height: "16", viewBox: "0 0 16 16", xmlns: "http://www.w3.org/2000/svg" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { d: "M8 14.3A6.3 6.3 0 1 0 8 1.7a6.3 6.3 0 0 0 0 12.6zm0 .7A7 7 0 1 1 8 1a7 7 0 0 1 0 14zM4.55 7.246a.322.322 0 0 0-.456.455l2.986 2.986 4.826-4.825a.322.322 0 1 0-.455-.455l-4.37 4.37-2.532-2.531z", fillRule: "nonzero", fill: "currentColor" }));
});

var _extends$4 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$4(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Check = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$4(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$4({ width: "20", height: "20", viewBox: "0 0 10 9", xmlns: "http://www.w3.org/2000/svg" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { strokeWidth: "2", strokeLinecap: "round", d: "M1 4l2 3 6-6", stroke: "currentColor", fill: "none" }));
});

var _extends$5 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$5(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Closecircle = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$5(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$5({ className: styles["icon"] || "icon", viewBox: "0 0 1024 1024", xmlns: "http://www.w3.org/2000/svg", width: "16", height: "16" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { d: "M512 0C229.2 0 0 229.2 0 512s229.2 512 512 512 512-229.2 512-512S794.8 0 512 0zm205.3 666.9c14 14.1 14 36.9-.1 50.9-7 7-16.2 10.5-25.4 10.5s-18.5-3.5-25.5-10.6L512 563 357.7 717.7c-7 7.1-16.3 10.6-25.5 10.6s-18.4-3.5-25.4-10.5c-14.1-14-14.1-36.8-.1-50.9L461.2 512 306.7 357.1c-14-14.1-14-36.9.1-50.9s36.9-14 50.9.1L512 461l154.3-154.8c14-14.1 36.8-14.1 50.9-.1 14.1 14 14.1 36.8.1 50.9L562.8 512l154.5 154.9z", fill: "currentColor" }));
});

var _extends$6 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$6(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Close = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$6(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$6({ xmlns: "http://www.w3.org/2000/svg", width: "16", height: "16", viewBox: "32 32 448 448" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { fill: "currentColor", d: "M430.933 110.933l-29.866-29.867L256 221.866l-145.066-140.8-29.867 29.867 140.8 145.066-140.8 145.067 29.867 29.866L256 290.132l145.067 140.8 29.866-29.866-140.8-145.067z" }));
});

var _extends$7 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$7(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Color = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$7(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$7({ xmlns: "http://www.w3.org/2000/svg", width: "16", height: "16", viewBox: "4 4 16 16" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { fill: "currentColor", d: "M14.326 4.062l2.44 1.387c.224.128.3.41.171.632l-4.276 7.293-3.252-1.85 4.275-7.293a.473.473 0 0 1 .642-.169zm-5.387 8.263l3.253 1.85-.94 1.602c-.446-.25-.747-.33-.904-.24-.157.09-.314.245-.47.463H8c.387-.56.582-.966.583-1.218 0-.251-.193-.536-.583-.855l.939-1.602zM5.5 17.03h13a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5h-13a.5.5 0 0 1-.5-.5v-1a.5.5 0 0 1 .5-.5z" }));
});

var _extends$8 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$8(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Complete = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$8(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$8({ xmlns: "http://www.w3.org/2000/svg", width: "16", height: "16", viewBox: "3 3 18 18" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { fill: "currentColor", d: "M12 21a9 9 0 1 1 0-18 9 9 0 0 1 0 18zm0-2a7 7 0 1 0 0-14 7 7 0 0 0 0 14zm3.651-10.33l.732.677a.5.5 0 0 1 .035.698l-5.009 5.674a.5.5 0 0 1-.706.044l-2.986-2.639a.5.5 0 0 1-.047-.701l.65-.754a.5.5 0 0 1 .713-.046l1.7 1.525a.25.25 0 0 0 .356-.022l3.846-4.417a.5.5 0 0 1 .716-.038z" }));
});

var _extends$9 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$9(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Download = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$9(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$9({ xmlns: "http://www.w3.org/2000/svg", width: "16", height: "16", viewBox: "3 3 18 18" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { fill: "currentColor", d: "M11.095 15.322l-.097-.096L8.16 12.32a.5.5 0 0 1 0-.707l.706-.708a.5.5 0 0 1 .707 0l1.419 1.486-.016-8.067a.5.5 0 0 1 .499-.501l1-.003a.5.5 0 0 1 .501.499l.018 8.078 1.46-1.489a.5.5 0 0 1 .706 0l.708.705a.5.5 0 0 1 0 .707l-3.518 3.541a.5.5 0 0 1-.704.003l-.352-.347-.198-.195zM18 18v-4.5a.5.5 0 0 1 .5-.5h1a.5.5 0 0 1 .5.5v5a1.5 1.5 0 0 1-1.5 1.5h-13A1.5 1.5 0 0 1 4 18.5v-5a.5.5 0 0 1 .5-.5h1a.5.5 0 0 1 .5.5V18h12z" }));
});

var _extends$10 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$10(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Edit = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$10(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$10({ width: "16", height: "16", viewBox: "2 3 10 10", xmlns: "http://www.w3.org/2000/svg" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { d: "M9.004 5.286L7.767 4.05l.802-.793a.888.888 0 0 1 1.252.004.87.87 0 0 1-.009 1.24l-.808.786zm-.679.66L4.516 9.654 3 9.803l.077-1.12 4.016-3.968 1.232 1.232zm-5.014 4.94h8v1.045h-8v-1.044z", fill: "currentColor", fillRule: "evenodd" }));
});

var _extends$11 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$11(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Enter = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$11(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$11({ width: "16", height: "16", viewBox: "0 0 17 17", xmlns: "http://www.w3.org/2000/svg" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { d: "M3 11h1v2a1 1 0 0 0 1 1h9a1 1 0 0 0 1-1V4a1 1 0 0 0-1-1H5a1 1 0 0 0-1 1v2H3V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-2zm6.793-3L7.818 6.025a.5.5 0 0 1 .707-.707L11.707 8.5l-3.182 3.182a.5.5 0 1 1-.707-.707L9.793 9H1.5a.5.5 0 0 1 0-1h8.293zM3 11h1v2a1 1 0 0 0 1 1h9a1 1 0 0 0 1-1V4a1 1 0 0 0-1-1H5a1 1 0 0 0-1 1v2H3V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-2z", fillRule: "nonzero", fill: "currentColor" }));
});

var _extends$12 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$12(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Export = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$12(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$12({ xmlns: "http://www.w3.org/2000/svg", width: "16", height: "16", viewBox: "3 3 18 18" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { fill: "currentColor", d: "M20.707 12.707l.002.001-.197.197-.095.097h-.001l-2.36 2.363a.5.5 0 0 1-.708.001l-.707-.707a.5.5 0 0 1-.001-.707l.942-.943-6.067.016a.5.5 0 0 1-.502-.499l-.003-1a.5.5 0 0 1 .499-.501l6.079-.018-.938-.935a.5.5 0 0 1-.001-.707l.705-.708a.5.5 0 0 1 .708 0l2.99 2.994a.5.5 0 0 1 .002.704l-.347.352zM8 18h4.5a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5h-5A1.5 1.5 0 0 1 6 18.5v-13A1.5 1.5 0 0 1 7.5 4h5a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5H8v12z" }));
});

var _extends$13 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$13(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var H1 = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$13(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$13({ xmlns: "http://www.w3.org/2000/svg", width: "16", height: "16", viewBox: "3 3 18 18" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { fill: "currentColor", fillRule: "evenodd", d: "M6 11h5V5.5a.5.5 0 0 1 .5-.5h1a.5.5 0 0 1 .5.5v13a.5.5 0 0 1-.5.5h-1a.5.5 0 0 1-.5-.5V13H6v5.5a.5.5 0 0 1-.5.5h-1a.5.5 0 0 1-.5-.5v-13a.5.5 0 0 1 .5-.5h1a.5.5 0 0 1 .5.5V11zm10.32 2.226h-.82V11.5l.69-.149c.36-.09.749-.25 1.154-.474a5.1 5.1 0 0 0 1.03-.8l.18-.077h1.306v9.068H18l-.044-6.606c-.466.33-1.01.584-1.637.764z" }));
});

var _extends$14 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$14(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var H2 = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$14(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$14({ xmlns: "http://www.w3.org/2000/svg", width: "16", height: "16", viewBox: "3 3 18 18" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { fill: "currentColor", fillRule: "evenodd", d: "M6 11h5V5.5a.5.5 0 0 1 .5-.5h1a.5.5 0 0 1 .5.5v13a.5.5 0 0 1-.5.5h-1a.5.5 0 0 1-.5-.5V13H6v5.5a.5.5 0 0 1-.5.5h-1a.5.5 0 0 1-.5-.5v-13a.5.5 0 0 1 .5-.5h1a.5.5 0 0 1 .5.5V11zm14.476 6.264V19H14v-.25c0-.943.302-1.757.913-2.444.33-.381 1.006-.92 2.014-1.613.508-.354.893-.67 1.132-.92.335-.379.501-.777.501-1.191 0-.396-.104-.682-.29-.859-.197-.178-.508-.271-.948-.271-.452 0-.772.145-.991.444-.226.287-.357.752-.38 1.379l-.008.241h-1.898l.003-.253c.013-1.022.312-1.85.905-2.48.612-.679 1.424-1.019 2.417-1.019.887 0 1.63.26 2.22.785.583.53.874 1.21.874 2.045 0 .8-.306 1.532-.907 2.199-.34.364-.927.817-1.822 1.418-.594.39-1.02.744-1.276 1.053h4.017z" }));
});

var _extends$15 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$15(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var H3 = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$15(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$15({ xmlns: "http://www.w3.org/2000/svg", width: "16", height: "16", viewBox: "3 3 18 18" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { fill: "currentColor", fillRule: "evenodd", d: "M6 11h5V5.5a.5.5 0 0 1 .5-.5h1a.5.5 0 0 1 .5.5v13a.5.5 0 0 1-.5.5h-1a.5.5 0 0 1-.5-.5V13H6v5.5a.5.5 0 0 1-.5.5h-1a.5.5 0 0 1-.5-.5v-13a.5.5 0 0 1 .5-.5h1a.5.5 0 0 1 .5.5V11zm14.264 3.612c.33.37.495.85.495 1.414 0 .861-.304 1.576-.91 2.13-.628.562-1.445.844-2.436.844-.945 0-1.721-.247-2.308-.743-.653-.548-1.02-1.353-1.097-2.38l-.02-.269h1.937l.01.24c.022.498.17.861.448 1.11.254.234.59.354 1.018.354.476 0 .847-.132 1.108-.383.233-.233.346-.507.346-.843 0-.413-.12-.703-.354-.888-.23-.193-.59-.29-1.1-.29h-.85v-1.556h.85c.451 0 .78-.093.99-.264.194-.166.296-.421.296-.77 0-.35-.092-.598-.26-.758-.201-.173-.516-.264-.954-.264-.449 0-.771.103-.999.31-.235.206-.377.53-.42.987l-.02.227h-1.88l.022-.27c.078-.936.424-1.667 1.043-2.183.582-.517 1.334-.771 2.242-.771.925 0 1.685.224 2.258.68.58.472.872 1.121.872 1.934 0 .838-.353 1.466-1.034 1.86.29.148.526.328.707.542z" }));
});

var _extends$16 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$16(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Images = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$16(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$16({ xmlns: "http://www.w3.org/2000/svg", width: "16", height: "16", viewBox: "4 4 16 16" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { fill: "currentColor", d: "M17 11.761V7H7v6.261l.563-.609a2.631 2.631 0 0 1 3.367-.421c.293.19.68.157.936-.081l1.855-1.723a1.5 1.5 0 0 1 2.12.079L17 11.761zm0 2.949l-2.285-2.476-1.488 1.381a2.765 2.765 0 0 1-3.387.292.631.631 0 0 0-.808.102L7 16.21V17h10v-2.29zM6 5h12a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1zm3 5a1 1 0 1 1 0-2 1 1 0 0 1 0 2z" }));
});

var _extends$17 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$17(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Message = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$17(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$17({ xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 512 512", width: "16", height: "16", fill: "currentColor" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { d: "M511.609 197.601c-.001-.77-.173-1.933-.472-2.603a13.069 13.069 0 0 0-5.154-7.281l-73.292-50.948V82.153c0-7.24-5.872-13.112-13.112-13.112H335.26l-71.743-49.878a13.104 13.104 0 0 0-14.935-.026l-72.206 49.904h-83.95c-7.242 0-13.112 5.872-13.112 13.112v53.973L5.666 187.027c-3.623 2.504-5.583 6.507-5.645 10.6-.004.077-.021.15-.021.23l.391 284.235a13.118 13.118 0 0 0 3.852 9.266 13.114 13.114 0 0 0 9.26 3.827h.018l485.385-.667c7.24-.01 13.104-5.889 13.094-13.13l-.391-283.787zm-78.919-28.893l41.898 29.118-41.898 29.128v-58.246zM256.015 45.884l33.31 23.156h-66.812l33.502-23.156zM105.538 95.265h300.928v149.921L305.43 315.428l-41.194-31.954c-.064-.05-.119-.081-.181-.126-4.604-3.454-11.116-3.581-15.894.126l-41.493 32.185-101.13-69.893V95.265zm-26.224 72.738v59.64l-43.146-29.819 43.146-29.821zm-53.056 54.864l158.669 109.655L26.578 455.346l-.32-232.479zm25.617 246.042l204.324-158.484L459.79 468.348l-407.915.561zm275.269-136.638L485.42 222.235l.32 233.059-158.596-123.023z" }), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { d: "M344.77 147.713H167.234c-7.24 0-13.112 5.872-13.112 13.112s5.872 13.112 13.112 13.112H344.77c7.242 0 13.112-5.872 13.112-13.112s-5.87-13.112-13.112-13.112zM344.77 215.895H167.234c-7.24 0-13.112 5.872-13.112 13.112s5.872 13.112 13.112 13.112H344.77c7.242 0 13.112-5.872 13.112-13.112s-5.87-13.112-13.112-13.112z" }));
});

var _extends$18 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$18(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Mindmapnote = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$18(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$18({ xmlns: "http://www.w3.org/2000/svg", width: "16", height: "16", viewBox: "2 2 18 18" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("g", { fill: "currentColor", fillRule: "evenodd", stroke: "#FFF", strokeWidth: "1.5" }, react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("circle", { cx: "11", cy: "11", r: "8.25" }), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("circle", { cx: "11", cy: "11", r: "8.25" }), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { fill: "#FFF", fillRule: "nonzero", d: "M11.03 7.75h3.986l-.75-.75v1.5l.75-.75h-3.985zm0 0H7.046l.75.75V7l-.75.75h3.986zm0 3h3.986l-.75-.75v1.5l.75-.75h-3.985zm0 0H7.046l.75.75V10l-.75.75h3.986zm0 3h3.986l-.75-.75v1.5l.75-.75h-3.985zm0 0H7.046l.75.75V13l-.75.75h3.986z" })));
});

var _extends$19 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$19(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Moon = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$19(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$19({ xmlns: "http://www.w3.org/2000/svg", width: "16", height: "16", viewBox: "-32 16 480 480" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { fill: "currentColor", d: "M349.631 363.808q-14.303 2.384-29.137 2.384-48.209 0-89.266-23.84t-64.897-64.897-23.84-89.266q0-50.858 27.548-94.564-53.242 15.894-87.014 60.659T49.252 256q0 34.435 13.509 65.824t36.157 54.036 54.036 36.157 65.824 13.509q38.144 0 72.447-16.291t58.407-45.428zm53.772-22.515q-24.899 53.772-75.095 85.956t-109.531 32.184q-41.322 0-78.936-16.158t-64.897-43.441-43.441-64.897-16.158-78.936q0-40.528 15.231-77.479t41.322-63.97 62.38-43.573 76.817-18.145q11.655-.53 16.158 10.331 4.768 10.86-3.973 19.072-22.78 20.661-34.833 48.076t-12.053 57.877q0 39.203 19.337 72.314t52.447 52.447 72.314 19.337q31.257 0 60.394-13.509 10.861-4.768 19.072 3.443 3.709 3.709 4.635 9.007t-1.192 10.065z" }));
});

var _extends$20 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$20(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Navigationmap = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$20(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$20({ xmlns: "http://www.w3.org/2000/svg", width: "16", height: "16", viewBox: "2 8 28 18" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { fill: "currentColor", fillRule: "evenodd", d: "M12 17v6a2 2 0 0 1-2 2H6.732a2 2 0 1 1 0-2H10v-6H6.732a2 2 0 1 1 0-2H10V9H6.732a2 2 0 1 1 0-2H10a2 2 0 0 1 2 2v6h1.17a3.001 3.001 0 0 1 5.66 0H20V9a2 2 0 0 1 2-2h3.268a2 2 0 1 1 0 2H22v6h3.268a2 2 0 1 1 0 2H22v6h3.268a2 2 0 1 1 0 2H22a2 2 0 0 1-2-2v-6h-1.17a3.001 3.001 0 0 1-5.66 0H12z" }));
});

var _extends$21 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$21(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Note = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$21(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$21({ xmlns: "http://www.w3.org/2000/svg", width: "16", height: "16", viewBox: "3 3 18 18" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { fill: "currentColor", d: "M10.17 17h9.298a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5H4.61a.5.5 0 0 1-.5-.5v-1c0-.04.005-.077.013-.114a1.5 1.5 0 0 1 .05-.626l1.103-3.71a1.5 1.5 0 0 1 .332-.586l8.25-9.01a1.5 1.5 0 0 1 2.12-.094l.01.01 2.518 2.348a1.5 1.5 0 0 1 .084 2.11l-8.253 9.014a1.5 1.5 0 0 1-.169.158zm3.328-10.191l.018.016 1.77 1.65 1.495-1.632-1.788-1.667-1.495 1.633zm-1.35 1.475L7.162 13.73l-.785 2.637 2.566-.963 4.992-5.453-1.783-1.663a1.021 1.021 0 0 1-.004-.004z" }));
});

var _extends$22 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$22(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Plus = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$22(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$22({ width: "16", height: "16", viewBox: "0 0 16 16", xmlns: "http://www.w3.org/2000/svg" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { d: "M8.35 7.65v-5.8a.35.35 0 1 0-.7 0v5.8h-5.8a.35.35 0 1 0 0 .7h5.8v5.8a.35.35 0 1 0 .7 0v-5.8h5.8a.35.35 0 1 0 0-.7h-5.8z", strokeWidth: "2", fill: "currentColor", fillRule: "evenodd" }));
});

var _extends$23 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$23(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Pulldown = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$23(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$23({ width: "16", height: "16", viewBox: "0 0 16 16", xmlns: "http://www.w3.org/2000/svg" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("g", { fill: "none", fillRule: "evenodd" }, react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { d: "M10.93 7.335L9 9.768a1 1 0 0 1-1.567 0l-1.93-2.433a1 1 0 0 1 .783-1.621h3.86a1 1 0 0 1 .784 1.621z", fill: "currentColor" }), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { d: "M0 0h16v16H0z" })));
});

var _extends$24 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$24(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Refresh = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$24(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$24({ width: "16", height: "16", viewBox: "0 0 16 16", xmlns: "http://www.w3.org/2000/svg" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { d: "M11.31 6.45H15V2.742h-.716v2.301C13.17 2.663 10.784 1 7.968 1 4.134 1 1 4.132 1 8c0 3.852 3.118 7 6.968 7 2.625 0 4.9-1.47 6.11-3.628h-.844a6.232 6.232 0 0 1-5.25 2.893c-3.436 0-6.22-2.813-6.22-6.249 0-3.436 2.784-6.249 6.204-6.249 2.641 0 4.884 1.662 5.807 3.98h-2.466v.703z", fillRule: "nonzero", fill: "currentColor" }));
});

var _extends$25 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$25(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Setting = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$25(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$25({ xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 511.999 511.999", width: "16", height: "16", fill: "currentColor" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { d: "M489.175 206.556a1566.991 1566.991 0 0 0-29.379-4.111c-1.195-.155-2.165-.966-2.467-2.064a207.8 207.8 0 0 0-19.636-47.389c-.57-1.002-.463-2.266.273-3.223a1575.02 1575.02 0 0 0 17.876-23.69c7.824-10.578 6.688-25.588-2.64-34.917l-32.366-32.366c-9.329-9.328-24.338-10.464-34.918-2.638a1579.273 1579.273 0 0 0-23.689 17.875c-.954.736-2.221.843-3.223.274a207.812 207.812 0 0 0-47.389-19.637c-1.099-.301-1.91-1.271-2.066-2.469a1587.93 1587.93 0 0 0-4.109-29.376C303.495 9.812 292.079 0 278.886 0h-45.773c-13.194 0-24.61 9.812-26.554 22.824a1579.752 1579.752 0 0 0-4.11 29.379c-.157 1.197-.967 2.165-2.067 2.467a207.876 207.876 0 0 0-47.387 19.637c-1.003.569-2.269.459-3.225-.274a1575.991 1575.991 0 0 0-23.69-17.876c-10.581-7.825-25.59-6.687-34.917 2.64L58.797 91.163c-9.329 9.33-10.464 24.341-2.638 34.918a1580.844 1580.844 0 0 0 17.875 23.688c.735.955.843 2.22.274 3.223a207.826 207.826 0 0 0-19.637 47.389c-.301 1.097-1.271 1.908-2.467 2.065a1587.026 1587.026 0 0 0-29.378 4.111C9.812 208.502 0 219.92 0 233.112v45.774c0 13.193 9.812 24.61 22.824 26.556a1578.724 1578.724 0 0 0 29.379 4.11c1.197.157 2.165.967 2.467 2.066a207.833 207.833 0 0 0 19.637 47.389c.569 1.003.461 2.268-.274 3.223a1571.918 1571.918 0 0 0-17.875 23.689c-7.825 10.578-6.691 25.589 2.638 34.918l32.366 32.366c9.33 9.329 24.341 10.465 34.918 2.638a1579.273 1579.273 0 0 0 23.689-17.875c.955-.736 2.221-.842 3.223-.274a207.846 207.846 0 0 0 47.389 19.637c1.099.302 1.91 1.271 2.066 2.467 1.289 9.88 2.672 19.765 4.11 29.376 1.946 13.013 13.362 22.825 26.556 22.825h45.773c13.193 0 24.61-9.812 26.555-22.827a1597.167 1597.167 0 0 0 4.109-29.376c.157-1.197.967-2.166 2.066-2.469a207.902 207.902 0 0 0 47.388-19.637c1.003-.567 2.268-.459 3.224.274a1574.173 1574.173 0 0 0 23.689 17.875c10.578 7.825 25.588 6.691 34.918-2.638l32.366-32.366c9.328-9.329 10.464-24.339 2.639-34.918a1607.832 1607.832 0 0 0-17.876-23.689c-.735-.955-.843-2.22-.273-3.223a207.841 207.841 0 0 0 19.636-47.388c.304-1.1 1.272-1.91 2.469-2.067a1578.782 1578.782 0 0 0 29.378-4.11c13.013-1.945 22.825-13.362 22.825-26.555v-45.774c0-13.19-9.812-24.608-22.824-26.553zm-1.084 72.332c0 1.45-1.054 2.7-2.453 2.911a1571.912 1571.912 0 0 1-28.932 4.048c-10.758 1.402-19.56 9.024-22.426 19.42a183.951 183.951 0 0 1-17.375 41.932c-5.333 9.389-4.504 21.012 2.112 29.612a1559.297 1559.297 0 0 1 17.604 23.329c.842 1.137.702 2.769-.323 3.794L403.931 436.3c-1.026 1.026-2.657 1.163-3.793.324a1565.489 1565.489 0 0 1-23.33-17.605c-8.599-6.617-20.221-7.446-29.609-2.114a183.98 183.98 0 0 1-41.934 17.377c-10.394 2.865-18.016 11.667-19.421 22.426a1549.245 1549.245 0 0 1-4.047 28.932c-.209 1.399-1.461 2.453-2.911 2.453h-45.773c-1.45 0-2.702-1.054-2.911-2.454a1567.626 1567.626 0 0 1-4.047-28.93c-1.403-10.759-9.027-19.561-19.421-22.426a183.901 183.901 0 0 1-41.934-17.378 26.697 26.697 0 0 0-13.196-3.491 26.872 26.872 0 0 0-16.412 5.607 1570.69 1570.69 0 0 1-23.33 17.605c-1.138.839-2.767.702-3.792-.324l-32.367-32.366c-1.026-1.026-1.166-2.656-.324-3.793a1554.583 1554.583 0 0 1 17.604-23.33c6.615-8.6 7.445-20.221 2.114-29.609A183.93 183.93 0 0 1 77.72 305.27c-2.865-10.394-11.667-18.017-22.425-19.42a1574.379 1574.379 0 0 1-28.934-4.048c-1.399-.21-2.453-1.461-2.453-2.911v-45.774c0-1.45 1.054-2.701 2.453-2.911a1566.765 1566.765 0 0 1 28.932-4.048c10.759-1.402 19.561-9.025 22.426-19.42a183.86 183.86 0 0 1 17.377-41.934c5.332-9.389 4.502-21.011-2.113-29.609a1575.762 1575.762 0 0 1-17.604-23.33c-.84-1.137-.701-2.769.324-3.793l32.365-32.367c1.024-1.026 2.655-1.163 3.792-.324a1556.978 1556.978 0 0 1 23.33 17.605c8.6 6.614 20.221 7.445 29.611 2.112a183.928 183.928 0 0 1 41.932-17.377c10.395-2.865 18.019-11.667 19.422-22.426a1562.97 1562.97 0 0 1 4.048-28.933c.209-1.397 1.461-2.452 2.911-2.452h45.773c1.45 0 2.702 1.054 2.911 2.453a1555.746 1555.746 0 0 1 4.048 28.932c1.403 10.759 9.027 19.561 19.421 22.426a183.999 183.999 0 0 1 41.934 17.377c9.388 5.33 21.01 4.502 29.608-2.114a1568.83 1568.83 0 0 1 23.329-17.604c1.137-.842 2.769-.703 3.794.324l32.366 32.366c1.026 1.026 1.164 2.657.324 3.793a1549.126 1549.126 0 0 1-17.604 23.33c-6.615 8.601-7.445 20.223-2.112 29.612a183.928 183.928 0 0 1 17.377 41.933c2.865 10.394 11.669 18.016 22.424 19.418 9.716 1.268 19.451 2.63 28.934 4.048 1.399.21 2.453 1.461 2.453 2.911v45.773z" }), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { d: "M256 144.866c-61.28 0-111.134 49.854-111.134 111.134S194.72 367.134 256 367.134 367.134 317.28 367.134 256 317.28 144.866 256 144.866zm0 198.359c-48.097 0-87.225-39.129-87.225-87.225 0-48.097 39.13-87.225 87.225-87.225 48.096 0 87.225 39.129 87.225 87.225S304.097 343.225 256 343.225z" }));
});

var _extends$26 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$26(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Shoppingcart = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$26(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$26({ xmlns: "http://www.w3.org/2000/svg", width: "16", height: "16", viewBox: "0 0 511.999 511.999", fill: "currentColor" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { d: "M214.685 402.828c-24.829 0-45.029 20.2-45.029 45.029 0 24.829 20.2 45.029 45.029 45.029s45.029-20.2 45.029-45.029c-.001-24.829-20.201-45.029-45.029-45.029zm0 64.914c-10.966 0-19.887-8.922-19.887-19.887 0-10.966 8.922-19.887 19.887-19.887s19.887 8.922 19.887 19.887c0 10.967-8.922 19.887-19.887 19.887zM372.63 402.828c-24.829 0-45.029 20.2-45.029 45.029 0 24.829 20.2 45.029 45.029 45.029s45.029-20.2 45.029-45.029c-.001-24.829-20.201-45.029-45.029-45.029zm0 64.914c-10.966 0-19.887-8.922-19.887-19.887 0-10.966 8.922-19.887 19.887-19.887 10.966 0 19.887 8.922 19.887 19.887 0 10.967-8.922 19.887-19.887 19.887zM383.716 165.755H203.567c-6.943 0-12.571 5.628-12.571 12.571s5.629 12.571 12.571 12.571h180.149c6.943 0 12.571-5.628 12.571-12.571 0-6.944-5.628-12.571-12.571-12.571zM373.911 231.035H213.373c-6.943 0-12.571 5.628-12.571 12.571s5.628 12.571 12.571 12.571H373.91c6.943 0 12.571-5.628 12.571-12.571 0-6.942-5.628-12.571-12.57-12.571z" }), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { d: "M506.341 109.744a25.04 25.04 0 0 0-19.489-9.258H95.278L87.37 62.097a25.173 25.173 0 0 0-14.614-17.989l-55.177-23.95c-6.37-2.767-13.773.156-16.536 6.524-2.766 6.37.157 13.774 6.524 16.537L62.745 67.17l60.826 295.261c2.396 11.628 12.752 20.068 24.625 20.068h301.166c6.943 0 12.571-5.628 12.571-12.571s-5.628-12.571-12.571-12.571H148.197l-7.399-35.916H451.69c11.872 0 22.229-8.44 24.624-20.068l35.163-170.675a25.043 25.043 0 0 0-5.136-20.954zM451.69 296.301H135.619l-35.161-170.674 386.393.001-35.161 170.673z" }));
});

var _extends$27 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$27(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Sparklingstick = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$27(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$27({ xmlns: "http://www.w3.org/2000/svg", width: "16", height: "16", viewBox: "2 2 20 20" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { fill: "currentColor", fillRule: "evenodd", d: "M8.757 10.586l2.829-2.829 9.546 9.546a.5.5 0 0 1 0 .707l-2.122 2.122a.5.5 0 0 1-.707 0l-9.546-9.546zm1.415 0l2.12 2.121 1.415-1.414-2.121-2.121-1.414 1.414zM5.575 5.282l.707-.707a.5.5 0 0 1 .708 0L9.464 7.05 8.05 8.464 5.575 5.99a.5.5 0 0 1 0-.708zm-.707 9.193L7.343 12l1.414 1.414-2.475 2.475a.5.5 0 0 1-.707 0l-.707-.707a.5.5 0 0 1 0-.707zM13 6.343l2.475-2.475a.5.5 0 0 1 .707 0l.707.707a.5.5 0 0 1 0 .707l-2.475 2.475L13 6.343zm-6.268 3.39v1h-3.75a.25.25 0 0 1-.25-.25v-.5a.25.25 0 0 1 .25-.25h3.75zm9 0h3.75a.25.25 0 0 1 .25.25v.5a.25.25 0 0 1-.25.25h-3.75v-1zm-4-4h-1v-3.75a.25.25 0 0 1 .25-.25h.5a.25.25 0 0 1 .25.25v3.75zm0 9v3.75a.25.25 0 0 1-.25.25h-.5a.25.25 0 0 1-.25-.25v-3.75h1z" }));
});

var _extends$28 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$28(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Structuredown = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$28(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$28({ xmlns: "http://www.w3.org/2000/svg", width: "16", height: "16", viewBox: "4 4 24 24" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { fill: "currentColor", d: "M17 14h6.004a2 2 0 0 1 2 2v6.27a2 2 0 1 1-2-.005V16H17v6.268a2 2 0 1 1-2 0V16H9.004v6.27a2 2 0 1 1-2-.005V16a2 2 0 0 1 2-2H15V9.83a3.001 3.001 0 1 1 2 0V14z" }));
});

var _extends$29 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$29(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Structureleft = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$29(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$29({ xmlns: "http://www.w3.org/2000/svg", width: "16", height: "16", viewBox: "4 4 24 24" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { fill: "currentColor", fillRule: "evenodd", d: "M22.17 15a3.001 3.001 0 1 1 0 2H18v6a2 2 0 0 1-2 2H8.732a2 2 0 1 1 0-2H16v-6H8.732a2 2 0 1 1 0-2H16V9H8.732a2 2 0 1 1 0-2H16a2 2 0 0 1 2 2v6h4.17z" }));
});

var _extends$30 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$30(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Structureright = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$30(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$30({ xmlns: "http://www.w3.org/2000/svg", width: "16", height: "16", viewBox: "4 4 24 24" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { fill: "currentColor", fillRule: "evenodd", d: "M9.83 17a3.001 3.001 0 1 1 0-2H14V9a2 2 0 0 1 2-2h7.268a2 2 0 1 1 0 2H16v6h7.268a2 2 0 1 1 0 2H16v6h7.268a2 2 0 1 1 0 2H16a2 2 0 0 1-2-2v-6H9.83z" }));
});

var _extends$31 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$31(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Sun = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$31(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$31({ xmlns: "http://www.w3.org/2000/svg", width: "16", height: "16", viewBox: "0 0 512 512" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { fill: "currentColor", d: "M256 136q32.656 0 60.235 16.094t43.672 43.672T376.001 256t-16.094 60.235-43.672 43.672T256 376.001t-60.234-16.094-43.672-43.672T136 256t16.094-60.234 43.672-43.672T256 136zM128.813 363.188q8.281 0 14.141 5.938t5.859 14.219q0 8.125-5.938 14.063l-28.281 28.281q-5.938 5.938-14.063 5.938-8.281 0-14.141-5.86t-5.859-14.141q0-8.438 5.781-14.219l28.281-28.281q5.938-5.938 14.219-5.938zM256 416q8.281 0 14.141 5.86t5.86 14.141v40q0 8.281-5.86 14.141T256 496.002t-14.141-5.86T236 476.001v-40q0-8.281 5.859-14.141T256 416zM36 236h40q8.281 0 14.141 5.859T96 256t-5.859 14.141T76 276.001H36q-8.282 0-14.141-5.86T15.999 256t5.86-14.141T36 236zm220-60q-33.125 0-56.563 23.438t-23.438 56.563 23.438 56.563T256 336.002t56.563-23.438 23.438-56.563-23.438-56.563T256 176zm127.344 187.188q8.125 0 14.063 5.938l28.281 28.281q5.938 5.938 5.938 14.219 0 8.125-5.938 14.063t-14.063 5.938q-8.281 0-14.219-5.938l-28.281-28.281q-5.781-5.781-5.781-14.063t5.86-14.219 14.141-5.938zM100.531 80.375q8.125 0 14.063 5.938l28.281 28.281q5.938 5.938 5.938 14.063 0 8.281-5.859 14.141t-14.141 5.859q-8.438 0-14.219-5.781l-28.281-28.281q-5.781-5.781-5.781-14.219 0-8.281 5.859-14.141t14.141-5.859zM256 16q8.281 0 14.141 5.86t5.86 14.141v40q0 8.281-5.86 14.141T256 96.001t-14.141-5.859T236 76.001v-40q0-8.282 5.859-14.141T256 16zm180 220h40q8.281 0 14.141 5.859t5.86 14.141-5.86 14.141-14.141 5.86h-40q-8.281 0-14.141-5.86T415.999 256t5.86-14.141T436 236zM411.625 80.375q8.125 0 14.063 5.938t5.938 14.063q0 8.281-5.938 14.219l-28.281 28.281q-5.781 5.781-14.063 5.781-8.594 0-14.297-5.703t-5.704-14.297q0-8.281 5.781-14.063l28.281-28.281q5.938-5.938 14.219-5.938z" }));
});

var _extends$32 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$32(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Trash = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$32(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$32({ xmlns: "http://www.w3.org/2000/svg", width: "16", height: "16", viewBox: "4 4 16 16" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { fill: "currentColor", fillRule: "evenodd", d: "M18 9v9.5a1.5 1.5 0 0 1-1.5 1.5h-9A1.5 1.5 0 0 1 6 18.5V9H3.5a.5.5 0 0 1-.5-.5v-1a.5.5 0 0 1 .5-.5h17a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5H18zm-2 0H8v9h8V9zM8.5 4h7a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5h-7a.5.5 0 0 1-.5-.5v-1a.5.5 0 0 1 .5-.5z" }));
});

var _extends$33 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$33(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var View = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$33(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$33({ width: "14", height: "14", viewBox: "0 0 14 14", xmlns: "http://www.w3.org/2000/svg" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { d: "M1 7a6.002 6.002 0 0 1 11.317 0A6.002 6.002 0 0 1 1 7zm5.659 2.5a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5zm0-1.5a1 1 0 1 1 0-2 1 1 0 0 1 0 2z", fill: "currentColor", fillRule: "evenodd" }));
});

var _extends$34 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$34(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Zoomin = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$34(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$34({ xmlns: "http://www.w3.org/2000/svg", width: "16", height: "16", viewBox: "3 2 20 20" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { fill: "currentColor", d: "M18.733 15.322c.012.01.024.02.035.032l3.535 3.535a.5.5 0 0 1 0 .707l-.707.707a.5.5 0 0 1-.707 0l-3.443-3.443a8 8 0 1 1 1.287-1.538zM12 17a6 6 0 1 0 0-12 6 6 0 0 0 0 12zm-1-7V7h2v3h3v2h-3v3h-2v-3H8v-2h3z" }));
});

var _extends$35 = Object.assign || function (target) {
  for (var i = 1; i < arguments.length; i++) {
    var source = arguments[i];for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        target[key] = source[key];
      }
    }
  }return target;
};

function _objectWithoutProperties$35(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

var Zoomout = (function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties$35(_ref, ["styles"]);

  return react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("svg", _extends$35({ xmlns: "http://www.w3.org/2000/svg", width: "16", height: "16", viewBox: "3 2 20 20" }, props), react__WEBPACK_IMPORTED_MODULE_0___default.a.createElement("path", { fill: "currentColor", d: "M18.733 15.322c.012.01.024.02.035.032l3.535 3.535a.5.5 0 0 1 0 .707l-.707.707a.5.5 0 0 1-.707 0l-3.443-3.443a8 8 0 1 1 1.287-1.538zM12 17a6 6 0 1 0 0-12 6 6 0 0 0 0 12zm-4-7h8v2H8v-2z" }));
});

var iconTypes = ['add', 'arrow-right', 'check-circle-dark', 'check-circle', 'check', 'close-circle', 'close', 'color', 'complete', 'download', 'edit', 'enter', 'export', 'h1', 'h2', 'h3', 'images', 'message', 'mindmap-note', 'moon', 'navigation-map', 'note', 'plus', 'pulldown', 'refresh', 'setting', 'shopping-cart', 'sparkling-stick', 'structure-down', 'structure-left', 'structure-right', 'sun', 'trash', 'view', 'zoom-in', 'zoom-out'];
var iconMap = new Map([['add', Add], ['arrow-right', Arrowright], ['check-circle-dark', Checkcircledark], ['check-circle', Checkcircle], ['check', Check], ['close-circle', Closecircle], ['close', Close], ['color', Color], ['complete', Complete], ['download', Download], ['edit', Edit], ['enter', Enter], ['export', Export], ['h1', H1], ['h2', H2], ['h3', H3], ['images', Images], ['message', Message], ['mindmap-note', Mindmapnote], ['moon', Moon], ['navigation-map', Navigationmap], ['note', Note], ['plus', Plus], ['pulldown', Pulldown], ['refresh', Refresh], ['setting', Setting], ['shopping-cart', Shoppingcart], ['sparkling-stick', Sparklingstick], ['structure-down', Structuredown], ['structure-left', Structureleft], ['structure-right', Structureright], ['sun', Sun], ['trash', Trash], ['view', View], ['zoom-in', Zoomin], ['zoom-out', Zoomout]]);

var EventTypes = ["onCopy", "onCut", "onPaste", "onCompositionEnd", "onCompositionStart", "onCompositionUpdate", "onKeyDown", "onKeyPress", "onKeyUp", "onFocus", "onBlur", "onChange", "onInput", "onInvalid", "onSubmit", "onClick", "onContextMenu", "onDoubleClick", "onDrag", "onDragEnd", "onDragEnter", "onDragExit", "onDragLeave", "onDragOver", "onDragStart", "onDrop", "onMouseDown", "onMouseEnter", "onMouseLeave", "onMouseMove", "onMouseOut", "onMouseOver", "onMouseUp", "onSelect", "onTouchCancel", "onTouchEnd", "onTouchMove", "onTouchStart", "onScroll", "onWheel", "onAbort", "onCanPlay", "onCanPlayThrough", "onDurationChange", "onEmptied", "onEncrypted", "onEnded", "onError", "onLoadedData", "onLoadedMetadata", "onLoadStart", "onPause", "onPlay", "onPlaying", "onProgress", "onRateChange", "onSeeked", "onSeeking", "onStalled", "onSuspend", "onTimeUpdate", "onVolumeChange", "onWaiting", "onLoad", "onError", "onAnimationStart", "onAnimationEnd", "onAnimationIteration", "onTransitionEnd", "onToggle"];
var DOMAttributes = ["accept", "acceptCharset", "accessKey", "action", "allowFullScreen", "alt", "async", "autoComplete", "autoFocus", "autoPlay", "capture", "cellPadding", "cellSpacing", "challenge", "charSet", "checked", "cite", "classID", "className", "colSpan", "cols", "content", "contentEditable", "contextMenu", "controls", "controlsList", "coords", "crossOrigin", "data", "dateTime", "default", "defer", "dir", "disabled", "download", "draggable", "encType", "form", "formAction", "formEncType", "formMethod", "formNoValidate", "formTarget", "frameBorder", "headers", "height", "hidden", "high", "href", "hrefLang", "htmlFor", "httpEquiv", "icon", "id", "inputMode", "integrity", "is", "keyParams", "keyType", "kind", "label", "lang", "list", "loop", "low", "manifest", "marginHeight", "marginWidth", "max", "maxLength", "media", "mediaGroup", "method", "min", "minLength", "multiple", "muted", "name", "noValidate", "nonce", "open", "optimum", "pattern", "placeholder", "poster", "preload", "profile", "radioGroup", "readOnly", "rel", "required", "reversed", "role", "rowSpan", "rows", "sandbox", "scope", "scoped", "scrolling", "seamless", "selected", "shape", "size", "sizes", "span", "spellCheck", "src", "srcDoc", "srcLang", "srcSet", "start", "step", "style", "summary", "tabIndex", "target", "title", "type", "useMap", "value", "width", "wmode", "wrap"];
var SVGAttributes = ["className", "color", "height", "id", "lang", "max", "media", "method", "min", "name", "style", "target", "type", "width", "role", "tabIndex", "accentHeight", "accumulate", "additive", "alignmentBaseline", "allowReorder", "alphabetic", "amplitude", "arabicForm", "ascent", "attributeName", "attributeType", "autoReverse", "azimuth", "baseFrequency", "baselineShift", "baseProfile", "bbox", "begin", "bias", "by", "calcMode", "capHeight", "clip", "clipPath", "clipPathUnits", "clipRule", "colorInterpolation", "colorInterpolationFilters", "colorProfile", "colorRendering", "contentScriptType", "contentStyleType", "cursor", "cx", "cy", "d", "decelerate", "descent", "diffuseConstant", "direction", "display", "divisor", "dominantBaseline", "dur", "dx", "dy", "edgeMode", "elevation", "enableBackground", "end", "exponent", "externalResourcesRequired", "fill", "fillOpacity", "fillRule", "filter", "filterRes", "filterUnits", "floodColor", "floodOpacity", "focusable", "fontFamily", "fontSize", "fontSizeAdjust", "fontStretch", "fontStyle", "fontVariant", "fontWeight", "format", "from", "fx", "fy", "g1", "g2", "glyphName", "glyphOrientationHorizontal", "glyphOrientationVertical", "glyphRef", "gradientTransform", "gradientUnits", "hanging", "horizAdvX", "horizOriginX", "ideographic", "imageRendering", "in2", "in", "intercept", "k1", "k2", "k3", "k4", "k", "kernelMatrix", "kernelUnitLength", "kerning", "keyPoints", "keySplines", "keyTimes", "lengthAdjust", "letterSpacing", "lightingColor", "limitingConeAngle", "local", "markerEnd", "markerHeight", "markerMid", "markerStart", "markerUnits", "markerWidth", "mask", "maskContentUnits", "maskUnits", "mathematical", "mode", "numOctaves", "offset", "opacity", "operator", "order", "orient", "orientation", "origin", "overflow", "overlinePosition", "overlineThickness", "paintOrder", "panose1", "pathLength", "patternContentUnits", "patternTransform", "patternUnits", "pointerEvents", "points", "pointsAtX", "pointsAtY", "pointsAtZ", "preserveAlpha", "preserveAspectRatio", "primitiveUnits", "r", "radius", "refX", "refY", "renderingIntent", "repeatCount", "repeatDur", "requiredExtensions", "requiredFeatures", "restart", "result", "rotate", "rx", "ry", "scale", "seed", "shapeRendering", "slope", "spacing", "specularConstant", "specularExponent", "speed", "spreadMethod", "startOffset", "stdDeviation", "stemh", "stemv", "stitchTiles", "stopColor", "stopOpacity", "strikethroughPosition", "strikethroughThickness", "string", "stroke", "strokeDasharray", "strokeDashoffset", "strokeLinecap", "strokeLinejoin", "strokeMiterlimit", "strokeOpacity", "strokeWidth", "surfaceScale", "systemLanguage", "tableValues", "targetX", "targetY", "textAnchor", "textDecoration", "textLength", "textRendering", "to", "transform", "u1", "u2", "underlinePosition", "underlineThickness", "unicode", "unicodeBidi", "unicodeRange", "unitsPerEm", "vAlphabetic", "values", "vectorEffect", "version", "vertAdvY", "vertOriginX", "vertOriginY", "vHanging", "vIdeographic", "viewBox", "viewTarget", "visibility", "vMathematical", "widths", "wordSpacing", "writingMode", "x1", "x2", "x", "xChannelSelector", "xHeight", "xlinkActuate", "xlinkArcrole", "xlinkHref", "xlinkRole", "xlinkShow", "xlinkTitle", "xlinkType", "xmlBase", "xmlLang", "xmlns", "xmlnsXlink", "xmlSpace", "y1", "y2", "y", "yChannelSelector", "z", "zoomAndPan"];
var properties = {
	EventTypes: EventTypes,
	DOMAttributes: DOMAttributes,
	SVGAttributes: SVGAttributes
};

/**
 * All React Events
 * @version 16.2
 * @see https://reactjs.org/docs/events.html#reference
 */
var EventTypes$1 = properties.EventTypes;
var EventEntries = [];
for (var _i = 0, EventTypes_1 = EventTypes$1; _i < EventTypes_1.length; _i++) {
    var event_1 = EventTypes_1[_i];
    EventEntries.push([event_1, true]);
}
/**
 * All React DOMAttribute
 * @version 16.2
 * @see https://reactjs.org/docs/dom-elements.html#all-supported-html-attributes
 */
var DOMAttributes$1 = properties.DOMAttributes;
var DOMEntries = [];
for (var _a = 0, DOMAttributes_1 = DOMAttributes$1; _a < DOMAttributes_1.length; _a++) {
    var attribute = DOMAttributes_1[_a];
    DOMEntries.push([attribute, true]);
}
/**
 * All React SVGAttribute
 * @version 16.2
 * @see https://reactjs.org/docs/dom-elements.html#all-supported-html-attributes
 */
var SVGAttributes$1 = properties.SVGAttributes;
var SVGEntries = [];
for (var _b = 0, SVGAttributes_1 = SVGAttributes$1; _b < SVGAttributes_1.length; _b++) {
    var attribute = SVGAttributes_1[_b];
    SVGEntries.push([attribute, true]);
}
var libs = {
    Event: EventEntries,
    DOMAttribute: DOMEntries,
    SVGAttribute: SVGEntries
};
/**
 * Assign
 *
 * @param props
 * @description Auto assign properties. By default, Assign would extends all React events.
 */
function Assign(props) {
    var source = props.props,
        _a = props.lib,
        lib = _a === void 0 ? ['Event', 'DOMAttribute', 'SVGAttribute'] : _a,
        exclude = props.exclude;
    var targetProps = _assign({}, props.children.props);
    var entries = [];
    for (var _i = 0, lib_1 = lib; _i < lib_1.length; _i++) {
        var e = lib_1[_i];
        var ens = libs[e];
        if (ens) {
            entries = entries.concat(ens);
        }
    }
    var AssignMap = new Map(entries);
    // 去除掉制定的属性
    if (Array.isArray(exclude)) {
        for (var i = 0, l = exclude.length; i < l; i++) {
            var e = exclude[i];
            AssignMap.delete(e);
        }
    }
    // 遍历原参数的属性，如果属性在 AssignMap 中，则按类型分配属性值
    Object.keys(source).forEach(function (key) {
        if (source.hasOwnProperty(key) && AssignMap.get(key)) {
            var prop_1 = source[key];
            if (targetProps.hasOwnProperty(key) && typeof targetProps[key] === 'function') {
                // 如果 target 中有此属性且是一个 function，则进行装饰
                var targetElement_1 = targetProps[key];
                targetProps[key] = function () {
                    var args = [];
                    for (var _i = 0; _i < arguments.length; _i++) {
                        args[_i] = arguments[_i];
                    }
                    prop_1.apply(void 0, args);
                    return targetElement_1.apply(void 0, args);
                };
            }
            if (!targetProps.hasOwnProperty(key)) {
                targetProps[key] = prop_1;
            }
        }
    });
    return Object(react__WEBPACK_IMPORTED_MODULE_0__["cloneElement"])(props.children, targetProps);
}

var styles = { "spin-rotate": "spin-rotate__3wyl8_NT", "rotate360": "rotate360__2idrTaTH" };

var spinnerSpeed = {
    slow: '3s',
    default: '2s',
    fast: '1s'
};
var Icon = function Icon(props) {
    var _a;
    var type = props.type,
        size = props.size,
        spin = props.spin,
        style = props.style,
        className = props.className,
        speed = props.speed;
    var Svg = iconMap.get(type);
    if (Svg === undefined || Svg === null) {
        console.error('Invalid icon type: ', type);
        return null;
    }
    var SPIN = styles['spin-rotate'];
    var classNames = classnames__WEBPACK_IMPORTED_MODULE_2___default()(className, (_a = {}, _a[SPIN] = spin, _a));
    return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Assign, { props: props }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Svg, { "data-sel": "spark-icon-" + type, width: size, height: size, className: classNames, style: _assign({}, style, { animationDuration: spinnerSpeed[speed] }) }));
};
Icon.propTypes = {
    className: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
    type: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["oneOf"])(iconTypes).isRequired,
    spin: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
    style: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
    speed: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["oneOf"])(['fast', 'default', 'slow'])
};
Icon.defaultProps = {
    spin: false,
    style: {},
    className: '',
    speed: 'default',
    size: 16
};

var styles$1 = { "btn": "btn__291oZBzw", "btn-default": "btn-default__3a7RwcoU", "btn-primary": "btn-primary__1BS5oyGI", "btn-warn": "btn-warn__2WjItviZ", "btn-inner": "btn-inner__1h7mVLfm", "btn-large": "btn-large__2qIWnc1j", "btn-standard": "btn-standard__1fCURDlO", "btn-small": "btn-small__tPPGoLao" };

var Button = function Button(props) {
    var type = props.type,
        nativeType = props.nativeType,
        size = props.size,
        loading = props.loading,
        icon = props.icon,
        disabled = props.disabled,
        className = props.className,
        style = props.style;
    var btnClass = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$1['btn'], styles$1["btn-" + size], styles$1["btn-" + type], className);
    var iconComponent = null;
    if (icon) {
        iconComponent = Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Icon, { type: icon });
    }
    if (loading) {
        iconComponent = Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Icon, { type: "refresh", spin: true, speed: "fast" });
    }
    return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Assign, { props: props, lib: ['Event'] }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("button", { "data-sel": "spark-button", type: nativeType, className: btnClass, style: style, disabled: disabled }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("span", { "data-sel": "spark-button-inner", className: styles$1['btn-inner'] }, iconComponent, props.children)));
};
Button.propTypes = {
    children: prop_types__WEBPACK_IMPORTED_MODULE_1__["node"],
    style: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
    className: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
    disabled: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
    loading: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
    nativeType: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
    type: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
    size: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
    icon: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"]
};
Button.defaultProps = {
    disabled: false,
    nativeType: 'button',
    size: 'standard',
    type: 'default'
};

var KeyCode;
(function (KeyCode) {
    KeyCode[KeyCode["Backspace"] = 8] = "Backspace";
    KeyCode[KeyCode["Tab"] = 9] = "Tab";
    KeyCode[KeyCode["Enter"] = 13] = "Enter";
    KeyCode[KeyCode["Shift"] = 16] = "Shift";
    KeyCode[KeyCode["Control"] = 17] = "Control";
    KeyCode[KeyCode["Alt"] = 18] = "Alt";
    KeyCode[KeyCode["CapsLock"] = 20] = "CapsLock";
    KeyCode[KeyCode["Esc"] = 27] = "Esc";
    KeyCode[KeyCode["Space"] = 32] = "Space";
    KeyCode[KeyCode["PageUp"] = 33] = "PageUp";
    KeyCode[KeyCode["PageDown"] = 34] = "PageDown";
    KeyCode[KeyCode["End"] = 35] = "End";
    KeyCode[KeyCode["Home"] = 36] = "Home";
    KeyCode[KeyCode["ArrowLeft"] = 37] = "ArrowLeft";
    KeyCode[KeyCode["ArrowUp"] = 38] = "ArrowUp";
    KeyCode[KeyCode["ArrowRight"] = 39] = "ArrowRight";
    KeyCode[KeyCode["ArrowDown"] = 40] = "ArrowDown";
    KeyCode[KeyCode["Semicolon"] = 186] = "Semicolon";
    KeyCode[KeyCode["Colon"] = 186] = "Colon";
    KeyCode[KeyCode["EqualsSign"] = 187] = "EqualsSign";
    KeyCode[KeyCode["Plus"] = 187] = "Plus";
    KeyCode[KeyCode["Comma"] = 188] = "Comma";
    KeyCode[KeyCode["LessThanSign"] = 188] = "LessThanSign";
    KeyCode[KeyCode["Minus"] = 189] = "Minus";
    KeyCode[KeyCode["Underscore"] = 189] = "Underscore";
    KeyCode[KeyCode["Period"] = 190] = "Period";
    KeyCode[KeyCode["GreaterThanSign"] = 190] = "GreaterThanSign";
    KeyCode[KeyCode["ForwardSlash"] = 191] = "ForwardSlash";
    KeyCode[KeyCode["QuestionMark"] = 191] = "QuestionMark";
    KeyCode[KeyCode["Backtick"] = 192] = "Backtick";
    KeyCode[KeyCode["Tilde"] = 192] = "Tilde";
    KeyCode[KeyCode["OpeningSquareBracket"] = 219] = "OpeningSquareBracket";
    KeyCode[KeyCode["OpeningCurlyBrace"] = 219] = "OpeningCurlyBrace";
    KeyCode[KeyCode["Backslash"] = 220] = "Backslash";
    KeyCode[KeyCode["Pipe"] = 220] = "Pipe";
    KeyCode[KeyCode["ClosingSquareBracket"] = 221] = "ClosingSquareBracket";
    KeyCode[KeyCode["ClosingCurlyBrace"] = 221] = "ClosingCurlyBrace";
    KeyCode[KeyCode["SingleQuote"] = 222] = "SingleQuote";
    KeyCode[KeyCode["DoubleQuote"] = 222] = "DoubleQuote";
    KeyCode[KeyCode["Pause"] = 19] = "Pause";
    KeyCode[KeyCode["PrintScreen"] = 44] = "PrintScreen";
    KeyCode[KeyCode["Insert"] = 45] = "Insert";
    KeyCode[KeyCode["Delete"] = 46] = "Delete";
    KeyCode[KeyCode["Num0"] = 48] = "Num0";
    KeyCode[KeyCode["Num1"] = 49] = "Num1";
    KeyCode[KeyCode["Num2"] = 50] = "Num2";
    KeyCode[KeyCode["Num3"] = 51] = "Num3";
    KeyCode[KeyCode["Num4"] = 52] = "Num4";
    KeyCode[KeyCode["Num5"] = 53] = "Num5";
    KeyCode[KeyCode["Num6"] = 54] = "Num6";
    KeyCode[KeyCode["Num7"] = 55] = "Num7";
    KeyCode[KeyCode["Num8"] = 56] = "Num8";
    KeyCode[KeyCode["Num9"] = 57] = "Num9";
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
    KeyCode[KeyCode["MetaLeft"] = 91] = "MetaLeft";
    KeyCode[KeyCode["MetaRight"] = 92] = "MetaRight";
    KeyCode[KeyCode["ContextMenu"] = 93] = "ContextMenu";
    KeyCode[KeyCode["Numpad0"] = 96] = "Numpad0";
    KeyCode[KeyCode["Numpad1"] = 97] = "Numpad1";
    KeyCode[KeyCode["Numpad2"] = 98] = "Numpad2";
    KeyCode[KeyCode["Numpad3"] = 99] = "Numpad3";
    KeyCode[KeyCode["Numpad4"] = 100] = "Numpad4";
    KeyCode[KeyCode["Numpad5"] = 101] = "Numpad5";
    KeyCode[KeyCode["Numpad6"] = 102] = "Numpad6";
    KeyCode[KeyCode["Numpad7"] = 103] = "Numpad7";
    KeyCode[KeyCode["Numpad8"] = 104] = "Numpad8";
    KeyCode[KeyCode["Numpad9"] = 105] = "Numpad9";
    KeyCode[KeyCode["NumpadMultiply"] = 106] = "NumpadMultiply";
    KeyCode[KeyCode["NumpadAdd"] = 107] = "NumpadAdd";
    KeyCode[KeyCode["NumpadSubtract"] = 109] = "NumpadSubtract";
    KeyCode[KeyCode["NumpadDecimal"] = 110] = "NumpadDecimal";
    KeyCode[KeyCode["NumpadDivide"] = 111] = "NumpadDivide";
    KeyCode[KeyCode["F1"] = 112] = "F1";
    KeyCode[KeyCode["F2"] = 113] = "F2";
    KeyCode[KeyCode["F3"] = 114] = "F3";
    KeyCode[KeyCode["F4"] = 115] = "F4";
    KeyCode[KeyCode["F5"] = 116] = "F5";
    KeyCode[KeyCode["F6"] = 117] = "F6";
    KeyCode[KeyCode["F7"] = 118] = "F7";
    KeyCode[KeyCode["F8"] = 119] = "F8";
    KeyCode[KeyCode["F9"] = 120] = "F9";
    KeyCode[KeyCode["F10"] = 121] = "F10";
    KeyCode[KeyCode["F11"] = 122] = "F11";
    KeyCode[KeyCode["F12"] = 123] = "F12";
    KeyCode[KeyCode["NumLock"] = 144] = "NumLock";
    KeyCode[KeyCode["ScrollLock"] = 145] = "ScrollLock";
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

var styles$2 = { "input-wrapper": "input-wrapper__2QRkg5Xs", "input": "input__2L8-mS0U", "suffix": "suffix__3AI6EPl3", "suffix-icon": "suffix-icon__2Gzkz_jJ" };

var TextField = /** @class */function (_super) {
    __extends(TextField, _super);
    function TextField(props) {
        var _this = _super.call(this, props) || this;
        _this.input = null;
        _this.handleChange = function (e) {
            var _a = _this.props,
                onChange = _a.onChange,
                value = _a.value;
            if (typeof onChange === 'function') {
                onChange(e);
                return;
            }
            // If no value input by onChange, then use default behavior
            var newValue = e.target.value;
            if (typeof value === 'string') {
                newValue = value;
            }
            _this.setState({
                value: _this.getCleanValue(newValue)
            });
        };
        _this.handleKeyPress = function (e) {
            var onPressEnter = _this.props.onPressEnter;
            if (e.charCode === KeyCode.Enter && typeof onPressEnter === 'function') {
                onPressEnter(e);
            }
        };
        _this.handleSuffixClick = function (e) {
            var _a = _this.props,
                onSuffixClick = _a.onSuffixClick,
                value = _a.value;
            if (onSuffixClick) {
                onSuffixClick(e);
                return;
            }
            // Apply the default behavior
            if (typeof value !== 'string') {
                _this.setState({
                    value: ''
                });
            }
        };
        _this.getCleanValue = function (val) {
            if (!val || typeof val !== 'string') {
                return '';
            }
            var maxLength = _this.props.maxLength;
            if (typeof maxLength === 'number') {
                return val.slice(0, maxLength);
            }
            return val;
        };
        var defaultValue = props.defaultValue,
            value = props.value;
        var val = defaultValue;
        if (typeof value === 'string' && value) {
            val = value;
        }
        _this.state = {
            value: _this.getCleanValue(val)
        };
        return _this;
    }
    TextField.prototype.componentDidMount = function () {
        if (this.props.autoFocus && this.input) {
            this.input.focus();
        }
    };
    TextField.prototype.componentWillReceiveProps = function (nextProps) {
        var value = nextProps.value;
        if (value !== undefined && typeof value === 'string') {
            this.setState({
                value: this.getCleanValue(value)
            });
        }
    };
    TextField.prototype.focus = function () {
        this.input && this.input.focus();
    };
    TextField.prototype.blur = function () {
        this.input && this.input.blur();
    };
    TextField.prototype.renderSuffix = function () {
        var _a = this.props,
            suffix = _a.suffix,
            value = _a.value;
        // if no value pass, it should hide.
        if (!value && !this.state.value) return null;
        if (suffix === null) return null;
        return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("span", { "data-sel": "spark-textfield-suffix", className: styles$2['suffix'], onClick: this.handleSuffixClick }, suffix || Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Icon, { className: styles$2['suffix-icon'], type: "close-circle", size: 14 }));
    };
    TextField.prototype.render = function () {
        var _this = this;
        var _a = this.props,
            placeholder = _a.placeholder,
            wrapperStyle = _a.wrapperStyle,
            wrapperClassName = _a.wrapperClassName,
            style = _a.style,
            className = _a.className;
        var value = this.state.value;
        var wrapperClassNames = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$2['input-wrapper'], wrapperClassName);
        var inputClassName = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$2['input'], className);
        return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-textfield", style: wrapperStyle, className: wrapperClassNames }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Assign, { props: this.props, lib: ['Event', 'DOMAttribute'] }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("input", { "data-sel": "spark-textfield-input", type: "text", style: style, className: inputClassName, placeholder: placeholder, onChange: this.handleChange, onKeyPress: this.handleKeyPress, value: value, ref: function ref(e) {
                _this.input = e;
            } })), this.renderSuffix());
    };
    TextField.propTypes = {
        value: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        defaultValue: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        wrapperStyle: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
        wrapperClassName: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        style: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
        className: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        placeholder: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        maxLength: prop_types__WEBPACK_IMPORTED_MODULE_1__["number"],
        onChange: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onPressEnter: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        suffix: prop_types__WEBPACK_IMPORTED_MODULE_1__["node"],
        autoFocus: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"]
    };
    TextField.defaultProps = {
        defaultValue: '',
        wrapperStyle: {},
        wrapperClassName: '',
        style: {},
        className: '',
        autoFocus: false
    };
    return TextField;
}(react__WEBPACK_IMPORTED_MODULE_0__["Component"]);

/**
 * Once 装饰器，被装饰的方法只被执行一次
 */
function Once() {
    var executed = false;
    return function (target, key, descriptor) {
        var fn = descriptor.value;
        if (!Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(fn)) {
            return descriptor;
        }
        descriptor.value = function () {
            var args = [];
            for (var _i = 0; _i < arguments.length; _i++) {
                args[_i] = arguments[_i];
            }
            if (!executed) {
                return fn.apply(this, args);
                executed = true;
            }
        };
        return descriptor;
    };
}

/**
 * forEach优化
 *
 * @param {Array<T>} arr
 * @param {function} callback
 */
function forEach(arr, callback) {
    for (var i = 0, length_1 = arr.length; i < length_1; i++) {
        var v = arr[i];
        callback(v, i, arr);
    }
}
/**
 * filter优化
 *
 * @param {Array<T>} arr
 * @param {function} callback
 * @returns {Array<T>}
 */
function filter(arr, callback) {
    var newArr = [];
    for (var i = 0, length_2 = arr.length; i < length_2; i++) {
        var v = arr[i];
        if (callback(v, i, arr)) {
            newArr.push(v);
        }
    }
    return newArr;
}
/**
 * map优化
 *
 * @param {Array<T>} arr
 * @param {function} callback
 * @returns {Array<an'y>}
 */

/**
 * weakMap优化
 *
 * @param {Array<T>} arr
 * @param {function} callback
 * @returns {Array<an'y>}
 */

var SelectManager = /** @class */function () {
    function SelectManager(select) {
        var _this = this;
        this.options = [];
        this.optionMetaMap = new Map();
        this.optionMap = new Map();
        this.activeValue = null;
        this.selectedValue = null;
        /**
         * 此方法由Select在做forEach的时候调用，需确保value唯一性。
         * 为什么push操作和setInstance操作需要分开？
         * 原因：因为React的限制，在list未渲染的时候，Option组件没有instance，所以需要遍历来获取meta信息，同时维护好Option的顺序
         */
        this.push = function (option) {
            var valid = _this.optionMetaMap.get(option.value);
            if (valid !== undefined) {
                console.error('Warning: Each option must have a unique value, but got a duplicate value: ', option.value);
                return;
            }
            _this.options.push(option);
            _this.optionMetaMap.set(option.value, option);
        };
        this.remove = function (value) {
            var index = _this.options.findIndex(function (v) {
                return v.value === value;
            });
            _this.options = _this.options.slice(0, index).concat(_this.options.slice(index + 1, _this.options.length));
            _this.optionMetaMap.delete(value);
            _this.optionMap.delete(value);
        };
        /**
         * 此方法在Option初始化以及更新时调用，确保注册到最新的组件
         */
        this.setInstance = function (option) {
            _this.optionMap.set(option.props.value, option);
        };
        /**
         * 此方法在Option注销的时候调用，确保Map无空项
         */
        this.deleteInstance = function (option) {
            _this.optionMap.delete(option.props.value);
        };
        this.clear = function () {
            _this.options = [];
            _this.optionMetaMap.clear();
        };
        this.mouseEnter = function (e, option) {
            _this.active(option.props.value);
        };
        this.mouseLeave = function (e, option) {
            _this.active(null);
        };
        this.click = function (e, option) {
            _this.selectInstance.onOptionClick(e, option);
        };
        this.active = function (value) {
            var option = value === null ? null : _this.optionMap.get(value);
            var activeOption = _this.activeValue === null ? null : _this.optionMap.get(_this.activeValue);
            if (!Object(lodash_es__WEBPACK_IMPORTED_MODULE_4__["default"])(activeOption) && activeOption !== option) {
                activeOption.onBlur();
            }
            if (!Object(lodash_es__WEBPACK_IMPORTED_MODULE_4__["default"])(option)) {
                option.onActive();
                _this.selectInstance.onOptionAvtive(option);
            }
            _this.activeValue = value;
        };
        this.select = function (value) {
            var option = value === null ? null : _this.optionMap.get(value);
            var selectedOption = _this.selectedValue === null ? null : _this.optionMap.get(_this.selectedValue);
            if (!Object(lodash_es__WEBPACK_IMPORTED_MODULE_4__["default"])(selectedOption) && selectedOption !== option) {
                selectedOption.onDeselect();
            }
            if (!Object(lodash_es__WEBPACK_IMPORTED_MODULE_4__["default"])(option)) {
                option.onSelect();
            }
            _this.selectedValue = value;
        };
        this.getActiveValue = function () {
            return _this.activeValue;
        };
        this.getActiveMeta = function () {
            if (_this.activeValue === null) {
                return null;
            }
            return _this.optionMetaMap.get(_this.activeValue);
        };
        this.getSelectedValue = function () {
            return _this.selectedValue;
        };
        this.getSelectedMeta = function () {
            if (_this.selectedValue === null) {
                return null;
            }
            return _this.optionMetaMap.get(_this.selectedValue);
        };
        this.getOptionMeta = function (value) {
            return _this.optionMetaMap.get(value);
        };
        /**
         * 选择在此 Select 组下的 Option
         *
         * @param {string} value 定位值
         * @param {number} to 偏移值
         * @example 使用 to 值来控制选择的偏移量，若为 -1 则向上一位选择，若为 1 则向下一位选择，0 表示选择当前项，支持环形选择。
         * 若偏移量的值为 disable 状态，则继续向下寻找第一个不为 disable 的值，一个循环后终止。
         * @returns {string} 偏移后的值
         */
        this.activeTo = function (value, to) {
            if (to === void 0) {
                to = 0;
            }
            var index = _this.options.findIndex(function (meta) {
                return meta.value === value;
            });
            var size = _this.options.length;
            var offset = index !== -1 ? (index + to) % size : 0;
            var i = offset >= 0 ? offset : size + offset;
            var activeValue = value;
            /* 若偏移量为自然数，则正向查找 */
            if (to >= 0) {
                for (var j = i, count = 0; count < size; j++, count++) {
                    var meta = _this.options[j % size];
                    var disable = meta.disable,
                        value_1 = meta.value,
                        visible = meta.visible;
                    if (!disable && visible) {
                        activeValue = value_1;
                        break;
                    }
                }
            }
            /* 若偏移量为负数，则逆向查找 */
            if (to < 0) {
                for (var j = i, count = 0; count < size; j--, count++) {
                    /* [ Max(count) == size - 1 ] && [ j >= 0 ] => [ Min(j) == 1 - size ] => [ j + size > 0 ] */
                    var meta = _this.options[(j + size) % size];
                    var disable = meta.disable,
                        value_2 = meta.value,
                        visible = meta.visible;
                    if (!disable && visible) {
                        activeValue = value_2;
                        break;
                    }
                }
            }
            _this.active(activeValue);
            return activeValue;
        };
        this.selectInstance = select;
    }
    return SelectManager;
}();

var AbstractOption = /** @class */function (_super) {
    __extends(AbstractOption, _super);
    function AbstractOption(props, context) {
        var _this = _super.call(this, props, context) || this;
        _this.context = context;
        _this.manager = context.manager;
        return _this;
    }
    return AbstractOption;
}(react__WEBPACK_IMPORTED_MODULE_0__["Component"]);

var styles$3 = { "option-default": "option-default__2JMlKdxL", "active": "active__2qu0zQMz", "selected": "selected__iafhq_O0", "disable": "disable__3KXd733R", "option-cover": "option-cover__1KUXtMBs" };

var Option = /** @class */function (_super) {
    __extends(Option, _super);
    function Option(props, context) {
        var _this = _super.call(this, props, context) || this;
        _this.hover = false;
        _this.liNode = null;
        _this.onActive = function () {
            _this.setState({
                active: true
            });
        };
        _this.onBlur = function () {
            _this.setState({
                active: false
            });
        };
        _this.onSelect = function () {
            _this.setState({
                selected: true
            });
        };
        _this.onDeselect = function () {
            _this.setState({
                selected: false
            });
        };
        _this.getLiNode = function () {
            return _this.liNode;
        };
        _this.liRef = function (node$$1) {
            if (node$$1) {
                _this.liNode = node$$1;
            }
        };
        _this.handleClick = function (e) {
            var disable = _this.props.disable;
            if (!disable) {
                _this.manager.click(e, _this);
            }
        };
        _this.handleMouseEnter = function (e) {
            var disable = _this.props.disable;
            if (!disable && !_this.hover) {
                _this.hover = true;
                _this.manager.mouseEnter(e, _this);
            }
        };
        _this.handleMouseLeave = function (e) {
            _this.hover = false;
            var disable = _this.props.disable;
            if (!disable) {
                _this.manager.mouseLeave(e, _this);
            }
        };
        var value = props.value;
        if (value === '') {
            console.error('Warning: The value of option should not be a empty string.');
        }
        var manager = _this.manager;
        _this.state = {
            active: value === manager.getActiveValue(),
            selected: value === manager.getSelectedValue()
        };
        _this.manager.setInstance(_this);
        return _this;
    }
    Option.prototype.componentWillReceiveProps = function (nextProps) {
        /* 每次Select更新时可能会导致instance不一致 */
        this.manager.setInstance(this);
        var activeValue = this.manager.getActiveValue();
        var selectedValue = this.manager.getSelectedValue();
        var value = this.props.value;
        this.setState({
            active: value === activeValue,
            selected: value === selectedValue
        });
    };
    Option.prototype.componentWillUnmount = function () {
        this.manager.deleteInstance(this);
    };
    Option.prototype.render = function () {
        var _a;
        var _b = this.props,
            children = _b.children,
            disable = _b.disable,
            style = _b.style,
            className = _b.className;
        var mode = this.context.mode;
        var _c = this.state,
            active = _c.active,
            selected = _c.selected;
        var DISABLE = styles$3['disable'];
        var ACTIVE = styles$3['active'];
        var SELECTED = styles$3['selected'];
        var classNames = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$3["option-" + mode], className, (_a = {}, _a[DISABLE] = disable, _a[ACTIVE] = active, _a[SELECTED] = selected, _a));
        return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("li", { "data-sel": "spark-select-option", ref: this.liRef, style: style, onClick: this.handleClick, onMouseEnter: this.handleMouseEnter, onMouseLeave: this.handleMouseLeave, className: classNames }, children);
    };
    Option.propTypes = {
        children: prop_types__WEBPACK_IMPORTED_MODULE_1__["node"],
        style: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
        className: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        title: prop_types__WEBPACK_IMPORTED_MODULE_1__["node"],
        value: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"].isRequired,
        disable: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"]
    };
    Option.defaultProps = {
        disable: false
    };
    Option.contextTypes = {
        manager: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["instanceOf"])(SelectManager),
        mode: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"]
    };
    return Option;
}(AbstractOption);

var Portal = /** @class */function (_super) {
    __extends(Portal, _super);
    function Portal() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    Portal.init = function () {
        Portal.container = document.createElement('div');
        Portal.container.setAttribute('data-sel', 'spark-portal-container');
        document.body.appendChild(Portal.container);
    };
    Portal.prototype.render = function () {
        var container = this.props.container;
        var c = container instanceof HTMLElement ? container : Portal.container;
        return Object(react_dom__WEBPACK_IMPORTED_MODULE_16__["createPortal"])(this.props.children, c);
    };
    __decorate([Once()], Portal, "init", null);
    return Portal;
}(react__WEBPACK_IMPORTED_MODULE_0__["Component"]);
Portal.init();

var Animate = /** @class */function (_super) {
    __extends(Animate, _super);
    function Animate(props) {
        var _this = _super.call(this, props) || this;
        _this.handleComponentWillEnter = function () {
            var onComponentWillEnter = _this.props.onComponentWillEnter;
            onComponentWillEnter && onComponentWillEnter();
        };
        _this.handleComponentDidEnter = function () {
            var onComponentDidEnter = _this.props.onComponentDidEnter;
            onComponentDidEnter && onComponentDidEnter();
        };
        _this.handleComponentWillLeave = function () {
            var onComponentWillLeave = _this.props.onComponentWillLeave;
            onComponentWillLeave && onComponentWillLeave();
        };
        _this.handleComponentDidLeave = function () {
            var onComponentDidLeave = _this.props.onComponentDidLeave;
            onComponentDidLeave && onComponentDidLeave();
        };
        _this.handleAnimationEnd = function (e) {
            var _a = _this.state,
                visible = _a.visible,
                leave = _a.leave;
            _this.setState({
                enter: false,
                leave: false
            });
            if (visible && leave) {
                _this.setState({
                    visible: false
                });
            }
        };
        var visible = props.visible;
        _this.state = {
            visible: visible,
            enter: visible,
            leave: false
        };
        if (visible) {
            _this.handleComponentWillEnter();
        }
        return _this;
    }
    Animate.prototype.componentDidMount = function () {
        if (this.state.visible) {
            this.handleComponentDidEnter();
        }
    };
    Animate.prototype.componentWillReceiveProps = function (nextProps) {
        var disable = nextProps.disable;
        var _a = this.state,
            visible = _a.visible,
            enter = _a.enter,
            leave = _a.leave;
        /* disable animation */
        if (disable) {
            this.setState({
                visible: nextProps.visible,
                enter: false,
                leave: false
            });
            if (!visible && nextProps.visible) {
                this.handleComponentWillEnter();
            }
            if (visible && !nextProps.visible) {
                this.handleComponentWillLeave();
            }
            return;
        }
        /* normal enter */
        if (!visible && nextProps.visible) {
            this.setState({
                visible: true,
                enter: true,
                leave: false
            });
            this.handleComponentWillEnter();
        }
        /* normal leave */
        if (visible && !nextProps.visible) {
            this.setState({
                visible: true,
                enter: false,
                leave: true
            });
            this.handleComponentWillLeave();
        }
        /* enter when is leaving */
        if (leave && nextProps.visible) {
            this.setState({
                visible: true,
                enter: false,
                leave: false
            });
            this.handleComponentWillEnter();
        }
        /* leave when is entering */
        if (enter && !nextProps.visible) {
            this.setState({
                visible: false,
                enter: false,
                leave: false
            });
            this.handleComponentWillLeave();
        }
    };
    Animate.prototype.componentDidUpdate = function (prevProps, prevState) {
        var _a = this.state,
            visible = _a.visible,
            enter = _a.enter,
            leave = _a.leave;
        if (visible && !enter && !leave) {
            this.handleComponentDidEnter();
        }
        if (prevState.visible && !visible) {
            this.handleComponentDidLeave();
        }
    };
    Animate.prototype.render = function () {
        var _this = this;
        var _a;
        var _b = this.props,
            visibleField = _b.visibleField,
            children = _b.children,
            enterClassName = _b.enterClassName,
            leaveClassName = _b.leaveClassName,
            disable = _b.disable,
            destroyAfterLeave = _b.destroyAfterLeave;
        var _c = this.state,
            visible = _c.visible,
            enter = _c.enter,
            leave = _c.leave;
        /* 注销组件 */
        if (destroyAfterLeave && !visible) {
            return null;
        }
        var childrenProps = children.props;
        var animationClass = classnames__WEBPACK_IMPORTED_MODULE_2___default()(childrenProps.className, (_a = {}, _a[enterClassName] = !disable && enter, _a[leaveClassName] = !disable && leave, _a));
        var handleAnimationEnd = childrenProps.handleAnimationEnd ? function (e) {
            _this.handleAnimationEnd(e);
            childrenProps.handleAnimationEnd(e);
        } : this.handleAnimationEnd;
        var style = childrenProps.style || {};
        var visibleToggler = {
            display: visibleField === 'display' && !visible ? 'none' : undefined,
            visibility: visibleField === 'visibility' && !visible ? 'hidden' : undefined
        };
        return Object(react__WEBPACK_IMPORTED_MODULE_0__["cloneElement"])(children, _assign({}, childrenProps, { style: _assign({}, style, visibleToggler), className: animationClass, onAnimationEnd: handleAnimationEnd }));
    };
    Animate.propTypes = {
        children: prop_types__WEBPACK_IMPORTED_MODULE_1__["element"],
        visible: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        visibleField: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["oneOf"])(['display', 'visibility']),
        enterClassName: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        leaveClassName: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        disable: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        onComponentWillEnter: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onComponentDidEnter: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onComponentWillLeave: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onComponentDidLeave: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        destroyAfterLeave: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"]
    };
    Animate.defaultProps = {
        visibleField: 'display',
        enterClassName: '',
        leaveClassName: '',
        disable: false,
        destroyAfterLeave: false
    };
    return Animate;
}(react__WEBPACK_IMPORTED_MODULE_0__["Component"]);

/**
 * Popup component
 */
var Popup = /** @class */function (_super) {
    __extends(Popup, _super);
    function Popup() {
        var _this = _super !== null && _super.apply(this, arguments) || this;
        _this.getPopupRef = function (node$$1) {
            var popupRef = _this.props.popupRef;
            popupRef && popupRef(node$$1);
        };
        _this.handleComponentWillEnter = function () {
            var _a = _this.props,
                animate = _a.animate,
                onVisibleChange = _a.onVisibleChange,
                onPopupWillEnter = _a.onPopupWillEnter;
            if (animate && onVisibleChange) {
                onVisibleChange(true);
            }
            onPopupWillEnter && onPopupWillEnter();
        };
        _this.handleComponentDidEnter = function () {
            var onPopupDidEnter = _this.props.onPopupDidEnter;
            onPopupDidEnter && onPopupDidEnter();
        };
        _this.handleComponentWillLeave = function () {
            var onPopupWillLeave = _this.props.onPopupWillLeave;
            onPopupWillLeave && onPopupWillLeave();
        };
        _this.handleComponentDidLeave = function () {
            var _a = _this.props,
                animate = _a.animate,
                onVisibleChange = _a.onVisibleChange,
                onPopupDidLeave = _a.onPopupDidLeave;
            if (animate && onVisibleChange) {
                onVisibleChange(false);
            }
            onPopupDidLeave && onPopupDidLeave();
        };
        return _this;
    }
    Popup.prototype.render = function () {
        var _a = this.props,
            visible = _a.visible,
            visibleField = _a.visibleField,
            animate = _a.animate,
            enterClassName = _a.enterClassName,
            leaveClassName = _a.leaveClassName,
            destroyAfterLeave = _a.destroyAfterLeave;
        return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Animate, { visible: visible, visibleField: visibleField, enterClassName: enterClassName, leaveClassName: leaveClassName, disable: !animate, onComponentWillEnter: this.handleComponentWillEnter, onComponentDidEnter: this.handleComponentDidEnter, onComponentWillLeave: this.handleComponentWillLeave, onComponentDidLeave: this.handleComponentDidLeave, destroyAfterLeave: destroyAfterLeave }, Assign({
            props: this.props,
            lib: ['Event', 'DOMAttribute'],
            children: Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-popup", ref: this.getPopupRef }, this.props.children)
        }));
    };
    Popup.propTypes = {
        children: prop_types__WEBPACK_IMPORTED_MODULE_1__["node"],
        visible: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"].isRequired,
        style: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
        className: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        animate: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        onPopupWillEnter: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onPopupDidEnter: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onPopupWillLeave: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onPopupDidLeave: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        enterClassName: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        leaveClassName: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        onVisibleChange: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        popupRef: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"]
    };
    Popup.defaultProps = {
        animate: true,
        enterClassName: '',
        leaveClassName: '',
        destroyAfterLeave: false
    };
    return Popup;
}(react__WEBPACK_IMPORTED_MODULE_0__["Component"]);

/**
 * 安全的 Float Parser，如果结果为 NaN，则返回 0.
 */
var safeParseFloat = function safeParseFloat(value) {
    var parsed = parseFloat(value);
    return parsed || 0;
};
/**
 * 使用 Math.round 方法对对象中的浮点数进行整数化
 * @param o 需要转换的对象
 */
function intify(obj) {
    for (var key in obj) {
        if (obj.hasOwnProperty(key)) {
            var n = Math.round(obj[key]);
            obj[key] = n;
        }
    }
    return obj;
}
function precisify(obj, p) {
    for (var key in obj) {
        if (obj.hasOwnProperty(key)) {
            obj[key] = Number(obj[key].toFixed(p));
        }
    }
    return obj;
}

var placements = ['top', 'bottom', 'left', 'right', 'topLeft', 'bottomLeft', 'topRight', 'bottomRight', 'leftTop', 'rightTop', 'leftBottom', 'rightBottom'];
var contextMenuPlacements = ['bottomRight', 'bottomLeft', 'topRight', 'topLeft'];
var AlignRect = /** @class */function () {
    function AlignRect(rect) {
        this.top = 0;
        this.left = 0;
        this.right = 0;
        this.bottom = 0;
        this.width = 0;
        this.height = 0;
        if (rect) {
            this.top = rect.top;
            this.left = rect.left;
            this.right = rect.right;
            this.bottom = rect.bottom;
            this.width = rect.width;
            this.height = rect.height;
        }
    }
    return AlignRect;
}();
/* 鼠标点 */
var Point = /** @class */function () {
    function Point(point) {
        /**
         * 距离屏幕边界的距离
         * @see https://www.w3.org/TR/uievents/#events-mouseevents
         */
        this.screenX = 0;
        this.screenY = 0;
        /**
         * 距离浏览器视口的距离
         * @see https://www.w3.org/TR/uievents/#events-mouseevents
         */
        this.clientX = 0;
        this.clientY = 0;
        /**
         * 距离文档流边界的距离
         * @see https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent/pageX
         */
        this.pageX = 0;
        this.pageY = 0;
        /**
         * 距离当前Target边界距离。
         * @description 原生事件中的offsetX/Y代表了Event点距离Target边界的距离，但是兼容性不好，FireFox不支持，Chrome和Safari支持
         * @see https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent/offsetX
         */
        this.offsetX = 0;
        this.offsetY = 0;
        /**
         * 距离当前Container边界距离。
         * @description 不同的浏览器表现不同，FireFox表现为文档流边界，Chrome和Safari为viewport边界
         * @see https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent/offsetX
         */
        this.layerX = 0;
        this.layerY = 0;
        /**
         * 距离当前Container文档流边界距离。
         * @see https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent/offsetX
         */
        this.x = 0;
        this.y = 0;
        if (point) {
            this.screenX = point.screenX;
            this.screenY = point.screenY;
            this.clientX = point.clientX;
            this.clientY = point.clientY;
            this.pageX = point.pageX;
            this.pageY = point.pageY;
            this.offsetX = point.offsetX;
            this.offsetY = point.offsetY;
            this.layerX = point.layerX;
            this.layerY = point.layerY;
            this.x = point.x;
            this.y = point.y;
        }
    }
    return Point;
}();
var never = function never(x) {
    console.error(x, 'is not a placement.');
};
/**
 * 获取元素真实的 transform 值
 * @param {HTMLElement} node
 */
var getComputedTransform = function getComputedTransform(node$$1) {
    var style = getComputedStyle(node$$1);
    var matrix = style.transform || style.webkitTransform || '';
    var is3D = /matrix3d/.test(matrix);
    var values = matrix.match(/[\d\.\+\-]+/g) || Array(17).fill(0);
    return {
        translateX: is3D ? safeParseFloat(values[13]) : safeParseFloat(values[4]),
        translateY: is3D ? safeParseFloat(values[14]) : safeParseFloat(values[5]),
        translateZ: is3D ? safeParseFloat(values[15]) : 0
    };
};
/**
 * 从目标元素开始（包括目标），向上找到第一 offset 元素（非 static 定位）
 * @param target 目标元素
 * @description 若 target 元素朝上没有一个 non-static 元素，则会返回浏览器文档流元素，具体值取决于浏览器
 */
function findFirstOffsetElement(target) {
    var currentNode = target;
    while (currentNode !== null) {
        var style = getComputedStyle(currentNode);
        /* 若找到了第一个非 static 元素，则 break */
        if (style.position !== 'static' && currentNode instanceof HTMLElement) {
            break;
        } else if (currentNode.offsetParent instanceof HTMLElement) {
            /* 若当前元素是 static 定位，且 offsetParent 为 HTMLElement，则继续向上查找 */
            currentNode = currentNode.offsetParent;
        } else {
            currentNode = null;
        }
    }
    if (currentNode !== null) {
        return currentNode;
    }
    /* 在 Safari 和 Edge 下面，滚动的文档流是 body */
    if (bowser__WEBPACK_IMPORTED_MODULE_17___default.a.safari || bowser__WEBPACK_IMPORTED_MODULE_17___default.a.msedge) {
        return document.body;
    }
    /* 在 Chrome/FireFox/IE 下面，滚动的文档流是 html */
    return document.documentElement;
}
/**
 * 获取一个元素在一个容器中的绝对定位
 * @param {HTMLElement} target
 * @param {HTMLElement} container 需是 non-static 定位
 */
var getAbsNodeRect = function getAbsNodeRect(target, container) {
    var width = target.offsetWidth;
    var height = target.offsetHeight;
    var left = 0;
    var top = 0;
    var currentNode = target;
    /**
     * 若当前节点还没有到达 container 时则进行查找
     */
    while (currentNode instanceof HTMLElement && currentNode !== container) {
        var _a = getComputedTransform(currentNode),
            translateX = _a.translateX,
            translateY = _a.translateY;
        /**
         * 加上当前节点的偏移量，包括 offset 偏移和 transform 偏移
         */
        left = left + currentNode.offsetLeft + translateX;
        top = top + currentNode.offsetTop + translateY;
        /**
         * 在FireFox下面，offsetLeft对其的是offsetParent的边框外围，其他浏览器对其的是内围
         */
        if (target !== currentNode && !bowser__WEBPACK_IMPORTED_MODULE_17___default.a.firefox) {
            left = left + currentNode.clientLeft;
            top = top + currentNode.clientTop;
        }
        var offsetParent = currentNode.offsetParent;
        var parentNode = currentNode.parentNode;
        var style = getComputedStyle(currentNode);
        if (style.position === 'fixed') {
            /* TODO: 实现 fixed 定位的搜寻 */
        } else {
            /**
             * 每次需要从当前节点向上到 offsetParent 扣除滚动值，应该在一个节点到其 offsetParent 路径中，可能会存在多个
             * 滚动的 static 区域
             */
            while (parentNode instanceof Element && parentNode !== offsetParent && parentNode !== container) {
                left = left - parentNode.scrollLeft;
                top = top - parentNode.scrollTop;
                parentNode = parentNode.parentNode;
            }
        }
        /**
         * 如果还没有找到 container 则需要继续扣除滚动偏移量
         */
        if (offsetParent && offsetParent !== container) {
            left = left - offsetParent.scrollLeft;
            top = top - offsetParent.scrollTop;
        }
        currentNode = currentNode.offsetParent;
    }
    return {
        left: left,
        top: top,
        right: container.scrollWidth - width - left,
        bottom: container.scrollHeight - height - top,
        width: width,
        height: height
    };
};
/**
 * 生成弹层在文档流中的绝对 Rect
 *
 * @param {Placement} placement 需放置的位置
 * @param {HTMLElement} node 当前元素的
 * @param {HTMLElement} ref 参照物
 * @param {HTMLElement} container
 * @param {Array<number>} offset 弹层与内容之间的间隙
 * @returns 转换后的弹层 Rect
 */
var getRectFromRef = function getRectFromRef(placement, node$$1, ref, container, offset) {
    if (offset === void 0) {
        offset = [0, 0];
    }
    var _a = offset[0],
        topOffset = _a === void 0 ? 0 : _a,
        _b = offset[1],
        leftOffset = _b === void 0 ? 0 : _b;
    var refRect = getAbsNodeRect(ref, container);
    var popup = {
        width: node$$1.offsetWidth,
        height: node$$1.offsetHeight
    };
    var precision = 0; /* chrome下面精度过高会有偏差 */
    var rect = new AlignRect();
    switch (placement) {
        case 'top':
            rect.top = refRect.top - popup.height + topOffset;
            rect.left = refRect.left - (popup.width - refRect.width) / 2 + leftOffset;
            rect.width = popup.width;
            rect.height = popup.height;
            rect.right = container.scrollWidth - rect.left - popup.width - leftOffset;
            rect.bottom = container.scrollHeight - rect.top - popup.height - topOffset;
            return precisify(rect, precision);
        case 'bottom':
            rect.top = refRect.top + refRect.height + topOffset;
            rect.left = refRect.left - (popup.width - refRect.width) / 2 + leftOffset;
            rect.width = popup.width;
            rect.height = popup.height;
            rect.right = container.scrollWidth - rect.left - popup.width - leftOffset;
            rect.bottom = container.scrollHeight - rect.top - popup.height - topOffset;
            return precisify(rect, precision);
        case 'left':
            rect.top = refRect.top - (popup.height - refRect.height) / 2 + topOffset;
            rect.left = refRect.left - popup.width + leftOffset;
            rect.width = popup.width;
            rect.height = popup.height;
            rect.right = container.scrollWidth - rect.left - popup.width - leftOffset;
            rect.bottom = container.scrollHeight - rect.top - popup.height - topOffset;
            return precisify(rect, precision);
        case 'right':
            rect.top = refRect.top - (popup.height - refRect.height) / 2 + topOffset;
            rect.left = refRect.left + refRect.width + leftOffset;
            rect.width = popup.width;
            rect.height = popup.height;
            rect.right = container.scrollWidth - rect.left - popup.width - leftOffset;
            rect.bottom = container.scrollHeight - rect.top - popup.height - topOffset;
            return precisify(rect, precision);
        case 'topLeft':
            rect.top = refRect.top - popup.height + topOffset;
            rect.left = refRect.left + leftOffset;
            rect.width = popup.width;
            rect.height = popup.height;
            rect.right = container.scrollWidth - rect.left - popup.width - leftOffset;
            rect.bottom = container.scrollHeight - rect.top - popup.height - topOffset;
            return precisify(rect, precision);
        case 'topRight':
            rect.top = refRect.top - popup.height + topOffset;
            rect.left = refRect.left - (popup.width - refRect.width) + leftOffset;
            rect.width = popup.width;
            rect.height = popup.height;
            rect.right = container.scrollWidth - rect.left - popup.width - leftOffset;
            rect.bottom = container.scrollHeight - rect.top - popup.height - topOffset;
            return precisify(rect, precision);
        case 'leftTop':
            rect.top = refRect.top + topOffset;
            rect.left = refRect.left - popup.width + leftOffset;
            rect.width = popup.width;
            rect.height = popup.height;
            rect.right = container.scrollWidth - rect.left - popup.width - leftOffset;
            rect.bottom = container.scrollHeight - rect.top - popup.height - topOffset;
            return precisify(rect, precision);
        case 'leftBottom':
            rect.top = refRect.top - (popup.height - refRect.height) + topOffset;
            rect.left = refRect.left - popup.width + leftOffset;
            rect.width = popup.width;
            rect.height = popup.height;
            rect.right = container.scrollWidth - rect.left - popup.width - leftOffset;
            rect.bottom = container.scrollHeight - rect.top - popup.height - topOffset;
            return precisify(rect, precision);
        case 'rightTop':
            rect.top = refRect.top + topOffset;
            rect.left = refRect.left + refRect.width + leftOffset;
            rect.width = popup.width;
            rect.height = popup.height;
            rect.right = container.scrollWidth - rect.left - popup.width - leftOffset;
            rect.bottom = container.scrollHeight - rect.top - popup.height - topOffset;
            return precisify(rect, precision);
        case 'rightBottom':
            rect.top = refRect.top - (popup.height - refRect.height) + topOffset;
            rect.left = refRect.left + refRect.width + leftOffset;
            rect.width = popup.width;
            rect.height = popup.height;
            rect.right = container.scrollWidth - rect.left - popup.width - leftOffset;
            rect.bottom = container.scrollHeight - rect.top - popup.height - topOffset;
            return precisify(rect, precision);
        case 'bottomLeft':
            rect.top = refRect.top + refRect.height + topOffset;
            rect.left = refRect.left + leftOffset;
            rect.width = popup.width;
            rect.height = popup.height;
            rect.right = container.scrollWidth - rect.left - popup.width - leftOffset;
            rect.bottom = container.scrollHeight - rect.top - popup.height - topOffset;
            return precisify(rect, precision);
        case 'bottomRight':
            rect.top = refRect.top + refRect.height + topOffset;
            rect.left = refRect.left - (popup.width - refRect.width) + leftOffset;
            rect.width = popup.width;
            rect.height = popup.height;
            rect.right = container.scrollWidth - rect.left - popup.width - leftOffset;
            rect.bottom = container.scrollHeight - rect.top - popup.height - topOffset;
            return precisify(rect, precision);
        default:
            never(placement);
            rect.top = refRect.top + refRect.height + topOffset;
            rect.left = refRect.left - (popup.width - refRect.width) / 2 + leftOffset;
            rect.width = popup.width;
            rect.height = popup.height;
            rect.right = container.scrollWidth - rect.left - popup.width - leftOffset;
            rect.bottom = container.scrollHeight - rect.top - popup.height - topOffset;
            return precisify(rect, precision);
    }
};
var getRectFromPoint = function getRectFromPoint(placement, popup, container, point) {
    switch (placement) {
        case 'topLeft':
            return intify({
                top: point.y - popup.height,
                left: point.x - popup.width,
                width: popup.width,
                height: popup.height,
                right: container.scrollWidth - point.x,
                bottom: container.scrollHeight - point.y
            });
        case 'topRight':
            return intify({
                top: point.y - popup.height,
                left: point.x,
                width: popup.width,
                height: popup.height,
                right: container.scrollWidth - point.x - popup.width,
                bottom: container.scrollHeight - point.y
            });
        case 'bottomLeft':
            return intify({
                top: point.y,
                left: point.x - popup.width,
                width: popup.width,
                height: popup.height,
                right: container.scrollWidth - point.x,
                bottom: container.scrollHeight - point.y - popup.height
            });
        case 'bottomRight':
            return intify({
                top: point.y,
                left: point.x,
                width: popup.width,
                height: popup.height,
                right: container.scrollWidth - point.x - popup.width,
                bottom: container.scrollHeight - point.y - popup.height
            });
        default:
            return intify({
                top: point.x,
                left: point.y,
                width: popup.width,
                height: popup.height,
                right: container.scrollWidth - point.x - popup.width,
                bottom: container.scrollHeight - point.y - popup.height
            });
    }
};
/* 浏览器的DOM的scrollWidth会奇妙的随着节点变化，导致边缘为0的时候无法正确的判断溢出定位 */
var OVERFLOW_OFFSET = 2;
/**
 * 判断一个元素是否溢出文档流
 *
 * @param rect 文档流四个方向的距离
 */
var isOverflow = function isOverflow(rect, container, checkViewport) {
    if (container && checkViewport) {
        var viewportTop = rect.top - container.scrollTop;
        var viewportLeft = rect.left - container.scrollLeft;
        var viewportBottom = rect.bottom - (container.scrollHeight - container.scrollTop - container.clientHeight);
        var viewportRight = rect.right - (container.scrollWidth - container.scrollLeft - container.clientWidth);
        return viewportTop < OVERFLOW_OFFSET || viewportLeft < OVERFLOW_OFFSET || viewportBottom < OVERFLOW_OFFSET || viewportRight < OVERFLOW_OFFSET;
    }
    return rect.top < OVERFLOW_OFFSET || rect.left < OVERFLOW_OFFSET || rect.right < OVERFLOW_OFFSET || rect.bottom < OVERFLOW_OFFSET;
};

var AlignStatus;
(function (AlignStatus) {
    /* 初始化 */
    AlignStatus[AlignStatus["INIT"] = 0] = "INIT";
    /* trigger元素渲染完成，获取定位ref */
    AlignStatus[AlignStatus["READY"] = 1] = "READY";
    /* popup预渲染完成，进行定位计算 */
    AlignStatus[AlignStatus["ALIGN"] = 2] = "ALIGN";
    /* 渲染完成 */
    AlignStatus[AlignStatus["RENDER"] = 3] = "RENDER";
})(AlignStatus || (AlignStatus = {}));
var LazyAlign = /** @class */function (_super) {
    __extends(LazyAlign, _super);
    function LazyAlign(props) {
        var _this = _super.call(this, props) || this;
        _this.alignNode = null;
        _this.alignRef = null;
        _this.aligns = [];
        _this.getPopupRef = function (node$$1) {
            var popupRef = _this.props.popupRef;
            _this.alignNode = node$$1;
            popupRef && popupRef(node$$1);
        };
        _this.handleLazyInit = function (prevProps, prevState) {
            _this.setState({
                status: AlignStatus.READY
            });
            if (!prevProps.visible && _this.props.visible) {
                _this.props.onVisibleChange && _this.props.onVisibleChange(true);
            }
        };
        _this.handleLazyReady = function (prevProps, prevState) {
            var ref = _this.props.getAlignRef();
            _this.alignRef = ref;
            if (!ref) {
                _this.setState({
                    status: AlignStatus.RENDER
                });
                return;
            }
            /* 只在初始化后进行定位重置 */
            if (prevState.status === AlignStatus.INIT) {
                _this.aligns = _this.props.getAlignments(ref);
            }
            var align = _this.aligns[0];
            if (!align) {
                _this.setState({
                    status: AlignStatus.RENDER
                });
                return;
            }
            _this.setState({
                status: AlignStatus.ALIGN,
                placement: align.placement
            });
        };
        _this.handleLazyAlign = function (prevProps, prevState) {
            var align = _this.aligns[0];
            var ref = _this.alignRef;
            var node$$1 = _this.alignNode;
            var container = findFirstOffsetElement(_this.props.container);
            if (!align || !ref || !node$$1) {
                _this.setState({
                    status: AlignStatus.RENDER
                });
                return;
            }
            /* 当前状态为元素已经完成 pre-render，开始进行实际定位 */
            var placement = align.placement,
                offset = align.offset,
                enterClassName = align.enterClassName,
                leaveClassName = align.leaveClassName;
            var rect = getRectFromRef(placement, node$$1, ref, container, offset);
            _this.setState({
                placement: placement,
                rect: rect,
                enterClassName: enterClassName || '',
                leaveClassName: leaveClassName || ''
            });
            /* 若元素溢出，且自适应，则进行下一次搜索定位 */
            if (_this.isOverflow(rect, container)) {
                _this.aligns.shift();
                _this.setState({
                    status: AlignStatus.READY
                });
            } else {
                /* 否则则直接进行渲染 */
                _this.setState({
                    status: AlignStatus.RENDER
                });
            }
        };
        _this.handleLazyRender = function (prevProps, prevState) {
            var _a = _this.props,
                didAlign = _a.didAlign,
                visible = _a.visible;
            var _b = _this.state,
                placement = _b.placement,
                rect = _b.rect;
            if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(didAlign) && prevState.status === AlignStatus.ALIGN && visible) {
                didAlign(placement, rect);
            }
            if (prevProps.visible && !visible) {
                _this.props.onVisibleChange && _this.props.onVisibleChange(false);
            }
            _this.aligns = [];
        };
        _this.isOverflow = function (rect, container) {
            var adjustOverflow = _this.props.adjustOverflow;
            var checker = [];
            if (Array.isArray(adjustOverflow)) {
                checker = adjustOverflow;
            } else {
                checker = [adjustOverflow];
            }
            var adjust = checker[0],
                viewport = checker[1];
            if (adjust) {
                return viewport === 'check-viewport' ? isOverflow(rect, container, true) : isOverflow(rect);
            }
            return false;
        };
        _this.state = {
            status: AlignStatus.INIT,
            placement: 'bottom',
            rect: {
                top: 0,
                left: 0,
                width: 0,
                height: 0,
                bottom: 0,
                right: 0
            },
            enterClassName: '',
            leaveClassName: ''
        };
        return _this;
    }
    LazyAlign.prototype.componentDidMount = function () {
        this.handleLazyReady(this.props, this.state);
    };
    LazyAlign.prototype.componentWillReceiveProps = function (nextProps) {
        if (nextProps.visible) {
            this.setState({
                status: AlignStatus.INIT
            });
        }
    };
    LazyAlign.prototype.shouldComponentUpdate = function (nextProps) {
        /* 当组件完全不显示时则不更新，以优化渲染性能 */
        if (!this.props.visible && !nextProps.visible) {
            return false;
        }
        return true;
    };
    LazyAlign.prototype.componentDidUpdate = function (prevProps, prevState) {
        if (this.state.status === AlignStatus.INIT) {
            this.handleLazyInit(prevProps, prevState);
            return;
        }
        if (this.state.status === AlignStatus.READY) {
            this.handleLazyReady(prevProps, prevState);
            return;
        }
        if (this.state.status === AlignStatus.ALIGN) {
            this.handleLazyAlign(prevProps, prevState);
            return;
        }
        if (this.state.status === AlignStatus.RENDER) {
            this.handleLazyRender(prevProps, prevState);
            return;
        }
    };
    LazyAlign.prototype.render = function () {
        var _a = this.props,
            visible = _a.visible,
            style = _a.style,
            className = _a.className,
            animate = _a.animate,
            getPopup = _a.getPopup,
            onMouseEnter = _a.onMouseEnter,
            onMouseLeave = _a.onMouseLeave,
            onPopupWillEnter = _a.onPopupWillEnter,
            onPopupDidEnter = _a.onPopupDidEnter,
            onPopupWillLeave = _a.onPopupWillLeave,
            onPopupDidLeave = _a.onPopupDidLeave,
            destroyAfterClose = _a.destroyAfterClose;
        var _b = this.state,
            status = _b.status,
            placement = _b.placement,
            rect = _b.rect,
            enterClassName = _b.enterClassName,
            leaveClassName = _b.leaveClassName;
        var top = rect.top,
            left = rect.left; // 只取top和left防止造成偏差
        var children = getPopup({ placement: placement, trigger: this.alignRef });
        var visibility = status === AlignStatus.RENDER ? undefined : 'hidden';
        return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Popup, { popupRef: this.getPopupRef, visible: visible, style: _assign({}, style, { top: top,
                left: left,
                visibility: visibility }), className: className, animate: animate, enterClassName: enterClassName, leaveClassName: leaveClassName, onMouseEnter: onMouseEnter, onMouseLeave: onMouseLeave, onPopupWillEnter: onPopupWillEnter, onPopupDidEnter: onPopupDidEnter, onPopupWillLeave: onPopupWillLeave, onPopupDidLeave: onPopupDidLeave, destroyAfterLeave: destroyAfterClose }, children);
    };
    LazyAlign.defaultProps = {
        adjustOverflow: true,
        style: {},
        className: '',
        animate: true
    };
    return LazyAlign;
}(react__WEBPACK_IMPORTED_MODULE_0__["Component"]);

/**
 * Trigger component
 */
var Trigger = /** @class */function (_super) {
    __extends(Trigger, _super);
    function Trigger(props) {
        var _this = _super.call(this, props) || this;
        _this.popup = null;
        _this.timer = -999; // toggle timer
        _this.areaTimer = -999; // mouseArea timer
        _this.setMouseArea = function (area) {
            _this.mouseArea = _assign({}, _this.mouseArea, area);
            clearTimeout(_this.areaTimer);
            _this.areaTimer = setTimeout(function () {
                var hover = _this.mouseArea.trigger || _this.mouseArea.popup;
                var _a = _this.props,
                    hideActions = _a.hideActions,
                    showActions = _a.showActions;
                if (!hover && (Object(lodash_es__WEBPACK_IMPORTED_MODULE_5__["default"])(hideActions, 'onMouseLeave') || Object(lodash_es__WEBPACK_IMPORTED_MODULE_5__["default"])(hideActions, 'onMouseOut'))) {
                    _this.actionToggleVisible(false);
                }
                if (hover && (Object(lodash_es__WEBPACK_IMPORTED_MODULE_5__["default"])(showActions, 'onMouseEnter') || Object(lodash_es__WEBPACK_IMPORTED_MODULE_5__["default"])(hideActions, 'onMouseOver'))) {
                    _this.actionToggleVisible(true);
                }
            }, 0);
        };
        _this.getAlignRef = function () {
            var ref = Object(react_dom__WEBPACK_IMPORTED_MODULE_16__["findDOMNode"])(_this);
            if (ref instanceof HTMLElement) {
                return ref;
            }
            return null;
        };
        _this.mapActionsToHandler = function (showActions, hideActions) {
            var handlers = {};
            handlers.onMouseEnter = _this.handleMouseEnter;
            handlers.onMouseLeave = _this.handleMouseLeave;
            // 处理 showActions 事件
            for (var _i = 0, showActions_1 = showActions; _i < showActions_1.length; _i++) {
                var action = showActions_1[_i];
                if (action === 'onClick') {
                    handlers.onClick = _this.handleClick;
                    continue;
                }
                if (action !== 'onMouseEnter' && action !== 'onMouseOver') {
                    handlers[action] = function () {
                        _this.actionToggleVisible(true);
                    };
                }
            }
            // 处理 hideActions 事件
            for (var _a = 0, hideActions_1 = hideActions; _a < hideActions_1.length; _a++) {
                var action = hideActions_1[_a];
                if (action === 'onClick') {
                    handlers.onClick = _this.handleClick;
                    continue;
                }
                if (action !== 'onMouseLeave' && action !== 'onMouseOut') {
                    handlers[action] = function () {
                        _this.actionToggleVisible(false);
                    };
                }
            }
            return handlers;
        };
        _this.handleClick = function () {
            var _a = _this.props,
                showActions = _a.showActions,
                hideActions = _a.hideActions;
            var visible = _this.state.visible;
            if (visible && Object(lodash_es__WEBPACK_IMPORTED_MODULE_5__["default"])(hideActions, 'onClick')) {
                _this.actionToggleVisible(false);
            }
            if (!visible && Object(lodash_es__WEBPACK_IMPORTED_MODULE_5__["default"])(showActions, 'onClick')) {
                _this.actionToggleVisible(true);
            }
        };
        _this.handleMouseEnter = function () {
            if (!_this.mouseArea.trigger) {
                _this.setMouseArea({
                    trigger: true
                });
            }
        };
        _this.handleMouseLeave = function () {
            _this.setMouseArea({
                trigger: false
            });
        };
        _this.handleTriggerNode = function () {
            var node$$1 = _this.getAlignRef();
            var targetRef = _this.props.targetRef;
            targetRef && targetRef(node$$1);
        };
        _this.getPopupRef = function (node$$1) {
            _this.popup = node$$1;
            var popupRef = _this.props.popupRef;
            if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(popupRef)) {
                popupRef(node$$1);
            }
        };
        /**
         * Debounced toggler, 绝对的 visible toggler，调用前请充足的检测上下文
         */
        _this.toggleVisible = function (visible, wait) {
            clearTimeout(_this.timer);
            if (wait !== undefined && wait > 0) {
                _this.timer = setTimeout(function () {
                    if (visible !== _this.state.visible) {
                        _this.setState({
                            visible: visible
                        });
                    }
                }, wait);
            } else {
                if (visible !== _this.state.visible) {
                    _this.setState({
                        visible: visible
                    });
                }
            }
        };
        /**
         * 交互事件的 Toggler ，对 visible 和 disable 参数进行了检测
         */
        _this.actionToggleVisible = function (show) {
            var _a = _this.props,
                visible = _a.visible,
                disable = _a.disable,
                showDelay = _a.showDelay,
                hideDelay = _a.hideDelay;
            if (disable || Object(lodash_es__WEBPACK_IMPORTED_MODULE_6__[/* default */ "a"])(visible)) {
                return;
            }
            var delay = show ? showDelay : hideDelay;
            _this.toggleVisible(show, delay);
        };
        _this.handlePopupMouseEnter = function (e) {
            if (!_this.mouseArea.popup) {
                _this.setMouseArea({
                    popup: true
                });
            }
            _this.props.onPopupMouseEnter && _this.props.onPopupMouseEnter(e);
        };
        _this.handlePopupMouseLeave = function (e) {
            _this.setMouseArea({
                popup: false
            });
            _this.props.onPopupMouseLeave && _this.props.onPopupMouseLeave(e);
        };
        var disable = props.disable,
            visible = props.visible,
            defaultVisible = props.defaultVisible;
        var stateVisible = defaultVisible;
        switch (true) {
            case disable:
                stateVisible = false;
                break;
            case Object(lodash_es__WEBPACK_IMPORTED_MODULE_6__[/* default */ "a"])(visible):
                stateVisible = visible;
                break;
            default:
                break;
        }
        _this.state = {
            visible: stateVisible
        };
        _this.mouseArea = {
            trigger: false,
            popup: false
        };
        return _this;
    }
    /**
     * 初始化 Trigger 组件。
     */
    Trigger.init = function () {
        // 创建Popover container元素
        var e = document.createElement('div');
        e.setAttribute('data-sel', 'spark-trigger-container');
        Trigger.container = e;
        document.body.appendChild(e);
        // 注册resize事件
        window.addEventListener('resize', Object(lodash_es__WEBPACK_IMPORTED_MODULE_7__["default"])(function (e) {
            Trigger.resizeHandlers.forEach(function (v, k) {
                v(e);
            });
        }, 200));
        // 注册mousewheel事件
        window.addEventListener('mousewheel', Object(lodash_es__WEBPACK_IMPORTED_MODULE_7__["default"])(function (e) {
            Trigger.wheelHandlers.forEach(function (v, k) {
                v(e);
            });
        }, 200));
        // 注册click事件
        window.addEventListener('mousedown', function (e) {
            Trigger.clickHandlers.forEach(function (v, k) {
                v(e);
            });
        });
    };
    Trigger.prototype.componentDidMount = function () {
        var _this = this;
        this.handleTriggerNode();
        var toggleRef = this.props.toggleRef;
        if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(toggleRef)) {
            var show = this.toggleVisible.bind(this, true, 0);
            var hide = this.toggleVisible.bind(this, false, 0);
            toggleRef(show, hide);
        }
        /* 处理 resize 事件 */
        Trigger.resizeHandlers.set(this, function (e) {
            if (_this.state.visible) {
                _this.forceUpdate();
            }
        });
        /* 处理 mouse wheel 事件 */
        Trigger.wheelHandlers.set(this, function (e) {
            if (_this.state.visible) {
                _this.forceUpdate();
            }
        });
        /* 处理 mask click 事件 */
        Trigger.clickHandlers.set(this, function (e) {
            var target = e.target;
            var popup = _this.popup;
            var trigger = _this.getAlignRef();
            if (!_this.props.maskClick || !_this.state.visible || !popup || !trigger) {
                return;
            }
            if (!popup.contains(target) && !trigger.contains(target)) {
                _this.actionToggleVisible(false);
            }
        });
    };
    Trigger.prototype.componentWillReceiveProps = function (nextProps, nextState) {
        if (nextProps.disable) {
            this.toggleVisible(false, 0);
            return;
        }
        if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_6__[/* default */ "a"])(nextProps.visible) && this.props.visible !== nextProps.visible) {
            var delay = nextProps.visible ? nextProps.showDelay : nextProps.hideDelay;
            this.toggleVisible(nextProps.visible, delay);
        }
    };
    Trigger.prototype.componentDidUpdate = function (prevProps, prevState) {
        this.handleTriggerNode();
    };
    Trigger.prototype.componentWillUnmount = function () {
        Trigger.resizeHandlers.delete(this);
        Trigger.wheelHandlers.delete(this);
        Trigger.clickHandlers.delete(this);
    };
    /**
     * 获取渲染 container
     */
    Trigger.prototype.getContainer = function () {
        if (!Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(this.props.getContainer)) {
            return Trigger.container;
        }
        var container = this.props.getContainer();
        if (!container) {
            return Trigger.container;
        }
        return container;
    };
    Trigger.prototype.render = function () {
        var visible = this.state.visible;
        var _a = this.props,
            showActions = _a.showActions,
            hideActions = _a.hideActions,
            didAlign = _a.didAlign,
            onVisibleChange = _a.onVisibleChange,
            onPopupWillEnter = _a.onPopupWillEnter,
            onPopupDidEnter = _a.onPopupDidEnter,
            onPopupWillLeave = _a.onPopupWillLeave,
            onPopupDidLeave = _a.onPopupDidLeave,
            style = _a.style,
            getAlignments = _a.getAlignments,
            className = _a.className,
            zIndex = _a.zIndex,
            getPopup = _a.getPopup,
            animate = _a.animate,
            adjustOverflow = _a.adjustOverflow,
            children = _a.children,
            destroyAfterClose = _a.destroyAfterClose;
        /* 获取渲染的 container */
        var container = this.getContainer();
        return [Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Assign, { key: "trigger", props: this.mapActionsToHandler(showActions, hideActions), lib: ['Event'] }, children), Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Portal, { key: "portal", container: container }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(LazyAlign, { visible: visible, getAlignments: getAlignments, getAlignRef: this.getAlignRef, getPopup: getPopup, style: _assign({}, style, { zIndex: zIndex }), className: className, animate: animate, adjustOverflow: adjustOverflow, didAlign: didAlign, onVisibleChange: onVisibleChange, onMouseEnter: this.handlePopupMouseEnter, onMouseLeave: this.handlePopupMouseLeave, onPopupWillEnter: onPopupWillEnter, onPopupDidEnter: onPopupDidEnter, onPopupWillLeave: onPopupWillLeave, onPopupDidLeave: onPopupDidLeave, destroyAfterClose: destroyAfterClose, container: container, popupRef: this.getPopupRef }))];
    };
    Trigger.propTypes = {
        children: prop_types__WEBPACK_IMPORTED_MODULE_1__["element"].isRequired,
        getPopup: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"].isRequired,
        getAlignments: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        getContainer: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        adjustOverflow: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["oneOfType"])([prop_types__WEBPACK_IMPORTED_MODULE_1__["array"], prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"]]),
        style: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
        className: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        zIndex: prop_types__WEBPACK_IMPORTED_MODULE_1__["number"],
        showDelay: prop_types__WEBPACK_IMPORTED_MODULE_1__["number"],
        hideDelay: prop_types__WEBPACK_IMPORTED_MODULE_1__["number"],
        defaultVisible: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        showActions: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["arrayOf"])(prop_types__WEBPACK_IMPORTED_MODULE_1__["string"]),
        hideActions: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["arrayOf"])(prop_types__WEBPACK_IMPORTED_MODULE_1__["string"]),
        onPopupMouseEnter: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onPopupMouseLeave: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        didAlign: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onVisibleChange: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        maskClick: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        visible: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        disable: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        animate: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        destroyAfterClose: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        toggleRef: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        targetRef: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        popupRef: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"]
    };
    Trigger.defaultProps = {
        getAlignments: function getAlignments() {
            return [{
                placement: 'bottom',
                offset: [0, 0]
            }];
        },
        adjustOverflow: true,
        style: {},
        className: '',
        zIndex: 999,
        showDelay: 0,
        hideDelay: 0,
        defaultVisible: false,
        showActions: ['onMouseEnter'],
        hideActions: ['onMouseLeave'],
        maskClick: true,
        disable: false,
        animate: true,
        destroyAfterClose: false
    };
    Trigger.resizeHandlers = new Map();
    Trigger.wheelHandlers = new Map();
    Trigger.clickHandlers = new Map();
    __decorate([Once()], Trigger, "init", null);
    return Trigger;
}(react__WEBPACK_IMPORTED_MODULE_0__["Component"]);
Trigger.init();

var styles$4 = { "list": "list__2j8RSynL", "value": "value__3wd2XBDU", "placeholder": "placeholder__1uezgRke", "dropdown-placeholder": "dropdown-placeholder__1rDry6nt", "content": "content__xBu6DUpl", "title": "title__2uPgvaob", "input-wrapper": "input-wrapper__nKWp6yXZ", "pulldown": "pulldown__1gqWyPgc", "select-default": "select-default__mL43rcIj", "focus": "focus__2kNCrj71", "open": "open__JXaOSAqN", "dropdown-default": "dropdown-default__gAKL99RO", "dropdown-override": "dropdown-override__1GVgOeUL", "select-cover": "select-cover__1YwV4ivt", "pulldown-cover": "pulldown-cover__8fGj3LPz", "dropdown-cover": "dropdown-cover__3epy-fej", "cover-title": "cover-title__17P0dzkL", "hidden": "hidden__2aHDKJsD", "disable": "disable__IGsS9oq9", "popup": "popup__3yqg7jGR", "bottom-enter": "bottom-enter__2u3Qc6NO", "slide-in": "slide-in__1cRF82TJ", "bottom-leave": "bottom-leave__23S9Zzog", "slide-out": "slide-out__1_W66qzV" };

var CoverDropdown = /** @class */function (_super) {
    __extends(CoverDropdown, _super);
    function CoverDropdown() {
        var _this = _super !== null && _super.apply(this, arguments) || this;
        _this.getPopup = function (args) {
            var content = _this.props.content;
            return Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(content) ? content() : content;
        };
        _this.getAlignments = function (trigger) {
            return [{
                placement: 'bottom',
                /* 解释一下：cover模式是整个浮窗盖上去的，这里要把选框的长度盖过 */
                offset: [-trigger.offsetHeight - 1, 0],
                enterClassName: styles$4['bottom-enter'],
                leaveClassName: styles$4['bottom-leave']
            }];
        };
        return _this;
    }
    CoverDropdown.prototype.render = function () {
        var _a = this.props,
            visible = _a.visible,
            disable = _a.disable,
            animate = _a.animate,
            showDelay = _a.showDelay,
            hideDelay = _a.hideDelay,
            dropdownRef = _a.dropdownRef,
            getContainer = _a.getContainer,
            destroyAfterClose = _a.destroyAfterClose,
            didAlign = _a.didAlign,
            onVisibleChange = _a.onVisibleChange,
            zIndex = _a.zIndex,
            children = _a.children;
        return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Trigger, { visible: visible, adjustOverflow: false, getAlignments: this.getAlignments, getPopup: this.getPopup, className: styles$4['popup'], maskClick: false, disable: disable, animate: animate, showActions: [], hideActions: [], showDelay: showDelay, hideDelay: hideDelay, popupRef: dropdownRef, getContainer: getContainer, destroyAfterClose: destroyAfterClose, didAlign: didAlign, onVisibleChange: onVisibleChange, zIndex: zIndex }, children);
    };
    return CoverDropdown;
}(react__WEBPACK_IMPORTED_MODULE_0__["Component"]);

var AbstractSelect = /** @class */function (_super) {
    __extends(AbstractSelect, _super);
    function AbstractSelect(props, context) {
        return _super.call(this, props, context) || this;
    }
    return AbstractSelect;
}(react__WEBPACK_IMPORTED_MODULE_0__["Component"]);

var styles$5 = { "dropdown-top-enter": "dropdown-top-enter__3-3c5NZE", "top-enter": "top-enter__H8TV-Eb2", "dropdown-top-leave": "dropdown-top-leave__3z08Tvnl", "top-leave": "top-leave__24AtS4qC", "dropdown-bottom-enter": "dropdown-bottom-enter__2Nv64vUT", "bottom-enter": "bottom-enter__2tI_FXdX", "dropdown-bottom-leave": "dropdown-bottom-leave__3KKzqLzK", "bottom-leave": "bottom-leave__1h0uTkIo", "popup": "popup__1eJEOIvw", "content-inner": "content-inner__2XhNhokM", "triangle": "triangle__1Ejs3MQ2", "top-triangle": "top-triangle__3D6O0iNj", "bottom-triangle": "bottom-triangle__hCwt5aEH", "left-triangle": "left-triangle__2MD1wvte", "right-triangle": "right-triangle__1yHUGJvb", "topLeft-triangle": "topLeft-triangle__OSFSkiTe", "bottomLeft-triangle": "bottomLeft-triangle__2jBDiJyB", "topRight-triangle": "topRight-triangle__14P1DorJ", "bottomRight-triangle": "bottomRight-triangle__37QnAEy-", "leftTop-triangle": "leftTop-triangle__2zuvYkii", "rightTop-triangle": "rightTop-triangle__3tYBj59e", "leftBottom-triangle": "leftBottom-triangle__1EOo-3Nx", "rightBottom-triangle": "rightBottom-triangle__hh1JGNX7" };

var Content = function Content(props) {
    var placement = props.placement,
        style = props.style,
        className = props.className,
        children = props.children,
        gap = props.gap,
        arrow = props.arrow;
    var wrapperStyle = {};
    switch (true) {
        case /^top/.test(placement):
            wrapperStyle.paddingBottom = gap;
            break;
        case /^bottom/.test(placement):
            wrapperStyle.paddingTop = gap;
            break;
        case /^left/.test(placement):
            wrapperStyle.paddingRight = gap;
            break;
        case /^right/.test(placement):
            wrapperStyle.paddingLeft = gap;
            break;
        default:
            wrapperStyle.paddingBottom = gap;
    }
    var innerClassName = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$5['content-inner'], className);
    var triangleClassName = styles$5[placement + "-triangle"];
    return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-dropdown", style: wrapperStyle }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-dropdown-content", className: innerClassName, style: style }, children, arrow && Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-dropdown-triangle", className: triangleClassName })));
};

var dropdownPlacements = ['top', 'bottom', 'topLeft', 'topRight', 'bottomLeft', 'bottomRight'];
var alignMaps = {
    top: {
        placement: 'top',
        enterClassName: styles$5['dropdown-top-enter'],
        leaveClassName: styles$5['dropdown-top-leave']
    },
    bottom: {
        placement: 'bottom',
        enterClassName: styles$5['dropdown-bottom-enter'],
        leaveClassName: styles$5['dropdown-bottom-leave']
    },
    topLeft: {
        placement: 'topLeft',
        enterClassName: styles$5['dropdown-top-enter'],
        leaveClassName: styles$5['dropdown-top-leave']
    },
    topRight: {
        placement: 'topRight',
        enterClassName: styles$5['dropdown-top-enter'],
        leaveClassName: styles$5['dropdown-top-leave']
    },
    bottomLeft: {
        placement: 'bottomLeft',
        enterClassName: styles$5['dropdown-bottom-enter'],
        leaveClassName: styles$5['dropdown-bottom-leave']
    },
    bottomRight: {
        placement: 'bottomRight',
        enterClassName: styles$5['dropdown-bottom-enter'],
        leaveClassName: styles$5['dropdown-bottom-leave']
    }
};

var Dropdown = /** @class */function (_super) {
    __extends(Dropdown, _super);
    function Dropdown() {
        var _this = _super !== null && _super.apply(this, arguments) || this;
        _this.getPopup = function (args) {
            var placement = args.placement;
            var _a = _this.props,
                content = _a.content,
                className = _a.className,
                style = _a.style,
                gap = _a.gap,
                arrow = _a.arrow;
            return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Content, { placement: placement, className: className, style: style, gap: gap, arrow: arrow }, Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(content) ? content() : content);
        };
        _this.getAlignments = function (trigger) {
            var _a = _this.props,
                placement = _a.placement,
                adjustPlacements = _a.adjustPlacements,
                getOffset = _a.getOffset;
            var placements = Object(lodash_es__WEBPACK_IMPORTED_MODULE_8__["default"])([placement], adjustPlacements);
            return placements.map(function (val) {
                var align = alignMaps[val];
                var offset = Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(getOffset) ? getOffset(val, trigger) : [0, 0];
                return _assign({}, align, { offset: offset });
            });
        };
        return _this;
    }
    Dropdown.prototype.render = function () {
        var _a = this.props,
            children = _a.children,
            dropdownStyle = _a.dropdownStyle,
            dropdownClassName = _a.dropdownClassName,
            adjustOverflow = _a.adjustOverflow,
            zIndex = _a.zIndex,
            showDelay = _a.showDelay,
            hideDelay = _a.hideDelay,
            defaultVisible = _a.defaultVisible,
            showActions = _a.showActions,
            hideActions = _a.hideActions,
            onDropdownMouseEnter = _a.onDropdownMouseEnter,
            onDropdownMouseLeave = _a.onDropdownMouseLeave,
            didAlign = _a.didAlign,
            onVisibleChange = _a.onVisibleChange,
            maskClick = _a.maskClick,
            visible = _a.visible,
            disable = _a.disable,
            animate = _a.animate,
            destroyAfterClose = _a.destroyAfterClose,
            getContainer = _a.getContainer,
            toggleRef = _a.toggleRef,
            dropdownRef = _a.dropdownRef;
        var className = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$5['popup'], dropdownClassName);
        return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Trigger, { getPopup: this.getPopup, getAlignments: this.getAlignments, adjustOverflow: adjustOverflow, style: dropdownStyle, className: className, zIndex: zIndex, showDelay: showDelay, hideDelay: hideDelay, defaultVisible: defaultVisible, showActions: showActions, hideActions: hideActions, onPopupMouseEnter: onDropdownMouseEnter, onPopupMouseLeave: onDropdownMouseLeave, didAlign: didAlign, onVisibleChange: onVisibleChange, maskClick: maskClick, visible: visible, disable: disable, animate: animate, destroyAfterClose: destroyAfterClose, getContainer: getContainer, toggleRef: toggleRef, popupRef: dropdownRef }, children);
    };
    Dropdown.propTypes = {
        children: prop_types__WEBPACK_IMPORTED_MODULE_1__["element"].isRequired,
        content: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["oneOfType"])([prop_types__WEBPACK_IMPORTED_MODULE_1__["node"], prop_types__WEBPACK_IMPORTED_MODULE_1__["func"]]).isRequired,
        placement: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["oneOf"])(dropdownPlacements),
        style: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
        className: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        dropdownStyle: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
        dropdownClassName: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        zIndex: prop_types__WEBPACK_IMPORTED_MODULE_1__["number"],
        showDelay: prop_types__WEBPACK_IMPORTED_MODULE_1__["number"],
        hideDelay: prop_types__WEBPACK_IMPORTED_MODULE_1__["number"],
        defaultVisible: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        adjustOverflow: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["oneOfType"])([prop_types__WEBPACK_IMPORTED_MODULE_1__["array"], prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"]]),
        adjustPlacements: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["arrayOf"])(Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["oneOf"])(dropdownPlacements)),
        showActions: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["arrayOf"])(prop_types__WEBPACK_IMPORTED_MODULE_1__["string"]),
        hideActions: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["arrayOf"])(prop_types__WEBPACK_IMPORTED_MODULE_1__["string"]),
        onDropdownMouseEnter: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onDropdownMouseLeave: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onVisibleChange: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        maskClick: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        visible: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        disable: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        gap: prop_types__WEBPACK_IMPORTED_MODULE_1__["number"],
        animate: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        arrow: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        destroyAfterClose: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        getOffset: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        getContainer: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        toggleRef: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        dropdownRef: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"]
    };
    Dropdown.defaultProps = {
        placement: 'bottom',
        style: {},
        className: '',
        zIndex: 999,
        showDelay: 0,
        hideDelay: 0,
        defaultVisible: false,
        adjustOverflow: true,
        adjustPlacements: dropdownPlacements,
        showActions: ['onClick'],
        hideActions: ['onClick'],
        maskClick: true,
        gap: 6,
        animate: true,
        arrow: false,
        destroyAfterClose: false
    };
    return Dropdown;
}(react__WEBPACK_IMPORTED_MODULE_0__["Component"]);

/**
 * 为什么要自己组合state？
 * 我们熟知的React的setState方法，在官方doc中描述的是一个异步的方法，React会把state组合在一起更新，也就是
 * 网上许多人研究源码中的batchedUpdate，但是这有一个先决条件，React只会在自己的合成事件的调用栈中组合state。
 * 也就是说在原生事件或者计时器中是同步更新的。
 */
var Updater = /** @class */function () {
    function Updater(component) {
        var _this = this;
        this.updating = false;
        this.stateQueue = [];
        this.batchUpdate = function (state) {
            if (!_this.updating) {
                _this.updating = true;
                Promise.resolve().then(function () {
                    _this.flush();
                });
                _this.stateQueue.push(state);
            }
            _this.stateQueue.push(state);
        };
        this.flush = function () {
            var updateState = {};
            for (var _i = 0, _a = _this.stateQueue; _i < _a.length; _i++) {
                var state = _a[_i];
                updateState = _assign({}, updateState, state);
            }
            _this.updating = false;
            _this.stateQueue = [];
            _this.component.setState(updateState);
        };
        this.component = component;
    }
    return Updater;
}();

var styles$6 = { "list": "list__2wUtn9SV", "value": "value__3ykTiS0i", "placeholder": "placeholder__3OfQ1R61", "dropdown-placeholder": "dropdown-placeholder__OXW5Zkg3", "content": "content__2dKBqrbN", "title": "title__3KBjJE_A", "input-wrapper": "input-wrapper__3Xcl5k0k", "pulldown": "pulldown__213Lk9c4", "select-default": "select-default__2lKWMkVp", "focus": "focus__2TAV09ls", "open": "open__3NF65BpY", "dropdown-default": "dropdown-default__2q8P7nIJ", "dropdown-override": "dropdown-override__1CQR58FV", "select-cover": "select-cover__2cLxPEaj", "pulldown-cover": "pulldown-cover__1dMN_vrZ", "dropdown-cover": "dropdown-cover__z7Jvz4J9", "cover-title": "cover-title__3IF2zzru", "hidden": "hidden__1Q4RUdw5", "disable": "disable__23cVLtID" };

var selectModes = ['default', 'cover'];
var EMPTY = ''; // value 为空的状态
var ClassNames = {
    Open: styles$6['open'],
    Focus: styles$6['focus'],
    Placeholder: styles$6['placeholder'],
    Hidden: styles$6['hidden'],
    Disable: styles$6['disable']
};
var Select = /** @class */function (_super) {
    __extends(Select, _super);
    function Select(props) {
        var _this = _super.call(this, props) || this;
        _this.selectRef = null;
        _this.dropdownRef = null;
        _this.listRef = null;
        _this.inputRef = null;
        _this.children = null;
        _this.focus = function () {
            _this.toggleFocus(true);
        };
        _this.blur = function () {
            _this.toggleFocus(false);
            _this.toggleOpen(false);
            _this.selectRef && _this.selectRef.blur();
        };
        _this.ulRef = function (node$$1) {
            if (node$$1) {
                _this.listRef = node$$1;
            }
        };
        _this.divRef = function (node$$1) {
            if (node$$1) {
                _this.selectRef = node$$1;
            }
        };
        _this.getDropdownRef = function (node$$1) {
            var dropdownRef = _this.props.dropdownRef;
            if (node$$1) {
                _this.dropdownRef = node$$1;
            }
            Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(dropdownRef) && dropdownRef(node$$1);
        };
        _this.getInputRef = function (node$$1) {
            if (node$$1) {
                _this.inputRef = node$$1;
            }
        };
        _this.handleWindowMouseDown = function (e) {
            var _a = _this.state,
                focus = _a.focus,
                open = _a.open;
            var node$$1 = _this.selectRef;
            var dropdown = _this.dropdownRef;
            var target = e.target;
            if (!focus && !open) {
                return;
            }
            /* 判断Select选框 */
            if (node$$1 && node$$1.contains(target)) {
                return;
            }
            /* 判断dropdown列表 */
            if (dropdown && dropdown.contains(target)) {
                return;
            }
            /* 注意这里有一个逻辑：节点未渲染出来的时候，要blur */
            _this.toggleFocus(false, true);
            _this.toggleOpen(false, true);
        };
        _this.onOptionAvtive = function (option) {
            var ul = _this.listRef;
            var li = option.getLiNode();
            if (!ul || !li) {
                return;
            }
            /* 元素在视口下方 */
            if (li.offsetTop + li.offsetHeight > ul.clientHeight + ul.scrollTop) {
                ul.scrollTop = li.offsetTop + li.offsetHeight - ul.clientHeight;
            }
            /* 元素在视口上方 */
            if (li.offsetTop < ul.scrollTop) {
                ul.scrollTop = li.offsetTop;
            }
        };
        _this.onOptionClick = function (e, option) {
            var _a = _this.props,
                disable = _a.disable,
                onOptionClick = _a.onOptionClick,
                deselectable = _a.deselectable;
            if (disable) {
                return;
            }
            var value = option.props.value;
            var selected = option.state.selected;
            if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(onOptionClick)) {
                onOptionClick({ value: value, selected: selected, e: e });
            }
            if (!selected) {
                _this.handleChange(value);
            }
            if (selected && deselectable) {
                _this.handleChange(EMPTY);
            }
        };
        _this.toggleFocus = function (focus, batch) {
            if (batch === void 0) {
                batch = false;
            }
            var disable = _this.props.disable;
            if (disable || _this.state.focus === focus) {
                return;
            }
            var _a = _this.props,
                onFocus = _a.onFocus,
                onBlur = _a.onBlur;
            if (focus) {
                Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(onFocus) && onFocus();
            } else {
                Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(onBlur) && onBlur();
            }
            if (batch) {
                _this.batchUpdater.batchUpdate({
                    focus: focus
                });
            } else {
                _this.setState({
                    focus: focus
                });
            }
        };
        _this.toggleOpen = function (open, batch) {
            if (batch === void 0) {
                batch = false;
            }
            var _a = _this.props,
                disable = _a.disable,
                controlOpen = _a.open;
            if (disable || Object(lodash_es__WEBPACK_IMPORTED_MODULE_6__[/* default */ "a"])(controlOpen) || _this.state.open === open) {
                return;
            }
            var state = { open: open };
            if (!open) {
                state.searchValue = EMPTY;
            }
            if (batch) {
                _this.batchUpdater.batchUpdate(state);
            } else {
                _this.setState(state);
            }
        };
        _this.handleChange = function (val) {
            var _a = _this.props,
                onChange = _a.onChange,
                value = _a.value,
                placeholder = _a.placeholder;
            if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(onChange)) {
                onChange({ value: val });
            }
            /* Change之后延迟200ms关闭 */
            setTimeout(function () {
                _this.toggleOpen(false);
            }, 200);
            /* 若参数中显示存在 selectedKeys，则不执行默认操作 */
            if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_9__["default"])(value)) {
                return;
            }
            _this.manager.select(val);
            var meta = _this.manager.getSelectedMeta();
            var title = placeholder;
            if (val !== EMPTY && meta) {
                title = meta.title;
            }
            _this.setState({
                value: val,
                title: title
            });
        };
        _this.handleClick = function (e) {
            var _a = _this.props,
                disable = _a.disable,
                searchable = _a.searchable,
                onClick = _a.onClick;
            var open = _this.state.open;
            Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(onClick) && onClick(e);
            if (disable || searchable && open) {
                return;
            }
            var manager = _this.manager;
            var activeValue = manager.getActiveValue();
            var selectedValue = manager.getSelectedValue();
            if (_this.state.open) {
                _this.toggleOpen(false);
            } else {
                _this.toggleOpen(true);
                _this.toggleFocus(true);
            }
            manager.active(activeValue || selectedValue);
        };
        _this.handleFocus = function (e) {
            _this.focus();
        };
        _this.handleInputChange = function (e) {
            var onSearch = _this.props.onSearch;
            Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(onSearch) && onSearch(e);
            _this.setState({
                searchValue: e.target.value
            });
        };
        _this.handleKeyDown = function (e) {
            var _a = _this.props,
                disable = _a.disable,
                onKeyDown = _a.onKeyDown;
            if (disable) {
                return;
            }
            Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(onKeyDown) && onKeyDown(e);
            var manager = _this.manager;
            var activeValue = manager.getActiveValue();
            var selectedValue = manager.getSelectedValue();
            var _b = _this.state,
                open = _b.open,
                value = _b.value;
            /* 若当前为关闭状态，则打开 */
            if (e.keyCode === KeyCode.Enter && !open) {
                _this.toggleOpen(true);
                manager.active(activeValue || selectedValue);
                e.preventDefault();
                return;
            }
            /* 若当前为打开状态，且无激活项，则关闭 */
            if (e.keyCode === KeyCode.Enter && open && activeValue === null) {
                _this.toggleOpen(false);
                e.preventDefault();
                return;
            }
            /* 若当前为打开状态，切激活项等于选择项，则关闭 */
            if (e.keyCode === KeyCode.Enter && open && value === activeValue) {
                _this.toggleOpen(false);
                e.preventDefault();
                return;
            }
            /* 若当前为打开状态，且存在不等于选择项的激活项，则选择 */
            if (e.keyCode === KeyCode.Enter && open && activeValue !== null && activeValue !== value) {
                _this.handleChange(activeValue);
                manager.select(activeValue);
                e.preventDefault();
                return;
            }
            /* ESC键关闭 */
            if (e.keyCode === KeyCode.Esc) {
                _this.toggleOpen(false);
                e.preventDefault();
                return;
            }
            /* Up键，并且为关闭状态，则打开，激活态定位当选中值 */
            if (e.keyCode === KeyCode.ArrowUp && !_this.state.open) {
                _this.toggleOpen(true);
                manager.active(activeValue || selectedValue);
                e.preventDefault();
                return;
            }
            /* Up键，并且为打开状态，则向上循环激活 */
            if (e.keyCode === KeyCode.ArrowUp && _this.state.open) {
                manager.activeTo(activeValue, -1);
                e.preventDefault();
                return;
            }
            /* Down键，并且为关闭状态 */
            if (e.keyCode === KeyCode.ArrowDown && !_this.state.open) {
                _this.toggleOpen(true);
                manager.active(activeValue || selectedValue);
                e.preventDefault();
                return;
            }
            /* Down键，并且为打开状态，则向下循环激活 */
            if (e.keyCode === KeyCode.ArrowDown && _this.state.open) {
                manager.activeTo(activeValue, 1);
                e.preventDefault();
                return;
            }
            /* Tab键，焦点切换 */
            if (e.keyCode === KeyCode.Tab) {
                _this.toggleOpen(false);
                _this.toggleFocus(false);
            }
        };
        _this.handleDropdownClick = function (e) {
            var _a = _this.props,
                disable = _a.disable,
                searchable = _a.searchable,
                mode = _a.mode;
            if (disable) {
                return;
            }
            _this.toggleFocus(true);
            /* 点击弹窗的其他区域会造成元素失焦，这里手动focus */
            if (searchable && mode === 'default') {
                _this.inputRef && _this.inputRef.focus();
                return;
            }
            _this.selectRef && _this.selectRef.focus();
        };
        _this.forEachOption = function (children) {
            var manager = _this.manager;
            manager.clear();
            if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_10__["default"])(children)) {
                forEach(children, function (child) {
                    if (Object(react__WEBPACK_IMPORTED_MODULE_0__["isValidElement"])(child) && child.type === Option) {
                        _this.push(child);
                    }
                });
            }
            if (Object(react__WEBPACK_IMPORTED_MODULE_0__["isValidElement"])(children) && children.type === Option) {
                _this.push(children);
            }
        };
        _this.filterOption = function (children) {
            var manager = _this.manager;
            manager.clear();
            var filter$$1 = _this.props.filter;
            var searchValue = _this.state.searchValue;
            if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_10__["default"])(children)) {
                return filter(children, function (option) {
                    if (Object(react__WEBPACK_IMPORTED_MODULE_0__["isValidElement"])(option) && option.type === Option) {
                        var visible = filter$$1(searchValue, option.props);
                        _this.push(option, visible);
                        return visible;
                    }
                    return false;
                });
            }
            if (Object(react__WEBPACK_IMPORTED_MODULE_0__["isValidElement"])(children) && children.type === Option) {
                var visible = filter$$1(searchValue, children.props);
                _this.push(children, visible);
                return visible ? children : null;
            }
            return null;
        };
        _this.push = function (option, visible) {
            if (visible === void 0) {
                visible = true;
            }
            var _a = option.props,
                value = _a.value,
                title = _a.title,
                children = _a.children,
                disable = _a.disable;
            _this.manager.push({
                value: value,
                disable: !!disable,
                title: title || children,
                visible: visible
            });
        };
        _this.getDropdownPlaceholder = function () {
            var dropdownPlaceholder = _this.props.dropdownPlaceholder;
            return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-select-dropdown-placeholder", className: styles$6['dropdown-placeholder'] }, dropdownPlaceholder);
        };
        _this.getOptions = function () {
            var _a, _b;
            var node$$1 = _this.selectRef;
            if (!node$$1) {
                return null;
            }
            var _c = _this.state,
                title = _c.title,
                open = _c.open,
                value = _c.value,
                focus = _c.focus;
            var _d = _this.props,
                mode = _d.mode,
                listStyle = _d.listStyle,
                listClassName = _d.listClassName,
                dropdownStyle = _d.dropdownStyle,
                dropdownClassName = _d.dropdownClassName,
                searchable = _d.searchable,
                children = _d.children;
            var listClassNames = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$6['list'], listClassName);
            var dropdownClassNames = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$6["dropdown-" + mode], dropdownClassName, (_a = {}, _a[ClassNames.Open] = mode === 'cover' && open, _a[ClassNames.Focus] = mode === 'cover' && focus, _a));
            /* 若不支持搜索，或者不是default模式，则用默认值 */
            if (!searchable || mode !== 'default') {
                _this.children = children;
            }
            /**
             * 这里相当于对children做了一个缓存，为什么要这么做呢？因为搜索之后options会变化，在关闭的时候需要清空searchValue，
             * 这时候会导致filter不一致，为了保持交互一致，这里做了个缓存
             */
            if (searchable && open && mode === 'default') {
                _this.children = _this.filterOption(children);
            }
            var renderChildren = !Object(lodash_es__WEBPACK_IMPORTED_MODULE_11__["default"])(_this.children) ? _this.children : _this.getDropdownPlaceholder();
            /* cover 模式 */
            if (mode === 'cover') {
                var valueClassNames = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$6['value'], (_b = {}, _b[ClassNames.Placeholder] = value === EMPTY, _b));
                return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-select-dropdown", className: dropdownClassNames, style: _assign({
                        /* 解释一下：cover模式是整个浮窗盖上去的，这里要把选框的长度盖过 */
                        width: node$$1.offsetWidth + 2 }, dropdownStyle), onClick: _this.handleDropdownClick }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-select-title", className: styles$6['cover-title'] }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-select-value", className: valueClassNames }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-select-title", className: styles$6['title'] }, title))), Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("ul", { "data-sel": "spark-select-list", ref: _this.ulRef, className: listClassNames, style: listStyle }, renderChildren));
            }
            /* default 模式 */
            return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-select-dropdown", className: dropdownClassNames, style: _assign({ width: node$$1.offsetWidth }, dropdownStyle), onClick: _this.handleDropdownClick }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("ul", { "data-sel": "spark-select-list", ref: _this.ulRef, className: listClassNames, style: listStyle }, renderChildren));
        };
        _this.manager = new SelectManager(_this);
        _this.batchUpdater = new Updater(_this);
        var _a = _this.props,
            defaultOpen = _a.defaultOpen,
            open = _a.open,
            autoFocus = _a.autoFocus,
            value = _a.value,
            defaultValue = _a.defaultValue,
            disable = _a.disable,
            placeholder = _a.placeholder,
            children = _a.children;
        /* 初始化的时候获取meta */
        _this.forEachOption(children);
        /* 优先级： disable > value > defaultValue */
        var stateVal = EMPTY;
        switch (true) {
            case disable:
                stateVal = EMPTY;
                break;
            case !Object(lodash_es__WEBPACK_IMPORTED_MODULE_4__["default"])(value):
                stateVal = value;
                break;
            case !Object(lodash_es__WEBPACK_IMPORTED_MODULE_4__["default"])(defaultValue):
                stateVal = defaultValue;
                break;
            default:
                break;
        }
        var title = placeholder;
        if (stateVal !== EMPTY && !disable) {
            _this.manager.select(stateVal);
            var meta = _this.manager.getSelectedMeta();
            title = meta ? meta.title : title;
        }
        _this.state = {
            value: stateVal,
            /* 优先级： disable > open > defaultOpen */
            open: disable ? false : Object(lodash_es__WEBPACK_IMPORTED_MODULE_6__[/* default */ "a"])(open) ? open : !!defaultOpen,
            /* 优先级： disable > autoFocus */
            focus: disable ? false : !!autoFocus,
            title: title,
            searchValue: EMPTY
        };
        return _this;
    }
    Select.init = function () {
        window.addEventListener('mousedown', function (e) {
            Select.clickHandlers.forEach(function (v, k) {
                v(e);
            });
        });
    };
    Select.prototype.getChildContext = function () {
        return {
            manager: this.manager,
            mode: this.props.mode
        };
    };
    Select.prototype.componentDidMount = function () {
        Select.clickHandlers.set(this, this.handleWindowMouseDown);
        var _a = this.props,
            disable = _a.disable,
            searchable = _a.searchable;
        var _b = this.state,
            focus = _b.focus,
            open = _b.open;
        if (focus && !disable && this.selectRef) {
            this.selectRef.focus();
        }
        if (searchable && open && focus && this.inputRef) {
            this.inputRef.focus();
        }
    };
    Select.prototype.componentWillReceiveProps = function (nextProps) {
        var value = nextProps.value,
            open = nextProps.open,
            disable = nextProps.disable,
            placeholder = nextProps.placeholder,
            children = nextProps.children;
        this.forEachOption(children);
        var state = {};
        if (!Object(lodash_es__WEBPACK_IMPORTED_MODULE_4__["default"])(value) && !disable) {
            state.value = value;
            this.manager.select(value);
            var meta = this.manager.getSelectedMeta();
            state.title = placeholder;
            if (value !== EMPTY && meta) {
                state.title = meta.title;
            }
        }
        if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_6__[/* default */ "a"])(open)) {
            state.open = open;
        }
        if (disable) {
            state.focus = false;
            state.open = false;
            state.value = EMPTY;
        }
        if (!Object(lodash_es__WEBPACK_IMPORTED_MODULE_11__["default"])(state)) {
            this.setState(state);
        }
    };
    Select.prototype.componentDidUpdate = function () {
        var _a = this.props,
            disable = _a.disable,
            searchable = _a.searchable;
        var _b = this.state,
            focus = _b.focus,
            open = _b.open;
        if (disable || !focus) {
            return;
        }
        if (searchable && open && this.inputRef) {
            this.inputRef.focus();
            return;
        }
        if (this.selectRef) {
            this.selectRef.focus();
        }
    };
    Select.prototype.componentWillUnmount = function () {
        Select.clickHandlers.delete(this);
    };
    Select.prototype.render = function () {
        var _a, _b, _c;
        var _d = this.state,
            open = _d.open,
            focus = _d.focus,
            value = _d.value,
            title = _d.title,
            searchValue = _d.searchValue;
        var _e = this.props,
            mode = _e.mode,
            style = _e.style,
            className = _e.className,
            showDelay = _e.showDelay,
            hideDelay = _e.hideDelay,
            destroyAfterClose = _e.destroyAfterClose,
            onMouseEnter = _e.onMouseEnter,
            onMouseLeave = _e.onMouseLeave,
            onMouseDown = _e.onMouseDown,
            didAlign = _e.didAlign,
            onOpenChange = _e.onOpenChange,
            animate = _e.animate,
            disable = _e.disable,
            searchable = _e.searchable,
            tabIndex = _e.tabIndex,
            zIndex = _e.zIndex,
            gap = _e.gap,
            getDropdownOffset = _e.getDropdownOffset,
            getContainer = _e.getContainer;
        var isEmpty$$1 = value === EMPTY;
        var classNames = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$6["select-" + mode], className, (_a = {}, _a[ClassNames.Open] = open, _a[ClassNames.Focus] = focus, _a[ClassNames.Disable] = disable, _a));
        var inputClassNames = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$6['input-wrapper'], (_b = {}, _b[ClassNames.Hidden] = !searchable || !focus || !open, _b));
        var valueClassNames = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$6['value'], (_c = {}, _c[ClassNames.Placeholder] = isEmpty$$1 || searchable && open && focus, _c[ClassNames.Hidden] = searchable && open && focus && searchValue !== EMPTY, _c));
        /* cover 模式 */
        if (mode === 'cover') {
            return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(CoverDropdown, { visible: open, disable: disable, animate: animate, content: this.getOptions, maskClick: false, showActions: [], hideActions: [], showDelay: showDelay, hideDelay: hideDelay, dropdownRef: this.getDropdownRef, getContainer: getContainer, destroyAfterClose: destroyAfterClose, didAlign: didAlign, onVisibleChange: onOpenChange, zIndex: zIndex }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-select", ref: this.divRef, style: style, className: classNames, tabIndex: disable ? undefined : tabIndex, onFocus: this.handleFocus, onKeyDown: this.handleKeyDown, onClick: this.handleClick, onMouseEnter: onMouseEnter, onMouseLeave: onMouseLeave, onMouseDown: onMouseDown }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-select-value", className: valueClassNames }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-select-title", className: styles$6['title'] }, title)), Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("span", { "data-sel": "spark-select-pulldown", className: styles$6['pulldown'] }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Icon, { type: "pulldown" }))));
        }
        /* default 模式 */
        return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Dropdown, { visible: open, disable: disable, animate: animate, className: styles$6['dropdown-override'], content: this.getOptions, placement: "bottom", adjustOverflow: false, maskClick: false, showActions: [], hideActions: [], showDelay: showDelay, hideDelay: hideDelay, dropdownRef: this.getDropdownRef, gap: gap, getOffset: getDropdownOffset, getContainer: getContainer, destroyAfterClose: destroyAfterClose, didAlign: didAlign, onVisibleChange: onOpenChange, zIndex: zIndex }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-select", ref: this.divRef, style: style, className: classNames, tabIndex: disable ? undefined : tabIndex, onClick: this.handleClick, onFocus: this.handleFocus, onKeyDown: this.handleKeyDown, onMouseEnter: onMouseEnter, onMouseLeave: onMouseLeave, onMouseDown: onMouseDown }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-select-content", className: styles$6['content'] }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-select-value", className: valueClassNames }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-select-title", className: styles$6['title'] }, title)), Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-select-text", className: inputClassNames }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("input", { "data-sel": "spark-select-input", ref: this.getInputRef, type: "text", value: searchValue, onChange: this.handleInputChange }))), Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("span", { "data-sel": "spark-select-pulldown", className: styles$6['pulldown'] }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Icon, { type: "pulldown" }))));
    };
    Select.Option = Option;
    Select.propTypes = {
        children: prop_types__WEBPACK_IMPORTED_MODULE_1__["node"].isRequired,
        mode: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["oneOf"])(selectModes),
        style: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
        className: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        listStyle: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
        listClassName: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        dropdownStyle: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
        dropdownClassName: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        tabIndex: prop_types__WEBPACK_IMPORTED_MODULE_1__["number"],
        zIndex: prop_types__WEBPACK_IMPORTED_MODULE_1__["number"],
        showDelay: prop_types__WEBPACK_IMPORTED_MODULE_1__["number"],
        hideDelay: prop_types__WEBPACK_IMPORTED_MODULE_1__["number"],
        value: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        defaultValue: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        placeholder: prop_types__WEBPACK_IMPORTED_MODULE_1__["node"],
        dropdownPlaceholder: prop_types__WEBPACK_IMPORTED_MODULE_1__["node"],
        gap: prop_types__WEBPACK_IMPORTED_MODULE_1__["number"],
        animate: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        defaultOpen: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        open: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        autoFocus: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        disable: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        deselectable: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        destroyAfterClose: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        searchable: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        filter: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        getDropdownOffset: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onOptionClick: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onSearch: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onChange: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onFocus: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onBlur: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onClick: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onMouseEnter: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onMouseLeave: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onKeyDown: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onOpenChange: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"]
    };
    Select.defaultProps = {
        mode: 'default',
        placeholder: EMPTY,
        dropdownPlaceholder: EMPTY,
        tabIndex: 0,
        zIndex: 999,
        gap: 1,
        defaultOpen: false,
        autoFocus: false,
        disable: false,
        deselectable: false,
        destroyAfterClose: false,
        searchable: false,
        filter: function filter$$1() {
            return true;
        }
    };
    Select.childContextTypes = {
        manager: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["instanceOf"])(SelectManager).isRequired,
        mode: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["oneOf"])(selectModes).isRequired
    };
    Select.clickHandlers = new Map();
    __decorate([Once()], Select, "init", null);
    return Select;
}(AbstractSelect);
Select.init();

var styles$7 = { "triangle": "triangle__3WQEMs-L", "triangle-left": "triangle-left__XNUEjrJD", "triangle-right": "triangle-right__2p3yEl4m", "triangle-top": "triangle-top__1H3TMgOo", "triangle-bottom": "triangle-bottom__2iUf5DaJ", "popup": "popup__6JA8Hb43", "popover-top-enter": "popover-top-enter__wpCtFB54", "top-enter": "top-enter__3NkuBnKQ", "popover-top-leave": "popover-top-leave__262wdHJK", "top-leave": "top-leave__2dNZE3VX", "popover-topLeft-enter": "popover-topLeft-enter__1ABwYDWw", "top-left-enter": "top-left-enter__3y39ox27", "popover-topLeft-leave": "popover-topLeft-leave__2yEOVGQ4", "top-left-leave": "top-left-leave__3PH4pQVu", "popover-topRight-enter": "popover-topRight-enter__1cmehnHo", "top-right-enter": "top-right-enter__1H9tCW3K", "popover-topRight-leave": "popover-topRight-leave__2d2AnxwV", "top-right-leave": "top-right-leave__1H37CXtF", "popover-bottom-enter": "popover-bottom-enter__3ezYIjay", "bottom-enter": "bottom-enter__1m8c9aL4", "popover-bottom-leave": "popover-bottom-leave__2bayuzP0", "bottom-leave": "bottom-leave__3Phgg5J9", "popover-bottomLeft-enter": "popover-bottomLeft-enter__2B0627GB", "bottom-left-enter": "bottom-left-enter__E5aEOmQm", "popover-bottomLeft-leave": "popover-bottomLeft-leave__1FX9_zF6", "bottom-left-leave": "bottom-left-leave__1A5ChhQA", "popover-bottomRight-enter": "popover-bottomRight-enter__2jksVgbE", "bottom-right-enter": "bottom-right-enter__2bv6mX1K", "popover-bottomRight-leave": "popover-bottomRight-leave__WmaJHAnO", "bottom-right-leave": "bottom-right-leave__1POVbfE-", "popover-left-enter": "popover-left-enter__3UUfAS1-", "left-enter": "left-enter__buvIX8J5", "popover-left-leave": "popover-left-leave__2HqKEf7B", "left-leave": "left-leave__3fy7SIRo", "popover-leftTop-enter": "popover-leftTop-enter__2u2Szp4U", "left-top-enter": "left-top-enter__33dM7FYA", "popover-leftTop-leave": "popover-leftTop-leave__3v3mXXJG", "left-top-leave": "left-top-leave__r7vGxz-7", "popover-leftBottom-enter": "popover-leftBottom-enter__Jrv_Byd7", "left-bottom-enter": "left-bottom-enter__1gUyInVN", "popover-leftBottom-leave": "popover-leftBottom-leave__1MN1Nhma", "left-bottom-leave": "left-bottom-leave__YdskhapX", "popover-right-enter": "popover-right-enter__1fbotrm3", "right-enter": "right-enter__3MecXPQy", "popover-right-leave": "popover-right-leave__Mis2pDgY", "right-leave": "right-leave__373pBBaU", "popover-rightTop-enter": "popover-rightTop-enter__3soW2Dmz", "right-top-enter": "right-top-enter__1Xv9Fnul", "popover-rightTop-leave": "popover-rightTop-leave__2AXo-gij", "right-top-leave": "right-top-leave__-59yAcHy", "popover-rightBottom-enter": "popover-rightBottom-enter__n_bj-V10", "right-bottom-enter": "right-bottom-enter__q1ykth7t", "popover-rightBottom-leave": "popover-rightBottom-leave__1EICGpHh", "right-bottom-leave": "right-bottom-leave__2Mspxd2x", "content-inner": "content-inner__3IVEXlPI", "top-triangle": "top-triangle__39wzDK0Z", "bottom-triangle": "bottom-triangle__3lBY_MvD", "left-triangle": "left-triangle__1LowkDSt", "right-triangle": "right-triangle__27STIQpj", "topLeft-triangle": "topLeft-triangle__SS6j_Egm", "bottomLeft-triangle": "bottomLeft-triangle__3u1cEhds", "topRight-triangle": "topRight-triangle__DFRAK--A", "bottomRight-triangle": "bottomRight-triangle__1CcsOEIO", "leftTop-triangle": "leftTop-triangle__1wCk1v7L", "rightTop-triangle": "rightTop-triangle__1QCWLgxh", "leftBottom-triangle": "leftBottom-triangle__2nS-eHbe", "rightBottom-triangle": "rightBottom-triangle__3mTfKFMX" };

var Content$2 = function Content(props) {
    var placement = props.placement,
        style = props.style,
        className = props.className,
        arrow = props.arrow,
        gap = props.gap,
        children = props.children;
    var wrapperStyle = {};
    switch (true) {
        case /^top/.test(placement):
            wrapperStyle.paddingBottom = gap;
            break;
        case /^bottom/.test(placement):
            wrapperStyle.paddingTop = gap;
            break;
        case /^left/.test(placement):
            wrapperStyle.paddingRight = gap;
            break;
        case /^right/.test(placement):
            wrapperStyle.paddingLeft = gap;
            break;
        default:
            wrapperStyle.paddingBottom = gap;
    }
    var triangleClassName = styles$7[placement + "-triangle"];
    var innerClassName = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$7['content-inner'], className);
    return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-popover", style: wrapperStyle }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-popover-content", className: innerClassName, style: style }, children, arrow && Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-popover-triangle", className: triangleClassName })));
};

var alignMaps$1 = {
    top: {
        placement: 'top',
        enterClassName: styles$7['popover-top-enter'],
        leaveClassName: styles$7['popover-top-leave']
    },
    bottom: {
        placement: 'bottom',
        enterClassName: styles$7['popover-bottom-enter'],
        leaveClassName: styles$7['popover-bottom-leave']
    },
    left: {
        placement: 'left',
        enterClassName: styles$7['popover-left-enter'],
        leaveClassName: styles$7['popover-left-leave']
    },
    right: {
        placement: 'right',
        enterClassName: styles$7['popover-right-enter'],
        leaveClassName: styles$7['popover-right-leave']
    },
    topLeft: {
        placement: 'topLeft',
        enterClassName: styles$7['popover-topLeft-enter'],
        leaveClassName: styles$7['popover-topLeft-leave']
    },
    topRight: {
        placement: 'topRight',
        enterClassName: styles$7['popover-topRight-enter'],
        leaveClassName: styles$7['popover-topRight-leave']
    },
    bottomLeft: {
        placement: 'bottomLeft',
        enterClassName: styles$7['popover-bottomLeft-enter'],
        leaveClassName: styles$7['popover-bottomLeft-leave']
    },
    bottomRight: {
        placement: 'bottomRight',
        enterClassName: styles$7['popover-bottomRight-enter'],
        leaveClassName: styles$7['popover-bottomRight-leave']
    },
    leftTop: {
        placement: 'leftTop',
        enterClassName: styles$7['popover-leftTop-enter'],
        leaveClassName: styles$7['popover-leftTop-leave']
    },
    leftBottom: {
        placement: 'leftBottom',
        enterClassName: styles$7['popover-left-enter'],
        leaveClassName: styles$7['popover-left-leave']
    },
    rightTop: {
        placement: 'rightTop',
        enterClassName: styles$7['popover-rightTop-enter'],
        leaveClassName: styles$7['popover-rightTop-leave']
    },
    rightBottom: {
        placement: 'rightBottom',
        enterClassName: styles$7['popover-rightBottom-enter'],
        leaveClassName: styles$7['popover-rightBottom-leave']
    }
};

/* 注意此处的常量与 './styles/Commmon.less' 中的常量等量 */
var SQRT_2 = 1.5;
var TRIANGLE_BORDER = 8;
var BORDER_RADIUS = 3;
var TRIANGLE_GAP = 4;
/* 16.5 */
var ARROW_OFFSET = SQRT_2 + TRIANGLE_BORDER + BORDER_RADIUS + TRIANGLE_GAP;
/**
 * Popover component
 */
var Popover = /** @class */function (_super) {
    __extends(Popover, _super);
    function Popover() {
        var _this = _super !== null && _super.apply(this, arguments) || this;
        _this.getPopup = function (args) {
            var placement = args.placement;
            var _a = _this.props,
                content = _a.content,
                style = _a.style,
                className = _a.className,
                arrow = _a.arrow,
                gap = _a.gap;
            return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Content$2, { placement: placement, style: style, className: className, arrow: arrow, gap: gap }, Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(content) ? content() : content);
        };
        _this.getAlignments = function (trigger) {
            var _a = _this.props,
                placement = _a.placement,
                adjustPlacements = _a.adjustPlacements,
                arrowAtCenter = _a.arrowAtCenter,
                arrow = _a.arrow,
                getOffset = _a.getOffset;
            var placements$$1 = Object(lodash_es__WEBPACK_IMPORTED_MODULE_12__[/* default */ "a"])([placement], adjustPlacements, placement);
            return placements$$1.map(function (val) {
                var align = alignMaps$1[val];
                if (arrow && arrowAtCenter && trigger) {
                    var rect = trigger.getBoundingClientRect();
                    return _assign({}, align, { offset: _this.getCenterPosition(val, rect) });
                }
                var offset = Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(getOffset) ? getOffset(val, trigger) : [0, 0];
                return _assign({}, align, { offset: offset });
            });
        };
        _this.getCenterPosition = function (placement, rect) {
            var leftOffset = rect.width / 2 - ARROW_OFFSET;
            var topOffset = rect.height / 2 - ARROW_OFFSET;
            if (placement === 'topLeft' || placement === 'bottomLeft') {
                return [0, leftOffset];
            }
            if (placement === 'topRight' || placement === 'bottomRight') {
                return [0, -leftOffset];
            }
            if (placement === 'leftTop' || placement === 'rightTop') {
                return [topOffset, 0];
            }
            if (placement === 'leftBottom' || placement === 'rightBottom') {
                return [-topOffset, 0];
            }
            return [0, 0];
        };
        return _this;
    }
    Popover.prototype.render = function () {
        var _a = this.props,
            adjustOverflow = _a.adjustOverflow,
            popoverStyle = _a.popoverStyle,
            popoverClassName = _a.popoverClassName,
            zIndex = _a.zIndex,
            showDelay = _a.showDelay,
            hideDelay = _a.hideDelay,
            defaultVisible = _a.defaultVisible,
            showActions = _a.showActions,
            hideActions = _a.hideActions,
            onPopoverMouseEnter = _a.onPopoverMouseEnter,
            onPopoverMouseLeave = _a.onPopoverMouseLeave,
            didAlign = _a.didAlign,
            onVisibleChange = _a.onVisibleChange,
            maskClick = _a.maskClick,
            visible = _a.visible,
            disable = _a.disable,
            animate = _a.animate,
            destroyAfterClose = _a.destroyAfterClose,
            getContainer = _a.getContainer,
            toggleRef = _a.toggleRef,
            popoverRef = _a.popoverRef;
        var className = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$7['popup'], popoverClassName);
        return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Trigger, { getPopup: this.getPopup, getAlignments: this.getAlignments, adjustOverflow: adjustOverflow, style: popoverStyle, className: className, zIndex: zIndex, showDelay: showDelay, hideDelay: hideDelay, defaultVisible: defaultVisible, showActions: showActions, hideActions: hideActions, onPopupMouseEnter: onPopoverMouseEnter, onPopupMouseLeave: onPopoverMouseLeave, didAlign: didAlign, onVisibleChange: onVisibleChange, maskClick: maskClick, visible: visible, disable: disable, animate: animate, getContainer: getContainer, destroyAfterClose: destroyAfterClose, toggleRef: toggleRef, popupRef: popoverRef }, this.props.children);
    };
    Popover.propTypes = {
        children: prop_types__WEBPACK_IMPORTED_MODULE_1__["element"].isRequired,
        content: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["oneOfType"])([prop_types__WEBPACK_IMPORTED_MODULE_1__["node"], prop_types__WEBPACK_IMPORTED_MODULE_1__["func"]]).isRequired,
        placement: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["oneOf"])(placements),
        style: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
        className: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        popoverStyle: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
        popoverClassName: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        zIndex: prop_types__WEBPACK_IMPORTED_MODULE_1__["number"],
        showDelay: prop_types__WEBPACK_IMPORTED_MODULE_1__["number"],
        hideDelay: prop_types__WEBPACK_IMPORTED_MODULE_1__["number"],
        defaultVisible: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        adjustOverflow: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["oneOfType"])([prop_types__WEBPACK_IMPORTED_MODULE_1__["array"], prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"]]),
        adjustPlacements: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["arrayOf"])(Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["oneOf"])(placements)),
        showActions: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["arrayOf"])(prop_types__WEBPACK_IMPORTED_MODULE_1__["string"]),
        hideActions: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["arrayOf"])(prop_types__WEBPACK_IMPORTED_MODULE_1__["string"]),
        onPopoverMouseEnter: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onPopoverMouseLeave: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        didAlign: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onVisibleChange: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        maskClick: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        visible: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        disable: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        arrow: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        arrowAtCenter: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        gap: prop_types__WEBPACK_IMPORTED_MODULE_1__["number"],
        getOffset: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        animate: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        destroyAfterClose: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        getContainer: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        toggleRef: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        popoverRef: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"]
    };
    Popover.defaultProps = {
        placement: 'bottom',
        style: {},
        className: '',
        popoverStyle: {},
        popoverClassName: '',
        zIndex: 999,
        showDelay: 0,
        hideDelay: 0,
        defaultVisible: false,
        adjustOverflow: true,
        adjustPlacements: placements,
        showActions: ['onMouseEnter'],
        hideActions: ['onMouseLeave'],
        maskClick: true,
        disable: false,
        arrow: true,
        arrowAtCenter: false,
        gap: 12,
        animate: true,
        destroyAfterClose: false
    };
    return Popover;
}(react__WEBPACK_IMPORTED_MODULE_0__["Component"]);

var styles$8 = { "tooltip": "tooltip__h5Tk8-6c" };

/**
 * Tooltip component
 */
var Tooltip = function Tooltip(props) {
    var tooltipStyle = props.tooltipStyle,
        tooltipClassName = props.tooltipClassName,
        onTooltipMouseEnter = props.onTooltipMouseEnter,
        onTooltipMouseLeave = props.onTooltipMouseLeave,
        className = props.className,
        children = props.children,
        tooltipRef = props.tooltipRef;
    var classNames = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$8['tooltip'], className);
    return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Popover, _assign({}, props, { content: props.title, className: classNames, popoverStyle: tooltipStyle, popoverClassName: tooltipClassName, onPopoverMouseEnter: onTooltipMouseEnter, onPopoverMouseLeave: onTooltipMouseLeave, popoverRef: tooltipRef }), children);
};
Tooltip.propTypes = {
    title: prop_types__WEBPACK_IMPORTED_MODULE_1__["node"],
    tooltipStyle: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
    tooltipClassName: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
    onTooltipMouseEnter: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
    onTooltipMouseLeave: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
    tooltipRef: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"]
};

var LazyStatus;
(function (LazyStatus) {
    LazyStatus[LazyStatus["Ready"] = 0] = "Ready";
    LazyStatus[LazyStatus["Render"] = 1] = "Render";
})(LazyStatus || (LazyStatus = {}));
var LazyRender = /** @class */function (_super) {
    __extends(LazyRender, _super);
    function LazyRender(props) {
        var _this = _super.call(this, props) || this;
        _this.modalRef = null;
        _this.handleLazyReady = function () {
            /**
             * 使用 Promise 把渲染操作放进 NextTick 中
             * 为什么要进入下一个 Event Loop？
             * 解答：因为第一次渲染的时候，由于父组件的 backRef 没有获取到，导致无法获取定位
             * 为什么不能使用 setTimeout 和 requestAnimateFrame ？
             * 解答：setTimeout 和 requestAnimateFrame 触发时机不稳定，会导致与 mousePosition 的更新计数无法保持顺序
             */
            Promise.resolve().then(function () {
                _this.setState({
                    status: LazyStatus.Render,
                    transformOrigin: _this.getTransformOrigin()
                });
            });
        };
        _this.handleLazyRender = function () {
            /* do nothing */
        };
        _this.handlePopupWillEnter = function () {
            _this.props.onShow();
        };
        _this.handlePopupDidEnter = function () {
            _this.props.afterShow();
        };
        _this.handlePopupWillLeave = function () {
            _this.props.onClose();
        };
        _this.handlePopupDidLeave = function () {
            _this.props.afterClose();
        };
        _this.getPopupRef = function (node$$1) {
            _this.modalRef = node$$1;
            _this.props.popupRef(node$$1);
        };
        _this.getModalRect = function (node$$1) {
            var rect = {
                top: node$$1.offsetTop,
                left: node$$1.offsetLeft,
                width: node$$1.offsetWidth,
                height: node$$1.offsetHeight
            };
            return rect;
        };
        _this.getTransformOrigin = function () {
            var modal = _this.modalRef;
            var back = _this.props.getBackRef();
            var mousePosition = _this.props.getMousePosition();
            if (!mousePosition || !modal || !back) {
                return;
            }
            var center = _this.props.center;
            var rect = _this.getModalRect(modal);
            var x = mousePosition.x - rect.left;
            /* 这里有个BUG，center状态下有添加伪类填充，导致初始获取高度时总是在视口最下方 */
            var y = center ? mousePosition.y - (back.offsetHeight - rect.height) / 2 : mousePosition.y - rect.top;
            var origin = x + "px " + y + "px";
            return origin;
        };
        _this.state = {
            status: LazyStatus.Ready
        };
        return _this;
    }
    LazyRender.prototype.componentDidMount = function () {
        this.handleLazyReady();
    };
    LazyRender.prototype.componentWillReceiveProps = function (nextProps) {
        var visible = this.props.visible;
        if (!visible && nextProps.visible) {
            this.setState({
                status: LazyStatus.Ready
            });
        }
    };
    LazyRender.prototype.componentDidUpdate = function () {
        if (this.state.status === LazyStatus.Ready) {
            this.handleLazyReady();
        }
        if (this.state.status === LazyStatus.Render) {
            this.handleLazyRender();
        }
    };
    LazyRender.prototype.render = function () {
        var _a = this.props,
            children = _a.children,
            visible = _a.visible,
            style = _a.style,
            className = _a.className,
            animate = _a.animate,
            enterClassName = _a.enterClassName,
            leaveClassName = _a.leaveClassName;
        var transformOrigin = this.state.transformOrigin;
        return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Popup, { popupRef: this.getPopupRef, visible: visible, style: _assign({}, style, { transformOrigin: transformOrigin }), className: className, enterClassName: enterClassName, leaveClassName: leaveClassName, animate: animate, onPopupWillEnter: this.handlePopupWillEnter, onPopupDidEnter: this.handlePopupDidEnter, onPopupWillLeave: this.handlePopupWillLeave, onPopupDidLeave: this.handlePopupDidLeave }, children);
    };
    return LazyRender;
}(react__WEBPACK_IMPORTED_MODULE_0__["Component"]);

var DialogManager = /** @class */function () {
    function DialogManager() {
        var _this = this;
        this.dialogList = [];
        this.maskActive = false;
        this.active = function () {
            if (!_this.maskActive) {
                var html = document.documentElement;
                var widthWithScroll = html.offsetWidth;
                html.style.overflow = 'hidden';
                var widthNoScroll = html.offsetWidth;
                var padding = widthNoScroll - widthWithScroll;
                html.style.paddingRight = padding + 'px';
                _this.maskActive = true;
            }
        };
        this.resume = function () {
            _this.maskActive = false;
            document.documentElement.style.overflow = null;
            document.documentElement.style.paddingRight = null;
        };
        this.push = function (dialog) {
            _this.dialogList.push(dialog);
            _this.active();
        };
        this.shift = function () {
            var dialog = _this.dialogList.shift();
            if (_this.dialogList.length <= 0) {
                _this.resume();
            }
            return dialog;
        };
        this.remove = function (dialog) {
            var index = _this.dialogList.findIndex(function (symbol) {
                return dialog === symbol;
            });
            if (index !== -1) {
                _this.dialogList.splice(index, 1);
            }
            if (_this.dialogList.length <= 0) {
                _this.resume();
            }
        };
    }
    return DialogManager;
}();

var styles$9 = { "dialog-back": "dialog-back__124hPC4E", "dialog-back-active": "dialog-back-active__3VSUCnem", "dialog-back-center": "dialog-back-center__2WyGnTWZ", "dialog-mask": "dialog-mask__HgODHdX0", "dialog-mask-active": "dialog-mask-active__GaGEWk3X", "dialog-wrapper": "dialog-wrapper__2EigZaWM", "dialog-wrapper-center": "dialog-wrapper-center__3tZL5HiO", "dialog-enter": "dialog-enter__jpWTkiCW", "zoom-in": "zoom-in__2eNM9E37", "dialog-leave": "dialog-leave__2GyU_pid", "zoom-out": "zoom-out__3TtgfC4u", "dialog-content": "dialog-content__2eZqZ0kU", "dialog-close": "dialog-close__d5DV33Ag", "dialog-header": "dialog-header__2xs9AgNx", "dialog-body": "dialog-body__3jUwD84c", "dialog-footer": "dialog-footer__39x0E9GW" };

var mousePosition = null;
var Dialog = /** @class */function (_super) {
    __extends(Dialog, _super);
    function Dialog(props) {
        var _this = _super.call(this, props) || this;
        _this.backRef = null;
        _this.dialogRef = null;
        _this.getBackRef = function (node$$1) {
            _this.backRef = node$$1;
        };
        _this.getPopupRef = function (node$$1) {
            var dialogRef = _this.props.dialogRef;
            _this.dialogRef = node$$1;
            if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(dialogRef)) {
                dialogRef(node$$1);
            }
        };
        _this.toggleVisible = function (visible) {
            var _a = _this.props,
                onShow = _a.onShow,
                onClose = _a.onClose;
            if (visible) {
                Dialog.manager.push(_this);
                _this.setState({
                    back: true,
                    destory: false
                });
                onShow && onShow();
            } else {
                onClose && onClose();
            }
        };
        _this.handleCloseClick = function (e) {
            var closeble = _this.props.closeble;
            if (closeble) {
                _this.toggleVisible(false);
            }
        };
        _this.handleMaskClick = function (e) {
            var target = e.target;
            if (_this.dialogRef && _this.dialogRef.contains(target)) {
                return;
            }
            if (_this.backRef && !_this.backRef.contains(target)) {
                return;
            }
            var maskClick = _this.props.maskClick;
            if (maskClick) {
                _this.toggleVisible(false);
            }
        };
        _this.handleKeyDown = function (e) {
            if (e.keyCode !== KeyCode.Esc) {
                return;
            }
            var escCancel = _this.props.escCancel;
            if (escCancel) {
                _this.toggleVisible(false);
            }
        };
        _this.handleOkClick = function (e) {
            var onOkLoading = _this.props.onOkLoading;
            if (onOkLoading) {
                _this.setState({
                    loading: onOkLoading
                });
            }
            _this.handleButtonClick('ok', e);
        };
        _this.handleCancelClick = function (e) {
            _this.handleButtonClick('cancel', e);
        };
        _this.handleButtonClick = function (type, e) {
            var _a = _this.props,
                onOkClick = _a.onOkClick,
                onCancelClick = _a.onCancelClick;
            var mask = true;
            if (type === 'ok' && onOkClick) {
                mask = onOkClick(e);
            }
            if (type === 'cancel' && onCancelClick) {
                mask = onCancelClick(e);
            }
            if (mask instanceof Promise) {
                mask.then(function (mask) {
                    mask && _this.toggleVisible(false);
                    _this.setState({
                        loading: false
                    });
                }, function (mask) {
                    mask && _this.toggleVisible(false);
                    _this.setState({
                        loading: false
                    });
                });
            }
            if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_6__[/* default */ "a"])(mask) && mask) {
                _this.toggleVisible(false);
            }
        };
        _this.handleDialogWillEnter = function () {
            /*  */
        };
        _this.handleDialogDidEnter = function () {
            var afterShow = _this.props.afterShow;
            afterShow && afterShow();
        };
        _this.handleDialogWillLeave = function () {
            /*  */
        };
        _this.handleDialogDidLeave = function () {
            Dialog.manager.remove(_this);
            var destroyAfterClose = _this.props.destroyAfterClose;
            _this.setState({
                back: false,
                destory: destroyAfterClose
            });
            var afterClose = _this.props.afterClose;
            afterClose && afterClose();
        };
        _this.getDialogChildren = function () {
            var _a = _this.props,
                style = _a.style,
                className = _a.className,
                bodyStyle = _a.bodyStyle,
                bodyClassName = _a.bodyClassName,
                title = _a.title,
                closeble = _a.closeble;
            var classNames = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$9['dialog-content'], className);
            var titleClassName = styles$9['dialog-header'];
            var bodyClassNames = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$9['dialog-body'], bodyClassName);
            var footer = _this.getDialogFooter();
            return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-dialog-content", style: style, className: classNames }, closeble && Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("span", { "data-sel": "spark-dialog-close", className: styles$9['dialog-close'], onClick: _this.handleCloseClick }, '\xD7'), title !== null && Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-dialog-title", className: titleClassName }, title), Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-dialog-body", style: bodyStyle, className: bodyClassNames }, _this.props.children), footer);
        };
        _this.getDialogFooter = function () {
            var _a = _this.props,
                footer = _a.footer,
                okText = _a.okText,
                okProps = _a.okProps,
                cancelText = _a.cancelText,
                cancelProps = _a.cancelProps;
            var loading = _this.state.loading;
            var footerClassName = styles$9['dialog-footer'];
            if (footer === null) {
                return null;
            }
            if (footer === undefined) {
                return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-dialog-footer", className: footerClassName }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Button, _assign({ onClick: _this.handleCancelClick }, cancelProps), cancelText), Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Button, _assign({ type: "primary", onClick: _this.handleOkClick, loading: loading }, okProps), okText));
            }
            return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-dialog-footer", className: footerClassName }, footer);
        };
        var visible = props.visible,
            destroyAfterClose = props.destroyAfterClose;
        _this.state = {
            destory: visible ? false : destroyAfterClose,
            back: visible,
            loading: false
        };
        if (visible) {
            Dialog.manager.push(_this);
        }
        return _this;
    }
    Dialog.init = function () {
        var e = document.createElement('div');
        e.setAttribute('data-sel', 'spark-dialog-container');
        document.body.appendChild(e);
        Dialog.container = e;
        Dialog.manager = new DialogManager();
        window.addEventListener('click', function (e) {
            mousePosition = {
                x: e.clientX,
                y: e.clientY
            };
            /**
             * 我们认为在下次event loop中处理的Dialog显示事件是非click触发
             * 此处取两个 Frame 的时间
             */
            setTimeout(function () {
                mousePosition = null;
            }, 34);
        }, true);
    };
    Dialog.prototype.componentWillReceiveProps = function (nextProps) {
        var visible = this.props.visible;
        if (!visible && nextProps.visible) {
            this.toggleVisible(true);
        }
    };
    Dialog.prototype.shouldComponentUpdate = function (nextProps, nextState) {
        var visible = this.props.visible;
        if (!visible && !nextProps.visible && Object(lodash_es__WEBPACK_IMPORTED_MODULE_13__["default"])(this.state, nextState)) {
            return false;
        }
        return true;
    };
    Dialog.prototype.componentDidUpdate = function (prevProps, prevState) {
        var visible = this.props.visible;
        if (!prevProps.visible && visible) {
            /* focus 元素之后 keydown 事件才会生效 */
            this.backRef && this.backRef.focus();
        }
    };
    Dialog.prototype.render = function () {
        var _this = this;
        var _a, _b, _c;
        var _d = this.props,
            dialogStyle = _d.dialogStyle,
            dialogClassName = _d.dialogClassName,
            center = _d.center,
            animate = _d.animate,
            zIndex = _d.zIndex,
            width = _d.width,
            tabIndex = _d.tabIndex,
            visible = _d.visible,
            showMask = _d.showMask,
            maskStyle = _d.maskStyle;
        var _e = this.state,
            back = _e.back,
            destory = _e.destory;
        var DIALOG_WRAPPER_CENTER = styles$9['dialog-wrapper-center'];
        var wrapperClassName = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$9['dialog-wrapper'], dialogClassName, (_a = {}, _a[DIALOG_WRAPPER_CENTER] = center, _a));
        var enterClassName = styles$9['dialog-enter'];
        var leaveClassName = styles$9['dialog-leave'];
        var DIALOG_BACK_ACTIVE = styles$9['dialog-back-active'];
        var DIALOG_BACK_CENTER = styles$9['dialog-back-center'];
        var backClassName = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$9['dialog-back'], (_b = {}, _b[DIALOG_BACK_ACTIVE] = back, _b[DIALOG_BACK_CENTER] = center, _b));
        var DIALOG_MASK_AVTIVE = styles$9['dialog-mask-active'];
        var maskClassName = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$9['dialog-mask'], (_c = {}, _c[DIALOG_MASK_AVTIVE] = visible && showMask, _c));
        var children = this.getDialogChildren();
        return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Portal, { container: Dialog.container }, !destory && Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-dialog-back", ref: this.getBackRef, style: { zIndex: zIndex }, className: backClassName, tabIndex: tabIndex, onClick: this.handleMaskClick, onKeyDown: this.handleKeyDown }, showMask && Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-dialog-mask", style: visible ? maskStyle : {}, className: maskClassName }), Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(LazyRender, { popupRef: this.getPopupRef, visible: visible, style: _assign({}, dialogStyle, { width: width }), className: wrapperClassName, enterClassName: enterClassName, leaveClassName: leaveClassName, getMousePosition: function getMousePosition() {
                return mousePosition;
            }, getBackRef: function getBackRef() {
                return _this.backRef;
            }, center: center, animate: animate, onShow: this.handleDialogWillEnter, afterShow: this.handleDialogDidEnter, onClose: this.handleDialogWillLeave, afterClose: this.handleDialogDidLeave }, children)));
    };
    Dialog.propTypes = {
        children: prop_types__WEBPACK_IMPORTED_MODULE_1__["node"].isRequired,
        visible: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"].isRequired,
        dialogStyle: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
        dialogClassName: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        style: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
        className: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        bodyStyle: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
        bodyClassName: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        center: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        animate: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        zIndex: prop_types__WEBPACK_IMPORTED_MODULE_1__["number"],
        width: prop_types__WEBPACK_IMPORTED_MODULE_1__["number"],
        tabIndex: prop_types__WEBPACK_IMPORTED_MODULE_1__["number"],
        title: prop_types__WEBPACK_IMPORTED_MODULE_1__["node"],
        footer: prop_types__WEBPACK_IMPORTED_MODULE_1__["node"],
        okText: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        okProps: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
        onOkClick: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onOkLoading: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        cancelText: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        cancelProps: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
        onCancelClick: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        showMask: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        maskStyle: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
        closeble: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        maskClick: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        escCancel: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        destroyAfterClose: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        onShow: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        afterShow: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onClose: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        afterClose: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        dialogRef: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"]
    };
    Dialog.defaultProps = {
        dialogStyle: {},
        dialogClassName: '',
        style: {},
        className: '',
        bodyStyle: {},
        bodyClassName: '',
        center: false,
        animate: true,
        zIndex: 1000,
        width: 520,
        tabIndex: -1,
        title: '',
        okText: 'OK',
        onOkLoading: false,
        cancelText: 'Cancel',
        showMask: true,
        maskStyle: {},
        closeble: true,
        maskClick: true,
        escCancel: true,
        destroyAfterClose: false
    };
    __decorate([Once()], Dialog, "init", null);
    return Dialog;
}(react__WEBPACK_IMPORTED_MODULE_0__["Component"]);
Dialog.init();

/**
 * 这个组件用于控制 Dialog 的显示和影藏
 */
var Ghost = /** @class */function (_super) {
    __extends(Ghost, _super);
    function Ghost() {
        var _this = _super !== null && _super.apply(this, arguments) || this;
        _this.state = {
            visible: true
        };
        return _this;
    }
    /**
     * Close Dialog
     */
    Ghost.prototype.close = function () {
        this.setState({
            visible: false
        });
    };
    Ghost.prototype.render = function () {
        var _this = this;
        return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Dialog, _assign({}, this.props, { destroyAfterClose: true, visible: this.state.visible, onClose: function onClose() {
                _this.setState({
                    visible: false
                });
            } }), this.props.content || this.props.children);
    };
    return Ghost;
}(react__WEBPACK_IMPORTED_MODULE_0__["PureComponent"]);
var Dialog$1 = /** @class */function (_super) {
    __extends(Dialog$$1, _super);
    function Dialog$$1() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    /**
     * Toggle Dialog
     * @param props Dialog props
     */
    Dialog$$1.show = function (props) {
        var ghost = document.createElement('div');
        document.body.appendChild(ghost);
        return react_dom__WEBPACK_IMPORTED_MODULE_16___default.a.render(Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Ghost, _assign({}, props, { afterClose: function afterClose() {
                react_dom__WEBPACK_IMPORTED_MODULE_16___default.a.unmountComponentAtNode(ghost);
                document.body.removeChild(ghost);
            } })), ghost);
    };
    return Dialog$$1;
}(Dialog);

var styles$10 = { "breadcrumb": "breadcrumb__JZ41lYKt", "breadcrumb-separator": "breadcrumb-separator__3S7m8O0v" };

var BreadcrumbItem = function BreadcrumbItem(props) {
    var children = props.children,
        separator = props.separator;
    var link;
    var linkClass = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$10['breadcrumb-link']);
    var separatorClass = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$10['breadcrumb-separator']);
    if (props.hasOwnProperty('href')) {
        link = Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("a", { "data-sel": "spark-breadcrumb-link", href: props.href, className: linkClass }, children);
    } else {
        link = Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("span", { "data-sel": "spark-breadcrumb-link", className: linkClass }, children);
    }
    return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Assign, { props: props }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("span", null, link, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("span", { "data-sel": "spark-breadcrumb-separator", className: separatorClass }, separator)));
};

var Breadcrumb = /** @class */function (_super) {
    __extends(Breadcrumb, _super);
    function Breadcrumb() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    Breadcrumb.prototype.defaultItemRender = function (routes, route, paths) {
        var isLastItem = routes[routes.length - 1] === route;
        var path = paths.join('/');
        return isLastItem ? Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("span", null, route.breadcrumbName) : Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("a", { href: "#/" + path }, route.breadcrumbName);
    };
    Breadcrumb.prototype.render = function () {
        var _a = this.props,
            separator = _a.separator,
            routes = _a.routes,
            className = _a.className,
            children = _a.children,
            _b = _a.itemRender,
            itemRender = _b === void 0 ? this.defaultItemRender : _b;
        var crumbs;
        if (routes && routes.length) {
            var paths_1 = [];
            crumbs = routes.map(function (route, index) {
                var _a = route.path,
                    path = _a === void 0 ? '' : _a;
                if (path) {
                    paths_1.push(path);
                }
                return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(BreadcrumbItem, { key: index, separator: separator, className: className }, itemRender(routes, route, paths_1));
            });
        } else {
            crumbs = react__WEBPACK_IMPORTED_MODULE_0__["Children"].map(children, function (breadcrumbItem, index) {
                if (!breadcrumbItem) {
                    return null;
                }
                return Object(react__WEBPACK_IMPORTED_MODULE_0__["cloneElement"])(breadcrumbItem, {
                    key: index,
                    separator: separator,
                    className: className
                });
            });
        }
        var classNames = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$10['breadcrumb'], className);
        return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Assign, { props: this.props }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("div", { "data-sel": "spark-breadcrumb", className: classNames }, crumbs));
    };
    Breadcrumb.propTypes = {
        itemRender: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        className: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        routes: prop_types__WEBPACK_IMPORTED_MODULE_1__["array"],
        separator: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"]
    };
    Breadcrumb.Item = BreadcrumbItem;
    Breadcrumb.defaultProps = {
        separator: '/'
    };
    return Breadcrumb;
}(react__WEBPACK_IMPORTED_MODULE_0__["Component"]);

var styles$11 = { "vertical": "vertical__3DblyXep", "item-check": "item-check__3NzRIwUD", "item-check-light": "item-check-light__3tSA35ah", "item-check-dark": "item-check-dark__5-owl1Ei", "item-inline": "item-inline__uSFofi_-", "light": "light__2eCZ2jX7", "dark": "dark__1BcUv620", "item-vertical": "item-vertical__1BZVlWiR", "item-context": "item-context__3OPRd6Jy", "item-horizontal": "item-horizontal__2-EO0WoQ", "light__selected": "light__selected__2p0GjA6c", "item-disable": "item-disable__1dbTuyX5" };

/* 需要从 props 中剔除的属性 */
var EXCLUDE_ATTRS = ['id', 'mode', 'theme', 'selected', 'onItemClick', 'value'];
var Item = /** @class */function (_super) {
    __extends(Item, _super);
    function Item() {
        var _this = _super !== null && _super.apply(this, arguments) || this;
        _this.handleClick = function (e) {
            var _a = _this.props,
                id = _a.id,
                value = _a.value,
                selected = _a.selected,
                disable = _a.disable,
                onItemClick = _a.onItemClick;
            if (!disable) {
                onItemClick({
                    key: id,
                    value: value,
                    selected: selected,
                    event: e.nativeEvent
                });
            }
        };
        return _this;
    }
    Item.prototype.render = function () {
        var _a;
        var _b = this.props,
            mode = _b.mode,
            theme = _b.theme,
            className = _b.className,
            selected = _b.selected,
            disable = _b.disable;
        var ITEM_SELECTED = styles$11[theme + "__selected"];
        var ITEM_DISABLE = styles$11["item-disable"];
        var classNames = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$11["item-" + mode], styles$11[theme], className, (_a = {}, _a[ITEM_SELECTED] = selected, _a[ITEM_DISABLE] = disable, _a));
        var checkClassNames = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$11["item-check"], styles$11["item-check-" + theme]);
        /* 水平模式排版不一样，目前不显示icon */
        var checked = selected && mode !== 'horizontal' && Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("span", { "data-sel": "spark-item-check", className: checkClassNames }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Icon, { type: "check", size: 12 }));
        return Assign({
            props: Object(lodash_es__WEBPACK_IMPORTED_MODULE_14__["default"])(this.props, EXCLUDE_ATTRS),
            lib: ['Event', 'DOMAttribute'],
            exclude: [],
            children: Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("li", { "data-sel": "spark-menu-item", className: classNames, onClick: this.handleClick }, this.props.children, checked)
        });
    };
    Item.propTypes = {
        children: prop_types__WEBPACK_IMPORTED_MODULE_1__["node"],
        style: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
        className: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        value: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        disable: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"]
    };
    Item.defaultProps = {
        value: '',
        className: '',
        disable: false
    };
    return Item;
}(react__WEBPACK_IMPORTED_MODULE_0__["Component"]);

var styles$12 = { "title-inline": "title-inline__3l3Cxqju", "title-vertical": "title-vertical__W9R67Dzf", "arrow": "arrow__2JVrubBH", "light": "light__1Mr4_wcO", "light__active": "light__active__3jkworcC", "light__selected": "light__selected__1LUAfkCQ", "dark": "dark__32AWkvn5", "dark__active": "dark__active__2IUBXEfi", "dark__selected": "dark__selected__WnL4sOI_", "title-context": "title-context__3SOnSKyc", "title-disable": "title-disable__15XeyM5B", "submenu-vertical": "submenu-vertical___QuujLKX", "submenu-context": "submenu-context__Sl4yLlUn" };

var adjustPlacements = ['rightBottom', 'leftTop', 'leftBottom'];
var SubMenu = /** @class */function (_super) {
    __extends(SubMenu, _super);
    function SubMenu(props) {
        var _this = _super.call(this, props) || this;
        _this.setMouseArea = function (area) {
            _this.mouseArea = _assign({}, _this.mouseArea, area);
            if (_this.props.disable) {
                return;
            }
            setTimeout(function () {
                var _a = _this.props,
                    id = _a.id,
                    onSubmenuOpenChange = _a.onSubmenuOpenChange,
                    opened = _a.opened;
                var hover = _this.mouseArea.title || _this.mouseArea.submenu;
                if (hover && !opened) {
                    onSubmenuOpenChange({
                        opened: true,
                        key: id
                    });
                }
                if (!hover && opened) {
                    onSubmenuOpenChange({
                        opened: false,
                        key: id
                    });
                }
            }, 0);
        };
        _this.handleMouseEnter = function (e) {
            if (!_this.mouseArea.title) {
                _this.setMouseArea({
                    title: true
                });
            }
        };
        _this.handleMouseLeave = function (e) {
            _this.setMouseArea({
                title: false
            });
        };
        _this.handleSubmenuMouseEnter = function (e) {
            if (!_this.mouseArea.submenu) {
                _this.setMouseArea({
                    submenu: true
                });
            }
        };
        _this.handleSubmenuMouseLeave = function (e) {
            _this.setMouseArea({
                submenu: false
            });
        };
        _this.renderVerticalMode = function () {
            var _a;
            var _b = _this.props,
                children = _b.children,
                mode = _b.mode,
                theme = _b.theme,
                animate = _b.animate,
                adjustOverflow = _b.adjustOverflow,
                selected = _b.selected,
                opened = _b.opened,
                style = _b.style,
                className = _b.className,
                title = _b.title,
                titleStyle = _b.titleStyle,
                titleClassName = _b.titleClassName,
                disable = _b.disable,
                getSubmenuContainer = _b.getSubmenuContainer;
            var SUB_ACTIVE = styles$12[theme + "__active"];
            var SUB_SELECTED = styles$12[theme + "__selected"];
            var SUB_DISABLE = styles$12["title-disable"];
            var titleClassNames = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$12["title-" + mode], styles$12[theme], titleClassName, (_a = {}, _a[SUB_ACTIVE] = opened, _a[SUB_SELECTED] = selected, _a[SUB_DISABLE] = disable, _a));
            var arrowClassName = styles$12['arrow'];
            var submenuClassNames = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$12["submenu-" + mode], styles$12[theme], className);
            var gap = theme === 'light' ? 6 : 5;
            return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Popover, { content: children, placement: "rightTop", adjustOverflow: adjustOverflow, style: style, className: submenuClassNames, gap: gap, arrow: false, animate: animate, visible: opened, onPopoverMouseEnter: _this.handleSubmenuMouseEnter, onPopoverMouseLeave: _this.handleSubmenuMouseLeave, disable: disable, getContainer: getSubmenuContainer }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("li", { "data-sel": "spark-submenu", style: titleStyle, className: titleClassNames, onMouseEnter: _this.handleMouseEnter, onMouseLeave: _this.handleMouseLeave }, title, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("span", { "data-sel": "spark-submenu-arrow", className: arrowClassName }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Icon, { type: "arrow-right", size: 10 }))));
        };
        _this.renderContextMode = function () {
            var _a;
            var _b = _this.props,
                children = _b.children,
                mode = _b.mode,
                theme = _b.theme,
                adjustOverflow = _b.adjustOverflow,
                selected = _b.selected,
                opened = _b.opened,
                style = _b.style,
                className = _b.className,
                title = _b.title,
                titleStyle = _b.titleStyle,
                titleClassName = _b.titleClassName,
                disable = _b.disable,
                submenuRef = _b.submenuRef,
                getSubmenuContainer = _b.getSubmenuContainer;
            var SUB_ACTIVE = styles$12[theme + "__active"];
            var SUB_SELECTED = styles$12[theme + "__selected"];
            var SUB_DISABLE = styles$12["title-disable"];
            var titleClassNames = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$12["title-" + mode], styles$12[theme], titleClassName, (_a = {}, _a[SUB_ACTIVE] = opened, _a[SUB_SELECTED] = selected, _a[SUB_DISABLE] = disable, _a));
            var arrowClassName = styles$12['arrow'];
            var submenuClassNames = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$12["submenu-" + mode], styles$12[theme], className);
            var gap = theme === 'light' ? 6 : 5; // light 模式有 1px 外层边框
            return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Popover, { content: children, placement: "rightTop", adjustOverflow: adjustOverflow, adjustPlacements: adjustPlacements, style: style, className: submenuClassNames, gap: gap, arrow: false, visible: opened, animate: false, onPopoverMouseEnter: _this.handleSubmenuMouseEnter, onPopoverMouseLeave: _this.handleSubmenuMouseLeave, disable: disable, popoverRef: submenuRef, getContainer: getSubmenuContainer }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("li", { "data-sel": "spark-submenu", style: titleStyle, className: titleClassNames, onMouseEnter: _this.handleMouseEnter, onMouseLeave: _this.handleMouseLeave }, title, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("span", { "data-sel": "spark-submenu-arrow", className: arrowClassName }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Icon, { type: "arrow-right", size: 10 }))));
        };
        _this.mouseArea = {
            title: false,
            submenu: false
        };
        return _this;
    }
    SubMenu.prototype.render = function () {
        var mode = this.props.mode;
        if (mode === 'inline') {
            console.warn('目前 SubMenu 仅支持 vertical 和 context 模式，inline 和 horizontal 模式将在后续支持。');
            return null;
        }
        if (mode === 'vertical') {
            return this.renderVerticalMode();
        }
        if (mode === 'context') {
            return this.renderContextMode();
        }
        if (mode === 'horizontal') {
            console.warn('目前 SubMenu 仅支持 vertical 和 context 模式，inline 和 horizontal 模式将在后续支持。');
            return null;
        }
        return null;
    };
    SubMenu.propTypes = {
        children: prop_types__WEBPACK_IMPORTED_MODULE_1__["node"],
        style: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
        className: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        title: prop_types__WEBPACK_IMPORTED_MODULE_1__["node"],
        titleStyle: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
        titleClassName: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        disable: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"]
    };
    SubMenu.defaultProps = {
        className: '',
        titleClassName: '',
        disable: false
    };
    return SubMenu;
}(react__WEBPACK_IMPORTED_MODULE_0__["Component"]);

var styles$13 = { "divider-vertical": "divider-vertical__1uRc-on0", "light": "light__3SuSUmZq", "dark": "dark__pc2SV9Hq", "divider-context": "divider-context__2KbjYlYe" };

var Divider = function Divider(props) {
    var mode = props.mode,
        theme = props.theme,
        style = props.style,
        className = props.className;
    var classNames = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$13["divider-" + mode], styles$13[theme], className);
    return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("li", { "data-sel": "spark-menu-divider", style: style, className: classNames }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("hr", null));
};

var styles$14 = { "menu-horizontal": "menu-horizontal__1eqsprS0", "light": "light__3z5Hhf2K", "menu-vertical": "menu-vertical__t0eH5x8x", "dark": "dark__3BZw29VD", "menu-inline": "menu-inline__1BMYIb_F", "menu-context": "menu-context__HGf6zKCW" };

var _typeof$1 = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) { return typeof obj; } : function (obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; };

var Menu = /** @class */function (_super) {
    __extends(Menu, _super);
    function Menu(props) {
        var _this = _super.call(this, props) || this;
        _this.node = null;
        _this.submenuMap = new Map();
        /**
         * Menu 是否包含了此元素
         */
        _this.contains = function (e) {
            if (_this.node && _this.node.contains(e)) {
                return true;
            }
            var submenus = Array.from(_this.submenuMap.values()); // ts编译不支持枚举Map
            for (var _i = 0, submenus_1 = submenus; _i < submenus_1.length; _i++) {
                var node$$1 = submenus_1[_i];
                if (node$$1 instanceof HTMLElement && node$$1.contains(e)) {
                    return true;
                }
            }
            return false;
        };
        _this.handleSubmenuOpenChange = function (opts) {
            var _a;
            var key = opts.key,
                opened = opts.opened;
            var _b = _this.props,
                onSubmenuOpenChange = _b.onSubmenuOpenChange,
                submenuOpenKeys = _b.submenuOpenKeys;
            if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(onSubmenuOpenChange)) {
                onSubmenuOpenChange(opts);
            }
            /* 若参数中显示存在 submenuOpenKeys，则不执行默认操作 */
            if (Array.isArray(submenuOpenKeys)) {
                return;
            }
            if (!Object(lodash_es__WEBPACK_IMPORTED_MODULE_9__["default"])(key) && !Object(lodash_es__WEBPACK_IMPORTED_MODULE_15__["default"])(key)) {
                return;
            }
            var openedMenu = _this.state.openedMenu;
            _this.setState({
                openedMenu: _assign({}, openedMenu, (_a = {}, _a[key] = opened, _a))
            });
        };
        _this.handleItemClick = function (opts) {
            var _a = _this.props,
                onItemClick = _a.onItemClick,
                selectable = _a.selectable,
                deselectable = _a.deselectable;
            if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(onItemClick)) {
                onItemClick(opts);
            }
            var key = opts.key,
                selected = opts.selected,
                value = opts.value;
            if (!Object(lodash_es__WEBPACK_IMPORTED_MODULE_9__["default"])(key) && !Object(lodash_es__WEBPACK_IMPORTED_MODULE_15__["default"])(key)) {
                return;
            }
            if (selected && deselectable) {
                _this.handleSelect(key, value, false);
            }
            if (!selected && selectable) {
                _this.handleSelect(key, value, true);
            }
        };
        _this.handleSelect = function (key, value, selected) {
            var _a, _b;
            var _c = _this.props,
                multiple = _c.multiple,
                selectedKeys = _c.selectedKeys,
                onChange = _c.onChange;
            if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(onChange)) {
                onChange({
                    key: key,
                    value: value,
                    selected: selected
                });
            }
            /* 若参数中显示存在 selectedKeys，则不执行默认操作 */
            if (Array.isArray(selectedKeys)) {
                return;
            }
            var selectedMap = _this.state.selectedMap;
            if (multiple) {
                _this.setState({
                    selectedMap: _assign({}, selectedMap, (_a = {}, _a[key] = selected, _a))
                });
            } else {
                _this.setState({
                    selectedMap: (_b = {}, _b[key] = selected, _b)
                });
            }
        };
        _this.isSelected = function (key) {
            if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_9__["default"])(key) || Object(lodash_es__WEBPACK_IMPORTED_MODULE_15__["default"])(key)) {
                return !!_this.state.selectedMap[key];
            }
            return false;
        };
        _this.isOpened = function (key) {
            if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_9__["default"])(key) || Object(lodash_es__WEBPACK_IMPORTED_MODULE_15__["default"])(key)) {
                return !!_this.state.openedMenu[key];
            }
            return false;
        };
        /**
         * 给 Item 组件注入参数
         *
         * @param {Item} item Item element
         * @param {MapOptions} opts Item 子树的状态
         */
        _this.injectPropsToItem = function (item, opts) {
            var key = item.key;
            var selected = _this.isSelected(key);
            var _a = _this.props,
                mode = _a.mode,
                theme = _a.theme;
            return _assign({}, item.props, { mode: mode, theme: theme, selected: selected, onItemClick: _this.handleItemClick, id: key });
        };
        /**
         * 给 SubMenu 组件注入参数
         *
         * @param {SubMenu} submenu submenu element
         * @param {MapOptions} opts submenu 子树的状态
         */
        _this.injectPropsToSubmenu = function (submenu, opts) {
            var key = submenu.key;
            var opened = _this.isOpened(key);
            var _a = _this.props,
                mode = _a.mode,
                theme = _a.theme,
                animate = _a.animate,
                adjustOverflow = _a.adjustOverflow,
                getSubmenuContainer = _a.getSubmenuContainer;
            return _assign({}, submenu.props, { mode: mode, theme: theme, animate: animate, selected: opts.selected, opened: opened || opts.opened, onSubmenuOpenChange: _this.handleSubmenuOpenChange, id: key, submenuRef: function submenuRef(node$$1) {
                    _this.submenuMap.set(key, node$$1);
                }, adjustOverflow: adjustOverflow, getSubmenuContainer: getSubmenuContainer });
        };
        /**
        * 给 Divider 组件注入参数
        *
        * @param {Divider} divider
        * @param {MapOptions} opts 子树的状态
        */
        _this.injectPropsToDivider = function (divider, opts) {
            var key = divider.key;
            var _a = _this.props,
                mode = _a.mode,
                theme = _a.theme;
            return _assign({}, divider.props, { mode: mode, theme: theme, id: key });
        };
        var _a = _this.props,
            multiple = _a.multiple,
            selectedKeys = _a.selectedKeys,
            defaultSelectedKeys = _a.defaultSelectedKeys,
            submenuOpenKeys = _a.submenuOpenKeys,
            defaultSubmenuOpenKeys = _a.defaultSubmenuOpenKeys,
            selectable = _a.selectable;
        var selectedMap = {};
        var itemKeys = selectedKeys || defaultSelectedKeys || [];
        if (selectable) {
            itemKeys.forEach(function (key) {
                if (!Object(lodash_es__WEBPACK_IMPORTED_MODULE_9__["default"])(key) && !Object(lodash_es__WEBPACK_IMPORTED_MODULE_15__["default"])(key)) {
                    console.warn("The item's key must be a string or a number, but recieve: " + (typeof key === 'undefined' ? 'undefined' : _typeof$1(key)));
                    return;
                }
                if (!multiple && Object.keys(selectedMap).length >= 1) {
                    return;
                }
                selectedMap[key] = true;
            });
        }
        var openedMenu = {};
        var submenuKeys = submenuOpenKeys || defaultSubmenuOpenKeys || [];
        submenuKeys.forEach(function (key) {
            if (!Object(lodash_es__WEBPACK_IMPORTED_MODULE_9__["default"])(key) && !Object(lodash_es__WEBPACK_IMPORTED_MODULE_15__["default"])(key)) {
                console.warn("The item's key must be a string or a number, but recieve: " + (typeof key === 'undefined' ? 'undefined' : _typeof$1(key)));
                return;
            }
            openedMenu[key] = true;
        });
        _this.state = {
            selectedMap: selectedMap,
            openedMenu: openedMenu
        };
        return _this;
    }
    Menu.prototype.componentWillReceiveProps = function (nextProps) {
        var multiple = nextProps.multiple,
            selectedKeys = nextProps.selectedKeys,
            selectable = nextProps.selectable,
            submenuOpenKeys = nextProps.submenuOpenKeys;
        /* 若显示存在 selectedKeys 则使用显示声明的 keys */
        if (Array.isArray(selectedKeys) && selectable) {
            var selectedMap_1 = {};
            selectedKeys.forEach(function (key) {
                if (!Object(lodash_es__WEBPACK_IMPORTED_MODULE_9__["default"])(key) && !Object(lodash_es__WEBPACK_IMPORTED_MODULE_15__["default"])(key)) {
                    console.warn("The item's key must be a string or a number, but recieve: " + (typeof key === 'undefined' ? 'undefined' : _typeof$1(key)));
                    return;
                }
                if (!multiple && Object.keys(selectedMap_1).length >= 1) {
                    return;
                }
                selectedMap_1[key] = true;
            });
            this.setState({
                selectedMap: selectedMap_1
            });
        }
        /* 若显示存在 submenuOpenKeys 则使用显示声明的 keys */
        if (Array.isArray(submenuOpenKeys)) {
            var openedMenu_1 = {};
            submenuOpenKeys.forEach(function (key) {
                if (!Object(lodash_es__WEBPACK_IMPORTED_MODULE_9__["default"])(key) && !Object(lodash_es__WEBPACK_IMPORTED_MODULE_15__["default"])(key)) {
                    console.warn("The item's key must be a string or a number, but recieve: " + (typeof key === 'undefined' ? 'undefined' : _typeof$1(key)));
                    return;
                }
                openedMenu_1[key] = true;
            });
            this.setState({
                openedMenu: openedMenu_1
            });
        }
    };
    /**
     * Menu 组件的递归核心，层序遍历子组件树，处理所有的 Item 组件并且返回一份 copy.
     * 若子树中存在 selected 或 opened 的子节点，那么该节点也同样拥有这些激活属性。
     *
     * @param children Menu 组件的 children
     * @returns 子树遍历的结果
     */
    Menu.prototype.deepMapChlidren = function (children) {
        if (Array.isArray(children)) {
            var cloneChildren = [];
            var opened = false;
            var selected = false;
            for (var index = 0; index < children.length; index++) {
                var e = children[index];
                var opts = this.deepMapChlidren(e);
                selected = selected || opts.selected; // 若子树中selected为true，那么此节点也为true
                opened = opened || opts.opened; // 若子树中opened为true，那么此节点也为true
                cloneChildren.push(opts.children);
            }
            return {
                children: cloneChildren,
                selected: selected,
                opened: opened
            };
        }
        if (Object(react__WEBPACK_IMPORTED_MODULE_0__["isValidElement"])(children)) {
            var deepChildren = children.props.children;
            var deepOpts = this.deepMapChlidren(deepChildren);
            var cloneDeepChildren = deepOpts.children,
                selected = deepOpts.selected,
                opened = deepOpts.opened;
            if (children.type === Item) {
                var props = this.injectPropsToItem(children, deepOpts);
                return {
                    children: Object(react__WEBPACK_IMPORTED_MODULE_0__["cloneElement"])(children, props, cloneDeepChildren),
                    selected: props.selected,
                    opened: opened
                };
            }
            if (children.type === SubMenu) {
                var props = this.injectPropsToSubmenu(children, deepOpts);
                return {
                    children: Object(react__WEBPACK_IMPORTED_MODULE_0__["cloneElement"])(children, props, cloneDeepChildren),
                    selected: props.selected,
                    opened: props.opened
                };
            }
            if (children.type === Divider) {
                var props = this.injectPropsToDivider(children, deepOpts);
                return {
                    children: Object(react__WEBPACK_IMPORTED_MODULE_0__["cloneElement"])(children, props, cloneDeepChildren),
                    selected: selected,
                    opened: opened
                };
            }
            return {
                children: Object(react__WEBPACK_IMPORTED_MODULE_0__["cloneElement"])(children, children.props, cloneDeepChildren),
                selected: selected,
                opened: opened
            };
        }
        return {
            children: children,
            selected: false,
            opened: false
        };
    };
    Menu.prototype.render = function () {
        var _this = this;
        var _a = this.props,
            children = _a.children,
            style = _a.style,
            className = _a.className,
            mode = _a.mode,
            theme = _a.theme;
        var classNames = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$14["menu-" + mode], styles$14["" + theme], className);
        var renderChildren = this.deepMapChlidren(children).children;
        return Assign({
            props: this.props,
            lib: ['Event', 'DOMAttribute'],
            children: Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])("ul", { "data-sel": "spark-menu", style: style, className: classNames, ref: function ref(e) {
                    return _this.node = e;
                } }, renderChildren)
        });
    };
    Menu.propTypes = {
        children: prop_types__WEBPACK_IMPORTED_MODULE_1__["node"].isRequired,
        style: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
        className: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        mode: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["oneOf"])(['inline', 'vertical', 'horizontal', 'context']),
        theme: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["oneOf"])(['light', 'dark']),
        animate: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        adjustOverflow: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["oneOfType"])([prop_types__WEBPACK_IMPORTED_MODULE_1__["array"], prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"]]),
        multiple: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        selectable: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        deselectable: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        selectedKeys: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["arrayOf"])(Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["oneOfType"])([prop_types__WEBPACK_IMPORTED_MODULE_1__["string"], prop_types__WEBPACK_IMPORTED_MODULE_1__["number"]])),
        defaultSelectedKeys: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["arrayOf"])(Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["oneOfType"])([prop_types__WEBPACK_IMPORTED_MODULE_1__["string"], prop_types__WEBPACK_IMPORTED_MODULE_1__["number"]])),
        submenuOpenKeys: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["arrayOf"])(Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["oneOfType"])([prop_types__WEBPACK_IMPORTED_MODULE_1__["string"], prop_types__WEBPACK_IMPORTED_MODULE_1__["number"]])),
        defaultSubmenuOpenKeys: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["arrayOf"])(Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["oneOfType"])([prop_types__WEBPACK_IMPORTED_MODULE_1__["string"], prop_types__WEBPACK_IMPORTED_MODULE_1__["number"]])),
        onItemClick: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onChange: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        onSubmenuOpenChange: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        getSubmenuContainer: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"]
    };
    Menu.defaultProps = {
        className: '',
        mode: 'vertical',
        theme: 'light',
        animate: true,
        adjustOverflow: true,
        multiple: false,
        selectable: true,
        deselectable: false
    };
    Menu.Item = Item;
    Menu.SubMenu = SubMenu;
    Menu.Divider = Divider;
    return Menu;
}(react__WEBPACK_IMPORTED_MODULE_0__["Component"]);

var styles$15 = { "popup": "popup__BpsUHsg2", "light": "light__e370DUbl", "dark": "dark__2H3BKayB", "show": "show__2ekt90S8", "fade-in": "fade-in__2zNFaDKa", "hide": "hide__3OIN08xz", "fade-out": "fade-out__2y4ixhL5" };

var placements$1 = {
    bottomRight: {
        enterClassName: styles$15['show'],
        leaveClassName: styles$15['hide']
    },
    bottomLeft: {
        enterClassName: styles$15['show'],
        leaveClassName: styles$15['hide']
    },
    topRight: {
        enterClassName: styles$15['show'],
        leaveClassName: styles$15['hide']
    },
    topLeft: {
        enterClassName: styles$15['show'],
        leaveClassName: styles$15['hide']
    }
};

var AlignStatus$1;
(function (AlignStatus) {
    /* 预渲染完成 */
    AlignStatus[AlignStatus["READY"] = 1] = "READY";
    /* 渲染完成 */
    AlignStatus[AlignStatus["RENDER"] = 2] = "RENDER";
})(AlignStatus$1 || (AlignStatus$1 = {}));
var LazyAlign$2 = /** @class */function (_super) {
    __extends(LazyAlign, _super);
    function LazyAlign(props) {
        var _this = _super.call(this, props) || this;
        _this.popupNode = null;
        _this.getPopupRef = function (ref) {
            var popupRef = _this.props.popupRef;
            _this.popupNode = ref;
            if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(popupRef)) {
                popupRef(ref);
            }
        };
        _this.handleLazyReady = function (prevProps, prevState) {
            var popup = _this.popupNode;
            var _a = _this.props,
                point = _a.point,
                adjustOverflow = _a.adjustOverflow,
                getContainer = _a.getContainer,
                placements$$1 = _a.placements,
                didAlign = _a.didAlign,
                visible = _a.visible,
                onVisibleChange = _a.onVisibleChange;
            var container = getContainer();
            if (!popup || !container) {
                return;
            }
            var _b = _this.getPosition(placements$$1, adjustOverflow, popup, container, point),
                placement = _b.placement,
                rect = _b.rect;
            _this.setState({
                placement: placement,
                position: {
                    top: rect.top,
                    left: rect.left
                },
                status: AlignStatus$1.RENDER
            });
            if (visible && !prevProps.visible && Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(onVisibleChange)) {
                onVisibleChange(true);
            }
            if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(didAlign)) {
                didAlign(placement, rect);
            }
        };
        _this.handleLazyRender = function (prevProps, prevState) {
            var _a = _this.props,
                onVisibleChange = _a.onVisibleChange,
                visible = _a.visible;
            if (!visible && prevProps.visible && Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(onVisibleChange)) {
                onVisibleChange(false);
            }
        };
        _this.getPosition = function (placements$$1, adjustOverflow, node$$1, container, point) {
            var firstPlacement = placements$$1[0];
            var shape = _this.getNodeRect(node$$1);
            /* 搜索可用定位 */
            if (adjustOverflow) {
                for (var _i = 0, placements_1 = placements$$1; _i < placements_1.length; _i++) {
                    var placement = placements_1[_i];
                    var rect_1 = getRectFromPoint(placement, shape, container, point);
                    if (!_this.isOverflow(rect_1, container)) {
                        return {
                            placement: placement,
                            rect: rect_1
                        };
                    }
                }
            }
            /* 若无适应的定位，或不自适应，则返回第一个位置 */
            var rect = getRectFromPoint(firstPlacement, shape, container, point);
            return {
                placement: firstPlacement,
                rect: rect
            };
        };
        _this.getNodeRect = function (node$$1) {
            return {
                width: node$$1.offsetWidth,
                height: node$$1.offsetHeight
            };
        };
        _this.isOverflow = function (rect, container) {
            var adjustOverflow = _this.props.adjustOverflow;
            var checker = [];
            if (Array.isArray(adjustOverflow)) {
                checker = adjustOverflow;
            } else {
                checker = [adjustOverflow];
            }
            var adjust = checker[0],
                viewport = checker[1];
            if (adjust) {
                return viewport === 'check-viewport' ? isOverflow(rect, container, true) : isOverflow(rect);
            }
            return false;
        };
        var point = props.point;
        _this.state = {
            status: AlignStatus$1.READY,
            placement: props.placements[0],
            position: {
                top: point.y,
                left: point.x
            },
            enterClassName: '',
            leaveClassName: ''
        };
        return _this;
    }
    LazyAlign.prototype.componentDidMount = function () {
        this.handleLazyReady(this.props, this.state);
    };
    LazyAlign.prototype.componentWillReceiveProps = function (nextProps) {
        if (nextProps.visible) {
            this.setState({
                status: AlignStatus$1.READY
            });
        }
    };
    LazyAlign.prototype.shouldComponentUpdate = function (nextProps) {
        /* 当组件完全不显示时则不更新，以优化渲染性能 */
        if (!this.props.visible && !nextProps.visible) {
            return false;
        }
        return true;
    };
    LazyAlign.prototype.componentDidUpdate = function (prevProps, prevState) {
        if (this.state.status === AlignStatus$1.READY) {
            this.handleLazyReady(prevProps, prevState);
            return;
        }
        if (this.state.status === AlignStatus$1.RENDER) {
            this.handleLazyRender(prevProps, prevState);
            return;
        }
    };
    LazyAlign.prototype.render = function () {
        var _a = this.props,
            visible = _a.visible,
            style = _a.style,
            className = _a.className,
            animate = _a.animate,
            onClick = _a.onClick,
            onContextMenu = _a.onContextMenu,
            onMouseEnter = _a.onMouseEnter,
            onMouseLeave = _a.onMouseLeave,
            destroyAfterClose = _a.destroyAfterClose,
            children = _a.children;
        var _b = this.state,
            status = _b.status,
            placement = _b.placement,
            position = _b.position;
        var top = position.top,
            left = position.left; // 只取top和left
        var _c = placements$1[placement],
            enterClassName = _c.enterClassName,
            leaveClassName = _c.leaveClassName;
        var visibility = status === AlignStatus$1.RENDER ? undefined : 'hidden';
        return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Popup, { popupRef: this.getPopupRef, visible: visible, style: _assign({}, style, { top: top,
                left: left,
                visibility: visibility }), className: className, animate: animate, enterClassName: enterClassName, leaveClassName: leaveClassName, onClick: onClick, onContextMenu: onContextMenu, onMouseEnter: onMouseEnter, onMouseLeave: onMouseLeave, destroyAfterLeave: destroyAfterClose }, children);
    };
    return LazyAlign;
}(react__WEBPACK_IMPORTED_MODULE_0__["Component"]);

var SubMenu$2 = Menu.SubMenu;
var Item$2 = Menu.Item;
var Divider$2 = Menu.Divider;
var ContextMenu = /** @class */function (_super) {
    __extends(ContextMenu, _super);
    function ContextMenu(props) {
        var _this = _super.call(this, props) || this;
        _this.contextNode = null;
        _this.popupNode = null;
        _this.menu = null;
        _this.contextMenuItems = [];
        _this.content = null;
        _this.timer = -999999;
        _this.getContainer = function () {
            var getContainer = _this.props.getContainer;
            var node$$1 = Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(getContainer) && getContainer();
            if (node$$1 instanceof HTMLElement) {
                return node$$1;
            }
            if (_this.contextNode) {
                return _this.contextNode;
            }
            return ContextMenu.container;
        };
        /**
         * Get Children 逻辑：若参数为一个回调，则返回由 ContextMenu 事件触发后获取的 Children，
         * 否则直接返回参数中的内容.
         */
        _this.getChildren = function () {
            var _a = _this.props,
                content = _a.content,
                items = _a.items,
                theme = _a.theme,
                animate = _a.animate,
                adjustOverflow = _a.adjustOverflow,
                menuProps = _a.menuProps;
            /* 若存在content，则优先返回content */
            if (!Object(lodash_es__WEBPACK_IMPORTED_MODULE_4__["default"])(content)) {
                return Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(content) ? _this.content : content;
            }
            /* 若不存在content，则返回items */
            if (!Object(lodash_es__WEBPACK_IMPORTED_MODULE_4__["default"])(items)) {
                var contextMenuItems = Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(items) ? _this.contextMenuItems : items;
                return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Menu, _assign({ adjustOverflow: adjustOverflow, mode: "context", theme: theme, animate: animate, ref: function ref(e) {
                        _this.menu = e;
                    }, getSubmenuContainer: _this.getContainer }, menuProps), contextMenuItems.map(function (item) {
                    if (item) {
                        return _this.mapItem(item);
                    }
                    return null;
                }));
            }
            console.error('Warning: ContextMenu must have content or items props!');
            return null;
        };
        _this.getContent = function (e) {
            var content = _this.props.content;
            if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(content)) {
                return content(e);
            }
            return null;
        };
        _this.getContextMenuItems = function (e) {
            var items = _this.props.items;
            if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(items)) {
                return items(e) || [];
            }
            return [];
        };
        _this.mapItem = function (item) {
            if (item.type === 'item') {
                return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Item$2, { key: item.key, value: item.value, disable: item.disable, style: item.style, className: item.className }, item.text);
            }
            if (item.type === 'divider') {
                return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Divider$2, { key: item.key, style: item.style, className: item.className }, item.text);
            }
            if (item.type === 'submenu') {
                return Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(SubMenu$2, { key: item.key, disable: item.disable, title: item.text, titleStyle: item.style, titleClassName: item.className }, item.children && item.children.map(function (item) {
                    return _this.mapItem(item);
                }));
            }
            return null;
        };
        _this.getPopupRef = function (popup) {
            var contextMenuRef = _this.props.contextMenuRef;
            if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(contextMenuRef)) {
                contextMenuRef(popup);
            }
            _this.popupNode = popup;
        };
        _this.toggleVisible = function (visible, wait, point) {
            if (point === void 0) {
                point = _this.state.point;
            }
            clearTimeout(_this.timer);
            var disable = _this.props.disable;
            if (disable) {
                return;
            }
            if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_15__["default"])(wait) && wait > 0) {
                _this.timer = setTimeout(function () {
                    _this.setState({
                        visible: visible,
                        point: point
                    });
                }, wait);
                return;
            }
            _this.setState({
                visible: visible,
                point: point
            });
        };
        _this.handleWindowMouseDown = function (e) {
            var visible = _this.state.visible;
            var wait = _this.props.hideDelay;
            var content = _this.props.content;
            var node$$1 = _this.popupNode;
            var menu = _this.menu;
            if (!visible || !node$$1 || node$$1.contains(e.target)) {
                return;
            }
            /* 自定义content模式 */
            if (!Object(lodash_es__WEBPACK_IMPORTED_MODULE_4__["default"])(content)) {
                _this.toggleVisible(false, wait);
                return;
            }
            /* 默认menu模式 */
            if (menu && !menu.contains(e.target)) {
                _this.toggleVisible(false, wait);
            }
        };
        _this.handleContextMenu = function (e) {
            var node$$1 = _this.contextNode;
            var container = _this.getContainer();
            var _a = _this.props,
                showDelay = _a.showDelay,
                disable = _a.disable;
            if (disable || !node$$1 || !container) {
                return;
            }
            var event = e.nativeEvent;
            var clientRect = node$$1.getBoundingClientRect();
            var x = event.clientX - clientRect.left;
            var y = event.clientY - clientRect.top;
            /* 若trigger等于container，则计算滚动距离 */
            if (node$$1 === container) {
                x = x + node$$1.scrollLeft;
                y = y + node$$1.scrollTop;
            } else {
                /* 否则计算文档流距离 */
                var absRect = getAbsNodeRect(node$$1, container);
                x = x + absRect.left;
                y = y + absRect.top;
            }
            var point = new Point({
                screenX: event.screenX,
                screenY: event.screenY,
                clientX: event.clientX,
                clientY: event.clientY,
                pageX: event.pageX,
                pageY: event.pageY,
                offsetX: event.offsetX,
                offsetY: event.offsetY,
                layerX: event.layerX,
                layerY: event.layerY,
                x: x,
                y: y
            });
            _this.content = _this.getContent(event);
            _this.contextMenuItems = _this.getContextMenuItems(event);
            _this.toggleVisible(true, showDelay, point);
            e.preventDefault();
        };
        _this.handlePopupContextMenu = function (e) {
            e.preventDefault();
        };
        _this.state = {
            visible: false,
            point: new Point()
        };
        return _this;
    }
    ContextMenu.init = function () {
        var e = document.createElement('div');
        e.setAttribute('data-sel', 'spark-contextmenu-container');
        ContextMenu.container = e;
        document.body.appendChild(e);
        window.addEventListener('mousedown', function (e) {
            ContextMenu.eventHandlers.forEach(function (v, k) {
                v(e);
            });
        }, true);
    };
    ContextMenu.prototype.componentDidMount = function () {
        var node$$1 = Object(react_dom__WEBPACK_IMPORTED_MODULE_16__["findDOMNode"])(this);
        if (node$$1 instanceof HTMLElement) {
            this.contextNode = node$$1;
        }
        ContextMenu.eventHandlers.set(this, this.handleWindowMouseDown);
        var toggleRef = this.props.toggleRef;
        if (Object(lodash_es__WEBPACK_IMPORTED_MODULE_3__["default"])(toggleRef)) {
            var show = this.toggleVisible.bind(this, true, 0);
            var hide = this.toggleVisible.bind(this, false, 0);
            toggleRef(show, hide);
        }
    };
    ContextMenu.prototype.componentDidUpdate = function () {
        var node$$1 = Object(react_dom__WEBPACK_IMPORTED_MODULE_16__["findDOMNode"])(this);
        if (node$$1 instanceof HTMLElement) {
            this.contextNode = node$$1;
        }
    };
    ContextMenu.prototype.componentWillUnmount = function () {
        ContextMenu.eventHandlers.delete(this);
    };
    ContextMenu.prototype.render = function () {
        var _a = this.props,
            children = _a.children,
            style = _a.style,
            className = _a.className,
            theme = _a.theme,
            zIndex = _a.zIndex,
            adjustOverflow = _a.adjustOverflow,
            animate = _a.animate,
            onVisibleChange = _a.onVisibleChange,
            didAlign = _a.didAlign,
            destroyAfterClose = _a.destroyAfterClose;
        var _b = this.state,
            visible = _b.visible,
            point = _b.point;
        var classNames = classnames__WEBPACK_IMPORTED_MODULE_2___default()(styles$15['popup'], styles$15["" + theme], className);
        var contextMenuChildren = this.getChildren();
        var container = this.getContainer();
        return [Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Assign, { key: "trigger", props: {
                onContextMenu: this.handleContextMenu
            }, lib: ['Event'] }, children), Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(Portal, { key: "contextmenu", container: container }, Object(react__WEBPACK_IMPORTED_MODULE_0__["createElement"])(LazyAlign$2, { popupRef: this.getPopupRef, visible: visible, placements: contextMenuPlacements, style: _assign({}, style, { zIndex: zIndex }), className: classNames, point: point, adjustOverflow: adjustOverflow, animate: animate, onVisibleChange: onVisibleChange, didAlign: didAlign, onContextMenu: this.handlePopupContextMenu, getContainer: this.getContainer, destroyAfterClose: destroyAfterClose }, contextMenuChildren))];
    };
    ContextMenu.propTypes = {
        children: prop_types__WEBPACK_IMPORTED_MODULE_1__["node"].isRequired,
        content: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["oneOfType"])([prop_types__WEBPACK_IMPORTED_MODULE_1__["node"], prop_types__WEBPACK_IMPORTED_MODULE_1__["func"]]),
        items: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["oneOfType"])([prop_types__WEBPACK_IMPORTED_MODULE_1__["array"], prop_types__WEBPACK_IMPORTED_MODULE_1__["func"]]),
        theme: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["oneOf"])(['light', 'dark']),
        menuProps: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
        adjustOverflow: Object(prop_types__WEBPACK_IMPORTED_MODULE_1__["oneOfType"])([prop_types__WEBPACK_IMPORTED_MODULE_1__["array"], prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"]]),
        style: prop_types__WEBPACK_IMPORTED_MODULE_1__["object"],
        className: prop_types__WEBPACK_IMPORTED_MODULE_1__["string"],
        zIndex: prop_types__WEBPACK_IMPORTED_MODULE_1__["number"],
        showDelay: prop_types__WEBPACK_IMPORTED_MODULE_1__["number"],
        hideDelay: prop_types__WEBPACK_IMPORTED_MODULE_1__["number"],
        onVisibleChange: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        didAlign: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        disable: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        animate: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        destroyAfterClose: prop_types__WEBPACK_IMPORTED_MODULE_1__["bool"],
        contextMenuRef: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        toggleRef: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"],
        getContainer: prop_types__WEBPACK_IMPORTED_MODULE_1__["func"]
    };
    ContextMenu.defaultProps = {
        menuProps: {},
        adjustOverflow: true,
        style: {},
        className: '',
        zIndex: 998,
        showDelay: 0,
        hideDelay: 0,
        disable: false,
        animate: true
    };
    ContextMenu.eventHandlers = new Map();
    __decorate([Once()], ContextMenu, "init", null);
    return ContextMenu;
}(react__WEBPACK_IMPORTED_MODULE_0__["Component"]);
ContextMenu.init();

/* General */


//# sourceMappingURL=index.js.map


/***/ })

}]);
//# sourceMappingURL=https://s3.pstatp.com/eesz/resource/bear/js/vendors~docs~mindnote.98a956dd48cb8de0ecdc.js.map