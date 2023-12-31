//
//  V3ListCellData.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/23.
//

import CTFoundation
import RichLabel
import UniverseDesignIcon
import CoreGraphics
import UniverseDesignFont

// MARK: - Cell Data

struct V3ListCellData {
    var contentType: V3ListContentType?
    var isFocused: Bool = false
    // 缓存一个高度，避免多次计算
    var cellHeight: CGFloat?

    var todo: Rust.Todo
    var completeState: CompleteState

    init(with todo: Rust.Todo, completeState: CompleteState) {
        self.todo = todo
        self.completeState = completeState
    }
}

extension V3ListCellData {

    func preferredHeight(maxWidth: CGFloat) -> CGFloat {
        guard let contentType = contentType else {
            return .leastNormalMagnitude
        }
        switch contentType {
        case .content(let data):
            return data.preferredHeight(maxWidth: maxWidth)
        case .availableToDrop:
            return ListConfig.Cell.minHeight
        case .skeleton:
            return ListConfig.Cell.middleHeight
        }
    }
}

extension V3ListCellData {
    /// 用户视角的完成时间（单位：毫秒）
    var userCompletedMilliTime: Int64 { todo.userCompletedTime(with: completeState, isMilliTime: true) }
}

extension V3ListCellData {

    /// 接受Extra Push 主要更新子任务进度, 评论数
    /// - Parameters:
    ///   - commentCnt: 评论数
    ///   - progress: 子任务进度
    mutating func updateTodoExtra(commentCnt: Int32? = nil, progress: Rust.TodoProgress? = nil) {
        var newTodo = todo
        if let commentCnt = commentCnt {
            newTodo.commentCount = commentCnt
        }
        // 只有或签任务才展示子任务
        if let progress = progress {
            newTodo.progress = progress
        }
        todo = newTodo
        if case .content(var data) = contentType {
            data.updateExtensionInfo(newTodo)
            contentType = .content(data: data)
        }
    }

}

// MARK: - For Animation

extension V3ListCellData: DiffableType, Equatable {

    var diffId: String {
        guard case .content = contentType else {
            return todo.logInfo
        }
        return todo.guid
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.diffId == rhs.diffId
    }

}

enum V3ListContentType {
    case content(data: V3ListContentData)
    case skeleton
    case availableToDrop

    var ownerBorderColor: UIColor? {
        switch self {
        case .content(let data):
            return data.ownerInfo?.avatars.first?.boarderColor
        case .skeleton, .availableToDrop:
            return nil
        }
    }
}

// MARK: - Cell Content Data

struct V3ListContentData {
    var checkboxInfo: (state: CheckboxState, identifier: String, isRotated: Bool)
    var titleInfo: (title: AttrText, outOfRangeText: AttrText, size: CGSize)
    var ownerInfo: AvatarGroupViewData?
    var timeInfo: V3ListTimeInfo?
    var extensionInfo: V3ListExtensionInfo?

    init(
        todo: Rust.Todo,
        isTaskEditableInContainer: Bool,
        completeState: (state: CompleteState, useTodoState: Bool) ,
        richContentService: RichContentService?,
        timeContext: TimeContext
    ) {
        self.checkboxInfo = Self.checkBoxInfo(todo, and: completeState.state, and: isTaskEditableInContainer, and: completeState.useTodoState)
        self.titleInfo = Self.getAttrTitle(todo, by: richContentService, and: completeState.state)
        self.ownerInfo = Self.owner(todo, and: completeState.state)
        self.timeInfo = Self.timeInfo(todo, with: timeContext, and: completeState.useTodoState ? (todo.completedMilliTime > 0) : completeState.state.isCompleted)
        self.extensionInfo = extensionInfo(todo)
    }
}

extension V3ListContentData {

    func preferredHeight(maxWidth: CGFloat) -> CGFloat {
        typealias Config = ListConfig.Cell
        // 内容最大宽度
        let maxContentWidth = maxWidth - Config.leftPadding - Config.checkBoxSize.width - Config.horizontalSpace - Config.rightPadding
        // 标题计算
        var maxTitleWidth = maxContentWidth
        if let owner = ownerInfo {
            maxTitleWidth -= Config.horizontalSpace + (owner.width ?? 0)
        }
        var height: CGFloat = Config.minTitleHeight
        if titleInfo.size.width > maxTitleWidth {
            // 标题未两行
            height = Config.maxTitleHeight - Config.singleSpace
        }
        height += Config.topPadding + Config.bottomPadding
        // time + extension 计算
        switch (timeInfo, extensionInfo) {
        case (.some(let time), .some(let exInfo)):
            if time.totalWidth + exInfo.totalWidth + Config.separateSpace * 2 + Config.separateWidth > maxContentWidth {
                // 超过一行
                height += Config.verticalSpace + Config.timeHeight
                height += Config.verticalSpace + Config.extensionHeight
            } else {
                // 在一行之内
                height += Config.verticalSpace + Config.extensionHeight
            }
        case (.none, .some):
            height += Config.verticalSpace + Config.extensionHeight
        case (.some, .none):
            height += Config.verticalSpace + Config.timeHeight
        default:
            // 单行上下各加
            height += Config.singleSpace + Config.singleSpace
        }
        return height
    }

}

extension V3ListContentData {

    // MARK: - CheckBox

    static func checkBoxInfo(
        _ todo: Rust.Todo,
        and completeState: CompleteState,
        and isTaskEditableInContainer: Bool,
        and useTodoState: Bool
    ) -> (state: CheckboxState, identifier: String, isRotated: Bool) {
        var checkState: CheckboxState {
            if todo.isCompleteEnabled(with: completeState) || isTaskEditableInContainer {
                return .enabled(isChecked: useTodoState ? (todo.completedMilliTime > 0) : completeState.isCompleted)
            } else {
                return .disabled(isChecked: useTodoState ? (todo.completedMilliTime > 0) : completeState.isCompleted, hasAction: false)
            }
        }
        return (state: checkState, identifier: todo.guid, isRotated: FeatureGating.boolValue(for: .gantt) && todo.isMilestone)
    }

    // MARK: - Title

    static func getAttrTitle(
        _ todo: Rust.Todo,
        by richContentService: RichContentService?,
        and completeState: CompleteState
    ) -> (title: AttrText, outOfRangeText: AttrText, size: CGSize) {
        let titleAttrs = titleAttrs(completeState.isCompleted)
        var attrText: AttrText
        if todo.selfPermission.isReadable {
            if !todo.richSummary.richText.isEmpty, let service = richContentService {
                var config = RichLabelContentBuildConfig(baseAttrs: titleAttrs, lineSeperator: " ")
                config.anchorConfig.sourceIdForHangEntity = todo.guid
                let result = service.buildLabelContent(with: todo.richSummary, config: config)
                attrText = result.attrText
            } else {
                // 空数据
                attrText = MutAttrText(
                    string: I18N.Todo_Task_NoTitlePlaceholder,
                    attributes: titleAttrs)
            }
        } else {
            // 无权限
            attrText = MutAttrText(
                string: I18N.Todo_Tasks_BlockingTasksNoPermissionView_Text,
                attributes: titleAttrs)
        }

        let outOfRangeText = AttrText(string: "\u{2026}", attributes: titleAttrs)

        // 计算title宽度
        let size = attrText.componentTextSize(for: CGSize(width: CGFloat.greatestFiniteMagnitude, height: ListConfig.Cell.minTitleHeight), limitedToNumberOfLines: 1)
        return (attrText, outOfRangeText, size)
    }

    private static func titleAttrs(_ isCompleted: Bool) -> [AttrText.Key: Any] {
        let color = isCompleted ? UIColor.ud.textPlaceholder : UIColor.ud.textTitle
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineBreakMode = .byWordWrapping
        var attrs: [AttrText.Key: Any] = [
            .font: UDFont.systemFont(ofSize: 16),
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
        if isCompleted {
            attrs[LKLineAttributeName] = LKLineStyle(
                color: UIColor.ud.textCaption,
                position: .strikeThrough,
                style: .line
            )
        }
        return attrs
    }

    // MARK: - Owners

    static func owner(_ todo: Rust.Todo, and completeState: CompleteState) -> AvatarGroupViewData? {
        guard !todo.isNoAssignee else { return nil }
        var showCheck = true
        if case .classicMode = completeState {
            showCheck = false
        }
        let avatars = todo.assignees
            .map(Assignee.init(model:))
            .map { CheckedAvatarViewData(icon: .avatar($0.avatar), isChecked: showCheck && $0.completedTime != nil, boarderColor: UIColor.ud.bgBody) }
        // 大于两个头像就只展示一个头像+数据；否则只展示头像
         let maxCount = avatars.count > 2 ? 1 : 2
        let viewData = AvatarGroupViewData(avatars: Array(avatars.prefix(maxCount)), style: .big, remainCount: avatars.count - maxCount)
        return viewData
    }

    // MARK: - Time

    static func timeInfo(_ todo: Rust.Todo, with timeContext: TimeContext, and shouldChangeColor: Bool) -> V3ListTimeInfo? {
        guard let text = Utils.TimeFormat.formatTimeStr(by: todo, timeContext: timeContext) else { return nil }
        var reminder: UIImage? ,repeatRule: UIImage?, color: UIColor = UIColor.ud.textCaption
        if shouldChangeColor {
            color = UIColor.ud.textPlaceholder
        } else {
            color = V3ListTimeGroup.dueTime(
                dueTime: todo.dueTimeForDisplay(timeContext.timeZone),
                timeContext: timeContext
            ).color
        }
        var iconWidth: CGFloat = 0
        if let pb = todo.reminders.first, let r = Reminder(pb: pb), r.hasReminder {
            reminder = UDIcon.getIconByKey(
                .bellOutlined,
                iconColor: color,
                size: ListConfig.Cell.timeIconSize
            )
            iconWidth += ListConfig.Cell.timeIconSize.width + ListConfig.Cell.timeIconTextSpace
        }

        if todo.isRRuleValid {
            repeatRule = UDIcon.getIconByKey(
                .repeatOutlined,
                iconColor: color,
                size: ListConfig.Cell.timeIconSize
            )
            iconWidth += ListConfig.Cell.timeIconSize.width + ListConfig.Cell.timeIconTextSpace
        }
        let textWidth = CGFloat(ceil(text.size(withAttributes: [
            .font: ListConfig.Cell.detailFont
        ]).width))

        return V3ListTimeInfo(
            text: text,
            color: color,
            reminderIcon: reminder,
            repeatRuleIcon: repeatRule,
            textWidth: textWidth,
            totalWidth: textWidth + iconWidth
        )
    }

}

extension V3ListContentData {

    mutating func updateExtensionInfo(_ todo: Rust.Todo) {
        extensionInfo = extensionInfo(todo)
    }

    func extensionInfo(_ todo: Rust.Todo) -> V3ListExtensionInfo? {
        let iconWidth = ListConfig.Cell.extensionIconSize.width + ListConfig.Cell.extensionIconTextSpace
        var totalWidth: CGFloat = 0
        let subTasksProgress = subTaskProcess(numerator: todo.progress.completed, denominator: todo.progress.total)
        var subTasksProgressWidth: CGFloat = 0
        if let subTasksProgress = subTasksProgress {
            subTasksProgressWidth = CGFloat(ceil(subTasksProgress.size(withAttributes: [
                .font: ListConfig.Cell.detailFont
            ]).width))
            totalWidth += iconWidth + subTasksProgressWidth
        }

        var attachmentsCnt: String?
        var attachmentsCntWidth: CGFloat = 0
        attachmentsCnt = attachmentsCountStr(todo.attachments.count)
        if let attachmentsCnt = attachmentsCnt {
            attachmentsCntWidth = CGFloat(ceil(attachmentsCnt.size(withAttributes: [
                .font: ListConfig.Cell.detailFont
            ]).width))
            totalWidth += iconWidth + attachmentsCntWidth
        }

        let commentsCnt = commentCountStr(todo.commentCount)
        var commentsCntWidth: CGFloat = 0
        if let commentsCnt = commentsCnt {
            commentsCntWidth = CGFloat(ceil(commentsCnt.size(withAttributes: [
                .font: ListConfig.Cell.detailFont
            ]).width))
            totalWidth += iconWidth + commentsCntWidth
        }
        if subTasksProgress == nil, attachmentsCnt == nil, commentsCnt == nil {
            return nil
        }
        return V3ListExtensionInfo(
            subTasksProgress: subTasksProgress,
            subTasksProgressWidth: subTasksProgressWidth,
            attachmentsCnt: attachmentsCnt,
            attachmentsCntWidth: attachmentsCntWidth,
            commentsCnt: commentsCnt,
            commentsCntWidth: commentsCntWidth,
            totalWidth: totalWidth
        )
    }

    private func attachmentsCountStr(_ cnt: Int) -> String? {
        guard cnt > 0 else { return nil }
        if cnt > 99 {
            return "99+"
        }
        return "\(cnt)"
    }

    func commentCountStr(_ cnt: Int32) -> String? {
        guard cnt > 0 else { return nil }
        if cnt > 99 {
            return "99+"
        }
        return "\(cnt)"
    }

    func subTaskProcess(numerator: Int32, denominator: Int32) -> String? {
        guard denominator > 0 else { return nil }
        return "\(numerator)/\(denominator)"
    }

}
