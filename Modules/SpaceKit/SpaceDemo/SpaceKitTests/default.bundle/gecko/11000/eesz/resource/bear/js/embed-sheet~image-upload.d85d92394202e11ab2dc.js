(window["webpackJsonp"] = window["webpackJsonp"] || []).push([[5],{

/***/ 1626:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
  value: true
});
var IN_BROWSER = exports.IN_BROWSER = typeof window !== 'undefined';
var WINDOW = exports.WINDOW = IN_BROWSER ? window : {};
var NAMESPACE = exports.NAMESPACE = 'viewer';

// Actions
var ACTION_MOVE = exports.ACTION_MOVE = 'move';
var ACTION_SWITCH = exports.ACTION_SWITCH = 'switch';
var ACTION_ZOOM = exports.ACTION_ZOOM = 'zoom';

// Classes
var CLASS_ACTIVE = exports.CLASS_ACTIVE = NAMESPACE + '-active';
var CLASS_CLOSE = exports.CLASS_CLOSE = NAMESPACE + '-close';
var CLASS_FADE = exports.CLASS_FADE = NAMESPACE + '-fade';
var CLASS_FIXED = exports.CLASS_FIXED = NAMESPACE + '-fixed';
var CLASS_FULLSCREEN = exports.CLASS_FULLSCREEN = NAMESPACE + '-fullscreen';
var CLASS_FULLSCREEN_EXIT = exports.CLASS_FULLSCREEN_EXIT = NAMESPACE + '-fullscreen-exit';
var CLASS_HIDE = exports.CLASS_HIDE = NAMESPACE + '-hide';
var CLASS_HIDDEN = exports.CLASS_HIDDEN = NAMESPACE + '-hidden';
var CLASS_HIDE_MD_DOWN = exports.CLASS_HIDE_MD_DOWN = NAMESPACE + '-hide-md-down';
var CLASS_HIDE_SM_DOWN = exports.CLASS_HIDE_SM_DOWN = NAMESPACE + '-hide-sm-down';
var CLASS_HIDE_XS_DOWN = exports.CLASS_HIDE_XS_DOWN = NAMESPACE + '-hide-xs-down';
var CLASS_IN = exports.CLASS_IN = NAMESPACE + '-in';
var CLASS_INVISIBLE = exports.CLASS_INVISIBLE = NAMESPACE + '-invisible';
var CLASS_VISIBLE = exports.CLASS_VISIBLE = NAMESPACE + '-visible';
var CLASS_LOADING = exports.CLASS_LOADING = NAMESPACE + '-loading';
var CLASS_MOVE = exports.CLASS_MOVE = NAMESPACE + '-move';
var CLASS_OPEN = exports.CLASS_OPEN = NAMESPACE + '-open';
var CLASS_SHOW = exports.CLASS_SHOW = NAMESPACE + '-show';
var CLASS_TRANSITION = exports.CLASS_TRANSITION = NAMESPACE + '-transition';

// Events
var EVENT_CLICK = exports.EVENT_CLICK = 'click';
var EVENT_DRAG_START = exports.EVENT_DRAG_START = 'dragstart';
var EVENT_HIDDEN = exports.EVENT_HIDDEN = 'hidden';
var EVENT_HIDE = exports.EVENT_HIDE = 'hide';
var EVENT_KEY_DOWN = exports.EVENT_KEY_DOWN = 'keydown';
var EVENT_KEY_UP = exports.EVENT_KEY_UP = 'keyup';
var EVENT_KEY_PRESS = exports.EVENT_KEY_PRESS = 'keypress';
var EVENT_LOAD = exports.EVENT_LOAD = 'load';
var EVENT_POINTER_DOWN = exports.EVENT_POINTER_DOWN = WINDOW.PointerEvent ? 'pointerdown' : 'touchstart mousedown';
var EVENT_POINTER_MOVE = exports.EVENT_POINTER_MOVE = WINDOW.PointerEvent ? 'pointermove' : 'touchmove mousemove';
var EVENT_POINTER_UP = exports.EVENT_POINTER_UP = WINDOW.PointerEvent ? 'pointerup pointercancel' : 'touchend touchcancel mouseup';
var EVENT_GESTURE_START = exports.EVENT_GESTURE_START = 'gesturestart';
var EVENT_GESTURE_CHANGE = exports.EVENT_GESTURE_CHANGE = 'gesturechange';
var EVENT_GESTURE_END = exports.EVENT_GESTURE_END = 'gestureend';
var EVENT_MOUSE_ENTER = exports.EVENT_MOUSE_ENTER = 'mouseenter';
var EVENT_MOUSE_LEAVE = exports.EVENT_MOUSE_LEAVE = 'mouseleave';
var EVENT_READY = exports.EVENT_READY = 'ready';
var EVENT_RESIZE = exports.EVENT_RESIZE = 'resize';
var EVENT_SHOW = exports.EVENT_SHOW = 'show';
var EVENT_SHOWN = exports.EVENT_SHOWN = 'shown';
var EVENT_TRANSITION_END = exports.EVENT_TRANSITION_END = 'transitionend';
var EVENT_VIEW = exports.EVENT_VIEW = 'view';
var EVENT_VIEWED = exports.EVENT_VIEWED = 'viewed';
var EVENT_WHEEL = exports.EVENT_WHEEL = 'wheel mousewheel DOMMouseScroll';
var EVENT_ZOOM = exports.EVENT_ZOOM = 'zoom';
var EVENT_ZOOMED = exports.EVENT_ZOOMED = 'zoomed';
var WHEEL_SCROLL_SPEED_FACTOR = exports.WHEEL_SCROLL_SPEED_FACTOR = 3;
// Data keys
var DATA_ACTION = exports.DATA_ACTION = NAMESPACE + 'Action';
var BUTTONS = exports.BUTTONS = ['zoom-in', 'zoom-out', 'one-to-one', 'reset', 'prev', 'play', 'next', 'rotate-left', 'rotate-right', 'flip-horizontal', 'flip-vertical'];

var TOOLTIP = exports.TOOLTIP = {
  'zoom-in': t('image.zoom-in'),
  'zoom-out': t('image.zoom-out'),
  'one-to-one': t('image.one-to-one'),
  reset: t('image.reset')
};

var UX_EVENT_TYPE = exports.UX_EVENT_TYPE = {
  CANVAS_CLICK: 'CANVAS_CLICK',
  CANVAS_DBL_CLICK: 'CANVAS_DBL_CLICK',
  BUTTON_CLICK: 'BUTTON_CLICK',
  BACKGROUND_CLICK: 'BACKGROUND_CLICK',
  KEYBOARD: 'KEYBOARD',
  PINCH: 'PINCH',
  SWIPE: 'SWIPE',
  DRAG: 'DRAG',
  WHEEL: 'WHEEL'
};

var UX_ACTION_TYPE = exports.UX_ACTION_TYPE = {
  NEXT: 'NEXT',
  PREV: 'PREV',
  ZOOM_IN: 'ZOOM_IN',
  ZOOM_OUT: 'ZOOM_OUT',
  MOVE: 'MOVE',
  ORIGINAL_SIZE: 'ORIGINAL_SIZE',
  INITIAL_SIZE: 'INITIAL_SIZE',
  HIDE: 'HIDE'
};
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 1654:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.numRange = exports.assign = exports.isNaN = undefined;

var _typeof2 = __webpack_require__(76);

var _typeof3 = _interopRequireDefault(_typeof2);

exports.isString = isString;
exports.isNumber = isNumber;
exports.isUndefined = isUndefined;
exports.isObject = isObject;
exports.isPlainObject = isPlainObject;
exports.isFunction = isFunction;
exports.forEach = forEach;
exports.setStyle = setStyle;
exports.hasClass = hasClass;
exports.addClass = addClass;
exports.removeClass = removeClass;
exports.toggleClass = toggleClass;
exports.hyphenate = hyphenate;
exports.getData = getData;
exports.setData = setData;
exports.removeData = removeData;
exports.removeListener = removeListener;
exports.addListener = addListener;
exports.dispatchEvent = dispatchEvent;
exports.getOffset = getOffset;
exports.getTransforms = getTransforms;
exports.getImageNameFromURL = getImageNameFromURL;
exports.getImageNaturalSizes = getImageNaturalSizes;
exports.getResponsiveClass = getResponsiveClass;
exports.getMaxZoomRatio = getMaxZoomRatio;
exports.getPointer = getPointer;
exports.getPointersCenter = getPointersCenter;

var _constants = __webpack_require__(1626);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * Check if the given value is a string.
 * @param {*} value - The value to check.
 * @returns {boolean} Returns `true` if the given value is a string, else `false`.
 */
function isString(value) {
  return typeof value === 'string';
}

/**
 * Check if the given value is not a number.
 */
var isNaN = exports.isNaN = Number.isNaN || _constants.WINDOW.isNaN;

/**
 * Check if the given value is a number.
 * @param {*} value - The value to check.
 * @returns {boolean} Returns `true` if the given value is a number, else `false`.
 */
function isNumber(value) {
  return typeof value === 'number' && !isNaN(value);
}

/**
 * Check if the given value is undefined.
 * @param {*} value - The value to check.
 * @returns {boolean} Returns `true` if the given value is undefined, else `false`.
 */
function isUndefined(value) {
  return typeof value === 'undefined';
}

/**
 * Check if the given value is an object.
 * @param {*} value - The value to check.
 * @returns {boolean} Returns `true` if the given value is an object, else `false`.
 */
function isObject(value) {
  return (typeof value === 'undefined' ? 'undefined' : (0, _typeof3.default)(value)) === 'object' && value !== null;
}

var hasOwnProperty = Object.prototype.hasOwnProperty;

/**
 * Check if the given value is a plain object.
 * @param {*} value - The value to check.
 * @returns {boolean} Returns `true` if the given value is a plain object, else `false`.
 */

function isPlainObject(value) {
  if (!isObject(value)) {
    return false;
  }

  try {
    var _constructor = value.constructor;
    var prototype = _constructor.prototype;


    return _constructor && prototype && hasOwnProperty.call(prototype, 'isPrototypeOf');
  } catch (e) {
    return false;
  }
}

/**
 * Check if the given value is a function.
 * @param {*} value - The value to check.
 * @returns {boolean} Returns `true` if the given value is a function, else `false`.
 */
function isFunction(value) {
  return typeof value === 'function';
}

/**
 * Iterate the given data.
 * @param {*} data - The data to iterate.
 * @param {Function} callback - The process function for each element.
 * @returns {*} The original data.
 */
function forEach(data, callback) {
  if (data && isFunction(callback)) {
    if (Array.isArray(data) || isNumber(data.length) /* array-like */) {
        var length = data.length;

        var i = void 0;

        for (i = 0; i < length; i += 1) {
          if (callback.call(data, data[i], i, data) === false) {
            break;
          }
        }
      } else if (isObject(data)) {
      Object.keys(data).forEach(function (key) {
        callback.call(data, data[key], key, data);
      });
    }
  }

  return data;
}

/**
 * Extend the given object.
 * @param {*} obj - The object to be extended.
 * @param {*} args - The rest objects which will be merged to the first object.
 * @returns {Object} The extended object.
 */
var assign = exports.assign = Object.assign || function assign(obj) {
  for (var _len = arguments.length, args = Array(_len > 1 ? _len - 1 : 0), _key = 1; _key < _len; _key++) {
    args[_key - 1] = arguments[_key];
  }

  if (isObject(obj) && args.length > 0) {
    args.forEach(function (arg) {
      if (isObject(arg)) {
        Object.keys(arg).forEach(function (key) {
          obj[key] = arg[key];
        });
      }
    });
  }

  return obj;
};

var REGEXP_SUFFIX = /^(?:width|height|left|top|marginLeft|marginTop)$/;

/**
 * Apply styles to the given element.
 * @param {Element} element - The target element.
 * @param {Object} styles - The styles for applying.
 */
function setStyle(element, styles) {
  var style = element.style;


  forEach(styles, function (value, property) {
    if (REGEXP_SUFFIX.test(property) && isNumber(value)) {
      value += 'px';
    }

    style[property] = value;
  });
}

/**
 * Check if the given element has a special class.
 * @param {Element} element - The element to check.
 * @param {string} value - The class to search.
 * @returns {boolean} Returns `true` if the special class was found.
 */
function hasClass(element, value) {
  return element.classList ? element.classList.contains(value) : element.className.indexOf(value) > -1;
}

/**
 * Add classes to the given element.
 * @param {Element} element - The target element.
 * @param {string} value - The classes to be added.
 */
function addClass(element, value) {
  if (!value) {
    return;
  }

  if (isNumber(element.length)) {
    forEach(element, function (elem) {
      addClass(elem, value);
    });
    return;
  }

  if (element.classList) {
    element.classList.add(value);
    return;
  }

  var className = element.className.trim();

  if (!className) {
    element.className = value;
  } else if (className.indexOf(value) < 0) {
    element.className = className + ' ' + value;
  }
}

/**
 * Remove classes from the given element.
 * @param {Element} element - The target element.
 * @param {string} value - The classes to be removed.
 */
function removeClass(element, value) {
  if (!value) {
    return;
  }

  if (isNumber(element.length)) {
    forEach(element, function (elem) {
      removeClass(elem, value);
    });
    return;
  }

  if (element.classList) {
    element.classList.remove(value);
    return;
  }

  if (element.className.indexOf(value) >= 0) {
    element.className = element.className.replace(value, '');
  }
}

/**
 * Add or remove classes from the given element.
 * @param {Element} element - The target element.
 * @param {string} value - The classes to be toggled.
 * @param {boolean} added - Add only.
 */
function toggleClass(element, value, added) {
  if (!value) {
    return;
  }

  if (isNumber(element.length)) {
    forEach(element, function (elem) {
      toggleClass(elem, value, added);
    });
    return;
  }

  // IE10-11 doesn't support the second parameter of `classList.toggle`
  if (added) {
    addClass(element, value);
  } else {
    removeClass(element, value);
  }
}

var REGEXP_HYPHENATE = /([a-z\d])([A-Z])/g;

/**
 * Transform the given string from camelCase to kebab-case
 * @param {string} value - The value to transform.
 * @returns {string} The transformed value.
 */
function hyphenate(value) {
  return value.replace(REGEXP_HYPHENATE, '$1-$2').toLowerCase();
}

/**
 * Get data from the given element.
 * @param {Element} element - The target element.
 * @param {string} name - The data key to get.
 * @returns {string} The data value.
 */
function getData(element, name) {
  if (isObject(element[name])) {
    return element[name];
  }

  if (element.dataset) {
    return element.dataset[name];
  }

  return element.getAttribute('data-' + hyphenate(name));
}

/**
 * Set data to the given element.
 * @param {Element} element - The target element.
 * @param {string} name - The data key to set.
 * @param {string} data - The data value.
 */
function setData(element, name, data) {
  if (isObject(data)) {
    element[name] = data;
  } else if (element.dataset) {
    element.dataset[name] = data;
  } else {
    element.setAttribute('data-' + hyphenate(name), data);
  }
}

/**
 * Remove data from the given element.
 * @param {Element} element - The target element.
 * @param {string} name - The data key to remove.
 */
function removeData(element, name) {
  if (isObject(element[name])) {
    try {
      delete element[name];
    } catch (e) {
      element[name] = undefined;
    }
  } else if (element.dataset) {
    // #128 Safari not allows to delete dataset property
    try {
      delete element.dataset[name];
    } catch (e) {
      element.dataset[name] = undefined;
    }
  } else {
    element.removeAttribute('data-' + hyphenate(name));
  }
}

var REGEXP_SPACES = /\s\s*/;
var onceSupported = function () {
  var supported = false;

  if (_constants.IN_BROWSER) {
    var once = false;
    var listener = function listener() {};
    var options = Object.defineProperty({}, 'once', {
      get: function get() {
        supported = true;
        return once;
      },


      /**
       * This setter can fix a `TypeError` in strict mode
       * {@link https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Errors/Getter_only}
       * @param {boolean} value - The value to set
       */
      set: function set(value) {
        once = value;
      }
    });

    _constants.WINDOW.addEventListener('test', listener, options);
    _constants.WINDOW.removeEventListener('test', listener, options);
  }

  return supported;
}();

/**
 * Remove event listener from the target element.
 * @param {Element} element - The event target.
 * @param {string} type - The event type(s).
 * @param {Function} listener - The event listener.
 * @param {Object} options - The event options.
 */
function removeListener(element, type, listener) {
  var options = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : {};

  var handler = listener;

  type.trim().split(REGEXP_SPACES).forEach(function (event) {
    if (!onceSupported) {
      var listeners = element.listeners;


      if (listeners && listeners[event] && listeners[event][listener]) {
        handler = listeners[event][listener];
        delete listeners[event][listener];

        if (Object.keys(listeners[event]).length === 0) {
          delete listeners[event];
        }

        if (Object.keys(listeners).length === 0) {
          delete element.listeners;
        }
      }
    }

    element.removeEventListener(event, handler, options);
  });
}

/**
 * Add event listener to the target element.
 * @param {Element} element - The event target.
 * @param {string} type - The event type(s).
 * @param {Function} listener - The event listener.
 * @param {Object} options - The event options.
 */
function addListener(element, type, listener) {
  var options = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : {};

  var _handler = listener;

  type.trim().split(REGEXP_SPACES).forEach(function (event) {
    if (options.once && !onceSupported) {
      var _element$listeners = element.listeners,
          listeners = _element$listeners === undefined ? {} : _element$listeners;


      _handler = function handler() {
        for (var _len2 = arguments.length, args = Array(_len2), _key2 = 0; _key2 < _len2; _key2++) {
          args[_key2] = arguments[_key2];
        }

        delete listeners[event][listener];
        element.removeEventListener(event, _handler, options);
        listener.apply(element, args);
      };

      if (!listeners[event]) {
        listeners[event] = {};
      }

      if (listeners[event][listener]) {
        element.removeEventListener(event, listeners[event][listener], options);
      }

      listeners[event][listener] = _handler;
      element.listeners = listeners;
    }

    element.addEventListener(event, _handler, options);
  });
}

/**
 * Dispatch event on the target element.
 * @param {Element} element - The event target.
 * @param {string} type - The event type(s).
 * @param {Object} data - The additional event data.
 * @returns {boolean} Indicate if the event is default prevented or not.
 */
function dispatchEvent(element, type, data) {
  var event = void 0;

  // Event and CustomEvent on IE9-11 are global objects, not constructors
  if (isFunction(Event) && isFunction(CustomEvent)) {
    event = new CustomEvent(type, {
      detail: data,
      bubbles: true,
      cancelable: true
    });
  } else {
    event = document.createEvent('CustomEvent');
    event.initCustomEvent(type, true, true, data);
  }

  return element.dispatchEvent(event);
}

/**
 * Get the offset base on the document.
 * @param {Element} element - The target element.
 * @returns {Object} The offset data.
 */
function getOffset(element) {
  var box = element.getBoundingClientRect();

  return {
    left: box.left + (window.pageXOffset - document.documentElement.clientLeft),
    top: box.top + (window.pageYOffset - document.documentElement.clientTop)
  };
}

/**
 * Get transforms base on the given object.
 * @param {Object} obj - The target object.
 * @returns {string} A string contains transform values.
 */
function getTransforms(_ref) {
  var rotate = _ref.rotate,
      scaleX = _ref.scaleX,
      scaleY = _ref.scaleY,
      translateX = _ref.translateX,
      translateY = _ref.translateY;

  var values = [];

  if (isNumber(translateX) && translateX !== 0) {
    values.push('translateX(' + translateX + 'px)');
  }

  if (isNumber(translateY) && translateY !== 0) {
    values.push('translateY(' + translateY + 'px)');
  }

  // Rotate should come first before scale to match orientation transform
  if (isNumber(rotate) && rotate !== 0) {
    values.push('rotate(' + rotate + 'deg)');
  }

  if (isNumber(scaleX) && scaleX !== 1) {
    values.push('scaleX(' + scaleX + ')');
  }

  if (isNumber(scaleY) && scaleY !== 1) {
    values.push('scaleY(' + scaleY + ')');
  }

  var transform = values.length ? values.join(' ') : 'none';

  return {
    WebkitTransform: transform,
    msTransform: transform,
    transform: transform
  };
}

/**
 * Get an image name from an image url.
 * @param {string} url - The target url.
 * @example
 * // picture.jpg
 * getImageNameFromURL('http://domain.com/path/to/picture.jpg?size=1280×960')
 * @returns {string} A string contains the image name.
 */
function getImageNameFromURL(url) {
  return isString(url) ? url.replace(/^.*\//, '').replace(/[?&#].*$/, '') : '';
}

var IS_SAFARI = _constants.WINDOW.navigator && /(Macintosh|iPhone|iPod|iPad).*AppleWebKit/i.test(_constants.WINDOW.navigator.userAgent);

/**
 * Get an image's natural sizes.
 * @param {string} image - The target image.
 * @param {Function} callback - The callback function.
 * @returns {HTMLImageElement} The new image.
 */
function getImageNaturalSizes(image, callback) {
  var newImage = document.createElement('img');

  // Modern browsers (except Safari)
  if (image.naturalWidth && !IS_SAFARI) {
    callback(image.naturalWidth, image.naturalHeight);
    return newImage;
  }

  var body = document.body || document.documentElement;

  newImage.onload = function () {
    callback(newImage.width, newImage.height);

    if (!IS_SAFARI) {
      body.removeChild(newImage);
    }
  };

  newImage.src = image.src;

  // iOS Safari will convert the image automatically
  // with its orientation once append it into DOM
  if (!IS_SAFARI) {
    newImage.style.cssText = 'left:0;' + 'max-height:none!important;' + 'max-width:none!important;' + 'min-height:0!important;' + 'min-width:0!important;' + 'opacity:0;' + 'position:absolute;' + 'top:0;' + 'z-index:-1;';
    body.appendChild(newImage);
  }

  return newImage;
}

/**
 * Get the related class name of a responsive type number.
 * @param {string} type - The responsive type.
 * @returns {string} The related class name.
 */
function getResponsiveClass(type) {
  switch (type) {
    case 2:
      return _constants.CLASS_HIDE_XS_DOWN;

    case 3:
      return _constants.CLASS_HIDE_SM_DOWN;

    case 4:
      return _constants.CLASS_HIDE_MD_DOWN;

    default:
      return '';
  }
}

/**
 * Get the max ratio of a group of pointers.
 * @param {string} pointers - The target pointers.
 * @returns {number} The result ratio.
 */
function getMaxZoomRatio(pointers) {
  var pointers2 = assign({}, pointers);
  var ratios = [];

  forEach(pointers, function (pointer, pointerId) {
    delete pointers2[pointerId];

    forEach(pointers2, function (pointer2) {
      var x1 = Math.abs(pointer.startX - pointer2.startX);
      var y1 = Math.abs(pointer.startY - pointer2.startY);
      var x2 = Math.abs(pointer.endX - pointer2.endX);
      var y2 = Math.abs(pointer.endY - pointer2.endY);
      var z1 = Math.sqrt(x1 * x1 + y1 * y1);
      var z2 = Math.sqrt(x2 * x2 + y2 * y2);
      var ratio = (z2 - z1) / z1;

      ratios.push(ratio);
    });
  });

  ratios.sort(function (a, b) {
    return Math.abs(a) < Math.abs(b);
  });

  return ratios[0];
}

/**
 * Get a pointer from an event object.
 * @param {Object} event - The target event object.
 * @param {boolean} endOnly - Indicates if only returns the end point coordinate or not.
 * @returns {Object} The result pointer contains start and/or end point coordinates.
 */
function getPointer(_ref2, endOnly) {
  var pageX = _ref2.pageX,
      pageY = _ref2.pageY;

  var end = {
    endX: pageX,
    endY: pageY
  };

  return endOnly ? end : assign({
    startX: pageX,
    startY: pageY
  }, end);
}

/**
 * Get the center point coordinate of a group of pointers.
 * @param {Object} pointers - The target pointers.
 * @returns {Object} The center point coordinate.
 */
function getPointersCenter(pointers) {
  var pageX = 0;
  var pageY = 0;
  var count = 0;

  forEach(pointers, function (_ref3) {
    var startX = _ref3.startX,
        startY = _ref3.startY;

    pageX += startX;
    pageY += startY;
    count += 1;
  });

  pageX /= count;
  pageY /= count;

  return {
    pageX: pageX,
    pageY: pageY
  };
}

var numRange = exports.numRange = function numRange(value, minValue, maxValue) {
  return Math.min(maxValue, Math.max(minValue, value));
};

/***/ }),

/***/ 1816:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.createViewer = exports.MODULE_TYPE = undefined;

var _viewerjs = __webpack_require__(3043);

var _viewerjs2 = _interopRequireDefault(_viewerjs);

var _tea = __webpack_require__(47);

var _tea2 = _interopRequireDefault(_tea);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var MODULE_TYPE = exports.MODULE_TYPE = {
    DOC_FULLSCREEN: 'presentation',
    DOC_BODY: 'mainbody',
    SHEET: 'sheet'
};
var createViewer = exports.createViewer = function createViewer(element, options, evtSource) {
    var startTime = Date.now();
    var report = function report(_ref) {
        var actionType = _ref.actionType,
            evtType = _ref.evtType;

        var action = void 0;
        var event = void 0;
        switch (actionType) {
            case _viewerjs.UX_ACTION_TYPE.HIDE:
                action = 'close';
                event = evtType === _viewerjs.UX_EVENT_TYPE.KEYBOARD ? 'esc' : evtType === _viewerjs.UX_EVENT_TYPE.BUTTON_CLICK ? 'click_icon' : 'click_bg';
                break;
            case _viewerjs.UX_ACTION_TYPE.NEXT:
            case _viewerjs.UX_ACTION_TYPE.PREV:
                action = actionType === _viewerjs.UX_ACTION_TYPE.NEXT ? 'next_image' : 'previous_image';
                event = evtType === _viewerjs.UX_EVENT_TYPE.KEYBOARD ? 'keyboard' : 'click_icon';
                break;
            case _viewerjs.UX_ACTION_TYPE.ZOOM_IN:
            case _viewerjs.UX_ACTION_TYPE.ZOOM_OUT:
                action = actionType === _viewerjs.UX_ACTION_TYPE.ZOOM_IN ? 'zoom_in' : 'zoom_out';
                event = evtType === _viewerjs.UX_EVENT_TYPE.KEYBOARD ? 'keyboard' : evtType === _viewerjs.UX_EVENT_TYPE.WHEEL ? 'wheel' : evtType === _viewerjs.UX_EVENT_TYPE.PINCH ? 'pinch' : 'click_icon';
                break;
            case _viewerjs.UX_ACTION_TYPE.ORIGINAL_SIZE:
            case _viewerjs.UX_ACTION_TYPE.INITIAL_SIZE:
                action = actionType === _viewerjs.UX_ACTION_TYPE.ORIGINAL_SIZE ? 'original_size' : 'initial_size';
                event = evtType === _viewerjs.UX_EVENT_TYPE.CANVAS_DBL_CLICK ? 'double_click' : 'click_icon';
                break;
            case _viewerjs.UX_ACTION_TYPE.MOVE:
                action = 'move';
                event = evtType === _viewerjs.UX_EVENT_TYPE.DRAG ? 'drag' : 'wheel';
                break;
            default:
                return;
        }
        (0, _tea2.default)('client_block_view', {
            client_block_view_type: 'picture',
            client_block_view_subtype: 'picture_' + action + '_by_' + event,
            client_block_view_source: evtSource
        });
    };
    var launchTimeReporter = function launchTimeReporter() {
        var endTime = Date.now();
        (0, _tea2.default)('client_block_view', {
            client_block_view_type: 'picture',
            client_block_view_subtype: 'picture_open',
            client_block_view_source: evtSource,
            client_block_view_launch_duration: endTime - startTime
        });
    };
    return new _viewerjs2.default(element, Object.assign({
        minZoomRatio: 0.1,
        maxZoomRatio: 5,
        button: false,
        navbar: false,
        title: false,
        clearSwitchTransition: true,
        toolbar: {
            zoomIn: true,
            zoomOut: true,
            oneToOne: true
        },
        rotatable: false,
        fullscreen: false,
        keyboard: true,
        loop: false,
        url: function url(image) {
            var dataSrc = image.getAttribute('data-src');
            return dataSrc ? dataSrc.replace(/\/$/, '~noop') : image.src;
        },
        report: report,
        shown: launchTimeReporter
    }, options));
};

/***/ }),

/***/ 3043:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.UX_EVENT_TYPE = exports.UX_ACTION_TYPE = undefined;

var _viewer = __webpack_require__(3044);

var _viewer2 = _interopRequireDefault(_viewer);

var _constants = __webpack_require__(1626);

__webpack_require__(3052);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.UX_ACTION_TYPE = _constants.UX_ACTION_TYPE;
exports.UX_EVENT_TYPE = _constants.UX_EVENT_TYPE;
exports.default = _viewer2.default;

/***/ }),

/***/ 3044:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _throttle2 = __webpack_require__(502);

var _throttle3 = _interopRequireDefault(_throttle2);

var _debounce2 = __webpack_require__(275);

var _debounce3 = _interopRequireDefault(_debounce2);

var _defaults = __webpack_require__(3045);

var _defaults2 = _interopRequireDefault(_defaults);

var _template = __webpack_require__(3046);

var _template2 = _interopRequireDefault(_template);

var _render = __webpack_require__(3047);

var _render2 = _interopRequireDefault(_render);

var _events = __webpack_require__(3048);

var _events2 = _interopRequireDefault(_events);

var _handlers = __webpack_require__(3049);

var _handlers2 = _interopRequireDefault(_handlers);

var _methods = __webpack_require__(3050);

var _methods2 = _interopRequireDefault(_methods);

var _others = __webpack_require__(3051);

var _others2 = _interopRequireDefault(_others);

var _constants = __webpack_require__(1626);

var _utilities = __webpack_require__(1654);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var AnotherViewer = _constants.WINDOW.Viewer;

var Viewer = function () {
  /**
   * Create a new Viewer.
   * @param {Element} element - The target element for viewing.
   * @param {Object} [options={}] - The configuration options.
   */
  function Viewer(element) {
    var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
    (0, _classCallCheck3.default)(this, Viewer);

    if (!element || element.nodeType !== 1) {
      throw new Error('The first argument is required and must be an element.');
    }

    this.element = element;
    this.options = (0, _utilities.assign)({}, _defaults2.default, (0, _utilities.isPlainObject)(options) && options);
    this.action = false;
    this.fading = false;
    this.fulled = false;
    this.hiding = false;
    this.imageData = {};
    this.index = this.options.initialViewIndex;
    this.isImg = false;
    this.isShown = false;
    this.length = 0;
    this.played = false;
    this.playing = false;
    this.pointers = {};
    this.ready = false;
    this.showing = false;
    this.timeout = false;
    this.tooltipping = false;
    this.viewed = false;
    this.viewing = false;
    this.zooming = false;

    this._reportWheelThrottled = (0, _throttle3.default)(this.report, this.options.reportThrottle);
    this._reportPinchThrottled = (0, _throttle3.default)(this.report, this.options.reportThrottle);
    this._reportDragThrottled = (0, _throttle3.default)(this.report, this.options.reportThrottle);

    this.init();
  }

  (0, _createClass3.default)(Viewer, [{
    key: 'init',
    value: function init() {
      var _this = this;

      var element = this.element,
          options = this.options;


      if ((0, _utilities.getData)(element, _constants.NAMESPACE)) {
        return;
      }

      (0, _utilities.setData)(element, _constants.NAMESPACE, this);

      var isImg = element.tagName.toLowerCase() === 'img';
      var images = [];

      (0, _utilities.forEach)(isImg ? [element] : element.querySelectorAll('img'), function (image) {
        if ((0, _utilities.isFunction)(options.filter)) {
          if (options.filter.call(_this, image)) {
            images.push(image);
          }
        } else {
          images.push(image);
        }
      });

      if (!images.length) {
        return;
      }

      this.isImg = isImg;
      this.length = images.length;
      this.images = images;

      var ownerDocument = element.ownerDocument;

      var body = ownerDocument.body || ownerDocument.documentElement;

      this.body = body;
      this.scrollbarWidth = window.innerWidth - ownerDocument.documentElement.clientWidth;
      this.initialBodyPaddingRight = window.getComputedStyle(body).paddingRight;

      this._wheelThrottled = (0, _throttle3.default)(this._wheel.bind(this), 50);
      this._scrollThrottled = (0, _throttle3.default)(this._scroll.bind(this), 50);
      // Override `transition` option if it is not supported
      if ((0, _utilities.isUndefined)(document.createElement(_constants.NAMESPACE).style.transition)) {
        options.transition = false;
      }

      if (options.inline) {
        var count = 0;
        var progress = function progress() {
          count += 1;

          if (count === _this.length) {
            // build asynchronously to keep `this.viewer` is accessible in `ready` event handler.
            var timeout = setTimeout(function () {
              _this.delaying = false;
              _this.build();
            }, 0);

            _this.initializing = false;
            _this.delaying = {
              abort: function abort() {
                clearTimeout(timeout);
              }
            };
          }
        };

        this.initializing = {
          abort: function abort() {
            (0, _utilities.forEach)(images, function (image) {
              if (!image.complete) {
                (0, _utilities.removeListener)(image, _constants.EVENT_LOAD, progress);
              }
            });
          }
        };

        (0, _utilities.forEach)(images, function (image) {
          if (image.complete) {
            progress();
          } else {
            (0, _utilities.addListener)(image, _constants.EVENT_LOAD, progress, {
              once: true
            });
          }
        });
      } else {
        (0, _utilities.addListener)(element, _constants.EVENT_CLICK, this.onStart = function (_ref) {
          var target = _ref.target;

          if (target.tagName.toLowerCase() === 'img') {
            _this.view(_this.images.indexOf(target));
          }
        });
      }
    }
  }, {
    key: 'build',
    value: function build() {
      if (this.ready) {
        return;
      }

      var element = this.element,
          options = this.options;

      var parent = element.parentNode;
      var template = document.createElement('div');

      template.innerHTML = _template2.default;

      var viewer = template.querySelector('.' + _constants.NAMESPACE + '-container');
      var title = viewer.querySelector('.' + _constants.NAMESPACE + '-title');
      var toolbar = viewer.querySelector('.' + _constants.NAMESPACE + '-toolbar');
      var navbar = viewer.querySelector('.' + _constants.NAMESPACE + '-navbar');
      var button = viewer.querySelector('.' + _constants.NAMESPACE + '-button');
      var background = viewer.querySelector('.' + _constants.NAMESPACE + '-background');
      var header = viewer.querySelector('.' + _constants.NAMESPACE + '-header');
      var footer = viewer.querySelector('.' + _constants.NAMESPACE + '-footer');
      var left = viewer.querySelector('.' + _constants.NAMESPACE + '-left');
      var right = viewer.querySelector('.' + _constants.NAMESPACE + '-right');
      var indexing = viewer.querySelector('.' + _constants.NAMESPACE + '-index');

      this.parent = parent;
      this.viewer = viewer;
      this.title = title;
      this.toolbar = toolbar;
      this.navbar = navbar;
      this.button = button;
      this.background = background;
      this.header = header;
      this.footer = footer;
      this.left = left;
      this.right = right;
      this.indexing = indexing;
      this.canvas = viewer.querySelector('.' + _constants.NAMESPACE + '-canvas');
      this.tooltipBox = viewer.querySelector('.' + _constants.NAMESPACE + '-tooltip');
      this.player = viewer.querySelector('.' + _constants.NAMESPACE + '-player');
      this.list = viewer.querySelector('.' + _constants.NAMESPACE + '-list');

      (0, _utilities.addClass)(title, !options.title ? _constants.CLASS_HIDE : (0, _utilities.getResponsiveClass)(Array.isArray(options.title) ? options.title[0] : options.title));
      (0, _utilities.addClass)(navbar, !options.navbar ? _constants.CLASS_HIDE : (0, _utilities.getResponsiveClass)(options.navbar));
      (0, _utilities.toggleClass)(button, _constants.CLASS_HIDE, !options.button);

      if (options.backdrop) {
        (0, _utilities.addClass)(viewer, _constants.NAMESPACE + '-backdrop');

        if (!options.inline && options.backdrop === true) {
          (0, _utilities.setData)(background, _constants.DATA_ACTION, 'hide');
        }
      }

      if (options.toolbar) {
        var fragment = document.createDocumentFragment();
        var custom = (0, _utilities.isPlainObject)(options.toolbar);
        var zoomButtons = _constants.BUTTONS.slice(0, 3);
        var rotateButtons = _constants.BUTTONS.slice(7, 9);
        var scaleButtons = _constants.BUTTONS.slice(9);

        if (!custom) {
          (0, _utilities.addClass)(toolbar, (0, _utilities.getResponsiveClass)(options.toolbar));
        }

        (0, _utilities.forEach)(custom ? options.toolbar : _constants.BUTTONS, function (value, index) {
          var deep = custom && (0, _utilities.isPlainObject)(value);
          var name = custom ? (0, _utilities.hyphenate)(index) : value;
          var show = deep && !(0, _utilities.isUndefined)(value.show) ? value.show : value;

          if (!show || !options.zoomable && zoomButtons.indexOf(name) !== -1 || !options.rotatable && rotateButtons.indexOf(name) !== -1 || !options.scalable && scaleButtons.indexOf(name) !== -1) {
            return;
          }

          var size = deep && !(0, _utilities.isUndefined)(value.size) ? value.size : value;
          var click = deep && !(0, _utilities.isUndefined)(value.click) ? value.click : value;
          var item = document.createElement('li');
          var tooltip = document.createElement('div');
          tooltip.className = 'tooltiptext';
          tooltip.innerHTML = _constants.TOOLTIP[name];
          item.appendChild(tooltip);

          item.setAttribute('role', 'button');
          (0, _utilities.addClass)(item, _constants.NAMESPACE + '-icon-' + name);

          if (!(0, _utilities.isFunction)(click)) {
            (0, _utilities.setData)(item, _constants.DATA_ACTION, name);
          }

          if ((0, _utilities.isNumber)(show)) {
            (0, _utilities.addClass)(item, (0, _utilities.getResponsiveClass)(show));
          }

          if (['small', 'large'].indexOf(size) !== -1) {
            (0, _utilities.addClass)(item, _constants.NAMESPACE + '-' + size);
          } else if (name === 'play') {
            (0, _utilities.addClass)(item, _constants.NAMESPACE + '-large');
          }

          if ((0, _utilities.isFunction)(click)) {
            (0, _utilities.addListener)(item, _constants.EVENT_CLICK, click);
          }

          fragment.appendChild(item);
        });

        toolbar.appendChild(fragment);

        this.toolbarOneToOne = false;
      } else {
        (0, _utilities.addClass)(toolbar, _constants.CLASS_HIDE);
      }

      if (!options.rotatable) {
        var rotates = toolbar.querySelectorAll('li[class*="rotate"]');

        (0, _utilities.addClass)(rotates, _constants.CLASS_INVISIBLE);
        (0, _utilities.forEach)(rotates, function (rotate) {
          toolbar.appendChild(rotate);
        });
      }

      if (options.inline) {
        (0, _utilities.addClass)(button, _constants.CLASS_FULLSCREEN);
        (0, _utilities.setStyle)(viewer, {
          zIndex: options.zIndexInline
        });

        if (window.getComputedStyle(parent).position === 'static') {
          (0, _utilities.setStyle)(parent, {
            position: 'relative'
          });
        }

        parent.insertBefore(viewer, element.nextSibling);
      } else {
        (0, _utilities.addClass)(button, _constants.CLASS_CLOSE);
        (0, _utilities.addClass)(viewer, _constants.CLASS_FIXED);
        (0, _utilities.addClass)(viewer, _constants.CLASS_FADE);
        (0, _utilities.addClass)(viewer, _constants.CLASS_HIDE);

        (0, _utilities.setStyle)(viewer, {
          zIndex: options.zIndex
        });

        var container = options.container;


        if ((0, _utilities.isString)(container)) {
          container = element.ownerDocument.querySelector(container);
        }

        if (!container) {
          container = this.body;
        }

        container.appendChild(viewer);
      }

      if (options.inline) {
        this.render();
        this.bind();
        this.isShown = true;
      }

      (0, _utilities.addClass)(header, _constants.CLASS_VISIBLE);
      (0, _utilities.addClass)(footer, _constants.CLASS_VISIBLE);
      this.index !== 0 && (0, _utilities.addClass)(left, _constants.CLASS_VISIBLE);
      this.index !== this.length - 1 && (0, _utilities.addClass)(right, _constants.CLASS_VISIBLE);
      (0, _utilities.addClass)(indexing, _constants.CLASS_VISIBLE);

      if (options.autohideControls) {
        this.initialControlsVisibleTimeout = setTimeout(function () {
          (0, _utilities.removeClass)(header, _constants.CLASS_VISIBLE);
          (0, _utilities.removeClass)(footer, _constants.CLASS_VISIBLE);
          (0, _utilities.removeClass)(left, _constants.CLASS_VISIBLE);
          (0, _utilities.removeClass)(right, _constants.CLASS_VISIBLE);
          (0, _utilities.removeClass)(indexing, _constants.CLASS_VISIBLE);
        }, options.initialControlsVisibleTimeout || 1500);
        this.debounceRemoveCls = (0, _debounce3.default)(_utilities.removeClass, options.initialControlsVisibleTimeout || 1500);
        this.debounceRemoveCls(indexing, _constants.CLASS_VISIBLE);
      } else {
        this.debounceRemoveCls = function () {
          return null;
        };
      }

      this.ready = true;

      if ((0, _utilities.isFunction)(options.ready)) {
        (0, _utilities.addListener)(element, _constants.EVENT_READY, options.ready, {
          once: true
        });
      }

      if ((0, _utilities.dispatchEvent)(element, _constants.EVENT_READY) === false) {
        this.ready = false;
        return;
      }

      if (this.ready && options.inline) {
        this.view(this.index);
      }
    }

    /**
     * Get the no conflict viewer class.
     * @returns {Viewer} The viewer class.
     */

  }], [{
    key: 'noConflict',
    value: function noConflict() {
      window.Viewer = AnotherViewer;
      return Viewer;
    }

    /**
     * Change the default options.
     * @param {Object} options - The new default options.
     */

  }, {
    key: 'setDefaults',
    value: function setDefaults(options) {
      (0, _utilities.assign)(_defaults2.default, (0, _utilities.isPlainObject)(options) && options);
    }
  }]);
  return Viewer;
}();

(0, _utilities.assign)(Viewer.prototype, _render2.default, _events2.default, _handlers2.default, _methods2.default, _others2.default);

exports.default = Viewer;

/***/ }),

/***/ 3045:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = {
  /**
   * Define the initial index of image for viewing.
   * @type {number}
   */
  initialViewIndex: 0,

  /**
   * Enable inline mode.
   * @type {boolean}
   */
  inline: false,

  /**
   * Show the button on the top-right of the viewer.
   * @type {boolean}
   */
  button: true,

  /**
   * Show the navbar.
   * @type {boolean | number}
   */
  navbar: true,

  /**
   * Specify the visibility and the content of the title.
   * @type {boolean | number | Function | Array}
   */
  title: true,

  /**
   * Show the toolbar.
   * @type {boolean | number | Object}
   */
  toolbar: true,

  /**
   * Show the tooltip with image ratio (percentage) when zoom in or zoom out.
   * @type {boolean}
   */
  tooltip: true,

  /**
   * Enable to move the image.
   * @type {boolean}
   */
  movable: true,

  /**
   * Enable to zoom the image.
   * @type {boolean}
   */
  zoomable: true,

  /**
   * Enable to rotate the image.
   * @type {boolean}
   */
  rotatable: true,

  /**
   * Enable to scale the image.
   * @type {boolean}
   */
  scalable: true,

  /**
   * Enable CSS3 Transition for some special elements.
   * @type {boolean}
   */
  transition: true,

  /**
   * Enable to request fullscreen when play.
   * @type {boolean}
   */
  fullscreen: true,

  /**
   * The amount of time to delay between automatically cycling an image when playing.
   * @type {number}
   */
  interval: 5000,

  /**
   * Enable keyboard support.
   * @type {boolean}
   */
  keyboard: true,

  /**
   * Enable a modal backdrop, specify `static` for a backdrop
   * which doesn't close the modal on click.
   * @type {boolean}
   */
  backdrop: true,

  /**
   * Indicate if show a loading spinner when load image or not.
   * @type {boolean}
   */
  loading: true,

  /**
   * Indicate if enable loop viewing or not.
   * @type {boolean}
   */
  loop: true,

  /**
   * Min width of the viewer in inline mode.
   * @type {number}
   */
  minWidth: 200,

  /**
   * Min height of the viewer in inline mode.
   * @type {number}
   */
  minHeight: 100,

  /**
   * Define the ratio when zoom the image by wheeling mouse.
   * @type {number}
   */
  zoomRatio: 0.1,

  /**
   * Define the min ratio of the image when zoom out.
   * @type {number}
   */
  minZoomRatio: 0.01,

  /**
   * Define the max ratio of the image when zoom in.
   * @type {number}
   */
  maxZoomRatio: 100,

  /**
   * Define the CSS `z-index` value of viewer in modal mode.
   * @type {number}
   */
  zIndex: 2015,

  /**
   * Define the CSS `z-index` value of viewer in inline mode.
   * @type {number}
   */
  zIndexInline: 0,

  /**
   * Define where to get the original image URL for viewing.
   * @type {string | Function}
   */
  url: 'src',

  /**
   * Define where to put the viewer in modal mode.
   * @type {string | Element}
   */
  container: 'body',

  /**
   * Filter the images for viewing. Return true if the image is viewable.
   * @type {Function}
   */
  filter: null,

  /**
   * Indicate if toggle the image size between its natural size
   * and initial size when double click on the image or not.
   * @type {boolean}
   */
  toggleOnDblclick: true,

  /**
   * whether or not autohide controls, include close button and toolbar.
   * @type {boolean}
   */
  autohideControls: true,

  /**
   * how often report calls should be made for frequent events.
   * @type {number}
   */
  reportThrottle: 1000,

  /**
   * Event shortcuts.
   * @type {Function}
   */
  ready: null,
  show: null,
  shown: null,
  hide: null,
  hidden: null,
  view: null,
  viewed: null,
  zoom: null,
  zoomed: null,
  report: null
};

/***/ }),

/***/ 3046:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _browserHelper = __webpack_require__(34);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

var _classnames = __webpack_require__(29);

var _classnames2 = _interopRequireDefault(_classnames);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var viewerCls = (0, _classnames2.default)('viewer-container', {
  'view-container-in-windows': _browserHelper2.default.windows
});
exports.default = ['<div class="' + viewerCls + '" touch-action="none">', '<div class="viewer-background"></div>', '<div class="viewer-canvas"></div>', '<div class="viewer-header" data-viewer-action="hide">', '<div role="button" class="viewer-icon-close" data-viewer-action="mix"></div>', '</div>', '<div class="viewer-left" data-viewer-action="hide">', '<div role="button" class="viewer-icon-prev" data-viewer-action="prev">', '<div class="tooltiptext">' + t('image.prev') + '</div>', '</div>', '</div>', '<div class="viewer-right" data-viewer-action="hide">', '<div role="button" class="viewer-icon-next" data-viewer-action="next">', '<div class="tooltiptext">' + t('image.next') + '</div>', '</div>', '</div>', '<div class="viewer-index"></div>', '<div class="viewer-footer" data-viewer-action="hide">', '<div class="viewer-title"></div>', '<ul class="viewer-toolbar"></ul>', '<div class="viewer-navbar">', '<ul class="viewer-list"></ul>', '</div>', '</div>', '<div class="viewer-tooltip"></div>', '<div role="button" class="viewer-button" data-viewer-action="mix"></div>', '<div class="viewer-player"></div>', '</div>'].join('');
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 3047:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _constants = __webpack_require__(1626);

var _utilities = __webpack_require__(1654);

exports.default = {
  render: function render() {
    this.initContainer();
    this.initViewer();
    this.initList();
    this.renderViewer();
  },
  initContainer: function initContainer() {
    this.containerData = {
      width: window.innerWidth,
      height: window.innerHeight
    };
  },
  initViewer: function initViewer() {
    var options = this.options,
        parent = this.parent;

    var viewerData = void 0;

    if (options.inline) {
      viewerData = {
        width: Math.max(parent.offsetWidth, options.minWidth),
        height: Math.max(parent.offsetHeight, options.minHeight)
      };

      this.parentData = viewerData;
    }

    if (this.fulled || !viewerData) {
      viewerData = this.containerData;
    }

    this.viewerData = (0, _utilities.assign)({}, viewerData);
  },
  renderViewer: function renderViewer() {
    if (this.options.inline && !this.fulled) {
      (0, _utilities.setStyle)(this.viewer, this.viewerData);
    }
  },
  initList: function initList() {
    var _this = this;

    var element = this.element,
        options = this.options,
        list = this.list;

    var items = [];

    (0, _utilities.forEach)(this.images, function (image, i) {
      var src = image.src;

      var alt = image.alt || (0, _utilities.getImageNameFromURL)(src);
      var url = options.url;


      if ((0, _utilities.isString)(url)) {
        url = image.getAttribute(url);
      } else if ((0, _utilities.isFunction)(url)) {
        url = url.call(_this, image);
      }

      if (src || url) {
        items.push('<li>' + '<img' + (' src="' + (src || url) + '"') + ' role="button"' + ' data-viewer-action="view"' + (' data-index="' + i + '"') + (' data-original-url="' + (url || src) + '"') + (' alt="' + alt + '"') + '>' + '</li>');
      }
    });

    list.innerHTML = items.join('');
    this.items = list.getElementsByTagName('li');
    (0, _utilities.forEach)(this.items, function (item) {
      var image = item.firstElementChild;

      (0, _utilities.setData)(image, 'filled', true);

      if (options.loading) {
        (0, _utilities.addClass)(item, _constants.CLASS_LOADING);
      }

      (0, _utilities.addListener)(image, _constants.EVENT_LOAD, function (event) {
        if (options.loading) {
          (0, _utilities.removeClass)(item, _constants.CLASS_LOADING);
        }

        _this.loadImage(event);
      }, {
        once: true
      });
    });

    if (options.transition) {
      (0, _utilities.addListener)(element, _constants.EVENT_VIEWED, function () {
        (0, _utilities.addClass)(list, _constants.CLASS_TRANSITION);
      }, {
        once: true
      });
    }
  },
  renderList: function renderList(index) {
    var i = index || this.index;
    var width = this.items[i].offsetWidth || 30;
    var outerWidth = width + 1; // 1 pixel of `margin-left` width

    // Place the active item in the center of the screen
    (0, _utilities.setStyle)(this.list, (0, _utilities.assign)({
      width: outerWidth * this.length
    }, (0, _utilities.getTransforms)({
      translateX: (this.viewerData.width - width) / 2 - outerWidth * i
    })));
  },
  resetList: function resetList() {
    var list = this.list;


    list.innerHTML = '';
    (0, _utilities.removeClass)(list, _constants.CLASS_TRANSITION);
    (0, _utilities.setStyle)(list, (0, _utilities.getTransforms)({
      translateX: 0
    }));
  },
  getViewerDimension: function getViewerDimension() {
    var viewerData = this.viewerData;


    if (!this.options.keepFooterOffsetHeight) {
      return viewerData;
    }

    var footerHeight = this.footer.offsetHeight;
    return {
      width: viewerData.width,
      height: Math.max(viewerData.height - footerHeight, footerHeight)
    };
  },
  initImage: function initImage(done) {
    var _this2 = this;

    var options = this.options,
        image = this.image;

    var _getViewerDimension = this.getViewerDimension(),
        viewerWidth = _getViewerDimension.width,
        viewerHeight = _getViewerDimension.height;

    var oldImageData = this.imageData || {};
    var sizingImage = (0, _utilities.getImageNaturalSizes)(image, function (naturalWidth, naturalHeight) {
      var aspectRatio = naturalWidth / naturalHeight;
      var width = viewerWidth;
      var height = viewerHeight;

      _this2.imageInitializing = false;

      if (viewerHeight * aspectRatio > viewerWidth) {
        height = viewerWidth / aspectRatio;
      } else {
        width = viewerHeight * aspectRatio;
      }

      width = Math.min(width * 0.9, naturalWidth);
      height = Math.min(height * 0.9, naturalHeight);

      var imageData = {
        naturalWidth: naturalWidth,
        naturalHeight: naturalHeight,
        aspectRatio: aspectRatio,
        ratio: width / naturalWidth,
        width: width,
        height: height,
        left: (viewerWidth - width) / 2,
        top: (viewerHeight - height) / 2
      };
      var initialImageData = (0, _utilities.assign)({}, imageData);

      if (options.rotatable) {
        imageData.rotate = oldImageData.rotate || 0;
        initialImageData.rotate = 0;
      }

      if (options.scalable) {
        imageData.scaleX = oldImageData.scaleX || 1;
        imageData.scaleY = oldImageData.scaleY || 1;
        initialImageData.scaleX = 1;
        initialImageData.scaleY = 1;
      }

      _this2.imageData = imageData;

      _this2.initialImageData = initialImageData;
      _this2.initialImageZoom = _this2.isLongImg();
      if (done) {
        done();
      }
    });

    this.imageInitializing = {
      abort: function abort() {
        sizingImage.onload = null;
      }
    };
  },
  renderImage: function renderImage(done) {
    var _this3 = this;

    var image = this.image,
        imageData = this.imageData,
        options = this.options,
        viewerData = this.viewerData;

    if (!image) {
      return;
    }

    var style = (0, _utilities.assign)({
      width: imageData.width,
      height: imageData.height,
      marginLeft: imageData.left,
      marginTop: imageData.top
    }, (0, _utilities.getTransforms)(imageData));

    var movable = imageData.width > viewerData.width || imageData.height > viewerData.height;

    (0, _utilities.setStyle)(image, style);

    (0, _utilities.toggleClass)(image, _constants.CLASS_MOVE, movable && options.movable);

    if (done) {
      if ((this.viewing || this.zooming) && options.transition) {
        var onTransitionEnd = function onTransitionEnd() {
          _this3.imageRendering = false;
          done();
        };

        this.imageRendering = {
          abort: function abort() {
            (0, _utilities.removeListener)(image, _constants.EVENT_TRANSITION_END, onTransitionEnd);
          }
        };

        (0, _utilities.addListener)(image, _constants.EVENT_TRANSITION_END, onTransitionEnd, {
          once: true
        });
      } else {
        done();
      }
    }
  },
  resetImage: function resetImage() {
    // this.image only defined after viewed
    if (this.viewing || this.viewed) {
      var image = this.image;


      if (this.viewing) {
        this.viewing.abort();
      }

      image.parentNode.removeChild(image);
      this.image = null;
    }
  }
};

/***/ }),

/***/ 3048:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _constants = __webpack_require__(1626);

var _utilities = __webpack_require__(1654);

exports.default = {
  bind: function bind() {
    this.setEventHandlers();
  },
  unbind: function unbind() {
    this.setEventHandlers(false);
  },
  setEventHandlers: function setEventHandlers(on) {
    on = on !== false;

    var method = on ? _utilities.addListener : _utilities.removeListener;

    if (on) {
      this.onClick = this.click.bind(this);
      this.onWheel = this.wheel.bind(this);
      this.onDragStart = this.dragstart.bind(this);
      this.onCanvasClick = this.canvasClick.bind(this);

      if (_constants.WINDOW.GestureEvent) {
        // Safari (macOS & iOS)
        this.onGestureStart = this.gesturestart.bind(this);
        this.onGestureChange = this.gesturechange.bind(this);
        this.onGestureEnd = this.gestureend.bind(this);
      }
      this.onPointerDown = this.pointerdown.bind(this);
      this.onPointerMove = this.pointermove.bind(this);
      this.onPointerUp = this.pointerup.bind(this);

      this.onKeyDown = this.keydown.bind(this);
      this.onKeyUp = this.keyup.bind(this);
      this.onKeyPress = this.keypress.bind(this);
      this.onResize = this.resize.bind(this);
      this.onMouseEnterHeaderFooter = this.mouseenterHeaderFooter.bind(this);
      this.onMouseLeaveHeaderFooter = this.mouseleaveHeaderFooter.bind(this);
      this.onMouseEnterLeftRight = this.mouseenterLeftRight.bind(this);
      this.onMouseLeaveLeftRight = this.mouseleaveLeftRight.bind(this);
    }

    var canvas = this.canvas,
        element = this.element,
        viewer = this.viewer;


    method(viewer, _constants.EVENT_CLICK, this.onClick);
    method(viewer, _constants.EVENT_WHEEL, this.onWheel);
    method(viewer, _constants.EVENT_DRAG_START, this.onDragStart);

    method(canvas, _constants.EVENT_CLICK, this.onCanvasClick);

    if (_constants.WINDOW.GestureEvent) {
      // Safari (macOS & iOS)
      method(element.ownerDocument, _constants.EVENT_GESTURE_START, this.onGestureStart);
      method(element.ownerDocument, _constants.EVENT_GESTURE_CHANGE, this.onGestureChange);
      method(element.ownerDocument, _constants.EVENT_GESTURE_END, this.onGestureEnd);
    }
    method(canvas, _constants.EVENT_POINTER_DOWN, this.onPointerDown);
    method(element.ownerDocument, _constants.EVENT_POINTER_MOVE, this.onPointerMove);
    method(element.ownerDocument, _constants.EVENT_POINTER_UP, this.onPointerUp);

    method(window, _constants.EVENT_RESIZE, this.onResize);
    // Use capture to be able to block key propagation when viewer is shown
    method(element.ownerDocument, _constants.EVENT_KEY_DOWN, this.onKeyDown, { capture: true });
    method(element.ownerDocument, _constants.EVENT_KEY_UP, this.onKeyUp, { capture: true });
    method(element.ownerDocument, _constants.EVENT_KEY_PRESS, this.onKeyPress, { capture: true });
    // Show controls on hover
    method(this.header, _constants.EVENT_MOUSE_ENTER, this.onMouseEnterHeaderFooter);
    method(this.footer, _constants.EVENT_MOUSE_ENTER, this.onMouseEnterHeaderFooter);
    method(this.left, _constants.EVENT_MOUSE_ENTER, this.onMouseEnterLeftRight);
    method(this.right, _constants.EVENT_MOUSE_ENTER, this.onMouseEnterLeftRight);
    method(this.header, _constants.EVENT_MOUSE_LEAVE, this.onMouseLeaveHeaderFooter);
    method(this.footer, _constants.EVENT_MOUSE_LEAVE, this.onMouseLeaveHeaderFooter);
    method(this.left, _constants.EVENT_MOUSE_LEAVE, this.onMouseLeaveLeftRight);
    method(this.right, _constants.EVENT_MOUSE_LEAVE, this.onMouseLeaveLeftRight);
  }
};

/***/ }),

/***/ 3049:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _bowser = __webpack_require__(382);

var _bowser2 = _interopRequireDefault(_bowser);

var _debounce2 = __webpack_require__(275);

var _debounce3 = _interopRequireDefault(_debounce2);

var _constants = __webpack_require__(1626);

var _utilities = __webpack_require__(1654);

var _browserHelper = __webpack_require__(34);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var isControlCmdPressed = function isControlCmdPressed(e) {
  return _bowser2.default.mac && e.metaKey || !_bowser2.default.mac && e.ctrlKey;
};
var debounceToggleCls = (0, _debounce3.default)(_utilities.toggleClass, 200);
exports.default = {
  click: function click(_ref) {
    var target = _ref.target;
    var options = this.options,
        imageData = this.imageData;

    var action = (0, _utilities.getData)(target, _constants.DATA_ACTION);
    var evtType = _constants.UX_EVENT_TYPE.BUTTON_CLICK;

    switch (action) {
      case 'mix':
        if (this.played) {
          this.stop();
        } else if (options.inline) {
          if (this.fulled) {
            this.exit();
          } else {
            this.full();
          }
        } else {
          this.hide({ evtType: evtType });
        }

        break;

      case 'hide':
        this.hide({ evtType: _constants.UX_EVENT_TYPE.BACKGROUND_CLICK });
        break;

      case 'view':
        this.view((0, _utilities.getData)(target, 'index'));
        break;

      case 'zoom-in':
        this.zoom(options.zoomRatio, { evtType: evtType }, true);
        break;

      case 'zoom-out':
        this.zoom(-options.zoomRatio, { evtType: evtType }, true);
        break;

      case 'one-to-one':
        this.toggle({ evtType: evtType });
        break;

      case 'reset':
        this.reset();
        break;

      case 'prev':
        this.prev({ evtType: evtType }, options.loop);
        break;

      case 'play':
        this.play(options.fullscreen);
        break;

      case 'next':
        this.next({ evtType: evtType }, options.loop);
        break;

      case 'rotate-left':
        this.rotate(-90);
        break;

      case 'rotate-right':
        this.rotate(90);
        break;

      case 'flip-horizontal':
        this.scaleX(-imageData.scaleX || -1);
        break;

      case 'flip-vertical':
        this.scaleY(-imageData.scaleY || -1);
        break;

      default:
        if (this.played) {
          this.stop();
        }
    }
  },
  canvasClick: function canvasClick(event) {
    var _this = this;

    if (this.pointUpTimer) {
      window.clearTimeout(this.pointUpTimer);
      this.pointUpTimer = null;
      return;
    }
    var toggleOnDblclick = this.options.toggleOnDblclick;

    if (!toggleOnDblclick) {
      this.hide({ evtType: _constants.UX_EVENT_TYPE.CANVAS_CLICK });
      return;
    }

    this.canvasClickCount = (this.canvasClickCount || 0) + 1;
    if (this.canvasClickCount === 1) {
      this.canvasTimer = window.setTimeout(function () {
        _this.hide({ evtType: _constants.UX_EVENT_TYPE.CANVAS_CLICK });
      }, 200);
      return;
    }

    if (this.canvasTimer) {
      window.clearTimeout(this.canvasTimer);
      this.canvasTimer = null;
    }
    this.toggle({ evtType: _constants.UX_EVENT_TYPE.CANVAS_DBL_CLICK });
    this.canvasClickCount = 0;
  },
  load: function load() {
    var _this2 = this;

    var isSwitch = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : false;

    if (this.timeout) {
      clearTimeout(this.timeout);
      this.timeout = false;
    }

    var element = this.element,
        options = this.options,
        image = this.image,
        index = this.index,
        viewerData = this.viewerData;


    (0, _utilities.removeClass)(image, _constants.CLASS_INVISIBLE);

    if (options.loading) {
      (0, _utilities.removeClass)(this.canvas, _constants.CLASS_LOADING);
    }

    var cssText = 'height:0;' + ('margin-left:' + viewerData.width / 2 + 'px;') + ('margin-top:' + viewerData.height / 2 + 'px;') + 'max-width:none!important;' + 'position:absolute;' + 'width:0;';

    image.style.cssText = cssText;

    this.initImage(function () {
      if (isSwitch) {
        (0, _utilities.removeClass)(image, _constants.CLASS_TRANSITION);
        // 切换操作结束后
        _this2.viewed = true;
        _this2.initLongImg();
        debounceToggleCls(image, _constants.CLASS_TRANSITION, options.transition);
      } else {
        (0, _utilities.toggleClass)(image, _constants.CLASS_TRANSITION, options.transition);
      }

      _this2.renderImage(function () {
        _this2.viewed = true;
        _this2.viewing = false;
        _this2.initLongImg();
        if ((0, _utilities.isFunction)(options.viewed)) {
          (0, _utilities.addListener)(element, _constants.EVENT_VIEWED, options.viewed, {
            once: true
          });
        }

        (0, _utilities.dispatchEvent)(element, _constants.EVENT_VIEWED, {
          originalImage: _this2.images[index],
          index: index,
          image: image
        });
      });
    });
  },
  loadImage: function loadImage(e) {
    var image = e.target;
    var parent = image.parentNode;
    var parentWidth = parent.offsetWidth || 30;
    var parentHeight = parent.offsetHeight || 50;
    var filled = !!(0, _utilities.getData)(image, 'filled');

    (0, _utilities.getImageNaturalSizes)(image, function (naturalWidth, naturalHeight) {
      var aspectRatio = naturalWidth / naturalHeight;
      var width = parentWidth;
      var height = parentHeight;

      if (parentHeight * aspectRatio > parentWidth) {
        if (filled) {
          width = parentHeight * aspectRatio;
        } else {
          height = parentWidth / aspectRatio;
        }
      } else if (filled) {
        height = parentWidth / aspectRatio;
      } else {
        width = parentHeight * aspectRatio;
      }

      (0, _utilities.setStyle)(image, (0, _utilities.assign)({
        width: width,
        height: height
      }, (0, _utilities.getTransforms)({
        translateX: (parentWidth - width) / 2,
        translateY: (parentHeight - height) / 2
      })));
    });
  },
  filterKey: function filterKey(e) {
    if (this.isShown) {
      e.preventDefault();
      e.stopPropagation();
    }
  },
  keydown: function keydown(e) {
    var options = this.options;


    this.filterKey(e);

    if (!this.fulled || !options.keyboard) {
      return;
    }

    var evtType = _constants.UX_EVENT_TYPE.KEYBOARD;

    switch (e.keyCode || e.which || e.charCode) {
      // Escape
      case 27:
        if (this.played) {
          this.stop();
        } else if (options.inline) {
          if (this.fulled) {
            this.exit();
          }
        } else {
          this.hide({ evtType: evtType });
        }

        break;

      // Space
      case 32:
        if (this.played) {
          this.stop();
        }

        break;

      // ArrowLeft
      case 37:
        this.prev({ evtType: evtType }, options.loop);
        break;

      // ArrowUp
      case 38:
        // Prevent scroll on Firefox
        e.preventDefault();

        // Zoom in
        this.zoom(options.zoomRatio, { evtType: evtType }, true);
        break;

      // ArrowRight
      case 39:
        this.next({ evtType: evtType }, options.loop);
        break;

      // ArrowDown
      case 40:
        // Prevent scroll on Firefox
        e.preventDefault();

        // Zoom out
        this.zoom(-options.zoomRatio, { evtType: evtType }, true);
        break;

      // Ctrl/⌘ + 0
      case 48:
      // Fall through

      // Ctrl/⌘ + 1
      // eslint-disable-next-line no-fallthrough
      case 49:
        if (isControlCmdPressed(e)) {
          e.preventDefault();
          this.toggle({ evtType: evtType });
        }
        break;

      // Ctrl/⌘ + '-'
      case 187:
        if (isControlCmdPressed(e)) {
          this.zoom(options.zoomRatio, { evtType: evtType }, true);
        }
        break;

      // Ctrl/⌘ + '='
      case 189:
        if (isControlCmdPressed(e)) {
          this.zoom(-options.zoomRatio, { evtType: evtType }, true);
        }
        break;

      default:
    }
  },
  keyup: function keyup(e) {
    this.filterKey(e);
  },
  keypress: function keypress(e) {
    this.filterKey(e);
  },
  dragstart: function dragstart(e) {
    if (e.target.tagName.toLowerCase() === 'img') {
      e.preventDefault();
    }
  },


  // For Safari (macOS & iOS)
  gesturestart: function gesturestart(e) {
    this.lastGestureEventScale = 1;
    this.gesture(e);
  },
  gesturechange: function gesturechange(e) {
    this.gesture(e);
  },
  gestureend: function gestureend(e) {
    this.gesture(e);
    this.lastGestureEventScale = null;
  },
  gesture: function gesture(e) {
    var options = this.options;

    var delta = e.scale - this.lastGestureEventScale;

    e.preventDefault();

    if (Math.abs(delta) > options.zoomRatio) {
      delta = (delta < 0 ? -1 : 1) * options.zoomRatio;
      this.zoom(delta, { evtType: _constants.UX_EVENT_TYPE.PINCH }, true);
      this.lastGestureEventScale += delta;
    }
  },
  pointerdown: function pointerdown(e) {
    var options = this.options,
        pointers = this.pointers;


    if (!this.viewed || this.showing || this.viewing || this.hiding) {
      return;
    }

    // This line is required for preventing page zooming in iOS browsers
    e.preventDefault();

    if (e.changedTouches) {
      (0, _utilities.forEach)(e.changedTouches, function (touch) {
        pointers[touch.identifier] = (0, _utilities.getPointer)(touch);
      });
    } else {
      pointers[e.pointerId || 0] = (0, _utilities.getPointer)(e);
    }

    var action = options.movable ? _constants.ACTION_MOVE : false;

    if (Object.keys(pointers).length > 1) {
      action = _constants.ACTION_ZOOM;
    } else if ((e.pointerType === 'touch' || e.type === 'touchstart') && this.isSwitchable()) {
      action = _constants.ACTION_SWITCH;
    }

    if (options.transition && (action === _constants.ACTION_MOVE || action === _constants.ACTION_ZOOM)) {
      (0, _utilities.removeClass)(this.image, _constants.CLASS_TRANSITION);
    }

    this.action = action;
  },
  pointermove: function pointermove(e) {
    var pointers = this.pointers,
        action = this.action;


    if (!this.viewed || !action) {
      return;
    }

    e.preventDefault();
    this.pointerMove = true;

    if (e.changedTouches) {
      (0, _utilities.forEach)(e.changedTouches, function (touch) {
        (0, _utilities.assign)(pointers[touch.identifier], (0, _utilities.getPointer)(touch, true));
      });
    } else {
      (0, _utilities.assign)(pointers[e.pointerId || 0], (0, _utilities.getPointer)(e, true));
    }

    this.change(e);
  },
  pointerup: function pointerup(e) {
    var _this3 = this;

    var action = this.action,
        pointers = this.pointers;


    if (e.changedTouches) {
      (0, _utilities.forEach)(e.changedTouches, function (touch) {
        delete pointers[touch.identifier];
      });
    } else {
      delete pointers[e.pointerId || 0];
    }

    if (!action) {
      return;
    }

    e.preventDefault();

    // pointup之后会触发click事件
    // 图片单击会退出viewer模式
    if (this.pointerMove) {
      this.pointUpTimer = window.setTimeout(function () {
        _this3.pointUpTimer = null;
      }, 200);
      this.pointerMove = false;
    }

    if (this.options.transition && (action === _constants.ACTION_MOVE || action === _constants.ACTION_ZOOM)) {
      (0, _utilities.addClass)(this.image, _constants.CLASS_TRANSITION);
    }

    this.action = false;
  },
  resize: function resize() {
    var _this4 = this;

    if (!this.isShown || this.hiding) {
      return;
    }

    this.initContainer();
    this.initViewer();
    this.renderViewer();
    this.renderList();

    if (this.viewed) {
      this.initImage(function () {
        _this4.renderImage();
        _this4.initLongImg();
      });
    }

    if (this.played) {
      if (this.options.fullscreen && this.fulled && !document.fullscreenElement && !document.mozFullScreenElement && !document.webkitFullscreenElement && !document.msFullscreenElement) {
        this.stop();
        return;
      }

      (0, _utilities.forEach)(this.player.getElementsByTagName('img'), function (image) {
        (0, _utilities.addListener)(image, _constants.EVENT_LOAD, _this4.loadImage.bind(_this4), {
          once: true
        });
        (0, _utilities.dispatchEvent)(image, _constants.EVENT_LOAD);
      });
    }
  },
  wheel: function wheel(e) {
    if (!this.viewed) {
      return;
    }

    e.preventDefault();
    if (_browserHelper2.default.modernIE) {
      // ie11下放大缩小,双指放大缩小时系数固定为97.5/-97.5
      if (Math.abs(e.deltaY) === 97.5) {
        this._wheelThrottled(e); // 放大缩小
      } else {
        e.returnValue = false;
        this._scrollThrottled(e); // 滚动
      }
    } else {
      // 放大缩小时deltaY都是小数
      if (String(e.deltaY).indexOf('.') > -1) {
        this._wheelThrottled(e); // 放大缩小
      } else {
        this._scrollThrottled(e); // 滚动
      }
    }
  },
  _wheelDelta: function _wheelDelta(e) {
    var delta = 1;
    if (e.deltaY) {
      delta = e.deltaY > 0 ? 1 : -1;
    } else if (e.wheelDelta) {
      delta = -e.wheelDelta / 120;
    } else if (e.detail) {
      delta = e.detail > 0 ? 1 : -1;
    }
    return delta;
  },
  _wheel: function _wheel(e) {
    var ratio = Number(this.options.zoomRatio) || 0.1;
    var delta = this._wheelDelta(e);
    this.zoom(-delta * ratio, { evtType: _constants.UX_EVENT_TYPE.WHEEL }, true, e);
  },
  _scroll: function _scroll(e) {
    var offsetX = -e.deltaX * _constants.WHEEL_SCROLL_SPEED_FACTOR;
    var offsetY = -e.deltaY * _constants.WHEEL_SCROLL_SPEED_FACTOR;
    this.move({ offsetX: offsetX, offsetY: offsetY }, { evtType: _constants.UX_EVENT_TYPE.WHEEL });
  },
  mouseenterHeaderFooter: function mouseenterHeaderFooter() {
    if (this.initialControlsVisibleTimeout) {
      clearTimeout(this.initialControlsVisibleTimeout);
      this.initialControlsVisibleTimeout = null;
    }
    (0, _utilities.addClass)(this.header, _constants.CLASS_VISIBLE);
    (0, _utilities.addClass)(this.footer, _constants.CLASS_VISIBLE);
  },
  mouseenterLeftRight: function mouseenterLeftRight() {
    if (this.initialControlsVisibleTimeout) {
      clearTimeout(this.initialControlsVisibleTimeout);
      this.initialControlsVisibleTimeout = null;
    }
    (0, _utilities.addClass)(this.left, _constants.CLASS_VISIBLE);
    (0, _utilities.addClass)(this.right, _constants.CLASS_VISIBLE);
  },
  mouseleaveHeaderFooter: function mouseleaveHeaderFooter() {
    if (this.options.autohideControls) {
      (0, _utilities.removeClass)(this.header, _constants.CLASS_VISIBLE);
      (0, _utilities.removeClass)(this.footer, _constants.CLASS_VISIBLE);
    }
  },
  mouseleaveLeftRight: function mouseleaveLeftRight() {
    if (this.options.autohideControls) {
      (0, _utilities.removeClass)(this.left, _constants.CLASS_VISIBLE);
      (0, _utilities.removeClass)(this.right, _constants.CLASS_VISIBLE);
    }
  }
};

/***/ }),

/***/ 3050:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _constants = __webpack_require__(1626);

var _utilities = __webpack_require__(1654);

exports.default = {
  /** Show the viewer (only available in modal mode)
   * @param {boolean} [immediate=false] - Indicates if show the viewer immediately or not.
   * @returns {Viewer} this
   */
  show: function show() {
    var immediate = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : false;
    var element = this.element,
        options = this.options;


    if (options.inline || this.showing || this.isShown || this.showing) {
      return this;
    }

    if (!this.ready) {
      this.build();

      if (this.ready) {
        this.show(immediate);
      }

      return this;
    }

    if ((0, _utilities.isFunction)(options.show)) {
      (0, _utilities.addListener)(element, _constants.EVENT_SHOW, options.show, {
        once: true
      });
    }

    if ((0, _utilities.dispatchEvent)(element, _constants.EVENT_SHOW) === false || !this.ready) {
      return this;
    }

    if (this.hiding) {
      this.transitioning.abort();
    }

    this.showing = true;
    this.open();

    var viewer = this.viewer;


    (0, _utilities.removeClass)(viewer, _constants.CLASS_HIDE);

    if (options.transition && !immediate) {
      var shown = this.shown.bind(this);

      this.transitioning = {
        abort: function abort() {
          (0, _utilities.removeListener)(viewer, _constants.EVENT_TRANSITION_END, shown);
          (0, _utilities.removeClass)(viewer, _constants.CLASS_IN);
        }
      };

      (0, _utilities.addClass)(viewer, _constants.CLASS_TRANSITION);

      // Force reflow to enable CSS3 transition
      // eslint-disable-next-line
      viewer.offsetWidth;
      (0, _utilities.addListener)(viewer, _constants.EVENT_TRANSITION_END, shown, {
        once: true
      });
      (0, _utilities.addClass)(viewer, _constants.CLASS_IN);
    } else {
      (0, _utilities.addClass)(viewer, _constants.CLASS_IN);
      this.shown();
    }

    return this;
  },


  /**
   * Hide the viewer (only available in modal mode)
   * @param {boolean} [immediate=false] - Indicates if hide the viewer immediately or not.
   * @returns {Viewer} this
   */
  hide: function hide(_ref) {
    var evtType = _ref.evtType;
    var immediate = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;

    if (this.imageData.height === 0 && this.imageData.width === 0) {
      // 有可能图片查看器不能关闭，这个条件就是图片查看器出问题的时候的表现，所以加上代码强行关闭
      this.zoomTo(0);
      window.Raven.captureException('IMAGE_VIEWER_CAN_NOT_CLOSE');
    }

    var element = this.element,
        options = this.options;


    if (options.inline || this.hiding || !(this.isShown || this.showing)) {
      return this;
    }

    if (!this.viewed) {
      immediate = true;
    }

    if ((0, _utilities.isFunction)(options.hide)) {
      (0, _utilities.addListener)(element, _constants.EVENT_HIDE, options.hide, {
        once: true
      });
    }

    if ((0, _utilities.dispatchEvent)(element, _constants.EVENT_HIDE) === false) {
      return this;
    }

    if (this.showing) {
      this.transitioning.abort();
    }

    this.hiding = true;

    if (this.played) {
      this.stop();
    } else if (this.viewing) {
      this.viewing.abort();
    }

    var viewer = this.viewer;


    if (options.transition && !immediate) {
      var hidden = this.hidden.bind(this);
      var hide = function hide() {
        (0, _utilities.addListener)(viewer, _constants.EVENT_TRANSITION_END, hidden, {
          once: true
        });
        (0, _utilities.removeClass)(viewer, _constants.CLASS_IN);
      };

      this.transitioning = {
        abort: function abort() {
          if (this.viewed) {
            (0, _utilities.removeListener)(this.image, _constants.EVENT_TRANSITION_END, hide);
          } else {
            (0, _utilities.removeListener)(viewer, _constants.EVENT_TRANSITION_END, hidden);
          }
        }
      };

      if (this.viewed) {
        this.zoomTo(0, false, false, true, hide);
      } else {
        hide();
      }
    } else {
      (0, _utilities.removeClass)(viewer, _constants.CLASS_IN);
      this.hidden();
    }

    this.report(evtType, _constants.UX_ACTION_TYPE.HIDE);

    return this;
  },


  /**
   * View one of the images with image's index
   * @param {number} index - The index of the image to view.
   * @returns {Viewer} this
   */
  view: function view() {
    var _this = this;

    var index = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : this.options.initialViewIndex;
    var isSwitch = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;

    index = Number(index) || 0;

    if (!this.isShown) {
      this.index = index;
      return this.show();
    }

    if (this.hiding || this.played || index < 0 || index >= this.length || this.viewed && index === this.index) {
      return this;
    }

    if (this.viewing) {
      this.viewing.abort();
    }

    var element = this.element,
        options = this.options,
        title = this.title,
        canvas = this.canvas;

    var item = this.items[index];
    var img = item.querySelector('img');
    var url = (0, _utilities.getData)(img, 'originalUrl');
    var alt = img.getAttribute('alt');
    var image = document.createElement('img');

    image.src = url;
    image.alt = alt;

    if ((0, _utilities.isFunction)(options.view)) {
      (0, _utilities.addListener)(element, _constants.EVENT_VIEW, options.view, {
        once: true
      });
    }

    if ((0, _utilities.dispatchEvent)(element, _constants.EVENT_VIEW, {
      originalImage: this.images[index],
      index: index,
      image: image
    }) === false || !this.isShown || this.hiding || this.played) {
      return this;
    }

    this.image = image;

    (0, _utilities.removeClass)(this.items[this.index], _constants.CLASS_ACTIVE);
    (0, _utilities.addClass)(item, _constants.CLASS_ACTIVE);
    this.viewed = false;
    this.index = index;
    this.imageData = {};
    (0, _utilities.addClass)(image, _constants.CLASS_INVISIBLE);

    if (options.loading) {
      (0, _utilities.addClass)(canvas, _constants.CLASS_LOADING);
    }

    canvas.innerHTML = '';
    canvas.appendChild(image);

    var viewerIndex = document.querySelector('.' + _constants.NAMESPACE + '-index');
    viewerIndex.innerText = this.index + 1 + ' / ' + this.items.length;
    (0, _utilities.toggleClass)(this.left, _constants.CLASS_HIDDEN, this.index === 0);
    (0, _utilities.toggleClass)(this.right, _constants.CLASS_HIDDEN, this.index === this.items.length - 1);

    // Center current item
    this.renderList();

    // Clear title
    title.innerHTML = '';

    // Generate title after viewed
    var onViewed = function onViewed() {
      var imageData = _this.imageData;

      var render = Array.isArray(options.title) ? options.title[1] : options.title;

      title.innerHTML = (0, _utilities.isFunction)(render) ? render.call(_this, image, imageData) : alt + ' (' + imageData.naturalWidth + ' \xD7 ' + imageData.naturalHeight + ')';
    };
    var onLoad = void 0;

    (0, _utilities.addListener)(element, _constants.EVENT_VIEWED, onViewed, {
      once: true
    });

    this.viewing = {
      abort: function abort() {
        (0, _utilities.removeListener)(element, _constants.EVENT_VIEWED, onViewed);

        if (image.complete) {
          if (this.imageRendering) {
            this.imageRendering.abort();
          } else if (this.imageInitializing) {
            this.imageInitializing.abort();
          }
        } else {
          (0, _utilities.removeListener)(image, _constants.EVENT_LOAD, onLoad);

          if (this.timeout) {
            clearTimeout(this.timeout);
          }
        }
      }
    };

    if (image.complete) {
      this.load(isSwitch);
    } else {
      (0, _utilities.addListener)(image, _constants.EVENT_LOAD, onLoad = this.load.bind(this), {
        once: true
      });

      if (this.timeout) {
        clearTimeout(this.timeout);
      }

      // Make the image visible if it fails to load within 1s
      this.timeout = setTimeout(function () {
        (0, _utilities.removeClass)(image, _constants.CLASS_INVISIBLE);
        _this.timeout = false;
      }, 1000);
    }

    return this;
  },


  /**
   * View the previous image
   * @param {boolean} [loop=false] - Indicate if view the last one
   * when it is the first one at present.
   * @returns {Viewer} this
   */
  prev: function prev(_ref2) {
    var evtType = _ref2.evtType;
    var loop = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;

    var index = this.index - 1;

    if (index < 0) {
      index = loop ? this.length - 1 : 0;
    }

    this.switchImageAnimation(index);
    this.report(evtType, _constants.UX_ACTION_TYPE.PREV);

    return this;
  },


  /**
   * View the next image
   * @param {boolean} [loop=false] - Indicate if view the first one
   * when it is the last one at present.
   * @returns {Viewer} this
   */
  next: function next(_ref3) {
    var evtType = _ref3.evtType;
    var loop = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;

    var maxIndex = this.length - 1;
    var index = this.index + 1;

    if (index > maxIndex) {
      index = loop ? 0 : maxIndex;
    }

    this.switchImageAnimation(index);
    this.report(evtType, _constants.UX_ACTION_TYPE.NEXT);

    return this;
  },


  /**
   * Move the image with relative offsets.
   * @param {number} offsetX - The relative offset distance on the x-axis.
   * @param {number} offsetY - The relative offset distance on the y-axis.
   * @returns {Viewer} this
   */
  move: function move() {
    var _ref4 = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {},
        _ref4$offsetX = _ref4.offsetX,
        offsetX = _ref4$offsetX === undefined ? 0 : _ref4$offsetX,
        _ref4$offsetY = _ref4.offsetY,
        offsetY = _ref4$offsetY === undefined ? 0 : _ref4$offsetY;

    var _ref5 = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {},
        evtType = _ref5.evtType;

    var _imageData = this.imageData,
        width = _imageData.width,
        height = _imageData.height,
        left = _imageData.left,
        top = _imageData.top;

    var _getViewerDimension = this.getViewerDimension(),
        viewerWidth = _getViewerDimension.width,
        viewerHeight = _getViewerDimension.height;

    var xMovable = width > viewerWidth;
    var x = xMovable ? (0, _utilities.numRange)(left + Number(offsetX), viewerWidth - width, 0) : (viewerWidth - width) / 2;
    var yMovable = height > viewerHeight;
    var y = yMovable ? (0, _utilities.numRange)(top + Number(offsetY), viewerHeight - height, 0) : (viewerHeight - height) / 2;

    this.moveTo(x, y);

    if (xMovable || yMovable) {
      this.reportThrottledIfNecessary(evtType, _constants.UX_ACTION_TYPE.MOVE);
    }

    return this;
  },


  /**
   * Move the image to an absolute point.
   * @param {number} x - The x-axis coordinate.
   * @param {number} [y=x] - The y-axis coordinate.
   * @returns {Viewer} this
   */
  moveTo: function moveTo(x) {
    var y = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : x;
    var imageData = this.imageData;


    x = Number(x);
    y = Number(y);

    if (this.viewed && !this.played && this.options.movable) {
      var changed = false;

      if ((0, _utilities.isNumber)(x)) {
        imageData.left = x;
        changed = true;
      }

      if ((0, _utilities.isNumber)(y)) {
        imageData.top = y;
        changed = true;
      }

      if (changed) {
        this.renderImage();
      }
    }

    return this;
  },


  /**
   * Zoom the image with a relative ratio.
   * @param {number} ratio - The target ratio.
   * @param {boolean} [hasTooltip=false] - Indicates if it has a tooltip or not.
   * @param {Event} [_originalEvent=null] - The original event if any.
   * @returns {Viewer} this
   */
  zoom: function zoom(ratio, _ref6) {
    var evtType = _ref6.evtType;
    var hasTooltip = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : false;

    var _originalEvent = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : null;

    var _imageData2 = this.imageData,
        width = _imageData2.width,
        naturalWidth = _imageData2.naturalWidth;


    ratio = Number(ratio);
    ratio = ratio < 0 ? 1 / (1 - ratio) : 1 + ratio;

    this.zoomTo(width * ratio / naturalWidth, hasTooltip, _originalEvent);

    var actionType = _constants.UX_ACTION_TYPE.ZOOM_IN;

    if (ratio < 1) {
      // ensure the zoomed out image stick to the center
      this.move();
      actionType = _constants.UX_ACTION_TYPE.ZOOM_OUT;
    }

    this.reportThrottledIfNecessary(evtType, actionType);

    return this;
  },


  /**
   * Zoom the image to an absolute ratio.
   * @param {number} ratio - The target ratio.
   * @param {boolean} [hasTooltip=false] - Indicates if it has a tooltip or not.
   * @param {Event} [_originalEvent=null] - The original event if any.
   * @param {Event} [_zoomable=false] - Indicates if the current zoom is available or not.
   * @returns {Viewer} this
   */
  zoomTo: function zoomTo(ratio) {
    var hasTooltip = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;

    var _originalEvent = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : null;

    var _this2 = this;

    var _zoomable = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : false;

    var done = arguments[4];
    var element = this.element,
        options = this.options,
        pointers = this.pointers,
        imageData = this.imageData;


    ratio = Math.max(0, ratio);

    if ((0, _utilities.isNumber)(ratio) && this.viewed && !this.played && (_zoomable || options.zoomable)) {
      if (!_zoomable) {
        var minZoomRatio = Math.max(0.01, options.minZoomRatio);
        var maxZoomRatio = Math.min(100, options.maxZoomRatio);

        ratio = Math.min(Math.max(ratio, minZoomRatio), maxZoomRatio);
      }

      if (_originalEvent && ratio > 0.95 && ratio < 1.05) {
        ratio = 1;
      }

      var newWidth = imageData.naturalWidth * ratio;
      var newHeight = imageData.naturalHeight * ratio;
      var oldRatio = imageData.width / imageData.naturalWidth;

      if ((0, _utilities.isFunction)(options.zoom)) {
        (0, _utilities.addListener)(element, _constants.EVENT_ZOOM, options.zoom, {
          once: true
        });
      }

      if ((0, _utilities.dispatchEvent)(element, _constants.EVENT_ZOOM, {
        ratio: ratio,
        oldRatio: oldRatio,
        originalEvent: _originalEvent
      }) === false) {
        return this;
      }

      this.zooming = true;

      if (options.centerAtTriggeringPoint && _originalEvent && pointers && Object.keys(pointers).length) {
        var offset = (0, _utilities.getOffset)(this.viewer);
        var center = (0, _utilities.getPointersCenter)(pointers);

        // Zoom from the triggering point of the event
        imageData.left -= (newWidth - imageData.width) * ((center.pageX - offset.left - imageData.left) / imageData.width);
        imageData.top -= (newHeight - imageData.height) * ((center.pageY - offset.top - imageData.top) / imageData.height);
      } else {
        // Zoom from the center of the image
        imageData.left -= (newWidth - imageData.width) / 2;
        imageData.top -= (newHeight - imageData.height) / 2;
      }

      imageData.width = newWidth;
      imageData.height = newHeight;
      imageData.ratio = ratio;
      this.renderImage(function () {
        done && done();
        _this2.zooming = false;

        if ((0, _utilities.isFunction)(options.zoomed)) {
          (0, _utilities.addListener)(element, _constants.EVENT_ZOOMED, options.zoomed, {
            once: true
          });
        }

        (0, _utilities.dispatchEvent)(element, _constants.EVENT_ZOOMED, {
          ratio: ratio,
          oldRatio: oldRatio,
          originalEvent: _originalEvent
        });
      });

      if (hasTooltip) {
        this.tooltip();
      }
    }

    return this;
  },


  /**
   * Rotate the image with a relative degree.
   * @param {number} degree - The rotate degree.
   * @returns {Viewer} this
   */
  rotate: function rotate(degree) {
    this.rotateTo((this.imageData.rotate || 0) + Number(degree));

    return this;
  },


  /**
   * Rotate the image to an absolute degree.
   * @param {number} degree - The rotate degree.
   * @returns {Viewer} this
   */
  rotateTo: function rotateTo(degree) {
    var imageData = this.imageData;


    degree = Number(degree);

    if ((0, _utilities.isNumber)(degree) && this.viewed && !this.played && this.options.rotatable) {
      imageData.rotate = degree;
      this.renderImage();
    }

    return this;
  },


  /**
   * Scale the image on the x-axis.
   * @param {number} scaleX - The scale ratio on the x-axis.
   * @returns {Viewer} this
   */
  scaleX: function scaleX(_scaleX) {
    this.scale(_scaleX, this.imageData.scaleY);

    return this;
  },


  /**
   * Scale the image on the y-axis.
   * @param {number} scaleY - The scale ratio on the y-axis.
   * @returns {Viewer} this
   */
  scaleY: function scaleY(_scaleY) {
    this.scale(this.imageData.scaleX, _scaleY);

    return this;
  },


  /**
   * Scale the image.
   * @param {number} scaleX - The scale ratio on the x-axis.
   * @param {number} [scaleY=scaleX] - The scale ratio on the y-axis.
   * @returns {Viewer} this
   */
  scale: function scale(scaleX) {
    var scaleY = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : scaleX;
    var imageData = this.imageData;


    scaleX = Number(scaleX);
    scaleY = Number(scaleY);

    if (this.viewed && !this.played && this.options.scalable) {
      var changed = false;

      if ((0, _utilities.isNumber)(scaleX)) {
        imageData.scaleX = scaleX;
        changed = true;
      }

      if ((0, _utilities.isNumber)(scaleY)) {
        imageData.scaleY = scaleY;
        changed = true;
      }

      if (changed) {
        this.renderImage();
      }
    }

    return this;
  },


  /**
   * Play the images
   * @param {boolean} [fullscreen=false] - Indicate if request fullscreen or not.
   * @returns {Viewer} this
   */
  play: function play() {
    var _this3 = this;

    var fullscreen = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : false;

    if (!this.isShown || this.played) {
      return this;
    }

    var options = this.options,
        player = this.player;

    var onLoad = this.loadImage.bind(this);
    var list = [];
    var total = 0;
    var index = 0;

    this.played = true;
    this.onLoadWhenPlay = onLoad;

    if (fullscreen) {
      this.requestFullscreen();
    }

    (0, _utilities.addClass)(player, _constants.CLASS_SHOW);
    (0, _utilities.forEach)(this.items, function (item, i) {
      var img = item.querySelector('img');
      var image = document.createElement('img');

      image.src = (0, _utilities.getData)(img, 'originalUrl');
      image.alt = img.getAttribute('alt');
      total += 1;
      (0, _utilities.addClass)(image, _constants.CLASS_FADE);
      (0, _utilities.toggleClass)(image, _constants.CLASS_TRANSITION, options.transition);

      if ((0, _utilities.hasClass)(item, _constants.CLASS_ACTIVE)) {
        (0, _utilities.addClass)(image, _constants.CLASS_IN);
        index = i;
      }

      list.push(image);
      (0, _utilities.addListener)(image, _constants.EVENT_LOAD, onLoad, {
        once: true
      });
      player.appendChild(image);
    });

    if ((0, _utilities.isNumber)(options.interval) && options.interval > 0) {
      var play = function play() {
        _this3.playing = setTimeout(function () {
          (0, _utilities.removeClass)(list[index], _constants.CLASS_IN);
          index += 1;
          index = index < total ? index : 0;
          (0, _utilities.addClass)(list[index], _constants.CLASS_IN);
          play();
        }, options.interval);
      };

      if (total > 1) {
        play();
      }
    }

    return this;
  },


  // Stop play
  stop: function stop() {
    var _this4 = this;

    if (!this.played) {
      return this;
    }

    var player = this.player;


    this.played = false;
    clearTimeout(this.playing);
    (0, _utilities.forEach)(player.getElementsByTagName('img'), function (image) {
      (0, _utilities.removeListener)(image, _constants.EVENT_LOAD, _this4.onLoadWhenPlay);
    });
    (0, _utilities.removeClass)(player, _constants.CLASS_SHOW);
    player.innerHTML = '';
    this.exitFullscreen();

    return this;
  },


  // Enter modal mode (only available in inline mode)
  full: function full() {
    var _this5 = this;

    var options = this.options,
        viewer = this.viewer,
        image = this.image,
        list = this.list;


    if (!this.isShown || this.played || this.fulled || !options.inline) {
      return this;
    }

    this.fulled = true;
    this.open();
    (0, _utilities.addClass)(this.button, _constants.CLASS_FULLSCREEN_EXIT);

    if (options.transition) {
      (0, _utilities.removeClass)(list, _constants.CLASS_TRANSITION);

      if (this.viewed) {
        (0, _utilities.removeClass)(image, _constants.CLASS_TRANSITION);
      }
    }

    (0, _utilities.addClass)(viewer, _constants.CLASS_FIXED);
    viewer.setAttribute('style', '');
    (0, _utilities.setStyle)(viewer, {
      zIndex: options.zIndex
    });

    this.initContainer();
    this.viewerData = (0, _utilities.assign)({}, this.containerData);
    this.renderList();

    if (this.viewed) {
      this.initImage(function () {
        _this5.renderImage(function () {
          if (options.transition) {
            setTimeout(function () {
              (0, _utilities.addClass)(image, _constants.CLASS_TRANSITION);
              (0, _utilities.addClass)(list, _constants.CLASS_TRANSITION);
            }, 0);
          }
        });
      });
    }

    return this;
  },


  // Exit modal mode (only available in inline mode)
  exit: function exit() {
    var _this6 = this;

    var options = this.options,
        viewer = this.viewer,
        image = this.image,
        list = this.list;


    if (!this.isShown || this.played || !this.fulled || !options.inline) {
      return this;
    }

    this.fulled = false;
    this.close();
    (0, _utilities.removeClass)(this.button, _constants.CLASS_FULLSCREEN_EXIT);

    if (options.transition) {
      (0, _utilities.removeClass)(list, _constants.CLASS_TRANSITION);

      if (this.viewed) {
        (0, _utilities.removeClass)(image, _constants.CLASS_TRANSITION);
      }
    }

    (0, _utilities.removeClass)(viewer, _constants.CLASS_FIXED);
    (0, _utilities.setStyle)(viewer, {
      zIndex: options.zIndexInline
    });

    this.viewerData = (0, _utilities.assign)({}, this.parentData);
    this.renderViewer();
    this.renderList();

    if (this.viewed) {
      this.initImage(function () {
        _this6.renderImage(function () {
          if (options.transition) {
            setTimeout(function () {
              (0, _utilities.addClass)(image, _constants.CLASS_TRANSITION);
              (0, _utilities.addClass)(list, _constants.CLASS_TRANSITION);
            }, 0);
          }
        });
      });
    }

    return this;
  },


  // Show the current ratio of the image with percentage
  tooltip: function tooltip() {
    var _this7 = this;

    var options = this.options,
        tooltipBox = this.tooltipBox,
        imageData = this.imageData;


    if (!this.viewed || this.played || !options.tooltip) {
      return this;
    }

    tooltipBox.textContent = Math.round(imageData.ratio * 100) + '%';

    if (!this.tooltipping) {
      if (options.transition) {
        if (this.fading) {
          (0, _utilities.dispatchEvent)(tooltipBox, _constants.EVENT_TRANSITION_END);
        }

        (0, _utilities.addClass)(tooltipBox, _constants.CLASS_SHOW);
        (0, _utilities.addClass)(tooltipBox, _constants.CLASS_FADE);
        (0, _utilities.addClass)(tooltipBox, _constants.CLASS_TRANSITION);

        // Force reflow to enable CSS3 transition
        // eslint-disable-next-line
        tooltipBox.offsetWidth;
        (0, _utilities.addClass)(tooltipBox, _constants.CLASS_IN);
      } else {
        (0, _utilities.addClass)(tooltipBox, _constants.CLASS_SHOW);
      }
    } else {
      clearTimeout(this.tooltipping);
    }

    this.tooltipping = setTimeout(function () {
      if (options.transition) {
        (0, _utilities.addListener)(tooltipBox, _constants.EVENT_TRANSITION_END, function () {
          (0, _utilities.removeClass)(tooltipBox, _constants.CLASS_SHOW);
          (0, _utilities.removeClass)(tooltipBox, _constants.CLASS_FADE);
          (0, _utilities.removeClass)(tooltipBox, _constants.CLASS_TRANSITION);
          _this7.fading = false;
        }, {
          once: true
        });

        (0, _utilities.removeClass)(tooltipBox, _constants.CLASS_IN);
        _this7.fading = true;
      } else {
        (0, _utilities.removeClass)(tooltipBox, _constants.CLASS_SHOW);
      }

      _this7.tooltipping = false;
    }, 1000);

    return this;
  },


  // Toggle the image size between its natural size and initial size
  toggle: function toggle(_ref7) {
    var evtType = _ref7.evtType;

    if (this.toolbarOneToOne) {
      this.zoomTo(this.initialImageData.ratio, true);
      this.report(evtType, _constants.UX_ACTION_TYPE.INITIAL_SIZE);
    } else {
      this.zoomTo(1, true);
      this.report(evtType, _constants.UX_ACTION_TYPE.ORIGINAL_SIZE);
    }

    this.toolbarOneToOne = !this.toolbarOneToOne;

    var element = document.querySelector('.' + _constants.NAMESPACE + '-icon-one-to-one');
    (0, _utilities.toggleClass)(element, _constants.CLASS_ACTIVE, this.toolbarOneToOne);
    if (this.toolbarOneToOne) {
      element.children[0].innerText = _constants.TOOLTIP.reset;
    } else {
      element.children[0].innerText = _constants.TOOLTIP['one-to-one'];
    }

    // ensure the zoomed out image stick to the center
    this.move();

    return this;
  },


  // Reset the image to its initial state
  reset: function reset() {
    if (this.viewed && !this.played) {
      this.imageData = (0, _utilities.assign)({}, this.initialImageData);
      this.renderImage();
    }
    return this;
  },


  // Update viewer when images changed
  update: function update() {
    var element = this.element,
        options = this.options,
        isImg = this.isImg;

    // Destroy viewer if the target image was deleted

    if (isImg && !element.parentNode) {
      return this.destroy();
    }

    var images = [];

    (0, _utilities.forEach)(isImg ? [element] : element.querySelectorAll('img'), function (image) {
      if (options.filter) {
        if (options.filter(image)) {
          images.push(image);
        }
      } else {
        images.push(image);
      }
    });

    if (!images.length) {
      return this;
    }

    this.images = images;
    this.length = images.length;

    if (this.ready) {
      var indexes = [];

      (0, _utilities.forEach)(this.items, function (item, i) {
        var img = item.querySelector('img');
        var image = images[i];

        if (image) {
          if (image.src !== img.src) {
            indexes.push(i);
          }
        } else {
          indexes.push(i);
        }
      });

      (0, _utilities.setStyle)(this.list, {
        width: 'auto'
      });

      this.initList();

      if (this.isShown) {
        if (this.length) {
          if (this.viewed) {
            var index = indexes.indexOf(this.index);

            if (index >= 0) {
              this.viewed = false;
              this.view(Math.max(this.index - (index + 1), 0));
            } else {
              (0, _utilities.addClass)(this.items[this.index], _constants.CLASS_ACTIVE);
            }
          }
        } else {
          this.image = null;
          this.viewed = false;
          this.index = 0;
          this.imageData = {};
          this.canvas.innerHTML = '';
          this.title.innerHTML = '';
        }
      }
    } else {
      this.build();
    }

    return this;
  },


  // Destroy the viewer
  destroy: function destroy() {
    var element = this.element,
        options = this.options;


    if (!(0, _utilities.getData)(element, _constants.NAMESPACE)) {
      return this;
    }

    this.destroyed = true;

    if (this.ready) {
      if (this.played) {
        this.stop();
      }

      if (options.inline) {
        if (this.fulled) {
          this.exit();
        }

        this.unbind();
      } else if (this.isShown) {
        if (this.viewing) {
          if (this.imageRendering) {
            this.imageRendering.abort();
          } else if (this.imageInitializing) {
            this.imageInitializing.abort();
          }
        }

        if (this.hiding) {
          this.transitioning.abort();
        }

        this.hidden();
      } else if (this.showing) {
        this.transitioning.abort();
        this.hidden();
      }

      this.ready = false;
      this.viewer.parentNode.removeChild(this.viewer);
    } else if (options.inline) {
      if (this.delaying) {
        this.delaying.abort();
      } else if (this.initializing) {
        this.initializing.abort();
      }
    }

    if (!options.inline) {
      (0, _utilities.removeListener)(element, _constants.EVENT_CLICK, this.onStart);
    }

    (0, _utilities.removeData)(element, _constants.NAMESPACE);
    return this;
  },
  isLongImg: function isLongImg() {
    return this.imageData.naturalHeight >= window.innerHeight && this.imageData.height < this.imageData.naturalHeight;
  },
  isWideImage: function isWideImage() {
    return this.imageData.naturalWidth >= window.innerWidth && this.imageData.width < this.imageData.naturalWidth;
  },
  initLongImg: function initLongImg() {
    if (this.initialImageZoom) {
      if (this.isWideImage()) {
        this.zoomTo(window.innerWidth / this.imageData.naturalWidth);
      } else {
        this.zoomTo(1);
      }
      this.move({ offsetX: 0, offsetY: this.imageData.naturalHeight / 2 });
      this.initialImageZoom = false;
    }
  },
  switchImageAnimation: function switchImageAnimation(index) {
    this.view(index, this.options.clearSwitchTransition);
    (0, _utilities.addClass)(this.indexing, _constants.CLASS_VISIBLE);
    this.debounceRemoveCls(this.indexing, _constants.CLASS_VISIBLE);
  },
  report: function report(evtType, actionType) {
    var report = this.options.report;

    if (report) {
      report({ evtType: evtType, actionType: actionType });
    }
  },
  reportThrottledIfNecessary: function reportThrottledIfNecessary(evtType, actionType) {
    if (!evtType) return;
    switch (evtType) {
      case _constants.UX_EVENT_TYPE.DRAG:
        this._reportDragThrottled(evtType, actionType);
        break;
      case _constants.UX_EVENT_TYPE.PINCH:
        this._reportPinchThrottled(evtType, actionType);
        break;
      case _constants.UX_EVENT_TYPE.WHEEL:
        this._reportPinchThrottled(evtType, actionType);
        break;
      default:
        this.report(evtType, actionType);
        break;
    }
  }
};

/***/ }),

/***/ 3051:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _constants = __webpack_require__(1626);

var _utilities = __webpack_require__(1654);

exports.default = {
  open: function open() {
    var body = this.body;


    (0, _utilities.addClass)(body, _constants.CLASS_OPEN);

    body.style.paddingRight = this.scrollbarWidth + (parseFloat(this.initialBodyPaddingRight) || 0) + 'px';
  },
  close: function close() {
    var body = this.body;


    (0, _utilities.removeClass)(body, _constants.CLASS_OPEN);
    body.style.paddingRight = this.initialBodyPaddingRight;
  },
  shown: function shown() {
    var element = this.element,
        options = this.options;


    this.fulled = true;
    this.isShown = true;
    this.render();
    this.bind();
    this.showing = false;

    if ((0, _utilities.isFunction)(options.shown)) {
      (0, _utilities.addListener)(element, _constants.EVENT_SHOWN, options.shown, {
        once: true
      });
    }

    if ((0, _utilities.dispatchEvent)(element, _constants.EVENT_SHOWN) === false) {
      return;
    }

    if (this.ready && this.isShown && !this.hiding) {
      this.view(this.index);
    }
  },
  hidden: function hidden() {
    var element = this.element,
        options = this.options;


    this.fulled = false;
    this.viewed = false;
    this.isShown = false;
    this.close();
    this.unbind();
    (0, _utilities.addClass)(this.viewer, _constants.CLASS_HIDE);
    this.resetList();
    this.resetImage();
    this.hiding = false;

    if (!this.destroyed) {
      if ((0, _utilities.isFunction)(options.hidden)) {
        (0, _utilities.addListener)(element, _constants.EVENT_HIDDEN, options.hidden, {
          once: true
        });
      }

      (0, _utilities.dispatchEvent)(element, _constants.EVENT_HIDDEN);
    }
  },
  requestFullscreen: function requestFullscreen() {
    var document = this.element.ownerDocument;

    if (this.fulled && !document.fullscreenElement && !document.mozFullScreenElement && !document.webkitFullscreenElement && !document.msFullscreenElement) {
      var documentElement = document.documentElement;


      if (documentElement.requestFullscreen) {
        documentElement.requestFullscreen();
      } else if (documentElement.msRequestFullscreen) {
        documentElement.msRequestFullscreen();
      } else if (documentElement.mozRequestFullScreen) {
        documentElement.mozRequestFullScreen();
      } else if (documentElement.webkitRequestFullscreen) {
        documentElement.webkitRequestFullscreen(Element.ALLOW_KEYBOARD_INPUT);
      }
    }
  },
  exitFullscreen: function exitFullscreen() {
    if (this.fulled) {
      var document = this.element.ownerDocument;

      if (document.exitFullscreen) {
        document.exitFullscreen();
      } else if (document.msExitFullscreen) {
        document.msExitFullscreen();
      } else if (document.mozCancelFullScreen) {
        document.mozCancelFullScreen();
      } else if (document.webkitExitFullscreen) {
        document.webkitExitFullscreen();
      }
    }
  },
  change: function change(e) {
    var options = this.options,
        pointers = this.pointers;
    var _pointers$Object$keys = pointers[Object.keys(pointers)[0]],
        startX = _pointers$Object$keys.startX,
        startY = _pointers$Object$keys.startY,
        endX = _pointers$Object$keys.endX,
        endY = _pointers$Object$keys.endY;

    var offsetX = endX - startX;
    var offsetY = endY - startY;

    switch (this.action) {
      // Move the current image
      case _constants.ACTION_MOVE:
        this.move({ offsetX: offsetX, offsetY: offsetY }, { evtType: _constants.UX_EVENT_TYPE.DRAG });
        break;

      // Zoom the current image
      case _constants.ACTION_ZOOM:
        this.zoom((0, _utilities.getMaxZoomRatio)(pointers), { evtType: _constants.UX_EVENT_TYPE.PINCH }, true, e);
        break;

      case _constants.ACTION_SWITCH:
        {
          this.action = 'switched';

          var absoluteOffsetX = Math.abs(offsetX);

          if (absoluteOffsetX > 1 && absoluteOffsetX > Math.abs(offsetY)) {
            // Empty `pointers` as `touchend` event will not be fired after swiped in iOS browsers.
            this.pointers = {};

            var evtType = _constants.UX_EVENT_TYPE.SWIPE;

            if (offsetX > 1) {
              this.prev({ evtType: evtType }, options.loop);
            } else if (offsetX < -1) {
              this.next({ evtType: evtType }, options.loop);
            }
          }

          break;
        }

      default:
    }

    // Override
    (0, _utilities.forEach)(pointers, function (p) {
      p.startX = p.endX;
      p.startY = p.endY;
    });
  },
  isSwitchable: function isSwitchable() {
    var imageData = this.imageData,
        viewerData = this.viewerData;


    return this.length > 1 && imageData.left >= 0 && imageData.top >= 0 && imageData.width <= viewerData.width && imageData.height <= viewerData.height;
  }
};

/***/ }),

/***/ 3052:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ })

}]);
//# sourceMappingURL=https://s3.pstatp.com/eesz/resource/bear/js/embed-sheet~image-upload.d85d92394202e11ab2dc.js.map