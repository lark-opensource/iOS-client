import Foundation
import WebBrowser
import Swinject
import LKCommonsLogging
import LarkContainer

private let LKWebViewControllerAPILogger = Logger.log(WebBrowser.self, category: "WebBrowser")

extension WebBrowser {

    func jsCustomEventScript(name: String, arguments: [String: Any]) -> String {
        if let argsData = try? JSONSerialization.data(withJSONObject: arguments),
            let argsString = String(data: argsData, encoding: .utf8) {
            /** 不能采用下述方式，会导致定义的event变量覆盖了window.event对象
            let script = "var event = new CustomEvent('\(name)',"
                + "{ 'detail': \(argsString) });"
                + "document.dispatchEvent(event);"
            */
            let script = "document.dispatchEvent(new CustomEvent('\(name)', { 'detail': \(argsString) }));"
            return script.lu.transformToExecutableScript()
        } else {
            return ""
        }
    }

    func hasPermission(url: URL, resolver: Resolver) -> Bool {
        guard let reqUrlDomain = url.host else {
                return false
        }

        let secLinkWhitelist = JsSDKDependencyImpl().secLinkWhitelist

        let range = NSRange(location: 0, length: reqUrlDomain.count)
        let matchPattern: String? = secLinkWhitelist.first(where: {
            if let regExp = try? NSRegularExpression(pattern: $0) {
                return (regExp.firstMatch(in: reqUrlDomain, range: range) != nil)
            }
            return false
        })
        return (matchPattern != nil)
    }
}

class CheckPermissionJsAPIHandler {
    static let logger = Logger.log(CheckPermissionJsAPIHandler.self)
    /// enable whitelist check
    var needCheckPermission: Bool { true }

    let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    func validatedHandle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        assertionFailure("need be overrided")
    }
}

extension CheckPermissionJsAPIHandler: JsAPIHandler {

    /// disable JSSDK default authrization
    var needAuthrized: Bool { false }

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        if needCheckPermission {
            if let url = api.webView.url, api.hasPermission(url: url, resolver: resolver) {
                validatedHandle(args: args, api: api, sdk: sdk, callback: callback)
            } else {
                CheckPermissionJsAPIHandler.logger.error("request url not in the whteList, url = \(String(describing: api.webView.url))")
                return
            }
        } else {
            validatedHandle(args: args, api: api, sdk: sdk, callback: callback)
        }
    }
}
