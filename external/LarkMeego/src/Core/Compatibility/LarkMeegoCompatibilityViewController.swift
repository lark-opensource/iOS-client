//  LarkMeegoCompatibilityViewController.swift
//  LarkMeego
//
//  Created by qsc on 2023/8/7.
//

import Foundation
import UIKit
import EENavigator
import UniverseDesignEmpty
import UniverseDesignButton
import LKCommonsLogging
import LarkContainer
import LarkUIKit
import LarkExtensions
import LarkSetting
import LarkMeegoLogger

class LarkMeegoCompatiblityViewController: BaseUIViewController {

    static let forceWebviewQueryKey = "force_webview"

    @ProviderSetting
    private var meegoLinkConfig: MeegoLinkConfig?

    private lazy var upgradeTipView: UDEmptyView = {
        let descriptionText = BundleI18n.LarkMeego.Meego_Shared_MobileCommon_UnableToViewPleaseUpdateApp_EmptyState()
        let description = UDEmptyConfig.Description(descriptionText: descriptionText)
        let config = UDEmptyConfig(title: nil, description: description, type: .upgraded)
        let view = UDEmptyView(config: config)
        return view
    }()

    private lazy var openInWebviewButton: UIButton = {
        let config = UDButtonUIConifg.textBlue
        let button = UDButton(config)
        button.setTitle(BundleI18n.LarkMeego.Meego_Shared_Mobile_MeegoOpenWebPage, for: .normal)

        return button
    }()

    private let req: EENavigator.Request

    public init(req: EENavigator.Request) {
        self.req = req
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addUpgradeTipView()
        addEnterWebIfNeed()
    }

    private func addUpgradeTipView() {
        view.addSubview(upgradeTipView)
        upgradeTipView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func addEnterWebIfNeed() {
        guard let meegoLinkConfig = meegoLinkConfig else {
            return
        }

        if !meegoLinkConfig.isFlutterOnly(url: self.req.url) {
            view.addSubview(openInWebviewButton)
            openInWebviewButton.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(self.view.snp.bottom).inset(172)
            }

            openInWebviewButton.addTarget(self, action: #selector(openWebview), for: .touchUpInside)
        }
    }

    @objc
    private func openWebview() {

        let forceWebviewUrl = self.req.url.append(parameters: [Self.forceWebviewQueryKey: "1"])
        MeegoLogger.info("force open meego in webview! url: \(forceWebviewUrl)")

        /// 需要使用 forcePush
        /// 原因：Router 使用 url.identifier 作为页面唯一性判断
        /// 打开网页时，给原 url 新增了 force_webview 参数，但是路由框架在 end(resource) 时消费 url 不看 query 和 fragment
        /// 导致 Router 认为新 push 的页面与当前页面相同而中止路由
        Container.shared.getCurrentUserResolver().navigator.push(forceWebviewUrl,
                                                                 context: self.req.context,
                                                                 from: self,
                                                                 forcePush: true) { _, _ in
            /// push 后从路由栈中移除此兜底页
            self.navigationController?.viewControllers.lf_remove(object: self)
            MeegoLogger.info("removed MeegoCompatibilityView from view stack")
        }

    }
}
