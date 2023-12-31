//
// Created by duanxiaochen.7 on 2021/4/27.
// Affiliated with SKBitable.
//
// Description:

import UIKit
import HandyJSON

/// 数字字段，区分 rawValue 和 formattedValue
struct BTNumberModel: HandyJSON, Equatable {
    static func == (lhs: BTNumberModel, rhs: BTNumberModel) -> Bool {
        return lhs.rawValue == rhs.rawValue &&
               lhs.formattedValue == rhs.formattedValue

    }
    var rawValue: Double = 0
    var formattedValue: String = ""

    mutating func mapping(mapper: HelpingMapper) {
        mapper <<< self.rawValue <-- "numberValue"
        mapper <<< self.formattedValue <-- "formatterValue"
    }
}
