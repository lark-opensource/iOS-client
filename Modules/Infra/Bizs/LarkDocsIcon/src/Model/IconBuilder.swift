//
//  IconBuilder.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/11/15.
//

import Foundation

public struct IconExtend {
    //形状
    public var shape: IconShpe = .SQUARE
    //圆形可以传入背景颜色
    public var backgroundColor: UIColor?
    //默认图标
    public var placeHolderImage: UIImage?
    
    public init(shape: IconShpe = .SQUARE, backgroundColor: UIColor? = nil, placeHolderImage: UIImage? = nil) {
        self.shape = shape
        self.backgroundColor = backgroundColor
        self.placeHolderImage = placeHolderImage
    }
}

public enum BizIconType {
    case docsWithUrl(iconInfo: String?, url: String, container: ContainerInfo)
    case docsWithToken(iconInfo: String?, token: String, type: CCMDocsType, container: ContainerInfo)
    case iconInfo(iconType: Int, iconKey: String, textColor: String? = nil)
}

public struct IconBuilder {
    
    public init(bizIconType: BizIconType, iconExtend: IconExtend = IconExtend(shape: .SQUARE)) {
        self.bizIconType = bizIconType
        self.iconExtend = iconExtend
    }
    
    public var bizIconType: BizIconType
    public var iconExtend: IconExtend
    
}
