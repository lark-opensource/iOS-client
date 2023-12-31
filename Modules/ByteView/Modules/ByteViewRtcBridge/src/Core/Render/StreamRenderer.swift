//
//  StreamRenderer.swift
//  ByteViewRtcBridge
//
//  Created by kiri on 2023/5/30.
//

import Foundation
import ByteViewCommon
import ByteViewRTCRenderer

final class RenderingFlag {
    @RwAtomic
    var isRendering: Bool = false
}

protocol StreamRenderProtocol: ByteViewVideoRenderer {
    func onRenderPaused()
    var subscribeConfig: VideoSubscribeConfig { get }
    func setRenderElapseObserver(_ observer: ByteViewRenderElapseObserver?)
    var renderingFlag: RenderingFlag? { get set }
}

protocol StreamRendererDelegate: AnyObject {
    var videoView: UIView? { get }
    var sampleBufferRenderView: ByteViewRenderView? { get }
    func setVideoView(_ videoView: UIView?)
    func setVideoFrameSize(_ size: CGSize?)
    func setRendering(_ isRendering: Bool)
}

final class StreamRenderer: NSObject, StreamRenderProtocol {

    let rendererType: ByteViewRendererType
    let streamKey: RtcStreamKey
    let cropLocalPortraitTo1x1: Bool
    weak var delegate: StreamRendererDelegate?

    @RwAtomic
    var renderingFlag: RenderingFlag?

    @RwAtomic
    var forceCrop1x1: VideoStreamForceCrop1x1Mode

    @RwAtomic
    var frameReceiver: ByteViewFrameReceiver?

    @RwAtomic
    var subscribeConfig: VideoSubscribeConfig

    @RwAtomic
    var isRenderMirrorEnabled: Bool

    @RwAtomic
    var frameCount: UInt64 = 0

    @RwAtomic
    var lastFrameCountTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()

    @RwAtomic
    var actor: MultiTargetActor?

    init(rendererType: ByteViewRendererType,
         parentInfo: String,
         streamKey: RtcStreamKey,
         isRenderMirrorEnabled: Bool,
         cropLocalPortraitTo1x1: Bool,
         subscribeConfig: VideoSubscribeConfig,
         forceCrop1x1: VideoStreamForceCrop1x1Mode) {
        self.desc = "Proxy(\(parentInfo))"
        self.rendererType = rendererType
        self.streamKey = streamKey
        self.subscribeConfig = subscribeConfig
        self.isRenderMirrorEnabled = isRenderMirrorEnabled
        self.cropLocalPortraitTo1x1 = cropLocalPortraitTo1x1
        self.forceCrop1x1 = forceCrop1x1
        super.init()
        _ = Self.setupLoggerOnce
    }

    func onRenderPaused() {
        self.frameCount = 0
        Util.runInMainThread {
            guard let parent = self.delegate else {
                return
            }
            if parent.videoView != nil {
                Logger.renderView.info("\(self) onRenderPaused")
                self.lastFrameSize = nil
                parent.setVideoView(nil)
                parent.setVideoFrameSize(nil)
                self.frameReceiver = nil
            } else {
                #if DEBUG
                Logger.renderView.info("\(self) duplicated render paused")
                #endif
            }
        }
    }

    func updateVideoFrameSizeIfNeeded(_ size: CGSize?) {
        guard self.lastFrameSize != size else {
            return
        }
        Util.runInMainThread {
            self.lastFrameSize = size
            self.delegate?.setVideoFrameSize(size)
        }
    }

    func createImage() -> UIImage? {
        guard let frame = lastFrame, let orientation =  UIImage.Orientation(rawValue: frame.rotation.rawValue)else {
            return nil
        }
        let ciImage = CIImage(cvPixelBuffer: frame.pixelBuffer)
        return UIImage(ciImage: ciImage, scale: 1, orientation: orientation)
    }

    func renderFrame(_ frame: ByteViewVideoFrame?) {
        let frame = self.processFrame(frame)
        self.lastFrame = frame
        self.frameCount &+= 1
        /// NOTE: 确保在大部分情况下 `frameReceiver.renderFrame()` 是在后台线程被调用:
        /// - `renderFrame` 内部会调用 metal api，执行创建纹理等耗时操作，主线程调用有可能产生卡顿
        /// - 原则上避免用 block 捕获 VideoFrame 切换线程, block 持有 VideoFrame, 发生积压时容易产生 OOM
        if let frameReceiver = self.frameReceiver {
            self.updateVideoFrameSizeIfNeeded(frame?.size)
            frameReceiver.renderFrame(frame)
        } else {
            Util.runInMainThread {
                // 仅在首帧时执行
                guard let parent = self.delegate, let flag = self.renderingFlag, flag.isRendering else {
                    #if DEBUG
                    Logger.renderView.warn("\(self) receive Frame , parentIsNil \(self.delegate == nil), isRenderingFlag: \(self.renderingFlag?.isRendering.description ?? "<nil>")")
                    #endif
                    return
                }

                var frameReceiver: ByteViewFrameReceiver?
                if parent.videoView == nil {
                    Logger.renderView.info("\(self) onRenderResumed")
                    self.frameCount = 1
                    self.lastFrameCountTime = CFAbsoluteTimeGetCurrent()

                    let videoView: ByteViewRenderView
                    if self.rendererType == .sampleBufferLayer, let renderView = parent.sampleBufferRenderView {
                        // 尽可能复用缓存的sampleBufferRenderView，减少初始化引起的卡死
                        renderView.removeFromSuperview()
                        videoView = renderView
                    } else {
                        videoView = ByteViewRenderViewFactory(renderType: self.rendererType)
                                        .create(with: StreamRenderTicker.current, fpsHint: self.subscribeConfig.fps)
                    }

                    videoView.renderElapseObserver = self.elapseObserver
                    frameReceiver = videoView.frameReceiver
                    self.updateVideoFrameSizeIfNeeded(frame?.size)
                    parent.setVideoView(videoView)
                } else {
                    frameReceiver = self.frameReceiver
                    self.updateVideoFrameSizeIfNeeded(frame?.size)
                    frameReceiver?.renderFrame(frame)
                    return
                }
                if frameReceiver == nil {
                    Logger.renderView.error("\(self) frameReceiver is nil!")
                    assertionFailure()
                }
                frameReceiver?.renderFrame(frame)
                parent.setRendering(true)
                self.frameReceiver = frameReceiver
            }
        }
    }

    @RwAtomic
    private var lastFrameSize: CGSize?
    @RwAtomic
    private var lastFrame: ByteViewVideoFrame?
    @RwAtomic
    private var rotation = ByteViewVideoRotation._0

    @RwAtomic
    private var deviceDegree: Int = 0
    @RwAtomic
    private var statusBarDegree: Int = 0
    private func applyLocalCropAndRotation(_ frameInfo: inout RenderingFrameInfo, interfaceOrientation: UIInterfaceOrientation, isExternalDisplay: Bool, crop1x1Mode: VideoStreamForceCrop1x1Mode) {
        guard self.streamKey == .local else {
            assertionFailure()
            return
        }

        var isPortrait = interfaceOrientation.isPortrait
        if let orientation = RtcCameraOrientation.current {
            let interfaceOrientation = Display.pad ? interfaceOrientation : orientation.statusBarOrientation
            isPortrait = interfaceOrientation.isPortrait
            deviceDegree = orientation.interfaceDeviceOrientaion.toRenderDegree() ?? deviceDegree
            statusBarDegree = interfaceOrientation.toRenderDegree() ?? statusBarDegree
            if orientation.isInBackground  {
                // 在后台时 StatusBarOrientation 不准，此时取 DeviceOrientation
                if Display.pad {
                    statusBarDegree = deviceDegree
                    isPortrait = orientation.interfaceDeviceOrientaion.isPortrait
                } else {
                    statusBarDegree = 0
                    isPortrait = true
                }
            }
        }
        // https://bytedance.feishu.cn/docx/doxcnM1ZbVHwSPpo8FR6ZMY6Ejf
        // disable-lint: magic number
        if isExternalDisplay {
            if frameInfo.flip {
                if let rotation = ByteViewVideoRotation(rawValue: (450 - deviceDegree) % 360) {
                    frameInfo.rotation = rotation
                }
            } else {
                if let rotation = ByteViewVideoRotation(rawValue: (90 + deviceDegree) % 360) {
                    frameInfo.rotation = rotation
                }
            }
        } else {
            if frameInfo.flip {
                if let rotation = ByteViewVideoRotation(rawValue: (statusBarDegree - deviceDegree * 2 + 810) % 360) {
                    frameInfo.rotation = rotation
                }
                frameInfo.flipHorizontal = (deviceDegree - statusBarDegree + 360) % 180 == 0
            } else {
                if let rotation = ByteViewVideoRotation(rawValue: (90 + statusBarDegree) % 360) {
                    frameInfo.rotation = rotation
                }
            }
        }

        // enable-lint: magic number
        let originWidth = frameInfo.frameSize.width
        let originHeight = frameInfo.frameSize.height
        if cropLocalPortraitTo1x1,
           isPortrait, originWidth != originHeight, originHeight > 0, originWidth > 0 {
            let cropWidth = originWidth > originHeight ? CGFloat(originHeight) / CGFloat(originWidth) : 1.0
            let cropHeight = originWidth > originHeight ? 1.0 : CGFloat(originWidth) / CGFloat(originHeight)
            frameInfo.cropRect = CGRect(x: (1.0 - cropWidth) * 0.5, y: (1.0 - cropHeight) * 0.5, width: cropWidth, height: cropHeight)
        }
    }

    func crop1x1IfNeeded(_ frameInfo: inout RenderingFrameInfo, crop1x1Mode: VideoStreamForceCrop1x1Mode) {
        let originWidth = frameInfo.frameSize.width
        let originHeight = frameInfo.frameSize.height
        var width = originWidth
        var height = originHeight
        if frameInfo.rotation == ._90 || frameInfo.rotation == ._270 {
            (width, height) = (height, width)
        }

        if crop1x1Mode == .alwaysCrop && width != height ||
            crop1x1Mode == .cropHeight && width < height  {
            // crop1x1IfNeeded
            let croppedWidth = (max(originWidth, originHeight) - originHeight) / originWidth
            let croppedHeight = (max(originWidth, originHeight) - originWidth) / originHeight
            frameInfo.cropRect = CGRect(x: croppedWidth * 0.5, y: croppedHeight * 0.5, width: 1.0 - croppedWidth, height: 1.0 - croppedHeight)
        }
    }


    func processFrame(_ frame: ByteViewVideoFrame?) -> ByteViewVideoFrame? {
        guard let frame = frame else { return nil }

        let originWidth = CGFloat(CVPixelBufferGetWidth(frame.pixelBuffer))
        let originHeight = CGFloat(CVPixelBufferGetHeight(frame.pixelBuffer))
        if originWidth < 1.0 || originHeight < 1.0 {
            return frame
        }
        let frameSize = CGSize(width: originWidth, height: originHeight)
        var frameInfo = RenderingFrameInfo(frameSize: frameSize, flip: frame.flip, flipHorizontal: true, rotation: frame.rotation, cropRect: CGRect(x: 0, y: 0, width: 1, height: 1))

        if self.streamKey.isLocal {
            self.applyLocalCropAndRotation(&frameInfo, interfaceOrientation: interfaceOrientation, isExternalDisplay: isExternalDisplay, crop1x1Mode: forceCrop1x1)
        } else {
            self.crop1x1IfNeeded(&frameInfo, crop1x1Mode: forceCrop1x1)
        }

        if frameInfo.rotation != self.rotation {
            Logger.renderView.info("render rotation changed rotation: \(frameInfo.rotation.rawValue), flip: \(frameInfo.flip), flipHorizontal: \(frameInfo.flipHorizontal)")
            self.rotation = frameInfo.rotation
        }

        var width: CGFloat = originWidth * frameInfo.cropRect.width
        var height: CGFloat = originHeight * frameInfo.cropRect.height
        if frameInfo.rotation == ._90 || frameInfo.rotation == ._270 {
            (width, height) = (height, width)
        }

        var flip = frameInfo.flip
        if flip, self.streamKey == .local, !self.isRenderMirrorEnabled {
            flip = false
        }

        let newFrame = ByteViewVideoFrame(pixelBuffer: frame.pixelBuffer,
                                          cropRect: frameInfo.cropRect,
                                          flip: flip,
                                          flipHorizontal: frameInfo.flipHorizontal,
                                          rotation: frameInfo.rotation,
                                          timeStampNs: frame.timeStampNs)


        return newFrame
    }

    var interfaceOrientation: UIInterfaceOrientation {
        guard let view = self.delegate as? StreamRenderView else {
            return .portrait
        }
        return view.interfaceOrientation
    }

    var isExternalDisplay: Bool {
        guard let view = self.delegate as? StreamRenderView else {
            return false
        }
        return view.isExternalDisplay
    }

    func readFPS() -> Int {
        let frameCnt = self.frameCount
        let start = self.lastFrameCountTime
        let now = CFAbsoluteTimeGetCurrent()

        self.frameCount = 0
        self.lastFrameCountTime = now

        let fps = Double(frameCnt) / (now - start)
        return Int(fps)
    }

    private weak var elapseObserver: ByteViewRenderElapseObserver?
    func setRenderElapseObserver(_ observer: ByteViewRenderElapseObserver?) {
        // 不统计本地渲染耗时
        if streamKey.isLocal {
            return
        }
        self.elapseObserver = observer
    }

    private let desc: String
    override var description: String {
        desc
    }
}


private extension StreamRenderer {
    static let logger = Logger.getLogger("Log", prefix: "RTCRender")
    static let setupLoggerOnce: Void = setupRenderViewLog()
    static func setupRenderViewLog() {
        ByteViewRTCLogging.sharedInstance().logCallback = { (level, filename, _, line, funcName, format) in
            switch level {
            case .warn:
                self.logger.warn(format, file: filename, function: funcName, line: Int(line))
            case .error:
                self.logger.error(format, file: filename, function: funcName, line: Int(line))
            default:
                break
            }
        }
    }
}
