//
//  DetailCommentViewModel.swift
//  Todo
//
//  Created by 张威 on 2021/3/4.
//

import RxSwift
import RxCocoa
import LarkContainer
import TodoInterface
import RustPB
import LarkTimeFormatUtils
import EditTextView
import LarkAccountInterface
import Foundation
import LarkEmotion
import UniverseDesignFont

/// Detail - Comment - ViewModel

final class DetailCommentViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    /// 错误处理
    typealias ErrorHandler = (_ errMsg: String) -> Void

    enum ListUpload {
        case fullReload             // 更新所有 cells
        case cellReload(index: Int) // 更新指定 cell
    }

    /// tableView 数据变化
    var onListUpdate: ((ListUpload) -> Void)?
    // 是否需要立刻刷新，默认是false的原因是需要等待重复任务的parentTodo才一起刷新
    private var updateImmediately: Bool = false
    private var loadFinished: Bool = false
    private var innerCellItems = [InnerCellItem]()
    private var innerHeaderData = DetailCommentHeaderViewData()
    @ScopedInjectedLazy private var commentNoti: CommentNoti?
    @ScopedInjectedLazy private var commentApi: TodoCommentApi?
    @ScopedInjectedLazy private var fetchApi: TodoFetchApi?
    @ScopedInjectedLazy private var messengerDependency: MessengerDependency?
    @ScopedInjectedLazy private var passportService: PassportUserService?
    @ScopedInjectedLazy private var timeService: TimeService?
    @ScopedInjectedLazy private var richContentService: RichContentService?
    private let cellItemSorter: (InnerCellItem, InnerCellItem) -> Bool
    private var todoId: String { store.state.scene.todoId ?? "" }

    private let disposeBag = DisposeBag()
    private var lastLoadMoreDisposable: Disposable?

    private let store: DetailModuleStore

    // 心跳 timer
    private var heartbeatTimer: Timer?
    private var currentAccountUser: Rust.User?

    private lazy var timeFormatOption: LarkTimeFormatUtils.Options = {
        var options = LarkTimeFormatUtils.Options()
        options.dateStatusType = .relative
        options.timePrecisionType = .minute
        options.is12HourStyle = timeService?.rx12HourStyle.value ?? false
        options.timeZone = timeService?.rxTimeZone.value ?? .current
        return options
    }()

    init(resolver: UserResolver, store: DetailModuleStore) {
        self.userResolver = resolver
        self.store = store
        self.cellItemSorter = { $0.comment.position < $1.comment.position }
    }

    deinit {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }

    /// 初始化，返回布尔值，描述模块是否可用
    func setup() -> Driver<Bool> {
        store.rxInitialized()
            .observeOn(MainScheduler.asyncInstance)
            .map { [weak self] _ -> Bool in
                guard let state = self?.store.state else { return false }
                return state.scene.isForEditing && state.permissions.comment.isReadable
            }
            .do(onSuccess: { [weak self] isAvailable in
                guard let self = self else { return }
                if isAvailable {
                    self.setupState()
                    self.loadEarlierComments(forFirst: true).subscribe().disposed(by: self.disposeBag)
                    self.setupHeartbeat()
                    self.setupNotiHandler()
                }
            })
            .asDriver(onErrorJustReturn: false)
    }

    func loadMore() {
        lastLoadMoreDisposable?.dispose()
        lastLoadMoreDisposable = loadEarlierComments().subscribe()
    }

    func retryForFailed() {
        loadEarlierComments().subscribe().disposed(by: disposeBag)
    }

    // 设置心跳：定时向 server 发送心跳，维系联系，以便 server 能向端上发送 comment 或者 reaction 的更新
    private func setupHeartbeat() {
        let doSend = { [weak self] in
            guard let self = self, let commentApi = self.commentApi else { return }
            commentApi.sendCommentHeartbeat(either: self.todoId, or: nil).subscribe().disposed(by: self.disposeBag)
        }
        doSend()
        let timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in doSend() }
        RunLoop.main.add(timer, forMode: .common)
        heartbeatTimer = timer
    }

    // 向上拉取更早的评论
    private func loadEarlierComments(forFirst: Bool = false) -> Observable<Void> {
        guard let commentApi = commentApi else { return .just(void) }
        let updateLoadStatus = { [weak self] (status: DetailCommentLoadStatus) in
            guard let self = self else { return }
            self.innerHeaderData.status = status
            self.onListUpdate?(.fullReload)
        }
        var delaySwitchToLoadingDisposable: Disposable?
        if forFirst {
            innerHeaderData.status = .loadingFirstSilently
            onListUpdate?(.fullReload)
            updateLoadStatus(.loadingFirstSilently)
            // 首次加载，延迟 1s 才将 list 从 loadingFirstSilently 切换到 loadingFirst；
            // 避免 loading 时间太短导致的的闪烁
            delaySwitchToLoadingDisposable = MainScheduler.instance
                .scheduleRelative((), dueTime: .milliseconds(1_000)) { _ in
                    updateLoadStatus(.loadingFirst)
                    return Disposables.create()
                }
        } else {
            updateLoadStatus(innerCellItems.isEmpty ? .emptyData : .loadingMore)
        }
        let position: Int32
        if let top = innerCellItems.first?.comment.position {
            position = top - 1
        } else {
            position = .max
        }
        return commentApi.getUpComments(from: position, count: 10, todoId: todoId)
            .observeOn(MainScheduler.asyncInstance)
            .do(
                onNext: { [weak self] (comments, hasMore) in
                    delaySwitchToLoadingDisposable?.dispose()
                    let comments = comments.filter { $0.status != .deleted }
                    guard let self = self else { return }
                    self.innerCellItems = (comments.map { InnerCellItem(
                        userResolver: self.userResolver,
                        comment: $0,
                        activeChattersCallback: { [weak self] in self?.getActiveChatters() }
                    )
                    } + self.innerCellItems)
                    .lf_unique(by: \.comment.id)
                    .sorted(by: self.cellItemSorter)
                    var status: DetailCommentLoadStatus = hasMore ? .hasMore : .noMore
                    if self.innerCellItems.isEmpty {
                        status = .emptyData
                    }
                    self.loadFinished = true
                    self.innerHeaderData = self.createHeaderRichContent(status)
                    updateLoadStatus(status)
                },
                onError: { err in
                    delaySwitchToLoadingDisposable?.dispose()
                    Detail.logger.error("load comments failed. err: \(err)")

                    if case .some(.todoOfCommentNotFound) = Rust.makeUserError(from: err).bizCode() {
                        updateLoadStatus(.emptyData)
                        return
                    }

                    if self.innerCellItems.isEmpty {
                        updateLoadStatus(.loadFailed)
                    }
                }
            )
            .map { _ in void }
    }

    // 向下拉取更晚的评论
    private func loadLaterComments() -> Observable<Void> {
        guard let position = innerCellItems.last?.comment.position, let commentApi = commentApi else {
            Detail.assertionFailure()
            return .just(void)
        }
        return commentApi.getDownComments(from: position + 1, count: 10, todoId: todoId)
            .observeOn(MainScheduler.asyncInstance)
            .do(
                onNext: { [weak self] (comments, hasMore) in
                    let comments = comments.filter { $0.status != .deleted }
                    guard let self = self else { return }
                    self.innerCellItems = (self.innerCellItems + comments.map { InnerCellItem(
                        userResolver: self.userResolver,
                        comment: $0,
                        activeChattersCallback: { [weak self] in self?.getActiveChatters() }
                    )
                    })
                    .lf_unique(by: \.comment.id)
                    .sorted(by: self.cellItemSorter)
                    if self.innerCellItems.isEmpty {
                        self.innerHeaderData.status = .emptyData
                    } else {
                        self.innerHeaderData.status = hasMore ? .hasMore : .noMore
                    }
                    self.onListUpdate?(.fullReload)
                },
                onError: { err in
                    Detail.logger.error("load comments failed. err: \(err)")
                    if self.innerCellItems.isEmpty {
                        self.innerHeaderData.status = .loadFailed
                        self.onListUpdate?(.fullReload)
                    }
                }
            )
            .map { _ in void }
    }

    private func getActiveChatters() -> Set<String> {
        store.state.activeChatters
    }

}

// MARK: - Store State

extension DetailCommentViewModel {

    private func setupState() {
        store.rxValue(forKeyPath: \.parentTodo)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] parent in
                guard let self = self, let parent = parent, !parent.isLoadSdk else { return }
                if !self.updateImmediately {
                    self.updateImmediately = true
                    self.innerHeaderData = self.createHeaderRichContent(self.innerHeaderData.status)
                    self.onListUpdate?(.fullReload)
                }
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - Noti Handler

extension DetailCommentViewModel {

    /// 监听通知
    private func setupNotiHandler() {
        let todoId = self.todoId
        commentNoti?.rxCommentSubject.filter { $0.todoId == todoId }
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] body in
                self?.handleCommentNoti(body)
            })
            .disposed(by: disposeBag)

        commentNoti?.rxCommentReactionSubject.filter { $0.todoId == todoId }
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] body in
                self?.handleReactionNoti(body)
            })
            .disposed(by: disposeBag)
        store.rxValue(forKeyPath: \.activeChatters)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] _ in
                self?.reloadItemsAtStatus()
            })
            .disposed(by: disposeBag)
    }

    private func reloadItemsAtStatus() {
        var needReload = false
        for index in innerCellItems.indices {
            if innerCellItems[index].updateAtIfNeeded() {
                needReload = true
            }
        }
        if needReload {
            onListUpdate?(.fullReload)
        }
    }

    // 处理 comment 通知
    private func handleCommentNoti(_ body: CommentNotiBody) {
        if innerCellItems.isEmpty {
            loadEarlierComments().subscribe().disposed(by: disposeBag)
        } else {
            if let index = innerCellItems.firstIndex(where: { $0.comment.id == body.comment.id }) {
                // body.comment 已在列表中，直接替换，或者删除
                if body.comment.status == .deleted {
                    innerCellItems.remove(at: index)
                    onListUpdate?(.fullReload)
                } else {
                    innerCellItems[index] = InnerCellItem(userResolver: userResolver, comment: body.comment) { [weak self] in self?.getActiveChatters() }
                    onListUpdate?(.cellReload(index: index))
                }
            } else {
                guard body.comment.status != .deleted else {
                    Detail.logger.info("got a comment from noti, but it is deleted")
                    return
                }
                let (first, last) = (innerCellItems.first!, innerCellItems.last!)
                if body.comment.position < first.comment.position {
                    if innerHeaderData.status == .noMore {
                        // 收到更早的消息，直接刷新
                        // 收到更早的消息，直接刷新
                        innerCellItems.insert((InnerCellItem(userResolver: userResolver, comment: body.comment) { [weak self] in self?.getActiveChatters() }), at: 0)
                        innerCellItems.sort(by: cellItemSorter)
                        onListUpdate?(.fullReload)
                    } else if innerHeaderData.status == .loadingMore {
                        // 如果正在 loading，则重新触发，避免新 push 的数据被漏掉了
                        lastLoadMoreDisposable?.dispose()
                        lastLoadMoreDisposable = loadEarlierComments().subscribe()
                    } else {
                        Detail.logger.info("逻辑不应该执行到这里")
                    }
                } else if body.comment.position > last.comment.position {
                    loadLaterComments().subscribe().disposed(by: disposeBag)
                } else {
                    innerCellItems.append(InnerCellItem(userResolver: userResolver, comment: body.comment) { [weak self] in self?.getActiveChatters() })
                    innerCellItems.sort(by: cellItemSorter)
                    onListUpdate?(.fullReload)
                }
            }
        }
    }

    // 处理 reaction 通知
    private func handleReactionNoti(_ body: CommentReactionNotiBody) {
        guard let index = innerCellItems.firstIndex(where: { $0.comment.id == body.commentId }) else {
            Detail.logger.info("got a reaction push, but not in list")
            return
        }
        innerCellItems[index].innerReactions.synced = body.reactions.filter { reaction in
            let reactionKey = reaction.type
            let isDeleted = EmotionResouce.shared.isDeletedBy(key: reactionKey)
            return !isDeleted
        }
        innerCellItems[index].innerReactions.clearDisplayInfo()
        onListUpdate?(.fullReload)
    }

}

// MARK: - List Data: Inner

extension DetailCommentViewModel {

    /// reaction action. 描述当前用户操作的 reaction action
    struct ReactionAction {
        /// action id
        var actionId: String
        // reaction type
        var type: String
        /// 是否完成（收到 server 回调，表示成功）
        var completed: Bool
        var userId: String
        var userName: String
        // 新增 or 删除
        var isAdding: Bool
    }

    private struct InnerCellItem: DetailCommentCellDataType {
        struct ReactionContext {
            /// 从 server/rust 同步来的
            var synced = [Rust.Reaction]()
            /// actions by user
            var actions = [ReactionAction]()
            var displayInfo: [DetailCommentReactionInfo]?

            /// 构建 display info
            mutating func buildDisplayInfo() {
                guard displayInfo == nil else { return }
                var infos = [DetailCommentReactionInfo]()
                var typeIndexDict = [String: Int]()
                for item in synced where !item.users.isEmpty {
                    let info = DetailCommentReactionInfo(
                        reactionKey: item.type,
                        users: item.users
                            .map { DetailCommentReactionUser(id: $0.userID, name: $0.name) }
                            .lf_unique(by: \.id)
                    )
                    typeIndexDict[item.type] = infos.count
                    infos.append(info)
                }
                for action in actions {
                    if let existIndex = typeIndexDict[action.type] {
                        var users = infos[existIndex].users
                        if action.isAdding {
                            // 自己，优先放在前面
                            users.insert(DetailCommentReactionUser(id: action.userId, name: action.userName), at: 0)
                        } else {
                            users.removeAll(where: { $0.id == action.userId })
                        }
                        infos[existIndex].users = users.lf_unique(by: \.id)
                    } else {
                        if action.isAdding {
                            let info = DetailCommentReactionInfo(
                                reactionKey: action.type,
                                users: [DetailCommentReactionUser(id: action.userId, name: action.userName)]
                            )
                            typeIndexDict[action.type] = infos.count
                            infos.append(info)
                        }
                    }
                }
                displayInfo = infos.filter { !$0.users.isEmpty }
            }

            /// 清除 display info
            mutating func clearDisplayInfo() {
                displayInfo = nil
            }
        }

        init(userResolver: UserResolver, comment: Rust.Comment, activeChattersCallback: (() -> Set<String>?)?) {
            self.userResolver = userResolver
            self.activeChattersCallback = activeChattersCallback
            self.comment = comment
            var reactions = ReactionContext()
            reactions.synced = comment.reactions.filter { reaction in
                let reactionKey = reaction.type
                let isDeleted = EmotionResouce.shared.isDeletedBy(key: reactionKey)
                return !isDeleted
            }
            self.innerReactions = reactions
            guard !comment.needBlock else {
                self.images = []
                self.attachments = []
                return
            }
            self.images = comment.attachments.compactMap { attachment -> Rust.ImageSet? in
                guard attachment.type == .image else { return nil }
                return attachment.imageSet
            }
            self.attachments = comment.fileAttachments.filter { $0.type == .file }
            setNeedFoldAttachment(true)
            _ = updateAtIfNeeded()
        }

        var activeChattersCallback: (() -> Set<String>?)?

        var userResolver: LarkContainer.UserResolver

        var commentId: String { comment.cid }
        var comment: Rust.Comment
        var innerReactions = ReactionContext()

        var richContent: Rust.RichContent? {
            if comment.needBlock {
                var content = Rust.RichContent()
                content.richText = Utils.RichText.makeRichText(from: I18N.Todo_Task_UnsupportedComment)
                return content
            }
            return comment.richContent.richText.isEmpty ? nil : comment.richContent
        }

        var images: [Rust.ImageSet]

        let attachments: [Rust.Attachment]
        var needFoldAttachment = true
        var attachmentCellDatas = [DetailAttachmentContentCellData]()
        var attachmentFooterData: DetailAttachmentFooterViewData?

        var reactions: [DetailCommentReactionInfo] { innerReactions.displayInfo ?? [] }

        var avatar: AvatarSeed {
            AvatarSeed(avatarId: comment.fromUser.userID, avatarKey: comment.fromUser.avatarKey)
        }

        var name: String { comment.fromUser.name }
        var timeStr: String = ""



        mutating func setNeedFoldAttachment(_ needFold: Bool) {
            needFoldAttachment = needFold
            let attachmentFoldCount = 4
            let footerData: DetailAttachmentFooterViewData
            let cellDatas: [DetailAttachmentContentCellData]
            if needFoldAttachment {
                let isFold = attachments.count > attachmentFoldCount
                footerData = .init(
                    hasMoreState: isFold ? .hasMore(moreCount: attachments.count - attachmentFoldCount) : .noMore,
                    isAddViewHidden: true
                )
                let finalAttachments = Array(attachments.prefix(attachmentFoldCount))
                cellDatas = DetailAttachment.attachments2CellDatas(finalAttachments, canDelete: false)
            } else {
                footerData = .init(
                    hasMoreState: .noMore,
                    isAddViewHidden: true
                )
                cellDatas = DetailAttachment.attachments2CellDatas(attachments, canDelete: false)
            }
            attachmentCellDatas = cellDatas.sorted(by: { $0.uploadTime < $1.uploadTime })
            attachmentFooterData = footerData
        }

        mutating func updateAtIfNeeded() -> Bool {
            guard let activeChatters = activeChattersCallback?() else { return false }
            let atElements = comment.richContent.richText.elements.filter { $0.value.tag == .at }
            guard !atElements.isEmpty else { return false }
            var allElements = comment.richContent.richText.elements

            var needChange = false
            for (id, elm) in atElements {
                var atPro = elm.property.at
                let newIsOuter = !activeChatters.contains(atPro.userID)
                if atPro.isOuter != newIsOuter {
                    needChange = true
                    atPro.isOuter = newIsOuter
                    var newElm = elm
                    newElm.property.at = atPro
                    allElements[id] = newElm
                }
            }

            guard needChange else { return false }
            comment.richContent.richText.elements = allElements
            return true
        }
    }

    private func lazyComplementCellItem(_ cellItem: inout InnerCellItem) {
        // time str
        if cellItem.timeStr.isEmpty {
            let date = Date(timeIntervalSince1970: TimeInterval(cellItem.comment.createMilliTime / 1_000))
            var timeStr = TimeFormatUtils.formatDateTime(from: date, with: timeFormatOption)
            if case .edited = cellItem.comment.status {
                timeStr = "\(timeStr) \(I18N.Todo_Task_EditedComment)"
            }
            cellItem.timeStr = timeStr
        }

        if cellItem.innerReactions.displayInfo == nil {
            cellItem.innerReactions.buildDisplayInfo()
        }
    }

    private func appendCellItems(with comments: [Rust.Comment]) {
        innerCellItems.append(contentsOf: comments.map { InnerCellItem(
            userResolver: userResolver,
            comment: $0,
            activeChattersCallback: { [weak self] in self?.getActiveChatters() }
        )
        })
        innerCellItems.sort(by: cellItemSorter)
        if !innerCellItems.isEmpty && innerHeaderData.status == .emptyData {
            innerHeaderData.status = .noMore
        }
        onListUpdate?(.fullReload)
    }

    private func deleteCellItem(with commentId: String) {
        let oldCount = innerCellItems.count
        innerCellItems = innerCellItems.filter { $0.comment.id != commentId }
        if oldCount != innerCellItems.count {
            if innerCellItems.isEmpty && innerHeaderData.status != .emptyData {
                innerHeaderData.status = .emptyData
            }
            onListUpdate?(.fullReload)
        }
    }

    private func updateCellItem(with comment: Rust.Comment) {
        var needsReload = false
        for i in 0..<innerCellItems.count where innerCellItems[i].comment.id == comment.id {
            innerCellItems[i] = InnerCellItem(userResolver: userResolver, comment: comment) { [weak self] in self?.getActiveChatters() }
            needsReload = true
        }
        if needsReload {
            onListUpdate?(.fullReload)
        }
    }

    private func safeCellItem(at index: Int) -> InnerCellItem? {
        guard index >= 0 && index < innerCellItems.count else {
            assertionFailure()
            return nil
        }
        lazyComplementCellItem(&innerCellItems[index])
        return innerCellItems[index]
    }

    private func createHeaderRichContent(_ status: DetailCommentLoadStatus) -> DetailCommentHeaderViewData {
        guard innerHeaderData.hasContent() == false else { return innerHeaderData }
        guard updateImmediately, loadFinished, let todo = store.state.todo else { return .init(status: status) }

        let attrText = MutAttrText()
        var linkActions: [NSRange: DetailCommentHeaderViewData.Action] = .init()

        let attributes: [AttrText.Key: Any] = [
            .font: UDFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.ud.textTitle
        ]
        let linkAttr: [AttrText.Key: Any] = [
            .font: UDFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.ud.textLinkNormal
        ]

        // parent todo
        if let parent = store.state.parentTodo, let parentTodo = parent.todo,
            !parent.isLoadSdk, let richContentService = richContentService {
            let config = RichLabelContentBuildConfig(baseAttrs: linkAttr, lineSeperator: " ")
            var result = richContentService.buildLabelContent(with: parentTodo.richSummary, config: config).attrText
            if result.length == 0 {
                result = MutAttrText(string: I18N.Todo_Task_NoTitlePlaceholder, attributes: linkAttr)
            }
            let title = MutAttrText(attributedString: result)

            let maxLength = 20
            if title.length > maxLength {
                title.replaceCharacters(
                    in: NSRange(location: maxLength, length: title.length - maxLength),
                    with: .init(string: "...", attributes: linkAttr)
                )
            }

            let stringFunc = { (s1: String) -> String in
                return I18N.Todo_TaskDuplicatedFromTask_New_Text(s1)
            }
            let rawText = MutAttrText(
                string: stringFunc(title.string),
                attributes: attributes
            )
            if let summaryRange = Utils.RichText.getRange(for: title.string, with: { stringFunc($0) }),
               Utils.RichText.checkRangeValid(summaryRange, in: rawText) {
                rawText.replaceCharacters(in: summaryRange, with: title)
                let titleRange = NSRange(location: summaryRange.location, length: title.length)
                linkActions[titleRange] = .title(guid: parentTodo.guid)
            }
            attrText.append(rawText)
        } else {
            // todo create name
            let stringFunc = { (s1: String) -> String in
                return I18N.Todo_Task_ChangeLogUserCreatedTask(s1)
            }
            let userText = MutAttrText(
                string: stringFunc(todo.creator.name),
                attributes: attributes
            )
            if let userRange = Utils.RichText.getRange(for: todo.creator.name, with: { stringFunc($0) }),
               Utils.RichText.checkRangeValid(userRange, in: userText) {
                userText.addAttribute(.foregroundColor, value: UIColor.ud.textLinkNormal, range: userRange)
                linkActions = [userRange: .user(chatterId: todo.creatorID)]
            }
            attrText.append(userText)
        }

        // time
        let date = Date(timeIntervalSince1970: TimeInterval(todo.createMilliTime / 1_000))
        let timeStr = TimeFormatUtils.formatDateTime(from: date, with: timeFormatOption)
        let timeAttrText = AttrText(string: " \(timeStr)", attributes: [
            .font: UDFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.ud.textPlaceholder
        ])
        attrText.append(timeAttrText)

        return .init(
            linkActions: linkActions,
            richContent: RichLabelContent(id: "create_info", attrText: attrText),
            status: status
        )
    }

}

// MARK: - List Data

extension DetailCommentViewModel {

    enum CellAction: Int {
        case copy = 1, reply, edit, delete
    }

    enum LinkAction {
        case atUser(userInfo: Rust.RichText.Element.AtProperty)
        case anchorUrl(urlStr: String)
    }

    struct ReplyContext {
        var rootId: String
        var parentId: String
        var richContent: Rust.RichContent
    }

    func numberOfRows() -> Int {
        return innerHeaderData.hasContent() ? innerCellItems.count : 0
    }

    func headerData() -> DetailCommentHeaderViewData? {
        return innerHeaderData
    }

    func cellDataForRow(at index: Int) -> DetailCommentCellDataType? {
        return safeCellItem(at: index)
    }

    func commentIdForRow(at index: Int) -> String? {
        return safeCellItem(at: index)?.comment.id
    }

    func linkAction(for range: NSRange, at index: Int) -> LinkAction? {
        return nil
    }

    func replyContextForRow(at index: Int) -> ReplyContext? {
        guard let cellItem = safeCellItem(at: index) else { return nil }
        let fromUser = cellItem.comment.fromUser
        let todoUser = User(
            chatterId: fromUser.userID,
            tenantId: fromUser.tenantID,
            name: fromUser.name,
            avatarKey: fromUser.avatarKey
        )
        let richContent = Utils.RichText.makeRichContent(
            for: cellItem.comment.fromUser,
            isOuter: !store.state.activeChatters.contains(todoUser.chatterId)
        )
        return ReplyContext(
            rootId: cellItem.comment.replyRootID,
            parentId: cellItem.comment.id,
            richContent: richContent
        )
    }

    func imagesForRow(at index: Int) -> [Rust.ImageSet] {
        return safeCellItem(at: index)?.comment.attachments
            .compactMap { attachment -> Rust.ImageSet? in
                guard attachment.type == .image else { return nil }
                return attachment.imageSet
            }
            ?? []
    }

    /// Cell 支持的 actions
    func supportedActionForRow(at index: Int) -> [CellAction] {
        guard let cellItem = safeCellItem(at: index) else { return [] }
        let comment = cellItem.comment

        let isFromSelf = comment.fromUser.userID == userResolver.userID
        switch (comment.needBlock, isFromSelf) {
        case (true, true):
            return [.reply, .delete]
        case (true, false):
            return [.reply]
        case (false, false):
            return [.copy, .reply]
        case (false, true):
            return [.copy, .reply, .edit, .delete]
        }
    }

    /// Cell 支持的 copy 内容
    func copyStringForRow(at index: Int) -> String {
        guard let richContent = safeCellItem(at: index)?.comment.richContent else {
            return ""
        }
        return Utils.RichText.makePlainText(from: richContent, needsFixAnchor: false)
    }

    /// 评论的 senderId
    func senderIdForRow(at index: Int) -> String? {
        guard let cellItem = safeCellItem(at: index) else { return nil }
        return cellItem.comment.fromUser.userID
    }

}

// MARK: - View Action

extension DetailCommentViewModel {

    /// 发送评论
    func sendComment(
        with content: CommentInputContent,
        for scene: CommentInputScene,
        completion: @escaping (UserResponse<Void>) -> Void
    ) {
        var info = Rust.CreateCommentInfo()
        info.cid = UUID().uuidString
        info.content = content.richContent
        info.attachments = content.attachments
        info.fileAttachments = content.fileAttachments
        info.type = .richText

        let trackerTask = Tracker.Appreciable.Task(scene: .comment, event: .commentSend).resume()
        let trackerTypeKey = "type"

        let rxSendComment: Observable<Rust.Comment>?
        let onSendSucceed: (Rust.Comment) -> Void
        switch scene {
        case .edit(let commentId):
            rxSendComment = commentApi?.updateComment(
                byId: commentId,
                content: content.richContent,
                attachments: content.attachments,
                fileAttachments: content.fileAttachments,
                todoId: todoId
            )
            trackerTask.category[trackerTypeKey] = "edit"
            onSendSucceed = { [weak self] comment in
                self?.updateCellItem(with: comment)
            }
        case let .reply(parentId, rootId):
            info.replyParentID = parentId
            info.replyRootID = rootId
            trackerTask.category[trackerTypeKey] = "reply"
            fallthrough
        case .create:
            if trackerTask.category[trackerTypeKey] == nil {
                trackerTask.category[trackerTypeKey] = "new"
            }
            rxSendComment = commentApi?.createComment(withTodoId: todoId, info: info)
            onSendSucceed = { [weak self] comment in
                self?.appendCellItems(with: [comment])
            }
        }
        rxSendComment?.observeOn(MainScheduler.asyncInstance).take(1).asSingle()
            .subscribe(
                onSuccess: { [weak self] comment in
                    Detail.logger.info("create comment succeed. scene: \(scene.debugDescription)")
                    self?.syncAtUserToFollower(comment: comment)
                    onSendSucceed(comment)
                    trackerTask.complete()
                    completion(.success(void))
                },
                onError: { err in
                    Detail.logger.error("create comment failed. scene: \(scene.debugDescription), err: \(err)")
                    trackerTask.error(err)
                    let userErr: UserError
                    if let code = Rust.makeUserError(from: err).bizCode(),
                       code == .textNotAudit || code == .imageNotAudit {
                        userErr = .init(error: err, message: I18N.Todo_Report_FailedToSend())
                    } else {
                        userErr = Rust.makeUserError(from: err)
                    }
                    completion(.failure(userErr))
                }
            )
            .disposed(by: disposeBag)
    }

    func editInput(forId commentId: String) -> CommentInputContent {
        guard let comment = innerCellItems.first(where: { $0.comment.id == commentId })?.comment else {
            assertionFailure()
            return (richContent: Rust.RichContent(), attachments: [], fileAttachments: [])
        }
        return (
            richContent: comment.richContent,
            attachments: comment.attachments,
            fileAttachments: comment.fileAttachments
        )
    }

    func indexForComment(byId commentId: String) -> Int? {
        return innerCellItems.firstIndex(where: { $0.comment.id == commentId })
    }

    /// 删除 comment
    func deleteComment(at index: Int, onError: ErrorHandler? = nil) {
        guard let commentId = safeCellItem(at: index)?.comment.id else {
            assertionFailure()
            return
        }
        let trackerTask = Tracker.Appreciable.Task(scene: .comment, event: .commentDelete).resume()
        commentApi?.deleteComment(byId: commentId, todoId: todoId)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onNext: { _ in
                    Detail.logger.info("delete succeed")
                    self.deleteCellItem(with: commentId)
                    trackerTask.complete()
                },
                onError: { err in
                    Detail.logger.error("delete comment failed. err: \(err)")
                    onError?(Rust.displayMessage(from: err))
                    trackerTask.error(err)
                }
            )
            .disposed(by: disposeBag)
    }

    func doExpandAttachment(at index: Int) {
        guard safeCellItem(at: index) != nil else { return }
        innerCellItems[index].setNeedFoldAttachment(false)
        onListUpdate?(.cellReload(index: index))
    }

    func toggleReaction(withType type: String, at index: Int, onError: ErrorHandler? = nil) {
        guard let commentId = safeCellItem(at: index)?.comment.id else {
            assertionFailure()
            return
        }
        let needsRemove = innerCellItems[index].innerReactions.displayInfo?
            .first(where: { $0.reactionKey == type })?.users
            .contains(where: { $0.id == userResolver.userID })
            ?? false
        let actionId = optimisticUpdateReaction(wityType: type, index: index, isAdding: !needsRemove)

        let rxRet: Observable<Void>?
        let trackerTask: Tracker.Appreciable.Task
        if needsRemove {
            rxRet = commentApi?.deleteReaction(withType: type, commentId: commentId, todoId: todoId)
            trackerTask = .init(scene: .comment, event: .commentReactionDelete)
        } else {
            rxRet = commentApi?.insertReaction(withType: type, commentId: commentId, todoId: todoId)
            // 将用户使用的 reaction 同步到「最近使用」        
            messengerDependency?.updateRecentlyUsedReaction(reactionType: type).subscribe().disposed(by: disposeBag)
            trackerTask = .init(scene: .comment, event: .commentReactionAdd)
        }
        trackerTask.resume()
        rxRet?.observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onNext: { _ in
                    Detail.logger.info("add reaction succeed. type: \(type)")
                    trackerTask.complete()
                },
                onError: { [weak self] err in
                    self?.recoverReaction(wityActionId: actionId, commentId: commentId)
                    Detail.logger.error("add reaction failed. type: \(type). err: \(err)")
                    // 移除 action
                    onError?(Rust.displayMessage(from: err))
                    trackerTask.error(err)
                }
            )
            .disposed(by: disposeBag)
    }

    // 乐观更新 reaction
    private func optimisticUpdateReaction(wityType type: String, index: Int, isAdding: Bool) -> String {
        let actionId = UUID().uuidString
        guard let account = passportService?.user else { return actionId }
        var actions = innerCellItems[index].innerReactions.actions
        let newAction = { [weak self] (userName: String) in
            guard let self = self else { return }
            let newAction = ReactionAction(
                actionId: actionId,
                type: type,
                completed: false,
                userId: account.userID,
                userName: userName,
                isAdding: isAdding
            )
            actions.append(newAction)
            self.innerCellItems[index].innerReactions.actions = actions
            self.innerCellItems[index].innerReactions.clearDisplayInfo()
            self.onListUpdate?(.fullReload)
        }
        if let currentUser = currentAccountUser {
            newAction(currentUser.name)
        } else {
            fetchApi?.getUsers(byIds: [account.userID]).take(1).asSingle()
                .observeOn(MainScheduler.instance)
                .subscribe(
                    onSuccess: { [weak self] users in
                        guard let self = self, let user = users.first else {
                            newAction(account.localizedName)
                            return
                        }
                        self.currentAccountUser = user
                        newAction(user.name)
                    },
                    onError: { err in
                        newAction(account.localizedName)
                        Detail.logger.info("updateUser failed, \(err)")
                    }
                )
                .disposed(by: disposeBag)
        }
        return actionId
    }

    // 恢复 reaction
    private func recoverReaction(wityActionId actionId: String, commentId: String) {
        guard let index = innerCellItems.firstIndex(where: { $0.comment.id == commentId }) else {
            return
        }
        innerCellItems[index].innerReactions.actions.removeAll(where: { $0.actionId == actionId })
        onListUpdate?(.fullReload)
    }

    private func syncAtUserToFollower(comment: Rust.Comment) {
        var userIds = [String]()
        let richText = comment.richContent.richText
        for atEleId in richText.atIds {
            if let userId = richText.elements[atEleId]?.property.at.userID,
               !userId.isEmpty {
                userIds.append(userId)
            }
        }
        let idSet = Set(store.state.followers.map { $0.identifier })
        userIds = userIds.filter { !idSet.contains($0) }
        guard !userIds.isEmpty else { return }

        fetchApi?.getUsers(byIds: userIds)
            .map { $0.map { Follower(member: .user(User(pb: $0))) } }
            .take(1)
            .asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { [weak self] followers in
                    Detail.logger.error("syncAtUser2Follower succeed. userIds: \(userIds)")
                    self?.store.dispatch(.appendFollowers(followers))
                },
                onError: { err in
                    Detail.logger.error("syncAtUser2Follower err: \(err)")
                }
            )
            .disposed(by: disposeBag)
    }
}
