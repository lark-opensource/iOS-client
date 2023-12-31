//
//  LarkPrivacyAlertModalViewController.swift
//  LarkLaunchGuide
//
//  Created by tangyunfei.tyf on 2020/2/26.
//

import Foundation
import UIKit
import LarkUIKit
import RichLabel
import LarkExtensions
import LKCommonsLogging
import LKCommonsTracker
import Homeric

final class LarkPrivacyAlertModalViewController: UIViewController {
    static let log = Logger.log(
        LarkPrivacyAlertModalViewController.self,
        category: "PrivacyAlert"
    )

    private let modalView = LarkPrivacyModalView()
    private let privacyGuidelineView = LarkPrivacyGuidelineView() // 个人信息保护指引
    private let config: PrivacyAlertConfigProtocol
    private let alertView = LarkPrivacyAlertView() // 拒绝政策后的二次弹窗

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        privacyGuidelineView.onViewTransition(size.width)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        // setup and add subviews
        privacyGuidelineView.setup(config: config, availableWidth: view.bounds.width)
        modalView.addSubview(privacyGuidelineView)
        privacyGuidelineView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.top.greaterThanOrEqualTo(36)
            // 最小侧边距为36，优先级low尽力撑开白底
            $0.left.equalTo(36).priority(.low)
        }
        alertView.setup(config: config, availableWidth: view.bounds.width)
        modalView.addSubview(alertView)
        alertView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.top.greaterThanOrEqualTo(36)
            // 最小侧边距为36，优先级low尽力撑开白底
            $0.left.equalTo(36).priority(.low)
        }
        alertView.isHidden = true
        view.addSubview(modalView)
        modalView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        appearAnimation()

    }

    private func appearAnimation() {
        self.privacyGuidelineView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        self.view.alpha = 0
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.1, animations: {
                self.privacyGuidelineView.transform = CGAffineTransform(scaleX: 1, y: 1)
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

        privacyGuidelineView.openLinkHandler = { [weak self] (url) in
            guard let self = self else { return }
            Self.log.info("openned link in priacy notice alert: \(url.absoluteString)")
            let vc = LarkPrivacyWebViewController(url: url)
            self.navigationController?.pushViewController(vc, animated: true)
        }
        privacyGuidelineView.rightHandler = {
            Self.log.info("dismissed priacy notice alert")
            Tracker.post(TeaEvent(Homeric.PRIVACY_POLICY_ACCEPT))
            confirmCallback()
        }
        privacyGuidelineView.leftHandler = { [weak self] in
            self?.showNotAgreeToast()
        }
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

    private func showNotAgreeToast() {
        privacyGuidelineView.isHidden = true
        alertView.isHidden = false
    }
}
