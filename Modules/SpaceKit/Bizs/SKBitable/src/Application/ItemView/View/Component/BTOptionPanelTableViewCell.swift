//
//  BTOptionPanelTableViewCell.swift
//  SKBitable
//
//  Created by zoujie on 2021/10/28.
//  


import Foundation
import SnapKit
import SKUIKit
import LarkTag
import SKBrowser
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignCheckBox

public protocol BTOptionPanelTableViewCellDelegate: AnyObject {
    func didClickMoreButton(model: BTCapsuleModel)
}

public final class BTOptionPanelTableViewCell: UITableViewCell {
    private lazy var checkmark: UDCheckBox = {
        let checkBox = UDCheckBox(boxType: .multiple, config: .init(style: .circle)) { (_) in }
        checkBox.isUserInteractionEnabled = false
        return checkBox
    }()

    private lazy var pLabel: PaddingUILabel = PaddingUILabel().construct { it in
        it.paddingLeft = 10
        it.paddingRight = 10
        it.paddingTop = 6
        it.paddingBottom = 6
        it.layer.masksToBounds = true
        it.text = "option"
        it.textAlignment = .center
        it.textColor = UDColor.textTitle
        it.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        it.lineBreakMode = .byTruncatingTail
        it.numberOfLines = 1
        it.layer.cornerRadius = 12
        it.clipsToBounds = true
    }

    public var model: BTCapsuleModel?
    public weak var delegate: BTOptionPanelTableViewCellDelegate?
    private lazy var moreButton: UIButton = UIButton().construct { it in
        it.setImage(UDIcon.getIconByKey(.moreVerticalOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UDColor.iconN3), for: .normal)
        it.addTarget(self, action: #selector(didClickMoreButton), for: .touchUpInside)
    }

    private lazy var selectedCellBackgroundView = UIView().construct { it in
        it.backgroundColor = UDColor.fillPressed
    }

    private lazy var separator = UIView().construct { it in
        it.backgroundColor = UDColor.lineDividerDefault
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UDColor.bgFloat
        contentView.addSubview(pLabel)
        contentView.addSubview(moreButton)
        contentView.addSubview(separator)
        contentView.addSubview(checkmark)

        pLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(12)
            make.width.greaterThanOrEqualTo(32)
            make.left.equalTo(self.safeAreaLayoutGuide.snp.left).offset(56)
            make.right.lessThanOrEqualTo(moreButton.snp.left).offset(12)
        }

        checkmark.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
            make.left.equalTo(self.safeAreaLayoutGuide.snp.left).offset(18)
        }

        separator.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(56)
            make.right.equalToSuperview()
            make.height.equalTo(1 / SKDisplay.scale)
            make.bottom.equalToSuperview()
        }
        selectedBackgroundView = selectedCellBackgroundView

        moreButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-4)
            make.width.height.equalTo(44)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(text: String,
                colors: BTColorModel,
                isSingle: Bool,
                isSelected: Bool,
                canEdit: Bool) {
        moreButton.isHidden = !canEdit
        moreButton.snp.updateConstraints { make in
            make.width.equalTo(canEdit ? 44 : 0)
        }

        pLabel.snp.updateConstraints { make in
            make.right.lessThanOrEqualTo(moreButton.snp.left).offset(canEdit ? 12 : -12)
        }

        pLabel.text = text
        pLabel.color = UIColor.docs.rgb(colors.color)
        pLabel.textColor = UIColor.docs.rgb(colors.textColor)
        checkmark.isSelected = isSelected
        checkmark.updateUIConfig(boxType: isSingle ? .single : .multiple, config: .init(style: .circle))
    }

    func updateSeparatorStatus(isLast: Bool) {
        separator.snp.updateConstraints { make in
            make.left.equalToSuperview().offset(isLast ? 0 : 56)
        }
        layoutIfNeeded()
    }

    @objc
    func didClickMoreButton() {
        guard let model = model else { return }
        delegate?.didClickMoreButton(model: model)
    }
}
