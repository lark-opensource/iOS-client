//
//  LoaderDefine.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/3/29.
//  

import Foundation
import SKResource
import SKFoundation

//https://bytedance.feishu.cn/space/doc/doccnXXTqP1BoMlqbbvzHl
public enum LoadStatus {
    public enum LoadingStage {
        case start(url: URL, isPreload: Bool)
        case preloadOk
        case renderCachStart
        case renderCacheSuccess
        case renderCalled
        case afterReadLocalClientVar
        case beforeReadLocalHtmlCache
        
        public var descriptionInLog: String {
            switch self {
            case .start(url: _, isPreload: let isPrelaod):
                return "start, ispreload: \(isPrelaod)"
            default:
                return String(describing: self)
            }
        }
    }
    case unknown
    case loading(LoadingStage)
    case cancel
    case success
    case overtime
    case fail(error: Error?)
    
    public var isLoading: Bool {
        switch self {
        case .loading: return true
        default: return false
        }
    }
    
    public var isSuccess: Bool {
        switch self {
        case .success: return true
        default: return false
        }
    }
    
    public var isFail: Bool {
        switch self {
        case .fail: return true
        default: return false
        }
    }
    
    public var isOvertime: Bool {
        switch self {
        case .overtime: return true
        default: return false
        }
    }
    
    /// 是否可以继续响应
    public var canContinue: Bool {
        switch self {
        case .overtime, .fail: return false //超时或失败后，不能响应后面的事件了
        default: return true
        }
    }

    public var error: Error? {
        switch self {
        case .fail(error: let err): return err
        default: return nil
        }
    }

    public var errCode: Int? {
        guard isFail else { return nil }
        guard let currentErr = error else { return nil }
        if (currentErr as NSError).domain == LoaderErrorDomain.failEventFromH5 {
            return (currentErr as NSError).code
        } else if let urlErr = currentErr as? URLError {
            if urlErr.code == .cancelled {
                return nil
            } else {
                return urlErr.errorCode
            }
        } else if (currentErr as NSError).domain == LoaderErrorDomain.getWikiToken {
            return (currentErr as NSError).code
        }
        return nil
    }

    public var errorMsg: String? {
        guard isFail else { return nil }
        guard let currentErr = error else { return nil }
        var errMsg = BundleI18n.SKResource.LarkCCM_Docs_LoadError_Mob()
        if let urlErr = currentErr as? URLError {
            if urlErr.code == .cancelled {
                return nil
            }
        } else if (currentErr as NSError).domain == LoaderErrorDomain.getWikiToken {
            let err = (currentErr as NSError)
            if err.code == LoaderErrorCode.wikiTokenNetError.rawValue {
                errMsg = BundleI18n.SKResource.Doc_Facade_NetworkInterrutedRetry
            } else if err.code == LoaderErrorCode.wikiTokenOtherError.rawValue {
                errMsg = BundleI18n.SKResource.Doc_Doc_GetWikiInfoOtherErr
            } else if err.code == LoaderErrorCode.wikiTokenNotExist.rawValue {
                errMsg = BundleI18n.SKResource.Doc_Doc_GetWikiInfoNotExists
            }
        }
        return errMsg
    }
    public var newCodeFromMsg: String? {
        guard isFail else { return nil }
        guard let currentErr = error else { return nil }
        var code: String?
        if (currentErr as NSError).domain == LoaderErrorDomain.failEventFromH5 {
            code = "\((currentErr as NSError).code)"
        } else if let urlErr = currentErr as? URLError {
            if urlErr.code == .cancelled {
                return nil
            } else {
                code = "\(urlErr.errorCode)"
            }
        } else if (currentErr as NSError).domain == LoaderErrorDomain.getWikiToken {
            let err = (currentErr as NSError)
            if err.code == LoaderErrorCode.wikiTokenNetError.rawValue {
                code = "\(err.code)"
            } else if err.code == LoaderErrorCode.wikiTokenOtherError.rawValue {
                code = "\(err.code)"
            } else if err.code == LoaderErrorCode.wikiTokenNotExist.rawValue {
                code = "\(err.code)"
            }
        }
        return code
    }

    public var shouldReload: Bool {
        guard isFail else { return false }
        guard let currentErr = error else { return false }
        if let urlErr = currentErr as? URLError, urlErr.code == .unsupportedURL {
            return true
        }
        return false
    }

    // webview 的原因引发的错误
    public var errorIsFromWebview: Bool {
        guard isFail else { return false }
        guard let currentErr = error else { return false }
        if let urlErr = currentErr as? URLError, urlErr.code != .cancelled {
            return true
        }
        return false
    }

    //url 不要在日志里
    public var descriptionInLog: String {
        switch self {
        case .loading(let stage):
            return "loading:" + stage.descriptionInLog
        case .fail:
            return "fail:" + (errorMsg ?? "")
        default:
            return String(describing: self)
        }
    }
}

extension LoadStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .cancel: return "cancel"
        case .unknown:
            return "unknown"
        case .loading(let stage):
            return "loading:" + stage.descriptionInLog
        case .success:
            return "success"
        case .overtime:
            return "overtime"
        case .fail:
            return "fail:" + (errorMsg ?? "")
        }
    }
}

public struct LoaderErrorDomain {
    public static let failEventFromH5 = "failEventFromH5"
    public static let getWikiToken = "getWikiTokenError"
    public static let failEventRender = "failEventRender"
    public static let getSyncedBlockParent = "getSyncedBlockParentTokenError"
}

//https://bytedance.feishu.cn/space/doc/AoUDEV1B4gA0QNX3GR1Jpd#9pSVds
public enum LoaderErrorCode: Int {
    case overtime = -50
    case tokenError = -51
    case syncCookieError = -52
    case wikiTokenNetError = -60
    case wikiTokenOtherError = -61
    case wikiTokenNotExist = -62
    case syncedBlockParentTokenError = -70
    case noNet = -1
    case netOverTime = -2
    case unKnownNetError = -3

    //
    //urlError: (-900, -1250] iOS webview
}
