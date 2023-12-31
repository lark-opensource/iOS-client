//
//  LarkIconEmoji.swift
//  testUI
//
//  Created by huangzhikai on 2023/12/14.
//

import Foundation
import UIKit

class LarkIconEmoji {
    // nolint: magic_number
    static let defultSize: CGFloat = 44
    private var outputImageSize: CGSize
    //改变fontSize，可以调整emoji的大小  *1.2是为了让图标更大一定，填充满背景
    // nolint: magic_number
    private var emojiScale: CGFloat = 1.2
    
    init(size: CGFloat = defultSize) {
        outputImageSize = CGSize(width: size, height: size)
    }
    
    func generateEmojiImage(emoji: String) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.outputImageSize, false, 0)
        
        let baseSize = emoji.boundingRect(with: CGSize(width: 2048, height: 2048),
                                          options: .usesLineFragmentOrigin,
                                          attributes: [.font: UIFont.systemFont(ofSize: self.outputImageSize.width / 2.0)], context: nil).size
        
        //改变fontSize，可以调整emoji的大小  *1.2是为了让图标更大一定，填充满背景
        let fontSize = self.outputImageSize.width / max(baseSize.width, baseSize.height) * (self.outputImageSize.width / 2.0) * self.emojiScale
        
        
        let font = UIFont.systemFont(ofSize: fontSize)
        let textSize = emoji.boundingRect(with: CGSize(width: self.outputImageSize.width, height: self.outputImageSize.height),
                                          options: .usesLineFragmentOrigin,
                                          attributes: [.font: font], context: nil).size
        
        
        let style = NSMutableParagraphStyle()
        style.alignment = NSTextAlignment.center
        
        let attr : [NSAttributedString.Key : Any] = [NSAttributedString.Key.font : font,
                                                     NSAttributedString.Key.paragraphStyle: style,
                                                     NSAttributedString.Key.backgroundColor: UIColor.clear ]
        
        
        //绘制emoji图标
        emoji.draw(in: CGRect(x: (self.outputImageSize.width - textSize.width) / 2.0,
                              y: (self.outputImageSize.height - textSize.height) / 2.0,
                              width: textSize.width,
                              height: textSize.height),
                   withAttributes: attr)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
        
    }
}
