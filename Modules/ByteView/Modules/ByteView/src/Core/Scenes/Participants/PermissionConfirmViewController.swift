//
//  PermissionConfirmViewController.swift
//  ByteView
//
//  Created by yangyao on 2020/7/21.
//

import UIKit
import RxSwift
import RxCocoa
import ByteViewCommon
import ByteViewNetwork
import ByteViewTracker
import UniverseDesignIcon

class PermissionApplyViewModel {
    let userId: String
    private let startInfo: VideoChatInfo

    var sponsorId: String {
        return startInfo.sponsor.id
    }
    var sponsorType: ParticipantType {
        return startInfo.sponsor.type
    }
    var meetingId: String {
        return startInfo.id
    }
    var topic: String {
        return startInfo.settings.topic
    }

    private let sponsorNameSubject = BehaviorSubject<String?>(value: nil)
    var sponsorName: Observable<String> {
        sponsorNameSubject.asObservable().compactMap { $0 }
    }

    let httpClient: HttpClient

    deinit {
        Logger.ui.info("PermissionApplyViewModel deinit")
    }

    init(userId: String, meeting: InMeetMeeting) {
        self.userId = userId
        self.startInfo = meeting.info
        self.httpClient = meeting.httpClient
        httpClient.participantService.participantInfo(pid: startInfo.sponsor, meetingId: meeting.meetingId) { [weak self] ap in
            self?.sponsorNameSubject.onNext(ap.name)
        }
    }
}

extension PermissionApplyViewController {
    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
}

class PermissionApplyViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    private let disposeBag: DisposeBag = DisposeBag()

    private lazy var reasonForApplyLabel: UILabel = {
        return getDescriptionLabel(text: I18n.View_G_ContactRequestMessage)
    }()

    private lazy var reasonTextView: UITextView = {
        let textView = UITextView()
        textView.delegate = self
        textView.textAlignment = .left
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textColor = UIColor.ud.textTitle
        textView.backgroundColor = .clear
        textView.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 4
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        return textView
    }()

    private lazy var aliasDescriptionLabel: UILabel = {
        return getDescriptionLabel(text: I18n.View_G_EditAlias)
    }()

    private lazy var applicationInputView: UITextField = {
        let textField = UITextField()
        textField.delegate = self
        textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        textField.textAlignment = .left
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.clearButtonMode = .whileEditing
        textField.textColor = UIColor.ud.textTitle
        textField.backgroundColor = .clear
        textField.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 4
        // 占位View
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 48))
        textField.leftView = leftView
        textField.leftViewMode = .always
        return textField
    }()

    private lazy var barCloseButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: .ud.iconN1, size: CGSize(width: 24, height: 24)), for: .normal)
        button.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: .ud.iconN3, size: CGSize(width: 24, height: 24)), for: .highlighted)
        button.addTarget(self, action: #selector(closeViewController), for: .touchUpInside)
        return button
    }()

    private lazy var rightButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentLoading, for: .highlighted)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.setTitle(I18n.View_G_Send, for: .normal)
        button.addTarget(self, action: #selector(sendFriendApplication), for: .touchUpInside)
        return button
    }()

    let viewModel: PermissionApplyViewModel
    init(viewModel: PermissionApplyViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func closeViewController() {
        self.navigationController?.popViewController(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = I18n.View_M_AddContactNow
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: barCloseButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)

        view.backgroundColor = UIColor.ud.bgBody


        view.addSubview(reasonForApplyLabel)
        view.addSubview(reasonTextView)
        view.addSubview(aliasDescriptionLabel)
        view.addSubview(applicationInputView)

        reasonForApplyLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(24)
            make.left.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.right.equalTo(view.safeAreaLayoutGuide).offset(-16)
            make.height.equalTo(22)
        }
        reasonTextView.snp.makeConstraints { (make) in
            make.left.right.equalTo(reasonForApplyLabel)
            make.top.equalTo(reasonForApplyLabel.snp.bottom).offset(8)
            make.height.equalTo(108)
        }
        aliasDescriptionLabel.snp.makeConstraints { (make) in
            make.top.equalTo(reasonTextView.snp.bottom).offset(24)
            make.left.right.equalTo(reasonForApplyLabel)
            make.height.equalTo(22)
        }
        applicationInputView.snp.makeConstraints { (make) in
            make.top.equalTo(aliasDescriptionLabel.snp.bottom).offset(8)
            make.left.right.equalTo(reasonForApplyLabel)
            make.height.equalTo(48)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let nav = navigationController, nav == self.parent else {
            return
        }
        nav.setNavigationBarHidden(false, animated: animated)
    }

    private func getDescriptionLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.numberOfLines = 2
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .left
        return label
    }

    @objc
    private func sendFriendApplication() {
        VCTracker.post(name: .authorize_collaboration_request, params: ["number": 1, "scene": "vc_ongoing_confirm"])

        let httpClient = viewModel.httpClient
        viewModel.sponsorName.flatMapLatest { [weak self] (sponsorName) -> Observable<Void> in
            guard let self = self else { return .empty() }
            let request = SendChatApplicationRequest(
                userId: self.viewModel.userId,
                userAlias: self.applicationInputView.text ?? "",
                sender: self.viewModel.topic.isEmpty ? sponsorName : "",
                senderId: self.viewModel.sponsorId,
                sourceId: self.viewModel.meetingId,
                sourceName: self.viewModel.topic,
                extraMessage: self.reasonTextView.text ?? "")
            return RxTransform.single {
                httpClient.send(request, completion: $0)
            }.asObservable()
        }
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] _ in
            Toast.show(I18n.View_G_RequestSentShort)
            Logger.ui.info("addContactRelation success")
            self?.navigationController?.popViewController(animated: true)
        }, onError: { (error) in
            Logger.ui.info("addContactRelation error!", error: error)
            guard let errorInfo = error as? RustBizError else {
                return
            }
            Toast.show("\(errorInfo.displayMessage)")
        }).disposed(by: disposeBag)
    }

    @objc
    func textDidChange() {
        guard let text = applicationInputView.text else {
            return
        }
        if let selectedRange = applicationInputView.markedTextRange {
            let position = applicationInputView.position(from: selectedRange.start, offset: 0)
            if position == nil {
                if text.count > 50 {
                    applicationInputView.text = String(text[0..<50])
                }
            }
        } else {
            if text.count > 50 {
                applicationInputView.text = String(text[0..<50])
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

    private func dismissSelf() {
        navigationController?.popViewController(animated: true)
    }
}

extension PermissionApplyViewController {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.becomeFirstResponder()
        textField.layer.ud.setBorderColor(UIColor.ud.primaryFillHover)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        textField.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
    }
}


extension PermissionApplyViewController {
    func textViewDidChange(_ textView: UITextView) {
        guard let text = textView.text else {
            return
        }
        var attributedString: NSAttributedString?
        if let selectedRange = textView.markedTextRange {
            let position = textView.position(from: selectedRange.start, offset: 0)
            if position == nil {
                if text.count > 100 {
                    attributedString = NSAttributedString(string: String(text[0..<100]), config: .body)
                } else {
                    attributedString = NSAttributedString(string: text, config: .body)
                }
            }
        } else {
            if text.count > 100 {
                attributedString = NSAttributedString(string: String(text[0..<100]), config: .body)
            } else {
                attributedString = NSAttributedString(string: text, config: .body)
            }
        }

        guard let attributedString = attributedString else {
            return
        }

        let mutableAttr = NSMutableAttributedString(attributedString: attributedString)
        mutableAttr.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle],
                                  range: NSRange(location: 0, length: mutableAttr.string.count))
        textView.attributedText = mutableAttr
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.layer.ud.setBorderColor(UIColor.ud.primaryFillHover)

    }
    func textViewDidEndEditing(_ textView: UITextView) {
        textView.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
    }
}
