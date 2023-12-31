//
//  RecentForwardViewCell.swift
//  LarkSearchCore
//
//  Created by bytedance on 2022/6/22.
//

import Foundation
import UIKit
import LarkUIKit
import SnapKit
import LarkMessengerInterface
import LarkBizAvatar
import UniverseDesignColor

final class RecentForwardCellData {
    var item: ForwardItem
    var isMutiple: Bool
    var isSelected: Bool
    var tapEvent: (() -> Void)?
    init(item: ForwardItem, isMutiple: Bool = false, isSelected: Bool = false, tapEvent: (() -> Void)? = nil) {
        self.item = item
        self.isMutiple = isMutiple
        self.isSelected = isSelected
        self.tapEvent = tapEvent
    }
}

final class RecentForwardViewCell: UIView, LKCheckboxDelegate {

    lazy var iconImageView: BizAvatar = BizAvatar()

    lazy var nameLabel: UILabel = {
        let label = UILabel()
        let font = UIFont.systemFont(ofSize: 11, weight: .regular)
        label.font = font
        label.textColor = UIColor.ud.textCaption
        label.numberOfLines = 2
        label.textAlignment = .center
        label.backgroundColor = .clear
        return label
    }()

    lazy var checkBox: LKCheckbox = LKCheckbox(boxType: .multiple)
    lazy var checkBoxContainer: UIView = UIView()
    var tapEvent: (() -> Void)?
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(iconImageView)
        self.addSubview(checkBoxContainer)
        checkBoxContainer.addSubview(checkBox)
        self.addSubview(nameLabel)
        checkBoxContainer.backgroundColor = UIColor.ud.bgBody
        checkBoxContainer.layer.cornerRadius = 8
        checkBox.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        self.addGestureRecognizer(tap)
        iconImageView.snp.makeConstraints { make in
            make.top.equalTo(10)
            make.width.height.equalTo(48)
            make.centerX.equalToSuperview()
        }
        checkBoxContainer.snp.makeConstraints { make in
            make.width.height.equalTo(16)
            make.top.right.equalTo(iconImageView)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(8)
            make.left.right.equalToSuperview()
        }
        checkBox.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func didTapView() {
        if let block = self.tapEvent {
            block()
        }
    }

    func didTapLKCheckbox(_ checkbox: LKCheckbox) {
        didTapView()
    }

    func updateCellContent(model: ForwardItem, hideCheckBox: Bool, isSelected: Bool, tapEvent: (() -> Void)? = nil) {
        self.iconImageView.setAvatarByIdentifier(model.id, avatarKey: model.avatarKey,
                                                        avatarViewParams: .init(sizeType: .size(48)))
        if model.isPrivate {
            var miniIcon = MiniIconProps(.dynamicIcon(Resources.private_chat))
            iconImageView.setMiniIcon(miniIcon)
        } else {
            iconImageView.setMiniIcon(nil)
        }
        var para = NSMutableParagraphStyle()
        para.lineSpacing = 0
        para.alignment = .center
        let attrStr = NSMutableAttributedString(string: model.name, attributes: [
            .paragraphStyle: para
        ])
        self.nameLabel.btd_SetText(model.name, lineHeight: 12)
        self.checkBoxContainer.isHidden = hideCheckBox
        self.checkBox.isSelected = isSelected
        self.tapEvent = tapEvent
    }
}
