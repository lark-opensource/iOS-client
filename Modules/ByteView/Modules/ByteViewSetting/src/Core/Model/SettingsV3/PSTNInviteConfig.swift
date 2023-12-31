//
//  PSTNInviteConfig.swift
//  ByteView
//
//  Created by bytedance on 2022/5/31.
//

import Foundation

public struct PSTNInviteConfig: Decodable, CustomStringConvertible {

    /// 电话服务官网链接
    public let url: String

    static let `default` = PSTNInviteConfig(url: "https://www.feishu.cn/hc/zh-CN/articles/479225592814")

    enum CodingKeys: String, CodingKey {
        case url = "phoneCallOnboardingLink" // "phone_call_onboarding_link"
    }

    public var description: String {
        "PSTNInviteConfig(url: \(url.hash))"
    }
}
