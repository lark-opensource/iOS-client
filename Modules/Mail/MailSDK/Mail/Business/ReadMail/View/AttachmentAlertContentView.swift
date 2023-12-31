//
//  AttachmentAlertContentView.swift
//  MailSDK
//
//  Created by ByteDance on 2023/6/8.
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
import UniverseDesignIcon

final class AttachmentAlertContentView: UIView {
    var isCheckboxSelected = false

    private var textView = ActionableTextView()
    private let checkbox = UIImageView(frame: .zero)
    private let checkboxTextView = ActionableTextView()

    init(accountContext: MailAccountContext, from: UIViewController, alert: LarkAlertController, navigator: Navigatable, limitSize: String) {
        super.init(frame: .zero)
        textView = ActionableTextView.alertWithLinkTextView(text: BundleI18n.MailSDK.Mail_Shared_FilesUploadedAsLargeAttachments_Desc(16, limitSize, BundleI18n.MailSDK.Mail_Shared_Settings_LargeAttachmentStorage_Title), actionableText: BundleI18n.MailSDK.Mail_Shared_Settings_LargeAttachmentStorage_Title) {
            // 跳转附件管理页面
            
//            navi.view.backgroundColor = UIColor.ud.bgMask
            let vc = MailAttachmentsManagerViewController(accountContext: accountContext, accountID: accountContext.accountID, transferFolderKey: "")
            let navi = attachmentAlertNavi(rootViewController: vc)
            navi.modalPresentationStyle = .overFullScreen
            let event = NewCoreEvent(event: .email_large_attachment_alert_click)
            event.params = ["mail_account_type":Store.settingData.getMailAccountType(),
                            "click":"manage_attachment"]
            event.post()
            navigator.present(navi, from:alert)
        }
        let alertWidth = LarkAlertController.Layout.dialogWidth
        let horizontalPadding: CGFloat = 20
        let maxAddressHeight: CGFloat = 200
        let sharedParagraphStyle = NSMutableParagraphStyle()
        sharedParagraphStyle.lineSpacing = 6
                
        let textHeight = textView.sizeThatFits(
            CGSize(width: alertWidth - horizontalPadding * 2, height: .greatestFiniteMagnitude)
        ).height
        addSubview(textView)
        textView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(-12)
            make.left.right.equalToSuperview()
            make.height.lessThanOrEqualTo(textHeight)
        }

        checkbox.image = Resources.mail_cell_option
        updateCheckBox()
        checkbox.isUserInteractionEnabled = true
        let checkboxTap = UITapGestureRecognizer(target: self, action: #selector(tapCheckBox))
        checkbox.addGestureRecognizer(checkboxTap)
        addSubview(checkbox)
        checkbox.snp.makeConstraints { make in
            make.top.equalTo(textView.snp.bottom).offset(12)
            make.left.equalTo(textView).offset(4)
            make.height.width.equalTo(18)
        }

        sharedParagraphStyle.lineSpacing = 2
        let checkBoxStr = BundleI18n.MailSDK.Mail_Shared_FilesUploadedAsLargeAttachments_NoAlert
        var checkboxAttribuedStr = NSMutableAttributedString(string: checkBoxStr,
                                                             attributes: [.paragraphStyle: sharedParagraphStyle,.foregroundColor: UIColor.ud.textTitle])
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
        
        let labelTap = UITapGestureRecognizer(target: self, action: #selector(tapCheckBox))
        checkboxTextView.addGestureRecognizer(labelTap)
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
            make.left.equalTo(checkbox.snp.right).offset(4)
            make.right.equalToSuperview().offset(-20)
        }
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
}


extension LarkAlertController: UINavigationControllerDelegate{
    static func showAttachmentAlert(
        accountContext: MailAccountContext,
        from: UIViewController,
        navigator: Navigatable,
        limitSize: String,
        userStore: MailKVStore,
        action: @escaping () -> Void
    ) {
        if userStore.bool(forKey: "MailAttachmentAlert.dontShowAlert") {
            action()
        } else {
            let alert = LarkAlertController()
            alert.setTitle(text: BundleI18n.MailSDK.Mail_Shared_FilesUploadedAsLargeAttachments_NoticeTitle(17))
            let contentView = AttachmentAlertContentView(accountContext: accountContext, from: from, alert: alert, navigator: navigator, limitSize: limitSize)
            alert.setContent(view: contentView)
            alert.addCancelButton {
                let event = NewCoreEvent(event: .email_large_attachment_alert_click)
                event.params = ["mail_account_type":Store.settingData.getMailAccountType(),
                                "click":"cancel"]
                event.post()
            }
            let actionTitle = BundleI18n.MailSDK.Mail_Shared_FilesUploadedAsLargeAttachment_Upload
            alert.addButton(text: actionTitle, color: .ud.primaryContentDefault, numberOfLines: 2, dismissCompletion:  {
                let selected = contentView.isCheckboxSelected
                if selected {
                    userStore.set(true, forKey: "MailAttachmentAlert.dontShowAlert")
                }
                action()
                let event = NewCoreEvent(event: .email_large_attachment_alert_click)
                event.params = ["mail_account_type":Store.settingData.getMailAccountType(),
                                "click":"continue_upload"]
                event.post()
            })
            navigator.present(alert, from: from)
        }
    }
        
}

class attachmentAlertNavi: MailNavigationController {
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        navigationController.navigationBar.barTintColor = toVC.view.backgroundColor
        return nil
    }
    
    override func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        guard self.isNavigationBarHidden == false else {
            // 隐藏导航栏时不配置颜色，防止侧滑返回时下层调用，导致导航栏颜色跳变
            return
        }
        self.navigationBar.barTintColor = viewController.view.backgroundColor
        self.navigationBar.isTranslucent = false
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = viewController.view.backgroundColor
            if let bgColor = viewController.view.backgroundColor {
                appearance.backgroundImage = UIImage.ud.fromPureColor(bgColor)
                appearance.shadowImage = UIImage.ud.fromPureColor(bgColor)
            }
            
            self.navigationBar.standardAppearance = appearance
            self.navigationBar.scrollEdgeAppearance = self.navigationBar.standardAppearance
            self.navigationBar.shadowImage = nil
        }
    }
}
