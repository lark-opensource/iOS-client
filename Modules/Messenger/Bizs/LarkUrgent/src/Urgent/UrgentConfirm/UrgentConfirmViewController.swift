//
//  UrgentConfirmViewController.swift
//  Lark
//
//  Created by zc09v on 2017/6/30.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import LarkModel
import LarkCore
import UniverseDesignToast
import LarkSDKInterface
import LarkMessengerInterface
import RxSwift
import LKCommonsLogging
import RustPB
import LarkRustClient
import LarkContainer

typealias UrgentResult = (urgentType: RustPB.Basic_V1_Urgent.TypeEnum, chatters: [Chatter])

final class UrgentConfirmViewController: BaseUIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UserResolverWrapper {
    let userResolver: UserResolver

    static let logger = Logger.log(UrgentConfirmViewController.self, category: "LarkUrgent.Confitm")

    fileprivate var urgentMessageViewsOfSupportUrgent: [UrgentConfirmMessageViewProtocol]
    fileprivate let message: Message
    fileprivate let itemWidth: CGFloat = 50
    fileprivate let itemHeight: CGFloat = 70
    fileprivate let lineSpacing: CGFloat = 15
    fileprivate let itemSpacing: CGFloat = 23
    fileprivate let channelId: String
    fileprivate let scene: UrgentScene

    var sendSelected: ((_ type: SendUrgentSelectType, _ cancelAck: Bool) -> Void)?
    var addCloseButton: Bool = false
    var supportChatterSectionModel: UrgentConfrimChatterSectionModel?
    var unSupportChatterSectionModels: [UrgentConfrimChatterSectionModel] = []
    var allSectionModels: [UrgentConfrimChatterSectionModel] = []
    var onlySupportAppUrgent: Bool = false

    var urgentType: RustPB.Basic_V1_Urgent.TypeEnum = .app {
        didSet {
            self.updateUrgentChatters()
        }
    }
    // 加急已读后是否发送通知
    var shouldSendReceipt: Bool = true

    // UI上展示的顺序
    let unsupportChatterTypes: [UnSupportChatterType] = [.crossGroup, .externalNotFriend, .emptyPhone, .emptyName]
    let mode: UrgentConfirmDisplayMode
    let collectionHeader: UrgentConfirmCollectionHeader
    private var isSuperChat: Bool { chat.isSuper }

    private let modelService: ModelService
    private let configurationAPI: ConfigurationAPI
    private var collectionView: UICollectionView = .init(frame: .zero, collectionViewLayout: .init())
    private var disposeBag = DisposeBag()
    private let chat: Chat

    fileprivate lazy var sureButtonItem: LKBarButtonItem = {
        let btnItem = LKBarButtonItem(title: BundleI18n.LarkUrgent.Lark_Legacy_Send, fontStyle: .medium)
        btnItem.setProperty(font: LKBarButtonItem.FontStyle.medium.font, alignment: .right)
        btnItem.setBtnColor(color: UIColor.ud.primaryContentDefault)
        btnItem.button.addTarget(self, action: #selector(didTapSure), for: .touchUpInside)
        return btnItem
    }()

    // MARK: life cycle
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(
        userResolver: UserResolver,
        message: Message,
        chat: Chat,
        mode: UrgentConfirmDisplayMode,
        channelId: String,
        scene: UrgentScene,
        modelService: ModelService,
        configurationAPI: ConfigurationAPI,
        enableTurnOffReadReceipt: Bool,
        rustService: RustService
    ) {
        self.userResolver = userResolver
        self.message = message
        self.mode = mode
        self.chat = chat
        self.configurationAPI = configurationAPI
        self.channelId = channelId
        self.modelService = modelService
        self.scene = scene
        self.urgentMessageViewsOfSupportUrgent = [UrgentConfirmMessageViewProtocol]()
        self.collectionHeader = UrgentConfirmCollectionHeader(isP2p: chat.type == .p2P, enableTurnOffReadReceipt: enableTurnOffReadReceipt)
        super.init(nibName: nil, bundle: nil)
        self.defaultSupportedUrgentMessageViews(rustService: rustService)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = sureButtonItem
        if addCloseButton {
            self.addCancelItem()
        }
        self.backCallback = { [weak self] in
            guard let self = self else { return }
            // track
            UrgentTracker.trackImDingConfirmClick(click: "return",
                                                  target: "im_ding_receiver_select_view",
                                                  chat: self.chat,
                                                  message: self.message)
        }
        self.title = BundleI18n.LarkUrgent.Lark_Legacy_UrgentConfirmTitle

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        layout.minimumInteritemSpacing = itemSpacing
        layout.minimumLineSpacing = lineSpacing
        layout.sectionInset = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.ud.bgBody
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.register(AvatarWithBottomNameCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: AvatarWithBottomNameCollectionViewCell.self))
        collectionView.register(ShowMoreCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ShowMoreCollectionViewCell.self))
        let hearderIndentifier = String(describing: UrgentChatterCollectionHeader.self)
        collectionView.register(UrgentChatterCollectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: hearderIndentifier)
        self.view.addSubview(collectionView)
        self.collectionView = collectionView
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        collectionHeader.modelService = modelService
        let urgentConfirmMessage = self.fetchSupportUrgentMessageView(supportType: message.type)
        let messageView = urgentConfirmMessage.fetchMessageView(
            message: message,
            modelService: modelService
        )
        messageView.backgroundColor = UIColor.ud.bgBase
        let heightOfView = urgentConfirmMessage.heightOfView(
            message: message,
            modelService: modelService
        )
        collectionHeader.set(messageView: messageView, heightOfView: heightOfView)
        collectionHeader.urgentConfirmMessage = urgentConfirmMessage
        collectionHeader.supportAllType = !self.onlySupportAppUrgent
        collectionHeader.urgentTypeChanged = { [weak self] urgentType in
            guard let `self` = self else { return false }
            if urgentType != .app && self.onlySupportAppUrgent {
                if urgentType == .phone {
                    UDToast.showTips(with: BundleI18n.LarkUrgent.Lark_buzz_HaveNotOpenedPhoneCall, on: self.view, delay: 1.5)
                } else if urgentType == .sms {
                    UDToast.showTips(with: BundleI18n.LarkUrgent.Lark_buzz_HaveNotOpenedMessage, on: self.view, delay: 1.5)
                }
                return false
            }
            self.urgentType = urgentType
            return true
        }
        collectionHeader.receiptSwitched = { [weak self] shouldSendReceipt in
            guard let self = self else { return }
            self.shouldSendReceipt = shouldSendReceipt
            if shouldSendReceipt {
                UDToast.showTips(with: BundleI18n.LarkUrgent.Lark_IM_Buzz_ReadReceipts_Enabled_Toast, on: self.view)
            } else {
                UDToast.showTips(with: BundleI18n.LarkUrgent.Lark_IM_Buzz_ReadReceipts_Disabled_Toast, on: self.view)
            }
        }
        collectionView.addSubview(collectionHeader)
        self.updateCollectionHeader()
        self.updateUrgentChatters()

        self.configurationAPI
            .fetchSmsPhoneSetting(strategy: .tryLocal)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (setting) in
                guard let `self` = self else { return }
                self.collectionHeader.updateNotifyBar(show: setting.canSend)
                self.updateCollectionHeader()
            }, onError: { (error) in
                UrgentConfirmViewController.logger.error(
                    "fetch sms setting failed",
                    error: error
                )
            })
            .disposed(by: disposeBag)

        // track
        UrgentTracker.trackImDingConfirmView(chat: chat, message: message)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let height = self.collectionHeader.headerHeight
        self.collectionHeader.frame = CGRect(
            x: 0,
            y: -height,
            width: self.view.bounds.width,
            height: height)
    }

    func reloadData() {
        self.collectionView.reloadData()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (_) in
            let height = self.collectionHeader.headerHeight
            self.collectionHeader.frame = CGRect(
                x: 0,
                y: -height,
                width: size.width,
                height: height)
        }, completion: nil)
    }

    fileprivate func defaultSupportedUrgentMessageViews(rustService: RustService) {
        urgentMessageViewsOfSupportUrgent.append(UrgentConfirmTextMessageView(userResolver: userResolver, rustService: rustService))
        urgentMessageViewsOfSupportUrgent.append(UrgentConfirmPostMessageView(userResolver: userResolver))
        urgentMessageViewsOfSupportUrgent.append(UrgentConfirmImageMessageView())
        urgentMessageViewsOfSupportUrgent.append(UrgentConfirmAudioMessageView())
        urgentMessageViewsOfSupportUrgent.append(UrgentConfirmCardMessageView())
        urgentMessageViewsOfSupportUrgent.append(UrgentConfirmMediaMessageView())
        urgentMessageViewsOfSupportUrgent.append(UrgentConfirmLocationMessageView())
        urgentMessageViewsOfSupportUrgent.append(UrgentConfirmMergeForwardMessageView())
        urgentMessageViewsOfSupportUrgent.append(UrgentConfirmStickerMessageView())
        urgentMessageViewsOfSupportUrgent.append(UrgentConfirmShareUserCardMessageView())
        urgentMessageViewsOfSupportUrgent.append(UrgentConfirmFileMessageView())
        urgentMessageViewsOfSupportUrgent.append(UrgentConfirmFolderMessageView())
        urgentMessageViewsOfSupportUrgent.append(UrgentConfirmVideoChatMessageView())
        urgentMessageViewsOfSupportUrgent.append(UrgentConfirmHongbaoMessageView())
        urgentMessageViewsOfSupportUrgent.append(UrgentConfirmCommercializedHongbaoMessageView())
        urgentMessageViewsOfSupportUrgent.append(UrgentConfirmShareCalendarEventMessageView())
        urgentMessageViewsOfSupportUrgent.append(UrgentConfirmTodoMessageView())
    }

    fileprivate func fetchSupportUrgentMessageView(supportType: Message.TypeEnum) -> UrgentConfirmMessageViewProtocol {
        for supportedUrgent in urgentMessageViewsOfSupportUrgent where supportType == supportedUrgent.type {
            return supportedUrgent
        }

        return UrgentConfirmMessageViewEmpty()
    }

    @objc
    fileprivate func didTapSure() {
        switch mode {
        case .single(let chatters):
            var result: [UrgentResult] = []
            if let chatters = supportChatterSectionModel?.chatters {
                result.append((urgentType, chatters))
            }
            if !self.unSupportChatterSectionModels.isEmpty {
                result.append((.app, self.unSupportChatterSectionModels.flatMap({ $0.chatters })))
            }
            self.sendSelected?(.selectSomeChatter(urgentResults: result), !shouldSendReceipt)
        case .group(_, let disableList, let additionalList):
            if isSuperChat {
                Self.logger.info("sendSelected selectAllChatter, disableListCount = \(disableList.count), additionalListCount = \(additionalList)")
                self.sendSelected?(.selectAllChatter(disableList: disableList, additionalList: additionalList), !shouldSendReceipt)
            } else {
                Self.logger.info("sendSelected selectUnreadChatter, disableListCount = \(disableList.count), additionalListCount = \(additionalList)")
                self.sendSelected?(.selectUnreadChatter(disableList: disableList, additionalList: additionalList), !shouldSendReceipt)
            }
        }

        // track
        UrgentTracker.trackImDingConfirmClick(click: "send",
                                              target: "im_chat_main_view",
                                              chat: chat,
                                              message: message)
    }

    fileprivate func updateCollectionHeader() {
        let headerHeight = self.collectionHeader.headerHeight
        self.collectionHeader.frame = CGRect(
            x: 0,
            y: -headerHeight,
            width: self.view.frame.width,
            height: headerHeight)
        collectionView.contentInset = UIEdgeInsets(top: headerHeight, left: 0, bottom: 60, right: 0)
        collectionView.contentOffset = CGPoint(x: 0, y: -headerHeight)
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard section < allSectionModels.count else { return CGSize(width: 0, height: 0) }
        var model = allSectionModels[section]
        return CGSize(width: self.view.frame.width, height: model.suggestHeight)
    }

    // MARK: - UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return allSectionModels.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard section < allSectionModels.count else { return 0 }
        return allSectionModels[section].chatters.count + (allSectionModels[section].hasOther ? 1 : 0)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellIndentifier: String
        let row = indexPath.row
        guard indexPath.section < allSectionModels.count else {
            Self.logger.info("indexPath.section: \(indexPath.section) out of index: \(allSectionModels.count)")
            return UICollectionViewCell()
        }
        let sectionModel = allSectionModels[indexPath.section]
        // 额外处理...等x人的cell
        if let otherCount = sectionModel.otherCount, indexPath.row == sectionModel.chatters.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ShowMoreCollectionViewCell.self), for: indexPath)
            if let collectionCell = cell as? ShowMoreCollectionViewCell {
                collectionCell.setContent(count: "+\(otherCount)", description: BundleI18n.LarkUrgent.Lark_Buzz_ConfirmationTotalBuzzed(sectionModel.allCount))
                return collectionCell
            } else {
                return cell
            }
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: AvatarWithBottomNameCollectionViewCell.self), for: indexPath)
            guard indexPath.row < sectionModel.chatters.count else {
                Self.logger.info("indexPath.row: \(indexPath.row) out of index: \(sectionModel.chatters.count)")
                return cell
            }
            let chatter = sectionModel.chatters[indexPath.row]
            if let collectionCell = cell as? AvatarWithBottomNameCollectionViewCell {
                let displayName: String
                switch scene {
                case .groupChat:
                    displayName = chatter.displayName(chatId: self.channelId, chatType: .group, scene: .urgentConfirm)
                default:
                    displayName = chatter.displayName(chatId: self.channelId, chatType: nil, scene: .urgentConfirm)
                }
                collectionCell.setContent(chatter.avatarKey, entityId: chatter.id, userName: displayName)
                return collectionCell
            }
            return cell
        }
        return UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let hearderIndentifier = String(describing: UrgentChatterCollectionHeader.self)
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: hearderIndentifier, for: indexPath)
        if let header = header as? UrgentChatterCollectionHeader {
            guard indexPath.section < allSectionModels.count else { return header }
            let model = allSectionModels[indexPath.section]
            header.setContent(text: model.title, alertText: model.description, isShowTopLine: model.isShowTopLine)
        }
        return header
    }
}
