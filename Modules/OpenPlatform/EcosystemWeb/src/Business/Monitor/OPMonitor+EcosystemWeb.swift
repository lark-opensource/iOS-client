//
//  OPMonitor+WebBrowser.swift
//  EcosystemWeb
//
//  Created by yinyuan on 2022/4/27.
//

import ECOInfra
import ECOProbe
import LarkWebViewContainer
import WebBrowser

public extension OPMonitor {
    
    /// 创建OPMonitor实例
    /// - Parameters:
    ///   - event: WebContainerMonitorEvent事件
    ///   - code: OPMonitorCode
    convenience init(event: WebContainerMonitorEvent,
                     code: OPMonitorCode?,
                     browser: WebBrowser? = nil) {
        self.init(service: nil, name: event.rawValue, code: code)
        if let browser = browser {
            _ = self.setWebBrowser(browser)
        }
    }

    /// 创建OPMonitor实例
    /// - Parameter event: WebContainerMonitorEvent事件
    convenience init(_ event: WebContainerMonitorEvent,
                     browser: WebBrowser? = nil) {
        self.init(event: event, code: nil, browser: browser)
    }

    /// 添加一个自定义的 Key-Value，value 为枚举/分类类型（可分类筛选)
    /// 重复设置相同key会覆盖
    func addCategoryValue(_ eventKey: WebContainerMonitorEventKey, _ value: Any?) -> OPMonitor {
        addCategoryValue(eventKey.rawValue, value)
    }

    /// 添加一个自定义的 Key-Value，value 为枚举/分类类型（可分类筛选)
    /// 重复设置相同key会覆盖
    func addCategoryValueIfNotNull(_ eventKey: WebContainerMonitorEventKey, _ value: Any?) -> OPMonitor {
        if let value = value {
            addCategoryValue(eventKey.rawValue, value)
        }
        return self
    }
    
    func setWebBrowser(_ browser: WebBrowser?) -> OPMonitor {
        if let browser = browser {
            self.tracing(browser.getTrace())
                .setWebAppID(browser.appInfoForCurrentWebpage?.id)
                .setWebURL(browser.browserURL)
                .setWebBizType(browser.configuration.webBizType)
                .setWebBrowserScene(browser.configuration.scene)
                .setWebBrowserOffline(browser.configuration.offline)
        }
        return self
    }
    
    public func setWebURL(_ url: URL?) -> OPMonitor {
        if let url = url {
            self
                .addCategoryValueIfNotNull(.url, url.safeURLString)
                .addCategoryValueIfNotNull(.host, url.host)
                .addCategoryValueIfNotNull(.path, url.path)
        }
        return self
    }
    
    public func setWebAppID(_ appID: String?) -> OPMonitor {
        self.addCategoryValueIfNotNull(.appID, appID)
        return self
    }
    
    public func setWebBizType(_ bizType: LarkWebViewBizType?) -> OPMonitor {
        self.addCategoryValueIfNotNull(.biz, bizType?.rawValue)
        return self
    }
    
    public func setBrowserDuration(_ duration: TimeInterval?) -> OPMonitor {
        self.addCategoryValueIfNotNull(.duration, duration)
        return self
    }
    
    
    public func setBrowserStage(_ stage: WebBrowser.BroswerProcessStage) -> OPMonitor {
        self.addCategoryValueIfNotNull(.stage, stage.rawValue)
        return self
    }
    
    public func setWebBrowserScene(_ scene: WebBrowserScene) -> OPMonitor {
        self.addCategoryValueIfNotNull(.scene, scene.rawValue)
        return self
    }
    
    public func setWebBrowserOffline(_ offline: Bool) -> OPMonitor {
        self.addCategoryValueIfNotNull(.offline, offline)
        return self
    }
}
