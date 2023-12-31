//
//  MailScheduleSendNavBar.swift
//  MailSDK
//
//  Created by majx on 2020/12/5.
//

import Foundation
import SnapKit

class MailScheduleSendNavBar: UIView {
    private var isShowSubTitle: Bool = false
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        self.backgroundColor = UIColor.ud.bgBody
        self.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.height.equalTo(Display.realNavBarHeight())
            make.leading.trailing.bottom.equalTo(0)
        }
        contentView.addSubview(closeButton)
        contentView.addSubview(confirmButton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subTitleLabel)

        titleLabel.text = BundleI18n.MailSDK.Mail_SendLater_ScheduleSend

        closeButton.snp.makeConstraints { (make) in
            make.leading.equalTo(20)
            make.centerY.equalToSuperview()
        }

        confirmButton.snp.makeConstraints { (make) in
            make.trailing.equalTo(-16)
            make.centerY.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { (make) in
            make.centerY.centerX.equalToSuperview()
        }

        subTitleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
        }
        subTitleLabel.alpha = 0.0
    }

    func updateScheduleDate(_ date: Date) {
        if let timeStr = ProviderManager.default.timeFormatProvider?.mailScheduleSendTimeFormat(Int64(date.timeIntervalSince1970)) {
            subTitleLabel.text = BundleI18n.MailSDK.Mail_SendLater_ScheduledForDate(timeStr ?? "")
        }
    }

    func showSubTitle(show: Bool, _ animation: Bool = true) {
        guard show != isShowSubTitle else { return }

        UIView.animate(withDuration: timeIntvl.uiAnimateNormal, delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 5,
                       options: .curveEaseIn) {
            if show {
                let offsetY: CGFloat = -8
                self.titleLabel.transform = CGAffineTransform.identity.translatedBy(x: 0, y: offsetY)
                self.subTitleLabel.transform = CGAffineTransform.identity.translatedBy(x: 0, y: offsetY)
                self.subTitleLabel.alpha = 1.0
                self.isShowSubTitle = true
            } else {
                self.titleLabel.transform = CGAffineTransform.identity
                self.subTitleLabel.transform = CGAffineTransform.identity
                self.subTitleLabel.alpha = 0.0
                self.isShowSubTitle = false
            }
        }
    }

    lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .center
        return label
    }()

    lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .center
        return label
    }()

    lazy var closeButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(Resources.navigation_cancel.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.tintColor = UIColor.ud.iconN1
        return btn
    }()

    lazy var confirmButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        btn.setTitleColor(UIColor.ud.textDisable, for: .disabled)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        btn.setTitle(BundleI18n.MailSDK.Mail_Common_Confirm, for: .normal)
        return btn
    }()
}
