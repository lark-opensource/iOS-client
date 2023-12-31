//
//  SCPasteboard.swift
//  CalendarFoundation
//
//  Created by JackZhao on 2023/3/8.
//

import Foundation
import LKCommonsLogging

// doc: https://bytedance.feishu.cn/wiki/wikcnhezxNdMtFcUiLqetuVSJ6d
// 用于剪切版安全管控的工具类; SC = security
public struct SCPasteboardUtils {
    private static let logger = Logger.log(SCPasteboardUtils.self, category: "lark.calendar.CalendarFoundation")
    
    // 剪切版安全管控上报场景
    public enum SCPasteboardScene: String {
        // 日历的CopyableLabel组件复制，比如在日历标题进行复制
        case copyableLabelCopy              = "LARK-PSDA-calendar_copyableLabel_copy"
        // 日程详情地点信息复制
        case eventDetailLocationInfoCopy    = "LARK-PSDA-calendar_event_detail_locationInfo_copy"
        // 日程详情会议室信息复制
        case eventDetailMeetingRoomInfoCopy = "LARK-PSDA-calendar_event_detail_meetingRoomInfo_copy"
        // 日程链接签到复制链接
        case eventCheckInLinkCopy           = "LARK-PSDA-calendar_event_checkInLink_copy"
        // 日程QRCode签到分享url的复制
        case eventCheckInQRCodeShareUrlCopy = "LARK-PSDA-calendar_event_checkInQRCode_shareUrl_copy"
        // 日历分享
        case calendarShareCopy              = "LARK-PSDA-calendar_share_copy"
        // 日历的webView通过JSBridge调用剪切版复制, 例如在日历详情页复制
        case docsWebViewBridgeClipBoardSet  = "LARK-PSDA-calendar_docsWebViewBridge_clipBoardSet"
        // 日历开发者模式debug复制一些信息，比如日程、会议室的debug描述信息
        case debugModeInfoCopy              = "LARK-PSDA-calendar_debugMode_info_copy"
    }
    
    // 获取上报场景的唯一标识
    public static func getSceneKey(_ scene: SCPasteboardScene) -> String {
         scene.rawValue
    }

    // 上报copy失败的日志
    public static func logCopyFailed(file: String = #fileID,
                                     function: String = #function,
                                     line: Int = #line) {
        let log = "setting pasteboard failed due to insecurity"
        Self.logger.info(log,
                         file: file,
                         function: function,
                         line: line)
        assertionFailure(log)
    }
}
