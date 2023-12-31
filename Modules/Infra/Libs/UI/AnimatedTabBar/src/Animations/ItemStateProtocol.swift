//
//  ItemStateProtocol.swift
//  AnimatedTabBar
//
//  Created by Meng on 2019/11/4.
//

import UIKit
import Foundation
import LarkExtensions

public protocol ItemStateProtocol: AnyObject {
    func selectedUserEvent(icon: UIImageView, title: UILabel, config: ItemStateConfig)
    func selectedState(icon: UIImageView, title: UILabel, config: ItemStateConfig)
    func deselectState(icon: UIImageView, title: UILabel, config: ItemStateConfig)
}

extension ItemStateProtocol {
    public func selectedUserEvent(icon: UIImageView, title: UILabel, config: ItemStateConfig) {
        icon.image = config.selectedIcon
        title.textColor = config.selectedTitleColor
    }

    public func selectedState(icon: UIImageView, title: UILabel, config: ItemStateConfig) {
        icon.image = config.selectedIcon
        title.textColor = config.selectedTitleColor
    }

    public func deselectState(icon: UIImageView, title: UILabel, config: ItemStateConfig) {
        icon.image = config.defaultIcon
        title.textColor = config.defaultTitleColor
    }
}

final class DefaultItemState: ItemStateProtocol {}

internal final class DefaultTabState: ItemStateProtocol {
    func selectedUserEvent(icon: UIImageView, title: UILabel, config: ItemStateConfig) {
        icon.layer.lu.bounceAnimation(duration: TimeInterval(0.35))
        icon.image = config.selectedIcon
        title.textColor = config.selectedTitleColor
    }
}
