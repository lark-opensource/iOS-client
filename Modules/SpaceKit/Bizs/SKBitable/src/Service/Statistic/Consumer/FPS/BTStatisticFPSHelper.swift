//
//  BTStatisticFPSHelper.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/12/1.
//

import Foundation

final class BTStatisticFPSHelper {
    static let drop3 = 3
    static let drop7 = 7
    static let drop25 = 25

    static func getFPSAverage(fpsInfo: [Int: Double]) -> Float {
        if fpsInfo.isEmpty {
            return 0
        }
        if fpsInfo.count > BTStatisticConstant.fpsMaxCount {
            return 0
        }
        var fpsAverage: Float = 0
        let count = fpsInfo.count
        if count > 0 {
            var totalFPS = 0
            fpsInfo.values.forEach { fps in
                totalFPS += Int(fps)
            }
            fpsAverage = Float(totalFPS) / Float(count)
        }
        return fpsAverage
    }

    static func dropStateRatio(dropCountInfo: [AnyHashable: Int]) -> [String: Any]? {
        if dropCountInfo.isEmpty {
            return nil
        }
        if dropCountInfo.count > BTStatisticConstant.dropMaxCount {
            return nil
        }
        var totalCount = 0
        var stateCounts: [BTFPSDropState: Int] = [:]
        dropCountInfo.forEach { (key, value) in
            guard let realKey = key as? String,
                  let fps = Int(realKey),
                  value > 0 else {
                return
            }
            totalCount += value
            let state = BTFPSDropState.state(dropFrame: fps)
            stateCounts[state] = (stateCounts[state] ?? 0) + value
        }
        guard totalCount > 0 else {
            return nil
        }
        var result = [String: Any]()

        for caseValue in BTFPSDropState.allCases {
            guard let count = stateCounts[caseValue] else {
                continue
            }
            result[caseValue.rawValue] = Float(count) / Float(totalCount)
        }
        return result
    }

    static func dropDurationRatio(dropDurationInfo: [AnyHashable : Double], hitchDuration: Double, duration: Double) -> [String: Any]? {
        if dropDurationInfo.isEmpty {
            return nil
        }
        if dropDurationInfo.count > BTStatisticConstant.dropMaxCount {
            return nil
        }
        guard hitchDuration > 0, duration > 0 else {
            return nil
        }
        var result = [String: Any]()

        var drop3Dur: Double = 0
        var drop7Dur: Double = 0
        var drop25Dur: Double = 0

        dropDurationInfo.forEach { (key, value) in
            guard let realKey = key as? String,
                  let fps = Int(realKey),
                  value > 0 else {
                return
            }
            if fps >= drop3 {
                drop3Dur += value
            }
            if fps >= drop7 {
                drop7Dur += value
            }
            if fps >= drop25 {
                drop25Dur += value
            }
        }

        result["hitch_dur_ratio"] = hitchDuration / duration
        result["drop3_dur_ratio"] = drop3Dur / duration
        result["drop7_dur_ratio"] = drop7Dur / duration
        result["drop25_dur_ratio"] = drop25Dur / duration
        return result
    }
}
