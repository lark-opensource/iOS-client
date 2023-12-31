//
//  BlockEditMenuView.swift
//  SKDoc
//
//  Created by zoujie on 2021/1/24.
// swiftlint:disable file_length

import SKFoundation
import SKResource
import SKUIKit
import UniverseDesignColor
import UIKit

public final class BlockEditMenuView: BlockMenuBaseView {
    private var data: [BlockMenuItem] = []
    private var horizontalData: [BlockMenuItem] = []
    private var collectionView: UICollectionView
    private let layout = StrictCollectionViewLayout().construct { (ct) in
        ct.minimumLineSpacing = 8
        ct.minimumInteritemSpacing = 4
    }

    private let reuseIdentifier: String = "com.bytedance.ee.docs.blockEditMenuVertical"
    private let horizontalView: BlockEditMenuHorizontalView

    private let verticalView: UIView = {
        let view = UIView()
        return view
    }()

   public init() {
        self.collectionView = UICollectionView(frame: .zero,
                                               collectionViewLayout: layout)
        collectionView.delaysContentTouches = false
        collectionView.backgroundColor = UDColor.bgBody
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.clipsToBounds = false
        collectionView.register(IconAloneCell.self,
                                forCellWithReuseIdentifier: BlockMenuConst.iconAloneCellID)
        collectionView.register(MenuGroupCell.self,
                                forCellWithReuseIdentifier: BlockMenuConst.menuGroupCellID)
        collectionView.register(DocsToolBarHighlightCell.self,
                                forCellWithReuseIdentifier: BlockMenuConst.highlightCellID)
        collectionView.isScrollEnabled = false
        self.horizontalView = BlockEditMenuHorizontalView(frame: .zero)
        super.init(shouldShowDropBar: true, isNewMenu: true)
        menuLevel = 1
        collectionView.dataSource = self
        collectionView.delegate = self
        addSubView()
    }

    private func addSubView() {
        contentView.addSubview(horizontalView)
        contentView.addSubview(collectionView)

        horizontalView.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(BlockMenuConst.cellHeight)
        }

        collectionView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(horizontalView.snp.bottom).offset(8)
        }
    }

    var isPad: Bool {
        return SKDisplay.pad &&
        menuWidth >= BlockMenuConst.menuMaxWidthForIPad
    }
    
    var blockEditMinimumInteritemSpacing: CGFloat {
        if isPad {
            return 8
        } else {
            return 4
        }
    }
    
    private func countCellWidth() {
        let contentWidth = menuWidth - 2 * menuPadding

        if menuWidth >= BlockMenuConst.menuMaxWidthForIPad {
            BlockMenuConst.cellWidth = 48
            return
        }
        var compensatoryWidth: CGFloat = 0
        if isPad {
            compensatoryWidth = 2
        }
        let containsHighlightItem = self.data.contains { $0.id == BlockMenuV2Identifier.highlight.rawValue }
        let arrowWidth: CGFloat = containsHighlightItem ? BlockMenuConst.highLightCellArrowWidth : 0
        //面板中三行的图标尺寸保持一致，每个图标在下图中示意为红色矩形，高度固定为 48 ，宽度根据屏幕宽度动态计算。宽度计算方式：根据第二行图标来进行计算，公式如下 （Block 菜单面板宽度-两边橙色间距之和2*8-组内绿色间距3*1-组间的蓝色间距4*2）/ 6
        let width = ((contentWidth -
                      (3 * BlockMenuConst.groupSeparatorWidth +
                       arrowWidth +
                       compensatoryWidth +
                       2 * blockEditMinimumInteritemSpacing)) / 6)
        BlockMenuConst.cellWidth = floor(width * 10) / 10 //保留一位小数
        DocsLogger.info("blockmenu countCellWidth, containsHighlightItem:\(containsHighlightItem), cellWidth: \(BlockMenuConst.cellWidth)")
    }

    public override func setMenus(data: [BlockMenuItem]) {
        DocsLogger.info("block menu setItems")
        let verticalData = data.filter({ (item) -> Bool in
            return item.id != BlockMenuV2Identifier.textBlockTransform.rawValue
        })
        let horizontalData = data.filter({ (item) -> Bool in
            return item.id == BlockMenuV2Identifier.textBlockTransform.rawValue
        })
        //要做数据diff
        let needUpdateVerticalData = (self.data != verticalData || !self.isShow)
        let needUpdateHorizontalData = (self.horizontalData != horizontalData || !self.isShow)

        guard !self.isShow || needUpdateVerticalData || needUpdateHorizontalData else { return }

        if needUpdateVerticalData {
            //更新竖向数据
            self.data = verticalData
            countMenuSize()
            reloadItems()
        }

        if needUpdateHorizontalData {
            //更新横向数据
            self.horizontalData = horizontalData
            countMenuSize()
            horizontalView.setMenu(data: horizontalData)
        }
    }

    override func countMenuSize() {
        guard let superview = self.superview else { return }
        let maxMenuWidth = superview.frame.width - 2 * menuMargin - 2 * offsetLeft - (delegate?.getCommentViewWidth ?? 0)
        var lineCellNum: CGFloat = 6
        var lineNum: CGFloat = 1
        if maxMenuWidth >= BlockMenuConst.menuMaxWidthForIPad {
            menuWidth = BlockMenuConst.menuMaxWidthForIPad
            menuWidth = max(prepareSize.width, menuWidth)
            lineCellNum = 11
            BlockMenuConst.cellWidth = 48
        } else {
            menuWidth = maxMenuWidth
            menuWidth = max(prepareSize.width, menuWidth)
            countCellWidth()
            lineNum = 2
        }

        horizontalView.hostViewWidth = menuWidth

        //需要加上BlockEditMenuHorizontalView这一行
        let top: CGFloat = 32 // 距离顶部的距离
        let bottom: CGFloat = 8 // 距离底部的距离
        let margin: CGFloat = 8 // 每一行的间距
        menuHeight = (lineNum + 1) * BlockMenuConst.cellHeight + lineNum * margin + top + bottom

        menuHeight = min(prepareSize.height, menuHeight)
        super.countMenuSize()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func reloadItems() {
        DocsLogger.info("block menu cell width:\(BlockMenuConst.cellWidth)")
        layout.minimumInteritemSpacing = blockEditMinimumInteritemSpacing
        UIView.performWithoutAnimation {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
            CATransaction.commit()
        }
    }

    public func getCellFrame(byToolBarItemID: String) -> CGRect? {
        //通过ToolBarItemID去获取对应cell的frame
        let cellAccessibilityIdentifierID = BlockMenuConst.cellIdentifierPrefix + byToolBarItemID
        let cellArr = collectionView.visibleCells
        for cell in cellArr where cell.accessibilityIdentifier == cellAccessibilityIdentifierID {
            return cell.convert(cell.bounds, to: self)
        }
        return nil
    }

    private func countGroupCellWidth(items: [BlockMenuItem]?) -> CGFloat {
        var width: CGFloat = 0
        guard let members = items else { return width }
        width = CGFloat(members.count) * BlockMenuConst.cellWidth + CGFloat(members.count - 1) * BlockMenuConst.groupSeparatorWidth
        return width
    }

    public override func refreshLayout() {
        layoutIfNeeded()
        countMenuSize()
        horizontalView.refreshLayout()
        super.refreshLayout()
        reloadItems()
    }

    public override func scale(leftOffset: CGFloat, isShrink: Bool = true) {
        let currentOffset = isShrink ? leftOffset : 0
        guard offsetLeft != currentOffset else { return }
        offsetLeft = currentOffset
        layoutIfNeeded()
        countMenuSize()
        horizontalView.refreshLayout()
        layout.invalidateLayout()
        super.scale(leftOffset: leftOffset, isShrink: isShrink)
        let cell = collectionView.visibleCells.first(where: { (cell) -> Bool in
            return cell is DocsToolBarHighlightCell
        })
        guard let highLightCell = cell as? DocsToolBarHighlightCell else { return }
        highLightCell.updateFrame(highlightColorViewSize: CGSize(width: BlockMenuConst.cellWidth, height: BlockMenuConst.cellHeight),
                                  selectViewWidth: BlockMenuConst.highLightCellArrowWidth)
    }
}

extension BlockEditMenuView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: BlockMenuConst.iconAloneCellID, for: indexPath)

        guard indexPath.row < data.count else { return collectionViewCell }
        let item = data[indexPath.row]

        collectionViewCell.accessibilityIdentifier = BlockMenuConst.cellIdentifierPrefix + item.id
        if item.type == .group {
            let groupCell = collectionView.dequeueReusableCell(withReuseIdentifier: BlockMenuConst.menuGroupCellID, for: indexPath)
            guard let cell: MenuGroupCell = groupCell as? MenuGroupCell else { return collectionViewCell }
            cell.accessibilityIdentifier = BlockMenuConst.cellIdentifierPrefix + item.id
            cell.setItems(blockMenuItem: item)
            return cell
        }

        if item.id == BlockMenuV2Identifier.highlight.rawValue {
            let highlightCell = collectionView.dequeueReusableCell(withReuseIdentifier: BlockMenuConst.highlightCellID, for: indexPath)
            guard let cell: DocsToolBarHighlightCell = highlightCell as? DocsToolBarHighlightCell else { return collectionViewCell }
            cell.accessibilityIdentifier = BlockMenuConst.cellIdentifierPrefix + item.id
            if let image = item.loadImage() {
                let selected = (item.selected ?? false) && (item.enable ?? true)
                cell.updateFrame(highlightColorViewSize: CGSize(width: BlockMenuConst.cellWidth, height: BlockMenuConst.cellHeight),
                                 selectViewWidth: BlockMenuConst.highLightCellArrowWidth)
                cell.setViewBackgroundColor(colorViewBgColor: selected ? UDColor.colorfulBlue.withAlphaComponent(0.1) : UDColor.bgBodyOverlay,
                                            colorViewHighlightBgColor: selected ? UDColor.B900.withAlphaComponent(0.16) : UDColor.N300,
                                            selectViewBgColor: selected ? UDColor.colorfulBlue.withAlphaComponent(0.15) : UDColor.bgFiller,
                                            selectViewHighlightBgColor: selected ? UDColor.B800.withAlphaComponent(0.22) : UDColor.N400)
                cell.lightItUp(light: selected, image: image)
                cell.updateHighlightIcon(20)
                cell.isEnabled = item.enable ?? true
                cell.index = indexPath
                let params: [String: Any] = ["background": ["value": item.backgroundColor?.filter {
                    $0.key != "key"
                }],
                "text": ["value": item.foregroundColor?.filter {
                    $0.key != "key"
                }]]
                cell.updateHighlightColor(for: params)
                cell.delegate = self
            }
            return cell
        }

        guard let cell: IconAloneCell = collectionViewCell as? IconAloneCell else { return collectionViewCell }
        if let image = item.loadImage() {
            cell.update(light: item.selected ?? false, enable: item.enable ?? false, backgroundColor: UDColor.bgBodyOverlay, image: image)
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard indexPath.row < data.count else { return CGSize(width: 0, height: 0) }
        let item = data[indexPath.row]
        if item.type == .group {
            return CGSize(width: countGroupCellWidth(items: item.members), height: BlockMenuConst.cellHeight)
        }

        if item.id == BlockMenuV2Identifier.highlight.rawValue {
            var compensatoryWidth: CGFloat = 0
            if isPad {
                compensatoryWidth = 2
            }
            return CGSize(width: BlockMenuConst.cellWidth + compensatoryWidth + BlockMenuConst.highLightCellArrowWidth, height: BlockMenuConst.cellHeight)
        }

        return CGSize(width: BlockMenuConst.cellWidth, height: BlockMenuConst.cellHeight)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.row < data.count else { return }
        let item = data[indexPath.row]

        guard item.enable ?? true else { return }
        //group类型交给组内处理
        if item.type == .group || item.type == .separator || item.id == BlockMenuV2Identifier.highlight.rawValue {
            return
        }
        item.action?()
        clearAllCellPointer()
    }
    
    func clearAllCellPointer() {
        let cells = self.collectionView.visibleCells
        for cell in cells {
            if let aCell = cell as? MenuGroupCell {
                aCell.removeAllPointer()
            }
            if let aCell = cell as? IconAloneCell {
                aCell.docs.removeAllPointer()
            }
        }
    }
}

extension BlockEditMenuView: DocsToolBarHighlightCellDelegate {
    public func hasChooseAction(isOpenPanel: Bool, index: IndexPath) {
        let item = data[index.row]
        let params: [String: Any] = ["clickDropdown": isOpenPanel]
        //高亮色cell点击处理
        delegate?.didClickedItem(item, blockMenuPanel: self, params: params)
    }
}

class BlockEditMenuHorizontalView: UIView {
    public var hostViewWidth: CGFloat = 0
    private var data: [BlockMenuItem] = []
    private var realData: [BlockMenuItem] = []
    var groupItems: [[BlockMenuItem]] = []
    public let collectionView: UICollectionView
    private let layout = UICollectionViewFlowLayout().construct { (ct) in
        ct.scrollDirection = .horizontal
    }

    private lazy var leftMaskView = UIView(frame: CGRect(x: 0, y: 0, width: 56, height: 52)).construct { it in
        let layer = CAGradientLayer()
        layer.position = it.center
        layer.bounds = it.bounds
        it.layer.addSublayer(layer)
        it.isUserInteractionEnabled = false
        layer.ud.setColors([
            UDColor.bgBody.withAlphaComponent(0.94),
            UDColor.bgBody.withAlphaComponent(0.70),
            UDColor.bgBody.withAlphaComponent(0.00)
        ])
        layer.locations = [0, 0.63, 1]
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.needsDisplayOnBoundsChange = true
    }
    
    private lazy var rightMaskView = UIView(frame: CGRect(x: 0, y: 0, width: 56, height: 52)).construct { it in
        let layer = CAGradientLayer()
        layer.position = it.center
        layer.bounds = it.bounds
        it.layer.addSublayer(layer)
        it.isUserInteractionEnabled = false
        layer.ud.setColors([
            UDColor.bgBody.withAlphaComponent(0.00),
            UDColor.bgBody.withAlphaComponent(0.70),
            UDColor.bgBody.withAlphaComponent(0.94)
        ])
        layer.locations = [0, 0.37, 1]
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.needsDisplayOnBoundsChange = true
    }

    private let reuseIdentifier: String = "com.bytedance.ee.docs.blockEditMenuHorizontal"

    var isPad: Bool {
        return SKDisplay.pad &&
        hostViewWidth >= BlockMenuConst.menuMaxWidthForIPad
    }
    override init(frame: CGRect) {
        self.collectionView = UICollectionView(frame: .zero,
                                               collectionViewLayout: layout)
        collectionView.delaysContentTouches = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isScrollEnabled = true
        collectionView.register(IconAloneCell.self,
                                forCellWithReuseIdentifier: BlockMenuConst.iconAloneCellID)
        collectionView.register(BlockMenuHnCell.self,
                                forCellWithReuseIdentifier: BlockMenuConst.hnCellID)
        collectionView.register(BlockMenuSeparatorCell.self,
                                forCellWithReuseIdentifier: BlockMenuConst.separatorCellID)
        collectionView.backgroundColor = .clear
        super.init(frame: frame)
        collectionView.delegate = self
        collectionView.dataSource = self
        _addSubView()
        updateCanScrollTips()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func _addSubView() {
        addSubview(collectionView)
        addSubview(leftMaskView)
        addSubview(rightMaskView)

        leftMaskView.snp.makeConstraints { (make) in
            make.width.equalTo(BlockMenuConst.cellWidth + 8)
            make.height.equalTo(52)
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        rightMaskView.snp.makeConstraints { (make) in
            make.width.equalTo(BlockMenuConst.cellWidth + 8)
            make.height.equalTo(52)
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    public func setMenu(data: [BlockMenuItem]) {
        self.data = data.first?.members ?? []
        moveSpecialCell()
        reloadItem()
    }

    private func updateScrollViewFrame() {
        leftMaskView.snp.updateConstraints { (make) in
            make.width.equalTo(BlockMenuConst.cellWidth + 8)
        }
        rightMaskView.snp.updateConstraints { (make) in
            make.width.equalTo(BlockMenuConst.cellWidth + 8)
        }
        layoutIfNeeded()
        leftMaskView.layer.sublayers?.forEach { layer in
            if layer is CAGradientLayer {
                layer.position = leftMaskView.bounds.center
                layer.bounds = leftMaskView.bounds
            }
        }
        rightMaskView.layer.sublayers?.forEach { layer in
            if layer is CAGradientLayer {
                layer.position = rightMaskView.bounds.center
                layer.bounds = rightMaskView.bounds
            }
        }
    }

    ///左右遮罩view的显示隐藏逻辑
    func updateCanScrollTips() {
        updateScrollViewFrame()
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) {
            let contentWidth = self.collectionView.contentSize.width
            let frameWidth = self.collectionView.frame.size.width
            let offsetX = self.collectionView.contentOffset.x
            DocsLogger.info("block edit menu scroll contentWidth:\(contentWidth), frameWidth:\(frameWidth), offsetX:\(offsetX), cellWidth:\(BlockMenuConst.cellWidth)")
            if contentWidth > frameWidth {
                if offsetX <= 0 {
                    self.leftMaskView.isHidden = true
                    self.rightMaskView.isHidden = false
                } else if floor(offsetX + frameWidth) < floor(contentWidth) { //在某些特殊机型下contentWidth的宽度会是很奇怪的*.000000001之类的
                    self.leftMaskView.isHidden = false
                    self.rightMaskView.isHidden = false
                } else if floor(offsetX + frameWidth) >= floor(contentWidth) {
                    self.leftMaskView.isHidden = false
                    self.rightMaskView.isHidden = true
                }
            } else {
                self.rightMaskView.isHidden = true
                self.leftMaskView.isHidden = true
            }
        }
    }

    ///pad 在 c模式下有hn的情况下要移除h4，h5
    @discardableResult
    private func moveSpecialCell() -> Bool {
        let needReloadData = realData.count != self.data.count
        realData = self.data
        if SKDisplay.pad &&
            hostViewWidth < BlockMenuConst.menuMaxWidthForIPad {
            let hn = self.realData.first { (item) -> Bool in
                return item.id == BlockMenuV2Identifier.hn.rawValue
            }
            if hn != nil {
                self.realData = self.realData.filter { (item) -> Bool in
                    return item.id != BlockMenuV2Identifier.h4.rawValue &&
                        item.id != BlockMenuV2Identifier.h5.rawValue
                }
            }
        }
        let oldCount = groupItems.flatMap { $0 }.count
        guard let groupItems = self.realData.aggregateByGroupID() as? [[BlockMenuItem]] else { return false }
        self.groupItems = groupItems
        let newCount = groupItems.flatMap { $0 }.count
        return needReloadData || oldCount != newCount
    }

    private func reloadItem() {
        UIView.performWithoutAnimation {
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
        }
        updateCanScrollTips()
    }

    ///iPad分屏转屏时刷新布局
    public func refreshLayout() {
        if moveSpecialCell() {
            reloadItem()
        } else {
            collectionView.collectionViewLayout.invalidateLayout()
            updateCanScrollTips()
        }
    }
}

extension BlockEditMenuHorizontalView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCanScrollTips()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section < groupItems.count {
           return groupItems[section].count
        }
        return 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return groupItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: BlockMenuConst.iconAloneCellID, for: indexPath)
        guard indexPath.section < groupItems.count,
              indexPath.row < groupItems[indexPath.section].count else {
                return collectionViewCell
        }
        let items = groupItems[indexPath.section]
        let item = items[indexPath.row]
        let position = BlockHorizontalCellPosition.converToPisition(rows: items.count, indexPath: indexPath)
        collectionViewCell.accessibilityIdentifier = BlockMenuConst.cellIdentifierPrefix + item.id
        if item.id == BlockMenuV2Identifier.hn.rawValue {
            let hnCell = collectionView.dequeueReusableCell(withReuseIdentifier: BlockMenuConst.hnCellID, for: indexPath)
            guard let cell: BlockMenuHnCell = hnCell as? BlockMenuHnCell else { return collectionViewCell }
            cell.accessibilityIdentifier = BlockMenuConst.cellIdentifierPrefix + item.id
            if let image = item.loadImage() {
                cell.update(light: item.selected ?? false, enable: item.enable ?? true, image: image)
            }
            cell.update(position)
            return cell
        }

        if item.id == BlockMenuV2Identifier.separator.rawValue {
            let separatorCell = collectionView.dequeueReusableCell(withReuseIdentifier: BlockMenuConst.separatorCellID, for: indexPath)

            guard let cell: BlockMenuSeparatorCell = separatorCell as? BlockMenuSeparatorCell else {
                return collectionViewCell
            }
            return cell
        }

        guard let cell: IconAloneCell = collectionViewCell as? IconAloneCell else { return collectionViewCell }
        cell.update(position)
        if let image = item.loadImage() {
            cell.update(light: item.selected ?? false, enable: item.enable ?? true, backgroundColor: UDColor.bgBodyOverlay, image: image)
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.section < groupItems.count,
              indexPath.row < groupItems[indexPath.section].count else {
                return
        }
        let items = groupItems[indexPath.section]
        guard items[indexPath.row].enable ?? true else { return }
        let item = items[indexPath.row]
        guard item.type != .separator else {
            return
        }
        collectionView.deselectItem(at: indexPath, animated: false)
        item.action?()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard indexPath.section < groupItems.count,
              indexPath.row < groupItems[indexPath.section].count else {
                return CGSize(width: 0, height: 0)
        }
        let items = groupItems[indexPath.section]
        let item = items[indexPath.row]
        if item.id == BlockMenuV2Identifier.hn.rawValue {
            return CGSize(width: BlockMenuConst.cellWidth + BlockMenuConst.hnCellArrowWidth, height: BlockMenuConst.cellHeight)
        }

        if item.id == BlockMenuV2Identifier.separator.rawValue {
            return CGSize(width: BlockMenuConst.blockEditMenuSeparatorWidth, height: BlockMenuConst.cellHeight)
        }

        return CGSize(width: BlockMenuConst.cellWidth, height: BlockMenuConst.cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let sections = self.numberOfSections(in: collectionView)
        let inset: CGFloat = isPad ? 4 : 2
        let isLast = (section == sections - 1)
        return UIEdgeInsets(top: 0, left: section != 0 ? inset : 0, bottom: 0, right: isLast ? 0: inset)
    }
}


class BlockMenuSeparatorCell: UICollectionViewCell {
    private let separator: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpView() {
        contentView.addSubview(separator)

        separator.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalTo(0.5)
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
        }
    }
}
