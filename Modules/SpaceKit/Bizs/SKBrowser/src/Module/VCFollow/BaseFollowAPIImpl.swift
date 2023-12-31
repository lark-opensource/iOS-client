//
//  BaseFollowAPIImpl.swift
//  SpaceKit
//
//  Created by lijuyou on 2020/4/10.
//swiftlint:disable file_length

import Foundation
import SpaceInterface
import SwiftyJSON
import SKCommon
import SKFoundation
import LarkContainer

/// 通用的FollowAPI实现基类
/// 主要作用：RN通信、FollowAPIDelegate
class BaseFollowAPIImpl: SKTracableProtocol, FollowableContentDelegate {

    var followViewController: FollowableViewController     //实现了FollowableViewController的实例
    weak var attachFile: FollowableViewController? // 附件VC
    var nativeFollowViewControllers = NSHashTable<UIViewController>(options: .weakMemory)
    var token: String?
    var meetingID: String?
    var url: URL
    var callbackDict = [String: FollowStateCallBack]() //NSMapTable<NSString, AnyObject>(keyOptions: .strongMemory, valueOptions: .weakMemory)
    weak var followAPIDelegate: FollowAPIDelegate?
    var followRole: FollowRole = .none
    var refreshing = false
    var registerEvents: [FollowEvent]?
    var optionsParams: String?
    var contextString: String?
    
    var tracingContext: TracingContext?
    var tracingComponent: String {
        return LogComponents.vcFollow
    }
    
    var isHostNativeContent: Bool {
        return false
    }
    
    @ThreadSafe var followableContentDict: Dictionary = [String: FollowableContent]()
    var currentFollowAttachMountToken: String?

    init(url: URL, vcWebId: String, followableVC: FollowableViewController) {
        self.url = url
        self.followViewController = followableVC
        let isDocsUrl = URLValidator.isDocsURL(url)
        if let fileToken = isDocsUrl ? DocsUrlUtil.getFileToken(from: (url)) : Self.getThirdPartyUrlToken(url) {
            self.token = "\(fileToken)\(vcWebId)"
        }
        self.meetingID = getUrlParam(url: url, key: "vc_meeting_id")
    }

    deinit {
        rootTracing.startChildAndEndAutomatically(spanName: SKVCFollowTrace.closeVCFollow)
        rootTracing.finish()
        callbackDict.removeAll()
        registerEvents?.removeAll()
        followViewController.onDestroy()
        destroyRN()
    }

    func onSetup(events: [FollowEvent]) {
        self.followViewController.onSetup(followAPIDelegate: self)
        self.registerEvents = events
    }

    func registerEventsFunc(events: [FollowEvent]?) {
        let eventNames = events?.map { $0.rawValue } ?? []
        rootTracing.startChildAndEndAutomatically(spanName: SKVCFollowTrace.implRegisterEvents, params: ["events": eventNames])
        guard let evts = events else { return }
        //RegistEvent for VC
        for event in evts {
            self.registerEventHandler(eventType: event.rawValue, source: EventSource.outer)
        }
        // 注册同层附件 Follow 状态：DocxBoxPreview
        self.registerEventHandler(eventType: FollowModuleRecvEvent.followReplay.rawValue,
                                    module: FollowModule.docxBoxPreview.rawValue,
                                    source: EventSource.inner)
    }

    static func startMeeting() {
        DocsLogger.vcfInfo("startMeeting....")
        PowerConsumptionExtendedStatistic.shared.markBeginMagicShare()
        if UserScopeNoChangeFG.CS.msDowngradeNewStrategyEnable {
            let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: true)
            if let service = try? userResolver.resolve(assert: CCMMagicShareDowngradeService.self) {
                service.startMeeting()
            }
        }
    }

    static func stopMeeting() {
        DocsLogger.vcfInfo("stopMeeting, destroy all RNFollowObj....")
        Self.sendDataToRN(operation: InvokeMethod.destroy, body: [:])//token为空代表destroy所有RNfollow实例
        PowerConsumptionExtendedStatistic.shared.markEndMagicShare()
        if UserScopeNoChangeFG.CS.msDowngradeNewStrategyEnable {
            let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: true)
            if let service = try? userResolver.resolve(assert: CCMMagicShareDowngradeService.self) {
                service.stopMeeting()
            }
        }
    }
    
    func follow(_ followableHost: FollowableViewController?, register content: FollowableContent) {
        if let mountToken = content.followMountToken {
            followableContentDict[mountToken] = content
        } else {
            var contentModuleName = content.moduleName
            if FollowNativeModule(rawValue: contentModuleName) != nil {
                // 如果属于原生 Follow 内容，注册监听的 Module 为 BoxPreview
                contentModuleName = FollowModule.boxPreview.rawValue
            }
            followableContentDict[contentModuleName] = content
            rootTracing.info("AttachFollow: register FollowableContent no mountToken")
        }
        content.onSetup(delegate: self)
    }
    
    func follow(_ followableHost: FollowableViewController?, unRegister content: FollowableContent) {
        guard let mountToken = content.followMountToken else { return }
        followableContentDict.removeValue(forKey: mountToken)
    }
    
    // MARK: 解析收到的原生事件（Follower 回放事件）
    func onModuleRecvEvent(_ event: FollowModuleRecvEvent, jsonStr: String?) {
        guard let jsonStr = jsonStr else {
            rootTracing.error("onModuleRecvEvent jsonStr is nil")
            return
        }
        guard let utf8Data = jsonStr.data(using: .utf8),
              let moduleStates = try? JSONDecoder().decode([FollowModuleState].self, from: utf8Data) else {
            rootTracing.error("onModuleRecvEvent module State format err", extraInfo: ["data": jsonStr])
            return
        }
        for moduleState in moduleStates {
            // 将event转发到业务
            self.onModuleStateChange(eventType: event, state: moduleState)
        }
    }

    func onModuleStateChange(eventType: FollowModuleRecvEvent, state: FollowModuleState?) {
        switch eventType {
        case .followReplay:
            guard let state = state else { return }
            guard let followModule = FollowModule(rawValue: state.module) else { return }
            switch followModule {
            case .boxPreview:
                DocsLogger.info("AttachFollow receive BoxPreview state: \(state)")
                guard let mountToken = currentFollowAttachMountToken else { return }
                followableContentDict[mountToken]?.setState(state)
                followableContentDict[state.module]?.setState(state)
            case .docxBoxPreview:
                // 当前有全屏附件时，不更新同层附件的 Follow 状态
                guard currentFollowAttachMountToken == nil else { return }
                for key in followableContentDict.keys {
                    let data = state.data["driveUpdateRecordIdMap"][key]
                    let moduleState = FollowModuleState(module: state.module, actionType: state.actionType, data: data)
                    followableContentDict[key]?.setState(moduleState)
                }
            }
        default:
            break
        }
    }
    
    // MARK: FollowableContentDelegate（Presenter 发出事件）
    func onContentEvent(_ event: FollowModuleEvent, at mountToken: String?) {
        switch event {
        case .stateChanged(let state):
            onStateChanged(state, at: mountToken)
        case .presenterLocationChanged:
            break
        }
    }
    
    private func onStateChanged(_ state: FollowModuleState, at mountToken: String?) {
        guard let mountToken = mountToken else {
            rootTracing.error("AttachFollow: stateChanged no mountToken")
            return
        }
        var dataJson: String
        if currentFollowAttachMountToken == mountToken {
            dataJson = state.getBoxPreviewData()
            rootTracing.info("AttachFollow send BoxPreview data: \(dataJson)")
        } else {
            dataJson = state.getDocxBoxPreviewData(mountToken: mountToken)
        }
        let operation = "window.lark.biz." + InvokeMethod.sendEvent
        var data: [String: Any] = [:]
        data[ParamKey.dataJson] = dataJson
        followViewController.executeJSFromVcfollow(operation: operation, params: data)
    }
}

// MARK: - FollowAPI
extension BaseFollowAPIImpl: FollowAPI {

    var followUrl: String {
        return url.absoluteString
    }

    var followTitle: String {
        return followViewController.followTitle
    }

    var followVC: UIViewController {
        return followViewController.followVC
    }

    /// 文档是否支持回到上次位置
    var canBackToLastPosition: Bool {
        return followViewController.canBackToLastPosition
    }

    var scrollView: UIScrollView? {
        return followViewController.followScrollView
    }

    var isEditingStatus: Bool {
        return followViewController.isEditingStatus
    }

    func setDelegate(_ delegate: FollowAPIDelegate) {
        self.followAPIDelegate = delegate
    }

    func startRecord() {
        rootTracing.startChildAndEndAutomatically(spanName: SKVCFollowTrace.implStartRecord)
        changeRole(.presenter)
        self.innerInvoke(funcName: FuncName.startRecord)
    }

    func stopRecord() {
        rootTracing.startChildAndEndAutomatically(spanName: SKVCFollowTrace.implStopRecord)
        changeRole(.none)
        self.innerInvoke(funcName: FuncName.stopRecord)
    }

    func startFollow() {
        rootTracing.startChildAndEndAutomatically(spanName: SKVCFollowTrace.implStartFollow)
        changeRole(.follower)
        self.innerInvoke(funcName: FuncName.startReplay)
    }

    func stopFollow() {
        rootTracing.startChildAndEndAutomatically(spanName: SKVCFollowTrace.implStopFollow)
        changeRole(.none)
        self.innerInvoke(funcName: FuncName.stopReplay)
    }

    func setState(states: [FollowState], meta: String?) {
        if followRole == .presenter {
            rootTracing.error("cannot setState to presenter")
            return
        }
        rootTracing.info("setState...")
        var stateDicts = [[String: Any]]()
        for action in states {
            let json = action.toJSONString()
            if let dic = json.toDictionary() {
                stateDicts.append(dic)
            }
        }
        let stateJSON = stateDicts.toJSONString()
        guard let paramJson = stateJSON else {
            rootTracing.error("setState stateJSON error")
            return
        }
        self.innerInvoke(funcName: FuncName.replayActions, paramJson: paramJson, metaJson: meta)
    }

    func getState(callBack: @escaping FollowStateCallBack) {
        rootTracing.info("getState...")
        //let point = Unmanaged.passUnretained(callBack as AnyObject).toOpaque();  callbackId = "\(point.hashValue)"
        let callbackId = "\(Date().timeIntervalSince1970)"
        callbackDict[callbackId] = callBack
        self.innerInvoke(funcName: FuncName.getCurrentStatus, callbackId: callbackId)
    }

    func reload() {
        rootTracing.info("reload isHostNativeContent: \(isHostNativeContent)")
        if !isHostNativeContent {
            refreshing = true
        }
        popAttachFileVCIfNeed()
        followViewController.refreshFollow()
        self.innerInvoke(funcName: FuncName.refresh)
    }

    func injectJS(_ script: String) {
        followViewController.injectJS(script)
    }
    
    func invoke(funcName: String,
                paramJson: String?,
                metaJson: String?,
                callBack: FollowStateCallBack?) {
        var callbackId: String?
        if let callBack = callBack {
            let timestamp = "\(Date().timeIntervalSince1970)"
            callbackDict[timestamp] = callBack
            callbackId = timestamp
        }
        rootTracing.info("invoke \(funcName)")
        self.innerInvoke(funcName: funcName, paramJson: paramJson, metaJson: metaJson, callbackId: callbackId)
    }

    func callFollowAPI(type: FollowAPIType) {
        switch type {
        case .backToLastPosition:
            self.sendDataToWebView(operation: DocsJSCallBack.backToLastPosition.rawValue, body: nil)
        case .clearLastPosition(let token):
            var params: [String: Any] = [:]
            if let token = token {
                params["token"] = token
            }
            self.sendDataToWebView(operation: DocsJSCallBack.clearLastPosition.rawValue, body: params)
        case .keepCurrentPosition:
            self.sendDataToWebView(operation: DocsJSCallBack.keepCurrentPosition.rawValue, body: nil)
        case .updateOptions(let paramJson):
            optionsParams = paramJson
            self.innerInvoke(funcName: FuncName.updateOptions, paramJson: paramJson)
        case .updateContext(let context):
            contextString = context
            self.innerInvoke(funcName: FuncName.updateContext, paramJson: context)
        }
    }

    /// 状态相关的方法，刷新完成后需要重新调用
    private func reloadReady() {
        //rn迁移到webview后，刷新完成后native需要主动调用startRecord/startFollow，避免follow状态丢失
        if followRole == .presenter {
            self.startRecord()
        } else if followRole == .follower {
            self.startFollow()
        }

        self.innerInvoke(funcName: FuncName.updateOptions, paramJson: optionsParams)
        self.innerInvoke(funcName: FuncName.updateContext, paramJson: contextString)
    }
    
    /// VC 界面即将进入小窗口模式
    func willSetFloatingWindow() {
        
        for vc in nativeFollowViewControllers.allObjects {
            let followerVC = vc as? FollowableViewController
            followerVC?.onOperate(.willSetFloatingWindow)
        }
        followViewController.onOperate(.willSetFloatingWindow)
    }
    
    func finishFullScreenWindow() {
        for vc in nativeFollowViewControllers.allObjects {
            let followerVC = vc as? FollowableViewController
            followerVC?.onOperate(.finishFullScreenWindow)
        }
        followViewController.onOperate(.finishFullScreenWindow)
    }
}

// MARK: - SpaceFollowAPIDelegate
extension BaseFollowAPIImpl: SpaceFollowAPIDelegate {

    func follow(_ followableHost: FollowableViewController?, onOperate operation: SpaceFollowOperation) {
        switch operation {
        case .vcOperation(let value):
            followAPIDelegate?.follow(self, onOperate: value)
        case .onExitAttachFile: //native主动退出附件预览
            rootTracing.info("AttachFollow: onExitAttachFile")
            unRegisterBoxPreview()
            currentFollowAttachMountToken = nil
            self.followViewController.onOperate(operation)
            followAPIDelegate?.follow(self, onOperate: .openOrCloseAttachFile(isOpen: false))
        case .exitAttachFile:   //web调用退出附件预览
            rootTracing.info("AttachFollow: exitAttachFile")
            followableContentDict.removeValue(forKey: currentFollowAttachMountToken ?? "")
            currentFollowAttachMountToken = nil
            popAttachFileVCIfNeed()
            followAPIDelegate?.follow(self, onOperate: .openOrCloseAttachFile(isOpen: false))
        case .onDocumentVCDidMove:
            for vc in nativeFollowViewControllers.allObjects {
                let followerVC = vc as? FollowableViewController
                //附件卡片被移除，通知前端
                followerVC?.onOperate(.onDocumentVCDidMove)
            }
            nativeFollowViewControllers.removeAllObjects()
        case let .nativeStatus(funcName, params):
            self.sendDataToWebView(operation: funcName, body: params)
        case .onRemoveFollowSameLayerFile(let mountToken):
            rootTracing.info("AttachFollow: onRemoveFollowSameLayerFile")
            followableContentDict.removeValue(forKey: mountToken)
        case .willSetFloatingWindow:
            break
        case .finishFullScreenWindow:
            break
        }
    }

    func followDidReady(_ followableHost: FollowableViewController?) {
        // web注册事件需要在followReday之后
        if !isHostNativeContent {
            self.registerEventsFunc(events: registerEvents)
        }

        rootTracing.startChild(spanName: SKVCFollowTrace.implFollowDidReady)
        if isCurrentHost(followableHost) {
            self.reloadReady()
            if refreshing {
                //刷新DocsBrowserVC时的DidReady不用回调
                refreshing = false
                return
            }
            followAPIDelegate?.followDidReady(self)
        }
        rootTracing.endSpan(spanName: SKVCFollowTrace.implFollowDidReady,
                             params: ["isCurrentHost": isCurrentHost(followableHost)])
    }
    
    func followAttachDidReady() {
        rootTracing.info("AttachFollow: attach did ready register BoxPreview")
        // 注册非同层附件 Follow 状态：BoxPreivew
        registerEventHandler(eventType: FollowModuleRecvEvent.followReplay.rawValue,
                                  module: FollowModule.boxPreview.rawValue,
                                  source: EventSource.inner)
    }

    func followDidRenderFinish(_ followableHost: FollowableViewController?) {
        rootTracing.startChild(spanName: SKVCFollowTrace.implFollowDidRenderFinish)
        if isCurrentHost(followableHost) {
            followAPIDelegate?.followDidRenderFinish(self)
        }
        rootTracing.endSpan(spanName: SKVCFollowTrace.implFollowDidRenderFinish,
                             params: ["isCurrentHost": isCurrentHost(followableHost)])
    }

    func followWillBack(_ followableHost: FollowableViewController?) {
        
        rootTracing.startChild(spanName: SKVCFollowTrace.implFollowWillBack)
        if isCurrentHost(followableHost) {
            followAPIDelegate?.followWillBack(self)
        }
        rootTracing.endSpan(spanName: SKVCFollowTrace.implFollowWillBack,
                             params: ["isCurrentHost": isCurrentHost(followableHost)])
    }

    func follow(_ followableHost: FollowableViewController?, add subHost: FollowableViewController) {
        rootTracing.startChildAndEndAutomatically(spanName: SKVCFollowTrace.implFollowAddSubHost)
        if !subHost.isSameLayerFollow {
            // 弹出附件(非同层)才标记当前的 attachFile
            if let vc = subHost as? UIViewController {
                nativeFollowViewControllers.add(vc)
            }
            if !UserScopeNoChangeFG.QYK.btSwitchAttachInMSFixDisable {
                if subHost.canSetAttachFile {
                    attachFile = subHost
                }
            } else {
                attachFile = subHost
            }
        }
        subHost.onSetup(followAPIDelegate: self)
    }
    
    func didReceivedJSData(data outData: [String: Any]) {
        guard let innerData = outData["data"] as? [String: Any],
              let action = outData["action"] as? String else {
            rootTracing.info("didReceived JSData,ignore action...")
            return
        }
        rootTracing.info("didReceivedJSData action: \(action)")
        switch action {
        case "vcfollow.onInvokeResult":
            self.onInvokeResult(data: innerData, isFromRN: false)
        case "vcfollow.onEvent":
            self.onEvent(data: innerData, isFromRN: false)
        default: break
        }
    }
}

extension BaseFollowAPIImpl {

    func onInvokeResult(data: [String: Any], isFromRN: Bool = true) {
        
        guard let callbackId = data[ParamKey.callbackId] as? String, let callback = callbackDict[callbackId] else {
            rootTracing.info("onInvokeResult callbackId unmatch")
            return
        }
        if isFromRN {
            guard let token = data[ParamKey.token] as? String, token == self.token else {
                rootTracing.error("onRNInvokeResult token match failed", extraInfo: ["isFromRN": isFromRN])
                return
            }
        }
        let funcName = data[ParamKey.funcName] as? String
        guard let resultJson = data[ParamKey.resultJson] else {
            rootTracing.error("onInvokeResult resultJson is Nil", extraInfo: ["isFromRN": isFromRN, "data": data])
            return
        }
        if let jsonStr = resultJson as? String, let actions = BaseFollowAPIImpl.convertJsonToFollowState(jsonStr) {
            rootTracing.info("callback to vc")
            let metaJson = data[ParamKey.metaJson] as? String
            callback(actions, metaJson)
        } else {
            rootTracing.error("onInvokeResult resultJson parse failed", extraInfo: ["isFromRN": isFromRN, "data": data])
        }
        
        #if DEBUG
        if funcName == FuncName.getCurrentStatus {
            DocsLogger.vcfDebug("getCurrentStatus: \(resultJson)")
        }
        #endif
        callbackDict.removeValue(forKey: callbackId)
    }

    func onEvent(data: [String: Any], isFromRN: Bool = true) {
        if isFromRN {
            guard let token = data[ParamKey.token] as? String, token == self.token else {
                rootTracing.error("onRNEvent token match failed", extraInfo: ["isFromRN": isFromRN, "data": data])
                return
            }
        }
        guard let eventType = data["eventType"] as? String else {
            rootTracing.error("onEvent eventType is nil", extraInfo: ["isFromRN": isFromRN, "data": data])
            return
        }
        let jsonStr = data[ParamKey.dataJson] as? String
        if let event = FollowEvent(rawValue: eventType) {
            let metaStr = data[ParamKey.metaJson] as? String
            onFollowEvent(event, jsonStr: jsonStr, metaStr: metaStr)
        } else if let event = FollowModuleRecvEvent(rawValue: eventType) {
            onModuleRecvEvent(event, jsonStr: jsonStr)
        } else {
            rootTracing.info("onRNEvent unknow Event: \(eventType)")
        }
    }

    private func onFollowEvent(_ event: FollowEvent, jsonStr: String?, metaStr: String?) {
        guard let jsonStr = jsonStr else {
            rootTracing.error("onFollowEvent jsonStr is nil")
            return
        }
        let json = JSON(parseJSON: jsonStr)
        guard let actionJSONs = json.arrayObject as?  [[String: Any]] else {
            rootTracing.error("onFollowEvent jsonStr parse error", extraInfo: ["data": jsonStr])
            return
        }
        var followActions = [SpaceInterface.FollowState]()
        for item in actionJSONs {
            guard JSONSerialization.isValidJSONObject(item) else {
                assertionFailure("非法json \(item)")
                rootTracing.error("前端传入非法json", extraInfo: ["item": item])
                continue
            }
            if let json = item.jsonString {
                followActions.append(DocsVCFollowState(rawJson: json))
            }
        }
        followAPIDelegate?.follow(self, on: event, with: followActions, metaJson: metaStr) //将event转发回给VC
    }
}

// MARK: - Native->RN 发送数据至RN
extension BaseFollowAPIImpl {


    /// VC的调用统一通过invoke到RN/web
    /// - Parameters:
    ///   - funcName: 调用名称startRecord/getState/setState
    ///   - paramJson: 参数
    ///   - callbackId: 回调ID
    func innerInvoke(funcName: String, paramJson: String? = nil, metaJson: String? = nil, callbackId: String? = nil) {
        var body: [String: Any] = [
            ParamKey.token: self.token ?? "",
            ParamKey.funcName: funcName,
            ParamKey.paramJson: paramJson ?? "",
            ParamKey.callbackId: callbackId ?? ""
        ]
        if let metaJson = metaJson {
            body[ParamKey.metaJson] = metaJson
        }
        sendData(operation: InvokeMethod.invoke, body: body)
    }


    /// 给rn发送模块事件, 在FollowableContent.onStateChange后发送
    func sendEvent(eventType: String, dataJson: String?) {
        let body: [String: Any] = [
            ParamKey.token: self.token ?? "",
            ParamKey.eventType: eventType,
            ParamKey.dataJson: dataJson ?? ""
        ]
        sendData(operation: InvokeMethod.sendEvent, body: body)
    }

    /// 向FollowSDK注册模块事件
    func registerEventHandler(eventType: String, module: String? = nil, source: String? = nil) {
        let body: [String: Any] = [
            ParamKey.token: self.token ?? "",
            ParamKey.module: module ?? "",
            ParamKey.eventType: eventType,
            ParamKey.source: source ?? ""]
        sendData(operation: InvokeMethod.registerEventHandler, body: body)
    }

    func unRegisterEventHandler(eventType: String, module: String? = nil) {
        let body: [String: Any] = [
            ParamKey.token: self.token ?? "",
            ParamKey.module: module ?? "",
            ParamKey.eventType: eventType
        ]
        sendData(operation: InvokeMethod.unRegisterEventHandler, body: body)
    }

    func destroyRN() {
        let body: [String: Any] = [ParamKey.token: self.token ?? ""]
        sendData(operation: InvokeMethod.destroy, body: body)
    }

    private func sendData(operation: String, body: [String: Any]) {
        if isHostNativeContent {
            Self.sendDataToRN(operation: operation, body: body)
        } else {
            let prefix = "window.lark.biz."
            sendDataToWebView(operation: prefix + operation, body: body)
        }
    }

    private static func sendDataToRN(operation: String, body: [String: Any]) {
        let data: [String: Any] = ["operation": operation, "body": body]
        let composedData: [String: Any] = ["business": "base", "data": data]
        RNManager.manager.sendSpaceBusnessToRN(data: composedData)
    }

    private func sendDataToWebView(operation: String, body: [String: Any]?) {
        //发送给webview处理，不经过RN
        let params = body?.filter { (key, _) in
            return key != ParamKey.token
        }
        self.followViewController.executeJSFromVcfollow(operation: operation, params: params)
    }
}

// MARK: - Private Method
extension BaseFollowAPIImpl {

    private static func convertJsonToFollowState(_ jsonStr: String) -> [FollowState]? {
        guard let data = jsonStr.data(using: .utf8) else { return nil }
        guard let actionJSONs = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else { return nil }
        var followActions = [FollowState]()
        for item in actionJSONs {
            if let json = item.jsonString {
                followActions.append(DocsVCFollowState(rawJson: json))
            }
        }
        return followActions
    }

    private static func getThirdPartyUrlToken(_ url: URL) -> String {
        guard url.fragment != nil, let fragmentIndex = url.absoluteString.lastIndex(of: "#") else {
            return url.absoluteString
        }
        let token = url.absoluteString[..<fragmentIndex]
        return String(token)
    }
    
    private func isCurrentHost(_ followableHost: FollowableViewController?) -> Bool {
        if let host = followableHost {
            return host === self.followViewController
        }
        return true //为nil时默认是当前的followViewController
    }

    //移除子FollowVC
    private func popAttachFileVCIfNeed() {
        rootTracing.info("popAttachFileVCIfNeed")
        if let attachVC = attachFile {
            if let topVC = attachVC.followVC.nearestNavigation?.topViewController {
                if topVC == attachVC.followVC {
                    rootTracing.info("popAttachFileVCIfNeed topVC success")
                    attachVC.followVC.nearestNavigation?.popViewController(animated: false)
                } else {
                    rootTracing.info("popAttachFileVCIfNeed topVC is not followVC")
                    // Docx 同层附件是 Present 的形式，把退出操作交回给附件的 VC 处理
                    attachVC.onOperate(.exitAttachFile)
                }
            } else {
                attachVC.followVC.dismiss(animated: true)
                rootTracing.info("popAttachFileVCIfNeed without topVC ")
            }
            attachFile = nil
        } else {
            rootTracing.info("popAttachFileVCIfNeed without attachFile")
        }
        unRegisterBoxPreview()
    }
    
    private func unRegisterBoxPreview() {
        rootTracing.info("AttachFollow: unRegisterBoxPreview")
        unRegisterEventHandler(eventType: FollowModuleRecvEvent.followReplay.rawValue,
                               module: FollowModule.boxPreview.rawValue)
    }

    private func getUrlParam(url: URL, key: String) -> String? {
        if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            let meetingIDItem = urlComponents.queryItems?.first { $0.name == key }
            return meetingIDItem?.value
        }
        return nil
    }

    private func changeRole(_ newRole: FollowRole) {
        if followRole == newRole {
            return
        }
        rootTracing.info("changeRole oldRole: \(followRole), newRole: \(newRole)")
        followRole = newRole
        self.followViewController.onRoleChange(newRole)
        for vc in nativeFollowViewControllers.allObjects {
            let followerVC = vc as? FollowableViewController
            followerVC?.onRoleChange(newRole)
        }
        if newRole != .none {
            self.onModuleStateChange(eventType: .presenterState, state: nil) //清空presenterState
        }
    }
}
