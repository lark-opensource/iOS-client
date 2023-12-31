//
//  MailClientOAuthLoadingViewController.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2022/8/3.
//

import Foundation
import EENavigator
import RxSwift
import FigmaKit
import LarkAlertController

class MailClientOAuthLoadingViewController: LarkAlertController {
    private let loadingBgWidth: CGFloat = 303
    private let loadingBgHeight: CGFloat = 261

    private let loadingBackground = UIView()
    private let loadingAnimation = MailBaseLoadingView()
    private let sepView = UIView()
    private let closeButton = UIButton()

    private let disposeBag = DisposeBag()

    var closeHandler: (() -> Void)? = nil
    var taskID: String = "" {
        didSet {
            if !oldValue.isEmpty, oldValue != taskID {
                MailRoundedHUD.showWarning(with: BundleI18n.MailSDK.Mail_ThirdClient_Second_AddAnotherLater_Toast, on: view)
            }
        }
    }
    private(set) var needShowErrorAlert = false
    init() {
        super.init()
        setupViews()
        let delayer = Observable<()>.just(()).delay(.seconds(60), scheduler: MainScheduler.instance)
        delayer.subscribe(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.needShowErrorAlert = true
            self.closeButtonClicked()
        }, onError: { [weak self] (error) in
            MailLogger.info("[mail_client_token] delayer 60 cancel")
        }).disposed(by: disposeBag)
    }

    @objc
    func closeButtonClicked() {
        Store.fetcher?.cancelOAuthAccount(taskID: taskID)
            .subscribe(onNext: { [weak self] (_) in
                MailLogger.info("[mail_client_token] cancel cancelOAuthAccount success")
        }, onError: { [weak self] (error) in
            guard let `self` = self else { return }
            MailLogger.error("[mail_client_token] cancel login fail", error: error)
        }).disposed(by: disposeBag)
        //closeHandler?()
        dismiss(animated: false) { [weak self] in
            self?.closeHandler?()
        }
    }

    func setupViews() {
        let contentView = UIView()
        contentView.backgroundColor = UIColor.ud.bgMask
        view.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.height.equalTo(Display.height)
            make.centerY.left.right.bottom.equalToSuperview()
        }

        loadingBackground.backgroundColor = UIColor.ud.bgFloat
        loadingBackground.layer.ud.setShadow(type: .s4DownPri)
        loadingBackground.layer.cornerRadius = 8
        loadingBackground.layer.masksToBounds = true
        contentView.addSubview(loadingBackground)
        loadingBackground.snp.makeConstraints { make in
            make.width.equalTo(loadingBgWidth)
            make.height.equalTo(loadingBgHeight)
            make.center.equalToSuperview()
        }

        loadingAnimation.text = BundleI18n.MailSDK.Mail_ThirdClient_Second_VerifyingAccount_MobileLoading
        loadingAnimation.play()
        loadingAnimation.backgroundColor = UIColor.ud.bgFloat
        loadingBackground.addSubview(loadingAnimation)
        loadingAnimation.snp.makeConstraints { make in
            make.top.equalTo(24)
            make.height.equalTo(163)
            make.width.equalToSuperview()
        }

        sepView.backgroundColor = UIColor.ud.lineDividerDefault.withAlphaComponent(0.15)
        loadingBackground.addSubview(sepView)
        sepView.snp.makeConstraints { make in
            make.bottom.equalTo(-50)
            make.height.equalTo(1)
            make.width.equalToSuperview()
        }


        closeButton.setTitle(BundleI18n.MailSDK.Mail_Common_Cancel, for: .normal)
        closeButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        closeButton.titleLabel?.textAlignment = .center
        closeButton.addTarget(self, action: #selector(closeButtonClicked), for: .touchUpInside)
        contentView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.width.equalTo(sepView.snp.width)
            make.centerX.equalToSuperview()
            make.height.equalTo(50)
            make.top.equalTo(sepView.snp.top)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
