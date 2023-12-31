//
//  AVCodeScanner.swift
//  QRCode
//
//  Created by jiangxiangrui on 2022/11/29.
//

import UIKit
import Foundation
import RxSwift
import AVFoundation
import ImageIO
import AudioToolbox
import Vision
import LarkFeatureGating
import LKCommonsLogging
import LarkFoundation
import LarkSetting
import LarkSensitivityControl

enum ImageScanReuslt {
    case res(String,ScanType)
    case err(Error)
}

final class AVCodeScanner: NSObject, CodeScannerType, AVCaptureMetadataOutputObjectsDelegate {
    
    var isRunning: Bool {
        return session?.isRunning ?? false
    }
    var device: AVCaptureDevice?  // 摄像头对象
    var session: AVCaptureSession?  // 会话对象
    var previewlayer: AVCaptureVideoPreviewLayer?  // 摄像头图层
    var input: AVCaptureInput? // 输入类
    var output: AVCaptureMetadataOutput? // 输出类
    
    var scanerCameraCaptureFrameHandler: (() -> Void)?
    
    var scanerLumaDetectHandler: ((Int) -> Void)?
    
    var cameraScanObservable = PublishSubject<CameraScanSingleObservableResult>()
    
    var imageScanObservable = PublishSubject<ImageScanObservableResult>()
    
    var cameraScanMulticodeObservable = PublishSubject<CameraScanMulticodeObservableResult>()

    var supportTypes: [ScanType] = [.all]

    var enableLumaDetect: Bool = true
    
    var isTorchOn: Bool = false
    
    var lumaSence: Int = 1
    
    var isInterrupted: Bool = false

    var scanerSuspend: ((Bool) -> Void)?

    public var isTripartiteEnigma: Bool {
        return true
    }

    var videoZoomFactor: Float = 0 {
        didSet {
            try? self.device?.lockForConfiguration()
            device?.videoZoomFactor = CGFloat(videoZoomFactor)
            device?.unlockForConfiguration()
        }
    }
    weak var previewView: UIView?
    
    private let scanFlashEnable: Bool = true
    
    var timer: Timer?

    var lastScannedResult: String?
    var lastScannedTime: Date?

    var isViewDidAppear: Bool = false

    private let logger = Logger.log(AVCodeScanner.self)

    /// 默认打开，此FG控制是否需要关闭
    @FeatureGatingValue(key: "core.scan.support.microspur.close") private var microspurEnableClose: Bool
    /// 是否需要关闭重复结果过滤优化逻辑
    @FeatureGatingValue(key: ScanQRCodeFeatureKey.distinctEnableClose.key) private var distinctEnableClose: Bool
    private(set) public var currentCamera: AVCaptureDevice.Position = .back
    
    init(previewView: UIView) {
        self.previewView = previewView
        super.init()
        guard LarkFoundation.Utils.cameraPermissions() else { return }
        // 获取手机摄像头
        do {
            let token = Token("LARK-PSDA-qrcode_get_camera_device")
            try device = CameraEntry.defaultCameraDevice(forToken: token)
        } catch {
            logger.info("due PSDA control default cameraDevice failure")
        }
        if microspurEnableClose {
            device = AVCaptureDevice.default(for: AVMediaType.video)
        } else {
            logger.info("use microspur:\(microspurEnableClose)")
            device = deviceWithMediaType(.video, preferringPosition: currentCamera)
            if let videoDevice = device {
                self.videoZoomFactor = Float(CodeScanTool.minZoomFactor(for: videoDevice.deviceType))
            }
        }
        addVideoInput()
        // 创建会话对象,承担实时获取设备数据的责任
        session = AVCaptureSession()
        // 设备输出类,支持二维码、条形码的扫描识别
        output = AVCaptureMetadataOutput()
        guard let device = device else { return }
        // 设备输入类
        do {
            try self.input = AVCaptureDeviceInput(device: device)
        } catch {
            logger.error("ScanCode.AVScanner: input init error: \(error)")
        }
        guard let session = session,
            let output = output, let input = input else { return }
        // 设置
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        session.sessionPreset = AVCaptureSession.Preset.high
        // 将输入、输出对象加入到会话中
        if session.canAddInput(input) {
            session.addInput(input)
        } else {
            logger.error("ScanCode.AVScanner: add input error ")
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
        } else {
            logger.error("ScanCode.AVScanner: add output error ")
        }
        //创建图层类  可以快速呈现摄像头的原始数据
        previewlayer = AVCaptureVideoPreviewLayer(session: session)
        guard let previewlayer = self.previewlayer else { return }
        previewlayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewlayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        self.previewView?.layer.addSublayer(previewlayer)
        logger.info("ScanCode.AVScanner: init finish")
    }

    deinit {
        timer?.invalidate()
        timer = nil
        logger.info("ScanCode.AVScanner: deinit")
    }

    private func addVideoInput() {
        if let device = self.device {
            do {
                try device.lockForConfiguration()
                //设置支持连续自动对焦功
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                    //设置支持平滑自动对焦功能。平滑自动对焦功能允许摄像头在保持高画质的同时更加平滑地进行自动对焦，从而提高用户体验
                    if device.isSmoothAutoFocusSupported {
                        device.isSmoothAutoFocusEnabled = true
                    }
                }
                // 设置支持连续自动曝光
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }
                //设置白平衡模式，用于调整摄像头在捕获图像时对颜色的处理，以获得准确的颜色表现
                if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                    device.whiteBalanceMode = .continuousAutoWhiteBalance
                }
                //设置低光增强功能可用时是否自动启用，暂不设置
//                if device.isLowLightBoostSupported {
//                    device.automaticallyEnablesLowLightBoostWhenAvailable = true
//                }
                device.unlockForConfiguration()
            } catch {
                logger.error("ScanCode.AVScanner: add video input error \(error)")
            }
        }
    }

    private func configEnableType(supportTypes: [ScanType]) {
        guard let output = output else { return }
        var metadataObjectTypes: [AVMetadataObject.ObjectType] = []
        for scanType in supportTypes {
            switch scanType {
            case .unkonwn:
                break
            case .qrCode:
                metadataObjectTypes.append(AVMetadataObject.ObjectType.qr)
            case .barCode:
                metadataObjectTypes.append(contentsOf: [AVMetadataObject.ObjectType.ean13, AVMetadataObject.ObjectType.ean8,
                                                        AVMetadataObject.ObjectType.code128, AVMetadataObject.ObjectType.upce,
                                                        AVMetadataObject.ObjectType.code39])
            case .dataMatrix:
                metadataObjectTypes.append(AVMetadataObject.ObjectType.dataMatrix)
            case .pdf:
                metadataObjectTypes.append(AVMetadataObject.ObjectType.pdf417)
            case .all:
                metadataObjectTypes = [AVMetadataObject.ObjectType.ean13, AVMetadataObject.ObjectType.ean8,
                                       AVMetadataObject.ObjectType.code128, AVMetadataObject.ObjectType.code39,
                                       AVMetadataObject.ObjectType.qr, AVMetadataObject.ObjectType.upce,
                                       AVMetadataObject.ObjectType.dataMatrix, AVMetadataObject.ObjectType.pdf417]
            }
        }
        logger.info("ScanCode.AVScanner: set output metadataObjectTypes")
        for item in metadataObjectTypes {
            if output.availableMetadataObjectTypes.contains(item) {
                output.metadataObjectTypes.append(item)
            } else {
                logger.info("ScanCode.AVScanner: metadataObjectTypes can not add \(item)")
            }
        }
    }

    private func deviceWithMediaType(
            _ mediaType: AVMediaType,
            preferringPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
            var captureDevice = CodeScanTool.supportedCameraTypes()
                    .lazy
                    .compactMap({ AVCaptureDevice.default($0.deviceType, for: mediaType, position: position) })
                    .first
        return captureDevice
    }

    func switchToImageMode() {
        timer?.invalidate()
        timer = nil
        logger.info("ScanCode.AVScanner: image mode")
    }

    func switchToCameraMode() {
        logger.info("ScanCode.AVScanner: camera mode")
        timer?.invalidate()
        timer = nil
        if scanFlashEnable && (UIDevice.current.userInterfaceIdiom != .pad) {
            timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true, block: { [weak self] _ in
                let scene = (self?.device?.iso ?? 0 > 1000) ? 0 : 1
                guard ((self?.enableLumaDetect ?? false)) else { return }
                if self?.lumaSence != scene {
                    self?.lumaSence = scene
                    self?.scanerLumaDetectHandler?(scene)
                }
            })
        }
    }

    func scan(image: UIImage) -> Observable<ImageScanObservableResult> {
        return Observable.create { observer in
            let result = self.parseBarCode(img: image)
            switch result {
            case .res(let value, let type):
                observer.on(
                    .next(([CodeItemInfo(position: .zero, content: value, type: type)], image))
                )
                observer.onCompleted()
            case .err(let error):
                observer.on(
                    .error(QRScanError.imageScanFailure(error))
                )
            }
            return Disposables.create()
        }
    }
    
    func enableTorch(enable: Bool) {
        guard let device = self.device else { return }
        logger.info("ScanCode.Scanner: Torch enable \(enable)")
        guard device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            //开启、关闭闪光灯
            if enable {
                device.torchMode = .on
            } else {
                device.torchMode = .off
            }
            device.unlockForConfiguration()
        } catch {
            logger.error("ScanCode.AVScanner: enable Torch error \(error)")
        }
    }
    
    func openCamera() {
        guard let session = session else { return }
        do {
            let token = Token("LARK-PSDA-qrcode_session_start")
            try CameraEntry.startRunning(forToken: token, session: session)
        } catch {
            logger.info("due PSDA control startRunning failuer ")
        }
        logger.info("ScanCode.AVScanner: openCamera")
    }
    
    func stopCamera() {
        guard let session = session else { return }
        session.stopRunning()
        logger.info("ScanCode.AVScanner: stopCamera")
    }
    
    func startCameraScanner() {
        switchToCameraMode()
    }
    
    func setupScanner() {
        //设置有效的扫描区域
        output?.rectOfInterest = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        configEnableType(supportTypes: self.supportTypes)
    }

    func stopScanner() {}
    func cancelReSanner() {}

    func rotateSanner() {
        self.previewlayer?.connection?.videoOrientation = getDeviceOrientation()
    }
    
    // 识别二维码返回
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.count > 0 {
            stopCamera()
            let metadataObject = metadataObjects[0] as? AVMetadataMachineReadableCodeObject
            guard let metadata: AVMetadataMachineReadableCodeObject = metadataObject,
                let stringValue = metadata.stringValue else { return }
            logger.info("ScanCode.AVScanner: distinctEnableClose: \(distinctEnableClose)")
            if !distinctEnableClose {
                logger.info("ScanCode.AVScanner: distinct Enable")
                if let lastScannedResult = lastScannedResult,
                   stringValue == lastScannedResult,
                   let lastScannedTime = lastScannedTime,
                   Date().timeIntervalSince(lastScannedTime) < 1 {
                    logger.info("ScanCode.AVScanner: filtering repetition stringValue: \(stringValue.md5()) lastScannedResult: \(lastScannedResult.md5())")
                    return
                }
                if isViewDidAppear {
                    // 保存此次扫描的结果和时间, viewDidAppear之前的结果丢弃，避免viewDidAppear之前扫码到了结果但是没有给业务方回调但是保存了，viewDidAppear之后需要给业务方回调但是过滤了，会导致业务方得1s后才能拿到回调
                    lastScannedResult = stringValue
                    lastScannedTime = Date()
                }
            }
            let newValue = transCoding(value: stringValue)
            var lensName: String?
            if #available(iOS 15.0, *) {
                lensName = self.device?.activePrimaryConstituent?.deviceType.rawValue
                logger.info("ScanCode.AVScanner: metadataOutput lensName:\(String(describing: lensName))")
            }
            self.cameraScanObservable.onNext((newValue, tranfrom(codeType: metadata.type), lensName))
        }
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

    private func tranfrom(codeType: AVMetadataObject.ObjectType) -> ScanType {
        switch codeType {
        case .qr:
            return .qrCode
        case .dataMatrix:
            return .dataMatrix
        case .pdf417:
            return .pdf
        case .code128, .code39, .ean8, .ean13, .upce:
            return .barCode
        default:
            return .unkonwn
        }
    }
    
    private func tranfrom(codeType: VNBarcodeSymbology) -> ScanType {
        switch codeType {
        case .qr:
            return .qrCode
        case .dataMatrix:
            return .dataMatrix
        case .pdf417:
            return .pdf
        case .code128, .code39, .ean8, .ean13, .upce:
            return .barCode
        default:
            return .unkonwn
        }
    }
    
    /// 识别二维码和条形码
    private func parseBarCode(img: UIImage) -> ImageScanReuslt {
        var res: ImageScanReuslt
        guard let cgimg = img.cgImage else {
            return .err(QRScanError.imageToCGImageError)
        }
        let handler = VNImageRequestHandler(cgImage: cgimg)
        let request = VNDetectBarcodesRequest()
        if #available(iOS 15.0, *) {
            request.revision = VNDetectBarcodesRequestRevision2
            request.symbologies = [.codabar, .ean8, .ean13, .qr, .aztec, .code128, .code39, .upce, .dataMatrix, .pdf417]
        } else {
            request.symbologies = [.ean8, .ean13, .qr, .aztec, .code128, .code39, .upce, .dataMatrix,.pdf417]
        }
        do {
            try handler.perform([request])
        } catch {
            return .err(error)
        }
        if let detectBarCodes = request.results, detectBarCodes.count > 0, let payloadStringValue =  detectBarCodes[0].payloadStringValue {
            res = .res(payloadStringValue, tranfrom(codeType: detectBarCodes[0].symbology))
            logger.info("ScanCode.AVScanner: return payloadStringValue")
        } else {
            res = .err(QRScanError.imageScanNoResult)
        }
        return res
    }

    func transCoding(value: String) -> String {
        let gbk = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))
        let data = value.data(using: .isoLatin1)
        if let data = data, let newString = String(data: data, encoding: String.Encoding(rawValue: gbk)) {
            logger.info("ScanCode.AVScanner: transCoding to GBK")
            return newString
        }
        return value
        
    }
    
}
