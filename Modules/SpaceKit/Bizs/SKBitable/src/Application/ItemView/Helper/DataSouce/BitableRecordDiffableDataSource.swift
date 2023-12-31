//
// Created by duanxiaochen.7 on 2022/3/17.
// Affiliated with SKBitable.
//
// Description: BTRecord 用这个 DataSource 来差量更新 collectionViewCell
//


import ObjectiveC
import UIKit
import SKCommon
import SKUIKit
import SKFoundation
import RxDataSources


final class BitableRecordDiffableDataSource: NSObject, UICollectionViewDataSource {

    private var fieldsLayout: BTFieldLayout

    private weak var fieldsDelegate: BTFieldDelegate?
    
    // ui model
    var latestSnapshot: BTRecordModel
    
    // data model
    private var realRecordModel: BTRecordModel

    // 当前展示封面的 fileToken 和 index，如果 fileToken 和 index 不匹配代表附件数据发生了增减，则默认滚动到第一张封面
    private var currentAttachmentCover: (token: String, index: Int)? = nil

    init(layout: BTFieldLayout,
         delegate: BTFieldDelegate,
         initialUIModel: BTRecordModel,
         initalDataModel: BTRecordModel) {
        fieldsLayout = layout
        fieldsDelegate = delegate
        latestSnapshot = initialUIModel
        realRecordModel = initalDataModel
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return latestSnapshot.wrappedFields.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        DocsLogger.btInfo("[DIFF] [Record] dequeue field indexPath \(indexPath) in record \(latestSnapshot.recordID)")
        guard 0 <= indexPath.item, indexPath.item < latestSnapshot.wrappedFields.count else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: BTUnsupportedField.reuseIdentifier, for: indexPath)
        }

        let fieldModel = latestSnapshot.wrappedFields[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: fieldModel.cellReuseID, for: indexPath)
        configureField(collectionView, cell, withModel: fieldModel, latestRecordInfo: latestSnapshot)
        return cell
    }

    func revertCurrentAttachmentCover() {
        currentAttachmentCover = nil
        guard let collectionView = fieldsLayout.collectionView else {
            DocsLogger.btError("[BTRecordDataSource] get collectionView fail")
            return
        }
        guard collectionView.numberOfItems(inSection: 0) > 0 else {
            return
        }
        guard let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? BTAttachmentCoverCell else {
            return
        }
        cell.revertIndexIfNeeded()
    }
}

extension BitableRecordDiffableDataSource: BTAttachmentCoverCellDelegate {
    func attachmentCoverCell(cell: BTAttachmentCoverCell, updateCover cover: (token: String, index: Int)) {
        currentAttachmentCover = cover
    }

    func attachmentCoverCellGetCurrentCover(cell: BTAttachmentCoverCell) -> (token: String?, index: Int)? {
        return currentAttachmentCover
    }
}

extension BitableRecordDiffableDataSource {

    // record 数据已经在 BTFieldLayout 里面做了一次 diff，所以这里只需要 apply patch
    func applyPatch(_ collectionView: UICollectionView, differences: [Changeset<BTRecordModel>], uiModel: BTRecordModel, dataModel: BTRecordModel, completion: ((Bool) -> Void)? = nil) {
        realRecordModel = dataModel
        if collectionView.window == nil {
            latestSnapshot = uiModel
            collectionView.reloadData()
            completion?(true)
            return
        }

        guard !differences.isEmpty else {
            completion?(false)
            return
        }
        
        let manager = DifferencesCompletionManager(differences: differences) {
            completion?(true)
            collectionView.collectionViewLayout.invalidateLayout()
        }

        UIView.performWithoutAnimation {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            
            for (index, difference) in differences.enumerated() {
                guard let finalSectionForThisStep = difference.finalSections.first else {
                    latestSnapshot = uiModel
                    collectionView.reloadData()
                    manager.finishDiffereceTask(index: index, isFinishAllTask: true)
                    break
                }
                
                if #unavailable(iOS 13.0), !UserScopeNoChangeFG.ZJ.btDiffFixIOS12Disable {
                    handleUpdateForIOS12(collectionView, difference,
                                         finalSnapshot: uiModel,
                                         finalSectionForThisStep: finalSectionForThisStep) {
                        manager.finishDiffereceTask(index: index)
                    }
                    continue
                }
                
                if DifferencesCompletionManager.hasUpdate(of: difference) {
                    collectionView.performBatchUpdates {
                        difference.updatedItems.forEach { [weak self] item in
                            guard let self = self else { return }
                            let index = item.itemIndex
                            guard 0 <= index, index < self.latestSnapshot.items.count else {
                                spaceAssertionFailure("[DIFF] [Field] index out of bounds")
                                return
                            }
                            
                            let oldField = self.latestSnapshot.items[index]
                            if let newField = finalSectionForThisStep.items.first(where: { $0.identity == oldField.identity }) {
                                self.latestSnapshot.update(newField, for: index)
                            }
                        }
                        
                        updateItems(collectionView, at: difference.updatedItems.map { IndexPath(item: $0.itemIndex, section: $0.sectionIndex) },
                                    latestRecordInfo: uiModel)
                    } completion: { completed in
                        if completed {
                            manager.finishDiffereceTask(index: index)
                        }
                    }
                }
                
                if DifferencesCompletionManager.hasDeleteOrInsertOrMove(of: difference) {
                    collectionView.performBatchUpdates {
                        latestSnapshot = uiModel
                        latestSnapshot.update(fields: finalSectionForThisStep.items)
                        deleteItems(collectionView, at: difference.deletedItems.map { IndexPath(item: $0.itemIndex, section: $0.sectionIndex) },
                                    latestRecordInfo: uiModel)
                        insertItems(collectionView, at: difference.insertedItems.map { IndexPath(item: $0.itemIndex, section: $0.sectionIndex) },
                                    latestRecordInfo: uiModel)
                        difference.movedItems.forEach { (from: ItemPath, to: ItemPath) in
                            moveItem(collectionView,
                                     from: IndexPath(item: from.itemIndex, section: from.sectionIndex),
                                     to: IndexPath(item: to.itemIndex, section: to.sectionIndex),
                                     latestRecordInfo: uiModel)
                        }
                    } completion: { completed in
                        if completed {
                            manager.finishDiffereceTask(index: index)
                        }
                    }
                }
            }
            CATransaction.commit()
        }
    }

    ///latestRecordInfo: 最新的record数据，除field数据外的其它数据，例如卡片是否可见、是否可编辑等
    ///BTRecordModel diff的对象是wrappedFields，所以finalSectionForThisStep除了wrappedFields数据是最新的外，其它的数据都是旧的
    func deleteItems(_ collectionView: UICollectionView, at indexPaths: [IndexPath], latestRecordInfo: BTRecordModel) {
        guard !indexPaths.isEmpty else { return }
        DocsLogger.btInfo("[DIFF] [Record] delete field items \(indexPaths) in record \(latestSnapshot.recordID), current items count: \(latestSnapshot.items.count)")
        collectionView.deleteItems(at: indexPaths)
    }

    func insertItems(_ collectionView: UICollectionView, at indexPaths: [IndexPath], latestRecordInfo: BTRecordModel) {
        guard !indexPaths.isEmpty else { return }
        DocsLogger.btInfo("[DIFF] [Record] insert field items \(indexPaths) in record \(latestSnapshot.recordID), current items count: \(latestSnapshot.items.count)")
        collectionView.insertItems(at: indexPaths)
    }

    func updateItems(_ collectionView: UICollectionView, at indexPaths: [IndexPath], latestRecordInfo: BTRecordModel) {
        for indexPath in indexPaths {
            let index = indexPath.item
            guard 0 <= index, index < latestSnapshot.items.count else {
                spaceAssertionFailure("[DIFF] [Record] index out of bounds")
                break
            }
            DocsLogger.btInfo("[DIFF] [Record] update field item \(index) in record \(latestSnapshot.recordID), current items count: \(latestSnapshot.items.count)")
            let fieldModel = latestSnapshot.items[index]
            if fieldModel.isEditing, fieldModel.compositeType.uiType.interceptUpdateWhileEditing {
                if fieldModel.usingLayoutV2, let cell = collectionView.cellForItem(at: indexPath) as? BTFieldModelLoadable {
                    cell.updateModelInEditing(fieldModel, layout: fieldsLayout)
                }
                continue
            }
            if collectionView.indexPathsForVisibleItems.contains(indexPath),
               let field = collectionView.cellForItem(at: indexPath) {
                if let cell = field as? BTFieldModelLoadable,
                   cell.fieldModel.cellReuseID != fieldModel.cellReuseID {
                    // cell 类型要变化，需要 reload，否则将无法正常显示数据
                    collectionView.reloadItems(at: [indexPath])
                } else {
                    // cell 类型不变化，可以直接更新 cell 内容
                    configureField(collectionView, field, withModel: fieldModel, latestRecordInfo: latestRecordInfo)
                }
            }
        }
    }

    func moveItem(_ collectionView: UICollectionView, from oldIndexPath: IndexPath, to newIndexPath: IndexPath, latestRecordInfo: BTRecordModel) {
        DocsLogger.btInfo("[DIFF] [Record] move field item in record \(latestSnapshot.recordID) from \(oldIndexPath) to \(newIndexPath), current items count: \(latestSnapshot.items.count)")
        collectionView.moveItem(at: oldIndexPath, to: newIndexPath)
    }


    func configureField(
        _ collectionView: UICollectionView,
        _ providedCell: UICollectionViewCell,
        withModel fieldModel: BTFieldModel,
        latestRecordInfo: BTRecordModel
    ) {

        switch fieldModel.extendedType {
        // 卡片里的 cell
        case .inherent, .hiddenFieldsDisclosure:
            if let cell = providedCell as? BTFieldModelLoadable {
                cell.delegate = fieldsDelegate
                cell.loadModel(fieldModel, layout: fieldsLayout)
            }
        // 表单里的 cell
        case .formHeroImage: ()
        case .customFormCover:
            if let cell = providedCell as? BTCustomFormCoverCell {
                    if let urlStr = fieldModel.formBannerUrl {
                        if !urlStr.isEmpty {
                            cell.update(mode: .custom(url: urlStr))
                        } else {
                            cell.update(mode: .normal)
                        }
                    } else {
                        cell.update(mode: .normal)
                    }
            }
        case .formTitle:
            if let cell = providedCell as? BTFieldModelLoadable {
                cell.delegate = fieldsDelegate
                cell.loadModel(fieldModel, layout: fieldsLayout)
            }
        case .formSubmit:
            if let cell = providedCell as? BTFormSubmitCell {
                cell.delegate = fieldsDelegate
                cell.setupData(canSubmit: fieldModel.editable)
            }
        case .unreadable:
            break
        case .recordCountOverLimit:
            if let cell = providedCell as? BTFormRecordOverLimitCell {
                cell.delegate = fieldsDelegate
            }
        case .stageDetail:
            if let cell = providedCell as? BTStageDetailInfoCell {
                cell.setData(fieldModel)
                cell.delegate = fieldsDelegate
            }
        case .itemViewTabs:
            if let cell = providedCell as? BTItemViewListHeaderCell {
                cell.delegate = fieldsDelegate
                cell.setTitles(titles: fieldModel.itemViewTabs.map{ $0.name })
                cell.setSelectedIndex(index: latestRecordInfo.currentItemViewIndex)
            }
        case .itemViewHeader:
            if let cell = providedCell as? BTItemViewTiTleCell {
                cell.delegate = fieldsDelegate
                cell.update(
                    title: fieldModel.name,
                    hasShowTabs: realRecordModel.shouldShowItemViewTabs,
                    hasShowCover: realRecordModel.shouldShowAttachmentCoverField(),
                    hasShowCatalogue: realRecordModel.shouldShowItemViewCatalogue
                )
            }
        case .attachmentCover:
            if let cell = providedCell as? BTAttachmentCoverCell {
                cell.delegate = fieldsDelegate
                cell.coverDelegate = self
                cell.loadModel(fieldModel, layout: fieldsLayout)
            }
        case .itemViewCatalogue:
            if let cell = providedCell as? BTItemViewCatalogueCell {
                cell.delegate = fieldsDelegate
                cell.setData(
                    firstLevelTitle: latestRecordInfo.baseNameAdaptedForUntitled,
                    secondLevelTitle: latestRecordInfo.tableName,
                    showBottomLine: !realRecordModel.shouldShowItemViewTabs,
                    showLeftLabel: fieldModel.mode.isAddRecord)
            }
        }
    }
    
    // iOS12上多个changset要放到一个performBatchUpdates里面处理，不然会crash
    //https://slardar.bytedance.net/node/app_detail/?aid=1161&os=iOS&region=cn&lang=zh#/abnormal/detail/crash/0646a740d7796874a0a6c01673396af3?params=%7B%22token%22%3A%22%22%2C%22token_type%22%3A0%2C%22crash_time_type%22%3A%22insert_time%22%2C%22start_time%22%3A1675915080%2C%22end_time%22%3A1676519880%2C%22granularity%22%3A86400%2C%22filters_conditions%22%3A%7B%22type%22%3A%22and%22%2C%22sub_conditions%22%3A%5B%5D%7D%2C%22ios_issue_id_version%22%3A%22v2%22%2C%22event_index%22%3A1%7D
    private func handleUpdateForIOS12(_ collectionView: UICollectionView, _ difference: Changeset<BTRecordModel>,
                                      finalSnapshot: BTRecordModel,
                                      finalSectionForThisStep: BTRecordModel,
                                      completion: (() -> Void)? = nil) {
        DocsLogger.btInfo("[DIFF] [Record] handleUpdateForIOS12")
        if DifferencesCompletionManager.hasDeleteOrInsertOrMove(of: difference) {
            DocsLogger.btInfo("[DIFF] [Record] handleDeleteOrInsertOrMoveForIOS12")
            latestSnapshot = finalSnapshot
            collectionView.reloadData()
            completion?()
            return
        }
        
        if DifferencesCompletionManager.hasUpdate(of: difference) {
            difference.updatedItems.forEach { [weak self] item in
                guard let self = self else { return }
                let index = item.itemIndex
                guard 0 <= index, index < self.latestSnapshot.items.count else {
                    spaceAssertionFailure("[DIFF] [Field] index out of bounds")
                    return
                }
                
                let oldField = self.latestSnapshot.items[index]
                if let newField = finalSectionForThisStep.items.first(where: { $0.identity == oldField.identity }) {
                    self.latestSnapshot.update(newField, for: index)
                }
            }
            
            updateItems(collectionView, at: difference.updatedItems.map { IndexPath(item: $0.itemIndex, section: $0.sectionIndex) },
                        latestRecordInfo: finalSnapshot)
        }
        completion?()
    }
}
