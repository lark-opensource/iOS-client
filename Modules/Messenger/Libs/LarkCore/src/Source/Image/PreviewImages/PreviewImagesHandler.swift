//
//  PreviewImagesHandler.swift
//  Lark
//
//  Created by liuwanlin on 2018/8/17.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkUIKit
import LarkContainer
import Swinject
import LarkMessengerInterface
import RxSwift
import LarkModel
import EENavigator
import ByteWebImage
import UniverseDesignToast
import LarkAccountInterface
import LarkAssetsBrowser
import LarkQRCode
import RustPB
import LarkSetting
import LarkSDKInterface
import LarkExtensions
import AppReciableSDK
import LarkFeatureGating
import LarkRustClient
import LarkRichTextCore
import LKCommonsLogging
import LarkNavigator

class PreviewImagesHandler: UserTypedRouterHandler {
    public static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    @ScopedInjectedLazy private var qrCodeAnalysis: QRCodeAnalysisService?
    private static let logger = Logger.log(PreviewImagesHandler.self, category: "LarkCore")
    private var abilityHandlers: [String: PreviewImagesAbilityHandlerFactory]
    private var abilityHandler: PreviewImagesAbilityHandler?
    private var passThrough: ImagePassThrough?
    private var scene: PreviewImagesScene = .normal(assetPositionMap: [:], chatId: nil)
    private var fetchKeyWithCrypto: Bool

    private typealias TranslateCompletion = (LKDisplayAsset?, Error?) -> Void
    private typealias LanguageConflictSideEffect = (() -> Void)?
    @ScopedInjectedLazy private var rustService: SDKRustService?

    public override init(resolver: UserResolver) {
        fetchKeyWithCrypto = resolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "messenger.image.resource_not_found"))
        abilityHandlers = [PreviewImagesScene.chatIndentifier: PreviewImagesAbilityForChatHandlerFactory(),
                           PreviewImagesScene.searchInChatIndentifier: PreviewImagesAbilityForSearchInChatHandlerFactory(),
                           PreviewImagesScene.chatAlbumIndentifier: PreviewImagesAbilityForChatAlbumHandlerFactory(),
                           PreviewImagesScene.searchInThreadIndentifier: PreviewImagesAbilityForSearchInThreadHandlerFactory(),
                           PreviewImagesScene.normalIndentifier: PreviewImagesAbilityForNormalHandlerFactory()]
        super.init(resolver: resolver)
    }

    func scanQR(_ code: String, from: UIViewController) {
        let status: QRCodeAnalysisCallBack = { [weak from] status, callback in
            switch status {
            case .preFinish:
                break
            case .fail(errorInfo: let errorInfo):
                guard let window = from?.view.window else { return }
                if let errorInfo = errorInfo {
                    UDToast.showFailure(with: errorInfo, on: window)
                } else {
                    UDToast.showFailure(with: BundleI18n.LarkCore.Lark_Legacy_QrCodeQrCodeError, on: window)
                }
            }
            callback?()
        }
        qrCodeAnalysis?.handle(code: code, status: status, from: .pressImage, fromVC: from)
    }

    public func handle(_ body: PreviewImagesBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        guard let vc = req.from.fromViewController else {
            assertionFailure()
            return
        }
        let chatSecurityAuditService = try userResolver.resolve(assert: ChatSecurityAuditService.self)
        guard let rustService = self.rustService else {
            throw UserScopeError.disposed
            return
        }

        let from = WindowTopMostFrom(vc: vc)
        let assets = body.assets.map { $0.transform() }
        self.scene = body.scene
        var shareImage: ((String, UIImage) -> Void)?
        var viewInChat: ((LKDisplayAsset) -> Void)?
        var loadMoreOld: ((@escaping ([LKDisplayAsset], Bool) -> Void) -> Void)?
        var loadMoreNew: ((@escaping ([LKDisplayAsset], Bool) -> Void) -> Void)?
        var translateService: AssetBrowserTranslateHandler?
        var isLoadMoreEnabled = false
        var viewInChatTitle = BundleI18n.LarkCore.Lark_Legacy_JumpToChat

        if case .chat(let id, let type, _) = self.scene {
            if body.pageIndex < assets.count {
                let currentAsset = assets[body.pageIndex]
                let fileType = getFileTypeDescription(asset: currentAsset)
                if let type = type {
                    chatSecurityAuditService.auditEvent(.chatPreviewfile(chatId: id, chatType: type, fileId: currentAsset.key, fileName: fileType, fileType: fileType),
                                                             isSecretChat: self.abilityHandler?.isFromSecretChat ?? false)
                }
            } else {
                assertionFailure("index out of range")
                Self.logger.error("PreviewImagesBody: auditEvent index out of range")
            }
        }

        self.abilityHandler = self.abilityHandlers[scene.indentifier]?.create(
            assets: assets,
            scene: self.scene,
            resolver: self.userResolver
        )

        if body.canShareImage, abilityHandler?.supportAbilities.contains(.shareImage) ?? false {
            shareImage = self.shareImage(from: from)
        }

        if body.canViewInChat, abilityHandler?.supportAbilities.contains(.jumpToChat) ?? false {
            viewInChat = self.viewInChat(from: from)
            viewInChatTitle = BundleI18n.LarkCore.Lark_Legacy_JumpToChat
        }

        if abilityHandler?.supportAbilities.contains(.jumpToThreadDetail) ?? false {
            viewInChat = self.viewInThreadDetail(from: from)
            viewInChatTitle = BundleI18n.LarkCore.Lark_Chat_TopicImageJumpToTopic
        }

        if abilityHandler?.supportAbilities.contains(.loadMore) ?? false {
            loadMoreOld = loadMoreOldAsset()
            loadMoreNew = loadMoreNewAsset()
            isLoadMoreEnabled = true
        }

        if abilityHandler?.supportAbilities.contains(.imageTranslate) ?? false {
            translateService = AssetBrowserTranslateHandler(
                canTranslateImage: body.canTranslate,
                translateDetectBlock: createTranslationDetectHandler(entityContext: body.translateEntityContext),
                translateHandler: createTranslateHandler(entityContext: body.translateEntityContext, from: from),
                cancelTranslateHandler: createCancelTranslateHandler(),
                userResolver: self.userResolver)
        }

        weak var browserVC: UIViewController?
        let actionHandler = try AssetBrowserActionHandlerFactory
            .handler(with: userResolver,
                     shouldDetectFile: body.shouldDetectFile,
                     canSaveImage: body.canSaveImage,
                     canEditImage: body.canEditImage,
                     canTranslate: body.canTranslate,
                     canImageOCR: body.canImageOCR,
                     scanQR: { [weak self] code in
                        guard let self else { return }
                        if self.userResolver.fg.dynamicFeatureGatingValue(with: "im.scan_code.multi_code_identification"),
                           let browserVC { // 新版扫码不退出大图查看器,直接跳转
                            self.scanQR(code, from: browserVC)
                        } else {
                            if let fromVC = from.fromViewController {
                                self.scanQR(code, from: fromVC)
                            }
                        }
                     },
                     loadMoreOldAsset: loadMoreOld,
                     loadMoreNewAsset: loadMoreNew,
                     showSaveToCloud: body.showSaveToCloud,
                     shareImage: shareImage,
                     viewInChat: viewInChat,
                     viewInChatTitle: viewInChatTitle,
                     fromWhere: .other,
                     onSaveImage: { [weak self] imageAsset in
                        //这里的实现有些特化了，只服务了im，实际使用的场景更广
                        chatSecurityAuditService.auditEvent(.saveImage(key: imageAsset.key),
                                                                  isSecretChat: self?.abilityHandler?.isFromSecretChat ?? false)
                     },
                     onEditImage: { [weak self] asset in
                        if case .chat(let chatId, let chatType, _) = self?.scene, let chatType = chatType {
                            chatSecurityAuditService.auditEvent(.chatEditImage(chatId: chatId, chatType: chatType, imageKey: asset.key),
                                                              isSecretChat: self?.abilityHandler?.isFromSecretChat ?? false)

                        }
                     },
                     onNextImage: { [weak self] asset in
                        if case .chat(let chatId, let chatType, _) = self?.scene, let chatType = chatType {
                            let fileType = self?.getFileTypeDescription(asset: asset) ?? ""
                            chatSecurityAuditService.auditEvent(.chatPreviewfile(chatId: chatId, chatType: chatType, fileId: asset.key, fileName: fileType, fileType: fileType),
                                isSecretChat: self?.abilityHandler?.isFromSecretChat ?? false)
                        }
                     },
                     onSaveVideo: { [weak self] mediaInfoItem in
                        //这里的实现有些特化了，只服务了im，实际使用的场景更广
                        chatSecurityAuditService.auditEvent(.saveVideo(key: mediaInfoItem.key),
                                                                  isSecretChat: self?.abilityHandler?.isFromSecretChat ?? false)
                     },
                     addToSticker: !body.showAddToSticker ? nil : { [weak self] imageAsset in

                        PublicTracker.AssetsBrowser.Click.chatAlbumClick(action: .sticker_save)

                        guard let self = self, let browserVC = browserVC else { return }
                        let hud = UDToast.showLoading(on: browserVC.view)

                        var request = Im_V1_CreateCustomizedStickersRequest()
                        let imageKey = imageAsset.originalImageKey ?? imageAsset.key
                        request.imageKeys = [imageKey]
                        if let messageId = imageAsset.extraInfo[ImageAssetMessageIdKey] as? String {
                            request.type = .imageKeyV1
                            var imageData = Im_V1_ImageKeyData()
                            imageData.imageKey = imageKey
                            imageData.messageID = messageId
                            request.imageInfos = [imageData]
                        } else {
                            request.type = .imageKey
                        }

                        _ = rustService.sendAsyncRequest(request)
                            .observeOn(MainScheduler.instance)
                            .subscribe(onNext: { (_: Im_V1_CreateCustomizedStickersResponse) in
                                hud.remove()
                                hud.showSuccess(with: BundleI18n.LarkCore.Lark_Legacy_StickerAdded, on: browserVC.view)
                            }, onError: { error in
                                hud.remove()
                                guard let rcError = error.metaErrorStack.last as? RCError,
                                      case let .businessFailure(buzErrorInfo) = rcError else { return }
                                hud.showFailure(with: buzErrorInfo.displayMessage, on: browserVC.view)
                            })
                     })

        let controller = LKAssetBrowserViewController(
            assets: assets,
            pageIndex: body.pageIndex,
            actionHandler: actionHandler,
            translateService: translateService,
            buttonType: body.buttonType)
        controller.showSavePhoto = body.canSaveImage
        controller.showEditPhoto = body.canEditImage
        controller.checkImageOCR = body.canImageOCR
        controller.checkImageTranlation = body.canTranslate
        controller.additonImageRequestOptions = self.abilityHandler?.isFromSecretChat ?? false ? [.ignoreCache(.disk), .notCache(.disk)] : []
        browserVC = controller
        controller.videoShowMoreButton = body.videoShowMoreButton
        controller.dismissCallback = body.dismissCallback
        controller.getExistedImageBlock = { (_) -> UIImage? in
            return nil
        }

        controller.videoPlayProxyFactory = { [userResolver] in
            try userResolver.resolve(assert: LKVideoDisplayViewProxy.self,
                                     arguments: body.session ?? (try? userResolver.resolve(assert: PassportUserService.self).user.sessionKey),
                                     false)
        }
        let trackInfo: PreviewImageTrackInfo = body.trackInfo ?? PreviewImageTrackInfo(scene: .Chat, messageID: "")
        configureAssetInfo(controller, trackInfo: trackInfo)
        controller.isLoadMoreEnabled = isLoadMoreEnabled
        controller.isSavePhotoButtonHidden = body.hideSavePhotoBut
        controller.showImageOnly = body.showImageOnly
        controller.customTransition = body.customTransition
        controller.handleLoadCompletion = { [weak controller] info in
            if case .image = info.data {
                if let error = info.error as? ByteWebImageError,
                   error.code == 5607 {
                    if let view = controller?.view {
                        UDToast.showFailure(with: BundleI18n.LarkCore.Lark_IM_ViewOrDownloadFile_FileDeleted_Text, on: view)
                    }
                }
            }
        }

        let navigation = AssetsNavigationController(rootViewController: controller)
        navigation.transitioningDelegate = controller
        navigation.modalPresentationStyle = .custom
        navigation.modalPresentationCapturesStatusBarAppearance = true
        PublicTracker.AssetsBrowser.show()
        res.end(resource: navigation)
    }

    private func getFileTypeDescription(asset: LKDisplayAsset) -> String {
        return asset.isVideo ? "video" : "image"
    }

    private func configureAssetInfo(_ controller: LKAssetBrowserViewController, trackInfo: PreviewImageTrackInfo) {
        let fetchKeyWithCrypto = fetchKeyWithCrypto
        controller.prepareAssetInfo = { (displayAsset) in
            let sourceType = (displayAsset.extraInfo[ImageAssetExtraInfo] as? LKImageAssetSourceType) ?? .other
            var passThrough: ImagePassThrough?
            if !displayAsset.fsUnit.isEmpty {
                passThrough = ImagePassThrough()
                passThrough?.key = displayAsset.key
                passThrough?.fsUnit = displayAsset.fsUnit
            }
            switch sourceType {
            /// Image情况存在下面几种情况：
            /// 1. 本地有原图优先使用
            /// 2. 本地没原图，直接使用displayAsset.key
            /// 3. 本地没原图，用middle，服务端决定middle是否跟origin一样
            case .image(let imageSet):
                if let dataProvider = ImageDisplayStrategy.largeImage(imageItem: ImageItemSet.transform(imageSet: imageSet),
                                                                      scene: .lookLargeImage, forceOrigin: displayAsset.forceLoadOrigin) {
                    return (dataProvider, passThrough, TrackInfo(
                        scene: trackInfo.scene, isOrigin: dataProvider.getImageKeyResource().cacheKey == imageSet.origin.key,
                        fromType: .image))
                }
                if fetchKeyWithCrypto {
                    let originResource = imageSet.origin.imageItem().imageResource()
                    if displayAsset.forceLoadOrigin || LarkImageService.shared.isCached(resource: originResource) {
                        return (originResource, passThrough,
                                TrackInfo(scene: trackInfo.scene, isOrigin: true, fromType: .image))
                    }
                    return (imageSet.middle.imageItem().imageResource(), passThrough,
                            TrackInfo(scene: trackInfo.scene, isOrigin: false, fromType: .image))
                } else {
                    let key = imageSet.origin.key
                    let originResource = LarkImageResource.default(key: key)
                    if displayAsset.forceLoadOrigin || LarkImageService.shared.isCached(resource: originResource) {
                        return (originResource, passThrough,
                                TrackInfo(scene: trackInfo.scene, isOrigin: true, fromType: .image))
                    }
                    return (LarkImageResource.default(key: imageSet.middle.key), passThrough,
                            TrackInfo(scene: trackInfo.scene, isOrigin: false, fromType: .image))
                }
            /// Image情况存在下面几种情况：
            /// 1. 本地有原图优先使用
            /// 2. 本地没原图，forceLoadOrigin(老的线上图、新图中通过原图加载) 为true，则加载origin
            /// 3. 本地没原图，用middle，服务端决定middle是否跟origin一样
            case .post(let property):
                if let dataProvider = ImageDisplayStrategy.largeImage(imageItem: ImageItemSet.transform(imageProperty: property),
                                                                      scene: .lookLargeImage, forceOrigin: displayAsset.forceLoadOrigin) {
                    return (dataProvider, passThrough, TrackInfo(
                        scene: trackInfo.scene, isOrigin: dataProvider.getImageKeyResource().cacheKey == property.originKey,
                        fromType: .post))
                }
                if fetchKeyWithCrypto {
                    let originResource: LarkImageResource
                    if property.hasOrigin, !property.origin.key.isEmpty {
                        originResource = property.origin.imageItem().imageResource()
                    } else { // 两端统一用 originKey 兜底兼容老数据
                        let originKey = property.originKey
                        originResource = .default(key: originKey)
                        Self.logger.warn("property origin is empty, fallback to originKey: \(originKey)")
                    }
                    if displayAsset.forceLoadOrigin || LarkImageService.shared.isCached(resource: originResource) {
                        return (originResource, passThrough,
                                TrackInfo(scene: trackInfo.scene, isOrigin: true, fromType: .post))
                    }
                    let middleResource: LarkImageResource
                    if property.hasMiddleWebp, !property.middleWebp.key.isEmpty {
                        middleResource = property.middleWebp.imageItem().imageResource()
                    } else {
                        middleResource = .default(key: property.middleKey)
                    }
                    return (middleResource, passThrough,
                            TrackInfo(scene: trackInfo.scene, fromType: .post))
                } else {
                    let key = property.originKey
                    let originResource = LarkImageResource.default(key: key)
                    if displayAsset.forceLoadOrigin ||
                        LarkImageService.shared.isCached(resource: originResource) {
                        return (originResource, passThrough,
                                TrackInfo(scene: trackInfo.scene, isOrigin: true, fromType: .post))
                    }
                    return (LarkImageResource.default(key: property.middleKey), passThrough,
                            TrackInfo(scene: trackInfo.scene, fromType: .post))
                }
            case .avatar(let params, let chatID):
                let resource = LarkImageResource.avatar(key: displayAsset.key,
                                                        entityID: chatID ?? "",
                                                        params: params ?? .defaultBig)
                return (resource, passThrough, TrackInfo(scene: trackInfo.scene, fromType: .avatar))
            case .sticker(let stickerSetID):
                let resource = LarkImageResource.sticker(key: displayAsset.key,
                                                         stickerSetID: stickerSetID)
                return (resource, passThrough, TrackInfo(scene: .Chat, fromType: .sticker))
            case .other:
                let resource = LarkImageResource.default(key: displayAsset.originalUrl)
                return (resource, passThrough, TrackInfo(scene: trackInfo.scene, isOrigin: true, fromType: .unknown))
            case .video(let mediaItem):
                let key = ImageItemSet.transform(imageSet: mediaItem.videoCoverImage).generateVideoMessageKey(forceOrigin: true)
                let resource = LarkImageResource.default(key: key)
                return (resource, passThrough, TrackInfo(scene: trackInfo.scene, isOrigin: true, fromType: .media))
            }
        }
    }

    private func shareImage(from: NavigatorFrom) -> ((String, UIImage) -> Void) {
        return { [weak self] (assetKey, image) in
            self?.abilityHandler?.shareImage(by: assetKey, image: image, from: from)
        }
    }

    private func viewInChat(from: NavigatorFrom) -> ((LKDisplayAsset) -> Void) {
        return { [weak self] asset in
            if asset.translateProperty == .translated,
                let translateDisplayAsset = asset.extraInfo[TranslateAssetExtraInfo] as? TranslateDisplayAsset {
                self?.abilityHandler?.jumpToChat(by: translateDisplayAsset.translatedToOriginal ?? "", from: from)
            } else {
                self?.abilityHandler?.jumpToChat(by: asset.key, from: from)
            }
        }
    }

    private func viewInThreadDetail(from: NavigatorFrom) -> ((LKDisplayAsset) -> Void) {
        return { [weak self] asset in
            self?.abilityHandler?.jumpToChat(by: asset.key, from: from)
        }
    }

    private func loadMoreOldAsset() -> ((@escaping ([LKDisplayAsset], Bool) -> Void) -> Void) {
        var loadMoreOldAsset: ((@escaping ([LKDisplayAsset], Bool) -> Void) -> Void)
        loadMoreOldAsset = { completion in
            self.abilityHandler?.loadMoreOldImages(completion: completion)
        }
        return loadMoreOldAsset
    }

    private func loadMoreNewAsset() -> ((@escaping ([LKDisplayAsset], Bool) -> Void) -> Void) {
        var loadMoreNewAsset: ((@escaping ([LKDisplayAsset], Bool) -> Void) -> Void)
        loadMoreNewAsset = { completion in
            self.abilityHandler?.loadMoreNewImages(completion: completion)
        }
        return loadMoreNewAsset
    }

    private func createTranslateHandler(entityContext: TranslateEntityContext, from: NavigatorFrom)
        -> ((LKDisplayAsset, ImageTranslationAbility, LanguageConflictSideEffect, @escaping TranslateCompletion) -> Void) {
        var translateHandler: ((LKDisplayAsset, ImageTranslationAbility, LanguageConflictSideEffect, @escaping TranslateCompletion) -> Void)
        translateHandler = { [weak self] (asset, translateAbility, languageConflictSideEffect, completion) in

            let isOrigin = asset.translateProperty == .origin
            let translateDisplayAsset = asset.extraInfo[TranslateAssetExtraInfo] as? TranslateDisplayAsset

            var entityID = entityContext.0
            var entityType = entityContext.1

            // 如果外部没有传入 entityID, 则尝试使用 asset 内部数据兜底
            if entityID == nil,
               let messageId = asset.extraInfo[ImageAssetMessageIdKey] as? String {
                entityID = messageId
                // 有 messageID 的时候 优先按照 message 类型处理
                entityType = .message
            }
            // 根据 DownloadScene 设置 Im_V1_ImageTranslateScene
            var translateScene: Im_V1_ImageTranslateScene = .imageTranslationSceneChat
            if let scene = asset.extraInfo[ImageAssetDownloadSceneKey] as? RustPB.Media_V1_DownloadFileScene {
                switch scene {
                case .favorite:
                    translateScene = .imageTranslationSceneFavorite
                case .todo:
                    translateScene = .imageTranslationSceneTodo
                @unknown default:
                    break
                }
            }
            self?.abilityHandler?.translateImage(entityId: entityID,
                                                entityType: entityType,
                                                translateScene: translateScene,
                                                imageKey: asset.originalImageKey ?? "",
                                                middleImageKey: asset.key,
                                                tranlateToOriginKey: translateDisplayAsset?.translatedToOriginal,
                                                isOrigin: isOrigin,
                                                imageTranslateAbility: translateAbility,
                                                languageConflictSideEffect: languageConflictSideEffect,
                                                from: from,
                                                completion: completion)
        }
        return translateHandler
    }

    private func createTranslationDetectHandler(entityContext: TranslateEntityContext)
        -> ([String], @escaping ([ImageTranslationAbility]?, Error?) -> Void) -> Void {
        var translationDetectHandler: ([String], @escaping ([ImageTranslationAbility]?, Error?) -> Void) -> Void
        translationDetectHandler = { (assetKeys, completion) in
            self.abilityHandler?.detectImageTranslationAbility(assetKeys: assetKeys,
                                                               completion: completion)
        }
        return translationDetectHandler
    }

    private func createCancelTranslateHandler() -> CancelTranslateBlock {
        return {
            self.abilityHandler?.cancelTransalte()
        }
    }
}
