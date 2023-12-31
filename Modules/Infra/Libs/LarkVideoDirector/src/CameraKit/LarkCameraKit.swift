//
//  LarkCameraKit.swift
//  LarkVideoDirector
//
//  Created by Saafo on 2023/7/4.
//

import UIKit
import LarkMedia // AVAudioSession
import LarkUIKit // Utils
import LarkCamera // LarkCamera
import LarkSetting // FG
import AVFoundation // AVCaptureDevice
import LarkContainer // UserResolver
import LarkFoundation // Utils
import LarkSceneManager // isMainScene
import LKCommonsLogging // Logger
import UniverseDesignDialog // UDDialog
import LarkSensitivityControl // PSDA

public enum LarkCameraKit {

    public struct CameraConfig {

        /// 相机类型
        public enum CameraType : CaseIterable, Identifiable {
            /// 系统相机
            case system
            /// LarkCamera
            case lark
            /// 自动
            ///
            /// 目前国内使用 CK 相机，海外或 iPad 非主窗口使用 LarkCamera
            /// - Note: 使用 CK 相机需要注意在主工程引入 CKNLE subspec，否则会降级到 lark 相机
            case automatic

            public var id: Self { self }
        }

        /// 拍照后行为
        public enum AfterTakePhotoAction: CaseIterable, Identifiable {
            /// 显示预览页（目前只有 LarkCamera 支持）
            case showPreview
            /// 进入图片编辑器（目前只有 LarkCamera 和 CK 相机支持）
            case enterImageEditor
            /// 直接返回图片
            case returnImage

            public var id: Self { self }
        }

        /// 录像后行为
        public enum AfterRecordVideoAction {
            /// 进入视频编辑器（目前只有 CK 相机支持）
            case enterVideoEditor
        }

        /// 媒体类型
        public enum MediaType: CaseIterable, Identifiable {
            /// 只允许拍照
            case photoOnly
            /// 只允许录像（目前只有 LarkCamera 和 CK 相机支持）
            case videoOnly
            /// 允许拍照和录像（目前只有 LarkCamera 和 CK 相机支持）
            case photoAndVideo

            public var id: Self { self }
        }

        // Callbacks

        /// 拍照回调
        ///
        /// 参数：（图片，VC，自动保存是否成功，保存相册权限是否授予）
        /// - Note: 注意：
        /// * 必须在该回调中主动调用 vc.dismiss(animated:)
        /// * 当 ``autoSave`` 为 false 时，后两个参数始终为 false
        public var didTakePhoto: ((UIImage, UIViewController, Bool, Bool) -> Void)?

        /// 录像回调
        ///
        /// 参数：（视频URL，VC，自动保存是否成功，保存相册权限是否授予）
        /// - Note: 注意：
        /// * 必须在该回调中主动调用 vc.dismiss(animated:)
        /// * 当 ``autoSave`` 为 false 时，后两个参数始终为 false
        public var didRecordVideo: ((URL, UIViewController, Bool, Bool) -> Void)?

        /// 取消回调
        ///
        /// 用户主动关闭相机页面时会回调这个闭包
        ///
        /// 参数：当用户正常退出，参数为空；如果是被打断音频而退出，参数非空
        public var didCancel: ((Error.Recording?) -> Void)?

        // Configs

        /// 相机类型
        public var cameraType: CameraType = .automatic

        /// 拍照后行为
        public var afterTakePhotoAction: AfterTakePhotoAction = .enterImageEditor

        /// 录像后行为
        public var afterRecordVideoAction: AfterRecordVideoAction = .enterVideoEditor

        /// 媒体类型
        public var mediaType: MediaType = .photoAndVideo

        /// 是否自动保存照片/视频
        public var autoSave: Bool = true

        /// 相机位置，前摄 or 后摄
        ///
        /// 默认为上次进入的位置/后摄
        public var cameraPosition: AVCaptureDevice.Position = .unspecified

        /// 视频最大录制时长
        ///
        /// 大于 1 时生效，否则为默认值（LarkCamera 为 15s，CK 为 30s）
        public var videoMaxDuration: TimeInterval = 0

        /// 创建相机失败时，展示默认弹窗
        public var showDialogWhenCreatingFailed: Bool = false

        public init() {}
    }

    public enum Error {
        /// 创建相机时错误
        public enum Creating: Swift.Error {
            /// 不支持模拟器
            case notSupportSimulator
            /// 没有相机权限
            case noVideoPermission
            /// 没有录音权限
            case noAudioPermission
            /// 媒体资源被其他 scene 占用
            /// - scene: 当前占用的场景
            /// - msg: 通用错误文案
            case mediaOccupiedByOthers(MediaMutexScene, String?)
        }
        /// 进入相机后错误
        public enum Recording: Swift.Error {
            /// 媒体资源被打断
            ///
            /// 参数：（打断者的场景，打断通用文案）
            case mediaInterrupted(MediaMutexScene, String?)
        }
    }

    internal static let logger = Logger.log(LarkCameraKit.self, category: "LarkCameraKit")

    /// 创建相机的便利方法，内置了默认配置，提供给简单拍照的场景
    ///
    /// 行为对齐 LarkUIKit.BaseUIViewController.takePhoto()
    /// 业务方不需要 present,但是需要在回调中 dismiss
    public static func takePhoto(
        from vc: UIViewController,
        userResolver: UserResolver,
        mutatingConfig: ((inout CameraConfig) -> Void)? = nil,
        didCancel: ((Swift.Error?) -> Void)? = nil,
        completion: ((UIImage, UIViewController) -> Void)? = nil
    ) {
        var config = CameraConfig()
        config.autoSave = false
        config.mediaType = .photoOnly
        config.didCancel = { error in
            didCancel?(error)
        }
        config.didTakePhoto = { image, camera, _, _ in
            completion?(image, camera)
        }
        config.showDialogWhenCreatingFailed = true
        mutatingConfig?(&config)
        createCamera(with: config, from: vc, userResolver: userResolver) { result in
            switch result {
            case .success(let camera):
                vc.present(camera, animated: true)
            case .failure(let error):
                didCancel?(error)
            }
        }
    }

    /// 生成相机 VC
    ///
    /// - Note: 注意：
    /// * 生成后需要业务方打开页面，业务方也需要在结果回调中关闭页面
    /// * 会异步校验相机录音权限和 MediaMutex 锁
    /// * 生成失败时可以通过 ``LarkCameraKit/CameraConfig/showDialogWhenCreatingFailed`` 展示默认弹窗提示用户
    public static func createCamera(with config: CameraConfig,
                                    from vc: UIViewController,
                                    userResolver: UserResolver,
                                    completion: @escaping ((Result<UIViewController, Error.Creating>) -> Void)) {
        let dealResult: ((Result<UIViewController, Error.Creating>) -> Void) = { result in
            switch result {
            case .success(let vc):
                vc.modalPresentationStyle = .fullScreen
                completion(.success(vc))
            case .failure(let error):
                Self.logger.error("createCamera failed: \(error)")
                if config.showDialogWhenCreatingFailed {
                    showDefaultDialog(for: error, from: vc, completion: { completion(result) })
                } else {
                    completion(result)
                }
            }
        }

        guard !Utils.isSimulator else {
            dealResult(.failure(.notSupportSimulator))
            return
        }
        checkSystemPermission(with: config) { result in
            switch result {
            case .success:
                tryLockMediaMutex(with: config) { result in
                    asyncInMain {
                        switch result {
                        case .success(let coordinator):
                            dealResult(getCamera(with: config, from: vc,
                                                 coordinator: coordinator, userResolver: userResolver))
                        case .failure(let error):
                            dealResult(.failure(error))
                        }
                    }
                }
            case .failure(let error):
                asyncInMain {
                    dealResult(.failure(error))
                }
            }
        }
    }

    // MARK: Check

    private static func checkSystemPermission(with config: CameraConfig,
                                              completion: @escaping ((Result<Void, Error.Creating>) -> Void)) {
        let checkMicrophonePermission = {
            // 系统相机暂不支持录像，不检测麦克风权限
            if case .system = config.cameraType {
                completion(.success(()))
                return
            }
            if case .photoOnly = config.mediaType {
                completion(.success(()))
                return
            }
            let microphoneAuth = AVAudioSession.sharedInstance().recordPermission
            switch microphoneAuth {
            case .undetermined:
                do {
                    try AudioRecordEntry.requestRecordPermission(
                        forToken: .init(withIdentifier: "LARK-PSDA-camerakit_request_record_permission"),
                        session: .sharedInstance()) { granted in
                            if granted {
                                completion(.success(()))
                            } else {
                                completion(.failure(.noAudioPermission))
                            }
                        }
                } catch {
                    completion(.failure(.noAudioPermission))
                }
            case .denied:
                completion(.failure(.noAudioPermission))
            case .granted:
                completion(.success(()))
            @unknown default:
                fatalError()
            }
        }
        let videoAuth = AVCaptureDevice.authorizationStatus(for: .video)
        switch videoAuth {
        case .notDetermined:
            do {
                try CameraEntry.requestAccessCamera(
                    forToken: .init(withIdentifier: "LARK-PSDA-camerakit_request_video_access")) { granted in
                        if granted {
                            checkMicrophonePermission()
                        } else {
                            completion(.failure(.noVideoPermission))
                        }
                    }
            } catch {
                completion(.failure(.noVideoPermission))
            }
        case .denied, .restricted:
            completion(.failure(.noVideoPermission))
        case .authorized:
            checkMicrophonePermission()
        @unknown default:
            fatalError()
        }
    }

    private static func tryLockMediaMutex(with config: CameraConfig,
                                          completion: @escaping ((Result<CameraCoordinator, Error.Creating>) -> Void)) {
        let scene: MediaMutexScene = config.mediaType == .photoOnly ? .commonCamera : .commonVideoRecord
        let coordinator = CameraCoordinator(config: config, scene: scene)
        logger.debug("try lock media mutex")
        LarkMediaManager.shared.tryLock(scene: scene, observer: coordinator) { result in
            switch result {
            case .success(let resource):
                if #available(iOS 17, *) {
                    resource.microphone.requestMute(false) { _ in
                        // 这里暂时忽略是否成功，因为可能 scene 不带录音权限，只做尝试性的解除静音
                        completion(.success(coordinator))
                    }
                } else {
                    completion(.success(coordinator))
                }
            case .failure(let error):
                logger.error("try Lock failed \(error)")
                if case .occupiedByOther(let scene, let msg) = error {
                    if let msg {
                        completion(.failure(.mediaOccupiedByOthers(scene, msg)))
                    }
                } else {
                    completion(.success(coordinator))
                }
            }
        }
    }

    // MARK: getCamera

    private static func getCamera(with config: CameraConfig,
                                  from vc: UIViewController,
                                  coordinator: CameraCoordinator,
                                  userResolver: UserResolver) -> Result<UIViewController, Error.Creating> {
        switch config.cameraType {
        case .system:
            return getSystemCamera(with: config, coordinator: coordinator)
        case .lark:
            return .success(getLarkCamera(with: config, coordinator: coordinator, userResolver: userResolver))
        case .automatic:
            if useCKCamera(from: vc, userResolver: userResolver) {
                return .success(getCKCamera(with: config, coordinator: coordinator))
            } else {
                return .success(getLarkCamera(with: config, coordinator: coordinator, userResolver: userResolver))
            }
        }
    }

    private static func getSystemCamera(with config: CameraConfig,
                                        coordinator: CameraCoordinator) -> Result<UIViewController, Error.Creating> {
        let systemPicker: UIImagePickerController
        do {
            systemPicker = try AlbumEntry.createImagePickerController(
                forToken: .init(withIdentifier: "LARK-PSDA-camerakit_init_system_camera")
            )
        } catch {
            return .failure(.noVideoPermission)
        }
        systemPicker.sourceType = .camera
        systemPicker.cameraDevice = config.cameraPosition == .front ? .front : .rear

        systemPicker.lvdCameraCoordinator = coordinator
        systemPicker.delegate = coordinator
        coordinator.vc = systemPicker
        return .success(systemPicker)
    }

    private static func getLarkCamera(with config: CameraConfig,
                                      coordinator: CameraCoordinator,
                                      userResolver: UserResolver) -> UIViewController {
        let larkCamera = LarkCameraController(nibName: nil, bundle: nil,
                                              shouldShowPreview: config.afterTakePhotoAction == .showPreview)
        switch config.mediaType {
        case .photoOnly:
            larkCamera.mediaType = .photo
        case .videoOnly:
            larkCamera.mediaType = .video
        case .photoAndVideo:
            larkCamera.mediaType = .all
        }
        switch config.cameraPosition {
        case .front:
            larkCamera.defaultCameraPosition = .front
        case .back:
            larkCamera.defaultCameraPosition = .back
        default:
            break
        }
        larkCamera.lazyAudio = true
        let minMaxDuration: Double = 1
        if config.videoMaxDuration > minMaxDuration {
            larkCamera.maxVideoDuration = config.videoMaxDuration
        }

        let navigation = UINavigationController(rootViewController: larkCamera)
        navigation.lvdCameraCoordinator = coordinator
        larkCamera.delegate = coordinator
        coordinator.vc = navigation
        return navigation
    }

    /// 在 FG 开启、Main Scene、有 CKNLE subspec 时才会使用 CK 相机
    private static func useCKCamera(from vc: UIViewController, userResolver: UserResolver) -> Bool {
        let isMainScene: Bool = {
            if #available(iOS 13, *),
               Display.pad,
               let windowScene = vc.view.window?.windowScene,
               !windowScene.sceneInfo.isMainScene() {
                return false
            }
            return true
        }()
        if userResolver.fg.staticFeatureGatingValue(with: "messenger.mobile.ve_camera"),
           LVDCameraService.available(),
           isMainScene {
            return true
        }
        return false
    }

    private static func getCKCamera(with config: CameraConfig,
                                    coordinator: CameraCoordinator) -> UIViewController {
        let cameraType: LVDCameraType
        switch config.mediaType {
        case .photoOnly:
            cameraType = .onlySupportPhoto
        case .videoOnly:
            cameraType = .onlySupportVideo
        case .photoAndVideo:
            cameraType = .supportPhotoAndVideo
        }

        let ckCamera = LVDCameraService.cameraController(with: coordinator,
                                                         cameraType: cameraType,
                                                         cameraPosition: config.cameraPosition,
                                                         videoMaxDuration: config.videoMaxDuration)
        let navigation = UINavigationController(rootViewController: ckCamera)
        navigation.lvdCameraCoordinator = coordinator
        coordinator.vc = navigation
        return navigation
    }

    // MARK: Dialog

    private static func showDefaultDialog(for error: Error.Creating, from vc: UIViewController,
                                          completion: @escaping () -> Void) {
        let permissionDialog = { title, detail in
            let dialog = UDDialog()
            dialog.setTitle(text: title)
            dialog.setContent(text: detail)
            dialog.addSecondaryButton(text: BundleI18n.LarkVideoDirector.Lark_Legacy_Cancel, dismissCompletion: completion)
            dialog.addPrimaryButton(text: BundleI18n.LarkVideoDirector.Lark_Legacy_Setting, dismissCompletion: {
                completion()
                if let appSettings = URL(string: UIApplication.openSettingsURLString),
                   UIApplication.shared.canOpenURL(appSettings) {
                    UIApplication.shared.open(appSettings)
                }
            })
            return dialog
        }
        let normalDialog = { content in
            let dialog = UDDialog()
            dialog.setContent(text: content)
            dialog.addPrimaryButton(text: BundleI18n.LarkVideoDirector.Lark_Legacy_Sure, dismissCompletion: completion)
            return dialog
        }
        var dialog: UDDialog?
        switch error {
        case .noVideoPermission:
            dialog = permissionDialog(BundleI18n.LarkVideoDirector.Lark_Core_CameraAccess_Title,
                                      BundleI18n.LarkVideoDirector.Lark_Core_CameraAccessForPhoto_Desc())
        case .noAudioPermission:
            dialog = permissionDialog(BundleI18n.LarkVideoDirector.Lark_Core_MicrophoneAccess_Title,
                                      BundleI18n.LarkVideoDirector
                .Lark_Core_EnableMicrophoneAccess_RecordAudioDuringVideoRecording())
        case .notSupportSimulator:
            #if DEBUG
            dialog = normalDialog("camera not supported on simulator")
            #endif
        case .mediaOccupiedByOthers(_, let message):
            if let message {
                dialog = normalDialog(message)
            }
        }
        if let dialog {
            vc.present(dialog, animated: true)
        }
    }
}

// MARK: Utils

extension LarkCameraKit {
    internal static func asyncInMain(execute work: @escaping @convention(block) () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }
}

extension UINavigationController {
    private static var cameraCoordinatorKey = "LVDCameraCoordinator"
    fileprivate var lvdCameraCoordinator: CameraCoordinator? {
        get {
            objc_getAssociatedObject(self, &Self.cameraCoordinatorKey) as? CameraCoordinator
        }
        set {
            objc_setAssociatedObject(self, &Self.cameraCoordinatorKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
