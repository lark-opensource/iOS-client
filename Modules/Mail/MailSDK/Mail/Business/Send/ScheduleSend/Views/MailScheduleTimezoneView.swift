//
//  Cell.swift
//  MailSDK
//
//  Created by majx on 2020/12/5.
//

import Foundation
import SnapKit

protocol MailScheduleTimezoneViewDelegate: AnyObject {
    func onClickTimezoneView()
}

class MailScheduleTimezoneView: UIView {
    private var iconTimezone = UIImageView()
    private var iconMore = UIImageView()
    private var topBorder = UIView()
    private var bottomBorder = UIView()
    private var titleLabel = UILabel()

    weak var delegate: MailScheduleTimezoneViewDelegate?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    func setupViews() {
        backgroundColor = UIColor.ud.bgBody
        iconMore.tintColor = UIColor.ud.iconN3

        addSubview(iconTimezone)
        iconTimezone.image = Resources.mail_icon_time_zone
        iconTimezone.snp.makeConstraints { (make) in
            make.leading.equalTo(16)
            make.centerY.equalToSuperview()
        }

        addSubview(titleLabel)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.numberOfLines = 0
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalTo(iconTimezone.snp.trailing).offset(8)
            make.trailing.equalTo(-48)
        }

        addSubview(iconMore)
        iconMore.image = Resources.mail_setting_icon_arrow_small.withRenderingMode(.alwaysTemplate)
        iconMore.snp.makeConstraints { (make) in
            make.trailing.equalTo(-16)
            make.centerY.equalToSuperview()
        }

        addSubview(topBorder)
        topBorder.backgroundColor = UIColor.ud.lineDividerDefault
        topBorder.snp.makeConstraints { (make) in
            make.left.right.top.equalTo(0)
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }

        addSubview(bottomBorder)
        bottomBorder.backgroundColor = UIColor.ud.lineDividerDefault
        bottomBorder.snp.makeConstraints { (make) in
            make.left.right.bottom.equalTo(0)
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onClick))
        self.addGestureRecognizer(tapRecognizer)
    }

    func updateTimezone(name: String) {
        titleLabel.text = name
    }

    @objc
    func onClick() {
        delegate?.onClickTimezoneView()
    }
}
