//
//  AddCommonItem.swift
//  LarkWorkplaceModel
//
//  Created by Shengxy on 2022/12/4.
//

import Foundation

/// [lark/workplace/api/AddCommonItem] - request paramters
/// request parameters for adding commonly used app
struct WPAddCommonAppRequestParams: Codable {
    /// list of item identifier
    let itemIds: [String]?
    /// list of application identifier
    let appIds: [String]?
}
