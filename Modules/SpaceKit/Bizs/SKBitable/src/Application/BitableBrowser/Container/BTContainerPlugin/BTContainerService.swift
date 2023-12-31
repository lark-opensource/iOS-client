//
//  BTContainerService.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/6.
//

import SKFoundation
import SKCommon
import SKInfra

protocol BTContainerService: AnyObject {
    var browserViewController: BitableBrowserViewController? { get }
    
    var model: BTContainerModel { get }
    // 是否是记录分享
    var isIndRecord: Bool { get }
    
    // 是否是记录新建
    var isAddRecord: Bool { get }
    
    // 查找 plugin
    func getPlugin<T: BTContainerBasePlugin>(_ type: T.Type) -> T?
    // 查找 plugin，如果没有创建会自动创建
    func getOrCreatePlugin<T: BTContainerBasePlugin>(_ type: T.Type) -> T
    
    func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?)
    
    func setMainContainerSize(mainContainerSize: CGSize)
    func setBaseHeaderHidden(baseHeaderHidden: Bool, animated: Bool)
    func setBlockCatalogueHidden(blockCatalogueHidden: Bool, animated: Bool)
    func setToolBarHidden(toolBarHidden: Bool, animated: Bool)
    func setHeaderTitleHeight(headerTitleHeight: CGFloat)
    func shouldPopoverDisplay() -> Bool
    func setContainerState(containerState: ContainerState)
    func trackContainerEvent(_ enumEvent: DocsTracker.EventType, params: [String: Any])
    func setContainerTimeout(containerTimeout: Bool)
    func setRecordNoHeader(recordNoHeader: Bool)
    func setIndRecordShow(indRecordShow: Bool)
}
