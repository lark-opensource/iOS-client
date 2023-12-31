//
//  RustPBAlias.swift
//  ByteView
//
//  Created by liuning.cn on 2019/10/12.
//

import Foundation
import RustPB
import ByteViewNetwork

typealias SketchDataUnit = Videoconference_V1_SketchDataUnit
typealias SketchOperationUnit = Videoconference_V1_SketchOperationUnit
typealias SketchRemoveData = Videoconference_V1_SketchOperationUnit.SketchRemoveData
typealias ByteMetadata = Videoconference_V1_ByteMetadata
typealias SketchData = Videoconference_V1_SketchData
typealias SketchTransferMode = Videoconference_V1_InMeetingData.ScreenSharedData.SketchTransferMode
typealias CustomStatus = Basic_V1_Chatter.ChatterCustomStatus

extension Videoconference_V1_ByteviewUser {
    var identifier: String {
        "\(userID)_\(userType.rawValue)_\(deviceID)"
    }

    var vcType: ByteviewUser {
        .init(id: userID, type: ParticipantType(rawValue: userType.rawValue), deviceId: deviceID)
    }
}
