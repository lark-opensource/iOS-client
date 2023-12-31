//
//  PersonalLinkViewController.swift
//  LarkContact
//
//  Created by liuxianyu on 2021/9/17.
//

import Foundation
import UIKit
import LarkUIKit
import SnapKit
import LKCommonsLogging
import LarkModel
import RxSwift
import LarkSegmentedView
import LarkMessengerInterface
import LarkSDKInterface
import UniverseDesignToast
import UniverseDesignColor
import EENavigator
import LarkSnsShare
import LarkShareToken
import LarkContainer
import LarkFeatureGating
import UniverseDesignButton

final class PersonalLinkViewController: BaseUIViewController {
    private static let logger = Logger.log(PersonalLinkViewController.self, category: "Module.LarkContact.PersonalInfo.PersonalLink")

    private let disposeBag: DisposeBag = DisposeBag()

    private let userResolver: UserResolver

    private lazy var scrollView = UIScrollView()

    private lazy var personalLinkView: PersonalLinkView = {
        return PersonalLinkView(resolver: self.userResolver)
    }()

    private let copyButton = UDButton(.secondaryBlue.type(.custom(from: .big, inset: 6)))
    let shareButton = UDButton(.primaryBlue.type(.custom(from: .big, inset: 6)))

    private lazy var buttonGroup: UDButtonGroupView = {
        var config = UDButtonGroupView.Configuration()
        config.layoutStyle = .adaptive
        config.buttonHeight = 48
        return UDButtonGroupView(configuration: config)
    }()

    private let viewModel: ExternalInvitationIndexViewModel

    var inputNavigationItem: UINavigationItem?
    private var isChangeExpireTime = false

    var copyLinkAction: (() -> Void)?
    var shareLinkAction: (() -> Void)?

    init(viewModel: ExternalInvitationIndexViewModel, resolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgBase)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.ud.bgBase

        setButtonEnable(false)
        setupSubviews()
        setupGroupLinkView()
        setupButtonStyle()
        setupButtonEvent()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindWithModel(cardInfo: InviteAggregationInfo) {
        personalLinkView.setup(cardInfo: cardInfo)
        personalLinkView.updateContentView(false)
        self.setButtonEnable(true)
    }

    func start3DRotateAnimation() {
        let duration = SwitchAnimatedView.switchAnimationDuration
        personalLinkView.start3DRotateAnimation(duration: duration, delegate: nil)
    }

    private func setupSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(personalLinkView)
        view.addSubview(buttonGroup)
    }

    private func setupGroupLinkView() {
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(buttonGroup.snp.top).offset(-20)
        }
        personalLinkView.snp.makeConstraints { make in
            make.top.bottom.left.right.equalTo(scrollView.contentLayoutGuide)
            make.width.equalToSuperview()
        }
    }

    private func setupButtonStyle() {
        buttonGroup.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-24)
        }
        copyButton.setTitle(BundleI18n.LarkContact.Lark_Legacy_Copy, for: .normal)
        shareButton.setTitle(BundleI18n.LarkContact.Lark_Legacy_QrCodeShare, for: .normal)
        buttonGroup.addButton(copyButton, priority: .default)
        buttonGroup.addButton(shareButton, priority: .highest)
    }

    private func setButtonEnable(_ isEnable: Bool) {
        let alpha: CGFloat = isEnable ? 1 : 0.6
        copyButton.isEnabled = isEnable
        shareButton.isEnabled = isEnable

        copyButton.alpha = alpha
        shareButton.alpha = alpha
    }

    private func setupButtonEvent() {
        copyButton.rx.tap.asDriver().drive(onNext: { [weak self] (_) in
            guard let self = self else { return }
            self.copyLinkAction?()
        }).disposed(by: disposeBag)

        shareButton.rx.tap.asDriver().drive(onNext: { [weak self] (_) in
            guard let self = self else { return }
            self.shareLinkAction?()
        }).disposed(by: disposeBag)
    }
}
