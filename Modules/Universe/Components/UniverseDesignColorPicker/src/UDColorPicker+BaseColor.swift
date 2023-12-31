//
//  UDColorPicker+BaseColor.swift
//  UDKit
//
//  Created by zfpan on 2020/11/13.
//  Copyright © 2020年 panzaofeng. All rights reserved.
//

import Foundation
import UniverseDesignColor

extension UDColorPickerConfig {
    //默认颜色组Model
    public static func defaultModel(category: UDPaletteItemsCategory,
                                    title: String) -> UDPaletteModel {
        var model: UDPaletteModel
        switch category {
        case .basic:
            model = UDColorPickerConfig.constructBasicModel(title: title)
        case .text:
            model = UDColorPickerConfig.constructTextModel(title: title)
        case .background:
            model = UDColorPickerConfig.constructBackgroundModel(title: title)
        }
        return model
    }
    //默认的基础组颜色
    private static func constructBasicModel(title: String) -> UDPaletteModel {
        return UDPaletteModel(category: .basic, title: title,
                              items: [UDPaletteItem(color: UDColorPickerColorTheme.baseModelColor0),
                                      UDPaletteItem(color: UDColorPickerColorTheme.baseModelColor1),
                                      UDPaletteItem(color: UDColorPickerColorTheme.baseModelColor2),
                                      UDPaletteItem(color: UDColorPickerColorTheme.baseModelColor3),
                                      UDPaletteItem(color: UDColorPickerColorTheme.baseModelColor4),
                                      UDPaletteItem(color: UDColorPickerColorTheme.baseModelColor5),
                                      UDPaletteItem(color: UDColorPickerColorTheme.baseModelColor6),
                                      UDPaletteItem(color: UDColorPickerColorTheme.baseModelColor7),
                                      UDPaletteItem(color: UDColorPickerColorTheme.baseModelColor8),
                                      UDPaletteItem(color: UDColorPickerColorTheme.baseModelColor9),
                                      UDPaletteItem(color: UDColorPickerColorTheme.baseModelColor10),
                                      UDPaletteItem(color: UDColorPickerColorTheme.baseModelColor11)])
    }
    //默认的文字组颜色
    private static func constructTextModel(title: String) -> UDPaletteModel {
        return UDPaletteModel(category: .text, title: title,
                              items: [UDPaletteItem(color: UDColorPickerColorTheme.textModelColor0),
                                      UDPaletteItem(color: UDColorPickerColorTheme.textModelColor1),
                                      UDPaletteItem(color: UDColorPickerColorTheme.textModelColor2),
                                      UDPaletteItem(color: UDColorPickerColorTheme.textModelColor3),
                                      UDPaletteItem(color: UDColorPickerColorTheme.textModelColor4),
                                      UDPaletteItem(color: UDColorPickerColorTheme.textModelColor5),
                                      UDPaletteItem(color: UDColorPickerColorTheme.textModelColor6)])
    }
    //默认的文字背景组颜色
    private static func constructBackgroundModel(title: String) -> UDPaletteModel {
        return UDPaletteModel(category: .background, title: title,
                              items: [UDPaletteItem(color: UDColorPickerColorTheme.textBackgroundModelColor0),
                                      UDPaletteItem(color: UDColorPickerColorTheme.textBackgroundModelColor1),
                                      UDPaletteItem(color: UDColorPickerColorTheme.textBackgroundModelColor2),
                                      UDPaletteItem(color: UDColorPickerColorTheme.textBackgroundModelColor3),
                                      UDPaletteItem(color: UDColorPickerColorTheme.textBackgroundModelColor4),
                                      UDPaletteItem(color: UDColorPickerColorTheme.textBackgroundModelColor5),
                                      UDPaletteItem(color: UDColorPickerColorTheme.textBackgroundModelColor6),
                                      UDPaletteItem(color: UDColorPickerColorTheme.textBackgroundModelColor7),
                                      UDPaletteItem(color: UDColorPickerColorTheme.textBackgroundModelColor8),
                                      UDPaletteItem(color: UDColorPickerColorTheme.textBackgroundModelColor9),
                                      UDPaletteItem(color: UDColorPickerColorTheme.textBackgroundModelColor10),
                                      UDPaletteItem(color: UDColorPickerColorTheme.textBackgroundModelColor11),
                                      UDPaletteItem(color: UDColorPickerColorTheme.textBackgroundModelColor12),
                                      UDPaletteItem(color: UDColorPickerColorTheme.textBackgroundModelColor13)])
    }
}
