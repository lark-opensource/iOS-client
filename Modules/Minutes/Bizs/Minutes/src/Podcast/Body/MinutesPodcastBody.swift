//
//  MinutesPodcastBody.swift
//  ByteView
//
//  Created by panzaofen.cn on 2021/1/12.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import EENavigator
import MinutesFoundation
import MinutesNetwork

public struct MinutesPodcastBody: PlainBody {
    public static let pattern = "//client/minutes/podcast"
    let minutes: Minutes
    let player: MinutesVideoPlayer?

    public init(minutes: Minutes, player: MinutesVideoPlayer? = nil) {
        self.minutes = minutes
        self.player = player
    }
}
