//
//  FeedTeamViewController.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/13.
//

import Foundation
import UIKit
import RxSwift
import LarkUIKit
import EENavigator
import RxDataSources
import LarkSDKInterface
import LarkMessengerInterface
import LarkSwipeCellKit
import LKCommonsLogging
import LarkKeyCommandKit
import LarkPerf
import AppReciableSDK
import LarkZoomable
import LarkModel
import LarkSceneManager
import UniverseDesignEmpty
import RustPB
import LarkOpenFeed
import LarkContainer

final class FeedTeamViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UserResolverWrapper {
    var userResolver: UserResolver { viewModel.userResolver }
    static var rightOrientation: SwipeOptions?

    let tableView: FeedTableView
    let viewModel: FeedTeamViewModelInterface
    var context: FeedContextService?
    let disposeBag: DisposeBag
    weak var emptyView: UDEmptyView?
    weak var feedEmptyView: UIView?
    weak var delegate: FeedModuleVCDelegate?
    let tableFooter = LabelTableFooter(title: BundleI18n.LarkFeed.Project_MV_MobileCreateTeam)

    @ScopedInjectedLazy var feedListPageSwitchService: FeedListPageSwitchService?
    lazy var feedActionService: FeedActionService? = {
        return try? userResolver.resolve(assert: FeedActionService.self)
    }()

    init(viewModel: FeedTeamViewModelInterface,
         context: FeedContextService) {
        self.context = context
        self.tableView = FeedTableView(frame: .zero, style: .plain)
        #if swift(>=5.5)
        if #available(iOS 15.0, *) {
            tableView.fillerRowHeight = 0
            tableView.sectionHeaderTopPadding = .zero
        }
        #endif
        self.disposeBag = DisposeBag()
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bind()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        preloadDetail()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selectIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectIndexPath, animated: false)
        }
    }

    func getSwitchModeModule() -> SwitchModeModule.Mode {
        let mode: SwitchModeModule.Mode
        if let teamId = viewModel.subTeamId, !teamId.isEmpty, let id = Int(teamId) {
            mode = .threeBarMode(id)
        } else {
            mode = .standardMode
        }
        return mode
    }

    private func getTeam(section: Int) -> FeedTeamItemViewModel? {
        return section < viewModel.dataSource.count ? viewModel.dataSource[section] : nil //viewModel.teamUIModel.getTeam(section: section)
    }

    private func getChat(indexPath: IndexPath) -> FeedTeamChatItemViewModel? {
        guard let teamItemVM = getTeam(section: indexPath.section) else {
            return nil
        }
        return indexPath.row < teamItemVM.chatModels.count ? teamItemVM.chatModels[indexPath.row] : nil
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        viewWillTransitionForPad(to: size, with: coordinator)
    }

    // MARK: TableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.dataSource.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let team = getTeam(section: section) else {
            return 0
        }
        return 54
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let team = getTeam(section: section) else {
            return nil
        }
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: FeedTeamSectionHeader.identifier) as? FeedTeamSectionHeader else {
            return nil
        }
        header.set(team, context: context, mode: getSwitchModeModule())
        header.delegate = self
        return header
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let team = getTeam(section: section), !team.chatModels.isEmpty,
            team.isExpanded else {
            return 0
        }
        return 12
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let team = getTeam(section: section),
              !team.chatModels.isEmpty,
              team.isExpanded else { return nil }
        guard let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: FeedTeamSectionFooter.identifier) as? FeedTeamSectionFooter else {
            return nil
        }
        footer.set(team, viewModel.subTeamId)
        return footer
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let team = getTeam(section: section) else {
            return 0
        }
        let base = team.chatModels.count
        if team.hidenCount > 0 {
            return base + 1
        }
        return base
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let team = getTeam(section: indexPath.section),
              team.isExpanded else {
            return 0
        }
        if team.hidenCount > 0 && indexPath.row == team.chatModels.count {
            // 最后一个 feed
            return FeedTeamChatCell.Cons.cellHeight
        }

        guard getChat(indexPath: indexPath) != nil else {
            return 0
        }
        return FeedTeamChatCell.Cons.cellHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let team = getTeam(section: indexPath.section) else {
            return UITableViewCell(frame: .zero)
        }
        if team.hidenCount > 0 && indexPath.row == team.chatModels.count {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: FeedTeamHiddenCell.identifier, for: indexPath) as? FeedTeamHiddenCell else {
                return UITableViewCell(frame: .zero)
            }
            cell.set(count: team.hidenCount, mode: getSwitchModeModule())
            return cell
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FeedTeamChatCell.identifier, for: indexPath) as? FeedTeamChatCell,
            let chat = getChat(indexPath: indexPath) else {
            return UITableViewCell(frame: .zero)
        }
        cell.set(userResolver: userResolver, chat, mode: getSwitchModeModule(), teamID: team.teamEntity.id)
        cell.delegate = self
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        guard let team = getTeam(section: indexPath.section) else { return }

        if team.hidenCount > 0 && indexPath.row == team.chatModels.count {
            guard let page = self.context?.page else {
                return
            }
            let body = HiddenTeamChatListBody(teamViewModel: team)
            navigator.push(body: body, from: page)
            return
        }

        guard let selectedCell = tableView.cellForRow(at: indexPath) as? FeedTeamChatCell,
              let chatId = selectedCell.viewModel?.chatEntity.id,
              !viewModel.shouldSkip(feedId: chatId, traitCollection: view.horizontalSizeClass) else { return }
        // TODO: feed action 待处理
        selectedCell.didSelectCell(teamItemModel: team,
                                   indexPath: indexPath,
                                   from: self.parent ?? self,
                                   dependency: viewModel.dependency)
    }

    // MARK: - UIScrollViewDelegate
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        viewModel.frozenDataQueue(.draging)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            preloadDetail()
        }
        viewModel.resumeDataQueue(.draging)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        preloadDetail()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        viewModel.resumeDataQueue(.draging)
    }

    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let team = viewModel.teamUIModel.getTeam(section: indexPath.section),
              let feed = viewModel.teamUIModel.getChat(indexPath: indexPath) else {
            return nil
        }
        let actions = getActions(team: team, feed: feed, view: self.view.window ?? self.view)
        if actions.isEmpty {
            return nil
        }
        let identifier = indexPath as NSCopying
        return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil) { _ in
            return UIMenu(title: "", children: actions)
        }
    }

    @available(iOS 13.0, *)
    private func getActions(team: FeedTeamItemViewModel, feed: FeedTeamChatItemViewModel, view: UIView) -> [UIAction] {
        let actionItems = self.getActionItems(team: team, feed: feed, event: .longPress)
        return FeedActionViewUtil.transformToUIAction(items: actionItems)
    }
}
