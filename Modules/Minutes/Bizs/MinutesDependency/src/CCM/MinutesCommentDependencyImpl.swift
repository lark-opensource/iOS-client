//
//  MinutesCommentDependencyImpl.swift
//  MinutesMod
//
//  Created by yangyao on 2022/11/15.
//

import Foundation
import LarkContainer
import LarkContainer
import LKCommonsLogging
import Minutes
import SpaceInterface

public class MinutesCommentDependencyImpl: MinutesCommentDependency {
    public var docCommentModule: DocCommentModuleSDK?
    public var dependency: CCMCommentDependency?
    
    static let logger = Logger.log(MinutesCommentDependencyImpl.self, category: "Minutes")

    private let userResolver: UserResolver
    public init(resolver: UserResolver) {
        self.userResolver = resolver
    }
    
    deinit {
        Self.logger.info("CommentDependencyImpl deinit")
    }

    public func initCCMCommentModule(token: String, type: Int, permission: MinutesCommentPermissionType, translateLanguage: String?, delegate: CCMCommentDelegate?) {
        
        dependency = CCMCommentDependency(delegate: delegate, resolver: userResolver)
  
        let permissionType = CommentModulePermission(canComment: permission.canComment,
                                                     canResolve: permission.canResolve,
                                                     canShowMore: permission.canShowMore,
                                                     canShowVoice: permission.canShowVoice,
                                                     canReaction: permission.canReaction,
                                                     canCopy: permission.canCopy,
                                                     canDelete: permission.canDelete,
                                                     canTranslate: permission.canTranslate,
                                                     canDownload: permission.canDownload)
        
        var translateLan = CommentTranslateLang.en
        if let l = translateLanguage, let lan = CommentTranslateLang(rawValue: l) {
            translateLan = lan
        }
        
        let body = CommentModuleParamsBody(token: token, type: type,
                                           canOpenURL: true,
                                           canOpenProfile: false,
                                           translateLang: translateLan, translateMode: CommentModuleParamsBody.CommentTranslateMode.bothShow, permission: permissionType, dependency: dependency!)
        docCommentModule = try? userResolver.resolve(assert: DocCommentModuleSDK.self, argument: body)
        dependency?.docCommentModule = docCommentModule
    }
    
    public func updateTranslateLang(lan: String) {
        if let lan = CommentTranslateLang(rawValue: lan) {
            docCommentModule?.updateTranslateLang(translateLang: lan)
        }
    }
    
    public func fetchComment() {
        docCommentModule?.fetchComment()
    }
    
    public func showCommentCards(commentId: String, replyId: String?) {
        docCommentModule?.showCommentCards(body: CommentShowCardParamsBody(commentId: commentId, replyId: replyId))
    }
    
    public func showCommentInput(quote: String, tmpCommentId: String) {
        docCommentModule?.showCommentInput(body: CommentInputParamsBody(quote: quote, tmpCommentId: tmpCommentId))
    }
    
    public func setCommentMetadata(commentIds: [String]) {
        docCommentModule?.setCommentMetadata(body: CommentMetadataParamsBody(commentIds: commentIds))
    }

    public func dismiss() {
        docCommentModule?.dismiss()
    }
    
    public var isVisiable: Bool {
        docCommentModule?.isVisiable == true
    }
    
    public func updatePermission(permission: MinutesCommentPermissionType) {
        let permissionType = CommentModulePermission(canComment: permission.canComment,
                                                     canResolve: permission.canResolve,
                                                     canShowMore: permission.canShowMore,
                                                     canShowVoice: permission.canShowVoice,
                                                     canReaction: permission.canReaction,
                                                     canCopy: permission.canCopy,
                                                     canDelete: permission.canDelete,
                                                     canTranslate: permission.canTranslate,
                                                     canDownload: permission.canDownload)
        
        docCommentModule?.updatePermission(permission: permissionType)
    }
}
