//
//  ModuleManager.swift
//  SKCommon
//
//  Created by lijuyou on 2020/6/8.
//  


import Foundation
import SKFoundation
import LarkContainer

public extension CCMExtension where Base == UserResolver {
    
    // 因为DocsSDK还未改造完,暂时继续使用单例
    public var moduleManager: ModuleManager {
        return .singleInstance
    }
}

public final class ModuleManager {
    
    //TODO.chensi 用户态迁移完成后删除旧的单例代码
    fileprivate static let singleInstance = ModuleManager()
    
    private var moduleList = [ModuleService]()

    private init() {}
    
    public func registerModules(_ modules: [ModuleService]) {
        self.moduleList = modules
        for module in moduleList {
            module.setup()
        }
    }
}

extension ModuleManager: ModuleService {

    public func setup() {
        //do nothing
    }

    public func registerURLRouter() {
        for module in moduleList {
            module.registerURLRouter()
        }
    }

    public func registerJSServices(type: DocsJSServiceType, ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?, register: (JSServiceHandler) -> Void) {
        for module in moduleList {
            module.registerJSServices(type: type, ui: ui, model: model, navigator: navigator, register: register)
        }
    }

    public func userDidLogout() {
        for module in moduleList {
            module.userDidLogout()
        }
    }

    public func userDidLogin() {
        for module in moduleList {
            module.userDidLogin()
        }
    }
}
