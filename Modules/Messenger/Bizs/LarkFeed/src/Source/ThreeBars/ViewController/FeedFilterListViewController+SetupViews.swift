//
//  FeedFilterListViewController+SetupViews.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/3/8.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkUIKit
import SnapKit
import UniverseDesignToast
import UniverseDesignEmpty
import LarkMessengerInterface

extension FeedFilterListViewController: UIGestureRecognizerDelegate {
    func setupViews() {
        isNavigationBarHidden = true
        let backgroundColor = UIColor.ud.bgBody
        view.backgroundColor = backgroundColor

        headerView.editBlock = { [weak self] in
            guard let self = self else { return }
            FeedTracker.ThreeColumns.Click.settingClick()

            guard let window = self.viewModel.dependency.currentWindow else {
                assertionFailure("window is nil")
                return
            }
            self._dismiss(animated: true, completion: {
                let body = FeedFilterSettingBody(source: .fromFeed)
                self.userResolver.navigator.present(body: body,
                                                    wrap: LkNavigationController.self,
                                                    from: window,
                                                    prepare: { $0.modalPresentationStyle = .formSheet },
                                                    animated: true)
            })
        }
        self.view.addSubview(headerView)

        tableView.register(FeedFilterListSectionHeader.self, forHeaderFooterViewReuseIdentifier: FeedFilterListSectionHeader.identifier)
        tableView.register(FeedFilterListSubItemCell.self, forCellReuseIdentifier: FeedFilterListSubItemCell.identifier)
        tableView.register(FeedFilterListCell.self, forCellReuseIdentifier: FeedFilterListCell.identifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: defaultCellIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = backgroundColor
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        self.view.addSubview(tableView)
        let compact: Bool
        if Feed.Feature(userResolver).groupPopOverForPad {
            compact = true
        } else {
            compact = viewModel.dependency.styleService.currentStyle != .padRegular
        }
        setupSubviewLayout(compact)
    }

    private func setupSubviewLayout(_ compact: Bool) {
        headerView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(headerView.height)
        }

        headerView.setTitleLabelFontSize(compact ? CompactLayout.headerViewTitleSize : RegularLayout.headerViewTitleSize)

        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    func updateSubviewLayout(_ compact: Bool) {
        headerView.snp.remakeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(headerView.height)
        }

        headerView.setTitleLabelFontSize(compact ? CompactLayout.headerViewTitleSize : RegularLayout.headerViewTitleSize)
    }
}

extension FeedFilterListViewController {
    enum RegularLayout {
        static let headerViewTopInset: CGFloat = 26
        static let headerViewTitleSize: CGFloat = 24
    }

    enum CompactLayout {
        static let headerViewTopInset: CGFloat = 0
        static let headerViewTitleSize: CGFloat = 22
    }
}
