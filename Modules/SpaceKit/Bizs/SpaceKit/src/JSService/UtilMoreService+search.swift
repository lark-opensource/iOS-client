//
//  UtilMoreService+sheet.swift
//  SpaceKit
//
//  Created by Webster on 2019/6/19.
//

import Foundation
import SKCommon
import SKBrowser
import SKFoundation
import HandyJSON
import SKResource


extension UtilMoreService {
    /// 展示查找面板
    func displaySearchPanel() {
        guard let info = hostDocsInfo, let attachView = registeredVC?.view, searchUIManager == nil else {
            return
        }
        var placeholderText = ""
        var finishText = BundleI18n.SKResource.Doc_Doc_SearchDone
        if info.type == .doc || info.type == .docX {
            placeholderText = BundleI18n.SKResource.Doc_Facade_LookFor
            DocsTracker.log(enumEvent: .clickMoreFindWithin, parameters: makeParameters(with: ""))
        } else if info.type == .sheet {
            placeholderText = BundleI18n.SKResource.Doc_Facade_SearchInSheet
            ui?.uiResponder.setTrigger(trigger: DocsKeyboardTrigger.sheet.rawValue)
            logSheetShowFind()
        } else if info.type == .bitable {
            placeholderText = BundleI18n.SKResource.Bitable_Search_PleaseEnterKeyword
            finishText = BundleI18n.SKResource.Bitable_Common_ButtonCancel
        }
        searchUIManager = SearchReplaceUIManager(attachView, placeholderText: placeholderText, finishButtonText: finishText, docType: info.type)
        searchUIManager?.postAnimatorNotify = (info.type == .sheet)
        searchUIManager?.delegate = self
        searchUIManager?.showView(keyboardOn: true)
        
        if self.hostDocsInfo?.type == .sheet {
            SheetTracker.report(event: .searchViewExpose, docsInfo: self.hostDocsInfo)
        } else {
            DocsSearchTracker.report(event: .showSearchPanel, docsInfo: self.hostDocsInfo)
        }
        (navigator?.currentBrowserVC as? BrowserViewController)?.setSearchMode(searchMode: .search(finishCallback: { [weak self] in
            self?.searchUIManager?.finishSearch()
        }))
    }

    func removeSearchView() {
        guard hostDocsInfo != nil else {
            return
        }
        (navigator?.currentBrowserVC as? BrowserViewController)?.setSearchMode(searchMode: .normal)
        searchUIManager?.didReceivedFinishEvent()
        searchUIManager = nil
    }

    func handleJsUpdateSearch(current: Int, total: Int) {
        guard hostDocsInfo != nil else {
            return
        }
         searchUIManager?.updateResult(current: current, total: total)
    }

    func handleSimulateOpenSearch() {
        displaySearchPanel()
    }
    
    
}

extension UtilMoreService: SearchReplaceUIManagerDelegate {

    var supportedViewController: SearchReplaceUIManagerController? {
        return registeredVC as? SearchReplaceUIManagerController
    }

    func requestNewSearch(_ manager: SearchReplaceUIManager, content: String, exitKeyboard: Bool) {
        guard let callBack = searchCallBackList[DocsJSService.search] else { return }
        let params = [
            "content": content,
            "inKeyboard": exitKeyboard
            ] as [String: Any]
        callFunction(DocsJSCallBack(callBack), params: params, completion: nil)
    }

    func requestClearSearch(_ manager: SearchReplaceUIManager) {
        (navigator?.currentBrowserVC as? BrowserViewController)?.setSearchMode(searchMode: .normal)
        guard let callBack = searchCallBackList[DocsJSService.clearSearchResult] else { return }
        callFunction(DocsJSCallBack(callBack), params: [String: Any](), completion: nil)
        searchUIManager = nil
        if self.hostDocsInfo?.type == .sheet {
            SheetTracker.report(event: .searchFinish, docsInfo: self.hostDocsInfo)
        } else {
            DocsSearchTracker.report(event: .finishFind, docsInfo: self.hostDocsInfo)
        }
    }

    func requestSwitchSearch(_ manager: SearchReplaceUIManager, result: SearchRestultNum) {
        guard let callBack = searchCallBackList[DocsJSService.switchSearchResult] else { return }
        let params = [
            "index": result.current
            ] as [String: Any]
        searchUIManager?.updateResult(current: (result.current), total: result.total)
        callFunction(DocsJSCallBack(callBack), params: params, completion: nil)
    }

    func didClickSwitchButton(_ manager: SearchReplaceUIManager, isPrevious: Bool) {
        if self.hostDocsInfo?.type == .sheet {
            logSheetFindSwitch(isPrevious: isPrevious)
        } else {
            DocsSearchTracker.report(event: .scrollResult(isPrev: isPrevious), docsInfo: self.hostDocsInfo)
        }
    }

    func requestChangeKeyboard(_ innerHeight: CGFloat, openKeyboard: Bool) {
        let info = BrowserKeyboard(height: innerHeight, isShow: openKeyboard, trigger: DocsKeyboardTrigger.search.rawValue)
        let params: [String: Any] = [SimulateKeyboardInfo.key: info]
        model?.jsEngine.simulateJSMessage(DocsJSService.simulateKeyboardChange.rawValue, params: params)
    }
}
