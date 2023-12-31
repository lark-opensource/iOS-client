//
//  EventCheckInInfoViewController.swift
//  Calendar
//
//  Created by huoyunjie on 2022/9/16.
//

import UIKit
import Foundation
import LarkContainer
import UniverseDesignTabs
import UniverseDesignIcon
import UniverseDesignColor
import RxSwift

class EventCheckInInfoViewController: UIViewController, UserResolverWrapper {

    /// 页签视图
    var tabsView = UDTabsTitleView()
    /// 子视图代理
    var subViewControllers: [UDTabsListContainerViewDelegate] = []
    /// 子视图映射后的视图
    private lazy var listContainerView: UDTabsListContainerView = {
        return UDTabsListContainerView(dataSource: self)
    }()

    private let viewModel: EventCheckInInfoViewModel
    private let disposeBag = DisposeBag()

    let userResolver: UserResolver

    init(viewModel: EventCheckInInfoViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
        self.makeTabsView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNaviBar()
        self.view.addSubview(tabsView)
        self.view.addSubview(listContainerView)

        tabsView.snp.makeConstraints { (make) in
            make.top.right.left.equalToSuperview()
            make.height.equalTo(40)
        }

        listContainerView.backgroundColor = UDColor.bgBase
        listContainerView.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
            make.top.equalTo(tabsView.snp.bottom)
        }

        tabsView.defaultSelectedIndex = viewModel.defaultSelectedTab.rawValue
        listContainerView.defaultSelectedIndex = viewModel.defaultSelectedTab.rawValue

        self.traceView()
    }

    private func traceView() {
        self.viewModel.getEventCheckInInfo(condition: [])
            .map(\.eventID)
            .subscribe(onNext: { [weak self] eventID in
                guard let self = self else { return }
                CalendarTracerV2.CheckInfo.traceView {
                    $0.mergeEventCommonParams(commonParam: CommonParamData(calEventId: eventID.description,
                                                                           eventStartTime: self.viewModel.startTime.description,
                                                                           originalTime: self.viewModel.originalTime.description,
                                                                           uid: self.viewModel.key))
                }
            }).disposed(by: disposeBag)
    }

    private func setupNaviBar() {
        title = I18n.Calendar_Event_CheckInfoTitle

        let backButton = UIBarButtonItem(image: UDIcon.closeSmallOutlined, style: .plain, target: self, action: #selector(dimissSelf))
        self.navigationItem.leftBarButtonItem = backButton
    }

    @objc
    private func dimissSelf() {
        self.dismiss(animated: true)
    }

    private func makeTabsView() {
        // 设置单个页签底部的指示器
        let indicator = UDTabsIndicatorLineView()
        indicator.indicatorHeight = 2                   // 设置指示器高度

        // 设置页签视图
        tabsView.titles = viewModel.tabs.map(\.description)
        tabsView.backgroundColor = UDColor.bgBody       // 设置 tabsView 背景颜色
        tabsView.indicators = [indicator]               // 添加指示器
        tabsView.listContainer = listContainerView      // 添加子视图

        // 设置页签外观配置
        let config = tabsView.getConfig()
        config.layoutStyle = .average                   // 每个页签平分屏幕宽度
        config.isItemSpacingAverageEnabled = false      // 当单个页签的宽度超过整体时，是否还平分，默认为 true
        config.itemSpacing = 0                          // 间距，默认为 20
        config.titleNumberOfLines = 0                   // 多行显示
        tabsView.setConfig(config: config)              // 更新配置

    }
}

extension EventCheckInInfoViewController: UDTabsListContainerViewDataSource {
    func listContainerView(_ listContainerView: UDTabsListContainerView, initListAt index: Int) -> UDTabsListContainerViewDelegate {
        let tab: EventCheckInInfoViewModel.Tab
        if index < viewModel.tabs.count {
            tab = viewModel.tabs[index]
        } else {
            tab = .link
        }
        switch tab {
        case .link:
            return EventCheckInLinkViewController(viewModel: viewModel, userResolver: self.userResolver)
        case .qrcode:
            return EventCheckInQRCodeViewController(viewModel: viewModel, userResolver: self.userResolver)
        case .stats:
            return EventCheckInStatsViewController(viewModel: viewModel, userResolver: self.userResolver)
        }
    }

    func numberOfLists(in listContainerView: UDTabsListContainerView) -> Int {
        return viewModel.tabs.count
    }
}
