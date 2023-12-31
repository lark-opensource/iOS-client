//
//  LarkInterface+Forward.swift
//  LarkInterface
//
//  Created by zc09v on 2018/5/28.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import EENavigator
import LarkSDKInterface
import RustPB

public enum ForwardAppReciableTrackChatType: Int {
    case unknown
    case single
    case group
    case topic //话题详情
    case threadDetail //chat详情
    case thread //话题群
}

//转发组件路由Body
public struct ForwardLocalFileBody: PlainBody {
    public static let pattern = "//client/forward/forwardLocalFile"
    public let localPath: String
    public init(localPath: String) {
        self.localPath = localPath
    }
}

//转发消息
public struct ForwardMessageBody: PlainBody {
    public static let pattern = "//client/forward/forwardMessage"
    public static let forwardImageThumbnailKey = "ForwardImageThumbnailKey"

    public enum From {
        case chat
        case pin
        case favorite
        case flag
        case file
        case thread
        case location
        case preview
    }

    public let message: Message
    public let from: From
    public let type: TransmitType
    public let context: [String: Any]
    public let traceChatType: ForwardAppReciableTrackChatType
    /// originMergeForwardId: 私有话题群转发的详情页传入 其他业务传入nil
    /// 私有话题群帖子转发 走的合并转发的消息，在私有话题群转发的详情页，不在群内的用户是可以转发或者收藏这些消息的 会有权限问题，需要originMergeForwardId
    public let originMergeForwardId: String?

    /// 是否可以转发到replyinThread创建的话题中
    /// 默认false,产品只要求特定的几个长江支持即可，转发暂不支持区分消息帖子和普通帖子，在转发组件新参数中，根据该值对帖子类型做统一的置灰
    public let supportToMsgThread: Bool

    public init(
        originMergeForwardId: String? = nil,
        message: Message,
        type: TransmitType,
        from: From,
        traceChatType: ForwardAppReciableTrackChatType = .unknown,
        context: [String: Any] = [:]) {
            self.init(originMergeForwardId: originMergeForwardId,
                      message: message,
                      type: type,
                      from: from,
                      supportToMsgThread: false,
                      traceChatType: traceChatType,
                      context: context)
    }

    public init(
        originMergeForwardId: String? = nil,
        message: Message,
        type: TransmitType,
        from: From,
        supportToMsgThread: Bool,
        traceChatType: ForwardAppReciableTrackChatType = .unknown,
        context: [String: Any] = [:]) {
        self.originMergeForwardId = originMergeForwardId
        self.message = message
        self.type = type
        self.from = from
        self.context = context
        self.supportToMsgThread = supportToMsgThread
        self.traceChatType = traceChatType
    }
}

//逐条消息
public struct BatchTransmitMessageBody: PlainBody {
    public static let pattern = "//client/forward/batchTransmitMessage"
    //会话ID
    public let fromChannelId: String
    public let messageIds: [String]
    public let title: String
    public var finishCallback: (() -> Void)?
    public let originMergeForwardId: String?
    public let traceChatType: ForwardAppReciableTrackChatType
    /// 是否可以转发到replyinThread创建的话题中
    /// 默认false,产品只要求特定的几个长江支持即可
    public let supportToMsgThread: Bool
    public let containBurnMessage: Bool

    public init(fromChannelId: String,
                originMergeForwardId: String?,
                messageIds: [String],
                title: String,
                traceChatType: ForwardAppReciableTrackChatType,
                supportToMsgThread: Bool = false,
                containBurnMessage: Bool = false,
                finishCallback: (() -> Void)?) {
        self.fromChannelId = fromChannelId
        self.originMergeForwardId = originMergeForwardId
        self.messageIds = messageIds
        self.title = title
        self.traceChatType = traceChatType
        self.supportToMsgThread = supportToMsgThread
        self.containBurnMessage = containBurnMessage
        self.finishCallback = finishCallback
    }
}

//合并转发
public struct MergeForwardMessageBody: PlainBody {
    public static let pattern = "//client/forward/mergeForwardMessage"

    public let originMergeForwardId: String?
    public let fromChannelId: String
    public let messageIds: [String]
    public var threadRootMessage: Message?
    public let title: String
    public let forwardThread: Bool
    public var finishCallback: (() -> Void)?
    public let needQuasiMessage: Bool
    public let traceChatType: ForwardAppReciableTrackChatType
    public let afterForwardBlock: (() -> Void)?
    public let containBurnMessage: Bool
    /// 是否可以转发到replyinThread创建的话题中
    /// 默认false,产品只要求特定的几个长江支持即可
    public let supportToMsgThread: Bool
    public let isMsgThread: Bool

    public init(
        originMergeForwardId: String?,
        fromChannelId: String,
        messageIds: [String],
        threadRootMessage: Message? = nil,
        title: String,
        forwardThread: Bool = false,
        traceChatType: ForwardAppReciableTrackChatType,
        finishCallback: (() -> Void)?,
        needQuasiMessage: Bool = true,
        supportToMsgThread: Bool = false,
        isMsgThread: Bool = false,
        containBurnMessage: Bool = false,
        afterForwardBlock: (() -> Void)? = nil) {
        self.originMergeForwardId = originMergeForwardId
        self.fromChannelId = fromChannelId
        self.messageIds = messageIds
        self.threadRootMessage = threadRootMessage
        self.title = title
        self.forwardThread = forwardThread
        self.finishCallback = finishCallback
        self.needQuasiMessage = needQuasiMessage
        self.traceChatType = traceChatType
        self.supportToMsgThread = supportToMsgThread
        self.isMsgThread = isMsgThread
        self.containBurnMessage = containBurnMessage
        self.afterForwardBlock = afterForwardBlock
    }
}

//群分享
public struct ShareChatBody: CodablePlainBody {
    public static let pattern = "//client/forward/shareChat"

    public let chatId: String

    public init(chatId: String) {
        self.chatId = chatId
    }
}

//个人名片分享
public struct ShareUserCardBody: CodablePlainBody {
    public static var pattern: String = "//client/forward/shareUserCard"

    public let shareChatterId: String

    public init(shareChatterId: String) {
        self.shareChatterId = shareChatterId
    }
}

// 从文件夹消息里面转发文件/文件夹副本
public struct ForwardCopyFromFolderMessageBody: CodablePlainBody {
    public static var pattern: String = "//client/forward/folderMessage/forwardCopy"

    // 转发类型
    public enum CopyType: String, Codable {
        case file
        case zip
        case folder
    }

    public let folderMessageId: String
    public let key: String
    public let name: String
    public let size: Int64
    public let copyType: CopyType

    public init(folderMessageId: String,
                key: String,
                name: String,
                size: Int64,
                copyType: CopyType) {
        self.folderMessageId = folderMessageId
        self.key = key
        self.name = name
        self.size = size
        self.copyType = copyType
    }
}

//会议分享
public struct ShareMeetingBody: CodablePlainBody {

    public enum Source: String {
        /// 扫码分享会议链接
        case QRCode
        /// 会中会议详情 - 「分享至会话」
        case meetingDetail
        /// 参会人列表邀请 - 「分享至会话」
        case participants
        /// tab详情 - 分享
        case tabDetail
    }

    public enum Style: String {
        /// 会议链接形式（扫码分享room会议
        case link
        /// 会议卡片形式（会中分享
        case card
    }

    public static let pattern = "//client/byteview/share"

    public let meetingId: String

    public let skipCopyLink: Bool

    public let style: Style

    public let source: Source

    public let canShare: (() -> Bool)?

    public init(meetingId: String,
                skipCopyLink: Bool = false,
                style: Style,
                source: Source,
                canShare: (() -> Bool)? = nil
    ) {
        self.meetingId = meetingId
        self.skipCopyLink = skipCopyLink
        self.style = style
        self.source = source
        self.canShare = canShare
    }

    // --- for link style ---
    enum CodingKeys: String, CodingKey {
        case meetingId
        case skipCopyLink
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        meetingId = try values.decode(String.self, forKey: .meetingId)
        skipCopyLink = try values.decode(Bool.self, forKey: .skipCopyLink)
        style = .link
        source = .QRCode
        canShare = nil
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(meetingId, forKey: .meetingId)
        try container.encode(skipCopyLink, forKey: .skipCopyLink)
    }
}

/// 分享类型
public enum ShareImageType {
    /// 默认
    case normal
    /// 和'转发图片消息'保持一致，有footer
    case forward
    /// 和'新转发图片消息的一级预览'保持一致，有footer
    case forwardPreview
}

/// 分享图片，目前用在以下地方：
/// 1、Docs中预览大图；
/// 2、分享群二维码；
/// 3、Chat中预览大图。
public struct ShareImageBody: PlainBody {
    public static let pattern = "//client/shareImage"

    public let name: String
    public let image: UIImage
    public let type: ShareImageType
    public let needFilterExternal: Bool
    public let cancelCallBack: (() -> Void)?
    public let successCallBack: (() -> Void)?
    //开平二维码分享结果回调
    public var shareResultsCallBack: (([(String, Bool)]?) -> Void)?
    // Mail 邮件内图片分享结果回调
    public var forwardResultsCallBack: ((ForwardResult?) -> Void)?

    public init(name: String = "",
                image: UIImage,
                type: ShareImageType = .normal,
                needFilterExternal: Bool = true,
                cancelCallBack: (() -> Void)? = nil,
                successCallBack: (() -> Void)? = nil) {
        self.name = name
        self.image = image
        self.type = type
        self.needFilterExternal = needFilterExternal
        self.cancelCallBack = cancelCallBack
        self.successCallBack = successCallBack
    }
}

public struct ForwardFileBody: PlainBody {
    public static let pattern = "//client/shareFile"

    public let fileName: String
    public let fileURL: String
    public let fileSize: Int64
    public var shareResultsCallBack: (([(String, Bool)]?) -> Void)?
    public init(fileName: String,
                fileURL: String,
                fileSize: Int64,
                shareResultsCallBack: (([(String, Bool)]?) -> Void)? = nil) {
        self.fileName = fileName
        self.fileURL = fileURL
        self.fileSize = fileSize
        self.shareResultsCallBack = shareResultsCallBack
    }
}

public struct ShareContentBody: CodablePlainBody {
    public static let pattern = "//client/shareContent"

    public let title: String //标题
    public let content: String //具体的分享内容
    public let sourceAppName: String? //分享来源app
    public let sourceAppUrl: String? //分享来源app url
    public var shouldShowInputViewWhenShareToTopicCircle: Bool //分享到话题圈是否显示输入框

    public init(
        title: String,
        content: String,
        sourceAppName: String? = nil,
        sourceAppUrl: String? = nil,
        shouldShowInputViewWhenShareToTopicCircle: Bool = true) {

        self.title = title
        self.content = content
        self.sourceAppName = sourceAppName
        self.sourceAppUrl = sourceAppUrl
        self.shouldShowInputViewWhenShareToTopicCircle = shouldShowInputViewWhenShareToTopicCircle
    }
}

public struct ShareMailAttachementBody: PlainBody {
    public static var pattern: String = "//client/forward/shareMailAttachment"
    public let title: String
    public let img: UIImage
    public let token: String
    public let isLargeAttachment: Bool
    public var forwardResultsCallBack: ((ForwardResult?) -> Void)?
    public init(title: String, img: UIImage, token: String, isLargeAttachment: Bool,
                forwardResultsCallBack: ((ForwardResult?) -> Void)? = nil) {
        self.title = title
        self.img = img
        self.token = token
        self.isLargeAttachment = isLargeAttachment
        self.forwardResultsCallBack = forwardResultsCallBack
    }
}

/// 转发一个纯文本 样式和转发消息相同
public struct ForwardTextBody: PlainBody {
    public typealias SentHandler = (_ userIds: [String], _ chatIds: [String]) -> Void

    public static let pattern = "//client/forwardText"
    public let text: String
    /// 转发成功后返回单聊和群聊信息
    public let sentHandler: SentHandler?
    //开平链接分享结果回调
    public var shareResultsCallBack: (([(String, Bool)]?) -> Void)?

    public init(text: String, sentHandler: SentHandler? = nil) {
        self.text = text
        self.sentHandler = sentHandler
    }
}

public struct ForwardLingoBody: PlainBody {
    public typealias SentCompletion = (_ userIds: [String], _ chatIds: [String]) -> Void
    public static let pattern = "//client/abbreviation/open"
    public let content: String
    public let title: String
    public let sentCompletion: SentCompletion

    public init(content: String, title: String, sentCompletion: @escaping SentCompletion) {
        self.content = content
        self.title = title
        self.sentCompletion = sentCompletion
    }
}

// ShareExtension分享
public struct ShareExtensionBody: CodablePlainBody {
    // Note: copy from LarkExtensionCommo
    public static let pattern = "//client/extension/share"

    public init() {}
}

/// 预选信息，包含预选会话的类型和id
public enum PreSelectInfo {
    case chatID(String)
    case chatterID(String)
}

//选择会话
public struct ChatChooseBody: PlainBody {
    public static let pattern = "//client/chooseChat"
    // 是否需要实现JXSegmentedListContainerViewListDelegate协议(作为容器的一部分)
    public let isWithinContainer: Bool
    public let allowCreateGroup: Bool
    public let multiSelect: Bool
    public let ignoreSelf: Bool
    public let ignoreBot: Bool
    /// 是否包含外部联系人
    public let needSearchOuterTenant: Bool
    /// 是否包含外部群组
    public let includeOuterChat: Bool?
    public let selectType: Int
    public let confirmTitle: String?
    // 展示的确认框描述，当inputView显示时无效
    public let confirmDesc: String
    public let confirmOkText: String?
    // 是否展示留言输入框，与confirmDesc互斥
    public let showInputView: Bool
    // 预选信息
    public let preSelectInfos: [PreSelectInfo]?
    public let showRecentForward: Bool
    public var targetPreview: Bool = true
    public var includeMyAI: Bool = false
    // 权限
    public var permissions: [RustPB.Basic_V1_Auth_ActionType]?
    // 下面两种回调形式二选一设置即可，内部优先判断 callback
    // 非阻塞式的回调形式，转发页点击确定即 dismiss
    public let callback: (([String: Any]?, Bool) -> Void)?
    // 阻塞式的回调形式，转发页点击确定等待外部信号发送 onNext 事件后才会 dismiss
    public let blockingCallback: (([String: Any]?, Bool) -> Observable<Void>)?
    public let forwardVCDismissBlock: (() -> Void)?
    // nolint: duplicated_code -- 与识别出来的重复代码差异较大，不建议合并
    public init(isWithinContainer: Bool = false,
                allowCreateGroup: Bool,
                multiSelect: Bool,
                ignoreSelf: Bool,
                ignoreBot: Bool,
                needSearchOuterTenant: Bool = true,
                includeOuterChat: Bool? = nil,
                selectType: Int,
                confirmTitle: String? = nil,
                confirmDesc: String,
                confirmOkText: String? = nil,
                showInputView: Bool,
                preSelectInfos: [PreSelectInfo]? = nil,
                showRecentForward: Bool = true,
                callback: (([String: Any]?, Bool) -> Void)? = nil,
                blockingCallback: (([String: Any]?, Bool) -> Observable<Void>)? = nil,
                forwardVCDismissBlock: (() -> Void)? = nil) {
        self.isWithinContainer = isWithinContainer
        self.allowCreateGroup = allowCreateGroup
        self.multiSelect = multiSelect
        self.ignoreSelf = ignoreSelf
        self.ignoreBot = ignoreBot
        self.needSearchOuterTenant = needSearchOuterTenant
        self.includeOuterChat = includeOuterChat
        self.selectType = selectType
        self.confirmTitle = confirmTitle
        self.confirmDesc = confirmDesc
        self.confirmOkText = confirmOkText
        self.showInputView = showInputView
        self.callback = callback
        self.blockingCallback = blockingCallback
        self.forwardVCDismissBlock = forwardVCDismissBlock
        self.preSelectInfos = preSelectInfos
        self.showRecentForward = showRecentForward
    }
    // enable-lint: duplicated_code
}

//picker
public struct EventShareBody: PlainBody {
    public static let pattern = "//client/forward/eventShare"

    public let currentChatId: String
    public let shouldShowExternalUser: Bool
    public let shouldShowHint: Bool
    public let shareMessage: String
    public let subMessage: String
    public let shareImage: UIImage
    public let pickerCallBack: ([String], String?, Error?, Bool) -> Void
    public init(currentChatId: String,
                shareMessage: String,
                subMessage: String,
                shareImage: UIImage,
                shouldShowExternalUser: Bool,
                shouldShowHint: Bool,
                callBack: @escaping ([String], String?, Error?, Bool) -> Void) {
        self.currentChatId = currentChatId
        self.pickerCallBack = callBack
        self.shouldShowHint = shouldShowHint
        self.shareMessage = shareMessage
        self.shareImage = shareImage
        self.shouldShowExternalUser = shouldShowExternalUser
        self.subMessage = subMessage
    }
}

public struct AppCardShareBody: PlainBody {
    public static let pattern: String = "//client/share/application"

    public let appShareType: ShareAppCardType
    public let appUrl: String
    public var multiSelect: Bool?
    public let callback: (([String: Any]?, Bool) -> Void)?
    public var customView: (UIView)?

    public init(shareType: ShareAppCardType,
                appUrl: String,
                callback: (([String: Any]?, Bool) -> Void)? = nil) {
        self.appShareType = shareType
        self.appUrl = appUrl
        self.callback = callback
    }
}

public struct ShareThreadTopicBody: PlainBody {
    public static let pattern = "//client/forward/shareThreadTopic"
    public let message: Message
    public let title: String

    public init(message: Message, title: String) {
        self.message = message
        self.title = title
    }
}

public struct EmotionShareBody: PlainBody {
    public static var pattern = "//client/forward/emotion"
    public let stickerSet: RustPB.Im_V1_StickerSet

    public init(stickerSet: RustPB.Im_V1_StickerSet) {
        self.stickerSet = stickerSet
    }
}

public struct SendSingleEmotionBody: PlainBody {
    public static var pattern = "//client/forward/send_single_emotion"
    public let sticker: RustPB.Im_V1_Sticker
    public let message: Message

    public init(sticker: RustPB.Im_V1_Sticker, message: Message) {
        self.sticker = sticker
        self.message = message
    }
}

public struct EmotionShareToPanelBody: PlainBody {
    public static var pattern = "//client/forward/emotion_share_pannel"
    public let stickerSet: RustPB.Im_V1_StickerSet

    public init(stickerSet: RustPB.Im_V1_StickerSet) {
        self.stickerSet = stickerSet
    }
}

public struct MailMessageShareBody: PlainBody {
    public static var pattern = "//client/forward/mailMessage"
    public let threadId: String
    public let messageIds: [String]
    public let summary: String
    public var statisticsParams: [String: Any] = [:]

    public init(threadId: String, messageIds: [String], summary: String) {
        self.threadId = threadId
        self.messageIds = messageIds
        self.summary = summary
    }
}

public struct OpenShareBody: CodablePlainBody {
    public static var pattern = "//client/openShare"

    public init() { }
}

// 分享方式类型
public enum ShareChatViaLinkType: String, Codable {
    case card // 群名片
    case link // 群链接
    case QRcode // 群二维码
}

//群分享（群名片，群链接，群二维码）
public struct ShareChatViaLinkBody: CodablePlainBody {
    public static let pattern = "//client/forward/shareChatViaLink"

    public let chatId: String
    public let defaultSelected: ShareChatViaLinkType // 初始选中，默认选中群名片

    public init(chatId: String, defaultSelected: ShareChatViaLinkType = .card) {
        self.chatId = chatId
        self.defaultSelected = defaultSelected
    }
}

//分享公司圈动态
public struct ShareMomentsPostBody: PlainBody {
    public static let pattern = "//client/forward/shareMomentsPost"

    public let post: RustPB.Moments_V1_Post
    public let action: ([String], String?) -> Observable<Void>
    public let cancel: (() -> Void)?

    public init(post: RustPB.Moments_V1_Post,
                action: @escaping ([String], String?) -> Observable<Void>,
                cancel: (() -> Void)?) {
        self.post = post
        self.action = action
        self.cancel = cancel
    }
}

public struct AtUserBody: PlainBody {
    public static let pattern = "//client/forward/atUser"

    public var atSuccessCallBack: (([ForwardItem]) -> Void)?
    public var atCancelCallBack: (() -> Void)?

    public let provider: ForwardAlertProvider

    public init(provider: ForwardAlertProvider) {
        self.provider = provider
    }
}

public struct ForwardMentionBody: PlainBody {
    public static let pattern = "//client/forward/mention"

    public var atSuccessCallBack: (([ForwardItem]) -> Void)?
    public var atCancelCallBack: (() -> Void)?

    public let forwardConfig: ForwardConfig

    public init(forwardConfig: ForwardConfig) {
        self.forwardConfig = forwardConfig
    }
}
