//
//  OPMonitorCodeDefine.swift
//  OPSDK
//
//  Created by laisanpin on 2022/4/24.
//  用来定义开放平台中的埋点Code(主要是产品埋点, 不走ECOProbeMeta)

import Foundation

/// 导航栏按钮Code
/// meego: https://meego.feishu.cn/?app=meego&storyId=4479826&project=larksuite&#detail
/// code定义: https://bytedance.feishu.cn/sheets/shtcncTYngXV6omM6ltYTzccpOD
public enum OPNavigationBarItemMonitorCode: String {
    /// 返回按钮"<"
    case backButton = "1001"
    /// 返回首页按钮
    case homeButton = "1002"
    /// 更多按钮
    case moreButton = "1003"
    /// 关闭按钮
    case closeButton = "1004"
    /// 独立窗口按钮
    case windowButton = "1005"
    /// 完成按钮
    case completeButton = "1006"
    /// 前进按钮
    case forwardButton = "1007"
}

/// 应用中更多菜单栏按钮Code
/// meego: https://meego.feishu.cn/?app=meego&storyId=4479826&project=larksuite&#detail
/// code定义: https://bytedance.feishu.cn/sheets/shtcncTYngXV6omM6ltYTzccpOD
public enum OPMenuItemMonitorCode: String {
    /// 保留位
    case unknown = "2000"
    /// 打开飞书调试界面按钮
    case larkDebugButton = "2001"
    /// 分享按钮按钮
    case shareButton = "2002"
    /// 打开浮窗按钮
    case multiTaskButton = "2003"
    /// 添加到工作台常用按钮
    case commonAppButton = "2004"
    /// 添加到桌面按钮
    case addDesktopButton = "2005"
    /// 调试按钮
    case appDebugButton = "2006"
    /// 反馈按钮
    case feedbackButton = "2007"
    /// 机器人按钮
    case botButton = "2008"
    /// 重新进入应用按钮
    case relaunchButton = "2009"
    /// 关于按钮
    case aboutButton = "2010"
    /// 返回首页按钮
    case gohomeButton = "2011"
    /// 应用评分按钮
    case scoreButton = "2014"
    /// 刷新按钮
    case refreshButton = "2015"
    /// 打开浏览器按钮
    case openBrowserButton = "2016"
    /// 复制链接按钮
    case copyLinkButton = "2017"
    /// 翻译按钮
    case translateButton = "2018"
    /// 分享到微信按钮
    case shareToWechatButton = "2019"
    /// 分享到微信朋友圈
    case shareToWechatMomentButton = "2020"
    /// 清理缓存按钮
    case cacheClearButton = "2022"
    // 添加到更多按钮
    case launcherMoreButton = "2023"
}
