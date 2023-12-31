//
//  LarkCameraController.swift
//  Camera
//
//  Created by Kongkaikai on 2018/11/20.
//  Copyright © 2018 Kongkaikai. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import LarkStorage

public protocol LarkCameraControllerDelegate: AnyObject {
    func camera(_ camera: LarkCameraController, log message: String, error: Error?)

    func camera(_ camera: LarkCameraController, didTake photo: UIImage, with lensName: String?)
    func camera(_ camera: LarkCameraController, didFinishRecordVideoAt url: URL)

    /// 为了统一将对AVAudioSession的设置代理出来
    func camera(_ camera: LarkCameraController,
                set category: CameraController.AudioSessionCategory,
                with options: CameraController.AudioSessionCategoryOptions)

    /// 退出时调用，以便于调用者处理一些事情
    func cameraDidDismiss(_ camera: LarkCameraController)
    func cameraViewDidAppear(_ camera: LarkCameraController)
    func cameraViewDidDisappear(_ camera: LarkCameraController)
    func cameraVideoPreviewDidAppear(_ camera: LarkCameraController)
    func cameraVideoPreviewDidDisappear(_ camera: LarkCameraController)
}

public extension LarkCameraControllerDelegate {
    func camera(_ camera: LarkCameraController, log message: String, error: Error?) {}
    func camera(_ camera: LarkCameraController, didTake photo: UIImage, with lensName: String?) {}
    func camera(_ camera: LarkCameraController, didFinishRecordVideoAt url: URL) {}
    func camera(_ camera: LarkCameraController,
                set category: CameraController.AudioSessionCategory,
                with options: CameraController.AudioSessionCategoryOptions) {}
    func cameraDidDismiss(_ camera: LarkCameraController) {}
    func cameraViewDidAppear(_ camera: LarkCameraController) {}
    func cameraViewDidDisappear(_ camera: LarkCameraController) {}
    func cameraVideoPreviewDidAppear(_ camera: LarkCameraController) {}
    func cameraVideoPreviewDidDisappear(_ camera: LarkCameraController) {}
}

open class LarkCameraController: UIViewController {
    public enum MediaType {
        case photo
        case video

        /// video && photo
        case all
    }

    public enum CameraPosition: Int {
        case back
        case front
    }

    /// video quality
    public var videoQuality: AVCaptureSession.Preset = .hd1920x1080 {
        didSet {
            recordController.videoQuality = videoQuality
        }
    }

    /// record video max duraion
    public var maxVideoDuration: CFTimeInterval = 15 {
        didSet {
            progressButton.duration = maxVideoDuration
        }
    }

    /// Support Media Type
    public var mediaType: MediaType = .all {
        didSet {
            if mediaType == .photo {
                progressButton.isLongPressEnable = false
            }
            tipsLabel.isHidden = mediaType != .all
        }
    }

    /// Whether start audio capture at start of the camera or start of capturing
    public var lazyAudio: Bool = false {
        didSet {
            recordController.lazyAudio = lazyAudio
        }
    }

    private let recordController: CameraController

    /// 初始摄像头方向 默认后置
    public var defaultCameraPosition: CameraPosition = .back {
        didSet {
            switch defaultCameraPosition {
            case .back:
                recordController.defaultCamera = .back
            case .front:
                recordController.defaultCamera = .front
            }
        }
    }

    private let progressButton: CameraButton
    private let cancelButton: UIButton
    private let switchButton: UIButton
    private let focusView: UIImageView
    private let tipsLabel: UILabel
    private let shouldShowPreview: Bool

    public weak var delegate: LarkCameraControllerDelegate?

    /// Disable view autorotation for forced portrait recorindg
    override open var shouldAutorotate: Bool {
        return recordController.shouldAutorotate
    }

    public convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    public init(nibName nibNameOrNil: String?,
                bundle nibBundleOrNil: Bundle?,
                shouldShowPreview: Bool = true) {

        let makeFrame: (_ size: CGFloat) -> CGRect = { (size) in
            return CGRect(origin: .zero, size: CGSize(width: size, height: size))
        }

        progressButton = CameraButton(frame: makeFrame(100))
        cancelButton = UIButton(frame: makeFrame(40))
        switchButton = UIButton(frame: makeFrame(40))
        focusView = UIImageView(frame: makeFrame(61))
        tipsLabel = UILabel()
        self.shouldShowPreview = shouldShowPreview

        recordController = CameraController()

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        recordController.cameraDelegate = self
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        initRecord()
        bindingEvent()

        self.navigationController?.isNavigationBarHidden = true
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // iPad 不再限制录制过程中的重新布局
        if recordController.isVideoRecording && UIDevice.current.userInterfaceIdiom == .phone { return }

        let width = view.bounds.width
        let height = view.bounds.height
        let bottomMargin: CGFloat = 70

        let centerY = height - bottomMargin - 35 // 35 是小的圆的半径，但是整个View按照大圆设置的Frame
        progressButton.center = CGPoint(x: width / 2, y: centerY - view.safeAreaInsets.bottom)

        cancelButton.center = CGPoint(
            x: (width - progressButton.bounds.width) / 4,
            y: progressButton.center.y)

        switchButton.center = CGPoint(
            x: width - (width - progressButton.bounds.width) / 4,
            y: progressButton.center.y)

        let size = tipsLabel.textRect(
            forBounds: CGRect(x: 0, y: 0, width: width - 32, height: CGFloat.greatestFiniteMagnitude),
            limitedToNumberOfLines: 2).size

        tipsLabel.frame = CGRect(
            origin: CGPoint(x: (width - size.width) / 2, y: progressButton.frame.minY - 5 - size.height),
            size: size)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        focus(at: view.center)
        delegate?.cameraViewDidAppear(self)
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.cameraViewDidDisappear(self)
    }
}

// record
fileprivate extension LarkCameraController {

    func initRecord() {

        addChild(recordController)

        recordController.shouldPrompToAppSettings = true
        recordController.shouldUseDeviceOrientation = true
        recordController.isAudioEnabled = mediaType == .photo ? false : true
        recordController.isAllowAutoRotate = true
        recordController.flashMode = .off
        recordController.videoQuality = videoQuality
        recordController.videoGravity = .resizeAspect
        /// 调用 recordController.view 会开始 recordController 的生命周期
        recordController.view.frame = view.bounds
        view.addSubview(recordController.view)
        view.addSubview(progressButton)
        view.addSubview(cancelButton)
        view.addSubview(switchButton)
        view.addSubview(focusView)
        view.addSubview(tipsLabel)

        cancelButton.setImage(Resources.cancel, for: .normal)
        cancelButton.addTarget(self, action: #selector(tapCancel), for: .touchUpInside)

        switchButton.setImage(Resources.switch, for: .normal)
        switchButton.addTarget(self, action: #selector(tapSwitchCrame), for: .touchUpInside)

        progressButton.duration = self.maxVideoDuration

        focusView.isHidden = true
        focusView.image = Resources.focusing

        tipsLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        tipsLabel.font = UIFont.systemFont(ofSize: 15)
        tipsLabel.text = BundleI18n.LarkCamera.Lark_Legacy_CameraRecordTip
        tipsLabel.numberOfLines = 2
        tipsLabel.textAlignment = .center
    }

    private func bindingEvent() {
        progressButton.onTap = { [weak self] (_) in
            guard self?.mediaType == .all || self?.mediaType == .photo else { return }
            self?.progressButton.isUserInteractionEnabled = false
            self?.recordController.takePhoto()
        }

        progressButton.onLongPress = { [weak self] (state) in
            guard self?.mediaType == .all || self?.mediaType == .video else { return }

            switch state {
            case .began:
                self?.switchControl(true)
                self?.recordController.startVideoRecording()
            case .move(let offset):
                self?.recordController.zoomVideo(with: offset)
            case .ended:
                self?.switchControl(false)
                self?.recordController.stopVideoRecording()
            case .richMaxDuration:
                self?.recordController.stopVideoRecording()
            }
        }
    }

    private func switchControl(_ isHidden: Bool) {
        cancelButton.isHidden = isHidden
        switchButton.isHidden = isHidden
        if mediaType == .all {
            tipsLabel.isHidden = isHidden
        }
    }

    @objc
    func tapCancel() {
        self.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.cameraDidDismiss(self)
        }
    }

    @objc
    func tapSwitchCrame() {
        recordController.switchCamera()
    }
}

extension LarkCameraController: CameraControllerDelegate {

    public func camera(_ camera: CameraController, didTake photo: UIImage, with lensName: String?) {
        self.progressButton.isUserInteractionEnabled = true

        if shouldShowPreview {
            let preview = PhotoPreviewController()
            preview.image = photo
            preview.autoDisapper = false

            self.addChild(preview)
            self.view.addSubview(preview.view)

            preview.onTapSure = { [weak self] (_) in
                guard let `self` = self else { return }
                self.delegate?.camera(self, didTake: photo, with: lensName)
            }

            preview.onTapBack = { (controller) in
                controller.view.removeFromSuperview()
                controller.removeFromParent()
            }
        } else {
            self.delegate?.camera(self, didTake: photo, with: lensName)
        }
    }

    public func camera(_ camera: CameraController, didFinishProcessVideoAt url: URL) {
        let preview = VideoPreviewController()
        preview.videoURL = url
        preview.autoDisapper = false

        self.addChild(preview)
        self.view.addSubview(preview.view)

        preview.onTapSure = { [weak self] (_) in
            guard let `self` = self else { return }
            self.delegate?.camera(self, didFinishRecordVideoAt: url)
        }

        preview.onTapBack = { (controller) in
            controller.view.removeFromSuperview()
            controller.removeFromParent()
            try? AbsPath(url: url)?.notStrictly.removeItem()
        }
        preview.onViewDidAppear = { [weak self] in
            guard let self else { return }
            self.delegate?.cameraVideoPreviewDidAppear(self)
        }
        preview.onViewDidDisappear = { [weak self] in
            guard let self else { return }
            self.delegate?.cameraVideoPreviewDidDisappear(self)
        }
    }

    public func camera(_ camera: CameraController, didFailToTakePhoto error: Error) {
        self.progressButton.isUserInteractionEnabled = true
    }

    public func camera(_ camera: CameraController, didFocusAtPoint point: CGPoint) {
        focus(at: point)
    }

    public func camera(_ camera: CameraController, log message: String, error: Error?) {
        delegate?.camera(self, log: message, error: error)
    }

    public func camera(_ camera: CameraController,
                       set category: CameraController.AudioSessionCategory,
                       with options: CameraController.AudioSessionCategoryOptions) {
        delegate?.camera(self, set: category, with: options)
    }
}

fileprivate extension LarkCameraController {

    /// focus at point animation
    func focus(at point: CGPoint) {
        let focusView = self.focusView

        focusView.center = point
        focusView.alpha = 0.0
        focusView.isHidden = false

        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            focusView.alpha = 1.0
            focusView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        }, completion: { (_) in
            UIView.animate(withDuration: 0.15, delay: 0.5, options: .curveEaseInOut, animations: {
                focusView.alpha = 0.0
                focusView.transform = CGAffineTransform(translationX: 0.6, y: 0.6)
            }, completion: { (_) in
                focusView.isHidden = true
            })
        })
    }
}
