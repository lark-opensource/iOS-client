//
//  InMeetHeartbeatTrackViewModel.swift
//  ByteView
//
//  Created by liujianlong on 2022/7/8.
//

import Foundation
import ByteViewTracker

/// 会中视图周期性埋点
/// https://bytedance.feishu.cn/sheets/shtcnGuTTDaYcJBFG0HXLG618Hb

final class InMeetHeartbeatTrackViewModel: InMeetViewModelComponent, InMeetViewChangeListener, RouterListener, InMeetShareDataListener {
    private let viewContext: InMeetViewContext
    private let tracker: InMeetViewHeartbeatTracker
    private let account: ByteviewUser

    required init(resolver: InMeetViewModelResolver) {
        let meeting = resolver.meeting
        self.viewContext = resolver.viewContext
        self.account = resolver.meeting.account
        self.tracker = InMeetViewHeartbeatTracker(isFloating: meeting.router.isFloating,
                                                  isHorizontalRegular: viewContext.horizontalSizeClassIsRegular,
                                                  isSingleVideoVisible: viewContext.isSingleVideoVisible,
                                                  contentScene: self.viewContext.meetingScene)
        resolver.meeting.shareData.addListener(self, fireImmediately: true)
        // 小窗切换为全屏重置 contentScene 时，不会回调 contentScene viewChange 事件
        // 需要监听 scope 事件 更新 contentScene
        viewContext.addListener(self, for: [.contentScene, .scope, .singleVideo, .horizontalSizeClass, .containerDidFirstAppear, .inMeetFloatingDidAppear])
        meeting.router.addListener(self, fireImmediately: false)
    }

    deinit {
        self.tracker.stop()
    }

    // MARK: - ViewChange
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        switch change {
        case .contentScene, .scope:
            self.tracker.updateContentScene(self.viewContext.meetingScene)
        case .singleVideo:
            self.tracker.updateIsFullScreen(self.viewContext.isSingleVideoVisible)
        case .horizontalSizeClass:
            self.tracker.updateHorizontalIsRegular(self.viewContext.horizontalSizeClassIsRegular)
        case .inMeetFloatingDidAppear, .containerDidFirstAppear:
            self.tracker.start()
        default:
            break
        }
    }

    // MARK: - RouterListener
    func didChangeWindowFloatingBeforeAnimation(_ isFloating: Bool, window: FloatingWindow?) {
        self.tracker.updateIsFloating(isFloating)
    }

    // MARK: - InMeetShareDataListener
    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        self.tracker.updateIsSharing(newScene.isSharingContent,
                                     isSharer: newScene.isSelfSharingContent(with: self.account),
                                     shareType: newScene.shareTypeDesc)
    }

}

private final class InMeetViewHeartbeatTracker {

    enum LayoutType: String {
        case thumbnail
        case mini_window
        case speaker
        case gallery
        case webinar_stage
    }

    private enum HeartbeatTrackerState {
        case stop
        case pending(DispatchSourceTimer)
        case running(DispatchSourceTimer)
    }
    private var heartbeatStatus: HeartbeatTrackerState = .stop

    private let queue = DispatchQueue(label: "com.byteview.heartbeat_tracks")

    private var contentScene: InMeetSceneManager.SceneMode
    private var isFloating: Bool
    private var ifLandscapeScreen: Bool {
        InMeetOrientationToolComponent.isLandscapeOrientation
    }
    private var isSharing: Bool = false
    private var isSharer: Bool = false
    private var shareType: String = "none"
    private var timer: DispatchSourceTimer?
    private var isFullScreen: Bool = false
    private var horizontalIsRegular: Bool = false

    private var layoutType: LayoutType? {
        if isFloating {
            return .mini_window
        }

        switch contentScene {
        case .gallery:
            return .gallery
        case .speech:
            return .speaker
        case .thumbnailRow:
            return .thumbnail
        case .webinarStage:
            return .webinar_stage
        }
    }

    required init(isFloating: Bool,
                  isHorizontalRegular: Bool,
                  isSingleVideoVisible: Bool,
                  contentScene: InMeetSceneManager.SceneMode) {
        self.isFloating = isFloating
        self.isFullScreen = isSingleVideoVisible
        self.horizontalIsRegular = isHorizontalRegular
        self.contentScene = contentScene
    }

    deinit {
        if case .pending(let timer) = heartbeatStatus {
            timer.cancel()
            timer.resume()
        } else if case .running(let timer) = heartbeatStatus {
            timer.cancel()
        }
    }

    private func makeTimer() -> DispatchSourceTimer {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        self.timer = timer
        timer.setEventHandler { [weak self] in
            self?.track()
        }
        // nolint-next-line: magic number
        timer.schedule(deadline: .now(), repeating: .seconds(30), leeway: .seconds(1))
//        timer.schedule(deadline: .now(), repeating: .seconds(5), leeway: .seconds(1))
        return timer
    }

    func start() {
        self.queue.async {
            guard case .stop = self.heartbeatStatus else {
                return
            }
            let timer = self.makeTimer()
            if self.layoutType == nil {
                self.heartbeatStatus = .pending(timer)
            } else {
                self.heartbeatStatus = .running(timer)
                timer.resume()
            }
        }
    }

    func stop() {
        self.queue.async {
            switch self.heartbeatStatus {
            case .stop:
                return
            case .running(let timer):
                timer.cancel()
                self.heartbeatStatus = .stop
                return
            case .pending(let timer):
                timer.cancel()
                timer.resume()
                self.heartbeatStatus = .stop
                return
            }
        }
    }

    private func tryActivateTimer() {
        if self.layoutType != nil,
           case .pending(let timer) = self.heartbeatStatus {
            self.heartbeatStatus = .running(timer)
            timer.resume()
        }
    }

    func updateContentScene(_ contentScene: InMeetSceneManager.SceneMode) {
        queue.async {
            self.contentScene = contentScene
            self.tryActivateTimer()
        }
    }

    func updateIsFloating(_ isFloating: Bool) {
        queue.async {
            self.isFloating = isFloating
            self.tryActivateTimer()
        }
    }

    func updateHorizontalIsRegular(_ isRegular: Bool) {
        queue.async {
            self.horizontalIsRegular = isRegular
        }
    }

    func updateIsFullScreen(_ isFullScreen: Bool) {
        queue.async {
            self.isFullScreen = isFullScreen
        }
    }

    func updateIsSharing(_ isSharing: Bool, isSharer: Bool, shareType: String) {
        queue.async {
            self.isSharing = isSharing
            self.isSharer = isSharer
            self.shareType = shareType
        }
    }

    private func track() {
        let layoutType = self.layoutType ?? .gallery
        var params: [String: Any] = [
            "layout_type": layoutType.rawValue,
            "is_sharing": isSharing,
            "share_type": shareType,
            "view_type_pad": Display.phone ? "none" : self.horizontalIsRegular ? "r" : "c",
            "is_full_screen": isFullScreen,
            "is_sharer": isSharing ? "\(isSharer)" : "none"
        ]
        if layoutType != .mini_window {
            params["if_landscape_screen"] = "\(ifLandscapeScreen)"
        } else {
            params["if_landscape_screen"] = "false"
        }
        VCTracker.post(name: .vc_meeting_onthecall_heartbeat_status,
                       params: TrackParams(params))
    }
}

private extension InMeetShareScene {

    var shareTypeDesc: String {
        switch shareSceneType {
        case .othersSharingScreen, .selfSharingScreen, .shareScreenToFollow:
            return "screen"
        case .magicShare:
            return "follow"
        case .whiteboard:
            return "white_board"
        default:
            return "none"
        }
    }

}
