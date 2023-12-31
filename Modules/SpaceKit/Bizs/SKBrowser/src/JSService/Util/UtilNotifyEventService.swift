//
//  UtilNotifyEventService.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/7/4.
//  
//https://bytedance.feishu.cn/space/doc/UYjQ5NcMa2FydMRdjCSQwe#dyaRsZ
//页面通知客户端本文档（doc、sheet、slide、mindnote）的状态（3.4以后）

import Foundation
import SKCommon
import SKFoundation
import RxSwift
import RustPB
import LarkRustClient
import SKInfra

public final class UtilNotifyEventService: BaseJSService {
    
    var disposeBag = DisposeBag()
    
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
    }
}

extension UtilNotifyEventService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.notifyEvent]
    }

    public func handle(params: [String: Any], serviceName: String) {
        guard let eventName = params["event"] as? String, let event = Event(rawValue: eventName) else {
            DocsLogger.error("params not valid for \(serviceName), params is \(params)")
            return
        }
        DocsLogger.info("UtilNotifyEventService handle \(serviceName), params is \(params.jsonString?.encryptToShort)")
        switch event {
        case .delete:
            handleDelete(params)
        case .keyDelete:
            handleKeyDelete(params)
        case .versionRecover:
            versionRecover(params)
        case .notFound:
            handleNotFound(params)
        }
    }

    private func handleDelete(_ params: [String: Any]) {
        guard let objToken = params["token"] as? String else {
            DocsLogger.info("can not get objToken")
            return
        }
        let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
        dataCenterAPI?.deleteSpaceEntry(token: TokenStruct(token: objToken))
        
        // 文档被删兜底逻辑
        docDelete(objToken)
        
        // 展示删除兜底页
        ui?.displayConfig.handleDeleteEvent()
    }
    
    // 5.0版本从DocsFeedDataService迁移出来的
    private func docDelete(_ token: String) {
        guard let rustClient = DocsContainer.shared.resolve(RustService.self) else {
            DocsLogger.error("获取rustClient失败")
            return
        }
        var request = Space_Doc_V1_RemoveDocRequest()
        request.token = token
        _ = rustClient.sendAsyncRequest(request).subscribe({ _ in
            DocsLogger.info("调用兜底删除逻辑")
            }).disposed(by: disposeBag)
    }

    private func handleKeyDelete(_ params: [String: Any]) {
        DocsLogger.info("调用密钥删除逻辑")
        ui?.displayConfig.handleKeyDeleteEvent()
    }
    
    private func versionRecover(_ params: [String: Any]) {
        DocsLogger.info("notify version Recover Event", component: LogComponents.version)
        // 展示删除兜底页
        ui?.displayConfig.handleDeleteRecoverEvent()
    }
    
    private func handleNotFound(_ params: [String: Any]) {
        ui?.displayConfig.handleNotFoundEvent()
    }
}

extension UtilNotifyEventService {
    enum Event: String {
        // 文档删除
        case delete = "NOTE_DELETED"
        // 密钥删除
        case keyDelete = "KEY_DELETED"
        // 版本恢复
        case versionRecover = "EDITION_RECOVER"
        // 文档 NOT FOUND
        case notFound = "NOTE_NOT_FOUND"
    }
}
