//
//  MetaLoadStatus.swift
//  TTMicroApp
//
//  Created by dengbo on 2022/3/23.
//

import Foundation
import LKCommonsLogging
import OPSDK

extension Notification.Name {
    public static let MetaLoadStatusNotification = Notification.Name(rawValue: "gadget.meta.load.status")
}

@objc
public enum MetaLoadStatus: Int, CustomStringConvertible {
    case started
    case success
    case fail
    
    public var description: String {
        switch self{
             case .started: return "started"
             case .success: return "success"
             case .fail:    return "fail"
        }
    }
}

public extension MetaLoadStatus {
    static let metaLoadStatusKey = "MetaLoadStatus.status"
    static let metaLoadIdentifierKey = "MetaLoadStatus.identifier"
}

@objc public protocol MetaLoadStatusDelegate {
    func loadStatusDidChange(status: MetaLoadStatus, identifier: String)
}

public protocol MetaLoadStatusListener {
    func addObserver()
}

@objcMembers
public final class MetaLoadStatusManager: NSObject, MetaLoadStatusListener {
    
    private static let logger = Logger.oplog(MetaLoadStatusManager.self, category: "MetaLoadStatusManager")
    
    public static let shared = MetaLoadStatusManager()
    
    private var delegates: [WeakObj] = []
    
    private let lock = NSLock()
    private var statusMap: [String: MetaLoadStatus] = [:]
    
    private var finishAddObserver = false
    
    public func addObserver() {
        //切换租户时会重新添加监听。添加标记避免重复监听导致回调多次
        if finishAddObserver {
            Self.logger.info("finished add observer")
            return
        }
        finishAddObserver = true
        Self.logger.info("add observer")
        NotificationCenter.default.addObserver(
            forName: Notification.Name.MetaLoadStatusNotification,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] notification in
            guard let self = self else {
                Self.logger.warn("handle notification but self is nil")
                return
            }
            self.handleNotification(notification: notification)
        }
    }
    
    private func handleNotification(notification: Notification) {
        Self.logger.info("handle notification userInfo: \(notification.userInfo ?? [:])")
        guard let userInfo = notification.userInfo,
              let status = userInfo[MetaLoadStatus.metaLoadStatusKey] as? MetaLoadStatus,
              let identifier = userInfo[MetaLoadStatus.metaLoadIdentifierKey] as? String else {
                  return
              }
        
        update(status: status, identifier: identifier)
        
        delegates = delegates.filter{ $0.value != nil }
        delegates.forEach {
            if let delegate = $0.value as? MetaLoadStatusDelegate {
                delegate.loadStatusDidChange(status: status, identifier: identifier)
            }
        }
    }
    
    private func update(status: MetaLoadStatus, identifier: String) {
        Self.logger.info("update status \(identifier), \(status)")
        lock.lock()
        defer {
            lock.unlock()
        }
        
        statusMap[identifier] = status
    }
    
    public func fetchStatus(for identifier: String) -> String? {
        Self.logger.info("fetch status \(identifier)")
        lock.lock()
        defer {
            lock.unlock()
        }
        
        guard let status = statusMap[identifier] else {
            Self.logger.warn("no status for \(identifier)")
            return nil
        }
        return status.description
    }
    
    public func add(_ delegate: MetaLoadStatusDelegate) {
        Self.logger.info("add delegate \(delegate)")
        assert(Thread.isMainThread, "must be called on main thread")
        
        let weak = WeakObj(value: delegate)
        guard !delegates.contains(weak) else {
            Self.logger.error("delegate exist")
            return
        }
        delegates.append(weak)
    }
    
    public func remove(_ delegate: MetaLoadStatusDelegate) {
        Self.logger.info("remove delegate \(delegate)")
        assert(Thread.isMainThread, "must be called on main thread")
        
        if let index = delegates.firstIndex(where: { (weakObj) -> Bool in
            if let value = weakObj.value, value === delegate {
                return true
            }
            return false
        }) {
            delegates.remove(at: index)
        }
    }
}

class WeakObj: Equatable {
    weak var value: AnyObject?
    init(value: AnyObject) {
        self.value = value
    }
    static func ==(lhs: WeakObj, rhs: WeakObj) -> Bool {
        if let lvalue = lhs.value, let rvalue = rhs.value, lvalue === rvalue {
            return true
        }
        return false
    }
}
