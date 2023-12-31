//
//  Whiteboard+Rust.swift
//  ByteViewNetwork
//
//  Created by Prontera on 2022/3/20.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

typealias RustPBWhiteboardInfo = Videoconference_V1_WhiteboardInfo
typealias RustPBWhiteboardSettings = Videoconference_V1_WhiteboardSettings
typealias RustPBWhiteboardSettingsShareMode = Videoconference_V1_WhiteboardSettings.ShareMode
typealias RustPBWhiteboardPage = Videoconference_V1_WhiteboardPage
typealias RustPBWhiteboardSnapshot = Videoconference_V1_WhiteboardSnapshot

extension RustPBWhiteboardInfo {
    var vcType: WhiteboardInfo {
        .init(whiteboardID: whiteboardID,
              sharer: sharer.vcType,
              whiteboardSettings: whiteboardSettings.vcType,
              pages: pages.map { $0.vcType },
              whiteboardIsSharing: whiteboardIsSharing,
              version: version,
              extraInfo: extraInfo.vcType)
    }
}

extension RustPBWhiteboardInfo.ExtraInfo {
    var vcType: WhiteboardInfo.ExtraInfo {
        .init(sharerWatermarkOpen: sharerWatermarkOpen)
    }
}

extension RustPBWhiteboardSettings {
    var vcType: WhiteboardSettings {
        .init(shareMode: shareMode.vcType,
              canvasSize: CGSize(width: Int(canvasSize.width), height: Int(canvasSize.height)))
    }
}

extension RustPBWhiteboardSettingsShareMode {
    var vcType: WhiteboardSettings.ShareMode {
        switch self {
        case .presentationMode:
            return .presentation
        case .collaborationMode:
            return .collaboration
        @unknown default:
            return .collaboration
        }
    }
}

extension RustPBWhiteboardPage {
    var vcType: WhiteboardPage {
        .init(pageID: pageID, pageNum: pageNum, isSharing: isSharing)
    }
}

extension RustPBWhiteboardSnapshot {
    var vcType: WhiteboardSnapshot {
        .init(whiteboardID: whiteboardID,
              page: page.vcType,
              latestDownVersion: latestDownVersion,
              snapshotData: snapshotData)
    }
}
