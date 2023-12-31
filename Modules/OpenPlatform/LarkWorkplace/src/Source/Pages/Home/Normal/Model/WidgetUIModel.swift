//
//  WidgetUIData.swift
//  LarkWorkplace
//
//  Created by 李论 on 2020/5/26.
//

import Foundation
import LKCommonsLogging

struct WidgetUIModel {
    /// 请求的WidgetID
    var widgetID: String = ""
    /// 请求的Widget当时的版本
    var widgetVersion: String = ""
    /// 缓存在本地的数据
    var cacheData: WidgetBizCacheData?
    /// 远程数据
    var remoteData: WidgetBizCacheData?
    /// 是否设置过业务数据
    var didUpdateData: Bool = false
    /// 是否可以设置业务数据，因为卡片在加载的最初时间，还没准备好
    var canUpdateData: Bool = false
}

/// widget 业务数据来源
enum WidgetBizCacheDataSource: String {
    case pull
    case push
}

final class WidgetBizDataUpdate {
    static let logger = Logger.log(WidgetBizDataUpdate.self)
    /// 业务数据更新逻辑
    var data: WidgetUIModel
    /// 业务数据更新时的回调
    var callback: (WidgetBizCacheData?, Error?, WidgetBizDataUpdate) -> Void
    /// 业务数据缓存管理对象
    var dataManage: WidgetDataManage
    /// 业务数据push observe ID
    var observeID: String?
    /// unique Identifier
    var uniqueWidgetID: String

    private let userId: String

    /// 业务数据控制逻辑初始化
    init(
        userId: String,
        dataManage: WidgetDataManage,
        widgetID: String,
        widgetVersion: String,
        uniqueWidgetID: String,
        dataUpdateCallback: @escaping (WidgetBizCacheData?, Error?, WidgetBizDataUpdate) -> Void
    ) {
        self.userId = userId
        self.dataManage = dataManage
        self.data = WidgetUIModel()
        self.data.widgetID = widgetID
        self.data.widgetVersion = widgetVersion
        self.uniqueWidgetID = uniqueWidgetID
        self.callback = dataUpdateCallback
        /// 加载widget业务数据缓存
        loadWidgetCache()
        /// 监听widget业务数据push
        observePushData()
    }

    deinit {
        clearPush()
    }

    /// 加载本地缓存数据
    func loadWidgetCache() {
        data.cacheData = dataManage.getWidgetData(widgetID: self.data.widgetID) as? WidgetBizCacheData
    }

    /// 尝试刷新数据
    func flushCardData() {
        if let bizData = data.remoteData ?? data.cacheData {
            callbackWithBizData(
                timeout: false,
                loadError: nil,
                bizDataObj: bizData
            )
        }
    }

    /// 尝试push数据到卡片
    func callbackWithBizData(timeout: Bool, loadError: Error?, bizDataObj: WidgetBizCacheData?) {
        /// 如果更新数据全部为空，表示超时没有拿到业务数据
        guard !timeout else {
            let errorMsg = "\(data.widgetID) load bizdata timeout"
            WidgetBizDataUpdate.logger.error(errorMsg)
            let errorInfo = NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorTimedOut,
                userInfo: [NSLocalizedDescriptionKey: errorMsg]
            )
            self.callback(nil, errorInfo, self)
            return
        }
        /// 如果加载业务数据出现了错误，那么直接回调错误
        guard loadError == nil else {
            WidgetBizDataUpdate.logger.error(
                "\(data.widgetID) load bizdata error \(loadError?.localizedDescription ?? "")"
            )
            self.callback(nil, loadError, self)
            return
        }
        /// 只有卡片允许更新数据的时候(JSRuntime就绪），才能更新
        guard data.canUpdateData else {
            WidgetBizDataUpdate.logger.info("\(data.widgetID) not ready to update card data")
            return
        }
        self.callback(bizDataObj, nil, self)
        markAlreadyCallbackData() // 标记业务数据ready，已经注入到cardContainer
        clearBizData()  // 清空已经消费的业务数据
    }

    func markAlreadyCallbackData() {
        /// 标记更新过数据
        data.didUpdateData = true
    }

    /// 清理已经消费的业务数据
    func clearBizData() {
        data.cacheData = nil
        data.remoteData = nil
    }

    /// 清理监听
    func clearPush() {
        if let pushIDToRemove = observeID {
            dataManage.removeWidgetDataPushObserver(observeID: pushIDToRemove)
        }
    }

    /// 标记已经可以更新业务数据
    func readyToUpdateCard() {
        data.canUpdateData = true
        flushCardData()
    }

    /// 构造请求上下文
    func widgetDataRequestContext() -> WidgetBizDataReqContext {
        let req = WidgetBizDataReqContext()
        req.userID = userId
        req.widgetID = data.widgetID
        req.widgetVersion = data.widgetVersion
        req.locale = WorkplaceTool.curLanguage()
        return req
    }

    /// 监听业务数据
    func observePushData() {
        /// 清理历史监听
        clearPush()
        /// 构造监听上下文
        let req = widgetDataRequestContext()
        /// 注册监听
        observeID = dataManage.observeWidgetDataPush(req: req) {  [weak self] (rsp, err) in
            if err != nil {
                self?.callbackWithBizData(
                    timeout: false,
                    loadError: err,
                    bizDataObj: nil
                )
            } else if let bizData = rsp.first as? WidgetBizCacheData {
                self?.processRespBizData(
                    req: req,
                    widgetBizData: bizData,
                    source: .push
                )
            }
        }.observeID
    }

    /// 直接拉取业务数据
    func requestRemoteData() {
        let req = widgetDataRequestContext()

        dataManage.batchRequestWidgetData(reqList: [req]) { [weak self] (rsp, err) in
            /// 如果存在错误，那么尝试直接回调错误
            if err != nil {
                self?.callbackWithBizData(
                    timeout: false,
                    loadError: err,
                    bizDataObj: nil
                )
            } else if let bizData = rsp.first as? WidgetBizCacheData {
                self?.processRespBizData(
                    req: req,
                    widgetBizData: bizData,
                    source: .pull
                )
            }
        }
    }

    /// 处理响应的widget业务数据，需要根据来源的不同，分别处理
    private func processRespBizData(
        req: WidgetBizDataReqContext,
        widgetBizData: WidgetBizCacheData,
        source: WidgetBizCacheDataSource
    ) {
        /// 暂存业务数据
        data.remoteData = widgetBizData
        /// 刷新carde业务数据
        flushCardData()
        /// 缓存数据
        dataManage.updateCache(
            widgetID: req.widgetID,
            data: widgetBizData
        )
    }
}
