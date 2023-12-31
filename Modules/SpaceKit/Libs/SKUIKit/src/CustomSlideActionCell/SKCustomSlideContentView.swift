//
//  SKCustomSlideContentView.swift
//  SKUIKit
//
//  Created by Weston Wu on 2023/5/19.
//

import Foundation
import UniverseDesignColor
import SnapKit

private typealias SlideItem = SKCustomSlideItem

// 辅助处理多个 cell 的侧滑互斥逻辑
public final class SKCustomSlideMutexHelper {
    public typealias MutexHandler = () -> Void
    private var currentMutexHandler: MutexHandler?

    fileprivate var hasActiveSliding: Bool {
        currentMutexHandler != nil
    }

    public init() {}

    // cell 开始侧滑时，收起前一个 cell
    public func startSliding(mutexHandler: @escaping MutexHandler) {
        currentMutexHandler?()
        currentMutexHandler = mutexHandler
    }

    // 滑动时收起当前侧滑的 cell
    public func listViewDidScroll() {
        currentMutexHandler?()
        currentMutexHandler = nil
    }

    // 点击侧滑菜单选项后，需要收起侧滑菜单
    public func didClickSlideAction() {
        currentMutexHandler?()
        currentMutexHandler = nil
    }

    // 用于 tableView 感知不到的 cell 自行收起的情况下，主动释放掉 handler
    fileprivate func invalidateHandler() {
        currentMutexHandler = nil
    }
}

private class MutexTapView: UIControl {
    var shouldIntercept: (() -> Bool)?
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard super.point(inside: point, with: event) else { return false }
        return shouldIntercept?() ?? false
    }
}

public struct SKCustomSlideItem {

    public typealias Handler = (SKCustomSlideItem, UIView) -> Void
    // 通过构造函数限制保证两个不能同时为 nil
    public let title: String?
    public let icon: UIImage?
    public let backgroundColor: UIColor
    public var handler: Handler

    private init(title: String?,
                 icon: UIImage?,
                 backgroundColor: UIColor,
                 clickHandler: @escaping Handler) {
        self.title = title
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.handler = clickHandler
    }

    public init(title: String, backgroundColor: UIColor, handler: @escaping Handler) {
        self.init(title: title, icon: nil, backgroundColor: backgroundColor, clickHandler: handler)
    }

    public init(icon: UIImage, backgroundColor: UIColor, handler: @escaping Handler) {
        self.init(title: nil, icon: icon, backgroundColor: backgroundColor, clickHandler: handler)
    }

    public init(title: String, icon: UIImage, backgroundColor: UIColor, handler: @escaping Handler) {
        self.init(title: title, icon: icon, backgroundColor: backgroundColor, clickHandler: handler)
    }
}

private class SlideItemView: UIControl {
    private var iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    private var titleLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UDColor.staticWhite
        return label
    }()

    private var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .fillProportionally
        view.spacing = 4
        view.isUserInteractionEnabled = false
        return view
    }()

    private var currentItem: SlideItem?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override var intrinsicContentSize: CGSize {
        let width = stackView.systemLayoutSizeFitting(.zero).width
        return CGSize(width: 40 + width, height: super.intrinsicContentSize.height)
    }

    private func setupUI() {
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
        stackView.addArrangedSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
        stackView.addArrangedSubview(titleLabel)

        addTarget(self, action: #selector(didClick), for: .touchUpInside)
    }

    func update(item: SlideItem) {
        currentItem = item
        backgroundColor = item.backgroundColor
        if let title = item.title {
            titleLabel.text = title
            titleLabel.isHidden = false
        } else {
            titleLabel.isHidden = true
        }

        if let icon = item.icon {
            iconView.image = icon
            iconView.isHidden = false
        } else {
            iconView.isHidden = true
        }
    }

    @objc
    private func didClick() {
        guard let currentItem else { return }
        currentItem.handler(currentItem, self)
    }
}

public protocol SlideContentViewDataSource: AnyObject {
    func getSlideActions() -> [SKCustomSlideItem]?
}

public typealias SKCustomSlideItemProvider = () -> ([SKCustomSlideItem]?, SKCustomSlideMutexHelper?)

public class SKCustomSlideContentView: UIScrollView, UIScrollViewDelegate {
    // 实际的 cell 内容，尺寸与 cell 等大
    let contentView = UIView()

    private lazy var mutexTapView: MutexTapView = {
        let view = MutexTapView()
        view.addTarget(self, action: #selector(mutexClick), for: .touchUpInside)
        view.isUserInteractionEnabled = true
        view.backgroundColor = .clear
        view.shouldIntercept = { [weak self] in
            guard let self,
                  let provider = self.slideItemProvider,
                  let mutexHelper = provider().1 else {
                return false
            }
            return mutexHelper.hasActiveSliding
        }
        return view
    }()

    private let itemStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.clipsToBounds = true
        view.layer.cornerRadius = 6
        view.distribution = .fillProportionally
        view.alignment = .fill
        return view
    }()

    private var slideActionWidth: CGFloat = 0
    private weak var mutexHelper: SKCustomSlideMutexHelper?
    var slideItemProvider: SKCustomSlideItemProvider?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        delegate = self
        alwaysBounceHorizontal = true
        showsHorizontalScrollIndicator = false

        addSubview(itemStackView)
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.size.equalTo(frameLayoutGuide)
            make.edges.equalTo(contentLayoutGuide)
        }
        addSubview(mutexTapView)
        mutexTapView.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }

        itemStackView.snp.makeConstraints { make in
            make.top.bottom.equalTo(frameLayoutGuide)
            make.left.equalTo(contentView.snp.right).offset(6)
            make.right.equalTo(frameLayoutGuide).inset(6)
        }
        panGestureRecognizer.maximumNumberOfTouches = 1
    }

    override public func touchesShouldCancel(in view: UIView) -> Bool {
        // 对所有内容都返回 true，包括 UIControl 类
        true
    }

    func prepareForReuse() {
        slideItemProvider = nil
        mutexHelper = nil
        setContentOffset(.zero, animated: false)
        cleanUpSlideActions()
    }

    func forceShowSlideActions() {
        guard contentOffset.x == 0 else { return }
        scrollViewWillBeginDragging(self)
        setContentOffset(CGPoint(x: contentInset.right, y: 0), animated: true)
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView.contentOffset.x == 0 else { return }
        guard let (items, mutexHelper) = slideItemProvider?(),
              let items else {
            panGestureRecognizer.isEnabled = false
            panGestureRecognizer.isEnabled = true
            return
        }
        scrollView.alwaysBounceHorizontal = true
        self.mutexHelper = mutexHelper
        mutexHelper?.startSliding { [weak self] in
            self?.forceReset()
        }

        items.forEach { originItem in
            let itemView = SlideItemView()
            var item = originItem
            item.handler = { [weak self] item, _ in
                guard let self else { return }
                self.mutexHelper?.didClickSlideAction()
                // 这里替换成 contentView
                originItem.handler(item, self.superview ?? self)
            }
            itemView.update(item: item)
            itemStackView.addArrangedSubview(itemView)
        }
        let actionWidths = itemStackView.systemLayoutSizeFitting(.zero).width + 12
        contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: actionWidths)
    }

    private func forceReset() {
        panGestureRecognizer.isEnabled = false
        if contentOffset == .zero {
            cleanUpSlideActions()
        } else {
            setContentOffset(.zero, animated: true)
        }
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        var shouldShowActions = false
        let currentXOffset = scrollView.contentOffset.x
        let slideActionWidth = itemStackView.systemLayoutSizeFitting(.zero).width + 12
        if currentXOffset >= slideActionWidth / 2 {
            // 滑动超过一半，默认展开
            shouldShowActions = true
        } else {
            shouldShowActions = false
        }
        if velocity.x > 0 {
            shouldShowActions = true
        } else if velocity.x < 0 {
            shouldShowActions = false
        }
        if shouldShowActions {
            targetContentOffset.pointee = CGPoint(x: slideActionWidth, y: 0)
        } else {
            targetContentOffset.pointee = .zero
        }
        if velocity.x == 0, scrollView.contentOffset.x == 0 {
            scrollViewDidEndDecelerating(scrollView)
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x <= 0 {
            cleanUpSlideActions()
            // 主动滑动收起时，清理下 mutexHelper
            mutexHelper?.invalidateHandler()
        }
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        panGestureRecognizer.isEnabled = true
        if scrollView.contentOffset.x <= 0 {
            cleanUpSlideActions()
        }
    }

    private func cleanUpSlideActions() {
        self.panGestureRecognizer.isEnabled = true
        itemStackView.arrangedSubviews.forEach { view in
            view.removeFromSuperview()
        }
        contentInset = .zero
    }

    @objc
    private func mutexClick() {
        guard let (_, mutexHelper) = slideItemProvider?() else {
            return
        }
        mutexHelper?.listViewDidScroll()
    }
}

extension SKCustomSlideContentView: UIGestureRecognizerDelegate {

    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard super.gestureRecognizerShouldBegin(gestureRecognizer) else { return false }

        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        let velocity = panGesture.velocity(in: self)
        // 水平分量大于垂直分量才能滑动
        guard abs(velocity.x) >= abs(velocity.y) else {
            return false
        }
        // 未展开状态，只允许向左滑
        if contentOffset.x == 0 {
            guard velocity.x < 0 else {
                return false
            }
        }
        return true
    }
}
