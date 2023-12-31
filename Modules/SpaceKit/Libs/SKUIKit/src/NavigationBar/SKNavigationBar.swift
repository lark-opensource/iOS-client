//
//  SKNavigationBar.swift
//  SKNavigationBar
//
//  Created by 边俊林 on 2019/11/21.
//
// swiftlint:disable file_length

import UIKit
import SKFoundation
import SKResource
import SnapKit
import UniverseDesignColor
import UniverseDesignBadge

/**
 The standard navigation bar component used in SpaceKit iOS.

 For more information, see the articles below:

 * [SKNavigationBar WiKi archive](https://bytedance.feishu.cn/drive/folder/fldcnXRmSqKdcGhkZmh4nB7bTSx)
 * [Documentation-CN](https://bytedance.feishu.cn/docs/doccnegmq1DegcIRqfEGvBX2MGg)
 */
open class SKNavigationBar: UIView {

    // MARK: Read-Write Interfaces

    public var navigationMode: SKNavigationBar.NavigationMode {
        didSet {
            leadingBarButtonItems = _filterBarButtonItems(currentItems: leadingBarButtonItems)
            temporaryTrailingBarButtonItems = _filterBarButtonItems(currentItems: temporaryTrailingBarButtonItems)
            trailingBarButtonItems = _filterBarButtonItems(currentItems: trailingBarButtonItems)
        }
    }

    private var customBackgroundColor: UIColor?

    public var leadingBarButtonItem: SKBarButtonItem? {
        didSet {
            if let leadingBarButtonItem = leadingBarButtonItem {
                leadingBarButtonItems = [leadingBarButtonItem]
            } else {
                leadingBarButtonItems = []
            }
        }
    }

    public var leadingBarButtonItems: [SKBarButtonItem] = [] {
        didSet {
            leadingBarButtonItems = _filterBarButtonItems(currentItems: leadingBarButtonItems)
            leadingButtonBar.items = leadingBarButtonItems
            _didModifyLeadingItems(old: oldValue, new: leadingBarButtonItems)
            setNeedsLayout()
        }
    }

    public var title: String? {
        didSet {
            titleInfo = NavigationTitleInfo(title: title)
        }
    }

    public var titleInfo: NavigationTitleInfo? {
        didSet {
            _reloadTitleInfo()
        }
    }

    /// 根据前端传来权限判断能否编辑标题
    public var titleCanRename: Bool? {
        didSet {
            if let canRename = titleCanRename, let shouldRename = titleShouldRename {
                if canRename && shouldRename {
                    addMaskUIView()
                }
            }
        }
    }

    /// 根据文档类型以及是否是ipad判断能否编辑标题（仅限ipad sheet）
    public var titleShouldRename: Bool? {
        didSet {
            if let canRename = titleCanRename, let shouldRename = titleShouldRename {
                if canRename && shouldRename {
                    addMaskUIView()
                }
            }
        }
    }

    var shouldBeginEditingTitleAfterKeyboardDidHide: Bool = false
    /// 判断是否进入了编辑态
    var isEditingTitle: Bool = false

    /// 在某些状态下会临时显示的 item，目前用在 docs 的编辑态里
    public var temporaryTrailingBarButtonItem: SKBarButtonItem? {
        didSet {
            if let temporaryTrailingBarButtonItem = temporaryTrailingBarButtonItem {
                temporaryTrailingBarButtonItems = [temporaryTrailingBarButtonItem]
            } else {
                temporaryTrailingBarButtonItems = []
            }
        }
    }

    public var temporaryTrailingBarButtonItems: [SKBarButtonItem] = [] {
        didSet {
            temporaryTrailingBarButtonItems = _filterBarButtonItems(currentItems: temporaryTrailingBarButtonItems)
            temporaryTrailingButtonBar.items = temporaryTrailingBarButtonItems
            _didModifyTrailingItems(old: oldValue, new: temporaryTrailingBarButtonItems)
            setNeedsLayout()
        }
    }

    public var trailingBarButtonItem: SKBarButtonItem? {
        didSet {
            if let trailingBarButtonItem = trailingBarButtonItem {
                trailingBarButtonItems = [trailingBarButtonItem]
            } else {
                trailingBarButtonItems = []
            }
        }
    }

    public var trailingBarButtonItems: [SKBarButtonItem] = [] {
        didSet {
            trailingBarButtonItems = _filterBarButtonItems(currentItems: trailingBarButtonItems)
            trailingButtonBar.items = trailingBarButtonItems
            _didModifyTrailingItems(old: oldValue, new: trailingBarButtonItems)
            setNeedsLayout()
        }
    }

    /// Attributes for customizing navigation bar layout
    public var layoutAttributes: LayoutAttributes {
        didSet { setNeedsLayout() }
    }

    /// Affects the height of the bar
    public var sizeType: SKNavigationBar.SizeType = .secondary {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }
    
    /// 禁用自定义背景色
    public var disableCustomBackgroundColor: Bool = false

    public override var isHidden: Bool {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    // MARK: Read-Only Interfaces

    public var leadingButtons: [SKBarButton] {
        leadingButtonBar.itemViews.compactMap { return $0 as? SKBarButton }
    }

    public var titleView: SKNavigationBarCustomTitleView

    public var titleLabel: UILabel { titleView.titleLabel }

    public var subtitleLabel: UILabel { titleView.subtitleLabel }

    public var trailingButtons: [SKBarButton] {
        trailingButtonBar.itemViews.compactMap { return $0 as? SKBarButton }
    }

    public var intrinsicHeight: CGFloat {
        intrinsicContentSize.height
    }

    public override var intrinsicContentSize: CGSize {
        let height: CGFloat
        if isHidden {
            height = 0
        } else {
            height = estimatedHeight
        }
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }

    public var estimatedHeight: CGFloat {
        switch sizeType {
        case .secondary:
            return 44
        case .formSheet:
            return 56
        case .primary:
            return 60
        }
    }

    // MARK: Title Renaming Interfaces

    var titleEditorView: TitleEditorView

    var maskUIView: MaskUIView

    public weak var renameDelegate: SheetRenameRequest?

    var keyboard: Keyboard?

    // MARK: Private Properties

    // NOTICE: Warn of using.
    // Opening these interfaces provides some extensibility and dynamism,
    // and we want to make it easy for users to use and provide more customizable capabilities,
    // but we don't want them to be abused. Make sure you really need it before using these
    // interfaces, and don't forget to code review.

    public internal(set) var leadingButtonBar: SKButtonBar

    public internal(set) var trailingButtonBar: SKButtonBar

    public internal(set) var temporaryTrailingButtonBar: SKButtonBar

    var badgeConfigsForTrailingItems: [SKNavigationBar.ButtonIdentifier: UDBadgeConfig] = [:]

    var bottomSeparator: UIView


    // MARK: - Life Cycle

    public init(frame: CGRect, mode: NavigationMode, layoutAttribute: LayoutAttributes) {
        self.navigationMode = mode
        self.layoutAttributes = layoutAttribute
        self.leadingButtonBar = SKButtonBar(arrangementDirection: .leading, layoutAttributes: .restricted)
        self.trailingButtonBar = SKButtonBar(arrangementDirection: .trailing, layoutAttributes: .restricted)
        self.temporaryTrailingButtonBar = SKButtonBar(arrangementDirection: .trailing, layoutAttributes: .restricted)
        self.titleView = SKNavigationBarTitle()
        self.bottomSeparator = UIView()
        self.titleEditorView = TitleEditorView()
        self.maskUIView = MaskUIView()
        self.keyboard = Keyboard(listenTo: [titleEditorView], trigger: "sheetRename")
        super.init(frame: frame)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
        titleEditorView.titleDelegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(editorViewDidChange), name: UITextField.textDidChangeNotification, object: titleEditorView)
        _setupSubviews()
    }

    convenience public override init(frame: CGRect = .zero) {
        self.init(frame: frame, mode: .open, layoutAttribute: .default)
    }

    required public init?(coder: NSCoder) {
        self.navigationMode = .open
        self.layoutAttributes = .default
        self.leadingButtonBar = SKButtonBar(arrangementDirection: .leading, layoutAttributes: .restricted)
        self.trailingButtonBar = SKButtonBar(arrangementDirection: .trailing, layoutAttributes: .restricted)
        self.temporaryTrailingButtonBar = SKButtonBar(arrangementDirection: .trailing, layoutAttributes: .restricted)
        self.titleView = SKNavigationBarTitle()
        self.bottomSeparator = UIView()
        self.titleEditorView = TitleEditorView()
        self.maskUIView = MaskUIView()
        self.keyboard = Keyboard(listenTo: [titleEditorView], trigger: "sheetRename")
        super.init(coder: coder)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
        titleEditorView.titleDelegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(editorViewDidChange), name: UITextField.textDidChangeNotification, object: titleEditorView)
        _setupSubviews()
    }

    public override func layoutSubviews() {
        DocsLogger.info("========================== sk navigation bar begin layout ==========================")
        UIView.performWithoutAnimation {
            super.layoutSubviews()
            _setupBar()
            _setupTitle(after: _setupButtons())
            _addBadgesFor(trailingButtonBar.itemViews, accordingTo: badgeConfigsForTrailingItems)
        }
        DocsLogger.info("========================== sk navigation bar end layout ==========================")
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        let height = min(max(size.height, layoutAttributes.minimumHeight), layoutAttributes.maximumHeight)
        return CGSize(width: size.width, height: height)
    }

    // MARK: Interface

    /// 设置导航栏各个部位的颜色
    /// - Parameters:
    ///   - backgroundColor: bar 整体的背景色，保持当前不变请显式传 nil，不传则恢复默认值 bgBody，需要透明请传 .clear
    ///   - itemForegroundColorMapping: bar item 的文字/图标颜色，保持当前不变请显式传 nil，不传则恢复默认配置，要变则所有 item 一起变
    ///   （使用了 customView 的 SKBarButtonItem 不会跟着变化，需要业务方自行处理）
    ///   - separatorColor: 导航栏底部分割线(若有)的颜色，保持当前不变请显式传 nil，不传则恢复默认值 N300，如果本来就没有显示分割线，则设置无效
    public func customizeBarAppearance(backgroundColor: UIColor? = UDColor.bgBody,
                                       itemForegroundColorMapping: [UIControl.State: UIColor]? = SKBarButton.defaultIconColorMapping,
                                       separatorColor: UIColor? = UDColor.lineDividerDefault,
                                       iconHeight: CGFloat? = nil,
                                       cornerRadius: CGFloat? = nil) {
        if let backgroundColor = backgroundColor {
            customBackgroundColor = backgroundColor
        } else {
            customBackgroundColor = self.backgroundColor
        }
        if let itemForegroundColors = itemForegroundColorMapping {
            leadingButtonBar.layoutAttributes.itemForegroundColorMapping = itemForegroundColors
            temporaryTrailingButtonBar.layoutAttributes.itemForegroundColorMapping = itemForegroundColors
            trailingButtonBar.layoutAttributes.itemForegroundColorMapping = itemForegroundColors
        }
        
        if let iconHeight = iconHeight {
            leadingButtonBar.layoutAttributes.iconHeight = iconHeight
            temporaryTrailingButtonBar.layoutAttributes.iconHeight = iconHeight
            trailingButtonBar.layoutAttributes.iconHeight = iconHeight
        }
        
        if let cornerRadius = cornerRadius {
            leadingButtonBar.layoutAttributes.cornerRadius = cornerRadius
            temporaryTrailingButtonBar.layoutAttributes.cornerRadius = cornerRadius
            trailingButtonBar.layoutAttributes.cornerRadius = cornerRadius
        }
        
        if let separatorColor = separatorColor {
            layoutAttributes.bottomSeparatorColor = separatorColor
        }
    }

    /// 移除所有按钮，使用时请注意补充返回按钮或者退出按钮
    public func removeAllItems() {
        self.leadingBarButtonItems = []
        self.trailingBarButtonItems = []
        self.temporaryTrailingBarButtonItems = []
        self.title = nil
    }
    
    public func removeAllItemsExceptBack() {
        self.leadingBarButtonItems.removeAll(where: { $0.id != .back && $0.id != .close })
        self.trailingBarButtonItems = []
        self.temporaryTrailingBarButtonItems = []
        self.title = nil
    }

    deinit {
        keyboard?.stop()
        keyboard = nil
        maskUIView.removeFromSuperview()
    }

}

// MARK: - Private Methods

extension SKNavigationBar {

    private func _setupSubviews() {
        addSubview(leadingButtonBar)
        addSubview(trailingButtonBar)
        addSubview(temporaryTrailingButtonBar)
        addSubview(titleView)
        addSubview(bottomSeparator)

        keyboard?.on(events: [.willHide]) { [weak self] opt in
            switch opt.event {
            case .willHide:
                self?.handleKeyboardWillHide()
            default:
                ()
            }
        }
    }

    private func _setupBar() {
        backgroundColor = customBackgroundColor ?? UDColor.bgBody

        // Apply attributes first to make sure UI state is correct
        _applyLayoutAttributes()

        if layoutAttributes.showsBottomSeparator {
            bottomSeparator.frame = CGRect(x: bounds.minX, y: bounds.maxY - 1, width: bounds.width, height: 1)
            bottomSeparator.backgroundColor = layoutAttributes.bottomSeparatorColor
        } else {
            bottomSeparator.frame = .zero
            bottomSeparator.backgroundColor = .clear
        }
    }

    private func _setupButtons() -> (leadingFrame: CGRect, temporaryTrailingFrame: CGRect, trailingFrame: CGRect) {
        let horizontalPadding = layoutAttributes.barHorizontalInset // Bar's leading and trailing padding
        let titleHorizontalOffset = layoutAttributes.titleHorizontalOffset // Space that outsets titleView horizontally

        // Layout Button Bars

        DocsLogger.debug("========== sk navigation bar begin checking conflict 1st round ==========")

        DocsLogger.debug("sk navigation bar width: \(bounds.width)")
        // 1. Calculate Button Bars' needed sizes
        var leadingButtonBarSize = leadingButtonBar.sizeThatFits(bounds.size)
        DocsLogger.debug("sk navigation bar leadingButtonBar width: \(leadingButtonBarSize.width), count: \(leadingBarButtonItems.count)")
        var trailingButtonBarSize = trailingButtonBar.sizeThatFits(bounds.size)
        DocsLogger.debug("sk navigation bar trailingButtonBar width: \(trailingButtonBarSize.width), count: \(trailingBarButtonItems.count)")
        var temporaryTrailingButtonBarSize = temporaryTrailingButtonBar.sizeThatFits(bounds.size)
        DocsLogger.debug("sk navigation bar temporaryTrailingButtonBar width: \(temporaryTrailingButtonBarSize.width)")

        // 2. Check if it's needed to reduce trailing items, given that leading items' should not be trimmed
        var requiredLeadingWidth: CGFloat = safeAreaInsets.left + horizontalPadding + leadingButtonBarSize.width
        // Depending on the existence of temporaryTrailingBarButtonItems
        if !temporaryTrailingBarButtonItems.isEmpty {
            // |...-leadingButtonBar-(titleHorizontalOffset)-temporaryTrailingButtonBar-(titleHorizontalOffset)-trailingButtonBar-...|
            requiredLeadingWidth += titleHorizontalOffset + temporaryTrailingButtonBarSize.width + titleHorizontalOffset
        } else {
            // |...-leadingButtonBar-(interButtonSpacing)-trailingButtonBar-...|
            requiredLeadingWidth += layoutAttributes.interButtonSpacing
        }
        DocsLogger.debug("sk navigation bar required leading width: \(requiredLeadingWidth)")

        // 3. See if there is layout conflict.
        var hasLayoutConflict = requiredLeadingWidth + trailingButtonBarSize.width + horizontalPadding + safeAreaInsets.right > bounds.width
        if hasLayoutConflict {
            DocsLogger.info("sk navigation bar will go through layout conflict")
            // Trim trailing items as much as possible.
            // Calculate how many trailing items can be displayed in limited space
            // where titleView occupies no space at all and leading items are not trimmed whatsoever
            let trailingItemsLeftoverSpace: CGFloat = bounds.width - safeAreaInsets.right - horizontalPadding - requiredLeadingWidth
            let trailingItemsCapacity = trailingButtonBar.maxAmountOfItemsForWidth(trailingItemsLeftoverSpace)
            DocsLogger.debug("sk navigation bar trailingItemsLeftoverSpace: \(trailingItemsLeftoverSpace), capacity: \(trailingItemsCapacity)")

            var deletedTrailingItems = [SKBarButtonItem]()
            var deletedTrailingItemsDescription = ""
            var trimmedTrailingItems = [SKBarButtonItem]()
            for item in trailingBarButtonItems {
                if item.id.priority < .required {
                    deletedTrailingItems.append(item)
                    deletedTrailingItemsDescription = "\(deletedTrailingItemsDescription) \(item.id)"
                } else {
                    trimmedTrailingItems.append(item)
                }
            }
            if !deletedTrailingItems.isEmpty {
                DocsLogger.info("there is layout conflict in sk navigation bar, deleted trailing items: \(deletedTrailingItemsDescription)")
                trailingButtonBar.itemViews.forEach {
                    $0.removeFromSuperview()
                }
                trailingButtonBar.itemViews = trailingButtonBar.viewsFromItems(trimmedTrailingItems)
            }
        }
        DocsLogger.debug("========================== sk navigation bar end checking conflict 1st round==========================")

        // 4. After trimming trailing side's items, recalculate button bar sizes.

        DocsLogger.debug("========== sk navigation bar begin checking conflict 2nd round ==========")

        leadingButtonBarSize = leadingButtonBar.sizeThatFits(bounds.size)
        DocsLogger.debug("sk navigation bar leadingButtonBar width: \(leadingButtonBarSize.width), count: \(leadingBarButtonItems.count)")
        trailingButtonBarSize = trailingButtonBar.sizeThatFits(bounds.size)
        DocsLogger.debug("sk navigation bar trailingButtonBar width: \(trailingButtonBarSize.width), count: \(trailingBarButtonItems.count)")
        temporaryTrailingButtonBarSize = temporaryTrailingButtonBar.sizeThatFits(bounds.size)
        DocsLogger.debug("sk navigation bar temporaryTrailingButtonBar width: \(temporaryTrailingButtonBarSize.width)")

        // 5. Check out if it's needed to reduce leading items, given that trailing items cannot be trimmed anymore.
        requiredLeadingWidth = safeAreaInsets.left + horizontalPadding + leadingButtonBarSize.width
        // Depending on the existence of temporaryTrailingBarButtonItems
        if !temporaryTrailingBarButtonItems.isEmpty {
            // |...-leadingButtonBar-(titleHorizontalOffset)-temporaryTrailingButtonBar-(titleHorizontalOffset)-trailingButtonBar-...|
            requiredLeadingWidth += titleHorizontalOffset + temporaryTrailingButtonBarSize.width + titleHorizontalOffset
        } else {
            // |...-leadingButtonBar-(interButtonSpacing)-trailingButtonBar-...|
            requiredLeadingWidth += layoutAttributes.interButtonSpacing
        }
        DocsLogger.debug("sk navigation bar required leading width: \(requiredLeadingWidth)")

        hasLayoutConflict = requiredLeadingWidth + trailingButtonBarSize.width + horizontalPadding + safeAreaInsets.right > bounds.width
        if hasLayoutConflict {
            DocsLogger.info("sk navigation bar will still go through layout conflict")
            // We cannot reduce trailing items anymore. So we resort to leading ones.
            var deletedLeadingItems = [SKBarButtonItem]()
            var deletedLeadingItemsDescription = ""
            var trimmedLeadingItems = [SKBarButtonItem]()
            for item in leadingBarButtonItems {
                if item.id.priority < .required {
                    deletedLeadingItems.append(item)
                    deletedLeadingItemsDescription = "\(deletedLeadingItemsDescription) \(item.id)"
                } else {
                    trimmedLeadingItems.append(item)
                }
            }
            if deletedLeadingItems.isEmpty {
                DocsLogger.error("there is layout conlict in sk navigation bar, cannot delete both sides' bar items any more, please check why!")
            } else {
                DocsLogger.info("there is layout conflict in sk navigation bar, deleted leading items: \(deletedLeadingItemsDescription)")
                leadingButtonBar.itemViews.forEach {
                    $0.removeFromSuperview()
                }
                leadingButtonBar.itemViews = leadingButtonBar.viewsFromItems(trimmedLeadingItems)
            }
        }
        DocsLogger.debug("========================== sk navigation bar end checking conflict 2nd round ==========================")

        leadingButtonBarSize = leadingButtonBar.sizeThatFits(bounds.size)
        DocsLogger.debug("sk navigation bar leadingButtonBar width: \(leadingButtonBarSize.width), count: \(leadingBarButtonItems.count)")
        trailingButtonBarSize = trailingButtonBar.sizeThatFits(bounds.size)
        DocsLogger.debug("sk navigation bar trailingButtonBar width: \(trailingButtonBarSize.width), count: \(trailingBarButtonItems.count)")
        temporaryTrailingButtonBarSize = temporaryTrailingButtonBar.sizeThatFits(bounds.size)
        DocsLogger.debug("sk navigation bar temporaryTrailingButtonBar width: \(temporaryTrailingButtonBarSize.width)")

        let leadingButtonBarFrame = CGRect(x: safeAreaInsets.left + horizontalPadding,
                                           y: (bounds.height - leadingButtonBarSize.height) / 2,
                                           width: leadingButtonBarSize.width,
                                           height: leadingButtonBarSize.height)
        leadingButtonBar.frame = leadingButtonBarFrame

        let trailingButtonBarFrame = CGRect(x: bounds.width - safeAreaInsets.right - horizontalPadding - trailingButtonBarSize.width,
                                            y: (bounds.height - trailingButtonBarSize.height) / 2,
                                            width: trailingButtonBarSize.width,
                                            height: trailingButtonBarSize.height)
        trailingButtonBar.frame = trailingButtonBarFrame

        // |...-temporaryTrailingButtonBar-(titleHorizontalOffset)-trailingButtonBar-...|
        let temporaryTrailingButtonBarFrame = CGRect(x: trailingButtonBarFrame.minX - titleHorizontalOffset - temporaryTrailingButtonBarSize.width,
                                                     y: bounds.minY,
                                                     width: temporaryTrailingButtonBarSize.width,
                                                     height: temporaryTrailingButtonBarSize.height)
        if !temporaryTrailingBarButtonItems.isEmpty {
            temporaryTrailingButtonBar.frame = temporaryTrailingButtonBarFrame
        } else {
            temporaryTrailingButtonBar.frame = CGRect(origin: trailingButtonBar.frame.origin, size: .zero)
        }

        return (leadingButtonBarFrame, temporaryTrailingButtonBarFrame, trailingButtonBarFrame)
    }

    private func _setupTitle(after buttonFrames: (CGRect, CGRect, CGRect)) {
        let (leadingButtonBarFrame, temporaryTrailingButtonBarFrame, trailingButtonBarFrame) = buttonFrames
        // Prelayout titleView & titleLabel
        let titleHorizontalOffset = layoutAttributes.titleHorizontalOffset

        var titleContainerFrame: CGRect
        var titleLeadingOffset: CGFloat = 0
        var trailOffset: CGFloat = 0
        if layoutAttributes.titleHorizontalAlignment == .center {
            titleContainerFrame = bounds.insetBy(dx: max(leadingButtonBar.frame.maxX,
                                                         bounds.maxX - min(trailingButtonBar.frame.minX, temporaryTrailingButtonBar.frame.minX))
                                                 + layoutAttributes.editorHorizontalPadding
                                                 + layoutAttributes.textFieldSidePadding,
                                                 dy: 0)
            titleLeadingOffset = titleContainerFrame.minX
            trailOffset = titleContainerFrame.maxX
        } else {
            switch leadingButtonBar.itemViews.count {
            case 0: titleLeadingOffset = safeAreaInsets.left + 16
            case 1: titleLeadingOffset = leadingButtonBarFrame.maxX + layoutAttributes.titleHorizontalOffsetWhenLeft1Button
            default: titleLeadingOffset = leadingButtonBarFrame.maxX + titleHorizontalOffset
            }
            titleContainerFrame = CGRect.zero
            titleContainerFrame.origin.x = titleLeadingOffset
            if !temporaryTrailingBarButtonItems.isEmpty {
                // |...-leadingButtonBar-(titleHorizontalOffset)-titleView-(titleHorizontalOffset)-temporaryTrailingButtonBar-...|
                titleContainerFrame.size.width = max(0, temporaryTrailingButtonBarFrame.minX - titleHorizontalOffset - titleContainerFrame.origin.x)
            } else {
                // |...-leadingButtonBar-(titleHorizontalOffset)-titleView-(titleHorizontalOffset)-trailingButtonBar-...|
                titleContainerFrame.size.width = max(0, trailingButtonBarFrame.minX - titleHorizontalOffset - titleContainerFrame.origin.x)
            }
            titleContainerFrame.size.height = bounds.height
            trailOffset = trailingButtonBarFrame.minX
        }

        // Layout titleLabel
        let titleNeededSize = _titleSize(boundingRectWithSize: bounds.size, leadingOffset: titleLeadingOffset, trailOffset: trailOffset)
        let verticallyAlignedTitleContainerFrame = _titleVerticallyAlignedFrame(containerFrame: titleContainerFrame,
                                                                                titleNeededSize: titleNeededSize,
                                                                                alignment: layoutAttributes.titleVerticalAlignment)
        var targetTitleFrame = _titleHorizontallyAlignedFrame(containerFrame: verticallyAlignedTitleContainerFrame,
                                                              titleNeededWidth: titleNeededSize.width,
                                                              alignment: layoutAttributes.titleHorizontalAlignment)
        if !(titleView is SKNavigationBarTitle) {
            targetTitleFrame.origin.y = 0
            targetTitleFrame.size.height = min(max(bounds.height, layoutAttributes.minimumHeight),
                                               layoutAttributes.maximumHeight)
        }
        titleView.frame = targetTitleFrame
    }

//    @inline(__always)
//    private func _mainSync(_ callback: (() -> Void)) {
//        if Thread.isMainThread {
//            callback()
//        } else {
//            DispatchQueue.main.sync {
//                callback()
//            }
//        }
//    }

    private func _reloadTitleInfo() {
        let title = titleInfo?.title
        if (title == nil || title?.utf16.count == 0),
            SKDisplay.pad,
            layoutAttributes.titleHorizontalAlignment == .center,
            titleView.needDisPlayTag,
            titleInfo?.untitledName != nil {
            titleView.title = titleInfo?.untitledName
        } else {
            titleView.title = title
        }
        titleView.subtitle = titleInfo?.subtitle
        titleView.customView = titleInfo?.customView
        titleView.displayType = titleInfo?.displayType ?? .title
        setNeedsLayout()
    }

//    private func _reloadTitleView(previousTitleView: UIView?) {
//        if previousTitleView != titleView {
//            previousTitleView?.removeFromSuperview()
//        }
//        addSubview(titleView)
//        setNeedsLayout()
//    }

    /** The attributes applier of child components layout, your should call this before calculate frame. */
    private func _applyLayoutAttributes() {
        titleLabel.font = layoutAttributes.titleFont
        titleLabel.textColor = layoutAttributes.titleTextColor
        subtitleLabel.font = layoutAttributes.subTitleFont
        subtitleLabel.textColor = layoutAttributes.subTitleTextColor

        leadingButtonBar.itemSpacing = layoutAttributes.interButtonSpacing
        trailingButtonBar.itemSpacing = layoutAttributes.interButtonSpacing
        temporaryTrailingButtonBar.itemSpacing = layoutAttributes.interButtonSpacing
        
        if let buttonHitTestInset = layoutAttributes.buttonHitTestInset {
            leadingButtonBar.buttonHitTestInset = buttonHitTestInset
            trailingButtonBar.buttonHitTestInset = buttonHitTestInset
            temporaryTrailingButtonBar.buttonHitTestInset = buttonHitTestInset
        }
    }

    private func _titleSize(boundingRectWithSize size: CGSize, leadingOffset: CGFloat, trailOffset: CGFloat) -> CGSize {
        let targetSize = titleView.layoutTitle(size: size, leadingOffset: leadingOffset, trailOffset: trailOffset)
        return CGSize(width: ceil(targetSize.width),
                      height: ceil(targetSize.height))
    }

    private func _titleVerticallyAlignedFrame(containerFrame: CGRect,
                                              titleNeededSize: CGSize,
                                              alignment: UIControl.ContentVerticalAlignment) -> CGRect {
        switch alignment {
        case .fill:
            return containerFrame
        case .top:
            let height = min(containerFrame.height, layoutAttributes.maximumHeight)
            let targetMinY = max(floor((height - titleNeededSize.height) / 2), 0)
            return CGRect(x: containerFrame.minX,
                          y: targetMinY,
                          width: containerFrame.width,
                          height: containerFrame.height)
        case .center:
            let targetMinY = floor((containerFrame.height - titleNeededSize.height) / 2) + containerFrame.minY
            return CGRect(x: containerFrame.minX,
                          y: targetMinY,
                          width: containerFrame.width,
                          height: titleNeededSize.height)
        case .bottom:
            return CGRect(x: containerFrame.minX,
                          y: containerFrame.maxY - titleNeededSize.height,
                          width: containerFrame.width,
                          height: containerFrame.height)
        @unknown default:
            return .zero
        }
    }

    private func _titleHorizontallyAlignedFrame(containerFrame: CGRect,
                                                titleNeededWidth: CGFloat,
                                                alignment: UIControl.ContentHorizontalAlignment) -> CGRect {
        switch alignment {
        case .fill, .leading:
            return containerFrame
        case .center:
            let halfTitleNeededWidth: CGFloat = titleNeededWidth / 2
            if containerFrame.width >= titleNeededWidth {
                let trailingEmptySpace = containerFrame.maxX - bounds.midX
                if trailingEmptySpace >= halfTitleNeededWidth {
                    return CGRect(x: bounds.midX - halfTitleNeededWidth,
                                  y: containerFrame.minY,
                                  width: titleNeededWidth,
                                  height: containerFrame.height)
                } else {
                    return CGRect(x: containerFrame.maxX - titleNeededWidth,
                                  y: containerFrame.minY,
                                  width: titleNeededWidth,
                                  height: containerFrame.height)
                }
            } else {
                return containerFrame
            }
        default:
            return .zero
        }
    }

    private func _addBadgesFor(_ views: [UIView], accordingTo badges: [SKNavigationBar.ButtonIdentifier: UDBadgeConfig]) {
        badges.forEach { (badge) in
            let labelOfButtonOfInterest = badge.key
            let udBadgeConfig = badge.value
            let badgeView = UDBadge(config: udBadgeConfig)
            for view in views {
                view.badge?.removeFromSuperview()
                if let view = view as? SKBarButton, view.item?.id == labelOfButtonOfInterest {
                    if let imageView = view.imageView {
                        imageView.addSubview(badgeView)
                        imageView.badge = badgeView
                        badgeView.snp.makeConstraints { (make) in
                            make.centerX.equalTo(imageView.snp.trailing)
                            make.centerY.equalTo(imageView.snp.top)
                        }
                        imageView.clipsToBounds = false
                        continue
                    } else if let titleLabel = view.titleLabel {
                        titleLabel.addSubview(badgeView)
                        titleLabel.badge = badgeView
                        badgeView.snp.makeConstraints { (make) in
                        make.centerX.equalTo(titleLabel.snp.trailing)
                        make.centerY.equalTo(titleLabel.snp.top)
                        }
                        titleLabel.clipsToBounds = false
                        continue
                    }
                } else if let item = view.accessibilityElements?.first as? SKBarButtonItem, item.id == labelOfButtonOfInterest {
                    view.addSubview(badgeView)
                    view.badge = badgeView
                    badgeView.snp.makeConstraints { (make) in
                        make.centerX.equalTo(view.snp.trailing)
                        make.centerY.equalTo(view.snp.top)
                    }
                }
            }
        }
    }

    private func _filterBarButtonItems(currentItems: [SKBarButtonItem]) -> [SKBarButtonItem] {
        var items = currentItems
        switch navigationMode {
        case .basic:
            items.removeAll { item in
                ![.back, .close].contains(item.id)
            }
        case .allowing(list: let allowList):
            items.removeAll { item in
                !allowList.contains(item.id)
            }
        case .blocking(list: let allowList):
            items.removeAll { item in
                allowList.contains(item.id)
            }
        case .open: () // do not filter
        }
        return items
    }

    private func _didModifyLeadingItems(old oldValue: [SKBarButtonItem]?, new newValue: [SKBarButtonItem]?) {
        leadingButtonBar.itemViews.enumerated().forEach { index, view in
            view.accessibilityIdentifier = "docs.nav.left.button\(index)"
        } // 这里的 accesibilityIdentifier 是用于自动化测试的，和 badge 无关
        // 有item代表在文件夹里面，所以字体要变小
        let fontSize: CGFloat = (newValue?.count ?? 0) > 0 ? 17 : 24
        titleView.titleFont = UIFont.systemFont(ofSize: fontSize, weight: .medium)
    }

    private func _didModifyTrailingItems(old oldValue: [SKBarButtonItem]?, new newValue: [SKBarButtonItem]?) {
        trailingButtonBar.itemViews.enumerated().forEach { index, view in
            view.accessibilityIdentifier = "docs.nav.right.button\(index)"
        } // 这里的 accesibilityIdentifier 是用于自动化测试的，和 badge 无关
        
        badgeConfigsForTrailingItems = [:]
        // 取 badgeStyle 和 badgeNum，预先配置这些 badge 到 badges 数组中
        newValue?.forEach { item in
            if let style = item.badgeStyle {
                badgeConfigsForTrailingItems.updateValue(style, forKey: item.id)
            }
        }
    }

}
