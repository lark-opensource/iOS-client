//
//  RNDefines.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/7/22.
//

import Foundation

public protocol RNMangerAPI: AnyObject {
    func sendSpaceBusnessToRN(data: [String: Any])
    func sendSyncData(data: [String: Any], responseId: String?)
    func registerRnEvent(eventNames: [RNManager.RNEventName], handler: RNMessageDelegate)
}

extension RNMangerAPI {
    func sendSyncData(data: [String: Any]) {
        sendSyncData(data: data, responseId: nil)
    }
}

public protocol RNMessageDelegate: AnyObject {

    /// 处理收到的 RN 的数据
    ///
    /// - Parameters:
    ///   - data: 具体的数据
    ///   - eventName: 响应的 RN 事件
    func didReceivedRNData(data: [String: Any], eventName: RNManager.RNEventName)

    /// 判断推送是否可以由当前实例响应。
    /// 只有当前端的数据里有“identifier”字段 时，才会被调用
    ///
    /// - Parameter identifier: 用来判断是否由当前实例响应的信息
    /// - Returns: YES，可以处理这个；NO 不可以处理这次事件
    func compareIdentifierEquality(identifier: [String: Any]) -> Bool
}

extension RNMessageDelegate {
    var identifier: [String: Any]? { return nil }
    public func compareIdentifierEquality(identifier: [String: Any]) -> Bool { return true }
}

extension RNManager {
    public enum RNEventName: String {
        case sendMessageToWebview = "biz.util.sendMessageToWebview"
        case rnSetData = "biz.util.setData"
        case rnGetData = "biz.util.getData"
        case offlineCreateDocs = "biz.util.getOfflineCreatedDoc"
        case syncDocInfo = "biz.notify.syncDocInfo"
        case notifySyncStatus = "biz.util.notifySyncStatus"
        case modifyOfflineDocInfo = "biz.util.modifyOfflineDocInfo"
        case logger = "biz.util.logger"
        case batchLogger = "biz.util.batchLogger" // RN日志聚合
        case uploadImage = "biz.util.uploadImage" //即将废弃，使用uploadFile
        case uploadFile = "biz.util.uploadFile"
        case comment
        case permission
        case base   // 所有信箱服务都是用这个
        case version
        case common
        case sheetPreloadComplete = "biz.sheet.loadComplete"
        case bitablePreloadComplete = "biz.bitable.loadComplete"
        case docxPreloadComplete = "biz.docx.loadComplete"
        case preloadImages = "biz.util.preloadImage"
        case rnPreloadComplete = "biz.util.preloadComplete"
        case rnStatistics = "biz.statistics.reportEvent"
        case getDataFromRN = "biz.util.sendDataToNative"
        case showQuotaDialog = "biz.util.showFullQuoteDialog"
        case postMessage = "biz.comment.postMessage"
        case larkUnifiedMessage
        case getAppSetting = "biz.util.getAppSetting" // RN获取native的settings
        case unknown
    }

    enum BundleType: String {
        case base = "base_0_61_2.ios"
        case doc
        case comment
        case permission
        case version
        case common
    }
}

extension RNManager: RNMangerAPI {}
