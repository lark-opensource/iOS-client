//
//  CameraController.swift
//  Camera
//
//  Created by Kongkaikai on 2018/11/9.
//  Copyright © 2018 Kongkaikai. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import AVFoundation
import CoreTelephony
import LarkSensitivityControl
import LarkStorage

public final class CameraController: UIViewController {

    public typealias VideoGravity = AVLayerVideoGravity
    public typealias VideoQuality = AVCaptureSession.Preset
    public typealias CameraSession = AVCaptureDevice.Position
    public typealias AudioSessionCategory = AVAudioSession.Category
    public typealias AudioSessionCategoryOptions = AVAudioSession.CategoryOptions
    public typealias FlashMode = AVCaptureDevice.FlashMode

    /**

     Result from the AVCaptureSession Setup

     - success: success
     - notAuthorized: User denied access to Camera of Microphone
     - configurationFailed: Unknown error
     */
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }

    public enum CameraError: Error {
        case getDeviceError
        case sessionNotRunning
        case connectionError
        case readDataBufferError
        case addIOError
        case fileOutputError
        case dataOutputError
        case fixCMSampleBufferTimeFailed(String)
        case appendDataFailed
    }

    /// Public Camera Delegate for the Custom View Controller Subclass
    public weak var cameraDelegate: CameraControllerDelegate?

    /// Video capture quality
    public var videoQuality: VideoQuality = .high

    // Flash Mode
    public var flashMode: FlashMode = .off

    /// Sets whether Pinch to Zoom is enabled for the capture session
    public var isPinchToZoomEnable: Bool = true

    /// Sets the maximum zoom scale allowed during gestures gesture
    public var maxZoomScale: CGFloat = .greatestFiniteMagnitude

    /// Sets whether Tap to Focus and Tap to Adjust Exposure is enabled for the capture session
    public var isTapToFocusEnable: Bool = true

    /// Sets whether the capture session should adjust to low light conditions automatically
    ///
    /// Only supported on iPhone 5 and 5C
    public var isLowLightBoostEnable: Bool = true

    /// Set whether Camera should allow background audio from other applications
    public var isBackgroundAudioEnable: Bool = true

    /// Sets whether a double tap to switch cameras is supported
    public var isDoubleTapCameraSwitchEnable: Bool = true

    /// Sets whether swipe vertically to zoom is supported
    public var isSwipeToZoomEnable: Bool = true

    /// Sets whether swipe vertically gestures should be inverted
    public var isSwipeToZoomInverted: Bool = false

    /// Set default launch camera
    public var defaultCamera: CameraSession = .back

    /// Sets wether the taken photo or video should be oriented according to the device orientation
    public var shouldUseDeviceOrientation: Bool = false {
        didSet {
            orientation.shouldUseDeviceOrientation = shouldUseDeviceOrientation
        }
    }

    /// Sets whether or not View Controller supports auto rotation
    public var isAllowAutoRotate: Bool = false

    /// Specifies the 'videoGravity' for the preview layer.
    public var videoGravity: VideoGravity = .resizeAspect

    public var videoSize: CGSize?

    /// Sets whether or not video recordings will record audio
    /// Setting to true will prompt user for access to microphone on View Controller launch.
    public var isAudioEnabled: Bool = true

    /// Sets whether or not app should display prompt to app settings if audio/video permission is denied
    /// If set to false, delegate function will be called to handle exception
    public var shouldPrompToAppSettings: Bool = true

    /// Video will be recorded to this folder
    private lazy var outputFolder: IsoPath = {
        let path = IsoPath.in(space: .global, domain: Domain.biz.core.child("LarkCamera"))
           .build(.temporary)
        try? path.createDirectoryIfNeeded()
        return path
    }()

    /// Whether start audio capture at start of the camera or start of capturing
    public var lazyAudio: Bool = false {
        didSet {
            log("lazyAudio set to \(lazyAudio)")
        }
    }

    /// Public access to Pinch Gesture
    private(set) public var pinchGesture: UIPinchGestureRecognizer?

    /// Public access to Pan Gesture
    private(set) public var panGesture: UIPanGestureRecognizer?

    // MARK: Public Get-only Variable Declarations

    /// Returns true if video is currently being recorded
    private(set) public var isVideoRecording: Bool = false

    /// Returns true if the capture session is currently running
    private(set) public var isSessionRunning: Bool = false

    /// Returns the CameraSelection corresponding to the currently utilized camera
    private(set) public var currentCamera: CameraSession = .back

    // MARK: Public Constant Declarations

    /// Current Capture Session
    public let session: AVCaptureSession = AVCaptureSession()

    public let audioSession: AVCaptureSession = AVCaptureSession()

    /// Serial queue used for setting up session
    private let sessionQueue: DispatchQueue = DispatchQueue(label: "session queue", attributes: [])

    // MARK: Private Variable Declarations

    /// The writer to compose video and audio steam data into file
    private var assetWriter: AVAssetWriter?

    /// State of AVAssetWriter
    private enum AssetWriterState {
        /// The asset writer is available
        case idle
        /// User is capturing, and assetWriter is writing
        case writing
        /// User stopped capture, but assetWriter is still waiting for last few video or audio data callback
        case finishing
        /// The asset writer finished writing, generating file
        case finished
    }

    /// The state of assetWriter
    private var assetWriterState: AssetWriterState = .idle

    /// Video data input of assetWriter
    private var videoDataInput: AVAssetWriterInput?

    /// Audio data input of assetWriter
    private var audioDataInput: AVAssetWriterInput?

    /// Flag of videoDataInput's state
    private var videoDataInputIsFinished: Bool = false

    /// Flag of audioDataInput's state
    private var audioDataInputIsFinished: Bool = false

    /// The time user start recording
    private var startRecordingTime: CMTime = .zero

    /// The time user end recording
    private var stopRecordingTime: CMTime = .zero

    /// Video data output from capture session, should pass to videoDataInput
    private var videoDataOutput: AVCaptureVideoDataOutput?

    /// Audio data output from capture session, should pass to audioDataInput
    private var audioDataOutput: AVCaptureAudioDataOutput?

    /// Exec assetWriter in this queue to avoid multi-thread problems
    private let assetWriterQueue = DispatchQueue(label: "com.larkCamera.assetWriter")

    /// Output video file path
    private var videoOutputFilePath: IsoPath?

    /// Variable for storing initial zoom scale before Pinch to Zoom begins
    private var beginZoomScale: CGFloat = 1.0

    /// Supported camera deviceType list
    private let supportedCameraTypes: [(deviceType: AVCaptureDevice.DeviceType, minZoomFactor: CGFloat)] = {
        var cameraList: [(deviceType: AVCaptureDevice.DeviceType, minZoomFactor: CGFloat)] = []
        if #available(iOS 13, *) {
            // triple and dualWide has ultra wide lens
            // we're expected to set the minimize zoom to 1
            // so we should set the factor to 2 on those two lens
            cameraList += [(.builtInTripleCamera, 2),
                           (.builtInDualWideCamera, 2)]
        }
        cameraList += [(.builtInDualCamera, 1),
                       (.builtInWideAngleCamera, 1)]
        return cameraList
    }()

    /// Returns true if the torch (flash) is currently enabled
    private var isCameraTorchOn: Bool = false

    /// Variable to store result of capture session setup
    private var setupResult: SessionSetupResult = .success

    /// BackgroundID variable for video recording
    private var backgroundRecordingID: UIBackgroundTaskIdentifier?

    /// Video Input device, should not be empty except configurationFailed
    private var videoDeviceInput: AVCaptureDeviceInput?

    /// Audio input device, will be empty if calling or audio is being used
    private var audioDeviceInput: AVCaptureDeviceInput?

    /// Movie File Output variable
    private var movieFileOutput: AVCaptureMovieFileOutput?

    /// Photo File Output variable
    private var photoFileOutput: AVCaptureStillImageOutput?

    /// Video Device variable
    private var videoDevice: AVCaptureDevice?

    /// PreviewView for the capture session
    private var previewLayer: CameraPreviewView?

    /// Alert view when session is isInterrupted
    private let alertLabel: UILabel = UILabel()

    /// UIView for front facing flash
    private var flashView: UIView?

    /// Pan Translation
    private var previousPanTranslation: CGFloat = 0.0

    /// Last changed orientation
    private var orientation: CameraOrientation = CameraOrientation()

    /// Boolean to store when View Controller is notified session is running
    private var sessionRunning: Bool = false

    /// Boolean to store user is calling
    private var userIsCalling: Bool = false

    /// Disable view autorotation for forced portrait recording
    override public var shouldAutorotate: Bool {
        return isAllowAutoRotate
    }

    /// max retry start session when runtime error
    private var maxRetryStartTimes = 5

    /// current retry start session when runtime error
    private var currentRetryStartTimes = 0

    // MARK: ViewDidLoad
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black

        let previewLayer = CameraPreviewView(frame: view.frame, videoGravity: videoGravity)
        self.previewLayer = previewLayer
        view.addSubview(previewLayer)
        view.sendSubviewToBack(previewLayer)

        alertLabel.textColor = UIColor.white
        alertLabel.numberOfLines = 0
        alertLabel.backgroundColor = UIColor.clear
        alertLabel.font = UIFont.systemFont(ofSize: 18)
        alertLabel.textAlignment = .center
        alertLabel.isHidden = true
        view.addSubview(alertLabel)

        addGestureRecognizers()
        previewLayer.session = session
        loadDeviceAuthorizationStatus()
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
        updatePreviewLayerOrientation()

        if #available(iOS 16.0, *) {
            // swiftlint:disable line_length
            self.cameraDelegate?.camera(
                self,
                log: "[Camera]: session isMultitaskingCameraAccessSupported \(self.session.isMultitaskingCameraAccessSupported) " +
                     "isMultitaskingCameraAccessEnabled \(self.session.isMultitaskingCameraAccessEnabled)",
                error: nil
            )
            // swiftlint:enable line_length
        }
    }

    // MARK: ViewDidLayoutSubviews

    /// ViewDidLayoutSubviews() Implementation
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        alertLabel.frame = CGRect(
            origin: CGPoint(x: 0, y: self.view.bounds.height / 2 - 22),
            size: CGSize(width: self.view.bounds.width, height: 44)
        )
        previewLayer?.frame = view.bounds
    }

    // MARK: viewWillTransition

    /// viewWillTransition Implementation
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] _ in
            self?.updatePreviewLayerOrientation()
        }
    }

    /// - Note: When rotate iPad from .portrait to .portraitUpsideDown, size of window or view will not change,
    ///         so `viewDidLayoutSubviews` will not be called.
    ///         Currently preview orientation is based on UIInterfaceOrientation,
    ///         so we call this function in `viewDidLoad` (for the first time) and after `viewWillTransition`,
    ///         instead of `viewDidLayoutSubviews`.
    private func updatePreviewLayerOrientation() {
        if let connection = self.previewLayer?.videoPreviewLayer.connection {
            defer { log("preview orientation changed to: \(connection.videoOrientation)") }
            guard shouldAutorotate else {
                connection.videoOrientation = .portrait
                return
            }
            connection.videoOrientation = orientation.getPreviewLayerOrientation()
        }
    }

    // MARK: ViewWillAppear

    /// ViewWillAppear(_ animated:) Implementation
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        func addObserver(with name: NSNotification.Name?, selector: Selector) {
            NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
        }

        addObserver(with: .AVCaptureSessionDidStartRunning, selector: #selector(captureSessionDidStartRunning))
        addObserver(with: .AVCaptureSessionDidStopRunning, selector: #selector(captureSessionDidStopRunning))
        addObserver(with: .AVCaptureSessionRuntimeError, selector: #selector(captureSessionRuntimeError))
        addObserver(with: UIApplication.didBecomeActiveNotification, selector: #selector(applicationDidBecomActive(_:)))

        if UIDevice.current.userInterfaceIdiom == .phone {
            addObserver(with: .AVCaptureSessionWasInterrupted, selector: #selector(captureSessionWasInterrupted))
            addObserver(with: .AVCaptureSessionInterruptionEnded, selector: #selector(applicationDidBecomActive))
        } else {
            addObserver(with: .AVCaptureSessionWasInterrupted, selector: #selector(updateUIWhenInterruptChanged))
            addObserver(with: .AVCaptureSessionInterruptionEnded, selector: #selector(updateUIWhenInterruptChanged))
            addObserver(with: .AVCaptureSessionDidStartRunning, selector: #selector(updateUIWhenInterruptChanged))
            addObserver(with: .AVCaptureSessionDidStopRunning, selector: #selector(updateUIWhenInterruptChanged))
        }
    }

    // MARK: ViewDidAppear

    /// ViewDidAppear(_ animated:) Implementation
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Subscribe to device rotation notifications
        if shouldUseDeviceOrientation {
            do {
                try orientation.start(with: view)
            } catch {
                log("Could not monitor accelerometer", error: error)
            }
        }

        // Set background audio preference
        setBackgroundAudioPreference()

        sessionQueue.async {
            switch self.setupResult {
            case .success: // Begin Session
                self.updateAudioInputIfNeeded()
                do {
                    try CameraEntry.startRunning(
                        forToken: CameraToken.viewDidAppearStartRunning,
                        session: self.session
                    )
                } catch {
                    DispatchQueue.main.async {
                        self.cameraDelegate?.cameraDidFailToConfigure(self)
                    }
                    return
                }
                self.isSessionRunning = self.session.isRunning

                // Preview layer video orientation can be set only after the connection is created
                DispatchQueue.main.async {
                    self.previewLayer?.videoPreviewLayer.connection?.videoOrientation =
                        self.orientation.getPreviewLayerOrientation()
                    var message = "start running isRunning \(self.session.isRunning) " +
                    "isInterrupted \(self.session.isInterrupted) " +
                    "inputs \(self.session.inputs) outputs \(self.session.outputs)"
                    if self.lazyAudio {
                        message += ", audio inputs \(self.audioSession.inputs), outputs \(self.audioSession.outputs)"
                    }
                    self.log(message)
                }

            case .notAuthorized:
                if self.shouldPrompToAppSettings {
                    self.promptToAppSettings()
                } else {
                    self.cameraDelegate?.cameraNotAuthorized(self)
                }
            case .configurationFailed:
                // Unknown Error
                DispatchQueue.main.async {
                    self.cameraDelegate?.cameraDidFailToConfigure(self)
                }
            }
        }
    }

    // MARK: ViewDidDisappear

    /// ViewDidDisappear(_ animated:) Implementation
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // swiftlint:disable notification_center_detachment
        NotificationCenter.default.removeObserver(self)
        //swiftlint:enable notification_center_detachment
        sessionRunning = false

        // If session is running, stop the session
        if self.isSessionRunning {
            self.session.stopRunning()
            self.isSessionRunning = false
        }

        //Disble flash if it is currently enabled
        disableFlash()

        // Unsubscribe from device rotation notifications
        if shouldUseDeviceOrientation {
            orientation.stop()
        }
    }
}

// MARK: public method
extension CameraController {
    // MARK: Public Functions

    /**
     Capture photo from current session
     UIImage will be returned with the SwiftyCamViewControllerDelegate function SwiftyCamDidTakePhoto(photo:)
     */
    public func takePhoto() {
        guard let device = videoDevice else {
            cameraDelegate?.camera(self, didFailToTakePhoto: CameraError.getDeviceError)
            return
        }

        if device.hasFlash, flashMode != .off {
            changeFlashSettings(device: device, mode: .on)
            capturePhotoAsyncronously(completionHandler: { (_) in })
        } else {
            if device.isFlashActive {
                changeFlashSettings(device: device, mode: .off)
            }
            capturePhotoAsyncronously(completionHandler: { (_) in })
        }
    }

    /**
     Begin recording video of current session
     SwiftyCamViewControllerDelegate function SwiftyCamDidBeginRecordingVideo() will be called
     */
    public func startVideoRecording() {
        guard sessionRunning else {
            cameraDelegate?.camera(
                self,
                log: "[Camera]: Cannot start video recoding. Capture session is not running", error: nil)
            cameraDelegate?.camera(self, didFailToRecordVideo: CameraError.sessionNotRunning)
            return
        }

        if currentCamera == .back, flashMode == .on {
            enableFlash()
        }

        if currentCamera == .front, flashMode == .on {
            let tmpView = UIView(frame: view.frame)
            tmpView.backgroundColor = UIColor.white
            tmpView.alpha = 0.85
            previewLayer?.addSubview(tmpView)
            flashView = tmpView
        }

        //Must be fetched before on main thread
        let previewOrientation = previewLayer?.videoPreviewLayer.connection?.videoOrientation

        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard !self.lazyAudio else { // using guard to preserve old git info
                guard self.assetWriterState == .idle else {
                    self.stopVideoRecording()
                    return
                }
                self.audioSession.startRunning()
                self.configureAssetWriter()
                DispatchQueue.main.async {
                    self.isVideoRecording = true
                    self.cameraDelegate?.camera(self, didBeginRecordingVideo: self.currentCamera)
                }
                return
            }
            guard let movieFileOutput = self.movieFileOutput else {
                self.cameraDelegate?.camera(self, didFailToRecordVideo: CameraError.fileOutputError)
                self.stopVideoRecording()
                return
            }
            if !movieFileOutput.isRecording {
                if UIDevice.current.isMultitaskingSupported {
                    self.tryEndBackgroundTask()
                    self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask {
                        self.tryEndBackgroundTask()
                    }
                }

                // Update the orientation on the movie file output video connection before starting recording.
                let movieFileOutputConnection = self.movieFileOutput?.connection(with: AVMediaType.video)

                //flip video output if front facing camera is selected
                if self.currentCamera == .front {
                    movieFileOutputConnection?.isVideoMirrored = true
                }
                if let videoOrientation = self.orientation.getVideoOrientation() ?? previewOrientation {
                    movieFileOutputConnection?.videoOrientation = videoOrientation
                }

                // Start recording to a temporary file.
                let outputFilePath = self.outputFolder + "\(UUID().uuidString).mov"
                do {
                    try CameraEntry.startRecording(
                        forToken: CameraToken.startVideoRecording,
                        movieFileOutput: movieFileOutput,
                        toOutputFile: outputFilePath.url, recordingDelegate: self)
                    self.isVideoRecording = true
                    DispatchQueue.main.async {
                        self.cameraDelegate?.camera(self, didBeginRecordingVideo: self.currentCamera)
                    }
                } catch {
                    self.cameraDelegate?.camera(self, didFailToRecordVideo: error)
                    self.stopVideoRecording()
                }
            } else {
                movieFileOutput.stopRecording()
                self.tryEndBackgroundTask()
            }
        }
    }

    func tryEndBackgroundTask() {
        guard let backgroundRecordingID = self.backgroundRecordingID else { return }
        UIApplication.shared.endBackgroundTask(backgroundRecordingID)
        self.backgroundRecordingID = nil
    }

    /**
     Stop video recording video of current session
     SwiftyCamViewControllerDelegate function SwiftyCamDidFinishRecordingVideo() will be called
     When video has finished processing, the URL to the video location will be returned by
     SwiftyCamDidFinishProcessingVideoAt(url:)
     */
    public func stopVideoRecording() {
        if self.isVideoRecording {
            self.isVideoRecording = false
            if lazyAudio {
                assetWriterQueue.async { [weak self] in
                    self?.assetWriterState = .finishing
                    let stopRecordingTime: CMTime = .current
                    self?.stopRecordingTime = stopRecordingTime
                    self?.log("stopVideoRecording at: \(stopRecordingTime.seconds)")
                }
            } else {
                movieFileOutput?.stopRecording()
                tryEndBackgroundTask()
            }
            disableFlash()

            if currentCamera == .front, flashMode == .on, flashView != nil {
                UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: {
                    self.flashView?.alpha = 0.0
                }, completion: { (_) in
                    self.flashView?.removeFromSuperview()
                })
            }
            self.cameraDelegate?.camera(self, didFinishRecordingVideo: self.currentCamera)
        }
    }

    /**
     Switch between front and rear camera
     SwiftyCamViewControllerDelegate function SwiftyCamDidSwitchCameras(camera:  will be
     return the current camera selection
     */
    public func switchCamera() {
        guard isVideoRecording != true else {
            cameraDelegate?.camera(
                self,
                log: "[Camera]: Switching between cameras while recording video is not supported", error: nil)
            return
        }

        guard session.isRunning else { return }

        currentCamera = currentCamera == .back ? .front : .back
        session.stopRunning()

        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.resetSessionInput()
            DispatchQueue.main.async {
                self.cameraDelegate?.camera(self, didSwitchCameras: self.currentCamera)
            }
        }

        // If flash is enabled, disable it as the torch is needed for front facing camera
        disableFlash()
    }

    /*
     reset session input
     */
    func resetSessionInput() {
        // remove and re-add inputs and outputs
        session.beginConfiguration()
        for input in self.session.inputs {
            self.session.removeInput(input)
        }
        if lazyAudio {
            audioSession.inputs.forEach { audioSession.removeInput($0) }
        }
        self.addInputs()
        session.commitConfiguration()
        try? CameraEntry.startRunning(
            forToken: CameraToken.resetSessionInputStartRunning,
            session: self.session
        )
    }

    /// check user calling state
    func checkUserIsCalling() -> Bool {
        do {
            if let calls = try DeviceInfoEntry.currentCalls(
                forToken: Token(withIdentifier: "LARK-PSDA-camera_audio_monitor"),
                callCenter: CTCallCenter()),
               !calls.isEmpty {
                return true
            }
            return false
        } catch {
            log("Could not fetch currentCalls by LarkSensitivityControl API", error: error)
            return false
        }
    }

    /// update audio input if needed
    func updateAudioInputIfNeeded() {
        if self.userIsCalling,
           !self.checkUserIsCalling() {
            self.resetSessionInput()
        }
    }
}

extension CameraController {

    /**
     Returns an AVCapturePreset from VideoQuality Enumeration
     - Parameter quality: ViewQuality enum
     - Returns: String representing a AVCapturePreset
     */
    /// Configure session, add inputs and outputs
    private func configureSession() {
        guard setupResult == .success else {
            return
        }

        currentCamera = defaultCamera

        session.beginConfiguration()
        session.automaticallyConfiguresApplicationAudioSession = false
        if lazyAudio { audioSession.beginConfiguration() }
        addInputs()
        if lazyAudio {
            configureVideoDataOutput()
            configureAudioDataOutput()
            audioSession.commitConfiguration()
        } else {
            configureVideoOutput()
        }
        configurePhotoOutput()
        session.commitConfiguration()
    }

    /// Add inputs after changing camera()
    private func addInputs() {
        configureVideoPreset()
        addVideoInput()
        if lazyAudio {
            addAudioInput(to: audioSession)
        } else {
            addAudioInput(to: session)
        }
    }

    // Front facing camera will always be set to VideoQuality.high
    // If set video quality is not supported, videoQuality variable will be set to VideoQuality.high
    /// Configure image quality preset
    private func configureVideoPreset() {
        if currentCamera == .front {
            session.sessionPreset = .high
        } else {
            if session.canSetSessionPreset(videoQuality) {
                session.sessionPreset = videoQuality
            } else {
                session.sessionPreset = .high
            }
        }
    }

    private func deviceWithMediaType(
        _ mediaType: AVMediaType,
        preferringPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
            supportedCameraTypes
                .lazy
                .compactMap({
                    try? CameraEntry.defaultCameraDeviceWithDeviceType(
                        forToken: CameraToken.getVideoDevice,
                        deviceType: $0.deviceType, position: position)
                })
                .first
    }

    private func addVideoInput() {
        videoDevice = deviceWithMediaType(.video, preferringPosition: currentCamera)
        if let device = videoDevice {
            do {
                try device.lockForConfiguration()
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                    if device.isSmoothAutoFocusSupported {
                        device.isSmoothAutoFocusEnabled = true
                    }
                }

                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }

                if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                    device.whiteBalanceMode = .continuousAutoWhiteBalance
                }

                if device.isLowLightBoostSupported, isLowLightBoostEnable {
                    device.automaticallyEnablesLowLightBoostWhenAvailable = true
                }

                device.unlockForConfiguration()
            } catch {
                cameraDelegate?.camera(self, log: "[Camera]: Error locking configuration", error: error)
            }
        }

        do {
            if let device = videoDevice {
                let videoDeviceInput = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(videoDeviceInput) {
                    session.addInput(videoDeviceInput)
                    self.videoDeviceInput = videoDeviceInput
                    // set zoom to logical 1 for ultra wide lens
                    // must after addInput to session to make it work
                    do {
                        try device.lockForConfiguration()
                        device.videoZoomFactor = minZoomFactor(for: device.deviceType)
                        device.unlockForConfiguration()
                    } catch {
                        log("Error locking configuration", error: error)
                    }
                } else {
                    cameraDelegate?.camera(
                        self,
                        log: "[Camera]: Could not add video device input to the session",
                        error: nil
                    )
                    setupResult = .configurationFailed
                    self.videoDeviceInput = nil
                    session.commitConfiguration()
                    return
                }
            }
        } catch {
            cameraDelegate?.camera(self, log: "[Camera]: Could not create video device input:", error: error)
            setupResult = .configurationFailed
            return
        }
    }

    /// Add Audio Inputs
    private func addAudioInput(to session: AVCaptureSession) {
        guard isAudioEnabled else {
            cameraDelegate?.camera(self, log: "[Camera]: Audio disable", error: nil)
            self.audioDeviceInput = nil
            return
        }
        if self.checkUserIsCalling() {
            self.userIsCalling = true
            cameraDelegate?.camera(self, log: "[Camera]: user is calling", error: CameraError.addIOError)
            self.audioDeviceInput = nil
            return
        } else {
            self.userIsCalling = false
        }
        do {
            if let audioDevice = try AudioRecordEntry.defaultAudioDevice(
                forToken: CameraToken.addAudioInput
            ) {
                let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
                if session.canAddInput(audioDeviceInput) {
                    session.addInput(audioDeviceInput)
                    self.audioDeviceInput = audioDeviceInput
                    return
                } else {
                    log("Could not add audio device input", error: CameraError.addIOError)
                }
            } else {
                log("Could not find an audio device", error: CameraError.addIOError)
            }
        } catch {
            log("Could not create audio device input", error: error)
        }
        self.audioDeviceInput = nil
    }

    /// Configure Movie Output
    private func configureVideoOutput() {
        let movieFileOutput = AVCaptureMovieFileOutput()

        if self.session.canAddOutput(movieFileOutput) {
            self.session.addOutput(movieFileOutput)
            if let connection = movieFileOutput.connection(with: AVMediaType.video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
            self.movieFileOutput = movieFileOutput
        } else {
            log("Could not add move file out.", error: CameraError.addIOError)
        }
    }

    /// configure video data output
    private func configureVideoDataOutput() {
        let videoDataOutput = AVCaptureVideoDataOutput()
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            if let connection = videoDataOutput.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    // when output to data stream, .auto on some devices will turn to .cinematic or .cinematicExtended
                    // which will lead to a 1s delay and is not acceptable
                    connection.preferredVideoStabilizationMode = .standard
                }
            }
            videoDataOutput.setSampleBufferDelegate(self, queue: assetWriterQueue)
            self.videoDataOutput = videoDataOutput
        } else {
            log("Could not add videoDataOutput.", error: CameraError.addIOError)
        }
    }

    /// configure audio data output
    private func configureAudioDataOutput() {
        let audioDataOutput = AVCaptureAudioDataOutput()
        if audioSession.canAddOutput(audioDataOutput) {
            audioSession.addOutput(audioDataOutput)
            audioDataOutput.setSampleBufferDelegate(self, queue: assetWriterQueue)
            self.audioDataOutput = audioDataOutput
        } else {
            log("Could not add audioDataOutput", error: CameraError.addIOError)
        }
    }

    /// configure asset writer when start recording
    private func configureAssetWriter() {
        let outputFilePath = outputFolder + "\(UUID().uuidString).mov"
        self.videoOutputFilePath = outputFilePath
        let assetWriter: AVAssetWriter
        do {
            assetWriter = try AVAssetWriter(outputURL: outputFilePath.url, fileType: .mov)
        } catch {
            log("create AVAssetWriter failed: ", error: error)
            cameraDelegate?.camera(self, didFailToRecordVideo: error)
            return
        }
        self.assetWriter = assetWriter

        let videoCompressionSettings = self.videoDataOutput?
            .recommendedVideoSettingsForAssetWriter(writingTo: .mov)
        let videoInput: AVAssetWriterInput
        if assetWriter.canApply(outputSettings: videoCompressionSettings, forMediaType: .video) {
            videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoCompressionSettings)
        } else {
            log("Could not configure video settings: \(String(describing: videoCompressionSettings)) " +
                "try init with empty config", error: CameraError.addIOError)
            videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: nil)
        }
        videoInput.expectsMediaDataInRealTime = true
        // we do mirror and orientation by transform for better performance
        videoInput.transform = self.orientation.getVideoTransform(for: self.currentCamera)
        assetWriter.add(videoInput)
        self.videoDataInput = videoInput

        let audioCompressionSettings = self.audioDataOutput?
            .recommendedAudioSettingsForAssetWriter(writingTo: .mov)
        if self.audioDeviceInput != nil { // only add audio when audio device available
            let audioInput: AVAssetWriterInput
            // Try to fix the bug when other app is using mic, the channel in recommended setting
            // is inconsistency with audioSession's channel. In such case, we log and ignore audio.
            // However, bad cases such as connect to AirPods and other app is using mic still exist,
            // result in odd(unclear) audio. This bug also exist in AVCaptureMovieFileOutput,
            // but using AVAudioRecorder or AudioQueue doesn't have the problem.
            // It's considered as some bug or configuration problem with AVCaptureSession,
            // and waiting for exploration.
            let avas = AVAudioSession.sharedInstance()
            let recommendedChannel = audioCompressionSettings?[AVNumberOfChannelsKey] as? Int ?? -1
            if recommendedChannel == avas.inputNumberOfChannels {
                if assetWriter.canApply(outputSettings: audioCompressionSettings, forMediaType: .audio) {
                    audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioCompressionSettings)
                } else {
                    log("Could not configure audio settings: \(String(describing: audioCompressionSettings)) " +
                        "try init with empty config", error: CameraError.addIOError)
                    audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: nil)
                }
                audioInput.expectsMediaDataInRealTime = true
                assetWriter.add(audioInput)
                self.audioDataInput = audioInput
            } else {
                log("Audio channel not compatible: \(recommendedChannel), \(avas.inputNumberOfChannels), " +
                    "AVAudioSession: \(avas.isOtherAudioPlaying), \(avas.currentRoute.inputs), " +
                    "recommended settings: \(String(describing: audioCompressionSettings))",
                    error: CameraError.addIOError)
                self.audioDataInput = nil
            }
        } else {
            log("Could not add audio input device to asset writer due to empty audioDeviceInput",
                error: CameraError.addIOError)
            self.audioDataInput = nil
        }

        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: .zero)
        self.startRecordingTime = .current
        self.assetWriterState = .writing
        log("startVideoRecording at \(self.startRecordingTime.seconds), writer: \(assetWriter) " +
            "inputs: \(assetWriter.inputs)")
    }

    /// Configure Photo Output
    private func configurePhotoOutput() {
        let photoFileOutput = AVCaptureStillImageOutput()

        if self.session.canAddOutput(photoFileOutput) {
            photoFileOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            self.session.addOutput(photoFileOutput)
            self.photoFileOutput = photoFileOutput
        } else {
            log("Could not add photo file out.", error: CameraError.addIOError)
        }
    }

    /**
     Returns a UIImage from Image Data.
     - Parameter imageData: Image Data returned from capturing photo from the capture session.
     - Returns: UIImage from the image data, adjusted for proper orientation.
     */
    private func processPhoto(_ imageData: Data) -> UIImage? {
        guard let dataProvider = CGDataProvider(data: imageData as CFData),
        let cgImageRef = CGImage(jpegDataProviderSource: dataProvider,
                                 decode: nil,
                                 shouldInterpolate: true,
                                 intent: .defaultIntent) else {
            return nil
        }

        // Set proper orientation for photo
        // If camera is currently set to front camera, flip image
        return UIImage(cgImage: cgImageRef,
                       scale: 1.0,
                       orientation: self.orientation.getImageOrientation(for: self.currentCamera))
    }

    private func capturePhotoAsyncronously(completionHandler: @escaping(Bool) -> Void) {
        guard sessionRunning else {
            cameraDelegate?.camera(self, log: "[Camera]: Cannot take photo. Capture session is not running", error: nil)
            cameraDelegate?.camera(self, didFailToTakePhoto: CameraError.sessionNotRunning)
            return
        }

        if let photoFileOutput,
           let videoConnection = photoFileOutput.connection(with: AVMediaType.video) {
            var lensName: String?
            if #available(iOS 15.0, *) {
                lensName = videoDevice?.activePrimaryConstituent?.deviceType.rawValue
            }
            do {
                try CameraEntry.captureStillImageAsynchronously(
                    forToken: CameraToken.capturePhoto,
                    photoFileOutput: photoFileOutput, fromConnection: videoConnection) { (sampleBuffer, _) in
                        if let buffer = sampleBuffer,
                           let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer),
                           let image = self.processPhoto(imageData) {

                            // Call delegate and return new image
                            DispatchQueue.main.async {
                                self.cameraDelegate?.camera(self, didTake: image, with: lensName)
                            }
                            completionHandler(true)
                        } else {
                            completionHandler(false)
                            self.cameraDelegate?.camera(self, didFailToTakePhoto: CameraError.readDataBufferError)
                        }
                    }
            } catch {
                completionHandler(false)
                cameraDelegate?.camera(self, didFailToTakePhoto: error)
            }
        } else {
            completionHandler(false)
            cameraDelegate?.camera(self, didFailToTakePhoto: CameraError.connectionError)
        }
    }

    /// Enable or disable flash for photo
    private func changeFlashSettings(device: AVCaptureDevice, mode: AVCaptureDevice.FlashMode) {
        do {
            try device.lockForConfiguration()
            device.flashMode = mode
            device.unlockForConfiguration()
        } catch {
            cameraDelegate?.camera(self, log: "[SwiftyCam]: ", error: error)
        }
    }

    /// Enable flash
    public func enableFlash() {
        if self.isCameraTorchOn == false {
            toggleFlash()
        }
    }

    /// Disable flash
    public func disableFlash() {
        if self.isCameraTorchOn {
            toggleFlash()
        }
    }

    /// Toggles between enabling and disabling flash
    private func toggleFlash() {

        // Flash is not supported for front facing camera
        guard self.currentCamera == .back else { return }

        let device = try? CameraEntry.defaultCameraDevice(
            forToken: CameraToken.toggleFlash
        )
        // Check if device has a flash
        if device?.hasTorch == true {
            do {
                try device?.lockForConfiguration()
                if device?.torchMode == .on {
                    device?.torchMode = .off
                    self.isCameraTorchOn = false
                } else {
                    do {
                        try device?.setTorchModeOn(level: 1.0)
                        self.isCameraTorchOn = true
                    } catch {
                        cameraDelegate?.camera(self, log: "[Camera]:", error: error)
                    }
                }
                device?.unlockForConfiguration()
            } catch {
                cameraDelegate?.camera(self, log: "[Camera]:", error: error)
            }
        }
    }

    func zoomVideo(with offset: CGPoint) {
        do {
            guard let captureDevice = videoDevice else {
                cameraDelegate?.camera(self, log: "[Camera]: Get device failed.", error: nil)
                return
            }
            try captureDevice.lockForConfiguration()

            let currentZoom = captureDevice.videoZoomFactor

            let videoZoomFactor = min(
                currentZoom + (offset.y / 75) * (isSwipeToZoomInverted ? 1 : -1),
                captureDevice.activeFormat.videoMaxZoomFactor)
            let minZoomFactor = minZoomFactor(for: captureDevice.deviceType)
            let zoomScale = min(maxZoomScale, max(minZoomFactor, videoZoomFactor))

            captureDevice.videoZoomFactor = zoomScale

            // Call Delegate function with current zoom scale
            DispatchQueue.main.async {
                self.cameraDelegate?.camera(self, didChangeZoomLevel: zoomScale)
            }

            captureDevice.unlockForConfiguration()

        } catch {
            cameraDelegate?.camera(self, log: "[Camera]: Error locking configuration", error: error)
        }
    }
}

// MARK: Authorization
private extension CameraController {
    func loadDeviceAuthorizationStatus() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            sessionQueue.suspend()
            do {
                try CameraEntry.requestAccessCamera(
                    forToken: CameraToken.requestAuth, completionHandler: { [weak self] granted in
                        guard let self = self else { return }

                        guard granted else {
                            self.setupResult = .notAuthorized
                            return
                        }

                        self.sessionQueue.resume()
                    })
            } catch {
                log("check authorization failed", error: error)
            }
        case .denied, .restricted:
            setupResult = .notAuthorized
            cameraDelegate?.camera(self, log: "[Camera]: check authorization failed", error: nil)
        @unknown default:
            break
        }
    }

    /// Handle Denied App Privacy Settings
    func promptToAppSettings() {

        DispatchQueue.main.async {
            let alertController = UIAlertController(
                title: BundleI18n.LarkCamera.Lark_Core_CameraAccess_Title,
                message: BundleI18n.LarkCamera.Lark_Core_CameraAccessForPhoto_Desc(),
                preferredStyle: .alert)
            alertController.addAction(UIAlertAction(
                title: BundleI18n.LarkCamera.Lark_Legacy_Cancel,
                style: .cancel,
                handler: nil))
            alertController.addAction(UIAlertAction(
                title: BundleI18n.LarkCamera.Lark_Legacy_Setting,
                style: .default,
                handler: { _ in
                    if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                    }
            }))
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

// MARK: OutputSampleBufferDelegate
extension CameraController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        guard let assetWriter, let videoDataInput else { return } // videoDataInput must exist
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let outputDescription = output == videoDataOutput ? "video" : "audio"
        let durationPerFrame = CMTime(value: 1, timescale: 30) // 30fps
        switch assetWriterState {
        case .finishing:
            // we finish capture after the real stop time
            // so we can capture the last frame completely
            guard timestamp - durationPerFrame > stopRecordingTime else {
                fallthrough
            }
            if output == videoDataOutput {
                videoDataInput.markAsFinished()
                videoDataInputIsFinished = true
            } else if output == audioDataOutput {
                audioDataInput?.markAsFinished()
                audioDataInputIsFinished = true
            }
            if videoDataInputIsFinished, (audioDataInputIsFinished || audioDataInput == nil) {
                self.assetWriterState = .finished // ignore coming samples
                let totalDuration = stopRecordingTime - startRecordingTime
                log("assetWriter end session, finishWriting: \(CACurrentMediaTime()), total: \(totalDuration.seconds)")
                assetWriter.endSession(atSourceTime: totalDuration)
                assetWriter.finishWriting { [weak self] in
                    guard let self, let videoOutputFilePath = self.videoOutputFilePath else {
                        self?.log("VideoOutputFilePath is nil, cannot finish process",
                                  error: CameraError.dataOutputError)
                        return
                    }
                    DispatchQueue.main.async {
                        self.cameraDelegate?.camera(self, didFinishProcessVideoAt: videoOutputFilePath.url)
                    }
                    let dataLength = (try? Data.read(from: videoOutputFilePath).count) ?? -1
                    self.log("assetWriter finished writing file: \(CACurrentMediaTime()), length: \(dataLength)")
                    // reset
                    self.assetWriterState = .idle
                    self.videoDataInputIsFinished = false
                    self.audioDataInputIsFinished = false
                    self.startRecordingTime = .zero
                    self.stopRecordingTime = .zero
                }
                sessionQueue.async {
                    self.audioSession.stopRunning()
                }
            }
        case .writing:
            // we start capture ahead of the real start time
            // so we can capture the very first frame completely
            guard timestamp + durationPerFrame > startRecordingTime else {
                log("data too early, discarded: \(outputDescription), \(timestamp.seconds), \(CACurrentMediaTime())")
                return
            }
            // fix time stamp to startRecordingTime
            let fixedTime = timestamp - startRecordingTime
            var timeFixedSampleBuffer: CMSampleBuffer
            switch sampleBuffer.fixTimeStamp(with: fixedTime) {
            case .success(let fixedSampleBuffer):
                timeFixedSampleBuffer = fixedSampleBuffer
            case .failure(let error):
                log("reset sample buffer's timestamp failed", error: error)
                return
            }
            // log samples at beginning or in the end
            var logTime: String?
            if startRecordingTime - durationPerFrame < timestamp,
               timestamp < startRecordingTime + durationPerFrame {
                logTime = "first"
            } else if stopRecordingTime - durationPerFrame < timestamp,
                      timestamp < stopRecordingTime + durationPerFrame {
                logTime = "last"
            }
            if let logTime {
                log("\(logTime) few \(outputDescription) sample, fixedTime: \(fixedTime.seconds), " +
                    "originTime: \(timestamp.seconds), currentTime: \(CACurrentMediaTime())")
            }
            // write to asset writer
            if output == videoDataOutput {
                guard videoDataInput.isReadyForMoreMediaData, videoDataInput.append(timeFixedSampleBuffer) else {
                    let message = "video, isReadyForMoreMediaData: \(videoDataInput.isReadyForMoreMediaData), " +
                        "assetWriter status: \(assetWriter.status), error: \(String(describing: assetWriter.error))"
                    log(message, error: CameraError.appendDataFailed)
                    return
                }
            } else if output == audioDataOutput {
                guard let audioDataInput else { return } // only write audio data when input is valid
                guard audioDataInput.isReadyForMoreMediaData,
                      audioDataInput.append(timeFixedSampleBuffer) else {
                    let message = "audio, isReadyForMoreMediaData: " +
                        "\(String(describing: audioDataInput.isReadyForMoreMediaData)), " +
                        "assetWriter status: \(assetWriter.status), error: \(String(describing: assetWriter.error))"
                    log(message, error: CameraError.appendDataFailed)
                    return
                }
            }
        default:
            return
        }
    }
}

// MARK: AVCaptureFileOutputRecordingDelegate
extension CameraController: AVCaptureFileOutputRecordingDelegate {

    /// Process newly captured video and write it to temporary directory
    public func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?) {

        if let currentBackgroundRecordingID = backgroundRecordingID {
            backgroundRecordingID = .invalid

            if currentBackgroundRecordingID != .invalid {
                UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
            }
        }

        if let currentError = error {
            cameraDelegate?.camera(self, log: "[SwiftyCam]: Movie file finishing error:", error: currentError)
            DispatchQueue.main.async {
                self.cameraDelegate?.camera(self, didFailToRecordVideo: currentError)
            }
        } else {
            //Call delegate function with the URL of the outputfile
            DispatchQueue.main.async {
                self.cameraDelegate?.camera(self, didFinishProcessVideoAt: outputFileURL)
            }
        }
    }
}

// MARK: - Gesture

private extension CameraController {

    /// Handle pinch gesture
    @objc
    func zoomGesture(pinch: UIPinchGestureRecognizer) {
        //ignore pinch
        guard isPinchToZoomEnable, self.currentCamera == .back,
              let captureDevice = self.videoDevice else { return }
        do {
            try captureDevice.lockForConfiguration()
            let minZoomFactor = minZoomFactor(for: captureDevice.deviceType)

            let zoomScale = min(maxZoomScale,
                                max(minZoomFactor,
                                    min(beginZoomScale * pinch.scale,
                                        captureDevice.activeFormat.videoMaxZoomFactor)))

            captureDevice.videoZoomFactor = zoomScale

            // Call Delegate function with current zoom scale
            DispatchQueue.main.async {
                self.cameraDelegate?.camera(self, didChangeZoomLevel: zoomScale)
            }

            captureDevice.unlockForConfiguration()

        } catch {
            cameraDelegate?.camera(self, log: "[Camera]: Error locking configuration", error: error)
        }
    }

    /// Handle single tap gesture
    @objc
    func singleTapGesture(tap: UITapGestureRecognizer) {
        // Ignore taps
        guard isTapToFocusEnable, let previewLayer else { return }

        let screenSize = previewLayer.bounds.size
        let tapPoint = tap.location(in: previewLayer)
        let focusX = tapPoint.y / screenSize.height
        let focusY = 1.0 - tapPoint.x / screenSize.width
        let focusPoint = CGPoint(x: focusX, y: focusY)

        if let device = videoDevice {
            do {
                try device.lockForConfiguration()

                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = focusPoint
                    device.focusMode = .autoFocus
                }
                device.exposurePointOfInterest = focusPoint
                device.exposureMode = .continuousAutoExposure
                device.unlockForConfiguration()

                //Call delegate function and pass in the location of the touch
                DispatchQueue.main.async {
                    self.cameraDelegate?.camera(self, didFocusAtPoint: tapPoint)
                }
            } catch {
                // just ignore
            }
        }
    }

    /// Handle double tap gesture
    @objc
    func doubleTapGesture(tap: UITapGestureRecognizer) {
        guard isDoubleTapCameraSwitchEnable else {
            return
        }
        switchCamera()
    }

    @objc
    func panGesture(pan: UIPanGestureRecognizer) {

        guard isSwipeToZoomEnable && self.currentCamera == .back else {
            //ignore pan
            return
        }

        let point: CGPoint = pan.translation(in: view)

        zoomVideo(with: CGPoint(x: 0, y: point.y - previousPanTranslation))

        if pan.state == .ended || pan.state == .failed || pan.state == .cancelled {
            previousPanTranslation = 0.0
        } else {
            previousPanTranslation = point.y
        }
    }

    /**
     Add pinch gesture recognizer and double tap gesture recognizer to currentView

     - Parameter view: View to add gesture recognzier

     */
    func addGestureRecognizers() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(zoomGesture(pinch:)))
        self.pinchGesture = pinchGesture
        pinchGesture.delegate = self
        previewLayer?.addGestureRecognizer(pinchGesture)

        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTapGesture(tap:)))
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.delegate = self
        previewLayer?.addGestureRecognizer(singleTapGesture)

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapGesture(tap:)))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.delegate = self
        previewLayer?.addGestureRecognizer(doubleTapGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGesture(pan:)))
        self.panGesture = panGesture
        panGesture.delegate = self
        previewLayer?.addGestureRecognizer(panGesture)
    }
}

// MARK: UIGestureRecognizerDelegate
extension CameraController: UIGestureRecognizerDelegate {
    /// Set beginZoomScale when pinch begins
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isKind(of: UIPinchGestureRecognizer.self),
           let zoomScale = videoDevice?.videoZoomFactor {
            beginZoomScale = zoomScale
        }
        return true
    }
}

// MARK: - Notifications handler

private extension CameraController {

    /// Called when Notification Center registers session starts running
    @objc
    func captureSessionDidStartRunning(_ notification: Notification) {
        let captureSession = notification.object as? AVCaptureSession
        cameraDelegate?.camera(
            self,
            log: "[Camera]: receive push \(notification.name) \(String(describing: notification.userInfo)) " +
                "from \(captureSession == session ? "video" : "audio") session",
            error: nil
        )
        guard captureSession == session else { return }
        sessionRunning = true
        DispatchQueue.main.async {
            self.cameraDelegate?.cameraSessionDidStartRunning(self)
        }
    }

    /// Called when Notification Center registers session stops running
    @objc
    func captureSessionDidStopRunning(_ notification: Notification) {
        let captureSession = notification.object as? AVCaptureSession
        cameraDelegate?.camera(
            self,
            log: "[Camera]: receive push \(notification.name) \(String(describing: notification.userInfo)) " +
            "from \(captureSession == session ? "video" : "audio") session",
            error: nil
        )
        guard captureSession == session else { return }
        sessionRunning = false
        DispatchQueue.main.async {
            self.cameraDelegate?.cameraSessionDidStopRunning(self)
        }
    }

    @objc
    func captureSessionRuntimeError(_ notification: Notification) {
        let captureSession = notification.object as? AVCaptureSession
        stopVideoRecording()
        cameraDelegate?.camera(
            self,
            log: "[Camera]: Capture session get runtime error \(String(describing: notification.userInfo)) " +
            "from \(captureSession == session ? "video" : "audio") session",
            error: notification.userInfo?[AVCaptureSessionErrorKey] as? Error
        )

        if self.currentRetryStartTimes >= self.maxRetryStartTimes {
            return
        }
        self.currentRetryStartTimes += 1
        self.sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.stopRunning()
            self.sessionQueue.async { [weak self] in
                guard let self else { return }
                do {
                    try CameraEntry.startRunning(
                        forToken: CameraToken.sessionRuntimeErrorStartRunning,
                        session: self.session
                    )
                    self.isSessionRunning = true
                } catch {
                    self.log("start running session failed", error: error)
                }
            }
        }
    }

    @objc
    func applicationDidBecomActive(_ notification: Notification) {
        /// App 回到前台时，如果 session.isRunning 为 false, 代表 session 被中断
        /// 尝试恢复 session
        if !self.session.isRunning {
            self.sessionQueue.async { [weak self] in
                guard let self else { return }
                do {
                    try CameraEntry.startRunning(
                        forToken: CameraToken.didBecomeActiveStartRunning,
                        session: self.session
                    )
                    self.isSessionRunning = true
                } catch {
                    self.log("start running session failed", error: error)
                }
            }
        }
    }

    @objc
    func captureSessionWasInterrupted(_ notification: Notification) {
        let captureSession = notification.object as? AVCaptureSession
        cameraDelegate?.camera(
            self,
            log: "[Camera]: receive push \(notification.name) \(String(describing: notification.userInfo)) " +
            "from \(captureSession == session ? "video" : "audio") session",
            error: nil
        )
        stopVideoRecording()
        if let reason = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as? AVCaptureSession.InterruptionReason {
            cameraDelegate?.camera(
                self,
                log: "[Camera]: Capture session was interrupted, reason: \(reason).",
                error: notification.userInfo?[AVCaptureSessionErrorKey] as? Error
            )
        }
        guard captureSession == session else { return }
        self.isSessionRunning = false
    }

    @objc
    func updateUIWhenInterruptChanged(_ notification: Notification) {
        let session = notification.object as? AVCaptureSession
        cameraDelegate?.camera(
            self,
            log: "[Camera]: receive push \(notification.name) \(String(describing: notification.userInfo)) " +
            "from \(session == self.session ? "video" : "audio") session",
            error: nil
        )
        guard session == self.session else { return }
        let captureSession = self.session
        if Thread.isMainThread {
            self.updateUIWhenCaptureSession(
                isInterrupted: captureSession.isInterrupted,
                isRunnning: captureSession.isRunning
            )
        } else {
            DispatchQueue.main.async {
                self.updateUIWhenCaptureSession(
                    isInterrupted: captureSession.isInterrupted,
                    isRunnning: captureSession.isRunning
                )
            }
        }
    }

    private func updateUIWhenCaptureSession(isInterrupted: Bool, isRunnning: Bool) {
        if UIDevice.current.userInterfaceIdiom != .pad {
            return
        }
        let isFullScreen: Bool 
        if let w = self.view.window {
            isFullScreen = w.bounds.size == w.screen.bounds.size
        } else {
            isFullScreen = true
        }

        /// 只有在非全屏并且 interrupted || !running 的时候才显示提示文案
        if (isInterrupted || !isRunnning) && !isFullScreen {
            self.previewLayer?.isHidden = true
            self.alertLabel.isHidden = false
            self.updateAlertTextWhenInterrupted()
        } else {
            self.previewLayer?.isHidden = false
            self.alertLabel.isHidden = true
        }
    }

    private func updateAlertTextWhenInterrupted() {
        /// 这里单独抽离方法是考虑未来有多种不同提示情况
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.alertLabel.text = BundleI18n.LarkCamera.Lark_Legacy_iPadSplitViewCamera
        }
    }

    func setBackgroundAudioPreference() {
        guard isBackgroundAudioEnable, isAudioEnabled else { return }

        let options: AudioSessionCategoryOptions
        options = [.allowBluetooth, .allowAirPlay, .allowBluetoothA2DP]
        DispatchQueue.main.async {
            self.cameraDelegate?.camera(self, set: .playAndRecord, with: options)
        }
    }
}

// MARK: - Token

private extension CameraController {
    enum CameraToken {
        static let addAudioInput = Token("LARK-PSDA-larkcamera_add_audio_input")
        static let capturePhoto = Token("LARK-PSDA-larkcamera_capture_photo")
        static let didBecomeActiveStartRunning = Token("LARK-PSDA-larkcamera_did_become_active_start_running")
        static let getVideoDevice = Token("LARK-PSDA-larkcamera_get_video_device")
        static let requestAuth = Token("LARK-PSDA-larkcamera_request_auth")
        static let resetSessionInputStartRunning = Token("LARK-PSDA-larkcamera_reset_session_input_start_running")
        static let sessionRuntimeErrorStartRunning = Token("LARK-PSDA-larkcamera_session_runtime_error_start_running")
        static let startVideoRecording = Token("LARK-PSDA-larkcamera_start_video_recording")
        static let toggleFlash = Token("LARK-PSDA-larkcamera_toggle_flash")
        static let viewDidAppearStartRunning = Token("LARK-PSDA-larkcamera_view_did_appear_start_running")
    }
}

// MARK: - Utils

private extension CameraController {

    func minZoomFactor(for deviceType: AVCaptureDevice.DeviceType) -> CGFloat {
        if let tuple = supportedCameraTypes.first(where: { $0.deviceType == deviceType }) {
            return tuple.minZoomFactor
        }
        assertionFailure("deviceType not supported")
        log("deviceType not supported: \(deviceType), return default value 1", error: CameraError.addIOError)
        return 1
    }
}

private extension CameraController {

    @inline(__always)
    func log(_ log: String, error: Error? = nil) {
        cameraDelegate?.camera(self, log: "[Camera]: " + log, error: error)
    }
}

private extension CMTime {

    @inline(__always)
    static var current: CMTime {
        CMTime(seconds: CACurrentMediaTime(), preferredTimescale: 1000000)
    }
}

private extension CMSampleBuffer {

    func fixTimeStamp(with fixedTime: CMTime) -> Result<CMSampleBuffer, Swift.Error> {
        var fixedSampleBuffer: CMSampleBuffer
        // Not only should we call set output pts, but also set new timing infos to make new timestamp work.
        // Referenced by Apple's demo `Writing Fragmented MPEG-4 Files for HTTP Live Streaming`.
        if #available(iOS 13, *) {
            // try not use unsafe API on iOS 13+
            do {
                let newSampleTimingInfos = try self.sampleTimingInfos().map {
                    var newSampleTiming = $0
                    newSampleTiming.presentationTimeStamp = fixedTime
                    if $0.decodeTimeStamp.isValid {
                        newSampleTiming.decodeTimeStamp = fixedTime
                    }
                    return newSampleTiming
                }
                fixedSampleBuffer = try CMSampleBuffer(copying: self, withNewTiming: newSampleTimingInfos)
            } catch {
                return .failure(error)
            }
        } else {
            // identical to code above
            var count: CMItemCount = 0
            let osStatus1 = CMSampleBufferGetSampleTimingInfoArray(self, entryCount: 0, arrayToFill: nil,
                                                                   entriesNeededOut: &count)
            let pInfo = UnsafeMutablePointer<CMSampleTimingInfo>.allocate(capacity: Int(count))
            let osStatus2 = CMSampleBufferGetSampleTimingInfoArray(self, entryCount: count, arrayToFill: pInfo,
                                                                   entriesNeededOut: &count)
            for index in 0..<count {
                pInfo.advanced(by: Int(index)).pointee.decodeTimeStamp = fixedTime // kCMTimeInvalid if in sequence
                pInfo.advanced(by: Int(index)).pointee.presentationTimeStamp = fixedTime
            }
            var sampleBufferOut: CMSampleBuffer?
            let osStatus3 = CMSampleBufferCreateCopyWithNewTiming(allocator: kCFAllocatorDefault,
                                                                  sampleBuffer: self,
                                                                  sampleTimingEntryCount: count,
                                                                  sampleTimingArray: pInfo,
                                                                  sampleBufferOut: &sampleBufferOut)
            pInfo.deallocate()

            if let sampleBufferOut {
                fixedSampleBuffer = sampleBufferOut
            } else {
                return .failure(CameraController.CameraError
                    .fixCMSampleBufferTimeFailed("\(osStatus1), \(osStatus2), \(osStatus3)")
                )
            }
        }
        CMSampleBufferSetOutputPresentationTimeStamp(fixedSampleBuffer, newValue: fixedTime)
        return .success(fixedSampleBuffer)
    }
}
//swiftlint:disable file_length
//swiftlint:enable file_length
