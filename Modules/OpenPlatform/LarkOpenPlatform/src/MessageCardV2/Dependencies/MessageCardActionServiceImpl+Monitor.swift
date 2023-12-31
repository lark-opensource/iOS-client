//
//  MessageCardActionServiceImpl+Monitor.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/1/17.
//

import Foundation
import ECOProbe
import LarkMessageCard
extension MessageCardActionServiceImpl {
    enum ReportActionType: String {
        case openLink = "open_link"
        case interaction = "interaction"
        case openLinkandInteraction = "open_link_and_interaction"
    }

    /// 消息卡片业务埋
    /// https://bytedance.feishu.cn/sheets/shtcn7SfFfKGMVduuDvFajBLwDf?sheet=KFuJbb
    /// https://bytedance.feishu.cn/docx/MX3ud8pZGoilsAxgO0icZc1UnGe
    func reportAction(
        actionType: ReportActionType?,
        elementTag: String? = nil,
        url: String? = nil
    ) {
        let teaEventName = "openplatform_im_message_card_click"
        let monitor = OPMonitor(teaEventName)
            .addMetricValue("click", "message_card")
            .addMetricValue("msg_id", messageID)
            .addMetricValue("action_type", actionType?.rawValue)
            .addMetricValue("click_element", elementTag)
            .addMetricValue("target", "none")
            .setPlatform(.tea)
        
        if let url = url {
            url.setUrlMonitorCategoryValue(monitor: monitor)
        }
        monitor.flush()
    }
}

