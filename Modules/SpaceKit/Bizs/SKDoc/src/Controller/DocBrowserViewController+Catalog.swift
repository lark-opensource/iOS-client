//
//  DocBrowserViewController+Catalog.swift
//  SKBrowser
//
//  Created by lizechuang on 2021/1/6.
//

import Foundation
import SKUIKit
import SKResource
import SKFoundation
import SKCommon

extension DocBrowserViewController {

    @inline(__always)
    func _catalogDisplayButtonItemAction() {
        guard let docsInfo = self.docsInfo else {
            return
        }
        super.catalogDisplayButtonItemAction()
        if docsInfo.inherentType == .docX {
            editor.jsEngine.simulateJSMessage(DocsJSService.ipadCatalogDisplay.rawValue, params: ["isShow": self.isShowCatalogItem])
        } else {
            editor.jsEngine.callFunction(.requestShowCatalog, params: ["isShow": self.isShowCatalogItem], completion: nil)
            reportClickCatalogShowButtom(isShow: self.isShowCatalogItem)
        }
    }

    private func reportClickCatalogShowButtom(isShow: Bool) {
        guard let docsInfo = self.docsInfo else {
            return
        }
        let params: [String: Any] = ["module": docsInfo.fromModule ?? "",
                                     "subModule": docsInfo.fromSubmodule ?? "",
                                     "action": "docs_iPad_click_catalog_button",
                                     "fileType": docsInfo.type.name,
                                     "fileID": docsInfo.encryptedObjToken,
                                     "catalog_switch": self.isShowCatalogItem ? "0" : "1"]
        let newParams = FileListStatistics.addParamsInto(params)
        DocsTracker.log(enumEvent: .iPadClickCatalogButton, parameters: newParams)
    }
}
