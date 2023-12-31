//
//  PreviewImagesAbilityForSearchInChat.swift
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
import RustPB

class PreviewImagesAbilityForSearchInChatHandlerFactory: PreviewImagesAbilityHandlerFactory {
    func create(assets: [LKDisplayAsset], scene: PreviewImagesScene, resolver: UserResolver) -> PreviewImagesAbilityHandler {
        return PreviewImagesAbilityForSearchInChat(assets: assets, scene: scene, resolver: resolver)
    }
}

class PreviewImagesAbilityForSearchInChat: BasePreviewImagesAbilityForChat, PreviewImagesAbilityHandler {
    var supportAbilities: [PreviewImagesAbilities] {
        return [.shareImage, .jumpToChat, .loadMore, .imageTranslate]
    }

    init(assets: [LKDisplayAsset], scene: PreviewImagesScene, resolver: UserResolver) {
        super.init(scene: scene, resolver: resolver)

        configData(assets: assets, scene: scene)
    }

    func configData(assets: [LKDisplayAsset], scene: PreviewImagesScene) {
        switch scene {
        case .searchInChat(chatId: let chatId, messageId: let messageId, position: let position, assetInfos: let assetInfos, currentAsset: let currentAsset):
            self.chatId = chatId
            for assetInfo in assetInfos {
                switch assetInfo.messageType {
                case .thread(let threadPostion, let threadId):
                    assetPositionMap[assetInfo.asset.key] = (threadPostion, threadId)
                    threadInfo[assetInfo.asset.key] = true
                case .message(let position, let messageId):
                    assetPositionMap[assetInfo.asset.key] = (position, messageId)
                    threadInfo[assetInfo.asset.key] = false
                }
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
            if self.threadInfo[assetKey] ?? false {
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
        switch scene {
        case .searchInChat(chatId: let chatId, messageId: let messageId, position: let position, assetInfos: let assetInfos, currentAsset: let currentAsset):
            guard let currentPosition = assetInfos.firstIndex { $0.asset == currentAsset }, currentPosition > 0 else {
                completion([], false)
                return
            }
            completion(Array(assetInfos[0...currentPosition - 1]).map { $0.asset.transform() }, false)
        default: break
        }
    }

    func loadMoreNewImages(completion: @escaping ([LKDisplayAsset], Bool) -> Void) {
        guard !self.chatId.isEmpty else { return }
        switch scene {
        case .searchInChat(chatId: let chatId, messageId: let messageId, position: let position, assetInfos: let assetInfos, currentAsset: let currentAsset):
            guard let currentPosition = assetInfos.firstIndex { $0.asset == currentAsset }, currentPosition < assetInfos.count - 1 else {
                completion([], false)
                return
            }
            completion(Array(assetInfos[currentPosition + 1...assetInfos.count - 1]).map { $0.asset.transform() }, false)
        default: break
        }

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
                                                     entityType: .message,
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
                        translatedToOriginal: originImageKey,  ///translatedToOriginal：译图对应的原图key
                        entityID: self?.assetPositionMap[imageToEntityKey ?? ""]?.1, ///entityID：当前图片的messageID
                        entityType: .message ///entityType: 当前图片的messageType
                    )

                    // 修复图片翻译反复操作后不能翻译的bug， 后端返回原图的key和第一次操作的key可能不同
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
                    // 修复图片翻译反复操作后不能翻译的bug， 后端返回原图的key和第一次操作的key可能不同
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
}
