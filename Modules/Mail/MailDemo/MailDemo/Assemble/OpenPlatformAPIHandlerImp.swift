//
//  OpenPlatformAPIHandlerImp.swift
//  LarkOpenPlatform
//
//  Created by zhysan on 2020/10/12.
//

import Foundation
import EENavigator
import LarkAppLinkSDK
import WebBrowser
import LarkMessengerInterface
import LarkLocalizations
import LarkUIKit
import LarkAccountInterface
import Swinject
import LarkRustClient
import RustPB
import RxSwift
import LKCommonsLogging
import LarkOPInterface
import LarkSDKInterface
import Homeric
import LKCommonsTracker
import CookieManager
import LarkFeatureGating
import LarkSetting
import SuiteAppConfig
import OPFoundation
import LarkTab
import LarkNavigation
import LarkGuide
import LarkWebViewContainer
import ECOInfra
import LarkContainer
import WebKit
import LarkCloudScheme

// swiftlint:disable all
private let logger = Logger.oplog(OpenPlatformAPIHandlerImp.self, category: "OpenPlatformAPIHandlerImp")

private let kOPAPIHandlerErrorDomain = "client.open_platform.api_handler"

final class OpenPlatformAPIHandlerImp {

    @Provider var configService: ECOConfigService

    internal init(_ resolver: Resolver) {
        self.resolver = resolver
    }

    // MARK: - private

    private let resolver: Resolver

    func featureGeting(for key: String) -> Bool {
        LarkFeatureGating.shared.getFeatureBoolValue(for: key)
    }
    
    func settingsDictionaryValue(for key: String) -> [String: Any]? {
        configService.getDictionaryValue(for: key)
    }
}

let hookJSString = """
(function () {
  'use strict';
  class Bridge {
    constructor() {
      this.callbackID = 1;
      this.pendings = {};
    }
  
    invoke(name, data = {}) {
      // warn: 如果传数字，回传的 callbackID 就会变成空字符串
      const callbackID = (this.callbackID ++).toString();
      return new Promise((resolve, reject) => {
        this.pendings[callbackID] = {
          resolve,
          reject
        }
        webkit.messageHandlers.ajaxFetchHook.postMessage({
          apiName: name,
          data,
          callbackID,
        });
      })
    }
  
    callback(response) {
      const callbackID = response.callbackID;
      if (!bridge.pendings[callbackID]) {
        return;
      }
  
      if (response.callbackType === 'success') {
        bridge.pendings[callbackID].resolve(response.data)
      } else {
        bridge.pendings[callbackID].reject(response.data)
      }
      delete bridge.pendings[callbackID];
    }
  }
  
  const bridge = new Bridge();
  
  window.AjaxFetchHookBridge = window.AjaxFetchHookBridge || {};
  window.AjaxFetchHookBridge.callback = function (response) {
    bridge.callback(response);
  };
  
  const getID = function () {
    return bridge.invoke('getBodyRecoverRequestID').then((data) => {
      return data.id;
    });
  };
  
  const setBody = function (id, url, bodyType, formEnctype, value) {
    return bridge.invoke('setRecoverRequestBody', {
      id,
      url,
      bodyType,
      formEnctype,
      value
    });
  }
  
  const isHookEnabled = function () {
    return bridge.invoke('getAjaxFetchFG').then((data) => {
      if (data && !!data.result) {
        return true;
      } else {
        return Promise.reject('unable');
      }
    });
  }
  
  const convertArrayBufferToBase64 = function (arraybuffer) {
    var uint8Array = new Uint8Array(arraybuffer);
    var charCode = "";
    var length = uint8Array.byteLength;
    for (var i = 0; i < length; i++) {
      charCode += String.fromCharCode(uint8Array[i]);
    }
    // 字符串转成base64
    return window.btoa(charCode);
  };
  
  function __values(o) {
    var m = typeof Symbol === "function" && o[Symbol.iterator], i = 0;
    if (m) return m.call(o);
    return {
        next: function () {
            if (o && i >= o.length) o = void 0;
            return { value: o && o[i++], done: !o };
        }
    };
  }
  
  const traversalEntries = function (formData, traversal) {
    var e_1, _a;
    if (formData._entries) { // 低版本的 iOS 系统，并不支持 entries() 方法，所以这里做兼容处理
      for (var i = 0; i < formData._entries.length; i++) {
        var pair = formData._entries[i];
        var key = pair[0];
        var value = pair[1];
        var fileName = pair.length > 2 ? pair[2] : null;
        if (traversal) {
          traversal(key, value, fileName);
        }
      }
    }
    else {
      try {
        // JS 里 FormData 表单实际上也是一个键值对
        for (var _b = __values(formData.entries()), _c = _b.next(); !_c.done; _c = _b.next()) {
          var pair = _c.value;
          var key = pair[0];
          var value = pair[1];
          if (traversal) {
            traversal(key, value, null);
          }
        }
      }
      catch (e_1_1) { e_1 = { error: e_1_1 }; }
      finally {
        try {
          if (_c && !_c.done && (_a = _b.return)) _a.call(_b);
        }
        finally { if (e_1) throw e_1.error; }
      }
    }
  };
  
  const convertSingleFormDataRecordToArray = function (key, value, fileName) {
    return new Promise(function (resolve, reject) {
      var singleKeyValue = [];
      singleKeyValue.push(key);
      if (value instanceof File || value instanceof Blob) { // 针对文件特殊处理
        var reader = new FileReader();
        
        reader.onload = function (ev) {
          var base64 = ev.target.result;
          var formDataFile = {
            name: fileName ? fileName : (value instanceof File ? value.name : ''),
            lastModified: value instanceof File ? value.lastModified : 0,
            size: value.size,
            type: value.type,
            data: base64
          };
          singleKeyValue.push(formDataFile);
          resolve(singleKeyValue);
          return null;
        };
        reader.onerror = function (ev) {
          reject(Error("formdata 表单读取文件数据失败"));
          return null;
        };
        reader.readAsDataURL(value);
      }
      else {
        singleKeyValue.push(value);
        resolve(singleKeyValue);
      }
    });
  };
  
  const convertFormDataToJson = function (formData, callback) {
    var allPromise = [];
    traversalEntries(formData, function (key, value, fileName) {
      allPromise.push(convertSingleFormDataRecordToArray(key, value, fileName));
    });
    return Promise.all(allPromise).then(function (formDatas) {
      var formDataJson = {};
      var formDataFileKeys = [];
      for (var i = 0; i < formDatas.length; i++) {
        var singleKeyValue = formDatas[i];
        // 只要不是字符串，那就是一个类文件对象，需要加入到 formDataFileKeys 里，方便 native 做编码转换
        if (singleKeyValue.length > 1 && !(typeof singleKeyValue[1] == "string")) {
            formDataFileKeys.push(singleKeyValue[0]);
        }
      }
      formDataJson['fileKeys'] = formDataFileKeys;
      formDataJson['formData'] = formDatas;
      return formDataJson;
    })
  };
  
  const transformData = function (data) {
    if (data instanceof ArrayBuffer) {
      return {
        bodyType: "ArrayBuffer",
        bodyData: convertArrayBufferToBase64(data)
      }
    }
    else if (data instanceof Blob) { // 说明是 Blob，转成 base64
      return new Promise((resolve, reject) => {
        var fileReader = new FileReader();
        fileReader.onload = function (ev) {
          resolve({
            bodyType: 'Blob',
            bodyData: ev.target.result
          });
        };
        fileReader.onerror = function (error) {
          reject(error);
        }
        fileReader.readAsDataURL(data);
      })
    }
    else if (data instanceof FormData) { // 说明是表单
      return convertFormDataToJson(data).then((formDataJSON) => {
        return {
          bodyType: "FormData",
          bodyData: formDataJSON
        }
      })
    }
    else {
      return Promise.resolve({
        bodyType: "String",
        bodyData: data
      });
    }
  }
  
  const isNonNormalHttpRequest = function (url, httpMethod) {
    var pattern = /^((http|https):\\/\\/)/;
    var isNonNormalRequest = !pattern.test(url) && httpMethod === "GET";
    return isNonNormalRequest;
  };
  
  const _fetch = window.fetch;
  window.fetch = function (resource, init) {
    let url;
    let body;
    if (typeof resource === 'string' && init && init.body !== undefined) {
      url = resource;
      body = init.body;
    } else if (resource instanceof Request) {
      url = resource.url;
      body = resource.body;
    }

    if (!url || !body) {
      return _fetch.call(window, resource, init);
    }

    return isHookEnabled().then(() => {
      const formEnctype = body instanceof FormData ? "multipart/form-data" : 'application/x-www-form-urlencoded';
  
      return Promise.all([getID(), transformData(body)]).then(([ id, { bodyType, bodyData } ]) => {
        if (typeof resource === 'string' && init) {
          if (init.headers) {
            init.headers['Lark-Web-Body-Recover-Request-ID'] = id;
          } else {
            init.headers = {
              'Lark-Web-Body-Recover-Request-ID': id,
            }
          }
        } else if (resource instanceof Request) {
          resource.headers['Lark-Web-Body-Recover-Request-ID'] = id;
        }
        return setBody(id, url, bodyType, formEnctype, bodyData)
      }).then(() => {
        return _fetch.call(window, resource, init);
      }).catch((error) => {
        console.error('set body to native failed', error);
        return _fetch.call(window, resource, init);
      });
    }).catch((error) => {
      return _fetch.call(window, resource, init);
    });
  };
  
  const _open = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function (method, url) {
    this.__url = url;
    this.__method = method;
    return _open.apply(this, arguments);
  }
  
  const _send = XMLHttpRequest.prototype.send;
  XMLHttpRequest.prototype.send = function (body) {
    const args = [].slice.call(arguments);
    const xhr = this;
    if (isNonNormalHttpRequest(this.__url, this.__method)) {
      return _send.apply(xhr, args);
    }
    if (!body) {
      return _send.apply(xhr, args);
    }
    const formEnctype = body instanceof FormData ? "multipart/form-data" : 'application/x-www-form-urlencoded';
  
    isHookEnabled().then(() => {
      Promise.all([getID(), transformData(body)]).then(([ id, { bodyType, bodyData } ]) => {
        xhr.setRequestHeader('Lark-Web-Body-Recover-Request-ID', id.toString());
        return setBody(id, xhr.__url, bodyType, formEnctype, bodyData)
      })
      .then(() => {
        return _send.apply(xhr, args);
      }).catch((error) => {
        console.error('set body to native failed', error);
        return _send.apply(xhr, args);
      });
    }).catch((error) => {
      return _send.apply(xhr, args);
    });
  }
})();
"""

extension OpenPlatformAPIHandlerImp: WebBrowserDependencyProtocol, LarkWebViewProtocol {
    func errorpageHTML() -> String? {
        return nil
    }
    func webDetectPageHTML() -> String? {
        return nil
    }
    
    func ajaxFetchHookString() -> String? {
        return nil
    }
    func launchMyAI(browser: WebBrowser) {}

    func registerExtensionItemsForBitableHomePage(browser: WebBrowser) {}
    
    public func setupAjaxFetchHook(webView: LarkWebView) {
        if LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.offline_web.ajax_hook.enable") {
            webView.ajaxFetchHookBridge.setAjaxFetchHook()
            var hookIframe = LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.offline_web.ajax_hook.iframe.enable")
            let userScript = WKUserScript(source: hookJSString, injectionTime: .atDocumentStart, forMainFrameOnly: !hookIframe)
            webView.configuration.userContentController.addUserScript(userScript)
        }
    }
    public func networkClient() -> ECONetworkClientProtocol {
        Injected<ECONetworkClientProtocol>(name: ECONetworkChannel.rust.rawValue, arguments: OperationQueue(), DefaultRequestSetting).wrappedValue
    }
    func appInfoForCurrentWebpage(browser: WebBrowser) -> WebAppInfo? {
        return nil
    }
    func isWebAppForCurrentWebpage(browser: WebBrowser) -> Bool {
        return false
    }
    func registerTranslate(browser: WebBrowser) {

    }
    func isTabState(_ tab: Tab?) -> Bool {
        guard let navigationService = self.resolver.resolve(NavigationService.self),
              let tab = tab else {
            return false
        }
        if navigationService.checkInTabs(for: tab) {
            return true
        }
        return false
    }
    func getLarkWebJsSDK(with api: WebBrowser, methodScope: JsAPIMethodScope) -> LarkWebJSSDK? {
        return nil
    }

    func canOpen(url: URL) -> Bool {
        CloudSchemeManager.shared.canOpen(url: url)
    }

    func openURL(_ url: URL,
                 options: [UIApplication.OpenExternalURLOptionsKey: Any],
                 completionHandler completion: ((Bool) -> Void)?) {
        CloudSchemeManager.shared.open(url, options: options, completionHandler: completion)
    }

    /// 获取网页应用带Api授权机制的JSSDK
    /// - Parameters:
    ///   - appId: 应用ID
    ///   - apiHost: api实现方
//    func getWebAppJsSDKWithAuthorization(appId: String, apiHost: WebBrowser) -> WebAppApiAuthJsSDKProtocol? {
//        WebAppApiAuthJsSDK(appID: appId, apiHost: apiHost, resolver: resolver)
//    }

    /// 获取网页应用不带Api授权机制的JSSDK
    /// - Parameters:
    ///   - apiHost: api实现方
//    func getWebAppJsSDKWithoutAuthorization(apiHost: WebBrowser) -> WebAppApiNoAuthProtocol? {
//        WebAppApiNoAuth(apiHost: apiHost)
//    }

//    func auditEnterH5App(_ appID: String) {
//        if let auditService = resolver.resolve(OPAppAuditService.self) {
//            auditService.auditEnterApp(appID)
//        }
//    }
//
//    func asyncDetectAndReportH5AppSandbox(_ appId: String) {
//        SandboxDetection.asyncDetectAndReportH5SandboxInfo(appId: appId)
//    }

    //  Onboarding相关
    /// 是否需要引导
    /// - Parameter key: 引导key
    func checkShouldShowGuide(key: String) -> Bool {
        guard let newGuideService = resolver.resolve(NewGuideService.self) else {
            let msg = "has no NewGuideService, please contact ug team"
            assertionFailure(msg)
            logger.error(msg)
            return false
        }
        return newGuideService.checkShouldShowGuide(key: key)
    }

    /// 完成引导
    /// - Parameter guideKey: 引导Key
    func didShowedGuide(guideKey: String) {
        guard let newGuideService = resolver.resolve(NewGuideService.self) else {
            let msg = "has no NewGuideService, please contact ug team"
            assertionFailure(msg)
            logger.error(msg)
            return
        }
        newGuideService.didShowedGuide(guideKey: guideKey)
    }
}

extension OpenPlatformAPIHandlerImp {
    func close(_ viewController: UIViewController?) -> Bool {
        guard let vc = viewController else {
            return true
        }
        guard let nav = vc.navigationController else {
            // present
            vc.dismiss(animated: true, completion: nil)
            return true
        }
        guard let topvc = nav.topViewController else {
            logger.warn("nav top vc is nil, nav: \(nav), vcs: \(nav.viewControllers)")
            return false
        }
        guard topvc == vc || topvc.children.contains(vc) else {
            logger.warn("web vc is not at the top level, topvc: \(nav.viewControllers)")
            return false
        }
        // zhysan todo: iPad 兼容性验证
        //  iPad兼容 @lixiaorui
        return true
    }

    func canOpen(_ url: URL) -> Bool {
        return true
    }

    func open(_ url: URL) {
        if !canOpen(url) {
            logger.warn("open url not support: \(url)")
            return
        }
        // iPad 兜底适配
        if let from = OPNavigatorHelper.topmostNav(window: OPWindowHelper.fincMainSceneWindow()) {
            Navigator.shared.push(url, from: from)
        } else {
            logger.error("open url failed because can not find from")
        }
    }

    func larkCookies() -> [HTTPCookie] {
        LarkCookieManager.shared.buildLarkCookies(session: AccountServiceAdapter.shared.currentAccessToken, domains: nil).map { $1 }.flatMap { $0 }
    }
}

// swiftlint:enable all
