//
//  BlockDemoDetailViewController.swift
//  LarkWorkplace
//
//  Created by chenziyi on 2021/8/11.
//

import EENavigator
import OPSDK
import LarkUIKit
import LarkTab
import LKCommonsLogging
import LarkOPInterface
import LarkAppLinkSDK
import Foundation
import LarkContainer
import LarkNavigator

/// block demo的详情页
final class BlockDemoDetailViewController: BaseUIViewController {

    // WPBlockView 使用
    private let userResolver: UserResolver

    private let navigator: UserNavigator
    private let params: BlockDemoParams
    // 列表页信息
    private let listPageData: [String: Any]

    // 是否直接跳转
    private let openDirectly: Bool

    private lazy var blockView: WPBlockView = {
        let blockModel = BlockModel(
            item: params.item,
            badgeKey: nil,
            scene: .demoBlock,
            elementId: UUID().uuidString,
            editorProps: nil,
            styles: nil,
            sourceData: params.sourceData
        )
        let blockView = WPBlockView(userResolver: userResolver, model: blockModel, trace: nil)
        return blockView
    }()

    private lazy var navTitleLabel: UILabel = {
        let navTitleLabel = UILabel()
        // swiftlint:disable init_font_with_token
        navTitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        // swiftlint:enable init_font_with_token
        navTitleLabel.text = self.params.title
        navTitleLabel.textAlignment = .center

        return navTitleLabel
    }()

    init(
        userResolver: UserResolver,
        navigator: UserNavigator,
        params: BlockDemoParams,
        listPageData: [String: Any]
    ) {
        self.userResolver = userResolver
        self.navigator = navigator
        self.params = params
        self.listPageData = listPageData
        self.openDirectly = !listPageData.isEmpty
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBlockView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavItems()
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		blockView.blockVCShow = true
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		blockView.blockVCShow = false
	}

    private func setupBlockView() {

        view.addSubview(self.blockView)

        blockView.snp.makeConstraints {(make) in
            make.edges.equalToSuperview()
        }
        blockView.clipsToBounds = true
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
        if openDirectly {
            let navBarHomeBtn = UIBarButtonItem(
                image: Resources.back_home,
                style: .plain,
                target: self,
                action: #selector(tapHomeButton)
            )
            navigationItem.leftBarButtonItem = navBarHomeBtn
        }
        navigationItem.titleView = navTitleLabel
    }

    @objc
    private func tapCloseButton() {
        if let nav = self.navigationController {
            for targetVC in nav.viewControllers.reversed() {
                if !(targetVC is BlockDemoViewController) && !(targetVC is BlockDemoDetailViewController) {
                    nav.popToViewController(targetVC, animated: true)
                    break
                }
            }
        }
    }

    @objc
    private func tapHomeButton() {
        if let nav = self.navigationController {
            let navigator = navigator
            let listPageData = listPageData
            navigator.pop(from: self, animated: false) {
                let body = BlockDemoBody(params: listPageData)
                navigator.push(body: body, from: nav, animated: false)
            }
        }
    }
}
