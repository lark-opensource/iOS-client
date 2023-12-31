//
//  Whiteboard+Server.swift
//  ByteViewNetwork
//
//  Created by Prontera on 2022/3/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

typealias ServerPBWhiteboardSnapshot = ServerPB_Videochat_whiteboard_WhiteboardSnapshot
typealias ServerPBWhiteboardPage = ServerPB_Videochat_whiteboard_WhiteboardPage

extension ServerPBWhiteboardSnapshot {
    var vcType: WhiteboardSnapshot {
        .init(whiteboardID: whiteboardID,
              page: page.vcType,
              latestDownVersion: latestDownVersion,
              snapshotData: snapshotData)
    }
}

extension ServerPBWhiteboardPage {
    var vcType: WhiteboardPage {
        .init(pageID: pageID, pageNum: pageNum, isSharing: isSharing)
    }
}
