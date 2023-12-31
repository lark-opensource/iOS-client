//
//  ChatTabSetURLNameController.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/4/1.
//

import UIKit
import Foundation
import LarkUIKit
import LarkSDKInterface
import UniverseDesignColor
import LKCommonsLogging
import LKCommonsTracker
import RxSwift
import RxCocoa
import LarkOpenChat
import Homeric
import LarkContainer
import UniverseDesignIcon
import LarkCore
import UniverseDesignToast
import LarkModel
import TangramService
import RustPB

final class ChatTabSetURLNameController: BaseUIViewController, UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(ChatTabSetURLNameController.self, category: "Module.ChatTabSetURLNameController")

    private lazy var titleView: ChatTabSetURLTitleView = {
        return ChatTabSetURLTitleView()
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

    private let setURLNameModel: ChatAddTabSetURLModel
    private let addCompletion: (ChatTabContent) -> Void

    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    @ScopedInjectedLazy private var todoService: ChatTodoDependency?

    init(userResolver: UserResolver, setURLNameModel: ChatAddTabSetURLModel, addCompletion: @escaping (ChatTabContent) -> Void) {
        self.userResolver = userResolver
        self.setURLNameModel = setURLNameModel
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

        self.titleView.setModel(setURLNameModel)

        self.inputWrapperView.set(inputText: setURLNameModel.urlPreviewInfo?.title ?? "") { [weak self] editStatus in
            guard let self = self else { return }
            switch editStatus {
            case .limit:
                self.navigationItem.rightBarButtonItem?.isEnabled = false
            case .normal:
                self.navigationItem.rightBarButtonItem?.isEnabled = true
            }
        }
        self.inputWrapperView.showKeyboard()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.view.canResignFirstResponder {
            self.view.endEditing(true)
        }
    }

    @objc
    func rightBarButtonEvent() {
        guard let chatID = Int64(self.setURLNameModel.chatId) else { return }
        let inputText = self.inputWrapperView.inputText
        let urlPreviewInfo = self.setURLNameModel.urlPreviewInfo
        var iconDic: [String: Any] = ["udIcon": urlPreviewInfo?.udIcon ?? "",
                                      "iconKey": urlPreviewInfo?.iconKey ?? "",
                                      "iconUrl": urlPreviewInfo?.iconUrl ?? ""]
        if let passThrough = self.setURLNameModel.urlPreviewInfo?.imageSetPassThrough {
            iconDic.merge(ChatTabImagePassThroughConfig.convertToJsonDic(passThrough)) { _, new in return new }
        }
        let jsonDic: [String: Any] = ["name": inputText,
                                      "url": setURLNameModel.url,
                                      "icon": iconDic]
        var jsonPayload: String?
        if let data = try? JSONSerialization.data(withJSONObject: jsonDic) {
            jsonPayload = String(data: data, encoding: .utf8)
        }
        self.rightItem.button.isUserInteractionEnabled = false

        // todo 的临时逻辑，赶时间先这么写一下，二期马上就会对齐 doc 的实现 from: baiyantao
        var type: RustPB.Im_V1_ChatTab.TypeEnum = .url
        if let url = URL(string: setURLNameModel.url), todoService?.isTaskListAppLink(url) == true {
            type = .task
        }

        self.chatAPI?.addChatTab(chatId: chatID, name: inputText, type: type, jsonPayload: jsonPayload)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] response in
                guard let self = self else { return }
                self.rightItem.button.isUserInteractionEnabled = true
                IMTracker.Chat.DocPageAdd.Click.TabSave(
                    self.setURLNameModel.chat,
                    params: ["name_add": "true",
                             "tab_id": response.newTabID,
                             "file_id": "NA"]
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
            }).disposed(by: disposeBag)
    }
}

final class ChatTabSetURLTitleView: UIView {
    static let logger = Logger.log(ChatTabSetURLTitleView.self, category: "Module.IM.ChatTab")
    private lazy var tipLabel: UILabel = {
        let tipLabel = UILabel()
        tipLabel.font = UIFont.systemFont(ofSize: 14)
        tipLabel.textColor = UIColor.ud.textCaption
        tipLabel.text = BundleI18n.LarkChat.Lark_IM_AddTabs_LinkTitle
        return tipLabel
    }()

    private lazy var containerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.ud.bgBody
        containerView.layer.cornerRadius = 10
        return containerView
    }()

    private lazy var iconImageView: UIImageView = {
        let iconImageView = UIImageView()
        return iconImageView
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
        containerView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(16)
            make.size.equalTo(40)
            make.centerY.equalToSuperview()
        }
        containerView.addSubview(titleLabel)
        containerView.addSubview(subTitleLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setModel(_ model: ChatAddTabSetURLModel) {
        let defaultIcon = UDIcon.getIconByKey(.fileRoundLinkColorful, size: CGSize(width: 40, height: 40))
        guard let urlPreviewInfo = model.urlPreviewInfo else {
            self.titleLabel.text = model.url
            self.subTitleLabel.isHidden = true
            titleLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(iconImageView.snp.right).offset(12)
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().inset(16)
            }
            iconImageView.image = defaultIcon
            return
        }
        self.titleLabel.text = urlPreviewInfo.title
        self.subTitleLabel.isHidden = false
        self.subTitleLabel.text = model.url
        titleLabel.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().offset(12)
            make.left.equalTo(iconImageView.snp.right).offset(12)
            make.right.equalToSuperview().inset(16)
            make.height.equalTo(22)
        }
        subTitleLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.left.equalTo(iconImageView.snp.right).offset(12)
            make.right.equalToSuperview().inset(16)
        }
        if let udIconKey = urlPreviewInfo.udIcon, !udIconKey.isEmpty {
            iconImageView.image = URLPreviewUDIcon.getIconByKey(udIconKey, iconColor: UIColor.ud.textLinkNormal, size: CGSize(width: 40, height: 40)) ?? defaultIcon
            return
        }
        let iconKey = urlPreviewInfo.iconKey ?? urlPreviewInfo.iconUrl
        if let iconKey = iconKey, !iconKey.isEmpty {
            iconImageView.bt.setLarkImage(with: .default(key: iconKey),
                                          placeholder: defaultIcon) { [weak iconImageView] res in
                switch res {
                case .success(let imageResult):
                    if let image = imageResult.image {
                        iconImageView?.setImage(image, tintColor: UIColor.ud.textLinkNormal)
                    }
                case .failure(let error):
                    Self.logger.error("set image fail", error: error)
                }
            }
            return
        }
        iconImageView.image = defaultIcon
    }
}

struct ChatAddTabSetURLModel {
    let chatId: String
    let chat: Chat
    let url: String
    let urlPreviewInfo: URLPreviewInfo?

    public init(chatId: String,
                chat: Chat,
                url: String,
                urlPreviewInfo: URLPreviewInfo?) {
        self.chatId = chatId
        self.chat = chat
        self.url = url
        self.urlPreviewInfo = urlPreviewInfo
    }
}
