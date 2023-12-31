//
//  MinutesAudioRecordingBody.swift
//  Minutes
//
//  Created by 陈乐辉 on 2023/11/14.
//

import Foundation
import EENavigator
import MinutesFoundation
import MinutesNetwork
import MinutesInterface


public struct MinutesAudioRecordingBody: PlainBody {
    public static let pattern = "//client/minutes/audio/recording"
    let minutes: Minutes
    let source: MinutesAudioRecordingSource?

    public init(minutes: Minutes, source: MinutesAudioRecordingSource?){
        self.minutes = minutes
        self.source = source
    }
}
