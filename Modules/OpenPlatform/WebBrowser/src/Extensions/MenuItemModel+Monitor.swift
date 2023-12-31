//
//  MenuItemModel+Monitor.swift
//  WebBrowser
//
//  Created by yinyuan on 2022/4/24.
//

import ECOInfra
import ECOProbe
import LarkUIKit
import LarkSetting

/// 应用中更多菜单栏按钮Code
/// meego: https://meego.feishu.cn/?app=meego&storyId=4479826&project=larksuite&#detail
/// code定义: https://bytedance.feishu.cn/sheets/shtcncTYngXV6omM6ltYTzccpOD
private var webMenuItemButtonIDMap: [String: String] = [:]

extension MenuItemModel {
    
    public static func webBindButtonID(menuItemIdentifer: String, buttonID: String) {
        webMenuItemButtonIDMap[menuItemIdentifer] = buttonID
    }
    
    public static func webReportClick(applicationID: String?, menuItemIdentifer: String?) {
        var buttonID: String? = nil
        if let menuItemIdentifer = menuItemIdentifer {
            buttonID = webMenuItemButtonIDMap[menuItemIdentifer]
        }
        
        OPMonitor("openplatform_web_container_menu_click")
            .addCategoryValue("application_id", applicationID ?? "none")
            .addCategoryValue("identify_status", applicationID?.isEmpty == false ? "web_app": "web")
            .addCategoryValue("click", "button")
            .addCategoryValue("target", "none")
            .addCategoryValue("container_open_type", "single_tab")
            .addCategoryValue("windows_type", "embedded_window")
            .addCategoryValue("button_id", buttonID)
            .setPlatform(.tea)
            .flush()
    }
    
    public static func webButtonList(headerButtonIDList: [String]?, meunItemModels: [String: MenuItemModelProtocol]) -> String? {
        
        var buttonList: String = ""
        headerButtonIDList?.forEach({ webButtonID in
            if buttonList.count > 0 {
                buttonList.append(",")
            }
            buttonList.append(webButtonID)
        })
        meunItemModels.values.sorted { (a,b) in
            a.itemPriority > b.itemPriority
        }.forEach { item in
            let itemIdentifier = item.itemIdentifier
            if let webButtonID = webMenuItemButtonIDMap[itemIdentifier], !webButtonID.isEmpty {
                if buttonList.count > 0 {
                    buttonList.append(",")
                }
                buttonList.append(webButtonID)
            }
        }
        return buttonList
    }
}
