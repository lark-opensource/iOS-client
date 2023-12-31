//
//  MsgCardAPIUtils.swift
//  LarkMessageCard
//
//  Created by ByteDance on 2023/1/6.
//

import Foundation
import LarkOpenAPIModel
import EENavigator
import LarkNavigator
import Lynx

public class MsgCardAPIUtils {
    
    public static func sourceVC(context: OpenAPIContext) -> UIViewController? {
        if let msgContext = context.additionalInfo["msgContext"] as? MessageCardLynxContext, let bizContext = msgContext.bizContext as? MessageCardContainer.Context, let sourceVC = bizContext.dependency?.sourceVC {
            return sourceVC
        }
        return nil
    }
    
    public static func presentController(vc: UIViewController, context: OpenAPIContext) {
        let fromVC = Self.sourceVC(context: context)
        if let fromVC = fromVC {
            Navigator.shared.present(vc, wrap: nil, from: fromVC, prepare: { controller in
                #if canImport(CryptoKit)
                if #available(iOS 13.0, *) {
                    if controller.modalPresentationStyle == .automatic {
                        controller.modalPresentationStyle = .fullScreen
                    }
                }
                #endif
            })
        } else {
            context.apiTrace.error("presentController fail, fromVC is nil")
        }
    }
    
    /// 为popover外接矩形增加padding
    public static func sourceRectWithPadding(for originSourceRect: CGRect) -> CGRect {
        return originSourceRect.inset(by: UIEdgeInsets(edges: -4))
    }
    
    public static func getLynxView(context: OpenAPIContext) -> LynxView? {
        if let msgContext = context.additionalInfo["msgContext"] as? MessageCardLynxContext, let lynxContext = msgContext.lynxContext as? LynxContext, let lynxView = lynxContext.getLynxView() {
            return lynxView
        }
        return nil
    }
}

extension LynxView {
    enum EventName: String {
        case updateCardState
    }
    
    struct ParamKey {
        static let elementID = "elementID"
        static let eventName = "eventName"
        static let params = "params"
    }
    
    func updateCardState(elementID: String, eventName: String, params: [String: String]?) {
        var dict: [String: Any] = [
            ParamKey.elementID: elementID,
            ParamKey.eventName: eventName
        ]
        if let params = params {
            dict[ParamKey.params] = params
        }
        sendGlobalEvent(EventName.updateCardState.rawValue, withParams: [dict])
    }
}
