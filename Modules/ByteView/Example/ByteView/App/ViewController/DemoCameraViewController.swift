//
//  DemoCameraViewController.swift
//  ByteView_Example
//
//  Created by fakegourmet on 2022/5/25.
//

import AVFoundation
import UIKit
import SnapKit
import RxSwift
import RxCocoa
import LKCommonsLogging
import LarkMedia
import ByteViewUI

class DemoCameraViewController: BaseViewController {

    let camera = AVCamera()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(camera.previewView)
        camera.previewView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        camera.startCapturing()
    }

    deinit {
        camera.stopCapturing()
        LarkMediaManager.shared.unlock(scene: .imCamera)
    }
}

let captureSessionQueue = DispatchQueue(label: "capture session queue")

final class CameraPreviewView: UIView {

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        return layer
    }

    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

}

final class AVCamera {
    private let logger = LKCommonsLogging.Logger.log("ByteView", category: "Camera")

    static let `default` = AVCamera()

    private let disposeBag = DisposeBag()
    let previewView = CameraPreviewView()
    private let captureSession = AVCaptureSession()
    private let output: AVCaptureVideoDataOutput = {
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        return output
    }()
    private var succeedsToConfigure = false
    private var isCapturing = false {
        didSet {
            DispatchQueue.main.async {
                let alpha: CGFloat = self.isCapturing ? 1.0 : 0.0
                guard self.previewView.alpha != alpha else {
                    return
                }
                // nolint-next-line: magic number
                UIView.animate(withDuration: 0.2) {
                    self.previewView.alpha = alpha
                }
            }
        }
    }
    private var isEnabled = true

    deinit {
        stopCapturing()
    }

    init() {
        self.previewView.videoPreviewLayer.videoGravity = .resizeAspectFill
        self.previewView.session = captureSession
        self.isCapturing = { self.isCapturing }()

        configureNotifications()
    }

    func changeVideoGravity(_ videoGravity: AVLayerVideoGravity) {
        self.previewView.videoPreviewLayer.videoGravity = videoGravity
    }

    private func configureNotifications() {
        let notificationNames = [Notification.Name.AVCaptureSessionInterruptionEnded,
                                 Notification.Name.AVCaptureSessionRuntimeError,
                                 Notification.Name.AVCaptureSessionDidStartRunning,
                                 Notification.Name.AVCaptureSessionDidStopRunning,
                                 Notification.Name.AVCaptureSessionWasInterrupted]
        let notifications = notificationNames.map {
            NotificationCenter.default.rx.notification($0)
        }
        Observable.merge(notifications)
            .subscribe(onNext: { [weak self] notification in
                self?.logger.debug("camera notification: " + notification.name.rawValue + "info: \(notification.userInfo ?? [:])")
            })
            .disposed(by: disposeBag)

        NotificationCenter.default.rx
            .notification(UIApplication.didChangeStatusBarOrientationNotification)
            .observeOn(MainScheduler.instance)
            .subscribe({ [weak self] (_) in
                self?.setVideoOrientation()
            })
            .disposed(by: disposeBag)
    }

    private func setVideoOrientation() {
        var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
        let interfaceOrientation = UIApplication.shared.statusBarOrientation
        if interfaceOrientation != .unknown,
            let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation: interfaceOrientation) {
            initialVideoOrientation = videoOrientation
        }

        self.previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
    }

    func startCapturing() {
        captureSessionQueue.async { [weak self] in
            guard let self = self, self.isEnabled else {
                return
            }

            let captureSession = self.captureSession

            let startRunning = {
                self.logger.debug("start capturing, and succeedsToConfigure is \(self.succeedsToConfigure)")

                guard self.succeedsToConfigure else {
                    return
                }

                self.logger.debug("start capturing successfully.")
                captureSession.startRunning()
                self.isCapturing = true
            }

            if !self.succeedsToConfigure {
                let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
                self.logger.debug("authStatus is \(authStatus)")
                switch authStatus {
                case .notDetermined:
                    AVCaptureDevice.requestAccess(for: .video, completionHandler: { access in
                        captureSessionQueue.async {
                            self.logger.debug("request access, grant is \(access)")
                            if access {
                                self.configureSession()
                                startRunning()
                            }
                        }
                    })
                case .authorized:
                    self.configureSession()
                    startRunning()
                default:
                    break
                }
            } else {
                startRunning()
            }
        }
    }

    private func configureSession() {
        guard !self.succeedsToConfigure else {
            return
        }

        do {
            logger.debug("start to configure capture session")
            captureSession.beginConfiguration()
            let maybeDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                      for: .video,
                                                      position: .front)
            guard let frontCameraDevice = maybeDevice else {
                logger.error("cannot find a front camera.")
                captureSession.commitConfiguration()
                return
            }

            let input = try AVCaptureDeviceInput(device: frontCameraDevice)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                logger.error("cannot add input.")
            }

            if captureSession.canAddOutput(self.output) {
                captureSession.addOutput(self.output)
                self.succeedsToConfigure = true
            } else {
                logger.error("cannot add output.")
            }

            DispatchQueue.main.async { [weak self] in
                self?.setVideoOrientation()
            }
            captureSession.commitConfiguration()
        } catch {
            logger.error("catch configuration error: \(error).")
            captureSession.commitConfiguration()
        }
    }

    func setVideoOrientation(for interfaceOrientation: UIInterfaceOrientation) {
        if let videoPreviewLayerConnection = self.previewView.videoPreviewLayer.connection {
            guard let newVideoOrientation = AVCaptureVideoOrientation(interfaceOrientation: interfaceOrientation) else {
                return
            }
            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
        }
    }

    func stopCapturing() {
        // 由于异步，deinit()中self会被销毁，需要提前捕获capture session
        let captureSession = self.captureSession
        captureSessionQueue.async { [weak self] in
            self?.logger.debug("stop capturing.")
            if self?.isCapturing != false,
                captureSession.isRunning {
                self?.logger.debug("stop capturing successfully.")
                captureSession.stopRunning()
            }
            self?.isCapturing = false
        }
    }

    func resetRenderView(_ view: UIView?) {
        guard view != previewView.superview else {
            return
        }

        previewView.removeFromSuperview()
        if let renderView = view {
            previewView.frame = renderView.bounds
            previewView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            renderView.addSubview(previewView)
        }
    }

    func disableCapturing() {
        stopCapturing()
        isEnabled = false
    }

    func enableCapturing() {
        isEnabled = true
    }

}

extension AVCaptureVideoOrientation {
    init?(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeRight
        case .landscapeRight: self = .landscapeLeft
        default: return nil
        }
    }
}
