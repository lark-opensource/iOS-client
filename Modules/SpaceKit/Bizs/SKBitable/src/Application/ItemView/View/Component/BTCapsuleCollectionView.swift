// 
// Created by duanxiaochen.7 on 2020/3/29.
// Affiliated with DocsSDK.
// 
// Description:

import Foundation
import UIKit
import Kingfisher
import SKCommon
import SKBrowser
import SKFoundation
import SKResource
import UniverseDesignColor

protocol BTCapsuleCollectionViewDelegate: AnyObject {
    func btCapsuleCollectionView(_ collectionView: BTCapsuleCollectionView, didTapCell model: BTCapsuleModel)
    func btCapsuleCollectionView(_ collectionView: BTCapsuleCollectionView, didDoubleTapCell model: BTCapsuleModel)
    func btCapsuleCollectionView(_ collectionView: BTCapsuleCollectionView, shouleAllowCellApplyAction action: BTTextViewMenuAction) -> Bool
}

extension BTCapsuleCollectionViewDelegate {
    func btCapsuleCollectionView(_ collectionView: BTCapsuleCollectionView, didTapCell model: BTCapsuleModel) {}
}

final class BTCapsuleCollectionView: UIView {

    weak var delegate: BTCapsuleCollectionViewDelegate?

    var dataSource: [BTCapsuleModel] = [] {
        didSet {
            if oldValue != dataSource {
                layout.data = dataSource
                collectionView.collectionViewLayout = layout
                collectionView.reloadData()
                collectionView.collectionViewLayout.invalidateLayout()
            }
        }
    }

    var layoutConfig: BTCapsuleUIConfiguration = .zero {
        didSet {
            if oldValue != layoutConfig {
                layout.layoutConfig = layoutConfig
                collectionView.collectionViewLayout = layout
                collectionView.reloadData()
                collectionView.collectionViewLayout.invalidateLayout()
            }
        }
    }
    
    var contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior = .automatic {
        didSet {
            collectionView.contentInsetAdjustmentBehavior = contentInsetAdjustmentBehavior
        }
    }

    private lazy var layout = BTCapsuleCollectionViewFlowLayout().construct { it in
        it.scrollDirection = .vertical
        it.minimumLineSpacing = layoutConfig.rowSpacing
        it.minimumInteritemSpacing = layoutConfig.colSpacing
    }

    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout).construct { it in
        it.backgroundColor = .clear
        it.dataSource = self
        it.delegate = self
        it.bounces = false
        it.isScrollEnabled = UserScopeNoChangeFG.ZJ.btCellLargeContentOpt
        it.showsVerticalScrollIndicator = false
        it.register(BTCapsuleCell.self, forCellWithReuseIdentifier: "BTCapsuleCell")
        it.register(BTCapsuleCellWithAvatar.self, forCellWithReuseIdentifier: "BTCapsuleCellWithAvatar")
    }

    private var style: BTCapsuleCollectionViewStyle

    enum BTCapsuleCollectionViewStyle {
        case regular
        case avatar
    }

    /// withPadding: 是否有一圈透明内边距
    init(_ style: BTCapsuleCollectionViewStyle = .regular) {
        self.style = style
        super.init(frame: .zero)
        backgroundColor = .clear
        setupUI()
    }

    private func setupUI() {
        addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BTCapsuleCollectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: BTCapsuleCell
        switch style {
        case .regular:
            cell = (collectionView.dequeueReusableCell(withReuseIdentifier: "BTCapsuleCell", for: indexPath) as? BTCapsuleCell)!
        case .avatar:
            cell = (collectionView.dequeueReusableCell(withReuseIdentifier: "BTCapsuleCellWithAvatar", for: indexPath) as? BTCapsuleCellWithAvatar)!
        }
        cell.setupCell(dataSource[indexPath.row], maxLength: collectionView.bounds.width, layoutConfig: layoutConfig)
        cell.delegate = self
        return cell
    }
}

extension BTCapsuleCollectionView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard style == .avatar, dataSource.count > indexPath.row else { return }
        delegate?.btCapsuleCollectionView(self, didTapCell: dataSource[indexPath.row])
    }
}

// 处理判断点击的是否是cell
extension BTCapsuleCollectionView {
    func detectTouchIsInCell(_ touch: UITouch) -> Bool {
        let point = touch.location(in: self)
        for cell in collectionView.visibleCells {
            if cell.frame.contains(point) {
                return true
            }
        }
        return false
    }
}

extension BTCapsuleCollectionView: BTCapsuleCellDelegate {
    
    func btCapsuleCell(_ cell: BTCapsuleCell, didDoubleTapTextContentof model: BTCapsuleModel) {
        self.delegate?.btCapsuleCollectionView(self, didDoubleTapCell: model)
    }
    
    func btCapsuleCell(_ cell: BTCapsuleCell, didSingleTapTextContentof model: BTCapsuleModel) {
        self.delegate?.btCapsuleCollectionView(self, didTapCell: model)
    }
    
    func btCapsuleCell(_ cell: BTCapsuleCell, shouleApplyAction action: BTTextViewMenuAction) -> Bool {
        self.delegate?.btCapsuleCollectionView(self, shouleAllowCellApplyAction: action) ?? false
    }
}


// MARK: - Layout

final class BTCollectionViewWaterfallHelper {

    static let label: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textTitle
        label.textAlignment = .center
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    class func getSize(with dataList: [BTCapsuleModel], maxLineLength: CGFloat, layoutConfig: BTCapsuleUIConfiguration) -> CGSize {
        let (size, _, _) = calculate(with: dataList, maxLineLength: maxLineLength, layoutConfig: layoutConfig)
        return size
    }

    class func calculate(with dataList: [BTCapsuleModel], maxLineLength: CGFloat, layoutConfig: BTCapsuleUIConfiguration) -> (CGSize, [CGRect], Int) {
        var currentLength: CGFloat = 0
        var currentHeight: CGFloat = 0
        var currentRow = 1
        var rects: [CGRect] = []
        for dataInfo in dataList {
            label.text = dataInfo.text
            label.font = dataInfo.font
            //计算文本宽高
            let width = ceil(label.intrinsicContentSize.width)
            var cellWidth = layoutConfig.textInsets.left + width + layoutConfig.textInsets.right
            //保证它最小是个正方形，同时不超过collectionview宽度
            if cellWidth < layoutConfig.lineHeight {
                cellWidth = layoutConfig.lineHeight
            } else if cellWidth > maxLineLength {
                cellWidth = maxLineLength
            }
            var cellX: CGFloat = 0
            var cellY: CGFloat = 0
            if currentLength + cellWidth <= maxLineLength {
                cellX = currentLength
                cellY = currentHeight
            } else {
                currentRow += 1
                currentLength = 0
                currentHeight += layoutConfig.lineHeight + layoutConfig.rowSpacing
                cellX = currentLength
                cellY = currentHeight
            }
            currentLength += cellWidth + layoutConfig.colSpacing
            rects.append(CGRect(x: cellX, y: cellY, width: cellWidth, height: layoutConfig.lineHeight))
        }
        return (CGSize(width: maxLineLength, height: currentHeight + layoutConfig.lineHeight), rects, currentRow)
    }
}


final class BTCapsuleCollectionViewFlowLayout: UICollectionViewFlowLayout {
    var data: [BTCapsuleModel] = [] {
        didSet {
            recalculate()
        }
    }
    var layoutConfig: BTCapsuleUIConfiguration = .zero
    private var calculatedLayoutResult: (CGSize, [CGRect], Int) = (.zero, [], 1)
    private var cachedAttributes: [UICollectionViewLayoutAttributes] = []

    override func prepare() {
        super.prepare()
        recalculate()
    }

    func recalculate() {
        guard let collectionView = collectionView else { return }
        calculatedLayoutResult = BTCollectionViewWaterfallHelper.calculate(with: data,
                                                                           maxLineLength: collectionView.bounds.width,
                                                                           layoutConfig: layoutConfig)
        cachedAttributes.removeAll()
        for (index, rect) in calculatedLayoutResult.1.enumerated() {
            let indexPath = IndexPath(item: index, section: 0)
            let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attr.frame = rect
            cachedAttributes.append(attr)
        }
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let cv = collectionView else { return false }
        return cv.bounds.origin != newBounds.origin || cv.bounds.size != newBounds.size
    }

    override var collectionViewContentSize: CGSize {
        calculatedLayoutResult.0
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        cachedAttributes.filter { rect.intersects($0.frame) }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.item < cachedAttributes.count else { return nil }
        return cachedAttributes[indexPath.item]
    }
}
