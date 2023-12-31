//
//  DetailSubTaskContentCell.swift
//  Todo
//
//  Created by baiyantao on 2022/7/28.
//

import Foundation
import EditTextView
import UniverseDesignIcon
import UIKit
import RxSwift
import LarkSwipeCellKit

protocol DetailSubTaskContentCellDelegate: AnyObject {
    func onCheckboxClick(_ cell: DetailSubTaskContentCell, _ viewData: DetailSubTaskContentCellData?)
    func onAddTimeBtnClick(_ cell: DetailSubTaskContentCell)
    func onAddOwnerBtnClick(_ cell: DetailSubTaskContentCell)
    func onOwnerAvatarClick(_ cell: DetailSubTaskContentCell)
    func onTimeClearBtnClick(_ cell: DetailSubTaskContentCell)
    func onTimeDetailClick(_ cell: DetailSubTaskContentCell)
    func onDetailClick(_ cell: DetailSubTaskContentCell)
    func onSummaryUpdate(content: Rust.RichContent, _ cell: DetailSubTaskContentCell)
    func onReturnClick(_ cell: DetailSubTaskContentCell)
    func onEmptyBackspaceClick(_ cell: DetailSubTaskContentCell)
    func onBeginEditing(_ cell: DetailSubTaskContentCell)
    func onEmptyEndEditing(_ cell: DetailSubTaskContentCell)
}

struct DetailSubTaskContentCellData {
    var todo: Rust.Todo?

    var checkboxState: CheckboxState = .enabled(isChecked: false)
    var isMilestone: Bool = false
    var richSummary: Rust.RichContent?
    var hasStrikethrough: Bool = false
    var assignees: [Assignee] = []
    var timeComponents: TimeComponents?
    var taskMode: Rust.TaskMode = .taskComplete

    var isForCreating: Bool = true
    var currentUserId: String?
    var timeZone: TimeZone?
    var is12HourStyle: Bool = false

    var rank: String = ""

    // 在 UI 上不会展示的元素
    var richNotes: Rust.RichContent?
    var attachments = [Rust.Attachment]()
}

extension DetailSubTaskContentCellData {
    var hasAssignees: Bool {
        !assignees.isEmpty
    }
    var hasTime: Bool {
        guard let timeComponents = timeComponents else {
            return false
        }
        return (timeComponents.startTime ?? 0) > 0 || (timeComponents.dueTime ?? 0) > 0
    }
    var cellHeight: CGFloat {
        hasTime ? DetailSubTask.withTimeCellHeight : DetailSubTask.withoutTimeCellHeight
    }
}

final class DetailSubTaskContentCell: SwipeTableViewCell, CheckboxDelegate {

    var viewData: DetailSubTaskContentCellData? {
        didSet {
            guard let data = viewData else { return }
            checkbox.viewData = {
                return CheckBoxViewData(checkState: data.checkboxState, isRotated: data.isMilestone)
            }()
            checkbox.isUserInteractionEnabled = !data.isForCreating

            summaryView.inputController?.rxActiveChatters.accept(data.getActiveChatters())
            summaryView.hasStrikethrough = data.hasStrikethrough
            summaryView.isEditMode = data.isForCreating
            summaryView.richContent = data.richSummary

            addTimeBtn.isHidden = data.hasTime || !data.isForCreating
            addOwnerBtn.isHidden = data.hasAssignees || !data.isForCreating
            ownerAvatarView.isHidden = !data.hasAssignees
            // 大于两个头像就只展示一个头像+数据；否则只展示头像
             let maxCount = data.assignees.count > 2 ? 1 : 2
            if data.hasAssignees {
                let avatars = data.assignees
                    .prefix(maxCount)
                    .map { CheckedAvatarViewData(icon: .avatar($0.avatar), isChecked: data.taskMode == .userComplete && $0.completedTime != nil) }
                let viewData = AvatarGroupViewData(avatars: avatars, style: .big, remainCount: data.assignees.count - maxCount)
                ownerAvatarContentView.viewData = viewData
            }

            timeContentView.isHidden = !data.hasTime

            if let components = data.timeComponents {
                let timeContext = TimeContext(
                    currentTime: Int64(Date().timeIntervalSince1970),
                    timeZone: data.timeZone ?? .current,
                    is12HourStyle: data.is12HourStyle
                )
                let timeTodo: Rust.Todo = {
                    var todo = Rust.Todo()
                    todo.startMilliTime = (components.startTime ?? 0) * Utils.TimeFormat.Thousandth
                    todo.dueTime = components.dueTime ?? 0
                    todo.isAllDay = components.isAllDay
                    return todo
                }()
                if let timeText = Utils.TimeFormat.formatTimeStr(by: timeTodo, timeContext: timeContext) {
                    var hasRepeat = false
                    if let rrule = components.rrule {
                        hasRepeat = !rrule.isEmpty
                    }
                    let timeViewData = DetailSubTaskCellTimeContentViewData(
                        timeText: timeText,
                        hasReminder: components.reminder?.hasReminder ?? false,
                        hasRepeat: hasRepeat,
                        hasClearBtn: data.isForCreating
                    )
                    timeContentView.viewData = timeViewData
                }
            }
            detailGestureView.isHidden = data.isForCreating

            layoutSummaryView()
        }
    }

    weak var actionDelegate: DetailSubTaskContentCellDelegate?

    var cellInputController: DetailSubTaskCellInputController? {
        didSet {
            cellInputController?.returnHandler = { [weak self] in
                guard let self = self else { return }
                // 忽略内容为空时的回车回调
                if !self.summaryView.textView.attributedText.string.isEmpty {
                    self.actionDelegate?.onReturnClick(self)
                }
            }
            cellInputController?.emptyBackspaceHandler = { [weak self] in
                guard let self = self else { return }
                if self.summaryView.textView.attributedText.string.isEmpty {
                    self.actionDelegate?.onEmptyBackspaceClick(self)
                }
            }
            cellInputController?.beginEditingHandler = { [weak self] in
                guard let self = self else { return }
                self.actionDelegate?.onBeginEditing(self)
            }
            cellInputController?.endEditingHandler = { [weak self] in
                guard let self = self else { return }
                if self.summaryView.textView.attributedText.string.isEmpty {
                    self.actionDelegate?.onEmptyEndEditing(self)
                }
            }
        }
    }

    private lazy var checkbox = getCheckbox()
    private(set) lazy var summaryView = DetailSubTaskCellSummaryView()

    private lazy var stackView = getStackView()
    private lazy var addTimeBtn = getAddTimeBtn()
    private lazy var addOwnerBtn = getAddOwnerBtn()
    private(set) lazy var ownerAvatarView = getOwnerAvatarView()
    private lazy var ownerAvatarContentView = AvatarGroupView(style: .big)

    private lazy var timeContentView = getTimeContentView()

    private lazy var detailGestureView = getDetailGestureView()

    private let disposeBag = DisposeBag()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        swipeView.backgroundColor = UIColor.ud.bgBody
        contentView.backgroundColor = UIColor.ud.bgBody
        selectionStyle = .none

        swipeView.addSubview(checkbox)
        checkbox.snp.makeConstraints {
            $0.left.equalToSuperview()
            $0.top.equalToSuperview().offset(12)
            $0.width.height.equalTo(16)
        }

        swipeView.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.right.equalToSuperview().offset(-10)
            $0.centerY.equalTo(checkbox)
            $0.width.equalTo(0)
        }

        stackView.addArrangedSubview(addTimeBtn)
        addTimeBtn.snp.makeConstraints { $0.width.height.equalTo(36) }
        addTimeBtn.isHidden = true

        stackView.addArrangedSubview(addOwnerBtn)
        addOwnerBtn.snp.makeConstraints { $0.width.height.equalTo(36) }
        addOwnerBtn.isHidden = true

        stackView.addArrangedSubview(ownerAvatarView)
        ownerAvatarView.snp.makeConstraints { $0.height.equalTo(36) }
        ownerAvatarView.isHidden = true

        swipeView.addSubview(summaryView)
        layoutSummaryView()

        swipeView.addSubview(timeContentView)
        timeContentView.snp.makeConstraints {
            $0.left.equalTo(summaryView).offset(3.5)
            $0.height.equalTo(20)
            $0.top.equalTo(checkbox.snp.bottom).offset(12)
            $0.right.lessThanOrEqualToSuperview().offset(-10)
        }

        swipeView.addSubview(detailGestureView)
        detailGestureView.snp.makeConstraints {
            $0.left.equalTo(summaryView)
            $0.top.bottom.right.equalToSuperview()
        }

        summaryView.textView.rx.attributedText
            .debounce(.milliseconds(100), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] attrText in
                guard let self = self, let attrText = attrText, let input = self.summaryView.inputController else {
                    return
                }
                let content = input.makeRichContent(from: attrText)
                self.actionDelegate?.onSummaryUpdate(content: content, self)
            })
            .disposed(by: disposeBag)
    }

    private func layoutSummaryView() {
        if stackView.arrangedSubviews.contains(where: { !$0.isHidden }) {
            let width = stackView.arrangedSubviews.reduce(0) { partialResult, view in
                guard !view.isHidden else { return partialResult }
                if view.tag == Self.OwnerViewTag {
                    return partialResult + ownerAvatarContentView.intrinsicContentSize.width + 12
                } else {
                    return partialResult + 36
                }
            }
            stackView.snp.updateConstraints {
                $0.width.equalTo(width)
            }
            summaryView.snp.remakeConstraints {
                $0.left.equalTo(checkbox.snp.right).offset(7.5)
                $0.centerY.equalTo(checkbox)
                $0.right.equalTo(stackView.snp.left).offset(-16)
                $0.height.lessThanOrEqualTo(38.5)
            }
        } else {
            summaryView.snp.remakeConstraints {
                $0.left.equalTo(checkbox.snp.right).offset(7.5)
                $0.centerY.equalTo(checkbox)
                $0.right.equalToSuperview().offset(-16)
                $0.height.lessThanOrEqualTo(38.5)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func getCheckbox() -> Todo.Checkbox {
        let checkbox = Todo.Checkbox()
        checkbox.hitTestEdgeInsets = UIEdgeInsets(top: -12, left: -12, bottom: -12, right: -12)
        checkbox.delegate = self
        return checkbox
    }

    private func getStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 0
        return stackView
    }

    private func getAddTimeBtn() -> UIView {
        let containerView = UIView()
        let imageView = UIImageView()
        imageView.image = UDIcon.calendarDateOutlined.ud.withTintColor(UIColor.ud.iconN3)
        containerView.addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(20)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(onAddTimeBtnClick))
        containerView.addGestureRecognizer(tap)
        return containerView
    }

    private func getAddOwnerBtn() -> UIView {
        let containerView = UIView()
        let imageView = UIImageView()
        imageView.image = UDIcon.memberAddOutlined.ud.withTintColor(UIColor.ud.iconN3)
        containerView.addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(20)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(onAddOwnerBtnClick))
        containerView.addGestureRecognizer(tap)
        return containerView
    }

    static let OwnerViewTag = 08_031_942
    private func getOwnerAvatarView() -> UIView {
        let containerView = UIView()
        containerView.addSubview(ownerAvatarContentView)
        ownerAvatarContentView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.height.equalTo(24)
            $0.left.equalToSuperview().offset(6)
            $0.right.equalToSuperview().offset(-6)
        }
        containerView.tag = DetailSubTaskContentCell.OwnerViewTag
        let tap = UITapGestureRecognizer(target: self, action: #selector(onOwnerAvatarClick))
        containerView.addGestureRecognizer(tap)
        return containerView
    }

    private func getTimeContentView() -> DetailSubTaskCellTimeContentView {
        let view = DetailSubTaskCellTimeContentView()
        view.detailClickHandler = { [weak self] in
            guard let self = self else { return }
            self.actionDelegate?.onTimeDetailClick(self)
        }
        view.clearBtnClickHandler = { [weak self] in
            guard let self = self else { return }
            self.actionDelegate?.onTimeClearBtnClick(self)
        }
        return view
    }

    private func getDetailGestureView() -> UIControl {
        let control = UIControl()
        control.addTarget(self, action: #selector(onDetailClick), for: .touchUpInside)
        return control
    }

    @objc
    private func onAddTimeBtnClick() {
        self.actionDelegate?.onAddTimeBtnClick(self)
    }

    @objc
    private func onAddOwnerBtnClick() {
        self.actionDelegate?.onAddOwnerBtnClick(self)
    }

    @objc
    private func onOwnerAvatarClick() {
        self.actionDelegate?.onOwnerAvatarClick(self)
    }

    @objc
    private func onDetailClick() {
        self.actionDelegate?.onDetailClick(self)
    }

    // MARK: - CheckboxDelegate

    func disabledAction(for checkbox: Checkbox) -> CheckboxDisabledAction {
        {  }
    }

    func enabledAction(for checkbox: Checkbox) -> CheckboxEnabledAction {
        let operationViewData = viewData
        return .immediate(completion: { [weak self] in
            guard let self = self else { return }
            self.actionDelegate?.onCheckboxClick(self, operationViewData)
        })
    }
}

extension DetailSubTaskContentCellData {
    func getActiveChatters() -> Set<String> {
        var activeChatters = Set<String>()
        if isForCreating {
            if let currentUserId = currentUserId {
                activeChatters.insert(currentUserId)
            }
            activeChatters.formUnion(assignees.map { $0.identifier }.filter { !$0.isEmpty })
        } else {
            if let todo = todo {
                if todo.hasAssigner, !todo.assigner.userID.isEmpty {
                    activeChatters.insert(todo.assigner.userID)
                }
                if todo.hasCreatorID, !todo.creatorID.isEmpty {
                    activeChatters.insert(todo.creatorID)
                }
                activeChatters.formUnion(todo.assignees.map { $0.assigneeID }.filter { !$0.isEmpty })
                activeChatters.formUnion(todo.followers.map { $0.followerID }.filter { !$0.isEmpty })
            }
        }
        return activeChatters
    }
}
