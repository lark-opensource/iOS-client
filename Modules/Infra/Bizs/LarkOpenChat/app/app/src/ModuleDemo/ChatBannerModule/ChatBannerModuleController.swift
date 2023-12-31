//
//  ChatBannerModuleController.swift
//  LarkOpenChatDev
//
//  Created by 李勇 on 2020/12/9.
//

import Foundation
import UIKit
import LarkOpenChat
import LarkModel
import Swinject
import RxCocoa

class ChatBannerModuleController: UIViewController, ChatOpenService {
    lazy var chat: BehaviorRelay<Chat> = .init(value: self.getPlaceholderChat())

    private let context: ChatModuleContext
    /// ChatBannerModule-2：ChatBannerModule init
    private lazy var bannerModule = ChatBannerModule(context: self.context.bannerContext)
    private let bannerStackView = UIStackView()

    init(context: ChatModuleContext) {
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.title = "ChatBannerModule"

        self.bannerStackView.axis = .vertical
        self.bannerStackView.alignment = .fill
        self.bannerStackView.distribution = .fill
        self.bannerStackView.spacing = 0.0
        self.view.addSubview(self.bannerStackView)
        self.bannerStackView.snp.makeConstraints { (make) in
            let navigationBarHeight = self.navigationController?.navigationBar.frame.size.height ?? 0
            make.top.equalTo(navigationBarHeight + UIApplication.shared.statusBarFrame.size.height)
            make.left.right.equalToSuperview()
        }

        self.reloadBanner()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    func chatVC() -> UIViewController {
        return self
    }

    func reloadBanner() {
        // ChatBannerModule-3：ChatBannerModule handle
        // 调用一次BannerSubModule的canHandle-handler
        let model = ChatBannerMetaModel(chat: self.getPlaceholderChat())
        self.bannerModule.handler(model: model)
        // 创建Banner视图
        self.bannerModule.createViews(model: model)
        self.refreshBanner()
    }

    func refreshBanner() {
        self.bannerModule.onRefresh()
        self.bannerStackView.subviews.forEach { (view) in
            view.removeFromSuperview()
            self.bannerStackView.removeArrangedSubview(view)
        }
        self.bannerModule.contentViews().forEach { (view) in
            self.bannerStackView.addArrangedSubview(view)
        }
    }

    func chatPage() -> UIViewController {
        return self
    }

    /// Mock Chat Model
    private func getPlaceholderChat() -> Chat {
        return Chat(id: "", type: .group, name: "", namePinyin: "", lastMessageId: "", lastMessagePosition: 0,
                    updateTime: 0, createTime: 0, chatterId: "", description: "", avatar: Image(), avatarKey: "",
                    miniAvatarKey: "", ownerId: "", chatterCount: 0, userCount: 0, isDepartment: false, isPublic: false,
                    isArchived: false, isDeleted: false, isRemind: false, role: .member, isCustomerService: false,
                    isCustomIcon: false, textDraftId: "", postDraftId: "", isShortCut: false,
                    announcement: Chat.Announcement(), offEditGroupChatInfo: false, tenantId: "", isDissolved: false,
                    messagePosition: .recentLeft, addMemberPermission: .allMembers, anonymousSetting: .allowed,
                    atAllPermission: .allMembers, joinMessageVisible: .allMembers, quitMessageVisible: .allMembers,
                    shareCardPermission: .allowed, addMemberApply: .needApply, putChatterApplyCount: 0,
                    anonymousTotalQuota: 0, showBanner: false, lastVisibleMessageId: "", burnLife: 0, isCrypto: false,
                    isMeeting: false, chatable: false, muteable: false, isTenant: false, isCrossTenant: false,
                    isInBox: false, firstMessagePostion: 0, isOfficialOncall: false, isOfflineOncall: false,
                    oncallId: "", lastVisibleMessagePosition: 0, readPosition: 0, readPositionBadgeCount: 0,
                    lastMessagePositionBadgeCount: 0, isAutoTranslate: false, chatMode: .threadV2,
                    lastThreadPositionBadgeCount: 0, readThreadPosition: 0, readThreadPositionBadgeCount: 0,
                    lastVisibleThreadPosition: 0, lastVisibleThreadId: "", lastThreadId: "", lastThreadPosition: 0,
                    myThreadsReadTimestamp: 0, myThreadsLastTimestamp: 0, myThreadsUnreadCount: 0, sidebarButtons: [],
                    isAllowPost: false, postType: .anyone, hasWaterMark: false, lastDraftId: "", lastReadPosition: 0,
                    lastReadOffset: 0)
    }
}
