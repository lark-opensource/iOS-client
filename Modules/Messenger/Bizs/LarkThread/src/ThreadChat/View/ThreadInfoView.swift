//
//  ThreadInfoView.swift
//  LarkThread
//
//  Created by lizhiqiang on 2019/7/23.
//

import Foundation
import RxCocoa
import RxSwift
import LarkTag
import LarkBizTag
import LarkCore
import LarkModel
import LarkUIKit
import RichLabel
import EENavigator
import UniverseDesignToast
import LarkMessengerInterface
import LarkAccountInterface
import LarkSDKInterface
import LKCommonsLogging
import LarkBizAvatar
import LarkFeatureGating
import UniverseDesignColor
import UIKit
import LarkContainer

final class ThreadChatHeaderViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    @ScopedProvider var passportUser: PassportUserService?

    // MARK: fileprivate and internal
    static fileprivate let logger = Logger.log(ThreadChatHeaderViewModel.self, category: "ThreadInfoView")
    fileprivate let chatPushWrapper: ChatPushWrapper
    fileprivate var unReadAnnounce: Bool = false
    fileprivate let isDefaultTopicGroup: Bool
    fileprivate var chat: Chat {
        return self.chatPushWrapper.chat.value
    }

    var enabled: Bool {
        return !chat.isTeamVisitorMode
    }

    init(
        userResolver: UserResolver,
        chatPushWrapper: ChatPushWrapper,
        chatAPI: ChatAPI,
        isDefaultTopicGroup: Bool
    ) {
        self.userResolver = userResolver
        self.isDefaultTopicGroup = isDefaultTopicGroup
        self.chatPushWrapper = chatPushWrapper
        self.chatAPI = chatAPI

        let chat = chatPushWrapper.chat.value
        ThreadChatHeaderViewModel.logger.info(
            """
            ThreadInfoView init chatID: \(chat.id),
            announcement: \(chat.announcement.content.count)
            """
        )

        unReadAnnounce = chat.chatOptionInfo?.announce ?? false
        // 如果未读 && 群公告内容是空时，主动发起一次已读请求。
        if unReadAnnounce, chat.announcement.content.isEmpty {
            chatAPI.readChatAnnouncement(
                by: chat.id,
                updateTime: chat.announcement.updateTime
            ).subscribe().dispose()
        }
    }

    // 群头像编辑
    fileprivate func previewAvatar(from view: UIView) {
        guard let window = view.window else {
            assertionFailure("缺少路由跳转的Window")
            return
        }
        let asset = LKDisplayAsset.createAsset(avatarKey: chat.avatarKey, chatID: self.chat.id).transform()
        if hasAccess {
            let body = SettingSingeImageBody(asset: asset,
                                             modifyAvatarString: BundleI18n.LarkThread.Lark_Groups_EditChannelPhoto) { [weak self] (info) -> Observable<[String]> in
                guard let `self` = self, let data = info.0 else { return .just([]) }
                guard self.hasAccess else {
                    let text = BundleI18n.LarkThread.Lark_Legacy_OnlyGOGAEditGroupInfo
                    UDToast.showFailure(with: text, on: view)
                    return .just([])
                }

                return self.changeGroupAvatar(avatarData: data)
                    .do(onNext: { _ in })
                    .map { _ in [] }
            }
            navigator.present(body: body, from: window)
        } else {
            let body = PreviewImagesBody(assets: [asset],
                                         pageIndex: 0,
                                         scene: .normal(assetPositionMap: [:], chatId: chat.id),
                                         shouldDetectFile: chat.shouldDetectFile,
                                         canShareImage: false,
                                         canEditImage: false,
                                         canTranslate: userResolver.fg.staticFeatureGatingValue(with: .init(key: .imageViewerInOtherScenesTranslateEnable)),
                                         translateEntityContext: (nil, .other))
            navigator.present(body: body, from: window)
        }
    }

    /// 获取ThreadChat对应[Tag]
    ///
    /// - Returns: [Tag]
    fileprivate func getTags(style: Style, tenantTagStyle: Style) -> [TagDataItem] {
        var tagDataItems: [TagDataItem] = []
        // 特化处理，如果是默认小组只显示一个全员标签。
        if isDefaultTopicGroup {
            tagDataItems.append(TagDataItem(tagType: .allStaff, frontColor: style.textColor, backColor: style.backColor))
            return tagDataItems
        }

        if chat.isCrossWithKa {
            UserStyle.on(.connectTag, userType: passportUser?.user.type ?? .undefined).apply(on: {
                tagDataItems.append(TagDataItem(tagType: .connect, frontColor: style.textColor, backColor: style.backColor))
            }, off: {})
        }
        chat.tagData?.tagDataItems.forEach { item in
            let isExternal = item.respTagType == .relationTagExternal
            if isExternal, !chat.isCrossWithKa {
                tagDataItems.append(TagDataItem(tagType: .external, frontColor: style.textColor, backColor: style.backColor))
            } else {
                // 产品要求租户标签特化
                let tagStyle = (item.respTagType == .tenantEntityTag ? tenantTagStyle : style)
                let tagDataItem = LarkBizTag.TagDataItem(text: item.textVal,
                                                         tagType: item.respTagType.transform(),
                                                         frontColor: tagStyle.textColor,
                                                         backColor: tagStyle.backColor,
                                                         priority: Int(item.priority))
                tagDataItems.append(tagDataItem)
            }
        }

        if chat.isPublic {
            tagDataItems.append(TagDataItem(tagType: .public, frontColor: style.textColor, backColor: style.backColor))
        }
        if chat.isDepartment {
            tagDataItems.append(TagDataItem(tagType: .team, frontColor: style.textColor, backColor: style.backColor))
        }
        if chat.isTenant {
            tagDataItems.append(TagDataItem(tagType: .allStaff, frontColor: style.textColor, backColor: style.backColor))
        }
        if chat.chatter?.type == .bot, !(chat.chatter?.withBotTag.isEmpty ?? true) {
            tagDataItems.append(TagDataItem(tagType: .robot, frontColor: style.textColor, backColor: style.backColor))
        }
        if chat.isSuper {
            tagDataItems.append(TagDataItem(tagType: .superChat, frontColor: style.textColor, backColor: style.backColor))
        }
        return tagDataItems
    }

    // MARK: private
    private let chatAPI: ChatAPI
    private var isOwner: Bool {
        return userResolver.userID == chat.ownerId
    }
    // 是否是群管理
    var isGroupAdmin: Bool {
        chat.isGroupAdmin
    }

    private var hasAccess: Bool {
        return chat.isAllowPost && (isOwner || isGroupAdmin || !chat.offEditGroupChatInfo)
    }

    /// 自己是不是c端用户
    private var selfIsCustomer: Bool {
        if let tenantID = passportUser?.user.tenant.tenantID {
            return LarkCore.isCustomer(tenantId: tenantID)
        }
        return false
    }

    private func changeGroupAvatar(avatarData: Data) -> Observable<String> {
        return self.chatAPI
            .updateChat(chatId: self.chat.id, iconData: avatarData, avatarMeta: nil)
            .observeOn(MainScheduler.instance)
            .map({ (chatModel) -> String in
                return chatModel.displayAvatar.firstUrl
            })
    }
}

extension ThreadChatHeader {
    struct HeaderStyle {
        let backgroundColor: UIColor

        let titleColor: UIColor
        let memberIconColor: UIColor
        let memberCountColor: UIColor
        let descriptionColor: UIColor
        let announcementColor: UIColor
        let sharedButtonColor: UIColor
        let sharedTextColor: UIColor
        let sharedIconColor: UIColor
        let tagTextColor: UIColor
        let tagBackColor: UIColor
        let tenantTagBackColor: UIColor

        // 是否支持使用头像作为背景
        let supportBackgroundImage: Bool

        static var `default`: HeaderStyle {
            return Display.pad ? HeaderStyle.iPad : HeaderStyle.iPhone
        }

        static var iPad: HeaderStyle {
            return HeaderStyle(
                backgroundColor: UIColor.ud.N200,
                titleColor: UIColor.ud.N900,
                memberIconColor: UIColor.ud.N500,
                memberCountColor: UIColor.ud.N500,
                descriptionColor: UIColor.ud.N800,
                announcementColor: UIColor.ud.N800,
                sharedButtonColor: UIColor.ud.N900,
                sharedTextColor: UIColor.ud.N900,
                sharedIconColor: UIColor.ud.N900,
                tagTextColor: UIColor.ud.colorfulBlue,
                tagBackColor: UIColor.ud.colorfulBlue.nonDynamic.withAlphaComponent(0.12),
                tenantTagBackColor: UIColor.ud.udtokenTagBgIndigo,
                supportBackgroundImage: false
            )
        }

        static var iPhone: HeaderStyle {
            return HeaderStyle(
                backgroundColor: UIColor.ud.N300,
                titleColor: UIColor.ud.primaryOnPrimaryFill,
                memberIconColor: UIColor.ud.primaryOnPrimaryFill,
                memberCountColor: UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8),
                descriptionColor: UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8),
                announcementColor: UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8),
                sharedButtonColor: UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.6),
                sharedTextColor: UIColor.ud.primaryOnPrimaryFill,
                sharedIconColor: UIColor.ud.primaryOnPrimaryFill,
                tagTextColor: UIColor.ud.N900.nonDynamic,
                tagBackColor: UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8),
                tenantTagBackColor: UIColor.ud.udtokenTagBgIndigoSolid,
                supportBackgroundImage: true
            )
        }
    }
}

final class ThreadChatHeader: UIView {
    var clickedAnnounceLabel: (() -> Void)?
    var clickedShareButton: (() -> Void)?
    private(set) var heightOfContentView: CGFloat = 0
    private let heightOfNavigationBar: CGFloat
    // navigationBar + filterBar
    private lazy var miniHeight: CGFloat = {
        return heightOfNavigationBar + SegmentLayout.tabsHeight
    }()

    // header
    let headerStyle: HeaderStyle = HeaderStyle.default
    /// 创建ThreadChatHeader
    ///
    /// - Parameters:
    ///   - viewModel: ThreadChatHeaderViewModel
    ///   - tabsView: 过滤菜单
    ///   - relateAnimtaionViews: 关联需要做动画的Views，对其隐藏/显示。
    init(viewModel: ThreadChatHeaderViewModel,
         tabsView: UIView,
         relateAnimtaionViews: [UIView],
         navBarHeight: CGFloat
    ) {
        self.releateAnimationViews = relateAnimtaionViews
        self.viewModel = viewModel
        self.tabsView = tabsView
        self.heightOfNavigationBar = navBarHeight
        super.init(frame: .zero)
        self.setupUI()
        // 如果群公告未读: -> UI展示群公告
        self.update(with: viewModel.chat, updateAnnouncement: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addToView(_ view: UIView) {
        view.addSubview(self)
        newAnnouncementTrack()
        // for systemLayoutSizeFitting
        self.topicInfoView.layoutIfNeeded()
        heightOfContentView = self.topicInfoView.systemLayoutSizeFitting(view.frame.size).height.rounded(.up)

        ThreadChatHeaderViewModel.logger.info(
            """
            ThreadInfoView addToView
            chatID: \(viewModel.chat.id),
            heightOfContentView:\(heightOfContentView),
            contentLabel: \(contentLabel.attributedText?.string.count ?? 0),
            announcement: \(viewModel.chat.announcement.content.count)
            """
        )
        // 有未读群公告 || 倒序，则头部默认展开
        if self.viewModel.unReadAnnounce {
            self.snp.makeConstraints { (make) in
                make.left.top.right.equalToSuperview()
                make.height.equalTo(heightOfContentView + miniHeight)
            }
            self.releateAnimationViews.forEach({ (view) in
                view.alpha = 0
            })
            self.isShow = true
        } else {
            self.snp.makeConstraints { (make) in
               make.left.top.right.equalToSuperview()
               make.height.equalTo(miniHeight)
            }
            self.releateAnimationViews.forEach({ (view) in
               view.alpha = 1
            })
            self.isShow = false
        }
        self.addObservers()
    }

    public func closeThreadChatHeader() {
        self.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(0)
            make.height.equalTo(heightOfNavigationBar)
        }
        self.releateAnimationViews.forEach({ (view) in
           view.alpha = 1
        })
        self.isShow = false
    }

    private func newAnnouncementTrack() {
        if viewModel.unReadAnnounce {
            ThreadTracker.trackTopicNewAnnouncementRemind(chatID: viewModel.chat.id, uid: viewModel.userResolver.userID)
        }
    }

    /// 更新监听的tableView
    ///
    /// - Parameter tableView: UITableView
    func updateTableViewObservers(tableView: UITableView) {
        guard currentTableView != tableView else {
            return
        }
        // 更新
        tableViewDisposeBag = DisposeBag()
        currentTableView = tableView
        updateHeaderViewForAutoHideView(tableView: tableView)
    }

    // MARK: private
    private let leading: CGFloat = 16
    private let heightOfIcon: CGFloat = 12
    private let heightOfAvatar: CGFloat = 50

    private let tabsView: UIView
    private let releateAnimationViews: [UIView]
    private let viewModel: ThreadChatHeaderViewModel
    private let disposeBag = DisposeBag()
    private var tableViewDisposeBag = DisposeBag()

    private var currentTableView: UITableView?
    private var relatedTableViews = [UITableView]()
    private var lastContentOffsetY: CGFloat = 0
    /// 记录上次向上推动时的ContentOffsetY位置。
    private var startPullTopContentOffsetY: CGFloat?
    private var startHeaderHeight: CGFloat = 0

    // supprot reverse FG
    private var isShow: Bool = false
    private var isAnimating: Bool = false
    private var isUserDragging: Bool = false
    private var lastContentOffsetYForAutoHideView: CGFloat?
    // 记录avatarKey
    private var avatarKey = ""

    private lazy var topicInfoView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.backgroundColor = UIColor.clear
        return view
    }()

    private lazy var topOfContentView: UIView = {
        let topView = UIView()
        return topView
    }()

    private lazy var downOfContentView: UIView = {
        let topView = UIView()
        return topView
    }()

    private lazy var avatarImageView: BizAvatar = {
        let view = BizAvatar()
        view.clipsToBounds = true
        view.avatar.layer.borderWidth = 2
        view.avatar.layer.borderColor = UIColor.ud.primaryOnPrimaryFill.cgColor
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        let tap = UITapGestureRecognizer(target: self, action: #selector(avatarTapped))
        view.addGestureRecognizer(tap)
        return view
    }()

    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.ud.N300
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    // 黑暗模式下，背景图片要有一层遮罩
    private lazy var backgroundMaskView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear & UIColor.ud.staticBlack.withAlphaComponent(0.12)
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 1
        view.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        view.textColor = UIColor.ud.primaryOnPrimaryFill
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }()

    private lazy var shareLabel: UILabel = UILabel()
    private lazy var shareIcon: UIImageView = UIImageView(image:
        Resources.thread_header_share.withRenderingMode(.alwaysTemplate)
    )

    private lazy var shareButton: UIButton = {
        let button = UIButton()
        button.rx.tap.asDriver().drive(onNext: { [weak self] (_) in
            self?.clickedShareButton?()
        })
        .disposed(by: disposeBag)
        button.layer.cornerRadius = 14
        button.layer.borderColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.6).cgColor
        button.layer.borderWidth = 1
        button.clipsToBounds = true

        let imageView = self.shareIcon
        imageView.tintColor = UIColor.ud.primaryOnPrimaryFill
        button.addSubview(imageView)
        imageView.snp.makeConstraints({ (make) in
            make.leading.equalToSuperview().offset(11)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 16, height: 16))
        })

        let label = self.shareLabel
        label.text = BundleI18n.LarkThread.Lark_Chat_TopicToolShare
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.addSubview(label)
        label.snp.makeConstraints({ (make) in
            make.leading.equalTo(imageView.snp.trailing).offset(2)
            make.trailing.equalToSuperview().offset(-11)
            make.centerY.equalToSuperview()
        })

        return button
    }()

    lazy var chatTagBuilder = ChatTagViewBuilder()
    lazy var tagView: TagWrapperView = {
        let tagView = chatTagBuilder.build()
        return tagView
    }()

    private lazy var desLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 1
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
        return view
    }()

    private lazy var iconImageView: UIImageView = {
        let view = UIImageView(image: Resources.thread_announcement_announcement_icon)
        return view
    }()

    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 2
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
        label.isUserInteractionEnabled = true
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        let tap = UITapGestureRecognizer(target: self, action: #selector(contentLabelTapped))
        label.addGestureRecognizer(tap)
        return label
    }()

    private lazy var memberCountIconImageView: UIImageView = {
        let view = UIImageView(image:
            Resources.thread_member_icon.withRenderingMode(.alwaysTemplate)
        )
        view.tintColor = UIColor.ud.primaryOnPrimaryFill
        return view
    }()

    private lazy var memberCountLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 1
        view.font = UIFont.systemFont(ofSize: 14)
        view.textColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        return view
    }()

    private lazy var speratorLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
        return view
    }()

    private func setupUI() {
        self.isUserInteractionEnabled = viewModel.enabled
        self.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.center.equalToSuperview()
        }
        addSubview(backgroundMaskView)
        backgroundMaskView.snp.makeConstraints { make in
            make.edges.equalTo(backgroundImageView)
        }

        configTopicInfoView()
        configFilterView()
        setupHeaderStyle()
    }

    private func setupHeaderStyle() {
        backgroundImageView.backgroundColor = headerStyle.backgroundColor
        titleLabel.textColor = headerStyle.titleColor
        memberCountIconImageView.tintColor = headerStyle.memberIconColor
        memberCountLabel.textColor = headerStyle.memberCountColor
        desLabel.textColor = headerStyle.descriptionColor
        shareIcon.tintColor = headerStyle.sharedIconColor
        shareLabel.textColor = headerStyle.sharedTextColor
        shareButton.layer.borderColor = headerStyle.sharedButtonColor.cgColor
    }

    private func configFilterView() {
        tabsView.layer.cornerRadius = 8
        tabsView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        tabsView.layer.masksToBounds = true
        addSubview(tabsView)
        tabsView.snp.makeConstraints { (make) in
            make.top.equalTo(self.topicInfoView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(SegmentLayout.tabsHeight)
        }
    }

    private func configTopOfContentView() {
        topOfContentView.addSubview(avatarImageView)
        topOfContentView.addSubview(titleLabel)
        topOfContentView.addSubview(shareButton)
        topOfContentView.addSubview(memberCountIconImageView)
        topOfContentView.addSubview(memberCountLabel)

        avatarImageView.snp.makeConstraints { (make) in
            make.top.bottom.leading.equalToSuperview()
            make.width.equalTo(heightOfAvatar)
            make.height.equalTo(heightOfAvatar)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(avatarImageView.snp.top).offset(2.5)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(9)
            make.trailing.equalTo(shareButton.snp.leading).offset(-6)
        }

        shareButton.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(titleLabel)
            make.height.equalTo(28)
        }

        memberCountIconImageView.snp.makeConstraints { (make) in
            make.leading.equalTo(titleLabel)
            make.bottom.equalTo(avatarImageView.snp.bottom).offset(-4)
            make.width.equalTo(14)
            make.height.equalTo(14)
        }

        memberCountLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(memberCountIconImageView.snp.trailing).offset(4)
            make.centerY.equalTo(memberCountIconImageView)
            make.trailing.lessThanOrEqualToSuperview()
        }
    }

    fileprivate func configDownOfContentView() {
        downOfContentView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }

        contentLabel.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(3)
            make.leading.equalToSuperview()
            make.size.equalTo(CGSize(width: heightOfIcon, height: heightOfIcon))
        }
    }

    private func configTopicInfoView() {
        self.addSubview(topicInfoView)
        topicInfoView.snp.makeConstraints { (make) in
            make.top.equalTo(heightOfNavigationBar)
            make.leading.trailing.equalToSuperview()
        }

        let contentStackView = UIStackView()
        contentStackView.axis = .vertical
        contentStackView.spacing = 16
        topicInfoView.addSubview(contentStackView)
        contentStackView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(6).priority(.low)
            make.leading.equalTo(leading)
            make.trailing.equalTo(-leading)
            make.bottom.equalTo(-16)
        }

        configTopOfContentView()
        contentStackView.addArrangedSubview(topOfContentView)

        configDownOfContentView()
        contentStackView.addArrangedSubview(downOfContentView)
    }

    private func update(with chat: Chat, updateAnnouncement: Bool) {
        updateAvatar(by: chat)
        updateMemberInfo(by: chat)
        updateChatName(by: chat)
        updateDescription(by: chat)

        // 不需要更新群公告
        if !updateAnnouncement {
            return
        }
        if self.viewModel.unReadAnnounce {
            self.updateAnnouncement(content: chat.announcement.content)
        } else {
            // 已读情况下 不展示群公告
            self.updateAnnouncement(content: "")
        }
    }

    private func updateChatName(by chat: Chat) {
        titleLabel.text = chat.displayName
        let hideShareButton = chat.isFrozen || chat.isCrossTenant || chat.shareCardPermission != .allowed || !viewModel.enabled

        let style = Style(
            textColor: self.headerStyle.tagTextColor,
            backColor: self.headerStyle.tagBackColor
        )

        let tenantTagStyle = Style(
            textColor: self.headerStyle.tagTextColor,
            backColor: self.headerStyle.tenantTagBackColor
        )

        let tags = viewModel.getTags(style: style, tenantTagStyle: tenantTagStyle)
        if tags.isEmpty {
            tagView.removeFromSuperview()
            titleLabel.snp.remakeConstraints { (make) in
                if viewModel.isDefaultTopicGroup {
                    make.centerY.equalTo(avatarImageView)
                } else {
                    make.top.equalTo(avatarImageView.snp.top).offset(2.5)
                }
                make.leading.equalTo(heightOfAvatar + 8)
                if hideShareButton {
                    make.trailing.equalToSuperview().offset(-8)
                } else {
                    make.trailing.lessThanOrEqualTo(shareButton.snp.leading).offset(-7)
                }
            }
        } else {
            topOfContentView.addSubview(tagView)
            chatTagBuilder.update(with: tags)
            titleLabel.snp.remakeConstraints { (make) in
                if viewModel.isDefaultTopicGroup {
                    make.centerY.equalTo(avatarImageView)
                } else {
                    make.top.equalTo(avatarImageView.snp.top).offset(2.5)
                }
                make.leading.equalTo(heightOfAvatar + 8)
            }

            tagView.snp.remakeConstraints { (make) in
                make.centerY.equalTo(titleLabel)
                make.leading.equalTo(titleLabel.snp.trailing).offset(7)
                if hideShareButton {
                    make.trailing.lessThanOrEqualToSuperview().offset(-8)
                } else {
                    make.trailing.lessThanOrEqualTo(shareButton.snp.leading).offset(-7)
                }
            }
        }

        // hide shareButton if chat is external or .notAllowed
        if hideShareButton {
            shareButton.isHidden = true
        }
    }

    private func updateDescription(by chat: Chat) {
        if chat.description.isEmpty {
            speratorLineView.removeFromSuperview()
            desLabel.removeFromSuperview()
            memberCountLabel.snp.remakeConstraints { (make) in
                make.leading.equalTo(memberCountIconImageView.snp.trailing).offset(4)
                make.centerY.equalTo(memberCountIconImageView)
                make.trailing.lessThanOrEqualToSuperview()
            }
        } else {
            downOfContentView.addSubview(speratorLineView)
            downOfContentView.addSubview(desLabel)
            speratorLineView.snp.remakeConstraints { (make) in
                make.width.equalTo(1)
                make.height.equalTo(10)
                make.leading.equalTo(memberCountLabel.snp.trailing).offset(4)
                make.centerY.equalTo(memberCountLabel)
            }

            desLabel.snp.remakeConstraints { (make) in
                make.leading.equalTo(speratorLineView.snp.trailing).offset(4)
                make.trailing.lessThanOrEqualToSuperview()
                make.centerY.equalTo(memberCountIconImageView)
            }

            desLabel.text = chat.description
        }
    }

    private func updateMemberInfo(by chat: Chat) {
        if viewModel.isDefaultTopicGroup || chat.isFrozen || !chat.isUserCountVisible {
            memberCountIconImageView.isHidden = true
            memberCountLabel.isHidden = true
        } else {
            memberCountLabel.text = String(chat.userCount)
            memberCountIconImageView.isHidden = false
            memberCountLabel.isHidden = false
        }
    }

    private func updateAvatar(by chat: Chat) {
        let avatarKey = chat.avatarKey
        self.avatarKey = avatarKey
        avatarImageView.setAvatarByIdentifier(chat.id,
                                              avatarKey: self.avatarKey,
                                              avatarViewParams: .init(sizeType: .size(heightOfAvatar)),
                                              completion: { [weak self] result in

            // determine avatarKey == self.avatarKey cell maybe targger reuse
            guard let `self` = self,
                avatarKey == self.avatarKey,
                let image = (try? result.get())?.image,
                self.headerStyle.supportBackgroundImage else {
                    return
            }

            // real size is not important. use estimate size. background imageView use scaleAspectFill
            let size = CGSize(width: 375, height: 184)
            ThreadPrimaryColorManager.getPrimaryColorImageBy(image: image, avatarKey: avatarKey, size: size) { (blendImage, _) in
                guard avatarKey == self.avatarKey, let blendImage = blendImage else {
                    return
                }
                self.backgroundImageView.image = blendImage
            }
        })
    }

    private func updateAnnouncement(content: String) {
        if content.isEmpty {
            downOfContentView.isHidden = true
        } else {
            downOfContentView.isHidden = false

            let contentStr: String
            if viewModel.unReadAnnounce {
                let promatStr = BundleI18n.LarkThread.Lark_Chat_TopicTitlebarNewAnnouncement + ": "
                contentStr = promatStr + content
            } else {
                contentStr = content
            }

            let style = NSMutableParagraphStyle()
            style.firstLineHeadIndent = 16
            style.minimumLineHeight = 17
            style.maximumLineHeight = 17
            style.lineBreakMode = .byTruncatingTail

            let contentAttributeStr = NSAttributedString(
                string: contentStr,
                attributes: [
                    .foregroundColor: self.headerStyle.announcementColor,
                    .font: contentLabel.font ?? UIFont.systemFont(ofSize: 12),
                    .paragraphStyle: style
                ]
            )
            contentLabel.attributedText = contentAttributeStr
        }
    }

    private func addObservers() {
        self.viewModel.chatPushWrapper.chat.distinctUntilChanged({ (chat1, chat2) -> Bool in
            return (chat1.avatarKey == chat2.avatarKey) &&
            (chat1.displayName == chat2.displayName) &&
            (chat1.description == chat2.description) &&
            (chat1.announcement.content == chat2.announcement.content) &&
            (chat1.isFrozen == chat2.isFrozen) &&
            (chat1.userCount == chat2.userCount) &&
            (chat1.isUserCountVisible == chat2.isUserCountVisible)
        })
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self](chat) in
            guard let self = self else { return }
            ThreadChatHeaderViewModel.logger.info(
                """
                ThreadInfoView push chatID: \(chat.id),
                announcement: \(chat.announcement.content.count)
                """
            )
            // update announcement content when init.
            // sometime first enter group chat.announcement is nil then SDK will push chat to update announcement.
            // but update announcement will let view height change.
            // 只在初始化数据时更新群公告内容，SDK push chat 时不更新.
            // 因为更新群公告内容会引起整个内容区域移动，体验差。
            self.update(with: chat, updateAnnouncement: false)
        })
        .disposed(by: disposeBag)

        // 兼容实现直接吐当前值，前面init处理了当前值，所以就不需要监听这个变化了
    }

    func showHeaderView(_ isShow: Bool) {
        if isShow {
            self.showHeaderView()
        } else {
            self.hideHeaderView()
        }
    }

    private func hideHeaderView() {
        // 正在动画 或者 已经隐藏 return
        if isAnimating || !isShow { return }

        isAnimating = true
        self.snp.remakeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(miniHeight)
        }
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 1,
            options: .curveEaseInOut,
            animations: {
                self.isAnimating = false
                self.isShow = false
                self.releateAnimationViews.forEach({ (view) in
                    view.alpha = 1
                })
                self.superview?.layoutIfNeeded()
            }
        )
    }

    private func showHeaderView() {
        // 正在动画 或者 已经显示 return
        if isAnimating || isShow { return }

        self.isAnimating = true
        self.snp.remakeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(heightOfContentView + miniHeight)
        }
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 1,
            options: .curveEaseInOut,
            animations: {
                self.isShow = true
                self.isAnimating = false
                self.releateAnimationViews.forEach({ (view) in
                    view.alpha = 0
                })
                self.superview?.layoutIfNeeded()
            }
        )
    }

    private func updateHeaderViewForAutoHideView(tableView: UITableView) {
        isUserDragging = false
        lastContentOffsetYForAutoHideView = nil

        tableView.rx.didScroll.asDriver().drive(onNext: { [weak self] () in
            guard let self = self else { return }
            // 用户手指再屏幕上 && 拖动返回操作正负50pt才会隐藏。
            if self.isUserDragging,
               let firstContentOffsetY = self.lastContentOffsetYForAutoHideView,
               abs(tableView.contentOffset.y - firstContentOffsetY) > 50 {
                self.hideHeaderView()
            }
        }).disposed(by: tableViewDisposeBag)

        tableView.rx.willBeginDragging.asDriver().drive(onNext: { [weak self] () in
            guard let self = `self` else { return }
            self.isUserDragging = true
            if self.lastContentOffsetYForAutoHideView == nil {
                self.lastContentOffsetYForAutoHideView = tableView.contentOffset.y
            }
        }).disposed(by: tableViewDisposeBag)

        tableView.rx.willEndDragging.asDriver().drive(onNext: { [weak self] _ in
            self?.isUserDragging = false
            self?.lastContentOffsetYForAutoHideView = nil
        }).disposed(by: tableViewDisposeBag)
    }

    @objc
    private func contentLabelTapped() {
        ThreadTracker.trackTopicNewAnnouncementRemindClick(chatID: viewModel.chat.id, uid: viewModel.userResolver.userID)
        clickedAnnounceLabel?()
    }

    @objc
    private func avatarTapped() {
        viewModel.previewAvatar(from: self)
    }
}
