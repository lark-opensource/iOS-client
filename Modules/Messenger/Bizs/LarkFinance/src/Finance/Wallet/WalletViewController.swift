//
//  WalletViewController.swift
//  Pods
//
//  Created by CharlieSu on 2018/10/29.
//

import Foundation
import UIKit
import Homeric
import LarkUIKit
import LarkModel
import LarkMessengerInterface
import RxSwift
import RxCocoa
import LKCommonsLogging
import LKCommonsTracker
import EENavigator
import LarkLocalizations
import LarkSDKInterface
import RustPB
import LarkEnv
import LarkContainer
import LarkCore
import UniverseDesignToast
import LarkSetting

/*
 零钱: https://tp-pay-test.snssdk.com/usercenter/balance?merchant_id=1300000004&app_id=800000070008
 银行卡: https://tp-pay-test.snssdk.com/usercenter/cards?merchant_id=1300000004&app_id=800000070008
 交易记录: https://tp-pay-test.snssdk.com/usercenter/transaction?merchant_id=1300000004&app_id=800000070008
 安全: https://tp-pay-test.snssdk.com/usercenter/member?merchant_id=1300000004&app_id=800000070008
 */

struct WalletInfo {

    static var merchantID: String {
        if EnvManager.env.isStaging {
            return "800075700120022"
        } else {
            return "800010000160015"
        }
    }

    static var appID: String {
        if EnvManager.env.isStaging {
            return "TNA202006221356022354024974"
        } else {
            return "NA202007282136550990958085"
        }
    }

    static var host: String {
         let host = DomainSettingManager.shared.currentSetting[.cjHongbao]?.first ?? ""
         assert(!host.isEmpty)
         return host
     }

    static let transactionPath = "usercenter/transaction"
    static let securePath = "usercenter/member"
    static let withdrawPath = "cashdesk_withdraw"

    static func urlString(
        testEnv: Bool,
        path: String,
        params: [String: String] = [:]
    ) -> String {
        let host = WalletInfo.host
        WalletViewController.logger.info("walletHost is \(host)")
        var url = String(
            format: "\(host)/%@?merchant_id=%@&app_id=%@",
            path,
            WalletInfo.merchantID,
            WalletInfo.appID)
        params.forEach { (key, value) in
            url.append("&\(key)=\(value)")
        }
        return url
    }
}

final class WalletViewController: BaseUIViewController, UserResolverWrapper {

    static let logger = Logger.log(WalletViewController.self, category: "Finance")

    var userResolver: LarkContainer.UserResolver
    private let redPacketAPI: RedPacketAPI
    private let userAppConfig: UserAppConfig
    private let payManagerService: PayManagerService
    private var balance: WalletBalance?
    private let disposeBag = DisposeBag()

    private let topBgView = UIImageView(image: Resources.wallet_top)
    // 成功
    private let walletStackView = UIStackView()
    private let topMainLabel = UILabel()
    private let topSubLabel = UILabel()
    // 加载中
    private let loadingIndicator = UIActivityIndicatorView()
    // 加载失败
    private let loadFailLabel = UILabel()

    private let testEnv: Bool
    private let payManager: PayManagerService

    init(
        testEnv: Bool,
        redPacketAPI: RedPacketAPI,
        payManagerService: PayManagerService,
        userAppConfig: UserAppConfig,
        payManager: PayManagerService,
        userResolver: UserResolver) {
        self.testEnv = testEnv
        self.redPacketAPI = redPacketAPI
        self.payManagerService = payManagerService
        self.userAppConfig = userAppConfig
        self.payManager = payManager
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.payManagerService.cjpayInitIfNeeded(callback: nil)
        Tracker.post(TeaEvent(Homeric.WALLET_OPEN))

        titleString = BundleI18n.LarkFinance.Lark_Legacy_Wallet
        view.backgroundColor = UIColor.ud.bgBody

        view.addSubview(topBgView)
        topBgView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(topBgView.snp.width).multipliedBy(160.0 / 351.0)
        }

        let placeHolderView = UIView()
        topBgView.addSubview(placeHolderView)
        placeHolderView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.width.equalTo(1)
            make.centerX.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(32.0 / 130.0)
        }

        topBgView.lu.addTapGestureRecognizer(action: #selector(walletDidTapped),
                                             target: self)

        walletStackView.axis = .vertical
        walletStackView.alignment = .center
        walletStackView.distribution = .fill
        walletStackView.spacing = 4
        walletStackView.isHidden = true
        topBgView.addSubview(walletStackView)
        walletStackView.snp.makeConstraints { (make) in
            make.top.equalTo(placeHolderView.snp.bottom)
            make.centerX.equalToSuperview()
        }

        topMainLabel.textColor = UIColor.ud.N00.alwaysLight
        topMainLabel.font = UIFont(name: "DINAlternate-Bold", size: 44)
        walletStackView.addArrangedSubview(topMainLabel)

        topSubLabel.textColor = UIColor.ud.N00.alwaysLight
        topSubLabel.font = UIFont.systemFont(ofSize: 14)
        walletStackView.addArrangedSubview(topSubLabel)

        loadingIndicator.style = .whiteLarge
        topBgView.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 35, height: 35))
            make.center.equalToSuperview()
        }

        topBgView.addSubview(loadFailLabel)
        loadFailLabel.font = UIFont.systemFont(ofSize: 14)
        loadFailLabel.textColor = UIColor.ud.N00.alwaysLight
        loadFailLabel.isHidden = true
        loadFailLabel.text = BundleI18n.LarkFinance.Lark_Legacy_LoadingFailed
        topBgView.addSubview(loadFailLabel)
        loadFailLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        WalletFunction.allCases.forEach { (walletFunction) in
            let button = WalletFunctionButton()
            button.rx.tap.subscribe(onNext: { [weak self] () in
                guard let self = self else { return }
                self.buttonDidTapped(button: button, function: walletFunction)
            })
            .disposed(by: disposeBag)
            button.setImage(walletFunction.image, for: .normal)
            button.setTitle(walletFunction.title, for: .normal)
            button.setTitleColor(UIColor.ud.N900, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
            stackView.addArrangedSubview(button)
        }
        view.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(topBgView.snp.bottom).offset(20)
        }
        fetchUserPhoneInfo()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if Display.pad {
            preferredContentSize = CGSize(
                width: 375, height: 620 - (navigationController?.navigationBar.bounds.height ?? 0)
            )
        }
        walletStackView.isHidden = true
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()
        redPacketAPI.getBalance()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (balance) in
                self?.walletStackView.isHidden = false
                self?.loadingIndicator.isHidden = true
                self?.loadingIndicator.stopAnimating()
                self?.loadFailLabel.isHidden = true
                self?.set(balance)
            }, onError: { [weak self] (error) in
                self?.walletStackView.isHidden = true
                self?.loadingIndicator.isHidden = true
                self?.loadingIndicator.stopAnimating()
                self?.loadFailLabel.isHidden = false
                WalletViewController.logger.error("获取钱包余额失败", error: error)
            })
            .disposed(by: disposeBag)
    }

    private func set(_ balance: WalletBalance) {
        self.balance = balance
        topMainLabel.text = String(format: "%.2f", Float(balance.balance) / 100.0)

        let uinitText: String
        switch balance.currency {
        case .unknown:
            uinitText = "Unknown"
        case .cny:
            uinitText = BundleI18n.LarkFinance.Lark_Legacy_WalletUnit
        case .usd:
            uinitText = "USD"
        case .vir:
            uinitText = "VIR"
        @unknown default:
            assert(false, "new value")
            uinitText = "Unknown"
        }
        topSubLabel.text = BundleI18n.LarkFinance.Lark_Legacy_BalanceVIR + "(" + uinitText + ")"
    }

    @objc
    private func walletDidTapped() {
        Tracker.post(TeaEvent(Homeric.WALLET_BALANCE))
        userResolver.navigator.push(body: WithdrawBody(), from: self)
    }

    private func buttonDidTapped(button: UIButton, function: WalletFunction) {
        switch function {
        case .bankCard:
            Tracker.post(TeaEvent(Homeric.WALLET_CARDS))
            payManagerService.openBankCardList(referVc: self)
        case .transaction:
            Tracker.post(TeaEvent(Homeric.WALLET_TRANSACTION))
            payManagerService.openTransaction(referVc: self)
        case .secure:
            Tracker.post(TeaEvent(Homeric.WALLET_SECURITY))
            payManagerService.openPaySecurity(referVc: self)
        case .help:
            Tracker.post(TeaEvent(Homeric.WALLET_HELP))
            if let url: URL = URL(string: userAppConfig.resourceAddrWithLanguage(key: RustPB.Basic_V1_AppConfig.ResourceKey.helpAboutHongbao) ?? "" ) {
                userResolver.navigator.push(url, context: ["from": "lark"], from: self)
            }
        }
    }
}

// 手机号是否绑定的判断逻辑
extension WalletViewController {
    fileprivate func fetchUserPhoneInfo() {
        showLoading(true)
        self.payManager.fetchUserPhoneInfo().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (isBind) in
            self?.showPhone(isBind)
        }, onError: { [weak self] error in
            guard let self = self else { return }
            self.showLoading(false)
            if let rxError = error as? RxError, case .timeout = rxError {
                UDToast.showFailure(with: BundleI18n.LarkFinance.Lark_Legacy_NetworkError, on: self.view)
            }
            self.navigationController?.popViewController(animated: true)
        }).disposed(by: self.disposeBag)
    }

    private func showPhone(_ isBind: Bool) {
        guard !isBind else {
            self.showLoading(false)
            return
        }
        let from = WindowTopMostFrom(vc: self)
        userResolver.navigator.present(
            body: AlertAddPhoneBody(content: BundleI18n.LarkFinance.Lark_Wallet_FinancialAccountMissPhoneText()),
            wrap: LkNavigationController.self,
            from: from,
            prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() },
            completion: { [weak self] _, _ in
                self?.showLoading(false)
                self?.navigationController?.popViewController(animated: true)
            }
        )
    }

    private func showLoading(_ isShow: Bool) {
        self.loadingPlaceholderView.backgroundColor = UIColor.ud.N00
        self.loadingPlaceholderView.isHidden = !isShow
    }
}
