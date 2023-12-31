//
//  OPNormalCamera.swift
//  OPPlugin
//
//  Created by baojianjun on 2022/6/29.
//

import ByteDanceKit
import UIKit
import LarkOpenAPIModel
import LarkWebviewNativeComponent
import LKCommonsLogging
import OPPluginManagerAdapter
import TTVideoEditor
import LarkSetting
import OPPluginBiz

// MARK: - OPCameraPreview
protocol OPCameraPreviewDelegate: AnyObject {
    func didPinch(scale: CGFloat, state: UIGestureRecognizer.State)
    func frameDidChange(_ frame: CGRect)
}

final class OPCameraPreview: UIView {
    weak var delegate: OPCameraPreviewDelegate?
    public override init(frame: CGRect) {
        super.init(frame: frame)
        let ges = UIPinchGestureRecognizer(target: self, action: #selector(viewDidPinch))
        addGestureRecognizer(ges)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func viewDidPinch(_ pinch: UIPinchGestureRecognizer) {
        delegate?.didPinch(scale: pinch.scale, state: pinch.state)
    }
    
    override var frame: CGRect {
        didSet {
            delegate?.frameDidChange(frame)
        }
    }
}

final class OPNormalCamera: OPCameraNativeProtocol {
    
    // MARK: - Properties
    
    let resolution: CameraResolution
    
    private(set) var devicePosition: CameraDevicePosition
    
    private(set) var flash: CameraFlash
    
    private var frame: CGRect
    
    private var camera: VERecorderPublicProtocol?
    private var cameraAction: IESCameraAction
    private weak var delegate: OPCameraComponentDelegate?
    
    let preview: OPCameraPreview
    private let uniqueID: OPAppUniqueID
    
    private var isCapture = false
    private var isRecord = false
    private var recordTimer: Timer?
    private var setZoomTimer: Timer?
    private var maxCameraZoomFactor: Double?
    private var currentZoom: CGFloat?
    
    private var outputSize = CGSize.zero
    private var interfaceOrientation: UIInterfaceOrientation
    
    static let logger = Logger.oplog(OPNormalCamera.self, category: "LarkWebviewNativeComponent")
    
    // MARK: - LifeCycle
    
    init(params: OpenNativeCameraInsertParams, uniqueID: OPAppUniqueID) {
        self.resolution = params.resolution
        self.devicePosition = params.devicePosition
        self.flash = params.flash
        self.uniqueID = uniqueID
        
        let frame = params.style?.frame() ?? CGRect.zero
        self.frame = frame
        self.preview = OPCameraPreview(frame: frame)
        
        self.cameraAction = .didStartVideoCapture
        
        self.interfaceOrientation = getInterfaceOrientation()
        
        let config = OpenNativeCameraComponent.customConfig()
        config.cameraPosition = OpenNativeCameraComponent.getCameraPosition(with: self.devicePosition)
        config.capturePreset = OpenNativeCameraComponent.getResolution(with: self.resolution)
        
        let camera = VERecorder.createRecorder(with: self.preview, config: config)
        
        camera.iesCameraActionBlock = { [weak self] action, error, data in
            executeOnMainQueueAsync {
                guard let self else { return }
                self.actionCallback(action: action, error: error, data: data)
            }
        }
        
        camera.setMaxZoomFactor(10) // 默认值是4, 设置范围大一些
        
        self.camera = camera
        
        resetFrameIfNeeded()
        resetOutputRotationMode(with: self.interfaceOrientation)
        
        startVideoCapture(camera: camera)
        Self.logger.info("init, uniqueID: \(uniqueID.fullString)")
    }
    
    private var active = true
    func destory() {
        Self.logger.info("destory, active: \(active), uniqueID: \(uniqueID.fullString)")
        if active {
            active = false
            camera?.cancelVideoRecord()
            camera?.stopVideoCapture()
            camera?.stopAudioCapture()
        }
        preview.removeFromSuperview()
        camera = nil
        recordTimer?.invalidate()
        recordTimer = nil
        setZoomTimer?.invalidate()
        setZoomTimer = nil
    }
    
    deinit {
        Self.logger.info("deinit, uniqueID: \(uniqueID.fullString)")
        destory()
    }
    
    func update(params: OpenNativeCameraUpdateParams, trace: OPTrace) {
        Self.logger.info("update, uniqueID: \(uniqueID.fullString)")
        guard let camera = camera else {
            let error = OpenAPIError(errno: OpenNativeCameraErrno.updateInternalError)
                .setCameraError(.noCamera)
            trace.error("update but cannot find camera", tag: "camera", additionalData: nil, error: error)
            return
        }
        if let devicePosition = params.devicePosition,
            devicePosition != self.devicePosition {
            trace.info("update devicePosition, from \(self.devicePosition) to \(devicePosition)")
            self.devicePosition = devicePosition
            camera.switchCameraSource()
            bindStop(source: .willChangeCameraDevice)
        }
        if let flash = params.flash,
           flash != self.flash {
            trace.info("update flash, from \(self.flash) to \(flash)")
            self.flash = flash
            camera.cameraFlashMode = OpenNativeCameraComponent.getFlash(with: flash)
            torchIfNeeded(with: flash, devicePosition: devicePosition)
        }
    }
    
    func startCaptureIfNeeded() {
        Self.logger.info("startCapture, uniqueID: \(uniqueID.fullString), active: \(active)")
        guard !active, let camera = camera else {
            return
        }
        active = true
        startVideoCapture(camera: camera)
    }
    
    private func startVideoCapture(camera: VERecorderPublicProtocol) {
        if let startVideoCapture = camera.startVideoCapture(withPrivacyCert:) {
            startVideoCapture(OPSensitivityEntryToken.OPNormalCamera_startVideoCapture.psdaToken)
        } else {
            camera.startVideoCapture()
        }
    }
    
    func viewWillDisappear() {
        Self.logger.info("stopCapture, uniqueID: \(uniqueID.fullString), active: \(active)")
        active = false // 防止后台小程序释放时，导致前台camera停止采集
        camera?.stopVideoCapture()
        if isRecord {
            camera?.stopAudioCapture()
            cleanRecordTimer()
            cleanRecordContext()
        }
    }
    
    func viewDidDisappear() { }
    
    func onDeviceOrientationChange(_ orientation: UIDeviceOrientation) {
        guard active else { return }
        let interfaceOrientation = getInterfaceOrientation()
        Self.logger.info("onDeviceOrientationChange, current: \(interfaceOrientation), old state is \(self.interfaceOrientation)")
        guard self.interfaceOrientation != interfaceOrientation else {
            return
        }
        self.interfaceOrientation = interfaceOrientation
        resetOutputRotationMode(with: self.interfaceOrientation)
        resetFrameIfNeeded()
    }
    
    private func resetOutputRotationMode(with interfaceOrientation: UIInterfaceOrientation) {
        camera?.outputDirection = interfaceOrientation.outputVideoOrientation()
        let rotationMode = interfaceOrientation.rotationMode()
        camera?.previewRotationMode = rotationMode
    }
}

// MARK: - OPCameraPreviewDelegate
extension OPNormalCamera: OPCameraPreviewDelegate {
    func didPinch(scale: CGFloat, state: UIGestureRecognizer.State) {
        guard let camera = camera,
        let maxCameraZoomFactor = maxCameraZoomFactor,
        let currentZoom = currentZoom else {
            return
        }
        
        let maxFactor = maxCameraZoomFactor
        func minMaxZoom(_ factor: CGFloat) -> CGFloat { return min(max(factor, 1.0), maxFactor) }
        let currentScale = minMaxZoom(scale * currentZoom)
        let videoScale = minMaxZoom((currentScale - 1) * (currentScale - 1) * 0.6 + 1)
        switch state {
        case .began, .changed:
            camera.cameraSetZoomFactor(videoScale)
        case .ended:
            self.currentZoom = currentScale
            camera.cameraSetZoomFactor(videoScale)
        default: break
        }
    }
    
    func frameDidChange(_ frame: CGRect) {
        self.frame = frame
        resetFrameIfNeeded()
    }
}

// MARK: - OPCameraComponent
extension OPNormalCamera: OPCameraComponent {
    
    func set(delegate: OPCameraComponentDelegate) {
        self.delegate = delegate
    }
    
    func takePhoto(params: OpenNativeCameraTakePhotoParams, context: OpenPluginNativeComponent.Context, callback: @escaping (OpenComponentBaseResponse<OpenNativeCameraTakePhotoResult>) -> Void) {
        let trace = context.trace
        trace.info("takePhoto, params: \(params.description)")
        guard let camera = camera else {
            let error = OpenAPIError(errno: OpenNativeCameraErrno.dispatchAction(.cameraInitError))
                .setCameraError(.noCamera)
            callback(.failure(error: error))
            return
        }
        
        let options = IESMMCaptureOptions()
        options.captureMode = .system
        options.forceUseCustomCaptureSize = true
        options.customCaptureSize = camera.outputSize
        camera.captureImage(with: options) { image, error in
            DispatchQueue.main.async { [weak self] in
                do {
                    guard let self = self else {
                        let error = OpenAPIError(errno: OpenNativeCameraErrno.dispatchAction(.internalError))
                            .setCameraError(.noSelf)
                        throw error
                    }
                    
                    if let error = error {
                        let apiError = OpenAPIError(errno: OpenNativeCameraErrno.dispatchAction(.takePhotoInnerError))
                            .setError(error)
                        throw apiError
                    }
                    
                    guard var image = image else {
                        let error = OpenAPIError(errno: OpenNativeCameraErrno.dispatchAction(.takePhotoInnerError))
                            .setMonitorMessage("photo is not exist")
                        throw error
                    }
                    
                    // 手动镜像
                    if self.devicePosition == .front, !params.selfieMirror {
                        image = image.withHorizontallyFlippedOrientation()
                        image = UIImage.btd_fixImgOrientation(image) ?? image
                    }
                    
                    let fsContext = FileSystem.Context(uniqueId: self.uniqueID,
                                                       trace: trace,
                                                       tag: "cameraTakePhoto")
                    
                    // 再图片压缩 + 保存图片
                    let quality = OpenNativeCameraComponent.getCompressionQuality(with: params.quality)
                    let result = try FileUtils.saveImage(image: image,
                                                         compressionQuality: quality,
                                                         fsContext: fsContext)
                    let param = OpenNativeCameraTakePhotoResult(tempImagePath: result.path)
                    callback(.success(data: param))
                } catch let error as FileUtils.SaveImageError {
                    let callbackError = OpenAPIError(errno: OpenNativeCameraErrno.dispatchAction(.takePhotoSaveFileError))
                        .setError(error)
                    callback(.failure(error: callbackError))
                } catch let error as OpenAPIError {
                    callback(.failure(error: error))
                } catch let error {
                    callback(.failure(error: OpenAPIError(errno: OpenNativeCameraErrno.dispatchAction(.takePhotoInnerError)).setError(error)))
                }
            }
        }
    }
    
    func setZoom(params: OpenNativeCameraSetZoomParams, context: OpenPluginNativeComponent.Context, callback: @escaping (OpenComponentBaseResponse<OpenNativeCameraSetZoomResult>) -> Void) {
        guard let camera = camera else {
            let error = OpenAPIError(errno: OpenNativeCameraErrno.dispatchAction(.cameraInitError))
                .setCameraError(.noCamera)
            callback(.failure(error: error))
            return
        }
        
        let zoom = params.zoom.adapter(with: maxCameraZoomFactor)
        
        // 上一次的setZoom尚未回调, 直接触发
        setZoomTimer?.fire()
        setZoomTimer = nil
        
        camera.cameraSetZoomFactor(CGFloat(zoom))
        
        let trace = context.trace
        
        let timer = Timer.bdp_scheduledTimer(withInterval: 1.0, target: self) {
            [weak self] _ in
            guard let self = self else { return }
            // 显式捕获callback
            self.fireSetZoom(trace: trace, callback: callback)
        }
        setZoomTimer = timer
    }
    
    func startRecord(params: OpenNativeCameraStartRecordParams, context: OpenPluginNativeComponent.Context, callback: @escaping (OpenComponentBaseResponse<OpenComponentBaseResult>) -> Void) {
        guard let camera = camera else {
            let error = OpenAPIError(errno: OpenNativeCameraErrno.dispatchAction(.cameraInitError))
                .setCameraError(.noCamera)
            callback(.failure(error: error))
            return
        }
        
        guard isCapture else {
            let error = OpenAPIError(errno: OpenNativeCameraErrno.dispatchAction(.startRecordInnerError))
                .setCameraError(.isNotCapture)
            callback(.failure(error: error))
            return
        }
        
        guard isRecord == false else {
            let error = OpenAPIError(errno: OpenNativeCameraErrno.dispatchAction(.recordAlreadyStarted))
            callback(.failure(error: error))
            return
        }
        cleanRecordTimer()
        isRecord = true
        
        let trace = context.trace
        let timeoutID = params.timeoutCallbackId
        let timer = Timer.bdp_scheduledTimer(withInterval: params.timeout, target: self) {
            [weak self] _ in
            self?.startRecordTimeout(timeoutID: timeoutID, trace: trace)
        }
        recordTimer = timer
        camera.startVideoRecord(withRate: 1.0)
        
        let startAudioCaptureCb: ((Bool, Error?) -> Void) = { success, error in
            // 此时trace已经finish了，不使用trace
            Self.logger.info("[startRecord], startAudioCapture finish \(success ? "success" : "fail"), trace_id: \(trace.traceId), \(error?.localizedDescription ?? "")")
        }
        let result = if let startAudioCapture = camera.startAudioCapture(_:withPrivacyCert:) {
            startAudioCapture(startAudioCaptureCb, OPSensitivityEntryToken.OPNormalCamera_startRecord.psdaToken)
        } else {
            camera.startAudioCapture(startAudioCaptureCb)
        }
        if !result {
            // 音频录制是否成功不影响当前API(视频录制打开即可)
            Self.logger.error("[startRecord], startAudioCapture return error")
        }
        callback(.success(data: nil))
    }
    
    private func startRecordTimeout(timeoutID: Double, trace: OPTrace) {
        self.prStopRecord(compressed: false, trace: trace) {
            [weak self] result in
            guard let delegate = self?.delegate else {
                trace.error("time out stop record but no delegate")
                return
            }
            switch result {
            case .success(let data):
                if let rawData = data {
                    let action = OpenNativeCameraRecordTimeoutAction(stopRecordResult: rawData, timeoutCallbackId: timeoutID)
                    delegate.onRecordTimeout(action: action)
                    return
                }
            default: break
            }
            trace.error("time out stop record error")
        }
    }
    
    func stopRecord(params: OpenNativeCameraStopRecordParams, context: OpenPluginNativeComponent.Context, callback: @escaping (OpenComponentBaseResponse<OpenNativeCameraStopRecordResult>) -> Void) {
        prStopRecord(compressed: params.compressed, trace: context.trace, callback: callback)
    }
    
    private func prStopRecord(compressed: Bool, trace: OPTrace, callback: @escaping (OpenComponentBaseResponse<OpenNativeCameraStopRecordResult>) -> Void) {
        guard let camera = camera else {
            let error = OpenAPIError(errno: OpenNativeCameraErrno.dispatchAction(.cameraInitError))
                .setCameraError(.noCamera)
            callback(.failure(error: error))
            return
        }
        guard isRecord else {
            let error = OpenAPIError(errno: OpenNativeCameraErrno.dispatchAction(.recordNotStarted))
            callback(.failure(error: error))
            return
        }
        cleanRecordTimer()
        
        let firstImage = camera.getFirstRecordFrame()
        camera.stopAudioCapture()
        camera.pauseVideoRecord()
        camera.export(withVideo: camera.videoData) {
            [weak self] newVideoData, error in
            if let error = error {
                let error = OpenAPIError(errno: OpenNativeCameraErrno.dispatchAction(.stopRecordInnerError))
                    .setMonitorMessage(error.localizedDescription)
                callback(.failure(error: error))
                self?.cleanRecordContext()
                return
            }
            
            guard let newVideoData = newVideoData else {
                let error = OpenAPIError(errno: OpenNativeCameraErrno.dispatchAction(.stopRecordInnerError))
                    .setMonitorMessage("export failed: no videod ata")
                callback(.failure(error: error))
                self?.cleanRecordContext()
                return
            }
            
            guard let self = self else {
                let error = OpenAPIError(errno: OpenNativeCameraErrno.dispatchAction(.stopRecordInnerError))
                    .setCameraError(.noSelf)
                callback(.failure(error: error))
                return
            }
            
            self.saveVideo(compressed: compressed, firstImage: firstImage, videoData: newVideoData, trace: trace, callback: callback)
        }
    }
    
    private func saveVideo(compressed: Bool, firstImage: UIImage?, videoData: HTSVideoData, trace: OPTrace, callback: @escaping (OpenComponentBaseResponse<OpenNativeCameraStopRecordResult>) -> Void) {
        guard let videoAsset = videoData.videoAssets.lastObject as? AVAsset else {
            let error = OpenAPIError(errno: OpenNativeCameraErrnoDispatchAction.stopRecordInnerError)
                .setMonitorMessage("no videoAssets")
            callback(.failure(error: error))
            cleanRecordContext()
            return
        }
        
        // image
        let fsContext = FileSystem.Context(uniqueId: uniqueID,
                                           trace: trace,
                                           tag: "cameraTakePhoto")

        var tempImagePath = ""
        if let firstImage = firstImage {
            do {
                // TODOZJX
                let quality = CGFloat((try? SettingManager.shared.setting(with: Int.self, key: .make(userKeyLiteral: "api_compressImage_rate"))) ?? 80) / 100.0
                let result = try FileUtils.saveImage(image: firstImage,
                                                     compressionQuality: quality,
                                                     fsContext: fsContext)
                tempImagePath = result.path
            } catch {
                trace.error("save image error: \(error)")
            }
        }
        
        var pathExtension = "mov"
        if let videoURLAsset = videoAsset as? AVURLAsset {
            pathExtension = videoURLAsset.url.pathExtension
        }
        
        let moudleManager = BDPModuleManager(of: uniqueID.appType)
        guard let storage = moudleManager.resolveModule(with: BDPStorageModuleProtocol.self) as? BDPStorageModuleProtocol else {
            let error = OpenAPIError(errno: OpenNativeCameraErrnoDispatchAction.stopRecordSaveFileError)
                .setMonitorMessage("can't find storage")
            callback(.failure(error: error))
            cleanRecordContext()
            return
        }
        guard let sandbox = OPUnsafeObject(storage.minimalSandbox(with: uniqueID)) as? BDPMinimalSandboxProtocol else {
            let error = OpenAPIError(errno: OpenNativeCameraErrnoDispatchAction.stopRecordSaveFileError)
                .setMonitorMessage("can't find sandbox")
            callback(.failure(error: error))
            cleanRecordContext()
            return
        }
        
        guard let randomPath = FileSystemUtils.generateRandomPrivateTmpPath(with: sandbox) else {
            let error = OpenAPIError(errno: OpenNativeCameraErrnoDispatchAction.stopRecordSaveFileError)
                .setMonitorMessage("can't generate random path")
            callback(.failure(error: error))
            cleanRecordContext()
            return
        }
        let path = URL(fileURLWithPath: randomPath).absoluteString
        
        EMAImagePicker.exportVideo(with: videoAsset, pathExtension: pathExtension, maxDuration: TimeInterval.infinity, compressed: compressed, outputFilePathWithoutExtention: path) {
            [weak self] result in
            guard let videoRawFilePath = result.filePath else {
                let error = OpenAPIError(errno: OpenNativeCameraErrnoDispatchAction.stopRecordSaveFileError)
                    .setMonitorMessage("export video failed")
                callback(.failure(error: error))
                self?.cleanRecordContext()
                return
            }
            
            let randomTempVideoPath = FileObject.generateRandomTTFile(type: .temp, fileExtension: (videoRawFilePath as NSString).pathExtension)
            do {
                try FileSystemCompatible.moveSystemFile(videoRawFilePath, to: randomTempVideoPath, context: fsContext)
                
                let param = OpenNativeCameraStopRecordResult(tempThumbPath: tempImagePath, tempVideoPath: randomTempVideoPath.rawValue)
                callback(.success(data: param))
            } catch let error as FileSystemError {
                let callbackError = OpenAPIError(errno: OpenNativeCameraErrno.dispatchAction(.stopRecordSaveFileError))
                    .setError(error)
                callback(.failure(error: callbackError))
            } catch let error as OpenAPIError {
                callback(.failure(error: error))
            } catch let error {
                callback(.failure(error: OpenAPIError(errno: OpenNativeCameraErrno.dispatchAction(.takePhotoInnerError)).setError(error)))
            }
            self?.cleanRecordContext()
        }
    }
    
    // 子线程的回调
    func onCameraFrame(context: OpenPluginNativeComponent.Context, callback: @escaping (OpenComponentBaseResponse<OpenComponentBaseResult>) -> Void) {
        // onCameraFrame 本期不支持
        callback(.failure(error: OpenAPIError(errno: OpenAPICommonErrno.unable)))
        return
        
//        guard let camera = camera else {
//            let error = OpenAPIError(errno: OpenNativeCameraErrno.dispatchAction(.internalError))
//                .setCameraError(.noCamera)
//            callback(.failure(error: error))
//            return
//        }
//        camera.setVideoBufferCallback { [weak self] pixelBuffer, cmTime in
//            // 会非常频繁, 注意不要做耗时操作
//            do {
//                guard let self = self else {
//                    throw OpenAPIError(errno: OpenNativeCameraErrno.fireEvent(.internalError))
//                        .setCameraError(.noSelf)
//                }
//                
//                guard let pixelBuffer = pixelBuffer else {
//                    throw OpenAPIError(errno: OpenNativeCameraErrno.fireEvent(.internalError))
//                        .setCameraError(.frameCallbackNoFrame)
//                }
//                if let delegate = self.delegate {
//                    let width = CVPixelBufferGetWidth(pixelBuffer)
//                    let height = CVPixelBufferGetHeight(pixelBuffer)
//                    let data = NSData(data: Data.from(pixelBuffer: pixelBuffer))
//                    let base64 = data.base64EncodedString(options: .lineLength64Characters)
//                    let frame = OpenNativeCameraCameraFrameAction(width: width, height: height, data: base64)
//                    delegate.onCameraFrame(frame: frame)
//                } else {
//                    throw OpenAPIError(errno: OpenNativeCameraErrno.fireEvent(.internalError))
//                        .setCameraError(.noDelegate)
//                }
//            } catch let error {
//                Self.logger.error("pixelbuffer callback error", tag: "OPCamera", additionalData: nil, error: error)
//            }
//        }
//        callback(.success(data: nil))
    }
    
    func offCameraFrame(context: OpenPluginNativeComponent.Context, callback: @escaping (OpenComponentBaseResponse<OpenComponentBaseResult>) -> Void) {
        // offCameraFrame 本期不支持
        callback(.failure(error: OpenAPIError(errno: OpenAPICommonErrno.unable)))
        return
        
//        guard let camera = camera else {
//            let error = OpenAPIError(errno: OpenNativeCameraErrno.dispatchAction(.internalError))
//                .setCameraError(.noCamera)
//            callback(.failure(error: error))
//            return
//        }
//        camera.setVideoBufferCallback { _,_ in }
//        callback(.success(data: nil))
    }
}

// MARK: - Action Callback
extension OPNormalCamera {
    private func actionCallback(action: IESCameraAction, error: Error?, data: Any?) {
        // 相机状态变更回调
        Self.logger.info("camera state change from \(cameraAction.rawValue) to \(action.rawValue)", tag: "OPCamera", additionalData: nil, error: error)
        cameraAction = action
        var log = "did"
        switch action {
        case .didStartVideoCapture:
            log = "didStartVideoCapture"
            didStartVideoCapture()
        case .didStopVideoCapture:
            log = "didStopVideoCapture"
            didStopVideoCapture()
        case .didStartVideoRecord:
            log = "didStartVideoRecord"
        case .didPauseVideoRecord:
            log = "didPauseVideoRecord"
        case .didRecordReady:
            log = "didRecordReady"
        case .didChangeCameraDeviceType:
            log = "didChangeCameraDeviceType"
            bindInitDone(source: .didChangeCameraDeviceType)
        case .didFirstFrameRender:
            log = "didFirstFrameRender"
        case .didChangeCameraZoomFactor:
            log = "didChangeCameraZoomFactor"
            setZoomTimer?.fire()
            setZoomTimer = nil
        default:
            // do nothing
            log = "\(action)"
        }
        Self.logger.info("camera action didchange: \(log)")
    }
    
    private func didStartVideoCapture() {
        // log
        guard isCapture == false else {
            return
        }
        isCapture = true
        camera?.cameraFlashMode = OpenNativeCameraComponent.getFlash(with: flash)
        torchIfNeeded(with: flash, devicePosition: devicePosition)
        resetFrameIfNeeded()
        bindInitDone(source: .initDone)
    }
    
    private func didStopVideoCapture() {
        guard isCapture else {
            return
        }
        isCapture = false
        bindStop(source: .captureStop)
    }
    
    private func fireSetZoom(trace: OPTrace, callback: @escaping (OpenComponentBaseResponse<OpenNativeCameraSetZoomResult>) -> Void) {
        guard let camera = self.camera else {
            let error = OpenAPIError(errno: OpenNativeCameraErrno.dispatchAction(.cameraInitError))
                .setCameraError(.noCamera)
            callback(.failure(error: error))
            return
        }
        let resultZoom = camera.currentCameraZoomFactor()
        currentZoom = resultZoom
        let result = OpenNativeCameraSetZoomResult(zoom: Double(resultZoom))
        trace.info("fireSetZoom, result zoom: \(resultZoom)")
        callback(.success(data: result))
    }
    
    enum CameraInitDoneSource: String {
        case initDone
        case didChangeCameraDeviceType
    }
    
    enum CameraStopSource: String {
        case captureStop
        case willChangeCameraDevice
    }
    
    private func bindInitDone(source: CameraInitDoneSource) {
        guard let camera = camera, let delegate = delegate else {
            return
        }
        let devicePosition = camera.currentCameraPosition
        let enumDevicePosition = OpenNativeCameraComponent.getEnumCameraPosition(with: devicePosition)
        let maxCameraZoomFactor = Double(camera.maxCameraZoomFactor())
        let params = OpenNativeCameraBindInitDoneResult(maxZoom: maxCameraZoomFactor, devicePosition: enumDevicePosition)
        self.maxCameraZoomFactor = maxCameraZoomFactor
        currentZoom = camera.currentCameraZoomFactor()
        executeOnMainQueueAsync { [weak self] in
            self?.preview.delegate = self
        }
        delegate.bindInitDone(params: params)
    }
    
    private func bindStop(source: CameraStopSource) {
        delegate?.bindStop()
    }
}

// MARK: - Private

extension OPNormalCamera {
    private func cleanRecordContext() {
        btd_dispatch_async_on_main_queue {
            self.camera?.removeAllVideoFragments()
        }
    }
    
    private func cleanRecordTimer() {
        isRecord = false
        recordTimer?.invalidate()
        recordTimer = nil
    }
    
    private func torchIfNeeded(with flash: CameraFlash, devicePosition: CameraDevicePosition) {
        camera?.torchOn = .torch == flash && .back == devicePosition
    }
    
    private func resetFrameIfNeeded() {
        var outputSize = OpenNativeCameraComponent.getOutputSize(resolution: self.resolution, previewSize: self.frame.size)
        if isLandscape() {
            // 如果横屏, 需要旋转outputSize, 以便VE可以根据outputDirection自适应旋转结果图片
            outputSize = CGSizeMake(outputSize.height, outputSize.width)
        }
        guard outputSize != self.outputSize else {
            return
        }
        Self.logger.info("outputSize change from \(self.outputSize) to \(outputSize)")
        self.outputSize = outputSize
        camera?.outputSize = outputSize
    }
    
    private func isLandscape() -> Bool {
        return self.interfaceOrientation == .landscapeLeft || self.interfaceOrientation == .landscapeRight
    }
}
