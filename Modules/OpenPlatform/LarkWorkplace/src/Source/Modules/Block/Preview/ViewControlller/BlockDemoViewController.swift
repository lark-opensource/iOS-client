//
//  BlockDemoViewController.swift
//  LarkWorkplace
//
//  Created by chenziyi on 2021/8/2.
//

import EENavigator
import OPSDK
import LarkUIKit
import LarkTab
import LKCommonsLogging
import LarkOPInterface
import LarkAppLinkSDK
import UniverseDesignIcon
import UIKit
import LarkNavigator
import LarkWorkplaceModel

struct OpenDemoBlockParams {
    var appId: String = ""
    var blockTypeId: String = ""
    var blockId: String = ""
    var title: String = ""
    var sourceData: [String: Any] = [:]
    var sourceMeta: [String: Any] = [:]
}

struct BlockDemoParams {
    var item: WPAppItem
    var title: String = ""
    var sourceData: [String: Any] = [:]
    var sourceMeta: [String: Any] = [:]
}

final class BlockDemoViewController: BaseUIViewController {
    private let navigator: UserNavigator
    private let params: [String: Any]

    /// 页面默认先选中component
    private var selectedTab = "component"
    private var isAnotherBlockInit = false

    /// tabbaritem的图片
    private let componentImg = Resources.demo_component.withRenderingMode(.alwaysOriginal)
    private let componentSelectedImg = Resources.demo_component_highlighted.withRenderingMode(.alwaysOriginal)
    private let apiImg = Resources.demo_api.withRenderingMode(.alwaysOriginal)
    private let apiSelectedImg = Resources.demo_api_highlighted.withRenderingMode(.alwaysOriginal)

    /// 组件列表页的tabbaritem
    private lazy var componentTabBarItem: UITabBarItem = {
        let componentBarItem = UITabBarItem()
        componentBarItem.title = BundleI18n.LarkWorkplace.OpenPlatform_Block_ComponentsTtl
        componentBarItem.image = componentImg
        componentBarItem.selectedImage = componentSelectedImg
        componentBarItem.tag = 0

        componentBarItem.setTitleTextAttributes(
            // swiftlint:disable init_font_with_token
            [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)],
            // swiftlint:enable init_font_with_token
            for: .normal
        )

        return componentBarItem
    }()

    /// api列表页的tabbaritem
    private lazy var apiTabBarItem: UITabBarItem = {
        let apiBarItem = UITabBarItem()
        apiBarItem.title = BundleI18n.LarkWorkplace.OpenPlatform_Block_ApiTtl
        apiBarItem.image = apiImg
        apiBarItem.selectedImage = apiSelectedImg
        apiBarItem.tag = 1

        apiBarItem.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)], for: .normal)

        return apiBarItem
    }()

    /// tabbar的VC
    // swiftlint:disable closure_body_length
    private lazy var demoTabBarVC: UITabBarController = {
        let demoTabBarVC = UITabBarController()

        let blockInfo = WPBlockInfo(blockId: "", blockTypeId: params["blockTypeId"] as? String ?? "")
        let componentAppItem = WPAppItem.buildBlockDemoItem(
            appId: params["appId"] as? String ?? "", blockInfo: blockInfo
        )
        let apiAppItem = WPAppItem.buildBlockDemoItem(
            appId: params["appId"] as? String ?? "", blockInfo: blockInfo
        )

        let sourceData = params["sourceData"] as? [String: Any] ?? [:]
        selectedTab = sourceData["tab"] as? String ?? "component"
        let componentDemoParams = BlockDemoParams(item: componentAppItem, title: "component", sourceData: sourceData)
        let apiDemoParams = BlockDemoParams(
            item: apiAppItem,
            title: "api",
            sourceData: params["sourceData"] as? [String: Any] ?? [:]
        )

        var tabVCs: [UIViewController] = []

        /// 组件列表页
        let componentListBody = BlockDemoListBody(params: componentDemoParams)
        if let componentVC = navigator.response(for: componentListBody).resource as? BlockDemoListViewController {
            componentVC.tabBarItem = self.componentTabBarItem
            tabVCs.append(componentVC)
        }

        /// API列表页
        let apiListBody = BlockDemoListBody(params: apiDemoParams)
        if let apiVC = navigator.response(for: apiListBody).resource as? BlockDemoListViewController {
            apiVC.tabBarItem = self.apiTabBarItem
            tabVCs.append(apiVC)
        }

        demoTabBarVC.setViewControllers(tabVCs, animated: false)
        demoTabBarVC.selectedIndex = tabToIndex()
        demoTabBarVC.tabBar.backgroundColor = UIColor.dynamic(
            light: UIColor.ud.N00.withAlphaComponent(0.9),
            dark: UIColor.ud.bgBody
        )

        return demoTabBarVC
    }()
    // swiftlint:enable closure_body_length

    /// navbar的标题
    private let navTitleLabel: UILabel = {
        let navTitleLabel = UILabel()
        navTitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        navTitleLabel.text = BundleI18n.LarkWorkplace.OpenPlatform_Block_BlockSampleTtl
        navTitleLabel.textAlignment = .center
        return navTitleLabel
    }()

    init(navigator: UserNavigator, params: [String: Any]) {
        self.navigator = navigator
        self.params = params
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(demoTabBarVC)
        view.addSubview(demoTabBarVC.view)
        demoTabBarVC.didMove(toParent: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavItems()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        demoTabBarVC.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func tabToIndex() -> Int {
        if selectedTab == "api" {
            return 1
        } else {
            return 0
        }
    }

    /// navbaritem的设置
    private func setupNavItems() {
        let navBarCloseBtn = UIBarButtonItem(
            image: Resources.close,
            style: .plain,
            target: self,
            action: #selector(tapCloseButton)
        )
        navigationItem.rightBarButtonItem = navBarCloseBtn
        navigationItem.setHidesBackButton(true, animated: false)
        navigationItem.leftBarButtonItem = nil
        navigationItem.titleView = navTitleLabel
    }

    @objc
    private func tapCloseButton() {
        navigator.pop(from: self, animated: true, completion: nil)
    }
}
