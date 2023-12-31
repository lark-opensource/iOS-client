//
//  TabState.swift
//  LarkNavigation
//
//  Created by Meng on 2019/10/14.
//

import UIKit
import Foundation
import AnimatedTabBar

final class DefaultTabState: ItemStateProtocol {
    func selectedUserEvent(icon: UIImageView, title: UILabel, config: ItemStateConfig) {
        icon.layer.lu.bounceAnimation(duration: TimeInterval(0.25))
        icon.image = config.selectedIcon
        title.textColor = config.selectedTitleColor
    }
}

final class CalendarTabState: ItemStateProtocol {
    func selectedUserEvent(icon: UIImageView, title: UILabel, config: ItemStateConfig) {
        setIconState(icon, selecteState: true)
        title.textColor = config.selectedTitleColor
    }

    func selectedState(icon: UIImageView, title: UILabel, config: ItemStateConfig) {
        setIconState(icon, selecteState: true)
        title.textColor = config.selectedTitleColor
    }

    func deselectState(icon: UIImageView, title: UILabel, config: ItemStateConfig) {
        setIconState(icon, selecteState: false)
        title.textColor = config.defaultTitleColor
    }

    private func setIconState(_ icon: UIImageView, selecteState: Bool) {
        icon.subviews.forEach { (view) in
            if let control = view as? UIControl {
                control.isSelected = selecteState
            }
        }
    }
}
