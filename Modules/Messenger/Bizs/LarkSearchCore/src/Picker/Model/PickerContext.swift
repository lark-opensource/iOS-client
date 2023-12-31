//
//  PickerContext.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/4/7.
//

import Foundation
import LarkModel

class PickerContext {
    enum Style {
        case picker // 传统Picker样式, 参考创建群组
        case search // 大搜样式
    }
    var style: Style = .search
    var tenantId: String = ""
    var userId: String = ""
    var featureConfig = PickerFeatureConfig()
}
