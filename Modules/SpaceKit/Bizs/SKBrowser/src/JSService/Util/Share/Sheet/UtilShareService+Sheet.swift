//
//  UtilShareService+Sheet.swift
//  SKBrowser
//
//  Created by 吴珂 on 2020/10/23.



import Foundation
import SKFoundation
import SKCommon
import SKUIKit
import HandyJSON


extension UtilShareService {
    func handleShowShareTitle(_ params: [String: Any]) {
        sheetShareManager?.handleShowShareTitle(params)
        return
    }
    
    func handleHideSheetTitle(_ params: [String: Any]) {
        sheetShareManager?.handleHideSheetTitle(params)
        return
    }
    
    func handleShowSheetPreview(_ params: [String: Any]) {
        sheetShareManager?.handleShowSheetPreview(params)
        return
    }
    
    func changeStatusBarStyle(_ isDark: Bool) {
        sheetShareManager?.changeStatusBarStyle(isDark: isDark)
        return
    }
    
    
    
    func handleHideSheetPreview(_ params: [String: Any]) {
        sheetShareManager?.handleHideSheetPreview(params)
        return
    }
    
    func handleSheetHideLoading() {
        sheetShareManager?.handleSheetHideLoading()
        return
    }
    
    func handleSheetShowLoading() {
        sheetShareManager?.handleSheetShowLoading()
        return
    }
    
    func handleStartWriteImage(_ params: [String: Any]) {
        sheetShareManager?.handleStartWriteImage(params)
    }
    
    func handleReceiveImageData(_ params: [String: Any]) {
        sheetShareManager?.handleReceiveImageData(params)
    }
}

//导航栏相关
extension UtilShareService {
    
    func notifyFrontendSharePanelHeight(_ params: [String: Any]) {
        sheetShareManager?.notifyFrontendSharePanelHeight(params)
        return
    }
    
    func notifyFrontendUserDidTakeSnapshot() {
        sheetShareManager?.notifyFrontendUserDidTakeSnapshot()
    }
    
    func showSnapshotAlertView(_ params: [String: Any]) {
        if let window = self.navigator?.currentBrowserVC?.view.window, !window.isKeyWindow {
            DocsLogger.info("currentBrowserVC not in keywindow, dont showSnapshotAlertView")
            return
        }
        sheetShareManager?.showSnapshotAlertView(params)
        return
    }
}

extension UtilShareService: SheetShareManagerDelegate {
    
    func callJSService(_ callback: DocsJSCallBack, params: [String: Any]) {
        model?.jsEngine.callFunction(callback, params: params, completion: nil)
    }
    func presentViewController(_ vc: UIViewController, animated: Bool) {
        DocsLogger.info("navigator 调用系统分享面板")
        navigator?.presentViewController(vc, animated: animated, completion: nil)
    }
    
    func simulateJS(_ js: String, params: [String: Any]) {
        model?.jsEngine.simulateJSMessage(js, params: params)
    }
    
    func trackBaseInfo() -> [String: Any] {
        guard let info = hostDocsInfo else { return [:] }
        let params = [
                      "file_id": DocsTracker.encrypt(id: info.objToken),
                      "file_type": info.type.name,
                      "module": "sheet"]
        return params
    }
}
