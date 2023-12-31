//
//  IconLayer.swift
//  LarkIcon
//
//  Created by huangzhikai on 2023/12/14.
//

import Foundation

//图标形状
public enum LarkIconShape {
    case SQUARE //方形
    case CIRCLE //圆形
    case CORNERRADIUS(value: CGFloat) //圆角
}

public struct IconLayer {
    
    //边框
    public struct Border {
        public var borderWidth: CGFloat //边框宽度
        public var borderColor: UIColor //边框颜色
        public init(borderWidth: CGFloat, borderColor: UIColor) {
            self.borderWidth = borderWidth
            self.borderColor = borderColor
        }
    }
    
    public var backgroundColor: UIColor? //背景颜色
    public var border: Border? //边框
    public init(backgroundColor: UIColor? = nil, border: Border? = nil) {
        self.backgroundColor = backgroundColor
        self.border = border
    }
}

// 前景色设置
public struct IconForeground {
    public var foregroundImage: UIImage? //叠加前景图片
    public init(foregroundImage: UIImage? = nil) {
        self.foregroundImage = foregroundImage
    }
}

