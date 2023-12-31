//
//  FollowTabItemCell.swift
//  FollowTabItemCell
//
//  Created by 袁平 on 2021/9/13.
//

import UniverseDesignTabs

/// 已订阅
struct FollowTabItemModel: TabItemBaseModel {
    var itemType: TabItemType
    var cellType: TabItemBaseCell.Type
    var title: String
}

final class FollowTabItemCell: TabItemBaseCell {
}
