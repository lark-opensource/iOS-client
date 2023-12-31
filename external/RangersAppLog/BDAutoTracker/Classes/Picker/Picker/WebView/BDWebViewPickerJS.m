//
//  BDWebViewPickerJS.m
//  Pods-BDAutoTracker_Example
//
//  Created by bob on 2019/7/6.
//

#import "BDWebViewPickerJS.h"

NSString *bd_picker_pickerJS() {
    #define __picker_js_func__(x) @#x
    static NSString *bdPickerJSCode = __picker_js_func__(
 !(function() {
     "use strict";

     function e(e) {
         if (["LI", "TR", "DL"].includes(e.nodeName)) return !0;
         if (e.dataset && e.dataset.hasOwnProperty("teaIdx")) return !0;
         if (e.hasAttribute && e.hasAttribute("data-tea-idx")) return !0;
         return !1
     }

     function t(t) {
         for (var n = []; null !== t.parentElement;) n.push(t), t = t.parentElement;
         var r = [],
             i = [];
         return n.forEach((function(t) {
             var n = function(t) {
                     if (null === t) return {
                         str: "",
                         index: 0
                     };
                     var n = 0,
                         r = t.parentElement;
                     if (r)
                         for (var i = 0; i < r.children.length && r.children[i] !== t; i++) r.children[i].nodeName === t.nodeName && n++;
                     return {
                         str: [t.nodeName.toLowerCase(), e(t) ? "[]" : ""].join(""),
                         index: n
                     }
                 }(t),
                 o = n.str,
                 a = n.index;
             r.unshift(o), i.unshift(a)
         })), {
             element_path: "/".concat(r.join("/")),
             positions: i
         }
     }
     var n = window.__TEA_CHUNK_MAX__ || 524288;

     function r(e) {
         try {
             return new Blob([e]).size
         } catch (i) {
             for (var t = e.length, n = t - 1; n >= 0; n--) {
                 var r = e.charCodeAt(n);
                 r > 127 && r <= 2047 ? t++ : r > 2047 && r <= 65535 && (t += 2), r >= 56320 && r <= 57343 && n--
             }
             return t
         }
     }

     function i(e) {
         if (r(e) < n) return [e];
         var t = encodeURIComponent(e),
             i = Math.ceil(r(t) / n);
         return new Array(i).fill("").map((function(e, r) {
             return t.substr(r * n, n)
         }))
     }
     var o = !1,
         a = 1,
         u = window.innerWidth,
         c = window.innerHeight,
         l = new Set;
     var f = function(e) {
             var t = e._element_path,
                 n = e.positions,
                 r = e.children;
             e._checkList = !0;
             var i = t.split("/").length - 2;
             if (e.fuzzy_positions || (e.fuzzy_positions = [].concat(n)), e.fuzzy_positions[i] = "*", r) {
                 ! function e(t) {
                     t.forEach((function(t) {
                         t.fuzzy_positions || (t.fuzzy_positions = [].concat(t.positions)), t.fuzzy_positions[i] = "*", t.children && e(t.children)
                     }))
                 }(r)
             }
         },
         s = function e(n) {
             return Array.prototype.slice.call(n, 0).reduce((function(n, r) {
                 if (!r) return n;
                 var i = r.nodeName;
                 if (function(e) {
                         return ["script", "link", "style", "embed"].includes(e)
                     }(i = i.toLowerCase()) || function(e) {
                         var t = getComputedStyle(e, null);
                         if ("none" === t.getPropertyValue("display")) return !0;
                         if ("0" === t.getPropertyValue("opacity")) return !0;
                         return !1
                     }(r)) return n;
                 var o = function(e) {
                     var t = arguments.length > 1 && void 0 !== arguments[1] ? arguments[1] : 1,
                         n = e.getBoundingClientRect().toJSON();
                     if (1 === t) return n;
                     return Object.keys(n).reduce((function(e, r) {
                         return e[r] = Math.ceil(n[r] * t), e
                     }), {})
                 }(r, a);
                 if (! function(e, t) {
                         var n = e.left,
                             r = e.right,
                             i = e.top,
                             o = e.bottom,
                             a = e.width,
                             u = e.height,
                             c = !(a > 0 && u > 0),
                             l = getComputedStyle(t, null);
                         if (!["", "static"].includes(l.getPropertyValue("position"))) {
                             if (c && !t.children.length) return !1;
                             var f = l.getPropertyValue("z-index");
                             if ("auto" !== f && parseInt(f, 10) < 0) return !1;
                             return !0
                         }
                         if (c) return !1;
                         if (n > window.innerWidth || r < 0 || i > window.innerHeight || o < 0) return !1;
                         return !0
                     }(o, r)) return n;
                 o = function(e) {
                     var t = {
                         x: e.left,
                         y: e.top,
                         width: e.width,
                         height: e.height
                     };
                     return e.top < 0 && (t.y = 0, t.height += e.top), e.bottom > c && (t.height = c - t.y), e.left < 0 && (t.x = 0, t.width += e.left), e.right > u && (t.width = u - t.x), Object.keys(t).forEach((function(e) {
                         t[e] = Math.floor(t[e])
                     })), t
                 }(o);
                 var s = {};
                 if (! function(e) {
                         return ["button", "select"].includes(e)
                     }(i) && r.children) {
                     var h = e(r.children);
                     h && h.length && (s = {
                         children: h
                     })
                 }
                 var d = function(e) {
                         var n = t(e),
                             r = n.element_path,
                             i = n.positions.map((function(e) {
                                 return "".concat(e)
                             })),
                             o = [].concat(i).reverse(),
                             a = !1;
                         if (-1 !== r.indexOf("[]")) {
                             a = !0;
                             var u = !1;
                             r.split("/").reverse().forEach((function(e, t) {
                                 u || -1 === e.indexOf("[]") || (u = !0, o[t] = "*")
                             }))
                         }
                         var c = e.id,
                             l = e.tagName,
                             f = ["absolute", "fixed"],
                             s = 0,
                             h = getComputedStyle(e, null).getPropertyValue("z-index");
                         "auto" !== h && (s = parseInt(String(h), 10));
                         for (var d = e.parentElement; d;) {
                             var p = getComputedStyle(d, null);
                             if (f.includes(p.getPropertyValue("position"))) {
                                 s += 1e4;
                                 break
                             }
                             d = d.parentElement
                         }
                         return Object.assign({
                             element_id: c,
                             element_type: l,
                             _element_path: r,
                             element_path: "".concat(r, "/*"),
                             positions: i.concat("*"),
                             zIndex: s
                         }, a ? {
                             fuzzy_positions: o.reverse().concat("*")
                         } : {})
                     }(r),
                     p = d._element_path,
                     v = !1;
                 if (l.has(p)) v = !0;
                 else {
                     var g = r.parentElement;
                     if (g) {
                         var m = g.children,
                             w = Array.from(m).filter((function(e) {
                                 return e.nodeName.toLowerCase() === i
                             })),
                             y = w.length;
                         if (y >= 3) {
                             var _ = Array.from(r.classList),
                                 z = _.length,
                                 b = Array.from(r.children).map((function(e) {
                                     return e.nodeName.toLowerCase()
                                 })).join(","),
                                 A = 0;
                             Array.from(w).forEach((function(e) {
                                 if (e === r) return A++, void 0;
                                 var t = !1;
                                 if (z) {
                                     var n = Array.from(e.classList);
                                     _.length + n.length - new Set([].concat(n, _)).size > 0 && (t = !0)
                                 } else t = !0;
                                 if (t) {
                                     var i = !1;
                                     if (b) {
                                         var o = Array.from(e.children).map((function(e) {
                                             return e.nodeName.toLowerCase()
                                         })).join(",");
                                         o === b && (i = !0)
                                     } else i = !0;
                                     i && A++
                                 }
                             })), A >= 3 && A / y >= .5 && (v = !0), v && l.add(p)
                         }
                     }
                 }
                 return d = Object.assign(Object.assign({
                     nodeName: i,
                     frame: o
                 }, d), s), v && f(d), d.children && d.children.forEach((function(e) {
                     var t = e._element_path,
                         n = e._checkList;
                     l.has(t) && !n && f(e)
                 })), n.push(d), n
             }), [])
         },
         h = function() {
             if (o) return;
             o = !0, a = function() {
                 try {
                     var e = window.outerWidth / window.innerWidth;
                     if (1 === e) return 1;
                     if (e) return e;
                     var t = document.querySelector('meta[name="viewport"]');
                     if (t) {
                         var n = t.content.match(/initial-scale=(.*?)(,|$)/);
                         if (n && n[1]) {
                             var r = parseFloat(n[1]);
                             if (r) return r
                         }
                     }
                 } catch (e) {
                     return 1
                 }
                 return 1
             }(), u = window.innerWidth * a, c = window.innerHeight * a, l = new Set
         },
         d = function(e) {
             return JSON.stringify(e)
         };
     if (!window.TEAWebviewInfo) {
         var p = [],
             v = function() {
                 var e = arguments.length > 0 && void 0 !== arguments[0] && arguments[0];
                 if (p.length) return console.log(p.length, p), d({
                     value: p.shift(),
                     done: !p.length
                 });
                 h();
                 try {
                     var t = s(document.querySelectorAll("body > *")),
                         n = {
                             page: window.location.href,
                             info: t
                         },
                         r = d(n);
                     if (console.log(r), !e) return r;
                     if (1 === (p = i(r)).length) return p.shift();
                     return console.log(p.length, p), d({
                         value: p.shift(),
                         done: !1
                     })
                 } catch (e) {
                     console.log(e)
                 }
                 return ""
             };
         v.version = "1.2.1", window.TEAWebviewInfo = v
     }
 }());

    );
    #undef __picker_js_func__
    return bdPickerJSCode;
}
