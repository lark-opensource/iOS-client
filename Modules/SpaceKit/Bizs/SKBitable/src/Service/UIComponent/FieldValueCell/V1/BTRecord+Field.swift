// 
// Created by duanxiaochen.7 on 2020/3/25.
// Affiliated with DocsSDK.
// 
// Description:

import Foundation
import UIKit
import SKCommon
import SKFoundation
import SKBrowser
import SKUIKit
import SKInfra
import SKResource
import UniverseDesignToast
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignActionPanel
import UniverseDesignMenu
import UniverseDesignIcon

// MARK: - BTFieldDelegate
protocol BTFieldDelegate: AnyObject {
    var baseContext: BaseContext? { get }
    var holdDataProvider: BTHoldDataProvider? { get }
    func didTapView(withAttributes: [NSAttributedString.Key: Any], inFieldModel: BTFieldModel?)
    func didDoubleTap(_ sender: BTFieldCellProtocol, field: BTFieldModel)

    func showDescriptionPanel(forFieldModel: BTFieldModel, fromButton: UIButton)
    func changeDescriptionLimitMode(forFieldID: String, toLimited: Bool)

    /// - Parameters:
    ///   - field: field
    ///   - scrollPosition: `nil`: do not scroll; `top`, `middle`, `bottom`: scroll to that position
    func panelDidStartEditingField(_: BTFieldCellProtocol, scrollPosition: UICollectionView.ScrollPosition?)
    func stopEditingField(_: BTFieldCellProtocol, scrollPosition: UICollectionView.ScrollPosition?)

    func generateHapticFeedback()
    
    func startEditing(inField: BTFieldCellProtocol, newEditAgent: BTBaseEditAgent?)

    func didTapChatter(with model: BTCapsuleModel)
    func startPickingChatter(forField field: BTFieldChatterCellProtocol)
    
    func startEditProgress(forField: BTFieldCellProtocol)

    func previewAttachments(_: [BTAttachmentModel], atIndex: Int)
    func previewAttachments(_: [BTAttachmentModel], atIndex: Int, inFieldWithID: String)
    func previewAttachments(_: [PendingAttachment], atIndex: Int)
    func deleteAttachment(data: BTAttachmentModel, inFieldWithID: String)
    func deleteAttachment(data: PendingAttachment, inFieldWithID: String)
    func cancelAttachment(data: BTMediaUploadInfo, inFieldWithID: String)
    func didClickAddAttachment(inField: BTFieldCellProtocol)

    func didToggleCheckbox(forFieldID: String, toStatus: Bool)

    func linkCell(_ cell: BTFieldLinkCellProtocol, didClickRecordWithID: String)
    func startModifyLinkage(fromField: BTFieldLinkCellProtocol)
    func cancelLinkage(fromFieldID: String, toRecordID: String, inFieldModel: BTFieldModel)

    func didClickOpenLocation(inField: BTFieldCellProtocol)
    func didClickCopyMenuItem(inField: BTGeoLocationField)
    func track(event: String, params: [String: Any])

    func didTapSubmit()

    func deleteRecord(sourceView: UIView)
    
    func openUrl(_ url: String, inFieldModel: BTFieldModel)
    
    func getCopyPermission() -> BTCopyPermission?
    
    func textViewOfField(_ field: BTFieldModel, shouldAppyAction action: BTTextViewMenuAction) -> Bool
    
    func presentViewController(_ vc: UIViewController)
    
    ///记录卡片当前滚动的偏移量，用来处理多行文本跟卡片的滚动冲突
    func startRecordContentOffset()
    
    ///设置当前卡片内容是否可滚动，当多行文本在滚动时，卡片保持多行文本滚动开始时的偏移量
    func setRecordScrollEnable(_ enable: Bool)
    
    /// 点击了button字段
    func didClickButtonField(inFieldWithID fieldID: String)
    ///更新当前按钮字段的状态
    func updateButtonFieldStatus(to status: BTButtonFieldStatus, inFieldWithID fieldID: String)
    /// 点击了表单Record超限制的了解更多
    func didClickRecordLimitMoreInForm()
    /// 阶段字段点击
    func stageFieldClick(with fieldModel: BTFieldModel)
    /// 阶段字段详情mockField切换option, 只保留index
    func stageDetailFieldChange(with stageIndex: Int)
    /// 阶段字段详情点击终止流程
    func stageDetailFieldClickCancel(sourceView: UIView, fieldModel: BTFieldModel, cancelOptionId: String)
    /// 阶段字段详情点击完成流程
    func stageDetailFieldClickDone(fieldModel: BTFieldModel, currentOptionId: String)
    /// 阶段字段详情点击重置流程
    func stageDetailFieldClickRevert(sourceView: UIView, fieldModel: BTFieldModel, currentOptionId: String)
    /// 阶段字段详情点击恢复流程
    func stageDetailFieldClickRecover(fieldModel: BTFieldModel)
    /// itemView点击tab切换
    func didClickTab(index: Int)
    /// 获取当前卡片弹出模式
    func getCurrentCardPresentMode() -> CardPresentMode
    /// 获取当前打开 itemView 的 traceId
    func getOpenRecordTraceId() -> String?
    // 获取卡片的 global Index
    func getGlobalRecordIndex() -> Int
    /// 点击了目录条上的 BaseName
    func didClickCatalogueBaseName()
    /// 点击了目录条上的 TableName
    func didClickCatalogueTableName()
}

extension BTRecord: BTFieldDelegate {
    
    var holdDataProvider: BTHoldDataProvider? {
        delegate?.holdDataProvider
    }
    
    var baseContext: BaseContext? {
        delegate?.baseContext
    }

    func didTapView(withAttributes attributes: [NSAttributedString.Key: Any], inFieldModel: BTFieldModel?) {
        delegate?.didTapView(withAttributes: attributes, inFieldModel: inFieldModel)
    }
    
    func didDoubleTap(_ sender: BTFieldCellProtocol, field: BTFieldModel) {
        delegate?.didDoubleTap(self, field: field)
    }

    func showDescriptionPanel(forFieldModel fieldModel: BTFieldModel, fromButton button: UIButton) {
        guard let descriptionSegments = fieldModel.description?.content else {
            spaceAssertionFailure("不可能显示不存在的字段描述，请保留现场")
            return
        }
        let fieldName = fieldModel.name
        let fieldID = fieldModel.fieldID
        let result = BTUtil.convert(descriptionSegments,
                                    font: BTFieldLayout.Const.fieldDescriptionFont,
                                    forTextView: nil)
        delegate?.showDescriptionPanel(withAttrText: result, forFieldID: fieldID, fieldName: fieldName, fromButton: button)
    }

    func changeDescriptionLimitMode(forFieldID fieldID: String, toLimited isLimited: Bool) {
        delegate?.saveEditing(animated: true)
        delegate?.setDescriptionLimitState(forFieldID: fieldID, to: isLimited)
    }

    func panelDidStartEditingField(_ field: BTFieldCellProtocol, scrollPosition: UICollectionView.ScrollPosition? = nil) {
        if let scrollPosition = scrollPosition {
            if scrollPosition != .bottom, let indexPath = fieldsView.indexPath(for: field) {
                scrollToField(at: indexPath, scrollPosition: scrollPosition)
            } else {
                scrollTillFieldBottomIsVisible(field)
            }
        }
    }

    func stopEditingField(_ field: BTFieldCellProtocol, scrollPosition: UICollectionView.ScrollPosition? = nil) {
        if let scrollPosition = scrollPosition, let indexPath = fieldsView.indexPath(for: field) {
            scrollToField(at: indexPath, scrollPosition: scrollPosition)
        }
        delegate?.didEndEditingField()
    }

    func generateHapticFeedback() {
        delegate?.generateHapticFeedback()
    }
    
    func startEditing(inField field: BTFieldCellProtocol, newEditAgent: BTBaseEditAgent?) {
        delegate?.startEditing(field, newEditAgent: newEditAgent)
    }
    
    func startEditProgress(forField field: BTFieldCellProtocol) {
        delegate?.startEditing(field, newEditAgent: nil)
    }
    
    func startPickingChatter(forField field: BTFieldChatterCellProtocol) {
        delegate?.startEditing(field, newEditAgent: nil)
    }
    func didTapChatter(with model: BTCapsuleModel) {
        delegate?.didClickChatter(model)
    }

    func previewAttachments(_ attachments: [BTAttachmentModel], atIndex: Int) {
        delegate?.previewAttachments(attachments, atIndex: atIndex)
    }

    func previewAttachments(_ attachments: [BTAttachmentModel], atIndex: Int, inFieldWithID fieldID: String) {
        delegate?.logAttachmentEvent(action: "preview", attachmentCount: nil)
        
        //先判断PendingAttachment，如是pending则以Local方式展示。(目前不存在pending & existing混合的情况)
        var pendingAttachments = [PendingAttachment.LocalFile]()
        var pendingPreviewIndex = atIndex
        for (i, attachment) in attachments.enumerated() {
            if i == atIndex {
                pendingPreviewIndex = pendingAttachments.count //修正index，避免万一出现pending & existing混合的情况
            }
            if let url = recordModel.localStorageURLs[attachment.attachmentToken], SKFilePath(absUrl: url).exists {
                let file = PendingAttachment.LocalFile(fileName: attachment.name, fileURL: url)
                pendingAttachments.append(file)
            }
        }
        DocsLogger.btInfo("[ACTION] previewAttachments in field, pending: \(pendingAttachments.count), normal: \(attachments.count)")
        if !pendingAttachments.isEmpty {
            delegate?.previewLocalAttachments(pendingAttachments, atIndex: pendingPreviewIndex)
        } else {
            delegate?.previewAttachments(attachments, atIndex: atIndex, inFieldWithID: fieldID)
        }
    }

    func previewAttachments(_ attachments: [PendingAttachment], atIndex: Int) {
        let localFiles = attachments.map { PendingAttachment.LocalFile(fileName: $0.mediaInfo.name, fileURL: $0.mediaInfo.storageURL) }
        delegate?.previewLocalAttachments(localFiles, atIndex: atIndex)
    }

    func deleteAttachment(data: BTAttachmentModel, inFieldWithID fieldID: String) {
        
        delegate?.newLogAttachmentEvent(.operateClick(action: .delete, isOnlyCamera: nil))
        delegate?.logAttachmentEvent(action: "delete_attachment", attachmentCount: nil)
        delegate?.deleteAttachment(data: data, inFieldWithID: fieldID)
    }

    func deleteAttachment(data: PendingAttachment, inFieldWithID fieldID: String) {
        delegate?.deletePendingAttachment(data: data)
    }
    
    func cancelAttachment(data: BTMediaUploadInfo, inFieldWithID fieldID: String) {
        delegate?.logAttachmentOperate(action: "upload_delete")
        delegate?.cancelUploadingAttachment(data: data)
    }

    func didClickAddAttachment(inField field: BTFieldCellProtocol) {
        delegate?.newLogAttachmentEvent(.operateClick(action: .add, isOnlyCamera: nil))
        delegate?.startEditing(field, newEditAgent: nil)
    }

    // 只有在 field 里面存在唯一 checkbox 的情况下才能编辑。在 lookup 字段显示多个 checkbox 时，只能阅读，故无需区分是编辑哪个 checkbox
    func didToggleCheckbox(forFieldID fieldID: String, toStatus status: Bool) {
        delegate?.updateCheckboxValue(inFieldWithID: fieldID, toSelected: status)
    }

    func linkCell(_ cell: BTFieldLinkCellProtocol, didClickRecordWithID recordID: String) {
        let recordIDs = cell.linkedRecords.map { $0.recordID }
        delegate?.openLinkedRecord(withID: recordID, allLinkedRecordIDs: recordIDs, linkFieldModel: cell.fieldModel)
    }

    func startModifyLinkage(fromField field: BTFieldLinkCellProtocol) {
        delegate?.beginModifyLinkage(fromLinkField: field)
    }

    func cancelLinkage(fromFieldID: String, toRecordID: String, inFieldModel: BTFieldModel) {
        delegate?.cancelLinkage(fromFieldID: fromFieldID, toRecordID: toRecordID, inFieldModel: inFieldModel)
    }
    
    func didClickOpenLocation(inField field: BTFieldCellProtocol) {
        if let geoLocation = field.fieldModel.geoLocationValue.first {
            delegate?.didClickGeoLocation(geoLocation, on: field)
        }
    }
    func didClickCopyMenuItem(inField field: BTGeoLocationField) {
        //经base rd确认，暂时没有调用的地方，可删除，后续需要调用需要接入psda管控
//        SKPasteboard.setString(field.textView.text)
//        UDToast.showSuccess(with: BundleI18n.SKResource.Bitable_Common_CopiedToClipboard, on: self.window ?? self)
    }
    
    func track(event: String, params: [String: Any]) {
        delegate?.track(event: event, params: params)
    }

    func didTapSubmit() {
        delegate?.didClickSubmitForm()
    }

    func deleteRecord(sourceView: UIView) {
        delegate?.didClickDelete(sourceView: sourceView)
    }
    
    func continueSubmit() {
        delegate?.didClickHeaderButton(action: .continueSubmit)
    }
    
    func openUrl(_ url: String, inFieldModel: BTFieldModel) {
        delegate?.openUrl(url, inFieldModel: inFieldModel)
    }
    
    func getCopyPermission() -> BTCopyPermission? {
        return delegate?.getCopyPermission()
    }
    
    func textViewOfField(_ field: BTFieldModel, shouldAppyAction action: BTTextViewMenuAction) -> Bool {
        return delegate?.textViewOfField(field, shouldAppyAction: action) ?? false
    }
    
    func presentViewController(_ vc: UIViewController) {
        delegate?.presentViewController(vc)
    }
    
    func setRecordScrollEnable(_ enable: Bool) {
        DocsLogger.btInfo("[BTRecord] setRecordScrollEnable:\(enable) latestContenOffset:\(latestContenOffset)")
        let stopRecordScroller = { [weak self] in
            guard let self = self, let contentOffset = self.latestContenOffset else { return }
            self.fieldsView.setContentOffset(contentOffset, animated: false)
        }
        
        if !enable {
            stopRecordScroller()
            recordCanScroll = false
        } else {
            if !recordCanScroll {
                //停止decelerating
                stopRecordScroller()
            }
            recordCanScroll = true
        }
    }
    
    func startRecordContentOffset() {
        latestContenOffset = fieldsView.contentOffset
    }
    
    func updateButtonFieldStatus(to status: BTButtonFieldStatus, inFieldWithID fieldID: String) {
        delegate?.updateButtonFieldStatus(to: status, inRecordWithID: recordID, inFieldWithID: fieldID)
    }
    
    func didClickButtonField(inFieldWithID fieldID: String) {
        delegate?.didClickButtonField(inRecordWithID: recordID, inFieldWithID: fieldID)
    }
    
    func didClickRecordLimitMoreInForm() {
        delegate?.didClickCTANoticeMore()
    }
    
    func stageFieldClick(with fieldModel: BTFieldModel) {
        if !UserScopeNoChangeFG.ZJ.btItemViewProAddStageFieldFixDisable &&
            recordModel.viewMode == .submit {
            return
        }
        //切换到阶段字段tab
        if UserScopeNoChangeFG.ZJ.btCardReform {
            switchItemViewTab(to: fieldModel.fieldID)
        } else {
            delegate?.didClickStageField(with: recordID, fieldModel: fieldModel)
        }
    }
    
    func stageDetailFieldClickCancel(sourceView: UIView, fieldModel: BTFieldModel, cancelOptionId: String) {
        let action = UDMenuAction(
            title: BundleI18n.SKResource.Bitable_Flow_RecordCard_EndStep_Text,
            icon: UDIcon.stopOutlined,
            tapHandler: { [weak self] in
                self?.delegate?.didClickStageDetailCancel(sourceView: sourceView, fieldModel: fieldModel, cancelOptionId: cancelOptionId)
            }
        )
        var style = UDMenuStyleConfig.defaultConfig()
        style.menuItemIconTintColor = UDColor.functionDanger500
        style.menuItemTitleColor = UDColor.functionDanger500
        style.showArrowInPopover = false
        let menu = UDMenu(actions: [action], style: style)
        if let vc =  self.affiliatedViewController {
            menu.showMenu(sourceView: sourceView, sourceVC: vc)
        }
    }
    
    func stageDetailFieldChange(with stageIndex: Int) {
        delegate?.saveEditing(animated: true)
        self.changeStageSelected(index: stageIndex)
    }
    
    func stageDetailFieldClickDone(fieldModel: BTFieldModel, currentOptionId: String) {
        delegate?.saveEditing(animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.delegate?.didClickStageDetailDone(fieldModel: fieldModel, currentOptionId: currentOptionId)
        }
    }
    
    func stageDetailFieldClickRevert(sourceView: UIView ,fieldModel: BTFieldModel, currentOptionId: String) {
        delegate?.saveEditing(animated: true)
        let action = UDMenuAction(
            title: BundleI18n.SKResource.Bitable_Flow_RecordCard_StatusBack_Button,
            icon: UDIcon.resetOutlined,
            tapHandler: { [weak self] in
                self?.delegate?.stageDetailFieldClickRevert(sourceView: sourceView, fieldModel: fieldModel, currentOptionId: currentOptionId)
            }
        )
        var style = UDMenuStyleConfig.defaultConfig()
        style.menuItemIconTintColor = UDColor.textTitle
        style.menuItemTitleColor = UDColor.textTitle
        style.showArrowInPopover = false
        let menu = UDMenu(actions: [action], config: UDMenuConfig(position: .bottomRight),style: style)
        if let vc =  self.affiliatedViewController {
            menu.showMenu(sourceView: sourceView, sourceVC: vc)
        }
    }
    
    func stageDetailFieldClickRecover(fieldModel: BTFieldModel) {
        delegate?.saveEditing(animated: true)
        delegate?.stageDetailFieldClickRecover(fieldModel: fieldModel)
    }
    
    func didClickTab(index: Int) {
        delegate?.didClickTab(index: index, recordID: recordID)
    }
    
    func didChangeStage(stageFieldId: String, selectOptionId: String) {
        delegate?.didChangeStage(recordID: recordID, stageFieldId: stageFieldId, selectOptionId: selectOptionId)
    }
    
    func getCurrentCardPresentMode() -> CardPresentMode {
        return delegate?.cardPresentMode ?? .fullScreen
    }

    func getOpenRecordTraceId() -> String? {
        return context?.openRecordTraceId
    }

    func getGlobalRecordIndex() -> Int {
        return recordModel.globalIndex
    }
    
    func didClickCatalogueBaseName() {
        delegate?.didClickCatalogueBaseName()
    }
    
    func didClickCatalogueTableName() {
        delegate?.didClickCatalogueTableName()
    }
}

