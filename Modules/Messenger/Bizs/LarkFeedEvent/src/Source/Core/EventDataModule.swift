//
//  EventDataModule.swift
//  LarkFeedEvent
//
//  Created by xiaruzhen on 2022/10/18.
//

import Foundation
import LKCommonsLogging
import LarkOpenFeed

struct EventDataModule {
    private(set) var filterList: Set<String> = []
    private(set) var datas: [EventItem] = []
    private(set) var relationShip: [String: Int] = [:]

    mutating func insertOrUpdate(items: [String: EventItem]) {
        var errs: [String] = []
        items.map { id, item in
            if let index = relationShip[id] {
                if index < self.datas.count {
                    self.datas[index] = item
                } else {
                    errs.append("id: \(item.id), index: \(index), currTime: \(datas.count)")
                }
            } else {
                self.datas.append(item)
            }
        }
        sort()
        var logInfo = "eventlog/data/insertOrUpdate. totalCount: \(datas.count), \(items.map({ $1.description }))"
        if !errs.isEmpty {
            logInfo.append(", errs: \(errs)")
        }
        EventManager.log.info(logInfo)
    }

    mutating func remove(ids: [String]) {
        let list = ids.deduplicat({ $0 })
        if list.count != ids.count {
            EventManager.log.error("eventlog/data/remove/duplicat. totalCount: \(datas.count), ids: \(ids)")
        }
        let indexs = list.compactMap({ relationShip[$0] }).sorted { $0 > $1 }
        guard !indexs.isEmpty else { return }
        var errs: [Int] = []
        indexs.forEach { index in
            if index < self.datas.count {
                self.datas.remove(at: index)
            } else {
                errs.append(index)
            }
        }
        sort()
        var logInfo = "eventlog/data/remove. totalCount: \(datas.count), ids: \(ids)"
        if !errs.isEmpty {
            logInfo.append(", errs: \(errs)")
        }
        EventManager.log.info(logInfo)
    }

    mutating func fillter(items: [EventItem]) {
        items.forEach { item in
            self.filterList.insert(item.id)
        }
        EventManager.log.info("eventlog/data/fillter. \(items.map({ $0.description }))")
    }

    private mutating func sort() {
        self.datas = self.datas.sorted(by: {
            if $0.position == $1.position {
                return $0.id > $1.id
            } else {
                return $0.position > $1.position
            }
        })
        self.relationShip.removeAll()
        for i in 0..<datas.count {
            let item = datas[i]
            self.relationShip[item.id] = i
        }
    }
}

extension EventDataModule {
    var description: String {
        return "datas: \(datas.count), \(datas.map({ $0.description })), relationShip: \(relationShip.keys.count), \(relationShip), filterList: \(filterList.count), \(filterList)"
    }
}

extension Array {
    // 去重
    func deduplicat<E: Equatable>(_ filter: (Element) -> E) -> [Element] {
        var result = [Element]()
        for item in self {
            let key = filter(item)
            if !result.map({ filter($0) }).contains(key) {
                result.append(item)
            }
        }
        return result
    }
}
