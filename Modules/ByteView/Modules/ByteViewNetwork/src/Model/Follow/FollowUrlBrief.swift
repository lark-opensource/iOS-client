//
//  FollowUrlBrief.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/9.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_UrlBrief
public struct FollowUrlBrief: Equatable {
    public init(url: String, title: String, type: FollowShareType, subtype: FollowShareSubType,
                isDirty: Bool, openInBrowser: Bool, docTenantWatermarkOpen: Bool, docTenantID: String) {
        self.url = url
        self.title = title
        self.type = type
        self.subtype = subtype
        self.isDirty = isDirty
        self.openInBrowser = openInBrowser
        self.docTenantWatermarkOpen = docTenantWatermarkOpen
        self.docTenantID = docTenantID
    }

    public var url: String

    public var title: String

    public var type: FollowShareType

    public var subtype: FollowShareSubType

    public var isDirty: Bool

    public var openInBrowser: Bool

    public var docTenantWatermarkOpen: Bool

    public var docTenantID: String
}

extension FollowUrlBrief: CustomStringConvertible {
    public var description: String {
        String(
            indent: "FollowUrlBrief",
            "url: \(url.hash)",
            "type: \(type)",
            "subtype: \(subtype)",
            "isDirty: \(isDirty)",
            "openInBrowser: \(openInBrowser)",
            "docTenantWatermarkOpen: \(docTenantWatermarkOpen)",
            "docTenantID: \(docTenantID)"
        )
    }
}
