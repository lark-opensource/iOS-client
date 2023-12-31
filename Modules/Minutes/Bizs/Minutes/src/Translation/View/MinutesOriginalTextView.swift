//
//  MinutesOriginalTextView.swift
//  Minutes
//
//  Created by yangyao on 2021/2/23.
//

import UIKit
import YYText
import UniverseDesignIcon

class MinutesOriginalTextView: UIView {
    let maskLayer = CAShapeLayer()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.Minutes.MMWeb_G_OriginalLanguage
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .center
        return label
    }()

    lazy var closeButton: UIButton = {
        let button = UIButton()
        let image = UDIcon.getIconByKey(.closeSmallOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 24, height: 24))

        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        return button
    }()

    lazy var contentTextView: YYTextView = {
        let textView = YYTextView()
        textView.showsVerticalScrollIndicator = false
        textView.font = .systemFont(ofSize: 17)
        textView.allowsCopyAttributedString = false
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        textView.isEditable = false
        return textView
    }()

    lazy var line = UIView()

    @objc func dismissSelf() {
        removeFromSuperview()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.shadowColor = UIColor.ud.staticBlack.withAlphaComponent(0.08).cgColor
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowRadius = 2
        layer.shadowOpacity = 1.0
        layer.cornerRadius = 12

        backgroundColor = UIColor.ud.bgFloat

        addSubview(titleLabel)
        addSubview(closeButton)
        addSubview(contentTextView)
        addSubview(line)

        titleLabel.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(14)
            maker.left.equalTo(56)
            maker.right.equalTo(-56)
        }
        closeButton.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(16)
            maker.width.height.equalTo(24)
            maker.centerY.equalTo(titleLabel)
        }
        line.backgroundColor = UIColor.ud.lineDividerDefault
        line.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview()
            maker.height.equalTo(0.5)
            maker.top.equalToSuperview().inset(48)
        }
        contentTextView.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(24)
            maker.right.equalToSuperview().offset(-24)
            maker.top.equalTo(titleLabel.snp.bottom).offset(30)
            maker.bottom.equalTo(self.safeAreaLayoutGuide).offset(-20)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
