//
//  ChatWidgetsSortAndDeleteViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/3/28.
//

import Foundation
import RxSwift
import RxCocoa
import LarkMessageCore
import LarkOpenChat
import LarkCore
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import AppContainer
import LarkModel
import UniverseDesignToast

final class ChatWidgetsSortAndDeleteViewModel: ChatOpenWidgetService, UserResolverWrapper {
    let userResolver: UserResolver
    private static let logger = Logger.log(ChatWidgetsSortAndDeleteViewModel.self, category: "ChatWidgetsSortAndDeleteViewModel")

    private let dataProcessQueue = DispatchQueue(label: "messenger.chat.widgets.sortAndDelete", qos: .userInteractive)
    private let widgetContainer: Container
    private let chatWrapper: ChatPushWrapper
    private let widgets: [ChatWidget]
    private let disposeBag = DisposeBag()

    private var tableRefreshPublish: PublishSubject<[ChatWidgetCellViewModel]> = PublishSubject<[ChatWidgetCellViewModel]>()
    lazy var refreshDriver: Driver<Void> = {
        return tableRefreshPublish
            .observeOn(MainScheduler.instance)
            .map { [weak self] datas in
                self?.uiDataSource = datas
            }
            .asDriver(onErrorRecover: { _ in Driver<Void>.empty() })
    }()

    var containerSize: CGSize
    var uiDataSource: [ChatWidgetCellViewModel] = []
    let getChat: () -> Chat
    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    weak var targetVC: UIViewController?

    private lazy var module: ChatWidgetModule = {
        widgetContainer.register(ChatOpenWidgetService.self) { [weak self] (_) -> ChatOpenWidgetService in
            return self ?? DefaultChatOpenWidgetServiceImp()
        }
        let widgetContext = ChatWidgetContext(parent: widgetContainer, store: Store(), userStorage: userResolver.storage, compatibleMode: userResolver.compatibleMode)
        let module = ChatWidgetModule(context: widgetContext)
        return module
    }()

    init(userResolver: UserResolver, widgetContainer: Container, chatWrapper: ChatPushWrapper, widgets: [ChatWidget], containerSize: CGSize) {
        self.userResolver = userResolver
        self.widgetContainer = widgetContainer
        self.chatWrapper = chatWrapper
        self.widgets = widgets
        self.containerSize = containerSize
        self.getChat = {
            return chatWrapper.chat.value
        }
    }

    func setup() {
        let metaModel = ChatWidgetMetaModel(chat: self.chatWrapper.chat.value)
        self.module.handler(model: metaModel)
        self.module.modelDidChange(model: metaModel)
        self.chatWrapper.chat
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] chat in
                self?.module.modelDidChange(model: ChatWidgetMetaModel(chat: chat))
            }.disposed(by: self.disposeBag)

        self.handle(widgets: widgets)
    }

    func move(from: Int, to: Int) {
        guard self.uiDataSource.count > from, self.uiDataSource.count > to, let chatAPI else { return }
        let itemToMove = self.uiDataSource[from]
        self.uiDataSource.remove(at: from)
        self.uiDataSource.insert(itemToMove, at: to)

        let chatId = self.chatWrapper.chat.value.id
        Self.logger.info("widgetTrace reOrder begin chatId: \(chatId) from: \(from) to: \(to)")

        let reorderWidgetIds = self.uiDataSource.map { $0.metaModel.widget.id }
        guard let chatId = Int64(chatId) else { return }
        chatAPI.reorderChatWidgets(chatId: chatId, widgetIds: reorderWidgetIds)
            .observeOn(MainScheduler.instance)
            .subscribe(onError: { [weak self] error in
                Self.logger.error("widgetTrace reOrder fail chatId: \(chatId)", error: error)
                if let targetVC = self?.targetVC {
                    UDToast.showFailureIfNeeded(on: targetVC.view, error: error)
                }
            }).disposed(by: disposeBag)
        IMTracker.Chat.Main.Click.ChatWidgetDrag(self.chatWrapper.chat.value, widetIds: [itemToMove.metaModel.widget.id])
    }

    func delete(widgetId: Int64) -> Observable<Int64> {
        guard let chatId = Int64(self.chatWrapper.chat.value.id), let chatAPI else { return .empty() }
        return chatAPI.deleteChatWidgets(chatId: chatId, widgetIds: [widgetId]).map { _ in return widgetId }
            .do(onError: { error in
                Self.logger.error("widgetTrace delete widget fail widgetId: \(widgetId) chatId: \(chatId)", error: error)
            })
    }

    private func handle(widgets: [ChatWidget]) {
        self.dataProcessQueue.async {
            let chat = self.chatWrapper.chat.value
            let cellViewModels: [ChatWidgetCellViewModel] = widgets.compactMap({ widget in
                let metaModel = ChatWidgetCellMetaModel(chat: chat, widget: widget)
                guard let contentVM = self.module.createViewModel(metaModel) else {
                    return nil
                }
                return ChatWidgetCellViewModel(metaModel: metaModel, context: self.module.context, contentVM: contentVM)
            })
            self.tableRefreshPublish.onNext(cellViewModels)
        }
    }

    /// ChatOpenWidgetService 排序删除列表不支持
    func update(doUpdate: @escaping (ChatWidget) -> ChatWidget?, completion: ((Bool) -> Void)?) {}
    func refresh() {}
}
