//
//  LableFeedCell.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/20.
//

import Foundation
import UIKit
import LarkSwipeCellKit
import RxSwift
import LarkTag
import SnapKit
import LarkBizAvatar
import LarkZoomable
import LarkSceneManager
import ByteWebImage
import RustPB
import LarkModel
import LarkBadge
import LarkMessengerInterface
import LarkOpenFeed
import UniverseDesignDialog
import EENavigator
import LarkUIKit
import LarkNavigator
import LarkFeatureGating
import UniverseDesignColor
import LarkContainer
import LarkSDKInterface
import UniverseDesignToast
import UniverseDesignIcon
import LarkFeedBase

final class LableFeedCell: SwipeTableViewCell {

    static let identifier: String = "LableFeedCell"
    static let downsampleSize = CGSize(width: 32, height: 32)
    static let downsampleSizeForAtAvatar = CGSize(width: 22, height: 22)
    var viewModel: LabelFeedViewModel?
    var isSelectedState: Bool = false
    let highlightColor = UIColor.ud.fillHover
    let nameLabel = UILabel()
    let atAvatarView = BizAvatar()
    let avatarView = LarkMedalAvatar()
    let atAvatarWrapper = UIView()
    let badgeView = BadgeView(with: .label(.number(0)))
    private lazy var tagStackView = TagWrapperView()
    // markIcon
    public lazy var markIcon: UIImageView = {
        // 标记的小红旗
        let image = UDIcon.getIconByKey(.flagFilled, iconColor: UIColor.ud.colorfulRed)
        return UIImageView(image: image)
    }()

    private let disposeBag = DisposeBag()
    var selectedColor = UDMessageColorTheme.imFeedFeedFillActive

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
        layout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.setBackViewColor(backgroundColor(highlighted))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.setBackViewColor(backgroundColor(selected))
    }

    func setupView() {
        selectionStyle = .none
        let bgColor = UIColor.ud.bgBody
        self.backgroundColor = .clear
        self.swipeView.backgroundColor = .clear
        setupBackgroundViews(highlightOn: true)
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.font = Self.Cons.nameFont
        avatarView.contentMode = .scaleAspectFit
        atAvatarWrapper.isHidden = true
        badgeView.isHidden = true
        badgeView.setMaxNumber(to: 999)
    }

    func layout() {
        swipeView.addSubview(avatarView)
        swipeView.addSubview(nameLabel)
        swipeView.addSubview(tagStackView)
        swipeView.addSubview(markIcon)
        swipeView.addSubview(atAvatarWrapper)
        atAvatarWrapper.addSubview(atAvatarView)
        swipeView.addSubview(badgeView)

        avatarView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
            make.leading.equalToSuperview().offset(36)
        }

        badgeView.setContentCompressionResistancePriority(.required, for: .horizontal)
        badgeView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
        }

        atAvatarWrapper.snp.makeConstraints { make in
            make.size.equalTo(Self.downsampleSizeForAtAvatar)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(badgeView.snp.leading).offset(-8)
        }

        atAvatarWrapper.setContentCompressionResistancePriority(.required, for: .horizontal)
        atAvatarView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(2)
            make.bottom.trailing.equalToSuperview().offset(-2)
        }

        markIcon.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(FeedCardFlagComponentCons.flagSize)
            make.trailing.equalTo(atAvatarWrapper.snp.leading).offset(-8)
        }

        tagStackView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.height.equalTo(16)
            make.trailing.lessThanOrEqualTo(markIcon.snp.leading).offset(-8)
        }

        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(tagStackView.snp.leading).offset(-4)
        }
    }

    func set(viewModel: LabelFeedViewModel, isSelected: Bool) {
        self.viewModel = viewModel
        self.isSelectedState = isSelected
        configAvatar(viewModel)
        nameLabel.font = UIFont.ud.title4

        let tagVM = viewModel.feedViewModel.componentVMMap[.tag] as? FeedCardTagVM
        let tagBuilder = tagVM?.tagBuilder
        if let tagBuilder = tagBuilder {
            let tagDatas = tagBuilder.getSupportTags()
            tagStackView.setElements(tagDatas.map({ $0 }))
            tagStackView.isHidden = tagBuilder.isDisplayedEmpty()
        } else {
            tagStackView.setElements([])
            tagStackView.isHidden = true
        }

        if let titleVM = viewModel.feedViewModel.componentVMMap[.title] as? FeedCardTitleVM {
            self.nameLabel.text = titleVM.title
        } else {
            self.nameLabel.text = ""
        }
        if let badgeInfo = viewModel.badgeInfo {
            badgeView.isHidden = false
            badgeView.type = badgeInfo.type
            badgeView.style = badgeInfo.style
            badgeView.snp.updateConstraints { make in
                make.trailing.equalToSuperview().offset(-16)
            }
        } else {
            badgeView.isHidden = true
            badgeView.snp.updateConstraints { make in
                make.trailing.equalToSuperview()
            }
        }
        let isHiddenMarkIcon = !viewModel.feedPreview.basicMeta.isFlaged
        self.markIcon.isHidden = isHiddenMarkIcon
    }

    func configAvatar(_ labelFeed: LabelFeedViewModel) {
        let feed = labelFeed.feedPreview
        let entityId = labelFeed.avatarId
        let avatarKey = feed.uiMeta.avatarKey
        if (!entityId.isEmpty) && (!labelFeed.avatarId.isEmpty) {
            avatarView.setAvatarByIdentifier(
                entityId,
                avatarKey: avatarKey,
                medalKey: feed.preview.chatData.avatarMedal.key,
                medalFsUnit: feed.preview.chatData.avatarMedal.name,
                scene: .Feed,
                options: [.downsampleSize(Self.downsampleSize)],
                avatarViewParams: .init(sizeType: .size(Self.downsampleSize.width)))
        } else {
            avatarView.image = nil
        }
        avatarView.updateBorderSize(CGSize(width: LableFeedCell.downsampleSize.width + 4, height: LableFeedCell.downsampleSize.height + 4))

        if let avatarVM = labelFeed.feedViewModel.componentVMMap[.avatar] as? FeedCardAvatarVM {
            FeedCardAvatarUtil.setBorderImage(
                avatarView: avatarView,
                isBorderVisible: avatarVM.avatarViewModel.isBorderVisible)
        } else {
            avatarView.updateBorderImage(nil)
        }

        avatarView.updateBadge(labelFeed.avatarBadgeInfo.type, style: labelFeed.avatarBadgeInfo.style)
        if feed.uiMeta.mention.hasAtInfo {
            atAvatarWrapper.isHidden = false
            atAvatarView.updateBorderSize(Self.downsampleSizeForAtAvatar)
            let entityId = feed.uiMeta.mention.atInfo.userID
            let avatarKey = feed.uiMeta.mention.atInfo.avatarKey
            if (!entityId.isEmpty) && (!avatarKey.isEmpty) {
                atAvatarView.setAvatarByIdentifier(
                    entityId,
                    avatarKey: avatarKey,
                    scene: .Feed,
                    avatarViewParams: .init(sizeType: .size(Self.downsampleSizeForAtAvatar.width)))
            } else {
                atAvatarView.image = nil
            }
            atAvatarView.updateBorderImage(labelFeed.atBorderImage)
            atAvatarWrapper.snp.updateConstraints { make in
                make.size.equalTo(Self.downsampleSizeForAtAvatar)
                make.trailing.equalTo(badgeView.snp.leading).offset(-8)
            }
        } else {
            atAvatarWrapper.isHidden = true
            atAvatarWrapper.snp.updateConstraints { make in
                make.size.equalTo(CGSize.zero)
                make.trailing.equalTo(badgeView.snp.leading)
            }
        }
    }
}

// 跳转逻辑
extension LableFeedCell {
    func didSelectCell(feed: LabelFeedViewModel,
                       label: LabelViewModel,
                       from: UIViewController,
                       dependency: LabelDependency) {
        FeedContext.log.info("feedlog/label/didSelectCell: labelId: \(label.item.id), \(feed.feedPreview.description)")
        let isChatMember = feed.feedPreview.preview.chatData.chatRole == .member
        if isChatMember {
            //如果是群成员
            pushChatController(chat: feed.feedPreview, label: label, from: from, navigator: dependency.navigator)
        } else {
            // 需弹框拦截，同时移除该 Feed
            removeFeedCard(chatId: feed.feedPreview.id, dependency: dependency, from: from)
        }
    }

    func pushChatController(chat: FeedPreview,
                            label: LabelViewModel,
                            from: UIViewController,
                            navigator: Navigatable
    ) {
        let body = ChatControllerByBasicInfoBody(chatId: chat.id,
                                                 fromWhere: .feed,
                                                 isCrypto: chat.preview.chatData.isCrypto,
                                                 isMyAI: chat.preview.chatData.isP2PAi,
                                                 chatMode: chat.preview.chatData.chatMode,
                                                 extraInfo: ["feedId": chat.id]
        )
        var selectedInfo = FeedSelection(feedId: chat.id)
        selectedInfo.parendId = String(label.item.id)
        selectedInfo.filterTabType = .tag
        let context: [String: Any] = [FeedSelection.contextKey: selectedInfo]
        navigator.showDetailOrPush(body: body,
                                          context: context,
                                          wrap: LkNavigationController.self,
                                          from: from)
    }
}

// 移除群聊 逻辑
extension LableFeedCell {
    // 如果被踢出群聊，需弹框拦截，同时移除该 Feed
    func removeFeedCard(chatId: String, dependency: LabelDependency, from: UIViewController) {
        dependency.getKickInfo(chatId: chatId)
            .timeout(.milliseconds(500), scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak from] (content) in
                guard let from = from else { return }
                let dialog = UDDialog()
                dialog.setContent(text: content)
                dialog.addPrimaryButton(text: BundleI18n.LarkFeed.Lark_Legacy_IKnow,
                                        dismissCompletion: {
                                     var channel = Basic_V1_Channel()
                                     channel.type = .chat
                                     channel.id = chatId
                    dependency.removeFeedCard(channel: channel, feedPreviewPBType: .chat)
                                 })
                dependency.navigator.present(dialog, from: from)
            }).disposed(by: self.disposeBag)
    }
}

// 选中逻辑
extension LableFeedCell {
    func backgroundColor(_ highlighted: Bool) -> UIColor {
        var backgroundColor = UIColor.ud.fillHover
        let needShowSelected = isSelectedState && self.horizontalSizeClass == .regular
        if FeedSelectionEnable && needShowSelected {
            backgroundColor = self.selectedColor
        } else {
            backgroundColor = highlighted ? self.highlightColor : UIColor.ud.bgBody
        }
        return backgroundColor
    }
}

extension LableFeedCell: FeedCardCellWithPreview {
    var feedPreview: FeedPreview? {
        return viewModel?.feedPreview
    }
}

extension LableFeedCell: FeedSwipingCellInterface {}

extension LableFeedCell {
    /// 布局配置
    enum Cons {
        static var vMargin: CGFloat { 12 }
        static var nameFont: UIFont { UIFont.ud.title4 }

        // contentHeight 属性会在列表滑动时多次获取，若为计算变量，会生成大量 UIFont 实例，
        // 这里改用使用静态存储变量提升性能
        private static var _zoom: Zoom?
        private static var _contentHeight: CGFloat = getContentHeight()
        private static func getContentHeight() -> CGFloat {
            _zoom = Zoom.currentZoom
            return nameFont.figmaHeight
        }
        // Zoom 级别变化时，对静态存储变量重新赋值
        static var contentHeight: CGFloat {
            if Zoom.currentZoom != _zoom {
                _zoom = Zoom.currentZoom
                _contentHeight = getContentHeight()
            }
            return _contentHeight
        }
        static var cellHeight: CGFloat {
            contentHeight + vMargin * 2
        }
    }
}
