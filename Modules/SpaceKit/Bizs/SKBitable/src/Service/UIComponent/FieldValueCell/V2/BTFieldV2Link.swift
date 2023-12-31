//
// Created by duanxiaochen.7 on 2020/1/29.
// Affiliated with DocsSDK.
//
// Description:

import Foundation
import SKCommon
import LarkTag
import SKFoundation
import SKResource
import SKBrowser
import UniverseDesignToast
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignIcon

struct BTFieldUIDataLink: BTFieldUIData {
    struct Const {
        static let textColor = UDColor.textTitle
        static let textFont = UDFont.body1
        static let textInsetH: CGFloat = 9.0
        static let textInsetV: CGFloat = 2.0
        static let lineHeight: CGFloat = 24
        static let lineSpacing: CGFloat = 8.0
        static let interitemSpacing: CGFloat = 8.0
    }
}

extension BTRecordModel {
    var linkRecordTitle: String {
        recordTitle.isEmpty ? BundleI18n.SKResource.Doc_Block_UnnamedRecord : recordTitle
    }
}

final class BTLinkFieldFlowLayout: UICollectionViewFlowLayout {
    var data: [BTRecordModel] = [] {
        didSet {
            recalculate()
        }
    }
    private var calculatedLayoutResult: (CGSize, [CGRect]) = (.zero, [])
    private var cachedAttributes: [UICollectionViewLayoutAttributes] = []

    override func prepare() {
        super.prepare()
        recalculate()
    }

    private func recalculate() {
        guard let collectionView = collectionView else { return }
        calculatedLayoutResult = BTLinkFieldFlowLayout.calculate(data, maxWidth: collectionView.bounds.width)
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
    
    static func calculate(_ dataSource: [BTRecordModel], maxWidth: CGFloat) -> (size: CGSize, rects: [CGRect]) {
        let label = UILabel()
        label.font = BTFieldUIDataLink.Const.textFont
        label.numberOfLines = 1
        label.textAlignment = .center
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        var currentOriginX: CGFloat = 0
        var currentOriginY: CGFloat = 0
        var currentRow = 1
        var rects: [CGRect] = []
        
        for item in dataSource {
            label.text = item.linkRecordTitle
            //计算文本宽高
            let textW = ceil(label.intrinsicContentSize.width)
            var cellW = BTFieldUIDataLink.Const.textInsetH * 2 + textW
            //保证它最小是个正方形，同时不超过collectionview宽度
            if cellW < BTFieldUIDataLink.Const.lineHeight {
                cellW = BTFieldUIDataLink.Const.lineHeight
            } else if cellW > maxWidth {
                cellW = maxWidth
            }
            var originX: CGFloat = 0
            var originY: CGFloat = 0
            if currentOriginX + cellW <= maxWidth {
                originX = currentOriginX
                originY = currentOriginY
            } else {
                currentRow += 1
                currentOriginX = 0
                currentOriginY += (BTFieldUIDataLink.Const.lineHeight + BTFieldUIDataLink.Const.lineSpacing)
                originX = currentOriginX
                originY = currentOriginY
            }
            currentOriginX += (cellW + BTFieldUIDataLink.Const.interitemSpacing)
            rects.append(CGRect(x: originX, y: originY, width: cellW, height: BTFieldUIDataLink.Const.lineHeight))
        }
        let totalW = currentRow > 1 ? maxWidth : currentOriginX - BTFieldUIDataLink.Const.interitemSpacing
        let totalH = currentOriginY + BTFieldUIDataLink.Const.lineHeight
        return (CGSize(width: totalW, height: totalH), rects)
    }
}

// MARK: - BTLinkField
final class BTFieldV2Link: BTFieldV2Base, BTFieldLinkCellProtocol, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private lazy var flowLayout = BTLinkFieldFlowLayout()

    private lazy var linkedRecordsView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout).construct { it in
        it.delegate = self
        it.dataSource = self
        it.backgroundColor = .clear
        it.insetsLayoutMarginsFromSafeArea = false
        it.bounces = false
        it.contentInsetAdjustmentBehavior = .never
        it.isScrollEnabled = UserScopeNoChangeFG.ZJ.btCellLargeContentOpt
        it.delaysContentTouches = false
        it.showsVerticalScrollIndicator = false
        it.showsHorizontalScrollIndicator = false
        it.register(LinkedRecordCell.self, forCellWithReuseIdentifier: LinkedRecordCell.reuseIdentifier)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onListViewCellOutsideClick(_:)))
        tap.delegate = self
        it.addGestureRecognizer(tap)
    }

    /// 被关联的所有记录的 model
    var linkedRecords: [BTRecordModel] = []

    var showingMenuIndexPath: IndexPath?
    
    override func subviewsInit() {
        super.subviewsInit()
        containerView.addSubview(linkedRecordsView)
        linkedRecordsView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)
        linkedRecords = model.linkedRecords
        flowLayout.data = linkedRecords
        flowLayout.invalidateLayout()
        linkedRecordsView.reloadData()
    }
    
    @objc
    override func onFieldEditBtnClick(_ sender: UIButton) {
        modifyLinkage()
    }
    
    @objc
    override func onFieldValueEnlargeAreaClick(_ sender: UITapGestureRecognizer) {
        handleCheckboxOutsideClick()
    }
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer.view == linkedRecordsView {
            let point = touch.location(in: linkedRecordsView)
            for cell in linkedRecordsView.visibleCells {
                if cell.frame.contains(point) {
                    return false
                }
            }
            return true
        }
        return super.gestureRecognizer(gestureRecognizer, shouldReceive: touch)
    }
    
    private func handleCheckboxOutsideClick() {
        modifyLinkage()
    }

    private func modifyLinkage() {
        guard fieldModel.editable else {
            showUneditableToast()
            return
        }
        delegate?.startModifyLinkage(fromField: self)
    }

    func panelDidStartEditing() {
        updateBorderMode(.editing)
        delegate?.panelDidStartEditingField(self, scrollPosition: .bottom)
    }

    func stopEditing() {
        updateBorderMode(.normal)
        delegate?.stopEditingField(self, scrollPosition: nil)
    }

    @objc
    private func onListViewCellOutsideClick(_ sender: UITapGestureRecognizer) {
        handleCheckboxOutsideClick()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return linkedRecords.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LinkedRecordCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? LinkedRecordCell, indexPath.item < linkedRecords.count {
            let record = linkedRecords[indexPath.item]
            cell.loadCell(text: record.linkRecordTitle, id: record.recordID)
            cell.linkageCanceller = self
            cell.isSelected = false
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        defer {
            collectionView.deselectItem(at: indexPath, animated: true)
        }
        guard let cell = collectionView.cellForItem(at: indexPath) as? LinkedRecordCell,
              let recordID = cell.recordID else { return }
        delegate?.linkCell(self, didClickRecordWithID: recordID)
    }

    func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        guard fieldModel.editable else { return false }
        if let showingMenuIndexPath = showingMenuIndexPath,
           showingMenuIndexPath != indexPath,
           let highlightedCell = collectionView.cellForItem(at: showingMenuIndexPath) as? LinkedRecordCell {
            highlightedCell.menuWillHide()
            return false
        }
        guard let cell = collectionView.cellForItem(at: indexPath) as? LinkedRecordCell else { return false }
        let deleteItem = UIMenuItem(title: BundleI18n.SKResource.Doc_Facade_Delete, action: #selector(LinkedRecordCell.cancelLinkage))
        UIMenuController.shared.menuItems = [deleteItem]
        delegate?.generateHapticFeedback()
        cell.showBorder(true)
        showingMenuIndexPath = indexPath
        return true
    }

    func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        action == #selector(LinkedRecordCell.cancelLinkage)
    }

    func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        // 这个方法根本不会调用，但是如果不实现的话则无法呼出 menu
    }
}

extension BTFieldV2Link: BTLinkageCanceller {
    func cancelLinkage(toRecordID recordID: String) {
        linkedRecords.removeAll { record in
            record.recordID == recordID
        }
        delegate?.cancelLinkage(fromFieldID: fieldID, toRecordID: recordID, inFieldModel: fieldModel)
    }

    func clearState() {
        showingMenuIndexPath = nil
    }
}


extension BTFieldV2Link {
    final class LinkedRecordCell: UICollectionViewCell {

        var recordID: String?

        weak var linkageCanceller: BTLinkageCanceller?

        override var isSelected: Bool {
            didSet {
                contentView.backgroundColor = isSelected ? UDColor.N900.withAlphaComponent(0.1) : UDColor.N900.withAlphaComponent(0.05)
            }
        }

        private lazy var titleLabel = UILabel().construct { it in
            it.numberOfLines = 1
            it.textColor = BTFieldUIDataLink.Const.textColor
            it.font = BTFieldUIDataLink.Const.textFont
            it.textAlignment = .center
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            
            contentView.layer.cornerRadius = 4
            contentView.layer.masksToBounds = true
            contentView.backgroundColor = UDColor.N900.withAlphaComponent(0.05)
            NotificationCenter.default.addObserver(self, selector: #selector(menuWillHide), name: UIMenuController.willHideMenuNotification, object: nil)
            
            contentView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(BTFieldUIDataLink.Const.textInsetH)
                make.top.bottom.equalToSuperview().inset(BTFieldUIDataLink.Const.textInsetV)
                make.height.equalTo(BTFieldUIDataLink.Const.lineHeight)
            }
        }

        func loadCell(text: String, id: String) {
            recordID = id
            showBorder(false)
            titleLabel.text = text
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func showBorder(_ show: Bool) {
            if show {
                contentView.layer.ud.setBorderColor(UDColor.primaryContentDefault)
                contentView.layer.borderWidth = 1
            } else {
                contentView.layer.ud.setBorderColor(.clear)
                contentView.layer.borderWidth = 0
            }
        }

        // In order to make editing menu work, the cell (rather than collectionView) must implement the action's selector!
        @objc
        func cancelLinkage() {
            guard let recordID = recordID else { return }
            linkageCanceller?.cancelLinkage(toRecordID: recordID)
        }

        @objc
        func menuWillHide() {
            showBorder(false)
            linkageCanceller?.clearState()
        }
    }
}
