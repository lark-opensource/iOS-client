//
//  AtSettingItemModel.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/10/12.
//

import Foundation

final class AtSettingItemModel {
    var selected: Bool
    let title: String
    let isEnabled: Bool

    init(title: String, isEnabled: Bool, selected: Bool) {
        self.title = title
        self.isEnabled = isEnabled
        self.selected = selected
    }
}
