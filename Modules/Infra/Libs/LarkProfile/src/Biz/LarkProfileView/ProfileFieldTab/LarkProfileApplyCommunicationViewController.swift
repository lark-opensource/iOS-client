//
//  LarkProfileApplyCommunicationViewController.swift
//  LarkProfile
//
//  Created by ByteDance on 2023/2/13.
//

import UIKit
import LarkUIKit
import RxSwift
import RxCocoa
import UniverseDesignDialog
import UniverseDesignInput
import UniverseDesignIcon
import LarkContainer
import LKCommonsLogging
import UniverseDesignToast

public final class LarkProfileApplyCommunicationViewController: BaseUIViewController, UDMultilineTextFieldDelegate {

    static let logger = Logger.log(LarkProfileApplyCommunicationViewController.self, category: "LarkProfileApplyCommunicationViewController")
    public var userResolver: LarkContainer.UserResolver
    private let profileAPI: LarkProfileAPI
    private let userId: String
    private var reasonText: String = ""
    let disposeBag = DisposeBag()
    private var dismissCallback: ((Bool) -> Void)?

    public override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgBodyOverlay)
    }

    private(set) lazy var cancelItem: UIBarButtonItem = {
        let btnItem = LKBarButtonItem(title: BundleI18n.LarkProfile.Lark_Core_AddToPhoneContacts_Cancel_Button)
        btnItem.setBtnColor(color: UIColor.ud.textTitle)
        btnItem.button.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        return btnItem
    }()

    private(set) lazy var sendItem: UIBarButtonItem = {
        let btnItem = LKBarButtonItem(title: BundleI18n.LarkProfile.Lark_Legacy_Send)
        btnItem.setProperty(font: UIFont.systemFont(ofSize: Cons.reasonTextFont), alignment: .right)
        btnItem.setBtnColor(color: UIColor.ud.textLinkNormal)
        btnItem.button.addTarget(self, action: #selector(didTapSend), for: .touchUpInside)
        return btnItem
    }()

    // 最大字符数(中文:英文 -> 1:1)
    private var maxLength = 50

    private lazy var containView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        view.layer.cornerRadius = Cons.containRadius
        view.layer.borderWidth = Cons.containBorderWidth
        view.layer.borderColor = UIColor.ud.primaryContentDefault.cgColor
        return view
    }()

    private lazy var applicationReasonTextField: UDMultilineTextField = {
        let config = UDMultilineTextFieldUIConfig(textColor: UIColor.ud.textTitle,
                                                  font: UIFont.systemFont(ofSize: Cons.reasonTextFont),
                                                  minHeight: Cons.reasonTextMinHeight)
        let textField = UDMultilineTextField(config: config)
        textField.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        textField.textContainerInset = .zero
        textField.setContentCompressionResistancePriority(.required, for: .vertical)
        textField.setContentHuggingPriority(.required, for: .vertical)
        textField.placeholder = BundleI18n.LarkProfile.Lark_IM_SendMessageRequest_Placeholder
        return textField
    }()

    private lazy var countLabel: UILabel = {
        let countLabel = UILabel()
        countLabel.font = UIFont.systemFont(ofSize: Cons.reasonConutNumFont)
        countLabel.textColor = UIColor.ud.textPlaceholder
        countLabel.textAlignment = .right
        countLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        countLabel.setContentHuggingPriority(.required, for: .vertical)
        countLabel.text = "0/\(maxLength)"
        return countLabel
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        let icon = UDIcon.getIconByKey(.closeOutlined, size: Cons.iconSize).ud.withTintColor(UIColor.ud.iconN3)
        button.setImage(icon, for: .normal)
        button.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
        return button
    }()

    public init(userResolver: UserResolver,
                userId: String,
                dismissCallback: ((Bool) -> Void)? = nil) throws {
        self.userResolver = userResolver
        self.userId = userId
        self.profileAPI = try userResolver.resolve(assert: LarkProfileAPI.self)
        self.dismissCallback = dismissCallback
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.title = BundleI18n.LarkProfile.Lark_IM_SendMessageRequest_Button
        self.navigationItem.leftBarButtonItem = cancelItem
        self.navigationItem.rightBarButtonItem = sendItem
        self.view?.backgroundColor = UIColor.ud.bgBodyOverlay
        setupSubViews()
    }

    private func setupSubViews() {
        view.addSubview(containView)
        containView.addSubview(applicationReasonTextField)
        containView.addSubview(countLabel)
        containView.addSubview(closeButton)

        containView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(Cons.vMargin)
            make.leading.equalToSuperview().offset(Cons.hMargin)
            make.trailing.equalToSuperview().offset(-Cons.hMargin)
            make.height.equalTo(Cons.containHeight)
        }
        closeButton.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().offset(-Cons.vMargin)
            make.bottom.equalToSuperview().offset(-Cons.vMargin)
            make.size.equalTo(Cons.iconSize)
        }
        countLabel.snp.makeConstraints { (make) in
            make.trailing.equalTo(closeButton.snp.leading).offset(-Cons.vMargin)
            make.leading.equalToSuperview().offset(Cons.vMargin)
            make.centerY.equalTo(closeButton.snp.centerY)
        }
        applicationReasonTextField.snp.makeConstraints { (make) in
            make.leading.top.equalToSuperview().offset(Cons.vMargin)
            make.right.equalToSuperview().offset(-Cons.vMargin)
            make.bottom.equalTo(closeButton.snp.top).offset(-Cons.vMargin)
        }
        applicationReasonTextField.input.delegate = self
    }

    @objc
    private func didTapCancel() {
        dismiss(isSuccess: false)
    }

    private func dismiss(isSuccess: Bool = true) {
        self.dismissCallback?(isSuccess)
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    @objc
    private func didTapSend() {
        Self.logger.info("did tap send apply toUserId: \(userId)")
        let loadingHUD = UDToast.showDefaultLoading(with: BundleI18n.LarkProfile.Lark_Legacy_Sending, on: self.view, disableUserInteraction: true)
        self.profileAPI.sendApplyCommunicationApplicationBy(userID: userId, reason: reasonText)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                loadingHUD.remove()
                guard let self = self, let window = self.view.window else { return }
                UDToast.showSuccess(with: BundleI18n.LarkProfile.Lark_IM_MessageRequestSent_Toast, on: window)
                self.dismiss()
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                Self.logger.info("send apply communication application failure error: \(error)")
                UDToast.showFailure(
                    with: BundleI18n.LarkProfile.Lark_Legacy_ActionFailedTryAgainLater,
                    on: self.view,
                    error: error.transformToAPIError()
                )
            }).disposed(by: self.disposeBag)
            
    }

    @objc
    private func didTapCloseButton() {
        guard !applicationReasonTextField.text.isEmpty else {
            return
        }
        applicationReasonTextField.text = ""
        textViewDidChange(text: "")
    }

    private func updateTextCount(_ textCount: Int) {
        let displayCount = Int(ceil(Float(textCount)))
        let totalCount = Int(ceil(Float(maxLength)))
        countLabel.text = "\(displayCount)/\(totalCount)"
    }

    private func textViewDidChange(text: String) {
        reasonText = text.isEmpty ? "" : text
    }

    //MARK: UDMultilineTextFieldDelegate
    @objc
    public func textViewDidChange(_ textView: UITextView) {
        let limit = maxLength
        var selectedLength = 0
        if let range = textView.markedTextRange {
            selectedLength = textView.offset(from: range.start, to: range.end)
        }
        let contentLength = max(0, textView.text.count - selectedLength)
        let validText = String(textView.text.prefix(contentLength))
        if ProfileProcessStringUtil.getLength(forText: validText, characterRatio: Cons.characterRatio) > limit {
            let trimmedText = ProfileProcessStringUtil.getPrefix(limit, forText: textView.text, characterRatio: Cons.characterRatio)
            textView.text = trimmedText
            updateTextCount(ProfileProcessStringUtil.getLength(forText: trimmedText, characterRatio: Cons.characterRatio))
            textViewDidChange(text: trimmedText)
            UDToast.showTips(with: BundleI18n.LarkProfile.Lark_IM_MaxCharLimitExceeded_Toast, on: self.view)
        } else {
            updateTextCount(ProfileProcessStringUtil.getLength(forText: validText, characterRatio: Cons.characterRatio))
            textViewDidChange(text: validText)
        }
        // Adjust content offset to avoid UI bug under iOS13
        if #available(iOS 13, *) {} else {
            let range = NSRange(location: (textView.text as NSString).length - 1, length: 1)
            textView.scrollRangeToVisible(range)
        }
    }
}

extension LarkProfileApplyCommunicationViewController {
    enum Cons {
        static var reasonTextFont: CGFloat { 16 }
        static var reasonTextMinHeight: CGFloat { 22 }
        static var reasonConutNumFont: CGFloat { 12 }
        static var iconSize: CGSize { CGSize(width: 14, height: 14) }
        static var containRadius: CGFloat { 6 }
        static var containBorderWidth: CGFloat { 1 }
        static var hMargin: CGFloat { 16 }
        static var vMargin: CGFloat { 12 }
        static var containHeight: CGFloat { 136 }
        static var characterRatio: Int { 1 }
    }
}
