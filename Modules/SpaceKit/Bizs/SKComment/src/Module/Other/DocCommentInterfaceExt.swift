//
//  DocCommentInterfaceExt.swift
//  SKCommon
//
//  Created by huayufan on 2022/11/17.
//  


import Foundation
import SpaceInterface
import SKUIKit
import SKCommon

extension CommentModulePermission {
    
    func toInnerPermission() -> CommentPermission {
        var commentPermission: CommentPermission = []
        if canResolve {
            commentPermission.insert(.canResolve)
        }
        if canComment {
            commentPermission.insert(.canComment)
        }
        if canCopy {
            commentPermission.insert(.canCopy)
        }
        if canShowMore {
            commentPermission.insert(.canShowMore)
        }
        if !canDelete {
            commentPermission.insert(.canNotDelete)
        }
        if canReaction {
            commentPermission.insert(.canReaction)
        }
        if canShowVoice {
            commentPermission.insert(.canShowVoice)
        }
        if canTranslate {
            commentPermission.insert(.canTranslate)
        }
        if canDownload {
            commentPermission.insert(.canDownload)
        }
        
        return commentPermission
    }
}

extension CommentKeyboardOptions.KeyboardEvent {
    
    static func convertKeyboardEvent(_ event: Keyboard.KeyboardEvent) -> CommentKeyboardOptions.KeyboardEvent? {
        switch event {
        case .willChangeFrame:
            return .willChangeFrame
        case .willShow:
            return .willShow
        case .didChangeFrame:
            return .didChangeFrame
        case .didShow:
            return .didShow
        case .willHide:
            return .willHide
        case .didHide:
            return .didHide
        case .didChangeInputMode:
            return nil
        @unknown default:
            return nil
        }
    }
}

extension RemoteCommentData {
    
    static func convert(from commentData: RNCommentData) -> RemoteCommentData {
        var diff: RemoteCommentData.DiffComment?
        if let diffComments = commentData.diffComments {
            diff = .init(addedComments: diffComments.addedComments,
                         deletedComments: diffComments.deletedComments,
                         updatedComments: diffComments.updatedComments,
                         resolveStatusChangedComments: diffComments.resolveStatusChangedComments)
        }
        let data = RemoteCommentData(commentData.comments,
                                     commentData.currentCommentID,
                                     commentData.code,
                                     commentData.msg,
                                     diff)
        return data
    }
}
