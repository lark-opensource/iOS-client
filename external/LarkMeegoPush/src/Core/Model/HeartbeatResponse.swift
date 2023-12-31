//
//  HeartbeatResponse.swift
//  LarkMeegoPush
//
//  Created by ByteDance on 2022/7/13.
//

import Foundation
import LarkMeegoNetClient

public struct HeartbeatResponse: Codable {
    public let deviceIdentification: String

    private enum CodingKeys: String, CodingKey {
        case deviceIdentification = "device_identification"
    }
}
