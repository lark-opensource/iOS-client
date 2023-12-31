//
//  MainImageTransform.swift
//  LarkIcon
//
//  Created by huangzhikai on 2023/12/14.
//

import Foundation
import UIKit
class MainImageTransform: LarkIconTransformProtocol {
    private let image: UIImage?
    private var scale: CGFloat?
    //图标设置了背景色，图标缩小0.6
    init(image: UIImage?, scale: CGFloat?) {
        self.image = image
        if let scale = scale {
            self.scale = scale > 1 ? 1 : scale
        }
        
    }
    
    func beginTransform(with context: CGContext, builderExtend: BuilderExtend) {
        
        guard let image = self.image else {
            return
        }
        
        let size = builderExtend.canvasSize
        var imageSize = size  //绘制圆型的时候，中间图标大小设置
        
        if let scale = self.scale { //一般有设置了背景颜色，可以传入scale缩小中间图片大小
            imageSize = CGSize(width: size.width * scale, height: size.height * scale)
        }
        
        let imageBound = CGRect(x: (size.width - imageSize.width) / 2,
                                y: (size.height - imageSize.height) / 2,
                                width: imageSize.width,
                                height: imageSize.height)
        
        
        // 翻转坐标系
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        
        if let cgImage = image.cgImage {
            context.draw(cgImage, in: imageBound)
        }
    }
    
}
