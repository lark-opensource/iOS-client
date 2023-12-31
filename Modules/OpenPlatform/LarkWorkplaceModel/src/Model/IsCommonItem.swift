//
//  IsCommonItem.swift
//  LarkWorkplaceModel
//
//  Created by Shengxy on 2022/10/28.
//

import Foundation

/// [ 'lark/workplace/api/IsCommonItem'] -  request parameters
/// request parameters for querying whether one app is common or recommend
struct WPQueryAppTypeRequestParams: Codable {
    /// application id
    let appId: String
}

/// [ 'lark/workplace/api/IsCommonItem']
/// check whether current app is common and recommend
struct WPQueryAppType: Codable {
    /// commonly used app (user-picked)
    let isUserCommon: Bool?
    /// removable recommend app (admin-picked)
    let isUserDistributedRecommend: Bool?
    /// non-removable recommend app (admin-picked)
    let isUserRecommend: Bool?
}
