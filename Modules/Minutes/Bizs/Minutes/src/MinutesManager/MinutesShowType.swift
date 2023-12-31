//
//  MinutesShowType.swift
//  Minutes
//
//  Created by 陈乐辉 on 2023/11/10.
//

import Foundation
import MinutesNetwork
import LarkContainer

enum MinutesShowType {
    case detail
    case clip
    case podcast
    case record
    case preview
}

struct MinutesShowParams {
    let minutes: Minutes
    let userResolver: UserResolver
    let player: MinutesVideoPlayer?
    let source: MinutesSource?
    let destination: MinutesDestination?
    let recordingSource: MinutesAudioRecordingSource?
    let topic: String

    init(minutes: Minutes, userResolver: UserResolver, player: MinutesVideoPlayer? = nil, source: MinutesSource? = nil, destination: MinutesDestination? = nil, recordingSource: MinutesAudioRecordingSource? = nil, topic: String = "") {
        self.minutes = minutes
        self.userResolver = userResolver
        self.player = player
        self.source = source
        self.destination = destination
        self.recordingSource = recordingSource
        self.topic = topic
    }
}
