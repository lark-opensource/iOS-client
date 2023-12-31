//
//  CommentTeaService.swift
//  SKCommon
//
//  Created by huayufan on 2021/10/29.
//  


import SKFoundation
import SwiftyJSON
import SpaceInterface
import SKInfra

public final class CommentTeaService: BaseJSService, JSServiceHandler, GadgetJSServiceHandlerType {

    public static var handleServices: [DocsJSService] = [.commentReportToTea]
    
    public var gadgetJsBridges: [String] {
        return handleServices.map { $0.rawValue }
    }
    
    public var handleServices: [DocsJSService] {
        return Self.handleServices
    }
    
    public static var gadgetJsBridges: [String] { Self.handleServices.map { $0.rawValue } }
    
    public func handle(params: [String: Any], serviceName: String) {
        guard serviceName == DocsJSService.commentReportToTea.rawValue else {
            return
        }
        let json = JSON(params)
        guard let eventname = json["event_name"].string else {
            DocsLogger.error("CommentTeaService eventname is nil")
            return
        }
        var data = params["data"] as? [String: Any] ?? [:]
        if let info = model?.browserInfo.docsInfo {
            let token = info.wikiInfo?.objToken ?? info.objToken
            data["file_id"] = DocsTracker.encrypt(id: token)
            data["file_type"] = info.type.name
            let commentTracker = DocsContainer.shared.resolve(CommentTrackerInterface.self)
            let baseParametera = commentTracker?.baseParametera(docsInfo: info) ?? [:]
            data.merge(baseParametera) { (old, _) in old }
        }
        if json["noPrefix"].boolValue {
            DocsTracker.newLog(event: eventname, parameters: data)
        } else {
            DocsTracker.log(event: eventname, parameters: data)
        }
    }
    
    required public convenience init(gadgetInfo: CommentDocsInfo, dependency: CommentPluginDependency, delegate: GadgetJSServiceHandlerDelegate) {
        self.init()
    }
    
    public func handle(params: [String: Any], extra: [String: Any], serviceName: String, callback: GadgetCommentCallback) {
        callback(.success(data: [:]))
        self.handle(params: params, serviceName: serviceName)
    }
}
