//
// Created by duanxiaochen.7 on 2021/9/15.
// Affiliated with SKBrowser.
//
// Description: 颜色选择器 SKColorWell 及其用到的 cell

import UniverseDesignColor
import RxSwift
import UIKit

public protocol SKColorWellDelegate: AnyObject {
    var appearance: SKColorWell.Appearance { get }
    var layout: SKColorWell.Layout { get }
    func didSelectColor(string: String, index: Int)
}

public final class SKColorWell: UIView {

    /// The appearance of unselected items
    public typealias Appearance = (length: CGFloat, radius: CGFloat)

    /// How items are placed
    public enum Layout {

        /// all items will be squashed into one line, separated by even space
        case singleLine

        /// number of items in one line is fixed, items have equal horizontal and vertical spacing
        case fixedNumber(itemsPerLine: Int)

        /// horizontal and vertical spacing between items is fixed, number of items per line is calculated, items are overall leading aligned
        case fixedSpacing(itemSpacing: CGFloat)
    }

    private weak var delegate: SKColorWellDelegate?

    private var selectedIndexPath = IndexPath(item: -1, section: 0)

    private var colorsArray: [String] = []

    private lazy var colorWell: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        let well = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        well.register(SKColorWellCell.self, forCellWithReuseIdentifier: SKColorWellCell.reuseIdentifier)
        well.isScrollEnabled = false
        well.backgroundColor = .clear
        well.delegate = self
        well.dataSource = self
        well.showsVerticalScrollIndicator = false
        well.showsHorizontalScrollIndicator = false
        return well
    }()
    
    public init(delegate: SKColorWellDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)
        addSubview(colorWell)
        colorWell.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    public func updateColors(_ colors: [String], currentSelectedColor: String?) {
        colorsArray = colors
        selectedIndexPath = IndexPath(item: -1, section: 0)
        for (index, colorValue) in colorsArray.enumerated() where colorValue == currentSelectedColor {
            selectedIndexPath = IndexPath(item: index, section: 0)
        }
        reloadColorWell()
    }

    public func reloadColorWell() {
        colorWell.reloadData()
        colorWell.collectionViewLayout.invalidateLayout()
    }
    
    public func refreshColorWellLayout() {
        colorWell.collectionViewLayout.invalidateLayout()
    }
    
    public func reloadColorWellData() {
        colorWell.reloadData()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension SKColorWell: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colorsArray.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SKColorWellCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? SKColorWellCell, let normalItemLength = delegate?.appearance.length, let normalCornerRadius = delegate?.appearance.radius {
            cell.isSelected = (self.selectedIndexPath == indexPath)
            if indexPath.item < colorsArray.count {
                cell.setupData(colorValue: colorsArray[indexPath.item], colorSize: normalItemLength, colorRadius: normalCornerRadius)
            }
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let appearance = delegate?.appearance else {
            return CGSize(width: collectionView.frame.height, height: collectionView.frame.height)
        }
        let selectedItemLength = appearance.length + 6
        return CGSize(width: selectedItemLength, height: selectedItemLength)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        guard let layout = delegate?.layout, let appearance = delegate?.appearance else {
            return 0
        }
        var colorsCount: CGFloat = 0
        switch layout {
        case .singleLine:
            colorsCount = CGFloat(colorsArray.count)
        case .fixedNumber(let numberOfItemsPerLine):
            colorsCount = CGFloat(numberOfItemsPerLine)
        case .fixedSpacing(let itemSpacing):
            return itemSpacing
        }
        let selectedItemLength = appearance.length + 6
        let boardWidth: CGFloat = collectionView.frame.size.width
        return floor((boardWidth - selectedItemLength * colorsCount) / (colorsCount - 1))
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        guard let layout = delegate?.layout, let appearance = delegate?.appearance else {
            return 0
        }
        var colorsCount: CGFloat = 0
        switch layout {
        case .singleLine:
            colorsCount = CGFloat(colorsArray.count)
        case .fixedNumber(let numberOfItemsPerLine):
            colorsCount = CGFloat(numberOfItemsPerLine)
        case .fixedSpacing(let itemSpacing):
            return itemSpacing
        }
        let selectedItemLength = appearance.length + 6
        let boardWidth: CGFloat = collectionView.frame.size.width
        return floor((boardWidth - selectedItemLength * colorsCount) / (colorsCount - 1))
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if selectedIndexPath != indexPath {
            collectionView.deselectItem(at: selectedIndexPath, animated: false)
        }
        selectedIndexPath = indexPath
        let index = indexPath.item
        if index < colorsArray.count {
            delegate?.didSelectColor(string: colorsArray[index], index: index)
        }
    }


}


public final class SKColorWellCell: UICollectionViewCell {

    private let colorItem = UIView()

    private let highlightBorder = UIView()

    private let hoverView = UIView()

    private let disposeBag = DisposeBag()

    private var colorValue = "" {
        didSet {
            let color = UIColor.docs.rgb(colorValue)
            colorItem.backgroundColor = color
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.clipsToBounds = true
        contentView.addSubview(colorItem)
        contentView.addSubview(highlightBorder)

        colorItem.layer.ud.setBorderColor(UDColor.lineBorderComponent)
        colorItem.layer.borderWidth = 0.5
        highlightBorder.layer.ud.setBorderColor(UDColor.primaryContentDefault)
        highlightBorder.layer.borderWidth = 3
        
        guard SKDisplay.pad else { return }
        contentView.addSubview(hoverView)
        hoverView.snp.makeConstraints { make in
            make.edges.equalTo(colorItem)
        }
        hoverView.layer.masksToBounds = true
        hoverView.docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setupData(colorValue: String, colorSize: CGFloat = 40, colorRadius: CGFloat = 8) {
        self.colorValue = colorValue
        let itemLength: CGFloat = isSelected ? (colorSize - 4) : colorSize
        let itemRadius: CGFloat = isSelected ? (colorRadius - 2) : colorRadius
        colorItem.layer.cornerRadius = itemRadius
        hoverView.layer.cornerRadius = itemRadius
        if !isSelected,
           true == UIColor.docs.shouldBorderMonochromeColor(colorValue) {
            colorItem.layer.borderWidth = 0.5
        } else {
            colorItem.layer.borderWidth = 0
        }
        highlightBorder.layer.cornerRadius = colorRadius + 3
        highlightBorder.isHidden = !isSelected
        
        colorItem.snp.remakeConstraints { (make) in
            make.width.height.equalTo(itemLength)
            make.center.equalToSuperview()
        }
        
        highlightBorder.snp.remakeConstraints { (make) in
            make.width.height.equalTo(colorSize + 6)
            make.center.equalToSuperview()
        }
    }
}
