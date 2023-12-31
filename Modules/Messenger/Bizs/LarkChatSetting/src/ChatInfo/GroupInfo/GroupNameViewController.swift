//
//  GroupNameViewController.swift
//  Lark
//
//  Created by chengzhipeng-bytedance on 2017/4/24.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import LarkUIKit
import LarkModel
import LarkButton
import LKCommonsLogging
import UniverseDesignToast
import LarkSDKInterface
import LarkAlertController
import LarkFeatureGating
import EENavigator

final class ChatReviseNameInputView: UIView, UITextFieldDelegate {
    private let textMaxLength: Int
    let textField = BaseTextField(frame: .zero)
    var textFieldDidChangeHandler: ((UITextField) -> Void)?
    var text: String? {
        get { return self.textField.text }
        set {
            self.textField.text = newValue
            inputViewTextFieldDidChange(self.textField)
        }
    }
    let textCountLabel: UILabel = UILabel(frame: .zero)

    init(textMaxLength: Int) {
        self.textMaxLength = textMaxLength
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgFloat
        textField.delegate = self
        textField.exitOnReturn = true
        textField.textAlignment = .left
        textField.borderStyle = .none
        textField.addClearIcon()
        textField.textColor = UIColor.ud.N900
        textField.backgroundColor = UIColor.ud.bgFloat
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.returnKeyType = .done
        textField.addTarget(self, action: #selector(inputViewTextFieldDidChange(_:)), for: .editingChanged)
        self.addSubview(textField)
        textField.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-7)
            make.top.equalToSuperview().offset(16)
            make.height.equalTo(20)
        }

        textCountLabel.font = .systemFont(ofSize: 12)
        self.addSubview(textCountLabel)
        textCountLabel.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(textField.snp.bottom).offset(6)
            make.bottom.equalToSuperview().offset(-8)
        }
        let attr = NSAttributedString(string: "\(0)/\(textMaxLength)",
                                      attributes: [.foregroundColor: UIColor.ud.N500])
        textCountLabel.attributedText = attr
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func inputViewTextFieldDidChange(_ textField: UITextField) {
        let count = textField.text?.count ?? 0
        if count > textMaxLength {
            let attr = NSMutableAttributedString(string: "\(count)",
                                                 attributes: [.foregroundColor: UIColor.ud.colorfulRed])
            attr.append(NSAttributedString(string: "/\(textMaxLength)",
                                           attributes: [.foregroundColor: UIColor.ud.N500]))
            textCountLabel.attributedText = attr
        } else {
            let attr = NSAttributedString(string: "\(count)/\(textMaxLength)",
                                          attributes: [.foregroundColor: UIColor.ud.N500])
            textCountLabel.attributedText = attr
        }
        if let handler = self.textFieldDidChangeHandler {
            handler(textField)
        }
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        let attr = NSAttributedString(string: "0/\(textMaxLength)",
                                      attributes: [.foregroundColor: UIColor.ud.N500])
        textCountLabel.attributedText = attr
        return true
    }
}

final class GroupNameViewController: BaseSettingController {
    private static let logger = Logger.log(
        GroupNameViewController.self,
        category: "LarkChat.ChatInfo.GroupNameViewController")

    private let disposeBag = DisposeBag()

    private let chat: Chat
    private let chatAPI: ChatAPI
    private let currentChatterId: String
    private var isOwner: Bool {
        currentChatterId == chat.ownerId
    }
    // 是否是群管理
    var isGroupAdmin: Bool {
        return chat.isGroupAdmin
    }

    private(set) var groupName: String
    private var hasAccess: Bool {
        return chat.isAllowPost && (chat.ownerId == currentChatterId || isGroupAdmin || !chat.offEditGroupChatInfo)
    }

    private let textMaxLength = 60
    lazy var nameInputView = ChatReviseNameInputView(textMaxLength: textMaxLength)
    private(set) var finishedButton: UIButton?

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }
    private let navi: Navigatable
    init(chat: Chat, currentChatterId: String, chatAPI: ChatAPI, navi: Navigatable) {
        self.chat = chat
        self.chatAPI = chatAPI
        self.currentChatterId = currentChatterId
        self.groupName = chat.displayName
        self.navi = navi
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgFloatBase
        NewChatSettingTracker.imEditGroupNameView(chat: self.chat)

        self.addNavigationBarRightItem()

        nameInputView.layer.cornerRadius = 10.0
        nameInputView.text = groupName
        nameInputView.textFieldDidChangeHandler = { [weak self] (textField) in
            guard let self = self else { return }
            let textCount = textField.text?.count ?? 0
            let color = textCount > self.textMaxLength ? UIColor.ud.N400 : UIColor.ud.colorfulBlue
            self.finishedButton?.setTitleColor(color, for: .normal)
        }
        self.view.addSubview(nameInputView)

        nameInputView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(15)
        }

        self.backCallback = { [weak self] in
            self?.endEditting()
        }

        self.setAccessHandler(self.hasAccess)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.nameInputView.textField.becomeFirstResponder()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.endEditting()
    }

    fileprivate func addNavigationBarRightItem() {
        let rightItem = LKBarButtonItem(title: BundleI18n.LarkChatSetting.Lark_Legacy_Save, fontStyle: .medium)
        rightItem.setProperty(font: LKBarButtonItem.FontStyle.medium.font, alignment: .right)
        rightItem.button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        rightItem.button.addTarget(self, action: #selector(navigationBarRightItemTapped), for: .touchUpInside)
        self.finishedButton = rightItem.button
        self.navigationItem.rightBarButtonItem = rightItem
    }

    @objc
    fileprivate func navigationBarRightItemTapped() {
        NewChatSettingTracker.imEditGroupNameSaveClick(chat: self.chat)
        guard hasAccess else {
            let alertController = LarkAlertController()
            let content = BundleI18n.LarkChatSetting.Lark_Legacy_OnlyGOGAEditGroupInfo
            alertController.setContent(text: content)
            alertController.addPrimaryButton(text: BundleI18n.LarkChatSetting.Lark_Legacy_Sure)
            self.navi.present(alertController, from: self)
            return
        }
        let textCount = self.nameInputView.text?.count ?? 0
        guard textCount <= self.textMaxLength else {
            if let window = self.view.window {
                UDToast.showTips(with: BundleI18n.LarkChatSetting.Lark_Group_DescriptionCharacterLimitExceeded,
                                    on: window)
            }
            return
        }

        let newName = (self.nameInputView.text ?? "").trimmingCharacters(in: .whitespaces)
        NewChatSettingTracker.imChatSettingEditTitleSaveClick(chatId: chat.id,
                                                              isAdmin: isOwner,
                                                              altered: newName != groupName,
                                                              charCount: newName.count)
        let hud = UDToast.showLoading(on: view)
        chatAPI.updateChat(chatId: chat.id, name: newName)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self, let window = self.view.window else { return }
                hud.showSuccess(with: BundleI18n.LarkChatSetting.Lark_Legacy_SaveSuccess, on: window)
                ChatSettingTracker.trackChatNameSave(chat: self.chat, newName: newName)
                if self.presentingViewController != nil {
                    self.presentingViewController?.dismiss(animated: true, completion: nil)
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
            }, onError: { [weak self, weak hud] (error) in
                if let self = self {
                    hud?.showFailure(
                        with: BundleI18n.LarkChatSetting.Lark_Legacy_ChatGroupInfoModifyGroupNameFailed,
                        on: self.view,
                        error: error
                    )
                }
                GroupNameViewController.logger.error("modify group name failed", error: error)
            }, onCompleted: { [weak self] in
                if let self = self {
                    UDToast.removeToast(on: self.view)
                }
            }).disposed(by: disposeBag)
    }

    fileprivate func endEditting() {
        if self.view.canResignFirstResponder {
            self.view.endEditing(true)
        }
    }

    fileprivate func setAccessHandler(_ hasAccess: Bool) {
        self.nameInputView.textField.isEnabled = hasAccess
        self.finishedButton?.isHidden = !hasAccess
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension UITextField {

    func addClearIcon() {
        let wrapperView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 52))
        let clearButton = UIButton(frame: CGRect(x: 16, y: 18, width: 16, height: 16))
        clearButton.setImage(Resources.icon_clear, for: .normal)
        wrapperView.addSubview(clearButton)
        clearButton.addTarget(self, action: #selector(clearButtonClicked), for: .touchUpInside)
        self.rightView = wrapperView
        self.rightViewMode = .whileEditing
        self.rightView?.systemLayoutSizeFitting(CGSize(width: 44, height: 52))
    }

    func clearTextField() {
        self.text = ""
    }

    @objc
    private func clearButtonClicked() {
        clearTextField()
        _ = self.delegate?.textFieldShouldClear?(self)
    }
}
