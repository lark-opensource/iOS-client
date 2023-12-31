//
//  UltrasonicWaveViewController.swift
//  ByteViewDemo
//
//  Created by kiri on 2021/3/11.
//

import UIKit
import nfdsdk
import LarkSetting
import ByteViewCommon
import ByteViewUI
import LarkMedia

final class UltrasonicWaveViewController: BaseViewController, NFDKitDelegate, MediaResourceInterruptionObserver {
    let startButton = UIButton(type: .system)
    let textLabel = UILabel()
    override var logger: Logger { .util }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "超声波"
        startButton.setTitle("Start", for: .normal)
        startButton.addTarget(self, action: #selector(didStart(_:)), for: .touchUpInside)
        view.addSubview(startButton)
        startButton.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
        }

        textLabel.textColor = .black
        view.addSubview(textLabel)
        textLabel.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(startButton.snp.top).offset(-100)
        }

        NFDKit.shared().initSDK(self)
        NFDKit.shared().initScanner()
    }

    private var isReceiving: Bool = false {
        didSet {
            if isReceiving {
                startButton.setTitle("Stop", for: .normal)
            } else {
                startButton.setTitle("Start", for: .normal)
            }
        }
    }

    @objc private func didStart(_ sender: Any) {
        if isReceiving {
            isReceiving = false
            textLabel.text = ""
            LarkAudioSession.shared.waitAudioSession("stopUltrawave", in: .main) {
                NFDKit.shared().stopScan()
            }
            if let resource = LarkMediaManager.shared.getMediaResource(for: .ultrawave) {
                leaveUltrawaveMode(resource: resource)
            }
            LarkMediaManager.shared.unlock(scene: .ultrawave)
        } else {
            isReceiving = true
            textLabel.text = "Scanning..."
            if let config = try? SettingManager.shared.setting(with: String.self, key: .make(userKeyLiteral: "nfd_scan_config")) {
                logger.info("nfd_scan_config is \(config)")
                NFDKit.shared().configScan(config)
            } else {
                logger.error("nfd_scan_config is nil")
            }
            let startTime = CACurrentMediaTime()
            let completion: (LarkMediaResource, String, String?) -> Void = { [weak self] (resource, key, error) in
                self?.leaveUltrawaveMode(resource: resource)
                LarkAudioSession.shared.waitAudioSession("leaveUltrawaveMode", in: .main) {
                    if let error = error {
                        self?.textLabel.text = "error: \(error)"
                    } else {
                        let interval = CACurrentMediaTime() - startTime
                        self?.textLabel.text = "\(key) [Costs: \(String(format: "%.2f", interval))s]"
                    }
                    self?.isReceiving = false
                }
            }
            let result = LarkMediaManager.shared.tryLock(scene: .ultrawave, observer: self)
            guard case .success(let resource) = result else {
                textLabel.text = "error: \(result)"
                isReceiving = false
                return
            }
            enterUltrawaveMode(resource: resource)
            LarkAudioSession.shared.waitAudioSession("startUltrawave", in: .main) {
                let ret = NFDKit.shared().startScan(3000, andMode: .SCAN_MODE_USS, andUsage: .UNKNOWN) { (key, error) in
                    completion(resource, key, error == .NFD_NO_ERROR ? nil : "NFDKitScanErrorCode(\(error.rawValue))")
                }
                if ret != .SUCCESS {
                    completion(resource, "", "NFDKitReturnValue(\(ret.rawValue))")
                }
            }
        }
    }

    private var ultrawave = AudioSessionScenario("ultrawave", category: .playAndRecord, mode: .default, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])

    private var isSpeakerOnBeforeUltrawave: Bool = false
    private func enterUltrawaveMode(resource: LarkMediaResource) {
        self.isSpeakerOnBeforeUltrawave = true
        resource.audioSession.enter(ultrawave, options: isSpeakerOnBeforeUltrawave ? .enableSpeakerIfNeeded : [])
    }

    private func leaveUltrawaveMode(resource: LarkMediaResource) {
        resource.audioSession.leave(ultrawave)
        if isSpeakerOnBeforeUltrawave {
            LarkAudioSession.shared.enableSpeakerIfNeeded(true)
        }
    }

    func onNFDKitLogging(_ level: NFDKitLogLevel, andContent content: String) {
        switch level {
        case .LEVEL_ERROR:
            logger.error("onNFDKitLogging: \(content)")
        case .LEVEL_WARN:
            logger.warn("onNFDKitLogging: \(content)")
        default:
            logger.info("onNFDKitLogging[\(level.rawValue)]: \(content)")
        }
    }

    func onNFDKitTracking(_ event: String, andParams params: String) {
        logger.info("onNFDKitTracking: \(event), params: \(params)")
    }

    func mediaResourceWasInterrupted(by scene: MediaMutexScene, type: MediaMutexType, msg: String?) {
        isReceiving = true
        didStart(startButton)
    }

    func mediaResourceInterruptionEnd(from scene: MediaMutexScene, type: MediaMutexType) {}
}
