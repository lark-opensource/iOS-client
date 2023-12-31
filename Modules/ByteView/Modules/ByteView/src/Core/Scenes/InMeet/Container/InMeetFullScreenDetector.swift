//
//  InMeetFullScreenManager.swift
//  ByteView
//
//  Created by liujianlong on 2021/10/27.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import ByteViewSetting

class BlockFullScreenToken {
    let function: String
    weak var fullScreenDetector: InMeetFullScreenDetector?

    init(function: String, detector: InMeetFullScreenDetector?) {
        self.function = function
        self.fullScreenDetector = detector
    }

    func invalidate() {
        fullScreenDetector?.unblockAutoFullScreen()
        fullScreenDetector?.removeToken(self)
        fullScreenDetector = nil
    }
}

final class InMeetFullScreenDetector: NSObject, UIGestureRecognizerDelegate {
    private lazy var autoHideToolbarConfig = setting.autoHideToolbarConfig

    enum State {
        /// 始终显示工具栏
        case disabled
        /// overlay 状态，经过 timer 时间后自动进入 fullscreen 态，如果 timer  为空，则保持 overlay 态
        case overlayWaiting(Timer?)
        /// 沉浸态
        case fullscreen
    }

    private var disableAutoFullScreenMask: Int = 0
    private var forceAlwaysShowToolbar: Bool = false {
        didSet {
            guard self.forceAlwaysShowToolbar != oldValue else {
                return
            }
            enableFullscreenMode()
        }
    }
    private var state: State = .disabled
    private let interruptGesture: InterruptFullScreenGest

    private var hoverGest: UIGestureRecognizer?

    private weak var container: InMeetViewContainer?
    private var tokens: [BlockFullScreenToken] = []

    var isMobileLandscapeMode: Bool = false {
        didSet {
            guard self.isMobileLandscapeMode != oldValue else {
                return
            }
            enableFullscreenMode(animate: false)
        }
    }

    // WARNING: 这个方法是专门给 MagicShare 场景开的后门 (MagicShare 需要强制始终显示工具栏), 
    // 其它地方使用请咨询 liujianlong
    func forceAlwaysShowToolbar(_ forceShow: Bool) {
        self.forceAlwaysShowToolbar = forceShow
    }

    let userId: String
    let setting: MeetingSettingManager
    init(container: InMeetContainerViewController) {
        let gest = InterruptFullScreenGest()
        self.interruptGesture = gest
        self.userId = container.viewModel.meeting.userId
        self.setting = container.viewModel.meeting.setting
        super.init()

        gest.fullScreenManager = self
        gest.delegate = self
        gest.addTarget(self, action: #selector(interruptGestDetected(_:)))
        if #available(iOS 13.0, *) {
            self.hoverGest = UIHoverGestureRecognizer(target: self, action: #selector(handleHoverGesture(_:)))
            self.hoverGest?.delegate = self
        }
        let observer1 = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
            self?.backgroundBlockFullScreenToken = nil
            self?.postInterruptEvent()
        }

        let observer2 = NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.backgroundBlockFullScreenToken = self.requestBlockAutoFullScreen()
        }
        self.observers = [observer1, observer2]

        if Display.phone {
            InMeetOrientationToolComponent.isLandscapeModeRelay.asObservable()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] b in
                    self?.isMobileLandscapeMode = b
                })
                .disposed(by: rx.disposeBag)
        }

        self.container = container
        if self.autoHideToolStatusBar && !self.forceAlwaysShowToolbar {
            container.switchMeetLayoutStyle(.overlay, animated: false)
            container.view.addGestureRecognizer(self.interruptGesture)
            if let hoverGest = hoverGest {
                container.view.addGestureRecognizer(hoverGest)
            }
            scheduleWaiting(isFirstTime: container.context.shouldStartFirstOverlayTimeOut)
        } else {
            container.switchMeetLayoutStyle(.tiled, animated: false)
        }
        container.viewModel.meeting.setting.addListener(self, for: .autoHideToolStatusBar)
    }

    func removeToken(_ token: BlockFullScreenToken) {
        self.tokens.removeAll(where: { $0 === token })
    }

    private var observers: [NSObjectProtocol] = []
    private var backgroundBlockFullScreenToken: BlockFullScreenToken? {
        didSet {
            guard self.backgroundBlockFullScreenToken !== oldValue else {
                return
            }
            oldValue?.invalidate()
        }
    }

    deinit {
        self.observers.forEach(NotificationCenter.default.removeObserver)
    }

    func registerInterruptWhiteListView(_ view: UIView) {
        self.interruptGesture.registerWhiteListView(view)
    }

    func unregisterInterruptWhiteListView(_ view: UIView) {
        self.interruptGesture.removeWhiteListView(view)
    }

    func registerWhiteListClass(_ clazz: AnyClass) {
        if !InterruptFullScreenGest.whiteListClass.contains(where: { $0 === clazz }) {
            InterruptFullScreenGest.whiteListClass.append(clazz)
        }
    }

    func enableFullscreenMode(animate: Bool = true) {
        let enabled = (self.isMobileLandscapeMode || self.autoHideToolStatusBar) && !self.forceAlwaysShowToolbar
        assertMain()
        switch self.state {
        case .disabled:
            if !enabled {
                return
            }
            container?.view.addGestureRecognizer(self.interruptGesture)
            if let hoverGest = self.hoverGest {
                container?.view.addGestureRecognizer(hoverGest)
            }
            container?.switchMeetLayoutStyle(.overlay, animated: animate)
            scheduleWaiting()
        case .overlayWaiting(let timer):
            if !enabled {
                timer?.invalidate()
            }
            fallthrough
        case .fullscreen:
            if !enabled {
                self.state = .disabled
                container?.view.removeGestureRecognizer(self.interruptGesture)
                if let hoverGest = self.hoverGest {
                    container?.view.removeGestureRecognizer(hoverGest)
                }

                container?.switchMeetLayoutStyle(.tiled, animated: animate)
            }
        }
    }

    func requestBlockAutoFullScreen(function: String = #function, leaveFullScreen: Bool = true) -> BlockFullScreenToken {
        assertMain()
        self.disableAutoFullScreenMask += 1
        let token = BlockFullScreenToken(function: function, detector: self)
        self.tokens.append(token)
        guard self.disableAutoFullScreenMask == 1 else {
            return token
        }


        if case .overlayWaiting = self.state {
            self.scheduleWaiting()
        } else if case .fullscreen = self.state, leaveFullScreen {
            container?.switchMeetLayoutStyle(.overlay, animated: true)
            self.scheduleWaiting()
        }
        return token
    }

    fileprivate func unblockAutoFullScreen() {
        assertMain()
        self.disableAutoFullScreenMask -= 1
        if self.disableAutoFullScreenMask == 0,
           case .overlayWaiting = self.state {
            self.scheduleWaiting()
        }
    }

    func postInterruptEvent(anmited: Bool = true) {
        assertMain()
        guard case .fullscreen = self.state else {
            return
        }
        switch self.state {
        case .disabled:
            break
        case .overlayWaiting(let timer):
            timer?.invalidate()
            scheduleWaiting()
        case .fullscreen:
            container?.switchMeetLayoutStyle(.overlay, animated: anmited)
            scheduleWaiting()
        }
    }

    func postEnterFullScreenEvent() {
        assertMain()
        guard disableAutoFullScreenMask <= 0,
            case .overlayWaiting(let timer) = self.state else {
            return
        }
        timer?.invalidate()
        container?.switchMeetLayoutStyle(.fullscreen, animated: true)
        self.state = .fullscreen
    }

    func postKeepOverlayWaiting() {
        assertMain()
        guard case .overlayWaiting(let timer) = self.state else {
            return
        }
        timer?.invalidate()
        scheduleWaiting()
    }

    private func handleFullScreenTimerFired(timer: Timer) {
        guard self.disableAutoFullScreenMask <= 0,
              case .overlayWaiting(let curTimer) = self.state,
              curTimer === timer else {
                  return
              }
        if container?.presentedViewController != nil {
            self.scheduleWaiting()
        } else {
            container?.switchMeetLayoutStyle(.fullscreen, animated: true)
            self.state = .fullscreen
        }
    }

    func postSwitchFullScreenEvent() {
        guard self.disableAutoFullScreenMask <= 0 else {
            return
        }

        switch self.state {
        case .disabled:
            break
        case .fullscreen:
            container?.switchMeetLayoutStyle(.overlay, animated: true)
            scheduleWaiting()
        case .overlayWaiting(let timer):
            timer?.invalidate()
            container?.switchMeetLayoutStyle(.fullscreen, animated: true)
            self.state = .fullscreen
        }
    }

    private func scheduleWaiting(isFirstTime: Bool = false) {
        if self.disableAutoFullScreenMask > 0 || !self.autoHideToolStatusBar {
            self.state = .overlayWaiting(nil)
        } else {
            let timer = Timer(timeInterval: isFirstTime ? Double(autoHideToolbarConfig.firstAutoHideDuration) / 1000 : Double(autoHideToolbarConfig.continueAutoHideDuration) / 1000, repeats: true) { [weak self] timer in
                self?.handleFullScreenTimerFired(timer: timer)
            }
            RunLoop.current.add(timer, forMode: .common)
            self.state = .overlayWaiting(timer)
        }
    }

    @objc
    func interruptGestDetected(_ gest: InterruptFullScreenGest) {
        if let container = container,
           container.meetingLayoutStyle == .fullscreen {
            let isSharing = container.context.meetingContent.isShareContent
            let shareType: String
            if container.context.meetingContent == .follow {
                shareType = "follow"
            } else if container.context.meetingContent == .shareScreen {
                shareType = "screen"
            } else if container.context.meetingContent == .whiteboard {
                shareType = "whiteboard"
            } else {
                shareType = "none"
            }
            InMeetFullScreenTracks.trackPhoneFullScreenWakeUpToolbar(isSharing: isSharing, shareType: shareType)
        }

        postSwitchFullScreenEvent()
    }

    @available(iOS 13.0, *)
    @objc
    func handleHoverGesture(_ gest: UIHoverGestureRecognizer) {
        switch gest.state {
        case .began, .changed, .ended:
            self.postInterruptEvent()
        default:
            break
        }
    }

    // MARK: - GestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === self.interruptGesture else {
            return false
        }
        return true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if container?.context.meetingContent == .follow,
           container?.context.meetingScene != .gallery,
           gestureRecognizer === self.hoverGest {
            return false
        }
        return disableAutoFullScreenMask == 0
    }
}

extension InMeetFullScreenDetector: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .autoHideToolStatusBar {
            Util.runInMainThread { [weak self] in
                self?.enableFullscreenMode()
            }
        }
    }
}

class InterruptFullScreenGest: UIGestureRecognizer {
    private static let timeSlope: TimeInterval = 0.5
    private static let distance2Slope: CGFloat = 100

    static var whiteListClass: [AnyClass] = [UIControl.self, UITableViewCell.self, UICollectionViewCell.self, InMeetNavigationBar.self, InMeetShareScreenBottomView.self, WhiteboardBottomView.self]
//    static let blackListClass: [AnyClass] = [InMeetingParticipantGridCell.self]

    var whiteList: Set<Int> = []
    weak var fullScreenManager: InMeetFullScreenDetector?
    var eventHandled = false

    var beginPos: CGPoint?
    var beginTimestamp: TimeInterval?

    func registerWhiteListView(_ view: UIView) {
        let ptr = Unmanaged.passUnretained(view).toOpaque()
        let addr = Int(bitPattern: ptr)
        whiteList.insert(addr)
    }

    func removeWhiteListView(_ view: UIView) {
        let ptr = Unmanaged.passUnretained(view).toOpaque()
        let addr = Int(bitPattern: ptr)
        whiteList.remove(addr)
    }

    override func reset() {
        eventHandled = false
        beginPos = nil
        beginTimestamp = nil
        super.reset()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        // 手势交互过程中不会主动进入沉浸态
        self.fullScreenManager?.postKeepOverlayWaiting()
        if self.beginPos != nil {
            for touch in touches {
                self.ignore(touch, for: event)
            }
            return
        }

        if touches.count != 1 {
            eventHandled = true
            return
        }

        let touch = touches.first!

        self.beginPos = self.location(in: nil)
        self.beginTimestamp = touch.timestamp
        for touch in touches {
            var view = touch.view
            while view != nil {
                let ptr = Unmanaged.passUnretained(view!).toOpaque()
                let addr = Int(bitPattern: ptr)
                if whiteList.contains(addr) {
                    self.eventHandled = true
                    return
                }

                if Self.whiteListClass.contains(where: { view!.isKind(of: $0) }) {
                    self.eventHandled = true
                    return
                }

                view = view?.superview
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        // 手势交互过程中不会主动进入沉浸态
        self.fullScreenManager?.postKeepOverlayWaiting()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        // 手势交互过程中不会主动进入沉浸态
        self.fullScreenManager?.postKeepOverlayWaiting()
        guard let touch = touches.first,
              let beginPos = self.beginPos,
        let beginTimestamp = self.beginTimestamp else {
            self.eventHandled = true
            self.state = .failed
            return
        }
        if touch.timestamp - beginTimestamp >= Self.timeSlope {
            self.eventHandled = true
        }
        let curPos = self.location(in: nil)
        let dx = curPos.x - beginPos.x
        let dy = curPos.y - beginPos.y
        if dx * dx + dy * dy > Self.distance2Slope {
            self.eventHandled = true
        }

        // Tap 视图空白处 进入/退出沉浸态
        if !eventHandled {
            self.eventHandled = true
            self.state = .ended
        } else {
            self.state = .failed
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        self.eventHandled = true
        self.state = .failed
    }


    override func shouldRequireFailure(of otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer is UITapGestureRecognizer {
            return true
        }
        return false
    }

    override func shouldBeRequiredToFail(by otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}


extension InMeetFullScreenDetector {
    var autoHideToolStatusBar: Bool {
        setting.autoHideToolStatusBar
    }
}
