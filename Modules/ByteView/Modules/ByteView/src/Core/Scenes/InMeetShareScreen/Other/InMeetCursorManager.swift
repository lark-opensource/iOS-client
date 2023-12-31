//
//  InMeetCursorManager.swift
//  ByteView
//
//  Created by fakegourmet on 2023/4/14.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import ByteViewTracker
import ByteViewRtcBridge

struct CursorInfo {
    let enableCursorShare: Bool
    let cursorFrame: CursorFrame
    let image: UIImage?

    var isZero: Bool {
        cursorFrame.sharedRectWidth == 0 ||
        cursorFrame.sharedRectHeight == 0 ||
        cursorFrame.cursorFrameWidth == 0 ||
        cursorFrame.cursorFrameHeight == 0
    }
}

typealias CursorInfoEventHandler = (CursorInfo) -> Void

final class InMeetCursorManager {

    private static let logger = Logger.otherShareScreen

    private lazy var displayLink: CADisplayLink = {
        let displayLink = CADisplayLink(target: WeakProxy(target: self), selector: #selector(WeakProxy.link(sender:)))
        displayLink.preferredFramesPerSecond = 60
        displayLink.add(to: .current, forMode: .common)
        return displayLink
    }()

    private class WeakProxy: NSObject {
        weak var target: InMeetCursorManager?

        init(target: InMeetCursorManager) {
            self.target = target
            super.init()
        }

        @objc func link(sender: CADisplayLink) {
            target?.link(sender: sender)
        }
    }

    @RwAtomic
    private var lastRecvDelta: Int = 0
    @RwAtomic
    private var maxRecvDelta: Int = 0
    @RwAtomic
    private var lastCaptureInterval: Int = 0
    @RwAtomic
    private var minCaptureInterval: Int = Int.max
    private var oldCursorFrame: CursorFrame?

    private var cursorImageCache = MemoryCache(countLimit: 10)
    private var cursorFrameBuffer = JitterBuffer<CursorFrame>(maxDuration: 100)
    /// 一次鼠标传输通道的开启和关闭记一个 matchID
    /// 下一次开启 ID 自增 1
    /// 会议结束后重置
    private var matchID: UInt = 0

    private var enableCursorShare: Bool = false {
        didSet {
            guard oldValue != enableCursorShare else { return }
            cursorShareTrack()
        }
    }

    private var cursorFrame: CursorFrame? {
        didSet {
            createCursorInfo()
        }
    }

    private(set) var cursorInfo: CursorInfo? {
        didSet {
            if let cursorInfo = cursorInfo {
                cursorEventHandler?(cursorInfo)
            }
        }
    }

    private lazy var cursorQueue = DispatchQueue(label: "com.byteview.cursor-buffer")
    private var renderTimer: DispatchSourceTimer?
    private var timer: DispatchSourceTimer?

    private var cursorEventHandler: CursorInfoEventHandler?

    private let meeting: InMeetMeeting
    private lazy var logDescription = metadataDescription(of: self)

    init(meeting: InMeetMeeting, handler: @escaping CursorInfoEventHandler) {
        self.meeting = meeting
        self.cursorEventHandler = handler
        meeting.shareData.addListener(self)
        meeting.rtc.engine.addBinaryFrameListener(self)

        startCursorUpdator()
        Self.logger.debug("init \(logDescription)")
    }

    deinit {
        endCursorUpdator()
        Self.logger.debug("deinit \(logDescription)")
    }

    @objc func link(sender: CADisplayLink) {
        if let frame = cursorFrameBuffer.dequeue() {
            cursorFrame = frame
        }
    }

    private func cursorShareTrack() {
        if self.matchID > 0 {
            VCTracker.post(name: .vc_meeting_sharescreen_mouse_transfer_status,
                           params: ["is_presenter": self.meeting.shareData.isSelfSharingContent,
                                    "status": enableCursorShare ? "open" : "close",
                                    "action_match_id": self.matchID])
        }
        if !enableCursorShare {
            self.matchID += 1
        }
    }

    private func startCursorUpdator() {
        Util.runInMainThread {
            // 主线程初始化 displayLink
            // 后台线程无法触发 displaylink 回调
            _ = self.displayLink
        }
        timer = DispatchSource.makeTimerSource(flags: [], queue: cursorQueue)
        timer?.setEventHandler { [weak self] in
            self?.updateBufferSize()
            self?.updateBufferInterval()
        }
        timer?.schedule(deadline: .now(), repeating: .seconds(2), leeway: .seconds(1))
        timer?.resume()
    }

    private func endCursorUpdator() {
        displayLink.invalidate()
        timer?.cancel()
        timer = nil
    }

    private func createCursorInfo() {
        guard let cursorFrame = self.cursorFrame else {
            return
        }
        self.cursorInfo = CursorInfo(
            enableCursorShare: enableCursorShare,
            cursorFrame: cursorFrame,
            image: {
                if let image = self.cursorImageCache.value(forKey: cursorFrame.imageKey, type: UIImage.self) {
                    return image
                } else {
                    let image = cursorFrame.cursorData.vc.createRGBImage(
                        width: Int(cursorFrame.cursorFrameWidth),
                        height: Int(cursorFrame.cursorFrameHeight)
                    )
                    self.cursorImageCache.setValue(image, forKey: cursorFrame.imageKey)
                    return image
                }
            }()
        )
    }

    private func updateBufferSize(targetDelta: Int? = nil) {
        guard enableCursorShare else { return }
        let delta: Int
        if let targetDelta = targetDelta {
            delta = targetDelta
        } else {
            delta = maxRecvDelta
            maxRecvDelta = 0
        }
        let estimatedBufferDuration: Int = min(max(100, delta), 500)
        let maxDuration = cursorFrameBuffer.maxDuration
        if estimatedBufferDuration < maxDuration {
            cursorFrameBuffer.setMaxDuration((estimatedBufferDuration + maxDuration) / 2)
        } else {
            cursorFrameBuffer.setMaxDuration(estimatedBufferDuration)
        }
    }

    private func updateBufferInterval(targetInterval: Int? = nil) {
        guard enableCursorShare else { return }
        var interval: Int
        if let targetInterval = targetInterval {
            interval = targetInterval
        } else {
            interval = minCaptureInterval
            minCaptureInterval = Int.max
        }
        // nolint-next-line: magic number
        interval = min(max(interval, 16), 66) // 15fps ~ 60fps
        DispatchQueue.main.async {
            self.cursorFrameBuffer.setRenderInterval(interval)
            self.displayLink.preferredFramesPerSecond = 1000 / interval
        }
    }
}

extension InMeetCursorManager: InMeetShareDataListener {
    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        if [.othersSharingScreen, .magicShare, .shareScreenToFollow, .none].contains(newScene.shareSceneType)
            || [.othersSharingScreen, .magicShare, .shareScreenToFollow, .none].contains(oldScene.shareSceneType) {
            let newScreenSharedData = newScene.shareScreenData
            let oldScreenSharedData = oldScene.shareScreenData

            self.enableCursorShare = newScreenSharedData?.enableCursorShare ?? false
            if newScreenSharedData != nil && oldScreenSharedData != nil {
                // 发生抢共享事件时，序号会清零，重置frame
                self.cursorFrameBuffer.clear()
                self.cursorFrame = nil
            }
        }
    }
}

extension InMeetCursorManager: RtcRoomMessageListener {
    func didReceiveRoomBinaryMessage(_ message: Data) {
        guard let header = RoomMessageHeader(data: message) else {
            Self.logger.error("RoomMessage decode error")
            return
        }
        do {
            let frame = try CursorFrame.init(serializedData: header.body)
            didReceiveCursorFrame(frame)
        } catch {
            Self.logger.error("receive cursor frame decode error: \(error)")
        }
    }

    func didReceiveCursorFrame(_ cursorFrame: CursorFrame) {
        if let oldFrame = self.oldCursorFrame {
            if cursorFrame.sequenceNumber <= oldFrame.sequenceNumber {
                Self.logger.warn("didReceiveCursorFrame sequence error")
                return
            }
            guard cursorFrame.timestamp >= oldFrame.timestamp, oldFrame.timestamp > 0,
                  cursorFrame.recvTimestamp >= oldFrame.recvTimestamp, oldFrame.recvTimestamp > 0 else {
                Self.logger.warn("didReceiveCursorFrame timestamp error")
                return
            }
            let captureInterval: Int = Int(cursorFrame.timestamp - oldFrame.timestamp)
            let recvDelta: Int = captureInterval + Int(cursorFrame.recvTimestamp - oldFrame.recvTimestamp)

            if recvDelta > maxRecvDelta {
                maxRecvDelta = recvDelta
            }
            if captureInterval < minCaptureInterval {
                minCaptureInterval = captureInterval
            }
            if captureInterval < lastCaptureInterval {
                updateBufferInterval(targetInterval: minCaptureInterval)
            }
            if recvDelta < lastRecvDelta {
                updateBufferSize(targetDelta: maxRecvDelta)
            }
            lastRecvDelta = recvDelta
            lastCaptureInterval = captureInterval
        }
        cursorFrameBuffer.enqueue(cursorFrame)
        oldCursorFrame = cursorFrame
    }
}

extension CursorFrame: JitterBufferProtocol {}

fileprivate extension CursorFrame {
    func isDataEqual(to rhs: CursorFrame) -> Bool {
        self.cursorFrameWidth == rhs.cursorFrameWidth &&
        self.cursorFrameHeight == rhs.cursorFrameHeight &&
        self.cursorRenderDstX == rhs.cursorRenderDstX &&
        self.cursorRenderDstY == rhs.cursorRenderDstY &&
        self.sharedRectWidth == rhs.sharedRectWidth &&
        self.sharedRectHeight == rhs.sharedRectHeight &&
        self.cursorRenderSrcX == rhs.cursorRenderSrcX &&
        self.cursorRenderSrcY == rhs.cursorRenderSrcY &&
        self.imageKey == rhs.imageKey &&
        self.userID == rhs.userID &&
        self.targetUserID == rhs.targetUserID
    }
}
