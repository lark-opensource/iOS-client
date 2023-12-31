//
//  InstanceCache.swift
//  Calendar
//
//  Created by zhuheng on 2020/7/3.
//

import Foundation
import CryptoSwift
import CalendarFoundation
import RxSwift
import ThreadSafeDataStructure
import LKCommonsLogging
import CTFoundation

typealias TimeZoneId = String

protocol InstanceCacheDelegateOld: AnyObject {
    func cacheElimnated() // 淘汰后回调（将废弃）
    func cacheChanged(instance: [CalendarEventInstanceEntity], timeZoneId: String)
}

struct InstanceCachedDataOld {
    var timeZoneId: String = TimeZone.current.identifier
    var instanceEntityMap: [String: CalendarEventInstanceEntity] = [:]
    var julianDays: Set<Int32> = Set<Int32>()
    var version: Int = 0
    func getInstances() -> [CalendarEventInstanceEntity] {
        return instanceEntityMap.map { (_, instance) -> CalendarEventInstanceEntity in
            return instance
        }
    }

}

protocol InstanceCacheOld {
    // 更新缓存窗口，淘汰JulianDayRange之外的instance
    func updateCacheWindow(with range: JulianDayRange)
    // 查询缓存instance，未命中返回空
    func selectInstances(with range: JulianDayRange, timeZoneId: TimeZoneId) -> [CalendarEventInstanceEntity]?
    // 更新instance
    func updateCachedInstances(new: [CalendarEventInstanceEntity], range: JulianDayRange?, timeZoneId: TimeZoneId)
    // 通过EventUniqueField删除instance
    func deleteInstances(with deleteEvent: [CalendarEventUniqueField], timeZoneId: TimeZoneId)
    // 删除julianday对应的instance
    func deleteInstances(with range: JulianDayRange, timeZoneId: TimeZoneId)
    // 更新时区后，缓存清空
    func update(with timeZoneId: TimeZoneId)
    var delegate: InstanceCacheDelegateOld? { get set }
    // 清理缓存，收到push时调用
    func clean()

    // 是否正在淘汰（将废弃）
    var isEliminating: Bool { get }
    var isEmpty: Bool { get } // （将废弃）
    // 获取当前前缓存范围
    func getCacheRange() -> JulianDayRange// （将废弃）
}

final class InstanceCacheImplOld: InstanceCacheOld {
    static let logger = Logger.log(InstanceCacheImplOld.self, category: "Calendar.Instance.Cache")
    weak var delegate: InstanceCacheDelegateOld?
    var isEliminating: Bool {
        return eliminationCacheItem != nil
    }

    var isEmpty: Bool {
        return self.cachedData.value.julianDays.isEmpty
    }

    private(set) var cachedData: SafeAtomic<InstanceCachedDataOld> = InstanceCachedDataOld() + .readWriteLock
    private weak var eliminationCacheItem: DispatchWorkItem?
    private let instanceSnapShot: InstanceSnapshot
    private let cacheQueue = DispatchQueue(label: "calendar.InstanceCache", qos: .default)
    init(instanceSnapShot: InstanceSnapshot) {
        self.instanceSnapShot = instanceSnapShot
    }

    // 淘汰julianDays的补集
    func updateCacheWindow(with range: JulianDayRange) {
        let julianDays = Set(range.map { Int32($0) })
        eliminationCacheItem?.cancel()
        let eliminationCacheItem = DispatchWorkItem { [weak self] in
            guard let `self` = self else { return }
            Self.logger.info("remove cache with \(julianDays)")
            self.cachedData.safeWrite { [weak self] (data) in
                if data.julianDays.max() != julianDays.max() || data.julianDays.min() != julianDays.min() {
                    data.julianDays = data.julianDays.intersection(julianDays)
                    data.instanceEntityMap = data.instanceEntityMap.filter { (_, instance) -> Bool in
                        // 淘汰掉instance所在日期与“当前预期缓存日期”没有交集的instance
                        return !instance.getInstanceDays().isDisjoint(with: julianDays)
                    }
                    data.version += 1
                    self?.delegate?.cacheElimnated()
                    Self.logger.info("remove cache sucess version: \(data.version)")
                }
            }
        }
        self.cacheQueue.asyncAfter(deadline: .now() + .seconds(3), execute: eliminationCacheItem)
        self.eliminationCacheItem = eliminationCacheItem
    }

    func getCacheRange() -> JulianDayRange {
        var julianDaySet = Set<Int32>()
        self.cachedData.safeRead { (data) in
            julianDaySet = data.julianDays
        }

        return JulianDayUtil.makeJulianDayRange(min: julianDaySet.min(), max: julianDaySet.max())
    }

    // 查询缓存instance，未命中返回空
    func selectInstances(with range: JulianDayRange, timeZoneId: TimeZoneId) -> [CalendarEventInstanceEntity]? {
        let julianDays = Set(range.map { Int32($0) })
        if timeZoneId != cachedData.value.timeZoneId {
            Self.logger.info("timeZone not match\(cachedData.value.timeZoneId)!=\(timeZoneId)")
            self.clean()
            return nil
        }

        var ret: [CalendarEventInstanceEntity]?

        self.cachedData.safeRead { [weak self] (data) in
            if data.julianDays.isEmpty || !julianDays.isSubset(of: data.julianDays) {
                Self.logger.info("julianDay not match\(julianDays)!=\(data.julianDays)")
            } else {
                Self.logger.info("cache hit")
                ret = self?.filter(with: data.getInstances(), in: range)
            }
        }

        return ret
    }

    // 更新instance
    func updateCachedInstances(new: [CalendarEventInstanceEntity], range: JulianDayRange? = nil, timeZoneId: TimeZoneId) {

        self.cachedData.safeWrite { [weak self] (data) in
            var days = data.julianDays
            if let range = range {
                days = Set(range.map { Int32($0) })
            }
            data.julianDays = data.julianDays.union(days)
            new.forEach { (entity) in
                let uniqueId = entity.getInstanceQuadrupleString()
                data.instanceEntityMap[uniqueId] = entity
            }
            data.version += 1
            data.timeZoneId = timeZoneId
            Self.logger.info("cache update \(String(describing: days)) version: \(data.version)")
            self?.delegate?.cacheChanged(instance: data.getInstances(), timeZoneId: data.timeZoneId)
        }
    }

    // 通过EventUniqueField删除instance
    func deleteInstances(with deleteEvent: [CalendarEventUniqueField], timeZoneId: TimeZoneId) {
        guard !deleteEvent.isEmpty else { return }

        Self.logger.info("delete with \(deleteEvent.map { $0.getInstanceTripleString() }))")
        let tripleStringArr = deleteEvent.map { (eventUniqueField) -> String in
            return eventUniqueField.getInstanceTripleString()
        }
        self.cachedData.safeWrite { [weak self] (data) in
            guard timeZoneId == data.timeZoneId else {
                Self.logger.error("time zone not match \(data.timeZoneId) \(timeZoneId)")
                return
            }

            data.instanceEntityMap = data.instanceEntityMap.filter { (_, instance) -> Bool in
                return !tripleStringArr.contains(instance.getInstanceTripleString())
            }
            data.version += 1
            Self.logger.info("delete with \(deleteEvent.map { $0.getInstanceTripleString() }) version: \(data.version))")
            self?.delegate?.cacheChanged(instance: data.getInstances(), timeZoneId: data.timeZoneId)
        }
    }

    // 删除julianday对应的instance
    func deleteInstances(with range: JulianDayRange, timeZoneId: TimeZoneId) {
        let days = Set(range.map { Int32($0) })

        self.cachedData.safeWrite { [weak self] (data) in
            guard timeZoneId == data.timeZoneId else {
                Self.logger.error("time zone not match \(data.timeZoneId) \(timeZoneId)")
                return
            }
            data.instanceEntityMap = data.instanceEntityMap.filter { (_, instance) -> Bool in
                return instance.getInstanceDays().isDisjoint(with: days)
            }
            data.version += 1
            Self.logger.info("clean with \(days) version: \(data.version)")
            self?.delegate?.cacheChanged(instance: data.getInstances(), timeZoneId: data.timeZoneId)
        }
    }

    func update(with timeZoneId: TimeZoneId) {
        Self.logger.info("timeZone change \(timeZoneId)")
        self.clean()
    }

    // 清理缓存
    func clean() {
        cachedData.safeWrite { [weak self] (data) in
            data.instanceEntityMap.removeAll()
            data.julianDays.removeAll()
            data.timeZoneId = TimeZone.current.identifier
            data.version += 1
            Self.logger.info("clean version: \(data.version)")
            self?.delegate?.cacheChanged(instance: data.getInstances(), timeZoneId: data.timeZoneId)
        }
    }

    private func filter(with instances: [CalendarEventInstanceEntity], in range: JulianDayRange) -> [CalendarEventInstanceEntity] {
        let julianDays = Set(range.map { Int32($0) })
        return instances.filter { (instance) -> Bool in
            // 过滤掉instance所在日期与所取日期没有交集的instance && 过滤掉不可见的calendar
            return !instance.getInstanceDays().isDisjoint(with: julianDays)
        }.sortedByServerId()
    }

}

extension Array where Element == CalendarEventInstanceEntity {
    fileprivate func sortedByServerId() -> [CalendarEventInstanceEntity] {
        return self.sorted { (left, right) -> Bool in
            let leftID = Int(left.eventServerId) ?? 0
            let rightID = Int(right.eventServerId) ?? 0
            return leftID > rightID
        }
    }
}
