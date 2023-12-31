//
// Created by duanxiaochen.7 on 2021/7/5.
// Affiliated with SKBitable.
//
// Description:

import UIKit
import HandyJSON
import SKCommon
import SKBrowser
import SKUIKit
import SKFoundation
import SKResource
import UniverseDesignToast
import LarkUIKit

extension BTJSService: BTUploadMediaHelperDelegate {
    func beginUploading() {
        cardVC?.orientationMask = [.portrait]
    }

    func updateUploadProgress(infos: [BTFieldLocation: [BTMediaUploadInfo]], updatesUI: Bool) {
        DispatchQueue.main.async {
            self.cardVC?.viewModel.tableModel.update(uploadingAttachments: infos)
            if updatesUI {
                self.cardVC?.viewModel.notifyModelUpdate()
            }
        }
    }

    func updatePendingAttachments(infos: [PendingAttachment], updatesUI: Bool) {
        var dict: [BTFieldLocation: [PendingAttachment]] = [:]
        infos.forEach { pa in
            if var pas = dict[pa.location] {
                pas.append(pa)
                dict[pa.location] = pas
            } else {
                dict[pa.location] = [pa]
            }
        }
        cardVC?.viewModel.tableModel.update(pendingAttachments: dict)
        if updatesUI {
            cardVC?.viewModel.notifyModelUpdate()
        }
    }

    func updateAttachmentLocalStorageURLs(infos: [String: URL], updatesUI: Bool) {
        cardVC?.viewModel.tableModel.update(localStorageURLs: infos)
        if updatesUI {
            cardVC?.viewModel.notifyModelUpdate()
        }
    }
    
    func markAllUploadFinished() {
        cardVC?.orientationMask = nil
    }

    func notifyFrontendDidUploadMedia(forLocation location: BTFieldLocation, attachmentModel: BTAttachmentModel, callback: String) {
        let editType: BTFieldEditType
        if self.cardVC?.viewModel.mode == .addRecord, UserScopeNoChangeFG.YY.baseAddRecordPage {
            editType = .preAdd
        } else if self.cardVC?.viewModel.mode == .submit, UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable {
            editType = .preAdd
        } else {
            editType = .add
        }
        let args = BTSaveFieldArgs(originBaseID: location.originBaseID,
                                   originTableID: location.originTableID,
                                   currentBaseID: location.baseID,
                                   currentTableID:  location.tableID,
                                   currentViewID: location.viewID,
                                   currentRecordID: location.recordID,
                                   currentFieldID: location.fieldID,
                                   callback: callback,
                                   editType: editType,
                                   value: [attachmentModel.toJSON()])
        saveField(args: args)
    }
    
    func localEditAttachment(with type: BTFieldEditType, pendingAttachment: PendingAttachment, callback: String) {
        let location = pendingAttachment.location
        let localModelForUpload = BTAttachmentModel()
        // 和前端确认，反馈如下：附件只判断是否为空值，只要不是null就行，后续如用作其他用途，请再次确认
        let args = BTSaveFieldArgs(originBaseID: location.originBaseID,
                                   originTableID: location.originTableID,
                                   currentBaseID: location.baseID,
                                   currentTableID:  location.tableID,
                                   currentViewID: location.viewID,
                                   currentRecordID: location.recordID,
                                   currentFieldID: location.fieldID,
                                   callback: callback,
                                   editType: type,
                                   value: [localModelForUpload.toJSON()])
        saveField(args: args)
    }

    // 埋点，用于上传到drive 和 最终在bitable中的附件对比，看会浪费多少空间
    func trackAttachmentSize(imageSize: Int) {
        if var trackParams = cardVC?.viewModel.getCommonTrackParams() {
            trackParams["image_size"] = imageSize
            trackParams["click"] = "upload_image"
            if cardVC?.viewModel.mode == .form {
                DocsTracker.newLog(enumEvent: .bitableFormClick, parameters: trackParams)
            } else if cardVC?.viewModel.mode == .submit {
                DocsTracker.newLog(enumEvent: .bitableCardClick, parameters: trackParams)
            }
        }
    }

    func handleUploadMediaFailure(error: Error, mountNodeToken: String, mountNode: String) {
        
        func showErrorToast() {
            let fromVC = cardVC ?? UIViewController()
            let fromView = navigator?.currentBrowserVC?.view.affiliatedWindow ?? UIView()

            if let error = error as? BTError {
                switch error {
                case .attachmentSizeLimit:
                    UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Download_UploadAttachmentExceedMax_Toast(2), on: fromView)
                }
                return
            }
            switch (error as NSError).code {
            case DocsNetworkError.Code.createLimited.rawValue, DocsNetworkError.Code.uploadLimited.rawValue:
                if QuotaAlertPresentor.shared.enableTenantQuota {
                    QuotaAlertPresentor.shared.showQuotaAlert(type: .upload, from: fromVC)
                } else {
                    UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_UploadFail, on: fromView)
                }
            case DocsNetworkError.Code.rustUserUploadLimited.rawValue:
                if QuotaAlertPresentor.shared.enableUserQuota {
                    let bizParams = SpaceBizParameter(module: .bitable, fileID: mountNodeToken, fileType: .bitable)
                    QuotaAlertPresentor.shared.showUserQuotaAlert(mountNodeToken: mountNodeToken,
                                                                  mountPoint: mountNode,
                                                                  from: fromVC,
                                                                  bizParams: bizParams)
                } else {
                    UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_UploadFail, on: fromView)
                }
                
            case DocsNetworkError.Code.networkError.rawValue:
                UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Field_NetworkError, on: fromView)
            default:
                UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_UploadFail, on: fromView)
            }
        }
        
        DispatchQueue.main.async {
            showErrorToast()
        }
    }
}
