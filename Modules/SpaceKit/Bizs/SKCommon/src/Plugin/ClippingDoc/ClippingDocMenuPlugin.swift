//
//  ClippingDocMenuPlugin.swift
//  SKCommon
//
//  Created by huayufan on 2022/6/24.
//  


import LarkUIKit
import WebBrowser
import SKFoundation
import SKResource
import LarkGuide
import UniverseDesignIcon
import LarkContainer

public final class ClippingDocMenuPlugin: MenuPlugin {
    
    
    private let menuContext: WebBrowserMenuContext
    
    private let copyLinkIdentifier = "clippingDoc"
    
    static let onboardingKey = "ccm_clip_red_dot"
    
    public static var enableMenuContexts: [MenuContext.Type] {
        [WebBrowserMenuContext.self]
    }

    public static var pluginID: String {
        "ClippingDocMenuPlugin"
    }
    
    let priority: Float = 7

    public required init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        DocsLogger.info("init", component: LogComponents.clippingDoc)
        guard let webMenuContext = menuContext as? WebBrowserMenuContext else {
               return nil
        }
        self.menuContext = webMenuContext
    }
    
    public func pluginDidLoad(handler: MenuPluginOperationHandler) {
        let fgOpen = LKFeatureGating.clipDocEnable
        DocsLogger.info("pluginDidLoad fg:\(fgOpen)", component: LogComponents.clippingDoc)
        guard fgOpen else {
            return
        }
        if let browser = menuContext.webBrowser {
            let showGuide = shouldShowRedDot()
            let badgeNumber: UInt = showGuide ? 1 : 0
            let icon = UDIcon.feishuclipOutlined
            let imageModel = MenuItemImageModel(normalForIPhonePanel: icon, normalForIPadPopover: icon)
            let item = MenuItemModel(title: BundleI18n.SKResource.LarkCCM_Clip_CliptoDoc,
                                     imageModel: imageModel,
                                     itemIdentifier: copyLinkIdentifier,
                                     badgeNumber: badgeNumber,
                                     autoClosePanelWhenClick: true,
                                     disable: false,
                                     itemPriority: priority,
                                     action: { [weak self, weak browser] in
                guard let self = self, let browser = browser else { return }
                DocsLogger.info("click \($0)", component: LogComponents.clippingDoc)
                let browseHandler = ClippingBridgeFactory.generateBridgeHandler(webBrowser: browser)
                browseHandler.register()
                browseHandler.injectScript()
                self.didShowedRedDot()
            })
            handler.updateItemModels(for: [item])
        } else {
            DocsLogger.error("setup fail,webBrowser is nil", component: LogComponents.clippingDoc)
        }
    }
}

// MARK: - 红点
extension ClippingDocMenuPlugin {

    private func shouldShowRedDot() -> Bool {
        guard let newGuideService = implicitResolver?.resolve(NewGuideService.self) else {
            DocsLogger.error("has no NewGuideService, please contact ug team", component: LogComponents.clippingDoc)
            return false
        }
        return newGuideService.checkShouldShowGuide(key: Self.onboardingKey)
    }

    private func didShowedRedDot() {
        guard let newGuideService = implicitResolver?.resolve(NewGuideService.self) else {
            DocsLogger.error("has no NewGuideService, please contact ug team", component: LogComponents.clippingDoc)
            return
        }
        newGuideService.didShowedGuide(guideKey: Self.onboardingKey)
    }
    
}
