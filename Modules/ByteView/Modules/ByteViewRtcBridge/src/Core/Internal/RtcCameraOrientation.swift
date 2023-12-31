//
//  OrientationKit.swift
//  ByteView
//
//  Created by chentao on 2021/2/19.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import CoreMotion
import ByteViewCommon

protocol RtcCameraOrientationDelegate: AnyObject {
    func didChangeCameraOrientation(_ orientation: UIDeviceOrientation, degree: Int)
}

final class RtcCameraOrientation {
    // 调试菜单
    static var isCoreMotionEnabled = true
    private let pullingInteval: TimeInterval = 0.1
    private lazy var opeataionQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    private lazy var coreMotionManager: CMMotionManager = {
        let coreMotionManager = CMMotionManager()
        coreMotionManager.deviceMotionUpdateInterval = pullingInteval
        coreMotionManager.accelerometerUpdateInterval = pullingInteval
        return coreMotionManager
    }()

    @RwAtomic private var deviceOrientation: UIDeviceOrientation = .unknown {
        didSet {
            if deviceOrientation != oldValue, deviceOrientation != .faceUp, deviceOrientation != .faceDown {
                interfaceDeviceOrientaion = deviceOrientation
                self.logger.info("didChangeInterfaceDeviceOrientaion to \(deviceOrientation.logDescription), by \(#function)")
            }
        }
    }

    /// 过滤`faceUp`、`faceDown`状态的`deviceOrientation`
    /// 进入`faceUp`、`faceDown`时会保持进入前的状态
    @RwAtomic private(set) var interfaceDeviceOrientaion: UIDeviceOrientation = .unknown
    @RwAtomic private(set) var statusBarOrientation: UIInterfaceOrientation = .unknown
    @RwAtomic private(set) var isInBackground: Bool = false
    weak var delegate: RtcCameraOrientationDelegate?

    let sessionId: String
    let proxy: RtcActionProxy
    let logger: Logger
    init(sessionId: String, proxy: RtcActionProxy) {
        self.sessionId = sessionId
        self.proxy = proxy
        self.logger = Logger.camera.withContext(sessionId).withTag("[RtcCameraOrientation(\(sessionId))]")
        DispatchQueue.main.async { [weak self] in
            self?.setupStatusBarOrientation()
        }
        self.fixDeviceOrientation()
    }

    deinit {
        if RtcCameraOrientation.isCoreMotionEnabled {
            logger.debug("stop monitor by deinit")
            internalStopMonitor()
        }
    }

    func startMonitor() {
        guard RtcCameraOrientation.isCoreMotionEnabled else { return }
        opeataionQueue.addOperation { [weak self] in
            guard let self = self else { return }
            self.logger.debug("start monitor and current is running:\(self.isRunning)")
            guard !self.isRunning else { return }
            self.fixDeviceOrientation()
            self.internalStartMonitor()
        }
    }

    private func internalStartMonitor() {
        proxy.startDeviceMotionUpdatesForCamera(manager: coreMotionManager, to: opeataionQueue) { [weak self] data, error in
            if let self = self, let data = data, error == nil, let orientation = self.estimateSystemLike(gravity: data.gravity) {
                self.notifyOrientationChanged(orientation)
            }
        }
    }

    func stopMonitor() {
        guard RtcCameraOrientation.isCoreMotionEnabled else { return }
        opeataionQueue.addOperation { [weak self] in
            self?.logger.debug("stop monitor")
            self?.internalStopMonitor()
        }
    }

    private func internalStopMonitor() {
        coreMotionManager.stopDeviceMotionUpdates()
        deviceOrientation = .unknown
    }

    func toRtcDegree() -> Int? {
        deviceOrientation.toRtcDegree() ?? statusBarOrientation.toDeviceOrientation().toRtcDegree()
    }

    private var isRunning: Bool {
        return coreMotionManager.isDeviceMotionActive
    }

    private func setupStatusBarOrientation() {
        self.statusBarOrientation = UIApplication.shared.statusBarOrientation
        self.isInBackground = UIApplication.shared.applicationState == .background
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeStatusBarOrientation),
                                               name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
        logger.debug("setup: statusBarOrientation = \(statusBarOrientation.logDescription), isInBackground = \(isInBackground)")
    }

    @objc private func didChangeStatusBarOrientation() {
        self.statusBarOrientation = UIApplication.shared.statusBarOrientation
        logger.debug("didChangeStatusBarOrientation to \(statusBarOrientation.logDescription)")
    }

    @objc private func didEnterBackground() {
        self.isInBackground = true
        logger.debug("didEnterBackground")
    }

    @objc private func didBecomeActive() {
        self.isInBackground = false
        logger.debug("didBecomeActive")
    }

    private func fixDeviceOrientation() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            var initOrientation = UIDevice.current.orientation
            // 第一次旋转发生之前，UIDevice.current.orientation == .unknown，此时用statusBarOrientation作为初始值
            if initOrientation == .unknown {
                initOrientation = self.statusBarOrientation.toDeviceOrientation()
            }
            // 更新 interfaceDeviceOrientaion 初始值
            if [.faceUp, .faceDown].contains(initOrientation) {
                self.interfaceDeviceOrientaion = self.statusBarOrientation.toDeviceOrientation()
                self.logger.info("didChangeInterfaceDeviceOrientaion to \(self.interfaceDeviceOrientaion.logDescription), by \(#function)")
            }
            self.notifyOrientationChanged(initOrientation)
        }
    }

    private func notifyOrientationChanged(_ orientation: UIDeviceOrientation, from: String = #function) {
        if self.deviceOrientation != orientation {
            self.deviceOrientation = orientation
            if let degree = orientation.toRtcDegree() {
                self.logger.info("didChangeDeviceOrientation to \(orientation.logDescription), degree is \(degree), by \(from)")
                // 通知接收方设备方向有变化（已经有pullingInteval了，不再做debounce）
                self.delegate?.didChangeCameraOrientation(orientation, degree: degree)
            }
        }
    }

    private func estimateSystemLike(gravity g: CMAcceleration) -> UIDeviceOrientation? {
        // Just a quick guess, but mimics iPhone's behavior fairly well.
        if abs(g.z) > 0.88 {
            if g.z > 0 {
                return .faceDown
            } else {
                return .faceUp
            }
        }
        /*
         Linear estimation from the following measured data (all in %)
         when orientation change occurs from the fixed axis.

          z     x     y
        -----------------
          0    88    48
         10    88    48
         20    86    46
         30    84    44
         40    82    41
         50    78    37
         60    73    33
         70    66    26
         80    --    --  (no orientation change)
        */
        let x = abs(g.x)
        let y = abs(g.y)
        let threshold = 1.07 + 0.1 * abs(g.z)
        if x > y && atan2(x, y) > threshold {
            if g.x > 0 {
                return .landscapeRight
            } else {
                return .landscapeLeft
            }
        } else if y > x && atan2(y, x) > threshold {
            if g.y > 0 {
                return .portraitUpsideDown
            } else {
                return .portrait
            }
        }
        return nil
    }
}

private extension UIInterfaceOrientation {
    func toDeviceOrientation() -> UIDeviceOrientation {
        switch self {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft: // UIInterfaceOrientation、UIDeviceOrientation landscape是相反的
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        default:
            return .unknown
        }
    }
}

private extension UIDeviceOrientation {
    // disable-lint: magic number
    func toRtcDegree() -> Int? {
        switch self {
        case .landscapeLeft:
            return 270
        case .landscapeRight:
            return 90
        case .portraitUpsideDown:
            return 180
        case .portrait:
            return 0
        default:
            return nil
        }
    }
    // enable-lint: magic numberGrootCellNotifier
}

extension UIInterfaceOrientation {
    var logDescription: String {
        switch self {
        case .portrait:
            return "portrait"
        case .portraitUpsideDown:
            return "portraitUpsideDown"
        case .landscapeLeft:
            return "landscapeLeft"
        case .landscapeRight:
            return "landscapeRight"
        default:
            return "unknown(\(rawValue))"
        }
    }
}

extension UIDeviceOrientation {
    var logDescription: String {
        switch self {
        case .portrait:
            return "portrait"
        case .portraitUpsideDown:
            return "portraitUpsideDown"
        case .landscapeLeft:
            return "landscapeLeft"
        case .landscapeRight:
            return "landscapeRight"
        case .faceUp:
            return "faceUp"
        case .faceDown:
            return "faceDown"
        default:
            return "unknown(\(rawValue))"
        }
    }
}
