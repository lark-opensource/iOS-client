//
//  FeatureGatingSyncEvent.swift
//  LarkSetting
//
//  Created by ByteDance on 2023/12/20.
//

import Foundation
import LKCommonsTracker


public enum FeatureGatingSyncScene: Int  {
    case notSyncUpdate = 0
    case firstLogin
    case upgradeVersion
}

public class FeatureGatingSyncEventCollector {

    public static let shared = FeatureGatingSyncEventCollector()

    let queue = DispatchQueue(label: "larkSetting.fg.syncEvent")

    var userCollectors: [String: UserFeatureGatingSyncEventCollector] = [:]

    class UserFeatureGatingSyncEventCollector {
        var syncScene: FeatureGatingSyncScene = .notSyncUpdate
        var isSuccess: Bool = false
        var cost: Int = 0
        var addKeys: String = ""
        var removeKeys: String = ""

        func syncScene(_ scene: FeatureGatingSyncScene) {
            self.syncScene = scene
        }

        func syncResult(_ isSuccess: Bool) {
            self.isSuccess = isSuccess
        }

        func syncCost(_ cost: TimeInterval) {
            self.cost = Int(cost)
        }

        func calculateDiff(old: Set<String>, new: Set<String>) {
            guard self.syncScene != .notSyncUpdate, self.cost != 0 else { return }
            let addedKeys = new.subtracting(old)
            let removedKeys = old.subtracting(new)
            self.addKeys = addedKeys.joined(separator: ",")
            self.removeKeys = removedKeys.joined(separator: ",")
        }

        func reportEvent() {
            guard self.syncScene != .notSyncUpdate, self.cost != 0 else { return }
            Tracker.post(
                TeaEvent("fg_sync_update", params: ["sync_cost": self.cost, "update_success": self.isSuccess, "scene": self.syncScene.rawValue, "add_keys": self.addKeys, "remove_keys": self.removeKeys])
            )
        }
    }

    private func getOrCreateCollector(for userID: String) -> UserFeatureGatingSyncEventCollector {
        if let collector = userCollectors[userID] {
            return collector
        }else {
            let newCollector = UserFeatureGatingSyncEventCollector()
            userCollectors[userID] = newCollector
            return newCollector
        }
    }

    private func removeCollector(for userID: String) {
        self.userCollectors.removeValue(forKey: userID)
    }

    public func syncScene(_ userID: String, _ scene: FeatureGatingSyncScene) {
        self.queue.async {
            let collector = self.getOrCreateCollector(for: userID)
            collector.syncScene(scene)
        }
    }

    public func syncResult(_ userID: String, _ isSuccess: Bool) {
        self.queue.async {
            let collector = self.getOrCreateCollector(for: userID)
            collector.syncResult(isSuccess)
            collector.reportEvent()
            self.removeCollector(for: userID)
        }
    }

    public func syncCost(_ userID: String, _ cost: TimeInterval) {
        self.queue.async {
            let collector = self.getOrCreateCollector(for: userID)
            collector.syncCost(cost)
        }
    }

    public func calculateDiff(for userID: String, old: Set<String>, new: Set<String>) {
        self.queue.async {
            let collector = self.getOrCreateCollector(for: userID)
            collector.calculateDiff(old: old, new: new)
        }
    }
}
