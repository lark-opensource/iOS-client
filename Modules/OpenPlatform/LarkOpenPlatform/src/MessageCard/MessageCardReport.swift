//
//  MessageCardReport.swift
//  LarkOpenPlatform
//
//  Created by 李论 on 2020/1/15.
//

import UIKit
import LKCommonsLogging
import LKCommonsTracker

class MessageCardReport: NSObject {

    /*
     - id: mini_appplus_keyboard_click
       desc: 点击加号菜单入口
       apply: ["android","ios","pc"]

     - id: mini_appplus_keyboard_click_app
       desc: 点击加号菜单内的小程序应用
       apply: ["android","ios","pc"]

     - id: mini_appplus_keyboard_app_count
       desc: 加菜单小程序列表变化统计
       apply: ["android","ios","pc"]

     - id: gadget_sendMessageCard_send
       desc: 小程序应用卡片发送统计
       apply: ["android","ios","pc"]

     - id: gadget_sendMessageCard_call
       desc: 小程序应用卡片发送接口被调用
       apply: ["android","ios","pc"]

     - id: gadget_sendMessageCard_preview_click
       desc: 小程序应用卡片发送接口被调用
       apply: ["android","ios","pc"]
     */
    public static let key_appplus_keyboard_click = "mini_appplus_keyboard_click"
    public static let key_appplus_keyboard_click_app = "mini_appplus_keyboard_click_app"
    public static let key_appplus_keyboard_app_count = "mini_appplus_keyboard_app_count"
    public static let gadget_sendMessageCard_send = "gadget_sendMessageCard_send"
    public static let gadget_sendMessageCard_call = "gadget_sendMessageCard_call"
    public static let gadget_sendMessageCard_preview_click = "gadget_sendMessageCard_preview_click"
    private static let report_salt1 = "08a441"
    private static let report_salt2 = "42b91e"

    private let tenant_id_enc: String
    private let user_id_enc: String

    init(tenant_id: String, user_id: String) {
        tenant_id_enc = MessageCardReport.secreatString(str: tenant_id)
        user_id_enc = MessageCardReport.secreatString(str: user_id)
    }

    private static func secreatString(str: String) -> String {
        let md5 = (str + report_salt2).md5()
        let sha1 = (report_salt1 + md5).sha1()
        return sha1
    }

    public func baseParameter() -> [String: String] {
        return ["tenant_id_enc": tenant_id_enc, "user_id_enc": user_id_enc]
    }

    public func report(eventKey: String, paraDic: [String: String]) {
        let pra = baseParameter().merging(paraDic) { (left, _) -> String in
            return left
        }
        Tracker.post(TeaEvent(eventKey,
                              category: nil,
                              params: pra,
                              timestamp: Timestamp(time: Date().timeIntervalSince1970)))
    }
}
