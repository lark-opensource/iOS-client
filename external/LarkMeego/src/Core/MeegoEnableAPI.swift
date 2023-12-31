//
//  MeegoEnableAPI.swift
//  LarkMeego
//
//  Created by shizhengyu on 2023/9/26.
//

import Foundation
import LarkMeegoNetClient

struct MeegoEnableResponseData: Codable {
    // web 使用的可用状态（目前用不上）
    let visible: Bool
    // 租户是否签约 meego
    let tenantVisible: Bool

    private enum CodingKeys: String, CodingKey {
        case visible = "visible"
        case tenantVisible = "tenant_visible"
    }
}

struct MeegoEnableRequest: Request {
    typealias ResponseType = Response<MeegoEnableResponseData>

    private let larkUserId: String
    private let tenantId: String

    init(larkUserId: String, tenantId: String) {
        self.larkUserId = larkUserId
        self.tenantId = tenantId
    }

    var endpoint: String {
        return "/goapi/v1/user/visible"
    }

    var method: RequestMethod {
        return .post
    }

    var parameters: [String: Any] {
        return [
            "lark_user_id": larkUserId,
            "tenant_id": tenantId
        ]
    }
}
