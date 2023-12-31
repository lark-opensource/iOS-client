//
//  BTStatisticConsumer.swift
//  SKFoundation
//
//  Created by 刘焱龙 on 2023/8/29.
//

import Foundation
import SKFoundation

struct BTStatisticFPSInfo {
    // 当前滑动时间内的平均帧，因为高刷、动态帧率的存在，该数据仅供参考，推荐使用丢帧率和丢帧时长率
    let averageFPS: Float

    // 滑动时长
    let duration: Double
}

struct BTStatisticDropFrameInfo {
    // 丢帧原始数据，不推荐使用
    let dropCounts: [AnyHashable: Int]

    // 丢帧时长原始数据，不推荐使用
    let dropDurations: [AnyHashable: Double]

    // 丢帧率，仅供参考，推荐使用丢帧时长率
    let dropFrameRatio: [String: Any]

    // 丢帧时长率
    let dropDurationRatio: [String: Any]

    // 滑动时长
    let duration: Double

    // 丢帧时长
    let hitchDuration: Double
}

class BTStatisticConsumer: NSObject {}

protocol BTStatisticNormalConsumer: BTStatisticConsumer {
    func consume(
        trace: BTStatisticBaseTrace,
        logger: BTStatisticLoggerProvider,
        currentPoint: BTStatisticNormalPoint,
        allPoint: [BTStatisticNormalPoint]
    ) -> [BTStatisticNormalPoint]

    func consumeTempPoint(
        trace: BTStatisticBaseTrace,
        currentPoint: BTStatisticNormalPoint,
        allPoint: [BTStatisticNormalPoint]
    ) -> [BTStatisticNormalPoint]
}

extension BTStatisticNormalConsumer {
    func consumeTempPoint(
        trace: BTStatisticBaseTrace,
        currentPoint: BTStatisticNormalPoint,
        allPoint: [BTStatisticNormalPoint]
    ) -> [BTStatisticNormalPoint] {
        return []
    }
}

protocol BTStatisticFPSConsumer: BTStatisticConsumer {
    func consume(trace: BTStatisticFPSTrace, logger: BTStatisticLoggerProvider, fpsInfo: BTStatisticFPSInfo)

    func consume(
        trace: BTStatisticTrace,
        logger: BTStatisticLoggerProvider,
        dropFrameInfo: BTStatisticDropFrameInfo
    )
}
