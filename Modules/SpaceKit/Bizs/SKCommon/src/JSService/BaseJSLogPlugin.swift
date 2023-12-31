//
//  BaseJSLogPlugin.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/3/15.
//  

import SpaceInterface

public protocol SKBaseLogPluginProtocol: AnyObject {
    func didReceiveLog(_ msg: String)
}

public final class SKBaseLogPlugin: JSServiceHandler, GadgetJSServiceHandlerType {
    
    public static var handleServices: [DocsJSService] = [.utilLogger]
    
    public var handleServices: [DocsJSService] {
        return Self.handleServices
    }

    public var gadgetJsBridges: [String] {
        return handleServices.map { $0.rawValue }
    }
    
    public static var gadgetJsBridges: [String] { Self.handleServices.map { $0.rawValue } }
    
    public var logPrefix: String = ""
    public weak var pluginProtocol: SKBaseLogPluginProtocol?
    public func handle(params: [String: Any], serviceName: String) {
        guard serviceName == DocsJSService.utilLogger.rawValue else {
            return
        }
        guard let message = params["logMessage"] as? String else {
            return
        }
        if pluginProtocol != nil {
            pluginProtocol?.didReceiveLog(message)
        } else {
            skInfo(logPrefix + message)
        }
    }
    
    public init() {
        
    }
    
    required public convenience init(gadgetInfo: CommentDocsInfo, dependency: CommentPluginDependency, delegate: GadgetJSServiceHandlerDelegate) {
        self.init()
    }
    
    public func handle(params: [String: Any], extra: [String: Any], serviceName: String, callback: GadgetCommentCallback) {
        callback(.success(data: [:]))
        self.handle(params: params, serviceName: serviceName)
    }
}
