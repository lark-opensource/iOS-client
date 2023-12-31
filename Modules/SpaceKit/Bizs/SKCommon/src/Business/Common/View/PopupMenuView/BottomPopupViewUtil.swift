//
//  BottomPopupViewUtil.swift
//  SKCommon
//
//  Created by chenhuaguan on 2021/10/28.
// swiftlint:disable line_length

import Foundation
import SKResource
import SpaceInterface

/// 前端传过来的数据，不是很合理。不够通用
public struct BottomPopupModel: Codable {
    public struct Position: Codable {
        public let x: Double
        public let y: Double
    }
    public enum ActionSource: String, Codable {
        case `default`
        case globalComment
    }
    public let title: String
    public let des: String
    public let confirmBtnText: String
    public let sendLarkText: String
    public let callback: String?
    public let position: BottomPopupModel.Position?
    public let actionSource: ActionSource? //发起来源
}

public final class BottomPopupViewUtil: NSObject {
    public static var shared = BottomPopupViewUtil()

    public class func config4AtPermission(_ model: BottomPopupModel) -> PopupMenuConfig {
        var string = NSAttributedString(string: model.des, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)])
        let options = [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html]
        if let htmlData = NSString(string: model.des).data(using: String.Encoding.unicode.rawValue),
            let attributedString = try? NSMutableAttributedString(data: htmlData, options: options, documentAttributes: nil) {
            attributedString.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)],
                                           range: NSRange(location: 0, length: attributedString.length))
            string = attributedString
        }

        var config = PopupMenuConfig(title: model.title,
                                                      content: string,
                                                      confirmBtn: model.confirmBtnText,
                                                      sendLarkText: model.sendLarkText,
                                                      sendLark: true,
                                     actionSource: model.actionSource)

        string.enumerateAttributes(in: NSRange(location: 0, length: string.length), options: []) { (attributes, _, _) in
            if let url = attributes[.link] as? URL,
               let params = url.docs.fetchQuery(),
               let chatterId = params["chatterId"] {
                config.extraInfo = chatterId
            }
        }
        return config
    }

    public class func config4AtInfo(_ at: AtInfo) -> PopupMenuConfig {
        let userName = at.at
        let desc: String = """
        <a href="lark://client/contact/personcard?chatterId=\(at.token)">\(userName)</a> \(BundleI18n.SKResource.CreationMobile_mention_GrantPermDesc(""))
        """
        let model = BottomPopupModel(title: BundleI18n.SKResource.CreationMobile_Permssions_Share_Title, des: desc, confirmBtnText: BundleI18n.SKResource.CreationMobile_mention_GrantPermBtn, sendLarkText: BundleI18n.SKResource.CreationMobile_mention_NotifyUserCheckbox, callback: nil, position: nil, actionSource: nil)
        var config = Self.config4AtPermission(model)
        config.extraInfo = at
        return config
    }


    public class func getPopupMenuViewInPoperOverStyle(delegate: BottomPopupVCMenuDelegate?, config: PopupMenuConfig, permStatistics: PermissionStatistics?, rectInView: CGRect, soureViewHeight: CGFloat) -> UIViewController {
        let alertVC = CustomContainerAlert()
        let arrowDirection: UIPopoverArrowDirection = (rectInView.midY > soureViewHeight / 2.0) ? .down : .up
        let tipViewWidth: CGFloat = 351
        let constraitHeight: CGFloat = 177
        var config = config
        config.isPopover = true
        let inviteView = BottomPopupMenuView(config: config)
        inviteView.permStatistics = permStatistics
        inviteView.delegate = delegate
        alertVC.preferredContentSize = CGSize(width: tipViewWidth, height: constraitHeight)

        alertVC.setTipsView(inviteView, arrowUp: (arrowDirection == .up ? true : false), constraitHeight: constraitHeight)
        alertVC.modalPresentationStyle = .popover
        alertVC.popoverPresentationController?.sourceRect = rectInView
        alertVC.popoverPresentationController?.permittedArrowDirections = arrowDirection
        return alertVC
    }

}

extension BottomPopupViewUtil: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController,
                                          traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        if let _ = controller.presentedViewController as? CommentConfirmAlertVCType {
            return .none
        } else {
            return controller.presentedViewController.modalPresentationStyle
        }
    }
}
