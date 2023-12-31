//
//  WebContainerMonitorEvent.swift
//  EcosystemWeb
//
//  Created by yinyuan on 2022/4/27.
//

import Foundation

/// 容器级别的埋点事件 https://bytedance.feishu.cn/docx/doxcne4RFawV8ZLuUH1JeX2Bnbc
public enum WebContainerMonitorEvent: String {
    
    /// 外部业务打开容器前上报
    case containerStartHandle = "wb_container_start_handle"
    
    /// 网页容器首次加载url之前出现的失败
    case containerLoadFailed = "wb_container_load_failed"
    
    /// 容器创建完成后上报（webview已经创建）
    case containerCreated = "wb_container_created"
    
    /// 容器开始首次加载url
    case containerFirstLoadUrl = "wb_container_first_load_url"
    
    /// 容器页面展示
    case containerAppear = "wb_container_appear"
    
    /// 容器页面消失
    case containerDisappear = "wb_container_disappear"
    
    /// 容器销毁
    case containerDestroyed = "wb_container_destroyed"
    
    /// 容器预请求耗时
    case containerLoadPrepareDuration = "wb_load_prepare_duration"
    
    /// H5网页应用启动(上报到tea平台)
    case h5ApplicationLaunch = "h5application_launch"
}

public enum WebContainerMonitorEventKey: String {
    /// appID
    case appID = "app_id"
    /// 所属业务
    case biz = "biz_type"
    /// 页面url，需加密
    case url = "url"
    /// 页面url.host，目前只针对网页容器打印，已有安全同学确认
    case host = "host"
    /// 页面url.path，目前只针对网页容器打印，已有安全同学确认
    case path = "path"
    /// 容器生命时长
    case duration = "broswer_duration"
    /// 容器状态
    case stage = "stage"
    /// 容器startHandle的场景
    case scene = "scene"
    /// 容器是否支持离线应用
    case offline = "offline"
}

