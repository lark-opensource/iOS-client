//
//  LarkBackgroundTaskMonitor.swift
//  Action
//
//  Created by KT on 2019/7/17.
//

import UIKit
import Foundation
import LKCommonsLogging
import RxSwift
import RxCocoa

private let logger = Logger.log(UIApplication.self)

// MARK: - 后台任务启动和结束写入日志
extension UIApplication {
    @objc
    static func swizzleMethod() {
        let originalSelector = #selector(beginBackgroundTask(expirationHandler:))
        let swizzledSelector = #selector(lark_beginBackgroundTask(expirationHandler:))
        swizzling(
            forClass: UIApplication.self,
            originalSelector: originalSelector,
            swizzledSelector: swizzledSelector
        )

        let originalSelector1 = #selector(beginBackgroundTask(withName:expirationHandler:))
        let swizzledSelector1 = #selector(lark_beginBackgroundTask(withName:expirationHandler:))
        swizzling(
            forClass: UIApplication.self,
            originalSelector: originalSelector1,
            swizzledSelector: swizzledSelector1
        )

        let originalSelector2 = #selector(endBackgroundTask(_:))
        let swizzledSelector2 = #selector(lark_endBackgroundTask(_:))
        swizzling(
            forClass: UIApplication.self,
            originalSelector: originalSelector2,
            swizzledSelector: swizzledSelector2
        )
    }

    @objc
    func lark_beginBackgroundTask(expirationHandler handler: (() -> Void)? = nil) -> UIBackgroundTaskIdentifier {
        let identify = lark_beginBackgroundTask(expirationHandler: handler)
        LarkBackgroundTaskMonitor.shared.addBackgroundTask(identify: identify)
        return identify
    }

    @objc
    func lark_beginBackgroundTask(
        withName taskName: String?,
        expirationHandler handler: (() -> Void)? = nil) -> UIBackgroundTaskIdentifier {
        let identify = lark_beginBackgroundTask(withName: taskName, expirationHandler: handler)
        LarkBackgroundTaskMonitor.shared.addBackgroundTask(identify: identify, name: taskName)
        return identify
    }

    @objc
    func lark_endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        lark_endBackgroundTask(identifier)
        LarkBackgroundTaskMonitor.shared.endBackgroundTask(identify: identifier)
    }
}

// MARK: - swizzling
public func swizzling(
    forClass: AnyClass,
    originalSelector: Selector,
    swizzledSelector: Selector) {

    guard let originalMethod = class_getInstanceMethod(forClass, originalSelector),
        let swizzledMethod = class_getInstanceMethod(forClass, swizzledSelector) else {
            return
    }
    if class_addMethod(
        forClass,
        originalSelector,
        method_getImplementation(swizzledMethod),
        method_getTypeEncoding(swizzledMethod)
        ) {
        class_replaceMethod(
            forClass,
            swizzledSelector,
            method_getImplementation(originalMethod),
            method_getTypeEncoding(originalMethod)
        )
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

final class LarkBackgroundTaskMonitor {
    static let shared = LarkBackgroundTaskMonitor()
    private let disposeBag = DisposeBag()
    private let timeOut: TimeInterval = 10.0

    private lazy var queue: DispatchQueue = {
        return DispatchQueue(label: "LarkBackgroundTaskMonitor", qos: .utility)
    }()
    private lazy var queueScheduler: SchedulerType = {
        return SerialDispatchQueueScheduler(
            queue: queue,
            internalSerialQueueName: queue.label)
    }()

    private init() {
        NotificationCenter.default.rx
            .notification(UIApplication.willEnterForegroundNotification)
            .observeOn(queueScheduler)
            .subscribe(onNext: { [weak self] (_) in
                self?.currentActivityTasks = [:]
                self?.lastItem?.cancel()
            })
            .disposed(by: disposeBag)

        NotificationCenter.default.rx
            .notification(UIApplication.didEnterBackgroundNotification)
            .observeOn(queueScheduler)
            .subscribe(onNext: { [weak self] (_) in
                self?.checkTimeOut()
            })
            .disposed(by: disposeBag)
    }

    private var currentActivityTasks: [UIBackgroundTaskIdentifier: String] = [:]
    func addBackgroundTask(identify: UIBackgroundTaskIdentifier, name: String? = "none") {
        self.queue.async {
            self.currentActivityTasks[identify] = name
        }
    }

    func endBackgroundTask(identify: UIBackgroundTaskIdentifier) {
        self.queue.async {
            self.currentActivityTasks.removeValue(forKey: identify)
        }
    }

    private var lastItem: DispatchWorkItem?
    private func checkTimeOut() {
        lastItem?.cancel()
        lastItem = DispatchWorkItem { [weak self] in
            guard let self = self, !self.currentActivityTasks.isEmpty else { return }
            self.reportError()
        }
        guard let task = lastItem else { return }
        queue.asyncAfter(deadline: .now() + timeOut, execute: task)
    }

    private func reportError() {
        let tasks = self.currentActivityTasks.values.joined(separator: "|")
        logger.error("BackgroundTask Touch TimeOut: \(timeOut)s, with Tasks: \(tasks)")
    }
}
