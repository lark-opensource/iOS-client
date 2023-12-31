//
//  HowlingDatabase.swift
//  ByteView
//
//  Created by wulv on 2021/8/12.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

final class HowlingDatabase {
    typealias DBDate = TimeInterval
    typealias DBCount = UInt

    let storage: UserStorage
    init(storage: UserStorage) {
        self.storage = storage
    }

    private let dbIgnoreDateKey = "firstIgnoreDate"
    private let dbIgnoreCountKey = "totalIgnoreCount"
    private let dbNoWarnDateKey = "firstNoWarnDate"

    func firstIgnoreDate() -> DBDate? {
        guard let dict = localDict() else { return nil }
        guard dict.keys.contains(dbIgnoreDateKey),
              let date = dict[dbIgnoreDateKey] as? DBDate else { return nil }
        return date
    }

    func updateFirstIgnoreDate(_ date: DBDate) {
        guard var local = localDict() else {
            saveLocalDict([dbIgnoreDateKey: date])
            return
        }

        if let localDate = local[dbIgnoreDateKey] as? DBDate,
           localDate == date { return }
        local[dbIgnoreDateKey] = date
        saveLocalDict(local)
    }

    func totalIgnoreCount() -> DBCount? {
        guard let dict = localDict(isDate: false) else { return nil }
        guard dict.keys.contains(dbIgnoreCountKey),
              let count = dict[dbIgnoreCountKey] as? DBCount else { return nil }
        return count
    }

    func updateTotalIgnoreCount(_ count: DBCount) {
        guard var local = localDict(isDate: false) else {
            saveLocalDict([dbIgnoreCountKey: count], isDate: false)
            return
        }

        if let localCount = local[dbIgnoreCountKey] as? DBCount,
           localCount == count { return }
        local[dbIgnoreCountKey] = count
        saveLocalDict(local, isDate: false)
    }

    func firstNoWarnDate() -> DBDate? {
        guard let dict = localDict() else { return nil }

        guard dict.keys.contains(dbNoWarnDateKey),
              let date = dict[dbNoWarnDateKey] as? DBDate else { return nil }
        return date
    }

    func updateFirstNoWarnDate(_ date: DBDate) {
        guard var local = localDict() else {
            saveLocalDict([dbNoWarnDateKey: date])
            return
        }

        if let localDate = local[dbNoWarnDateKey] as? DBDate,
           localDate == date { return }
        local[dbNoWarnDateKey] = date
        saveLocalDict(local)
    }

    func localDict(isDate: Bool = true) -> [String: Any]? {
        if isDate {
            guard let dict: [String: DBDate] = storage.value(forKey: .howlingDate) else { return nil }
            Logger.howling.info("local DBDate data = \(dict)")
            return dict
        } else {
            guard let dict: [String: DBCount] = storage.value(forKey: .howlingCount) else { return nil }
            Logger.howling.info("local DBCount data = \(dict)")
            return dict
        }
    }

    func saveLocalDict(_ dict: [String: Any]?, isDate: Bool = true) {
        var new: [String: Any]?
        if let dict = dict {
            if var local = localDict(isDate: isDate) {
                dict.forEach { (k: String, v: Any) in local[k] = v }
                new = local
            } else {
                new = dict
            }
        } else {
            new = nil
        }

        if let data = new as? [String: DBDate] {
            storage.setValue(data, forKey: .howlingDate)
        }
        if let data = new as? [String: DBCount] {
            storage.setValue(data, forKey: .howlingCount)
        }
    }
}

extension HowlingDatabase {
    func clearAll() {
        saveLocalDict(nil)
    }
}
