//
//  InMeetViewContext.swift
//  ByteView
//
//  Created by kiri on 2021/5/18.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewUI

/// 用于InMeetViewModel的UI上下文
/// - 存储view间交互的flags，并触发相关的InMeetViewChange的通知
final class InMeetViewContext {
    let meetingId: String
    var meetingLayoutStyle: MeetingLayoutStyle = .tiled {
        didSet {
            guard meetingLayoutStyle != oldValue else {
                return
            }
            updateBottomBar()
        }
    }
    private let actionHolder: InMeetAsyncActionHolder
    private(set) var scope: InMeetViewScope = .fullScreen
    /// 小窗的Size大小，避免直接取window的值不准确
    @RwAtomic
    var floatingWindowSize: CGSize = .zero
    init(meetingId: String) {
        self.meetingId = meetingId
        self.actionHolder = InMeetAsyncActionHolder(meetingId: meetingId)
        InMeetAsyncActionHolder.current = actionHolder
    }

    weak var hostViewController: UIViewController?

    /// 大小窗切换时更新context
    func updateScope(_ scope: InMeetViewScope) {
        if scope != self.scope {
            self.scope = scope
            if scope == .fullScreen {
                resetContextOnFullScreen()
            }
            postWithoutBlocking(.scope, userInfo: self.scope)
        }
    }

    /// 横竖屏切换时更新context
    func updateOrientation() {
        if scope == .fullScreen, Display.phone {
            updateTopBar()
            updateBottomBar()
        }
    }

    /// 是否需要小窗返回展示白板菜单
    var isNeedAutoShowWbMenu: Bool = false

    var chatRecordText = ""
    var isTurnOnSubtitleWhenJoinChecked = false
    /// 是否点掉过面试速记提示
    var cancledPeopleMinutesPopovers: Set<Int64> = []
    /// 倒计时悬浮面板的位置
    var countDownBoardLeftTopPoint: CGPoint?

    /// 隐藏表情
    var isHiddenReactionBubble = false {
        didSet {
            if isHiddenReactionBubble != oldValue {
                post(.hideReactionBubble, userInfo: isHiddenReactionBubble)
            }
        }
    }
    /// 隐藏聊天
    var isHiddenMessageBubble = false {
        didSet {
            if isHiddenMessageBubble != oldValue {
                post(.hideMessageBubble, userInfo: isHiddenMessageBubble)
            }
        }
    }

    /// 是否打开了标注
    var isSketchMenuEnabled = false {
        didSet {
            if oldValue != isSketchMenuEnabled {
                post(.sketchMenu, userInfo: isSketchMenuEnabled)
                updateBottomBar()
            }
        }
    }

    // 白板编辑权限是否变化（用户更新横屏悬浮组件布局）
    var isWhiteboardEditEnable: Bool = false {
        didSet {
            if oldValue != isWhiteboardEditEnable {
                post(.whiteboardEditAuthority, userInfo: isWhiteboardEditEnable)
            }
        }
    }
    /// 是否在编辑白板
    var isWhiteboardMenuEnabled = false {
        didSet {
            if oldValue != isWhiteboardMenuEnabled {
                post(.whiteboardMenu, userInfo: isWhiteboardMenuEnabled)
                updateBottomBar()
            }
        }
    }

    /// 是否打开了字幕
    var isSubtitleVisible = false {
        didSet {
            if oldValue != isSubtitleVisible {
                post(.subtitle, userInfo: isSubtitleVisible)
            }
        }
    }

    /// 是否为译员
    var isInterpreter = false {
        didSet {
            if oldValue != isInterpreter {
                post(.interpretation, userInfo: isInterpreter)
            }
        }
    }

    /// 是否打开了单流放大
    var isSingleVideoVisible = false {
        didSet {
            if oldValue != isSingleVideoVisible {
                post(.singleVideo, userInfo: isSingleVideoVisible)
                updateTopBar()
                updateBottomBar()
            }
        }
    }

    /// 是否收起顶部视频流
    var isFlowShrunken = false {
        didSet {
            if oldValue != isFlowShrunken {
                post(.flowShrunken, userInfo: isFlowShrunken)
            }
        }
    }

    /// 缩略图视图宫格流是否被隐藏
    var isThumbnailFLowHidden = false {
        didSet {
            if oldValue != isThumbnailFLowHidden {
                post(.thumbnailFlowHidden, userInfo: isThumbnailFLowHidden)
            }
        }
    }

    var isFlowPageControlVisible = false {
        didSet {
            if oldValue != isFlowPageControlVisible {
                post(.flowPageControl, userInfo: isFlowPageControlVisible)
            }
        }
    }

    var currentGridVisibleRange: GridVisibleRange = .page(index: 0) {
        didSet {
            if currentGridVisibleRange != oldValue {
                post(.currentGridVisibleRange, userInfo: currentGridVisibleRange)
            }
        }
    }

    var horizontalSizeClassIsRegular: Bool = false {
        didSet {
            if horizontalSizeClassIsRegular != oldValue {
                post(.horizontalSizeClass, userInfo: horizontalSizeClassIsRegular)
            }
        }
    }

    /// 当前主界面的模式（宫格、共享屏幕、magicshare）
    var contentScene: InMeetContentScene = .initial {
        didSet {
            if oldValue != contentScene {
                post(.contentScene, userInfo: contentScene)
            }
        }
    }

    // 保存共享/非共享场景下的 SceneMode，用于大小窗切换时恢复
    var sceneControllerState: SceneSwitchStrategy.SceneControllerState = .default
    var savedSelfShareScreenIsShrink: Bool?
    var savedFocusIsShrink: Bool?

    var meetingContent: InMeetSceneManager.ContentMode = .flow {
        didSet {
            if oldValue != meetingContent {
                self.isShowSpeakerOnMainScreen = false
                post(.contentScene, userInfo: meetingContent)
            }
        }
    }

    var meetingScene: InMeetSceneManager.SceneMode = .gallery {
        didSet {
            if oldValue != meetingScene {
                post(.contentScene, userInfo: meetingScene)
                updateBottomBar()
            }
        }
    }

    // 演讲者视图小窗状态(是否收起, 位移)
    var floatingSpeechState: (Bool, CGAffineTransform)?

    // 演讲者视图状态(是否大小窗切换, 内容)
    var isSpeechFlowSwitched: Bool = false

    weak var sceneManager: InMeetSceneManager?
    weak var fullScreenDetector: InMeetFullScreenDetector?

    /// 是否在设置页显示“隐藏本人视图”设置开关
    var hideSelfEnabled: Bool {
        sceneManager?.hideSelfEnabled ?? false
    }
    /// 设置开关；是否真正隐藏自己还需要更多业务判断，比如会中人数
    var isSettingHideSelf: Bool = false {
        didSet {
            sceneManager?.updateHideSelf()
        }
    }
    /// 是否真正隐藏自己
    var isHideSelf: Bool = false {
        didSet {
            if oldValue != isHideSelf {
                post(.hideSelf, userInfo: isHideSelf)
            }
        }
    }

    /// 设置页“隐藏非视频参会者”开关状态
    var hideNonVideoParticipantsEnableType: InMeetSceneManager.SettingEnableType {
        sceneManager?.hideNonVideoParticipantsEnabled ?? .none
    }
    /// 设置开关；是否真正隐藏非视频参会者还需要更多业务判断，比如会中人数
    var isSettingHideNonVideoParticipants = false {
        didSet {
            sceneManager?.updateHideNonVideo()
        }
    }
    /// 是否隐藏非视频参会者
    var isHideNonVideoParticipants = false {
        didSet {
            if oldValue != isHideNonVideoParticipants {
                post(.hideNonVideoParticipants, userInfo: isHideNonVideoParticipants)
            }
        }
    }

    var magicShareUrl: String? {
        didSet {
            guard magicShareUrl != oldValue else { return }
            self.isShowSpeakerOnMainScreen = false
        }
    }

    var screenShareID: String? {
        didSet {
            guard screenShareID != oldValue else { return }
            self.isShowSpeakerOnMainScreen = false
        }
    }
    var whiteboardID: Int64? {
        didSet {
            guard whiteboardID != oldValue else { return }
            self.isShowSpeakerOnMainScreen = false
        }
    }

    /// 是否在设置显示"主画面显示发言人"
    var showSpeakerOnMainScreenEnabled: Bool {
        if meetingScene == .gallery {
            // 宫格流不显示
            return false
        }
        return meetingContent.enableShowSpeakOnMainView
    }

    var isShowSpeakerOnMainScreen: Bool = false {
        didSet {
            if isShowSpeakerOnMainScreen != oldValue {
                self.updateBottomBar()
                self.post(.showSpeakerOnMainScreen, userInfo: isShowSpeakerOnMainScreen)
            }
        }
    }

    var isNotesButtonColorful: Bool = false {
        didSet {
            if isNotesButtonColorful != oldValue {
                self.post(.notesButtonChangeColor, userInfo: isNotesButtonColorful)
            }
        }
    }

    // MARK: - topbottom
    /// TopBar是否隐藏（无论划出还是藏起来都是隐藏）
    private(set) var isTopBarHidden = false
    /// TopBar是否被划出界面（会影响界面的布局）
    private(set) var isTopBarSlideOut = false
    /// BottomBar是否隐藏（无论划出还是藏起来都是隐藏）
    private(set) var isBottomBarHidden = false
    /// BottomBar是否被划出界面（会影响界面的布局）
    private(set) var isBottomBarSlideOut = false
    /// 不包含自动隐藏（iphone横屏）的情况
    private(set) var isStatusBarHidden = false

    var isFullScreenMicHidden = true {
        didSet {
            guard oldValue != isFullScreenMicHidden else {
                return
            }
            post(.fullScreenMicHidden, userInfo: isFullScreenMicHidden)
        }
    }

    /// 入会首次自动隐藏时长异化
    var shouldStartFirstOverlayTimeOut: Bool = true

    private func updateTopBar() {
        let isTopHidden = isSingleVideoVisible
        let isSlideOut: Bool
        if isTopHidden {
            if isSingleVideoVisible {
                isSlideOut = false
            } else {
                isSlideOut = true
            }
        } else {
            isSlideOut = false
        }
        if self.isTopBarHidden != isTopHidden || self.isTopBarSlideOut != isSlideOut {
            self.isTopBarHidden = isTopHidden
            self.isTopBarSlideOut = isSlideOut
            post(.topBarHidden, userInfo: isTopHidden)
        }
    }

    private func updateBottomBar() {
        let isBottomHidden = ((isSketchMenuEnabled || isWhiteboardMenuEnabled) && meetingScene != .gallery && !isShowSpeakerOnMainScreen)
            || isSingleVideoVisible
            || (Display.phone && VCScene.isLandscape)
            || meetingLayoutStyle == .fullscreen
        let isSlideOut: Bool
        if isBottomHidden {
            if !isSubtitleVisible, isSingleVideoVisible {
                isSlideOut = false
            } else {
                isSlideOut = true
            }
        } else {
            isSlideOut = false
        }
        if self.isBottomBarHidden != isBottomHidden || self.isBottomBarSlideOut != isSlideOut {
            self.isBottomBarHidden = isBottomHidden
            self.isBottomBarSlideOut = isSlideOut
            post(.bottomBarHidden, userInfo: isBottomBarHidden)
        }
    }

    // MARK: - common
    func post(_ change: InMeetViewChange, userInfo: Any? = nil) {
        if isBlockViewChangePosting { return }
        postWithoutBlocking(change, userInfo: userInfo)
    }

    private func postWithoutBlocking(_ change: InMeetViewChange, userInfo: Any?) {
        assertMain()
        listeners.invokeListeners(for: change) { listener in
            listener.viewDidChange(change, userInfo: userInfo)
        }
    }

    private var isBlockViewChangePosting = false
    private func resetContextOnFullScreen() {
        isBlockViewChangePosting = true
        isSubtitleVisible = false
        isSingleVideoVisible = false
        contentScene = .initial
        isTopBarHidden = false
        isTopBarSlideOut = false
        isBottomBarHidden = false
        isBottomBarSlideOut = false

        updateTopBar()
        updateBottomBar()
        isBlockViewChangePosting = false
    }

    /// 在`container.accessoryGuide`范围内的Views.
    /// 横屏模式下的`InMeetOrientationToolComponent`需要感知该信息以防止
    /// 浮动麦克风拖拽后与这些View重叠.
    var accessoryViews: [UIView] = []

    private let listeners = HashListeners<InMeetViewChange, InMeetViewChangeListener>()
}

extension InMeetViewContext {
    func addListener(_ listener: InMeetViewChangeListener, for change: InMeetViewChange) {
        listeners.addListener(listener, for: change)
    }

    func addListener(_ listener: InMeetViewChangeListener, for changes: Set<InMeetViewChange>) {
        listeners.addListener(listener, for: changes)
    }

    func removeListener(_ listener: InMeetViewChangeListener) {
        listeners.removeListener(listener)
    }
}

extension InMeetAsyncActionHolder {
    /// 和会中界面同生命周期
    fileprivate(set) static weak var current: InMeetAsyncActionHolder?
}

extension InMeetViewContext {
    var hasShareBar: Bool {
        meetingScene != .gallery && (meetingContent != .flow && meetingContent != .selfShareScreen)
    }
}
