//
//  MeetingRtcEngine.swift
//  ByteViewRtcBridge
//
//  Created by kiri on 2023/5/25.
//

import Foundation
import ByteViewCommon

/// MeetingSession维度的rtc抽象
public final class MeetingRtcEngine: CustomStringConvertible {
    let sessionId: String
    @RwAtomic
    private(set) var createParams: RtcCreateParams
    let logger: Logger
    let listeners = RtcListeners()
    @RwAtomic private(set) var isRtcCreated = false
    @RwAtomic private(set) var isDestroyed = false
    @RwAtomic private(set) var isCameraCreated = false
    private(set) lazy var cameraDevice: RtcCameraDevice = {
        self.isCameraCreated = true
        return RtcCameraDevice(engine: self)
    }()

    var uid: String { createParams.uid }
    var proxy: RtcActionProxy { createParams.actionProxy }
    public var description: String

    public init(createParams: RtcCreateParams) {
        self.sessionId = createParams.sessionId
        self.createParams = createParams
        self.description = "MeetingRtcEngine(\(sessionId))"
        self.logger = Logger.byteRtc.withContext(sessionId).withTag("[\(self.description)]")
        logger.info("init MeetingRtcEngine")
    }

    deinit {
        logger.info("deinit MeetingRtcEngine")
        if isRtcCreated, !isDestroyed {
            assertionFailure("should release MeetingRtcEngine before deinit")
            let sessionId = self.sessionId
            let proxy = self.proxy
            RtcPrivateQueue.exeucteQueue.async {
                proxy.performAction(.rtc) {
                    RtcInstances.destroyRtc(sessionId: sessionId, reason: "deinit")
                }
            }
        }
    }

    public func release(completion: (() -> Void)? = nil) {
        logger.info("release rtc engine, isRtcCreated = \(isRtcCreated), isDestroyed = \(isDestroyed)")
        if !isRtcCreated || isDestroyed {
            self.isDestroyed = true
            executeInQueue {
                self.callbackInQueue {
                    completion?()
                }
            }
            return
        }

        self.isDestroyed = true
        executeInQueue {
            RtcInstances.destroyRtc(sessionId: self.sessionId, reason: "release")
            if self.isCameraCreated {
                self.cameraDevice.release()
            }
            self.callbackInQueue {
                completion?()
            }
        }
    }

    func execute(_ action: @escaping (RtcInstance) -> Void) {
        RtcInstances.executeInCurrentContext(action)
    }

    func ensureRtc(isInMeet: Bool = false, file: String = #fileID, function: String = #function, line: Int = #line) {
        if isDestroyed {
            assertionFailure("ensureRtc after destroyed, by \(function)")
            return
        }
        let isFirstCreate = !self.isRtcCreated
        self.isRtcCreated = true
        self.logger.info("ensureRtc(\(isInMeet)) by \(function), isFirst = \(isFirstCreate)", file: file, function: function, line: line)
        executeInQueue {
            _ = self.cameraDevice
            RtcInstances.ensureRtc(for: self.createParams, listeners: self.listeners, isInMeet: isInMeet)
        }
    }

    func joinChannel(_ params: RtcJoinParams) {
        execute {
            $0.setBusinessId(params.businessId)
            $0.joinChannel(byKey: params.channelKey, channelName: params.channelName, info: params.info, traceId: params.traceId)
        }
    }

    func leaveChannel() {
        execute {
            $0.leaveChannel()
            // leavaChannel后移除rtc加密
            $0.removeCustomEncryptor()
            RtcInstances.destroyRtc(sessionId: self.sessionId, reason: "leaveChannel")
        }
    }
}

public extension MeetingRtcEngine {
    func prestart(_ createParams: RtcCreateParams) {
        self.createParams = createParams
        ensureRtc()
    }

    func startForEffect() {
        logger.info("ensureRtc: from labcamera")
        ensureRtc()
    }

    func createInMeetEngine(_ createParams: RtcCreateParams) -> InMeetRtcEngine {
        self.createParams = createParams
        return InMeetRtcEngine(self)
    }

    static func enableAUPrestart(_ isEnabled: Bool, for sessionId: String) {
        let logger = Logger.byteRtc.withContext(sessionId).withTag("[MeetingRtcEngine(\(sessionId))]")
        var shouldEnabled = isEnabled
        if Util.isiOSAppOnMacSystem {
            logger.info("enableAUPreStart: \(isEnabled), isiOSAppOnMacSystem = true")
            shouldEnabled = false
        } else {
            logger.info("enableAUPreStart: \(isEnabled)")
        }
        RtcPrivateQueue.exeucteQueue.async {
            RtcInstances.instanceType.enableAUPreStart(shouldEnabled)
        }
    }
}

private extension MeetingRtcEngine {
    func executeInQueue(_ action: @escaping () -> Void) {
        RtcPrivateQueue.exeucteQueue.async {
            self.proxy.performAction(.rtc, action: action)
        }
    }

    func callbackInQueue(_ action: @escaping () -> Void) {
        RtcPrivateQueue.callbackQueue.async {
            self.proxy.performAction(.callback, action: action)
        }
    }
}

private struct RtcPrivateQueue {
    static let exeucteQueue = DispatchQueue(label: "lark.byteview.rtc.execute.default")
    static let callbackQueue = DispatchQueue(label: "lark.byteview.rtc.callback.default")
}

private final class RtcInstances {
    #if RTCBRIDGE_HAS_SDK
    static let instanceType: RtcInstance.Type = RtcWrapper.self
    #else
    static let instanceType: RtcInstance.Type = MockRtcInstance.self
    #endif
    private static var users: [String: (RtcCreateParams, RtcListeners)] = [:]
    private static var lockedInstances: Set<String> = []
    private static var current: RtcInstance?
    private static func logger(sessionId: String) -> Logger {
        Logger.byteRtc.withContext(sessionId).withTag("[RtcInstances(\(sessionId))]")
    }

    static func executeInCurrentContext(_ action: @escaping (RtcInstance) -> Void) {
        RtcPrivateQueue.exeucteQueue.async {
            if let rtc = RtcInstances.current, !rtc.isDestroyed {
                rtc.proxy.performAction(.rtc) {
                    action(rtc)
                }
            }
        }
    }

    static func destroyRtc(sessionId: String, reason: String) {
        if let rtc = current, rtc.sessionId == sessionId {
            _destroyRtc(rtc, reason: reason)
            if let (params, listeners) = self.users.first?.value {
                _createRtc(params: params, listeners: listeners, reason: reason)
            }
        }
    }

    static func ensureRtc(for params: RtcCreateParams, listeners: RtcListeners, isInMeet: Bool) {
        let tag = "ensureRtc(\(isInMeet))"
        let logger = self.logger(sessionId: params.sessionId)
        defer {
            if isInMeet, let rtc = current {
                lockedInstances.insert(rtc.instanceId)
            }
        }
        guard let rtc = current, !rtc.isDestroyed else {
            _createRtc(params: params, listeners: listeners, reason: tag)
            return
        }
        if !isInMeet, lockedInstances.contains(rtc.instanceId) {
            logger.info("\(tag) ignored, current rtc is locked: \(rtc)")
            return
        }
        do {
            try rtc.reuse(params, checkSession: isInMeet)
        } catch {
            logger.info("\(tag) reuse failed, error is \(error)")
            _createRtc(params: params, listeners: listeners, reason: "\(tag) cannotReuse")
        }
    }

    private static func _destroyRtc(_ rtc: RtcInstance, reason: String) {
        if !rtc.isDestroyed {
            logger(sessionId: rtc.sessionId).info("destroyRtcKit by \(reason)")
            lockedInstances.remove(rtc.instanceId)
            rtc.destroy()
            RtcInternalListeners.forEach { $0.onDestroyInstance(rtc) }
        }
        if self.current?.instanceId == rtc.instanceId {
            self.users.removeValue(forKey: rtc.sessionId)
            self.current = nil
        }
    }

    private static func _createRtc(params: RtcCreateParams, listeners: RtcListeners, reason: String) {
        if let rtc = self.current {
            _destroyRtc(rtc, reason: reason)
        }
        logger(sessionId: params.sessionId).info("createRtcKit by \(reason)")
        let rtc = instanceType.init(params: params, listeners: listeners)
        self.current = rtc
        self.users[params.sessionId] = (params, listeners)
        RtcInternalListeners.forEach { $0.onCreateInstance(rtc) }
    }
}

#if RTCBRIDGE_HAS_SDK
struct VideoStreamRtcExecutor {
    static func executeInCurrentContext(_ action: @escaping (RtcWrapper) -> Void) {
        RtcInstances.executeInCurrentContext {
            if let obj = $0 as? RtcWrapper {
                action(obj)
            }
        }
    }
}
#endif

extension Logger {
    static let byteRtc = getLogger("ByteRtc")
    static let byteRtcSDK = getLogger("ByteRtcSDK.Log")
}
