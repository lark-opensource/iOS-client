//
//  SendImageProcessKeyPointTracker.swift
//  LarkMessageCore
//
//  Created by zc09v on 2019/11/25.
//

import UIKit
import Foundation
import ThreadSafeDataStructure

final class SendImageProcessKeyPointTracker {
    private var trackInfoMap: SafeDictionary<String, SendImageProcessTrackerInfo> = [:] + .readWriteLock

    func startImageProcess(indentify: String, imageFrom: ImageFrom) {
        let info = SendImageProcessTrackerInfo(indentify: indentify, imageFrom: imageFrom)
        info.pointCost[.total] = CACurrentMediaTime()
        trackInfoMap[indentify] = info
    }

    func startThumbImageProcess(indentify: String) {
        self.start(indentify: indentify, process: .thumbImageProcess)
    }

    func endThumbImageProcess(indentify: String) {
        self.end(indentify: indentify, process: .thumbImageProcess)
    }

    func startImageRequest(indentify: String) {
        self.start(indentify: indentify, process: .imageRequest)
    }

    func endImageRequest(indentify: String) {
        self.end(indentify: indentify, process: .imageRequest)
    }

    func startOriginImageProcess(indentify: String) {
        self.start(indentify: indentify, process: .originImageProcess)
    }

    func endOriginImageProcess(indentify: String) {
        self.end(indentify: indentify, process: .originImageProcess)
    }

    func endImageProcess(indentify: String) -> SendImageProcessTrackerInfo? {
        guard let info = trackInfoMap[indentify], let start = info.pointCost[.total] else {
            return nil
        }
        info.pointCost[.total] = CACurrentMediaTime() - start
        trackInfoMap.removeValue(forKey: indentify)
        return info
    }

    private func start(indentify: String, process: KeyPointForSendImageProcess) {
        guard let info = trackInfoMap[indentify] else {
            return
        }
        info.pointCost[process] = CACurrentMediaTime()
    }

    private func end(indentify: String, process: KeyPointForSendImageProcess) {
        guard let info = trackInfoMap[indentify], let start = info.pointCost[process] else {
            return
        }
        info.pointCost[process] = CACurrentMediaTime() - start
    }
}

public enum ImageFrom: Int {
    case takePhoto
    case photoLibrary
}

enum KeyPointForSendImageProcess: String {
    case total
    case thumbImageProcess
    case imageRequest
    case originImageProcess
}

final class SendImageProcessTrackerInfo {
    let indentify: String
    private let imageFrom: ImageFrom
    // 记录各指标耗时
    var pointCost: SafeDictionary<KeyPointForSendImageProcess, TimeInterval> = [:] + .readWriteLock

    init(indentify: String, imageFrom: ImageFrom) {
        self.indentify = indentify
        self.imageFrom = imageFrom
    }

    // 作为参数放在metric中，Slardar打点使用
    var metricLog: [String: String] {
        return pointCost.reduce([String: String]()) { (result, arg) -> [String: String] in
            let (key, value) = arg
            var result = result
            result[key.rawValue] = "\(Int64(value * 1000))"
            return result
        }
    }

    var category: [String: String] {
        return ["imageFrom": "\(imageFrom.rawValue)"]
    }
}
