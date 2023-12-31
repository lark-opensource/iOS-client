//
//  MinutesListReciableTracker.swift
//  ByteView
//
//  Created by panzaofeng on 2021/4/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import AppReciableSDK

public final class MinutesListReciableTracker: MinutesLatencyDetailReciableTracker {

    public static let shared = MinutesListReciableTracker()

    // listType: 0 - me, 1 - share, 2 - home, 3 - trash
    public func startEnterList(listType: Int) {
        let extra = Extra.init(category: ["listtype": listType], extra: nil)
        MinutesReciableTracker.shared.start(biz: .VideoConference, scene: .MinutesList, event: Event.minutes_enter_list_time, extra: extra)
        reset()
    }

    public func endEnterList() {
        finishRender()
        let extra = Extra(isNeedNet: true, latencyDetail: latencyDetail)
        MinutesReciableTracker.shared.end(event: Event.minutes_enter_list_time, extra: extra)
    }

    public func loadError(page: String = "me", error: Error) {
        MinutesReciableTracker.shared.error(biz: .VideoConference,
                                            scene: .MinutesList,
                                            event: .minutes_load_list_error,
                                            page: page,
                                            error: error)
    }
}
