//
//  FeedListViewController+SetupViews.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/8.
//

import Foundation
import SnapKit
import RxDataSources
import RxSwift
import RxCocoa
import LarkNavigation
import AnimatedTabBar
import LKCommonsLogging
import RunloopTools
import LarkSDKInterface
import RustPB
import AppContainer
import LarkPerf
import LarkMessengerInterface
import EENavigator
import LarkKeyCommandKit
import LarkUIKit
import UniverseDesignTabs
import LarkFoundation
import Heimdallr
import AppReciableSDK
import LarkAccountInterface
import UIKit

extension FeedListViewController {
    func setupSubViews() {
        let backgroundColor = UIColor.ud.bgBody
        view.backgroundColor = backgroundColor
        let wrapperScrollView = UIScrollView()
        self.view.addSubview(wrapperScrollView)
        wrapperScrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 4))
        tableView.tableHeaderView = headerView
        wrapperScrollView.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.size.edges.equalToSuperview()
        }
        self.view.layoutIfNeeded()
    }
}
