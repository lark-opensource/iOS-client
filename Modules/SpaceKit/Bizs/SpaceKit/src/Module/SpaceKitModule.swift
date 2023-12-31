//
//  GlobalModule.swift
//  SpaceKit
//
//  Created by lijuyou on 2020/7/9.
//  


import Foundation
import EENavigator
import SKCommon
import SKSpace
import SKDrive
import SKBrowser
import SKUIKit
import SKSheet
import SKInfra
import LarkContainer
import SKFoundation

public class SpaceKitModule: ModuleService {
    
    public init() {}
    
    public func setup() {
        DocsContainer.shared.register(SpaceKitModule.self, factory: { _ in
            return self
        }).inObjectScope(.container)
    }

    /// 注册JSService
    public func registerJSServices(type: DocsJSServiceType, ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?, register: (JSServiceHandler) -> Void) {

        switch type {
        case .commonBusiness:
            register(UtilMoreService(ui: ui, model: model, navigator: navigator))
            register(UtilActionService(ui: ui, model: model, navigator: navigator))
        default:
            break
        }
    }
}
