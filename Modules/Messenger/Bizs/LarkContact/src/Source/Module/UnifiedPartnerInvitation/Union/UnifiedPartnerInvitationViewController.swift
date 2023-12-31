//
//  UnifiedPartnerInvitationViewController.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/9/22.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import RxSwift
import RxCocoa
import Swinject
import LarkSDKInterface
import LKCommonsLogging
import LKCommonsTracker
import LarkAppConfig
import LarkFeatureGating
import LarkSetting

protocol UnifiedPartnerInvitationRouter {
    /// 邀请团队成员
    func pushTeamMembersInvitationViewController(vc: BaseUIViewController)
    /// 邀请外部联系人
    func pushExternalContactsInvitationViewController(vc: BaseUIViewController)
    /// 飞书邀请帮助中心
    func pushInvitationHelpCenterViewController(vc: BaseUIViewController)
}

final class UnifiedPartnerInvitationViewController: BaseUIViewController {
    private static let logger = Logger.log(UnifiedPartnerInvitationViewController.self, category: "LarkContact")
    private let dependency: UnifiedInvitationDependency
    private let router: UnifiedPartnerInvitationRouter
    private let memberInviteAwardEnable: Bool
    private let externalInviteAwardEnable: Bool
    private let disposeBag = DisposeBag()
    private let fgService: FeatureGatingService

    init(fgService: FeatureGatingService,
         router: UnifiedPartnerInvitationRouter,
         dependency: UnifiedInvitationDependency) {
        self.fgService = fgService
        self.router = router
        self.dependency = dependency
        self.memberInviteAwardEnable = fgService.staticFeatureGatingValue(with: "invite.member.award.enable")
        self.externalInviteAwardEnable = fgService.staticFeatureGatingValue(with: "invite.external.award.enable")
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.N00
        layoutPageSubviews()
        Tracer.trackInvitationEnterChooseShow()
        Tracer.trackInvitePeopleMemberCTAView(rewardNewTenant: externalInviteAwardEnable ? 1 : 0)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { (_) in
            self.layoutInviteCards()
        }
    }

    @objc
    override func closeBtnTapped() {
        if !hasBackPage && presentingViewController != nil {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc
    func routeToHelpPage() {
        router.pushInvitationHelpCenterViewController(vc: self)
        Tracer.trackInvitePeopleHelpClick()
    }

    private lazy var containerView: UIScrollView = {
        let container = UIScrollView()
        container.backgroundColor = UIColor.ud.N00
        container.alwaysBounceVertical = true
        container.showsVerticalScrollIndicator = false
        return container
    }()

    private lazy var memberInviteCard: InviteCardView = {
        let view = InviteCardView(frame: .zero, showRedPacket: self.memberInviteAwardEnable)
        view.illustration = Resources.member_invite_illustration
        view.title = BundleI18n.LarkContact.Lark_UserGrowth_InvitePeopleMemberTitle
        view.desc = BundleI18n.LarkContact.Lark_UserGrowth_InvitePeopleMemberDesc
        view.buttonBGColor = UIColor.ud.colorfulBlue
        view.buttonFrontColor = .white
        view.buttonTitle = BundleI18n.LarkContact.Lark_UserGrowth_InvitePeopleMember
        view.clickHandle = { [unowned self] in
            self.router.pushTeamMembersInvitationViewController(vc: self)
            Tracer.trackInvitationChooseInternalClick()
            Tracer.trackInvitePeopleMemberCTAClick(rewardNewTenant: self.externalInviteAwardEnable ? 1 : 0)
        }
        return view
    }()

    private lazy var externalInviteCard: InviteCardView = {
        let view = InviteCardView(frame: .zero, showRedPacket: self.externalInviteAwardEnable)
        view.illustration = Resources.external_invite_illustration
        view.title = BundleI18n.LarkContact.Lark_UserGrowth_InvitePeopleContactsTitle
        view.desc = BundleI18n.LarkContact.Lark_UserGrowth_InvitePeopleContactsDescVersionB
        view.buttonBGColor = .white
        view.buttonFrontColor = UIColor.ud.colorfulBlue
        view.buttonTitle = BundleI18n.LarkContact.Lark_UserGrowth_InvitePeopleContacts
        view.clickHandle = { [unowned self] in
            self.router.pushExternalContactsInvitationViewController(vc: self)
            Tracer.trackInvitationChooseExternalClick()
        }
        return view
    }()
}

private extension UnifiedPartnerInvitationViewController {
    func layoutPageSubviews() {
        setupNavigationBar()
        view.addSubview(containerView)
        containerView.addSubview(memberInviteCard)
        containerView.addSubview(externalInviteCard)

        containerView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        layoutInviteCards()
        Tracer.trackInvitePeopleExternalCtaView()
    }

    func layoutInviteCards() {
        memberInviteCard.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview()
            make.width.equalTo(view.frame.width - 32)
        }
        externalInviteCard.snp.makeConstraints { (make) in
            make.top.equalTo(memberInviteCard.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }
        containerView.layoutIfNeeded()
        /// Ensure that the height of each card is consistent
        let maxHeight = max(memberInviteCard.frame.height, externalInviteCard.frame.height)
        let suitableCardHeight = max(240, maxHeight)
        memberInviteCard.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview()
            make.width.equalTo(view.frame.width - 32)
            make.height.equalTo(suitableCardHeight)
        }
        externalInviteCard.snp.remakeConstraints { (make) in
            make.top.equalTo(memberInviteCard.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.width.equalTo(view.frame.width - 32)
            make.height.equalTo(suitableCardHeight)
            make.bottom.equalToSuperview().inset(16)
        }
    }

    func setupNavigationBar() {
        self.title = BundleI18n.LarkContact.Lark_UserGrowth_InvitePeopleEntry
        let l_barItem = LKBarButtonItem(image: Resources.navigation_close_light)
        l_barItem.button.addTarget(self, action: #selector(closeBtnTapped), for: .touchUpInside)
        navigationItem.leftBarButtonItem = l_barItem
        if dependency.unifiedInvitationHelpCenterURL() != nil {
            let r_barItem = LKBarButtonItem(image: Resources.invite_help)
            r_barItem.button.addTarget(self, action: #selector(routeToHelpPage), for: .touchUpInside)
            navigationItem.rightBarButtonItem = r_barItem
        }
    }
}

private final class InviteCardView: UIControl {
    var buttonBGColor: UIColor = .white {
        didSet { operationButton.backgroundColor = buttonBGColor }
    }
    var buttonFrontColor: UIColor = UIColor.ud.colorfulBlue {
        didSet { operationButton.setTitleColor(buttonFrontColor, for: .normal) }
    }
    var illustration: UIImage? {
        didSet { illustrationView.image = illustration }
    }
    var title: String? {
        didSet { titleLabel.text = title }
    }
    var desc: String? {
        didSet { descLabel.setText(text: desc ?? "", lineSpacing: 4) }
    }
    var buttonTitle: String? {
        didSet {
            operationButton.setTitle(buttonTitle, for: .normal)
            operationButton.sizeToFit()
            let suitableWidth = operationButton.frame.width + 32
            operationButton.snp.remakeConstraints { (make) in
                make.bottom.equalToSuperview().inset(28)
                make.left.equalTo(titleLabel)
                make.height.equalTo(28)
                make.width.equalTo(suitableWidth)
            }
        }
    }
    var clickHandle: (() -> Void)?

    init(frame: CGRect, showRedPacket: Bool) {
        super.init(frame: frame)
        backgroundColor = .clear
        layer.shadowColor = UIColor.ud.N900.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2.5)
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 5.0
        addTarget(self, action: #selector(cardDidClick), for: .touchUpInside)
        layoutPageSubviews(showRedPacket: showRedPacket)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func cardDidClick() {
        clickHandle?()
    }

    private func layoutPageSubviews(showRedPacket: Bool = false) {
        addSubview(wrapperView)
        wrapperView.addSubview(illustrationView)
        wrapperView.addSubview(titleLabel)
        wrapperView.addSubview(descLabel)
        wrapperView.addSubview(operationButton)

        wrapperView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        illustrationView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(0)
            make.centerY.equalToSuperview()
            make.width.equalTo(min(UIScreen.main.bounds.width / 375 * 121, 169))
            make.height.equalTo(min(UIScreen.main.bounds.width / 375 * 160.0, 224))
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(illustrationView.snp.right).offset(10)
            make.top.equalToSuperview().offset(28)
        }
        descLabel.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.right.equalToSuperview().inset(12)
            make.bottom.lessThanOrEqualTo(operationButton.snp.top).offset(-12)
        }
        operationButton.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().inset(28)
            make.left.equalTo(titleLabel)
            make.height.equalTo(28)
        }
        if showRedPacket {
            wrapperView.addSubview(redPacketView)
            redPacketView.snp.makeConstraints { (make) in
                make.left.equalTo(titleLabel.snp.right).offset(6)
                make.height.equalTo(16)
                make.centerY.equalTo(titleLabel)
                make.right.lessThanOrEqualToSuperview().inset(4)
            }
        }
    }

    private lazy var wrapperView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.borderColor = UIColor.ud.N300.cgColor
        view.layer.borderWidth = 0.5
        view.layer.cornerRadius = 12.0
        view.layer.masksToBounds = true
        view.isUserInteractionEnabled = false
        return view
    }()

    private lazy var illustrationView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N900
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        return label
    }()
    private lazy var redPacketView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.R100
        view.layer.cornerRadius = 2
        view.layer.masksToBounds = true
        let icon = UIImageView()
        icon.image = Resources.red_packet_icon
        let label = UILabel()
        label.textColor = UIColor.ud.colorfulRed
        label.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        label.text = BundleI18n.LarkContact.Lark_Legacy_KeyboardChatOthersHongbao
        view.addSubview(icon)
        view.addSubview(label)
        icon.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(7)
            make.top.bottom.equalToSuperview().inset(3)
            make.width.equalTo(8.5)
            make.height.equalTo(10)
        }
        label.snp.makeConstraints { (make) in
            make.left.equalTo(icon.snp.right).offset(3.5)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(5)
        }
        return view
    }()
    private lazy var descLabel: InsetsLabel = {
        let label = InsetsLabel(frame: .zero, insets: .zero)
        label.textColor = UIColor.ud.N600
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 0
        return label
    }()
    private lazy var operationButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = self.buttonBGColor
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        button.layer.cornerRadius = 4.0
        button.layer.masksToBounds = true
        button.layer.borderColor = UIColor.ud.colorfulBlue.cgColor
        button.layer.borderWidth = 1
        button.isUserInteractionEnabled = false
        return button
    }()
}
