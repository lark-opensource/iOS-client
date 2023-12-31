//
//  LarkInterface+PreviewImage.swift
//  LarkInterface
//
//  Created by liuwanlin on 2018/5/18.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import LarkModel
import EENavigator
import RustPB
import LarkAssetsBrowser
import LarkImageEditor
import AppReciableSDK
import LarkAccountInterface
import LarkUIKit

public enum ImageAssetSourceType {
    case image(ImageSet)
    case video(MediaInfoItem)
    case sticker(stickerSetID: String)
    case post(RustPB.Basic_V1_RichTextElement.ImageProperty)
    case avatar(avatarViewParams: [String: Any]?, entityId: String?)
    case other
}

public struct MediaInfoItem {
    public var key: String
    public var videoCoverKey: String
    public var videoCoverImage: ImageSet
    public var url: String
    public var videoCoverUrl: String
    public var localPath: String
    public var size: Float
    public var messageId: String
    public var fatherMFId: String?
    public var replyThreadRootId: String?
    public var channelId: String
    public var sourceId: String = ""
    // 消息链接化场景需要使用previewID做资源鉴权
    public var authToken: String?
    public var sourceType: Message.SourceType = .typeFromUnkonwn
    public var needAuthentication = true
    public var downloadFileScene: RustPB.Media_V1_DownloadFileScene?
    public var duration: Int32
    public var isPCOriginVideo: Bool
    public var messageRiskObjectKeys: [String] = []

    public init(
        content: MediaContent,
        messageId: String,
        messageRiskObjectKeys: [String] = [],
        channelId: String,
        sourceId: String,
        sourceType: Message.SourceType,
        isSuccess: Bool,
        needAuthentication: Bool = true,
        downloadFileScene: RustPB.Media_V1_DownloadFileScene?
    ) {
        self.key = content.key
        self.videoCoverKey = content.image.origin.key
        self.videoCoverImage = content.image
        self.url = Self.getUrl(url: content.url, downloadFileScene: downloadFileScene)
        self.videoCoverUrl = content.image.origin.firstUrl
        self.size = Float(content.size / 1024 / 1024)
        self.localPath = isSuccess ? content.filePath : content.originPath
        self.messageId = messageId
        self.messageRiskObjectKeys = messageRiskObjectKeys
        self.channelId = channelId
        self.sourceId = sourceId
        self.authToken = content.authToken
        self.sourceType = sourceType
        self.needAuthentication = needAuthentication
        self.downloadFileScene = downloadFileScene
        self.duration = content.duration
        self.isPCOriginVideo = content.isPCOriginVideo
    }

    public init(
        content: MediaContent,
        messageId: String,
        messageRiskObjectKeys: [String],
        fatherMFId: String?,
        replyThreadRootId: String?,
        channelId: String,
        sourceId: String,
        sourceType: Message.SourceType,
        isSuccess: Bool,
        needAuthentication: Bool = true,
        downloadFileScene: RustPB.Media_V1_DownloadFileScene?
    ) {
        self.init(
            content: content,
            messageId: messageId,
            channelId: channelId,
            sourceId: sourceId,
            sourceType: sourceType,
            isSuccess: isSuccess,
            needAuthentication: needAuthentication,
            downloadFileScene: downloadFileScene
        )
        self.fatherMFId = fatherMFId
        self.replyThreadRootId = replyThreadRootId
        self.messageRiskObjectKeys = messageRiskObjectKeys
    }

    public init(
        mediaProperty: RustPB.Basic_V1_RichTextElement.MediaProperty,
        messageId: String,
        messageRiskObjectKeys: [String],
        fatherMFId: String?,
        replyThreadRootId: String?,
        channelId: String,
        sourceId: String,
        sourceType: Message.SourceType,
        authToken: String?,
        needAuthentication: Bool = true,
        downloadFileScene: RustPB.Media_V1_DownloadFileScene?) {
            self.init(
                mediaProperty: mediaProperty,
                messageId: messageId,
                channelId: channelId,
                sourceId: sourceId,
                sourceType: sourceType,
                authToken: authToken,
                needAuthentication: needAuthentication,
                downloadFileScene: downloadFileScene)
            self.fatherMFId = fatherMFId
            self.replyThreadRootId = replyThreadRootId
            self.messageRiskObjectKeys = messageRiskObjectKeys
        }

    public init(
        mediaProperty: RustPB.Basic_V1_RichTextElement.MediaProperty,
        messageId: String,
        messageRiskObjectKeys: [String] = [],
        channelId: String,
        sourceId: String,
        sourceType: Message.SourceType,
        authToken: String?,
        needAuthentication: Bool = true,
        downloadFileScene: RustPB.Media_V1_DownloadFileScene?) {
        self.key = mediaProperty.key
        self.videoCoverKey = mediaProperty.image.origin.key
        self.videoCoverImage = mediaProperty.image
        self.url = Self.getUrl(url: mediaProperty.url, downloadFileScene: downloadFileScene)
        self.videoCoverUrl = mediaProperty.image.origin.firstUrl
        self.size = Float(mediaProperty.size / 1024 / 1024)
        self.localPath = mediaProperty.originPath // FIXME: 成功 compress 失败 origin
        self.messageId = messageId
        self.messageRiskObjectKeys = messageRiskObjectKeys
        self.channelId = channelId
        self.sourceId = sourceId
        self.sourceType = sourceType
        self.authToken = authToken
        self.needAuthentication = true
        self.downloadFileScene = downloadFileScene
        self.duration = mediaProperty.duration
        self.isPCOriginVideo = false
    }

    public init(
        key: String,
        videoKey: String,
        coverImage: ImageSet,
        url: String,
        videoCoverUrl: String,
        localPath: String,
        size: Float,
        messageId: String,
        messageRiskObjectKeys: [String] = [],
        channelId: String,
        sourceId: String,
        sourceType: Message.SourceType,
        needAuthentication: Bool = true,
        downloadFileScene: RustPB.Media_V1_DownloadFileScene?,
        duration: Int32,
        isPCOriginVideo: Bool) {
        self.key = key
        self.videoCoverKey = videoKey
        self.videoCoverImage = coverImage
        self.url = Self.getUrl(url: url, downloadFileScene: downloadFileScene)
        self.videoCoverUrl = videoCoverUrl
        self.localPath = localPath
        self.size = size
        self.messageId = messageId
        self.messageRiskObjectKeys = messageRiskObjectKeys
        self.channelId = channelId
        self.sourceId = sourceId
        self.sourceType = sourceType
        self.needAuthentication = needAuthentication
        self.downloadFileScene = downloadFileScene
        self.duration = duration
        self.isPCOriginVideo = isPCOriginVideo
    }

    private static func getUrl(url: String, downloadFileScene: RustPB.Media_V1_DownloadFileScene?) -> String {
        if let downloadFileScene = downloadFileScene {
            // 主要用于ttPlayer，传给 ttPlayer 的url需要加上downloadFileScene用来鉴权/下载
            return url.appending("&scene=\(downloadFileScene.rawValue)")
        } else {
            return url
        }
    }
}

/// 与Asset一一绑定的翻译属性
/// origin: 原asset
/// translated: 是别的asset的翻译态asset
public enum AssetTranslationProperty: String {
    case origin
    case translated
}

public struct Asset: Equatable {
    public var visibleThumbnail: UIImageView?
    public var originalUrl: String
    public var key: String
    public var fsUnit: String
    public var placeHolder: UIImage?
    public var sourceType: ImageAssetSourceType
    /// 原图的对应key
    public var originKey: String?
    /// inact图对应的key
    public var intactKey: String?
    /// 原图对应的大小
    public var originImageFileSize: UInt64 = 0
    /// 是否自动加载原图
    public var isAutoLoadOrigin: Bool = false
    /// 是否强制加载原图
    public var forceLoadOrigin: Bool = false

    public var videoUrl: String = ""
    public var videoCoverUrl: String = ""
    public var videoSize: Float = 0  //以 MB 为单位
    public var isVideo = false
    public var isVideoMuted = false
    public var isLocalVideoUrl = false
    public var videoId: String = ""
    public var translateProperty: AssetTranslationProperty = .origin
    public var detectCanTranslate: Bool = true
    /// 是否有预览权限
    public var permissionState: PermissionDisplayState = .allow
    public var duration: Int32 = 0
    public var extraInfo: [String: Any] = [:]
    // 当图片被展示的时候，此字段会被透传到image_load埋点的extra参数上
    public var trackExtraInfo: [String: Any] = [:]

    public init(
        visibleThumbnail: UIImageView? = nil,
        originalUrl: String = "",
        key: String = "",
        fsUnit: String = "",
        sourceType: ImageAssetSourceType
    ) {
        self.visibleThumbnail = visibleThumbnail
        self.originalUrl = originalUrl
        self.key = key
        self.fsUnit = fsUnit
        self.sourceType = sourceType
    }

    public static func == (lhs: Asset, rhs: Asset) -> Bool {
        return lhs.key == rhs.key
    }
}

/// 这么实现并不友好，这个符号不应该在LarkMessagerInterface中，但是Asset和LKDisplayAsset要同步一些extraInfo属性。两边需要使用同一个key，后续思路
/// 应该是全部迁移到LKAsset里面。
/// TODO：@黄浩庭
public let MessageRiskObjectKeys: String = "MessageRiskObjectKeys"

public extension Asset {
    var riskObjectKeys: [String] {
        get {
            return (extraInfo[MessageRiskObjectKeys] as? [String]) ?? []
        }
        set {
            extraInfo[MessageRiskObjectKeys] = newValue
        }
    }

    /// 添加对应点位的DLP检测信息
    mutating func addSecurityExtraInfo(for event: SecurityControlEvent, securityExtraInfo: SecurityExtraInfo) {
        var checkInfo = (self.extraInfo["DisplayAssetSecurityExtraInfoKey"] as? [SecurityControlEvent: SecurityExtraInfo]) ?? [:]
        checkInfo[event] = securityExtraInfo
        self.extraInfo["DisplayAssetSecurityExtraInfoKey"] = checkInfo
    }
}

public enum PreviewImagesFromWhere {
    case chatHistory
    case other
}

public struct SearchAssetInfo {
    public enum MessageType {
        case thread(postion: Int32, id: String)
        case message(postion: Int32, id: String)
    }
    public let asset: Asset
    public let messageType: MessageType

    public init(asset: Asset,
                messageType: MessageType) {
        self.asset = asset
        self.messageType = messageType
    }
}

public enum PreviewImagesScene {
    public static let chatIndentifier = "chat"
    public static let searchInChatIndentifier = "searchInChat"
    public static let chatAlbumIndentifier = "chatAlbum"
    public static let searchInThreadIndentifier = "searchInThread"
    public static let normalIndentifier = "normal"

    /// 会话
    case chat(chatId: String, chatType: Chat.TypeEnum?, assetPositionMap: [String: (position: Int32, id: String)])
    /// 会话内搜索
    case searchInChat(chatId: String, messageId: String, position: Int32, assetInfos: [SearchAssetInfo], currentAsset: Asset)
    /// 会话内图片查看器
    case chatAlbum(chatId: String, messageId: String, position: Int32, isMsgThread: Bool)
    /// 小组内搜索
    case searchInThread(chatId: String, messageID: String, threadID: String, position: Int32, assetInfos: [SearchAssetInfo], currentAsset: Asset)
    /// 其它带message信息预览，分享图片时会从此处获取图片对应的message：
    /// 1：能取到messageId，走转发消息逻辑；
    /// 2：1不成立，走发送消息逻辑。
    /// 注：如预览群头像等场景时，因为没有message信息和chatId信息，传空即可。
    case normal(assetPositionMap: [String: (position: Int32, id: String)], chatId: String?)

    public var indentifier: String {
        switch self {
        case .chat: return PreviewImagesScene.chatIndentifier
        case .searchInChat: return PreviewImagesScene.searchInChatIndentifier
        case .chatAlbum: return PreviewImagesScene.chatAlbumIndentifier
        case .searchInThread: return PreviewImagesScene.searchInThreadIndentifier
        case .normal: return PreviewImagesScene.normalIndentifier
        }
    }
}

public enum TranslateEntityType: Int {
    case other = 0 // 其他查看场景，比如收藏、pin等
    case message = 1 // 消息查看场景，比如chat、thread等
}

/// TranslateEntityContext = (entity_id, entity_type)
/// 如在消息场景中，entity_id为message_id，entity_type为.message
public typealias TranslateEntityContext = (String?, TranslateEntityType)

// 埋点信息收敛
public struct PreviewImageTrackInfo {
    public var messageID: String = ""
    public var scene: Scene = .Chat

    public init(scene: Scene = .Chat, messageID: String? = nil) {
        self.scene = scene
        self.messageID = messageID ?? ""
    }
}

public struct PreviewImagesBody: PlainBody {
    public static let pattern = "//client/preview/images"

    public let assets: [Asset]
    public let pageIndex: Int
    public let scene: PreviewImagesScene
    /// 是否要对文件资源进行安全检测
    public let shouldDetectFile: Bool
    public let trackInfo: PreviewImageTrackInfo?
    public var hideSavePhotoBut: Bool = false
    public var showSaveToCloud: Bool?
    public var showImageOnly: Bool
    public var canSaveImage: Bool
    public var canEditImage: Bool
    public var canShareImage: Bool
    public var canTranslate: Bool
    public var canViewInChat: Bool
    public let translateEntityContext: TranslateEntityContext
    public var canImageOCR: Bool
    public let dismissCallback: (() -> Void)?
    public let buttonType: LKAssetBrowserViewController.ButtonType
    public let showAddToSticker: Bool
    public var customTransition: LKAssetBrowserTransitionProvider?
    public let session: String?
    public let videoShowMoreButton: Bool

    /// 构造 PreviewImagesBody
    ///
    /// - Parameters:
    ///   - assets: [Asset] 资源数组
    ///   - pageIndex: Int
    ///   - scene: PreviewImagesScene
    ///   - canEditImage: 是否能够编辑图片，gif不支持编辑
    ///   - canShareImage: 是否能够分享图片
    ///   - hideSavePhotoBut: Bool 隐藏保存照片按钮
    ///   - showSaveToCloud: Bool? 显示保存到云盘按钮 默认：nil 由内部isByteDancer决定。
    public init(
        assets: [Asset],
        pageIndex: Int,
        scene: PreviewImagesScene,
        trackInfo: PreviewImageTrackInfo? = nil,
        shouldDetectFile: Bool,
        canSaveImage: Bool = true,
        canShareImage: Bool = true,
        canEditImage: Bool = true,
        hideSavePhotoBut: Bool = false,
        showSaveToCloud: Bool? = nil,
        showImageOnly: Bool = false,
        canTranslate: Bool,
        translateEntityContext: TranslateEntityContext,
        dismissCallback: (() -> Void)? = nil,
        buttonType: LKAssetBrowserViewController.ButtonType = .onlySave,
        showAddToSticker: Bool = false
    ) {
        self.init(assets: assets,
                  pageIndex: pageIndex,
                  scene: scene,
                  trackInfo: trackInfo,
                  shouldDetectFile: shouldDetectFile,
                  canSaveImage: canSaveImage,
                  canShareImage: canShareImage,
                  canEditImage: canEditImage,
                  hideSavePhotoBut: hideSavePhotoBut,
                  showSaveToCloud: showSaveToCloud,
                  showImageOnly: showImageOnly,
                  canTranslate: canTranslate,
                  translateEntityContext: translateEntityContext,
                  canImageOCR: false,
                  dismissCallback: dismissCallback,
                  buttonType: buttonType,
                  showAddToSticker: showAddToSticker,
                  session: nil,
                  videoShowMoreButton: true)
    }

    // 二进制兼容保留
    public init(
        assets: [Asset],
        pageIndex: Int,
        scene: PreviewImagesScene,
        shouldDetectFile: Bool,
        canSaveImage: Bool = true,
        canShareImage: Bool = true,
        canEditImage: Bool = true,
        hideSavePhotoBut: Bool = false,
        showSaveToCloud: Bool? = nil,
        showImageOnly: Bool = false,
        canTranslate: Bool,
        translateEntityContext: TranslateEntityContext,
        dismissCallback: (() -> Void)? = nil,
        buttonType: LKAssetBrowserViewController.ButtonType = .onlySave,
        showAddToSticker: Bool = false
    ) {
        self.init(assets: assets,
                  pageIndex: pageIndex,
                  scene: scene,
                  shouldDetectFile: shouldDetectFile,
                  canSaveImage: canSaveImage,
                  canShareImage: canShareImage,
                  canEditImage: canEditImage,
                  hideSavePhotoBut: hideSavePhotoBut,
                  showSaveToCloud: showSaveToCloud,
                  showImageOnly: showImageOnly,
                  canTranslate: canTranslate,
                  translateEntityContext: translateEntityContext,
                  canImageOCR: false,
                  dismissCallback: dismissCallback,
                  buttonType: buttonType,
                  showAddToSticker: showAddToSticker,
                  session: nil,
                  videoShowMoreButton: true)
    }

    // 二进制兼容保留
    public init(
        assets: [Asset],
        pageIndex: Int,
        scene: PreviewImagesScene,
        trackInfo: PreviewImageTrackInfo? = nil,
        shouldDetectFile: Bool,
        canSaveImage: Bool = true,
        canShareImage: Bool = true,
        canEditImage: Bool = true,
        hideSavePhotoBut: Bool = false,
        showSaveToCloud: Bool? = nil,
        showImageOnly: Bool = false,
        canTranslate: Bool,
        translateEntityContext: TranslateEntityContext,
        dismissCallback: (() -> Void)? = nil,
        buttonType: LKAssetBrowserViewController.ButtonType = .onlySave,
        showAddToSticker: Bool = false,
        session: String?,
        videoShowMoreButton: Bool = true
    ) {
        self.init(assets: assets,
                  pageIndex: pageIndex,
                  scene: scene,
                  trackInfo: trackInfo,
                  shouldDetectFile: shouldDetectFile,
                  canSaveImage: canSaveImage,
                  canShareImage: canShareImage,
                  canEditImage: canEditImage,
                  hideSavePhotoBut: hideSavePhotoBut,
                  showSaveToCloud: showSaveToCloud,
                  showImageOnly: showImageOnly,
                  canTranslate: canTranslate,
                  translateEntityContext: translateEntityContext,
                  canImageOCR: false,
                  dismissCallback: dismissCallback,
                  buttonType: buttonType,
                  showAddToSticker: showAddToSticker,
                  session: session,
                  videoShowMoreButton: videoShowMoreButton)
    }

    // 二进制兼容保留
    public init(
        assets: [Asset],
        pageIndex: Int,
        scene: PreviewImagesScene,
        trackInfo: PreviewImageTrackInfo? = nil,
        shouldDetectFile: Bool,
        canSaveImage: Bool = true,
        canShareImage: Bool = true,
        canEditImage: Bool = true,
        hideSavePhotoBut: Bool = false,
        showSaveToCloud: Bool? = nil,
        showImageOnly: Bool = false,
        canTranslate: Bool,
        canViewInChat: Bool = true,
        translateEntityContext: TranslateEntityContext,
        canImageOCR: Bool,
        dismissCallback: (() -> Void)? = nil,
        buttonType: LKAssetBrowserViewController.ButtonType = .onlySave,
        showAddToSticker: Bool = false,
        session: String? = nil,
        videoShowMoreButton: Bool = true
    ) {
        self.showSaveToCloud = showSaveToCloud
        self.assets = assets
        self.pageIndex = pageIndex
        self.scene = scene
        self.trackInfo = trackInfo
        self.shouldDetectFile = shouldDetectFile
        self.canSaveImage = canSaveImage
        self.canShareImage = canShareImage
        self.canEditImage = canEditImage
        self.hideSavePhotoBut = hideSavePhotoBut
        self.showImageOnly = showImageOnly
        self.canTranslate = canTranslate
        self.canViewInChat = canViewInChat
        self.canImageOCR = canImageOCR
        self.translateEntityContext = translateEntityContext
        self.dismissCallback = dismissCallback
        self.buttonType = buttonType
        self.showAddToSticker = showAddToSticker
        self.session = session
        self.videoShowMoreButton = videoShowMoreButton
    }
}

// 上传图片
public struct UploadImageBody: PlainBody {
    public static let pattern = "//client/upload/image"

    public let multiple: Bool
    public let max: Int
    public var uploadSuccess: (([String]) -> Void)?

    public init(multiple: Bool, max: Int) {
        self.multiple = multiple
        self.max = max
    }
}

public enum PreviewAvatarScene {
    // 个性化头像
    case personalizedAvatar
    case simple
}

// 预览我的头像（支持修改）
public struct PreviewAvatarBody: PlainBody {
    public static let pattern = "//client/preview/avatar"

    public let avatarKey: String
    public let scene: PreviewAvatarScene
    public let supportReset: Bool
    public let entityId: String

    public init(avatarKey: String,
                entityId: String,
                supportReset: Bool = false,
                scene: PreviewAvatarScene = .simple) {
        self.avatarKey = avatarKey
        self.supportReset = supportReset
        self.entityId = entityId
        self.scene = scene
    }
}

public enum ImageLoadSettingType {
    case face
    case image
    case background // 背景图片
}

// 预览群头像
public struct SettingSingeImageBody: PlainBody {
    public static let pattern = "//client/Setting/SingeImage"
    public let asset: Asset
    public let updateCallback: ((imageData: Data?, image: UIImage, isOrigin: Bool)) -> Observable<[String]>
    public let showUploadCallback: (() -> Void)?
    public let actionCallback: ((_ isPhoto: Bool?) -> Void)?
    public let modifyAvatarString: String?
    public let type: ImageLoadSettingType
    public let editConfig: CropperConfigure

    public init(
        asset: Asset,
        modifyAvatarString: String? = nil,
        type: ImageLoadSettingType = .face,
        editConfig: CropperConfigure = .default,
        showUploadCallback: (() -> Void)? = nil,
        actionCallback: ((_ isPhoto: Bool?) -> Void)? = nil,
        updateCallback: @escaping ((Data?, UIImage, Bool)) -> Observable<[String]>
    ) {
        self.asset = asset
        self.type = type
        self.editConfig = editConfig
        self.updateCallback = updateCallback
        self.modifyAvatarString = modifyAvatarString
        self.showUploadCallback = showUploadCallback
        self.actionCallback = actionCallback
    }
}
