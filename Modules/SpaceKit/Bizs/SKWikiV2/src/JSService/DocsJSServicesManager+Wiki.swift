//
//  DocsJSServicesManager+Wiki.swift
//  SpaceKit
//
//  Created by lijuyou on 2020/6/9.
//  


import Foundation
import SKCommon
import SKBrowser
import SKFoundation

extension DocsJSServicesManager {
    func registerWikiServiceWithHandler(_ handler: WikiJSEventHandler) {
        guard self.ui != nil, self.model != nil else {
            spaceAssertionFailure("Invalid")
            return
        }
        guard let ui, let model, let navigator else {
            return
        }
        registerBusinessService(handler: WikiTitleChangeService(handler))
        registerBusinessService(handler: WikiSetInfoService(handler))
        registerBusinessService(handler: WikiSetTreeEnableService(handler))
        registerBusinessService(handler: WikiPermssionChangeService(handler))
        // 文件夹block
        if UserScopeNoChangeFG.MJ.folderBlockEnable {
            _ = register(handler: FolderBlockService(ui: ui, model: model, navigator: navigator))
        }
    }
}
