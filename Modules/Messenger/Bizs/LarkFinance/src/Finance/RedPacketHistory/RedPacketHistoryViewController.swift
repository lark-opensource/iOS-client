//
//  RedPacketHistoryViewController.swift
//  LarkFinance
//
//  Created by SuPeng on 12/20/18.
//

import Foundation
import UIKit
import LarkUIKit
import LarkModel
import EENavigator
import LarkSDKInterface
import LarkMessengerInterface
import SnapKit
import UniverseDesignTabs
import LarkContainer

final class RedPacketHistoryViewController: BaseUIViewController, UserResolverWrapper {

    var userResolver: LarkContainer.UserResolver
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private let redPacketAPI: RedPacketAPI

    private var tabViewControllers: [UDTabsListContainerViewDelegate] = []

    init(redPacketAPI: RedPacketAPI,
         userResolver: UserResolver) {
        self.redPacketAPI = redPacketAPI
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        isNavigationBarHidden = true

        let naviBar = TitleNaviBar(titleString: BundleI18n.LarkFinance.Lark_Legacy_History)
        let titleColor = UIColor.ud.Y200.alwaysLight
        view.addSubview(naviBar)
        (naviBar.titleView as? UILabel)?.textColor = titleColor
        naviBar.backgroundColor = redPacketRed
        naviBar.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }

        let backButton = UIButton()
        backButton.setImage(Resources.red_packet_back, for: .normal)
        backButton.addTarget(self, action: #selector(closeOrBackButtonDidClick), for: .touchUpInside)
        naviBar.addSubview(backButton)
        backButton.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 48, height: 48))
            make.centerY.equalTo(naviBar.titleView.snp.centerY)
            make.left.equalToSuperview()
        }

        let receivedBody = RedPacketReceivedHistoryBody()
        if let receivedVC = (userResolver.navigator.response(for: receivedBody).resource as? UDTabsListContainerViewDelegate) {
            tabViewControllers.append(receivedVC)
        }

        let sentBody = RedPacketSentHistoryBody()
        if let sentVC = (userResolver.navigator.response(for: sentBody).resource as? UDTabsListContainerViewDelegate) {
            tabViewControllers.append(sentVC)
        }

        // UDTabs

        let tab = UDTabsTitleView()
        let indicator = UDTabsIndicatorLineView()
        let horizontalScrollContainer = UDTabsListContainerView(dataSource: self)

        tab.indicators = [indicator]
        tab.titles = [BundleI18n.LarkFinance.Lark_Legacy_ReceivedHistory,
                      BundleI18n.LarkFinance.Lark_Legacy_SendHistory]
        tab.listContainer = horizontalScrollContainer
        tab.backgroundColor = UIColor.ud.bgBody

        let tabConfig = tab.getConfig()
        tabConfig.layoutStyle = .average
        tabConfig.isItemSpacingAverageEnabled = false
        tabConfig.itemSpacing = 0
        tabConfig.contentEdgeInsetLeft = 0
        tabConfig.titleNormalColor = redPacketRed
        tabConfig.titleSelectedColor = redPacketRed

        indicator.indicatorHeight = 2
        indicator.indicatorColor = redPacketRed

        view.addSubview(tab)
        view.addSubview(horizontalScrollContainer)
        tab.snp.makeConstraints {
            $0.top.equalTo(naviBar.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(40)
        }
        horizontalScrollContainer.snp.makeConstraints {
            $0.top.equalTo(tab.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    @objc
    private func closeOrBackButtonDidClick() {
        self.navigationController?.popViewController(animated: true)
    }
}

extension RedPacketHistoryViewController: UDTabsListContainerViewDataSource {
    func listContainerView(_ listContainerView: UDTabsListContainerView, initListAt index: Int) -> UDTabsListContainerViewDelegate {
        tabViewControllers[index]
    }

    func numberOfLists(in listContainerView: UDTabsListContainerView) -> Int {
        tabViewControllers.count
    }
}

extension SendReceiveViewController: UDTabsListContainerViewDelegate {
    public func listView() -> UIView {
        return view
    }
}
