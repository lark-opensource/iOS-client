//
//  BitableRecommendNativeWrapperController.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/11/6.
//

import Foundation
import SKCommon
import SpaceInterface
import SKFoundation
import EENavigator
import LarkNavigator
import SKUIKit
import UniverseDesignIcon
import UniverseDesignColor
import SnapKit
import SKResource

final class BitableRecommendNativeWrapperController: UIViewController {
    private let context: BaseHomeContext

    private(set) lazy var recommendController: SKBitableRecommendNativeController = {
        return SKBitableRecommendNativeController(context: self.context, config: RecommendNativeConfig.bottomTabConfig)
    }()

    private lazy var headerView: UIView = UIView().construct { it in
        it.backgroundColor = .ud.bgBody
    }

    private lazy var titleView: UILabel = UILabel().construct { it in
        it.text = BundleI18n.SKResource.Bitable_HomeDashboard_Discover_Tab
        it.textAlignment = .center
        it.textColor = UDColor.textTitle
        it.font = UIFont.boldSystemFont(ofSize: 18)
    }
    
    private lazy var searchButton: UIButton = UIButton().construct { it in
        it.setImage(UDIcon.searchOutlined, for: .normal)
        it.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        it.addTarget(self, action: #selector(searchButtonDidClick), for: .touchUpInside)
    }
    
    private lazy var closeButton: UIButton = UIButton().construct { it in
        it.setImage(UDIcon.closeOutlined, for: .normal)
        it.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        it.addTarget(self, action: #selector(closeButtonDidClick), for: .touchUpInside)
    }

    private var hasDisappear = true

    //MARK: lifyCycle
    init(context: BaseHomeContext) {
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupHeader()
        setupRecommendNative()

        addApplicationObserver()
        DocsTracker.reportBitableHomePageRecommendView(context: context)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if hasDisappear {
            DocsTracker.reportBitableHomePageView(context: context, tab: .recommend)
            hasDisappear = false
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        hasDisappear = true
    }

    private func setupRecommendNative() {
        addChild(recommendController)
        recommendController.didMove(toParent: self)
        view.addSubview(recommendController.view)
        recommendController.view.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-BitableHomeTabViewController.bottomTabBarHeight)
        }
    }

    private func setupHeader() {
        view.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.height.equalTo(BitableHomeLayoutConfig.homeHeaderHeight)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }

        headerView.addSubview(titleView)
        titleView.sizeToFit()
        titleView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 20
        stackView.alignment = .center
        headerView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-18)
            make.centerY.equalToSuperview()
        }

        stackView.addArrangedSubview(searchButton)
        searchButton.snp.makeConstraints { make in
            make.height.width.equalTo(20)
        }

        stackView.addArrangedSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.height.width.equalTo(20)
        }
    }

    @objc
    private func closeButtonDidClick() {
        self.navigationController?.popViewController(animated: true)

        BTOpenHomeReportMonitor.reportCancel(context: context, type: .user_back)
    }

    @objc
    private func searchButtonDidClick() {
        guard let factory = try? context.userResolver.resolve(assert: BitableSearchFactoryProtocol.self) else {
            DocsLogger.error("can not get WorkspaceSearchFactory")
            return
        }
        factory.jumpToSearchController(fromVC: self)

        DocsTracker.reportBitableHomePageClick(context: context, click: .search)
    }
}

extension BitableRecommendNativeWrapperController {
    private func addApplicationObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc
    private func applicationDidBecomeActive(_ notification: Notification) {
        if view.superview == nil {
            return
        }
        if hasDisappear {
            return
        }
        DocsTracker.reportBitableHomePageView(context: context, tab: .recommend)
    }
}
