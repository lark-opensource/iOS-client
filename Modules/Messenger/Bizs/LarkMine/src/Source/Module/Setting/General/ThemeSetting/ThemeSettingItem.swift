//
//  ThemeSettingItem.swift
//  LarkMine
//
//  Created by bytedance on 2021/4/22.
//

import UIKit
import Foundation

struct ThemeSettingItem {
    var name: String
    var image: UIImage
    var isSelected: Bool
    var isEnabled: Bool
    var onSelect: (() -> Void)?
}
