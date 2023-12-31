//
//  HiddenChatListViewController.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/10/26.
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

final class HiddenChatListViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UserResolverWrapper {
    var userResolver: UserResolver { viewModel.userResolver }

    static var rightOrientation: SwipeOptions?
    let tableView: UITableView
    let viewModel: HiddenChatListViewModel
    let disposeBag: DisposeBag
    weak var emptyView: UDEmptyView?

    init(viewModel: HiddenChatListViewModel) {
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selectIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectIndexPath, animated: false)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        viewWillTransitionForPad(to: size, with: coordinator)
    }

    // MARK: TableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.teamUIModel.chatModels.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FeedTeamChatCell.identifier, for: indexPath) as? FeedTeamChatCell,
              indexPath.row < viewModel.teamUIModel.chatModels.count else {
            return UITableViewCell(frame: .zero)
        }
        let chat = viewModel.teamUIModel.chatModels[indexPath.row]
        cell.set(userResolver: userResolver, chat, mode: .standardMode, teamID: Int64(viewModel.teamItemId))
        cell.update()
        cell.delegate = self
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        guard let selectedCell = tableView.cellForRow(at: indexPath) as? FeedTeamChatCell,
              let chatId = selectedCell.viewModel?.chatEntity.id,
            !viewModel.shouldSkip(feedId: chatId, traitCollection: view.horizontalSizeClass) else { return }
        selectedCell.didSelectCell(teamItemModel: viewModel.teamUIModel, indexPath: indexPath, from: self, dependency: viewModel.dependency)
    }

    // MARK: - UIScrollViewDelegate
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        viewModel.frozenDataQueue(.draging)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        viewModel.resumeDataQueue(.draging)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        viewModel.resumeDataQueue(.draging)
    }
}
