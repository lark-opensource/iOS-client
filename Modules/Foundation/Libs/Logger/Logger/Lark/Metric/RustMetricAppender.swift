//
//  RustMetricAppender.swift
//  LarkApp
//
//  Created by Miaoqi Wang on 2019/11/20.
//

import Foundation
import LKMetric

public final class RustMetricAppender: Appender {

    private static var metricInit = false

    public static func identifier() -> String {
        return "\(RustMetricAppender.self)"
    }

    public static func setupMetric(storePath: String) {
        let result = init_metric_path(storePath)
        if result == 0 {
            metricInit = true
        } else {
            #if DEBUG
            print("RustMetricAppender setup failed \(result)")
            #endif
            return
        }
        LogCenter.setup(config: [LKMetricLogCategory: [RustMetricAppender()]])
    }

    public static func persistentStatus() -> Bool { return false }
    public func persistent(status: Bool) {}

    public func doAppend(_ event: LogEvent) {
        guard RustMetricAppender.metricInit else {
            assertionFailure("RustMetricAppender need initialization")
            return
        }
        guard let metricEvent = MetricEvent(time: event.time, logParams: event.params, error: event.error) else {
            #if DEBUG
            print("RustMetricAppender metric event init error \(event)")
            #endif
            return
        }

        #if DEBUG
        print("RustMetricAppender append \(metricEvent)")
        #endif

        let result = write_metric_v2(
            metricEvent.time,
            metricEvent.tracingId,
            metricEvent.domain,
            Int32(metricEvent.domain.count),
            metricEvent.mType,
            metricEvent.id,
            metricEvent.params,
            metricEvent.emitType,
            metricEvent.emitValue
        )

        if result != 0 {
            #if DEBUG
            print("RustMetricAppender write error \(result)")
            #endif
        }
    }
}
