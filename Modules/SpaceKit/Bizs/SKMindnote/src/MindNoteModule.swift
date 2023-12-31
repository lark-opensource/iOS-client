//
//  MindNoteModule.swift
//  SpaceKit
//
//  Created by lijuyou on 2020/6/9.
//  


import Foundation
import SKCommon
import SKFoundation
import SKInfra
import LarkContainer

public final class MindNoteModule: ModuleService {

    public init() { }

    public func setup() {
        DocsLogger.info("MindNoteModule setup")
        DocsContainer.shared.register(MindNoteModule.self, factory: { _ in
            return self
        }).inObjectScope(.container)
    }

    public func registerJSServices(type: DocsJSServiceType, ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?, register: (JSServiceHandler) -> Void) {
        switch type {
        case .individualBusiness: // 纯 mindnote 要用到的 service 放在这里
            register(MindNoteSetViewService(ui: ui, model: model, navigator: navigator))
            register(MindnoteShowThemeCardService(ui: ui, model: model, navigator: navigator))
        default:
            break
        }
    }
}
