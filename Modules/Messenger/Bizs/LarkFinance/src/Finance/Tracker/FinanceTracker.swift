//
//  FinanceTracker.swift
//  LarkFinance
//
//  Created by 李晨 on 2019/3/6.
//

import Foundation
import Homeric
import LarkCore
import LarkModel
import LarkSDKInterface
import LKCommonsTracker

final class FinanceTracker {
    static func track(_ event: String, params: [String: Any]) {
        Tracker.post(TeaEvent(event, params: params))
    }

    static func transformHongbaoTypeToString(_ hongbaoType: RedPacketType) -> String {
        let hongbaoTypeString: String
        switch hongbaoType {
        case .exclusive:
            hongbaoTypeString = "private"
        case .groupFix, .p2P:
            hongbaoTypeString = "normal"
        case .groupRandom:
            hongbaoTypeString = "random"
        case .b2CFix:
            hongbaoTypeString = "company_normal"
        case .b2CRandom:
            hongbaoTypeString = "company_random"
        @unknown default:
            hongbaoTypeString = ""
        }
        return hongbaoTypeString
    }

    static func transformHongbaoTypeFromPageType(_ pageType: SendRedpacketPageType) -> String {
        let hongbaoTypeString: String
        switch pageType {
        case .exclusive:
            hongbaoTypeString = "private"
        case .equal:
            hongbaoTypeString = "normal"
        case .random:
            hongbaoTypeString = "random"
        default:
            hongbaoTypeString = ""
        }
        return hongbaoTypeString
    }

    // 「领取红包详情」页面
    static func imHongbaoReceiveDetailView(hongbaoType: RedPacketType,
                                           hongbaoId: String,
                                           isReciever: Bool) {
        let hongbaoTypeString = transformHongbaoTypeToString(hongbaoType)
        Self.track(Homeric.IM_HONGBAO_RECEIVE_DETAIL_VIEW, params: ["hongbao_type": hongbaoTypeString,
                                                                    "hongbao_id": hongbaoId,
                                                                    "is_receiver": isReciever ? "true" : "false"])
    }

    // 「发送红包」页面
    static func imHongbaoSendViewTrack(pageType: SendRedpacketPageType) {
        let hongbaoTypeString = transformHongbaoTypeFromPageType(pageType)
        Tracker.post(TeaEvent(Homeric.IM_HONGBAO_SEND_VIEW, params: ["hongbao_type": hongbaoTypeString]))
    }

    // 在「发送红包」页面，发生动作事件
    static func imHongbaoSendClickTrack(click: String,
                                        target: String,
                                        coverId: String? = nil,
                                        pageType: SendRedpacketPageType? = nil,
                                        themeType: String? = nil) {
        var parms: [String: String] = ["click": click,
                                       "target": target]
        if let id = coverId { parms["cover_id"] = id }
        if let type = themeType { parms["theme_type"] = type }
        if let pageType = pageType { parms["hongbao_type"] = transformHongbaoTypeFromPageType(pageType) }
        Tracker.post(TeaEvent(Homeric.IM_HONGBAO_SEND_CLICK,
                              params: parms))
    }

    // 在「领取红包」页面，发生动作事件
    static func imHongbaoReceiveClick(click: String,
                                      target: String,
                                      hongbaoType: RedPacketType,
                                      hongbaoId: String) {
        let hongbaoTypeString = transformHongbaoTypeToString(hongbaoType)
        var params: [String: String] = ["click": click,
                                        "hongbao_id": hongbaoId,
                                        "hongbao_type": hongbaoTypeString,
                                        "target": target]
        Tracker.post(TeaEvent(Homeric.IM_HONGBAO_RECEIVE_CLICK,
                              params: params))
    }

    // 「红包单个主题」页面
    static func imHongbaoThemeViewTrack(coverId: String,
                                        themeType: String) {
        var params: [String: String] = ["cover_id": coverId,
                                        "theme_type": themeType]
        Tracker.post(TeaEvent(Homeric.IM_HONGBAO_THEME_VIEW,
                              params: params))
    }

    // 「红包单个主题」页面，发生点击事件
    static func imHongbaoThemeClickTrack(click: String,
                                         target: String? = nil,
                                         coverId: String,
                                         themeType: String) {
         var params: [String: String] = ["click": click,
                                         "cover_id": coverId,
                                         "theme_type": themeType]
         if let target = target { params["target"] = target }
         Tracker.post(TeaEvent(Homeric.IM_HONGBAO_THEME_CLICK,
                               params: params))
     }
}
