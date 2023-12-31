//
//  Domains.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

public enum Domains {
    /// 业务型 Domains
    public enum Business: String, CaseIterable, DomainConvertible {
        case messenger = "Messenger"
        case ccm = "CCM"
        case bitable = "Bitable"
        case mail = "MailSDK"
        case calendar = "Calendar"
        case byteView = "ByteView"
        case minutes = "Minutes"
        case microApp = "MicroApp"
        case webApp = "WebApp"
        case openPlatform = "OpenPlatform"
        case workplace = "Workplace"
        case block = "Block"
        case todo = "Todo"
        case meego = "Meego"
        case ka = "Ka"
        case passport = "Passport"
        case ai = "AI"
        case core = "Core"

        case rust = "Rust"

        case feed = "Feed"
        case setting = "Setting"
        case snc = "SecurityCompliance"

        case infra = "Infra"

        public var isolationId: String {
            rawValue
        }

        public func asDomain() -> Domain {
            Domain(rawValue)
        }
    }

    /// 功能型 Domains
    public enum Function: String, CaseIterable, DomainConvertible {
        case network = "Network"

        public var isolationId: String {
            rawValue
        }

        public func asDomain() -> Domain {
            Domain(rawValue)
        }
    }
}

extension Domain {
    public static let biz = Domains.Business.self
    public static let fun = Domains.Function.self
}
