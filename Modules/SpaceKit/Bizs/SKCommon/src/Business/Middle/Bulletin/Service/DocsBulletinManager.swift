//
//  DocsBulletinManager.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/3/11.
//  swiftlint:disable file_length

import SwiftyJSON
import Foundation
import LarkReleaseConfig
import SKFoundation
import SKInfra

public protocol DocsBulletinResponser: AnyObject {
    /// 标记本页面能够handle的公告类型("docs", "sheet", etc...)
    func canHandle(_ type: [String]) -> Bool
    /// 展示公告，每次只会展示一个公告，所以当前页面如果有未关闭的公告，需要进行覆盖。
    func bulletinShouldShow(_ info: BulletinInfo)
    /// 关闭指定公告，若为nil则关闭任何公告
    func bulletinShouldClose(_ info: BulletinInfo?)
}

public protocol DocsBulletinDBBridge: AnyObject {
    func clear()
    func reloadData()
}


public enum DocsBulletinTrackEvent {
    case view(bulletin: BulletinInfo) //公告展示
    case close(bulletin: BulletinInfo) //公告关闭
    case openLink(bulletin: BulletinInfo) //点击公告链接，如果没有链接不会触发。
}

/// 负责Docs公告逻辑，包括离线/在线公告拉取、定时公告、关闭及失败重试等逻辑
public final class DocsBulletinManager: NSObject {
    // MARK: Configuration
    /// 关闭公告请求失败后重试频率，当前每1分钟重试一次
    private(set) var retryInterval: TimeInterval = 1 * 60 // 1 Min

    // MARK: Data
    private var dbReadyToUse: Bool = false
    private var observers: [WeakObserver] = []
    private var current: BulletinInfo?
    private var bulletins: [BulletinInfo] = []
    private var shouldCloseIds: Set<String> = []
    private var _getRequest: DocsRequest<JSON>?
    private var _closeRequest: DocsRequest<JSON>?

    // MARK: Tool
    private var _nextActionTimer: Timer?
    private var _retryTimer: Timer?
    private var hasRegistered: Bool = false

    override init() {
        super.init()
        startListeningNotification()
    }

    deinit {
        _nextActionTimer?.invalidate()
        _retryTimer?.invalidate()
        stopListeningNotification()
    }

    // MARK: External Interface
    /// 注册成为公告板观察者，只保留弱引用
    public func addObserver(_ observer: DocsBulletinResponser) {
        observers.append(WeakObserver(observer))
        observers.checkout()
    }

    /// 取消注册公告板观察者
    public func removeObserver(_ observer: DocsBulletinResponser) {
        guard let idx = observers.firstIndex(where: {
            guard let obv = $0.observer else { return false }
            return obv === observer
        }) else { return }
        observers.remove(at: idx)
        observers.checkout()
    }
    
    
    /// 公告埋点
    /// - Parameters:
    ///   - event: 公告买点事件
    ///   - commonParams: 各个挂载公告对应的公参。Space 公参，CCM 公参
    public func track(_ event: DocsBulletinTrackEvent, commonParams: [String: Any]) {
        switch event {
        case .close(let bulletin):
            var params: [String: Any] = [
                "location": "ios_lark",
                "announcement_id": bulletin.id,
                "click": "close"
            ]
            params.merge(other: commonParams)
            DocsTracker.newLog(enumEvent: .announcementClick, parameters: params)
        case .openLink(let bulletin):
            var params: [String: Any] = [
                "location": "ios_lark",
                "announcement_id": bulletin.id,
                "click": "open",
                "target": "none"
            ]
            params.merge(other: commonParams)
            DocsTracker.newLog(enumEvent: .announcementClick, parameters: params)
        case .view(let bulletin):
            var params: [String: Any] = [
                "location": "ios_lark",
                "announcement_id": bulletin.id
            ]
            params.merge(other: commonParams)
            DocsTracker.newLog(enumEvent: .announcementView, parameters: params)
        }
    }

    /// 显示公告，原则上公告栏只显示数据库(离线)/后端(在线)数据，如有特殊需求可以在此手动显示
//    public func showBulletin(_ info: BulletinInfo) {
//        _showBulletin(info)
//    }

    /// 关闭指定公告，若为nil则关闭任何公告
//    public func closeBulletin(_ info: BulletinInfo?) {
//        if let info = info, info.id == current?.id {
//            _closeBulletin(info, byUser: true)
//        } else if info == nil {
//            _closeBulletin(nil, byUser: true)
//        }
//    }
}

// MARK: Internal supporting method
extension DocsBulletinManager {
    // MARK: Executable Method
    private func _showBulletin(_ info: BulletinInfo) {
        // Update Model
        current = info
        // Dispatch Action
        DocsLogger.info("_showBulletin id:  \(info.id)", component: LogComponents.blletinManager)
        observerDispatcher { observers in
            for observer in observers where observer.canHandle(info.products) {
                observer.bulletinShouldShow(info)
            }
        }
        observers.checkout()
    }

    /// 关闭公告栏并决定是否上报后端(若为用户操作则上报)
    private func _closeBulletin(_ info: BulletinInfo?, byUser: Bool) {
        // Update Model
        guard let _current = current else { return }
        DocsLogger.info("_closeBulletin id:  \(_current.id) ", component: LogComponents.blletinManager)
        self.current = nil
        // Dispatch Action
        observerDispatcher { observers in
            for observer in observers {
                observer.bulletinShouldClose(info)
            }
        }
        observers.checkout()
        /// 如果是用户手动触发，需要上报服务端，且需要将当前从缓存中移除，
        if byUser {
            shouldCloseIds.insert(_current.id)
            _retryTimer?.invalidate()
            DispatchQueue.main.async {
                self._retryTimer = Timer(timeInterval: self.retryInterval, repeats: true, block: { [weak self] _ in
                    self?.shouldCloseIds.forEach {
                        self?.requestCloseBulletin($0, completion: nil)
                    }
                }).addToRunloop(.default).go()
            }
            self.removeBulletinBySync(_current)
        }
    }

    private func enableRegulerRequest() {
        DispatchQueue.main.async {
            self.requestGetBulletin(completion: nil)
        }
    }

    // MARK: Tool Method
    private func observerDispatcher(_ dispatchAction: (([DocsBulletinResponser]) -> Void)) {
        let realObservers = self.observers.compactMap { return $0.observer }
        dispatchAction(realObservers)
    }
    /** 获取跟RN通信用的opKey，目前有如下几种， 适配了ka用户，适配了单品
     "BULLETIN_ios_lark_cn"
     "BULLETIN_ios_lark_va"
     "BULLETIN_ios_lark_kalark"
     "BULLETIN_ios_lark_ka2lark"
     "BULLETIN_ios_larkdocs_cn"
     "BULLETIN_ios_larkdocs_va"
     
     如果是在 boe 环境中，unitID 要变为 boecn，例如 "BULLETIN_ios_lark_boecn"
     当在 boe 环境链接不上 RN 的时候，根据 unitID 定位一下。
     */
    private func getPushInfo() -> SKPushInfo {
        let unitID: String = DomainConfig.unitIDForBulletin
        var appName: String = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? "lark"
        appName = appName.lowercased()
        let operationKey = StablePushPrefix.bulletin.rawValue + "ios_\(appName)_\(unitID)"
        DocsLogger.info("get operationKey \(operationKey)", component: LogComponents.blletinManager)
        let pushInfo = SKPushInfo(tag: operationKey,
                                  resourceType: StablePushPrefix.bulletin.resourceType(),
                                  routeKey: unitID,
                                  routeType: SKPushRouteType.unit)
        return pushInfo
    }
    
    private func startListeningNotification() {
        RNManager.manager.registerRnEvent(eventNames: [.base], handler: self)

        NotificationCenter.default.addObserver(self, selector: #selector(bulletinOpenLink(notification:)),
                                               name: DocsBulletinManager.bulletinOpenLinkNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(bulletinClose(notification:)),
                                               name: DocsBulletinManager.bulletinCloseNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(bulletinRequestShow(notification:)),
                                               name: DocsBulletinManager.bulletinRequestShowIfNeeded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(bulletinRequestRefresh(notification:)),
                                               name: DocsBulletinManager.bulletinRequestRefresh, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(bulletinRegisterRN(notification:)),
                                               name: Notification.Name.Docs.docsTabDidAppear, object: nil)
    }
    
    public func registerRN() {
        if !hasRegistered {
            sendToRN(pushInfo: getPushInfo())
        }
    }
    
    ///向RN注册监听Event:operationKey
    func sendToRN(bodyData: [String: Any]? = nil, pushInfo: SKPushInfo) {
        var body = [String: Any]()
        body["type"] = "registerList"
        body["tag"] = pushInfo.tag
        body["route_key"] = pushInfo.routeKey
        body["route_type"] = pushInfo.routeType.rawValue
        body["resource_type"] = pushInfo.resourceType
        body["serviceType"] = pushInfo.tag

        let data: [String: Any] = ["operation": "pushList",
                                   "body": body]
        let composedData: [String: Any] = ["business": "base",
                                           "data": data]
        RNManager.manager.sendSpaceBusnessToRN(data: composedData)
        self.hasRegistered = true
    }

    private func stopListeningNotification() {
        NotificationCenter.default.removeObserver(self, name: DocsBulletinManager.bulletinOpenLinkNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: DocsBulletinManager.bulletinCloseNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: DocsBulletinManager.bulletinRequestShowIfNeeded, object: nil)
        NotificationCenter.default.removeObserver(self, name: DocsBulletinManager.bulletinRequestRefresh, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.Docs.docsTabDidAppear, object: nil)
    }

    @objc
    private func bulletinClose(notification: Notification) {
        guard let id = notification.userInfo?["id"] as? String else { return }
        if let current = current, current.id == id {
            _closeBulletin(current, byUser: true)
        }
    }

    @objc
    private func bulletinOpenLink(notification: Notification) {
        // 点击公告栏链接进入的Docs页面不应显示公告栏，此逻辑由BrowserView自行处理
    }

    @objc
    private func bulletinRequestShow(notification: Notification) {
        guard let obj = notification.object as? DocsBulletinResponser else { return }
        if let current = current, obj.canHandle(current.products) {
            obj.bulletinShouldShow(current)
        }
    }

    @objc
    private func bulletinRequestRefresh(notification: Notification) {
        requestGetBulletin(completion: nil)
    }
    
    @objc
    private func bulletinRegisterRN(notification: Notification) {
        registerRN()
    }
}

// MARK: Network supporting method
extension DocsBulletinManager {
    private func updateBulletinStatus(_ id: String, bulletInfo: BulletinInfo, completion: ((_ error: Error?) -> Void)?) {
        let params: [String: Any] = ["id": id]
        _getRequest?.cancel()
        _getRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.bulletinUpdateStatus, params: params)
            .set(method: .GET).start(result: { [weak self] json, error in
                guard let `self` = self else {
                    completion?(nil); return
                }
                guard (error as? URLError)?.errorCode != NSURLErrorCancelled else {
                    completion?(nil); return
                }
                guard error == nil else {
                    DocsLogger.error("Bulletin request error", error: error, component: LogComponents.blletinManager)
                    completion?(error); return
                }
                if let dataDic = json?["data"] {
                    let isClose = dataDic["close"].bool
                    if isClose == false {
                        ///后台返回了没有关闭公告栏，即需要update 公告栏信息进行展示
                        self.updateBulletinBySync(bulletInfo)
                    } else {
                        self.removeBulletinBySync(bulletInfo)
                    }
                }
                completion?(nil)
            })
    }
    ///Comment: zsy 这里拿到了所有的公告，不太合理，这里应该可以根据当前日期进行筛选返回吧。貌似没根据版本来筛选。
    private func requestGetBulletin(completion: ((_ error: Error?) -> Void)?) {
        _getRequest?.cancel()
        _getRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.bulletinGet, params: ["no_cache": "true"])
            .set(method: .GET)
            .start(result: { [weak self] json, error in
                guard let `self` = self else {
                    completion?(nil); return
                }
                guard (error as? URLError)?.errorCode != NSURLErrorCancelled else {
                    completion?(nil); return
                }
                guard error == nil else {
                    DocsLogger.error("Bulletin request error", error: error, component: LogComponents.blletinManager)
                    completion?(error); return
                }
                if let json = json {
                    let infos = self.decodeBulletinJSON(json)
                    self.didUpdateBulletins(infos)
                    DocsLogger.info("requestGetBulletin success", component: LogComponents.blletinManager)
                }
                completion?(nil)
            })
    }

    @inline(__always)
    private func decodeBulletinJSON(_ json: JSON) -> [BulletinInfo] {
        if let bulletins = json["data"]["bulletins"].dictionary {
            return bulletins.compactMap {
                let id = $0.key
                let value = $0.value
                if let startTime = value["start_time"].int,
                    let endTime = value["end_time"].int,
                    let content = value["content"].dictionaryObject as? [String: String],
                    let products = value["products"].arrayObject as? [String] {
                    return BulletinInfo(id: id, content: content, startTime: startTime, endTime: endTime, products: products)
                }
                return nil
            }
        }
        return []
    }
    ///v3.12改版，后台新增协议格式
    @inline(__always)
    private func decodeBulletinJSON2(_ json: JSON) -> BulletinInfo? {
        if  let id = json["id"].string,
            let startTime = json["start_time"].int,
            let endTime = json["end_time"].int,
            let content = json["content"].dictionaryObject as? [String: String],
            let products = json["products"].arrayObject as? [String] {
            let versionArr = json["version"].arrayObject

            guard let versions = versionArr, versions.count > 0,
                let version = versions[0] as? [String: String] else {
                return BulletinInfo(id: id, content: content, startTime: startTime, endTime: endTime, products: products)
            }
            return BulletinInfo(id: id, content: content, startTime: startTime, endTime: endTime, products: products, version: version)
        }
        return nil
    }

    /// 拿到新数据更新公告
    private func didUpdateBulletins(_ infos: [BulletinInfo]) {
    
        let ts = Date().timeIntervalSince1970
        /// 1.过滤出还未结束的公告
        let workedInfos = infos.filter { return $0.endTime > Int(ts) }
//                .filter { return !shouldCloseIds.contains($0.id) }
                .sorted { return $0.startTime < $1.startTime }
        
        /// 2. 找出已开启未结束，且开启时间距离当前时间最近的公告
        if let showingBulletin = current {
            _closeBulletin(showingBulletin, byUser: false)
        }
        if let bulletinToShow = workedInfos.last(where: { $0.startTime <= Int(ts) }) {
            _showBulletin(bulletinToShow)
        }
        
        /// 3. 计算下个定时器的开启时间，用于下一个展示的公告。
        var nxtActionTs: Int = Int.max
        if let showingBulletin = current {
            nxtActionTs = showingBulletin.endTime
            if let nextWorkedInfo = workedInfos.first(where: { $0.id != showingBulletin.id && $0.startTime > showingBulletin.startTime && $0.startTime < showingBulletin.endTime }) {
                nxtActionTs = nextWorkedInfo.startTime
            }
        } else {
            nxtActionTs = workedInfos.first?.startTime ?? Int.max
        }
        /// 4. 开启下一个任务定时器
        self._nextActionTimer?.invalidate()
        self._nextActionTimer = nil
        if nxtActionTs != Int.max {
            let nxtActionDate = Date(timeIntervalSince1970: TimeInterval(nxtActionTs))
            DispatchQueue.main.async {
                self._nextActionTimer = Timer(fire: nxtActionDate, interval: 0, repeats: false, block: { [weak self] _ in
                    self?.shouldBeginNextAction()
                }).addToRunloop(.default)
            }
        }
        self.bulletins = workedInfos
    }
    
    /// 移除公告
    private func removeBulletinBySync(_ info: BulletinInfo) {
        let updatedBulletins = self.bulletins.filter { $0.id != info.id }
        shouldBeginNextAction(with: updatedBulletins)
    }
    
    /// 添加公告
    private func updateBulletinBySync(_ info: BulletinInfo) {
        var updatedBulletins = self.bulletins.filter { $0.id != info.id }
        updatedBulletins.append(info)
        shouldBeginNextAction(with: updatedBulletins)
    }
    
    /// 开启一轮展示询问
    private func shouldBeginNextAction(with bulletins: [BulletinInfo]? = nil) {
        let nextBulletins = bulletins ?? self.bulletins
        didUpdateBulletins(nextBulletins)
    }

    private func requestCloseBulletin(_ id: String, completion: ((_ error: Error?) -> Void)?) {
        let params: [String: Any] = ["id": id]
        _closeRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.bulletinClose, params: params)
            .set(method: .POST)
            .start(result: { [weak self] _, error in
                guard let `self` = self else { return }
                guard (error as? URLError)?.errorCode != NSURLErrorCancelled else {
                    completion?(nil)
                    return
                }
                guard error == nil else {
                    completion?(error)
                    return
                }
                self.didCloseBulletins(id)
                completion?(nil)
            })
    }

    private func didCloseBulletins(_ id: String) {
        shouldCloseIds.remove(id)
        if shouldCloseIds.isEmpty {
            _retryTimer?.invalidate()
            _retryTimer = nil
        }
    }
}

// MARK: DataCenter commication Protocol
extension DocsBulletinManager: DocsBulletinDBBridge {
    public func clear() {
        execOnMain { [weak self] in
            guard let self = self else { return }
            self.bulletins = []
        }
    }

    public func reloadData() {
        self.execOnMain { [weak self] in
            guard let self = self else { return }
            self.enableRegulerRequest()
        }
    }

    /// Execute task on main queue
    @inline(__always)
    private func execOnMain(_ task: @escaping () -> Void) {
        DispatchQueue.main.async {
            task()
        }
    }
}

// MARK: Observer weak reference helper
private class WeakObserver {
    weak var observer: DocsBulletinResponser?
    init(_ observer: DocsBulletinResponser) {
        self.observer = observer
    }
}

// MARK: Helper Extension
private extension Array where Element: WeakObserver {
    mutating func checkout() {
        self = self.filter { $0.observer != nil }
    }
}

private extension Timer {
    func addToRunloop(_ mode: RunLoop.Mode) -> Timer {
        RunLoop.current.add(self, forMode: mode)
        return self
    }

    func go() -> Timer {
        fire()
        return self
    }
}

extension DocsBulletinManager {
    public static let encoder: JSONEncoder = JSONEncoder()
    public static let decoder: JSONDecoder = JSONDecoder()
    /// 关闭公告牌通知。参数表：userInfo["id": 公告id]
    public static let bulletinCloseNotification: Notification.Name = Notification.Name(rawValue: "com.feishu.docs.bulletinClose")
    /// 打开公告牌链接通知。参数表: userInfo["id": 公告id]
    public static let bulletinOpenLinkNotification: Notification.Name = Notification.Name(rawValue: "com.feishu.docs.bulletinOpenLink")
    /// 获取被告知当前是否要显示公告牌。参数表: obj: 请求对象
    public static let bulletinRequestShowIfNeeded: Notification.Name = Notification.Name(rawValue: "com.feishu.docs.bulletinRequestShow")
    /// 希望刷新公告栏，不受限制，根据各自需求(如下拉刷新、返回页面时触发)决定。默认会每10分钟拉取一次。
    public static let bulletinRequestRefresh: Notification.Name = Notification.Name(rawValue: "com.feishu.docs.bulletinRequestRefresh")
}

extension DocsBulletinManager: RNMessageDelegate {
    ///收到RN的回调，开始处理数据
    public func didReceivedRNData(data: [String: Any], eventName: RNManager.RNEventName) {
        guard let operation = data["operation"] as? String,
            let body = data["body"] as? [String: Any] else {
                    spaceAssertionFailure("DocsBulletinManager no operation in data")
                    return
        }
        if operation != getPushInfo().tag {
            return
        }
        DocsLogger.debug("DocsBulletinManager receive,operationType is:\(operation), data is: \(data)", component: LogComponents.dataModel)
        guard let jsonStr = body["data"] as? String else {
            DocsLogger.info("DocsBulletinManager receive, format not ok", component: LogComponents.dataModel)
            return
        }
        let json = JSON(parseJSON: jsonStr)
        guard let id = json["id"].string,
            let bulletInfo = self.decodeBulletinJSON2(json) else { return }
        let status = json["status"].int
        let version: [String: String] = bulletInfo.version
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        ///判断当前app版本是否在公告栏版本列表
        guard let startVer = version["start"],
              let endVer = version["end"],
            compareVersion(appVersion, startVer) != -1,
            compareVersion(appVersion, endVer) != 1 else { return }
        ///status：0是打开公告栏，1是关闭公告栏
    
        DocsLogger.debug("didReceivedRNData need handle status: \(status) bulletinId: \(bulletInfo.id)", component: LogComponents.blletinManager)
        if status == 0 {
            self.updateBulletinStatus(id, bulletInfo: bulletInfo, completion: nil)
        } else if status == 1 {
            self.removeBulletinBySync(bulletInfo)
        }
    }

    ///v1>v2 return 1,v1<v2 return -1 其他返回0
    func compareVersion(_ version1: String, _ version2: String) -> Int {
        var numbers1 = version1.split(separator: ".").compactMap { Int(String($0)) }
        var numbers2 = version2.split(separator: ".").compactMap { Int(String($0)) }
        let numDiff = numbers1.count - numbers2.count

        if numDiff < 0 {
            numbers1.append(contentsOf: Array(repeating: 0, count: -numDiff))
        } else if numDiff > 0 {
            numbers2.append(contentsOf: Array(repeating: 0, count: numDiff))
        }

        for i in 0..<numbers1.count {
            let diff = numbers1[i] - numbers2[i]
            if diff != 0 {
                return diff < 0 ? -1 : 1
            }
        }
        return 0
    }
}
