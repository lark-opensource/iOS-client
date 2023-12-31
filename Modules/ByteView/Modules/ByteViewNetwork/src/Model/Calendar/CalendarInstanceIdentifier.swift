//
//  CalendarInstanceIdentifier.swift
//  ByteViewNetwork
//
//  Created by Tobb Huang on 2022/8/22.
//

import Foundation
import RustPB
import ServerPB

/// Videoconference_V1_CalendarInstanceIdentifier
/// ServerPB_Videochat_common_CalendarInstanceIdentifier
public struct CalendarInstanceIdentifier: Equatable {

    public init(uid: String, originalTime: Int64, instanceStartTime: Int64, instanceEndTime: Int64) {
        self.uid = uid
        self.originalTime = originalTime
        self.instanceStartTime = instanceStartTime
        self.instanceEndTime = instanceEndTime
    }

    public var uid: String

    public var originalTime: Int64

    public var instanceStartTime: Int64

    public var instanceEndTime: Int64
}

extension CalendarInstanceIdentifier {

    init(pb: Videoconference_V1_CalendarInstanceIdentifier) {
        self.uid = pb.uid
        self.originalTime = pb.originalTime
        self.instanceStartTime = pb.instanceStartTime
        self.instanceEndTime = pb.instanceEndTime
    }

    init(serverPB: ServerPB_Videochat_common_CalendarInstanceIdentifier) {
        self.uid = serverPB.uid
        self.originalTime = serverPB.originalTime
        self.instanceStartTime = serverPB.instanceStartTime
        self.instanceEndTime = serverPB.instanceEndTime
    }

    var pbType: Videoconference_V1_CalendarInstanceIdentifier {
        var identifier = Videoconference_V1_CalendarInstanceIdentifier()
        identifier.uid = uid
        identifier.originalTime = originalTime
        identifier.instanceStartTime = instanceStartTime
        identifier.instanceEndTime = instanceEndTime
        return identifier
    }

    var serverPBType: ServerPB_Videochat_common_CalendarInstanceIdentifier {
        var identifier = ServerPB_Videochat_common_CalendarInstanceIdentifier()
        identifier.uid = uid
        identifier.originalTime = originalTime
        identifier.instanceStartTime = instanceStartTime
        identifier.instanceEndTime = instanceEndTime
        return identifier
    }
}
