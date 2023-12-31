//
//  OPAPIHandlerAccelerometer.swift
//  LarkOpenApis
//
//  Created by yi on 2021/2/2.
//

import OPFoundation
import CoreMotion
import LarkOpenPluginManager
import LarkOpenAPIModel
import ECOProbe
import OPPluginManagerAdapter
import LarkContainer

final class OpenPluginAccelerometer: OpenBasePlugin {

    private var interval: String?
    private var manager: CMMotionManager? {
        get {
            if let manager = internalManager {
                return manager
            }
            let manager = CMMotionManager()
            let motionInterval = interval == "ui" ? 0.06 : 0.2
            manager.accelerometerUpdateInterval = motionInterval
            manager.deviceMotionUpdateInterval = motionInterval
            internalManager = manager
            return manager
        }
        set {
            internalManager = newValue
        }
    }
    private var internalManager: CMMotionManager?

    deinit {
        manager?.stopDeviceMotionUpdates()
    }

    lazy var queue: OperationQueue = {
        let operationQueue = OperationQueue()
        return operationQueue
    }()

    public func enableAccelerometer(params: OpenAPIEnableAccelerometerParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        
        let uniqueID = gadgetContext.uniqueID
        let enable = params.enable
        let paramInterval = params.interval
        if interval != paramInterval {
            manager?.stopDeviceMotionUpdates()
            activeAccelerometer[uniqueID] = nil
            manager = nil
            interval = paramInterval
        }
        // 关闭加速度计
        if !enable {
            manager?.stopDeviceMotionUpdates()
            activeAccelerometer[uniqueID] = nil
            callback(.success(data: nil))
            return
        }

        guard let manager = manager else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setErrno(OpenAPICommonErrno.internalError)
                .setMonitorMessage("CMMotionManager is nil")
            callback(.failure(error: error))
            return
        }

        if !manager.isDeviceMotionAvailable {
            let error = OpenAPIError(code: EnableAccelerometerErrorCode.notSupport)
                .setErrno(OpenAPIAccelerometerErrno.notSupport)
                .setOuterMessage(BundleI18n.OPPlugin.not_support_accelerometers())
            callback(.failure(error: error))
            return
        }

        if manager.isDeviceMotionActive {
            let error = OpenAPIError(code: EnableAccelerometerErrorCode.alreadyRunning)
                .setErrno(OpenAPIAccelerometerErrno.alreadyRunning)
                .setOuterMessage(BundleI18n.OPPlugin.accelerometer_is_running())
            callback(.failure(error: error))
            return
        }
        
        let deviceMotionUpdatesHandler: CMDeviceMotionHandler = { (motion, error) in
            guard let motion = motion else {
                context.apiTrace.error("startDeviceMotionUpdates get nil motion,error\(String(describing: error))")
                return
            }
            let userAcceleration = motion.userAcceleration
            let gravity = motion.gravity
            let data = [
                "x": (userAcceleration.x + gravity.x),
                "y": (userAcceleration.y + gravity.y),
                "z": (userAcceleration.z + gravity.z)
            ]
            // TODO: FireEvent直接接入continue
            do {
                let firEventInfo = try OpenAPIFireEventParams(event: "onAccelerometerChange",
                                                              data: data, preCheckType: .shouldInterruption)
                let response = context.syncCall(apiName: "fireEvent", params: firEventInfo, context: context)
                switch response {
                case let .failure(error: e):
                    context.apiTrace.error("fire event fail \(e)")
                case .success(data: _):
                    context.apiTrace.info("fire event success")
                case .continue(event: _, data: _):
                    context.apiTrace.info("fire event continue")
                @unknown default:
                    context.apiTrace.info("fire event unknown")
                }
            } catch {
                context.apiTrace.info("generate fire event params error \(error)")
            }

        }

        activeAccelerometer[uniqueID] =
            ActiveAccelerometerOperation(manager: manager,
                                         handlerQueue: queue,
                                         handler: deviceMotionUpdatesHandler,
                                         apiTrace: context.apiTrace,
                                         uniqueID: uniqueID)
        // 开启加速度计
        do {
           try OPSensitivityEntry.startDeviceMotionUpdates(forToken: .openPluginAccelerometerEnableAccelerometer, manager: manager, to: queue, withHandler: deviceMotionUpdatesHandler)
            context.apiTrace.info("startDeviceMotionUpdates sucess")
            callback(.success(data: nil))
        } catch {
            context.apiTrace.error("startAccelerometerUpdates throw error: \(error)")
            let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                .setMonitorMessage(error.localizedDescription)
            callback(.failure(error: error))
        }
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "enableAccelerometer", pluginType: Self.self, paramsType: OpenAPIEnableAccelerometerParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.enableAccelerometer(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        addAppActivityListener()
    }
    
    private var activeAccelerometer: [OPAppUniqueID: ActiveAccelerometerOperation] = [:]
    // MARK: - addAppActivityListener
    /// 在小程序进入后台以后关闭加速度计，进入前台后尝试恢复。
    private func addAppActivityListener() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAppEnterBackground(_:)),
                                               name: NSNotification.Name(rawValue: kBDPEnterBackgroundNotification),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAppEnterForeground(_:)),
                                               name: NSNotification.Name(rawValue: kBDPEnterForegroundNotification),
                                               object: nil)
    }
    
    @objc
    private func handleAppEnterBackground(_ notify: Notification) {
        if let uniqueID = notify.userInfo?[kBDPUniqueIDUserInfoKey] as? OPAppUniqueID,
           let manager = activeAccelerometer[uniqueID] {
            manager.pauseActive()
        }
    }

    @objc
    private func handleAppEnterForeground(_ notify: Notification) {
        if let uniqueID = notify.userInfo?[kBDPUniqueIDUserInfoKey] as? OPAppUniqueID,
           let manager = activeAccelerometer[uniqueID] {
            manager.resumeActiveIfNeeded()
        }
    }
}

extension OpenPluginAccelerometer {
    private final class ActiveAccelerometerOperation {
        private weak var manager: CMMotionManager?
        private let handler: CMDeviceMotionHandler
        private weak var handlerQueue: OperationQueue?
        let apiTrace: OPTrace
        let uniqueID: OPAppUniqueID
        init(manager: CMMotionManager,
             handlerQueue: OperationQueue,
             handler: @escaping CMDeviceMotionHandler,
             apiTrace: OPTrace,
             uniqueID: OPAppUniqueID) {
            self.manager = manager
            self.handlerQueue = handlerQueue
            self.handler = handler
            self.apiTrace = apiTrace
            self.uniqueID = uniqueID
        }
        
        func resumeActiveIfNeeded() {
            guard let manager = manager,
                  let queue = handlerQueue,
                  !manager.isDeviceMotionActive else {
                return
            }
            apiTrace.info("accelerometer resume active! uniqueID: \(uniqueID)")
            do {
               try OPSensitivityEntry.startDeviceMotionUpdates(forToken: .openPluginAccelerometerResumeActiveIfNeeded, manager: manager, to: queue, withHandler: handler)
                apiTrace.info("accelerometer resume active! uniqueID: \(uniqueID)")
            } catch {
                apiTrace.info("accelerometer resume active failed! uniqueID: \(uniqueID), throws error: \(error)")
            }
            manager.startDeviceMotionUpdates(to: queue, withHandler: handler)
        }
        
        func pauseActive() {
            guard let manager = manager,
                  let queue = handlerQueue,
                  manager.isDeviceMotionActive else {
                return
            }
            apiTrace.info("accelerometer pause active! uniqueID: \(uniqueID)")
            manager.stopDeviceMotionUpdates()
        }
    }
}
