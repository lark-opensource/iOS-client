//
//  InvitationView.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/9/10.
//

import UIKit
import Foundation
import LarkModel
import LarkCore
import LarkUIKit
import LarkButton
import UniverseDesignToast
import RustPB

protocol InvitationViewDelegate: AnyObject {
    func invite(type: RustPB.Contact_V1_SendUserInvitationRequest.TypeEnum, content: String)
    func popViewController()
    func pushPersonCard()
    func pushSelectVC()
}

final class InvitationView: UIView {
    private typealias card = (entityId: String, avatarKey: String, displayName: String, tenantName: String)

    private enum InviteStatus {
        case invite, confirm, invited(card)
    }

    static let emailRegex: String = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
    static let emailPredicate: NSPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

    lazy var inviteButton: LarkButton.TypeButton = {
        let inviteButton = LarkButton.TypeButton(style: .largeA)
        inviteButton.setTitle(BundleI18n.LarkContact.Lark_Legacy_PersoncardLinkButton, for: .normal)
        inviteButton.isEnabled = false
        inviteButton.addTarget(self, action: #selector(inviteAction), for: .touchUpInside)
        return inviteButton
    }()

    lazy var inviteView: UIView = {
        let inviteImageView = UIImageView()
        inviteImageView.contentMode = .scaleAspectFit
        inviteImageView.image = Resources.invite
        return inviteImageView
    }()

    lazy var inviteLabel: UILabel = {
        let inviteLabel = UILabel()
        inviteLabel.numberOfLines = 2
        inviteLabel.font = UIFont.systemFont(ofSize: 14)
        inviteLabel.textColor = UIColor.ud.N600
        inviteLabel.textAlignment = .center
        return inviteLabel
    }()

    lazy var bottomSeperator: UIView = {
        let bottomSeperator = UIView()
        bottomSeperator.backgroundColor = UIColor.ud.commonTableSeparatorColor
        return bottomSeperator
    }()

    lazy var inviteInputView: UITextField = {
        let inviteInputView = UITextField()
        inviteInputView.textAlignment = .left
        inviteInputView.font = UIFont.systemFont(ofSize: 16)
        inviteInputView.textColor = UIColor.ud.N900
        inviteInputView.clearButtonMode = .whileEditing
        inviteInputView.autocorrectionType = .no
        inviteInputView.returnKeyType = .done
        inviteInputView.delegate = self
        inviteInputView.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        return inviteInputView
    }()

    lazy var selectNumberLabel: UILabel = {
        let selectNumberLabel = UILabel()
        selectNumberLabel.text = countryNumber
        selectNumberLabel.textColor = UIColor.ud.N900
        selectNumberLabel.font = UIFont.boldSystemFont(ofSize: 16)
        return selectNumberLabel
    }()

    let invitationType: RustPB.Contact_V1_SendUserInvitationRequest.TypeEnum
    let isTenantInvite: Bool

    private var inviteStatus: InviteStatus = .invite {
        didSet {
            setInviteStatus(inviteStatus)
        }
    }

    weak var delegate: InvitationViewDelegate?

    var bgTapGesture: UITapGestureRecognizer?

    var countryNumber: String = "+86" {
        didSet {
            selectNumberLabel.text = countryNumber
        }
    }

    init(invitationType: RustPB.Contact_V1_SendUserInvitationRequest.TypeEnum, delegate: InvitationViewDelegate?, isTenantInvite: Bool = false) {
        self.invitationType = invitationType
        self.delegate = delegate
        self.isTenantInvite = isTenantInvite
        super.init(frame: .zero)

        self.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        bgTapGesture = self.lu.addTapGestureRecognizer(action: #selector(handTap))
        self.addSubview(inviteButton)
        self.addSubview(bottomSeperator)
        self.addSubview(inviteInputView)
        self.addSubview(inviteLabel)
        self.addSubview(inviteView)

        bottomSeperator.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(62)
            make.right.equalToSuperview().offset(-62)
            make.top.equalTo(inviteInputView.snp.bottom).offset(10)
            make.height.equalTo(1 / UIScreen.main.scale)
        }

        switch invitationType {
        case .mobile:
            self.addSubview(selectNumberLabel)

            let selectNumberLabelTapGesture = selectNumberLabel.lu.addTapGestureRecognizer(action: #selector(pushSelectNumber(sender:)), target: self)
            bgTapGesture?.shouldRequireFailure(of: selectNumberLabelTapGesture)
            selectNumberLabel.snp.makeConstraints { (make) in
                make.left.equalTo(bottomSeperator.snp.left)
                make.top.equalToSuperview().offset(44)
            }
            selectNumberLabel.sizeToFit()
            let selectNumberWidth = self.selectNumberLabel.bounds.width

            inviteInputView.keyboardType = .numberPad
            inviteInputView.attributedPlaceholder = NSAttributedString(
                string: BundleI18n.LarkContact.Lark_Legacy_PhoneNumber,
                attributes: [
                    .foregroundColor: UIColor.ud.N500,
                    .font: UIFont.systemFont(ofSize: 16)
                ]
            )

            inviteInputView.snp.makeConstraints { (make) in
                make.left.equalTo(bottomSeperator).offset(selectNumberWidth + 10)
                make.right.equalTo(bottomSeperator.snp.right)
                make.top.equalToSuperview().offset(44)
            }
        case .email:
            inviteInputView.attributedPlaceholder = NSAttributedString(
                string: BundleI18n.LarkContact.Lark_Legacy_EmailAddress,
                attributes: [
                    .foregroundColor: UIColor.ud.N500,
                    .font: UIFont.systemFont(ofSize: 16)
                ]
            )
            inviteInputView.snp.makeConstraints { (make) in
                make.left.equalTo(bottomSeperator.snp.left)
                make.right.equalTo(bottomSeperator.snp.right)
                make.top.equalToSuperview().offset(44)
            }
        case .unknown:
            break
        @unknown default:
            assert(false, "new value")
            break
        }

        inviteView.snp.makeConstraints { (make) in
            make.top.equalTo(bottomSeperator.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }

        inviteLabel.snp.makeConstraints { (make) in
            make.top.equalTo(inviteView.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(42)
        }

        inviteButton.snp.makeConstraints { (make) in
            make.height.equalTo(inviteButton.defaultHeight)
            make.top.equalTo(inviteLabel.snp.bottom).offset(24)
            make.right.equalToSuperview().offset(-52)
            make.left.equalToSuperview().offset(52)
        }

        setInviteStatus(inviteStatus)
    }

    func validateEmail(email: String) -> Bool {
        return InvitationView.emailPredicate.evaluate(with: email)
    }

    @objc
    func inviteAction() {
        switch inviteStatus {
        case .invite:
            guard let text = inviteInputView.text?.replacingOccurrences(of: "\\p{Cf}", with: "", options: .regularExpression) else { return }
            switch invitationType {
            case .mobile:
                let content = "\(countryNumber)\(text)"
                self.delegate?.invite(type: self.invitationType, content: content)
            case .email:
                if validateEmail(email: text) {
                    self.delegate?.invite(type: self.invitationType, content: text)
                } else {
                    UDToast.showTips(with: BundleI18n.LarkContact.Lark_Legacy_EnterValidEmail, on: self)
                }
            case .unknown:
                break
            @unknown default:
                assert(false, "new value")
                break
            }
        case .confirm:
            self.delegate?.popViewController()
        case .invited:
            break
        }
    }

    @objc
    func pushPersonCard() {
        self.delegate?.pushPersonCard()
    }

    @objc
    func pushSelectNumber(sender: UITapGestureRecognizer) {
        self.delegate?.pushSelectVC()
    }

    private func setInviteStatus(_ status: InviteStatus) {
        self.inviteView.removeFromSuperview()
        switch status {
        case .invite:
            let inviteImageView = UIImageView()
            inviteImageView.contentMode = .scaleAspectFit
            inviteImageView.image = Resources.invite
            inviteView = inviteImageView
            if self.isTenantInvite {
                switch invitationType {
                case .mobile:
                    inviteLabel.text = BundleI18n.LarkContact.Lark_UserGrowth_InviteTenantViaPhone
                case .email:
                    inviteLabel.text = BundleI18n.LarkContact.Lark_UserGrowth_InviteTenantViaEmail
                case .unknown:
                    break
                @unknown default:
                    assert(false, "new value")
                    break
                }
            } else {
                inviteLabel.text = BundleI18n.LarkContact.Lark_Legacy_InvitePartnersToLark()
            }
            inviteButton.setTitle(BundleI18n.LarkContact.Lark_Legacy_Invite, for: .normal)
            inviteButton.isHidden = false
        case .confirm:
            let inviteImageView = UIImageView()
            inviteImageView.contentMode = .scaleAspectFit
            inviteImageView.image = Resources.invited
            inviteView = inviteImageView
            switch invitationType {
            case .mobile:
                inviteLabel.text = BundleI18n.LarkContact.Lark_Legacy_InvitationIsSuccessfulOnPhone()
            case .email:
                inviteLabel.text = BundleI18n.LarkContact.Lark_Legacy_InvitationIsSuccessfulOnEmail()
            case .unknown:
                break
            @unknown default:
                assert(false, "new value")
                break
            }
            inviteButton.setTitle(BundleI18n.LarkContact.Lark_Legacy_ConfirmInfo, for: .normal)
            inviteButton.isHidden = false
        case .invited(let card):
            let invitationCardView = InvitationCardControl()
            invitationCardView.setInvitationCardView(entityId: card.entityId,
                                                     avatarKey: card.avatarKey,
                                                     displayName: card.displayName,
                                                     tenantName: card.tenantName)
            let invitationCardViewTapGesture = invitationCardView.lu.addTapGestureRecognizer(action: #selector(pushPersonCard), target: self)
            bgTapGesture?.shouldRequireFailure(of: invitationCardViewTapGesture)
            inviteView = invitationCardView
            inviteLabel.text = BundleI18n.LarkContact.Lark_Legacy_AlreadyHasLarkAccount()
            inviteButton.isHidden = true
        }
        self.addSubview(self.inviteView)
        inviteView.snp.remakeConstraints { (make) in
            make.top.equalTo(bottomSeperator.snp.bottom).offset(24)
            make.left.equalTo(bottomSeperator.snp.left)
            make.right.equalTo(bottomSeperator.snp.right)
            make.bottom.equalTo(inviteLabel.snp.top).offset(-8)
        }
    }

    func setCountry(number: String) {
        self.countryNumber = number
        self.layoutIfNeeded()
        let selectNumberWidth = self.selectNumberLabel.bounds.width
        inviteInputView.snp.remakeConstraints { (make) in
            make.left.equalTo(bottomSeperator).offset(selectNumberWidth + 10)
            make.right.equalTo(bottomSeperator.snp.right)
            make.top.equalToSuperview().offset(44)
        }
    }

    func setResult(isSuccess: Bool, entityId: String = "", avatarKey: String = "", displayName: String = "", tenantName: String = "") {
        if isSuccess {
            self.inviteStatus = .confirm
        } else {
            self.inviteStatus = .invited((entityId: entityId,
                                          avatarKey: avatarKey,
                                          displayName: displayName,
                                          tenantName: tenantName))
        }
    }

    func setContent(content: String) {
        self.inviteInputView.text = content
        inviteButton.isEnabled = !content.isEmpty
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension InvitationView: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        inviteInputView.becomeFirstResponder()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        inviteInputView.resignFirstResponder()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        inviteInputView.resignFirstResponder()
        return true
    }

    @objc
    func handTap(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            inviteInputView.resignFirstResponder()
        }
        sender.cancelsTouchesInView = false
    }

    @objc
    func textDidChange() {
        guard let text = inviteInputView.text else {
            return
        }
        if text.isEmpty {
            inviteButton.isEnabled = false
        } else {
            inviteButton.isEnabled = true
        }

        switch invitationType {
        case .mobile:
            if text.count > 20 {
                inviteInputView.text = String(text[0..<20])
            }
        case .email, .unknown:
            break
        @unknown default:
            assert(false, "new value")
            break
        }

        switch inviteStatus {
        case .invited, .confirm:
            inviteStatus = .invite
        case .invite:
            break
        }
    }
}
