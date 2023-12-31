//
//  NotesInfo.swift
//  ByteViewNetwork
//
//  Created by liurundong.henry on 2023/5/11.
//

import Foundation

/// 会议纪要
/// Videoconference_V1_NotesInfo
public struct NotesInfo: Equatable {

    public init(notesURL: String,
                activatingAgenda: AgendaInfo,
                pausedAgenda: PausedAgenda) {
        self.notesURL = notesURL
        self.activatingAgenda = activatingAgenda
        self.pausedAgenda = pausedAgenda
    }

    /// 纪要链接
    public var notesURL: String
    /// 当前正在进行的议程
    public var activatingAgenda: AgendaInfo
    /// 暂停的议程
    public var pausedAgenda: PausedAgenda

}

extension NotesInfo: CustomStringConvertible {

    public var description: String {
        String(indent: "NotesInfo",
               "notesURL.hash: \(notesURL.hashValue)",
               "activatingAgenda: \(activatingAgenda)",
               "pausedAgenda: \(pausedAgenda)")
    }

}
