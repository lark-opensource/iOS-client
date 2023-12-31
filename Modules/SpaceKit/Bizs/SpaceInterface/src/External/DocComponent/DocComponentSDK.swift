//
//  DocComponentSDK.swift
//  SpaceInterface
//
//  Created by lijuyou on 2023/5/18.
//  


import Foundation

/// DocComponentSDK，业务方可以通过LarkContainer获取实例
public protocol DocComponentSDK {
    
    /// 创建DocComponentAPI实例
    func create(url: URL, config: DocComponentConfig) -> DocComponentAPI?
}


public struct DocComponentConfig {
    
    /// 接入模块名称
    public let module: String
    
    /// 场景ID，统一分配
    public let sceneID: String
    
    /// 页面配置
    public let pageConfig: DocComponentPageConfig?
    
    /// setting配置 https://cloud.bytedance.net/appSettings-v2/detail/config/167186/detail/status
    public let settingConfig: [String: Any]?
    
    public init(module: String,
                sceneID: String,
                pageConfig: DocComponentPageConfig? = nil,
                settingConfig: [String: Any]? = nil) {
        self.module = module
        self.sceneID = sceneID
        self.pageConfig = pageConfig
        self.settingConfig = settingConfig
    }
}

/// 页面配置
public struct DocComponentPageConfig {
    /// 导航栏显示成关闭按钮
    public let showCloseButton: Bool
    public init(showCloseButton: Bool) {
        self.showCloseButton = showCloseButton
    }
}
