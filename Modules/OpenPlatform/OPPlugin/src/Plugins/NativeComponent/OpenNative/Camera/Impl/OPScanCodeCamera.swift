//
//  OPScanCodeCamera.swift
//  OPPlugin
//
//  Created by baojianjun on 2022/11/15.
//

import LarkOpenAPIModel
import LarkSetting
import LarkWebviewNativeComponent
import LKCommonsLogging
import TTVideoEditor
import ECOProbe
import OPSDK
import OPFoundation

final class OPScanCodeCamera: NSObject {
    
    // MARK: - Properties
    
    let resolution: CameraResolution
    
    let scanCodeType: CameraScanCodeType
    
    let devicePosition: CameraDevicePosition = .back
    
    private(set) var flash: CameraFlash
    
    private var frame: CGRect
    
    private var scanSession: VEScan?
    private weak var delegate: OPCameraComponentDelegate?
    
    let preview: OPCameraPreview
    private let uniqueID: OPAppUniqueID
    
    private var maxCameraZoomFactor: Double?
    private var currentZoom: Double?
    private var lumaScene: Int32?
    private var lastTimeStamp: TimeInterval
    
    private var isCapture = false
    private var active = true
    private var rotationMode: HTSGLRotationMode
    
    static let logger = Logger.oplog(OPScanCodeCamera.self, category: "LarkWebviewNativeComponent")
    
    // MARK: - LifeCycle
    
    init(params: OpenNativeCameraInsertParams, uniqueID: OPAppUniqueID) throws {
        self.resolution = params.resolution
        self.flash = params.flash
        self.scanCodeType = params.scanCodeType
        self.uniqueID = uniqueID
        
        let frame = params.style?.frame() ?? CGRect.zero
        self.frame = frame
        self.preview = OPCameraPreview(frame: frame)
        
        self.lastTimeStamp = NSDate().timeIntervalSince1970 * 1000
        
        self.rotationMode = getInterfaceOrientation().rotationMode()
        
        super.init()
        
        try self.createScanSession()
        
        Self.logger.info("init, uniqueID: \(uniqueID.fullString)")
    }
    
    deinit {
        Self.logger.info("deinit, uniqueID: \(uniqueID.fullString)")
        destory()
    }
    
    private func createScanSession() throws {
        guard let scanSession = VEScan.create() else {
            let errno = OpenNativeCameraErrnoFireEvent.cameraInitError
            throw OpenAPIError(errno: errno)
        }
        
        scanSession.custom(with: self, preview: self.preview, resolution: self.resolution, scanCodeType: self.scanCodeType)
        // 校正初始旋转方向
        scanSession.setPreviewRotationMode(rotationMode)
        
        openCamera(scanSession: scanSession)
        
        self.scanSession = scanSession
    }
    
    private func openCamera(scanSession: VEScan) {
        let result = scanSession.openCamera(withPrivacyCert: OPSensitivityEntryToken.OPScanCodeCamera_openCamera.psdaToken)
        if result != 0 {
            // error
            Self.logger.error("[createScanSession], openCamera \(result)")
        }
        scanSession.start()
    }
}

// MARK: - OPCameraNativeProtocol
extension OPScanCodeCamera: OPCameraNativeProtocol {
    func destory() {
        Self.logger.info("destory, active: \(active), uniqueID: \(uniqueID.fullString)")
        if active {
            scanSession?.stop()
            scanSession?.stopCamera()
        }
        
        if self.scanSession != nil {
            VEScan.release()
            self.scanSession = nil
        }
        preview.removeFromSuperview()
    }
    
    func startCaptureIfNeeded() {
        Self.logger.info("startCapture, uniqueID: \(uniqueID.fullString), active: \(active)")
        guard !active else {
            return
        }
        active = true
        
        if let scanSession = self.scanSession {
            openCamera(scanSession: scanSession)
            return
        }
        
        do {
            try self.createScanSession()
            Self.logger.info("startCapture, uniqueID: \(uniqueID.fullString), active: \(active)")
        } catch let error {
            Self.logger.error("startCapture failed, uniqueID: \(uniqueID.fullString), active: \(active), error: \(error)")
        }
    }
    
    func viewWillDisappear() {
        Self.logger.info("stopCapture, uniqueID: \(uniqueID.fullString), active: \(active)")
        active = false // 防止后台小程序释放时，导致前台camera停止采集
        scanSession?.stop()
        scanSession?.stopCamera()
    }
    
    func viewDidDisappear() {
        // VE扫码接口是类接口, 会和飞书本身扫一扫相冲突, 因此退出页面即需要调用release, 回到页面时需重新设置相机
        VEScan.release()
        scanSession = nil
    }
    
    func onDeviceOrientationChange(_ orientation: UIDeviceOrientation) {
        guard active else { return }
        let rotationMode = getInterfaceOrientation().rotationMode()
        Self.logger.info("onDeviceOrientationChange, current: \(rotationMode), old state is \(self.rotationMode)")
        guard rotationMode != self.rotationMode else {
            return
        }
        self.rotationMode = rotationMode
        scanSession?.setPreviewRotationMode(rotationMode)
    }
}

// MARK: - OPCameraPreviewDelegate
extension OPScanCodeCamera: OPCameraPreviewDelegate {
    func didPinch(scale: CGFloat, state: UIGestureRecognizer.State) {
        guard let maxCameraZoomFactor = maxCameraZoomFactor,
        let currentZoom = currentZoom else {
            return
        }

        let maxFactor = maxCameraZoomFactor
        func minMaxZoom(_ factor: CGFloat) -> CGFloat { return min(max(factor, 1.0), maxFactor) }
        let currentScale = minMaxZoom(scale * currentZoom)
        let videoScale = minMaxZoom((currentScale - 1) * (currentScale - 1) * 0.6 + 1)
        switch state {
        case .began, .changed:
            scanSession?.setScanZoomWithScale(Float(videoScale))
        case .ended:
            self.currentZoom = currentScale
            scanSession?.setScanZoomWithScale(Float(videoScale))
        default: break
        }
    }
    
    func frameDidChange(_ frame: CGRect) {
        self.frame = frame
    }
}

// MARK: - VEScanDelegate
extension OPScanCodeCamera: VEScanDelegate {
    
    func scan(_ scaner: VEScan?, onScanCompleteWith result: VEScanQRCodeResult?) {
        if scanCodeType == .continuous { // 限制频率
            let current = NSDate().timeIntervalSince1970 * 1000
            if current - lastTimeStamp >= 250 {
                lastTimeStamp = current
            } else {
                return
            }
        }
        
        guard let result = result else {
            // 无result
            Self.logger.error("onScanCompleteWith result is nil")
            return
        }
        
        guard let content = result.content else {
            // 无content
            Self.logger.error("onScanCompleteWith content is nil")
            return
        }
        
        if let error = result.error {
            Self.logger.error("onScanCompleteWith error: \(error), \(error.localizedDescription)")
            return
        }
        
        let type = result.codeType.type()
        Self.logger.info("scan onScanCompleteWith type: \(type), content: \(content)")
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.bindScanCode(result: .init(type: type, result: content))
        }
    }
    
    // 回调根据配置 setLumaDetectInterval 决定，较频繁，不打日志
    func scan(_ scaner: VEScan?, onRecLumaDetectResult result: VELumaDetectResult) {
        guard result.error == nil else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.onLumaDetect(scene: result.scene)
        }
    }
    
    private func onLumaDetect(scene: Int32) {
        if scene == lumaScene {
            return // 去重
        }
        lumaScene = scene
        delegate?.bindLumaDetect(result: .init(scene: Int(scene)))
        Self.logger.info("onLumaDetect, scene: \(scene)")
    }
    
    func scan(_ scaner: VEScan?, onRecCaptureSessionEvent type: VE_CAPTURE_SESSION_EVENT_TYPE) {
        // com.ies.vesdk.iesmmcapturekit线程派发，注意处理的线程
        Self.logger.info("scan onRecCaptureSessionEvent: \(type)")
        DispatchQueue.main.async { [weak self] in
            switch type {
            case .CAPTURE_SESSION_EVENT_DIDSTART: fallthrough
            case .CAPTURE_SESSION_EVENT_INTERRUPTEND:
                self?.didStartVideoCapture()
            case .CAPTURE_SESSION_EVENT_DIDSTOP: fallthrough
            case .CAPTURE_SESSION_EVENT_INTERRUPTED:
                self?.didStopVideoCapture()
            case .CAPTURE_SESSION_EVENT_OTHER: fallthrough
            @unknown default:
                break
            }
        }
    }
    
    private func didStartVideoCapture() {
        guard isCapture == false, let scanSession = scanSession else {
            return
        }
        isCapture = true
        let maxZoom = Double(scanSession.maxZoomFactor())
        maxCameraZoomFactor = maxZoom
        currentZoom = 1
        scanSession.enableTorch(self.flash.enable())
        self.preview.delegate = self
        delegate?.bindInitDone(params: .init(maxZoom: maxZoom, devicePosition: .back))
        Self.logger.info("didStartVideoCapture, maxZoom: \(maxZoom)")
    }
    
    private func didStopVideoCapture() {
        guard isCapture else {
            return
        }
        isCapture = false
        delegate?.bindStop()
        Self.logger.info("didStopVideoCapture")
    }
}

// MARK: - OPCameraComponent
extension OPScanCodeCamera: OPCameraComponent {
    
    func set(delegate: OPCameraComponentDelegate) {
        self.delegate = delegate
    }
    
    func update(params: OpenNativeCameraUpdateParams, trace: OPTrace) {
        Self.logger.info("update, uniqueID: \(uniqueID.fullString)")
        
        if let flash = params.flash,
           flash.enable() != self.flash.enable() {
            trace.info("update flash, from \(self.flash) to \(flash)")
            self.flash = flash
            scanSession?.enableTorch(flash.enable())
        }
    }
    
    func takePhoto(params: OpenNativeCameraTakePhotoParams, context: OpenPluginNativeComponent.Context, callback: @escaping (OpenComponentBaseResponse<OpenNativeCameraTakePhotoResult>) -> Void) {
        callback(.failure(error: OpenNativeCameraErrnoDispatchAction.notAllowedError(.takePhoto)))
    }
    
    func setZoom(params: OpenNativeCameraSetZoomParams, context: OpenPluginNativeComponent.Context, callback: @escaping (OpenComponentBaseResponse<OpenNativeCameraSetZoomResult>) -> Void) {
        let zoom = params.zoom.adapter(with: maxCameraZoomFactor)
        scanSession?.setScanZoomWithScale(Float(zoom))
        callback(.success(data: .init(zoom: zoom)))
    }
    
    func startRecord(params: OpenNativeCameraStartRecordParams, context: OpenPluginNativeComponent.Context, callback: @escaping (OpenComponentBaseResponse<OpenComponentBaseResult>) -> Void) {
        callback(.failure(error: OpenNativeCameraErrnoDispatchAction.notAllowedError(.startRecord)))
    }
    
    func stopRecord(params: OpenNativeCameraStopRecordParams, context: OpenPluginNativeComponent.Context, callback: @escaping (OpenComponentBaseResponse<OpenNativeCameraStopRecordResult>) -> Void) {
        callback(.failure(error: OpenNativeCameraErrnoDispatchAction.notAllowedError(.stopRecord)))
    }
}

fileprivate extension VEScan {
    func custom(with delegate: VEScanDelegate, preview: UIView, resolution: CameraResolution, scanCodeType: CameraScanCodeType) {
        // create
        let codeType: UInt =
        VE_CODE_TYPE.CODE_TYPE_QRCODE.rawValue |
        VE_CODE_TYPE.CODE_TYPE_VORTEX_CODE.rawValue |
        VE_CODE_TYPE.CODE_TYPE_I2of5_CODE.rawValue |
        VE_CODE_TYPE.CODE_TYPE_UPC_E_CODE.rawValue |
        VE_CODE_TYPE.CODE_TYPE_EAN_8_CODE.rawValue |
        VE_CODE_TYPE.CODE_TYPE_EAN_13_CODE.rawValue |
        VE_CODE_TYPE.CODE_TYPE_CODE39_CODE.rawValue |
        VE_CODE_TYPE.CODE_TYPE_CODE128_CODE.rawValue |
        VE_CODE_TYPE.CODE_TYPE_DATA_MATRIX.rawValue |
        VE_CODE_TYPE.CODE_TYPE_PDF_417.rawValue
        enableCodeTypes(codeType)
        setScanDelegate(delegate)
        
        // config
        let bundle = BundleConfig.OPPluginBundle
        if let string = bundle.path(forResource: "scan_camera_graph_config", ofType: "json", inDirectory: "Config"),
           let content = try? String(contentsOfFile: string) {// lint:disable:this lark_storage_check
            setEnigmaConfig(content, sourceType: ETEEnigmaSourceCamera)
        }
        
        let nativeResolution = OpenNativeCameraComponent.getResolution(with: resolution)
        let config = getDefaultCameraConfig()
        config.sessionMode = .normal
        config.capturePreset = nativeResolution
        setCameraPreviewView(preview, with: config)
        
        setLumaDetectInterval(500)
        enableLumaDetect(true)
        setScanCodeBehavior(scanCodeType.veBehavior())
        enableEnigmaScanSource(ETEEnigmaSourceCamera)
    }
}

fileprivate extension CameraFlash {
    /// scanCode模式下, 这两种状态为手电筒打开
    func enable() -> Bool {
        return .torch == self || .on == self
    }
}



fileprivate extension CameraScanCodeType {
    func veBehavior() -> VEScanCodeBehavior {
        switch self {
        case .continuous:
            return VEScanCodeContinue
        case .single:
            return VEScanCodeOnce
        }
    }
}

fileprivate extension VE_CODE_TYPE {
    func type() -> String {
        switch self {
        case .CODE_TYPE_QRCODE:
            return "QR_CODE"
        case .CODE_TYPE_VORTEX_CODE:
            return "VORTEX_CODE"
        case .CODE_TYPE_I2of5_CODE:
            return "I2of5_CODE"
        case .CODE_TYPE_UPC_E_CODE:
            return "UPC_E_CODE"
        case .CODE_TYPE_EAN_8_CODE:
            return "EAN_8_CODE"
        case .CODE_TYPE_EAN_13_CODE:
            return "EAN_13_CODE"
        case .CODE_TYPE_CODE39_CODE:
            return "CODE39_CODE"
        case .CODE_TYPE_CODE128_CODE:
            return "CODE128_CODE"
        case .CODE_TYPE_DATA_MATRIX:
            return "DATA_MATRIX"
        case .CODE_TYPE_PDF_417:
            return "PDF_417"
        default:
            return "UNKNOWN"
        }
    }
}
