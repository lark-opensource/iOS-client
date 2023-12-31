//
//  CameraControllerDelegate.swift
//  Camera
//
//  Created by Kongkaikai on 2018/11/11.
//  Copyright © 2018 Kongkaikai. All rights reserved.
//

import Foundation
import UIKit

public protocol CameraControllerDelegate: AnyObject {

    /**
     CameraControllerDelegate function called when when CameraController session did start running.
     Photos and video capture will be enabled.

     - Parameter camera: Current CameraController
     */
    func cameraSessionDidStartRunning(_ camera: CameraController)

    /**
     CameraControllerDelegate function called when when CameraController session did stops running.
     Photos and video capture will be disabled.

     - Parameter camera: Current CameraController
     */
    func cameraSessionDidStopRunning(_ camera: CameraController)

    /**
     CameraControllerDelegate function called when the takePhoto() function is called.

     - Parameter camera: Current CameraController session
     - Parameter photo: UIImage captured from the current session
     - Parameter lensName: The primary (constituent) lens' name used to take the photo
     */
    func camera(_ camera: CameraController, didTake photo: UIImage, with lensName: String?)

    /**
     CameraControllerDelegate function called when CameraController begins recording video.

     - Parameter camera: Current CameraController session
     - Parameter camera: Current camera orientation
     */
    func camera(_ camera: CameraController, didBeginRecordingVideo session: CameraController.CameraSession)

    /**
     CameraControllerDelegate function called when CameraController finishes recording video.

     - Parameter camera: Current CameraController session
     - Parameter camera: Current camera orientation
     */
    func camera(_ camera: CameraController, didFinishRecordingVideo session: CameraController.CameraSession)

    /**
     CameraControllerDelegate function called when CameraController is done processing video.

     - Parameter camera: Current CameraController session
     - Parameter url: URL location of video in temporary directory
     */
    func camera(_ camera: CameraController, didFinishProcessVideoAt url: URL)

    /**
     CameraControllerDelegate function called when CameraController fails to take a photo.

     - Parameter camera: Current CameraController session
     - Parameter error: An error object that describes the problem
     */
    func camera(_ camera: CameraController, didFailToTakePhoto error: Error)

    /**
     CameraControllerDelegate function called when CameraController fails to record a video.

     - Parameter camera: Current CameraController session
     - Parameter error: An error object that describes the problem
     */
    func camera(_ camera: CameraController, didFailToRecordVideo error: Error)

    /**
     CameraControllerDelegate function called when CameraController switches between front or rear camera.

     - Parameter camera: Current CameraController session
     - Parameter camera: Current camera selection
     */
    func camera(_ camera: CameraController, didSwitchCameras session: CameraController.CameraSession)

    /**
     CameraControllerDelegate function called when CameraController view is tapped and begins focusing at that point.

     - Parameter camera: Current CameraController session
     - Parameter point: Location in view where camera focused
     */
    func camera(_ camera: CameraController, didFocusAtPoint point: CGPoint)

    /**
     CameraControllerDelegate function called when when CameraController view changes zoom level.

     - Parameter camera: Current CameraController session
     - Parameter zoom: Current zoom level
     */
    func camera(_ camera: CameraController, didChangeZoomLevel zoom: CGFloat)

    /**
     CameraControllerDelegate function called when when CameraController fails to confiture the session.

     - Parameter camera: Current CameraController
     */
    func cameraDidFailToConfigure(_ camera: CameraController)

    /**
     CameraControllerDelegate function called when when CameraController does not have access to camera or microphone.

     - Parameter camera: Current CameraController
     */
    func cameraNotAuthorized(_ camera: CameraController)

    /**
     CameraControllerDelegate function called when when CameraController encountering an error.

     - Parameter camera: Current CameraController
     - Parameter message: error message
     - Parameter error: error
     */
    func camera(_ camera: CameraController, log message: String, error: Error?)

    /// 为了统一将对AVAudioSession的设置代理出来
    func camera(_ camera: CameraController,
                set category: CameraController.AudioSessionCategory,
                with options: CameraController.AudioSessionCategoryOptions)
}

// Optional
public extension CameraControllerDelegate {
    func cameraSessionDidStartRunning(_ camera: CameraController) {}
    func cameraSessionDidStopRunning(_ camera: CameraController) {}
    func camera(_ camera: CameraController, didTake photo: UIImage, with lensName: String?) {}
    func camera(_ camera: CameraController, didBeginRecordingVideo session: CameraController.CameraSession) {}
    func camera(_ camera: CameraController, didFinishRecordingVideo session: CameraController.CameraSession) {}
    func camera(_ camera: CameraController, didFinishProcessVideoAt url: URL) {}
    func camera(_ camera: CameraController, didFailToTakePhoto error: Error) {
        self.camera(camera, log: "[Camera]: Failed to take photo", error: error)
    }
    func camera(_ camera: CameraController, didFailToRecordVideo error: Error) {
        self.camera(camera, log: "[Camera]: Failed to record video", error: error)
    }
    func camera(_ camera: CameraController, didSwitchCameras session: CameraController.CameraSession) { }
    func camera(_ camera: CameraController, didFocusAtPoint point: CGPoint) {}
    func camera(_ camera: CameraController, didChangeZoomLevel zoom: CGFloat) {}
    func cameraDidFailToConfigure(_ camera: CameraController) {
        self.camera(camera, log: "[Camera]: Failed to congigure", error: nil)
    }
    func cameraNotAuthorized(_ camera: CameraController) {
        self.camera(camera, log: "[Camera]: Not authorized", error: nil)
    }
    func camera(_ camera: CameraController, log message: String, error: Error?) {}
    func camera(
        _ camera: CameraController,
        set category: CameraController.AudioSessionCategory,
        with options: CameraController.AudioSessionCategoryOptions
    ) {}
}
