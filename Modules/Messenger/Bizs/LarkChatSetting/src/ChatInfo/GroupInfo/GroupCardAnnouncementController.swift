//
//  GroupCardAnnouncementController.swift
//  Lark
//
//  Created by chengzhipeng-bytedance on 2017/12/5.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift
import LarkModel
import LarkFoundation
import RichLabel
import SnapKit
import LKCommonsLogging
import EENavigator
import UniverseDesignToast
import LarkAccountInterface
import LarkSDKInterface
import LarkSendMessage
import LarkMessengerInterface
import LarkFeatureGating
import DateToolsSwift
import RustPB
import UniverseDesignEmpty
import LarkContainer

final class GroupCardDisplayAnnouncementView: UIView, LKLabelDelegate {
    private(set) var scrollView: UIScrollView!
    private(set) var contentLabel: LKLabel = .init()
    private(set) var titleLabel: UILabel = .init()

    weak var delegate: LKLabelDelegate? {
        didSet {
            self.contentLabel.delegate = delegate
        }
    }

    var hasContent: Bool = true {
        didSet {
            self.titleLabel.snp.updateConstraints({ (make) in
                make.top.equalTo(self.hasContent ? 15 : 0)
            })
        }
    }

    override var bounds: CGRect {
        didSet {
            contentLabel.preferredMaxLayoutWidth = self.bounds.width - 31
            contentLabel.invalidateIntrinsicContentSize()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear

        let scrollView = UIScrollView(frame: .zero)
        scrollView.backgroundColor = UIColor.clear
        scrollView.alwaysBounceHorizontal = false
        scrollView.clipsToBounds = true
        scrollView.contentInsetAdjustmentBehavior = .never
        self.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.scrollView = scrollView

        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.N500
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 1
        scrollView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.top.equalTo(15)
            make.right.lessThanOrEqualTo(-15)
        }
        self.titleLabel = titleLabel

        let contentLabel = LKLabel(frame: .zero).lu.setProps(fontSize: 16, numberOfLine: 0, textColor: UIColor.ud.N900)
        contentLabel.textCheckingDetecotor = DataCheckDetector
        scrollView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { (make) in
            make.left.equalTo(15)
            make.right.bottom.equalTo(-15)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(12)
        }
        let blueLink: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(rawValue: kCTForegroundColorAttributeName as String): UIColor.ud.colorfulBlue.cgColor,
            NSAttributedString.Key(rawValue: kCTUnderlineStyleAttributeName as String): 0
        ]
        contentLabel.linkAttributes = blueLink
        self.contentLabel = contentLabel
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(content: String) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3
        let attribute = LKLabel.lu.basicAttribute(foregroundColor: UIColor.ud.N900,
                                                  atMeBackground: nil,
                                                  lineSpacing: 3,
                                                  font: UIFont.systemFont(ofSize: 16),
                                                  lineBreakMode: NSLineBreakMode.byWordWrapping)
        self.contentLabel.attributedText = NSAttributedString(string: content, attributes: attribute)
    }

    func set(title: String) {
        self.titleLabel.text = title
    }
}

final class GroupCardEdittingAnnouncementView: UIView, UITextViewDelegate {
    private(set) var textView: UITextView!
    private(set) var titleLabel: UILabel = .init()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.isUserInteractionEnabled = true

        let textView = UITextView()
        textView.backgroundColor = UIColor.clear
        textView.textColor = UIColor.ud.N900
        textView.dataDetectorTypes = [.link, .phoneNumber]
        textView.delegate = self
        textView.isSelectable = false
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        textView.textContainerInset = UIEdgeInsets(top: 42, left: 12, bottom: 12, right: 12)
        textView.linkTextAttributes = [
            .foregroundColor: UIColor.ud.colorfulBlue,
            .font: UIFont.systemFont(ofSize: 16)]
        textView.font = UIFont.systemFont(ofSize: 16)
        self.addSubview(textView)
        textView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.textView = textView

        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.N500
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 1
        textView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.top.equalTo(15)
            make.right.equalTo(-15)
        }
        self.titleLabel = titleLabel

        self.layoutIfNeeded()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(title: String, textContent: String) {
        self.titleLabel.text = title
        self.textView.text = textContent
    }
}

final class GroupCardAnnouncementController: BaseSettingController {
    static let logger = Logger.log(GroupCardAnnouncementController.self, category: "group.card.announcement")

    fileprivate let disposeBag = DisposeBag()

    let chatId: String

    fileprivate let hasAccess: Bool

    fileprivate let chat: LarkModel.Chat
    fileprivate let announcement: LarkModel.Chat.Announcement

    fileprivate var displayView: GroupCardDisplayAnnouncementView?
    fileprivate var editView: GroupCardEdittingAnnouncementView?

    private lazy var emptyView: UDEmptyView = {
        let emptyDesc = UDEmptyConfig.Description(descriptionText: BundleI18n.LarkChatSetting.Lark_Legacy_GroupAnnouncementNone)
        let emptyView = UDEmptyView(config: UDEmptyConfig(description: emptyDesc, type: .noGroup))
        emptyView.backgroundColor = UIColor.ud.N00
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        return emptyView
    }()

    fileprivate var rightItem: LKBarButtonItem? {
        return self.navigationItem.rightBarButtonItem as? LKBarButtonItem
    }

    fileprivate var chatterAPI: ChatterAPI
    fileprivate var chatAPI: ChatAPI
    fileprivate var sendMessageAPI: SendMessageAPI
    fileprivate var sendThreadAPI: SendThreadAPI

    fileprivate var hasContent: Bool {
        return !self.announcement.content.isEmpty
    }

    fileprivate var rightItemStyle: RightItemStyle = .display {
        didSet {
            switch rightItemStyle {
            case .display:
                self.updateRightItem(title: BundleI18n.LarkChatSetting.Lark_Legacy_Edit, color: UIColor.ud.N900, font: LKBarButtonItem.FontStyle.regular.font)
                self.displayView?.isHidden = false
                self.editView?.isHidden = true
            case .edit:
                self.updateRightItem(title: BundleI18n.LarkChatSetting.Lark_Legacy_Save, color: UIColor.ud.colorfulBlue, font: LKBarButtonItem.FontStyle.medium.font)
                self.displayView?.isHidden = true
                self.editView?.isHidden = false
            }
        }
    }
    private let navi: Navigatable
    init?(userResolver: UserResolver,
          chatId: String,
          chatAPI: ChatAPI,
          chatterAPI: ChatterAPI,
          sendMessageAPI: SendMessageAPI,
          sendThreadAPI: SendThreadAPI,
          navi: Navigatable) {
        self.chatId = chatId
        self.chatterAPI = chatterAPI
        self.chatAPI = chatAPI
        self.sendMessageAPI = sendMessageAPI
        self.sendThreadAPI = sendThreadAPI
        self.navi = navi
        guard let chat = chatAPI.getLocalChat(by: chatId) else { return nil }

        self.chat = chat
        self.announcement = chat.announcement

        // 是否是群管理
        let isGroupAdmin = chat.isGroupAdmin
        let isOwner = (chat.ownerId == userResolver.userID)
        self.hasAccess = isOwner || isGroupAdmin || !chat.offEditGroupChatInfo

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = BundleI18n.LarkChatSetting.Lark_Legacy_Announcement
        self.registerNotification()
        self.setupSubviews()
        self.setNavigationBarRightItem()
        self.setAccessHandler(self.hasAccess)
        self.setReadAnnouncement()

        emptyView.isHidden = hasContent
    }

    private func setReadAnnouncement() {
        chatAPI.readChatAnnouncement(by: chatId, updateTime: chat.announcement.updateTime).subscribe().dispose()
    }

    fileprivate func setAccessHandler(_ hasAccess: Bool) {
        if hasAccess == false {
            self.updateRightItem(title: "", color: UIColor.clear, font: LKBarButtonItem.FontStyle.regular.font)
        }
    }

    fileprivate func registerNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardFrameChange(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardFrameChange(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    fileprivate func setupSubviews() {
        let contentText = self.hasContent ? self.announcement.content : BundleI18n.LarkChatSetting.Lark_Legacy_GroupAnnouncementNone
        let displayView = GroupCardDisplayAnnouncementView()
        displayView.delegate = self
        displayView.hasContent = self.hasContent
        displayView.set(content: contentText)
        self.view.addSubview(displayView)
        displayView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.displayView = displayView
        self.setPostAnnouncementTime()

        let editView = GroupCardEdittingAnnouncementView()
        editView.set(title: BundleI18n.LarkChatSetting.Lark_Legacy_GroupAnnouncementTips, textContent: self.announcement.content)
        self.view.addSubview(editView)
        editView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.editView = editView
    }

    func setNavigationBarRightItem() {
        let rightItem = LKBarButtonItem(title: BundleI18n.LarkChatSetting.Lark_Legacy_Edit)
        rightItem.setProperty(alignment: .right)
        rightItem.addTarget(self, action: #selector(navigationBarRightItemTapped), for: .touchUpInside)
        self.rightItemStyle = .display
        self.navigationItem.rightBarButtonItem = rightItem
    }

    fileprivate func setAnnoucement(time: Int64, userName: String) -> String {
        let nowDate = Date(timeIntervalSince1970: TimeInterval(time))
        let isToday = NSCalendar.current.isDateInToday(nowDate)
        let year = NSCalendar.current.component(.year, from: nowDate)

        var timeStamp = ""
        if isToday {
            timeStamp = nowDate.format(with: "H:mm")
        } else if nowDate.component(.year) != year {
            timeStamp = nowDate.format(with: BundleI18n.LarkChatSetting.Lark_Legacy_CommonLongDateTimeFormat)
        } else {
            timeStamp = nowDate.format(with: BundleI18n.LarkChatSetting.Lark_Legacy_DateFormatMdT)
        }
        return BundleI18n.LarkChatSetting.Lark_Legacy_GroupAnnouncementPostTime(userName, timeStamp)
    }

    func updateRightItem(title: String, color: UIColor, font: UIFont) {
        self.rightItem?.resetTitle(title: title, font: font)
        self.rightItem?.setBtnColor(color: color)
    }

    /// 有内容时显示谁发的内容
    fileprivate func setPostAnnouncementTime() {
        if self.hasContent {
            self.chatterAPI.getChatChatters(ids: [self.announcement.lastEditorID], chatId: self.chatId)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (userModels) in
                    guard let `self` = self else { return }
                    if let user = userModels[self.announcement.lastEditorID] {
                        let displayName = user.displayName(chatId: self.chatId, chatType: .group, scene: .postAnnouncement)
                        let titleText = self.setAnnoucement(time: self.announcement.updateTime, userName: displayName)
                        self.displayView?.set(title: titleText)
                    }
                })
                .disposed(by: self.disposeBag)
        }
    }

    @objc
    fileprivate func keyboardFrameChange(_ notify: Notification) {
        guard let userinfo = notify.userInfo, self.rightItemStyle == .edit else {
            return
        }
        let duration: TimeInterval = userinfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0
        if notify.name == UIResponder.keyboardWillShowNotification {
            guard let toFrame = userinfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                return
            }
            let keyboardHeight = toFrame.size.height + 15
            UIView.animate(withDuration: duration, animations: {
                self.editView?.snp.updateConstraints({ (make) in
                    make.bottom.equalTo(-keyboardHeight)
                })
            }, completion: { (_) in
                self.editView?.textView.lu.scrollToBottom(animated: true)
            })
        } else if notify.name == UIResponder.keyboardWillHideNotification {
            UIView.animate(withDuration: duration, animations: {
                self.editView?.snp.updateConstraints({ (make) in
                    make.bottom.equalToSuperview()
                })
            }, completion: { (_) in
                self.editView?.textView.lu.scrollToTop(animated: true)
            })
        }
    }

    @objc
    fileprivate func navigationBarRightItemTapped() {
        switch self.rightItemStyle {
        case .display:
            self.rightItemStyle = .edit
            self.emptyView.isHidden = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.editView?.textView.becomeFirstResponder()
            }
        case .edit:
            let announcement = self.editView?.textView.text.lf.trimCharacters(in: .whitespacesAndNewlines, postion: .tail) ?? ""
            guard self.chat.announcement.content != announcement else {
                self.navigationController?.popViewController(animated: true)
                return
            }

            let sendMessageAPI = self.sendMessageAPI
            let sendThreadAPI = self.sendThreadAPI

            let hud = UDToast.showLoading(on: view)
            self.chatAPI
                .updateChat(chatId: self.chatId, announcement: announcement)
                .observeOn(MainScheduler.instance)
                .map({ (chat) -> Chat in
                    if !announcement.isEmpty {
                        let postRichText = RustPB.Basic_V1_RichText.text(announcement)
                        if chat.chatMode == .threadV2 {
                            sendThreadAPI.sendPost(
                                context: nil,
                                to: .threadChat,
                                title: BundleI18n.LarkChatSetting.Lark_Groups_Announcement,
                                content: postRichText,
                                chatId: chat.id,
                                isGroupAnnouncement: false,
                                preprocessingHandler: nil)
                        } else {
                            sendMessageAPI.sendPost(
                                context: nil,
                                title: BundleI18n.LarkChatSetting.Lark_Legacy_GroupAnnouncement,
                                content: postRichText,
                                parentMessage: nil,
                                chatId: chat.id,
                                threadId: nil,
                                isGroupAnnouncement: false,
                                scheduleTime: nil,
                                preprocessingHandler: nil,
                                sendMessageTracker: nil,
                                stateHandler: nil
                            )
                        }
                    }
                    return chat
                }).subscribe(onNext: { [weak self, weak hud] (_) in
                    guard let `self` = self else { return }
                    hud?.showSuccess(with: BundleI18n.LarkChatSetting.Lark_Legacy_SendAnnouncementSuccess, on: self.view)
                    self.navigationController?.popViewController(animated: true)
                }, onError: { [weak self, weak hud] (error) in
                    if let apiError = error.underlyingError as? APIError,
                        case .announcementAPIInvalid = apiError.type {
                        if let self = self {
                            hud?.showFailure(
                                with: BundleI18n.LarkChatSetting.Lark_Legacy_SendAnnouncementFailedPleaseUpdate,
                                on: self.view,
                                error: error
                            )
                        }
                    } else if let self = self {
                        hud?.showFailure(
                            with: BundleI18n.LarkChatSetting.Lark_Legacy_GroupAnnouncementChangeFailed,
                            on: self.view,
                            error: error
                        )
                    }
                    GroupCardAnnouncementController.logger.error("update announcement failed", error: error)
                }).disposed(by: self.disposeBag)
        }
    }
}

extension GroupCardAnnouncementController: LKLabelDelegate {
    func attributedLabel(_ label: LKLabel, didSelectLink url: URL) {
        navi.push(url, context: ["from": "group_tab_notice"], from: self)
    }

    func attributedLabel(_ label: LKLabel, didSelectPhoneNumber phoneNumber: String) {
        navi.open(body: OpenTelBody(number: phoneNumber), from: self)
    }
}
