//
//  EnterpriseLimitLinkConfig.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/10.
//

import Foundation

public struct EnterpriseLimitLinkConfig: Decodable, CustomStringConvertible {
    public let controlLink: String

    static let `default` = EnterpriseLimitLinkConfig(controlLink: "")

    public var description: String {
        "EnterpriseLimitLinkConfig(controlLink: \(controlLink.hash))"
    }
}
