//
//  MinutesAudioPreviewBody.swift
//  Minutes
//
//  Created by 陈乐辉 on 2023/11/14.
//

import Foundation
import EENavigator
import MinutesFoundation
import MinutesNetwork
import MinutesInterface


public struct MinutesAudioPreviewBody: PlainBody {
    public static let pattern = "//client/minutes/audio/preview"
    let minutes: Minutes
    let topic: String

    public init(minutes: Minutes, topic: String){
        self.minutes = minutes
        self.topic = topic
    }
}
