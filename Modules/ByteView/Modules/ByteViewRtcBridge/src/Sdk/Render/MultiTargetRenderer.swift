//
//  MultiTargetRenderer.swift
//  ByteView
//
//  Created by liujianlong on 2021/1/28.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import VolcEngineRTC
import ByteViewRTCRenderer
import UIKit
import ByteViewCommon

protocol MultiTargetRendererDelegate: AnyObject {
    func didChangeSubscribeConfig(renderer: MultiTargetRenderer, config: VideoSubscribeConfig)
}

struct RenderingFrameInfo {
    let frameSize: CGSize
    let flip: Bool
    var flipHorizontal: Bool
    var rotation: ByteViewVideoRotation
    var cropRect: CGRect
}

@objc final class MultiTargetRenderer: NSObject {
    private let logger: Logger
    private let actor: MultiTargetActor
    private let queue: DispatchQueue
    private let rendererQueue = DispatchQueue(label: "lark.byteview.renderer")
    private let key: RtcStreamKey
    weak var delegate: MultiTargetRendererDelegate?

    @RwAtomic
    private var lastFrame: ByteViewVideoFrame?
    @RwAtomic
    private var renderers: [StreamRenderProtocol] = []
    private var renderElapse: (Int, Int) = (0, 0)

    private var resolutionMap = [ObjectIdentifier: VideoSubscribeConfig]()

    /// 记录一个延迟取消订阅事件序列号，处理 ABA 问题
    private var removeStamp: Int = Int.random(in: 0...Int.max)

    private(set) var subscribeConfig: VideoSubscribeConfig
    private let listeners: VideoStreamListeners
    var isRenderingFlag = RenderingFlag()

    init(key: RtcStreamKey, queue: DispatchQueue, actor: MultiTargetActor, subscribeConfig: VideoSubscribeConfig,
         listeners: VideoStreamListeners) {
        self.key = key
        self.queue = queue
        self.actor = actor
        self.subscribeConfig = subscribeConfig
        self.listeners = listeners
        if key.isLocal {
            self.logger = Logger.streamManager.withTag("[MultiTargetRenderer][local]")
        } else {
            self.logger = Logger.streamManager.withContext(key.sessionId).withTag("[MultiTargetRenderer(\(key))]")
        }
        super.init()
        self.logger.info("init MultiTargetRenderer")
    }

    deinit {
        self.logger.info("deinit MultiTargetRenderer")
    }

    func setSubscribeConfig(_ config: VideoSubscribeConfig, renderer: AnyObject) {
        let sizeKey = ObjectIdentifier(renderer)
        self.resolutionMap[sizeKey] = config
        let oldRendererResolution = self.subscribeConfig
        if let newRendererResolution = self.computeResolution(), oldRendererResolution != newRendererResolution {
            self.subscribeConfig = newRendererResolution
            self.logger.info("resolutionChange: \(oldRendererResolution) -> \(newRendererResolution)")
            self.reportSubscribeConfigChanged()
        }
    }

    private func computeResolution() -> VideoSubscribeConfig? {
        return resolutionMap.values.max { $0.res < $1.res }
    }

    private func reportSubscribeConfigChanged() {
        delegate?.didChangeSubscribeConfig(renderer: self, config: subscribeConfig)
    }

    func addChild(renderer: StreamRenderProtocol) {
        assert(renderer.renderingFlag == nil)
        renderer.renderingFlag = self.isRenderingFlag
        renderer.setRenderElapseObserver(self)
        renderers.append(renderer)
        let lastFrame = self.lastFrame

        if lastFrame != nil {
            renderer.renderFrame(lastFrame)
        }
        self.setSubscribeConfig(renderer.subscribeConfig, renderer: renderer)
    }

    func removeChild(renderer: StreamRenderProtocol) -> CleanAction {
        if !renderers.contains(where: { $0 === renderer }) {
            self.logger.warn("remove renderer not existed \(renderer)")
        }
        renderers.removeAll(where: { $0 === renderer })
        let isEmpty = renderers.isEmpty
        let sizeKey = ObjectIdentifier(renderer)
        resolutionMap.removeValue(forKey: sizeKey)
        rendererQueue.async {
            renderer.onRenderPaused()
        }
        let oldRendererSize = self.subscribeConfig
        if let newRendererSize = computeResolution(), oldRendererSize != newRendererSize {
            self.subscribeConfig = newRendererSize
            self.logger.info("resolutionChange: \(oldRendererSize) -> \(subscribeConfig)")
            reportSubscribeConfigChanged()
        }
        self.removeStamp &+= 1
        return isEmpty ? .delayRemove(removeStamp) : .skip
    }

    func onRenderResumed() {
        self.isRenderingFlag.isRendering = true
    }

    func onRenderPaused() {
        self.isRenderingFlag.isRendering = false
        self.lastFrame = nil
        let snapshot = self.renderers
        self.rendererQueue.async {
            for renderer in snapshot {
                renderer.onRenderPaused()
            }
        }
    }

    func shouldRemove(token: Int) -> Bool {
        renderers.isEmpty && removeStamp == token
    }

    enum CleanAction {
        case skip
        case delayRemove(Int)
    }
}

extension MultiTargetRenderer: ByteRTCVideoSinkProtocol {
    func shouldInitialize() -> Bool {
        return true
    }
    func shouldStart() {
    }

    func shouldStop() {
    }

    func shouldDispose() {
    }

    func pixelFormat() -> ByteRTCVideoPixelFormat {
        return .NV12
    }

    func renderPixelBuffer(_ pixelBuffer: CVPixelBuffer, rotation: ByteRTCVideoRotation, cameraId: ByteRTCCameraID, extendedData: Data?) {
        self.actor.performRenderAction {
            let timeStampNs = Int64(NSDate().timeIntervalSince1970 * 1000 * 1000 * 1000)
            var rtcRotation = ByteViewVideoRotation._0
            switch rotation {
            case .rotation0:
                rtcRotation = ._0
            case .rotation90:
                rtcRotation = ._90
            case .rotation180:
                rtcRotation = ._180
            case .rotation270:
                rtcRotation = ._270
            @unknown default:
                break
            }

            let frame = ByteViewVideoFrame(pixelBuffer: pixelBuffer,
                                           cropRect: CGRect(x: 0, y: 0, width: 1, height: 1),
                                           flip: cameraId == .front,
                                           flipHorizontal: true,
                                           rotation: rtcRotation,
                                           timeStampNs: timeStampNs)
            self.lastFrame = frame
            let snapshot = self.renderers

            for renderer in snapshot {
                renderer.renderFrame(frame)
            }
            listeners.rendererListenerers.forEach({ $0.didRenderVideoFrame(key: key) })
        }
    }

    func getRenderElapse() -> Int32 {
        defer {
            renderElapse = (0, 0)
        }
        if renderElapse.1 > 0 {
            return Int32(renderElapse.0 / renderElapse.1)
        } else {
            return 0
        }
    }
}

extension MultiTargetRenderer: ByteViewRenderElapseObserver {
    func reportRenderElapse(_ elapse: Int32) {
        renderElapse = (renderElapse.0 + Int(elapse), renderElapse.1 + 1)
    }
}
