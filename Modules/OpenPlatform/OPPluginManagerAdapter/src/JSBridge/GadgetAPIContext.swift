//
//  GadgetAPIContext.swift
//  OPPluginManagerAdapter
//
//  Created by lixiaorui on 2021/3/23.
//

import Foundation
import OPSDK
import LKCommonsLogging
import LarkOpenAPIModel
import LarkOpenPluginManager

// 等待后期新架构完成之后，可换成新容器的context
public final class GadgetAPIContext: NSObject, OPAPIContextProtocol {

    static public let logger = Logger.log(GadgetAPIContext.self, category: "OpenAPI")

    public let pluginContext: BDPPluginContext
    //与容器保持一致：uniqueID的生命周期>engine的生命周期，即engien释放后，uniqueID仍可访问
    public let uniqueID: OPAppUniqueID

    public init(with pluginContext: BDPPluginContext) {
        self.pluginContext = pluginContext
        if let engine = pluginContext.engine {
            self.uniqueID = engine.uniqueID
        } else {
            assertionFailure("gadget context engine is nil")
            Self.logger.error("gadget context engine is nil, can not get uniqueID")
            self.uniqueID = OPAppUniqueID(appID: "", identifier: "", versionType: .current, appType: .unknown)
        }
        super.init()
    }

    @available(*, deprecated, message: "Use GadgetSessionPlugin instead")
    public var session: String {
        guard let auth = BDPModuleManager(of: uniqueID.appType).resolveModule(with: BDPAuthModuleProtocol.self) as? BDPAuthModuleProtocol, let session = auth.getSessionContext(pluginContext) else {
            Self.logger.error("can not get session for app \(uniqueID)")
            return ""
        }
        return session
    }

    public var controller: UIViewController? {
        var controller =  pluginContext.controller as? UIViewController
        if controller == nil {
            // fg打开，context上不会每次都从engine上读取controller挂在context上，为需要时从context的engine里面拿controller（其中engine读controller是同步操作）
            controller = (pluginContext.engine as? BDPEngineProtocol & BDPJSBridgeEngineProtocol)?.bridgeController as? UIViewController
        }
        return controller
    }
    
    public func getControllerElseFailure<Result>(_ trace: OPTrace, _ callback: (OpenAPIBaseResponse<Result>) -> Void) -> UIViewController?
    where Result: OpenAPIBaseResult {
        guard let controller = self.controller else {
            trace.error("gadgetContext.controller nil? YES")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("gadgetContext.controller nil").setErrno(OpenAPICommonErrno.internalError)
            callback(.failure(error: error))
            return nil
        }
        return controller
    }

    public func fireEvent(event: String, sourceID: Int, data: [AnyHashable: Any]?) -> Bool {
        guard let engine = pluginContext.engine else {
            assertionFailure("gadget context engine is nil")
            Self.logger.error("gadget context engine is nil, can not fire event")
            return false
        }
        if let contextWorkerEngine = pluginContext.workerEngine, let workerEngine = contextWorkerEngine {
            workerEngine.bdp_fireEvent(event, sourceID: sourceID, data: data)
        } else {
            engine.bdp_fireEvent(event, sourceID: sourceID, data: data)
        }

        return true
    }

    // TODO: BDPAuthorization refactor
    public var authorization: BDPAuthorization? {
        guard let engine = pluginContext.engine else {
            assertionFailure("gadget context engine is nil")
            Self.logger.error("gadget context engine is nil, can not resolve authorization")
            return nil
        }
        return engine.authorization as? BDPAuthorization
    }
    
    public func handlerCallback(pluginCallBlock: (@escaping BDPJSBridgeCallback, BDPPluginContext) -> Void, callback: @escaping BDPJSBridgeCallback) {
        pluginCallBlock(callback, pluginContext)
    }
    
    public func exportHandlerCallback(pluginCallBlock: (@escaping BDPJSBridgeCallback, BDPJSBridgeEngine, UIViewController?) -> Void, callback: @escaping BDPJSBridgeCallback) {
        guard let engine = pluginContext.engine as? NSObject & BDPJSBridgeEngineProtocol,
              let proxyEngine = engine.bdp_weakProxy as? BDPJSBridgeEngineProtocol else {
            callback(.failed, nil)
            return
        }
        pluginCallBlock(callback, proxyEngine, self.controller)
    }
}

