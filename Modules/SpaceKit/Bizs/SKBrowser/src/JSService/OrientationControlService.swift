//
// Created by duanxiaochen.7 on 2021/2/10.
// Affiliated with SKBrowser.
//
// Description:


import Foundation
import SKFoundation
import SKCommon

class OrientationControlService: BaseJSService {
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
    }
}


extension OrientationControlService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.orientationControl]
    }

    func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.orientationControl.rawValue:
            handleControlInfo(params)
        default:
            ()
        }
    }

    /// landscape：当前要强制转过去的方向，support_landscape支持的展示方向
    private func handleControlInfo(_ params: [String: Any]) {
        guard let browserVC = registeredVC as? BrowserViewController,
            let landscapeJSEnabled = params["landscape"] as? Bool else { return }
        guard let docsInfo = model?.browserInfo.docsInfo else {
            DocsLogger.error("handleControlInfo docsInfo is nil")
            return
        }
        DocsLogger.info("OrientationControl, landscape:\(landscapeJSEnabled), editorId:\(String(describing: self.model?.jsEngine.editorIdentity))")
        let supportlandscape = params["support_landscape"] as? Bool ?? docsInfo.inherentType.alwaysOrientationsEnable
        browserVC.orientationDirector?.dynamicOrientationMask = supportlandscape ? [.portrait, .landscape] : [.portrait]
        #if swift(>=5.7)
        if #available(iOS 16.0, *) {
            browserVC.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
        #endif
        if !landscapeJSEnabled {
            browserVC.orientationDirector?.forceSetOrientation(.portrait)
            browserVC.hideForceOrientationTip()//隐藏转屏按钮
        }
    }
}
