//
//  MomentsUserNoticeViewController.swift
//  Moment
//
//  Created by bytedance on 2021/2/22.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignTabs
import LarkContainer
import RxSwift
import EENavigator

final class MomentsUserNoticeContainerViewController: MomentsViewAdapterViewController, UDTabsListContainerViewDataSource {
    weak var navFromForPad: NavigatorFrom?
    private let disposeBag = DisposeBag()
    private let tabsView = MomentsTabsView()
    @ScopedInjectedLazy private var badgeNoti: MomentBadgePushNotification?
    private let circleId: String?

    lazy var listContainerView: UDTabsListContainerView = {
        return UDTabsListContainerView(dataSource: self)
    }()

    init(userResolver: UserResolver, circleId: String?) {
        self.circleId = circleId
        super.init(userResolver: userResolver)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.Moment.Lark_Community_NotificationTab
        setupUI()
        addObserverForBadge()
        view.backgroundColor = .ud.bgBody
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] _ in
            self?.tabsView.reloadData()
        }
    }

    func addObserverForBadge() {
        self.badgeNoti?.badgePush
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (info) in
                guard let self = self, let badge = self.momentsAccountService?.getCurrentUserBadge(info) else { return }
                self.setTabsViewBadge((Int(badge.messageCount), Int(badge.reactionCount)))
            }).disposed(by: self.disposeBag)
    }

    func setTabsViewBadge(_ badge: (Int, Int)) {
        tabsView.badgeCountArr = [badge.0, badge.1]
        /// 这里只刷新徽标
        tabsView.collectionView.reloadData()
    }

    override func backItemTapped() {
        super.backItemTapped()
        if let vc = listContainerView.validListDict[tabsView.selectedIndex] as? MomentsNoticeBaseVC {
            MomentsTracer.trackNotificationPageClickWith(type: vc.viewModel.sourceType,
                                                         clickType: .others,
                                                         circleId: circleId)
        }
    }

    func setupUI() {
        tabsView.titles = [BundleI18n.Moment.Lark_Community_NotificationInteractive,
                           BundleI18n.Moment.Lark_Community_NotificationEmoji]
        let config = tabsView.getConfig()
        config.layoutStyle = .average
        config.itemSpacing = 0
        config.contentEdgeInsetLeft = 0
        tabsView.badgeCountArr = [Int(self.badgeNoti?.currentBadge.messageCount ?? 0),
                                  Int(self.badgeNoti?.currentBadge.reactionCount ?? 0)]
        tabsView.lu.addBottomBorder()
        tabsView.setConfig(config: config)
        let indicator = UDTabsIndicatorLineView()
        indicator.indicatorHeight = 2
        indicator.indicatorCornerRadius = 0
        tabsView.defaultSelectedIndex = 0
        tabsView.backgroundColor = UIColor.ud.bgBody
        // 如果message没有新消息 reaction有的话，需要跳转到reaction
        if (self.badgeNoti?.currentBadge.messageCount ?? 0) <= 0,
           (self.badgeNoti?.currentBadge.reactionCount ?? 0) > 0 {
            tabsView.defaultSelectedIndex = tabsView.titles.count - 1
        }
        Tracer.trackCommunityTabNotification(type: tabsView.defaultSelectedIndex == 0 ? .interaction : .emoji)
        tabsView.indicators = [indicator]
        self.view.addSubview(tabsView)
        tabsView.delegate = self
        tabsView.listContainer = listContainerView
        self.view.addSubview(listContainerView)
        listContainerView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(tabsView.snp.bottom)
        }
        tabsView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.height.equalTo(40)
        }
    }

    /// - Parameter listContainerView: UDTabsListContainerView
    func numberOfLists(in listContainerView: UniverseDesignTabs.UDTabsListContainerView) -> Int {
        return 2
    }

    /// - Parameters:
    ///   - listContainerView: UDTabsListContainerView
    ///   - index: 目标index
    /// - Returns: 遵从UDTabsListContainerViewListDelegate协议的实例
    func listContainerView(_ listContainerView: UniverseDesignTabs.UDTabsListContainerView, initListAt index: Int) -> UniverseDesignTabs.UDTabsListContainerViewDelegate {
        let context = NoticeContext()
        context.navFromForPad = self.navFromForPad
        if index == 0 {
            let vm = MomentsUserNoticeViewModel(userResolver: userResolver, type: .message, context: context, circleId: circleId)
            let vc = MomentsNoticeMessageVC(userResolver: userResolver, viewModel: vm)
            context.pageAPI = vc
            context.dataSourceAPI = vm
            return vc
        } else {
            let vm = MomentsUserNoticeViewModel(userResolver: userResolver, type: .reaction, context: context, circleId: circleId)
            let vc = MomentsNoticeReactionVC(userResolver: userResolver, viewModel: vm)
            context.pageAPI = vc
            context.dataSourceAPI = vm
            return vc
        }
    }
}
extension MomentsUserNoticeContainerViewController: UDTabsViewDelegate {
    func tabsView(_ tabsView: UniverseDesignTabs.UDTabsView, didSelectedItemAt index: Int) {
        Tracer.trackCommunityTabNotification(type: (index == 0 ? .interaction : .emoji))
    }
}
