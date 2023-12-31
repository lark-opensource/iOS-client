//
//  SheetModule.swift
//  SpaceKit
//
//  Created by lijuyou on 2020/6/8.
//  


import Foundation
import SKCommon
import SKFoundation
import SKInfra
import LarkContainer

public final class SheetModule: ModuleService {
    
    public init() { }

    public func setup() {
        DocsLogger.info("SheetModule setup")
        DocsContainer.shared.register(SheetModule.self, factory: { _ in
            return self
        }).inObjectScope(.container)
    }

    public func registerJSServices(type: DocsJSServiceType, ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?, register: (JSServiceHandler) -> Void) {
        switch type {
        case .commonBusiness: // sheet@docs 也能用的业务，要放在这里
            register(SheetDropdownService(ui: ui, model: model, navigator: navigator))
            register(SheetAttachmentListService(ui: ui, model: model, navigator: navigator))
            register(SheetToolManagerService(ui: ui, model: model, navigator: navigator))
            register(SheetReminderService(ui: ui, model: model, navigator: navigator))
            register(SheetShowCellContentService(ui: ui, model: model, navigator: navigator))
        case .individualBusiness: // 纯 sheet 才能用的业务，放在这里
            register(SheetShowInputService(ui: ui, model: model, navigator: navigator))
            register(SheetTabOperationService(ui: ui, model: model, navigator: navigator))
            register(SheetTabService(ui: ui, model: model, navigator: navigator))
            register(SheetCardModeNavBarService(ui: ui, model: model, navigator: navigator))
            register(SheetExportShareService(ui: ui, model: model, navigator: navigator))
        default:
            break
        }
    }
}
