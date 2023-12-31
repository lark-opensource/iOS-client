//
//  ByteViewSettingsBody.swift
//  ByteViewInterface
//
//  Created by kiri on 2023/6/29.
//

import Foundation

/// “通话与会议”页面, /client/byteview/settings
public struct ByteViewSettingsBody: CodablePathBody {
    public static let path: String = "/client/byteview/settings"

    public let source: String?
    public init(source: String?) {
        self.source = source
    }
}
