//
//  LarkLiveID.swift
//  ByteView
//
//  Created by tuwenbo on 2021/1/29.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

struct LarkLiveID: Codable {
    let liveID: String?

    enum CodingKeys: String, CodingKey {
        case liveID = "live_id"
    }
}
