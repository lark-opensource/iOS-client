//
//  ShareContentBody.swift
//  ByteViewInterface
//
//  Created by kiri on 2023/6/29.
//

import Foundation

/// 发起共享内容, /client/byteview/sharecontent
public struct ShareContentBody: CodablePathBody {
    public static let path: String = "/client/byteview/sharecontent"

    public let source: ShareContentEntry

    public init(source: ShareContentEntry) {
        self.source = source
    }
}

public enum ShareContentEntry: String, Equatable, Codable {
    case groupPlus = "group_plus" // 群下方加号
    case independTab = "independ_tab" // 独立tab
}

extension ShareContentBody: CustomStringConvertible {
    public var description: String {
        "ShareContentBody(source: \(source.rawValue))"
    }
}
