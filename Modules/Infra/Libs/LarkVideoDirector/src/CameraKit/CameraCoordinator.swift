//
//  CameraCoordinator.swift
//  LarkVideoDirector
//
//  Created by Saafo on 2023/7/18.
//

import UIKit
import RxSwift // DisposeBag
import LarkMedia // AVAudioSession
import LarkUIKit // Utils
import LarkCamera // LarkCamera
import LarkMonitor // BDPowerLogManager
import LarkFoundation // Utils
import LarkImageEditor // LarkImageEditor
import LKCommonsTracker // Tracker

internal final class CameraCoordinator: NSObject {
    var config: LarkCameraKit.CameraConfig
    weak var vc: UIViewController?

    private let audioQueue = DispatchQueue(label: "lvd.LarkCameraKit.audioQueue")
    private let scene: MediaMutexScene
    private var scenario: AudioSessionScenario?
    private var imageEditorDidFinish: ((UIImage) -> Void)?
    private var mediaInterruptionInfo: (scene: MediaMutexScene, msg: String?)?
    private var disposeBag = DisposeBag()

    init(config: LarkCameraKit.CameraConfig, scene: MediaMutexScene) {
        self.config = config
        self.scene = scene
    }

    deinit {
        // Coordinator 生命周期跟随 VC, VC 销毁时解锁
        LarkMediaManager.shared.unlock(scene: scene)
        LarkCameraKit.logger.debug("unlock media mutex \(scene)")
        LarkCameraKit.logger.debug("CameraCoordinator deinit")
    }
}

// MARK: Utils

private extension CameraCoordinator {
    func didCancel() {
        LarkCameraKit.asyncInMain { [weak self] in
            guard let self else { return }
            var error: LarkCameraKit.Error.Recording?
            if let info = self.mediaInterruptionInfo {
                error = .mediaInterrupted(info.scene, info.msg)
            }
            self.config.didCancel?(error)
            self.mediaInterruptionInfo = nil
        }
    }

    func saveMediaIfNeeded(image: UIImage? = nil, video: URL? = nil, completion: ((Bool, Bool) -> Void)? = nil) {
        guard config.autoSave else {
            LarkCameraKit.logger.debug("not save media")
            completion?(false, false)
            return
        }
        if let image {
            Utils.savePhoto(image: image) { success, granted in
                LarkCameraKit.logger.debug("save photo \(success) \(granted)")
                completion?(success, granted)
            }
        } else if let video {
            Utils.saveVideo(url: video) { success, granted in
                LarkCameraKit.logger.debug("save video \(success) \(granted)")
                completion?(success, granted)
            }
        } else {
            LarkCameraKit.logger.debug("skip save media")
            completion?(false, false)
        }
    }
}

// MARK: Camera Delegate

extension CameraCoordinator: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var targetImage: UIImage?
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            targetImage = image
        } else if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            targetImage = image
        }
        if let targetImage = targetImage {
            LarkCameraKit.logger.info("finish photo taken: \(targetImage)")
            CameraTracker.didTakePhoto(from: .system, image: targetImage, with: nil)
            self.saveMediaIfNeeded(image: targetImage) { [weak self, weak picker] success, granted in
                guard let self, let picker else { return }
                LarkCameraKit.asyncInMain {
                    self.config.didTakePhoto?(targetImage, picker, success, granted)
                }
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            LarkCameraKit.asyncInMain {
                self.config.didCancel?(nil)
            }
        }
    }
}

extension CameraCoordinator: LarkCameraControllerDelegate {
    func camera(_ camera: LarkCameraController, log message: String, error: Error?) {
        if let error {
            LarkCameraKit.logger.error(message, error: error)
        } else {
            LarkCameraKit.logger.info(message)
        }
    }

    func camera(_ camera: LarkCameraController, didTake photo: UIImage, with lensName: String?) {
        LarkCameraKit.logger.info("finish takenPhoto from lark camera: \(photo)")
        CameraTracker.didTakePhoto(from: .lark, image: photo, with: lensName)
        editImageIfNeeded(photo, from: camera, didFinish: { [weak self, weak camera] image in
            guard let self, let camera else { return }
            self.saveMediaIfNeeded(image: image) { [weak self, weak camera] success, granted in
                guard let self, let camera else { return }
                self.restAVAudioSessionScenario()
                LarkCameraKit.asyncInMain {
                    self.config.didTakePhoto?(image, camera, success, granted)
                }
            }
        })
    }

    func camera(_ camera: LarkCameraController, didFinishRecordVideoAt url: URL) {
        LarkCameraKit.logger.info("finish takenVideo from lark camera: \(url)")
        CameraTracker.didRecordVideo(from: .lark, url: url)
        saveMediaIfNeeded(video: url) { [weak self, weak camera] success, granted in
            guard let self, let camera else { return }
            self.restAVAudioSessionScenario()
            LarkCameraKit.asyncInMain {
                self.config.didRecordVideo?(url, camera, success, granted)
            }
        }
    }

    func cameraDidDismiss(_ camera: LarkCameraController) {
        self.restAVAudioSessionScenario()
        didCancel()
    }

    /// 为了统一将对AVAudioSession的设置代理出来
    func camera(_ camera: LarkCameraController,
                set category: CameraController.AudioSessionCategory,
                with options: CameraController.AudioSessionCategoryOptions) {
        let audioScenario = AudioSessionScenario("LarkCameraKit", category: category, mode: .default, options: options)
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

    func cameraViewDidAppear(_ camera: LarkCameraController) {
        BDPowerLogManager.beginEvent("messenger_video_record", params: ["scene": "camera"])
    }
    func cameraViewDidDisappear(_ camera: LarkCameraController) {
        BDPowerLogManager.endEvent("messenger_video_record", params: ["scene": "camera"])
    }
    func cameraVideoPreviewDidAppear(_ camera: LarkCameraController) {
        BDPowerLogManager.beginEvent("messenger_video_preview", params: ["scene": "camera"])
    }
    func cameraVideoPreviewDidDisappear(_ camera: LarkCameraController) {
        BDPowerLogManager.endEvent("messenger_video_preview", params: ["scene": "camera"])
    }
}

extension CameraCoordinator: LVDCameraControllerDelegate {
    func cameraDidDismiss(from vc: UIViewController) {
        didCancel()
    }

    func cameraTakePhoto(_ image: UIImage, from lens: String?, controller vc: UIViewController) {
        LarkCameraKit.logger.info("finish takenPhoto from new Camera: \(image)")
        CameraTracker.didTakePhoto(from: .ve, image: image, with: lens)
        editImageIfNeeded(image, from: vc, didFinish: { [weak self, weak vc] image in
            guard let self, let vc else { return }
            self.saveMediaIfNeeded(image: image) { [weak self, weak vc] success, granted in
                guard let self, let vc else { return }
                self.config.didTakePhoto?(image, vc, success, granted)
            }
        })
    }

    func cameraTakeVideo(_ videoURL: URL, controller vc: UIViewController) {
        LarkCameraKit.logger.info("finish takenVideo from new Camera: \(videoURL)")
        CameraTracker.didRecordVideo(from: .ve, url: videoURL)
        saveMediaIfNeeded(video: videoURL) { [weak self, weak vc] success, granted in
            guard let self, let vc else { return }
            self.config.didRecordVideo?(videoURL, vc, success, granted)
        }
    }
}

// MARK: ImageEditor

extension CameraCoordinator {
    private func editImageIfNeeded(_ image: UIImage,
                                   from vc: UIViewController,
                                   didFinish: ((UIImage) -> Void)? = nil) {
        guard config.afterTakePhotoAction == .enterImageEditor else {
            didFinish?(image)
            return
        }
        let imageEditor = ImageEditorFactory.createEditor(with: image)
        imageEditor.delegate = self
        imageEditor.editEventObservable.subscribe(onNext: { (event) in
            Tracker.post(TeaEvent(event.event, params: event.params ?? [:]))
        }).disposed(by: disposeBag)
        imageEditorDidFinish = { image in
            didFinish?(image)
        }
        vc.navigationController?.pushViewController(imageEditor, animated: false)
    }
}

extension CameraCoordinator: ImageEditViewControllerDelegate {
    func closeButtonDidClicked(vc: EditViewController) {
        vc.navigationController?.popViewController(animated: true)
    }

    func finishButtonDidClicked(vc: EditViewController, editImage: UIImage) {
        LarkCameraKit.logger.info("finish image edit \(editImage)")
        imageEditorDidFinish?(editImage)
        imageEditorDidFinish = nil
    }
}

// MARK: MediaMutex

extension CameraCoordinator: MediaResourceInterruptionObserver {
    public func mediaResourceWasInterrupted(by scene: MediaMutexScene, type: MediaMutexType, msg: String?) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.mediaInterruptionInfo = (scene, msg)
            LarkCameraKit.logger.warn("interrupted by \(scene) \(type)")
            self.vc?.dismiss(animated: false)
        }
    }

    public func mediaResourceInterruptionEnd(from scene: MediaMutexScene, type: MediaMutexType) {
    }
}
