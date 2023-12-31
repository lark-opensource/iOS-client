//
//  MailAlertContentView.swift
//  MailSDK
//
//  Created by Quanze Gao on 2022/9/6.
//

import Foundation
import UIKit
import LarkUIKit
import LarkAlertController
import EENavigator
import SkeletonView
import RxSwift
import UniverseDesignColor
import UniverseDesignDialog


enum MailAlertType {
    case spamAlert(_ isUnauthorized: Bool, _ trackContent: SpamTrackContent)
    case replyAlert
}

enum SpamAlertType {
    case markSpam
    case markNormal
    case conversationMoveToFolder(_ folder: String, _ labelID: String)

    var toSpam: Bool {
        switch self {
        case .markSpam: return true
        case .markNormal: return false
        case .conversationMoveToFolder(_, let labelID): return labelID == Mail_LabelId_Spam
        }
    }

    var isMoveAction: Bool {
        switch self {
        case .markSpam, .markNormal: return false
        case .conversationMoveToFolder: return true
        }
    }
}

final class MailAlertContentView: UIView {
    var isCheckboxSelected = false

    private let textView = ActionableTextView()
    private let checkbox = UIImageView(frame: .zero)
    private let checkboxTextView = ActionableTextView()
    private let type: MailAlertType
    private var trackContent: SpamTrackContent {
        get {
            switch self.type {
            case .replyAlert: return SpamTrackContent()
            case .spamAlert(_, let trackContent): return trackContent
            }
        }
    }

    init(type: MailAlertType, content: String, checkBoxStr: String, enableCheckbox: Bool) {
        self.type = type
        super.init(frame: .zero)

        let authInfo: (Bool, Bool) = {
            switch self.type {
            case .replyAlert: return (false, false)
            case .spamAlert(let isUnauthorized, _): return (true, isUnauthorized)
            }
        }()
        let shouldCheckAuth = authInfo.0
        let isUnauthorized = authInfo.1

        let alertWidth = LarkAlertController.Layout.dialogWidth
        let horizontalPadding: CGFloat = 20
        let maxAddressHeight: CGFloat = 260
        var addressesHeight = maxAddressHeight

        let sharedParagraphStyle = NSMutableParagraphStyle()
        sharedParagraphStyle.lineSpacing = 6

        let text = content + (shouldCheckAuth ? (isUnauthorized ? "" : " " + BundleI18n.MailSDK.Mail_SingularMoveToSpam_LearnMore_Button) : "")
        let attributedText = NSAttributedString(string: text, attributes: [.paragraphStyle: sharedParagraphStyle])
        textView.attributedText = attributedText
        textView.textColor = .ud.textTitle
        textView.textContainerInset = .zero
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        if !isUnauthorized && shouldCheckAuth {
            configLink(for: textView)
        }

        textView.font = .systemFont(ofSize: 16)
        let textHeight = textView.sizeThatFits(
            CGSize(width: alertWidth - horizontalPadding * 2, height: .greatestFiniteMagnitude)
        ).height
        addSubview(textView)
        textView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.lessThanOrEqualTo(textHeight)
        }

        checkbox.image = Resources.mail_cell_option
        updateCheckBox()
        if enableCheckbox {
            checkbox.isUserInteractionEnabled = true
            let checkboxTap = UITapGestureRecognizer(target: self, action: #selector(tapCheckBox))
            checkbox.addGestureRecognizer(checkboxTap)
        }
        addSubview(checkbox)
        checkbox.snp.makeConstraints { make in
            make.top.equalTo(textView.snp.bottom).offset(20)
            make.left.equalToSuperview()
            make.height.width.equalTo(18)
        }

        sharedParagraphStyle.lineSpacing = 2
        var checkBoxStr = checkBoxStr + (!isUnauthorized ? "" : " " + BundleI18n.MailSDK.Mail_SingularMoveToSpam_LearnMore_Button)
        var checkboxAttribuedStr = NSMutableAttributedString(string: checkBoxStr,
                                                             attributes: [.paragraphStyle: sharedParagraphStyle,
                                                                          .foregroundColor: UIColor.ud.textTitle
                                                                         ])
        let range = (checkBoxStr as NSString).range(of: BundleI18n.MailSDK.Mail_UnverifiedSingualrMarkSpamNotice_Checkbox)
        if range.location != NSNotFound {
            checkboxAttribuedStr.addAttributes([.foregroundColor: UIColor.ud.textCaption], range: range)
        }
        checkboxTextView.attributedText = checkboxAttribuedStr
        checkboxTextView.font = .systemFont(ofSize: 14)
        checkboxTextView.isUserInteractionEnabled = true
        checkboxTextView.isScrollEnabled = false
        checkboxTextView.textContainerInset = .zero
        checkboxTextView.backgroundColor = .clear
        if isUnauthorized && shouldCheckAuth {
            configLink(for: checkboxTextView)
        } else {
            let labelTap = UITapGestureRecognizer(target: self, action: #selector(tapCheckBox))
            checkboxTextView.addGestureRecognizer(labelTap)
        }
        let labelHeight = checkboxTextView.sizeThatFits(
            CGSize(width: alertWidth - horizontalPadding * 2 - 26, height: .greatestFiniteMagnitude)
        ).height
        let greaterThanOneLine = labelHeight > (UIFont.systemFont(ofSize: 14).lineHeight + 2)
        addSubview(checkboxTextView)
        checkboxTextView.snp.makeConstraints { make in
            make.top.equalTo(checkbox.snp.top)
            if !greaterThanOneLine {
                make.bottom.equalToSuperview().offset(-6).priority(.medium)
                make.centerY.equalTo(checkbox.snp.centerY).priority(.required)
            } else {
                make.bottom.equalToSuperview().offset(-6)
            }
            make.left.equalTo(checkbox.snp.right).offset(8)
            make.right.equalToSuperview().offset(-20)
        }

        trackView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func tapCheckBox() {
        isCheckboxSelected.toggle()
        updateCheckBox()
    }

    private func updateCheckBox() {
        checkbox.image = isCheckboxSelected ? Resources.mail_cell_option_selected : Resources.mail_cell_option
        if isCheckboxSelected {
            checkbox.backgroundColor = UIColor.ud.primaryContentDefault
            checkbox.layer.cornerRadius = 10
            checkbox.clipsToBounds = true
        } else {
            checkbox.backgroundColor = UIColor.clear
            checkbox.layer.cornerRadius = 0
            checkbox.clipsToBounds = false
        }
    }
    
    private func configLink(for textView: ActionableTextView) {
        textView.actionTextColor = .ud.textLinkNormal
        textView.actionableText = BundleI18n.MailSDK.Mail_SingularMoveToSpam_LearnMore_Button
        textView.action = { [weak self] in
            guard let self = self else { return }
            if let urlString = ProviderManager.default.commonSettingProvider?.stringValue(key: "spamMailPolicy"), let url = URL(string: urlString) {
                MailLogger.info("[Spam] Click spam help page")
                UIApplication.shared.open(url)
            } else {
                MailLogger.error("[Spam] Failed to get spam help page url")
            }
            self.trackClick()
        }
        textView.updateAttributes()
    }
    
    private func trackView() {
        switch self.type {
        case .replyAlert: break
        case .spamAlert(_, _):
            let name = trackContent.isToSpam ? "email_spam_toast_view" : "email_not_spam_toast_view"
            MailTracker.log(
                event: name,
                params: [
                    "label_item": trackContent.fromLabelID,
                    "toast_type": trackContent.toastType
                ]
            )
        }
    }

    private func trackClick() {
        let name = trackContent.isToSpam ? "email_spam_toast_click" : "email_not_spam_toast_click"
        MailTracker.log(
            event: name,
            params: [
                "label_item": trackContent.fromLabelID,
                "toast_type": trackContent.toastType,
                "click": "more_detail"
            ]
        )
    }
}

struct SpamAlertContent {
    enum Scene {
        case thread
        case search
        case message
    }
    var threadIDs: [String] = []
    var fromLabelID = ""
    var mailAddresses: [String] = []
    var unauthorizedAddresses: [String] = []
    var isFromMessageList: Bool = false
    var isAllAuthorized = false
    var shouldFetchUnauthorized = true
    var scene: Scene = .thread
    var allInnerDomain: Bool = false
}

struct SpamTrackContent {
    var fromLabelID = ""
    var isSuspicious = false
    var isToSpam = false

    var toastType: String {
        isSuspicious ? "dubious_sender" : "spam_mail"
    }
}

/// 文案逻辑 https://bytedance.feishu.cn/docx/doxcn2wyaZMkRSVZp91dPU8lnLh
extension LarkAlertController {
    static func showSpamAlert(
        type: SpamAlertType,
        content: SpamAlertContent,
        from: NavigatorFrom,
        navigator: Navigatable,
        userStore: MailKVStore,
        action: @escaping (Bool) -> Void
    ) {

        if Store.settingData.mailClient
            || !FeatureManager.open(.newSpamPolicy)
            || (userStore.bool(forKey: "MailSpamAlert.dontShowAlert") && content.isAllAuthorized) {
            action(false)
        } else {
            typealias i18n = BundleI18n.MailSDK
            let isConversationMode = Store.settingData.getCachedCurrentSetting()?.enableConversationMode == true
            let currentAccount = Store.settingData.currentAccount.value?.accountAddress
            var mailAddresses = content.mailAddresses.unique.filter({ $0 != currentAccount })
            let unauthorizedAddresses = content.unauthorizedAddresses.unique.filter({ $0 != currentAccount })

            var title: String = ""
            var desc: String = ""
            var actionTitle: String = ""
            var enableCheckbox = true
            var checkBoxStr = i18n.Mail_SingularMoveToSpam_NoRemind_Button
            var trackContent = SpamTrackContent(fromLabelID: content.fromLabelID, isToSpam: type.toSpam)
            var layoutConfig = UDDialogUIConfig()

            switch type {
            case .markSpam:
                title = i18n.Mail_MarkSpam_Tittle
                actionTitle = i18n.Mail_SingularMoveToSpam_Mark_Button
            case .markNormal:
                title = i18n.Mail_NotSpam_Title
                actionTitle = i18n.Email_UnmarkSpamSuspiciousEmailSingular_Title
                layoutConfig.style = .vertical
            case .conversationMoveToFolder(let folder, let labelID):
                if labelID == Mail_LabelId_Spam {
                    title = i18n.Mail_MovetoSpam_Title
                } else {
                    title = i18n.Mail_MovetoFolder_Title(folder)
                }
                actionTitle = i18n.Mail_MovetoFolderConfirm_Button
            }

            /// 正常发件人描述
            func __updateDesc(mailAddresses: [String]) {
                guard !mailAddresses.isEmpty else { return }
                var addressesStr = addressesString(from: Array(mailAddresses[0...min(1, mailAddresses.count - 1)]))
                if type.toSpam {
                    if mailAddresses.count <= 1 {
                        if content.isFromMessageList && isConversationMode {
                            desc = i18n.Mail_PluralConversationMoveToSpam_IOS_Desc1(addressesStr)
                        } else if content.isFromMessageList {
                            desc = i18n.Mail_SingularMoveToSpam_Desc(addressesStr)
                        } else {
                            desc = i18n.Mail_PluralMessagesMoveToSpam_IOS_Desc1(addressesStr)
                        }
                    } else {
                        if content.isFromMessageList && isConversationMode {
                            desc = i18n.Mail_PluralConversationMoveToSpam_IOS_Desc2(mailAddresses.count, addressesStr)
                        } else {
                            desc = i18n.Mail_PluralMessagesMoveToSpam_IOS_Desc2(mailAddresses.count, addressesStr)
                        }
                    }
                } else {
                    if mailAddresses.count <= 1 {
                        desc = i18n.Mail_PluralNotSpam_IOS_Desc1(addressesStr)
                    } else {
                        desc = i18n.Mail_PluralNotSpam_IOS_Desc2(mailAddresses.count, addressesStr)
                    }
                }
            }

            /// 未认证发件人描述
            func __updateDesc(unauthorizedAddresses: [String]?) {
                if let unauthorizedAddresses = unauthorizedAddresses, unauthorizedAddresses.count > 0 {
                    let address1 = unauthorizedAddresses[0]
                    if unauthorizedAddresses.count > 1 {
                        let address2 = unauthorizedAddresses[1]
                        desc = type.toSpam
                        ? type.isMoveAction ? i18n.Mail_UnverifiedPluralMoveToSpam_Desc : i18n.Mail_UnverifiedPluralMarkSpam_Desc
                        : i18n.Mail_UnverifiedPluralNotSpam_Desc
                        checkBoxStr = type.toSpam
                        ? i18n.Mail_UnverifiedPluralMarkSpamSendFuture_Checkbox(unauthorizedAddresses.count, address1, address2, "")
                        : i18n.Mail_UnverifiedPluralNotSpam_Checkbox(unauthorizedAddresses.count, address1, address2)
                    } else {
                        desc = type.toSpam
                        ? type.isMoveAction ? i18n.Mail_UnverifiedSingularMoveToSpam_Desc : i18n.Mail_UnverifiedSingualrMarkSpam_Desc
                        : i18n.Email_UnmarkSpamSuspiciousEmailSingular_IOS_Description1(address1)
                        checkBoxStr = type.toSpam
                        ? i18n.Mail_UnverifiedSingualrMarkSpamSendFuture_Checkbox(address1, "")
                        : i18n.Email_UnmarkSpamSuspiciousEmailSingularFutureAction_Description(address1)
                    }
                    trackContent.isSuspicious = true
                } else {
                    desc = type.toSpam ? i18n.Mail_UnverifiedSingualrMarkSpam_Desc : i18n.Mail_UnverifiedSingularUnmarkSpamUnknown_Desc
                    checkBoxStr = type.toSpam ? i18n.Mail_UnverifiedSingualrMarkSpamSendFutureUnknown_Checkbox("") : i18n.Mail_DonotSendFutureToSpamFallBack_checkbox
                }
            }
            // 黑白名单二期
            let v2FG = FeatureManager.open(.blockSender, openInMailClient: false)
            
            if (!content.shouldFetchUnauthorized && !v2FG) ||
                (v2FG && (content.scene == .message || content.scene == .search)) {
                let needUpdateUnauth = !v2FG && !content.allInnerDomain
                if needUpdateUnauth {
                    __updateDesc(mailAddresses: mailAddresses)
                } else {
                    // address + unauthorizedAddresses
                    for unauth in unauthorizedAddresses where !mailAddresses.contains(unauth) {
                        mailAddresses.append(unauth)
                    }
                    __updateDesc(mailAddresses: mailAddresses)
                }
                if needUpdateUnauth {
                    __updateDesc(unauthorizedAddresses: unauthorizedAddresses)
                }
                // 完全不弹框的场景
                let v1Logic = !v2FG && mailAddresses.isEmpty && unauthorizedAddresses.isEmpty
                let allInner = v2FG && content.allInnerDomain
                if v1Logic || allInner {
                    action(false)
                } else {
                    var hasUnauthorized = !unauthorizedAddresses.isEmpty
                    if v2FG {
                        // 二期不弹 未经身份认证 那个弹框
                        hasUnauthorized = false
                    }
                    showAlert(title: title, content: desc, actionTitle: actionTitle, checkBoxStr: checkBoxStr, hasUnauthorized:hasUnauthorized, enableCheckbox: enableCheckbox, trackContent: trackContent, from: from, navigator: navigator, userStore: userStore, config: layoutConfig, action: action)
                }
            } else {
                MailDataServiceFactory.commonDataService?.getThreadsAddresses(threadIDs: content.threadIDs, fromLabel: content.fromLabelID, onlyUnauthorized: !content.isAllAuthorized)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { addresses in
                        var mailAddresses = addresses
                        let onlyHasSelf = mailAddresses.filter({ $0.0 != currentAccount }).isEmpty
                        if !content.isAllAuthorized {
                            if !onlyHasSelf {
                                mailAddresses = mailAddresses.filter({ $0.0 != currentAccount })
                            } else if type.toSpam && !addresses.isEmpty {
                                /// 未认证邮箱只有自己时， 显示自己地址，如果是加黑时禁止 checkbox
                                enableCheckbox = false
                            }
                            if !v2FG {
                                __updateDesc(unauthorizedAddresses: mailAddresses.map({$0.0}))
                            } else {
                                mailAddresses = mailAddresses.filter({ $0.0 != currentAccount })
                                __updateDesc(mailAddresses: mailAddresses.map({$0.0}))
                            }
                        } else {
                            if onlyHasSelf {
                                action(false)
                                return
                            } else {
                                mailAddresses = mailAddresses.filter({ $0.0 != currentAccount })
                                __updateDesc(mailAddresses: mailAddresses.map({$0.0}))
                            }
                        }
                        let hasExtern = mailAddresses.contains(where: { $0.1 == true })
                        // 二期开关打开的情况下，没有外部地址不弹框
                        if (v2FG && !hasExtern) {
                            action(false)
                            return
                        }
                        var hasUnauthorized = !content.isAllAuthorized
                        if v2FG {
                            hasUnauthorized = false
                        }
                        showAlert(title: title, content: desc, actionTitle: actionTitle, checkBoxStr: checkBoxStr, hasUnauthorized:hasUnauthorized, enableCheckbox: enableCheckbox, trackContent: trackContent, from: from, navigator: navigator, userStore: userStore, config: layoutConfig, action: action)
                    }) { _ in
                        if !content.isAllAuthorized && !v2FG {
                            __updateDesc(unauthorizedAddresses: nil)
                        }
                        var hasUnauthorized = !content.isAllAuthorized
                        if v2FG {
                            hasUnauthorized = false
                        }
                        showAlert(title: title, content: desc, actionTitle: actionTitle, checkBoxStr: checkBoxStr, hasUnauthorized: hasUnauthorized, enableCheckbox: enableCheckbox, trackContent: trackContent, from: from, navigator: navigator, userStore: userStore, config: layoutConfig, action: action)
                    }
            }
        }
    }

    static func showReplyAlert(
        from: NavigatorFrom,
        navigator: Navigatable,
        userStore: MailKVStore,
        action: @escaping (Bool) -> Void
    ) {
        let alert = LarkAlertController()
        alert.setTitle(text: BundleI18n.MailSDK.Mail_StrangerMail_ReplyToStrangerNotice_Title)
        let content = BundleI18n.MailSDK.Mail_StrangerMail_ReplyToStrangerNotice_Desc
        let contentView = MailAlertContentView(type: .replyAlert, content: content, checkBoxStr: BundleI18n.MailSDK.Mail_StrangerMail_ReplyToStranger_DontRemind_Checkbox, enableCheckbox: true)
        alert.setContent(view: contentView)
        alert.addButton(text: BundleI18n.MailSDK.Mail_StrangerMail_ReplyToStrangerNotice_Cancel, color: UIColor.ud.textTitle, dismissCompletion:  {
            action(false)
        })
        alert.addButton(text: BundleI18n.MailSDK.Mail_StrangerMail_ReplyToStrangerNotice_Reply, dismissCompletion:  {
            let selected = contentView.isCheckboxSelected
            if selected {
                userStore.set(true, forKey: "MailStrangerReplyAlert.dontShowAlert")
            }
            action(true)
        })
        navigator.present(alert, from: from)
    }

    static func showStrangerReadReceiptAlert(
        from: NavigatorFrom,
        labelItem: String,
        navigator: Navigatable,
        userStore: MailKVStore,
        action: @escaping (Bool) -> Void
    ) {
        let alert = LarkAlertController()
        alert.setTitle(text: BundleI18n.MailSDK.Mail_ReadReceipt_SendReadReceiptConfirmation_Title)
        let content = BundleI18n.MailSDK.Mail_ReadReceipt_SendReadReceiptConfirmation_Desc
        let contentView = MailAlertContentView(type: .replyAlert, content: content, checkBoxStr: BundleI18n.MailSDK.Mail_ReadReceipt_SendReadReceiptConfirmation_DontRemindAgagin, enableCheckbox: true)
        alert.setContent(view: contentView)
        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_ReadReceipt_SendReadReceiptConfirmation_Cancel, dismissCompletion: {
            MailTracker.log(event: "email_stranger_read_receipt_window_click",
                            params: ["click": "cancel",
                                     "not_remind": contentView.isCheckboxSelected ? "True" : "False",
                                     "label_item": labelItem,
                                     "mail_account_type": Store.settingData.getMailAccountType()])
            action(false)
        })
        alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ReadReceipt_SendReadReceiptConfirmation_Send, dismissCompletion: {
            let selected = contentView.isCheckboxSelected
            if selected {
                userStore.set(true, forKey: "MailReadReceipt.StrangerAlert.dontShowAlert")
            }
            MailTracker.log(event: "email_stranger_read_receipt_window_click",
                            params: ["click": "send",
                                     "not_remind": selected ? "True" : "False",
                                     "label_item": labelItem,
                                     "mail_account_type": Store.settingData.getMailAccountType()])
            action(true)
        })
        navigator.present(alert, from: from)
    }

    private static func showAlert(
        title: String,
        content: String,
        actionTitle: String,
        checkBoxStr: String,
        hasUnauthorized: Bool,
        enableCheckbox: Bool,
        trackContent: SpamTrackContent,
        from: NavigatorFrom,
        navigator: Navigatable,
        userStore: MailKVStore,
        config: UDDialogUIConfig,
        action: @escaping (Bool) -> Void
    ) {
        guard !content.isEmpty else {
            action(false)
            return
        }
        let alert = LarkAlertController(config: config)
        alert.setTitle(text: title)
        var checkBoxStr = checkBoxStr == BundleI18n.MailSDK.Mail_SingularMoveToSpam_NoRemind_Button || !enableCheckbox || !trackContent.isToSpam ? checkBoxStr : checkBoxStr + " " + BundleI18n.MailSDK.Mail_UnverifiedSingualrMarkSpamNotice_Checkbox
        let contentView = MailAlertContentView(type: .spamAlert(hasUnauthorized, trackContent), content: content, checkBoxStr: checkBoxStr, enableCheckbox: enableCheckbox)
        alert.setContent(view: contentView)
        if config.style != .vertical {
            alert.addCancelButton(dismissCompletion: {
                Self.trackClick(content: trackContent, isCancelled: true)
            })
        }
        alert.addPrimaryButton(text: actionTitle, numberOfLines: 2, dismissCompletion: {
            let selected = contentView.isCheckboxSelected
            if !hasUnauthorized {
                if selected {
                    userStore.set(true, forKey: "MailSpamAlert.dontShowAlert")
                }
                action(false)
            } else {
                action(selected)
            }
            Self.trackClick(content: trackContent, isCancelled: false)
        })
        if config.style == .vertical {
            alert.addCancelButton(dismissCompletion:  {
                Self.trackClick(content: trackContent, isCancelled: true)
            })
        }
        navigator.present(alert, from: from)
    }

    private static func trackClick(content: SpamTrackContent, isCancelled: Bool) {
        let name = content.isToSpam ? "email_spam_toast_click" : "email_not_spam_toast_click"
        MailTracker.log(
            event: name,
            params: [
                "label_item": content.fromLabelID,
                "toast_type": content.toastType,
                "click": isCancelled ? "cancel" : "confirm"
            ]
        )
    }

    private static func addressesString(from addresses: [String]) -> String {
        guard !addresses.isEmpty else { return "" }
        var str = addresses.unique.reduce("", { $0 + $1 + BundleI18n.MailSDK.Email_Common_ChineseComma })
        str.removeLast()
        return str
    }
}
