//
//  DocsOpHistoryViewController.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/11/17.
//  

import SKFoundation
import LarkUIKit
import UIKit
import EENavigator
import SKUIKit
import SpaceInterface

public final class DocsOpHistoryViewController: LynxBaseViewController {
    
    public var supportOrientations: UIInterfaceOrientationMask = .portrait
    
    private var lastSendSize: CGSize?
    
    public init(token: String, type: DocsType) {
        super.init(nibName: nil, bundle: nil)
        initialProperties = [
            "token": token,
            "obj_type": type.rawValue
        ]
        templateRelativePath = "pages/doc-operation-history/template.js"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        registerHandlers()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let preSize = lastSendSize ?? .zero
        let size = calculateSizeForLynxView()
        if abs(preSize.width - size.width) > 0.1 ||
           abs(preSize.height - size.height) > 0.1 {
            let event = GlobalEventEmiter.Event(
                name: "ccm-pagesize-change",
                params: ["pageWidth": size.width, "pageHeight": size.height]
            )
            self.globalEventEmiter.send(event: event, needCache: true)
            lynxView?.triggerLayout()
            lastSendSize = size
        }
    }
    
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }

    public static func show(token: String, type: DocsType, from: UIViewController) {
        let vc = DocsOpHistoryViewController(token: token, type: type)
        let nav = LkNavigationController(rootViewController: vc)
        Navigator.shared.present(nav, from: from)
    }
    
    private func registerHandlers() {
        // 跳转个人主页
        PageOpenBridgeHandler.register(key: "jump_user_profile") { (url, params, vc) -> Bool in
            guard let components = URLComponents(string: url.absoluteString) else { return false }
            guard components.scheme == "lark", components.host == "ccm.bytedance.net", components.path == "/ccm/profile_main",
                let userID = params["id"] as? String else {
                return false
            }
            LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) { [weak self] in
                guard self != nil else { return }
                HostAppBridge.shared.call(ShowUserProfileService(userId: userID, fromVC: vc))
            }
            return true
        }
    }
    
    private func calculateSizeForLynxView() -> CGSize {
        var size = self.view.bounds.size
        size.height -= self.statusBar.frame.size.height
        return size
    }
}
