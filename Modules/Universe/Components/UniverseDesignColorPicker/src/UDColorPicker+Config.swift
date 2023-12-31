//
//  UDColorPickerConfig.swift
//  UDKit
//
//  Created by zfpan on 2020/11/13.
//  Copyright © 2020年 panzaofeng. All rights reserved.
//

import UIKit
import Foundation

/// 提供通用样式配置
public enum UDPaletteItemsCategory {
    /// 基础颜色选择器
    case basic
    /// 字体景颜色
    case text
    /// 字体背景颜色
    case background
}

public struct UDPaletteItem: Equatable {
    //色块的颜色
    let color: UIColor

    public init(color: UIColor) {
        self.color = color
    }

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1) {
        self.color = UIColor(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha)
    }
}

public struct UDPaletteModel: Equatable {
    // colorPicker类型
    var category: UDPaletteItemsCategory
    // colorPicker标题
    var title: String
    //colorPicker的色块组
    var items: [UDPaletteItem]
    //选中的色块Index
    var selectedIndex: Int

    public init(category: UDPaletteItemsCategory, title: String, items: [UDPaletteItem], selectedIndex: Int = 0) {
        self.category = category
        self.title = title
        self.items = items
        self.selectedIndex = selectedIndex
    }
}

public struct UDColorPickerConfig: Equatable {

    /// 配置背景色
    public var backgroundColor: UIColor
    
    /// colorPicker Model组， 每一组表示一种类型， colorpicker支持一次显示多组
    public var models: [UDPaletteModel]

    public init(models: [UDPaletteModel]) {
        self.models = models
        self.backgroundColor = UDColorPickerColorTheme.colorPickerBgColor
    }
    
    public init(models: [UDPaletteModel], backgroudColor: UIColor) {
        self.models = models
        self.backgroundColor = backgroudColor
    }
}
