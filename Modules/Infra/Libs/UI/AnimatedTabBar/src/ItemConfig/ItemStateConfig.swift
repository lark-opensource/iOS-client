//
//  ItemStateConfig.swift
//  AnimatedTabBar
//
//  Created by Meng on 2019/11/4.
//

import UIKit
import Foundation
import UniverseDesignColor
import UniverseDesignTheme

public struct ItemStateConfig {
    public var defaultIcon: UIImage?
    public var selectedIcon: UIImage?
    public var quickBarIcon: UIImage?
    public var defaultTitleColor: UIColor
    public var selectedTitleColor: UIColor
    public var quickTitleColor: UIColor

    public init(defaultIcon: UIImage?,
                selectedIcon: UIImage?,
                quickBarIcon: UIImage?,
                defaultTitleColor: UIColor = UIColor.ud.staticBlack70 & UIColor.ud.staticWhite80,
                selectedTitleColor: UIColor = UIColor.ud.primaryContentDefault,
                quickTitleColor: UIColor = UIColor.ud.textTitle) {
        self.defaultIcon = defaultIcon
        self.selectedIcon = selectedIcon
        self.quickBarIcon = quickBarIcon
        self.defaultTitleColor = defaultTitleColor
        self.selectedTitleColor = selectedTitleColor
        self.quickTitleColor = quickTitleColor
    }
}
