//
//  GetTagsAndRecentItems.swift
//  LarkWorkplaceModel
//
//  Created by Shengxy on 2022/12/2.
//

import Foundation

/// ['lark/workplace/api/GetTagsAndRecentItems'] - request parameters
/// request parameters for getting the list of recently used app
struct WPGetTagsAndRecentItemsRequestParams: Codable {
    /// locale for response data
    let locale: String
    /// this field is always true
    let needWidget: Bool
    /// need block or not
    let needBlock: Bool
}

// ['lark/workplace/api/GetTagsAndRecentItems'] - response data
// same as `WPSearchCategoryApp`
