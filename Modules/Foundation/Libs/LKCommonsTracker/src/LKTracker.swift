//
//  LKTracker.swift
//  LKCommonsTracker
//
//  Created by lichen on 2018/11/27.
//

import Foundation

public final class Tracker {

    public static let shared = Tracker()

    // 存储注册的 tracker
    var trackerDic: [Platform: TrackServiceWrapper] = [:]
    // 用于存储没有注册过的事件
    var cacheDic: [Platform: DefaultService] = [:]
    // tracker 锁
    let lock: NSLock = NSLock()

    // 存储事件开始时间
    var timeDic: [String: TimeInterval] = [:]
    // time lock
    let timeLock: NSLock = NSLock()

    public func register(key: Platform, tracker: TrackerService) {
        lock.lock()
        defer { lock.unlock() }

        if let cache = cacheDic[key] {
            cache.cache.forEach { (event) in
                tracker.post(event: event)
            }
            cacheDic[key] = nil
        }

        if let wrapper = trackerDic[key] {
            if !wrapper.services.contains(where: { (service) -> Bool in
                return service === tracker
            }) {
                wrapper.services.append(tracker)
                trackerDic[key] = wrapper
            }
        } else {
            let wrapper = TrackServiceWrapper()
            wrapper.services.append(tracker)
            trackerDic[key] = wrapper
        }
    }

    public func unregister(key: Platform, tracker: TrackerService) {
        lock.lock()
        defer { lock.unlock() }
        if let wrapper = trackerDic[key] {
            if let index = wrapper.services.firstIndex(where: { (service) -> Bool in
                return service === tracker
            }) {
                wrapper.services.remove(at: index)
                trackerDic[key] = wrapper
            }
        }
    }

    public func unregisterAll(key: Platform) {
        lock.lock()
        defer { lock.unlock() }
        trackerDic[key] = nil
    }

    public func tracker(key: Platform) -> TrackerService {
        lock.lock()
        defer { lock.unlock() }

        if let tracker = self.trackerDic[key] {
            return tracker
        }
        if let defaultTracker = self.cacheDic[key] {
            return defaultTracker
        }
        let tracker = DefaultService(platform: key)
        self.cacheDic[key] = tracker
        return tracker
    }

    public func start(token: String) {
        timeLock.lock()
        defer { timeLock.unlock() }

        let start = Date().timeIntervalSince1970
        self.timeDic[token] = start
    }

    public func end(token: String) -> Timestamp? {
        timeLock.lock()
        defer { timeLock.unlock() }

        if let start = self.timeDic[token] {
            self.timeDic[token] = nil
                let end = Date().timeIntervalSince1970
                return Timestamp(start: start, end: end)
        } else {
            print("warning: dont't exist start time for token \(token) in LKCommonsTracker")
        }
        return nil
    }

    public static func currentTime() -> Timestamp {
        let time = Date().timeIntervalSince1970
        return Timestamp(time: time)
    }
}
