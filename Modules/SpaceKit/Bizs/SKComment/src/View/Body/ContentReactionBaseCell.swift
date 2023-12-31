//
//  ContentReactionBaseCell.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/8/7.
//  


import UIKit
import SnapKit
import SKFoundation
import LarkEmotion
import SKResource
import LarkReactionView
import UniverseDesignIcon
import LarkMenuController
import UniverseDesignColor
import SpaceInterface

/// 正文reaction表情Cell
class ContentReactionBaseCell: CommentShadowBaseCell {
    
    fileprivate static var _cellId: String { String(describing: ContentReactionBaseCell.self) }
    
    weak var delegate: CommentTableViewCellDelegate?
    
    private(set) var commentItem: CommentItem?
    
    /// 允许触发reaction事件：more按钮显示、长按响应、点击表情响应
    private var canTriggerReaction = true
    
    var cellWidth: CGFloat? {
        didSet {
            updateReactionViewMaxWidth(cellWidth: cellWidth)
        }
    }
    
    /// 表情View
    private(set) lazy var reactionView: ReactionView = _setupReactionView()
    
    /// 表情末尾虚拟View，用于点击末尾按钮时避免遮挡ReactionView
    private(set) lazy var reactionTailView = UIView()
    
    private lazy var longPressGesture: UILongPressGestureRecognizer = _setupLongPress()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupNotification()
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) {
            self.updateReactionViewMaxWidth()
        }
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func setupUI() {
        self.addGestureRecognizer(longPressGesture)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
    
    private func setupNotification() {
        let name1 = UIApplication.didChangeStatusBarOrientationNotification
        NotificationCenter.default.addObserver(self, selector: #selector(handleOrientationChange), name: name1, object: nil)
        
        let name2 = MenuViewController.Notification.MenuControllerDidHideMenu
        NotificationCenter.default.addObserver(self, selector: #selector(handleMenuHide), name: name2, object: nil)
    }
    
    @objc
    func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard canTriggerReaction else { return }
        delegate?.didLongPressToShowReaction(self, gesture: gesture)
    }
    
    @objc
    private func handleOrientationChange() {
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) {
            self.updateReactionViewMaxWidth()
        }
    }
    
    @objc
    private func handleMenuHide() {
        let image = BundleResources.SKResource.Common.ReactionPanel.ReactionPanel_showmore
        reactionView.resetReactionOpenEntranceImage(image)
    }
    
    /// for override
    func reactionMaxLayoutWidth(_ cellWidth: CGFloat) -> CGFloat {
        return CGFloat(cellWidth - 84)
    }
    
    @objc
    private func handleTapReactionIcon(_ data: Any) {
        guard let (reactionVM, tapType) = data as? (ReactionInfo, ReactionTapType) else { return }
        delegate?.didClickReaction(commentItem, reactionVM: reactionVM, tapType: tapType)
    }
}

extension ContentReactionBaseCell {
    
    func updateCommentItem(_ item: CommentItem?) {
        commentItem = item
        updateReactions(item?.reactions ?? [])
    }
    
    func setCanTriggerReaction(_ canTrigger: Bool) {
        canTriggerReaction = canTrigger
        reactionView.setReactionsData(reactions: reactionView.reactions,
                                      showReactionOpenEntrance: canTriggerReaction)
    }
    
    private func updateReactions(_ reactions: [CommentReaction]) {
        guard !reactions.isEmpty else {
            reactionView.reactions = []
            reactionView.isHidden = true
            return
        }
        reactionView.isHidden = false
        if reactionView.preferMaxLayoutWidth <= 0 {
            updateReactionViewMaxWidth(cellWidth: cellWidth)
        }
        UIView.performWithoutAnimation {
            let larkReactions = reactions.map { $0.toLarkReactionInfo() }
            self.reactionView.setReactionsData(reactions: larkReactions,
                                               showReactionOpenEntrance: canTriggerReaction)
        }
    }
    
    private func updateReactionViewMaxWidth(cellWidth: CGFloat? = nil) {
        let cellCopy = cellWidth ?? contentView.frame.size.width
        if cellCopy > 84 {
            reactionView.preferMaxLayoutWidth = reactionMaxLayoutWidth(cellCopy)
        }
    }
}

// MARK: ReactionView Delegate

extension ContentReactionBaseCell: ReactionViewDelegate {
    
    func reactionBeginTap(_ reactionVM: ReactionInfo, tapType: ReactionTapType) {
        if case .icon = tapType, !canTriggerReaction { return } // 不允许触发表情
        // 这么做的原因是: reactionDidTapped方法会在动画结束后调用，如果快速连续点击一个表情，可能会在动画期间由于前端数据过来使cell复用了，
        // 传递过去的commentItem就不对了，因此改为动画期间不会发出表情，动画结束后才发出
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        let data = (reactionVM, tapType)
        let delay = ReactionView.iconAnimationDuration
        self.perform(#selector(handleTapReactionIcon), with: data, afterDelay: delay)
    }

    func reactionDidTapped(_ reactionVM: ReactionInfo, tapType: ReactionTapType) {
        switch tapType {
        case .name, .more:
            handleTapReactionIcon((reactionVM, tapType))
        case .icon: break
        @unknown default: break
        }
    }

    func reactionViewImage(_ reactionVM: ReactionInfo, callback: @escaping (UIImage) -> Void) {
        if let image = EmotionResouce.shared.imageBy(key: reactionVM.reactionKey) {
            callback(image)
        }
    }
    
    func reactionViewDidOpenEntrance() {
        guard let item = commentItem, canTriggerReaction else { return }
        let image = BundleResources.SKResource.Common.ReactionPanel.ReactionPanel_showmore
        let tintImage = image.tinted(with: UDColor.colorfulBlue)
        reactionView.resetReactionOpenEntranceImage(tintImage)
        delegate?.didClickMoreAction(button: reactionTailView, cell: self, commentItem: item)
    }
}

// MARK: setup

extension ContentReactionBaseCell {
    
    private func _setupReactionView() -> ReactionView {
        let reactionView = ReactionView()
        reactionView.tagBackgroundColor = UIColor.ud.udtokenReactionBgGreyFloat
        reactionView.delegate = self
        return reactionView
    }
    
    private func _setupLongPress() -> UILongPressGestureRecognizer {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPress.minimumPressDuration = 0.4
        longPress.delegate = self
        return longPress
    }
}

/// 正文reaction表情Cell：iPhone显示
class ContentReactionPhoneCell: ContentReactionBaseCell {
    
    static var cellId: String { _cellId + "_iPhone" }
    
    private let xMargin = CGFloat(16)
    
    /// 容器View
    private lazy var bgContainerView: UIView = _setupBgView()
    
    override func setupUI() {
        super.setupUI()
        
        contentView.addSubview(bgContainerView)
        bgContainerView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.bottom.equalToSuperview().inset(3)
        }
        
        bgContainerView.addSubview(reactionView)
        reactionView.snp.makeConstraints {
            $0.top.equalTo(9)
            $0.leading.trailing.equalToSuperview().inset(xMargin)
            $0.bottom.equalTo(-9)
        }
        
        bgContainerView.addSubview(reactionTailView)
        reactionTailView.snp.makeConstraints {
            $0.bottom.equalTo(reactionView).offset(-10)
            $0.trailing.equalTo(reactionView)
            $0.size.equalTo(1)
        }
    }
    
    override func reactionMaxLayoutWidth(_ cellWidth: CGFloat) -> CGFloat {
        return cellWidth - (xMargin * 2)
    }
}

extension ContentReactionPhoneCell: CommentHighLightAnimationPerformer {
    
    func setBgViewColor(color: UIColor) {
        let bgColorView = bgContainerView.viewWithTag(999)
        bgColorView?.backgroundColor = color
    }
}

/// 正文reaction表情Cell：iPad显示
class ContentReactionPadCell: ContentReactionBaseCell {
    
    static var cellId: String { _cellId + "_iPad" }
    
    private let backgroundPadding = CGFloat(12)
    private let reactionPadding = CGFloat(12)
    
    override func setupUI() {
        super.setupUI()
        
        contentView.addSubview(bgShadowView)
        bgShadowView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(backgroundPadding)
            $0.top.bottom.equalToSuperview()
        }
        
        bgShadowView.addSubview(reactionView)
        reactionView.snp.makeConstraints {
            $0.top.equalTo(8)
            $0.leading.trailing.equalToSuperview().inset(reactionPadding)
            $0.bottom.equalTo(-8)
        }

        bgShadowView.addSubview(reactionTailView)
        reactionTailView.snp.makeConstraints {
            $0.bottom.equalTo(reactionView).offset(-15)
            $0.trailing.equalTo(reactionView)
            $0.size.equalTo(1)
        }
    }
    
    override func reactionMaxLayoutWidth(_ cellWidth: CGFloat) -> CGFloat {
        return cellWidth - (reactionPadding * 2) - (backgroundPadding * 2)
    }
    
    // 为了解决 reactionView 点击响应的问题
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touchView = touch.view else { return true }
        if gestureRecognizer == highLightTap {
            if touchView.isDescendant(of: reactionView), touchView.superview != reactionView, touchView != reactionView {
                return false
            }
            return true
        }
        return true
    }
    
    @objc
    override func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard highLighted else { return } // 仅高亮的cell能响应长按
        super.handleLongPress(gesture)
    }
}

private extension UIImage {
    
    func tinted(with color: UIColor) -> UIImage {
        defer { UIGraphicsEndImageContext() }
        var renderSize = size
        if renderSize.width == 0 { renderSize.width = 1 }
        if renderSize.height == 0 { renderSize.height = 1 }
        UIGraphicsBeginImageContextWithOptions(renderSize, false, scale)
        color.set()
        self.withRenderingMode(.alwaysTemplate).draw(in: CGRect(origin: .zero, size: renderSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}
