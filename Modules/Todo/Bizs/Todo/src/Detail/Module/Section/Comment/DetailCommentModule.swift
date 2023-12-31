//
//  CommentModule.swift
//  Todo
//
//  Created by 张威 on 2021/3/4.
//

import LarkFoundation
import LarkMenuController
import EENavigator
import CTFoundation
import TodoInterface
import LarkContainer
import LarkNavigator
import LarkUIKit
import RxSwift
import RxCocoa
import LarkEmotion
import LarkEmotionKeyboard
import UniverseDesignIcon
import UniverseDesignActionPanel
import UIKit
import LarkEMM
import LarkSensitivityControl

/// Detail - Comment - Module

// nolint: magic number
class DetailCommentModule: DetailBaseModule, HasViewModel {
    let viewModel: DetailCommentViewModel

    private let disposeBag = DisposeBag()

    @ScopedInjectedLazy private var routeDependency: RouteDependency?
    @ScopedInjectedLazy private var messengerDependency: MessengerDependency?
    @ScopedInjectedLazy private var driveDependency: DriveDependency?

    override init(resolver: UserResolver, context: DetailModuleContext) {
        self.viewModel = ViewModel(resolver: resolver, store: context.store)
        super.init(resolver: resolver, context: context)
    }

    override func setup() {
        viewModel.onListUpdate = { [weak self] update in
            guard let self = self else { return }
            guard let tableView = self.context.tableView else { return }
            switch update {
            case .fullReload:
                tableView.reloadData()
            case .cellReload(let index):
                let indexPath = IndexPath(row: index, section: 0)
                guard tableView.cellForRow(at: indexPath) != nil else {
                    tableView.reloadData()
                    return
                }
                tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
        let trackerTask = Tracker.Appreciable.Task(scene: .comment, event: .commentLoadFirstPage).resume()
        viewModel.setup()
            .drive(onNext: { [weak self] isAvailable in
                if isAvailable {
                    trackerTask.complete()
                    self?.setupTableView()
                }
            })
            .disposed(by: disposeBag)

        context.bus.subscribe { [weak self] event in
            guard let self = self else { return }
            switch event {
            case let .sendCommentInput(content, scene, completion):
                self.viewModel.sendComment(
                    with: content,
                    for: scene,
                    completion: { [weak self] result in
                        switch result {
                        case .success:
                            completion(nil)
                        case .failure(let err):
                            completion(err)
                            self?.makeErrorHandler()(err.message)
                        }
                    }
                )
            case let .commentInputStatusChanged(isActive, scene):
                self.handleCommentInputChanged(isActive: isActive, scene: scene)
            default:
                break
            }
        }.disposed(by: disposeBag)
    }

    private func setupTableView() {
        guard let tableView = context.tableView else {
            assertionFailure()
            return
        }
        tableView.ctf.register(cellType: DetailCommentCell.self)
        tableView.ctf.register(headerViewType: DetailCommentHeaderView.self)
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longGesture.minimumPressDuration = 0.2
        tableView.addGestureRecognizer(longGesture)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
    }

    @objc
    private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard
            case .began = gesture.state,
            let tableView = context.tableView,
            let viewController = context.viewController
        else {
            return
        }
        let location = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: location) else {
            return
        }
        guard let targetCell = tableView.cellForRow(at: indexPath) as? DetailCommentCell else {
            return
        }
        let locationInCell = tableView.convert(location, to: targetCell)
        showMenuAction(forCell: targetCell, at: indexPath, location: locationInCell)
    }

    private func makeErrorHandler() -> (String) -> Void {
        return { [weak self] errMsg in
            guard let containerView = self?.context.viewController?.view else { return }
            Utils.Toast.showError(with: errMsg, on: containerView)
        }
    }

    private func handleCommentInputChanged(isActive: Bool, scene: CommentInputScene) {
        let deselectRow = { [weak self] in
            if let indexPath = self?.context.tableView?.indexPathForSelectedRow {
                self?.context.tableView?.deselectRow(at: indexPath, animated: false)
            }
        }
        let selectRow = { [weak self] (commentId: String) in
            if let index = self?.viewModel.indexForComment(byId: commentId) {
                // delay 0.1s，确保 tableView 的 inset 已经设置 ok
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let indexPath = IndexPath(row: index, section: 0)
                    self?.context.tableView?.selectRow(at: indexPath, animated: false, scrollPosition: .top)
                }
            }
        }
        if isActive {
            switch scene {
            case .create:
                deselectRow()
            case let .edit(commentId):
                selectRow(commentId)
            case let .reply(parentId, _):
                selectRow(parentId)
            }
        } else {
            deselectRow()
        }
    }

}

// MARK: - View Action

extension DetailCommentModule {

    private func showMenuAction(
        forCell cell: UITableViewCell,
        at indexPath: IndexPath,
        location locationInCell: CGPoint
    ) {
        guard let viewController = context.viewController else { return }
        let actionsItems = viewModel.supportedActionForRow(at: indexPath.row)
        guard !actionsItems.isEmpty else { return }

        typealias ItemInfo = (name: String, image: UIImage, handler: (IndexPath) -> Void)
        let itemInfoMap: [ViewModel.CellAction: ItemInfo] = [
            .copy: (
                name: I18N.Todo_Task_Copy,
                image: UDIcon.copyOutlined.ud.withTintColor(UIColor.ud.iconN1),
                handler: { [weak self] in
                    self?.handleCopyForCell(at: $0)
                }
            ),
            .reply: (
                name: I18N.Todo_Common_Reply,
                image: UDIcon.replyCnOutlined.ud.withTintColor(UIColor.ud.iconN1),
                handler: { [weak self] in self?.handleReplyForCell(at: $0) }
            ),
            .edit: (
                name: I18N.Todo_Task_IconHintEdit,
                image: UDIcon.editOutlined.ud.withTintColor(UIColor.ud.iconN1),
                handler: { [weak self] in self?.handleEditForCell(at: $0) }
            ),
            .delete: (
                name: I18N.Todo_common_Delete,
                image: UDIcon.deleteTrashOutlined.ud.withTintColor(UIColor.ud.iconN1),
                handler: { [weak self] in
                    self?.handleDeleteForCell(at: $0)
                }
            )
        ]

        guard let messengerDependency = messengerDependency else { return }
        let reactionService = messengerDependency.reactionService
        // reaction item maker: type -> item
        let reactionItemMaker = { (entity: ReactionEntity) -> MenuReactionItem in
            return MenuReactionItem(reactionEntity: entity) { [weak self] type in
                guard let self = self else { return }
                self.viewModel.toggleReaction(withType: type, at: indexPath.row, onError: self.makeErrorHandler())
                self.trackAction("select_reaction")
            }
        }

        // recent reactions
        var recentReactions = reactionService.getRecentReactions()
        if recentReactions.isEmpty {
            recentReactions = EmotionResouce.recentReactions.map { ReactionEntity(key: $0, selectSkinKey: $0, skinKeys: EmotionResouce.shared.skinKeysBy(key: $0)) }
        }
        let recentReactionMenuItems = Array(recentReactions.prefix(6)).map(reactionItemMaker)

        // all reactions
        var allReactionGroups = reactionService.getAllReactions()
        if allReactionGroups.isEmpty {
            let entities = EmotionResouce.reactions.map({ key in
                return ReactionEntity(
                    key: key,
                    selectSkinKey: key,
                    skinKeys: EmotionResouce.shared.skinKeysBy(key: key)
                )
            })
            allReactionGroups = [ReactionGroup(type: .default, iconKey: "", title: I18N.Lark_IM_DefaultEmojis_Title, source: "", entities: entities)]
        }
        let allReactionMenuItems = allReactionGroups.flatMap { $0.entities }.map(reactionItemMaker)

        let menuViewModel = SimpleMenuViewModel(
            recentReactionMenuItems: recentReactionMenuItems,
            scene: .todo,
            allReactionMenuItems: allReactionMenuItems,
            allReactionGroups: allReactionGroups,
            actionItems: actionsItems.compactMap { cellAcion -> MenuActionItem? in
                guard let info = itemInfoMap[cellAcion] else { return nil }
                return MenuActionItem(name: info.name, image: info.image, enable: true) { _ in
                    info.handler(indexPath)
                }
            }
        )
        menuViewModel.menuBar.reactionBarAtTop = false
        menuViewModel.menuBar.reactionSupportSkinTones = true
        let menuViewController = LarkMenuController.MenuViewController(
            viewModel: menuViewModel,
            layout: DetailCommentMenuLayout(),
            trigerView: cell,
            trigerLocation: locationInCell
        )
        menuViewController.dismissBlock = {
            // do nothing
        }
        menuViewController.show(in: viewController)
    }

    private func handleCopyForCell(at indexPath: IndexPath) {
        let copyText = viewModel.copyStringForRow(at: indexPath.row)
        DispatchQueue.main.async {
            do {
                let config = PasteboardConfig(token: Token("LARK-PSDA-task-detail-comment-item"))
                try SCPasteboard.generalUnsafe(config).string = copyText
                guard let window = self.userResolver.navigator.mainSceneWindow else {
                    assertionFailure("缺少 window")
                    return
                }
                Utils.Toast.showSuccess(with: I18N.Todo_Task_CopySuccessful, on: window)
            } catch { }

        }
    }

    private func handleReplyForCell(at indexPath: IndexPath) {
        guard let replyContext = viewModel.replyContextForRow(at: indexPath.row) else {
            Detail.logger.error("获取 replyContext 逻辑异常，index: \(indexPath.row)")
            return
        }
        let scene = CommentInputScene.reply(parentId: replyContext.parentId, rootId: replyContext.rootId)
        let content: CommentInputContent = (replyContext.richContent, [], [])
        context.bus.post(.activeCommentInput(content: content, scene: scene))
        trackAction("reply_comment")
    }

    private func handleEditForCell(at indexPath: IndexPath) {
        guard let commentId = viewModel.commentIdForRow(at: indexPath.row) else {
            Detail.logger.error("获取 commentId 逻辑异常，index: \(indexPath.row)")
            return
        }
        let scene = CommentInputScene.edit(commentId: commentId)
        let content = viewModel.editInput(forId: commentId)
        context.bus.post(.activeCommentInput(content: content, scene: scene))
    }

    private func handleDeleteForCell(at indexPath: IndexPath) {
        guard let viewController = context.viewController else {
            return
        }
        guard let cell = context.tableView?.cellForRow(at: indexPath) else {
            return
        }
        let source = UDActionSheetSource(
            sourceView: cell,
            sourceRect: CGRect(origin: cell.bounds.origin, size: CGSize(width: 220, height: 60)),
            arrowDirection: .up
        )
        let config = UDActionSheetUIConfig(titleColor: UIColor.ud.textPlaceholder, isShowTitle: true, popSource: source)
        let actionSheet = UDActionSheet(config: config)
        actionSheet.setTitle(I18N.Todo_Task_ConfirmDeleteComment)
        actionSheet.addItem(
            UDActionSheetItem(
                title: I18N.Todo_common_Delete,
                titleColor: UIColor.ud.functionDangerContentDefault,
                action: { [weak self] in
                    guard let self = self else { return }
                    self.viewModel.deleteComment(at: indexPath.row, onError: self.makeErrorHandler())
                }
            )
        )
        actionSheet.setCancelItem(text: I18N.Todo_Common_Cancel) {
            // do nothing
        }
        viewController.present(actionSheet, animated: true)
    }

}

// MARK: - TableView

extension DetailCommentModule: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let headerData = viewModel.headerData() else {
            return .leastNormalMagnitude
        }
        let statusHeight = DetailCommentHeaderView.heightForStatus(headerData.status)
        guard headerData.displayContent, let content = headerData.richContent else {
            return statusHeight
        }
        let contentHeight = DetailCommentHeaderView.heightForRichContent(content, displayWidth: tableView.frame.width)
        return statusHeight + contentHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerData = viewModel.headerData() else {
            return nil
        }
        let headerView = tableView.ctf.dequeueReusableHeaderView(DetailCommentHeaderView.self)
        headerView?.viewData = headerData
        headerView?.onLoadMore = { [weak self] in self?.viewModel.loadMore() }
        headerView?.onRetry = { [weak self] in self?.viewModel.retryForFailed() }
        headerView?.onTapContent = { [weak self] range in
            guard let action = headerData.linkActions?[range] else { return }
            switch action {
            case .user(let chatterId): self?.showUserProfile(chatterId)
            case .title(let guid): self?.showDetailVC(guid)
            }
        }
        return headerView
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.ud.N100
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let cellData = viewModel.cellDataForRow(at: indexPath.row) else {
            return .leastNormalMagnitude
        }
        return DetailCommentCell.cellHeight(for: cellData, with: tableView.frame.width)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.ctf.dequeueReusableCell(DetailCommentCell.self, for: indexPath),
            let cellData = viewModel.cellDataForRow(at: indexPath.row) else {
            return UITableViewCell()
        }
        cell.cellWidth = tableView.frame.width > 0 ? tableView.bounds.width : nil
        cell.viewData = cellData
        cell.delegate = self
        return cell
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: false)
    }

}

// MARK: - Header Action

extension DetailCommentModule {

    private func showDetailVC(_ guid: String) {
        guard let viewController = context.viewController, let source = context.store.state.scene.editSource else { return }
        let detailVC = DetailViewController(
            resolver: userResolver,
            input: .edit(guid: guid, source: .rrule(source: source), callbacks: .init())
        )
        userResolver.navigator.push(detailVC, from: viewController)
    }

}

// MARK: - Cell Action

extension DetailCommentModule: DetailCommentCellDelegate {

    private func showUserProfile(_ userId: String) {
        guard let viewController = context.viewController else { return }
        var routeParams = RouteParams(from: viewController)
        routeParams.openType = .push
        routeDependency?.showProfile(with: userId, params: routeParams)
    }

    /// 点击头像
    func didTapAvatar(from sender: DetailCommentCell) {
        guard
            let indexPath = context.tableView?.indexPath(for: sender),
            let senderId = viewModel.senderIdForRow(at: indexPath.row)
        else {
            Detail.assertionFailure()
            return
        }
        showUserProfile(senderId)
    }

    /// 点击 RichLabel At
    func didTapRichLabel(with atItem: RichLabelContent.AtItem, from sender: DetailCommentCell) {
        guard let viewController = context.viewController else {
            Detail.assertionFailure()
            return
        }
        showUserProfile(atItem.property.userID)
    }

    func didTapImageItem(_ index: Int, imageView: UIImageView, sourceItems: [RichLabelContent.ImageItem], from sender: DetailCommentCell) {
        guard let viewController = context.viewController else {
            Detail.assertionFailure()
            return
        }
        routeDependency?.previewImages(.property(sourceItems.map(\.property)), sourceIndex: index, sourceView: imageView, from: viewController)
    }
    /// 点击 RichLabel Anchor
    func didTapRichLabel(with anchorItem: RichLabelContent.AnchorItem, from sender: DetailCommentCell) {
        guard let viewController = context.viewController else {
            Detail.assertionFailure()
            return
        }
        do {
            let url = try URL.forceCreateURL(string: anchorItem.property.href)
            guard let httpUrl = url.lf.toHttpUrl() else {
                Detail.logger.error("url is not valid.")
                return
            }
            userResolver.navigator.push(httpUrl, context: ["from": "todo_detail"], from: viewController)
        } catch {
            Detail.logger.error("forceCreateURL failed. err: \(error)")
            Detail.assertionFailure()
        }
    }

    /// 点击更多
    func didTapMore(from sender: DetailCommentCell) {
        guard let indexPath = context.tableView?.indexPath(for: sender) else {
            Detail.assertionFailure()
            return
        }
        let location = CGPoint(x: sender.contentView.bounds.width - 28, y: 10)
        showMenuAction(forCell: sender, at: indexPath, location: location)
    }

    /// 点击图片
    func didTapImageView(_ imageView: UIImageView, at index: Int, from sender: DetailCommentCell) {
        guard
            let viewController = context.viewController,
            let indexPath = context.tableView?.indexPath(for: sender)
        else {
            Detail.assertionFailure(type: .findIndexPath)
            return
        }
        let images = viewModel.imagesForRow(at: indexPath.row)
        routeDependency?.previewImages(.imageSet(images), sourceIndex: index, sourceView: imageView, from: viewController)
    }

    /// 点击 Reaction Icon
    func didTapReactionIcon(with type: String, from sender: DetailCommentCell) {
        guard let indexPath = context.tableView?.indexPath(for: sender) else {
            Detail.assertionFailure()
            return
        }
        viewModel.toggleReaction(withType: type, at: indexPath.row, onError: makeErrorHandler())
    }

    /// 点击 Reaction 对应的 User
    func didTapReactionUser(with type: String, userId: String, from sender: DetailCommentCell) {
        showUserProfile(userId)
    }

    /// 点击 Reaction 对应的 More
    func didTapReactionMore(with type: String, from sender: DetailCommentCell) {
        Detail.logger.info("didTapReactionMore. type: \(type)")
        guard
            let viewController = context.viewController,
            let indexPath = context.tableView?.indexPath(for: sender),
            let cellData = viewModel.cellDataForRow(at: indexPath.row)
        else {
            Detail.assertionFailure()
            return
        }
        let dependency = ReactionDetailDependency(resolver: userResolver, focusType: type, reactions: cellData.reactions)
        let vc = dependency.makeViewController()
        userResolver.navigator.present(
            dependency.makeViewController(),
            wrap: LkNavigationController.self,
            from: viewController,
            prepare: { controller in
                controller.modalPresentationStyle = .overCurrentContext
                controller.modalTransitionStyle = .crossDissolve
                controller.view.backgroundColor = .clear

            },
            animated: false
        )
    }

    func didAnchorTitleFixed(from sender: DetailCommentCell) {
        guard let tableView = self.context.tableView else { return }
        tableView.reloadData()
    }

    func didTapAttachment(from sender: DetailCommentCell, fileToken: String) {
        guard let vc = context.viewController else { return }
        driveDependency?.previewFile(from: vc, fileToken: fileToken)
    }

    func didExpandAttachment(from sender: DetailCommentCell) {
        guard let indexPath = context.tableView?.indexPath(for: sender) else { return }
        viewModel.doExpandAttachment(at: indexPath.row)
    }
}

// MARK: - Track

extension DetailCommentModule {

    private func trackAction(_ action: String) {
        Detail.tracker(
            .todo_comment,
            params: [
                "action": action,
                "source": "task_detail",
                "task_id": context.scene.todoId ?? ""
            ]
        )
    }

}
