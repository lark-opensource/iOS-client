//
//  VCJoinedDeviceInfoChange.swift
//  ByteViewNetwork
//
//  Created by tuwenbo on 2023/12/1.
//

import Foundation
import RustPB

public struct VCJoinedDeviceInfoChangeData {
    public var infos: [RustPB.Videoconference_V1_JoinedDeviceInfo]
}

extension VCJoinedDeviceInfoChangeData: _NetworkDecodable, NetworkDecodable {

    typealias ProtobufType = RustPB.Videoconference_V1_GetJoinedDevicesInfoResponse

    init(pb: ProtobufType) {
        self.infos = pb.devices
    }
}
