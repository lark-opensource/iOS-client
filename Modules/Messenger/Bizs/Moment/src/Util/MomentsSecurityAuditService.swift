//
//  MomentsSecurityAuditService.swift
//  Moment
//
//  Created by bytedance on 3/18/22.
//

import Foundation
import LarkContainer
import LarkSecurityAudit

enum MomentsSecurityAuditEventType {
    case momentsCreateComment(commentId: String, postId: String, imageKeys: [String], officialUserId: String?)
    case momentsForwardPost(postId: String, forwardIds: [String])
    case momentsCreatePost(postId: String, imageKeys: [String], videoKeys: [String], officialUserId: String?)
    case momentsCopyComment(commentId: String, postId: String)
    case momentsCopyLink(url: String, postId: String)
    case momentsCopyPost(postId: String)
    case momentsPreviewImage(originKey: String, postId: String)
    case momentsPreviewVideo(driveUrl: String, postId: String)
    case momentsSaveImage(originKey: String, postId: String)
    case momentsShowDetail(postId: String)
    case momentsShowPost(postId: String)
}

protocol MomentsSecurityAuditService {
    func auditEvent(_ event: MomentsSecurityAuditEventType, status: SecurityEvent_Status?)
}

final class MomentsSecurityAuditServiceImp: MomentsSecurityAuditService {
    private let securityAudit: SecurityAudit

    init(currentUserID: String) {
        self.securityAudit = SecurityAudit()
        var event = Event()
        event.operator = OperatorEntity()
        event.operator.type = .entityUserID
        event.operator.value = currentUserID
        self.securityAudit.sharedParams = event
    }

    func auditEvent(_ eventType: MomentsSecurityAuditEventType, status: SecurityEvent_Status?) {
        var event = Event()
        event.module = .moduleMoments
        var objectEntity = ObjectEntity()
        if !objectEntity.hasDetail {
            objectEntity.detail = SecurityEvent_ObjectDetail()
        }

        if !event.hasExtend {
            event.extend = SecurityEvent_Extend()
        }

        if !event.extend.hasCommonDrawer {
            event.extend.commonDrawer = SecurityEvent_CommonDrawer()
        }

        if let status = status {
            event.extend.status = status
        }
        var renderItems: [SecurityEvent_RenderItem] = []
        switch eventType {
        case .momentsCreateComment(let commentId, let postId, let imageKeys, let officialUserId):
            event.operation = .operationCreate
            objectEntity.type = .entityMomentsComment
            objectEntity.value = commentId
            var data: [(String, String)] = [(renderKeyToString(.momentsPostID), postId),
                                            (renderKeyToString(.momentsCommentID), commentId)]
            if !imageKeys.isEmpty {
                data.append((renderKeyToString(.momentsImageKeys), imageKeys.joined(separator: ",")))
            }
            if let officialUserId = officialUserId, !officialUserId.isEmpty {
                data.append((renderKeyToString(.momentsOfficialID), officialUserId))
            }
            renderItems = self.renderItemsForData(data)
        case .momentsForwardPost(let postId, let forwardIds):
            event.operation = .operationForward
            objectEntity.type = .entityMomentsPost
            objectEntity.value = postId
            renderItems = self.renderItemsForData([(renderKeyToString(.momentsPostID), postId),
                                                   (renderKeyToString(.momentsForwardIds), forwardIds.joined(separator: ","))])
        case .momentsCreatePost(let postId, let imageKeys, let videoKeys, let officialUserId):
            event.operation = .operationCreate
            objectEntity.type = .entityMomentsPost
            objectEntity.value = postId
            var data: [(String, String)] = [(renderKeyToString(.momentsPostID), postId)]
            if !imageKeys.isEmpty {
                data.append((renderKeyToString(.momentsImageKeys), imageKeys.joined(separator: ",")))
            }
            if !videoKeys.isEmpty {
                data.append((renderKeyToString(.momentsVideoKeys), videoKeys.joined(separator: ",")))
            }
            if let officialUserId = officialUserId, !officialUserId.isEmpty {
                data.append((renderKeyToString(.momentsOfficialID), officialUserId))
            }
            renderItems = self.renderItemsForData(data)
        case .momentsCopyLink(let url, let postId):
            event.operation = .operationCopyContent
            objectEntity.type = .entityLink
            objectEntity.value = url
            renderItems = self.renderItemsForData([(renderKeyToString(.momentsPostID), postId),
                                                   (renderKeyToString(.momentsPostURL), url)])
        case .momentsCopyComment(let commentId, let postId):
            event.operation = .operationCopyContent
            objectEntity.type = .entityMomentsComment
            objectEntity.value = commentId
            renderItems = self.renderItemsForData([(renderKeyToString(.momentsPostID), postId),
                                                   (renderKeyToString(.momentsCommentID), commentId)])
        case .momentsCopyPost(let postId):
            event.operation = .operationCopyContent
            objectEntity.type = .entityMomentsPost
            objectEntity.value = postId
            renderItems = self.renderItemsForData([(renderKeyToString(.momentsPostID), postId)])
        case .momentsPreviewImage(originKey: let originKey, postId: let postId):
            event.operation = .operationRead
            objectEntity.type = .entityMomentsImage
            objectEntity.value = originKey
            renderItems = self.renderItemsForData([(renderKeyToString(.momentsImageKeys), originKey),
                                                   (renderKeyToString(.momentsPostID), postId)])
        case .momentsPreviewVideo(driveUrl: let driveUrl, postId: let postId):
            event.operation = .operationRead
            objectEntity.type = .entityMomentsVideo
            objectEntity.value = driveUrl
            renderItems = self.renderItemsForData([(renderKeyToString(.momentsVideoKeys), driveUrl),
                                                   (renderKeyToString(.momentsPostID), postId)])
        case .momentsSaveImage(originKey: let originKey, postId: let postId):
            event.operation = .operationDownload
            objectEntity.type = .entityMomentsImage
            objectEntity.value = originKey
            renderItems = self.renderItemsForData([(renderKeyToString(.momentsImageKeys), originKey),
                                                   (renderKeyToString(.momentsPostID), postId)])
        case .momentsShowDetail(postId: let postId):
            event.operation = .operationRead
            objectEntity.type = .entityMomentsPostDetail
            objectEntity.value = postId
            renderItems = self.renderItemsForData([(renderKeyToString(.momentsPostID), postId)])
        case .momentsShowPost(postId: let postId):
            event.operation = .operationRead
            objectEntity.type = .entityMomentsPost
            objectEntity.value = postId
            renderItems = self.renderItemsForData([(renderKeyToString(.momentsPostID), postId)])
        }
        event.objects = [objectEntity]
        event.extend.commonDrawer.itemList = renderItems
        self.securityAudit.auditEvent(event)
    }

    /// 这里为什么不传入字典，而是使用数组，因为renderItem 本身要求是个数组 传入字典不能保序
    private func renderItemsForData(_ data: [(String, String)]) -> [SecurityEvent_RenderItem] {
        var renderItems: [SecurityEvent_RenderItem] = []
        for item in data {
            var renderItem = SecurityEvent_RenderItem()
            renderItem.key = item.0
            renderItem.value = item.1
            renderItem.renderTypeValue = .plainText
            renderItems.append(renderItem)
        }
        return renderItems
    }

    private func renderKeyToString(_ key: SecurityEvent_RenderItemKey) -> String {
        var value = ""
        switch key {
        case .momentsPostID:
            value = "momentsPostID"
        case .momentsCommentID:
            value = "momentsCommentID"
        case .momentsForwardIds:
            value = "momentsForwardIds"
        case .momentsPostURL:
            value = "momentsPostURL"
        case .momentsImageKeys:
            value = "momentsImageKeys"
        case .momentsVideoKeys:
            value = "momentsVideoKeys"
        case .momentsOfficialID:
            value = "momentsOfficialID"
        default:
            assertionFailure("error SecurityEvent_RenderItemKey \(key)")
        }
        return value
    }
}
