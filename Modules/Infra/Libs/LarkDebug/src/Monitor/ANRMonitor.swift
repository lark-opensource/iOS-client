//
//  ANRMonitor.swift
//  Lark
//
//  Created by Yuguo on 2017/6/4.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
#if DEBUG

extension NSObject: ANREyeDelegate {
    private struct AssociatedKeys {
        static let anrEyeKey = "anrKey"
    }

    fileprivate var anrEye: ANREye? {
        get {
            return objc_getAssociatedObject(self, AssociatedKeys.anrEyeKey) as? ANREye
        }

        set {
            objc_setAssociatedObject(self, AssociatedKeys.anrEyeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public func openANRMonitor(with threshold: Double = 2) {
        anrEye = ANREye()
        anrEye?.delegate = self
        anrEye?.open(with: threshold)
    }

    public func closeANRMonitor() {
        anrEye?.close()
    }

    public func anrEye(anrEye: ANREye, catchWithThreshold threshold: Double) {
//        assertionFailure("在主线程中阻塞时间超过 \(threshold) 秒，请根据左边的调用堆栈信息查明原因解决")
    }
}

// --------------------------------------------------------------------------
// MARK: - ANREyeDelegate
// --------------------------------------------------------------------------
@objc public protocol ANREyeDelegate: AnyObject {
    @objc
    func anrEye(anrEye: ANREye, catchWithThreshold threshold: Double)
}

// --------------------------------------------------------------------------
// MARK: - ANREye
// --------------------------------------------------------------------------
open class ANREye: NSObject {
    // --------------------------------------------------------------------------
    // MARK: OPEN PROPERTY
    // --------------------------------------------------------------------------
    open weak var delegate: ANREyeDelegate?

    public var isOpening: Bool {
        guard let pingThread = self.pingThread else {
            return false
        }

        return !pingThread.isCancelled
    }

    // --------------------------------------------------------------------------
    // MARK: OPEN FUNCTION
    // --------------------------------------------------------------------------
    public func open(with threshold: Double) {
        self.pingThread = AppPingThread()
        self.pingThread?.name = "AppPingThread"
        self.pingThread?.start(threshold: threshold, handler: { [weak self] in
            guard let sself = self else {
                return
            }

            sself.delegate?.anrEye(anrEye: sself, catchWithThreshold: threshold)
        })
    }

    public func close() {
        self.pingThread?.cancel()
    }

    // --------------------------------------------------------------------------
    // MARK: LIFE CYCLE
    // --------------------------------------------------------------------------
    deinit {
        self.pingThread?.cancel()
    }

    // --------------------------------------------------------------------------
    // MARK: PRIVATE PROPERTY
    // --------------------------------------------------------------------------
    private var pingThread: AppPingThread?
}

// --------------------------------------------------------------------------
// MARK: - GLOBAL DEFINE
// --------------------------------------------------------------------------
public typealias AppPingThreadCallBack = () -> Void

// --------------------------------------------------------------------------
// MARK: - AppPingThread
// --------------------------------------------------------------------------
private final class AppPingThread: Thread {
    func start(threshold: Double, handler: @escaping AppPingThreadCallBack) {
        self.handler = handler
        self.threshold = threshold
        self.start()
    }

    override func main() {
        while self.isCancelled == false {
            self.isMainThreadBlock = true

            DispatchQueue.main.async {
                self.isMainThreadBlock = false
                self.semaphore.signal()
            }

            Thread.sleep(forTimeInterval: self.threshold)

            if self.isMainThreadBlock {
                self.handler?()
            }

            _ = self.semaphore.wait(timeout: DispatchTime.distantFuture)
        }
    }

    private let semaphore = DispatchSemaphore(value: 0)

    private var isMainThreadBlock = false

    private var threshold: Double = 0.4

    fileprivate var handler: (() -> Void)?
}

#endif
