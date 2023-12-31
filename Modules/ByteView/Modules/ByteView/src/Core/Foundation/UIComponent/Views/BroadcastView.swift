//
//  BroadcastView.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/3/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import UniverseDesignIcon

class BroadcastView: UIView {
    private var iconView: UIImageView = .init(image: nil)
    private var textView: UITextView!
    private var closeButton: UIButton!
    private(set) var contentText: String?

    var closeAction: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        backgroundColor = UIColor.ud.G50

        let image = UDIcon.getIconByKey(.announceFilled, iconColor: .ud.functionSuccessContentDefault, size: CGSize(width: 16, height: 16))
        iconView = UIImageView(image: image)
        addSubview(iconView)
        iconView.snp.makeConstraints { (make) in
            make.top.equalTo(18)
            make.left.equalTo(16)
            make.width.height.equalTo(16)
        }

        closeButton = UIButton(type: .custom)
        closeButton.setImage(UDIcon.getIconByKey(.closeOutlined, iconColor: .ud.iconN2, size: CGSize(width: 16, height: 16)), for: .normal)
        closeButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.top.equalTo(18)
            make.right.equalToSuperview().inset(16)
            make.width.height.equalTo(16)
        }

        textView = UITextView()
        textView.textContainerInset = .zero
        textView.layoutManager.usesFontLeading = false
        textView.textContainer.lineFragmentPadding = 0
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        textView.isEditable = false
        addSubview(textView)
        textView.snp.makeConstraints { (make) in
            make.left.equalTo(iconView.snp.right).offset(8)
            make.right.equalTo(closeButton.snp.left).offset(-16)
            make.top.bottom.equalToSuperview().inset(16)
        }
    }

    func setText(_ text: String) {
        contentText = text
        let content = NSMutableAttributedString()

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.12
        content.append(NSAttributedString(string: I18n.View_G_FromTheHost,
                                          attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .medium),
                                                       .foregroundColor: UIColor.ud.textTitle,
                                                       .paragraphStyle: paragraphStyle]))

        content.append(NSAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .regular),
                                                                     .foregroundColor: UIColor.ud.textTitle,
                                                                     .paragraphStyle: paragraphStyle]))

        textView.attributedText = content
    }

    @objc func dismiss() {
        closeAction?()
    }
}
