//
//  PreviewImagesAbilityForNormal.swift
//  LarkCore
//
//  Created by 李勇 on 2020/4/14.
//

import Foundation
import LarkUIKit
import LarkMessengerInterface
import Swinject
import LarkModel
import RxSwift
import LarkSDKInterface
import LarkAssetsBrowser
import LarkImageEditor
import EENavigator
import RustPB
import LarkContainer

final class PreviewImagesAbilityForNormalHandlerFactory: PreviewImagesAbilityHandlerFactory {
    func create(assets: [LKDisplayAsset], scene: PreviewImagesScene, resolver: UserResolver) -> PreviewImagesAbilityHandler {
        return PreviewImagesAbilityForNormal(scene: scene, resolver: resolver)
    }
}

final class PreviewImagesAbilityForNormal: BasePreviewImagesAbility, PreviewImagesAbilityHandler {
    let supportAbilities: [PreviewImagesAbilities] = [.shareImage, .imageTranslate]
    private var chatId: String?

    override init(scene: PreviewImagesScene, resolver: UserResolver) {
        super.init(scene: scene, resolver: resolver)
        switch scene {
        case .normal(let assetPositionMap, let chatId):
            self.assetPositionMap = assetPositionMap
            self.chatId = chatId
        default:
            break
        }
    }

    var isFromSecretChat: Bool {
        guard let chatID = self.chatId, !chatID.isEmpty else { return false }
        if let chat = try? self.resolver.resolve(type: ChatAPI.self).getLocalChat(by: chatID), chat.isCrypto {
            return true
        }
        return false
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
                if let imageSet = imageSet {
                    ///translatedToOriginal：译图对应的原图key
                    ///entityID：当前图片的messageID
                    ///entityType: 当前图片的messageType
                    let translateDisplayAsset = TranslateDisplayAsset(
                        translatedToOriginal: originImageKey,
                        entityID: self?.assetPositionMap[imageToEntityKey ?? ""]?.1,
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
                        entityID: self?.assetPositionMap[originImageKey ?? ""]?.1,
                        entityType: .message
                    )

                    if self?.assetPositionMap[imageProperty.originKey ?? ""] == nil {
                        self?.assetPositionMap[imageProperty.originKey ?? ""] = self?.assetPositionMap[imageToEntityKey ?? ""]
                    }
                    displayAsset.key = imageProperty.originKey
                    displayAsset.originalImageKey = imageProperty.originKey
                    displayAsset.isAutoLoadOriginalImage = false
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
