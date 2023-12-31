//
//  UserDataEraserDefines.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/7/4.
//

import Foundation

struct EraseUserScope: Codable {
    //用户ID
    let userID: String
    //租户ID
    let tenantID: String
}
