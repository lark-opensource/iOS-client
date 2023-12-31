//
//  LabPlatformApplinkConfig.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/10.
//

import Foundation

public struct LabPlatformApplinkConfig: Decodable, CustomStringConvertible {
    public let feishuHost: String
    public let larkHost: String

    static let `default` = LabPlatformApplinkConfig(feishuHost: "https://effect-bd.feishu.cn",
                                                    larkHost: "https://effect-bd.larksuite.com")

    public var description: String {
        "LabPlatformApplinkConfig(feishuHost: \(feishuHost.hash), larkHost: \(larkHost.hash))"
    }
}
