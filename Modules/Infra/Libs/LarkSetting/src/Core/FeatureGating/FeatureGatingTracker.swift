//
//  FeatureGatingTracker.swift
//  LarkSetting
//
//  Created by 王元洵 on 2022/9/15.
//

import Foundation
import LKCommonsTracker
import Homeric
import LarkStorage

enum FeatureGatingTracker {
    private static let serialQueue = DispatchQueue(label: "FeatureGatingTracker", qos: .background)
    private static let currentVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

    private static var userTrackers = [String: UserTracker]()
    @KVConfig(key: "cacheVersion", default: "", store: KVStores.FG.global)
    private static var cacheVersion

    private class UserTracker {
        private static let secondPerHour = TimeInterval(3600)
        private static let defaultCapacity = 200

        private let store: KVStore
        private let id: String

        private lazy var lastTrackTime = lastTrackTimeCache
        private lazy var data = dataCache

        @KVBinding(to: \UserTracker.store, key: "lastTrackTime", default: Date())
        private var lastTrackTimeCache
        @KVBinding(to: \UserTracker.store, key: "userFGData", default: [String: [String: String]]())
        private var dataCache

        init(userID: String) {
            id = userID
            store = KVStores.FG.user(id: id)
        }

        func insert(key: String, clientValue: String, serverValue: String, type: String) {
            let synthesisKey = key + clientValue + serverValue + type
            data[synthesisKey] = ["fg_key": key, "fg_value_client": clientValue, "fg_value_server": serverValue,
                                  "fg_Interface_type": type, "pv": String((Int(data[synthesisKey]?["pv"] ?? "0") ?? 0) + 1)]
            if -lastTrackTime.timeIntervalSinceNow > Self.secondPerHour { track() }
        }

        func track() {
            let limit = (try? SettingStorage.setting(with: id, and: "fg_use_config") as? [String: Int])?["fg_keys_capacity"]
            ?? Self.defaultCapacity
            let trackData = Array(data.values)
            stride(from: 0, to: trackData.count, by: limit).forEach { Tracker.post(TeaEvent(Homeric.FG_USE_CLIENT, params: ["fg_params": Array(trackData[$0..<($0 + limit >= trackData.count ? trackData.count : $0 + limit)])])) }
            data = [:]
            lastTrackTime = Date()
        }

        func sync() {
            lastTrackTimeCache = lastTrackTime
            dataCache = data
        }
    }
}

// MARK: internal interfaces
extension FeatureGatingTracker {
    static func record(key: String, value: Bool, serverValue: Bool, userID: String, type: FeatureGatingType) {
        serialQueue.async {
            guard !userID.isEmpty else { return }
            let tracker: UserTracker
            if let v = userTrackers[userID] {
                tracker = v
            } else {
                tracker = .init(userID: userID)
                userTrackers[userID] = tracker
            }
            tracker.insert(key: key,
                           clientValue: value ? "1" : "0",
                           serverValue: serverValue ? "1" : "0",
                           type: type == .dynamic ? "1" : "0")
        }
    }

    static func trackAndSyncIfNeeded(with userID: String) {
        serialQueue.async {
            cacheVersion.isEmpty ? userTrackers[userID]?.track() : cacheVersion != currentVersion ? userTrackers = [:] : nil
            cacheVersion = currentVersion
        }
    }

    static func syncCache() { serialQueue.async { userTrackers.values.forEach { $0.sync() } } }
}
