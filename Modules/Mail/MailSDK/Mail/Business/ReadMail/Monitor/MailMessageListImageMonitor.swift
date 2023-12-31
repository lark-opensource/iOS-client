//
//  MailMessageListImageMonitor.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2021/9/22.
//

import Foundation

// 图片下载方式
enum MailImageDownloadType: String {
    case driveOrigin // 下载drive原图
    case driveThumb  // 下载drive缩略图
    case rust        // 使用rust接口下载
    case http        // 使用http协议下载
    case cache       // 从缓存加载
    case unknown     // 未知
}

typealias APMErrorInfo = (code: Int, errMsg: String)
/// https://bytedance.feishu.cn/wiki/wikcnVl8ZjWCy0yC92doueapB8c
class MailImageDownloadEvent: Equatable, Hashable {
    enum MailImageEventState: Int {
        case start = 1
        case intercept
        case prepareGetCache
        case prepareDownload
        case startDownload
        case finishDownload
        case sendData
        case onLoad
    }
    // 可感知数据上报事件
    // 可感知事件和Tea事件上报时机保存一致，和android、pc对齐
    let apmEvent = MailAPMEvent.MessageImageLoad()
    private var state = MailImageEventState.start

    let src: String
    /// 1
    private var startTime: Int
    /// 2
    private var interceptTime: Int?
    /// 3
    private var prepareGetCacheTime: Int?
    /// 4
    private var prepareDownloadTime: Int?
    /// 5
    private var startDownloadTime: Int?
    /// 6
    private var finishDownloadTime: Int?
    /// 7
    private var sendDataTime: Int?
    /// 8
    private var onLoadTime: Int?
    /// 开始等待阶段
    private var waitStartStep: Int?

    /// 图片所在邮件是否已读
    var isRead: Bool?
    /// 读信的from
    var come_from: String = ""
    /// 是否通过DriveSDK下载
    var finishWithDrive = false
    /// 下载类型
    var downloadType: MailImageDownloadType = .unknown
    /// mail_status: 成功success 失败包括status_exception, timeout等
    var mail_status: String?
    ///  是否网络图片被拦截后用户手动点击加载图片，只对网络图片有效
    var isBlocked: Bool = false

    var startWaitTime: Int? {
        didSet {
            if startWaitTime != nil {
                waitStartStep = state.rawValue
            }
        }
    }

    var domContentLoadedTime: Int?
    var dataLength: Int?
    var fromCache = false

    static func == (lhs: MailImageDownloadEvent, rhs: MailImageDownloadEvent) -> Bool {
        return lhs.src == rhs.src
    }

    init(src: String) {
        self.src = src
        self.startTime = MailTracker.getCurrentTime()
    }

    func updateState(_ newState: MailImageEventState, timestamp: Int? = nil, isCurrent: Bool = true) {
        guard newState.rawValue > state.rawValue else {
            if let timestamp = timestamp, newState == .start {
                // cid拦截时，需要补上startTime，因为startLoad比intercept慢
                if let interceptTime = interceptTime, interceptTime < timestamp {
                    apmEvent.markPostStart(startDate: Date(timeIntervalSince1970: Double(interceptTime) / 1000))
                    startTime = interceptTime
                } else {
                    startTime = timestamp
                    // 如果startLoad时间早于intercept时间，需要以startLoad时间为准
                    apmEvent.markPostStart(startDate: Date(timeIntervalSince1970: Double(timestamp) / 1000))
                }
                let interceptTime = interceptTime ?? timestamp
                prepareGetCacheTime = ((prepareGetCacheTime ?? 0) < interceptTime) ? nil : prepareGetCacheTime
                prepareDownloadTime = ((prepareDownloadTime ?? 0) < interceptTime) ? nil : prepareDownloadTime
                startDownloadTime = ((startDownloadTime ?? 0) < interceptTime) ? nil : startDownloadTime
                finishDownloadTime = ((finishDownloadTime ?? 0) < interceptTime) ? nil : finishDownloadTime
                sendDataTime = ((sendDataTime ?? 0) < interceptTime) ? nil : sendDataTime
                onLoadTime = ((onLoadTime ?? 0) < interceptTime) ? nil : onLoadTime
                if (startWaitTime ?? 0) < interceptTime {
                    startWaitTime = nil
                    waitStartStep = nil
                }
            }
            return
        }
        let current = timestamp ?? MailTracker.getCurrentTime()

        state = newState
        switch newState {
        case .start:
            break
        case .intercept:
            interceptTime = current
        case .prepareGetCache:
            prepareGetCacheTime = current
        case .prepareDownload:
            prepareDownloadTime = current
        case .startDownload:
            startDownloadTime = current
        case .finishDownload:
            finishDownloadTime = current
        case .sendData:
            sendDataTime = current
        case .onLoad:
            onLoadTime = current
            log(isCurrent: isCurrent)
        }
    }

    func log(isCurrent: Bool) {
        guard let onLoadTime = onLoadTime else {
            MailLogger.error("MailImageDownloadEvent: log before onLoadTime initialized")
            return
        }
        var params = [String: Any]()
        params["intercept"] = interceptTime == nil ? 0 : 1
        let isCached = fromCache ? 1 : 0
        params["cache"] = isCached

        params["download_type"] = downloadType.rawValue
        params["mail_status"] = mail_status ?? ""
        params["mail_account_type"] = Store.settingData.getMailAccountType()
        params["length"] = dataLength ?? 0
        let timeCostMS = onLoadTime - startTime
        params["time_cost_ms"] = timeCostMS
        params["time_js_handle"] = jsHandleTime
        params["time_load_done"] = loadDataTime
        params["time_native_start"] = inQueueTime
        params["time_native_done"] = actualDownloadTime
        params["time_js_render"] = jsRenderTime
        params["time_wait"] = waitTime
        if let waitStartStep = waitStartStep {
            params["start_step"] = waitStartStep
        }
        if let isRead = isRead {
            params["is_read"] = isRead ? 1 : 0
        }
        params["come_from"] = come_from
        params["use_drivesdk"] = finishWithDrive ? 1 : 0
        params["scheme"] = schemeValue
        params["optimize_feat"] = optimizeFeat

        var isValidLog = true
        if let timeWait = params["time_wait"] as? Int, timeWait > timeCostMS {
            // 等待时间大于图片下载时间，打点有问题，排除
            isValidLog = false
            MailLogger.error("MailImageLog waitTime bigger than total time, wait: \(timeWait), total: \(timeCostMS)")
        }

        params["isCurrent"] = isCurrent ? 1 : 0
        params["is_blocked"] = isBlocked ? 1 : 0


        // apmEvent
        apmEvent.endParams.append(MailAPMEvent.MessageImageLoad.EndParam.is_cache(isCached))
        apmEvent.endParams.append(MailAPMEvent.MessageImageLoad.EndParam.download_type(downloadType.rawValue))
        apmEvent.endParams.append(MailAPMEvent.MessageImageLoad.EndParam.resource_content_length(dataLength ?? 0))
        apmEvent.endParams.append(MailAPMEvent.MessageImageLoad.EndParam.upload_ms(actualDownloadTime))
        apmEvent.endParams.append(MailAPMEvent.MessageImageLoad.EndParam.in_queue_time(inQueueTime))
        apmEvent.endParams.append(MailAPMEvent.MessageImageLoad.EndParam.actual_download_time(actualDownloadTime))
        apmEvent.endParams.append(MailAPMEvent.MessageImageLoad.EndParam.scheme(schemeValue))
        apmEvent.endParams.append(MailAPMEvent.MessageImageLoad.EndParam.optimize_feat(optimizeFeat))
        apmEvent.endParams.append(MailAPMEvent.MessageImageLoad.EndParam.is_blocked(isBlocked ? 1 : 0))
        apmEvent.endParams.append(MailAPMEvent.MessageImageLoad.EndParam.is_current(isCurrent ? 1 : 0))
        apmEvent.endParams.append(MailAPMEvent.MessageImageLoad.EndParam.perceptible_wait_time(waitTime))
        if let totalCostTime = self.totalCostTime { // 不为nil才上报
            apmEvent.endParams.append(MailAPMEvent.MessageImageLoad.EndParam.total_cost_time(totalCostTime))
            params["total_cost_time"] = totalCostTime
        }
        apmEvent.endParams.append(MailAPMEventConstant.CommonParam.status_success)

        if isValidLog {
            MailTracker.log(event: "mail_messagelist_image_wait_time_dev", params: params)
            MailLogger.info("mail_messagelist_image_wait_time_dev", extraInfo: params, error: nil, component: nil)
            apmEvent.postEnd()
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(src)
    }

    private var loadDataTime: Int {
        if let sendDataTime = sendDataTime, let interceptTime = interceptTime, sendDataTime - interceptTime >= 0 {
            return sendDataTime - interceptTime
        } else {
            return 0
        }
    }
    private var inQueueTime: Int {
        if let startDownloadTime = startDownloadTime, let interceptTime = interceptTime, startDownloadTime - interceptTime >= 0 {
            return startDownloadTime - interceptTime
        } else {
            return 0
        }
    }

    private var actualDownloadTime: Int {
        if let sendDataTime = sendDataTime, let startDownloadTime = startDownloadTime, sendDataTime - startDownloadTime >= 0 {
            return sendDataTime - startDownloadTime
        } else {
            return 0
        }
    }

    private var schemeValue: String {
        if let scheme = URL(string: src)?.scheme {
            return scheme
        } else {
            return ""
        }
    }

    private var jsHandleTime: Int {
        if let interceptTime = interceptTime, interceptTime - startTime > 0 {
            return interceptTime - startTime
        } else {
            return 0
        }
    }

    private var jsRenderTime: Int {
        if let sendDataTime = sendDataTime, let onLoadTime = onLoadTime, onLoadTime - sendDataTime >= 0 {
            return onLoadTime - sendDataTime
        } else {
            return 0
        }
    }
    private var waitTime: Int {
        if let startWaitTime = startWaitTime, let onLoadTime = onLoadTime, onLoadTime - startWaitTime >= 0 {
            return onLoadTime - startWaitTime
        } else {
            return 0
        }
    }

    private var totalCostTime: Int? {
        if let domStart = domContentLoadedTime, let onLoadTime = onLoadTime, onLoadTime - domStart >= 0 {
            return onLoadTime - domStart
        } else {
            return nil
        }
    }
    private var optimizeFeat: String {
        var feat = ""
        if FeatureManager.open(.loadThumbImageEnable) {
            feat += "imageThumb"
        }
        if FeatureManager.open(.preloadMailImageEnable) {
            feat += "preloadImage"
        }
        if FeatureManager.open(.optimizeImgDownload, openInMailClient: true) {
            feat += "optimizeDownload"
        }
        if FeatureManager.open(.enableImageDownloadQueue, openInMailClient: true) {
            feat += "imageQueue"
        }
        return feat
    }
}

class MailMessageListImageMonitor {

    private var events = Set<MailImageDownloadEvent>()

    func clear() {
        events.removeAll()
        MailLogger.info("MailMessageListImageMonitor clear")
    }

    /// 1. 图片下载开始，创建event并记录开始的时间
    func handleImageStartLoad(src: String, timestamp: Int, isBlocked: Bool, domContentLoadedTime: Int?, isRead: Bool?, from: String) {
        MailLogger.info("handleImageStartLoad isBlocked \(isBlocked), domContentLoadedTime: \(domContentLoadedTime)")
        //这里要判断一下是否是cid？或者取出cid
        if let event = getEvent(with: src, createIfNeed: true) {
            event.isRead = isRead
            event.come_from = from
            event.isBlocked = isBlocked
            event.domContentLoadedTime = domContentLoadedTime
            event.updateState(.start, timestamp: timestamp)
        }
    }
    /// 2. Native拦截图片下载，更新event的拦截时间
    func handleNativeInterceptDownload(src: String) {
        if let event = getEvent(with: src, createIfNeed: true) {
            event.updateState(.intercept)
        }
    }

    /// 3、4. Native拦截图片准备开始下载
    func handleNativePrepareToDownload(src: String, fromCache: Bool) {
        if let event = getEvent(with: src) {
            event.fromCache = fromCache
            if fromCache {
                event.updateState(.prepareGetCache)
            } else {
                event.updateState(.prepareDownload)
            }
        }
    }

    /// 5. Native拦截图片正式开始下载，有progress了
    func handleNativeDownloading(src: String) {
        if let event = getEvent(with: src) {
            event.updateState(.startDownload)
        }
    }

    /// 6. 成功：Native拦截图片完成下载
    func handleNativeFinishDownload(src: String, finishWithDrive: Bool, downloadType: MailImageDownloadType) {
        if let event = getEvent(with: src) {
            event.updateState(.finishDownload)
            event.finishWithDrive = finishWithDrive
            event.downloadType = downloadType
        }
    }

    /// 6. 失败: 图片下载失败
    func handleImageLoadFailed(src: String, finishWithDrive: Bool, downloadType: MailImageDownloadType, errorInfo: APMErrorInfo?) {
        if let event = getEvent(with: src) {
            event.updateState(.finishDownload)
            event.finishWithDrive = finishWithDrive
            event.downloadType = downloadType
            event.mail_status = MailAPMEventConstant.CommonParam.status_exception.value as? String
            event.apmEvent.endParams.append(MailAPMEventConstant.CommonParam.status_exception)
            if let errorInfo = errorInfo {
                event.apmEvent.endParams.appendError(errorCode: errorInfo.code, errorMessage: errorInfo.errMsg)
            }
            event.updateState(.onLoad) // 下载失败的情况下此方法先调用，前端ImageOnError后调用会被忽略
        }
    }

    /// 7. Native数据流形成并回调给JS
    func handleNativeDataSent(src: String, dataLength: Int) {
        if let event = getEvent(with: src) {
            event.updateState(.sendData)
            event.dataLength = dataLength
        }
    }

    /// 8.1 图片下载结束，进行event的打点
    func handleImageOnLoad(src: String, timestamp: Int, isCurrent: Bool) {
        if let event = getEvent(with: src) {
            event.mail_status = MailAPMEventConstant.CommonParam.status_success.value as? String
            event.apmEvent.endParams.append(MailAPMEventConstant.CommonParam.status_success)
            event.updateState(.onLoad, timestamp: timestamp, isCurrent: isCurrent)
        }
    }
    /// 8. 2 图片下载结束渲染失败，进行event的打点
    func handleImageOnError(src: String, timestamp: Int, isCurrent: Bool) {
        if let event = getEvent(with: src) {
            event.mail_status = MailAPMEventConstant.CommonParam.status_render_fail.value as? String
            event.apmEvent.endParams.append(MailAPMEventConstant.CommonParam.status_render_fail)
            event.updateState(.onLoad, timestamp: timestamp, isCurrent: isCurrent)
        }
    }

    /// 图片正在loading且用户在等待，记录下开始等待的时间
    func handleImageLoadingOnScreen(src: String) {
        if let event = getEvent(with: src, createIfNeed: true) {
            event.startWaitTime = MailTracker.getCurrentTime()
            MailLogger.info("handleImageLoadingOnScreen \(event.startWaitTime)")
        }
    }

    private func getEvent(with src: String, createIfNeed: Bool = false) -> MailImageDownloadEvent? {
        let event = events.first(where: { $0.src == src })
        if event == nil && createIfNeed {
            let e = MailImageDownloadEvent(src: src)
            events.insert(e)
            return e
        } else {
            return event
        }
    }

}
