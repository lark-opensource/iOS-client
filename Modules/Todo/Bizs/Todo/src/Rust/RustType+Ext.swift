//
//  RustType+Ext.swift
//  Todo
//
//  Created by 张威 on 2021/6/4.
//

import RustPB
import LarkLocalizations
import Foundation
import LarkAccountInterface

// MARK: Todo

extension Rust.Todo {
    ///  开始时间是否有效
    var isStartTimeValid: Bool { startMilliTime > 0  }

    var startTimeForFormat: Int64 { startMilliTime / Utils.TimeFormat.Thousandth }

    /// 判断是否有有效截止时间
    var isDueTimeValid: Bool { dueTime > 0 }

    // 未安排截止时间
    var isNoDueTime: Bool { !isDueTimeValid }

    /// 未安排执行者
    var isNoAssignee: Bool { assignees.isEmpty }

    /// 描述是否已删除
    var isDeleted: Bool { deletedMilliTime > 0 }
    /// 描述任务是否整个完成，从任务视角看，区别用户视角看
    var isTodoCompleted: Bool { completedMilliTime > 0 }
    /// 重复规则是否合法
    var isRRuleValid: Bool { hasRrule && !rrule.isEmpty }

    func dueTimeForDisplay(_ timeZone: TimeZone) -> Int64 {
        guard isDueTimeValid else { return 0 }
        guard isAllDay else { return dueTime }
        return Utils.TimeFormat.lastSecondForAllDay(dueTime, timeZone: timeZone)
    }

    func startTimeForDisplay(_ timeZone: TimeZone) -> Int64 {
        guard isStartTimeValid else { return 0 }
        guard isAllDay else { return startTimeForFormat }
        return Utils.TimeFormat.lastSecondForAllDay(startTimeForFormat, timeZone: timeZone)
    }

    /// 是否被移除，用于push
    func isRemoved(_ curUserId: String, ignoreRole: Bool = false) -> Bool {
        if isDeleted { return true }
        // 用于子任务
        if hiddenMilliTime > 0 { return true }
        // 没有读权限
        guard selfPermission.isReadable else { return true }
        // 忽律角色
        if ignoreRole { return false }
        if isNotMine { return true }
        // 局外人
        return isOutsider(curUserId)
    }

    /// 是否创建者
    func isCreator(_ curUserId: String) -> Bool { creatorID == curUserId }
    /// 是否执行者
    func isAssignee(_ curUserId: String) -> Bool {
        return assignees.contains(where: { $0.assigneeID == curUserId })
    }
    /// 是否分配者
    func isAssigner(_ curUserId: String) -> Bool {
        return assignees.contains(where: { $0.assignerID == curUserId })
    }
    /// 是否关注者
    func isFollower(_ curUserId: String) -> Bool {
        return followers.contains(where: { $0.followerID == curUserId })
    }
    /// 是否是局外人，不是todo的任何角色
    func isOutsider(_ curUserId: String) -> Bool {
        return !isCreator(curUserId) && !isAssignee(curUserId) && !isFollower(curUserId)
    }
    /// 是否有读权限
    func readable(for key: Todo_V1_Commit.Key) -> Bool {
        let k = key.rawValue
        return selfPermission.canReadCommitKeys.contains { key, value in
            return key == k && value
        }
    }
    /// 是否有编辑权限
    func editable(for key: Todo_V1_Commit.Key) -> Bool {
        let k = key.rawValue
        return selfPermission.canEditCommitKeys.contains { key, value in
            return key == k && value
        }
    }

    func fixedForCreating(fillOwner: Bool = false, passportService: PassportUserService? = nil) -> Self {
        var new = self
        new.selfPermission.isReadable = true
        new.selfPermission.isEditable = true
        if let user = User.current(passportService) {
            // 新建的时候需要填充自己为负责人
            if fillOwner, !assignees.contains(where: { $0.identifier == user.chatterId }) {
                new.assignees.append(Assignee(member: .user(user)).asModel())
            }
        }
        new.mode = .taskComplete
        return new
    }

    /// 判断站在草稿的视角，todo 是否有意义的数据
    var isValidDraft: Bool {
        return !richSummary.richText.isEmpty
        || !richDescription.richText.isEmpty
        || !assignees.isEmpty
        || isDueTimeValid
        || !followers.isEmpty
    }

    // MARK: - 多执行者用的完成状态
    /// 是否完成
    func isComleted(_ completeService: CompleteService?) -> Bool {
        guard let completeService = completeService else { return false }
        let completeState = completeService.state(for: self)
        return completeState.isCompleted
    }

    /// 用户视角的完成时间（单位：默认秒）
    func userCompletedTime(with state: CompleteState, isMilliTime: Bool = false) -> Int64 {
        if case .classicMode = state {
            return isMilliTime ? completedMilliTime : completedMilliTime / Utils.TimeFormat.Thousandth
        } else {
            return isMilliTime ? displayCompletedMilliTime : displayCompletedMilliTime / Utils.TimeFormat.Thousandth
        }
    }

    /// 是否允许完成/取消完成
    func isCompleteEnabled(with completeState: CompleteState) -> Bool {
        if case .classicMode = completeState {
            let k = Todo_V1_Commit.Key.todoCompletedTime.rawValue
            return selfPermission.canEditCommitKeys.contains { key, value in
                return key == k && value
            }
        } else {
            let k1 = Todo_V1_Commit.Key.todoCompletedMilliTime.rawValue
            let k2 = Todo_V1_Commit.Key.todoUsersCompletedMilliTime.rawValue
            return selfPermission.canEditCommitKeys.contains { key, value in
                return (k1 == key || k2 == key) && value
            }
        }
    }

    mutating func updateStartTime(to type: V3ListTimeGroup.StartTime, offset: Int64, with timeZone: TimeZone) {
        if !isStartTimeValid, !isDueTimeValid, FeatureGating.boolValue(for: .startTime) {
            isAllDay = true
        }
        let timestamp = type.defaultStartTime(by: offset, timeZone: timeZone, isAllDay: isAllDay)
        if isDueTimeValid, timestamp > dueTime {
            dueTime = timestamp
        }
        startMilliTime = timestamp * Utils.TimeFormat.Thousandth
    }

    mutating func updateDueTime(to type: V3ListTimeGroup.DueTime, offset: Int64, with timeZone: TimeZone) {
        if !isStartTimeValid, !isDueTimeValid, FeatureGating.boolValue(for: .startTime) {
            isAllDay = true
        }
        let timestamp = type.defaultDueTime(by: offset, timeZone: timeZone, isAllDay: isAllDay)
        if isStartTimeValid, startTimeForFormat > timestamp {
            startMilliTime = timestamp * Utils.TimeFormat.Thousandth
        }
        dueTime = timestamp
    }

}
// MARK: - Container Meta

extension Rust.TaskContainer {
    // 是否任务清单
    var isTaskList: Bool { category == .taskList }
    // 没有被删除且至少有阅读权限
    var isValid: Bool { !isDeleted && isReadOnly }
    // 是否已删除
    var isDeleted: Bool { deleteMilliTime > 0 }
    // 是否可编辑
    var canEdit: Bool { getPermission(by: .editContainer) }
    // 是否可删除
    var canDelete: Bool { getPermission(by: .deleteContainer) }
    // 是否可编辑任务
    var canEditTask: Bool { getPermission(by: .editTask) }
    // 是否只读
    var isReadOnly: Bool { getPermission(by: .view) }
    // 是否是负责人
    var isTaskListOwner: Bool { getPermission(by: .manageOwner) }
    // 是否在管理页面有编辑权限
    var isManageEditor: Bool { getPermission(by: .manageEditor) }
    // 是否在管理页面有阅读权限
    var isManageViewer: Bool { getPermission(by: .manageViewer) }
    // 是否在管理页面有继承权限
    var isManageInherit: Bool { getPermission(by: .manageInherit)}
    // 是否已归档
    var isArchived: Bool { isTaskList && archivedMilliTime > 0 }

    func getPermission(by k: Rust.PermissionAction) -> Bool {
        // 只用于清单
        guard isTaskList else { return false }
        // 无权限的数据为unknown
        return currentUserPermission.permissions.contains { (key, value) in
            return key == k.rawValue && value
        }
    }
}
// MARK: - Section

extension Rust.TaskSection {

    // 分组名称
    var displayName: String {
        return name.isEmpty ? (isDefault ? I18N.Todo_New_Section_NoSection_Title : I18N.Todo_New_UntitledSection_Title) : name
    }

}

extension Rust.TaskListSectionRef {
    
    var isDeleted: Bool { deleteMilliTime > 0 }

}

extension Rust.ContainerSection {

    var toContainerTasKRef: Rust.ContainerTaskRef {
        var ref = Rust.ContainerTaskRef()
        ref.sectionGuid = sectionGuid
        ref.rank = rank
        ref.containerGuid = containerGuid
        return ref
    }

    var isValid: Bool {
        return !(sectionGuid.isEmpty || containerGuid.isEmpty)
    }
}

extension Rust.ContainerTaskRef {

    var toContainerSection: Rust.ContainerSection {
        var cs = Rust.ContainerSection()
        cs.containerGuid = containerGuid
        cs.sectionGuid = sectionGuid
        cs.rank = rank
        return cs
    }
}

// MARK: - TaskListSection

extension Rust.TaskListSection {

    var displayName: String {
        return name.isEmpty ? I18N.Todo_TaskList_UntitledSection_Text : name
    }
}

// MARK: - RichText

extension Rust.RichText {
    var isEmpty: Bool {
        if elements.isEmpty {
            return true
        }
        if elementIds.isEmpty {
            return true
        }
        return false
    }

    /// 是否有可见内容
    func hasVisibleContent() -> Bool {
        if !atIds.isEmpty || !anchorIds.isEmpty || !imageIds.isEmpty {
            return true
        }
        let visibleTags: Set<Rust.RichText.Element.Tag> = [.emotion, .a, .mention]
        for ele in elements.values {
            if visibleTags.contains(ele.tag) {
                return true
            }
            if ele.tag == .text && !ele.property.text.content.isEmpty {
                return true
            }
        }
        return false
    }

    var atEelementMap: [String: String]? {
        return elements.compactMapValues({ element -> String? in
            if element.tag == .at {
                let property = element.property.at
                if property.isAnonymous || property.userID == "all" {
                    return nil
                }
                return property.userID
            }
            return nil
        })
    }
}

// MARK: - Todo Origin

extension Rust.TodoOrigin {
    init?(source: TodoCreateSource) {
        switch source {
        case .chat(let chatContext):
            var origin = Rust.TodoOrigin()
            origin.type = .chat
            var sourceChat = Todo_V1_TodoSourceChat()
            sourceChat.chatID = chatContext.chatId
            sourceChat.chatName = chatContext.chatName
            if let messageId = chatContext.messageId {
                sourceChat.messageID = messageId
            }
            origin.element = .chat(sourceChat)
            self = origin
        case .list, .subTask, .inline:
            return nil
        }
    }
}

// MARK: - Assignee & Follower

extension Rust.Assignee: MemberConvertible {
    init(user: Rust.User) {
        var u = Rust.Assignee.User()
        u.user = user
        var ret = Rust.Assignee()
        ret.type = .user
        ret.assignee = .user(u)
        ret.assigneeID = u.user.userID
        self = ret
    }

    func asMember() -> Member { Assignee(model: self).asMember() }
}

extension Rust.Follower: MemberConvertible {
    func asMember() -> Member { Follower(model: self).asMember() }
}

extension Rust.TaskMember {
    init(member: Member) {
        var res = Rust.TaskMember()
        switch member {
        case .user(let userType):
            var user = Todo_V1_TodoUser()
            user.userID = userType.chatterId
            user.name = userType.name
            user.avatarKey = userType.avatar.avatarKey
            user.tenantID = userType.tenantId
            res.user = user
            res.type = .user
        case .group(let chatId):
            var chat = Todo_V1_TodoChat()
            chat.chatID = chatId
            res.chat = chat
            res.type = .group
        case .unknown:
            assertionFailure()
        }
        self = res
    }
}

extension Rust.TaskMemberType {

    init(from serverPB: Rust.EntityType) {
        switch serverPB {
        case .docs: self = .docs
        case .group: self = .group
        case .user: self = .user
        case .app: self = .app
        case .unknownTodoItemMemberType: self = .unknown
        @unknown default: self = .unknown
        }
    }

    func toServerPB() -> Rust.EntityType {
        switch self {
        case .docs: return .docs
        case .group: return .group
        case .user: return .user
        case .app: return .app
        case .unknown: return .unknownTodoItemMemberType
        @unknown default: return .unknownTodoItemMemberType
        }
    }
}


extension Rust.TaskFieldValue {
    mutating func completeMetaDataIfNeeded(
        with assoc: Rust.ContainerTaskFieldAssoc,
        and taskGuid: String
    ) {
        if self.fieldKey.isEmpty || self.taskGuid.isEmpty {
            self.taskGuid = taskGuid
            self.fieldKey = assoc.taskField.key
            self.fieldType = assoc.taskField.type
        }
    }
}

extension Rust.TodoChangeset {
    var isEmpty: Bool {
        return deletedTodoIdents.isEmpty && updatedTodoIdents.isEmpty && addedTodoIdents.isEmpty && todos.isEmpty
    }
}

extension Rust.RichContent {

    /// 未配对的 hangPoints，意味着需要额外加载对应的 hang entities
    func unpairedHangPoints() -> [Rust.RichText.AnchorHangPoint] {
        return urlPreviewHangPoints.values.filter { urlPreviewEntities.previewEntity[$0.previewID] == nil }
    }

    /// 插入 hang entities
    mutating func insert(_ hangEntities: [Rust.RichText.AnchorHangEntity]) {
        hangEntities.forEach { urlPreviewEntities.previewEntity[$0.previewID] = $0 }
    }

}

// MARK: - Container Ref
extension Rust.ContainerTaskRef {
    // 是否合法
    var isValid: Bool { !(containerGuid.isEmpty || sectionGuid.isEmpty || rank.isEmpty) }
}

// MARK: - Launch Screen
extension Rust.ListLaunchScreen {

    var shouldDisplay: Bool { status == .enable && text != nil }

    var text: String? {
        let key = LanguageManager.currentLanguage.localeIdentifier.lowercased()
        return i18NRichTexts[key]?.lc.summerize()
    }

    var buttonoText: String? {
        let key = LanguageManager.currentLanguage.localeIdentifier.lowercased()
        return buttonI18NTexts[key]
    }

    var buttonUrl: URL? {
        guard let url = URL(string: buttonAction.ios.href) else {
            return nil
        }
        return url
    }

}

// MARK: - Comment

extension Rust.Comment {
    var needBlock: Bool { type == .unknownType }
}

extension Rust.TaskMode {

    var pickerTitle: String {
        if self == .taskComplete {
            return I18N.Todo_MultiOwners_RequireAnyoneComplete_Option
        }
        return I18N.Todo_MultiOwners_RequireEveryoneComplete_Option
    }
}
