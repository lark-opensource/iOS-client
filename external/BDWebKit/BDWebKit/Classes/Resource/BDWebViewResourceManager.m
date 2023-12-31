//
//  BDWebViewResourceManager.m
//  BDWebKit
//
//  Created by wealong on 2019/12/29.
//

#import "BDWebViewResourceManager.h"
#import "BDWebKitVersion.h"
#import <IESGeckoKit/IESGeckoKit.h>
#import <IESGeckoKit/IESGurdKit+ExtraParams.h>
#import <BDAlogProtocol/BDAlogProtocol.h>

static const NSTimeInterval SYNC_INTERVAL = 30 * 60; // 30分钟
static NSString * const PUBLIC_ACCESS_KEY = @"03c035fcbad03eef873d03312a65a7f9";
static NSString * const IN_HOUSE_ACCESS_KEY = @"1b191a8beae1d32c4eec160ffb42e3c3";

@interface BDWebViewResourceManager ()

@property (nonatomic, assign) NSTimeInterval lastSyncTime;

@end

@implementation BDWebViewResourceManager

+ (instancetype)sharedInstance {
    static BDWebViewResourceManager *_sharedSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedSingleton = [[self alloc] init];
    });
    return _sharedSingleton;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didBecomeActiveNotification:(NSNotification *)notification {
    [self syncAssetsIfNeed];
}

#pragma mark - Gecko Sync

- (void)syncAssetsIfNeed {
    NSTimeInterval currentTime = [NSDate date].timeIntervalSince1970;
    if (self.lastSyncTime + SYNC_INTERVAL < currentTime) {
        self.lastSyncTime = currentTime;
        [self syncBDWebViewAssetsWithChannels:[self innerChannels] completion:NULL];
    }
}

- (NSArray <NSString *>*)innerChannels {
    if (self.isInHouse) {
        return @[@"bdwebview_hook", @"vconsole", @"native_video_hook"];
    } else {
        return @[@"bdwebview_hook", @"native_video_hook"];
    }
}

- (NSString *)geckoAccessKey {
    NSString *accessKey = nil;
    if (self.isInHouse) {
        accessKey = IN_HOUSE_ACCESS_KEY;
    }
    else {
        accessKey = PUBLIC_ACCESS_KEY;
    }
    return accessKey;
}

- (void)syncBDWebViewAssetsWithChannels:(NSArray<NSString *> *)channels completion:(nullable void(^)(BOOL success))completion {

    [self syncAssetsWithAccessKey:[self geckoAccessKey]
                         channels:channels
                       completion:completion];
}

- (void)syncAssetsWithAccessKey:(NSString *)accessKey channels:(NSArray<NSString *> *)channels completion:(void (^)(BOOL))completion {
    
    [IESGurdKit registerAccessKey:accessKey channels:channels];
    if (![IESGurdKit didSetup]) {
        BDALOG_PROTOCOL_ERROR(@"IESGeckoKit hasn't setup, call +[IESGurdKit setupWithAppId:appVersion:cacheRootDirectory:]");
        if (completion) {
            completion(NO);
        }
        return;
    }
    [IESGurdKit syncResourcesWithAccessKey:accessKey channels:channels resourceVersion:_BDWebKitVersion() completion:^(BOOL succeed, IESGurdSyncStatusDict  _Nonnull dict) {
        if (completion) {
            completion(succeed);
        }
    }];
}

#pragma mark - remote Script

- (NSString *)fetchAjaxHookJS {
    NSString *jsScript = nil;
    NSString *accessKey = [self geckoAccessKey];
    //兜底
    NSString *path = @"wk_hookajax.js";
    NSString *channel = @"bdwebview_hook";
    [self syncAssetsIfNeed];
    BOOL res = [IESGurdKit hasCacheForPath:path accessKey:accessKey channel:channel];
    if (res) {
        NSData *data = [IESGurdKit dataForPath:path accessKey:accessKey channel:channel];
        jsScript = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } else {
        //读取内置的
        jsScript = [self bdw_hookAjaxJS];
    }
    return jsScript;
}

- (NSString *)vConsoleJS {
    NSString *jsScript = nil;
    NSString *accessKey = [self geckoAccessKey];

    NSString *path = @"vconsole.js";
    NSString *channel = @"vconsole";
    NSData *data = [IESGurdKit dataForPath:path accessKey:accessKey channel:channel];
    if (data) {
        jsScript = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        return jsScript;
    } else {
        [self syncAssetsIfNeed];
    }
    return @"";
}

- (NSString *)nativeVideoHookJS {
    NSString *jsScript = nil;
    NSString *accessKey = [self geckoAccessKey];

    NSString *path = @"native_video_hook.js";
    NSString *channel = @"native_video_hook";
    [self syncAssetsIfNeed];
    NSData *data = [IESGurdKit dataForPath:path accessKey:accessKey channel:channel];
    if (data) {
        jsScript = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        return jsScript;
    }
    return @"";
}

#pragma mark - inner Script

- (NSString *)fetchDetectBlankContentJS {
    return @"(function(){try{\
                var blankContent = false;\
                var img = document.getElementsByTagName('img');\
                var video = document.getElementsByTagName('video');\
                var text = document.documentElement.innerText;\
                text = text.trim();\
                if (!text && img.length < 1 && video.length < 1) {\
                    blankContent = true;\
                }\
                return blankContent;\
            }catch(e){}})();";
}

- (NSString *)fetchHookConsoleLogToConfirm {
    return @"window.console.__log__ = window.console.log; \
             window.console.log = function(msg) { \
                 window.console.__log__(msg);   \
                 if (typeof msg === 'string') { \
                    if (msg.indexOf('bytedance://domReady') === 0) { \
                        confirm(msg); \
                    } else { \
                        try { \
                            window.webkit.messageHandlers['consoleLog'].postMessage(msg); \
                        } catch (e) {}\
                    } \
                 } \
             }";
}

- (NSString *)bdw_hookAjaxJS {
    return @"!function(t,e){\"object\"==typeof exports&&\"undefined\"!=typeof module?e():\"function\"==typeof define&&define.amd?define(e):e()}(0,function(){\"use strict\";function t(t){var e={};return t instanceof Headers?t.forEach(function(t,r){e[r]=t}):t&&Object.getOwnPropertyNames(t).forEach(function(r){e[r]=t[r]}),e}var e={searchParams:\"URLSearchParams\"in self,iterable:\"Symbol\"in self&&\"iterator\"in Symbol,blob:\"FileReader\"in self&&\"Blob\"in self&&function(){try{return new Blob,!0}catch(t){return!1}}(),formData:\"FormData\"in self,arrayBuffer:\"ArrayBuffer\"in self};if(e.arrayBuffer)var r=[\"[object Int8Array]\",\"[object Uint8Array]\",\"[object Uint8ClampedArray]\",\"[object Int16Array]\",\"[object Uint16Array]\",\"[object Int32Array]\",\"[object Uint32Array]\",\"[object Float32Array]\",\"[object Float64Array]\"],o=ArrayBuffer.isView||function(t){return t&&r.indexOf(Object.prototype.toString.call(t))>-1};function n(t){if(\"string\"!=typeof t&&(t=String(t)),/[^a-z0-9\\-#$%&'*+.^_`|~]/i.test(t)||\"\"===t)throw new TypeError(\"Invalid character in header field name\");return t.toLowerCase()}function s(t){return\"string\"!=typeof t&&(t=String(t)),t}function i(t){var r={next:function(){var e=t.shift();return{done:void 0===e,value:e}}};return e.iterable&&(r[Symbol.iterator]=function(){return r}),r}function a(t){this.map={},t instanceof a?t.forEach(function(t,e){this.append(e,t)},this):Array.isArray(t)?t.forEach(function(t){this.append(t[0],t[1])},this):t&&Object.getOwnPropertyNames(t).forEach(function(e){this.append(e,t[e])},this)}function h(t){if(t.bodyUsed)return Promise.reject(new TypeError(\"Already read\"));t.bodyUsed=!0}function d(t){return new Promise(function(e,r){t.onload=function(){e(t.result)},t.onerror=function(){r(t.error)}})}function c(t){var e=new FileReader,r=d(e);return e.readAsArrayBuffer(t),r}function u(t){if(t.slice)return t.slice(0);var e=new Uint8Array(t.byteLength);return e.set(new Uint8Array(t)),e.buffer}function f(){return this.bodyUsed=!1,this._initBody=function(t){var r;this._bodyInit=t,t?\"string\"==typeof t?this._bodyText=t:e.blob&&Blob.prototype.isPrototypeOf(t)?this._bodyBlob=t:e.formData&&FormData.prototype.isPrototypeOf(t)?this._bodyFormData=t:e.searchParams&&URLSearchParams.prototype.isPrototypeOf(t)?this._bodyText=t.toString():e.arrayBuffer&&e.blob&&((r=t)&&DataView.prototype.isPrototypeOf(r))?(this._bodyArrayBuffer=u(t.buffer),this._bodyInit=new Blob([this._bodyArrayBuffer])):e.arrayBuffer&&(ArrayBuffer.prototype.isPrototypeOf(t)||o(t))?this._bodyArrayBuffer=u(t):this._bodyText=t=Object.prototype.toString.call(t):this._bodyText=\"\",this.headers.get(\"content-type\")||(\"string\"==typeof t?this.headers.set(\"content-type\",\"text/plain;charset=UTF-8\"):this._bodyBlob&&this._bodyBlob.type?this.headers.set(\"content-type\",this._bodyBlob.type):e.searchParams&&URLSearchParams.prototype.isPrototypeOf(t)&&this.headers.set(\"content-type\",\"application/x-www-form-urlencoded;charset=UTF-8\"))},e.blob&&(this.blob=function(){var t=h(this);if(t)return t;if(this._bodyBlob)return Promise.resolve(this._bodyBlob);if(this._bodyArrayBuffer)return Promise.resolve(new Blob([this._bodyArrayBuffer]));if(this._bodyFormData)throw new Error(\"could not read FormData body as blob\");return Promise.resolve(new Blob([this._bodyText]))},this.arrayBuffer=function(){return this._bodyArrayBuffer?h(this)||Promise.resolve(this._bodyArrayBuffer):this.blob().then(c)}),this.text=function(){var t,e,r,o=h(this);if(o)return o;if(this._bodyBlob)return t=this._bodyBlob,e=new FileReader,r=d(e),e.readAsText(t),r;if(this._bodyArrayBuffer)return Promise.resolve(function(t){for(var e=new Uint8Array(t),r=new Array(e.length),o=0;o<e.length;o++)r[o]=String.fromCharCode(e[o]);return r.join(\"\")}(this._bodyArrayBuffer));if(this._bodyFormData)throw new Error(\"could not read FormData body as text\");return Promise.resolve(this._bodyText)},e.formData&&(this.formData=function(){return this.text().then(y)}),this.json=function(){return this.text().then(JSON.parse)},this}a.prototype.append=function(t,e){t=n(t),e=s(e);var r=this.map[t];this.map[t]=r?r+\", \"+e:e},a.prototype.delete=function(t){delete this.map[n(t)]},a.prototype.get=function(t){return t=n(t),this.has(t)?this.map[t]:null},a.prototype.has=function(t){return this.map.hasOwnProperty(n(t))},a.prototype.set=function(t,e){this.map[n(t)]=s(e)},a.prototype.forEach=function(t,e){for(var r in this.map)this.map.hasOwnProperty(r)&&t.call(e,this.map[r],r,this)},a.prototype.keys=function(){var t=[];return this.forEach(function(e,r){t.push(r)}),i(t)},a.prototype.values=function(){var t=[];return this.forEach(function(e){t.push(e)}),i(t)},a.prototype.entries=function(){var t=[];return this.forEach(function(e,r){t.push([r,e])}),i(t)},e.iterable&&(a.prototype[Symbol.iterator]=a.prototype.entries);var l=[\"DELETE\",\"GET\",\"HEAD\",\"OPTIONS\",\"POST\",\"PUT\"];function p(t,e){var r,o,n=(e=e||{}).body;if(t instanceof p){if(t.bodyUsed)throw new TypeError(\"Already read\");this.url=t.url,this.credentials=t.credentials,e.headers||(this.headers=new a(t.headers)),this.method=t.method,this.mode=t.mode,this.signal=t.signal,n||null==t._bodyInit||(n=t._bodyInit,t.bodyUsed=!0)}else this.url=String(t);if(this.credentials=e.credentials||this.credentials||\"same-origin\",!e.headers&&this.headers||(this.headers=new a(e.headers)),this.method=(r=e.method||this.method||\"GET\",o=r.toUpperCase(),l.indexOf(o)>-1?o:r),this.mode=e.mode||this.mode||null,this.signal=e.signal||this.signal,this.referrer=null,(\"GET\"===this.method||\"HEAD\"===this.method)&&n)throw new TypeError(\"Body not allowed for GET or HEAD requests\");this._initBody(n)}function y(t){var e=new FormData;return t.trim().split(\"&\").forEach(function(t){if(t){var r=t.split(\"=\"),o=r.shift().replace(/\\+/g,\" \"),n=r.join(\"=\").replace(/\\+/g,\" \");e.append(decodeURIComponent(o),decodeURIComponent(n))}}),e}function w(t,e){e||(e={}),this.type=\"default\",this.status=void 0===e.status?200:e.status,this.ok=this.status>=200&&this.status<300,this.statusText=\"statusText\"in e?e.statusText:\"OK\",this.headers=new a(e.headers),this.url=e.url||\"\",this._initBody(t)}p.prototype.clone=function(){return new p(this,{body:this._bodyInit})},f.call(p.prototype),f.call(w.prototype),w.prototype.clone=function(){return new w(this._bodyInit,{status:this.status,statusText:this.statusText,headers:new a(this.headers),url:this.url})},w.error=function(){var t=new w(null,{status:0,statusText:\"\"});return t.type=\"error\",t};var b=[301,302,303,307,308];w.redirect=function(t,e){if(-1===b.indexOf(e))throw new RangeError(\"Invalid status code\");return new w(null,{status:e,headers:{location:t}})};var _=self.DOMException;try{new _}catch(t){(_=function(t,e){this.message=t,this.name=e;var r=Error(t);this.stack=r.stack}).prototype=Object.create(Error.prototype),_.prototype.constructor=_}!function(){void 0===window.console.__log__&&(window.console.__log__=window.console.log),window.console.log=function(t){if(window.console.__log__.apply(this,arguments),\"string\"==typeof t)try{window.webkit.messageHandlers.consoleLog.postMessage(t)}catch(t){}};var e=(new Date).getTime(),r=(e=parseInt(e/1e3%1e5))+1,o={};window.imy_realxhr_callback=function(t,e){var r=o[t];if(r&&!r.is_abort&&r.callbackNative(e),!r)try{Array.prototype.slice.call(document.querySelectorAll(\"iframe\")).forEach(function(r){r.contentWindow.postMessage({key:\"imy_realxhr_callback\",id:t,message:e},\"*\")})}catch(t){console.error(t)}o[t]=null},window.addEventListener(\"message\",function(t){if(t&&t.data){var e=t.data||{};\"imy_realxhr_callback\"===e.key&&e.id&&e.message&&window.imy_realxhr_callback(e.id,e.message)}},!1),function(t){function e(t){return function(){return this.hasOwnProperty(t+\"_\")?this[t+\"_\"]:this._xhr[t]}}function r(e){return function(r){var o=this._xhr,n=this;0==e.indexOf(\"on\")?t[e]?o[e]=function(){t[e](n)||r.apply(o,arguments)}:o[e]=r:this[e+\"_\"]=r}}function o(e){return function(){var r=[].slice.call(arguments);if(t[e]){var o=t[e].call(this,r,this._xhr);if(!0===o)return;if(o&&(\"getResponseHeader\"===e||\"getAllResponseHeaders\"===e))return o}return this._xhr[e].apply(this._xhr,r)}}window._ahrealxhr=window._ahrealxhr||XMLHttpRequest,window.XMLHttpRequest=function(){for(var n in this._xhr=new window._ahrealxhr,this._xhr){var s=\"\";try{s=typeof this._xhr[n]}catch(t){}\"function\"===s?this[n]=o(n):Object.defineProperty(this,n,{get:e(n),set:r(n)})}for(var i in t)this[i]||(this[i]=o(i))},window.XMLHttpRequest.UNSENT=0,window.XMLHttpRequest.OPENED=1,window.XMLHttpRequest.HEADERS_RECEIVED=2,window.XMLHttpRequest.LOADING=3,window.XMLHttpRequest.DONE=4,window.XMLHttpRequest.prototype=window._ahrealxhr.prototype,window._ahrealxhr}({getResponseHeader:function(t,e){if(this.needHook){var r=t&&t[0]?t[0].trim():\"\";if(r=r.toLowerCase())for(var o in this.responseHeaders)if(r==o.toLowerCase())return this.responseHeaders[o]}},getAllResponseHeaders:function(t,e){if(this.needHook&&this.responseHeaders){var r=this.responseHeaders,o=\"\";return Object.keys(r).forEach(function(t){o=o+t+\": \"+r[t]+\"\\r\\n\"}),o}},setRequestHeader:function(t,e){try{this._headers||(this._headers={});t[0];var r=t[1];r&&(r=r.toString().trim()),this._headers[t[0]]=t[1]}catch(t){console.error(t)}},open:function(t,e){this.open_arguments=t},send:function(t,e){var n=0,s=this.open_arguments&&this.open_arguments[0]&&\"post\"===this.open_arguments[0].toLowerCase();if(s&&(n=1),s&&(window._is_offline_closed?s=!1:!1===this.open_arguments[2]?(s=!1,n=-1):t&&t[0]&&t[0].constructor===FormData.prototype.constructor?(s=!1,n=-2):n=1),n<0&&console.log(\"bytedance://disable_offline\"),this.needHook=s,console.log(\"bytedance://log_event_v3?event=wkwebview_hook&params=\"+JSON.stringify({value:n})),s){this.request_id=r,o[this.request_id]=this,r++;var i={};i.id=this.request_id,i.data=t[0],i.method=this.open_arguments[0],i.url=this.open_arguments[1],i.headers=this._headers||{},i.headers.referer=location.href,i.headers.origin=location.protocol+\"//\"+location.host,this.readyState=3;try{window.webkit.messageHandlers.IMYXHR.postMessage(i)}catch(t){window.imy_realxhr_callback(this.request_id,{status:0})}return!0}this.withCredentials&&(this._xhr.withCredentials=!0),this.responseType&&(this._xhr.responseType=this.responseType),this.timeout&&(this._xhr.timeout=this.timeout)},abort:function(){this.is_abort=!0},callbackNative:function(t,e){var r=t[0];return this.is_abort?this.readyState=1:(this.status=r.status,this.responseText=r.data?r.data:\"\",this.response=r.data?r.data:\"\",this.responseHeaders=r.headers,this.readyState=4),this.readyState>=3&&(this.status>=200&&this.status<300?this.statusText=\"OK\":this.statusText=\"Fail\"),this.dispatchEvent(new Event(\"readystatechange\")),this.dispatchEvent(new Event(\"load\")),this.onreadystatechange&&this.onreadystatechange(),4==this.readyState?this.onload&&this.onload():this.onerror&&this.onerror(),!0}});window.fetch&&(window._realFetch=window._realFetch||window.fetch,window.fetch=function(e,n){var s,i=\"\",a=\"\",h={},d={},c=0,u=!1;return\"string\"==typeof e&&\"object\"==typeof n&&\"string\"==typeof n.method?(i=e,a=n.method,s=Promise.resolve(n.body),d=t(n.headers)):\"object\"==typeof e&&\"function\"==typeof e.json&&(i=e.url||\"\",a=e.method||\"GET\",s=e.json(),d=t(e.headers)),s?s.then(function(t){return h=t,(u=\"post\"===a.toLowerCase())&&(window._is_offline_closed?(u=!1,c=0):void 0===h||null===h?(u=!1,c=-1):h&&h.constructor===FormData.prototype.constructor?(u=!1,c=-2):c=1),c<=0&&console.log(\"bytedance://disable_offline\"),u?new Promise(function(t,s){var c=n&&n.signal||e&&e.signal;if(c&&c.aborted)return s(new DOMException(\"Aborted\",\"AbortError\"));var u=r;window.xxxRequestId=u,o[u]={callbackNative:function(e){if(c&&c.aborted)return s(new DOMException(\"Aborted\",\"AbortError\"));var r,o={status:e.status,statusText:e.statusText,headers:(r=e.headers||\"\",new Headers(r))};o.url=\"responseURL\"in e?e.responseURL:o.headers.get(\"X-Request-URL\");var n=new w(e.data,o);t(n)}},r++;var f={};f.id=u,f.data=h,f.method=a,f.url=i,f.headers=d;try{window.webkit.messageHandlers.IMYXHR.postMessage(f)}catch(t){window.imy_realxhr_callback(u,{status:0})}}):window._realFetch(e,n)}):window._realFetch(e,n)}),window._setbackXML_=function(){window.XMLHttpRequest=window._ahrealxhr,\"function\"==typeof window._realFetch&&(window.fetch=window._realFetch)}}()});\n";
}

@end
