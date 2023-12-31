//
//  EventAttendeeEditCell.swift
//  Calendar
//
//  Created by 张威 on 2020/4/6.
//

import UniverseDesignIcon
import RxSwift
import RxCocoa
import LarkActivityIndicatorView
import LarkBizAvatar
import UniverseDesignTag
import UniverseDesignColor
import UIKit
import LarkTag
import SnapKit

// MARK: Non Group Cell
private let avatarSize = CGSize(width: 36, height: 36)

protocol EventNonGroupEditCellDataType {
    var avatar: Avatar { get }
    var status: AttendeeStatus { get }
    var name: String { get }
    var subTitle: String? { get }
    var underGroup: Bool { get }        // 是否是群组下的成员（群组下的成员缩进 16 pt)
    var externalTag: String? { get }     // 扩展标签
    var isOptional: Bool { get }        // 是否可选
    var canDelete: Bool { get }         // 是否可删除
    var shouldShowAIStyle: Bool { get } // 是否AI样式
}

/// 参与人列表 - cell for 非「群参与人」
final class EventNonGroupEditCell: UITableViewCell, ViewDataConvertible {

    var viewData: EventNonGroupEditCellDataType? {
        didSet {
            if let avatar = viewData?.avatar {
                avatarView.setAvatar(avatar, with: avatarSize.width)
            }
            statusView.image = statusImage(for: viewData?.status)
            nameLabel.text = viewData?.name
            subTitleLabel.isHidden = viewData?.subTitle == nil
            subTitleLabel.text = viewData?.subTitle ?? ""
            externalTagView.isHidden = viewData?.externalTag == nil
            externalTagView.text = viewData?.externalTag ?? ""
            optionalTagView.isHidden = !(viewData?.isOptional ?? false)
            deleteButton.isHidden = !(viewData?.canDelete ?? false)
            if let underGroup = viewData?.underGroup, underGroup {
                stackView.layoutMargins = UIEdgeInsets(top: 0, left: 32, bottom: 0, right: 16)
            } else {
                stackView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            }
            relayoutTitleStackView()


            if let shouldShowAIStyle = viewData?.shouldShowAIStyle {
                deleteButton.isHidden = shouldShowAIStyle
                aiStyleBgView.isHidden = !shouldShowAIStyle
                updateAIStyleBg()
            }

            if let canShowDelete = canShowDelete {
                deleteButton.isHidden = !canShowDelete
            }
        }
    }

    var showBottomLine: Bool = true {
        didSet { bottomLineView.isHidden = !showBottomLine }
    }

    var canShowDelete: Bool?

    var deleteHandler: (() -> Void)?

    private let avatarView = AvatarView()
    private let statusView = UIImageView()
    private let nameLabel = UILabel.cd.textLabel(fontSize: 16)
    private let subTitleLabel = UILabel.cd.textLabel(fontSize: 14)
    private var externalTagView: UDTag = TagViewProvider.emailTag(with: I18n.Calendar_Detail_External)
    private let optionalTagView = TagViewProvider.optionalAttend
    private let deleteButton = UIButton()
    private var stackView: UIStackView = UIStackView()
    private var bottomLineView: UIView = UIView()

    private lazy var aiStyleBgView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.layer.cornerRadius = 7
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        backgroundColor = UIColor.ud.bgBody
        contentView.backgroundColor = UIColor.ud.bgBody
        subTitleLabel.textColor = UIColor.ud.textPlaceholder

        bottomLineView.backgroundColor = EventEditUIStyle.Color.horizontalSeperator
        contentView.addSubview(bottomLineView)
        bottomLineView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(68)
            $0.right.bottom.equalToSuperview()
            $0.height.equalTo(EventEditUIStyle.Layout.horizontalSeperatorHeight)
        }

        let avatarStatusMixedView = UIView()
        avatarStatusMixedView.clipsToBounds = false
        avatarStatusMixedView.snp.makeConstraints {
            $0.size.equalTo(avatarSize)
        }
        avatarStatusMixedView.addSubview(avatarView)
        avatarView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        avatarStatusMixedView.addSubview(statusView)

        statusView.snp.makeConstraints {
            $0.width.height.equalTo(16)
            $0.bottom.equalTo(avatarView).offset(2)
            $0.right.equalToSuperview().offset(2)
        }

        deleteButton.increaseClickableArea()
        deleteButton.setImage(UDIcon.getIconByKeyNoLimitSize(.closeOutlined).scaleInfoSize().renderColor(with: .n2), for: .normal)
        deleteButton.addTarget(self, action: #selector(didDeleteButtonClick), for: .touchUpInside)

        let titleStackView = UIStackView(arrangedSubviews: [nameLabel, externalTagView, optionalTagView])
        titleStackView.axis = .horizontal
        titleStackView.spacing = 8

        let textStackView = UIStackView(arrangedSubviews: [titleStackView, subTitleLabel])
        textStackView.axis = .vertical
        textStackView.alignment = .leading
        textStackView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(20)
        }
        let arrangedSubviews: [UIView] = [
            avatarStatusMixedView,
            textStackView
        ]
        stackView = UIStackView(arrangedSubviews: arrangedSubviews)
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.spacing = 16
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.left.bottom.top.equalToSuperview()
            $0.right.lessThanOrEqualToSuperview().offset(-32)
        }

        contentView.addSubview(deleteButton)
        deleteButton.snp.makeConstraints {
            $0.centerY.equalTo(stackView)
            $0.right.equalToSuperview().offset(-16)
            $0.width.height.equalTo(16)
        }

        showBottomLine = true

        contentView.addSubview(aiStyleBgView)
        aiStyleBgView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(horizontal: 6, vertical: 4))
        }
    }

    private var externalTagViewConstraint: Constraint?

    func relayoutTitleStackView() {
        self.setNeedsLayout()
        self.layoutIfNeeded()
        let stackViewWidth = stackView.bounds.width
        var stackViewCompleteWidth: CGFloat = 0
        stackView.arrangedSubviews.forEach({ stackViewCompleteWidth += $0.intrinsicContentSize.width })
        if stackViewCompleteWidth > stackViewWidth {
            let nameLabelCompleteWidth = nameLabel.intrinsicContentSize.width
            let externalCompleteWidth = externalTagView.intrinsicContentSize.width
            let stackViewContrast = stackViewCompleteWidth - stackViewWidth
            let externalContrast = externalCompleteWidth - 60
            if externalContrast > stackViewContrast {
                externalTagView.snp.remakeConstraints { make in
                    externalTagViewConstraint = make.width.equalTo(externalCompleteWidth - externalContrast + stackViewContrast).constraint
                }
            } else {
                let tagShouldWidth = externalCompleteWidth > 60 ? 60 : externalCompleteWidth
                externalTagView.snp.remakeConstraints { make in
                    externalTagViewConstraint = make.width.equalTo(tagShouldWidth).constraint
                }
            }
        } else {
            externalTagViewConstraint?.deactivate()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func statusImage(for status: AttendeeStatus?) -> UIImage? {
        guard let status = status else { return nil }
        let image: UIImage
        switch status {
        case .accept: return UIImage.cd.image(named: "yes_filled")
        case .decline: return UIImage.cd.image(named: "decline_filled")
        case .tentative: return UIImage.cd.image(named: "maybe_filled")
        @unknown default: return nil
        }
        return image.withRenderingMode(.alwaysOriginal)
    }

    @objc
    private func didDeleteButtonClick() {
        deleteHandler?()
    }

    private func updateAIStyleBg() {
        aiStyleBgView.backgroundColor = UDColor.AIPrimaryFillTransparent01(ofSize: aiStyleBgView.bounds.size)
    }
}

// MARK: Group Cell

enum EventGroupEditViewStatus {
    case invisible  // 不可见
    case expanded   // 群成员已展开
    case collapsed  // 群成员已收拢
}

protocol EventGroupEditCellDataType {
    var avatar: Avatar { get }
    var title: String { get }
    var subtitle: String? { get }
    var status: EventGroupEditViewStatus { get }
    var canBreakUp: Bool { get }                    // 是否可打散
    var canDelete: Bool { get }                     // 是否可删除
    var isLoading: Bool { get }
    var hasMoreMembers: Bool? { get }
    var relationTagStr: String? { get }             // 关联组织自定义标签
    var shouldShowAIStyle: Bool { get }             // 是否AI样式
}

/// 参与人列表 - cell for 「群参与人」
class EventDetailGroupEditCell: EventGroupEditCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setChatFirstStyle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 参与人列表 - cell for 「群参与人」
class EventEditGroupEditCell: EventGroupEditCell {

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setStatusFirstStyle()
    }
}

/// 参与人列表 - cell for 「群参与人」
class EventGroupEditCell: UITableViewCell, ViewDataConvertible {

    var viewData: EventGroupEditCellDataType? {
        didSet {
            isLoading = viewData?.isLoading ?? false
            if let avatar = viewData?.avatar {
                avatarView.setAvatar(avatar, with: avatarSize.width)
            }
            titleLabel.text = viewData?.title
            subtitleLabel.text = viewData?.subtitle
            var statusImage: UIImage?
            if let status = viewData?.status {
                switch status {
                case .invisible: statusImage = UDIcon.getIconByKeyNoLimitSize(.visibleLockOutlined).renderColor(with: .n2)
                    enterChatButton.isHidden = true
                case .expanded: statusImage = UDIcon.getIconByKeyNoLimitSize(.upOutlined).renderColor(with: .n2)
                    enterChatButton.isHidden = false
                case .collapsed: statusImage = UDIcon.getIconByKeyNoLimitSize(.downOutlined).renderColor(with: .n2)
                    enterChatButton.isHidden = false
                }
            }
            statusButton.setImage(statusImage?.scaleInfoSize(), for: .normal)
            externalTagView.isHidden = viewData?.relationTagStr == nil
            externalTagView.text = viewData?.relationTagStr ?? ""

            if let shouldShowAIStyle = viewData?.shouldShowAIStyle, shouldShowAIStyle {
                breakUpButton.isHidden = true
            } else {
                breakUpButton.isHidden = !(viewData?.canBreakUp ?? false)
            }

            if let shouldShowAIStyle = viewData?.shouldShowAIStyle, shouldShowAIStyle {
                deleteButton.isHidden = true
            } else {
                deleteButton.isHidden = !(viewData?.canDelete ?? false)
            }

            relayoutTitleStackView()


            if let shouldShowAIStyle = viewData?.shouldShowAIStyle, shouldShowAIStyle {
                enterChatButton.isHidden = true
                clickableBackgroundView.isHidden = true
                statusButton.isHidden = true
            }
        }
    }

    var showBottomLine: Bool = true {
        didSet { bottomLineView.isHidden = !showBottomLine }
    }

    var expandHandler: (() -> Void)?        // 展开群成员
    var collapseHandler: (() -> Void)?      // 收拢群成员
    var breakUpHandler: (() -> Void)?       // 打散群成员
    var enterChatHandler: (() -> Void)?     // 进入群聊
    var deleteHandler: (() -> Void)?        // 删除群
    var seeInvisibleHandler: (() -> Void)?  // 查看 invisible 群

    private let avatarView = AvatarView()
    private let titleLabel = UILabel.cd.textLabel(fontSize: 16)
    private let subtitleLabel = UILabel.cd.textLabel(fontSize: 14)
    private let externalTagView = TagWrapperView.titleTagView(for: .external)
    private var activityView = ActivityIndicatorView(color: UIColor.ud.primaryContentDefault)
    private let activityBGView = UIView()
    private let statusButton = UIButton()
    private let enterChatButton = UIButton()
    private let breakUpButton = UIButton()
    private let deleteButton = UIButton()
    private var leftStackView: UIStackView = UIStackView()
    private var titleStackView: UIStackView = UIStackView()
    private var textStackView: UIStackView = UIStackView()
    private var rightStackView: UIStackView = UIStackView()
    private var bottomLineView: UIView = UIView()
    private var clickableBackgroundView: UIButton = UIButton()

    var isLoading: Bool = false {
        didSet {
            if isLoading {
                activityBGView.isHidden = false
                activityView.startAnimating()
                statusButton.isHidden = true
            } else {
                activityBGView.isHidden = true
                activityView.stopAnimating()
                statusButton.isHidden = false
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        backgroundColor = UIColor.ud.bgBody
        contentView.backgroundColor = UIColor.ud.bgBody

        subtitleLabel.textColor = UIColor.ud.textPlaceholder

        contentView.addSubview(clickableBackgroundView)
        clickableBackgroundView.addTarget(self, action: #selector(handleStatusChanged), for: .touchUpInside)
        clickableBackgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        bottomLineView.backgroundColor = EventEditUIStyle.Color.horizontalSeperator
        contentView.addSubview(bottomLineView)
        bottomLineView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(68)
            $0.right.bottom.equalToSuperview()
            $0.height.equalTo(EventEditUIStyle.Layout.horizontalSeperatorHeight)
        }

        statusButton.increaseClickableArea()
        statusButton.addTarget(self, action: #selector(handleStatusChanged), for: .touchUpInside)

        enterChatButton.increaseClickableArea()
        enterChatButton.addTarget(self, action: #selector(handleEnterChat), for: .touchUpInside)
        enterChatButton.setImage(UDIcon.getIconByKeyNoLimitSize(.chatOutlined).scaleInfoSize().renderColor(with: .n2), for: .normal)

        breakUpButton.increaseClickableArea()
        breakUpButton.setImage(UDIcon.getIconByKeyNoLimitSize(.expandOutlined).scaleInfoSize().renderColor(with: .n2), for: .normal)
        breakUpButton.addTarget(self, action: #selector(handleBreakUp), for: .touchUpInside)

        deleteButton.increaseClickableArea()
        deleteButton.setImage(UDIcon.getIconByKeyNoLimitSize(.closeOutlined).scaleInfoSize().renderColor(with: .n2), for: .normal)
        deleteButton.addTarget(self, action: #selector(handleDelete), for: .touchUpInside)

        rightStackView = UIStackView()
        rightStackView.axis = .horizontal
        rightStackView.alignment = .center
        rightStackView.isLayoutMarginsRelativeArrangement = true
        rightStackView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16)
        rightStackView.spacing = 16
        contentView.addSubview(rightStackView)
        rightStackView.snp.makeConstraints {
            $0.right.bottom.top.equalToSuperview()
        }
        avatarView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: avatarSize.width, height: avatarSize.width))
        }

        activityBGView.backgroundColor = .clear
        activityBGView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
        }

        activityBGView.addSubview(activityView)
        activityView.snp.makeConstraints {
            $0.width.height.equalTo(14)
            $0.center.equalToSuperview()
        }

        titleLabel.lineBreakMode = .byTruncatingTail
        titleStackView = UIStackView(arrangedSubviews: [titleLabel, externalTagView])
        titleStackView.isUserInteractionEnabled = false
        titleStackView.axis = .horizontal
        titleStackView.alignment = .center
        titleStackView.spacing = 8

        textStackView = UIStackView(arrangedSubviews: [titleStackView, subtitleLabel])
        textStackView.isUserInteractionEnabled = false
        textStackView.axis = .vertical
        textStackView.alignment = .fill
        textStackView.distribution = .fill

        leftStackView = UIStackView(arrangedSubviews: [avatarView, textStackView])
        leftStackView.isUserInteractionEnabled = false
        leftStackView.axis = .horizontal
        leftStackView.alignment = .center
        leftStackView.isLayoutMarginsRelativeArrangement = true
        leftStackView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        contentView.addSubview(leftStackView)
        leftStackView.snp.makeConstraints {
            $0.left.bottom.top.equalToSuperview()
            $0.right.lessThanOrEqualTo(rightStackView.snp.left)
        }
        leftStackView.spacing = 16

        showBottomLine = true
    }

    func setStatusFirstStyle() {
        rightStackView.addArrangedSubview(statusButton)
        rightStackView.addArrangedSubview(activityBGView)
        rightStackView.addArrangedSubview(enterChatButton)
        rightStackView.addArrangedSubview(breakUpButton)
        rightStackView.addArrangedSubview(deleteButton)
    }

    func setChatFirstStyle() {
        rightStackView.addArrangedSubview(enterChatButton)
        rightStackView.addArrangedSubview(statusButton)
        rightStackView.addArrangedSubview(activityBGView)
        rightStackView.addArrangedSubview(breakUpButton)
        rightStackView.addArrangedSubview(deleteButton)
    }

    private var externalTagViewConstraint: Constraint?

    func relayoutTitleStackView() {
        self.setNeedsLayout()
        self.layoutIfNeeded()
        let stackViewWidth = titleStackView.bounds.width
        var stackViewCompleteWidth: CGFloat = 0
        titleStackView.arrangedSubviews.forEach({ stackViewCompleteWidth += $0.intrinsicContentSize.width })
        if stackViewCompleteWidth > stackViewWidth {
            let nameLabelCompleteWidth = titleLabel.intrinsicContentSize.width
            let externalCompleteWidth = externalTagView.intrinsicContentSize.width
            let stackViewContrast = stackViewCompleteWidth - stackViewWidth
            let externalContrast = externalCompleteWidth - 60
            if externalContrast > stackViewContrast {
                externalTagView.snp.remakeConstraints { make in
                    externalTagViewConstraint = make.width.equalTo(externalCompleteWidth - externalContrast + stackViewContrast).constraint
                }
            } else {
                let tagShouldWidth = externalCompleteWidth > 60 ? 60 : externalCompleteWidth
                externalTagView.snp.remakeConstraints { make in
                    externalTagViewConstraint = make.width.equalTo(tagShouldWidth).constraint
                }
            }
        } else {
            externalTagViewConstraint?.deactivate()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func handleBreakUp() {
        breakUpHandler?()
    }

    @objc
    func handleDelete() {
        deleteHandler?()
    }

    @objc
    private func handleEnterChat() {
        enterChatHandler?()
    }

    @objc
    private func handleStatusChanged() {
        guard let status = self.viewData?.status else { return }
        switch status {
        case .invisible: seeInvisibleHandler?()
        case .expanded: collapseHandler?()
        case .collapsed: expandHandler?()
        }
    }

}

final class GroupAttendeeCellMoreFooterView: UIView {
    private lazy var tipLabel = initTipLabel()
    private let section: Int

    var tapedHandler: ((_ section: Int) -> Void)?

    var tipText: String = BundleI18n.Calendar.Calendar_Edit_SeeMoreGuest {
        didSet {
            tipLabel.text = tipText
        }
    }

    init(frame: CGRect, section: Int) {
        self.section = section
        super.init(frame: frame)

        addSubview(tipLabel)
        tipLabel.snp.makeConstraints {
            $0.right.bottom.top.equalToSuperview()
            $0.left.equalToSuperview().offset(84)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(moreFooterViewTaped))
        tapGesture.numberOfTapsRequired = 1
        addGestureRecognizer(tapGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func moreFooterViewTaped() {
        tapedHandler?(section)
    }

    private func initTipLabel() -> UILabel {
        let tipLabel = UILabel.cd.subTitleLabel(fontSize: 14)
        tipLabel.textColor = UIColor.ud.primaryContentPressed
        tipLabel.textAlignment = .left
        tipLabel.text = BundleI18n.Calendar.Calendar_Edit_SeeMoreGuest
        return tipLabel
    }
}
