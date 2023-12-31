//
//  WorkplacePreviewModel.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/10/12.
//

import Foundation

struct WorkplacePreviewResponse: Codable {
    enum Code: Int {
        /// 成功
        case success = 0
        /// 无权限
        case permission = 11401
        /// 已删除
        case deleted = 11402
        /// 过期
        case expired = 11425
    }

    let msg: String
    let code: Int
    let data: WPPortalTemplate?
}
