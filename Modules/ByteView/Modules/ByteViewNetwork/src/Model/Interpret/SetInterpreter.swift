//
//  SetInterpreter.swift
//  ByteViewNetwork
//
//  Created by wulv on 2022/7/19.
//

import Foundation
import RustPB

/// Videoconference_V1_SetInterpreter
public struct SetInterpreter: Equatable, Codable {
    public var user: ByteviewUser

    public var interpreterSetting: InterpreterSetting?

    ///是否删除传译员
    public var isDeleteInterpreter: Bool

    public init(user: ByteviewUser, interpreterSetting: InterpreterSetting?, isDeleteInterpreter: Bool) {
        self.user = user
        self.interpreterSetting = interpreterSetting
        self.isDeleteInterpreter = isDeleteInterpreter
    }
}

extension SetInterpreter {
    var pbType: PBSetInterpreter {
        var setting = PBSetInterpreter()
        setting.user = user.pbType
        setting.isDeleteInterpreter = isDeleteInterpreter
        if !isDeleteInterpreter, let interpreterSetting = interpreterSetting {
            var obj = PBInterpreterSetting()
            obj.firstLanguage = interpreterSetting.firstLanguage.pbType
            obj.secondLanguage = interpreterSetting.secondLanguage.pbType
            obj.interpreterSetTime = interpreterSetting.interpreterSetTime
            setting.interpreterSetting = obj
        }
        return setting
    }

    var pbHostManageType: PBHostManageSetInterpreter {
        var setting = PBHostManageSetInterpreter()
        setting.user = user.pbType
        setting.isDeleteInterpreter = isDeleteInterpreter
        if !isDeleteInterpreter, let interpreterSetting = interpreterSetting {
            var obj = PBInterpreterSetting()
            obj.firstLanguage = interpreterSetting.firstLanguage.pbType
            obj.secondLanguage = interpreterSetting.secondLanguage.pbType
            obj.interpreterSetTime = interpreterSetting.interpreterSetTime
            setting.interpreterSetting = obj
        }
        return setting
    }

    var serverPbType: ServerPBSetInterpreter {
        var setting = ServerPBSetInterpreter()
        setting.user = user.serverPbType
        setting.isDeleteInterpreter = isDeleteInterpreter
        if !isDeleteInterpreter, let interpreterSetting = interpreterSetting {
            var obj = ServerPBInterpreterSetting()
            obj.firstLanguage = interpreterSetting.firstLanguage.serverPbType
            obj.secondLanguage = interpreterSetting.secondLanguage.serverPbType
            obj.interpreterSetTime = interpreterSetting.interpreterSetTime
            setting.interpreterSetting = obj
        }
        return setting
    }
}

extension SetInterpreter: CustomStringConvertible {
    public var description: String {
        String(
            indent: "SetInterpreter",
            "user: \(user)",
            "interpreterSetting: \(interpreterSetting)",
            "isDeleteInterpreter: \(isDeleteInterpreter)"
        )
    }
}
