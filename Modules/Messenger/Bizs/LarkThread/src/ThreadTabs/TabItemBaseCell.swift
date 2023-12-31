//
//  TabItemBaseCell.swift
//  TabItemBaseCell
//
//  Created by 袁平 on 2021/9/13.
//

import Foundation
import UniverseDesignTabs

enum TabItemType: String {
    case all = "AllTabItem" // 全部
    case follow = "FollowTabItem" // 我订阅的
}

protocol TabItemBaseModel {
    var itemType: TabItemType { get }
    var cellType: TabItemBaseCell.Type { get }
    var title: String { get }
}

class TabItemBaseCell: UDTabsTitleCell {
    func config(model: TabItemBaseModel) {
    }
}
