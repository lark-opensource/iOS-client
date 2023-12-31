//
//  DemoCellItem.swift
//  ByteView_Example
//
//  Created by kiri on 2023/8/31.
//

import Foundation
import UIKit

struct DemoCellItem {
    let title: String
    let isOn: Bool
    let action: () -> Void
    var data: Any?

    init(title: String, isOn: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.action = action
        self.isOn = isOn
    }
}
