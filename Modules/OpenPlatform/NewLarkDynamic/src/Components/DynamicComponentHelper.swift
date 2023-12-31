//
//  DynamicComponentHelper.swift
//  NewLarkDynamic
//
//  Created by lilun.ios on 2021/9/5.
//

import Foundation
import LarkUIKit
import LarkEmotion
import LarkFeatureGating

/// 通过emojikey加载图片
func loadEmotion(_ emojiKey: String) -> UIImage? {
    if let icon = EmotionResouce.shared.imageBy(key: emojiKey) {
        return icon
    }
    if let emotionKey = EmotionResouce.shared.emotionKeyBy(i18n: emojiKey),
       let icon = EmotionResouce.shared.imageBy(key: emotionKey) {
        return icon
    }
    cardlog.error("load emotion failed \(emojiKey)")
    return nil
}
