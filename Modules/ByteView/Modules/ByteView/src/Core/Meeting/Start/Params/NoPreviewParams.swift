//
//  NoPreviewParams.swift
//  ByteView
//
//  Created by kiri on 2022/8/5.
//

import Foundation

struct NoPreviewParams: EntryParams, CustomStringConvertible {
    let id: String
    let idType: EntryIdType
    let source: MeetingEntrySource = .openPlatform
    let entryType: EntryType = .noPreview
    let isJoinMeeting: Bool = true
    let isCall: Bool = false
    let mic: Bool?
    let camera: Bool?
    let speaker: Bool?

    var description: String {
        "NoPreviewParams(id: \(id), idType: \(idType), mic: \(mic), camera: \(camera), speaker: \(speaker))"
    }

    static func openPlatform(id: String, mic: Bool?, camera: Bool?, speaker: Bool?) -> NoPreviewParams {
        .init(id: id, idType: .reservationId, mic: mic, camera: camera, speaker: speaker)
    }
}
