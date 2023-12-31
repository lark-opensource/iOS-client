//
//  EventDetailTableOrganizerEmailView.swift
//  Calendar
//
//  Created by Rico on 2021/4/22.
//

import UIKit
import CalendarFoundation
import UniverseDesignIcon

final class EventDetailTableOrganizerEmailView: UIView, ViewDataConvertible {
    private let avatarView = EventDetailAvatarView()
    private let tagStackView = UIStackView()
    private let icon = UIImageView()
    private let nameLabel = DetailCell.normalTextLabel()

    var viewData: EventDetailTableOrganizerViewDataType? {
        didSet {
            guard let viewData = viewData else { return }
            let avatarTuple = viewData.avatar
            self.nameLabel.text = avatarTuple.avatar.userName
            self.avatarView.setAvatar(avatarTuple.avatar, with: 32)
            tagStackView.clearSubviews()
            for tagTuple in viewData.tagStrings {
                let label = TagViewProvider.label(text: tagTuple.tag, color: tagTuple.textColor)
                tagStackView.addArrangedSubview(label)
            }
        }
    }

    init() {
        // 外部包装在 stackview 中 此处无需指定宽度
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 52))
        self.snp.makeConstraints { (make) in
            make.height.greaterThanOrEqualTo(52)
        }
        layoutIcon(icon: icon, image: UDIcon.getIconByKeyNoLimitSize(.memberOutlined).renderColor(with: .n3))
        layoutAvartView(avatarView)
        layoutLabel(stackView: UIStackView(),
                    namelLabel: nameLabel,
                    tagStackView: tagStackView,
                    leftView: avatarView)
        layoutActionButton(UIButton(type: .custom))
    }

    private func layoutIcon(icon: UIImageView, image: UIImage) {
        self.addSubview(icon)
        icon.image = image
        icon.contentMode = .scaleAspectFit
        icon.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.height.width.equalTo(16)
        }
    }

    private func layoutActionButton(_ btn: UIButton) {
        self.insertSubview(btn, at: 0)
        btn.setHighlitedImageWithColor()
        btn.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func layoutAvartView(_ avatar: UIView) {
        avatarView.isUserInteractionEnabled = false
        self.addSubview(avatar)
        avatar.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.height.width.equalTo(32)
            make.left.equalToSuperview().offset(48)
        }
    }

    private func layoutLabel(stackView: UIStackView,
                             namelLabel: UILabel,
                             tagStackView: UIStackView,
                             leftView: UIView) {
        self.addSubview(stackView)
        stackView.isUserInteractionEnabled = false
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.alignment = .leading
        stackView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(12)
            make.left.equalTo(leftView.snp.right).offset(12)
            make.right.equalToSuperview().offset(-16)
        }
        tagStackView.axis = .horizontal
        tagStackView.spacing = 6.0
        stackView.addArrangedSubview(namelLabel)
        stackView.addArrangedSubview(tagStackView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
