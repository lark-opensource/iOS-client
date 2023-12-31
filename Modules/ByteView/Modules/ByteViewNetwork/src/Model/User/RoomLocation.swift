//
//  RoomLocation.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/9.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

public struct RoomLocation: Equatable {
    public init(floorName: String, buildingName: String) {
        self.floorName = floorName
        self.buildingName = buildingName
    }

    /// 会议室楼层
    public var floorName: String

    /// 会议室所处建筑名（city-building）
    public var buildingName: String
}
