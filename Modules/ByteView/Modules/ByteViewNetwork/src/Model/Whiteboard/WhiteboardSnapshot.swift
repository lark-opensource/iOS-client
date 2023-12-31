//
//  WhiteboardSnapshot.swift
//  ByteViewNetwork
//
//  Created by Prontera on 2022/3/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation

public struct WhiteboardSnapshot: Equatable {

    public let whiteboardID: Int64

    public let page: WhiteboardPage

    /// 该 snapshot 数据已更新至该 down_version （即使该页的snapshot没有更新，down_version也会保持更新）
    public let latestDownVersion: Int64

    public var snapshotData: Data
}
