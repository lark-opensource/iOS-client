//
//  IconBuilderManager+Default.swift
//  LarkIcon
//
//  Created by ByteDance on 2023/12/14.
//

import Foundation
import RxSwift

extension LarkIconManager {
    
    func createDefultIcon() -> LIResult {
        var layer = self.iconExtend.layer
        var scale: CGFloat? = nil
        //圆形的按照标准，暂时缩小0.6
        if case .CIRCLE = self.iconExtend.shape {
            scale = self.circleScale
        } else { //方形和圆角则不处理背景色
            layer?.backgroundColor = nil
        }
        
        let image = LarkIconBuilder.createImageWith(originImage: self.iconExtend.placeHolderImage, 
                                                    scale: scale,
                                                    iconLayer: layer,
                                                    iconShape: self.iconExtend.shape,
                                                    foreground: self.iconExtend.foreground)
        
        return (image: image, error: nil)
    }
}
