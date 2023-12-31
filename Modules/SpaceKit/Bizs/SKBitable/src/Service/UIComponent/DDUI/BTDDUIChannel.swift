//
//  BTDDUIChannel.swift
//  SKBitable
//
//  Created by X-MAN on 2023/4/12.
//

import Foundation
import SKFoundation
import SKCommon
import LarkWebViewContainer
import SpaceInterface

final class BTDDUIChannel {
    
    var context: BTDDUIContext
    private var componentMap: [String: (any BTDDUIComponentProtocol, BTDDUIBaseModel)] = [:]
    // 存储componentId的栈，pop的时候按顺序unmount
    private var viewStack: [String] = []
    
    init(context: BTDDUIContext) {
        self.context = context
    }
    
    func handle(data: BTDDUIBaseModel, baseContext: BaseContext) {
        switch data.action {
        case .mount:
            guard !data.mounted else {
                DocsLogger.btError("[BTDDUIService] component has already mounted \(data.componentType.rawValue)")
                return
            }
            do {
                let component = try BTDDUIComponentFactory.constructComponent(with: data, baseContext: baseContext)
                component.context = context
                component.onMountCallbackId = data.onMounted
                component.onUnmountCallbackId = data.onUnmounted
                componentMap[data.componentId] = (component, data)
                viewStack.append(data.componentId)
                let model = try component.classObject.convert(from: data.payload)
                try component.mountInternal(with: model)
                component.unmountBlock = { [weak self] in
                    if !UserScopeNoChangeFG.XM.dduiUnmoutBlockFixDisable {
                        self?.componentMap[data.componentId] = nil
                        if let index = self?.viewStack.firstIndex(of: data.componentId) {
                            self?.viewStack.remove(at: index)
                        }
                    }
                }
//                excuteCallback(with: data)
            } catch let error {
                DocsLogger.btError("[BTDDUIService] can not construct component \(error)")
//                excuteCallback(with: data, error: error)
                return
            }
            
        case .setData:
            if let component = componentMap[data.componentId]?.0 {
                do {
                    let payload = try component.classObject.convert(from: data.payload)
                    try component.setDataInternal(with: payload)
//                    excuteCallback(with: data)
                } catch let error {
                    DocsLogger.btError("[BTDDUIService] can not deserialize payload \(error)")
//                    excuteCallback(with: data, error: error)
                }
            } else {
                DocsLogger.btError("[BTDDUIService] setData failed: cant find component")
//                excuteCallback(with: data, error: BTDDUIError.setDataWithoutComponent)
                return
            }
        case .unmount:
            if let component = componentMap[data.componentId]?.0 {
                component.unmount()
                viewStack.removeAll(where: { $0 == data.componentId })
                componentMap.removeValue(forKey: data.componentId)
//                excuteCallback(with: data)
            } else {
                DocsLogger.btError("[BTDDUIService] unmount not mounted component")
                //excuteCallback(with: data, error: BTDDUIError.unmountFailed)
            }
        }
    }
    
    func clearAll() {
        while !viewStack.isEmpty {
            if let componentId = viewStack.popLast() {
                componentMap[componentId]?.0.unmount()
            }
        }
        componentMap.removeAll()
    }
}


fileprivate extension BTDDUIComponentProtocol {
    var classObject: Self.Type {
        return Self.self
    }
    
    func setDataInternal(with model: BTDDUIPlayload) throws {
        if let model = model as? Self.UIModel {
            try setData(with: model)
        } else {
            DocsLogger.btError("[BTDDUIService] model type invalid")
            throw BTDDUIError.setDataFailedInvalidData
        }
    }
    
    func mountInternal(with model: BTDDUIPlayload) throws {
        if let model = model as? Self.UIModel {
            try mount(with: model)
        } else {
            DocsLogger.btError("[BTDDUIService] mountInternal model type invalid")
            throw BTDDUIError.setDataFailedInvalidData
        }
    }
}
