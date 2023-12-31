//
//  IDPNetworkLossInteractiveViewController.swift
//  LarkAccount
//
//  Created by au on 2023/1/9.
//

import RxCocoa
import RxSwift
import UniverseDesignButton
import UniverseDesignEmpty
import UIKit

class IDPNetworkLossInteractiveViewController: UIViewController {

    private let settingBlock: (() -> Void)
    private let refreshBlock: (() -> Void)

    init(settingBlock: @escaping (() -> Void), refreshBlock: @escaping (() -> Void)) {
        self.settingBlock = settingBlock
        self.refreshBlock = refreshBlock
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.ud.bgBody

        let containerView = UIView()
        containerView.backgroundColor = UIColor.ud.bgBody

        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview()
        }

        containerView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 125, height: 125))
        }

        titleLabel.text = BundleI18n.suiteLogin.Lark_Shared_Passport_HuazhuInternetConnectionError_NetworkRequestErrorTitle
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(24)
            make.top.equalTo(imageView.snp.bottom).offset(12)
        }

        messageLabel.text = BundleI18n.suiteLogin.Lark_Shared_Passport_HuazhuInternetConnectionError_CheckPermissionAndSettingsDesc
        containerView.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(24)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
        }

        settingButton.setTitle(BundleI18n.suiteLogin.Lark_Shared_Passport_HuazhuInternetConnectionError_GoToSettingsButton, for: .normal)
        settingButton.rx
            .tap
            .subscribe(onNext: { [weak self] _ in
                self?.settingBlock()
            })
            .disposed(by: disposeBag)
        containerView.addSubview(settingButton)
        settingButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualTo(24)
            make.right.lessThanOrEqualTo(-24)
            make.top.equalTo(messageLabel.snp.bottom).offset(16)
        }

        refreshButton.setTitle(BundleI18n.suiteLogin.Lark_Shared_Passport_HuazhuInternetConnectionError_RefreshButton, for: .normal)
        refreshButton.rx
            .tap
            .subscribe(onNext: { [weak self] _ in
                self?.refreshBlock()
            })
            .disposed(by: disposeBag)
        containerView.addSubview(refreshButton)
        refreshButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualTo(24)
            make.right.lessThanOrEqualTo(-24)
            make.top.equalTo(settingButton.snp.bottom).offset(12)
            make.bottom.equalToSuperview()
        }
    }

    private let imageView: UIImageView = {
        let view = UIImageView(image: UDEmptyType.loadingFailure.defaultImage())
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let settingButton: UDButton = {
        var config = UDButtonUIConifg.primaryBlue
        config.type = .middle
        let button = UDButton(config)
        return button
    }()

    private let refreshButton: UDButton = {
        var config = UDButtonUIConifg.secondaryGray
        config.type = .middle
        let button = UDButton(config)
        return button
    }()

    private let disposeBag = DisposeBag()
}
