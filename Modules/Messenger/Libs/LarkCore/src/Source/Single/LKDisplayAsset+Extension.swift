//
//  LKDisplayAsset+Extension.swift
//  LarkCore
//
//  Created by liuwanlin on 2018/8/9.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import LarkMessengerInterface
import ByteWebImage
import LarkSDKInterface
import LarkFeatureGating
@_exported import LarkAssetsBrowser
@_exported import LarkImageEditor
import RustPB
import LKCommonsLogging

private typealias Path = LarkSDKInterface.PathWrapper

public let DisplayAssetSecurityExtraInfoKey: String = "DisplayAssetSecurityExtraInfoKey"
public let ImageAssetExtraInfo: String = "ImageAssetExtraInfo"
public let ImageAssetMessageIdKey: String = "ImageAssetMessageIdKey"
public let ImageAssetFatherMFIdKey: String = "ImageAssetFatherMFIdKey"
public let ImageAssetReplyThreadRootIdKey: String = "ImageAssetReplyThreadRootIdKey"
public let TranslateAssetExtraInfo: String = "TranslateAssetExtraInfo"
public let ImageAssetDownloadSceneKey: String = "ImageAssetDownloadSceneKey"

public enum LKImageAssetSourceType {
    /// 图片消息
    case image(ImageSet)
    /// 视频消息/富文本中的视频
    case video(MediaInfoItem)
    /// 表情
    case sticker(stickerSetID: String)
    /// 富文本中的图片
    case post(RustPB.Basic_V1_RichTextElement.ImageProperty)
    /// 头像
    case avatar(avatarViewParams: AvatarViewParams?, entityId: String?)
    /// 其他
    case other
}
// 用于LKDisplayAsset extra字段，翻译需要的扩展字段放入其中
struct TranslateDisplayAsset {
    public let translatedToOriginal: String?
    public let entityID: String?
    public let entityType: TranslateEntityType?
    public init(translatedToOriginal: String? = nil, entityID: String? = nil, entityType: TranslateEntityType? = nil) {
        self.translatedToOriginal = translatedToOriginal
        self.entityID = entityID
        self.entityType = entityType
    }
}

public struct CreateAssetsResult {
    public let assets: [LKDisplayAsset]
    public let selectIndex: Int?
    /// [asset.key: (消息position, 消息id)]
    public let assetPositionMap: [String: (position: Int32, id: String)]
    public init(assets: [LKDisplayAsset], selectIndex: Int?, assetPositionMap: [String: (position: Int32, id: String)]) {
        self.assets = assets
        self.selectIndex = selectIndex
        self.assetPositionMap = assetPositionMap
    }
}

private final class Log {
    static let logger = Logger.log(LKDisplayAsset.self, category: "LarkCore.LKDisplayAsset.Extension")
}

private extension LKDisplayAsset {

    static func createAsset(
        postMediaProperty: RustPB.Basic_V1_RichTextElement.MediaProperty,
        mediaInfo: MediaInfoItem,
        downloadScene: RustPB.Media_V1_DownloadFileScene? = nil,
        permissionState: PermissionDisplayState = .allow) -> LKDisplayAsset {
        var url: String = postMediaProperty.url
        var isLocalVideoUrl = false
        // 本地沙盒中是否有该文件
        if let path = replacePathHomeDirectory(with: postMediaProperty.originPath),
           Path(path).exists {
            url = path
            isLocalVideoUrl = true
        }

        let asset = LKDisplayAsset.initWith(
            videoUrl: url,
            videoCoverUrl: postMediaProperty.image.key,
            videoSize: Float(postMediaProperty.size / 1024 / 1024))
        asset.key = postMediaProperty.image.origin.key
        asset.placeHolder = try? ByteImage(postMediaProperty.image.inlinePreview)
        asset.permissionState = permissionState
        asset.isLocalVideoUrl = isLocalVideoUrl
        asset.extraInfo = [ImageAssetExtraInfo: LKImageAssetSourceType.video(mediaInfo),
                         ImageAssetFromTypeKey: TrackInfo.FromType.media]
        if let downloadScene = downloadScene {
            asset.extraInfo[ImageAssetDownloadSceneKey] = downloadScene
        }
        asset.duration = postMediaProperty.duration
        return asset
    }

    /// 有内存小图取小图，无小图取 inline preview
    static func getPlaceholder(with imageSet: ImageSet?) -> UIImage? {
        guard let imageSet = imageSet else {
            Log.logger.info("received empty imageSet, return nil")
            return nil
        }
        let thumbKey = ImageItemSet.transform(imageSet: imageSet).generateImageMessageKey(forceOrigin: false)
        if let image = LarkImageService.shared.image(with: .default(key: thumbKey), cacheOptions: .memory) {
            Log.logger.info("return thumbnail image with key: \(imageSet.key), \(thumbKey).")
            return image
        } else if !imageSet.inlinePreview.isEmpty {
            if let image = try? ByteImage(imageSet.inlinePreview) {
                Log.logger.info("return inlinePreview image with key: \(imageSet.key).")
                return image
            } else {
                Log.logger.warn("failed to convert imageData to image with key: \(imageSet.key).")
                return nil
            }
        } else {
            Log.logger.warn("inlinePreview is empty, return nil with key: \(imageSet.key).")
            return nil
        }
    }

    static func getAllImageProperties(richText: RustPB.Basic_V1_RichText, imageKey: String) -> ([RustPB.Basic_V1_RichTextElement.ImageProperty], Int) {
        let imageProperties = richText.imageIds.compactMap({ (id) -> RustPB.Basic_V1_RichTextElement.ImageProperty? in
            guard let imageProperty = richText.elements[id]?.property.image, imageProperty.imgCanPreview else {
                return nil
            }
            return imageProperty
        })
        let index = imageProperties.firstIndex { (property) -> Bool in
            return property.originKey == imageKey
        }
        return (imageProperties, index ?? 0)
    }

    /// 解析RustPB.Basic_V1_RichText,将所有叶子结点有序输出
    static func parseRichText(elements: [String: RustPB.Basic_V1_RichTextElement], elementIds: [String], leafs: inout [RustPB.Basic_V1_RichTextElement]) {
        for elementId in elementIds {
            if let element = elements[elementId] {
                if element.childIds.isEmpty {
                    leafs.append(element)
                } else {
                    parseRichText(elements: elements, elementIds: element.childIds, leafs: &leafs)
                }
            }
        }
    }

    /// 将路径中 HomeDirectory 替换为 当前 HomeDirectory
    ///
    /// - Parameter path: 绝对路径
    /// - Returns: 替换后的路径，替换失败返回nil
    static func replacePathHomeDirectory(with path: String?) -> String? {
        guard let path = path, !path.isEmpty else { return nil }
        return VideoCacheConfig.replaceHomeDirectory(forPath: path)
    }
}

public extension LKDisplayAsset {
    var riskObjectKeys: [String] {
        get {
            return (extraInfo[MessageRiskObjectKeys] as? [String]) ?? []
        }
        set {
            extraInfo[MessageRiskObjectKeys] = newValue
        }
    }

    /// 获取对应点位的DLP检测信息
    func securityExtraInfo(for event: SecurityControlEvent) -> SecurityExtraInfo? {
        guard let checkInfo = self.extraInfo[DisplayAssetSecurityExtraInfoKey] as? [SecurityControlEvent: SecurityExtraInfo] else { return nil }
        return checkInfo[event]
    }

    /// 添加对应点位的DLP检测信息
    func addSecurityExtraInfo(for event: SecurityControlEvent, securityExtraInfo: SecurityExtraInfo) {
        var checkInfo = (self.extraInfo[DisplayAssetSecurityExtraInfoKey] as? [SecurityControlEvent: SecurityExtraInfo]) ?? [:]
        checkInfo[event] = securityExtraInfo
        self.extraInfo[DisplayAssetSecurityExtraInfoKey] = checkInfo
    }

    /// 这个好像没地方使用了！！！
    static func createAsset(
        message: LarkModel.Message,
        richText: RustPB.Basic_V1_RichText,
        imageKey: String,
        isMeSend: (String) -> Bool,
        downloadScene: RustPB.Media_V1_DownloadFileScene? = nil
    ) -> CreateAssetsResult {
        guard !message.isDeleted && !message.isRecalled && !message.isSecretChatDecryptedFailed else {
            return CreateAssetsResult(assets: [], selectIndex: 0, assetPositionMap: [:])
        }

        var assets: [LKDisplayAsset] = []
        var assetPositionMap: [String: (position: Int32, id: String)] = [:]
        let (imageProperties, index) = self.getAllImageProperties(richText: richText, imageKey: imageKey)
        imageProperties.forEach { (imageProperty) in
            let imageAsset = self.createAsset(
                postImageProperty: imageProperty,
                isTranslated: false,
                isAutoLoadOrigin: isMeSend(message.fromId),
                downloadScene: downloadScene,
                message: message
            )
            imageAsset.detectCanTranslate = message.localStatus == .success
            imageAsset.trackExtraInfo = ["message_id": message.id, "is_message_delete": message.isDeleted]
            imageAsset.extraInfo[ImageAssetMessageIdKey] = message.id
            imageAsset.extraInfo[ImageAssetFatherMFIdKey] = message.fatherMFMessage?.id
            imageAsset.extraInfo[ImageAssetReplyThreadRootIdKey] = message.threadMessageType == .threadReplyMessage ? message.rootId : nil
            imageAsset.riskObjectKeys = message.riskObjectKeys
            assets.append(imageAsset)
            assetPositionMap[imageAsset.key] = (message.position, message.id)
        }
        return CreateAssetsResult(assets: assets, selectIndex: index, assetPositionMap: assetPositionMap)
    }

    // nolint: long_function,duplicated_code
    static func createAssetExceptForSticker(
        messages: [LarkModel.Message],
        selected id: String,
        cid: String,
        downloadFileScene: RustPB.Media_V1_DownloadFileScene? = nil,
        isMeSend: (String) -> Bool,
        checkPreviewPermission: (Message) -> PermissionDisplayState = { _ in return .allow },
        chat: Chat? = nil) -> CreateAssetsResult {
        let messages = messages.filter { !$0.isDeleted && !$0.isRecalled }
        var currentIndex: Int = 0
        var index: Int?
        var assets: [LKDisplayAsset] = []
        var assetPositionMap: [String: (position: Int32, id: String)] = [:]

        messages.forEach { (message) in
            let isFileDeleted = message.fileDeletedStatus != .normal
            if var imageContent = message.content as? LarkModel.ImageContent {
                var isTranslated: Bool = false
                switch message.displayRule {
                case .onlyTranslation, .withOriginal:
                    /// 纯图片理论上没有翻译对照，因此该模式下也一定会传入译图到查看器
                    if let translatedContent = message.translateContent as? LarkModel.ImageContent {
                        imageContent = translatedContent
                        isTranslated = true
                    }
                case .noTranslation, .unknownRule: break
                @unknown default: break
                }
                if message.id == id, message.cid == cid {
                    index = currentIndex
                }
                currentIndex += 1
                let asset = self.asset(
                    with: imageContent.image,
                    isTranslated: isTranslated,
                    isOriginSource: imageContent.isOriginSource,
                    originSize: imageContent.originFileSize,
                    isAutoLoadOrigin: isMeSend(message.fromId),
                    downloadScene: downloadFileScene,
                    permissionState: checkPreviewPermission(message),
                    message: message,
                    chat: chat
                )
                assetPositionMap[asset.key] = (position: message.position, id: message.id)
                asset.detectCanTranslate = message.localStatus == .success
                asset.extraInfo[ImageAssetMessageIdKey] = message.id
                asset.addSecurityExtraInfo(for: .saveImage, securityExtraInfo: SecurityExtraInfo(fileKey: imageContent.image.origin.key, message: message, chat: chat))
                asset.extraInfo[ImageAssetFatherMFIdKey] = message.fatherMFMessage?.id
                asset.extraInfo[ImageAssetReplyThreadRootIdKey] = message.threadMessageType == .threadReplyMessage ? message.rootId : nil
                asset.riskObjectKeys = message.riskObjectKeys
                asset.trackExtraInfo = ["message_id": message.id, "is_message_delete": message.isDeleted]
                assets.append(asset)
            } else if let mediaContent = message.content as? LarkModel.MediaContent,
                !isFileDeleted {   // 转发，文件被删了不可预览
                if message.id == id, message.cid == cid {
                    index = currentIndex
                }
                currentIndex += 1

                let item = MediaInfoItem(
                    content: mediaContent,
                    messageId: message.id,
                    messageRiskObjectKeys: message.riskObjectKeys,
                    fatherMFId: message.fatherMFMessage?.id,
                    replyThreadRootId: message.threadMessageType == .threadReplyMessage ? message.rootId : nil,
                    channelId: message.channel.id,
                    sourceId: message.sourceID,
                    sourceType: message.sourceType,
                    isSuccess: message.localStatus == .success,
                    downloadFileScene: downloadFileScene
                )

                let asset = self.asset(with: item, downloadScene: downloadFileScene, message: message, permissionState: checkPreviewPermission(message))
                assetPositionMap[asset.key] = (position: message.position, id: message.id)
                asset.detectCanTranslate = false
                asset.trackExtraInfo = ["message_id": message.id, "is_message_delete": message.isDeleted]
                asset.addSecurityExtraInfo(for: .saveVideo, securityExtraInfo: SecurityExtraInfo(message: message))
                assets.append(asset)
            } else if let postContent = message.content as? LarkModel.PostContent {
                let imageTranslationInfo = (message.translateContent as? PostContent)?.imageTranslationInfo
                let richText = postContent.richText
                var leafs: [RustPB.Basic_V1_RichTextElement] = []
                parseRichText(elements: richText.elements, elementIds: richText.elementIds, leafs: &leafs)
                for element in leafs {
                    if element.tag == .media {
                        let mediaProperty = element.property.media
                        let mediaInfo = MediaInfoItem(
                            mediaProperty: mediaProperty,
                            messageId: message.id,
                            messageRiskObjectKeys: message.riskObjectKeys,
                            fatherMFId: message.fatherMFMessage?.id,
                            replyThreadRootId: message.threadMessageType == .threadReplyMessage ? message.rootId : nil,
                            channelId: message.channel.id,
                            sourceId: message.sourceID,
                            sourceType: message.sourceType,
                            authToken: postContent.authToken,
                            downloadFileScene: downloadFileScene
                        )
                        let asset = LKDisplayAsset.createAsset(
                            postMediaProperty: mediaProperty,
                            mediaInfo: mediaInfo,
                            downloadScene: downloadFileScene,
                            permissionState: checkPreviewPermission(message)
                        )
                        asset.trackExtraInfo = ["message_id": message.id, "is_message_delete": message.isDeleted]
                        asset.addSecurityExtraInfo(for: .saveVideo, securityExtraInfo: SecurityExtraInfo(message: message))
                        currentIndex += 1
                        assetPositionMap[asset.key] = (position: message.position, id: message.id)
                        assets.append(asset)
                    } else if element.tag == .img {
                        var imageProperty = element.property.image
                        let imageKey = imageProperty.originKey.replacingOccurrences(of: "origin:", with: "", options: .regularExpression)
                        var isTranslated: Bool = false

                        func replaceImage() {
                            if let imageSet = imageTranslationInfo?.translatedImages[imageKey]?.translatedImageSet {
                                imageProperty = imageProperty.modifiedImageProperty(imageSet)
                                isTranslated = true
                            }
                        }
                        switch message.displayRule {
                        /// 该方法的调用假设是不会出现图片翻译对照(没有提供selectKey也无法计算)，直接取译图即可
                        case .onlyTranslation:
                            replaceImage()
                        case .withOriginal:
                            /// 先将原图加入图片浏览器
                            let asset = LKDisplayAsset.createAsset(
                                postImageProperty: imageProperty,
                                isTranslated: isTranslated,
                                isAutoLoadOrigin: isMeSend(message.fromId),
                                downloadScene: downloadFileScene,
                                permissionState: checkPreviewPermission(message),
                                message: message,
                                chat: chat
                            )
                            currentIndex += 1
                            assetPositionMap[asset.key] = (position: message.position, id: message.id)
                            asset.addSecurityExtraInfo(for: .saveImage, securityExtraInfo: SecurityExtraInfo(fileKey: imageKey, message: message, chat: chat))
                            asset.detectCanTranslate = message.localStatus == .success
                            asset.trackExtraInfo = ["message_id": message.id, "is_message_delete": message.isDeleted]
                            assets.append(asset)
                            /// 再将image更改为译图内容
                            replaceImage()
                        @unknown default: break
                        }

                        /// 再将译图加入图片浏览器
                        let asset = LKDisplayAsset.createAsset(
                            postImageProperty: imageProperty,
                            isTranslated: isTranslated,
                            isAutoLoadOrigin: isMeSend(message.fromId),
                            downloadScene: downloadFileScene,
                            permissionState: checkPreviewPermission(message),
                            message: message,
                            chat: chat
                        )
                        currentIndex += 1
                        assetPositionMap[asset.key] = (position: message.position, id: message.id)
                        asset.addSecurityExtraInfo(for: .saveImage, securityExtraInfo: SecurityExtraInfo(fileKey: imageKey, message: message, chat: chat))
                        asset.trackExtraInfo = ["message_id": message.id, "is_message_delete": message.isDeleted]
                        asset.detectCanTranslate = message.localStatus == .success
                        assets.append(asset)
                    }
                }
            }
        }
        return CreateAssetsResult(assets: assets, selectIndex: index, assetPositionMap: assetPositionMap)
    }
    // enable-lint: long_function,duplicated_code

    /**
     important：Sticker
     1 多次发送和转发同一张图片的，会生成不同的key，即每张图片的key是唯一的
     2 对于sticker类型的图片 多次发送之后，key相同，故不可以用来当做唯一的标识符
     TODO:@liluobin 此处为临时修复方案，将来整体对图片和sticker完善
     */
    static func createAssetForSticker(
        messages: [LarkModel.Message],
        currentMessage: LarkModel.Message,
        downloadScene: RustPB.Media_V1_DownloadFileScene? = nil
    ) -> CreateAssetsResult {
        var assets: [LKDisplayAsset] = []
        var stickerMessages: [LarkModel.Message] = []
        var assetPositionMap: [String: (position: Int32, id: String)] = [:]
        messages.filter { !$0.isDeleted && !$0.isRecalled }.forEach { (message) in
            guard let content = message.content as? StickerContent else { return }

            let asset = LKDisplayAsset()
            asset.key = content.key
            asset.originalImageKey = content.key
            asset.forceLoadOrigin = true
            asset.isAutoLoadOriginalImage = true
            asset.extraInfo = [ImageAssetExtraInfo: LKImageAssetSourceType.sticker(stickerSetID: content.stickerSetID),
                             ImageAssetFromTypeKey: TrackInfo.FromType.sticker]
            asset.extraInfo[ImageAssetMessageIdKey] = message.id
            asset.extraInfo[ImageAssetFatherMFIdKey] = message.fatherMFMessage?.id
            asset.extraInfo[ImageAssetReplyThreadRootIdKey] = message.threadMessageType == .threadReplyMessage ? message.rootId : nil
            if let downloadScene = downloadScene {
                asset.extraInfo[ImageAssetDownloadSceneKey] = downloadScene
            }
            asset.trackExtraInfo = ["message_id": currentMessage.id, "is_message_delete": currentMessage.isDeleted]
            asset.detectCanTranslate = message.localStatus == .success
            assets.append(asset)
            assetPositionMap[asset.key] = (message.position, message.id)
            stickerMessages.append(message)
        }
        let selectIndex = stickerMessages.firstIndex { $0.id == currentMessage.id }
        return CreateAssetsResult(assets: assets, selectIndex: selectIndex, assetPositionMap: assetPositionMap)
    }

    // nolint: long_function
    static func createAssetExceptForSticker(messages: [LarkModel.Message],
                                            selectedKey: String = "",
                                            mergeForwardOriginID: String? = nil,
                                            downloadFileScene: RustPB.Media_V1_DownloadFileScene? = nil,
                                            isMeSend: (String) -> Bool,
                                            checkPreviewPermission: (Message) -> PermissionDisplayState = { _ in return .allow },
                                            chat: Chat? = nil) -> CreateAssetsResult {
        let messages = messages.filter { !$0.isDeleted && !$0.isRecalled }
        var currentIndex: Int = 0
        var index: Int = 0
        var assets: [LKDisplayAsset] = []
        var assetPositionMap: [String: (position: Int32, id: String)] = [:]
        messages.forEach { (message) in
            let isFileDeleted = message.fileDeletedStatus != .normal
            if var imageContent = message.content as? LarkModel.ImageContent {
                var isTranslated: Bool = false
                switch message.displayRule {
                case .onlyTranslation, .withOriginal:
                    /// 纯图片理论上没有翻译对照，因此该模式下也一定传入译图到查看器
                    if let translatedContent = message.translateContent as? LarkModel.ImageContent {
                        imageContent = translatedContent
                        isTranslated = true
                    }
                case .noTranslation, .unknownRule: break
                @unknown default: break
                }
                if imageContent.image.key == selectedKey {
                    index = currentIndex
                }
                currentIndex += 1
                let asset = self.asset(
                    with: imageContent.image,
                    isTranslated: isTranslated,
                    isOriginSource: imageContent.isOriginSource,
                    originSize: imageContent.originFileSize,
                    isAutoLoadOrigin: isMeSend(message.fromId),
                    downloadScene: downloadFileScene,
                    permissionState: checkPreviewPermission(message),
                    message: message,
                    chat: chat
                )
                assetPositionMap[asset.key] = (position: message.position, id: message.id)
                asset.detectCanTranslate = message.localStatus == .success
                asset.addSecurityExtraInfo(for: .saveImage, securityExtraInfo: SecurityExtraInfo(fileKey: imageContent.image.origin.key, message: message, chat: chat))
                asset.extraInfo[ImageAssetMessageIdKey] = message.id
                asset.extraInfo[ImageAssetFatherMFIdKey] = message.fatherMFMessage?.id
                asset.extraInfo[ImageAssetReplyThreadRootIdKey] = message.threadMessageType == .threadReplyMessage ? message.rootId : nil
                asset.riskObjectKeys = message.riskObjectKeys
                asset.trackExtraInfo = ["message_id": message.id, "is_message_delete": message.isDeleted]
                assets.append(asset)
            } else if let mediaContent = message.content as? LarkModel.MediaContent, !isFileDeleted {
                // 转发，文件被删了不可预览
                if mediaContent.key == selectedKey {
                    index = currentIndex
                }

                currentIndex += 1
                let item = MediaInfoItem(
                    content: mediaContent,
                    messageId: message.id,
                    messageRiskObjectKeys: message.riskObjectKeys,
                    fatherMFId: message.fatherMFMessage?.id,
                    replyThreadRootId: message.threadMessageType == .threadReplyMessage ? message.rootId : nil,
                    channelId: message.channel.id,
                    sourceId: message.sourceID,
                    sourceType: message.sourceType,
                    isSuccess: message.localStatus == .success,
                    downloadFileScene: downloadFileScene
                )

                let asset = self.asset(with: item, downloadScene: downloadFileScene, message: message, permissionState: checkPreviewPermission(message))
                asset.trackExtraInfo = ["message_id": message.id, "is_message_delete": message.isDeleted]
                asset.addSecurityExtraInfo(for: .saveVideo, securityExtraInfo: SecurityExtraInfo(message: message))
                asset.detectCanTranslate = false
                assetPositionMap[asset.key] = (position: message.position, id: message.id)
                assets.append(asset)
            } else if let postContent = message.content as? LarkModel.PostContent {
                let imageTranslationInfo = (message.translateContent as? PostContent)?.imageTranslationInfo
                let richText = postContent.richText
                var leafs: [RustPB.Basic_V1_RichTextElement] = []
                parseRichText(elements: richText.elements, elementIds: richText.elementIds, leafs: &leafs)
                for element in leafs {
                    if element.tag == .media {
                        let mediaProperty = element.property.media
                        let mediaInfo = MediaInfoItem(
                            mediaProperty: mediaProperty,
                            messageId: message.id,
                            messageRiskObjectKeys: message.riskObjectKeys,
                            fatherMFId: message.fatherMFMessage?.id,
                            replyThreadRootId: message.threadMessageType == .threadReplyMessage ? message.rootId : nil,
                            channelId: message.channel.id,
                            sourceId: mergeForwardOriginID ?? message.sourceID,
                            sourceType: mergeForwardOriginID == nil ? message.sourceType : .typeFromMergeforward,
                            authToken: postContent.authToken,
                            downloadFileScene: downloadFileScene
                        )
                        let asset = LKDisplayAsset.createAsset(
                            postMediaProperty: mediaProperty,
                            mediaInfo: mediaInfo,
                            downloadScene: downloadFileScene,
                            permissionState: checkPreviewPermission(message)
                        )
                        if mediaProperty.key == selectedKey {
                            index = currentIndex
                        }
                        currentIndex += 1
                        asset.trackExtraInfo = ["message_id": message.id, "is_message_delete": message.isDeleted]
                        asset.addSecurityExtraInfo(for: .saveVideo, securityExtraInfo: SecurityExtraInfo(message: message))
                        assetPositionMap[asset.key] = (position: message.position, id: message.id)
                        asset.detectCanTranslate = false
                        assets.append(asset)
                    } else if element.tag == .img {
                        var imageProperty = element.property.image
                        let imageKey = imageProperty.originKey.replacingOccurrences(of: "origin:", with: "", options: .regularExpression)
                        var isTranslated: Bool = false

                        func replaceImage() {
                            if let imageSet = imageTranslationInfo?.translatedImages[imageKey]?.translatedImageSet {
                                imageProperty = imageProperty.modifiedImageProperty(imageSet)
                                isTranslated = true
                            }
                        }
                        switch message.displayRule {
                        case .onlyTranslation:
                            replaceImage()
                        case .withOriginal:
                            /// 先将原图加入图片浏览器，再将译图加入图片浏览器
                            let asset = LKDisplayAsset.createAsset(
                                postImageProperty: imageProperty,
                                isTranslated: isTranslated,
                                isAutoLoadOrigin: false,
                                downloadScene: downloadFileScene,
                                permissionState: checkPreviewPermission(message),
                                message: message,
                                chat: chat
                            )
                            if imageProperty.originKey == selectedKey {
                                index = currentIndex
                            }
                            currentIndex += 1
                            assetPositionMap[asset.key] = (position: message.position, id: message.id)
                            asset.addSecurityExtraInfo(for: .saveImage, securityExtraInfo: SecurityExtraInfo(fileKey: imageKey, message: message, chat: chat))
                            asset.detectCanTranslate = message.localStatus == .success
                            asset.trackExtraInfo = ["message_id": message.id, "is_message_delete": message.isDeleted]
                            assets.append(asset)
                            /// 再将image更改为译图内容
                            replaceImage()
                        @unknown default: break
                        }

                        /// 再将译图加入图片浏览器
                        let asset = LKDisplayAsset.createAsset(
                            postImageProperty: imageProperty,
                            isTranslated: isTranslated,
                            isAutoLoadOrigin: isMeSend(message.fromId),
                            downloadScene: downloadFileScene,
                            permissionState: checkPreviewPermission(message),
                            message: message,
                            chat: chat
                        )
                        asset.extraInfo[ImageAssetMessageIdKey] = message.id
                        asset.addSecurityExtraInfo(for: .saveImage, securityExtraInfo: SecurityExtraInfo(fileKey: imageKey, message: message, chat: chat))
                        asset.extraInfo[ImageAssetFatherMFIdKey] = message.fatherMFMessage?.id
                        asset.extraInfo[ImageAssetReplyThreadRootIdKey] = message.threadMessageType == .threadReplyMessage ? message.rootId : nil
                        asset.riskObjectKeys = message.riskObjectKeys
                        asset.trackExtraInfo = ["message_id": message.id, "is_message_delete": message.isDeleted]
                        if imageProperty.originKey == selectedKey {
                            index = currentIndex
                        }
                        currentIndex += 1
                        assetPositionMap[asset.key] = (position: message.position, id: message.id)
                        asset.detectCanTranslate = message.localStatus == .success
                        assets.append(asset)
                    }
                }
            }
        }
        return CreateAssetsResult(assets: assets, selectIndex: index, assetPositionMap: assetPositionMap)
    }
    // enable-lint: long_function

    static func createAsset(
        postImageProperty: RustPB.Basic_V1_RichTextElement.ImageProperty,
        isTranslated: Bool,
        isAutoLoadOrigin: Bool,
        downloadScene: RustPB.Media_V1_DownloadFileScene? = nil,
        permissionState: PermissionDisplayState = .allow,
        message: Message? = nil,
        chat: Chat? = nil
    ) -> LKDisplayAsset {
        let asset = LKDisplayAsset()
        asset.key = postImageProperty.middleKey
        asset.originalImageKey = postImageProperty.originKey
        asset.originalImageSize = postImageProperty.originSize
        if asset.originalImageSize <= LarkImageService.shared.imageDisplaySetting.largeImageLoad.remote.remoteAutoOriginMax {
            asset.forceLoadOrigin = true
            asset.isAutoLoadOriginalImage = true
        } else {
            asset.forceLoadOrigin = !postImageProperty.isOriginSource
            asset.isAutoLoadOriginalImage = isAutoLoadOrigin
        }
        asset.intactImageKey = postImageProperty.intact.key
        let imageItemSet = ImageItemSet.transform(imageProperty: postImageProperty)
        if let inlinePreview = imageItemSet.inlinePreview {
            asset.placeHolder = inlinePreview
        } else {
            // 如果FG关闭或则没有inline图，所以把 thumbnail 作为兜底显示内容
            let thumbKey = imageItemSet.generatePostMessageKey(forceOrigin: false)
            asset.placeHolder = LarkImageService.shared.image(with: .default(key: thumbKey), cacheOptions: .memory)
            Log.logger.info("for postImageProperty with thumbKey: \(thumbKey)")
        }
        Log.logger.info("set asset placeholder with non-empty image successful: \(asset.placeHolder != nil) ")
        asset.extraInfo = [ImageAssetExtraInfo: LKImageAssetSourceType.post(postImageProperty),
                         ImageAssetFromTypeKey: TrackInfo.FromType.post]
        if let downloadScene = downloadScene {
            asset.extraInfo[ImageAssetDownloadSceneKey] = downloadScene
        }
        asset.permissionState = permissionState
        asset.addSecurityExtraInfo(for: .saveImage, securityExtraInfo: SecurityExtraInfo(fileKey: postImageProperty.originKey, message: message, chat: chat))
        asset.translateProperty = isTranslated ? .translated : .origin
        return asset
    }

    static func asset(with imageSet: LarkModel.ImageSet,
                      isTranslated: Bool,
                      isOriginSource: Bool,
                      originSize: UInt64,
                      isAutoLoadOrigin: Bool,
                      downloadScene: RustPB.Media_V1_DownloadFileScene? = nil,
                      permissionState: PermissionDisplayState = .allow,
                      message: Message? = nil,
                      extraInfo: [String: Any] = [:],
                      chat: Chat? = nil) -> LKDisplayAsset {
        let asset = LKDisplayAsset()
        asset.key = imageSet.middle.key
        asset.originalImageKey = imageSet.origin.key
        asset.originalImageSize = originSize
        if asset.originalImageSize <= LarkImageService.shared.imageDisplaySetting.largeImageLoad.remote.remoteAutoOriginMax {
            asset.forceLoadOrigin = true
            asset.isAutoLoadOriginalImage = true
        } else {
            asset.forceLoadOrigin = !isOriginSource
            asset.isAutoLoadOriginalImage = isAutoLoadOrigin
        }
        asset.intactImageKey = imageSet.intact.key
        asset.placeHolder = getPlaceholder(with: imageSet)
        asset.extraInfo = extraInfo
        if let message = message {
            asset.extraInfo[ImageAssetMessageIdKey] = message.id
            asset.riskObjectKeys = message.riskObjectKeys
        }
        asset.extraInfo[ImageAssetExtraInfo] = LKImageAssetSourceType.image(imageSet)
        if let message = message {
            asset.extraInfo[ImageAssetMessageIdKey] = message.id
            asset.extraInfo[ImageAssetFatherMFIdKey] = message.fatherMFMessage?.id
            asset.extraInfo[ImageAssetReplyThreadRootIdKey] = message.threadMessageType == .threadReplyMessage ? message.rootId : nil
        }
        asset.extraInfo[ImageAssetFromTypeKey] = TrackInfo.FromType.image
        if let downloadScene = downloadScene {
            asset.extraInfo[ImageAssetDownloadSceneKey] = downloadScene
        }
        asset.permissionState = permissionState
        asset.addSecurityExtraInfo(for: .saveImage, securityExtraInfo: SecurityExtraInfo(fileKey: imageSet.origin.key, message: message, chat: chat))
        asset.translateProperty = isTranslated ? .translated : .origin
        return asset
    }

    static func asset(
        with mediaContent: MediaInfoItem,
        downloadScene: RustPB.Media_V1_DownloadFileScene? = nil,
        message: Message?,
        permissionState: PermissionDisplayState
    ) -> LKDisplayAsset {
        var url: String?
        var isLocalVideoUrl = false
        if let path = replacePathHomeDirectory(with: mediaContent.localPath),
           Path(path).exists {
            url = path
            isLocalVideoUrl = true
        }

        let asset = LKDisplayAsset.initWith(
            videoUrl: url ?? mediaContent.url,
            videoCoverUrl: mediaContent.videoCoverUrl,
            videoSize: mediaContent.size)
        asset.key = mediaContent.videoCoverKey
        asset.originalImageKey = mediaContent.videoCoverKey
        asset.isLocalVideoUrl = isLocalVideoUrl
        asset.extraInfo = [ImageAssetExtraInfo: LKImageAssetSourceType.video(mediaContent),
                         ImageAssetFromTypeKey: TrackInfo.FromType.media]
        if let downloadScene = downloadScene {
            asset.extraInfo[ImageAssetDownloadSceneKey] = downloadScene
        }
        asset.addSecurityExtraInfo(for: .saveVideo, securityExtraInfo: SecurityExtraInfo(message: message))
        asset.permissionState = permissionState
        asset.duration = mediaContent.duration
        asset.translateProperty = .origin
        asset.riskObjectKeys = mediaContent.messageRiskObjectKeys
        return asset
    }

    static func createAsset(
        avatarKey: String,
        avatarViewParams: AvatarViewParams? = nil,
        downloadScene: RustPB.Media_V1_DownloadFileScene? = nil,
        chatID: String? = nil) -> LKDisplayAsset {
        let asset = LKDisplayAsset()
        asset.key = avatarKey
        asset.originalImageKey = avatarKey
        asset.forceLoadOrigin = true
        asset.isAutoLoadOriginalImage = true
        asset.extraInfo = [ImageAssetExtraInfo: LKImageAssetSourceType.avatar(avatarViewParams: avatarViewParams, entityId: chatID),
                         ImageAssetFromTypeKey: TrackInfo.FromType.avatar]
        if let downloadScene = downloadScene {
            asset.extraInfo[ImageAssetDownloadSceneKey] = downloadScene
        }
        asset.translateProperty = .origin
        return asset
    }

    static func transform(sourceType: ImageAssetSourceType) -> LKImageAssetSourceType {
        switch sourceType {
        case .image(let content):
            return .image(content)
        case .video(let content):
            return .video(content)
        case .avatar(let params, let chatId):
            return .avatar(avatarViewParams: AvatarViewParams.transform(additionMap: params), entityId: chatId)
        case .other:
            return .other
        case .post(let property):
            return .post(property)
        case .sticker(let stickerSetID):
            return .sticker(stickerSetID: stickerSetID)
        }
    }

    func transform() -> Asset {
        let sourceType = self.transform(sourceType: (self.extraInfo[ImageAssetExtraInfo] as? LKImageAssetSourceType) ?? .other)
        var asset = Asset(sourceType: sourceType)
        if !self.isVideo {
            asset.originalUrl = self.originalUrl
        } else {
            asset.videoUrl = self.videoUrl
            asset.videoCoverUrl = self.videoCoverUrl
            asset.videoSize = self.videoSize
            asset.isVideo = true
            asset.isVideoMuted = self.isVideoMuted
            asset.isLocalVideoUrl = isLocalVideoUrl
            asset.duration = self.duration
        }
        asset.key = self.key
        asset.placeHolder = self.placeHolder
        asset.originKey = self.originalImageKey
        asset.intactKey = self.intactImageKey
        asset.originImageFileSize = self.originalImageSize
        asset.isAutoLoadOrigin = self.isAutoLoadOriginalImage
        asset.forceLoadOrigin = self.forceLoadOrigin
        asset.detectCanTranslate = self.detectCanTranslate
        asset.permissionState = self.permissionState
        asset.visibleThumbnail = self.visibleThumbnail
        asset.extraInfo = self.extraInfo
        asset.trackExtraInfo = self.trackExtraInfo
        asset.translateProperty = AssetTranslationProperty(rawValue: self.translateProperty.rawValue) ?? .origin

        return asset
    }

    func transform(sourceType: LKImageAssetSourceType) -> ImageAssetSourceType {
        switch sourceType {
        case .image(let content):
            return .image(content)
        case .video(let content):
            return .video(content)
        case .avatar(avatarViewParams: let params, let chatId):
            return .avatar(avatarViewParams: params?.transformDic(), entityId: chatId)
        case .other:
            return .other
        case .post(let property):
            return .post(property)
        case .sticker(let stickerSetID):
            return .sticker(stickerSetID: stickerSetID)
        }
    }
}
