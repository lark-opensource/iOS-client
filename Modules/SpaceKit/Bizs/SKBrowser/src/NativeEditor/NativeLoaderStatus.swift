//
//  NativeLoaderStatus.swift
//  SKBrowser
//
//  Created by chenhuaguan on 2021/7/15.
//

import Foundation
import SKResource

public enum NativeLoaderStatus {
    case unknown
    case loading
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

    public var error: Error? {
        switch self {
        case .fail(error: let err): return err
        default: return nil
        }
    }

    public var errCode: Int? {
        guard isFail else { return nil }
        guard let currentErr = error else { return nil }
        if let urlErr = currentErr as? URLError {
            if urlErr.code == .cancelled {
                return nil
            } else {
                return urlErr.errorCode
            }
        }
        return nil
    }

    public var errorMsg: String? {
        guard isFail else { return nil }
        guard let currentErr = error else { return nil }
        var errMsg = BundleI18n.SKResource.Doc_Facade_LoadFailed
        if let urlErr = currentErr as? URLError {
            if urlErr.code == .cancelled {
                return nil
            } else {
                errMsg += "(\(urlErr.errorCode))"
            }
        }
        return errMsg
    }

    public var shouldReload: Bool {
        guard isFail else { return false }
        guard let currentErr = error else { return false }
        if let urlErr = currentErr as? URLError, urlErr.code == .unsupportedURL {
            return true
        }
        return false
    }
}

extension NativeLoaderStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .cancel: return "cancel"
        case .unknown:
            return "unknown"
        case .loading:
            return "loading"
        case .success:
            return "success"
        case .overtime:
            return "overtime"
        case .fail:
            return "fail:" + (errorMsg ?? "")
        }
    }
}
