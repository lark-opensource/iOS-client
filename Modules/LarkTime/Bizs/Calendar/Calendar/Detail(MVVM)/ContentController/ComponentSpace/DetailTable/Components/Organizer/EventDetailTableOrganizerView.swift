//
//  EventDetailTableOrganizerView.swift
//  Calendar
//
//  Created by Rico on 2021/3/30.
//

import UIKit
import SnapKit
import CalendarFoundation
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignFont

protocol EventDetailTableOrganizerViewDataType {
    var avatar: (avatar: Avatar, statusImage: UIImage?) { get }
    var tagStrings: [(tag: String, textColor: UIColor)] { get }
    var subTitle: String? { get }
}

final class EventDetailTableOrganizerView: UIView, ViewDataConvertible {
    var viewData: EventDetailTableOrganizerViewDataType? {
        didSet {
            guard let viewData = viewData else { return }
            let avatarTuple = viewData.avatar
            self.titleLabel.text = avatarTuple.avatar.userName
            self.avatarView.setAvatar(avatarTuple.avatar, with: 32)
            self.avatarView.setStatusImage(avatarTuple.statusImage)
            self.subTitleLable.isHidden = viewData.subTitle.isEmpty
            self.subTitleLable.text = viewData.subTitle ?? ""
            relayoutTitleAndStackView(viewData: viewData)
        }
    }

    var tapAction: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        layoutUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutUI() {
        let titleIconContainerView = UIView()
        titleIconContainerView.addSubview(titleLabel)
        titleIconContainerView.addSubview(stackView)

        let leftStackView = UIStackView(arrangedSubviews: [titleIconContainerView, subTitleLable])
        leftStackView.axis = .vertical
        leftStackView.spacing = 2

        addSubview(icon)
        addSubview(avatarView)
        insertSubview(actionButton, at: 0)
        addSubview(leftStackView)

        icon.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalTo(16)
            make.size.equalTo(CGSize(width: 16, height: 16))
        }

        avatarView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.height.width.equalTo(32)
            make.left.equalToSuperview().offset(48)
        }

//        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        stackView.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.right).offset(4)
            make.right.lessThanOrEqualToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(0)
        }

        leftStackView.snp.makeConstraints { make in
            make.left.equalTo(avatarView.snp.right).offset(8)
            make.right.lessThanOrEqualToSuperview().offset(-36)
            make.top.bottom.equalTo(avatarView)
        }

        actionButton.snp.edgesEqualToSuperView()
    }

    private func relayoutTitleAndStackView(viewData: EventDetailTableOrganizerViewDataType) {
        stackView.clearSubviews()
        let tagCount = viewData.tagStrings.count
        var stackViewWidth: CGFloat = CGFloat((tagCount - 1) * 4)
        for tagTuple in viewData.tagStrings {
            let label = TagViewProvider.label(text: tagTuple.tag, color: tagTuple.textColor)
            stackViewWidth += ceil(label.intrinsicContentSize.width)
            stackView.addArrangedSubview(label)
        }
        self.setNeedsLayout()
        self.layoutIfNeeded()
//        let stackViewWidth = stackView.intrinsicContentSize.width
        // title 的完全展示宽度
        let labelWidth = titleLabel.intrinsicContentSize.width
        let baseWidth = self.bounds.width - titleLabel.frame.left - 36
        let stackViewMinWidth: CGFloat = CGFloat(tagCount * 60 + (tagCount - 1) * 4)
        let stackViewShouldWidth: CGFloat
        if stackViewWidth + labelWidth > baseWidth, stackViewWidth > stackViewMinWidth {
            stackViewShouldWidth = stackViewMinWidth
            for arrangedView in stackView.arrangedSubviews {
                let shouldWidth = arrangedView.intrinsicContentSize.width < 60 ? ceil(arrangedView.intrinsicContentSize.width) : 60
                arrangedView.snp.remakeConstraints { make in
                    make.width.equalTo(shouldWidth)
                }
            }
        } else {
            stackViewShouldWidth = stackViewWidth
            for arrangedView in stackView.arrangedSubviews {
                arrangedView.snp.remakeConstraints { make in
                    make.width.equalTo(ceil(arrangedView.intrinsicContentSize.width))
                }
            }
        }
        stackView.snp.updateConstraints { make in
            make.width.equalTo(stackViewShouldWidth)
        }
    }

    @objc
    private func cellTaped(sender: UIButton) {
        self.tapAction?()
    }

    private lazy var icon: UIImageView = {
        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        icon.image = UDIcon.getIconByKeyNoLimitSize(.memberOutlined).renderColor(with: .n3)
        return icon
    }()

    private lazy var avatarView: EventDetailAvatarView = {
        let avatarView = EventDetailAvatarView()
        avatarView.isUserInteractionEnabled = false
        return avatarView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = UDColor.textTitle

        label.font = UDFont.body0(.fixed)
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 4.0
        stackView.isUserInteractionEnabled = false
        stackView.distribution = .fillProportionally
        return stackView
    }()

    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setHighlitedImageWithColor()
        button.addTarget(self, action: #selector(cellTaped(sender:)), for: .touchUpInside)
        return button
    }()

    private lazy var subTitleLable: UILabel = {
        let label = UILabel.cd.textLabel(fontSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()
}
