//
//  VEQRCodeViewController.swift
//  QRCode
//
//  Created by Yuri on 2022/4/22.
//

import Foundation
import UIKit
import LarkUIKit
import LarkFoundation
import TTVideoEditor
import LKCommonsLogging
import RxSwift
import RxCocoa
import LKCommonsTracker
import Homeric
import EEAtomic
import LarkAssetsBrowser
import UniverseDesignDialog
import CommonCrypto
import AVFoundation
import LarkMedia
import LarkSetting
import UniverseDesignToast

final class AirClassPenetrateView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let res = super.hitTest(point, with: event)
        if res == self { return nil }
        return res
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

open class ScanCodeViewController: BaseUIViewController, ScanCodeViewControllerType {

    public typealias ScanResultData = (String, ScanType, String?)

    public typealias QRError = QRScanError

    public var supportTypes: [ScanType]?

    public var didScanSuccessHandler: ((String, ScanType) -> Void)?

    public var didScanFailHandler: ((QRError) -> Void)?

    public var didManualCancelHandler: ((ScanType) -> Void)?

    public var didScanQRCodeBlock: ((String, VEQRCodeFromType) -> Void)?

    public weak var delegate: QRCodeViewControllerDelegate?

    public var lifeCircle: QRCodeViewControllerLifeCircle?

    public var firstDescribelText: String?
    public var secondDescribelText: String?

    private let naviBar: TitleNaviBar = TitleNaviBar(titleString: BundleI18n.QRCode.Lark_Legacy_LarkScan)
    private lazy var contentView: ScanCodeContentView = { ScanCodeContentView() }()
    public lazy var customView: UIView = { AirClassPenetrateView() }()
    private var imageScanLoading: UDToast?
    private var isFirstFrameToken = AtomicOnce()

    /// 标记相机选择后如果是多码识别此时回到相机页不需要启动相机
    public var isNoNeedStartCamera: Bool = false

    private static let moreScanCodeTag: Int = 1

    @FeatureGatingValue(key: "core.scan_qrcode.ve") private var veScanEnable: Bool //Global 后续会全量，等全量后再删掉
    /// 是否需要关闭AV扫码重复结果过滤优化逻辑
    @FeatureGatingValue(key: ScanQRCodeFeatureKey.distinctEnableClose.key) private var distinctEnableClose: Bool

    private lazy  var scanner: CodeScannerType = {
        if veScanEnable {
            return VECodeScanner(previewView: self.contentView.videoPreviewView)
        } else {
            return AVCodeScanner(previewView: self.contentView.videoPreviewView)
        }
    }()

    private let logLock = NSLock()
    private let logger = Logger.log(ScanCodeViewController.self)

    private var isViewDidAppeared = BehaviorRelay(value: false)
    private let disposeBag = DisposeBag()

    private var numberOfFramesBeforeScanSucceed: Int = 0
    private var isFirstTorchAppear: Bool = true
    private var sessionStartTimeStamp: CFAbsoluteTime?

    private let readyOnceToken = AtomicOnce()
    private var isFullScreen: Bool

    /// 标记是否正在执行页面跳转，防止临近时间同时执行页面跳转操作，导致冻屏
    private var executingPageSkip: Bool = false

    private(set) lazy var backButton: UIButton = {
        let backButton = UIButton(type: .custom)
        backButton.titleLabel?.font = UIFont.ud.title3
        backButton.setTitleColor(UIColor.ud.staticWhite, for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return backButton
    }()

    public init(
        supportTypes: [ScanType] = [.all],
        didScanSuccessHandler: ((String, ScanType) -> Void)? = nil,
        didScanFailHandler: ((QRError) -> Void)? = nil,
        didManualCancelHandler: ((ScanType) -> Void)? = nil,
        isFullScreen: Bool = true
    ) {
        self.supportTypes = supportTypes
        self.didScanSuccessHandler = didScanSuccessHandler
        self.didScanFailHandler = didScanFailHandler
        self.didManualCancelHandler = didManualCancelHandler
        self.isFullScreen = isFullScreen
        super.init(nibName: nil, bundle: nil)
        setupSupportTypes()
        startupQRScaner()
        tryOpenCamera()
        sessionStartTimeStamp = CFAbsoluteTimeGetCurrent()
        logger.info("ScanCode.ScanVC: init")
    }

    /**
     * @deprecated use init(
                    supportTypes: [ScanType] = [.all],
                    didScanSuccessHandler: ((String, ScanType) -> Void)? = nil,
                    didScanFailHandler: ((QRError) -> Void)? = nil),
                    didManualCancelHandler: ((ScanType) -> Void)? = nil)
     *             instead
     */
    public init(
        type: ScanCodeType = .qrCode,
        lifeCircle: QRCodeViewControllerLifeCircle? = nil,
        isFullScreen: Bool = true
    ) {
        self.lifeCircle = lifeCircle
        lifeCircle?.onInit(state: .start)
        defer {
            lifeCircle?.onInit(state: .end)
        }
        self.isFullScreen = isFullScreen
        super.init(nibName: nil, bundle: nil)
        startupQRScaner()
        tryOpenCamera()
        sessionStartTimeStamp = CFAbsoluteTimeGetCurrent()
        logger.info("ScanCode.ScanVC: init")
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

    deinit {
        logger.info("ScanCode.ScanVC: deinit")
        VEScan.release()
        NotificationCenter.default.removeObserver(self)
    }

    override open func viewDidLoad() {
        lifeCircle?.onViewDidLoad(state: .start)
        defer {
            lifeCircle?.onViewDidLoad(state: .end)
        }
        super.viewDidLoad()
        Tracker.post(TeaEvent("qrcode_open_scan_dev",
                                  params: ["vesdk_enabled": (veScanEnable ? "true" : "false")]))
        setupView()

        func addObserver(with name: NSNotification.Name?) {
            NotificationCenter.default.addObserver(self, selector: #selector(updateUIInMainThread), name: name, object: nil)
        }

        let pinchGesture = UIPinchGestureRecognizer()
        self.view.addGestureRecognizer(pinchGesture)
        pinchGesture.addTarget(self, action: #selector(self.pinchGestureInvoked(pinch:)))
        cameraScannerStart()
        scanner.scanerCameraCaptureFrameHandler = { [weak self] in
            self?.recordCaptureFrame()
        }

        if Display.pad {
            addObserver(with: .AVCaptureSessionWasInterrupted)
            addObserver(with: .AVCaptureSessionInterruptionEnded)
            addObserver(with: .AVCaptureSessionDidStartRunning)
            addObserver(with: .AVCaptureSessionDidStopRunning)
        }
        isViewDidAppeared.filter { $0 }.take(1)
            .subscribe(onNext: { [weak self] _ in
                self?.updateUIWhenCaptureSession()
            }).disposed(by: disposeBag)
        setupCameraScanFlow()
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        scanner.scanerLumaDetectHandler = { [weak self] (lumaResult)in
            guard let self = self else { return }
            DispatchQueue.main.async(execute: {
                if lumaResult == 0 {
                    self.contentView.torchButton.isHidden = false
                    guard self.isFirstTorchAppear else { return }
                    self.isFirstTorchAppear = false
                    self.contentView.setTorchBlinking()
                } else {
                    UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
                        self.contentView.torchButton.isHidden = true
                    }
                }
            })
        }
        scanner.scanerSuspend = { [weak self] (isSuspend) in
            guard let self = self else { return }
            self.scanerSuspend(isSuspend)
        }
    }

    private func scanerSuspend(_ isSuspend: Bool) {
        if isSuspend {
            self.contentView.scanMaskView.pauseScan()
            self.scanner.stopCamera()
            self.scanner.stopScanner()
        } else {
            self.contentView.scanMaskView.resumeScan()
            self.startScanning()
        }
    }

    private func setupCameraScanFlow() {
        if !veScanEnable, !distinctEnableClose {
            isViewDidAppeared.filter { $0 }
                .take(1)
                .flatMapLatest {
                    [weak self] _ -> Observable<CameraScanSingleObservableResult> in
                    guard let self = self else { return  .just(("", .unkonwn, nil))}
                    return self.scanner.cameraScanObservable
                }.observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] result in
                    // 处理扫码结果
                    self?.handleScanResult(result: result)
                }).disposed(by: disposeBag)
        } else {
            Observable.combineLatest(isViewDidAppeared.filter { $0 }.take(1), // 确保ViewDidAppeared才处理扫码结果
                                     scanner.cameraScanObservable)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_, result) in
                self?.handleScanResult(result: result)
            }).disposed(by: disposeBag)
        }
        Observable.combineLatest(isViewDidAppeared.filter { $0 }.take(1), // 确保ViewDidAppeared才处理扫码结果
                                 scanner.cameraScanMulticodeObservable)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_, codeInfo) in
                let (codeItems, image, cropRect, lensName) = codeInfo
                self?.handleMulticodeScanResult(codeItems: codeItems, image: image, lensName: lensName, cropRect: cropRect)
            }).disposed(by: disposeBag)
    }

    private func setupImageScanFlow() {
        logger.info("ScanCode.ScanVC: start image picker")
        let picker = ImagePickerViewController(assetType: .imageOnly(maxCount: 9),
                                               sendButtonTitle: BundleI18n.QRCode.Lark_Legacy_ConfirmSure)
        let uiClearHandler: ((@escaping () -> Void) -> Void) = { [weak self, weak picker] in
            self?.imageScanLoading?.remove()
            self?.imageScanLoading = nil
            picker?.dismiss(animated: true, completion: $0)
        }
        scanner.switchToImageMode()
        picker.selectImage()
            .do(onNext: { [weak self, weak picker] (_) in
                guard let picker = picker, let self = self else { return }
                self.imageScanLoading = UDToast.showLoading(with: BundleI18n.QRCode.Lark_Legacy_BaseUiLoading, on: picker.view, disableUserInteraction: true)
                Tracker.post(TeaEvent("scan_code_click_album",
                                      params: ["vesdk_enabled": (self.veScanEnable ? "true" : "false")]))
            })
            .flatMap { [weak self] (result) -> Observable<ImageScanObservableResult> in
                self?.isNoNeedStartCamera = true
                let error = QRError.pickerCancel
                let scan = self?.scanner.scan(image: result) ?? .error(error)
                return scan
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] res in
                let (codeItems, image) = res
                guard let self = self, !codeItems.isEmpty else { return }
                uiClearHandler {
                    if codeItems.count == Self.moreScanCodeTag, let codeItem = codeItems.first {
                        self.logger.info("call back scan image single code")
                        self.didScanQRCode(result: (codeItem.content, codeItem.type, nil), from: .album)
                    } else {
                        // 多二维码处理
                        self.logger.info("call back scan image multi pickcode")
                        self.displayMultiPickcode(codeItems: codeItems, image: image, cropRect: nil, lensName: nil, from: .album)
                    }
                }
            },
                onError: { [weak self] error in
                guard let self = self else { return }
                self.isNoNeedStartCamera = false
                self.imageScanLoading?.remove()
                self.imageScanLoading = nil
                uiClearHandler {
                    self.handleImageScanError(error)
                }
            }, onDisposed: { [weak self] in
                self?.scanner.switchToCameraMode()
            })
            .disposed(by: disposeBag)
        present(picker, animated: true)
    }

    private func handleScanResult(result: ScanResultData) {
        logLock.lock()
        Tracker.post(TeaEvent(Homeric.SCAN_QRCODE_FRAME,
                                  params: ["frames": self.numberOfFramesBeforeScanSucceed]))
        logLock.unlock()
        didScanQRCode(result: result, from: .camera)
    }
    
    /// 扫一扫多码识别结果处理
    private func handleMulticodeScanResult(codeItems: [CodeItemInfo], image: UIImage?, lensName: String?, cropRect: CGRect) {
        logger.info("handle multicode scan result count:\(codeItems.count) imageIsEmpty:\(String(describing: image)) cropRect:\(String(describing: cropRect))")
        contentView.switchToMulticodeResultStyle()
        guard let img = image else {
            logger.info("handle multicode scan result image is nil, direct jump first code result page")
            if let codeItem = codeItems.first {
                handleScanResult(result: (codeItem.content, codeItem.type, lensName))
            }
            return
        }
        self.displayMultiPickcode(codeItems: codeItems, image: img, cropRect: cropRect, lensName: lensName, from: .camera, animated: true)
    }

    private func displayMultiPickcode(codeItems: [CodeItemInfo], image: UIImage, cropRect: CGRect?, lensName: String?, from: VEQRCodeFromType, animated: Bool = false) {
        logger.info("display multi pickcode count:\(codeItems.count) cropRect:\(String(describing: cropRect))")
        guard !executingPageSkip else {
            logger.info("executing page skip,not allow open multiQRCode page")
            return
        }
        executingPageSkip = true
        var imageInfo = MultiQRCodeScanner.ImageInfos(image: .uiImage(image))
        imageInfo.visibleRect = cropRect
        if animated {
            imageInfo.needAppearAnimation = true
        }
        MultiQRCodeScanner.pickCode(image: imageInfo, from: self, codeInfos: codeItems, setting: SettingManager.shared) { [weak self] codeItemInfo in
            self?.executingPageSkip = false
            guard let codeItem = codeItemInfo else {
                self?.isNoNeedStartCamera = false //恢复标记值
                self?.resumeScanCameraStyle()
                self?.scanner.cancelReSanner()
                return
            }
            self?.handleScanMulticode(by: codeItem, from: from, lensName: lensName)
        }
    }
    
    /// 处理多码识别的选择结果后跳转
    /// - Parameter codeItem: 二维码信息
    private func handleScanMulticode(by codeItem: CodeItemInfo, from: VEQRCodeFromType, lensName: String?) {
        logger.info("select form multicode codeItem:\(codeItem.description)")
        didScanQRCode(result: (codeItem.content, codeItem.type, lensName), from: from)
    }

    private func handleImageScanError(_ error: Error) {
        logger.info("ScanCode.ScanVC: scan image error \(error)")
        guard let err = error as? QRError else { return }
        switch err {
        case .pickerError:
            didScanFailHandler != nil ? handleError(err) : showErrorAlert(error: BundleI18n.QRCode.Lark_Legacy_NetworkOrServiceError)
        case .imageScanFailure(_):
            didScanFailHandler != nil ? handleError(err) : showErrorAlert(error: BundleI18n.QRCode.Lark_Legacy_QrCodeNotFound)
        default:
            didScanFailHandler?(err)
            scanner.switchToCameraMode()
        }
    }
    
    /// 提供默认实现，调用block，也可以提供给子类override
    open func didScanQRCode(dataStr: String, from: VEQRCodeFromType) {
        didScanQRCodeBlock?(dataStr, from)
    }

    private func handleError(_ error: QRError) {
        didScanFailHandler?(error)
        scanner.switchToCameraMode()
    }

    private func showErrorAlert(error: String) {
        scanner.stopScanner()
        let alert = UDDialog()
        alert.setTitle(text: BundleI18n.QRCode.Lark_Legacy_Hint)
        alert.setContent(text: error, numberOfLines: 0)
        alert.addPrimaryButton(text: BundleI18n.QRCode.Lark_Legacy_Sure, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.scanner.startCameraScanner()
        })
        self.present(alert, animated: true)
    }

    @objc
    private func clickAlbumButton() {
        self.delegate?.didClickAlbum()
        setupImageScanFlow()
        contentView.cleanTorchButton()
        scanner.enableLumaDetect = true
    }

    @objc
    private func didEnterBackground() {
        self.contentView.cleanTorchButton()
        scanner.enableLumaDetect = true
    }

    @objc
    private func didBecomeActive() {
        guard !scanner.isTorchOn else { return }
        self.contentView.cleanTorchButton()
        scanner.lumaSence = 1
        scanner.enableLumaDetect = true
    }

    @objc
    private func clickTorchButton() {
        if let timer = contentView.timer {
            timer.invalidate()
            contentView.timer = nil
            contentView.torchButton.alpha = 1
        }
        contentView.torchButton.isSelected = !contentView.torchButton.isSelected
        scanner.enableLumaDetect = !contentView.torchButton.isSelected
        if contentView.torchButton.isSelected {
            contentView.torchButton.isHidden = false
            scanner.lumaSence = 0
        }
        scanner.enableTorch(enable: contentView.torchButton.isSelected)
    }

    private func tryStartCaptureDevice() {
        if LarkFoundation.Utils.cameraPermissions() == false { // 无相机权限
            lifeCircle?.onError(QRCodeError.noCameraAccess)
            let dialog = UDDialog.noPermissionDialog(title: BundleI18n.QRCode.Lark_Core_CameraAccess_Title,
                                                     detail: BundleI18n.QRCode.Lark_Core_CameraAccessForScanCode_Desc())
            present(dialog, animated: true, completion: nil)
        }
        tryOpenCamera()
    }

    func openCamera() {
        if isFullScreen {
            scanner.openCamera()
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

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFullScreen()
        updateUIWhenCaptureSession()
        if isFullScreen {
            tryOpenCamera()
        } else {
            stopCamera()
        }
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if Display.pad && !isViewDidAppeared.value {
            self.updateUIWhenCaptureSession()
        }
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopCamera()
    }
    
    public func stopScanning() {
        scanner.stopScanner()
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scanner.isViewDidAppear = true
        isViewDidAppeared.accept(true)
        if !isNoNeedStartCamera {
            tryStartCaptureDevice()
        }
    }

    func backWayisPop() -> Bool {
        if (self.navigationController != nil), self.navigationController?.viewControllers.first != self {
            return true
        }
        return false
    }

    /// 提供默认实现，调用block，也可以提供给子类override
    open func didScanQRCode(result: ScanResultData, from: VEQRCodeFromType) {
        let dataStr = result.0
        let md5 = md5(code: dataStr)
        logger.info("ScanCode.ScanVC: scan result \(from) \(md5)")
        // completionHandler由开平传入，和didScanQRCodeBlock
        didScanSuccessHandler != nil ? didScanSuccessHandler?(dataStr, result.1) : didScanQRCodeBlock?(dataStr, from)
        let lensName = result.2 ?? ""
        addScanTracker(lensName: lensName, from: from)
    }

    private func addScanTracker(lensName: String, from: VEQRCodeFromType) {
        guard let sessionStartTimeStamp = sessionStartTimeStamp else { return }
        let timeInterval = Int((CFAbsoluteTimeGetCurrent() - sessionStartTimeStamp) * 1000)
        let scanSource: String
        switch from {
        case .album: scanSource = "album"
        case .camera: scanSource = "camera"
        }
        let scanEngimaType = scanner.isTripartiteEnigma ? "other" : "ve"
        Tracker.post(TeaEvent("qrcode_success_scan", params: ["time_consuming": timeInterval,
                                                              "vesdk_enabled": (veScanEnable ? "true" : "false"),
                                                              "scan_source": "\(scanSource)",
                                                              "lens_name": lensName,
                                                              "ve_scan_type": scanEngimaType
                                                            ]))
        self.sessionStartTimeStamp = nil
    }

    public func startScanning() {
        tryOpenCamera()
        cameraScannerStart()
    }

    private func cameraScannerStart() {
        lifeCircle?.onCameraReady(state: .start)
        numberOfFramesBeforeScanSucceed = 0
        scanner.startCameraScanner()
    }

    private func tryOpenCamera() {
        logger.info("ScanCode.ScanVC: MediaMutex tryLock")
        LarkMediaManager.shared.tryLock(scene: .imCamera, observer: self) { [weak self] (result) in
            guard let self = self else { return }
            self.logger.info("ScanCode.ScanVC: MediaMutex return result")
            DispatchQueue.main.async { [weak self] in
                switch result {
                case .success:
                    self?.openCamera()
                case .failure(let error):
                    if case let MediaMutexError.occupiedByOther(context) = error {
                        if let msg = context.1 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                self?.showMediaLockAlert(msg: msg)
                            }
                        }
                    }
                    self?.logger.error("try Lock failed \(error)")
                }
            }
        }
    }
    
    private func stopCamera() {
        guard scanner.isRunning else { return }
        scanner.stopCamera()
        LarkMediaManager.shared.unlock(scene: .imCamera)
    }

    @objc
    private func updateUIInMainThread() {
        if Thread.isMainThread {
            self.updateUIWhenCaptureSession()
        } else {
            DispatchQueue.main.async {
                self.updateUIWhenCaptureSession()
            }
        }
    }

    private func updateUIWhenCaptureSession() {
        let isInterrupted = scanner.isInterrupted
        let isRunning = scanner.isRunning
        if UIDevice.current.userInterfaceIdiom != .pad {
            return
        }
        contentView.updateViewBy(isInterrupted: isInterrupted,
                                 isRunning: isRunning,
                                 isFullScreen: isFullScreen)
    }

    @objc
    private func backButtonTapped() {
        guard !executingPageSkip else {
            logger.info("executing page skip,not allow back")
            return
        }
        executingPageSkip = true
        self.delegate?.didClickBack()
        self.didManualCancelHandler?(.unkonwn)
        if backWayisPop() {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }

    private func resumeScanCameraStyle() {
        contentView.switchToNormalScanStyle()
        self.scanerSuspend(false)
    }

    private func setupSupportTypes() {
        scanner.supportTypes = supportTypes ?? [.all]
    }

    private func startupQRScaner() {
        lifeCircle?.onCameraReady(state: .start)
        scanner.setupScanner()
    }

    private var zoomFactor: CGFloat = 1.0
    @objc
    private func pinchGestureInvoked(pinch: UIPinchGestureRecognizer) {
        func minMaxZoom(_ factor: Float) -> Float { return min(max(factor, 1.0), 8) }

        let currentScale = minMaxZoom(Float(pinch.scale * zoomFactor))
        let videoScale: Float = minMaxZoom((currentScale - 1) * (currentScale - 1) * 0.6 + 1)

        switch pinch.state {
        case .began, .changed:
            scanner.videoZoomFactor = videoScale
        case .ended:
            zoomFactor = CGFloat(currentScale)
            scanner.videoZoomFactor = videoScale
        default: break
        }
    }

    // MARK: - VEDelegate
    public func recordCaptureFrame() {
        DispatchQueue.main.async {
            self.readyOnceToken.once { [weak self] in
                guard let self = self else { return }
                self.lifeCircle?.onCameraReady(state: .end)
            }
        }
        logLock.lock()
        self.numberOfFramesBeforeScanSucceed += 1
        logLock.unlock()
        isFirstFrameToken.once {
            guard let sessionStartTimeStamp = self.sessionStartTimeStamp else { return }
            let timeInterval = Int((CFAbsoluteTimeGetCurrent() - sessionStartTimeStamp) * 1000)
            Tracker.post(TeaEvent("scan_qrcode_preview_first_frame_time_dev",
                                  params: ["cost_time_int": timeInterval,
                                           "vesdk_enabled": (veScanEnable ? "true" : "false"),
                                           "is_cold_launch": "unknown"]))
        }
    }

    // MARK: - UI
    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        contentView.frame = view.bounds
        customView.frame = view.bounds
        scanner.rotateSanner()
    }

    private func setupView() {
        view.addSubview(contentView)
        view.addSubview(customView)

        defer { view.bringSubviewToFront(self.naviBar) }
        setupNavibar()

        let tap = UITapGestureRecognizer(target: self, action: #selector(clickAlbumButton))
        contentView.albumContainerView.addGestureRecognizer(tap)

        contentView.torchButton.addTarget(self, action: #selector(clickTorchButton), for: .touchUpInside)

        if let text = firstDescribelText {
            contentView.firstDescribeLabel.text = text
            contentView.firstDescribeLabel.isHidden = false
        }

        if let text = secondDescribelText {
            contentView.secondDescribeLabel.text = text
            contentView.secondDescribeLabel.isHidden = false
        }
    }

    private func setupNavibar() {
        self.isNavigationBarHidden = true

        naviBar.backgroundColor = .clear
        (naviBar.titleView as? UILabel)?.textColor = UIColor.ud.primaryOnPrimaryFill
        self.view.addSubview(naviBar)
        naviBar.snp.makeConstraints { (make) in make.top.left.right.equalToSuperview()
        }

        // 返回按钮
        naviBar.addSubview(self.backButton)
        backButton.snp.makeConstraints({ (make) in
            make.width.equalTo(Cons.backButtonWidth)
            make.height.equalTo(Cons.backButtonWidth)
            make.bottom.equalTo(-Cons.backButtonBottom)
            make.left.equalTo(Cons.backButtonLeft)
        })
        setBackButton()
        
    }

    func setBackButton() {
        backButton.setTitle("", for: .normal)
        if backWayisPop() {
            backButton.setImage(Resources.navigation_back_white_light, for: .normal)
        } else {
            backButton.setImage(Resources.navigation_back_white_cross, for: .normal)
        }
        backButton.snp.updateConstraints { make in
            make.width.height.equalTo(Cons.backButtonWidth)
        }
    }

    private func md5(code: String) -> String {
        guard let data = code.data(using: .utf8) else {
            return ""
        }
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        _ = data.withUnsafeBytes { bytes in
            return CC_MD5(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    private func updateFullScreen() {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        let keyWindow = view.window
        if let currentWindow = keyWindow {
            isFullScreen = UIScreen.main.bounds == currentWindow.bounds
        }
    }
}

extension ScanCodeViewController {
    enum Cons {
        static var backButtonWidth: CGFloat { 24 }
        static var backButtonCancelWidth: CGFloat { 38 }
        static var backButtonLeft: CGFloat { 20 }
        static var backButtonBottom: CGFloat { 10 }
    }
}

extension ScanCodeViewController: MediaResourceInterruptionObserver {
    public func mediaResourceWasInterrupted(by scene: LarkMedia.MediaMutexScene, type: LarkMedia.MediaMutexType, msg: String?) {
        DispatchQueue.main.async { [weak self] in
            self?.navigationController?.popViewController(animated: false)
        }
        logger.info("mediaResourceWasInterrupted: occupied by \(scene) type is \(type)  msg: \(msg)")
    }

    public func mediaResourceInterruptionEnd(from scene: LarkMedia.MediaMutexScene, type: LarkMedia.MediaMutexType) {
        logger.info("mediaResourceInterruptionEnd: release by \(scene) type is \(type)")
    }
}
