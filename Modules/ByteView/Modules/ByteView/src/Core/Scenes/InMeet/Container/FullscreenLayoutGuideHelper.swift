//
//  InMeetContainerLayoutGuideHelper.swift
//  ByteView
//
//  Created by liujianlong on 2021/10/25.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import SnapKit
import ByteViewCommon
import ByteViewUI

enum MeetingLayoutStyle {
    // 堆叠态，工具栏 & 导航栏叠在宫格流视图上方，二者在 Z 轴方向上有重叠部分

    // 宫格流内部处理安全区偏移量：
    // - 会中 1~2 人无需偏移
    // - 会中 3 ~ ∞ 人
    //      - 字幕开启时： 需要偏移到 subtitle 上方
    //      - 字幕关闭时： 需要偏移到底部安全区上方
    // |---TopBar---|             |-subtitle-|---BottomBar---|
    // |---------------------Flow----------------------------|


    // 共享内容进入沉浸态后绝对位置不发生变化
    // |-TopBar-|-Flow-|          |-subtitle-|---BottomBar---|
    //        |---------------Share---------------|
    case overlay

    // 沉浸态，工具栏 & 导航栏 隐藏，显示悬浮麦克风控件
    // 宫格流
    //                                            |-subtitle-|
    // |----------------------Flow---------------------------|

    // 共享内容
    // 共享内容进入沉浸态后绝对位置不发生变化
    // |-Flow-|---------------Share---------------|-subtitle-|
    case fullscreen

    // 平铺态，导航栏、宫格流、工具栏自上而下排布，Z 轴方向没有重叠
    // 宫格流
    // |-TopBar-|---------Flow--------|-subtitle-|-BottomBar-|
    // 共享内容
    // |-TopBar-|-Flow-|-----Share----|-subtitle-|-BottomBar-|
    case tiled
}

extension MeetingLayoutStyle {
    var isOverlayFullScreen: Bool {
        switch self {
        case .overlay, .fullscreen:
            return true
        default:
            return false
        }
    }
}

protocol MeetingLayoutStyleListener: AnyObject {
    func containerDidChangeLayoutStyle(container: InMeetViewContainer, prevStyle: MeetingLayoutStyle?)
}

/// 用于获取InMeetViewComponent创建的LayouGuide，以满足互相对齐的要求
/// - 为统一管理设为enum，如要动态扩展可改为struct
enum InMeetLayoutGuideKey: String, Hashable {
    case topBar
    case topExtendContainer
    // 不包含顶部安全区
    case topBarContent
    case bottomBar

    /// 悬浮聊天框点击唤起键盘时**可显示聊天内容的区间**，目的是在键盘弹起时聊天和表情气泡跟着弹起，并且方便计算和更新气泡显示范围
    case chatInputKeyboard
    case content

    case padSubtitleHistory
    case initialSubtitle

    // shareBar < subtitle < toolbar
    // 同传、全屏麦克风、人名标牌、字幕、工具栏
    case accessory
    case interpreter
    case fullScreenMic
}

extension InMeetViewContainer {
    var topBarGuide: UILayoutGuide {
        self.addLayoutGuideIfNeeded(for: .topBar)
    }

    var topBarContentGuide: UILayoutGuide {
        self.addLayoutGuideIfNeeded(for: .topBarContent)
    }


    var bottomBarGuide: UILayoutGuide {
        self.addLayoutGuideIfNeeded(for: .bottomBar)
    }

    var chatInputKeyboardGuide: UILayoutGuide {
        self.addLayoutGuideIfNeeded(for: .chatInputKeyboard)
    }

    // top: max(safeArea.top, topBar.Bottom, shareBar.bottom)
    // bottom: min(safeArea.bottom, subtitle.top, bottomBar.top)
    // 提供内容显示区域的布局基础，主要包含flow、follow、shareScreen、subtitle
    var contentGuide: UILayoutGuide {
        self.addLayoutGuideIfNeeded(for: .content)
    }

    // iPad R 视图，字幕历史 LayoutGuide，由 SubtitleComponent 控制
    var padSubtitleHistory: UILayoutGuide {
        self.addLayoutGuideIfNeeded(for: .padSubtitleHistory)
    }

    var fullScreenMicGuide: UILayoutGuide {
        self.addLayoutGuideIfNeeded(for: .fullScreenMic)
    }

    var interpreterGuide: UILayoutGuide {
        self.addLayoutGuideIfNeeded(for: .interpreter)
    }

    var subtitleInitialGuide: UILayoutGuide {
        self.addLayoutGuideIfNeeded(for: .initialSubtitle)
    }

    // 提供小组件显示区域的布局基础，主要包含tips、attention、orientationTool、chat、interpreter
    var accessoryGuide: UILayoutGuide {
        self.addLayoutGuideIfNeeded(for: .accessory)
    }

    var topExtendContainerGuide: UILayoutGuide {
        self.addLayoutGuideIfNeeded(for: .topExtendContainer)
    }

    #if DEBUG
    func checkLayoutGuides() {
        let guides: [UILayoutGuide] = [
            self.topBarGuide,
            self.topBarContentGuide,
            self.bottomBarGuide,
            self.accessoryGuide
        ]
        for guide in guides where guide.hasAmbiguousLayout {
            Logger.ui.error("LayoutError: \(guide.identifier) is ambiguous!")
            let verticalConstraints = guide.constraintsAffectingLayout(for: .vertical)
            let horizontalConstraints = guide.constraintsAffectingLayout(for: .horizontal)
            Logger.ui.error("LayoutError: v: \(verticalConstraints), h: \(horizontalConstraints)")
        }
    }
    #endif
}

protocol InMeetLayoutGuideHelper {
    func updateLayoutGuides(container: InMeetViewContainer)
    func handleViewChange(_ change: InMeetViewChange, userInfo: Any?, container: InMeetViewContainer)
}

class FullscreenLayoutGuideHelper: TiledLayoutGuideHelper {

    override func updateLayoutGuides(container: InMeetViewContainer) {
        super.updateLayoutGuides(container: container)
        updateInterpreterGuide(container: container)
    }

    override func handleViewChange(_ change: InMeetViewChange, userInfo: Any?, container: InMeetViewContainer) {
        super.handleViewChange(change, userInfo: userInfo, container: container)
        switch change {
        case .subtitle:
            updateInterpreterGuide(container: container)
        default:
            break
        }
    }


    override func updateInterpreterGuide(container: InMeetViewContainer) {
        if VCScene.isPhoneLandscape {
            super.updateInterpreterLandscapeLayoutGuide(container: container)
            return
        }

        let isSubtitleVisible = container.context.isSubtitleVisible
        let subtitleOffset: CGFloat = TiledLayoutGuideHelper.subtitleHeight + 16
        let isSingleVideo = container.context.isSingleVideoVisible
        let bottomMargin = isSingleVideo ? -64 : -32

        container.interpreterGuide.snp.remakeConstraints { make in
            make.top.left.right.equalTo(container.accessoryGuide)

            make.bottom.lessThanOrEqualTo(container.accessoryGuide.snp.bottom)
            // 避免 interpreterGuide 把 accessoryGuide 往上拉
            make.bottom.equalTo(container.accessoryGuide.snp.bottom).priority(.high)

            if !isSubtitleVisible {
                make.bottom.lessThanOrEqualTo(container.fullScreenMicGuide.snp.top).offset(-16)
                make.bottom.equalTo(container.fullScreenMicGuide.snp.top).offset(-16).priority(.veryHigh)
            }

            if container.meetingLayoutStyle == .fullscreen {
                if !Display.pad {
                    make.bottom.lessThanOrEqualTo(container.bottomBarGuide.snp.top).offset(isSubtitleVisible ? -120 : bottomMargin)
                    make.bottom.equalTo(container.bottomBarGuide.snp.top).offset(isSubtitleVisible ? -120 : -32).priority(.veryHigh)
                } else {
                    make.bottom.lessThanOrEqualTo(container.bottomBarGuide.snp.top).offset(isSubtitleVisible ? -118 : bottomMargin)
                    make.bottom.equalTo(container.bottomBarGuide.snp.top).offset(isSubtitleVisible ? -118 : bottomMargin).priority(.veryHigh)
                }
            } else {
                make.bottom.lessThanOrEqualTo(container.bottomBarGuide.snp.top).offset(isSubtitleVisible ? -subtitleOffset : bottomMargin)
                make.bottom.equalTo(container.bottomBarGuide.snp.top).offset(isSubtitleVisible ? -subtitleOffset : bottomMargin).priority(.veryHigh)
            }

            if Display.phone && container.context.meetingScene != .gallery {
                make.bottom.lessThanOrEqualTo(container.contentGuide.snp.bottom).offset(isSubtitleVisible ? -subtitleOffset : -12)
                make.bottom.equalTo(container.contentGuide.snp.bottom).offset(isSubtitleVisible ? -subtitleOffset : -12).priority(.veryHigh)
            }
        }
    }

}
