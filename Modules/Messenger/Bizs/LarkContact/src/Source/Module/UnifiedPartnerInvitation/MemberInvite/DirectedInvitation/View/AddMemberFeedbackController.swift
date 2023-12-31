//
//  AddMemberFeedbackController.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/12/13.
//

import Foundation
import UIKit
import SnapKit
import LarkAlertController
import EENavigator
import LarkMessengerInterface
import UniverseDesignToast
import LarkContainer

final class AddMemberFeedbackPresenter {
    class func present(resolver: UserResolver,
                       type: FieldListType,
                       needApproval: Bool,
                       baseVc: UIViewController,
                       doneCallBack: @escaping () -> Void,
                       continueCallBack: @escaping () -> Void) {
        let alertController = LarkAlertController()
        alertController.setContent(view: feedBackContentView(type: type, needApproval: needApproval),
                                   padding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
        alertController.addSecondaryButton(text: BundleI18n.LarkContact.Lark_Invitation_AddMembersFinishInvitation, dismissCompletion: {
            doneCallBack()
        })
        alertController.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Invitation_AddMembersInviteMore, dismissCompletion: {
            continueCallBack()
        })
        resolver.navigator.present(alertController, from: baseVc)
    }
    /// 飞书内邀请好友结果提示：引导流程Alert 一般流程Toast
    class func presentForLarkInvite(resolver: UserResolver,
                                    source: MemberInviteSourceScenes,
                                    baseVc: UIViewController,
                                    doneCallBack: @escaping () -> Void) {
        let needAlert = source == .newGuide || source == .upgrade

        if needAlert {
            let alertController = LarkAlertController()
            alertController.setContent(view: larkInviteBackContentView(),
                                       padding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
            alertController.addSecondaryButton(text: BundleI18n.LarkContact.Lark_Invitation_AddMembersFinishInvitation, dismissCompletion: {
                doneCallBack()
            })
            alertController.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Invitation_AddMembersInviteMore)
            resolver.navigator.present(alertController, from: baseVc)
        } else {
            UDToast.showSuccess(with: BundleI18n.LarkContact.Lark_Invitation_AddMembersSucceedTitle, on: baseVc.view)
        }
    }
}

private extension AddMemberFeedbackPresenter {
    class func larkInviteBackContentView() -> UIView {
        return feedBackContentView(type: .email, needApproval: false, isLarkInvite: true)
    }

    class func feedBackContentView(type: FieldListType, needApproval: Bool, isLarkInvite: Bool = false) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = Resources.add_member_feedback

        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.N900
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.numberOfLines = 1
        if isLarkInvite {
            titleLabel.text = BundleI18n.LarkContact.Lark_Invitation_AddMembersSucceedTitle
        } else {
            titleLabel.text = needApproval ?
                BundleI18n.LarkContact.Lark_Invitation_AddMembersNeedApproveTitle :
                BundleI18n.LarkContact.Lark_Invitation_AddMembersSucceedTitle
        }

        let messageLabel = InsetsLabel(frame: .zero, insets: .zero)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        let attributedContent: NSMutableAttributedString

        if isLarkInvite {
            messageLabel.font = UIFont.systemFont(ofSize: 14)
            messageLabel.textColor = UIColor.ud.N600
            attributedContent = NSMutableAttributedString(
                string: BundleI18n.LarkContact.Lark_Invitation_AddMembersInLarkSucceedContent,
                attributes: messageLabel.labelAttributes(lineSpacing: 4)
            )
        } else {
            let msg = needApproval ?
                BundleI18n.LarkContact.Lark_Invitation_AddMembersNeedApproveContent() :
                BundleI18n.LarkContact.Lark_Invitation_AddMembersSucceedContent()

            messageLabel.font = UIFont.systemFont(ofSize: 14)
            messageLabel.textColor = UIColor.ud.N600
            let msgAttr = messageLabel.labelAttributes(lineSpacing: 4)

            attributedContent = NSMutableAttributedString(string: msg)
            attributedContent.addAttributes(msgAttr, range: NSRange(location: 0, length: msg.count))
        }
        messageLabel.setText(attributedString: attributedContent)

        container.addSubview(imageView)
        container.addSubview(titleLabel)
        container.addSubview(messageLabel)

        imageView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(24)
            make.width.height.equalTo(125)
            make.centerX.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(imageView.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(12)
            make.height.equalTo(24)
        }
        messageLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.right.equalToSuperview().inset(21)
            make.bottom.equalToSuperview().inset(24)
        }

        return container
    }
}
