//
//  SKSlideableTableViewCell.swift
//  SKUIKit
//
//  Created by Weston Wu on 2021/9/14.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RxRelay
import UniverseDesignColor

extension SKSlideableTableViewCell {

    // 辅助处理多个 cell 的侧滑互斥逻辑
    public final class MutexHelper {
        private var currentMutexHandler: MutexHandler?

        public init() {}

        // cell 开始侧滑时，收起前一个 cell
        public func startSliding(mutexHandler: @escaping MutexHandler) {
            currentMutexHandler?()
            currentMutexHandler = mutexHandler
        }

        // 滑动时收起当前侧滑的 cell
        public func tableViewDidScroll() {
            currentMutexHandler?()
            currentMutexHandler = nil
        }

        // 点击侧滑菜单选项后，需要收起侧滑菜单
        public func didClickSlideMenuAction() {
            currentMutexHandler?()
            currentMutexHandler = nil
        }

        // 用于 tableView 感知不到的 cell 自行收起的情况下，主动释放掉 handler
        fileprivate func invalidateHandler() {
            currentMutexHandler = nil
        }
    }

    // 同一个 tableView 中，slide 需要做互斥
    public typealias MutexHandler = () -> Void
    public typealias ClickHandler = () -> Void
    public typealias SlideItem = SKSlidableTableViewCellItem
    private typealias SlideItemView = SKSlidableTableViewCellItemView

    private enum ScrollState {
        // contentOffset = 0
        case inactive
        // 正在展示 slideItems
        case active(items: [SlideItem])

        var itemCount: Int {
            switch self {
            case .inactive:
                return 0
            case let .active(items):
                return items.count
            }
        }

        var isActive: Bool {
            switch self {
            case .inactive:
                return false
            case .active:
                return true
            }
        }
    }

    public enum Layout {
        static var slideItemWidth: CGFloat { 56 }
        public static var cornerRadius: CGFloat = 8
    }
}

// 因为在 cell 的内部增加了 UIScrollView，导致无法正确触发 UITableViewDelegate 的 highlight、selected 方法，建议业务方按需自行实现
// 仅当 cell 的样式存在左右缩进，且需要支持侧滑菜单时，才考虑使用此 View
open class SKSlideableTableViewCell: UITableViewCell, UIScrollViewDelegate {

    public private(set) lazy var containerView: UIControl = {
        let view = UIControl()
        view.backgroundColor = UDColor.bgBodyOverlay
        return view
    }()

    public private(set) lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .clear
        view.clipsToBounds = true
        view.delegate = self
        view.isDirectionalLockEnabled = true

        view.alwaysBounceVertical = false
        view.alwaysBounceHorizontal = true

        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        if #available(iOS 13.4, *) {
            view.panGestureRecognizer.allowedScrollTypesMask = [.continuous]
        }
        return view
    }()

    private lazy var itemContainerView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .fill
        view.distribution = .fillEqually
        return view
    }()

    private lazy var scrollState = ScrollState.inactive
    private var reuseBag = DisposeBag()

    private var clickHandler: ClickHandler?

    private weak var mutexHelper: MutexHelper?
    public var slideItemProvider: ((@escaping MutexHandler) -> ([SlideItem]?, MutexHelper?))?

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        selectionStyle = .none
        contentView.backgroundColor = .clear

        contentView.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(16)
        }

        scrollView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.left.lessThanOrEqualTo(scrollView.frameLayoutGuide)
            make.left.equalTo(scrollView.contentLayoutGuide).priority(.medium)
            make.top.bottom.equalTo(scrollView.contentLayoutGuide)
            make.height.width.equalTo(scrollView.frameLayoutGuide)
            make.right.equalTo(scrollView.contentLayoutGuide)
        }

        scrollView.addSubview(itemContainerView)
        itemContainerView.snp.makeConstraints { make in
            make.top.bottom.right.equalTo(scrollView.frameLayoutGuide)
            make.left.equalTo(containerView.snp.right)
        }

        containerView.addTarget(self, action: #selector(didClickContainer), for: .touchUpInside)
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        slideItemProvider = nil
        clickHandler = nil
        mutexHelper = nil
        scrollView.setContentOffset(.zero, animated: false)
        resetToInactive(animated: false)
        reuseBag = DisposeBag()
    }

    public func update(roundCorners: CACornerMask) {
        if roundCorners.isEmpty {
            scrollView.layer.cornerRadius = 0
        } else {
            scrollView.layer.cornerRadius = Layout.cornerRadius
            scrollView.layer.maskedCorners = roundCorners
        }
    }

    // MARK: - UIScrollViewDelegate
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        print("will begin dragging")
        switch scrollState {
        case .active:
            return
        case .inactive:
            break
        }

        let mutexHandler: MutexHandler = { [weak self] in
            guard let self = self else { return }
            self.resetToInactive(animated: true)
        }
        guard let (slideItems, mutexHelper) = slideItemProvider?(mutexHandler),
              let items = slideItems,
              !items.isEmpty else {
            scrollView.alwaysBounceHorizontal = false
            return
        }
        self.mutexHelper = mutexHelper
        let scrollWidth = CGFloat(items.count) * Layout.slideItemWidth
        containerView.snp.updateConstraints { make in
            make.right.equalTo(scrollView.contentLayoutGuide).inset(scrollWidth)
        }
        items.forEach { item in
            let itemView = SlideItemView()
            itemView.update(item: item)
            itemContainerView.addArrangedSubview(itemView)
            itemView.rx.controlEvent(.touchUpInside).subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                let handler = item.handler
                handler(item, self)
            }).disposed(by: reuseBag)
        }
        scrollState = .active(items: items)
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let expandedOffsetX = CGFloat(scrollState.itemCount) * Layout.slideItemWidth
        if velocity.x == 0 {
            if scrollView.contentOffset.x < expandedOffsetX / 2 {
                targetContentOffset.pointee = .zero
            } else {
                targetContentOffset.pointee = CGPoint(x: expandedOffsetX, y: 0)
            }
            return
        }

        if velocity.x > 0 {
            targetContentOffset.pointee = CGPoint(x: expandedOffsetX, y: 0)
        } else {
            targetContentOffset.pointee = .zero
        }
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        print("did end dragging")
        scrollView.alwaysBounceHorizontal = true
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print("did end decelerating")
        if scrollView.contentOffset == .zero {
            mutexHelper?.invalidateHandler()
            mutexHelper = nil
            resetToInactive(animated: false)
        }
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        print("did end scroll animation")
        if scrollView.contentOffset == .zero {
            resetToInactive(animated: false)
        }
    }

    private func resetToInactive(animated: Bool) {
        let resetCompletion = { [self] in
            scrollState = .inactive
            itemContainerView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            containerView.snp.updateConstraints { make in
                make.right.equalTo(scrollView.contentLayoutGuide)
            }
        }
        if animated {
            UIView.animate(withDuration: 0.5) { [self] in
                scrollView.contentOffset = .zero
                scrollView.layoutIfNeeded()
            } completion: { _ in
                resetCompletion()
            }
        } else {
            resetCompletion()
        }
    }

    /// 设置点击事件
    /// - Parameter handler: 处理点击事件，入参表明
    open func setClickAction(_ handler: @escaping ClickHandler) {
        clickHandler = handler
    }

    @objc
    private func didClickContainer() {
        switch scrollState {
        case .inactive:
            clickHandler?()
        case .active:
            mutexHelper?.invalidateHandler()
            mutexHelper = nil
            resetToInactive(animated: true)
        }
    }
}

public struct SKSlidableTableViewCellItem {
    public typealias Handler = (SKSlidableTableViewCellItem, UIView) -> Void
    public let icon: UIImage
    public let backgroundColor: UIColor
    public let handler: Handler

    public init(icon: UIImage, backgroundColor: UIColor, handler: @escaping Handler) {
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.handler = handler
    }
}

private class SKSlidableTableViewCellItemView: UIControl {
    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.tintColor = UDColor.primaryOnPrimaryFill
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
            make.left.equalToSuperview().inset(18)
        }
    }

    func update(item: SKSlidableTableViewCellItem) {
        iconView.image = item.icon.withRenderingMode(.alwaysTemplate)
        backgroundColor = item.backgroundColor
    }
}
