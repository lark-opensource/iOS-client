//
//  GeckoPackageManager+analysis.swift
//  SpaceKit
//
//  Created by Webster on 2020/4/13.
//

import SKFoundation

public enum FEPkgManageBadCaseCode: Int {
    case notHaveAnyPkg = 1
    case filePathPlistWriteFail = 2
    case createItemFail = 3
    case removeItemFail = 4
    case moveItemFail = 5
    case unzipAbnormal = 6 // 资源包解压使用异常
}

extension GeckoPackageManager {
    
    private var currentChannel: DocsChannelInfo {
        (.webInfo,
         GeckoPackageManager.shared.currentUsingAppChannel.rawValue,
         "SKResource.framework/SKResource.bundle/eesz-zip",
         GeckoPackageManager.shared.bundleSlimPkgName)
    }
    
    func logZipFirstUnzipStatus(_ success: Bool, channel: String) {
        let params = ["status": success ? "1" : "0",
                      "channel": channel]
        DocsTracker.log(enumEvent: DocsTracker.InnerEventType.offlineResFirstUnzipStatus, parameters: params)
    }
    func logZipRetryUnzipStatus(_ success: Bool, time: Int, channel: String) {
        let params = ["status": success ? "1" : "0",
                      "retryTime": String(time),
                      "channel": channel]
        DocsTracker.log(enumEvent: DocsTracker.InnerEventType.offlineResRetryUnzipStatus, parameters: params)
    }
    func logZipRetryUnzipFail(_ reason: String, isUseingSSZip: Bool) {
        let params = [
            "reason": reason,
            "lib_type": isUseingSSZip ? "ssziparchive" : "libarchivekit"
        ]
        
        DocsTracker.log(enumEvent: DocsTracker.InnerEventType.offlineResUnzipFailReason, parameters: params)
    }
    func logDownloadFullPkgTime(durationMS: Double, isSuccess: Bool, errorMsg: String = "", retryCount: Int, downloader: String) {
        let params: [String: Any] = ["duration_ms": durationMS,
                                     "is_success": isSuccess ? "yes" : "no",
                                     "errorMsg": errorMsg,
                                     "downloader": downloader,
                                     "retry_count": retryCount,
                                      DocsTracker.Params.docNetStatus: DocsNetStateMonitor.shared.accessType.intForStatistics]
        DocsTracker.log(enumEvent: DocsTracker.EventType.fullPackageDownloadDuration, parameters: params)
        DocsLogger.info("完整包下载耗时埋点统计触发，event:\(DocsTracker.EventType.fullPackageDownloadDuration)", extraInfo: params, component: LogComponents.fePackgeDownload)
    }
    public func logBadCase(code: FEPkgManageBadCaseCode, msg: String) {
        let params: [String: Any] = ["code": code.rawValue,
                                     "msg": msg]
        DocsTracker.log(enumEvent: DocsTracker.EventType.fePkgManageBadCase, parameters: params)
    }
    
    private enum BundlePkgUnzipResult: Int {
        case success = 0
        case failure = -1
    }
    
    private var bundleSlimPkgFormat: String {
        return BundlePackageExtractor.currentFormat?.fileExtension ?? ""
    }
    
    /// 上报解压成功
    func trackUnzipSuccessEvent(duration: Double, localPath: String) {
        
        let zipInfo = OfflineResourceZipInfo.info(by: currentChannel)
        let versionInfo = Self.Folder.getCurentVersionInfo(in: zipInfo.zipFileBaseFolder)
        
        let params: [String: Any] = ["result": BundlePkgUnzipResult.success.rawValue.description,
                                     "during": duration * 1000, // millisecond
                                     "format": bundleSlimPkgFormat,
                                     "localpath": localPath,
                                     "channel": currentChannel.name,
                                     "package_version": versionInfo.version]
        DocsTracker.newLog(enumEvent: .bundleSlimPkgExtract, parameters: params)
    }
    
    /// 上报解压失败
    func trackUnzipFailureEvent(duration: Double, localPath: String, errorDesc: String?) {
        
        let zipInfo = OfflineResourceZipInfo.info(by: currentChannel)
        let versionInfo = Self.Folder.getCurentVersionInfo(in: zipInfo.zipFileBaseFolder)
        
        var params: [String: Any] = ["result": BundlePkgUnzipResult.failure.rawValue.description,
                                     "during": duration * 1000, // millisecond
                                     "format": bundleSlimPkgFormat,
                                     "localpath": localPath,
                                     "channel": currentChannel.name,
                                     "package_version": versionInfo.version]
        if let desc = errorDesc {
            params["error_des"] = desc
        }
        DocsTracker.newLog(enumEvent: .bundleSlimPkgExtract, parameters: params)
    }
    
    // 开始倒计时，15s后检查完整包并上报结果
    func startTrackFullPkgDownloadResult(slimVersion: String?) {
        let countdown = 15
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(countdown)) {
            guard let info = self.locatorMapping.value(ofKey: .webInfo) else {
                GeckoLogger.error("locatorMapping get nil, when track FullPkgDownloadResult")
                return
            }
            let hasFullPkg = !info.isSlim
            let downloader = UserScopeNoChangeFG.HZK.disableGeckoDownloadFullPkg ? "rust" : "gecko"
            var params: [String: Any] = [
                "downloader": downloader,
                "has_full_pkg": hasFullPkg,
                "limit": countdown
            ]
            if let slimVersion = slimVersion {
                params["slim_res_version"] = slimVersion
            }
            DocsTracker.newLog(enumEvent: .fullPackageDownloadResultDev, parameters: params)
        }
    }
}
