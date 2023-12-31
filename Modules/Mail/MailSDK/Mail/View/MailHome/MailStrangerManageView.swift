//
//  MailStrangerManageView.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/3/10.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignButton
import UniverseDesignIcon
import FigmaKit

protocol MailStrangerManageDelegate: AnyObject {
    func didClickStrangerReply(status: Bool)
}

class MailStrangerManageView: UIView {
    weak var delegate: MailStrangerManageDelegate?

    private let allowButton = UDButton()
    private let rejectButton = UDButton()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refreshButton() {
        allowButton.backgroundColor = UIColor.ud.bgFloat
        rejectButton.backgroundColor = UIColor.ud.bgFloat
    }

    private func setupViews() {
        var config = UDButtonUIConifg.secondaryGray
        config.type = .custom(from: .small, font: UIFont.systemFont(ofSize: 14), iconSize: CGSize(width: 16, height: 16))
        config.pressedColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.functionSuccessContentPressed,
                                                          backgroundColor: UIColor.ud.functionSuccessFillTransparent01 , textColor: .ud.textTitle)
        allowButton.config = config
        allowButton.layer.ux.setSmoothCorner(radius: 6)
        allowButton.layer.masksToBounds = true
        allowButton.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        allowButton.layer.borderWidth = 0.5
        allowButton.setTitle(BundleI18n.MailSDK.Mail_StrangerInbox_Allow_Button, for: .normal)
        allowButton.titleLabel?.font = UIFont.systemFont(ofSize: 14.0, weight: .medium)
        allowButton.setImage(UDIcon.yesOutlined.ud.colorize(color: UIColor.ud.functionSuccessContentDefault), for: .normal)
        allowButton.setImage(UDIcon.yesOutlined.ud.colorize(color: UIColor.ud.functionSuccessContentDefault), for: .highlighted)
        allowButton.backgroundColor = UIColor.ud.bgFloat
        addSubview(allowButton)
        allowButton.addTarget(self, action: #selector(didClickAllow), for: .touchUpInside)
        allowButton.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.width.equalToSuperview().dividedBy(2).offset(-4)
            make.height.equalTo(36)
        }

        config.pressedColor = UDButtonUIConifg.ThemeColor(borderColor: .ud.functionDangerContentPressed,
                                                          backgroundColor: .ud.functionDangerFillTransparent01,
                                                          textColor: .ud.textTitle)
        rejectButton.config = config
        rejectButton.layer.ux.setSmoothCorner(radius: 6)
        rejectButton.layer.masksToBounds = true
        rejectButton.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        rejectButton.layer.borderWidth = 0.5
        rejectButton.setTitle(BundleI18n.MailSDK.Mail_StrangerInbox_Reject_Button, for: .normal)
        rejectButton.titleLabel?.font = UIFont.systemFont(ofSize: 14.0, weight: .medium)
        rejectButton.setImage(UDIcon.noOutlined.ud.colorize(color: UIColor.ud.functionDangerContentDefault), for: .normal)
        rejectButton.setImage(UDIcon.noOutlined.ud.colorize(color: UIColor.ud.functionDangerContentDefault), for: .highlighted)
        rejectButton.backgroundColor = UIColor.ud.bgFloat
        addSubview(rejectButton)
        rejectButton.addTarget(self, action: #selector(didClickReject), for: .touchUpInside)
        rejectButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
            make.width.equalToSuperview().dividedBy(2).offset(-4)
            make.height.equalTo(36)
        }
    }

    @objc func didClickAllow() {
        delegate?.didClickStrangerReply(status: true)
    }

    @objc func didClickReject() {
        delegate?.didClickStrangerReply(status: false)
    }
}
