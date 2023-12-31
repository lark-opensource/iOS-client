//
//  BaseJSService.swift
//  SpaceKit
//
//  Created by weidong fu on 2018/12/7.
//

import Foundation
import SKUIKit
import SKFoundation
import SKInfra

open class BaseJSService {
    public weak var ui: BrowserUIConfig?
    public weak var model: BrowserModelConfig?
    public weak var navigator: BrowserNavigator?

    public init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        self.ui = ui
        self.model = model
        self.navigator = navigator
    }

    public init() {
    }

    @available(*, deprecated, message: "Disambiguate using hostDocsInfo - PermissionUpdate")
    public var docsInfo: DocsInfo? {
        self.model?.browserInfo.docsInfo
    }

    public var hostDocsInfo: DocsInfo? {
        self.model?.hostBrowserInfo.docsInfo
    }
    
    public var registeredVC: UIViewController? {
        return ui?.hostView.affiliatedViewController
    }
    
    public var editorIdentity: String {
        model?.jsEngine.editorIdentity ?? ""
    }
    
    /// brows 的 rootTracing
    public var browserTrace: SKTracableProtocol? {
        return self.navigator?.currentBrowserVC as? SKTracableProtocol
    }
    
    public var isInVideoConference: Bool {
        self.model?.vcFollowDelegate != nil
    }
    
    public var isDocComponent: Bool {
        self.model?.docComponentDelegate != nil
    }
    
    public var docComponentHost: DocComponentHost? {
        self.navigator?.currentBrowserVC as? DocComponentHost
    }
    
}

extension BaseJSService {
    
    /// 根据 BrowserVC 来获取顶层控制器
    public func topMostOfBrowserVC() -> UIViewController? {
        let browserVC = self.navigator?.currentBrowserVC
        if model?.hostBrowserInfo.isInVideoConference ?? false {
           //需要这样取的是因为适配 meego https://meego.feishu.cn/larksuite/issue/detail/4180327?parentUrl=%2Flarksuite%2FissueView%2FSBg67fTcn
            return UIViewController.docs.topMostWhichFiltedUnmatchVC(of: browserVC)
        } else {
            return UIViewController.docs.topMost(of: browserVC)
        }
    }
    
    public func topMostOfBrowserVCWithoutDismissing(completion: @escaping (UIViewController?) -> Void) {
        guard let topMost = topMostOfBrowserVC() else {
            completion(nil)
            return
        }
        guard topMost.isBeingDismissed ||
                topMost.isMovingFromParent ||
                topMost.navigationController?.isBeingDismissed ?? false else {
            completion(topMost)
            return
        }
        (topMost.navigationController ?? topMost).dismiss(animated: false, completion: { [weak self] in
            completion(self?.topMostOfBrowserVC())
        })
    }
}
