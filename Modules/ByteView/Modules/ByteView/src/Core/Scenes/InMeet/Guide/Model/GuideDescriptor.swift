//
//  GuideDescriptor.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/8/9.
//

import Foundation
import ByteViewCommon

enum GuideType: String {
    case askHostForHelp
    case rejoinBreakoutRoom
    case breakoutRoomHostControl
    case countDown
    case countDownFold
    case more
    case liveReachMaxParticipant
    case interpretation
    case hostControl
    case padChangeSceneMode
    case vote
    case customOrder
    case resetOrder
    case interviewPromotion
    case interviewSpace
    case webinarAttendee
    /// 投屏转妙享，点击按钮可以自由浏览
    case shareScreenToFollowViewOnYourOwn
    /// 投屏转妙享，点击按钮回到共享屏幕
    case shareScreenToFollowReturnToShareScreen
    /// 会议纪要引导
    case notesOnboarding
    /// 创建会议纪要
    case newNotesHint
    /// 新议程开始
    case newAgendaHint
    case transcribe
    /// 麦克风位置调整
    case micLocation
    case myai
    case security
}

class GuideDescriptor {
    typealias Action = () -> Void

    let type: GuideType
    var title: String?
    var desc: String?
    var animationName: String?
    var duration: TimeInterval?
    // 暂时不支持流程式 guide
//    var next: GuideDescriptor?
    var sureAction: Action?
    /// 点击触发当前Guide移除之后进行的操作。如果需要继续显示其他Guide，可以写在这里
    var afterSureAction: Action?
    var style: GuideStyle = .plain

    var isShowing = false

    init(type: GuideType, title: String?, desc: String?) {
        self.type = type
        self.title = title
        self.desc = desc
    }

    enum GuideStyle: String {
        case plain
        /// 特化浅色的Onboarding样式，例：纪要Onboarding
        case lightOnboarding
        case darkPlain
        case focusPlain
        case alert
        case alertWithAnimation
        /// 特化浅色的Tips样式，例：纪要NewAgendaHint
        case stressedPlain
    }
}
