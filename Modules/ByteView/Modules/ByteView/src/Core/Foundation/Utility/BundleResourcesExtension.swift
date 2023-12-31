//
//  BundleResourcesExtension.swift
//  ByteView
//
//  Created by fakegourmet on 2023/4/18.
//

import Foundation

typealias EmojiResources = BundleResources.ByteView.Meet.StatusEmoji
typealias ExclusiveReactionResource = BundleResources.ByteView.Meet.ExclusiveReaction

extension EmojiResources {
    private static let handsUpEmojiSkins = [
        "MediumLightHandsUp": EmojiResources.MediumLightHandsUp,
        "LightHandsUp": EmojiResources.LightHandsUp,
        "HandsUp": EmojiResources.HandsUp,
        "MediumHandsUp": EmojiResources.MediumHandsUp,
        "MediumDarkHandsUp": EmojiResources.MediumDarkHandsUp,
        "DarkHandsUp": EmojiResources.DarkHandsUp
    ]

    static func getEmojiSkin(by key: String?) -> UIImage {
        if let key = key, let image = handsUpEmojiSkins[key] {
            return image
        } else {
            return EmojiResources.HandsUp
        }
    }
}

extension ExclusiveReactionResource {
    private static let exclusiveReaction = getReactionImage()
    static let defaultKeys = ["VC_SoundsClear", "VC_NoSound", "VC_LooksGood", "VC_CanNotSee"]

    static func getExclusiveReaction(by key: String) -> UIImage? {
        if let image = exclusiveReaction[key] {
            return image
        } else {
            return nil
        }
    }

    private static func getReactionImage() -> [String: UIImage] {
        if BundleI18n.getCurrentLanguageString().hasPrefix("zh_") {
            return [
                "VC_SoundsClear": ExclusiveReactionResource.VC_SoundsClear_zh,
                "VC_NoSound": ExclusiveReactionResource.VC_NoSound_zh,
                "VC_LooksGood": ExclusiveReactionResource.VC_LooksGood_zh,
                "VC_CanNotSee": ExclusiveReactionResource.VC_CanNotSee_zh
            ]
        } else {
            return [
                "VC_SoundsClear": ExclusiveReactionResource.VC_SoundsClear_en,
                "VC_NoSound": ExclusiveReactionResource.VC_NoSound_en,
                "VC_LooksGood": ExclusiveReactionResource.VC_LooksGood_en,
                "VC_CanNotSee": ExclusiveReactionResource.VC_CanNotSee_en
            ]
        }
    }
}
