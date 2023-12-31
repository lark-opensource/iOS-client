//
//  BaseEventDetailModelGetter.swift
//  Calendar
//
//  Created by zhouyuan on 2018/11/19.
//  Copyright © 2018 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import RxSwift
import LarkContainer

public struct DetailControllerGetterModel {
    let scene: EventDetailScene
    public let key: String
    public let calendarId: String
    public let originalTime: Int64
    public let startTime: Int64?
    public let endTime: Int64?
    public let isJoined: Bool
    public let messageId: String
    public let source: String
    public let token: String?
    public let isFromAPNS: Bool
    let joinEventAction: JoinEventAction?

    public init(scene: EventDetailScene,
                key: String,
                calendarId: String,
                source: String,
                originalTime: Int64,
                startTime: Int64?,
                endTime: Int64?,
                isJoined: Bool,
                messageId: String,
                token: String?,
                isFromAPNS: Bool = false,
                joinEventAction: ((_ success: @escaping () -> Void,
        _ failure: ((Error) -> Void)?) -> Void)?) {
        self.scene = scene
        self.key = key
        self.calendarId = calendarId
        self.originalTime = originalTime
        self.startTime = startTime
        self.endTime = endTime
        self.isJoined = isJoined
        self.messageId = messageId
        self.source = source
        self.token = token
        self.joinEventAction = joinEventAction
        self.isFromAPNS = isFromAPNS
    }
}
