//
//  TestHelper.swift
//  LarkMessengerUnitTest
//
//  Created by 袁平 on 2020/8/26.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import XCTest
import LarkFoundation
import RustPB
import LarkModel

func async(_ work: @escaping () -> Void) {
    DispatchQueue.global().async(execute: work)
}

func asyncAfter(_ deadline: DispatchTime, _ work: @escaping () -> Void) {
    DispatchQueue.global().asyncAfter(deadline: deadline, execute: work)
}

func main(_ work: @escaping () -> Void) {
    DispatchQueue.main.async(execute: work)
}

func mainAfter(_ deadline: DispatchTime, _ work: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: deadline, execute: work)
}

/// 构造一个初始化了required字段的FeedPreview
func buildFeedPreview() -> FeedPreview {
    var feed = Feed_V1_FeedCardPreview()
    feed.pair.id = ""
    feed.pair.type = .chat
    feed.feedType = .inbox
    feed.avatarKey = ""
    feed.name = ""
    feed.unreadCount = 1
    feed.isRemind = true
    feed.updateTime = Int64(CACurrentMediaTime())
    feed.isShortcut = true
    feed.localizedDigestMessage = ""
    feed.entityStatus = .normal
    feed.displayTime = Int64(CACurrentMediaTime())
    feed.rankTime = Int64(CACurrentMediaTime())
    feed.parentCardID = ""
    feed.crossTenant = false
    return FeedPreview.transformByCardPreview(feed)
}

func buildChat() -> Chat {
    return Chat(id: "id",
                type: .p2P,
                name: "name",
                namePinyin: "namePinyin",
                lastMessageId: "lastMessageId",
                lastMessagePosition: 0,
                updateTime: CACurrentMediaTime(),
                createTime: CACurrentMediaTime(),
                chatterId: "chatterId",
                description: "description",
                avatar: Image(),
                avatarKey: "avatarKey",
                miniAvatarKey: "miniAvatarKey",
                ownerId: "ownerId",
                chatterCount: 0,
                userCount: 0,
                isDepartment: true,
                isPublic: false,
                isArchived: true,
                isDeleted: false,
                isRemind: true,
                role: .member,
                isCustomerService: false,
                isCustomIcon: false,
                textDraftId: "textDraftId",
                postDraftId: "postDraftId",
                isShortCut: true,
                announcement: .init(),
                offEditGroupChatInfo: false,
                tenantId: "tenantId",
                isDissolved: false,
                messagePosition: .recentLeft,
                addMemberPermission: .allMembers,
                atAllPermission: .allMembers,
                joinMessageVisible: .allMembers,
                quitMessageVisible: .allMembers,
                shareCardPermission: .allowed,
                addMemberApply: .needApply,
                putChatterApplyCount: 0,
                showBanner: true,
                lastVisibleMessageId: "lastVisibleMessageId",
                burnLife: 0,
                isCrypto: false,
                isMeeting: false,
                chatable: true,
                muteable: true,
                isTenant: true,
                isCrossTenant: true,
                isInBox: false,
                firstMessagePostion: 0,
                isOfficialOncall: false,
                isOfflineOncall: false,
                oncallId: "oncallId",
                lastVisibleMessagePosition: 0,
                readPosition: 0,
                readPositionBadgeCount: 0,
                lastMessagePositionBadgeCount: 0,
                isAutoTranslate: false,
                chatMode: .default,
                lastThreadPositionBadgeCount: 0,
                readThreadPosition: 0,
                readThreadPositionBadgeCount: 0,
                lastVisibleThreadPosition: 0,
                lastVisibleThreadId: "lastVisibleThreadId",
                lastThreadId: "lastThreadId",
                lastThreadPosition: 0,
                sidebarButtons: [],
                isAllowPost: true,
                postType: .anyone,
                hasWaterMark: true,
                lastDraftId: "lastDraftId",
                lastReadPosition: 0,
                lastReadOffset: 0)
}

func buildMessage() -> Message {
    return Message(id: "id",
                   cid: "cid",
                   type: .unknown,
                   channel: .init(),
                   createTime: CACurrentMediaTime(),
                   updateTime: CACurrentMediaTime(),
                   rootId: "rootId",
                   parentId: "parentId",
                   fromId: "fromId",
                   isRecalled: false,
                   isNoTraceDeleted: true,
                   isEdited: false,
                   replyCount: 0,
                   position: 0,
                   meRead: true,
                   parentSourceId: "parentSourceId",
                   rootSourceId: "rootSourceId",
                   isUrgent: false,
                   urgentId: "urgentId",
                   isAtMe: false,
                   isAtAll: false,
                   isTruncated: false,
                   unreadChatterIds: [],
                   textDraftId: "textDraftId",
                   postDraftId: "postDraftId",
                   isDeleted: false,
                   fromType: .unknownFromType,
                   docKey: "docKey",
                   unreadCount: 0,
                   readCount: 0,
                   unackUrgentChatterIds: [],
                   ackUrgentChatterIds: [],
                   content: UnknownContent(),
                   reactions: [],
                   isVisible: false,
                   burnLife: 0,
                   burnTime: 0,
                   isBurned: false,
                   isCryptoIntermediate: false,
                   sourceType: .typeFromUnkonwn,
                   sourceID: "sourceID",
                   recallerId: "recallerId",
                   recallerIdentity: .unknownIdentity,
                   pinTimestamp: 0,
                   isReeditable: false,
                   badgeCount: 0,
                   isBadged: false,
                   isUntranslateable: false,
                   readAtChatterIds: [],
                   threadId: "threadId",
                   threadPosition: 0,
                   threadBadgeCount: 0,
                   messageLanguage: "messageLanguage",
                   displayRule: .unknownRule,
                   isAutoTranslatedByReceiver: false,
                   translateLanguage: "",
                   originalSenderID: "",
                   isForwardFromFriend: false,
                   isFileDeleted: false)
}

extension XCTestCase {
    func mainWait(_ time: TimeInterval = 1, _ name: String = "mainWait") {
        let expect = expectation(description: name)
        mainAfter(.now() + time) {
            expect.fulfill()
        }
        wait(for: [expect], timeout: time + 1)
    }
}
