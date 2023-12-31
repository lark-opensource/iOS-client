//
//  InstanceMemoryCache.swift
//  Calendar
//
//  Created by 张威 on 2020/10/14.
//

import UIKit
import ThreadSafeDataStructure
import CalendarFoundation

/// Instance Memory Cache

private let logger = InstanceServiceImpl.logger

final class InstanceMemoryCache {

    private struct Storage {
        var timeZoneId: String
        var dict: DayRustInstanceMap
        var version: Int
    }

    private var storage = Storage(timeZoneId: TimeZone.current.identifier, dict: .init(), version: 0)

    // MARK: Trim

    /// 裁剪策略
    struct TrimStrategy: CustomDebugStringConvertible {
        // 时区
        var activeTimeZone: TimeZone
        // 指定范围
        var activeDays: Set<JulianDay>

        var debugDescription: String {
            return "activeTimeZone: \(activeTimeZone.identifier), activeDays: \(activeDays)"
        }
    }

    private let trimThrottle: Throttler
    private let queue: DispatchQueue
    init(queue: DispatchQueue) {
        self.queue = queue
        trimThrottle = Throttler(delay: 3, executeLast: true, queue: queue)
    }

    #if DEBUG
    // 预期本类的 api 都在同一个队列中被访
    private var threadContext = (identifier: ObjectIdentifier, desc: String)?.none
    private func checkThreadSafe() {
        dispatchPrecondition(condition: .onQueue(queue))
    }
    #endif

    // 根据策略裁剪
    func trimItems(with strategy: TrimStrategy) {
        #if DEBUG
        checkThreadSafe()
        #endif
        if storage.timeZoneId != strategy.activeTimeZone.identifier {
            doTrim(with: strategy)
        } else {
            trimThrottle.call { [weak self] in self?.doTrim(with: strategy) }
        }
    }

    private func doTrim(with strategy: TrimStrategy) {
        if storage.timeZoneId != strategy.activeTimeZone.identifier {
            storage.dict.removeAll()
        }
        for day in storage.dict.keys where !strategy.activeDays.contains(day) {
            storage.dict.removeValue(forKey: day)
        }
        logger.info("trim memory cache. strategy: \(strategy.debugDescription)")
    }

    // MARK: Version

    var version: Int {
        #if DEBUG
        checkThreadSafe()
        #endif
        return storage.version
    }

    func trimAll(withNewVersion version: Int) {
        #if DEBUG
        checkThreadSafe()
        #endif
        assert(version >= storage.version)
        storage.version = version
        storage.dict.removeAll()
    }

    // MARK: Get

    func getAllItems(in timeZone: TimeZone) -> DayRustInstanceMap {
        #if DEBUG
        checkThreadSafe()
        #endif
        guard storage.timeZoneId == timeZone.identifier else { return .init() }
        return storage.dict
    }

    func getItems(for days: [JulianDay], in timeZone: TimeZone, with version: Int) -> DayRustInstanceMap {
        #if DEBUG
        checkThreadSafe()
        #endif
        guard storage.version == version && storage.timeZoneId == timeZone.identifier else {
            return .init()
        }
        return storage.dict.filter { days.contains($0.key) }
    }

    func getItems(for dayRange: JulianDayRange, in timeZone: TimeZone, with version: Int) -> DayRustInstanceMap {
        #if DEBUG
        checkThreadSafe()
        #endif
        return getItems(for: [JulianDay](dayRange), in: timeZone, with: version)
    }

    // MARK: Update

    /// 更新 items
    func updateItems(_ items: DayRustInstanceMap, in timeZone: TimeZone, with version: Int) {
        #if DEBUG
        checkThreadSafe()
        #endif
        guard storage.version == version else { return }
        guard storage.timeZoneId == timeZone.identifier else { return }
        items.forEach { storage.dict[$0.key] = $0.value }
    }

}
