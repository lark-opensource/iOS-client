//
//  MinutesTracker.swift
//  Minutes_iOS
//
//  Created by panzaofeng on 2020/12/23.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import LKCommonsTracker
import MinutesFoundation
import MinutesNetwork

/// class MinutesTracker
class MinutesTracker: BusinessTracker {
    private var minutes: MinutesInfo

    public init(minutes: Minutes) {
        self.minutes = minutes.info
        super.init()
    }

    public init(info: MinutesInfo) {
        self.minutes = info
        super.init()
    }

    override func commonParamsGenerat() -> [AnyHashable: Any] {
        var params = super.commonParamsGenerat()
        params["conference_id"] = minutes.basicInfo?.meetingID ?? ""
        params["is_page_owner"] = (minutes.basicInfo?.isOwner ?? false) ? true : false
        params["token"] = minutes.basicInfo?.objectToken ?? ""
        params["object_type"] = String(minutes.basicInfo?.objectType.rawValue ?? 0)
        params["is_page_editor"] = minutes.basicInfo?.canModify ?? false

        return params
    }

    private var lastTrackDate: Date = Date()
    private let queue: DispatchQueue = DispatchQueue.global(qos: .background)
    private let keepAlivePeriod: Int = 60000
    private var isTracking: Bool = false

    func pageActive() {
        MinutesLogger.common.info("starting track page active")
        queue.async {
            self.lastTrackDate = Date()
            self.isTracking = true
        }

        queue.asyncAfter(deadline: .now() + .milliseconds(keepAlivePeriod)) { [weak self] in
            self?.flushKeepAliveDuration(true)
        }
    }

    func pageDeactive() {
        MinutesLogger.common.info("stopping track page active")
        queue.async {
            self.flushKeepAliveDuration(false)
        }
    }

    private func flushKeepAliveDuration(_ alive: Bool) {
        guard isTracking else {
            return
        }
        let current = Date()
        let ms = Int(current.timeIntervalSince(lastTrackDate) * 1000)

        MinutesLogger.common.info("track page active \(ms)")
        if ms > keepAlivePeriod {
            trackerAliveDuration(keepAlivePeriod)
        } else {
            trackerAliveDuration(ms)
        }

        if alive {
            self.lastTrackDate = current
            queue.asyncAfter(deadline: .now() + .milliseconds(keepAlivePeriod)) { [weak self] in
                self?.flushKeepAliveDuration(true)
            }
        } else {
            isTracking = false
        }
    }

    private func trackerAliveDuration(_ duration: Int) {
        var params = [AnyHashable: Any]()
        params["url"] = minutes.baseURL.absoluteString
        params["duration"] = duration
        params["title"] = minutes.basicInfo?.topic ?? ""
        tracker(name: .pageAlive, params: params)
    }
}
