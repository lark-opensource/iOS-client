//
//  PausedAgenda.swift
//  ByteViewNetwork
//
//  Created by ByteDance on 2023/8/15.
//

import Foundation

/// 暂停的议程
/// Videoconference_V1_PausedAgenda
public struct PausedAgenda: Equatable {

    public init(agendaID: String,
                relativePausedTime: Int64) {
        self.agendaID = agendaID
        self.relativePausedTime = relativePausedTime
    }

    public var agendaID: String
    /// 议程暂停相对会议开始的时间
    public var relativePausedTime: Int64
}

extension PausedAgenda: CustomStringConvertible {

    public var description: String {
        String(indent: "AgendaInfo",
               "agendaID: \(agendaID)",
               "relativePausedTime: \(relativePausedTime)")
    }
}
