//
//  CameraPreviewView.swift
//  Camera
//
//  Created by Kongkaikai on 2018/11/11.
//

import UIKit
import Foundation
import AVFoundation

final class CameraPreviewView: UIView {
    private var gravity: CameraController.VideoGravity = .resizeAspect

    lazy var videoPreviewLayer: AVCaptureVideoPreviewLayer = {
        //swiftlint:disable force_cast
        let previewlayer = layer as! AVCaptureVideoPreviewLayer
        //swiftlint:enable force_cast
        previewlayer.videoGravity = gravity
        return previewlayer
    }()

    var session: AVCaptureSession? {
        get { return videoPreviewLayer.session }
        set { videoPreviewLayer.session = newValue }
    }

    init(frame: CGRect, videoGravity: CameraController.VideoGravity) {
        gravity = videoGravity
        super.init(frame: frame)
        self.backgroundColor = UIColor.black
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override class var layerClass: AnyClass { return  AVCaptureVideoPreviewLayer.self }
}
