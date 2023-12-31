//
//  BTController+ViewModelListener.swift
//  DocsSDK
//
//  Created by linxin on 2020/3/19.
//


import UIKit
import EENavigator
import SKCommon
import SKResource
import SKFoundation
import SKUIKit
import UniverseDesignToast
import SKBrowser

extension BTController: BTViewModelListener {
    
    func didFailRequestingValue() {
        closeAllCardsAndClear()
    }
    
    func didRequestingValueErrorWhenOpenCard(_ error: Error?) {
        if let toastVC = self.delegate?.cardGetBrowserController() {
            let toastView: UIView = toastVC.view.window ?? toastVC.view
            UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Error_SyetemErrorCommonTips_Mobile, on: toastView)
        }
        closeAllCardsAndClear()
    }

    func didFailRequestingMeta() {
        closeAllCardsAndClear()
    }
    
    /// 请求失败时需要做清理操作
    private func closeAllCardsAndClear() {
        // 请求失败，隐藏骨架
        if UserScopeNoChangeFG.XM.cardOpenLoadingEnable {
                checkHideLoading()
        }
        closeAllCards()
        self.showCardActionTask?.completedBlock()
        self.showCardActionTask = nil
        notifyToFrontAndClearWhenDidClose()
    }
    
    func didLoadInitial(model: BTTableModel) {
        loadInitialModel(model)
    }
    
    func bitableReady() {
        notifyBitableIsReady()
    }

    func didUpdateModel(model: BTTableModel) {
        guard !isTransitioningSize else { return }
        // 更新卡片数据
        cardsLayout.isUpdatingData = true
        cardsLayout.currentIndex = viewModel.currentRecordIndex
        updateModel(model, completion: { [weak self] _ in
            guard let self = self else { return }
            self.cardsLayout.isUpdatingData = false
            DocsLogger.btInfo("[DIFF] finished updating data for \(model.tableID), recordsCount: \(model.records.count)")
        })
        
        // 更新编辑面板数据（若有）
        if let currentEditAgent = currentEditAgent {
            let editingRecordID = currentEditAgent.recordID
            let editingFieldID = currentEditAgent.fieldID
            if let editingRecordModel = model.getRecordModel(id: editingRecordID) {
                if let editingFieldModel = editingRecordModel.getFieldModel(id: editingFieldID) {
                    currentEditAgent.updateInput(fieldModel: editingFieldModel)
                } else {
                    // 正在编辑的字段没了，关掉编辑面板
                    currentEditAgent.stopEditing(immediately: false, sync: false)
                }
            } else {
                // 正在编辑的卡片没了，关掉编辑面板
                currentEditAgent.stopEditing(immediately: false, sync: false)
            }
        }
        if UserScopeNoChangeFG.YY.baseAddRecordPage {
            if viewModel.mode.isIndRecord, let browser = delegate?.cardGetBrowserController() as? BrowserViewController {
                let title = viewModel.tableModel.records.first?.recordTitle
                browser.browserViewDidUpdateDocName(browser.editor, docName: title)
            }
        }
    }

    func didUpdateMeta(meta: BTTableMeta) {
        closeDescriptionPanelWhenFieldIsRemoved(from: meta.fields)
        stopEditingWhenFieldIsRemoved(from: meta.fields)
        titleView.setTitle(meta.tableName)
    }

    private func closeDescriptionPanelWhenFieldIsRemoved(from fields: [String: BTFieldMeta]) {
        // 感觉这么写不是很好，MagicShare 可能会有问题？要不 BTController 里维护一个 BTFieldDescriptionPanel 的弱引用？
        if let presentedNav = presentedViewController as? UINavigationController,
           let presentedDescPanel = presentedNav.viewControllers.first as? BTFieldDescriptionPanel {
            let currentShowingFieldID = presentedDescPanel.fieldID
            if fields[currentShowingFieldID] == nil {
                presentedNav.dismiss(animated: true, completion: nil)
            }
        }
    }

    func stopEditingWhenFieldIsRemoved(from fields: [String: BTFieldMeta]) {
        if let currentEditAgent = currentEditAgent,
           false == fields.keys.contains(currentEditAgent.fieldID) {
            currentEditAgent.stopEditing(immediately: false, sync: false)
        }
    }

    func jsRequestCloseCard(newAction: BTCardActionTask) {
        //处理VCFollow bitable at doc/docx情况下多block时，在不同的block之间切换时，showCard和closeCard的时序不能保证，会导致关闭了错误的卡片，
        //因此前端在closeCard时加上tableId字段，用来判断是否需要执行closeCard
        if newAction.actionParams.data.tableId == viewModel.actionParams.data.tableId ||
            newAction.actionParams.data.tableId.isEmpty {
            closeAllCards {
                newAction.completedBlock()
            }
        } else {
            newAction.completedBlock()
        }
    }
    
    func jsRequestCardHidden(newAction: BTCardActionTask, isHidden: Bool) {
        view.isHidden = isHidden
        newAction.completedBlock()
    }

    func currentCardScrollToField(at indexPath: IndexPath, scrollPosition: UICollectionView.ScrollPosition) {
        currentCard?.scrollToField(at: indexPath, scrollPosition: scrollPosition, animated: false)
    }
    
    func currentCardScrollToField(with fieldId: String, scrollPosition: UICollectionView.ScrollPosition) {
        currentCard?.scrollToField(with: fieldId, scrollPosition: scrollPosition)
    }

    func scrollToDesignatedCard(animated: Bool, completion: (() -> Void)? = nil) {
        scrollToCurrentCard(animated: animated, completion: completion)
    }

    func notifyScrollToCardField(fieldID: String) {
        scrollToCardField(fieldID: fieldID)
    }

    func notifyRefreshDataByShowCard() {
        scrollToDesignatedCard(animated: false, completion: nil)
        notifyFrontCardDidOpen()
    }
}
