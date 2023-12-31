//
//  OpenAPIAuthErrorViewController.swift
//  LarkAccount
//
//  Created by au on 2023/6/8.
//

import UIKit
import LarkUIKit
import LKCommonsLogging
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignFont

final class OpenAPIAuthErrorViewController: UIViewController {

    private static let logger = Logger.log(OpenAPIAuthErrorViewController.self, category: "LarkAccount")

    private let code: String
    private let message: String
    private let logID: String?
    private let retryAction: (() -> Void)
    private let cancelAction: (() -> Void)

    init(code: String, message: String, logID: String?, retryAction: @escaping (() -> Void), cancelAction: @escaping (() -> Void)) {
        self.code = code
        self.message = message
        self.logID = logID
        self.retryAction = retryAction
        self.cancelAction = cancelAction
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.ud.bgLogin
        setupNavigation()
        setupContents()

        Self.logger.info("n_action_open_api_service", body: "error page view did load")
    }

    private func setupContents() {
        let imageView: UIImageView = UIImageView(image: EmptyBundleResources.image(named: "emptyNegativeError"))
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(100)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(84)
        }

        view.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(Display.pad ? -12 : 0)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }

        view.addSubview(retryButton)
        retryButton.snp.makeConstraints { make in
            make.bottom.equalTo(cancelButton.snp.top).offset(-12)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }

        let titleLabel = UILabel()
        titleLabel.text = I18N.Lark_Passport_ThirdPartyAppAuthorization_AuthError_ErrorCodeAndInfo(code, message)
        titleLabel.font = UDFont.title3
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(imageView.snp.bottom).offset(20)
        }

        let rawSubtitle = I18N.Lark_Passport_ThirdPartyAppAuthorization_AuthError_LogidInfo(logid: logID ?? "")
        let attrSubtitle = NSMutableAttributedString(string: rawSubtitle)
        attrSubtitle.addAttributes(Self.subtitleAttributes, range: NSRange(location: 0, length: attrSubtitle.length))
        let subtitleLabel = UILabel()
        subtitleLabel.numberOfLines = 0
        subtitleLabel.attributedText = attrSubtitle
        view.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.bottom.equalTo(retryButton.snp.top).offset(-24)
        }
    }

    private func setupNavigation() {
        let closeButton = UIButton(type: .custom)
        closeButton.setImage(BundleResources.UDIconResources.closeOutlined, for: .normal)
        closeButton.addTarget(self, action: #selector(onCloseButtonTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        closeButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(8)
            make.left.equalToSuperview().offset(12)
            make.width.height.equalTo(32)
        }

        let titleLabel = UILabel()
        titleLabel.text = I18N.Lark_Login_SSO_AuthorizationTitle()
        titleLabel.textColor = UDColor.textTitle
        titleLabel.textAlignment = .center
        titleLabel.font = UDFont.title3
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.height.equalTo(24)
            make.top.equalToSuperview().offset(12)
            make.left.right.equalToSuperview().inset(64)
        }

        let separator = UIView()
        separator.backgroundColor = UDColor.lineDividerDefault
        view.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(47)
            make.height.equalTo(0.5)
        }
    }

    @objc
    private func onCloseButtonTapped() {
        Self.logger.info("n_action_open_api_service", body: "error page tap close button")
        dismiss(animated: true) { [self] in
            cancelAction()
        }
    }

    @objc
    private func onRetryButtonTapped() {
        Self.logger.info("n_action_open_api_service", body: "error page tap retry button")
        dismiss(animated: true) { [self] in
            retryAction()
        }
    }

    @objc
    private func onCancelButtonTapped() {
        Self.logger.info("n_action_open_api_service", body: "error page tap cancel button")
        dismiss(animated: true) { [self] in
            cancelAction()
        }
    }

    // MARK: - Property

    private lazy var retryButton: NextButton = {
        let confirmButton = NextButton(title: I18N.Lark_Passport_ThirdPartyAppAuthorization_AuthError_RefreshTitle, style: .roundedRectBlue)
        confirmButton.addTarget(self, action: #selector(onRetryButtonTapped), for: .touchUpInside)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        return confirmButton
    }()

    private lazy var cancelButton: NextButton = {
        let button = NextButton(title: I18N.Lark_Passport_ThirdPartyAppAuthorization_Button_Cancel, style: .roundedRectWhiteWithGrayOutline)
        button.addTarget(self, action: #selector(onCancelButtonTapped), for: .touchUpInside)
        return button
    }()

    static var subtitleAttributes: [NSAttributedString.Key: Any] {
        let centerStyle = NSMutableParagraphStyle()
        centerStyle.alignment = NSTextAlignment.center
        centerStyle.lineSpacing = 4
        return [NSAttributedString.Key.paragraphStyle: centerStyle,
                NSAttributedString.Key.font: UDFont.body0,
                NSAttributedString.Key.foregroundColor: UIColor.ud.textCaption]
    }

}

extension OpenAPIAuthErrorViewController {
    static func calculateErrorSheetHeight(code: String, message: String, logID: String?) -> CGFloat {
        // navigation bar: 48
        // image: 156
        // buttons: 172
        let width = UIScreen.main.bounds.width - 32
        let title = I18N.Lark_Passport_ThirdPartyAppAuthorization_AuthError_ErrorCodeAndInfo(code, message)
        let titleHeight = title.height(withConstrainedWidth: width, attributes: [.font: UDFont.title3])
        let subtitle = I18N.Lark_Passport_ThirdPartyAppAuthorization_AuthError_LogidInfo(logid: logID ?? "")
        let subtitleHeight = subtitle.height(withConstrainedWidth: width, attributes: subtitleAttributes)
        let result: CGFloat = 48 + 156 + titleHeight + 10 + subtitleHeight + 172
        return result
    }

    static func height(for text: String, with constrainedWidth: CGFloat, attributes: [NSAttributedString.Key: Any]) -> CGFloat {
        let constraintRect = CGSize(width: constrainedWidth, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)

        return ceil(boundingBox.height)
    }
}
