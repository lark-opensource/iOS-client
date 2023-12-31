//
//  EventEmailSuggestionView.swift
//  Calendar
//
//  Created by 张威 on 2020/6/5.
//

import UIKit

final class EventEmailSuggestionView: UIView {

    var suggestion: String = "" {
        didSet {
            textView.text = suggestion
        }
    }

    var onClick: (() -> Void)?

    private let contentView = UIButton()
    private let bottomLineView = UIView()
    private let iconView = UIImageView()
    private let textView = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody

        contentView.addTarget(self, action: #selector(didClickContentView), for: .touchUpInside)
        addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.top.left.right.equalToSuperview()
            $0.height.equalTo(68)
        }

        iconView.image = UIImage.cd.image(named: "add_email_attendee")
        contentView.addSubview(iconView)
        iconView.snp.makeConstraints {
            $0.left.equalTo(16)
            $0.top.equalTo(10)
            $0.width.height.equalTo(48)
        }

        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textColor = UIColor.ud.textTitle
        contentView.addSubview(textView)
        textView.snp.makeConstraints {
            $0.left.equalTo(iconView.snp.right).offset(12)
            $0.right.equalToSuperview().offset(-16)
            $0.centerY.equalTo(iconView)
        }

        bottomLineView.backgroundColor = UIColor.ud.lineDividerDefault
        addSubview(bottomLineView)
        bottomLineView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(76)
            $0.right.equalToSuperview()
            $0.top.equalTo(contentView.snp.bottom)
            $0.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didClickContentView() {
        onClick?()
    }

}
