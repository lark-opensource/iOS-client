//
//  ChatSettingLinkedPagesModuleViewModel.swift
//  LarkChatSetting
//
//  Created by zhaojiachen on 2023/10/17.
//

import RustPB
import RxSwift
import LarkModel
import Foundation
import LarkOpenChat
import LarkContainer
import LKCommonsLogging
import ThreadSafeDataStructure
import LarkNavigator
import LarkSwipeCellKit
import SuiteAppConfig

final class ChatSettingLinkedPagesModuleViewModel: ChatSettingModuleViewModel, SwipeTableViewCellDelegate {

    private let logger = Logger.log(ChatSettingLinkedPagesModuleViewModel.self, category: "Module.IM.ChatLinkedPages")

    private var userResolver: LarkContainer.UserResolver
    private let pushChat: Observable<Chat>
    private var chat: Chat
    private weak var targetVC: UIViewController?
    private var chatLinkedPagesDataManager: ChatLinkedPagesDataManager?
    private var linkedPageModels: [ChatLinkedPageModel] = []
    private let disposeBag = DisposeBag()
    private let reloadSubject = PublishSubject<Void>()
    var reloadObservable: Observable<Void> {
        reloadSubject.asObservable()
    }

    private var _items: SafeAtomic<[CommonCellItemProtocol]> = [] + .readWriteLock
    var items: [CommonCellItemProtocol] {
        get { _items.value }
        set { _items.value = newValue }
    }

    init(resolver: UserResolver,
         chat: Chat,
         pushChat: Observable<Chat>,
         targetVC: UIViewController?) {
        self.chat = chat
        self.pushChat = pushChat
        self.targetVC = targetVC
        self.userResolver = resolver
    }

    func structItems() {
        self.items = self.getItems()
    }

    func startToObserve() {
        guard !AppConfigManager.shared.leanModeIsOn else {
            return
        }
        guard self.userResolver.fg.staticFeatureGatingValue(with: "messenger.chat_plugin.whitelist") else {
            return
        }

        DispatchQueue.main.async {
            guard let chatID = Int64(self.chat.id) else { return }
            self.chatLinkedPagesDataManager = ChatLinkedPagesDataManager(userResolver: self.userResolver,
                                                                         chatID: chatID,
                                                                         targetVC: self.targetVC)
            self.chatLinkedPagesDataManager?.setup()
            self.chatLinkedPagesDataManager?.modelsDriver
                .drive(onNext: { [weak self] models in
                    guard let self = self else { return }
                    self.linkedPageModels = models
                    self.structItems()
                    self.reloadSubject.onNext(())
                }).disposed(by: self.disposeBag)

            self.pushChat
                .filter { $0.id == "\(chatID)" }
                .distinctUntilChanged { $0.chatPinPermissionSetting == $1.chatPinPermissionSetting }
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] chat in
                    guard let self = self else { return }
                    self.chat = chat
                    self.structItems()
                    self.reloadSubject.onNext(())
                }).disposed(by: self.disposeBag)
        }
    }

    private func getItems() -> [CommonCellItemProtocol] {
        if linkedPageModels.isEmpty {
            return []
        }
        var items: [CommonCellItemProtocol] = []

        let titleItem = ChatInfoLinkedPagesTitleItem(
            type: .linkedPagesTitle,
            cellIdentifier: ChatInfoLinkedPagesTitleCell.lu.reuseIdentifier,
            style: .none,
            title: BundleI18n.LarkChatSetting.Lark_GroupLinkPage_LinkedPages_Title,
            totalCount: linkedPageModels.count,
            tapHandler: { [weak self] _ in
                guard let self = self,
                      let targetVC = self.targetVC else { return }
                let viewModel = ChatLinkedPagesDetailViewModel(userResolver: self.userResolver, chat: self.chat)
                let controller = ChatLinkedPagesDetailViewController(viewModel: viewModel)
                self.userResolver.navigator.push(controller, from: targetVC)
            }
        )
        items.append(titleItem)

        let displayLinkedPages = linkedPageModels.prefix(ChatInfoLinkedPagesTitleCell.maxTotalCount)
        displayLinkedPages.forEach { linkedPageModel in
            let item = ChatInfoLinkedPagesDetailItem(
                type: .linkedPagesDetail,
                cellIdentifier: ChatInfoLinkedPagesDetailCell.lu.reuseIdentifier,
                linkedPageModel: linkedPageModel,
                longPressHandler: { [weak self] in
                    guard let self = self, let targetVC = self.targetVC else { return }
                    guard ChatLinkedPagesdUtils.checkDeletePermission(chat: self.chat, userID: self.userResolver.userID) else {
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
                        self.logger.error("chatLinkedPage click url fail chatID: \(self.chat.id)")
                    }
                }, delegate: self
            )
            items.append(item)
        }

        let footerItem = ChatInfoLinkedPagesFooterItem(
            type: .linkedPagesFooter,
            cellIdentifier: ChatInfoLinkedPagesFooterCell.lu.reuseIdentifier,
            style: .none
        )
        items.append(footerItem)
        return items
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else {
            return nil
        }
        let index = indexPath.row
        guard index < self.items.count,
              let url = ( self.items[index] as? ChatInfoLinkedPagesDetailItem)?.linkedPageModel.url else {
            return nil
        }
        if let deleteAction = ChatLinkedPagesdUtils.getSwipeDeleteAction(
            chat: self.chat,
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
