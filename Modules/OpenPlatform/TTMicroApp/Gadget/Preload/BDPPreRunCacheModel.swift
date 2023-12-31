//
//  BDPPreRunCacheModel.swift
//  TTMicroApp
//
//  Created by ChenMengqi on 2022/11/21.
//

import Foundation
import OPSDK
import LKCommonsLogging

/// PreRun预载缓存对象. 目前只会缓存小程序
@objcMembers
public final class BDPPreRunCacheModel: NSObject {
    /// 是否命中过缓存(只要有一个缓存在启动时被命中使用, 这个就会标记成true)
    public private(set) var hitCache = false

    /// 开始prerun预载时间
    public private(set) var startTime: CFTimeInterval = 0

    public private(set) var monitor = OPMonitor(String.monitorEventName)

    /// 应用id
    public let appID: String

    /// 根据应用id构建的UniqueID
    public let uniqueID: OPAppUniqueID

    /// prerun过来的场景值
    public let prerunScene: [Int]

    /// prerun预载的meta信息
    public private(set) var cachedMeta: GadgetMeta?

    private static let logger = Logger.oplog(BDPPreRunCacheModel.self, category: "BDPPreRunCacheModel")

    /// 是否已经prerun过了
    private var hasCached = false

    /// JS字符串缓存表['FilePath' : 'JSString']
    private var cachedMap = [String : String]()

    private var packageReader: BDPPackageStreamingFileHandle?

    lazy var readCacheFiles: [String] = {
        [String]()
    }()

    /// 读写锁
    private let rwSignal = DispatchSemaphore(value: 1)

    init(_ appID: String, prerunScene: [Int]) {
        self.appID = appID
        let uniqueID = OPAppUniqueID(appID: appID, identifier: nil, versionType: .current, appType: .gadget)
        self.uniqueID = uniqueID
        self.prerunScene = prerunScene
        self.monitor.setUniqueID(uniqueID).timing()
        self.monitor.addCategoryValue("prerun_scene", prerunScene)
    }

    public func cachedJSString(_ filePath: String?) -> String? {
        guard let filePath = filePath else {
            return nil
        }

        rwSignal.wait()
        let script = cachedMap[filePath]
        rwSignal.signal()
        if BDPIsEmptyString(script) {
            Self.logger.info("[PreRun] script is nil path: \(filePath) for \(appID)")
        } else {
            Self.logger.info("[PreRun] hit cache \(filePath) for \(appID)")
        }
        return script
    }

    /// 开始prerun缓存文件. 目前只会缓存"page-frame.js"和"app-service.js"
    public func startPreRunGadgetFile() {
        Self.logger.info("[PreRun] start preRun gadget \(uniqueID.appID)")
        guard !hasCached else {
            Self.logger.info("[PreRun] already cached \(uniqueID.appID)")
            return
        }

        startTime = CACurrentMediaTime()

        // 只允许外部调用一次cahce指令
        hasCached = true

        guard let gadgetMeta = MetaLocalAccessorBridge.getMetaWithUniqueId(uniqueID: uniqueID) as? GadgetMeta else {
            Self.logger.warn("[PreRun] can not get meta for: \(uniqueID.appID)")
            prehandleGadget(BDPPreRunManager.sharedInstance.preRunABtestHit)
            addFailedReasonAndReport(BDPPreRunFailedReason.localPackageNotExsit.rawValue + "abTest:\(BDPPreRunManager.sharedInstance.preRunABtestHit)")
            return
        }

        let pkgCtx = packageContext(with: gadgetMeta)

        guard !pkgCtx.isSubpackageEnable() else {
            Self.logger.info("[PreRun] split pkg not support prerun: \(uniqueID.appID)")
            addFailedReasonAndReport(BDPPreRunFailedReason.subPackageNotSupport.rawValue)
            return
        }

        guard BDPPackageLocalManager.isLocalPackageExsit(pkgCtx) else {
            Self.logger.warn("[PreRun] local pkg not exist: \(uniqueID.appID)")
            prehandleGadget(BDPPreRunManager.sharedInstance.preRunABtestHit)
            addFailedReasonAndReport(BDPPreRunFailedReason.localPackageNotExsit.rawValue + "abTest:\(BDPPreRunManager.sharedInstance.preRunABtestHit)")
            return
        }

        // 这边流式包获取过来的reader是BDPPackageStreamingFileHandle协议对象
        guard let fileReader = BDPPackageManagerStrategy.packageReaderAfterDownloaded(for: pkgCtx) as? BDPPackageStreamingFileHandle else {
            Self.logger.warn("[PreRun] can not get BDPPackageStreamingFileHandle for: \(uniqueID.appID)")
            return
        }

        // 这边持有一下fileReader,防止被释放
        packageReader = fileReader

        // 这边记录当前prerun缓存的meta信息
        cachedMeta = gadgetMeta

        readAppJS(String.pageFrameJSName, by: fileReader) {[weak self] filePath, script in
            self?.safeCache(script, for: filePath)
        }

        readAppJS(String.appServiceJSName, by: fileReader) {[weak self] filePath, script in
            self?.safeCache(script, for: filePath)
        }
    }

    /// 为埋点记录命中的缓存文件(Note: 当前只有在主线程中使用, 后续使用要考虑多线程安全)
    public func addMonitorCachedFile(_ fileName: String) {
        if !readCacheFiles.contains(fileName) {
            readCacheFiles.append(fileName)
        }

        // 当启动使用了缓存,标记命中缓存
        if !readCacheFiles.isEmpty {
            hitCache = true
        }

        monitor.addCategoryValue("usedCacheFiles", readCacheFiles)
    }

    public func reportMonitorResult() {
        guard hitCache else {
            monitor.setResultType(BDPPreRunFailedReason.caceheNotUse.rawValue)
            monitor.timing().flush()
            return
        }

        monitor.setResultTypeSuccess()
        monitor.timing().flush()
        // 用户在命中缓存后,后续可能多次重复打开,那么也可能会命中缓存
        // 因此这边要重新初始化埋点以便下一次命中后上报
        monitor = OPMonitor(String.monitorEventName)
        monitor.setUniqueID(uniqueID).timing()
        monitor.addCategoryValue("prerun_scene", prerunScene)
    }

    public func addFailedReasonAndReport(_ reason: String) {
        // 当前命中过缓存后,后续就不再上报失败的case
        // 因为在上报一次成功后会重新构建一个OPMinitor对象,但是如果此时触发了清理逻辑,预期是不上报失败
        if hitCache {
            Self.logger.info("[PreRun] already hitted cached. failed: \(reason)")
            return
        }

        monitor.setResultType(reason)
        monitor.timing().flush()
    }

    func readAppJS(_ fileName: String,
                   by fileReader: BDPPackageStreamingFileHandle,
                   completion: @escaping (_ filePath: String, _ script: String?) -> Void) {
        let subPackagePath = fileReader.basic().pagePath

        let filePath = filePath(fileName, subPagePath: subPackagePath)

        readPkgFile(with: filePath, by: fileReader) { script in
            completion(filePath, script)
        }
    }

    func readPkgFile(with fileName: String,
                     by fileReader: BDPPkgFileAsyncReadHandleProtocol,
                     completion: @escaping (_ script: String?) -> Void) {
        fileReader.readData(inOrder: false, withFilePath: fileName, dispatchQueue: .global(qos: .userInitiated)) {[weak self] error, path, data in
            guard error == nil else {
                Self.logger.warn("[PreRun] read pkg data error: \(String(describing: error)) path: \(fileName)")
                completion(nil)
                self?.monitor.setError(error)
                self?.addFailedReasonAndReport(BDPPreRunFailedReason.readFileError.rawValue)
                return
            }

            guard let _data = data else {
                Self.logger.warn("[PreRun] read pkg data is nil for path: \(fileName)")
                completion(nil)
                self?.addFailedReasonAndReport(BDPPreRunFailedReason.fileDataNil.rawValue)
                return
            }

            let pageFrameScript = String(data: _data, encoding: .utf8)
            Self.logger.info("[PreRun] readFile success for \(String(describing: self?.appID)) file: \(fileName)")
            completion(pageFrameScript)
        }
    }

    func packageContext(with appMeta: AppMetaProtocol) -> BDPPackageContext {
        let tracingManager = BDPTracingManager.sharedInstance()
        let trace = tracingManager.getTracingBy(appMeta.uniqueID) ?? tracingManager.generateTracing(by: appMeta.uniqueID)
        return BDPPackageContext(appMeta: appMeta, packageType: .pkg, packageName: nil, trace: trace)
    }

    func filePath(_ fileName: String, subPagePath: String?) -> String {
        guard let subPagePath = subPagePath else {
            return fileName
        }

        return subPagePath.appendingPathComponent(fileName)
    }

    private func safeCache(_ script: String?, for key: String) {
        guard let script = script else {
            Self.logger.info("[PreRun] script is nil for path: \(key) appID: \(appID)")
            return
        }
        rwSignal.wait()
        cachedMap[key] = script
        rwSignal.signal()
    }
}

extension BDPPreRunCacheModel {
    // 是否需要预下载应用
    func prehandleGadget(_ needDownload: Bool) {
        guard needDownload else {
            return
        }

        let preloadScene = BDPPreloadScene(priority: 0, sceneName: "PreRun")
        let handleInfo = BDPPreloadHandleInfo(uniqueID: uniqueID, scene: preloadScene, scheduleType: .directHandle)
        BDPPreloadHandlerManager.sharedInstance.handlePkgPreloadEvent(preloadInfoList: [handleInfo])
    }
}

fileprivate extension String {
    static let pageFrameJSName = "page-frame.js"
    static let appServiceJSName = "app-service.js"
    static let monitorEventName = "op_gadget_prerun_result"
}

public enum BDPPreRunFailedReason: String {
    // settings 已经关闭
    case settingsDisable = "settings disable"
    // 接收到系统memory warning
    case memoryWarning = "memory warning"
    // 读取磁盘中的文件失败
    case readFileError = "read file error"
    // 读取出来的数据为空
    case fileDataNil = "file data is nil"
    // 飞书已经进入后台
    case larkIsAlreadyBackground = "lark is already background"
    // 触发的过于频繁
    case triggerTooOften = "trigger too often"
    // 已经预加载了相同的appid
    case triggerSameAppid = "trigger same app id"
    // 该scene 未开启prerun
    case sceneDisable = "scene disable"
    // 没有在指定scene 和 时间范围内打开过
    case notOpenInTime = "not open in time"
    // 飞书进入后台
    case larkBackground = "lark enter background"
    // 缓存存在的时间超过限制
    case cacheTimeout = "timeout"
    // 缓存被替换
    case cacheReplaced = "cache replaced"
    // 飞书被杀死
    case larkTerminal = "lark terminal"
    // 由于止血/meta过期缘故,则认为prerun缓存的内容过期
    case cacheNotMatch = "cache not match"
    // 小程序启动完毕了但是缓存还没有被使用
    case caceheNotUse = "cache not use"
    // 分包不支持prerun
    case subPackageNotSupport = "subPackage not support"
    // 本地无包
    case localPackageNotExsit = "local pkg not exsit"
    // 被容灾清理
    case DRClean = "trigger DR clean"

}
