//
//  EnterpriseCallItem.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/7/5.
//

import Foundation
import UniverseDesignIcon

class EnterpriseCallItem {
    var title: String
    var icon: UDIconType
    var action: (() -> Void)?
    var isEnabled = true
    var isHighlighted = false

    private(set) lazy var throttledAction: Throttle<Void> = {
        throttle(interval: .milliseconds(600)) { [weak self] in
            self?.action?()
        }
    }()

    init(title: String, icon: UDIconType) {
        self.title = title
        self.icon = icon
    }
}
