//
//  PreviewImagesAbilityHandler.swift
//  LarkCore
//
//  Created by zc09v on 2019/3/22.
//

import UIKit
import Foundation
import LarkUIKit
import LarkMessengerInterface
import Swinject
import LarkModel
import LarkAssetsBrowser
import EENavigator
import RustPB
import LarkContainer

enum PreviewImagesAbilities {
    case shareImage
    case jumpToChat
    case jumpToThreadDetail
    case loadMore
    case imageTranslate
}

protocol PreviewImagesAbilityHandler {
    var scene: PreviewImagesScene { get }
    var resolver: Resolver { get }
    var supportAbilities: [PreviewImagesAbilities] { get }
    var isFromSecretChat: Bool { get }
    func shareImage(by assetKey: String, image: UIImage, from: NavigatorFrom)
    func jumpToChat(by assetKey: String, from: NavigatorFrom)
    func loadMoreOldImages(completion: @escaping ([LKDisplayAsset], Bool) -> Void)
    func loadMoreNewImages(completion: @escaping ([LKDisplayAsset], Bool) -> Void)
    func detectImageTranslationAbility(assetKeys: [String],
                                       completion: @escaping ([ImageTranslationAbility]?, Error?) -> Void)
    // swiftlint:disable function_parameter_count
    func translateImage(entityId: String?,
                        entityType: TranslateEntityType?,
                        translateScene: Im_V1_ImageTranslateScene,
                        imageKey: String,
                        middleImageKey: String,
                        tranlateToOriginKey: String?,
                        isOrigin: Bool,
                        imageTranslateAbility: ImageTranslationAbility,
                        languageConflictSideEffect: (() -> Void)?,
                        from: NavigatorFrom,
                        completion: @escaping (LKDisplayAsset?, Error?) -> Void)
    // swiftlint:enable function_parameter_count
    func cancelTransalte()
}

extension PreviewImagesAbilityHandler {
    func jumpToChat(by assetKey: String, from: NavigatorFrom) { }
    func loadMoreOldImages(completion: @escaping ([LKDisplayAsset], Bool) -> Void) { }
    func loadMoreNewImages(completion: @escaping ([LKDisplayAsset], Bool) -> Void) { }
    func detectImageTranslationAbility(assetKeys: [String],
                                       completion: @escaping ([ImageTranslationAbility]?, Error?) -> Void) { }
    // swiftlint:disable function_parameter_count
    func translateImage(entityId: String?,
                        entityType: TranslateEntityType?,
                        translateScene: Im_V1_ImageTranslateScene,
                        imageKey: String,
                        middleImageKey: String,
                        tranlateToOriginKey: String?,
                        isOrigin: Bool,
                        imageTranslateAbility: ImageTranslationAbility,
                        languageConflictSideEffect: (() -> Void)?,
                        from: NavigatorFrom,
                        completion: @escaping (LKDisplayAsset?, Error?) -> Void) {}
    // swiftlint:enable function_parameter_count
    func cancelTransalte() {}
}

protocol PreviewImagesAbilityHandlerFactory {
    func create(assets: [LKDisplayAsset], scene: PreviewImagesScene, resolver: UserResolver) -> PreviewImagesAbilityHandler
}
