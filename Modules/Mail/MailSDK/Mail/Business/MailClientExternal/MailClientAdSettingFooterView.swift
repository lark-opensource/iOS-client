//
//  MailClientAdSettingFooterView.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2021/11/29.
//

import Foundation
import UIKit
import RxSwift
import SnapKit
import UniverseDesignButton

protocol MailClientAdSettingFooterViewDelegate: AnyObject {
    func headerViewDidClickedLogin(_ footerView: MailClientAdSettingFooterView, scene: MailClientAdSettingScene)
}

class MailClientAdSettingFooterView: UITableViewHeaderFooterView {

    weak var delegate: MailClientAdSettingFooterViewDelegate?

    private let disposeBag = DisposeBag()
    private lazy var loginButton: UDButton = {
        let config = UDButtonUIConifg.makeLoginButtonConfig()
        let loginButton = UDButton()
        loginButton.layer.cornerRadius = 6
        loginButton.layer.masksToBounds = true
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        loginButton.setTitle(self.title, for: .normal)
        loginButton.isEnabled = scene != .login
        loginButton.config = config
        loginButton.rx.tap.subscribe(onNext: { [weak self] in
            guard let `self` = self else { return }
            self.didClickLoginButton()
        }).disposed(by: disposeBag)
        return loginButton
    }()
    private var title: String = ""
    private var scene: MailClientAdSettingScene = .login

    init(reuseIdentifier: String?, scene: MailClientAdSettingScene) {
        super.init(reuseIdentifier: reuseIdentifier)
        switch scene {
        case .login:
            self.title = BundleI18n.MailSDK.Mail_ThirdClient_Login
        case .config:
            self.title = BundleI18n.MailSDK.Mail_ThirdClient_SaveMobile
        case .reVerfiy:
            self.title = BundleI18n.MailSDK.Mail_ThirdClient_VerifiedAgain
        }
        self.scene = scene
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        addSubview(loginButton)
        loginButton.snp.makeConstraints { make in
            make.top.equalTo(8)
            make.bottom.equalToSuperview()
            make.left.equalTo(safeAreaInsets.left + 16)
            make.right.equalTo(-safeAreaInsets.right - 16)
        }
    }

    func enableLogin(_ enable: Bool) {
        loginButton.isEnabled = enable
    }

    func didClickLoginButton() {
        delegate?.headerViewDidClickedLogin(self, scene: self.scene)
    }

    func showLoading() {
        loginButton.showLoading()
    }

    func hideLoading() {
        loginButton.hideLoading()
    }
}
