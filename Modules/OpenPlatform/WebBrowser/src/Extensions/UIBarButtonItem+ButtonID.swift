//
//  UIBarButtonItem+ButtonID.swift
//  WebBrowser
//
//  Created by yinyuan on 2022/4/24.
//

import ECOInfra
import ECOProbe
import LarkSetting

/// 导航栏按钮Code
/// meego: https://meego.feishu.cn/?app=meego&storyId=4479826&project=larksuite&#detail
/// code定义: https://bytedance.feishu.cn/sheets/shtcncTYngXV6omM6ltYTzccpOD
extension UIBarButtonItem {
    
    private static var _webButtonIDKey: Void?
    
    public var webButtonID: String? {
        get {
            return objc_getAssociatedObject(self, &UIBarButtonItem._webButtonIDKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &UIBarButtonItem._webButtonIDKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public func webReportClick(applicationID: String?) {
        OPMonitor("openplatform_web_container_click")
            .addCategoryValue("application_id", applicationID ?? "none")
            .addCategoryValue("click", "button")
            .addCategoryValue("button_id", webButtonID)
            .addCategoryValue("click_location", "top")
            .addCategoryValue("container_open_type", "single_tab")
            .addCategoryValue("windows_type", "embedded_window")
            .setPlatform(.tea)
            .flush()
    }
    
}
