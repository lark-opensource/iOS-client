//
//  LarkIconManager+Emoji.swift
//  LarkIcon
//
//  Created by huangzhikai on 2023/12/15.
//

import Foundation

extension LarkIconManager {
    
    func createEmojiIcon() -> LIResult {
        
        
        //字符串转emoji，转失败了用兜底的图标
        guard let emoji = EmojiUtil.scannerStringChangeToEmoji(key: self.iconKey), !emoji.isEmpty else {
            LarkIconLogger.logger.warn("scannerStringChangeToEmoji is nil, key:\(self.iconKey ?? ""), use defult icon")
            let defult = self.createDefultIcon()
            return (image: defult.image, error: IconError.emojiKeyChangeError)
        }
        
        
        var scale: CGFloat? = nil
        if case .CIRCLE = self.iconExtend.shape {
            scale = self.circleScale
        } else if let borderWidth = self.iconExtend.layer?.border?.borderWidth, borderWidth > 0 {
            scale = self.emojiBorderScale
        }
        
        let image = LarkIconBuilder.createImageWith(emoji: emoji,
                                                    scale: scale,
                                                    iconLayer: self.iconExtend.layer,
                                                    iconShape: self.iconExtend.shape,
                                                    foreground: self.iconExtend.foreground)

        return (image: image, error: nil)
    }
}
