//
//  PageOpenBridgeHandler.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/11/12.
//  


import Foundation
import BDXServiceCenter
import BDXBridgeKit
import EENavigator
import UIKit
import SKUIKit
import LarkUIKit

public final class PageOpenBridgeHandler: BridgeHandler {
    public typealias Interceptor = (URL, [String: Any], UIViewController) -> Bool
    static private var globalURLInterceptors: [String: Interceptor] = [:]
    
    public let methodName = "ccm.openPage"
    
    weak var currentPage: UIViewController?
    
    public let handler: BDXLynxBridgeHandler
    
    init(page: UIViewController?) {
        currentPage = page
        handler = { [weak page] (lynxView, _, params, callback) in
            guard let schema = params?["schema"] as? String, let page = page else {
                return
            }
            var prePage: UIViewController? = page
            let replace = params?["replace"] as? Bool ?? false
            if replace {
                if page.presentingViewController == nil {
                    prePage = page.navigationController
                } else {
                    prePage = page.presentingViewController
                }
            }
            guard let prePage = prePage else {
                return
            }
            var url = URL(string: schema)
            if url == nil, let urlStr = schema.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                url = URL(string: urlStr)
            }
            guard let url = url else {
                return
            }
            // 按 lynx 侧的数据定义解析出 contextID 和 initialProperties
            let shareContextID = params?["shareContextID"] as? String
            let initialProperties = params?["initialProperties"] as? [String: Any]
            let panelParams = params?["panelParam"] as? [String: Any]
            var context: [String: Any] = [
                SKLynxRouteHandler.kShareContextID: shareContextID,
                SKLynxRouteHandler.kInitialProperties: initialProperties,
                SKLynxRouteHandler.kPanelParams: panelParams,
                SKLynxRouteHandler.kPanelSourceView: lynxView as? UIView
            ]
            let useWebView: Bool = params?["useSysBrowser"] as? Bool ?? false
            let presentingPanel = panelParams != nil
            if !replace {
                Self.dismissComplete(url: url, from: prePage, useWebView: useWebView, context: context, presentingPanel: presentingPanel)
                return
            }
            if page.presentingViewController == nil {
                page.navigationController?.popViewController(animated: true, completion: {
                    Self.dismissComplete(url: url, from: prePage, useWebView: useWebView, context: context, presentingPanel: presentingPanel)
                })
            } else {
                page.dismiss(animated: true, completion: {
                    Self.dismissComplete(url: url, from: prePage, useWebView: useWebView, context: context, presentingPanel: presentingPanel)
                })
            }
        }
    }
    
    private static func dismissComplete(url: URL,
                                        from: UIViewController,
                                        useWebView: Bool,
                                        context: [String: Any],
                                        presentingPanel: Bool) {
        if Self.handleURL(url, topVC: from) {
            return
        }
        if useWebView {
            let webVC = WebViewController(url)
            Navigator.shared.push(webVC, from: from)
        } else {
            if from.navigationController != nil,
               !presentingPanel {
                Navigator.shared.docs.showDetailOrPush(url, context: context, wrap: LkNavigationController.self, from: from, forcePush: true)
            } else {
                Navigator.shared.present(url, context: context, from: from)
            }
        }
    }
    
    public static func register(key: String, interceptor: @escaping Interceptor) {
        globalURLInterceptors[key] = interceptor
    }
    
    private static func handleURL(_ url: URL, topVC: UIViewController?) -> Bool {
        guard let topVC = topVC, let queryItems = URLComponents(string: url.absoluteString)?.queryItems else { return false }
        var params: [String: Any] = [:]
        for item in queryItems {
            params[item.name] = item.value
        }
        for interceptor in globalURLInterceptors.values {
            if interceptor(url, params, topVC) {
                return true
            }
        }
        return false
    }
}

//extension UIApplication {
//    fileprivate func topViewController() -> UIViewController? {
//        let keyWindow = self.windows.first(where: { $0.isKeyWindow })
//
//        if var topController = keyWindow?.rootViewController {
//            while let presentedViewController = topController.presentedViewController {
//                topController = presentedViewController
//            }
//            return topController
//        }
//        return nil
//    }
//}

extension UINavigationController {
    func popViewController(animated: Bool, completion: @escaping () -> Void) {
        popViewController(animated: animated)

        if animated, let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { _ in
                completion()
            }
        } else {
            completion()
        }
    }
}
