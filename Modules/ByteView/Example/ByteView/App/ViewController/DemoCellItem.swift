//
//  DemoCellItem.swift
//  ByteView_Example
//
//  Created by kiri on 2023/8/31.
//

import Foundation
import UIKit

struct DemoCellSection {
    let title: String?
    let rows: [DemoCellRow]
}

struct DemoCellRow {
    let type: DemoCellType
    let title: String
    var action: () -> Void = { }
    var isOn: Bool = false
    var swAction: (Bool) -> Void = { _ in }

    init(title: String, action: @escaping () -> Void) {
        self.type = .normal
        self.title = title
        self.action = action
    }

    private init(_ type: DemoCellType, title: String, action: @escaping () -> Void,
                 isOn: Bool, swAction: @escaping (Bool) -> Void) {
        self.type = type
        self.title = title
        self.action = action
        self.isOn = isOn
        self.swAction = swAction
    }

    static func swCell(title: String, isOn: Bool, action: @escaping (Bool) -> Void) -> DemoCellRow {
        DemoCellRow(.swCell, title: title, action: { }, isOn: isOn, swAction: action)
    }

    static func checkmark(title: String, isOn: Bool, action: @escaping (Bool) -> Void) -> DemoCellRow {
        DemoCellRow(.checkmark, title: title, action: { }, isOn: isOn, swAction: action)
    }
}

enum DemoCellType: String {
    case normal
    case swCell
    case checkmark
}
