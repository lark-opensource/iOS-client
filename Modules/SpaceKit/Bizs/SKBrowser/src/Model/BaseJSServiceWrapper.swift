//
//  BaseJSServiceWrapper.swift
//  SKBrowser
//
//  Created by lijuyou on 2020/7/14.
//  


import Foundation
import SKCommon

extension BaseJSService {
    var vcTopPadding: CGFloat {
        guard let dbvc = registeredVC as? BrowserViewController, let browserView = dbvc.view else { return 0 }
        let primaryBrowserViewRectInWindow = browserView.convert(browserView.bounds, to: nil)
        return primaryBrowserViewRectInWindow.minY
    }
}

//class BaseJSServiceWrapper: BaseJSService {
//
//    public weak var modelConfig: BrowserModelConfig?
//
//    var vcTopPadding: CGFloat {
//        guard let dbvc = registeredVC as? BrowserViewController, let browserView = dbvc.view else { return 0 }
//        let primaryBrowserViewRectInWindow = browserView.convert(browserView.bounds, to: nil)
//        return primaryBrowserViewRectInWindow.minY
//    }
//
//    init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
//        super.init(ui: ui, model: model, navigator: navigator)
//        modelConfig = model
//    }
//
//    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
//        super.init(ui: ui, model: model, navigator: navigator)
//        modelConfig = model as? BrowserModelConfig
//    }
//
//    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?, resolver: DocsResolver) {
//        super.init(ui: ui, model: model, navigator: navigator, resolver: resolver)
//        modelConfig = model as? BrowserModelConfig
//    }
//}
