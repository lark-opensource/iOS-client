//
//  SearchResultCell.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/9/25.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import LarkSDKInterface
import ByteWebImage
import UniverseDesignColor
import UniverseDesignButton
import UniverseDesignIcon
import LarkMessengerInterface
import LarkBizAvatar
import LarkSetting
import LarkContactComponent
import RustPB

final class SearchResultCell: UITableViewCell, DataSourceBindable {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        layoutPageSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindWithModel(model: UserProfile, tenantNameService: LarkTenantNameService, fgService: FeatureGatingService) {
        recommandedUserView.bindWithModel(model: model, tenantNameService: tenantNameService, fgService: fgService)
    }

    private func layoutPageSubviews() {
        contentView.addSubview(recommandedUserView)
        recommandedUserView.snp.makeConstraints({ (make) in
            make.edges.equalToSuperview()
        })
    }

    private lazy var recommandedUserView: ContactSearchResultView = {
        let recommandedUserView = ContactSearchResultView(frame: .zero)
        return recommandedUserView
    }()
}

final class ContactSearchResultView: UIView, DataSourceBindable {

    override init(frame: CGRect) {
        super.init(frame: frame)
        layoutPageSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindWithModel(model: UserProfile, tenantNameService: LarkTenantNameService, fgService: FeatureGatingService) {
        avatarView.setAvatarByIdentifier(model.userId,
                                         avatarKey: model.avatarKey,
                                         scene: .Contact,
                                         avatarViewParams: .init(sizeType: .size(avatarSize)))
        nameLabel.text = model.displayNameForSearch
        var companyName = model.company.tenantName
        if fgService.staticFeatureGatingValue(with: "ios.profile.tenantname.unified_component") {
            if tenantContainerView == nil {
                let tenantNameUIConfig = LarkTenantNameUIConfig(
                    tenantNameFont: UIFont.systemFont(ofSize: 14),
                    tenantNameColor: UIColor.ud.textPlaceholder,
                    isShowCompanyAuth: true,
                    isSupportAuthClick: false,
                    isOnlySingleLineDisplayed: true)
                tenantContainerView = tenantNameService.generateTenantNameView(with: tenantNameUIConfig)
                addSubview(tenantContainerView ?? UIView())
            }
            let v2CertificationInfo = tenantContainerView?.transFormCertificationInfo(v1CertificationInfo: model.company.certificationInfo)
            let name = model.company.tenantName
            let tenantNameStatus = model.company.tenantNameStatus
            let tenantInfo = LarkTenantInfo(
                tenantName: name,
                isFriend: model.isFriend,
                tenantNameStatus: tenantNameStatus,
                certificationInfo: v2CertificationInfo,
                tapCallback: nil)
            let (tenantName, _) = tenantContainerView?.config(tenantInfo: tenantInfo) ?? ("", false)
            tenantContainerView?.snp.remakeConstraints { (make) in
                make.top.equalTo(nameLabel.snp.bottom).offset(4)
                make.left.equalTo(avatarView.snp.right).offset(12)
                make.height.equalTo(18)
                make.right.equalTo(agreeButton.snp.left).offset(-12)
            }
            companyName = tenantName
        } else {
            let (tenantName, hasTenantCertification) = fetchSecurityTenantName(userProfile: model)
            let status = model.company.certificationInfo.certificateStatus
            let isTenantCertification = (status == .certificated)
            if hasTenantCertification {
                authTagView.isHidden = false
                setAuthTag(isAuth: isTenantCertification)
            } else {
                authTagView.isHidden = true
            }
            companyLabel.text = tenantName
            companyName = tenantName
        }
        if companyName.isEmpty {
            nameLabel.snp.updateConstraints { (make) in
                make.height.equalTo(45)
            }
        } else {
            nameLabel.snp.updateConstraints { (make) in
                make.height.equalTo(24)
            }
        }
        if model.isFriend {
            statusLabel.text = BundleI18n.LarkContact.Lark_UserGrowth_InvitePeopleSearchAdded
            statusLabel.isHidden = false
            agreeButton.isHidden = true
        } else {
            if !model.requestUserApply && !model.targetUserApply {
                statusLabel.isHidden = true
                agreeButton.isHidden = false
                agreeButton.setTitle(BundleI18n.LarkContact.Lark_UserGrowth_InvitePeopleSearchAdd, for: .normal)
            } else if model.requestUserApply && !model.targetUserApply {
                statusLabel.isHidden = false
                agreeButton.isHidden = true
                statusLabel.text = BundleI18n.LarkContact.Lark_Contacts_ExternalContactRequestSent
            } else if !model.requestUserApply && model.targetUserApply {
                statusLabel.isHidden = true
                agreeButton.isHidden = false
                agreeButton.setTitle(BundleI18n.LarkContact.Lark_Legacy_Agree, for: .normal)
            }

            if !agreeButton.isHidden {
                if let width = agreeButton.titleLabel?.text?.getWidth(font: agreeButton.titleLabel?.font ?? UIFont.systemFont(ofSize: 12)) {
                    let buttonWidth = max(width + 32, 60)
                    agreeButton.snp.updateConstraints { (make) in
                        make.width.equalTo(buttonWidth)
                    }
                }
            }
        }
    }

    private func fetchSecurityTenantName(userProfile: UserProfile) -> (String, Bool) {
        let tenantName = userProfile.company.tenantName
        let status = userProfile.company.certificationInfo.certificateStatus
        let hasTenantCertification = tenantName.isEmpty ? false : (userProfile.company.certificationInfo.isShowCertSign && status != .teamCertificated)
        switch userProfile.company.tenantNameStatus {
        case .visible:
            return (tenantName, hasTenantCertification)
        case .notFriend:
            return userProfile.isFriend ? (tenantName, hasTenantCertification) : (BundleI18n.LarkContact.Lark_IM_Profile_AddAsExternalContactToViewOrgInfo_Placeholder, false)
        case .hide:
            return (BundleI18n.LarkContact.Lark_IM_Profile_UserHideOrgInfo_Placeholder, false)
        case .unknown:
            break
        @unknown default:
            break
        }
        return (tenantName, hasTenantCertification)
    }

    private func setAuthTag(isAuth: Bool) {
        let text = isAuth ? BundleI18n.LarkContact.Lark_FeishuCertif_Verif : BundleI18n.LarkContact.Lark_FeishuCertif_Unverif
        let font = UIFont.systemFont(ofSize: 12)
        let icon = isAuth ? UDIcon.verifyFilled.ud.withTintColor(UIColor.ud.udtokenTagTextSTurquoise) : nil
        let backgroundColor = isAuth ? UIColor.ud.udtokenTagBgTurquoise : UIColor.ud.udtokenTagNeutralBgNormal
        let textColor = isAuth ? UIColor.ud.udtokenTagTextSTurquoise : UIColor.ud.textCaption
        let attributedString = NSAttributedString(
            string: text,
            attributes: [
                .foregroundColor: textColor,
                .font: font
            ]
        )

        authTagView.configUI(backgroundColor: backgroundColor,
                         icon: icon,
                         font: font,
                         attributedString: attributedString)

        let tagSize = authTagView.getSize()
        authTagView.snp.updateConstraints { (make) in
            make.width.equalTo(tagSize)
        }
    }

    private func layoutPageSubviews() {
        self.backgroundColor = UIColor.ud.bgBody
        self.addSubview(avatarView)
        self.addSubview(nameLabel)
        self.addSubview(companyLabel)
        self.addSubview(authTagView)
        self.addSubview(agreeButton)
        self.addSubview(statusLabel)
        avatarView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }
        agreeButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
            make.height.equalTo(28)
            make.right.equalToSuperview().offset(-16)
        }
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.right.equalTo(agreeButton.snp.left).offset(-45)
            make.top.equalToSuperview().offset(11.5)
            make.height.equalTo(24)
        }
        companyLabel.snp.makeConstraints { (make) in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.height.equalTo(18)
        }
        authTagView.snp.makeConstraints { (make) in
            make.centerY.equalTo(companyLabel.snp.centerY)
            make.left.equalTo(companyLabel.snp.right).offset(7)
            make.height.equalTo(18)
            make.width.equalTo(0)
            make.right.lessThanOrEqualTo(agreeButton.snp.left).offset(-12)
        }
        statusLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
            make.height.equalTo(19)
            make.right.equalToSuperview().offset(-16)
        }
    }

    private let avatarSize: CGFloat = 40
    private lazy var avatarView: BizAvatar = {
        let view = BizAvatar()
        view.image = Resources.add_contact_icon
        view.layer.cornerRadius = 20.0
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 17)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var companyLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var bottomLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    private lazy var agreeButton: UDButton = {
        let button = UDButton.primaryBlue
        button.isUserInteractionEnabled = false
        button.titleLabel?.textColor = UIColor.ud.primaryOnPrimaryFill
        return button
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    private lazy var authTagView: AuthTagView = {
        let tagView = AuthTagView(frame: .zero)
        tagView.isHidden = true
        return tagView
    }()

    private var tenantContainerView: LarkTenantNameViewInterface?
}

final class AuthTagView: UIView {
    lazy var iconView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        return imageView
    }()

    lazy var label: UILabel = {
        let label = UILabel()
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.cornerRadius = 4
        self.layer.masksToBounds = true
        self.addSubview(label)
        self.addSubview(iconView)
    }

    func configUI(backgroundColor: UIColor,
                  icon: UIImage?,
                  font: UIFont,
                  attributedString: NSAttributedString) {
        let isShowIcon = icon != nil
        self.backgroundColor = backgroundColor
        if isShowIcon {
            iconView.frame = CGRect(x: 4, y: 3, width: 12, height: 12)
        } else {
            iconView.frame = .zero
        }
        if let icon = icon {
            iconView.image = icon
        }
        let width = (attributedString.string  as NSString).boundingRect(
            with: CGSize(width: Int.max, height: 20),
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil).width
        label.frame = CGRect(x: iconView.frame.maxX + (isShowIcon ? 2 : 4), y: 0, width: width, height: 18)
        label.attributedText = attributedString
    }

    func getSize() -> CGSize {
        return CGSize(width: label.frame.maxX + 4, height: 18)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
