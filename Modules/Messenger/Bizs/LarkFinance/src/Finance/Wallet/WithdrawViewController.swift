//
//  WithdrawViewController.swift
//  LarkFinance
//
//  Created by 李晨 on 2019/11/6.
//

import Foundation
import UIKit
import SnapKit
import LarkModel
import LarkSDKInterface
import RxSwift
import RxCocoa
import LKCommonsLogging
import LarkMessengerInterface

final class WithdrawViewController: UIViewController {

    static let logger = Logger.log(WithdrawViewController.self, category: "Finance")

    private let testEnv: Bool
    private let redPacketAPI: RedPacketAPI
    private let payManagerService: PayManagerService
    private var balance: WalletBalance? {
        didSet {
            if let balance = self.balance {
                moneyLabel.text = String(format: "%.2f", Float(balance.balance) / 100.0)
            }
        }
    }
    private let disposeBag = DisposeBag()

    private let iconView: UIImageView = {
        let icon = UIImageView()
        icon.image = Resources.balance
        return icon
    }()

    private let moneyLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "DINAlternate-Bold", size: 44)
        label.textColor = UIColor.ud.N900
        return label
    }()

    private let tipLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkFinance.Lark_Hongbao_Balance
        label.textColor = UIColor.ud.N500
        return label
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let loadingIndicator = UIActivityIndicatorView()
        loadingIndicator.style = .gray
        return loadingIndicator
    }()

    private let loadFailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.isHidden = true
        label.text = BundleI18n.LarkFinance.Lark_Legacy_LoadingFailed
        label.textColor = UIColor.ud.N500
        return label
    }()

    private let withdrawBtn: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.ud.colorfulBlue
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.setTitle(BundleI18n.LarkFinance.Lark_Hongbao_Withdraw, for: .normal)
        return button
    }()

    init(testEnv: Bool, redPacketAPI: RedPacketAPI, payManagerService: PayManagerService) {
        self.testEnv = testEnv
        self.redPacketAPI = redPacketAPI
        self.payManagerService = payManagerService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        self.title = BundleI18n.LarkFinance.Lark_Hongbao_Balance
        self.view.addSubview(iconView)
        self.view.addSubview(moneyLabel)
        self.view.addSubview(loadFailLabel)
        self.view.addSubview(loadingIndicator)
        self.view.addSubview(tipLabel)
        self.view.addSubview(withdrawBtn)

        self.withdrawBtn.addTarget(self, action: #selector(clickWithdrawBtn), for: .touchUpInside)

        iconView.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(24)
        }

        moneyLabel.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(iconView.snp.bottom)
            maker.height.equalTo(50)
        }

        loadFailLabel.snp.makeConstraints { (maker) in
            maker.center.equalTo(moneyLabel)
        }

        loadingIndicator.snp.makeConstraints { (maker) in
            maker.center.equalTo(moneyLabel)
        }

        tipLabel.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(moneyLabel.snp.bottom).offset(8)
        }

        withdrawBtn.snp.makeConstraints { (maker) in
            maker.left.equalTo(17)
            maker.right.equalTo(-17)
            maker.top.equalTo(tipLabel.snp.bottom).offset(40)
            maker.height.equalTo(50)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadBalance()
    }

    func reloadBalance() {
        moneyLabel.isHidden = true
        loadFailLabel.isHidden = true
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()
        redPacketAPI.getBalance()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (balance) in
                self?.loadingIndicator.isHidden = true
                self?.loadingIndicator.stopAnimating()
                self?.loadFailLabel.isHidden = true
                self?.moneyLabel.isHidden = false
                self?.balance = balance
            }, onError: { [weak self] (error) in
                self?.loadingIndicator.isHidden = true
                self?.loadingIndicator.stopAnimating()
                self?.loadFailLabel.isHidden = false
                self?.moneyLabel.isHidden = true
                WithdrawViewController.logger.error("get balance failed", error: error)
            })
            .disposed(by: disposeBag)
    }

    @objc
    func clickWithdrawBtn() {
        payManagerService.openWithdrawDesk(
            url: WalletInfo.urlString(
                testEnv: self.testEnv,
                path: WalletInfo.withdrawPath,
                params: ["payment_type": "trade", "product_code": "withdraw"]
            ),
            referVc: self,
            closeCallBack: { [weak self] _ in
                self?.reloadBalance()
            }
        )
    }
}
