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
import UniverseDesignToast
import UniverseDesignColor

// MARK: - BTLinkField
final class BTLinkField: BTBaseField, BTFieldLinkCellProtocol, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private lazy var flowLayout = UICollectionViewFlowLayout().construct { it in
        it.minimumLineSpacing = BTFieldLayout.Const.tableItemSpacing
    }

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
    }

    private lazy var tapGR = UITapGestureRecognizer(target: self, action: #selector(onTappingEmptyContainer)).construct { it in
        it.cancelsTouchesInView = false
    }

    private lazy var addButton = AddButton().construct { it in
        it.addTarget(self, action: #selector(modifyLinkage), for: .touchUpInside)
    }

    /// 被关联的所有记录的 model
    var linkedRecords: [BTRecordModel] = []

    var showingMenuIndexPath: IndexPath?

    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)
        linkedRecords = model.linkedRecords
        relayout()
        linkedRecordsView.reloadData()
    }

    private func relayout() {
        linkedRecordsView.removeFromSuperview()
        addButton.removeFromSuperview()
        if fieldModel.editable {
            containerView.addSubview(addButton)
            // 有编辑权限，不能弹 toast
            containerView.removeGestureRecognizer(tapGR)
            if linkedRecords.isEmpty {
                addButton.snp.remakeConstraints { it in
                    it.edges.equalToSuperview()
                }
                addButton.layer.cornerRadius = 6
                if fieldModel.isEditing || !fieldModel.errorMsg.isEmpty {
                    addButton.shouldAddNewBorder = false
                    containerView.layer.borderWidth = BTFieldLayout.Const.containerBorderWidth
                } else {
                    addButton.shouldAddNewBorder = true
                    containerView.layer.borderWidth = 0 // 为了让 add button 的虚线边框显示出来
                }
            } else {
                containerView.addSubview(linkedRecordsView)
                linkedRecordsView.snp.remakeConstraints { it in
                    it.left.top.right.equalToSuperview().inset(BTFieldLayout.Const.containerPadding)
                    it.bottom.equalToSuperview().inset(BTFieldLayout.Const.containerPadding + BTFieldLayout.Const.tableItemHeight + BTFieldLayout.Const.tableItemSpacing)
                }
                addButton.snp.remakeConstraints { it in
                    it.left.right.bottom.equalToSuperview().inset(BTFieldLayout.Const.containerPadding)
                    it.height.equalTo(BTFieldLayout.Const.tableItemHeight)
                }
                addButton.layer.cornerRadius = 4
                addButton.shouldAddNewBorder = true
                containerView.layer.borderWidth = BTFieldLayout.Const.containerBorderWidth
            }
        } else {
            if linkedRecords.isEmpty {
                // 无编辑权限，仅在 collectionView 为空时弹 toast
                containerView.addGestureRecognizer(tapGR)
            } else {
                // 无编辑权限，但 collectionView 有内容时，不弹 toast
                containerView.removeGestureRecognizer(tapGR)
                containerView.addSubview(linkedRecordsView)
                linkedRecordsView.snp.remakeConstraints { it in
                    it.left.top.right.bottom.equalToSuperview().inset(BTFieldLayout.Const.containerPadding)
                }
            }
        }
        layoutIfNeeded()
    }

    func stringForPrimaryField(inRecord recordModel: BTRecordModel) -> String? {
        let primaryFieldID = fieldModel.property.primaryFieldId
        return BTUtil.getTitleAttrString(title: recordModel.recordTitle).string
    }

    @objc
    private func modifyLinkage() {
        guard fieldModel.editable else { return }
        delegate?.startModifyLinkage(fromField: self)
    }

    func panelDidStartEditing() {
        updateBorderMode(.editing)
        delegate?.panelDidStartEditingField(self, scrollPosition: .bottom)
    }

    func stopEditing() {
        relayout()
        delegate?.stopEditingField(self, scrollPosition: nil)
    }

    @objc
    private func onTappingEmptyContainer() {
        if !fieldModel.editable {
            showUneditableToast()
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return linkedRecords.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LinkedRecordCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? LinkedRecordCell, indexPath.item < linkedRecords.count {
            let recordModel = linkedRecords[indexPath.item]
            if let primaryString = stringForPrimaryField(inRecord: recordModel) {
                cell.linkageCanceller = self
                cell.loadCell(text: primaryString, id: recordModel.recordID)
            }
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = fieldModel.width - BTFieldLayout.Const.containerLeftRightMargin * 2 - BTFieldLayout.Const.containerPadding * 2
        return CGSize(width: width, height: BTFieldLayout.Const.tableItemHeight)
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


protocol BTLinkageCanceller: AnyObject {
    func cancelLinkage(toRecordID: String)
    func clearState()
}

extension BTLinkField: BTLinkageCanceller {
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


extension BTLinkField {
    final class LinkedRecordCell: UICollectionViewCell {

        var recordID: String?

        weak var linkageCanceller: BTLinkageCanceller?

        override var isSelected: Bool {
            didSet {
                contentView.backgroundColor = isSelected ? UDColor.fillPressed : UDColor.fillTag
            }
        }

        private lazy var titleLabel = UILabel().construct { it in
            it.numberOfLines = 1
            it.textColor = UDColor.textTitle
            it.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            contentView.layer.cornerRadius = 4
            contentView.layer.masksToBounds = true
            contentView.backgroundColor = UDColor.bgFloatOverlay
            NotificationCenter.default.addObserver(self, selector: #selector(menuWillHide), name: UIMenuController.willHideMenuNotification, object: nil)
            setupLayout()
        }

        func setupLayout() {
            contentView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { it in
                it.left.equalToSuperview().offset(14)
                it.right.equalToSuperview().offset(-14)
                it.centerY.equalToSuperview()
            }
        }

        func loadCell(text: String, id: String) {
            recordID = id
            showBorder(false)
            titleLabel.text = text.isEmpty ? BundleI18n.SKResource.Doc_Block_UnnamedRecord : text
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
