//
//  ChangeGroupDescriptionController.swift
//  Lark
//
//  Created by chengzhipeng-bytedance on 2017/7/28.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import LarkUIKit
import LarkFoundation
import RichLabel
import LarkModel
import LKCommonsLogging
import EENavigator
import UniverseDesignToast
import LarkSDKInterface
import LarkMessengerInterface
import LarkAlertController
import EditTextView
import LarkKeyboardKit
import LarkFeatureGating
import UniverseDesignEmpty

enum RightItemStyle {
    case display, edit
}

final class GroupDescriptionController: BaseSettingController, EditTextViewTextDelegate {
    private static let logger = Logger.log(
        GroupDescriptionController.self,
        category: "Module.IM.GroupDescriptionController")

    private let disposeBag = DisposeBag()
    private(set) var rightItem: LKBarButtonItem?
    private(set) var displayView: GroupDescriptionDisplayView?
    private(set) var editView: GroupDescriptionEditView?
    private let chat: Chat
    private(set) var currentChatterId: String
    // 是否是群管理
    var isGroupAdmin: Bool {
        return chat.isGroupAdmin
    }
    private var hasAccess: Bool {
        return !chat.isOncall && chat.isAllowPost && (chat.ownerId == currentChatterId || isGroupAdmin || !chat.offEditGroupChatInfo)
    }
    var isOwner: Bool {
        currentChatterId == chat.ownerId
    }

    private let groupDescription: String
    private let chatAPI: ChatAPI
    private lazy var emptyView: UDEmptyView = {
        let content = (chat.chatMode == .threadV2) ?
            BundleI18n.LarkChatSetting.Lark_Groups_DescriptionEmpty :
            BundleI18n.LarkChatSetting.Lark_Legacy_DescriptionEmpty
        let emptyDesc = UDEmptyConfig.Description(descriptionText: content)
        let emptyView = UDEmptyView(config: UDEmptyConfig(description: emptyDesc, type: .noGroup))
        emptyView.backgroundColor = UIColor.ud.bgFloatBase
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        return emptyView
    }()

    private(set) var rightItemStyle: RightItemStyle = .display {
        didSet {
            switch rightItemStyle {
            case .display:
                let font = LKBarButtonItem.FontStyle.regular.font
                self.updateRightItem(title: BundleI18n.LarkChatSetting.Lark_Legacy_Edit, color: UIColor.ud.N900, font: font)
                self.displayView?.isHidden = false
                self.editView?.isHidden = true
            case .edit:
                let font = LKBarButtonItem.FontStyle.medium.font
                self.updateRightItem(title: BundleI18n.LarkChatSetting.Lark_Legacy_Save, color: UIColor.ud.colorfulBlue, font: font)
                self.displayView?.isHidden = true
                self.editView?.isHidden = false
            }
        }
    }

    private let maxTextCount = 100
    private let navi: Navigatable

    init(chat: Chat, currentChatterId: String, chatAPI: ChatAPI, navi: Navigatable) {
        self.chat = chat
        self.groupDescription = chat.description
        self.currentChatterId = currentChatterId
        self.chatAPI = chatAPI
        self.navi = navi
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NewChatSettingTracker.imEditGroupDescriptionView(chat: self.chat)
        self.setupSubviews()
    }

    func setupRightItemStyle() {
        if self.hasAccess && self.groupDescription.isEmpty {
            self.rightItemStyle = .edit
            emptyView.isHidden = true
            self.editView?.inputTextView.becomeFirstResponder()
        } else {
            emptyView.isHidden = !groupDescription.isEmpty
            self.rightItemStyle = .display
        }
    }

    func setupSubviews() {
        self.view.backgroundColor = UIColor.ud.bgFloatBase

        // edit view
        let editView = GroupDescriptionEditView()
        editView.backgroundColor = UIColor.clear
        self.view.addSubview(editView)
        editView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        editView.inputTextView.textDelegate = self
        self.editView = editView
        self.editView?.set(content: groupDescription)
        let attr = NSAttributedString(string: "\((groupDescription as NSString).length)/\(maxTextCount)",
                                      attributes: [.foregroundColor: UIColor.ud.N500])
        self.editView?.set(textCount: attr)

        // display view
        let displayView = GroupDescriptionDisplayView()
        displayView.delegate = self
        displayView.backgroundColor = UIColor.clear
        self.view.addSubview(displayView)
        displayView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.displayView = displayView
        self.displayView?.set(content: groupDescription)
        self.setupNavigationBar()
        self.setupRightItemStyle()
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    func setupNavigationBar() {
        let item = LKBarButtonItem()
        item.setProperty(alignment: .right)
        item.setBtnColor(color: UIColor.ud.colorfulBlue)
        item.button.addTarget(self, action: #selector(navigationBarRightItemTapped), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = item
        self.rightItem = item
        self.rightItem?.button.isHidden = !self.hasAccess
    }

    func updateRightItem(title: String, color: UIColor, font: UIFont) {
        self.rightItem?.resetTitle(title: title, font: font)
        self.rightItem?.setBtnColor(color: color)
    }

    @objc
    fileprivate func navigationBarRightItemTapped() {
        switch self.rightItemStyle {
        case .display:
            self.rightItemStyle = .edit
            self.emptyView.isHidden = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.editView?.inputTextView.becomeFirstResponder()
            }
        case .edit:
            let text = editView?.inputTextView.text ?? ""
            if text.count > maxTextCount {
                UDToast.showTips(with: BundleI18n.LarkChatSetting.Lark_Group_DescriptionCharacterLimitExceeded, on: view)
            } else {
                self.editView?.inputTextView.resignFirstResponder()
                self.saveNewDescription()
            }
        }
    }

    private func saveNewDescription() {
        guard hasAccess else {
            let alertController = LarkAlertController()
            let content = BundleI18n.LarkChatSetting.Lark_Legacy_OnlyGOGAEditGroupInfo
            alertController.setContent(text: content)
            alertController.addPrimaryButton(text: BundleI18n.LarkChatSetting.Lark_Legacy_Sure)
            self.navi.present(alertController, from: self)
            return
        }

        let new = self.editView?.inputTextView.text ?? ""
        NewChatSettingTracker.imChatSettingEditDescriptionSaveClick(chatId: chat.id,
                                                                    isAdmin: isOwner,
                                                                    altered: new != groupDescription,
                                                                    charCount: new.count,
                                                                    chat: chat)
        guard new != groupDescription else {
            self.dismissSelf()
            return
        }

        let hud = UDToast.showLoading(on: view)

        chatAPI.updateChat(chatId: chat.id, description: new)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak hud] _ in
                if let self = self {
                    hud?.showSuccess(with: BundleI18n.LarkChatSetting.Lark_Legacy_SaveSuccess, on: self.view)
                    self.dismissSelf()
                }
            }, onError: { [weak self] (error) in
                GroupDescriptionController.logger.error("modify group description failed", error: error)
                if let self = self {
                    hud.showFailure(
                        with: BundleI18n.LarkChatSetting.Lark_Legacy_ChatGroupInfoModifyGroupDescriptionFailed,
                        on: self.view,
                        error: error
                    )
                }
            }, onCompleted: { [weak self] in
                if let self = self {
                    UDToast.removeToast(on: self.view)
                }
            }).disposed(by: disposeBag)
    }

    private func dismissSelf() {
        if self.presentingViewController != nil {
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    func textChange(text: String, textView: LarkEditTextView) {
        let count = (text as NSString).length
        if count > maxTextCount {
            self.rightItem?.setBtnColor(color: UIColor.ud.N400)
            let attr = NSMutableAttributedString(string: "\(count)",
                                                 attributes: [.foregroundColor: UIColor.ud.colorfulRed])
            attr.append(NSAttributedString(string: "/\(maxTextCount)",
                                           attributes: [.foregroundColor: UIColor.ud.N500]))
            editView?.set(textCount: attr)
        } else {
            self.rightItem?.setBtnColor(color: UIColor.ud.colorfulBlue)
            let attr = NSAttributedString(string: "\(count)/\(maxTextCount)",
                                          attributes: [.foregroundColor: UIColor.ud.N500])
            editView?.set(textCount: attr)
        }
    }
}

extension GroupDescriptionController: LKLabelDelegate {
    func attributedLabel(_ label: LKLabel, didSelectLink url: URL) {
        self.navi.push(url, context: [
            "from": "lark",
            "scene": "messenger",
            "location": "messenger_group_description"
        ], from: self)
    }

    func attributedLabel(_ label: LKLabel, didSelectPhoneNumber phoneNumber: String) {
        self.navi.open(body: OpenTelBody(number: phoneNumber), from: self)
    }
}

final class GroupDescriptionDisplayView: UIView, LKLabelDelegate {
    private(set) var contentLabel: LKLabel = .init()

    weak var delegate: LKLabelDelegate? {
        didSet {
            self.contentLabel.delegate = delegate
        }
    }

    override var bounds: CGRect {
        didSet {
            contentLabel.preferredMaxLayoutWidth = self.bounds.width - 31
            contentLabel.invalidateIntrinsicContentSize()
        }
    }

    init() {
        super.init(frame: .zero)

        let contentLabel = LKLabel().lu.setProps(fontSize: 16, numberOfLine: 0, textColor: UIColor.ud.N900)
        contentLabel.textCheckingDetecotor = DataCheckDetector
        contentLabel.textAlignment = .left
        contentLabel.delegate = delegate
        let blueLink: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(rawValue: kCTForegroundColorAttributeName as String): UIColor.ud.colorfulBlue.cgColor,
            NSAttributedString.Key(rawValue: kCTUnderlineStyleAttributeName as String): 0
        ]
        contentLabel.linkAttributes = blueLink
        self.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { (make) in
            make.left.top.equalTo(15)
            make.right.equalTo(-15)
        }
        self.contentLabel = contentLabel
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(content: String) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3
        let attribute = LKLabel.lu.basicAttribute(
            foregroundColor: UIColor.ud.N900,
            atMeBackground: nil,
            lineSpacing: 3,
            font: UIFont.systemFont(ofSize: 16),
            lineBreakMode: NSLineBreakMode.byWordWrapping
        )
        self.contentLabel.attributedText = NSAttributedString(string: content, attributes: attribute)
    }
}

final class GroupDescriptionEditView: UIView {
    private(set) var inputTextView: LarkEditTextView = .init()
    private(set) var wrapperView: UIView = .init()
    private(set) var textCountLabel: UILabel = .init()
    private let disposeBag = DisposeBag()
    private var inputTextViewMaxH: CGFloat = 124 {
        didSet {
            guard inputTextViewMaxH > 0 else { return }
            inputTextView.maxHeight = inputTextViewMaxH
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        let wrapperView = UIView()
        wrapperView.backgroundColor = UIColor.ud.bgFloat
        self.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(Layout.wrapperTopMargin)
        }
        wrapperView.layer.cornerRadius = 10.0
        self.wrapperView = wrapperView

        let inputTextView = LarkEditTextView()
        let font = UIFont.systemFont(ofSize: 16)
        let defaultTypingAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.ud.N900
        ]
        inputTextView.defaultTypingAttributes = defaultTypingAttributes
        inputTextView.isScrollEnabled = false
        inputTextView.font = font
        inputTextView.textAlignment = .left
        inputTextView.textContainerInset = .zero
        inputTextView.placeholder = BundleI18n.LarkChatSetting.Lark_Legacy_SetADescription
        inputTextView.placeholderTextColor = UIColor.ud.N500
        inputTextView.maxHeight = inputTextViewMaxH
        inputTextView.backgroundColor = UIColor.clear
        self.wrapperView.addSubview(inputTextView)
        inputTextView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.top.equalToSuperview().offset(Layout.inputTextViewTopMargin)
            make.height.greaterThanOrEqualTo(124)
        }
        self.inputTextView = inputTextView

        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        wrapperView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.equalTo(inputTextView.snp.bottom).offset(Layout.labelTopMargin)
            make.trailing.equalTo(inputTextView)
            make.bottom.equalToSuperview().offset(-Layout.labelBottomMargin)
        }
        textCountLabel = label

        KeyboardKit.shared.keyboardHeightChange.distinctUntilChanged().drive(onNext: { [weak self] height in
            self?.updateEditView(by: height)
        }).disposed(by: disposeBag)

        DispatchQueue.main.async {
            let maxH = self.bounds.height - self.textCountLabel.bounds.height - Layout.totalMargin
            self.inputTextViewMaxH = maxH
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateEditView(by keyboardH: CGFloat) {
        let maxH = self.bounds.height - self.textCountLabel.bounds.height - Layout.totalMargin - keyboardH
        if keyboardH > 0, maxH > 0 {
            self.inputTextViewMaxH = maxH
            self.inputTextView.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(10)
                make.right.equalToSuperview().offset(-10)
                make.top.equalToSuperview().offset(Layout.inputTextViewTopMargin)
                make.height.greaterThanOrEqualTo(124)
                make.height.lessThanOrEqualTo(maxH)
            }
        }
        self.superview?.layoutIfNeeded()
    }

    func set(content: String) {
        self.inputTextView.text = content
    }

    func set(textCount: NSAttributedString) {
        textCountLabel.attributedText = textCount
    }
}

extension GroupDescriptionEditView {
    enum Layout {
        static let wrapperTopMargin: CGFloat = 16
        static let labelTopMargin: CGFloat = 4
        static let labelBottomMargin: CGFloat = 8
        static let inputTextViewTopMargin: CGFloat = 14
        static let inputTextViewBottomMargin: CGFloat = 16
        static var totalMargin: CGFloat {
            return wrapperTopMargin + labelTopMargin + labelBottomMargin + inputTextViewBottomMargin + inputTextViewTopMargin
        }
    }
}
