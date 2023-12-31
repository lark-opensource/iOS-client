//
//  LarkIconBuilder+Factory.swift
//  LarkIcon
//
//  Created by huangzhikai on 2023/12/14.
//

import Foundation
import UniverseDesignTheme

extension LarkIconBuilder {
    //传入图片进行渲染
    public static func createImageWith(originImage: UIImage?,
                                       scale: CGFloat? = nil,
                                       iconLayer: IconLayer? = nil,
                                       iconShape: LarkIconShape? = .SQUARE,
                                       foreground: IconForeground? = nil) -> UIImage? {
        
        //没有颜色渲染，不用处理暗黑模式
        guard let iconLayer = iconLayer, (iconLayer.backgroundColor != nil || iconLayer.border?.borderColor != nil) else {
            let image = LarkIconBuilder()
                .addTransform(ShapeTransform(iconLayer: iconLayer, iconShape: iconShape))
                .addTransform(MainImageTransform(image: originImage, scale: scale))
                .addTransform(ForegroundTransform(foreground: foreground))
                .build()
            return image
        }
        
        //需要处理暗黑模式
        let resultLayer = self.changerLayer(iconLayer: iconLayer)
        
        let lightImage = LarkIconBuilder()
            .addTransform(ShapeTransform(iconLayer: resultLayer.lightLayer, iconShape: iconShape))
            .addTransform(MainImageTransform(image: originImage, scale: scale))
            .addTransform(ForegroundTransform(foreground: foreground))
            .build()
        
        let darkImage = LarkIconBuilder()
            .addTransform(ShapeTransform(iconLayer: resultLayer.darkLayer, iconShape: iconShape))
            .addTransform(MainImageTransform(image: originImage, scale: scale))
            .addTransform(ForegroundTransform(foreground: foreground))
            .build()
        
        if let lightImage, let darkImage {
            return lightImage & darkImage
        }
        
        return lightImage ?? darkImage
        
    }
    
    //传入emoji进行进行渲染
    public static func createImageWith(emoji: String,
                                       scale: CGFloat? = nil,
                                       iconLayer: IconLayer? = nil,
                                       iconShape: LarkIconShape? = .SQUARE,
                                       foreground: IconForeground? = nil) -> UIImage? {
        
        
        let emojiImage = LarkIconEmoji().generateEmojiImage(emoji: emoji)
        
        //如果有颜色，则需要处理下暗黑模式
        //没有颜色渲染，不用处理暗黑模式
        guard let iconLayer = iconLayer, (iconLayer.backgroundColor != nil || iconLayer.border?.borderColor != nil) else {
            let image = LarkIconBuilder()
                .addTransform(ShapeTransform(iconLayer: iconLayer, iconShape: iconShape))
                .addTransform(MainImageTransform(image: emojiImage, scale: scale))
                .addTransform(ForegroundTransform(foreground: foreground))
                .build()
            return image
        }
        
        //需要处理暗黑模式
        let resultLayer = self.changerLayer(iconLayer: iconLayer)
        
        let lightImage = LarkIconBuilder()
            .addTransform(ShapeTransform(iconLayer: resultLayer.lightLayer, iconShape: iconShape))
            .addTransform(MainImageTransform(image: emojiImage, scale: scale))
            .addTransform(ForegroundTransform(foreground: foreground))
            .build()
        
        
        
        let darkImage = LarkIconBuilder()
            .addTransform(ShapeTransform(iconLayer: resultLayer.darkLayer, iconShape: iconShape))
            .addTransform(MainImageTransform(image: emojiImage, scale: scale))
            .addTransform(ForegroundTransform(foreground: foreground))
            .build()
        
        if let lightImage, let darkImage {
            return lightImage & darkImage
        }
        
        return lightImage ?? darkImage
    }
    
    //传入文本进行进行渲染
    public static func createImageWith(word: String?,
                                       iconLayer: IconLayer? = nil,
                                       iconShape: LarkIconShape? = .SQUARE,
                                       foreground: IconForeground? = nil) -> UIImage? {
        
        
        
        
        //如果有颜色，则需要处理下暗黑模式
        //没有颜色渲染，不用处理暗黑模式
        guard let iconLayer = iconLayer, (iconLayer.backgroundColor != nil || iconLayer.border?.borderColor != nil) else {
            
            let image = LarkIconBuilder()
                .addTransform(ShapeTransform(iconLayer: iconLayer, iconShape: iconShape))
                .addTransform(WorkTransform(word: word, color: iconLayer?.border?.borderColor))
                .addTransform(ForegroundTransform(foreground: foreground))
                .build()
            
            return image
        }
        
        //需要处理暗黑模式
        let resultLayer = self.changerLayer(iconLayer: iconLayer)
        
        let lightImage = LarkIconBuilder()
            .addTransform(ShapeTransform(iconLayer: resultLayer.lightLayer, iconShape: iconShape))
            .addTransform(WorkTransform(word: word, color: iconLayer.border?.borderColor))
            .addTransform(ForegroundTransform(foreground: foreground))
            .build()
        
        
        
        let darkImage = LarkIconBuilder()
            .addTransform(ShapeTransform(iconLayer: resultLayer.darkLayer, iconShape: iconShape))
            .addTransform(WorkTransform(word: word, color: iconLayer.border?.borderColor))
            .addTransform(ForegroundTransform(foreground: foreground))
            .build()
        
        if let lightImage, let darkImage {
            return lightImage & darkImage
        }
        
        return lightImage ?? darkImage
    }
    
    static func changerLayer(iconLayer: IconLayer) -> (lightLayer: IconLayer, darkLayer: IconLayer) {
        //重新构建下light Model layer
        var lightLayer = IconLayer(backgroundColor: iconLayer.backgroundColor?.alwaysLight)
        if let border = iconLayer.border {
            lightLayer.border = IconLayer.Border(borderWidth: border.borderWidth,
                                                 borderColor: border.borderColor.alwaysLight)
        }
        
        //重新构建下dark Model layer
        var darkLayer = IconLayer(backgroundColor: iconLayer.backgroundColor?.alwaysDark)
        if let border = iconLayer.border {
            darkLayer.border = IconLayer.Border(borderWidth: border.borderWidth,
                                                borderColor: border.borderColor.alwaysDark)
        }
        
        return (lightLayer: lightLayer, darkLayer: darkLayer)
    }
}
