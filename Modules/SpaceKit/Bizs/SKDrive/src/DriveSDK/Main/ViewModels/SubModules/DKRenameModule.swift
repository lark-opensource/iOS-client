//
//  DKRenameModule.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/8/22.
//

import Foundation
import SKCommon
import SKFoundation
import RxSwift
import RxCocoa
import UniverseDesignDialog
import UniverseDesignToast
import SKResource
import EENavigator
import UniverseDesignInput
import SKInfra
import SKUIKit

class DKRenameModule: DKBaseSubModule {
    enum RenameActionType {
        case useNewType
        case useOldType
        case canceled
    }

    var navigator: DKNavigatorProtocol
    /// 需要在 TextField 长度为空，修改 Button 的颜色
    private weak var okButton: UIButton?

    init(hostModule: DKHostModuleType,
         navigator: DKNavigatorProtocol = Navigator.shared) {
        self.navigator = navigator
        super.init(hostModule: hostModule)
    }

    deinit {
        DocsLogger.driveInfo("DKRenameModule -- deinit")
    }

    override func bindHostModule() -> DKSubModuleType {
        super.bindHostModule()
        guard let host = hostModule else { return self }
        host.subModuleActionsCenter.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] action in
            guard let self = self else { return }
            if case .rename = action {
                self.renameFile()
            }
        }).disposed(by: bag)
        return self
    }
    
    func renameFile() {
        guard let hostModule, let hostController = hostModule.hostController else {
            DocsLogger.error("failed to get host controller when rename file")
            assertionFailure()
            return
        }
        let bizPrams = SpaceBizParameter(module: .drive,
                                         fileID: fileInfo.fileID,
                                         fileType: docsInfo.type,
                                         driveType: fileInfo.type)
        // Drive业务埋点：重命名文档
        DriveStatistic.clientContentManagement(action: DriveStatisticAction.clickRename,
                                               fileId: fileInfo.fileToken,
                                               additionalParameters: hostModule.additionalStatisticParameters)

        let config = UDDialogUIConfig()
        config.contentMargin = .zero
        let dialog = UDDialog(config: config)
        
        dialog.setTitle(text: BundleI18n.SKResource.Drive_Drive_Rename, inputView: true)
        // cancel button
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel, dismissCompletion: { [weak self] in
            DocsLogger.debug("do nothing")
            self?.reportStatics(actionType: .canceled)
            DocsTracker.reportSpaceDriveRenameClick(click: "cancel", bizParms: bizPrams)
        })
        // ok button
        let button = dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Normal_OK, dismissCompletion: { [weak dialog, weak self] in
            guard let `self` = self else { return }
            guard let newTitle = dialog?.textField.text, newTitle.isEmpty == false else {
                DocsLogger.error("no new name to rename")
                return
            }
            self.preCheckModifyFileName(newTitle: newTitle)
            DocsTracker.reportSpaceDriveRenameClick(click: "confirm", bizParms: bizPrams)
        })
        okButton = button
        dialog.bindInputEventWithConfirmButton(button)
        self._renderOkButton(with: self.docsInfo.title)
        // textField
        let textField = dialog.addTextField(placeholder: BundleI18n.SKResource.Doc_More_RenameSheetPlaceholder,
                                            text: self.fileInfo.name)
        textField.delegate = self
        textField.input.addTarget(self, action: #selector(self._textDidChange(_:)), for: .editingChanged)
        if let baseTextField = textField.input as? SKBaseTextField {
            let encryptID = ClipboardManager.shared.getEncryptId(token: hostModule.hostToken) ?? fileInfo.fileToken
            baseTextField.pointId = encryptID
            if let forbiddenBlock = getCopyForbiddenBlockWhenRename() {
                baseTextField.copyForbiddenBlock = { [weak dialog] in
                    guard let dialog else { return }
                    forbiddenBlock(dialog)
                }
            }
        }

        // present it
        navigator.present(vc: dialog, from: hostController, animated: true) {
            textField.becomeFirstResponder()
        }
    }

    private func getCopyForbiddenBlockWhenRename() -> ((UIViewController) -> Void)? {
        guard let permissionService = hostModule?.permissionService else { return nil }
        let response = permissionService.validate(operation: .copyContent)
        guard case let .forbidden(denyType, _) = response.result else { return nil } // 有复制权限，不拦截
        guard case let .blockByUserPermission(reason) = denyType else {
            return {
                response.didTriggerOperation(controller: $0, BundleI18n.SKResource.Doc_Doc_CopyFailed)
            }
        }
        switch reason {
        case .blockByServer, .unknown, .userPermissionNotReady, .blockByAudit:
            if LKFeatureGating.securityCopyEnable { return nil } // 假设重命名场景有编辑权限，若命中单文档粘贴保护，允许复制
        case .blockByCAC, .cacheNotSupport:
            break
        }
        return {
            response.didTriggerOperation(controller: $0, BundleI18n.SKResource.Doc_Doc_CopyFailed)
        }
    }

    func preCheckModifyFileName(newTitle: String) {
        let oldName = SKFilePath.getFileNamePrefix(name: self.fileInfo.name)
        let oldType = SKFilePath.getFileExtension(from: self.fileInfo.name, needTrim: false) ?? ""
        let newName = SKFilePath.getFileNamePrefix(name: newTitle)
        let newType = SKFilePath.getFileExtension(from: newTitle) ?? ""

        let nameChanged = oldName != newName
        let typeChanged = newType != oldType
        if !nameChanged, !typeChanged {
            // 名字和扩展名都没变
            guard let hostController = hostModule?.hostController,
                  let window = hostController.view.window else { return }
            let tips = BundleI18n.SKResource.Doc_Facade_Rename + BundleI18n.SKResource.Doc_Normal_Success
            UDToast.showSuccess(with: tips, on: window)
            self.reportStatics(actionType: .useOldType)
        } else if !typeChanged {
            // 拓展名没变
            let newFileName = SKFilePath.createFileName(name: newName, ext: newType)
            self.modifyFileName(newFileName, needRenameCache: false)
            self.reportStatics(actionType: .useNewType)
        } else {
            // 扩展名发生变化，提示用户确认
            self._showConfirm(newName, newType, oldType)
        }
    }

    private func _showConfirm(_ newName: String, _ newType: String, _ oldType: String) {
        guard let hostController = hostModule?.hostController else {
            DocsLogger.error("failed to get host controller when confirm rename file")
            assertionFailure()
            return
        }
        let config = UDDialogUIConfig(style: .vertical)
        let dialog = UDDialog(config: config)
        dialog.setTitle(text: BundleI18n.SKResource.Drive_Drive_ChangeFileType)
        dialog.setContent(text: BundleI18n.SKResource.Drive_Drive_FileOperationMayHaveImpact)
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Drive_Drive_UseExtension(".\(newType)"), dismissCompletion: { [weak self] in
            guard let self = self else { return }
            let newFileName = SKFilePath.createFileName(name: newName, ext: newType)
            self.modifyFileName(newFileName, needRenameCache: true)
            self.reportStatics(actionType: .useNewType)
        })
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Drive_Drive_KeepExtension(".\(oldType)"), dismissCompletion: { [weak self] in
            guard let self = self else { return }
            let newFileName = SKFilePath.createFileName(name: newName, ext: oldType)
            self.modifyFileName(newFileName, needRenameCache: false)
            self.reportStatics(actionType: .useOldType)
        })
        navigator.present(vc: dialog, from: hostController, animated: false)
    }

    private func _renderOkButton(with text: String?) {
        okButton?.isUserInteractionEnabled = !(text?.isEmpty ?? true)
        okButton?.alpha = (text?.isEmpty ?? true) ? DKConstant.disabledTextAlpha : 1.0
    }
    
    func reportStatics(actionType: RenameActionType) {
        let confirmType: String
        switch actionType {
        case .useNewType:
            confirmType = "use_new"
        case .useOldType:
            confirmType = "use_old"
        default:
            confirmType = "use_old"
        }
        // Drive数据埋点：重命名的确认
        var additionalParameters = ["sub_confirm_type": confirmType]
        additionalParameters.merge(other: hostModule?.additionalStatisticParameters)
        DriveStatistic.clientContentManagement(action: DriveStatisticAction.clickRenameConfirm,
                                               fileId: fileInfo.fileToken,
                                               additionalParameters: additionalParameters)
    }
    
    func modifyFileName(_ name: String, needRenameCache: Bool = false) {
        guard let host = hostModule else {
            spaceAssertionFailure("hostModule not found")
            return
        }
        /// 开始请求
        host.subModuleActionsCenter.accept(.showLoading)
        host.netManager.updateFileInfo(name: name, completion: {[weak self, weak host] (result) in
            guard let self = self else { return }
            host?.subModuleActionsCenter.accept(.endLoading)
            switch result {
            case .success:
                DocsLogger.driveInfo("rename success")
                self.docsInfo.title = name
                self.fileInfo.name = name
                self.showSuccessToast(msg: BundleI18n.SKResource.Doc_Facade_Rename + BundleI18n.SKResource.Doc_Normal_Success)
                if needRenameCache {
                    DocsLogger.driveInfo("rename success need rename cache")
                    host?.cacheService.deleteFile(dataVersion: nil)
                }
                // 重命名如果正在下载停止下载
                host?.subModuleActionsCenter.accept(.stopDownload)
                host?.subModuleActionsCenter.accept(.refreshVersion(version: nil))
                let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
                let objToken = self.docsInfo.wikiInfo?.wikiToken ?? self.fileInfo.fileToken
                dataCenterAPI?.rename(objToken: objToken, with: name)
            case .failure(let error):
                DocsLogger.driveInfo("modify filename failed", extraInfo: ["errorMsg": error.localizedDescription])
                guard let driveError = error as? DriveError else {
                    DocsLogger.warning("Failed to rename", extraInfo: ["error": error])
                    if let docsError = error as? DocsNetworkError,
                        let message = docsError.code.errorMessage {
                        self.showErrorToast(msg: message)
                    } else {
                        self.showErrorToast(msg: BundleI18n.SKResource.Doc_Facade_RenameFailed)
                    }
                    return
                }
                switch driveError {
                case .serverError(let code):
                    if code == DriveFileInfoErrorCode.machineAuditFailureError.rawValue ||
                        code == DriveFileInfoErrorCode.humanAuditFailureError.rawValue {
                        self.showErrorToast(msg: BundleI18n.SKResource.Doc_Review_Fail_Rename)
                    } else if let docsError = DocsNetworkError(code),
                        let message = docsError.code.errorMessage {
                        self.showErrorToast(msg: message)
                    } else {
                        self.showErrorToast(msg: BundleI18n.SKResource.Doc_Facade_RenameFailed)
                    }
                default:
                    self.showErrorToast(msg: BundleI18n.SKResource.Doc_Facade_RenameFailed)
                }
            }
        })
    }
    
    private func showSuccessToast(msg: String) {
        guard let hostVC = hostModule?.hostController, let window = hostVC.view.window else {
            spaceAssertionFailure("window not found")
            return
        }
        UDToast.showSuccess(with: msg, on: window)
    }
    
    private func showErrorToast(msg: String) {
        guard let hostVC = hostModule?.hostController, let window = hostVC.view.window else {
            spaceAssertionFailure("window not found")
            return
        }
        UDToast.showFailure(with: msg, on: window)
    }
}

// MARK: - UITextFieldDelegate
extension DKRenameModule: UDTextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard let name = textField.text else { return }
        let fileName = SKFilePath.getFileNamePrefix(name: name)
        let range = NSRange(location: 0, length: fileName.count)
        let begin = textField.beginningOfDocument
        guard let end = textField.position(from: begin, offset: range.location + range.length) else { return }
        textField.selectedTextRange = textField.textRange(from: end, to: end)
    }

    @objc
    private func _textDidChange(_ textField: UITextField) {
        _renderOkButton(with: textField.text)
    }
}
