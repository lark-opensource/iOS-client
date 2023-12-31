//
//  MailStateManager.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/8/5.
//

import Foundation
import LKCommonsLogging

public protocol MailStateObserver {
    /// 第一次进入Email tab只会回调这个方法
    func didMailServiceFirstEntry()

    func didLeaveMailService()

    func didEnterMailService()
}

fileprivate protocol CounterWrapperDelegate: AnyObject {
    func didCounterSet(oldValue: Int, counter: Int)
}

fileprivate class CounterWrapper {
    weak var delegate: CounterWrapperDelegate?

    // 初始化值为-1，第一次进入mailtab不需要走两次一样的逻辑。
    var counter: Int = -1 {
        didSet {
            delegate?.didCounterSet(oldValue: oldValue, counter: counter)
        }
    }
}

extension CounterWrapper: MailCleanAbleValue {
    func mailClean() {
        self.counter = -1
    }
}

public final class MailStateManager {

    public static let shared = MailStateManager()

    static let logger = Logger.log(MailStateManager.self, category: "Module.LarkMail")

    private var observersContainer: ObserverContainer<MailStateObserver> = ObserverContainer<MailStateObserver>()

    @MailAutoCleanData private var mailPageCounter: CounterWrapper = CounterWrapper()

    init() {
        self.mailPageCounter.delegate = self
    }
}

// MARK: interface
extension MailStateManager {
    public var hasEnteredMailPage: Bool {
        return mailPageCounter.counter > 0
    }

    public var isInMailPage: Bool {
        return mailPageCounter.counter > 0 || mailPageCounter.counter == -1
    }

    public func enterMailPage() {
        if mailPageCounter.counter == -1 {
            mailPageCounter.counter = 1
            return
        }
        mailPageCounter.counter = mailPageCounter.counter + 1
    }

    public func exitMailPage() {
        mailPageCounter.counter = max(0, mailPageCounter.counter - 1)
    }

    public func enterMailTab() {
        mailPageCounter.counter = 1
    }

    public func exitMailTab() {
        mailPageCounter.counter = 0
    }

    public func addObserver(_ observer: MailStateObserver) {
        observersContainer.add(observer)
    }
}

// MARK: internal
extension MailStateManager {
    func notifyEnterMailService() {
        MailStateManager.logger.info("[mail_client_sync] didEnterMailService")
        observersContainer.enumerateObjectUsing { (_, observer) in
            observer.didEnterMailService()
        }
    }

    func notifyLeaveMailService() {
        MailStateManager.logger.info("[mail_client_sync] didLeaveMailService")
        observersContainer.enumerateObjectUsing { (_, observer) in
            observer.didLeaveMailService()
        }
    }

    func notifyFirstEnterMailService() {
        MailStateManager.logger.info("[mail_client_sync] didMailServiceFirstEntry")
        observersContainer.enumerateObjectUsing { (_, observer) in
            observer.didMailServiceFirstEntry()
        }
    }
}

extension MailStateManager: CounterWrapperDelegate {
    func didCounterSet(oldValue: Int, counter: Int) {
        if oldValue == 0 && counter > 0 {
            notifyEnterMailService()
        } else if oldValue > 0 && counter == 0 {
            notifyLeaveMailService()
        } else if oldValue == -1 && counter > 0 {
            notifyFirstEnterMailService()
        }
    }
}
