//
//  WaterMarkManagerProtocol.swift
//  LarkWaterMark
//
//  Created by Xingjian Sun on 2022/11/7.
//

import UIKit
import Foundation
import LarkRustClient
import RxSwift
import RxCocoa
import LarkDebugExtensionPoint

public enum WaterMarkContext {
    case `some`(window: UIWindow)
}

struct WaterMarkDebugItem: DebugCellItem {
    var title: String { return "Show Watermark" }
    let type: DebugCellType = .switchButton

    var isSwitchButtonOn: Bool { return false }

    let switchValueDidChange: ((Bool) -> Void)?

    init(switchValueDidChange: ((Bool) -> Void)? = nil) {
        self.switchValueDidChange = switchValueDidChange
    }
}

protocol WaterMarkManagerProtocol: WaterMarkService {}
