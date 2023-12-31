//
//  OpenLinkJSAPIHandler.swift
//  LarkWeb
//
//  Created by zhenning on 2019/12/12.
//

import WebBrowser
import LKCommonsLogging
import EENavigator
import LarkContainer

class OpenLinkJSAPIHandler: JsAPIHandler {

    enum PresentStyle: String {
        case push
        case present
    }

    private static let logger = Logger.log(OpenLinkJSAPIHandler.self, category: "OpenLinkJSAPIHandler")
    private weak var api: WebBrowser?
    
    private let resolver: UserResolver
    
    init(api: WebBrowser, resolver: UserResolver) {
        self.api = api
        self.resolver = resolver
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        OpenLinkJSAPIHandler.logger.debug("handle args = \(args))")

        if let urlStr = args["url"] as? String,
            var url = URL(string: urlStr) {
            let animated = ((args["animated"] as? String ?? "true") == "true")
            var presentStyleName = "push"

            if let params = args["params"] as? [String: Any],
                let callbacks = args["callbacks"] as? [String: String] {
                if let newUrl = newUrl(fromUrl: url, params: params, callbacks: callbacks) {
                    url = newUrl
                } else {
                    OpenLinkJSAPIHandler.logger.error("make new url from \(url) failed params \(params)")
                }
            }

            if let presentStyleStr = args["presentStyle"] as? String,
                let presentStyle = PresentStyle(rawValue: presentStyleStr),
                presentStyle == .present {
                presentStyleName = "present"
                let fullScreen = ((args["fullScreen"] as? String ?? "true") == "true")
                if fullScreen {
                    resolver.navigator.present(url,
                                             context: [:],
                                             wrap: nil,
                                             from: api,
                                             prepare: { $0.modalPresentationStyle = .fullScreen },
                                             animated: true,
                                             completion: nil)
                } else {
                    resolver.navigator.present(url, from: api)
                }
            } else {
                resolver.navigator.push(url, from: api)
            }

            if let onSuccess = args["onSuccess"] as? String {
                let arguments = [["url": urlStr, "animated": "\(animated)", "presentStyle": presentStyleName]] as [[String: Any]]
                callbackWith(api: api, funcName: onSuccess, arguments: arguments)
            }
            OpenLinkJSAPIHandler.logger.debug("OpenLinkJSAPIHandler success, url = \(url), animated = \(animated), presentStyle = \(presentStyleName)")
        } else {
            if let onFailed = args["onFailed"] as? String {
                let arguments = [NewJsSDKErrorAPI.missingRequiredArgs.description()] as [[String: Any]]
                callbackWith(api: api, funcName: onFailed, arguments: arguments)
            }
            OpenLinkJSAPIHandler.logger.error("OpenLinkJSAPIHandler failed, urlStr is empty")
        }
    }

    @objc
    func callback(noti: Notification) {
        guard let api = self.api else {
            OpenLinkJSAPIHandler.logger.error("api is released unexpected, cannot callback \(noti.name.rawValue)")
            return
        }
        if let arguments = noti.object {
            api.callbackEvent(name: noti.name.rawValue, params: arguments)
        } else {
            api.callbackEvent(name: noti.name.rawValue, params: "")
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension OpenLinkJSAPIHandler {

    private func newUrl(fromUrl url: URL, params: [String: Any], callbacks: [String: String]) -> URL? {
        guard var urlComponent = URLComponents(string: url.absoluteString) else {
            OpenLinkJSAPIHandler.logger.error("bad url can not make components \(self)")
            return nil
        }
        OpenLinkJSAPIHandler.logger.info("params \(params)")
        var queryItems = [URLQueryItem]()
        params.forEach { (key, value) in
            queryItems.append(URLQueryItem(name: key, value: "\(value)"))
        }
        callbacks.forEach { (key, value) in
            queryItems.append(URLQueryItem(name: key, value: value))
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(callback),
                                                   name: Notification.Name(value),
                                                   object: nil)
        }
        urlComponent.queryItems = queryItems
        return urlComponent.url
    }
}

extension WebBrowser {

    func callbackEvent(name: String, params: Any) {
        func pushEvent() {
            let eventScript = jsCustomEventScript(name: "biz.util.page.openLink.callback",
                                                  arguments: ["name": name, "params": params])
            webView.evaluateJavaScript(eventScript)
        }

        if Thread.isMainThread {
            pushEvent()
        } else {
            DispatchQueue.main.async {
                pushEvent()
            }
        }
    }
}
