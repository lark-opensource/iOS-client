//
//  MemberPanelDisplayHeader.swift
//  Calendar
//
//  Created by Hongbin Liang on 4/10/23.
//

import Foundation
import LarkTag
import UniverseDesignIcon

class MemberPanelDisplayHeader: UIView {

    var closeBtnOnClicked: (() -> Void)?

    func setUp(with data: CalendarMemberCellDataType) {
        avatar.setAvatar(data.avatar, with: 44)
        titleLabel.text = data.title
        relationTag.text = data.relationTagStr

        relationTag.isHidden = data.relationTagStr.isEmpty
    }

    private let avatar = AvatarView()
    private let titleLabel = UILabel.cd.textLabel(fontSize: 17)
    private let relationTag = TagWrapperView.titleTagView(for: .external)

    private(set) var closeBtn = UIButton()

    override init(frame: CGRect) {
        super.init(frame: frame)

        let nameStack = UIStackView(arrangedSubviews: [titleLabel, relationTag])
        nameStack.spacing = 4
        nameStack.alignment = .center

        let wrapper = UIView()
        wrapper.addSubview(nameStack)
        nameStack.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview()
        }

        closeBtn.setImage(UIImage.cd.image(named: "close_circle_colorful"), for: .normal)
        closeBtn.increaseClickableArea()
        closeBtn.addTarget(self, action: #selector(closeBtnClicked), for: .touchUpInside)
        closeBtn.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 24, height: 24))
        }

        let horizontalContainer = UIStackView(arrangedSubviews: [avatar, wrapper, closeBtn])
        horizontalContainer.spacing = 8
        horizontalContainer.alignment = .center

        addSubview(horizontalContainer)
        horizontalContainer.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.bottom.equalToSuperview().inset(12)
            $0.height.equalTo(44)
        }

        avatar.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 44, height: 44))
        }
    }

    @objc
    private func closeBtnClicked() {
        closeBtnOnClicked?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
