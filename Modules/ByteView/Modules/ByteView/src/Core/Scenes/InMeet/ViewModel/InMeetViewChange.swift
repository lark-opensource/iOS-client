//
//  InMeetViewChangeNotifier.swift
//  ByteView
//
//  Created by kiri on 2021/4/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon

protocol InMeetViewChangeListener: AnyObject {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?)
}

enum InMeetViewChange: Int, Hashable {
    case subtitle
    case sketchMenu
    case contentScene
    case hideSelf
    case hideNonVideoParticipants
    case showSpeakerOnMainScreen
    case singleVideo
    case topBarHidden
    case bottomBarHidden

    case fullScreenMicHidden

    case horizontalSizeClass

    case flowShrunken
    case thumbnailFlowHidden
    case containerWillAppear
    case containerDidDisappear
    case containerLayoutStyle
    case participantsDidAppear
    case participantsDidDisappear
    case suggestedParticipantsAppear
    case suggestedParticipantsDisappear
    case hostControlDidAppear
    case scope

    case containerDidLayout
    case containerDidFirstAppear
    case inMeetFloatingDidAppear
    case interpretation
    case flowPageControl
    case currentGridVisibleRange

    case whiteboardMenu
    case whiteboardEditAuthority
    /// 用户是否正在操作白板
    case whiteboardOperateStatus
    /// 纪要按钮变颜色
    case notesButtonChangeColor
    /// 隐藏表情
    case hideReactionBubble
    /// 隐藏聊天
    case hideMessageBubble
}
