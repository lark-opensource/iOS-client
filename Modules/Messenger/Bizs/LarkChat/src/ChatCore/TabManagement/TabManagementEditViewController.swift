//
//  TabManagementEditViewController.swift.swift
//  LarkChat
//
//  Created by Zigeng on 2022/4/4.
//

import Foundation
import LarkUIKit
import LarkModel
import LarkCore
import LarkSDKInterface
import UniverseDesignColor
import UIKit
import RxCocoa
import RxSwift
import EditTextView
import LarkContainer
import LKCommonsLogging
import UniverseDesignToast
import LarkOpenChat
import RustPB

final class TabManagementEditViewController: BaseUIViewController, UserResolverWrapper, UITextViewDelegate {
    let userResolver: UserResolver
    static let logger = Logger.log(TabManagementEditViewController.self, category: "Module.TabManagementEditViewController")
    private let disposeBag = DisposeBag()

    var updateCompletion: ((ChatTabContent) -> Void)?

    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    @ScopedInjectedLazy private var docAPI: DocAPI?

    private lazy var nameInputWrapperView: ChatTabNameInputWrapperView = {
        let inputWrapperView = ChatTabNameInputWrapperView()
        return inputWrapperView
    }()

    private lazy var rightItem: LKBarButtonItem = {
        let rightItem = LKBarButtonItem(title: BundleI18n.LarkChat.Lark_Legacy_Save)
        rightItem.button.setTitleColor(UIColor.ud.textLinkNormal, for: .normal)
        rightItem.button.setTitleColor(UIColor.ud.textPlaceholder, for: .disabled)
        rightItem.button.addTarget(self, action: #selector(rightBarButtonEvent), for: .touchUpInside)
        return rightItem
    }()

    private lazy var linkTipLabel: UILabel = {
        let inputTitleLabel = UILabel()
        inputTitleLabel.font = UIFont.systemFont(ofSize: 14)
        inputTitleLabel.textColor = UIColor.ud.textCaption
        inputTitleLabel.text = BundleI18n.LarkChat.Lark_IM_AddTabs_LinkTitle
        return inputTitleLabel
    }()

    private lazy var nameTipLabel: UILabel = {
        let inputTitleLabel = UILabel()
        inputTitleLabel.font = UIFont.systemFont(ofSize: 14)
        inputTitleLabel.textColor = UIColor.ud.textCaption
        inputTitleLabel.text = BundleI18n.CCM.Lark_Groups_DocumentName
        return inputTitleLabel
    }()

    private lazy var linkInputTextView: LarkEditTextView = {
        let inputTextView = LarkEditTextView()
        let defaultTypingAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.ud.textTitle
        ]
        inputTextView.defaultTypingAttributes = [.font: UIFont.systemFont(ofSize: 16),
                                                 .foregroundColor: UIColor.ud.textTitle]
        inputTextView.isScrollEnabled = false
        inputTextView.delegate = self
        inputTextView.textContainerInset = UIEdgeInsets(top: 14, left: 0, bottom: 14, right: 0)
        inputTextView.maxHeight = 108
        inputTextView.backgroundColor = UIColor.clear
        return inputTextView
    }()

    private lazy var linkInputWrapperView: UIView = {
        let wrapperView = UIView()
        wrapperView.backgroundColor = UIColor.ud.bgBody
        wrapperView.layer.cornerRadius = 10
        return wrapperView
    }()

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgFloatBase

        self.navigationItem.rightBarButtonItem = self.rightItem
        self.addCancelItem()
        titleString = BundleI18n.LarkChat.Lark_IM_EditTabs_Title

        self.view.addSubview(linkTipLabel)
        self.linkTipLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(20)
            make.top.equalToSuperview().inset(28)
        }

        self.view.addSubview(linkInputWrapperView)
        linkInputWrapperView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(linkTipLabel.snp.bottom).offset(4)
        }
        linkInputWrapperView.addSubview(linkInputTextView)
        linkInputTextView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview()
            make.height.greaterThanOrEqualTo(20)
            make.height.lessThanOrEqualTo(108)
        }

        self.view.addSubview(nameTipLabel)
        self.nameTipLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(20)
            make.top.equalTo(linkInputWrapperView.snp.bottom).offset(16)
        }

        self.view.addSubview(nameInputWrapperView)
        nameInputWrapperView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(nameTipLabel.snp.bottom).offset(4)
        }

        let linkText = self.getLink(tabContent: self.tabContent)
        self.linkInputTextView.text = linkText
        if tabContent.type == .task {
            self.linkInputTextView.isEditable = false
        }
        self.updateLinkInputStatus(linkText.isEmpty ? .limit : .normal)
        self.nameInputWrapperView.set(inputText: self.tabTitle) { [weak self] editStatus in
            self?.updateNameInputStatus(editStatus)
        }
        self.nameInputWrapperView.showKeyboard()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.view.canResignFirstResponder {
            self.view.endEditing(true)
        }
    }

    private var inputStatus: (ChatTabEditStatus, ChatTabEditStatus) = (.normal, .normal) {
        didSet {
            if inputStatus == (.normal, .normal) {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
            } else {
                self.navigationItem.rightBarButtonItem?.isEnabled = false
            }
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        if textView.text.isEmpty {
            self.updateLinkInputStatus(.limit)
        } else {
            self.updateLinkInputStatus(.normal)
        }
    }

    private func getLink(tabContent: ChatTabContent) -> String {
        guard let data = tabContent.payloadJson.data(using: .utf8),
              let dic = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let url = dic["url"] as? String else {
                  return ""
              }
        return url
    }

    private func updateLinkInputStatus(_ status: ChatTabEditStatus) {
        self.inputStatus.0 = status
    }

    private func updateNameInputStatus(_ status: ChatTabEditStatus) {
        self.inputStatus.1 = status
    }

    @objc
    func rightBarButtonEvent() {
        guard let link = self.linkInputTextView.text else { return }
        self.rightItem.button.isUserInteractionEnabled = false
        /// url 不变，只更新 name
        if link == self.getLink(tabContent: self.tabContent) {
            let tabName = self.nameInputWrapperView.inputText
            guard let data = self.tabContent.payloadJson.data(using: .utf8),
                  var jsonDic = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                return
            }
            jsonDic["name"] = tabName
            self.updateTab(jsonDic)
            return
        }
        switch self.tabContent.type {
        case .doc:
            self.docAPI?.getDocByURL(urls: [link])
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (result) in
                    guard let self = self else { return }
                    let docType = result.docs[link]?.type
                    self.updateDocTab(url: link, docType: docType ?? .unknown)
                }, onError: { [weak self] _ in
                    self?.updateDocTab(url: link, docType: .unknown)
                }).disposed(by: self.disposeBag)
        case .url, .task:
            self.updateURLTab(url: link)
        @unknown default:
            assertionFailure("unsupported tab type")
        }
        if link != self.getLink(tabContent: self.tabContent) {
            IMTracker.Chat.TabManagement.Click.TabLinkChange(self.chat)
        }
        if self.nameInputWrapperView.inputText != self.tabTitle {
            IMTracker.Chat.TabManagement.Click.TabNameChange(self.chat)
        }
    }

    private func updateURLTab(url: String) {
        let tabName = self.nameInputWrapperView.inputText
        let jsonDic: [String: Any] = ["name": tabName,
                                      "url": url]
        self.updateTab(jsonDic)
    }

    private func updateDocTab(url: String, docType: RustPB.Basic_V1_Doc.TypeEnum) {
        let tabName = self.nameInputWrapperView.inputText
        let jsonDic: [String: String] = ["name": tabName,
                                         "url": url,
                                         "docType": "\(docType.rawValue)"]
        self.updateTab(jsonDic)
    }

    private func updateTab(_ jsonDic: [String: Any]) {
        var jsonPayload: String?
        if let data = try? JSONSerialization.data(withJSONObject: jsonDic) {
            jsonPayload = String(data: data, encoding: .utf8)
        }
        var updateTab = self.tabContent
        updateTab.payloadJson = jsonPayload ?? ""
        updateTab.name = self.nameInputWrapperView.inputText
        let tabId = updateTab.id
        self.chatAPI?.updateChatTabDetail(chatId: self.chatId, tab: updateTab)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] response in
                guard let self = self else { return }
                self.rightItem.button.isUserInteractionEnabled = true
                if let newTab = response.tabs.first(where: { $0.id == tabId }) {
                    self.updateCompletion?(newTab)
                    return
                }
                Self.logger.error("can not find new updated tab")
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.rightItem.button.isUserInteractionEnabled = true
                Self.logger.error("update tab failed \(error)")
                UDToast.showFailure(with: BundleI18n.LarkChat.Lark_Legacy_ErrorMessageTip, on: self.view, error: error)
            }, onCompleted: { [weak self] in
                self?.rightItem.button.isUserInteractionEnabled = true
            }).disposed(by: disposeBag)
    }

    init(userResolver: UserResolver, chat: Chat, tabTitle: String, tabContent: ChatTabContent) {
        self.userResolver = userResolver
        self.chatId = Int64(chat.id) ?? 0
        self.chat = chat
        self.tabTitle = tabTitle
        self.tabContent = tabContent
        super.init(nibName: nil, bundle: nil)
    }

    private let tabContent: ChatTabContent
    private let tabTitle: String
    private let chatId: Int64
    private let chat: Chat

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
