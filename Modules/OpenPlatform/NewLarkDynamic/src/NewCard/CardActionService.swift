//
//  CardActionService.swift
//  LarkOpenPlatform
//
//  Created by lilun.ios on 2021/12/16.
//

import Foundation

public final class CardAction {
    public let key: String
    public let tagID: String
    public let createTime: Date
    public let actionID: String
    public init(key: String, tagID: String, actionID: String) {
        self.key = key
        self.tagID = tagID
        self.actionID = actionID
        self.createTime = Date()
    }
}


public final class ActionObserver: NSObject {
    public let key: String
    public var actionStatusChange: (() -> Void)?
    public var cardAction: CardAction?
    
    public var actionNotFinish: Bool {
        return cardAction != nil
    }
    
    public init(key: String) {
        self.key = key
        self.actionStatusChange = nil
        self.cardAction = nil
    }
    
    deinit {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    public func observeAction(action: CardAction) -> Bool {
        /// 每次只能记录一次Action
        guard cardAction == nil else {
            return false
        }
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        cardAction = action
        DispatchQueue.main.async {
            self.actionStatusChange?()
            let _ = self.perform(#selector(self.timeout),
                                 with: nil,
                                 afterDelay: 10)
        }
        return true
    }
    
    public func removeAction() {
        guard cardAction != nil else {
            return
        }
        cardAction = nil
        DispatchQueue.main.async {
            self.actionStatusChange?()
        }
    }
    
    @objc
    private func timeout() {
        removeAction()
    }
}

public protocol ActionService {
    /// 获取保存对应消息的交互观察者
    func getCardActionObserver(key: String) -> ActionObserver
}

public final class ActionServiceImpl: ActionService {
    var observers: [String: ActionObserver] = [:]
    let lock = NSLock()
    
    public init() {
        
    }
    
    public func getCardActionObserver(key: String) -> ActionObserver {
        lock.lock()
        defer {
            lock.unlock()
        }
        guard let observer = observers[key] else {
            let observer = ActionObserver(key: key)
            observers[key] = observer
            return observer
        }
        return observer
    }
}
