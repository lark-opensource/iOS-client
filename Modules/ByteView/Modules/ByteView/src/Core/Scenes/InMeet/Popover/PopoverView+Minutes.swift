//
//  PopoverView+Minutes.swift
//  ByteView
//
//  Created by wulv on 2021/12/31.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

struct PeopleMinutesText {
    static let title = I18n.View_G_WrittenRecord_HoverTitle
    static let content = I18n.View_G_WrittenRecordForFair_HoverExplain
    static let stop = I18n.View_G_EndWrittenRecording_Button
}

class MinutesPopover: UIView {

    struct Model {
        let title: String
        let content: String
        let button: String
        let buttonAction: (() -> Void)
    }

    private(set) var model: Model

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: 16.0, weight: .medium)
        label.text = model.title
        return label
    }()

    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.text = model.content
        return label
    }()

    lazy var bottomButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentLoading, for: .highlighted)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.contentHorizontalAlignment = .leading
        button.setTitle(model.button, for: .normal)
        button.addTarget(self, action: #selector(bottomButtonButtonAction), for: .touchUpInside)
        return button
    }()

    @objc private func bottomButtonButtonAction() {
        model.buttonAction()
    }

    init(frame: CGRect = .zero, with model: Model) {
        self.model = model
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(16)
            make.height.equalTo(22)
        }

        addSubview(contentLabel)
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.equalTo(titleLabel.snp.left)
            make.right.equalTo(titleLabel.snp.right)
        }

        addSubview(bottomButton)
        bottomButton.snp.makeConstraints { make in
            make.top.equalTo(contentLabel.snp.bottom).offset(6)
            make.left.equalTo(contentLabel.snp.left)
            make.height.equalTo(20)
            make.bottom.equalToSuperview().offset(-16)
        }
    }
}

extension PopoverView {

    static func peopleMinutesPopover(sourceView: UIView?, with configures: [PopoverLayoutConfigure]?, buttonAction: @escaping (() -> Void)) -> PopoverView {
        let model = MinutesPopover.Model(title: PeopleMinutesText.title, content: PeopleMinutesText.content,
                                         button: PeopleMinutesText.stop, buttonAction: buttonAction)
        let content = MinutesPopover(with: model)
        let popover = PopoverView(sourceView: sourceView, contentView: content, with: configures)
        return popover
    }
}
