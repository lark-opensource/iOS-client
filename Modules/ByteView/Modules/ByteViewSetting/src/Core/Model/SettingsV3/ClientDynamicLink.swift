//
//  ClientDynamicLink.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/10.
//

import Foundation

public struct ClientDynamicLink: Decodable, CustomStringConvertible {
    public var livePolicyUrl: String
    public var recordPolicyUrl: String

    enum CodingKeys: String, CodingKey {
        case livePolicyUrl = "live-policy-url"
        case recordPolicyUrl = "record-policy-url"
    }

    static let `default` = ClientDynamicLink(livePolicyUrl: "", recordPolicyUrl: "")

    public var description: String {
        "ClientDynamicLink(livePolicyUrl: \(livePolicyUrl.hash), recordPolicyUrl: \(recordPolicyUrl.hash))"
    }
}
