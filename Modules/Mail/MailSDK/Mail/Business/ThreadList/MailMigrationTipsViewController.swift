//
//  MailMigrationTipsViewController.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2021/12/4.
//

import Foundation
import UIKit
import SnapKit
import RustPB
import UniverseDesignColor

protocol MailMigrationTipsViewControllerDelegate: AnyObject {
    func migrationTipsButtonClick(_ flag: Bool, provider: MailTripartiteProvider)
}

class MailMigrationTipsViewController: WidgetViewController {

    weak var delegate: MailMigrationTipsViewControllerDelegate?
    let topMargin: CGFloat = 24
    let detailMargin: CGFloat = 12
    let msgHeight: CGFloat = 136
    let bottomMargin: CGFloat = 74

    let titleLabel = UILabel()
    let detailLabel = UILabel()
    var titleText = ""
    var detailText = ""

    var titleHeight: CGFloat = 24
    var detailHeight: CGFloat = 80

    var imapResp: MailIMAPMigrationOldestMessage
    var provider: MailTripartiteProvider
    var rootSizeClassIsRegular: Bool

    init(provider: MailTripartiteProvider, imapResp: MailIMAPMigrationOldestMessage, rootSizeClassIsRegular: Bool) {
        self.provider = provider
        self.imapResp = imapResp
        self.rootSizeClassIsRegular = rootSizeClassIsRegular
        let contentHeight = max(362, topMargin + titleHeight + detailMargin + detailHeight + msgHeight + bottomMargin)
        super.init(contentHeight: contentHeight)
        contentView.backgroundColor = UIColor.ud.bgFloat
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        needAnimated = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    @objc
    func noButtonClicked() {
        animatedView(isShow: false) { [weak self] in
            guard let `self` = self else { return }
            self.delegate?.migrationTipsButtonClick(false, provider: self.provider)
        }
    }

    @objc
    func yesButtonClicked() {
        animatedView(isShow: false) { [weak self] in
            guard let `self` = self else { return }
            self.delegate?.migrationTipsButtonClick(true, provider: self.provider)
        }
    }

    private func daysBetween(firstDate: Date, secondDate: Date) -> Int {
        let calendar = Calendar.current
        let date1 = calendar.startOfDay(for: firstDate)
        let date2 = calendar.startOfDay(for: secondDate)
        let components = calendar.dateComponents([.day], from: date1, to: date2)
        return components.day ?? 0
    }

    func setupViews() {
        view.backgroundColor = UIColor.ud.bgMask.withAlphaComponent(0.4)

        titleText = BundleI18n.MailSDK.Mail_ThirdClient_SyncEnabledConfirmFollowing
        let daysMargin = daysBetween(firstDate: Date(), secondDate: Date(timeIntervalSince1970: TimeInterval(imapResp.sendTimestamp/1000)))
        detailText = "\(BundleI18n.MailSDK.Mail_ThirdClient_FirstEmailDaysAgo(imapResp.totalMessageCount, abs(daysMargin)))\n\(BundleI18n.MailSDK.Mail_ThirdClient_ConfirmFirstEmail)"

        let tipWidth: CGFloat = rootSizeClassIsRegular ? 400 : 300

        titleLabel.textColor = UIColor.ud.iconN1
        titleLabel.text = titleText
        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        let calTitleHeight = titleText.getTextHeight(font: titleLabel.font, width: tipWidth - 40.0) //, 24)
        if calTitleHeight > titleHeight {
            titleHeight = calTitleHeight
        }
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.top.equalTo(24)
            make.right.equalTo(-20)
//            make.height.equalTo(titleHeight)
        }

        detailLabel.textColor = UIColor.ud.textTitle
        detailLabel.text = detailText
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        detailLabel.numberOfLines = 0
        let calDetailHeight: CGFloat = detailText.getTextHeight(font: detailLabel.font, width: tipWidth - 40)
        if calDetailHeight > detailHeight {
            detailHeight = calDetailHeight
        }
        contentView.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.right.equalTo(-20)
//            make.height.equalTo(detailHeight)
        }

        let msgBg = UIView()
        msgBg.layer.cornerRadius = 6
        msgBg.layer.masksToBounds = true
        msgBg.backgroundColor = UIColor.ud.bgFloatOverlay
        contentView.addSubview(msgBg)
        msgBg.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.top.equalTo(detailLabel.snp.bottom).offset(12)
            make.right.equalTo(-20)
//            make.height.equalTo(msgHeight)
        }

        let msgTitle = UILabel()
        msgTitle.textColor = UIColor.ud.textTitle
        msgTitle.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        msgTitle.numberOfLines = 2
        msgTitle.text = imapResp.title
        msgBg.addSubview(msgTitle)
        msgTitle.snp.makeConstraints { make in
            make.left.top.equalTo(8)
            make.right.equalTo(-8)
            make.height.greaterThanOrEqualTo(20)
            make.height.lessThanOrEqualTo(40)
        }

        let senderTitle = UILabel()
        senderTitle.textColor = UIColor.ud.textCaption
        senderTitle.font = UIFont(name: "PingFangSC-Medium", size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .medium)
        senderTitle.text = BundleI18n.MailSDK.Mail_ThirdClient_Sender
        msgBg.addSubview(senderTitle)
        senderTitle.snp.makeConstraints { make in
            make.top.equalTo(msgTitle.snp.bottom).offset(8)
            make.left.equalTo(8)
            make.right.equalTo(-8)
            make.height.equalTo(20)
        }

        let sender = UILabel()
        sender.textColor = UIColor.ud.textCaption
        sender.font = UIFont(name: "PingFangSC-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        sender.numberOfLines = 2
        sender.text = imapResp.sender
        //sender.numberOfLines = 2
        msgBg.addSubview(sender)
        sender.snp.makeConstraints { make in
            make.top.equalTo(senderTitle.snp.bottom).offset(2)
            make.left.equalTo(8)
            make.right.equalTo(-8)
            make.height.greaterThanOrEqualTo(20)
            make.height.lessThanOrEqualTo(40)
//            make.height.equalTo(20)
        }

        let dateTitle = UILabel()
        dateTitle.textColor = UIColor.ud.textCaption
        dateTitle.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        dateTitle.text = BundleI18n.MailSDK.Mail_ThirdClient_SendTime
        msgBg.addSubview(dateTitle)
        dateTitle.snp.makeConstraints { make in
            make.top.equalTo(sender.snp.bottom).offset(8)
            make.left.equalTo(8)
            make.right.equalTo(-8)
            make.height.equalTo(20)
        }

        let date = UILabel()
        date.textColor = UIColor.ud.textCaption
        date.font = UIFont.systemFont(ofSize: 14)
        date.text = ProviderManager.default.timeFormatProvider?.relativeDate(imapResp.sendTimestamp / 1000, showTime: true) ?? ""
        msgBg.addSubview(date)
        date.snp.makeConstraints { make in
            make.top.equalTo(dateTitle.snp.bottom).offset(2)
            make.left.equalTo(8)
            make.right.equalTo(-8)
            make.height.equalTo(20)
            make.bottom.equalToSuperview().offset(-8)
        }

        let noButton = UIButton(type: .custom)
        noButton.setTitle(BundleI18n.MailSDK.Mail_ThirdClient_No, for: .normal)
        noButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
        noButton.addTarget(self, action: #selector(noButtonClicked), for: .touchUpInside)
        contentView.addSubview(noButton)
        noButton.snp.makeConstraints { make in
            make.top.equalTo(msgBg.snp.bottom).offset(24)
            make.left.bottom.equalToSuperview()
            make.height.equalTo(50)
            make.width.equalToSuperview().multipliedBy(0.5)
        }

        let yesButton = UIButton(type: .custom)
        yesButton.setTitle(BundleI18n.MailSDK.Mail_ThirdClient_Yes, for: .normal)
        yesButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        yesButton.addTarget(self, action: #selector(yesButtonClicked), for: .touchUpInside)
        contentView.addSubview(yesButton)
        yesButton.snp.makeConstraints { make in
            make.top.equalTo(msgBg.snp.bottom).offset(24)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(50)
            make.width.equalToSuperview().multipliedBy(0.5)
        }

        let horSep = UIView()
        horSep.backgroundColor = UIColor.ud.lineDividerDefault
        contentView.addSubview(horSep)
        horSep.snp.makeConstraints { make in
            make.top.equalTo(noButton)
            make.height.equalTo(1)
            make.width.equalToSuperview()
        }

        let verSep = UIView()
        verSep.backgroundColor = UIColor.ud.lineDividerDefault
        contentView.addSubview(verSep)
        verSep.snp.makeConstraints { make in
            make.top.equalTo(noButton).offset(1)
            make.left.equalTo(noButton.snp.right).offset(-0.5)
            make.height.bottom.equalTo(noButton)
            make.width.equalTo(1)
        }

        contentHeight = max(362, topMargin + titleHeight + detailMargin + detailHeight + msgHeight + bottomMargin)
        contentView.snp.remakeConstraints { (make) in
            make.left.greaterThanOrEqualTo(16)
            make.width.lessThanOrEqualTo(400)
            make.width.equalTo(400).priority(.high)
//            make.height.equalTo(contentHeight)
            make.center.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
