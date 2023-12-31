(window["webpackJsonp"] = window["webpackJsonp"] || []).push([[2],{

/***/ 1573:
/***/ (function(module, exports, __webpack_require__) {

/* WEBPACK VAR INJECTION */(function(global) {(function (global, factory) {
     true ? factory(exports, __webpack_require__(2803), __webpack_require__(2806)) :
    undefined;
}(this, (function (exports,bintrees,Hammer) { 'use strict';

    if (typeof __FASTER_META__ === 'undefined') {
            var glb = typeof global !== 'undefined' ? global : typeof self !== 'undefined' ? self : typeof window !== 'undefined' ? window : {};
            glb.__FASTER_META__ = {};
          }
          

    Hammer = Hammer && Hammer.hasOwnProperty('default') ? Hammer['default'] : Hammer;

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

    var extendStatics = function(d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };

    function __extends(d, b) {
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    }

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

    var FPoint = /** @class */ (function () {
        function FPoint(x, y) {
            this.x = x;
            this.y = y;
        }
        FPoint.prototype.move = function (offsetX, offsetY) {
            this.x += offsetX;
            this.y += offsetY;
            return this;
        };
        FPoint.prototype.clone = function () {
            return new FPoint(this.x, this.y);
        };
        FPoint.prototype.equal = function (point) {
            return this.x === point.x && this.y === point.y;
        };
        FPoint.prototype.sub = function (from) {
            return new FPoint(this.x - from.x, this.y - from.y);
        };
        FPoint.prototype.scale = function (sx, sy) {
            this.x *= sx;
            this.y *= sy;
            return this;
        };
        FPoint.prototype.transform = function (t) {
            var ox = t.ox, oy = t.oy, sx = t.sx, sy = t.sy, tx = t.tx, ty = t.ty;
            return this.scale(sx, sy).move((1 - sx) * ox, (1 - sy) * oy).move(tx, ty);
        };
        FPoint.prototype.rtransform = function (t) {
            var ox = t.ox, oy = t.oy, sx = t.sx, sy = t.sy, tx = t.tx, ty = t.ty;
            return this.move(-tx, -ty).move((sx - 1) * ox, (sy - 1) * oy).scale(1 / sx, 1 / sy);
        };
        FPoint.prototype.rounds = function () {
            this.x = Math.round(this.x);
            this.y = Math.round(this.y);
            return this;
        };
        return FPoint;
    }());

    var FRect = /** @class */ (function () {
        function FRect(x, y, width, height) {
            if (x === void 0) { x = 0; }
            if (y === void 0) { y = 0; }
            if (width === void 0) { width = 0; }
            if (height === void 0) { height = 0; }
            this.x = x;
            this.y = y;
            this.width = width;
            this.height = height;
        }
        Object.defineProperty(FRect.prototype, "center", {
            get: function () {
                return new FPoint(this.x + this.width / 2, this.y + this.height / 2);
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FRect.prototype, "size", {
            get: function () {
                return new FSize(this.width, this.height);
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FRect.prototype, "maxX", {
            get: function () {
                return this.x + this.width;
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FRect.prototype, "maxY", {
            get: function () {
                return this.y + this.height;
            },
            enumerable: true,
            configurable: true
        });
        FRect.prototype.containPoint = function (pt) {
            return this.x <= pt.x && pt.x <= this.x + this.width
                && this.y <= pt.y && pt.y <= this.y + this.height;
        };
        FRect.prototype.containRect = function (rect) {
            return this.x <= rect.x && rect.x + rect.width <= this.x + this.width
                && this.y <= rect.y && rect.y + rect.height <= this.y + this.height;
        };
        FRect.prototype.equal = function (rect) {
            var x = rect.x, y = rect.y, width = rect.width, height = rect.height;
            return this.x === x && this.y === y && this.width === width && this.height === height;
        };
        FRect.prototype.leftTop = function () {
            return new FPoint(this.x, this.y);
        };
        FRect.prototype.intersect = function (rect) {
            var x = rect.x, y = rect.y, width = rect.width, height = rect.height;
            return this.x < x + width && x < this.x + this.width
                && this.y < y + height && y < this.y + this.height;
        };
        FRect.prototype.intersectRect = function (rect) {
            var left = Math.max(this.x, rect.x);
            var top = Math.max(this.y, rect.y);
            var right = Math.min(this.x + this.width, rect.x + rect.width);
            var bottom = Math.min(this.y + this.height, rect.y + rect.height);
            this.x = left;
            this.y = top;
            this.width = right - left;
            this.height = bottom - top;
            return this;
        };
        FRect.prototype.union = function (rect) {
            if (rect.isEmpty())
                return this;
            if (this.isEmpty()) {
                this.x = rect.x;
                this.y = rect.y;
                this.width = rect.width;
                this.height = rect.height;
                return this;
            }
            var left = Math.min(this.x, rect.x);
            var top = Math.min(this.y, rect.y);
            var right = Math.max(this.x + this.width, rect.x + rect.width);
            var bottom = Math.max(this.y + this.height, rect.y + rect.height);
            this.x = left;
            this.y = top;
            this.width = right - left;
            this.height = bottom - top;
            return this;
        };
        FRect.prototype.sub = function (rect) {
            var parts = [];
            var subArea = this.clone().intersectRect(rect);
            if (!subArea.isEmpty()) {
                if (subArea.y > this.y) {
                    parts.push(new FRect(this.x, this.y, this.width, subArea.y - this.y));
                }
                if (subArea.x > this.x) {
                    parts.push(new FRect(this.x, subArea.y, subArea.x - this.x, subArea.height));
                }
                if (subArea.x + subArea.width < this.x + this.width) {
                    parts.push(new FRect(subArea.x + subArea.width, subArea.y, this.x + this.width - (subArea.x + subArea.width), subArea.height));
                }
                if (subArea.y + subArea.height < this.y + this.height) {
                    parts.push(new FRect(this.x, subArea.y + subArea.height, this.width, this.y + this.height - (subArea.y + subArea.height)));
                }
            }
            else {
                parts.push(this.clone());
            }
            return parts;
        };
        FRect.prototype.clone = function () {
            return new FRect(this.x, this.y, this.width, this.height);
        };
        FRect.prototype.isEmpty = function () {
            return this.width <= 0 || this.height <= 0;
        };
        FRect.prototype.reset = function () {
            this.x = this.y = this.width = this.height = 0;
        };
        FRect.prototype.move = function (offsetX, offsetY) {
            this.x += offsetX;
            this.y += offsetY;
            return this;
        };
        FRect.prototype.rounds = function () {
            var right = Math.round(this.width + this.x);
            var bottom = Math.round(this.height + this.y);
            this.x = Math.round(this.x);
            this.y = Math.round(this.y);
            this.width = right - this.x;
            this.height = bottom - this.y;
            return this;
        };
        FRect.prototype.boundary = function () {
            var right = Math.ceil(this.width + this.x);
            var bottom = Math.ceil(this.height + this.y);
            this.x = Math.floor(this.x);
            this.y = Math.floor(this.y);
            this.width = right - this.x;
            this.height = bottom - this.y;
            return this;
        };
        FRect.prototype.roundClip = function () {
            var right = Math.floor(this.width + this.x);
            var bottom = Math.floor(this.height + this.y);
            this.x = Math.round(this.x);
            this.y = Math.round(this.y);
            this.width = right - this.x;
            this.height = bottom - this.y;
            return this;
        };
        FRect.prototype.scale = function (scaleX, scaleY) {
            this.x *= scaleX;
            this.width *= scaleX;
            this.y *= scaleY;
            this.height *= scaleY;
            return this;
        };
        FRect.prototype.transform = function (t) {
            var sx = t.sx, sy = t.sy, ox = t.ox, oy = t.oy, tx = t.tx, ty = t.ty;
            return this.scale(sx, sy).move(ox * (1 - sx), oy * (1 - sy)).move(tx, ty);
        };
        FRect.prototype.rtransform = function (t) {
            var sx = t.sx, sy = t.sy, ox = t.ox, oy = t.oy, tx = t.tx, ty = t.ty;
            return this.move(-tx, -ty).move((sx - 1) * ox, (sy - 1) * oy).scale(1 / sx, 1 / sy);
        };
        return FRect;
    }());
    var FSize = /** @class */ (function () {
        function FSize(width, height) {
            this.width = width;
            this.height = height;
        }
        return FSize;
    }());

    (function (FontWeight) {
        FontWeight[FontWeight["normal"] = 400] = "normal";
        FontWeight[FontWeight["bold"] = 700] = "bold";
    })(exports.FontWeight || (exports.FontWeight = {}));
    var FCanvasRenderingContext2D = /** @class */ (function () {
        function FCanvasRenderingContext2D(fcanvas, ctx) {
            this.fcanvas = fcanvas;
            this._ctx = ctx;
            if (!this._ctx._stack)
                this._ctx._stack = [this._defaultState()];
        }
        Object.defineProperty(FCanvasRenderingContext2D.prototype, "fillStyle", {
            get: function () {
                return this._ctx.fillStyle;
            },
            set: function (fillStyle) {
                if (this._ctx.fillStyle !== fillStyle)
                    this._ctx.fillStyle = fillStyle;
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FCanvasRenderingContext2D.prototype, "shadowBlur", {
            get: function () {
                return this._ctx.shadowBlur;
            },
            set: function (shadowBlur) {
                if (this._ctx.shadowBlur !== shadowBlur) {
                    this._ctx.shadowBlur = shadowBlur;
                }
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FCanvasRenderingContext2D.prototype, "shadowColor", {
            get: function () {
                return this._ctx.shadowColor;
            },
            set: function (shadowColor) {
                if (this._ctx.shadowColor !== shadowColor) {
                    this._ctx.shadowColor = shadowColor;
                }
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FCanvasRenderingContext2D.prototype, "shadowOffsetX", {
            get: function () {
                return this._ctx.shadowOffsetX;
            },
            set: function (shadowOffsetX) {
                if (this._ctx.shadowOffsetX !== shadowOffsetX) {
                    this._ctx.shadowOffsetX = shadowOffsetX;
                }
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FCanvasRenderingContext2D.prototype, "shadowOffsetY", {
            get: function () {
                return this._ctx.shadowOffsetY;
            },
            set: function (shadowOffsetY) {
                if (this._ctx.shadowOffsetY !== shadowOffsetY) {
                    this._ctx.shadowOffsetY = shadowOffsetY;
                }
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FCanvasRenderingContext2D.prototype, "globalAlpha", {
            get: function () {
                return this._ctx.globalAlpha;
            },
            set: function (globalAlpha) {
                if (this._ctx.globalAlpha !== globalAlpha) {
                    this._ctx.globalAlpha = globalAlpha;
                }
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FCanvasRenderingContext2D.prototype, "lineDashOffset", {
            get: function () {
                return this._ctx.lineDashOffset;
            },
            set: function (lineDashOffset) {
                if (this._ctx.lineDashOffset !== lineDashOffset) {
                    this._ctx.lineDashOffset = lineDashOffset;
                }
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FCanvasRenderingContext2D.prototype, "lineWidth", {
            get: function () {
                return this._ctx.lineWidth;
            },
            set: function (lineWidth) {
                if (this._ctx.lineWidth !== lineWidth) {
                    this._ctx.lineWidth = lineWidth;
                }
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FCanvasRenderingContext2D.prototype, "miterLimit", {
            get: function () {
                return this._ctx.miterLimit;
            },
            set: function (miterLimit) {
                if (this._ctx.miterLimit !== miterLimit) {
                    this._ctx.miterLimit = miterLimit;
                }
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FCanvasRenderingContext2D.prototype, "strokeStyle", {
            get: function () {
                return this._ctx.strokeStyle;
            },
            set: function (strokeStyle) {
                if (this._ctx.strokeStyle !== strokeStyle) {
                    this._ctx.strokeStyle = strokeStyle;
                }
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FCanvasRenderingContext2D.prototype, "lineJoin", {
            get: function () {
                return this._ctx.lineJoin;
            },
            set: function (lineJoin) {
                if (this._ctx.lineJoin !== lineJoin) {
                    this._ctx.lineJoin = lineJoin;
                }
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FCanvasRenderingContext2D.prototype, "globalCompositeOperation", {
            get: function () {
                return this._ctx.globalCompositeOperation;
            },
            set: function (globalCompositeOperation) {
                if (this._ctx.globalCompositeOperation !== globalCompositeOperation) {
                    this._ctx.globalCompositeOperation = globalCompositeOperation;
                }
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FCanvasRenderingContext2D.prototype, "lineCap", {
            get: function () {
                return this._ctx.lineCap;
            },
            set: function (lineCap) {
                if (this._ctx.lineCap !== lineCap) {
                    this._ctx.lineCap = lineCap;
                }
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FCanvasRenderingContext2D.prototype, "fontSize", {
            get: function () {
                var stack = this._ctx._stack;
                var state = stack[stack.length - 1];
                return state.fontSize || 10;
            },
            set: function (fontSize) {
                if (this.fontSize !== fontSize) {
                    var stack = this._ctx._stack;
                    var state = stack[stack.length - 1];
                    state.fontSize = fontSize;
                }
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FCanvasRenderingContext2D.prototype, "fontFamily", {
            get: function () {
                var stack = this._ctx._stack;
                var state = stack[stack.length - 1];
                return state.fontFamily || 'sans-serif';
            },
            set: function (fontFamily) {
                if (this.fontFamily !== fontFamily) {
                    var stack = this._ctx._stack;
                    var state = stack[stack.length - 1];
                    state.fontFamily = fontFamily;
                }
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FCanvasRenderingContext2D.prototype, "fontStyle", {
            get: function () {
                var stack = this._ctx._stack;
                var state = stack[stack.length - 1];
                return state.fontStyle;
            },
            set: function (fontStyle) {
                if (this.fontStyle !== fontStyle) {
                    var stack = this._ctx._stack;
                    var state = stack[stack.length - 1];
                    state.fontStyle = fontStyle;
                }
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FCanvasRenderingContext2D.prototype, "fontWeight", {
            get: function () {
                var stack = this._ctx._stack;
                var state = stack[stack.length - 1];
                return state.fontWeight;
            },
            set: function (fontWeight) {
                if (this.fontWeight !== fontWeight) {
                    var stack = this._ctx._stack;
                    var state = stack[stack.length - 1];
                    state.fontWeight = fontWeight;
                }
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FCanvasRenderingContext2D.prototype, "textAlign", {
            get: function () {
                return this._ctx.textAlign;
            },
            set: function (textAlign) {
                if (this._ctx.textAlign !== textAlign) {
                    this._ctx.textAlign = textAlign;
                }
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FCanvasRenderingContext2D.prototype, "textBaseline", {
            get: function () {
                return this._ctx.textBaseline;
            },
            set: function (textBaseline) {
                if (this._ctx.textBaseline !== textBaseline) {
                    this._ctx.textBaseline = textBaseline;
                }
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FCanvasRenderingContext2D.prototype, "imageSmoothingEnabled", {
            get: function () {
                return this._ctx.imageSmoothingEnabled || this._ctx.mozImageSmoothingEnabled
                    || this._ctx.webkitImageSmoothingEnabled || this._ctx.oImageSmoothingEnabled;
            },
            set: function (smooth) {
                if (this.imageSmoothingEnabled !== smooth) {
                    this._ctx.imageSmoothingEnabled = smooth;
                    this._ctx.mozImageSmoothingEnabled = smooth;
                    this._ctx.webkitImageSmoothingEnabled = smooth;
                    this._ctx.oImageSmoothingEnabled = smooth;
                }
            },
            enumerable: true,
            configurable: true
        });
        FCanvasRenderingContext2D.prototype.getTransform = function () {
            var stack = this._ctx._stack;
            return stack[stack.length - 1].transform;
        };
        FCanvasRenderingContext2D.prototype.beginPath = function () {
            this._ctx.beginPath();
        };
        FCanvasRenderingContext2D.prototype.closePath = function () {
            this._ctx.closePath();
        };
        FCanvasRenderingContext2D.prototype.arc = function (x, y, radius, startAngle, endAngle, anticlockwise) {
            var mx = this.getTransform();
            this._ctx.setTransform(mx.a, mx.b, mx.c, mx.d, mx.e, mx.f);
            this._ctx.arc(x, y, radius, startAngle, endAngle, anticlockwise);
        };
        //  arcTo(x1: number, y1: number, x2: number, y2: number, radius: number): void;
        //  bezierCurveTo(cp1x: number, cp1y: number, cp2x: number, cp2y: number, x: number, y: number): void;
        FCanvasRenderingContext2D.prototype.ellipse = function (x, y, radiusX, radiusY, rotation, startAngle, endAngle, anticlockwise) {
            var mx = this.getTransform();
            var ctx = this._ctx;
            ctx.setTransform(mx.a, mx.b, mx.c, mx.d, mx.e, mx.f);
            if (this._ctx.ellipse) {
                this._ctx.ellipse(x, y, radiusX, radiusY, rotation, startAngle, endAngle, anticlockwise);
            }
            else {
                ctx.save();
                ctx.translate(x, y);
                ctx.rotate(rotation);
                ctx.scale(radiusX, radiusY);
                ctx.arc(0, 0, 1, startAngle, endAngle, anticlockwise);
                ctx.restore();
            }
        };
        FCanvasRenderingContext2D.prototype.moveTo = function (x, y) {
            var t = this.getTransform();
            this._ctx.setTransform(1, t.b, t.c, 1, 0, 0);
            x = Math.round(this.xLogic2Device(x));
            y = Math.round(this.yLogic2Device(y));
            this._ctx.moveTo(x, y);
        };
        FCanvasRenderingContext2D.prototype.lineTo = function (x, y) {
            var t = this.getTransform();
            this._ctx.setTransform(1, t.b, t.c, 1, 0, 0);
            x = Math.round(this.xLogic2Device(x));
            y = Math.round(this.yLogic2Device(y));
            this._ctx.lineTo(x, y);
        };
        FCanvasRenderingContext2D.prototype.drawLine = function (x1, y1, x2, y2) {
            var lw = this.lineWidth;
            if (lw > 0) {
                var t = this.getTransform();
                if (x1 === x2 || y1 === y2) {
                    x1 = Math.round(this.xLogic2Device(x1));
                    x2 = Math.round(this.xLogic2Device(x2));
                    y1 = Math.round(this.yLogic2Device(y1));
                    y2 = Math.round(this.yLogic2Device(y2));
                    this._ctx.setTransform(1, t.b, t.c, 1, 0, 0);
                    if (x1 === x2) {
                        var linePx = Math.round(lw * t.a);
                        this._ctx.lineWidth = linePx;
                        x1 = x2 = x1 + linePx / 2;
                    }
                    else {
                        var linePx = Math.round(lw * t.d);
                        this._ctx.lineWidth = linePx;
                        y1 = y2 = y1 + linePx / 2;
                    }
                }
                else {
                    this._ctx.setTransform(t.a, t.b, t.c, t.d, t.e, t.f);
                    var halfW = lw / 2;
                    x1 += halfW;
                    x2 += halfW;
                    y1 += halfW;
                    y2 += halfW;
                }
                this._ctx.beginPath();
                this._ctx.moveTo(x1, y1);
                this._ctx.lineTo(x2, y2);
                this._ctx.stroke();
            }
        };
        FCanvasRenderingContext2D.prototype.rect = function (rect) {
            var mx = this.getTransform();
            this.logic2DeviceRect(rect).rounds();
            this._ctx.setTransform(1, mx.b, mx.c, 1, 0, 0);
            this._ctx.rect(rect.x, rect.y, rect.width, rect.height);
            this.deviceRect2Logic(rect);
        };
        //  quadraticCurveTo(cpx: number, cpy: number, x: number, y: number): void;
        FCanvasRenderingContext2D.prototype.clearRect = function (rect) {
            var t = this.getTransform();
            this.logic2DeviceRect(rect).boundary();
            this._ctx.setTransform(1, t.b, t.c, 1, 0, 0);
            this._ctx.clearRect(rect.x, rect.y, rect.width, rect.height);
            this.deviceRect2Logic(rect);
        };
        FCanvasRenderingContext2D.prototype.clip = function (fillRule) {
            this._ctx.clip(fillRule);
        };
        FCanvasRenderingContext2D.prototype.fill = function (fillRule) {
            this._ctx.fill(fillRule);
        };
        FCanvasRenderingContext2D.prototype.strokeText = function (text, x, y, maxWidth) {
            this._setFont();
            var mx = this.getTransform();
            this._ctx.setTransform(mx.a, mx.b, mx.c, mx.d, mx.e, mx.f);
            if (maxWidth !== undefined)
                this._ctx.strokeText(text, x, y, maxWidth);
            else
                this._ctx.strokeText(text, x, y);
        };
        FCanvasRenderingContext2D.prototype.fillText = function (text, x, y, maxWidth) {
            this._setFont();
            var mx = this.getTransform();
            this._ctx.setTransform(mx.a, mx.b, mx.c, mx.d, mx.e, mx.f);
            if (maxWidth !== undefined)
                this._ctx.fillText(text, x, y, maxWidth);
            else
                this._ctx.fillText(text, x, y);
        };
        // strokeRect(x: number, y: number, w: number, h: number): void;
        // fillRect(x: number, y: number, w: number, h: number): void;
        // createImageData(imageDataOrSw: number | ImageData, sh?: number): ImageData;
        // getImageData(sx: number, sy: number, sw: number, sh: number): ImageData;
        // getLineDash(): number[];
        // isPointInPath(x: number, y: number, fillRule?: CanvasFillRule): boolean;
        FCanvasRenderingContext2D.prototype.measureText = function (text) {
            this._setFont();
            var mx = this.getTransform();
            this._ctx.setTransform(mx.a, mx.b, mx.c, mx.d, mx.e, mx.f);
            var res = this._ctx.measureText(text);
            return { width: Math.round(res.width) };
        };
        // putImageData(imagedata: ImageData, dx: number, dy: number, dirtyX?: number, dirtyY?: number, dirtyWidth?: number, dirtyHeight?: number): void;
        FCanvasRenderingContext2D.prototype.restore = function () {
            this._ctx._stack.pop();
            this._ctx.restore();
        };
        FCanvasRenderingContext2D.prototype.rotate = function (w) {
            var t = this.getTransform();
            var cw = Math.cos(-w);
            var sw = Math.sin(-w);
            var a = t.a * cw - t.c * sw;
            var b = t.b * cw - t.d * sw;
            var c = t.c * cw + t.a * sw;
            var d = t.d * cw + t.b * sw;
            t.a = a;
            t.b = b;
            t.c = c;
            t.d = d;
        };
        FCanvasRenderingContext2D.prototype.save = function () {
            var stack = this._ctx._stack;
            var t = stack[stack.length - 1];
            stack.push({
                fontSize: t.fontSize,
                fontFamily: t.fontFamily,
                fontWeight: t.fontWeight,
                fontStyle: t.fontStyle,
                transform: __assign({}, t.transform)
            });
            this._ctx.save();
        };
        FCanvasRenderingContext2D.prototype.scale = function (sx, sy) {
            var t = this.getTransform();
            sx = sx || 1;
            sy = sy || sx;
            t.a *= sx;
            t.c *= sy;
            t.b *= sx;
            t.d *= sy;
        };
        FCanvasRenderingContext2D.prototype.setLineDash = function (segments) {
            this._ctx.setLineDash(segments);
        };
        FCanvasRenderingContext2D.prototype.setTransform = function (a, b, c, d, e, f) {
            var stack = this._ctx._stack;
            stack[stack.length - 1].transform = { a: a, b: b, c: c, d: d, e: e, f: f };
        };
        FCanvasRenderingContext2D.prototype.stroke = function () {
            this._ctx.stroke();
        };
        FCanvasRenderingContext2D.prototype.transform = function (a, b, c, d, e, f) {
            var t = this.getTransform();
            var na = t.a * a + t.c * b;
            var nb = t.b * a + t.d * b;
            var nc = t.a * c + t.c * d;
            var nd = t.b * c + t.d * d;
            var ne = t.e + t.a * e + t.c * f;
            var nf = t.f + t.b * e + t.d * f;
            t.a = na;
            t.b = nb;
            t.c = nc;
            t.d = nd;
            t.e = ne;
            t.f = nf;
        };
        FCanvasRenderingContext2D.prototype.translate = function (x, y) {
            var t = this.getTransform();
            t.e += x * t.a + y * t.c;
            t.f += x * t.b + y * t.d;
        };
        FCanvasRenderingContext2D.prototype.drawImage = function (image, dst, src) {
            var srcPic = image instanceof FCanvas ? image.element() : image;
            var t = this.getTransform();
            this._ctx.setTransform(1, t.b, t.c, 1, 0, 0);
            if (dst instanceof FRect) {
                dst = dst.clone();
                if (src instanceof FRect) {
                    this.logic2DeviceRect(dst);
                    if (image instanceof FCanvas) {
                        src = image.ctx().logic2DeviceRect(src.clone());
                    }
                    var scaleX = src.width / dst.width;
                    var scaleY = src.height / dst.height;
                    dst.rounds();
                    src.x = Math.round(src.x);
                    src.y = Math.round(src.y);
                    src.width = Math.round(dst.width * scaleX);
                    src.height = Math.round(dst.height * scaleY);
                    this._ctx.drawImage(srcPic, src.x, src.y, src.width, src.height, dst.x, dst.y, dst.width, dst.height);
                }
                else {
                    dst = this.logic2DeviceRect(dst).rounds();
                    this._ctx.drawImage(srcPic, dst.x, dst.y, dst.width, dst.height);
                }
                return dst;
            }
            else if (typeof src === 'number' && typeof dst === 'number') {
                src = Math.round(t.a * src + t.e);
                dst = Math.round(t.d * dst + t.f);
                this._ctx.drawImage(srcPic, src, dst);
            }
            else {
                console.error('invalid args to draw image');
            }
            return null;
        };
        FCanvasRenderingContext2D.prototype.xLogic2Device = function (x) {
            var t = this.getTransform();
            return x * t.a + t.e;
        };
        FCanvasRenderingContext2D.prototype.xDevice2Logic = function (x) {
            var t = this.getTransform();
            return (x - t.e) / t.a;
        };
        FCanvasRenderingContext2D.prototype.yLogic2Device = function (y) {
            var t = this.getTransform();
            return y * t.d + t.f;
        };
        FCanvasRenderingContext2D.prototype.yDevice2Logic = function (y) {
            var t = this.getTransform();
            return (y - t.f) / t.d;
        };
        FCanvasRenderingContext2D.prototype.xDeviceRound = function (x) {
            x = Math.round(this.xLogic2Device(x));
            return this.xDevice2Logic(x);
        };
        FCanvasRenderingContext2D.prototype.yDeviceRound = function (y) {
            y = Math.round(this.yLogic2Device(y));
            return this.yDevice2Logic(y);
        };
        FCanvasRenderingContext2D.prototype.logic2DeviceRect = function (rect) {
            var t = this.getTransform();
            return rect.scale(t.a, t.d).move(t.e, t.f);
        };
        FCanvasRenderingContext2D.prototype.deviceRect2Logic = function (rect) {
            var t = this.getTransform();
            return rect.move(-t.e, -t.f).scale(1 / t.a, 1 / t.d);
        };
        FCanvasRenderingContext2D.prototype.reset = function () {
            this._ctx._stack = [this._defaultState()];
        };
        FCanvasRenderingContext2D.prototype._setFont = function () {
            var font = this.fontStyle + " " + this.fontWeight + " " + this.fontSize + "px " + this.fontFamily;
            if (font !== this._ctx.font)
                this._ctx.font = font;
        };
        FCanvasRenderingContext2D.prototype._defaultState = function () {
            return {
                fontSize: 10,
                fontFamily: 'sans-serif',
                fontStyle: 'normal',
                fontWeight: exports.FontWeight.normal,
                transform: { a: 1, b: 0, c: 0, d: 1, e: 0, f: 0 }
            };
        };
        return FCanvasRenderingContext2D;
    }());

    var FCanvasPool = /** @class */ (function () {
        function FCanvasPool() {
        }
        FCanvasPool.borrowCanvas = function (root, domCanvas, syncDPI) {
            var canvas;
            if (!domCanvas) {
                if (this._pool.length > 0) {
                    domCanvas = this._pool.pop();
                }
                else {
                    domCanvas = document.createElement('canvas');
                }
            }
            canvas = new FCanvas(domCanvas, syncDPI !== false);
            this._malloced.push({ canvas: canvas, root: root });
            return canvas;
        };
        FCanvasPool.backCanvas = function (canvas) {
            if (this._pool.length < FCanvasPool.poolSize) {
                canvas.reset();
                this._pool.push(canvas.element());
                canvas.element().removeAttribute('style');
                var parentNode = canvas.element().parentNode;
                if (parentNode !== null)
                    parentNode.removeChild(canvas.element());
                this._malloced = this._malloced.filter(function (c) { return c.canvas !== canvas; });
            }
        };
        FCanvasPool.mallocedCanvas = function (fx) {
            return this._malloced.filter(function (node) { return node.root === fx; }).map(function (node) { return node.canvas; });
        };
        FCanvasPool.updateDPI = function () {
            var oRatioX = FCanvasPool.ratioX;
            var oRatioY = FCanvasPool.ratioY;
            var ratio = window.devicePixelRatio;
            if (ratio) {
                FCanvasPool.ratioX = ratio;
                FCanvasPool.ratioY = ratio;
            }
            else {
                var screen_1 = window.screen;
                if (screen_1.deviceXDPI) {
                    var ratioX = screen_1.deviceXDPI / screen_1.logicalXDPI;
                    FCanvasPool.ratioX = ratioX;
                }
                if (screen_1.deviceYDPI) {
                    var ratioY = screen_1.deviceYDPI / screen_1.logicalYDPI;
                    FCanvasPool.ratioY = ratioY;
                }
            }
            if (FCanvasPool.ratioX < 1)
                FCanvasPool.ratioX = 1;
            if (FCanvasPool.ratioY < 1)
                FCanvasPool.ratioY = 1;
            if (FCanvasPool.ratioX !== oRatioX || FCanvasPool.ratioY !== oRatioY) {
                this._malloced.forEach(function (elem) {
                    var c = elem.canvas;
                    if (c.isDpiSync()) {
                        c.resize(c.width(), c.height(), true);
                    }
                });
            }
        };
        FCanvasPool.poolSize = 256;
        FCanvasPool.ratioX = 1;
        FCanvasPool.ratioY = 1;
        FCanvasPool._pool = [];
        FCanvasPool._malloced = [];
        return FCanvasPool;
    }());
    (function (FCanvasNotify) {
        FCanvasNotify[FCanvasNotify["Resized"] = 0] = "Resized";
        FCanvasNotify[FCanvasNotify["Suspend"] = 1] = "Suspend";
        FCanvasNotify[FCanvasNotify["Wakeup"] = 2] = "Wakeup";
    })(exports.FCanvasNotify || (exports.FCanvasNotify = {}));
    var FCanvas = /** @class */ (function () {
        function FCanvas(_canvas, _syncDPI) {
            if (_syncDPI === void 0) { _syncDPI = true; }
            this._canvas = _canvas;
            this._syncDPI = _syncDPI;
            this._width = 0;
            this._height = 0;
            this.isActive = true;
        }
        FCanvas.prototype.element = function () {
            return this._canvas;
        };
        FCanvas.prototype.ctx = function () {
            return new FCanvasRenderingContext2D(this, this._canvas.getContext('2d'));
        };
        FCanvas.prototype.width = function () {
            return this._width;
        };
        FCanvas.prototype.height = function () {
            return this._height;
        };
        FCanvas.prototype.isSuspend = function () {
            return !this.isActive;
        };
        FCanvas.prototype.suspend = function () {
            this.isActive = false;
            this._canvas.width = 0;
            this._canvas.height = 0;
            this._fireNotify(exports.FCanvasNotify.Suspend);
        };
        FCanvas.prototype.wakeup = function () {
            this.isActive = true;
            this._updateCanvasSize();
            this._fireNotify(exports.FCanvasNotify.Wakeup);
        };
        FCanvas.prototype.isDpiSync = function () {
            return this._syncDPI;
        };
        FCanvas.prototype.resize = function (width, height, force) {
            if (force === void 0) { force = false; }
            if (!force && this._width === width && this._height === height)
                return;
            var suspend = this.isSuspend();
            this._width = width;
            this._height = height;
            this._canvas.style.width = width + "px";
            this._canvas.style.height = height + "px";
            if (!suspend)
                this._updateCanvasSize();
        };
        FCanvas.prototype.clear = function () {
            var ctx = this.ctx();
            var t = ctx.getTransform();
            ctx.setTransform(1, 0, 0, 1, 0, 0);
            ctx.clearRect(new FRect(0, 0, this._width, this._height));
            ctx.setTransform(t.a, t.b, t.c, t.d, t.e, t.f);
        };
        FCanvas.prototype.registerNotiry = function (handler) {
            if (!this._handlers)
                this._handlers = [];
            this._handlers.push(handler);
        };
        FCanvas.prototype.unRegisterNotify = function (handler) {
            if (this._handlers) {
                this._handlers = this._handlers.filter(function (h) { return h !== handler; });
            }
        };
        FCanvas.prototype.reset = function () {
            var elem = this._canvas;
            elem.style.display = 'none';
            this.ctx().reset();
            this.resize(0, 0);
            if (this._handlers)
                this._handlers = [];
        };
        FCanvas.prototype.fakeHide = function () {
            this._canvas.style.display = 'block';
            this._canvas.style.position = 'fixed';
            this._canvas.style.top = '0';
            this._canvas.style.left = '0';
            this._canvas.style.transform = 'translate(-100%, -100%)';
            document.body.appendChild(this._canvas);
        };
        FCanvas.prototype._fireNotify = function (type) {
            if (this._handlers) {
                this._handlers.forEach(function (h) { return h(type); });
            }
        };
        FCanvas.prototype._updateCanvasSize = function () {
            var ratioX = this._syncDPI ? FCanvasPool.ratioX : 1;
            var ratioY = this._syncDPI ? FCanvasPool.ratioY : 1;
            this._canvas.width = Math.round(this._width * ratioX);
            this._canvas.height = Math.round(this._height * ratioY);
            this.ctx().reset();
            this.ctx().setTransform(ratioX, 0, 0, ratioY, 0, 0);
            this._fireNotify(exports.FCanvasNotify.Resized);
        };
        return FCanvas;
    }());

    (function (FEventType) {
        FEventType[FEventType["MouseMove"] = 0] = "MouseMove";
        FEventType[FEventType["MouseDown"] = 1] = "MouseDown";
        FEventType[FEventType["MouseUp"] = 2] = "MouseUp";
        FEventType[FEventType["Click"] = 3] = "Click";
        FEventType[FEventType["Dblclick"] = 4] = "Dblclick";
        FEventType[FEventType["MouseEnter"] = 5] = "MouseEnter";
        FEventType[FEventType["MouseLeave"] = 6] = "MouseLeave";
        FEventType[FEventType["MouseWheel"] = 7] = "MouseWheel";
        FEventType[FEventType["ContextMenu"] = 8] = "ContextMenu";
        FEventType[FEventType["DragStart"] = 9] = "DragStart";
        FEventType[FEventType["Drag"] = 10] = "Drag";
        FEventType[FEventType["DragEnter"] = 11] = "DragEnter";
        FEventType[FEventType["DragOver"] = 12] = "DragOver";
        FEventType[FEventType["DragLeave"] = 13] = "DragLeave";
        FEventType[FEventType["Drop"] = 14] = "Drop";
        FEventType[FEventType["DragEnd"] = 15] = "DragEnd";
        FEventType[FEventType["Tap"] = 16] = "Tap";
        FEventType[FEventType["PanStart"] = 17] = "PanStart";
        FEventType[FEventType["PanMove"] = 18] = "PanMove";
        FEventType[FEventType["PanEnd"] = 19] = "PanEnd";
        FEventType[FEventType["PanCancel"] = 20] = "PanCancel";
        FEventType[FEventType["Press"] = 21] = "Press";
        FEventType[FEventType["PressUp"] = 22] = "PressUp";
        FEventType[FEventType["Swipe"] = 23] = "Swipe";
        FEventType[FEventType["RotateStart"] = 24] = "RotateStart";
        FEventType[FEventType["RotateMove"] = 25] = "RotateMove";
        FEventType[FEventType["RotateEnd"] = 26] = "RotateEnd";
        FEventType[FEventType["RotateCancel"] = 27] = "RotateCancel";
        FEventType[FEventType["PinchStart"] = 28] = "PinchStart";
        FEventType[FEventType["PinchMove"] = 29] = "PinchMove";
        FEventType[FEventType["PinchEnd"] = 30] = "PinchEnd";
        FEventType[FEventType["PinchCancel"] = 31] = "PinchCancel";
        // lifetime event
        FEventType[FEventType["BeforeChange"] = 32] = "BeforeChange";
        FEventType[FEventType["AfterChange"] = 33] = "AfterChange";
        FEventType[FEventType["BeforeFlush"] = 34] = "BeforeFlush";
        FEventType[FEventType["AfterFlush"] = 35] = "AfterFlush";
        FEventType[FEventType["Destroy"] = 36] = "Destroy";
        FEventType[FEventType["AddChild"] = 37] = "AddChild";
        FEventType[FEventType["RemoveChild"] = 38] = "RemoveChild";
        FEventType[FEventType["EventTypeEnd"] = 39] = "EventTypeEnd";
        FEventType[FEventType["BeforeTick"] = 40] = "BeforeTick";
        FEventType[FEventType["AfterTick"] = 41] = "AfterTick";
    })(exports.FEventType || (exports.FEventType = {}));
    var CustomEventStart = exports.FEventType.EventTypeEnd + 1;
    var FEvent = /** @class */ (function () {
        function FEvent(type, target) {
            this.type = type;
            this.target = target;
            this._preventDefalut = false;
        }
        FEvent.prototype.preventDefault = function () {
            this._preventDefalut = true;
        };
        Object.defineProperty(FEvent.prototype, "defaultPrevented", {
            get: function () {
                return this._preventDefalut;
            },
            enumerable: true,
            configurable: true
        });
        return FEvent;
    }());
    var FUIEvent = /** @class */ (function (_super) {
        __extends(FUIEvent, _super);
        function FUIEvent(type, target) {
            var _this = _super.call(this, type, target) || this;
            _this.type = type;
            _this.target = target;
            return _this;
        }
        return FUIEvent;
    }(FEvent));

    (function (WidgetType) {
        WidgetType["faster"] = "core/faster";
        WidgetType["widget"] = "core/widget";
    })(exports.WidgetType || (exports.WidgetType = {}));

    var FChangeEvent = /** @class */ (function (_super) {
        __extends(FChangeEvent, _super);
        function FChangeEvent(type, target, changes) {
            var _this = _super.call(this, type, target) || this;
            _this.changes = changes;
            return _this;
        }
        return FChangeEvent;
    }(FEvent));

    var BindReferens = /** @class */ (function () {
        function BindReferens() {
            this._refs = {};
        }
        BindReferens.prototype.anyDepends = function (id, p) {
            return id in this._refs && p in this._refs[id];
        };
        BindReferens.prototype.addRef = function (id, prop, node) {
            if (!(id in this._refs)) {
                this._refs[id] = {};
            }
            var allDepends = this._refs[id];
            if (!(prop in allDepends)) {
                allDepends[prop] = [];
            }
            var bds = allDepends[prop];
            bds.push(node);
        };
        BindReferens.prototype.removeRef = function (id, prop, node) {
            if (this.anyDepends(id, prop)) {
                var bds = this._refs[id][prop];
                bds = bds.filter(function (ref) { return ref.id !== node.id || ref.prop !== node.prop || ref.pip !== node.pip; });
                if (bds.length > 0)
                    this._refs[id][prop] = bds;
                else
                    delete this._refs[id][prop];
            }
        };
        BindReferens.prototype.allPropRefs = function (id, prop) {
            if (!this.anyDepends(id, prop))
                return [];
            else
                return this._refs[id][prop];
        };
        BindReferens.prototype.allRefs = function (id) {
            return this._refs[id] || {};
        };
        BindReferens.prototype.removeAllRefs = function (id) {
            delete this._refs[id];
        };
        return BindReferens;
    }());
    var Bind = /** @class */ (function () {
        function Bind() {
        }
        Bind.firePropChange = function (w, prop, value) {
            var refs = this._depends.allPropRefs(w.UID, prop);
            refs.forEach(function (ref) {
                var obj = FObj.getObjById(ref.id.toString());
                var cfg = {};
                if (ref.pip)
                    cfg[ref.prop] = ref.pip(value);
                else
                    cfg[ref.prop] = value;
                if (obj)
                    obj.updateByCfg(cfg);
            });
        };
        Bind.propBind = function (target, tprop, src, sprop, pip) {
            var sid = src.UID;
            var tid = target.UID;
            Bind._depends.addRef(sid, sprop, { id: tid, prop: tprop, pip: pip });
            Bind._dependsOn.addRef(tid, tprop, { id: sid, prop: sprop, pip: pip });
            var val = src._cleanProp(sprop);
            if (val !== undefined) {
                var cfg = {};
                if (pip)
                    cfg[tprop] = pip(val);
                else
                    cfg[tprop] = val;
                target.updateByCfg(cfg);
            }
            return { sid: sid, sprop: sprop, tid: tid, tprop: tprop };
        };
        /**
         * convenient util
         * target 与 src 之间双向绑定两个属性
         */
        Bind.dupBind = function (target, tprop, src, sprop) {
            this.propBind(target, tprop, src, sprop);
            this.propBind(src, sprop, target, tprop);
        };
        /**
         * convenient util
         * target 与 src 大小保持一致
         */
        Bind.bindSize = function (target, src, margin) {
            if (margin === void 0) { margin = 0; }
            this.propBind(target, 'width', src, 'width', function (w) { return w - margin * 2; });
            this.propBind(target, 'height', src, 'height', function (h) { return h - margin * 2; });
            if (margin !== 0) {
                target.updateByCfg({ x: margin, y: margin });
            }
        };
        Bind.unBindAll = function (w) {
            var _this = this;
            var id = w.UID;
            var allRefs = this._dependsOn.allRefs(id);
            Object.keys(allRefs).forEach(function (key) {
                allRefs[key].forEach(function (ref) {
                    _this._depends.removeRef(ref.id, ref.prop, { id: id, prop: key, pip: ref.pip });
                });
            });
            this._dependsOn.removeAllRefs(id);
        };
        Bind.propsUnBind = function (handler) {
            var sid = handler.sid, sprop = handler.sprop, tid = handler.tid, tprop = handler.tprop, pip = handler.pip;
            Bind._depends.removeRef(sid, sprop, { id: tid, prop: tprop, pip: pip });
            Bind._dependsOn.removeRef(tid, tprop, { id: sid, prop: sprop, pip: pip });
        };
        Bind._depends = new BindReferens();
        Bind._dependsOn = new BindReferens();
        return Bind;
    }());

    function parentLoop(w, cb) {
        while (w !== null) {
            if (!cb(w)) {
                w = w.parent();
            }
            else {
                return true;
            }
        }
        return false;
    }

    // @deprecated remove this enum  use 1/0/-1 replace
    (function (CompareRes) {
        CompareRes[CompareRes["Greater"] = 0] = "Greater";
        CompareRes[CompareRes["Equal"] = 1] = "Equal";
        CompareRes[CompareRes["Less"] = 2] = "Less";
    })(exports.CompareRes || (exports.CompareRes = {}));
    /**
     *
     * @param arr
     * @param predicate
     * if there is no elemnt in the arr where predicate return eqaule, return the nearest idx if
     * this param is true, otherwise return -1
     * @param nearest
     */
    function findInSorted(arr, predicate, nearest) {
        if (nearest === void 0) { nearest = false; }
        var start = 0;
        var end = arr.length - 1;
        while (start <= end) {
            var i = Math.floor((end + start) / 2);
            var res = predicate(arr[i]);
            if (res === exports.CompareRes.Greater) {
                start = i + 1;
            }
            else if (res === exports.CompareRes.Less) {
                end = i - 1;
            }
            else {
                return i;
            }
        }
        return nearest ? Math.min(start, 0) : -1;
    }
    function equals(one, other) {
        if (one === other) {
            return true;
        }
        if (one === null || one === undefined || other === null || other === undefined) {
            return false;
        }
        if (typeof one !== typeof other) {
            return false;
        }
        if (typeof one !== 'object') {
            return false;
        }
        if ((Array.isArray(one)) !== (Array.isArray(other))) {
            return false;
        }
        var i;
        var key;
        if (Array.isArray(one)) {
            if (one.length !== other.length) {
                return false;
            }
            for (i = 0; i < one.length; i++) {
                if (!equals(one[i], other[i])) {
                    return false;
                }
            }
        }
        else {
            var oneKeys = [];
            for (key in one) {
                oneKeys.push(key);
            }
            oneKeys.sort();
            var otherKeys = [];
            for (key in other) {
                otherKeys.push(key);
            }
            otherKeys.sort();
            if (!equals(oneKeys, otherKeys)) {
                return false;
            }
            for (i = 0; i < oneKeys.length; i++) {
                if (!equals(one[oneKeys[i]], other[oneKeys[i]])) {
                    return false;
                }
            }
        }
        return true;
    }

    // https://humanwhocodes.com/blog/2009/06/23/loading-javascript-without-blocking/
    function loadScript(url, callback, onerror) {
        var script = document.createElement('script');
        script.type = 'text/javascript';
        // for IE
        if (script.readyState) {
            script.onreadystatechange = function () {
                if (script.readyState === 'loaded' || script.readyState === 'complete') {
                    script.onreadystatechange = null;
                    callback && callback();
                }
            };
        }
        // for others
        else {
            script.onload = function () {
                callback && callback();
            };
            script.onerror = function () {
                onerror && onerror();
            };
        }
        script.src = url;
        document.body.appendChild(script);
    }

    var ArrIterator = /** @class */ (function () {
        function ArrIterator(_arr) {
            this._arr = _arr;
            this._idx = Number.NEGATIVE_INFINITY;
        }
        ArrIterator.prototype.next = function () {
            if (this._idx === Number.NEGATIVE_INFINITY)
                this._idx = -1;
            if (this._idx >= this._arr.length - 1) {
                this._idx = Number.NEGATIVE_INFINITY;
                return null;
            }
            this._idx++;
            return this;
        };
        ArrIterator.prototype.prev = function () {
            if (this._idx === Number.NEGATIVE_INFINITY)
                this._idx = this._arr.length;
            if (this._idx <= 0) {
                this._idx = Number.NEGATIVE_INFINITY;
                return null;
            }
            this._idx--;
            return this;
        };
        ArrIterator.prototype.value = function () {
            return this._arr[this._idx];
        };
        ArrIterator.prototype.isValid = function () {
            return this._idx !== Number.NEGATIVE_INFINITY;
        };
        ArrIterator.prototype.seek = function (idx) {
            if (0 <= idx && idx < this._arr.length)
                this._idx = idx;
            else
                this._idx = Number.NEGATIVE_INFINITY;
            return this;
        };
        ArrIterator.prototype.idx = function () {
            return this._idx;
        };
        return ArrIterator;
    }());

    var SortedArray = /** @class */ (function () {
        function SortedArray(_compare, _arr) {
            if (_arr === void 0) { _arr = []; }
            this._compare = _compare;
            this._arr = _arr;
        }
        SortedArray.prototype.insert = function (v) {
            this._backInsert(v);
        };
        /**
         * Return the value of the arbitary elment in the array which is equal
         * or nearest elem and less than the value, and -1 otherwise
         *
         * @param value: the value to find.
         * @param nearest: accept an nearest one element in the array or must be equal.
         */
        SortedArray.prototype.find = function (value, nearest) {
            var start = 0;
            var end = this._arr.length - 1;
            while (start <= end) {
                var i = Math.floor((end + start) / 2);
                var res = this._compare(value, this._arr[i]);
                if (res > 0)
                    start = i + 1;
                else if (res < 0)
                    end = i - 1;
                else
                    return i;
            }
            if (nearest && this._arr.length > 0) {
                var i = Math.min(start, end);
                return Math.max(i, 0);
            }
            return -1;
        };
        /**
         * Removes elements from an array and, if necessary,  returning the deleted elements.
         * @param start The zero-based location in the array from which to start removing elements.
         * @param deleteCount The number of elements to remove.
         */
        SortedArray.prototype.remove = function (start, deleteCount) {
            return this._arr.splice(start, deleteCount);
        };
        SortedArray.prototype.at = function (pos) {
            return this._arr[pos];
        };
        SortedArray.prototype.last = function () {
            return this._arr[this._arr.length - 1] || null;
        };
        SortedArray.prototype.first = function () {
            return this._arr[0] || null;
        };
        SortedArray.prototype.len = function () {
            return this._arr.length;
        };
        SortedArray.prototype.lbound = function (value, nearest) {
            var idx = this.find(value, nearest);
            if (idx === -1)
                return idx;
            var res = this._compare(value, this._arr[idx]);
            if (res === 0) {
                // if the element equal to v, get the last one as insert place.
                while (idx - 1 > 0) {
                    if (this._compare(value, this._arr[idx - 1]) !== 0)
                        break;
                    --idx;
                }
            }
            else if (nearest && res < 0 && idx > 0) {
                --idx;
            }
            return idx;
        };
        SortedArray.prototype.ubound = function (value, nearest) {
            var idx = this.find(value, nearest);
            if (idx === -1)
                return idx;
            var res = this._compare(value, this._arr[idx]);
            if (res === 0) {
                // if the element equal to v, get the last one as insert place.
                while (idx + 1 < this._arr.length) {
                    if (this._compare(value, this._arr[idx + 1]) !== 0)
                        break;
                    ++idx;
                }
            }
            else if (nearest && res > 0 && idx < this._arr.length - 1) {
                ++idx;
            }
            return idx;
        };
        SortedArray.prototype.clear = function () {
            this._arr.length = 0;
        };
        SortedArray.prototype.iter = function () {
            return new ArrIterator(this._arr);
        };
        SortedArray.prototype.toArray = function () {
            return this._arr.slice();
        };
        SortedArray.prototype._backInsert = function (v) {
            var idx = this.ubound(v, true);
            if (idx !== -1) {
                if (this._compare(v, this._arr[idx]) >= 0)
                    ++idx;
                this._arr.splice(idx, 0, v);
            }
            else {
                this._arr.push(v);
            }
        };
        return SortedArray;
    }());

    var FObj = /** @class */ (function () {
        function FObj() {
            this._changes = new Map();
            // tmp code, remove this after removed _cleanProps
            this._zindex = 0;
            this.UID = FObj.widgetUid();
            FObj.glbHashes[this.UID] = this;
            this._cfg = this._defalutCfg();
        }
        FObj.getObjById = function (uid) {
            return FObj.glbHashes[uid];
        };
        FObj.widgetUid = function () {
            FObj._uid += 1;
            return FObj._uid;
        };
        FObj.prototype.destroied = function () {
            return this._destroied === true;
        };
        FObj.prototype.hasChild = function () {
            return this._children ? this._children.size : 0;
        };
        FObj.prototype.children = function () {
            if (!this._children) {
                this._children = new bintrees.RBTree(this._compareZindex); // sort by z-index
            }
            return this._children;
        };
        FObj.prototype.addChild = function (w) {
            if (w.ancestorOf(this)) {
                console.error('can not append widget to its\' children');
                return;
            }
            if (w.parent() === this)
                return;
            if (w._parent)
                w._parent.removeChild(w);
            w._parent = this;
            this.children().insert(w);
        };
        FObj.prototype.removeChild = function (w) {
            this.children().remove(w);
            w._parent = null;
        };
        FObj.prototype.parent = function () {
            return this._parent ? this._parent : null;
        };
        FObj.prototype.setParent = function (p) {
            var op = this.parent();
            if (op !== null) {
                op.removeChild(this);
            }
            if (p !== null) {
                p.addChild(this);
            }
            this._parent = p;
        };
        FObj.prototype.ancestorOf = function (w) {
            var p = w;
            while (p !== null) {
                if (p === this)
                    return true;
                else
                    p = p.parent();
            }
            return false;
        };
        FObj.prototype.updateByCfg = function (cfg) {
            var _this = this;
            var changes = this._pickChanges(cfg);
            var keys = Object.keys(changes);
            if (keys.length > 0) {
                this.event(new FChangeEvent(exports.FEventType.BeforeChange, this, changes));
                var keys_1 = Object.keys(changes);
                keys_1.forEach(function (key) {
                    var change = changes[key];
                    // can not ignore detect value, before change maybe change current value again.
                    if (change.current !== change.before) {
                        _this._changes.set(key, change.current);
                        Bind.firePropChange(_this, key, change.current);
                    }
                    if (change.current === _this._cfg[key]) {
                        _this._changes.delete(key);
                    }
                });
                this.event(new FChangeEvent(exports.FEventType.AfterChange, this, changes));
            }
            return changes;
        };
        FObj.prototype.event = function (e) {
            if (this._handlers && e.type in this._handlers) {
                return this._handlers[e.type].some(function (hd) { return hd(e); });
            }
            return false;
        };
        FObj.prototype.addListener = function (type, handler) {
            if (!this._handlers)
                this._handlers = {};
            if (!(type in this._handlers)) {
                this._handlers[type] = [];
            }
            this._handlers[type].push(handler);
        };
        FObj.prototype.addOnceListener = function (type, handler) {
            var _this = this;
            var wrapper = function (e) {
                var prevent = handler(e);
                _this.removeListener(type, wrapper);
                return prevent;
            };
            this.addListener(type, wrapper);
        };
        FObj.prototype.removeListener = function (type, handler) {
            if (!this._handlers)
                return;
            if (!(type in this._handlers))
                return;
            this._handlers[type] = this._handlers[type].filter(function (hd) { return hd !== handler; });
        };
        FObj.prototype.detectLifetimeOnce = function (onlySelf) {
            if (onlySelf === void 0) { onlySelf = false; }
            if (!this._changes.has('_phantom')) {
                this.updateByCfg({ _phantom: true });
                if (this._children && !onlySelf) {
                    this._children.each(function (w) { return w.detectLifetimeOnce(onlySelf); });
                }
            }
        };
        FObj.prototype.beforeChange = function (e) {
            // lifetime function
        };
        FObj.prototype.afterChange = function (e) {
            // lifetime function
        };
        FObj.prototype.beforeFlush = function (e) {
            // lifetime function
        };
        FObj.prototype.afterFlush = function (e) {
            // lifetime function
        };
        FObj.prototype.beforeTick = function (e) {
            // lifetime function
        };
        FObj.prototype.afterTick = function (e) {
            // lifetime function
        };
        FObj.prototype.onChildChange = function (c, changes) {
            // lifetime function
        };
        FObj.prototype.destroy = function () {
            delete FObj.glbHashes[this.UID];
            this._destroied = true;
            Bind.unBindAll(this);
            if (this._children) {
                // notify children
                this._children.each(function (w) {
                    w._parent = null;
                    w.destroy();
                });
                this._children.clear();
            }
            // remove from parent
            if (this._parent)
                this._parent.removeChild(this);
            this.event(new FEvent(exports.FEventType.Destroy, this));
        };
        // if widget has custom cfg type, should override this function.
        FObj.prototype._defalutCfg = function () {
            return {};
        };
        FObj.prototype._cleanProp = function (key) {
            return this._changes.has(key) ? this._changes.get(key) : this._cfg[key];
        };
        FObj.prototype._pickChanges = function (cfg) {
            var changes = {};
            for (var key in cfg) {
                var v = cfg[key];
                var ov = this._cleanProp(key);
                complainNaN(v);
                if (!equals(v, ov)) {
                    changes[key] = { before: ov, current: v };
                }
            }
            return changes;
        };
        FObj.prototype._compareZindex = function (a, b) {
            var diff = a._zindex - b._zindex;
            if (diff === 0)
                return a.UID - b.UID;
            else
                return diff;
        };
        FObj.glbHashes = {};
        FObj._uid = 0;
        return FObj;
    }());
    function complainNaN(v) {
        if (v !== v) {
            throw new Error('Cfg value cant be NaN');
        }
    }

    (function (borderDash) {
        borderDash[borderDash["dash"] = 0] = "dash";
    })(exports.borderDash || (exports.borderDash = {}));
    var dashLine = [5, 5];
    function QuaterSplit(q, defaultV, top, right, bottom, left) {
        if (q instanceof Array) {
            if (q.length === 2) {
                if (top === undefined)
                    top = q[0];
                if (right === undefined)
                    right = q[1];
                if (bottom === undefined)
                    bottom = q[0];
                if (left === undefined)
                    left = q[1];
            }
            else if (q.length === 4) {
                if (top === undefined)
                    top = q[0];
                if (right === undefined)
                    right = q[1];
                if (bottom === undefined)
                    bottom = q[2];
                if (left === undefined)
                    left = q[3];
            }
            else {
                console.error('quater type must be a 2 or 4 element array.');
            }
        }
        else {
            if (top === undefined)
                top = q;
            if (right === undefined)
                right = q;
            if (bottom === undefined)
                bottom = q;
            if (left === undefined)
                left = q;
        }
        if (top === undefined)
            top = defaultV;
        if (right === undefined)
            right = defaultV;
        if (bottom === undefined)
            bottom = defaultV;
        if (left === undefined)
            left = defaultV;
        return [top, right, bottom, left];
    }

    // Widget
    var WIDGET_UID = 'UID';
    // style
    var BACKGROUND = 'transparent';
    var SHADOW_BLUR = 0;
    var SHADOW_COLOR = 'fully-transparent black';
    var SHADOW_OFFSET_X = 0;
    var SHADOW_OFFSET_Y = 0;
    var SCROLLBAR_COLOR = '#E3E5EA';
    var SCROLLBAR_BACKGROUND = '#efefef';
    var SCROLLBAR_THICK = 8;

    (function (WidgetProps) {
        WidgetProps[WidgetProps["Droppable"] = 0] = "Droppable";
        WidgetProps[WidgetProps["Draggable"] = 1] = "Draggable";
        WidgetProps[WidgetProps["ChildDirty"] = 2] = "ChildDirty";
        WidgetProps[WidgetProps["EndWidgetProps"] = 3] = "EndWidgetProps";
    })(exports.WidgetProps || (exports.WidgetProps = {}));
    var FWidget = /** @class */ (function (_super) {
        __extends(FWidget, _super);
        function FWidget(parent) {
            var _this = _super.call(this) || this;
            _this._props = 0;
            _this._filters = [];
            _this._dirtyRect = new FRect();
            if (parent !== null)
                parent.addChild(_this);
            return _this;
        }
        FWidget.prototype.setLayout = function (layout) {
            if (this.layoutManager !== undefined) {
                this.layoutManager.detach();
            }
            this.layoutManager = layout;
            layout && layout.attach(this);
        };
        Object.defineProperty(FWidget.prototype, "x", {
            get: function () {
                return this._cleanProp('x');
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FWidget.prototype, "y", {
            get: function () {
                return this._cleanProp('y');
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FWidget.prototype, "background", {
            get: function () {
                return this._cleanProp('background');
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FWidget.prototype, "foreground", {
            get: function () {
                return this._cleanProp('foreground');
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FWidget.prototype, "width", {
            get: function () {
                return this._cleanProp('width');
            },
            set: function (d) {
                this.updateByCfg({ width: d });
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FWidget.prototype, "height", {
            get: function () {
                return this._cleanProp('height');
            },
            set: function (d) {
                this.updateByCfg({ height: d });
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FWidget.prototype, "rect", {
            get: function () {
                return new FRect(this._cleanProp('x'), this._cleanProp('y'), this._cleanProp('width'), this._cleanProp('height'));
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FWidget.prototype, "isSelfDirty", {
            get: function () {
                return this._changes.size > 0;
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FWidget.prototype, "isChildDirty", {
            get: function () {
                return this._getProps(exports.WidgetProps.ChildDirty);
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FWidget.prototype, "draggable", {
            get: function () {
                return this._getProps(exports.WidgetProps.Draggable);
            },
            set: function (flag) {
                this._setProps(exports.WidgetProps.Draggable, flag);
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FWidget.prototype, "droppable", {
            get: function () {
                return this._getProps(exports.WidgetProps.Droppable);
            },
            set: function (flag) {
                this._setProps(exports.WidgetProps.Droppable, flag);
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FWidget.prototype, "zindex", {
            get: function () {
                return this._zindex || 0;
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FWidget.prototype, "hidden", {
            get: function () {
                return this._cleanProp('hidden') || false;
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FWidget.prototype, "ignore", {
            get: function () {
                return this._cleanProp('ignore') || false;
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FWidget.prototype, "padding", {
            get: function () {
                return this._cleanProp('padding');
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FWidget.prototype, "border", {
            get: function () {
                return this._cleanProp('border');
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FWidget.prototype, "borderTop", {
            get: function () {
                return this._cleanProp('borderTop');
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FWidget.prototype, "borderRight", {
            get: function () {
                return this._cleanProp('borderRight');
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FWidget.prototype, "borderBottom", {
            get: function () {
                return this._cleanProp('borderBottom');
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FWidget.prototype, "borderLeft", {
            get: function () {
                return this._cleanProp('borderLeft');
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FWidget.prototype, "radius", {
            get: function () {
                return this._cleanProp('radius');
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FWidget.prototype, "shadow", {
            get: function () {
                return this._cleanProp('shadow');
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FWidget.prototype, "cursor", {
            get: function () {
                return this._cleanProp('cursor');
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FWidget.prototype, "transform", {
            get: function () {
                var t = this._cleanProp('transform');
                return t ? __assign({}, t) : { sx: 1, sy: 1, ox: 0, oy: 0, tx: 0, ty: 0 };
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FWidget.prototype, "frame", {
            get: function () {
                return this.rect;
            },
            set: function (rect) {
                this.updateByCfg({
                    x: rect.x,
                    y: rect.y,
                    width: rect.width,
                    height: rect.height,
                });
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FWidget.prototype, "size", {
            get: function () {
                return new FSize(this.width, this.height);
            },
            set: function (s) {
                var rect = new FRect(this.x, this.y, s.width, s.height);
                this.frame = rect;
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(FWidget.prototype, "origin", {
            get: function () {
                return new FPoint(this.x, this.y);
            },
            set: function (p) {
                this.updateByCfg({
                    x: p.x,
                    y: p.y
                });
            },
            enumerable: true,
            configurable: true
        });
        FWidget.prototype.respondEvent = function (etype) {
            var ignore = this.ignore;
            if (typeof ignore === 'boolean') {
                return !ignore;
            }
            else if (typeof ignore === 'object') {
                return ignore.indexOf(etype) === -1;
            }
            else {
                return ignore !== etype;
            }
        };
        FWidget.prototype.selfRect = function () {
            return new FRect(0, 0, this.width, this.height);
        };
        FWidget.prototype.findWidget = function (pt, etype) {
            pt = this.mapFromParent(pt.clone());
            var p = null;
            var w = this.selfRect().containPoint(pt) ? this : null;
            while (w !== p && w) {
                p = w;
                var iter = w.children().iterator();
                while (iter.prev()) {
                    var c = iter.data();
                    if (!c.hidden && c.respondEvent(etype)) {
                        var selfPt = c.mapFromParent(pt.clone());
                        if (c.selfRect().containPoint(selfPt)) {
                            pt = c.mapFromParent(pt);
                            w = c;
                            break;
                        }
                    }
                }
            }
            return w;
        };
        FWidget.prototype.addEventFilter = function (filter) {
            this._filters.push(filter);
        };
        FWidget.prototype.removeEventFilter = function (filter) {
            this._filters = this._filters.filter(function (f) { return f !== filter; });
        };
        FWidget.prototype.eventFilters = function () {
            return this._filters;
        };
        FWidget.prototype.paint = function (ctx, dirtyArea) {
            ctx.save();
            if (this._cfg.transform !== undefined) {
                var _a = this._transformInfo(true), ox = _a.ox, oy = _a.oy, sx = _a.sx, sy = _a.sy, tx = _a.tx, ty = _a.ty;
                ctx.translate(tx + ox - ox * sx, ty + oy - oy * sy);
                ctx.logic2DeviceRect(dirtyArea).rounds();
                ctx.deviceRect2Logic(dirtyArea);
                ctx.scale(sx, sy);
            }
            // render scope
            if (!dirtyArea.equal(this.paintedRect())) {
                ctx.beginPath();
                ctx.rect(dirtyArea);
                ctx.clip();
            }
            this.renderWidget(ctx, dirtyArea);
            var x = ctx.xDeviceRound(this._cfg.x);
            var y = ctx.yDeviceRound(this._cfg.y);
            dirtyArea.x -= x;
            dirtyArea.y -= y;
            ctx.translate(x, y);
            this.renderChildren(ctx, dirtyArea);
            ctx.translate(-x, -y);
            this._paintBorder(ctx);
            ctx.restore();
        };
        FWidget.prototype.renderChildren = function (ctx, dirtyArea) {
            var _this = this;
            if (this.hasChild()) {
                this.children().each(function (w) {
                    var paintRect = dirtyArea.clone();
                    if (_this._isChildNeedPaint(w, paintRect)) {
                        w.paint(ctx, paintRect);
                    }
                });
            }
        };
        FWidget.prototype.mapFromParent = function (pt) {
            var t = this._transformInfo(false);
            return pt.move(-this.x, -this.y).rtransform(t);
        };
        FWidget.prototype.mapToParent = function (pt) {
            var t = this._transformInfo(false);
            return pt.transform(t).move(this.x, this.y);
        };
        FWidget.prototype.mapFromGlobal = function (pt) {
            var path = [];
            parentLoop(this, function (p) {
                path.push(p);
                return false;
            });
            path.reverse().forEach(function (w) { return w.mapFromParent(pt); });
            return pt;
        };
        FWidget.prototype.mapToGlobal = function (pt) {
            parentLoop(this, function (p) {
                p.mapToParent(pt);
                return false;
            });
            return pt;
        };
        FWidget.prototype.updateByCfg = function (cfg) {
            var changes = _super.prototype.updateByCfg.call(this, cfg);
            var parent = this.parent();
            if (parent !== null && !parent.isChildDirty && this.isSelfDirty) {
                parent._dirtyList(exports.WidgetProps.ChildDirty);
            }
            if ('zindex' in changes) {
                if (parent !== null) {
                    parent.removeChild(this);
                    this._zindex = cfg.zindex;
                    parent.addChild(this);
                }
                else {
                    this._zindex = cfg.zindex;
                }
            }
            if (parent)
                parent.onChildChange(this, changes);
            return changes;
        };
        FWidget.prototype.parent = function () {
            return _super.prototype.parent.call(this);
        };
        FWidget.prototype.addChild = function (w) {
            _super.prototype.addChild.call(this, w);
            this._dirtyList(exports.WidgetProps.ChildDirty);
            this.event(new FEvent(exports.FEventType.AddChild, w));
        };
        FWidget.prototype.removeChild = function (w) {
            if (w.parent() === this) {
                this.markDirtyRect(w.paintedRect());
                this._dirtyList(exports.WidgetProps.ChildDirty);
                _super.prototype.removeChild.call(this, w);
                w.detectLifetimeOnce();
                this.event(new FEvent(exports.FEventType.RemoveChild, w));
            }
            else {
                console.error('remove a child is not this widget child');
            }
        };
        FWidget.prototype.removeSelf = function () {
            if (this.parent()) {
                this.parent().removeChild(this);
            }
        };
        FWidget.prototype.children = function () {
            return _super.prototype.children.call(this);
        };
        FWidget.prototype.event = function (e) {
            var res = _super.prototype.event.call(this, e);
            if (!e.defaultPrevented) {
                res = res || this._partationEvent(e);
            }
            return res;
        };
        FWidget.prototype.mouseDown = function (e) {
            return false;
        };
        FWidget.prototype.mouseMove = function (e) {
            return false;
        };
        FWidget.prototype.mouseUp = function (e) {
            return false;
        };
        FWidget.prototype.click = function (e) {
            return false;
        };
        FWidget.prototype.dblClick = function (e) {
            return false;
        };
        FWidget.prototype.mouseEnter = function (e) {
            return false;
        };
        FWidget.prototype.mouseLeave = function (e) {
            return false;
        };
        FWidget.prototype.mouseWheel = function (e) {
            return false;
        };
        FWidget.prototype.contextMenu = function (e) {
            return false;
        };
        FWidget.prototype.dragStart = function (e) {
            var ctx = e.defautDragImageCtx();
            ctx.save();
            ctx.translate(-this.x, -this.y);
            this.paint(ctx, this.paintedRect());
            ctx.restore();
            return true;
        };
        FWidget.prototype.dragEnd = function (e) {
            return false;
        };
        FWidget.prototype.dragOver = function (e) {
            return false;
        };
        FWidget.prototype.dragEnter = function (e) {
            return false;
        };
        FWidget.prototype.dragLeave = function (e) {
            return false;
        };
        FWidget.prototype.dragEvent = function (e) {
            return false;
        };
        FWidget.prototype.dropEvent = function (e) {
            return false;
        };
        FWidget.prototype.tap = function (e) {
            return false;
        };
        FWidget.prototype.panStart = function (e) {
            return false;
        };
        FWidget.prototype.panMove = function (e) {
            return false;
        };
        FWidget.prototype.panEnd = function (e) {
            return false;
        };
        FWidget.prototype.panCancel = function (e) {
            return false;
        };
        FWidget.prototype.press = function (e) {
            return false;
        };
        FWidget.prototype.pressUp = function (e) {
            return false;
        };
        FWidget.prototype.swipe = function (e) {
            return false;
        };
        FWidget.prototype.rotateStart = function (e) {
            return false;
        };
        FWidget.prototype.rotateMove = function (e) {
            return false;
        };
        FWidget.prototype.rotateEnd = function (e) {
            return false;
        };
        FWidget.prototype.rotateCancel = function (e) {
            return false;
        };
        FWidget.prototype.pinchStart = function (e) {
            return false;
        };
        FWidget.prototype.pinchMove = function (e) {
            return false;
        };
        FWidget.prototype.pinchEnd = function (e) {
            return false;
        };
        FWidget.prototype.pinchCancel = function (e) {
            return false;
        };
        /**
         * Immediatly flush config and mark dirty area.
         * when you call this function, all dirty area will be
         * repaint in next tick.
         *
         * Mind that flush an island widget will not mark dirty area
         * and not effect next tick draw.
         */
        FWidget.prototype.flushCfg = function (needDirtyArea) {
            var _this = this;
            var parent = this.parent();
            var changes = this._changes;
            var propChanged = changes.size > 0;
            var echanges = {};
            var ot = this._transformInfo(true);
            if (propChanged) {
                changes.forEach(function (v, k) {
                    echanges[k] = { before: _this._cfg[k], current: v };
                });
                this.event(new FChangeEvent(exports.FEventType.BeforeFlush, this, echanges));
                if (needDirtyArea) {
                    var oRect = this.paintedRect();
                    var dirty = this._flushProps(echanges);
                    if (dirty) {
                        // should map old rect into new transform, get a logic rect
                        var nt = this._transformInfo(false);
                        oRect.transform(ot).rtransform(nt);
                        var nRect = this.paintedRect();
                        if (!parent) {
                            this.markDirtyRect(oRect);
                            this.markDirtyRect(nRect);
                        }
                        else {
                            parent.markDirtyRect(oRect.transform(nt));
                            parent.markDirtyRect(nRect.transform(nt));
                            this._dirtyRect.reset();
                        }
                        // if self mark dirty rect, children needn't mark dirty rect
                        needDirtyArea = false;
                    }
                }
                else {
                    this._flushProps(echanges);
                }
            }
            if (this.isChildDirty) {
                this._setProps(exports.WidgetProps.ChildDirty, false);
                this.children().each(function (child) { return child.flushCfg(needDirtyArea); });
            }
            if (propChanged) {
                this.event(new FChangeEvent(exports.FEventType.AfterFlush, this, echanges));
            }
            if (!this._dirtyRect.isEmpty() && parent) {
                var nt = this._transformInfo(false);
                var dRect = this._dirtyRect;
                dRect.move(this._cfg.x, this._cfg.y).transform(nt);
                dRect.intersectRect(this.paintedRect().transform(nt));
                parent.markDirtyRect(dRect);
                dRect.reset();
            }
        };
        FWidget.prototype.paintedRect = function () {
            var _a = this._cfg, x = _a.x, y = _a.y, width = _a.width, height = _a.height, shadow = _a.shadow;
            var rect = new FRect(x, y, width, height);
            if (shadow !== undefined) {
                this._rectAppendShadow(rect, shadow);
            }
            return rect;
        };
        FWidget.prototype.contentRect = function (rendered) {
            var cfg = rendered ? this._cfg : this;
            var x = cfg.x, y = cfg.y, width = cfg.width, height = cfg.height, padding = cfg.padding, border = cfg.border;
            var dBorder = { width: 0, color: '' };
            border = QuaterSplit(border, dBorder);
            padding = QuaterSplit(padding, 0);
            x += padding[3] + border[3].width;
            y += padding[0] + border[0].width;
            width = width - padding[1] - padding[3] - border[1].width - border[3].width;
            height = height - padding[0] - padding[2] - border[0].width - border[2].width;
            return new FRect(x, y, width, height);
        };
        FWidget.prototype.markDirtyRect = function (rect) {
            this._dirtyRect.union(rect);
        };
        FWidget.prototype.fvgNode = function () {
            var cfg = this._cfg;
            var nodeCfg = {
                x: cfg.x,
                y: cfg.y,
                width: cfg.width,
                height: cfg.height,
                draggable: this.draggable,
                droppable: this.droppable,
            };
            var node = {
                type: exports.WidgetType.widget,
                cfg: nodeCfg,
            };
            if (cfg.zindex !== undefined)
                nodeCfg.zindex = cfg.zindex;
            if (cfg.hidden !== undefined)
                nodeCfg.hidden = cfg.hidden;
            if (cfg.ignore !== undefined)
                nodeCfg.ignore = cfg.ignore;
            if (cfg.background !== undefined)
                nodeCfg.background = cfg.background;
            if (cfg.foreground !== undefined)
                nodeCfg.foreground = cfg.foreground;
            if (cfg.shadow !== undefined)
                nodeCfg.shadow = cfg.shadow;
            if (cfg.radius !== undefined)
                nodeCfg.radius = cfg.radius;
            if (cfg.padding !== undefined)
                nodeCfg.padding = cfg.padding;
            if (cfg.borderTop !== undefined)
                nodeCfg.borderTop = cfg.borderTop;
            if (cfg.borderRight !== undefined)
                nodeCfg.borderRight = cfg.borderRight;
            if (cfg.borderBottom !== undefined)
                nodeCfg.borderBottom = cfg.borderBottom;
            if (cfg.borderLeft !== undefined)
                nodeCfg.borderLeft = cfg.borderLeft;
            if (cfg.border !== undefined)
                nodeCfg.border = cfg.border;
            if (cfg.cursor !== undefined)
                nodeCfg.cursor = cfg.cursor;
            return node;
        };
        /**
         * detect if w need paint by dirty area,
         * and reset the paint rect to a new rect which this widget to paint.
         */
        FWidget.prototype._isChildNeedPaint = function (w, paintArea) {
            if (w._cfg.hidden)
                return false;
            var t = w._cfg.transform;
            if (t !== undefined) {
                paintArea.rtransform(t);
            }
            paintArea.intersectRect(w.paintedRect());
            return !paintArea.isEmpty();
        };
        FWidget.prototype.renderWidget = function (ctx, renderRect) {
            ctx.save();
            var x = this._cfg.x;
            var y = this._cfg.y;
            var width = this._cfg.width;
            var height = this._cfg.height;
            var _a = this._cfg, radius = _a.radius, shadow = _a.shadow, background = _a.background;
            if (shadow) {
                ctx.shadowBlur = shadow.blur || SHADOW_BLUR;
                ctx.shadowColor = shadow.color || SHADOW_COLOR;
                ctx.shadowOffsetX = shadow.offsetX || SHADOW_OFFSET_X;
                ctx.shadowOffsetY = shadow.offsetY || SHADOW_OFFSET_Y;
            }
            ctx.fillStyle = background || BACKGROUND;
            var _b = this._quaterSplitRadius(radius, width, height), rTop = _b[0], rRight = _b[1], rBottom = _b[2], rLeft = _b[3];
            ctx.beginPath();
            ctx.moveTo(x + rTop, y);
            ctx.lineTo(x + width - rRight, y);
            if (rRight > 0) {
                ctx.arc(x + width - rRight, y + rRight, rRight, 3 / 2 * Math.PI, 2 * Math.PI);
            }
            ctx.lineTo(x + width, y + height - rBottom);
            if (rBottom > 0) {
                ctx.arc(x + width - rBottom, y + height - rBottom, rBottom, 0, 1 / 2 * Math.PI);
            }
            ctx.lineTo(x + rLeft, y + height);
            if (rLeft > 0) {
                ctx.arc(x + rLeft, y + height - rLeft, rLeft, 1 / 2 * Math.PI, Math.PI);
            }
            ctx.lineTo(x, y + rTop);
            if (rTop > 0) {
                ctx.arc(x + rTop, y + rTop, rTop, Math.PI, 3 / 2 * Math.PI);
            }
            ctx.closePath();
            ctx.fill();
            ctx.restore();
        };
        FWidget.prototype._dirtyList = function (dirty) {
            parentLoop(this, function (w) {
                if (w._getProps(dirty))
                    return true;
                w._setProps(dirty, true);
                return false;
            });
        };
        /// flush props from _changes to cfg,
        /// return if the area is dirty
        FWidget.prototype._flushProps = function (changes) {
            var _this = this;
            var dirty = false;
            Object.keys(changes).forEach(function (k) {
                // todo: we should split cfg into two part: effect render or not effect render.
                var v = changes[k];
                if (k === 'draggable') {
                    _this.draggable = v.current;
                }
                else if (k === 'dropable') {
                    _this.droppable = v.current;
                }
                else if (k === '_phantom') {
                    _this._changes.delete(k);
                    dirty = true;
                }
                else {
                    _this._cfg[k] = v.current;
                    if (k !== 'cursor' && k !== 'ignore')
                        dirty = true;
                }
                // remove flushed prop in changes,
                // the props that updated during flush period will enter next lifetime cycle.
                if (_this._changes.get(k) === v.current)
                    _this._changes.delete(k);
            });
            return dirty;
        };
        FWidget.prototype._defalutCfg = function () {
            return { x: 0, y: 0, width: 0, height: 0 };
        };
        FWidget.prototype._paintBorder = function (ctx) {
            // clear shadow
            ctx.shadowBlur = 0;
            ctx.shadowOffsetX = 0;
            ctx.shadowOffsetY = 0;
            var _a = this._cfg, x = _a.x, y = _a.y, width = _a.width, height = _a.height, radius = _a.radius;
            var _b = this._cfg, border = _b.border, borderTop = _b.borderTop, borderRight = _b.borderRight, borderBottom = _b.borderBottom, borderLeft = _b.borderLeft;
            var _c = QuaterSplit(border, { color: '', width: 0 }, borderTop, borderRight, borderBottom, borderLeft), bTop = _c[0], bRight = _c[1], bBottom = _c[2], bLeft = _c[3];
            // adjust radius
            var _d = QuaterSplit(radius, 0), rTL = _d[0], rTR = _d[1], rBR = _d[2], rBL = _d[3];
            /**
             *  borders case with radius.
             *  we split border to many area to paint.
             *   /+--------------------------------+
             *  /_|(tlX, tlY)                      | \
             * |   \                  (trX, trY)<--+--+
             * |    \                             /   |
             * |     +---------------------------+    |
             * |     |                           |    |
             * |     |                           |    |
             * |     |                           |    |
             * |     |                           |    |
             * |     |                           |    |
             * |     |                           |    |
             * |     |                           |    |
             * |     |   (blX, blY)              |    |
             * |     |  /             (brX, brY) |    |
             * +-----+-+-------------------------+    |
             * \       |                          \   |
             *   \     |                            \ |
             *     \___|______________________________|
             */
            var tlX = x + rTL;
            var tlY = y + rTL;
            var trX = x + width - rTR;
            var trY = y + rTR;
            var blX = x + rBL;
            var blY = y + height - rBL;
            var brX = x + width - rBR;
            var brY = y + height - rBR;
            var rBorderXpos = ctx.xDeviceRound(x + width) - bRight.width;
            var bBorderYPos = ctx.yDeviceRound(y + height) - bBottom.width;
            if (bTop.width > 0) {
                ctx.save();
                ctx.beginPath();
                ctx.moveTo(tlX, y);
                ctx.lineTo(tlX, tlY);
                ctx.lineTo(x + bLeft.width, y + bTop.width);
                ctx.lineTo(x + width - bRight.width, y + bTop.width);
                ctx.lineTo(trX, trY);
                ctx.lineTo(trX, y);
                ctx.clip();
                this._drawLine(ctx, bTop, x, y, x + width, y);
                ctx.restore();
            }
            if (bRight.width > 0) {
                ctx.save();
                ctx.beginPath();
                ctx.moveTo(x + width, trY);
                ctx.lineTo(trX, trY);
                ctx.lineTo(rBorderXpos, y + bTop.width);
                ctx.lineTo(rBorderXpos, bBorderYPos);
                ctx.lineTo(brX, brY);
                ctx.lineTo(x + width, brY);
                ctx.clip();
                this._drawLine(ctx, bRight, rBorderXpos, y, rBorderXpos, y + height);
                ctx.restore();
            }
            if (bBottom.width > 0) {
                ctx.save();
                ctx.beginPath();
                ctx.moveTo(brX, y + height);
                ctx.lineTo(brX, brY);
                ctx.lineTo(rBorderXpos, bBorderYPos);
                ctx.lineTo(x + bLeft.width, bBorderYPos);
                ctx.lineTo(blX, blY);
                ctx.lineTo(blX, y + height);
                ctx.clip();
                this._drawLine(ctx, bBottom, x, bBorderYPos, x + width, bBorderYPos);
                ctx.restore();
            }
            if (bLeft.width > 0) {
                ctx.save();
                ctx.beginPath();
                ctx.moveTo(x, blY);
                ctx.lineTo(blX, blY);
                ctx.lineTo(x + bLeft.width, bBorderYPos);
                ctx.lineTo(x + bLeft.width, y + bTop.width);
                ctx.lineTo(tlX, tlY);
                ctx.lineTo(x, tlY);
                ctx.clip();
                this._drawLine(ctx, bLeft, x, y + height, x, y);
                ctx.restore();
            }
            // draw left top corner
            this._drawBorderLTCorner(ctx, tlX, tlY, rTL, 0, bLeft, bTop);
            // draw right top corner
            this._drawBorderLTCorner(ctx, trX, trY, rTR, Math.PI / 2, bTop, bRight);
            // draw right bottom corner
            this._drawBorderLTCorner(ctx, brX, brY, rBR, Math.PI, bRight, bBottom);
            // draw left bottom corner
            this._drawBorderLTCorner(ctx, blX, blY, rBL, 3 / 2 * Math.PI, bBottom, bLeft);
        };
        FWidget.prototype._collectRadians = function (opposite, adjacent, lineDash) {
            var radians = [0];
            var i = 0;
            var ox = 0;
            while (ox < opposite) {
                var size = lineDash[i++ % lineDash.length];
                ox = Math.min(ox + size, opposite);
                radians.push(Math.atan(ox / adjacent));
            }
            return radians;
        };
        FWidget.prototype._drawLine = function (ctx, bstyle, x1, y1, x2, y2) {
            ctx.beginPath();
            ctx.lineWidth = bstyle.width;
            ctx.strokeStyle = bstyle.color;
            if (bstyle.style === exports.borderDash.dash)
                ctx.setLineDash(dashLine);
            ctx.drawLine(x1, y1, x2, y2);
        };
        FWidget.prototype._drawBorderLTCorner = function (ctx, cx, cy, radius, rotation, left, top) {
            if (radius <= 0)
                return;
            if (left.width <= 0 && top.width <= 0)
                return;
            ctx.save();
            ctx.translate(cx, cy);
            ctx.rotate(rotation);
            if (radius > top.width && radius > left.width) {
                var drawDashRadians = function (radians) {
                    var i = 0;
                    while (i + 1 < radians.length) {
                        var start = radians[i++];
                        var end = radians[i++];
                        ctx.beginPath();
                        ctx.arc(0, 0, radius, start, end);
                        ctx.lineTo(0, 0);
                        ctx.fill();
                    }
                };
                ctx.beginPath();
                ctx.arc(0, 0, radius, Math.PI, 3 / 2 * Math.PI);
                ctx.ellipse(0, 0, radius - left.width, radius - top.width, 0, 3 / 2 * Math.PI, Math.PI, true);
                ctx.clip();
                // draw left border half
                var leftSegs = left.style !== exports.borderDash.dash ? [Math.PI, 5 / 4 * Math.PI]
                    : this._collectRadians(radius, radius, dashLine).map(function (r) { return r + Math.PI; });
                ctx.fillStyle = left.color;
                drawDashRadians(leftSegs);
                // draw top border half
                var topSegs = top.style !== exports.borderDash.dash ? [5 / 4 * Math.PI, 3 / 2 * Math.PI]
                    : this._collectRadians(radius, radius, dashLine).reverse().map(function (r) { return 3 / 2 * Math.PI - r; });
                ctx.fillStyle = top.color;
                drawDashRadians(topSegs);
            }
            else {
                var strokeBorder = function (border, start, end) {
                    ctx.strokeStyle = border.color;
                    ctx.setLineDash(border.style === exports.borderDash.dash ? dashLine : []);
                    ctx.lineWidth = radius;
                    ctx.beginPath();
                    ctx.arc(0, 0, radius / 2, start, end);
                    ctx.stroke();
                };
                strokeBorder(left, Math.PI, 5 / 4 * Math.PI);
                strokeBorder(top, 5 / 4 * Math.PI, 3 / 2 * Math.PI);
            }
            ctx.restore();
        };
        FWidget.prototype._rectAppendShadow = function (rect, shadow) {
            var offsetX = shadow.offsetX || 0;
            var offsetY = shadow.offsetY || 0;
            var blur = shadow.blur || 0;
            var left = Math.floor(rect.x - 0.5 * blur + offsetX - 1);
            var top = Math.floor(rect.y - 0.5 * blur + offsetY - 1);
            var right = Math.floor(rect.x + rect.width + blur + 2);
            var bottom = Math.floor(rect.y + rect.height + blur + 2);
            var shadowRect = new FRect(left, top, right - left, bottom - top);
            return rect.union(shadowRect);
        };
        FWidget.prototype._quaterSplitRadius = function (radius, width, height) {
            var minW = Math.min(width, height) / 2;
            var _a = QuaterSplit(radius, 0), rTop = _a[0], rRight = _a[1], rBottom = _a[2], rLeft = _a[3];
            rTop = Math.min(rTop, minW);
            rRight = Math.min(rRight, minW);
            rBottom = Math.min(rBottom, minW);
            rLeft = Math.min(rLeft, minW);
            return [rTop, rRight, rBottom, rLeft];
        };
        FWidget.prototype._partationEvent = function (e) {
            switch (e.type) {
                case exports.FEventType.MouseMove:
                    return this.mouseMove(e);
                case exports.FEventType.MouseDown:
                    return this.mouseDown(e);
                case exports.FEventType.MouseUp:
                    return this.mouseUp(e);
                case exports.FEventType.Click:
                    return this.click(e);
                case exports.FEventType.Dblclick:
                    return this.dblClick(e);
                case exports.FEventType.MouseEnter:
                    return this.mouseEnter(e);
                case exports.FEventType.MouseLeave:
                    return this.mouseLeave(e);
                case exports.FEventType.MouseWheel:
                    return this.mouseWheel(e);
                case exports.FEventType.ContextMenu:
                    return this.contextMenu(e);
                case exports.FEventType.DragStart:
                    if (!this.draggable)
                        return false;
                    else
                        return this.dragStart(e);
                case exports.FEventType.Drag:
                    if (!this.draggable)
                        return false;
                    else
                        return this.dragEvent(e);
                case exports.FEventType.Drop:
                    if (!this.droppable)
                        return false;
                    else
                        return this.dropEvent(e);
                case exports.FEventType.DragOver:
                    if (!this.droppable)
                        return false;
                    else
                        return this.dragOver(e);
                case exports.FEventType.DragEnd:
                    if (!this.draggable)
                        return false;
                    else
                        return this.dragEnd(e);
                case exports.FEventType.DragEnter:
                    if (!this.droppable)
                        return false;
                    else
                        return this.dragEnter(e);
                case exports.FEventType.DragLeave:
                    if (!this.droppable)
                        return false;
                    else
                        return this.dragLeave(e);
                case exports.FEventType.Tap:
                    return this.tap(e);
                case exports.FEventType.PanStart:
                    return this.panStart(e);
                case exports.FEventType.PanMove:
                    return this.panMove(e);
                case exports.FEventType.PanEnd:
                    return this.panEnd(e);
                case exports.FEventType.PanCancel:
                    return this.panCancel(e);
                case exports.FEventType.Press:
                    return this.press(e);
                case exports.FEventType.PressUp:
                    return this.pressUp(e);
                case exports.FEventType.Swipe:
                    return this.swipe(e);
                case exports.FEventType.RotateStart:
                    return this.rotateStart(e);
                case exports.FEventType.RotateMove:
                    return this.rotateMove(e);
                case exports.FEventType.RotateEnd:
                    return this.rotateEnd(e);
                case exports.FEventType.RotateCancel:
                    return this.rotateCancel(e);
                case exports.FEventType.PinchStart:
                    return this.pinchStart(e);
                case exports.FEventType.PinchMove:
                    return this.pinchMove(e);
                case exports.FEventType.PinchEnd:
                    return this.pinchEnd(e);
                case exports.FEventType.PinchCancel:
                    return this.pinchCancel(e);
                case exports.FEventType.BeforeFlush:
                    this.beforeFlush(e);
                    return false;
                case exports.FEventType.AfterFlush:
                    this.afterFlush(e);
                    return false;
                case exports.FEventType.AfterChange:
                    this.afterChange(e);
                    return false;
                case exports.FEventType.BeforeChange:
                    this.beforeChange(e);
                    return false;
                case exports.FEventType.BeforeTick:
                    this.beforeTick(e);
                    return false;
                case exports.FEventType.AfterTick:
                    this.afterTick(e);
                    return false;
                default: return false;
            }
        };
        FWidget.prototype._transformInfo = function (rendered) {
            if (rendered) {
                var t = this._cfg.transform;
                if (t === undefined) {
                    return { ox: 0, oy: 0, sx: 1, sy: 1, tx: 0, ty: 0 };
                }
                return t;
            }
            else {
                return this.transform;
            }
        };
        // user should never use below two function.
        FWidget.prototype._setProps = function (prop, flag) {
            if (flag)
                this._props = this._props | (1 << prop);
            else
                this._props = this._props & (~(1 << prop));
        };
        FWidget.prototype._getProps = function (prop) {
            return !!(this._props & (1 << prop));
        };
        return FWidget;
    }(FObj));

    var FApp = /** @class */ (function () {
        function FApp() {
        }
        FApp.doTick = function () {
            var insArr = FApp.running;
            for (var i = 0; i < insArr.length; i++) {
                try {
                    insArr[i].tick();
                }
                catch (e) {
                    console.error(e);
                }
            }
            try {
                ListenersControl.doTick();
            }
            catch (e) {
                console.error(e);
            }
            FApp.animationId = requestAnimationFrame(FApp.doTick);
            FApp.cbMap.forEach(function (cb) { return cb(); });
        };
        FApp.start = function (f) {
            if (FApp.running.length === 0) {
                FApp.doTick();
            }
            FApp.running.push(f);
        };
        FApp.exit = function (f) {
            FApp.running = FApp.running.filter(function (faster) { return f !== faster; });
            if (FApp.running.length === 0) {
                cancelAnimationFrame(FApp.animationId);
                FApp.animationId = 0;
            }
        };
        FApp.addIdleListener = function (cb) {
            var id = FApp.cbId++;
            FApp.cbMap.set(id, cb);
            return id;
        };
        FApp.removeIdleListener = function (id) {
            if (FApp.cbMap.has(id)) {
                FApp.cbMap.delete(id);
            }
        };
        FApp.running = [];
        FApp.animationId = 0;
        FApp.cbMap = new Map();
        FApp.cbId = 1000;
        return FApp;
    }());

    var FTickEvent = /** @class */ (function (_super) {
        __extends(FTickEvent, _super);
        function FTickEvent(type, target) {
            return _super.call(this, type, target) || this;
        }
        return FTickEvent;
    }(FEvent));

    var Faster = /** @class */ (function (_super) {
        __extends(Faster, _super);
        function Faster(host) {
            var _this = _super.call(this, null) || this;
            _this._offset = { x: 0, y: 0, };
            _this._offsetDirty = false;
            _this._pinchScale = { sx: 1, sy: 1 };
            _this._isActive = false;
            _this.isWindowBlur = false;
            _this._setOffsetDirty = function () {
                _this._offsetDirty = true;
            };
            _this._windowBlured = function () {
                _this.isWindowBlur = true;
            };
            _this._windowFocused = function () {
                _this.isWindowBlur = false;
            };
            if (host instanceof HTMLCanvasElement) {
                _this._canvas = FCanvasPool.borrowCanvas(_this, host);
            }
            else {
                _this._canvas = FCanvasPool.borrowCanvas(_this);
                host.appendChild(_this._canvas.element());
            }
            _this._canvas.registerNotiry(function (t) {
                var rect = _this.paintedRect();
                _this.markDirtyRect(rect);
            });
            _this._dispatcher = new Dispatcher(_this);
            setTimeout(function () { return _this.updateOffset(); });
            return _this;
        }
        Faster.sendEvent = function (w, e, async) {
            return ListenersControl.sendEvent(w, e, async);
        };
        Faster.findFaster = function (w) {
            var p = w;
            while (p.parent() !== null)
                p = p.parent();
            if (p instanceof Faster)
                return p;
            return null;
        };
        Faster.prototype.dispatcher = function () {
            return this._dispatcher;
        };
        Faster.prototype.canvas = function () {
            return this._canvas;
        };
        Faster.prototype.updateDraggable = function (flag) {
            this._canvas.element().draggable = flag;
        };
        Faster.prototype.updateOffset = function () {
            var rect = this._canvas.element().getBoundingClientRect();
            this._offset.x = rect.left + this.scrollX;
            this._offset.y = rect.top + this.scrollY;
            this._offsetDirty = false;
        };
        Faster.prototype.suspend = function () {
            if (!this._isActive)
                return;
            this._isActive = false;
            var canvas = FCanvasPool.mallocedCanvas(this);
            canvas.forEach(function (c) { return c.suspend(); });
            FApp.exit(this);
            this._dispatcher.stop();
            this._unbindEvents();
        };
        Faster.prototype.wakeup = function () {
            if (this._isActive)
                return;
            this._isActive = true;
            var canvas = FCanvasPool.mallocedCanvas(this);
            canvas.forEach(function (c) { return c.wakeup(); });
            FApp.start(this);
            this._canvas.resize(this.width, this.height);
            this._dispatcher.start();
            this._bindEvents();
            this._setOffsetDirty();
        };
        Faster.prototype.exec = function () {
            this.wakeup();
        };
        Faster.prototype.exit = function () {
            if (this._isActive) {
                this.suspend();
            }
            this._dispatcher.destroy();
            this.destroy();
        };
        Faster.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            FCanvasPool.backCanvas(this._canvas);
        };
        Faster.prototype.domPoint2Faster = function (pt) {
            // 如果位置已发生移动，则需要更新Offset
            if (this._offsetDirty) {
                this.updateOffset();
            }
            var _a = this._offset, x = _a.x, y = _a.y;
            x -= this.scrollX;
            y -= this.scrollY;
            return new FPoint(pt.x - x, pt.y - y);
        };
        Faster.prototype.findWidgetByMultiPoint = function (pointers, type) {
            var _this = this;
            var widgets = pointers.map(function (pt) { return _this.findWidget(pt, type); });
            var path = [];
            widgets.forEach(function (w) {
                if (path.length === 0) {
                    parentLoop(w, function (p) {
                        path.push(p);
                        return false;
                    });
                }
                else {
                    parentLoop(w, function (p) {
                        var idx = path.findIndex(function (p1) { return p1 === p; });
                        if (idx !== -1) {
                            path = path.slice(idx);
                            return true;
                        }
                        return false;
                    });
                }
            });
            if (path.length === 0)
                return null;
            else
                return path.shift();
        };
        Faster.prototype.tick = function () {
            FCanvasPool.updateDPI();
            var dirty = false;
            if (this.isSelfDirty || this.isChildDirty || !this._dirtyRect.isEmpty()) {
                // 每隔 16 ms 都会触发 tick。但只有 dirty 的 tick 事件才有意义
                dirty = true;
                this.event(new FTickEvent(exports.FEventType.BeforeTick, this));
            }
            while (this.isSelfDirty || this.isChildDirty) {
                this.flushCfg(true);
            }
            var dRect = this._dirtyRect;
            if (!dRect.isEmpty()) {
                var ctx = this._canvas.ctx();
                var t = this._cfg.transform;
                if (t !== undefined) {
                    ctx.clearRect(dRect.transform(t));
                    dRect.rtransform(t);
                }
                else {
                    ctx.clearRect(dRect);
                }
                dRect.intersectRect(this.paintedRect());
                if (!dRect.isEmpty())
                    this.paint(ctx, dRect);
                this._dirtyRect.reset();
            }
            this.refreshCursor();
            if (dirty) {
                this.event(new FTickEvent(exports.FEventType.AfterTick, this));
            }
        };
        Faster.prototype.fvgNode = function () {
            var node = _super.prototype.fvgNode.call(this);
            node.type = exports.WidgetType.faster;
            return node;
        };
        Faster.prototype.refreshCursor = function () {
            var cursor = '';
            parentLoop(this._dispatcher.cursorWidget(), function (w) {
                cursor = w.cursor;
                return cursor !== '' && cursor !== undefined;
            });
            var dom = this._canvas.element();
            dom.style.cursor = cursor || this.cursor || 'default';
        };
        Faster.prototype.pinchStart = function (e) {
            var t = this.transform;
            this._pinchScale = { sx: t.sx, sy: t.sy };
            var lt = new FPoint(0, 0).transform(t);
            t.ox = e.center.x;
            t.oy = e.center.y;
            var lt2 = new FPoint(0, 0).transform(t);
            var offset = lt.sub(lt2);
            t.tx += offset.x;
            t.ty += offset.y;
            t.sx *= e.scale;
            t.sy *= e.scale;
            this.updateByCfg({ transform: t });
            return false;
        };
        Faster.prototype.pinchMove = function (e) {
            var _a = this._pinchScale, sx = _a.sx, sy = _a.sy;
            var t = this.transform;
            t.sx = e.scale * sx;
            t.sy = e.scale * sy;
            this.updateByCfg({ transform: t });
            return false;
        };
        Faster.prototype.beforeFlush = function (e) {
            var chgs = e.changes;
            if ('width' in chgs || 'height' in chgs) {
                this._setOffsetDirty();
                this._canvas.resize(this.width, this.height);
            }
        };
        Faster.prototype._bindEvents = function () {
            var _this = this;
            ['DOMSubtreeModified', 'scroll', 'mousewheel'].forEach(function (item) {
                window.addEventListener(item, _this._setOffsetDirty);
            });
            window.addEventListener('blur', this._windowBlured);
            window.addEventListener('focus', this._windowFocused);
        };
        Faster.prototype._unbindEvents = function () {
            var _this = this;
            ['DOMSubtreeModified', 'scroll', 'mousewheel'].forEach(function (evt) {
                window.removeEventListener(evt, _this._setOffsetDirty);
            });
            window.removeEventListener('blur', this._windowBlured);
            window.removeEventListener('focus', this._windowFocused);
        };
        Object.defineProperty(Faster.prototype, "scrollX", {
            get: function () {
                var t = document.documentElement || document.body.parentNode;
                return (t && typeof t.scrollLeft === 'number' ? t : document.body).scrollLeft;
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(Faster.prototype, "scrollY", {
            get: function () {
                var t = document.documentElement || document.body.parentNode;
                return (t && typeof t.scrollTop === 'number' ? t : document.body).scrollTop;
            },
            enumerable: true,
            configurable: true
        });
        return Faster;
    }(FWidget));

    (function (FMouseButtons) {
        FMouseButtons[FMouseButtons["None"] = 0] = "None";
        FMouseButtons[FMouseButtons["MainButton"] = 1] = "MainButton";
        FMouseButtons[FMouseButtons["Secondary"] = 2] = "Secondary";
        FMouseButtons[FMouseButtons["Auxiliary"] = 4] = "Auxiliary";
    })(exports.FMouseButtons || (exports.FMouseButtons = {}));
    var FMouseEvent = /** @class */ (function (_super) {
        __extends(FMouseEvent, _super);
        function FMouseEvent(type, target, globalX, globalY, buttons, ctrlKey, shiftKey, altKey, metaKey) {
            var _this = _super.call(this, type, target) || this;
            _this.buttons = buttons;
            _this.ctrlKey = ctrlKey;
            _this.shiftKey = shiftKey;
            _this.altKey = altKey;
            _this.metaKey = metaKey;
            var pt = target.mapFromGlobal(new FPoint(globalX, globalY));
            _this.x = pt.x;
            _this.y = pt.y;
            return _this;
        }
        FMouseEvent.prototype.globalPoint = function () {
            return this.target.mapToGlobal(new FPoint(this.x, this.y));
        };
        return FMouseEvent;
    }(FUIEvent));
    var FWheelEvent = /** @class */ (function (_super) {
        __extends(FWheelEvent, _super);
        function FWheelEvent(deltaX, deltaY, target, globalX, globalY, buttons, ctrlKey, shiftKey, altKey, metaKey) {
            var _this = _super.call(this, exports.FEventType.MouseWheel, target, globalX, globalY, buttons, ctrlKey, shiftKey, altKey, metaKey) || this;
            _this.deltaX = deltaX;
            _this.deltaY = deltaY;
            _this.globalX = globalX;
            _this.globalY = globalY;
            _this.buttons = buttons;
            _this.ctrlKey = ctrlKey;
            _this.shiftKey = shiftKey;
            _this.altKey = altKey;
            _this.metaKey = metaKey;
            return _this;
        }
        return FWheelEvent;
    }(FMouseEvent));
    var FEnterEvent = /** @class */ (function (_super) {
        __extends(FEnterEvent, _super);
        function FEnterEvent(type, target, globalX, globalY, buttons, ctrlKey, shiftKey, altKey, metaKey) {
            var _this = _super.call(this, type, target, globalX, globalY, buttons, ctrlKey, shiftKey, altKey, metaKey) || this;
            _this.buttons = buttons;
            _this.ctrlKey = ctrlKey;
            _this.shiftKey = shiftKey;
            _this.altKey = altKey;
            _this.metaKey = metaKey;
            return _this;
        }
        return FEnterEvent;
    }(FMouseEvent));
    var FLeaveEvent = /** @class */ (function (_super) {
        __extends(FLeaveEvent, _super);
        function FLeaveEvent(type, target, globalX, globalY, buttons, ctrlKey, shiftKey, altKey, metaKey) {
            var _this = _super.call(this, type, target, globalX, globalY, buttons, ctrlKey, shiftKey, altKey, metaKey) || this;
            _this.globalX = globalX;
            _this.globalY = globalY;
            _this.buttons = buttons;
            _this.ctrlKey = ctrlKey;
            _this.shiftKey = shiftKey;
            _this.altKey = altKey;
            _this.metaKey = metaKey;
            return _this;
        }
        return FLeaveEvent;
    }(FMouseEvent));
    var FDragEvent = /** @class */ (function (_super) {
        __extends(FDragEvent, _super);
        function FDragEvent(type, target, globalX, globalY, buttons, ctrlKey, shiftKey, altKey, metaKey, dataTransfer, _dragImgCanvas) {
            var _this = _super.call(this, type, target, globalX, globalY, buttons, ctrlKey, shiftKey, altKey, metaKey) || this;
            _this.buttons = buttons;
            _this.ctrlKey = ctrlKey;
            _this.shiftKey = shiftKey;
            _this.altKey = altKey;
            _this.metaKey = metaKey;
            _this.dataTransfer = dataTransfer;
            _this._dragImgCanvas = _dragImgCanvas;
            return _this;
        }
        FDragEvent.prototype.srcWidget = function () {
            var uid = this.dataTransfer.getData(WIDGET_UID);
            if (uid !== '') {
                var w = FWidget.getObjById(uid);
                return w instanceof FWidget ? w : null;
            }
            else {
                return null;
            }
        };
        FDragEvent.prototype.defautDragImageCtx = function () {
            return this._dragImgCanvas.ctx();
        };
        return FDragEvent;
    }(FMouseEvent));

    (function (FDirection) {
        FDirection[FDirection["Left"] = 0] = "Left";
        FDirection[FDirection["Right"] = 1] = "Right";
        FDirection[FDirection["Up"] = 2] = "Up";
        FDirection[FDirection["Down"] = 3] = "Down";
    })(exports.FDirection || (exports.FDirection = {}));
    var FSingleTouchEvent = /** @class */ (function (_super) {
        __extends(FSingleTouchEvent, _super);
        function FSingleTouchEvent(type, target, globalCenter, deltaTime) {
            var _this = _super.call(this, type, target) || this;
            _this.deltaTime = deltaTime;
            _this.center = target.mapFromGlobal(globalCenter);
            return _this;
        }
        FSingleTouchEvent.prototype.globalCenter = function () {
            return this.target.mapToGlobal(this.center.clone());
        };
        return FSingleTouchEvent;
    }(FUIEvent));
    var FPressEvent = /** @class */ (function (_super) {
        __extends(FPressEvent, _super);
        function FPressEvent() {
            return _super !== null && _super.apply(this, arguments) || this;
        }
        return FPressEvent;
    }(FSingleTouchEvent));
    var FTapEvent = /** @class */ (function (_super) {
        __extends(FTapEvent, _super);
        function FTapEvent() {
            return _super !== null && _super.apply(this, arguments) || this;
        }
        return FTapEvent;
    }(FSingleTouchEvent));
    var FPanEvent = /** @class */ (function (_super) {
        __extends(FPanEvent, _super);
        function FPanEvent(type, target, globalCenter, deltaTime, deltaX, deltaY) {
            var _this = _super.call(this, type, target, globalCenter, deltaTime) || this;
            _this.deltaX = deltaX;
            _this.deltaY = deltaY;
            return _this;
        }
        return FPanEvent;
    }(FSingleTouchEvent));
    var FSwipeEvent = /** @class */ (function (_super) {
        __extends(FSwipeEvent, _super);
        function FSwipeEvent(type, target, globalCenter, deltaTime, velocityX, // Velocity on the X axis, in px/ms.
        velocityY, // Velocity on the Y axis, in px/ms
        velocity, // Highest velocityX/Y value.
        direction) {
            var _this = _super.call(this, type, target, globalCenter, deltaTime) || this;
            _this.velocityX = velocityX;
            _this.velocityY = velocityY;
            _this.velocity = velocity;
            _this.direction = direction;
            return _this;
        }
        return FSwipeEvent;
    }(FSingleTouchEvent));
    var FMultiTouchEvent = /** @class */ (function (_super) {
        __extends(FMultiTouchEvent, _super);
        function FMultiTouchEvent(type, target, globalCenter, deltaTime, globalPointers) {
            var _this = _super.call(this, type, target, globalCenter, deltaTime) || this;
            _this.globalPointers = globalPointers;
            _this.pointers = globalPointers.map(function (pt) { return target.mapFromGlobal(pt); });
            return _this;
        }
        return FMultiTouchEvent;
    }(FSingleTouchEvent));
    var FPincEvent = /** @class */ (function (_super) {
        __extends(FPincEvent, _super);
        function FPincEvent(type, target, globalCenter, deltaTime, globalPointers, scale) {
            var _this = _super.call(this, type, target, globalCenter, deltaTime, globalPointers) || this;
            _this.scale = scale;
            return _this;
        }
        return FPincEvent;
    }(FMultiTouchEvent));
    var FRotateEvent = /** @class */ (function (_super) {
        __extends(FRotateEvent, _super);
        function FRotateEvent(type, target, globalCenter, deltaTime, globalPointers, rotate) {
            var _this = _super.call(this, type, target, globalCenter, deltaTime, globalPointers) || this;
            _this.rotate = rotate;
            return _this;
        }
        return FRotateEvent;
    }(FMultiTouchEvent));

    var Dispatcher = /** @class */ (function () {
        function Dispatcher(_faster) {
            var _this = this;
            this._faster = _faster;
            this._autoCaptrue = null;
            this._userCaptrue = null;
            this._hammer = null;
            this._preventDefaultTouchMove = false;
            this._syntheticClick = null;
            this._preventTouchMoveEvent = function (event) {
                if (_this._preventDefaultTouchMove) {
                    event.preventDefault();
                }
            };
            this._processDomEvent = function (event) {
                var canvas = _this._faster.canvas().element();
                if (event.target === canvas || _this.isCapture()) {
                    if (event.type === 'mouseleave') {
                        if (_this._cursorWidget !== null) {
                            var _a = event, buttons = _a.buttons, ctrlKey = _a.ctrlKey, shiftKey = _a.shiftKey, altKey = _a.altKey, metaKey = _a.metaKey;
                            _this._enterLeaveDispatch(true, null, { globalX: 0, globalY: 0, buttons: buttons, ctrlKey: ctrlKey, shiftKey: shiftKey, altKey: altKey, metaKey: metaKey });
                        }
                    }
                    else {
                        _this.dispath(event);
                    }
                }
            };
            this._cursorWidget = null;
            var dom = _faster.canvas().element();
            if ('ontouchstart' in document.documentElement) {
                var hammer = new Hammer(dom, { domEvents: true, touchAction: 'auto' });
                hammer.get('pan').set({ direction: Hammer.DIRECTION_ALL });
                hammer.get('swipe').set({ direction: Hammer.DIRECTION_ALL });
                hammer.get('pinch').set({ enable: true });
                hammer.get('rotate').set({ enable: true });
                this._hammer = hammer;
            }
            this._dragCanvas = FCanvasPool.borrowCanvas(this._faster, undefined, false);
            this._dragCanvas.resize(300, 150);
            var elem = this._dragCanvas.element();
            this._dragCanvas.fakeHide();
            elem.style.opacity = '0.8';
            document.body.appendChild(elem);
        }
        Dispatcher.filterEvent = function (widget, fevent) {
            var filterStack = [];
            parentLoop(widget, function (w) {
                var filters = w.eventFilters();
                if (filters.length > 0)
                    filterStack.push(filters);
                return false;
            });
            return filterStack.reverse().some(function (filters) {
                return filters.some(function (f) { return f(fevent); });
            });
        };
        Dispatcher.prototype.isCapture = function () {
            return this._captureWidget() !== null;
        };
        Dispatcher.prototype.capture = function (w) {
            this._userCaptrue = w;
        };
        Dispatcher.prototype.lowestCommonAncestor = function (downW, upW) {
            var cp = this._faster;
            parentLoop(upW, function (cur) {
                if (cur.ancestorOf(downW)) {
                    cp = cur;
                    return true;
                }
                return false;
            });
            return cp;
        };
        Dispatcher.prototype.releaseCapture = function () {
            this._userCaptrue = null;
        };
        Dispatcher.prototype.dispath = function (event) {
            var fevent = null;
            var domEvent = null;
            // before an new auto touch captrue start
            // we need force release old.
            if (event.type === 'panstart' ||
                event.type === 'pinchstart' ||
                event.type === 'rotatestart') {
                this._autoCaptrue = null;
            }
            if (event instanceof Event) {
                var detectType = function (events) {
                    return events.findIndex(function (e) { return e === event.type; }) !== -1;
                };
                if (detectType(Dispatcher.mouseEvents)) {
                    // mouse button release, should release capture
                    var me = event;
                    if (me.buttons === 0 && event.type !== 'mouseup') {
                        this._autoCaptrue = null;
                    }
                    fevent = this._convertMouseEvent(me);
                }
                else if (detectType(Dispatcher.dragEvents)) {
                    fevent = this._convertDragEvent(event);
                }
                domEvent = event;
                // no matter can convert to fevent, dragover should prevent.
                // otherwise drop event will not fire
                if (event.type === 'dragover')
                    event.preventDefault();
            }
            else {
                fevent = this._convertHammerEvent(event);
                domEvent = event.srcEvent;
            }
            if (fevent === null || domEvent == null)
                return;
            switch (fevent.type) {
                case exports.FEventType.Drop:
                case exports.FEventType.ContextMenu:
                    domEvent.preventDefault();
                    break;
                default: break;
            }
            var processed = this.dispatchFEvent(fevent);
            if (fevent.defaultPrevented)
                domEvent.preventDefault();
            if (processed)
                domEvent.stopPropagation();
            if (fevent.type === exports.FEventType.PanMove
                || fevent.type === exports.FEventType.PanStart) {
                this._preventDefaultTouchMove = fevent.defaultPrevented;
            }
            if (fevent.type === exports.FEventType.PinchStart
                || fevent.type === exports.FEventType.PinchMove
                || fevent.type === exports.FEventType.RotateStart
                || fevent.type === exports.FEventType.RotateMove) {
                this._preventDefaultTouchMove = true;
            }
        };
        Dispatcher.prototype.dispatchFEvent = function (fevent) {
            var widget = fevent.target;
            var needEnterLeave = false;
            switch (fevent.type) {
                case exports.FEventType.MouseDown:
                case exports.FEventType.PanStart:
                case exports.FEventType.PinchStart:
                case exports.FEventType.RotateStart:
                    this._faster.updateDraggable(widget.draggable);
                    this._autoCaptrue = widget;
                    break;
                case exports.FEventType.MouseMove:
                case exports.FEventType.MouseWheel:
                case exports.FEventType.DragOver:
                    needEnterLeave = true;
                    break;
                case exports.FEventType.MouseUp:
                case exports.FEventType.PanEnd:
                case exports.FEventType.PinchEnd:
                case exports.FEventType.RotateEnd:
                case exports.FEventType.PanCancel:
                case exports.FEventType.PinchCancel:
                case exports.FEventType.RotateCancel:
                case exports.FEventType.DragEnd:
                    this._autoCaptrue = null;
                    break;
                case exports.FEventType.DragStart:
                    this._autoCaptrue = widget;
                    this._clearDragImage();
                    fevent.dataTransfer.setDragImage(this._dragCanvas.element(), 0, 0);
                    break;
                default:
                    break;
            }
            // filter from top to bottom
            var processed = Dispatcher.filterEvent(widget, fevent);
            if (processed)
                return true;
            if (fevent.type === exports.FEventType.MouseWheel && this._faster.isWindowBlur) {
                needEnterLeave = false;
            }
            if (needEnterLeave) {
                var isMouse = fevent.type === exports.FEventType.DragOver ? false : true;
                var me = fevent;
                var gpt = me.globalPoint();
                this._enterLeaveDispatch(isMouse, widget, {
                    globalX: gpt.x,
                    globalY: gpt.y,
                    buttons: me.buttons,
                    ctrlKey: me.ctrlKey,
                    shiftKey: me.shiftKey,
                    altKey: me.altKey,
                    metaKey: me.metaKey
                });
            }
            // event pop from bottom to top
            return parentLoop(widget, function (w) {
                return w.event(fevent);
            });
        };
        Dispatcher.prototype.cursorWidget = function () {
            return this._cursorWidget;
        };
        Dispatcher.prototype.start = function () {
            var _this = this;
            // register dom event
            var domEvents = Dispatcher.mouseEvents.concat(Dispatcher.dragEvents);
            domEvents.forEach(function (e) { return document.addEventListener(e, _this._processDomEvent); });
            Dispatcher.canvasEvents.forEach(function (e) { return _this._faster.canvas().element().addEventListener(e, _this._processDomEvent); });
            // register touch event
            if (this._hammer !== null) {
                this._hammer.on(Dispatcher.hammerEvents, function (e) { return _this.dispath(e); });
                this._faster.canvas().element().addEventListener('touchmove', this._preventTouchMoveEvent);
            }
        };
        Dispatcher.prototype.stop = function () {
            var _this = this;
            var domEvents = Dispatcher.mouseEvents.concat(Dispatcher.dragEvents);
            domEvents.forEach(function (e) { return document.removeEventListener(e, _this._processDomEvent); });
            Dispatcher.canvasEvents.forEach(function (e) { return _this._faster.canvas().element().removeEventListener(e, _this._processDomEvent); });
            if (this._hammer !== null) {
                this._hammer.off(Dispatcher.hammerEvents);
                this._faster.canvas().element().removeEventListener('touchmove', this._preventTouchMoveEvent);
            }
        };
        Dispatcher.prototype.destroy = function () {
            FCanvasPool.backCanvas(this._dragCanvas);
        };
        Dispatcher.prototype._convertHammerEvent = function (he) {
            var _this = this;
            // todo: should we not listen dom event, all use harmmer event?
            // but how can we support drag & drop in computer, harmmerjs not support native drag & drop event
            if (he.pointerType === 'mouse')
                return null;
            var e = null;
            var center = new FPoint(he.center.x, he.center.y);
            center = this._faster.domPoint2Faster(center);
            var captureWidget = this._captureWidget();
            if (he.pointers.length <= 1) {
                var creatPanEvent = function (type) {
                    var w = captureWidget || _this._faster.findWidget(center, type);
                    if (w == null)
                        return null;
                    return new FPanEvent(type, w, center, he.deltaTime, he.deltaX, he.deltaY);
                };
                var createSingleTounch = function (type) {
                    var w = captureWidget || _this._faster.findWidget(center, type);
                    if (w == null)
                        return null;
                    return new FPressEvent(type, w, center, he.deltaTime);
                };
                var createSwipeEvent = function (type) {
                    var w = captureWidget || _this._faster.findWidget(center, type);
                    if (w == null)
                        return e;
                    var dir;
                    if (he.direction & Hammer.DIRECTION_LEFT)
                        dir = exports.FDirection.Left;
                    else if (he.direction & Hammer.DIRECTION_RIGHT)
                        dir = exports.FDirection.Right;
                    else if (he.direction & Hammer.DIRECTION_UP)
                        dir = exports.FDirection.Up;
                    else
                        dir = exports.FDirection.Down;
                    return new FSwipeEvent(type, w, center, he.deltaTime, he.velocityX, he.velocityY, he.velocity, dir);
                };
                switch (he.type) {
                    case 'panstart':
                        e = creatPanEvent(exports.FEventType.PanStart);
                        break;
                    case 'panmove':
                        e = creatPanEvent(exports.FEventType.PanMove);
                        break;
                    case 'panend':
                        e = creatPanEvent(exports.FEventType.PanEnd);
                        break;
                    case 'pancancel':
                        e = creatPanEvent(exports.FEventType.PanCancel);
                        break;
                    case 'press':
                        e = createSingleTounch(exports.FEventType.Press);
                        break;
                    case 'tap':
                        e = createSingleTounch(exports.FEventType.Tap);
                        break;
                    case 'pressup':
                        e = createSingleTounch(exports.FEventType.PressUp);
                        break;
                    case 'swipe':
                        e = createSwipeEvent(exports.FEventType.Swipe);
                        break;
                    default: break;
                }
            }
            else {
                var pointers_1 = he.pointers.map(function (pt) {
                    return _this._faster.domPoint2Faster(new FPoint(pt.clientX, pt.clientY));
                });
                var createRotateEvent = function (type) {
                    var w = captureWidget || _this._faster.findWidgetByMultiPoint(pointers_1, type);
                    if (w == null)
                        return null;
                    return new FRotateEvent(type, w, center, he.deltaTime, pointers_1, he.rotation);
                };
                var createPinchEvent = function (type) {
                    var w = captureWidget || _this._faster.findWidgetByMultiPoint(pointers_1, type);
                    if (w == null)
                        return null;
                    return new FPincEvent(type, w, center, he.deltaTime, pointers_1, he.scale);
                };
                switch (he.type) {
                    case 'rotatestart':
                        e = createRotateEvent(exports.FEventType.RotateStart);
                        break;
                    case 'rotatemove':
                        e = createRotateEvent(exports.FEventType.RotateMove);
                        break;
                    case 'rotateend':
                        e = createRotateEvent(exports.FEventType.RotateEnd);
                        break;
                    case 'rotatecancel':
                        e = createRotateEvent(exports.FEventType.RotateCancel);
                        break;
                    case 'pinchstart':
                        e = createPinchEvent(exports.FEventType.PinchStart);
                        break;
                    case 'pinchmove':
                        e = createPinchEvent(exports.FEventType.PinchMove);
                        break;
                    case 'pinchend':
                        e = createPinchEvent(exports.FEventType.PinchEnd);
                        break;
                    case 'pinchcancel':
                        e = createPinchEvent(exports.FEventType.PinchCancel);
                        break;
                    default: break;
                }
            }
            return e;
        };
        Dispatcher.prototype._convertMouseEvent = function (event) {
            var _this = this;
            var globalPt = new FPoint(event.clientX, event.clientY);
            globalPt = this._faster.domPoint2Faster(globalPt);
            var e = null;
            var findWidget = function (type) {
                var w = _this._captureWidget() || _this._faster.findWidget(globalPt, type);
                return w;
            };
            var newMouseEvent = function (type) {
                var w = findWidget(type);
                if (w == null)
                    return null;
                return new FMouseEvent(type, w, globalPt.x, globalPt.y, event.buttons, event.ctrlKey, event.shiftKey, event.altKey, event.metaKey);
            };
            var createSyntheticClick = function () {
                var downW = _this._captureWidget();
                if (!downW) {
                    _this._syntheticClick = null;
                    return;
                }
                var upW = _this._faster.findWidget(globalPt, exports.FEventType.MouseUp);
                if (!upW) {
                    _this._syntheticClick = null;
                    return;
                }
                var cp = _this.lowestCommonAncestor(downW, upW);
                _this._syntheticClick = new FMouseEvent(exports.FEventType.Click, cp, globalPt.x, globalPt.y, event.buttons, event.ctrlKey, event.shiftKey, event.altKey, event.metaKey);
            };
            switch (event.type) {
                case 'mousedown':
                    e = newMouseEvent(exports.FEventType.MouseDown);
                    break;
                case 'mouseup':
                    e = newMouseEvent(exports.FEventType.MouseUp);
                    createSyntheticClick();
                    break;
                case 'mousemove':
                    e = newMouseEvent(exports.FEventType.MouseMove);
                    break;
                case 'click':
                    if (this._syntheticClick !== null) {
                        e = this._syntheticClick;
                    }
                    else {
                        e = newMouseEvent(exports.FEventType.Click);
                    }
                    break;
                case 'dblclick':
                    e = newMouseEvent(exports.FEventType.Dblclick);
                    break;
                case 'wheel':
                    var _a = event, deltaX = _a.deltaX, deltaY = _a.deltaY;
                    var w = findWidget(exports.FEventType.MouseWheel);
                    e = w && new FWheelEvent(deltaX, deltaY, w, globalPt.x, globalPt.y, event.buttons, event.ctrlKey, event.shiftKey, event.altKey, event.metaKey);
                    break;
                case 'contextmenu':
                    e = newMouseEvent(exports.FEventType.ContextMenu);
                    break;
            }
            return e;
        };
        Dispatcher.prototype._convertDragEvent = function (event) {
            var _this = this;
            var w = null;
            var e = null;
            var newDragEvent = function (type, needCapture) {
                var globalPt = new FPoint(event.clientX, event.clientY);
                globalPt = _this._faster.domPoint2Faster(globalPt);
                var capture = _this._captureWidget();
                var anchor = _this._faster.findWidget(globalPt, type);
                w = needCapture ? _this.dragTarget(capture || anchor) : _this.dropTarget(anchor);
                if (w == null)
                    return null;
                var de = event;
                return new FDragEvent(type, w, globalPt.x, globalPt.y, de.buttons, de.ctrlKey, de.shiftKey, de.altKey, de.metaKey, de.dataTransfer, _this._dragCanvas);
            };
            switch (event.type) {
                case 'dragstart':
                    e = newDragEvent(exports.FEventType.DragStart, true);
                    if (e instanceof FDragEvent) {
                        e.dataTransfer.setData(WIDGET_UID, e.target.UID.toString());
                    }
                    break;
                case 'drag':
                    e = newDragEvent(exports.FEventType.Drag, true);
                    break;
                case 'dragend':
                    e = newDragEvent(exports.FEventType.DragEnd, true);
                    break;
                case 'dragenter':
                case 'dragover':
                    e = newDragEvent(exports.FEventType.DragOver, false);
                    break;
                case 'drop':
                    e = newDragEvent(exports.FEventType.Drop, false);
                    break;
                case 'dragleave':
                    var _a = event, buttons = _a.buttons, ctrlKey = _a.ctrlKey, shiftKey = _a.shiftKey, altKey = _a.altKey, metaKey = _a.metaKey;
                    this._enterLeaveDispatch(false, null, { globalX: 0, globalY: 0, buttons: buttons, ctrlKey: ctrlKey, shiftKey: shiftKey, altKey: altKey, metaKey: metaKey });
                    break;
                default:
                    break;
            }
            return e;
        };
        Dispatcher.prototype._clearDragImage = function () {
            var ctx = this._dragCanvas.ctx();
            ctx.clearRect(new FRect(0, 0, this._dragCanvas.width(), this._dragCanvas.height()));
        };
        /**
         *
         *  if true represent dispatch mouse enter / leave,
         *  otherwise drag event enter / leave should be fire
         * 如果传入null，从cursorWidget到faster之间所有节点发送leave事件。
         * 如果是widget，查找与cursorWidget的共同祖先，ancestor。
         * cursorWidget与ancestor路径上的节点发送leave事件。
         * widget与ancestor路径上的节点发送enter事件。
         * leave事件从上到下，enter事件自底向上。
         * @param mouseType
         * @param w
         * @param e
         */
        Dispatcher.prototype._enterLeaveDispatch = function (mouseType, w, e) {
            var _this = this;
            if (w === this._cursorWidget)
                return;
            var leaveStack = [];
            var nearest = null;
            parentLoop(this._cursorWidget, function (cur) {
                if (w !== null && cur.ancestorOf(w)) {
                    nearest = cur;
                    return true;
                }
                else {
                    leaveStack.push(cur);
                    return false;
                }
            });
            var enterStack = [];
            parentLoop(w, function (cur) {
                if (cur !== nearest) {
                    enterStack.unshift(cur);
                    return false;
                }
                else {
                    return true;
                }
            });
            this._cursorWidget = w;
            leaveStack.forEach(function (w) {
                if (!_this._isDestroied(w)) {
                    var type = mouseType ? exports.FEventType.MouseLeave : exports.FEventType.DragLeave;
                    var leaveEvent = new FLeaveEvent(type, w, e.globalX, e.globalY, e.buttons, e.ctrlKey, e.shiftKey, e.altKey, e.metaKey);
                    ListenersControl.sendEvent(w, leaveEvent);
                }
            });
            enterStack.forEach(function (w) {
                var type = mouseType ? exports.FEventType.MouseEnter : exports.FEventType.DragEnter;
                var enterEvent = new FEnterEvent(type, w, e.globalX, e.globalY, e.buttons, e.ctrlKey, e.shiftKey, e.altKey, e.metaKey);
                ListenersControl.sendEvent(w, enterEvent);
            });
        };
        Dispatcher.prototype.dragTarget = function (w) {
            var target = null;
            parentLoop(w, function (p) {
                var draggable = p.draggable;
                if (draggable)
                    target = p;
                return draggable;
            });
            return target;
        };
        Dispatcher.prototype.dropTarget = function (w) {
            var target = null;
            parentLoop(w, function (p) {
                var droppable = p.droppable;
                if (droppable)
                    target = p;
                return droppable;
            });
            return target;
        };
        Dispatcher.prototype._isDestroied = function (w) {
            return w.parent() == null && !(w instanceof Faster);
        };
        Dispatcher.prototype._captureWidget = function () {
            if (this._userCaptrue !== null) {
                if (!this._isDestroied(this._userCaptrue))
                    return this._userCaptrue;
                else
                    this._userCaptrue = null;
            }
            if (this._autoCaptrue !== null) {
                if (!this._isDestroied(this._autoCaptrue))
                    return this._autoCaptrue;
                else
                    this._autoCaptrue = null;
            }
            return null;
        };
        Dispatcher.dragEvents = ['dragstart', 'drag', 'drop', 'dragover', 'dragend', 'dragenter', 'dragleave'];
        Dispatcher.mouseEvents = [
            'mousedown', 'mousemove', 'mouseup', 'click', 'dblclick',
            'wheel', 'contextmenu',
        ];
        Dispatcher.canvasEvents = [
            'mouseleave',
        ];
        Dispatcher.hammerEvents = 'tap panstart panmove panend pancancel press pressup swipe \
  pinchstart pinchmove pinchend pinchcancel \
  rotatestart rotatemove rotateend rotatecancel';
        return Dispatcher;
    }());

    var ListenersControl = /** @class */ (function () {
        function ListenersControl() {
        }
        ListenersControl.sendEvent = function (w, e, async) {
            if (async === void 0) { async = false; }
            if (async)
                ListenersControl.EventStatck.push({ w: w, e: e });
            else if (!Dispatcher.filterEvent(w, e))
                w.event(e);
        };
        ListenersControl.doTick = function () {
            if (ListenersControl.EventStatck.length > 0) {
                var asyncEvents = ListenersControl.EventStatck;
                asyncEvents.forEach(function (_a) {
                    var w = _a.w, e = _a.e;
                    if (!w.destroied && !Dispatcher.filterEvent(w, e))
                        w.event(e);
                });
                ListenersControl.EventStatck = [];
            }
        };
        ListenersControl.removeEventByWidget = function (w) {
            ListenersControl.EventStatck = ListenersControl.EventStatck.filter(function (ae) { return ae.w !== w; });
        };
        ListenersControl.EventStatck = [];
        return ListenersControl;
    }());

    var FDefaultConstructor = /** @class */ (function () {
        function FDefaultConstructor() {
        }
        FDefaultConstructor.prototype.constructWidget = function (node) {
            var w;
            if (node.type === exports.WidgetType.faster) {
                var canvas = document.createElement('canvas');
                w = new Faster(canvas);
            }
            else {
                w = new FWidget(null);
            }
            w.updateByCfg(node.cfg);
            return w;
        };
        return FDefaultConstructor;
    }());

    function enableDebugger() {
        document.addEventListener('keydown', function (e) {
            var keyD = 68;
            if (e.ctrlKey && e.altKey && e.metaKey && e.keyCode === keyD) {
                var cfg = __FASTER_META__.config;
                loadScript(cfg.devtoolsUrl);
            }
        });
    }
    function enableShadow(shadowRecorder) {
        document.addEventListener('keydown', function (e) {
            var keyL = 76;
            if (e.ctrlKey && e.altKey && e.metaKey && e.keyCode === keyL) {
                var cfg = __FASTER_META__.config;
                loadScript(cfg.recorderUrl, function () {
                    var Record = __FASTER_META__.shelter.Record;
                    // tslint:disable
                    new Record(shadowRecorder);
                });
            }
        });
    }

    exports.enableDebugger = enableDebugger;
    exports.enableShadow = enableShadow;
    exports.ListenersControl = ListenersControl;
    exports.Bind = Bind;
    exports.CustomEventStart = CustomEventStart;
    exports.FEvent = FEvent;
    exports.FUIEvent = FUIEvent;
    exports.FMouseEvent = FMouseEvent;
    exports.FWheelEvent = FWheelEvent;
    exports.FEnterEvent = FEnterEvent;
    exports.FLeaveEvent = FLeaveEvent;
    exports.FDragEvent = FDragEvent;
    exports.Dispatcher = Dispatcher;
    exports.FChangeEvent = FChangeEvent;
    exports.FSingleTouchEvent = FSingleTouchEvent;
    exports.FPressEvent = FPressEvent;
    exports.FTapEvent = FTapEvent;
    exports.FPanEvent = FPanEvent;
    exports.FSwipeEvent = FSwipeEvent;
    exports.FMultiTouchEvent = FMultiTouchEvent;
    exports.FPincEvent = FPincEvent;
    exports.FRotateEvent = FRotateEvent;
    exports.FTickEvent = FTickEvent;
    exports.FObj = FObj;
    exports.FPoint = FPoint;
    exports.FRect = FRect;
    exports.FSize = FSize;
    exports.dashLine = dashLine;
    exports.QuaterSplit = QuaterSplit;
    exports.FWidget = FWidget;
    exports.WIDGET_UID = WIDGET_UID;
    exports.BACKGROUND = BACKGROUND;
    exports.SHADOW_BLUR = SHADOW_BLUR;
    exports.SHADOW_COLOR = SHADOW_COLOR;
    exports.SHADOW_OFFSET_X = SHADOW_OFFSET_X;
    exports.SHADOW_OFFSET_Y = SHADOW_OFFSET_Y;
    exports.SCROLLBAR_COLOR = SCROLLBAR_COLOR;
    exports.SCROLLBAR_BACKGROUND = SCROLLBAR_BACKGROUND;
    exports.SCROLLBAR_THICK = SCROLLBAR_THICK;
    exports.FCanvasPool = FCanvasPool;
    exports.FCanvas = FCanvas;
    exports.FCanvasRenderingContext2D = FCanvasRenderingContext2D;
    exports.Faster = Faster;
    exports.parentLoop = parentLoop;
    exports.findInSorted = findInSorted;
    exports.equals = equals;
    exports.loadScript = loadScript;
    exports.SortedArray = SortedArray;
    exports.ArrIterator = ArrIterator;
    exports.FApp = FApp;
    exports.FDefaultConstructor = FDefaultConstructor;

    Object.defineProperty(exports, '__esModule', { value: true });


            __FASTER_META__.core = exports;

            __FASTER_META__.config = {"version":"0.4.20","devtoolsUrl":"https://faster.roading.org/devtools.0.4.20.js","recorderUrl":"https://faster.roading.org/shelter.0.4.20.js"};

})));
//# sourceMappingURL=core.umd.js.map

/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(84)))

/***/ }),

/***/ 1601:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(global) {


      if (typeof __FASTER_META__ === 'undefined') {
        var glb = typeof global !== 'undefined' ? global : typeof self !== 'undefined' ? self : typeof window !== 'undefined' ? window : {};
        glb.__FASTER_META__ = {};
      }
      

Object.defineProperty(exports, '__esModule', { value: true });

var core = __webpack_require__(1573);

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

var extendStatics = function(d, b) {
    extendStatics = Object.setPrototypeOf ||
        ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
        function (d, b) { for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p]; };
    return extendStatics(d, b);
};

function __extends(d, b) {
    extendStatics(d, b);
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
}

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

var DragStatus;
(function (DragStatus) {
    DragStatus[DragStatus["None"] = 0] = "None";
    DragStatus[DragStatus["Dragging"] = 1] = "Dragging";
})(DragStatus || (DragStatus = {}));
(function (ScrollSnapSide) {
    ScrollSnapSide[ScrollSnapSide["Inside"] = 0] = "Inside";
    ScrollSnapSide[ScrollSnapSide["OutSide"] = 1] = "OutSide";
})(exports.ScrollSnapSide || (exports.ScrollSnapSide = {}));
var HidenTime = 1000;
var SCROLLBAR_THICK = 8;
var SCROLLBAR_THIN = 4;
var SCROLLBAR_GAP = 2;
var FScrollbar = /** @class */ (function (_super) {
    __extends(FScrollbar, _super);
    function FScrollbar(p) {
        var _this = _super.call(this, p) || this;
        _this._status = DragStatus.None;
        _this._press = false;
        _this._scrollToPt = new core.FPoint(0, 0);
        _this.idleCbId = 0;
        _this.lastActiveTime = 0;
        _this.idleCheck = function () {
            var now = Date.now();
            if (now - _this.lastActiveTime > HidenTime && !_this.hovered) {
                _this._slider.updateByCfg({ hidden: true });
                core.FApp.removeIdleListener(_this.idleCbId);
                _this.idleCbId = 0;
            }
        };
        _this._slider = new core.FWidget(_this);
        core.Bind.propBind(_this._slider, 'background', _this, 'color');
        _this._slider.updateByCfg({ hidden: true });
        return _this;
    }
    Object.defineProperty(FScrollbar.prototype, "min", {
        get: function () {
            return this._cleanProp('min');
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FScrollbar.prototype, "max", {
        get: function () {
            return this._cleanProp('max');
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FScrollbar.prototype, "page", {
        get: function () {
            return this._cleanProp('page');
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FScrollbar.prototype, "value", {
        get: function () {
            return this._cleanProp('value');
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FScrollbar.prototype, "hovered", {
        get: function () {
            return this._cleanProp('hover');
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FScrollbar.prototype, "autoHide", {
        get: function () {
            return this._cleanProp('autoHide');
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FScrollbar.prototype, "snapSide", {
        get: function () {
            return this._cleanProp('snapSide');
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FScrollbar.prototype, "thick", {
        get: function () {
            return this._cleanProp('thick');
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FScrollbar.prototype, "thin", {
        get: function () {
            return this._cleanProp('thin');
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FScrollbar.prototype, "gap", {
        get: function () {
            return this._cleanProp('gap');
        },
        enumerable: true,
        configurable: true
    });
    FScrollbar.prototype.mouseDown = function (e) {
        var _this = this;
        if (e.target !== this)
            return false;
        if (e.buttons & core.FMouseButtons.MainButton) {
            this._press = true;
            this._scrollToPt = new core.FPoint(e.x, e.y);
            var value_1 = this._pt2Value(this._scrollToPt);
            var distance = value_1 - this.value;
            if (Math.abs(distance) > 10) {
                var step_1 = distance / 50;
                var step2Pt_1 = function () {
                    _this.updateByCfg({ value: _this.value + step_1 });
                    if (_this._press && Math.abs(_this.value - value_1) > 1) {
                        setTimeout(function () { return step2Pt_1(); }, 20);
                    }
                };
                step2Pt_1();
            }
            else {
                this.updateByCfg({ value: value_1 });
            }
        }
        return false;
    };
    FScrollbar.prototype.mouseMove = function (e) {
        if (e.target !== this)
            return false;
        if (e.buttons & core.FMouseButtons.MainButton) {
            this._scrollToPt = new core.FPoint(e.x, e.y);
        }
        return false;
    };
    FScrollbar.prototype.mouseUp = function (e) {
        if (e.target !== this)
            return false;
        this._press = false;
        return false;
    };
    FScrollbar.prototype.mouseEnter = function () {
        this.updateByCfg({ hover: true });
        return false;
    };
    FScrollbar.prototype.mouseLeave = function () {
        this.updateByCfg({ hover: false });
        return false;
    };
    FScrollbar.prototype.click = function () {
        return true;
    };
    FScrollbar.prototype.pos2View = function () {
        var scrollSize = this.scrollSize() - this.page;
        if (scrollSize === 0) {
            return 0;
        }
        return (this.value / scrollSize) * (this.barSize() - this.slideSize());
    };
    FScrollbar.prototype._pt2Value = function (pt) {
        var pos = this._pickPos(pt);
        var v = (pos / this.barSize()) * this.scrollSize() - this.page / 2;
        return this.validValue(v);
    };
    FScrollbar.prototype.slideSize = function () {
        var scrollSize = this.scrollSize();
        var MINI_SIZE = 20;
        if (scrollSize === 0) {
            return 0;
        }
        var ratio = this.page / scrollSize;
        var size = this.barSize() * ratio;
        if (size < MINI_SIZE) {
            size = MINI_SIZE;
        }
        return size;
    };
    FScrollbar.prototype.scrollSize = function () {
        return this.max - this.min;
    };
    FScrollbar.prototype.validValue = function (value) {
        var maxValue = this.max - this.page;
        if (maxValue <= 0) {
            return 0;
        }
        if (value > maxValue) {
            value = maxValue;
        }
        else if (value < this.min) {
            value = this.min;
        }
        return value;
    };
    FScrollbar.prototype.barSize = function () {
        console.error('implment this in derive class');
        return 0;
    };
    FScrollbar.prototype._pickPos = function (pt) {
        console.error('implment this in derive class');
        return 0;
    };
    FScrollbar.prototype._defalutCfg = function () {
        var cfg = _super.prototype._defalutCfg.call(this);
        cfg.min = 0;
        cfg.max = 0;
        cfg.page = 0;
        cfg.value = 0;
        cfg.color = core.SCROLLBAR_COLOR;
        cfg.hover = false;
        cfg.snapSide = exports.ScrollSnapSide.Inside;
        cfg.autoHide = true;
        cfg.onlyNecessary = false;
        cfg.thick = SCROLLBAR_THICK;
        cfg.thin = SCROLLBAR_THIN;
        cfg.gap = SCROLLBAR_GAP;
        return cfg;
    };
    FScrollbar.prototype.beforeChange = function (e) {
        var chgs = e.changes;
        if (chgs.value !== undefined && Object.keys(chgs).length === 1) {
            chgs.value.current = this.validValue(chgs.value.current);
        }
    };
    FScrollbar.prototype.afterChange = function (e) {
        _super.prototype.afterChange.call(this, e);
        var cfg = this._sliderCfg();
        this._slider.updateByCfg(cfg);
        var chgs = e.changes;
        // valid value again
        if (chgs.value === undefined || Object.keys(chgs).length > 1) {
            var value = this.validValue(this.value);
            if (this.value !== value) {
                this.updateByCfg({ value: value });
            }
        }
    };
    FScrollbar.prototype.beforeFlush = function (e) {
        var changes = e.changes;
        if (this._cleanProp('onlyNecessary')) {
            if (changes['max'] !== undefined || changes['page'] !== undefined) {
                var show = this.max > this.page;
                this.updateByCfg({ hidden: !show });
            }
        }
        if (!this.autoHide) {
            if (this._slider.hidden) {
                this._slider.updateByCfg({ hidden: false });
            }
            return false;
        }
        var active = e.changes['value'] !== undefined || e.changes['hover'] !== undefined;
        if (active) {
            this.lastActiveTime = Date.now();
            if (this.idleCbId === 0) {
                this.idleCbId = core.FApp.addIdleListener(this.idleCheck);
            }
            if (this._slider.hidden) {
                this._slider.updateByCfg({ hidden: false });
            }
        }
        return false;
    };
    FScrollbar.prototype._sliderCfg = function () {
        console.error('implement this in derive class');
        return {};
    };
    return FScrollbar;
}(core.FWidget));

var FVScrollbar = /** @class */ (function (_super) {
    __extends(FVScrollbar, _super);
    function FVScrollbar(p) {
        var _this = _super.call(this, p) || this;
        _this._mouseY = 0;
        _this._slider.addListener(core.FEventType.MouseDown, function (e) {
            var me = e;
            _this._mouseY = me.y + me.target.y;
            _this._status = DragStatus.Dragging;
            return false;
        });
        _this._slider.addListener(core.FEventType.MouseMove, function (e) {
            if (_this._status === DragStatus.Dragging && _this.height > 0) {
                var me = e;
                var y = me.y + me.target.y;
                var diff = y - _this._mouseY;
                _this._mouseY = y;
                diff = (diff / _this.height) * _this.scrollSize();
                _this.updateByCfg({ value: diff + _this.value });
            }
            return false;
        });
        _this._slider.addListener(core.FEventType.MouseUp, function (e) {
            _this._status = DragStatus.None;
            return false;
        });
        return _this;
    }
    FVScrollbar.prototype.mouseWheel = function (e) {
        this.updateByCfg({ value: e.deltaY + this.value });
        return false;
    };
    FVScrollbar.prototype._defalutCfg = function () {
        var cfg = _super.prototype._defalutCfg.call(this);
        cfg.width = cfg.thick + cfg.gap * 2;
        return cfg;
    };
    FVScrollbar.prototype._pickPos = function (pt) {
        return pt.y;
    };
    FVScrollbar.prototype.barSize = function () {
        return this.height;
    };
    FVScrollbar.prototype._sliderCfg = function () {
        var width = 0;
        var x = 0;
        if (this.autoHide) {
            width = this.hovered ? this.thick : this.thin;
        }
        else {
            width = this.thick;
        }
        if (this.snapSide === exports.ScrollSnapSide.Inside) {
            x = this.width - width - this.gap;
        }
        else {
            x = this.gap;
        }
        return {
            width: width,
            height: this.slideSize(),
            x: x,
            y: this.pos2View(),
            radius: width / 2,
        };
    };
    return FVScrollbar;
}(FScrollbar));

var FHScrollbar = /** @class */ (function (_super) {
    __extends(FHScrollbar, _super);
    function FHScrollbar(p) {
        var _this = _super.call(this, p) || this;
        _this._mouseX = 0;
        _this._slider.addListener(core.FEventType.MouseDown, function (e) {
            var me = e;
            _this._mouseX = me.x + me.target.x;
            _this._status = DragStatus.Dragging;
            return true;
        });
        _this._slider.addListener(core.FEventType.MouseMove, function (e) {
            if (_this._status === DragStatus.Dragging && _this.width > 0) {
                var me = e;
                var x = me.x + me.target.x;
                var diff = x - _this._mouseX;
                _this._mouseX = x;
                diff = (diff / _this.width) * _this.scrollSize();
                _this.updateByCfg({ value: _this.value + diff });
            }
            return false;
        });
        _this._slider.addListener(core.FEventType.MouseUp, function (e) {
            _this._status = DragStatus.None;
            return true;
        });
        return _this;
    }
    FHScrollbar.prototype._defalutCfg = function () {
        var cfg = _super.prototype._defalutCfg.call(this);
        cfg.height = cfg.thick + cfg.gap * 2;
        return cfg;
    };
    FHScrollbar.prototype.mouseWheel = function (e) {
        this.updateByCfg({ value: this.value + e.deltaX });
        return false;
    };
    FHScrollbar.prototype._pickPos = function (pt) {
        return pt.x;
    };
    FHScrollbar.prototype.barSize = function () {
        return this.width;
    };
    FHScrollbar.prototype._sliderCfg = function () {
        var y = 0;
        var height = 0;
        if (this.autoHide) {
            height = this.hovered ? this.thick : this.thin;
        }
        else {
            height = this.thick;
        }
        if (this.snapSide === exports.ScrollSnapSide.Inside) {
            y = this.height - height - this.gap;
        }
        else {
            y = this.gap;
        }
        return {
            width: this.slideSize(),
            height: height,
            x: this.pos2View(),
            y: y,
            radius: height / 2,
        };
    };
    return FHScrollbar;
}(FScrollbar));

(function (FAutoScrollType) {
    FAutoScrollType[FAutoScrollType["HScroll"] = 1] = "HScroll";
    FAutoScrollType[FAutoScrollType["VScroll"] = 2] = "VScroll";
})(exports.FAutoScrollType || (exports.FAutoScrollType = {}));
function CalcAutoSize(w) {
    var maxWidth = 0;
    var maxHeight = 0;
    w.children().each(function (child) {
        if (child.hidden)
            return;
        maxHeight = Math.max(maxHeight, child.rect.y + child.rect.height);
        maxWidth = Math.max(maxWidth, child.rect.x + child.rect.width);
    });
    return { width: maxWidth, height: maxHeight };
}
var AutoSizeWidget = /** @class */ (function (_super) {
    __extends(AutoSizeWidget, _super);
    function AutoSizeWidget(p) {
        return _super.call(this, p) || this;
    }
    Object.defineProperty(AutoSizeWidget.prototype, "minHeight", {
        get: function () {
            return this._cleanProp('minHeight') || 0;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(AutoSizeWidget.prototype, "maxHeight", {
        get: function () {
            return this._cleanProp('maxHeight') || Infinity;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(AutoSizeWidget.prototype, "minWidth", {
        get: function () {
            return this._cleanProp('minWidth') || 0;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(AutoSizeWidget.prototype, "maxWidth", {
        get: function () {
            return this._cleanProp('maxWidth') || Infinity;
        },
        enumerable: true,
        configurable: true
    });
    // todo: refactor -> should this really do beforechange?
    AutoSizeWidget.prototype.beforeChange = function (e) {
        var chgs = e.changes;
        var rect = this.rect;
        var minHeightChg = chgs.minHeight;
        var maxHeightChg = chgs.maxHeight;
        var isSet = function (c) { return c && c.current !== undefined; };
        if (minHeightChg !== undefined || maxHeightChg !== undefined) {
            var minHeight = isSet(minHeightChg) ? minHeightChg.current : this.minHeight;
            var maxHeight = isSet(maxHeightChg) ? maxHeightChg.current : this.maxHeight;
            this.updateByCfg({ height: Math.min(Math.max(rect.height, minHeight), maxHeight) });
        }
        var minWidthChg = chgs.minWidth;
        var maxWidthChg = chgs.maxWidth;
        if (minWidthChg !== undefined || maxWidthChg !== undefined) {
            var minWidth = isSet(minWidthChg) ? minWidthChg.current : this.minWidth;
            var maxWidth = isSet(maxWidthChg) ? maxWidthChg.current : this.maxWidth;
            this.updateByCfg({ width: Math.min(Math.max(rect.height, minWidth), maxWidth) });
        }
    };
    AutoSizeWidget.prototype.onChildChange = function (w, changes) {
        var size = CalcAutoSize(this);
        size.height = Math.min(Math.max(size.height, this.minHeight), this.maxHeight);
        size.width = Math.min(Math.max(size.width, this.minWidth), this.maxWidth);
        this.updateByCfg({
            width: size.width,
            height: size.height
        });
    };
    AutoSizeWidget.prototype._defalutCfg = function () {
        var cfg = _super.prototype._defalutCfg.call(this);
        cfg.minHeight = 0;
        cfg.maxHeight = Infinity;
        cfg.minWidth = 0;
        cfg.maxWidth = Infinity;
        return cfg;
    };
    return AutoSizeWidget;
}(core.FWidget));
var FContainerWidget = /** @class */ (function (_super) {
    __extends(FContainerWidget, _super);
    function FContainerWidget(p, _scrolltype) {
        var _this = _super.call(this, p) || this;
        _this.hscroll = null;
        _this.vscroll = null;
        _this.container = new AutoSizeWidget(_this);
        _super.prototype.addChild.call(_this, _this.container);
        if (_scrolltype & exports.FAutoScrollType.HScroll) {
            _this.initHscroll();
        }
        if (_scrolltype & exports.FAutoScrollType.VScroll) {
            _this.initVscroll();
        }
        _this.addChild = _this._addChild;
        _this.removeChild = _this._removeChild;
        return _this;
    }
    Object.defineProperty(FContainerWidget.prototype, "scrollTop", {
        get: function () {
            if (!this.vscroll)
                return 0;
            return this.vscroll.value;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FContainerWidget.prototype, "scrollLeft", {
        get: function () {
            if (!this.hscroll)
                return 0;
            return this.hscroll.value;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FContainerWidget.prototype, "scrollHeight", {
        get: function () {
            return this.container.height;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FContainerWidget.prototype, "scrollWidth", {
        get: function () {
            return this.container.width;
        },
        enumerable: true,
        configurable: true
    });
    FContainerWidget.prototype.scrollTo = function (x, y) {
        if (this.vscroll) {
            this.vscroll.updateByCfg({ value: y });
        }
        if (this.hscroll) {
            this.hscroll.updateByCfg({ value: x });
        }
    };
    FContainerWidget.prototype.mouseWheel = function (e) {
        if (this.vscroll) {
            this.vscroll.mouseWheel(e);
        }
        if (this.hscroll) {
            this.hscroll.mouseWheel(e);
        }
        return false;
    };
    FContainerWidget.prototype.afterChange = function (e) {
        var chgs = e.changes;
        var sizeCfg = {};
        if (chgs.height !== undefined) {
            sizeCfg.minHeight = chgs.height.current;
        }
        if (chgs.width !== undefined) {
            sizeCfg.minWidth = chgs.width.current;
        }
        this.container.updateByCfg(sizeCfg);
        if (this.vscroll) {
            this.vscroll.updateByCfg({ hidden: this.container.rect.height <= this.rect.height });
        }
        if (this.hscroll) {
            this.hscroll.updateByCfg({ hidden: this.container.rect.width <= this.rect.width });
        }
    };
    FContainerWidget.prototype._addChild = function (w) {
        this.container.addChild(w);
    };
    FContainerWidget.prototype._removeChild = function (w) {
        this.container.removeChild(w);
    };
    FContainerWidget.prototype.initVscroll = function () {
        var _this = this;
        this.vscroll = new FVScrollbar(this);
        _super.prototype.addChild.call(this, this.vscroll);
        this.vscroll.updateByCfg({ x: 0, y: 0, height: 0, hidden: true, zindex: 1 });
        core.Bind.propBind(this.vscroll, 'max', this.container, 'height');
        core.Bind.propBind(this.vscroll, 'x', this, 'width', function (v) { return v - _this.vscroll.width; });
        core.Bind.propBind(this.vscroll, 'height', this, 'height');
        core.Bind.propBind(this.vscroll, 'page', this, 'height');
        core.Bind.propBind(this.container, 'y', this.vscroll, 'value', function (v) { return -v; });
        core.Bind.propBind(this.vscroll, 'hidden', this.container, 'height', function () { return _this.container.height <= _this.height; });
    };
    FContainerWidget.prototype.initHscroll = function () {
        var _this = this;
        this.hscroll = new FHScrollbar(this);
        _super.prototype.addChild.call(this, this.hscroll);
        this.hscroll.updateByCfg({ x: 0, y: 0, width: 0, hidden: true, });
        core.Bind.propBind(this.hscroll, 'max', this.container, 'width');
        core.Bind.propBind(this.hscroll, 'y', this, 'height', function (v) { return v - _this.hscroll.height; });
        core.Bind.propBind(this.hscroll, 'width', this, 'width');
        core.Bind.propBind(this.hscroll, 'page', this, 'width');
        core.Bind.propBind(this.container, 'x', this.hscroll, 'value', function (v) { return -v; });
        core.Bind.propBind(this.hscroll, 'hidden', this.container, 'width', function () { return _this.container.width <= _this.width; });
    };
    return FContainerWidget;
}(core.FWidget));

var DomImagePool = /** @class */ (function () {
    function DomImagePool() {
    }
    DomImagePool._images = new Map();
    DomImagePool.released = [];
    return DomImagePool;
}());
core.FApp.addIdleListener(function () {
    if (DomImagePool.released.length > 0) {
        DomImagePool.released.forEach(function (ref) {
            if (ref.refCount() === 0) {
                DomImagePool._images.delete(ref.element().src);
            }
        });
        DomImagePool.released.length = 0;
    }
});
var ImageRef = /** @class */ (function () {
    /**
     * use static funtion newImage to create a imageRef instance.
     */
    function ImageRef(src) {
        this._ref = 0;
        this._img = new Image();
        this._img.src = src;
        DomImagePool._images.set(src, this);
        return this;
    }
    ImageRef.newImage = function (src) {
        if (!DomImagePool._images.has(src)) {
            var ref = new ImageRef(src);
            DomImagePool._images.set(src, ref);
        }
        return DomImagePool._images.get(src).addRef();
    };
    ImageRef.prototype.addRef = function () {
        this._ref++;
        return this;
    };
    ImageRef.prototype.relase = function () {
        if (--this._ref === 0) {
            DomImagePool.released.push(this);
        }
    };
    ImageRef.prototype.refCount = function () {
        return this._ref;
    };
    ImageRef.prototype.element = function () {
        return this._img;
    };
    return ImageRef;
}());
var FDomImage = /** @class */ (function () {
    function FDomImage(url) {
        var _this = this;
        this._errorHandlers = [];
        this._loadedHandlers = [];
        this._onloaded = function () {
            _this._loadedHandlers.forEach(function (handler) { return handler(); });
        };
        this._onerror = function () {
            _this._errorHandlers.forEach(function (handler) { return handler(); });
        };
        this._ref = ImageRef.newImage(url);
        var elem = this._ref.element();
        elem.addEventListener('load', this._onloaded);
        elem.addEventListener('error', this._onerror);
    }
    FDomImage.prototype.onLoaded = function (hanlder) {
        this._loadedHandlers.push(hanlder);
    };
    FDomImage.prototype.onError = function (handler) {
        this._errorHandlers.push(handler);
    };
    FDomImage.prototype.width = function () {
        return this._ref.element().width;
    };
    FDomImage.prototype.height = function () {
        return this._ref.element().height;
    };
    FDomImage.prototype.release = function () {
        this._ref.relase();
        this._errorHandlers.length = 0;
        this._loadedHandlers.length = 0;
        var elem = this._ref.element();
        elem.removeEventListener('load', this._onloaded);
        elem.removeEventListener('error', this._onerror);
    };
    FDomImage.prototype.element = function () {
        return this._ref.element();
    };
    return FDomImage;
}());

var FImage = /** @class */ (function (_super) {
    __extends(FImage, _super);
    function FImage(p) {
        var _this = _super.call(this, p) || this;
        if (_this.imgUrl)
            _this._newDomImage(_this.imgUrl);
        return _this;
    }
    Object.defineProperty(FImage.prototype, "imgUrl", {
        get: function () {
            return this._cleanProp('imgUrl');
        },
        enumerable: true,
        configurable: true
    });
    FImage.prototype.fvgNode = function () {
        var node = _super.prototype.fvgNode.call(this);
        node.type = exports.WdkFvgType.image;
        node.cfg.imgUrl = this._cfg.imgUrl;
        return node;
    };
    FImage.prototype.beforeFlush = function (e) {
        var chgs = e.changes;
        var imgUrlChange = chgs['imgUrl'];
        if (imgUrlChange) {
            var imgUrl = imgUrlChange.current;
            this._newDomImage(imgUrl);
            if (this._img.width() === 0 && this._img.height() === 0) {
                // update img url siliently
                // since img.onload will trigger repaint
                delete chgs['imgUrl'];
                this._cfg['imgUrl'] = imgUrl;
            }
        }
    };
    FImage.prototype.destroy = function () {
        _super.prototype.destroy.call(this);
        if (this._img)
            this._img.release();
    };
    FImage.prototype.renderWidget = function (ctx, renderRect) {
        _super.prototype.renderWidget.call(this, ctx, renderRect);
        if (!this._img)
            return;
        // todo: only draw rende rect.
        var x = this._cfg.x;
        var y = this._cfg.y;
        var width = this._cfg.width;
        var height = this._cfg.height;
        var scale = this._img.width() / this._img.height();
        if (width && !height) {
            height = width / scale;
        }
        else if (!width && height) {
            width = height * scale;
        }
        else if (!width && !height) {
            width = this._img.width();
            height = this._img.height();
        }
        // fix IE draw svg image crash
        try {
            ctx.drawImage(this._img.element(), new core.FRect(x, y, width, height));
        }
        catch (e) { /* don't do nothing */ }
    };
    FImage.prototype._defalutCfg = function () {
        var cfg = _super.prototype._defalutCfg.call(this);
        cfg.imgUrl = '';
        return cfg;
    };
    FImage.prototype._newDomImage = function (url) {
        var _this = this;
        this._img = new FDomImage(url);
        this._img.onLoaded(function () {
            var rect = new core.FRect(0, 0, _this._cfg.width, _this._cfg.height);
            _this.markDirtyRect(rect);
            _this._dirtyList(core.WidgetProps.ChildDirty);
        });
    };
    return FImage;
}(core.FWidget));

(function (HorizontalAlign) {
    HorizontalAlign[HorizontalAlign["Left"] = 0] = "Left";
    HorizontalAlign[HorizontalAlign["Center"] = 1] = "Center";
    HorizontalAlign[HorizontalAlign["Right"] = 2] = "Right";
})(exports.HorizontalAlign || (exports.HorizontalAlign = {}));
(function (VerticalAlign) {
    VerticalAlign[VerticalAlign["Top"] = 0] = "Top";
    VerticalAlign[VerticalAlign["Center"] = 1] = "Center";
    VerticalAlign[VerticalAlign["Bottom"] = 2] = "Bottom";
})(exports.VerticalAlign || (exports.VerticalAlign = {}));
(function (TextDecoration) {
    TextDecoration[TextDecoration["None"] = 0] = "None";
    TextDecoration[TextDecoration["Bottom"] = 1] = "Bottom";
    TextDecoration[TextDecoration["Mid"] = 2] = "Mid";
    TextDecoration[TextDecoration["Top"] = 4] = "Top";
})(exports.TextDecoration || (exports.TextDecoration = {}));

function charType(codePoint) {
    /* unicode range subsetting
    Latin glyphs: U+000-5FF;
    CJK: [U+2E80+9FFF,  U+20000–U+2EBEF]
    */
    if (codePoint < 0x5FF)
        return 0 /* Latin */;
    else if (0x2E80 < codePoint && codePoint < 0x9FFF)
        return 1 /* CJK */;
    else if (0x20000 < codePoint && codePoint < 0x2EBEF)
        return 1 /* CJK */;
    else
        return 2 /* Other */;
}
var baseFontSize = 12;
/**
 * ALL the font info store in caches are measured by 10px size.
 */
var FontMeasurer = /** @class */ (function () {
    function FontMeasurer(_fontFamily, _fontWeigth, fontSize) {
        if (fontSize === void 0) { fontSize = 10; }
        this._fontFamily = _fontFamily;
        this._fontWeigth = _fontWeigth;
        this._measured = 0;
        this._latain = 0; // latin char avarage width
        this._cjk = 0; // Chinese character description languages char avarage width;
        this._other = 0; // other char avarage width
        this._factor = fontSize / baseFontSize;
        var key = _fontFamily + "_" + _fontWeigth;
        if (FontMeasurer[key] === undefined) {
            var ctx = this._ctx();
            this.setupStyle();
            FontMeasurer[key] = {
                latin: {
                    sum: ctx.measureText('AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz0123456789,;.?').width,
                    count: 66
                },
                cjk: {
                    sum: ctx.measureText('永字八法，。；').width,
                    count: 7
                },
                other: {
                    sum: ctx.measureText('😀😁😂').width,
                    count: 3
                },
                lineHeight: FontMeasurer.fontLineHeight(_fontFamily)
            };
        }
        this._fontInfo = FontMeasurer[key];
        this._updateGuesser();
    }
    FontMeasurer.fontLineHeight = function (fontFamily) {
        if (FontMeasurer.span === null) {
            var span = document.createElement('span');
            span.innerHTML = 'H';
            var style = span.style;
            style.visibility = 'hidden';
            style.top = '-100%';
            style.left = '-100%';
            style.position = 'absolute';
            style.fontSize = baseFontSize + 'px';
            document.body.insertBefore(span, null);
            FontMeasurer.span = span;
        }
        FontMeasurer.span.style.fontFamily = fontFamily;
        return FontMeasurer.span.offsetHeight || baseFontSize * 1.2;
    };
    FontMeasurer.prototype.setupStyle = function () {
        var ctx = FontMeasurer.canvas.ctx();
        ctx.fontFamily = this._fontFamily;
        ctx.fontWeight = this._fontWeigth;
        ctx.fontSize = baseFontSize;
    };
    FontMeasurer.prototype.measureText = function (str) {
        var ctx = this._ctx();
        this.setupStyle();
        return ctx.measureText(str).width * this._factor;
    };
    FontMeasurer.prototype.measureChar = function (codePoint, char) {
        var ctx = this._ctx();
        this.setupStyle();
        var width = ctx.measureText(char).width;
        var fInfo = this._fontInfo;
        var summary;
        var t = charType(codePoint);
        if (t === 0 /* Latin */)
            summary = fInfo.latin;
        else if (t === 1 /* CJK */)
            summary = fInfo.cjk;
        else
            summary = fInfo.other;
        summary.count += 1;
        summary.sum += width;
        this._measured += 1;
        if (this._measured > 256) {
            this._updateGuesser();
            this._measured = 0;
        }
        return width * this._factor;
    };
    FontMeasurer.prototype.guessCharWidth = function (codePoint) {
        var t = charType(codePoint);
        if (t === 0 /* Latin */)
            return this._latain * this._factor;
        if (t === 1 /* CJK */)
            return this._cjk * this._factor;
        else
            return this._other * this._factor;
    };
    FontMeasurer.prototype.lineHeight = function () {
        return this._fontInfo.lineHeight * this._factor;
    };
    FontMeasurer.prototype._ctx = function () {
        var ctx = FontMeasurer.canvas.ctx();
        return ctx;
    };
    FontMeasurer.prototype._updateGuesser = function () {
        var _a = this._fontInfo, latin = _a.latin, cjk = _a.cjk, other = _a.other;
        this._latain = latin.sum / latin.count;
        this._cjk = cjk.sum / cjk.count;
        this._other = other.sum / other.count;
    };
    FontMeasurer.canvas = core.FCanvasPool.borrowCanvas(null);
    FontMeasurer.span = null;
    return FontMeasurer;
}());
/**
 * Iterate whole char in string.
 *
 * References: [utf-16](https://en.wikipedia.org/wiki/UTF-16)
 */
var CharIter = /** @class */ (function () {
    function CharIter(_str) {
        this._str = _str;
        this._idx = Number.NEGATIVE_INFINITY;
        this._charInfo = {
            codePoint: 0,
            units: 0,
        };
    }
    CharIter.prototype.next = function () {
        if (this._idx === Number.NEGATIVE_INFINITY)
            this._idx = 0;
        var units = this._charInfo.units;
        if (this._idx >= this._str.length - units) {
            this._idx = Number.NEGATIVE_INFINITY;
            this._charInfo = { codePoint: 0, units: 0 };
            return null;
        }
        this._idx += units;
        this._getWholeChar();
        return this;
    };
    CharIter.prototype.prev = function () {
        if (this._idx === Number.NEGATIVE_INFINITY)
            this._idx = this._str.length;
        if (this._idx <= 0) {
            this._idx = Number.NEGATIVE_INFINITY;
            this._charInfo = { codePoint: 0, units: 0 };
            return null;
        }
        this._idx--;
        this._getWholeChar();
        return this;
    };
    CharIter.prototype.codePoint = function () {
        if (this._charInfo.units <= 0)
            return -1;
        else
            return this._charInfo.codePoint;
    };
    CharIter.prototype.char = function () {
        var cinfo = this._charInfo;
        var str = this._str;
        if (cinfo.units <= 0)
            return '';
        if (cinfo.units === 1)
            return str.charAt(this._idx);
        else
            return str.charAt(this._idx) + str.charAt(this._idx + 1);
    };
    CharIter.prototype.idx = function () {
        return this._idx;
    };
    CharIter.prototype.units = function () {
        return this._charInfo.units;
    };
    CharIter.prototype.seek = function (charpos) {
        this._charInfo.codePoint = 0;
        this._charInfo.units = 0;
        if (charpos < 0 || this._str.length <= charpos) {
            this._idx = Number.NEGATIVE_INFINITY;
        }
        else {
            this._idx = charpos;
            // beacuse the char info units is zero,
            // next method will not setp to next, just init char info.
            this.next();
        }
        return this;
    };
    CharIter.prototype.isValid = function () {
        return this._idx !== Number.NEGATIVE_INFINITY;
    };
    CharIter.prototype._getWholeChar = function () {
        var str = this._str;
        var idx = this._idx;
        var code = str.charCodeAt(idx);
        // char in basic multilingual plane
        if (code < 0xD800 || code > 0xDFFF) {
            this._charInfo.codePoint = str.codePointAt(idx);
            this._charInfo.units = 1;
        }
        else if (0xD800 <= code && code <= 0xDBFF) {
            // High surrogate (could change last hex to 0xDB7F to treat high private
            // surrogates as single characters)
            if (str.length <= (idx + 1)) {
                throw new Error('High surrogate without following low surrogate');
            }
            var next = str.charCodeAt(idx + 1);
            if (0xDC00 > next || next > 0xDFFF) {
                throw new Error('High surrogate without following low surrogate');
            }
            this._charInfo.codePoint = str.codePointAt(idx);
            this._charInfo.units = 2;
        }
        else {
            // Low surrogate byte
            if (idx <= 0) {
                throw new Error('Low surrogate without preceding high surrogate');
            }
            var prev = str.charCodeAt(idx - 1);
            if (prev < 0xD800 || 0xDBFF < prev) {
                throw new Error('Low surrogate without preceding high surrogate');
            }
            this._idx -= 1;
            this._charInfo.codePoint = str.codePointAt(idx - 1);
            this._charInfo.units = 2;
        }
    };
    return CharIter;
}());

var defaultFont = {
    fontSize: 12,
    fontFamily: 'Arial',
    fontStyle: 'normal',
    fontWeight: core.FontWeight.normal
};
var FTypographyStream = /** @class */ (function () {
    function FTypographyStream(_typher, _defalutStyle) {
        if (_defalutStyle === void 0) { _defalutStyle = {}; }
        this._typher = _typher;
        this._defalutStyle = _defalutStyle;
        this._str = '';
        function rgComp(v, curr) {
            if (v.rg.from > curr.rg.from)
                return 1;
            else if (v.rg.from < curr.rg.from)
                return -1;
            else
                return 0;
        }
        this._styles = new core.SortedArray(rgComp);
        this._aligns = new core.SortedArray(rgComp);
        this._insets = new core.SortedArray(function (v, curr) {
            if (v.pos > curr.pos)
                return 1;
            else if (v.pos < curr.pos)
                return -1;
            else
                return 0;
        });
        this._fillDefaultStyle();
    }
    FTypographyStream.prototype.updateDefaultStyle = function (dfstyle) {
        this._defalutStyle = dfstyle;
        this._fillDefaultStyle();
    };
    FTypographyStream.prototype.updateStr = function (str) {
        this._str = str;
        this._typher.reset();
    };
    FTypographyStream.prototype.addStyleAttr = function (attr) {
        // todo support intersect style, and merge intersect area.
        this._styles.insert(attr);
        this._typher.reset();
    };
    FTypographyStream.prototype.addInset = function (inset) {
        if (inset.wrapText !== false)
            inset.wrapText = true;
        this._insets.insert(inset);
        this._typher.reset();
    };
    FTypographyStream.prototype.addAlignAttr = function (attr) {
        this._aligns.insert(attr);
        this._typher.reset();
    };
    FTypographyStream.prototype.removeAlignAttr = function (from, to) {
        FTypographyStream._removeAttr(this._aligns, from, to);
        this._typher.reset();
    };
    FTypographyStream.prototype.removeStyleAttr = function (from, to) {
        FTypographyStream._removeAttr(this._styles, from, to);
        this._typher.reset();
    };
    FTypographyStream.prototype.removeInset = function (from, to) {
        var low = this._insets.lbound({ pos: from }, true);
        if (low === -1)
            return;
        var up = this._insets.ubound({ pos: to }, true);
        if (up === -1)
            return;
        if (this._insets.at(low).pos < from)
            ++low;
        if (this._insets.at(up).pos > to)
            --up;
        this._insets.remove(low, up - low + 1);
        this._typher.reset();
    };
    FTypographyStream.prototype.removeAllDecorator = function (from, to) {
        this.removeStyleAttr(from, to);
        this.removeInset(from, to);
        this.removeAlignAttr(from, to);
    };
    FTypographyStream.prototype.defaultStyle = function () {
        return this._defalutStyle;
    };
    FTypographyStream.prototype.aligns = function () {
        return this._aligns;
    };
    FTypographyStream.prototype.styles = function () {
        return this._styles;
    };
    FTypographyStream.prototype.str = function () {
        return this._str;
    };
    FTypographyStream.prototype.insets = function () {
        return this._insets;
    };
    FTypographyStream.prototype.iter = function () {
        return new StreamIterator(this);
    };
    FTypographyStream.prototype._fillDefaultStyle = function () {
        var style = this._defalutStyle;
        if (!style.fontInfo) {
            style.fontInfo = defaultFont;
        }
        else {
            var font = style.fontInfo;
            if (!font.fontFamily)
                font.fontFamily = defaultFont.fontFamily;
            if (!font.fontSize)
                font.fontSize = defaultFont.fontSize;
            if (!font.fontStyle)
                font.fontStyle = defaultFont.fontStyle;
            if (!font.fontWeight)
                font.fontWeight = defaultFont.fontWeight;
        }
        if (!style.color)
            style.color = 'black';
    };
    FTypographyStream._removeAttr = function (attrs, from, to) {
        var low = attrs.lbound({ rg: { from: from, to: to } }, true);
        if (low === -1)
            return;
        var up = attrs.ubound({ rg: { from: to, to: to } }, true);
        if (up === -1)
            return;
        var lowElem = attrs.at(low);
        if (lowElem.rg.to < from) {
            ++low;
            if (low < attrs.len())
                lowElem = attrs.at(low);
        }
        var upElem = attrs.at(up);
        if (upElem.rg.from > to) {
            --up;
            if (up >= 0)
                upElem = attrs.at(up);
        }
        attrs.remove(low, up - low + 1);
        if (lowElem.rg.from < from && from < lowElem.rg.to) {
            lowElem.rg.to = from - 1;
            attrs.insert(lowElem);
        }
        if (upElem.rg.from < to && to < upElem.rg.to) {
            upElem.rg.from = to + 1;
            attrs.insert(upElem);
        }
    };
    return FTypographyStream;
}());
var StreamIterator = /** @class */ (function () {
    function StreamIterator(_reader) {
        this._reader = _reader;
        this._citer = new CharIter(this._reader.str());
        this._insetIter = this._reader.insets().iter();
        this._styleIter = this._reader.styles().iter();
        this._alignIter = this._reader.aligns().iter();
    }
    StreamIterator.prototype.next = function () {
        var citer = this._citer;
        var iiter = this._insetIter;
        var insets = this._reader.insets();
        var str = this._reader.str();
        if (!this.isValid()) {
            if (!insets.len())
                citer.next();
            else if (!str.length)
                iiter.next();
            else if (insets.first().pos <= 0)
                iiter.next();
            else
                citer.next();
            this._styleIter.next();
            this._alignIter.next();
        }
        else {
            if (citer.isValid() && iiter.isValid()) {
                if (iiter.value().pos === citer.idx()) {
                    iiter.next();
                }
                else if (iiter.value().pos < citer.idx()) {
                    iiter.next();
                    if (!iiter.isValid() || iiter.value().pos !== citer.idx())
                        citer.next();
                }
                else {
                    citer.next();
                }
            }
            else if (citer.isValid() && !iiter.isValid()) {
                var pos = citer.idx() + citer.units();
                citer.next();
                var firstInset = insets.first();
                if (firstInset && (((!citer.isValid() && firstInset.pos >= pos) ||
                    firstInset.pos === citer.idx())))
                    iiter.next();
            }
            else if (!citer.isValid() && iiter.isValid()) {
                var pos = iiter.value().pos;
                iiter.next();
                if (pos <= 0 && (!iiter.isValid() || iiter.value().pos > 0))
                    citer.next();
            }
        }
        this._nextAttr();
        return this.isValid() ? this : null;
    };
    StreamIterator.prototype.prev = function () {
        var citer = this._citer;
        var iiter = this._insetIter;
        var insets = this._reader.insets();
        var str = this._reader.str();
        if (!this.isValid()) {
            if (!insets.len())
                citer.prev();
            else if (!str.length)
                iiter.prev();
            else if (insets.last().pos >= str.length)
                iiter.prev();
            else
                citer.prev();
            this._styleIter.prev();
            this._alignIter.prev();
        }
        else {
            if (citer.isValid() && iiter.isValid()) {
                var prevChar = function () {
                    citer.prev();
                    // when char hit inset, we should let this char iterate before the inset
                    // because prev method means iterating in reverse.
                    if (iiter.isValid() && citer.idx() === iiter.value().pos)
                        iiter.next();
                };
                if (iiter.value().pos >= citer.idx()) {
                    iiter.prev();
                    if (!iiter.isValid() || iiter.value().pos !== citer.idx())
                        prevChar();
                }
                else {
                    prevChar();
                }
            }
            else if (citer.isValid() && !iiter.isValid()) {
                var lastInset = insets.last();
                if (lastInset && lastInset.pos === citer.idx()) {
                    iiter.prev();
                }
                else {
                    var pos = citer.idx();
                    citer.prev();
                    if (lastInset && (!citer.isValid() && lastInset.pos <= pos))
                        iiter.prev();
                }
            }
            else if (!citer.isValid() && iiter.isValid()) {
                var pos = iiter.value().pos;
                iiter.prev();
                if (0 < str.length && str.length <= pos
                    && (!iiter.isValid() || iiter.value().pos < str.length))
                    citer.prev();
            }
        }
        this._prevAttr();
        return this.isValid() ? this : null;
    };
    StreamIterator.prototype.value = function () {
        if (!this.atInset())
            return this._citer.char();
        else
            return this._insetIter.value();
    };
    StreamIterator.prototype.codePoint = function () {
        return this._citer.codePoint();
    };
    StreamIterator.prototype.char = function () {
        return this._citer.char();
    };
    StreamIterator.prototype.charPos = function () {
        return this._citer.isValid() ? this._citer.idx()
            : this._insetIter.isValid() ? this._insetIter.value().pos : -1;
    };
    StreamIterator.prototype.units = function () {
        return this._citer.units();
    };
    StreamIterator.prototype.isValid = function () {
        return this._citer.isValid() || this._insetIter.isValid();
    };
    StreamIterator.prototype.atInset = function () {
        var iiter = this._insetIter;
        var citer = this._citer;
        return (!citer.isValid() && iiter.isValid())
            || (iiter.isValid() && iiter.value().pos === citer.idx());
    };
    StreamIterator.prototype.currentAlign = function () {
        var attr = this._currentAttr(this._alignIter);
        return {
            hAlign: attr && attr.hAlign || exports.HorizontalAlign.Left,
            vAlign: attr && attr.vAlign || exports.VerticalAlign.Top
        };
    };
    StreamIterator.prototype.currentStyle = function () {
        var attr = this._currentAttr(this._styleIter);
        return attr !== null ? attr.style : this._reader.defaultStyle();
    };
    StreamIterator.prototype.seek = function (idx) {
        this._citer.seek(idx);
        var styleIdx = this._attrIdx(this._reader.styles());
        var alignIdx = this._attrIdx(this._reader.aligns());
        this._styleIter.seek(styleIdx);
        this._alignIter.seek(alignIdx);
        return this;
    };
    StreamIterator.prototype._attrIdx = function (arr) {
        var idx = this.charPos();
        if (!this._citer.isValid())
            return idx;
        var attrIdx = arr.lbound({ rg: { from: idx, to: idx } }, true);
        return attrIdx;
    };
    StreamIterator.prototype._currentAttr = function (iter) {
        if (!iter.isValid())
            return null;
        var v = iter.value();
        var idx = this.charPos();
        if (idx < v.rg.from || v.rg.to < idx)
            return null;
        else
            return v;
    };
    StreamIterator.prototype._nextAttr = function () {
        this._nextAttrIter(this._alignIter);
        this._nextAttrIter(this._styleIter);
    };
    StreamIterator.prototype._prevAttr = function () {
        this._prevAttrIter(this._alignIter);
        this._prevAttrIter(this._styleIter);
    };
    StreamIterator.prototype._nextAttrIter = function (iter) {
        if (!iter.isValid())
            return;
        var idx = this.charPos();
        if (idx < 0)
            return;
        var rg = iter.value().rg;
        if (idx > rg.to)
            iter.next();
    };
    StreamIterator.prototype._prevAttrIter = function (iter) {
        if (!iter.isValid())
            return;
        var idx = this.charPos();
        if (idx < 0)
            return;
        var rg = iter.value().rg;
        if (idx < rg.from)
            iter.prev();
    };
    return StreamIterator;
}());

var TextSeg = /** @class */ (function () {
    function TextSeg(from, len, chars, rect, style) {
        this.from = from;
        this.len = len;
        this.chars = chars;
        this.rect = rect;
        this.style = style;
    }
    TextSeg.prototype.clone = function () {
        return new TextSeg(this.from, this.len, this.chars, this.rect.clone(), this.style);
    };
    return TextSeg;
}());
var EllipsisSeg = /** @class */ (function () {
    function EllipsisSeg(rect, ellipsis, style) {
        this.rect = rect;
        this.ellipsis = ellipsis;
        this.style = style;
    }
    EllipsisSeg.prototype.clone = function () {
        return new EllipsisSeg(this.rect.clone(), this.ellipsis, this.style);
    };
    return EllipsisSeg;
}());
var InsetSeg = /** @class */ (function () {
    function InsetSeg(rect, inset) {
        this.rect = rect;
        this.inset = inset;
    }
    InsetSeg.prototype.clone = function () {
        return new InsetSeg(this.rect.clone(), this.inset);
    };
    return InsetSeg;
}());
var FTypographer = /** @class */ (function () {
    function FTypographer(options) {
        this._lines = [];
        this._cursor = new core.FPoint(0, 0);
        this._typhyLine = null;
        this._effectedInset = [];
        this._stream = new FTypographyStream(this, options.defaultStyle);
        this._width = options.width || Number.MAX_VALUE;
        this._maxWidth = options.maxWidth || -1;
        this._minWidth = options.minWidth || -1;
        this._height = options.height || Number.MAX_VALUE;
        this._wordWrap = !!options.wordWrap;
        this._ellipsis = options.ellipsis;
        this._iter = this._stream.iter();
        this._wordBox = { width: 0, height: 0, segs: [], guessing: true };
        this._wordsBox = { width: 0, height: 0, segs: [], guessing: true, };
        this._currMeasure = this._newMeasurer(this._stream.defaultStyle());
        this._visualInfo = { lineCount: 0, width: 0, height: 0, ellipsLine: null };
    }
    /**
     * typography to vertical pos 'y'
     */
    FTypographer.prototype.typography = function (toY) {
        var iter = this._iter;
        toY = Math.min(toY, this._height);
        if (this._cursor.y >= toY)
            return;
        if (this._lines.length > 0 && !iter.isValid())
            return;
        while (this._cursor.y < toY && iter.next() !== null) {
            var v = iter.value();
            if (iter.atInset()) {
                this._placeInset(v);
            }
            else {
                if (v === '\r' || v === '\n') {
                    // if char iter not back, place in line.
                    this._smartPlaceWord();
                    this._placeWords();
                    if (this._typhyLine === null)
                        this._newLine();
                    this._placeLine(true);
                    if (v === '\r') {
                        // if next char is \n, skip both \r and \n , otherwise back and only skip \r
                        var nextIsN = iter.next() !== null && iter.char() === '\n';
                        if (!nextIsN)
                            iter.prev();
                    }
                }
                else {
                    if (this._breakableChar(iter)) {
                        this._smartPlaceWord();
                        // smart place in word may skip some char
                        if (v === iter.value())
                            this._preplaceChar();
                    }
                    else {
                        this._preplaceChar();
                    }
                }
            }
            if (!iter.isValid())
                break;
        }
        this._smartPlaceWord();
        this._placeWords();
        this._placeLine(true);
        this._updateVisualInfo();
        var ellipsisLine = this._visualInfo.ellipsLine;
        if (ellipsisLine) {
            this._alignHorizontal(ellipsisLine);
            this._alignVertical(ellipsisLine);
        }
    };
    FTypographer.prototype.updateOptions = function (options) {
        // todo: should support increment typography
        this._width = options.width || Number.MAX_VALUE;
        this._maxWidth = options.maxWidth || -1;
        this._minWidth = options.minWidth || -1;
        this._height = options.height || Number.MAX_VALUE;
        this._wordWrap = !!options.wordWrap;
        this._ellipsis = options.ellipsis;
        if (options.defaultStyle) {
            this._stream.updateDefaultStyle(options.defaultStyle);
        }
        this.reset();
    };
    FTypographer.prototype.reset = function () {
        this._lines.length = 0;
        this._iter = this._stream.iter();
        this._effectedInset.length = 0;
        this._cursor.x = 0;
        this._cursor.y = 0;
        this._typhyLine = null;
        this._resetWordBox();
        this._resetTyphingWords();
        this._currMeasure = this._newMeasurer(this._stream.defaultStyle());
        this._visualInfo.lineCount = 0;
        this._visualInfo.width = 0;
        this._visualInfo.height = 0;
        this._visualInfo.ellipsLine = null;
    };
    FTypographer.prototype.visualInfo = function () {
        return this._visualInfo;
    };
    FTypographer.prototype.stream = function () {
        return this._stream;
    };
    FTypographer.prototype.lines = function () {
        return this._lines;
    };
    /**
     * Find which char at `pos`, if no char at there, return -1,
     * otherwise, return the char idx.
     */
    FTypographer.prototype.posHitChar = function (pos) {
        var lines = new core.SortedArray(function (a, b) {
            if (a.y < b.y)
                return -1;
            else if (a.y > b.y)
                return 1;
            else
                return 0;
        }, this._lines);
        var lineIdx = lines.lbound({ y: pos.y }, true);
        if (lineIdx === -1)
            return -1;
        var line = lines.at(lineIdx);
        if (line.y <= pos.y && pos.y < line.y + line.height) {
            var segs = new core.SortedArray(function (a, b) {
                if (a.rect.x < b.rect.x)
                    return -1;
                else if (a.rect.x > b.rect.x)
                    return 1;
                else
                    return 0;
            }, line.segs);
            var segIdx = segs.lbound({ rect: { x: pos.x } }, true);
            if (segIdx === -1)
                return -1;
            var seg = segs.at(segIdx);
            if (seg instanceof TextSeg && seg.rect.x <= pos.x && pos.x < seg.rect.maxX) {
                return this._measureChar(seg, pos.x - seg.rect.x, false).idx;
            }
        }
        return -1;
    };
    /**
     * get the char rect by the char idx.
     */
    FTypographer.prototype.charRect = function (idx) {
        var rect = new core.FRect();
        var lines = new core.SortedArray(function (a, b) {
            if (a.from < b.from)
                return -1;
            else if (a.from > b.from)
                return 1;
            else
                return 0;
        }, this._lines);
        var lineIdx = lines.lbound({ from: idx }, true);
        if (lineIdx === -1)
            return rect;
        var segs = new core.SortedArray(function (a, b) { return a.from < b.from ? -1 : a.from > b.from ? 1 : 0; }, lines.at(lineIdx).segs.filter(function (seg) { return seg instanceof TextSeg; }));
        var segIdx = segs.lbound({ from: idx }, true);
        if (segIdx === -1)
            return rect;
        var seg = segs.at(segIdx);
        if (seg.from <= idx && idx < seg.from + seg.len) {
            var measurer = this._newMeasurer(seg.style);
            var text = this._stream.str().substr(seg.from, idx - seg.from);
            rect.y = seg.rect.y;
            rect.height = seg.rect.height;
            rect.x = seg.rect.x + measurer.measureText(text);
            var citer = new CharIter(this._stream.str());
            citer.seek(idx);
            rect.width = measurer.measureChar(citer.codePoint(), citer.char());
        }
        return rect;
    };
    FTypographer.prototype._alignHorizontal = function (tline) {
        if (tline.hAlign === exports.HorizontalAlign.Left)
            return;
        var width = this._width !== Number.MAX_VALUE ? this._validWidth(this._width) :
            this._validWidth(this._visualInfo.width);
        var toAdjust = tline.segs;
        var lineSpaces = [new core.FRect(0, tline.y, width, tline.height)];
        var adjustSegs = function () {
            if (toAdjust.length === 0)
                return;
            var contentWidth = toAdjust[toAdjust.length - 1].rect.maxX - toAdjust[0].rect.x;
            var rect = lineSpaces.shift();
            while (rect && lineSpaces.length && rect.width < contentWidth) {
                rect = lineSpaces.shift();
            }
            if (!rect)
                return;
            var offset = rect.x - toAdjust[0].rect.x;
            var blank = rect.width - contentWidth;
            if (tline.hAlign === exports.HorizontalAlign.Right) {
                toAdjust.forEach(function (seg) { return seg.rect.x += offset + blank; });
            }
            else {
                toAdjust.forEach(function (seg) { return seg.rect.x += offset + blank / 2; });
            }
        };
        adjustSegs();
        if (this._effectedInset.length) {
            toAdjust = [];
            lineSpaces = [new core.FRect(0, tline.y, width, tline.height)];
            this._effectedInset.forEach(function (info) {
                var newSpaces = [];
                lineSpaces.forEach(function (space) {
                    if (space.intersect(info.seg.rect)) {
                        var x = info.seg.rect.x;
                        if (x > space.x) {
                            newSpaces.push(new core.FRect(space.x, space.y, x - space.x, space.height));
                        }
                        var maxX = info.seg.rect.maxX;
                        if (maxX < space.maxX) {
                            newSpaces.push(new core.FRect(maxX, space.y, space.maxX - maxX, space.height));
                        }
                    }
                    else {
                        newSpaces.push(space);
                    }
                });
                lineSpaces = newSpaces;
            });
            lineSpaces.sort(function (a, b) {
                if (a.x < b.x)
                    return -1;
                else if (a.x > b.x)
                    return 1;
                else
                    return 0;
            });
            tline.segs.forEach(function (seg) {
                if (!toAdjust.length || (!(seg instanceof InsetSeg)
                    && toAdjust[toAdjust.length - 1].rect.maxX === seg.rect.x)) {
                    toAdjust.push(seg);
                }
                else {
                    adjustSegs();
                    toAdjust.length = 0;
                    if (!(seg instanceof InsetSeg))
                        toAdjust.push(seg);
                }
            });
            adjustSegs();
        }
    };
    FTypographer.prototype._alignVertical = function (tline) {
        var dfont = this._stream.defaultStyle().fontInfo;
        tline.segs.forEach(function (seg) {
            if (seg instanceof InsetSeg && seg.inset.inline !== true)
                return;
            var font = dfont;
            if (seg instanceof TextSeg && seg.style)
                font = seg.style.fontInfo || dfont;
            if (!(seg instanceof InsetSeg))
                seg.rect.height = font.fontSize || dfont.fontSize;
            if (tline.vAlign === exports.VerticalAlign.Center) {
                seg.rect.y += tline.height / 2 - seg.rect.height / 2;
            }
            else if (tline.vAlign === exports.VerticalAlign.Bottom) {
                seg.rect.y += tline.height - seg.rect.height;
            }
        });
    };
    FTypographer.prototype._measureWordsBox = function () {
        return this._measureWords(this._wordsBox);
    };
    FTypographer.prototype._measureWordBox = function () {
        return this._measureWords(this._wordBox);
    };
    /**
     * measure real width of the typographing words
     * and return the difference between the real width and guess width
     */
    FTypographer.prototype._measureWords = function (wordInfo) {
        var _this = this;
        if (wordInfo.guessing) {
            var segs = wordInfo.segs;
            var diff = segs.reduce(function (c, seg) {
                var text = _this._stream.str().substr(seg.from, seg.len);
                var guess = seg.rect.width;
                var measurer = _this._newMeasurer(seg.style);
                seg.rect.width = measurer.measureText(text);
                return c + seg.rect.width - guess;
            }, 0);
            wordInfo.width += diff;
            wordInfo.guessing = false;
            return diff;
        }
        return 0;
    };
    /**
     * split segs by spliter from back
     */
    FTypographer.prototype._rsegsSplit = function (segs, spliter, containSplter) {
        var res = [];
        var iter = new CharIter(this._stream.str());
        for (var i = segs.length - 1; i >= 0; i--) {
            var seg = segs[i];
            if (!(seg instanceof TextSeg))
                break;
            iter.seek(seg.from + seg.len);
            var chars = 0;
            while (iter.prev() !== null && iter.idx() >= seg.from && !spliter(seg, iter))
                ++chars;
            var idx = iter.idx();
            if (!containSplter)
                idx += iter.units();
            if (idx <= seg.from) {
                res.unshift(seg);
                segs.pop();
            }
            else {
                var splited = this._splitSeg(seg, idx, chars);
                res.unshift(splited);
                break;
            }
        }
        return res;
    };
    FTypographer.prototype._splitSeg = function (seg, idx, chars) {
        var splited = new TextSeg(idx, seg.from + seg.len - idx, chars, seg.rect.clone(), seg.style);
        seg.len -= splited.len;
        seg.chars -= chars;
        var splitedText = this._stream.str().substr(splited.from, splited.len);
        splited.rect.width = this._newMeasurer(splited.style).measureText(splitedText);
        seg.rect.width -= splited.rect.width;
        return splited;
    };
    FTypographer.prototype._trim = function (word) {
        var iter = new CharIter(this._stream.str());
        var lineHeightChanged = false;
        while (word.segs.length > 0) {
            var seg = word.segs[0];
            var end = seg.from + seg.len;
            iter.seek(seg.from);
            var chars = 0;
            while (iter.idx() < end && iter.char() === ' ') {
                iter.next();
                chars++;
            }
            var idx = iter.idx();
            if (idx === end) {
                word.segs.shift();
                if (seg.rect.height >= word.height)
                    lineHeightChanged = true;
                word.width -= seg.rect.width;
            }
            else {
                if (idx > seg.from) {
                    var second = this._splitSeg(seg, idx, chars);
                    word.width -= seg.rect.width;
                    word.segs[0] = second;
                }
                break;
            }
        }
        if (lineHeightChanged) {
            word.height = word.segs.reduce(function (p, c) { return Math.max(p, c.rect.height); }, 0);
        }
    };
    FTypographer.prototype._trimEnd = function (word) {
        var blank = this._rsegsSplit(word.segs, function (_, iter) { return iter.char() !== ' '; }, false);
        if (blank.length > 0) {
            word.height = word.segs.reduce(function (p, c) {
                if (!(c instanceof TextSeg))
                    return p;
                else
                    return Math.max(p, c.rect.height);
            }, 0);
            word.width -= blank.reduce(function (p, c) { return p + c.rect.width; }, 0);
        }
        return blank;
    };
    FTypographer.prototype._placeLine = function (skipBlank) {
        if (this._typhyLine !== null) {
            var tline = this._typhyLine;
            if (tline.segs.length > 0)
                this._trimEnd(tline);
            this._cursor.x = 0;
            tline.y = this._cursor.y;
            this._cursor.y += tline.height;
            if (this._effectedInset.length > 0) {
                tline.refLines = this._effectedInset.map(function (info) { return info.place; });
            }
            if (this._width !== Number.MAX_VALUE) {
                this._alignHorizontal(tline);
                this._alignVertical(tline);
            }
            this._typhyLine = null;
            if (skipBlank)
                this._skipBlank();
        }
    };
    FTypographer.prototype._newLine = function () {
        this._shakeInsets(this._cursor.y);
        var idx = this._iter.charPos();
        if (this._wordsBox.segs.length > 0)
            idx = this._wordStart(this._wordsBox);
        else if (this._wordBox.segs.length > 0)
            idx = this._wordStart(this._wordBox);
        var _a = this._alignment(idx), hAlign = _a.hAlign, vAlign = _a.vAlign;
        this._typhyLine = {
            hAlign: hAlign, vAlign: vAlign,
            y: this._cursor.y,
            segs: [], from: idx,
            width: 0,
            height: this._currLineHeight(),
        };
        this._lines.push(this._typhyLine);
    };
    FTypographer.prototype._shakeInsets = function (typhied) {
        this._effectedInset = this._effectedInset
            .filter(function (ins) { return typhied < ins.seg.rect.maxY; });
    };
    FTypographer.prototype._placeInset = function (inset) {
        this._smartPlaceWord();
        if (this._wordsBox !== null) {
            this._trimEnd(this._wordsBox);
            this._placeWords();
        }
        var pos;
        if (!inset.wrapText) {
            this._placeLine(true);
            pos = new core.FPoint(this._cursor.x, this._cursor.y);
        }
        else {
            pos = this._findEmptySpace(this._cursor.x, this._cursor.y, inset.width, inset.height);
            if (pos.y !== this._cursor.y) {
                this._placeLine(true);
                this._cursor = pos;
            }
        }
        if (this._typhyLine == null)
            this._newLine();
        var insetInfo = new InsetSeg(new core.FRect(pos.x, pos.y, inset.width, inset.height), inset);
        var tline = this._typhyLine;
        tline.segs.push(insetInfo);
        tline.width += insetInfo.rect.width;
        // when word wrap not be allowed, all inset must be inline.
        // otherwise, we didn't know how to typography an line has inset, and need horizontal align by center.
        // example:
        // `this is line one has a inset |40x100|, line height is 20 and horizontal aligned by left.
        // this is line two has another inset |200, 50|, line height is 20 and horizontal aligned by center.`
        // in the example how do we place the inset line two?
        if (inset.inline === true || !inset.wrapText) {
            tline.height = Math.max(tline.height, inset.height);
        }
        else {
            this._effectedInset.push({ place: this._lines.length, seg: insetInfo });
        }
        this._cursor.x = insetInfo.rect.maxX;
        if (!inset.wrapText)
            this._placeLine(true);
        this._skipBlank();
    };
    FTypographer.prototype._findEmptySpace = function (x, y, width, height) {
        var ctxWidth = this._contentWidth();
        // if x is over the line, reset it to line start to find good place.
        var newLine = function () {
            x = 0;
            y += height;
        };
        var intersected = 0;
        do {
            intersected = 0;
            if (x !== 0 && x + width > ctxWidth)
                newLine();
            this._effectedInset.forEach(function (info) {
                var rect = info.seg.rect;
                if (rect.x < x + width && x < rect.maxX && rect.y < y + height && y < rect.maxY) {
                    if (ctxWidth - rect.maxX > width) {
                        // right has space to place
                        x = rect.maxX;
                    }
                    else if (x > width) {
                        // left has space to place
                        newLine();
                    }
                    else {
                        x = 0;
                        y = rect.maxY;
                    }
                    intersected++;
                }
            });
        } while (intersected);
        return new core.FPoint(x, y);
    };
    FTypographer.prototype._newMeasurer = function (style) {
        var dfont = this._stream.defaultStyle().fontInfo;
        var fontInfo = style.fontInfo || dfont;
        return new FontMeasurer(fontInfo.fontFamily || dfont.fontFamily, fontInfo.fontWeight || core.FontWeight.normal, fontInfo.fontSize || dfont.fontSize);
    };
    FTypographer.prototype._contentWidth = function () {
        return this._wordWrap === true ? this._validWidth(this._width) : Number.MAX_VALUE;
    };
    FTypographer.prototype._alignment = function (pos) {
        if (pos !== this._iter.charPos()) {
            var aligns = this._stream.aligns();
            var idx = aligns.lbound({ rg: { from: pos, to: pos } }, true);
            if (idx !== -1) {
                var align = aligns.at(idx);
                if (align.rg.to >= pos)
                    return { hAlign: align.hAlign, vAlign: align.vAlign };
            }
            return {
                hAlign: exports.HorizontalAlign.Left,
                vAlign: exports.VerticalAlign.Top
            };
        }
        else {
            return this._iter.currentAlign();
        }
    };
    /**
     * when typographing words' real width greater than guess width, and current place cant't
     * place the words with real width, must break words or find a new place to place the words.
     *
     */
    FTypographer.prototype._refindTyphingWordsPlace = function () {
        var _this = this;
        var backedWords = [];
        var words = this._wordsBox;
        while (words.segs.length > 0) {
            var word = this._rsegsSplit(words.segs, function (_, iter) { return _this._breakableChar(iter); }, true);
            var size = this._textSegsSize(word);
            words.height = words.segs.reduce(function (p, c) { return Math.max(p, c.rect.height); }, 0);
            words.width -= size.width;
            backedWords.unshift({ width: size.width, segs: word, height: size.height, guessing: true });
            var pos = this._findEmptySpace(this._cursor.x, this._cursor.y, words.width, words.height);
            if (pos.equal(this._cursor)) {
                this._innerPlaceWords();
                break;
            }
        }
        var bword = this._wordBox;
        backedWords.forEach(function (word) {
            _this._wordBox = word;
            _this._smartPlaceWord();
        });
        this._wordBox = bword;
    };
    FTypographer.prototype._resetTyphingWords = function () {
        this._wordsBox.guessing = true;
        this._wordsBox.segs.length = 0;
        this._wordsBox.height = 0;
        this._wordsBox.width = 0;
    };
    FTypographer.prototype._newAttrSeg = function () {
        var segs = this._wordBox.segs;
        if (segs.length > 0) {
            // remove tail empty seg
            var lastSeg = segs[segs.length - 1];
            if (lastSeg.len === 0) {
                segs.pop();
                if (lastSeg.rect.height >= this._wordBox.height) {
                    this._wordBox.height = segs.reduce(function (p, c) { return Math.max(p, c.rect.height); }, 0);
                }
            }
        }
        var style = this._iter.currentStyle();
        this._currMeasure = this._newMeasurer(style);
        var seg = new TextSeg(this._iter.charPos(), 0, 0, new core.FRect(0, 0, 0, this._currLineHeight()), style);
        segs.push(seg);
        this._wordBox.height = Math.max(this._wordBox.height, seg.rect.height);
    };
    FTypographer.prototype._applyEllipsis = function (line) {
        var style = this._stream.defaultStyle();
        var eWidth = 0;
        var segs = line.segs;
        var width = this._validWidth(this._width);
        for (var i = segs.length - 1; i >= 0; i--) {
            var seg = segs[i];
            if (!(seg instanceof TextSeg))
                break;
            style = seg.style;
            var measurer = this._newMeasurer(style);
            eWidth = measurer.measureText(this._ellipsis);
            var contentEnd = width - eWidth;
            if (seg.rect.x >= contentEnd) {
                segs.pop();
            }
            else if (seg.rect.maxX > contentEnd) {
                this._splitSegByWidth(seg, contentEnd - seg.rect.x, false);
            }
        }
        var x = 0;
        if (segs.length > 0) {
            var lastSeg = segs[segs.length - 1];
            if (lastSeg instanceof EllipsisSeg)
                return;
            x = segs[segs.length - 1].rect.maxX;
        }
        var ellipsisSeg = new EllipsisSeg(new core.FRect(x, line.y, eWidth, this._currLineHeight()), this._ellipsis, style);
        segs.push(ellipsisSeg);
        line.width = ellipsisSeg.rect.maxX;
    };
    FTypographer.prototype._preplaceChar = function () {
        var code = this._iter.codePoint();
        var segs = this._wordBox.segs;
        if (segs.length === 0) {
            this._newAttrSeg();
        }
        else {
            var last = segs[segs.length - 1];
            var currentStyle = this._iter.currentStyle();
            if (last.style !== currentStyle)
                this._newAttrSeg();
        }
        var word = this._wordBox;
        var cw = word.guessing ? this._currMeasure.guessCharWidth(code)
            : this._currMeasure.measureChar(code, this._iter.value());
        var seg = segs[segs.length - 1];
        seg.len += this._iter.units();
        seg.chars += 1;
        seg.rect.width += cw;
        word.width += cw;
        this._tryEarlyCheckIn();
    };
    FTypographer.prototype._tryEarlyCheckIn = function () {
        if (this._typhyLine === null)
            this._newLine();
        var tline = this._typhyLine;
        var word = this._wordBox;
        var words = this._wordsBox;
        // todo: right align can also be early check
        var earlyCheckin = !this._wordWrap && this._cursor.x + words.width + word.width > this._validWidth(this._width)
            && (this._ellipsis !== null || tline.hAlign === exports.HorizontalAlign.Left);
        if (earlyCheckin) {
            var diff = this._measureWordBox() + this._measureWordsBox();
            if (diff < 0) {
                this._tryEarlyCheckIn();
                return;
            }
            this._placeWord();
            this._placeWords();
            if (this._ellipsis !== null) {
                this._applyEllipsis(tline);
                this._skipToNextLine();
            }
            else if (tline.hAlign === exports.HorizontalAlign.Left) {
                this._skipToNextLine();
            }
        }
    };
    FTypographer.prototype._smartPlaceWord = function () {
        var word = this._wordBox;
        if (word.segs.length === 0)
            return;
        var twords = this._wordsBox;
        var cx = this._cursor.x;
        var cy = this._cursor.y;
        var height = Math.max(word.height, twords.height);
        if (this._typhyLine !== null) {
            height = Math.max(this._typhyLine.height, height);
        }
        var pos = this._findEmptySpace(cx + twords.width, cy, word.width, Math.max(twords.height, height));
        if (pos.x !== cx + twords.width || pos.y !== cy) {
            if (twords.segs.length > 0) {
                this._placeWords();
                this._smartPlaceWord();
            }
            else {
                var wordDiff = this._measureWordBox();
                if (wordDiff >= 0) {
                    if (pos.y !== cy)
                        this._placeLine(false);
                    this._cursor = pos;
                    // as the first word of a new place, should trim the word
                    this._trim(word);
                    this._placeWord();
                }
                else {
                    this._smartPlaceWord();
                }
            }
        }
        else {
            this._placeWord();
        }
    };
    FTypographer.prototype._placeWord = function () {
        var word = this._wordBox;
        if (word.segs.length === 0)
            return;
        var twords = this._wordsBox;
        if (twords.segs.length === 0) {
            twords.guessing = word.guessing;
        }
        // if current word width greater than the line, and word wrap be allowed,
        // we can force break the word. And cursor current must be in a new line.
        var width = this._validWidth(this._width);
        if (this._wordWrap && word.width > width) {
            var diff = this._measureWordBox();
            // word width really greater than the line
            if (diff >= 0) {
                while (word.width > width && word.segs.length > 0) {
                    this._wordBox = this._forceSplitWordByWidth(word, width);
                    this._trim(word);
                    if (word.segs.length > 0) {
                        this._innerPlaceInWord(word);
                        this._innerPlaceWords();
                        this._placeLine(true);
                    }
                    word = this._wordBox;
                }
                if (this._wordBox.segs.length > 0)
                    this._placeWord();
            }
            else {
                this._smartPlaceWord();
            }
        }
        else {
            if (!twords.guessing)
                this._measureWordBox();
            this._innerPlaceInWord(this._wordBox);
            this._resetWordBox();
        }
    };
    FTypographer.prototype._innerPlaceInWord = function (word) {
        var twords = this._wordsBox;
        twords.segs = this._connectTextSegs(twords.segs, word.segs, false);
        twords.width += word.width;
        twords.height = Math.max(word.height, twords.height);
    };
    FTypographer.prototype._placeWords = function () {
        var diff = this._measureWordsBox();
        if (diff > 0) {
            // if real width greater than guess width. we should place the typographing words again
            // before place current char.
            var twords = this._wordsBox;
            var tpos = this._findEmptySpace(this._cursor.x, this._cursor.y, twords.width, twords.height);
            if (!tpos.equal(this._cursor))
                this._refindTyphingWordsPlace();
            else
                this._innerPlaceWords();
        }
        else {
            this._innerPlaceWords();
        }
    };
    FTypographer.prototype._wordStart = function (word) {
        var from = 0;
        word.segs.forEach(function (seg) {
            if (seg instanceof TextSeg) {
                from = seg.from;
                return true;
            }
            return false;
        });
        return from;
    };
    FTypographer.prototype._innerPlaceWords = function () {
        if (this._wordsBox.segs.length === 0)
            return;
        if (this._typhyLine === null)
            this._newLine();
        var tline = this._typhyLine;
        var x = this._cursor.x;
        var y = this._cursor.y;
        this._wordsBox.segs.forEach(function (seg) {
            seg.rect.x = x;
            seg.rect.y = y;
            x = seg.rect.maxX;
        });
        tline.segs = this._connectTextSegs(tline.segs, this._wordsBox.segs, true);
        tline.height = Math.max(tline.height, this._wordsBox.height);
        tline.width += this._wordsBox.width;
        this._cursor.x = x;
        this._resetTyphingWords();
    };
    FTypographer.prototype._connectTextSegs = function (segs1, segs2, needPositonNear) {
        if (segs1.length > 0 && segs2.length > 0) {
            var last = segs1[segs1.length - 1];
            var first = segs2[0];
            if (last instanceof TextSeg && last.style === first.style
                && (!needPositonNear || last.rect.maxX === first.rect.x)) {
                first.rect.x = last.rect.x;
                first.from = last.from;
                first.len += last.len;
                first.chars += last.chars;
                first.rect.width += last.rect.width;
                segs1.pop();
            }
        }
        return segs1.concat(segs2);
    };
    FTypographer.prototype._resetWordBox = function () {
        this._wordBox.segs.length = 0;
        this._wordBox.height = 0;
        this._wordBox.guessing = true;
        this._wordBox.width = 0;
    };
    FTypographer.prototype._breakableChar = function (iter) {
        var code = iter.codePoint();
        var char = iter.char();
        return charType(code) !== 0 /* Latin */ || char === ' ';
    };
    FTypographer.prototype._skipToNextLine = function () {
        var newline = function (v) { return v === '\r' || v === '\n'; };
        this._skipTo(newline);
        this._placeLine(true);
    };
    FTypographer.prototype._skipBlank = function () {
        var iter = this._iter;
        this._skipTo(function (char) { return char !== ' '; });
        if (iter.isValid())
            iter.prev();
    };
    FTypographer.prototype._skipTo = function (cb) {
        var iter = this._iter;
        while (iter.isValid() && iter.next() !== null && !cb(iter.value()))
            ;
    };
    /**
     * calc the segs size
     */
    FTypographer.prototype._textSegsSize = function (segs) {
        return segs.reduce(function (p, c) {
            p.width += c.rect.width;
            p.height = Math.max(c.rect.height, p.height);
            return p;
        }, { width: 0, height: 0 });
    };
    FTypographer.prototype._updateVisualInfo = function () {
        var visual = this._visualInfo;
        visual.lineCount = this._lines.length;
        visual.width = 0;
        visual.height = 0;
        var lines = this._lines;
        if (this._ellipsis !== null) {
            var i = lines.length - 1;
            while (i > 0) {
                var line = lines[i];
                if (line.y + line.height <= this._height)
                    break;
                else
                    --i;
            }
            visual.lineCount = i + 1;
            if (visual.lineCount < lines.length || this._iter.isValid()
                || (0 <= i && i < lines.length && lines[i].width > this._validWidth(this._width))) {
                var ellipsisLine = __assign({}, lines[i]);
                // segs may changing when applyEllipsis, but we should not change the typography data.
                // so segs must be deepclone,
                ellipsisLine.segs = ellipsisLine.segs.map(function (seg) { return seg.clone(); });
                this._applyEllipsis(ellipsisLine);
                visual.ellipsLine = ellipsisLine;
                visual.lineCount -= 1;
            }
        }
        if (visual.lineCount > 0) {
            for (var i = 0; i < visual.lineCount; i++) {
                visual.width = Math.max(lines[i].width, visual.width);
            }
            var lastLine = lines[visual.lineCount - 1];
            visual.height = lastLine.y + lastLine.height;
        }
        if (visual.ellipsLine !== null) {
            visual.width = Math.max(visual.width, visual.ellipsLine.width);
            visual.height = visual.ellipsLine.y + visual.ellipsLine.height;
        }
    };
    FTypographer.prototype._forceSplitWordByWidth = function (word, width) {
        var res = [];
        var wordWidth = word.width;
        var lineHeightChanged = false;
        for (var i = word.segs.length - 1; i >= 0; i--) {
            var seg = word.segs[i];
            if (word.width - seg.rect.width > width) {
                res.unshift(seg);
                word.segs.pop();
                word.width -= seg.rect.width;
                if (seg.rect.height >= word.height)
                    lineHeightChanged = true;
            }
            else {
                if (word.width - width > 0) {
                    var cut = this._splitSegByWidth(seg, seg.rect.width - (word.width - width), word.segs.length === 1);
                    if (cut !== null) {
                        word.width -= cut.rect.width;
                        res.unshift(cut);
                    }
                }
                break;
            }
        }
        var secondSeg = {
            guessing: false,
            segs: res,
            height: word.height,
            width: wordWidth - word.width
        };
        if (lineHeightChanged) {
            word.height = word.segs.reduce(function (p, c) { return Math.max(p, c.rect.height); }, 0);
            secondSeg.height = res.reduce(function (p, c) { return Math.max(p, c.rect.height); }, 0);
        }
        return secondSeg;
    };
    FTypographer.prototype._splitSegByWidth = function (seg, width, leastOneChar) {
        var _a = this._measureChar(seg, width, leastOneChar), chars = _a.chars, idx = _a.idx, measureWidth = _a.measureWidth;
        if (seg.chars - chars > 0) {
            var cutSeg = seg.clone();
            cutSeg.chars = seg.chars - chars;
            cutSeg.from = idx;
            cutSeg.len = seg.from + seg.len - cutSeg.from;
            cutSeg.rect.width = seg.rect.width - measureWidth;
            cutSeg.rect.x = seg.rect.x + chars;
            seg.len -= cutSeg.len;
            seg.chars = chars;
            seg.rect.width = measureWidth;
            return cutSeg;
        }
        else {
            return null;
        }
    };
    FTypographer.prototype._measureChar = function (seg, width, leastOneChar) {
        var iter = new CharIter(this._stream.str());
        var avg = seg.rect.width / seg.chars;
        var keepChars = Math.floor(width / avg);
        iter.seek(seg.from);
        for (var i = 0; i < keepChars && iter.next() !== null; i++)
            ;
        var text = this._stream.str().substr(seg.from, iter.idx() - seg.from);
        var measurer = this._newMeasurer(seg.style);
        var keepWidth = measurer.measureText(text);
        // if keep not enough chars
        while (keepWidth < width && iter.isValid()) {
            var cw = measurer.measureChar(iter.codePoint(), iter.char());
            keepWidth += cw;
            ++keepChars;
            iter.next();
        }
        // if keep too many chars
        while ((!leastOneChar || keepChars > 1)
            && keepWidth > width && iter.prev() !== null) {
            var cw = measurer.measureChar(iter.codePoint(), iter.char());
            keepWidth -= cw;
            --keepChars;
        }
        return { idx: iter.idx(), chars: keepChars, measureWidth: keepWidth };
    };
    FTypographer.prototype._currLineHeight = function () {
        var style = this._iter.currentStyle();
        var settings = style.lineHeight || this._stream.defaultStyle().lineHeight || 0;
        return settings > 0 ? settings : this._currMeasure.lineHeight();
    };
    FTypographer.prototype._validWidth = function (width) {
        if (this._maxWidth > 0)
            width = Math.min(this._maxWidth, width);
        if (this._minWidth > 0)
            width = Math.max(this._minWidth, width);
        if (width < 0)
            width = Number.MAX_VALUE;
        return width;
    };
    return FTypographer;
}());

var FTypographyPainter = /** @class */ (function () {
    function FTypographyPainter(_typher) {
        this._typher = _typher;
    }
    FTypographyPainter.prototype.paintLines = function (ctx) {
        ctx.save();
        // todo: use Alphabetic align
        ctx.textBaseline = 'middle';
        var info = this._typher.visualInfo();
        if (info.ellipsLine !== null) {
            this.paintLine(ctx, info.ellipsLine);
        }
        var lines = this._typher.lines();
        for (var i = 0; i < info.lineCount; i++) {
            this.paintLine(ctx, lines[i]);
        }
        ctx.restore();
    };
    FTypographyPainter.prototype.paintLine = function (ctx, line) {
        var _this = this;
        line.segs.forEach(function (seg) {
            if (!(seg instanceof InsetSeg))
                _this._paintSeg(ctx, seg);
        });
    };
    FTypographyPainter.prototype._paintSeg = function (ctx, seg) {
        var dfstyle = this._typher.stream().defaultStyle();
        var style;
        var text;
        style = seg.style || dfstyle;
        if (seg instanceof EllipsisSeg)
            text = seg.ellipsis;
        else
            text = this._typher.stream().str().substr(seg.from, seg.len);
        var font = style.fontInfo || dfstyle.fontInfo;
        var dfont = dfstyle.fontInfo;
        ctx.fontSize = font.fontSize || dfont.fontSize || 12;
        ctx.fontFamily = font.fontFamily || dfont.fontFamily || 'Arial';
        ctx.fontStyle = font.fontStyle || dfont.fontStyle || 'normal';
        ctx.fontWeight = font.fontWeight || dfont.fontWeight || core.FontWeight.normal;
        ctx.fillStyle = style.color || dfstyle.color;
        var y = seg.rect.y + seg.rect.height / 2;
        ctx.fillText(text, seg.rect.x, y, seg.rect.width);
        var decroation = (style.decoration !== undefined ? style.decoration : dfstyle.decoration) || exports.TextDecoration.None;
        ctx.strokeStyle = ctx.fillStyle;
        ctx.lineWidth = Math.floor(Math.max(ctx.fontSize - 12, 0) / 21 + 1);
        var x = seg.rect.x;
        var width = seg.rect.width;
        if (decroation & exports.TextDecoration.Bottom) {
            var ypos = seg.rect.maxY - (seg.rect.height - ctx.fontSize) / 2;
            ctx.beginPath();
            ctx.drawLine(x, ypos, x + width, ypos);
        }
        if (decroation & exports.TextDecoration.Mid) {
            var ypos = seg.rect.y + seg.rect.height / 2;
            ctx.beginPath();
            ctx.drawLine(x, ypos, x + width, ypos);
        }
        if (decroation & exports.TextDecoration.Top) {
            var ypos = seg.rect.y + (seg.rect.height - ctx.fontSize) / 2;
            ctx.beginPath();
            ctx.drawLine(x, ypos, x + width, ypos);
        }
    };
    return FTypographyPainter;
}());

var FLabel = /** @class */ (function (_super) {
    __extends(FLabel, _super);
    function FLabel(p) {
        var _this = _super.call(this, p) || this;
        _this._autoWidth = true;
        _this._autoHeight = true;
        _this._autoSet = false;
        _this._typher = new FTypographer(_this._typographyOptions());
        _this._painter = new FTypographyPainter(_this._typher);
        return _this;
    }
    Object.defineProperty(FLabel.prototype, "fontSize", {
        get: function () {
            return this._cleanProp('fontSize');
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FLabel.prototype, "fontFamily", {
        get: function () {
            return this._cleanProp('fontFamily');
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FLabel.prototype, "fontStyle", {
        get: function () {
            return this._cleanProp('fontStyle');
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FLabel.prototype, "fontWeight", {
        get: function () {
            return this._cleanProp('fontWeight');
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FLabel.prototype, "lineHeight", {
        get: function () {
            return this._cleanProp('lineHeight');
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FLabel.prototype, "autoHeight", {
        get: function () {
            return this._cleanProp('autoHeight');
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FLabel.prototype, "autoWidth", {
        get: function () {
            return this._cleanProp('autoWidth');
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FLabel.prototype, "text", {
        get: function () {
            return this._cleanProp('text');
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FLabel.prototype, "color", {
        get: function () {
            return this._cleanProp('color');
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FLabel.prototype, "textDecoration", {
        get: function () {
            return this._cleanProp('textDecoration') || 0;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FLabel.prototype, "hAlign", {
        get: function () {
            return this._cleanProp('hAlign');
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FLabel.prototype, "vAlign", {
        get: function () {
            return this._cleanProp('vAlign');
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FLabel.prototype, "wordWrap", {
        get: function () {
            return this._cleanProp('wordWrap') || false;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FLabel.prototype, "ellipsis", {
        get: function () {
            return this._cleanProp('ellipsis');
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FLabel.prototype, "minWidth", {
        get: function () {
            return this._cleanProp('minWidth');
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FLabel.prototype, "minHeight", {
        get: function () {
            return this._cleanProp('minHeight');
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FLabel.prototype, "maxWidth", {
        get: function () {
            return this._cleanProp('maxWidth');
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FLabel.prototype, "maxHeight", {
        get: function () {
            return this._cleanProp('maxHeight');
        },
        enumerable: true,
        configurable: true
    });
    FLabel.prototype.fvgNode = function () {
        var node = _super.prototype.fvgNode.call(this);
        node.type = exports.WdkFvgType.label;
        node.cfg.fontSize = this.fontSize;
        if (this.fontFamily)
            node.cfg.fontFamily = this.fontFamily;
        if (this.fontStyle)
            node.cfg.fontStyle = this.fontStyle;
        if (this.fontWeight)
            node.cfg.fontWeight = this.fontWeight;
        if (this.lineHeight)
            node.cfg.lineHeight = this.lineHeight;
        node.cfg.color = this.color;
        node.cfg.text = this.text;
        node.cfg.hAlign = this.hAlign;
        node.cfg.vAlign = this.vAlign;
        node.cfg.textDecoration = this.textDecoration;
        return node;
    };
    FLabel.prototype.posHitChar = function (pos) {
        return this._typher.posHitChar(pos);
    };
    FLabel.prototype.charRect = function (idx) {
        var crect = this.contentRect(true).move(-this.x, -this.y);
        return this._typher.charRect(idx).move(crect.x, crect.y);
    };
    FLabel.prototype.insetCreator = function (inset, rect) {
        throw new Error('label not support inset');
    };
    FLabel.prototype.afterChange = function (e) {
        if (!this._autoSet) {
            if ('width' in e.changes) {
                this._autoWidth = e.changes['width'].current < 0;
            }
            if ('height' in e.changes) {
                this._autoHeight = e.changes['height'].current < 0;
            }
        }
        return _super.prototype.afterChange.call(this, e);
    };
    FLabel.prototype.beforeChange = function (e) {
        var widthChg = e.changes['width'];
        if (widthChg)
            widthChg.current = this._validWidth(widthChg.current);
        var heightChg = e.changes['height'];
        if (heightChg)
            heightChg.current = this._validHeight(heightChg.current);
    };
    FLabel.prototype.afterFlush = function (e) {
        _super.prototype.afterFlush.call(this, e);
        var autoSetCount = 0;
        if (this._autoHeight && 'height' in e.changes)
            autoSetCount += 1;
        if (this._autoWidth && 'width' in e.changes)
            autoSetCount += 1;
        if (Object.keys(e.changes).length === autoSetCount)
            return;
        var options = ['wordWrap', 'ellipsis', 'width', 'height', 'fontSize',
            'maxWidth', 'maxHeight', 'minWidth', 'minHeight',
            'fontFamily', 'fontStyle', 'fontWeight', 'lineHeight', 'color'];
        var align = ['hAlign', 'vAlign'];
        if (options.some(function (key) { return key in e.changes; })) {
            this._typher.updateOptions(this._typographyOptions());
        }
        if (align.some(function (key) { return key in e.changes; })) {
            this._setAlign();
        }
        if ('text' in e.changes) {
            this._typher.stream().updateStr(this._cfg.text);
        }
        this._typography();
    };
    FLabel.prototype._setAlign = function () {
        var stream = this._typher.stream();
        var to = this._cfg.text.length - 1;
        stream.addAlignAttr({
            rg: { from: 0, to: to },
            hAlign: this._cfg.hAlign,
            vAlign: this._cfg.vAlign
        });
    };
    FLabel.prototype.renderWidget = function (ctx, rcRender) {
        _super.prototype.renderWidget.call(this, ctx, rcRender);
        var content = this.contentRect(true);
        var info = this._typher.visualInfo();
        if (info.width > this.width || info.height > this.height) {
            ctx.beginPath();
            ctx.rect(this.paintedRect());
            ctx.clip();
        }
        ctx.save();
        ctx.translate(content.x, content.y);
        this._painter.paintLines(ctx);
        ctx.restore();
    };
    FLabel.prototype._defalutCfg = function () {
        var cfg = _super.prototype._defalutCfg.call(this);
        cfg.fontFamily = 'Arial';
        cfg.fontSize = 12;
        cfg.color = '#000';
        cfg.text = '';
        cfg.hAlign = exports.HorizontalAlign.Left;
        cfg.vAlign = exports.VerticalAlign.Top;
        cfg.textDecoration = 0;
        cfg.width = -1;
        cfg.height = -1;
        cfg.minHeight = -1;
        cfg.maxHeight = -1;
        cfg.minWidth = -1;
        cfg.maxWidth = -1;
        return cfg;
    };
    FLabel.prototype._typography = function () {
        var _this = this;
        var height = this._autoHeight ? Number.MAX_VALUE : this._cfg.height;
        height = this._validHeight(height);
        this._typher.typography(height);
        if (this._autoHeight || this._autoWidth) {
            var info = this._typher.visualInfo();
            var _a = this._paddingBorderSize(), w = _a[0], h = _a[1];
            var width = info.width + w;
            var height_1 = info.height + h;
            this._autoSet = true;
            if (this._autoHeight)
                this.updateByCfg({ height: this._validHeight(height_1) });
            if (this._autoWidth)
                this.updateByCfg({ width: this._validWidth(width) });
            this._autoSet = false;
        }
        this._typher.lines().forEach(function (line) {
            if (line.y < _this.height) {
                line.segs.forEach(function (seg) {
                    if (seg instanceof InsetSeg && seg.rect.x < _this.width) {
                        _this._createInset(seg);
                    }
                });
            }
        });
    };
    FLabel.prototype._typographyOptions = function () {
        var rect = this.contentRect(true);
        var width = this._autoWidth ? Number.MAX_VALUE : rect.width;
        var height = this._autoHeight ? Number.MAX_VALUE : rect.height;
        height = this._validHeight(height);
        var options = {
            width: width, height: height,
            wordWrap: this.wordWrap,
            ellipsis: this.ellipsis !== undefined ? this.ellipsis : null,
            defaultStyle: {
                decoration: this._cfg.textDecoration,
                fontInfo: {
                    fontSize: this._cfg.fontSize,
                    fontFamily: this._cfg.fontFamily,
                    fontStyle: this._cfg.fontStyle,
                    fontWeight: this._cfg.fontWeight
                },
                color: this._cfg.color,
                lineHeight: this._cfg.lineHeight
            }
        };
        var w = this._paddingBorderSize()[0];
        if (this.minWidth > 0)
            options.minWidth = this.minWidth - w;
        if (this.maxWidth > 0)
            options.maxWidth = this.maxWidth - w;
        return options;
    };
    FLabel.prototype._createInset = function (seg) {
        if (!this._insetCache)
            this._insetCache = new Map();
        if (!this._insetCache.has(seg)) {
            var w_1 = this.insetCreator(seg.inset, seg.rect);
            if (w_1)
                this._insetCache.set(seg, w_1);
        }
        var w = this._insetCache.get(seg);
        if (w.parent() !== this)
            w.setParent(this);
    };
    FLabel.prototype._validWidth = function (width) {
        if (this.maxWidth > 0)
            width = Math.min(this.maxWidth, width);
        if (this.minWidth > 0)
            width = Math.max(this.minWidth, width);
        return width;
    };
    FLabel.prototype._validHeight = function (height) {
        if (this.maxHeight > 0)
            height = Math.min(this.maxHeight, height);
        if (this.minHeight > 0)
            height = Math.max(this.minHeight, height);
        return height;
    };
    FLabel.prototype._paddingBorderSize = function () {
        var width = 0;
        var height = 0;
        if (this._cfg.border) {
            var border = core.QuaterSplit(this._cfg.border, { width: 0, color: '' });
            width += border[1].width + border[3].width;
            height += border[0].width + border[2].width;
        }
        if (this._cfg.padding) {
            var padding = core.QuaterSplit(this._cfg.padding, 0);
            width += padding[1] + padding[3];
            height += padding[0] + padding[2];
        }
        return [width, height];
    };
    return FLabel;
}(core.FWidget));

(function (WdkFvgType) {
    WdkFvgType["image"] = "wdk/image";
    WdkFvgType["label"] = "wdk/label";
    WdkFvgType["document"] = "wdk/document";
})(exports.WdkFvgType || (exports.WdkFvgType = {}));
var FVGWdkConstructor = /** @class */ (function () {
    function FVGWdkConstructor() {
    }
    FVGWdkConstructor.prototype.constructWidget = function (node) {
        var w = null;
        if (node.type === exports.WdkFvgType.image) {
            w = new FImage(null);
            w.updateByCfg(node.cfg);
        }
        else if (node.type === exports.WdkFvgType.label) {
            w = new FLabel(null);
            w.updateByCfg(node.cfg);
        }
        else if (node.type === exports.WdkFvgType.document) {
            var docNode = node;
            w = new core.FWidget(null);
            w.updateByCfg(node.cfg);
            docNode.styles.forEach(function (node) {
                var c = new core.FWidget(w);
                c.updateByCfg(__assign({}, node.rect));
                c.updateByCfg(node.style);
            });
        }
        return w;
    };
    return FVGWdkConstructor;
}());

(function (FDocCustomEvent) {
    FDocCustomEvent[FDocCustomEvent["MarkDirty"] = core.CustomEventStart] = "MarkDirty";
})(exports.FDocCustomEvent || (exports.FDocCustomEvent = {}));
var FDocDirtyEvent = /** @class */ (function (_super) {
    __extends(FDocDirtyEvent, _super);
    function FDocDirtyEvent(target, area) {
        var _this = _super.call(this, exports.FDocCustomEvent.MarkDirty, target) || this;
        _this._area = area.clone();
        return _this;
    }
    FDocDirtyEvent.prototype.dirtyArea = function () {
        return this._area;
    };
    return FDocDirtyEvent;
}(core.FEvent));
var FDocument = /** @class */ (function (_super) {
    __extends(FDocument, _super);
    function FDocument(p, model) {
        var _this = _super.call(this, p) || this;
        _this._model = null;
        _this._cacheRows = 64;
        _this._cacheCols = 32;
        _this._rowsInfo = [];
        _this._colsInfo = [];
        _this._cells = [];
        _this._overCells = new Map();
        _this._refToPull = new Map();
        if (model !== null)
            _this.setModel(model);
        return _this;
    }
    FDocument.prototype.setModel = function (model) {
        this._model = model;
        this.reset();
        this.updateByCfg(this.docSize());
    };
    FDocument.prototype.docSize = function () {
        if (this._model) {
            var width = this._model.width();
            var height = this._model.height();
            if (width === -1)
                width = this._hintWidth();
            if (height === -1)
                height = this._hintHeight();
            return { width: width, height: height };
        }
        else {
            return { width: 0, height: 0 };
        }
    };
    FDocument.prototype.reset = function () {
        this._rowsInfo.length = 0;
        this._colsInfo.length = 0;
        this._cells.forEach(function (row) { return row.forEach(function (cell) {
            if (cell.content != null)
                cell.content.destroy();
        }); });
        this._cells.length = 0;
        this._overCells.forEach(function (w) { return w.destroy(); });
        this._overCells.clear();
    };
    FDocument.prototype.loadDocArea = function (area) {
        var _this = this;
        if (this._model == null)
            return;
        var size = this.docSize();
        if (size.width <= 0 || size.height <= 0)
            return;
        area.x = Math.max(area.x, 0);
        area.y = Math.max(area.y, 0);
        if (area.isEmpty())
            return;
        var oloadRect = this._loadedRect();
        if (oloadRect.containRect(area))
            return;
        else if (!area.intersect(oloadRect))
            this.reset();
        var fromRow = this.measureRow(0, 0, area.y);
        var model = this._model;
        if (!model.hasRow(fromRow.row))
            return;
        var fromCol = this.measureCol(0, 0, area.x);
        if (!model.hasCol(fromCol.col))
            return;
        var toRow = this.measureRow(fromRow.row, fromRow.pos, area.y + area.height - fromRow.pos);
        var toCol = this.measureCol(fromCol.col, fromCol.pos, area.x + area.width - fromCol.pos);
        var needLoadRows = [];
        var rInfo = this._rowsInfo;
        if (rInfo.length > 0) {
            var lrf = rInfo[0];
            if (fromRow.row < lrf.idx) {
                needLoadRows.push({ from: fromRow.row, offset: fromRow.pos, to: lrf.idx - 1 });
            }
            var lrt = rInfo[rInfo.length - 1];
            if (toRow.row > lrt.idx) {
                needLoadRows.push({ from: lrt.idx + 1, offset: lrt.pos + lrt.size, to: toRow.row });
            }
        }
        else {
            needLoadRows.push({ from: fromRow.row, offset: fromRow.pos, to: toRow.row });
        }
        var needLoadCols = [];
        var cInfo = this._colsInfo;
        if (cInfo.length > 0) {
            var lcf = cInfo[0];
            if (fromCol.col < lcf.idx) {
                needLoadCols.push({ from: fromCol.col, offset: fromCol.pos, to: lcf.idx - 1 });
            }
            var lct = cInfo[cInfo.length - 1];
            if (toCol.col > lct.idx) {
                needLoadCols.push({ from: lct.idx + 1, offset: lct.pos + lct.size, to: toCol.col });
            }
        }
        else {
            needLoadCols.push({ from: fromCol.col, offset: fromCol.pos, to: toCol.col });
        }
        // load row col info
        needLoadRows.forEach(function (seg) {
            _this._loadRowsInfo(seg.from, seg.offset, seg.to);
            rInfo = _this._rowsInfo;
            if (cInfo.length > 0) {
                _this._loadCells(seg.from, seg.to, cInfo[0].idx, cInfo[cInfo.length - 1].idx);
            }
        });
        needLoadCols.forEach(function (seg) {
            _this._loadColsInfo(seg.from, seg.offset, seg.to);
            cInfo = _this._colsInfo;
            if (rInfo.length > 0) {
                _this._loadCells(rInfo[0].idx, rInfo[rInfo.length - 1].idx, seg.from, seg.to);
            }
        });
        if (rInfo.length > this._cacheRows) {
            var mid = Math.floor(rInfo.length / 2) + rInfo[0].idx;
            if (fromRow.row > rInfo[0].idx) {
                this._removeRows(rInfo[0].idx, Math.min(fromRow.row - 1, mid));
            }
            else if (rInfo[rInfo.length - 1].idx > toRow.row) {
                this._removeRows(Math.max(toRow.row + 1, mid), rInfo[rInfo.length - 1].idx);
            }
        }
        if (cInfo.length > this._cacheCols) {
            var mid = Math.floor(cInfo.length / 2) + cInfo[0].idx;
            if (fromCol.col > cInfo[0].idx) {
                this._removeCols(cInfo[0].idx, Math.min(fromCol.col - 1, mid));
            }
            else if (cInfo[cInfo.length - 1].idx > toCol.col) {
                this._removeCols(Math.max(toCol.col + 1, mid), cInfo[cInfo.length - 1].idx);
            }
        }
        var loadedRect = this._loadedRect();
        // remove needn't overflow cells
        this._overCells.forEach(function (w, k) {
            var rect = w.paintedRect();
            if (!loadedRect.intersect(rect)) {
                w.destroy();
                _this._overCells.delete(k);
            }
        });
        // pull new cells
        this._pullRefCells();
        this.updateByCfg(this.docSize());
    };
    FDocument.prototype.cell2DocPos = function (cell) {
        var x = this.measureWidth(0, cell.col);
        var y = this.measureHeight(0, cell.row);
        return new core.FPoint(x, y);
    };
    FDocument.prototype.docPos2Cell = function (pos) {
        return {
            col: this.measureCol(0, 0, pos.x).col,
            row: this.measureRow(0, 0, pos.y).row
        };
    };
    FDocument.prototype.measureCol = function (fromCol, fromColPos, width) {
        var sum = 0;
        var col = fromCol;
        var model = this._model;
        while (model.hasCol(col) && sum < width) {
            var _a = model.colWidth(col), blockSize = _a[0], count = _a[1];
            var part = blockSize * count;
            if (sum + part > width) {
                count = Math.floor((width - sum) / blockSize);
                sum += blockSize * count;
                col += count;
                break;
            }
            else {
                sum += part;
                col += count;
            }
        }
        if (!model.hasCol(col) && col > 0)
            col -= 1;
        return { col: col, pos: sum + fromColPos };
    };
    FDocument.prototype.measureRow = function (fromRow, fromRowPos, height) {
        var sum = 0;
        var row = fromRow;
        var model = this._model;
        while (model.hasRow(row) && sum < height) {
            var _a = model.rowHeight(row), blockSize = _a[0], count = _a[1];
            var part = blockSize * count;
            if (sum + part > height) {
                count = Math.floor((height - sum) / blockSize);
                sum += blockSize * count;
                row += count;
                break;
            }
            else {
                sum += part;
                row += count;
            }
        }
        if (!model.hasRow(row) && row > 0)
            row -= 1;
        return { row: row, pos: sum + fromRowPos };
    };
    FDocument.prototype.measureWidth = function (fromCol, toCol) {
        var model = this._model;
        var sum = 0;
        while (model.hasCol(fromCol) && fromCol < toCol) {
            var _a = model.colWidth(fromCol), size = _a[0], count = _a[1];
            var bc = Math.min(count, toCol - fromCol);
            sum += size * bc;
            fromCol += bc;
        }
        return sum;
    };
    FDocument.prototype.measureHeight = function (fromRow, toRow) {
        var model = this._model;
        var sum = 0;
        while (model.hasRow(fromRow) && fromRow < toRow) {
            var _a = model.rowHeight(fromRow), size = _a[0], count = _a[1];
            var bc = Math.min(count, toRow - fromRow);
            sum += size * bc;
            fromRow += bc;
        }
        return sum;
    };
    FDocument.prototype._loadedRect = function () {
        var rect = new core.FRect();
        var rows = this._rowsInfo.length;
        if (rows > 0) {
            var firstRow = this._rowsInfo[0];
            var lastRow = this._rowsInfo[rows - 1];
            rect.y = firstRow.pos;
            rect.height = lastRow.pos + lastRow.size - firstRow.pos;
        }
        var cols = this._colsInfo.length;
        if (cols > 0) {
            var firstCol = this._colsInfo[0];
            var lastCol = this._colsInfo[cols - 1];
            rect.x = firstCol.pos;
            rect.width = lastCol.pos + lastCol.size - firstCol.pos;
        }
        return rect;
    };
    FDocument.prototype.markDirtyRect = function (rect) {
        core.ListenersControl.sendEvent(this, new FDocDirtyEvent(this, rect));
        _super.prototype.markDirtyRect.call(this, rect);
    };
    FDocument.prototype.fvgNode = function () {
        var rInfos = this._rowsInfo;
        var cInfos = this._colsInfo;
        var style = {
            type: exports.WdkFvgType.document,
            cfg: _super.prototype.fvgNode.call(this).cfg,
            styles: []
        };
        if (rInfos.length === 0 || cInfos.length === 0)
            return style;
        var rect = this.paintedRect().move(-this.x, -this.y);
        var p = this.parent();
        if (p !== null) {
            var prect = p.paintedRect();
            rect.intersectRect(new core.FRect(-this.x, -this.y, prect.width, prect.height));
            if (rect.isEmpty())
                return style;
        }
        var rf = this._forceFindRowColIndexByPos(rInfos, rect.y);
        var rt = this._forceFindRowColIndexByPos(rInfos, rect.y + rect.height);
        var cf = this._forceFindRowColIndexByPos(cInfos, rect.x);
        var ct = this._forceFindRowColIndexByPos(cInfos, rect.x + rect.width);
        for (var r = rf; r <= rt; r++) {
            var rowInfo = rInfos[r];
            for (var c = cf; c <= ct; c++) {
                var cell = this._cells[r][c];
                if (cell.style === null)
                    continue;
                var colInfo = cInfos[c];
                style.styles.push({
                    rect: { x: colInfo.pos, y: rowInfo.pos, width: colInfo.size, height: rowInfo.size },
                    style: cell.style
                });
            }
        }
        return style;
    };
    FDocument.prototype.renderWidget = function (ctx, paintRect) {
        var _this = this;
        var rInfos = this._rowsInfo;
        var cInfos = this._colsInfo;
        if (rInfos.length === 0 || cInfos.length === 0)
            return;
        var _a = this._cfg, x = _a.x, y = _a.y;
        // translate to self axis
        var docRect = paintRect.clone().move(-x, -y);
        var rf = this._forceFindRowColIndexByPos(rInfos, docRect.y);
        var rt = this._forceFindRowColIndexByPos(rInfos, docRect.y + docRect.height);
        var cf = this._forceFindRowColIndexByPos(cInfos, docRect.x);
        var ct = this._forceFindRowColIndexByPos(cInfos, docRect.x + docRect.width);
        var iterCellStyle = function (cb) {
            for (var r = rf; r <= rt; r++) {
                var rowInfo = rInfos[r];
                for (var c = cf; c <= ct; c++) {
                    var cell = _this._cells[r][c];
                    if (cell.style === null)
                        continue;
                    var colInfo = cInfos[c];
                    var cellRect = new core.FRect(colInfo.pos, rowInfo.pos, colInfo.size, rowInfo.size);
                    var rect = docRect.clone().intersectRect(cellRect);
                    if (rect.isEmpty())
                        continue;
                    cb(cellRect, rect, cell.style);
                }
            }
        };
        ctx.save();
        ctx.translate(x, y);
        // todo: paint row style
        // todo: paint col style
        // paint cell style background
        iterCellStyle(function (_cellRect, rect, style) {
            var background = style.background;
            if (background !== undefined) {
                ctx.beginPath();
                ctx.rect(rect);
                if (ctx.fillStyle !== background) {
                    ctx.fillStyle = background;
                }
                ctx.fill();
            }
        });
        ctx.beginPath();
        // paint cell style border
        iterCellStyle(function (cellRect, rect, style) {
            var drawLine = function (x1, y1, x2, y2, border) {
                if (border.width <= 0 && border.color === background)
                    return;
                ctx.strokeStyle = border.color;
                ctx.lineWidth = border.width;
                ctx.drawLine(x1, y1, x2, y2);
            };
            var background = style.background, border = style.border, borderBottom = style.borderBottom, borderLeft = style.borderLeft, borderRight = style.borderRight, borderTop = style.borderTop;
            var _a = core.QuaterSplit(border, { width: 0, color: '' }, borderTop, borderRight, borderBottom, borderLeft), top = _a[0], right = _a[1], bottom = _a[2], left = _a[3];
            var lWidth = left.width;
            var rWidth = right.width;
            var tWidth = top.width;
            var bWidth = bottom.width;
            var x = cellRect.x, y = cellRect.y, width = cellRect.width, height = cellRect.height;
            /**
             * ===========================||
             * || Line border below       ||
             * ||                         ||
             * ||===========================
             */
            if (tWidth > 0) {
                var brect = new core.FRect(x, y, width, tWidth);
                var drawArea = brect.intersectRect(brect);
                if (!drawArea.isEmpty()) {
                    drawLine(drawArea.x, y, drawArea.x + drawArea.width, y, top);
                }
            }
            if (rWidth > 0) {
                var brect = new core.FRect(x + width - rWidth, y, rWidth, height);
                var drawArea = brect.intersectRect(brect);
                if (!drawArea.isEmpty()) {
                    var xPos = ctx.xDeviceRound(drawArea.x + right.width) - right.width;
                    drawLine(xPos, drawArea.y, xPos, drawArea.y + drawArea.height, right);
                }
            }
            if (bWidth > 0) {
                var brect = new core.FRect(x, y + height - bWidth, width, bWidth);
                var drawArea = brect.intersectRect(brect);
                if (!drawArea.isEmpty()) {
                    var yPos = ctx.yDeviceRound(drawArea.y + bottom.width) - bottom.width;
                    drawLine(drawArea.x, yPos, drawArea.x + drawArea.width, yPos, bottom);
                }
            }
            if (lWidth > 0) {
                var brect = new core.FRect(x, y, lWidth, height);
                var drawArea = brect.intersectRect(brect);
                if (!drawArea.isEmpty()) {
                    drawLine(x, drawArea.y, x, drawArea.y + drawArea.height, left);
                }
            }
        });
        ctx.restore();
    };
    FDocument.prototype._loadCells = function (fromRow, toRow, fromCol, toCol) {
        var _this = this;
        var model = this._model;
        var rInfo = this._rowsInfo;
        var cInfo = this._colsInfo;
        var rBase = rInfo.length > 0 ? rInfo[0].idx : fromRow;
        var cBase = cInfo.length > 0 ? cInfo[0].idx : fromCol;
        for (var row = fromRow; row <= toRow; row++) {
            var y = rInfo[row - rBase].pos;
            var wRowInfo = this._cells[row - rBase];
            var newCells = new Array(toCol - fromCol + 1);
            var _loop_1 = function (col) {
                var cellInfo = null;
                var key = this_1._cellHash(row, col);
                // if this cell is over flow cell, transplant from overcells
                if (this_1._overCells.has(key)) {
                    cellInfo = this_1._overCells.get(key);
                    this_1._overCells.delete(key);
                }
                else {
                    cellInfo = model.cellWidget(row, col);
                    if (cellInfo instanceof core.FWidget) {
                        var x = cInfo[col - cBase].pos + cellInfo.x;
                        cellInfo.updateByCfg({ x: x, y: y + cellInfo.y });
                        this_1.addChild(cellInfo);
                    }
                    else if (cellInfo !== null) {
                        cellInfo.forEach(function (cell) {
                            _this._refToPull.set(key, cell);
                        });
                        cellInfo = null;
                    }
                }
                var style = model.cellStyle(row, col);
                newCells[col - fromCol] = { style: style, content: cellInfo };
            };
            var this_1 = this;
            for (var col = fromCol; col <= toCol; col++) {
                _loop_1(col);
            }
            wRowInfo.splice.apply(wRowInfo, [fromCol - cBase, 0].concat(newCells));
        }
    };
    FDocument.prototype._loadRowsInfo = function (fromRow, fromRowPos, toRow) {
        if (fromRow > toRow)
            return;
        var model = this._model;
        var rInfo = this._rowsInfo;
        var newInfos = new Array(toRow - fromRow + 1);
        var newRows = new Array(toRow - fromRow + 1);
        var pos = fromRowPos;
        for (var row = fromRow; row < toRow + 1; row++) {
            var style = model.rowStyle(row);
            var size = model.rowHeight(row)[0];
            var rowInfo = { style: style, idx: row, pos: pos, size: size };
            newInfos[row - fromRow] = rowInfo;
            newRows[row - fromRow] = [];
            pos += size;
        }
        var rBase = rInfo.length > 0 ? rInfo[0].idx : 0;
        var fidx = Math.max(0, fromRow - rBase);
        var cells = this._cells;
        this._rowsInfo = this._arrayInsert(rInfo, newInfos, fidx);
        this._cells = this._arrayInsert(cells, newRows, fidx);
    };
    FDocument.prototype._arrayInsert = function (arr, insertArr, insert) {
        var beforeArr = arr.slice(0, insert);
        var afterArr = arr.slice(insert);
        var comArr = beforeArr.concat(insertArr).concat(afterArr);
        return comArr;
    };
    FDocument.prototype._loadColsInfo = function (fromCol, fromColPos, toCol) {
        if (fromCol > toCol)
            return;
        var model = this._model;
        var cInfo = this._colsInfo;
        // load col infos
        var pos = fromColPos;
        var newInfos = new Array(toCol - fromCol + 1);
        for (var col = fromCol; col < toCol + 1; col++) {
            var style = model.colStyle(col);
            var size = model.colWidth(col)[0];
            var colInfo = { style: style, idx: col, pos: pos, size: size };
            newInfos[col - fromCol] = colInfo;
            pos += size;
        }
        var cBase = cInfo.length > 0 ? cInfo[0].idx : 0;
        var fidx = Math.max(fromCol - cBase, 0);
        this._colsInfo = this._arrayInsert(cInfo, newInfos, fidx);
    };
    FDocument.prototype._forceFindRowColIndexByPos = function (info, pos) {
        var idx = this._findRowColIndexByPos(info, pos);
        if (idx === -1) {
            if (info.length === 0) {
                idx = 0;
            }
            else {
                if (pos < info[0].pos)
                    idx = 0;
                else
                    idx = info.length - 1;
            }
        }
        return idx;
    };
    FDocument.prototype._findRowColIndexByPos = function (info, pos) {
        return core.findInSorted(info, function (v) {
            if (pos < v.pos)
                return core.CompareRes.Less;
            else if (v.pos + v.size < pos)
                return core.CompareRes.Greater;
            else
                return core.CompareRes.Equal;
        });
    };
    FDocument.prototype._removeCols = function (fromCol, toCol) {
        var fIdx = fromCol - this._colsInfo[0].idx;
        var tIdx = toCol - this._colsInfo[0].idx;
        if (fIdx !== 0 && tIdx !== this._colsInfo.length - 1) {
            console.error('cols can not be interrupted');
            return;
        }
        this._removeCells(0, this._rowsInfo.length - 1, fIdx, tIdx);
        this._colsInfo.splice(fIdx, tIdx - fIdx + 1);
    };
    FDocument.prototype._removeRows = function (fromRow, toRow) {
        var fIdx = fromRow - this._rowsInfo[0].idx;
        var tIdx = toRow - this._rowsInfo[0].idx;
        var rows = this._cells;
        if (fIdx !== 0 && tIdx !== this._rowsInfo.length - 1) {
            console.error('rows can not be interrupted');
            return;
        }
        this._removeCells(fIdx, tIdx, 0, this._colsInfo.length - 1);
        rows.splice(fIdx, tIdx - fIdx + 1);
        this._rowsInfo.splice(fIdx, tIdx - fIdx + 1);
    };
    FDocument.prototype._removeCells = function (fromRowIdx, toRowIdx, fromColIdx, toColidx) {
        for (var r = fromRowIdx; r <= toRowIdx; r++) {
            var rInfo = this._rowsInfo[r];
            var row = this._cells[r];
            for (var c = fromColIdx; c <= toColidx; c++) {
                var cWidget = row[c].content;
                if (cWidget != null) {
                    var wRect = cWidget.paintedRect();
                    var cInfo = this._colsInfo[c];
                    var cellRect = new core.FRect(cInfo.pos, rInfo.pos, cInfo.size, rInfo.size);
                    if (!cellRect.containRect(wRect)) {
                        this._overCells.set(this._cellHash(rInfo.idx, cInfo.idx), cWidget);
                    }
                    else {
                        cWidget.destroy();
                    }
                }
            }
            row.splice(fromColIdx, toColidx - fromColIdx + 1);
        }
    };
    FDocument.prototype._hintWidth = function () {
        var cInfo = this._colsInfo;
        if (cInfo.length > 0) {
            var last = cInfo[cInfo.length - 1];
            var hasMore = this._model.hasCol(last.idx + 1);
            var scrollSpace = hasMore ? last.size * 2 : 0;
            return last.pos + last.size + scrollSpace;
        }
        else if (this._model.hasCol(0)) {
            return Number.MAX_VALUE;
        }
        else {
            return 0;
        }
    };
    FDocument.prototype._hintHeight = function () {
        var rInfo = this._rowsInfo;
        if (rInfo.length > 0) {
            var last = rInfo[rInfo.length - 1];
            var hasMore = this._model.hasRow(last.idx + 1);
            var scrollSpace = hasMore ? last.size * 2 : 0;
            return last.pos + last.size + scrollSpace;
        }
        else if (this._model.hasRow(0)) {
            return Number.MAX_VALUE;
        }
        else {
            return 0;
        }
    };
    FDocument.prototype._cellHash = function (row, col) {
        return row + "_" + col;
    };
    FDocument.prototype._pullRefCells = function () {
        var _this = this;
        if (this._refToPull.size === 0)
            return;
        var rf = -1;
        var rt = -1;
        var cf = -1;
        var ct = -1;
        var rInfo = this._rowsInfo;
        if (rInfo.length > 0) {
            rf = rInfo[0].idx;
            rt = rInfo[rInfo.length - 1].idx;
        }
        var cInfo = this._colsInfo;
        if (cInfo.length > 0) {
            cf = cInfo[0].idx;
            ct = cInfo[cInfo.length - 1].idx;
        }
        this._refToPull.forEach(function (c) {
            if (c.row < rf || rt < c.row || c.col < cf || ct < c.col) {
                var key = _this._cellHash(c.row, c.col);
                if (_this._overCells.has(key))
                    return;
                var w = _this._model.cellWidget(c.row, c.col);
                if (w instanceof core.FWidget) {
                    var x = _this.measureWidth(0, c.col) + w.x;
                    var y = _this.measureHeight(0, c.row) + w.y;
                    w.updateByCfg({ x: x, y: y });
                    _this._overCells.set(key, w);
                    _this.addChild(w);
                }
                else {
                    console.error("Some wrong in model, some cell ref to cell(" + c.row + ", " + c.col + "),\n           but cell(" + c.row + ", " + c.col + ") not return a widget");
                }
            }
        });
        this._refToPull.clear();
    };
    return FDocument;
}(core.FWidget));

var tan30 = Math.tan(Math.PI * 30 / 180);
var tan60 = 1 / tan30;
var FDocView = /** @class */ (function (_super) {
    __extends(FDocView, _super);
    function FDocView(p, model) {
        var _this = _super.call(this, p) || this;
        // the doc area buffered in buffer screen.
        _this._bufferedArea = new core.FRect();
        _this._bufferScreen = null;
        _this._swapScreen = null;
        _this._bufferZone = 100;
        _this._bufferWnd = new core.FRect();
        _this._dirtyBuffer = new core.FRect();
        _this._startPanAnchor = new core.FPoint(0, 0);
        _this._panDirection = 'x';
        _this.animateId = 0;
        _this._ignoreBuffer = false;
        _this._doc = new FDocument(_this, model);
        core.Bind.propBind(_this._doc, 'x', _this, 'posX', function (v) { return -v; });
        core.Bind.propBind(_this._doc, 'y', _this, 'posY', function (v) { return -v; });
        core.Bind.propBind(_this, 'posX', _this._doc, 'x', function (v) { return -v; });
        core.Bind.propBind(_this, 'posY', _this._doc, 'y', function (v) { return -v; });
        _this._doc.addListener(exports.FDocCustomEvent.MarkDirty, function (e) {
            var de = e;
            var nDirty = de.dirtyArea().intersectRect(_this._bufferedArea);
            _this._dirtyBuffer.union(nDirty);
            return false;
        });
        return _this;
    }
    Object.defineProperty(FDocView.prototype, "posY", {
        get: function () {
            return this._cleanProp('posY');
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FDocView.prototype, "posX", {
        get: function () {
            return this._cleanProp('posX');
        },
        enumerable: true,
        configurable: true
    });
    FDocView.prototype.doc2View = function (docPos) {
        docPos.move(-this.posX, -this.posY);
        return docPos;
    };
    FDocView.prototype.view2Doc = function (pos) {
        pos.move(this.posX, this.posY);
        return pos;
    };
    FDocView.prototype.cell2DocPos = function (cell) {
        return this._doc.cell2DocPos(cell);
    };
    FDocView.prototype.docPos2Cell = function (pos) {
        return this._doc.docPos2Cell(pos);
    };
    FDocView.prototype.setModel = function (model) {
        this._doc.setModel(model);
        this.reset();
    };
    FDocView.prototype.panStart = function (e) {
        core.FApp.removeIdleListener(this.animateId);
        if (Math.abs(e.deltaX) >= Math.abs(e.deltaY)) {
            this._panDirection = 'x';
        }
        else {
            this._panDirection = 'y';
        }
        return this.panMove(e);
    };
    FDocView.prototype.panMove = function (e) {
        var start = this._startPanAnchor;
        var docSize = this._doc.docSize();
        var deltaX = start.x - e.deltaX;
        var deltaY = start.y - e.deltaY;
        var _a = this, posX = _a.posX, posY = _a.posY;
        var overBoundary;
        if (this._panDirection === 'x') {
            overBoundary = (posX <= 0 && deltaX < 0)
                || (posX >= docSize.width - this.width && deltaX > 0);
        }
        else {
            overBoundary = (posY <= 0 && deltaY < 0)
                || (posY >= docSize.height - this.height && deltaY > 0);
        }
        if (!overBoundary) {
            this._wheelStep(deltaX, deltaY);
            this._startPanAnchor = new core.FPoint(e.deltaX, e.deltaY);
            e.preventDefault();
        }
        return false;
    };
    FDocView.prototype.panEnd = function (e) {
        this._startPanAnchor = new core.FPoint(0, 0);
        return false;
    };
    FDocView.prototype.swipe = function (e) {
        var vx = e.velocityX;
        var vy = e.velocityY;
        var t = Math.abs(vy) / Math.abs(vx);
        if (t > tan60) {
            vx = 0;
        }
        else if (t < tan30) {
            vy = 0;
        }
        this.inertia(Date.now(), vx, vy);
        return false;
    };
    FDocView.prototype.inertia = function (t, vx, vy) {
        var _this = this;
        var friction = 0.95;
        this.animateId = core.FApp.addIdleListener(function () {
            var now = Date.now();
            var dt = now - t;
            var stopped = true;
            var f = Math.pow(friction, dt / 16);
            var newVx = f * vx;
            var newVy = f * vy;
            var dx = 0;
            var dy = 0;
            if (Math.abs(newVx) > 0.05) {
                stopped = false;
                dx = (vx + newVx) / 2 * dt;
            }
            if (Math.abs(newVy) > 0.05) {
                stopped = false;
                dy = (vy + newVy) / 2 * dt;
            }
            _this._wheelStep(-dx, -dy);
            if (stopped) {
                core.FApp.removeIdleListener(_this.animateId);
            }
            else {
                t = now;
                vx = newVx;
                vy = newVy;
            }
        });
    };
    FDocView.prototype.mouseWheel = function (e) {
        this._wheelStep(e.deltaX, e.deltaY);
        return false;
    };
    FDocView.prototype.reset = function () {
        this._doc.reset();
        this._bufferedArea.reset();
        this._bufferWnd.reset();
        this._dirtyBuffer.reset();
        var bs = this._bufferScreen;
        if (bs !== null) {
            bs.ctx().clearRect(new core.FRect(0, 0, bs.width(), bs.height()));
        }
        this.detectLifetimeOnce();
    };
    FDocView.prototype.docSize = function () {
        return this._doc.docSize();
    };
    FDocView.prototype.renderWidget = function (ctx, dirtyArea) {
        var _this = this;
        _super.prototype.renderWidget.call(this, ctx, dirtyArea);
        if (!this._needBuff())
            return;
        this._buffScreenReady(ctx);
        this._fixBuffer();
        var wnd = this._bufferWnd;
        var _a = this._cfg, x = _a.x, y = _a.y, posX = _a.posX, posY = _a.posY;
        // translate to self axis
        var docRect = dirtyArea.clone().move(-x, -y);
        // translate to doc axis
        docRect.move(posX, posY).intersectRect(wnd);
        if (docRect.isEmpty())
            return;
        dirtyArea = docRect.clone().move(-posX, -posY).move(x, y);
        var offscreen = this._bufferScreen;
        var buffCtx = offscreen.ctx();
        // round doc area pixel by offscreen device
        docRect.move(-wnd.x, -wnd.y);
        var dDocRect = buffCtx.logic2DeviceRect(docRect).rounds();
        docRect = buffCtx.deviceRect2Logic(dDocRect.clone());
        docRect.move(wnd.x, wnd.y);
        // an new dirty area that devicel pxiel calibrated.
        var nDirtyArea = docRect.move(x - posX, y - posY);
        var dDirtyArea = ctx.logic2DeviceRect(dirtyArea.clone()).rounds();
        var ndDirtyArea = ctx.logic2DeviceRect(nDirtyArea).rounds();
        // let dirty area full cover doc rect on device pixel.
        dDocRect.x += dDirtyArea.x - ndDirtyArea.x;
        dDocRect.y += dDirtyArea.y - ndDirtyArea.y;
        dDocRect.width = dDirtyArea.width;
        dDocRect.height = dDirtyArea.height;
        docRect = buffCtx.deviceRect2Logic(dDocRect).move(wnd.x, wnd.y);
        if (!this._bufferedArea.equal(wnd)) {
            var toPaints = wnd.sub(this._bufferedArea);
            buffCtx.save();
            buffCtx.translate(posX - wnd.x, posY - wnd.y);
            toPaints.forEach(function (paintRect) {
                // translate to doc view axis
                paintRect.move(-posX, -posY);
                _this._doc.paint(buffCtx, paintRect);
            });
            buffCtx.restore();
            this._bufferedArea = wnd.clone();
        }
        var buffRect = docRect.clone().move(-wnd.x, -wnd.y);
        dirtyArea = ctx.deviceRect2Logic(dDirtyArea);
        ctx.drawImage(offscreen, dirtyArea, buffRect);
    };
    FDocView.prototype.destroy = function () {
        _super.prototype.destroy.call(this);
        if (this._bufferScreen) {
            core.FCanvasPool.backCanvas(this._bufferScreen);
            this._bufferScreen = null;
        }
        if (this._swapScreen) {
            core.FCanvasPool.backCanvas(this._swapScreen);
            this._swapScreen = null;
        }
    };
    FDocView.prototype._isChildNeedPaint = function (w, dirtyArea) {
        if (w === this._doc && this._needBuff())
            return false;
        else
            return _super.prototype._isChildNeedPaint.call(this, w, dirtyArea);
    };
    FDocView.prototype.afterFlush = function (e) {
        if (!this._bufferedArea.isEmpty()
            && ('width' in e.changes || 'height' in e.changes)) {
            this._bufferedArea.reset();
        }
        var changes = e.changes;
        var keys = Object.keys(changes);
        if (keys.length === 2 && changes['docHeight'] && changes['docWidth']) {
            var _a = this.validatePos(this.posX, this.posY), posX = _a[0], posY = _a[1];
            var changes_1 = {};
            if (posX !== this.posX)
                Object.assign(changes_1, { posX: posX });
            if (posY !== this.posY)
                Object.assign(changes_1, { posY: posY });
            this.updateByCfg(changes_1);
            return;
        }
        var docRect = this.rect.move(-this.x, -this.y);
        docRect.move(this.posX, this.posY);
        this._letBuffWndContain(docRect);
        this._doc.loadDocArea(this._bufferWnd);
        // buffer window should always contain in doc.
        this._bufferWnd.intersectRect(new core.FRect(0, 0, this._doc.width, this._doc.height));
        var docSize = this._doc.docSize();
        this.updateByCfg({
            docHeight: docSize.height,
            docWidth: docSize.width,
        });
    };
    FDocView.prototype.beforeChange = function (e) {
        var posXChg = e.changes.posX;
        var posYChg = e.changes.posY;
        if (posXChg !== undefined || posYChg !== undefined) {
            var _a = this.validatePos(posXChg ? posXChg.current : this.posX, posYChg ? posYChg.current : this.posY), posX = _a[0], posY = _a[1];
            if (posXChg !== undefined) {
                posXChg.current = posX;
            }
            if (posYChg !== undefined) {
                posYChg.current = posY;
            }
        }
        return false;
    };
    FDocView.prototype.validatePos = function (posX, posY) {
        var _a = this.docSize(), width = _a.width, height = _a.height;
        var scrollLeft = Math.max(0, Math.min(width - this.width, posX));
        var scrollTop = Math.max(0, Math.min(height - this.height, posY));
        return [scrollLeft, scrollTop];
    };
    FDocView.prototype._fixBuffer = function () {
        var dirtyBuff = this._dirtyBuffer;
        if (!dirtyBuff.isEmpty()) {
            var _a = this._cfg, posX = _a.posX, posY = _a.posY;
            var wnd = this._bufferWnd;
            var buffCtx = this._bufferScreen.ctx();
            buffCtx.save();
            // let bufferScreen and buffer window has same axis.
            buffCtx.translate(-wnd.x, -wnd.y);
            // clear dirty buffer
            buffCtx.clearRect(dirtyBuff);
            // translate the difference between buffer window & doc veiw axis.
            buffCtx.translate(posX, posY);
            // translate area to doc view area to paint child
            dirtyBuff.move(-posX, -posY);
            this._doc.paint(buffCtx, dirtyBuff);
            buffCtx.restore();
            dirtyBuff.reset();
        }
    };
    FDocView.prototype._wheelStep = function (deltaX, deltaY) {
        var stepX = this._wheelValidStep(deltaX);
        var setpY = this._wheelValidStep(deltaY);
        this.updateByCfg({ posY: this.posY + setpY, posX: this.posX + stepX });
    };
    FDocView.prototype._wheelValidStep = function (step) {
        var maxStep = 0.7 * this._bufferZone;
        if (step > maxStep)
            return maxStep;
        else if (step < -maxStep)
            return -maxStep;
        else
            return step;
    };
    FDocView.prototype._letBuffWndContain = function (rect) {
        var wnd = this._bufferWnd;
        if (!wnd.containRect(rect)) {
            var bz = this._bufferZone;
            if (rect.x + rect.width > wnd.x + wnd.width)
                wnd.x = rect.x;
            else if (rect.x < wnd.x)
                wnd.x = rect.x - bz;
            if (rect.y + rect.height > wnd.y + wnd.height)
                wnd.y = rect.y;
            else if (rect.y < wnd.y)
                wnd.y = rect.y - bz;
            wnd.width = rect.width + bz;
            wnd.height = rect.height + bz;
        }
    };
    /**
     * doublication of offscreen canvas to buffer window doublication, and keep `keepArea`.
     * @param keepArea
     */
    FDocView.prototype.doublicationOffScreenToBuffWnd = function (keepArea) {
        var rect = this._bufferedArea;
        var wnd = this._bufferWnd;
        if (rect.x === wnd.x && rect.y === wnd.y) {
            return keepArea;
        }
        else {
            var bscreen = this._bufferScreen;
            var ctx = bscreen.ctx();
            // calibrate wnd buff to device pixel
            ctx.logic2DeviceRect(wnd).boundary();
            ctx.deviceRect2Logic(wnd);
            var swapCtx = this._swapScreen.ctx();
            var oBuffview = new core.FRect(keepArea.x - rect.x, keepArea.y - rect.y, keepArea.width, keepArea.height);
            var t = ctx.getTransform();
            swapCtx.setTransform(t.a, t.b, t.c, t.d, t.e, t.f);
            this._swapScreen.clear();
            swapCtx.drawImage(bscreen, oBuffview, oBuffview);
            bscreen.clear();
            keepArea.move(-wnd.x, -wnd.y);
            var deviceDst = ctx.drawImage(this._swapScreen, keepArea, oBuffview);
            if (deviceDst instanceof core.FRect) {
                keepArea = ctx.deviceRect2Logic(deviceDst);
            }
            keepArea.move(wnd.x, wnd.y);
            return keepArea;
        }
    };
    FDocView.prototype._pickReusefulArea = function () {
        var reuseArea = this._bufferedArea.clone().intersectRect(this._bufferWnd);
        if (reuseArea.isEmpty()) {
            this._bufferedArea.reset();
            this._bufferScreen.clear();
        }
        else {
            this._bufferedArea = this.doublicationOffScreenToBuffWnd(reuseArea);
        }
    };
    FDocView.prototype._buffScreenReady = function (ctx) {
        var _this = this;
        if (this._bufferScreen == null) {
            var fx = core.Faster.findFaster(this);
            this._bufferScreen = core.FCanvasPool.borrowCanvas(fx, undefined, false);
            this._bufferScreen.fakeHide();
            this._bufferScreen.registerNotiry(function (t) {
                if (t === core.FCanvasNotify.Suspend || t === core.FCanvasNotify.Wakeup) {
                    _this._bufferedArea.reset();
                }
            });
            this._swapScreen = core.FCanvasPool.borrowCanvas(fx, undefined, false);
            this._swapScreen.fakeHide();
        }
        // if offscreen transfrom not same as major canvas, reset it.
        var bctx = this._bufferScreen.ctx();
        var bt = bctx.getTransform();
        var t = ctx.getTransform();
        if (bt.a !== t.a ||
            bt.b !== t.b ||
            bt.c !== t.c ||
            bt.d !== t.d) {
            this._bufferedArea.reset();
            bctx.setTransform(t.a, t.b, t.c, t.d, bt.e, bt.f);
            this._swapScreen.ctx().setTransform(t.a, t.b, t.c, t.d, bt.e, bt.f);
        }
        this._resizebuffScreen();
        this._pickReusefulArea();
    };
    FDocView.prototype._resizebuffScreen = function () {
        var bscreen = this._bufferScreen;
        var t = bscreen.ctx().getTransform();
        var wnd = this._bufferWnd;
        var width = Math.round(wnd.width * t.a);
        var height = Math.round(wnd.height * t.d);
        if (width > bscreen.width() || height > bscreen.height()) {
            var swapScreen = this._swapScreen;
            bscreen.resize(width, height);
            swapScreen.resize(width, height);
            bscreen.ctx().setTransform(t.a, t.b, t.c, t.d, t.e, t.f);
            swapScreen.ctx().setTransform(t.a, t.b, t.c, t.d, t.e, t.f);
            this._bufferedArea.reset();
        }
    };
    FDocView.prototype.setIgnoreBuffer = function (ignore) {
        this._ignoreBuffer = ignore;
    };
    FDocView.prototype._needBuff = function () {
        if (this._ignoreBuffer)
            return false;
        return this._doc.height > this.height
            || this._doc.width > this.width;
    };
    return FDocView;
}(core.FWidget));

var FScrollView = /** @class */ (function (_super) {
    __extends(FScrollView, _super);
    function FScrollView(p, model) {
        var _this = _super.call(this, p) || this;
        _this._doc = new FDocView(_this, null);
        if (model !== null)
            _this.setModel(model);
        core.Bind.propBind(_this._doc, 'width', _this, 'width');
        core.Bind.propBind(_this._doc, 'height', _this, 'height');
        return _this;
    }
    FScrollView.prototype.setModel = function (model) {
        var docModel = this._scrollModel2DocModel(model);
        this._doc.setModel(docModel);
    };
    FScrollView.prototype.doc = function () {
        return this._doc;
    };
    FScrollView.prototype._scrollModel2DocModel = function (model) {
        console.error('"_scrollModel2DocModel" must be implementd in dirive class.');
        return {};
    };
    return FScrollView;
}(core.FWidget));

var VScrollDocModel = /** @class */ (function () {
    function VScrollDocModel(_view, _model) {
        this._view = _view;
        this._model = _model;
    }
    VScrollDocModel.prototype.height = function () {
        return this._model.sumSize();
    };
    VScrollDocModel.prototype.width = function () {
        return this._view.width;
    };
    VScrollDocModel.prototype.rowHeight = function (row) {
        return this._model.blockSize(row);
    };
    VScrollDocModel.prototype.colWidth = function (col) {
        return [this._view.width, 1];
    };
    VScrollDocModel.prototype.hasRow = function (row) {
        return this._model.has(row);
    };
    VScrollDocModel.prototype.hasCol = function (col) {
        return col === 0;
    };
    VScrollDocModel.prototype.rowStyle = function (row) {
        return null;
    };
    VScrollDocModel.prototype.colStyle = function (col) {
        return null;
    };
    VScrollDocModel.prototype.cellStyle = function (row, col) {
        return this._model.blockStyle(row);
    };
    VScrollDocModel.prototype.cellWidget = function (row, col) {
        return this._model.contentWidget(row);
    };
    return VScrollDocModel;
}());
var FVScrollView = /** @class */ (function (_super) {
    __extends(FVScrollView, _super);
    function FVScrollView() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    FVScrollView.prototype._scrollModel2DocModel = function (model) {
        return new VScrollDocModel(this, model);
    };
    return FVScrollView;
}(FScrollView));

var HScrollDocModel = /** @class */ (function () {
    function HScrollDocModel(_view, _model) {
        this._view = _view;
        this._model = _model;
    }
    HScrollDocModel.prototype.height = function () {
        return this._view.height;
    };
    HScrollDocModel.prototype.width = function () {
        return this._model.sumSize();
    };
    HScrollDocModel.prototype.rowHeight = function (row) {
        return [this._view.height, 1];
    };
    HScrollDocModel.prototype.colWidth = function (col) {
        return this._model.blockSize(col);
    };
    HScrollDocModel.prototype.hasRow = function (row) {
        return row === 0;
    };
    HScrollDocModel.prototype.hasCol = function (col) {
        return this._model.has(col);
    };
    HScrollDocModel.prototype.rowStyle = function (row) {
        return null;
    };
    HScrollDocModel.prototype.colStyle = function (col) {
        return null;
    };
    HScrollDocModel.prototype.cellStyle = function (row, col) {
        return this._model.blockStyle(col);
    };
    HScrollDocModel.prototype.cellWidget = function (row, col) {
        return this._model.contentWidget(col);
    };
    return HScrollDocModel;
}());
var FHScrollView = /** @class */ (function (_super) {
    __extends(FHScrollView, _super);
    function FHScrollView() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    FHScrollView.prototype.setModel = function (model) {
        this._doc.setModel(new HScrollDocModel(this, model));
    };
    FHScrollView.prototype._scrollModel2DocModel = function (model) {
        return new HScrollDocModel(this, model);
    };
    return FHScrollView;
}(FScrollView));

(function (FRichTextEvent) {
    FRichTextEvent[FRichTextEvent["HoverChar"] = core.CustomEventStart] = "HoverChar";
})(exports.FRichTextEvent || (exports.FRichTextEvent = {}));
var HoverCharEvent = /** @class */ (function (_super) {
    __extends(HoverCharEvent, _super);
    function HoverCharEvent(target, charIdx, srcEvent) {
        var _this = _super.call(this, exports.FRichTextEvent.HoverChar, target) || this;
        _this.charIdx = charIdx;
        _this.srcEvent = srcEvent;
        return _this;
    }
    return HoverCharEvent;
}(core.FEvent));
var FRichText = /** @class */ (function (_super) {
    __extends(FRichText, _super);
    function FRichText(p) {
        return _super.call(this, p) || this;
    }
    FRichText.prototype.setStyle = function (from, to, style) {
        this._typher.stream().addStyleAttr({ rg: { from: from, to: to }, style: style });
        this.detectLifetimeOnce(true);
    };
    FRichText.prototype.addInset = function (inset) {
        this._typher.stream().addInset(inset);
        this.detectLifetimeOnce(true);
    };
    FRichText.prototype.mouseMove = function (e) {
        this._onMmouseMove(e);
        return _super.prototype.mouseMove.call(this, e);
    };
    FRichText.prototype.mouseEnter = function (e) {
        this._onMmouseMove(e);
        return _super.prototype.mouseEnter.call(this, e);
    };
    FRichText.prototype.mouseLeave = function (e) {
        core.ListenersControl.sendEvent(this, new HoverCharEvent(this, -1, e));
        return _super.prototype.mouseLeave.call(this, e);
    };
    FRichText.prototype._onMmouseMove = function (e) {
        if (e.target !== this)
            return;
        var pos = this.posHitChar(new core.FPoint(e.x, e.y));
        if (pos === -1)
            return;
        core.ListenersControl.sendEvent(this, new HoverCharEvent(this, pos, e));
        var attrs = this._typher.stream().styles();
        var idx = attrs.lbound({ rg: { from: pos, to: pos } }, true);
        if (idx === -1)
            return;
        var attr = attrs.at(idx);
        if (attr.rg.from <= pos && pos <= attr.rg.to) {
            var cursor = attr.style.cursor || 'default';
            this.updateByCfg({ cursor: cursor });
        }
        else {
            this.updateByCfg({ cursor: 'default' });
        }
    };
    return FRichText;
}(FLabel));

(function (FDimensionType) {
    FDimensionType[FDimensionType["Fr"] = 0] = "Fr";
    FDimensionType[FDimensionType["Pr"] = 1] = "Pr";
    FDimensionType[FDimensionType["Abs"] = 2] = "Abs";
})(exports.FDimensionType || (exports.FDimensionType = {}));
var Auto = 'auto';
function Fraction(value) {
    return { type: exports.FDimensionType.Fr, value: value };
}
function Percent(value) {
    return { type: exports.FDimensionType.Pr, value: value };
}
var FLayout = /** @class */ (function () {
    function FLayout() {
        var _this = this;
        this.inLayout = false;
        this.needLayout = false;
        // 对于孩子任何改变都不会影响容器大小的情况，应该停止向上传递layout请求。
        this.bubbleLayout = true;
        this.layoutIfNecessary = function (e) {
            _this.doLayout();
            return false;
        };
        this.onChildInOut = function (e) {
            _this.setNeedLayout();
            if (e.type === core.FEventType.AddChild) {
                e.target.addListener(core.FEventType.AfterChange, _this.onContainerOrChildChange);
            }
            if (e.type === core.FEventType.RemoveChild) {
                e.target.removeListener(core.FEventType.AfterChange, _this.onContainerOrChildChange);
            }
            return false;
        };
        this.onContainerOrChildChange = function (e) {
            var target = e.target;
            if (target !== _this.container && !_this.respondElement(target)) {
                return false;
            }
            var ae = e;
            if (_this.inLayout)
                return false;
            var changes = ae.changes;
            // check size change
            if (changes.width !== undefined || changes.height !== undefined) {
                _this.setNeedLayout();
            }
            return false;
        };
    }
    FLayout.prototype.ensureContainer = function () {
        if (this.container === undefined)
            throw new Error('Layout should attch to a widget');
    };
    // cant change auto resized child's size
    FLayout.prototype.isElementSizeAuto = function (w) {
        return !!w.layoutManager && w.layoutManager.isSizeAuto();
    };
    FLayout.prototype.setElementFrame = function (w, r) {
        if (this.isElementSizeAuto(w)) {
            w.origin = r.leftTop();
        }
        else {
            w.frame = r;
        }
    };
    // TODO: hidden elements?
    FLayout.prototype.getElements = function () {
        var children = this.container.children();
        var ret = [];
        children.each(function (c) {
            !c.hidden && ret.push(c);
        });
        return ret;
    };
    FLayout.prototype.measure = function (w) {
        if (w.layoutManager && w.layoutManager.isSizeAuto()) {
            w.layoutManager.doLayout();
        }
        return new core.FSize(w.width, w.height);
    };
    FLayout.prototype.resolveChildrenSize = function () {
        var _this = this;
        var children = this.getElements();
        var maxWidth = 0;
        var maxHeight = 0;
        var fullWidth = 0;
        var fullHeight = 0;
        var fullSpace = 0;
        children.forEach(function (c) {
            var csize = _this.measure(c);
            fullWidth += csize.width;
            fullHeight += csize.height;
            maxWidth = Math.max(csize.width, maxWidth);
            maxHeight = Math.max(csize.height, maxHeight);
        });
        return { maxWidth: maxWidth, maxHeight: maxHeight, fullHeight: fullHeight, fullWidth: fullWidth, fullSpace: fullSpace };
    };
    FLayout.prototype.doLayout = function () {
        // TODO: what if no children?
        this.ensureContainer();
        if (!this.needLayout)
            return;
        this.inLayout = true;
        var childSizeInfo = this.resolveChildrenSize();
        this.arrangeChildrenPosition(childSizeInfo);
        this.resolveSizeFromChildren();
        this.needLayout = false;
        this.inLayout = false;
    };
    FLayout.prototype.setNeedLayout = function () {
        this.ensureContainer();
        // prevent children set need layout in layouting.
        if (!this.inLayout && !this.needLayout) {
            this.needLayout = true;
            // make sure container is marked as dirty.
            if (!this.container.isSelfDirty) {
                this.container.updateByCfg({ _phantom: true });
            }
            var parent_1 = this.container.parent();
            if (parent_1 && parent_1.layoutManager && this.bubbleLayout) {
                parent_1.layoutManager.setNeedLayout();
            }
        }
    };
    FLayout.prototype.attach = function (w) {
        var _this = this;
        this.container = w;
        w.addListener(core.FEventType.BeforeFlush, this.layoutIfNecessary);
        w.addListener(core.FEventType.AddChild, this.onChildInOut);
        w.addListener(core.FEventType.RemoveChild, this.onChildInOut);
        // attach changes for all children
        w.children().each(function (child) {
            child.addListener(core.FEventType.AfterChange, _this.onContainerOrChildChange);
        });
        w.addListener(core.FEventType.AfterChange, this.onContainerOrChildChange);
        this.setNeedLayout();
    };
    FLayout.prototype.detach = function () {
        var _this = this;
        // TODO: remove params.
        this.ensureContainer();
        this.container.removeListener(core.FEventType.BeforeFlush, this.layoutIfNecessary);
        this.container.removeListener(core.FEventType.AddChild, this.onChildInOut);
        this.container.removeListener(core.FEventType.RemoveChild, this.onChildInOut);
        this.container.children().each(function (child) {
            child.removeListener(core.FEventType.AfterChange, _this.onContainerOrChildChange);
        });
        this.container.removeListener(core.FEventType.AfterChange, this.onContainerOrChildChange);
    };
    return FLayout;
}());
function undef(f) { return f === undefined; }
function isPer(v) {
    return typeof v === 'object' && v.type === exports.FDimensionType.Pr;
}
function isFrc(v) {
    return typeof v === 'object' && v.type === exports.FDimensionType.Fr;
}
function isAbs(v) {
    return typeof v === 'number';
}
function isAuto(v) {
    return v === Auto;
}

var FAbsoluteLayout = /** @class */ (function (_super) {
    __extends(FAbsoluteLayout, _super);
    function FAbsoluteLayout() {
        var _this = _super !== null && _super.apply(this, arguments) || this;
        _this.elementParamMap = new Map();
        _this.bubbleLayout = false;
        return _this;
    }
    FAbsoluteLayout.prototype.changeElementParams = function (el, params) {
        var old = this.elementParamMap.get(el);
        var newParams = Object.assign({}, old, params);
        this.elementParamMap.set(el, newParams);
        if (this.container)
            this.setNeedLayout();
    };
    // override this, since there is no need
    // resolveChildrenSize() {
    //   return {} as ChildrenSizeInfo;
    // }
    FAbsoluteLayout.prototype.isSizeAuto = function () {
        return false;
    };
    FAbsoluteLayout.prototype.respondElement = function (w) {
        return this.elementParamMap.has(w);
    };
    FAbsoluteLayout.prototype.parseParams = function (child, params) {
        var pwidth = params.width, pheight = params.height, pleft = params.left, pright = params.right, ptop = params.top, pbottom = params.bottom;
        var fullWidth = this.container.width;
        var fullHeight = this.container.height;
        var x = undefined;
        var y = undefined;
        var width = undefined;
        var height = undefined;
        var left = undefined;
        var right = undefined;
        var top = undefined;
        var bottom = undefined;
        var stretchHor = !(undef(pleft) || undef(pright));
        var stretchVer = !(undef(ptop) || undef(pbottom));
        if (!undef(pwidth)) {
            if (isPer(pwidth)) {
                width = pwidth.value * fullWidth;
            }
            else if (isAbs(pwidth)) {
                width = pwidth;
            }
            else {
                this.panic();
            }
        }
        else {
            width = child.width;
        }
        if (!undef(pheight)) {
            if (isPer(pheight)) {
                height = pheight.value * fullHeight;
            }
            else if (isAbs(pheight)) {
                height = pheight;
            }
            else {
                this.panic();
            }
        }
        else {
            height = child.height;
        }
        var w = stretchHor ? 0 : width;
        // horizontal
        if (!undef(pleft)) {
            if (isPer(pleft)) {
                left = pleft.value * fullWidth - pleft.value * w;
            }
            else if (isAbs(pleft)) {
                left = pleft;
            }
            else {
                this.panic();
            }
        }
        if (!undef(pright)) {
            if (isPer(pright)) {
                right = pright.value * fullWidth - pright.value * w;
                right = fullWidth - right;
            }
            else if (isAbs(pright)) {
                right = fullWidth - pright;
            }
            else {
                this.panic();
            }
        }
        var h = stretchVer ? 0 : height;
        // vertical repeat horizontal
        if (!undef(ptop)) {
            if (isPer(ptop)) {
                top = ptop.value * fullHeight - ptop.value * h;
            }
            else if (isAbs(ptop)) {
                top = ptop;
            }
            else {
                this.panic();
            }
        }
        if (!undef(pbottom)) {
            if (isPer(pbottom)) {
                bottom = pbottom.value * fullHeight - pbottom.value * h;
                bottom = fullHeight - bottom;
            }
            else if (isAbs(pbottom)) {
                bottom = fullHeight - pbottom;
            }
            else {
                this.panic();
            }
        }
        // resolve horizontal
        if (stretchHor) { // stretch width
            x = left;
            width = right - left;
        }
        else {
            // only one or none side determined
            if (!undef(left)) {
                x = left;
            }
            if (!undef(right)) {
                x = right - width;
            }
        }
        if (stretchVer) { // stretch height
            y = top;
            height = bottom - top;
        }
        else {
            // only one or none side determined
            if (!undef(top)) {
                y = top;
            }
            if (!undef(bottom)) {
                y = bottom - height;
            }
        }
        return new core.FRect(x, y, width, height);
    };
    FAbsoluteLayout.prototype.panic = function () {
        throw new Error('Unsupported');
    };
    FAbsoluteLayout.prototype.arrangeChildrenPosition = function () {
        var _this = this;
        this.elementParamMap.forEach(function (params, w) {
            var frame = _this.parseParams(w, params);
            _this.setElementFrame(w, frame);
        });
    };
    FAbsoluteLayout.prototype.resolveSizeFromChildren = function () {
        //
    };
    return FAbsoluteLayout;
}(FLayout));

(function (FAlignment) {
    FAlignment[FAlignment["Start"] = 0] = "Start";
    FAlignment[FAlignment["Center"] = 1] = "Center";
    FAlignment[FAlignment["End"] = 2] = "End";
    FAlignment[FAlignment["Stretch"] = 3] = "Stretch";
    FAlignment[FAlignment["Auto"] = 4] = "Auto";
})(exports.FAlignment || (exports.FAlignment = {}));
(function (FDistribution) {
    FDistribution[FDistribution["Start"] = 0] = "Start";
    FDistribution[FDistribution["Center"] = 1] = "Center";
    FDistribution[FDistribution["End"] = 2] = "End";
    FDistribution[FDistribution["SpaceBetween"] = 3] = "SpaceBetween";
    FDistribution[FDistribution["SpaceAround"] = 4] = "SpaceAround";
})(exports.FDistribution || (exports.FDistribution = {}));
var DefaultStackParams = {
    autoResizing: false,
    horizontal: false,
    alignment: exports.FAlignment.Start,
    distribution: exports.FDistribution.Start,
    spacing: 0,
};
var DefaultStackElementParams = {
    alignSelf: exports.FAlignment.Auto
};
var FStackLayout = /** @class */ (function (_super) {
    __extends(FStackLayout, _super);
    function FStackLayout(params) {
        var _this = _super.call(this) || this;
        _this.containerParams = Object.assign({}, DefaultStackParams);
        _this.elementParamMap = new Map();
        if (params !== undefined) {
            _this.changeContainerParams(params);
        }
        return _this;
    }
    FStackLayout.prototype.changeContainerParams = function (params) {
        Object.assign(this.containerParams, params);
        if (this.container)
            this.setNeedLayout();
    };
    FStackLayout.prototype.changeElementParams = function (el, params) {
        var old = this.elementParamMap.get(el);
        var newParams = Object.assign({}, old, params);
        this.elementParamMap.set(el, newParams);
        if (this.container)
            this.setNeedLayout();
    };
    FStackLayout.prototype.getElementParams = function (el) {
        var params = this.elementParamMap.get(el);
        return Object.assign({}, DefaultStackElementParams, params);
    };
    //#region utils
    // set any widget's main extent.
    FStackLayout.prototype.setMainExtent = function (w, l) {
        if (this.containerParams.horizontal) {
            w.updateByCfg({ width: l });
        }
        else {
            w.updateByCfg({ height: l });
        }
    };
    Object.defineProperty(FStackLayout.prototype, "mainAxisAuto", {
        get: function () {
            return this.containerParams.autoResizing;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FStackLayout.prototype, "mainAxisExtent", {
        get: function () {
            if (this.containerParams.horizontal) {
                return this.container.width;
            }
            else {
                return this.container.height;
            }
        },
        enumerable: true,
        configurable: true
    });
    FStackLayout.prototype.respondElement = function (w) {
        return true;
    };
    FStackLayout.prototype.isSizeAuto = function () {
        return this.containerParams.autoResizing;
    };
    //#endregion
    FStackLayout.prototype.resolveChildrenSize = function () {
        var _this = this;
        var children = this.getElements();
        var maxWidth = 0;
        var maxHeight = 0;
        var fullWidth = 0;
        var fullHeight = 0;
        var fullSpace = 0;
        var spacing = this.containerParams.spacing;
        var size = children.length;
        var fractionBase = 0;
        var unresolvedArr = [];
        children.forEach(function (child) {
            var childParams = _this.getElementParams(child);
            var basis = childParams.basis;
            var unresolved = false;
            // when there is basis the the main extent is determined
            // but not for auto resized children
            if (!undef(basis) && !_this.isElementSizeAuto(child)) {
                if (isAbs(basis)) {
                    _this.setMainExtent(child, basis);
                }
                if (isPer(basis) && !_this.mainAxisAuto) {
                    var ext = basis.value * _this.mainAxisExtent;
                    _this.setMainExtent(child, ext);
                }
                if (isFrc(basis)) {
                    unresolvedArr.push({ child: child, fraction: basis.value });
                    fractionBase += basis.value;
                    unresolved = true;
                }
            }
            else {
                _this.measure(child);
            }
            if (!unresolved) {
                fullWidth += child.width;
                fullHeight += child.height;
            }
            // only update max cross for unresolved
            if (!unresolved || _this.containerParams.horizontal) {
                maxHeight = Math.max(child.height, maxHeight);
            }
            if (!unresolved || !_this.containerParams.horizontal) {
                maxWidth = Math.max(child.width, maxWidth);
            }
        });
        fullSpace = (size - 1) * spacing;
        var fullMain = this.containerParams.horizontal ? fullWidth : fullHeight;
        fullMain += fullSpace;
        var remain = this.mainAxisExtent - fullMain;
        unresolvedArr.forEach(function (cInfo) {
            var fract = remain / fractionBase;
            var d = fract * cInfo.fraction;
            if (remain > 0) {
                _this.setMainExtent(cInfo.child, d);
            }
            fullWidth += cInfo.child.width;
            fullHeight += cInfo.child.height;
        });
        return { maxWidth: maxWidth, maxHeight: maxHeight, fullHeight: fullHeight, fullWidth: fullWidth, fullSpace: fullSpace };
    };
    FStackLayout.prototype.arrangeChildrenPosition = function (sizeInfo) {
        var _this = this;
        var isHor = this.containerParams.horizontal;
        var children = this.getElements();
        var size = children.length;
        var top = 0;
        var left = 0;
        var spacing = this.containerParams.spacing;
        var spacingBefore = 0;
        var containerWidth = this.container.width;
        var containerHeight = this.container.height;
        var distribution = this.containerParams.distribution;
        if (this.containerParams.autoResizing) {
            // determine cross extent
            if (isHor) {
                containerHeight = sizeInfo.maxHeight;
                containerWidth = sizeInfo.fullWidth + sizeInfo.fullSpace;
            }
            else {
                containerWidth = sizeInfo.maxWidth;
                containerHeight = sizeInfo.fullHeight + sizeInfo.fullSpace;
            }
        }
        else { // rigid container size
            var remain = 0;
            if (isHor) {
                remain = containerWidth - sizeInfo.fullWidth;
            }
            else {
                remain = containerHeight - sizeInfo.fullHeight;
            }
            if (distribution === exports.FDistribution.SpaceBetween) {
                // only add spcing between when container is large enough
                if (remain >= 0) {
                    spacing = remain / (size - 1); // override spacing param
                }
            }
            if (distribution === exports.FDistribution.SpaceAround) {
                var s = remain / size / 2;
                spacing = s;
                spacingBefore = s;
            }
        }
        // main axis start pos
        if (isHor) {
            left = align(distribution, containerWidth, sizeInfo.fullWidth + sizeInfo.fullSpace);
        }
        else {
            top = align(distribution, containerHeight, sizeInfo.fullHeight + sizeInfo.fullSpace);
        }
        children.forEach(function (child) {
            var width = child.width;
            var height = child.height;
            var childAlign = _this.containerParams.alignment;
            var childParams = _this.getElementParams(child);
            if (childParams.alignSelf !== exports.FAlignment.Auto) {
                childAlign = childParams.alignSelf;
            }
            // cross axis pos
            if (_this.containerParams.horizontal) {
                if (childAlign === exports.FAlignment.Stretch) {
                    height = containerHeight;
                    top = 0;
                }
                else {
                    top = align(childAlign, containerHeight, child.height);
                }
            }
            else {
                if (childAlign === exports.FAlignment.Stretch) {
                    width = containerWidth;
                    left = 0;
                }
                else {
                    left = align(childAlign, containerWidth, child.width);
                }
            }
            // main axis grow
            if (_this.containerParams.horizontal) {
                left += spacingBefore;
            }
            else {
                top += spacingBefore;
            }
            var frame = new core.FRect(left, top, width, height);
            _this.setElementFrame(child, frame);
            // main axis grow
            if (_this.containerParams.horizontal) {
                left += child.width + spacing;
            }
            else {
                top += child.height + spacing;
            }
        });
    };
    FStackLayout.prototype.resolveSizeFromChildren = function () {
        if (!this.containerParams.autoResizing)
            return;
        var bounds = new core.FRect(0, 0, 0, 0);
        this.getElements().forEach(function (child) { return bounds.union(child.frame); });
        this.container.size = bounds.size;
    };
    return FStackLayout;
}(FLayout));
function align(alignment, containerWidth, contentWidth) {
    if (alignment === exports.FAlignment.Center) {
        return (containerWidth - contentWidth) / 2;
    }
    else if (alignment === exports.FAlignment.End) {
        return containerWidth - contentWidth;
    }
    else {
        return 0;
    }
}

var FGridLayout = /** @class */ (function (_super) {
    __extends(FGridLayout, _super);
    function FGridLayout(params) {
        var _this = _super.call(this) || this;
        _this.elementParamMap = new Map();
        _this.containerParams = _this.getDefaultGridParams();
        if (params !== undefined) {
            Object.assign(_this.containerParams, params);
        }
        return _this;
    }
    FGridLayout.prototype.isSizeAuto = function () {
        return false;
    };
    FGridLayout.prototype.respondElement = function (w) {
        return this.elementParamMap.has(w);
    };
    FGridLayout.prototype.changeContainerParams = function (params) {
        var pre = Object.assign({}, this.containerParams);
        Object.assign(this.containerParams, params);
        if (this.container && !core.equals(pre, this.containerParams))
            this.setNeedLayout();
    };
    FGridLayout.prototype.changeElementParams = function (el, left, top, columnSpan, rowSpan) {
        if (columnSpan === void 0) { columnSpan = 1; }
        if (rowSpan === void 0) { rowSpan = 1; }
        this.elementParamMap.set(el, {
            row: top, column: left,
            rowSpan: rowSpan, columnSpan: columnSpan
        });
        if (this.container)
            this.setNeedLayout();
    };
    FGridLayout.prototype.addArrangedChild = function (w, left, top, columnSpan, rowSpan) {
        if (columnSpan === void 0) { columnSpan = 1; }
        if (rowSpan === void 0) { rowSpan = 1; }
        this.ensureContainer();
        this.container.addChild(w);
        this.changeElementParams(w, left, top, columnSpan, rowSpan);
    };
    FGridLayout.prototype.getDefaultGridParams = function () {
        return {
            rows: [],
            columns: [],
        };
    };
    // limit layout children to row * col
    FGridLayout.prototype.getElements = function () {
        var rows = this.containerParams.rows.length || 1;
        var cols = this.containerParams.columns.length || 1;
        var cnt = rows * cols;
        var children = _super.prototype.getElements.call(this);
        return children.slice(0, cnt);
    };
    FGridLayout.prototype.resolveRowColDimensions = function () {
        if (this.containerParams.columns.length === 0) {
            this.colWidthArr = [this.container.width]; // should this be auto?
        }
        else {
            this.colWidthArr = resolveSegmentDimension(this.container.width, this.containerParams.columns);
        }
        if (this.containerParams.rows.length === 0) {
            this.rowHeightArr = [this.container.height];
        }
        else {
            this.rowHeightArr = resolveSegmentDimension(this.container.height, this.containerParams.rows);
        }
    };
    FGridLayout.prototype.getCellSize = function (range) {
        var col = range.col, colSpan = range.colSpan, row = range.row, rowSpan = range.rowSpan;
        var w = 0;
        var h = 0;
        while (colSpan-- > 0) {
            var dw = this.colWidthArr[col++];
            w += dw === undefined ? 0 : dw;
        }
        while (rowSpan-- > 0) {
            var dh = this.rowHeightArr[row++];
            h += dh === undefined ? 0 : dh;
        }
        return [w, h];
    };
    FGridLayout.prototype.getOrders = function () {
        var _this = this;
        var widgets = Array.from(this.elementParamMap.keys());
        widgets.forEach(function (w) {
            if (!_this.container.ancestorOf(w)) {
                _this.elementParamMap.delete(w);
                return;
            }
        });
        return this.elementParamMap;
    };
    FGridLayout.prototype.arrangeChildrenPosition = function (sizeInfo) {
        var _this = this;
        var orders = this.getOrders();
        this.resolveRowColDimensions();
        var rowTop = function (row) { return row > 0 && row <= _this.rowHeightArr.length ? _this.rowHeightArr[row - 1] : 0; };
        var colLeft = function (col) { return col > 0 && col <= _this.colWidthArr.length ? _this.colWidthArr[col - 1] : 0; };
        orders.forEach(function (params, w) {
            var top = rowTop(params.row);
            var left = colLeft(params.column);
            var width = colLeft(params.column + (params.columnSpan || 1)) - left;
            var height = rowTop(params.row + (params.rowSpan || 1)) - top;
            var frame = new core.FRect(left, top, width, height);
            _this.setElementFrame(w, frame);
        });
    };
    FGridLayout.prototype.resolveSizeFromChildren = function () {
        //
    };
    return FGridLayout;
}(FLayout));
function resolveSegmentDimension(containerWidth, segArr) {
    var fractionBase = 0;
    var fixSum = 0;
    segArr.forEach(function (s, i) {
        if (isAbs(s))
            fixSum += s;
        if (isPer(s))
            fixSum += s.value * containerWidth;
        if (isFrc(s))
            fractionBase += s.value;
    });
    var remain = Math.max(0, containerWidth - fixSum);
    var results = [];
    segArr.forEach(function (s, i) {
        if (isAbs(s))
            results.push(s);
        if (isPer(s))
            results.push(s.value * containerWidth);
        if (isFrc(s))
            results.push(s.value / fractionBase * remain);
    });
    var s = 0;
    return results.map(function (w) {
        s += w;
        return s;
    });
}

var FRawTableView = /** @class */ (function (_super) {
    __extends(FRawTableView, _super);
    function FRawTableView(p, model) {
        var _this = _super.call(this, p) || this;
        _this._corner = null;
        _this._colHeader = new FHScrollView(_this, null);
        _this._rowheader = new FVScrollView(_this, null);
        _this._model = null;
        _this.layout = new FGridLayout();
        _this._content = new FDocView(_this, null);
        core.Bind.propBind(_this._content, 'posX', _this._colHeader.doc(), 'posX');
        core.Bind.propBind(_this._content, 'posY', _this._rowheader.doc(), 'posY');
        core.Bind.propBind(_this._colHeader.doc(), 'posX', _this._content, 'posX');
        core.Bind.propBind(_this._rowheader.doc(), 'posY', _this._content, 'posY');
        _this.setLayout(_this.layout);
        if (model)
            _this.setModel(model);
        return _this;
    }
    /**
     * get row col index from doc positions
     * @param docX
     * @param docY
     */
    FRawTableView.prototype.docPos2Cell = function (docX, docY) {
        return this._content.docPos2Cell(new core.FPoint(docX, docY));
    };
    /**
     * get row col index from view position relative to TableView
     *
     * @param x
     * @param y
     */
    FRawTableView.prototype.viewPos2Cell = function (x, y) {
        var pt = new core.FPoint(x, y);
        pt = this.viewPos2Doc(pt);
        return this._content.docPos2Cell(pt);
    };
    FRawTableView.prototype.cell2DocPos = function (cell) {
        return this._content.cell2DocPos(cell);
    };
    FRawTableView.prototype.cell2ViewPos = function (cell) {
        var pos = this.cell2DocPos(cell);
        return this.docPos2View(pos);
    };
    FRawTableView.prototype.docPos2View = function (docPt) {
        var pt = this._content.doc2View(docPt);
        return pt.move(this._content.x, this._content.y);
    };
    FRawTableView.prototype.viewPos2Doc = function (viewPt) {
        viewPt.move(-this._content.x, -this._content.y);
        return this._content.view2Doc(viewPt);
    };
    FRawTableView.prototype.rowHeader = function () {
        return this._rowheader;
    };
    FRawTableView.prototype.colHeader = function () {
        return this._colHeader;
    };
    FRawTableView.prototype.contentDoc = function () {
        return this._content;
    };
    FRawTableView.prototype.setModel = function (model) {
        this._model = model;
        this._content.setModel(model);
        var rowHeader = new RowHeaderModel(this._model, this);
        this._rowheader.setModel(rowHeader);
        var colHeader = new ColHeaderModel(this._model, 0, this);
        this._colHeader.setModel(colHeader);
        this.reset();
        this._updateCorner();
        this.updateLayout();
    };
    FRawTableView.prototype.updateLayout = function () {
        var headerHeight = this._model.colHeaderHeight();
        var headerWidth = this._model.rowHeaderWidth();
        this.layout.changeContainerParams({
            rows: [headerHeight, Fraction(1)],
            columns: [headerWidth, Fraction(1)]
        });
        if (this._corner) {
            this.layout.changeElementParams(this._corner, 0, 0);
        }
        this.layout.changeElementParams(this._rowheader, 0, 1);
        this.layout.changeElementParams(this._colHeader, 1, 0);
        this.layout.changeElementParams(this._content, 1, 1);
    };
    FRawTableView.prototype.reset = function () {
        this._rowheader.doc().reset();
        this._colHeader.doc().reset();
        this._content.reset();
        this._updateCorner();
        this.updateLayout(); // call in sheet_view's rebuild
    };
    FRawTableView.prototype.model = function () {
        return this._model;
    };
    FRawTableView.prototype._updateCorner = function () {
        if (this._corner !== null) {
            this._corner.destroy();
            this._corner = null;
        }
        if (this._model !== null) {
            this._corner = this._model.leftTopCorner();
            if (this._corner !== null)
                this.addChild(this._corner);
        }
    };
    return FRawTableView;
}(core.FWidget));
var ColHeaderModel = /** @class */ (function () {
    function ColHeaderModel(_tblModel, _row, _tableView) {
        this._tblModel = _tblModel;
        this._row = _row;
        this._tableView = _tableView;
    }
    ColHeaderModel.prototype.sumSize = function () {
        return this._tblModel.width();
    };
    ColHeaderModel.prototype.blockSize = function (idx) {
        return this._tblModel.colWidth(idx);
    };
    ColHeaderModel.prototype.has = function (idx) {
        return this._tblModel.hasCol(idx);
    };
    ColHeaderModel.prototype.blockStyle = function (idx) {
        return null;
    };
    ColHeaderModel.prototype.contentWidget = function (idx) {
        return this._tblModel.colHeaderWidget(idx);
    };
    return ColHeaderModel;
}());
var RowHeaderModel = /** @class */ (function () {
    function RowHeaderModel(_tblModel, _tblView) {
        this._tblModel = _tblModel;
        this._tblView = _tblView;
    }
    RowHeaderModel.prototype.sumSize = function () {
        return this._tblModel.height();
    };
    RowHeaderModel.prototype.blockSize = function (idx) {
        return this._tblModel.rowHeight(idx);
    };
    RowHeaderModel.prototype.has = function (idx) {
        return this._tblModel.hasRow(idx);
    };
    RowHeaderModel.prototype.blockStyle = function (idx) {
        return null;
    };
    RowHeaderModel.prototype.contentWidget = function (idx) {
        return this._tblModel.rowHeaderWidget(idx);
    };
    return RowHeaderModel;
}());

var FTableView = /** @class */ (function (_super) {
    __extends(FTableView, _super);
    function FTableView(p, model) {
        var _this = _super.call(this, p) || this;
        _this._table = new FRawTableView(_this, null);
        _this._hscrollbar = new FHScrollbar(_this);
        _this._hscrollbar.updateByCfg({ hidden: true });
        _this._vscrollbar = new FVScrollbar(_this);
        _this._vscrollbar.updateByCfg({ hidden: true });
        var contentDoc = _this._table.contentDoc();
        core.Bind.propBind(_this._hscrollbar, 'y', _this, 'height', function (v) { return v - _this._hscrollbar.height; });
        core.Bind.propBind(_this._hscrollbar, 'width', _this, 'width', function (v) { return v - _this._vscrollVisibleWidth(); });
        core.Bind.propBind(_this._hscrollbar, 'page', contentDoc, 'width');
        core.Bind.propBind(_this._hscrollbar, 'value', contentDoc, 'posX');
        core.Bind.propBind(_this._hscrollbar, 'hidden', _this, 'hscroll');
        core.Bind.propBind(_this._vscrollbar, 'x', _this, 'width', function (v) { return v - _this._vscrollbar.width; });
        core.Bind.propBind(_this._vscrollbar, 'height', _this, 'height', function (v) { return v - _this._hscrollVisibleHeight(); });
        core.Bind.propBind(_this._vscrollbar, 'page', contentDoc, 'height');
        core.Bind.propBind(_this._vscrollbar, 'value', contentDoc, 'posY');
        core.Bind.propBind(_this._vscrollbar, 'hidden', _this, 'vscroll');
        core.Bind.propBind(contentDoc, 'posX', _this._hscrollbar, 'value');
        core.Bind.propBind(contentDoc, 'posY', _this._vscrollbar, 'value');
        core.Bind.propBind(_this._table, 'width', _this, 'width');
        core.Bind.propBind(_this._table, 'height', _this, 'height');
        _this._table.setModel(model);
        // contentDoc
        core.Bind.propBind(_this._vscrollbar, 'max', contentDoc, 'docHeight');
        core.Bind.propBind(_this._hscrollbar, 'max', contentDoc, 'docWidth');
        core.Bind.propBind(_this._vscrollbar, 'hidden', contentDoc, 'docHeight', function (v) { return !_this._hasVScroll(); });
        core.Bind.propBind(_this._hscrollbar, 'hidden', contentDoc, 'docWidth', function (v) { return !_this._hasHscroll(); });
        return _this;
        // contentDoc.addListener(FEventType.AfterFlush, () => {
        //   const size = contentDoc.docSize();
        //   this._vscrollbar.updateByCfg({
        //     max: size.height,
        //     hidden: !this._hasVScroll()
        //   });
        //   this._hscrollbar.updateByCfg({
        //     max: size.width,
        //     hidden: !this._hasHscroll()
        //   });
        //   return false;
        // });
    }
    FTableView.prototype.model = function () {
        return this._table.model();
    };
    FTableView.prototype.setModel = function (model) {
        this._table.setModel(model);
    };
    FTableView.prototype.reset = function () {
        this._table.reset();
    };
    FTableView.prototype.rowHeader = function () {
        return this._table.rowHeader();
    };
    FTableView.prototype.colHeader = function () {
        return this._table.colHeader();
    };
    FTableView.prototype.docPos2Cell = function (docX, docY) {
        return this._table.docPos2Cell(docX, docY);
    };
    FTableView.prototype.viewPos2Cell = function (x, y) {
        return this._table.viewPos2Cell(x, y);
    };
    FTableView.prototype.cell2DocPos = function (cell) {
        return this._table.cell2DocPos(cell);
    };
    FTableView.prototype.cell2ViewPos = function (cell) {
        return this._table.cell2ViewPos(cell);
    };
    FTableView.prototype.docPos2View = function (docPt) {
        return this._table.docPos2View(docPt);
    };
    FTableView.prototype.viewPos2Doc = function (viewPt) {
        return this._table.viewPos2Doc(viewPt);
    };
    Object.defineProperty(FTableView.prototype, "hscroll", {
        get: function () {
            return this._cleanProp('hscroll');
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FTableView.prototype, "vscroll", {
        get: function () {
            return this._cleanProp('vscroll');
        },
        enumerable: true,
        configurable: true
    });
    FTableView.prototype._hasVScroll = function () {
        return this.vscroll !== false && this._table.contentDoc().docSize().height > this._table.height;
    };
    FTableView.prototype._hasHscroll = function () {
        return this.hscroll !== false && this._table.contentDoc().docSize().width > this._table.width;
    };
    FTableView.prototype._vscrollVisibleWidth = function () {
        return this._hasVScroll() ? this._vscrollbar.width : 0;
    };
    FTableView.prototype._hscrollVisibleHeight = function () {
        return this._hasHscroll() ? this._hscrollbar.height : 0;
    };
    return FTableView;
}(core.FWidget));

var FCheckbox = /** @class */ (function (_super) {
    __extends(FCheckbox, _super);
    function FCheckbox(p) {
        return _super.call(this, p) || this;
    }
    Object.defineProperty(FCheckbox.prototype, "state", {
        get: function () {
            return this._cleanProp('state');
        },
        enumerable: true,
        configurable: true
    });
    FCheckbox.prototype.click = function (e) {
        var cfg = { state: !this.state };
        this.updateByCfg(cfg);
        return false;
    };
    FCheckbox.prototype._defalutCfg = function () {
        var cfg = _super.prototype._defalutCfg.call(this);
        cfg.state = false;
        return cfg;
    };
    return FCheckbox;
}(core.FWidget));

exports.FVScrollbar = FVScrollbar;
exports.FHScrollbar = FHScrollbar;
exports.FContainerWidget = FContainerWidget;
exports.FScrollView = FScrollView;
exports.VScrollDocModel = VScrollDocModel;
exports.FVScrollView = FVScrollView;
exports.HScrollDocModel = HScrollDocModel;
exports.FHScrollView = FHScrollView;
exports.FDocDirtyEvent = FDocDirtyEvent;
exports.FDocument = FDocument;
exports.FDocView = FDocView;
exports.FLabel = FLabel;
exports.HoverCharEvent = HoverCharEvent;
exports.FRichText = FRichText;
exports.TextSeg = TextSeg;
exports.EllipsisSeg = EllipsisSeg;
exports.InsetSeg = InsetSeg;
exports.FTypographer = FTypographer;
exports.charType = charType;
exports.FontMeasurer = FontMeasurer;
exports.CharIter = CharIter;
exports.FRawTableView = FRawTableView;
exports.FTableView = FTableView;
exports.FImage = FImage;
exports.FCheckbox = FCheckbox;
exports.Auto = Auto;
exports.Fraction = Fraction;
exports.Percent = Percent;
exports.FLayout = FLayout;
exports.undef = undef;
exports.isPer = isPer;
exports.isFrc = isFrc;
exports.isAbs = isAbs;
exports.isAuto = isAuto;
exports.FAbsoluteLayout = FAbsoluteLayout;
exports.FStackLayout = FStackLayout;
exports.FGridLayout = FGridLayout;
exports.FVGWdkConstructor = FVGWdkConstructor;
exports.FDomImage = FDomImage;


        __FASTER_META__.wdk = exports;

        __FASTER_META__.config = {"version":"0.4.20","devtoolsUrl":"https://faster.roading.org/devtools.0.4.20.js","recorderUrl":"https://faster.roading.org/shelter.0.4.20.js"};
        
//# sourceMappingURL=wdk.cjs.js.map

/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(84)))

/***/ }),

/***/ 1624:
/***/ (function(module, exports, __webpack_require__) {

"use strict";



var TYPED_OK =  (typeof Uint8Array !== 'undefined') &&
                (typeof Uint16Array !== 'undefined') &&
                (typeof Int32Array !== 'undefined');

function _has(obj, key) {
  return Object.prototype.hasOwnProperty.call(obj, key);
}

exports.assign = function (obj /*from1, from2, from3, ...*/) {
  var sources = Array.prototype.slice.call(arguments, 1);
  while (sources.length) {
    var source = sources.shift();
    if (!source) { continue; }

    if (typeof source !== 'object') {
      throw new TypeError(source + 'must be non-object');
    }

    for (var p in source) {
      if (_has(source, p)) {
        obj[p] = source[p];
      }
    }
  }

  return obj;
};


// reduce buffer size, avoiding mem copy
exports.shrinkBuf = function (buf, size) {
  if (buf.length === size) { return buf; }
  if (buf.subarray) { return buf.subarray(0, size); }
  buf.length = size;
  return buf;
};


var fnTyped = {
  arraySet: function (dest, src, src_offs, len, dest_offs) {
    if (src.subarray && dest.subarray) {
      dest.set(src.subarray(src_offs, src_offs + len), dest_offs);
      return;
    }
    // Fallback to ordinary array
    for (var i = 0; i < len; i++) {
      dest[dest_offs + i] = src[src_offs + i];
    }
  },
  // Join array of chunks to single array.
  flattenChunks: function (chunks) {
    var i, l, len, pos, chunk, result;

    // calculate data length
    len = 0;
    for (i = 0, l = chunks.length; i < l; i++) {
      len += chunks[i].length;
    }

    // join chunks
    result = new Uint8Array(len);
    pos = 0;
    for (i = 0, l = chunks.length; i < l; i++) {
      chunk = chunks[i];
      result.set(chunk, pos);
      pos += chunk.length;
    }

    return result;
  }
};

var fnUntyped = {
  arraySet: function (dest, src, src_offs, len, dest_offs) {
    for (var i = 0; i < len; i++) {
      dest[dest_offs + i] = src[src_offs + i];
    }
  },
  // Join array of chunks to single array.
  flattenChunks: function (chunks) {
    return [].concat.apply([], chunks);
  }
};


// Enable/Disable typed arrays use, for testing
//
exports.setTyped = function (on) {
  if (on) {
    exports.Buf8  = Uint8Array;
    exports.Buf16 = Uint16Array;
    exports.Buf32 = Int32Array;
    exports.assign(exports, fnTyped);
  } else {
    exports.Buf8  = Array;
    exports.Buf16 = Array;
    exports.Buf32 = Array;
    exports.assign(exports, fnUntyped);
  }
};

exports.setTyped(TYPED_OK);


/***/ }),

/***/ 1795:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


// (C) 1995-2013 Jean-loup Gailly and Mark Adler
// (C) 2014-2017 Vitaly Puzrin and Andrey Tupitsin
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//   claim that you wrote the original software. If you use this software
//   in a product, an acknowledgment in the product documentation would be
//   appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//   misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.

module.exports = {
  2:      'need dictionary',     /* Z_NEED_DICT       2  */
  1:      'stream end',          /* Z_STREAM_END      1  */
  0:      '',                    /* Z_OK              0  */
  '-1':   'file error',          /* Z_ERRNO         (-1) */
  '-2':   'stream error',        /* Z_STREAM_ERROR  (-2) */
  '-3':   'data error',          /* Z_DATA_ERROR    (-3) */
  '-4':   'insufficient memory', /* Z_MEM_ERROR     (-4) */
  '-5':   'buffer error',        /* Z_BUF_ERROR     (-5) */
  '-6':   'incompatible version' /* Z_VERSION_ERROR (-6) */
};


/***/ }),

/***/ 1796:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _defineProperty2 = __webpack_require__(11);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var React = _interopRequireWildcard(_react);

var _propTypes = __webpack_require__(0);

var _propTypes2 = _interopRequireDefault(_propTypes);

var _rcCheckbox = __webpack_require__(3260);

var _rcCheckbox2 = _interopRequireDefault(_rcCheckbox);

var _classnames = __webpack_require__(29);

var _classnames2 = _interopRequireDefault(_classnames);

var _shallowequal = __webpack_require__(741);

var _shallowequal2 = _interopRequireDefault(_shallowequal);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj['default'] = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var __rest = undefined && undefined.__rest || function (s, e) {
    var t = {};
    for (var p in s) {
        if (Object.prototype.hasOwnProperty.call(s, p) && e.indexOf(p) < 0) t[p] = s[p];
    }if (s != null && typeof Object.getOwnPropertySymbols === "function") for (var i = 0, p = Object.getOwnPropertySymbols(s); i < p.length; i++) {
        if (e.indexOf(p[i]) < 0) t[p[i]] = s[p[i]];
    }return t;
};

var Radio = function (_React$Component) {
    (0, _inherits3['default'])(Radio, _React$Component);

    function Radio() {
        (0, _classCallCheck3['default'])(this, Radio);

        var _this = (0, _possibleConstructorReturn3['default'])(this, (Radio.__proto__ || Object.getPrototypeOf(Radio)).apply(this, arguments));

        _this.saveCheckbox = function (node) {
            _this.rcCheckbox = node;
        };
        return _this;
    }

    (0, _createClass3['default'])(Radio, [{
        key: 'shouldComponentUpdate',
        value: function shouldComponentUpdate(nextProps, nextState, nextContext) {
            return !(0, _shallowequal2['default'])(this.props, nextProps) || !(0, _shallowequal2['default'])(this.state, nextState) || !(0, _shallowequal2['default'])(this.context.radioGroup, nextContext.radioGroup);
        }
    }, {
        key: 'focus',
        value: function focus() {
            this.rcCheckbox.focus();
        }
    }, {
        key: 'blur',
        value: function blur() {
            this.rcCheckbox.blur();
        }
    }, {
        key: 'render',
        value: function render() {
            var _classNames;

            var props = this.props,
                context = this.context;

            var prefixCls = props.prefixCls,
                className = props.className,
                children = props.children,
                style = props.style,
                restProps = __rest(props, ["prefixCls", "className", "children", "style"]);

            var radioGroup = context.radioGroup;

            var radioProps = (0, _extends3['default'])({}, restProps);
            if (radioGroup) {
                radioProps.name = radioGroup.name;
                radioProps.onChange = radioGroup.onChange;
                radioProps.checked = props.value === radioGroup.value;
                radioProps.disabled = props.disabled || radioGroup.disabled;
            }
            var wrapperClassString = (0, _classnames2['default'])(className, (_classNames = {}, (0, _defineProperty3['default'])(_classNames, prefixCls + '-wrapper', true), (0, _defineProperty3['default'])(_classNames, prefixCls + '-wrapper-checked', radioProps.checked), (0, _defineProperty3['default'])(_classNames, prefixCls + '-wrapper-disabled', radioProps.disabled), _classNames));
            return React.createElement(
                'label',
                { className: wrapperClassString, style: style, onMouseEnter: props.onMouseEnter, onMouseLeave: props.onMouseLeave },
                React.createElement(_rcCheckbox2['default'], (0, _extends3['default'])({}, radioProps, { prefixCls: prefixCls, ref: this.saveCheckbox })),
                children !== undefined ? React.createElement(
                    'span',
                    null,
                    children
                ) : null
            );
        }
    }]);
    return Radio;
}(React.Component);

exports['default'] = Radio;

Radio.defaultProps = {
    prefixCls: 'ant-radio',
    type: 'radio'
};
Radio.contextTypes = {
    radioGroup: _propTypes2['default'].any
};
module.exports = exports['default'];

/***/ }),

/***/ 1798:
/***/ (function(module, exports, __webpack_require__) {

var baseFlatten = __webpack_require__(386),
    baseIteratee = __webpack_require__(90),
    baseRest = __webpack_require__(85),
    baseUniq = __webpack_require__(729),
    isArrayLikeObject = __webpack_require__(511),
    last = __webpack_require__(727);

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
var unionBy = baseRest(function(arrays) {
  var iteratee = last(arrays);
  if (isArrayLikeObject(iteratee)) {
    iteratee = undefined;
  }
  return baseUniq(baseFlatten(arrays, 1, isArrayLikeObject, true), baseIteratee(iteratee, 2));
});

module.exports = unionBy;


/***/ }),

/***/ 1799:
/***/ (function(module, exports, __webpack_require__) {

var arrayPush = __webpack_require__(294),
    baseFlatten = __webpack_require__(386),
    copyArray = __webpack_require__(289),
    isArray = __webpack_require__(44);

/**
 * Creates a new array concatenating `array` with any additional arrays
 * and/or values.
 *
 * @static
 * @memberOf _
 * @since 4.0.0
 * @category Array
 * @param {Array} array The array to concatenate.
 * @param {...*} [values] The values to concatenate.
 * @returns {Array} Returns the new concatenated array.
 * @example
 *
 * var array = [1];
 * var other = _.concat(array, 2, [3], [[4]]);
 *
 * console.log(other);
 * // => [1, 2, 3, [4]]
 *
 * console.log(array);
 * // => [1]
 */
function concat() {
  var length = arguments.length;
  if (!length) {
    return [];
  }
  var args = Array(length - 1),
      array = arguments[0],
      index = length;

  while (index--) {
    args[index - 1] = arguments[index];
  }
  return arrayPush(isArray(array) ? copyArray(array) : [array], baseFlatten(args, 1));
}

module.exports = concat;


/***/ }),

/***/ 1986:
/***/ (function(module, exports) {


function TreeBase() {}

// removes all nodes from the tree
TreeBase.prototype.clear = function() {
    this._root = null;
    this.size = 0;
};

// returns node data if found, null otherwise
TreeBase.prototype.find = function(data) {
    var res = this._root;

    while(res !== null) {
        var c = this._comparator(data, res.data);
        if(c === 0) {
            return res.data;
        }
        else {
            res = res.get_child(c > 0);
        }
    }

    return null;
};

// returns iterator to node if found, null otherwise
TreeBase.prototype.findIter = function(data) {
    var res = this._root;
    var iter = this.iterator();

    while(res !== null) {
        var c = this._comparator(data, res.data);
        if(c === 0) {
            iter._cursor = res;
            return iter;
        }
        else {
            iter._ancestors.push(res);
            res = res.get_child(c > 0);
        }
    }

    return null;
};

// Returns an iterator to the tree node at or immediately after the item
TreeBase.prototype.lowerBound = function(item) {
    var cur = this._root;
    var iter = this.iterator();
    var cmp = this._comparator;

    while(cur !== null) {
        var c = cmp(item, cur.data);
        if(c === 0) {
            iter._cursor = cur;
            return iter;
        }
        iter._ancestors.push(cur);
        cur = cur.get_child(c > 0);
    }

    for(var i=iter._ancestors.length - 1; i >= 0; --i) {
        cur = iter._ancestors[i];
        if(cmp(item, cur.data) < 0) {
            iter._cursor = cur;
            iter._ancestors.length = i;
            return iter;
        }
    }

    iter._ancestors.length = 0;
    return iter;
};

// Returns an iterator to the tree node immediately after the item
TreeBase.prototype.upperBound = function(item) {
    var iter = this.lowerBound(item);
    var cmp = this._comparator;

    while(iter.data() !== null && cmp(iter.data(), item) === 0) {
        iter.next();
    }

    return iter;
};

// returns null if tree is empty
TreeBase.prototype.min = function() {
    var res = this._root;
    if(res === null) {
        return null;
    }

    while(res.left !== null) {
        res = res.left;
    }

    return res.data;
};

// returns null if tree is empty
TreeBase.prototype.max = function() {
    var res = this._root;
    if(res === null) {
        return null;
    }

    while(res.right !== null) {
        res = res.right;
    }

    return res.data;
};

// returns a null iterator
// call next() or prev() to point to an element
TreeBase.prototype.iterator = function() {
    return new Iterator(this);
};

// calls cb on each node's data, in order
TreeBase.prototype.each = function(cb) {
    var it=this.iterator(), data;
    while((data = it.next()) !== null) {
        if(cb(data) === false) {
            return;
        }
    }
};

// calls cb on each node's data, in reverse order
TreeBase.prototype.reach = function(cb) {
    var it=this.iterator(), data;
    while((data = it.prev()) !== null) {
        if(cb(data) === false) {
            return;
        }
    }
};


function Iterator(tree) {
    this._tree = tree;
    this._ancestors = [];
    this._cursor = null;
}

Iterator.prototype.data = function() {
    return this._cursor !== null ? this._cursor.data : null;
};

// if null-iterator, returns first node
// otherwise, returns next node
Iterator.prototype.next = function() {
    if(this._cursor === null) {
        var root = this._tree._root;
        if(root !== null) {
            this._minNode(root);
        }
    }
    else {
        if(this._cursor.right === null) {
            // no greater node in subtree, go up to parent
            // if coming from a right child, continue up the stack
            var save;
            do {
                save = this._cursor;
                if(this._ancestors.length) {
                    this._cursor = this._ancestors.pop();
                }
                else {
                    this._cursor = null;
                    break;
                }
            } while(this._cursor.right === save);
        }
        else {
            // get the next node from the subtree
            this._ancestors.push(this._cursor);
            this._minNode(this._cursor.right);
        }
    }
    return this._cursor !== null ? this._cursor.data : null;
};

// if null-iterator, returns last node
// otherwise, returns previous node
Iterator.prototype.prev = function() {
    if(this._cursor === null) {
        var root = this._tree._root;
        if(root !== null) {
            this._maxNode(root);
        }
    }
    else {
        if(this._cursor.left === null) {
            var save;
            do {
                save = this._cursor;
                if(this._ancestors.length) {
                    this._cursor = this._ancestors.pop();
                }
                else {
                    this._cursor = null;
                    break;
                }
            } while(this._cursor.left === save);
        }
        else {
            this._ancestors.push(this._cursor);
            this._maxNode(this._cursor.left);
        }
    }
    return this._cursor !== null ? this._cursor.data : null;
};

Iterator.prototype._minNode = function(start) {
    while(start.left !== null) {
        this._ancestors.push(start);
        start = start.left;
    }
    this._cursor = start;
};

Iterator.prototype._maxNode = function(start) {
    while(start.right !== null) {
        this._ancestors.push(start);
        start = start.right;
    }
    this._cursor = start;
};

module.exports = TreeBase;



/***/ }),

/***/ 2016:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


// Note: adler32 takes 12% for level 0 and 2% for level 6.
// It isn't worth it to make additional optimizations as in original.
// Small size is preferable.

// (C) 1995-2013 Jean-loup Gailly and Mark Adler
// (C) 2014-2017 Vitaly Puzrin and Andrey Tupitsin
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//   claim that you wrote the original software. If you use this software
//   in a product, an acknowledgment in the product documentation would be
//   appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//   misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.

function adler32(adler, buf, len, pos) {
  var s1 = (adler & 0xffff) |0,
      s2 = ((adler >>> 16) & 0xffff) |0,
      n = 0;

  while (len !== 0) {
    // Set limit ~ twice less than 5552, to keep
    // s2 in 31-bits, because we force signed ints.
    // in other case %= will fail.
    n = len > 2000 ? 2000 : len;
    len -= n;

    do {
      s1 = (s1 + buf[pos++]) |0;
      s2 = (s2 + s1) |0;
    } while (--n);

    s1 %= 65521;
    s2 %= 65521;
  }

  return (s1 | (s2 << 16)) |0;
}


module.exports = adler32;


/***/ }),

/***/ 2017:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


// Note: we can't get significant speed boost here.
// So write code to minimize size - no pregenerated tables
// and array tools dependencies.

// (C) 1995-2013 Jean-loup Gailly and Mark Adler
// (C) 2014-2017 Vitaly Puzrin and Andrey Tupitsin
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//   claim that you wrote the original software. If you use this software
//   in a product, an acknowledgment in the product documentation would be
//   appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//   misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.

// Use ordinary array, since untyped makes no boost here
function makeTable() {
  var c, table = [];

  for (var n = 0; n < 256; n++) {
    c = n;
    for (var k = 0; k < 8; k++) {
      c = ((c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1));
    }
    table[n] = c;
  }

  return table;
}

// Create table on load. Just 255 signed longs. Not a problem.
var crcTable = makeTable();


function crc32(crc, buf, len, pos) {
  var t = crcTable,
      end = pos + len;

  crc ^= -1;

  for (var i = pos; i < end; i++) {
    crc = (crc >>> 8) ^ t[(crc ^ buf[i]) & 0xFF];
  }

  return (crc ^ (-1)); // >>> 0;
}


module.exports = crc32;


/***/ }),

/***/ 2018:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
// String encode/decode helpers



var utils = __webpack_require__(1624);


// Quick check if we can use fast array to bin string conversion
//
// - apply(Array) can fail on Android 2.2
// - apply(Uint8Array) can fail on iOS 5.1 Safari
//
var STR_APPLY_OK = true;
var STR_APPLY_UIA_OK = true;

try { String.fromCharCode.apply(null, [ 0 ]); } catch (__) { STR_APPLY_OK = false; }
try { String.fromCharCode.apply(null, new Uint8Array(1)); } catch (__) { STR_APPLY_UIA_OK = false; }


// Table with utf8 lengths (calculated by first byte of sequence)
// Note, that 5 & 6-byte values and some 4-byte values can not be represented in JS,
// because max possible codepoint is 0x10ffff
var _utf8len = new utils.Buf8(256);
for (var q = 0; q < 256; q++) {
  _utf8len[q] = (q >= 252 ? 6 : q >= 248 ? 5 : q >= 240 ? 4 : q >= 224 ? 3 : q >= 192 ? 2 : 1);
}
_utf8len[254] = _utf8len[254] = 1; // Invalid sequence start


// convert string to array (typed, when possible)
exports.string2buf = function (str) {
  var buf, c, c2, m_pos, i, str_len = str.length, buf_len = 0;

  // count binary size
  for (m_pos = 0; m_pos < str_len; m_pos++) {
    c = str.charCodeAt(m_pos);
    if ((c & 0xfc00) === 0xd800 && (m_pos + 1 < str_len)) {
      c2 = str.charCodeAt(m_pos + 1);
      if ((c2 & 0xfc00) === 0xdc00) {
        c = 0x10000 + ((c - 0xd800) << 10) + (c2 - 0xdc00);
        m_pos++;
      }
    }
    buf_len += c < 0x80 ? 1 : c < 0x800 ? 2 : c < 0x10000 ? 3 : 4;
  }

  // allocate buffer
  buf = new utils.Buf8(buf_len);

  // convert
  for (i = 0, m_pos = 0; i < buf_len; m_pos++) {
    c = str.charCodeAt(m_pos);
    if ((c & 0xfc00) === 0xd800 && (m_pos + 1 < str_len)) {
      c2 = str.charCodeAt(m_pos + 1);
      if ((c2 & 0xfc00) === 0xdc00) {
        c = 0x10000 + ((c - 0xd800) << 10) + (c2 - 0xdc00);
        m_pos++;
      }
    }
    if (c < 0x80) {
      /* one byte */
      buf[i++] = c;
    } else if (c < 0x800) {
      /* two bytes */
      buf[i++] = 0xC0 | (c >>> 6);
      buf[i++] = 0x80 | (c & 0x3f);
    } else if (c < 0x10000) {
      /* three bytes */
      buf[i++] = 0xE0 | (c >>> 12);
      buf[i++] = 0x80 | (c >>> 6 & 0x3f);
      buf[i++] = 0x80 | (c & 0x3f);
    } else {
      /* four bytes */
      buf[i++] = 0xf0 | (c >>> 18);
      buf[i++] = 0x80 | (c >>> 12 & 0x3f);
      buf[i++] = 0x80 | (c >>> 6 & 0x3f);
      buf[i++] = 0x80 | (c & 0x3f);
    }
  }

  return buf;
};

// Helper (used in 2 places)
function buf2binstring(buf, len) {
  // use fallback for big arrays to avoid stack overflow
  if (len < 65537) {
    if ((buf.subarray && STR_APPLY_UIA_OK) || (!buf.subarray && STR_APPLY_OK)) {
      return String.fromCharCode.apply(null, utils.shrinkBuf(buf, len));
    }
  }

  var result = '';
  for (var i = 0; i < len; i++) {
    result += String.fromCharCode(buf[i]);
  }
  return result;
}


// Convert byte array to binary string
exports.buf2binstring = function (buf) {
  return buf2binstring(buf, buf.length);
};


// Convert binary string (typed, when possible)
exports.binstring2buf = function (str) {
  var buf = new utils.Buf8(str.length);
  for (var i = 0, len = buf.length; i < len; i++) {
    buf[i] = str.charCodeAt(i);
  }
  return buf;
};


// convert array to string
exports.buf2string = function (buf, max) {
  var i, out, c, c_len;
  var len = max || buf.length;

  // Reserve max possible length (2 words per char)
  // NB: by unknown reasons, Array is significantly faster for
  //     String.fromCharCode.apply than Uint16Array.
  var utf16buf = new Array(len * 2);

  for (out = 0, i = 0; i < len;) {
    c = buf[i++];
    // quick process ascii
    if (c < 0x80) { utf16buf[out++] = c; continue; }

    c_len = _utf8len[c];
    // skip 5 & 6 byte codes
    if (c_len > 4) { utf16buf[out++] = 0xfffd; i += c_len - 1; continue; }

    // apply mask on first byte
    c &= c_len === 2 ? 0x1f : c_len === 3 ? 0x0f : 0x07;
    // join the rest
    while (c_len > 1 && i < len) {
      c = (c << 6) | (buf[i++] & 0x3f);
      c_len--;
    }

    // terminated by end of string?
    if (c_len > 1) { utf16buf[out++] = 0xfffd; continue; }

    if (c < 0x10000) {
      utf16buf[out++] = c;
    } else {
      c -= 0x10000;
      utf16buf[out++] = 0xd800 | ((c >> 10) & 0x3ff);
      utf16buf[out++] = 0xdc00 | (c & 0x3ff);
    }
  }

  return buf2binstring(utf16buf, out);
};


// Calculate max possible position in utf8 buffer,
// that will not break sequence. If that's not possible
// - (very small limits) return max size as is.
//
// buf[] - utf8 bytes array
// max   - length limit (mandatory);
exports.utf8border = function (buf, max) {
  var pos;

  max = max || buf.length;
  if (max > buf.length) { max = buf.length; }

  // go back from last position, until start of sequence found
  pos = max - 1;
  while (pos >= 0 && (buf[pos] & 0xC0) === 0x80) { pos--; }

  // Very small and broken sequence,
  // return max, because we should return something anyway.
  if (pos < 0) { return max; }

  // If we came to start of buffer - that means buffer is too small,
  // return max too.
  if (pos === 0) { return max; }

  return (pos + _utf8len[buf[pos]] > max) ? pos : max;
};


/***/ }),

/***/ 2019:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


// (C) 1995-2013 Jean-loup Gailly and Mark Adler
// (C) 2014-2017 Vitaly Puzrin and Andrey Tupitsin
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//   claim that you wrote the original software. If you use this software
//   in a product, an acknowledgment in the product documentation would be
//   appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//   misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.

function ZStream() {
  /* next input byte */
  this.input = null; // JS specific, because we have no pointers
  this.next_in = 0;
  /* number of bytes available at input */
  this.avail_in = 0;
  /* total number of input bytes read so far */
  this.total_in = 0;
  /* next output byte should be put there */
  this.output = null; // JS specific, because we have no pointers
  this.next_out = 0;
  /* remaining free space at output */
  this.avail_out = 0;
  /* total number of bytes output so far */
  this.total_out = 0;
  /* last error message, NULL if no error */
  this.msg = ''/*Z_NULL*/;
  /* not visible by applications */
  this.state = null;
  /* best guess about the data type: binary or text */
  this.data_type = 2/*Z_UNKNOWN*/;
  /* adler32 value of the uncompressed data */
  this.adler = 0;
}

module.exports = ZStream;


/***/ }),

/***/ 2020:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


// (C) 1995-2013 Jean-loup Gailly and Mark Adler
// (C) 2014-2017 Vitaly Puzrin and Andrey Tupitsin
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//   claim that you wrote the original software. If you use this software
//   in a product, an acknowledgment in the product documentation would be
//   appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//   misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.

module.exports = {

  /* Allowed flush values; see deflate() and inflate() below for details */
  Z_NO_FLUSH:         0,
  Z_PARTIAL_FLUSH:    1,
  Z_SYNC_FLUSH:       2,
  Z_FULL_FLUSH:       3,
  Z_FINISH:           4,
  Z_BLOCK:            5,
  Z_TREES:            6,

  /* Return codes for the compression/decompression functions. Negative values
  * are errors, positive values are used for special but normal events.
  */
  Z_OK:               0,
  Z_STREAM_END:       1,
  Z_NEED_DICT:        2,
  Z_ERRNO:           -1,
  Z_STREAM_ERROR:    -2,
  Z_DATA_ERROR:      -3,
  //Z_MEM_ERROR:     -4,
  Z_BUF_ERROR:       -5,
  //Z_VERSION_ERROR: -6,

  /* compression levels */
  Z_NO_COMPRESSION:         0,
  Z_BEST_SPEED:             1,
  Z_BEST_COMPRESSION:       9,
  Z_DEFAULT_COMPRESSION:   -1,


  Z_FILTERED:               1,
  Z_HUFFMAN_ONLY:           2,
  Z_RLE:                    3,
  Z_FIXED:                  4,
  Z_DEFAULT_STRATEGY:       0,

  /* Possible values of the data_type field (though see inflate()) */
  Z_BINARY:                 0,
  Z_TEXT:                   1,
  //Z_ASCII:                1, // = Z_TEXT (deprecated)
  Z_UNKNOWN:                2,

  /* The deflate compression method */
  Z_DEFLATED:               8
  //Z_NULL:                 null // Use -1 or null inline, depending on var type
};


/***/ }),

/***/ 2028:
/***/ (function(module, exports, __webpack_require__) {

var Symbol = __webpack_require__(192),
    copyArray = __webpack_require__(289),
    getTag = __webpack_require__(247),
    isArrayLike = __webpack_require__(122),
    isString = __webpack_require__(385),
    iteratorToArray = __webpack_require__(2954),
    mapToArray = __webpack_require__(760),
    setToArray = __webpack_require__(403),
    stringToArray = __webpack_require__(757),
    values = __webpack_require__(394);

/** `Object#toString` result references. */
var mapTag = '[object Map]',
    setTag = '[object Set]';

/** Built-in value references. */
var symIterator = Symbol ? Symbol.iterator : undefined;

/**
 * Converts `value` to an array.
 *
 * @static
 * @since 0.1.0
 * @memberOf _
 * @category Lang
 * @param {*} value The value to convert.
 * @returns {Array} Returns the converted array.
 * @example
 *
 * _.toArray({ 'a': 1, 'b': 2 });
 * // => [1, 2]
 *
 * _.toArray('abc');
 * // => ['a', 'b', 'c']
 *
 * _.toArray(1);
 * // => []
 *
 * _.toArray(null);
 * // => []
 */
function toArray(value) {
  if (!value) {
    return [];
  }
  if (isArrayLike(value)) {
    return isString(value) ? stringToArray(value) : copyArray(value);
  }
  if (symIterator && value[symIterator]) {
    return iteratorToArray(value[symIterator]());
  }
  var tag = getTag(value),
      func = tag == mapTag ? mapToArray : (tag == setTag ? setToArray : values);

  return func(value);
}

module.exports = toArray;


/***/ }),

/***/ 2803:
/***/ (function(module, exports, __webpack_require__) {

module.exports = {
    RBTree: __webpack_require__(2804),
    BinTree: __webpack_require__(2805)
};


/***/ }),

/***/ 2804:
/***/ (function(module, exports, __webpack_require__) {


var TreeBase = __webpack_require__(1986);

function Node(data) {
    this.data = data;
    this.left = null;
    this.right = null;
    this.red = true;
}

Node.prototype.get_child = function(dir) {
    return dir ? this.right : this.left;
};

Node.prototype.set_child = function(dir, val) {
    if(dir) {
        this.right = val;
    }
    else {
        this.left = val;
    }
};

function RBTree(comparator) {
    this._root = null;
    this._comparator = comparator;
    this.size = 0;
}

RBTree.prototype = new TreeBase();

// returns true if inserted, false if duplicate
RBTree.prototype.insert = function(data) {
    var ret = false;

    if(this._root === null) {
        // empty tree
        this._root = new Node(data);
        ret = true;
        this.size++;
    }
    else {
        var head = new Node(undefined); // fake tree root

        var dir = 0;
        var last = 0;

        // setup
        var gp = null; // grandparent
        var ggp = head; // grand-grand-parent
        var p = null; // parent
        var node = this._root;
        ggp.right = this._root;

        // search down
        while(true) {
            if(node === null) {
                // insert new node at the bottom
                node = new Node(data);
                p.set_child(dir, node);
                ret = true;
                this.size++;
            }
            else if(is_red(node.left) && is_red(node.right)) {
                // color flip
                node.red = true;
                node.left.red = false;
                node.right.red = false;
            }

            // fix red violation
            if(is_red(node) && is_red(p)) {
                var dir2 = ggp.right === gp;

                if(node === p.get_child(last)) {
                    ggp.set_child(dir2, single_rotate(gp, !last));
                }
                else {
                    ggp.set_child(dir2, double_rotate(gp, !last));
                }
            }

            var cmp = this._comparator(node.data, data);

            // stop if found
            if(cmp === 0) {
                break;
            }

            last = dir;
            dir = cmp < 0;

            // update helpers
            if(gp !== null) {
                ggp = gp;
            }
            gp = p;
            p = node;
            node = node.get_child(dir);
        }

        // update root
        this._root = head.right;
    }

    // make root black
    this._root.red = false;

    return ret;
};

// returns true if removed, false if not found
RBTree.prototype.remove = function(data) {
    if(this._root === null) {
        return false;
    }

    var head = new Node(undefined); // fake tree root
    var node = head;
    node.right = this._root;
    var p = null; // parent
    var gp = null; // grand parent
    var found = null; // found item
    var dir = 1;

    while(node.get_child(dir) !== null) {
        var last = dir;

        // update helpers
        gp = p;
        p = node;
        node = node.get_child(dir);

        var cmp = this._comparator(data, node.data);

        dir = cmp > 0;

        // save found node
        if(cmp === 0) {
            found = node;
        }

        // push the red node down
        if(!is_red(node) && !is_red(node.get_child(dir))) {
            if(is_red(node.get_child(!dir))) {
                var sr = single_rotate(node, dir);
                p.set_child(last, sr);
                p = sr;
            }
            else if(!is_red(node.get_child(!dir))) {
                var sibling = p.get_child(!last);
                if(sibling !== null) {
                    if(!is_red(sibling.get_child(!last)) && !is_red(sibling.get_child(last))) {
                        // color flip
                        p.red = false;
                        sibling.red = true;
                        node.red = true;
                    }
                    else {
                        var dir2 = gp.right === p;

                        if(is_red(sibling.get_child(last))) {
                            gp.set_child(dir2, double_rotate(p, last));
                        }
                        else if(is_red(sibling.get_child(!last))) {
                            gp.set_child(dir2, single_rotate(p, last));
                        }

                        // ensure correct coloring
                        var gpc = gp.get_child(dir2);
                        gpc.red = true;
                        node.red = true;
                        gpc.left.red = false;
                        gpc.right.red = false;
                    }
                }
            }
        }
    }

    // replace and remove if found
    if(found !== null) {
        found.data = node.data;
        p.set_child(p.right === node, node.get_child(node.left === null));
        this.size--;
    }

    // update root and make it black
    this._root = head.right;
    if(this._root !== null) {
        this._root.red = false;
    }

    return found !== null;
};

function is_red(node) {
    return node !== null && node.red;
}

function single_rotate(root, dir) {
    var save = root.get_child(!dir);

    root.set_child(!dir, save.get_child(dir));
    save.set_child(dir, root);

    root.red = true;
    save.red = false;

    return save;
}

function double_rotate(root, dir) {
    root.set_child(!dir, single_rotate(root.get_child(!dir), !dir));
    return single_rotate(root, dir);
}

module.exports = RBTree;


/***/ }),

/***/ 2805:
/***/ (function(module, exports, __webpack_require__) {


var TreeBase = __webpack_require__(1986);

function Node(data) {
    this.data = data;
    this.left = null;
    this.right = null;
}

Node.prototype.get_child = function(dir) {
    return dir ? this.right : this.left;
};

Node.prototype.set_child = function(dir, val) {
    if(dir) {
        this.right = val;
    }
    else {
        this.left = val;
    }
};

function BinTree(comparator) {
    this._root = null;
    this._comparator = comparator;
    this.size = 0;
}

BinTree.prototype = new TreeBase();

// returns true if inserted, false if duplicate
BinTree.prototype.insert = function(data) {
    if(this._root === null) {
        // empty tree
        this._root = new Node(data);
        this.size++;
        return true;
    }

    var dir = 0;

    // setup
    var p = null; // parent
    var node = this._root;

    // search down
    while(true) {
        if(node === null) {
            // insert new node at the bottom
            node = new Node(data);
            p.set_child(dir, node);
            ret = true;
            this.size++;
            return true;
        }

        // stop if found
        if(this._comparator(node.data, data) === 0) {
            return false;
        }

        dir = this._comparator(node.data, data) < 0;

        // update helpers
        p = node;
        node = node.get_child(dir);
    }
};

// returns true if removed, false if not found
BinTree.prototype.remove = function(data) {
    if(this._root === null) {
        return false;
    }

    var head = new Node(undefined); // fake tree root
    var node = head;
    node.right = this._root;
    var p = null; // parent
    var found = null; // found item
    var dir = 1;

    while(node.get_child(dir) !== null) {
        p = node;
        node = node.get_child(dir);
        var cmp = this._comparator(data, node.data);
        dir = cmp > 0;

        if(cmp === 0) {
            found = node;
        }
    }

    if(found !== null) {
        found.data = node.data;
        p.set_child(p.right === node, node.get_child(node.left === null));

        this._root = head.right;
        this.size--;
        return true;
    }
    else {
        return false;
    }
};

module.exports = BinTree;



/***/ }),

/***/ 2806:
/***/ (function(module, exports, __webpack_require__) {

var __WEBPACK_AMD_DEFINE_RESULT__;/*! Hammer.JS - v2.0.7 - 2016-04-22
 * http://hammerjs.github.io/
 *
 * Copyright (c) 2016 Jorik Tangelder;
 * Licensed under the MIT license */
(function(window, document, exportName, undefined) {
  'use strict';

var VENDOR_PREFIXES = ['', 'webkit', 'Moz', 'MS', 'ms', 'o'];
var TEST_ELEMENT = document.createElement('div');

var TYPE_FUNCTION = 'function';

var round = Math.round;
var abs = Math.abs;
var now = Date.now;

/**
 * set a timeout with a given scope
 * @param {Function} fn
 * @param {Number} timeout
 * @param {Object} context
 * @returns {number}
 */
function setTimeoutContext(fn, timeout, context) {
    return setTimeout(bindFn(fn, context), timeout);
}

/**
 * if the argument is an array, we want to execute the fn on each entry
 * if it aint an array we don't want to do a thing.
 * this is used by all the methods that accept a single and array argument.
 * @param {*|Array} arg
 * @param {String} fn
 * @param {Object} [context]
 * @returns {Boolean}
 */
function invokeArrayArg(arg, fn, context) {
    if (Array.isArray(arg)) {
        each(arg, context[fn], context);
        return true;
    }
    return false;
}

/**
 * walk objects and arrays
 * @param {Object} obj
 * @param {Function} iterator
 * @param {Object} context
 */
function each(obj, iterator, context) {
    var i;

    if (!obj) {
        return;
    }

    if (obj.forEach) {
        obj.forEach(iterator, context);
    } else if (obj.length !== undefined) {
        i = 0;
        while (i < obj.length) {
            iterator.call(context, obj[i], i, obj);
            i++;
        }
    } else {
        for (i in obj) {
            obj.hasOwnProperty(i) && iterator.call(context, obj[i], i, obj);
        }
    }
}

/**
 * wrap a method with a deprecation warning and stack trace
 * @param {Function} method
 * @param {String} name
 * @param {String} message
 * @returns {Function} A new function wrapping the supplied method.
 */
function deprecate(method, name, message) {
    var deprecationMessage = 'DEPRECATED METHOD: ' + name + '\n' + message + ' AT \n';
    return function() {
        var e = new Error('get-stack-trace');
        var stack = e && e.stack ? e.stack.replace(/^[^\(]+?[\n$]/gm, '')
            .replace(/^\s+at\s+/gm, '')
            .replace(/^Object.<anonymous>\s*\(/gm, '{anonymous}()@') : 'Unknown Stack Trace';

        var log = window.console && (window.console.warn || window.console.log);
        if (log) {
            log.call(window.console, deprecationMessage, stack);
        }
        return method.apply(this, arguments);
    };
}

/**
 * extend object.
 * means that properties in dest will be overwritten by the ones in src.
 * @param {Object} target
 * @param {...Object} objects_to_assign
 * @returns {Object} target
 */
var assign;
if (typeof Object.assign !== 'function') {
    assign = function assign(target) {
        if (target === undefined || target === null) {
            throw new TypeError('Cannot convert undefined or null to object');
        }

        var output = Object(target);
        for (var index = 1; index < arguments.length; index++) {
            var source = arguments[index];
            if (source !== undefined && source !== null) {
                for (var nextKey in source) {
                    if (source.hasOwnProperty(nextKey)) {
                        output[nextKey] = source[nextKey];
                    }
                }
            }
        }
        return output;
    };
} else {
    assign = Object.assign;
}

/**
 * extend object.
 * means that properties in dest will be overwritten by the ones in src.
 * @param {Object} dest
 * @param {Object} src
 * @param {Boolean} [merge=false]
 * @returns {Object} dest
 */
var extend = deprecate(function extend(dest, src, merge) {
    var keys = Object.keys(src);
    var i = 0;
    while (i < keys.length) {
        if (!merge || (merge && dest[keys[i]] === undefined)) {
            dest[keys[i]] = src[keys[i]];
        }
        i++;
    }
    return dest;
}, 'extend', 'Use `assign`.');

/**
 * merge the values from src in the dest.
 * means that properties that exist in dest will not be overwritten by src
 * @param {Object} dest
 * @param {Object} src
 * @returns {Object} dest
 */
var merge = deprecate(function merge(dest, src) {
    return extend(dest, src, true);
}, 'merge', 'Use `assign`.');

/**
 * simple class inheritance
 * @param {Function} child
 * @param {Function} base
 * @param {Object} [properties]
 */
function inherit(child, base, properties) {
    var baseP = base.prototype,
        childP;

    childP = child.prototype = Object.create(baseP);
    childP.constructor = child;
    childP._super = baseP;

    if (properties) {
        assign(childP, properties);
    }
}

/**
 * simple function bind
 * @param {Function} fn
 * @param {Object} context
 * @returns {Function}
 */
function bindFn(fn, context) {
    return function boundFn() {
        return fn.apply(context, arguments);
    };
}

/**
 * let a boolean value also be a function that must return a boolean
 * this first item in args will be used as the context
 * @param {Boolean|Function} val
 * @param {Array} [args]
 * @returns {Boolean}
 */
function boolOrFn(val, args) {
    if (typeof val == TYPE_FUNCTION) {
        return val.apply(args ? args[0] || undefined : undefined, args);
    }
    return val;
}

/**
 * use the val2 when val1 is undefined
 * @param {*} val1
 * @param {*} val2
 * @returns {*}
 */
function ifUndefined(val1, val2) {
    return (val1 === undefined) ? val2 : val1;
}

/**
 * addEventListener with multiple events at once
 * @param {EventTarget} target
 * @param {String} types
 * @param {Function} handler
 */
function addEventListeners(target, types, handler) {
    each(splitStr(types), function(type) {
        target.addEventListener(type, handler, false);
    });
}

/**
 * removeEventListener with multiple events at once
 * @param {EventTarget} target
 * @param {String} types
 * @param {Function} handler
 */
function removeEventListeners(target, types, handler) {
    each(splitStr(types), function(type) {
        target.removeEventListener(type, handler, false);
    });
}

/**
 * find if a node is in the given parent
 * @method hasParent
 * @param {HTMLElement} node
 * @param {HTMLElement} parent
 * @return {Boolean} found
 */
function hasParent(node, parent) {
    while (node) {
        if (node == parent) {
            return true;
        }
        node = node.parentNode;
    }
    return false;
}

/**
 * small indexOf wrapper
 * @param {String} str
 * @param {String} find
 * @returns {Boolean} found
 */
function inStr(str, find) {
    return str.indexOf(find) > -1;
}

/**
 * split string on whitespace
 * @param {String} str
 * @returns {Array} words
 */
function splitStr(str) {
    return str.trim().split(/\s+/g);
}

/**
 * find if a array contains the object using indexOf or a simple polyFill
 * @param {Array} src
 * @param {String} find
 * @param {String} [findByKey]
 * @return {Boolean|Number} false when not found, or the index
 */
function inArray(src, find, findByKey) {
    if (src.indexOf && !findByKey) {
        return src.indexOf(find);
    } else {
        var i = 0;
        while (i < src.length) {
            if ((findByKey && src[i][findByKey] == find) || (!findByKey && src[i] === find)) {
                return i;
            }
            i++;
        }
        return -1;
    }
}

/**
 * convert array-like objects to real arrays
 * @param {Object} obj
 * @returns {Array}
 */
function toArray(obj) {
    return Array.prototype.slice.call(obj, 0);
}

/**
 * unique array with objects based on a key (like 'id') or just by the array's value
 * @param {Array} src [{id:1},{id:2},{id:1}]
 * @param {String} [key]
 * @param {Boolean} [sort=False]
 * @returns {Array} [{id:1},{id:2}]
 */
function uniqueArray(src, key, sort) {
    var results = [];
    var values = [];
    var i = 0;

    while (i < src.length) {
        var val = key ? src[i][key] : src[i];
        if (inArray(values, val) < 0) {
            results.push(src[i]);
        }
        values[i] = val;
        i++;
    }

    if (sort) {
        if (!key) {
            results = results.sort();
        } else {
            results = results.sort(function sortUniqueArray(a, b) {
                return a[key] > b[key];
            });
        }
    }

    return results;
}

/**
 * get the prefixed property
 * @param {Object} obj
 * @param {String} property
 * @returns {String|Undefined} prefixed
 */
function prefixed(obj, property) {
    var prefix, prop;
    var camelProp = property[0].toUpperCase() + property.slice(1);

    var i = 0;
    while (i < VENDOR_PREFIXES.length) {
        prefix = VENDOR_PREFIXES[i];
        prop = (prefix) ? prefix + camelProp : property;

        if (prop in obj) {
            return prop;
        }
        i++;
    }
    return undefined;
}

/**
 * get a unique id
 * @returns {number} uniqueId
 */
var _uniqueId = 1;
function uniqueId() {
    return _uniqueId++;
}

/**
 * get the window object of an element
 * @param {HTMLElement} element
 * @returns {DocumentView|Window}
 */
function getWindowForElement(element) {
    var doc = element.ownerDocument || element;
    return (doc.defaultView || doc.parentWindow || window);
}

var MOBILE_REGEX = /mobile|tablet|ip(ad|hone|od)|android/i;

var SUPPORT_TOUCH = ('ontouchstart' in window);
var SUPPORT_POINTER_EVENTS = prefixed(window, 'PointerEvent') !== undefined;
var SUPPORT_ONLY_TOUCH = SUPPORT_TOUCH && MOBILE_REGEX.test(navigator.userAgent);

var INPUT_TYPE_TOUCH = 'touch';
var INPUT_TYPE_PEN = 'pen';
var INPUT_TYPE_MOUSE = 'mouse';
var INPUT_TYPE_KINECT = 'kinect';

var COMPUTE_INTERVAL = 25;

var INPUT_START = 1;
var INPUT_MOVE = 2;
var INPUT_END = 4;
var INPUT_CANCEL = 8;

var DIRECTION_NONE = 1;
var DIRECTION_LEFT = 2;
var DIRECTION_RIGHT = 4;
var DIRECTION_UP = 8;
var DIRECTION_DOWN = 16;

var DIRECTION_HORIZONTAL = DIRECTION_LEFT | DIRECTION_RIGHT;
var DIRECTION_VERTICAL = DIRECTION_UP | DIRECTION_DOWN;
var DIRECTION_ALL = DIRECTION_HORIZONTAL | DIRECTION_VERTICAL;

var PROPS_XY = ['x', 'y'];
var PROPS_CLIENT_XY = ['clientX', 'clientY'];

/**
 * create new input type manager
 * @param {Manager} manager
 * @param {Function} callback
 * @returns {Input}
 * @constructor
 */
function Input(manager, callback) {
    var self = this;
    this.manager = manager;
    this.callback = callback;
    this.element = manager.element;
    this.target = manager.options.inputTarget;

    // smaller wrapper around the handler, for the scope and the enabled state of the manager,
    // so when disabled the input events are completely bypassed.
    this.domHandler = function(ev) {
        if (boolOrFn(manager.options.enable, [manager])) {
            self.handler(ev);
        }
    };

    this.init();

}

Input.prototype = {
    /**
     * should handle the inputEvent data and trigger the callback
     * @virtual
     */
    handler: function() { },

    /**
     * bind the events
     */
    init: function() {
        this.evEl && addEventListeners(this.element, this.evEl, this.domHandler);
        this.evTarget && addEventListeners(this.target, this.evTarget, this.domHandler);
        this.evWin && addEventListeners(getWindowForElement(this.element), this.evWin, this.domHandler);
    },

    /**
     * unbind the events
     */
    destroy: function() {
        this.evEl && removeEventListeners(this.element, this.evEl, this.domHandler);
        this.evTarget && removeEventListeners(this.target, this.evTarget, this.domHandler);
        this.evWin && removeEventListeners(getWindowForElement(this.element), this.evWin, this.domHandler);
    }
};

/**
 * create new input type manager
 * called by the Manager constructor
 * @param {Hammer} manager
 * @returns {Input}
 */
function createInputInstance(manager) {
    var Type;
    var inputClass = manager.options.inputClass;

    if (inputClass) {
        Type = inputClass;
    } else if (SUPPORT_POINTER_EVENTS) {
        Type = PointerEventInput;
    } else if (SUPPORT_ONLY_TOUCH) {
        Type = TouchInput;
    } else if (!SUPPORT_TOUCH) {
        Type = MouseInput;
    } else {
        Type = TouchMouseInput;
    }
    return new (Type)(manager, inputHandler);
}

/**
 * handle input events
 * @param {Manager} manager
 * @param {String} eventType
 * @param {Object} input
 */
function inputHandler(manager, eventType, input) {
    var pointersLen = input.pointers.length;
    var changedPointersLen = input.changedPointers.length;
    var isFirst = (eventType & INPUT_START && (pointersLen - changedPointersLen === 0));
    var isFinal = (eventType & (INPUT_END | INPUT_CANCEL) && (pointersLen - changedPointersLen === 0));

    input.isFirst = !!isFirst;
    input.isFinal = !!isFinal;

    if (isFirst) {
        manager.session = {};
    }

    // source event is the normalized value of the domEvents
    // like 'touchstart, mouseup, pointerdown'
    input.eventType = eventType;

    // compute scale, rotation etc
    computeInputData(manager, input);

    // emit secret event
    manager.emit('hammer.input', input);

    manager.recognize(input);
    manager.session.prevInput = input;
}

/**
 * extend the data with some usable properties like scale, rotate, velocity etc
 * @param {Object} manager
 * @param {Object} input
 */
function computeInputData(manager, input) {
    var session = manager.session;
    var pointers = input.pointers;
    var pointersLength = pointers.length;

    // store the first input to calculate the distance and direction
    if (!session.firstInput) {
        session.firstInput = simpleCloneInputData(input);
    }

    // to compute scale and rotation we need to store the multiple touches
    if (pointersLength > 1 && !session.firstMultiple) {
        session.firstMultiple = simpleCloneInputData(input);
    } else if (pointersLength === 1) {
        session.firstMultiple = false;
    }

    var firstInput = session.firstInput;
    var firstMultiple = session.firstMultiple;
    var offsetCenter = firstMultiple ? firstMultiple.center : firstInput.center;

    var center = input.center = getCenter(pointers);
    input.timeStamp = now();
    input.deltaTime = input.timeStamp - firstInput.timeStamp;

    input.angle = getAngle(offsetCenter, center);
    input.distance = getDistance(offsetCenter, center);

    computeDeltaXY(session, input);
    input.offsetDirection = getDirection(input.deltaX, input.deltaY);

    var overallVelocity = getVelocity(input.deltaTime, input.deltaX, input.deltaY);
    input.overallVelocityX = overallVelocity.x;
    input.overallVelocityY = overallVelocity.y;
    input.overallVelocity = (abs(overallVelocity.x) > abs(overallVelocity.y)) ? overallVelocity.x : overallVelocity.y;

    input.scale = firstMultiple ? getScale(firstMultiple.pointers, pointers) : 1;
    input.rotation = firstMultiple ? getRotation(firstMultiple.pointers, pointers) : 0;

    input.maxPointers = !session.prevInput ? input.pointers.length : ((input.pointers.length >
        session.prevInput.maxPointers) ? input.pointers.length : session.prevInput.maxPointers);

    computeIntervalInputData(session, input);

    // find the correct target
    var target = manager.element;
    if (hasParent(input.srcEvent.target, target)) {
        target = input.srcEvent.target;
    }
    input.target = target;
}

function computeDeltaXY(session, input) {
    var center = input.center;
    var offset = session.offsetDelta || {};
    var prevDelta = session.prevDelta || {};
    var prevInput = session.prevInput || {};

    if (input.eventType === INPUT_START || prevInput.eventType === INPUT_END) {
        prevDelta = session.prevDelta = {
            x: prevInput.deltaX || 0,
            y: prevInput.deltaY || 0
        };

        offset = session.offsetDelta = {
            x: center.x,
            y: center.y
        };
    }

    input.deltaX = prevDelta.x + (center.x - offset.x);
    input.deltaY = prevDelta.y + (center.y - offset.y);
}

/**
 * velocity is calculated every x ms
 * @param {Object} session
 * @param {Object} input
 */
function computeIntervalInputData(session, input) {
    var last = session.lastInterval || input,
        deltaTime = input.timeStamp - last.timeStamp,
        velocity, velocityX, velocityY, direction;

    if (input.eventType != INPUT_CANCEL && (deltaTime > COMPUTE_INTERVAL || last.velocity === undefined)) {
        var deltaX = input.deltaX - last.deltaX;
        var deltaY = input.deltaY - last.deltaY;

        var v = getVelocity(deltaTime, deltaX, deltaY);
        velocityX = v.x;
        velocityY = v.y;
        velocity = (abs(v.x) > abs(v.y)) ? v.x : v.y;
        direction = getDirection(deltaX, deltaY);

        session.lastInterval = input;
    } else {
        // use latest velocity info if it doesn't overtake a minimum period
        velocity = last.velocity;
        velocityX = last.velocityX;
        velocityY = last.velocityY;
        direction = last.direction;
    }

    input.velocity = velocity;
    input.velocityX = velocityX;
    input.velocityY = velocityY;
    input.direction = direction;
}

/**
 * create a simple clone from the input used for storage of firstInput and firstMultiple
 * @param {Object} input
 * @returns {Object} clonedInputData
 */
function simpleCloneInputData(input) {
    // make a simple copy of the pointers because we will get a reference if we don't
    // we only need clientXY for the calculations
    var pointers = [];
    var i = 0;
    while (i < input.pointers.length) {
        pointers[i] = {
            clientX: round(input.pointers[i].clientX),
            clientY: round(input.pointers[i].clientY)
        };
        i++;
    }

    return {
        timeStamp: now(),
        pointers: pointers,
        center: getCenter(pointers),
        deltaX: input.deltaX,
        deltaY: input.deltaY
    };
}

/**
 * get the center of all the pointers
 * @param {Array} pointers
 * @return {Object} center contains `x` and `y` properties
 */
function getCenter(pointers) {
    var pointersLength = pointers.length;

    // no need to loop when only one touch
    if (pointersLength === 1) {
        return {
            x: round(pointers[0].clientX),
            y: round(pointers[0].clientY)
        };
    }

    var x = 0, y = 0, i = 0;
    while (i < pointersLength) {
        x += pointers[i].clientX;
        y += pointers[i].clientY;
        i++;
    }

    return {
        x: round(x / pointersLength),
        y: round(y / pointersLength)
    };
}

/**
 * calculate the velocity between two points. unit is in px per ms.
 * @param {Number} deltaTime
 * @param {Number} x
 * @param {Number} y
 * @return {Object} velocity `x` and `y`
 */
function getVelocity(deltaTime, x, y) {
    return {
        x: x / deltaTime || 0,
        y: y / deltaTime || 0
    };
}

/**
 * get the direction between two points
 * @param {Number} x
 * @param {Number} y
 * @return {Number} direction
 */
function getDirection(x, y) {
    if (x === y) {
        return DIRECTION_NONE;
    }

    if (abs(x) >= abs(y)) {
        return x < 0 ? DIRECTION_LEFT : DIRECTION_RIGHT;
    }
    return y < 0 ? DIRECTION_UP : DIRECTION_DOWN;
}

/**
 * calculate the absolute distance between two points
 * @param {Object} p1 {x, y}
 * @param {Object} p2 {x, y}
 * @param {Array} [props] containing x and y keys
 * @return {Number} distance
 */
function getDistance(p1, p2, props) {
    if (!props) {
        props = PROPS_XY;
    }
    var x = p2[props[0]] - p1[props[0]],
        y = p2[props[1]] - p1[props[1]];

    return Math.sqrt((x * x) + (y * y));
}

/**
 * calculate the angle between two coordinates
 * @param {Object} p1
 * @param {Object} p2
 * @param {Array} [props] containing x and y keys
 * @return {Number} angle
 */
function getAngle(p1, p2, props) {
    if (!props) {
        props = PROPS_XY;
    }
    var x = p2[props[0]] - p1[props[0]],
        y = p2[props[1]] - p1[props[1]];
    return Math.atan2(y, x) * 180 / Math.PI;
}

/**
 * calculate the rotation degrees between two pointersets
 * @param {Array} start array of pointers
 * @param {Array} end array of pointers
 * @return {Number} rotation
 */
function getRotation(start, end) {
    return getAngle(end[1], end[0], PROPS_CLIENT_XY) + getAngle(start[1], start[0], PROPS_CLIENT_XY);
}

/**
 * calculate the scale factor between two pointersets
 * no scale is 1, and goes down to 0 when pinched together, and bigger when pinched out
 * @param {Array} start array of pointers
 * @param {Array} end array of pointers
 * @return {Number} scale
 */
function getScale(start, end) {
    return getDistance(end[0], end[1], PROPS_CLIENT_XY) / getDistance(start[0], start[1], PROPS_CLIENT_XY);
}

var MOUSE_INPUT_MAP = {
    mousedown: INPUT_START,
    mousemove: INPUT_MOVE,
    mouseup: INPUT_END
};

var MOUSE_ELEMENT_EVENTS = 'mousedown';
var MOUSE_WINDOW_EVENTS = 'mousemove mouseup';

/**
 * Mouse events input
 * @constructor
 * @extends Input
 */
function MouseInput() {
    this.evEl = MOUSE_ELEMENT_EVENTS;
    this.evWin = MOUSE_WINDOW_EVENTS;

    this.pressed = false; // mousedown state

    Input.apply(this, arguments);
}

inherit(MouseInput, Input, {
    /**
     * handle mouse events
     * @param {Object} ev
     */
    handler: function MEhandler(ev) {
        var eventType = MOUSE_INPUT_MAP[ev.type];

        // on start we want to have the left mouse button down
        if (eventType & INPUT_START && ev.button === 0) {
            this.pressed = true;
        }

        if (eventType & INPUT_MOVE && ev.which !== 1) {
            eventType = INPUT_END;
        }

        // mouse must be down
        if (!this.pressed) {
            return;
        }

        if (eventType & INPUT_END) {
            this.pressed = false;
        }

        this.callback(this.manager, eventType, {
            pointers: [ev],
            changedPointers: [ev],
            pointerType: INPUT_TYPE_MOUSE,
            srcEvent: ev
        });
    }
});

var POINTER_INPUT_MAP = {
    pointerdown: INPUT_START,
    pointermove: INPUT_MOVE,
    pointerup: INPUT_END,
    pointercancel: INPUT_CANCEL,
    pointerout: INPUT_CANCEL
};

// in IE10 the pointer types is defined as an enum
var IE10_POINTER_TYPE_ENUM = {
    2: INPUT_TYPE_TOUCH,
    3: INPUT_TYPE_PEN,
    4: INPUT_TYPE_MOUSE,
    5: INPUT_TYPE_KINECT // see https://twitter.com/jacobrossi/status/480596438489890816
};

var POINTER_ELEMENT_EVENTS = 'pointerdown';
var POINTER_WINDOW_EVENTS = 'pointermove pointerup pointercancel';

// IE10 has prefixed support, and case-sensitive
if (window.MSPointerEvent && !window.PointerEvent) {
    POINTER_ELEMENT_EVENTS = 'MSPointerDown';
    POINTER_WINDOW_EVENTS = 'MSPointerMove MSPointerUp MSPointerCancel';
}

/**
 * Pointer events input
 * @constructor
 * @extends Input
 */
function PointerEventInput() {
    this.evEl = POINTER_ELEMENT_EVENTS;
    this.evWin = POINTER_WINDOW_EVENTS;

    Input.apply(this, arguments);

    this.store = (this.manager.session.pointerEvents = []);
}

inherit(PointerEventInput, Input, {
    /**
     * handle mouse events
     * @param {Object} ev
     */
    handler: function PEhandler(ev) {
        var store = this.store;
        var removePointer = false;

        var eventTypeNormalized = ev.type.toLowerCase().replace('ms', '');
        var eventType = POINTER_INPUT_MAP[eventTypeNormalized];
        var pointerType = IE10_POINTER_TYPE_ENUM[ev.pointerType] || ev.pointerType;

        var isTouch = (pointerType == INPUT_TYPE_TOUCH);

        // get index of the event in the store
        var storeIndex = inArray(store, ev.pointerId, 'pointerId');

        // start and mouse must be down
        if (eventType & INPUT_START && (ev.button === 0 || isTouch)) {
            if (storeIndex < 0) {
                store.push(ev);
                storeIndex = store.length - 1;
            }
        } else if (eventType & (INPUT_END | INPUT_CANCEL)) {
            removePointer = true;
        }

        // it not found, so the pointer hasn't been down (so it's probably a hover)
        if (storeIndex < 0) {
            return;
        }

        // update the event in the store
        store[storeIndex] = ev;

        this.callback(this.manager, eventType, {
            pointers: store,
            changedPointers: [ev],
            pointerType: pointerType,
            srcEvent: ev
        });

        if (removePointer) {
            // remove from the store
            store.splice(storeIndex, 1);
        }
    }
});

var SINGLE_TOUCH_INPUT_MAP = {
    touchstart: INPUT_START,
    touchmove: INPUT_MOVE,
    touchend: INPUT_END,
    touchcancel: INPUT_CANCEL
};

var SINGLE_TOUCH_TARGET_EVENTS = 'touchstart';
var SINGLE_TOUCH_WINDOW_EVENTS = 'touchstart touchmove touchend touchcancel';

/**
 * Touch events input
 * @constructor
 * @extends Input
 */
function SingleTouchInput() {
    this.evTarget = SINGLE_TOUCH_TARGET_EVENTS;
    this.evWin = SINGLE_TOUCH_WINDOW_EVENTS;
    this.started = false;

    Input.apply(this, arguments);
}

inherit(SingleTouchInput, Input, {
    handler: function TEhandler(ev) {
        var type = SINGLE_TOUCH_INPUT_MAP[ev.type];

        // should we handle the touch events?
        if (type === INPUT_START) {
            this.started = true;
        }

        if (!this.started) {
            return;
        }

        var touches = normalizeSingleTouches.call(this, ev, type);

        // when done, reset the started state
        if (type & (INPUT_END | INPUT_CANCEL) && touches[0].length - touches[1].length === 0) {
            this.started = false;
        }

        this.callback(this.manager, type, {
            pointers: touches[0],
            changedPointers: touches[1],
            pointerType: INPUT_TYPE_TOUCH,
            srcEvent: ev
        });
    }
});

/**
 * @this {TouchInput}
 * @param {Object} ev
 * @param {Number} type flag
 * @returns {undefined|Array} [all, changed]
 */
function normalizeSingleTouches(ev, type) {
    var all = toArray(ev.touches);
    var changed = toArray(ev.changedTouches);

    if (type & (INPUT_END | INPUT_CANCEL)) {
        all = uniqueArray(all.concat(changed), 'identifier', true);
    }

    return [all, changed];
}

var TOUCH_INPUT_MAP = {
    touchstart: INPUT_START,
    touchmove: INPUT_MOVE,
    touchend: INPUT_END,
    touchcancel: INPUT_CANCEL
};

var TOUCH_TARGET_EVENTS = 'touchstart touchmove touchend touchcancel';

/**
 * Multi-user touch events input
 * @constructor
 * @extends Input
 */
function TouchInput() {
    this.evTarget = TOUCH_TARGET_EVENTS;
    this.targetIds = {};

    Input.apply(this, arguments);
}

inherit(TouchInput, Input, {
    handler: function MTEhandler(ev) {
        var type = TOUCH_INPUT_MAP[ev.type];
        var touches = getTouches.call(this, ev, type);
        if (!touches) {
            return;
        }

        this.callback(this.manager, type, {
            pointers: touches[0],
            changedPointers: touches[1],
            pointerType: INPUT_TYPE_TOUCH,
            srcEvent: ev
        });
    }
});

/**
 * @this {TouchInput}
 * @param {Object} ev
 * @param {Number} type flag
 * @returns {undefined|Array} [all, changed]
 */
function getTouches(ev, type) {
    var allTouches = toArray(ev.touches);
    var targetIds = this.targetIds;

    // when there is only one touch, the process can be simplified
    if (type & (INPUT_START | INPUT_MOVE) && allTouches.length === 1) {
        targetIds[allTouches[0].identifier] = true;
        return [allTouches, allTouches];
    }

    var i,
        targetTouches,
        changedTouches = toArray(ev.changedTouches),
        changedTargetTouches = [],
        target = this.target;

    // get target touches from touches
    targetTouches = allTouches.filter(function(touch) {
        return hasParent(touch.target, target);
    });

    // collect touches
    if (type === INPUT_START) {
        i = 0;
        while (i < targetTouches.length) {
            targetIds[targetTouches[i].identifier] = true;
            i++;
        }
    }

    // filter changed touches to only contain touches that exist in the collected target ids
    i = 0;
    while (i < changedTouches.length) {
        if (targetIds[changedTouches[i].identifier]) {
            changedTargetTouches.push(changedTouches[i]);
        }

        // cleanup removed touches
        if (type & (INPUT_END | INPUT_CANCEL)) {
            delete targetIds[changedTouches[i].identifier];
        }
        i++;
    }

    if (!changedTargetTouches.length) {
        return;
    }

    return [
        // merge targetTouches with changedTargetTouches so it contains ALL touches, including 'end' and 'cancel'
        uniqueArray(targetTouches.concat(changedTargetTouches), 'identifier', true),
        changedTargetTouches
    ];
}

/**
 * Combined touch and mouse input
 *
 * Touch has a higher priority then mouse, and while touching no mouse events are allowed.
 * This because touch devices also emit mouse events while doing a touch.
 *
 * @constructor
 * @extends Input
 */

var DEDUP_TIMEOUT = 2500;
var DEDUP_DISTANCE = 25;

function TouchMouseInput() {
    Input.apply(this, arguments);

    var handler = bindFn(this.handler, this);
    this.touch = new TouchInput(this.manager, handler);
    this.mouse = new MouseInput(this.manager, handler);

    this.primaryTouch = null;
    this.lastTouches = [];
}

inherit(TouchMouseInput, Input, {
    /**
     * handle mouse and touch events
     * @param {Hammer} manager
     * @param {String} inputEvent
     * @param {Object} inputData
     */
    handler: function TMEhandler(manager, inputEvent, inputData) {
        var isTouch = (inputData.pointerType == INPUT_TYPE_TOUCH),
            isMouse = (inputData.pointerType == INPUT_TYPE_MOUSE);

        if (isMouse && inputData.sourceCapabilities && inputData.sourceCapabilities.firesTouchEvents) {
            return;
        }

        // when we're in a touch event, record touches to  de-dupe synthetic mouse event
        if (isTouch) {
            recordTouches.call(this, inputEvent, inputData);
        } else if (isMouse && isSyntheticEvent.call(this, inputData)) {
            return;
        }

        this.callback(manager, inputEvent, inputData);
    },

    /**
     * remove the event listeners
     */
    destroy: function destroy() {
        this.touch.destroy();
        this.mouse.destroy();
    }
});

function recordTouches(eventType, eventData) {
    if (eventType & INPUT_START) {
        this.primaryTouch = eventData.changedPointers[0].identifier;
        setLastTouch.call(this, eventData);
    } else if (eventType & (INPUT_END | INPUT_CANCEL)) {
        setLastTouch.call(this, eventData);
    }
}

function setLastTouch(eventData) {
    var touch = eventData.changedPointers[0];

    if (touch.identifier === this.primaryTouch) {
        var lastTouch = {x: touch.clientX, y: touch.clientY};
        this.lastTouches.push(lastTouch);
        var lts = this.lastTouches;
        var removeLastTouch = function() {
            var i = lts.indexOf(lastTouch);
            if (i > -1) {
                lts.splice(i, 1);
            }
        };
        setTimeout(removeLastTouch, DEDUP_TIMEOUT);
    }
}

function isSyntheticEvent(eventData) {
    var x = eventData.srcEvent.clientX, y = eventData.srcEvent.clientY;
    for (var i = 0; i < this.lastTouches.length; i++) {
        var t = this.lastTouches[i];
        var dx = Math.abs(x - t.x), dy = Math.abs(y - t.y);
        if (dx <= DEDUP_DISTANCE && dy <= DEDUP_DISTANCE) {
            return true;
        }
    }
    return false;
}

var PREFIXED_TOUCH_ACTION = prefixed(TEST_ELEMENT.style, 'touchAction');
var NATIVE_TOUCH_ACTION = PREFIXED_TOUCH_ACTION !== undefined;

// magical touchAction value
var TOUCH_ACTION_COMPUTE = 'compute';
var TOUCH_ACTION_AUTO = 'auto';
var TOUCH_ACTION_MANIPULATION = 'manipulation'; // not implemented
var TOUCH_ACTION_NONE = 'none';
var TOUCH_ACTION_PAN_X = 'pan-x';
var TOUCH_ACTION_PAN_Y = 'pan-y';
var TOUCH_ACTION_MAP = getTouchActionProps();

/**
 * Touch Action
 * sets the touchAction property or uses the js alternative
 * @param {Manager} manager
 * @param {String} value
 * @constructor
 */
function TouchAction(manager, value) {
    this.manager = manager;
    this.set(value);
}

TouchAction.prototype = {
    /**
     * set the touchAction value on the element or enable the polyfill
     * @param {String} value
     */
    set: function(value) {
        // find out the touch-action by the event handlers
        if (value == TOUCH_ACTION_COMPUTE) {
            value = this.compute();
        }

        if (NATIVE_TOUCH_ACTION && this.manager.element.style && TOUCH_ACTION_MAP[value]) {
            this.manager.element.style[PREFIXED_TOUCH_ACTION] = value;
        }
        this.actions = value.toLowerCase().trim();
    },

    /**
     * just re-set the touchAction value
     */
    update: function() {
        this.set(this.manager.options.touchAction);
    },

    /**
     * compute the value for the touchAction property based on the recognizer's settings
     * @returns {String} value
     */
    compute: function() {
        var actions = [];
        each(this.manager.recognizers, function(recognizer) {
            if (boolOrFn(recognizer.options.enable, [recognizer])) {
                actions = actions.concat(recognizer.getTouchAction());
            }
        });
        return cleanTouchActions(actions.join(' '));
    },

    /**
     * this method is called on each input cycle and provides the preventing of the browser behavior
     * @param {Object} input
     */
    preventDefaults: function(input) {
        var srcEvent = input.srcEvent;
        var direction = input.offsetDirection;

        // if the touch action did prevented once this session
        if (this.manager.session.prevented) {
            srcEvent.preventDefault();
            return;
        }

        var actions = this.actions;
        var hasNone = inStr(actions, TOUCH_ACTION_NONE) && !TOUCH_ACTION_MAP[TOUCH_ACTION_NONE];
        var hasPanY = inStr(actions, TOUCH_ACTION_PAN_Y) && !TOUCH_ACTION_MAP[TOUCH_ACTION_PAN_Y];
        var hasPanX = inStr(actions, TOUCH_ACTION_PAN_X) && !TOUCH_ACTION_MAP[TOUCH_ACTION_PAN_X];

        if (hasNone) {
            //do not prevent defaults if this is a tap gesture

            var isTapPointer = input.pointers.length === 1;
            var isTapMovement = input.distance < 2;
            var isTapTouchTime = input.deltaTime < 250;

            if (isTapPointer && isTapMovement && isTapTouchTime) {
                return;
            }
        }

        if (hasPanX && hasPanY) {
            // `pan-x pan-y` means browser handles all scrolling/panning, do not prevent
            return;
        }

        if (hasNone ||
            (hasPanY && direction & DIRECTION_HORIZONTAL) ||
            (hasPanX && direction & DIRECTION_VERTICAL)) {
            return this.preventSrc(srcEvent);
        }
    },

    /**
     * call preventDefault to prevent the browser's default behavior (scrolling in most cases)
     * @param {Object} srcEvent
     */
    preventSrc: function(srcEvent) {
        this.manager.session.prevented = true;
        srcEvent.preventDefault();
    }
};

/**
 * when the touchActions are collected they are not a valid value, so we need to clean things up. *
 * @param {String} actions
 * @returns {*}
 */
function cleanTouchActions(actions) {
    // none
    if (inStr(actions, TOUCH_ACTION_NONE)) {
        return TOUCH_ACTION_NONE;
    }

    var hasPanX = inStr(actions, TOUCH_ACTION_PAN_X);
    var hasPanY = inStr(actions, TOUCH_ACTION_PAN_Y);

    // if both pan-x and pan-y are set (different recognizers
    // for different directions, e.g. horizontal pan but vertical swipe?)
    // we need none (as otherwise with pan-x pan-y combined none of these
    // recognizers will work, since the browser would handle all panning
    if (hasPanX && hasPanY) {
        return TOUCH_ACTION_NONE;
    }

    // pan-x OR pan-y
    if (hasPanX || hasPanY) {
        return hasPanX ? TOUCH_ACTION_PAN_X : TOUCH_ACTION_PAN_Y;
    }

    // manipulation
    if (inStr(actions, TOUCH_ACTION_MANIPULATION)) {
        return TOUCH_ACTION_MANIPULATION;
    }

    return TOUCH_ACTION_AUTO;
}

function getTouchActionProps() {
    if (!NATIVE_TOUCH_ACTION) {
        return false;
    }
    var touchMap = {};
    var cssSupports = window.CSS && window.CSS.supports;
    ['auto', 'manipulation', 'pan-y', 'pan-x', 'pan-x pan-y', 'none'].forEach(function(val) {

        // If css.supports is not supported but there is native touch-action assume it supports
        // all values. This is the case for IE 10 and 11.
        touchMap[val] = cssSupports ? window.CSS.supports('touch-action', val) : true;
    });
    return touchMap;
}

/**
 * Recognizer flow explained; *
 * All recognizers have the initial state of POSSIBLE when a input session starts.
 * The definition of a input session is from the first input until the last input, with all it's movement in it. *
 * Example session for mouse-input: mousedown -> mousemove -> mouseup
 *
 * On each recognizing cycle (see Manager.recognize) the .recognize() method is executed
 * which determines with state it should be.
 *
 * If the recognizer has the state FAILED, CANCELLED or RECOGNIZED (equals ENDED), it is reset to
 * POSSIBLE to give it another change on the next cycle.
 *
 *               Possible
 *                  |
 *            +-----+---------------+
 *            |                     |
 *      +-----+-----+               |
 *      |           |               |
 *   Failed      Cancelled          |
 *                          +-------+------+
 *                          |              |
 *                      Recognized       Began
 *                                         |
 *                                      Changed
 *                                         |
 *                                  Ended/Recognized
 */
var STATE_POSSIBLE = 1;
var STATE_BEGAN = 2;
var STATE_CHANGED = 4;
var STATE_ENDED = 8;
var STATE_RECOGNIZED = STATE_ENDED;
var STATE_CANCELLED = 16;
var STATE_FAILED = 32;

/**
 * Recognizer
 * Every recognizer needs to extend from this class.
 * @constructor
 * @param {Object} options
 */
function Recognizer(options) {
    this.options = assign({}, this.defaults, options || {});

    this.id = uniqueId();

    this.manager = null;

    // default is enable true
    this.options.enable = ifUndefined(this.options.enable, true);

    this.state = STATE_POSSIBLE;

    this.simultaneous = {};
    this.requireFail = [];
}

Recognizer.prototype = {
    /**
     * @virtual
     * @type {Object}
     */
    defaults: {},

    /**
     * set options
     * @param {Object} options
     * @return {Recognizer}
     */
    set: function(options) {
        assign(this.options, options);

        // also update the touchAction, in case something changed about the directions/enabled state
        this.manager && this.manager.touchAction.update();
        return this;
    },

    /**
     * recognize simultaneous with an other recognizer.
     * @param {Recognizer} otherRecognizer
     * @returns {Recognizer} this
     */
    recognizeWith: function(otherRecognizer) {
        if (invokeArrayArg(otherRecognizer, 'recognizeWith', this)) {
            return this;
        }

        var simultaneous = this.simultaneous;
        otherRecognizer = getRecognizerByNameIfManager(otherRecognizer, this);
        if (!simultaneous[otherRecognizer.id]) {
            simultaneous[otherRecognizer.id] = otherRecognizer;
            otherRecognizer.recognizeWith(this);
        }
        return this;
    },

    /**
     * drop the simultaneous link. it doesnt remove the link on the other recognizer.
     * @param {Recognizer} otherRecognizer
     * @returns {Recognizer} this
     */
    dropRecognizeWith: function(otherRecognizer) {
        if (invokeArrayArg(otherRecognizer, 'dropRecognizeWith', this)) {
            return this;
        }

        otherRecognizer = getRecognizerByNameIfManager(otherRecognizer, this);
        delete this.simultaneous[otherRecognizer.id];
        return this;
    },

    /**
     * recognizer can only run when an other is failing
     * @param {Recognizer} otherRecognizer
     * @returns {Recognizer} this
     */
    requireFailure: function(otherRecognizer) {
        if (invokeArrayArg(otherRecognizer, 'requireFailure', this)) {
            return this;
        }

        var requireFail = this.requireFail;
        otherRecognizer = getRecognizerByNameIfManager(otherRecognizer, this);
        if (inArray(requireFail, otherRecognizer) === -1) {
            requireFail.push(otherRecognizer);
            otherRecognizer.requireFailure(this);
        }
        return this;
    },

    /**
     * drop the requireFailure link. it does not remove the link on the other recognizer.
     * @param {Recognizer} otherRecognizer
     * @returns {Recognizer} this
     */
    dropRequireFailure: function(otherRecognizer) {
        if (invokeArrayArg(otherRecognizer, 'dropRequireFailure', this)) {
            return this;
        }

        otherRecognizer = getRecognizerByNameIfManager(otherRecognizer, this);
        var index = inArray(this.requireFail, otherRecognizer);
        if (index > -1) {
            this.requireFail.splice(index, 1);
        }
        return this;
    },

    /**
     * has require failures boolean
     * @returns {boolean}
     */
    hasRequireFailures: function() {
        return this.requireFail.length > 0;
    },

    /**
     * if the recognizer can recognize simultaneous with an other recognizer
     * @param {Recognizer} otherRecognizer
     * @returns {Boolean}
     */
    canRecognizeWith: function(otherRecognizer) {
        return !!this.simultaneous[otherRecognizer.id];
    },

    /**
     * You should use `tryEmit` instead of `emit` directly to check
     * that all the needed recognizers has failed before emitting.
     * @param {Object} input
     */
    emit: function(input) {
        var self = this;
        var state = this.state;

        function emit(event) {
            self.manager.emit(event, input);
        }

        // 'panstart' and 'panmove'
        if (state < STATE_ENDED) {
            emit(self.options.event + stateStr(state));
        }

        emit(self.options.event); // simple 'eventName' events

        if (input.additionalEvent) { // additional event(panleft, panright, pinchin, pinchout...)
            emit(input.additionalEvent);
        }

        // panend and pancancel
        if (state >= STATE_ENDED) {
            emit(self.options.event + stateStr(state));
        }
    },

    /**
     * Check that all the require failure recognizers has failed,
     * if true, it emits a gesture event,
     * otherwise, setup the state to FAILED.
     * @param {Object} input
     */
    tryEmit: function(input) {
        if (this.canEmit()) {
            return this.emit(input);
        }
        // it's failing anyway
        this.state = STATE_FAILED;
    },

    /**
     * can we emit?
     * @returns {boolean}
     */
    canEmit: function() {
        var i = 0;
        while (i < this.requireFail.length) {
            if (!(this.requireFail[i].state & (STATE_FAILED | STATE_POSSIBLE))) {
                return false;
            }
            i++;
        }
        return true;
    },

    /**
     * update the recognizer
     * @param {Object} inputData
     */
    recognize: function(inputData) {
        // make a new copy of the inputData
        // so we can change the inputData without messing up the other recognizers
        var inputDataClone = assign({}, inputData);

        // is is enabled and allow recognizing?
        if (!boolOrFn(this.options.enable, [this, inputDataClone])) {
            this.reset();
            this.state = STATE_FAILED;
            return;
        }

        // reset when we've reached the end
        if (this.state & (STATE_RECOGNIZED | STATE_CANCELLED | STATE_FAILED)) {
            this.state = STATE_POSSIBLE;
        }

        this.state = this.process(inputDataClone);

        // the recognizer has recognized a gesture
        // so trigger an event
        if (this.state & (STATE_BEGAN | STATE_CHANGED | STATE_ENDED | STATE_CANCELLED)) {
            this.tryEmit(inputDataClone);
        }
    },

    /**
     * return the state of the recognizer
     * the actual recognizing happens in this method
     * @virtual
     * @param {Object} inputData
     * @returns {Const} STATE
     */
    process: function(inputData) { }, // jshint ignore:line

    /**
     * return the preferred touch-action
     * @virtual
     * @returns {Array}
     */
    getTouchAction: function() { },

    /**
     * called when the gesture isn't allowed to recognize
     * like when another is being recognized or it is disabled
     * @virtual
     */
    reset: function() { }
};

/**
 * get a usable string, used as event postfix
 * @param {Const} state
 * @returns {String} state
 */
function stateStr(state) {
    if (state & STATE_CANCELLED) {
        return 'cancel';
    } else if (state & STATE_ENDED) {
        return 'end';
    } else if (state & STATE_CHANGED) {
        return 'move';
    } else if (state & STATE_BEGAN) {
        return 'start';
    }
    return '';
}

/**
 * direction cons to string
 * @param {Const} direction
 * @returns {String}
 */
function directionStr(direction) {
    if (direction == DIRECTION_DOWN) {
        return 'down';
    } else if (direction == DIRECTION_UP) {
        return 'up';
    } else if (direction == DIRECTION_LEFT) {
        return 'left';
    } else if (direction == DIRECTION_RIGHT) {
        return 'right';
    }
    return '';
}

/**
 * get a recognizer by name if it is bound to a manager
 * @param {Recognizer|String} otherRecognizer
 * @param {Recognizer} recognizer
 * @returns {Recognizer}
 */
function getRecognizerByNameIfManager(otherRecognizer, recognizer) {
    var manager = recognizer.manager;
    if (manager) {
        return manager.get(otherRecognizer);
    }
    return otherRecognizer;
}

/**
 * This recognizer is just used as a base for the simple attribute recognizers.
 * @constructor
 * @extends Recognizer
 */
function AttrRecognizer() {
    Recognizer.apply(this, arguments);
}

inherit(AttrRecognizer, Recognizer, {
    /**
     * @namespace
     * @memberof AttrRecognizer
     */
    defaults: {
        /**
         * @type {Number}
         * @default 1
         */
        pointers: 1
    },

    /**
     * Used to check if it the recognizer receives valid input, like input.distance > 10.
     * @memberof AttrRecognizer
     * @param {Object} input
     * @returns {Boolean} recognized
     */
    attrTest: function(input) {
        var optionPointers = this.options.pointers;
        return optionPointers === 0 || input.pointers.length === optionPointers;
    },

    /**
     * Process the input and return the state for the recognizer
     * @memberof AttrRecognizer
     * @param {Object} input
     * @returns {*} State
     */
    process: function(input) {
        var state = this.state;
        var eventType = input.eventType;

        var isRecognized = state & (STATE_BEGAN | STATE_CHANGED);
        var isValid = this.attrTest(input);

        // on cancel input and we've recognized before, return STATE_CANCELLED
        if (isRecognized && (eventType & INPUT_CANCEL || !isValid)) {
            return state | STATE_CANCELLED;
        } else if (isRecognized || isValid) {
            if (eventType & INPUT_END) {
                return state | STATE_ENDED;
            } else if (!(state & STATE_BEGAN)) {
                return STATE_BEGAN;
            }
            return state | STATE_CHANGED;
        }
        return STATE_FAILED;
    }
});

/**
 * Pan
 * Recognized when the pointer is down and moved in the allowed direction.
 * @constructor
 * @extends AttrRecognizer
 */
function PanRecognizer() {
    AttrRecognizer.apply(this, arguments);

    this.pX = null;
    this.pY = null;
}

inherit(PanRecognizer, AttrRecognizer, {
    /**
     * @namespace
     * @memberof PanRecognizer
     */
    defaults: {
        event: 'pan',
        threshold: 10,
        pointers: 1,
        direction: DIRECTION_ALL
    },

    getTouchAction: function() {
        var direction = this.options.direction;
        var actions = [];
        if (direction & DIRECTION_HORIZONTAL) {
            actions.push(TOUCH_ACTION_PAN_Y);
        }
        if (direction & DIRECTION_VERTICAL) {
            actions.push(TOUCH_ACTION_PAN_X);
        }
        return actions;
    },

    directionTest: function(input) {
        var options = this.options;
        var hasMoved = true;
        var distance = input.distance;
        var direction = input.direction;
        var x = input.deltaX;
        var y = input.deltaY;

        // lock to axis?
        if (!(direction & options.direction)) {
            if (options.direction & DIRECTION_HORIZONTAL) {
                direction = (x === 0) ? DIRECTION_NONE : (x < 0) ? DIRECTION_LEFT : DIRECTION_RIGHT;
                hasMoved = x != this.pX;
                distance = Math.abs(input.deltaX);
            } else {
                direction = (y === 0) ? DIRECTION_NONE : (y < 0) ? DIRECTION_UP : DIRECTION_DOWN;
                hasMoved = y != this.pY;
                distance = Math.abs(input.deltaY);
            }
        }
        input.direction = direction;
        return hasMoved && distance > options.threshold && direction & options.direction;
    },

    attrTest: function(input) {
        return AttrRecognizer.prototype.attrTest.call(this, input) &&
            (this.state & STATE_BEGAN || (!(this.state & STATE_BEGAN) && this.directionTest(input)));
    },

    emit: function(input) {

        this.pX = input.deltaX;
        this.pY = input.deltaY;

        var direction = directionStr(input.direction);

        if (direction) {
            input.additionalEvent = this.options.event + direction;
        }
        this._super.emit.call(this, input);
    }
});

/**
 * Pinch
 * Recognized when two or more pointers are moving toward (zoom-in) or away from each other (zoom-out).
 * @constructor
 * @extends AttrRecognizer
 */
function PinchRecognizer() {
    AttrRecognizer.apply(this, arguments);
}

inherit(PinchRecognizer, AttrRecognizer, {
    /**
     * @namespace
     * @memberof PinchRecognizer
     */
    defaults: {
        event: 'pinch',
        threshold: 0,
        pointers: 2
    },

    getTouchAction: function() {
        return [TOUCH_ACTION_NONE];
    },

    attrTest: function(input) {
        return this._super.attrTest.call(this, input) &&
            (Math.abs(input.scale - 1) > this.options.threshold || this.state & STATE_BEGAN);
    },

    emit: function(input) {
        if (input.scale !== 1) {
            var inOut = input.scale < 1 ? 'in' : 'out';
            input.additionalEvent = this.options.event + inOut;
        }
        this._super.emit.call(this, input);
    }
});

/**
 * Press
 * Recognized when the pointer is down for x ms without any movement.
 * @constructor
 * @extends Recognizer
 */
function PressRecognizer() {
    Recognizer.apply(this, arguments);

    this._timer = null;
    this._input = null;
}

inherit(PressRecognizer, Recognizer, {
    /**
     * @namespace
     * @memberof PressRecognizer
     */
    defaults: {
        event: 'press',
        pointers: 1,
        time: 251, // minimal time of the pointer to be pressed
        threshold: 9 // a minimal movement is ok, but keep it low
    },

    getTouchAction: function() {
        return [TOUCH_ACTION_AUTO];
    },

    process: function(input) {
        var options = this.options;
        var validPointers = input.pointers.length === options.pointers;
        var validMovement = input.distance < options.threshold;
        var validTime = input.deltaTime > options.time;

        this._input = input;

        // we only allow little movement
        // and we've reached an end event, so a tap is possible
        if (!validMovement || !validPointers || (input.eventType & (INPUT_END | INPUT_CANCEL) && !validTime)) {
            this.reset();
        } else if (input.eventType & INPUT_START) {
            this.reset();
            this._timer = setTimeoutContext(function() {
                this.state = STATE_RECOGNIZED;
                this.tryEmit();
            }, options.time, this);
        } else if (input.eventType & INPUT_END) {
            return STATE_RECOGNIZED;
        }
        return STATE_FAILED;
    },

    reset: function() {
        clearTimeout(this._timer);
    },

    emit: function(input) {
        if (this.state !== STATE_RECOGNIZED) {
            return;
        }

        if (input && (input.eventType & INPUT_END)) {
            this.manager.emit(this.options.event + 'up', input);
        } else {
            this._input.timeStamp = now();
            this.manager.emit(this.options.event, this._input);
        }
    }
});

/**
 * Rotate
 * Recognized when two or more pointer are moving in a circular motion.
 * @constructor
 * @extends AttrRecognizer
 */
function RotateRecognizer() {
    AttrRecognizer.apply(this, arguments);
}

inherit(RotateRecognizer, AttrRecognizer, {
    /**
     * @namespace
     * @memberof RotateRecognizer
     */
    defaults: {
        event: 'rotate',
        threshold: 0,
        pointers: 2
    },

    getTouchAction: function() {
        return [TOUCH_ACTION_NONE];
    },

    attrTest: function(input) {
        return this._super.attrTest.call(this, input) &&
            (Math.abs(input.rotation) > this.options.threshold || this.state & STATE_BEGAN);
    }
});

/**
 * Swipe
 * Recognized when the pointer is moving fast (velocity), with enough distance in the allowed direction.
 * @constructor
 * @extends AttrRecognizer
 */
function SwipeRecognizer() {
    AttrRecognizer.apply(this, arguments);
}

inherit(SwipeRecognizer, AttrRecognizer, {
    /**
     * @namespace
     * @memberof SwipeRecognizer
     */
    defaults: {
        event: 'swipe',
        threshold: 10,
        velocity: 0.3,
        direction: DIRECTION_HORIZONTAL | DIRECTION_VERTICAL,
        pointers: 1
    },

    getTouchAction: function() {
        return PanRecognizer.prototype.getTouchAction.call(this);
    },

    attrTest: function(input) {
        var direction = this.options.direction;
        var velocity;

        if (direction & (DIRECTION_HORIZONTAL | DIRECTION_VERTICAL)) {
            velocity = input.overallVelocity;
        } else if (direction & DIRECTION_HORIZONTAL) {
            velocity = input.overallVelocityX;
        } else if (direction & DIRECTION_VERTICAL) {
            velocity = input.overallVelocityY;
        }

        return this._super.attrTest.call(this, input) &&
            direction & input.offsetDirection &&
            input.distance > this.options.threshold &&
            input.maxPointers == this.options.pointers &&
            abs(velocity) > this.options.velocity && input.eventType & INPUT_END;
    },

    emit: function(input) {
        var direction = directionStr(input.offsetDirection);
        if (direction) {
            this.manager.emit(this.options.event + direction, input);
        }

        this.manager.emit(this.options.event, input);
    }
});

/**
 * A tap is ecognized when the pointer is doing a small tap/click. Multiple taps are recognized if they occur
 * between the given interval and position. The delay option can be used to recognize multi-taps without firing
 * a single tap.
 *
 * The eventData from the emitted event contains the property `tapCount`, which contains the amount of
 * multi-taps being recognized.
 * @constructor
 * @extends Recognizer
 */
function TapRecognizer() {
    Recognizer.apply(this, arguments);

    // previous time and center,
    // used for tap counting
    this.pTime = false;
    this.pCenter = false;

    this._timer = null;
    this._input = null;
    this.count = 0;
}

inherit(TapRecognizer, Recognizer, {
    /**
     * @namespace
     * @memberof PinchRecognizer
     */
    defaults: {
        event: 'tap',
        pointers: 1,
        taps: 1,
        interval: 300, // max time between the multi-tap taps
        time: 250, // max time of the pointer to be down (like finger on the screen)
        threshold: 9, // a minimal movement is ok, but keep it low
        posThreshold: 10 // a multi-tap can be a bit off the initial position
    },

    getTouchAction: function() {
        return [TOUCH_ACTION_MANIPULATION];
    },

    process: function(input) {
        var options = this.options;

        var validPointers = input.pointers.length === options.pointers;
        var validMovement = input.distance < options.threshold;
        var validTouchTime = input.deltaTime < options.time;

        this.reset();

        if ((input.eventType & INPUT_START) && (this.count === 0)) {
            return this.failTimeout();
        }

        // we only allow little movement
        // and we've reached an end event, so a tap is possible
        if (validMovement && validTouchTime && validPointers) {
            if (input.eventType != INPUT_END) {
                return this.failTimeout();
            }

            var validInterval = this.pTime ? (input.timeStamp - this.pTime < options.interval) : true;
            var validMultiTap = !this.pCenter || getDistance(this.pCenter, input.center) < options.posThreshold;

            this.pTime = input.timeStamp;
            this.pCenter = input.center;

            if (!validMultiTap || !validInterval) {
                this.count = 1;
            } else {
                this.count += 1;
            }

            this._input = input;

            // if tap count matches we have recognized it,
            // else it has began recognizing...
            var tapCount = this.count % options.taps;
            if (tapCount === 0) {
                // no failing requirements, immediately trigger the tap event
                // or wait as long as the multitap interval to trigger
                if (!this.hasRequireFailures()) {
                    return STATE_RECOGNIZED;
                } else {
                    this._timer = setTimeoutContext(function() {
                        this.state = STATE_RECOGNIZED;
                        this.tryEmit();
                    }, options.interval, this);
                    return STATE_BEGAN;
                }
            }
        }
        return STATE_FAILED;
    },

    failTimeout: function() {
        this._timer = setTimeoutContext(function() {
            this.state = STATE_FAILED;
        }, this.options.interval, this);
        return STATE_FAILED;
    },

    reset: function() {
        clearTimeout(this._timer);
    },

    emit: function() {
        if (this.state == STATE_RECOGNIZED) {
            this._input.tapCount = this.count;
            this.manager.emit(this.options.event, this._input);
        }
    }
});

/**
 * Simple way to create a manager with a default set of recognizers.
 * @param {HTMLElement} element
 * @param {Object} [options]
 * @constructor
 */
function Hammer(element, options) {
    options = options || {};
    options.recognizers = ifUndefined(options.recognizers, Hammer.defaults.preset);
    return new Manager(element, options);
}

/**
 * @const {string}
 */
Hammer.VERSION = '2.0.7';

/**
 * default settings
 * @namespace
 */
Hammer.defaults = {
    /**
     * set if DOM events are being triggered.
     * But this is slower and unused by simple implementations, so disabled by default.
     * @type {Boolean}
     * @default false
     */
    domEvents: false,

    /**
     * The value for the touchAction property/fallback.
     * When set to `compute` it will magically set the correct value based on the added recognizers.
     * @type {String}
     * @default compute
     */
    touchAction: TOUCH_ACTION_COMPUTE,

    /**
     * @type {Boolean}
     * @default true
     */
    enable: true,

    /**
     * EXPERIMENTAL FEATURE -- can be removed/changed
     * Change the parent input target element.
     * If Null, then it is being set the to main element.
     * @type {Null|EventTarget}
     * @default null
     */
    inputTarget: null,

    /**
     * force an input class
     * @type {Null|Function}
     * @default null
     */
    inputClass: null,

    /**
     * Default recognizer setup when calling `Hammer()`
     * When creating a new Manager these will be skipped.
     * @type {Array}
     */
    preset: [
        // RecognizerClass, options, [recognizeWith, ...], [requireFailure, ...]
        [RotateRecognizer, {enable: false}],
        [PinchRecognizer, {enable: false}, ['rotate']],
        [SwipeRecognizer, {direction: DIRECTION_HORIZONTAL}],
        [PanRecognizer, {direction: DIRECTION_HORIZONTAL}, ['swipe']],
        [TapRecognizer],
        [TapRecognizer, {event: 'doubletap', taps: 2}, ['tap']],
        [PressRecognizer]
    ],

    /**
     * Some CSS properties can be used to improve the working of Hammer.
     * Add them to this method and they will be set when creating a new Manager.
     * @namespace
     */
    cssProps: {
        /**
         * Disables text selection to improve the dragging gesture. Mainly for desktop browsers.
         * @type {String}
         * @default 'none'
         */
        userSelect: 'none',

        /**
         * Disable the Windows Phone grippers when pressing an element.
         * @type {String}
         * @default 'none'
         */
        touchSelect: 'none',

        /**
         * Disables the default callout shown when you touch and hold a touch target.
         * On iOS, when you touch and hold a touch target such as a link, Safari displays
         * a callout containing information about the link. This property allows you to disable that callout.
         * @type {String}
         * @default 'none'
         */
        touchCallout: 'none',

        /**
         * Specifies whether zooming is enabled. Used by IE10>
         * @type {String}
         * @default 'none'
         */
        contentZooming: 'none',

        /**
         * Specifies that an entire element should be draggable instead of its contents. Mainly for desktop browsers.
         * @type {String}
         * @default 'none'
         */
        userDrag: 'none',

        /**
         * Overrides the highlight color shown when the user taps a link or a JavaScript
         * clickable element in iOS. This property obeys the alpha value, if specified.
         * @type {String}
         * @default 'rgba(0,0,0,0)'
         */
        tapHighlightColor: 'rgba(0,0,0,0)'
    }
};

var STOP = 1;
var FORCED_STOP = 2;

/**
 * Manager
 * @param {HTMLElement} element
 * @param {Object} [options]
 * @constructor
 */
function Manager(element, options) {
    this.options = assign({}, Hammer.defaults, options || {});

    this.options.inputTarget = this.options.inputTarget || element;

    this.handlers = {};
    this.session = {};
    this.recognizers = [];
    this.oldCssProps = {};

    this.element = element;
    this.input = createInputInstance(this);
    this.touchAction = new TouchAction(this, this.options.touchAction);

    toggleCssProps(this, true);

    each(this.options.recognizers, function(item) {
        var recognizer = this.add(new (item[0])(item[1]));
        item[2] && recognizer.recognizeWith(item[2]);
        item[3] && recognizer.requireFailure(item[3]);
    }, this);
}

Manager.prototype = {
    /**
     * set options
     * @param {Object} options
     * @returns {Manager}
     */
    set: function(options) {
        assign(this.options, options);

        // Options that need a little more setup
        if (options.touchAction) {
            this.touchAction.update();
        }
        if (options.inputTarget) {
            // Clean up existing event listeners and reinitialize
            this.input.destroy();
            this.input.target = options.inputTarget;
            this.input.init();
        }
        return this;
    },

    /**
     * stop recognizing for this session.
     * This session will be discarded, when a new [input]start event is fired.
     * When forced, the recognizer cycle is stopped immediately.
     * @param {Boolean} [force]
     */
    stop: function(force) {
        this.session.stopped = force ? FORCED_STOP : STOP;
    },

    /**
     * run the recognizers!
     * called by the inputHandler function on every movement of the pointers (touches)
     * it walks through all the recognizers and tries to detect the gesture that is being made
     * @param {Object} inputData
     */
    recognize: function(inputData) {
        var session = this.session;
        if (session.stopped) {
            return;
        }

        // run the touch-action polyfill
        this.touchAction.preventDefaults(inputData);

        var recognizer;
        var recognizers = this.recognizers;

        // this holds the recognizer that is being recognized.
        // so the recognizer's state needs to be BEGAN, CHANGED, ENDED or RECOGNIZED
        // if no recognizer is detecting a thing, it is set to `null`
        var curRecognizer = session.curRecognizer;

        // reset when the last recognizer is recognized
        // or when we're in a new session
        if (!curRecognizer || (curRecognizer && curRecognizer.state & STATE_RECOGNIZED)) {
            curRecognizer = session.curRecognizer = null;
        }

        var i = 0;
        while (i < recognizers.length) {
            recognizer = recognizers[i];

            // find out if we are allowed try to recognize the input for this one.
            // 1.   allow if the session is NOT forced stopped (see the .stop() method)
            // 2.   allow if we still haven't recognized a gesture in this session, or the this recognizer is the one
            //      that is being recognized.
            // 3.   allow if the recognizer is allowed to run simultaneous with the current recognized recognizer.
            //      this can be setup with the `recognizeWith()` method on the recognizer.
            if (session.stopped !== FORCED_STOP && ( // 1
                    !curRecognizer || recognizer == curRecognizer || // 2
                    recognizer.canRecognizeWith(curRecognizer))) { // 3
                recognizer.recognize(inputData);
            } else {
                recognizer.reset();
            }

            // if the recognizer has been recognizing the input as a valid gesture, we want to store this one as the
            // current active recognizer. but only if we don't already have an active recognizer
            if (!curRecognizer && recognizer.state & (STATE_BEGAN | STATE_CHANGED | STATE_ENDED)) {
                curRecognizer = session.curRecognizer = recognizer;
            }
            i++;
        }
    },

    /**
     * get a recognizer by its event name.
     * @param {Recognizer|String} recognizer
     * @returns {Recognizer|Null}
     */
    get: function(recognizer) {
        if (recognizer instanceof Recognizer) {
            return recognizer;
        }

        var recognizers = this.recognizers;
        for (var i = 0; i < recognizers.length; i++) {
            if (recognizers[i].options.event == recognizer) {
                return recognizers[i];
            }
        }
        return null;
    },

    /**
     * add a recognizer to the manager
     * existing recognizers with the same event name will be removed
     * @param {Recognizer} recognizer
     * @returns {Recognizer|Manager}
     */
    add: function(recognizer) {
        if (invokeArrayArg(recognizer, 'add', this)) {
            return this;
        }

        // remove existing
        var existing = this.get(recognizer.options.event);
        if (existing) {
            this.remove(existing);
        }

        this.recognizers.push(recognizer);
        recognizer.manager = this;

        this.touchAction.update();
        return recognizer;
    },

    /**
     * remove a recognizer by name or instance
     * @param {Recognizer|String} recognizer
     * @returns {Manager}
     */
    remove: function(recognizer) {
        if (invokeArrayArg(recognizer, 'remove', this)) {
            return this;
        }

        recognizer = this.get(recognizer);

        // let's make sure this recognizer exists
        if (recognizer) {
            var recognizers = this.recognizers;
            var index = inArray(recognizers, recognizer);

            if (index !== -1) {
                recognizers.splice(index, 1);
                this.touchAction.update();
            }
        }

        return this;
    },

    /**
     * bind event
     * @param {String} events
     * @param {Function} handler
     * @returns {EventEmitter} this
     */
    on: function(events, handler) {
        if (events === undefined) {
            return;
        }
        if (handler === undefined) {
            return;
        }

        var handlers = this.handlers;
        each(splitStr(events), function(event) {
            handlers[event] = handlers[event] || [];
            handlers[event].push(handler);
        });
        return this;
    },

    /**
     * unbind event, leave emit blank to remove all handlers
     * @param {String} events
     * @param {Function} [handler]
     * @returns {EventEmitter} this
     */
    off: function(events, handler) {
        if (events === undefined) {
            return;
        }

        var handlers = this.handlers;
        each(splitStr(events), function(event) {
            if (!handler) {
                delete handlers[event];
            } else {
                handlers[event] && handlers[event].splice(inArray(handlers[event], handler), 1);
            }
        });
        return this;
    },

    /**
     * emit event to the listeners
     * @param {String} event
     * @param {Object} data
     */
    emit: function(event, data) {
        // we also want to trigger dom events
        if (this.options.domEvents) {
            triggerDomEvent(event, data);
        }

        // no handlers, so skip it all
        var handlers = this.handlers[event] && this.handlers[event].slice();
        if (!handlers || !handlers.length) {
            return;
        }

        data.type = event;
        data.preventDefault = function() {
            data.srcEvent.preventDefault();
        };

        var i = 0;
        while (i < handlers.length) {
            handlers[i](data);
            i++;
        }
    },

    /**
     * destroy the manager and unbinds all events
     * it doesn't unbind dom events, that is the user own responsibility
     */
    destroy: function() {
        this.element && toggleCssProps(this, false);

        this.handlers = {};
        this.session = {};
        this.input.destroy();
        this.element = null;
    }
};

/**
 * add/remove the css properties as defined in manager.options.cssProps
 * @param {Manager} manager
 * @param {Boolean} add
 */
function toggleCssProps(manager, add) {
    var element = manager.element;
    if (!element.style) {
        return;
    }
    var prop;
    each(manager.options.cssProps, function(value, name) {
        prop = prefixed(element.style, name);
        if (add) {
            manager.oldCssProps[prop] = element.style[prop];
            element.style[prop] = value;
        } else {
            element.style[prop] = manager.oldCssProps[prop] || '';
        }
    });
    if (!add) {
        manager.oldCssProps = {};
    }
}

/**
 * trigger dom event
 * @param {String} event
 * @param {Object} data
 */
function triggerDomEvent(event, data) {
    var gestureEvent = document.createEvent('Event');
    gestureEvent.initEvent(event, true, true);
    gestureEvent.gesture = data;
    data.target.dispatchEvent(gestureEvent);
}

assign(Hammer, {
    INPUT_START: INPUT_START,
    INPUT_MOVE: INPUT_MOVE,
    INPUT_END: INPUT_END,
    INPUT_CANCEL: INPUT_CANCEL,

    STATE_POSSIBLE: STATE_POSSIBLE,
    STATE_BEGAN: STATE_BEGAN,
    STATE_CHANGED: STATE_CHANGED,
    STATE_ENDED: STATE_ENDED,
    STATE_RECOGNIZED: STATE_RECOGNIZED,
    STATE_CANCELLED: STATE_CANCELLED,
    STATE_FAILED: STATE_FAILED,

    DIRECTION_NONE: DIRECTION_NONE,
    DIRECTION_LEFT: DIRECTION_LEFT,
    DIRECTION_RIGHT: DIRECTION_RIGHT,
    DIRECTION_UP: DIRECTION_UP,
    DIRECTION_DOWN: DIRECTION_DOWN,
    DIRECTION_HORIZONTAL: DIRECTION_HORIZONTAL,
    DIRECTION_VERTICAL: DIRECTION_VERTICAL,
    DIRECTION_ALL: DIRECTION_ALL,

    Manager: Manager,
    Input: Input,
    TouchAction: TouchAction,

    TouchInput: TouchInput,
    MouseInput: MouseInput,
    PointerEventInput: PointerEventInput,
    TouchMouseInput: TouchMouseInput,
    SingleTouchInput: SingleTouchInput,

    Recognizer: Recognizer,
    AttrRecognizer: AttrRecognizer,
    Tap: TapRecognizer,
    Pan: PanRecognizer,
    Swipe: SwipeRecognizer,
    Pinch: PinchRecognizer,
    Rotate: RotateRecognizer,
    Press: PressRecognizer,

    on: addEventListeners,
    off: removeEventListeners,
    each: each,
    merge: merge,
    extend: extend,
    assign: assign,
    inherit: inherit,
    bindFn: bindFn,
    prefixed: prefixed
});

// this prevents errors when Hammer is loaded in the presence of an AMD
//  style loader but by script tag, not by the loader.
var freeGlobal = (typeof window !== 'undefined' ? window : (typeof self !== 'undefined' ? self : {})); // jshint ignore:line
freeGlobal.Hammer = Hammer;

if (true) {
    !(__WEBPACK_AMD_DEFINE_RESULT__ = (function() {
        return Hammer;
    }).call(exports, __webpack_require__, exports, module),
				__WEBPACK_AMD_DEFINE_RESULT__ !== undefined && (module.exports = __WEBPACK_AMD_DEFINE_RESULT__));
} else {}

})(window, document, 'Hammer');


/***/ }),

/***/ 2823:
/***/ (function(module, exports, __webpack_require__) {

var baseHas = __webpack_require__(2824),
    hasPath = __webpack_require__(761);

/**
 * Checks if `path` is a direct property of `object`.
 *
 * @static
 * @since 0.1.0
 * @memberOf _
 * @category Object
 * @param {Object} object The object to query.
 * @param {Array|string} path The path to check.
 * @returns {boolean} Returns `true` if `path` exists, else `false`.
 * @example
 *
 * var object = { 'a': { 'b': 2 } };
 * var other = _.create({ 'a': _.create({ 'b': 2 }) });
 *
 * _.has(object, 'a');
 * // => true
 *
 * _.has(object, 'a.b');
 * // => true
 *
 * _.has(object, ['a', 'b']);
 * // => true
 *
 * _.has(other, 'a');
 * // => false
 */
function has(object, path) {
  return object != null && hasPath(object, path, baseHas);
}

module.exports = has;


/***/ }),

/***/ 2824:
/***/ (function(module, exports) {

/** Used for built-in method references. */
var objectProto = Object.prototype;

/** Used to check objects for own properties. */
var hasOwnProperty = objectProto.hasOwnProperty;

/**
 * The base implementation of `_.has` without support for deep paths.
 *
 * @private
 * @param {Object} [object] The object to query.
 * @param {Array|string} key The key to check.
 * @returns {boolean} Returns `true` if `key` exists, else `false`.
 */
function baseHas(object, key) {
  return object != null && hasOwnProperty.call(object, key);
}

module.exports = baseHas;


/***/ }),

/***/ 2876:
/***/ (function(module, exports, __webpack_require__) {

var createRound = __webpack_require__(2877);

/**
 * Computes `number` rounded to `precision`.
 *
 * @static
 * @memberOf _
 * @since 3.10.0
 * @category Math
 * @param {number} number The number to round.
 * @param {number} [precision=0] The precision to round to.
 * @returns {number} Returns the rounded number.
 * @example
 *
 * _.round(4.006);
 * // => 4
 *
 * _.round(4.006, 2);
 * // => 4.01
 *
 * _.round(4060, -2);
 * // => 4100
 */
var round = createRound('round');

module.exports = round;


/***/ }),

/***/ 2877:
/***/ (function(module, exports, __webpack_require__) {

var toInteger = __webpack_require__(190),
    toNumber = __webpack_require__(398),
    toString = __webpack_require__(189);

/* Built-in method references for those with the same name as other `lodash` methods. */
var nativeMin = Math.min;

/**
 * Creates a function like `_.round`.
 *
 * @private
 * @param {string} methodName The name of the `Math` method to use when rounding.
 * @returns {Function} Returns the new round function.
 */
function createRound(methodName) {
  var func = Math[methodName];
  return function(number, precision) {
    number = toNumber(number);
    precision = precision == null ? 0 : nativeMin(toInteger(precision), 292);
    if (precision) {
      // Shift with exponential notation to avoid floating-point issues.
      // See [MDN](https://mdn.io/round#Examples) for more details.
      var pair = (toString(number) + 'e').split('e'),
          value = func(pair[0] + 'e' + (+pair[1] + precision));

      pair = (toString(value) + 'e').split('e');
      return +(pair[0] + 'e' + (+pair[1] - precision));
    }
    return func(number);
  };
}

module.exports = createRound;


/***/ }),

/***/ 2881:
/***/ (function(module, exports, __webpack_require__) {

var baseUniq = __webpack_require__(729);

/**
 * This method is like `_.uniq` except that it accepts `comparator` which
 * is invoked to compare elements of `array`. The order of result values is
 * determined by the order they occur in the array.The comparator is invoked
 * with two arguments: (arrVal, othVal).
 *
 * @static
 * @memberOf _
 * @since 4.0.0
 * @category Array
 * @param {Array} array The array to inspect.
 * @param {Function} [comparator] The comparator invoked per element.
 * @returns {Array} Returns the new duplicate free array.
 * @example
 *
 * var objects = [{ 'x': 1, 'y': 2 }, { 'x': 2, 'y': 1 }, { 'x': 1, 'y': 2 }];
 *
 * _.uniqWith(objects, _.isEqual);
 * // => [{ 'x': 1, 'y': 2 }, { 'x': 2, 'y': 1 }]
 */
function uniqWith(array, comparator) {
  comparator = typeof comparator == 'function' ? comparator : undefined;
  return (array && array.length) ? baseUniq(array, undefined, comparator) : [];
}

module.exports = uniqWith;


/***/ }),

/***/ 2885:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
// Top level file is just a mixin of submodules & constants


var assign    = __webpack_require__(1624).assign;

var deflate   = __webpack_require__(2886);
var inflate   = __webpack_require__(2889);
var constants = __webpack_require__(2020);

var pako = {};

assign(pako, deflate, inflate, constants);

module.exports = pako;


/***/ }),

/***/ 2886:
/***/ (function(module, exports, __webpack_require__) {

"use strict";



var zlib_deflate = __webpack_require__(2887);
var utils        = __webpack_require__(1624);
var strings      = __webpack_require__(2018);
var msg          = __webpack_require__(1795);
var ZStream      = __webpack_require__(2019);

var toString = Object.prototype.toString;

/* Public constants ==========================================================*/
/* ===========================================================================*/

var Z_NO_FLUSH      = 0;
var Z_FINISH        = 4;

var Z_OK            = 0;
var Z_STREAM_END    = 1;
var Z_SYNC_FLUSH    = 2;

var Z_DEFAULT_COMPRESSION = -1;

var Z_DEFAULT_STRATEGY    = 0;

var Z_DEFLATED  = 8;

/* ===========================================================================*/


/**
 * class Deflate
 *
 * Generic JS-style wrapper for zlib calls. If you don't need
 * streaming behaviour - use more simple functions: [[deflate]],
 * [[deflateRaw]] and [[gzip]].
 **/

/* internal
 * Deflate.chunks -> Array
 *
 * Chunks of output data, if [[Deflate#onData]] not overridden.
 **/

/**
 * Deflate.result -> Uint8Array|Array
 *
 * Compressed result, generated by default [[Deflate#onData]]
 * and [[Deflate#onEnd]] handlers. Filled after you push last chunk
 * (call [[Deflate#push]] with `Z_FINISH` / `true` param)  or if you
 * push a chunk with explicit flush (call [[Deflate#push]] with
 * `Z_SYNC_FLUSH` param).
 **/

/**
 * Deflate.err -> Number
 *
 * Error code after deflate finished. 0 (Z_OK) on success.
 * You will not need it in real life, because deflate errors
 * are possible only on wrong options or bad `onData` / `onEnd`
 * custom handlers.
 **/

/**
 * Deflate.msg -> String
 *
 * Error message, if [[Deflate.err]] != 0
 **/


/**
 * new Deflate(options)
 * - options (Object): zlib deflate options.
 *
 * Creates new deflator instance with specified params. Throws exception
 * on bad params. Supported options:
 *
 * - `level`
 * - `windowBits`
 * - `memLevel`
 * - `strategy`
 * - `dictionary`
 *
 * [http://zlib.net/manual.html#Advanced](http://zlib.net/manual.html#Advanced)
 * for more information on these.
 *
 * Additional options, for internal needs:
 *
 * - `chunkSize` - size of generated data chunks (16K by default)
 * - `raw` (Boolean) - do raw deflate
 * - `gzip` (Boolean) - create gzip wrapper
 * - `to` (String) - if equal to 'string', then result will be "binary string"
 *    (each char code [0..255])
 * - `header` (Object) - custom header for gzip
 *   - `text` (Boolean) - true if compressed data believed to be text
 *   - `time` (Number) - modification time, unix timestamp
 *   - `os` (Number) - operation system code
 *   - `extra` (Array) - array of bytes with extra data (max 65536)
 *   - `name` (String) - file name (binary string)
 *   - `comment` (String) - comment (binary string)
 *   - `hcrc` (Boolean) - true if header crc should be added
 *
 * ##### Example:
 *
 * ```javascript
 * var pako = require('pako')
 *   , chunk1 = Uint8Array([1,2,3,4,5,6,7,8,9])
 *   , chunk2 = Uint8Array([10,11,12,13,14,15,16,17,18,19]);
 *
 * var deflate = new pako.Deflate({ level: 3});
 *
 * deflate.push(chunk1, false);
 * deflate.push(chunk2, true);  // true -> last chunk
 *
 * if (deflate.err) { throw new Error(deflate.err); }
 *
 * console.log(deflate.result);
 * ```
 **/
function Deflate(options) {
  if (!(this instanceof Deflate)) return new Deflate(options);

  this.options = utils.assign({
    level: Z_DEFAULT_COMPRESSION,
    method: Z_DEFLATED,
    chunkSize: 16384,
    windowBits: 15,
    memLevel: 8,
    strategy: Z_DEFAULT_STRATEGY,
    to: ''
  }, options || {});

  var opt = this.options;

  if (opt.raw && (opt.windowBits > 0)) {
    opt.windowBits = -opt.windowBits;
  }

  else if (opt.gzip && (opt.windowBits > 0) && (opt.windowBits < 16)) {
    opt.windowBits += 16;
  }

  this.err    = 0;      // error code, if happens (0 = Z_OK)
  this.msg    = '';     // error message
  this.ended  = false;  // used to avoid multiple onEnd() calls
  this.chunks = [];     // chunks of compressed data

  this.strm = new ZStream();
  this.strm.avail_out = 0;

  var status = zlib_deflate.deflateInit2(
    this.strm,
    opt.level,
    opt.method,
    opt.windowBits,
    opt.memLevel,
    opt.strategy
  );

  if (status !== Z_OK) {
    throw new Error(msg[status]);
  }

  if (opt.header) {
    zlib_deflate.deflateSetHeader(this.strm, opt.header);
  }

  if (opt.dictionary) {
    var dict;
    // Convert data if needed
    if (typeof opt.dictionary === 'string') {
      // If we need to compress text, change encoding to utf8.
      dict = strings.string2buf(opt.dictionary);
    } else if (toString.call(opt.dictionary) === '[object ArrayBuffer]') {
      dict = new Uint8Array(opt.dictionary);
    } else {
      dict = opt.dictionary;
    }

    status = zlib_deflate.deflateSetDictionary(this.strm, dict);

    if (status !== Z_OK) {
      throw new Error(msg[status]);
    }

    this._dict_set = true;
  }
}

/**
 * Deflate#push(data[, mode]) -> Boolean
 * - data (Uint8Array|Array|ArrayBuffer|String): input data. Strings will be
 *   converted to utf8 byte sequence.
 * - mode (Number|Boolean): 0..6 for corresponding Z_NO_FLUSH..Z_TREE modes.
 *   See constants. Skipped or `false` means Z_NO_FLUSH, `true` means Z_FINISH.
 *
 * Sends input data to deflate pipe, generating [[Deflate#onData]] calls with
 * new compressed chunks. Returns `true` on success. The last data block must have
 * mode Z_FINISH (or `true`). That will flush internal pending buffers and call
 * [[Deflate#onEnd]]. For interim explicit flushes (without ending the stream) you
 * can use mode Z_SYNC_FLUSH, keeping the compression context.
 *
 * On fail call [[Deflate#onEnd]] with error code and return false.
 *
 * We strongly recommend to use `Uint8Array` on input for best speed (output
 * array format is detected automatically). Also, don't skip last param and always
 * use the same type in your code (boolean or number). That will improve JS speed.
 *
 * For regular `Array`-s make sure all elements are [0..255].
 *
 * ##### Example
 *
 * ```javascript
 * push(chunk, false); // push one of data chunks
 * ...
 * push(chunk, true);  // push last chunk
 * ```
 **/
Deflate.prototype.push = function (data, mode) {
  var strm = this.strm;
  var chunkSize = this.options.chunkSize;
  var status, _mode;

  if (this.ended) { return false; }

  _mode = (mode === ~~mode) ? mode : ((mode === true) ? Z_FINISH : Z_NO_FLUSH);

  // Convert data if needed
  if (typeof data === 'string') {
    // If we need to compress text, change encoding to utf8.
    strm.input = strings.string2buf(data);
  } else if (toString.call(data) === '[object ArrayBuffer]') {
    strm.input = new Uint8Array(data);
  } else {
    strm.input = data;
  }

  strm.next_in = 0;
  strm.avail_in = strm.input.length;

  do {
    if (strm.avail_out === 0) {
      strm.output = new utils.Buf8(chunkSize);
      strm.next_out = 0;
      strm.avail_out = chunkSize;
    }
    status = zlib_deflate.deflate(strm, _mode);    /* no bad return value */

    if (status !== Z_STREAM_END && status !== Z_OK) {
      this.onEnd(status);
      this.ended = true;
      return false;
    }
    if (strm.avail_out === 0 || (strm.avail_in === 0 && (_mode === Z_FINISH || _mode === Z_SYNC_FLUSH))) {
      if (this.options.to === 'string') {
        this.onData(strings.buf2binstring(utils.shrinkBuf(strm.output, strm.next_out)));
      } else {
        this.onData(utils.shrinkBuf(strm.output, strm.next_out));
      }
    }
  } while ((strm.avail_in > 0 || strm.avail_out === 0) && status !== Z_STREAM_END);

  // Finalize on the last chunk.
  if (_mode === Z_FINISH) {
    status = zlib_deflate.deflateEnd(this.strm);
    this.onEnd(status);
    this.ended = true;
    return status === Z_OK;
  }

  // callback interim results if Z_SYNC_FLUSH.
  if (_mode === Z_SYNC_FLUSH) {
    this.onEnd(Z_OK);
    strm.avail_out = 0;
    return true;
  }

  return true;
};


/**
 * Deflate#onData(chunk) -> Void
 * - chunk (Uint8Array|Array|String): output data. Type of array depends
 *   on js engine support. When string output requested, each chunk
 *   will be string.
 *
 * By default, stores data blocks in `chunks[]` property and glue
 * those in `onEnd`. Override this handler, if you need another behaviour.
 **/
Deflate.prototype.onData = function (chunk) {
  this.chunks.push(chunk);
};


/**
 * Deflate#onEnd(status) -> Void
 * - status (Number): deflate status. 0 (Z_OK) on success,
 *   other if not.
 *
 * Called once after you tell deflate that the input stream is
 * complete (Z_FINISH) or should be flushed (Z_SYNC_FLUSH)
 * or if an error happened. By default - join collected chunks,
 * free memory and fill `results` / `err` properties.
 **/
Deflate.prototype.onEnd = function (status) {
  // On success - join
  if (status === Z_OK) {
    if (this.options.to === 'string') {
      this.result = this.chunks.join('');
    } else {
      this.result = utils.flattenChunks(this.chunks);
    }
  }
  this.chunks = [];
  this.err = status;
  this.msg = this.strm.msg;
};


/**
 * deflate(data[, options]) -> Uint8Array|Array|String
 * - data (Uint8Array|Array|String): input data to compress.
 * - options (Object): zlib deflate options.
 *
 * Compress `data` with deflate algorithm and `options`.
 *
 * Supported options are:
 *
 * - level
 * - windowBits
 * - memLevel
 * - strategy
 * - dictionary
 *
 * [http://zlib.net/manual.html#Advanced](http://zlib.net/manual.html#Advanced)
 * for more information on these.
 *
 * Sugar (options):
 *
 * - `raw` (Boolean) - say that we work with raw stream, if you don't wish to specify
 *   negative windowBits implicitly.
 * - `to` (String) - if equal to 'string', then result will be "binary string"
 *    (each char code [0..255])
 *
 * ##### Example:
 *
 * ```javascript
 * var pako = require('pako')
 *   , data = Uint8Array([1,2,3,4,5,6,7,8,9]);
 *
 * console.log(pako.deflate(data));
 * ```
 **/
function deflate(input, options) {
  var deflator = new Deflate(options);

  deflator.push(input, true);

  // That will never happens, if you don't cheat with options :)
  if (deflator.err) { throw deflator.msg || msg[deflator.err]; }

  return deflator.result;
}


/**
 * deflateRaw(data[, options]) -> Uint8Array|Array|String
 * - data (Uint8Array|Array|String): input data to compress.
 * - options (Object): zlib deflate options.
 *
 * The same as [[deflate]], but creates raw data, without wrapper
 * (header and adler32 crc).
 **/
function deflateRaw(input, options) {
  options = options || {};
  options.raw = true;
  return deflate(input, options);
}


/**
 * gzip(data[, options]) -> Uint8Array|Array|String
 * - data (Uint8Array|Array|String): input data to compress.
 * - options (Object): zlib deflate options.
 *
 * The same as [[deflate]], but create gzip wrapper instead of
 * deflate one.
 **/
function gzip(input, options) {
  options = options || {};
  options.gzip = true;
  return deflate(input, options);
}


exports.Deflate = Deflate;
exports.deflate = deflate;
exports.deflateRaw = deflateRaw;
exports.gzip = gzip;


/***/ }),

/***/ 2887:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


// (C) 1995-2013 Jean-loup Gailly and Mark Adler
// (C) 2014-2017 Vitaly Puzrin and Andrey Tupitsin
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//   claim that you wrote the original software. If you use this software
//   in a product, an acknowledgment in the product documentation would be
//   appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//   misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.

var utils   = __webpack_require__(1624);
var trees   = __webpack_require__(2888);
var adler32 = __webpack_require__(2016);
var crc32   = __webpack_require__(2017);
var msg     = __webpack_require__(1795);

/* Public constants ==========================================================*/
/* ===========================================================================*/


/* Allowed flush values; see deflate() and inflate() below for details */
var Z_NO_FLUSH      = 0;
var Z_PARTIAL_FLUSH = 1;
//var Z_SYNC_FLUSH    = 2;
var Z_FULL_FLUSH    = 3;
var Z_FINISH        = 4;
var Z_BLOCK         = 5;
//var Z_TREES         = 6;


/* Return codes for the compression/decompression functions. Negative values
 * are errors, positive values are used for special but normal events.
 */
var Z_OK            = 0;
var Z_STREAM_END    = 1;
//var Z_NEED_DICT     = 2;
//var Z_ERRNO         = -1;
var Z_STREAM_ERROR  = -2;
var Z_DATA_ERROR    = -3;
//var Z_MEM_ERROR     = -4;
var Z_BUF_ERROR     = -5;
//var Z_VERSION_ERROR = -6;


/* compression levels */
//var Z_NO_COMPRESSION      = 0;
//var Z_BEST_SPEED          = 1;
//var Z_BEST_COMPRESSION    = 9;
var Z_DEFAULT_COMPRESSION = -1;


var Z_FILTERED            = 1;
var Z_HUFFMAN_ONLY        = 2;
var Z_RLE                 = 3;
var Z_FIXED               = 4;
var Z_DEFAULT_STRATEGY    = 0;

/* Possible values of the data_type field (though see inflate()) */
//var Z_BINARY              = 0;
//var Z_TEXT                = 1;
//var Z_ASCII               = 1; // = Z_TEXT
var Z_UNKNOWN             = 2;


/* The deflate compression method */
var Z_DEFLATED  = 8;

/*============================================================================*/


var MAX_MEM_LEVEL = 9;
/* Maximum value for memLevel in deflateInit2 */
var MAX_WBITS = 15;
/* 32K LZ77 window */
var DEF_MEM_LEVEL = 8;


var LENGTH_CODES  = 29;
/* number of length codes, not counting the special END_BLOCK code */
var LITERALS      = 256;
/* number of literal bytes 0..255 */
var L_CODES       = LITERALS + 1 + LENGTH_CODES;
/* number of Literal or Length codes, including the END_BLOCK code */
var D_CODES       = 30;
/* number of distance codes */
var BL_CODES      = 19;
/* number of codes used to transfer the bit lengths */
var HEAP_SIZE     = 2 * L_CODES + 1;
/* maximum heap size */
var MAX_BITS  = 15;
/* All codes must not exceed MAX_BITS bits */

var MIN_MATCH = 3;
var MAX_MATCH = 258;
var MIN_LOOKAHEAD = (MAX_MATCH + MIN_MATCH + 1);

var PRESET_DICT = 0x20;

var INIT_STATE = 42;
var EXTRA_STATE = 69;
var NAME_STATE = 73;
var COMMENT_STATE = 91;
var HCRC_STATE = 103;
var BUSY_STATE = 113;
var FINISH_STATE = 666;

var BS_NEED_MORE      = 1; /* block not completed, need more input or more output */
var BS_BLOCK_DONE     = 2; /* block flush performed */
var BS_FINISH_STARTED = 3; /* finish started, need only more output at next deflate */
var BS_FINISH_DONE    = 4; /* finish done, accept no more input or output */

var OS_CODE = 0x03; // Unix :) . Don't detect, use this default.

function err(strm, errorCode) {
  strm.msg = msg[errorCode];
  return errorCode;
}

function rank(f) {
  return ((f) << 1) - ((f) > 4 ? 9 : 0);
}

function zero(buf) { var len = buf.length; while (--len >= 0) { buf[len] = 0; } }


/* =========================================================================
 * Flush as much pending output as possible. All deflate() output goes
 * through this function so some applications may wish to modify it
 * to avoid allocating a large strm->output buffer and copying into it.
 * (See also read_buf()).
 */
function flush_pending(strm) {
  var s = strm.state;

  //_tr_flush_bits(s);
  var len = s.pending;
  if (len > strm.avail_out) {
    len = strm.avail_out;
  }
  if (len === 0) { return; }

  utils.arraySet(strm.output, s.pending_buf, s.pending_out, len, strm.next_out);
  strm.next_out += len;
  s.pending_out += len;
  strm.total_out += len;
  strm.avail_out -= len;
  s.pending -= len;
  if (s.pending === 0) {
    s.pending_out = 0;
  }
}


function flush_block_only(s, last) {
  trees._tr_flush_block(s, (s.block_start >= 0 ? s.block_start : -1), s.strstart - s.block_start, last);
  s.block_start = s.strstart;
  flush_pending(s.strm);
}


function put_byte(s, b) {
  s.pending_buf[s.pending++] = b;
}


/* =========================================================================
 * Put a short in the pending buffer. The 16-bit value is put in MSB order.
 * IN assertion: the stream state is correct and there is enough room in
 * pending_buf.
 */
function putShortMSB(s, b) {
//  put_byte(s, (Byte)(b >> 8));
//  put_byte(s, (Byte)(b & 0xff));
  s.pending_buf[s.pending++] = (b >>> 8) & 0xff;
  s.pending_buf[s.pending++] = b & 0xff;
}


/* ===========================================================================
 * Read a new buffer from the current input stream, update the adler32
 * and total number of bytes read.  All deflate() input goes through
 * this function so some applications may wish to modify it to avoid
 * allocating a large strm->input buffer and copying from it.
 * (See also flush_pending()).
 */
function read_buf(strm, buf, start, size) {
  var len = strm.avail_in;

  if (len > size) { len = size; }
  if (len === 0) { return 0; }

  strm.avail_in -= len;

  // zmemcpy(buf, strm->next_in, len);
  utils.arraySet(buf, strm.input, strm.next_in, len, start);
  if (strm.state.wrap === 1) {
    strm.adler = adler32(strm.adler, buf, len, start);
  }

  else if (strm.state.wrap === 2) {
    strm.adler = crc32(strm.adler, buf, len, start);
  }

  strm.next_in += len;
  strm.total_in += len;

  return len;
}


/* ===========================================================================
 * Set match_start to the longest match starting at the given string and
 * return its length. Matches shorter or equal to prev_length are discarded,
 * in which case the result is equal to prev_length and match_start is
 * garbage.
 * IN assertions: cur_match is the head of the hash chain for the current
 *   string (strstart) and its distance is <= MAX_DIST, and prev_length >= 1
 * OUT assertion: the match length is not greater than s->lookahead.
 */
function longest_match(s, cur_match) {
  var chain_length = s.max_chain_length;      /* max hash chain length */
  var scan = s.strstart; /* current string */
  var match;                       /* matched string */
  var len;                           /* length of current match */
  var best_len = s.prev_length;              /* best match length so far */
  var nice_match = s.nice_match;             /* stop if match long enough */
  var limit = (s.strstart > (s.w_size - MIN_LOOKAHEAD)) ?
      s.strstart - (s.w_size - MIN_LOOKAHEAD) : 0/*NIL*/;

  var _win = s.window; // shortcut

  var wmask = s.w_mask;
  var prev  = s.prev;

  /* Stop when cur_match becomes <= limit. To simplify the code,
   * we prevent matches with the string of window index 0.
   */

  var strend = s.strstart + MAX_MATCH;
  var scan_end1  = _win[scan + best_len - 1];
  var scan_end   = _win[scan + best_len];

  /* The code is optimized for HASH_BITS >= 8 and MAX_MATCH-2 multiple of 16.
   * It is easy to get rid of this optimization if necessary.
   */
  // Assert(s->hash_bits >= 8 && MAX_MATCH == 258, "Code too clever");

  /* Do not waste too much time if we already have a good match: */
  if (s.prev_length >= s.good_match) {
    chain_length >>= 2;
  }
  /* Do not look for matches beyond the end of the input. This is necessary
   * to make deflate deterministic.
   */
  if (nice_match > s.lookahead) { nice_match = s.lookahead; }

  // Assert((ulg)s->strstart <= s->window_size-MIN_LOOKAHEAD, "need lookahead");

  do {
    // Assert(cur_match < s->strstart, "no future");
    match = cur_match;

    /* Skip to next match if the match length cannot increase
     * or if the match length is less than 2.  Note that the checks below
     * for insufficient lookahead only occur occasionally for performance
     * reasons.  Therefore uninitialized memory will be accessed, and
     * conditional jumps will be made that depend on those values.
     * However the length of the match is limited to the lookahead, so
     * the output of deflate is not affected by the uninitialized values.
     */

    if (_win[match + best_len]     !== scan_end  ||
        _win[match + best_len - 1] !== scan_end1 ||
        _win[match]                !== _win[scan] ||
        _win[++match]              !== _win[scan + 1]) {
      continue;
    }

    /* The check at best_len-1 can be removed because it will be made
     * again later. (This heuristic is not always a win.)
     * It is not necessary to compare scan[2] and match[2] since they
     * are always equal when the other bytes match, given that
     * the hash keys are equal and that HASH_BITS >= 8.
     */
    scan += 2;
    match++;
    // Assert(*scan == *match, "match[2]?");

    /* We check for insufficient lookahead only every 8th comparison;
     * the 256th check will be made at strstart+258.
     */
    do {
      /*jshint noempty:false*/
    } while (_win[++scan] === _win[++match] && _win[++scan] === _win[++match] &&
             _win[++scan] === _win[++match] && _win[++scan] === _win[++match] &&
             _win[++scan] === _win[++match] && _win[++scan] === _win[++match] &&
             _win[++scan] === _win[++match] && _win[++scan] === _win[++match] &&
             scan < strend);

    // Assert(scan <= s->window+(unsigned)(s->window_size-1), "wild scan");

    len = MAX_MATCH - (strend - scan);
    scan = strend - MAX_MATCH;

    if (len > best_len) {
      s.match_start = cur_match;
      best_len = len;
      if (len >= nice_match) {
        break;
      }
      scan_end1  = _win[scan + best_len - 1];
      scan_end   = _win[scan + best_len];
    }
  } while ((cur_match = prev[cur_match & wmask]) > limit && --chain_length !== 0);

  if (best_len <= s.lookahead) {
    return best_len;
  }
  return s.lookahead;
}


/* ===========================================================================
 * Fill the window when the lookahead becomes insufficient.
 * Updates strstart and lookahead.
 *
 * IN assertion: lookahead < MIN_LOOKAHEAD
 * OUT assertions: strstart <= window_size-MIN_LOOKAHEAD
 *    At least one byte has been read, or avail_in == 0; reads are
 *    performed for at least two bytes (required for the zip translate_eol
 *    option -- not supported here).
 */
function fill_window(s) {
  var _w_size = s.w_size;
  var p, n, m, more, str;

  //Assert(s->lookahead < MIN_LOOKAHEAD, "already enough lookahead");

  do {
    more = s.window_size - s.lookahead - s.strstart;

    // JS ints have 32 bit, block below not needed
    /* Deal with !@#$% 64K limit: */
    //if (sizeof(int) <= 2) {
    //    if (more == 0 && s->strstart == 0 && s->lookahead == 0) {
    //        more = wsize;
    //
    //  } else if (more == (unsigned)(-1)) {
    //        /* Very unlikely, but possible on 16 bit machine if
    //         * strstart == 0 && lookahead == 1 (input done a byte at time)
    //         */
    //        more--;
    //    }
    //}


    /* If the window is almost full and there is insufficient lookahead,
     * move the upper half to the lower one to make room in the upper half.
     */
    if (s.strstart >= _w_size + (_w_size - MIN_LOOKAHEAD)) {

      utils.arraySet(s.window, s.window, _w_size, _w_size, 0);
      s.match_start -= _w_size;
      s.strstart -= _w_size;
      /* we now have strstart >= MAX_DIST */
      s.block_start -= _w_size;

      /* Slide the hash table (could be avoided with 32 bit values
       at the expense of memory usage). We slide even when level == 0
       to keep the hash table consistent if we switch back to level > 0
       later. (Using level 0 permanently is not an optimal usage of
       zlib, so we don't care about this pathological case.)
       */

      n = s.hash_size;
      p = n;
      do {
        m = s.head[--p];
        s.head[p] = (m >= _w_size ? m - _w_size : 0);
      } while (--n);

      n = _w_size;
      p = n;
      do {
        m = s.prev[--p];
        s.prev[p] = (m >= _w_size ? m - _w_size : 0);
        /* If n is not on any hash chain, prev[n] is garbage but
         * its value will never be used.
         */
      } while (--n);

      more += _w_size;
    }
    if (s.strm.avail_in === 0) {
      break;
    }

    /* If there was no sliding:
     *    strstart <= WSIZE+MAX_DIST-1 && lookahead <= MIN_LOOKAHEAD - 1 &&
     *    more == window_size - lookahead - strstart
     * => more >= window_size - (MIN_LOOKAHEAD-1 + WSIZE + MAX_DIST-1)
     * => more >= window_size - 2*WSIZE + 2
     * In the BIG_MEM or MMAP case (not yet supported),
     *   window_size == input_size + MIN_LOOKAHEAD  &&
     *   strstart + s->lookahead <= input_size => more >= MIN_LOOKAHEAD.
     * Otherwise, window_size == 2*WSIZE so more >= 2.
     * If there was sliding, more >= WSIZE. So in all cases, more >= 2.
     */
    //Assert(more >= 2, "more < 2");
    n = read_buf(s.strm, s.window, s.strstart + s.lookahead, more);
    s.lookahead += n;

    /* Initialize the hash value now that we have some input: */
    if (s.lookahead + s.insert >= MIN_MATCH) {
      str = s.strstart - s.insert;
      s.ins_h = s.window[str];

      /* UPDATE_HASH(s, s->ins_h, s->window[str + 1]); */
      s.ins_h = ((s.ins_h << s.hash_shift) ^ s.window[str + 1]) & s.hash_mask;
//#if MIN_MATCH != 3
//        Call update_hash() MIN_MATCH-3 more times
//#endif
      while (s.insert) {
        /* UPDATE_HASH(s, s->ins_h, s->window[str + MIN_MATCH-1]); */
        s.ins_h = ((s.ins_h << s.hash_shift) ^ s.window[str + MIN_MATCH - 1]) & s.hash_mask;

        s.prev[str & s.w_mask] = s.head[s.ins_h];
        s.head[s.ins_h] = str;
        str++;
        s.insert--;
        if (s.lookahead + s.insert < MIN_MATCH) {
          break;
        }
      }
    }
    /* If the whole input has less than MIN_MATCH bytes, ins_h is garbage,
     * but this is not important since only literal bytes will be emitted.
     */

  } while (s.lookahead < MIN_LOOKAHEAD && s.strm.avail_in !== 0);

  /* If the WIN_INIT bytes after the end of the current data have never been
   * written, then zero those bytes in order to avoid memory check reports of
   * the use of uninitialized (or uninitialised as Julian writes) bytes by
   * the longest match routines.  Update the high water mark for the next
   * time through here.  WIN_INIT is set to MAX_MATCH since the longest match
   * routines allow scanning to strstart + MAX_MATCH, ignoring lookahead.
   */
//  if (s.high_water < s.window_size) {
//    var curr = s.strstart + s.lookahead;
//    var init = 0;
//
//    if (s.high_water < curr) {
//      /* Previous high water mark below current data -- zero WIN_INIT
//       * bytes or up to end of window, whichever is less.
//       */
//      init = s.window_size - curr;
//      if (init > WIN_INIT)
//        init = WIN_INIT;
//      zmemzero(s->window + curr, (unsigned)init);
//      s->high_water = curr + init;
//    }
//    else if (s->high_water < (ulg)curr + WIN_INIT) {
//      /* High water mark at or above current data, but below current data
//       * plus WIN_INIT -- zero out to current data plus WIN_INIT, or up
//       * to end of window, whichever is less.
//       */
//      init = (ulg)curr + WIN_INIT - s->high_water;
//      if (init > s->window_size - s->high_water)
//        init = s->window_size - s->high_water;
//      zmemzero(s->window + s->high_water, (unsigned)init);
//      s->high_water += init;
//    }
//  }
//
//  Assert((ulg)s->strstart <= s->window_size - MIN_LOOKAHEAD,
//    "not enough room for search");
}

/* ===========================================================================
 * Copy without compression as much as possible from the input stream, return
 * the current block state.
 * This function does not insert new strings in the dictionary since
 * uncompressible data is probably not useful. This function is used
 * only for the level=0 compression option.
 * NOTE: this function should be optimized to avoid extra copying from
 * window to pending_buf.
 */
function deflate_stored(s, flush) {
  /* Stored blocks are limited to 0xffff bytes, pending_buf is limited
   * to pending_buf_size, and each stored block has a 5 byte header:
   */
  var max_block_size = 0xffff;

  if (max_block_size > s.pending_buf_size - 5) {
    max_block_size = s.pending_buf_size - 5;
  }

  /* Copy as much as possible from input to output: */
  for (;;) {
    /* Fill the window as much as possible: */
    if (s.lookahead <= 1) {

      //Assert(s->strstart < s->w_size+MAX_DIST(s) ||
      //  s->block_start >= (long)s->w_size, "slide too late");
//      if (!(s.strstart < s.w_size + (s.w_size - MIN_LOOKAHEAD) ||
//        s.block_start >= s.w_size)) {
//        throw  new Error("slide too late");
//      }

      fill_window(s);
      if (s.lookahead === 0 && flush === Z_NO_FLUSH) {
        return BS_NEED_MORE;
      }

      if (s.lookahead === 0) {
        break;
      }
      /* flush the current block */
    }
    //Assert(s->block_start >= 0L, "block gone");
//    if (s.block_start < 0) throw new Error("block gone");

    s.strstart += s.lookahead;
    s.lookahead = 0;

    /* Emit a stored block if pending_buf will be full: */
    var max_start = s.block_start + max_block_size;

    if (s.strstart === 0 || s.strstart >= max_start) {
      /* strstart == 0 is possible when wraparound on 16-bit machine */
      s.lookahead = s.strstart - max_start;
      s.strstart = max_start;
      /*** FLUSH_BLOCK(s, 0); ***/
      flush_block_only(s, false);
      if (s.strm.avail_out === 0) {
        return BS_NEED_MORE;
      }
      /***/


    }
    /* Flush if we may have to slide, otherwise block_start may become
     * negative and the data will be gone:
     */
    if (s.strstart - s.block_start >= (s.w_size - MIN_LOOKAHEAD)) {
      /*** FLUSH_BLOCK(s, 0); ***/
      flush_block_only(s, false);
      if (s.strm.avail_out === 0) {
        return BS_NEED_MORE;
      }
      /***/
    }
  }

  s.insert = 0;

  if (flush === Z_FINISH) {
    /*** FLUSH_BLOCK(s, 1); ***/
    flush_block_only(s, true);
    if (s.strm.avail_out === 0) {
      return BS_FINISH_STARTED;
    }
    /***/
    return BS_FINISH_DONE;
  }

  if (s.strstart > s.block_start) {
    /*** FLUSH_BLOCK(s, 0); ***/
    flush_block_only(s, false);
    if (s.strm.avail_out === 0) {
      return BS_NEED_MORE;
    }
    /***/
  }

  return BS_NEED_MORE;
}

/* ===========================================================================
 * Compress as much as possible from the input stream, return the current
 * block state.
 * This function does not perform lazy evaluation of matches and inserts
 * new strings in the dictionary only for unmatched strings or for short
 * matches. It is used only for the fast compression options.
 */
function deflate_fast(s, flush) {
  var hash_head;        /* head of the hash chain */
  var bflush;           /* set if current block must be flushed */

  for (;;) {
    /* Make sure that we always have enough lookahead, except
     * at the end of the input file. We need MAX_MATCH bytes
     * for the next match, plus MIN_MATCH bytes to insert the
     * string following the next match.
     */
    if (s.lookahead < MIN_LOOKAHEAD) {
      fill_window(s);
      if (s.lookahead < MIN_LOOKAHEAD && flush === Z_NO_FLUSH) {
        return BS_NEED_MORE;
      }
      if (s.lookahead === 0) {
        break; /* flush the current block */
      }
    }

    /* Insert the string window[strstart .. strstart+2] in the
     * dictionary, and set hash_head to the head of the hash chain:
     */
    hash_head = 0/*NIL*/;
    if (s.lookahead >= MIN_MATCH) {
      /*** INSERT_STRING(s, s.strstart, hash_head); ***/
      s.ins_h = ((s.ins_h << s.hash_shift) ^ s.window[s.strstart + MIN_MATCH - 1]) & s.hash_mask;
      hash_head = s.prev[s.strstart & s.w_mask] = s.head[s.ins_h];
      s.head[s.ins_h] = s.strstart;
      /***/
    }

    /* Find the longest match, discarding those <= prev_length.
     * At this point we have always match_length < MIN_MATCH
     */
    if (hash_head !== 0/*NIL*/ && ((s.strstart - hash_head) <= (s.w_size - MIN_LOOKAHEAD))) {
      /* To simplify the code, we prevent matches with the string
       * of window index 0 (in particular we have to avoid a match
       * of the string with itself at the start of the input file).
       */
      s.match_length = longest_match(s, hash_head);
      /* longest_match() sets match_start */
    }
    if (s.match_length >= MIN_MATCH) {
      // check_match(s, s.strstart, s.match_start, s.match_length); // for debug only

      /*** _tr_tally_dist(s, s.strstart - s.match_start,
                     s.match_length - MIN_MATCH, bflush); ***/
      bflush = trees._tr_tally(s, s.strstart - s.match_start, s.match_length - MIN_MATCH);

      s.lookahead -= s.match_length;

      /* Insert new strings in the hash table only if the match length
       * is not too large. This saves time but degrades compression.
       */
      if (s.match_length <= s.max_lazy_match/*max_insert_length*/ && s.lookahead >= MIN_MATCH) {
        s.match_length--; /* string at strstart already in table */
        do {
          s.strstart++;
          /*** INSERT_STRING(s, s.strstart, hash_head); ***/
          s.ins_h = ((s.ins_h << s.hash_shift) ^ s.window[s.strstart + MIN_MATCH - 1]) & s.hash_mask;
          hash_head = s.prev[s.strstart & s.w_mask] = s.head[s.ins_h];
          s.head[s.ins_h] = s.strstart;
          /***/
          /* strstart never exceeds WSIZE-MAX_MATCH, so there are
           * always MIN_MATCH bytes ahead.
           */
        } while (--s.match_length !== 0);
        s.strstart++;
      } else
      {
        s.strstart += s.match_length;
        s.match_length = 0;
        s.ins_h = s.window[s.strstart];
        /* UPDATE_HASH(s, s.ins_h, s.window[s.strstart+1]); */
        s.ins_h = ((s.ins_h << s.hash_shift) ^ s.window[s.strstart + 1]) & s.hash_mask;

//#if MIN_MATCH != 3
//                Call UPDATE_HASH() MIN_MATCH-3 more times
//#endif
        /* If lookahead < MIN_MATCH, ins_h is garbage, but it does not
         * matter since it will be recomputed at next deflate call.
         */
      }
    } else {
      /* No match, output a literal byte */
      //Tracevv((stderr,"%c", s.window[s.strstart]));
      /*** _tr_tally_lit(s, s.window[s.strstart], bflush); ***/
      bflush = trees._tr_tally(s, 0, s.window[s.strstart]);

      s.lookahead--;
      s.strstart++;
    }
    if (bflush) {
      /*** FLUSH_BLOCK(s, 0); ***/
      flush_block_only(s, false);
      if (s.strm.avail_out === 0) {
        return BS_NEED_MORE;
      }
      /***/
    }
  }
  s.insert = ((s.strstart < (MIN_MATCH - 1)) ? s.strstart : MIN_MATCH - 1);
  if (flush === Z_FINISH) {
    /*** FLUSH_BLOCK(s, 1); ***/
    flush_block_only(s, true);
    if (s.strm.avail_out === 0) {
      return BS_FINISH_STARTED;
    }
    /***/
    return BS_FINISH_DONE;
  }
  if (s.last_lit) {
    /*** FLUSH_BLOCK(s, 0); ***/
    flush_block_only(s, false);
    if (s.strm.avail_out === 0) {
      return BS_NEED_MORE;
    }
    /***/
  }
  return BS_BLOCK_DONE;
}

/* ===========================================================================
 * Same as above, but achieves better compression. We use a lazy
 * evaluation for matches: a match is finally adopted only if there is
 * no better match at the next window position.
 */
function deflate_slow(s, flush) {
  var hash_head;          /* head of hash chain */
  var bflush;              /* set if current block must be flushed */

  var max_insert;

  /* Process the input block. */
  for (;;) {
    /* Make sure that we always have enough lookahead, except
     * at the end of the input file. We need MAX_MATCH bytes
     * for the next match, plus MIN_MATCH bytes to insert the
     * string following the next match.
     */
    if (s.lookahead < MIN_LOOKAHEAD) {
      fill_window(s);
      if (s.lookahead < MIN_LOOKAHEAD && flush === Z_NO_FLUSH) {
        return BS_NEED_MORE;
      }
      if (s.lookahead === 0) { break; } /* flush the current block */
    }

    /* Insert the string window[strstart .. strstart+2] in the
     * dictionary, and set hash_head to the head of the hash chain:
     */
    hash_head = 0/*NIL*/;
    if (s.lookahead >= MIN_MATCH) {
      /*** INSERT_STRING(s, s.strstart, hash_head); ***/
      s.ins_h = ((s.ins_h << s.hash_shift) ^ s.window[s.strstart + MIN_MATCH - 1]) & s.hash_mask;
      hash_head = s.prev[s.strstart & s.w_mask] = s.head[s.ins_h];
      s.head[s.ins_h] = s.strstart;
      /***/
    }

    /* Find the longest match, discarding those <= prev_length.
     */
    s.prev_length = s.match_length;
    s.prev_match = s.match_start;
    s.match_length = MIN_MATCH - 1;

    if (hash_head !== 0/*NIL*/ && s.prev_length < s.max_lazy_match &&
        s.strstart - hash_head <= (s.w_size - MIN_LOOKAHEAD)/*MAX_DIST(s)*/) {
      /* To simplify the code, we prevent matches with the string
       * of window index 0 (in particular we have to avoid a match
       * of the string with itself at the start of the input file).
       */
      s.match_length = longest_match(s, hash_head);
      /* longest_match() sets match_start */

      if (s.match_length <= 5 &&
         (s.strategy === Z_FILTERED || (s.match_length === MIN_MATCH && s.strstart - s.match_start > 4096/*TOO_FAR*/))) {

        /* If prev_match is also MIN_MATCH, match_start is garbage
         * but we will ignore the current match anyway.
         */
        s.match_length = MIN_MATCH - 1;
      }
    }
    /* If there was a match at the previous step and the current
     * match is not better, output the previous match:
     */
    if (s.prev_length >= MIN_MATCH && s.match_length <= s.prev_length) {
      max_insert = s.strstart + s.lookahead - MIN_MATCH;
      /* Do not insert strings in hash table beyond this. */

      //check_match(s, s.strstart-1, s.prev_match, s.prev_length);

      /***_tr_tally_dist(s, s.strstart - 1 - s.prev_match,
                     s.prev_length - MIN_MATCH, bflush);***/
      bflush = trees._tr_tally(s, s.strstart - 1 - s.prev_match, s.prev_length - MIN_MATCH);
      /* Insert in hash table all strings up to the end of the match.
       * strstart-1 and strstart are already inserted. If there is not
       * enough lookahead, the last two strings are not inserted in
       * the hash table.
       */
      s.lookahead -= s.prev_length - 1;
      s.prev_length -= 2;
      do {
        if (++s.strstart <= max_insert) {
          /*** INSERT_STRING(s, s.strstart, hash_head); ***/
          s.ins_h = ((s.ins_h << s.hash_shift) ^ s.window[s.strstart + MIN_MATCH - 1]) & s.hash_mask;
          hash_head = s.prev[s.strstart & s.w_mask] = s.head[s.ins_h];
          s.head[s.ins_h] = s.strstart;
          /***/
        }
      } while (--s.prev_length !== 0);
      s.match_available = 0;
      s.match_length = MIN_MATCH - 1;
      s.strstart++;

      if (bflush) {
        /*** FLUSH_BLOCK(s, 0); ***/
        flush_block_only(s, false);
        if (s.strm.avail_out === 0) {
          return BS_NEED_MORE;
        }
        /***/
      }

    } else if (s.match_available) {
      /* If there was no match at the previous position, output a
       * single literal. If there was a match but the current match
       * is longer, truncate the previous match to a single literal.
       */
      //Tracevv((stderr,"%c", s->window[s->strstart-1]));
      /*** _tr_tally_lit(s, s.window[s.strstart-1], bflush); ***/
      bflush = trees._tr_tally(s, 0, s.window[s.strstart - 1]);

      if (bflush) {
        /*** FLUSH_BLOCK_ONLY(s, 0) ***/
        flush_block_only(s, false);
        /***/
      }
      s.strstart++;
      s.lookahead--;
      if (s.strm.avail_out === 0) {
        return BS_NEED_MORE;
      }
    } else {
      /* There is no previous match to compare with, wait for
       * the next step to decide.
       */
      s.match_available = 1;
      s.strstart++;
      s.lookahead--;
    }
  }
  //Assert (flush != Z_NO_FLUSH, "no flush?");
  if (s.match_available) {
    //Tracevv((stderr,"%c", s->window[s->strstart-1]));
    /*** _tr_tally_lit(s, s.window[s.strstart-1], bflush); ***/
    bflush = trees._tr_tally(s, 0, s.window[s.strstart - 1]);

    s.match_available = 0;
  }
  s.insert = s.strstart < MIN_MATCH - 1 ? s.strstart : MIN_MATCH - 1;
  if (flush === Z_FINISH) {
    /*** FLUSH_BLOCK(s, 1); ***/
    flush_block_only(s, true);
    if (s.strm.avail_out === 0) {
      return BS_FINISH_STARTED;
    }
    /***/
    return BS_FINISH_DONE;
  }
  if (s.last_lit) {
    /*** FLUSH_BLOCK(s, 0); ***/
    flush_block_only(s, false);
    if (s.strm.avail_out === 0) {
      return BS_NEED_MORE;
    }
    /***/
  }

  return BS_BLOCK_DONE;
}


/* ===========================================================================
 * For Z_RLE, simply look for runs of bytes, generate matches only of distance
 * one.  Do not maintain a hash table.  (It will be regenerated if this run of
 * deflate switches away from Z_RLE.)
 */
function deflate_rle(s, flush) {
  var bflush;            /* set if current block must be flushed */
  var prev;              /* byte at distance one to match */
  var scan, strend;      /* scan goes up to strend for length of run */

  var _win = s.window;

  for (;;) {
    /* Make sure that we always have enough lookahead, except
     * at the end of the input file. We need MAX_MATCH bytes
     * for the longest run, plus one for the unrolled loop.
     */
    if (s.lookahead <= MAX_MATCH) {
      fill_window(s);
      if (s.lookahead <= MAX_MATCH && flush === Z_NO_FLUSH) {
        return BS_NEED_MORE;
      }
      if (s.lookahead === 0) { break; } /* flush the current block */
    }

    /* See how many times the previous byte repeats */
    s.match_length = 0;
    if (s.lookahead >= MIN_MATCH && s.strstart > 0) {
      scan = s.strstart - 1;
      prev = _win[scan];
      if (prev === _win[++scan] && prev === _win[++scan] && prev === _win[++scan]) {
        strend = s.strstart + MAX_MATCH;
        do {
          /*jshint noempty:false*/
        } while (prev === _win[++scan] && prev === _win[++scan] &&
                 prev === _win[++scan] && prev === _win[++scan] &&
                 prev === _win[++scan] && prev === _win[++scan] &&
                 prev === _win[++scan] && prev === _win[++scan] &&
                 scan < strend);
        s.match_length = MAX_MATCH - (strend - scan);
        if (s.match_length > s.lookahead) {
          s.match_length = s.lookahead;
        }
      }
      //Assert(scan <= s->window+(uInt)(s->window_size-1), "wild scan");
    }

    /* Emit match if have run of MIN_MATCH or longer, else emit literal */
    if (s.match_length >= MIN_MATCH) {
      //check_match(s, s.strstart, s.strstart - 1, s.match_length);

      /*** _tr_tally_dist(s, 1, s.match_length - MIN_MATCH, bflush); ***/
      bflush = trees._tr_tally(s, 1, s.match_length - MIN_MATCH);

      s.lookahead -= s.match_length;
      s.strstart += s.match_length;
      s.match_length = 0;
    } else {
      /* No match, output a literal byte */
      //Tracevv((stderr,"%c", s->window[s->strstart]));
      /*** _tr_tally_lit(s, s.window[s.strstart], bflush); ***/
      bflush = trees._tr_tally(s, 0, s.window[s.strstart]);

      s.lookahead--;
      s.strstart++;
    }
    if (bflush) {
      /*** FLUSH_BLOCK(s, 0); ***/
      flush_block_only(s, false);
      if (s.strm.avail_out === 0) {
        return BS_NEED_MORE;
      }
      /***/
    }
  }
  s.insert = 0;
  if (flush === Z_FINISH) {
    /*** FLUSH_BLOCK(s, 1); ***/
    flush_block_only(s, true);
    if (s.strm.avail_out === 0) {
      return BS_FINISH_STARTED;
    }
    /***/
    return BS_FINISH_DONE;
  }
  if (s.last_lit) {
    /*** FLUSH_BLOCK(s, 0); ***/
    flush_block_only(s, false);
    if (s.strm.avail_out === 0) {
      return BS_NEED_MORE;
    }
    /***/
  }
  return BS_BLOCK_DONE;
}

/* ===========================================================================
 * For Z_HUFFMAN_ONLY, do not look for matches.  Do not maintain a hash table.
 * (It will be regenerated if this run of deflate switches away from Huffman.)
 */
function deflate_huff(s, flush) {
  var bflush;             /* set if current block must be flushed */

  for (;;) {
    /* Make sure that we have a literal to write. */
    if (s.lookahead === 0) {
      fill_window(s);
      if (s.lookahead === 0) {
        if (flush === Z_NO_FLUSH) {
          return BS_NEED_MORE;
        }
        break;      /* flush the current block */
      }
    }

    /* Output a literal byte */
    s.match_length = 0;
    //Tracevv((stderr,"%c", s->window[s->strstart]));
    /*** _tr_tally_lit(s, s.window[s.strstart], bflush); ***/
    bflush = trees._tr_tally(s, 0, s.window[s.strstart]);
    s.lookahead--;
    s.strstart++;
    if (bflush) {
      /*** FLUSH_BLOCK(s, 0); ***/
      flush_block_only(s, false);
      if (s.strm.avail_out === 0) {
        return BS_NEED_MORE;
      }
      /***/
    }
  }
  s.insert = 0;
  if (flush === Z_FINISH) {
    /*** FLUSH_BLOCK(s, 1); ***/
    flush_block_only(s, true);
    if (s.strm.avail_out === 0) {
      return BS_FINISH_STARTED;
    }
    /***/
    return BS_FINISH_DONE;
  }
  if (s.last_lit) {
    /*** FLUSH_BLOCK(s, 0); ***/
    flush_block_only(s, false);
    if (s.strm.avail_out === 0) {
      return BS_NEED_MORE;
    }
    /***/
  }
  return BS_BLOCK_DONE;
}

/* Values for max_lazy_match, good_match and max_chain_length, depending on
 * the desired pack level (0..9). The values given below have been tuned to
 * exclude worst case performance for pathological files. Better values may be
 * found for specific files.
 */
function Config(good_length, max_lazy, nice_length, max_chain, func) {
  this.good_length = good_length;
  this.max_lazy = max_lazy;
  this.nice_length = nice_length;
  this.max_chain = max_chain;
  this.func = func;
}

var configuration_table;

configuration_table = [
  /*      good lazy nice chain */
  new Config(0, 0, 0, 0, deflate_stored),          /* 0 store only */
  new Config(4, 4, 8, 4, deflate_fast),            /* 1 max speed, no lazy matches */
  new Config(4, 5, 16, 8, deflate_fast),           /* 2 */
  new Config(4, 6, 32, 32, deflate_fast),          /* 3 */

  new Config(4, 4, 16, 16, deflate_slow),          /* 4 lazy matches */
  new Config(8, 16, 32, 32, deflate_slow),         /* 5 */
  new Config(8, 16, 128, 128, deflate_slow),       /* 6 */
  new Config(8, 32, 128, 256, deflate_slow),       /* 7 */
  new Config(32, 128, 258, 1024, deflate_slow),    /* 8 */
  new Config(32, 258, 258, 4096, deflate_slow)     /* 9 max compression */
];


/* ===========================================================================
 * Initialize the "longest match" routines for a new zlib stream
 */
function lm_init(s) {
  s.window_size = 2 * s.w_size;

  /*** CLEAR_HASH(s); ***/
  zero(s.head); // Fill with NIL (= 0);

  /* Set the default configuration parameters:
   */
  s.max_lazy_match = configuration_table[s.level].max_lazy;
  s.good_match = configuration_table[s.level].good_length;
  s.nice_match = configuration_table[s.level].nice_length;
  s.max_chain_length = configuration_table[s.level].max_chain;

  s.strstart = 0;
  s.block_start = 0;
  s.lookahead = 0;
  s.insert = 0;
  s.match_length = s.prev_length = MIN_MATCH - 1;
  s.match_available = 0;
  s.ins_h = 0;
}


function DeflateState() {
  this.strm = null;            /* pointer back to this zlib stream */
  this.status = 0;            /* as the name implies */
  this.pending_buf = null;      /* output still pending */
  this.pending_buf_size = 0;  /* size of pending_buf */
  this.pending_out = 0;       /* next pending byte to output to the stream */
  this.pending = 0;           /* nb of bytes in the pending buffer */
  this.wrap = 0;              /* bit 0 true for zlib, bit 1 true for gzip */
  this.gzhead = null;         /* gzip header information to write */
  this.gzindex = 0;           /* where in extra, name, or comment */
  this.method = Z_DEFLATED; /* can only be DEFLATED */
  this.last_flush = -1;   /* value of flush param for previous deflate call */

  this.w_size = 0;  /* LZ77 window size (32K by default) */
  this.w_bits = 0;  /* log2(w_size)  (8..16) */
  this.w_mask = 0;  /* w_size - 1 */

  this.window = null;
  /* Sliding window. Input bytes are read into the second half of the window,
   * and move to the first half later to keep a dictionary of at least wSize
   * bytes. With this organization, matches are limited to a distance of
   * wSize-MAX_MATCH bytes, but this ensures that IO is always
   * performed with a length multiple of the block size.
   */

  this.window_size = 0;
  /* Actual size of window: 2*wSize, except when the user input buffer
   * is directly used as sliding window.
   */

  this.prev = null;
  /* Link to older string with same hash index. To limit the size of this
   * array to 64K, this link is maintained only for the last 32K strings.
   * An index in this array is thus a window index modulo 32K.
   */

  this.head = null;   /* Heads of the hash chains or NIL. */

  this.ins_h = 0;       /* hash index of string to be inserted */
  this.hash_size = 0;   /* number of elements in hash table */
  this.hash_bits = 0;   /* log2(hash_size) */
  this.hash_mask = 0;   /* hash_size-1 */

  this.hash_shift = 0;
  /* Number of bits by which ins_h must be shifted at each input
   * step. It must be such that after MIN_MATCH steps, the oldest
   * byte no longer takes part in the hash key, that is:
   *   hash_shift * MIN_MATCH >= hash_bits
   */

  this.block_start = 0;
  /* Window position at the beginning of the current output block. Gets
   * negative when the window is moved backwards.
   */

  this.match_length = 0;      /* length of best match */
  this.prev_match = 0;        /* previous match */
  this.match_available = 0;   /* set if previous match exists */
  this.strstart = 0;          /* start of string to insert */
  this.match_start = 0;       /* start of matching string */
  this.lookahead = 0;         /* number of valid bytes ahead in window */

  this.prev_length = 0;
  /* Length of the best match at previous step. Matches not greater than this
   * are discarded. This is used in the lazy match evaluation.
   */

  this.max_chain_length = 0;
  /* To speed up deflation, hash chains are never searched beyond this
   * length.  A higher limit improves compression ratio but degrades the
   * speed.
   */

  this.max_lazy_match = 0;
  /* Attempt to find a better match only when the current match is strictly
   * smaller than this value. This mechanism is used only for compression
   * levels >= 4.
   */
  // That's alias to max_lazy_match, don't use directly
  //this.max_insert_length = 0;
  /* Insert new strings in the hash table only if the match length is not
   * greater than this length. This saves time but degrades compression.
   * max_insert_length is used only for compression levels <= 3.
   */

  this.level = 0;     /* compression level (1..9) */
  this.strategy = 0;  /* favor or force Huffman coding*/

  this.good_match = 0;
  /* Use a faster search when the previous match is longer than this */

  this.nice_match = 0; /* Stop searching when current match exceeds this */

              /* used by trees.c: */

  /* Didn't use ct_data typedef below to suppress compiler warning */

  // struct ct_data_s dyn_ltree[HEAP_SIZE];   /* literal and length tree */
  // struct ct_data_s dyn_dtree[2*D_CODES+1]; /* distance tree */
  // struct ct_data_s bl_tree[2*BL_CODES+1];  /* Huffman tree for bit lengths */

  // Use flat array of DOUBLE size, with interleaved fata,
  // because JS does not support effective
  this.dyn_ltree  = new utils.Buf16(HEAP_SIZE * 2);
  this.dyn_dtree  = new utils.Buf16((2 * D_CODES + 1) * 2);
  this.bl_tree    = new utils.Buf16((2 * BL_CODES + 1) * 2);
  zero(this.dyn_ltree);
  zero(this.dyn_dtree);
  zero(this.bl_tree);

  this.l_desc   = null;         /* desc. for literal tree */
  this.d_desc   = null;         /* desc. for distance tree */
  this.bl_desc  = null;         /* desc. for bit length tree */

  //ush bl_count[MAX_BITS+1];
  this.bl_count = new utils.Buf16(MAX_BITS + 1);
  /* number of codes at each bit length for an optimal tree */

  //int heap[2*L_CODES+1];      /* heap used to build the Huffman trees */
  this.heap = new utils.Buf16(2 * L_CODES + 1);  /* heap used to build the Huffman trees */
  zero(this.heap);

  this.heap_len = 0;               /* number of elements in the heap */
  this.heap_max = 0;               /* element of largest frequency */
  /* The sons of heap[n] are heap[2*n] and heap[2*n+1]. heap[0] is not used.
   * The same heap array is used to build all trees.
   */

  this.depth = new utils.Buf16(2 * L_CODES + 1); //uch depth[2*L_CODES+1];
  zero(this.depth);
  /* Depth of each subtree used as tie breaker for trees of equal frequency
   */

  this.l_buf = 0;          /* buffer index for literals or lengths */

  this.lit_bufsize = 0;
  /* Size of match buffer for literals/lengths.  There are 4 reasons for
   * limiting lit_bufsize to 64K:
   *   - frequencies can be kept in 16 bit counters
   *   - if compression is not successful for the first block, all input
   *     data is still in the window so we can still emit a stored block even
   *     when input comes from standard input.  (This can also be done for
   *     all blocks if lit_bufsize is not greater than 32K.)
   *   - if compression is not successful for a file smaller than 64K, we can
   *     even emit a stored file instead of a stored block (saving 5 bytes).
   *     This is applicable only for zip (not gzip or zlib).
   *   - creating new Huffman trees less frequently may not provide fast
   *     adaptation to changes in the input data statistics. (Take for
   *     example a binary file with poorly compressible code followed by
   *     a highly compressible string table.) Smaller buffer sizes give
   *     fast adaptation but have of course the overhead of transmitting
   *     trees more frequently.
   *   - I can't count above 4
   */

  this.last_lit = 0;      /* running index in l_buf */

  this.d_buf = 0;
  /* Buffer index for distances. To simplify the code, d_buf and l_buf have
   * the same number of elements. To use different lengths, an extra flag
   * array would be necessary.
   */

  this.opt_len = 0;       /* bit length of current block with optimal trees */
  this.static_len = 0;    /* bit length of current block with static trees */
  this.matches = 0;       /* number of string matches in current block */
  this.insert = 0;        /* bytes at end of window left to insert */


  this.bi_buf = 0;
  /* Output buffer. bits are inserted starting at the bottom (least
   * significant bits).
   */
  this.bi_valid = 0;
  /* Number of valid bits in bi_buf.  All bits above the last valid bit
   * are always zero.
   */

  // Used for window memory init. We safely ignore it for JS. That makes
  // sense only for pointers and memory check tools.
  //this.high_water = 0;
  /* High water mark offset in window for initialized bytes -- bytes above
   * this are set to zero in order to avoid memory check warnings when
   * longest match routines access bytes past the input.  This is then
   * updated to the new high water mark.
   */
}


function deflateResetKeep(strm) {
  var s;

  if (!strm || !strm.state) {
    return err(strm, Z_STREAM_ERROR);
  }

  strm.total_in = strm.total_out = 0;
  strm.data_type = Z_UNKNOWN;

  s = strm.state;
  s.pending = 0;
  s.pending_out = 0;

  if (s.wrap < 0) {
    s.wrap = -s.wrap;
    /* was made negative by deflate(..., Z_FINISH); */
  }
  s.status = (s.wrap ? INIT_STATE : BUSY_STATE);
  strm.adler = (s.wrap === 2) ?
    0  // crc32(0, Z_NULL, 0)
  :
    1; // adler32(0, Z_NULL, 0)
  s.last_flush = Z_NO_FLUSH;
  trees._tr_init(s);
  return Z_OK;
}


function deflateReset(strm) {
  var ret = deflateResetKeep(strm);
  if (ret === Z_OK) {
    lm_init(strm.state);
  }
  return ret;
}


function deflateSetHeader(strm, head) {
  if (!strm || !strm.state) { return Z_STREAM_ERROR; }
  if (strm.state.wrap !== 2) { return Z_STREAM_ERROR; }
  strm.state.gzhead = head;
  return Z_OK;
}


function deflateInit2(strm, level, method, windowBits, memLevel, strategy) {
  if (!strm) { // === Z_NULL
    return Z_STREAM_ERROR;
  }
  var wrap = 1;

  if (level === Z_DEFAULT_COMPRESSION) {
    level = 6;
  }

  if (windowBits < 0) { /* suppress zlib wrapper */
    wrap = 0;
    windowBits = -windowBits;
  }

  else if (windowBits > 15) {
    wrap = 2;           /* write gzip wrapper instead */
    windowBits -= 16;
  }


  if (memLevel < 1 || memLevel > MAX_MEM_LEVEL || method !== Z_DEFLATED ||
    windowBits < 8 || windowBits > 15 || level < 0 || level > 9 ||
    strategy < 0 || strategy > Z_FIXED) {
    return err(strm, Z_STREAM_ERROR);
  }


  if (windowBits === 8) {
    windowBits = 9;
  }
  /* until 256-byte window bug fixed */

  var s = new DeflateState();

  strm.state = s;
  s.strm = strm;

  s.wrap = wrap;
  s.gzhead = null;
  s.w_bits = windowBits;
  s.w_size = 1 << s.w_bits;
  s.w_mask = s.w_size - 1;

  s.hash_bits = memLevel + 7;
  s.hash_size = 1 << s.hash_bits;
  s.hash_mask = s.hash_size - 1;
  s.hash_shift = ~~((s.hash_bits + MIN_MATCH - 1) / MIN_MATCH);

  s.window = new utils.Buf8(s.w_size * 2);
  s.head = new utils.Buf16(s.hash_size);
  s.prev = new utils.Buf16(s.w_size);

  // Don't need mem init magic for JS.
  //s.high_water = 0;  /* nothing written to s->window yet */

  s.lit_bufsize = 1 << (memLevel + 6); /* 16K elements by default */

  s.pending_buf_size = s.lit_bufsize * 4;

  //overlay = (ushf *) ZALLOC(strm, s->lit_bufsize, sizeof(ush)+2);
  //s->pending_buf = (uchf *) overlay;
  s.pending_buf = new utils.Buf8(s.pending_buf_size);

  // It is offset from `s.pending_buf` (size is `s.lit_bufsize * 2`)
  //s->d_buf = overlay + s->lit_bufsize/sizeof(ush);
  s.d_buf = 1 * s.lit_bufsize;

  //s->l_buf = s->pending_buf + (1+sizeof(ush))*s->lit_bufsize;
  s.l_buf = (1 + 2) * s.lit_bufsize;

  s.level = level;
  s.strategy = strategy;
  s.method = method;

  return deflateReset(strm);
}

function deflateInit(strm, level) {
  return deflateInit2(strm, level, Z_DEFLATED, MAX_WBITS, DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY);
}


function deflate(strm, flush) {
  var old_flush, s;
  var beg, val; // for gzip header write only

  if (!strm || !strm.state ||
    flush > Z_BLOCK || flush < 0) {
    return strm ? err(strm, Z_STREAM_ERROR) : Z_STREAM_ERROR;
  }

  s = strm.state;

  if (!strm.output ||
      (!strm.input && strm.avail_in !== 0) ||
      (s.status === FINISH_STATE && flush !== Z_FINISH)) {
    return err(strm, (strm.avail_out === 0) ? Z_BUF_ERROR : Z_STREAM_ERROR);
  }

  s.strm = strm; /* just in case */
  old_flush = s.last_flush;
  s.last_flush = flush;

  /* Write the header */
  if (s.status === INIT_STATE) {

    if (s.wrap === 2) { // GZIP header
      strm.adler = 0;  //crc32(0L, Z_NULL, 0);
      put_byte(s, 31);
      put_byte(s, 139);
      put_byte(s, 8);
      if (!s.gzhead) { // s->gzhead == Z_NULL
        put_byte(s, 0);
        put_byte(s, 0);
        put_byte(s, 0);
        put_byte(s, 0);
        put_byte(s, 0);
        put_byte(s, s.level === 9 ? 2 :
                    (s.strategy >= Z_HUFFMAN_ONLY || s.level < 2 ?
                     4 : 0));
        put_byte(s, OS_CODE);
        s.status = BUSY_STATE;
      }
      else {
        put_byte(s, (s.gzhead.text ? 1 : 0) +
                    (s.gzhead.hcrc ? 2 : 0) +
                    (!s.gzhead.extra ? 0 : 4) +
                    (!s.gzhead.name ? 0 : 8) +
                    (!s.gzhead.comment ? 0 : 16)
                );
        put_byte(s, s.gzhead.time & 0xff);
        put_byte(s, (s.gzhead.time >> 8) & 0xff);
        put_byte(s, (s.gzhead.time >> 16) & 0xff);
        put_byte(s, (s.gzhead.time >> 24) & 0xff);
        put_byte(s, s.level === 9 ? 2 :
                    (s.strategy >= Z_HUFFMAN_ONLY || s.level < 2 ?
                     4 : 0));
        put_byte(s, s.gzhead.os & 0xff);
        if (s.gzhead.extra && s.gzhead.extra.length) {
          put_byte(s, s.gzhead.extra.length & 0xff);
          put_byte(s, (s.gzhead.extra.length >> 8) & 0xff);
        }
        if (s.gzhead.hcrc) {
          strm.adler = crc32(strm.adler, s.pending_buf, s.pending, 0);
        }
        s.gzindex = 0;
        s.status = EXTRA_STATE;
      }
    }
    else // DEFLATE header
    {
      var header = (Z_DEFLATED + ((s.w_bits - 8) << 4)) << 8;
      var level_flags = -1;

      if (s.strategy >= Z_HUFFMAN_ONLY || s.level < 2) {
        level_flags = 0;
      } else if (s.level < 6) {
        level_flags = 1;
      } else if (s.level === 6) {
        level_flags = 2;
      } else {
        level_flags = 3;
      }
      header |= (level_flags << 6);
      if (s.strstart !== 0) { header |= PRESET_DICT; }
      header += 31 - (header % 31);

      s.status = BUSY_STATE;
      putShortMSB(s, header);

      /* Save the adler32 of the preset dictionary: */
      if (s.strstart !== 0) {
        putShortMSB(s, strm.adler >>> 16);
        putShortMSB(s, strm.adler & 0xffff);
      }
      strm.adler = 1; // adler32(0L, Z_NULL, 0);
    }
  }

//#ifdef GZIP
  if (s.status === EXTRA_STATE) {
    if (s.gzhead.extra/* != Z_NULL*/) {
      beg = s.pending;  /* start of bytes to update crc */

      while (s.gzindex < (s.gzhead.extra.length & 0xffff)) {
        if (s.pending === s.pending_buf_size) {
          if (s.gzhead.hcrc && s.pending > beg) {
            strm.adler = crc32(strm.adler, s.pending_buf, s.pending - beg, beg);
          }
          flush_pending(strm);
          beg = s.pending;
          if (s.pending === s.pending_buf_size) {
            break;
          }
        }
        put_byte(s, s.gzhead.extra[s.gzindex] & 0xff);
        s.gzindex++;
      }
      if (s.gzhead.hcrc && s.pending > beg) {
        strm.adler = crc32(strm.adler, s.pending_buf, s.pending - beg, beg);
      }
      if (s.gzindex === s.gzhead.extra.length) {
        s.gzindex = 0;
        s.status = NAME_STATE;
      }
    }
    else {
      s.status = NAME_STATE;
    }
  }
  if (s.status === NAME_STATE) {
    if (s.gzhead.name/* != Z_NULL*/) {
      beg = s.pending;  /* start of bytes to update crc */
      //int val;

      do {
        if (s.pending === s.pending_buf_size) {
          if (s.gzhead.hcrc && s.pending > beg) {
            strm.adler = crc32(strm.adler, s.pending_buf, s.pending - beg, beg);
          }
          flush_pending(strm);
          beg = s.pending;
          if (s.pending === s.pending_buf_size) {
            val = 1;
            break;
          }
        }
        // JS specific: little magic to add zero terminator to end of string
        if (s.gzindex < s.gzhead.name.length) {
          val = s.gzhead.name.charCodeAt(s.gzindex++) & 0xff;
        } else {
          val = 0;
        }
        put_byte(s, val);
      } while (val !== 0);

      if (s.gzhead.hcrc && s.pending > beg) {
        strm.adler = crc32(strm.adler, s.pending_buf, s.pending - beg, beg);
      }
      if (val === 0) {
        s.gzindex = 0;
        s.status = COMMENT_STATE;
      }
    }
    else {
      s.status = COMMENT_STATE;
    }
  }
  if (s.status === COMMENT_STATE) {
    if (s.gzhead.comment/* != Z_NULL*/) {
      beg = s.pending;  /* start of bytes to update crc */
      //int val;

      do {
        if (s.pending === s.pending_buf_size) {
          if (s.gzhead.hcrc && s.pending > beg) {
            strm.adler = crc32(strm.adler, s.pending_buf, s.pending - beg, beg);
          }
          flush_pending(strm);
          beg = s.pending;
          if (s.pending === s.pending_buf_size) {
            val = 1;
            break;
          }
        }
        // JS specific: little magic to add zero terminator to end of string
        if (s.gzindex < s.gzhead.comment.length) {
          val = s.gzhead.comment.charCodeAt(s.gzindex++) & 0xff;
        } else {
          val = 0;
        }
        put_byte(s, val);
      } while (val !== 0);

      if (s.gzhead.hcrc && s.pending > beg) {
        strm.adler = crc32(strm.adler, s.pending_buf, s.pending - beg, beg);
      }
      if (val === 0) {
        s.status = HCRC_STATE;
      }
    }
    else {
      s.status = HCRC_STATE;
    }
  }
  if (s.status === HCRC_STATE) {
    if (s.gzhead.hcrc) {
      if (s.pending + 2 > s.pending_buf_size) {
        flush_pending(strm);
      }
      if (s.pending + 2 <= s.pending_buf_size) {
        put_byte(s, strm.adler & 0xff);
        put_byte(s, (strm.adler >> 8) & 0xff);
        strm.adler = 0; //crc32(0L, Z_NULL, 0);
        s.status = BUSY_STATE;
      }
    }
    else {
      s.status = BUSY_STATE;
    }
  }
//#endif

  /* Flush as much pending output as possible */
  if (s.pending !== 0) {
    flush_pending(strm);
    if (strm.avail_out === 0) {
      /* Since avail_out is 0, deflate will be called again with
       * more output space, but possibly with both pending and
       * avail_in equal to zero. There won't be anything to do,
       * but this is not an error situation so make sure we
       * return OK instead of BUF_ERROR at next call of deflate:
       */
      s.last_flush = -1;
      return Z_OK;
    }

    /* Make sure there is something to do and avoid duplicate consecutive
     * flushes. For repeated and useless calls with Z_FINISH, we keep
     * returning Z_STREAM_END instead of Z_BUF_ERROR.
     */
  } else if (strm.avail_in === 0 && rank(flush) <= rank(old_flush) &&
    flush !== Z_FINISH) {
    return err(strm, Z_BUF_ERROR);
  }

  /* User must not provide more input after the first FINISH: */
  if (s.status === FINISH_STATE && strm.avail_in !== 0) {
    return err(strm, Z_BUF_ERROR);
  }

  /* Start a new block or continue the current one.
   */
  if (strm.avail_in !== 0 || s.lookahead !== 0 ||
    (flush !== Z_NO_FLUSH && s.status !== FINISH_STATE)) {
    var bstate = (s.strategy === Z_HUFFMAN_ONLY) ? deflate_huff(s, flush) :
      (s.strategy === Z_RLE ? deflate_rle(s, flush) :
        configuration_table[s.level].func(s, flush));

    if (bstate === BS_FINISH_STARTED || bstate === BS_FINISH_DONE) {
      s.status = FINISH_STATE;
    }
    if (bstate === BS_NEED_MORE || bstate === BS_FINISH_STARTED) {
      if (strm.avail_out === 0) {
        s.last_flush = -1;
        /* avoid BUF_ERROR next call, see above */
      }
      return Z_OK;
      /* If flush != Z_NO_FLUSH && avail_out == 0, the next call
       * of deflate should use the same flush parameter to make sure
       * that the flush is complete. So we don't have to output an
       * empty block here, this will be done at next call. This also
       * ensures that for a very small output buffer, we emit at most
       * one empty block.
       */
    }
    if (bstate === BS_BLOCK_DONE) {
      if (flush === Z_PARTIAL_FLUSH) {
        trees._tr_align(s);
      }
      else if (flush !== Z_BLOCK) { /* FULL_FLUSH or SYNC_FLUSH */

        trees._tr_stored_block(s, 0, 0, false);
        /* For a full flush, this empty block will be recognized
         * as a special marker by inflate_sync().
         */
        if (flush === Z_FULL_FLUSH) {
          /*** CLEAR_HASH(s); ***/             /* forget history */
          zero(s.head); // Fill with NIL (= 0);

          if (s.lookahead === 0) {
            s.strstart = 0;
            s.block_start = 0;
            s.insert = 0;
          }
        }
      }
      flush_pending(strm);
      if (strm.avail_out === 0) {
        s.last_flush = -1; /* avoid BUF_ERROR at next call, see above */
        return Z_OK;
      }
    }
  }
  //Assert(strm->avail_out > 0, "bug2");
  //if (strm.avail_out <= 0) { throw new Error("bug2");}

  if (flush !== Z_FINISH) { return Z_OK; }
  if (s.wrap <= 0) { return Z_STREAM_END; }

  /* Write the trailer */
  if (s.wrap === 2) {
    put_byte(s, strm.adler & 0xff);
    put_byte(s, (strm.adler >> 8) & 0xff);
    put_byte(s, (strm.adler >> 16) & 0xff);
    put_byte(s, (strm.adler >> 24) & 0xff);
    put_byte(s, strm.total_in & 0xff);
    put_byte(s, (strm.total_in >> 8) & 0xff);
    put_byte(s, (strm.total_in >> 16) & 0xff);
    put_byte(s, (strm.total_in >> 24) & 0xff);
  }
  else
  {
    putShortMSB(s, strm.adler >>> 16);
    putShortMSB(s, strm.adler & 0xffff);
  }

  flush_pending(strm);
  /* If avail_out is zero, the application will call deflate again
   * to flush the rest.
   */
  if (s.wrap > 0) { s.wrap = -s.wrap; }
  /* write the trailer only once! */
  return s.pending !== 0 ? Z_OK : Z_STREAM_END;
}

function deflateEnd(strm) {
  var status;

  if (!strm/*== Z_NULL*/ || !strm.state/*== Z_NULL*/) {
    return Z_STREAM_ERROR;
  }

  status = strm.state.status;
  if (status !== INIT_STATE &&
    status !== EXTRA_STATE &&
    status !== NAME_STATE &&
    status !== COMMENT_STATE &&
    status !== HCRC_STATE &&
    status !== BUSY_STATE &&
    status !== FINISH_STATE
  ) {
    return err(strm, Z_STREAM_ERROR);
  }

  strm.state = null;

  return status === BUSY_STATE ? err(strm, Z_DATA_ERROR) : Z_OK;
}


/* =========================================================================
 * Initializes the compression dictionary from the given byte
 * sequence without producing any compressed output.
 */
function deflateSetDictionary(strm, dictionary) {
  var dictLength = dictionary.length;

  var s;
  var str, n;
  var wrap;
  var avail;
  var next;
  var input;
  var tmpDict;

  if (!strm/*== Z_NULL*/ || !strm.state/*== Z_NULL*/) {
    return Z_STREAM_ERROR;
  }

  s = strm.state;
  wrap = s.wrap;

  if (wrap === 2 || (wrap === 1 && s.status !== INIT_STATE) || s.lookahead) {
    return Z_STREAM_ERROR;
  }

  /* when using zlib wrappers, compute Adler-32 for provided dictionary */
  if (wrap === 1) {
    /* adler32(strm->adler, dictionary, dictLength); */
    strm.adler = adler32(strm.adler, dictionary, dictLength, 0);
  }

  s.wrap = 0;   /* avoid computing Adler-32 in read_buf */

  /* if dictionary would fill window, just replace the history */
  if (dictLength >= s.w_size) {
    if (wrap === 0) {            /* already empty otherwise */
      /*** CLEAR_HASH(s); ***/
      zero(s.head); // Fill with NIL (= 0);
      s.strstart = 0;
      s.block_start = 0;
      s.insert = 0;
    }
    /* use the tail */
    // dictionary = dictionary.slice(dictLength - s.w_size);
    tmpDict = new utils.Buf8(s.w_size);
    utils.arraySet(tmpDict, dictionary, dictLength - s.w_size, s.w_size, 0);
    dictionary = tmpDict;
    dictLength = s.w_size;
  }
  /* insert dictionary into window and hash */
  avail = strm.avail_in;
  next = strm.next_in;
  input = strm.input;
  strm.avail_in = dictLength;
  strm.next_in = 0;
  strm.input = dictionary;
  fill_window(s);
  while (s.lookahead >= MIN_MATCH) {
    str = s.strstart;
    n = s.lookahead - (MIN_MATCH - 1);
    do {
      /* UPDATE_HASH(s, s->ins_h, s->window[str + MIN_MATCH-1]); */
      s.ins_h = ((s.ins_h << s.hash_shift) ^ s.window[str + MIN_MATCH - 1]) & s.hash_mask;

      s.prev[str & s.w_mask] = s.head[s.ins_h];

      s.head[s.ins_h] = str;
      str++;
    } while (--n);
    s.strstart = str;
    s.lookahead = MIN_MATCH - 1;
    fill_window(s);
  }
  s.strstart += s.lookahead;
  s.block_start = s.strstart;
  s.insert = s.lookahead;
  s.lookahead = 0;
  s.match_length = s.prev_length = MIN_MATCH - 1;
  s.match_available = 0;
  strm.next_in = next;
  strm.input = input;
  strm.avail_in = avail;
  s.wrap = wrap;
  return Z_OK;
}


exports.deflateInit = deflateInit;
exports.deflateInit2 = deflateInit2;
exports.deflateReset = deflateReset;
exports.deflateResetKeep = deflateResetKeep;
exports.deflateSetHeader = deflateSetHeader;
exports.deflate = deflate;
exports.deflateEnd = deflateEnd;
exports.deflateSetDictionary = deflateSetDictionary;
exports.deflateInfo = 'pako deflate (from Nodeca project)';

/* Not implemented
exports.deflateBound = deflateBound;
exports.deflateCopy = deflateCopy;
exports.deflateParams = deflateParams;
exports.deflatePending = deflatePending;
exports.deflatePrime = deflatePrime;
exports.deflateTune = deflateTune;
*/


/***/ }),

/***/ 2888:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


// (C) 1995-2013 Jean-loup Gailly and Mark Adler
// (C) 2014-2017 Vitaly Puzrin and Andrey Tupitsin
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//   claim that you wrote the original software. If you use this software
//   in a product, an acknowledgment in the product documentation would be
//   appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//   misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.

var utils = __webpack_require__(1624);

/* Public constants ==========================================================*/
/* ===========================================================================*/


//var Z_FILTERED          = 1;
//var Z_HUFFMAN_ONLY      = 2;
//var Z_RLE               = 3;
var Z_FIXED               = 4;
//var Z_DEFAULT_STRATEGY  = 0;

/* Possible values of the data_type field (though see inflate()) */
var Z_BINARY              = 0;
var Z_TEXT                = 1;
//var Z_ASCII             = 1; // = Z_TEXT
var Z_UNKNOWN             = 2;

/*============================================================================*/


function zero(buf) { var len = buf.length; while (--len >= 0) { buf[len] = 0; } }

// From zutil.h

var STORED_BLOCK = 0;
var STATIC_TREES = 1;
var DYN_TREES    = 2;
/* The three kinds of block type */

var MIN_MATCH    = 3;
var MAX_MATCH    = 258;
/* The minimum and maximum match lengths */

// From deflate.h
/* ===========================================================================
 * Internal compression state.
 */

var LENGTH_CODES  = 29;
/* number of length codes, not counting the special END_BLOCK code */

var LITERALS      = 256;
/* number of literal bytes 0..255 */

var L_CODES       = LITERALS + 1 + LENGTH_CODES;
/* number of Literal or Length codes, including the END_BLOCK code */

var D_CODES       = 30;
/* number of distance codes */

var BL_CODES      = 19;
/* number of codes used to transfer the bit lengths */

var HEAP_SIZE     = 2 * L_CODES + 1;
/* maximum heap size */

var MAX_BITS      = 15;
/* All codes must not exceed MAX_BITS bits */

var Buf_size      = 16;
/* size of bit buffer in bi_buf */


/* ===========================================================================
 * Constants
 */

var MAX_BL_BITS = 7;
/* Bit length codes must not exceed MAX_BL_BITS bits */

var END_BLOCK   = 256;
/* end of block literal code */

var REP_3_6     = 16;
/* repeat previous bit length 3-6 times (2 bits of repeat count) */

var REPZ_3_10   = 17;
/* repeat a zero length 3-10 times  (3 bits of repeat count) */

var REPZ_11_138 = 18;
/* repeat a zero length 11-138 times  (7 bits of repeat count) */

/* eslint-disable comma-spacing,array-bracket-spacing */
var extra_lbits =   /* extra bits for each length code */
  [0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0];

var extra_dbits =   /* extra bits for each distance code */
  [0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13];

var extra_blbits =  /* extra bits for each bit length code */
  [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,3,7];

var bl_order =
  [16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15];
/* eslint-enable comma-spacing,array-bracket-spacing */

/* The lengths of the bit length codes are sent in order of decreasing
 * probability, to avoid transmitting the lengths for unused bit length codes.
 */

/* ===========================================================================
 * Local data. These are initialized only once.
 */

// We pre-fill arrays with 0 to avoid uninitialized gaps

var DIST_CODE_LEN = 512; /* see definition of array dist_code below */

// !!!! Use flat array instead of structure, Freq = i*2, Len = i*2+1
var static_ltree  = new Array((L_CODES + 2) * 2);
zero(static_ltree);
/* The static literal tree. Since the bit lengths are imposed, there is no
 * need for the L_CODES extra codes used during heap construction. However
 * The codes 286 and 287 are needed to build a canonical tree (see _tr_init
 * below).
 */

var static_dtree  = new Array(D_CODES * 2);
zero(static_dtree);
/* The static distance tree. (Actually a trivial tree since all codes use
 * 5 bits.)
 */

var _dist_code    = new Array(DIST_CODE_LEN);
zero(_dist_code);
/* Distance codes. The first 256 values correspond to the distances
 * 3 .. 258, the last 256 values correspond to the top 8 bits of
 * the 15 bit distances.
 */

var _length_code  = new Array(MAX_MATCH - MIN_MATCH + 1);
zero(_length_code);
/* length code for each normalized match length (0 == MIN_MATCH) */

var base_length   = new Array(LENGTH_CODES);
zero(base_length);
/* First normalized length for each code (0 = MIN_MATCH) */

var base_dist     = new Array(D_CODES);
zero(base_dist);
/* First normalized distance for each code (0 = distance of 1) */


function StaticTreeDesc(static_tree, extra_bits, extra_base, elems, max_length) {

  this.static_tree  = static_tree;  /* static tree or NULL */
  this.extra_bits   = extra_bits;   /* extra bits for each code or NULL */
  this.extra_base   = extra_base;   /* base index for extra_bits */
  this.elems        = elems;        /* max number of elements in the tree */
  this.max_length   = max_length;   /* max bit length for the codes */

  // show if `static_tree` has data or dummy - needed for monomorphic objects
  this.has_stree    = static_tree && static_tree.length;
}


var static_l_desc;
var static_d_desc;
var static_bl_desc;


function TreeDesc(dyn_tree, stat_desc) {
  this.dyn_tree = dyn_tree;     /* the dynamic tree */
  this.max_code = 0;            /* largest code with non zero frequency */
  this.stat_desc = stat_desc;   /* the corresponding static tree */
}



function d_code(dist) {
  return dist < 256 ? _dist_code[dist] : _dist_code[256 + (dist >>> 7)];
}


/* ===========================================================================
 * Output a short LSB first on the stream.
 * IN assertion: there is enough room in pendingBuf.
 */
function put_short(s, w) {
//    put_byte(s, (uch)((w) & 0xff));
//    put_byte(s, (uch)((ush)(w) >> 8));
  s.pending_buf[s.pending++] = (w) & 0xff;
  s.pending_buf[s.pending++] = (w >>> 8) & 0xff;
}


/* ===========================================================================
 * Send a value on a given number of bits.
 * IN assertion: length <= 16 and value fits in length bits.
 */
function send_bits(s, value, length) {
  if (s.bi_valid > (Buf_size - length)) {
    s.bi_buf |= (value << s.bi_valid) & 0xffff;
    put_short(s, s.bi_buf);
    s.bi_buf = value >> (Buf_size - s.bi_valid);
    s.bi_valid += length - Buf_size;
  } else {
    s.bi_buf |= (value << s.bi_valid) & 0xffff;
    s.bi_valid += length;
  }
}


function send_code(s, c, tree) {
  send_bits(s, tree[c * 2]/*.Code*/, tree[c * 2 + 1]/*.Len*/);
}


/* ===========================================================================
 * Reverse the first len bits of a code, using straightforward code (a faster
 * method would use a table)
 * IN assertion: 1 <= len <= 15
 */
function bi_reverse(code, len) {
  var res = 0;
  do {
    res |= code & 1;
    code >>>= 1;
    res <<= 1;
  } while (--len > 0);
  return res >>> 1;
}


/* ===========================================================================
 * Flush the bit buffer, keeping at most 7 bits in it.
 */
function bi_flush(s) {
  if (s.bi_valid === 16) {
    put_short(s, s.bi_buf);
    s.bi_buf = 0;
    s.bi_valid = 0;

  } else if (s.bi_valid >= 8) {
    s.pending_buf[s.pending++] = s.bi_buf & 0xff;
    s.bi_buf >>= 8;
    s.bi_valid -= 8;
  }
}


/* ===========================================================================
 * Compute the optimal bit lengths for a tree and update the total bit length
 * for the current block.
 * IN assertion: the fields freq and dad are set, heap[heap_max] and
 *    above are the tree nodes sorted by increasing frequency.
 * OUT assertions: the field len is set to the optimal bit length, the
 *     array bl_count contains the frequencies for each bit length.
 *     The length opt_len is updated; static_len is also updated if stree is
 *     not null.
 */
function gen_bitlen(s, desc)
//    deflate_state *s;
//    tree_desc *desc;    /* the tree descriptor */
{
  var tree            = desc.dyn_tree;
  var max_code        = desc.max_code;
  var stree           = desc.stat_desc.static_tree;
  var has_stree       = desc.stat_desc.has_stree;
  var extra           = desc.stat_desc.extra_bits;
  var base            = desc.stat_desc.extra_base;
  var max_length      = desc.stat_desc.max_length;
  var h;              /* heap index */
  var n, m;           /* iterate over the tree elements */
  var bits;           /* bit length */
  var xbits;          /* extra bits */
  var f;              /* frequency */
  var overflow = 0;   /* number of elements with bit length too large */

  for (bits = 0; bits <= MAX_BITS; bits++) {
    s.bl_count[bits] = 0;
  }

  /* In a first pass, compute the optimal bit lengths (which may
   * overflow in the case of the bit length tree).
   */
  tree[s.heap[s.heap_max] * 2 + 1]/*.Len*/ = 0; /* root of the heap */

  for (h = s.heap_max + 1; h < HEAP_SIZE; h++) {
    n = s.heap[h];
    bits = tree[tree[n * 2 + 1]/*.Dad*/ * 2 + 1]/*.Len*/ + 1;
    if (bits > max_length) {
      bits = max_length;
      overflow++;
    }
    tree[n * 2 + 1]/*.Len*/ = bits;
    /* We overwrite tree[n].Dad which is no longer needed */

    if (n > max_code) { continue; } /* not a leaf node */

    s.bl_count[bits]++;
    xbits = 0;
    if (n >= base) {
      xbits = extra[n - base];
    }
    f = tree[n * 2]/*.Freq*/;
    s.opt_len += f * (bits + xbits);
    if (has_stree) {
      s.static_len += f * (stree[n * 2 + 1]/*.Len*/ + xbits);
    }
  }
  if (overflow === 0) { return; }

  // Trace((stderr,"\nbit length overflow\n"));
  /* This happens for example on obj2 and pic of the Calgary corpus */

  /* Find the first bit length which could increase: */
  do {
    bits = max_length - 1;
    while (s.bl_count[bits] === 0) { bits--; }
    s.bl_count[bits]--;      /* move one leaf down the tree */
    s.bl_count[bits + 1] += 2; /* move one overflow item as its brother */
    s.bl_count[max_length]--;
    /* The brother of the overflow item also moves one step up,
     * but this does not affect bl_count[max_length]
     */
    overflow -= 2;
  } while (overflow > 0);

  /* Now recompute all bit lengths, scanning in increasing frequency.
   * h is still equal to HEAP_SIZE. (It is simpler to reconstruct all
   * lengths instead of fixing only the wrong ones. This idea is taken
   * from 'ar' written by Haruhiko Okumura.)
   */
  for (bits = max_length; bits !== 0; bits--) {
    n = s.bl_count[bits];
    while (n !== 0) {
      m = s.heap[--h];
      if (m > max_code) { continue; }
      if (tree[m * 2 + 1]/*.Len*/ !== bits) {
        // Trace((stderr,"code %d bits %d->%d\n", m, tree[m].Len, bits));
        s.opt_len += (bits - tree[m * 2 + 1]/*.Len*/) * tree[m * 2]/*.Freq*/;
        tree[m * 2 + 1]/*.Len*/ = bits;
      }
      n--;
    }
  }
}


/* ===========================================================================
 * Generate the codes for a given tree and bit counts (which need not be
 * optimal).
 * IN assertion: the array bl_count contains the bit length statistics for
 * the given tree and the field len is set for all tree elements.
 * OUT assertion: the field code is set for all tree elements of non
 *     zero code length.
 */
function gen_codes(tree, max_code, bl_count)
//    ct_data *tree;             /* the tree to decorate */
//    int max_code;              /* largest code with non zero frequency */
//    ushf *bl_count;            /* number of codes at each bit length */
{
  var next_code = new Array(MAX_BITS + 1); /* next code value for each bit length */
  var code = 0;              /* running code value */
  var bits;                  /* bit index */
  var n;                     /* code index */

  /* The distribution counts are first used to generate the code values
   * without bit reversal.
   */
  for (bits = 1; bits <= MAX_BITS; bits++) {
    next_code[bits] = code = (code + bl_count[bits - 1]) << 1;
  }
  /* Check that the bit counts in bl_count are consistent. The last code
   * must be all ones.
   */
  //Assert (code + bl_count[MAX_BITS]-1 == (1<<MAX_BITS)-1,
  //        "inconsistent bit counts");
  //Tracev((stderr,"\ngen_codes: max_code %d ", max_code));

  for (n = 0;  n <= max_code; n++) {
    var len = tree[n * 2 + 1]/*.Len*/;
    if (len === 0) { continue; }
    /* Now reverse the bits */
    tree[n * 2]/*.Code*/ = bi_reverse(next_code[len]++, len);

    //Tracecv(tree != static_ltree, (stderr,"\nn %3d %c l %2d c %4x (%x) ",
    //     n, (isgraph(n) ? n : ' '), len, tree[n].Code, next_code[len]-1));
  }
}


/* ===========================================================================
 * Initialize the various 'constant' tables.
 */
function tr_static_init() {
  var n;        /* iterates over tree elements */
  var bits;     /* bit counter */
  var length;   /* length value */
  var code;     /* code value */
  var dist;     /* distance index */
  var bl_count = new Array(MAX_BITS + 1);
  /* number of codes at each bit length for an optimal tree */

  // do check in _tr_init()
  //if (static_init_done) return;

  /* For some embedded targets, global variables are not initialized: */
/*#ifdef NO_INIT_GLOBAL_POINTERS
  static_l_desc.static_tree = static_ltree;
  static_l_desc.extra_bits = extra_lbits;
  static_d_desc.static_tree = static_dtree;
  static_d_desc.extra_bits = extra_dbits;
  static_bl_desc.extra_bits = extra_blbits;
#endif*/

  /* Initialize the mapping length (0..255) -> length code (0..28) */
  length = 0;
  for (code = 0; code < LENGTH_CODES - 1; code++) {
    base_length[code] = length;
    for (n = 0; n < (1 << extra_lbits[code]); n++) {
      _length_code[length++] = code;
    }
  }
  //Assert (length == 256, "tr_static_init: length != 256");
  /* Note that the length 255 (match length 258) can be represented
   * in two different ways: code 284 + 5 bits or code 285, so we
   * overwrite length_code[255] to use the best encoding:
   */
  _length_code[length - 1] = code;

  /* Initialize the mapping dist (0..32K) -> dist code (0..29) */
  dist = 0;
  for (code = 0; code < 16; code++) {
    base_dist[code] = dist;
    for (n = 0; n < (1 << extra_dbits[code]); n++) {
      _dist_code[dist++] = code;
    }
  }
  //Assert (dist == 256, "tr_static_init: dist != 256");
  dist >>= 7; /* from now on, all distances are divided by 128 */
  for (; code < D_CODES; code++) {
    base_dist[code] = dist << 7;
    for (n = 0; n < (1 << (extra_dbits[code] - 7)); n++) {
      _dist_code[256 + dist++] = code;
    }
  }
  //Assert (dist == 256, "tr_static_init: 256+dist != 512");

  /* Construct the codes of the static literal tree */
  for (bits = 0; bits <= MAX_BITS; bits++) {
    bl_count[bits] = 0;
  }

  n = 0;
  while (n <= 143) {
    static_ltree[n * 2 + 1]/*.Len*/ = 8;
    n++;
    bl_count[8]++;
  }
  while (n <= 255) {
    static_ltree[n * 2 + 1]/*.Len*/ = 9;
    n++;
    bl_count[9]++;
  }
  while (n <= 279) {
    static_ltree[n * 2 + 1]/*.Len*/ = 7;
    n++;
    bl_count[7]++;
  }
  while (n <= 287) {
    static_ltree[n * 2 + 1]/*.Len*/ = 8;
    n++;
    bl_count[8]++;
  }
  /* Codes 286 and 287 do not exist, but we must include them in the
   * tree construction to get a canonical Huffman tree (longest code
   * all ones)
   */
  gen_codes(static_ltree, L_CODES + 1, bl_count);

  /* The static distance tree is trivial: */
  for (n = 0; n < D_CODES; n++) {
    static_dtree[n * 2 + 1]/*.Len*/ = 5;
    static_dtree[n * 2]/*.Code*/ = bi_reverse(n, 5);
  }

  // Now data ready and we can init static trees
  static_l_desc = new StaticTreeDesc(static_ltree, extra_lbits, LITERALS + 1, L_CODES, MAX_BITS);
  static_d_desc = new StaticTreeDesc(static_dtree, extra_dbits, 0,          D_CODES, MAX_BITS);
  static_bl_desc = new StaticTreeDesc(new Array(0), extra_blbits, 0,         BL_CODES, MAX_BL_BITS);

  //static_init_done = true;
}


/* ===========================================================================
 * Initialize a new block.
 */
function init_block(s) {
  var n; /* iterates over tree elements */

  /* Initialize the trees. */
  for (n = 0; n < L_CODES;  n++) { s.dyn_ltree[n * 2]/*.Freq*/ = 0; }
  for (n = 0; n < D_CODES;  n++) { s.dyn_dtree[n * 2]/*.Freq*/ = 0; }
  for (n = 0; n < BL_CODES; n++) { s.bl_tree[n * 2]/*.Freq*/ = 0; }

  s.dyn_ltree[END_BLOCK * 2]/*.Freq*/ = 1;
  s.opt_len = s.static_len = 0;
  s.last_lit = s.matches = 0;
}


/* ===========================================================================
 * Flush the bit buffer and align the output on a byte boundary
 */
function bi_windup(s)
{
  if (s.bi_valid > 8) {
    put_short(s, s.bi_buf);
  } else if (s.bi_valid > 0) {
    //put_byte(s, (Byte)s->bi_buf);
    s.pending_buf[s.pending++] = s.bi_buf;
  }
  s.bi_buf = 0;
  s.bi_valid = 0;
}

/* ===========================================================================
 * Copy a stored block, storing first the length and its
 * one's complement if requested.
 */
function copy_block(s, buf, len, header)
//DeflateState *s;
//charf    *buf;    /* the input data */
//unsigned len;     /* its length */
//int      header;  /* true if block header must be written */
{
  bi_windup(s);        /* align on byte boundary */

  if (header) {
    put_short(s, len);
    put_short(s, ~len);
  }
//  while (len--) {
//    put_byte(s, *buf++);
//  }
  utils.arraySet(s.pending_buf, s.window, buf, len, s.pending);
  s.pending += len;
}

/* ===========================================================================
 * Compares to subtrees, using the tree depth as tie breaker when
 * the subtrees have equal frequency. This minimizes the worst case length.
 */
function smaller(tree, n, m, depth) {
  var _n2 = n * 2;
  var _m2 = m * 2;
  return (tree[_n2]/*.Freq*/ < tree[_m2]/*.Freq*/ ||
         (tree[_n2]/*.Freq*/ === tree[_m2]/*.Freq*/ && depth[n] <= depth[m]));
}

/* ===========================================================================
 * Restore the heap property by moving down the tree starting at node k,
 * exchanging a node with the smallest of its two sons if necessary, stopping
 * when the heap property is re-established (each father smaller than its
 * two sons).
 */
function pqdownheap(s, tree, k)
//    deflate_state *s;
//    ct_data *tree;  /* the tree to restore */
//    int k;               /* node to move down */
{
  var v = s.heap[k];
  var j = k << 1;  /* left son of k */
  while (j <= s.heap_len) {
    /* Set j to the smallest of the two sons: */
    if (j < s.heap_len &&
      smaller(tree, s.heap[j + 1], s.heap[j], s.depth)) {
      j++;
    }
    /* Exit if v is smaller than both sons */
    if (smaller(tree, v, s.heap[j], s.depth)) { break; }

    /* Exchange v with the smallest son */
    s.heap[k] = s.heap[j];
    k = j;

    /* And continue down the tree, setting j to the left son of k */
    j <<= 1;
  }
  s.heap[k] = v;
}


// inlined manually
// var SMALLEST = 1;

/* ===========================================================================
 * Send the block data compressed using the given Huffman trees
 */
function compress_block(s, ltree, dtree)
//    deflate_state *s;
//    const ct_data *ltree; /* literal tree */
//    const ct_data *dtree; /* distance tree */
{
  var dist;           /* distance of matched string */
  var lc;             /* match length or unmatched char (if dist == 0) */
  var lx = 0;         /* running index in l_buf */
  var code;           /* the code to send */
  var extra;          /* number of extra bits to send */

  if (s.last_lit !== 0) {
    do {
      dist = (s.pending_buf[s.d_buf + lx * 2] << 8) | (s.pending_buf[s.d_buf + lx * 2 + 1]);
      lc = s.pending_buf[s.l_buf + lx];
      lx++;

      if (dist === 0) {
        send_code(s, lc, ltree); /* send a literal byte */
        //Tracecv(isgraph(lc), (stderr," '%c' ", lc));
      } else {
        /* Here, lc is the match length - MIN_MATCH */
        code = _length_code[lc];
        send_code(s, code + LITERALS + 1, ltree); /* send the length code */
        extra = extra_lbits[code];
        if (extra !== 0) {
          lc -= base_length[code];
          send_bits(s, lc, extra);       /* send the extra length bits */
        }
        dist--; /* dist is now the match distance - 1 */
        code = d_code(dist);
        //Assert (code < D_CODES, "bad d_code");

        send_code(s, code, dtree);       /* send the distance code */
        extra = extra_dbits[code];
        if (extra !== 0) {
          dist -= base_dist[code];
          send_bits(s, dist, extra);   /* send the extra distance bits */
        }
      } /* literal or match pair ? */

      /* Check that the overlay between pending_buf and d_buf+l_buf is ok: */
      //Assert((uInt)(s->pending) < s->lit_bufsize + 2*lx,
      //       "pendingBuf overflow");

    } while (lx < s.last_lit);
  }

  send_code(s, END_BLOCK, ltree);
}


/* ===========================================================================
 * Construct one Huffman tree and assigns the code bit strings and lengths.
 * Update the total bit length for the current block.
 * IN assertion: the field freq is set for all tree elements.
 * OUT assertions: the fields len and code are set to the optimal bit length
 *     and corresponding code. The length opt_len is updated; static_len is
 *     also updated if stree is not null. The field max_code is set.
 */
function build_tree(s, desc)
//    deflate_state *s;
//    tree_desc *desc; /* the tree descriptor */
{
  var tree     = desc.dyn_tree;
  var stree    = desc.stat_desc.static_tree;
  var has_stree = desc.stat_desc.has_stree;
  var elems    = desc.stat_desc.elems;
  var n, m;          /* iterate over heap elements */
  var max_code = -1; /* largest code with non zero frequency */
  var node;          /* new node being created */

  /* Construct the initial heap, with least frequent element in
   * heap[SMALLEST]. The sons of heap[n] are heap[2*n] and heap[2*n+1].
   * heap[0] is not used.
   */
  s.heap_len = 0;
  s.heap_max = HEAP_SIZE;

  for (n = 0; n < elems; n++) {
    if (tree[n * 2]/*.Freq*/ !== 0) {
      s.heap[++s.heap_len] = max_code = n;
      s.depth[n] = 0;

    } else {
      tree[n * 2 + 1]/*.Len*/ = 0;
    }
  }

  /* The pkzip format requires that at least one distance code exists,
   * and that at least one bit should be sent even if there is only one
   * possible code. So to avoid special checks later on we force at least
   * two codes of non zero frequency.
   */
  while (s.heap_len < 2) {
    node = s.heap[++s.heap_len] = (max_code < 2 ? ++max_code : 0);
    tree[node * 2]/*.Freq*/ = 1;
    s.depth[node] = 0;
    s.opt_len--;

    if (has_stree) {
      s.static_len -= stree[node * 2 + 1]/*.Len*/;
    }
    /* node is 0 or 1 so it does not have extra bits */
  }
  desc.max_code = max_code;

  /* The elements heap[heap_len/2+1 .. heap_len] are leaves of the tree,
   * establish sub-heaps of increasing lengths:
   */
  for (n = (s.heap_len >> 1/*int /2*/); n >= 1; n--) { pqdownheap(s, tree, n); }

  /* Construct the Huffman tree by repeatedly combining the least two
   * frequent nodes.
   */
  node = elems;              /* next internal node of the tree */
  do {
    //pqremove(s, tree, n);  /* n = node of least frequency */
    /*** pqremove ***/
    n = s.heap[1/*SMALLEST*/];
    s.heap[1/*SMALLEST*/] = s.heap[s.heap_len--];
    pqdownheap(s, tree, 1/*SMALLEST*/);
    /***/

    m = s.heap[1/*SMALLEST*/]; /* m = node of next least frequency */

    s.heap[--s.heap_max] = n; /* keep the nodes sorted by frequency */
    s.heap[--s.heap_max] = m;

    /* Create a new node father of n and m */
    tree[node * 2]/*.Freq*/ = tree[n * 2]/*.Freq*/ + tree[m * 2]/*.Freq*/;
    s.depth[node] = (s.depth[n] >= s.depth[m] ? s.depth[n] : s.depth[m]) + 1;
    tree[n * 2 + 1]/*.Dad*/ = tree[m * 2 + 1]/*.Dad*/ = node;

    /* and insert the new node in the heap */
    s.heap[1/*SMALLEST*/] = node++;
    pqdownheap(s, tree, 1/*SMALLEST*/);

  } while (s.heap_len >= 2);

  s.heap[--s.heap_max] = s.heap[1/*SMALLEST*/];

  /* At this point, the fields freq and dad are set. We can now
   * generate the bit lengths.
   */
  gen_bitlen(s, desc);

  /* The field len is now set, we can generate the bit codes */
  gen_codes(tree, max_code, s.bl_count);
}


/* ===========================================================================
 * Scan a literal or distance tree to determine the frequencies of the codes
 * in the bit length tree.
 */
function scan_tree(s, tree, max_code)
//    deflate_state *s;
//    ct_data *tree;   /* the tree to be scanned */
//    int max_code;    /* and its largest code of non zero frequency */
{
  var n;                     /* iterates over all tree elements */
  var prevlen = -1;          /* last emitted length */
  var curlen;                /* length of current code */

  var nextlen = tree[0 * 2 + 1]/*.Len*/; /* length of next code */

  var count = 0;             /* repeat count of the current code */
  var max_count = 7;         /* max repeat count */
  var min_count = 4;         /* min repeat count */

  if (nextlen === 0) {
    max_count = 138;
    min_count = 3;
  }
  tree[(max_code + 1) * 2 + 1]/*.Len*/ = 0xffff; /* guard */

  for (n = 0; n <= max_code; n++) {
    curlen = nextlen;
    nextlen = tree[(n + 1) * 2 + 1]/*.Len*/;

    if (++count < max_count && curlen === nextlen) {
      continue;

    } else if (count < min_count) {
      s.bl_tree[curlen * 2]/*.Freq*/ += count;

    } else if (curlen !== 0) {

      if (curlen !== prevlen) { s.bl_tree[curlen * 2]/*.Freq*/++; }
      s.bl_tree[REP_3_6 * 2]/*.Freq*/++;

    } else if (count <= 10) {
      s.bl_tree[REPZ_3_10 * 2]/*.Freq*/++;

    } else {
      s.bl_tree[REPZ_11_138 * 2]/*.Freq*/++;
    }

    count = 0;
    prevlen = curlen;

    if (nextlen === 0) {
      max_count = 138;
      min_count = 3;

    } else if (curlen === nextlen) {
      max_count = 6;
      min_count = 3;

    } else {
      max_count = 7;
      min_count = 4;
    }
  }
}


/* ===========================================================================
 * Send a literal or distance tree in compressed form, using the codes in
 * bl_tree.
 */
function send_tree(s, tree, max_code)
//    deflate_state *s;
//    ct_data *tree; /* the tree to be scanned */
//    int max_code;       /* and its largest code of non zero frequency */
{
  var n;                     /* iterates over all tree elements */
  var prevlen = -1;          /* last emitted length */
  var curlen;                /* length of current code */

  var nextlen = tree[0 * 2 + 1]/*.Len*/; /* length of next code */

  var count = 0;             /* repeat count of the current code */
  var max_count = 7;         /* max repeat count */
  var min_count = 4;         /* min repeat count */

  /* tree[max_code+1].Len = -1; */  /* guard already set */
  if (nextlen === 0) {
    max_count = 138;
    min_count = 3;
  }

  for (n = 0; n <= max_code; n++) {
    curlen = nextlen;
    nextlen = tree[(n + 1) * 2 + 1]/*.Len*/;

    if (++count < max_count && curlen === nextlen) {
      continue;

    } else if (count < min_count) {
      do { send_code(s, curlen, s.bl_tree); } while (--count !== 0);

    } else if (curlen !== 0) {
      if (curlen !== prevlen) {
        send_code(s, curlen, s.bl_tree);
        count--;
      }
      //Assert(count >= 3 && count <= 6, " 3_6?");
      send_code(s, REP_3_6, s.bl_tree);
      send_bits(s, count - 3, 2);

    } else if (count <= 10) {
      send_code(s, REPZ_3_10, s.bl_tree);
      send_bits(s, count - 3, 3);

    } else {
      send_code(s, REPZ_11_138, s.bl_tree);
      send_bits(s, count - 11, 7);
    }

    count = 0;
    prevlen = curlen;
    if (nextlen === 0) {
      max_count = 138;
      min_count = 3;

    } else if (curlen === nextlen) {
      max_count = 6;
      min_count = 3;

    } else {
      max_count = 7;
      min_count = 4;
    }
  }
}


/* ===========================================================================
 * Construct the Huffman tree for the bit lengths and return the index in
 * bl_order of the last bit length code to send.
 */
function build_bl_tree(s) {
  var max_blindex;  /* index of last bit length code of non zero freq */

  /* Determine the bit length frequencies for literal and distance trees */
  scan_tree(s, s.dyn_ltree, s.l_desc.max_code);
  scan_tree(s, s.dyn_dtree, s.d_desc.max_code);

  /* Build the bit length tree: */
  build_tree(s, s.bl_desc);
  /* opt_len now includes the length of the tree representations, except
   * the lengths of the bit lengths codes and the 5+5+4 bits for the counts.
   */

  /* Determine the number of bit length codes to send. The pkzip format
   * requires that at least 4 bit length codes be sent. (appnote.txt says
   * 3 but the actual value used is 4.)
   */
  for (max_blindex = BL_CODES - 1; max_blindex >= 3; max_blindex--) {
    if (s.bl_tree[bl_order[max_blindex] * 2 + 1]/*.Len*/ !== 0) {
      break;
    }
  }
  /* Update opt_len to include the bit length tree and counts */
  s.opt_len += 3 * (max_blindex + 1) + 5 + 5 + 4;
  //Tracev((stderr, "\ndyn trees: dyn %ld, stat %ld",
  //        s->opt_len, s->static_len));

  return max_blindex;
}


/* ===========================================================================
 * Send the header for a block using dynamic Huffman trees: the counts, the
 * lengths of the bit length codes, the literal tree and the distance tree.
 * IN assertion: lcodes >= 257, dcodes >= 1, blcodes >= 4.
 */
function send_all_trees(s, lcodes, dcodes, blcodes)
//    deflate_state *s;
//    int lcodes, dcodes, blcodes; /* number of codes for each tree */
{
  var rank;                    /* index in bl_order */

  //Assert (lcodes >= 257 && dcodes >= 1 && blcodes >= 4, "not enough codes");
  //Assert (lcodes <= L_CODES && dcodes <= D_CODES && blcodes <= BL_CODES,
  //        "too many codes");
  //Tracev((stderr, "\nbl counts: "));
  send_bits(s, lcodes - 257, 5); /* not +255 as stated in appnote.txt */
  send_bits(s, dcodes - 1,   5);
  send_bits(s, blcodes - 4,  4); /* not -3 as stated in appnote.txt */
  for (rank = 0; rank < blcodes; rank++) {
    //Tracev((stderr, "\nbl code %2d ", bl_order[rank]));
    send_bits(s, s.bl_tree[bl_order[rank] * 2 + 1]/*.Len*/, 3);
  }
  //Tracev((stderr, "\nbl tree: sent %ld", s->bits_sent));

  send_tree(s, s.dyn_ltree, lcodes - 1); /* literal tree */
  //Tracev((stderr, "\nlit tree: sent %ld", s->bits_sent));

  send_tree(s, s.dyn_dtree, dcodes - 1); /* distance tree */
  //Tracev((stderr, "\ndist tree: sent %ld", s->bits_sent));
}


/* ===========================================================================
 * Check if the data type is TEXT or BINARY, using the following algorithm:
 * - TEXT if the two conditions below are satisfied:
 *    a) There are no non-portable control characters belonging to the
 *       "black list" (0..6, 14..25, 28..31).
 *    b) There is at least one printable character belonging to the
 *       "white list" (9 {TAB}, 10 {LF}, 13 {CR}, 32..255).
 * - BINARY otherwise.
 * - The following partially-portable control characters form a
 *   "gray list" that is ignored in this detection algorithm:
 *   (7 {BEL}, 8 {BS}, 11 {VT}, 12 {FF}, 26 {SUB}, 27 {ESC}).
 * IN assertion: the fields Freq of dyn_ltree are set.
 */
function detect_data_type(s) {
  /* black_mask is the bit mask of black-listed bytes
   * set bits 0..6, 14..25, and 28..31
   * 0xf3ffc07f = binary 11110011111111111100000001111111
   */
  var black_mask = 0xf3ffc07f;
  var n;

  /* Check for non-textual ("black-listed") bytes. */
  for (n = 0; n <= 31; n++, black_mask >>>= 1) {
    if ((black_mask & 1) && (s.dyn_ltree[n * 2]/*.Freq*/ !== 0)) {
      return Z_BINARY;
    }
  }

  /* Check for textual ("white-listed") bytes. */
  if (s.dyn_ltree[9 * 2]/*.Freq*/ !== 0 || s.dyn_ltree[10 * 2]/*.Freq*/ !== 0 ||
      s.dyn_ltree[13 * 2]/*.Freq*/ !== 0) {
    return Z_TEXT;
  }
  for (n = 32; n < LITERALS; n++) {
    if (s.dyn_ltree[n * 2]/*.Freq*/ !== 0) {
      return Z_TEXT;
    }
  }

  /* There are no "black-listed" or "white-listed" bytes:
   * this stream either is empty or has tolerated ("gray-listed") bytes only.
   */
  return Z_BINARY;
}


var static_init_done = false;

/* ===========================================================================
 * Initialize the tree data structures for a new zlib stream.
 */
function _tr_init(s)
{

  if (!static_init_done) {
    tr_static_init();
    static_init_done = true;
  }

  s.l_desc  = new TreeDesc(s.dyn_ltree, static_l_desc);
  s.d_desc  = new TreeDesc(s.dyn_dtree, static_d_desc);
  s.bl_desc = new TreeDesc(s.bl_tree, static_bl_desc);

  s.bi_buf = 0;
  s.bi_valid = 0;

  /* Initialize the first block of the first file: */
  init_block(s);
}


/* ===========================================================================
 * Send a stored block
 */
function _tr_stored_block(s, buf, stored_len, last)
//DeflateState *s;
//charf *buf;       /* input block */
//ulg stored_len;   /* length of input block */
//int last;         /* one if this is the last block for a file */
{
  send_bits(s, (STORED_BLOCK << 1) + (last ? 1 : 0), 3);    /* send block type */
  copy_block(s, buf, stored_len, true); /* with header */
}


/* ===========================================================================
 * Send one empty static block to give enough lookahead for inflate.
 * This takes 10 bits, of which 7 may remain in the bit buffer.
 */
function _tr_align(s) {
  send_bits(s, STATIC_TREES << 1, 3);
  send_code(s, END_BLOCK, static_ltree);
  bi_flush(s);
}


/* ===========================================================================
 * Determine the best encoding for the current block: dynamic trees, static
 * trees or store, and output the encoded block to the zip file.
 */
function _tr_flush_block(s, buf, stored_len, last)
//DeflateState *s;
//charf *buf;       /* input block, or NULL if too old */
//ulg stored_len;   /* length of input block */
//int last;         /* one if this is the last block for a file */
{
  var opt_lenb, static_lenb;  /* opt_len and static_len in bytes */
  var max_blindex = 0;        /* index of last bit length code of non zero freq */

  /* Build the Huffman trees unless a stored block is forced */
  if (s.level > 0) {

    /* Check if the file is binary or text */
    if (s.strm.data_type === Z_UNKNOWN) {
      s.strm.data_type = detect_data_type(s);
    }

    /* Construct the literal and distance trees */
    build_tree(s, s.l_desc);
    // Tracev((stderr, "\nlit data: dyn %ld, stat %ld", s->opt_len,
    //        s->static_len));

    build_tree(s, s.d_desc);
    // Tracev((stderr, "\ndist data: dyn %ld, stat %ld", s->opt_len,
    //        s->static_len));
    /* At this point, opt_len and static_len are the total bit lengths of
     * the compressed block data, excluding the tree representations.
     */

    /* Build the bit length tree for the above two trees, and get the index
     * in bl_order of the last bit length code to send.
     */
    max_blindex = build_bl_tree(s);

    /* Determine the best encoding. Compute the block lengths in bytes. */
    opt_lenb = (s.opt_len + 3 + 7) >>> 3;
    static_lenb = (s.static_len + 3 + 7) >>> 3;

    // Tracev((stderr, "\nopt %lu(%lu) stat %lu(%lu) stored %lu lit %u ",
    //        opt_lenb, s->opt_len, static_lenb, s->static_len, stored_len,
    //        s->last_lit));

    if (static_lenb <= opt_lenb) { opt_lenb = static_lenb; }

  } else {
    // Assert(buf != (char*)0, "lost buf");
    opt_lenb = static_lenb = stored_len + 5; /* force a stored block */
  }

  if ((stored_len + 4 <= opt_lenb) && (buf !== -1)) {
    /* 4: two words for the lengths */

    /* The test buf != NULL is only necessary if LIT_BUFSIZE > WSIZE.
     * Otherwise we can't have processed more than WSIZE input bytes since
     * the last block flush, because compression would have been
     * successful. If LIT_BUFSIZE <= WSIZE, it is never too late to
     * transform a block into a stored block.
     */
    _tr_stored_block(s, buf, stored_len, last);

  } else if (s.strategy === Z_FIXED || static_lenb === opt_lenb) {

    send_bits(s, (STATIC_TREES << 1) + (last ? 1 : 0), 3);
    compress_block(s, static_ltree, static_dtree);

  } else {
    send_bits(s, (DYN_TREES << 1) + (last ? 1 : 0), 3);
    send_all_trees(s, s.l_desc.max_code + 1, s.d_desc.max_code + 1, max_blindex + 1);
    compress_block(s, s.dyn_ltree, s.dyn_dtree);
  }
  // Assert (s->compressed_len == s->bits_sent, "bad compressed size");
  /* The above check is made mod 2^32, for files larger than 512 MB
   * and uLong implemented on 32 bits.
   */
  init_block(s);

  if (last) {
    bi_windup(s);
  }
  // Tracev((stderr,"\ncomprlen %lu(%lu) ", s->compressed_len>>3,
  //       s->compressed_len-7*last));
}

/* ===========================================================================
 * Save the match info and tally the frequency counts. Return true if
 * the current block must be flushed.
 */
function _tr_tally(s, dist, lc)
//    deflate_state *s;
//    unsigned dist;  /* distance of matched string */
//    unsigned lc;    /* match length-MIN_MATCH or unmatched char (if dist==0) */
{
  //var out_length, in_length, dcode;

  s.pending_buf[s.d_buf + s.last_lit * 2]     = (dist >>> 8) & 0xff;
  s.pending_buf[s.d_buf + s.last_lit * 2 + 1] = dist & 0xff;

  s.pending_buf[s.l_buf + s.last_lit] = lc & 0xff;
  s.last_lit++;

  if (dist === 0) {
    /* lc is the unmatched char */
    s.dyn_ltree[lc * 2]/*.Freq*/++;
  } else {
    s.matches++;
    /* Here, lc is the match length - MIN_MATCH */
    dist--;             /* dist = match distance - 1 */
    //Assert((ush)dist < (ush)MAX_DIST(s) &&
    //       (ush)lc <= (ush)(MAX_MATCH-MIN_MATCH) &&
    //       (ush)d_code(dist) < (ush)D_CODES,  "_tr_tally: bad match");

    s.dyn_ltree[(_length_code[lc] + LITERALS + 1) * 2]/*.Freq*/++;
    s.dyn_dtree[d_code(dist) * 2]/*.Freq*/++;
  }

// (!) This block is disabled in zlib defaults,
// don't enable it for binary compatibility

//#ifdef TRUNCATE_BLOCK
//  /* Try to guess if it is profitable to stop the current block here */
//  if ((s.last_lit & 0x1fff) === 0 && s.level > 2) {
//    /* Compute an upper bound for the compressed length */
//    out_length = s.last_lit*8;
//    in_length = s.strstart - s.block_start;
//
//    for (dcode = 0; dcode < D_CODES; dcode++) {
//      out_length += s.dyn_dtree[dcode*2]/*.Freq*/ * (5 + extra_dbits[dcode]);
//    }
//    out_length >>>= 3;
//    //Tracev((stderr,"\nlast_lit %u, in %ld, out ~%ld(%ld%%) ",
//    //       s->last_lit, in_length, out_length,
//    //       100L - out_length*100L/in_length));
//    if (s.matches < (s.last_lit>>1)/*int /2*/ && out_length < (in_length>>1)/*int /2*/) {
//      return true;
//    }
//  }
//#endif

  return (s.last_lit === s.lit_bufsize - 1);
  /* We avoid equality with lit_bufsize because of wraparound at 64K
   * on 16 bit machines and because stored blocks are restricted to
   * 64K-1 bytes.
   */
}

exports._tr_init  = _tr_init;
exports._tr_stored_block = _tr_stored_block;
exports._tr_flush_block  = _tr_flush_block;
exports._tr_tally = _tr_tally;
exports._tr_align = _tr_align;


/***/ }),

/***/ 2889:
/***/ (function(module, exports, __webpack_require__) {

"use strict";



var zlib_inflate = __webpack_require__(2890);
var utils        = __webpack_require__(1624);
var strings      = __webpack_require__(2018);
var c            = __webpack_require__(2020);
var msg          = __webpack_require__(1795);
var ZStream      = __webpack_require__(2019);
var GZheader     = __webpack_require__(2893);

var toString = Object.prototype.toString;

/**
 * class Inflate
 *
 * Generic JS-style wrapper for zlib calls. If you don't need
 * streaming behaviour - use more simple functions: [[inflate]]
 * and [[inflateRaw]].
 **/

/* internal
 * inflate.chunks -> Array
 *
 * Chunks of output data, if [[Inflate#onData]] not overridden.
 **/

/**
 * Inflate.result -> Uint8Array|Array|String
 *
 * Uncompressed result, generated by default [[Inflate#onData]]
 * and [[Inflate#onEnd]] handlers. Filled after you push last chunk
 * (call [[Inflate#push]] with `Z_FINISH` / `true` param) or if you
 * push a chunk with explicit flush (call [[Inflate#push]] with
 * `Z_SYNC_FLUSH` param).
 **/

/**
 * Inflate.err -> Number
 *
 * Error code after inflate finished. 0 (Z_OK) on success.
 * Should be checked if broken data possible.
 **/

/**
 * Inflate.msg -> String
 *
 * Error message, if [[Inflate.err]] != 0
 **/


/**
 * new Inflate(options)
 * - options (Object): zlib inflate options.
 *
 * Creates new inflator instance with specified params. Throws exception
 * on bad params. Supported options:
 *
 * - `windowBits`
 * - `dictionary`
 *
 * [http://zlib.net/manual.html#Advanced](http://zlib.net/manual.html#Advanced)
 * for more information on these.
 *
 * Additional options, for internal needs:
 *
 * - `chunkSize` - size of generated data chunks (16K by default)
 * - `raw` (Boolean) - do raw inflate
 * - `to` (String) - if equal to 'string', then result will be converted
 *   from utf8 to utf16 (javascript) string. When string output requested,
 *   chunk length can differ from `chunkSize`, depending on content.
 *
 * By default, when no options set, autodetect deflate/gzip data format via
 * wrapper header.
 *
 * ##### Example:
 *
 * ```javascript
 * var pako = require('pako')
 *   , chunk1 = Uint8Array([1,2,3,4,5,6,7,8,9])
 *   , chunk2 = Uint8Array([10,11,12,13,14,15,16,17,18,19]);
 *
 * var inflate = new pako.Inflate({ level: 3});
 *
 * inflate.push(chunk1, false);
 * inflate.push(chunk2, true);  // true -> last chunk
 *
 * if (inflate.err) { throw new Error(inflate.err); }
 *
 * console.log(inflate.result);
 * ```
 **/
function Inflate(options) {
  if (!(this instanceof Inflate)) return new Inflate(options);

  this.options = utils.assign({
    chunkSize: 16384,
    windowBits: 0,
    to: ''
  }, options || {});

  var opt = this.options;

  // Force window size for `raw` data, if not set directly,
  // because we have no header for autodetect.
  if (opt.raw && (opt.windowBits >= 0) && (opt.windowBits < 16)) {
    opt.windowBits = -opt.windowBits;
    if (opt.windowBits === 0) { opt.windowBits = -15; }
  }

  // If `windowBits` not defined (and mode not raw) - set autodetect flag for gzip/deflate
  if ((opt.windowBits >= 0) && (opt.windowBits < 16) &&
      !(options && options.windowBits)) {
    opt.windowBits += 32;
  }

  // Gzip header has no info about windows size, we can do autodetect only
  // for deflate. So, if window size not set, force it to max when gzip possible
  if ((opt.windowBits > 15) && (opt.windowBits < 48)) {
    // bit 3 (16) -> gzipped data
    // bit 4 (32) -> autodetect gzip/deflate
    if ((opt.windowBits & 15) === 0) {
      opt.windowBits |= 15;
    }
  }

  this.err    = 0;      // error code, if happens (0 = Z_OK)
  this.msg    = '';     // error message
  this.ended  = false;  // used to avoid multiple onEnd() calls
  this.chunks = [];     // chunks of compressed data

  this.strm   = new ZStream();
  this.strm.avail_out = 0;

  var status  = zlib_inflate.inflateInit2(
    this.strm,
    opt.windowBits
  );

  if (status !== c.Z_OK) {
    throw new Error(msg[status]);
  }

  this.header = new GZheader();

  zlib_inflate.inflateGetHeader(this.strm, this.header);
}

/**
 * Inflate#push(data[, mode]) -> Boolean
 * - data (Uint8Array|Array|ArrayBuffer|String): input data
 * - mode (Number|Boolean): 0..6 for corresponding Z_NO_FLUSH..Z_TREE modes.
 *   See constants. Skipped or `false` means Z_NO_FLUSH, `true` means Z_FINISH.
 *
 * Sends input data to inflate pipe, generating [[Inflate#onData]] calls with
 * new output chunks. Returns `true` on success. The last data block must have
 * mode Z_FINISH (or `true`). That will flush internal pending buffers and call
 * [[Inflate#onEnd]]. For interim explicit flushes (without ending the stream) you
 * can use mode Z_SYNC_FLUSH, keeping the decompression context.
 *
 * On fail call [[Inflate#onEnd]] with error code and return false.
 *
 * We strongly recommend to use `Uint8Array` on input for best speed (output
 * format is detected automatically). Also, don't skip last param and always
 * use the same type in your code (boolean or number). That will improve JS speed.
 *
 * For regular `Array`-s make sure all elements are [0..255].
 *
 * ##### Example
 *
 * ```javascript
 * push(chunk, false); // push one of data chunks
 * ...
 * push(chunk, true);  // push last chunk
 * ```
 **/
Inflate.prototype.push = function (data, mode) {
  var strm = this.strm;
  var chunkSize = this.options.chunkSize;
  var dictionary = this.options.dictionary;
  var status, _mode;
  var next_out_utf8, tail, utf8str;
  var dict;

  // Flag to properly process Z_BUF_ERROR on testing inflate call
  // when we check that all output data was flushed.
  var allowBufError = false;

  if (this.ended) { return false; }
  _mode = (mode === ~~mode) ? mode : ((mode === true) ? c.Z_FINISH : c.Z_NO_FLUSH);

  // Convert data if needed
  if (typeof data === 'string') {
    // Only binary strings can be decompressed on practice
    strm.input = strings.binstring2buf(data);
  } else if (toString.call(data) === '[object ArrayBuffer]') {
    strm.input = new Uint8Array(data);
  } else {
    strm.input = data;
  }

  strm.next_in = 0;
  strm.avail_in = strm.input.length;

  do {
    if (strm.avail_out === 0) {
      strm.output = new utils.Buf8(chunkSize);
      strm.next_out = 0;
      strm.avail_out = chunkSize;
    }

    status = zlib_inflate.inflate(strm, c.Z_NO_FLUSH);    /* no bad return value */

    if (status === c.Z_NEED_DICT && dictionary) {
      // Convert data if needed
      if (typeof dictionary === 'string') {
        dict = strings.string2buf(dictionary);
      } else if (toString.call(dictionary) === '[object ArrayBuffer]') {
        dict = new Uint8Array(dictionary);
      } else {
        dict = dictionary;
      }

      status = zlib_inflate.inflateSetDictionary(this.strm, dict);

    }

    if (status === c.Z_BUF_ERROR && allowBufError === true) {
      status = c.Z_OK;
      allowBufError = false;
    }

    if (status !== c.Z_STREAM_END && status !== c.Z_OK) {
      this.onEnd(status);
      this.ended = true;
      return false;
    }

    if (strm.next_out) {
      if (strm.avail_out === 0 || status === c.Z_STREAM_END || (strm.avail_in === 0 && (_mode === c.Z_FINISH || _mode === c.Z_SYNC_FLUSH))) {

        if (this.options.to === 'string') {

          next_out_utf8 = strings.utf8border(strm.output, strm.next_out);

          tail = strm.next_out - next_out_utf8;
          utf8str = strings.buf2string(strm.output, next_out_utf8);

          // move tail
          strm.next_out = tail;
          strm.avail_out = chunkSize - tail;
          if (tail) { utils.arraySet(strm.output, strm.output, next_out_utf8, tail, 0); }

          this.onData(utf8str);

        } else {
          this.onData(utils.shrinkBuf(strm.output, strm.next_out));
        }
      }
    }

    // When no more input data, we should check that internal inflate buffers
    // are flushed. The only way to do it when avail_out = 0 - run one more
    // inflate pass. But if output data not exists, inflate return Z_BUF_ERROR.
    // Here we set flag to process this error properly.
    //
    // NOTE. Deflate does not return error in this case and does not needs such
    // logic.
    if (strm.avail_in === 0 && strm.avail_out === 0) {
      allowBufError = true;
    }

  } while ((strm.avail_in > 0 || strm.avail_out === 0) && status !== c.Z_STREAM_END);

  if (status === c.Z_STREAM_END) {
    _mode = c.Z_FINISH;
  }

  // Finalize on the last chunk.
  if (_mode === c.Z_FINISH) {
    status = zlib_inflate.inflateEnd(this.strm);
    this.onEnd(status);
    this.ended = true;
    return status === c.Z_OK;
  }

  // callback interim results if Z_SYNC_FLUSH.
  if (_mode === c.Z_SYNC_FLUSH) {
    this.onEnd(c.Z_OK);
    strm.avail_out = 0;
    return true;
  }

  return true;
};


/**
 * Inflate#onData(chunk) -> Void
 * - chunk (Uint8Array|Array|String): output data. Type of array depends
 *   on js engine support. When string output requested, each chunk
 *   will be string.
 *
 * By default, stores data blocks in `chunks[]` property and glue
 * those in `onEnd`. Override this handler, if you need another behaviour.
 **/
Inflate.prototype.onData = function (chunk) {
  this.chunks.push(chunk);
};


/**
 * Inflate#onEnd(status) -> Void
 * - status (Number): inflate status. 0 (Z_OK) on success,
 *   other if not.
 *
 * Called either after you tell inflate that the input stream is
 * complete (Z_FINISH) or should be flushed (Z_SYNC_FLUSH)
 * or if an error happened. By default - join collected chunks,
 * free memory and fill `results` / `err` properties.
 **/
Inflate.prototype.onEnd = function (status) {
  // On success - join
  if (status === c.Z_OK) {
    if (this.options.to === 'string') {
      // Glue & convert here, until we teach pako to send
      // utf8 aligned strings to onData
      this.result = this.chunks.join('');
    } else {
      this.result = utils.flattenChunks(this.chunks);
    }
  }
  this.chunks = [];
  this.err = status;
  this.msg = this.strm.msg;
};


/**
 * inflate(data[, options]) -> Uint8Array|Array|String
 * - data (Uint8Array|Array|String): input data to decompress.
 * - options (Object): zlib inflate options.
 *
 * Decompress `data` with inflate/ungzip and `options`. Autodetect
 * format via wrapper header by default. That's why we don't provide
 * separate `ungzip` method.
 *
 * Supported options are:
 *
 * - windowBits
 *
 * [http://zlib.net/manual.html#Advanced](http://zlib.net/manual.html#Advanced)
 * for more information.
 *
 * Sugar (options):
 *
 * - `raw` (Boolean) - say that we work with raw stream, if you don't wish to specify
 *   negative windowBits implicitly.
 * - `to` (String) - if equal to 'string', then result will be converted
 *   from utf8 to utf16 (javascript) string. When string output requested,
 *   chunk length can differ from `chunkSize`, depending on content.
 *
 *
 * ##### Example:
 *
 * ```javascript
 * var pako = require('pako')
 *   , input = pako.deflate([1,2,3,4,5,6,7,8,9])
 *   , output;
 *
 * try {
 *   output = pako.inflate(input);
 * } catch (err)
 *   console.log(err);
 * }
 * ```
 **/
function inflate(input, options) {
  var inflator = new Inflate(options);

  inflator.push(input, true);

  // That will never happens, if you don't cheat with options :)
  if (inflator.err) { throw inflator.msg || msg[inflator.err]; }

  return inflator.result;
}


/**
 * inflateRaw(data[, options]) -> Uint8Array|Array|String
 * - data (Uint8Array|Array|String): input data to decompress.
 * - options (Object): zlib inflate options.
 *
 * The same as [[inflate]], but creates raw data, without wrapper
 * (header and adler32 crc).
 **/
function inflateRaw(input, options) {
  options = options || {};
  options.raw = true;
  return inflate(input, options);
}


/**
 * ungzip(data[, options]) -> Uint8Array|Array|String
 * - data (Uint8Array|Array|String): input data to decompress.
 * - options (Object): zlib inflate options.
 *
 * Just shortcut to [[inflate]], because it autodetects format
 * by header.content. Done for convenience.
 **/


exports.Inflate = Inflate;
exports.inflate = inflate;
exports.inflateRaw = inflateRaw;
exports.ungzip  = inflate;


/***/ }),

/***/ 2890:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


// (C) 1995-2013 Jean-loup Gailly and Mark Adler
// (C) 2014-2017 Vitaly Puzrin and Andrey Tupitsin
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//   claim that you wrote the original software. If you use this software
//   in a product, an acknowledgment in the product documentation would be
//   appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//   misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.

var utils         = __webpack_require__(1624);
var adler32       = __webpack_require__(2016);
var crc32         = __webpack_require__(2017);
var inflate_fast  = __webpack_require__(2891);
var inflate_table = __webpack_require__(2892);

var CODES = 0;
var LENS = 1;
var DISTS = 2;

/* Public constants ==========================================================*/
/* ===========================================================================*/


/* Allowed flush values; see deflate() and inflate() below for details */
//var Z_NO_FLUSH      = 0;
//var Z_PARTIAL_FLUSH = 1;
//var Z_SYNC_FLUSH    = 2;
//var Z_FULL_FLUSH    = 3;
var Z_FINISH        = 4;
var Z_BLOCK         = 5;
var Z_TREES         = 6;


/* Return codes for the compression/decompression functions. Negative values
 * are errors, positive values are used for special but normal events.
 */
var Z_OK            = 0;
var Z_STREAM_END    = 1;
var Z_NEED_DICT     = 2;
//var Z_ERRNO         = -1;
var Z_STREAM_ERROR  = -2;
var Z_DATA_ERROR    = -3;
var Z_MEM_ERROR     = -4;
var Z_BUF_ERROR     = -5;
//var Z_VERSION_ERROR = -6;

/* The deflate compression method */
var Z_DEFLATED  = 8;


/* STATES ====================================================================*/
/* ===========================================================================*/


var    HEAD = 1;       /* i: waiting for magic header */
var    FLAGS = 2;      /* i: waiting for method and flags (gzip) */
var    TIME = 3;       /* i: waiting for modification time (gzip) */
var    OS = 4;         /* i: waiting for extra flags and operating system (gzip) */
var    EXLEN = 5;      /* i: waiting for extra length (gzip) */
var    EXTRA = 6;      /* i: waiting for extra bytes (gzip) */
var    NAME = 7;       /* i: waiting for end of file name (gzip) */
var    COMMENT = 8;    /* i: waiting for end of comment (gzip) */
var    HCRC = 9;       /* i: waiting for header crc (gzip) */
var    DICTID = 10;    /* i: waiting for dictionary check value */
var    DICT = 11;      /* waiting for inflateSetDictionary() call */
var        TYPE = 12;      /* i: waiting for type bits, including last-flag bit */
var        TYPEDO = 13;    /* i: same, but skip check to exit inflate on new block */
var        STORED = 14;    /* i: waiting for stored size (length and complement) */
var        COPY_ = 15;     /* i/o: same as COPY below, but only first time in */
var        COPY = 16;      /* i/o: waiting for input or output to copy stored block */
var        TABLE = 17;     /* i: waiting for dynamic block table lengths */
var        LENLENS = 18;   /* i: waiting for code length code lengths */
var        CODELENS = 19;  /* i: waiting for length/lit and distance code lengths */
var            LEN_ = 20;      /* i: same as LEN below, but only first time in */
var            LEN = 21;       /* i: waiting for length/lit/eob code */
var            LENEXT = 22;    /* i: waiting for length extra bits */
var            DIST = 23;      /* i: waiting for distance code */
var            DISTEXT = 24;   /* i: waiting for distance extra bits */
var            MATCH = 25;     /* o: waiting for output space to copy string */
var            LIT = 26;       /* o: waiting for output space to write literal */
var    CHECK = 27;     /* i: waiting for 32-bit check value */
var    LENGTH = 28;    /* i: waiting for 32-bit length (gzip) */
var    DONE = 29;      /* finished check, done -- remain here until reset */
var    BAD = 30;       /* got a data error -- remain here until reset */
var    MEM = 31;       /* got an inflate() memory error -- remain here until reset */
var    SYNC = 32;      /* looking for synchronization bytes to restart inflate() */

/* ===========================================================================*/



var ENOUGH_LENS = 852;
var ENOUGH_DISTS = 592;
//var ENOUGH =  (ENOUGH_LENS+ENOUGH_DISTS);

var MAX_WBITS = 15;
/* 32K LZ77 window */
var DEF_WBITS = MAX_WBITS;


function zswap32(q) {
  return  (((q >>> 24) & 0xff) +
          ((q >>> 8) & 0xff00) +
          ((q & 0xff00) << 8) +
          ((q & 0xff) << 24));
}


function InflateState() {
  this.mode = 0;             /* current inflate mode */
  this.last = false;          /* true if processing last block */
  this.wrap = 0;              /* bit 0 true for zlib, bit 1 true for gzip */
  this.havedict = false;      /* true if dictionary provided */
  this.flags = 0;             /* gzip header method and flags (0 if zlib) */
  this.dmax = 0;              /* zlib header max distance (INFLATE_STRICT) */
  this.check = 0;             /* protected copy of check value */
  this.total = 0;             /* protected copy of output count */
  // TODO: may be {}
  this.head = null;           /* where to save gzip header information */

  /* sliding window */
  this.wbits = 0;             /* log base 2 of requested window size */
  this.wsize = 0;             /* window size or zero if not using window */
  this.whave = 0;             /* valid bytes in the window */
  this.wnext = 0;             /* window write index */
  this.window = null;         /* allocated sliding window, if needed */

  /* bit accumulator */
  this.hold = 0;              /* input bit accumulator */
  this.bits = 0;              /* number of bits in "in" */

  /* for string and stored block copying */
  this.length = 0;            /* literal or length of data to copy */
  this.offset = 0;            /* distance back to copy string from */

  /* for table and code decoding */
  this.extra = 0;             /* extra bits needed */

  /* fixed and dynamic code tables */
  this.lencode = null;          /* starting table for length/literal codes */
  this.distcode = null;         /* starting table for distance codes */
  this.lenbits = 0;           /* index bits for lencode */
  this.distbits = 0;          /* index bits for distcode */

  /* dynamic table building */
  this.ncode = 0;             /* number of code length code lengths */
  this.nlen = 0;              /* number of length code lengths */
  this.ndist = 0;             /* number of distance code lengths */
  this.have = 0;              /* number of code lengths in lens[] */
  this.next = null;              /* next available space in codes[] */

  this.lens = new utils.Buf16(320); /* temporary storage for code lengths */
  this.work = new utils.Buf16(288); /* work area for code table building */

  /*
   because we don't have pointers in js, we use lencode and distcode directly
   as buffers so we don't need codes
  */
  //this.codes = new utils.Buf32(ENOUGH);       /* space for code tables */
  this.lendyn = null;              /* dynamic table for length/literal codes (JS specific) */
  this.distdyn = null;             /* dynamic table for distance codes (JS specific) */
  this.sane = 0;                   /* if false, allow invalid distance too far */
  this.back = 0;                   /* bits back of last unprocessed length/lit */
  this.was = 0;                    /* initial length of match */
}

function inflateResetKeep(strm) {
  var state;

  if (!strm || !strm.state) { return Z_STREAM_ERROR; }
  state = strm.state;
  strm.total_in = strm.total_out = state.total = 0;
  strm.msg = ''; /*Z_NULL*/
  if (state.wrap) {       /* to support ill-conceived Java test suite */
    strm.adler = state.wrap & 1;
  }
  state.mode = HEAD;
  state.last = 0;
  state.havedict = 0;
  state.dmax = 32768;
  state.head = null/*Z_NULL*/;
  state.hold = 0;
  state.bits = 0;
  //state.lencode = state.distcode = state.next = state.codes;
  state.lencode = state.lendyn = new utils.Buf32(ENOUGH_LENS);
  state.distcode = state.distdyn = new utils.Buf32(ENOUGH_DISTS);

  state.sane = 1;
  state.back = -1;
  //Tracev((stderr, "inflate: reset\n"));
  return Z_OK;
}

function inflateReset(strm) {
  var state;

  if (!strm || !strm.state) { return Z_STREAM_ERROR; }
  state = strm.state;
  state.wsize = 0;
  state.whave = 0;
  state.wnext = 0;
  return inflateResetKeep(strm);

}

function inflateReset2(strm, windowBits) {
  var wrap;
  var state;

  /* get the state */
  if (!strm || !strm.state) { return Z_STREAM_ERROR; }
  state = strm.state;

  /* extract wrap request from windowBits parameter */
  if (windowBits < 0) {
    wrap = 0;
    windowBits = -windowBits;
  }
  else {
    wrap = (windowBits >> 4) + 1;
    if (windowBits < 48) {
      windowBits &= 15;
    }
  }

  /* set number of window bits, free window if different */
  if (windowBits && (windowBits < 8 || windowBits > 15)) {
    return Z_STREAM_ERROR;
  }
  if (state.window !== null && state.wbits !== windowBits) {
    state.window = null;
  }

  /* update state and reset the rest of it */
  state.wrap = wrap;
  state.wbits = windowBits;
  return inflateReset(strm);
}

function inflateInit2(strm, windowBits) {
  var ret;
  var state;

  if (!strm) { return Z_STREAM_ERROR; }
  //strm.msg = Z_NULL;                 /* in case we return an error */

  state = new InflateState();

  //if (state === Z_NULL) return Z_MEM_ERROR;
  //Tracev((stderr, "inflate: allocated\n"));
  strm.state = state;
  state.window = null/*Z_NULL*/;
  ret = inflateReset2(strm, windowBits);
  if (ret !== Z_OK) {
    strm.state = null/*Z_NULL*/;
  }
  return ret;
}

function inflateInit(strm) {
  return inflateInit2(strm, DEF_WBITS);
}


/*
 Return state with length and distance decoding tables and index sizes set to
 fixed code decoding.  Normally this returns fixed tables from inffixed.h.
 If BUILDFIXED is defined, then instead this routine builds the tables the
 first time it's called, and returns those tables the first time and
 thereafter.  This reduces the size of the code by about 2K bytes, in
 exchange for a little execution time.  However, BUILDFIXED should not be
 used for threaded applications, since the rewriting of the tables and virgin
 may not be thread-safe.
 */
var virgin = true;

var lenfix, distfix; // We have no pointers in JS, so keep tables separate

function fixedtables(state) {
  /* build fixed huffman tables if first call (may not be thread safe) */
  if (virgin) {
    var sym;

    lenfix = new utils.Buf32(512);
    distfix = new utils.Buf32(32);

    /* literal/length table */
    sym = 0;
    while (sym < 144) { state.lens[sym++] = 8; }
    while (sym < 256) { state.lens[sym++] = 9; }
    while (sym < 280) { state.lens[sym++] = 7; }
    while (sym < 288) { state.lens[sym++] = 8; }

    inflate_table(LENS,  state.lens, 0, 288, lenfix,   0, state.work, { bits: 9 });

    /* distance table */
    sym = 0;
    while (sym < 32) { state.lens[sym++] = 5; }

    inflate_table(DISTS, state.lens, 0, 32,   distfix, 0, state.work, { bits: 5 });

    /* do this just once */
    virgin = false;
  }

  state.lencode = lenfix;
  state.lenbits = 9;
  state.distcode = distfix;
  state.distbits = 5;
}


/*
 Update the window with the last wsize (normally 32K) bytes written before
 returning.  If window does not exist yet, create it.  This is only called
 when a window is already in use, or when output has been written during this
 inflate call, but the end of the deflate stream has not been reached yet.
 It is also called to create a window for dictionary data when a dictionary
 is loaded.

 Providing output buffers larger than 32K to inflate() should provide a speed
 advantage, since only the last 32K of output is copied to the sliding window
 upon return from inflate(), and since all distances after the first 32K of
 output will fall in the output data, making match copies simpler and faster.
 The advantage may be dependent on the size of the processor's data caches.
 */
function updatewindow(strm, src, end, copy) {
  var dist;
  var state = strm.state;

  /* if it hasn't been done already, allocate space for the window */
  if (state.window === null) {
    state.wsize = 1 << state.wbits;
    state.wnext = 0;
    state.whave = 0;

    state.window = new utils.Buf8(state.wsize);
  }

  /* copy state->wsize or less output bytes into the circular window */
  if (copy >= state.wsize) {
    utils.arraySet(state.window, src, end - state.wsize, state.wsize, 0);
    state.wnext = 0;
    state.whave = state.wsize;
  }
  else {
    dist = state.wsize - state.wnext;
    if (dist > copy) {
      dist = copy;
    }
    //zmemcpy(state->window + state->wnext, end - copy, dist);
    utils.arraySet(state.window, src, end - copy, dist, state.wnext);
    copy -= dist;
    if (copy) {
      //zmemcpy(state->window, end - copy, copy);
      utils.arraySet(state.window, src, end - copy, copy, 0);
      state.wnext = copy;
      state.whave = state.wsize;
    }
    else {
      state.wnext += dist;
      if (state.wnext === state.wsize) { state.wnext = 0; }
      if (state.whave < state.wsize) { state.whave += dist; }
    }
  }
  return 0;
}

function inflate(strm, flush) {
  var state;
  var input, output;          // input/output buffers
  var next;                   /* next input INDEX */
  var put;                    /* next output INDEX */
  var have, left;             /* available input and output */
  var hold;                   /* bit buffer */
  var bits;                   /* bits in bit buffer */
  var _in, _out;              /* save starting available input and output */
  var copy;                   /* number of stored or match bytes to copy */
  var from;                   /* where to copy match bytes from */
  var from_source;
  var here = 0;               /* current decoding table entry */
  var here_bits, here_op, here_val; // paked "here" denormalized (JS specific)
  //var last;                   /* parent table entry */
  var last_bits, last_op, last_val; // paked "last" denormalized (JS specific)
  var len;                    /* length to copy for repeats, bits to drop */
  var ret;                    /* return code */
  var hbuf = new utils.Buf8(4);    /* buffer for gzip header crc calculation */
  var opts;

  var n; // temporary var for NEED_BITS

  var order = /* permutation of code lengths */
    [ 16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15 ];


  if (!strm || !strm.state || !strm.output ||
      (!strm.input && strm.avail_in !== 0)) {
    return Z_STREAM_ERROR;
  }

  state = strm.state;
  if (state.mode === TYPE) { state.mode = TYPEDO; }    /* skip check */


  //--- LOAD() ---
  put = strm.next_out;
  output = strm.output;
  left = strm.avail_out;
  next = strm.next_in;
  input = strm.input;
  have = strm.avail_in;
  hold = state.hold;
  bits = state.bits;
  //---

  _in = have;
  _out = left;
  ret = Z_OK;

  inf_leave: // goto emulation
  for (;;) {
    switch (state.mode) {
      case HEAD:
        if (state.wrap === 0) {
          state.mode = TYPEDO;
          break;
        }
        //=== NEEDBITS(16);
        while (bits < 16) {
          if (have === 0) { break inf_leave; }
          have--;
          hold += input[next++] << bits;
          bits += 8;
        }
        //===//
        if ((state.wrap & 2) && hold === 0x8b1f) {  /* gzip header */
          state.check = 0/*crc32(0L, Z_NULL, 0)*/;
          //=== CRC2(state.check, hold);
          hbuf[0] = hold & 0xff;
          hbuf[1] = (hold >>> 8) & 0xff;
          state.check = crc32(state.check, hbuf, 2, 0);
          //===//

          //=== INITBITS();
          hold = 0;
          bits = 0;
          //===//
          state.mode = FLAGS;
          break;
        }
        state.flags = 0;           /* expect zlib header */
        if (state.head) {
          state.head.done = false;
        }
        if (!(state.wrap & 1) ||   /* check if zlib header allowed */
          (((hold & 0xff)/*BITS(8)*/ << 8) + (hold >> 8)) % 31) {
          strm.msg = 'incorrect header check';
          state.mode = BAD;
          break;
        }
        if ((hold & 0x0f)/*BITS(4)*/ !== Z_DEFLATED) {
          strm.msg = 'unknown compression method';
          state.mode = BAD;
          break;
        }
        //--- DROPBITS(4) ---//
        hold >>>= 4;
        bits -= 4;
        //---//
        len = (hold & 0x0f)/*BITS(4)*/ + 8;
        if (state.wbits === 0) {
          state.wbits = len;
        }
        else if (len > state.wbits) {
          strm.msg = 'invalid window size';
          state.mode = BAD;
          break;
        }
        state.dmax = 1 << len;
        //Tracev((stderr, "inflate:   zlib header ok\n"));
        strm.adler = state.check = 1/*adler32(0L, Z_NULL, 0)*/;
        state.mode = hold & 0x200 ? DICTID : TYPE;
        //=== INITBITS();
        hold = 0;
        bits = 0;
        //===//
        break;
      case FLAGS:
        //=== NEEDBITS(16); */
        while (bits < 16) {
          if (have === 0) { break inf_leave; }
          have--;
          hold += input[next++] << bits;
          bits += 8;
        }
        //===//
        state.flags = hold;
        if ((state.flags & 0xff) !== Z_DEFLATED) {
          strm.msg = 'unknown compression method';
          state.mode = BAD;
          break;
        }
        if (state.flags & 0xe000) {
          strm.msg = 'unknown header flags set';
          state.mode = BAD;
          break;
        }
        if (state.head) {
          state.head.text = ((hold >> 8) & 1);
        }
        if (state.flags & 0x0200) {
          //=== CRC2(state.check, hold);
          hbuf[0] = hold & 0xff;
          hbuf[1] = (hold >>> 8) & 0xff;
          state.check = crc32(state.check, hbuf, 2, 0);
          //===//
        }
        //=== INITBITS();
        hold = 0;
        bits = 0;
        //===//
        state.mode = TIME;
        /* falls through */
      case TIME:
        //=== NEEDBITS(32); */
        while (bits < 32) {
          if (have === 0) { break inf_leave; }
          have--;
          hold += input[next++] << bits;
          bits += 8;
        }
        //===//
        if (state.head) {
          state.head.time = hold;
        }
        if (state.flags & 0x0200) {
          //=== CRC4(state.check, hold)
          hbuf[0] = hold & 0xff;
          hbuf[1] = (hold >>> 8) & 0xff;
          hbuf[2] = (hold >>> 16) & 0xff;
          hbuf[3] = (hold >>> 24) & 0xff;
          state.check = crc32(state.check, hbuf, 4, 0);
          //===
        }
        //=== INITBITS();
        hold = 0;
        bits = 0;
        //===//
        state.mode = OS;
        /* falls through */
      case OS:
        //=== NEEDBITS(16); */
        while (bits < 16) {
          if (have === 0) { break inf_leave; }
          have--;
          hold += input[next++] << bits;
          bits += 8;
        }
        //===//
        if (state.head) {
          state.head.xflags = (hold & 0xff);
          state.head.os = (hold >> 8);
        }
        if (state.flags & 0x0200) {
          //=== CRC2(state.check, hold);
          hbuf[0] = hold & 0xff;
          hbuf[1] = (hold >>> 8) & 0xff;
          state.check = crc32(state.check, hbuf, 2, 0);
          //===//
        }
        //=== INITBITS();
        hold = 0;
        bits = 0;
        //===//
        state.mode = EXLEN;
        /* falls through */
      case EXLEN:
        if (state.flags & 0x0400) {
          //=== NEEDBITS(16); */
          while (bits < 16) {
            if (have === 0) { break inf_leave; }
            have--;
            hold += input[next++] << bits;
            bits += 8;
          }
          //===//
          state.length = hold;
          if (state.head) {
            state.head.extra_len = hold;
          }
          if (state.flags & 0x0200) {
            //=== CRC2(state.check, hold);
            hbuf[0] = hold & 0xff;
            hbuf[1] = (hold >>> 8) & 0xff;
            state.check = crc32(state.check, hbuf, 2, 0);
            //===//
          }
          //=== INITBITS();
          hold = 0;
          bits = 0;
          //===//
        }
        else if (state.head) {
          state.head.extra = null/*Z_NULL*/;
        }
        state.mode = EXTRA;
        /* falls through */
      case EXTRA:
        if (state.flags & 0x0400) {
          copy = state.length;
          if (copy > have) { copy = have; }
          if (copy) {
            if (state.head) {
              len = state.head.extra_len - state.length;
              if (!state.head.extra) {
                // Use untyped array for more convenient processing later
                state.head.extra = new Array(state.head.extra_len);
              }
              utils.arraySet(
                state.head.extra,
                input,
                next,
                // extra field is limited to 65536 bytes
                // - no need for additional size check
                copy,
                /*len + copy > state.head.extra_max - len ? state.head.extra_max : copy,*/
                len
              );
              //zmemcpy(state.head.extra + len, next,
              //        len + copy > state.head.extra_max ?
              //        state.head.extra_max - len : copy);
            }
            if (state.flags & 0x0200) {
              state.check = crc32(state.check, input, copy, next);
            }
            have -= copy;
            next += copy;
            state.length -= copy;
          }
          if (state.length) { break inf_leave; }
        }
        state.length = 0;
        state.mode = NAME;
        /* falls through */
      case NAME:
        if (state.flags & 0x0800) {
          if (have === 0) { break inf_leave; }
          copy = 0;
          do {
            // TODO: 2 or 1 bytes?
            len = input[next + copy++];
            /* use constant limit because in js we should not preallocate memory */
            if (state.head && len &&
                (state.length < 65536 /*state.head.name_max*/)) {
              state.head.name += String.fromCharCode(len);
            }
          } while (len && copy < have);

          if (state.flags & 0x0200) {
            state.check = crc32(state.check, input, copy, next);
          }
          have -= copy;
          next += copy;
          if (len) { break inf_leave; }
        }
        else if (state.head) {
          state.head.name = null;
        }
        state.length = 0;
        state.mode = COMMENT;
        /* falls through */
      case COMMENT:
        if (state.flags & 0x1000) {
          if (have === 0) { break inf_leave; }
          copy = 0;
          do {
            len = input[next + copy++];
            /* use constant limit because in js we should not preallocate memory */
            if (state.head && len &&
                (state.length < 65536 /*state.head.comm_max*/)) {
              state.head.comment += String.fromCharCode(len);
            }
          } while (len && copy < have);
          if (state.flags & 0x0200) {
            state.check = crc32(state.check, input, copy, next);
          }
          have -= copy;
          next += copy;
          if (len) { break inf_leave; }
        }
        else if (state.head) {
          state.head.comment = null;
        }
        state.mode = HCRC;
        /* falls through */
      case HCRC:
        if (state.flags & 0x0200) {
          //=== NEEDBITS(16); */
          while (bits < 16) {
            if (have === 0) { break inf_leave; }
            have--;
            hold += input[next++] << bits;
            bits += 8;
          }
          //===//
          if (hold !== (state.check & 0xffff)) {
            strm.msg = 'header crc mismatch';
            state.mode = BAD;
            break;
          }
          //=== INITBITS();
          hold = 0;
          bits = 0;
          //===//
        }
        if (state.head) {
          state.head.hcrc = ((state.flags >> 9) & 1);
          state.head.done = true;
        }
        strm.adler = state.check = 0;
        state.mode = TYPE;
        break;
      case DICTID:
        //=== NEEDBITS(32); */
        while (bits < 32) {
          if (have === 0) { break inf_leave; }
          have--;
          hold += input[next++] << bits;
          bits += 8;
        }
        //===//
        strm.adler = state.check = zswap32(hold);
        //=== INITBITS();
        hold = 0;
        bits = 0;
        //===//
        state.mode = DICT;
        /* falls through */
      case DICT:
        if (state.havedict === 0) {
          //--- RESTORE() ---
          strm.next_out = put;
          strm.avail_out = left;
          strm.next_in = next;
          strm.avail_in = have;
          state.hold = hold;
          state.bits = bits;
          //---
          return Z_NEED_DICT;
        }
        strm.adler = state.check = 1/*adler32(0L, Z_NULL, 0)*/;
        state.mode = TYPE;
        /* falls through */
      case TYPE:
        if (flush === Z_BLOCK || flush === Z_TREES) { break inf_leave; }
        /* falls through */
      case TYPEDO:
        if (state.last) {
          //--- BYTEBITS() ---//
          hold >>>= bits & 7;
          bits -= bits & 7;
          //---//
          state.mode = CHECK;
          break;
        }
        //=== NEEDBITS(3); */
        while (bits < 3) {
          if (have === 0) { break inf_leave; }
          have--;
          hold += input[next++] << bits;
          bits += 8;
        }
        //===//
        state.last = (hold & 0x01)/*BITS(1)*/;
        //--- DROPBITS(1) ---//
        hold >>>= 1;
        bits -= 1;
        //---//

        switch ((hold & 0x03)/*BITS(2)*/) {
          case 0:                             /* stored block */
            //Tracev((stderr, "inflate:     stored block%s\n",
            //        state.last ? " (last)" : ""));
            state.mode = STORED;
            break;
          case 1:                             /* fixed block */
            fixedtables(state);
            //Tracev((stderr, "inflate:     fixed codes block%s\n",
            //        state.last ? " (last)" : ""));
            state.mode = LEN_;             /* decode codes */
            if (flush === Z_TREES) {
              //--- DROPBITS(2) ---//
              hold >>>= 2;
              bits -= 2;
              //---//
              break inf_leave;
            }
            break;
          case 2:                             /* dynamic block */
            //Tracev((stderr, "inflate:     dynamic codes block%s\n",
            //        state.last ? " (last)" : ""));
            state.mode = TABLE;
            break;
          case 3:
            strm.msg = 'invalid block type';
            state.mode = BAD;
        }
        //--- DROPBITS(2) ---//
        hold >>>= 2;
        bits -= 2;
        //---//
        break;
      case STORED:
        //--- BYTEBITS() ---// /* go to byte boundary */
        hold >>>= bits & 7;
        bits -= bits & 7;
        //---//
        //=== NEEDBITS(32); */
        while (bits < 32) {
          if (have === 0) { break inf_leave; }
          have--;
          hold += input[next++] << bits;
          bits += 8;
        }
        //===//
        if ((hold & 0xffff) !== ((hold >>> 16) ^ 0xffff)) {
          strm.msg = 'invalid stored block lengths';
          state.mode = BAD;
          break;
        }
        state.length = hold & 0xffff;
        //Tracev((stderr, "inflate:       stored length %u\n",
        //        state.length));
        //=== INITBITS();
        hold = 0;
        bits = 0;
        //===//
        state.mode = COPY_;
        if (flush === Z_TREES) { break inf_leave; }
        /* falls through */
      case COPY_:
        state.mode = COPY;
        /* falls through */
      case COPY:
        copy = state.length;
        if (copy) {
          if (copy > have) { copy = have; }
          if (copy > left) { copy = left; }
          if (copy === 0) { break inf_leave; }
          //--- zmemcpy(put, next, copy); ---
          utils.arraySet(output, input, next, copy, put);
          //---//
          have -= copy;
          next += copy;
          left -= copy;
          put += copy;
          state.length -= copy;
          break;
        }
        //Tracev((stderr, "inflate:       stored end\n"));
        state.mode = TYPE;
        break;
      case TABLE:
        //=== NEEDBITS(14); */
        while (bits < 14) {
          if (have === 0) { break inf_leave; }
          have--;
          hold += input[next++] << bits;
          bits += 8;
        }
        //===//
        state.nlen = (hold & 0x1f)/*BITS(5)*/ + 257;
        //--- DROPBITS(5) ---//
        hold >>>= 5;
        bits -= 5;
        //---//
        state.ndist = (hold & 0x1f)/*BITS(5)*/ + 1;
        //--- DROPBITS(5) ---//
        hold >>>= 5;
        bits -= 5;
        //---//
        state.ncode = (hold & 0x0f)/*BITS(4)*/ + 4;
        //--- DROPBITS(4) ---//
        hold >>>= 4;
        bits -= 4;
        //---//
//#ifndef PKZIP_BUG_WORKAROUND
        if (state.nlen > 286 || state.ndist > 30) {
          strm.msg = 'too many length or distance symbols';
          state.mode = BAD;
          break;
        }
//#endif
        //Tracev((stderr, "inflate:       table sizes ok\n"));
        state.have = 0;
        state.mode = LENLENS;
        /* falls through */
      case LENLENS:
        while (state.have < state.ncode) {
          //=== NEEDBITS(3);
          while (bits < 3) {
            if (have === 0) { break inf_leave; }
            have--;
            hold += input[next++] << bits;
            bits += 8;
          }
          //===//
          state.lens[order[state.have++]] = (hold & 0x07);//BITS(3);
          //--- DROPBITS(3) ---//
          hold >>>= 3;
          bits -= 3;
          //---//
        }
        while (state.have < 19) {
          state.lens[order[state.have++]] = 0;
        }
        // We have separate tables & no pointers. 2 commented lines below not needed.
        //state.next = state.codes;
        //state.lencode = state.next;
        // Switch to use dynamic table
        state.lencode = state.lendyn;
        state.lenbits = 7;

        opts = { bits: state.lenbits };
        ret = inflate_table(CODES, state.lens, 0, 19, state.lencode, 0, state.work, opts);
        state.lenbits = opts.bits;

        if (ret) {
          strm.msg = 'invalid code lengths set';
          state.mode = BAD;
          break;
        }
        //Tracev((stderr, "inflate:       code lengths ok\n"));
        state.have = 0;
        state.mode = CODELENS;
        /* falls through */
      case CODELENS:
        while (state.have < state.nlen + state.ndist) {
          for (;;) {
            here = state.lencode[hold & ((1 << state.lenbits) - 1)];/*BITS(state.lenbits)*/
            here_bits = here >>> 24;
            here_op = (here >>> 16) & 0xff;
            here_val = here & 0xffff;

            if ((here_bits) <= bits) { break; }
            //--- PULLBYTE() ---//
            if (have === 0) { break inf_leave; }
            have--;
            hold += input[next++] << bits;
            bits += 8;
            //---//
          }
          if (here_val < 16) {
            //--- DROPBITS(here.bits) ---//
            hold >>>= here_bits;
            bits -= here_bits;
            //---//
            state.lens[state.have++] = here_val;
          }
          else {
            if (here_val === 16) {
              //=== NEEDBITS(here.bits + 2);
              n = here_bits + 2;
              while (bits < n) {
                if (have === 0) { break inf_leave; }
                have--;
                hold += input[next++] << bits;
                bits += 8;
              }
              //===//
              //--- DROPBITS(here.bits) ---//
              hold >>>= here_bits;
              bits -= here_bits;
              //---//
              if (state.have === 0) {
                strm.msg = 'invalid bit length repeat';
                state.mode = BAD;
                break;
              }
              len = state.lens[state.have - 1];
              copy = 3 + (hold & 0x03);//BITS(2);
              //--- DROPBITS(2) ---//
              hold >>>= 2;
              bits -= 2;
              //---//
            }
            else if (here_val === 17) {
              //=== NEEDBITS(here.bits + 3);
              n = here_bits + 3;
              while (bits < n) {
                if (have === 0) { break inf_leave; }
                have--;
                hold += input[next++] << bits;
                bits += 8;
              }
              //===//
              //--- DROPBITS(here.bits) ---//
              hold >>>= here_bits;
              bits -= here_bits;
              //---//
              len = 0;
              copy = 3 + (hold & 0x07);//BITS(3);
              //--- DROPBITS(3) ---//
              hold >>>= 3;
              bits -= 3;
              //---//
            }
            else {
              //=== NEEDBITS(here.bits + 7);
              n = here_bits + 7;
              while (bits < n) {
                if (have === 0) { break inf_leave; }
                have--;
                hold += input[next++] << bits;
                bits += 8;
              }
              //===//
              //--- DROPBITS(here.bits) ---//
              hold >>>= here_bits;
              bits -= here_bits;
              //---//
              len = 0;
              copy = 11 + (hold & 0x7f);//BITS(7);
              //--- DROPBITS(7) ---//
              hold >>>= 7;
              bits -= 7;
              //---//
            }
            if (state.have + copy > state.nlen + state.ndist) {
              strm.msg = 'invalid bit length repeat';
              state.mode = BAD;
              break;
            }
            while (copy--) {
              state.lens[state.have++] = len;
            }
          }
        }

        /* handle error breaks in while */
        if (state.mode === BAD) { break; }

        /* check for end-of-block code (better have one) */
        if (state.lens[256] === 0) {
          strm.msg = 'invalid code -- missing end-of-block';
          state.mode = BAD;
          break;
        }

        /* build code tables -- note: do not change the lenbits or distbits
           values here (9 and 6) without reading the comments in inftrees.h
           concerning the ENOUGH constants, which depend on those values */
        state.lenbits = 9;

        opts = { bits: state.lenbits };
        ret = inflate_table(LENS, state.lens, 0, state.nlen, state.lencode, 0, state.work, opts);
        // We have separate tables & no pointers. 2 commented lines below not needed.
        // state.next_index = opts.table_index;
        state.lenbits = opts.bits;
        // state.lencode = state.next;

        if (ret) {
          strm.msg = 'invalid literal/lengths set';
          state.mode = BAD;
          break;
        }

        state.distbits = 6;
        //state.distcode.copy(state.codes);
        // Switch to use dynamic table
        state.distcode = state.distdyn;
        opts = { bits: state.distbits };
        ret = inflate_table(DISTS, state.lens, state.nlen, state.ndist, state.distcode, 0, state.work, opts);
        // We have separate tables & no pointers. 2 commented lines below not needed.
        // state.next_index = opts.table_index;
        state.distbits = opts.bits;
        // state.distcode = state.next;

        if (ret) {
          strm.msg = 'invalid distances set';
          state.mode = BAD;
          break;
        }
        //Tracev((stderr, 'inflate:       codes ok\n'));
        state.mode = LEN_;
        if (flush === Z_TREES) { break inf_leave; }
        /* falls through */
      case LEN_:
        state.mode = LEN;
        /* falls through */
      case LEN:
        if (have >= 6 && left >= 258) {
          //--- RESTORE() ---
          strm.next_out = put;
          strm.avail_out = left;
          strm.next_in = next;
          strm.avail_in = have;
          state.hold = hold;
          state.bits = bits;
          //---
          inflate_fast(strm, _out);
          //--- LOAD() ---
          put = strm.next_out;
          output = strm.output;
          left = strm.avail_out;
          next = strm.next_in;
          input = strm.input;
          have = strm.avail_in;
          hold = state.hold;
          bits = state.bits;
          //---

          if (state.mode === TYPE) {
            state.back = -1;
          }
          break;
        }
        state.back = 0;
        for (;;) {
          here = state.lencode[hold & ((1 << state.lenbits) - 1)];  /*BITS(state.lenbits)*/
          here_bits = here >>> 24;
          here_op = (here >>> 16) & 0xff;
          here_val = here & 0xffff;

          if (here_bits <= bits) { break; }
          //--- PULLBYTE() ---//
          if (have === 0) { break inf_leave; }
          have--;
          hold += input[next++] << bits;
          bits += 8;
          //---//
        }
        if (here_op && (here_op & 0xf0) === 0) {
          last_bits = here_bits;
          last_op = here_op;
          last_val = here_val;
          for (;;) {
            here = state.lencode[last_val +
                    ((hold & ((1 << (last_bits + last_op)) - 1))/*BITS(last.bits + last.op)*/ >> last_bits)];
            here_bits = here >>> 24;
            here_op = (here >>> 16) & 0xff;
            here_val = here & 0xffff;

            if ((last_bits + here_bits) <= bits) { break; }
            //--- PULLBYTE() ---//
            if (have === 0) { break inf_leave; }
            have--;
            hold += input[next++] << bits;
            bits += 8;
            //---//
          }
          //--- DROPBITS(last.bits) ---//
          hold >>>= last_bits;
          bits -= last_bits;
          //---//
          state.back += last_bits;
        }
        //--- DROPBITS(here.bits) ---//
        hold >>>= here_bits;
        bits -= here_bits;
        //---//
        state.back += here_bits;
        state.length = here_val;
        if (here_op === 0) {
          //Tracevv((stderr, here.val >= 0x20 && here.val < 0x7f ?
          //        "inflate:         literal '%c'\n" :
          //        "inflate:         literal 0x%02x\n", here.val));
          state.mode = LIT;
          break;
        }
        if (here_op & 32) {
          //Tracevv((stderr, "inflate:         end of block\n"));
          state.back = -1;
          state.mode = TYPE;
          break;
        }
        if (here_op & 64) {
          strm.msg = 'invalid literal/length code';
          state.mode = BAD;
          break;
        }
        state.extra = here_op & 15;
        state.mode = LENEXT;
        /* falls through */
      case LENEXT:
        if (state.extra) {
          //=== NEEDBITS(state.extra);
          n = state.extra;
          while (bits < n) {
            if (have === 0) { break inf_leave; }
            have--;
            hold += input[next++] << bits;
            bits += 8;
          }
          //===//
          state.length += hold & ((1 << state.extra) - 1)/*BITS(state.extra)*/;
          //--- DROPBITS(state.extra) ---//
          hold >>>= state.extra;
          bits -= state.extra;
          //---//
          state.back += state.extra;
        }
        //Tracevv((stderr, "inflate:         length %u\n", state.length));
        state.was = state.length;
        state.mode = DIST;
        /* falls through */
      case DIST:
        for (;;) {
          here = state.distcode[hold & ((1 << state.distbits) - 1)];/*BITS(state.distbits)*/
          here_bits = here >>> 24;
          here_op = (here >>> 16) & 0xff;
          here_val = here & 0xffff;

          if ((here_bits) <= bits) { break; }
          //--- PULLBYTE() ---//
          if (have === 0) { break inf_leave; }
          have--;
          hold += input[next++] << bits;
          bits += 8;
          //---//
        }
        if ((here_op & 0xf0) === 0) {
          last_bits = here_bits;
          last_op = here_op;
          last_val = here_val;
          for (;;) {
            here = state.distcode[last_val +
                    ((hold & ((1 << (last_bits + last_op)) - 1))/*BITS(last.bits + last.op)*/ >> last_bits)];
            here_bits = here >>> 24;
            here_op = (here >>> 16) & 0xff;
            here_val = here & 0xffff;

            if ((last_bits + here_bits) <= bits) { break; }
            //--- PULLBYTE() ---//
            if (have === 0) { break inf_leave; }
            have--;
            hold += input[next++] << bits;
            bits += 8;
            //---//
          }
          //--- DROPBITS(last.bits) ---//
          hold >>>= last_bits;
          bits -= last_bits;
          //---//
          state.back += last_bits;
        }
        //--- DROPBITS(here.bits) ---//
        hold >>>= here_bits;
        bits -= here_bits;
        //---//
        state.back += here_bits;
        if (here_op & 64) {
          strm.msg = 'invalid distance code';
          state.mode = BAD;
          break;
        }
        state.offset = here_val;
        state.extra = (here_op) & 15;
        state.mode = DISTEXT;
        /* falls through */
      case DISTEXT:
        if (state.extra) {
          //=== NEEDBITS(state.extra);
          n = state.extra;
          while (bits < n) {
            if (have === 0) { break inf_leave; }
            have--;
            hold += input[next++] << bits;
            bits += 8;
          }
          //===//
          state.offset += hold & ((1 << state.extra) - 1)/*BITS(state.extra)*/;
          //--- DROPBITS(state.extra) ---//
          hold >>>= state.extra;
          bits -= state.extra;
          //---//
          state.back += state.extra;
        }
//#ifdef INFLATE_STRICT
        if (state.offset > state.dmax) {
          strm.msg = 'invalid distance too far back';
          state.mode = BAD;
          break;
        }
//#endif
        //Tracevv((stderr, "inflate:         distance %u\n", state.offset));
        state.mode = MATCH;
        /* falls through */
      case MATCH:
        if (left === 0) { break inf_leave; }
        copy = _out - left;
        if (state.offset > copy) {         /* copy from window */
          copy = state.offset - copy;
          if (copy > state.whave) {
            if (state.sane) {
              strm.msg = 'invalid distance too far back';
              state.mode = BAD;
              break;
            }
// (!) This block is disabled in zlib defaults,
// don't enable it for binary compatibility
//#ifdef INFLATE_ALLOW_INVALID_DISTANCE_TOOFAR_ARRR
//          Trace((stderr, "inflate.c too far\n"));
//          copy -= state.whave;
//          if (copy > state.length) { copy = state.length; }
//          if (copy > left) { copy = left; }
//          left -= copy;
//          state.length -= copy;
//          do {
//            output[put++] = 0;
//          } while (--copy);
//          if (state.length === 0) { state.mode = LEN; }
//          break;
//#endif
          }
          if (copy > state.wnext) {
            copy -= state.wnext;
            from = state.wsize - copy;
          }
          else {
            from = state.wnext - copy;
          }
          if (copy > state.length) { copy = state.length; }
          from_source = state.window;
        }
        else {                              /* copy from output */
          from_source = output;
          from = put - state.offset;
          copy = state.length;
        }
        if (copy > left) { copy = left; }
        left -= copy;
        state.length -= copy;
        do {
          output[put++] = from_source[from++];
        } while (--copy);
        if (state.length === 0) { state.mode = LEN; }
        break;
      case LIT:
        if (left === 0) { break inf_leave; }
        output[put++] = state.length;
        left--;
        state.mode = LEN;
        break;
      case CHECK:
        if (state.wrap) {
          //=== NEEDBITS(32);
          while (bits < 32) {
            if (have === 0) { break inf_leave; }
            have--;
            // Use '|' instead of '+' to make sure that result is signed
            hold |= input[next++] << bits;
            bits += 8;
          }
          //===//
          _out -= left;
          strm.total_out += _out;
          state.total += _out;
          if (_out) {
            strm.adler = state.check =
                /*UPDATE(state.check, put - _out, _out);*/
                (state.flags ? crc32(state.check, output, _out, put - _out) : adler32(state.check, output, _out, put - _out));

          }
          _out = left;
          // NB: crc32 stored as signed 32-bit int, zswap32 returns signed too
          if ((state.flags ? hold : zswap32(hold)) !== state.check) {
            strm.msg = 'incorrect data check';
            state.mode = BAD;
            break;
          }
          //=== INITBITS();
          hold = 0;
          bits = 0;
          //===//
          //Tracev((stderr, "inflate:   check matches trailer\n"));
        }
        state.mode = LENGTH;
        /* falls through */
      case LENGTH:
        if (state.wrap && state.flags) {
          //=== NEEDBITS(32);
          while (bits < 32) {
            if (have === 0) { break inf_leave; }
            have--;
            hold += input[next++] << bits;
            bits += 8;
          }
          //===//
          if (hold !== (state.total & 0xffffffff)) {
            strm.msg = 'incorrect length check';
            state.mode = BAD;
            break;
          }
          //=== INITBITS();
          hold = 0;
          bits = 0;
          //===//
          //Tracev((stderr, "inflate:   length matches trailer\n"));
        }
        state.mode = DONE;
        /* falls through */
      case DONE:
        ret = Z_STREAM_END;
        break inf_leave;
      case BAD:
        ret = Z_DATA_ERROR;
        break inf_leave;
      case MEM:
        return Z_MEM_ERROR;
      case SYNC:
        /* falls through */
      default:
        return Z_STREAM_ERROR;
    }
  }

  // inf_leave <- here is real place for "goto inf_leave", emulated via "break inf_leave"

  /*
     Return from inflate(), updating the total counts and the check value.
     If there was no progress during the inflate() call, return a buffer
     error.  Call updatewindow() to create and/or update the window state.
     Note: a memory error from inflate() is non-recoverable.
   */

  //--- RESTORE() ---
  strm.next_out = put;
  strm.avail_out = left;
  strm.next_in = next;
  strm.avail_in = have;
  state.hold = hold;
  state.bits = bits;
  //---

  if (state.wsize || (_out !== strm.avail_out && state.mode < BAD &&
                      (state.mode < CHECK || flush !== Z_FINISH))) {
    if (updatewindow(strm, strm.output, strm.next_out, _out - strm.avail_out)) {
      state.mode = MEM;
      return Z_MEM_ERROR;
    }
  }
  _in -= strm.avail_in;
  _out -= strm.avail_out;
  strm.total_in += _in;
  strm.total_out += _out;
  state.total += _out;
  if (state.wrap && _out) {
    strm.adler = state.check = /*UPDATE(state.check, strm.next_out - _out, _out);*/
      (state.flags ? crc32(state.check, output, _out, strm.next_out - _out) : adler32(state.check, output, _out, strm.next_out - _out));
  }
  strm.data_type = state.bits + (state.last ? 64 : 0) +
                    (state.mode === TYPE ? 128 : 0) +
                    (state.mode === LEN_ || state.mode === COPY_ ? 256 : 0);
  if (((_in === 0 && _out === 0) || flush === Z_FINISH) && ret === Z_OK) {
    ret = Z_BUF_ERROR;
  }
  return ret;
}

function inflateEnd(strm) {

  if (!strm || !strm.state /*|| strm->zfree == (free_func)0*/) {
    return Z_STREAM_ERROR;
  }

  var state = strm.state;
  if (state.window) {
    state.window = null;
  }
  strm.state = null;
  return Z_OK;
}

function inflateGetHeader(strm, head) {
  var state;

  /* check state */
  if (!strm || !strm.state) { return Z_STREAM_ERROR; }
  state = strm.state;
  if ((state.wrap & 2) === 0) { return Z_STREAM_ERROR; }

  /* save header structure */
  state.head = head;
  head.done = false;
  return Z_OK;
}

function inflateSetDictionary(strm, dictionary) {
  var dictLength = dictionary.length;

  var state;
  var dictid;
  var ret;

  /* check state */
  if (!strm /* == Z_NULL */ || !strm.state /* == Z_NULL */) { return Z_STREAM_ERROR; }
  state = strm.state;

  if (state.wrap !== 0 && state.mode !== DICT) {
    return Z_STREAM_ERROR;
  }

  /* check for correct dictionary identifier */
  if (state.mode === DICT) {
    dictid = 1; /* adler32(0, null, 0)*/
    /* dictid = adler32(dictid, dictionary, dictLength); */
    dictid = adler32(dictid, dictionary, dictLength, 0);
    if (dictid !== state.check) {
      return Z_DATA_ERROR;
    }
  }
  /* copy dictionary to window using updatewindow(), which will amend the
   existing dictionary if appropriate */
  ret = updatewindow(strm, dictionary, dictLength, dictLength);
  if (ret) {
    state.mode = MEM;
    return Z_MEM_ERROR;
  }
  state.havedict = 1;
  // Tracev((stderr, "inflate:   dictionary set\n"));
  return Z_OK;
}

exports.inflateReset = inflateReset;
exports.inflateReset2 = inflateReset2;
exports.inflateResetKeep = inflateResetKeep;
exports.inflateInit = inflateInit;
exports.inflateInit2 = inflateInit2;
exports.inflate = inflate;
exports.inflateEnd = inflateEnd;
exports.inflateGetHeader = inflateGetHeader;
exports.inflateSetDictionary = inflateSetDictionary;
exports.inflateInfo = 'pako inflate (from Nodeca project)';

/* Not implemented
exports.inflateCopy = inflateCopy;
exports.inflateGetDictionary = inflateGetDictionary;
exports.inflateMark = inflateMark;
exports.inflatePrime = inflatePrime;
exports.inflateSync = inflateSync;
exports.inflateSyncPoint = inflateSyncPoint;
exports.inflateUndermine = inflateUndermine;
*/


/***/ }),

/***/ 2891:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


// (C) 1995-2013 Jean-loup Gailly and Mark Adler
// (C) 2014-2017 Vitaly Puzrin and Andrey Tupitsin
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//   claim that you wrote the original software. If you use this software
//   in a product, an acknowledgment in the product documentation would be
//   appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//   misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.

// See state defs from inflate.js
var BAD = 30;       /* got a data error -- remain here until reset */
var TYPE = 12;      /* i: waiting for type bits, including last-flag bit */

/*
   Decode literal, length, and distance codes and write out the resulting
   literal and match bytes until either not enough input or output is
   available, an end-of-block is encountered, or a data error is encountered.
   When large enough input and output buffers are supplied to inflate(), for
   example, a 16K input buffer and a 64K output buffer, more than 95% of the
   inflate execution time is spent in this routine.

   Entry assumptions:

        state.mode === LEN
        strm.avail_in >= 6
        strm.avail_out >= 258
        start >= strm.avail_out
        state.bits < 8

   On return, state.mode is one of:

        LEN -- ran out of enough output space or enough available input
        TYPE -- reached end of block code, inflate() to interpret next block
        BAD -- error in block data

   Notes:

    - The maximum input bits used by a length/distance pair is 15 bits for the
      length code, 5 bits for the length extra, 15 bits for the distance code,
      and 13 bits for the distance extra.  This totals 48 bits, or six bytes.
      Therefore if strm.avail_in >= 6, then there is enough input to avoid
      checking for available input while decoding.

    - The maximum bytes that a single length/distance pair can output is 258
      bytes, which is the maximum length that can be coded.  inflate_fast()
      requires strm.avail_out >= 258 for each loop to avoid checking for
      output space.
 */
module.exports = function inflate_fast(strm, start) {
  var state;
  var _in;                    /* local strm.input */
  var last;                   /* have enough input while in < last */
  var _out;                   /* local strm.output */
  var beg;                    /* inflate()'s initial strm.output */
  var end;                    /* while out < end, enough space available */
//#ifdef INFLATE_STRICT
  var dmax;                   /* maximum distance from zlib header */
//#endif
  var wsize;                  /* window size or zero if not using window */
  var whave;                  /* valid bytes in the window */
  var wnext;                  /* window write index */
  // Use `s_window` instead `window`, avoid conflict with instrumentation tools
  var s_window;               /* allocated sliding window, if wsize != 0 */
  var hold;                   /* local strm.hold */
  var bits;                   /* local strm.bits */
  var lcode;                  /* local strm.lencode */
  var dcode;                  /* local strm.distcode */
  var lmask;                  /* mask for first level of length codes */
  var dmask;                  /* mask for first level of distance codes */
  var here;                   /* retrieved table entry */
  var op;                     /* code bits, operation, extra bits, or */
                              /*  window position, window bytes to copy */
  var len;                    /* match length, unused bytes */
  var dist;                   /* match distance */
  var from;                   /* where to copy match from */
  var from_source;


  var input, output; // JS specific, because we have no pointers

  /* copy state to local variables */
  state = strm.state;
  //here = state.here;
  _in = strm.next_in;
  input = strm.input;
  last = _in + (strm.avail_in - 5);
  _out = strm.next_out;
  output = strm.output;
  beg = _out - (start - strm.avail_out);
  end = _out + (strm.avail_out - 257);
//#ifdef INFLATE_STRICT
  dmax = state.dmax;
//#endif
  wsize = state.wsize;
  whave = state.whave;
  wnext = state.wnext;
  s_window = state.window;
  hold = state.hold;
  bits = state.bits;
  lcode = state.lencode;
  dcode = state.distcode;
  lmask = (1 << state.lenbits) - 1;
  dmask = (1 << state.distbits) - 1;


  /* decode literals and length/distances until end-of-block or not enough
     input data or output space */

  top:
  do {
    if (bits < 15) {
      hold += input[_in++] << bits;
      bits += 8;
      hold += input[_in++] << bits;
      bits += 8;
    }

    here = lcode[hold & lmask];

    dolen:
    for (;;) { // Goto emulation
      op = here >>> 24/*here.bits*/;
      hold >>>= op;
      bits -= op;
      op = (here >>> 16) & 0xff/*here.op*/;
      if (op === 0) {                          /* literal */
        //Tracevv((stderr, here.val >= 0x20 && here.val < 0x7f ?
        //        "inflate:         literal '%c'\n" :
        //        "inflate:         literal 0x%02x\n", here.val));
        output[_out++] = here & 0xffff/*here.val*/;
      }
      else if (op & 16) {                     /* length base */
        len = here & 0xffff/*here.val*/;
        op &= 15;                           /* number of extra bits */
        if (op) {
          if (bits < op) {
            hold += input[_in++] << bits;
            bits += 8;
          }
          len += hold & ((1 << op) - 1);
          hold >>>= op;
          bits -= op;
        }
        //Tracevv((stderr, "inflate:         length %u\n", len));
        if (bits < 15) {
          hold += input[_in++] << bits;
          bits += 8;
          hold += input[_in++] << bits;
          bits += 8;
        }
        here = dcode[hold & dmask];

        dodist:
        for (;;) { // goto emulation
          op = here >>> 24/*here.bits*/;
          hold >>>= op;
          bits -= op;
          op = (here >>> 16) & 0xff/*here.op*/;

          if (op & 16) {                      /* distance base */
            dist = here & 0xffff/*here.val*/;
            op &= 15;                       /* number of extra bits */
            if (bits < op) {
              hold += input[_in++] << bits;
              bits += 8;
              if (bits < op) {
                hold += input[_in++] << bits;
                bits += 8;
              }
            }
            dist += hold & ((1 << op) - 1);
//#ifdef INFLATE_STRICT
            if (dist > dmax) {
              strm.msg = 'invalid distance too far back';
              state.mode = BAD;
              break top;
            }
//#endif
            hold >>>= op;
            bits -= op;
            //Tracevv((stderr, "inflate:         distance %u\n", dist));
            op = _out - beg;                /* max distance in output */
            if (dist > op) {                /* see if copy from window */
              op = dist - op;               /* distance back in window */
              if (op > whave) {
                if (state.sane) {
                  strm.msg = 'invalid distance too far back';
                  state.mode = BAD;
                  break top;
                }

// (!) This block is disabled in zlib defaults,
// don't enable it for binary compatibility
//#ifdef INFLATE_ALLOW_INVALID_DISTANCE_TOOFAR_ARRR
//                if (len <= op - whave) {
//                  do {
//                    output[_out++] = 0;
//                  } while (--len);
//                  continue top;
//                }
//                len -= op - whave;
//                do {
//                  output[_out++] = 0;
//                } while (--op > whave);
//                if (op === 0) {
//                  from = _out - dist;
//                  do {
//                    output[_out++] = output[from++];
//                  } while (--len);
//                  continue top;
//                }
//#endif
              }
              from = 0; // window index
              from_source = s_window;
              if (wnext === 0) {           /* very common case */
                from += wsize - op;
                if (op < len) {         /* some from window */
                  len -= op;
                  do {
                    output[_out++] = s_window[from++];
                  } while (--op);
                  from = _out - dist;  /* rest from output */
                  from_source = output;
                }
              }
              else if (wnext < op) {      /* wrap around window */
                from += wsize + wnext - op;
                op -= wnext;
                if (op < len) {         /* some from end of window */
                  len -= op;
                  do {
                    output[_out++] = s_window[from++];
                  } while (--op);
                  from = 0;
                  if (wnext < len) {  /* some from start of window */
                    op = wnext;
                    len -= op;
                    do {
                      output[_out++] = s_window[from++];
                    } while (--op);
                    from = _out - dist;      /* rest from output */
                    from_source = output;
                  }
                }
              }
              else {                      /* contiguous in window */
                from += wnext - op;
                if (op < len) {         /* some from window */
                  len -= op;
                  do {
                    output[_out++] = s_window[from++];
                  } while (--op);
                  from = _out - dist;  /* rest from output */
                  from_source = output;
                }
              }
              while (len > 2) {
                output[_out++] = from_source[from++];
                output[_out++] = from_source[from++];
                output[_out++] = from_source[from++];
                len -= 3;
              }
              if (len) {
                output[_out++] = from_source[from++];
                if (len > 1) {
                  output[_out++] = from_source[from++];
                }
              }
            }
            else {
              from = _out - dist;          /* copy direct from output */
              do {                        /* minimum length is three */
                output[_out++] = output[from++];
                output[_out++] = output[from++];
                output[_out++] = output[from++];
                len -= 3;
              } while (len > 2);
              if (len) {
                output[_out++] = output[from++];
                if (len > 1) {
                  output[_out++] = output[from++];
                }
              }
            }
          }
          else if ((op & 64) === 0) {          /* 2nd level distance code */
            here = dcode[(here & 0xffff)/*here.val*/ + (hold & ((1 << op) - 1))];
            continue dodist;
          }
          else {
            strm.msg = 'invalid distance code';
            state.mode = BAD;
            break top;
          }

          break; // need to emulate goto via "continue"
        }
      }
      else if ((op & 64) === 0) {              /* 2nd level length code */
        here = lcode[(here & 0xffff)/*here.val*/ + (hold & ((1 << op) - 1))];
        continue dolen;
      }
      else if (op & 32) {                     /* end-of-block */
        //Tracevv((stderr, "inflate:         end of block\n"));
        state.mode = TYPE;
        break top;
      }
      else {
        strm.msg = 'invalid literal/length code';
        state.mode = BAD;
        break top;
      }

      break; // need to emulate goto via "continue"
    }
  } while (_in < last && _out < end);

  /* return unused bytes (on entry, bits < 8, so in won't go too far back) */
  len = bits >> 3;
  _in -= len;
  bits -= len << 3;
  hold &= (1 << bits) - 1;

  /* update state and return */
  strm.next_in = _in;
  strm.next_out = _out;
  strm.avail_in = (_in < last ? 5 + (last - _in) : 5 - (_in - last));
  strm.avail_out = (_out < end ? 257 + (end - _out) : 257 - (_out - end));
  state.hold = hold;
  state.bits = bits;
  return;
};


/***/ }),

/***/ 2892:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


// (C) 1995-2013 Jean-loup Gailly and Mark Adler
// (C) 2014-2017 Vitaly Puzrin and Andrey Tupitsin
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//   claim that you wrote the original software. If you use this software
//   in a product, an acknowledgment in the product documentation would be
//   appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//   misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.

var utils = __webpack_require__(1624);

var MAXBITS = 15;
var ENOUGH_LENS = 852;
var ENOUGH_DISTS = 592;
//var ENOUGH = (ENOUGH_LENS+ENOUGH_DISTS);

var CODES = 0;
var LENS = 1;
var DISTS = 2;

var lbase = [ /* Length codes 257..285 base */
  3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31,
  35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258, 0, 0
];

var lext = [ /* Length codes 257..285 extra */
  16, 16, 16, 16, 16, 16, 16, 16, 17, 17, 17, 17, 18, 18, 18, 18,
  19, 19, 19, 19, 20, 20, 20, 20, 21, 21, 21, 21, 16, 72, 78
];

var dbase = [ /* Distance codes 0..29 base */
  1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193,
  257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145,
  8193, 12289, 16385, 24577, 0, 0
];

var dext = [ /* Distance codes 0..29 extra */
  16, 16, 16, 16, 17, 17, 18, 18, 19, 19, 20, 20, 21, 21, 22, 22,
  23, 23, 24, 24, 25, 25, 26, 26, 27, 27,
  28, 28, 29, 29, 64, 64
];

module.exports = function inflate_table(type, lens, lens_index, codes, table, table_index, work, opts)
{
  var bits = opts.bits;
      //here = opts.here; /* table entry for duplication */

  var len = 0;               /* a code's length in bits */
  var sym = 0;               /* index of code symbols */
  var min = 0, max = 0;          /* minimum and maximum code lengths */
  var root = 0;              /* number of index bits for root table */
  var curr = 0;              /* number of index bits for current table */
  var drop = 0;              /* code bits to drop for sub-table */
  var left = 0;                   /* number of prefix codes available */
  var used = 0;              /* code entries in table used */
  var huff = 0;              /* Huffman code */
  var incr;              /* for incrementing code, index */
  var fill;              /* index for replicating entries */
  var low;               /* low bits for current root entry */
  var mask;              /* mask for low root bits */
  var next;             /* next available space in table */
  var base = null;     /* base value table to use */
  var base_index = 0;
//  var shoextra;    /* extra bits table to use */
  var end;                    /* use base and extra for symbol > end */
  var count = new utils.Buf16(MAXBITS + 1); //[MAXBITS+1];    /* number of codes of each length */
  var offs = new utils.Buf16(MAXBITS + 1); //[MAXBITS+1];     /* offsets in table for each length */
  var extra = null;
  var extra_index = 0;

  var here_bits, here_op, here_val;

  /*
   Process a set of code lengths to create a canonical Huffman code.  The
   code lengths are lens[0..codes-1].  Each length corresponds to the
   symbols 0..codes-1.  The Huffman code is generated by first sorting the
   symbols by length from short to long, and retaining the symbol order
   for codes with equal lengths.  Then the code starts with all zero bits
   for the first code of the shortest length, and the codes are integer
   increments for the same length, and zeros are appended as the length
   increases.  For the deflate format, these bits are stored backwards
   from their more natural integer increment ordering, and so when the
   decoding tables are built in the large loop below, the integer codes
   are incremented backwards.

   This routine assumes, but does not check, that all of the entries in
   lens[] are in the range 0..MAXBITS.  The caller must assure this.
   1..MAXBITS is interpreted as that code length.  zero means that that
   symbol does not occur in this code.

   The codes are sorted by computing a count of codes for each length,
   creating from that a table of starting indices for each length in the
   sorted table, and then entering the symbols in order in the sorted
   table.  The sorted table is work[], with that space being provided by
   the caller.

   The length counts are used for other purposes as well, i.e. finding
   the minimum and maximum length codes, determining if there are any
   codes at all, checking for a valid set of lengths, and looking ahead
   at length counts to determine sub-table sizes when building the
   decoding tables.
   */

  /* accumulate lengths for codes (assumes lens[] all in 0..MAXBITS) */
  for (len = 0; len <= MAXBITS; len++) {
    count[len] = 0;
  }
  for (sym = 0; sym < codes; sym++) {
    count[lens[lens_index + sym]]++;
  }

  /* bound code lengths, force root to be within code lengths */
  root = bits;
  for (max = MAXBITS; max >= 1; max--) {
    if (count[max] !== 0) { break; }
  }
  if (root > max) {
    root = max;
  }
  if (max === 0) {                     /* no symbols to code at all */
    //table.op[opts.table_index] = 64;  //here.op = (var char)64;    /* invalid code marker */
    //table.bits[opts.table_index] = 1;   //here.bits = (var char)1;
    //table.val[opts.table_index++] = 0;   //here.val = (var short)0;
    table[table_index++] = (1 << 24) | (64 << 16) | 0;


    //table.op[opts.table_index] = 64;
    //table.bits[opts.table_index] = 1;
    //table.val[opts.table_index++] = 0;
    table[table_index++] = (1 << 24) | (64 << 16) | 0;

    opts.bits = 1;
    return 0;     /* no symbols, but wait for decoding to report error */
  }
  for (min = 1; min < max; min++) {
    if (count[min] !== 0) { break; }
  }
  if (root < min) {
    root = min;
  }

  /* check for an over-subscribed or incomplete set of lengths */
  left = 1;
  for (len = 1; len <= MAXBITS; len++) {
    left <<= 1;
    left -= count[len];
    if (left < 0) {
      return -1;
    }        /* over-subscribed */
  }
  if (left > 0 && (type === CODES || max !== 1)) {
    return -1;                      /* incomplete set */
  }

  /* generate offsets into symbol table for each length for sorting */
  offs[1] = 0;
  for (len = 1; len < MAXBITS; len++) {
    offs[len + 1] = offs[len] + count[len];
  }

  /* sort symbols by length, by symbol order within each length */
  for (sym = 0; sym < codes; sym++) {
    if (lens[lens_index + sym] !== 0) {
      work[offs[lens[lens_index + sym]]++] = sym;
    }
  }

  /*
   Create and fill in decoding tables.  In this loop, the table being
   filled is at next and has curr index bits.  The code being used is huff
   with length len.  That code is converted to an index by dropping drop
   bits off of the bottom.  For codes where len is less than drop + curr,
   those top drop + curr - len bits are incremented through all values to
   fill the table with replicated entries.

   root is the number of index bits for the root table.  When len exceeds
   root, sub-tables are created pointed to by the root entry with an index
   of the low root bits of huff.  This is saved in low to check for when a
   new sub-table should be started.  drop is zero when the root table is
   being filled, and drop is root when sub-tables are being filled.

   When a new sub-table is needed, it is necessary to look ahead in the
   code lengths to determine what size sub-table is needed.  The length
   counts are used for this, and so count[] is decremented as codes are
   entered in the tables.

   used keeps track of how many table entries have been allocated from the
   provided *table space.  It is checked for LENS and DIST tables against
   the constants ENOUGH_LENS and ENOUGH_DISTS to guard against changes in
   the initial root table size constants.  See the comments in inftrees.h
   for more information.

   sym increments through all symbols, and the loop terminates when
   all codes of length max, i.e. all codes, have been processed.  This
   routine permits incomplete codes, so another loop after this one fills
   in the rest of the decoding tables with invalid code markers.
   */

  /* set up for code type */
  // poor man optimization - use if-else instead of switch,
  // to avoid deopts in old v8
  if (type === CODES) {
    base = extra = work;    /* dummy value--not used */
    end = 19;

  } else if (type === LENS) {
    base = lbase;
    base_index -= 257;
    extra = lext;
    extra_index -= 257;
    end = 256;

  } else {                    /* DISTS */
    base = dbase;
    extra = dext;
    end = -1;
  }

  /* initialize opts for loop */
  huff = 0;                   /* starting code */
  sym = 0;                    /* starting code symbol */
  len = min;                  /* starting code length */
  next = table_index;              /* current table to fill in */
  curr = root;                /* current table index bits */
  drop = 0;                   /* current bits to drop from code for index */
  low = -1;                   /* trigger new sub-table when len > root */
  used = 1 << root;          /* use root table entries */
  mask = used - 1;            /* mask for comparing low */

  /* check available table space */
  if ((type === LENS && used > ENOUGH_LENS) ||
    (type === DISTS && used > ENOUGH_DISTS)) {
    return 1;
  }

  /* process all codes and make table entries */
  for (;;) {
    /* create table entry */
    here_bits = len - drop;
    if (work[sym] < end) {
      here_op = 0;
      here_val = work[sym];
    }
    else if (work[sym] > end) {
      here_op = extra[extra_index + work[sym]];
      here_val = base[base_index + work[sym]];
    }
    else {
      here_op = 32 + 64;         /* end of block */
      here_val = 0;
    }

    /* replicate for those indices with low len bits equal to huff */
    incr = 1 << (len - drop);
    fill = 1 << curr;
    min = fill;                 /* save offset to next table */
    do {
      fill -= incr;
      table[next + (huff >> drop) + fill] = (here_bits << 24) | (here_op << 16) | here_val |0;
    } while (fill !== 0);

    /* backwards increment the len-bit code huff */
    incr = 1 << (len - 1);
    while (huff & incr) {
      incr >>= 1;
    }
    if (incr !== 0) {
      huff &= incr - 1;
      huff += incr;
    } else {
      huff = 0;
    }

    /* go to next symbol, update count, len */
    sym++;
    if (--count[len] === 0) {
      if (len === max) { break; }
      len = lens[lens_index + work[sym]];
    }

    /* create new sub-table if needed */
    if (len > root && (huff & mask) !== low) {
      /* if first time, transition to sub-tables */
      if (drop === 0) {
        drop = root;
      }

      /* increment past last table */
      next += min;            /* here min is 1 << curr */

      /* determine length of next table */
      curr = len - drop;
      left = 1 << curr;
      while (curr + drop < max) {
        left -= count[curr + drop];
        if (left <= 0) { break; }
        curr++;
        left <<= 1;
      }

      /* check for enough space */
      used += 1 << curr;
      if ((type === LENS && used > ENOUGH_LENS) ||
        (type === DISTS && used > ENOUGH_DISTS)) {
        return 1;
      }

      /* point entry in root table to sub-table */
      low = huff & mask;
      /*table.op[low] = curr;
      table.bits[low] = root;
      table.val[low] = next - opts.table_index;*/
      table[low] = (root << 24) | (curr << 16) | (next - table_index) |0;
    }
  }

  /* fill in remaining table entry if code is incomplete (guaranteed to have
   at most one remaining entry, since if the code is incomplete, the
   maximum code length that was allowed to get this far is one bit) */
  if (huff !== 0) {
    //table.op[next + huff] = 64;            /* invalid code marker */
    //table.bits[next + huff] = len - drop;
    //table.val[next + huff] = 0;
    table[next + huff] = ((len - drop) << 24) | (64 << 16) |0;
  }

  /* set return parameters */
  //opts.table_index += used;
  opts.bits = root;
  return 0;
};


/***/ }),

/***/ 2893:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


// (C) 1995-2013 Jean-loup Gailly and Mark Adler
// (C) 2014-2017 Vitaly Puzrin and Andrey Tupitsin
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//   claim that you wrote the original software. If you use this software
//   in a product, an acknowledgment in the product documentation would be
//   appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//   misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.

function GZheader() {
  /* true if compressed data believed to be text */
  this.text       = 0;
  /* modification time */
  this.time       = 0;
  /* extra flags (not used when writing a gzip file) */
  this.xflags     = 0;
  /* operating system */
  this.os         = 0;
  /* pointer to extra field or Z_NULL if none */
  this.extra      = null;
  /* extra field length (valid if extra != Z_NULL) */
  this.extra_len  = 0; // Actually, we don't need it in JS,
                       // but leave for few code modifications

  //
  // Setup limits is not necessary because in js we should not preallocate memory
  // for inflate use constant limit in 65536 bytes
  //

  /* space at extra (only when reading header) */
  // this.extra_max  = 0;
  /* pointer to zero-terminated file name or Z_NULL */
  this.name       = '';
  /* space at name (only when reading header) */
  // this.name_max   = 0;
  /* pointer to zero-terminated comment or Z_NULL */
  this.comment    = '';
  /* space at comment (only when reading header) */
  // this.comm_max   = 0;
  /* true if there was or will be a header crc */
  this.hcrc       = 0;
  /* true when done reading gzip header (not used when writing a gzip file) */
  this.done       = false;
}

module.exports = GZheader;


/***/ }),

/***/ 2895:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.Group = exports.Button = undefined;

var _radio = __webpack_require__(1796);

var _radio2 = _interopRequireDefault(_radio);

var _group = __webpack_require__(2897);

var _group2 = _interopRequireDefault(_group);

var _radioButton = __webpack_require__(2898);

var _radioButton2 = _interopRequireDefault(_radioButton);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

_radio2['default'].Button = _radioButton2['default'];
_radio2['default'].Group = _group2['default'];
exports.Button = _radioButton2['default'];
exports.Group = _group2['default'];
exports['default'] = _radio2['default'];

/***/ }),

/***/ 2896:
/***/ (function(module, exports, __webpack_require__) {

/**
 * Copyright 2013-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 *
 * @providesModule ReactComponentWithPureRenderMixin
 */

var shallowEqual = __webpack_require__(741);

function shallowCompare(instance, nextProps, nextState) {
  return !shallowEqual(instance.props, nextProps) || !shallowEqual(instance.state, nextState);
}

/**
 * If your React component's render function is "pure", e.g. it will render the
 * same result given the same props and state, provide this mixin for a
 * considerable performance boost.
 *
 * Most React components have pure render functions.
 *
 * Example:
 *
 *   var ReactComponentWithPureRenderMixin =
 *     require('ReactComponentWithPureRenderMixin');
 *   React.createClass({
 *     mixins: [ReactComponentWithPureRenderMixin],
 *
 *     render: function() {
 *       return <div className={this.props.className}>foo</div>;
 *     }
 *   });
 *
 * Note: This only checks shallow equality for props and state. If these contain
 * complex data structures this mixin may have false-negatives for deeper
 * differences. Only mixin to components which have simple props and state, or
 * use `forceUpdate()` when you know deep data structures have changed.
 *
 * See https://facebook.github.io/react/docs/pure-render-mixin.html
 */
var ReactComponentWithPureRenderMixin = {
  shouldComponentUpdate: function shouldComponentUpdate(nextProps, nextState) {
    return shallowCompare(this, nextProps, nextState);
  }
};

module.exports = ReactComponentWithPureRenderMixin;

/***/ }),

/***/ 2897:
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

var _react = __webpack_require__(1);

var React = _interopRequireWildcard(_react);

var _propTypes = __webpack_require__(0);

var _propTypes2 = _interopRequireDefault(_propTypes);

var _classnames = __webpack_require__(29);

var _classnames2 = _interopRequireDefault(_classnames);

var _shallowequal = __webpack_require__(741);

var _shallowequal2 = _interopRequireDefault(_shallowequal);

var _radio = __webpack_require__(1796);

var _radio2 = _interopRequireDefault(_radio);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj['default'] = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

function getCheckedValue(children) {
    var value = null;
    var matched = false;
    React.Children.forEach(children, function (radio) {
        if (radio && radio.props && radio.props.checked) {
            value = radio.props.value;
            matched = true;
        }
    });
    return matched ? { value: value } : undefined;
}

var RadioGroup = function (_React$Component) {
    (0, _inherits3['default'])(RadioGroup, _React$Component);

    function RadioGroup(props) {
        (0, _classCallCheck3['default'])(this, RadioGroup);

        var _this = (0, _possibleConstructorReturn3['default'])(this, (RadioGroup.__proto__ || Object.getPrototypeOf(RadioGroup)).call(this, props));

        _this.onRadioChange = function (ev) {
            var lastValue = _this.state.value;
            var value = ev.target.value;

            if (!('value' in _this.props)) {
                _this.setState({
                    value: value
                });
            }
            var onChange = _this.props.onChange;
            if (onChange && value !== lastValue) {
                onChange(ev);
            }
        };
        var value = void 0;
        if ('value' in props) {
            value = props.value;
        } else if ('defaultValue' in props) {
            value = props.defaultValue;
        } else {
            var checkedValue = getCheckedValue(props.children);
            value = checkedValue && checkedValue.value;
        }
        _this.state = {
            value: value
        };
        return _this;
    }

    (0, _createClass3['default'])(RadioGroup, [{
        key: 'getChildContext',
        value: function getChildContext() {
            return {
                radioGroup: {
                    onChange: this.onRadioChange,
                    value: this.state.value,
                    disabled: this.props.disabled,
                    name: this.props.name
                }
            };
        }
    }, {
        key: 'componentWillReceiveProps',
        value: function componentWillReceiveProps(nextProps) {
            if ('value' in nextProps) {
                this.setState({
                    value: nextProps.value
                });
            } else {
                var checkedValue = getCheckedValue(nextProps.children);
                if (checkedValue) {
                    this.setState({
                        value: checkedValue.value
                    });
                }
            }
        }
    }, {
        key: 'shouldComponentUpdate',
        value: function shouldComponentUpdate(nextProps, nextState) {
            return !(0, _shallowequal2['default'])(this.props, nextProps) || !(0, _shallowequal2['default'])(this.state, nextState);
        }
    }, {
        key: 'render',
        value: function render() {
            var _this2 = this;

            var props = this.props;
            var prefixCls = props.prefixCls,
                _props$className = props.className,
                className = _props$className === undefined ? '' : _props$className,
                options = props.options,
                buttonStyle = props.buttonStyle;

            var groupPrefixCls = prefixCls + '-group';
            var classString = (0, _classnames2['default'])(groupPrefixCls, groupPrefixCls + '-' + buttonStyle, (0, _defineProperty3['default'])({}, groupPrefixCls + '-' + props.size, props.size), className);
            var children = props.children;
            // 如果存在 options, 优先使用
            if (options && options.length > 0) {
                children = options.map(function (option, index) {
                    if (typeof option === 'string') {
                        // 此处类型自动推导为 string
                        return React.createElement(
                            _radio2['default'],
                            { key: index, prefixCls: prefixCls, disabled: _this2.props.disabled, value: option, onChange: _this2.onRadioChange, checked: _this2.state.value === option },
                            option
                        );
                    } else {
                        // 此处类型自动推导为 { label: string value: string }
                        return React.createElement(
                            _radio2['default'],
                            { key: index, prefixCls: prefixCls, disabled: option.disabled || _this2.props.disabled, value: option.value, onChange: _this2.onRadioChange, checked: _this2.state.value === option.value },
                            option.label
                        );
                    }
                });
            }
            return React.createElement(
                'div',
                { className: classString, style: props.style, onMouseEnter: props.onMouseEnter, onMouseLeave: props.onMouseLeave, id: props.id },
                children
            );
        }
    }]);
    return RadioGroup;
}(React.Component);

exports['default'] = RadioGroup;

RadioGroup.defaultProps = {
    disabled: false,
    prefixCls: 'ant-radio',
    buttonStyle: 'outline'
};
RadioGroup.childContextTypes = {
    radioGroup: _propTypes2['default'].any
};
module.exports = exports['default'];

/***/ }),

/***/ 2898:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _extends2 = __webpack_require__(10);

var _extends3 = _interopRequireDefault(_extends2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var React = _interopRequireWildcard(_react);

var _propTypes = __webpack_require__(0);

var _propTypes2 = _interopRequireDefault(_propTypes);

var _radio = __webpack_require__(1796);

var _radio2 = _interopRequireDefault(_radio);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj['default'] = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var RadioButton = function (_React$Component) {
    (0, _inherits3['default'])(RadioButton, _React$Component);

    function RadioButton() {
        (0, _classCallCheck3['default'])(this, RadioButton);
        return (0, _possibleConstructorReturn3['default'])(this, (RadioButton.__proto__ || Object.getPrototypeOf(RadioButton)).apply(this, arguments));
    }

    (0, _createClass3['default'])(RadioButton, [{
        key: 'render',
        value: function render() {
            var radioProps = (0, _extends3['default'])({}, this.props);
            if (this.context.radioGroup) {
                radioProps.onChange = this.context.radioGroup.onChange;
                radioProps.checked = this.props.value === this.context.radioGroup.value;
                radioProps.disabled = this.props.disabled || this.context.radioGroup.disabled;
            }
            return React.createElement(_radio2['default'], radioProps);
        }
    }]);
    return RadioButton;
}(React.Component);

exports['default'] = RadioButton;

RadioButton.defaultProps = {
    prefixCls: 'ant-radio-button'
};
RadioButton.contextTypes = {
    radioGroup: _propTypes2['default'].any
};
module.exports = exports['default'];

/***/ }),

/***/ 2907:
/***/ (function(module, exports, __webpack_require__) {

var baseClone = __webpack_require__(746);

/** Used to compose bitmasks for cloning. */
var CLONE_SYMBOLS_FLAG = 4;

/**
 * Creates a shallow clone of `value`.
 *
 * **Note:** This method is loosely based on the
 * [structured clone algorithm](https://mdn.io/Structured_clone_algorithm)
 * and supports cloning arrays, array buffers, booleans, date objects, maps,
 * numbers, `Object` objects, regexes, sets, strings, symbols, and typed
 * arrays. The own enumerable properties of `arguments` objects are cloned
 * as plain objects. An empty object is returned for uncloneable values such
 * as error objects, functions, DOM nodes, and WeakMaps.
 *
 * @static
 * @memberOf _
 * @since 0.1.0
 * @category Lang
 * @param {*} value The value to clone.
 * @returns {*} Returns the cloned value.
 * @see _.cloneDeep
 * @example
 *
 * var objects = [{ 'a': 1 }, { 'b': 2 }];
 *
 * var shallow = _.clone(objects);
 * console.log(shallow[0] === objects[0]);
 * // => true
 */
function clone(value) {
  return baseClone(value, CLONE_SYMBOLS_FLAG);
}

module.exports = clone;


/***/ }),

/***/ 2940:
/***/ (function(module, exports, __webpack_require__) {

var toString = __webpack_require__(189);

/**
 * Used to match `RegExp`
 * [syntax characters](http://ecma-international.org/ecma-262/7.0/#sec-patterns).
 */
var reRegExpChar = /[\\^$.*+?()[\]{}|]/g,
    reHasRegExpChar = RegExp(reRegExpChar.source);

/**
 * Escapes the `RegExp` special characters "^", "$", "\", ".", "*", "+",
 * "?", "(", ")", "[", "]", "{", "}", and "|" in `string`.
 *
 * @static
 * @memberOf _
 * @since 3.0.0
 * @category String
 * @param {string} [string=''] The string to escape.
 * @returns {string} Returns the escaped string.
 * @example
 *
 * _.escapeRegExp('[lodash](https://lodash.com/)');
 * // => '\[lodash\]\(https://lodash\.com/\)'
 */
function escapeRegExp(string) {
  string = toString(string);
  return (string && reHasRegExpChar.test(string))
    ? string.replace(reRegExpChar, '\\$&')
    : string;
}

module.exports = escapeRegExp;


/***/ }),

/***/ 2954:
/***/ (function(module, exports) {

/**
 * Converts `iterator` to an array.
 *
 * @private
 * @param {Object} iterator The iterator to convert.
 * @returns {Array} Returns the converted array.
 */
function iteratorToArray(iterator) {
  var data,
      result = [];

  while (!(data = iterator.next()).done) {
    result.push(data.value);
  }
  return result;
}

module.exports = iteratorToArray;


/***/ }),

/***/ 2955:
/***/ (function(module, exports, __webpack_require__) {

var baseExtremum = __webpack_require__(771),
    baseIteratee = __webpack_require__(90),
    baseLt = __webpack_require__(2956);

/**
 * This method is like `_.min` except that it accepts `iteratee` which is
 * invoked for each element in `array` to generate the criterion by which
 * the value is ranked. The iteratee is invoked with one argument: (value).
 *
 * @static
 * @memberOf _
 * @since 4.0.0
 * @category Math
 * @param {Array} array The array to iterate over.
 * @param {Function} [iteratee=_.identity] The iteratee invoked per element.
 * @returns {*} Returns the minimum value.
 * @example
 *
 * var objects = [{ 'n': 1 }, { 'n': 2 }];
 *
 * _.minBy(objects, function(o) { return o.n; });
 * // => { 'n': 1 }
 *
 * // The `_.property` iteratee shorthand.
 * _.minBy(objects, 'n');
 * // => { 'n': 1 }
 */
function minBy(array, iteratee) {
  return (array && array.length)
    ? baseExtremum(array, baseIteratee(iteratee, 2), baseLt)
    : undefined;
}

module.exports = minBy;


/***/ }),

/***/ 2956:
/***/ (function(module, exports) {

/**
 * The base implementation of `_.lt` which doesn't coerce arguments.
 *
 * @private
 * @param {*} value The value to compare.
 * @param {*} other The other value to compare.
 * @returns {boolean} Returns `true` if `value` is less than `other`,
 *  else `false`.
 */
function baseLt(value, other) {
  return value < other;
}

module.exports = baseLt;


/***/ }),

/***/ 3252:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/lodash-es/isSymbol.js
var isSymbol = __webpack_require__(115);

// CONCATENATED MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/lodash-es/_baseExtremum.js


/**
 * The base implementation of methods like `_.max` and `_.min` which accepts a
 * `comparator` to determine the extremum value.
 *
 * @private
 * @param {Array} array The array to iterate over.
 * @param {Function} iteratee The iteratee invoked per iteration.
 * @param {Function} comparator The comparator used to compare values.
 * @returns {*} Returns the extremum value.
 */
function baseExtremum(array, iteratee, comparator) {
  var index = -1,
      length = array.length;

  while (++index < length) {
    var value = array[index],
        current = iteratee(value);

    if (current != null && (computed === undefined
          ? (current === current && !Object(isSymbol["a" /* default */])(current))
          : comparator(current, computed)
        )) {
      var computed = current,
          result = value;
    }
  }
  return result;
}

/* harmony default export */ var _baseExtremum = (baseExtremum);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/lodash-es/_baseIteratee.js + 9 modules
var _baseIteratee = __webpack_require__(186);

// CONCATENATED MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/lodash-es/_baseLt.js
/**
 * The base implementation of `_.lt` which doesn't coerce arguments.
 *
 * @private
 * @param {*} value The value to compare.
 * @param {*} other The other value to compare.
 * @returns {boolean} Returns `true` if `value` is less than `other`,
 *  else `false`.
 */
function baseLt(value, other) {
  return value < other;
}

/* harmony default export */ var _baseLt = (baseLt);

// CONCATENATED MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/lodash-es/minBy.js




/**
 * This method is like `_.min` except that it accepts `iteratee` which is
 * invoked for each element in `array` to generate the criterion by which
 * the value is ranked. The iteratee is invoked with one argument: (value).
 *
 * @static
 * @memberOf _
 * @since 4.0.0
 * @category Math
 * @param {Array} array The array to iterate over.
 * @param {Function} [iteratee=_.identity] The iteratee invoked per element.
 * @returns {*} Returns the minimum value.
 * @example
 *
 * var objects = [{ 'n': 1 }, { 'n': 2 }];
 *
 * _.minBy(objects, function(o) { return o.n; });
 * // => { 'n': 1 }
 *
 * // The `_.property` iteratee shorthand.
 * _.minBy(objects, 'n');
 * // => { 'n': 1 }
 */
function minBy(array, iteratee) {
  return (array && array.length)
    ? _baseExtremum(array, Object(_baseIteratee["a" /* default */])(iteratee, 2), _baseLt)
    : undefined;
}

/* harmony default export */ var lodash_es_minBy = __webpack_exports__["default"] = (minBy);


/***/ }),

/***/ 3255:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/lodash-es/_Symbol.js
var _Symbol = __webpack_require__(96);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/lodash-es/_copyArray.js
var _copyArray = __webpack_require__(1640);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/lodash-es/_getTag.js + 2 modules
var _getTag = __webpack_require__(176);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/lodash-es/isArrayLike.js
var isArrayLike = __webpack_require__(139);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/lodash-es/isString.js
var isString = __webpack_require__(63);

// CONCATENATED MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/lodash-es/_iteratorToArray.js
/**
 * Converts `iterator` to an array.
 *
 * @private
 * @param {Object} iterator The iterator to convert.
 * @returns {Array} Returns the converted array.
 */
function iteratorToArray(iterator) {
  var data,
      result = [];

  while (!(data = iterator.next()).done) {
    result.push(data.value);
  }
  return result;
}

/* harmony default export */ var _iteratorToArray = (iteratorToArray);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/lodash-es/_mapToArray.js
var _mapToArray = __webpack_require__(690);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/lodash-es/_setToArray.js
var _setToArray = __webpack_require__(229);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/lodash-es/_stringToArray.js + 2 modules
var _stringToArray = __webpack_require__(2065);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/lodash-es/values.js + 1 modules
var values = __webpack_require__(544);

// CONCATENATED MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/lodash-es/toArray.js











/** `Object#toString` result references. */
var mapTag = '[object Map]',
    setTag = '[object Set]';

/** Built-in value references. */
var symIterator = _Symbol["a" /* default */] ? _Symbol["a" /* default */].iterator : undefined;

/**
 * Converts `value` to an array.
 *
 * @static
 * @since 0.1.0
 * @memberOf _
 * @category Lang
 * @param {*} value The value to convert.
 * @returns {Array} Returns the converted array.
 * @example
 *
 * _.toArray({ 'a': 1, 'b': 2 });
 * // => [1, 2]
 *
 * _.toArray('abc');
 * // => ['a', 'b', 'c']
 *
 * _.toArray(1);
 * // => []
 *
 * _.toArray(null);
 * // => []
 */
function toArray(value) {
  if (!value) {
    return [];
  }
  if (Object(isArrayLike["a" /* default */])(value)) {
    return Object(isString["default"])(value) ? Object(_stringToArray["a" /* default */])(value) : Object(_copyArray["a" /* default */])(value);
  }
  if (symIterator && value[symIterator]) {
    return _iteratorToArray(value[symIterator]());
  }
  var tag = Object(_getTag["a" /* default */])(value),
      func = tag == mapTag ? _mapToArray["a" /* default */] : (tag == setTag ? _setToArray["a" /* default */] : values["default"]);

  return func(value);
}

/* harmony default export */ var lodash_es_toArray = __webpack_exports__["default"] = (toArray);


/***/ }),

/***/ 3260:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/babel-runtime/helpers/extends.js
var helpers_extends = __webpack_require__(10);
var extends_default = /*#__PURE__*/__webpack_require__.n(helpers_extends);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/babel-runtime/helpers/defineProperty.js
var defineProperty = __webpack_require__(11);
var defineProperty_default = /*#__PURE__*/__webpack_require__.n(defineProperty);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/babel-runtime/helpers/objectWithoutProperties.js
var objectWithoutProperties = __webpack_require__(26);
var objectWithoutProperties_default = /*#__PURE__*/__webpack_require__.n(objectWithoutProperties);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/babel-runtime/helpers/classCallCheck.js
var classCallCheck = __webpack_require__(5);
var classCallCheck_default = /*#__PURE__*/__webpack_require__.n(classCallCheck);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/babel-runtime/helpers/createClass.js
var createClass = __webpack_require__(8);
var createClass_default = /*#__PURE__*/__webpack_require__.n(createClass);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/babel-runtime/helpers/possibleConstructorReturn.js
var possibleConstructorReturn = __webpack_require__(6);
var possibleConstructorReturn_default = /*#__PURE__*/__webpack_require__.n(possibleConstructorReturn);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/babel-runtime/helpers/inherits.js
var inherits = __webpack_require__(9);
var inherits_default = /*#__PURE__*/__webpack_require__.n(inherits);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/react/index.js
var react = __webpack_require__(1);
var react_default = /*#__PURE__*/__webpack_require__.n(react);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/prop-types/index.js
var prop_types = __webpack_require__(0);
var prop_types_default = /*#__PURE__*/__webpack_require__.n(prop_types);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/rc-util/es/PureRenderMixin.js
var PureRenderMixin = __webpack_require__(2896);
var PureRenderMixin_default = /*#__PURE__*/__webpack_require__.n(PureRenderMixin);

// EXTERNAL MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/classnames/index.js
var classnames = __webpack_require__(29);
var classnames_default = /*#__PURE__*/__webpack_require__.n(classnames);

// CONCATENATED MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/rc-checkbox/es/Checkbox.js












var Checkbox_Checkbox = function (_React$Component) {
  inherits_default()(Checkbox, _React$Component);

  function Checkbox(props) {
    classCallCheck_default()(this, Checkbox);

    var _this = possibleConstructorReturn_default()(this, (Checkbox.__proto__ || Object.getPrototypeOf(Checkbox)).call(this, props));

    Checkbox_initialiseProps.call(_this);

    var checked = 'checked' in props ? props.checked : props.defaultChecked;

    _this.state = {
      checked: checked
    };
    return _this;
  }

  createClass_default()(Checkbox, [{
    key: 'componentWillReceiveProps',
    value: function componentWillReceiveProps(nextProps) {
      if ('checked' in nextProps) {
        this.setState({
          checked: nextProps.checked
        });
      }
    }
  }, {
    key: 'shouldComponentUpdate',
    value: function shouldComponentUpdate() {
      for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
        args[_key] = arguments[_key];
      }

      return PureRenderMixin_default.a.shouldComponentUpdate.apply(this, args);
    }
  }, {
    key: 'render',
    value: function render() {
      var _classNames;

      var _props = this.props,
          prefixCls = _props.prefixCls,
          className = _props.className,
          style = _props.style,
          name = _props.name,
          type = _props.type,
          disabled = _props.disabled,
          readOnly = _props.readOnly,
          tabIndex = _props.tabIndex,
          onClick = _props.onClick,
          onFocus = _props.onFocus,
          onBlur = _props.onBlur,
          others = objectWithoutProperties_default()(_props, ['prefixCls', 'className', 'style', 'name', 'type', 'disabled', 'readOnly', 'tabIndex', 'onClick', 'onFocus', 'onBlur']);

      var globalProps = Object.keys(others).reduce(function (prev, key) {
        if (key.substr(0, 5) === 'aria-' || key.substr(0, 5) === 'data-' || key === 'role') {
          prev[key] = others[key];
        }
        return prev;
      }, {});

      var checked = this.state.checked;

      var classString = classnames_default()(prefixCls, className, (_classNames = {}, defineProperty_default()(_classNames, prefixCls + '-checked', checked), defineProperty_default()(_classNames, prefixCls + '-disabled', disabled), _classNames));

      return react_default.a.createElement(
        'span',
        { className: classString, style: style },
        react_default.a.createElement('input', extends_default()({
          name: name,
          type: type,
          readOnly: readOnly,
          disabled: disabled,
          tabIndex: tabIndex,
          className: prefixCls + '-input',
          checked: !!checked,
          onClick: onClick,
          onFocus: onFocus,
          onBlur: onBlur,
          onChange: this.handleChange
        }, globalProps)),
        react_default.a.createElement('span', { className: prefixCls + '-inner' })
      );
    }
  }]);

  return Checkbox;
}(react_default.a.Component);

Checkbox_Checkbox.propTypes = {
  prefixCls: prop_types_default.a.string,
  className: prop_types_default.a.string,
  style: prop_types_default.a.object,
  name: prop_types_default.a.string,
  type: prop_types_default.a.string,
  defaultChecked: prop_types_default.a.oneOfType([prop_types_default.a.number, prop_types_default.a.bool]),
  checked: prop_types_default.a.oneOfType([prop_types_default.a.number, prop_types_default.a.bool]),
  disabled: prop_types_default.a.bool,
  onFocus: prop_types_default.a.func,
  onBlur: prop_types_default.a.func,
  onChange: prop_types_default.a.func,
  onClick: prop_types_default.a.func,
  tabIndex: prop_types_default.a.string,
  readOnly: prop_types_default.a.bool
};
Checkbox_Checkbox.defaultProps = {
  prefixCls: 'rc-checkbox',
  className: '',
  style: {},
  type: 'checkbox',
  defaultChecked: false,
  onFocus: function onFocus() {},
  onBlur: function onBlur() {},
  onChange: function onChange() {}
};

var Checkbox_initialiseProps = function _initialiseProps() {
  var _this2 = this;

  this.handleChange = function (e) {
    var props = _this2.props;

    if (props.disabled) {
      return;
    }
    if (!('checked' in props)) {
      _this2.setState({
        checked: e.target.checked
      });
    }
    props.onChange({
      target: extends_default()({}, props, {
        checked: e.target.checked
      }),
      stopPropagation: function stopPropagation() {
        e.stopPropagation();
      },
      preventDefault: function preventDefault() {
        e.preventDefault();
      }
    });
  };
};

/* harmony default export */ var es_Checkbox = (Checkbox_Checkbox);
// CONCATENATED MODULE: /opt/tiger/fe_pkg/code.byted.org/ee/bear-mobile/node_modules/rc-checkbox/es/index.js
/* concated harmony reexport */__webpack_require__.d(__webpack_exports__, "default", function() { return es_Checkbox; });


/***/ })

}]);
//# sourceMappingURL=https://s3.pstatp.com/eesz/resource/bear/js/vendors~embed-sheet~sheet.152f173c365850f81774.js.map