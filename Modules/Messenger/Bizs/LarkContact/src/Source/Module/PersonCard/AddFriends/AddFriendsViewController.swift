//
//  AddFriendsViewController.swift
//  LarkContact
//
//  Created by 强淑婷 on 2020/7/14.
//

import Foundation
import UIKit
import LarkModel
import LarkUIKit
import RxSwift
import UniverseDesignToast
import UniverseDesignDialog
import LarkAccountInterface
import LarkSDKInterface
import LarkAlertController
import EENavigator
import LarkMessengerInterface
import LKCommonsLogging
import LarkContainer
import LKCommonsTracker
import Homeric
import RustPB

final class AddFriendsViewController: BaseUIViewController, UITextFieldDelegate, UITextViewDelegate, UserResolverWrapper {
    static let logger = Logger.log(AddFriendsViewController.self, category: "Module.IM.PersonCard")

    private let disposeBag: DisposeBag = DisposeBag()

    typealias SendFriendRequestCallBack = (_ sendRequestIsSucceed: Bool, _ error: Error?) -> Void
    var userResolver: LarkContainer.UserResolver
    private let passportUserService: PassportUserService
    @ScopedInjectedLazy private var chatterManager: ChatterManagerProtocol?

    private lazy var aliasDescriptionLabel: UILabel = {
        return self.getDescriptionLabel(text: BundleI18n.LarkContact.Lark_NewContacts_EditAlias)
    }()

    private lazy var applicationInputView: UITextField = {
        let applicationInputView = UITextField()
        applicationInputView.textAlignment = .left
        applicationInputView.font = UIFont.systemFont(ofSize: 16)
        applicationInputView.clearButtonMode = .whileEditing
        applicationInputView.delegate = self
        applicationInputView.textColor = UIColor.ud.N900
        applicationInputView.backgroundColor = UIColor.ud.N00
        applicationInputView.layer.borderColor = UIColor.ud.N400.cgColor
        applicationInputView.layer.borderWidth = 0.5
        applicationInputView.layer.cornerRadius = 4
        //占位View
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 48))
        applicationInputView.leftView = leftView
        applicationInputView.leftViewMode = .always
        return applicationInputView
    }()

    private lazy var reasonTextView: UITextView = {
        let reasonTextView = UITextView()
        reasonTextView.textAlignment = .left
        reasonTextView.font = UIFont.systemFont(ofSize: 16)
        reasonTextView.textColor = UIColor.ud.N900
        reasonTextView.backgroundColor = UIColor.ud.N00
        reasonTextView.layer.borderColor = UIColor.ud.N400.cgColor
        reasonTextView.layer.borderWidth = 0.5
        reasonTextView.layer.cornerRadius = 4
        reasonTextView.textContainerInset.left = 12
        reasonTextView.textContainerInset.right = 12
        // lineFragmentPadding默认值为5，手动设0与下方文本框对齐
        reasonTextView.textContainer.lineFragmentPadding = 0
        return reasonTextView
    }()

    private lazy var reasonForApplyLabel: UILabel = {
        return self.getDescriptionLabel(text: BundleI18n.LarkContact.Lark_NewContacts_ContactRequestMessage)
    }()

    private let chatApplicationAPI: ChatApplicationAPI
    private let chatAPI: ChatAPI

    private let pushCenter: PushNotificationCenter

    private let userId: String?
    private let chatId: String?
    private var addContactBlock: ((_ userId: String?) -> Void)?

    private var fromSource: Source

    private let businessType: AddContactBusinessType?

    private let userName: String

    private let token: String?

    private let maxCount = 50
    private var isAuth: Bool?
    private var hasAuth: Bool?
    // dissMiss添加好友页面后执行的任务
    public let dissmissBlock: (() -> Void)?

    init(chatApplicationAPI: ChatApplicationAPI,
         chatAPI: ChatAPI,
         resolver: UserResolver,
         userId: String?,
         chatId: String?,
         token: String?,
         source: Source,
         addContactBlock: ((_ userId: String?) -> Void)?,
         userName: String,
         isAuth: Bool? = nil,
         hasAuth: Bool? = nil,
         pushCenter: PushNotificationCenter,
         businessType: AddContactBusinessType?,
         dissmissBlock: (() -> Void)? = nil) throws {
        self.chatApplicationAPI = chatApplicationAPI
        self.chatAPI = chatAPI
        self.userResolver = resolver
        self.passportUserService = try resolver.resolve(assert: PassportUserService.self)
        self.userId = userId
        self.chatId = chatId
        self.fromSource = source
        self.addContactBlock = addContactBlock
        self.isAuth = isAuth
        self.hasAuth = hasAuth
        self.userName = userName
        self.token = token
        self.pushCenter = pushCenter
        self.businessType = businessType
        self.dissmissBlock = dissmissBlock
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.N00
        self.title = BundleI18n.LarkContact.Lark_NewContacts_RequestToAddToContacts
        let sendBarButtonItem = LKBarButtonItem(image: nil, title: BundleI18n.LarkContact.Lark_Legacy_Send)
        sendBarButtonItem.setBtnColor(color: UIColor.ud.colorfulBlue)
        sendBarButtonItem.setProperty(font: UIFont.systemFont(ofSize: 16), alignment: .center)
        sendBarButtonItem.addTarget(self, action: #selector(sendApplication), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = sendBarButtonItem

        let hasVerification = hasAuth ?? false ? "true" : "false"
        let userID = userId
        let isVerified = hasAuth ?? false && isAuth ?? false ? "true" : "false"

        var params: [AnyHashable: Any] = [:]

        params["verification"] = hasVerification
        params["to_user_id"] = userID
        params["is_verified"] = isVerified

        Tracker.post(TeaEvent(Homeric.PROFILE_CONTACT_REQUEST_VIEW, params: params, md5AllowList: ["to_user_id"]))

        self.view.addSubview(reasonForApplyLabel)
        reasonForApplyLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(14)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }

        /// 申请理由输入框
        reasonTextView.delegate = self
        self.view.addSubview(reasonTextView)

        //同步安卓，取displayName
        reasonTextView.text = BundleI18n.LarkContact.Lark_NewContacts_ContactRequestMessagePlaceholder2(self.chatterManager?.currentChatter.displayName ?? "")
        reasonTextView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(reasonForApplyLabel.snp.bottom).offset(6)
            make.height.equalTo(108)
        }

        ///设置备注名
        self.view.addSubview(aliasDescriptionLabel)
        self.view.addSubview(applicationInputView)

        aliasDescriptionLabel.snp.makeConstraints { (make) in
            make.top.equalTo(reasonTextView.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }

        applicationInputView.text = userName
        applicationInputView.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        applicationInputView.snp.makeConstraints { (make) in
            make.top.equalTo(aliasDescriptionLabel.snp.bottom).offset(6)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(48)
        }
    }

    private func getDescriptionLabel(text: String) -> UILabel {
        let descriptionLabel = UILabel()
        descriptionLabel.text = text
        descriptionLabel.numberOfLines = 2
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = UIColor.ud.N500
        descriptionLabel.textAlignment = .left
        return descriptionLabel
    }

    @objc
    private func sendApplication() {
        let sendRequestCallBack: SendFriendRequestCallBack = { [weak self] (isSucceed, error)  in
            if isSucceed {
                self?.sendRequestSucceed()
            } else {
                if let error = error {
                    self?.sendRequestError(error)
                }
            }
        }

        if fromSource.sourceType == .chat && fromSource.sourceName.isEmpty, let chatID = self.chatId {
            self.chatAPI
                .fetchChat(by: chatID, forceRemote: false)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (chat) in
                    self?.fromSource.sourceName = chat?.displayName ?? ""
                    self?.sendFriendApplication(sendRequestCallBack)
                }, onError: { [weak self] (_) in
                        self?.fromSource.sourceType = .unknownSource
                        self?.sendFriendApplication(sendRequestCallBack)
                        AddFriendsViewController.logger.error("AddFriendsViewController get name error, by id: \(self?.chatId ?? "")")
                }).disposed(by: self.disposeBag)
        } else {
            sendFriendApplication(sendRequestCallBack)
        }
        self.trackBusinessToAddContactSend(toUserIds: [self.userId ?? ""])
    }

    private func sendFriendApplication(_ sendRequestCallBack: @escaping SendFriendRequestCallBack) {
        var hud: UDToast?
        if let window = self.view.window {
            hud = UDToast.showLoading(on: window)
        }

        let hasVerification = hasAuth ?? false ? "true" : "false"
        let userID = userId
        let isVerified = hasAuth ?? false && isAuth ?? false ? "true" : "false"

        var params: [AnyHashable: Any] = [:]

        params["verification"] = hasVerification
        params["to_user_id"] = userID
        params["is_verified"] = isVerified
        params["target"] = "none"
        params["click"] = "send"
        params["is_reason_apply"] = self.reasonTextView.text.isEmpty ? "false" : "true"

        Tracker.post(TeaEvent(Homeric.PROFILE_CONTACT_REQUEST_CLICK, params: params, md5AllowList: ["to_user_id"]))
        var alias = applicationInputView.text ?? ""
        // 如果别名全是空格，需要保存为空字符串
        let fillterAlias = alias.replacingOccurrences(of: " ", with: "")
        if fillterAlias.isEmpty { alias = "" }
        AddContactRequestReciableTrack.addContactRequestStart()
        self.chatApplicationAPI.sendChatApplication(token: self.token,
                                                    chatID: chatId,
                                                    reason: self.reasonTextView.text ?? "",
                                                    userID: self.userId,
                                                    userAlias: alias,
                                                    source: fromSource,
                                                    useAction: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] res in
                AddContactRequestReciableTrack.addContactRequstEnd()
                hud?.remove()
                let action = res.crossBrandActionResult
                AddFriendsViewController.logger.debug("addContactRelation success style = \(action.styleType)")
                if action.styleType == .styleTypeUnknown {
                    sendRequestCallBack(true, nil)
                    let notificationName = Notification.Name(rawValue: LKFriendStatusChangeNotification)
                    NotificationCenter.default.post(name: notificationName, object: ["userID": self?.userId ?? "", "apply": true])
                    AddFriendsViewController.logger.debug("addContactRelation success")
                } else {
                    self?.showTnsAlert(action: action)
                    self?.trackTnsAlert(action: action)
                    AddFriendsViewController.logger.debug("addContactRelation success")
                }
            }, onError: { (error) in
                AddContactRequestReciableTrack.addContactPageLoadError(error: error)
                hud?.remove()
                sendRequestCallBack(false, error)
                AddFriendsViewController.logger.error("addContactRelation error!", error: error)
            }).disposed(by: self.disposeBag)
    }

    private func sendRequestSucceed() {
        // 添加好友完成后 提示Toast
        if let window = self.view.window {
            UDToast.showSuccess(with: BundleI18n.LarkContact.Lark_NewContacts_ContactRequestSentToast, on: window)
        }
        let userInfo = PushAddContactSuccessMessage(userId: self.userId ?? "")
        self.pushCenter.post(userInfo)
        self.addContactBlock?(self.userId)
        dismissSelf()
    }

    private func sendRequestError(_ error: Error) {
        self.showAlert(content: getDisplayMessage(
            error: error, defaultText: BundleI18n.LarkContact.Lark_Legacy_FriendRequestSendFailedRetry
        ))
        AddFriendsViewController.logger.error("AddFriendsViewController add Conotact error, by id: \(self.userId ?? "")")
    }

    private func getDisplayMessage(error: Error, defaultText: String) -> String {
        if let error = error.underlyingError as? APIError {
            if !error.serverMessage.isEmpty {
                return error.serverMessage
            }
            switch error.type {
            case .noApplyPermission(let message):
                return message
            /// 和PC、Android沟通过，他们都是依赖于SDK的错误信息
            case .unknownBusinessError(let message):
                return message
            case .externalCoordinateCtl, .targetExternalCoordinateCtl:
                return BundleI18n.LarkContact.Lark_Contacts_CantCompleteOperationNoExternalCommunicationPermission
            default:
                break
            }
        }
        return defaultText
    }

    private func showAlert(content: String) {
        let alertController = LarkAlertController()
        alertController.setContent(text: content)
        alertController.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Legacy_Sure)
        navigator.present(alertController, from: self)
    }

    private func showTnsAlert(action: RustPB.Im_V1_CrossBrandAction) {
        let config = UDDialogUIConfig(style: .vertical)
        let dialog = UDDialog(config: config)
        dialog.setTitle(text: action.title)
        dialog.setContent(text: action.content)
        dialog.addPrimaryButton(text: action.confirmBtnContent, dismissCompletion: { [weak self] in
            guard let self = self,
            let url = URL(string: action.confirmBtnActionLink) else {
                return
            }
            self.trackTnsAlertClick(action: action, isConfirm: true, content: action.confirmBtnContent)
            self.navigator.push(url, from: self)
        })
        dialog.addSecondaryButton(text: action.cancelBtnContent, dismissCompletion: { [weak self] in
            self?.trackTnsAlertClick(action: action, isConfirm: false, content: action.cancelBtnContent)
            guard let self = self,
                  let url = URL(string: action.cancelBtnActionLink) else { return }
            self.navigator.push(url, from: self)
        })
        self.present(dialog, animated: true)
    }

    private func trackTnsAlert(action: RustPB.Im_V1_CrossBrandAction) {
        var params = action.traceInfo
        params["style_type"] = getTrackStyleTypeString(action: action)
        Tracker.post(TeaEvent("tns_contact_add_external_cross_border_view", params: params))
    }

    private func trackTnsAlertClick(action: RustPB.Im_V1_CrossBrandAction, isConfirm: Bool, content: String) {
        var params = action.traceInfo
        params["style_type"] = getTrackStyleTypeString(action: action)
        params["click"] = isConfirm ? "confirm" : "cancel"
        params["click_content"] = content
        Tracker.post(TeaEvent("tns_contact_add_external_cross_border_click", params: params))
    }

    private func getTrackStyleTypeString(action: RustPB.Im_V1_CrossBrandAction) -> String {
        switch action.styleType {
        case .styleTypeAlert: return "alert"
        case .styleTypeTip: return "tip"
        case .styleTypeToast: return "toast"
        @unknown default: return ""
        }
    }

    // MARK: - UITextFieldDelegate & UITextViewDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.becomeFirstResponder()
        textField.layer.borderColor = UIColor.ud.colorfulBlue.cgColor
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        textField.layer.borderColor = UIColor.ud.N400.cgColor
    }

    @objc
    func textDidChange() {
        guard let text = applicationInputView.text else {
            return
        }
        if let selectedRange = applicationInputView.markedTextRange {
            let position = applicationInputView.position(from: selectedRange.start, offset: 0)
            if position == nil {
                if text.count > maxCount {
                    applicationInputView.text = String(text[0..<maxCount])
                }
            }
        } else {
            if text.count > maxCount {
                applicationInputView.text = String(text[0..<maxCount])
            }
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        guard let text = textView.text else {
            return
        }
        if let selectedRange = textView.markedTextRange {
            let position = textView.position(from: selectedRange.start, offset: 0)
            if position == nil {
                if text.count > maxCount {
                    textView.text = String(text[0..<maxCount])
                }
            }
        } else {
            if text.count > maxCount {
                textView.text = String(text[0..<maxCount])
            }
        }
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.layer.borderColor = UIColor.ud.colorfulBlue.cgColor

    }
    func textViewDidEndEditing(_ textView: UITextView) {
        textView.layer.borderColor = UIColor.ud.N400.cgColor
    }

    /// 点击空白区域收起键盘
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    private func dismissSelf() {
        if hasBackPage {
            navigationController?.popViewController(animated: true)
        } else if presentingViewController != nil {
            dismiss(animated: true, completion: nil)
        } else {
            AddFriendsViewController.logger.error("AddFriendsViewController !hasBackPage & presentingVc is nil, can not dismiss")
        }
        self.dissmissBlock?()
    }

    private func trackBusinessToAddContactSend(toUserIds: [String]) {
        if let businessType = businessType, !businessType.rawValue.isEmpty {
            if businessType == .profileAdd {
                Tracer.trackProfileAddSourceType(self.fromSource.sourceType,
                                                 userID: self.userId,
                                                 token: self.token,
                                                 isAuth: self.isAuth ?? false,
                                                 hasAuth: self.hasAuth ?? false)
            } else {
                Tracer.trackBusinessToAddContactSend(type: businessType,
                                                     toUserIds: toUserIds)
            }
        }
    }
}
