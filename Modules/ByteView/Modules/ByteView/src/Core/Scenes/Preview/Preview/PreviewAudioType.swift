//
//  PreviewAudioType.swift
//  ByteView
//
//  Created by lutingting on 2023/5/26.
//

import Foundation
import ByteViewNetwork

enum PreviewAudioType: Int {
    case system
    case room
    case noConnect
    case pstn

    var audioMode: ParticipantSettings.AudioMode {
        switch self {
        case .system:
            return .internet
        case .room:
            return .internet
        case .noConnect:
            return .noConnect
        case .pstn:
            return .pstn
        }
    }

    var toDeviceStyle: PreviewDeviceView.Style {
        switch self {
        case .system:
            return .system
        case .room:
            return .room
        case .noConnect:
            return .noConnect
        case .pstn:
            return .callMe
        }
    }
}


extension ParticipantSettings.AudioMode {
    var audioType: PreviewAudioType {
        switch self {
        case .pstn:
            return .pstn
        case .noConnect:
            return .noConnect
        default:
            return .system
        }
    }
}
