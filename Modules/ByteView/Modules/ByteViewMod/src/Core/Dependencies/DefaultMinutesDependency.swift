//
//  DefaultMinutesDependency.swift
//  LarkByteView
//
//  Created by kiri on 2021/6/30.
//

import Foundation
import ByteView

final class DefaultMinutesDependency: MinutesDependency {
    var isAudioRecording: Bool { false }
    var isPodcastMode: Bool { false }
    func stopPodcast() { }
    func stopAudioRecording() { }
}
