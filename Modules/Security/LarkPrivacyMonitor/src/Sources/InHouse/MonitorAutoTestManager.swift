//
//  MonitorAutoTestManager.swift
//  LarkPrivacyMonitor
//
//  Created by huanzhengjie on 2023/3/4.
//

import UIKit
import TSPrivacyKit
import ShootsAPISocket
import LarkSnCService

private let kStartAutoTestMethod = "startAutoTest"
private let kStopAutoTestMethod = "stopAutoTest"
private let kDataTypeVideo = "video"
private let kDataTypeAudio = "audio"
private let kDataTypeLocation = "location"
private let kStartUpdatingLocation = "startUpdatingLocation"
private let kStopUpdatingLocation = "stopUpdatingLocation"

class MonitorAPIHandler: NSObject, BDIAPIHandler {

    static func routes() -> [BDIRPCRoute] {
        let routes = MonitorAutoTestManager.shared.routes().map {
            BDIRPCRoute.call($0.methodName, respondTarget: self, action: #selector(handleRequest(_:)))
        }
        return routes
    }

    @objc
    static func handleRequest(_ request: BDIRPCRequest) -> BDIRPCResponse {
        let models = MonitorAutoTestManager.shared.routes()
        let targetModel = models.first(where: { $0.methodName == request.method })
        guard let targetModel = targetModel else {
            return BDIRPCResponse(to: request, withResult: ["msg": "Invalid request \(request.reqId)"])
        }
        let result = targetModel.action(targetModel.methodName, request.params)
        return BDIRPCResponse(to: request, withResult: result)
    }

}

/// 开启线下自动化测试、实现与shoots通信、收集敏感api调用信息等
public final class MonitorAutoTestManager: NSObject {

    public static let shared = MonitorAutoTestManager()
    private var caseID: String?
    private var caseName: String?
    private var eventsCache: [TSPKEvent] = []
    private let filterDataTypes = ["network", "snapshot", "local_network", "ip"]
    private var videoAsyncModel: TSPKAPIModel?
    private var videoAsyncEvent: TSPKEvent?
    private var audioAsyncModel: TSPKAPIModel?
    private var audioAsyncEvent: TSPKEvent?
    private var taskIdentifier: UIBackgroundTaskIdentifier?
    private var autoTestStarted: Bool = false
    private lazy var lock: NSLock = {
        NSLock()
    }()

    private override init() {
        super.init()
    }

    public func start() {
        // Monitor 切面监听
        TSPKEventManager.registerSubsciber(self, on: .accessEntryResult)
        TSPKEventManager.registerSubsciber(self, on: .releaseTypeStatus)
        // monitor - shoots 通信
        BDISocketServer.registerAPIHandlers([MonitorAPIHandler.self])
        // location hook stop 相关api
        TSPKMonitor.register(LocationStopPipeline())
        // 后台任务
        addObservers()
    }

    func routes() -> [MonitorSocketReceiveModel] {
        let startModel = MonitorSocketReceiveModel(methodName: kStartAutoTestMethod) { methodName, params in
            return self.handleReceiveMsgWithMethod(methodName: methodName, params: params)
        }
        let stopModel = MonitorSocketReceiveModel(methodName: kStopAutoTestMethod) { methodName, params in
            return self.handleReceiveMsgWithMethod(methodName: methodName, params: params)
        }
        return [startModel, stopModel]
    }

    func handleReceiveMsgWithMethod(methodName: String, params: [AnyHashable: Any]) -> [AnyHashable: Any] {

        let caseID = (params["case_id"] as? String) ?? "default_case_id"
        let caseName = params["case_name"] as? String ?? "default_case_name"

        if methodName == kStartAutoTestMethod {
            startAutoTest(caseID: caseID, caseName: caseName)
            return ["result": true]
        } else if methodName == kStopAutoTestMethod {
            stopAutoTest(caseID: caseID, caseName: caseName)
            return ["result": true]
        }
        return ["result": false]
    }

    /// 开启自动化测试case
    func startAutoTest(caseID: String, caseName: String) {
        // 保存状态
        self.caseID = caseID
        self.caseName = caseName
        autoTestStarted = true
        clearEventsCache()
    }

    /// 结束自动化测试case
    func stopAutoTest(caseID: String, caseName: String) {
        let delayTime = checkAudioVideoCallAsync() ? 3 : 1

        // 回传调用日志
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delayTime)) { [weak self] in
            self?.autoTestStarted = false
            let result = self?.collectAPICallInfo()
            guard let jsonStr = result?.toJsonString() else {
                return
            }
            BDISocketServer.pushMessage(jsonStr)
        }
    }

    /// 音视频敏感API配对调用监测
    func checkAudioVideoCallAsync() -> Bool {
        lock.lock()
        guard !eventsCache.isEmpty else {
            lock.unlock()
            return false
        }
        var hasAsyncTask = false
        var hasVideoAsyncTask = false
        var hasAudioAsyncTask = false
        for event in eventsCache {
            guard let apiModel = event.eventData?.apiModel else {
                continue
            }
            guard let dataType = apiModel.dataType else {
                continue
            }
            guard let pipelineType = apiModel.pipelineType else {
                continue
            }
            if filterDataTypes.contains(dataType) {
                continue
            }

            let isStart = apiModel.apiUsageType == .start
            guard isStart else {
                continue
            }

            let isReleaseEvent = (dataType == kDataTypeVideo || dataType == kDataTypeAudio)
            guard isReleaseEvent else {
                continue
            }
            if dataType == kDataTypeVideo {
                if hasVideoAsyncTask {
                    continue
                }
                hasVideoAsyncTask = true
                videoAsyncModel = apiModel
                videoAsyncEvent = event
            } else {
                if hasAudioAsyncTask {
                    continue
                }
                hasAudioAsyncTask = true
                audioAsyncModel = apiModel
                audioAsyncEvent = event
            }

            let planModel = TSPKDetectPlanModel()
            planModel.taskType = .detectReleaseStatus
            planModel.interestMethodType = pipelineType
            planModel.dataType = apiModel.dataType

            let detectEvent = TSPKDetectEvent()
            detectEvent.detectPlanModel = planModel

            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                TSPKDetectManager.shared()?.handle(detectEvent)
            }
            hasAsyncTask = true
        }
        lock.unlock()
        return hasAsyncTask
    }

}

/// api call data processing
extension MonitorAutoTestManager {

    /// 收集敏感API调用信息
    func collectAPICallInfo() -> [String: Any] {
        var result = [String: Any]()
        var apiResults = [[String: Any]]()
        var videoPairResults = [[String: Any]]()
        var audioPairResults = [[String: Any]]()
        var locationPairResults = [[String: Any]]()
        var locationApiResult = [String: Any]()
        var hasLocationStart = false
        var hasLocationStop = false
        lock.lock()
        for event in eventsCache {
            guard let apiModel = event.eventData?.apiModel else {
                continue
            }
            guard let dataType = apiModel.dataType else {
                continue
            }
            var time = ""
            if let timeInterval = event.eventData?.unixTimestamp {
                time = timeInterval.convertToTimeStr()
            }

            if event.eventType == .accessEntryResult {
                var apiResult = [String: Any]()
                apiResult["api_name"] = apiModel.apiMethod
                apiResult["data_type"] = apiModel.dataType
                apiResult["top_page"] = event.eventData?.topPageName
                apiResult["class_name"] = apiModel.apiClass
                apiResult["app_status"] = event.eventData?.appStatus
                apiResult["time"] = time
                apiResults.append(apiResult)
                if dataType == kDataTypeLocation,
                    let apiMethod = apiModel.apiMethod {
                    if apiMethod == kStartUpdatingLocation {
                        hasLocationStart = true
                        hasLocationStop = !hasLocationStart
                        locationApiResult = apiResult
                    } else if apiMethod == kStopUpdatingLocation {
                        hasLocationStop = true
                    }
                }
            } else if event.eventType == .releaseTypeStatus {
                if event.eventData?.isReleased ?? false {
                    continue
                }
                if dataType == kDataTypeVideo {
                    var videoApiResult = [String: Any]()
                    videoApiResult["api_name"] = videoAsyncModel?.apiMethod
                    videoApiResult["data_type"] = videoAsyncModel?.dataType
                    videoApiResult["class_name"] = videoAsyncModel?.apiClass
                    videoApiResult["top_page"] = videoAsyncEvent?.eventData?.topPageName
                    videoApiResult["app_status"] = videoAsyncEvent?.eventData?.appStatus
                    videoApiResult["time"] = time
                    videoPairResults.append(videoApiResult)
                } else if dataType == kDataTypeAudio {
                    var audioApiResult = [String: Any]()
                    audioApiResult["api_name"] = audioAsyncModel?.apiMethod
                    audioApiResult["data_type"] = audioAsyncModel?.dataType
                    audioApiResult["class_name"] = audioAsyncModel?.apiClass
                    audioApiResult["top_page"] = audioAsyncEvent?.eventData?.topPageName
                    audioApiResult["app_status"] = audioAsyncEvent?.eventData?.appStatus
                    audioApiResult["time"] = time
                    audioPairResults.append(audioApiResult)
                }
            }
        }
        lock.unlock()
        result["api_call_result"] = apiResults
        result["camera_pair_result"] = videoPairResults
        result["audio_pair_result"] = audioPairResults
        if hasLocationStart && !hasLocationStop {
            locationPairResults.append(locationApiResult)
        }
        result["location_pair_result"] = locationPairResults
        result["case_id"] = caseID
        result["case_name"] = caseName

        return result
    }

    /// 清理缓存
    func clearEventsCache() {
        lock.lock()
        eventsCache.removeAll()
        videoAsyncModel = nil
        videoAsyncEvent = nil
        audioAsyncModel = nil
        audioAsyncEvent = nil
        lock.unlock()
    }
}

/// observers
extension MonitorAutoTestManager {

    /// 注册事件
    private func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }

    @objc
    private func applicationDidEnterBackground(notification: NSNotification) {
        if let taskIdentifier = self.taskIdentifier {
            UIApplication.shared.endBackgroundTask(taskIdentifier)
        }
        // 添加后台任务，避免退到后台通信中断
        taskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "MonitorAutoTestManager") { [weak self] in
            if let taskIdentifier = self?.taskIdentifier {
                UIApplication.shared.endBackgroundTask(taskIdentifier)
            }
        }
    }
}

/// 敏感API调用切面，收集调用信息。
extension MonitorAutoTestManager: TSPKSubscriber {

    public func uniqueId() -> String {
        return "MonitorAutoTestManager-Subscriber"
    }

    public func canHandelEvent(_ event: TSPKEvent) -> Bool {
        return autoTestStarted
    }

    public func hanleEvent(_ event: TSPKEvent) -> TSPKHandleResult? {
        guard let apiModel = event.eventData?.apiModel else {
            return nil
        }
        guard let dataType = apiModel.dataType else {
            return nil
        }
        if filterDataTypes.contains(dataType) {
            return nil
        }
        lock.lock()
        eventsCache.append(event)
        lock.unlock()
        return nil
    }
}

/// extension utils

extension Double {

    // 时间戳转成字符串
    func convertToTimeStr() -> String {
        let date: Date = Date(timeIntervalSince1970: self)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date as Date)
    }
}
