//
//  LVDCameraServiceInterface.swift
//  LarkVideoDirector
//
//  Created by Saafo on 2023/7/7.
//

import UIKit
import AVFoundation

//@objc
//public protocol LVDCameraControllerDelegate: NSObjectProtocol {
//
//    @objc
//    func cameraTakePhoto(_ image: UIImage, from lens: NSString, controller vc: UIViewController)
//
//    @objc
//    func cameraTakeVideo(_ videoURL: URL, controller vc: UIViewController)
//
//    @objc
//    func cameraDidDismiss(from vc: UIViewController)
//}
//
//@objc
//public protocol LVDVideoEditorControllerDelegate: NSObjectProtocol {
//    @objc
//    func editorTakeVideo(_ videoURL: URL, controller vc: UIViewController)
//}
//
//@objc
//public protocol LVDCameraServiceProtocol: NSObjectProtocol {
//    @objc
//    static func available() -> Bool
//
//    @objc
//    static func setCameraSupport1080(_ support: Bool)
//
//    @objc
//    static func cameraSupport1080() -> Bool
//
//    @objc
//    static func cameraController(with delegate: LVDCameraControllerDelegate,
//                                 cameraType: LVDCameraType) -> UIViewController
//    @objc
//    static func cameraController(with delegate: LVDCameraControllerDelegate,
//                                 cameraType: LVDCameraType,
//                                 cameraPosition position: AVCaptureDevice.Position,
//                                 videoMaxDuration maxDuration: TimeInterval) -> UIViewController
//    @objc
//    static func videoEditorController(with delegate: LVDVideoEditorControllerDelegate,
//                                      assets: [AVAsset],
//                                      from vc: UIViewController) -> UIViewController
//}
//
//@objc
//public enum LVDCameraType: Int {
//    case supportPhotoAndVideo
//    case onlySupportPhoto
//    case onlySupportVideo
//}

#if !VideoDirectorIncludesCKNLE
// 没有集成 CKNLE 的 Mock 实现

@objc(LVDCameraService)
public final class LVDCameraService: NSObject, LVDCameraServiceProtocol {
    public static func available() -> Bool {
        false // Mock 实现
    }

    public static func setCameraSupport1080(_ support: Bool) {}

    public static func cameraSupport1080() -> Bool {
        false
    }

    public static func cameraController(with delegate: LVDCameraControllerDelegate,
                                        cameraType: LVDCameraType) -> UIViewController {
        getNotSupportVC()
    }

    public static func cameraController(with delegate: LVDCameraControllerDelegate,
                                        cameraType: LVDCameraType,
                                        cameraPosition position: AVCaptureDevice.Position,
                                        videoMaxDuration maxDuration: TimeInterval) -> UIViewController {
        getNotSupportVC()
    }

    public static func videoEditorController(with delegate: LVDVideoEditorControllerDelegate,
                                             assets: [AVAsset],
                                             from vc: UIViewController) -> UIViewController {
        getNotSupportVC()
    }

    private static func getNotSupportVC() -> UIViewController {
        let vc = UIViewController()
        let button = UIButton()
        vc.view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
            button.topAnchor.constraint(equalTo: vc.view.topAnchor),
            button.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor),
        ])
        vc.view.backgroundColor = .black
        button.setTitle("Feature not supported\n\nTap to Dismiss", for: .normal)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.setTitleColor(.systemBlue, for: .normal)
        button.addTarget(vc, action: #selector(vc.dismissWithAnimate), for: .touchUpInside)
        return vc
    }
}

private extension UIViewController {
    @objc
    func dismissWithAnimate() {
        dismiss(animated: true)
    }
}

#endif
