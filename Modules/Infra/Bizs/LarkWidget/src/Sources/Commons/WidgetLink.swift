//
//  TodayWidgetDetail.swift
//  ColorfulWidght
//
//  Created by ZhangHongyun on 2020/11/25.
//

import Foundation
import UIKit

public enum WidgetLink {

    public static var applinkHost = ""
    public static var helpCenterHost = ""
    public static var docsHomeHost = ""

    public static var searchMain: String { "lark://" + applinkHost + "/client/search/main" }
    public static var qrcodeMain: String { "lark://" + applinkHost + "/client/qrcode/main" }
    public static var workplaceMain: String { "lark://" + applinkHost + "/client/workplace/open" }
    public static var createSchedule: String { "lark://" + applinkHost + "/client/calendar/event/create" }
    public static var createDoc: String { "lark://" + applinkHost + "/client/docs/template" }
    public static var calendarTab: String { "lark://" + applinkHost + "/client/calendar/open" }
    public static var newTask: String { "lark://" + applinkHost + "/client/todo/create" }
    public static var newTodo: String { "https://" + applinkHost + "/client/todo/create" }
    public static var todoTab: String { "https://" + applinkHost + "/client/todo/open" }
    public static var docsDetail: String { "lark://" + applinkHost + "/client/docs/open" }
    // docTab appLink 暂不支持移动端，所以采用这种形式间接打开 Tab
    public static var docsTab: String { "lark://" + applinkHost + "/client/docs/open?url=http://\(docsHomeHost)/space/" }
    
    /// 小组件帮助文档的 AppLink
    /// - Parameter isFeishu: 是否飞书品牌
    public static func widgetHelpCenter(isFeishu: Bool) -> String {
        let applink = "https://\(applinkHost)"
        let openUrlPath = "/client/web_url/open?mode=window&url=https%3A%2F%2F\(helpCenterHost)%2Fhc%2Farticles%2F"
        let articleID = isFeishu ? "031796699668" : "460986746157"
        return applink + openUrlPath + articleID
    }
}
