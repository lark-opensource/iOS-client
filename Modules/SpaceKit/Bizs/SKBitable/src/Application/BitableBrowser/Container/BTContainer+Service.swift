//
//  BTContainer+Service.swift
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

extension BTContainer: BTContainerService {
    
    var isIndRecord: Bool {
        browserViewController?.isIndRecord ?? false
    }
    
    var isAddRecord: Bool {
        browserViewController?.isAddRecord ?? false
    }
    
    var browserViewController: BitableBrowserViewController? {
        return delegate?.browserViewController
    }
    
    func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?) {
        DocsLogger.info("BTContainerPlugin.callFunction:\(function.rawValue)")
        delegate?.callFunction(function, params: params, completion: completion)
    }
    
    // 查找 plugin，如果没有创建不会自动创建
    func getPlugin<T: BTContainerBasePlugin>(_ type: T.Type) -> T? {
        let pluginName = String(reflecting: type)
        return plugins[pluginName] as? T
    }
    
    // 查找 plugin，如果没有创建会自动创建
    func getOrCreatePlugin<T: BTContainerBasePlugin>(_ type: T.Type) -> T {
        getPlugin(type) ?? createPlugin(type)
    }
    
    func shouldPopoverDisplay() -> Bool {
        guard SKDisplay.pad else {
            return false
        }
        guard let browserViewController = delegate?.browserViewController else {
            DocsLogger.btError("browserViewController is nil")
            return false
        }
        return browserViewController.isMyWindowRegularSize()
    }

    func trackContainerEvent(_ enumEvent: DocsTracker.EventType, params: [String: Any]) {
        let hostDocInfo = delegate?.browserViewController?.docsInfo
        let baseData = BTBaseData(baseId: hostDocInfo?.token ?? "", tableId: "", viewId: "")
        var trackParams: [String: Any] = BTEventParamsGenerator.createCommonParams(by: hostDocInfo, baseData: baseData)
        trackParams.merge(other: params)
        
        DocsTracker.newLog(enumEvent: enumEvent, parameters: trackParams)
    }
}
