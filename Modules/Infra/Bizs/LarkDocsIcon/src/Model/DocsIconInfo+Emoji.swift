//
//  DocsIconInfo+Emoji.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/6/25.
//

import Foundation
import UniverseDesignColor
import LarkContainer
import UniverseDesignTheme
import LarkIcon
import UniverseDesignIcon

extension DocsIconInfo {
    
    func getEmojiIcon(shape: IconShpe = .CIRCLE,
                      container: ContainerInfo? = nil) -> UIImage  {
        let isShortCut = container?.isShortCut ?? false
        let shortCutImage: UIImage? = isShortCut ? UDIcon.wikiShortcutarrowColorful : nil
        let defaultIcon = self.getDefultIcon(shape: shape, container: container)
        //字符串转emoji，转失败了用兜底的图标
        guard let emoji = EmojiUtil.scannerStringChangeToEmoji(key: self.key), !emoji.isEmpty else {
            DocsIconLogger.logger.warn("scannerStringChangeToEmoji is nil, key:\(self.key ?? ""), use defult icon")
            return self.getDefultIcon(shape: shape, container: container)
        }
        
        switch shape {
        case .CIRCLE:
            //FG 为true 才显示圆形图标底色
            //fg使用，后续会比较快的去掉该fg，就没有用户态的问题
            let featureGating = try? Container.shared.getCurrentUserResolver().resolve(type: DocsIconFeatureGating.self)
            if featureGating?.circleBackgroundColor ?? false {
                
                //反向fg， FG 为false 接入使用larkIcon
                //fg使用，后续会比较快的去掉该fg，就没有用户态的问题
                if !(featureGating?.larkIconDisable ?? true) {
                    let iconImage = LarkIconBuilder.createImageWith(emoji: emoji,
                                                                    scale: 0.6,
                                                                    iconLayer: IconLayer(backgroundColor: self.iconBackgroundColor),
                                                                    iconShape: .CIRCLE,
                                                                    foreground: IconForeground(foregroundImage: shortCutImage)) ?? defaultIcon
                    return iconImage
                }
                
                //后续larkIconDisable fg删掉，后面的代码也删除
                let lightMode = DocsIconCreateUtil.creatImageWithEmoji(emoji: emoji,
                                                                       isShortCut: container?.isShortCut ?? false,
                                                                       backgroudColor: self.iconBackgroundColor.alwaysLight)
                let darkMode = DocsIconCreateUtil.creatImageWithEmoji(emoji: emoji,
                                                                      isShortCut: container?.isShortCut ?? false,
                                                                      backgroudColor: self.iconBackgroundColor.alwaysDark)
                return lightMode & darkMode
            } else { // 不显示底色
                //反向fg， FG 为false 接入使用larkIcon
                //fg使用，后续会比较快的去掉该fg，就没有用户态的问题
                if !(featureGating?.larkIconDisable ?? true) {
                    return LarkIconBuilder.createImageWith(emoji: emoji,
                                                           foreground: IconForeground(foregroundImage: shortCutImage)) ?? defaultIcon
                }
                //后续larkIconDisable fg删掉，后面的代码也删除
                return DocsIconCreateUtil.creatImageWithEmoji(emoji: emoji,
                                                              isShortCut: container?.isShortCut ?? false)
            }
            
        case .SQUARE, .OUTLINE:
            //反向fg， FG 为false 接入使用larkIcon
            //fg使用，后续会比较快的去掉该fg，就没有用户态的问题
            let featureGating = try? Container.shared.getCurrentUserResolver().resolve(type: DocsIconFeatureGating.self)
            if !(featureGating?.larkIconDisable ?? true) {
                return LarkIconBuilder.createImageWith(emoji: emoji,
                                                       foreground: IconForeground(foregroundImage: shortCutImage)) ?? defaultIcon
            }
            //后续larkIconDisable fg删掉，后面的代码也删除
            return DocsIconCreateUtil.creatImageWithEmoji(emoji: emoji,
                                                          isShortCut: container?.isShortCut ?? false)
        }
    }
    
    
}
