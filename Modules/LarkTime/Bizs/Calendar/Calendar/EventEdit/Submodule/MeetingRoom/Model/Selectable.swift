//
//  Selectable.swift
//  Calendar
//
//  Created by Rico on 2021/5/11.
//

import UIKit
import Foundation
import CalendarFoundation
import UniverseDesignTheme
import UniverseDesignCheckBox

// 对会议室多选数据模型的扩展
struct Selectable<RawType> {

    let raw: RawType
    var isSelected: SelectType?

    init(_ raw: RawType, isSelected: SelectType? = nil) {
        self.raw = raw
        self.isSelected = isSelected
    }
}

enum SelectType: Equatable {
    case nonSelected
    case halfSelected
    case selected
    case disabled

    var boxType: UDCheckBoxType {
        if case .halfSelected = self {
            return .mixed
        } else { return .multiple }
    }

    // 点击之后的状态切换
    func toggle() -> Self {
        switch self {
        case .nonSelected: return .selected
        case .halfSelected: return .selected
        case .selected: return .nonSelected
        case .disabled: return .disabled
        }
    }
}
