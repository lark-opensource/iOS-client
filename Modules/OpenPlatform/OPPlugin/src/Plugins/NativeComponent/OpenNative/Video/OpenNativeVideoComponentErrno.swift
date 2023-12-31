//
//  OpenNativeVideoComponentErrno.swift
//  OPPlugin
//
//  Created by zhujingcheng on 2/14/23.
//

import Foundation
import LarkWebviewNativeComponent

protocol OpenNativeVideoErrnoProtocol: OpenNativeComponentErrnoProtocol {}

extension OpenNativeVideoErrnoProtocol {
    var componentDomain: OpenNativeComponentType { .video }
}

enum OpenNativeVideoErrno: OpenNativeVideoErrnoProtocol {
    var apiDomain: OpenNativeAPIDomain {
        switch self {
        case .commonInternalError:
            return .common
        case .insertInternalError:
            return .insert
        case .updateInternalError:
            return .update
        case .dispatchAction(let err):
            return err.apiDomain
        case .fireEvent(let err):
            return err.apiDomain
        }
    }
    
    var rawValue: Int {
        switch self {
        case .commonInternalError, .insertInternalError, .updateInternalError:
            return 00
        case .dispatchAction(let err):
            return err.rawValue
        case .fireEvent(let err):
            return err.rawValue
        }
    }
    
    var errString: String {
        switch self {
        case .commonInternalError, .insertInternalError, .updateInternalError:
            return "Internal Error"
        case .dispatchAction(let err):
            return err.errString
        case .fireEvent(let err):
            return err.errString
        }
    }
    
    case commonInternalError
    case insertInternalError
    case updateInternalError
    case dispatchAction(_ err: OpenNativeVideoDispatchActionErrno)
    case fireEvent(_ err: OpenNativeVideoFireEventErrno)
}

enum OpenNativeVideoDispatchActionErrno: OpenNativeVideoErrnoProtocol {
    var apiDomain: OpenNativeAPIDomain { .dispatchAction }
    
    case internalError
    
    var rawValue: Int {
        switch self {
        case .internalError:
            return 00
        }
    }
    
    var errString: String {
        switch self {
        case .internalError:
            return "Internal Error"
        }
    }
}

enum OpenNativeVideoFireEventErrno: OpenNativeVideoErrnoProtocol {
    var apiDomain: OpenNativeAPIDomain { .fireEvent }
    
    case internalError
    case videoSrcInvalid
    case videoRequestFailed
    case videoDnsLookupFailed
    case videoEngineError
    case videoNetworkError
    
    var rawValue: Int {
        switch self {
        case .internalError:
            return 00
        case .videoSrcInvalid:
            return 01
        case .videoRequestFailed:
            return 02
        case .videoDnsLookupFailed:
            return 03
        case .videoEngineError:
            return 04
        case .videoNetworkError:
            return 05
        }
    }
    
    var errString: String {
        switch self {
        case .internalError:
            return "Internal Error"
        case .videoSrcInvalid:
            return "Unable to play. Video src is invalid"
        case .videoRequestFailed:
            return "Unable to play. Video src request failed"
        case .videoDnsLookupFailed:
            return "Unable to play. DNS lookup failed"
        case .videoEngineError:
            return "Unable to play. Video engine error"
        case .videoNetworkError:
            return "Unable to play. Network error"
        }
    }
}
