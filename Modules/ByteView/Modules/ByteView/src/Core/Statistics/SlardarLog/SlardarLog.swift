//
//  SlardarLog.swift
//  ByteView
//
//  Created by chentao on 2018/12/19.
//

import Foundation
import RxSwift
import ByteViewCommon
import ByteViewTracker

class SlardarLog {

    private struct Statistics {
        static var logStatisticsMap: [String: Int64] = [:]
        static let statisticsQueue = DispatchQueue(label: "LogStatistics.serialQueue", qos: .background)
        static var statisticsTimer: Timer?
    }

    static let shared = SlardarLog()

    static func updateConferenceId(_ id: String?) {
        // 仅统计会中日志打印
        if id != nil {
            startStatisticsTimer()
        } else {
            stopStatisticsTimer()
        }
    }

    static func log(with category: String) {
        frequencyStatistics(category: category)
    }
}

extension SlardarLog {
    private static func frequencyStatistics(category: String) {
        Statistics.statisticsQueue.async {
            if let count = Statistics.logStatisticsMap[category] {
                Statistics.logStatisticsMap[category] = count + 1
            } else {
                Statistics.logStatisticsMap[category] = 1
            }
        }
    }

    private static func clearStatistics() {
        Statistics.statisticsQueue.async {
            Statistics.logStatisticsMap.removeAll()
        }
    }

    private static func startStatisticsTimer() {
        DispatchQueue.main.async {
            if Statistics.statisticsTimer == nil {
                clearStatistics()
                // 60s上报一次日志打印数量
                Statistics.statisticsTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true, block: { _ in
                    trackFrequencyStatistics()
                })
            }
        }
    }

    private static func stopStatisticsTimer() {
        Statistics.statisticsTimer?.invalidate()
        Statistics.statisticsTimer = nil
    }

    private static func trackFrequencyStatistics() {
        Statistics.statisticsQueue.async {
            var uploadStatistics: String = ""
            Statistics.logStatisticsMap.forEach {
                let key = $0.key.replacingOccurrences(of: ".", with: "_") // 鉴于SQL解析对"."符号有特殊要求，category中改用"_"做连接
                if !key.isEmpty, $0.value > 0 {
                    uploadStatistics.append(key) // 为动态获取Category名称，以特定String的格式上报，由数据同学分割
                    uploadStatistics.append(":")
                    uploadStatistics.append(String($0.value))
                    uploadStatistics.append("#")
                }
            }
            if !uploadStatistics.isEmpty {
                uploadStatistics.removeLast() // 删掉最后一个"#"
            }
            AppreciableTracker.shared.track(.vc_log_frequency_monitor, params: ["log_category": uploadStatistics])
            Statistics.logStatisticsMap.removeAll()
        }
    }

}
