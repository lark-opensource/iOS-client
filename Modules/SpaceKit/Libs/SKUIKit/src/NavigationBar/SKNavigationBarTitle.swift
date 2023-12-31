//
//  SKNavigationBarTitleView.swift
//  SpaceKit
//
//  Created by 边俊林 on 2020/2/26.
//

import Foundation
import UIKit
import SKFoundation
import SKResource
import UniverseDesignColor
import UniverseDesignTag
import UniverseDesignIcon

/** A protocol that allows the user to provide a detailed configuration scheme */
public protocol SKNavigationBarTitleUIDelegate: AnyObject {

    func titleBarShouldShowExternalLabel(_ titleBar: SKNavigationBarTitle) -> Bool

    func titleBarShouldShowSecondTagLabel(_ titleBar: SKNavigationBarTitle) -> Bool
    
    func titleBarShouldShowTemplateTag(_ titleBar: SKNavigationBarTitle) -> Bool

    func titleBarShouldShowTitle(_ titleBar: SKNavigationBarTitle) -> Bool

    func titleBarShouldShowAvatar(_ titleBar: SKNavigationBarTitle) -> Bool

    func configureAvatarImageView(_ avatarImage: DocsAvatarImageView, with icon: IconSelectionInfo?)

    func titleBarShouldShowActionButton(_ titleBar: SKNavigationBarTitle) -> Bool
    
    func titleBarShowTitle() -> String?
    
    func configureActionButton(_ tipIcon: UIImageView)
    
    func actionButtonHandle(_ tipIcon: UIImageView, dissCallBack: @escaping() -> Void)
    
    func updateActionButton(_ tipIcon: UIImageView)
}

/** Default TitleView used  in `SKNavigationBar`, provides default presentation capabilities. */
//swiftlint:disable function_body_length
// swiftlint:disable type_body_length
public final class SKNavigationBarTitle: UIView, SKNavigationBarCustomTitleView {
    
    public weak var uiDelegate: SKNavigationBarTitleUIDelegate?

    public var title: String? {
        didSet {
            setNeedsLayout()
        }
    }

    public var subtitle: String? {
        didSet {
            setNeedsLayout()
        }
    }

    public var customView: UIView? {
        willSet {
            if newValue == nil {
                customView?.removeFromSuperview()
            }
        }
        didSet {
            oldValue?.removeFromSuperview()
            if let customView = customView {
                addSubview(customView)
            } else {
            }
            setNeedsLayout()
        }
    }
    
    public var iconInfo: IconSelectionInfo? {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var titleBottomAttachInfo: SKBarTitleBottomAttachInfo? {
        didSet {
            setNeedsLayout()
        }
    }

    /// Specifies whether to display the title and subtitle
    public var shouldShowTexts: Bool = true {
        didSet {
            setNeedsLayout()
        }
    }

    /// Decide whether to display external tenant identification
    public var needDisPlayTag: Bool = false {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var tagContent: String? {
        didSet {
            externalLabel.text = tagContent
            setNeedsLayout()
        }
    }

    public var showSecondTag: Bool = false {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var showTemplateTag: Bool = false {
        didSet {
            setNeedsLayout()
        }
    }

    public var titleHorizontalAlignment: UIControl.ContentHorizontalAlignment = .leading {
        didSet {
            setNeedsLayout()
        }
    }

    public var titleFont: UIFont {
        get {
            titleLabel.font
        }
        set {
            titleLabel.font = newValue
            setNeedsLayout()
        }
    }

    public var subtitleFont: UIFont {
        get {
            subtitleLabel.font
        }
        set {
            subtitleLabel.font = newValue
            setNeedsLayout()
        }
    }

    // MARK: UI Widget
    // Warning: You'd best not to make direct changes to these encapsulated UI components.
    
    public var displayType: NavigationTitleInfo.DisplayType = .title
    
    // 文字比较大的标题，title 和 subTitle 不会一起显示
    public var titleLabel: UILabel
    
    // 文字比较小的标题，title 和 subTitle 不会一起显示
    public var subtitleLabel: UILabel
    
    // 位于标题下方，由 icon 和文字组成的附视图。
    public var titleBottomAttachView: SKBarTitleBottomAttachView
    
    // 自定义view布局
    public var overridingCustomViewSizeProvider: ((CGSize) -> CGSize)?

    // 类似头像视图
    private(set) var avatarView: DocsAvatarImageView
    
    // 文档是否来自外部的标签
    private(set) lazy var externalLabel: UDTag = {
        let config = UDTagConfig.TextConfig(cornerRadius: 4,
                                            textColor: UDColor.udtokenTagTextSBlue,
                                            backgroundColor: UDColor.udtokenTagBgBlue)
        let tag = UDTag(text: "",
                        textConfig: config)
        return tag
    }()

    private(set) var secondTagLabel: SecondTagLabel
    
    let templateTag: TemplateTag = TemplateTag()
    
    // title后面的icon，比如版本后面的展示历史入口
    public var actionTipView: UIImageView
    
    public var titleTouchControl: UIControl

    private let avatarWidth: CGFloat = 24
    
    private let tagPadding: CGFloat = 5

    private let avatarPadding: CGFloat = 4

    private let customViewPadding: CGFloat = 5
    
    private let titleBottomAttachHeight: CGFloat = 16
    
    private let actionTipWidth: CGFloat = 16
    
    private let tagViewMinWidth: CGFloat = 33
    
    private var leadingOffsetX: CGFloat = 0
    
    private var trailOffsetX: CGFloat = 0

    // MARK: Interface
    public override init(frame: CGRect) {
        titleLabel = UILabel()
        subtitleLabel = UILabel()
        avatarView = DocsAvatarImageView()
        secondTagLabel = SecondTagLabel()
        titleBottomAttachView = SKBarTitleBottomAttachView()
        titleTouchControl = UIControl()
        actionTipView = UIImageView()
        super.init(frame: frame)
        titleTouchControl.addTarget(self, action: #selector(didTapActionButton), for: .touchUpInside)
        commonInit()
    }

    required public init?(coder: NSCoder) {
        titleLabel = UILabel()
        subtitleLabel = UILabel()
        avatarView = DocsAvatarImageView()
        secondTagLabel = SecondTagLabel()
        titleBottomAttachView = SKBarTitleBottomAttachView()
        titleTouchControl = UIControl()
        actionTipView = UIImageView()
        super.init(coder: coder)
        titleTouchControl.addTarget(self, action: #selector(didTapActionButton), for: .touchUpInside)
        commonInit()
    }

    /** Never call it directly, if overrided, you should call `super` in your own implementation. */
    public func commonInit() {
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(avatarView)
        addSubview(externalLabel)
        addSubview(secondTagLabel)
        addSubview(titleBottomAttachView)
        addSubview(templateTag)
        addSubview(actionTipView)
        addSubview(titleTouchControl)
        backgroundColor = .clear
    }

    @objc
    private func didTapActionButton() {
        uiDelegate?.actionButtonHandle(actionTipView, dissCallBack: { [weak self] in
            guard let iconView = self?.actionTipView else {
                return
            }
            self?.uiDelegate?.updateActionButton(iconView)
        })
    }

    // MARK: Layout
    public override func layoutSubviews() {
        super.layoutSubviews()
        _sizeThatFits(bounds.size, forceLayout: true)
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        _sizeThatFits(size)
    }
    
    public func layoutTitle(size: CGSize, leadingOffset: CGFloat, trailOffset: CGFloat) -> CGSize {
        leadingOffsetX = leadingOffset
        trailOffsetX = trailOffset
        return _sizeThatFits(size)
    }
    
    // swiftlint:disable cyclomatic_complexity
    @discardableResult
    private func _sizeThatFits(_ size: CGSize, forceLayout: Bool = false) -> CGSize {
        var leadingOffset: CGFloat = 0, trailingOffset: CGFloat = 0
        var accessoryViews: [UIView] = []

        // Add custom view if needed
        let shouldShowCustomView = (displayType == .customized || displayType == .fullCustomized)
        if let customView = customView {
            if shouldShowCustomView, displayType == .fullCustomized {
                customView.frame.size = size
            }
            let customViewWidth = shouldShowCustomView ? customView.frame.width : 0
            let customViewOccupiedWidth = customViewWidth + (shouldShowCustomView ? customViewPadding : 0)
            if forceLayout {
                if shouldShowCustomView {
                    customView.isHidden = false
                    customView.frame = CGRect(x: 0, y: (size.height - customView.frame.height) / 2,
                                              width: customView.frame.width, height: customView.frame.height)
                    accessoryViews.append(customView)
                } else {
                    customView.isHidden = true
                    customView.frame = .zero
                }
            }
            leadingOffset += customViewOccupiedWidth
        }

        // Add avatar if needed
        let shouldShowAvatar = (uiDelegate?.titleBarShouldShowAvatar(self) ?? true) && iconInfo != nil && displayType != .fullCustomized
        let avatarViewWidth: CGFloat = shouldShowAvatar ? avatarWidth : 0
        let avatarOccupiedWidth = avatarViewWidth + (shouldShowAvatar ? avatarPadding : 0)
        if forceLayout {
            if shouldShowAvatar {
                avatarView.isHidden = false
                avatarView.frame = CGRect(x: leadingOffset,
                                          y: (size.height - avatarWidth) / 2,
                                          width: avatarWidth,
                                          height: avatarWidth)
                configureIcon(avatarView, with: iconInfo)
                accessoryViews.append(avatarView)
            } else {
                avatarView.isHidden = true
                avatarView.frame = .zero
            }
        }
        leadingOffset += avatarOccupiedWidth

        // Calculate leftout space for texts
        var shouldShowTitleAndSubtitle = (uiDelegate?.titleBarShouldShowTitle(self) ?? true) && shouldShowTexts && displayType != .fullCustomized
        let shouldShowActionButton = (uiDelegate?.titleBarShouldShowActionButton(self) ?? false)
        let shouldShowTitleBottomAttach = titleBottomAttachInfo != nil && !shouldShowActionButton && displayType != .fullCustomized

        var tagViews: [(UIView, Bool)] = []
        
        let shouldShowExternal = (uiDelegate?.titleBarShouldShowExternalLabel(self) ?? true) && needDisPlayTag && (tagContent != nil) && displayType != .fullCustomized && shouldShowTexts
        tagViews.append((externalLabel, shouldShowExternal))

        let shouldShowSecondTagLabel = (uiDelegate?.titleBarShouldShowSecondTagLabel(self) ?? true) && showSecondTag && displayType != .fullCustomized
        tagViews.append((secondTagLabel, shouldShowSecondTagLabel))
        
        let shouldShowTemplateTag = (uiDelegate?.titleBarShouldShowTemplateTag(self) ?? true) && showTemplateTag && !shouldShowActionButton && displayType != .fullCustomized
        tagViews.append((templateTag, shouldShowTemplateTag))
        for (_, shouldShow) in tagViews {
            trailingOffset += shouldShow ? tagViewMinWidth + tagPadding : 0
        }

        let availableTextWidth: CGFloat = (shouldShowTitleAndSubtitle ||
                                           shouldShowTitleBottomAttach) ? (size.width - leadingOffset - trailingOffset - (shouldShowActionButton ? actionTipWidth + tagPadding * 2 : 0)) : 0

        // Configure what and how to show
        
        titleLabel.text = title
        if shouldShowActionButton, let versionName = uiDelegate?.titleBarShowTitle() {
            titleLabel.text = versionName
        }
        subtitleLabel.text = subtitle
        if let attachInfo = titleBottomAttachInfo {
            titleBottomAttachView.config(info: attachInfo)
        }
        let attachNeedWidth = titleBottomAttachView.calculateWidth(by: titleBottomAttachInfo?.title ?? "")
        let showingLabel: UILabel = displayType == .subtitle ? subtitleLabel : titleLabel
        let textNeededWidth = ceil(max(showingLabel.intrinsicContentSize.width, attachNeedWidth))
        let textNeededHeight = showingLabel.intrinsicContentSize.height
        let actionBtnWidth = shouldShowActionButton ? (actionTipWidth + 2 * tagPadding) : 0
        var totalWidth: CGFloat = leadingOffset + textNeededWidth + trailingOffset + actionBtnWidth
        if totalWidth > size.width && displayType != .fullCustomized {
            let benchmarkLabel = UILabel()
            benchmarkLabel.text = "三个字…"
            benchmarkLabel.font = showingLabel.font
            let benchmarkWidth = benchmarkLabel.intrinsicContentSize.width
            let cannotShowEnoughTitleText = availableTextWidth < benchmarkWidth
            if overridingCustomViewSizeProvider != nil && cannotShowEnoughTitleText {
                shouldShowTitleAndSubtitle = true
            }
            if cannotShowEnoughTitleText && shouldShowTitleAndSubtitle {
                // When the navigation bar can't provide enough width for me to show text more than
                // 3 full width characters and an ellipse, I will hide all my subviews.
                if forceLayout {
                    accessoryViews.forEach {
                        $0.isHidden = true
                        $0.frame = .zero
                    }
                    showingLabel.isHidden = true
                    showingLabel.frame = .zero
                    titleBottomAttachView.isHidden = true
                    titleBottomAttachView.frame = .zero
                    tagViews.forEach { tagView, _ in
                        tagView.isHidden = true
                        tagView.frame = .zero
                    }
                }
                return .zero
            }
        }
        let textUsingWidth = ceil(min(availableTextWidth, textNeededWidth))
        totalWidth = leadingOffset + textUsingWidth + trailingOffset + actionBtnWidth

        let attachUsingWidth = ceil(min(availableTextWidth, attachNeedWidth))

        if displayType == .subtitle {
            titleLabel.isHidden = true
            titleLabel.frame = .zero
            actionTipView.isHidden = true
            subtitleLabel.isHidden = !shouldShowTitleAndSubtitle
        } else {
            titleLabel.isHidden = !(shouldShowTitleAndSubtitle || shouldShowActionButton)
            actionTipView.isHidden = !shouldShowActionButton
            subtitleLabel.isHidden = true
            subtitleLabel.frame = .zero
        }

        if forceLayout && displayType != .fullCustomized {
            var tagMinX: CGFloat
            showingLabel.isHidden = !shouldShowTitleAndSubtitle
            titleBottomAttachView.isHidden = !shouldShowTitleBottomAttach
            
            switch (shouldShowTitleAndSubtitle, shouldShowTitleBottomAttach) {
            case (true, true):
                let titleAndAttachHeight = textNeededHeight + 2 + titleBottomAttachHeight
                showingLabel.frame = CGRect(x: leadingOffset,
                                            y: (size.height - titleAndAttachHeight) / 2,
                                            width: textUsingWidth,
                                            height: textNeededHeight)
                titleBottomAttachView.frame = CGRect(x: leadingOffset,
                                                     y: showingLabel.frame.maxY + 2,
                                                     width: attachUsingWidth,
                                                     height: titleBottomAttachHeight)
                actionTipView.frame = CGRect(x: showingLabel.frame.maxX + tagPadding,
                                            y: 0,
                                            width: actionTipWidth,
                                            height: size.height)
                titleTouchControl.frame = CGRect(x: showingLabel.frame.minX,
                                                 y: 0,
                                                 width: actionTipView.frame.maxX,
                                                 height: size.height)
                tagMinX = showingLabel.frame.maxX + tagPadding + (shouldShowActionButton ? tagPadding + actionTipWidth : 0)
            case (true, false):
                showingLabel.frame = CGRect(x: leadingOffset,
                                            y: (size.height - textNeededHeight) / 2,
                                            width: textUsingWidth,
                                            height: textNeededHeight)
                titleBottomAttachView.frame = .zero
                actionTipView.frame = CGRect(x: showingLabel.frame.maxX + tagPadding,
                                            y: 0,
                                            width: actionTipWidth,
                                            height: size.height)
                titleTouchControl.frame = CGRect(x: showingLabel.frame.minX,
                                                 y: 0,
                                                 width: actionTipView.frame.maxX,
                                                 height: size.height)
                tagMinX = showingLabel.frame.maxX + tagPadding + (shouldShowActionButton ? tagPadding + actionTipWidth : 0)
            case (false, true):
                showingLabel.frame = .zero
                titleBottomAttachView.frame = CGRect(x: leadingOffset,
                                                     y: (size.height - titleBottomAttachHeight) / 2,
                                                     width: attachUsingWidth,
                                                     height: titleBottomAttachHeight)
                actionTipView.frame = CGRect(x: titleBottomAttachView.frame.maxX + tagPadding,
                                            y: 0,
                                            width: actionTipWidth,
                                            height: size.height)
                titleTouchControl.frame = CGRect(x: showingLabel.frame.minX,
                                                 y: 0,
                                                 width: actionTipView.frame.maxX,
                                                 height: size.height)
                tagMinX = titleBottomAttachView.frame.maxX + tagPadding + (shouldShowActionButton ? tagPadding + actionTipWidth : 0)
            case (false, false):
                titleBottomAttachView.frame = .zero
                showingLabel.frame = .zero
                actionTipView.frame = CGRect(x: leadingOffset + tagPadding,
                                            y: 0,
                                            width: actionTipWidth,
                                            height: size.height)
                titleTouchControl.frame = CGRect(x: showingLabel.frame.minX,
                                                 y: 0,
                                                 width: actionTipView.frame.maxX,
                                                 height: size.height)
                tagMinX = leadingOffset + (shouldShowActionButton ? tagPadding + actionTipWidth : 0)
            }
            
            var tagTotalWidth = trailOffsetX - leadingOffsetX - totalWidth - 10
            for (tagView, shouldShow) in tagViews {
                tagView.isHidden = !shouldShow
                if shouldShow {
                    let intrinsicSize = tagView.intrinsicContentSize
                    var width: CGFloat = tagViewMinWidth
                    if tagTotalWidth > 0, intrinsicSize.width > tagViewMinWidth {
                        width = intrinsicSize.width - tagViewMinWidth > tagTotalWidth ? tagViewMinWidth + tagTotalWidth : intrinsicSize.width
                        tagTotalWidth -= width + tagPadding
                    }
                    tagView.frame = CGRect(x: tagMinX,
                                           y: (size.height - intrinsicSize.height) / 2.0,
                                           width: width,
                                           height: intrinsicSize.height)
                    tagMinX += width + tagPadding
                } else {
                    tagView.frame = .zero
                }
            }
        }
        
        if shouldShowActionButton {
            uiDelegate?.configureActionButton(actionTipView)
        }
        
        if let overridedSize = overridingCustomViewSizeProvider?(size) {
            return overridedSize
        }
        if displayType == .fullCustomized {
            // customView 完全填充
            return size
        }
        return CGSize(width: totalWidth, height: size.height)
    }

    private func configureIcon(_ avatarImage: DocsAvatarImageView, with icon: IconSelectionInfo?) {
        self.uiDelegate?.configureAvatarImageView(avatarImage, with: icon)
    }
}
