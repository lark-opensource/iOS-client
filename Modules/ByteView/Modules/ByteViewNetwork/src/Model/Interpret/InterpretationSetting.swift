//
//  InterpretationSetting.swift
//  ByteViewNetwork
//
//  Created by wulv on 2022/7/19.
//

import Foundation
import RustPB

/// Videoconference_V1_InterpretationSetting
public struct InterpretationSetting: Equatable, Codable {
    /// 是否开启同传能力，客户端必传此值
    public var isOpenInterpretation: Bool

    /// 传译员配置
    public var interpreterSettings: [SetInterpreter] = []

    public init(isOpenInterpretation: Bool, interpreterSettings: [SetInterpreter]) {
        self.isOpenInterpretation = isOpenInterpretation
        self.interpreterSettings = interpreterSettings
    }
}

extension InterpretationSetting {
    var pbType: PBInterpretationSetting {
        var setting = PBInterpretationSetting()
        setting.isOpenInterpretation = isOpenInterpretation
        setting.interpreterSettings = interpreterSettings.map { $0.pbType }
        return setting
    }

    var pbHostManageType: PBHostManageInterpretationSetting {
        var setting = PBHostManageInterpretationSetting()
        setting.isOpenInterpretation = isOpenInterpretation
        setting.interpreterSettings = interpreterSettings.map { $0.pbHostManageType }
        return setting
    }

    var serverPbType: ServerPBInterpretationSetting {
        var setting = ServerPBInterpretationSetting()
        setting.isOpenInterpretation = isOpenInterpretation
        setting.interpreterSettings = interpreterSettings.map { $0.serverPbType }
        return setting
    }
}

extension InterpretationSetting: CustomStringConvertible {
    public var description: String {
        String(
            indent: "InterpretationSetting",
            "isOpenInterpretation: \(isOpenInterpretation)",
            "interpreterSettings: \(interpreterSettings)"
        )
    }
}
