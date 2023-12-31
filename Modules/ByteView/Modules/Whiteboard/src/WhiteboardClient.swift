//
//  WhiteboardClient.swift
//  Whiteboard
//
//  Created by helijian on 2022/2/28.
//

import Foundation
import WbLib
import UIKit
import ByteViewCommon
import ByteViewNetwork

protocol WbClientNotificationDelegate: AnyObject {
    func didChangeUndoState(canUndo: Bool)
    func didChangeRedoState(canRedo: Bool)
    func didChangeViewportScale(_ scale: Float)
    func didChangeViewportTranslation(vector: Vector)
    func didGraphicStartDrawing(graphicInfo: DrawingStateData)
    func didGraphicDrawing(graphicInfo: DrawingStateData)
    func didGraphicEndDrawing(graphicInfo: DrawingStateData)
    func didChangeRenderCmds(_ cmd: [WbRenderCmd])
    func didTimerPaused(fps: Int, shapeCount: Int, cmdsCount: Int)
    func didGraphicCancelDrawing(graphicInfo: DrawingStateData)
    func onSyncData(_ type: WbSyncDataType, _ bytes: [UInt8])
}

extension WbClientNotificationDelegate {
    func didChangeUndoState(canUndo: Bool) {}
    func didChangeRedoState(canRedo: Bool) {}
    func didChangeViewportScale(_ scale: Float) {}
    func didChangeViewportTranslation(vector: Vector) {}
    func didGraphicStartDrawing(graphicInfo: DrawingStateData) {}
    func didGraphicDrawing(graphicInfo: DrawingStateData) {}
    func didGraphicEndDrawing(graphicInfo: DrawingStateData) {}
    func didChangeRenderCmds(_ cmd: [WbRenderCmd]) {}
    func didTimerPaused(fps: Int, shapeCount: Int, cmdsCount: Int) {}
    func didGraphicCancelDrawing(graphicInfo: DrawingStateData) {}
    func onSyncData(_ type: WbSyncDataType, _ bytes: [UInt8]) {}
}

private class SketchWeakProxy: NSObject {
    weak var target: WhiteboardClient?

    init(target: WhiteboardClient) {
        self.target = target
        super.init()
    }

    @objc func step(sender: CADisplayLink) {
        target?.step(sender: sender)
    }
}

class WhiteboardClient {

    weak var notificationDelegate: WbClientNotificationDelegate?
    private let client: WbClient
    private let account: ByteviewUser
    private let renderFPS: Int
    private let sendIntervalMs: Int
    private var atLeastDrawOnce = false
    private var shouldStopTimer = false
    private var displayLink: CADisplayLink?
    private var frameCount = 0
    private var cmdsCount = 0
    private var startTime: CFTimeInterval = 0
    private let minDuration = 100.0
    private var currentPageID: Int64 = 0
    private var tickTimer: Timer?

    private(set) var currentTool: WbTool?

    init(account: ByteviewUser,
         renderFPS: Int,
         sendIntervalMs: Int,
         isEnableIncrementalPath: Bool) {
        self.account = account
        self.renderFPS = renderFPS
        self.sendIntervalMs = sendIntervalMs
        // 提前设置log可以监控client的初始化状态日志
        setLogMessageHandler { (category, level, info) in
            if let level = LogLevel(rawValue: level) {
                let vcLevel: ByteViewCommon.LogLevel
                switch level {
                case .error:
                    vcLevel = .error
                case .warn:
                    vcLevel = .warn
                case .info:
                    vcLevel = .info
                case .debug:
                    vcLevel = .debug
                case .trace:
                    vcLevel = .trace
                }
                logger.log(vcLevel, "[\(category)]\(info)")
            }
        }
        client = WbClient(config: WbLibConfig(account.id, account.deviceId, account.type.rawValue))
        client.setEnableIncrementalPath(enable: isEnableIncrementalPath)
        setupWBClientSDK()
        setupDisplayLink()
    }

    deinit {
        displayLink?.invalidate()
        displayLink = nil
        invalidateTickTimer()
    }

    // 初始化默认配置
    func configDefaultClient() {
        setTool(.Move)
        client.setStrokeWidth(2)
    }

    func configTheme(mode: WbTheme) {
        client.setTheme(mode)
    }

    func handleTouchDown(x: Float, y: Float, id: Int) {
        client.handleTouchDown(x: x, y: y, id: id)
    }

    func handleTouchMoved(x: Float, y: Float, id: Int) {
        client.handleTouchMoved(x: x, y: y, id: id)
    }

    func handleTouchLifted(x: Float, y: Float, id: Int) {
        client.handleTouchLifted(x: x, y: y, id: id)
    }

    func clearMine() {
        client.clearMine()
    }

    func clearAll() {
        client.clearAll()
    }

    func clearOthers() {
        client.clearOthers()
    }

    func removePage(id: Int64) {
        client.removePage(id)
    }

    func newPage(id: Int64) {
        client.newPage(id)
    }

    func switchPage(id: Int64) {
        client.switchPage(id)
        currentPageID = id
    }

    func getPageInfo(id: Int64) -> PageInfo? {
        client.getPageInfo(id)
    }

    func getPageGraphics(pageId: Int64) -> [WbGraphic] {
        return client.getPageGraphics(pageId)
    }

    func setTool(_ tool: WbTool) {
        client.setTool(tool)
        currentTool = tool
    }

    func setFillColor(_ color: ColorType? = nil) {
        guard let color = color else {
            client.setFillColorToken(.Transparent)
            return
        }
        let token = getColorTokenFromColor(color: color)
        client.setFillColorToken(token)
    }

    func setStrokeWidth(_ width: UInt32) {
        client.setStrokeWidth(width)
    }

    func setColor(_ color: ColorType) {
        let token = getColorTokenFromColor(color: color)
        client.setStrokeColorToken(token)
    }

    private func getColorTokenFromColor(color: ColorType) -> WbColorToken {
        let token: WbColorToken
        switch color {
        case .red:
            token = .R500
        case .yellow:
            token = .Y500
        case .purple:
            token = .P500
        case .blue:
            token = .B500
        case .green:
            token = .G500
        case .black:
            token = .Primary
        }
        return token
    }

    func handleSyncData(_ bytes: [UInt8], type: WbSyncDataType) {
        client.handleSyncData(type, bytes)
    }


    func setPageSnapshot(_ bytes: [UInt8]) {
        let result = client.setPageSnapshot(bytes)
        if result == -1 {
            logger.error("setPageSnapshot failed")
        }
    }

    func undo() {
        client.undo()
    }

    func redo() {
        client.redo()
    }

    @objc func step(sender: CADisplayLink) {
        let cmds: [WbRenderCmd] = client.pullPendingGraphicCmds()
        notificationDelegate?.didChangeRenderCmds(cmds)
        atLeastDrawOnce = true
        frameCount += 1
        cmdsCount += cmds.count
        if shouldStopTimer {
            setTimerPaused(true)
        }
    }

    enum LogLevel: Int, Hashable {
        case error = 0
        case warn = 1
        case info = 2
        case debug = 3
        case trace = 4
    }

    private func setupTickTimer(interval: UInt32) {
        let timerInterval = Double(interval) / 1000.0
        invalidateTickTimer()
        let timer = Timer(timeInterval: timerInterval, repeats: true) { [weak self] (t) in
            if let self = self {
                self.client.tick()
            } else {
                t.invalidate()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        timer.fire()
        tickTimer = timer
    }

    private func invalidateTickTimer() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    private func setupWBClientSDK() {
        client.setNotificationDelegate(self)
        client.setSyncDataDelegate(self)
        client.setMeasureInlineTextDelegate(self)
        client.setSendSyncDataIntervalMs(interval: UInt32(sendIntervalMs))
        client.setReplaySyncDataFps(fps: UInt32(renderFPS))
    }

    private func didChangeHasPendingGraphicCmds(_ hasPendingGraphicCmds: Bool) {
        if hasPendingGraphicCmds {
            setTimerPaused(false)
            atLeastDrawOnce = false
            shouldStopTimer = false
        } else {
            if atLeastDrawOnce {
                setTimerPaused(true)
            } else {
                shouldStopTimer = true
            }
            // 多拉一次避免数据残留
            let cmds: [WbRenderCmd] = client.pullPendingGraphicCmds()
            notificationDelegate?.didChangeRenderCmds(cmds)
        }
    }

    private func setupDisplayLink() {
        let displayLink = CADisplayLink(target: SketchWeakProxy(target: self), selector: #selector(SketchWeakProxy.step(sender:)))
        displayLink.preferredFramesPerSecond = 60
        displayLink.isPaused = true
        displayLink.add(to: .current, forMode: .common)
        self.displayLink = displayLink
    }

    private func setTimerPaused(_ isPaused: Bool) {
        guard displayLink?.isPaused != isPaused else { return }
        displayLink?.isPaused = isPaused
        if isPaused {
            let duration = (CACurrentMediaTime() - startTime) * 1000
            // minDuration毫秒以内计算FPS误差会比较大，因此不做统计
            guard duration > minDuration else { return }
            let fps = Int(1000.0 / duration * Double(frameCount))
            let shapeCount = client.getPageInfo(currentPageID)?.shapeCount ?? 0
            notificationDelegate?.didTimerPaused(fps: fps, shapeCount: shapeCount, cmdsCount: cmdsCount)
        } else {
            startTime = CACurrentMediaTime()
            frameCount = 0
            cmdsCount = 0
        }
    }
}

extension PageInfo {
    var shapeCount: Int {
        return Int(arrowCount + ellipseCount + lineCount + pencilCount + triangleCount + rectangleCount + highlighterCount)
    }
}

extension WhiteboardClient: WbSyncDataDelegate {
    func onSyncData(_ type: WbSyncDataType, _ bytes: [UInt8]) {
        logger.info("wbclient receive onSyncData \(bytes.count)")
        self.notificationDelegate?.onSyncData(type, bytes)
    }
}

extension WhiteboardClient: WbNotificationDelegate {
    func onNotification(_ notification: WbNotification) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch notification {
            case .UndoRedoStatusChanged(let notification):
                self.notificationDelegate?.didChangeRedoState(canRedo: notification.canRedo)
                self.notificationDelegate?.didChangeUndoState(canUndo: notification.canUndo)
            case .ViewportScale(let scale):
                self.notificationDelegate?.didChangeViewportScale(scale)
            case .ViewportTranslation(let vector):
                self.notificationDelegate?.didChangeViewportTranslation(vector: vector)
            case .StartDrawing(let graphicInfo):
                self.notificationDelegate?.didGraphicStartDrawing(graphicInfo: graphicInfo)
            case .Drawing(let graphicInfo):
                self.notificationDelegate?.didGraphicDrawing(graphicInfo: graphicInfo)
            case .EndDrawing(let graphicInfo):
                self.notificationDelegate?.didGraphicEndDrawing(graphicInfo: graphicInfo)
            case .HasPendingGraphicCmds(let value):
                self.didChangeHasPendingGraphicCmds(value)
            case .CancelDrawing(let graphicInfo):
                self.notificationDelegate?.didGraphicCancelDrawing(graphicInfo: graphicInfo)
            case .StartTicker(let interval):
                self.setupTickTimer(interval: interval)
            case .StopTicker:
                self.invalidateTickTimer()
            default:
                return
            }
        }
    }
}

extension WhiteboardClient: WbMeasureInlineTextDelegate {
    func onMeasure(_ text: String, fontSize: Int, fontWeight: Int) -> InlineGlyphSpecs {
        // 测量行高
        let layer = CATextLayer()
        layer.string = text
        layer.fontSize = CGFloat(fontSize)
        layer.font = CTFontCreateWithName(LayerBuilder.getFontName(fontWeight) as CFString, CGFloat(fontSize), nil)
        let height = Float(layer.preferredFrameSize().height)
        // 测量文字块宽度
        let font = UIFont(name: LayerBuilder.getFontName(fontWeight), size: CGFloat(fontSize))!
        let attrs = [ NSAttributedString.Key.font: font ]
        let nsText = NSAttributedString(string: text, attributes: attrs)
        let nsLine = CTLineCreateWithAttributedString(nsText)
        let runs = CTLineGetGlyphRuns(nsLine) as? [CTRun]
        var widths = [Float]()
        for run in runs! {
            let glyphCount = CTRunGetGlyphCount(run)
            var cgSizes = Array(repeating: CGSize(), count: glyphCount)
            CTRunGetAdvances(run, CFRangeMake(0, glyphCount), &cgSizes)
            for cgSize in cgSizes {
                widths.append(Float(cgSize.width))
            }
        }
        return InlineGlyphSpecs(height, widths)
    }
}
