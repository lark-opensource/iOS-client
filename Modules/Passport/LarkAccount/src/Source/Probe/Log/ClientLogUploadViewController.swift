//
//  ClientLogUploadViewController.swift
//  LarkAccount
//
//  Created by au on 2021/9/22.
//

import LarkAccountInterface
import LarkContainer
import LarkUIKit
import LKCommonsLogging
import Reachability
import RxCocoa
import RxSwift
import UniverseDesignButton
import UniverseDesignDialog
import UniverseDesignEmpty
import UniverseDesignFont
import UniverseDesignInput

final class ClientLogUploadViewController: PassportBaseViewController {

    private static let logger = Logger.log(ClientLogUploadViewController.self, category: "ClientLogUploadViewController")

    enum UploadState {
        /// 未满足上传条件，token 没输入或者不符合其它要求，button 置灰
        case pending
        /// 满足上传条件，button 高亮，等待用户确定
        case ready
        /// 正在上传中，button loading，输入框不可输入
        case uploading
        /// 上传成功
        case success
        /// 上传失败，输入框底部提示错误文案，button 置灰
        case failure(PackAndUploadLogFailedReason)
    }

    enum UploadDialogScene {
        /// 上传时关闭
        case uploadingClose
        /// 非 Wi-Fi 时上传
        case uploadingNonWifi
        /// 失败 - 通用错误
        case failureGeneral
        /// 失败 - 已有上传任务
        case failureOtherTaskRunning
    }

    private var state: UploadState = .pending {
        didSet {
            switch state {
            case .pending:
                asPending()
            case .ready:
                asReady()
            case .uploading:
                asUploading()
            case .success:
                asSuccess()
            case .failure(let reason):
                asFailure(reason)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        transitionState(to: .pending)

        FetchClientLogHelper.progress
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] progress in
                self?.updateProgress(Int(progress))
            })
            .disposed(by: disposeBag)
    }

    private func setupViews() {
        closeButton.rx
            .tap
            .subscribe { [unowned self] _ in
                self.close()
            }
            .disposed(by: disposeBag)
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(Display.pad ? 16 : 10)
            make.size.equalTo(CGSize(width: BaseLayout.backHeight, height: BaseLayout.backHeight))
        }

        titleLabel.text = I18N.Lark_Passport_UploadLogForTroubleshoot_UploadLog_Title
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(closeButton.snp.bottom).offset(BaseLayout.titleLabelTop)
            make.left.right.equalToSuperview().inset(16)
            make.height.greaterThanOrEqualTo(BaseLayout.titleLabelHeight)
        }

        let subtitleRaw = I18N.Lark_Passport_UploadLogForTroubleshoot_UploadLog_Instructions_Desc.html2Attributed(font: .systemFont(ofSize: 14), forgroundColor: UIColor.ud.textCaption)
        let subtitle = NSMutableAttributedString(attributedString: subtitleRaw)
        subtitle.adjustLineHeight()
        detailLabel.attributedText = subtitle
        view.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
        }

        textField.input.rx
            .controlEvent(.editingChanged)
            .withLatestFrom(textField.input.rx.text.orEmpty)
            .subscribe(onNext: { [unowned self] token in
                self.validate(token)
            })
            .disposed(by: disposeBag)
        view.addSubview(textField)
        textField.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(detailLabel.snp.bottom).offset(24)
        }

        uploadButton.rx
            .tap
            .subscribe { [unowned self] _ in
                self.upload()
            }
            .disposed(by: disposeBag)
        view.addSubview(uploadButton)
        uploadButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(textField.snp.bottom).offset(16)
            make.height.equalTo(48)
        }

        let downloadLink = I18N.Lark_Passport_UploadLogForTroubleshoot_UploadLog_DownloadLog_TextButton
        let downloadTip = I18N.Lark_Passport_UploadLogForTroubleshoot_UploadLog_UnableToUpload_Text("{{placeholder}}")
        let downloadTipAttri = NSMutableAttributedString.tip(str: downloadTip, color: UIColor.ud.textPlaceholder)
        if let url = URL(string: shareLogPageLink) {
            let link = NSAttributedString.link(str: downloadLink, url: url, font: UIFont.systemFont(ofSize: 14.0))
            if let i = downloadTip.firstIndex(of: "{") {
                let index = downloadTip.distance(from: downloadTip.startIndex, to: i)
                downloadTipAttri.insert(link, at: index)
                let range = (downloadTipAttri.string as NSString).range(of: "{{placeholder}}")
                downloadTipAttri.deleteCharacters(in: range)
            }
        }
        shareLogLabel.attributedText = downloadTipAttri
        view.addSubview(shareLogLabel)
        shareLogLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(uploadButton.snp.bottom).offset(16)
        }
    }

    private func validate(_ token: String) {
        if case .failure = state {
            transitionState(to: .pending)
        }
        guard token.count >= 4 && token.count <= 6 else {
            transitionState(to: .pending)
            return
        }
        guard Double(token) != nil else {
            transitionState(to: .pending)
            return
        }
        transitionState(to: .ready)
    }

    private func upload() {

        func _upload() {
            guard let doubleValue = Double(textField.text ?? "") else {
                Self.logger.warn("n_action_client_log_upload_page: upload no token")
                return
            }
            transitionState(to: .uploading)
            Self.logger.info("n_action_client_log_upload_page: uploading")
            let token = UInt32(doubleValue)
            let api = PackAndUploadLogAPI()
            api.packAndUploadLog(token: token) { [weak self] reason in
                DispatchQueue.main.async {
                    if let reason = reason {
                        self?.transitionState(to: .failure(reason))
                    } else {
                        self?.transitionState(to: .success)
                    }
                }
            }
        }

        if let r = Reachability(), r.connection == .cellular {
            showDialog(.uploadingNonWifi) {
                _upload()
            }
            return
        }

        _upload()
    }

    func updateProgress(_ progress: Int) {
        guard case .uploading = state else {
            return
        }
        let value = max(min(100, progress), 0)
        let title = "\(value)% " + I18N.Lark_Passport_UploadLogForTroubleshoot_UploadLog_UploadInProgress_MainButton
        uploadButton.setTitle(title, for: .normal)
    }

    @objc
    private func close() {
        if case .uploading = state {
            showDialog(.uploadingClose) { [weak self] in
                self?.dismiss(animated: true)
            }
        } else {
            dismiss(animated: true)
        }
    }

    // MARK: - Properties

    private let shareLogPageLink = "//passportShareClientLog"
    private let disposeBag = DisposeBag()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(BundleResources.UDIconResources.closeOutlined.withRenderingMode(.alwaysOriginal), for: .normal)
        return button
    }()

    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 26, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 0
        return titleLabel
    }()

    private lazy var detailLabel: UITextView = {
        let label = LinkClickableLabel.default(with: self)
        label.textContainer.maximumNumberOfLines = 10
        label.textContainerInset = .zero
        label.textContainer.lineFragmentPadding = 0
        return label
    }()

    private let textField: UDTextField = {
        let textField = UDTextField()
        textField.config.isShowBorder = true
        textField.config.clearButtonMode = .whileEditing
        textField.input.keyboardType = .numberPad
        textField.placeholder = I18N.Lark_Passport_UploadLogForTroubleshoot_UploadLog_Placeholder
        return textField
    }()

    private let uploadButton: UDButton = {
        var config = UDButtonUIConifg.primaryBlue
        config.type = .big
        let button = UDButton(config)
        button.setTitle(I18N.Lark_Passport_UploadLogForTroubleshoot_UploadLog_Upload_MainButton, for: .normal)
        return button
    }()

    private lazy var shareLogLabel: LinkClickableLabel = {
        let label = LinkClickableLabel.default(with: self)
        label.textContainerInset = .zero
        label.textContainer.lineFragmentPadding = 0
        return label
    }()
}

// State Transition
extension ClientLogUploadViewController {

    private func transitionState(to newState: UploadState) {
        state = newState
    }

    private func asPending() {
        resetTextField()
        uploadButton.setTitle(I18N.Lark_Passport_UploadLogForTroubleshoot_UploadLog_Upload_MainButton, for: .normal)
        uploadButton.hideLoading()
        uploadButton.isEnabled = false
    }

    private func asReady() {
        resetTextField()
        uploadButton.hideLoading()
        uploadButton.isEnabled = true
    }

    private func asUploading() {
        textField.resignFirstResponder()
        textField.isUserInteractionEnabled = false
        textField.config.textColor = UIColor.ud.textPlaceholder
        textField.setStatus(.disable)
        uploadButton.showLoading()
    }

    private func asSuccess() {
        Self.logger.info("n_action_client_log_upload_page: state as success")
        textField.resignFirstResponder()
        if let from = PassportNavigator.topMostVC, from is UDDialog {
            from.dismiss(animated: true)
        }
        let config = UDEmptyConfig(titleText: I18N.Lark_Passport_UploadLogForTroubleshoot_LogUploaded_Title,
                                   description: UDEmptyConfig.Description(descriptionText: I18N.Lark_Passport_UploadLogForTroubleshoot_LogUploaded_Desc),
                                   type: .done,
                                   primaryButtonConfig: (I18N.Lark_Passport_UploadLogForTroubleshoot_LogUploaded_Close_Button, { [weak self] (_) in
            self?.dismiss(animated: true)
        }))
        let empty = UDEmptyView(config: config)
        view.addSubview(empty)
        empty.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func asFailure(_ reason: PackAndUploadLogFailedReason) {
        Self.logger.error("n_action_client_log_upload_page: state as failure \(reason.rawValue)")
        resetTextField()
        uploadButton.setTitle(I18N.Lark_Passport_UploadLogForTroubleshoot_UploadLog_Upload_MainButton, for: .normal)
        uploadButton.hideLoading()
        uploadButton.isEnabled = false
        switch reason {
        case .tokenExchangeFailed:
            textField.config.errorMessege = I18N.Lark_Passport_UploadLogForTroubleshoot_UploadLog_EnterValidCode_ErrorMessage
            textField.setStatus(.error)
        case .otherTaskRunning:
            showDialog(.failureOtherTaskRunning)
        default:
            showDialog(.failureGeneral)
        }
    }

    private func resetTextField() {
        textField.becomeFirstResponder()
        textField.isUserInteractionEnabled = true
        textField.config.textColor = UIColor.ud.textTitle
    }

    private func showDialog(_ scene: UploadDialogScene, action: (() -> Void)? = nil) {
        let dialog = UDDialog()
        switch scene {
        case .uploadingClose:
            dialog.setTitle(text: I18N.Lark_Passport_UploadLogForTroubleshoot_UploadLog_ClosePagePopUp_Title)
            dialog.setContent(text: I18N.Lark_Passport_UploadLogForTroubleshoot_UploadLog_ClosePagePopUp_Desc)
            dialog.addPrimaryButton(text: I18N.Lark_Passport_UploadLogForTroubleshoot_UploadLog_ClosePagePopUp_Close_Button, dismissCompletion: action)
            dialog.addSecondaryButton(text: I18N.Lark_Passport_UploadLogForTroubleshoot_UploadLog_ClosePagePopUp_Cancel_Button)
        case .uploadingNonWifi:
            dialog.setContent(text: I18N.Lark_Passport_UploadLogForTroubleshoot_UploadLog_NotConnectedToWifi_Desc)
            dialog.addPrimaryButton(text: I18N.Lark_Passport_UploadLogForTroubleshoot_UploadLog_NotConnectedToWifi_Upload_Button, dismissCompletion: action)
            dialog.addSecondaryButton(text: I18N.Lark_Passport_UploadLogForTroubleshoot_UploadLog_NotConnectedToWifi_Cancel_Button)
        case .failureGeneral:
            dialog.setTitle(text: I18N.Lark_Passport_UploadLogForTroubleshoot_UploadLog_UploadFailedTryNewCode_PopUp_Title)
            dialog.setContent(text: I18N.Lark_Passport_UploadLogForTroubleshoot_UploadLog_UploadFailedTryNewCode_ErrorMessage)
            dialog.addPrimaryButton(text: I18N.Lark_Passport_UploadLogForTroubleshoot_UploadLog_UploadFailedTryNewCode_PopUp_GotIt_Button)
        case .failureOtherTaskRunning:
            dialog.setTitle(text: I18N.Lark_Passport_UploadLogForTroubleshoot_UploadLog_UploadFailedTryNewCode_PopUp_Title)
            dialog.setContent(text: I18N.Lark_Passport_UploadLogForTroubleshoot_UploadLog_UploadInProgress_Toast)
            dialog.addPrimaryButton(text: I18N.Lark_Passport_UploadLogForTroubleshoot_UploadLog_UploadFailedTryNewCode_PopUp_GotIt_Button)
        }
        present(dialog, animated: true)
    }
}

extension ClientLogUploadViewController {
    func prefillToken(_ token: String) {
        textField.text = token
        guard token.count >= 4 && token.count <= 6 else {
            return
        }
        guard Double(token) != nil else {
            return
        }
        transitionState(to: .ready)
    }
}

extension ClientLogUploadViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        let text = URL.absoluteString
        if text.contains(shareLogPageLink) {
            FetchClientLogHelper.shareClientLog()
        }
        return false
    }
}
