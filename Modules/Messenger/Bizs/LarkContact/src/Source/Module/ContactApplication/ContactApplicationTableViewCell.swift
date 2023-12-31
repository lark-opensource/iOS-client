//
//  ContactApplicationTableViewCell.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/8/5.
//

import Foundation
import UIKit
import LarkModel
import LarkUIKit
import LarkCore
import LarkSDKInterface
import LarkContactComponent
import LarkSetting

protocol ContactApplicationTableViewCellDelegate: AnyObject {
    func viewAction(_ cell: ContactApplicationTableViewCell)
}

final class ContactApplicationTableViewCell: BaseTableViewCell {
    private lazy var acceptedButton: UIButton = {
        let acceptedButton = UIButton()
        acceptedButton.backgroundColor = .clear
        acceptedButton.layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
        acceptedButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        acceptedButton.titleLabel?.textAlignment = .center
        acceptedButton.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        acceptedButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12)
        acceptedButton.layer.cornerRadius = 4
        acceptedButton.addTarget(self, action: #selector(acceptedAction), for: .touchUpInside)
        acceptedButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        acceptedButton.isHidden = true
        return acceptedButton
    }()

    private lazy var bottomSeperator: UIView = {
        let bottomSeperator = UIView()
        bottomSeperator.backgroundColor = UIColor.ud.lineDividerDefault
        bottomSeperator.isHidden = true
        return bottomSeperator
    }()

    private var tenantContainerView: LarkTenantNameViewInterface?
    private lazy var contactListView = ContactListView()
    private var highlightColor = UIColor.ud.fillHover

    weak var delegate: ContactApplicationTableViewCellDelegate?
    private lazy var acceptedButtonWidth: CGFloat = {
        return BundleI18n.LarkContact.Lark_NewContacts_ContactRequestAccepted.lu.width(font: UIFont.systemFont(ofSize: 14), height: 28) + 32
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = UIColor.ud.bgBody
        setupBackgroundViews(highlightOn: true)

        contentView.addSubview(acceptedButton)
        contentView.addSubview(bottomSeperator)
        contentView.addSubview(contactListView)

        contactListView.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(acceptedButton.snp.left).offset(-16)
        }

        bottomSeperator.snp.makeConstraints { (make) in
            make.left.equalTo(contactListView.nameLabel.snp.left)
            make.height.equalTo(1 / UIScreen.main.scale)
            make.bottom.equalToSuperview()
            make.right.equalToSuperview()
        }

        let width = self.acceptedButtonWidth
        acceptedButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
            make.width.equalTo(width)
            make.height.equalTo(28)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setButtonStyle(title: String, enabled: Bool) {
        acceptedButton.isHidden = false
        acceptedButton.snp.updateConstraints { (make) in
            make.width.equalTo(self.acceptedButtonWidth)
        }
        acceptedButton.setTitle(title, for: .normal)
        acceptedButton.isUserInteractionEnabled = enabled
        if enabled {
            acceptedButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
            acceptedButton.layer.borderWidth = 1
        } else {
            acceptedButton.setTitleColor(UIColor.ud.textPlaceholder, for: .normal)
            acceptedButton.layer.borderWidth = 0
        }
    }

    func setContent(
        _ model: ChatApplication,
        delegate: ContactApplicationTableViewCellDelegate,
        tenantNameService: LarkTenantNameService
        ) {

        self.delegate = delegate

        switch model.status {
        case .pending:
            setButtonStyle(title: BundleI18n.LarkContact.Lark_Legacy_Agree, enabled: true)
        case .expired:
            setButtonStyle(title: BundleI18n.LarkContact.Lark_Legacy_HistoryExpired, enabled: false)
        case .agreed:
            setButtonStyle(title: BundleI18n.LarkContact.Lark_NewContacts_ContactRequestAccepted, enabled: false)
        case .refused, .deleted, .unknownStatus:
            acceptedButton.snp.updateConstraints { (make) in
                make.width.equalTo(0)
            }
            break
        @unknown default:
            fatalError("new value")
            break
        }
        if tenantContainerView == nil {
            let tenantNameUIConfig = LarkTenantNameUIConfig(
                tenantNameFont: UIFont.systemFont(ofSize: 14),
                tenantNameColor: UIColor.ud.textTitle,
                isShowCompanyAuth: true,
                isOnlySingleLineDisplayed: true)
            let tenantContainView = tenantNameService.generateTenantNameView(with: tenantNameUIConfig)
            tenantContainerView = tenantContainView
        }
        let isFriend = model.status == .agreed
        let v2CertificationInfo = tenantContainerView?.transFormCertificationInfo(basicV1CertificationInfo: model.contactSummary.certificationInfo)
        let tenantInfo = LarkTenantInfo(
            tenantName: model.contactSummary.tenantName,
            isFriend: isFriend,
            tenantNameStatus: model.contactSummary.tenantNameStatus,
            certificationInfo: v2CertificationInfo,
            tapCallback: nil)
        let (tenantName, _) = tenantContainerView?.config(tenantInfo: tenantInfo) ?? ("", false)
        contactListView.set(name: model.contactSummary.displayName,
                            info: model.extraMessage,
                            tenantName: tenantName,
                            entityId: model.contactSummary.userId,
                            avartKey: model.contactSummary.avatarKey,
                            tenantContainerView: tenantContainerView)
    }

    @objc
    func acceptedAction() {
        self.delegate?.viewAction(self)
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.setBackViewColor(highlighted ? self.highlightColor : UIColor.ud.bgBody)
    }

}
