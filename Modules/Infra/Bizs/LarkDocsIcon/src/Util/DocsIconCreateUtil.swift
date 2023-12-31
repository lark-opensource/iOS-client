//
//  DocsIconCreateUtil.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/6/14.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignTheme

private typealias stepBlock = () -> Void
private class DocsIconCreate {
    
    //输出图片大小
    private let outputImageSize: CGSize
    
    //改变fontSize，可以调整emoji的大小  *1.2是为了让图标更大一定，填充满背景
    // nolint: magic_number
    private var emojiScale: CGFloat {
        return 1.2
    }
    
    //如果设置了背景颜色，则需要缩小图片大小
    // nolint: magic_number
    private var emojiScaleWithBackground: CGFloat {
        return 0.65
    }
    
    //背景颜色
    private var circleBackgroundStep: stepBlock?
    private var createImageStep: stepBlock?
    private var createShortCutImageStep: stepBlock?
    private var createEmojiStep: stepBlock?
    
    public init(size: CGFloat) {
        outputImageSize = CGSize.init(width: size, height: size)
    }
    
    @discardableResult
    func setCircleBackground(color: UIColor) -> Self {
        self.circleBackgroundStep = { [weak self] in
            guard let self = self else {
                return
            }

            //绘制一个圆形
            let path = UIBezierPath.init(ovalIn: CGRectMake(0, 0, self.outputImageSize.width, self.outputImageSize.height))
            path.addClip()
          
            //填充背景颜色
            let color: UIColor = color
            color.setFill()
            UIRectFill(CGRectMake(0, 0, self.outputImageSize.width, self.outputImageSize.height))
        }
        return self
    }
    
    //设置当前图片
    @discardableResult
    func setImage(image: UIImage) -> Self {
        self.createImageStep = { [weak self] in
            guard let self = self else {
                return
            }
            
            let size = self.outputImageSize
            var imageSize = size  //绘制圆型的时候，中间图标大小设置
            
            if self.circleBackgroundStep != nil { //如果设置了背景颜色，则需要缩小图片大小
                imageSize = CGSize(width: size.width * 0.6, height: size.height * 0.6)
            }

            let imageBound = CGRect(x: (size.width - imageSize.width) / 2,
                                    y: (size.height - imageSize.height) / 2,
                                    width: imageSize.width,
                                    height: imageSize.height)
            image.draw(in: imageBound)
            
        }
        return self
    }
    
    // 生成emoji表情
    @discardableResult
    func setEmoji(emoji: String) -> Self {
        self.createEmojiStep = { [weak self] in
            guard let self = self else {
                return
            }
            
            let baseSize = emoji.boundingRect(with: CGSize(width: 2048, height: 2048),
                                             options: .usesLineFragmentOrigin,
                                              attributes: [.font: UIFont.systemFont(ofSize: self.outputImageSize.width / 2.0)], context: nil).size
            
            //改变fontSize，可以调整emoji的大小  *1.2是为了让图标更大一定，填充满背景
            var fontSize = self.outputImageSize.width / max(baseSize.width, baseSize.height) * (self.outputImageSize.width / 2.0) * self.emojiScale
            
            if self.circleBackgroundStep != nil { //如果设置了背景颜色，则需要缩小图片大小
                fontSize = fontSize * self.emojiScaleWithBackground
            }
            
            let font = UIFont.systemFont(ofSize: fontSize)
            let textSize = emoji.boundingRect(with: CGSize(width: self.outputImageSize.width, height: self.outputImageSize.height),
                                             options: .usesLineFragmentOrigin,
                                             attributes: [.font: font], context: nil).size
            
            
            let style = NSMutableParagraphStyle()
            style.alignment = NSTextAlignment.center
//            style.lineBreakMode = NSLineBreakMode.byClipping

            let attr : [NSAttributedString.Key : Any] = [NSAttributedString.Key.font : font,
                                                         NSAttributedString.Key.paragraphStyle: style,
                                                         NSAttributedString.Key.backgroundColor: UIColor.clear ]


            //绘制emoji图标
            emoji.draw(in: CGRect(x: (self.outputImageSize.width - textSize.width) / 2.0,
                                  y: (self.outputImageSize.height - textSize.height) / 2.0,
                                 width: textSize.width,
                                 height: textSize.height),
                                 withAttributes: attr)
            
        }
        return self
    }
    
    //设置快捷方式图片
    @discardableResult
    func setShortCutImage() -> Self {
        self.createShortCutImageStep = { [weak self] in
            guard let self = self else {
                return
            }
            
            let shortCutImage = UDIcon.wikiShortcutarrowColorful
            let shortCutImageBound = CGRect(x: 0,
                                            y: 0,
                                            width: self.outputImageSize.width,
                                            height: self.outputImageSize.height)
            shortCutImage.draw(in: shortCutImageBound)
            
        }
        return self
    }
    
    
    //生成图片
    func createImage() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.outputImageSize, false, 0)
        
        if let circleBackgroundStep = self.circleBackgroundStep {
            circleBackgroundStep()
        }
        
        if let createImageStep = self.createImageStep {
            createImageStep()
        }
        
        if let createEmojiStep = self.createEmojiStep {
            createEmojiStep()
        }
        
        if let createShortCutImageStep = self.createShortCutImageStep {
            createShortCutImageStep()
        }
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let newImage = newImage else { //如果设置尺寸异常，是会拿不到绘制的图片的可能
            DocsIconLogger.logger.error("createImage is nil, outputImageSize: \(outputImageSize)")
            //拿不到绘制的图片，做下兜底默认图处理, 有背景色返回圆形图标，没有返回方形图标
            let defultImage: UDIconType = self.circleBackgroundStep != nil ? .fileRoundUnknowColorful : .fileUnknowColorful
            return UDIcon.getIconByKeyNoLimitSize(defultImage)
        }
        
        return newImage
        
    }
    
    
    
}

class DocsIconCreateUtil {
    
    //图片默认大小
    // nolint: magic_number
    private static var iconDefultSize: CGFloat {
        return 44
    }
    
    //通过Image创建文档图标
    static func creatImage(image: UIImage, isShortCut: Bool = false, backgroudColor: UIColor? = nil) -> UIImage {
        if isShortCut == false && backgroudColor == nil {
            return image
        }
    
        var createImage = DocsIconCreate(size: iconDefultSize)
        
        //为了便于理解，分4种情况处理，可能存在重复的代码，如果需要重构，建议重构得容易理解点
        
        //1. 有背景颜色，没有快捷方式
        //2. 有背景颜色，有快捷方式
        //3. 没有背景颜色，有快捷方式
        //4. 没有背景颜色，没有快捷方式
        
        if let color = backgroudColor, isShortCut == false { //1. 有背景颜色，没有快捷方式
        
            createImage.setCircleBackground(color: color)
                .setImage(image: image)
            
        } else if let color = backgroudColor, isShortCut == true  { //2. 有背景颜色，有快捷方式
            
            createImage.setCircleBackground(color: color)
                .setImage(image: image)
            
            //如果有背景颜色圆形，还有快捷方式，需要重写开启一张方形的画布，进行增加快捷方式，要不绘制快捷方式会被截断，这里后续看下是否可以优化
            let tempImage = createImage.createImage()
            createImage = DocsIconCreate(size: max(tempImage.size.width, tempImage.size.height))
            createImage.setImage(image: tempImage)
                .setShortCutImage()
            
        } else if backgroudColor == nil && isShortCut == true {// 3.没有背景颜色，有快捷方式
            
            createImage.setImage(image: image)
                .setShortCutImage()
            
        } else { //4. 没有背景颜色，没有快捷方式 : isShortCut == false && backgroudColor == nil
            
            //直接返回image图片
            createImage.setImage(image: image)
             
        }
        return createImage.createImage()
    }
    
    //通过Emoji创建文档图标
    static func creatImageWithEmoji(emoji: String, isShortCut: Bool = false, backgroudColor: UIColor? = nil) -> UIImage {

    
        var createImage = DocsIconCreate(size: iconDefultSize)
        
        //为了便于理解，分4种情况处理，可能存在重复的代码，如果需要重构，建议重构得容易理解点
        
        //1. 有背景颜色，没有快捷方式
        //2. 有背景颜色，有快捷方式
        //3. 没有背景颜色，有快捷方式
        //4. 没有背景颜色，没有快捷方式
        
        if let color = backgroudColor, isShortCut == false { //1. 有背景颜色，没有快捷方式
            
            createImage.setCircleBackground(color: color)
                .setEmoji(emoji: emoji)
            
        } else if let color = backgroudColor, isShortCut == true  { //2. 有背景颜色，有快捷方式
            
            createImage.setCircleBackground(color: color)
                .setEmoji(emoji: emoji)
            
            //如果有背景颜色圆形，还有快捷方式，需要重写开启一张方形的画布，进行增加快捷方式，要不绘制快捷方式会被截断，这里后续看下是否可以优化
            let tempImage = createImage.createImage()
            createImage = DocsIconCreate(size: max(tempImage.size.width, tempImage.size.height))
            createImage.setImage(image: tempImage)
                .setShortCutImage()
            
        } else if backgroudColor == nil && isShortCut == true {// 3.没有背景颜色，有快捷方式
            
            createImage.setEmoji(emoji: emoji)
                .setShortCutImage()
            
        } else { //4. 没有背景颜色，没有快捷方式 : isShortCut == false && backgroudColor == nil
            
            //直接返回Emoji图片
            createImage.setEmoji(emoji: emoji)
             
        }
        
        return createImage.createImage()
    }
}
