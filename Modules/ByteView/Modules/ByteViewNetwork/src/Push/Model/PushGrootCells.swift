//
//  PushGrootCells.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/12/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 推送的数据
/// - PUSH_GROOT_CELLS = 89002
/// - Videoconference_V1_PushGrootCells
public struct PushGrootCells {

    var channel: GrootChannel

    var cells: [GrootCell]
}

extension PushGrootCells: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Videoconference_V1_PushGrootCells
    init(pb: Videoconference_V1_PushGrootCells) throws {
        self.channel = try GrootChannel(pb: pb.channelMeta)
        self.cells = pb.cells.map({ $0.vcType })
    }
}

extension PushGrootCells: CustomStringConvertible {
    public var description: String {
        String(indent: "PushGrootCells",
               "channel: \(channel)",
               "cells: \(cells.count > 10 ? "count=\(cells.count)" : "\(cells)")")
    }
}
