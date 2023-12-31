//
//  MinutesPodcastReciableTracker.swift
//  ByteView
//
//  Created by panzaofeng on 2021/4/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import AppReciableSDK

final class MinutesPodcastReciableTracker: MinutesLatencyDetailReciableTracker {

    public static let shared = MinutesPodcastReciableTracker()

    func startEnterPodcast() {
        MinutesReciableTracker.shared.start(biz: .VideoConference, scene: .MinutesPodcast, event: Event.minutes_enter_podcast_time, extra: nil)
        reset()
    }

    func endEnterPodcast() {
        finishRender()
        let extra = Extra(isNeedNet: true, latencyDetail: latencyDetail)
        MinutesReciableTracker.shared.end(event: Event.minutes_enter_podcast_time, extra: extra)
    }
}
