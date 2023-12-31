//
//  ShareContentNewFileCell.swift
//  ByteView
//
//  Created by liurundong.henry on 2021/9/18.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

class ShareContentNewFileCell: UITableViewCell {

    var tapCreateAndShareButtonClosure: ((UIView) -> Void)?

    private let infoLabel: UILabel = {
        let label = UILabel()
        label.attributedText = .init(string: I18n.View_VM_ShareDocs, config: .boldBodyAssist, textColor: UIColor.ud.textCaption)
        return label
    }()

    private let createAndShareButton: UIButton = {
        let button = UIButton()
        button.clipsToBounds = true
        button.setAttributedTitle(.init(string: I18n.View_MV_Add_SharingDoc, config: .bodyAssist), for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 4.0, bottom: 0, right: 4.0)
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnTextBgPriPressed, for: .highlighted)
        button.layer.cornerRadius = 6
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.ud.bgFloatBase
        // config color when pressed
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = UIColor.ud.bgFloatBase
        self.selectedBackgroundView = selectedBackgroundView
        setupSubviews()
        setupButtonTap()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        contentView.addSubview(infoLabel)
        contentView.addSubview(createAndShareButton)

        infoLabel.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.right.lessThanOrEqualTo(createAndShareButton.snp.left)
            maker.top.equalToSuperview().offset(22.0)
            maker.height.equalTo(20.0)
        }
        createAndShareButton.snp.makeConstraints { maker in
            maker.right.equalToSuperview()
            maker.top.equalToSuperview().offset(22.0)
            maker.height.equalTo(20.0)
        }
    }

    private func setupButtonTap() {
        createAndShareButton.addTarget(self, action: #selector(tapButton), for: .touchUpInside)
    }

    func configTapAction(tapCreateAndShare actionClosure: @escaping ((UIView) -> Void)) {
        self.tapCreateAndShareButtonClosure = actionClosure
    }

    func configCellEnabled(_ isEnabled: Bool) {
        isUserInteractionEnabled = isEnabled ? true : false
        createAndShareButton.setTitleColor(isEnabled ? UIColor.ud.colorfulBlue : UIColor.ud.textDisabled, for: .normal)
        infoLabel.textColor = isEnabled ? UIColor.ud.textCaption : UIColor.ud.textDisabled
    }

    @objc
    func tapButton() {
        self.tapCreateAndShareButtonClosure?(self.createAndShareButton)
    }

}
