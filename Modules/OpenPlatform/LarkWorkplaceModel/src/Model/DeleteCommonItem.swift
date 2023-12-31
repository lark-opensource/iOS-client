//
//  DeleteCommonItem.swift
//  LarkWorkplaceModel
//
//  Created by Shengxy on 2022/12/4.
//

import Foundation

/// [lark/workplace/api/DeleteCommonItem] - request parameters
/// request parameters for deleting comonly used app
struct WPDeleteCommonAppRequestParams: Codable {
    /// list of item identifier
    let itemId: String?
    /// list of application identifier
    let appId: String?
}
