//
//  OpenNativeComponentError.swift
//  LarkWebviewNativeComponent
//
//  Created by yi on 2021/9/23.
//
// 错误文档：https://bytedance.feishu.cn/docs/doccnqzA4QmhVZizFpiFdcHquCb

import Foundation
import LarkOpenAPIModel

public protocol OpenNativeComponentErrorProtocol {

    var innerCode: Int { get }
    var innerErrorMsg: String? { get }
}


extension OpenNativeComponentErrorProtocol {
    public var innerErrorMsg: String? {
        return ""
    }
}

/// Bridge处的error
public enum OpenNativeComponentBridgeError: Int, OpenNativeComponentErrorProtocol {
    case noHandler = 2000301
    public var innerCode: Int {
        return self.rawValue
    }
    public var innerErrorMsg: String? {
        switch self {
        case .noHandler:
            return "message not register"
        }
    }
}

public enum OpenNativeComponentMessageError: Int, OpenNativeComponentErrorProtocol {
    case noBridge = 2000401
    public var innerCode: Int {
        return self.rawValue
    }
    public var innerErrorMsg: String? {
        switch self {
        case .noBridge:
            return "bridge is nil"
        }
    }
}

public enum OpenNativeComponentBridgeAPIError: Int, OpenNativeComponentErrorProtocol {
    case noWebView = 2000201
    case noComponentManager = 2000202
    case initComponentError = 2000203
    case noRender = 2000204
    case bizError = 2000205
    case insertRenderError = 2000206
    case reRenderError = 2000207
    case insertComponentExist = 2000208
    case reRenderInsertError = 2000209
    case noTypeOrIDParams = 2000211
    case updateComponentFail = 2000221
    case removeComponentFail = 2000231
    case reRenderNoNativeView = 2000241
    case reRenderNoComponent = 2000242
    case dispatchActionNoComponent = 2000251
    case insertRenderSyncError = 2000261
    case noSyncManagerError = 2000262
    case noComponentWrapper = 2000263
    public var innerCode: Int {
        return self.rawValue
    }
    public var innerErrorMsg: String? {
        switch self {
        case .noWebView:
            return "can not find webview"
        case .noComponentManager:
            return "can not find component manager"
        case .noTypeOrIDParams:
            return "renderID or type is nil"
        case .removeComponentFail:
            return "removeComponent fail"
        case .updateComponentFail:
            return "update component fail"
        case .initComponentError:
            return "init component error"
        case .noRender:
            return "can not find render"
        case .bizError:
            return "biz error, can not get component view"
        case .insertRenderError:
            return "insert render error"
        case .reRenderError:
            return "rerender error"
        case .insertComponentExist:
            return "insert component exist"
        case .reRenderInsertError:
            return "rerender insert error"
        case .reRenderNoNativeView:
            return "reRender error, no native view"
        case .reRenderNoComponent:
            return "reRender error, no component"
        case .dispatchActionNoComponent:
            return "dispatch error, no component"
        case .insertRenderSyncError:
            return "sync insert render error"
        case .noSyncManagerError:
            return "can not find sync manager"
        case .noComponentWrapper:
            return "can not find component wrapper"
        }
    }
}
