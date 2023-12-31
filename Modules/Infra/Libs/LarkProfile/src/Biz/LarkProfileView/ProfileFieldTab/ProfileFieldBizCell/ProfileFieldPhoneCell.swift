//
//  ProfileFieldPhoneCell.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/7/7.
//

import UIKit
import Foundation
import UniverseDesignButton
import LarkContainer
import LarkMessengerInterface
import LarkSDKInterface
import LarkAlertController
import EENavigator
import UniverseDesignToast
import LarkFeatureGating
import LarkFoundation
import UniverseDesignActionPanel
import LarkBizAvatar
import UniverseDesignDialog

public final class ProfileFieldPhoneNumberItem: ProfileFieldItem {
    public var enableLongPress: Bool = true

    public var type: ProfileFieldType

    public var fieldKey: String

    public var title: String

    public var contentText: String

    public var phoneNumber: String

    public var countryCode: String

    public var avatarKey: String

    public var aliasName: String
    public var userName: String

    public var departmentName: String

    public var tenantName: String

    public var isPlain: Bool
    public var userID: String

    public init(type: ProfileFieldType = .normal,
                fieldKey: String = "",
                title: String = "",
                contentText: String = "",
                userID: String,
                phoneNumber: String,
                countryCode: String,
                avatarKey: String,
                aliasName: String,
                userName: String,
                tenantName: String,
                departmentName: String,
                isPlain: Bool) {
        self.type = type
        self.fieldKey = fieldKey
        self.title = title
        self.userID = userID
        self.contentText = contentText
        self.phoneNumber = phoneNumber
        self.countryCode = countryCode
        self.avatarKey = avatarKey
        self.aliasName = aliasName
        self.userName = userName
        self.tenantName = tenantName
        self.departmentName = departmentName
        self.isPlain = isPlain
    }
}

extension ProfileFieldPhoneNumberItem {
    func getDisplayName() -> String {
        return aliasName.isEmpty ? userName : aliasName
    }
}

public final class ProfileFieldPhoneCell: ProfileFieldCell {

    var callRequestService: CallRequestService?
    var chatterAPI: ChatterAPI?
    var profileContactUtil: ProfileContactSaveUtil?
    var userResolver: UserResolver? //Global 误报，cell初始化调用由UIKit调用，不太方便从init方法传入
    let bizAvatarView = BizAvatar()
    var saveToContactsFG: Bool = true

    private lazy var phoneWrapperView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        return stack
    }()

    private var responseNumber: String = ""

    private lazy var phoneLabel: UILabel = {
        let phoneLabel = UILabel()
        phoneLabel.numberOfLines = 1
        phoneLabel.font = Cons.contentFont
        phoneLabel.textColor = Cons.contentColor
        phoneLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return phoneLabel
    }()

    private lazy var showButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = Cons.contentFont
        button.setTitleColor(Cons.linkColor, for: .normal)
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return button
    }()

    private lazy var spaceView: UIView = {
        let spaceView = UIView()
        spaceView.snp.makeConstraints { make in
            make.width.equalTo(10)
        }
        spaceView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return spaceView
    }()

    public override class func canHandle(item: ProfileFieldItem) -> Bool {
        guard let cellItem = item as? ProfileFieldPhoneNumberItem else {
            return false
        }
        return cellItem.type == .normal
    }

    override func commonInit() {
        super.commonInit()

        stackView.distribution = .fill

        let paddingView = UIView()
        paddingView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        paddingView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        phoneLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        showButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        stackView.addArrangedSubview(phoneWrapperView)
        if isVerticalLayout {
            phoneWrapperView.semanticContentAttribute = .forceLeftToRight
            phoneWrapperView.addArrangedSubview(phoneLabel)
            phoneWrapperView.addArrangedSubview(spaceView)
            phoneWrapperView.addArrangedSubview(showButton)
            phoneWrapperView.addArrangedSubview(paddingView)
        } else {
            phoneWrapperView.semanticContentAttribute = .forceRightToLeft
            phoneWrapperView.addArrangedSubview(showButton)
            phoneWrapperView.addArrangedSubview(spaceView)
            phoneWrapperView.addArrangedSubview(phoneLabel)
            phoneWrapperView.addArrangedSubview(paddingView)
        }

        phoneWrapperView.snp.makeConstraints { make in
            make.height.equalTo(Cons.contentLineHeight)
        }

        guard let phoneItem = self.item as? ProfileFieldPhoneNumberItem else {
            return
        }

        // 自己的Profile页直接显示完整电话号码
        if phoneItem.isPlain {
            self.hideButton()
            phoneLabel.textColor = Cons.linkColor
        }
        phoneLabel.text = phoneItem.phoneNumber
        showButton.setTitle(phoneItem.contentText, for: .normal)
        showButton.addTarget(self, action: #selector(tapShowHandler), for: .touchUpInside)
    }

    @objc
    func tapShowHandler() {
        guard let phoneItem = self.item as? ProfileFieldPhoneNumberItem,
              let fromVC = self.context.fromVC else {
            return
        }

        let alertController = UDDialog()
        alertController.setContent(text: BundleI18n.LarkProfile.Lark_Profile_PhoneV7)
        alertController.addCancelButton()
        alertController.addPrimaryButton(text: BundleI18n.LarkProfile.Lark_Profile_PhoneV9, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.callRequestService?.showPhoneNumber(chatterId: phoneItem.userID, from: fromVC, callBack: self.showCompleteNumber(_:))
        })
        self.navigator?.present(alertController, from: fromVC)
    }

    public override func didTap() {
        super.didTap()

        guard let phoneItem = self.item as? ProfileFieldPhoneNumberItem else {
            return
        }

        guard let fromVC = self.context.fromVC else {
            assertionFailure()
            return
        }
        
        if saveToContactsFG {
            bizAvatarView.setAvatarByIdentifier(phoneItem.userID, avatarKey: phoneItem.avatarKey)
            if showButton.isHidden {
                if phoneItem.userID.isEmpty {
                    let phone = phoneItem.phoneNumber.replacingOccurrences(of: "-", with: "")
                    self.telecall(phoneNumber: phone)
                    return
                }
                let config = UDActionSheetUIConfig(isShowTitle: false)
                let actionSheet = UDActionSheet(config: config)
                actionSheet.addDefaultItem(text: BundleI18n.LarkProfile.Lark_Legacy_LarkCall) {
                    let number = phoneItem.phoneNumber.replacingOccurrences(of: "-", with: "")
                    LarkFoundation.Utils.telecall(phoneNumber: number)
                }
                actionSheet.addDefaultItem(text: BundleI18n.LarkProfile.Lark_Core_AddToPhoneContacts_Button) { [weak self] in
                    guard let self = self else { return }
                    self.showContactActionSheet(fromVC: fromVC, phoneItem: phoneItem)
                }
                actionSheet.setCancelItem(text: BundleI18n.LarkProfile.Lark_Core_AddToPhoneContacts_Cancel_Button)
                /// 弹出 actionSheet
                self.navigator?.present(actionSheet, from: fromVC)
            }
        } else {
            if showButton.isHidden, !phoneItem.isPlain {
                responseNumber = responseNumber.replacingOccurrences(of: "-", with: "")
                UDToast.showTips(with: BundleI18n.LarkProfile.Lark_Legacy_ChatViewNotifyOtherCall, on: fromVC.view)
                self.telecall(phoneNumber: responseNumber)
            } else {
                if phoneItem.userID.isEmpty {
                    let phone = phoneItem.phoneNumber.replacingOccurrences(of: "-", with: "")
                    self.telecall(phoneNumber: phone)
                    return
                }

                let alertController = UDDialog()
                alertController.setContent(text: BundleI18n.LarkProfile.Lark_Profile_PhoneV10)
                alertController.addCancelButton()
                alertController.addPrimaryButton(text: BundleI18n.LarkProfile.Lark_Profile_PhoneV12, dismissCompletion: { [weak self] in
                    guard let self = self else { return }
                    self.callRequestService?.callByPhone(chatterId: phoneItem.userID, from: fromVC, callBack: self.showCompleteNumber(_:))
                })
                self.navigator?.present(alertController, from: fromVC)
            }
        }
    }

    private func showCompleteNumber(_ number: String) {
        guard let phoneItem = self.item as? ProfileFieldPhoneNumberItem else {
            return
        }

        if !number.isEmpty {
            self.hideButton()
            phoneLabel.text = number
            phoneLabel.textColor = UIColor.ud.textLinkNormal
            responseNumber = number
            phoneItem.isPlain = true
            phoneItem.phoneNumber = number
        }
    }
    
    private func showContactActionSheet(fromVC: UIViewController, phoneItem: ProfileFieldPhoneNumberItem) {
        let config = UDActionSheetUIConfig(isShowTitle: false)
        let actionSheet = UDActionSheet(config: config)
        profileContactUtil = ProfileContactSaveUtil(phoneItem: phoneItem, fromVC: fromVC, image: bizAvatarView.image)
        actionSheet.addDefaultItem(text: BundleI18n.LarkProfile.Lark_Core_AddToPhoneContacts_CreateNew_Button){ [weak self] in
            self?.profileContactUtil?.createContact()
        }
        actionSheet.addDefaultItem(text: BundleI18n.LarkProfile.Lark_Core_AddToPhoneContacts_Existing_Button){ [weak self] in
            self?.profileContactUtil?.pickerContact()
        }
        actionSheet.setCancelItem(text: BundleI18n.LarkProfile.Lark_Core_AddToPhoneContacts_Cancel_Button)
        /// 弹出 actionSheet
        self.navigator?.present(actionSheet, from: fromVC)
    }

    public override func longPressHandle() {
        guard self.item as? ProfileFieldPhoneNumberItem != nil else {
            return
        }
        // 如果电话号码显示完整，才支持长按复制
        if showButton.isHidden {
            guard let phoneText = phoneLabel.text else { return }
            if ProfilePasteboardUtil.pasteboardPersonalItemInfo(text: phoneText) {
                if let window = self.context.fromVC?.view.window {
                    UDToast.showSuccess(with: BundleI18n.LarkProfile.Lark_Legacy_Copied, on: window)
                }
            } else {
                if let window = self.context.fromVC?.view.window {
                    UDToast.showFailure(with: BundleI18n.LarkProfile.Lark_IM_CopyContent_CopyingIsForbidden_Toast, on: window)
                }
            }
        }
    }

    private func hideButton() {
        showButton.isHidden = true
        spaceView.isHidden = true
    }

    func telecall(phoneNumber: String) {
        let responseNumber = phoneNumber.replacingOccurrences(of: "-", with: "")
        LarkFoundation.Utils.telecall(phoneNumber: responseNumber)
    }
}
