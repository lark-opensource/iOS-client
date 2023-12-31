//
//  SessionManager.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/8/13.
//

import Foundation

enum SessionType {
    case rustProxy
    case native
}

protocol SessionManager {
    var sessionType: SessionType { get }
    var session: URLSession { get }
}

class BaseSessionManager: SessionManager {

    static var httpUrlProtocols: [URLProtocol.Type]?

    var sessionType: SessionType {
        if self.remoteUseRustProxy {
            return .rustProxy
        } else {
            return .native
        }
    }

    var session: URLSession {
        switch self.sessionType {
        case .native:
            return self.nativeSession
        case .rustProxy:
            return self.rustSession
        }
    }

    public var nativeSession: URLSession {
        return BaseSessionManager.nativeSession
    }

    public var rustSession: URLSession {
        return BaseSessionManager.rustSession
    }

    private var remoteUseRustProxy: Bool {
        return PassportSwitch.shared.enablePassportRustHTTP && Self.httpUrlProtocols != nil
    }

    private static let rustSession: URLSession = {
        guard let classes = BaseSessionManager.httpUrlProtocols else {
            return nativeSession
        }
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.protocolClasses = classes
        return URLSession(configuration: configuration)
    }()

    private static let nativeSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        return URLSession(configuration: configuration)
    }()
}
