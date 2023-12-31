//
//  SendMessageTestModel.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/3/2.
//

import Foundation
import RustPB
import RxSwift
import LarkModel
import SwiftProtobuf
import LarkSDKInterface
@testable import LarkRustClient

struct SendMessageTestModel {
    static let chatId = "7057791413005647873"
    static let mockCid = "123131"

    static func mockChatter() -> LarkModel.Chatter {
        return Chatter(
            id: "pb.id",
            isAnonymous: false,
            isFrozen: false,
            name: "pb.name",
            localizedName: "pb.localizedName",
            enUsName: "pb.enUsName",
            namePinyin: "pb.namePinyin",
            alias: "pb.alias",
            anotherName: "pb.anotherName",
            nameWithAnotherName: "pb.nameWithAnotherName",
            type: .unknown,
            avatarKey: "pb.avatarKey",
            avatar: ImageSet(),
            updateTime: TimeInterval(0),
            creatorId: "pb.creatorID",
            isResigned: false,
            isRegistered: false,
            description: Chatter.Description(),
            withBotTag: "pb.withBotTag",
            canJoinGroup: true,
            tenantId: "pb.tenantID",
            workStatus: WorkStatus(),
            profileEnabled: false,
            focusStatusList: [],
            chatExtra: nil,
            accessInfo: Chatter.AccessInfo(),
            email: "pb.email",
            doNotDisturbEndTime: 0,
            openAppId: "pb.openAppID",
            acceptSmsPhoneUrgent: false,
            medalKey: "",
            timeZoneID: "pb.timeZone.timeZoneID",
            isDefaultAvatar: false,
            isSpecialFocus: false)    }

    static func mockMessage() -> LarkModel.Message {
        return Message(id: "",
                       cid: "",
                       type: .text,
                       channel: Basic_V1_Channel(),
                       createTime: 0,
                       updateTime: 0,
                       rootId: "",
                       parentId: "",
                       fromId: "",
                       isRecalled: false,
                       isNoTraceDeleted: false,
                       isEdited: false,
                       replyCount: 0,
                       position: 1,
                       meRead: false,
                       parentSourceId: "",
                       rootSourceId: "",
                       isUrgent: false,
                       urgentId: "",
                       isAtMe: false,
                       isAtAll: false,
                       isTruncated: false,
                       unreadChatterIds: [],
                       textDraftId: "",
                       postDraftId: "",
                       isDeleted: false,
                       fromType: .bot,
                       docKey: "",
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
                       sourceType: .typeFromFavorite,
                       sourceID: "",
                       recallerId: "",
                       recallerIdentity: .unknownIdentity,
                       pinTimestamp: 0,
                       isReeditable: false,
                       badgeCount: 0,
                       isBadged: false,
                       isUntranslateable: false,
                       readAtChatterIds: [],
                       threadId: "",
                       threadPosition: 0,
                       threadBadgeCount: 0,
                       messageLanguage: "",
                       displayRule: .noTranslation,
                       isAutoTranslatedByReceiver: false,
                       translateLanguage: "",
                       originalSenderID: "",
                       isForwardFromFriend: false,
                       isFileDeleted: false,
                       fileDeletedStatus: .normal,
                       syncDependency: false,
                       isDecryptoFail: false)
    }
}

class MockRustClient: SDKRustService {
    func register(pushCmd cmd: Command, handler: @escaping (Data, Packet) -> Void) -> Disposable {
        return Disposables.create()
    }

    func eventStream<R>(request: SwiftProtobuf.Message, config: Basic_V1_RequestPacket.BizConfig?, spanID: UInt64?) -> Observable<R> where R: SwiftProtobuf.Message {
        return .empty()
    }

    func eventStream<R>(request: SwiftProtobuf.Message, config: Basic_V1_RequestPacket.BizConfig?) -> Observable<R> where R: SwiftProtobuf.Message {
        return .empty()
    }

    func eventStream<R>(_ request: RequestPacket, event handler: @escaping (ResponsePacket<R>?, Bool) -> Void) -> Disposable where R: SwiftProtobuf.Message {
        return Disposables.create()
    }

    func async<R>(_ request: RequestPacket, callback: @escaping (ResponsePacket<R>) -> Void) where R: SwiftProtobuf.Message {
    }

    func async(_ request: RequestPacket, callback: @escaping (ResponsePacket<Void>) -> Void) {
    }

    // swiftlint:disable all
    func sync<R>(_ request: RequestPacket) -> ResponsePacket<R> where R: SwiftProtobuf.Message {
        var response = Im_V1_CreateQuasiMessageResponse()
        response.cid = SendMessageTestModel.mockCid
        var quasi = Basic_V1_QuasiMessage()
        quasi.cid = SendMessageTestModel.mockCid
        response.entity.quasiMessages[SendMessageTestModel.mockCid] = quasi
        return ResponsePacket(contextID: "", result: .success(response as! R))
    }

    func register<R>(pushCmd cmd: Command) -> Observable<R> where R: SwiftProtobuf.Message {
        return .just(Im_V1_CreateQuasiMessageResponse() as! R)
    }
    // swiftlint:enable all

    func sync(_ request: RequestPacket) -> ResponsePacket<Void> {
        return ResponsePacket(contextID: "", result: .success(()))
    }

    func register(pushCmd cmd: Command, handler: @escaping (Data) -> Void) -> Disposable {
        return Disposables.create()
    }

    func register(serverPushCmd cmd: ServerCommand, handler: @escaping (Data) -> Void) -> Disposable {
        return Disposables.create()
    }

    func unregisterPushHanlders() {
    }

    func dispose() {
    }

    func barrier(allowRequest: @escaping (RequestPacket) -> Bool, enter: @escaping (@escaping () -> Void) -> Void) {
    }
}
