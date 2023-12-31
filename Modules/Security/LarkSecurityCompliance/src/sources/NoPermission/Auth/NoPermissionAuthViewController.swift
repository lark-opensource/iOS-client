//
//  NoPermissionAuthViewController.swift
//  LarkSecurityAndCompliance
//
//  Created by qingchun on 2022/4/7.
//

import UIKit
import SnapKit
import RxCocoa
import RxSwift
import LarkLocalizations
import LarkContainer
import LarkUIKit
import LarkAlertController
import LarkReleaseConfig
import UniverseDesignButton
import UniverseDesignColor
import UniverseDesignIcon
import LarkSecurityComplianceInfra

final class NoPermissionAuthViewController: BaseViewController<NoPermissionAuthViewModel>, UITextViewDelegate {

    private let bag = DisposeBag()
    private let container = Container(frame: LayoutConfig.bounds)
    private weak var alertController: LarkAlertController?

    override func loadView() {
        view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgFloat
        view.endEditing(true)
        navigationController?.setNavigationBarHidden(true, animated: false)
        isNavigationBarHidden = true
        container.clickView.delegate = self
        Logger.info("show auth view controller")

        container.backButton.rx.tap
            .bind(to: viewModel.backClicked)
            .disposed(by: bag)
        container.denyButton.rx.tap
            .bind(to: viewModel.denyButtonClicked)
            .disposed(by: bag)
        container.checkboxButton.rx.tap
            .map({ [weak self] in self?.container.checkboxButton.isSelected ?? false })
            .bind(to: viewModel.checkboxClicked)
            .disposed(by: bag)
        container.agreeButton.rx.tap
            .bind(to: viewModel.agreeClicked)
            .disposed(by: bag)
        viewModel.checkbox
            .bind(to: container.checkboxButton.rx.isSelected)
            .disposed(by: bag)
        viewModel.dismissVC
            .bind { [weak self] in self?.dismiss(animated: true) }
            .disposed(by: bag)
        viewModel.showAgreeAlert
            .bind { [weak self] () in
                guard let `self` = self else { return }
                self.showPolicyAlert(delegate: self, completion: { value in
                    if value {
                        self.container.checkboxButton.sendActions(for: .touchUpInside)
                        self.container.agreeButton.sendActions(for: .touchUpInside)
                    }
                })
            }
            .disposed(by: bag)
    }

    // MARK: - UITextViewDelegate
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard let host = URL.host else { return false }
        alertController?.dismiss(animated: true)
        let type = NoPermissionAuthViewModel.TextLink(rawValue: host) ?? .service
        viewModel.textLinkClicked.accept(type)
        return true
    }

    func showPolicyAlert(delegate: UITextViewDelegate, completion: @escaping ((Bool) -> Void)) {
        let controller = LarkAlertController()
        controller.setTitle(text: I18N.Lark_Conditions_TipsNotice)
        let label = LinkClickableLabel.default(with: delegate)
        label.attributedText = self.alertAgreePolicyTip
        label.textAlignment = .center
        controller.setFixedWidthContent(view: label)
        controller.addSecondaryButton(
            text: I18N.Lark_Conditions_CancelAuthorizeButton,
            dismissCompletion: {
                completion(false)
            })
        controller.addPrimaryButton(
            text: I18N.Lark_Conditions_AgreeAndAuthorizeButton,
            dismissCompletion: {
                completion(true)
            })
        present(controller, animated: true, completion: nil)
        alertController = controller
    }

    var alertAgreePolicyTip: NSAttributedString {
        let font: UIFont = UIFont.systemFont(ofSize: 16.0)
        let res = I18N.Lark_Conditions_PleaseReadAndAgree(I18N.Lark_Conditions_UserAgreement, I18N.Lark_Conditions_PrivacyPrivy)
        let attributedString = NSMutableAttributedString(string: res, attributes: [.foregroundColor: UIColor.ud.textTitle, .font: font])
        let termAttributed: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.ud.primaryContentDefault,
            .link: URL(string: "://" + NoPermissionAuthViewModel.TextLink.service.rawValue)!
        ]
        let privacyAttributed: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.ud.primaryContentDefault,
            .link: URL(string: "://" + NoPermissionAuthViewModel.TextLink.privacy.rawValue)!
        ]
        do {
            let rng = (res as NSString).range(of: I18N.Lark_Conditions_UserAgreement)
            if rng.location != NSNotFound {
                attributedString.addAttributes(termAttributed, range: rng)
            }
        }
        do {
            let rng = (res as NSString).range(of: I18N.Lark_Conditions_PrivacyPrivy)
            if rng.location != NSNotFound {
                attributedString.addAttributes(privacyAttributed, range: rng)
            }
        }
        return attributedString
    }

}

private final class Container: UIView {

    private var brandName: String { LanguageManager.bundleDisplayName }

    let bgView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()

    let backButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: UIColor.ud.iconN1), for: .normal)
        return button
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = I18N.Lark_Conditions_DeviceInfo
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 26, weight: .semibold)
        return label
    }()

    lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.text = I18N.Lark_Conditions_BecauseCompanyNow(brandName)
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        return label
    }()

    lazy var agreeLabel: UILabel = {
        let label = UILabel()
        label.text = I18N.Lark_Conditions_BrandDevicing(brandName)
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        return label
    }()

    let deviceView = ItemView(title: I18N.Lark_Conditions_BelongsDevice, detail: I18N.Lark_Conditions_CompanyAndPersonal)
    let deviceStatusView = ItemView(title: I18N.Lark_Conditions_StatusOfDevice, detail: I18N.Lark_Conditions_UntrustedNot)

    let agreeButton: UIButton = {
        var config = UDButtonUIConifg.primaryBlue
        let button = UDButton(config)
        button.setTitle(I18N.Lark_Conditions_ButtAuthorize, for: .normal)
        return button
    }()

    let denyButton: UIButton = {
        var config = UDButtonUIConifg.secondaryGray
        let button = UDButton(config)
        button.setTitle(I18N.Lark_Conditions_ButUnauthorize, for: .normal)
        return button
    }()

    let checkboxButton: UIButton = {
        let button = UIButton(type: .custom)
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.setImage(BundleResources.LarkSecurityCompliance.checkbox_selected, for: .selected)
        button.setImage(UDIcon.getIconByKey(.ellipseOutlined, iconColor: UIColor.ud.rgb("#8F959E")), for: .normal)
        return button
    }()

    let clickView: UITextView = {
        let view = UITextView()
        view.textColor = .black
        view.isEditable = false
        view.isScrollEnabled = false
        view.dataDetectorTypes = [.link]
        view.contentInsetAdjustmentBehavior = .never
        view.backgroundColor = .clear
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(bgView)

        addSubview(backButton)
        bgView.addSubview(titleLabel)
        bgView.addSubview(subTitleLabel)
        bgView.addSubview(agreeLabel)
        bgView.addSubview(agreeButton)
        bgView.addSubview(deviceView)
        bgView.addSubview(deviceStatusView)
        bgView.addSubview(denyButton)
        bgView.addSubview(checkboxButton)
        bgView.addSubview(clickView)
        clickView.attributedText = policyTip()

        bgView.snp.makeConstraints { make in
            make.centerX.top.height.equalToSuperview()
            if Display.phone {
                make.width.equalToSuperview()
            } else {
                let width = min(400, LayoutConfig.bounds.width)
                make.width.equalTo(width)
            }
        }
        backButton.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.left.equalToSuperview()
            #if os(visionOS)
            make.top.equalTo(12)
            #else
            make.top.equalTo(UIApplication.shared.statusBarFrame.height + 12)
            #endif
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.equalTo(backButton.snp.bottom).offset(30)
        }
        subTitleLabel.snp.makeConstraints { make in
            make.left.right.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
        }
        agreeLabel.snp.makeConstraints { make in
            make.left.right.equalTo(titleLabel)
            make.top.equalTo(subTitleLabel.snp.bottom).offset(20)
        }
        deviceView.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.equalTo(agreeLabel.snp.bottom).offset(20)
            make.height.equalTo(48)
        }
        deviceStatusView.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.equalTo(deviceView.snp.bottom).offset(20)
            make.height.equalTo(48)
        }
        denyButton.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.height.equalTo(48)
            make.bottom.equalTo(-12 - LayoutConfig.safeAreaInsets.bottom)
        }
        agreeButton.snp.makeConstraints { make in
            make.left.right.height.equalTo(denyButton)
            make.bottom.equalTo(denyButton.snp.top).offset(-16)
        }
        checkboxButton.snp.makeConstraints { make in
            make.left.equalTo(denyButton)
            make.size.equalTo(24)
            make.bottom.equalTo(agreeButton.snp.top).offset(-16)
        }
        clickView.snp.makeConstraints { make in
            make.left.equalTo(checkboxButton.snp.right)
            make.right.equalTo(-16)
            make.centerY.equalTo(checkboxButton)
            make.height.greaterThanOrEqualTo(20)
        }
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !Display.phone {
            let width = min(400, bounds.width)
            bgView.snp.updateConstraints { make in
                make.width.equalTo(width)
            }
        }
    }

    func policyTip() -> NSAttributedString {
        let font: UIFont = UIFont.systemFont(ofSize: 14.0)
        let res = I18N.Lark_Conditions_IAgree(I18N.Lark_Conditions_UserAgreement, I18N.Lark_Conditions_PrivacyPrivy)
        let attributedString = NSMutableAttributedString(string: res, attributes: [NSAttributedString.Key.font: font,
                                                                                   .foregroundColor: UIColor.ud.textPlaceholder])
        // .tip(str: res, color: UIColor.ud.textPlaceholder, font: font, aligment: .left)
        let termAttributed: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.ud.primaryContentDefault,
            .link: URL(string: "://" + NoPermissionAuthViewModel.TextLink.service.rawValue)!
        ]
        let privacyAttributed: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.ud.primaryContentDefault,
            .link: URL(string: "://" + NoPermissionAuthViewModel.TextLink.privacy.rawValue)!
        ]
        do {
            let rng = (res as NSString).range(of: I18N.Lark_Conditions_UserAgreement)
            if rng.location != NSNotFound {
                attributedString.addAttributes(termAttributed, range: rng)
            }
        }
        do {
            let rng = (res as NSString).range(of: I18N.Lark_Conditions_PrivacyPrivy)
            if rng.location != NSNotFound {
                attributedString.addAttributes(privacyAttributed, range: rng)
            }
        }
        return attributedString
    }
}

final class ItemView: UIView {

    let dotView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.textPlaceholder
        view.layer.cornerRadius = 3
        return view
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        return label
    }()

    let detailLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        return label
    }()

    init(title: String?, detail: String?) {
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))// 占位frame

        addSubview(dotView)
        addSubview(titleLabel)
        addSubview(detailLabel)

        titleLabel.text = title
        detailLabel.text = detail

        dotView.snp.makeConstraints { make in
            make.size.equalTo(6)
            make.left.equalToSuperview()
            make.centerY.equalTo(titleLabel)
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(dotView.snp.right).offset(12)
            make.top.equalToSuperview()
            make.right.lessThanOrEqualTo(-16)
        }
        detailLabel.snp.makeConstraints { make in
            make.left.equalTo(dotView.snp.right).offset(12)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.right.lessThanOrEqualTo(-16)
        }
    }

    required init?(coder: NSCoder) {
        return nil
    }

}

extension LarkAlertController {

    func setFixedWidthContent(view: UIView) {
        let contentWidth: CGFloat = 303
        let contentPadding: UIEdgeInsets = UIEdgeInsets(top: 16, left: 20, bottom: 18, right: 20)
        let container = UIView()
        container.addSubview(view)
        view.snp.makeConstraints { (make) in
            make.width.equalTo(contentWidth - contentPadding.left - contentPadding.right).priority(.high)
            make.edges.equalToSuperview()
        }
        setContent(view: container, padding: contentPadding)
    }
}
