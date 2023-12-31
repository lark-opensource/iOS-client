//
//  BTContainer+Plugin.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/14.
//

import SKFoundation
import SKCommon
import LarkUIKit
import SKUIKit
import SKBrowser
import UniverseDesignTheme

extension BTContainerService {
    
    /// 背景插件
    /// superview = controller.view
    public var backgroundPlugin: BTContainerBackgroundPlugin {
        get {
            return getOrCreatePlugin(BTContainerBackgroundPlugin.self)
        }
    }
    
    /// 状态栏插件
    /// superview = controller.view
    public var statusBarPlugin: BTContainerStatusBarPlugin {
        get {
            return getOrCreatePlugin(BTContainerStatusBarPlugin.self)
        }
    }
    
    /// TopContainer 插件（导航栏）
    /// superview = controller.view
    public var topContainerPlugin: BTContainerTopContainerPlugin {
        get {
            return getOrCreatePlugin(BTContainerTopContainerPlugin.self)
        }
    }
    
    /// 主容器插件
    /// superview = controller.view
    public var mainContainerPlugin: BTContainerMainContainerPlugin {
        get {
            return getOrCreatePlugin(BTContainerMainContainerPlugin.self)
        }
    }
    
    /// Base 头插件
    /// superview = mainContainerPlugin.view
    public var headerPlugin: BTContainerHeaderPlugin {
        get {
            return getOrCreatePlugin(BTContainerHeaderPlugin.self)
        }
    }
    
    /// Block 目录插件
    /// superview = mainContainerPlugin.view
    public var blockCataloguePlugin: BTContainerBlockCataloguePlugin {
        get {
            return getOrCreatePlugin(BTContainerBlockCataloguePlugin.self)
        }
    }
    
    /// 视图容器插件
    /// superview = mainContainerPlugin.view
    public var viewContainerPlugin: BTContainerViewContainerPlugin {
        get {
            return getOrCreatePlugin(BTContainerViewContainerPlugin.self)
        }
    }
    
    /// 视图目录插件
    /// superview = viewContainerPlugin.view
    public var viewCataloguePlugin: BTContainerViewCataloguePlugin {
        get {
            return getOrCreatePlugin(BTContainerViewCataloguePlugin.self)
        }
    }
    
    /// 工具栏插件
    /// superview = viewContainerPlugin.view
    public var toolBarPlugin: BTContainerToolBarPlugin {
        get {
            return getOrCreatePlugin(BTContainerToolBarPlugin.self)
        }
    }
    
    /// BrowserView 插件
    /// superview = viewContainerPlugin.view
    public var browserViewPlugin: BTContainerBrowserViewPlugin {
        get {
            return getOrCreatePlugin(BTContainerBrowserViewPlugin.self)
        }
    }
    
    /// Onboarding 插件
    public var onboardingPlugin: BTContainerOnboardingPlugin {
        get {
            return getOrCreatePlugin(BTContainerOnboardingPlugin.self)
        }
    }
    
    /// Loading&State 插件
    public var loadingPlugin: BTContainerLoadingPlugin {
        get {
            return getOrCreatePlugin(BTContainerLoadingPlugin.self)
        }
    }
    
    /// FAB 插件
    public var fabPlugin: BTContainerFABPlugin {
        get {
            return getOrCreatePlugin(BTContainerFABPlugin.self)
        }
    }
    
    /// 高级权限
    public var adPermPlugin: BTContainerAdPermPlugin {
        get {
            return getOrCreatePlugin(BTContainerAdPermPlugin.self)
        }
    }
    
    /// 表单视图
    public var formViewPlugin: BTContainerFormViewPlugin {
        get {
            return getOrCreatePlugin(BTContainerFormViewPlugin.self)
        }
    }
    
    /// LinkedDocx
    public var linkedDocxPlugin: BTContainerLinkedDocxPlugin {
        get {
            return getOrCreatePlugin(BTContainerLinkedDocxPlugin.self)
        }
    }
    
    /// 手势处理
    public var gesturePlugin: BTContainerGesturePlugin? {
        get {
            if UserScopeNoChangeFG.LYL.disableAllViewAnimation {
                return nil
            }
            return getOrCreatePlugin(BTContainerGesturePlugin.self)
        }
    }

    // 记录分享
    public var indRecordPlugin: BTContainerIndRecordPlugin {
        get {
            return getOrCreatePlugin(BTContainerIndRecordPlugin.self)
        }
    }
    
    // 快捷记录新建
    public var addRecordPlugin: BTContainerAddRecordPlugin {
        get {
            return getOrCreatePlugin(BTContainerAddRecordPlugin.self)
        }
    }
    
    /// Native视图
    public var nativeRendrePlugin: BTContainerNativeRenderPlugin {
        get {
            return getOrCreatePlugin(BTContainerNativeRenderPlugin.self)
        }
    }
}

extension BTContainer {
    
    func createPlugin<T: BTContainerBasePlugin>(_ type: T.Type) -> T {
        let pluginName = String(reflecting: type)
        if let plugin = plugins[pluginName] as? T {
            return plugin   // 兜底保护，避免重复创建
        }
        DocsLogger.info("BTContainer.createPluginBegin:\(pluginName)")
        let plugin = type.init(status: status)
        plugins[pluginName] = plugin
        plugin.load(service: self)
        plugin.updateStatus(old: nil, new: status, stage: .finalStage)
        DocsLogger.info("BTContainer.createPluginEnd:\(pluginName)")
        return plugin
    }
    
}
