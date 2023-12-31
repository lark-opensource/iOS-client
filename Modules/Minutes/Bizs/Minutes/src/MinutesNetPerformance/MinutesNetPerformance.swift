//
//  MinutesNetPerformance.swift
//  Minutes
//
//  Created by Yuankai Zhu on 8/3/22.
//

import Foundation
import MinutesFoundation
import MinutesNetwork

public struct NetPerformance {
    static var apiNetPerformance: [String: Any] = [String: Any]()
    static let semaphore = DispatchSemaphore(value: 1)

    public static func setNetPerformance(apiDesc: String, requestStart: Double, requestEnd: Double, parseStart: Double, parseEnd: Double) {
        if urlWhiteList.contains(apiDesc) {
            semaphore.wait()
            apiNetPerformance[apiDesc] = ["net_state_1": getNetStateTime(start: requestStart, end: requestEnd), "net_state_2": getNetStateTime(start: parseStart, end: parseEnd)]
            semaphore.signal()
        }
    }
    
    public static func readNetPerformance() -> [String : Any] {
        semaphore.wait()
        let netPerformance = apiNetPerformance
        apiNetPerformance.removeAll()
        semaphore.signal()
        return netPerformance
    }

    static func getNetStateTime(start: Double, end: Double) -> Int {
        return Int((end - start) * 1000)
    }
    
    static let urlWhiteList: Set<String> = [MinutesAPIPath.subtitles,
                                            MinutesAPIPath.baseInfo,
                                            MinutesAPIPath.simpleBaseInfo,
                                            MinutesAPIPath.keywords,
                                            MinutesAPIPath.summaries]
}
