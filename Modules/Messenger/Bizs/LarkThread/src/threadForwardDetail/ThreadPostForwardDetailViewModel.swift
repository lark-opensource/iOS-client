//
//  ThreadPostForwardDetailViewModel.swift
//  LarkThread
//
//  Created by liluobin on 2021/6/8.
//

import Foundation
import UIKit
import LarkCore
import RustPB
import LarkMessengerInterface
import LarkMessageCore
import LarkMessageBase
import LarkSDKInterface
import LarkModel
import LarkContainer
import RxSwift
import RxCocoa
import LKCommonsLogging
import LarkOpenChat

final class ThreadPostForwardDetailViewModel: ThreadDetailTableViewDataSource, UserResolverWrapper {
    let userResolver: UserResolver
    private static let logger = Logger.log(ThreadPostForwardDetailViewModel.self, category: "LarkThread.PostForwardDetailViewModel")
    enum TableRefreshType {
        case startMultiSelect(startIndex: IndexPath)
        case finishMultiSelect
        case refreshTable
        case messagesUpdate(indexs: [IndexPath], guarantLastCellVisible: Bool)
    }
    let threadMessageSection = 0
    let replysSection = 1
    let originMergeForwardId: String
    var message: Message
    let context: ThreadDetailContext
    var threadMessage: ThreadMessage?
    let chat: Chat
    var uiDataSource: [[ThreadDetailCellViewModel]] = []
    var hostUIConfig: HostUIConfig = .init(size: .zero, safeAreaInsets: .zero)
    @ScopedInjectedLazy var menuService: ThreadMenuService?
    @ScopedInjectedLazy var generalSettings: UserGeneralSettings?
    let inSelectMode: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    let pickedMessages = BehaviorRelay<[ChatSelectedMessageContext]>(value: [])
    lazy var dataQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "detail.data.queue", qos: .userInitiated)
        return queue
    }()
    private let disposeBag = DisposeBag()
    /// 刷新信号
    var tableRefreshPublish: PublishSubject<TableRefreshType> = PublishSubject<TableRefreshType>()
    private var factory: ThreadDetailMessageCellViewModelFactory?

    init(userResolver: UserResolver,
         originMergeForwardId: String,
         context: ThreadDetailContext,
         chat: Chat,
         message: Message) {
        self.userResolver = userResolver
        self.originMergeForwardId = originMergeForwardId
        self.context = context
        self.chat = chat
        let copyMessage = message.copy()
        /// MergeForwardContent是class类型，需要做一次深拷贝
        if let content = copyMessage.content as? MergeForwardContent {
            copyMessage.content = content.copy()
        }
        self.message = copyMessage
        self.message = message
        self.addObserver()
        Self.logger.info("originMergeForwardId: ---- \(originMergeForwardId)")
    }

    func addObserver() {
        generalSettings?.is24HourTime.asObservable()
            .skip(1)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                self?.refreshUIOnTimeStyleChange()
            }).disposed(by: disposeBag)
    }

    func loadData() {
        let chat = self.chat
        dataQueue.async { [weak self] in
            guard let self = self else { return }
            fixMergeForwardContent(self.message)
            guard let threadMessage = self.threadMessage, let vmFactory = self.factory else { return }
            self.uiDataSource = [[vmFactory.create(with: ThreadDetailMetaModel(message: threadMessage.rootMessage,
                                                                                    isPrivateThread: true,
                                                                                    originMergeForwardId: self.originMergeForwardId,
                                                                                    getChat: { chat }),
                                                   metaModelDependency: self.getCellDependency())],
                                 threadMessage.replyMessages.map({ (message) -> ThreadDetailCellViewModel in
                                 vmFactory.create(with: ThreadDetailMetaModel(message: message,
                                                                                      isPrivateThread: true,
                                                                                      originMergeForwardId: self.originMergeForwardId,
                                                                                      getChat: { chat }),
                                                  metaModelDependency: self.getCellDependency())
                                 })]
            self.tableRefreshPublish.onNext(.refreshTable)
        }
    }

    func constructThreadMessageAndFactoryData() {
        guard let messageContent = self.message.content as? MergeForwardContent,
              let thread = messageContent.thread,
              !messageContent.messages.isEmpty else {
            return
        }
        Self.logger.info("messagesCount --- \(messageContent.messages.count)")
        var replyMessages = messageContent.messages
        let rootMessage = replyMessages.removeFirst()
        if rootMessage.threadId.isEmpty {
            rootMessage.threadId = thread.id
        }
        let threadMessage = ThreadMessage(thread: thread, rootMessage: rootMessage, replyMessages: replyMessages)
        let threadWrapper = threadWrappperItem(thread: thread)
        let factory = ThreadDetailMessageCellViewModelFactory(
            threadWrapper: threadWrapper,
            context: context,
            registery: ThreadDetailSubFactoryRegistery(context: context),
            threadMessage: threadMessage,
            cellLifeCycleObseverRegister: ThreadDetailCellLifeCycleObseverRegister(),
            messageTypeOfDisableAction: [.calendar, .generalCalendar, .shareCalendarEvent, .todo]
        )
        self.factory = factory
        self.threadMessage = threadMessage
    }

    func showHeader(section: Int) -> Bool {
        return section == replysSection
    }
    func showFooter(section: Int) -> Bool {
        return section == threadMessageSection
    }

    func showReplyMessageLastSepratorLine(section: Int) -> Bool {
        return false
    }

    func replyCount() -> Int {
        return Int(threadMessage?.thread.replyCount ?? 0)
    }

    func replysIndex() -> Int {
        return replysSection
    }

    func cellViewModel(by id: String) -> ThreadDetailCellViewModel? {
        return nil
    }

    func findMessageIndexBy(id: String) -> IndexPath? {
        return nil
    }

    func loadMoreNewMessages(finish: ((ScrollViewLoadMoreResult) -> Void)?) {

    }

    func loadMoreOldMessages(finish: ((ScrollViewLoadMoreResult) -> Void)?) {

    }

    // MARK: - 多选相关
    /// 获取被选中的消息
    func getPickedMessage() -> [Message] {
        let cellViewModels = uiDataSource
        var pickedMessages = [Message]()
        cellViewModels.forEach { (cellVMs) in
            cellVMs.forEach({ (cellViewModel) in
                if let vm = cellViewModel as? ThreadDetailRootCellViewModel,
                    vm.checked {
                    pickedMessages.append(vm.message)
                } else if let vm = cellViewModel as? ThreadDetailMessageCellViewModel,
                    vm.checked {
                    pickedMessages.append(vm.message)
                }
            })
        }

        return pickedMessages
    }

    func startMultiSelect(by messageId: String) {
        dataQueue.async { [weak self] in
            guard let self = self else { return }
            guard let indexPath = self.indexPath(by: messageId) else {
                return
            }
            self.inSelectMode.accept(true)
            let cellViewModel = self.uiDataSource[indexPath.section][indexPath.row]
            (cellViewModel as? ThreadDetailMessageCellViewModel)?.checked = true
            self.pickedMessages.accept(self.getPickedMessage())
            self.tableRefreshPublish.onNext(.startMultiSelect(startIndex: indexPath))
        }
    }

    func finishMultiSelect() {
        dataQueue.async { [weak self] in
            guard let self = self else { return }
            self.uiDataSource.forEach({ (cellViewModels) in
                cellViewModels.forEach({ (viewModel) in
                    (viewModel as? ThreadDetailMessageCellViewModel)?.checked = false
                })
            })
            self.inSelectMode.accept(false)
            self.tableRefreshPublish.onNext(.finishMultiSelect)
        }
    }

    func toggleSelectedMessage(by messageId: String) {
        dataQueue.async { [weak self] in
            guard let self = self else { return }
            self.pickedMessages.accept(self.getPickedMessage())
            self.tableRefreshPublish.onNext(.refreshTable)
        }
    }

    func indexPath(by messageId: String) -> IndexPath? {
        for (section, viewModels) in self.uiDataSource.enumerated() {
            if let index = viewModels.firstIndex(where: { (cellViewModel) -> Bool in
                if let viewModel = cellViewModel as? HasMessage {
                    return viewModel.message.id == messageId
                }
                return false
            }) {
                return IndexPath(item: index, section: section)
            }
        }
        return nil
    }

    func refreshUIOnTimeStyleChange() {
        self.refreshRenders()
        self.tableRefreshPublish.onNext(.refreshTable)
    }

    // MARK: - iPad适配
    func onResize() {
        dataQueue.async { [weak self] in
            guard let self = self else { return }
            for data in self.uiDataSource {
                data.forEach { (cellVM) in
                    cellVM.onResize()
                }
            }
            self.tableRefreshPublish.onNext(.refreshTable)
        }
    }
    func refreshRenders() {
        for cellvm in self.uiDataSource[threadMessageSection] {
            cellvm.calculateRenderer()
        }
        for cellvm in self.uiDataSource[replysSection] {
            cellvm.calculateRenderer()
        }
    }

    private func getCellDependency() -> ThreadDetailCellMetaModelDependency {
        return ThreadDetailCellMetaModelDependency(
            contentPadding: 0,
            contentPreferMaxWidth: { [weak self] message in
                return self?.getContentPreferMaxWidth(message) ?? 0
            }
        )
    }
}

extension ThreadPostForwardDetailViewModel: DataSourceAPI {
    func reloadRow(by messageId: String, animation: UITableView.RowAnimation) {
        guard !messageId.isEmpty else {
            return
        }
        func calculateRenderer(datas: [[ThreadDetailCellViewModel]]) -> IndexPath? {
            for (section, sectionDatas) in datas.enumerated() {
                for (row, cellVM) in sectionDatas.enumerated() {
                    if let messageCellVM = cellVM as? HasMessage, messageCellVM.message.id == messageId {
                        cellVM.calculateRenderer()
                        return IndexPath(row: row, section: section)
                    }
                }
            }
            return nil
        }
        self.dataQueue.async { [weak self] in
            if let indexPath = calculateRenderer(datas: self?.uiDataSource ?? []) {
                self?.tableRefreshPublish.onNext(.messagesUpdate(indexs: [indexPath], guarantLastCellVisible: false))
            }
        }
    }
    var traitCollection: UITraitCollection? {
        return nil
    }

    func processMessageSelectedEnable(message: Message) -> Bool {
        return true
    }

    var scene: ContextScene {
        return .threadPostForwardDetail
    }

    func filter<M: CellMetaModel, D: CellMetaModelDependency, T: PageContext>(_ predicate: (MessageCellViewModel<M, D, T>) -> Bool) -> [MessageCellViewModel<M, D, T>] {
        return uiDataSource
            .flatMap { $0 }
            .compactMap { $0 as? MessageCellViewModel<M, D, T> }
            .filter(predicate)
    }

    func pauseDataQueue(_ pause: Bool) {}

    func reloadTable() {
        self.tableRefreshPublish.onNext(.refreshTable)
    }

    func reloadRows(by messageIds: [String], doUpdate: @escaping (Message) -> Message?) {}

    func deleteRow(by messageId: String) {
    }

    func getContentPreferMaxWidth(_ message: Message) -> CGFloat {
        // rootMessage
        if message.threadId == message.id {
            return hostUIConfig.size.width - 16 - 16
        } // reply message
        else {
            return hostUIConfig.size.width - 52 - 16
        }
    }

    func currentTopNotice() -> BehaviorSubject<ChatTopNotice?>? {
        return nil
    }
}
