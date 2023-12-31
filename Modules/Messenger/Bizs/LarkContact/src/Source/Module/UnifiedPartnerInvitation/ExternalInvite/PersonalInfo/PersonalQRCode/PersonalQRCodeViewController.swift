//
//  PersonalQRCodeViewController.swift
//  LarkContact
//
//  Created by liuxianyu on 2021/9/17.
//

import Foundation
import LarkFoundation
import LarkUIKit
import SnapKit
import RxSwift
import RxCocoa
import UniverseDesignToast
import UIKit
import LarkContainer
import UniverseDesignButton

final class PersonalQRCodeViewController: BaseUIViewController {
    private let disposeBag: DisposeBag = DisposeBag()

    private let userResolver: UserResolver

    private lazy var scrollView = UIScrollView()

    private let qrCodeView: PersonalQRCodeView
    private let saveButton: UIButton
    let shareButton: UIButton
    private let viewModel: ExternalInvitationIndexViewModel

    private lazy var buttonGroup: UDButtonGroupView = {
        var config = UDButtonGroupView.Configuration()
        config.layoutStyle = .adaptive
        config.buttonHeight = 48
        return UDButtonGroupView(configuration: config)
    }()

    var saveQRCodeImage: (() -> Void)?
    var shareQRCodeImage: (() -> Void)?

    init(viewModel: ExternalInvitationIndexViewModel, resolver: UserResolver) {
        qrCodeView = PersonalQRCodeView(resolver: resolver)

        saveButton = UDButton(.secondaryBlue.type(.custom(from: .big, inset: 6)))
        shareButton = UDButton(.primaryBlue.type(.custom(from: .big, inset: 6)))

        self.viewModel = viewModel
        self.userResolver = resolver

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgBase)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.ud.bgBase

        setButtonEnable(false)
        setupSubviews()
        setupQRCodeView()
        setupButtonStyle()
        setupButtonEvent()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension PersonalQRCodeViewController {
    func bindWithModel(cardInfo: InviteAggregationInfo) {
        qrCodeView.setup(cardInfo: cardInfo)
        qrCodeView.updateContentView(false)
        self.setButtonEnable(true)
    }

    func start3DRotateAnimation() {
        let duration = SwitchAnimatedView.switchAnimationDuration
        qrCodeView.start3DRotateAnimation(duration: duration, delegate: nil)
    }

    private func setupSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(qrCodeView)
        view.addSubview(buttonGroup)
    }

    private func setupQRCodeView() {
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(buttonGroup.snp.top).offset(-20)
        }
        qrCodeView.snp.makeConstraints { make in
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
        saveButton.setTitle(BundleI18n.LarkContact.Lark_Contact_ShareQRCodeSaveImage_Button, for: .normal)
        shareButton.setTitle(BundleI18n.LarkContact.Lark_Legacy_QrCodeShare, for: .normal)
        buttonGroup.addButton(saveButton, priority: .default)
        buttonGroup.addButton(shareButton, priority: .highest)
    }

    private func setButtonEnable(_ isEnable: Bool) {
        let alpha: CGFloat = isEnable ? 1 : 0.6
        saveButton.isEnabled = isEnable
        shareButton.isEnabled = isEnable

        saveButton.alpha = alpha
        shareButton.alpha = alpha
    }

    private func setupButtonEvent() {
        saveButton.rx.tap.asDriver().drive(onNext: { [weak self] (_) in
            guard let self = self else { return }
            self.saveQRImage()
        }).disposed(by: disposeBag)

        shareButton.rx.tap.asDriver().drive(onNext: { [weak self] (_) in
            guard let self = self else { return }
            self.shareQRCodeImage?()
        }).disposed(by: disposeBag)
    }

    private func saveQRImage() {
        self.saveQRCodeImage?()
    }
}
