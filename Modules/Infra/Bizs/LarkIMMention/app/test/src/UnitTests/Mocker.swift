//
//  Mocker.swift
//  unit-tests
//
//  Created by Yuri on 2022/12/12.
//

import Foundation
import RustPB
import LarkIMMention

typealias Chatter = RustPB.Basic_V1_Chatter
typealias ChatChatter = RustPB.Basic_V1_Entity.ChatChatter
typealias ChatterResponse = RustPB.Im_V1_GetMentionChatChattersResponse

struct Mocker {
    
    static let chatChatters = [
        "1": Mocker.mockChatter(id: "1"),
        "3": Mocker.mockChatter(id: "3"),
        "5": Mocker.mockChatter(id: "5"),
        "7": Mocker.mockChatter(id: "7"),
    ]
    static let chatters = [
        "2": Mocker.mockChatter(id: "2"),
        "4": Mocker.mockChatter(id: "4"),
        "6": Mocker.mockChatter(id: "6"),
        "8": Mocker.mockChatter(id: "8"),
    ]
    
    static func mockChatter(id: String) -> Chatter {
        var chatter = Chatter()
        chatter.id = id
        chatter.name = id
        return chatter
    }
    
    static func mockItem(id: String, name: String? = nil) -> IMPickerOption {
        var chatter = IMPickerOption(id: id)
        chatter.actualName = name
        return chatter
    }
    
    static func mockLocalChatterResponse(chatId: String) -> ChatterResponse {
        var res = ChatterResponse()
        res.wantedMentionIds = ["1"]
        res.inChatChatterIds = ["3", "5"]
        res.outChatChatterIds = ["2", "4", "6"]
        var chatChatters = ChatChatter()
        chatChatters.chatters = Mocker.chatChatters
        res.entity.chatChatters = [chatId: chatChatters]
        res.entity.chatters = chatters
        return res
    }
    
    static func mockRemoteChatterResponse(chatId: String) -> ChatterResponse {
        var res = ChatterResponse()
        res.wantedMentionIds = ["1", "3"]
        res.inChatChatterIds = ["5", "7"]
        res.outChatChatterIds = ["6", "2", "8"]
        var chatChatters = ChatChatter()
        chatChatters.chatters = Mocker.chatChatters
        res.entity.chatChatters = [chatId: chatChatters]
        res.entity.chatters = chatters
        return res
    }
    
    static func mockMentionItem(id: String = UUID().uuidString) -> IMMentionOptionType {
        return IMPickerOption(id: id)
    }
    
    static func mockMeetingFocusStatus() -> RustPB.Basic_V1_Chatter.ChatterCustomStatus {
        var status = RustPB.Basic_V1_Chatter.ChatterCustomStatus()
        status.title = "In meeting"
        status.iconKey = "GeneralInMeetingBusy"
        var interval = RustPB.Basic_V1_StatusEffectiveInterval()
        interval.startTime = Int64(Date().timeIntervalSince1970 - 100)
        interval.endTime = Int64(Date().timeIntervalSince1970 + 100)
        interval.isShowEndTime = true
        status.effectiveInterval = interval
        var format = RustPB.Basic_V1_TimeFormat()
        format.timeUnit = .minute
        format.startEndLayout = .endOnly
        return status
    }
    
    static func mockOnLeaveFocusStatus() -> RustPB.Basic_V1_Chatter.ChatterCustomStatus {
        var status = RustPB.Basic_V1_Chatter.ChatterCustomStatus()
        status.title = "On Leave"
        status.iconKey = "GeneralVacation"
        var interval = RustPB.Basic_V1_StatusEffectiveInterval()
        interval.startTime = Int64(Date().timeIntervalSince1970 - 100)
        interval.endTime = Int64(Date().timeIntervalSince1970 + 100)
        interval.isShowEndTime = true
        status.effectiveInterval = interval
        var format = RustPB.Basic_V1_TimeFormat()
        format.timeUnit = .minute
        format.startEndLayout = .endOnly
        return status
    }
    
    static func mockExternalTag() -> RustPB.Basic_V1_TagData.TagDataItem {
        var item = RustPB.Basic_V1_TagData.TagDataItem()
        item.textVal = "External"
        item.tagID = UUID().uuidString
        item.respTagType = .relationTagExternal
        return item
    }
}
