//
//  OperatorCounter.swift
//  LarkChat
//
//  Created by zc09v on 2020/5/8.
//

import Foundation
import UIKit
import LKCommonsLogging
import RxSwift

//用于维护不同场景(业务)对同一状态的操作
public final class OperatorCounter {
    static let logger = Logger.log(OperatorCounter.self, category: "lark.OperatorCounter")

    //是否还有操作者
    public var hasOperator: Bool {
        self.threadSafe {
            return _hasOperator
        }
    }

    private var _hasOperator: Bool = false {
        willSet {
            if _hasOperator != newValue {
                hasOperatorSubject.onNext(newValue)
            }
        }
    }

    private let hasOperatorSubject: ReplaySubject<Bool> = ReplaySubject<Bool>.create(bufferSize: 1)

    public var hasOperatorObservable: Observable<Bool> {
        return hasOperatorSubject.asObserver()
    }

    private(set) var operatorCountMap: [String: Int] = [:]
    private var lock: NSRecursiveLock = NSRecursiveLock()
    private let threadSafe: Bool

    //是否需要保证线程安全
    public init(threadSafe: Bool = false) {
        self.threadSafe = threadSafe
    }

    //增加操作计数，category: 区分不同场景
    public func increase(category: String, hasOperator: (() -> Void)? = nil) {
        self.threadSafe {
            let operatorCount = (operatorCountMap[category] ?? 0) + 1
            OperatorCounter.logger.info("OperatorCounter trace increase  \(category) \(operatorCount)")
            operatorCountMap[category] = operatorCount
            if !self._hasOperator {
                self._hasOperator = true
                OperatorCounter.logger.info("OperatorCounter trace do hasOperator \(category) \(operatorCount)")
                hasOperator?()
            }
        }
    }

    //减少操作计数，category: 区分不同场景
    public func decrease(category: String, noneOperator: (() -> Void)? = nil) {
        self.threadSafe {
            var operatorCount = (operatorCountMap[category] ?? 0) - 1
            OperatorCounter.logger.info("OperatorCounter trace decrease \(category) \(operatorCount)")
            if operatorCount < 0 {
                operatorCount = 0
            }
            operatorCountMap[category] = operatorCount
            var hasOperator = false
            for v in self.operatorCountMap where v.value != 0 {
                hasOperator = true
                OperatorCounter.logger.info("OperatorCounter trace holdOperator by \(v.key) \(v.value)")
                break
            }
            if !hasOperator, self._hasOperator != hasOperator {
                OperatorCounter.logger.info("OperatorCounter trace do noneOperator \(category) \(operatorCount)")
                self._hasOperator = hasOperator
                noneOperator?()
            }
        }
    }

    private func threadSafe<R>(perform: () -> R) -> R {
        if threadSafe {
            lock.lock()
        }
        defer {
            if threadSafe {
                lock.unlock()
            }
        }
        return perform()
    }
}
