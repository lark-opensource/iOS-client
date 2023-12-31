//
//  DocGlobalTimer.swift
//  SpaceKit
//
//  Created by maxiao on 2019/10/16.
//  Copyright © 2019年 Bytedance.Inc. All rights reserved.
//

import SKFoundation
import SKInfra

protocol DocGlobalTimerFacade: AnyObject {

    func add<T: DocTimerObserverProtocol>(observer: T)

    func remove<T: DocTimerObserverProtocol>(observer: T)
}

public final class DocGlobalTimer {
    
    struct WeakWrapper {
        weak var value: DocTimerObserverProtocol?
    }

    public static let shared = DocGlobalTimer()

    private init() {}

    private var timer: Timer?

    private let defaultTimeInterval: TimeInterval = 30.0

    private var secondsCounter: [String: (Int, Int)] = [:] // (定时间隔、上次触发事件）

    
    private var observers: [String: WeakWrapper] = [:]

    @objc
    private func tiktok() {

        DocsLogger.info("tiktok====\(Date())")
        let obs = observers.compactMap { $1.value }
        guard !obs.isEmpty else {
            DocsLogger.info("tiktok====调用了tikitok，但是无ob，停止定时功能！")
            secondsCounter.removeAll()
            timer?.invalidate()
            timer = nil
            return
        }

        obs.forEach {

            let obKey = "\(ObjectIdentifier($0))"

            guard let countInfo = secondsCounter[obKey] else {
                return
            }

            let currentTime = Int(Date().timeIntervalSince1970)

            if (currentTime - countInfo.1) % countInfo.0 == 0 || countInfo.1 == 0 {
                $0.tiktok()
                secondsCounter[obKey] = (countInfo.0, currentTime)
            }

            secondsCounter = secondsCounter.filter { (key, _) in
                return observers[key] != nil
            }
        }
        DocsLogger.info("tiktok====seconsCounter keys 还有 \(secondsCounter.keys.count) 个")
    }

    public func pause() {
        DocsLogger.info("tiktok====暂停所有的定时业务，当前还有 \(secondsCounter.keys.count) 个")
        timer?.invalidate()
        timer = nil
    }

    public func resume() {
        DocsLogger.info("tiktok====继续所有的定时业务，当前还有 \(secondsCounter.keys.count) 个")
        secondsCounter = secondsCounter.mapValues { value -> (Int, Int) in
            return (value.0, 0)
        }
        timer = Timer(timeInterval: defaultTimeInterval,
                      target: self,
                      selector: #selector(tiktok),
                      userInfo: nil,
                      repeats: true)
        RunLoop.main.add(timer!, forMode: .common)
    }
}

extension DocGlobalTimer: DocGlobalTimerFacade {
    func add<T: DocTimerObserverProtocol>(observer: T) {
        synchronized(self) {
            guard Int(observer.timeInterval) % Int(defaultTimeInterval) == 0, observer.timeInterval > 0 else {
                assertionFailure("❌ 定时间隔必须为默认秒的整数倍！")
                return
            }

            let obIdentifier = "\(ObjectIdentifier(observer))"

            if observers[obIdentifier] != nil {
                return
            }

            observers[obIdentifier] = WeakWrapper(value: observer)
            secondsCounter[obIdentifier] = (Int(observer.timeInterval), 0)

            if timer != nil { return }

            timer = Timer(timeInterval: defaultTimeInterval,
                          target: self,
                          selector: #selector(tiktok),
                          userInfo: nil,
                          repeats: true)
            RunLoop.main.add(timer!, forMode: .common)
        }
    }

    func remove<T: DocTimerObserverProtocol>(observer: T) {
        synchronized(self) {
            let obIdentifier = "\(ObjectIdentifier(observer))"

            guard observers[obIdentifier] != nil else {
                assertionFailure("❌ 移除的Observer不存在！")
                return
            }
            observers.removeValue(forKey: obIdentifier)
        }
    }
}
