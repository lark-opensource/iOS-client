//
//  BTFieldListView.swift
//  SKBitable
//
//  Created by X-MAN on 2023/5/29.
//

import Foundation
import UniverseDesignColor
import SKFoundation
import SKUIKit

final class BTFieldListView: UICollectionView {
    
    private var diffableDataSource: BitableRecordDiffableDataSource?
    private var fieldsLayout: BTFieldLayout
    var context: BTContext? {
        didSet {
            fieldsLayout.context = context
        }
    }

    required init(frame: CGRect) {
        let fieldsLayout = BTFieldLayout()
        self.fieldsLayout = fieldsLayout
        super.init(frame: frame, collectionViewLayout: fieldsLayout)
        registerCells()
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func registerCells() {
        if UserScopeNoChangeFG.ZYS.recordCardV2 {
            BTFieldUIType.allCases.forEach { type in
                register(type.reusableCellTypeV2, forCellWithReuseIdentifier: type.reusableCellTypeV2.reuseIdentifier)
            }
        }
        register(BTTextField.self, forCellWithReuseIdentifier: BTTextField.reuseIdentifier)
        register(BTNumberField.self, forCellWithReuseIdentifier: BTNumberField.reuseIdentifier)
        register(BTOptionField.self, forCellWithReuseIdentifier: BTOptionField.reuseIdentifier)
        register(BTDateField.self, forCellWithReuseIdentifier: BTDateField.reuseIdentifier)
        register(BTCheckboxField.self, forCellWithReuseIdentifier: BTCheckboxField.reuseIdentifier)
        register(BTURLField.self, forCellWithReuseIdentifier: BTURLField.reuseIdentifier)
        register(BTAttachmentField.self, forCellWithReuseIdentifier: BTAttachmentField.reuseIdentifier)
        register(BTLinkField.self, forCellWithReuseIdentifier: BTLinkField.reuseIdentifier)
        register(BTGeoLocationField.self, forCellWithReuseIdentifier: BTGeoLocationField.reuseIdentifier)
        register(BTFormulaField.self, forCellWithReuseIdentifier: BTFormulaField.reuseIdentifier)
        register(BTAutoNumberField.self, forCellWithReuseIdentifier: BTAutoNumberField.reuseIdentifier)
        register(BTUnsupportedField.self, forCellWithReuseIdentifier: BTUnsupportedField.reuseIdentifier)
        register(BTPhoneField.self, forCellWithReuseIdentifier: BTPhoneField.reuseIdentifier)
        register(BTFormHeroImageCell.self, forCellWithReuseIdentifier: BTFormHeroImageCell.reuseIdentifier)
        register(BTCustomFormCoverCell.self, forCellWithReuseIdentifier: BTCustomFormCoverCell.reuseIdentifier)
        register(BTFormTitleCell.self, forCellWithReuseIdentifier: BTFormTitleCell.reuseIdentifier)
        register(BTFormSubmitCell.self, forCellWithReuseIdentifier: BTFormSubmitCell.reuseIdentifier)
        register(BTHiddenFieldsDisclosureCell.self, forCellWithReuseIdentifier: BTHiddenFieldsDisclosureCell.reuseIdentifier)
        register(BTFormUnreadableCell.self, forCellWithReuseIdentifier: BTFormUnreadableCell.reuseIdentifier)
        register(BTProgressField.self, forCellWithReuseIdentifier: BTProgressField.reuseIdentifier)
        register(BTChatterField.self, forCellWithReuseIdentifier: BTChatterField.reuseIdentifier)
        register(BTButtonField.self, forCellWithReuseIdentifier: BTButtonField.reuseIdentifier)
        register(BTRatingField.self, forCellWithReuseIdentifier: BTRatingField.reuseIdentifier)
        register(BTFormRecordOverLimitCell.self, forCellWithReuseIdentifier: BTFormRecordOverLimitCell.reuseIdentifier)
        register(BTStageField.self, forCellWithReuseIdentifier: BTStageField.reuseIdentifier)
        register(BTStageDetailInfoCell.self, forCellWithReuseIdentifier: BTStageDetailInfoCell.reuseIdentifier)
        register(BTItemViewTiTleCell.self, forCellWithReuseIdentifier: BTItemViewTiTleCell.reuseIdentifier)
        register(BTItemViewListHeaderCell.self, forCellWithReuseIdentifier: BTItemViewListHeaderCell.reuseIdentifier)
        register(BTAttachmentCoverCell.self, forCellWithReuseIdentifier: BTAttachmentCoverCell.reuseIdentifier)
        register(BTItemViewCatalogueCell.self, forCellWithReuseIdentifier: BTItemViewCatalogueCell.reuseIdentifier)
    }
    
    private func setup() {
        // layout配置
        fieldsLayout.scrollDirection = .vertical
        fieldsLayout.minimumInteritemSpacing = 0
        fieldsLayout.minimumLineSpacing = 0
    }
    
    func load(_ model: BTRecordModel, _ dataModel: BTRecordModel, fieldsDelegate: BTFieldDelegate) {
        fieldsLayout.reloadModel(model, dataModel)
        let recordsDataSource = BitableRecordDiffableDataSource(layout: fieldsLayout,
                                                                delegate: fieldsDelegate,
                                                                initialUIModel: model,
                                                                initalDataModel: dataModel)
        dataSource = recordsDataSource
        diffableDataSource = recordsDataSource
        reloadData()
    }
    
    func update(_ uiModel: BTRecordModel, _ dataModel: BTRecordModel) {
        fieldsLayout.acceptSnapshot(uiModel, dataModel) { [weak self] (hasChanged, differences) in
            guard hasChanged, let self = self else { return }
            self.collectionViewLayout = self.fieldsLayout
            self.diffableDataSource?.applyPatch(self, differences: differences, uiModel: uiModel, dataModel: dataModel)
        }
    }
    
    func setHearderViewHeight(height: CGFloat) {
        fieldsLayout.hearderViewHeight = height
    }

    func revertAttachmentCover() {
        diffableDataSource?.revertCurrentAttachmentCover()
    }
}


extension BTFieldListView {
    func attributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return fieldsLayout.layoutAttributesForItem(at: indexPath)
    }
}
