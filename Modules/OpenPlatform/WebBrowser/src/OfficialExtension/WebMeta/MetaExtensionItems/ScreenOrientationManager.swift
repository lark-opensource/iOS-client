//
//  ScreenOrientationManager.swift
//  WebBrowser
//
//  Created by luogantong on 2022/4/6.
//

import OPFoundation
import CoreMotion
import UIKit
import LKCommonsLogging

protocol ScreenOrientationManagerProtocol: AnyObject {
    func motionSensorUpdatesOrientation(to: UIInterfaceOrientation)
}
private let logger = Logger.oplog(ScreenOrientationManager.self, category: "ScreenOrientationManager")
class ScreenOrientationManager {
    var deviceOrientation : UIInterfaceOrientation = UIApplication.shared.statusBarOrientation

    private var coreMotionManager : CMMotionManager = {
        let manager = CMMotionManager()
        manager.deviceMotionUpdateInterval = 1
        return manager
    }()

    private lazy var operationQueue : OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    weak var delegate : ScreenOrientationManagerProtocol?

    init(delegate: ScreenOrientationManagerProtocol) {
        self.delegate = delegate
    }

    func startDeviceMotionObserver(){
        addMotionObserver()
    }

    func stopDeviceMotionObserver() {
        removeMotionObserver()
    }

    private func addMotionObserver() {
        if coreMotionManager.isDeviceMotionActive {
            return
        }
        // 监听传感器状态
        if let deviceMotion = coreMotionManager.deviceMotion {
            deviceOrientation = getCurrentOrientation(deviceMotion.gravity)
        }
        self.internalStartMonitor()
    }

    private func removeMotionObserver(){
        coreMotionManager.stopDeviceMotionUpdates()
    }

    private func internalStartMonitor() {
        do {
            try OPSensitivityEntry.startDeviceMotionUpdates(forToken: .webBrowserScreenOrientationManagerInternalStartMonitor, manager: coreMotionManager, to: operationQueue, withHandler: { [weak self] (motions, _) in
                guard let motion = motions else {
                    return
                }
                DispatchQueue.main.async { [weak self] in
                    self?.gravityDidChanged(motion.gravity)
                }
            })
        } catch {
            logger.error("startDeviceMotionUpdates throw error: \(error)")
        }
    }

    // 传感器发生变化时的处理
    private func gravityDidChanged(_ gravity: CMAcceleration) {
        let currentOrientation = getCurrentOrientation(gravity)
        if currentOrientation != deviceOrientation {
            deviceOrientation = currentOrientation
        }
        delegate?.motionSensorUpdatesOrientation(to: currentOrientation)
    }

    private func getCurrentOrientation(_ gravity: CMAcceleration) -> UIInterfaceOrientation {
        // 旋转偏离角度灵敏度
        let threshold: Double = 0.6
        let gravityX = gravity.x
        let gravityY = gravity.y
        var currentOrientation = deviceOrientation
        if gravityX <= -threshold && abs(gravityY) < 1 - threshold {
            currentOrientation = .landscapeRight
        }
        if gravityX >= threshold && abs(gravityY) < 1 - threshold {
            currentOrientation = .landscapeLeft
        }
        if gravityY <= -threshold && abs(gravityX) < 1 - threshold {
            currentOrientation = .portrait
        }
        if gravityY >= threshold && abs(gravityX) < 1 - threshold {
            currentOrientation = .portraitUpsideDown
        }
        return currentOrientation
    }
}
