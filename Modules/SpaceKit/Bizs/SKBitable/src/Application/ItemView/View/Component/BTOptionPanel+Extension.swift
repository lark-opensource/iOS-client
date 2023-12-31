//
//  BTOptionPanel+Extension.swift
//  SKBitable
//
//  Created by zoujie on 2021/10/28.
//  


import Foundation
import SKBrowser
import EENavigator
import SKResource
import SKFoundation
import UniverseDesignInput
import UniverseDesignActionPanel

extension BTOptionPanel: UITableViewDataSource, UITableViewDelegate {
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < optionFilterModel.count else { return }
        tableView.deselectRow(at: indexPath, animated: false)
        didSelectedModel(model: optionFilterModel[indexPath.row])
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }

    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return optionFilterModel.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseID, for: indexPath)
        guard indexPath.row < optionFilterModel.count else { return cell }
        if let cell = cell as? BTOptionPanelTableViewCell {
            let info = optionFilterModel[indexPath.row]
            cell.update(text: info.text,
                        colors: info.color,
                        isSingle: isSingle,
                        isSelected: info.isSelected,
                        canEdit: canEdit)
            cell.model = info
            cell.delegate = self
            //最后一个cell不需要显示下划线
            cell.updateSeparatorStatus(isLast: indexPath.row == optionModel.count - 1)
        }
        return cell
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        currentContentOffset = scrollView.contentOffset
        currentViewHeight = self.bounds.height
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard currentContentOffset.y == 0 else { return }

        let gestureRecongnizer = scrollView.panGestureRecognizer
        let yTranslation = gestureRecongnizer.translation(in: self).y

        //当前view已经是最大高度，则不响应向上滑动改变高度的操作
        if currentViewHeight == maxViewHeight, yTranslation > 0 {
            return
        }

        var height = currentViewHeight - yTranslation

        defer {
            lastPositionY = yTranslation
        }

        guard !keyboardIsShow,
              height <= maxViewHeight,
              !isStopEditing,
              let host = hostVC else {
                  return
              }

        DocsLogger.info("bitable option scrollViewDidScroll height:\(height) currentViewHeight:\(currentViewHeight)")

        self.gestureManager.resizePanel(panel: self, to: host.view.bounds.height - height)
        scrollView.contentOffset = currentContentOffset
    }
}

extension BTOptionPanel: UDTextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        //埋点上报
        delegate?.trackOptionFieldEvent(event: DocsTracker.EventType.bitableOptionFieldPanelClick.rawValue,
                                        params: getTrackParams(click: "search",
                                                               isSingle: isSingle))
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchBar.resignFirstResponder()
        return true
    }
}

extension BTOptionPanel: BTOptionPanelTableViewCellDelegate {
    func didClickMoreButton(model: BTCapsuleModel) {
        guard let host = hostVC else { return }
        resetSearchBar()
        //埋点上报
        delegate?.trackOptionFieldEvent(event: DocsTracker.EventType.bitableOptionFieldPanelClick.rawValue,
                                        params: getTrackParams(click: "option_more",
                                                               target: "ccm_bitable_option_field_more_view",
                                                               isSingle: isSingle))
        optionMenu = BTOptionMorePanel(model: model)
        guard let menu = optionMenu else { return }
        menu.delegate = self
        menu.modalPresentationStyle = .overFullScreen
        menu.updateLayoutWhenSizeClassChanged = false
        menu.transitioningDelegate = menu.panelTransitioningDelegate
        Navigator.shared.present(menu, from: host) { [weak self] _ in
            //埋点上报
            self?.delegate?.trackOptionFieldEvent(event: DocsTracker.EventType.bitableOptionFieldMoreViewOpen.rawValue,
                                                  params: [:])
        }
    }
}

extension BTOptionPanel: BTOptionEditorPanelDelegate {
    func didClickSelect(model: BTCapsuleModel) {
        editPanel?.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.lastClickItem = model
            self.didSelectedModel(model: model)
        }
    }

    func didClickCancel() {
        editPanel?.dismiss(animated: true)
    }

    func didClickDone(model: BTCapsuleModel, editMode: BTOptionEditMode) {
        editPanel?.dismiss(animated: true)
        //通知前端更新数据源
        //删除选项model，通知前端
        switch editMode {
        case .add:
            lastClickItem = model
            var newModels = optionModel
            newModels.insert(model, at: 0)
//            optionView.reloadData()
            let options = getModelsJSON(models: newModels)
            delegate?.executeCommands(command: .setFieldAttr,
                                      property: options,
                                      extraParams: nil,
                                      resultHandler: { _, _ in })
        case .update:
            let newModels = optionModel.map { m -> BTCapsuleModel in
                if m.id == model.id {
                    return model
                }
                return m
            }
//            optionView.reloadData()
            let options = getModelsJSON(models: newModels)
            delegate?.executeCommands(command: .setFieldAttr,
                                      property: options,
                                      extraParams: nil,
                                      resultHandler: { _, _ in })
        }
    }

    func trackOptionEditEvent(event: String, params: [String: Any]) {
        delegate?.trackOptionFieldEvent(event: event, params: params)
    }
}

extension BTOptionPanel: BTOptionMorePanelDelegate {
    func showConfirmActionPanel(model: BTCapsuleModel) {
        guard let host = hostVC else { return }
        //埋点上报
        delegate?.trackOptionFieldEvent(event: DocsTracker.EventType.bitableOptionFieldMoreViewClick.rawValue,
                                        params: getTrackParams(click: "delete",
                                                               target: "ccm_bitable_option_field_delete_view"))
        let sourceView = optionView.visibleCells.first { cell in
            if let optionCell = cell as? BTOptionPanelTableViewCell {
                return optionCell.model == model
            }
            return false
        }
        let source = UDActionSheetSource(sourceView: sourceView ?? self,
                                         sourceRect: sourceView?.bounds ?? self.bounds)

        let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: true, popSource: source))
        
        actionSheet.setTitle(BundleI18n.SKResource.Bitable_Option_ConfirmToDelete)
        actionSheet.addDestructiveItem(text: BundleI18n.SKResource.Bitable_Common_ButtonDelete) { [weak self] in
            guard let self = self else { return }
            //删除选项model，通知前端
            let updateModel = self.optionModel.filter({ $0.id != model.id })

            let options = self.getModelsJSON(models: updateModel)
            self.delegate?.executeCommands(command: .setFieldAttr,
                                           property: options,
                                           extraParams: nil,
                                           resultHandler: { _, _ in })

            //埋点上报
            self.delegate?.trackOptionFieldEvent(event: DocsTracker.EventType.bitableOptionFieldDeleteViewClick.rawValue,
                                                  params: ["click": "delete"])
        }
        actionSheet.setCancelItem(text: BundleI18n.SKResource.Bitable_Common_ButtonCancel) { [weak self] in
            //埋点上报
            self?.delegate?.trackOptionFieldEvent(event: DocsTracker.EventType.bitableOptionFieldDeleteViewClick.rawValue,
                                                  params: ["click": "cancel"])
        }

        self.actionSheet = actionSheet

        Navigator.shared.present(actionSheet, from: host) { [weak self] _ in
            //埋点上报
            self?.delegate?.trackOptionFieldEvent(event: DocsTracker.EventType.bitableOptionFieldDeleteViewOpen.rawValue,
                                                  params: [:])
        }
    }

    func showEditorPanel(model: BTCapsuleModel) {
        currentEditModel = model
        //埋点上报
        delegate?.trackOptionFieldEvent(event: DocsTracker.EventType.bitableOptionFieldMoreViewClick.rawValue,
                                        params: getTrackParams(click: "edit",
                                                               target: "ccm_bitable_option_field_edit_view"))
        showEditPanel(model: model, editMode: .update)
    }
}

extension BTOptionPanel: CustomBTOptionButtonDelegate {
    func didClick(model: BTCapsuleModel) {
        //埋点上报
        delegate?.trackOptionFieldEvent(event: DocsTracker.EventType.bitableOptionFieldPanelClick.rawValue,
                                        params: getTrackParams(click: "create_option",
                                                               target: isSingle ? "none" : "ccm_bitable_option_field_panel_view",
                                                               isSingle: isSingle))
        var newModel = optionModel
        newModel.insert(model, at: 0)
//        optionView.reloadData()
        let options = getModelsJSON(models: newModel)
        lastClickItem = model
        delegate?.executeCommands(command: .setFieldAttr,
                                  property: options,
                                  extraParams: nil,
                                  resultHandler: { _, _ in })
        resetSearchBar()
        hideAddButton()
        didSelectedModel(model: model)
    }
}
