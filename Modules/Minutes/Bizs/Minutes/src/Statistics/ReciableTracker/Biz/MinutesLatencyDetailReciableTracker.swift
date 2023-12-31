//
//  MinutesLatencyDetailReciableTracker.swift
//  Minutes
//
//  Created by lvdaqian on 2021/7/4.
//

import Foundation

public class MinutesLatencyDetailReciableTracker {

    var latencyDetail: [String: Any] = [String: Any]()
    var lastTrackedTime: TimeInterval = 0.0
    var wholeTrackedTime: Int = 0

    func finishPreProcess() {
        let now = CFAbsoluteTimeGetCurrent()
        let processTime = Int((now - lastTrackedTime) * 1000)
        latencyDetail["pre_process"] = processTime
        lastTrackedTime = now
        wholeTrackedTime += processTime
    }

    func finishNetworkReqeust() {
        let now = CFAbsoluteTimeGetCurrent()
        let processTime = Int((now - lastTrackedTime) * 1000)
        latencyDetail["network_request"] = processTime
        lastTrackedTime = now
        wholeTrackedTime += processTime
    }

    func finishDataProcess() {
        let now = CFAbsoluteTimeGetCurrent()
        let processTime = Int((now - lastTrackedTime) * 1000)
        latencyDetail["data_process"] = processTime
        lastTrackedTime = now
        wholeTrackedTime += processTime
    }

    func finishRender() {
        let now = CFAbsoluteTimeGetCurrent()
        let processTime = Int((now - lastTrackedTime) * 1000)
        latencyDetail["render"] = processTime
        latencyDetail["metric"] = NetPerformance.readNetPerformance()
        lastTrackedTime = now
        wholeTrackedTime += processTime
        latencyDetail["latency"] = wholeTrackedTime
    }

    func reset() {
        lastTrackedTime = CFAbsoluteTimeGetCurrent()
        wholeTrackedTime = 0
        latencyDetail = ["latency": 0,
                         "pre_process": 0,
                         "network_request": 0,
                         "data_process": 0,
                         "render": 0,
                         "metric": [String: Any]()]
    }
}
