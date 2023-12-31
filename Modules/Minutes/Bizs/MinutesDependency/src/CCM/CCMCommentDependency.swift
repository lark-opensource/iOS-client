//
//  CCMCommentDependency.swift
//  MinutesMod
//
//  Created by yangyao on 2022/11/15.
//

import Foundation
import LKCommonsLogging
import LarkContainer
import Minutes
import SpaceInterface

public class CCMCommentDependency: DocCommentModuleDependency {
    static let logger = Logger.log(CCMCommentDependency.self, category: "Minutes")
    
    public weak var delegate: CCMCommentDelegate?
    public weak var docCommentModule: DocCommentModuleSDK?
    public var fullCommentIds: [String] = []
    
    private let userResolver: UserResolver
    
    public init(delegate: CCMCommentDelegate?, resolver: UserResolver) {
        self.delegate = delegate
        self.userResolver = resolver
    }
    
    public func openURL(url: URL) {
        
    }
    
    public func showUserProfile(userId: String) {
        let from = userResolver.navigator.mainSceneTopMost
        MinutesProfile.personProfile(chatterId: userId, from: from, resolver: userResolver)
    }

    public func didReceiveCommentData(commentData: RemoteCommentData, action: CommentModuleAction) {
    }

    public func didSwitchCard(commentId: String, height: CGFloat) {
        delegate?.didSwitchCard(commentId: commentId, height: height)
    }

    public func cancelComment(type: CommentModuleCancelType) {
        if case .close(let commentModuleUIType) = type {
            if case .inputView = commentModuleUIType {
                // 取消新增评论，在newInput之后
                delegate?.cancelComment(type: .closeNewInput)
            }
            if case .floatCard = commentModuleUIType {
                // 评论卡片关闭
                delegate?.cancelComment(type: .closeFloatCard)
            }
        }
        
        if case .newInput = type {
            // 取消新增评论
            delegate?.cancelComment(type: .cancelNewInput)
        }
    }
    
    public func keyboardChange(options: CommentKeyboardOptions, textViewHeight: CGFloat) {
        delegate?.keyboardChange(options: 1, textViewHeight: textViewHeight)
    }

    public var topViewController: UIViewController? {
        if let vc = delegate as? UIViewController {
            return vc
        }
        return nil
    }
}

extension Comment: CustomStringConvertible {
    public var description: String {
        return "commentId: \(commentID), commentUUID: \(commentUUID), quote: \(quote), finish: \(finish), finishUserID: \(finishUserID), finishUserName: \(finishUserName), parentToken: \(parentToken), parentType: \(parentType), isWhole: \(isWhole), commentList: \(commentList), isUnsummit: \(isUnsummit), bizParams: \(bizParams), position: \(position), isNewInput: \(isNewInput), isActive: \(isActive), interactionType: \(interactionType), isFirstResponser: \(isFirstResponser), permission: \(permission)"
    }
}
