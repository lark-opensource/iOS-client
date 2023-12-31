//
//  ListActivityRecordsViewModel.swift
//  Todo
//
//  Created by wangwanxin on 2023/3/22.
//

import Foundation
import LarkContainer
import RxSwift
import RxCocoa
import RustPB
import LarkTimeFormatUtils
import UniverseDesignIcon
import LarkExtensions
import LKRichView
import LarkRichTextCore
import LarkUIKit
import ByteWebImage
import LarkModel
import UniverseDesignFont

final class ListActivityRecordsViewModel: UserResolverWrapper {
    let userResolver: LarkContainer.UserResolver
    let scene: Rust.ActivityScene
    let guid: String?
    
    // ID前面加前缀
    struct AnchorPrefix {
        static let taskList = "TaskList" + UUID().uuidString
        static let task = "Task" + UUID().uuidString
    }

    enum ListUpdate {
        case reload
        case reloadIndex(indexPath: IndexPath)
    }


    let rxLoadMoreState = BehaviorRelay<ListLoadMoreState>(value: .none)
    let rxViewState = BehaviorRelay<ListViewState>(value: .idle)
    let rxListUpdate = BehaviorRelay<ListUpdate>(value: (.reload))
    var onTapImage: ((Int, [Rust.RichText.Element.ImageProperty], UIImageView) -> Void)?
    // collection view宽度
    var collectionViewWidth: CGFloat = 0 {
        didSet {
            guard oldValue != collectionViewWidth else { return }
            remakeViewData()
        }
    }

    private lazy var cursor: String = ""
    private lazy var cellDatas = [ActivityRecordSectionData]()

    @ScopedInjectedLazy private var timeService: TimeService?
    @ScopedInjectedLazy private var listApi: TaskListApi?
    private var currentLoadMoreId: String?
    private let disposeBag = DisposeBag()

    init(resolver: LarkContainer.UserResolver, scene: Rust.ActivityScene, guid: String? = nil) {
        self.userResolver = resolver
        self.scene = scene
        self.guid = guid
    }

    func setup() {
        ActivityRecord.Track.viewTaskList(with: guid)
        loadData()
    }

    func retryFetch() {
        cursor = ""
        loadData()
    }

    func loadData() {
        rxViewState.accept(.loading)
        fetchData { [weak self] (res: Rust.ActivityRecordsRes) in
            guard let self = self else { return }
            self.handleRequestResult(res, isLoadMore: false)
        } onError: { [weak self] _ in
            self?.rxViewState.accept(.failed(.needsRetry))
        }
    }

    func loadMore(silent: Bool = false) {
        guard currentLoadMoreId == nil, !cursor.isEmpty else {
            ActivityRecord.logger.error("load more faild. cursor \(cursor)")
            return
        }
        currentLoadMoreId = UUID().uuidString
        if !silent {
            rxLoadMoreState.accept(.loading)
        }
        fetchData { [weak self] (res: Rust.ActivityRecordsRes) in
            guard let self = self else { return }
            self.currentLoadMoreId = nil
            self.handleRequestResult(res, isLoadMore: true)
        } onError: { [weak self] _ in
            self?.currentLoadMoreId = nil
            self?.rxLoadMoreState.accept(.hasMore)
        }
    }

    private func fetchData(onSuccess: @escaping (Rust.ActivityRecordsRes) -> Void, onError: @escaping (Error) -> Void) {
        let req: Rust.PageReq = {
            var req = Rust.PageReq()
            req.pageCount = Int32(Utils.List.fetchCount.initial)
            req.pageToken = cursor
            return req
        }()
        listApi?.getPagingActvityRecords(with: guid, scene: scene, and: req)
            .take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: onSuccess,
                onError: { error in
                    ActivityRecord.logger.error("load more activity record failed. error: \(error)")
                    onError(error)
                }
            )
            .disposed(by: disposeBag)
    }

    private func handleRequestResult(_ res: Rust.ActivityRecordsRes, isLoadMore: Bool) {
        cursor = res.pageResult.lastToken
        if !isLoadMore {
            cellDatas = makeSectionData(from: res.activityRecords)
        } else {
            let newSections = makeSectionData(from: res.activityRecords)
            newSections.forEach { section in
                guard let index = cellDatas.firstIndex(where: { $0.sectionID == section.sectionID }) else {
                    cellDatas.append(section)
                    return
                }
                let lastCombineItem = cellDatas[index].items.last(where: { item in
                    if case .combine = item {
                        return true
                    }
                    return false
                })
                let firstCombineItem = section.items.first(where: { item in
                    if case .combine = item {
                        return true
                    }
                    return false
                })
                if let lastCombineItem = lastCombineItem,
                   let firstCombineItem = firstCombineItem,
                   lastCombineItem.guid == firstCombineItem.guid {
                    // 之前的二级分组中能找到, 添加除了combineItem外的数据
                    cellDatas[index].items.append(contentsOf: section.items.filter({ $0.guid != firstCombineItem.guid }))
                } else {
                    cellDatas[index].items.append(contentsOf: section.items)
                }
            }
        }
        rxLoadMoreState.accept(res.pageResult.hasMore_p ? .hasMore : .noMore)
        rxViewState.accept(cellDatas.isEmpty ? .empty : .data)
        rxListUpdate.accept(.reload)
    }

}

extension ListActivityRecordsViewModel {

    /// Ipad C-R拖拽的时候，需要重新渲染宽度
    private func remakeViewData() {
        guard !cellDatas.isEmpty else { return }
        cellDatas = cellDatas.map { section in
            var newSection = section
            newSection.items = section.items.map { itemType -> ActivityRecordSectionData.ItemType in
                switch itemType {
                case .combine(let data):
                    return .combine(data)
                case .content(let data):
                    if let meta = data.metaData {
                        var newData = data
                        newData.itemHeight = nil
                        newData.content.text = makeMiddleTextData(meta)
                        return .content(newData)
                    }
                    return .content(data)
                }
            }
            return newSection
        }
        rxListUpdate.accept(.reload)
    }

    private func makeSectionData(from records: [Rust.ActivityRecord]) -> [ActivityRecordSectionData] {
        guard !records.isEmpty else { return [] }
        var sections = [ActivityRecordSectionData]()
        records.forEach { record in
            // 分组标题作为分组ID
            let time = makeSectionTime(record)
            let item = makeItem(record)
            let combineItem = makeCombineItem(record)
            guard let index = sections.firstIndex(where: { $0.sectionID == time }) else {
                var section = ActivityRecordSectionData(sectionID: time)
                section.header = makeSectionHeader(time)
                if let combineItem = combineItem {
                    section.items.append(combineItem)
                }
                section.items.append(item)
                sections.append(section)
                return
            }
            if let combineItem = combineItem {
                // 和上一个不同的时候才加入
                let lastCombineItem = sections[index].items.last(where: { item in
                    if case .combine = item {
                        return true
                    }
                    return false
                })
                if lastCombineItem?.guid != combineItem.guid {
                    sections[index].items.append(combineItem)
                } else {
                    ActivityRecord.logger.info("combined item is equal to last combined item. \(combineItem.guid), \(lastCombineItem?.guid ?? "empty")")
                }
            }
            sections[index].items.append(item)
        }
        return sections
    }

    private func makeSectionHeader(_ time: String) -> ActivityRecordSectionHeaderData {
        let attrs: [AttrText.Key: Any] = [
            .font: UDFont.systemFont(ofSize: 17, weight: .medium),
            .foregroundColor: UIColor.ud.textTitle
        ]
        let attr = AttrText(string: time, attributes: attrs)
        typealias config = ActivityRecordSectionHeader.Config
        let height = config.textHeight + config.topSpace + config.bottomSpace
        return ActivityRecordSectionHeaderData(
            text: attr,
            height: height,
            textHeight: config.textHeight,
            topSpace: config.topSpace
        )
    }

    private func makeSectionTime(_ record: Rust.ActivityRecord) -> String {
        return Utils.TimeFormat.formatDateStr(by: record.operateMilliTime / Utils.TimeFormat.Thousandth, timeZone: curTimeContext.timeZone)
    }

    private static let MyTaskGuid = UUID().uuidString
    private func makeCombineItem(_ record: Rust.ActivityRecord) -> ActivityRecordSectionData.ItemType? {
        guard scene == .user else { return nil }

        let taskListGuids = record.relatedTaskListGuids
        var data = ActivityRecordCombineData(guid: taskListGuids.isEmpty ? Self.MyTaskGuid : taskListGuids.joined())
        let text: String
        if taskListGuids.isEmpty {
            // 我的任务
            text = I18N.Todo_Updates_MyTasks_Title
        } else if taskListGuids.count == 1 {
            text = record.taskListGuidToNames.values.first ?? ""
        } else {
            text = I18N.Todo_Updates_NumListsIncluding_Title(taskListGuids.count - 1, record.taskListGuidToNames[taskListGuids[0]] ?? "")
        }
        let textWidth = CGFloat(ceil(text.size(withAttributes: [
            .font: ActivityRecordCombineCell.Config.font
        ]).width))
        data.text = text
        data.textWidth = min(textWidth, maxContentWidth * ActivityRecordCombineCell.Config.maxContentRatio)
        data.metaData = record
        return .combine(data)
    }

    private func makeItem(_ record: Rust.ActivityRecord) -> ActivityRecordSectionData.ItemType {
        var content = ActivityRecordMiddleContentData(text: makeMiddleTextData(record))
        if let images = makeImages(record) {
            content.images = images
        }
        if let attachments = makeAttachments(record) {
            content.attachments = attachments
        }
        var data = ActivityRecordContentData(
            guid: record.guid,
            header: makeHeaderData(record),
            user: makeUserData(record),
            content: content,
            footer: makeFooterData(record)
        )
        data.showMore = data.shouldShowMore
        data.metaData = record
        return .content(data)
    }

    // nolint: long function
    // swiftlint:disable function_body_length
    private func makeMiddleTextData(_ record: Rust.ActivityRecord) -> ActivityRecordTextData {
        var text: String?, richElement: [RichElement]?, content: Rust.RichContent?
        let name = record.operator.name
        switch record.recordKey {
        case .taskListCreate:
            text = I18N.Todo_TaskListUpdates_Create_Text(name)
        case .taskListRename:
            text = I18N.Todo_TaskListUpdates_ChangeListName_Text(name, record.renameEntity.oldTaskListName, record.renameEntity.newTaskListName)
        case .taskListDelete:
            text = I18N.Todo_TaskListUpdates_Delete_Text(name)
        case .taskListArchived:
            text = I18N.Todo_TaskListUpdates_Archive_Text(name)
        case .taskListNotArchived:
            text = I18N.Todo_TaskListUpdates_Restore_Text(name)
        case .taskListCreateSection:
            text = I18N.Todo_TaskListUpdates_NewSection_Text(name, sectionName(record, true))
        case .taskListUpdateSection:
            text = I18N.Todo_TaskListUpdates_ChangeSection_Text(
                name,
                sectionName(record, false),
                sectionName(record, true)
            )
        case .taskListDeleteSection:
            text = I18N.Todo_TaskListUpdates_DeleteSection_Text(name, sectionName(record, true))
        case .taskListAddAssignee, .taskListUpdateAssignee, .taskListDeleteAssignee, .taskListUpdateOwner:
            richElement = listPermission(record)
        case .taskListViewAdminSetting:
            text = I18N.Todo_TaskList_Activities_DefaultViewEdited_Text(name)
        case .taskListAddSubscribe: break
        case .taskListDeleteSubscribe: break
        case .taskAddIntoList:
            if case .task = scene {
                let entity = record.taskAddOrRemoveListEntity
                let temp: StrTemplateFunc = { I18N.Todo_TaskUpdates_AddToListName_Text(name, $0) }
                richElement = getAtRichElement(
                    from: [TapElement(
                        name: entity.targetTasklistName,
                        id: AnchorPrefix.taskList + entity.targetTasklistID)],
                    with: temp,
                    and: true)
            } else {
                text = I18N.Todo_TaskUpdates_AddToList_Text(name)
            }
        case .taskRemoveFromList:
            if case .task = scene {
                let temp: StrTemplateFunc = { I18N.Todo_TaskUpdates_RemoveFromListName_Text(name, $0) }
                let entity = record.taskAddOrRemoveListEntity
                richElement = getAtRichElement(
                    from: [
                        TapElement(
                            name: entity.targetTasklistName,
                            id: AnchorPrefix.taskList + entity.targetTasklistID
                        )],
                    with: temp,
                    and: true)
            } else {
                text = I18N.Todo_TaskUpdates_RemoveFromList_Text(name)
            }
        case .taskRepeatGenerate:
            let summary = record.repeatGenerateEntity.taskOldSummary.richText.lc.summerize()
            text = I18N.Todo_TaskUpdates_DuplicateTask_Text(name, summary.isEmpty ? I18N.Todo_Task_NoTitlePlaceholder : summary)
        case .taskCompleted:
            text = I18N.Todo_TaskUpdates_CompleteAll_Text(name)
        case .taskUncomplete:
            text = I18N.Todo_TaskUpdates_ReopenForAll_Text(name)
        case .taskDelete:
            text = I18N.Todo_TaskUpdates_Delete_Text(name)
        case .taskRestore:
            text = I18N.Todo_TaskUpdates_Restore_Text(name)
        case .taskUpdateSummary:
            text = I18N.Todo_TaskUpdates_ChangeTitle_Mobile_Text(name)
            if record.summaryUpdateEntity.taskNewSummary.richText.isEmpty {
                content = Rust.RichContent()
                content?.richText = Utils.RichText.makeRichText(from: I18N.Todo_Task_NoTitlePlaceholder)
            } else {
                content = record.summaryUpdateEntity.taskNewSummary
            }
        case .taskAddDescription:
            text = I18N.Todo_TaskUpdates_AddDesc_Text(name)
            content = record.descriptionUpdateEntity.taskNewDescription
        case .taskUpdateDescription:
            text = I18N.Todo_TaskUpdates_ChangeDesc_Mobile_Text(name)
            content = record.descriptionUpdateEntity.taskNewDescription
        case .taskDeleteDescription:
            text = I18N.Todo_TaskUpdates_DeleteDescription_Text(name)
            content = record.descriptionUpdateEntity.taskOldDescription
        case .taskAddOwner:
            let newOwners = record.ownerUpdateEntity.newOwners.map { user in
                return TapElement(name: user.name, id: user.userID)
            }
            let temp: StrTemplateFunc = { I18N.Todo_TaskUpdates_AddOwner_Text(newOwners.count, name, $0) }
            richElement = getAtRichElement(from: newOwners, with: temp)
        case .taskUpdateOwner:
            let newOwners = record.ownerUpdateEntity.newOwners.map { user in
                return TapElement(name: user.name, id: user.userID)
            }
            let oldOwners = record.ownerUpdateEntity.oldOwners.map { user in
                return TapElement(name: user.name, id: user.userID)
            }
            richElement = updateOwnerElement(new: newOwners, old: oldOwners, name: name)
        case .taskRemoveOwner:
            let oldOwners = record.ownerUpdateEntity.oldOwners.map { user in
                return TapElement(name: user.name, id: user.userID)
            }
            let temp: StrTemplateFunc = { I18N.Todo_TaskUpdates_RemoveOwner_Text(name, $0) }
            richElement = getAtRichElement(from: oldOwners, with: temp)
        case .taskAddFollower:
            text = I18N.Todo_TaskUpdates_Subscribe_Text(name)
        case .taskUserAddFollowers:
            let followers = record.followersEntity.followers.map { user in
                return TapElement(name: user.name, id: user.userID)
            }
            let temp: StrTemplateFunc = { I18N.Todo_TaskUpdates_AddSubscriber_Text(name, $0, followers.count) }
            richElement = getAtRichElement(from: followers, with: temp)
        case .taskAddDueTime:
            let new = record.dueTimeUpdateEntity.newDueTime
            let time = dueTime(from: new.dueMilliTime, isAllDay: new.isAllDay)
            text = I18N.Todo_TaskUpdates_SetDueTime_Text(name, time)
        case .taskUpdateDueTime:
            let old = record.dueTimeUpdateEntity.oldDueTime, new = record.dueTimeUpdateEntity.newDueTime
            let oldTime = dueTime(from: old.dueMilliTime, isAllDay: old.isAllDay)
            let newTime = dueTime(from: new.dueMilliTime, isAllDay: new.isAllDay)
            text = I18N.Todo_TaskUpdates_ChangeDueTime_Text(name, oldTime, newTime)
        case .taskRemoveDueTime:
            let old = record.dueTimeUpdateEntity.oldDueTime
            text = I18N.Todo_TaskUpdates_RemoveDueTime_Text(name, dueTime(from: old.dueMilliTime, isAllDay: old.isAllDay))
        case .taskAddRrule:
            text = I18N.Todo_TaskUpdates_AddRepeatFrequency_Text(name, record.rruleUpdateEntity.newRrule)
        case .taskUpdateRrule:
            text = I18N.Todo_TaskUpdates_ChangeRepeatFrequency_Text(
                name,
                record.rruleUpdateEntity.oldRrule,
                record.rruleUpdateEntity.newRrule
            )
        case .taskRemoveRrule:
            text = I18N.Todo_TaskUpdates_RemoveRepeatFrequency_Text(name, record.rruleUpdateEntity.oldRrule)
        case .taskAddAttachments:
            let count = record.attachmentEntity.attachment.count
            text = I18N.Todo_TaskUpdates_UploadAttachment_Text(count, name)
        case .taskDeleteAttachments:
            let count = record.attachmentEntity.attachment.count
            text = I18N.Todo_TaskUpdates_RemoveAttachment_Text(count, name)
        case .taskAddComment:
            text = I18N.Todo_TaskUpdates_AddComment_Text(name)
            content = record.commentEntity.comment.richContent
        case .taskReplyComment:
            text = I18N.Todo_TaskUpdates_ReplyComment_Text(user: name)
            content = record.commentEntity.comment.richContent
        case .taskListAddCustomField:
            let fieldName = record.listFieldUpdateEntity.fieldName
            text = I18N.Todo_TaskListHistory_UserAddedField_Text(name, fieldName)
        case .taskListRemoveCustomField:
            let fieldName = record.listFieldUpdateEntity.fieldName
            text = I18N.Todo_TaskListHistory_UserRemovedField_Text(name, fieldName)
        case .taskAddCustomFieldValue, .taskUpdateCustomFieldValue, .taskDeleteCustomFieldValue:
            let field = record.fieldValueUpdateEntity.taskField
            let recordText = DetailCustomFields.fieldVal2RecordText(
                field, record.fieldValueUpdateEntity.newValue
            )
            text = I18N.Todo_TaskListHistory_UserChangedValueOfField_Text(
                name, field.name, recordText
            )
        case .taskUpdateStartTime:
            var time = I18N.Todo_TaskUpdates_EmptyValue_Text
            if record.timeUpdateEntity.startMilliTime > 0 {
                time = dueTime(from: record.timeUpdateEntity.startMilliTime, isAllDay: record.timeUpdateEntity.isAllDay)
            }
            text = I18N.Todo_Task_ChangeLog_SetStartDateTime_Text(name, time)
        case .taskUpdateSingleDueTime:
            var time = I18N.Todo_TaskUpdates_EmptyValue_Text
            if record.timeUpdateEntity.dueMilliTime > 0 {
                time = dueTime(from: record.timeUpdateEntity.dueMilliTime, isAllDay: record.timeUpdateEntity.isAllDay)
            }
            text = I18N.Todo_TaskUpdates_SetDueTime_Text(name, time)
        case .taskUpdateStartAndDueTime:
            let start = dueTime(from: record.timeUpdateEntity.startMilliTime, isAllDay: record.timeUpdateEntity.isAllDay)
            let due = dueTime(from: record.timeUpdateEntity.dueMilliTime, isAllDay: record.timeUpdateEntity.isAllDay)
            text = I18N.Todo_TaskUpdates_SetTaskTimeframe_Text(name, start, due)
        case .taskRemoveStartAndDueTime:
            text = I18N.Todo_Task_ChangeLog_RemoveDueDateTime_Text(name)
        case .taskAddMilestone:
            text = I18N.Todo_TaskUpdates_MarkMilestone_Text(name)
        case .taskRemoveMilestone:
            text = I18N.Todo_TaskUpdates_UnmarkMilestone_Text(name)
        case .taskAddDependent, .taskRemoveDependent:
            text = dependentText(record)
        case .taskUpdateDependent:
            text = I18N.Todo_TaskUpdates_UpdateDependency_Text(name)
        case .taskCreate:
            text = I18N.Todo_TaskUpdates_Create_Task_Text(name)
        case .taskPartComplete, .taskPartUncomplete:
            let entity = record.taskCompleteEntity
            var isComplete = true
            if case .taskPartUncomplete = record.recordKey {
                isComplete = false
            }
            //有且只有一个且是自己
            if entity.targetUsers.count == 1, let first = entity.targetUsers.first, first.userID == record.operator.userID {
                text = isComplete
                ? I18N.Todo_TaskUpdates_Complete_Text(name)
                : I18N.Todo_TaskUpdates_Reopen_Text(name)
            } else {
                let assignees = entity.targetUsers.map { user in
                    return TapElement(name: user.name, id: user.userID)
                }
                let tmp: StrTemplateFunc = { 
                    isComplete
                    ? I18N.Todo_TaskUpdates_UserCompletedUserTask_Text(name, $0)
                    : I18N.Todo_TaskUpdates_UserReopenUserTask_Text(name, $0)
                }
                richElement = getAtRichElement(
                    from: assignees,
                    with: tmp)
            }
        case .taskRemoveFollower:
            text = I18N.Todo_TaskUpdates_UnSubscribe_Text(name)
        case .taskUserRemoveFollowers:
            let followers = record.followersEntity.followers.map { user in
                return TapElement(name: user.name, id: user.userID)
            }
            let temp: StrTemplateFunc = { I18N.Todo_TaskUpdates_DeleteSubscriber_Text(followers.count, name, $0) }
            richElement = getAtRichElement(from: followers, with: temp)
        case .taskUpdateReminders:
            let time = record.taskReminderEntity.reminders.isEmpty
            ? I18N.Todo_TaskUpdates_EmptyValue_Text
            : record.taskReminderEntity.reminders
                .map { reminderStr(with: $0) }
                .joined(separator: I18N.Todo_Task_Comma)
            text = I18N.Todo_TaskUpdates_UpdateAlert_Text(name, time)
        case .taskSetAncestor:
            let parentName = targetName(record.taskAncestorEntity.ancestorSummary)
            let temp: StrTemplateFunc = { I18N.Todo_TaskUpdates_AddAsSubtask_Text(name, $0) }
            richElement = getAtRichElement(
                from: [
                    TapElement(
                        name: parentName,
                        id: AnchorPrefix.task + record.taskAncestorEntity.ancestorGuid
                    )
                ],
                with: temp,
                and: true
            )
        case .taskDeleteReferContext:
            text = I18N.Todo_TaskUpdates_DeleteReferContext_Text(name)
            
        case .unknownRecord:
            text = I18N.Todo_Activities_UnknownActivityUpdate_Text
        @unknown default:
            text = I18N.Todo_Activities_UnknownActivityUpdate_Text
        }

        var middle = ActivityRecordTextData()
        do {
            let titleCore = LKRichViewCore()
            titleCore.load(styleSheets: styleSheets)
            var titleElement: LKRichElement?
            if let text = text, !text.isEmpty {
                titleElement = makeContentText([.text(text)])
            } else if let richElement = richElement, !richElement.isEmpty {
                titleElement = makeContentText(richElement)
            }
            if let titleElement = titleElement {
                titleCore.load(renderer: titleCore.createRenderer(titleElement))
                middle.titleCore = titleCore
                middle.titleSize = titleCore.layout(maxContentSize)
                middle.titleElement = titleElement
            }
        }
        middle.quoteText = makeQuoteText(record)
        do {
            // richText里面的元素为空，也是不合法的
            if let content = content, !content.richText.isEmpty {
                let contentCore = LKRichViewCore()
                contentCore.load(styleSheets: styleSheets)
                let contentElement = makeContentRichElement(content)
                contentCore.load(renderer: contentCore.createRenderer(contentElement))
                middle.contentCore = contentCore
                middle.contentSize = contentCore.layout(maxContentSize)
                middle.contentElement = contentElement
                middle.contentAtElements = content.richText.atEelementMap
            }
        }
        return middle
    }
    // swiftlint:enable function_body_length
    // enable-lint: long function

    private func makeContentText(_ elements: [RichElement]) -> LKRichElement {
        var children = [LKRichElement]()
        elements.forEach { ele in
            switch ele {
            case .text(let text):
                let textElement = LKTextElement(
                    classNames: [RichViewAdaptor.ClassName.text],
                    text: text
                )
                children.append(textElement)
            case .at(let at):
                let atElement = LKInlineElement(
                    id: at.id,
                    tagName: RichViewAdaptor.Tag.at,
                    classNames: [RichViewAdaptor.ClassName.atInnerGroup]
                ).children([
                    LKTextElement(
                        classNames: [RichViewAdaptor.ClassName.text],
                        text: at.name
                    )
                ])
                children.append(atElement)
            case .anchor(let anchor):
                let element = LKAnchorElement(
                    tagName: RichViewAdaptor.Tag.a,
                    text: anchor.name,
                    href: anchor.id
                )
                children.append(element)
            }
        }
        let titleElement = LKBlockElement(tagName: RichViewAdaptor.Tag.p).children(children)
        titleElement.style.font(UDFont.systemFont(ofSize: 16.0, weight: .medium)).fontWeight(.medium).color(UIColor.ud.textTitle)
        return titleElement
    }

    private func makeContentRichElement(_ content: Rust.RichContent) -> LKRichElement {
        let result = RichViewAdaptor.parseRichTextToRichElement(
            richText: content.richText,
            isShowReadStatus: false,
            checkIsMe: nil,
            defaultTextColor: UIColor.ud.textTitle,
            imageAttachmentProvider: { [weak self] property in
                guard let self = self else { return LKRichAttachmentImp(view: UIView(frame: .zero)) }
                return self.imageViewRichAttachment(property: property, richText: content.richText)
            }
        )
        return result
    }

    private func makeHeaderData(_ record: Rust.ActivityRecord) -> ActivityRecordContentHeaderData? {
        guard scene != .task else { return nil }
        let color = UIColor.ud.iconN3
        let size = ActivityRecordContentView.Config.headerIconSize
        var icon: UIImage = UDIcon.getIconByKey(.tabTodoFilled, iconColor: color, size: size)
        switch record.targetType {
        case .task:
            icon = UDIcon.getIconByKey(.tabTodoFilled, iconColor: color, size: size)
        case .taskList:
            icon = UDIcon.getIconByKey(.tasklistFilled, iconColor: color, size: size)
        @unknown default: break
        }
        return ActivityRecordContentHeaderData(icon: icon, text: targetName(record.targetName))
    }

    private func targetName(_ richContent: Rust.RichContent) -> String {
        var text = richContent.richText.lc.summerize()
        if text.isEmpty {
            text = I18N.Todo_Task_NoTitlePlaceholder
        }
        return text
    }

    private func makeUserData(_ record: Rust.ActivityRecord) -> ReadableAvatarViewData {
        return ReadableAvatarViewData(
            avatar: AvatarSeed(avatarId: record.operator.userID, avatarKey: record.operator.avatarKey)
        )
    }

    private func makeQuoteText(_ record: Rust.ActivityRecord) -> String? {
        var text: String = ""
        if record.commentEntity.hasReplyComment {
            text = record.commentEntity.replyComment.richContent.richText.lc.summerize()
            record.commentEntity.replyComment.attachments.forEach { _ in
                text += " \(I18N.Lark_Legacy_ImageSummarize)"
            }
            record.commentEntity.replyComment.fileAttachments.forEach { _ in
                text += " \(I18N.Todo_CommentFile_Text)"
            }
        }
        guard !text.isEmpty else {
            return nil
        }
        return text
    }

    private func makeImages(_ record: Rust.ActivityRecord) -> ActivityRecordImageData? {
        guard [.taskAddComment, .taskReplyComment].contains(where: { $0 == record.recordKey }) else {
            return nil
        }
        let images = record.commentEntity.comment.attachments.compactMap { attachment -> Rust.ImageSet? in
            guard attachment.type == .image else { return nil }
            return attachment.imageSet
        }
        return ActivityRecordImageData(images: images, imagesHeight: ImageGridView.preferredHeight(by: images, and: maxContentWidth))
    }

    private func makeAttachments(_ record: Rust.ActivityRecord, needFold: Bool = true) -> ActivityRecordAttachmentData? {
        guard [.taskAddAttachments, .taskDeleteAttachments, .taskAddComment, .taskReplyComment].contains(where: { $0 == record.recordKey }) else {
            return nil
        }
        var attachments: [RustPB.Todo_V1_TodoAttachment]?
        if [.taskAddAttachments, .taskDeleteAttachments].contains(where: { $0 == record.recordKey }) {
            attachments = record.attachmentEntity.attachment
        } else if [.taskAddComment, .taskReplyComment].contains(where: { $0 == record.recordKey }) {
            attachments = record.commentEntity.comment.fileAttachments
        } else {
            attachments = nil
        }
        guard let attachments = attachments else { return nil }

        let footerData: DetailAttachmentFooterViewData
        var cellDatas: [DetailAttachmentContentCellData]
        if needFold {
            let isFold = attachments.count > Config.attachmentFoldCount
            footerData = .init(
                hasMoreState: isFold ? .hasMore(moreCount: attachments.count - Config.attachmentFoldCount) : .noMore,
                isAddViewHidden: true
            )
            let finalAttachments = Array(attachments.prefix(Config.attachmentFoldCount))
            cellDatas = DetailAttachment.attachments2CellDatas(finalAttachments, canDelete: false)
        } else {
            footerData = .init(
                hasMoreState: .noMore,
                isAddViewHidden: true
            )
            cellDatas = DetailAttachment.attachments2CellDatas(attachments, canDelete: false)
        }
        cellDatas = cellDatas.sorted(by: { $0.uploadTime < $1.uploadTime })
        // 计算高度
        var height = cellDatas.reduce(0, { $0 + $1.cellHeight })
        height += footerData.footerHeight
        return ActivityRecordAttachmentData(attachments: cellDatas, attachmentFooter: footerData, attachmentsHeight: height)
    }

    private func makeFooterData(_ record: Rust.ActivityRecord) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(record.operateMilliTime / Utils.TimeFormat.Thousandth))
        var options = TimeFormatUtils.defaultOptions
        options.timeZone = curTimeContext.timeZone
        options.is12HourStyle = curTimeContext.is12HourStyle
        options.timePrecisionType = .minute
        return TimeFormatUtils.formatTime(from: date, with: options)
    }

}

// MARK: - Item

extension ListActivityRecordsViewModel {

    private func sectionName(_ record: Rust.ActivityRecord, _ isNew: Bool) -> String {
        var name: String = ""
        if isNew {
            name = record.sectionUpdateEntity.newSectionName
        } else {
            name = record.sectionUpdateEntity.oldSectionName
        }
        if name.isEmpty {
            name = record.sectionUpdateEntity.isDefault ? I18N.Todo_New_Section_NoSection_Title : I18N.Todo_New_UntitledSection_Title
        }
        return name
    }

    private func dueTime(from timestamp: Int64, isAllDay: Bool) -> String {
        guard timestamp > 0 else {
            return I18N.Todo_TaskUpdates_EmptyValue_Text
        }
        return Utils.DueTime.formatedString(
            from: timestamp / Utils.TimeFormat.Thousandth,
            in: curTimeContext.timeZone,
            isAllDay: isAllDay,
            is12HourStyle: curTimeContext.is12HourStyle
        )
    }
    
    private func reminderStr(with reminder: Rust.Reminder) -> String {
        let is12HourStyle = curTimeContext.is12HourStyle
        let timeZone = curTimeContext.timeZone
        switch reminder.type {
        case .relative:
            return Utils.Reminder.reminderStr(
                minutes: reminder.time,
                isAllDay: reminder.isAllDay,
                is12HourStyle: is12HourStyle
            )
        case .absolute:
            return Utils.TimeFormat.formatDateTimeStr(
                by: reminder.time,
                timeZone: timeZone,
                is12HourStyle: is12HourStyle
            )
        case .floating:
            Detail.assertionFailure("TodoEditRecord get reminderStr failed. type:\(reminder.type) time:\(reminder.time)")
            return ""
        @unknown default:
            return ""
        }
    }

    private func dependentText(_ record: Rust.ActivityRecord) -> String? {
        guard [.taskAddDependent, .taskRemoveDependent].contains(where: { $0 == record.recordKey }) else {
            return nil
        }
        var deps = record.taskDependentEntity.newDependents
        if record.recordKey == .taskRemoveDependent {
            deps = record.taskDependentEntity.oldDependents
        }
        let preDeps = deps.filter({ $0.type == .prev })
        let nextDeps = deps.filter({ $0.type == .next })
        let userName = record.operator.name
        var rawText: String?
        if !preDeps.isEmpty, nextDeps.isEmpty {
            if preDeps.count > 1 {
                rawText = I18N.Todo_TaskUpdates_SetTaskToBeBlockedByPlural_Text(preDeps.count, userName)
                if record.recordKey == .taskRemoveDependent {
                    rawText = I18N.Todo_TaskUpdates_RemoveBlockedByPlural_Text(preDeps.count, userName)
                }
            } else {
                if let preDep = preDeps.first {
                    let summaryText = targetName(preDep.taskSummary)
                    rawText = I18N.Todo_TaskUpdates_SetTaskToBeBlockedBy_Text(userName, summaryText)
                    if record.recordKey == .taskRemoveDependent {
                        rawText = I18N.Todo_TaskUpdates_RemoveBlockedBy_Text(userName, summaryText)
                    }
                }
            }
        } else if preDeps.isEmpty, !nextDeps.isEmpty {
            if nextDeps.count > 1 {
                rawText = I18N.Todo_TaskUpdates_SetToBlockPlural_Text(nextDeps.count, userName)
                if record.recordKey == .taskRemoveDependent {
                    rawText = I18N.Todo_TaskUpdates_RemoveFromBlockingPlural_Text(nextDeps.count, userName)
                }
            } else {
                if let nextDep = nextDeps.first {
                    let summaryText = targetName(nextDep.taskSummary)
                    rawText = I18N.Todo_TaskUpdates_SetToBlock_Text(userName, summaryText)
                    if record.recordKey == .taskRemoveDependent {
                        rawText = I18N.Todo_TaskUpdates_RemoveFromBlocking_Text(userName, summaryText)
                    }
                }
            }
        } else {
            rawText = I18N.Todo_Activities_UnknownActivityUpdate_Text
        }
        return rawText
    }

    private struct TapElement {
        var name: String
        // 群也会复用这个，当为nil的时候表示群，不能跳转
        var id: String
    }

    private enum RichElement {
        case text(String)
        case at(TapElement)
        case anchor(TapElement)
    }

    private func listPermission(_ record: Rust.ActivityRecord) -> [RichElement]? {
        let atElements = record.assigneeUpdateEntity.targetMembers.compactMap { member in
            var name: String?
            switch member.type {
            case .unknown: name = nil
            case .user: name = member.user.name
            case .group: name = member.chat.name
            case .app, .docs:  break
            @unknown default: break
            }
            if let name = name {
                return TapElement(name: name, id: member.user.userID)
            }
            return nil
        }

        let anchorElements = record.assigneeUpdateEntity.targetMembers.compactMap { member in
            if member.type == .docs {
                var name = member.doc.name
                if name.isEmpty {
                    name = member.doc.hasPermission_p ?
                    I18N.Todo_Doc_UntitledDocument_Title :
                    I18N.Todo_Activities_DocNameUnauthorized_Text
                }
                return TapElement(name: name, id: member.doc.url)
            }
            return nil
        }

        var temp: StrTemplateFunc?
        let name = record.operator.name
        typealias Role = RustPB.Todo_V1_TodoItemMemberRole
        switch record.recordKey {
        case .taskListAddAssignee:
            switch record.assigneeUpdateEntity.newRole {
            case .reader:
                if !anchorElements.isEmpty {
                    temp = { I18N.Todo_Activities_InsertListToDoc_Text(
                        name,
                        $0,
                        I18N.Todo_Activities_InsertListToDocCanView_Variable)
                    }
                } else {
                    temp = { I18N.Todo_TaskListUpdates_InvieteNewCanView_Text(atElements.count, name, $0) }
                }
            case .inherit:
                if !anchorElements.isEmpty {
                    temp = { I18N.Todo_Activities_InsertListToDoc_Text(
                        name,
                        $0,
                        I18N.Todo_Activities_InsertListToDocFollowDocsPermission_Variable)
                    }
                } else {
                    temp = nil
                }
            case .owner, .writer:
                if !anchorElements.isEmpty {
                    temp = { I18N.Todo_Activities_InsertListToDoc_Text(
                        name,
                        $0,
                        I18N.Todo_Activities_InsertListToDocCanEdit_Variable)
                    }
                } else {
                    temp = { I18N.Todo_TaskListUpdates_inviteNewCanEdit_Text(atElements.count, name, $0) }
                }

            @unknown default:
                temp = nil
            }
        case .taskListUpdateAssignee:
            switch (record.assigneeUpdateEntity.oldRole, record.assigneeUpdateEntity.newRole) {
            case (.reader, .writer):
                if !anchorElements.isEmpty {
                    temp = { I18N.Todo_Activities_DocCollaboratorsPermissionChange_Text(
                        name,
                        $0,
                        I18N.Todo_Activities_InsertListToDocCanView_Variable,
                        I18N.Todo_Activities_InsertListToDocCanEdit_Variable)
                    }
                } else {
                    temp = { I18N.Todo_TaskListUpdates_ViewToEdit_Text(name, $0) }
                }
            case (.writer, .reader):
                if !anchorElements.isEmpty {
                    temp = { I18N.Todo_Activities_DocCollaboratorsPermissionChange_Text(
                        name,
                        $0,
                        I18N.Todo_Activities_InsertListToDocCanEdit_Variable,
                        I18N.Todo_Activities_InsertListToDocCanView_Variable)
                    }
                } else {
                    temp = { I18N.Todo_TaskListUpdates_EditToView_Text(name, $0) }
                }
            case (.inherit, _):
                if !anchorElements.isEmpty {
                    temp = { I18N.Todo_Activities_DocCollaboratorsPermissionChange_Text(
                        name,
                        $0,
                        I18N.Todo_Activities_InsertListToDocFollowDocsPermission_Variable,
                        record.assigneeUpdateEntity.newRole == .reader ?
                        I18N.Todo_Activities_InsertListToDocCanView_Variable :
                            I18N.Todo_Activities_InsertListToDocCanEdit_Variable)
                    }
                } else {
                    temp = nil
                }
            case (_, .inherit):
                if !anchorElements.isEmpty {
                    temp = { I18N.Todo_Activities_DocCollaboratorsPermissionChange_Text(
                        name,
                        $0,
                        record.assigneeUpdateEntity.oldRole == .reader ?
                        I18N.Todo_Activities_InsertListToDocCanView_Variable :
                            I18N.Todo_Activities_InsertListToDocCanEdit_Variable,
                        I18N.Todo_Activities_InsertListToDocFollowDocsPermission_Variable)
                    }
                } else {
                    temp = nil
                }
            @unknown default:
                temp = nil
            }
        case .taskListDeleteAssignee:
            temp = { I18N.Todo_TaskListUpdates_RemoveCollaborator_Text(name, $0) }
        case .taskListUpdateOwner:
            temp = { I18N.Todo_TaskListUpdates_ChangeOwner_Text(name, $0) }
        @unknown default:
            temp = nil
        }
        if let temp = temp {
            return getAtRichElement(from: anchorElements.isEmpty ? atElements : anchorElements, with: temp, and: !anchorElements.isEmpty)
        }
        return nil
    }

    private func updateOwnerElement(new: [TapElement], old: [TapElement], name: String) -> [RichElement]? {
        let newName = new.map(\.name).joined(separator: I18N.Todo_Task_Comma)
        let oldName = old.map(\.name).joined(separator: I18N.Todo_Task_Comma)
        let newWrapperName = "\(UUID().uuidString)\(newName)\(UUID().uuidString)"
        let oldWrapperName = "\(UUID().uuidString)\(oldName)\(UUID().uuidString)"
        let text = I18N.Todo_TaskUpdates_ChangeOwner_Text(name, oldWrapperName, newWrapperName)
        guard let oldRange = text.range(of: oldWrapperName), let newRange = text.range(of: newWrapperName) else {
            return nil
        }
        guard oldRange.lowerBound <= oldRange.upperBound,
              newRange.lowerBound <= newRange.upperBound,
              oldRange.upperBound <= newRange.lowerBound else {
            ActivityRecord.logger.error("out of range")
            return nil
        }
        var elements = [RichElement]()
        var sub = text[..<oldRange.lowerBound]
        if !sub.isEmpty {
            elements.append(.text(String(sub)))
        }
        elements.append(contentsOf: joined(old))
        sub = text[oldRange.upperBound..<newRange.lowerBound]
        if !sub.isEmpty {
            elements.append(.text(String(sub)))
        }
        elements.append(contentsOf: joined(new))
        sub = text[newRange.upperBound...]
        if !sub.isEmpty {
            elements.append(.text(String(sub)))
        }
        return elements
    }

    private typealias StrTemplateFunc = (String) -> String
    private func getAtRichElement(from atElements: [TapElement], with templateFunc: StrTemplateFunc, and isAnchor: Bool = false) -> [RichElement]? {
        let otherName = atElements.map(\.name).joined(separator: I18N.Todo_Task_Comma)
        guard let texts = separate(for: otherName, with: templateFunc), texts.count == 2 else {
            return nil
        }
        guard let first = texts.first, let last = texts.last else {
            return nil
        }
        var elements = [RichElement]()
        switch (first.isEmpty, last.isEmpty) {
        case (false, false):
            //表示在中间
            elements.append(.text(first))
            elements.append(contentsOf: joined(atElements, isAnchor))
            elements.append(.text(last))
        case (true, true):
            //头尾都为空，不合法
            break
        case (false, true):
            // 尾部为空
            elements.append(.text(first))
            elements.append(contentsOf: joined(atElements, isAnchor))
        case (true, false):
            // 头部为空
            elements.append(contentsOf: joined(atElements, isAnchor))
            elements.append(.text(last))
        }
        return elements.isEmpty ? nil : elements
    }

    private func joined(_ ats: [TapElement], _ isAnchor: Bool = false) -> [RichElement] {
        var elements = [RichElement]()
        var index = 0
        for value in ats {
            elements.append(isAnchor ? .anchor(value) : .at(value))
            index += 1
            if index < ats.count {
                elements.append(.text(I18N.Todo_Task_Comma))
            }
        }
        return elements
    }

    private func separate(for text: String, with templateFunc: StrTemplateFunc) -> [String]? {
        guard !text.isEmpty else { return nil }
        // text 前后加 uuid，避免 templateFunc 中出现了和 text 相同的文案从而被错误识别
        let uuid: String = UUID().uuidString
        let wrappedText = "\(uuid)\(text)\(uuid)"
        let fullText = templateFunc(wrappedText)
        return fullText.components(separatedBy: wrappedText)
    }
}

// MARK: - ImageView

extension ListActivityRecordsViewModel {

    private func imageViewRichAttachment(property: Rust.RichText.Element.ImageProperty, richText: Rust.RichText) -> LKRichAttachment {
        let originSize = CGSize(width: CGFloat(property.originWidth), height: CGFloat(property.originHeight))
        let size = BaseImageViewWrapper.calculateSize(originSize: originSize, maxSize: maxContentSize, minSize: Config.minImageSize)

        let imageView = BaseImageViewWrapper(maxSize: maxContentSize, minSize: Config.minImageSize)
        imageView.backgroundColor = UIColor.ud.bgBody
        imageView.frame = CGRect(origin: .zero, size: size)
        imageView.clipsToBounds = true

        imageView.set(
            originSize: originSize,
            needLoading: true,
            animatedDelegate: nil,
            forceStartIndex: 0,
            forceStartFrame: nil,
            imageTappedCallback: { [weak self] imageView in
                self?.tapImage(imageView.imageView, property: property, richText: richText)
            },
            setImageAction: { (imageView, completion) in
                let imageSet = ImageItemSet.transform(imageProperty: property)
                let key = imageSet.generatePostMessageKey(forceOrigin: false)
                let placeholder = imageSet.inlinePreview
                let resource = LarkImageResource.default(key: key)
                imageView.bt.setLarkImage(with: resource,
                                          placeholder: placeholder,
                                          completion: { result in
                    switch result {
                    case let .success(imageResult):
                        completion(imageResult.image, nil)
                    case let .failure(error):
                        completion(placeholder, error)
                    }
                })
            }
        )
        return LKAsyncRichAttachmentImp(
            size: size,
            viewProvider: { imageView },
            ascentProvider: nil,
            verticalAlign: .baseline
        )
    }

    private func tapImage(_ sourceImage: UIImageView, property: Rust.RichText.Element.ImageProperty, richText: Rust.RichText) {
        let images = richText.imageIds.compactMap { elementId in
            return richText.elements[elementId]?.property.image
        }
        guard let index = images.firstIndex(where: { $0.originKey == property.originKey }) else {
            ActivityRecord.logger.error("can't find index. key: \(property.originKey)")
            return
        }
        onTapImage?(index, images, sourceImage)
    }

}

// MARK: - CollectionView

extension ListActivityRecordsViewModel {

    func numberOfSections() -> Int {
        return cellDatas.count
    }

    func numberOfItems(in section: Int) -> Int {
        guard let section = safeCheck(in: section) else { return .zero }
        return cellDatas[section].items.count
    }

    func itemInfo(at indexPath: IndexPath) -> ActivityRecordSectionData.ItemType? {
        guard let (section, row) = safeCheck(at: indexPath) else { return nil }
        return cellDatas[section].items[row]
    }

    func needPreload(at indexPath: IndexPath) -> Bool {
        guard currentLoadMoreId == nil, !cursor.isEmpty else { return false }
        let allItemCnt = cellDatas.reduce(0) { partialResult, section in
            return partialResult + section.items.count
        }
        // 总数要大于30屏才能触发
        guard allItemCnt >= Utils.List.fetchCount.initial else { return false }
        var leftCount = 0
        for (i, item) in cellDatas.enumerated() {
            if i > indexPath.section {
                leftCount += item.items.count
            } else if i == indexPath.section {
                leftCount += (item.items.count - indexPath.row)
            } else {
                continue
            }
        }
        let needFetch = leftCount <= Utils.List.fetchCount.loadMore
        guard needFetch else { return false }
        return true
    }

    func itemSize(at indexPath: IndexPath, and width: CGFloat) -> CGSize {
        guard let (section, row) = safeCheck(at: indexPath) else { return .zero }
        let itemInfo = cellDatas[section].items[row]
        if let cacheHeight = itemInfo.itemHeight {
            return CGSize(width: width, height: cacheHeight)
        }
        let height = itemInfo.preferredHeight(maxWidth: width)
        // update cache height
        cellDatas[section].items[row].updateCacheHeight(height)
        return CGSize(width: width, height: height)
    }

    func itemSpace() -> CGFloat {
        guard scene == .taskList else {
            return .zero
        }
        return Config.itemSpace
    }

    func itemCorner(at indexPath: IndexPath) -> (corners: CACornerMask, cornerSize: CGSize) {
        var corners: CACornerMask = []
        switch scene {
        case .user:
            if let (section, row) = safeCheck(at: indexPath), case .content = cellDatas[section].items[row] {
                let pre = row - 1, next = row + 1
                if pre >= 0, case .combine = cellDatas[section].items[pre] {
                    corners.insert([.layerMinXMinYCorner, .layerMaxXMinYCorner])
                }
                if next < cellDatas[section].items.count, case .content = cellDatas[section].items[next] {
                    // if next item is content, do nothing
                } else {
                    corners.insert([.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
                }
            }
        case .task:
            if let (section, row) = safeCheck(at: indexPath), case .content = cellDatas[section].items[row] {
                if row == 0 {
                    corners.insert([.layerMinXMinYCorner, .layerMaxXMinYCorner])
                }
                if row + 1 == cellDatas[section].items.count {                    corners.insert([.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
                }
            }
        default:
            corners.insert([.layerMinXMinYCorner, .layerMaxXMinYCorner])
            corners.insert([.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
        }
        return (corners, CGSize(width: Config.itemCornerRadius, height: Config.itemCornerRadius))
    }

    func sectionHeaderSize(in section: Int, and width: CGFloat) -> CGSize {
        guard let section = safeCheck(in: section) else {
            return .zero
        }
        let data = cellDatas[section].header
        guard let height = data.height else { return .zero }
        return CGSize(width: width, height: height)
    }

    func sectionHeader(in section: Int) -> ActivityRecordSectionHeaderData? {
        guard let section = safeCheck(in: section) else {
            return nil
        }
        return cellDatas[section].header
    }

    func safeCheck(at indexPath: IndexPath) -> (section: Int, row: Int)? {
        return ActivityRecordSectionData.safeCheck(indexPath: indexPath, with: cellDatas)
    }

    func safeCheck(in section: Int) -> Int? {
        return ActivityRecordSectionData.safeCheck(section: section, with: cellDatas)
    }

    func expandAttach(at indexPath: IndexPath) {
        guard let (section, row) = safeCheck(at: indexPath) else {
            ActivityRecord.logger.error("index path is invliad")
            return
        }
        if case .content(let data) = cellDatas[section].items[row], let metaData = data.metaData {
            if let attachments = makeAttachments(metaData, needFold: false) {
                var item = data
                item.content.attachments = attachments
                // 清理缓存的高度
                item.itemHeight = nil
                cellDatas[section].items[row] = .content(item)
                rxListUpdate.accept(.reloadIndex(indexPath: indexPath))
            }
        }
    }

    func expandContent(at indexPath: IndexPath) {
        guard let (section, row) = safeCheck(at: indexPath) else {
            ActivityRecord.logger.error("expand content failed. couse index path is invliad")
            return
        }
        if case .content(let data) = cellDatas[section].items[row] {
            var item = data
            item.showMore = false
            // 清理缓存的高度
            item.itemHeight = nil
            cellDatas[section].items[row] = .content(item)
            rxListUpdate.accept(.reloadIndex(indexPath: indexPath))
        }
    }

    struct TaskListAction {
        var name: String
        var guid: String
    }
    func taskListActions(_ record: Rust.ActivityRecord?) -> [TaskListAction]? {
        guard let record = record, !record.relatedTaskListGuids.isEmpty else { return nil }
        var actions = [TaskListAction]()
        record.relatedTaskListGuids.forEach { guid in
            guard let name = record.taskListGuidToNames[guid] else { return }
            actions.append(TaskListAction(name: name, guid: guid))
        }
        return actions.isEmpty ? nil : actions
    }
}

// MARK: - Layout

extension ListActivityRecordsViewModel {

    var maxContentWidth: CGFloat {
        typealias config = ActivityRecordContentView.Config
        let maxWidth = collectionViewWidth - config.leftPadding - config.rightPadding - ActivityRecordUserView.Config.avatarSize.width - config.largeSpace
        return maxWidth
    }

    var maxContentSize: CGSize {
        return CGSize(width: maxContentWidth, height: CGFloat.greatestFiniteMagnitude)
    }

    var styleSheets: [CSSStyleSheet] {
        return RichViewAdaptor.createStyleSheets(
            config: RichViewAdaptor.Config(
                normalFont: UDFont.systemFont(ofSize: 16),
                atColor: AtColor())
        )
    }

    struct Config {
        static let leftPadding: CGFloat = 16.0
        static let rightPadding: CGFloat = 16.0
        static let topPadding: CGFloat = 16.0
        static let minImageSize: CGSize = CGSize(width: 50, height: 50)
        static let attachmentFoldCount: Int = DetailAttachment.foldCount
        static let itemSpace: CGFloat = 12.0
        static let itemCornerRadius: CGFloat = 8.0
    }
}

extension ListActivityRecordsViewModel {

    var title: String {
        if case .task = scene {
            return I18N.Todo_Task_Changelog
        }
        return I18N.Todo_Updates_Title
    }

    var curTimeContext: TimeContext {
        return TimeContext(
            currentTime: Int64(Date().timeIntervalSince1970),
            timeZone: timeService?.rxTimeZone.value ?? .current,
            is12HourStyle: timeService?.rx12HourStyle.value ?? false
        )
    }
}
