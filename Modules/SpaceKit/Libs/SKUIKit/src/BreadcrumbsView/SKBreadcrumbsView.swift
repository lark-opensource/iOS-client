//
//  SKBreadcrumbsView.swift
//  SKUIKit
//
//  Created by Weston Wu on 2020/8/25.
//

import UIKit
import SnapKit
import SKResource
import class SKFoundation.DocsLogger
import UniverseDesignColor
import UniverseDesignTheme
import UniverseDesignIcon

public struct SKBreadcrumbsViewConfig {
    /// item 间的分隔图片
    public let seperatorImage: UIImage
    /// 文字字体
    public let titleFont: UIFont
    /// 可点击的文字颜色
    public let titleNormalColor: UIColor
    /// 不可点击的文字颜色
    public let titleDisableColor: UIColor
    /// 文字的最大宽度限制，nil表示不限制
    public let titleMaxWidth: CGFloat?
    /// item 间的间隔
    public let itemSpacing: CGFloat

    public init(seperatorImage: UIImage = UDIcon.rightOutlined.ud.withTintColor(UDColor.iconN3),
                titleFont: UIFont = UIFont.ct.systemRegular(ofSize: 15),
                titleNormalColor: UIColor = UDColor.primaryContentDefault,
                titleDisableColor: UIColor = UDColor.textCaption,
                titleMaxWidth: CGFloat? = nil,
                itemSpacing: CGFloat = 4) {
        self.seperatorImage = seperatorImage
        self.titleFont = titleFont
        self.titleNormalColor = titleNormalColor
        self.titleDisableColor = titleDisableColor
        self.titleMaxWidth = titleMaxWidth
        self.itemSpacing = itemSpacing
    }

    public static let `default` = SKBreadcrumbsViewConfig()
}

public protocol SKBreadcrumbItem {
    var itemID: String { get }
    var displayName: String { get }
}

public final class SKBreadcrumbsView<Item: SKBreadcrumbItem>: UIView {
    public typealias Config = SKBreadcrumbsViewConfig

    private var items: [Item] = []
    private var itemViews: [ItemView] = []
    private let config: Config

    public var currentItem: Item? {
        return items.last
    }

    /// 顶部分隔线
    private(set) public lazy var topSeperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    /// 底部分隔线
    private(set) public lazy var bottomSeperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        return view
    }()

    private lazy var scrollContentView: UIStackView = {
        let view = UIStackView(frame: .zero)
        view.alignment = .center
        view.axis = .horizontal
        view.distribution = .fill
        view.spacing = config.itemSpacing
        return view
    }()

    public var clickHandler: ((Item) -> Void)?

    public init(rootItem: Item, config: Config) {
        self.config = config
        super.init(frame: .zero)
        setupUI()
        reset(rootItem: rootItem)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBody
        // 绘制 0.5pt 线高度
        let seperatorHeight = 1 / SKDisplay.scale
        addSubview(topSeperatorView)
        topSeperatorView.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(seperatorHeight)
        }
        addSubview(bottomSeperatorView)
        bottomSeperatorView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(seperatorHeight)
        }
        addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        scrollView.addSubview(scrollContentView)
        scrollContentView.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }

    public func reset(rootItem: Item) {
        let allViews = scrollContentView.arrangedSubviews
        allViews.forEach { $0.removeFromSuperview() }
        let rootView = RootItemView(item: rootItem, config: config)
        rootView.clickHandler = { [weak self] item in
            self?.clickHandler?(item)
        }
        itemViews = [rootView]
        items = [rootItem]
        scrollContentView.addArrangedSubview(rootView)
        scrollContentView.layoutIfNeeded()
        scrollView.contentSize = scrollContentView.frame.size
    }

    public func push(item: Item) {
        let itemView = ItemView(item: item, config: config)
        itemView.clickHandler = { [weak self] item in
            self?.clickHandler?(item)
        }
        itemViews.last?.isEnabled = true
        itemViews.append(itemView)
        items.append(item)
        scrollContentView.addArrangedSubview(itemView)
        scrollContentView.layoutIfNeeded()
        scrollView.contentSize = scrollContentView.frame.size
        scrollView.scrollRectToVisible(itemView.frame, animated: true)
    }

    public func popTo(item: Item) {
        guard let index = items.firstIndex(where: { $0.itemID == item.itemID }) else {
            DocsLogger.error("Failed to locate item index in breadcrumbs view!")
            return
        }
        popTo(index: index)
    }

    public func popTo(index: Int) {
        guard index >= 0, index < items.count else {
            DocsLogger.error("Invalid index to pop to in breadcrumbs view!")
            return
        }
        let popItemsCount = items.count - index - 1
        items.removeLast(popItemsCount)
        itemViews.removeLast(popItemsCount)
        itemViews.last?.isEnabled = false
        let itemViewsToRemove = scrollContentView.arrangedSubviews.suffix(popItemsCount)
        itemViewsToRemove.forEach { $0.removeFromSuperview() }
        scrollContentView.layoutIfNeeded()
        scrollView.contentSize = scrollContentView.frame.size
    }
}

public extension SKBreadcrumbsView {

    func hideTopSeperatorView() {
        topSeperatorView.isHidden = true
    }
}

private extension SKBreadcrumbsView {

    private class ItemView: UIView {

        typealias Config = SKBreadcrumbsViewConfig

        private(set) lazy var button: UIButton = {
            let button = UIButton()
            button.setTitleColor(config.titleDisableColor, for: .disabled)
            button.setTitleColor(config.titleNormalColor, for: .normal)
            button.titleLabel?.font = config.titleFont
            button.titleLabel?.lineBreakMode = .byTruncatingMiddle
            button.setTitle(item.displayName, for: .normal)
            button.isEnabled = false
            return button
        }()

        private(set) lazy var seperatorView: UIImageView = {
            let view = UIImageView(image: config.seperatorImage)
            view.contentMode = .scaleAspectFit
            return view
        }()

        let item: Item
        let config: Config
        var clickHandler: ((Item) -> Void)?

        var isEnabled: Bool {
            get { button.isEnabled }
            set { button.isEnabled = newValue }
        }

        init(item: Item, config: Config) {
            self.item = item
            self.config = config
            super.init(frame: .zero)
            setupUI()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func setupUI() {
            addSubview(seperatorView)
            seperatorView.snp.makeConstraints { (make) in
                make.width.height.equalTo(16)
                make.left.equalToSuperview()
                make.centerY.equalToSuperview()
            }
            addSubview(button)
            button.snp.makeConstraints { (make) in
                make.top.bottom.right.equalToSuperview()
                if let maxWidth = config.titleMaxWidth {
                    make.width.lessThanOrEqualTo(maxWidth)
                }
                make.left.equalTo(seperatorView.snp.right).offset(config.itemSpacing)
            }
            button.addTarget(self, action: #selector(didClick), for: .touchUpInside)
        }

        @objc
        func didClick() {
            clickHandler?(item)
        }
    }

    private class RootItemView: ItemView {
        override func setupUI() {
            addSubview(button)
            button.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
                if let maxWidth = config.titleMaxWidth {
                    make.width.lessThanOrEqualTo(maxWidth)
                }
            }
            button.addTarget(self, action: #selector(didClick), for: .touchUpInside)
        }
    }
}
