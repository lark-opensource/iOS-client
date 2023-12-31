//
//  MyAIToolsDetailViewController.swift
//  LarkIMMention
//
//  Created by ByteDance on 2023/5/24.
//  MyAITools 详情

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import RxSwift
import RxCocoa
import UniverseDesignColor
import UniverseDesignIcon
import LKRichView
import LarkRichTextCore
import LarkMessengerInterface
import LarkModel
import LarkContainer
import UniverseDesignButton
import LKCommonsLogging
import UniverseDesignToast
import LKCommonsTracker
import Homeric
import LarkCore
import LarkAIInfra

final class MyAIToolsDetailViewController: BaseUIViewController, UserResolverWrapper {

    static let logger = Logger.log(MyAIToolsDetailViewController.self, category: "Module.LarkAI.MyAITool")
    public let toolItem: MyAIToolInfo
    public let addToolHandler: ((MyAIToolInfo) -> Void)?
    var userResolver: LarkContainer.UserResolver
    private let chat: Chat
    private var myAIPageService: MyAIPageService?

    lazy var dividerView: UIView = {
        let view = UIView()
        // 分割线颜色先用clear替换，避免善变的UX又变更了回来还得重新加上(灬ꈍ ꈍ灬)
        view.backgroundColor = UIColor.clear
        return view
    }()

    lazy var titleLable: UILabel = {
        let lable = UILabel()
        lable.textColor = UIColor.ud.textTitle
        lable.font = UIFont.ud.title2
        lable.numberOfLines = 2
        lable.textAlignment = .center
        return lable
    }()

    lazy var detailLable: UILabel = {
        let lable = UILabel()
        lable.textColor = UIColor.ud.textCaption
        lable.font = UIFont.ud.body0
        lable.numberOfLines = 6
        lable.textAlignment = .left
        return lable
    }()

    private lazy var avatarView: MyAIToolAvatarView = {
        let avatarView = MyAIToolAvatarView()
        return avatarView
    }()

    private lazy var addButton: UIButton = {
        let button = UDButton.primaryBlue
        button.config.type = .big
        button.config.radiusStyle = .square
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.titleLabel?.font = UIFont.ud.body0
        button.addTarget(self, action: #selector(addToolAction), for: .touchUpInside)
        return button
    }()
    private let disposeBag = DisposeBag()
    private let isSingleSelect: Bool
    private var myAIToolRustService: RustMyAIToolServiceAPI?
    private var aiService: MyAIService?
    private var extra: [AnyHashable: Any]

    init(toolItem: MyAIToolInfo,
         isSingleSelect: Bool,
         userResolver: UserResolver,
         chat: Chat,
         myAIPageService: MyAIPageService? = nil,
         extra: [AnyHashable: Any] = [:],
         addToolHandler: ((MyAIToolInfo) -> Void)? = nil) {
        self.toolItem = toolItem
        self.isSingleSelect = isSingleSelect
        self.userResolver = userResolver
        self.chat = chat
        self.aiService = try? userResolver.resolve(assert: MyAIService.self)
        self.myAIPageService = myAIPageService
        self.extra = extra
        self.myAIToolRustService = try? userResolver.resolve(assert: RustMyAIToolServiceAPI.self)
        self.addToolHandler = addToolHandler
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = toolItem.toolName
        self.view.backgroundColor = UIColor.ud.bgBody

        setupSubViews()
    }

    private func addClickIMTracker() {
        guard let myAIPageService = self.myAIPageService else {
            Self.logger.info("my ai add IMTracker, service is none")
            return
        }
        IMTracker.Chat.Main.Click.selectExtension(
            self.chat,
            params: self.extra,
            myAIPageService.chatFromWhere)
    }

    func setupSubViews() {
        if isSingleSelect {
            addButton.setTitle(BundleI18n.LarkAI.MyAI_IM_Extension_Use_Button, for: .normal)
        } else {
            self.addButton.isHidden = (toolItem.isSelected || !toolItem.enabled)
            addButton.setImage(Resources.my_ai_tool_add, for: .normal)
            addButton.setTitle(BundleI18n.LarkAI.MyAI_IM_SelectExtension_Button, for: .normal)
        }
        self.avatarView.setAvatarBy(by: toolItem.toolId, avatarKey: toolItem.toolAvatar)
        self.titleLable.text = toolItem.toolName
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = 22
        paragraphStyle.minimumLineHeight = 22
        paragraphStyle.lineSpacing = 2
        let attributes = [NSAttributedString.Key.font: UIFont.ud.body0,
                          NSAttributedString.Key.paragraphStyle: paragraphStyle,
                          NSAttributedString.Key.foregroundColor: UIColor.ud.textCaption]
        let detailAttr = NSMutableAttributedString(string: toolItem.toolInfo ?? "", attributes: attributes)
        self.detailLable.attributedText = detailAttr
        view.addSubview(dividerView)
        view.addSubview(avatarView)
        view.addSubview(titleLable)
        view.addSubview(detailLable)
        view.addSubview(addButton)
        dividerView.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(Cons.dividerViewHeight)
        }
        avatarView.snp.makeConstraints { make in
            make.top.equalTo(dividerView.snp.bottom).offset(Cons.avatarTopMargin)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: Cons.avatarViewWidth, height: Cons.avatarViewWidth))
        }
        titleLable.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Cons.detailLabelHMargin)
            make.top.equalTo(avatarView.snp.bottom).offset(Cons.titleLabelTopMargin)
            make.right.equalToSuperview().offset(-Cons.detailLabelHMargin)
        }
        detailLable.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Cons.detailLabelHMargin)
            make.top.equalTo(titleLable.snp.bottom).offset(Cons.detailLabelTopMargin)
            make.right.equalToSuperview().offset(-Cons.detailLabelHMargin)
            make.bottom.lessThanOrEqualToSuperview().offset(-Cons.detailLabelBottomMargin)
        }
        addButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Cons.addButtonHMargin)
            make.right.equalToSuperview().offset(-Cons.addButtonHMargin)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-Cons.addButtonBottomMargin)
        }
        titleLable.setContentHuggingPriority(.defaultHigh, for: .vertical)
        titleLable.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        detailLable.setContentHuggingPriority(.defaultLow, for: .vertical)
        detailLable.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    }

    func selectedToolCallBack() {
        guard let aiService = self.aiService else { return }
        let extensionInfoList = [MyAIExtensionInfo(id: self.toolItem.toolId, name: self.toolItem.toolName, avatarKey: self.toolItem.toolAvatar)]
        let extensionCallBackInfo = MyAIExtensionCallBackInfo(extensionList: extensionInfoList, fromVc: nil)
        aiService.selectedExtension.accept(extensionCallBackInfo)
    }

    func confimUseTool() {
        addClickIMTracker()
        let loadingHUD = UDToast.showDefaultLoading(with: BundleI18n.LarkAI.Lark_LocalDataEncryptionKey_LoadingTitle, on: self.view, disableUserInteraction: true)
        let messageId = (extra["msg_id"] as? String) ?? ""
        let aiChatModeId = myAIPageService?.chatModeConfig.aiChatModeId ?? 0
        self.myAIToolRustService?.sendMyAITools(toolIds: [self.toolItem.toolId],
                                                messageId: messageId,
                                                aiChatModeID: aiChatModeId,
                                                toolInfoList: [self.toolItem])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                loadingHUD.remove()
                guard let self = self else { return }
                Self.logger.info("set my ai tools success")
                self.selectedToolCallBack()
                self.closeBtnTapped()
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                Self.logger.info("set my ai tools failure error: \(error)")
                UDToast.showFailure(
                    with: BundleI18n.LarkAI.Lark_Legacy_NetworkOrServiceError,
                    on: self.view,
                    error: error.transformToAPIError()
                )
            }).disposed(by: self.disposeBag)
    }

    @objc
    private func addToolAction() {
        if self.isSingleSelect {
            self.confimUseTool()
        } else {
            self.addToolHandler?(toolItem)
            dismiss()
        }
    }

    func dismiss() {
        self.backItemTapped()
    }
}

extension MyAIToolsDetailViewController {
    enum Cons {
        static var dividerViewHeight: CGFloat { 0 }
        static var avatarViewWidth: CGFloat { 64 }
        static var avatarTopMargin: CGFloat { 38 }
        static var titleLabelTopMargin: CGFloat { 12 }
        static var detailLabelHMargin: CGFloat { 20 }
        static var detailLabelTopMargin: CGFloat { 20 }
        static var detailLabelBottomMargin: CGFloat { 80 }
        static var addButtonHMargin: CGFloat { 16 }
        static var addButtonBottomMargin: CGFloat { 20 }
    }
}
