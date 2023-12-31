//
//  LeanModeVerifyController.swift
//  LarkLeanMode
//
//  Created by 袁平 on 2020/3/3.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import LarkAccountInterface
import LarkAvatar

typealias VerifySuccess = (UIViewController) -> Void
typealias VerifyFail = (UIViewController) -> Void

final class LeanModeVerifyController: BaseUIViewController {
    private let layout = Layout()
    private let disposeBag = DisposeBag()
    private var isVerifying: Bool = false // 当前是否正在校验
    private let verifySuccess: VerifySuccess
    private let verifyFail: VerifyFail

    private var passportService: PassportUserService

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private lazy var titleNaviBar: TitleNaviBar = {
        let title = UILabel(frame: .zero)
        title.text = I18n.Lark_Security_LeanModeTurnOffIdentityVerificationPageTitle
        title.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        title.numberOfLines = 1
        title.textColor = .white
        let naviBar = TitleNaviBar(titleView: title)
        naviBar.backgroundColor = UIColor.ud.colorfulBlue
        let closeItem = TitleNaviBarItem(image: Resources.close_icon, action: { [weak self] (_) in
            self?.dismiss(animated: true)
        })
        naviBar.leftItems = [closeItem]
        return naviBar
    }()

    /// 顶部Wrapper View
    private lazy var topWrapper: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.ud.colorfulBlue
        return view
    }()

    /// 底部Wrapper View
    private lazy var bottomWrapper: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        return view
    }()

    private lazy var avatar: AvatarImageView = {
        let avatar = AvatarImageView(frame: .zero)
        avatar.layer.ud.setBorderColor(UIColor.ud.primaryOnPrimaryFill)
        avatar.layer.borderWidth = 1
        avatar.layer.allowsEdgeAntialiasing = true
        avatar.layer.cornerRadius = layout.avatarSize / 2
        avatar.clipsToBounds = true
        return avatar
    }()

    private lazy var name: UILabel = {
        let name = UILabel(frame: .zero)
        name.font = UIFont.systemFont(ofSize: 15)
        name.textColor = .white
        name.numberOfLines = 1
        return name
    }()

    /// 提示
    private lazy var remindImageView: UIImageView = {
        let remind = UIImageView(frame: .zero)
        remind.backgroundColor = .clear
        remind.image = Resources.no_permission
        remind.contentMode = .scaleAspectFit
        remind.clipsToBounds = true
        return remind
    }()

    /// 提示
    private lazy var remindLabel: UILabel = {
        let remind = UILabel(frame: .zero)
        remind.text = I18n.Lark_Security_LeanModeTurnOffIdentityVerificationPageContent
        remind.numberOfLines = 0
        remind.textColor = UIColor.ud.N500
        remind.font = UIFont.systemFont(ofSize: 14)
        remind.lineBreakMode = .byWordWrapping
        return remind
    }()

    /// 身份验证
    private lazy var verifyButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(I18n.Lark_Security_LeanModeTurnOffIdentityVerificationPageButton, for: .normal)
        button.backgroundColor = UIColor.ud.colorfulBlue
        button.layer.cornerRadius = 4
        button.lu.addTapGestureRecognizer(action: #selector(verify), target: self)
        return button
    }()

    init(verifySuccess: @escaping VerifySuccess, verifyFail: @escaping VerifyFail, passportService: PassportUserService) {
        self.verifySuccess = verifySuccess
        self.verifyFail = verifyFail
        self.passportService = passportService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        verify()
    }

    private func setupViews() {
        isNavigationBarHidden = true
        view.addSubview(titleNaviBar)
        titleNaviBar.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
        }

        view.addSubview(topWrapper)
        topWrapper.snp.makeConstraints { (make) in
            make.top.equalTo(titleNaviBar.snp.bottom)
            make.height.equalTo(layout.topWrapperHeight)
            make.leading.trailing.equalToSuperview()
        }
        topWrapper.addSubview(avatar)
        avatar.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.height.equalTo(layout.avatarSize)
            make.top.equalToSuperview().offset(21)
        }
        avatar.set(entityId: passportService.user.userID,
                   avatarKey: passportService.user.avatarKey)

        topWrapper.addSubview(name)
        name.snp.makeConstraints { (make) in
            make.top.equalTo(avatar.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(12)
            make.trailing.lessThanOrEqualToSuperview().offset(-12)
        }

        let user = passportService.user
        name.text = user.i18nNames?.currentLocalName ?? user.name

        view.addSubview(bottomWrapper)
        bottomWrapper.snp.makeConstraints { (make) in
            make.top.equalTo(topWrapper.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        bottomWrapper.addSubview(remindImageView)
        remindImageView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(68)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(layout.remindSize)
        }
        bottomWrapper.addSubview(remindLabel)
        remindLabel.snp.makeConstraints { (make) in
            make.top.equalTo(remindImageView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(67)
            make.trailing.lessThanOrEqualToSuperview().offset(-67)
        }
        bottomWrapper.addSubview(verifyButton)
        verifyButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-100)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(layout.verifyButtonHeight)
        }
    }

    @objc
    private func verify() {
        guard !isVerifying else { return }
        isVerifying = true
        passportService.getSecurityStatus(appId: "") { [weak self] (code, _, _) in
            guard let `self` = self else { return }
            let status = (code == 0 ? true : false)
            if status {
                self.verifySuccess(self)
            } else {
                self.verifyFail(self)
            }
            self.isVerifying = false
        }
    }
}

extension LeanModeVerifyController {
    struct Layout {
        let avatarSize: CGFloat = 65
        let topWrapperHeight: CGFloat = 198
        let remindSize: CGFloat = 80
        let verifyButtonHeight: CGFloat = 48
    }
}
