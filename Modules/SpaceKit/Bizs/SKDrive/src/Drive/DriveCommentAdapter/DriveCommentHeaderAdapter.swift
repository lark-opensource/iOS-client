//
//  DriveCommentHeaderAdapter.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/3/25.
//  

import Foundation
import SKCommon
import SpaceInterface

extension DriveCommentAdapter: CommentHeaderOutlet {
    func didClickResolveButton(_ commentId: String, _ activeCommentID: String, response: @escaping (RNCommentData) -> Void) {
        guard permission.contains(.canResolve) else {
            return
        }
        rnCommentDataManager.updateComment(commentID: commentId,
                                           finish: true,
                                           response: response)
    }
    
    func didClickBackButton(_ commentContext: CommentAdaptContext) {
        isClickCommentVCBackButton = true
        disposeCommentViewController()
    }
    
    func didExitEditing(_ commentContext: CommentAdaptContext) {
        // 无需处理
    }
}
