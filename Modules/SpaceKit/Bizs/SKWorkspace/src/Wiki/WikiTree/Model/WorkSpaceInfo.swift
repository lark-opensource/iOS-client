//
//  WorkSpaceInfo.swift
//  SKWorkspace
//
//  Created by majie.7 on 2023/5/17.
//

import Foundation

public struct WorkSpaceInfo {
    public var spaces: [WikiSpace]
    public var lastLabel: String
    public var hasMore: Bool
    
    public init(spaces: [WikiSpace], lastLabel: String, hasMore: Bool) {
        self.spaces = spaces
        self.lastLabel = lastLabel
        self.hasMore = hasMore
    }
}
