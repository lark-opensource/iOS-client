//
//  BaseFollowAPIImpl+Define.swift
//  SKBrowser
//
//  Created by lijuyou on 2020/9/17.
//  


import Foundation

extension BaseFollowAPIImpl {
    struct ParamKey {
        public static let data = "data"
        public static let body = "body"
        public static let token = "token"
        public static let funcName = "funcName"
        public static let callbackId = "callbackId"
        public static let module = "module"
        public static let eventType = "eventType"
        public static let source = "source"
        public static let action = "action"
        public static let paramJson = "paramJson"
        public static let metaJson = "metaJson"
        public static let dataJson = "dataJson"
        public static let resultJson = "resultJson"
    }

    struct InvokeMethod {
        public static let invoke = "vcfollow.invoke"
        public static let sendEvent = "vcfollow.sendEvent"
        public static let registerEventHandler = "vcfollow.registerEventHandler"
        public static let unRegisterEventHandler = "vcfollow.unRegisterEventHandler"
        public static let destroy = "vcfollow.destroy"
    }

    struct FuncName {
        public static let startRecord = "startRecord"
        public static let stopRecord = "stopRecord"
        public static let startReplay = "startReplay"
        public static let stopReplay = "stopReplay"
        public static let replayActions = "replayActions"
        public static let getCurrentStatus = "getCurrentStatus"
        public static let refresh = "refresh"
        public static let updateOptions = "updateOptions"
        public static let setNativeStatus = "setNativeStatus"
        public static let updateContext = "updateContext"
    }

    struct EventSource {
        public static let outer = "outer"
        public static let inner = "inner"
    }

    enum FollowModuleSendEvent: String {
        case followAction = "FOLLOW_ACTION"     //Follow动作-- 发送给RN的Event
        case presenterFollowerLocation = "FOLLOW_EVENT:PRESENTER_FOLLOWER_LOCATION"       //共享者&跟随者位置
    }

    /// 模块接收RN的Event
    enum FollowModuleRecvEvent: String {
        case followReplay = "FOLLOW_REPLAY"     //动作回放
        case presenterState = "PRESENTER_STATE" //自由浏览时派发主持人状态
    }
    
    /// 可监听的 Follow 模块
    enum FollowModule: String {
        case boxPreview = "BoxPreview" // 文档内附件
        case docxBoxPreview = "DocxBoxPreview" // 文档同层预览附件
    }
}
