//
//  UdRadius.swift
//  Pods-UniverseDesignStyleDev
//
//  Created by 强淑婷 on 2020/8/11.
//

import Foundation
import UIKit

extension UDStyle {
    /// Radius-XS, 标签 Tag / Basic, 进度条 Progress Value: 2
    public static var lessSmallRadius: CGFloat {
        return UDStyle.getValueByKey(.lessSmallRadius) ?? 2
    }

    /// Radius-S,  适用于按钮、输入框、全局提示等小型组件 Value: 4
    public static var smallRadius: CGFloat {
        return UDStyle.getValueByKey(.smallRadius) ?? 4
    }

    /// Radius-M, 适用于工具栏等承载小型组件卡片容器组件 Value: 6
    public static var middleRadius: CGFloat {
        return UDStyle.getValueByKey(.middleRadius) ?? 6
    }

    /// Radius-L, 适用于承载较复杂内容的大卡片容器组件 Value: 8
    public static var largeRadius: CGFloat {
        return UDStyle.getValueByKey(.largeRadius) ?? 8
    }

    /// Radius-XL, 适用于需要聚焦、提升用户点击率或关注度的组件 Value: 10
    public static var moreLargeRadius: CGFloat {
        return UDStyle.getValueByKey(.moreLargeRadius) ?? 10
    }

    /// Radius-XXL, IG新增特大圆角 Value: 12
    public static var superLargeRadius: CGFloat {
        return UDStyle.getValueByKey(.superLargeRadius) ?? 12
    }

}
