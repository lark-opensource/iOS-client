//
//  PermissionChangeActionManager.swift
//  LarkSecurityAudit
//
//  Created by ByteDance on 2022/9/1.
//

import Foundation
import ThreadSafeDataStructure
import LKCommonsLogging
import LarkSecurityComplianceInfra

@objc
public protocol PermissionChangeAction: AnyObject {
    var identifier: String { get }

    func onPermissionChange()
}

struct PermissionChangeActionManager {
    private let observers = NSHashTable<PermissionChangeAction>.weakObjects()
    static let logger = Logger.log(PullPermissionService.self, category: "SecurityAudit.PermissionChangeActionManager")

    func addObserver(_ observer: PermissionChangeAction) {
        DispatchQueue.runOnMainQueue {
            guard !self.observers.contains(observer) else {
                Self.logger.error("observer_registe_failed:\(observer.identifier)")
                return
            }
            self.observers.add(observer)
            Self.logger.info("observer_registe: \(observer.identifier)")
        }
    }

    func removeObserver(_ observer: PermissionChangeAction) {
        DispatchQueue.runOnMainQueue {
            guard self.observers.contains(observer) else {
                Self.logger.error("observer_remove_failed:\(observer.identifier)")
                return
            }
            self.observers.remove(observer)
            Self.logger.info("observer_remove: \(observer.identifier)")
        }
    }

    func notify() {
        DispatchQueue.runOnMainQueue {
            let observers = observers.allObjects
            for observer in observers {
                observer.onPermissionChange()
                Self.logger.info("observer_notify: \(observer.identifier)")
            }
        }
    }
}
