//
//  GadgetShowCommentJSService.swift
//  SKCommon
//
//  Created by huayufan on 2021/7/6.
//  


import UIKit
import SKFoundation
import SpaceInterface
import SKCommon


class GadgetShowCommentJSService: JSServiceHandler, GadgetJSServiceHandlerType {
    static var handleServices: [DocsJSService] {
        return [.commentShowCards,
                .commentCloseCards,
                .updateCurrentUser]
    }
    
    var handleServices: [DocsJSService] {
        return Self.handleServices
    }
    
    public var gadgetJsBridges: [String] {
        return handleServices.map { $0.rawValue }
    }
    
    public static var gadgetJsBridges: [String] { Self.handleServices.map { $0.rawValue } }

    var gadgetInfo: DocsInfo?
    
    var dependency: CommentPluginDependency?
    
    weak var delegate: GadgetJSServiceHandlerDelegate?
    
    var commentService: GadgetCommentService?
    
    private var userUseOpenID = false
    
    required init(gadgetInfo: CommentDocsInfo, dependency: CommentPluginDependency, delegate: GadgetJSServiceHandlerDelegate) {
        self.gadgetInfo = gadgetInfo as? DocsInfo
        self.dependency = dependency
        self.delegate = delegate
        commentService = GadgetCommentService(docInfo: gadgetInfo,
                                              dependency: dependency,
                                              jsServiceHandler: self,
                                              delegate: delegate)
    }
    
    func fetchServiceInstance<H>(_ service: H.Type) -> H? where H: GadgetJSServiceHandlerType {
        return self.delegate?.fetchServiceInstance(token: gadgetInfo?.objToken, service)
    }
    
    func simulateJSMessage(_ msg: String, params: [String: Any]) {
        self.delegate?.simulateJSMessage(token: gadgetInfo?.objToken, msg, params: params)
    }
    
    public func handle(params: [String: Any], extra: [String: Any], serviceName: String, callback: GadgetCommentCallback) {
        let service = DocsJSService(serviceName)
        switch service {
        case .commentShowCards:
            SpaceTranslationCenter.standard.config = nil
            DispatchQueue.main.async {
               self.commentService?.showComment(params, session: self.delegate?.minaSession)
               self.commentService?.commentModule?.update(useOpenID: self.userUseOpenID)
            }
        case .commentCloseCards:
            commentService?.hideComment(false, animated: false, completion: nil)
        case .updateCurrentUser:
            commentService?.updateCurrentUser(params: params)
            userUseOpenID = (try? CommentUser(params: params))?.useOpenId ?? false
            commentService?.commentModule?.update(useOpenID: userUseOpenID)
        default:
            break
        }
        callback(.success(data: [:]))
    }
    
    func handle(params: [String: Any], serviceName: String) {
        
    }
    
    func gadegetSessionHasUpdate(minaSession: Any) {
        commentService?.commentModule?.updateSession(session: minaSession)
    }
}
