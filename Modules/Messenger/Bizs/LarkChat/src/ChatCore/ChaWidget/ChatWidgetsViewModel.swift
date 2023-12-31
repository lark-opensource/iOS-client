//
//  ChatWidgetsViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/1/10.
//

import UIKit
import Foundation
import LarkOpenChat
import LarkMessageCore
import LKCommonsLogging
import RxSwift
import RxCocoa
import LarkSDKInterface
import LarkContainer
import LarkModel
import LarkCore
import RustPB
import LarkAccountInterface

enum ChatWidgetsRefreshType: OuputTaskTypeInfo {
    case refreshTable

    func canMerge(type: ChatWidgetsRefreshType) -> Bool {
        return true
    }

    var describ: String {
        switch self {
        case .refreshTable:
            return "refreshTable"
        }
    }

    func duration() -> Double {
        return 0
    }
    func isBarrier() -> Bool {
        return false
    }
}

/// widgets 数据处理逻辑
final class ChatWidgetsViewModel: AsyncDataProcessViewModel<ChatWidgetsRefreshType, [ChatWidgetCellViewModel]>, ChatOpenWidgetService, UserResolverWrapper {
    var userResolver: UserResolver { widgetModule.userResolver }
    static let logger = Logger.log(ChatWidgetsViewModel.self, category: "ChatWidgetsViewModel")

    private let disposeBag = DisposeBag()
    private var version: Int64?
    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    private var cellViewModels: [ChatWidgetCellViewModel] = []
    private let widgetModule: ChatWidgetModule
    private let chatWrapper: ChatPushWrapper
    let getChat: () -> Chat
    lazy var canManageWidgetsBehaviorRelay: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: true)

    init(widgetModule: ChatWidgetModule, chatWrapper: ChatPushWrapper) {
        self.widgetModule = widgetModule
        self.getChat = {
            return chatWrapper.chat.value
        }
        self.chatWrapper = chatWrapper
        super.init(uiDataSource: [])
    }

    func initSortAndDeleteViewModel() -> ChatWidgetsSortAndDeleteViewModel {
        let sortAndDeleteViewModel = ChatWidgetsSortAndDeleteViewModel(
            userResolver: userResolver,
            widgetContainer: Container(parent: self.widgetModule.context.container),
            chatWrapper: self.chatWrapper,
            widgets: self.uiDataSource.map { $0.metaModel.widget.copy() },
            containerSize: self.containerSize
        )
        return sortAndDeleteViewModel
    }

    func setup() {
        let metaModel = ChatWidgetMetaModel(chat: self.chatWrapper.chat.value)
        self.widgetModule.handler(model: metaModel)
        self.widgetModule.modelDidChange(model: metaModel)
        self.chatWrapper.chat
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] chat in
                self?.widgetModule.modelDidChange(model: ChatWidgetMetaModel(chat: chat))
            }.disposed(by: self.disposeBag)
        self.widgetModule.setup()

        let chatId = Int64(getChat().id) ?? 0
        try? self.widgetModule.context.resolver.userPushCenter
            .observable(for: PushChatWidgets.self)
            .filter { $0.push.chatID == chatId }
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                let idsLog = push.push.widgets.reduce("") { partialResult, widgte in
                    var partialResult = partialResult
                    partialResult += " \(widgte.id)"
                    return partialResult
                }
                Self.logger.info("widgetsTrace \(chatId) push widgets curVersion: \(self.version) newVersion: \(push.push.version) \(push.push.widgets.count) \(idsLog)")
                self.version = push.push.version
                let widgets = self.widgetModule.parseWidgetsPush(push: push.push)
                self.handle(widgets: widgets)
            }).disposed(by: self.disposeBag)

        self.chatAPI?.getChatWidgets(chatId: chatId)
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] response in
                guard let self = self else { return }
                let idsLog = response.widgets.reduce("") { partialResult, widgte in
                    var partialResult = partialResult
                    partialResult += " \(widgte.id)"
                    return partialResult
                }
                Self.logger.info("widgetsTrace \(chatId) get widgets curVersion: \(self.version) newVersion: \(response.version) \(response.widgets.count) \(idsLog)")
                if let version = self.version, version >= response.version { return }
                self.version = response.version
                let widgets = self.widgetModule.parseWidgetsResponse(response: response)
                self.handle(widgets: widgets)
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                Self.logger.error("widgetsTrace \(chatId) get widgets fail", error: error)
            }).disposed(by: self.disposeBag)

        self.chatWrapper.chat
            .observeOn(MainScheduler.instance)
            .map { [weak self] chat -> Bool in
                guard let self = self else { return false }
                return self.checkPermissionForManageWidgets(chat).0
            }
            .bind(to: self.canManageWidgetsBehaviorRelay).disposed(by: disposeBag)
    }

    func updateWidgetsExpandState(_ state: ChatWidgetUIState) {
        let chatId = self.chatWrapper.chat.value.id
        let widgetStatusValue = self.chatWrapper.chat.value.chatterExtraStates[Chat.ChatterExtraStatesType.widgetStatus]
        let oldExpandWidgets = widgetStatusValue == nil || widgetStatusValue == Int32(RustPB.Basic_V1_Chat.WidgetState.expand.rawValue)
        let expandWidgets: Bool
        switch state {
        case .fold:
            expandWidgets = false
        case .single, .limitExpand:
            expandWidgets = true
        }
        Self.logger.info("begin update chat \(chatId) expandWidgets \(expandWidgets) oldExpandWidgets \(oldExpandWidgets)")
        if expandWidgets == oldExpandWidgets { return }
        self.chatAPI?.updateChat(chatId: chatId, expandWidgets: expandWidgets)
            .subscribe()
    }

    /// CellVM transform
    private func handle(widgets: [ChatWidget]) {
        let chat = self.getChat()
        var oldCellViewModels = self.cellViewModels
        self.cellViewModels = []
        widgets.forEach { widget in
            let metaModel = ChatWidgetCellMetaModel(chat: chat, widget: widget)
            if let cellVM = oldCellViewModels.first(where: { $0.metaModel.widget.id == widget.id }) {
                self.cellViewModels.append(cellVM)
                cellVM.update(metaModel)
                Self.logger.info("widgetsTrace \(chat.id) update old cellVM \(widget.id)")
            } else if let contentVM = self.widgetModule.createViewModel(metaModel) {
                let createdCellVM = ChatWidgetCellViewModel(metaModel: metaModel, context: self.widgetModule.context, contentVM: contentVM)
                self.cellViewModels.append(createdCellVM)
                Self.logger.info("widgetsTrace \(chat.id) create new cellVM \(widget.id)")
            }
        }
        self.refreshTable()
    }

    private func refreshTable() {
        /// 判断 widget 卡片是否可见
        var widgetIdsForLog: String = ""
        let showCellViewModels = self.cellViewModels.filter { cellVM in
            let canShow = self.widgetModule.canShow(cellVM.metaModel)
            widgetIdsForLog += "\n widgetId:\(cellVM.metaModel.widget.id) show:\(canShow)"
            return canShow
        }
        Self.logger.info("widgetsTrace \(self.getChat().id) publish refreshTable \(widgetIdsForLog)")
        self.tableRefreshPublish.onNext((.refreshTable, newDatas: showCellViewModels, outOfQueue: false))
    }

    func update(doUpdate: @escaping (ChatWidget) -> ChatWidget?, completion: ((Bool) -> Void)?) {
        self.queueManager.addDataProcess { [weak self] in
            guard let self = self else { return }
            var widgetIdsForLog: String = ""
            var needUpdate = false
            for cellVM in self.cellViewModels {
                let widget = cellVM.metaModel.widget
                if let newWidget = doUpdate(widget) {
                    cellVM.update(ChatWidgetCellMetaModel(chat: self.getChat(), widget: newWidget))
                    needUpdate = true
                    widgetIdsForLog += " \(newWidget.id)"
                }
            }
            completion?(needUpdate)
            Self.logger.info("widgetsTrace \(self.getChat().id) update widgetIds \(widgetIdsForLog)")
            self.refreshTable()
        }
    }

    func refresh() {
        self.queueManager.addDataProcess {
            self.refreshTable()
        }
    }

    var containerSize: CGSize = .zero
    func onResize() {
        self.queueManager.addDataProcess { [weak self] in
            guard let self = self else { return }
            for cellVM in self.cellViewModels {
                cellVM.onResize()
            }
            self.refreshTable()
        }
    }

}

extension ChatWidgetsViewModel {
    private func checkPermissionForManageWidgets(_ chat: Chat) -> (Bool, String?) {
        if chat.isFrozen {
            return (false, BundleI18n.LarkChat.Lark_IM_CantCompleteActionBecauseGrpDisbanded_Toast)
        }
        if ChatPinPermissionUtils.checkChatTabsMenuWidgetsPermission(chat: chat, userID: self.userResolver.userID, featureGatingService: self.userResolver.fg) {
            return (true, nil)
        } else {
            return (false, BundleI18n.LarkChat.Lark_OnlyGroupOwnerAdminCanManage_Hover)
        }
    }

    var canManageWidgets: (Bool, String?) {
        return self.checkPermissionForManageWidgets(self.chatWrapper.chat.value)
    }
}
