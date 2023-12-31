//
//  BrowserViewProtocol.swift
//  SpaceKit
//
//  Created by weidong fu on 2018/12/6.
//

import Foundation
import RxSwift
import SKCommon
import SKUIKit
import SKFoundation
import SpaceInterface

protocol BrowserViewOfflineDelegate: AnyObject {
    func browserView(_ browserView: BrowserView, setTitle title: String, for objToken: String)
    func browserView(_ browserView: BrowserView, setNeedSync needSync: Bool, for objToken: String, type: DocsType)
    func browserView(_ browserView: BrowserView, didSyncWithObjToken objToken: String, type: DocsType)
}

public protocol BrowserViewDelegate: AnyObject {
    func browserView(_ browserView: BrowserView, shouldShowBanner item: BannerItem)
    func browserView(_ browserView: BrowserView, shouldHideBanner item: BannerItem)
    func browserView(_ browserView: BrowserView, shouldChangeBannerInvisible toHidden: Bool)
    func browserView(_ browserView: BrowserView, shouldChangeCompleteButtonInvisible toHidden: Bool)
    func browserView(_ browserView: BrowserView, shouldChangeCatalogButtonState isOpen: Bool)
    func browserVIewIPadCatalogState(_ browserView: BrowserView) -> Bool
    func browserViewTitleBarCoverHeight(_ browserView: BrowserView) -> CGFloat

    func browserView(_ browserView: BrowserView, setTopContainerState state: TopContainerState)

    func browserViewController() -> BaseViewController
    func browserViewShouldToggleEditMode(_ browserView: BrowserView)

    func browserView(_ browserView: BrowserView, markFeedCardShortcut isAdd: Bool, success: SKMarkFeedSuccess?, failure: SKMarkFeedFailure?)
    func browserView(_ browserView: BrowserView, needShowFeedCardShortcut channelType: Int) -> Bool
    func browserViewIsFeedCardShortcut(_ browserView: BrowserView) -> Bool
    func browserView(_ browserView: BrowserView, enableFullscreenScrolling enable: Bool)

    func browserView(_ browserView: BrowserView, shouldChange orientation: UIInterfaceOrientation)
    func browserViewCurrentOrientation(_ browserView: BrowserView) -> UIInterfaceOrientation

    func browserViewCustomTCDisplayConfig(_ browserView: BrowserView) -> CustomTopContainerDisplayConfig?

    func browserViewHandleDeleteEvent(_ browserView: BrowserView)
    func browserViewHandleDeleteRecoverEvent(_ browserView: BrowserView)
    func browserViewHandleKeyDeleteEvent(_ browserView: BrowserView)
    func browserViewHandleNotFoundEvent(_ browserView: BrowserView)

    func browserViewDidUpdateDocsInfo(_ browserView: BrowserView)
    func browserViewDidUpdateRealTokenAndType(info: DocsInfo)
    func noPermissionNotifyEvent(_ browserView: BrowserView)
    func canShowDeleteVersionEmptyView(_ show: Bool)
    func setCatalogueBanner(visible: Bool)
    func setCatalogueBanner(catalogueBannerData: SKCatalogueBannerData?, callback: SKCatalogueBannerViewCallback?)
    
    func browserViewDidUpdateDocName(_ browserView: BrowserView, docName: String?)
    // 将要显示无权限页面
    func browserViewWillShowNoPermissionView(_ browserView: BrowserView)
    // 承载权限申请界面的容器
    func browserPermissionHostView(_ browserView: BrowserView) -> UIView?
    // 承载失败页面界面的容器
    func browserStateHostConfig(_ browserView: BrowserView) -> CustomStatusConfig?
    // Browser 显示自定义loading，直接返回false就不变
    func browserViewShowCustomLoading(_ browserView: BrowserView) -> Bool
    
    func browserViewShowBitableAdvancedPermissionsSettingVC(data: BitableBridgeData, listener: BitableAdPermissionSettingListener?)
    func browserView(_ browserView: BrowserView, setKeyCommandsWith info: [UIKeyCommand: String])
    func browserViewHandleRefreshEvent(_ browserView: BrowserView)
}

protocol DocsBrowserShareDelegate: AnyObject {
    func browserViewRequestShareAccessory(_ browserView: BrowserView) -> UIView?
}

public protocol BrowserViewNavigationItemObserver: AnyObject {
    func titleDidChange(from oldValue: String?, to newValue: String?)
    func trailingButtonBarItemsDidChange(from oldValue: [SKBarButtonItem], to newValue: [SKBarButtonItem])
    func fullScreenButtonBarItemDidChangeState(isEnable: Bool)
}
