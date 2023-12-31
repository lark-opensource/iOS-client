//
//  ChatLinkedPagesDetailViewModel.swift
//  LarkChatSetting
//
//  Created by zhaojiachen on 2023/10/27.
//

import Foundation
import LarkContainer
import RxSwift
import RxCocoa
import LKCommonsLogging
import LarkSDKInterface
import LarkModel
import LarkSwipeCellKit

final class ChatLinkedPagesDetailViewModel: SwipeTableViewCellDelegate {
    private let logger = Logger.log(ChatLinkedPagesDetailViewModel.self, category: "Module.IM.ChatLinkedPages")

    private var userResolver: UserResolver
    private var chatModel: Chat
    private(set) var cellItems: [CommonCellItemProtocol] = []
    private var chatLinkedPagesDataManager: ChatLinkedPagesDataManager?
    private let disposeBag = DisposeBag()
    private weak var targetVC: UIViewController?
    private let reloadSubject = PublishSubject<Void>()
    lazy var reloadDriver: Driver<Void> = {
        return reloadSubject.asDriver(onErrorJustReturn: ())
    }()

    init(userResolver: UserResolver, chat: Chat) {
        self.userResolver = userResolver
        self.chatModel = chat
    }

    func setup(targetVC: UIViewController?) {
        guard let chatID = Int64(self.chatModel.id) else {
            return
        }
        let dataManager = ChatLinkedPagesDataManager(
            userResolver: self.userResolver,
            chatID: chatID,
            targetVC: self.targetVC
        )
        dataManager.setup()
        dataManager.modelsDriver
            .drive(onNext: { [weak self] models in
                self?.handleResult(models)
                self?.reloadSubject.onNext(())
            }).disposed(by: disposeBag)
        self.chatLinkedPagesDataManager = dataManager

        (try? self.userResolver.userPushCenter)?
            .observable(for: PushChat.self)
            .filter { $0.chat.id == "\(chatID)" }
            .distinctUntilChanged { $0.chat.chatPinPermissionSetting == $1.chat.chatPinPermissionSetting }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                self.chatModel = push.chat
                self.reloadSubject.onNext(())
            }).disposed(by: self.disposeBag)

        self.targetVC = targetVC
    }

    private func handleResult(_ models: [ChatLinkedPageModel]) {
        if models.isEmpty {
            self.cellItems = []
            return
        }
        var items: [CommonCellItemProtocol] = []

        let headerAndFooterItem = ChatInfoLinkedPagesFooterItem(
            type: .linkedPagesFooter,
            cellIdentifier: ChatInfoLinkedPagesFooterCell.lu.reuseIdentifier,
            style: .none
        )
        items.append(headerAndFooterItem)
        models.forEach { linkedPageModel in
            let item = ChatInfoLinkedPagesDetailItem(
                type: .linkedPagesDetail,
                cellIdentifier: ChatInfoLinkedPagesDetailCell.lu.reuseIdentifier,
                verticalPadding: 10,
                titleNumberOfLines: 3,
                linkedPageModel: linkedPageModel,
                longPressHandler: { [weak self] in
                    guard let self = self, let targetVC = self.targetVC else { return }
                    guard ChatLinkedPagesdUtils.checkDeletePermission(chat: self.chatModel, userID: self.userResolver.userID) else {
                        return
                    }
                    let url = linkedPageModel.url
                    ChatLinkedPagesdUtils.showAlert(
                        targetVC: targetVC,
                        navigator: self.userResolver.navigator,
                        confirmHandler: { [weak self] in
                            self?.chatLinkedPagesDataManager?.delete(url)
                        }
                    )
                },
                tapHandler: { [weak self] _ in
                    guard let self = self else { return }
                    if let url = try? URL.forceCreateURL(string: linkedPageModel.url), let targetVC = self.targetVC {
                        if let httpUrl = url.lf.toHttpUrl() {
                            self.userResolver.navigator.open(httpUrl, from: targetVC)
                        } else {
                            self.userResolver.navigator.open(url, from: targetVC)
                        }
                    } else {
                        self.logger.error("chatLinkedPage click url fail chatID: \(self.chatModel.id)")
                    }
                },
                delegate: self
            )
            items.append(item)
        }
        items.append(headerAndFooterItem)
        self.cellItems = items
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else {
            return nil
        }
        let index = indexPath.row
        guard index < self.cellItems.count,
              let url = ( self.cellItems[index] as? ChatInfoLinkedPagesDetailItem)?.linkedPageModel.url else {
            return nil
        }
        if let deleteAction = ChatLinkedPagesdUtils.getSwipeDeleteAction(
            chat: self.chatModel,
            userID: self.userResolver.userID,
            targetVC: targetVC,
            navigator: self.userResolver.navigator,
            deleteHandler: { [weak self] in
                self?.chatLinkedPagesDataManager?.delete(url)
            }
        ) {
            return [deleteAction]
        } else {
            return nil
        }
    }

    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        return ChatLinkedPagesdUtils.getSwipeOptions()
    }
}
