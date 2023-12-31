//
//  PreviewImagesAbilityForChat.swift
//  LarkCore
//
//  Created by zc09v on 2019/3/22.
//

import Foundation
import LarkContainer
import Swinject
import RxSwift
import LarkModel
import EENavigator
import LarkUIKit
import LarkSDKInterface
import LarkMessengerInterface
import LarkAssetsBrowser
import LarkImageEditor
import RustPB
import LarkAccountInterface
import LarkRustClient

final class PreviewImagesAbilityForChatHandlerFactory: PreviewImagesAbilityHandlerFactory {
    func create(assets: [LKDisplayAsset], scene: PreviewImagesScene, resolver: UserResolver) -> PreviewImagesAbilityHandler {
        return PreviewImagesAbilityForChat(assets: assets, scene: scene, resolver: resolver)
    }
}

final class PreviewImagesAbilityForChat: BasePreviewImagesAbilityForChat, PreviewImagesAbilityHandler {

    let supportAbilities: [PreviewImagesAbilities] = [.shareImage, .jumpToChat, .loadMore, .imageTranslate]

    @ScopedInjectedLazy private var messageAPI: MessageAPI?

    init(assets: [LKDisplayAsset], scene: PreviewImagesScene, resolver: UserResolver) {
        super.init(scene: scene, resolver: resolver)
        switch scene {
        case .chat(chatId: let chatId, _, assetPositionMap: let assetPositionMap):
            self.chatId = chatId
            self.assetPositionMap = assetPositionMap
            self.minFlag = assetPositionMap[assets.first?.key ?? ""]?.id ?? ""
            self.maxFlag = assetPositionMap[assets.last?.key ?? ""]?.id ?? ""
        default:
            break
        }
    }

    func jumpToChat(by assetKey: String, from: NavigatorFrom) {
        guard !self.chatId.isEmpty, let positionInfo = self.assetPositionMap[assetKey] else { return }
        let body = ChatControllerByIdBody(
            chatId: chatId,
            position: positionInfo.0,
            messageId: positionInfo.1
        )
        userResolver.navigator.push(body: body, from: from)
    }

    func loadMoreOldImages(completion: @escaping ([LKDisplayAsset], Bool) -> Void) {
        guard !self.chatId.isEmpty else { return }

        try? self.resolver.resolve(assert: ChatAPI.self)
            .fetchChatResources(chatId: self.chatId,
                                fromMessageId: minFlag,
                                count: 10,
                                direction: .before,
                                resourceTypes: [.image, .video])
            .flatMap { [weak self] (result) -> Observable<(FetchChatResourcesResult, [Message])> in
                guard let self = self else { return .empty() }
                let resourcesOb: Observable<FetchChatResourcesResult> = .just(result)
                let messagesOb: Observable<[Message]> = self.messageAPI?.fetchMessages(ids: result.messageMetas.map { $0.id }) ?? .error(RCError.cancel)
                return Observable.zip(resourcesOb, messagesOb)
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (resourcesResult, messages) in
                guard let self = self else { return }
                let messageMetas = resourcesResult.messageMetas.reversed()
                self.minFlag = messageMetas.first?.id ?? ""
                completion(self.transform(metas: zip(messageMetas, messages).map { $0 }), resourcesResult.hasMoreBefore)
            }, onError: { (_) in
                completion([], true)
            }).disposed(by: self.disposeBag)

    }

    func loadMoreNewImages(completion: @escaping ([LKDisplayAsset], Bool) -> Void) {
        guard !self.chatId.isEmpty else { return }
        try? self.resolver.resolve(assert: ChatAPI.self)
            .fetchChatResources(chatId: self.chatId,
                                fromMessageId: maxFlag,
                                count: 10,
                                direction: .after,
                                resourceTypes: [.image, .video])
            .flatMap { [weak self] (result) -> Observable<(FetchChatResourcesResult, [Message])> in
                guard let self = self else { return .empty() }
                let resourcesOb: Observable<FetchChatResourcesResult> = .just(result)
                let messagesOb: Observable<[Message]> = self.messageAPI?.fetchMessages(ids: result.messageMetas.map { $0.id }) ?? .error(RCError.cancel)
                return Observable.zip(resourcesOb, messagesOb)
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (resourcesResult, messages) in
                guard let self = self else { return }
                let messageMetas = resourcesResult.messageMetas.reversed()
                self.maxFlag = messageMetas.last?.id ?? ""
                completion(self.transform(metas: zip(messageMetas, messages).map { $0 }), resourcesResult.hasMoreAfter)
            }, onError: { (_) in
                completion([], true)
            }).disposed(by: self.disposeBag)
    }

    func detectImageTranslationAbility(assetKeys: [String],
                                       completion: @escaping ([ImageTranslationAbility]?, Error?) -> Void) {
        guard let translateService = try? resolver.resolve(assert: NormalTranslateService.self) else { return }
        translateService.detectImageTranslationAbility(assetKeys: assetKeys, completion: completion)
    }

    // swiftlint:disable function_parameter_count
    func translateImage(entityId: String?,
                        entityType: TranslateEntityType?,
                        translateScene: Im_V1_ImageTranslateScene,
                        imageKey: String,
                        middleImageKey: String,
                        tranlateToOriginKey: String? = nil,
                        isOrigin: Bool,
                        imageTranslateAbility: ImageTranslationAbility,
                        languageConflictSideEffect: (() -> Void)?,
                        from: NavigatorFrom,
                        completion: @escaping (LKDisplayAsset?, Error?) -> Void) {
        guard let translateService = try? resolver.resolve(assert: NormalTranslateService.self) else { return }
        var imageToEntityKey: String?
        if isOrigin {
            imageToEntityKey = middleImageKey // 原图
        } else {
            imageToEntityKey = tranlateToOriginKey// 译图
        }

        // 优先保持原有 assetPositionMap 查找逻辑，外部传入 entityId 作为兜底
        let entityID = self.assetPositionMap[imageToEntityKey ?? ""]?.1 ?? entityId

        let translateParam = ImageTranslateParameter(entityId: entityID,
                                                     entityType: entityType,
                                                     translateScene: translateScene,
                                                     chatId: chatId,
                                                     imageKey: imageKey,
                                                     middleImageKey: middleImageKey,
                                                     isOrigin: isOrigin,
                                                     imageTranslateAbility: imageTranslateAbility,
                                                     languageConflictSideEffect: languageConflictSideEffect) { [weak self] (imageSet, imageProperty, originImageKey, error) in
            if let err = error {
                completion(nil, err)
            } else {
                /// 针对不同场景的image结构，sdk约定从db查询出不同的原图数据结构，由端上做transform
                if let imageSet = imageSet {
                    ///translatedToOriginal：译图对应的原图key
                    ///entityID：当前图片的messageID
                    ///entityType: 当前图片的messageType  
                    let translateDisplayAsset = TranslateDisplayAsset(
                        translatedToOriginal: originImageKey,
                        entityID: entityID,
                        entityType: .message
                    )
                    if self?.assetPositionMap[imageSet.middle.key ?? ""] == nil {
                        self?.assetPositionMap[imageSet.middle.key ?? ""] = self?.assetPositionMap[imageToEntityKey ?? ""]
                    }
                    let displayAsset = LKDisplayAsset.asset(
                        with: imageSet,
                        isTranslated: isOrigin,
                        isOriginSource: false,
                        originSize: 0,
                        isAutoLoadOrigin: false,
                        extraInfo: [TranslateAssetExtraInfo: translateDisplayAsset]
                    )
                    completion(displayAsset, nil)
                    return
                }
                if let imageProperty = imageProperty {
                    let displayAsset = LKDisplayAsset()
                    let translateDisplayAsset = TranslateDisplayAsset(
                        translatedToOriginal: originImageKey,
                        entityID: entityID,
                        entityType: .message
                    )
                    if self?.assetPositionMap[imageProperty.originKey ?? ""] == nil {
                        self?.assetPositionMap[imageProperty.originKey ?? ""] = self?.assetPositionMap[imageToEntityKey ?? ""]
                    }
                    displayAsset.key = imageProperty.originKey
                    displayAsset.originalImageKey = imageProperty.originKey
                    displayAsset.intactImageKey = imageProperty.intact.key
                    displayAsset.forceLoadOrigin = true
                    displayAsset.extraInfo = [
                        ImageAssetExtraInfo: LKImageAssetSourceType.post(imageProperty),
                        TranslateAssetExtraInfo: translateDisplayAsset
                    ]
                    displayAsset.translateProperty = isOrigin ? .translated : .origin
                    completion(displayAsset, nil)
                    return
                }
                completion(nil, nil)
            }
        }
        translateService.translateImage(translateParam: translateParam, from: from)
    }
    // swiftlint:enable function_parameter_count

    func cancelTransalte() {
        guard let translateService = try? resolver.resolve(assert: NormalTranslateService.self) else { return }
        translateService.cancelImageTranslate()
    }
}

class BasePreviewImagesAbilityForChat: BasePreviewImagesAbility {
    // for thread topic. reply message need save threadID for jump to thread detail controller.
    var threadIDsMap: [String: String] = [:]
    /// 是否是msgThread
    var threadInfo: [String: Bool] = [:]
    var chatId: String = ""
    var minFlag: String = ""
    var maxFlag: String = ""

    @ScopedInjectedLazy private var chatSecurityControlService: ChatSecurityControlService?

    var isFromSecretChat: Bool {
        guard !chatId.isEmpty else { return false }
        if let chat = try? self.resolver.resolve(type: ChatAPI.self).getLocalChat(by: chatId), chat.isCrypto {
            return true
        }
        return false
    }

    private lazy var chat: Chat? = {
        return try? self.resolver.resolve(type: ChatAPI.self).getLocalChat(by: chatId)
    }()

    func transform(metas: [(RustPB.Media_V1_GetChatResourcesResponse.MessageMeta, Message)]) -> [LKDisplayAsset] {
        guard let chatSecurityControlService else { return [] }
        var assets: [LKDisplayAsset] = []
        for (messageMeta, message) in metas {
            for resource in messageMeta.resources {
                // 检查message对应的cache状态
                // 如果cache没有，就发起鉴权
                let previewAndReceiveResult = chatSecurityControlService.checkPreviewAndReceiveAuthority(chat: chat, message: message)
                if previewAndReceiveResult == .receiveLoading, let senderUserId = Int64(message.fromId), let senderTenantId = Int64(message.fromChatter?.tenantId ?? "") {
                    chatSecurityControlService.checkDynamicAuthority(
                        params: DynamicAuthorityParams(event: .receive, messageID: message.id, senderUserId: senderUserId, senderTenantId: senderTenantId, onComplete: { _ in }))
                }
                switch resource.type {
                case .image:
                    let asset = LKDisplayAsset.asset(
                        with: resource.image,
                        isTranslated: false,
                        isOriginSource: resource.isOriginSource,
                        originSize: resource.originSize,
                        isAutoLoadOrigin: false,
                        permissionState: previewAndReceiveResult,
                        message: message,
                        chat: self.chat
                    )
                    asset.extraInfo[ImageAssetMessageIdKey] = message.id
                    asset.extraInfo[ImageAssetFatherMFIdKey] = message.fatherMFMessage?.id
                    asset.extraInfo[ImageAssetReplyThreadRootIdKey] = message.threadMessageType == .threadReplyMessage ? message.rootId : nil
                    asset.riskObjectKeys = message.riskObjectKeys
                    assets.append(asset)
                    updateAssetPositionMapWithMessageMeta(messageMeta, asset: asset)
                case .video:
                    let mediaContent = MediaContent.transform(
                        content: resource.video.mediaContent,
                        filePath: resource.video.filePath)

                    let asset = LKDisplayAsset.asset(with:
                        MediaInfoItem(
                            content: mediaContent,
                            messageId: messageMeta.id,
                            messageRiskObjectKeys: message.riskObjectKeys,
                            fatherMFId: message.fatherMFMessage?.id,
                            replyThreadRootId: message.threadMessageType == .threadReplyMessage ? message.rootId : nil,
                            channelId: self.chatId,
                            sourceId: "",
                            sourceType: .typeFromUnkonwn,
                            isSuccess: true,
                            downloadFileScene: nil),
                        message: message,
                        permissionState: previewAndReceiveResult
                    )
                    updateAssetPositionMapWithMessageMeta(messageMeta, asset: asset)
                    assets.append(asset)
                @unknown default:
                    assert(false, "new value")
                    break
                }
            }
        }
        return assets
    }

    func updateAssetPositionMapWithMessageMeta(_ messageMeta: RustPB.Media_V1_GetChatResourcesResponse.MessageMeta,
                                               asset: LKDisplayAsset) {
        self.assetPositionMap[asset.key] = (position: messageMeta.position, id: messageMeta.id)
        if !messageMeta.threadID.isEmpty, messageMeta.threadID != messageMeta.id {
            self.threadIDsMap[asset.key] = messageMeta.threadID
        }
    }
}
