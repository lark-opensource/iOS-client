//
//  UDBreadcrumbView.swift
//  Pods-UniverseDesignBreadcrumbDev
//
//  Created by 强淑婷 on 2020/8/20.
//

import UIKit
import Foundation
import SnapKit
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignStyle

/// UDBreadcrumb UI Config
public struct UDBreadcrumbUIConfig {

    /// UDBreadcrumb BackgroundColor
    public var backgroundColor: UIColor?

    /// UDBreadcrumb Navigation Text Color
    public var navigationTextColor: UIColor?

    /// UDBreadcrumb Current Text Color
    public var currentTextColor: UIColor?

    /// UDBreadcrumb Next Icon Color
    public var iconColor: UIColor

    /// UDBreadcrumb Text Font
    public var textFont: UIFont

    /// UDBreadcrumb Item Corner Radius
    public var itemCornerRadius: CGFloat

    /// UDBreadcrumb Item Normal BG Color
    public var itemBackgroundColor: UIColor?

    /// UDBreadcrumb Item Hight BG Color
    public var itemHightedBackgroundColor: UIColor?

    /// Show Animation
    public var showAddAnimated: Bool

    /// init
    /// - Parameters:
    ///   - backgroundColor:
    ///   - navigationTextColor:
    ///   - currentTextColor:
    ///   - iconColor:
    ///   - textFont:
    ///   - itemCornerRadius:
    ///   - itemBackgroundColor:
    ///   - itemHightedBackgroundColor:
    ///   - showAddAnimated:
    public init(backgroundColor: UIColor? = .clear,
                navigationTextColor: UIColor? = UDBreadcrumbColorTheme.breadcrumbNavigationTextColor,
                currentTextColor: UIColor? = UDBreadcrumbColorTheme.breadcrumbCurrentTextColor,
                iconColor: UIColor = UDBreadcrumbColorTheme.breadcrumbIconColor,
                textFont: UIFont = UDFont.body0,
                itemCornerRadius: CGFloat = UDStyle.smallRadius,
                itemBackgroundColor: UIColor? = .clear,
                itemHightedBackgroundColor: UIColor? = UDBreadcrumbColorTheme.breadcrumbItemHightedBackgroundColor,
                showAddAnimated: Bool = false) {

        self.backgroundColor = backgroundColor
        self.navigationTextColor = navigationTextColor
        self.currentTextColor = currentTextColor
        self.iconColor = iconColor
        self.textFont = textFont
        self.itemCornerRadius = itemCornerRadius
        self.itemBackgroundColor = itemBackgroundColor
        self.itemHightedBackgroundColor = itemHightedBackgroundColor
        self.showAddAnimated = showAddAnimated
    }
}

/// UDBreadcrumb
public final class UDBreadcrumb: UIView {

    /// UI Config
    public let config: UDBreadcrumbUIConfig

    /// Tap Callback
    public var tapCallback: ((Int) -> Void)?

    var items: [UDBreadcrumbItemView] = []

    private var rightConstraint: Constraint?
    private var scrollView: UDScrollView!

    public init(config: UDBreadcrumbUIConfig = UDBreadcrumbUIConfig()) {
        self.config = config

        super.init(frame: .zero)

        scrollView = UDScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isUserInteractionEnabled = true
        self.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        self.backgroundColor = config.backgroundColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addItems(titles: [String]) {
        guard !titles.isEmpty else {
            return
        }

        if !items.isEmpty {
            rightConstraint?.deactivate()
            items.last?.setState(hasNext: true)
        }

        for i in 0..<titles.count {
            let title = titles[i]
            let breadcrumbItemView = UDBreadcrumbItemView(config: config)
            breadcrumbItemView.tapItem = { [weak self] index in
                self?.didTapItem(index: index)
            }
            breadcrumbItemView.setItem(title: title, hasNext: !(i == titles.count - 1), index: self.items.count)
            self.scrollView.addSubview(breadcrumbItemView)

            breadcrumbItemView.snp.remakeConstraints { (make) in
                make.centerY.equalToSuperview()
                if items.isEmpty {
                    make.leading.equalTo(8)
                } else {
                    make.leading.equalTo(items.last!.snp.trailing)
                }
                if i == titles.count - 1 {
                    rightConstraint = make.trailing.equalTo(-7).constraint
                }
            }

            items.append(breadcrumbItemView)
        }

        if config.showAddAnimated {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.25) {
                    self.layoutIfNeeded()
                }
            }
        }
    }

    private func removeLastItems(count: Int) {
        guard count >= 1 && count <= items.count else {
            return
        }

        for _ in 0..<count {
            items.popLast()!.removeFromSuperview()
        }

        if !items.isEmpty {
            let item = items.last!
            item.setState(hasNext: false)
            item.snp.remakeConstraints({ (make) in
                make.centerY.equalToSuperview()
                rightConstraint = make.trailing.equalToSuperview().offset(-7).constraint
                if items.count > 1 {
                    make.leading.equalTo(items[items.count - 2].snp.trailing).offset(8)
                } else {
                    make.leading.equalTo(8)
                }
            })
            rightConstraint?.activate()
            UIView.animate(withDuration: 0.25, animations: {
                self.layoutIfNeeded()
            })
        }
    }
}

extension UDBreadcrumb {
    /// Scroll directly to the far right of scrollView
    public func scrollToRight(delay: Double = 0.25) {
        let num: NSString = NumberFormatter.localizedString(from: NSNumber(value: 1),
                                                            number: NumberFormatter.Style.decimal
            ) as NSString
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()
            + DispatchTimeInterval.microseconds(Int(delay * num.doubleValue))) {
                guard self.scrollView.contentSize.width > self.scrollView.bounds.width else {
                    return
                }
                self.scrollView.setContentOffset(
                    CGPoint(
                        x: self.scrollView.contentSize.width - self.scrollView.bounds.width,
                        y: 0
                    ),
                    animated: true
                )
        }
    }

    public func scrollToRightDirectly() {
        let offsetX = self.scrollView.contentSize.width - self.scrollView.bounds.width
        guard offsetX > 0 else { return }
        self.scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: false)
    }

    /// Click the event of an item
    public func didTapItem(index: Int) {
        // 点击最新的不返回
        guard index != self.items.count - 1 else {
            return
        }
        self.tapCallback?(index)
    }

    /// Create itemViews based on title
    public func setItems(_ items: [String]) {
        removeItems()
        self.scrollView.contentSize = .zero
        addItems(titles: items)
    }

    /// Add items according to titles
    public func addItems(_ items: [String]) {
        self.addItems(titles: items)
    }

    /// Delete the last few items
    public func removeLast(count: Int = 1) {
        self.removeLastItems(count: count)
    }

    /// Delete from the index to the last
    public func removeTo(index: Int) {
        guard index >= 0 && index < items.count else {
            return
        }
        let count = items.count - index
        self.removeLastItems(count: count)
    }

    /// Remove all itemViews
    public func removeItems() {
        items.forEach { $0.removeFromSuperview() }
        items.removeAll()
        self.scrollView.contentSize = CGSize.zero
    }

    public func getTotalItemsNumber() -> Int {
        return self.items.count
    }
}
