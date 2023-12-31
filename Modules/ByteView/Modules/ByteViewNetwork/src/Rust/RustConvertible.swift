//
//  RustConvertible.swift
//  ByteViewNetwork
//
//  提供基本类型转换，本文件内的转换为public方法
//
//  Created by kiri on 2022/12/16.
//

import Foundation
import RustPB
import ServerPB

//public extension ParticipantType {
//    init(pb: Videoconference_V1_ParticipantType) {
//        self.init(rawValue: pb.rawValue)
//    }
//
//    init(pb: ServerPB_Videochat_common_ParticipantType) {
//        self.init(rawValue: pb.rawValue)
//    }
//
//    func toRustPB() -> Videoconference_V1_ParticipantType {
//        .init(rawValue: rawValue) ?? .unknow
//    }
//
//    func toServerPB() -> ServerPB_Videochat_common_ParticipantType {
//        .init(rawValue: rawValue) ?? .unknow
//    }
//}
//
//public extension ByteviewUser {
//    init(pb: Videoconference_V1_ByteviewUser) {
//        self.id = pb.userID
//        self.type = .init(pb: pb.userType)
//        self.deviceId = pb.deviceID
//    }
//
//    init(pb: ServerPB_Videochat_common_ByteviewUser) {
//        self.id = pb.userID
//        self.type = .init(pb: pb.userType)
//        self.deviceId = pb.deviceID
//    }
//
//    func toRustPB() -> Videoconference_V1_ByteviewUser {
//        var obj = Videoconference_V1_ByteviewUser()
//        obj.userID = self.id
//        obj.userType = self.type.toRustPB()
//        obj.deviceID = self.deviceId
//        return obj
//    }
//
//    func toServerPB() -> ServerPB_Videochat_common_ByteviewUser {
//        var obj = ServerPB_Videochat_common_ByteviewUser()
//        obj.userID = self.id
//        obj.userType = self.type.toServerPB()
//        obj.deviceID = self.deviceId
//        return obj
//    }
//}
