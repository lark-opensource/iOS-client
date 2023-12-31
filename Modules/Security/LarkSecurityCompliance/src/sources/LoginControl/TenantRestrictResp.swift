//
//  TenantRestrictResp.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/2/2.
//

import Foundation

struct TenantRestrictResp: Decodable {
    let shouldKickOff: Bool?
    let tenantId: String?

    enum CodingKeys: String, CodingKey {
        case shouldKickOff = "should_kick_off"
        case tenantId = "tenant_id"
    }
}
