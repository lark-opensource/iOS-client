//
//  EditStatusService.swift
//  SKBrowser
//
//  Created by liujinwei on 2022/9/26.
//


import Foundation
import SKFoundation
import SKCommon

class EditStatusService: BaseJSService {
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
    }
}


extension EditStatusService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.editStatus, .mindnoteEditStatus]
    }

    func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.editStatus.rawValue, DocsJSService.mindnoteEditStatus.rawValue:
            handleStatusUpdated(params)
        default:
            ()
        }
    }

    private func handleStatusUpdated(_ params: [String: Any]) {
        guard let browserVC = registeredVC as? BrowserViewController,
              let docsType = browserVC.docsInfo?.inherentType,
            let status = params["status"] as? UInt8 else { return }
        let editStatus = status == 1
        DocsLogger.info("Docx, editorStatus:\(editStatus), editorId:\(self.model?.jsEngine.editorIdentity)")
        if LKFeatureGating.enableScreenViewHorizental && docsType == .docX ||
            UserScopeNoChangeFG.GXY.mindnoteSupportScreenViewHorizental && docsType == .mindnote {
            let mask: UIInterfaceOrientationMask? = editStatus ? [.portrait] : [.portrait, .landscape]
            browserVC.orientationDirector?.dynamicOrientationMask = mask
            if docsType == .docX || docsType == .mindnote {
                browserVC.orientationDirector?.needShowTipWhenEditing = editStatus
            }
            if #available(iOS 16.0, *) {
                browserVC.setNeedsUpdateOfSupportedInterfaceOrientations()
            }
            browserVC.orientationDirector?.browserHideForceOrientationTip()
        }
    }
}
