//
//  QRCodeScanner.swift
//  QRCode
//
//  Created by Yuri on 2022/5/13.
//

import Foundation
import UIKit
import TTVideoEditor
import LarkVideoDirector
import RxSwift
import LarkAssetsBrowser
import LKCommonsLogging
import EEAtomic
import LarkSetting
import LarkUIKit

public typealias ImageScanObservableResult = ([CodeItemInfo], UIImage)
public typealias CameraScanSingleObservableResult = (String, ScanType, String?)
public typealias CameraScanMulticodeObservableResult = ([CodeItemInfo], UIImage?, CGRect, String?)

public protocol CodeScannerType {
    var scanerCameraCaptureFrameHandler: (() -> Void)? { get set }
    var scanerLumaDetectHandler: ((Int) -> Void)? { get set }
    var cameraScanObservable: PublishSubject<CameraScanSingleObservableResult> { get set }
    var imageScanObservable: PublishSubject<ImageScanObservableResult> { get set }
    var cameraScanMulticodeObservable: PublishSubject<CameraScanMulticodeObservableResult> { get set }
    var supportTypes: [ScanType] { get set }
    var enableLumaDetect: Bool { get set }
    var isTorchOn: Bool { get }
    var lumaSence: Int { get set }
    var isInterrupted: Bool { get }
    var isRunning: Bool { get }
    var videoZoomFactor: Float { get set }
    var scanerSuspend: ((Bool) -> Void)? { get set }
    var isTripartiteEnigma: Bool { get }
    var isViewDidAppear: Bool { get set }
    
    func switchToImageMode()
    func switchToCameraMode()
    func scan(image: UIImage) -> Observable<ImageScanObservableResult>
    func enableTorch(enable: Bool)
    func openCamera()
    func stopCamera()
    func startCameraScanner()
    func setupScanner()
    func stopScanner()
    func rotateSanner()
    func cancelReSanner()
}

/// VECodeScan 配置
struct VECodeScanSettingModel: SettingDecodable {
    static let settingKey = UserSettingKey.make(userKeyLiteral: "lark_core_ve_code_scan_config")
    let forceEnigmaType: ScanEnigmaType?
}

final class VECodeScanner: NSObject, CodeScannerType, VEScanDelegate {

    private static let moreScanCodeTag: Int = 1
    public var cameraScanObservable = PublishSubject<CameraScanSingleObservableResult>()
    public var imageScanObservable = PublishSubject<ImageScanObservableResult>()
    var cameraScanMulticodeObservable = PublishSubject<CameraScanMulticodeObservableResult>()
    @FeatureGatingValue(key: "core.scan.optimize.close") private var closeOptimize: Bool
    /// 多码识别算法优化关闭开关(此优化包括了VE自研算法流程与三方算法)
    @FeatureGatingValue(key: "core.scan.tripartite.optimize.close") private var closeTripartiteOptimize: Bool
    /// 使用三方算法
    @FeatureGatingValue(key: "im.scan_code.multi_code_identification") private var useTripartiteEnigma: Bool
    // 默认打开微距，此FG控制是否需要关闭
    @FeatureGatingValue(key: "core.scan.support.microspur.close") private var microspurEnableClose: Bool

    private static var codeSettings: VECodeScanSettingModel? {
        let result: VECodeScanSettingModel?
        do {
            result = try SettingManager.shared.setting(with: VECodeScanSettingModel.self)
        } catch {
            Self.logger.error("VECodeScanSettingModel lark_core_ve_code_scan_config decode error: \(error)")
            result = nil
        }
        Self.logger.info("VECodeScanSettingModel lark_core_ve_code_scan_config result: \(String(describing: result))")
        return result
    }

    var lumaSence = 1 // 默认亮光环境。暗光检测前几帧回调必然亮光
    private var isFirstFrameToken = AtomicOnce()
    var enableLumaDetect = true
    var supportTypes: [ScanType] = [.all]
    var scanMaskView: ScanMask?
    var isViewDidAppear: Bool = false

    var timer: Timer?
    public var isInterrupted: Bool {
        guard let scanner = scanner else { return true }
        return scanner.captureIsInterruptted()
    }

    public var isRunning: Bool {
        guard let scanner = scanner else { return false }
        return scanner.captureIsRunning()
    }

    public var videoZoomFactor: Float = 0 {
        didSet {
            scanner?.setScanZoomWithScale(videoZoomFactor)
        }
    }

    public var isTripartiteEnigma: Bool {
        return useTripartiteEnigma
    }

    public var scanerCameraCaptureFrameHandler: (() -> Void)?
    var scanerLumaDetectHandler: ((Int) -> Void)?

    /// 暂停扫码
    var scanerSuspend: ((Bool) -> Void)?

    private var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }

    private var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }

    private var cameraResolutionRatioWidth: CGFloat {
        Self.logger.info("cameraResolutionRatioWidth isLandscape:\(isLandscape())")
        return isLandscape() ? Cons.scanHeightResolutionRatio : Cons.scanWidthResolutionRatio
    }

    private var cameraResolutionRatioHeight: CGFloat {
        return isLandscape() ? Cons.scanWidthResolutionRatio : Cons.scanHeightResolutionRatio
    }

    private var cropoRect: CGRect {
        guard Display.pad else {
            let width = screenWidth * (cameraResolutionRatioHeight / screenHeight)
            return CGRect(x: (cameraResolutionRatioWidth - width) / 2, y: 0, width: width, height: cameraResolutionRatioHeight)
        }
        if isLandscape() {
            let height = screenHeight * (cameraResolutionRatioWidth / screenWidth)
            return CGRect(x: 0, y: (cameraResolutionRatioHeight - height) / 2, width: cameraResolutionRatioWidth, height: height)
        } else {
            let width = screenWidth * (cameraResolutionRatioHeight / screenHeight)
            return CGRect(x: (cameraResolutionRatioWidth - width) / 2, y: 0, width: width, height: cameraResolutionRatioHeight)
        }
    }

    var lastScannedResult: [String?]?
    var lastScannedTime: Date?

    private static let logger = Logger.log(VECodeScanner.self, category: "VECodeScanner")
    private var scanner: VEScan?
    private let enigmaSerialQueue = DispatchQueue(label: "com.enigma.serialQueue", qos: .default)
    private lazy var tripartiteParamEnigma: VECaptureProcessParamEnigma = {
        let enigma = VECaptureProcessParamEnigma()
        enigma.graphConfig = ""
        enigma.enableCodeTypes = getVESystemCodeType()
        return enigma
    }()
    private lazy var veCameraParamEnigma: VECaptureProcessParamEnigma = {
        let enigma = VECaptureProcessParamEnigma()
        enigma.graphConfig = getVECameraEnigmaConfig()
        enigma.enableCodeTypes = getVECodeType()
        return enigma
    }()
    private lazy var veImageParamEnigma: VECaptureProcessParamEnigma = {
        let enigma = VECaptureProcessParamEnigma()
        enigma.graphConfig = Self.getVEImageEnigmaConfig()
        enigma.enableCodeTypes = getVECodeType()
        return enigma
    }()
    private lazy var cameraConfig: IESMMCameraConfig? = {
        let config = scanner?.getDefaultCameraConfig()
        let deviceTypes = CodeScanTool.supportedCameraTypes().map { $0.0 }
        config?.preferredRearCameraDeviceTypes = deviceTypes
        config?.preferredBackZoomFactor = Cons.backZoomFactor
        return config
    }()

    deinit {
        self.stopScanner()
        timer?.invalidate()
        timer = nil
        Self.logger.info("ScanCode.Scanner: deinit")
    }

    private var previewView: UIView
    required init(previewView: UIView) {
        self.previewView = previewView
        super.init()
        // 在调用 VE 的任何方法之前，调用此方法初始化 VE 配置
        VideoEditorManager.shared.setupVideoEditorIfNeeded()
        self.scanner = VEScan.create()
    }

    // MARK: - Public
    static func scanImageUtil(by image: UIImage, enigmaType: ScanEnigmaType = .system, completionBlock: ScanCodeResultsCallBack?) {
        let useTripartiteEnigma = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "im.scan_code.multi_code_identification"))
        let scanEnigmaType: ScanEnigmaType
        if useTripartiteEnigma, let codeScanSettingModel = Self.codeSettings, let forceEnigmaType = codeScanSettingModel.forceEnigmaType {
            scanEnigmaType = forceEnigmaType
        } else {
            // 使用VE自研算法
            scanEnigmaType = enigmaType
        }
        Self.logger.info("use scanEnigmaType :\(scanEnigmaType) useTripartiteEnigma:\(useTripartiteEnigma) enigmaType:\(enigmaType)")
        switch scanEnigmaType {
        case .system:
            VEScan.scanCodeSystem(image, codeType: Self.getVESystemCodeType(supportTypes: [.all])) { (results, error) in
                if let err = error {
                    completionBlock?(.failure(err))
                    return
                }
                guard let codeItems = results as? [VEAlgorithmSessionCodeItem], !codeItems.isEmpty else {
                    completionBlock?(.success([]))
                    return
                }
                let codeResults = codeItems.map { CodeItemInfo(position: $0.position, content: $0.content ?? "", type: Self.tranfrom(codeType: $0.codeType)) }
                completionBlock?(.success(codeResults))
            }
        case .veOwner:
            let veImageParamEnigma = VECaptureProcessParamEnigma()
            veImageParamEnigma.graphConfig = Self.getVEImageEnigmaConfig()
            veImageParamEnigma.enableCodeTypes = Self.getVECodeType(supportTypes: [.all])
            let result = VEScan.scanCode(image, param: veImageParamEnigma)
            if let err = result.error {
                completionBlock?(.failure(err))
                return
            }
            guard let codeContent = result.content else {
                completionBlock?(.success([]))
                return
            }
            let codeResults = [CodeItemInfo(position: .zero, content: codeContent, type: Self.tranfrom(codeType: result.codeType))]
            completionBlock?(.success(codeResults))
            
        }
    }

    // MARK: - Private
    /// 设置扫码算法模型
    private func newSetScanEnigma() {
        guard let scanner = self.scanner else { return }
        Self.logger.info("new set scan enigma useTripartiteEnigma:\(useTripartiteEnigma)")
        if useTripartiteEnigma {
            // 使用三方算法能力
            scanner.turnSystemEnigma(true, param: self.tripartiteParamEnigma)
        } else {
            // 使用VE自研算法能力
            scanner.turnEnigma(true, param: self.veCameraParamEnigma)
        }
    }

    private func tranfrom(codeType: VE_CODE_TYPE) -> ScanType {
        return Self.tranfrom(codeType: codeType)
    }

    private static func tranfrom(codeType: VE_CODE_TYPE) -> ScanType {
        switch codeType {
        case .CODE_TYPE_QRCODE:
            return .qrCode
        case .CODE_TYPE_DATA_MATRIX:
            return .dataMatrix
        case .CODE_TYPE_VORTEX_CODE, .CODE_TYPE_I2of5_CODE, .CODE_TYPE_UPC_E_CODE,
                .CODE_TYPE_EAN_8_CODE, .CODE_TYPE_EAN_13_CODE, .CODE_TYPE_CODE39_CODE, .CODE_TYPE_CODE93_CODE, .CODE_TYPE_CODE128_CODE, .CODE_TYPE_PDF_417:
            return .barCode
        default:
            return .unkonwn
        }
    }

    private func getVECodeType() -> VE_CODE_TYPE {
        return Self.getVECodeType(supportTypes: self.supportTypes)
    }

    // nolint: duplicated_code - 需要做类型配置区分，非重复
    private static func getVECodeType(supportTypes: [ScanType]) -> VE_CODE_TYPE {
        let unkonwCodeType: VE_CODE_TYPE = []
        let qrCodeType: VE_CODE_TYPE = [VE_CODE_TYPE.CODE_TYPE_QRCODE]
        let barCodeType: VE_CODE_TYPE = [VE_CODE_TYPE.CODE_TYPE_VORTEX_CODE,
                           VE_CODE_TYPE.CODE_TYPE_VORTEX_CODE,
                           VE_CODE_TYPE.CODE_TYPE_I2of5_CODE,
                           VE_CODE_TYPE.CODE_TYPE_UPC_E_CODE,
                           VE_CODE_TYPE.CODE_TYPE_EAN_8_CODE,
                           VE_CODE_TYPE.CODE_TYPE_EAN_13_CODE,
                           VE_CODE_TYPE.CODE_TYPE_CODE39_CODE,
                           VE_CODE_TYPE.CODE_TYPE_CODE93_CODE,
                           VE_CODE_TYPE.CODE_TYPE_CODE128_CODE]
        let dmCodeType: VE_CODE_TYPE = [VE_CODE_TYPE.CODE_TYPE_DATA_MATRIX]
        let pdfCodeType: VE_CODE_TYPE = [VE_CODE_TYPE.CODE_TYPE_PDF_417]
        var type: VE_CODE_TYPE = unkonwCodeType
        for scanType in supportTypes {
            switch scanType {
            case .unkonwn:
                type.formUnion(unkonwCodeType)
            case .qrCode:
                type.formUnion(qrCodeType)
            case .barCode:
                type.formUnion(barCodeType)
            case .dataMatrix:
                type.formUnion(dmCodeType)
            case .pdf:
                type.formUnion(pdfCodeType)
            case .all:
                type.formUnion(qrCodeType)
                type.formUnion(barCodeType)
                type.formUnion(dmCodeType)
                type.formUnion(pdfCodeType)
            }
        }
        return type
    }

    private func getVESystemCodeType() -> VE_CODE_TYPE {
        return Self.getVESystemCodeType(supportTypes: self.supportTypes)
    }

    private static func getVESystemCodeType(supportTypes: [ScanType]) -> VE_CODE_TYPE {
        let unkonwCodeType: VE_CODE_TYPE = []
        let allType: VE_CODE_TYPE = [VE_CODE_TYPE.CODE_TYPE_ALL]
        let qrCodeType: VE_CODE_TYPE = [VE_CODE_TYPE.CODE_TYPE_QRCODE]
        let barCodeType: VE_CODE_TYPE = [VE_CODE_TYPE.CODE_TYPE_UPC_E_CODE,
                                         VE_CODE_TYPE.CODE_TYPE_I2of5_CODE,
                                         VE_CODE_TYPE.CODE_TYPE_EAN_8_CODE,
                                         VE_CODE_TYPE.CODE_TYPE_EAN_13_CODE,
                                         VE_CODE_TYPE.CODE_TYPE_CODE39_CODE,
                                         VE_CODE_TYPE.CODE_TYPE_CODE93_CODE,
                                         VE_CODE_TYPE.CODE_TYPE_CODE128_CODE]
        let dmCodeType: VE_CODE_TYPE = [VE_CODE_TYPE.CODE_TYPE_DATA_MATRIX]
        let pdfCodeType: VE_CODE_TYPE = [VE_CODE_TYPE.CODE_TYPE_PDF_417]
        var type: VE_CODE_TYPE = unkonwCodeType
        for scanType in supportTypes {
            switch scanType {
            case .unkonwn:
                type.formUnion(unkonwCodeType)
            case .qrCode:
                type.formUnion(qrCodeType)
            case .barCode:
                type.formUnion(barCodeType)
            case .dataMatrix:
                type.formUnion(dmCodeType)
            case .pdf:
                type.formUnion(pdfCodeType)
            case .all:
                type.formUnion(allType)
            }
        }
        return type
    }

    private func getVECameraEnigmaConfig() -> String {
        let bundle = BundleConfig.QRCodeBundle
        if let string = bundle.path(forResource: "scan_camera_graph_config", ofType: "json", inDirectory: "Config"),
           let content = try? String(contentsOfFile: string) {
            return content
        }
        return ""
    }

    private static func getVEImageEnigmaConfig() -> String {
        let bundle = BundleConfig.QRCodeBundle
        if let string = bundle.path(forResource: "scan_album_graph_config", ofType: "json", inDirectory: "Config"),
            // lint:disable:next lark_storage_check - 不涉及加解密，不处理
           let content = try? String(contentsOfFile: string) {
            return content
        }
        return ""
    }

    private func configEnableType(supportTypes: [ScanType]) {
        let unkonwCodeType = 0
        let qrCodeType = VE_CODE_TYPE.CODE_TYPE_QRCODE.rawValue
        let barCodeType = VE_CODE_TYPE.CODE_TYPE_VORTEX_CODE.rawValue
        | VE_CODE_TYPE.CODE_TYPE_VORTEX_CODE.rawValue
        | VE_CODE_TYPE.CODE_TYPE_I2of5_CODE.rawValue
        | VE_CODE_TYPE.CODE_TYPE_UPC_E_CODE.rawValue
        | VE_CODE_TYPE.CODE_TYPE_EAN_8_CODE.rawValue
        | VE_CODE_TYPE.CODE_TYPE_EAN_13_CODE.rawValue
        | VE_CODE_TYPE.CODE_TYPE_CODE39_CODE.rawValue
        | VE_CODE_TYPE.CODE_TYPE_CODE128_CODE.rawValue
        let dmCodeType = VE_CODE_TYPE.CODE_TYPE_DATA_MATRIX.rawValue
        let pdfCodeType = VE_CODE_TYPE.CODE_TYPE_PDF_417.rawValue

        var type: UInt = UInt(unkonwCodeType)
        for scanType in supportTypes {
            switch scanType {
            case .unkonwn:
                type |= UInt(unkonwCodeType)
            case .qrCode:
                type |= qrCodeType
            case .barCode:
                type |= barCodeType
            case .dataMatrix:
                type |= dmCodeType
            case .pdf:
                type |= pdfCodeType
            case .all:
                type |= (qrCodeType | barCodeType | dmCodeType | pdfCodeType)
            }
        }
        scanner?.enableCodeTypes(type)
    }

    //MARK: - CodeScannerType
    func setupScanner() {
        Self.logger.info("setup scanner closeTripartiteOptimize:\(closeTripartiteOptimize)")
        if closeTripartiteOptimize {
            setEnigma()
            configEnableType(supportTypes: self.supportTypes)
        } else {
            newSetScanEnigma()
        }
        setCameraPreviewFrames()
    }

    /// 设置算法
    private func setEnigma() {
        if closeOptimize {
            setupEnigmaConfig()
        } else {
            enigmaSerialQueue.async { [weak self] in
                guard let self = self else { return }
                self.setupEnigmaConfig()
            }
        }
    }

    /// 设置预览画面
    private func setCameraPreviewFrames() {
        guard let scanner = scanner else { return }
        // lint:enable lark_storage_check
        scanner.setScanDelegate(self)
        Self.logger.info("set camera preview frames microspurEnableClose:\(microspurEnableClose)")
        if let cameraConfig = self.cameraConfig, !microspurEnableClose {
            let code = scanner.setCameraPreviewView(previewView, with: cameraConfig)
            Self.logger.info("ScanCode.Scanner: set camera view with cameraConfig code: \(code)")
        } else {
            let code = scanner.setCameraPreviewView(previewView, withCapturePreset: closeOptimize ? .photo : .hd1280x720)
            Self.logger.info("ScanCode.Scanner: set camera view with capturePreset code: \(code)")
        }
        guard Display.pad else { return }
        rotateSanner()
    }

    private func setupEnigmaConfig() {
        guard let scanner = scanner else { return }
        // lint:disable lark_storage_check - 从 bundle 读数据，不涉及加解密，无需使用 LarkStorage
        let bundle = BundleConfig.QRCodeBundle
        if let string = bundle.path(forResource: "scan_camera_graph_config", ofType: "json", inDirectory: "Config"),
           let content = try? String(contentsOfFile: string) {
            scanner.setEnigmaConfig(content, sourceType: ETEEnigmaSourceCamera)
        }
        if let string = bundle.path(forResource: "scan_album_graph_config", ofType: "json", inDirectory: "Config"),
           let content = try? String(contentsOfFile: string) {
            scanner.setEnigmaConfig(content, sourceType: ETEEnigmaSourceImage)
        }
    }

    func startCameraScanner() {
        switchToCameraMode()
    }

    func stopScanner() {
        guard let scanner = scanner else { return }
        scanner.stop()
        Self.logger.info("ScanCode.Scanner: stop scanner")
    }

    func switchToCameraMode() {
        guard let scanner = scanner else { return }
        scanner.stop()
        setupFlashlight()

        guard closeTripartiteOptimize else {
            newStartVEScanner()
            return
        }
        if closeOptimize {
            startVEScanner()
        } else {
            enigmaSerialQueue.async { [weak self] in
                guard let self = self else { return }
                self.startVEScanner()
            }
        }
    }

    /// 设置闪光灯
    private func setupFlashlight() {
        guard let scanner = scanner else { return }
        if (UIDevice.current.userInterfaceIdiom != .pad) {
            // 重置默认值
            lumaSence = 1
            Self.logger.info("ScanCode.Scanner: start lumaDetect")
            if closeOptimize {
                //关闭优化
                scanner.enableLumaDetect(withDetectFrame: 1)
                timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true, block: { [weak self] _ in
                    self?.scanLumaDetect()
                })
            } else {
                scanner.setCameraInfoBlock({ [weak self] (_, value) in
                    guard let self = self, let value = value as? Double else { return }
                    self.checkFlashlight(value)
                }, withCameraInfoRequirement: .brightness)
            }
        }
    }

    private func startVEScanner() {
        guard let scanner = scanner else { return }
        let code = scanner.enableEnigmaScanSource(ETEEnigmaSourceCamera)
        Self.logger.info("ScanCode.Scanner: camera mode \(code)")
        let startCode = scanner.start()
        Self.logger.info("ScanCode.Scanner: start camera scanner \(startCode)")
    }

    /// 新Api
    private func newStartVEScanner() {
        guard let scanner = scanner else { return }
        Self.logger.info("New ScanCode.Scanner: camera mode")
        let startCode = scanner.start()
        Self.logger.info("New ScanCode.Scanner: start camera scanner \(startCode)")
    }

    private func newScan(image: UIImage) -> Observable<ImageScanObservableResult> {
        imageScanObservable = PublishSubject<ImageScanObservableResult>()
        if useTripartiteEnigma {
            VEScan.scanCodeSystem(image, codeType: getVESystemCodeType()) { [weak self] (results, error) in
                guard let self = self else { return }
                Self.logger.info("use scanCodeSystem process image")
                self.processImageMultipleScanResults(results: results as? [VEAlgorithmSessionCodeItem], image: image, error: error)
            }
        } else {
            DispatchQueue.main.async {
                Self.logger.info("use scanCodeVE process image")
                let result = VEScan.scanCode(image, param: self.veImageParamEnigma)
                self.processImageSingleScanResults(result: result, image: image)
            }
        }
        return imageScanObservable.asObserver()
    }

    func switchToImageMode() {
        guard let scanner = scanner else { return }
        scanner.stop()
        timer?.invalidate()
        timer = nil
        guard closeTripartiteOptimize else {
            return
        }
        let code = scanner.enableEnigmaScanSource(ETEEnigmaSourceImage)
        Self.logger.info("ScanCode.Scanner: image mode \(code)")
        let startCode = scanner.start()
        Self.logger.info("ScanCode.Scanner: start scanner \(startCode)")
    }

    func openCamera() {
        guard let scanner = scanner else { return }
        if scanner.captureIsRunning() { return }
        let code = scanner.openCamera(withPrivacyCert: QRCodeSensitivityEntryToken.OPVEScanCodeCamera_openCamera.psdaToken)
        if code == -1 {
            // 为了处理pad中通过小组件拉起扫一扫相机打开失败的情况，后续VE优化后可移除此判断处理
            Self.logger.info("reopen camera")
            DispatchQueue.main.async {
                self.reOpenCamera()
            }
        }
        Self.logger.info("ScanCode.Scanner: open camera code:\(code)")
    }

    func reOpenCamera() {
        guard let scanner = scanner else { return }
        if scanner.captureIsRunning() { return }
        setCameraPreviewFrames()
        let code = scanner.openCamera(withPrivacyCert: QRCodeSensitivityEntryToken.OPVEScanCodeCamera_openCamera.psdaToken)
        Self.logger.info("ScanCode.Scanner: again open camera code:\(code)")
    }

    func stopCamera() {
        guard let scanner = scanner else { return }
        scanner.stopCamera()
        Self.logger.info("ScanCode.Scanner: stop camera")
    }

    func enableTorch(enable: Bool) {
        guard let scanner = scanner else { return }
        scanner.enableTorch(enable)
        Self.logger.info("ScanCode.Scanner: Torch enable \(enable)")
    }

    var isTorchOn: Bool {
        guard let scanner = scanner else { return false }
        return scanner.torchIsOn()
    }

    func rotateSanner() {
        guard let scanner = scanner else { return }
        var rotation: HTSGLRotationMode = .noRotation
        var orientation: AVCaptureVideoOrientation = .portrait
        switch UIApplication.shared.statusBarOrientation {
        case .portraitUpsideDown:
            rotation = .rotate180
            orientation = .portraitUpsideDown
        case .landscapeLeft:
            rotation = .rotateLeft
            orientation = .landscapeLeft
        case .landscapeRight:
            rotation = .rotateRight
            orientation = .landscapeRight
        default:
            break
        }
        scanner.setVideoOrientation(orientation)
        scanner.setPreviewRotationMode(rotation)
    }

    /// 取消后重新扫码
    func cancelReSanner() {
        Self.logger.info("cancelReSanner")
        //首次启动算法第一次才会回调当前二维码结果页帧图
        scanner?.turnSystemEnigma(false, param: self.tripartiteParamEnigma)
        scanner?.turnSystemEnigma(true, param: self.tripartiteParamEnigma)
    }

    func checkFlashlight(_ value: Double) {
        guard enableLumaDetect else { return }
        if lumaSence != Int(value) {
            lumaSence = Int(value)
            let result = value < -1 ? 0 : Int(ceil(value))
            Self.logger.info("ScanCode.Scanner: Flashlight value: \(value) result: \(result)")
            scanerLumaDetectHandler?(result)
        }
    }

    func scan(image: UIImage) -> Observable<ImageScanObservableResult> {
        guard closeTripartiteOptimize else {
            Self.logger.info("use new scan image process")
            return newScan(image: image)
        }
        imageScanObservable = PublishSubject<ImageScanObservableResult>()
        scanner?.enableEnigmaScanSource(ETEEnigmaSourceImage)
        scanner?.scanInputImage(image)
        return imageScanObservable.asObserver()
    }

    private func processImageMultipleScanResults(results: [VEAlgorithmSessionCodeItem]?, image: UIImage, error: Error?) {
        if let err = error {
            Self.logger.info("scan failure from ve error:\(err)")
            imageScanObservable.onError(QRScanError.imageScanFailure(err))
        } else {
            guard let codeItems = results, !codeItems.isEmpty else {
                //检测下如果识别到的二维码内容是空，直接回调error弹窗提示
                Self.logger.info("scan success from ve,but content is empty")
                imageScanObservable.onError(QRScanError.imageScanFailure(NSError(domain: "scan.content.empty", code: 0, userInfo: nil)))
                return
            }
            if codeItems.count == Self.moreScanCodeTag, let codeItem = codeItems.first  {
                let codeResult = transformVEScanQRCodeResult(by: codeItem, error: nil)
                Self.logger.info("process image multiple scan results single")
                processImageSingleScanResults(result: codeResult, image: image)
            } else {
                let codeResults = codeItems.map { CodeItemInfo(position: $0.position, content: $0.content ?? "", type: self.tranfrom(codeType: $0.codeType)) }
                Self.logger.info("process image multiple scan results:\(codeResults.count)")
                imageScanObservable.onNext((codeResults, image))
            }
        }
    }

    private func processImageSingleScanResults(result: VEScanQRCodeResult?, image: UIImage) {
        guard let result = result else { return }
        if let error = result.error {
            Self.logger.info("scan failure from ve error:\(error)")
            imageScanObservable.onError(QRScanError.imageScanFailure(error))
        } else {
            let scanContent = result.content ?? ""
            guard !scanContent.isEmpty else {
                //检测下如果识别到的二维码内容是空，直接回调error弹窗提示
                Self.logger.info("scan success from ve,but content is empty")
                imageScanObservable.onError(QRScanError.imageScanFailure(NSError(domain: "scan.content.empty", code: 0, userInfo: nil)))
                return
            }
            Self.logger.info("process image single scan result")
            let codeItems = [CodeItemInfo(position: .zero, content: scanContent, type: self.tranfrom(codeType: result.codeType))]
            imageScanObservable.onNext((codeItems, image))
            self.imageScanObservable.onCompleted()
        }
    }

    /// 扫码-多码处理
    private func multicodeProcess(by codeList: [VEAlgorithmSessionCodeItem], image: UIImage?, lensName: String?) {
        var codeItemOriginList: [CodeItemInfo] = []
        for codeItem in codeList {
            let codeItemOriginInfo = CodeItemInfo(position: codeItem.position, content: codeItem.content ?? "", type: self.tranfrom(codeType: codeItem.codeType))
            codeItemOriginList.append(codeItemOriginInfo)
            Self.logger.info("multicodeProcess codeItemOriginInfo:\(codeItemOriginInfo.description)")
        }
        self.cameraScanMulticodeObservable.onNext((codeItemOriginList, image, cropoRect, lensName))
    }

    // MARK: - VEScanDelegate
    func scan(_ scaner: VEScan?, onScanCompleteWith result: VEScanQRCodeResult?) {
        guard closeTripartiteOptimize || !useTripartiteEnigma else { return }
        guard let scaner = scaner, let result = result else { return }
        switch scaner.enigmaSourceType() {
        case ETEEnigmaSourceCamera:
            if result.error != nil { return }
            guard let content = result.content else { return }
            var lensName: String?
            if #available(iOS 15.0, *) {
                lensName = scaner.activePrimaryConstituentDevice()?.deviceType.rawValue
                Self.logger.info("on scan complete lensName:\(String(describing: lensName))")
            }
            self.cameraScanObservable.onNext((content, self.tranfrom(codeType: result.codeType), lensName))
        case ETEEnigmaSourceImage:
            self.processImageSingleScanResults(result: result, image: UIImage())
        default: break
        }
    }

    func scan(_ scaner: VEScan?, onScanCodeResult result: VEAlgorithmSessionResultScanCode?) {
        guard let resultScanCode = result else { return }
        Self.logger.info("on scanCode result")
        let codeList = resultScanCode.codeList
        if let err = resultScanCode.error {
            Self.logger.info("useTripartiteEnigma scan failure from ve error:\(err)")
            return
        }
        guard let codeResults = codeList as? [VEAlgorithmSessionCodeItem], !codeResults.isEmpty else {
            Self.logger.info("useTripartiteEnigma scan codeResult isEmpty")
            return
        }
        let currentScannedResult = codeResults.map { $0.content }
        if let lastScannedResult = lastScannedResult,
            Set(currentScannedResult) == Set(lastScannedResult),
            let lastScannedTime = lastScannedTime,
            Date().timeIntervalSince(lastScannedTime) < 1 {
            Self.logger.info("VEScanner: filtering repetition currentScannedResult: \(currentScannedResult.count) lastScannedResult: \(lastScannedResult.count)")
            return
        }
        // 保存此次扫描的结果和时间
        lastScannedResult = currentScannedResult
        lastScannedTime = Date()

        var lensName: String?
        if #available(iOS 15.0, *) {
            lensName = scaner?.activePrimaryConstituentDevice()?.deviceType.rawValue
            Self.logger.info("on scan complete lensName:\(String(describing: lensName))")
        }
        if codeResults.count == Self.moreScanCodeTag {
            guard let codeItem = resultScanCode.codeList.firstObject as? VEAlgorithmSessionCodeItem,
                    let content = codeItem.content else {
                return
            }
            CodeScanTool.execInMainThread {
                self.stopCamera()
            }
            self.cameraScanObservable.onNext((content, self.tranfrom(codeType: codeItem.codeType), lensName))
        } else {
            CodeScanTool.execInMainThread {
                self.scanerSuspend?(true)
            }
            Self.logger.info("useTripartiteEnigma scan success codeCount: \(codeList.count) scanImageSize:\(String(describing: result?.image?.size)) screenWidth:\(screenWidth) screenHeight:\(screenHeight)")
            multicodeProcess(by: codeResults, image: resultScanCode.image, lensName: lensName)
        }
    }

    func scan(_ scaner: VEScan?, onRecLumaDetectResult result: VELumaDetectResult) {
        guard enableLumaDetect else { return }
        if lumaSence != Int(result.scene) {
            lumaSence = Int(result.scene)
            Self.logger.info("ScanCode.Scanner: LumaDetect scene \(result.scene)")
            scanerLumaDetectHandler?(Int(result.scene))
        }
    }
    func scan(_ scaner: VEScan?, onRecCaptureSessionEvent type: VE_CAPTURE_SESSION_EVENT_TYPE) {
    }

    func onRecCaptureFrameEvent(from scaner: VEScan?) {
        isFirstFrameToken.once {
            Self.logger.info("ScanCode.Scanner: return first CaptureFrame")
        }
        scanerCameraCaptureFrameHandler?()
    }

    func scanLumaDetect() {
        guard let scanner = scanner else { return }
        scanner.enableLumaDetect(withDetectFrame: 1)
    }

    private func isLandscape() -> Bool {
        guard Display.pad else { return false }
        if #available(iOS 13.0, *) {
            let interfaceOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation
            return interfaceOrientation == .landscapeLeft || interfaceOrientation == .landscapeRight
        } else {
            let orientation = UIDevice.current.orientation
            return orientation == .landscapeLeft || orientation == .landscapeRight
        }
    }

    private func transformVEScanQRCodeResult(by codeItem: VEAlgorithmSessionCodeItem, error: Error?) -> VEScanQRCodeResult {
        let codeResult: VEScanQRCodeResult = VEScanQRCodeResult()
        if error != nil {
            codeResult.error = error
        }
        codeResult.content = codeItem.content
        codeResult.codeType = codeItem.codeType
        return codeResult
    }
}

extension VECodeScanner {
    enum Cons {
        static var locationCalculateNum: CGFloat = 0.5
        static var backZoomFactor: CGFloat = 1.0
        static var scanWidthResolutionRatio: CGFloat = 720
        static var scanHeightResolutionRatio: CGFloat = 1280
    }
}

extension ImagePickerViewController {
    func selectImage() -> Observable<UIImage> {
        return Observable.create { [weak self] (ob) -> Disposable in
            guard let self = self else {
                return Disposables.create()
            }
            self.showSingleSelectAssetGridViewController()
            self.imagePikcerCancelSelect = { (_, _) in
                ob.onError(QRScanError.pickerCancel)
            }
            self.imagePickerFinishSelect = { (_, result) in
                guard let asset = result.selectedAssets.first,
                      let image = asset.originalImage() else {
                    ob.onError(QRScanError.pickerError)
                    return
                }
                ob.onNext(image)
                ob.onCompleted()
            }
            self.modalPresentationStyle = .fullScreen
            return Disposables.create()
        }
    }
}
