//
//  ServerPushService.swift
//  Calendar
//
//  Created by tuwenbo on 2022/8/22.
//

import Foundation
import ServerPB
import RxSwift
import LarkContainer

final class ServerPushService {
    /// exchange 绑定设置
    let rxExchangeBind: PublishSubject<Void> = .init()
    /// zoom 账号绑定成功通知
    let rxZoomBind: PublishSubject<Void> = .init()
    /// meetingNotes 绑定发生变更
    let rxMeetingNotesUpdate: PublishSubject<Server.MeetingNotesUpdateInfo> = .init()
    /// AI 生成日程数据
    let rxMyAiInlineStage: PublishSubject<Server.CalendarMyAIInlineStageInfo> = .init()

}
