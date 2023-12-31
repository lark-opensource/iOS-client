//
//  EmotionDependencyImpl.swift
//  LarkByteView
//
//  Created by kiri on 2021/7/6.
//

import Foundation
import ByteView
import ByteWebImage
import LarkEmotion
import LarkEmotionKeyboard

final class EmotionDependencyImpl: EmotionDependency {
    var reactions: [String] {
        EmotionResouce.reactions
    }

    func imageByKey(_ key: String) -> UIImage? {
        EmotionResouce.shared.imageBy(key: key)
    }

    func imageKey(by reactionKey: String) -> String? {
        EmotionResouce.shared.imageKeyBy(key: reactionKey)
    }

    func emotionKeyBy(i18n: String) -> String? {
        EmotionResouce.shared.emotionKeyBy(i18n: i18n)
    }

    func skinKeysBy(_ key: String) -> [String] {
        EmotionResouce.shared.skinKeysBy(key: key)
    }

    func sizeBy(_ key: String) -> CGSize? {
        EmotionResouce.shared.sizeBy(key: key)
    }

    func isDeletedBy(key: String) -> Bool {
        EmotionResouce.shared.isDeletedBy(key: key)
    }

    func getIllegaDisplayText() -> String {
        EmotionResouce.shared.getIllegaDisplayText()
    }

    func createLayout(_ layoutType: EmotionLayoutType) -> UICollectionViewFlowLayout {
        switch layoutType {
        case .leftAlignedFlowLayout: return EmotionLeftAlignedFlowLayout()
        case .recentReactionsFloatLayout: return RecentReactionsFlowLayout()
        }
    }
}
