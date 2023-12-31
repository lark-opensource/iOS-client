//
//  WebBrowser+CloseSelf.swift
//  WebBrowser
//
//  Created by jiangzhongping on 2022/11/22.
//

import Foundation
import LarkSetting
import ECOProbe

public enum WebCloseSelfScene: String {
    case open_schema
    case window_open
    case url_redirect
}

extension WebBrowser {
    
    ///是否 在打开新容器前，关闭自身容器
    public func canCloseSelf(with url: URL?, scene: WebCloseSelfScene) -> Bool {
        guard let url = url else {
            return false
        }
        
        var featureGatingValue = ""
        switch (scene) {
        case .open_schema:
            featureGatingValue = "openplatform.webbrowser.openschema.closeself.enable"
        case .window_open:
            featureGatingValue = "openplatform.webbrowser.windowopen.closeself.enable"
        case .url_redirect:
            featureGatingValue = "openplatform.webbrowser.urlredirect.closeself.enable"
        }
        
        if featureGatingValue.count <= 0 {
            return false
        }
        
        let closeSelfEnable = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral:featureGatingValue))// user:global
        var closeSelf = false
        if let closeSelfWindowString = url.lf.queryDictionary["lk_close_self_window"] as? NSString {
            closeSelf = closeSelfEnable && closeSelfWindowString.boolValue
            
            if WebMetaNavigationBarExtensionItem.isURLCustomQueryMonitorEnabled() {
                let appId = configuration.appId ?? currrentWebpageAppID()
                OPMonitor("openplatform_web_container_URLCustomQuery")
                    .addCategoryValue("name", "lk_close_self_window")
                    .addCategoryValue("content", closeSelfWindowString)
                    .addCategoryValue("url", url.safeURLString)
                    .addCategoryValue("appId", appId)
                    .setPlatform([.tea, .slardar])
                    .tracing(getTrace())
                    .flush()
            }
        }
        return closeSelf
    }
    
    public func closeSelfMonitor(with url: URL?, scene: WebCloseSelfScene) {
        
        guard let url = url else {
            return
        }
        let traceId = self.getTrace().traceId ?? ""
        
        OPMonitor("wb_container_redirect_closeself_action")
            .addCategoryValue("url", url.safeURLString ?? "")
            .addCategoryValue("type", scene.rawValue ?? "")
            .addCategoryValue("trace_Id", traceId).flush()
    }
    
    public func delayRemoveSelfInViewControllers() {
        //适当延迟remove操作，即时执行 或 在completionBlock执行删除失败复现概率大
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.removeSelfInViewControllers()
        }
    }
        
    private func removeSelfInViewControllers() {
        guard let viewControllers = self.navigationController?.viewControllers else {
            Self.logger.info("controllers are empty, don't remove")
            return
        }
        
        let count = viewControllers.count
        if count <= 2 {
            Self.logger.info("controller’s count is less than or equal to 2, don't remove")
            return
        }
            
        let viewControllersCopy = NSMutableArray.init(array: viewControllers)
        Self.logger.info("before remove, controller’s count is \(viewControllersCopy.count)")
    
        var hasUpdated = false
        for item in viewControllersCopy {
            if let viewController = item as? UIViewController {
                if viewController == self {
                    let index = viewControllersCopy.index(of: self)
                    if index > 0 && index < count - 1 {
                        Self.logger.info("remove controller, index is \(index), count:\(count)")
                        viewControllersCopy.remove(viewController)
                        hasUpdated = true
                    } else {
                        Self.logger.info("can't remove controller, index is \(index), count:\(count)")
                    }
                    break
                }
            }
        }
        
        if hasUpdated, let newViewControllers = viewControllersCopy as? [UIViewController] {
            self.navigationController?.viewControllers = newViewControllers
            Self.logger.info("after remove, controller’s count is \(viewControllersCopy.count)")
        } else {
            Self.logger.info("nothing to remove, hasUpdated: \(hasUpdated)")
        }
    }
}
