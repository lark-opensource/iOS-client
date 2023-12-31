//
//  NicknameViewController.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/3/17.
//

import Foundation
import UIKit
import RxSwift
import LarkUIKit
import LarkModel
import LarkButton
import LKCommonsLogging
import UniverseDesignToast
import LarkAccountInterface
import LarkSDKInterface
import LarkContainer

final class NicknameViewController: BaseSettingController {
    let userResolver: UserResolver
    private static let logger = Logger.log(
        NicknameViewController.self,
        category: "LarkChat.ChatInfo.NicknameViewController")
    private let disposeBag = DisposeBag()
    var isOwner: Bool { userResolver.userID == chatId }

    private let chat: Chat
    private let chatId: String
    private let chatterAPI: ChatterAPI
    private let saveNickName: (String) -> Void

    private(set) var oldName: String
    private let textMaxLength = 60
    lazy var nameInputView = ChatReviseNameInputView(textMaxLength: textMaxLength)
    private(set) var finishedButton: UIButton?

    init(userResolver: UserResolver, chat: Chat, oldName: String, chatId: String, chatterAPI: ChatterAPI, saveNickName: @escaping (String) -> Void) {
        self.userResolver = userResolver
        self.chat = chat
        self.chatId = chatId
        self.chatterAPI = chatterAPI
        self.oldName = oldName
        self.saveNickName = saveNickName

        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addNavigationBarRightItem()
        self.view.backgroundColor = UIColor.ud.bgFloatBase
        nameInputView.layer.cornerRadius = 10.0
        nameInputView.textFieldDidChangeHandler = { [weak self] (textField) in
            guard let self = self else { return }
            let textCount = textField.text?.count ?? 0
            let color = textCount > self.textMaxLength ? UIColor.ud.N400 : UIColor.ud.colorfulBlue
            self.finishedButton?.setTitleColor(color, for: .normal)
        }
        nameInputView.text = self.oldName
        self.view.addSubview(nameInputView)
        nameInputView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(15)
        }

        NewChatSettingTracker.imEditAliasView(chat: self.chat)

        self.backCallback = { [weak self] in
            self?.endEditting()
        }
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
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
        var inputName = self.nameInputView.text ?? ""
        guard inputName.count <= textMaxLength else {
            if let window = self.view.window {
                UDToast.showTips(with: BundleI18n.LarkChatSetting.Lark_Group_DescriptionCharacterLimitExceeded,
                                    on: window)
            }
            return
        }
        // 无任何输入表示不设置群昵称，否则需要去掉空格
        if !inputName.isEmpty {
            inputName = inputName.trimmingCharacters(in: .whitespaces)
            // 输入全为空格则提示错误
            if inputName.isEmpty {
                self.showAlert(
                    title: BundleI18n.LarkChatSetting.Lark_Legacy_Hint,
                    message: BundleI18n.LarkChatSetting.Lark_Legacy_ContentCantEmpty
                )
                return
            }
        }
        NewChatSettingTracker.imChatSettingAliasSaveClick(chatId: chatId,
                                                          isAdmin: isOwner,
                                                          altered: inputName != oldName,
                                                          charCount: inputName.count,
                                                          chat: self.chat)
        let hud = UDToast.showLoading(on: view)
        chatterAPI.setChannelNickname(chatId: chatId, nickname: inputName)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                if let window = self?.view.window {
                    hud.showSuccess(with: BundleI18n.LarkChatSetting.Lark_Legacy_SaveSuccess, on: window)
                }
                self?.saveNickName(inputName)
                if self?.presentingViewController != nil {
                    self?.presentingViewController?.dismiss(animated: true, completion: nil)
                } else {
                    self?.navigationController?.popViewController(animated: true)
                }
            }, onError: { [weak self, weak hud] (error) in
                if let self = self {
                    hud?.showFailure(
                        with: BundleI18n.LarkChatSetting.Lark_Legacy_GroupInfoSetMyAliasFail,
                        on: self.view,
                        error: error
                    )
                }
                NicknameViewController.logger.error("change channel nickName error ", error: error)
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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
