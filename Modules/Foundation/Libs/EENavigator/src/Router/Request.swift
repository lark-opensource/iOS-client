//
//  Request.swift
//  EENavigator
//
//  Created by liuwanlin on 2018/9/6.
//

import UIKit
import Foundation

/// the open behavior use model that confirm to Request-Respone. This class define the request behavior for the route.
public final class Request {
    /// Request url
    public private(set) var url: URL

    /// Context passed to request
    public var context: [String: Any]

    /// Parameters from query, path
    /// Priority: contenxt > matched parameters > query parameters
    public var parameters: [String: Any] {
        let matchedParameters = (context[ContextKeys.matchedParameters] as? [String: String]) ?? [:]
        let parameters = matchedParameters.merging(url.queryParameters, uniquingKeysWith: { mKey, _ in mKey })
        return context.merging(parameters, uniquingKeysWith: { ckey, _ in ckey })
    }

    /// Request body
    public var body: Body? {
        return parameters[ContextKeys.body] as? Body
    }

    public var from: NavigatorFrom {
        guard let from = self.context.from() else {
            /// context 中是一定会存在 from
//            assertionFailure()
            // 对于tab形式的路由可能不存在
            return Navigator.shared.mainSceneWindow ?? UIViewController()
        }
        return from
    }

    public init(url: URL, context: [String: Any]) {
        self.url = url
        self.context = context
    }

    func update(url: URL) {
        self.url = url
    }
}

extension Request {
    public var logInfo: String { url.logInfo }
}
