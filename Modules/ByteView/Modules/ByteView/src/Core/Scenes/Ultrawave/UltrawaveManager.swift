//
//  UltrawaveManager.swift
//  ByteView
//
//  Created by Tobb Huang on 2021/12/1.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkMedia
import ByteViewMeeting
import nfdsdk
import ByteViewTracker
import ByteViewSetting

final class UltrawaveManager: NSObject, NFDKitDelegate, MediaResourceInterruptionObserver {
    enum RecvResult {
        case success(String)
        case failure(String)
        case userSettingUnauthorized
        case isAlreadyRecving
        case privacyUnauthorized
    }

    enum NFDUsageType {
        case shareScreen
        case preview_manual
        case preview_auto
        case onthecall_auto
        case onthecall_manual

        var nfdType: NFDKitUsage {
            switch self {
            case .onthecall_auto:
                return .USS_ONTHECALL_AUTO
            case .onthecall_manual:
                return .USS_ONTHECALL_MANUAL
            case .preview_auto:
                return .USS_PREVIEW_AUTO
            case .preview_manual:
                return .USS_PREVIEW_MANUAL
            case .shareScreen:
                return .USS_SHARE_SCREEN
            }
        }
    }

    static let shared = UltrawaveManager()

    static let logger = Logger.ultrawave

    @RwAtomic
    private(set) var isRecvingUltrawave = false

    @RwAtomic
    private var callbacks: [(RecvResult) -> Void] = []

    override init() {
        super.init()
        NFDKit.shared().initSDK(self)
        NFDKit.shared().initScanner()
    }

    func startRecv(config: String, usageType: NFDUsageType, isSpeakerOn: Bool? = nil, isInMeet: Bool = false, callback: @escaping ((RecvResult) -> Void)) {
        // 需满足：用户设置授权 && 当前不在接收超声波 && 麦克风授权
        if self.isRecvingUltrawave {
            self.callbacks.append(callback)
            return
        }
        if !Privacy.audioAuthorized {
            callback(.privacyUnauthorized)
            return
        }
        if config.isEmpty {
            assertionFailure("nfd_scan_config is empty!")
            Self.logger.error("nfd_scan_config is empty!")
        } else {
            Self.logger.info("nfd_scan_config is \(config)")
            NFDKit.shared().configScan(config)
        }
        self.isRecvingUltrawave = true
        Self.logger.info("Start receiving ultrawave \(usageType)")
        let startTime = CACurrentMediaTime()
        let action: () -> Void = {
            let wrapper: (RecvResult) -> Void = { r in
                let cachedCallbacks = self.callbacks
                self.callbacks = []
                cachedCallbacks.forEach { $0(r) }
                callback(r)
                LarkMediaManager.shared.unlock(scene: .ultrawave, options: .leaveScenarios)
            }

            let completion: (LarkMediaResource, String, String?) -> Void = { (resource, result, error) in
                self.isRecvingUltrawave = false
                self.leaveUltrawaveMode(resource: resource)
                LarkAudioSession.shared.waitAudioSession("stopUltrawave", in: .main) {
                    let duration = CACurrentMediaTime() - startTime
                    if let error = error {
                        Self.logger.error("Receive ultrawave failed! \(error)")
                        wrapper(.failure(error))
                        CommonReciableTracker.trackUltrawaveRecognize(success: false, duration: duration)
                    } else {
                        Self.logger.info("Receive ultrawave success!")
                        wrapper(.success(result))
                        CommonReciableTracker.trackUltrawaveRecognize(success: true, duration: duration)
                    }
                }
            }

            let scan: (LarkMediaResource) -> Void = { resource in
                self.enterUltrawaveMode(resource: resource, isSpeakerOn: isSpeakerOn)
                LarkAudioSession.shared.waitAudioSession("startUltrawave") {
                    Self.logger.info("NFDKit.shared().startScan() start")
                    // nolint-next-line: magic number
                    let ret = NFDKit.shared().startScan(3000, andMode: .SCAN_MODE_USS, andUsage: usageType.nfdType) { (result, e) in
                        let error = "NFDKitScanErrorCode(\(e.rawValue))"
                        Self.logger.info("NFDKit.shared().startScan() finished, result = \(result), error = \(error)")
                        completion(resource, result, e == .NFD_NO_ERROR ? nil : error)
                    }
                    if ret != .SUCCESS {
                        let error = "NFDKitReturnValue(\(ret.rawValue))"
                        Self.logger.info("NFDKit.shared().startScan() failed, error = \(error)")
                        completion(resource, "", error)
                    }
                }
            }

            let result = LarkMediaManager.shared.tryLock(scene: .ultrawave, observer: self)
            guard case .success(let resource) = result else {
                Self.logger.error("Receive ultrawave failed! \(result.error)")
                wrapper(.failure("\(result.error)"))
                return
            }
            if #available(iOS 17, *), !isInMeet {
                resource.microphone.requestMute(false) { result in
                    switch result {
                    case .success:
                        scan(resource)
                    case .failure(let error):
                        Self.logger.error("Receive ultrawave failed!, requestMute error: \(error)")
                        completion(resource, "", "requestMute failed")
                    }
                }
            } else {
                scan(resource)
            }
        }

        if isInMeet {
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1), execute: action)
        } else {
            action()
        }
    }

    private var isSpeakerOnBeforeUltrawave: Bool = false
    /// 开启超声波接收模式，会临时打断当前的scenario和扬声器配置
    /// - 超声波接收过程中，enter/leave AudioSessionScenario可能会打断超声波接收。
    /// - 只是切换音频模式以兼容超声波，不含超声波接收和识别功能。
    private func enterUltrawaveMode(resource: LarkMediaResource, isSpeakerOn: Bool?) {
        self.isSpeakerOnBeforeUltrawave = isSpeakerOn ?? LarkAudioSession.shared.isSpeakerOn
        Logger.audio.info("enter isSpeakerOn \(isSpeakerOn), \(LarkAudioSession.shared.isSpeakerOn)")
        resource.audioSession.enter(.ultrawave, options: isSpeakerOnBeforeUltrawave ? .enableSpeakerIfNeeded : [])
    }

    /// 结束超声波接收模式，恢复当前的音频配置和之前的扬声器配置
    private func leaveUltrawaveMode(resource: LarkMediaResource) {
        resource.audioSession.leave(.ultrawave)
        if isSpeakerOnBeforeUltrawave {
            LarkAudioSession.shared.enableSpeakerIfNeeded(true)
        }
    }

    func stopRecv() {
        Self.logger.info("Stop receiving ultrawave")
        guard self.isRecvingUltrawave else { return }
        self.isRecvingUltrawave = false
        LarkAudioSession.shared.waitAudioSession("stopRecvUltrawave") {
            NFDKit.shared().stopScan()
        }
        if let resource = LarkMediaManager.shared.getMediaResource(for: .ultrawave) {
            leaveUltrawaveMode(resource: resource)
        }
        LarkMediaManager.shared.unlock(scene: .ultrawave)
    }

    func onNFDKitLogging(_ level: NFDKitLogLevel, andContent content: String) {
        switch level {
        case .LEVEL_ERROR:
            Self.logger.error("onNFDKitLogging: \(content)")
        case .LEVEL_WARN:
            Self.logger.warn("onNFDKitLogging: \(content)")
        default:
//            Self.logger.info("onNFDKitLogging[\(level.rawValue)]: \(content)")
            break
        }
    }

    func onNFDKitTracking(_ event: String, andParams params: String) {
        Self.logger.info("onNFDKitTracking: \(event), params: \(params)")
        if let data = params.data(using: .utf8), let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            VCTracker.post(TrackEvent.raw(name: event, params: json))
        } else {
            VCTracker.post(TrackEvent.raw(name: event))
        }
    }

    func mediaResourceWasInterrupted(by scene: MediaMutexScene, type: MediaMutexType, msg: String?) {
        Self.logger.error("mediaResourceWasInterrupted: \(scene) type: \(type)")
        stopRecv()
    }

    func mediaResourceInterruptionEnd(from scene: MediaMutexScene, type: MediaMutexType) {
        Self.logger.error("mediaResourceInterruptionEnd: \(scene) type: \(type)")
    }
}
