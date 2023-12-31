//
//  WidgetDataManage.swift
//  LarkWorkplace
//
//  Created by 李论 on 2020/5/14.
//

import LKCommonsLogging
import LarkUIKit
import RxSwift
import SwiftyJSON
import Swinject
import RustPB
import LarkContainer
import LarkSetting
import LarkStorage

/// 控制单个Widget更新的频率的逻辑，目前不做控制，直接请求
final class GadgetDataUpdateLogic: GadgetDataUpdateLogicProtocol {
    func shouldUpdateWidgetData(widgetID: String) -> Bool {
        return true
    }

    func recordUpdateWidgetData(reqList: [WidgetBizDataReqContextProtocol]) {
        /// Pass
    }
}

/// Widget缓存对象
final class WidgetDataCache: WidgetDataCacheProtocol {
    static let logger = Logger.log(WidgetDataCache.self)
    /// 请求的用户身份
    private let userID: String
    private let configService: WPConfigService
    /// 缓存的map
    var widgetMap: WidgetBizCacheMapDataProtocol
    /// 多线程安全加锁
    private var lock = NSRecursiveLock()

    /// 根据用户身份初始化数据缓存
    init(userID: String, configService: WPConfigService) {
        self.userID = userID
        self.configService = configService
        self.widgetMap = WidgetBizCacheMapData(
            hostVersion: WorkplaceTool.appVersion,
            userID: userID
        )
        loadCache()
    }

    /// 从磁盘加载缓存
    func loadCache() {
        let store = KVStores.in(space: .user(id: userID), domain: Domain.biz.workplace).mmkv()
        let model: WidgetBizCacheMapData? = store.value(forKey: WPCacheKey.widgetModel)
        Self.logger.info("[\(WPCacheKey.widgetModel)] cache \(model == nil ? "miss" : "hit").")
        if let model = model { self.widgetMap = model }
    }

    /// 保存缓存到磁盘中
    func saveCacheToDisk() {
        lock.lock()
        defer {
            lock.unlock()
        }
        if let widgetMap = widgetMap as? WidgetBizCacheMapData {
            let store = KVStores.in(space: .user(id: userID), domain: Domain.biz.workplace).mmkv()
            store.set(widgetMap, forKey: WPCacheKey.widgetModel)
            Self.logger.info("[\(WPCacheKey.widgetModel)] cache data.")
        }
    }

    /// 更新缓存
    func updateCache(widgetID: String, data: WidgetBizCacheDataProtocol?) {
        lock.lock()
        defer {
            lock.unlock()
        }
        widgetMap.widgetBizDataMap[widgetID] = data
        saveCacheToDisk()
    }

    /// 得到缓存的Widget业务数据对象
    func getWidgetData(widgetID: String) -> WidgetBizCacheDataProtocol? {
        lock.lock()
        defer {
            lock.unlock()
        }
        return widgetMap.widgetBizDataMap[widgetID]
    }
}

typealias WidgetDataCallBack = ([WidgetBizCacheDataProtocol], Error?) -> Void

/// push 观察者的上下文
struct WidgetDataObserveContext {
    let observeID: String
    let request: WidgetBizDataReqContextProtocol
    let callback: WidgetDataCallBack
}

/// Lock extension
extension NSRecursiveLock {
    func withCriticalSection<T>(_ closure: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try closure()
    }
}

/// Widget业务数据管理对象
final class WidgetDataManage: WidgetDataProtocol {
    static let log = Logger.log(WidgetDataManage.self)
    static let defaultHttpResponseCode = -9988
    static let defaultHttpMessage = "defaultHttpMessage"
    /// 更新频率控制
    let updateLogic: GadgetDataUpdateLogicProtocol
    /// 缓存对象
    let gadgetCache: WidgetDataCacheProtocol
    private let networkService: WPNetworkService
    /// manage push callback context
    var widgetObserverList: [WidgetDataObserveContext] = []
    /// widgetObserverList lock
    let lock = NSRecursiveLock()
    /// dispose bag
    private let disposeBag = DisposeBag()

    private let pushCenter: PushNotificationCenter
    private let traceService: WPTraceService

    init(
        pushCenter: PushNotificationCenter,
        traceService: WPTraceService,
        gadgetCache: WidgetDataCacheProtocol,
        networkService: WPNetworkService
    ) {
        self.pushCenter = pushCenter
        self.traceService = traceService
        self.gadgetCache = gadgetCache
        self.networkService = networkService
        self.updateLogic = GadgetDataUpdateLogic()
        observeGadgetPush()
    }

    /// 注册gadget push，提取widget data push的数据，然后处理
    func observeGadgetPush() {
        WidgetDataManage.log.info("WidgetDataManage observeGadgetPush")
        pushCenter.observable(for: GadgetCommonPushMessage.self)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self]message in
                guard let self = self else {
                    WidgetDataManage.log.info("Widget received push message, but self released")
                    return
                }
                /// 数据处理
                WidgetDataManage.log.info("Widget received push message biz \(message.biz)")
                if GadgetCommonPushBiz(rawValue: message.biz) == .widget {
                    self.handleWidgetPush(message: message)
                }
            })
    }

    /// 处理widget data push
    func handleWidgetPush(message: GadgetCommonPushMessage) {
        WidgetDataManage.log.info("Widget handleWidgetPush")
        let pushJson = JSON(parseJSON: message.data)
        for widgetJson in pushJson.arrayValue {
            if checkWidgetDataPlatform(platformData: widgetJson["Platform"].string) {
                let singleRspItem = WidgetBizDataResp(json: widgetJson)
                notifyPushCallback(pushRsp: singleRspItem)
            }
        }
    }

    /// data的平台数据校验
    private func checkWidgetDataPlatform(platformData: String?) -> Bool {
        guard let platform = platformData else {
            WidgetDataManage.log.error("widget data miss platform")
            return false
        }
        if UIDevice.current.userInterfaceIdiom == .pad {
            guard platform == "ipad" else {
                WidgetDataManage.log.warn("widget data's platform(\(platform)) not apply to iPad")
                return false
            }
        } else {
            guard platform == "iphone" else {
                WidgetDataManage.log.warn("widget data's platform(\(platform)) not apply to iPhone")
                return false
            }
        }
        return true
    }

    /// find proper request context and callback
    func notifyPushCallback(pushRsp: WidgetBizDataResp) {
        WidgetDataManage.log.info("Widget notifyPushCallback")
        var matchContextList: [(WidgetDataObserveContext, WidgetBizDataResp)] = []
        lock.withCriticalSection { () -> Void in
            for context in widgetObserverList {
                if requestMatchResponse(request: context.request, response: pushRsp) {
                    matchContextList.append((context, pushRsp))
                }
            }
        }

        for (ctx, rsp) in matchContextList {
            WidgetDataManage.log.info("notifyPushCallback \(ctx.request.widgetID) \(ctx.request.widgetVersion)")
            let bizItem = WidgetBizCacheData(req: ctx.request, rsp: rsp)
            DispatchQueue.main.async {
                ctx.callback([bizItem], nil)
            }
        }
    }

    private func requestMatchResponse(
        request: WidgetBizDataReqContextProtocol,
        response: WidgetBizDataResp
    ) -> Bool {
        if request.widgetID == response.widgetID {
            WidgetDataManage.log.info("requestMatchResponse equal \(response.widgetID)")
            return true
        }
        WidgetDataManage.log.info("requestMatchResponse return false")
        return false
    }

    /// 同步从缓存中取Widget对象
    func getWidgetData(widgetID: String) -> WidgetBizCacheDataProtocol? {
        WidgetDataManage.log.info("WidgetDataManage getWidgetData \(widgetID)")
        return lock.withCriticalSection { () -> WidgetBizCacheDataProtocol? in
            return gadgetCache.getWidgetData(widgetID: widgetID)
        }
    }

    /// 更新Widget业务数据到缓存中
    func updateCache(widgetID: String, data: WidgetBizCacheDataProtocol?) {
        WidgetDataManage.log.info("WidgetDataManage updateCache \(widgetID)")
        lock.withCriticalSection { () -> Void in
            gadgetCache.updateCache(widgetID: widgetID, data: data)
        }
    }

    /// 注册观察Widget业务数据push
    func observeWidgetDataPush(
        req: WidgetBizDataReqContextProtocol,
        callback: @escaping WidgetDataCallBack
    ) -> WidgetDataObserveContext {
        WidgetDataManage.log.info("WidgetDataManage observeWidgetDataPush \(req.widgetID)")
        let pushCtx = WidgetDataObserveContext(
            observeID: "\(Date().timeIntervalSince1970)",
            request: req,
            callback: callback
        )
        lock.withCriticalSection { () -> Void in
            widgetObserverList.append(pushCtx)
        }
        return pushCtx
    }

    /// 移除观察Widget业务数据push
    func removeWidgetDataPushObserver(observeID: String) {
        WidgetDataManage.log.info("WidgetDataManage removeWidgetDataPushObserver \(observeID)")
        lock.withCriticalSection { () -> Void in
            if let index = widgetObserverList.firstIndex(where: {(ctx) -> Bool in
                return ctx.observeID == observeID
            }) {
                widgetObserverList.remove(at: index)
            }
        }
    }

    /// 批量请求Widget业务数据
    func batchRequestWidgetData(
        reqList: [WidgetBizDataReqContextProtocol],
        callback: @escaping WidgetDataCallBack
    ) {
        let resuestWidgets = reqList.map { (widget) -> String in
            return widget.widgetID
        }
        WidgetDataManage.log.info("Widget：Widget \(resuestWidgets) biz data start：\(Date().timeIntervalSince1970)")
        
        let context = WPNetworkContext(injectInfo: .cookie, trace: self.traceService.currentTrace)
        var reqContextArray = [[String: String]]()
        reqList.forEach { item in
            reqContextArray.append([
                "Version": item.widgetVersion,
                "CardID": item.widgetID
            ])
        }
        let params: [String: Any] = [
            "Widgets": reqContextArray
        ].merging(WPGeneralRequestConfig.legacyParameters) { $1 }
        networkService.request(
            WPWidgetBizDataConfig.self,
            params: params,
            context: context
        )
        .observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
        // 闭包过长，注意精简
        // swiftlint:disable closure_body_length
        .subscribe(onSuccess: { (json) in
            let code = json["code"].int ?? WidgetDataManage.defaultHttpResponseCode
            let msg = json["msg"].string ?? WidgetDataManage.defaultHttpMessage
            guard code == 0 else {
                let err = NSError(
                    domain: "request widget Data Error, code != 0",
                    code: code,
                    userInfo: ["msg": msg]
                )
                Self.log.error("Widget：\(resuestWidgets) biz data fail error：", error: err)
                callback([], err)
                return
            }
            guard let rspDataList = json["data"]["WidgetDataList"].array else {
                let err = NSError(
                    domain: "request widget Data Error, no data list \(json.description)",
                    code: code,
                    userInfo: ["msg": msg]
                )
                Self.log.error("Widget：\(resuestWidgets) Widget data failed：", error: err)
                callback([], err)
                return
            }
            /// 构造返回结果
            var rspDataMap = [String: WidgetBizDataRespProtocol]()
            var result = [WidgetBizCacheData]()
            for json in rspDataList {
                /// 先把每个Item的请求响应放在一个Map中，然后我们遍历请求，构造最终的返回结果
                let singleRspItem = WidgetBizDataResp(json: json)
                rspDataMap[singleRspItem.widgetID] = singleRspItem
            }
            /// 我们将每个请求的上下文和响应结果保存，这样方便业务做过滤
            for reqItem in reqList {
                let bizItem = WidgetBizCacheData(
                    req: reqItem,
                    rsp: rspDataMap[reqItem.widgetID]
                )
                result.append(bizItem)
            }
            callback(result, nil)
            Self.log.info("Widget：\(resuestWidgets) request success")
            // swiftlint:enable closure_body_length
        }, onError: { (err) in
            Self.log.error("Widget：Widget data failed", error: err)
            callback([], err)
        }).disposed(by: disposeBag)
    }
}
