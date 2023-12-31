//
//  EventEditMeetingRoomView.swift
//  Calendar
//
//  Created by 张威 on 2020/3/9.
//

import UniverseDesignIcon
import UniverseDesignColor
import UIKit
import SnapKit
import RxCocoa
import RxSwift
import LarkButton

protocol EventEditMeetingRoomItemDataType {
    var name: String { get }
    // 是否可删除
    var canDelete: Bool { get }
    // 是否禁用
    var isDisabled: Bool { get }
    // 是否需要审批
    var needsApproval: Bool { get }
    // 是否是条件审批
    var conditionalApproval: Bool { get }
    // 会议室名字不置灰色
    var nameNotGray: Bool { get }
    // 会议室是否有效 无效的会议室在展示时会被删除线划掉
    var isValid: Bool { get }
    // 是否有关联表单
    var hasForm: Bool { get }
    // 表单是否有内容
    var formIsEmpty: Bool { get }
    // 表单是否完成
    var formCompleted: Bool { get }
    // 预订失败原因
    var invalidReasons: [String] { get }
    // 是否需要展示AI样式
    var shouldShowAIStyle: Bool { get }
    // 是否需要展示蓝牙Icon
    var shouldShowBluetooth: Bool { get }
}

protocol EventEditMeetingRoomViewDataType {
    var items: [EventEditMeetingRoomItemDataType] { get }
    var isVisible: Bool { get }
    // 控制显示 add 入口和是否可点击
    var isEditable: Bool { get }
    // 添加会议室标题的颜色
    var addRoomTitleColor: UIColor { get set }
}

final class EventEditMeetingRoomView: UIView, ViewDataConvertible {

    var viewData: EventEditMeetingRoomViewDataType? {
        didSet {
            resetViews()
            isHidden = !(viewData?.isVisible ?? false)
            isUserInteractionEnabled = viewData?.isEditable ?? false
        }
    }

    var addRoomClickHandler: (() -> Void)?
    var itemClickHandler: ((_ index: Int) -> Void)?
    var itemDeleteHandler: ((_ index: Int) -> Void)?
    var itemFormClickHandler: ((Int) -> Void)?
    var showAllRoomsClickHandler: (() -> Void)?

    private func makeAddView() -> EventEditCellLikeView {
        let itemView = EventEditCellLikeView()
        itemView.icon = .empty
        itemView.backgroundColors = EventEditUIStyle.Color.cellBackgrounds
        let titleContent = EventBasicCellLikeView.ContentTitle(
            text: BundleI18n.Calendar.Calendar_Edit_AddRoom,
            color: viewData?.addRoomTitleColor ?? UIColor.ud.functionDangerContentDefault,
            font: UIFont.cd.regularFont(ofSize: 16)
        )
        itemView.content = .title(titleContent)
        itemView.contentInset = EventEditUIStyle.Layout.contentLeftPadding
        itemView.snp.makeConstraints {
            $0.height.equalTo(23)
        }
        itemView.onClick = { [weak self] in
            self?.addRoomClickHandler?()
        }
        return itemView
    }

    private func makeShowAllView() -> EventEditCellLikeView {
        let itemView = EventEditCellLikeView()
        itemView.icon = .empty
        itemView.backgroundColors = EventEditUIStyle.Color.cellBackgrounds
        let titleContent = EventBasicCellLikeView.ContentTitle(
            text: BundleI18n.Calendar.Calendar_Edit_ViewAll,
            color: UIColor.ud.textLinkNormal,
            font: UIFont.cd.regularFont(ofSize: 16)
        )
        itemView.content = .title(titleContent)
        itemView.contentInset = EventEditUIStyle.Layout.contentLeftPadding
        itemView.snp.makeConstraints {
            $0.height.equalTo(23)
        }
        itemView.onClick = { [weak self] in
            guard let self = self else { return }
            self.showAllRoomsClickHandler?()
        }
        return itemView
    }

    private func makePlaceHolderView() -> EventEditCellLikeView {
        let itemView = EventEditCellLikeView()
        let icon = UDIcon.getIconByKeyNoLimitSize(.roomOutlined).renderColor(with: .n3)
        itemView.icon = .customImage(icon)
        itemView.iconSize = EventEditUIStyle.Layout.cellLeftIconSize
        itemView.backgroundColors = EventEditUIStyle.Color.cellBackgrounds
        let titleContent = EventBasicCellLikeView.ContentTitle(
            text: BundleI18n.Calendar.Calendar_Edit_AddRoom,
            color: viewData?.addRoomTitleColor ?? UIColor.ud.functionDangerContentDefault
        )
        itemView.content = .title(titleContent)

        itemView.snp.makeConstraints { make in
            make.height.equalTo(24)
        }
        itemView.accessory = .none

        itemView.onClick = { [weak self] in
            self?.addRoomClickHandler?()
        }
        return itemView
    }

    private func makeRemindCompleteInfoView() -> EventEditCellLikeView {
        let itemView = EventEditCellLikeView()
        itemView.icon = .empty
        itemView.iconSize = EventEditUIStyle.Layout.cellLeftIconSize
        itemView.backgroundColors = EventEditUIStyle.Color.cellBackgrounds
        let titleContent = EventBasicCellLikeView.ContentTitle(
            text: BundleI18n.Calendar.Calendar_MeetingRoom_CustomizedSeriveDescription,
            color: UIColor.ud.functionDangerContentDefault,
            font: UIFont.cd.regularFont(ofSize: 12)
        )
        itemView.content = .title(titleContent)
        itemView.contentInset = EventEditUIStyle.Layout.contentLeftPadding
        itemView.snp.makeConstraints {
            $0.height.equalTo(23)
        }
        return itemView
    }

    private func resetViews() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        guard let viewData = viewData else { return }

        let shownItems: [EventEditMeetingRoomItemDataType]
        let showAll: Bool
        let showCompleteInfo: Bool

        if viewData.items.count > FoldingLimitCount {
            // 支持会议室多选，大于10个要折叠
            shownItems = Array(viewData.items[0..<FoldingLimitCount])
            showAll = true
            showCompleteInfo = viewData.items[FoldingLimitCount...viewData.items.count - 1]
                .contains { !$0.formCompleted }
        } else {
            shownItems = viewData.items
            showAll = false
            showCompleteInfo = false
        }
        shownItems.enumerated().forEach { (index, item) in
            let leadingIcon: EventBasicCellLikeView.Icon
            if index == 0 {
                let icon = UDIcon.getIconByKeyNoLimitSize(.roomOutlined).renderColor(with: viewData.isEditable == true ? .n3 : .n4)
                if viewData.isEditable {
                    leadingIcon = .customImage(icon)
                } else {
                    leadingIcon = .customImageWithoutN3(icon)
                }
            } else {
                leadingIcon = .empty
            }
            let itemView = Self.makeItemView(index: index,
                                             leadingIcon: leadingIcon,
                                             item: item,
                                             itemDeleteHandler: { [weak self] (index) in
                                                self?.itemDeleteHandler?(index)
                                             },
                                             itemFormClickHandler: { [weak self] (index) in
                                                self?.itemFormClickHandler?(index)
                                             },
                                             itemClickHandler: { [weak self] (index) in
                                                self?.itemClickHandler?(index)
                                             },
                                             formIsEmpty: item.formIsEmpty,
                                             viewBounds: self.bounds.size,
                                             disposeBag: disposeBag
            )
            stackView.addArrangedSubview(itemView)
        }
        if showAll {
            let showAll = makeShowAllView()
            stackView.addArrangedSubview(showAll)

            if showCompleteInfo {
                stackView.setCustomSpacing(0, after: showAll)
                let view = makeRemindCompleteInfoView()
                stackView.addArrangedSubview(view)
            }
        }
        // 「添加会议室」
        if viewData.isEditable && !viewData.items.isEmpty {
            let itemView = makeAddView()
            stackView.addArrangedSubview(itemView)
        }
        if viewData.items.isEmpty {
            let itemView = makePlaceHolderView()
            stackView.addArrangedSubview(itemView)
        }
    }

    private let disposeBag = DisposeBag()
    private let stackView = UIStackView()
    private let FoldingLimitCount = 10

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgFloat
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 12
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EventEditMeetingRoomView {
    /// 与已选二级会议室公用UI
    static func makeItemView(index: Int,
                             leadingIcon: EventBasicCellLikeView.Icon,
                             item: EventEditMeetingRoomItemDataType,
                             itemDeleteHandler: ((_ index: Int) -> Void)? = nil,
                             itemFormClickHandler: ((Int) -> Void)? = nil,
                             itemClickHandler: ((_ index: Int) -> Void)? = nil,
                             formIsEmpty: Bool = true,
                             viewBounds: CGSize = CGSize(width: 0, height: 0),
                             disposeBag: DisposeBag) -> EventEditCellLikeView {
        let itemView = EventEditCellLikeView()
        itemView.backgroundColors = EventEditUIStyle.Color.cellBackgrounds
        itemView.icon = leadingIcon
        itemView.iconSize = EventEditUIStyle.Layout.cellLeftIconSize
        if item.canDelete {
            itemView.accessory = .type(.close)
            itemView.onAccessoryClick = {
                itemDeleteHandler?(index)
            }
        } else {
            itemView.accessory = .none
        }

        let titleLabel = UILabel()
        let attributes: [NSAttributedString.Key: NSObject]
        if item.canDelete && !item.isValid {
            // 能删除但无效
            attributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.textPlaceholder,
                          NSAttributedString.Key.strikethroughStyle: NSNumber(value: 1),
                          NSAttributedString.Key.strikethroughColor: UIColor.ud.textPlaceholder,
                          NSAttributedString.Key.font: UIFont.cd.regularFont(ofSize: 16)]
        } else if item.canDelete || item.nameNotGray {
            // 能删除且有效 || 不能删除但是名字不置灰
            attributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle,
                          NSAttributedString.Key.font: UIFont.cd.regularFont(ofSize: 16)]
        } else {
            // 不能删除
            attributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.textPlaceholder,
                          NSAttributedString.Key.font: UIFont.cd.regularFont(ofSize: 16)]
        }
        titleLabel.attributedText = NSAttributedString(string: item.name, attributes: attributes)

        if item.needsApproval || item.isDisabled {
            // 添加「需审批」或者「禁用」标签，只展示一个标签，优先展示「禁用」
            let contentView = UIView()

            contentView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints {
                $0.left.top.bottom.equalToSuperview()
            }

            let tagView: UIView
            if item.isDisabled {
                tagView = TagViewProvider.inactivate()
            } else {
                tagView = TagViewProvider.needApproval
            }
            contentView.addSubview(tagView)
            tagView.snp.makeConstraints {
                $0.centerY.equalToSuperview()
                $0.right.lessThanOrEqualToSuperview()
                $0.left.equalTo(titleLabel.snp.right).offset(4)
            }
            titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            tagView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            itemView.content = .customView(contentView)
        } else {

            let contentView: UIView = UIView()
            let containerView = UIView()
            let bgView: UIView = UIView()
            let bluetoothMark: UIImageView = UIImageView(image: UDIcon.getIconByKey(.bluetoothFilled,
                                                                                    iconColor: UDColor.primaryPri500,
                                                                                    size: CGSize(width: 14, height: 14)))
            let roomContentLeftMargin: CGFloat = 42
            let roomContentRightMargin: CGFloat = 40
            let roomContentAIVerticalPadding: CGFloat = 4
            let roomContentAIHorizonPadding: CGFloat = 6
            contentView.addSubview(containerView)
            contentView.addSubview(bgView)
            contentView.addSubview(titleLabel)
            contentView.addSubview(bluetoothMark)

            containerView.snp.makeConstraints { make in
                make.left.centerY.equalToSuperview()
                if viewBounds.width > 0 {
                    make.width.equalTo(viewBounds.width - roomContentRightMargin - roomContentLeftMargin)
                    make.height.equalTo(20)
                }
            }

            bgView.snp.makeConstraints { make in
                make.left.equalTo(containerView).offset(-roomContentAIHorizonPadding)
                make.right.equalTo(containerView)
                make.top.equalTo(containerView).offset(-roomContentAIVerticalPadding)
                make.bottom.equalTo(containerView).inset(-roomContentAIVerticalPadding)
            }

            titleLabel.snp.makeConstraints { make in
                make.left.top.bottom.equalToSuperview()
                if !item.shouldShowAIStyle || !item.shouldShowBluetooth {
                    make.right.equalToSuperview()
                }
            }

            bluetoothMark.snp.makeConstraints { make in
                make.left.equalTo(titleLabel.snp.right).offset(4)
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().inset(12)

                if !item.shouldShowAIStyle || !item.shouldShowBluetooth {
                    make.size.equalTo(0)
                } else {
                    make.size.equalTo(14)
                }
            }

            titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            bluetoothMark.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            bgView.layer.cornerRadius = 7
            bluetoothMark.isHidden = !item.shouldShowAIStyle || !item.shouldShowBluetooth

            itemView.content = .customView(contentView)
            bgView.backgroundColor = item.shouldShowAIStyle ? UDColor.AIPrimaryFillTransparent01(ofSize: CGSize(width: viewBounds.width - roomContentRightMargin - roomContentLeftMargin + roomContentAIHorizonPadding, height: 20 + 2 * roomContentAIVerticalPadding)) : .clear
            if item.canDelete {
                itemView.accessoryView.isHidden  = item.shouldShowAIStyle
            }
        }
        if case let .customView(contentView) = itemView.content {
            // 对于有表单的会议室 需要在下方添加表单编辑按钮
            let button = UIButton()
            let canClick = item.canDelete
            button.titleLabel?.font = UIFont.cd.regularFont(ofSize: 16)
            button.setTitleColor(canClick ? UIColor.ud.textLinkNormal : UIColor.ud.textDisabled, for: .normal)
            button.setTitle(formIsEmpty ? BundleI18n.Calendar.Calendar_MeetingRoom_FillInReservationForm : BundleI18n.Calendar.Calendar_MeetingRoom_EditReservationForm, for: .normal)
            button.snp.makeConstraints { $0.height.equalTo(22) }
            button.isHidden = !item.hasForm
            button.rx.tap
                .filter { canClick }
                .bind {
                    itemFormClickHandler?(index)
                }
                .disposed(by: disposeBag)

            // 有未完成表单的或会议室预订失败告警的会议室 需要添加告警
            let alerts = UIStackView()
            alerts.axis = .vertical
            alerts.spacing = 2
            alerts.distribution = .equalSpacing
            alerts.alignment = .leading
            let formIncompleteTipsLabel = UILabel()
            formIncompleteTipsLabel.text = BundleI18n.Calendar.Calendar_MeetingRoom_RequiredFieldEmpaty
            formIncompleteTipsLabel.textColor = UIColor.ud.functionDangerContentDefault
            formIncompleteTipsLabel.font = UIFont.cd.regularFont(ofSize: 12)
            formIncompleteTipsLabel.isHidden = item.formCompleted
            alerts.addArrangedSubview(formIncompleteTipsLabel)

            item.invalidReasons.forEach { invalidReason in
                let label = UILabel()
                label.text = invalidReason
                label.textColor = UIColor.ud.functionDangerContentDefault
                label.font = UIFont.cd.regularFont(ofSize: 12)
                label.numberOfLines = 0
                alerts.addArrangedSubview(label)
            }
            alerts.isHidden = alerts.arrangedSubviews.allSatisfy { $0.isHidden }
            let stackView = UIStackView(arrangedSubviews: [contentView, button, alerts])
            if !button.isHidden { stackView.setCustomSpacing(8, after: contentView) }
            if !alerts.isHidden { stackView.setCustomSpacing(4, after: contentView)}
            stackView.axis = .vertical
            stackView.spacing = 2
            stackView.alignment = .leading
            itemView.content = .customView(stackView)
            itemView.iconAlignment = .centerYEqualTo(refView: contentView)
            itemView.accessoryAlignment = .centerYEqualTo(refView: contentView)
        }

        itemView.onClick = {
            itemClickHandler?(index)
        }
        return itemView
    }

}
