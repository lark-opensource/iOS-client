//
//  NativeFollowAPIImpl.swift
//  SpaceKit
//
//  Created by lijuyou on 2020/4/9.
//  


import Foundation
import SpaceInterface
import SwiftyJSON
import SKCommon
import SKFoundation

class NativeFollowAPIImpl: BaseFollowAPIImpl {

    override func onSetup(events: [FollowEvent]) {
        super.onSetup(events: events)
        RNManager.manager.registerRnEvent(eventNames: [.getDataFromRN], handler: self)
        self.registerEventsFunc(events: events)
    }

    override var isHostNativeContent: Bool {
        return true
    }

    // MARK: SpaceFollowAPIDelegate
    //注册模块
    override func follow(_ followableHost: FollowableViewController?, register content: FollowableContent) {
        followableContentDict[content.moduleName] = content
        content.onSetup(delegate: self)
        self.registerEventHandler(eventType: FollowModuleRecvEvent.followReplay.rawValue, module: content.moduleName, source: EventSource.inner)
        self.registerEventHandler(eventType: FollowModuleRecvEvent.presenterState.rawValue, module: content.moduleName, source: EventSource.inner)
    }
    
    override func follow(_ followableHost: FollowableViewController?, unRegister content: FollowableContent) {
        followableContentDict.removeValue(forKey: content.moduleName)
    }

    /// 处理并解析接收到的原生事件（重写父类方法，因为解析方式不一样）
    override func onModuleRecvEvent(_ event: FollowModuleRecvEvent, jsonStr: String?) {
        guard let jsonStr = jsonStr else {
            rootTracing.error("onModuleRecvEvent jsonStr is nil")
            return
        }
        guard let utf8Data = jsonStr.data(using: .utf8),
              let moduleState = try? JSONDecoder().decode(FollowModuleState.self, from: utf8Data) else {
            rootTracing.error("onModuleRecvEvent module State format err", extraInfo: ["data": jsonStr])
            return
        }
        // 将event转发到业务
        self.onModuleStateChange(eventType: event, state: moduleState)
    }
    
    override func onModuleStateChange(eventType: FollowModuleRecvEvent, state: FollowModuleState?) {
        switch eventType {
        case .followReplay:
            if let state = state {
                followableContentDict[state.module]?.setState(state)
            }
        case .presenterState:
            if let state = state {
                followableContentDict[state.module]?.updatePresenterState(state)
            } else {
                for module in followableContentDict.values {
                    module.updatePresenterState(nil)
                }
            }
        default:
            break
        }
    }
    
    // FollowableContentDelegate
    override func onContentEvent(_ event: FollowModuleEvent, at mountToken: String?) {
        switch event {
        case .stateChanged(let state):
            onStateChanged(state)
        case .presenterLocationChanged(let state):
            onPresenterLocationChanged(state)
        }
    }
}

extension NativeFollowAPIImpl {
    private func onStateChanged(_ state: FollowModuleState) {
        rootTracing.info("onStateChanged module: \(state.module), action: \(state.actionType)")
        guard  let data = try? JSONEncoder().encode(state) else {
            return
        }
        let dataJson = String(data: data, encoding: String.Encoding.utf8)
        self.sendEvent(eventType: FollowModuleSendEvent.followAction.rawValue, dataJson: dataJson)
    }

    private func onPresenterLocationChanged(_ state: FollowLocationState) {
        rootTracing.info("onPresenterLocationChanged")
        guard  let data = try? JSONEncoder().encode(state) else {
            rootTracing.error("onPresenterLocationChanged encode json err")
            return
        }
        let dataJson = String(data: data, encoding: String.Encoding.utf8)
        self.sendEvent(eventType: FollowModuleSendEvent.presenterFollowerLocation.rawValue, dataJson: dataJson)
    }
}

// MARK: RNMessageDelegate -- 接收RN->Native的数据
extension NativeFollowAPIImpl: RNMessageDelegate {

    func didReceivedRNData(data outData: [String: Any], eventName: RNManager.RNEventName) {
        guard let data = outData[ParamKey.data] as? [String: Any], let action = data[ParamKey.action] as? String, let innerData = data[ParamKey.data] as? [String: Any]  else {
            DocsLogger.vcfInfo("didReceivedRNData,ignore action...")
            return
        }
        rootTracing.info("didReceivedRNData action: \(action)")
        switch action {
        case "vcfollow.onInvokeResult":
            self.onInvokeResult(data: innerData)
        case "vcfollow.onEvent":
            self.onEvent(data: innerData)
        default:
            return
        }
    }

}
