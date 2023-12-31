//
//  SettingDefines.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/3/27.
//

import Foundation
import ByteViewCommon

extension Logger {
    static let setting = Logger.getLogger("Setting")
}

public enum JoinAudioOutputSettingType: Int, Equatable {
    case last = 0
    case receiver
    case speaker

    var text: String {
        switch self {
        case.last:
            return I18n.View_G_RememberLastOne_Options
        case .receiver:
            return I18n.View_G_EarSpeakerDefault_Options
        case .speaker:
            return I18n.View_G_SpeakerDefault_Options
        }
    }
}
