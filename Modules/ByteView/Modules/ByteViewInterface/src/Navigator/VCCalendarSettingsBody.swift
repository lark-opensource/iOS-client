//
//  VCCalendarSettingsBody.swift
//  ByteViewInterface
//
//  Created by kiri on 2023/6/30.
//

import Foundation

/// /client/videochat/calendarsettings
public struct VCCalendarSettingsBody: CodablePathBody {
    public static let path = "/client/videochat/calendarsettings"

    public let uniqueID: String
    public let uid: String
    public let originalTime: Int64
    public let instanceStartTime: Int64
    public let instanceEndTime: Int64

    public init(uniqueID: String, uid: String, originalTime: Int64, instanceStartTime: Int64, instanceEndTime: Int64) {
        self.uniqueID = uniqueID
        self.uid = uid
        self.originalTime = originalTime
        self.instanceStartTime = instanceStartTime
        self.instanceEndTime = instanceEndTime
    }
}
