//
//  ApplyMinutesCollectionPermRequest.swift
//  ByteViewNetwork
//
//  Created by 陈乐辉 on 2023/5/6.
//

import Foundation
import ServerPB

/// 申请妙记合集权限
/// APPLY_MINUTES_COLLECTION_PERMISSION = 93001
/// ServerPB_Meeting_object_ApplyMinutesCollectionPermRequest
public struct ApplyMinutesCollectionPermRequest {
    public static let command: NetworkCommand = .server(.applyMinutesCollectionPermission)

    public var meetingID: Int64

    public init(meetingID: Int64) {
        self.meetingID = meetingID
    }
}


extension ApplyMinutesCollectionPermRequest: RustRequest {
    typealias ProtobufType = ServerPB_Meeting_object_ApplyMinutesCollectionPermRequest

    func toProtobuf() throws -> ServerPB_Meeting_object_ApplyMinutesCollectionPermRequest {
        var request = ProtobufType()
        request.meetingID = meetingID
        return request
    }
}
