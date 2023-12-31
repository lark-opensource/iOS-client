//
//  ShapeTransform.swift
//  LarkIcon
//
//  Created by huangzhikai on 2023/12/13.
//

import Foundation

class ShapeTransform: LarkIconTransformProtocol {
    private var iconLayer: IconLayer?
    private var iconShape: LarkIconShape?
    init(iconLayer: IconLayer?, iconShape: LarkIconShape?) {
        self.iconLayer = iconLayer
        self.iconShape = iconShape
    }
    
    func beginTransform(with context: CGContext, builderExtend: BuilderExtend) {
        
        //都为空，不进行绘制
        guard iconLayer != nil || iconShape != nil else {
            return
        }
        
        var radius = 0.0
        var path = UIBezierPath(roundedRect: CGRectMake(0, 0, builderExtend.canvasSize.width, builderExtend.canvasSize.height), cornerRadius: radius)
        
        //绘制圆角
        if let cornerRadius = self.iconShape {
            if case .CIRCLE = cornerRadius {
                radius = builderExtend.canvasSize.width / 2
            } else if case .CORNERRADIUS(let value) = cornerRadius {
                radius = value
            }
            path = UIBezierPath(roundedRect: CGRectMake(0, 0, builderExtend.canvasSize.width, builderExtend.canvasSize.height), cornerRadius: radius)
            path.addClip()
            context.addPath(path.cgPath)
        }
        
        // 绘制背景色
        if let backgroundColor = self.iconLayer?.backgroundColor {
            context.setFillColor(backgroundColor.cgColor)
            context.fill(CGRectMake(0, 0, builderExtend.canvasSize.width, builderExtend.canvasSize.height))
        }
        
        // 绘制边框和颜色
        if let border = self.iconLayer?.border {
            context.setStrokeColor(border.borderColor.cgColor)
            context.setLineWidth(border.borderWidth)
            context.addPath(path.cgPath)
        } else { //这里需要设置下linewidth为0，要不，没有设置背景色，默认会有个边框
            context.setLineWidth(0)
            context.addPath(path.cgPath)
        }
        
        context.strokePath()
    }
    
}
