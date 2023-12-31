//
//  MessengerDependency.swift
//  TodoInterface
//
//  Created by 张威 on 2021/1/25.
//

import UIKit
import RxSwift
import EENavigator
import RustPB
import Photos
import LarkModel
import RxCocoa
import LarkEmotionKeyboard
import LarkBizTag

/// Messenger Dependency

/// Chatter 概要信息
public struct ChatterSearchItem {
    public var id: String
    public var tenantId: String
    public var name: String
    public var otherName: UserName?
    public var avatarKey: String
    public var department: String?
    public var tagInfo: [TagDataItem]
    public var isBot: Bool
    public var isAnonymous: Bool

    // nolint: long parameters
    public init(
        id: String,
        tenantId: String,
        name: String,
        otherName: UserName? = nil,
        avatarKey: String,
        department: String?,
        tagInfo: [TagDataItem],
        isBot: Bool,
        isAnonymous: Bool
    ) {
        self.id = id
        self.tenantId = tenantId
        self.name = name
        self.otherName = otherName
        self.avatarKey = avatarKey
        self.department = department
        self.tagInfo = tagInfo
        self.isBot = isBot
        self.isAnonymous = isAnonymous
    }
    // enable-lint: long parameters
}

public struct UserName {
    public var alias: String
    public var anotherName: String
    public var localizedName: String

    public init(
        alias: String,
        anotherName: String,
        localizedName: String
    ) {
        self.alias = alias
        self.anotherName = anotherName
        self.localizedName = localizedName
    }
}

extension UserName {

    // 端上优先展示 alias > another_name > localize_name。
    public func displayNameForPick(_ rule: Contact_V1_GetAnotherNameFormatResponse.FormatRule) -> String {
        switch rule {
        case.nameFirst, .unknown:
            if !alias.isEmpty {
                return "\(alias)(\(localizedName))"
            } else if !anotherName.isEmpty {
                return "\(localizedName)(\(anotherName))"
            } else {
                return "\(localizedName)"
            }
        case .anotherNameFirst:
            switch (!alias.isEmpty, !anotherName.isEmpty) {
            case (true, true):
                return "\(alias)(\(anotherName))"
            case (true, false):
                return "\(alias)(\(localizedName))"
            case (false, true):
                return "\(anotherName)(\(localizedName))"
            case (false, false):
                return "\(localizedName)"
            }
        }
    }

}

/// 基于 Chat 的 chatter 搜索结果
public struct ChatterSearchResultBasedOnChat {
    public var isFromRemote: Bool
    public var chatChatters: [String: ChatterSearchItem]
    public var chatters: [String: ChatterSearchItem]
    public var wantedChatterIds: [String]
    public var inChatChatterIds: [String]
    public var outChatChatterIds: [String]

    // nolint: long parameters
    public init(
        isFromRemote: Bool,
        chatChatters: [String: ChatterSearchItem],
        chatters: [String: ChatterSearchItem],
        wantedChatterIds: [String],
        inChatChatterIds: [String],
        outChatChatterIds: [String]
    ) {
        self.isFromRemote = isFromRemote
        self.chatChatters = chatChatters
        self.chatters = chatters
        self.wantedChatterIds = wantedChatterIds
        self.inChatChatterIds = inChatChatterIds
        self.outChatChatterIds = outChatChatterIds
    }
    // enable-lint: long parameters
}

/// 基于 Query 的 chatter 搜索结果
public struct ChatterSearchResultBasedOnQuery {
    public var isFromRemote: Bool
    public var chatters: [ChatterSearchItem]

    public init(isFromRemote: Bool, chatters: [ChatterSearchItem]) {
        self.isFromRemote = isFromRemote
        self.chatters = chatters
    }
}

public protocol MessengerDependency {

    /// 批量拉取 messages
    /// - Parameter messageIds:  需要拉取的 message 的 id
    func fetchMessages(byIds messageIds: [String]) -> Observable<[LarkModel.Message]>

    /// 批量回复 messages
    ///
    /// - Parameters:
    ///   - messageId: 被回复的 message 的 id
    ///   - content: 回复内容
    func replyMessages(byIds messageIds: [String], with content: String, replyInThreadSet: Set<String>)

    /// 根据 userIds 获取对应的会话（如果没有会话，则创建一个），返回会话 id
    ///
    /// - Parameter userIds: user ids
    func checkAndCreateChats(byUserIds userIds: [String]) -> Observable<[String]>

    /// 基于 chatId & query 搜索 chatter
    func searchChatter(
        byQuery query: String,
        basedOnChat chatId: String
    ) -> Observable<ChatterSearchResultBasedOnChat>

    /// 基于 query 搜索 chatter
    func searchChatter(byQuery query: String) -> Observable<ChatterSearchResultBasedOnQuery>

    /// 获取合并消息的展示信息
    func getMergedMessageDisplayInfo(entity: Basic_V1_Entity, message: Basic_V1_Message) -> (title: String, content: NSAttributedString)

    /// 处理 Photo Assets
    func processPhotoAssets(_ assets: [PHAsset], isOriginal: Bool) -> [(image: UIImage, data: Data)]

    /// 根据 chatid 获取 chatName
    func fetchChatName(by chatId: String, onSuccess: @escaping (String) -> Void, onError: @escaping (Error) -> Void
    )

    /// 上传 Taken Photo
    func uploadTakenPhoto(_ photo: UIImage, callback: @escaping (_ compressedImage: UIImage) -> Void) -> Observable<String>

    /// 上传 Photo Assets
    func uploadPhotoAsset(_ asset: PHAsset, isOriginal: Bool, callback: @escaping (_ compressedImage: UIImage) -> Void) -> Observable<String>

    /// 解析图片压缩上传错误，返回一条错误文案用于提示
    func parseImageUploaderError(_ error: Error) -> String?

    /// 用户设置中，是否是24小时
    var is24HourTime: BehaviorRelay<Bool> { get }

    func resourceAddrWithLanguage(key: String) -> String?

    func updateRecentlyUsedReaction(reactionType: String) -> Observable<Void>

    var reactionService: EmojiDataSourceDependency { get }
}

/// 选择分享目标

public struct SelectSharingItemBody {

    /// 分享目标
    public enum SharingItem {
        case chat(chatId: String)
        case bot(botId: String)
        case user(userId: String)
        case thread(threadId: String, chatId: String)
        case replyThread(threadId: String, chatId: String)
        case generalFilter(id: String)
    }

    public static let pattern = "//client/todo/share"
    public let summary: String
    // 是否显示内容中的icon
    public var showIcon: Bool = true
    // 是否屏蔽机器人
    public var ignoreBot: Bool = false
    public var onCancel: (() -> Void)?
    public var onConfirm: ((_ items: [SharingItem], _ message: String?) -> Void)?
    public init(summary: String) {
        self.summary = summary
    }
}
