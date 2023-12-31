//
//  SKButtonBar.swift
//  SKNavigationBar
//
//  Created by 边俊林 on 2019/11/26.
//

import UIKit

/**
 A button bar use for placing bar, doing do a lot of layout work, easy to use than building your custom bar.

 If you want to use a toolbar of buttons, this component is preferred.
 A button bar contains a list of SKBarButtonItem elements, and you can use your own custom view to customize it.
 */
open class SKButtonBar: UIView {

    // MARK: External Properties
    public var items: [SKBarButtonItem]? {
        didSet { mainSync { _relayoutButtons() } }
    }

    public var arrangementDirection: ArrangementDirection {
        didSet { setNeedsLayout() }
    }

    public var itemSpacing: CGFloat = 20 {
        didSet { setNeedsLayout() }
    }

    /** The attributes use for customize button bar layout. */
    public var layoutAttributes: LayoutAttributes = .default {
        didSet { setNeedsLayout() }
    }

    // MARK: Internal Properties

    /** The final product of `items` that can use directly in SKButtonBar. It may be an `SKBarButton` or a normal `UIView`. */
    public internal(set) var itemViews: [UIView] = []

    /**
     The current button hitTest mode

     CAUTION: This property is calculated internally, which means
     you have to modify it carefully if really needed.
     */
    public internal(set) var buttonHitTestMode: ButtonHitTestMode = .none

    /// 设置按钮热区，不会影响 frame
    public internal(set) var buttonHitTestInset: UIEdgeInsets?
    
    public override var intrinsicContentSize: CGSize {
        return _sizeThatFits(bounds.size)
    }

    // MARK: Interface
    public init(frame: CGRect,
                items: [SKBarButtonItem]?,
                arrangementDirection: ArrangementDirection,
                layoutAttributes: LayoutAttributes) {
        self.items = items
        self.arrangementDirection = arrangementDirection
        self.layoutAttributes = layoutAttributes

        super.init(frame: frame)
        commonInit()
    }

    convenience public override init(frame: CGRect = .zero) {
        self.init(frame: frame, items: nil,
                  arrangementDirection: .automatic,
                  layoutAttributes: .default)
    }

    convenience public init(arrangementDirection: ArrangementDirection,
                            layoutAttributes: LayoutAttributes) {
        self.init(frame: .zero, items: nil,
                  arrangementDirection: arrangementDirection,
                  layoutAttributes: layoutAttributes)
    }

    required public init?(coder: NSCoder) {
        self.items = nil
        self.arrangementDirection = .automatic
        self.layoutAttributes = .default

        super.init(coder: coder)
        commonInit()
    }

    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard isHidden == false, alpha > 0.02 else { return false }
        let responseFrame = bounds.insetBy(dx: -itemSpacing / 2, dy: 0)
        return responseFrame.contains(point)
    }

    // MARK: Internal

    /** Never call it directly, if overrided, you should call `super` in your own implementation. */
    public func commonInit() {
        backgroundColor = .clear
    }

    /// 给定一个宽度，计算最多可以放下多少个 item
    public func maxAmountOfItemsForWidth(_ width: CGFloat) -> Int {
        // 目前先按照纯按钮的方式来算，后面加文本按钮之后再考虑怎么搞
        let itemWidth: CGFloat = layoutAttributes.itemHeight ?? 24
        let itemSlotWidth: CGFloat = itemWidth + itemSpacing
        let availableWidth: CGFloat = width + itemSpacing
        let quantity: CGFloat = availableWidth / itemSlotWidth
        let amount = floor(quantity)
        return Int(amount)
    }


    // MARK: Layout
    public override func layoutSubviews() {
        super.layoutSubviews()
        _sizeThatFits(bounds.size, forceLayout: true)
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        if isIpad && previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
            _relayoutButtons()
        }
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        return _sizeThatFits(size)
    }

    @discardableResult
    private func _sizeThatFits(_ size: CGSize, forceLayout: Bool = false) -> CGSize {
        guard !itemViews.isEmpty else { return .zero }
        _applyLayoutBehaviours()

        var targetWidth: CGFloat = 0, targetHeight: CGFloat = 0, leadingX: CGFloat = 0
        let shouldReverse: Bool = arrangementDirection == .trailing
        for view in shouldReverse ? itemViews.reversed() : itemViews {
            if let idx = index(of: view), let items = items, idx >= 0 && idx < items.count {
                var width = view.frame.width
                var height = size.height
                if let customHeight = layoutAttributes.itemHeight, view is SKBarButton {
                    height = customHeight
                } else if !(view is SKBarButton) {
                    // Use customView origin height if not restrict
                    height = view.frame.height
                }

                let minY = floor(size.height - height) / 2
                let item = items[idx]
                width = item.width > 0 ? item.width :
                    view.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: height)).width

                if forceLayout {
                    width = ceil(width)
                    height = ceil(height)
                    view.frame = CGRect(x: leadingX, y: minY, width: width, height: height)
                    // Set iPad pointer
                    if let view = view as? SKBarButton {
                        if case let .custom(insets) = buttonHitTestMode {
                            // Set frame according to hitTest area of view with custom hit test configurations
                            view.frame = CGRect(x: leadingX + insets.left,
                                                y: minY + insets.top,
                                                width: width - insets.left - insets.right,
                                                height: height - insets.top - insets.bottom)
                        }
                    } else if let view = view as? SKBarButtonCustomInsetable {
                        view.frame = CGRect(x: leadingX + view.offset.x,
                                            y: minY + view.offset.y,
                                            width: width,
                                            height: height)
                    }
                }
                leadingX += width + itemSpacing
                targetWidth += width + itemSpacing
            }
        }
        targetWidth -= itemSpacing
        targetHeight = size.height
        return CGSize(width: targetWidth, height: targetHeight)
    }

    private func _relayoutButtons() {
        itemViews.forEach {
            $0.removeFromSuperview()
        }
        itemViews = viewsFromItems(items)
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    /** NOTICE: You should apply attributes before calculate size and layout. */
    private func _applyLayoutBehaviours() {
        // calculate button hitest mode
        if let hitTestInsets = layoutAttributes.buttonHitTestInsets {
            buttonHitTestMode = .custom(insets: hitTestInsets)
        } else {
            buttonHitTestMode = .none
        }
    }
}

extension SKButtonBar {

    // MARK: Button Converter
    func viewsFromItems(_ items: [SKBarButtonItem]?) -> [UIView] {
        guard let items = items else { return [] }
        return items.compactMap { item -> UIView? in
            let view = viewFromItem(item)
            // Tips: align SKBarButtonItem width property to customView
            if item.width > 0 {
                var frame = view.frame
                frame.size.width = item.width
                view.frame = frame
            }
            self.addSubview(view)
            return view
        }
    }

    @inline(__always)
    func viewFromItem(_ item: SKBarButtonItem) -> UIView {
        // Take away the custom view, in avoid of it being taked by the system & make KVO work well.
        if let customView = item.customView, !(customView is PseudoCustomView) {
            item.skCustomView = customView
            item.customView = PseudoCustomView()
        }
        let customView = item.skCustomView != nil ? item.skCustomView : item.customView
        if let customView = customView {
            customView.docs.addStandardLift()
            customView.accessibilityElements = [item] // 如果是自定义 view，用 accElements?.first 来存放 BarButtonItem
            return customView
        }

        // Generate SKButtonItem if no custom should we take away.
        let button = SKBarButton()
        item.associatedButton = button
        if let buttonHitTestInset = buttonHitTestInset {
            button.hitTestEdgeInsets = buttonHitTestInset
        }
        button.apply(with: item, layout: layoutAttributes) // SKBarButton 和 SKBarButtonItem 互相关联
        // 要先收缩到合适的大小，然后才能配置背景图片
        button.sizeToFit()
        // Configure backgroundColor
        
        if let backgroundImageColorMapping = item.backgroundImageColorMapping,
           button.frame.size.width > 0 {
            for (state, color) in backgroundImageColorMapping {
                let backgroundImage = UIImage.docs.create(by: color, size: button.frame.size)
                button.setBackgroundImage(backgroundImage, for: state)
            }
        }
        button.docs.addHighlight(with: .zero, radius: 6)
        return button
    }

//    // MARK: Util method
//    @inline(__always)
//    func itemView(at index: Int) -> SKBarButton? {
//        guard index >= 0 && index < itemViews.count else { return nil }
//        return itemViews[index] as? SKBarButton
//    }

//    @inline(__always)
//    func itemView(of item: SKBarButtonItem) -> SKBarButton? {
//        guard let index = items?.firstIndex(of: item) else { return nil }
//        return itemView(at: index)
//    }

    @inline(__always)
    func index(of view: UIView) -> Int? {
        itemViews.firstIndex(of: view)
    }

    @inline(__always)
    func mainSync(_ callback: (() -> Void)) {
        if Thread.isMainThread {
            callback()
        } else {
            DispatchQueue.main.sync {
                callback()
            }
        }
    }
}

extension SKButtonBar {

    /** Determine in which order the components using the list of buttons to lay out the buttons. */
    public enum ArrangementDirection {

        /** Reserved property, current is same as leading. */
        case automatic

        /** From leading to trailing enumerate the `items` list. */
        case leading

        /** From trailing to leading enumerate the `items` list. */
        case trailing

    }

    /** The touch area expanding behaviour of each button. */
    public enum ButtonHitTestMode: Equatable {

        /** Touch area is same as its size. */
        case none

        /** Use custom `UIEdgeInsets` object to set touch area. */
        case custom(insets: UIEdgeInsets)

    }

}
