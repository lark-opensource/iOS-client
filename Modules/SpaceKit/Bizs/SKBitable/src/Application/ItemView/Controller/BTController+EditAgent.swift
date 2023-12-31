//
// Created by duanxiaochen.7 on 2021/7/19.
// Affiliated with SKBitable.
//
// Description:

import UIKit
import SKCommon
import SKUIKit
import SKFoundation
import LarkLocationPicker
import LarkCoreLocation
import SKBrowser
import LarkSetting
import EENavigator
import UniverseDesignToast
import SKResource


// MARK: edit handler
extension BTController: BTEditCoordinator {

    var inputSuperview: UIView {
        guard UserScopeNoChangeFG.ZJ.btCardReform else {
            return view
        }
        return self.currentCard ?? view
    }
    var attachedController: UIViewController { self }

    func invalidateEditAgent() {
        currentEditAgent = nil
        currentEditingField = nil
        viewModel.tableModel.update(editingRecord: nil, editingField: nil)
        viewModel.notifyModelUpdate()
    }

    func visibleEditCell(fieldID: String) -> BTFieldCellProtocol? {
        let cell = currentCard?.fieldsView.visibleCells.first(where: {
            if let baseField = $0 as? BTFieldCellProtocol, baseField.fieldID == fieldID {
                return true
            }
            return false
        })
        return cell as? BTFieldCellProtocol
    }

    func shouldContinueEditing(fieldID: String, inRecordID recordID: String) -> Bool {
        if let editingRecordModel = viewModel.tableModel.getRecordModel(id: recordID) {
            if let editingFieldModel = editingRecordModel.getFieldModel(id: fieldID) {
                return editingFieldModel.editable
            } else {
                return false
            }
        } else {
            return false
        }
    }

    var hostChatId: String? { viewModel.hostChatId }
    
    var editorDocsInfo: DocsInfo {
        if viewModel.mode.isIndRecord || viewModel.mode == .addRecord {
            // 记录分享场景下，url 的 token 实际是 shareToken，baseToken 从前端获取
            return DocsInfo(type: .bitable, objToken: viewModel.actionParams.data.baseId)
        }
        return viewModel.bizData.hostDocInfo
    }
}


extension BTController: BTBaseEditAgentBaseDelegate {
    func didCloseEditPanel(_ agent: BTEditAgent, payloadParams: [String: Any]? = nil) {
        currentCard?.resetContentInset()
        if let agent = agent as? BTLinkEditAgent {
            notifyFrontDidCloseLinkPanel(agent: agent)
        } else if let agent = agent as? BTChatterEditAgent {
            notifyFrontDidCloseChatterPanel(agent: agent, payloadParams: payloadParams)
        }
    }
    
    func didClickItem(with model: BTCapsuleModel, fileName: String?) {
        switch model.chatterType {
        case .group:
            guard !model.token.isEmpty else {
                UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Group_UnableToJoinGroup_Toast, on: self.view)
                return
            }
            var appLink = URLComponents()
            appLink.scheme = "https"
            appLink.host = DomainSettingManager.shared.currentSetting["applink"]?.first ?? ""
            appLink.path = "/client/chat/chatter/add_by_link"
            let query = URLQueryItem(name: "link_token", value: model.token)
            appLink.queryItems = [query]
            if let url = appLink.url {
                Navigator.shared.push(url, from: self)
            }
        case .user:
            // 暂时走不到，后续可以埋
            HostAppBridge.shared.call(ShowUserProfileService(userId: model.id, fileName: fileName, fromVC: self))
        }
        
    }

    func didStopEditing() {
        self.view.window?.endEditing(true)
        didEndEditingField()
    }
    
    private func notifyFrontDidCloseChatterPanel(agent: BTChatterEditAgent, payloadParams: [String: Any]?) {
        let targetInfo = ["tableId": viewModel.actionParams.data.tableId,
                          "recordId": viewModel.currentRecordID,
                          "fieldId": agent.fieldID,
                          "viewId": viewModel.actionParams.data.viewId]
        var targetJson: [String: Any] = ["target": targetInfo]
        if let payloadParams = payloadParams {
            targetJson.merge(other: payloadParams)
        }
        let params: [String: Any] = ["baseId": viewModel.actionParams.data.baseId,
                                     "tableId": viewModel.actionParams.data.tableId,
                                     "payload": targetJson]
        switch agent.chatterType {
        case .user:
            viewModel.bizData.jsFuncService?.callFunction(DocsJSCallBack.bitableEditClosePanel, params: params, completion: nil)
        case .group:
            break
        }
    }

    private func notifyFrontDidCloseLinkPanel(agent: BTLinkEditAgent) {
        let sourceBaseID = agent.currentLinkingBaseID
        let destinationBaseID = viewModel.actionParams.data.baseId
        let sourceTableID = agent.currentLinkingTableID
        let destinationTableID = viewModel.actionParams.data.tableId
        let callback = viewModel.actionParams.callback
        delegate?.cardLink(action: .backwardLinkTable,
                           originBaseID: viewModel.actionParams.originBaseID,
                           originTableID: viewModel.actionParams.originTableID,
                           sourceBaseID: sourceBaseID,
                           sourceTableID: sourceTableID,
                           destinationBaseID: destinationBaseID,
                           destinationTableID: destinationTableID,
                           callback: callback)
    }
}


extension BTController: BTUploadMediaDelegate {
    func didFinishPickingMedia(content: SKPickContent, forFieldID fieldID: String) {
        switch content {
        case .asset(assets: let assets, original: _):
            logAttachmentEvent(action: "upload_new_attachment", attachmentCount: assets.count)
        case .takePhoto, .takeVideo:
            logAttachmentEvent(action: "upload_new_attachment", attachmentCount: 1)
        case .iCloudFiles(let urls):
            logAttachmentEvent(action: "upload_new_attachment", attachmentCount: urls.count)
        case .uploadCanvas: ()
        }
        let uploadToLocation = BTFieldLocation(originBaseID: viewModel.actionParams.originBaseID,
                                               originTableID: viewModel.actionParams.originTableID,
                                               baseID: viewModel.actionParams.data.baseId,
                                               tableID: viewModel.actionParams.data.tableId,
                                               viewID: viewModel.actionParams.data.viewId,
                                               recordID: viewModel.currentRecordID,
                                               fieldID: fieldID)
        var uploadMode = BTUploadMode.uploadImmediately
        // 表单和高级权限的附件 为了不产生脏数据占用租户容量空间 不立即上传附件
        if let currentCard = currentCard {
            if currentCard.recordModel.viewMode == .addRecord, UserScopeNoChangeFG.YY.baseAddRecordPage {
                uploadMode = .preUploadForAddRecord
            } else if currentCard.viewMode == .submit {
                if UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable {
                    uploadMode = .preUploadForSubmit
                } else {
                    uploadMode = .uploadUntillSubmit
                }
            } else if (currentCard.viewMode == .form) {
                uploadMode = .uploadUntillSubmit
            }
        }
        uploader?.didPickMedia(content: content,
                               forLocation: uploadToLocation,
                               inRecord: currentCard,
                               uploadMode: uploadMode,
                               logHandler: { [weak self] type in
            self?.logUploadType(type: type)
        })
    }
    
    func didFinishNewPickingMedia(results: [MediaResult], forFieldID: String) {
        logAttachmentEvent(action: "upload_new_attachment", attachmentCount: results.count)
        let uploadToLocation = BTFieldLocation(originBaseID: viewModel.actionParams.originBaseID,
                                               originTableID: viewModel.actionParams.originTableID,
                                               baseID: viewModel.actionParams.data.baseId,
                                               tableID: viewModel.actionParams.data.tableId,
                                               viewID: viewModel.actionParams.data.viewId,
                                               recordID: viewModel.currentRecordID,
                                               fieldID: forFieldID)
        var uploadMode = BTUploadMode.uploadImmediately
        // 表单和高级权限的附件 为了不产生脏数据占用租户容量空间 不立即上传附件
        if let currentCard = currentCard {
            if currentCard.recordModel.viewMode == .addRecord, UserScopeNoChangeFG.YY.baseAddRecordPage {
                uploadMode = .preUploadForAddRecord
            } else if currentCard.viewMode == .submit {
                if UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable {
                    uploadMode = .preUploadForSubmit
                } else {
                    uploadMode = .uploadUntillSubmit
                }
            } else if (currentCard.viewMode == .form) {
                uploadMode = .uploadUntillSubmit
            }
        }
        uploader?.didNewPickMedia(results: results,
                               forLocation: uploadToLocation,
                               inRecord: currentCard,
                                  uploadMode: uploadMode,
                               logHandler: { [weak self] type in
            self?.logUploadType(type: type)
        })
    }
}

extension BTController: BTGeoLocationEditAgentDelegate {
    func startAutoLocate(forFieldID fieldID: String, forToken token: String, authFailHandler: @escaping (LocationAuthorizationError?) -> Void) {
        let fieldLocation = BTFieldLocation(
            originBaseID: viewModel.actionParams.originBaseID,
            originTableID: viewModel.actionParams.originTableID,
            baseID: viewModel.actionParams.data.baseId,
            tableID: viewModel.actionParams.data.tableId,
            viewID: viewModel.actionParams.data.viewId,
            recordID: viewModel.currentRecordID,
            fieldID: fieldID
        )
//        viewModel.tableModel.insert(fetchingGeoLocationField: fetchToLocation)
//        viewModel.notifyModelUpdate()
        geoFetcher?.didClickAutoLocate(forField: fieldLocation, forToken: token, inRecord: currentCard, authFailHandler: authFailHandler)
    }
    func startReGeocode(forFieldID fieldID: String, chooseLocation: ChooseLocation) {
        let fieldLocation = BTFieldLocation(
            originBaseID: viewModel.actionParams.originBaseID,
            originTableID: viewModel.actionParams.originTableID,
            baseID: viewModel.actionParams.data.baseId,
            tableID: viewModel.actionParams.data.tableId,
            viewID: viewModel.actionParams.data.viewId,
            recordID: viewModel.currentRecordID,
            fieldID: fieldID
        )
        geoFetcher?.didSelectLocation(forField: fieldLocation, inRecord: currentCard, geoLocation: chooseLocation)
    }
    func deleteGeoLocation(forFieldID: String) {
        let args = BTSaveFieldArgs(originBaseID: viewModel.actionParams.originBaseID,
                                   originTableID: viewModel.actionParams.originTableID,
                                   currentBaseID: viewModel.actionParams.data.baseId,
                                   currentTableID: viewModel.actionParams.data.tableId,
                                   currentViewID: viewModel.actionParams.data.viewId,
                                   currentRecordID: viewModel.currentRecordID,
                                   currentFieldID: forFieldID,
                                   callback: viewModel.actionParams.callback,
                                   editType: .cover,
                                   value: nil)
        viewModel.dataService?.saveField(args: args)
    }
}
