//
//  GetUserItems.swift
//  LarkWorkplaceModel
//
//  Created by shengxy on 2022/10/27.
//

import Foundation

/// ['lark/workplace/api/GetUserItems'] - request parameters
/// request parameters for getting rank page model
struct WPGetRankPageModelRequestParams: Codable {
    /// lark version number, eg: "5.27.0"
    let larkVersion: String
    /// locale for response data
    let locale: String
    /// this field is always true
    let needWidget: Bool
    /// need block or not
    let needBlock: Bool
}

/// ['lark/workplace/api/GetUserItems'] -  response data
/// rank page model
struct WPRankPageModel: Codable {
    /// itemId list - non-removable recommend application (admin-picked)
    let recommendItemList: [String]?
    /// itemId list - removable recommend application (admin-picked)
    let distributedRecommendItemList: [String]?
    /// itemId list - commonly used widget application (user-picked)
    let commonWidgetItemList: [String]?
    /// itemId list - commonly used application, shown in icon way (user-picked)
    let commonIconItemList: [String]?
    /// application pool
    /// key: itemId
    /// value: application properties
    let allItemInfos: [String: WPAppItem]?
}
