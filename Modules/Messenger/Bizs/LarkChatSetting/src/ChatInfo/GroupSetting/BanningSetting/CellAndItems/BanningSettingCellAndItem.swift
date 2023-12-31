//
//  File.swift
//  LarkChat
//
//  Created by kkk on 2019/3/11.
//

import Foundation

enum BanningSttingSectionType {
    case option
    case chatters
    case tips
}

struct BanningSettingSection {
    var type: BanningSttingSectionType
    var items: [BanningSettingItem]

    init(type: BanningSttingSectionType, items: [BanningSettingItem] = []) {
        self.type = type
        self.items = items
    }
}

protocol BanningSettingItem {
    var identifier: String { get }
}

protocol BanningSettingCell {
    var item: BanningSettingItem? { get }
    func set(item: BanningSettingItem)
}
