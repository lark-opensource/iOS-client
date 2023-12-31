//
//  DocsAttachedToolBarCollectionViewImpl.swift
//  DocsSDK
//
//  Created by Gill on 2020/6/8.
//  swiftlint:disable file_length

import UIKit
import SKCommon
import SKUIKit
import SKFoundation
import SKResource
import EENavigator
import UniverseDesignColor
import LarkContainer

/// 工具栏二级面板使用了两种样式
/// 一是水平、左右滑动的面板
/// 二是垂直、上下滑动的面板
/// 将具体的实现设计为一个类簇，
/// 对外开放 **DocsAttachedToolBarCollectionViewImpl** 类
/// 对内分为 **VerticalImpl**、**HorizontalImpl** 两种
/// 两个 impl 还有一些重复的，可以继续抽代码出来
class DocsAttachedToolBarCollectionViewImpl: NSObject {
    fileprivate struct Const {
        static let itemWidth: CGFloat = DocsMainToolBarV2.Const.itemWidth
        static let itemHeight: CGFloat = DocsMainToolBarV2.Const.attachedToolbarHeight
        static let imageWidth: CGFloat = 24
        static let itemHorizontalPadding: CGFloat = 6
        static let itemVerticalPadding: CGFloat = 1
        static let horPadding: CGFloat = 7
        static let staticHorPadding: CGFloat = 6
        static let separateWidth: CGFloat = 0.5
        static let separatePadding: CGFloat = 10
        static let sheetInputViewHeight: CGFloat = 44
        static let contentInset: CGFloat = 12
        static let triangleWidth: CGFloat = 28
        static let entiretyHorPadding: CGFloat = 9 //二级工具栏具体屏幕左右两边的padding
    }

    let orientation: ToolbarOrientation
    private(set) var items: [ToolBarItemInfo] = []
    fileprivate var groupedItems: [[ToolBarItemInfo]] = []
    fileprivate(set) var itemCollectionView: UICollectionView
    fileprivate var onSelect: ((UICollectionView, Int, String) -> Void)?
    fileprivate var didScroll: ((Bool, Bool) -> Void)?

    public var contentOffset: CGPoint {
        get {
            return itemCollectionView.contentOffset
        }
        set {
            guard itemCollectionView.bounds.width + floor(newValue.x) <= itemCollectionView.contentSize.width + Const.contentInset else { return }
            itemCollectionView.setContentOffset(newValue, animated: false)
        }
    }

    class func impl(for orientation: ToolbarOrientation,
                    items: [ToolBarItemInfo]) -> DocsAttachedToolBarCollectionViewImpl {
        if orientation == .horizontal {
            return DocsAttachedToolBarHorizontalImpl(orientation, items: items)
        } else {
            return DocsAttachedToolBarVerticalImpl(orientation, items: items)
        }
    }

    /// make sure that itemCollectionView
    /// was added to a super view
    /// returns whether should add side masks
    func makeConstraints(at point: CGPoint?, hostViewWidth: CGFloat) -> Bool {
        skAssertionFailure("Override this function")
        return false
    }

    func onCollectionDidSelect(_ handler: @escaping (UICollectionView, Int, String) -> Void) {
        onSelect = handler
    }

    func onCollectionDidScroll(_ handler: @escaping (Bool, Bool) -> Void) {
        didScroll = handler
    }

    public func scrollToItem(_ itemIdentifiID: String?) {
        guard let identifierID = itemIdentifiID else {
            _onCollectionDidScroll(scrollToLeft: true, scrollToRight: false)
            return
        }
        for (index, item) in groupedItems.enumerated() {
            for (subIndex, subItem) in item.enumerated() where subItem.identifier == identifierID {
                if index == 0, subIndex == 0 {
                    _onCollectionDidScroll(scrollToLeft: true, scrollToRight: false)
                } else if index == groupedItems.count - 1, subIndex == item.count - 1 {
                    _onCollectionDidScroll(scrollToLeft: false, scrollToRight: true)
                } else {
                    _onCollectionDidScroll(scrollToLeft: true, scrollToRight: false)
                }
                itemCollectionView.scrollToItem(at: IndexPath(row: subIndex, section: index), at: .centeredHorizontally, animated: false)
                break
            }
        }
    }

    fileprivate func _onCollectionDidSelect(_ collectionView: UICollectionView, at indexPath: IndexPath) {
        let item = groupedItems[indexPath.section][indexPath.row]
        if item.isSeparator {
            return
        }
        if let index = items.firstIndex(where: { return $0.identifier == item.identifier }) {
            onSelect?(collectionView, index, "")
        }
    }

    fileprivate func _onCollectionDidScroll(scrollToLeft: Bool, scrollToRight: Bool) {
        guard itemCollectionView.isScrollEnabled else {
            return
        }
        didScroll?(scrollToLeft, scrollToRight)
    }

// MARK: - Private
    fileprivate init(_ orientation: ToolbarOrientation,
                     items: [ToolBarItemInfo]) {
        self.orientation = orientation
        self.items = items
        self.itemCollectionView = Self._makeCollectionView(orientation: orientation)
        super.init()
        itemCollectionView.delegate = (self as? UICollectionViewDelegate)
        itemCollectionView.dataSource = (self as? UICollectionViewDataSource)
        _groupItems()
    }

    fileprivate class func _makeCollectionView(orientation: ToolbarOrientation) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        if orientation == .horizontal {
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = Const.itemHorizontalPadding
            layout.minimumInteritemSpacing = Const.itemHorizontalPadding
            layout.sectionInset = UIEdgeInsets(top: 0, left: Const.contentInset, bottom: 0, right: 0)
        } else {
            layout.scrollDirection = .vertical
            layout.minimumLineSpacing = Const.itemVerticalPadding
        }

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = UDColor.bgBody
        cv.layer.ud.setBorderColor(UDColor.lineBorderCard)
        cv.layer.cornerRadius = 8
        cv.layer.borderWidth = 1
        cv.layer.masksToBounds = true
        if orientation == .horizontal { //只有横着的工具栏才需要设置左右的padding
            cv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: Const.contentInset)
        }
        cv.showsVerticalScrollIndicator = false
        cv.showsHorizontalScrollIndicator = false
        return cv
    }

    // 将 Items 按照分割线分组
    // 不分组的话，分割线的 CollectionViewCell 和其他 Cell
    // 的上下 spacing 会过大，因此需要分组，然后分 Section 渲染
    private func _groupItems() {
        groupedItems.removeAll()
        var tmp: [ToolBarItemInfo] = []
        items.forEach {
            if $0.isSeparator {
                groupedItems.append(tmp)
                tmp.removeAll()
                groupedItems.append([$0])
            } else {
                tmp.append($0)
            }
        }
        groupedItems.append(tmp)
    }
}

// MARK: - DocsAttachedToolBarHorizontalImpl - 水平实现
class DocsAttachedToolBarHorizontalImpl: DocsAttachedToolBarCollectionViewImpl {

    override func makeConstraints(at point: CGPoint?, hostViewWidth: CGFloat) -> Bool {
        // 根据数量计算的长度
        let docsViewWidth = hostViewWidth

        let willWidth = items.totalWidth
        let trueWidth = items.maxWidth
        let widerThanScreen = willWidth > (docsViewWidth - 10)
        itemCollectionView.isScrollEnabled = widerThanScreen
        if widerThanScreen {
            itemCollectionView.snp.makeConstraints { (make) in
                make.top.equalToSuperview()
                make.bottom.equalToSuperview().offset(-4)
                //iPad工具栏自适应，二级菜单需要左右拉通
                if SKDisplay.pad && Const.itemWidth == 44 {
                    make.width.equalTo(trueWidth)
                    make.centerX.equalToSuperview()
                } else {
                    make.left.equalToSuperview().offset(DocsAttachedToolBarCollectionViewImpl.Const.entiretyHorPadding)
                    make.right.equalToSuperview().offset(-DocsAttachedToolBarCollectionViewImpl.Const.entiretyHorPadding)
                }
            }
        } else {
            itemCollectionView.snp.makeConstraints { (make) in
                make.top.equalToSuperview()
                make.bottom.equalToSuperview().offset(-4)
                make.width.equalTo(willWidth)
                //优化某些情况，距离左右间距较小，直接使用居中对齐即可
                if willWidth > docsViewWidth - 18 {
                    make.centerX.equalToSuperview()
                } else {
                    if let pt = point {
                        if pt.x + willWidth / 2 > docsViewWidth {
                            make.right.equalToSuperview().offset(-9)
                        } else if pt.x - willWidth / 2 < 0 {
                            make.left.equalToSuperview().offset(9)
                        } else {
                            make.centerX.equalTo(pt.x)
                        }
                    } else {
                        DocsLogger.info("Point should not be nil")
                        make.left.equalToSuperview().offset(9)
                    }
                }
            }
        }
        return widerThanScreen
    }

    override class func _makeCollectionView(orientation: ToolbarOrientation) -> UICollectionView {
        let cv = super._makeCollectionView(orientation: .horizontal)
        cv.register(DocsToolBarCell.self, forCellWithReuseIdentifier: DocsToolBarCell.reuseIdentifier)
        cv.register(DocsToolBarSeparatorCell.self, forCellWithReuseIdentifier: DocsToolBarSeparatorCell.reuseIdentifier)
        cv.register(DocsToolBarAdjustCell.self, forCellWithReuseIdentifier: DocsToolBarAdjustCell.reuseIdentifier)
        cv.register(DocsToolBarHighlightCell.self, forCellWithReuseIdentifier: DocsToolBarHighlightCell.reuseIdentifier)
        cv.register(SKColorWellCell.self, forCellWithReuseIdentifier: SKColorWellCell.reuseIdentifier)
        return cv
    }
}

extension DocsAttachedToolBarHorizontalImpl: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, FontSizeAdjustViewDelegate, DocsToolBarHighlightCellDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return groupedItems[section].count
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = groupedItems[indexPath.section][indexPath.row]
        if item.isSeparator {
            return CGSize(width: Const.separateWidth, height: Const.itemHeight)
        } else if item.isAdjustFont {
            return CGSize(width: DocsToolBarAdjustCell.suggestedWidth, height: Const.itemHeight)
        } else if item.isHighlight {
            return CGSize(width: Const.itemWidth + Const.triangleWidth, height: Const.itemHeight)
        } else {
            return CGSize(width: Const.itemWidth, height: Const.itemHeight)
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = groupedItems[indexPath.section][indexPath.row]
        let accessibilityIdentifier = "docs.comment.toolbar.attach.horizontal." + item.identifier

        if item.isAdjustFont {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DocsToolBarAdjustCell.reuseIdentifier, for: indexPath)
            if let list = item.valueList, let index = list.firstIndex(where: { $0 == item.value }) {
                (cell as? DocsToolBarAdjustCell)?.updateData(list, index: index)
            }
            (cell as? DocsToolBarAdjustCell)?.adjustViewDelegate = self
            cell.accessibilityIdentifier = accessibilityIdentifier
            return cell
        } else if item.isSeparator {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DocsToolBarSeparatorCell.reuseIdentifier, for: indexPath)
            (cell as? DocsToolBarSeparatorCell)?.set(orientation: .vertical)
            cell.accessibilityIdentifier = accessibilityIdentifier
            return cell
        } else if item.isHighlight {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DocsToolBarHighlightCell.reuseIdentifier, for: indexPath)
            if let highLightCell = cell as? DocsToolBarHighlightCell {
                if let image = item.image {
                    highLightCell.lightItUp(light: item.isSelected, image: image)
                    highLightCell.isEnabled = item.isEnable
                }
                if let json = item.valueJSON {
                    highLightCell.updateHighlightColor(for: json)
                }
                highLightCell.index = indexPath
                highLightCell.delegate = self
            }
            cell.accessibilityIdentifier = accessibilityIdentifier
            return cell
        } else if item.isMindnoteHighlight {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SKColorWellCell.reuseIdentifier, for: indexPath)
            if let mindnoteCell = cell as? SKColorWellCell, let color = item.value {
                mindnoteCell.isSelected = item.isSelected
                mindnoteCell.setupData(colorValue: color, colorSize: 24, colorRadius: 6)
            }
            cell.accessibilityIdentifier = accessibilityIdentifier
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DocsToolBarCell.reuseIdentifier, for: indexPath)
            if let cell = cell as? DocsToolBarCell {
                cell.updateAppearance(image: item.image,
                                      enabled: item.isEnable,
                                      adminLimit: item.adminLimit,
                                      selected: item.isSelected,
                                      hasChildren: false)
                // Todo
                if item.identifier == BarButtonIdentifier.highlight.rawValue {
                    if let json = item.valueJSON {
                        cell.updateHighlightColor(for: json)
                    } else if let colorValue = item.value {
                        cell.updateHighlightColor(for: colorValue)
                    }
                } else {
                    cell.contentView.backgroundColor = .clear
                }
                //颜色选择器颜色填充
                if item.identifier == BarButtonIdentifier.backColor.rawValue || item.identifier == BarButtonIdentifier.foreColor.rawValue {
                    let colorVal = (item.value ?? "#000000").lowercased()
                    cell.updateSelectColor(for: colorVal)
                } else {
                    cell.updateSelectColor(for: nil)
                }
            }
            cell.accessibilityIdentifier = accessibilityIdentifier
            return cell
        }
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return groupedItems.count
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard groupedItems[indexPath.section][indexPath.row].identifier != BarButtonIdentifier.highlight.rawValue,
              groupedItems[indexPath.section][indexPath.row].identifier != BarButtonIdentifier.fontSize.rawValue else {
                  //高亮按钮，字体大小调节按钮相关行为交由代理方法决定
                  return
              }
        _onCollectionDidSelect(collectionView, at: indexPath)
        collectionView.deselectItem(at: indexPath, animated: false)
    }

    func hasUpdateValue(cell: UICollectionViewCell, value: String) {
        guard let tmp: IndexPath = itemCollectionView.indexPath(for: cell) else { return }
        let item = groupedItems[tmp.section][tmp.row]
        if item.isSeparator {
            return
        }
        if let index = items.firstIndex(where: { return $0.identifier == item.identifier }) {
            onSelect?(itemCollectionView, index, value)
        }
    }

    func hasChooseAction(isOpenPanel: Bool, index: IndexPath) {
        let item = groupedItems[index.section][index.row]
        if var jsonValue = item.valueJSON {
            jsonValue["openPanel"] = isOpenPanel
            item.valueJSON = jsonValue
            item.updateJsonString(value: jsonValue)
        }
        _onCollectionDidSelect(itemCollectionView, at: index)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x <= 0.0 {
            //滚动到左侧顶部
            _onCollectionDidScroll(scrollToLeft: true, scrollToRight: false)
        } else if abs(scrollView.contentSize.width - scrollView.frame.width - scrollView.contentOffset.x) < Const.itemWidth {
            //滚动到右侧顶部
            _onCollectionDidScroll(scrollToLeft: false, scrollToRight: true)
        } else {
            //其他情况显示和滚动到左侧顶部一致
            _onCollectionDidScroll(scrollToLeft: true, scrollToRight: false)
        }
    }
}

// MARK: - DocsAttachedToolBarVerticalImpl - 垂直实现
class DocsAttachedToolBarVerticalImpl: DocsAttachedToolBarCollectionViewImpl {
    var textMaxLength: CGFloat = 0.0
    let innerPadding: CGFloat = 11

    fileprivate var textCellMaxWidth: CGFloat {
        typealias C = DocsToolBarDetailCell.Const
        return C.bgHorizontalInset + C.iconLeftInset + DocsToolBar.Const.imageWidth + C.iconTitleSpacing + textMaxLength + C.titleRightInset + C.bgHorizontalInset
    }

    override func makeConstraints(at point: CGPoint?, hostViewWidth: CGFloat) -> Bool {
        self.textMaxLength = items.reduce(0, { (accumulatedWidth, info) -> CGFloat in
            max(accumulatedWidth, info.titleDisplayLength)
        })
        let docsViewWidth = hostViewWidth
        let realWidth = max(textCellMaxWidth, DocsToolBarAdjustCell.suggestedWidth)
        itemCollectionView.snp.makeConstraints { (make) in
            make.width.equalTo(realWidth)
            make.bottom.equalToSuperview().offset(-4)
            make.height.equalTo(items.totalHeight)
            if let pt = point {
                if pt.x + realWidth / 2 > docsViewWidth {
                    make.right.equalToSuperview().offset(-9)
                } else if pt.x - realWidth / 2 < 0 {
                    make.left.equalToSuperview().offset(9)
                } else {
                    make.centerX.equalTo(pt.x)
                }
            } else {
                make.left.equalToSuperview().offset(9)
            }
        }
        return false
    }

    override class func _makeCollectionView(orientation: ToolbarOrientation) -> UICollectionView {
        let cv = super._makeCollectionView(orientation: .vertical)
        cv.register(DocsToolBarDetailCell.self, forCellWithReuseIdentifier: DocsToolBarDetailCell.reuseIdentifier)
        cv.register(DocsToolBarSeparatorCell.self, forCellWithReuseIdentifier: DocsToolBarSeparatorCell.reuseIdentifier)
        cv.register(DocsToolBarAdjustCell.self, forCellWithReuseIdentifier: DocsToolBarAdjustCell.reuseIdentifier)
        return cv
    }
}

extension DocsAttachedToolBarVerticalImpl: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return groupedItems[section].count
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = groupedItems[indexPath.section][indexPath.row]
        if item.isSeparator {
            return CGSize(width: collectionView.frame.width, height: Const.separateWidth)
        } else {
            return CGSize(width: collectionView.frame.width, height: Const.itemHeight)
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let item = groupedItems[indexPath.section][indexPath.row]
        let accessibilityIdentifier  = "docs.comment.toolbar.attach.vertical." + item.identifier

        if item.isAdjustFont {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DocsToolBarAdjustCell.reuseIdentifier, for: indexPath)
            if let list = item.valueList, let index = list.firstIndex(where: { $0 == item.value }) {
                (cell as? DocsToolBarAdjustCell)?.updateData(list, index: index)
            }
            cell.accessibilityIdentifier = accessibilityIdentifier
            return cell
        } else if item.isSeparator {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DocsToolBarSeparatorCell.reuseIdentifier, for: indexPath)
            (cell as? DocsToolBarSeparatorCell)?.set(orientation: .horizontal)
            cell.accessibilityIdentifier = accessibilityIdentifier
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DocsToolBarDetailCell.reuseIdentifier, for: indexPath)
            if let image = item.image {
                (cell as? DocsToolBarDetailCell)?.lightItUp(light: item.isSelected, image: image, title: item.title)
                (cell as? DocsToolBarDetailCell)?.isEnabled = item.isEnable
            }
            //颜色选择器颜色填充
            if item.identifier == BarButtonIdentifier.backColor.rawValue || item.identifier == BarButtonIdentifier.foreColor.rawValue {
                let colorVal = (item.value ?? "#ffffff").lowercased()
                (cell as? DocsToolBarDetailCell)?.updateSelectColor(for: colorVal)
            } else {
                (cell as? DocsToolBarDetailCell)?.updateSelectColor(for: nil)
            }
            cell.accessibilityIdentifier = accessibilityIdentifier
            return cell
        }
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return groupedItems.count
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        _onCollectionDidSelect(collectionView, at: indexPath)
        collectionView.deselectItem(at: indexPath, animated: false)
    }
}

// MARK: - Private Extension
// 这里都是计算属性，小心使用
extension Array where Element == ToolBarItemInfo {
    var totalHeight: CGFloat {
        let heightOfItems = CGFloat(countOfItems + countOfAdjustFont) * DocsAttachedToolBarCollectionViewImpl.Const.itemHeight
        let heightOfSeparators = CGFloat(countOfSeparator) * DocsAttachedToolBarCollectionViewImpl.Const.separateWidth
        let heightOfPadding = CGFloat(countOfItems + countOfAdjustFont - countOfSeparator - 1) * DocsAttachedToolBarCollectionViewImpl.Const.itemVerticalPadding
        return heightOfItems + heightOfSeparators + heightOfPadding
    }
}
fileprivate extension Array where Element == ToolBarItemInfo {
    var countOfSeparator: Int {
        filter { return $0.isSeparator }.count
    }

    var countOfAdjustFont: Int {
        filter { return $0.isAdjustFont }.count
    }

    var countOfHighlight: Int {
        filter { return $0.isHighlight }.count
    }

    var countOfItems: Int {
        count - countOfSeparator - countOfAdjustFont - countOfHighlight
    }

    var groudedItemsCount: Int {
        countOfSeparator * 2 + 1
    }

    var totalWidth: CGFloat {
        let widthOfItems = CGFloat(countOfItems) * DocsAttachedToolBarCollectionViewImpl.Const.itemWidth
        let widthOfSeparators = CGFloat(countOfSeparator) * DocsAttachedToolBarCollectionViewImpl.Const.separateWidth
        let widthOfAdjustFont = CGFloat(countOfAdjustFont) * DocsToolBarAdjustCell.suggestedWidth
        let widthOfHighlight = CGFloat(countOfHighlight) * (DocsAttachedToolBarCollectionViewImpl.Const.itemWidth + DocsAttachedToolBarCollectionViewImpl.Const.triangleWidth)
        let sessionPadding = CGFloat(groudedItemsCount) * DocsAttachedToolBarCollectionViewImpl.Const.contentInset
        let widthOfPaddings = CGFloat(count - groudedItemsCount) * DocsAttachedToolBarCollectionViewImpl.Const.itemHorizontalPadding + sessionPadding
        return widthOfItems + widthOfSeparators + widthOfAdjustFont + widthOfHighlight + widthOfPaddings + DocsAttachedToolBarCollectionViewImpl.Const.contentInset
    }

    var maxWidth: CGFloat { //仅用于iPad侧超出屏幕宽度时进行的计算
        var count: CGFloat = 6.0
        let ur = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        let docsViewWidth = ur.docs.editorManager?.currentEditor?.frame.width ?? SKDisplay.activeWindowBounds.width
        count = floor(docsViewWidth / (DocsAttachedToolBarCollectionViewImpl.Const.itemWidth + DocsAttachedToolBarCollectionViewImpl.Const.itemHorizontalPadding)) - 2
        let widthOfItems = (count + 0.5) * DocsAttachedToolBarCollectionViewImpl.Const.itemWidth
        let widthOfPaddings = count * DocsAttachedToolBarCollectionViewImpl.Const.itemHorizontalPadding
        return widthOfItems + widthOfPaddings + 12
    }
}

fileprivate extension ToolBarItemInfo {
    var isSeparator: Bool {
        return identifier == BarButtonIdentifier.separator.rawValue
    }
    var isAdjustFont: Bool {
        return identifier == BarButtonIdentifier.fontSize.rawValue
    }

    var isHighlight: Bool {
        return identifier == BarButtonIdentifier.highlight.rawValue
    }

    var isMindnoteHighlight: Bool {
        return identifier == BarButtonIdentifier.mnHighlight1.rawValue
            || identifier == BarButtonIdentifier.mnHighlight2.rawValue
            || identifier == BarButtonIdentifier.mnHighlight3.rawValue
            || identifier == BarButtonIdentifier.mnHighlight4.rawValue
            || identifier == BarButtonIdentifier.mnHighlight5.rawValue
            || identifier == BarButtonIdentifier.mnHighlight6.rawValue
            || identifier == BarButtonIdentifier.mnHighlight7.rawValue
    }

    var titleDisplayLength: CGFloat {
        return title?.estimatedSingleLineUILabelWidth(in: DocsToolBarDetailCell.Const.titleFont) ?? 0.0
    }
}
