//
//  InterpreterChannelSwitch.swift
//  ByteView
//
//  Created by fakegourmet on 2020/10/25.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit

final class InterpreterChannelSegmentedControl: UIControl {
    enum Orientation {
        case vertical
        case horizontal
    }

    var controlOrientation: Orientation = .horizontal {
        didSet {
            guard controlOrientation != oldValue else { return }
            applySegments(shouldResetIndex: false)
        }
    }

    private struct Constants {
        static let minimumIntrinsicContentSizeHeight: CGFloat = 46.0
        static let minimumSegmentIntrinsicContentSizeWidth: CGFloat = 72.0
        static let segmentMarginForVerticalOrientation: CGFloat = 3.0
    }

    /// Indicates a no-segment-selected state.
    static let noSegment = -1

    /// The selected index. Use `setIndex()` for setting the index.
    private(set) var index: Int

    /// The segments available for selection.
    var segments: [InterpreterChannelSegment] {
        didSet {
            applySegments()
        }
    }

    private var segmentSize: CGSize {
        segments
            .compactMap { $0.intrinsicContentSize }
            .reduce(CGSize()) { res, cur in
                CGSize(width: max(res.width, cur.width), height: max(res.height, cur.height))
            }
    }

    /// The currently selected index indicator view.
    let indicatorView = IndicatorView()

    /// Whether the the control should always send the .valueChanged event, regardless of the index remaining unchanged after interaction. Defaults to `false`.
    var alwaysAnnouncesValue: Bool = false

    /// Whether to send the .valueChanged event immediately or wait for animations to complete. Defaults to `true`.
    var announcesValueImmediately: Bool = true

    /// Whether the the control should ignore pan gestures. Defaults to `false`.
    var panningDisabled: Bool = false

    /// The control's and indicator's corner radii.
    var cornerRadius: CGFloat {
        get {
            layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            updateCornerRadii()
        }
    }

    /// The indicator view's background color.
    var indicatorViewBackgroundColor: UIColor? {
        get {
            indicatorView.backgroundColor
        }
        set {
            indicatorView.backgroundColor = newValue
        }
    }

    /// The indicator view's inset. Defaults to `4.0`.
    var indicatorViewInset: CGFloat = 4.0 {
        didSet {
            updateCornerRadii()
        }
    }

    /// The indicator view's border width.
    var indicatorViewBorderWidth: CGFloat {
        get {
            indicatorView.layer.borderWidth
        }
        set {
            indicatorView.layer.borderWidth = newValue
        }
    }

    /// The indicator view's border color.
    var indicatorViewBorderColor: UIColor? {
        get {
            guard let color = indicatorView.layer.borderColor else {
                return nil
            }
            return UIColor(cgColor: color)
        }
        set {
            indicatorView.layer.vc.borderColor = newValue
        }
    }

    var indicatorViewCornerRadius: CGFloat {
        get {
            indicatorView.cornerRadius
        }
        set {
            indicatorView.cornerRadius = newValue
        }
    }

    /// The duration of the animation of an index change. Defaults to `0.3`.
    var animationDuration: TimeInterval = 0.3

    /// The spring damping ratio of the animation of an index change. Defaults to `0.75`. Set to `1.0` for a no bounce effect.
    var animationSpringDamping: CGFloat = 0.75

    /// When the control auto-sizes itself, this controls the additional side padding between the segments.
    var segmentPadding: CGFloat = 14.0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    /// The spacing between two segment. Defaults to `4.0`.
    var segmentSpacing: CGFloat = 4.0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        if controlOrientation == .vertical {
            let margin = Constants.segmentMarginForVerticalOrientation
            let height = margin * 2 + segmentSize.height * CGFloat(segments.count) + 1 * CGFloat(segments.count - 1)
            let width = margin * 2 + segmentSize.width
            return .init(width: width, height: height)
        }

        let segmentIntrinsicContentSizes = segments.map {
            $0.intrinsicContentSize ?? .zero
        }

        var width = segmentIntrinsicContentSizes.reduce(totalInsetSize) { sum, size in
            return sum + segmentSpacing + max(size.width, Constants.minimumSegmentIntrinsicContentSizeWidth) + segmentPadding
        }
        width -= segmentSpacing

        let maxSegmentIntrinsicContentSizeHeight = segmentIntrinsicContentSizes.max(by: { (a, b) in
            return a.height < b.height
        })?.height ?? 0.0
        let height = ceil(max(maxSegmentIntrinsicContentSizeHeight + totalInsetSize, Constants.minimumIntrinsicContentSizeHeight))

        return .init(width: width, height: height)
    }

    private let normalSegmentViewsContainerView = UIView()
    private let selectedSegmentViewsContainerView = UIView()
    private let pointerInteractionViewsContainerView = UIView()
    private var initialIndicatorViewFrame: CGRect?
    private var tapGestureRecognizer: UITapGestureRecognizer!
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var normalSegmentViews: [UIView] = []
    private var normalSegmentViewCount: Int { normalSegmentViews.count }

    /// `selectedSegmentViews` provide accessibility traits.
    private var selectedSegmentViews: [UIView] = []

    var pointerInteractionViews: [UIView] = []
    /// Used for iPad Pointer Interaction support. Holds the reference to the view that should be highlighted, if any.
    weak var pointerInteractionView: UIView?

    /// Contains normal segment views, selected segment views and pointer interaction views.
    private var allSegmentViews: [UIView] { normalSegmentViews + selectedSegmentViews + pointerInteractionViews }

    private var safeIndex: Int {
        index >= 0 ? index : 0
    }
    private var lastIndex: Int { segments.endIndex - 1 }

    private var totalInsetSize: CGFloat { indicatorViewInset * 2.0 }

    private var isLayoutDirectionRightToLeft: Bool {
        let layoutDirection = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute)
        return layoutDirection == .rightToLeft
    }

    private static var defaultOptions: [Option] = [.backgroundColor(UIColor.ud.bgFloat),
                                                   .indicatorViewBackgroundColor(UIColor.ud.vcTokenVCBtnFillSelected)]

    init(frame: CGRect,
         segments: [InterpreterChannelSegment],
         index: Int = 0,
         options: [Option]? = nil) {
        if segments.indices.contains(index) || index == Self.noSegment {
            self.index = index
        } else {
            self.index = 0
        }
        self.segments = segments
        super.init(frame: frame)
        completeInit()
        if index == -1 {
            setIndicatorViewVisible(false, animated: false, completion: nil)
        }
        setOptions(InterpreterChannelSegmentedControl.defaultOptions)
        if let options = options {
            setOptions(options)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        self.index = 0
        self.segments = Self.generateDefaultSegments()

        super.init(coder: aDecoder)

        completeInit()
    }

    convenience override init(frame: CGRect) {
        self.init(frame: frame, segments: Self.generateDefaultSegments())
    }

    convenience init() {
        self.init(frame: .zero, segments: Self.generateDefaultSegments())
    }

    private func completeInit() {
        layer.masksToBounds = true

        if #available(iOS 13.4, *) {
            let interaction = UIPointerInteraction(delegate: self)
            addInteraction(interaction)
        }

        // set up view hierarchy
        normalSegmentViewsContainerView.clipsToBounds = true
        addSubview(normalSegmentViewsContainerView)
        addSubview(indicatorView)
        selectedSegmentViewsContainerView.clipsToBounds = true
        addSubview(selectedSegmentViewsContainerView)
        selectedSegmentViewsContainerView.layer.mask = indicatorView.segmentMaskView.layer
        pointerInteractionViewsContainerView.clipsToBounds = true
        addSubview(pointerInteractionViewsContainerView)

        // configure gestures
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        addGestureRecognizer(tapGestureRecognizer)

        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panned(_:)))
        panGestureRecognizer.delegate = self
        addGestureRecognizer(panGestureRecognizer)

        applySegments(shouldResetIndex: false)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard normalSegmentViewCount >= 1 else {
            return
        }

        normalSegmentViewsContainerView.frame = bounds
        selectedSegmentViewsContainerView.frame = bounds
        pointerInteractionViewsContainerView.frame = bounds

        indicatorView.frame = frameForElement(atIndex: safeIndex)

        for index in normalSegmentViews.indices {
            let frame = frameForElement(atIndex: index)
            normalSegmentViews[index].frame = frame
            selectedSegmentViews[index].frame = frame
            pointerInteractionViews[index].frame = frame
        }
    }

    func setIndex(_ index: Int, animated: Bool = true, shouldSendValueChangedEvent: Bool = false) {
        guard segments.indices.contains(index) || index == Self.noSegment else { return }

        let previousIndex = self.index
        self.index = index

        let shouldUpdateSegmentViewTraits = (index != previousIndex)
        let shouldUpdateSegmentViewTraitsBeforeAnimations = announcesValueImmediately && shouldUpdateSegmentViewTraits
        let shouldUpdateSegmentViewTraitsAfterAnimations = !announcesValueImmediately && shouldUpdateSegmentViewTraits

        let shouldSendEvent = (index != previousIndex || alwaysAnnouncesValue) && shouldSendValueChangedEvent
        let shouldSendEventBeforeAnimations = announcesValueImmediately && shouldSendEvent
        let shouldSendEventAfterAnimations = !announcesValueImmediately && shouldSendEvent

        if shouldSendEventBeforeAnimations {
            sendActions(for: .valueChanged)
        }
        if shouldUpdateSegmentViewTraitsBeforeAnimations {
            updateSegmentViewTraits()
        }
        performIndexChange(fromPreviousIndex: previousIndex, toNewIndex: index, animated: animated, completion: { [weak self] in
            guard let weakSelf = self else { return }
            if shouldSendEventAfterAnimations {
                weakSelf.sendActions(for: .valueChanged)
            }
            if shouldUpdateSegmentViewTraitsAfterAnimations {
                weakSelf.updateSegmentViewTraits()
            }
        })
    }

    func setOptions(_ options: [Option]) {
        for option in options {
            switch option {
            case let .indicatorViewBackgroundColor(value):
                indicatorViewBackgroundColor = value
            case let .indicatorViewInset(value):
                indicatorViewInset = value
            case let .indicatorViewBorderWidth(value):
                indicatorViewBorderWidth = value
            case let .indicatorViewBorderColor(value):
                indicatorViewBorderColor = value
            case let .indicatorViewCornerRadius(value):
                indicatorViewCornerRadius = value
            case let .alwaysAnnouncesValue(value):
                alwaysAnnouncesValue = value
            case let .announcesValueImmediately(value):
                announcesValueImmediately = value
            case let .panningDisabled(value):
                panningDisabled = value
            case let .backgroundColor(value):
                backgroundColor = value
            case let .cornerRadius(value):
                cornerRadius = value
            case let .borderWidth(value):
                layer.borderWidth = value
            case let .borderColor(value):
                layer.ud.setBorderColor(value)
            case let .animationDuration(value):
                animationDuration = value
            case let .animationSpringDamping(value):
                animationSpringDamping = value
            case let .segmentPadding(value):
                segmentPadding = value
            case let .segmentSpacing(value):
                segmentSpacing = value
            }
        }
    }

    private func setIndicatorViewVisible(_ isVisible: Bool, animated: Bool, completion: (() -> Void)?) {
        // nolint-next-line: magic number
        UIView.animate(withDuration: (animated ? 0.1 : 0.0),
                       delay: 0.0,
                       options: [.beginFromCurrentState, .curveEaseIn],
                       animations: { () -> Void in
                        self.selectedSegmentViewsContainerView.alpha = isVisible ? 1.0 : 0.0
                        self.indicatorView.alpha = isVisible ? 1.0 : 0.0
        }, completion: { _ in
            completion?()
        })
    }

    private func performIndexChange(fromPreviousIndex previousIndex: Int,
                                    toNewIndex newIndex: Int,
                                    animated: Bool,
                                    completion: @escaping () -> Void) {
        func moveIndicatorViewToIndex(animated: Bool, completion: @escaping () -> Void) {
            guard index >= 0 else { return }

            UIView.animate(withDuration: animated ? animationDuration : 0.0,
                           delay: 0.0,
                           usingSpringWithDamping: animationSpringDamping,
                           initialSpringVelocity: 0.0,
                           options: [.beginFromCurrentState, .curveEaseOut],
                           animations: { () -> Void in
                            self.indicatorView.frame = self.normalSegmentViews[self.index].frame
                            self.layoutIfNeeded()
            }, completion: { _ in
                completion()
            })
        }

        if index == Self.noSegment {
            setIndicatorViewVisible(false, animated: animated) {
                completion()
            }
        } else if previousIndex == Self.noSegment {
            moveIndicatorViewToIndex(animated: false, completion: { [weak self] in
                self?.setIndicatorViewVisible(true, animated: animated) {
                    completion()
                }
            })
        } else {
            moveIndicatorViewToIndex(animated: animated, completion: {
                completion()
            })
        }
    }

    private func applySegments(shouldResetIndex: Bool = true) {
        normalSegmentViews.forEach { $0.removeFromSuperview() }
        normalSegmentViews.removeAll()

        selectedSegmentViews.forEach { $0.removeFromSuperview() }
        selectedSegmentViews.removeAll()

        pointerInteractionViews.forEach { $0.removeFromSuperview() }
        pointerInteractionViews.removeAll()

        for segment in segments {
            segment.normalView.clipsToBounds = true
            segment.normalView.isAccessibilityElement = false

            segment.selectedView.clipsToBounds = true

            normalSegmentViewsContainerView.addSubview(segment.normalView)
            normalSegmentViews.append(segment.normalView)

            selectedSegmentViewsContainerView.addSubview(segment.selectedView)
            selectedSegmentViews.append(segment.selectedView)

            let pointerInteractionView = UIView()
            pointerInteractionViewsContainerView.addSubview(pointerInteractionView)
            pointerInteractionViews.append(pointerInteractionView)
        }

        updateSegmentViewTraits()
        updateCornerRadii()
        if shouldResetIndex {
            resetIndex()
        }

        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    private func updateCornerRadii() {
        allSegmentViews.forEach { $0.layer.cornerRadius = cornerRadius }
    }

    private func updateSegmentViewTraits() {
        accessibilityElements = selectedSegmentViews

        for index in selectedSegmentViews.indices {
            selectedSegmentViews[index].accessibilityTraits = (index == self.index ? [.button, .selected] : [.button])
        }
    }

    private func frameForElement(atIndex index: Int) -> CGRect {
        if controlOrientation == .vertical {
            let margin = Constants.segmentMarginForVerticalOrientation
            return CGRect(
                x: margin,
                y: margin + CGFloat(index) * (1 + segmentSize.height),
                width: segmentSize.width,
                height: segmentSize.height
            )
        }
        let realIndex = isLayoutDirectionRightToLeft ? lastIndex - index : index
        var x: CGFloat = 0
        var elementWidth: CGFloat = 0
        for (i, s) in segments.enumerated() {
            if i < realIndex {
                let sWidth = s.intrinsicContentSize?.width ?? 0
                let singleWidth = max(sWidth, Constants.minimumSegmentIntrinsicContentSizeWidth) + segmentPadding + segmentSpacing
                x += singleWidth
            } else if i == realIndex {
                elementWidth = max(s.intrinsicContentSize?.width ?? 0, Constants.minimumSegmentIntrinsicContentSizeWidth) + segmentPadding
            }
        }
        return CGRect(x: x + indicatorViewInset,
                      y: indicatorViewInset,
                      width: elementWidth,
                      height: bounds.height - totalInsetSize)
    }

    private func resetIndex() {
        let newIndex = (!segments.isEmpty ? 0 : -1)
        setIndex(newIndex, animated: false, shouldSendValueChangedEvent: false)
    }

    func closestIndex(toPoint point: CGPoint) -> Int {
        let distances = normalSegmentViews.map {
            self.controlOrientation == .vertical ? abs(point.y - $0.center.y) : abs(point.x - $0.center.x)
        }
        return Int(distances.firstIndex(of: distances.min()!)!)
    }

    private static func generateDefaultSegments() -> [LabelSegment] {
        [.init(text: ""), .init(text: "")]
    }

    @objc private func tapped(_ gestureRecognizer: UITapGestureRecognizer!) {
        let location = gestureRecognizer.location(in: self)
        setIndex(closestIndex(toPoint: location), shouldSendValueChangedEvent: true)
    }

    @objc private func panned(_ gestureRecognizer: UIPanGestureRecognizer!) {
        switch gestureRecognizer.state {
        case .began:
            initialIndicatorViewFrame = indicatorView.frame
        case .changed:
            var frame = initialIndicatorViewFrame!
            frame.origin.x += gestureRecognizer.translation(in: self).x
            frame.origin.x = max(min(frame.origin.x, bounds.width - indicatorViewInset - frame.width), indicatorViewInset)
            indicatorView.frame = frame
        case .ended, .failed, .cancelled:
            setIndex(closestIndex(toPoint: indicatorView.center), shouldSendValueChangedEvent: true)
        default: break
        }
    }
}

extension InterpreterChannelSegmentedControl: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGestureRecognizer {
            return indicatorView.frame.contains(gestureRecognizer.location(in: self)) && !panningDisabled
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
}

extension InterpreterChannelSegmentedControl {
    final class IndicatorView: UIView {
        let segmentMaskView = UIView()
        var cornerRadius: CGFloat = 0.0 {
            didSet {
                layer.cornerRadius = cornerRadius
                segmentMaskView.layer.cornerRadius = cornerRadius
            }
        }
        override var frame: CGRect {
            didSet {
                segmentMaskView.frame = frame
            }
        }

        init() {
            super.init(frame: CGRect.zero)
            completeInit()
        }
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            completeInit()
        }
        private func completeInit() {
            segmentMaskView.backgroundColor = UIColor.ud.N00
        }
    }
}
