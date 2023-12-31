//
//  WALoadStatus.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/27.
//

import Foundation

public enum WALoadStatus {
    public enum LoadingState {
        case preload
        case render
        case loadUrl
    }
    case start
    case loading(LoadingState)
    case success
    case cancel
    case overtime
    case error(WALoadError)
    
    public var isLoading: Bool {
        switch self {
        case .loading: return true
        default: return false
        }
    }
    
    public var isError: Bool {
        switch self {
        case .error(_): return true
        default: return false
        }
    }
    
    public var isPreloading: Bool {
        switch self {
        case .loading(let state):
            if state == .preload {
                return true
            }
        default: return false
        }
        return false
    }
    
    public var isFinish: Bool {
        switch self {
        case .cancel, .overtime, .success, .error(_):
            return true
        default:
            return false
        }
    }
}

extension WALoadStatus: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs)  {
        case (.start, .start),
            (.success, .success),
            (.cancel, .cancel),
            (.overtime, .overtime):
            return true
        case (.error(_), .error(_)):
            return false
        default:
            return false
        }
    }
}

enum LoadType: String {
    case online
    case offline
}

enum WAPreloadStatus {
    case none
    case checkPkg
    case loading
    case complete
    case fail
    
    var isReady: Bool {
        self == .complete
    }
    
    var isFail: Bool {
        self == .fail
    }
    
    var isLoading: Bool {
        self == .loading || self == .checkPkg
    }
}
