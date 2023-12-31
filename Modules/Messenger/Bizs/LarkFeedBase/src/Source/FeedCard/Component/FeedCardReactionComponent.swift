//
//  FeedCardReactionComponent.swift
//  LarkFeedBase
//
//  Created by liuxianyu on 2023/5/10.
//

import ByteWebImage
import Foundation
import LarkOpenFeed
import LarkModel
import LarkEmotion
import LarkUIExtension
import LarkZoomable
import LarkContainer
import LKCommonsTracker
import RustPB
import RxSwift
import UniverseDesignColor

// MARK: - Factory
public class FeedCardReactionFactory: FeedCardBaseComponentFactory {
    public let context: FeedCardContext

    // 组件类别
    public var type: FeedCardComponentType {
        return .reaction
    }

    public init(context: FeedCardContext) {
        self.context = context
    }

    public func creatVM(feedPreview: FeedPreview) -> FeedCardBaseComponentVM {
        return FeedCardReactionComponentVM(feedPreview: feedPreview, context: context)
    }

    public func creatView() -> FeedCardBaseComponentView {
        return FeedCardReactionComponentView()
    }
}

// MARK: - ViewModel
final class FeedCardReactionComponentVM: FeedCardBaseComponentVM {
    // 组件类别
    var type: FeedCardComponentType {
        return .reaction
    }

    // VM 数据
    let reactions: [RustPB.Basic_V1_Message.Reaction]
    private(set) var isShowReaction: Bool
    let autoHandleMaxCount: Bool
    private let hasReaction: Bool
    let hasDraft: Bool
    let userResolver: UserResolver

    // 在子线程生成view data
    init(feedPreview: FeedPreview, context: FeedCardContext) {
        reactions = feedPreview.uiMeta.reactions.filter { reaction in
            let isDeleted = EmotionResouce.shared.isDeletedBy(key: reaction.type)
            return isDeleted == false
        }
        self.hasReaction = !reactions.isEmpty
        let canShowReaction = feedPreview.uiMeta.draft.content.isEmpty
        isShowReaction = hasReaction && canShowReaction
        autoHandleMaxCount = !(feedPreview.preview.chatData.chatType == .group)
        self.hasDraft = !feedPreview.uiMeta.draft.content.isEmpty
        self.userResolver = context.userResolver
    }

    func update(selectedStatus: Bool) {
        let canShowReaction = selectedStatus || (!selectedStatus && !hasDraft)
        self.isShowReaction = hasReaction && canShowReaction
    }
}

// MARK: - View
public class FeedCardReactionComponentView: FeedCardBaseComponentView {
    // 提供布局信息，比如：width、height、padding等（cell初始化进行布局时获取）
    public var layoutInfo: LarkOpenFeed.FeedCardComponentLayoutInfo? {
        return FeedCardComponentLayoutInfo(padding: nil, width: 0, height: 0)
    }
    private let font = FeedCardReactionComponentView.Cons.font

    // 组件类别
    public var type: FeedCardComponentType {
        return .reaction
    }

    public static let reactionHasMoreKey = "reactionHasMoreKey"

    public var eventContext: [String: Any]? {
        return [FeedCardReactionComponentView.reactionHasMoreKey: hasMore]
    }

    private var hasMore: Bool = false

    public func creatView() -> UIView {
        let reactionsGroupView = ReactionsGroupView(font: font)
        return reactionsGroupView
    }

    public func updateView(view: UIView, vm: FeedCardBaseComponentVM) {
        guard let view = view as? ReactionsGroupView,
              let vm = vm as? FeedCardReactionComponentVM else { return }
        guard vm.isShowReaction else {
            view.isHidden = true
            view.snp.updateConstraints { make in
                make.width.equalTo(0)
                make.height.equalTo(0)
            }
            self.hasMore = false
            return
        }

        view.isHidden = false
        let containerWidth: CGFloat
        // TODO: open feed 框架层需要输出给component max width
        if let layoutConfig = try? vm.userResolver.resolve(assert: FeedLayoutService.self) {
            containerWidth = Cons.reactionAvailableWidth(layoutConfig.containerSize.width)
        } else {
            containerWidth = view.superview?.bounds.width ?? 0
        }
        let groupMaxCount: Int = 3
        let maxCount = vm.autoHandleMaxCount ? getP2pMaxCount(reactions: vm.reactions, containerWidth: containerWidth, font: font) : groupMaxCount
        // TODO: open feed
        let (size, hasMore) = view.set(reactions: vm.reactions, tryAddMoreView: !vm.autoHandleMaxCount, maxCount: maxCount)
        if size.width != view.bounds.size.width
            || size.height != view.bounds.size.height {
            view.snp.updateConstraints { make in
                make.width.equalTo(size.width)
                make.height.equalTo(size.height)
            }
        }
        self.hasMore = hasMore
    }

    public func subscribedEventTypes() -> [FeedCardEventType] {
        return [.prepareForReuse]
    }

    public func postEvent(type: FeedCardEventType, value: FeedCardEventValue, object: Any) {
        if case .prepareForReuse = type, let view = object as? UIView {
            view.isHidden = true
        }
    }

    private func getP2pMaxCount(reactions: [Basic_V1_Message.Reaction], containerWidth: CGFloat, font: UIFont) -> Int {
        var reactionWidth: CGFloat = 0.0
        var p2pCount: Int = 0
        // 单聊下相同表情至多应展示数字2
        let numWidth = "2".getWidth(font: font) + 2.auto()
        let maxWidth = containerWidth
        let hasMoreWidth = "...".getWidth(font: font)

        for reaction in reactions {
            var emojiWidth: CGFloat = FeedCardReactionComponentView.Cons.emojiHeight
            if let emojiSize = EmotionResouce.shared.sizeBy(key: reaction.type) {
                let widthScale = FeedCardReactionComponentView.Cons.emojiHeight / emojiSize.height
                emojiWidth = emojiSize.width * widthScale
            }
            let emotionWidth = emojiWidth + FeedCardReactionComponentView.Cons.reactionHPadding * 2 + FeedCardReactionComponentView.Cons.reactionHMargin

            var currentReactionWidth = emotionWidth
            if reaction.chatterIds.count > 1 {
                currentReactionWidth += numWidth
            }
            if reactionWidth + currentReactionWidth < maxWidth - hasMoreWidth {
                reactionWidth += currentReactionWidth
                p2pCount += 1
            } else {
                break
            }
        }
        return p2pCount
    }

    enum Cons {
        /// reaction 高度（和字体高度一致）
        private static var _zoom: Zoom?
        private static var _reactionHeight: CGFloat = 0
        static var reactionHeight: CGFloat {
            if Zoom.currentZoom != _zoom {
                _zoom = Zoom.currentZoom
                _reactionHeight = FeedCardDigestComponentView.Cons.digestFont.rowHeight
            }
            return _reactionHeight
        }

        /// font 用于 reaction 表示数量、"..."等label
        private static var _fontZoom: Zoom?
        private static var _font: UIFont?
        static var font: UIFont {
            if Zoom.currentZoom != _fontZoom {
                _fontZoom = Zoom.currentZoom
                _font = UIFont.ud.caption0
            }
            return _font ?? UIFont.ud.caption0
        }

        /// reaction 内部的横向间距
        static var reactionHPadding: CGFloat { 6 }
        /// reaction 之间的横向间距
        static var reactionHMargin: CGFloat { 4 }
        /// reaction 图标的尺寸
        static var emojiHeight: CGFloat {
            reactionHeight - 2.auto()
        }
        /// reaction group 的最大可用宽度
        static func reactionAvailableWidth(_ cellWidth: CGFloat) -> CGFloat {
            return cellWidth
                - Cons.hMargin * 2
                - FeedCardAvatarComponentView.Cons.size
                - Cons.avatarTitlePadding
                - Cons.reactionHPadding
        }
        /// stackView 内边距值
        static var hMargin: CGFloat = 16
        /// 头像和 stackView 之前的 padding
        static var avatarTitlePadding: CGFloat = 12
        /// reaction group 末尾分割线宽度
        static var separatorWidth: CGFloat { 1 }
        /// reaction group 末尾分割线高度
        static var separatorHeight: CGFloat { font.pointSize }
        /// 每个 reaction（不带文字，带末尾 margin）所占宽度
        static var reactionWidthAverage: CGFloat {
            return emojiHeight
                + reactionHPadding * 2
                + reactionHMargin
        }
    }
}

final class ReactionsGroupView: UIView {
    private var reactionViews: [ReactionTupleView] = []
    private var reuseViews: [ReactionTupleView] = []
    let separatorHeight = FeedCardReactionComponentView.Cons.separatorHeight
    let font: UIFont
    init(font: UIFont) {
        self.font = font
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var moreView: UILabel = {
        let label = UILabel()
        label.font = font
        label.text = "..."
        label.textColor = UIColor.ud.N500
        return label
    }()

    private lazy var separator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    private func getReactionTupleView() -> ReactionTupleView {
        if let reactionItemView = reuseViews.popLast() {
            return reactionItemView
        } else {
            let reactionItemView = ReactionTupleView(font: font)
            return reactionItemView
        }
    }

    private func clear() {
        self.subviews.forEach({ view in
            view.removeFromSuperview()
            // TODO: open feed reaction的重用优化
//            guard let view = view as? ReactionTupleView else { return }
//            reuseViews.append(view)
        })
        reactionViews.removeAll()
    }

    func set(reactions: [Basic_V1_Message.Reaction],
             tryAddMoreView: Bool,
             maxCount: Int) -> (CGSize, Bool) {
        assert(!reactions.isEmpty, "Reactions must not be empty.")

        // Clear all legacy views firstly.
        self.clear()
        // 粗略计算能够容纳的 reaction 数量

        // 数量计算现在依赖于cell宽度，但cell setViewModel时就会调用此方法计算尺寸
        // 此时cell frame宽度可能为0，可能计算出小于0的maxCount，异常情况直接返回，待后续cellWidth布局完成后进入后续计算
        // 另外此处还要根据cellWidth减去特定宽度，后续iPad适配后，如果将来对Feed宽度重新设计，也可能有问题
        // 此处先将所有异常情况简单处理，后续需要对这种布局方式redesign
        if maxCount <= 0 {
            return (.zero, false)
        }
        let hasMore = reactions.count > maxCount
        var lastView: UIView?
        reactions.prefix(maxCount).forEach { (reaction) in
            let tupleView = getReactionTupleView()
            tupleView.reaction = reaction
            reactionViews.append(tupleView)
            self.addSubview(tupleView)
            var newFrame = tupleView.frame
            if let lastView = lastView {
                newFrame.origin.x = lastView.frame.maxX + FeedCardReactionComponentView.Cons.reactionHMargin
                tupleView.frame = newFrame
            }
            lastView = tupleView
        }
        reactionViews.forEach {
            $0.backgroundColor = UIColor.ud.N200
        }

        guard let lastView else { return (.zero, false) }
        let width: CGFloat
        if hasMore {
            self.addSubview(moreView)
            moreView.sizeToFit()
            var newFrame = moreView.frame
            newFrame.origin.x = lastView.frame.maxX + FeedCardReactionComponentView.Cons.reactionHMargin
            newFrame.origin.y = (FeedCardReactionComponentView.Cons.reactionHeight - newFrame.height) / 2
            moreView.frame = newFrame
            if tryAddMoreView {
                width = addSeparatorView(leftView: moreView)
            } else {
                width = moreView.frame.maxX
            }
        } else {
            width = addSeparatorView(leftView: lastView)
        }
        return (CGSize(width: width + 1, height: FeedCardReactionComponentView.Cons.reactionHeight), hasMore)
    }

    private func addSeparatorView(leftView: UIView) -> CGFloat {
        self.addSubview(separator)
        separator.frame = CGRect(
            x: leftView.frame.maxX + 5,
            y: (FeedCardReactionComponentView.Cons.reactionHeight - separatorHeight) / 2,
            width: FeedCardReactionComponentView.Cons.separatorWidth,
            height: separatorHeight // TODO: open feed 改成 12
        )
        return separator.frame.maxX
    }
}

private final class ReactionTupleView: UIView {
    let reactionImageView = ReactionImageView()
    let font: UIFont

    lazy var numberLabel: UILabel = {
        let label = UILabel()
        label.font = font
        label.textColor = UDColor.textCaption
        return label
    }()

    init(font: UIFont) {
        self.font = font
        super.init(frame: .zero)
        self.layer.cornerRadius = FeedCardReactionComponentView.Cons.reactionHeight / 2
        self.layer.masksToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var reaction: Basic_V1_Message.Reaction? {
        didSet {
            guard let reaction else { return }
            reactionImageView.set(height: reactionImageView.frame.height, type: reaction.type)
            reactionImageView.sizeToFit()
            var newFrame = reactionImageView.frame
            let x = FeedCardReactionComponentView.Cons.reactionHPadding
            let y = (FeedCardReactionComponentView.Cons.reactionHeight - FeedCardReactionComponentView.Cons.emojiHeight) / 2
            newFrame.origin = CGPoint(x: x, y: y)
            // https://bytedance.feishu.cn/docs/doccnhznbnkgvSrS3tfWgUrFghk#HDIIa3
            // let scale = (newFrame.width > 0 && newFrame.height > 0) ? newFrame.width / newFrame.height : 1
            var emojiWidth: CGFloat = FeedCardReactionComponentView.Cons.emojiHeight
            if let emojiSize = EmotionResouce.shared.sizeBy(key: reaction.type) {
                let widthScale = FeedCardReactionComponentView.Cons.emojiHeight / emojiSize.height
                emojiWidth = emojiSize.width * widthScale
            }
            newFrame.size = CGSize(width: emojiWidth, height: FeedCardReactionComponentView.Cons.emojiHeight)
            reactionImageView.frame = newFrame
            reactionImageView.layer.cornerRadius = reactionImageView.frame.height / 2
            self.addSubview(reactionImageView)
            let chatterCount = reaction.chatterIds.count
            let reactionWidth: CGFloat
            if chatterCount > 1 {
                numberLabel.text = "\(chatterCount)"
                numberLabel.sizeToFit()
                self.addSubview(numberLabel)
                var newFrame = self.numberLabel.frame
                newFrame.origin.x = reactionImageView.frame.maxX + 2
                newFrame.origin.y = (FeedCardReactionComponentView.Cons.reactionHeight - newFrame.height) / 2
                numberLabel.frame = newFrame
                reactionWidth = numberLabel.frame.maxX + FeedCardReactionComponentView.Cons.reactionHPadding
            } else {
                reactionWidth = emojiWidth + FeedCardReactionComponentView.Cons.reactionHPadding * 2
                reactionImageView.frame.centerX = reactionWidth / 2
            }
            self.frame = CGRect(x: 0, y: 0, width: reactionWidth, height: FeedCardReactionComponentView.Cons.reactionHeight)
        }
    }
}

final class ReactionImageView: UIImageView {
    let disposeBag = DisposeBag()

    var reactionType: String?

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.contentMode = .scaleAspectFit
        // 注意：企业自定义表情管理员随时会在后台配置，每次需要渲染的时候才会去下载图片，因此需要监听下载成功事件并及时刷新
        self.handleImageDownloadSucceed()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(height: CGFloat, type: String) {
        // 你不能保证业务传过来的height都是合法值，所以必须兜底
        var defaultHeight: CGFloat = height > 0 ? height : 18
        let start = CACurrentMediaTime()
        reactionType = type
        if let icon = EmotionResouce.shared.imageBy(key: type) {
            self.image = icon
            trackerEmojiLoadDuration(duration: CACurrentMediaTime() - start, emojiKey: type, isLocalImage: true)
            return
        }
        // 走到这边的话表示该reaction没有本地缓存图片，需要从服务端下载
        FeedBaseContext.log.info("feedlog/reaction/load. has no cached image, reactionType = \(type)")
        // 用imageKey发起请求，如果imageKey为空的话就传空字符串（其他企业的自定义表情会出现为空的情况）
        let imageKey = EmotionResouce.shared.imageKeyBy(key: type) ?? ""
        if imageKey.isEmpty {
            FeedBaseContext.log.error("feedlog/reaction/load. imageKey is empty, reactionType = \(type)")
        }
        let resource = LarkImageResource.reaction(key: imageKey, isEmojis: true)
        self.contentMode = .topLeft
        self.layer.masksToBounds = true
        self.layer.cornerRadius = defaultHeight / 2
        self.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.06)

        self.bt.setLarkImage(
            with: resource,
            trackStart: {
                TrackInfo(biz: .Messenger, scene: .Chat, fromType: .reaction)
            },
            completion: { [weak self] result in
                var isCache = false
                switch result {
                case .success(let imageResult):
                    if let reactionIcon = imageResult.image {
                        self?.contentMode = .scaleAspectFit
                        self?.image = reactionIcon
                        self?.layer.cornerRadius = 0
                        self?.layer.masksToBounds = false
                        self?.backgroundColor = UIColor.clear
                    }
                    isCache = imageResult.from == .diskCache || imageResult.from == .memoryCache
                case .failure:
                    FeedBaseContext.log.error("feedlog/reaction/load. setLarkImage failed, reactionType = \(type)")
                }
                self?.trackerEmojiLoadDuration(duration: CACurrentMediaTime() - start, emojiKey: type, isLocalImage: isCache)
            })
    }

    private func trackerEmojiLoadDuration(duration: CFTimeInterval, emojiKey: String, isLocalImage: Bool) {
        if isLocalImage {
            Tracker.post(SlardarEvent(name: "larkw_emoji",
                                      metric: ["emoji_img_load_duration": duration * 1000],
                                      category: ["protocol": "file", "domain": "unknown"],
                                      extra: ["emojiKey": emojiKey]))
        } else {
            Tracker.post(SlardarEvent(name: "larkw_emoji",
                                      metric: ["emoji_img_load_duration": duration * 1000],
                                      category: ["protocol": "rust", "domain": "unknown"],
                                      extra: ["emojiKey": emojiKey]))
        }
    }

    // 表情图片下载成功后要刷新下数据源
    private func handleImageDownloadSucceed() {
        NotificationCenter.default.rx
            .notification(.LKEmojiImageDownloadSucceedNotification)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (notification) in
                guard let `self` = self else { return }
                guard let info = notification.object as? [String: Any] else { return }
                if let key = info["key"] as? String, key == self.reactionType,
                   let resource = EmotionResouce.shared.resourceBy(key: key),
                   let image = resource.image {
                    self.contentMode = .scaleAspectFit
                    self.image = image
                    self.layer.cornerRadius = 0
                    self.layer.masksToBounds = false
                    self.backgroundColor = UIColor.clear
                }
            })
            .disposed(by: disposeBag)
    }
}
