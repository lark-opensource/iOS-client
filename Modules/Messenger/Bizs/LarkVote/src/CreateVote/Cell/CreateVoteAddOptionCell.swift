//
//  CreateVoteAddOptionCell.swift
//  LarkVote
//
//  Created by Fan Hui on 2022/4/6.
//

import Foundation
import RxSwift
import UIKit
import UniverseDesignIcon
import UniverseDesignColor

final class CreateVoteAddOptionCell: CreateVoteBaseCell {

    let label: UILabel = UILabel()
    let optionBtn: UIButton = UIButton()
    var clickBlock: (() -> Void)?
    var isEnabled: Bool = false {
        didSet {
            optionBtn.isEnabled = isEnabled
            contentView.isUserInteractionEnabled = isEnabled
            label.textColor = isEnabled ? UIColor.ud.textTitle : UIColor.ud.textDisabled
        }
    }

    func setupCellContent() {
        self.contentView.addSubview(label)
        self.label.snp.makeConstraints {
            $0.left.equalTo(50)
            $0.right.equalToSuperview().inset(16)
            $0.top.equalToSuperview()
            $0.height.equalTo(48)
        }
        optionBtn.isUserInteractionEnabled = false
        self.contentView.addSubview(optionBtn)
        self.optionBtn.snp.makeConstraints {
            $0.left.equalTo(16)
            $0.top.equalToSuperview()
            $0.height.equalTo(48)
        }
        self.optionBtn.setImage(UDIcon.getIconByKey(.moreAddFilled, iconColor: UIColor.ud.primaryContentDefault, size: CGSize(width: 22, height: 22)), for: .normal)
        self.optionBtn.setImage(UDIcon.getIconByKey(.moreAddFilled, iconColor: UIColor.ud.iconDisabled, size: CGSize(width: 22, height: 22)), for: .disabled)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureAction))
        tapGesture.numberOfTapsRequired = 1
        self.contentView.addGestureRecognizer(tapGesture)

    }

    public func updateCellContent(text: String, clickBlock: (() -> Void)?) {
        self.label.text = text
        self.clickBlock = clickBlock
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupCellContent()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    @objc
    private func tapGestureAction() {
        self.clickBlock?()
    }
}
