//
//  Badge+Monitor.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/5/31.
//

import Foundation
import LarkWorkplaceModel

extension Array: WorkplaceCompatible where Element == WPBadge {
    typealias WorkplaceExtensionType = WorkplaceExtension<Self>
}

// swiftlint:disable:next syntactic_sugar
extension WorkplaceExtension where BaseType == Array<WPBadge> {
    var badgeBrief: String? {
        let encoder = JSONEncoder()
        let briefs = base.map({ TemplateBadgeNodeBrief(from: $0.toOpenAppBadgeNode()) })
        guard let data = try? encoder.encode(briefs) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// 用于埋点信息的结构
struct TemplateBadgeNodeBrief: Codable {
    let badgeId: String
    let appId: String
    let type: String
    let num: Int32
    let show: Bool
    let version: String

    init(from badgeNode: Rust.OpenAppBadgeNode) {
        self.badgeId = badgeNode.id
        self.appId = badgeNode.appID
        self.num = badgeNode.badgeNum
        self.show = badgeNode.needShow
        self.version = badgeNode.version
        switch badgeNode.feature {
        case .h5:
            self.type = "H5"
        case .miniApp:
            self.type = "MiniApp"
        @unknown default:
            self.type = "unknown"
        }
    }
}
