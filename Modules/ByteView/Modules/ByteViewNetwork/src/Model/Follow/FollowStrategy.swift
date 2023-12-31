//
//  FollowStrategy.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/17.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_FollowStrategy
public struct FollowStrategy: Equatable {
    public init(id: String, resourceVersions: [String: String], settings: String, keepOrder: Bool, iosResourceIds: [String]) {
        self.id = id
        self.resourceVersions = resourceVersions
        self.settings = settings
        self.keepOrder = keepOrder
        self.iosResourceIds = iosResourceIds
    }

    /// strategy的名字，唯一标识这个strategy
    public var id: String

    /// 资源id的版本，服务端锁定版本后用于告知客户端所用资源的版本
    public var resourceVersions: [String: String]

    /// JSON String,会塞给此strategy的js entry使用
    public var settings: String

    /// 是否需要保序，不需要时可以发 Trigger
    public var keepOrder: Bool

    /// ios资源id的版本，服务端锁定版本后用于告知客户端所用资源的版本
    public var iosResourceIds: [String]
}

extension FollowStrategy: CustomStringConvertible {
    public var description: String {
        String(
            indent: "FollowStrategy",
            "id: \(id)",
            "keepOrder: \(keepOrder)",
            "resourceVersions: \(resourceVersions)",
            "iosResourceIds: \(iosResourceIds)"
        )
    }
}
