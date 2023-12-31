//
//  CalendarShareViewController.swift
//  Calendar
//
//  Created by Hongbin Liang on 4/19/23.
//

import Foundation
import LarkUIKit
import LarkContainer
import UniverseDesignTabs
import UniverseDesignIcon
import UniverseDesignColor

class CalendarShareViewController: UIViewController, UserResolverWrapper {

    private let viewModel: CalendarShareViewModel

    let userResolver: UserResolver

    private(set) var forwardVC: CalendarShareForwardViewController

    init(viewModel: CalendarShareViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = userResolver
        self.forwardVC = .init(with: viewModel.calContext, userResolver: userResolver)
        super.init(nibName: nil, bundle: nil)
        title = I18n.Calendar_Share_ShareButton
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let closeIcon = UDIcon.getIconByKeyNoLimitSize(.closeSmallOutlined).scaleNaviSize().renderColor(with: .n1)
        let closeItem = LKBarButtonItem(image: closeIcon)
        closeItem.button.addTarget(self, action: #selector(closeBtnPressed), for: .touchUpInside)
        navigationItem.leftBarButtonItem = closeItem

        let listContainerView = UDTabsListContainerView(dataSource: self)
        listContainerView.backgroundColor = .ud.bgBase
        view.addSubview(listContainerView)
        listContainerView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
        }

        let tabsView = UDTabsTitleView()
        setup(tabs: tabsView, listContainer: listContainerView)
        view.addSubview(tabsView)
        tabsView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(40)
            make.bottom.equalTo(listContainerView.snp.top)
        }

        forwardVC.currentNavigationItem = navigationItem
        forwardVC.resetNaviItemIfNeeded()
        CalendarTracerV2.CalendarShare.traceView {
            $0.calendar_id = self.viewModel.calContext.calID
            $0.is_admin_plus = self.viewModel.calContext.isManager.description
        }
    }

    private func setup(tabs: UDTabsTitleView, listContainer: UDTabsListContainerView) {
        // 设置单个页签底部的指示器(蓝色高亮)
        let indicator = UDTabsIndicatorLineView()
        indicator.indicatorHeight = 2                   // 设置指示器高度

        // 设置页签视图
        tabs.titles = viewModel.tabs.map(\.description)
        tabs.backgroundColor = .ud.bgFloat & .ud.bgFloatBase
        tabs.indicators = [indicator]                   // 添加指示器
        tabs.listContainer = listContainer              // 添加子视图

        // 设置页签外观配置
        let config = tabs.getConfig()
        config.layoutStyle = .average                   // 每个页签平分屏幕宽度
        config.isItemSpacingAverageEnabled = false      // 当单个页签的宽度超过整体时，是否还平分，默认为 true
        config.itemSpacing = 0                          // 间距，默认为 20
        config.titleNumberOfLines = 0
        tabs.setConfig(config: config)
        tabs.delegate = self
    }

    @objc
    private func closeBtnPressed() {
        self.dismiss(animated: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - DataSource
extension CalendarShareViewController: UDTabsListContainerViewDataSource {
    func numberOfLists(in listContainerView: UDTabsListContainerView) -> Int {
        viewModel.tabs.count
    }

    func listContainerView(_ listContainerView: UDTabsListContainerView, initListAt index: Int) -> UDTabsListContainerViewDelegate {
        guard let tab = viewModel.tabs[safeIndex: index] else {
            CalendarBiz.shareLogger.error("share tab index out of range")
            return CalendarShareLinkViewController(viewModel: viewModel, userResolver: self.userResolver)
        }
        switch tab {
        case .forward: return forwardVC
        case .link: return CalendarShareLinkViewController(viewModel: viewModel, userResolver: self.userResolver)
        case .qrcode: return CalendarShareQRCodeViewController(viewModel: viewModel, userResolver: self.userResolver)
        }
    }
}

// MARK: - Delegate
extension CalendarShareViewController: UDTabsViewDelegate {
    func tabsView(_ tabsView: UDTabsView, didSelectedItemAt index: Int) {
        if let tab = viewModel.tabs[safeIndex: index], tab == .forward {
            if navigationItem.rightBarButtonItem.isNil { forwardVC.resetNaviItemIfNeeded() }
        } else { forwardVC.currentNavigationItem?.rightBarButtonItem = nil }

        CalendarTracerV2.CalendarShare.traceClick {
            $0.click(self.viewModel.tabs[safeIndex: index]?.tracerDesc ?? "")
            $0.calendar_id = self.viewModel.calContext.calID
            $0.is_admin_plus = self.viewModel.calContext.isManager.description
        }
    }
}
