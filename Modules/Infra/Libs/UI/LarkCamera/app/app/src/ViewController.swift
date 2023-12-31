//
//  ViewController.swift
//  CameraDemo
//
//  Created by Kongkaikai on 2018/11/9.
//  Copyright © 2018 Kongkaikai. All rights reserved.
//

import Foundation
import UIKit
import LarkCamera
import MobileCoreServices
import UniverseDesignColor
import AVFoundation
import Photos

class ViewController: UIViewController {
    private var startButton: UIButton = UIButton()
    private var progressButton: CameraButton = CameraButton(frame: CGRect(x: 100, y: 300, width: 100, height: 100))
    private var systemCamera: UIButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        startButton.frame = CGRect(x: 50, y: 500, width: 100, height: 100)
        startButton.layer.cornerRadius = 16
        startButton.setTitle("Custom", for: .normal)
        startButton.addTarget(self, action: #selector(showCustomCramera), for: .touchUpInside)
        startButton.addTarget(self, action: #selector(showNonLazyCamera), for: .touchDragInside)
        view.addSubview(startButton)
        startButton.backgroundColor = UIColor.ud.G400
        view.backgroundColor = UIColor.ud.bgBase

        progressButton.onTap = { (tap) in
            print("Tap")
        }

        let name: (_ state: CameraButton.LongPressState) -> String = { (state) in
            switch state {
            case .began:
                return "began"
            case .ended:
                return "ended"
            case .richMaxDuration:
                return "richMaxDuration"
            case .move(let offset):
                return "move\(offset)"
            }
        }

        progressButton.onLongPress = { (state) in
            print("longPress: " + name(state))
        }

        progressButton.duration = 3
        view.addSubview(progressButton)

        systemCamera.frame = CGRect(x: 200, y: 500, width: 100, height: 100)
        systemCamera.layer.cornerRadius = 16
        systemCamera.setTitle("System", for: .normal)
        systemCamera.addTarget(self, action: #selector(showSystemCamera), for: .touchUpInside)
        view.addSubview(systemCamera)
        systemCamera.backgroundColor = UIColor.ud.B400

        let recordVCButton = UIButton(frame: CGRect(x: 50, y: 650, width: 100, height: 100))
        recordVCButton.backgroundColor = .ud.O400
        recordVCButton.layer.cornerRadius = 16
        recordVCButton.setTitle("Record", for: .normal)
        recordVCButton.addTarget(self, action: #selector(pushRecord), for: .touchUpInside)
        view.addSubview(recordVCButton)
    }

    @objc
    fileprivate func showCustomCramera() {
        let customCameraController = LarkCameraController()
        customCameraController.lazyAudio = true
        customCameraController.delegate = self
        customCameraController.modalPresentationStyle = .fullScreen
        self.present(customCameraController, animated: true, completion: nil)
    }

    @objc
    fileprivate func showNonLazyCamera() {
        let customCameraController = LarkCameraController()
        customCameraController.delegate = self
        customCameraController.modalPresentationStyle = .fullScreen
        self.present(customCameraController, animated: true, completion: nil)
    }

    @objc
    fileprivate func showSystemCamera() {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        controller.videoQuality = .typeMedium
        controller.videoMaximumDuration = 15
        navigationController?.present(controller, animated: true, completion: {
            print("Success ")
        })
    }

    @objc
    private func pushRecord() {
        let controller = RecorderVC()
        navigationController?.pushViewController(controller, animated: true)
    }
}

extension ViewController: LarkCameraControllerDelegate {
    func camera(_ camera: LarkCameraController, log message: String, error: Error?) {
        if let error {
            print("❤️ " + message + " error: \(error)")
        } else {
            print(message)
        }
    }

    func camera(_ camera: LarkCameraController, didTake photo: UIImage, with lensName: String?) {
        camera.dismiss(animated: true, completion: nil)
    }

    func camera(_ camera: LarkCameraController, didFinishRecordVideoAt url: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url) }) { saved, error in
                let length = (try? Data(contentsOf: url).count) ?? -1
                if saved, length < 50 * 1024 * 1024, length > 0 {
                    print("saved")
                } else {
                    print("💛 save warning, length: \(length), error: \(String(describing: error))")
                }
            }
        camera.dismiss(animated: true, completion: nil)
    }

    /// 为了统一将对AVAudioSession的设置代理出来
    func camera(_ camera: LarkCameraController,
                set category: CameraController.AudioSessionCategory,
                with options: CameraController.AudioSessionCategoryOptions) {
        do {
            try AVAudioSession.sharedInstance().setCategory(category, mode: .default, options: options)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❤️ set audio session category failed: \(error)")
        }
    }

    func cameraDidDismiss(_ camera: LarkCameraController) {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("❤️ set audio session inactive failed: \(error)")
        }
    }
}
