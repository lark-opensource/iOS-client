//
//  ChatCardViewModel.swift
//  Todo
//
//  Created by 张威 on 2020/12/5.
//

import LarkMessageBase
import AsyncComponent
import LarkModel
import RichLabel
import LarkContainer
import LarkAccountInterface
import RustPB
import LarkEmotion
import RxSwift
import LarkNavigation
import UniverseDesignIcon
import UIKit
import UniverseDesignFont

/// 描述卡片支持的组件
private struct Components: OptionSet {
    let rawValue: UInt

    init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    /// 标题
    static let summary = Components(rawValue: 1 << 0)
    /// 截止时间
    static let time = Components(rawValue: 1 << 2)
    /// 负责人
    static let owner = Components(rawValue: 1 << 3)
    /// 每日提醒
    static let dailyRemind = Components(rawValue: 1 << 4)
    /// 打开任务中心
    static let openCenter = Components(rawValue: 1 << 5)

    /// 根据类型，决策可用的 components
    static func availables(for subType: Basic_V1_TodoOperationContent.TypeEnum) -> Components {
        switch subType {
        case .assign, .complete, .incomplete, .follow, .create, .delete, .share,
             .completeSelf, .completeAssignee, .restoreSelf, .restoreAssignee, .assignOwner:
            return [.summary, .owner, .time, openCenter]
        case .dailyRemind:
            return [.dailyRemind]
        @unknown default:
            assertionFailure()
            return [.summary, .owner, .time]
        }
    }
}

struct ChatCardContentConfig {
    let needBottomPadding: Bool?

    init(needBottomPadding: Bool? = nil) {
        self.needBottomPadding = needBottomPadding
    }
}

class ChatCardViewModel<
    M: CellMetaModel,
    D: CellMetaModelDependency,
    C: PageContext
>: MessageSubViewModel<M, D, C> {

    override var identifier: String { "TodoChatCard" }

    // swiftlint:disable force_cast
    private var content: TodoContent { message.content as! TodoContent }
    // swiftlint:enable force_cast


    private var timeService: TimeService? {
        try? context.userResolver.resolve(assert: TimeService.self)
    }
    private var richContentService: RichContentService? {
        try? context.userResolver.resolve(assert: RichContentService.self)
    }
    private var anchorService: AnchorService? {
        try? context.userResolver.resolve(assert: AnchorService.self)
    }
    private var completeService: CompleteService? {
        try? context.userResolver.resolve(assert: CompleteService.self)
    }
    private var navigationService: NavigationService? {
        try? context.userResolver.resolve(assert: NavigationService.self)
    }
    private var operateApi: TodoOperateApi? {
        try? context.userResolver.resolve(assert: TodoOperateApi.self)
    }

    private var currentUserId: String { context.userID }
    private let uuid: String = UUID().uuidString
    private let disposeBag = DisposeBag()
    private let chatCardContentConfig: ChatCardContentConfig
    typealias TodoDetail = Basic_V1_TodoDetail

    override var contentConfig: ContentConfig? {
        var config = ContentConfig(
            hasMargin: false,
            backgroundStyle: .white,
            maskToBounds: true,
            supportMutiSelect: true,
            hasBorder: true
        )
        config.isCard = true
        return config
    }

    init(metaModel: M, metaModelDependency: D, context: C, binder: ComponentBinder<C>, chatCardContentConfig: ChatCardContentConfig = ChatCardContentConfig()) {
        self.chatCardContentConfig = chatCardContentConfig
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: binder)
        // 对于 daily remind 卡片，时区发生变化时，刷新卡片
        if availableComponents.contains(.dailyRemind) {
            timeService?.rxTimeZone.map(\.identifier)
                .distinctUntilChanged()
                .skip(1)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    self.update(component: self.component)
                })
                .disposed(by: disposeBag)
        }
        ChatCard.Track.viewCard(with: trackCommonParams)
    }

    private var availableComponents: Components { .availables(for: content.pbModel.operationType) }

    private let currentTime = Int64(Date().timeIntervalSince1970)

    var logInfo: String { content.logInfo }

    var todoSource: Rust.TodoSource { content.pbModel.todoDetail.source }

    var isCompleted: Bool { completeService?.state(for: generateTodo()).isCompleted ?? false }

    var isDeleted: Bool {
        let todoDetail = content.pbModel.todoDetail
        return todoDetail.hasDeletedMilliTime && todoDetail.deletedMilliTime > 0
    }

    var isDailyReminder: Bool { availableComponents.contains(.dailyRemind) }

    var guid: String { content.pbModel.todoDetail.guid }

    var isExpired: Bool { content.pbModel.msgStatus == .deleted }

    var isFromBot: Bool { content.isFromBot }

    var chatId: String { content.chatId }

    var messageId: String { content.messageId }

    var hasReaction: Bool { !message.reactions.isEmpty }

    var isFromThread: Bool { content.isFromThread }

    var needBottomPadding: Bool {
        if let needBottomPadding = self.chatCardContentConfig.needBottomPadding {
            return needBottomPadding
        }
        return (self.context.scene == .newChat && self.message.showInThreadModeStyle) || isFromThread || !hasReaction
    }

    var trackCommonParams: ChatCard.Track.CommonParameters {
        let trackType: ChatCard.Track.TrackType
        switch content.pbModel.operationType {
        case .assign, .complete, .incomplete, .follow, .delete,
             .completeSelf, .completeAssignee, .restoreSelf, .restoreAssignee, .assignOwner:
            trackType = .notification
        case .create:
            trackType = .new
        case .share:
            trackType = .share
        case .dailyRemind:
            trackType = .remind
        @unknown default:
            assertionFailure("unexpected type: \(content.pbModel.operationType)")
            trackType = .notification
        }

        return .init(
            guid: guid,
            messageId: messageId,
            type: trackType
        )
    }

    var headerTitle: String? {
        if isExpired {
            return I18N.Todo_Task_BotMsgTaskCardExpired
        }
        let operatorName = content.pbModel.operator.name
        let senderId = content.senderId
        let operatorId = content.pbModel.operator.userID
        switch content.pbModel.operationType {
        case .create:   // 新建
            if senderId == operatorId {
                return I18N.Todo_Notify_CreatedATask
            } else {
                return I18N.Todo_Notify_UsernameCreatedTask(operatorName)
            }
        case .assign:   // xxx 添加你为负责人
            return I18N.Todo_UserAddedYouAsOwner_Text(operatorName)
        case .follow:   // xxx 添加你为关注者
            return I18N.Todo_Notify_FollowerAddedYou(operatorName)
        case .share:    // 分享
            return I18N.Todo_Notify_SharedATask
        case .complete, .incomplete: // 完成任务 & 反完成任务（恢复任务）
            let assigneeStr = content.pbModel.targetUsers.map(\.name).joined(separator: I18N.Todo_Task_Comma)
            let assigneeCount = content.pbModel.targetUsers.count
            let defaultReturn: String
            if content.pbModel.operationType == .complete {
                defaultReturn = I18N.Todo_CollabTask_UserCompleteTask(operatorName)
            } else {
                defaultReturn = I18N.Todo_CollabTask_UserRestoreTask(operatorName)
            }
            if let completeService = completeService, completeService.useClassicMode(for: generateTodo()) {
                return defaultReturn
            }
            switch content.pbModel.completeType {
            case .completeWholeTodo:
                // {{operator}} 完成了任务，整个任务已完成
                return I18N.Todo_CollabTask_CompletedWholeTaskCompleted(operatorName)
            case .completeWholeTodoAfterRemoveAssigneeSelf:
                // {{operator}} 不再参与任务，整个任务已完成
                return I18N.Todo_CollabTask_ExitWholeTaskCompleted(operatorName)
            case .completeWholeTodoAfterRemoveAssignees:
                if assigneeCount > 1 {
                    // {{operator}} 移除了负责人 {{num}} 人，整个任务已完成
                    return I18N.Todo_CollabTask_UserRemovedNumOwnersTaskDone(operatorName, assigneeCount)
                } else {
                    // {{operator}} 移除了负责人 {{owner}} ，整个任务已完成
                    return I18N.Todo_CollabTask_UserRemoveOwnerTaskDoneWithBlank(operatorName, assigneeStr)
                }
            case .completeWholeTodoAfterRemoveAssigneeYourself:
                // {{operator}} 将你从负责人中移除 ，整个任务已完成
                return I18N.Todo_CollabTask_UserRemovedYouAsOwnerTaskCompleted(operatorName)
            case .completeWholeTodoAfterCompleteAssignees:
                if assigneeCount > 1 {
                    // {{operator}} 完成了 {{num}} 个负责人的任务，整个任务已完成
                    return I18N.Todo_CollabTask_UserCompletedNumOwnerTasksDone(operatorName, assigneeCount)
                } else {
                    // {{operator}} 完成了 {{asignee}} 的任务，任务被全部完成
                    return I18N.Todo_CollabTask_UserCompletedAsigneeTaskDone(operatorName, assigneeStr)
                }
            case .completeWholeTodoAfterCompleteAssigneeYourself:
                // {{operator}} 完成了你的任务，整个任务已完成
                return I18N.Todo_CollabTask_UserCompletedYourTaskTaskDone(operatorName)

            case .restoreWholeTodo:
                // {{operator}} 恢复了整个任务
                return I18N.Todo_CollabTask_CreatorReopenedEntireTask(operatorName)
            case .restoreWholeTodoAfterAddAssigneeSelf:
                // {{operator}} 将自己添加为负责人，任务已被恢复
                return I18N.Todo_CollabTask_UserAddSelfOwnerTaskRestored(operatorName)
            case .restoreWholeTodoAfterAddAssignees:
                if assigneeCount > 1 {
                    // {{operator}}新增了负责人 {{num}} 人，任务已恢复
                    return I18N.Todo_CollabTask_UserAddOwnerTaskRestored_Plural(operatorName, assigneeCount)
                } else {
                    // {{operator}} 新增了负责人 {{assignee}}，任务已恢复
                    return I18N.Todo_CollabTask_UserAddOwnerTaskRestored(operatorName, assigneeStr)
                }
            case .restoreWholeTodoAfterAddAssigneesYourself:
                // {{operator}} 添加你为负责人，任务已被恢复
                return I18N.Todo_CollabTask_UserAddedYouAsOwnerTaskReopened(operatorName)
            case .restoreWholeTodoAfterRestoreSelf:
                // {{operator}} 恢复了自己的任务，任务已被恢复
                return I18N.Todo_CollabTask_UserRestoreOwnTask(operatorName)
            case .restoreWholeTodoAfterRestoreAssignee:
                if assigneeCount > 1 {
                    // {{operator}} 恢复了 {{num}} 个负责人，任务已恢复
                    return I18N.Todo_CollabTask_UserAddedBackOwnerTaskReopened(operatorName, assigneeCount)
                } else {
                    // {{operator}} 恢复了 {{assignee}} 的任务，任务已被恢复
                    return I18N.Todo_CollabTask_UserRestoreAsigneeTask(operatorName, assigneeStr)
                }
            case .restoreWholeTodoAfterRestoreAssigneeYourself:
                // {{operator}} 恢复了你的任务，任务已被恢复
                return I18N.Todo_CollabTask_UserReopenedYourTaskTaskReopened(operatorName)
            case .unknownCompleteType:
                return defaultReturn
            #if DEBUG
            #else
            @unknown default:
                return defaultReturn
            #endif
            }
        case .completeAssignee:
            // to assignee: {{operator}} 完成了你的任务
            return I18N.Todo_CollabTask_UserCompletedYourTask(operatorName)
        case .completeSelf:
            // to creator: {{operator}} 完成了任务
            return I18N.Todo_CollabTask_UserCompleteTask(operatorName)
        case .restoreAssignee:
            // to assignee: {{operator}} 恢复了你的任务
            return I18N.Todo_CollabTask_UserRestoredYourTask(operatorName)
        case .restoreSelf:
            // to creator: {{operator}} 恢复了任务
            return I18N.Todo_CollabTask_UserRestoreTask(operatorName)
        case .delete:   // 删除任务
            return I18N.Todo_Notify_CreatorDeletedTask(operatorName)
        case .dailyRemind:  // 每日提醒
            return I18N.Todo_Task_RecentTodoTask
        case .cancel:   // {{user_name}}将你从负责人中移除
            return I18N.Todo_Task_BotMsgTitleUserCanceledOwn(operatorName)
        case .unfollow:  //  取消你的关注者身份
            return I18N.Todo_Task_BotMsgTitleUserDeleteFollower(operatorName)
        case .update:   // 更新任务信息
            return I18N.Todo_Task_BotMsgTitleUserUpdatedTask(operatorName)
        case .assignOwner:
            return I18N.Todo_UserAddedYouAsOwner_Text(operatorName)

        // 异常处理
        case .unknown:
            return ""
        default:
            assertionFailure()
            return ""
        }
    }

    func summaryInfo() -> ChatCardRichTextInfo? {
        guard availableComponents.contains(.summary) else {
            return nil
        }

        let attrs: [AttrText.Key: Any]
        if isCompleted {
            attrs = [
                .font: UDFont.body2,
                .foregroundColor: UIColor.ud.textCaption,
                LKLineAttributeName: LKLineStyle(
                    color: UIColor.ud.textCaption,
                    position: .strikeThrough,
                    style: .line
                )
            ]
        } else {
            attrs = [
                .font: UDFont.body2,
                .foregroundColor: UIColor.ud.textTitle
            ]
        }

        if isDeleted {
            return ChatCardRichTextInfo(
                attrText: MutAttrText(string: I18N.Todo_Task_BotMsgTaskDeleted, attributes: attrs)
            )
        }

        let richContent = content.pbModel.todoDetail.richSummary
        var textInfo = makeRichTextInfo(from: richContent, with: attrs)
        if textInfo.attrText.length == 0 {
            textInfo.attrText = MutAttrText(string: I18N.Todo_Task_NoTitlePlaceholder, attributes: attrs)
        }
        return textInfo
    }

    var checkState: CheckboxState? {
        guard availableComponents.contains(.summary) else { return nil }
        var isEnabled = false
        if let permission = content.pbModel.todoDetail.userToPermission[currentUserId], !isDeleted {
            isEnabled = permission.canCompleteSelf || permission.canCompleteTodo
        }
        if isEnabled {
            return .enabled(isChecked: isCompleted)
        } else {
            return .disabled(isChecked: isCompleted, hasAction: true)
        }
    }

    var isMilestone: Bool {
        let fg = context.userResolver.fg.staticFeatureGatingValue(with: "todo.task_gantt_view")
        return fg && content.pbModel.todoDetail.isMilestone
    }

    var ownerContent: ChatCardOwnerData? {
        guard availableComponents.contains(.owner), !isDeleted else { return nil }
        let assignees = content.pbModel.todoDetail.assignees
        guard !assignees.isEmpty else { return nil }
        // 或签任务
        let isTaskComplete = generateTodo().mode == .taskComplete
        let assigneeModels = assignees.map(Assignee.init(model:))
        var completedCount = 0
        let avatars = assigneeModels.map { assignee in
            let isCompleted = !isTaskComplete && assignee.completedTime != nil
            if isCompleted {
                completedCount += 1
            }
            return CheckedAvatarViewData(icon: .avatar(assignee.avatar), isChecked: isCompleted)
        }
        var name = isTaskComplete ? I18N.Todo_NumTaskOwners_ICU(avatars.count) : I18N.Todo_MultiOwners_CompleteRatio_Text("\(completedCount)/\(avatars.count)")
        if avatars.count == 1 {
            name = assignees.first?.name ?? ""
        }
        /// 最多显示5个头像
        return ChatCardOwnerData(avatarData: AvatarGroupViewData(avatars: Array(avatars.prefix(5)), style: .normal), name: name)
    }

    var timeInfo: V3ListTimeInfo? {
        guard availableComponents.contains(.time) else { return nil }
        let todoDetail = content.pbModel.todoDetail
        return makeTimeInfo(todoDetail)
    }

    var openCenterTitle: String? {
        guard availableComponents.contains(.openCenter) else { return nil }
        let todoDetail = content.pbModel.todoDetail
        let relatedToMe = (
            currentUserId == todoDetail.creator.userID ||
            todoDetail.assignees.contains(where: { $0.assigneeID == currentUserId }) ||
            todoDetail.followers.contains(where: { $0.followerID == currentUserId })
        )
        /// 和我相关，并没有被删除, 并且有todo Tab
        if !isDeleted, relatedToMe, let navigationService = navigationService, navigationService.checkInTabs(for: .todo) {
            return I18N.Todo_TaskCard_OpenTasks_Button
        }
        return nil
    }

    func dailyReminderInfo() -> [ChatCardDailyReminderInfo] {
        guard availableComponents.contains(.dailyRemind) else { return [] }
        var ret = [ChatCardDailyReminderInfo]()
        for todo in content.pbModel.dailyRemind.todos.prefix(5) {
            let attrs: [AttrText.Key: Any] = [
                .font: UDFont.body2,
                    .foregroundColor: UIColor.ud.textTitle
            ]
            var title = makeRichTextInfo(
                from: todo.richSummary,
                with: attrs,
                ignoreLink: true
            )
            if title.attrText.length == 0 {
                title.attrText = MutAttrText(string: I18N.Todo_Task_NoTitlePlaceholder, attributes: attrs)
            }
            var info = ChatCardDailyReminderInfo(guid: todo.guid, title: title, timeContent: nil)
            info.timeContent = makeTimeInfo(todo)
            ret.append(info)
        }
        return ret
    }

    var followBtn: (text: String, isFollow: Bool)? {
        guard let isFollow = isFollow else { return nil }
        let text = isFollow ? I18N.Todo_Task_FollowButton : I18N.Todo_Task_Following
        return (text: text, isFollow: isFollow)
    }

    var isFollow: Bool? {
        guard isCanFollowPermission() else { return nil }
        guard !isBottomBtnDisabled else { return nil }

        let todoDetail = content.pbModel.todoDetail

        let followerIds = todoDetail.followers.map(\.followerID)
        let assigneeIds = todoDetail.assignees.map(\.assigneeID)
        let creatorId = todoDetail.creator.userID
        let ownerId = todoDetail.owner.user.userID

        if creatorId.isEmpty ||
            isFromBot ||
            currentUserId == creatorId ||
            assigneeIds.contains(currentUserId) {
            return nil
        }

        return !followerIds.contains(currentUserId)
    }

    private func isCanFollowPermission() -> Bool {
        let todoDetail = content.pbModel.todoDetail
        var canFollow = todoDetail.canFollow
        if let permission = todoDetail.userToPermission[currentUserId] {
            canFollow = permission.canFollow
        }
        return canFollow
    }

    var bottomText: String {
        if isDeleted {
            return I18N.Todo_Task_BotMsgTaskDeleted
        }

        switch content.pbModel.operationType {
        case .cancel:
            return I18N.Todo_Task_BotMsgRemovedFromTask
        case .dailyRemind:
            return I18N.Todo_BotNotification_TodayListMore
        @unknown default:
            return I18N.Todo_Task_ViewDetails
        }
    }

    var displayBottom: Bool {
        switch content.pbModel.operationType {
        case .dailyRemind:
            return navigationService?.checkInTabs(for: .todo) ?? false
        @unknown default:
            return true
        }
    }

    enum BottomAction {
        case detail(guid: String)
        case todoCenter
    }

    var bottomAction: BottomAction {
        if content.pbModel.operationType == .dailyRemind {
            return .todoCenter
        } else {
            return .detail(guid: content.pbModel.todoDetail.guid)
        }
    }

    var isBottomBtnDisabled: Bool {
        if isDeleted || isExpired {
            return true
        }
        switch content.pbModel.operationType {
        case .cancel, .unfollow:
            return true
        default:
            return false
        }
    }

}

// MARK: - Method

extension ChatCardViewModel {

    private func generateTodo(_ todoDetail: TodoDetail? = nil) -> Rust.Todo {
        let detail = todoDetail ?? content.pbModel.todoDetail
        var todo = Rust.Todo()
        todo.completedMilliTime = detail.completedMilliTime
        todo.deletedMilliTime = detail.deletedMilliTime
        todo.source = detail.source
        todo.startMilliTime = detail.startMilliTime
        todo.dueTime = detail.dueTime
        todo.isAllDay = detail.isAllDay
        todo.rrule = detail.rrule
        todo.reminders = detail.reminders
        todo.guid = detail.guid
        todo.creator = detail.creator
        todo.rrule = detail.rrule
        todo.reminders = detail.reminders
        todo.creatorID = todo.creator.userID
        todo.assignees = detail.assignees
        todo.customComplete = detail.customComplete
        todo.mode = detail.mode
        todo.isMilestone = detail.isMilestone
        return todo
    }

    private func makeTimeInfo(_ todoDetail: TodoDetail) -> V3ListTimeInfo? {
        let timeContext = TimeContext(
            currentTime: currentTime,
            timeZone: timeService?.rxTimeZone.value ?? .current,
            is12HourStyle: timeService?.rx12HourStyle.value ?? false
        )
        let todo = generateTodo(todoDetail)
        let shouldChangeColor = isCompleted || isDeleted
        var timeInfo = V3ListContentData.timeInfo(todo, with: timeContext, and: shouldChangeColor)
        if shouldChangeColor {
            timeInfo?.color = UIColor.ud.textCaption
        }
        return timeInfo
    }

}

// MARK: - ViewAction

extension ChatCardViewModel {

    func checkboxDisabledToast() -> String? {
        guard case .disabled(_, let hasAction) = checkState, hasAction else {
            return nil
        }
        if isDeleted {
            return I18N.Todo_Task_TaskHasBeenDeleted
        } else {
            return I18N.Todo_Notify_NoPermissionCompleteTask
        }
    }

    func getCustomComplete() -> CustomComplete? {
        return completeService?.customComplete(from: generateTodo())
    }

    func doubleCheckBeforeToggleCompleteState() -> CompleteDoubleCheckContext? {
        return completeService?.doubleCheckBeforeToggleState(
            with: .todo,
            todo: generateTodo(),
            hasContainerPermission: false
        )
    }

    func toggleCompleteState(completion: @escaping (UserResponse<String?>) -> Void) {
        let todo = generateTodo()
        let fromState = completeService?.state(for: todo) ?? .outsider(isCompleted: false)
        let ctx = CompleteContext(fromState: fromState, role: .todo)
        completeService?.toggleState(with: ctx, todoId: todo.guid, todoSource: todo.source, containerID: nil)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: {
                    ChatCard.logger.info("toggle succeed:  \($0.newState)")
                    let toast = fromState.toggleSuccessToast(by: .todo)
                    completion(.success(toast))
                },
                onError: { err in
                    ChatCard.logger.error("toggle failed error: \(err)")
                    completion(.failure(Rust.makeUserError(from: err)))
                }
            )
            .disposed(by: disposeBag)

        var commonParams = self.trackCommonParams
        commonParams.guid = todo.guid
        ChatCard.Track.clickCheckBox(with: commonParams, fromState: fromState)
    }

    func handleFollow() -> Single<Void> {
        guard let operateApi = operateApi, let isFollow = isFollow else { return .just(void) }

        if isFollow {
            Detail.tracker(
                .todo_task_follow,
                params: ["source": "card", "task_id": guid]
            )
        } else {
            Detail.tracker(
                .todo_task_follow_cancel,
                params: [
                    "type": "card",
                    "task_id": guid,
                    "select_user_id": currentUserId
                ]
            )
        }
        ChatCard.Track.clickFollow(with: trackCommonParams, isFollowed: isFollow)

        var authScene = Rust.DetailAuthScene()
        authScene.type = .message
        authScene.id = messageId
        return operateApi.followTodo(
            forId: guid,
            isFollow: isFollow,
            authScene: authScene
        )
        .take(1)
        .asSingle()
        .observeOn(MainScheduler.asyncInstance)
        .do(
            onSuccess: { _ in
                ChatCard.logger.info("follow succeed from: \(isFollow)")
            },
            onError: { err in
                ChatCard.logger.info("follow failed error: \(err)")
            }
        )
        .map { _ in void }
    }

}

// MARK: - Make RichText

extension ChatCardViewModel {

    /// 构建富文本内容
    private func makeRichTextInfo(
        from richContent: Rust.RichContent,
        with attrs: [AttrText.Key: Any],
        ignoreLink: Bool = false
    ) -> ChatCardRichTextInfo {
        var richContent = richContent
        // 新建场景，对于本地马上（< 10s）发送到会话的卡片，url 可能还未绑定 hangPoint，
        // 此时为了一致体验，允许从本地基于 url 取出 hangEntity
        if content.pbModel.operationType == .create && abs(message.createTime - NSDate().timeIntervalSince1970) < 10.0 {
            if !richContent.hasURLPreviewEntities {
                richContent.urlPreviewEntities = .init()
            }
            for (eleId, ele) in richContent.richText.elements {
                guard
                    ele.tag == .a,
                    let anchor = richContent.richText.elements[eleId]?.property.anchor
                else {
                    continue
                }
                if let point = richContent.urlPreviewHangPoints[eleId] {
                    if richContent.urlPreviewEntities.previewEntity[point.previewID] != nil {
                        continue
                    }
                    if let anchorService = anchorService, let entity = anchorService.getCachedHangEntity(forUrl: point.url) {
                        richContent.urlPreviewEntities.previewEntity[point.previewID] = entity
                    }
                } else {
                    if let anchorService = anchorService, let entity = anchorService.getCachedHangEntity(forUrl: anchor.href) {
                        var point = Rust.RichText.AnchorHangPoint()
                        point.previewID = UUID().uuidString
                        point.url = anchor.href
                        richContent.urlPreviewHangPoints[eleId] = point
                        richContent.urlPreviewEntities.previewEntity[point.previewID] = entity
                    }
                }
            }
        }
        let result = richContentService?.buildLabelContent(
            with: richContent,
            config: .init(
                baseAttrs: attrs,
                lineSeperator: " ",
                anchorConfig: .init(
                    foregroundColor: ignoreLink ? nil : UIColor.ud.textLinkNormal,
                    sourceIdForHangEntity: message.id
                ),
                atConfig: .init(
                    normalForegroundColor: ignoreLink ? nil : UIColor.ud.textLinkNormal,
                    outerForegroundColor: ignoreLink ? nil : UIColor.ud.textCaption
                )
            )
        )
        guard let result = result else {
            return ChatCardRichTextInfo(attrText: MutAttrText(string: ""))
        }
        var mutAttrText = MutAttrText(attributedString: result.attrText)
        if ignoreLink {
            return ChatCardRichTextInfo(attrText: mutAttrText)
        }
        var atMap = [NSRange: String]()
        result.atItems.forEach { atMap[$0.range] = $0.property.userID }
        var urlMap = [NSRange: String]()
        result.anchorItems.forEach { urlMap[$0.range] = $0.property.href }
        return ChatCardRichTextInfo(attrText: mutAttrText, atMap: atMap, urlMap: urlMap)
    }

    private typealias StrTemplateFunc = (String) -> String
    private func getRange(for text: String, with templateFunc: StrTemplateFunc) -> NSRange? {
        return Utils.RichText.getRange(for: text, with: templateFunc)
    }

    private func makeRichTextInfo(for assignees: [Rust.Assignee]) -> ChatCardRichTextInfo {
        let atMeAttrs: [AttrText.Key: Any] = [
            .foregroundColor: UIColor.ud.primaryOnPrimaryFill,
            .font: UDFont.body2
        ]
        let atOtherAttrs: [AttrText.Key: Any] = [
            .foregroundColor: UIColor.ud.textLinkNormal,
            .font: UDFont.body2
        ]
        let mutAttrText = MutAttrText()
        var atMap = [NSRange: String]()
        for i in 0..<assignees.count {
            let (chatterId, name) = (assignees[i].assigneeID, assignees[i].name)
            let atText = "@\(name)"
            let attrStr: AttrText
            if context.isMe(chatterId) {
                attrStr = LKLabel.lu.genAtMeAttributedText(
                    atMeAttrStr: AttrText(string: atText, attributes: atMeAttrs),
                    bgColor: UIColor.ud.primaryContentDefault
                )
            } else {
                attrStr = AttrText(string: atText, attributes: atOtherAttrs)
            }
            let range = NSRange(location: mutAttrText.length, length: attrStr.length)
            atMap[range] = chatterId
            mutAttrText.append(attrStr)
            mutAttrText.append(AttrText(string: " "))
        }
        return ChatCardRichTextInfo(attrText: mutAttrText, atMap: atMap)
    }

}
