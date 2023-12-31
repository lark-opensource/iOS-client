//
//  WABridgeHandler.swift
//  WebAppBridge
//
//  Created by lijuyou on 2023/10/30.
//

import Foundation
import LarkWebViewContainer
import LKCommonsLogging

public protocol WABridgeHandler {
    var name: WABridgeName { get }
    
    func handle(invocation: WABridgeInvocation)
    
    func transform<T: Decodable>(_ params: [String: Any]) -> T?
}

extension WABridgeHandler {
    public func transform<T: Decodable>(_ params: [String: Any]) -> T? {
        let decoder = JSONDecoder()
        do {
            let data = try JSONSerialization.data(withJSONObject: params, options: [])
            let model = try decoder.decode(T.self, from: data)
            return model
        } catch {
            WALogger.logger.error("transform params err", error: error)
            return nil
        }
    }
}

open class WABaseBridgeHandler: WABridgeHandler {
    
    public static let logger = LKCommonsLogging.Logger.log(WABridgeHandler.self, category: WALogger.TAG)
    public let name: WABridgeName
    public weak var service: WABridgeService?
        
    public init(service: WABridgeService, name: WABridgeName) {
        self.name = name
        self.service = service
    }
    
    public func handle(invocation: WABridgeInvocation) {
        assertionFailure()
    }
}
