//
//  ShareModel.swift
//  SKCommon
//
//  Created by lijuyou on 2021/1/18.
//  


import Foundation

// From ShareViewControllerV2.swift
public protocol ShareRouterAbility: AnyObject {
    func shareRouterToOtherApp(_ vc: UIViewController) -> Bool
}

public extension ShareRouterAbility {
    func shareRouterToOtherApp(_ vc: UIViewController) -> Bool {
        return false
    }
}
/// 分享来源
public enum ShareSource: String {
    /// 列表左滑
    case list = "list_slide"
    /// 文档内
    case content = "docs_page"
    /// 其他
    case other = "other"
    /// 未知
    case unkonwn = "unkonwn"
    /// 自定义模板
    case diyTemplate = "diy_template"
    /// 网格
    case grid = "grid"
}

public protocol SharePanelConfigInfoProtocol {
    var disables: [String] { get set }
    var badges: [String] { get set }
}

public protocol ShareViewControllerDelegate: AnyObject {
    func requestExportLongImage(controller: UIViewController)
    func requestSlideExport(controller: UIViewController)
    func requestDisplayShareViewAccessory() -> UIView?
    func requestExist(controller: UIViewController)
    func shouldDisplaySnapShotItem() -> Bool
    func shouldDisplaySlideExport() -> Bool
    func sharePanelConfigInfo() -> SharePanelConfigInfoProtocol?
    func requestShareToLarkServiceFromViewController() -> UIViewController?
    func onRemindNotificationViewClick(
        controller: UIViewController,
        shareToken: String
    )
    func onBitableAdPermPanelClick(_ data: BitableBridgeData)
    func didShareViewClicked(assistType: ShareAssistType)
}

public extension ShareViewControllerDelegate {
    func requestExportLongImage(controller: UIViewController) {}
    func requestSlideExport(controller: UIViewController) {}
    func requestDisplayShareViewAccessory() -> UIView? {
        return nil
    }
    func requestExist(controller: UIViewController) {}
    func shouldDisplaySnapShotItem() -> Bool {
        return false
    }
    func shouldDisplaySlideExport() -> Bool {
        return false
    }
    func sharePanelConfigInfo() -> SharePanelConfigInfoProtocol? {
        return nil
    }
    func requestShareToLarkServiceFromViewController() -> UIViewController? {
        return nil
    }
    func onRemindNotificationViewClick(
        controller: UIViewController,
        shareToken: String
    ) {
    }
    
    func onBitableAdPermPanelClick(_ data: BitableBridgeData) {}
    
    func didShareViewClicked(assistType: ShareAssistType) {}
}

enum ShareViewControllerState {
    case fetchData
    case setData
    case error
}
