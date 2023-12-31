//
// Created by duanxiaochen.7 on 2022/3/17.
// Affiliated with SKBitable.
//
// Description: BTController 用这个 DataSource 来差量更新 collectionViewCell
//

import UIKit
import SKUIKit
import SKFoundation
import RxDataSources
import SKCommon
import Foundation


final class BitableTableDiffableDataSource: NSObject, UICollectionViewDataSource {

    private(set) var recordsCollectionView: UICollectionView? // 由于卡片和表单时序不一样，collection view 没法在 init 时注入，只能后期注入

    private weak var recordsDelegate: BTRecordDelegate?

    var latestSnapshot: BTTableModel
    
    var bitableIsReady: Bool = false // ready后才可进行编辑

    //卡片切换支持定位，保持跟上张卡片相同的滚动位置
    private var currentTopFieldID: String = ""
    
    private var viewMode: BTViewMode
    
    var context: BTContext

    init(initialModel: BTTableModel, delegate: BTRecordDelegate, viewMode: BTViewMode, context: BTContext) {
        recordsDelegate = delegate
        latestSnapshot = initialModel
        self.context = context
        self.viewMode = viewMode
    }
    
    func bitableReady() {
        bitableIsReady = true
    }

    func setCollectionView(_ collectionView: UICollectionView) {
        recordsCollectionView = collectionView
        collectionView.dataSource = self
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        latestSnapshot.records.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        DocsLogger.btInfo("[DIFF] [Table] dequeue card item \(indexPath.item)")
        let record = collectionView.dequeueReusableCell(withReuseIdentifier: BTRecord.reuseIdentifier, for: indexPath)
        if 0 <= indexPath.item, indexPath.item < latestSnapshot.records.count, let record = record as? BTRecord {
            configureRecord(record, withModel: latestSnapshot.records[indexPath.item], usingReloadData: true)
        }
        return record
    }
}


extension BitableTableDiffableDataSource {

    func acceptSnapshot(_ snapshot: BTTableModel, completion: ((Bool) -> Void)? = nil) -> Bool {
        if recordsCollectionView?.window == nil {
            latestSnapshot = snapshot
            recordsCollectionView?.reloadData()
            return true
        }
        let oldRecordIds = latestSnapshot.records.map { $0.recordID }.toJSONString()
        let newRecordIds = latestSnapshot.records.map { $0.recordID }.toJSONString()
        DocsLogger.btInfo("[DIFF] [Table] diffing table model oldRecords: \(oldRecordIds), newRecords: \(newRecordIds)")
        var differences = [Changeset<BTTableModel>]()
        do {
            differences = try Diff.differencesForSectionedView(initialSections: [self.latestSnapshot], finalSections: [snapshot])
        } catch {
            self.latestSnapshot = snapshot
            self.recordsCollectionView?.reloadData()
            DocsLogger.btError("[DIFF] [Table] diffing table model failed with error \(error.localizedDescription)")
            return true
        }

        guard !differences.isEmpty else {
            completion?(false)
            return false
        }

        self.handleDifferences(snapshot, differences: differences, completion: completion)
        return true
    }

    func attachmentCoverChanged(_ snapshot: BTTableModel) -> Bool {
        guard let newRecord = snapshot.records.first, let oldRecord = latestSnapshot.records.first else {
            return false
        }
        return newRecord.attachmentCoverChanged(oldRecord)
    }

    func handleDifferences(_ snapshot: BTTableModel,
                              differences: [Changeset<BTTableModel>],
                              completion: ((Bool) -> Void)? = nil) {

        let manager = DifferencesCompletionManager(differences: differences) {
            completion?(true)
        }
        
        /// 执行任务
        UIView.performWithoutAnimation {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            
            for (index, difference) in differences.enumerated() {
                // 1. diff 数据为空直接 reloadData。
                guard let finalSectionForThisStep = difference.finalSections.first else {
                    latestSnapshot = snapshot
                    recordsCollectionView?.reloadData()
                    manager.finishDiffereceTask(index: index, isFinishAllTask: true)
                    break
                }
                
                // 2. 原先数据为空或当前数据为空时，直接 reloadData()
                guard !latestSnapshot.items.isEmpty && !finalSectionForThisStep.items.isEmpty else {
                    latestSnapshot = finalSectionForThisStep
                    recordsCollectionView?.reloadData()
                    manager.finishDiffereceTask(index: index, isFinishAllTask: true)
                    continue
                }
                
                if #unavailable(iOS 13.0), !UserScopeNoChangeFG.ZJ.btDiffFixIOS12Disable {
                    handleUpdateForIOS12(difference,
                                         finalSectionForThisStep: finalSectionForThisStep,
                                         finalSnapshot: snapshot) {
                        manager.finishDiffereceTask(index: index)
                    }
                    continue
                }
                
                // 3. 需要处理 diff
                // 3.1 因为 RxDataSources 的 diff 算法 delete 和 update 合一起了，所以这里要做特殊处理。
                if DifferencesCompletionManager.hasUpdate(of: difference) {
                    recordsCollectionView?.performBatchUpdates({
                        difference.updatedItems.forEach { [weak self] item in
                            guard let self = self else { return }
                            guard item.itemIndex < latestSnapshot.records.count else { return }
                            let oldRecord = self.latestSnapshot.records[item.itemIndex]
                            var newRecord: BTRecordModel?
                            if !UserScopeNoChangeFG.ZJ.recordDiffFixDisable {
                                newRecord = finalSectionForThisStep.items.first(where: { $0.identify == oldRecord.identify })
                            } else {
                                newRecord = finalSectionForThisStep.items.first(where: { $0.recordID == oldRecord.recordID })
                            }
                            
                            if let record = newRecord {
                                self.latestSnapshot.updateRecord(record, for: item.itemIndex)
                            }
                        }
                        updateItems(at: difference.updatedItems.map { IndexPath(item: $0.itemIndex, section: $0.sectionIndex) })
                    }, completion: { _ in
                        manager.finishDiffereceTask(index: index)
                    })
                }
                if DifferencesCompletionManager.hasDeleteOrInsertOrMove(of: difference) {
                    recordsCollectionView?.performBatchUpdates({
                        latestSnapshot = finalSectionForThisStep
                        deleteItems(at: difference.deletedItems.map { IndexPath(item: $0.itemIndex, section: $0.sectionIndex) })
                        insertItems(at: difference.insertedItems.map { IndexPath(item: $0.itemIndex, section: $0.sectionIndex) })
                        difference.movedItems.forEach { (from: ItemPath, to: ItemPath) in
                            moveItem(from: IndexPath(item: from.itemIndex, section: from.sectionIndex),
                                     to: IndexPath(item: to.itemIndex, section: to.sectionIndex))
                        }
                    }, completion: { _  in
                        manager.finishDiffereceTask(index: index)
                    })
                }
            }
        }
        CATransaction.commit()
    }

    func updateTopFieldID(_ topFieldID: String) {
        guard currentTopFieldID != topFieldID else { return }
        currentTopFieldID = topFieldID
        recordsCollectionView?.visibleCells.forEach { cell in
            guard let record = cell as? BTRecord else { return }
            DocsLogger.btInfo("btcontroller currentTopFieldId:\(currentTopFieldID) recordId:\(record.recordID)")
            record.currentTopFieldID = currentTopFieldID
        }
    }

    func deleteItems(at indexPaths: [IndexPath]) {
        guard !indexPaths.isEmpty else { return }
        DocsLogger.btInfo("[DIFF] [Table] delete card items \(indexPaths), current items count: \(latestSnapshot.items.count)")
        recordsCollectionView?.deleteItems(at: indexPaths)
    }

    func insertItems(at indexPaths: [IndexPath]) {
        guard !indexPaths.isEmpty else { return }
        DocsLogger.btInfo("[DIFF] [Table] insert card items \(indexPaths), current items count: \(latestSnapshot.items.count)")
        recordsCollectionView?.insertItems(at: indexPaths)
    }

    func forceUpdateItemsIfNeeded(at indexPath: IndexPath, cell: UICollectionViewCell) {
        guard let _ = recordsCollectionView else { return }
        let index = indexPath.item
        guard 0 <= index, index < latestSnapshot.items.count else {
            spaceAssertionFailure("[DIFF] [Table] index out of bounds")
            return
        }
        guard latestSnapshot.records[index].forceUpdateWhenWillDisplay else {
            return
        }
        latestSnapshot.update(forceUpdateWhenWillDisplay: false, recordIndex: index)
        guard let record = cell as? BTRecord else {
            DocsLogger.btError("[DIFF] [Table] cell is not BTRecord")
            return
        }
        configureRecord(record, withModel: latestSnapshot.records[index], usingReloadData: false)
    }

    func updateItems(at indexPaths: [IndexPath]) {
        guard let recordsCollectionView = recordsCollectionView else { return }
        for indexPath in indexPaths {
            let index = indexPath.item
            guard 0 <= index, index < latestSnapshot.items.count else {
                spaceAssertionFailure("[DIFF] [Table] index out of bounds")
                break
            }
            DocsLogger.btInfo("[DIFF] [Table] update card item \(index), current items count: \(latestSnapshot.items.count)")
            if let cell = recordsCollectionView.cellForItem(at: indexPath) {
                if recordsCollectionView.indexPathsForVisibleItems.contains(indexPath) {
                    if let record = cell as? BTRecord {
                        configureRecord(record, withModel: latestSnapshot.records[index], usingReloadData: false)
                    }
                } else {
                    latestSnapshot.update(forceUpdateWhenWillDisplay: true, recordIndex: index)
                }
            }
        }
    }

    func moveItem(from oldIndexPath: IndexPath, to newIndexPath: IndexPath) {
        DocsLogger.btInfo("[DIFF] [Table] move card item from \(oldIndexPath) to \(newIndexPath), current items count: \(latestSnapshot.items.count)")
        recordsCollectionView?.moveItem(at: oldIndexPath, to: newIndexPath)
    }

    func configureRecord(_ recordCell: BTRecord, withModel model: BTRecordModel, usingReloadData: Bool) {
        guard let cardsLayout = recordsCollectionView?.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        recordCell.delegate = recordsDelegate
        recordCell.context = context
        var recordModel = model
        recordModel.update(cardSize: cardsLayout.itemSize)
        /* RecordCell 每次更新数据源的时候 或者没有内存缓存 会拉取订阅状态 */
        if let enableSubscribe = recordsDelegate?.recordEnableSubscribe(record: recordModel), enableSubscribe {
            let shouldRequestSubscribeStatus = recordsDelegate?.fetchLocalRecordSubscribeStatus(recordId: recordModel.recordID) == .unknown || usingReloadData
            if shouldRequestSubscribeStatus {
                recordsDelegate?.fetchRemoteRecordSubscribeStatus(recordId: recordModel.recordID, completion: { _ in
                    //防止异步Record复用导致的错误更新
                    if recordCell.recordModel.recordID == recordModel.recordID {
                        recordCell.updateRecordSubscribeState()
                    }
               })
            }
        }
        
        if SKDisplay.phone && UIApplication.shared.statusBarOrientation.isLandscape {
            recordModel.update(canEditRecord: false)
            recordModel.update(fieldEditable: false, fieldUneditableReason: .phoneLandscape)
        } else if recordModel.editable {
            if !bitableIsReady {
                // 禁止和打开权限需要更严格
                recordModel.update(canEditRecord: false)
                recordModel.update(fieldEditable: false, fieldUneditableReason: .bitableNotReady)
            }
        }
        if !recordCell.fieldsViewHasLoaded || usingReloadData {
            // 没加载过model, 或者完全刷新
            recordCell.loadInitialModel(recordModel, context: context)
        } else {
            recordCell.updateModel(recordModel)
        }
        DispatchQueue.main.async {
            if recordCell.currentTopFieldID != self.currentTopFieldID {
                recordCell.currentTopFieldID = self.currentTopFieldID
            }
        }
    }
    
    // iOS12上多个changset要放到一个performBatchUpdates里面处理，不然会crash
    //https://slardar.bytedance.net/node/app_detail/?aid=1161&os=iOS&region=cn&lang=zh#/abnormal/detail/crash/0646a740d7796874a0a6c01673396af3?params=%7B%22token%22%3A%22%22%2C%22token_type%22%3A0%2C%22crash_time_type%22%3A%22insert_time%22%2C%22start_time%22%3A1675915080%2C%22end_time%22%3A1676519880%2C%22granularity%22%3A86400%2C%22filters_conditions%22%3A%7B%22type%22%3A%22and%22%2C%22sub_conditions%22%3A%5B%5D%7D%2C%22ios_issue_id_version%22%3A%22v2%22%2C%22event_index%22%3A1%7D
    // 分多个performBatchUpdates处理的原因是为了修复https://meego.feishu.cn/larksuite/issue/detail/5633782?parentUrl=/larksuite/issueView/SBg67fTcn
    // RxDifference有问题，update会用之前的index
    // 合到一个performBatchUpdates后，验证没问题
    private func handleUpdateForIOS12(_ difference: Changeset<BTTableModel>,
                                      finalSectionForThisStep: BTTableModel,
                                      finalSnapshot: BTTableModel,
                                      completion: (() -> Void)? = nil) {
        DocsLogger.btInfo("[DIFF] [Table] handleUpdateForIOS12")
        if DifferencesCompletionManager.hasDeleteOrInsertOrMove(of: difference) {
            DocsLogger.btInfo("[DIFF] [Table] handleDeleteOrInsertOrMoveForIOS12")
            latestSnapshot = finalSnapshot
            recordsCollectionView?.reloadData()
            completion?()
            return
        }
        
        if DifferencesCompletionManager.hasUpdate(of: difference) {
            difference.updatedItems.forEach { [weak self] item in
                guard let self = self else { return }
                guard item.itemIndex < latestSnapshot.records.count else { return }
                let oldRecord = self.latestSnapshot.records[item.itemIndex]
                var newRecord: BTRecordModel?
                if !UserScopeNoChangeFG.ZJ.recordDiffFixDisable {
                    newRecord = finalSectionForThisStep.items.first(where: { $0.identify == oldRecord.identify })
                } else {
                    newRecord = finalSectionForThisStep.items.first(where: { $0.recordID == oldRecord.recordID })
                }
                
                if let record = newRecord {
                    self.latestSnapshot.updateRecord(record, for: item.itemIndex)
                }
            }
            updateItems(at: difference.updatedItems.map { IndexPath(item: $0.itemIndex, section: $0.sectionIndex) })
        }
        completion?()
    }
}


extension BitableTableDiffableDataSource {

    func getRecordCount() -> Int {
        return latestSnapshot.records.count
    }
    
    func getIndexPathForRecord(recordId: String, groupValue: String) -> IndexPath? {
        guard let index = latestSnapshot.records.firstIndex(where: { $0.recordID == recordId && $0.groupValue == groupValue }) else {
            return nil
        }
        return IndexPath(row: index, section: 0)
    }

    func getRecordID(forCardIndex index: Int) -> String? {
        guard 0 <= index, index < latestSnapshot.records.count else {
            DocsLogger.btError("[BitableTableDiffableDataSource] getRecordID index:\(index) out of range")
            return nil
        }
        return latestSnapshot.records[index].recordID
    }
    
    func getRecordGroupValue(forCardIndex index: Int) -> String? {
        guard 0 <= index, index < latestSnapshot.records.count else {
            DocsLogger.btError("[BitableTableDiffableDataSource] getRecordGroupValue index:\(index) out of range")
            return nil
        }
        return latestSnapshot.records[index].groupValue
    }
}


final class DifferencesCompletionManager {
    
    private var differenceTasks: [Int: Int] = [:]
    
    private var didCompletion: (() -> Void)?
    
    init<T: AnimatableSectionModelType>(differences: [Changeset<T>], completion: (() -> Void)?) {
        /// 收集当前 diff 执行那些 task 才算完成
        var differenceTasks: [Int: Int] = [:]
        for (index, difference) in differences.enumerated() {
            var differenceTaskValue = 0
            if Self.hasUpdate(of: difference) {
                differenceTaskValue += 1
            }
            if Self.hasDeleteOrInsertOrMove(of: difference) {
                differenceTaskValue += 1
            }
            differenceTasks.updateValue(differenceTaskValue, forKey: index)
        }
        self.differenceTasks = differenceTasks
        self.didCompletion = completion
    }
    
    /// 每执行一次任务就调用一次。
    func finishDiffereceTask(index: Int, isFinishAllTask: Bool = false) {
        // 这里不要添加 weak, 这里是需要通过捕获来进行执行的。
        DispatchQueue.main.async {
            var tasks = self.differenceTasks
            DocsLogger.btInfo("[DIFF] DifferencesCompletionManager finishDiffereceTask: \(index) isAll: \(isFinishAllTask)  tasks \(tasks)")
            if isFinishAllTask {
                tasks.removeValue(forKey: index)
            } else if var taskValue = tasks[index], taskValue > 0 {
                taskValue -= 1
                if taskValue <= 0 {
                    tasks.removeValue(forKey: index)
                } else {
                    tasks.updateValue(taskValue, forKey: index)
                }
            }
            let resetTaskValue = tasks.reduce(0) { $0 + $1.value }
            self.differenceTasks = tasks
            if resetTaskValue <= 0 {
                DocsLogger.btInfo("[DIFF] DifferencesCompletionManager completion ")
                self.didCompletion?()
            }
        }
    }
    
    /// 判断是否有增删移操作
    static func hasDeleteOrInsertOrMove<T: AnimatableSectionModelType>(of difference: Changeset<T>) -> Bool {
        return (difference.insertedItems.count + difference.deletedItems.count + difference.movedItems.count) > 0
    }
    /// 判断是否有 update 操作
    static func hasUpdate<T: AnimatableSectionModelType>(of difference: Changeset<T>) -> Bool {
        return difference.updatedItems.count > 0
    }
}
