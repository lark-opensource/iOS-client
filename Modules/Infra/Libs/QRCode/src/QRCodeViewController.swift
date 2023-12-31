//
//  QRCodeViewController.swift
//  Lark
//
//  Created by zc09v on 2017/4/19.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import ImageIO
import LarkUIKit
import SnapKit
import LarkFoundation
import LKCommonsLogging
import RxSwift
import RxCocoa
import RoundedHUD
import LKCommonsTracker
import Homeric
import LarkAssetsBrowser
import EEAtomic
import UniverseDesignIcon
import ByteWebImage
import UniverseDesignDialog
import LarkImageEditor
import LarkMedia

open class QRCodeViewController: BaseUIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, ScanCodeViewControllerType {

    public var supportTypes: [ScanType]?

    public var didScanSuccessHandler: ((String, ScanType) -> Void)?

    public var didScanFailHandler: ((QRScanError) -> Void)?

    public var didManualCancelHandler: ((ScanType) -> Void)?

    public var didScanQRCodeBlock: ((String, VEQRCodeFromType) -> Void)?

    public weak var delegate: QRCodeViewControllerDelegate?

    public var lifeCircle: QRCodeViewControllerLifeCircle?

    public var firstDescribelText: String?
    public var secondDescribelText: String?

    private lazy var firstDescribeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N00
        label.backgroundColor = UIColor.clear
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    private var secondDescribeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N00
        label.backgroundColor = UIColor.clear
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private var maskView: ScanMask = ScanMask()

    private var alertLabel = UILabel()

    private static let logger = Logger.log(QRCodeViewController.self)

    private let naviBar: TitleNaviBar = TitleNaviBar(titleString: BundleI18n.QRCode.Lark_Legacy_LarkScan)

    private let qrCodeDecoder: QRCodeDecoder?
    private let qrCodeDecoderType: QRCodeDecoderType

    private var isViewDidAppeared = BehaviorRelay(value: false)
    private let disposeBag = DisposeBag()

    private let sessionQueue = DispatchQueue(label: "QRCodeViewController.SessionQueue", qos: .userInteractive)
    private let captureQueue = DispatchQueue(label: "QRCodeViewController.CaptureQueue")

    lazy var captureSession = AVCaptureSession()
    lazy var captureDevice: AVCaptureDevice? = {
        return LarkFoundation.Utils.cameraPermissions() ? AVCaptureDevice.default(for: AVMediaType.video) : nil
    }()
    lazy var videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)

    private var numberOfFramesBeforeScanSucceed: Int = 0
    private var sessionStartTimeStamp: CFAbsoluteTime?

    /// Session lock / unlock operation can be time consuming,
    /// thus we need dispatch these two operations on sessionQueue ( see startSession(), stopSession() ).
    /// So when we call stopSession() on main thread, thre session is not stopped immediately.
    /// isSessionLocked is a flag to mark which one of stopSession() and startSession() is called at last,
    /// though the underlying session may not be stoped or started actually.
    private let isSessionLocked = AtomicBool(true)
    private let readyOnceToken = AtomicOnce()
    private var isFullScreen: Bool {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return true }
        var isFullScreen = true
        let keyWindow = UIApplication.shared.windows.last { $0.isKeyWindow }
        if let currentWindow = keyWindow {
            isFullScreen = UIScreen.main.bounds == currentWindow.bounds
        }
        return isFullScreen
    }

    public init(
        type: ScanCodeType = .qrCode,
        lifeCircle: QRCodeViewControllerLifeCircle? = nil
    ) {
        self.lifeCircle = lifeCircle
        lifeCircle?.onInit(state: .start)
        defer {
            lifeCircle?.onInit(state: .end)
        }
        var decoderType: QRCodeDecoderType = QRCodeDecoderType()
        if type.contains(.barCode) {
            decoderType.insert(.bar)
        }
        if type.contains(.qrCode) {
            decoderType.insert(.QR)
        }
        qrCodeDecoderType = decoderType
        qrCodeDecoder = QRCodeDecoder(type: decoderType)
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override open var navigationBarStyle: NavigationBarStyle {
        return .none
    }

    override open func viewDidLoad() {
        
        lifeCircle?.onViewDidLoad(state: .start)
        defer {
            lifeCircle?.onViewDidLoad(state: .end)
        }
        super.viewDidLoad()
        setupView()

        func addObserver(with name: NSNotification.Name?) {
            NotificationCenter.default.addObserver(self, selector: #selector(updateUIWhenInterruptChanged), name: name, object: nil)
        }

        let pinchGesture = UIPinchGestureRecognizer()
        self.view.addGestureRecognizer(pinchGesture)
        pinchGesture.addTarget(self, action: #selector(self.pinchGestureInvoked(pinch:)))

        startupQRScaner()

        if Display.pad {
            addObserver(with: .AVCaptureSessionWasInterrupted)
            addObserver(with: .AVCaptureSessionInterruptionEnded)
            addObserver(with: .AVCaptureSessionDidStartRunning)
            addObserver(with: .AVCaptureSessionDidStopRunning)
        }
        isViewDidAppeared.filter { $0 }.take(1)
        .subscribe(onNext: { [weak self] _ in
                self?.updateUIWhenInterruptChanged()
        }).disposed(by: disposeBag)
    }

    private func setupView() {
        defer { view.bringSubviewToFront(self.naviBar) }
        setupNavibar()
        self.view.backgroundColor = UIColor.ud.staticBlack

        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer)

        self.maskView.frame = view.bounds
        self.maskView.clipsToBounds = true
        self.view.addSubview(maskView)

        setupAlbumButton()

        alertLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        alertLabel.numberOfLines = 0
        alertLabel.backgroundColor = UIColor.clear
        alertLabel.font = UIFont.systemFont(ofSize: 18)
        alertLabel.textAlignment = .center
        alertLabel.isHidden = true
        self.view.addSubview(alertLabel)
        alertLabel.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
            maker.left.greaterThanOrEqualToSuperview().offset(16)
            maker.right.lessThanOrEqualToSuperview().offset(-16)
        }

        if let text = firstDescribelText {
            firstDescribeLabel.text = text
            firstDescribeLabel.isHidden = false
        }
        self.view.addSubview(firstDescribeLabel)

        if let text = secondDescribelText {
            secondDescribeLabel.text = text
            secondDescribeLabel.isHidden = false
        }
        self.view.addSubview(secondDescribeLabel)
    }

    private func setupAlbumButton() {

        let albumContainerView = UIView()
        albumContainerView.layer.cornerRadius = 58 / 2
        albumContainerView.layer.ud.setBackgroundColor(UIColor.ud.bgMask.withAlphaComponent(0.4))

        let textLabel = UILabel()
        textLabel.text = BundleI18n.QRCode.Lark_Legacy_QrCodeAlbum
        textLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        textLabel.font = .systemFont(ofSize: 12)
        let albumImage = UDIcon.getIconByKey(.nopictureFilled, iconColor: UIColor.ud.primaryOnPrimaryFill)
        let albumImageView = UIImageView(image: albumImage)

        albumContainerView.addSubview(textLabel)
        albumContainerView.addSubview(albumImageView)
        self.view.addSubview(albumContainerView)

        albumContainerView.snp.makeConstraints { (maker) in
            maker.bottom.equalToSuperview().offset(-84)
            maker.centerX.equalToSuperview()
            maker.width.height.equalTo(58)
        }
        albumImageView.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(8)
            maker.centerX.equalToSuperview()
        }
        textLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(albumImageView.snp.bottom).offset(3)
            maker.centerX.equalToSuperview()
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(clickAlbumButton))
        albumContainerView.addGestureRecognizer(tap)
    }

    @objc
    private func clickAlbumButton() {
        self.delegate?.didClickAlbum()
        self.albumButtonDidClick()
    }

    private func setupNavibar() {
        self.isNavigationBarHidden = true

        naviBar.backgroundColor = .clear
        (naviBar.titleView as? UILabel)?.textColor = UIColor.ud.primaryOnPrimaryFill
        self.view.addSubview(naviBar)
        naviBar.snp.makeConstraints { (make) in make.top.left.right.equalToSuperview() }

        // 返回按钮
        let backButton = UIButton(type: .custom)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        naviBar.addSubview(backButton)
        backButton.snp.makeConstraints({ (make) in
            make.width.height.equalTo(24)
            make.bottom.equalTo(-10)
            make.left.equalTo(20)
        })

        if backWayisPop() {
            backButton.setImage(Resources.navigation_back_white_light, for: .normal)
        } else {
            backButton.setImage(Resources.navigation_back_white_cross, for: .normal)
        }
    }

    private func showMediaLockAlert(msg: String) {
        let dialog = UDDialog()
        dialog.setContent(text: msg)
        dialog.addPrimaryButton(text: BundleI18n.QRCode.Lark_Legacy_ConfirmSure, dismissCompletion: { [weak self] in
            self?.navigationController?.popViewController(animated: false)
        })
        self.present(dialog, animated: true)
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if Display.pad && !isViewDidAppeared.value {
            self.updateUIWhenCaptureSession(
                isInterrupted: self.captureSession.isInterrupted,
                isRunnning: self.captureSession.isRunning
            )
        }
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.updateUIWhenCaptureSession(
            isInterrupted: self.captureSession.isInterrupted,
            isRunnning: self.captureSession.isRunning
        )
        if isFullScreen {
            sessionStart()
        } else {
            stopSession()
        }
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        LarkMediaManager.shared.unlock(scene: .imCamera)
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if captureDevice == nil {
            if !isViewDidAppeared.value {
                lifeCircle?.onError(QRCodeError.invalidCameraDevice)
                let dialog = UDDialog.noPermissionDialog(title: BundleI18n.QRCode.Lark_Core_CameraAccess_Title,
                                                         detail: BundleI18n.QRCode.Lark_Core_CameraAccessForScanCode_Desc())
                present(dialog, animated: true, completion: nil)
            }
        } else {
            if isViewDidAppeared.value {
                startSession()
            }
        }
        isViewDidAppeared.accept(true)
    }

    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let vw = view.frame.width
        let vh = view.frame.height
        let scanRect = CGRect(
            x: 0,
            y: vh * 0.25, // 从屏幕25%起
            width: view.frame.width,
            height: vh * (0.45) // 25%到70%
        )
        self.maskView.frame = view.bounds
        self.maskView.update(frame: view.bounds, scanRect: scanRect)

        let labelSize: CGFloat = vw - 20
        let firstlabelRect = CGRect(
            x: (vw - labelSize) / 2,
            y: scanRect.bottom + 35,
            width: labelSize,
            height: 20
        )
        self.firstDescribeLabel.frame = firstlabelRect

        let secondlabelRect = CGRect(
            x: firstlabelRect.left,
            y: firstlabelRect.bottom + 8,
            width: labelSize,
            height: 20
        )
        self.secondDescribeLabel.frame = secondlabelRect

        self.videoPreviewLayer.frame = self.view.bounds
        self.videoPreviewLayer.connection?.videoOrientation = getDeviceOrientation()
    }

    private func getDeviceOrientation() -> AVCaptureVideoOrientation {
        switch UIApplication.shared.statusBarOrientation {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .unknown:
            return .portrait
        @unknown default:
            return .portrait
        }
    }

    func backWayisPop() -> Bool {
        if (self.navigationController != nil), self.navigationController?.viewControllers.first != self {
            return true
        }
        return false
    }

    /// 提供默认实现，调用block，也可以提供给子类override
    open func didScanQRCode(dataStr: String, from: VEQRCodeFromType) {
        didScanQRCodeBlock?(dataStr, from)
    }

    public func startScanning() {
        startSession()
    }

    public func stopScanning() {}

    private func sessionStart() {
        DispatchQueue.main.async {
            guard self.isFullScreen else { return }
            self.sessionStartTimeStamp = CFAbsoluteTimeGetCurrent()
            self.numberOfFramesBeforeScanSucceed = 0
            self.isSessionLocked.set(value: false)
            self.sessionQueue.async {
                self.captureSession.startRunning()
            }
        }
    }

    private func startSession() {
        LarkMediaManager.shared.tryLock(scene: .imCamera, observer: self) { [weak self] (result) in
            guard let self = self else { return }
            DispatchQueue.main.async { [weak self] in
                switch result {
                case .success:
                    self?.sessionStart()
                case .failure(let error):
                    if case let MediaMutexError.occupiedByOther(context) = error {
                        if let msg = context.1 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                self?.showMediaLockAlert(msg: msg)
                            }
                        }
                    }
                    Self.logger.error("try Lock failed \(error)")
                }
            }
        }
    }

    private func stopSession() {
        isSessionLocked.set(value: true)
        sessionQueue.async {
            self.captureSession.stopRunning()
        }
    }

    @objc
    private func updateUIWhenInterruptChanged() {
        if Thread.isMainThread {
            self.updateUIWhenCaptureSession(
                isInterrupted: self.captureSession.isInterrupted,
                isRunnning: self.captureSession.isRunning
            )
        } else {
            DispatchQueue.main.async {
                self.updateUIWhenCaptureSession(
                    isInterrupted: self.captureSession.isInterrupted,
                    isRunnning: self.captureSession.isRunning
                )
            }
        }
    }

    private func updateUIWhenCaptureSession(isInterrupted: Bool, isRunnning: Bool) {
        if UIDevice.current.userInterfaceIdiom != .pad {
            return
        }
        /// 只有在非全屏并且 interrupted || !running 的时候才显示提示文案
        if (isInterrupted || !isRunnning) && !isFullScreen {
            self.videoPreviewLayer.isHidden = true
            self.maskView.isHidden = true
            self.alertLabel.isHidden = false
            self.updateAlertTextWhenInterrupted()
        } else {
            self.videoPreviewLayer.isHidden = false
            self.maskView.isHidden = false
            self.alertLabel.isHidden = true
        }
    }

    private func updateAlertTextWhenInterrupted() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.alertLabel.text = BundleI18n.QRCode.Lark_Legacy_iPadSplitViewCamera
        }
    }

    @objc
    private func backButtonTapped() {
        self.delegate?.didClickBack()
        if backWayisPop() {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }

    private func startupQRScaner() {
        guard let captureDevice = captureDevice else { return }
        lifeCircle?.onCameraReady(state: .start)
        sessionQueue.async {
            do {
                self.captureSession.sessionPreset = AVCaptureSession.Preset.photo

                let inputDevice = try AVCaptureDeviceInput(device: captureDevice)
                let videoDataOutput = AVCaptureVideoDataOutput()
                videoDataOutput.setSampleBufferDelegate(self, queue: self.captureQueue)

                self.captureSession.addOutput(videoDataOutput)
                self.captureSession.addInput(inputDevice)

                self.configCaptureDevice()
                self.startSession()
            } catch {
                DispatchQueue.main.async {
                    self.showAlert(
                        title: BundleI18n.QRCode.Lark_Legacy_Hint,
                        message: BundleI18n.QRCode.Lark_Legacy_QrCodeDeviceError
                    )
                }
            }
        }
    }

    private func albumButtonDidClick() {
        let picker = ImagePickerViewController(assetType: .imageOnly(maxCount: 9),
                                               sendButtonTitle: BundleI18n.QRCode.Lark_Legacy_ConfirmSure)
        picker.showSingleSelectAssetGridViewController()
        picker.imagePikcerCancelSelect = { [weak self] (vc, _) in
            vc.dismiss(animated: true) {
                self?.startSession()
            }
        }
        picker.imagePickerFinishSelect = { [weak self] (vc, result) in
            let weakSelf = self
            guard let self = self, let asset = result.selectedAssets.first else {
                weakSelf?.startSession()
                vc.dismiss(animated: true, completion: nil)
                return
            }
            let hud = RoundedHUD.showLoading(on: vc.view, disableUserInteraction: true)
            DispatchQueue.global().async {
                let image: UIImage? = asset.originalImage()
                let result = image.flatMap { QRCodeTool.scan(from: $0, type: self.qrCodeDecoderType) }
                DispatchQueue.main.async {
                    hud.remove()
                    vc.dismiss(animated: true, completion: {
                        if image == nil {
                            self.showAlert(
                                title: BundleI18n.QRCode.Lark_Legacy_Hint,
                                message: BundleI18n.QRCode.Lark_Legacy_NetworkOrServiceError,
                                handler: { (_) in
                                    self.startSession()
                                }
                            )
                            return
                        }

                        if let result = result {
                            self.didScanQRCode(dataStr: result, from: .album)
                        } else {
                            self.showAlert(
                                title: BundleI18n.QRCode.Lark_Legacy_Hint,
                                message: BundleI18n.QRCode.Lark_Legacy_QrCodeNotFound,
                                handler: { (_) in
                                    self.startSession()
                                }
                            )
                        }
                    })
                }
            }
        }
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true)
        self.stopSession()
    }

    private func configCaptureDevice() {
        lockCaptureDeviceConfiguration { (captureDevice) in
            if captureDevice.isFocusModeSupported(.continuousAutoFocus) {
                captureDevice.focusMode = .continuousAutoFocus
            }

            if captureDevice.isExposureModeSupported(.continuousAutoExposure) {
                captureDevice.exposureMode = .continuousAutoExposure
            }
            if let supportedFrameRange = captureDevice.activeFormat.videoSupportedFrameRateRanges.first {
                if 20 <= supportedFrameRange.maxFrameRate {
                    captureDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 20)
                    captureDevice.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: 20)
                }
            }
        }
    }

    private var zoomFactor: CGFloat = 1.0
    @objc
    private func pinchGestureInvoked(pinch: UIPinchGestureRecognizer) {
        guard let device = captureDevice else { return }

        // 8是个经验值，表示最大放大倍数不超过8
        let maxFactor = min(8, device.activeFormat.videoMaxZoomFactor)
        func minMaxZoom(_ factor: CGFloat) -> CGFloat { return min(max(factor, 1.0), maxFactor) }

        let currentScale = minMaxZoom(pinch.scale * zoomFactor)
        let videoScale = minMaxZoom((currentScale - 1) * (currentScale - 1) * 0.6 + 1)

        switch pinch.state {
        case .began, .changed:
            lockCaptureDeviceConfiguration { (device) in
                device.videoZoomFactor = videoScale
            }
        case .ended:
            zoomFactor = currentScale
            lockCaptureDeviceConfiguration { (device) in
                device.videoZoomFactor = videoScale
            }
        default: break
        }
    }

    private func lockCaptureDeviceConfiguration(action: @escaping (AVCaptureDevice) -> Void) {
        sessionQueue.async {
            guard let captureDevice = self.captureDevice else {
                return
            }
            do {
                try captureDevice.lockForConfiguration()
                action(captureDevice)
                captureDevice.unlockForConfiguration()
            } catch {
                self.lifeCircle?.onError(error)
                QRCodeViewController.logger.error("lock captureDevice configuartion fail", error: error)
            }
        }
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard !isSessionLocked.value else { return }
        readyOnceToken.once {
            self.lifeCircle?.onCameraReady(state: .end)
        }
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        guard let result = qrCodeDecoder?.scanVideoPixelBuffer(pixelBuffer) else {
            return
        }

        if let sessionStartTimeStamp = sessionStartTimeStamp {
            let timeInterval = (CFAbsoluteTimeGetCurrent() - sessionStartTimeStamp) * 1000
            Tracker.post(TeaEvent(Homeric.SCAN_QRCODE_FIRST_FRAME_TIME,
                                  params: ["time": "\(timeInterval)"]))
            self.sessionStartTimeStamp = nil
        }

        numberOfFramesBeforeScanSucceed += 1
        if result.type == .found, let code = result.code {
            Tracker.post(TeaEvent(Homeric.SCAN_QRCODE_FRAME,
                                  params: ["frames": numberOfFramesBeforeScanSucceed]))
            self.stopSession()
            DispatchQueue.main.async {
                self.isViewDidAppeared
                    .filter({ $0 })
                    .take(1)
                    .subscribe(onNext: { [weak self] (appeared) in
                    if appeared {
                        self?.didScanQRCode(dataStr: code, from: .camera)
                    }
                }).disposed(by: self.disposeBag)
            }
        } else if result.type == .zoom, let scale = result.resizeFactor?.floatValue {
            lockCaptureDeviceConfiguration { (device) in
                var newScale = device.videoZoomFactor + CGFloat(scale)
                // 8是个经验值，表示最大放大倍数不超过8
                let maxFactor = min(8, device.activeFormat.videoMaxZoomFactor)
                newScale = max(1.0, newScale)
                newScale = min(maxFactor, newScale)
                device.ramp(toVideoZoomFactor: newScale, withRate: 5)
            }
        }
    }
}

extension QRCodeViewController: MediaResourceInterruptionObserver {
    public func mediaResourceWasInterrupted(by scene: LarkMedia.MediaMutexScene, type: LarkMedia.MediaMutexType, msg: String?) {
        DispatchQueue.main.async { [weak self] in
            self?.navigationController?.popViewController(animated: false)
        }
        Self.logger.info("mediaResourceWasInterrupted: occupied by \(scene) type is \(type) msg: \(msg)")
    }

    public func mediaResourceInterruptionEnd(from scene: LarkMedia.MediaMutexScene, type: LarkMedia.MediaMutexType) {
        Self.logger.info("mediaResourceInterruptionEnd: release by \(scene) type is \(type)")
    }
}
