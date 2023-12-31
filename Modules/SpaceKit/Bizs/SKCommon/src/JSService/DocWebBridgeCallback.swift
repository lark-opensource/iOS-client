//
//  DocWebBridgeCallback.swift
//  SKCommon
//
//  Created by huayufan on 2021/7/18.
//

import LarkWebViewContainer
import SpaceInterface


public enum DocWebBridgeCallback {
    
    case lark(APICallbackProtocol)
    
    case gadget(GadgetCommentCallback)
}

extension DocWebBridgeCallback {
    
    public func callFunction(action: CommentEventListenerAction?, params: [String: Any]?) {
        var pa = params ?? [:]
        if let actionRawValue = action?.rawValue {
            pa["action"] = actionRawValue
        }
        switch self {
        case .lark(let callback):
            callback.callbackSuccess(param: pa)
        case .gadget(let callback):
            callback(.success(data: pa))
        }
    }
}
