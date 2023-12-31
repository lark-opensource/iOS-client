//
//  MonitorUtils.swift
//  LarkHelpdesk
//
//  Created by yinyuan on 2021/8/31.
//

import Foundation
import ECOProbe

enum HelpDeskMonitorEvent: String {
    
    typealias RawValue = String
    
    /// Bar 开始加载
    case open_banner_load_start
    /// Bar 开始完成（成功/失败）
    case open_banner_load_result
    /// Bar Button 点击
    case open_banner_button_action_start
    /// Bar Button Action执行完成（成功/失败/取消）
    case open_banner_button_action_result
    /// Bar 开始请求数据
    case open_banner_pull_start
    /// Bar 开始请求完成（成功/失败）
    case open_banner_pull_result
    /// Bar Button 开始 post 数据
    case open_banner_button_post_start
    /// Bar Button 开始 post 数据完成（成功/失败）
    case open_banner_button_post_result
    /// Bar Button 开始跳转页面
    case open_banner_button_jump_start
    /// Bar Button 跳转页面完成(成功/失败)
    case open_banner_button_jump_result
    
}

extension OPMonitor {
    
    func setResultType(with error: Error?) -> OPMonitor {
        if error == nil {
            setResultTypeSuccess()
        } else {
            setResultTypeFail()
        }
        setError(error)
        if let error = error as? HelpDeskError {
            error.hasReported = true
        }
        return self
    }
        
    func setBannerResource(_ resource: BannerResource?) -> OPMonitor {
        addCategoryValue("resource_id", resource?.resourceID)
        addCategoryValue("resource_type", resource?.resourceType)
        return self
    }
    
    func setBannerResponse(_ response: BannerResponse?) -> OPMonitor {
        addCategoryValue("target_id", response?.targetID)
        addCategoryValue("target_type", response?.targetType.rawValue)
        addCategoryValue("container_tag", response?.containerTag?.rawValue)
        return self
    }
}
