//
//  InMeetViewComponentTypes.swift
//  ByteView
//
//  Created by kiri on 2021/4/9.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 表示容器和组件所归属的展示类别（比如全屏、浮窗等）
enum InMeetViewScope: Int, Hashable {
    case global = 0
    case fullScreen = 1
    case floating = 2
}

/// 用于对添加到容器中的view做z轴排序，level越高z-index越高
/// - 为统一管理设为enum，如要动态扩展可改为struct
enum InMeetContentLevel: Int, Hashable, Comparable {
    // content
    case sceneLayoutController = 101

    // https://www.figma.com/file/n55LvX7qptBy8DGfD3iFIN/Webinar-%E5%BD%A9%E6%8E%92%E6%A8%A1%E5%BC%8F-v5.30?t=M0fABoOXBHqcsOh3-1
    // 扩展 Topbar 区域，用于持久显示会中状态 （webinar 彩排中，pad 宫格模式下返回共享内容）
    case topExtendContainer

    //floating subtitle
    case floatingSubtitle

    // accessories below singleVideo
    case orientation = 201
    case activeSpeakerTag = 202
    case gridReorderTag = 203

    // single video
    case singleVideo = 300

    // suspending views
    case countDownBoard = 401 // count down board

    case fullScreenMicroPhone = 500 // fullscreen microphone

    // accessories above singleVideo
    case interpreter = 551

    // overlay
    case messageBubble = 601

    case topBar = 700
    // UX 要求 bottomBar/landscapeTools more 展开优先级需要高于 tips 及 attention，
    // 这样展开的蒙层能盖住 tips 和 attention
    case tips = 701
    case floatingMeetStatus = 702
    case floatingInteraction = 703
    case reaction = 704
    case reactionPanel = 705

    case attention = 802
    case landscapeTools = 803
    case bottomBar = 804
    case anchorToast = 805

    // cover tops
    case popover = 903
    case guide = 904

    // cover all
    case transition = 1100

    // detect is idle
    case idle = 10000

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.actualValue < rhs.actualValue
    }

    private var actualValue: Int {
        guard self == .reactionPanel, Display.pad else { return rawValue }
        // reactionPanel 在 phone 上小于 toolbar 展开页面，
        // 但是在 iPad 上要高于 toolbar，因为要把三角箭头展示在 toolbar 上
        // nolint-next-line: magic number
        return 810
    }
}

/// 用来唯一标识InMeetViewComponent
/// - 为统一管理设为enum，如要动态扩展可改为struct
enum InMeetViewComponentIdentifier: String, Hashable {
    case topBar
    case bottomBar
    case landscapeTools

    case topExtendContainer

    case content
    case flow
    case share
    case subtitle
    case interaction
    case messageBubble
    case reaction

    case singleVideo

    case accessory
    case tips
    case perfDegradeWarning
    case broadcast
    case attention
    case interpreter
    case anchorToast
    case autoShareScreen
    case misc
    case mobileLandscapeRightContainer
    case orientation
    case reconnect
    case popover
    case effect

    case guide

    case transition

    case lecturer

    case countDown
    case fullScreenMicrophone
    case rtc
    case battery

    case activeSpeakerTag

    case webinarRehearsal

    //会议状态悬浮态
    case meetingStatus
    /// 会议纪要
    case notes
}

/// 用来做ViewController的排序，目前用于查找状态栏和旋转方向的设置，最大的用于决定状态栏和旋转方向设置
struct InMeetOrderedViewController: Comparable {
    let level: Int
    var viewController: UIViewController
    static func < (lhs: InMeetOrderedViewController, rhs: InMeetOrderedViewController) -> Bool {
        lhs.level < rhs.level
    }

    private init(level: Int, viewController: UIViewController) {
        self.level = level
        self.viewController = viewController
    }
}

extension InMeetOrderedViewController {
    init(statusStyle level: StatusStyleLevel, _ viewController: UIViewController) {
        self.init(level: level.rawValue, viewController: viewController)
    }

    init(orientation level: OrientationLevel, _ viewController: UIViewController) {
        self.init(level: level.rawValue, viewController: viewController)
    }

    enum StatusStyleLevel: Int {
        case flow = 1
        case share = 2
        case singleVideo = 3
    }

    enum OrientationLevel: Int {
        case flow = 1
        case share = 2
    }
}
