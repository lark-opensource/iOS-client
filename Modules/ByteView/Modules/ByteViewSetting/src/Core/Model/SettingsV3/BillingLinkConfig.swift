//
//  BillingLinkConfig.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/10.
//

import Foundation

public struct BillingLinkConfig: Decodable, CustomStringConvertible {
    public let upgradeLink: String

    static let `default` = BillingLinkConfig(upgradeLink: "")

    public var description: String {
        "BillingLinkConfig(upgradeLink: \(upgradeLink.hash))"
    }
}
