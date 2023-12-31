//
//  SKLynxRouteHandler.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/11/8.
//

import Foundation
import EENavigator
import SKFoundation
import UniverseDesignColor

public extension SKLynxRouteHandler {
    struct PanelParams {
        let style: UIModalPresentationStyle
        let sourceRect: CGRect
        let estimateHeight: Double?

        init?(params: [String: Any]?) {
            guard let params else {
                return nil
            }
            guard let styleValue = params["panelStyle"] as? String else {
                DocsLogger.error("panel style not founc in panelParams")
                return nil
            }
            if styleValue == "formSheet" {
                style = .formSheet
            } else if styleValue == "popover" {
                style = .popover
            } else {
                DocsLogger.error("unknown panel style: \(styleValue)")
                return nil
            }
            guard let sourceRectInfo = params["sourceRect"] as? [String: Double],
            let sourceX = sourceRectInfo["x"],
            let sourceY = sourceRectInfo["y"],
            let width = sourceRectInfo["width"],
            let height = sourceRectInfo["height"] else {
                DocsLogger.error("invalid panel source rect info: \(params["sourceRect"])")
                return nil
            }
            sourceRect = CGRect(x: sourceX, y: sourceY, width: width, height: height)
            estimateHeight = params["estimateHeight"] as? Double
        }
    }
}

public enum SKLynxRouteHandler {

    public static var kShareContextID: String { "_ccm_lynx_route_share_context_id" }
    public static var kInitialProperties: String { "_ccm_lynx_route_initial_properties" }
    public static var kPanelParams: String { "_ccm_lynx_route_panel_params" }
    public static var kPanelSourceView: String { "_ccm_lynx_route_panel_source_view" }

    static func handle(request: EENavigator.Request, response: Response) {
        let controller = createController(request: request)
        response.end(resource: controller)
    }

    static func createController(request: EENavigator.Request) -> UIViewController {
        let queryParams = request.url.queryParameters
        var cardPath = request.url.path
        // path 带有一个前导 /, 需要去掉
        cardPath.removeFirst()
        let shareContextID = request.context[Self.kShareContextID] as? String
        var initialProperties = request.context[Self.kInitialProperties] as? [String: Any] ?? [:]
        // 将 query 参数带入 initialProperties，优先使用 context 中的值
        initialProperties.merge(queryParams) { contextValue, _ in
            return contextValue
        }

        let config = SKLynxConfig(cardPath: cardPath, initialProperties: initialProperties, shareContextID: shareContextID)
        guard let panelParams = PanelParams(params: request.context[Self.kPanelParams] as? [String: Any]) else {
            return defaultLynxController(config: config)
        }
        let controller: SKLynxPanelController
        if panelParams.style == .popover {
            guard let sourceView = request.context[Self.kPanelSourceView] as? UIView else {
                DocsLogger.error("panel source view not found in context")
                return defaultLynxController(config: config)
            }
            controller = SKLynxPanelController(config: config)
            controller.modalPresentationStyle = panelParams.style
            controller.transitioningDelegate = controller.panelTransitioningDelegate
            controller.popoverPresentationController?.backgroundColor = UDColor.bgFloat
            controller.popoverPresentationController?.permittedArrowDirections = .right
            controller.popoverPresentationController?.sourceView = sourceView
            controller.popoverPresentationController?.sourceRect = panelParams.sourceRect
        } else {
            controller = SKLynxPanelController(config: config)
            controller.modalPresentationStyle = panelParams.style
            controller.transitioningDelegate = controller.panelFormSheetTransitioningDelegate
        }

        controller.presentationController?.delegate = controller.adaptivePresentationDelegate
        controller.estimateHeight = panelParams.estimateHeight
        if let fromVC = request.from.fromViewController {
            controller.supportOrientations = fromVC.supportedInterfaceOrientations
        }
        return controller
    }

    private static func defaultLynxController(config: SKLynxConfig) -> SKLynxViewController {
        SKLynxViewController(config: config)
    }
}
