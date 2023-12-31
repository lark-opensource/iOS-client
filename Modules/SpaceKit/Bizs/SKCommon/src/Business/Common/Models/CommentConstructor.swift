//
//  CommentConstructor.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/4/15.
//

import Foundation
import SwiftyJSON
import SKFoundation
import SpaceInterface

public final class CommentConstructor {
    typealias RawComment = [String: Any]

    // key = CommentPermission.rawValue
    public typealias PermissionSetting = [Int: Bool]

    public static func constructCommentData(_ params: [String: Any],
                                            docsInfo: DocsInfo?,
                                            chatID: String? = nil) -> CommentData? {
        let setting: PermissionSetting = [CommentPermission.canDownload.rawValue: true,
                                          CommentPermission.disableImgPreview.rawValue: false]
        return constructCommentData(params,
                                    docsInfo: docsInfo,
                                    permissionSetting: setting,
                                    canManageDocs: true,
                                    canEdit: true,
                                    chatID: chatID)
    }
    
    /// canManageDocs 为nil表示不走doc评论权限处理逻辑, 小程序场景
    // swiftlint:disable cyclomatic_complexity
    public static func constructCommentData(_ params: [String: Any],
                                            docsInfo: DocsInfo?,
                                            permissionSetting: PermissionSetting = [:],
                                            canManageDocs: Bool?,
                                            canEdit: Bool?,
                                            chatID: String? = nil) -> CommentData? {

        guard let fileToken = params["token"] as? String else {
            //spaceAssertionFailure("评论缺失参数")
            return nil
        }
        let currentToken = docsInfo?.token ?? ""
        if fileToken != currentToken {
            DocsLogger.error("oops! token not compatible curToken:\(currentToken.encryptToken) commentToken:\(fileToken.encryptToken)")
        }


        var commentType: CommentData.CommentType = .card
        var rawComments: [RawComment] = [[:]]

        // 根据参数获取是卡片评论还是全文评论
        if let cards = params["cards"] as? [RawComment] {
            rawComments = cards
            commentType = .card
        } else if let globalComments = params["global_comments"] as? RawComment,
            let commentList = globalComments["comment_list"] as? [Any] { // 全文评论只有一种类型，所以不是数组
            if !commentList.isEmpty {
                rawComments = [globalComments]
            }
            commentType = .full
        } else {
            spaceAssertionFailure("缺少评论数据")
            return nil
        }

        // 不知道这里为什么要替换 token ...
        docsInfo?.objToken = fileToken
        var isInDocs = true
        if let info = docsInfo, info.appId != nil {
            isInDocs = false
        }
        let isInVideoConference = docsInfo?.isInVideoConference ?? false
        let commentPermission = self.constructorPermission(params: params,
                                                           isInDocs: isInDocs,
                                                           isInVC: isInVideoConference,
                                                           permissionSetting: permissionSetting)

        var comments: [Comment] = []

        // Raw Comment Data -> Comment Model
        // 过滤空数据
        for rawComment in rawComments.filter({ !$0.isEmpty }) {
            let comment = _constructComment(rawComment, docsInfo, commentPermission)
            comments.append(comment)
        }

        // 根据 cur_comment_id 获取当前是第几个页面
        var currentPage: Int?
        if let currentCommentID = params["cur_comment_id"] as? String,
            let index = comments.firstIndex(where: { $0.commentID == currentCommentID }) {
            currentPage = index
        }

        let commentData = CommentData(comments: comments,
                                      currentPage: currentPage,
                                      style: .normal,
                                      docsInfo: docsInfo,
                                      commentType: commentType,
                                      commentPermission: commentPermission)
        if let canManage = canManageDocs, let edit = canEdit {
            for comment in commentData.comments {
                self.updatePermission(comment: comment, canManageDocs: canManage, canEdit: edit)
            }
        }

        // 也不知道 chatID 是啥
        commentData.chatID = chatID

        if let cancelHightLight = params["cancel_highlight"] as? Bool {
            commentData.cancelHightLight = cancelHightLight
        }
        
        if let curCommentID = params["cur_comment_id"] as? String {
            commentData.currentCommentID = curCommentID
            if commentData.cancelHightLight == false {
                let comment = comments.first { $0.commentID == curCommentID }
                comment?.isActive = true
            }
        }

        if let currentCommentPos = params["cur_comment_pos"] as? CGFloat {
            commentData.currentCommentPos = currentCommentPos
        }

        if let isLoaded = params["is_loaded"] as? Bool {
            commentData.isLoaded = isLoaded
        }

        if let curReplyID = params["cur_reply_id"] as? String {
            commentData.currentReplyID = curReplyID
        }

        if let from = params["from"] as? String, from == "feed" {
            commentData.fromFeed = true
        }
        
        if let isInPicture = params["isInPicture"] as? Bool, isInPicture {
            commentData.isInPicture = true
        }
        
        if let statsExtraData = params["statsExtra"] as? [String: Any],
           var statsExtra: CommentStatsExtra = statsExtraData.mapModel() {
            statsExtra.generateReceiveTime()
            commentData.statsExtra = statsExtra
        }

        commentData.paylod = params

        return commentData
    }

    static private func _constructComment(_ rawComment: RawComment, _ docsInfo: DocsInfo?, _ permission: CommentPermission) -> Comment {
        let comment = Comment()
        comment.commentDocsInfo = docsInfo
        comment.serialize(dict: rawComment)
        comment.permission = permission
        comment.commentList.forEach { $0.permission = permission }
        return comment
    }
}

extension CommentConstructor {
    
    static func constructorPermission(params: [String: Any],
                                      isInDocs: Bool,
                                      isInVC: Bool,
                                      permissionSetting: PermissionSetting) -> CommentPermission {
        var commentPermission: CommentPermission = []
        let permission: [String: Bool] = (params["permission"] as? [String: Bool]) ?? [:]
        if permission["resolve"] ?? false {
            commentPermission.insert(.canResolve)
        }
        if permission["comment"] ?? false {
            commentPermission.insert(.canComment)
        }
        if permission["copy"] ?? false {
            commentPermission.insert(.canCopy)
        }
        if permission["show_more"] ?? false {
            commentPermission.insert(.canShowMore)
        }
        if permission["delete"] ?? false == false {
            commentPermission.insert(.canNotDelete)
        }
        if isInDocs {
            commentPermission.insert(.canReaction)
        }
        if isInDocs, !isInVC {
            commentPermission.insert(.canShowVoice)
        }
        for (raw, enable) in permissionSetting {
            if enable {
                commentPermission.insert(.init(rawValue: raw))
            } else {
                commentPermission.remove(.init(rawValue: raw))
            }
        }
        DocsLogger.info("comment permission: \(permission)", component: LogComponents.comment)
        return commentPermission
    }
}

extension CommentConstructor {

    public static func updatePermission(comment: Comment, canManageDocs: Bool, canEdit: Bool) {
        let mutation: (CommentItem, Bool, CommentPermission) -> () = { (item, can, value) in
            if can {
                item.permission.insert(value)
            } else {
                item.permission.remove(value)
            }
        }
        let canComment = comment.permission.contains(.canComment)
        // 处理`解决`，判断 header 和 第一条即可
        if let header = comment.commentList.first,
           let firstReply = comment.commentList.first(where: { $0.uiType.isNormal }) {
            let canResolve = canResolveComment(uid: comment.userId, canManageDocs: canManageDocs, canEdit: canEdit, canComment: canComment)
            mutation(header, canResolve, .canResolve)
            mutation(firstReply, canResolve, .canResolve)
            comment.permission = firstReply.permission
        }
        // 处理`删除`，遍历判断
        for item in comment.commentList {
            let canDelete = canDeleteComment(uid: item.userID, canManageDocs: canManageDocs, canComment: canComment)
            mutation(item, !canDelete, .canNotDelete)
        }
    }

    // 是否能解决发表者uid的评论
    private static func canResolveComment(uid: String, canManageDocs: Bool, canEdit: Bool, canComment: Bool) -> Bool {
        let selfUserId = User.current.basicInfo?.userID
        var canResolve = false
        let enable_v1 = UserScopeNoChangeFG.CS.commentReslovePermissionOpt
        let enable_v2 = UserScopeNoChangeFG.CS.commentReslovePermissionOptV2
        if enable_v2 {
            if canManageDocs || canEdit {
                canResolve = true
            } else {
                canResolve = selfUserId == uid // 可阅读用户: 仅能解决自己的评论
            }
        } else if enable_v1 {
            if !canManageDocs, selfUserId != uid { // 非管理权限、别人的评论
                canResolve = false
            } else {
                canResolve = true
            }
        } else {
            canResolve = true
        }
        if !canComment {
            canResolve = false
        }
        return canResolve
    }

    // 是否能删除发表者uid的回复
    private static func canDeleteComment(uid: String, canManageDocs: Bool, canComment: Bool) -> Bool {
        var canDelete = false
        let selfUserId = User.current.basicInfo?.userID
        if selfUserId == uid {
            canDelete = true
        } else {
            let enable = UserScopeNoChangeFG.CS.commentDeletePermissionOpt
            if enable {
                canDelete = canManageDocs
            } else {
                canDelete = false
            }
        }
        if !canComment {
            canDelete = false
        }
        return canDelete
    }
}
