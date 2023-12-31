//
//  ChatTabSetDocNameController.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/3/31.
//

import UIKit
import Foundation
import RustPB
import SnapKit
import LarkUIKit
import LarkCore
import LarkSDKInterface
import UniverseDesignColor
import UniverseDesignToast
import LKCommonsLogging
import LKCommonsTracker
import RxSwift
import RxCocoa
import LarkOpenChat
import Homeric
import LarkBizAvatar
import LarkContainer
import LarkModel

final class ChatTabSetDocNameController: BaseUIViewController {
    let userResolver: UserResolver
    static let logger = Logger.log(ChatTabSetDocNameController.self, category: "Module.ChatTabSetDocNameController")

    private lazy var titleView: ChatTabSetDocTitleView = {
        return ChatTabSetDocTitleView()
    }()

    private lazy var rightItem: LKBarButtonItem = {
        let rightItem = LKBarButtonItem(title: BundleI18n.LarkChat.Lark_Legacy_Save)
        rightItem.button.setTitleColor(UIColor.ud.textLinkNormal, for: .normal)
        rightItem.button.setTitleColor(UIColor.ud.textPlaceholder, for: .disabled)
        rightItem.button.addTarget(self, action: #selector(rightBarButtonEvent), for: .touchUpInside)
        return rightItem
    }()

    private lazy var inputTitleLabel: UILabel = {
        let inputTitleLabel = UILabel()
        inputTitleLabel.font = UIFont.systemFont(ofSize: 14)
        inputTitleLabel.textColor = UIColor.ud.textCaption
        inputTitleLabel.text = BundleI18n.CCM.Lark_Groups_DocumentName
        return inputTitleLabel
    }()

    private lazy var inputWrapperView: ChatTabNameInputWrapperView = {
        let inputWrapperView = ChatTabNameInputWrapperView()
        return inputWrapperView
    }()

    private let setDocNameModel: ChatAddTabSetDocModel
    private let addCompletion: (ChatTabContent) -> Void

    private let disposeBag = DisposeBag()
    private var chatAPI: ChatAPI

    init(userResolver: UserResolver, setDocNameModel: ChatAddTabSetDocModel, addCompletion: @escaping (ChatTabContent) -> Void) throws {
        self.userResolver = userResolver
        chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        self.setDocNameModel = setDocNameModel
        self.addCompletion = addCompletion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        titleString = BundleI18n.CCM.Lark_Groups_DocumentName
        view.backgroundColor = UIColor.ud.bgFloatBase
        self.navigationItem.rightBarButtonItem = self.rightItem
        self.view.addSubview(titleView)
        titleView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
        }
        self.view.addSubview(inputTitleLabel)
        inputTitleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(20)
            make.top.equalTo(titleView.snp.bottom).offset(16)
        }
        self.view.addSubview(inputWrapperView)
        inputWrapperView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(inputTitleLabel.snp.bottom).offset(4)
        }

        self.titleView.setModel(setDocNameModel, userResolver: userResolver)

        self.inputWrapperView.set(inputText: setDocNameModel.title) { [weak self] editStatus in
            guard let self = self else { return }
            switch editStatus {
            case .limit:
                self.navigationItem.rightBarButtonItem?.isEnabled = false
            case .normal:
                self.navigationItem.rightBarButtonItem?.isEnabled = true
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.inputWrapperView.showKeyboard()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.view.canResignFirstResponder {
            self.view.endEditing(true)
        }
    }

    @objc
    func rightBarButtonEvent() {
        let inputText = self.inputWrapperView.inputText
        let jsonDic: [String: String] = ["name": inputText,
                                         "url": setDocNameModel.url,
                                         "docType": "\(setDocNameModel.docType.rawValue)"]
        var jsonPayload: String?
        if let data = try? JSONEncoder().encode(jsonDic) {
            jsonPayload = String(data: data, encoding: .utf8)
        }
        self.rightItem.button.isUserInteractionEnabled = false
        self.chatAPI.addChatTab(chatId: Int64(self.setDocNameModel.chatId) ?? 0, name: inputText, type: .doc, jsonPayload: jsonPayload)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] response in
                guard let self = self else { return }
                self.rightItem.button.isUserInteractionEnabled = true
                IMTracker.Chat.DocPageAdd.Click.TabSave(
                    self.setDocNameModel.chat,
                    params: ["name_add": inputText == self.setDocNameModel.title ? "false" : "true",
                             "file_id": self.setDocNameModel.id,
                             "tab_id": response.newTabID]
                )
                if let newTab = response.tabs.first(where: { $0.id == response.newTabID }) {
                    self.addCompletion(newTab)
                    return
                }
                Self.logger.error("can not find new add tab")
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.rightItem.button.isUserInteractionEnabled = true
                Self.logger.error("add tab failed \(error)")
                UDToast.showFailure(with: BundleI18n.LarkChat.Lark_Legacy_ErrorMessageTip, on: self.view, error: error)
            }, onCompleted: { [weak self] in
                self?.rightItem.button.isUserInteractionEnabled = true
            }).disposed(by: disposeBag)
    }
}

final class ChatTabSetDocTitleView: UIView {
    private lazy var tipLabel: UILabel = {
        let tipLabel = UILabel()
        tipLabel.font = UIFont.systemFont(ofSize: 14)
        tipLabel.textColor = UIColor.ud.textCaption
        tipLabel.text = BundleI18n.CCM.Lark_Groups_SelectedDocument
        return tipLabel
    }()

    private lazy var containerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.ud.bgBody
        containerView.layer.cornerRadius = 10
        return containerView
    }()

    private lazy var docImageView: UIImageView = {
        let docImageView = UIImageView()
        return docImageView
    }()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.text = ""
        return titleLabel
    }()

    private lazy var subTitleLabel: UILabel = {
        let subTitleLabel = UILabel()
        subTitleLabel.font = UIFont.systemFont(ofSize: 14)
        subTitleLabel.textColor = UIColor.ud.textPlaceholder
        subTitleLabel.text = ""
        return subTitleLabel
    }()

    private lazy var avatarView: BizAvatar = {
        let avatarView = BizAvatar()
        return avatarView
    }()

    private let disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(20)
            make.top.equalToSuperview().inset(28)
            make.right.equalToSuperview()
        }
        self.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(tipLabel.snp.bottom).offset(4)
            make.height.equalTo(70)
            make.bottom.equalToSuperview()
        }
        containerView.addSubview(docImageView)
        docImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(16)
            make.size.equalTo(40)
            make.centerY.equalToSuperview()
        }
        containerView.addSubview(titleLabel)
        containerView.addSubview(subTitleLabel)
        containerView.addSubview(avatarView)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(12)
            make.left.equalTo(docImageView.snp.right).offset(12)
            make.right.equalToSuperview().inset(16)
            make.height.equalTo(22)
        }
        subTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.left.equalTo(docImageView.snp.right).offset(12)
        }
        avatarView.snp.makeConstraints { (make) in
            make.left.equalTo(subTitleLabel.snp.right).offset(4)
            make.size.equalTo(16)
            make.centerY.equalTo(subTitleLabel)
            make.right.lessThanOrEqualToSuperview().inset(16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setModel(_ docModel: ChatAddTabSetDocModel, userResolver: UserResolver) {
        let defaultIcon = LarkCoreUtils.docIconColorful(docType: docModel.docType, fileName: docModel.title)
        self.docImageView.image = defaultIcon
        let title = docModel.title.isEmpty ? BundleI18n.CCM.Lark_Legacy_DefaultName : docModel.title
        var titleAttributed = NSAttributedString(string: title)
        titleAttributed = SearchResult.attributedText(attributedString: titleAttributed,
                                                      withHitTerms: docModel.titleHitTerms,
                                                      highlightColor: UDColor.primaryContentDefault)
        let mutTitleAttributed = NSMutableAttributedString(attributedString: titleAttributed)
        mutTitleAttributed.addAttribute(.font,
                                        value: UIFont.systemFont(ofSize: 17),
                                        range: NSRange(location: 0, length: titleAttributed.length))
        self.titleLabel.attributedText = mutTitleAttributed
        self.subTitleLabel.text = "\(BundleI18n.CCM.Lark_Legacy_SendDocDocOwner)\(BundleI18n.CCM.Lark_Legacy_Colon)\(docModel.ownerName)"
        let chatterAPI = try? userResolver.resolve(assert: ChatterAPI.self)
        chatterAPI?.getChatter(id: docModel.ownerID, forceRemoteData: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] response in
                self?.avatarView.setAvatarByIdentifier(docModel.ownerID,
                                                       avatarKey: response?.avatarKey ?? "",
                                                       avatarViewParams: .init(sizeType: .size(16)))
            }).disposed(by: disposeBag)
    }
}

struct ChatAddTabSetDocModel {
    let chatId: String
    let chat: Chat
    let id: String
    let url: String
    let docType: RustPB.Basic_V1_Doc.TypeEnum
    let title: String
    let titleHitTerms: [String]
    let ownerID: String
    let ownerName: String

    public init(chatId: String,
                chat: Chat,
                id: String,
                url: String,
                docType: RustPB.Basic_V1_Doc.TypeEnum,
                title: String,
                titleHitTerms: [String],
                ownerID: String,
                ownerName: String) {
        self.chatId = chatId
        self.chat = chat
        self.id = id
        self.url = url
        self.docType = docType
        self.title = title
        self.titleHitTerms = titleHitTerms
        self.ownerID = ownerID
        self.ownerName = ownerName
    }
}
