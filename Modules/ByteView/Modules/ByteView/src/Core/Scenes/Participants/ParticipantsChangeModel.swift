//
//  ParticipantsChangeModel.swift
//  ByteView
//
//  Created by wulv on 2022/6/23.
//

import Foundation
import ByteViewNetwork

struct ParticipantsChangeModel {
    /// 全量呼叫
    var callings: [Participant]

    /// 全量会中
    var onTheCalls: [Participant]

    /// 全量呼叫反馈
    var feedbacks: [Participant]

    var isEmpty: Bool { callings.isEmpty && onTheCalls.isEmpty && feedbacks.isEmpty }
}
