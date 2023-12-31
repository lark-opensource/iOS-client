//
//  PreviewImagesAbilityForChatAlbumHandlerFactory.swift
//  LarkCore
//
//  Created by Patrick on 2022/2/11.
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
import RustPB
import LarkRustClient

final class PreviewImagesAbilityForChatAlbumHandlerFactory: PreviewImagesAbilityHandlerFactory {
    func create(assets: [LKDisplayAsset], scene: PreviewImagesScene, resolver: UserResolver) -> PreviewImagesAbilityHandler {
        return PreviewImagesAbilityForChatAlbum(assets: assets, scene: scene, resolver: resolver)
    }
}

final class PreviewImagesAbilityForChatAlbum: BasePreviewImagesAbilityForChat, PreviewImagesAbilityHandler {
    var supportAbilities: [PreviewImagesAbilities] {
        return [.shareImage, .jumpToChat, .loadMore, .imageTranslate]
    }

    @ScopedInjectedLazy private var messageAPI: MessageAPI?
    init(assets: [LKDisplayAsset], scene: PreviewImagesScene, resolver: UserResolver) {
        super.init(scene: scene, resolver: resolver)

        configData(assets: assets, scene: scene)
    }

    func configData(assets: [LKDisplayAsset], scene: PreviewImagesScene) {
        switch scene {
        case .chatAlbum(chatId: let chatId,
                        messageId: let messageId,
                        position: let position,
                        isMsgThread: let isMsgThread):
            self.chatId = chatId
            for asset in assets {
                assetPositionMap[asset.key] = (position, messageId)
                threadInfo[asset.key] = isMsgThread
            }
            self.minFlag = messageId
            self.maxFlag = messageId
        default:
            break
        }
    }

    func jumpToChat(by assetKey: String, from: NavigatorFrom) {
        guard let positionInfo = self.assetPositionMap[assetKey]  else { return }

        if supportAbilities.contains(.jumpToChat) {
            guard !self.chatId.isEmpty else { return }
            if threadInfo[assetKey] ?? false {
                let body = ReplyInThreadByIDBody(threadId: positionInfo.1,
                                                 loadType: .position,
                                                 position: positionInfo.0)
                userResolver.navigator.push(body: body, from: from)
            } else {
                let body = ChatControllerByIdBody(
                    chatId: chatId,
                    position: positionInfo.0,
                    messageId: positionInfo.1,
                    fromWhere: .search
                )
                userResolver.navigator.push(body: body, from: from)
            }
        } else if supportAbilities.contains(.jumpToThreadDetail) {
                let body = ThreadDetailByIDBody(threadId: positionInfo.1,
                                            loadType: .position,
                                            position: positionInfo.0)
                userResolver.navigator.push(body: body, from: from)
        }
    }

    func loadMoreOldImages(completion: @escaping ([LKDisplayAsset], Bool) -> Void) {
        guard !self.chatId.isEmpty else { return }
        try? self.resolver.resolve(assert: ChatAPI.self)
            .fetchChatResources(chatId: self.chatId,
                                fromMessageId: minFlag,
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
                let messageMetas = resourcesResult.messageMetas
                self.minFlag = messageMetas.first?.id ?? ""
                completion(self.transform(metas: zip(messageMetas, messages).map { $0 }), resourcesResult.hasMoreAfter)
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
                let messageMetas = resourcesResult.messageMetas
                self.maxFlag = messageMetas.last?.id ?? ""
                completion(self.transform(metas: zip(messageMetas, messages).map { $0 }), resourcesResult.hasMoreBefore)
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
        let translateParam = ImageTranslateParameter(entityId: self.assetPositionMap[imageToEntityKey ?? ""]?.1,
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
                    /// 翻译图片额外需要的信息存入translatedToOriginal结构中
                    let translateDisplayAsset = TranslateDisplayAsset(
                        translatedToOriginal: originImageKey,                   ///translatedToOriginal：译图对应的原图key
                        entityID: self?.assetPositionMap[imageToEntityKey ?? ""]?.1, ///entityID：当前图片的messageID
                        entityType: .message                                       ///entityType: 当前图片的messageType
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
                        entityID: self?.assetPositionMap[originImageKey ?? ""]?.1,
                        entityType: .message
                    )
                    if self?.assetPositionMap[imageProperty.originKey ?? ""] == nil {
                        self?.assetPositionMap[imageProperty.originKey ?? ""] = self?.assetPositionMap[imageToEntityKey ?? ""]
                    }
                    displayAsset.key = imageProperty.originKey
                    displayAsset.originalImageKey = imageProperty.originKey
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

    override func updateAssetPositionMapWithMessageMeta(_ messageMeta: Media_V1_GetChatResourcesResponse.MessageMeta, asset: LKDisplayAsset) {
        if messageMeta.position == replyInThreadMessagePosition {
            self.assetPositionMap[asset.key] = (position: messageMeta.threadPosition, id: messageMeta.threadID)
            self.threadInfo[asset.key] = true
        } else {
            self.assetPositionMap[asset.key] = (position: messageMeta.position, id: messageMeta.id)
            self.threadInfo[asset.key] = false
        }
        if !messageMeta.threadID.isEmpty, messageMeta.threadID != messageMeta.id {
            self.threadIDsMap[asset.key] = messageMeta.threadID
        }
    }
}
