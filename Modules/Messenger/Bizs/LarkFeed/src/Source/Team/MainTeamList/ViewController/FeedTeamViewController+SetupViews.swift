//
//  FeedTeamViewController+SetupViews.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/13.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkUIKit
import SnapKit
import UniverseDesignToast
import UniverseDesignEmpty
import RustPB
import Homeric
import LKCommonsTracker
import LarkMessengerInterface
import LarkOpenFeed
import LarkTab
import EENavigator

extension FeedTeamViewController {
    func setupViews() {
        isNavigationBarHidden = true
        let backgroundColor = UIColor.ud.bgBody
        view.backgroundColor = backgroundColor
        let wrapperScrollView = UIScrollView()
        wrapperScrollView.backgroundColor = backgroundColor
        // wrapperScrollView.isScrollEnabled = false
        tableView.register(FeedTeamSectionHeader.self, forHeaderFooterViewReuseIdentifier: FeedTeamSectionHeader.identifier)
        tableView.register(FeedTeamSectionFooter.self, forHeaderFooterViewReuseIdentifier: FeedTeamSectionFooter.identifier)
        tableView.register(FeedTeamChatCell.self, forCellReuseIdentifier: FeedTeamChatCell.identifier)
        tableView.register(FeedTeamHiddenCell.self, forCellReuseIdentifier: FeedTeamHiddenCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = backgroundColor
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0

        self.view.addSubview(wrapperScrollView)
        wrapperScrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        wrapperScrollView.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.size.edges.equalToSuperview()
        }
        tableFooter.delegate = self
        tableView.tableFooterView = tableFooter
    }

    func backFirstListWhenExist() {
        guard let teamId = viewModel.subTeamId, !teamId.isEmpty, let id = Int64(teamId) else { return }
        var teamItem = Basic_V1_Item()
        teamItem.id = id
        guard viewModel.teamUIModel.getTeam(teamItem: teamItem) == nil else { return }
        self.delegate?.backFirstList()
        viewModel.setSubTeamId(nil)
        viewModel.reload()
    }

    func showOrRemoveEmptyView() {
        guard viewModel.teamUIModel.dataState != .idle else {
            return
        }
        if viewModel.dataSource.isEmpty {
            showEmptyView()
            removeFeedEmptyView()
        } else if case .threeBarMode(let teamId) = getSwitchModeModule() {
            var teamItem = Basic_V1_Item()
            teamItem.id = Int64(teamId)
            if let team = viewModel.teamUIModel.getTeam(teamItem: teamItem),
               team.chatModels.isEmpty, team.hidenCount == 0 {
                self.removeEmptyView()
                self.showFeedEmptyView(team: team)
            } else {
                self.removeEmptyView()
                self.removeFeedEmptyView()
            }
        } else {
            self.removeEmptyView()
            self.removeFeedEmptyView()
        }
    }

    private func showEmptyView() {
        guard emptyView == nil else { return }
        let desc = UDEmptyConfig.Description(descriptionText: BundleI18n.LarkTeam.Project_T_TeamsIntro_CoreText)
        let config = UDEmptyConfig(description: desc,
                                   type: .custom(EmptyBundleResources.image(named: "emptyPositiveCreateTeam")),
                                   primaryButtonConfig: ( BundleI18n.LarkFeed.Project_MV_MobileCreateTeam, { [weak self] _ in
            self?.createTeam()
        }))
        let emptyView = UDEmptyView(config: config)
        emptyView.useCenterConstraints = true
        self.emptyView = emptyView
        tableView.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.leading.trailing.height.width.equalToSuperview()
            make.top.equalToSuperview().offset(-100)
        }
    }

    private func removeEmptyView() {
        emptyView?.removeFromSuperview()
        emptyView = nil
    }

    func showOrHidenLoading() {
        guard self.loadingPlaceholderView.isHidden == viewModel.shouldLoading else { return }
        self.loadingPlaceholderView.isHidden = !viewModel.shouldLoading
    }
}

extension FeedTeamViewController {
    func setTableFooterDisplay() {
        let display = viewModel.displayFooter
        guard tableFooter.display != display else { return }
        tableFooter.display = display
        let height: CGFloat = display ? Cons.tableFooterHeight : 0
        tableFooter.frame = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: height)
        tableView.tableFooterView = tableFooter
        tableFooter.delegate = self
    }

    enum Cons {
        static let tableFooterHeight: CGFloat = 50.0
    }
}

extension FeedTeamViewController: LabelTableFooterDelegate {
    func click() {
        createTeam()
    }

    func createTeam() {
        Tracker.post(TeaEvent(Homeric.FEED_TEAM_CLICK, params: ["click": "create_team",
                                                                "target": "feed_create_team_view"]))
        let body = CreateTeamBody { [weak self] team in
            guard let self, let feedListPageSwitchService = self.feedListPageSwitchService else { return }
            feedListPageSwitchService.switchToFeedTeamList(teamId: String(team.id))

            let completionHandler: TeamBindGroupBody.CompletionHandler? = { [weak self] feedId in
                guard let self = self else { return }
                // 创建成功后跳转聊天页面
                let body = FeedPageBody()
                var feedSelection = FeedSelection(feedId: feedId ?? "")
                feedSelection.filterTabType = .team
                feedSelection.parendId = String(team.id)
                let context: [String: Any] = [FeedSelection.contextKey: feedSelection]
                self.userResolver.navigator.showAfterSwitchIfNeeded(
                    tab: Tab.feed.url,
                    body: body,
                    context: context,
                    wrap: LkNavigationController.self,
                    from: self)
            }
            let body = TeamBindGroupBody(teamId: team.id,
                                         completionHandler: completionHandler,
                                         customLeftBarButtonItem: true)
            self.userResolver.navigator.present(
                body: body,
                from: self,
                prepare: { $0.modalPresentationStyle = .formSheet }
            )
        }
        navigator.present(body: body,
                          wrap: LkNavigationController.self,
                          from: self,
                          prepare: {
            $0.modalPresentationStyle = .formSheet
        })
    }
}

extension FeedTeamViewController: UITextViewDelegate {
    private func showFeedEmptyView(team: FeedTeamItemViewModel) {
        guard feedEmptyView == nil else { return }
        let desc = UDEmptyConfig.Description(descriptionText: BundleI18n.LarkTeam.Project_T_AddGroupsGuide_CoreText)
        let config = UDEmptyConfig(description: desc,
                                   type: .custom(EmptyBundleResources.image(named: "emptyPositiveCreateGroup")),
                                   primaryButtonConfig: ( BundleI18n.LarkTeam.Project_T_AddGroups_CoreButton, { [weak self] _ in
            self?.showActionSheet(team: team)
        }))
        let emptyView = UDEmptyView(config: config)
        emptyView.useCenterConstraints = true
        self.feedEmptyView = emptyView
        tableView.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.leading.trailing.width.bottom.equalToSuperview()
            make.height.equalTo(200)
            make.top.equalToSuperview().offset(100)
        }
    }

    private func removeFeedEmptyView() {
        feedEmptyView?.removeFromSuperview()
        feedEmptyView = nil
    }
}
