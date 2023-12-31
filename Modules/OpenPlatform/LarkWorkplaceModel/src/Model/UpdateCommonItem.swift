//
//  UpdateCommonItem.swift
//  LarkWorkplaceModel
//
//  Created by Shengxy on 2022/12/4.
//

import Foundation

/// [lark/workplace/api/UpdateCommonItem] - request parameters
/// request parameters for updating common and recommend apps
/// list of common and recommend apps to be updated
struct WPUpdateFavoriteAppRequestParams: Codable {
    /// item ids of commonly used widgets (new)
    let newCommonWidgetItemList: [String]
    /// item ids of commonly used widgets (old)
    let originCommonWidgetItemList: [String]
    /// item ids of commonly used apps (new)
    let newCommonIconItemList: [String]
    /// item ids of commonly used apps (old)
    let originCommonIconItemList: [String]
    /// item ids of removable recommend app (new)
    let newDistributedRecommendItemList: [String]
    /// item ids of removable recommend app (old)
    let originDistributedRecommendItemList: [String]
}
