//
//  Notes+Rust.swift
//  ByteViewNetwork
//
//  Created by liurundong.henry on 2023/5/15.
//

import Foundation
import RustPB

typealias PBNotesInfo = Videoconference_V1_NotesInfo
typealias PBAgendaInfo = Videoconference_V1_AgendaInfo
typealias PBPausedAgenda = Videoconference_V1_PausedAgenda

extension PBNotesInfo {
    var vcType: NotesInfo {
        .init(notesURL: notesURL,
              activatingAgenda: activatingAgenda.vcType,
              pausedAgenda: pausedAgenda.vcType)
    }
}

extension PBAgendaInfo {
    var vcType: AgendaInfo {
        .init(agendaID: agendaID,
              relativeActivatedTime: relativeActivatedTime,
              duration: duration,
              suiteVersion: suiteVersion,
              status: status.vcType,
              title: title,
              realEndTime: realEndTime)
    }
}

extension PBAgendaInfo.Status {
    var vcType: AgendaInfo.Status {
        .init(rawValue: self.rawValue) ?? .unknown
    }
}

extension PBPausedAgenda {
    var vcType: PausedAgenda {
        .init(agendaID: agendaID,
              relativePausedTime: relativePausedTime)
    }
}
