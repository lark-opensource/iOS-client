//
//  SidebarItemType.swift
//  Action
//
//  Created by KT on 2019/4/26.
//

import Foundation

// Chat 侧边栏Item
public enum SidebarItemType: String {
    /// 服务端下发的sidebar统一为remote类型
    case remote
    case announcement
    case pin
    case search
    case setting
    case event
    case freeBusyInChat
    case todo
}
