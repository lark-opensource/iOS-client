//
//  SendGrootCellsRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 批量发起请求
/// - SEND_GROOT_CELLS
/// - Videoconference_V1_SendGrootCellsRequest
struct SendGrootCellsRequest {
    static let command: NetworkCommand = .rust(.sendGrootCells)

    init(channel: GrootChannel, cells: [GrootCell]) {
        self.channel = channel
        self.cells = cells
    }

    var channel: GrootChannel
    var cells: [GrootCell]
}

extension SendGrootCellsRequest: CustomStringConvertible {
    var description: String {
        String(indent: "SendGrootCellsRequest", "channel: \(channel)", "cells.count: \(cells.count)", "upversion: \(cells.first?.upVersion)")
    }
}

extension SendGrootCellsRequest: RustRequest {
    typealias ProtobufType = Videoconference_V1_SendGrootCellsRequest
    func toProtobuf() throws -> Videoconference_V1_SendGrootCellsRequest {
        var request = ProtobufType()
        request.channelMeta = channel.pbType
        request.cells = cells.map { $0.pbType }
        return request
    }
}

private extension GrootCell {
    var pbType: PBGrootCell {
        var cell = PBGrootCell()
        if let action = PBGrootCell.Action(rawValue: action.rawValue) {
            cell.action = action
        }
        if dataType != .unknown, let dataType = PBGrootCell.DataType(rawValue: dataType.rawValue) {
            cell.dataType = dataType
        }
        if let sender = sender {
            cell.sender = sender.pbType
        }
        if pageID > 0 {
            cell.pageID = pageID
        }
        if upVersion > 0 {
            cell.upVersionI64 = upVersion
        }
        cell.payload = payload
        return cell
    }
}
