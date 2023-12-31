//
//  MenuActionBar.swift
//  LarkChat
//
//  Created by 李晨 on 2019/1/29.
//

import Foundation
import UIKit
import SnapKit
import LKCommonsLogging
import LarkInteraction
import UniverseDesignColor
import LarkBadge

public struct MenuUIConfig {
    var countInLine: Int
    var imageInsets: UIEdgeInsets
    var itemSpacing: CGFloat
    var sectionInsets: UIEdgeInsets
    init(countInLine: Int = 6,
         imageInsets: UIEdgeInsets = .zero,
         itemSpacing: CGFloat = 0,
         sectionInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)) {
        self.countInLine = countInLine
        self.imageInsets = imageInsets
        self.itemSpacing = itemSpacing
        self.sectionInsets = sectionInsets
    }
}

public final class MenuActionBar: UIView {
    // MARK: public属性
    // 外部设置items
    public var items: [MenuActionItem] = [] {
        didSet {
            updateItemSize(actionBarWidth: maxActionBarWidth)
            self.collection.reloadData()
        }
    }
    public var uiConfig: MenuUIConfig = MenuUIConfig() {
        didSet {
            self.collection.reloadData()
        }
    }
    // CCM还在用这个接口，所以先保留
    public var actionIconInset: UIEdgeInsets = .zero {
        didSet {
            self.uiConfig.imageInsets = actionIconInset
        }
    }

    // ActionBar的最大宽度
    var maxActionBarWidth: CGFloat = UIScreen.main.bounds.width {
        didSet {
            updateItemSize(actionBarWidth: maxActionBarWidth)
        }
    }
    // 是否有reactionBar。
    // actionBarItem宽度计算：有actionBar，没有reactionBar，并且actionItem的个数小于一行的个数。这时一个item的宽度为默认宽度，其余情况都是计算宽度
    var hasReactionBar: Bool = true {
        didSet {
            guard oldValue != hasReactionBar else { return }
            updateItemSize(actionBarWidth: maxActionBarWidth)
            self.collection.reloadData()
        }
    }
    // MARK: private属性
    private static let logger = Logger.log(MenuActionCell.self, category: "Module.IM.Menu")
    // 展示两行文字item的高度
    private static let itemRegularHeight: CGFloat = 58
    // 展示一行文字item的高度
    private static let itemSmallerHeight: CGFloat = 45
    // 默认item宽度
    private static let itemRegularWidth: CGFloat = 52
    // 行之间的最小间距
    private static let itemMinimumLineSpacing: CGFloat = 14
    // item的实际宽度
    private var itemWidth: CGFloat = 52
    // 每一行line的高度
    private var linesHeight: [CGFloat] = []
    private var lineCount: Int {
        return self.items.count / uiConfig.countInLine + ((self.items.count % uiConfig.countInLine) > 0 ? 1 : 0)
    }
    private var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        layout.itemSize = CGSize(width: MenuActionBar.itemRegularWidth, height: MenuActionBar.itemRegularHeight)
        layout.minimumLineSpacing = MenuActionBar.itemMinimumLineSpacing
        layout.minimumInteritemSpacing = 0
        return layout
    }()

    private lazy var collection: UICollectionView = { [weak self] in
        guard let `self` = self else { return UICollectionView() }
        let collection = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.layout)
        collection.backgroundColor = UIColor.ud.bgFloat
        collection.delegate = self
        collection.dataSource = self
        collection.showsHorizontalScrollIndicator = false
        collection.showsVerticalScrollIndicator = false
        collection.register(MenuActionCell.self, forCellWithReuseIdentifier: String(describing: MenuActionCell.self))
        collection.isScrollEnabled = false
        collection.accessibilityIdentifier = "menu.action.bar.collection"
        collection.clipsToBounds = false
        return collection
    }()

    // MARK: public方法
    public init(frame: CGRect, uiConfig: MenuUIConfig? = nil) {
        if let config = uiConfig {
            self.uiConfig = config
        }
        super.init(frame: frame)
        self.addSubview(collection)
        self.backgroundColor = UIColor.ud.bgFloat
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard self.collection.frame != self.bounds else {
            return
        }
        self.collection.frame = self.bounds
        updateItemSize(actionBarWidth: self.bounds.size.width)
        self.collection.reloadData()
    }

    // actionBar的宽度
    public func getActionBarWidth() -> CGFloat {
        // 如果items个数大于一行，actionBar的宽度等于外界传进来的宽度
        if self.items.count > uiConfig.countInLine {
            return maxActionBarWidth
        } else if !self.items.isEmpty {
            // 如果items个数小于一行的个数，actionBar的宽度等于默认item的宽度乘以个数
            return MenuActionBar.itemRegularWidth * CGFloat(self.items.count) + uiConfig.sectionInsets.left + uiConfig.sectionInsets.right
        } else {
            return 0
        }
    }

    // actionBar的高度
    public func getActionBarHeight() -> CGFloat {
        if lineCount == 0 { return 0 }
        var height: CGFloat = 0
        if !linesHeight.isEmpty {
            for h in linesHeight {
                height += h
            }
        } else {
            height = CGFloat(lineCount) * MenuActionBar.itemRegularHeight
        }
        let h = height + CGFloat(lineCount - 1) * MenuActionBar.itemMinimumLineSpacing
        return h
    }

    // MARK: private方法
    private func updateItemSize(actionBarWidth: CGFloat) {
        updateItemWidth(actionBarWidth: actionBarWidth)
        updateItemHeight()
    }

    // 更新item的宽度
    // actionBarItem宽度计算：有actionBar，没有reactionBar，并且actionItem的个数小于一行的个数。这时一个item的宽度为默认宽度，其余情况都是计算宽度
    private func updateItemWidth(actionBarWidth: CGFloat) {
        guard actionBarWidth != 0 else {
            itemWidth = MenuActionBar.itemRegularWidth
            return
        }
        if !items.isEmpty, !hasReactionBar, items.count < uiConfig.countInLine {
            itemWidth = MenuActionBar.itemRegularWidth
        } else {
            // item的宽度需要计算
            // 减1是因为，在测试的时候：actionBar450的宽度，左右间隔各为4，每一个item的宽度是73.66666666666667，四舍五入会导致一行放不下
            let collectionWidth = actionBarWidth - uiConfig.sectionInsets.left - uiConfig.sectionInsets.right - 1
            if collectionWidth >= 0 {
                itemWidth = collectionWidth / CGFloat(uiConfig.countInLine)
            } else {
                itemWidth = MenuActionBar.itemRegularWidth
                assertionFailure()
            }
        }
    }

    // 更新item的高度
    private func updateItemHeight() {
        // 每一行的高度
        var lineHeightArray: [CGFloat] = []
        // 设置attribute的各个参数
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: MenuActionCell.labelFont)]
        let option = NSStringDrawingOptions.usesLineFragmentOrigin
        let maxSize: CGSize = CGSize(width: 999, height: 999)
        for _ in 0..<lineCount {
            lineHeightArray.append(MenuActionBar.itemSmallerHeight)
        }
        for i in 0..<self.items.count {
            let text = items[i].name as NSString
            let rect = text.boundingRect(with: maxSize, options: option, attributes: attributes, context: nil)
            // 11号字体一行是13.12高度
            // 例如"Multi-\nselect"，给的文案就是两行的，需要再判断高度
            if rect.width > itemWidth || rect.height > 14 {
                lineHeightArray[i / uiConfig.countInLine] = MenuActionBar.itemRegularHeight
            }
        }
        linesHeight = lineHeightArray
    }
}
// MARK: collection 的代理方法
extension MenuActionBar: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // items个数
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = self.items[indexPath.row]
        let name = String(describing: MenuActionCell.self)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: name, for: indexPath)
        if let collectionCell = cell as? MenuActionCell {
            collectionCell.item = item
            collectionCell.imageInset = uiConfig.imageInsets
        }
        cell.accessibilityIdentifier = "menu.action.bar.cell.\(indexPath.row)"
        return cell
    }

    // item点击事件
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        let item = self.items[indexPath.row]
        if item.enable {
            item.action(item)
        } else {
            item.disableAction?(item)
        }
    }

    // item是否可以点击
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let item = self.items[indexPath.row]
        return item.enable || (item.disableAction != nil)
    }

    // 是否可以高亮
    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        let item = self.items[indexPath.row]
        return item.enable || (item.disableAction != nil)
    }

    // item大小
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let indexLine = indexPath.row / uiConfig.countInLine
        if indexLine < linesHeight.count {
            return CGSize(width: itemWidth, height: linesHeight[indexLine])
        } else {
            return CGSize(width: itemWidth, height: MenuActionBar.itemRegularHeight)
        }
    }
}
