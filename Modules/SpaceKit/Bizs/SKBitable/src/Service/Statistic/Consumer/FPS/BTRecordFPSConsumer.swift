//
//  BTRecordFPSConsumer.swift
//  SKFoundation
//
//  Created by 刘焱龙 on 2023/9/17.
//

import Foundation
import SKFoundation

final class BTRecordFPSConsumer: BTStatisticConsumer, BTStatisticFPSConsumer {
    private let scene: BTStatisticFPSScene

    private var tag: String {
        return scene.rawValue
    }

    init(scene: BTStatisticFPSScene) {
        self.scene = scene
    }

    func consume(trace: BTStatisticFPSTrace, logger: BTStatisticLoggerProvider, fpsInfo: BTStatisticFPSInfo) {
        logger.send(
            trace: trace,
            eventName: BTStatisticEventName.base_mobile_performance_fps_info.rawValue,
            params: [
                BTStatisticFPSEventKey.scene.rawValue: scene.rawValue,
                BTStatisticFPSEventKey.duration.rawValue : fpsInfo.duration,
                BTStatisticFPSEventKey.fps.rawValue: fpsInfo.averageFPS
            ])
    }

    func consume(trace: BTStatisticTrace, logger: BTStatisticLoggerProvider, dropFrameInfo: BTStatisticDropFrameInfo) {
        logger.send(
            trace: trace,
            eventName: BTStatisticEventName.base_mobile_performance_drop_frame_info.rawValue,
            params: [
                BTStatisticFPSEventKey.scene.rawValue: scene.rawValue,
                BTStatisticFPSEventKey.drop_frame.rawValue: dropFrameInfo.dropCounts,
                BTStatisticFPSEventKey.drop_durations.rawValue: dropFrameInfo.dropDurations,
                BTStatisticFPSEventKey.duration.rawValue: dropFrameInfo.duration,
                BTStatisticFPSEventKey.hitch_duration.rawValue: dropFrameInfo.hitchDuration,
                BTStatisticFPSEventKey.drop_state_ratio.rawValue: dropFrameInfo.dropFrameRatio,
                BTStatisticFPSEventKey.drop_dur_ratio.rawValue: dropFrameInfo.dropDurationRatio
            ])
    }
}
