//
//  MinutesRecordStoppedTaskStateHandle.swift
//  MinutesFoundation
//
//  Created by ByteDance on 2023/11/29.
//

import Foundation
import LarkStorage

public class MinutesRecordStoppedTaskStateHandle {
    let keyStoppedMinutes = "keyStoppedMinutes"
    let store = KVStores.udkv(
        space: .global,
        domain: Domain.biz.minutes
    )

    public init() {}

    public func checkMinutesIsStopped(with token: String?) -> Bool {
        guard let token = token else { return false }
        if let array: [String] = store.value(forKey: keyStoppedMinutes) {
            return array.contains(token)
        } else {
            return false
        }
    }

    public func markStoppedMinutes(with token: String?) {
        guard let token = token else { return }
        if var array: [String] = store.value(forKey: keyStoppedMinutes) {
            array.append(token)
            self.store.set(array, forKey: keyStoppedMinutes)
            MinutesLogger.upload.info("markStoppedMinutes: \(token), count: \(array.count)")
        } else {
            self.store.set([token], forKey: keyStoppedMinutes)
            MinutesLogger.upload.info("markStoppedMinutes: \(token), count: 1")
        }
        self.store.synchronize()
    }

    public func removeStoppedMinutes(with token: String?) {
        guard let token = token else { return }
        guard let array: [String] = store.value(forKey: keyStoppedMinutes) else { return }
        guard array.contains(token) else { return }
        let newArray = array.filter { $0 != token }
        self.store.set(newArray, forKey: keyStoppedMinutes)
        self.store.synchronize()

        MinutesLogger.upload.info("removeStoppedMinutes: \(token), new count: \(newArray.count)")
    }

    public func cleanStoppedMinutes() {
        guard let array: [String] = store.value(forKey: keyStoppedMinutes) else { return }
        if array.isEmpty == false {
            MinutesLogger.upload.info("cleanStoppedMinutes, \(array.count)")
            let empties: [String] = []
            self.store.set(empties, forKey: keyStoppedMinutes)
            self.store.synchronize()
        }
    }
}
