//
//  ForegroundTransform.swift
//  LarkIcon
//
//  Created by huangzhikai on 2023/12/14.
//

import Foundation
class ForegroundTransform: LarkIconTransformProtocol {
    private let foreground: IconForeground?
    init(foreground: IconForeground? = nil) {
        self.foreground = foreground
    }
    
    func beginTransform(with context: CGContext, builderExtend: BuilderExtend) {
        
        guard let foreground = self.foreground else {
            return
        }
        
        guard let image = foreground.foregroundImage else {
            return
        }
        let size = builderExtend.canvasSize
        let imageBound = CGRect(x: 0,
                                y: 0,
                                width: size.width,
                                height: size.height)
        
        // 翻转坐标系
        //        context.translateBy(x: 0, y: size.height)
        //        context.scaleBy(x: 1.0, y: -1.0)
        
        
        if let cgImage = image.cgImage {
            context.draw(cgImage, in: imageBound)
        }
    }
}
