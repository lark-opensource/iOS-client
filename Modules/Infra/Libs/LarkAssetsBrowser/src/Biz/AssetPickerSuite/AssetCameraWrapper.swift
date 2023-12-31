//
//  AssetCameraWrapper.swift
//  LarkAssetsBrowser
//
//  Created by aslan on 2022/4/15.
//

import UIKit
import Foundation
import LarkCamera
import AVFoundation
import LarkMedia
import LarkSetting
import LarkMonitor

@available(*, deprecated, message: "use LarkCameraKit instead")
public final class AssetCameraWrapper {

    public var outPutLog: ((String, Error?) -> Void)?
    public var didTakePhoto: ((UIImage) -> Void)?
    public var didFinishRecord: ((URL) -> Void)?
    public var didDismiss: (() -> Void)?

    public let camera: LarkCameraController = WrappedLarkCameraController(nibName: nil, bundle: nil, shouldShowPreview: false)

    private var scenario: AudioSessionScenario?
    private let scene: MediaMutexScene
    private let audioQueue = DispatchQueue(label: "asset.camera.wrapper.queue")

    public init() {
        self.scene = camera.mediaType == .photo ? .commonCamera : .commonVideoRecord
        camera.delegate = self
        camera.lazyAudio = true
    }

    public func present(vc: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        camera.wrapper = self
        vc.present(camera, animated: animated, completion: completion)
    }

    public func dismissCamera(animated: Bool, completion: (() -> Void)? = nil) {
        camera.dismiss(animated: animated) { [weak self] in
            if let completion = completion {
                completion()
            }
            self?.restAVAudioSessionScenario()
        }
    }
}

extension AssetCameraWrapper: LarkCameraControllerDelegate {
    public func camera(_ camera: LarkCameraController, log message: String, error: Error?) {
        self.outPutLog?(message, error)
    }

    public func camera(_ camera: LarkCameraController, didTake photo: UIImage, with lensName: String?) {
        self.didTakePhoto?(photo)
    }

    public func camera(_ camera: LarkCameraController, didFinishRecordVideoAt url: URL) {
        self.didFinishRecord?(url)
    }

    public func cameraDidDismiss(_ camera: LarkCameraController) {
        self.restAVAudioSessionScenario()
        self.didDismiss?()
    }

    /// 为了统一将对AVAudioSession的设置代理出来
    public func camera(_ camera: LarkCameraController,
                       set category: CameraController.AudioSessionCategory,
                       with options: CameraController.AudioSessionCategoryOptions) {
        let audioScenario = AudioSessionScenario("LarkCameraWrapper", category: category, mode: .default, options: options)
        self.scenario = audioScenario
        if let resource = LarkMediaManager.shared.getMediaResource(for: scene) {
            self.audioQueue.async {
                resource.audioSession.enter(audioScenario)
            }
        }
    }

    private func restAVAudioSessionScenario() {
        if let scenario = scenario, let resource = LarkMediaManager.shared.getMediaResource(for: scene) {
            self.audioQueue.async {
                resource.audioSession.leave(scenario)
            }
        }
    }
    
    public func cameraViewDidAppear(_ camera: LarkCameraController) {
        BDPowerLogManager.beginEvent("messenger_video_record", params: ["scene": "camera"])
    }
    public func cameraViewDidDisappear(_ camera: LarkCameraController) {
        BDPowerLogManager.endEvent("messenger_video_record", params: ["scene": "camera"])
    }
    public func cameraVideoPreviewDidAppear(_ camera: LarkCameraController) {
        BDPowerLogManager.beginEvent("messenger_video_preview", params: ["scene": "camera"])
    }
    public func cameraVideoPreviewDidDisappear(_ camera: LarkCameraController) {
        BDPowerLogManager.endEvent("messenger_video_preview", params: ["scene": "camera"])
    }
}

extension LarkCameraController {
    static var cameraWrappedKey = "LarkCameraWrappedKey"
    fileprivate var wrapper: AssetCameraWrapper? {
        get {
            return objc_getAssociatedObject(self, &LarkCameraController.cameraWrappedKey) as? AssetCameraWrapper
        }

        set {
            objc_setAssociatedObject(self, &LarkCameraController.cameraWrappedKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

/// 如果在小程序中打开 Camera，将 App 退出后台，通过 AppLink 再打开其他页面。这种情况下，CameraVC 可能被替换掉而没有调用到 dismissCamera。
/// 这种 case 下，wrapper 和 camera 的相互引用不会被打破。因此这里继承 LarkCameraController，覆写 dismiss 方法，在此时机来打破循环。
fileprivate final class WrappedLarkCameraController: LarkCameraController {
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag) {
            completion?()
            self.wrapper = nil
        }
    }
}
