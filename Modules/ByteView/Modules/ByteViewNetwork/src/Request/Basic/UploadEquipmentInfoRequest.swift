//
//  UploadEquipmentInfoRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// UPLOAD_EQUIPMENT_INFO
/// ServerPB_Vcinfo_UploadEquipmentInfoRequest
public struct UploadEquipmentInfoRequest {
    public static let command: NetworkCommand = .server(.uploadEquipmentInfo)

    public init(user: ByteviewUser, meetingID: String, microphoneName: String, speakerName: String, cameraName: String) {
        self.user = user
        self.meetingID = meetingID
        self.microphoneName = microphoneName
        self.speakerName = speakerName
        self.cameraName = cameraName
    }

    public var user: ByteviewUser

    public var meetingID: String

    public var microphoneName: String

    public var speakerName: String

    public var cameraName: String
}

extension UploadEquipmentInfoRequest: RustRequest {
    typealias ProtobufType = ServerPB_Vcinfo_UploadEquipmentInfoRequest

    func toProtobuf() throws -> ServerPB_Vcinfo_UploadEquipmentInfoRequest {
        var request = ProtobufType()
        request.user = user.serverPbType
        request.meetingID = meetingID
        request.microphoneName = microphoneName
        request.speakerName = speakerName
        request.cameraName = cameraName
        return request
    }
}
