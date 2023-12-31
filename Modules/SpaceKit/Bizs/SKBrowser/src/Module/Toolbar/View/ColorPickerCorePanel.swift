//
//  ColorPickerCorePanel.swift
//  SKBrowser
//
//  Created by 吴珂 on 2020/8/11.
//  


import Foundation
import SKUIKit
import SKResource
import RxSwift
import UniverseDesignColor
import UniverseDesignIcon

public protocol ColorPickerCorePanelDelegate: AnyObject {
    func didChooseColor(panel: ColorPickerCorePanel, color: String, isTapDetailColor: Bool)
}

public struct ColorPickerLayoutConfig {
    public let colorWellAroundMargin: CGFloat
    public let colorWellTopMargin: CGFloat
    public var colorWellHeight: CGFloat
    public let colorWellSelectedItemLength: CGFloat
    public let colorWellItemLength: CGFloat
    public let colorWellItemCornerRadius: CGFloat
    public let colorWellItemSpacing: CGFloat
    public let detailColorHeight: CGFloat
    public var defaultColorCount: CGFloat
    public var layout: SKColorWell.Layout

    public init(colorWellAroundMargin: CGFloat = 16,
                colorWellTopMargin: CGFloat = 16,
                colorWellHeight: CGFloat = 46,
                colorWellSelectedItemLength: CGFloat = 46,
                colorWellItemLength: CGFloat = 40,
                colorWellItemCornerRadius: CGFloat = 8,
                colorWellItemSpacing: CGFloat = 10,
                detailColorHeight: CGFloat = 48,
                defaultColorCount: CGFloat = 6,
                layout: SKColorWell.Layout = .singleLine) {
        self.colorWellAroundMargin = colorWellAroundMargin
        self.colorWellTopMargin = colorWellTopMargin
        self.colorWellHeight = colorWellHeight
        self.colorWellItemLength = colorWellItemLength
        self.colorWellSelectedItemLength = colorWellSelectedItemLength
        self.colorWellItemCornerRadius = colorWellItemCornerRadius
        self.colorWellItemSpacing = colorWellItemSpacing
        self.detailColorHeight = detailColorHeight
        self.defaultColorCount = defaultColorCount
        self.layout = layout
    }
}

public final class ColorPickerCorePanel: UIView {

    public enum Const {
        public static let colorReuseIdentifier = "colorReuserIdentifier"
        public static let detailColorReuseIdentifier = "detailColorReuserIdentifier"
        public static let defaultUnselectIndexPath = IndexPath(item: -1, section: -1)
    }
    
    public var colorInfos: [ColorItemNew]
    
    public lazy var colorWell = SKColorWell(delegate: self)

    public var layoutConfig: ColorPickerLayoutConfig

    public var ignoreColorWellAdditionalMargin = false
    
    private var colorWellAdditionalMargin: CGFloat = 0 {
        didSet {
            if oldValue != colorWellAdditionalMargin,
                !ignoreColorWellAdditionalMargin {
                colorWell.snp.updateConstraints { make in
                    make.leading.trailing.equalToSuperview().inset(layoutConfig.colorWellAroundMargin + colorWellAdditionalMargin)
                }
            }
        }
    }
    
    public lazy var colorDetailCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero
        let collView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collView.register(DetailColorCell.self, forCellWithReuseIdentifier: Const.detailColorReuseIdentifier)
        collView.delegate = self
        collView.dataSource = self
        collView.backgroundColor = UDColor.bgBody
        collView.isScrollEnabled = true
        return collView
    }()
    
    // section: colorWell，item: colorDetailCollectionView
    public var lastHitIndexPath: IndexPath = Const.defaultUnselectIndexPath
    
    public var didSelect: Bool {
        return lastHitIndexPath != Const.defaultUnselectIndexPath
    }
    
    public var currentIndexPath: IndexPath {
        if didSelect {
            return lastHitIndexPath
        }
        return IndexPath(row: 0, section: 0)
    }
    
    public var currentColor: String {
        didSelect ? colorInfos[lastHitIndexPath.section].colorList[lastHitIndexPath.item] : ""
    }
    
    public weak var delegate: ColorPickerCorePanelDelegate?
    
    public init(frame: CGRect,
                infos: [ColorItemNew],
                layoutConfig: ColorPickerLayoutConfig = ColorPickerLayoutConfig()) {
        self.colorInfos = infos
        self.layoutConfig = layoutConfig
        super.init(frame: frame)
        backgroundColor = UDColor.bgBody
        
        addSubview(colorWell)
        addSubview(colorDetailCollectionView)
        
        colorWell.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(layoutConfig.colorWellTopMargin)
            make.leading.trailing.equalToSuperview().inset(layoutConfig.colorWellAroundMargin)
            make.height.equalTo(layoutConfig.colorWellHeight)
        }
        
        colorDetailCollectionView.snp.makeConstraints { (make) in
            make.top.equalTo(colorWell.snp.bottom).offset(layoutConfig.colorWellAroundMargin)
            make.height.equalTo(layoutConfig.detailColorHeight)
            make.left.right.equalToSuperview().inset(layoutConfig.colorWellAroundMargin)
        }
    }

    //iPad转屏时刷新页面布局
    public func refreshViewLayout() {
        updateColorWellView(bounds: colorDetailCollectionView.bounds)
        colorWell.reloadColorWell()
        colorDetailCollectionView.collectionViewLayout.invalidateLayout()
    }

    public func updateColorWellView(bounds: CGRect) {
        guard colorInfos.count > 0 else { return }
        //固定item间距的情况下要考虑
        let colorWellCellCount = CGFloat(colorInfos.map(\.topicColor).count)
        let maxContentWidth = colorWellCellCount * layoutConfig.colorWellSelectedItemLength + layoutConfig.colorWellItemSpacing * (colorWellCellCount - 1)
        //需要显示的行数
        let lineNum = ceil(max(maxContentWidth / bounds.width, 1))
        if case .fixedSpacing = layoutConfig.layout,
           lineNum > 0 {
            layoutConfig.colorWellHeight = layoutConfig.colorWellSelectedItemLength * lineNum + layoutConfig.colorWellItemSpacing * (lineNum - 1)
            colorWell.snp.updateConstraints { (make) in
                make.height.equalTo(layoutConfig.colorWellHeight)
            }
        }
    }
    
    public func updateInfos(infos: [ColorItemNew]) {
        if canReloadPartialVisibleCells(old: colorInfos, new: infos) {
            reloadPartialVisibleCells(with: infos)
        } else {
            colorInfos = infos
            reloadData()
        }
    }
    
    public func updateInfos(info: ToolBarItemInfo) {
        var index = -1
        if let colorList = info.colorList {
            if didSelect, colorList.count > lastHitIndexPath.section, let value = info.value {
                let targetColors = colorList[lastHitIndexPath.section]
                index = targetColors.colorList.firstIndex(of: value) ?? -1
            }
            if index == -1 {
                lastHitIndexPath = info.getSelectIndexInfo()
            } else {
                lastHitIndexPath = IndexPath(item: index, section: lastHitIndexPath.section)
            }
            if canReloadPartialVisibleCells(old: colorInfos, new: colorList) {
                reloadPartialVisibleCells(with: colorList)
            } else {
                colorInfos = colorList
                reloadData()
            }
        }
    }
    
    func reloadTopicColors() {
        let topicColors = colorInfos.map(\.topicColor)
        let currentIndex = lastHitIndexPath.section
        if currentIndex >= 0 && currentIndex < topicColors.count {
            colorWell.updateColors(topicColors, currentSelectedColor: topicColors[currentIndex])
        } else {
            colorWell.updateColors(topicColors, currentSelectedColor: nil)
        }
    }
    
    func reloadPartialVisibleCells(with colorList: [ColorItemNew]) {
        colorInfos = colorList
        reloadTopicColors()
        
        let visibleIndexPath = colorDetailCollectionView.indexPathsForVisibleItems
        if visibleIndexPath.isEmpty {
            colorDetailCollectionView.reloadData()
        } else {
            for indexPath in visibleIndexPath {
                if let cell = colorDetailCollectionView.cellForItem(at: indexPath) as? DetailColorCell {
                    updateDetailColorCell(cell: cell, indexPath: indexPath)
                }
            }
        }
        isHiddenDetailColor = !didSelect
    }
    
    func canReloadPartialVisibleCells(old: [ColorItemNew], new: [ColorItemNew]) -> Bool {
        guard currentIndexPath.section < old.count,
              currentIndexPath.section < new.count else {
            return false
        }
        guard old.count == new.count,
           old[currentIndexPath.section].colorList.count == new[currentIndexPath.section].colorList.count else {
            return false
        }
        return true
    }
    
    var isHiddenDetailColor: Bool = false {
        didSet {
            colorDetailCollectionView.isHidden = isHiddenDetailColor
        }
    }
    
    @discardableResult
    public func clearColor() -> String {
        lastHitIndexPath = Const.defaultUnselectIndexPath
        reloadData()
        return ""
    }
    
    @discardableResult
    public func chooseFirstColor() -> String {
        guard let item = colorInfos.first else {
            return ""
        }
        lastHitIndexPath = IndexPath(item: item.defaultIndex, section: 0)
        reloadData()
        return item.defaultColor
    }
    
    func reloadData() {
        reloadTopicColors()
        colorDetailCollectionView.reloadData()
        isHiddenDetailColor = !didSelect
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ColorPickerCorePanel: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        lastHitIndexPath = IndexPath(item: indexPath.item, section: currentIndexPath.section)
        reloadPartialVisibleCells(with: colorInfos)
        delegate?.didChooseColor(panel: self, color: currentColor, isTapDetailColor: true)
    }
}

extension ColorPickerCorePanel: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if colorInfos.isEmpty {
            return 0
        }
        let showIndexPath = currentIndexPath
        return colorInfos[showIndexPath.section].colorList.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Const.detailColorReuseIdentifier, for: indexPath)
        if let cell = cell as? DetailColorCell {
            updateDetailColorCell(cell: cell, indexPath: indexPath)
        }
        return cell
    }
    
    func updateDetailColorCell(cell: DetailColorCell, indexPath: IndexPath) {
        let colorItem = colorInfos[currentIndexPath.section]
        indexPath.item == lastHitIndexPath.item ? cell.doSelect() : cell.unselect()
        let colorString = colorItem.colorList[indexPath.item]
        cell.backgroundColor = UIColor.docs.rgb(colorString)
        cell.isNeedDrawBorder = colorString == "#ffffff"
        let count = self.collectionView(colorDetailCollectionView, numberOfItemsInSection: 0)
        if indexPath.item == 0 {
            cell.cellType = .first
        } else if indexPath.item == count - 1 {
            cell.cellType = .last
        } else {
            cell.cellType = .normal
        }
    }
}

extension ColorPickerCorePanel: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemWidth = floor(collectionView.bounds.width / layoutConfig.defaultColorCount)
        colorWellAdditionalMargin = (itemWidth - layoutConfig.colorWellSelectedItemLength) / 2
        return CGSize(width: itemWidth, height: layoutConfig.detailColorHeight)
    }
}

extension ColorPickerCorePanel: SKColorWellDelegate {
    public var appearance: SKColorWell.Appearance {
        (length: layoutConfig.colorWellItemLength, radius: layoutConfig.colorWellItemCornerRadius)
    }

    public var layout: SKColorWell.Layout {
        layoutConfig.layout
    }

    public func didSelectColor(string: String, index: Int) {
        if lastHitIndexPath.section == index && didSelect {
            return
        }
        let item = colorInfos[index]
        lastHitIndexPath = IndexPath(item: item.defaultIndex, section: index)
        reloadPartialVisibleCells(with: colorInfos)
        delegate?.didChooseColor(panel: self, color: currentColor, isTapDetailColor: false)
    }
}

class DetailColorCell: UICollectionViewCell {
    
    enum CellType {
        case normal
        case first
        case last
    }
    
    var cellType: CellType = .normal
    
    var isNeedDrawBorder = false
    
    var selectedImageView: UIImageView
    
    var disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        selectedImageView = UIImageView()
        selectedImageView.contentMode = .center
        super.init(frame: frame)
        
        contentView.layer.masksToBounds = false
        self.layer.masksToBounds = false
        contentView.addSubview(selectedImageView)
        selectedImageView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(20)
        }
        selectedImageView.image = BundleResources.SKResource.Sheet.PickColor.icon_check_color
        contentView.docs.addHover(with: UDColor.N900.withAlphaComponent(0.1), disposeBag: disposeBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func doSelect() {
        selectedImageView.isHidden = false
    }
    
    func unselect() {
        selectedImageView.isHidden = true
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        context?.setFillColor(UDColor.bgBody.cgColor)
        context?.fill(rect)
        context?.setFillColor(backgroundColor?.cgColor ?? UDColor.bgBody.cgColor)
        switch cellType {
        case .normal:()
            context?.fill(rect)
        case .first:
            let borderPath = UIBezierPath(roundedRect: rect, byRoundingCorners: [.topLeft, .bottomLeft], cornerRadii: CGSize(width: 8, height: 8))
            context?.addPath(borderPath.cgPath)
            context?.fillPath()
        case .last:
            let borderPath = UIBezierPath(roundedRect: rect, byRoundingCorners: [.topRight, .bottomRight], cornerRadii: CGSize(width: 8, height: 8))
            context?.addPath(borderPath.cgPath)
            context?.fillPath()
        }
        
        if isNeedDrawBorder {
            var borderPath = UIBezierPath()
            let fixRect = rect.inset(by: UIEdgeInsets(top: 0.5, left: 0.5, bottom: 0.5, right: 0.5))
            if cellType == .first {
                borderPath = UIBezierPath(roundedRect: fixRect, byRoundingCorners: [.topLeft, .bottomLeft], cornerRadii: CGSize(width: 8, height: 8))
            } else {
                borderPath = UIBezierPath(rect: fixRect)
            }

            let borderColor = UDColor.N300 & UDColor.N900.withAlphaComponent(0.4)
            context?.setStrokeColor(borderColor.cgColor)
            context?.setLineWidth(1)
            context?.addPath(borderPath.cgPath)
            context?.drawPath(using: .stroke)
        }
    }
}
