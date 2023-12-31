//
//  CommentOpenPluginHandler.swift
//  SKCommon
//
//  Created by huayufan on 2021/7/26.
//  


import SwiftyJSON
import SKFoundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import SpaceInterface
import SKCommon

protocol CommentOpenPluginHandlerDelegate: AnyObject {
    
    var handleServices: [String] { get }
    
    func handle(message: String, _ params: [String: Any], extra: [String: Any], callback: GadgetCommentCallback)
    
    func pluginBeginUpdateEntity(entity: OPPluginEntity)
    
    func pluginEndUpdateEntity(entity: OPPluginEntity)
    
    func update(context: OpenAPIContext)
    
    func enviromentTerminate()
    
    func updateSession(_ session: Any)
}

struct OPPluginEntity {
    var type: Int
    var token: String
    var appId: String?
    var callback: GadgetCommentCallback?
    weak var controller: UIViewController?
    
    init(type: Int,
         token: String,
         appId: String?,
         callback: GadgetCommentCallback, controller: UIViewController? = nil) {
        self.type = type
        self.token = token
        self.appId = appId
        self.controller = controller
        self.callback = callback
    }
}

class CommentOpenPluginHandler {

    var allServices: [String] {
        if let delegate = delegate {
            return delegate.handleServices
        }
        return []
    }
    
    weak var delegate: CommentOpenPluginHandlerDelegate?
    
    init(delegate: CommentOpenPluginHandlerDelegate) {
        self.delegate = delegate
    }
    
    func handle(context: OpenAPIContext, message: String, _ params: [String: Any], callback: GadgetCommentCallback) {
        let service = DocsJSService(message)
        guard checkInitStatus(context: context, service: service, params: params, callback: callback) else {
            return
        }
        delegate?.handle(message: message, params, extra: [:], callback: callback)
    }
    
    func checkInitStatus(context: OpenAPIContext, service: DocsJSService, params: [String: Any], callback: GadgetCommentCallback) -> Bool {
        if  service == .commentSetEntity ||
            service == .commentRemoveEntity ||
            service == .commentRequestNative {
            
            guard let contextService = HostAppBridge.shared.call(OpenContextService(context.additionalInfo)) as? DocsOPAPIContextProtocol,
                  let controller = contextService.controller else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setMonitorMessage("gadgetContext is nil")
                callback(.failure(error: error))
                return false
            }
            
            let json = JSON(params)
            let type = json["type"].intValue
            let token = json["token"].stringValue
            let appId = json["appId"].string
            let entity = OPPluginEntity(type: type, token: token, appId: appId, callback: callback, controller: controller)
            switch service {
            case .commentSetEntity, .commentRequestNative:
                delegate?.pluginBeginUpdateEntity(entity: entity)
            case .commentRemoveEntity:
                delegate?.pluginEndUpdateEntity(entity: entity)
                return false
            default:
                break
            }
        }
        return true
    }
    
    func update(context: OpenAPIContext) {
        self.delegate?.update(context: context)
    }
    
    func enviromentTerminate() {
        self.delegate?.enviromentTerminate()
    }
    
    func updateSession(_ session: Any) {
        self.delegate?.updateSession(session)
    }
}
