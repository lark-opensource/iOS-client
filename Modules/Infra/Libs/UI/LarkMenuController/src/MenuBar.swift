//
//  MenuBar.swift
//  LarkChat
//
//  Created by 李晨 on 2019/1/29.
//

import UIKit
import Foundation
import LarkEmotionKeyboard
import LKCommonsLogging
import LarkSetting

/// MenuBarStyle
public enum MenuBarStyle {
    /// light
    case light
    /// dark
    case dark
}

public final class MenuBar: UIView {
    /// 最近使用的背景，最近使用点击展示全部reaction的时候，动画会有些问题(从最近使用的上层浮出，有重叠)
    /// 需要reactionBarBgView遮挡不需要展示的部分，整个看起来更加流畅
    private let reactionBarBgView: UIView = UIView()
    
    // reaction注入服务
    private let dependency: EmojiDataSourceDependency? = EmojiImageService.default

    // MARK: public属性
    // 是否展示更多的表情面板
    public var showMoreReactionBar: Bool = false {
        didSet {
            guard showMoreReactionBar != oldValue else { return }
            self.userReactionBar.showMore = showMoreReactionBar
            updateSubviewsLayout()
        }
    }

    // reaction是否在顶部
    public var reactionSupportSkinTones: Bool = false {
        didSet {
            self.moreReactionBar.reactionSupportSkinTones = reactionSupportSkinTones
        }
    }

    // reaction是否在顶部
    public var reactionBarAtTop: Bool = false {
        didSet {
            updateSubviewsLayout()
        }
    }

    public var hideRelactionBar: Bool {
        return reactionBar.items.isEmpty
    }

    // 设置当前menu的VC的宽度
    public var viewControllerWidth: CGFloat = UIScreen.main.bounds.width {
        didSet {
            // 设置actionBar的最大宽度，actionBar使用这个宽度，更新每个item的大小，但不会collection.reloadData
            actionBar.maxActionBarWidth = max(320, CGFloat(min(viewControllerWidth * 88 / 100, 450)))
            // menuBar再updateSubviewsLayout，可以获取到menu的正确大小
            updateSubviewsLayout()
        }
    }
    public override var bounds: CGRect {
        didSet {
            guard oldValue.size != bounds.size else { return }
            self.wrapperView.frame = self.bounds
            self.updateMoreBarLayout()
        }
    }
    public override var frame: CGRect {
        didSet {
            guard oldValue.size != bounds.size else { return }
            self.wrapperView.frame = self.bounds
            self.updateMoreBarLayout()
        }
    }

    public override var backgroundColor: UIColor? {
        didSet {
            self.reactionBarBgView.backgroundColor = backgroundColor
        }
    }

    // 四个view
    public let reactionBar: RecentReactionsBar
    public let userReactionBar: ReactionBar
    public let actionBar: MenuActionBar
    public let reactionPanel: ReactionPanel
    public let moreReactionBar: MoreReactionsBar
    // view之间的间隔
    public let lineXInset: CGFloat = 16 // line在x轴方向的inset
    public let lineHeight: CGFloat = 0.5 // line高度
    public let barSpaceWithLine: CGFloat = 16 // actionBar与line的间距
    public let barYInset: CGFloat = 14 // menuBar在y轴方向的inset

    // MARK: private属性
    // logger
    private static let logger = Logger.log(MenuBar.self, category: "LarkMenuController.MenuBar")
    // 最底层的view
    private let wrapperView: UIView = UIView()
    // 分割线
    private let line: UIView = UIView()
    // 计算menu的宽度
    private var menuWidth: CGFloat {
        // 如果没有reaction，menu宽度由actionBar决定
        if userReactionBar.items.isEmpty && reactionPanel.isHidden {
            return actionBar.getActionBarWidth()
        }
        // 有reaction，menu宽度为VC宽度的88%，并控制在320到450之间
        return max(320, CGFloat(min(viewControllerWidth * 88 / 100, 450)))
    }
    private let scene: ReactionPanelScene

    public init(reactions: [MenuReactionItem],
         allReactionGroups: [ReactionGroup],
         actionItems: [MenuActionItem],
         supportMoreReactions: Bool,
         style: MenuBarStyle? = nil,
         triggerGesture: UIGestureRecognizer? = nil,
         scene: ReactionPanelScene = .unknown) {
        // 新版ReactionBar
        self.userReactionBar = ReactionBar(config: .init(items: reactions,
                                                         supportMoreReactions: supportMoreReactions))
        // 老版ReactionBar（FG全量后再删除）
        self.reactionBar = RecentReactionsBar(config: .init(items: reactions,
                                                            supportMoreReactions: supportMoreReactions))
        // 新版Reaction面板
        let supportSheetMenu = FeatureGatingManager.shared.featureGatingValue(with: "im.emoji.commonly_used_abtest")
        self.reactionPanel = ReactionPanel(config: .init(supportSheetMenu: supportSheetMenu, scene: scene))
        // 老板Reaction面板（FG全量后再删除）
        self.moreReactionBar = MoreReactionsBar(config: .init(pageIndicatorTintColor: UIColor.ud.N300,
                                                              currentPageIndicatorTintColor: UIColor.ud.primaryContentDefault,
                                                              reactionGroups: allReactionGroups))
        self.actionBar = MenuActionBar(frame: .zero)
        self.scene = scene
        super.init(frame: CGRect.zero)
        setupSubviews(reactions: reactions, actionItems: actionItems, style: style)
    }

    // MARK: public方法
    // 更新menu数据
    public func reloadMenuBarByItems(_ items: [MenuActionItem], relactionItems: [MenuReactionItem]?) {
        MenuBar.logger.info("reloadMenuBar items \(items) \(relactionItems ?? [])")
        self.actionBar.hasReactionBar = !(relactionItems?.isEmpty ?? true)
        if let reactionItems = relactionItems {
            self.userReactionBar.items = reactionItems
        }
        self.actionBar.items = items
        updateSubviewsLayout()
    }

    var reactionBarHasHidden = false
    // 隐藏emoji header
    public func hideReactionBar() {
        self.actionBar.hasReactionBar = false
        self.reactionBar.items = []
        self.userReactionBar.items = []
        reactionBar.isHidden = true
        userReactionBar.isHidden = true
        reactionBarHasHidden = true
        updateSubviewsLayout()
    }

    // 获取menu的大小
    // 获取之前确保调用过updateSubviewsLayout，方法会将各个子View设置隐藏会展示
    public var menuSize: CGSize {
        var showReactionPanel = false
        var reactionPanelHeight = 0.0
        var showReactionBar = false
        var reactionBarHeight = 0.0
        showReactionPanel = !reactionPanel.isHidden
        reactionPanelHeight = reactionPanel.panelHeight
        showReactionBar = !userReactionBar.isHidden
        reactionBarHeight = userReactionBar.reactionBarHeight
        // 展示Reaction面板
        if showReactionPanel {
            // 如果同时展示ReactionBar和ReactionPanel
            if showReactionBar {
                let height = reactionBarHeight + barSpaceWithLine + barYInset + lineHeight + reactionPanelHeight
                MenuBar.logger.info("menuSize reactionPanel + mruReactionsBar width: \(menuWidth) height: \(height))")
                return CGSize(width: menuWidth, height: height)
            } else {
                // 如果只展示ReactionPanel
                MenuBar.logger.info("menuSize reactionPanel width: \(menuWidth) reactionPanel.panelHeight height: \(reactionPanelHeight)")
                return CGSize(width: menuWidth, height: reactionPanelHeight)
            }
        } else if showReactionBar && !actionBar.isHidden {
            // 展示ReactionBar和ActionBar
            let height = reactionBarHeight + (barSpaceWithLine + barYInset) * 2 + lineHeight + actionBar.getActionBarHeight()
            MenuBar.logger.info("menuSize reactionBar + actionBar width: \(menuWidth) height: \(height), actionBarHeight \(actionBar.getActionBarHeight())")
            return CGSize(width: menuWidth, height: height)
        } else if showReactionBar && actionBar.isHidden {
            // 只展示ReactionBar 这里需要加上下上边距 否则UI展示异常
            return CGSize(width: menuWidth, height: reactionBarHeight + barYInset * 2)
        } else if !showReactionBar && !actionBar.isHidden {
            // 只展示ActionBar
            MenuBar.logger.info("menuSize actionBar width: \(menuWidth) height \(actionBar.getActionBarHeight())")
            return CGSize(width: menuWidth, height: actionBar.getActionBarHeight() + barYInset * 2)
        } else {
            // 什么都没展示
            return .zero
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview != nil,
           !userReactionBar.items.isEmpty {
            MenuTracker.trackerTea(event: Const.reactionPopupEvent, params: [Const.scene: self.scene])
        }
    }

    // MARK: private方法
    private func setupSubviews(reactions: [MenuReactionItem],
                               actionItems: [MenuActionItem],
                               style: MenuBarStyle? = nil) {
        self.layer.masksToBounds = false
        self.layer.cornerRadius = 10
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.layer.shadowOpacity = 1.0
        self.layer.ud.setShadowColor(UIColor.ud.shadowDefaultSm)

        self.wrapperView.layer.masksToBounds = true
        self.wrapperView.backgroundColor = UIColor.clear
        self.wrapperView.layer.cornerRadius = 10

        self.addSubview(self.wrapperView)
        self.wrapperView.addSubview(self.actionBar)
        self.wrapperView.addSubview(self.line)
        self.wrapperView.addSubview(self.reactionPanel)
        self.wrapperView.addSubview(self.reactionBarBgView)
        self.wrapperView.addSubview(self.userReactionBar)

        reactionBar.isHidden = true
        userReactionBar.isHidden = true
        actionBar.isHidden = true
        line.isHidden = true
        moreReactionBar.isHidden = true
        reactionPanel.isHidden = true
        reactionBarBgView.isHidden = true

        self.wrapperView.accessibilityIdentifier = "menu.bar.wraper"
        self.userReactionBar.accessibilityIdentifier = "menu.bar.reactionbar"
        self.reactionPanel.accessibilityIdentifier = "menu.bar.more.reactionbar"
        self.actionBar.accessibilityIdentifier = "menu.bar.actionbar"

        self.backgroundColor = UIColor.ud.bgFloat
        self.reactionBar.moreIconColor = UIColor.ud.iconN1
        self.line.backgroundColor = UIColor.ud.lineDividerDefault

        if let style = style, style == .dark {
            self.reactionBar.moreIconColor = UIColor.ud.iconN1
            self.backgroundColor = UIColor.ud.bgFloat
        }

        self.reloadMenuBarByItems(actionItems, relactionItems: reactions)
    }

    // 更新布局，设置view是否隐藏
    private func updateSubviewsLayout() {
        var items: [MenuReactionItem] = userReactionBar.items
        // 是否可以展示各个view，即使在展示moreReactionBar时，也保持原来的view的frame不变
        let canShowReactionBar: Bool = !items.isEmpty
        // 是否可以展示分割线
        var canShowLine: Bool = false
        if showMoreReactionBar {
            canShowLine = !items.isEmpty
        } else {
            canShowLine = !items.isEmpty && !actionBar.items.isEmpty
        }
        /// 是否可以展示actionBar
        let canShowActionBar: Bool = !actionBar.items.isEmpty

        var reactionBarY: CGFloat = 0 // reaction的y轴位置
        var lineY: CGFloat = 0 // line的y轴位置
        var actionBarY: CGFloat = 0 // action的y轴位置
        var moreReactionBarY: CGFloat = 0 // 更多reaction的y轴位置
        var reactionBarBgY: CGFloat = 0 // reaction背景的y轴位置
        
        // ReactionPanel的高度
        var reactionPanelHeight = reactionPanel.panelHeight
        var reactionBarHeight = userReactionBar.reactionBarHeight

        if reactionBarAtTop {
            if canShowReactionBar {
                reactionBarY = barYInset
            }
            if canShowLine {
                lineY = reactionBarY + reactionBarHeight + barSpaceWithLine
            }
            actionBarY = canShowReactionBar ? (lineY + lineHeight + barSpaceWithLine) : barYInset
            moreReactionBarY = canShowReactionBar ? (lineY + lineHeight) : 0
        } else {
            /// 是否可以展示actionBar
            if canShowActionBar {
                actionBarY = barYInset
            }
            if canShowLine {
                let height = !self.showMoreReactionBar ? actionBar.getActionBarHeight() : reactionPanelHeight
                let y = !self.showMoreReactionBar ? actionBarY : moreReactionBarY
                lineY = y + height + (!self.showMoreReactionBar ? barSpaceWithLine : 0)
            }
            if canShowReactionBar {
                if !self.showMoreReactionBar {
                    reactionBarY = canShowActionBar ? (lineY + lineHeight + barSpaceWithLine) : barYInset
                } else {
                    reactionBarY = lineY + lineHeight + barSpaceWithLine
                }
            }
            reactionBarBgY = reactionBarY
        }

        // 更新subviews的布局
        line.frame = CGRect(x: lineXInset, y: lineY, width: menuWidth - lineXInset * 2, height: lineHeight)
        actionBar.frame = CGRect(x: 0, y: actionBarY, width: menuWidth, height: actionBar.getActionBarHeight())
        reactionPanel.frame = CGRect(x: 0, y: moreReactionBarY, width: menuWidth, height: reactionPanelHeight)
        userReactionBar.frame = CGRect(x: 0, y: reactionBarY, width: menuWidth, height: reactionBarHeight)
        let reactionBarBgViewHeight = reactionBarHeight + barYInset
        reactionBarBgView.frame = CGRect(x: 0, y: reactionBarBgY, width: menuWidth, height: reactionBarBgViewHeight)

        // mru & all 会同时存在
        self.line.isHidden = !showMoreReactionBar ? (reactionBar.items.isEmpty || actionBar.items.isEmpty) : reactionBar.items.isEmpty
        self.actionBar.isHidden = showMoreReactionBar || (actionBar.items.isEmpty ? true : false)
        var reactionBarIsHidden = true
        self.userReactionBar.isHidden = userReactionBar.items.isEmpty
        self.userReactionBar.clipsToBounds = true
        reactionBarIsHidden = self.userReactionBar.isHidden
        self.reactionPanel.isHidden = !showMoreReactionBar
        self.reactionPanel.clipsToBounds = true
        self.reactionBarBgView.isHidden = !reactionBarHasHidden ? !showMoreReactionBar : true
        MenuBar.logger.info("menuBar update subview \(reactionBarIsHidden) \(line.isHidden) \(actionBar.isHidden) \(!showMoreReactionBar)")
    }

    private func updateMoreBarLayout() {
        self.updateSubviewsLayout()
        var offset = self.reactionPanel.collection.contentOffset
        self.reactionPanel.layout.invalidateLayout()
        self.reactionPanel.collection.reloadData()
        var maxOffSet = self.reactionPanel.collection.contentSize.height - self.reactionPanel.collection.frame.height
        var collectionView = self.reactionPanel.collection
        guard maxOffSet > 0, offset.y < maxOffSet else {
            return
        }
        collectionView.setContentOffset(CGPoint(x: 0, y: offset.y), animated: false)
    }
}

extension MenuBar {
    enum Const {
        static let reactionPopupEvent: String = "public_reaction_panel_popup_view"
        static let scene: String = "scene"
    }
}
