//
// Created by duanxiaochen.7 on 2021/2/1.
// Affiliated with SKSheet.
//
// Description: sheet 卡片分享

import SKFoundation
import SKResource
import SKUIKit
import SKBrowser
import SKCommon
import HandyJSON
import EENavigator
import UniverseDesignToast


struct SheetShareModel: HandyJSON {
    var types: [SheetShareType] = []
    var callback: String = ""
}

class SheetExportShareService: BaseJSService, DocsJSServiceHandler {

    var callback: String = ""

    var handleServices: [DocsJSService] { [.sheetExportShare] }

    func handle(params: [String: Any], serviceName: String) {
        guard let json = SheetShareModel.deserialize(from: params) else {
            DocsLogger.error("前端 sheet export share 参数错误")
            return
        }

        callback = json.callback

        guard let hostVC = navigator?.currentBrowserVC as? BaseViewController, let docsInfo = model?.browserInfo.docsInfo else { return }

        self.navigator?.currentBrowserVC?.view.affiliatedWindow?.endEditing(true)
        
        LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) { [weak self] in
            guard let self = self else { return }
            let body = ExportDocumentViewControllerBody(titleText: BundleI18n.SKResource.CreationMobile_Sheets_Share,
                                                        docsInfo: docsInfo,
                                                        hostSize: hostVC.view.bounds.size,
                                                        isFromSpaceList: false,
                                                        isSheetCardMode: true,
                                                        needFormSheet: hostVC.isMyWindowRegularSize(),
                                                        isEditor: true,
                                                        hostViewController: hostVC,
                                                        module: .home(.recent),
                                                        containerID: nil,
                                                        containerType: nil,
                                                        proxy: self)
            Navigator.shared.present(body: body, from: hostVC, animated: true)
        }
        
    }
}

extension SheetExportShareService: ExportLongImageProxy {
    func handleExportDocsLongImage() {
        spaceAssertionFailure("sheet 卡片分享不可能走到这里")
    }

    private func validateExport() -> Bool {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            guard let permissionService = model?.permissionConfig.getPermissionService(for: .hostDocument),
                  let hostController = navigator?.currentBrowserVC else {
                spaceAssertionFailure("host permission service or hostController is nil")
                return false
            }
            let response = permissionService.validate(operation: .export)
            response.didTriggerOperation(controller: hostController)
            return response.allow
        } else {
            guard let docsInfo = hostDocsInfo else {
                DocsLogger.error("docsInfo is nil")
                return false
            }
            let dlpStatus = DlpManager.status(with: docsInfo.token, type: docsInfo.inherentType, action: .EXPORT)
            guard dlpStatus == .Safe else {
                DocsLogger.info("dlp control, can not export. dlp \(dlpStatus.rawValue)")
                let text = dlpStatus.text(action: .EXPORT, isSameTenant: docsInfo.isSameTenantWithOwner)
                let type: DocsExtension<UDToast>.MsgType = dlpStatus == .Detcting ? .tips : .failure
                guard let hostView = self.ui?.hostView else { return false }
                PermissionStatistics.shared.reportDlpSecurityInterceptToastView(action: .EXPORT, status: dlpStatus, isSameTenant: docsInfo.isSameTenantWithOwner)
                UDToast.docs.showMessage(text, on: hostView, msgType: type)
                return false
            }
            return true
        }
    }

    func handleExportSheetLongImage(with params: [String: Any]) {
        guard validateExport() else { return }
        model?.jsEngine.callFunction(DocsJSCallBack(callback), params: ["id": SheetShareType.image.rawValue], completion: nil)
    }

    func handleExportSheetText() {
        guard validateExport() else { return }
        model?.jsEngine.callFunction(DocsJSCallBack(callback), params: ["id": SheetShareType.text.rawValue], completion: nil)
    }
}
