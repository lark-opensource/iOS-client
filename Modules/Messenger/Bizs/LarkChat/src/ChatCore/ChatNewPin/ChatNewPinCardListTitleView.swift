//
//  ChatNewPinCardListTitleView.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/10/31.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor
import LarkNavigator
import LarkSDKInterface
import LarkModel
import LarkCore

final class ChatNewPinCardListTitleView: UIView {

    private let navigator: UserNavigator
    private weak var targetVC: UIViewController?
    private let userGeneralSettings: UserGeneralSettings?
    private let chat: Chat

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.text = BundleI18n.LarkChat.Lark_IM_NewPin_Pinned_Title
        return titleLabel
    }()

    private lazy var infoImageView: UIImageView = {
        let infoImageView = UIImageView()
        infoImageView.image = UDIcon.getIconByKey(.infoOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 16, height: 16))
        return infoImageView
    }()

    init(navigator: UserNavigator, userGeneralSettings: UserGeneralSettings?, targetVC: UIViewController?, chat: Chat) {
        self.targetVC = targetVC
        self.navigator = navigator
        self.userGeneralSettings = userGeneralSettings
        self.chat = chat
        super.init(frame: .zero)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func displayOnboarding() {
        addSubview(infoImageView)
        titleLabel.snp.remakeConstraints { make in
            make.left.greaterThanOrEqualToSuperview()
            make.top.bottom.equalToSuperview()
        }
        infoImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.left.equalTo(titleLabel.snp.right).offset(4)
        }
        self.lu.addTapGestureRecognizer(action: #selector(onClick), target: self)

    }

    @objc
    private func onClick() {
        guard let targetVC = targetVC else { return }
        IMTracker.Chat.Top.Onboarding.View(self.chat, isFromInfo: true)
        let controller = ChatPinOnboardingViewController(
            sourceView: self,
            targetVC: targetVC,
            userGeneralSettings: self.userGeneralSettings,
            nav: navigator,
            chat: chat
        )
        self.navigator.present(controller, from: targetVC)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
