//
//  LarkPrivacyOverseaAlertViewController.swift
//  LarkPrivacyAlert
//
//  Created by panbinghua on 2022/2/22.
//

import Foundation
import UIKit
import LarkUIKit
import RichLabel
import LarkExtensions
import LKCommonsLogging
import LKCommonsTracker
import Homeric

final class LarkPrivacyOverseaAlertViewController: UIViewController {
    static let log = Logger.log(
        LarkPrivacyOverseaAlertViewController.self,
        category: "PrivacyAlert"
    )

    private let modalView = LarkPrivacyModalView()
    private let alertView = PrivacyAlertView()
    private let config: PrivacyAlertConfigProtocol

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        alertView.onViewTransition(size.width)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        // setup and add subviews
        let privacyText = I18N.Lark_Core_AcceptServiceTermPrivacyPolicy_DisclaimerPrivacyPolicy
        let termText = I18N.Lark_Core_AcceptServiceTermPrivacyPolicy_UserAgreement
        let contentText = I18N.Lark_Core_AcceptServiceTermPrivacyPolicy_DisclaimerText(termText, privacyText)
        let acceptText = I18N.Lark_Core_AcceptServiceTermPrivacyPolicy_DisclaimerButton
        let declineText = I18N.Lark_Core_RejectServiceTermPrivacyPolicy_AndQuit_Button
        alertView.setup(availableWidth: view.bounds.width,
                        contentText: contentText, privacyText: privacyText, termText: termText,
                        privacyURL: config.privacyURL, termURL: config.serviceTermURL,
                        acceptText: acceptText, declineText: declineText)
        modalView.addSubview(alertView)
        alertView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.top.greaterThanOrEqualTo(36)
            // 最小侧边距为36，优先级low尽力撑开白底
            $0.left.equalTo(36).priority(.low)
        }
        view.addSubview(modalView)
        modalView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        appearAnimation()

    }

    private func appearAnimation() {
        self.alertView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        self.view.alpha = 0
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.1, animations: {
                self.alertView.transform = CGAffineTransform(scaleX: 1, y: 1)
                self.view.alpha = 1
            })
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    public init(
        config: PrivacyAlertConfigProtocol,
        confirmCallback: @escaping () -> Void
    ) {
        self.config = config
        super.init(nibName: nil, bundle: nil)

        alertView.openLinkHandler = { [weak self] (url) in
            guard let self = self else { return }
            Self.log.info("openned link in priacy notice alert: \(url.absoluteString)")
            let vc = LarkPrivacyWebViewController(url: url)
            self.navigationController?.pushViewController(vc, animated: true)
        }
        alertView.rightHandler = {
            Self.log.info("dismissed priacy notice alert")
            Tracker.post(TeaEvent(Homeric.PRIVACY_POLICY_ACCEPT))
            confirmCallback()
        }
        alertView.leftHandler = {
            exit(0)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
