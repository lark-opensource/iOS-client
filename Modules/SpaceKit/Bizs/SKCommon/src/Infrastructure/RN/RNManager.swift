//
//  RNManager.swift
//  SpaceKit
//
//  Created by Ryan on 2018/12/3.
// swiftlint:disable file_length

import UIKit
import BitableBridge
import SwiftyJSON
import ThreadSafeDataStructure
import RxRelay
import RxSwift
import SKFoundation
import LarkStorage
import SKResource
import SKInfra

// 文档在这里
//https://bytedance.feishu.cn/space/folder/fldcnwMcLTPC0d94GzMEvC2D9Fc
final public class RNManager: NSObject {
    public static let callbackID = "callbackId"
    public static let showDebugNotification = "RCTShowDevMenuNotification"
    public static let rnMessageQueueSemaphore = DispatchSemaphore(value: 0)
    static var rnWorkerToken = DispatchSpecificKey<()>()

    private var rnWorkerQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "RN_worker_queue")
        queue.setSpecific(key: RNManager.rnWorkerToken, value: ())
        queue.async {
            RNManager.rnMessageQueueSemaphore.wait()
            manager.injectDataIntoRN()
        }
        return queue
    }()

    public static let manager = RNManager()
    private var currentNetStatus: Int = 1
    var referenceCount: [String: Int] = [:]
    private let rnStatisticsHandler = RNStatistics()
    private let rnBridge: BitableBridge
    var userValidInjectObsevable = BehaviorRelay<Bool>(value: false)
    public var hadSetupEnviroment = BehaviorRelay<Bool>(value: false)

    private var canReloadRn = BehaviorRelay<Bool>(value: false)
    var canReloadRnObserverable: BehaviorRelay<Bool> {
        return canReloadRn
    }
    private var reloadDisposeBag = DisposeBag()

    public var  hadStarSetUp: Bool = false
    public var  isReloading: Bool = false

    private var loadBundleDisposeBag = DisposeBag()

    private var reloadCallback: ((Bool) -> Void)?
    private var messageHandlerDic = SafeDictionary<RNEventName, NSPointerArray>()//do not public this property due to thread safe issue
    private var bundlesToLoad = [BundleType]()
    private var targetBundles: [BundleType] {
        return [BundleType.base,
                BundleType.doc,
                BundleType.comment,
                BundleType.permission,
                BundleType.version,
                BundleType.common]
    }


    private var needUseSaverPkg: Bool = false

    override private init() {
        self.rnBridge = BitableBridge()
        super.init()
        bundlesToLoad = targetBundles
        self.rnBridge.delegate = self
        self.currentNetStatusWatch()
        self.injectNotification()
        handleRNInternalLog()
        handleErrorAndExcpetion()
        NotificationCenter.default.addObserver(self, selector: #selector(rnBridgeInnerReload), name: NSNotification.Name.RCTBridgeWillReload, object: nil)

        OpenAPI.docs.rnDebugShakeFollowSetting()
    }

    @objc
    func rnBridgeInnerReload() {
        DocsLogger.info("rnBridgeInnerReload", component: LogComponents.docsRN)
        #if DEBUG
        if self.isRemoteRN == false {
            ///目前应该只有RN调试模式才会触发内部reload，其它情况需要查下
            spaceAssertionFailure("no RemoteRN, but innerReload")
        }
        #endif
    }

    public func loadBundle() {
        #if DEBUG
        if #available(iOS 12.0, *) {
            os_signpost(.begin, log: DocsSDK.openFileLog, name: "setUpRN")
        }
        #endif
        hadStarSetUp = true
        if isRemoteRN {
            loadRemoteBundle()
        } else {
            DocsTracker.startRecordTimeConsuming(eventType: .rnLoadBundle, parameters: nil)
            loadLocalBundles()
        }
        registerRnEvent(eventNames: [.base, .common], handler: self)
        rnStatisticsHandler.startListen()
    }

    public func registerRnEvent(eventNames: [RNEventName], handler: RNMessageDelegate) {
        rnQueueAsync {
            eventNames.forEach { (eventName) in
                let handlers = self.messageHandlerDic[eventName] ?? NSPointerArray.weakObjects()
                let containHandler = handlers.allObjects.contains(where: { (obj) -> Bool in
                    guard let obj = obj as? RNMessageDelegate else {
                        spaceAssertionFailure("not RNMessageDelegate")
                        return false
                    }
                    return obj === handler
                })

                if containHandler == false {
                    handlers.addObject(handler)
                    self.messageHandlerDic[eventName] = handlers
                }
            }
        }
    }

    //requestFromNative
    public func sendSyncData(data: [String: Any], responseId: String? = nil) {
        rnQueueAsync {
            autoreleasepool {
                do {
                    guard JSONSerialization.isValidJSONObject(data) else {
                        spaceAssertionFailure("JSONSerialization, not Valid data")
                        return
                    }

                    let responseData = try JSONSerialization.data(withJSONObject: data, options: [])
                    guard let responseDataStr = String(data: responseData, encoding: String.Encoding.utf8) else {
                        spaceAssertionFailure("\(#function) to jsonStr fail")
                        return
                    }

                    var toRNData: [String: Any] = ["responseData": responseDataStr]
                    if let responseId = responseId {
                        toRNData["responseId"] = responseId
                    }
                    let strData = try JSONSerialization.data(withJSONObject: toRNData, options: [])
                    if let str = String(data: strData, encoding: String.Encoding.utf8) {
                        self.rnBridge.syncRequest(str)
                        let operation = data["operation"] as? String ?? ""
                        DocsLogger.info("docs RN bridge send to rn: " + operation)
                    } else {
                        DocsLogger.error("docs RN bridge send to rn unwrap fail")
                    }
                } catch {
                    DocsLogger.error("send data to rn parse error", error: error)
                }
            }
        }
    }

    public func sendSpaceBaseBusinessInfoToRN(data: [String: Any]) {
        let data: [String: Any] = ["business": "base",
                                   "data": data]
        sendSpaceBusnessToRN(data: data)
    }

    public func sendSpaceCommonBusinessInfoToRN(data: [String: Any]) {
        let data: [String: Any] = ["business": "common",
                                   "data": data]
        sendSpaceBusnessToRN(data: data)
    }

    public func sendLarkUnifiedMessageToRN(apiName: String, data: [String: Any], callbackID: String? = nil) {
        var msg: [String: Any] = ["apiName": apiName,
                                  "data": data]
        if let callbackID = callbackID {
            msg["callbackID"] = callbackID
        }
        sendSpaceBusnessToRN(data: msg)
    }

    //requestFromDocs
    public func sendSpaceBusnessToRN(data: [String: Any]) {
        rnQueueAsync {
            do {
                try autoreleasepool {
                    if self.handleReferenceCount(data: data) {
                        DocsLogger.error("handleReferenceCount, key=\(self.getBusAndOperationKey(data: data))", component: LogComponents.docsRN)
                        return
                    }
                    guard JSONSerialization.isValidJSONObject(data) else {
                        spaceAssertionFailure("JSONSerialization, not Valid data")
                        return
                    }
                    let responseData = try JSONSerialization.data(withJSONObject: data, options: [])
                    guard let responseDataStr = String(data: responseData, encoding: String.Encoding.utf8) else {
                        spaceAssertionFailure()
                        return
                    }
                    let json = JSON(data)
                    let operation = json["data"]["operation"].stringValue
                    let business = json["business"].stringValue
                    DocsLogger.info("spaceBusnessRequest business:\(business) operation:\(operation)", component: LogComponents.docsRN)
                    self.rnBridge.spaceBusnessRequest(responseDataStr)
                }
            } catch {
                DocsLogger.error("send data to rn parse error", error: error, component: LogComponents.docsRN)
            }
        }
    }

    private func getBusAndOperationKey(data: [String: Any]) -> String {
        let busKey = data["business"] as? String ?? ""
        let innerData = data["data"] as? [String: Any]
        let operationKey = innerData?["operation"] as? String ?? ""
        return busKey + operationKey
    }

    private func parseSyncDataString(_ dataString: String) {
        do {
            guard let jsonData = dataString.data(using: .utf8),
                let rnDataDic = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [String: Any],
                let handlerName = rnDataDic["handlerName"] as? String,
                let eventName = RNEventName(rawValue: handlerName) else {
                    DocsLogger.error("parse rn data error")
                    return
            }
            self.distributeRNEvent(rnDataDic: rnDataDic, rnEventName: eventName)
        } catch {
            DocsLogger.error("receive rn data parse error", error: error)
        }
    }

    private func parseSpaceBusnessDataString(dataString: String) {
        do {
            guard let jsonData = dataString.data(using: .utf8),
                let dic = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [String: Any] else {
                    spaceAssertionFailure("parse rn data error")
                    DocsLogger.error("parse rn data error")
                    return
            }
            let isLarkMsg = dic["apiName"] != nil
            if isLarkMsg {
                //lark统一消息
                self.distributeRNEvent(rnDataDic: dic, rnEventName: .larkUnifiedMessage)

            } else {
                guard let eventString = dic["business"] as? String,
                      let rnDataDic = dic["data"] as? [String: Any],
                      let eventName = RNEventName(rawValue: eventString) else {
                    spaceAssertionFailure("parse rn data error")
                    DocsLogger.error("parse rn data error")
                    return
                }
                self.distributeRNEvent(rnDataDic: rnDataDic, rnEventName: eventName)
            }

        } catch {
            DocsLogger.error("receive rn data parse error", error: error)
        }
    }

    private func distributeRNEvent(rnDataDic: [String: Any], rnEventName: RNEventName) {
        guard let handlers = messageHandlerDic[rnEventName]?.allObjects as? [RNMessageDelegate] else {
            if rnEventName == .comment {
                DocsLogger.error("can not handle \(rnEventName) rnDataDic:\(rnDataDic)", component: LogComponents.comment)
            } else {
                // spaceAssertionFailure("can not handle \(rnEventName)")
            }
            return
        }

        if rnEventName == .getDataFromRN,
            JSON(rnDataDic)["data"]["action"].stringValue == "confirmProcessRunning" {
            DocsLogger.info("=====RN-\(rnDataDic)")
            DispatchQueue.main.async {
                self.receiveRNConfirm()
            }
            return
        }

        handlers.forEach({ (handler) in
            DispatchQueue.main.async {
                guard let msgIdentifier = rnDataDic["identifier"] as? [String: Any] else {
                    handler.didReceivedRNData(data: rnDataDic, eventName: rnEventName)
                    return
                }
                if handler.compareIdentifierEquality(identifier: msgIdentifier) {
                    handler.didReceivedRNData(data: rnDataDic, eventName: rnEventName)
                }
            }
        })
    }
}

extension RNManager {
    private func handleErrorAndExcpetion() {
        RCTSetFatalHandler { (error) in
            DocsLogger.error("RN Fatal Error", error: error, component: LogComponents.docsRN)
            let reason = error?.localizedDescription ?? "unknown"
            DocsTracker.log(enumEvent: .rnFatal, parameters: ["reason": reason])
        }

        RCTSetFatalExceptionHandler { (excpetion) in
            if let excpetion = excpetion {
                DocsLogger.error("RN Fatal Exception", extraInfo: ["excpetion": excpetion], component: LogComponents.docsRN)
            } else {
                DocsLogger.error("RN Fatal Exception", component: LogComponents.docsRN)
            }

            let reason = excpetion?.reason ?? "unknown"
            DocsTracker.log(enumEvent: .rnException, parameters: ["reason": reason])
        }

        RCTSetAssertFunction { (condition, fileName, lineNumber, function, message) in
            let info: [String: Any] = ["condition": condition ?? "",
                                       "fileName": fileName ?? "",
                                       "lineNumber": lineNumber ?? Int(0),
                                       "function": function ?? "",
                                       "message": message ?? ""]
            DocsLogger.error("RN Assert", extraInfo: info, component: LogComponents.docsRN)
            spaceAssertionFailure("RN Assert \(info)")
        }
    }

    private func handleRNInternalLog() {
        #if DEBUG
        RCTSetLogThreshold(RCTLogLevel.trace)
        #else
        RCTSetLogThreshold(RCTLogLevel.warning)
        #endif

        RCTSetLogFunction { (level, source, fileName, lineNum, message) in
            DocsLogger.info("level:\(level.rawValue), source:\(source.rawValue),fileName:\(fileName ?? ""),lineNum:\(lineNum ?? 0),message:\(message ?? "")", component: LogComponents.docsRN)
            if level == RCTLogLevel.error || level == RCTLogLevel.fatal {
                let name = fileName ?? ""
                let msg = message ?? ""
                DocsTracker.log(enumEvent: .rnErrorLog, parameters: ["rnLog_level": level.rawValue,
                                                                     "rnLog_source": source.rawValue,
                                                                     "rnLog_fileName": name,
                                                                     "rnLog_lineNum": lineNum ?? 0,
                                                                     "rnLog_message": msg])
            }
        }
    }
}

// MARK: - Bundle 相关
extension RNManager {
    private var isRemoteRN: Bool {
        return OpenAPI.docs.remoteRN
    }

    private func loadLocalBundles() {
        DocsLogger.info("loadLocalBundles, bundlesToLoad.count=\(bundlesToLoad.count)", component: LogComponents.docsRN)
        guard let bundleType = bundlesToLoad.first else { return }

        loadBundleDisposeBag = DisposeBag()
        
        GeckoPackageManager.shared.fePkgReadyObserverble
            .observeOn(MainScheduler.instance)
            .distinctUntilChanged()
            .filter({ (value) -> Bool in
                return value
            })
            .subscribe(onNext: { [weak self](value) in
                DocsLogger.info("fepkg is ready on disk and locator is ready ? : \(value)")
                if bundleType == .base {
                    self?.loadPlatformBundle()
                } else {
                    self?.loadSubBundle(bundleType: bundleType)
                }
        }).disposed(by: loadBundleDisposeBag)

    }

    private func loadPlatformBundle() {
        let path = GeckoPackageManager.shared.filesRootPath(for: .webInfo) ?? SKFilePath(absPath: "")
        let fileName = getBundleName(.base)
        var filePath: SKFilePath? = GeckoPackageManager.shared.getFullFilePath(at: path, of: fileName)
        //返回上一级目录，跟replacingOccurrences(of: "/\(fileName)", with: "")效果一样
        filePath = filePath?.deletingLastPathComponent
        
        var baseBundleURL = filePath?.pathURL
        if OpenAPI.docs.RNHost.count > 1, isRemoteRN == true, let remoteUrl = URL(string: OpenAPI.docs.RNHost) {
            baseBundleURL = remoteUrl
        }

        let targetFileExist = filePath?.exists ?? false
        DocsLogger.info("RN 目录下是否有 \(fileName), \(targetFileExist)", component: LogComponents.docsRN)

        if !targetFileExist {
            if LKFeatureGating.rnReloadResSaverEnable {
                needUseSaverPkg = true
                // 写到本地，下次启动或重登陆时全清资源包数据
                CCMKeyValue.globalUserDefault.set(true, forKey: UserDefaultKeys.needClearAllFEPkg)
            }
            DocsLogger.error("RN 缺少 base bundle", component: LogComponents.docsRN)

            baseBundleURL = builtinRNBundleURL(for: .base)?.pathURL

            let msg = "RN base bundle file path error，enter saver logic,path: \(path), filePath:\(filePath?.pathString ?? ""), baseBundleURL: \(baseBundleURL?.path ?? "")"
            let params: [String: String] = ["crash_message": msg]
            DocsTracker.log(enumEvent: .rnLoadBundleFailed, parameters: params)
        } else {
            needUseSaverPkg = false
        }

        DispatchQueue.global().async {

            self.rnBridge.reload(withOfflineMode: !self.isRemoteRN,
                                 withJSBundleFolder: baseBundleURL,
                                 filename: BundleType.base.rawValue,
                                 extension: "jsbundle",
                                 remoteIP: "localhost")
            DocsLogger.info("docs RN bridge start load", component: LogComponents.docsRN)
        }
    }
    
    // 内置的 RN 包路径
    private func builtinRNBundleURL(for type: BundleType) -> SKFilePath? {
        var path = GeckoPackageManager.shared.getSaviorPkgPath()
        //RN 资源包兜底路径获取
        DocsLogger.info("RN resource bundle bottom path， getSaviorPkgPath,for:\(type), path：\(path.pathString)", component: LogComponents.docsRN)

        guard let url = getBundleFileUrl(in: path, type: type) else {
            //RN 资源包兜底路径获取
            DocsLogger.info("RN resource bundle bottom path，getBundleFileUrl nil, path：\(path.pathString)", component: LogComponents.docsRN)
            return nil
        }
        let isExist = checkFileIsExist(in: url, type: type)
        if !isExist {
            // 解压到沙盒
            path = GeckoPackageManager.shared.getFinalSaverPkgPath()
            let fileName = getBundleName(type)
            let finalUrlPath = GeckoPackageManager.shared.getTargetFileFullPath(in: path,
                                                                               fileName: fileName,
                                                                               needFullPath: type != .base)
//            let finalUrl = URL(fileURLWithPath: finalUrlStr)
            //RN 重新解压内嵌包后, 获取到的兜底
            DocsLogger.info("RN After reextracting the embedded package, get the bottom pocket,finalUrl：\(finalUrlPath.pathString)", component: LogComponents.docsRN)
            return finalUrlPath

        }
        //RN 资源包兜底路径获取
        DocsLogger.info("RN resource bundle bottom path, url.path：\(url.pathString) ", component: LogComponents.docsRN)
        return url
    }

    private func getBundleFileUrl(in folder: SKFilePath, type: BundleType) -> SKFilePath? {
        let fileName = getBundleName(type)
        guard var filePath = GeckoPackageManager.shared.getFullFilePath(at: folder, of: fileName) else {
            return nil
        }
        if type == .base {
            //返回上一级目录，跟replacingOccurrences(of: "/\(fileName)", with: "")效果一样
            filePath = filePath.deletingLastPathComponent
        }
        return filePath
    }

    private func getBundleName(_ type: BundleType) -> String {
        if type == .base {
            return type.rawValue + ".jsbundle"
        } else {
            return type.rawValue + ".ios.jsbundle"
        }
    }

    private func loadSubBundle(bundleType: BundleType) {
        guard let path = GeckoPackageManager.shared.filesRootPath(for: .webInfo) else {
            DocsLogger.error("loadSubBundle path nil", component: LogComponents.docsRN)
            return
        }
        
        guard var indexBundleURL = getBundleFileUrl(in: path, type: bundleType) else {
            DocsLogger.error("loadSubBundle indexBundleURL nil", component: LogComponents.docsRN)
            return
        }
        
        if !indexBundleURL.exists
            || (needUseSaverPkg && LKFeatureGating.rnReloadResSaverEnable) {
            
            if let bundleURL = builtinRNBundleURL(for: bundleType) {
                indexBundleURL = bundleURL
            } else {
                DocsLogger.error("loadSubBundle bundleURL nil", component: LogComponents.docsRN)
            }
            
        } else {
            DocsLogger.error("loadSubBundle indexBundleURL.exists: \(indexBundleURL.exists), needUseSaverPkg:\(needUseSaverPkg)", component: LogComponents.docsRN)
        }
        loadBusinessBundle(businessBundleUrl: indexBundleURL)
    }

    private func loadBusinessBundle(businessBundleUrl: SKFilePath) {
        DispatchQueue.global().async {
            do {
                _ = businessBundleUrl.pathURL.startAccessingSecurityScopedResource()
                let data = try Data.read(from: businessBundleUrl, options: .mappedIfSafe)
                businessBundleUrl.pathURL.stopAccessingSecurityScopedResource()
                self.rnBridge.executeSourceCode(data, sync: false)
            } catch {
                //RN 子bundle 加载报错
                let msg = "RN child bundle Load error，error:\(error), url: \(businessBundleUrl.pathString)"
                let params: [String: String] = ["crash_message": msg]
                DocsTracker.log(enumEvent: .rnLoadBundleFailed, parameters: params)
                DocsLogger.error("fail to transfer bundle into binary data", component: LogComponents.docsRN)
            }
        }
    }

    private func loadRemoteBundle() {
        let remoteIP = OpenAPI.docs.RNHost.count > 0 ? OpenAPI.docs.RNHost : "localhost"
        self.rnBridge.reload(withOfflineMode: !isRemoteRN,
                             withJSBundleFolder: I18n.resourceBundle.bundleURL,
                             filename: "index.ios",
                             extension: "bundle",
                             remoteIP: remoteIP)
        DocsLogger.info("docs RN bridge start load", component: LogComponents.docsRN)
    }

    private func checkFileIsExist(in folder: SKFilePath, type: BundleType) -> Bool {
        let fileName = getBundleName(type)
        var path = folder
        if !path.pathString.hasSuffix(fileName) {
            path = path.appendingRelativePath(fileName)
        }
        let isDirectory = path.isDirectory
        let isExist = path.exists
        DocsLogger.info("checkFileIsExist: \(isExist), isDirectory:\(isDirectory), path: \(path)", component: LogComponents.docsRN)
        return isExist && !isDirectory
    }

    public func reloadBundleAfterGeckoPacageUpdate() {
        DocsLogger.info("reloadBundleAfterGeckoPacageUpdate, begin", component: LogComponents.docsRN)
        guard hadStarSetUp else {
            DocsLogger.info("reloadBundleAfterGeckoPacageUpdate, hadStarSetUp = false", component: LogComponents.docsRN)
            return
        }
        reloadBundle { (finish) in
            DocsLogger.info("reloadBundleAfterGeckoPacageUpdate, finish=\(finish)", component: LogComponents.docsRN)
        }
    }

    public func reloadBundle(callback: @escaping (Bool) -> Void) {
        DocsLogger.info("reloadBundle", component: LogComponents.docsRN)

        self.reloadDisposeBag = DisposeBag()
        self.canReloadRn
            .observeOn(MainScheduler.instance)
            .filter({ (canReload) -> Bool in
                DocsLogger.info("canReload\(canReload)", component: LogComponents.docsRN)
                return canReload
              })
            .take(1)
            .subscribe(onNext: { (_) in
                self.innerReloadBundle(callback: callback)
            }).disposed(by: self.reloadDisposeBag)
    }

    func innerReloadBundle(callback: @escaping (Bool) -> Void) {
        DocsLogger.info("innerReloadBundle", component: LogComponents.docsRN)
        hadSetupEnviroment.accept(false)
        isReloading = true
        canReloadRn.accept(false)

        rnWorkerQueue.async {
            DispatchQueue.main.async {
                self.reloadCallback = callback
                self.bundlesToLoad = self.targetBundles
                self.loadLocalBundles()
            }
            self.referenceCount.removeAll()
            RNManager.rnMessageQueueSemaphore.wait()
            self.injectDataIntoRN()
        }
    }
}

// MARK: - 注入信息给RN
extension RNManager {
    public func injectDataIntoRN() {
        injectNetInfo()
        injectHeaders()
        injectUserInfo()
        injectAPPInfo()
    }

    public func updateAPPInfoIfNeed() {
        if RNManager.manager.hadSetupEnviroment.value == true {
            injectAPPInfo()
        }
    }

    private func currentNetStatusWatch() {
        DocsNetStateMonitor.shared.addObserver(self) { [weak self] (type, _) in
            var status = type.rawValue
            if type == .notReachable {
                status = 6
            }
            self?.currentNetStatus = status
            DocsLogger.info("currentNetStatusWatch = \(status)")

            if self?.hadSetupEnviroment.value == true {
                self?.injectNetInfo()
            }
        }
    }

    private func injectNetInfo() {
        let currentStatus = self.currentNetStatus
        let data: [String: Any] = [
            "operation": "nativeNotify",
            "body": [
                "type": "setNetworkState",
                "data": [
                    "status": currentStatus
                ]
            ]
        ]
        self.sendSpaceBaseBusinessInfoToRN(data: data)
        DocsLogger.info("inject net info to rn \(currentStatus)")
    }

    private func injectAPPInfo() {
        var body = [String: Any]()
        var scm = GeckoPackageManager.shared.currentVersion(type: .webInfo)
        let idx = scm.index(scm.endIndex, offsetBy: -5)
        scm = String(scm[idx...])
        body["scm"] = scm
        body["sdk"] = SpaceKit.version
        if DomainConfig.isNewDomain, !DomainConfig.enableAbandonOversea {
            body["isOversea"] = DomainConfig.envInfo.isChinaMainland ? 0 : 1
        }
        body["apiPrefix"] = OpenAPI.docs.baseUrl
        let longConDomainArray = OpenAPI.docs.docsLongConDomain
        DocsLogger.info("【LongConDomain】, inject longConDomainArray=\(longConDomainArray)")
        body["persistentConnectionURL"] = longConDomainArray.first ?? ""
        body["persistentConnectionURLList"] = longConDomainArray
        body["language"] = DocsSDK.currentLanguage.languageIdentifier
        body["doc-biz"] = SpaceHttpHeaders.docBiz
        body["ua"] = UserAgent.defaultWebViewUA
        var ttEnv: String = ""
        if OpenAPI.DocsDebugEnv.current == .staging {
            ttEnv =  KVPublic.Common.ttenv.value() ?? ""
        }
        body["x-tt-env"] = ttEnv
        var finalAppkey = ""
        /// 先从lark传入的 DomainConfig.appKey上取
        if let appKey = DomainConfig.appKey, !appKey.isEmpty {
            finalAppkey = appKey
        }
        
        DocsLogger.info("appkey from lark is : \(String(describing: transLogAppKey(DomainConfig.appKey)))")

        if let globalConfig = DomainConfig.globalConfig {
            body["domainCharacteristicConfig"] = globalConfig
            /* 非KA环境，代码走到这里，finalAppkey是有值的，但是KA环境，在新私有化环境准备阶段，Rust那边经常忘记配置，所以，作为兜底，
             在globalConfig（另外接口请求回来的）中取，两个地方的值在同一个环境中是一样的。
             */
            if  finalAppkey.isEmpty,
                let common = globalConfig["common"] as? [String: Any],
                let frontier = common["frontier"] as? [String: Any],
                let appKey = frontier["appKey"] as? String, !appKey.isEmpty {
                finalAppkey = appKey
                DocsLogger.info("get appkey from domain config all request is : \(String(describing: transLogAppKey(appKey)))")
            }
        }

        if !finalAppkey.isEmpty {
            body["persistentConnectionKey"] = finalAppkey
            DocsLogger.info("put persistentConnectionKey or appkey to rn, appkey.count is \(finalAppkey.count)")
        } else {
            DocsLogger.error("appkey can not be nil, lark did not pass to DocsSDK")
        }

        let data: [String: Any] = ["operation": "appInfo", "body": body]
        sendSyncData(data: data)
    }

    private func injectHeaders() {
        var body = [String: Any]()
        body["user-agent"] = UserAgent.defaultNativeApiUA
        body["sidecar"] = OpenAPI.docs.featureID
        let data: [String: Any] = ["operation": "headers", "body": body]
        sendSyncData(data: data)
    }

    private func injectUserInfo() {
        let id = User.current.info?.userID
        let tenantID = User.current.info?.tenantID
        let deviceID = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.deviceID)
        var body = [String: Any]()
        body["avatarUrl"] = User.current.info?.avatarURL
        body["id"] = id
        body["suid"] = id
        body["tenantId"] = tenantID
        body["deviceId"] = deviceID
        body["userName"] = User.current.info?.name
        //文档打开用的域名注入给前端（sheet_ssr预加载需求）
        body["domain"] = DomainConfig.userDomain

        var env = ""
        switch OpenAPI.DocsDebugEnv.current {
        case .staging: env = "staging"
        default: env = ""
        }
        body["host"] = env
        let data: [String: Any] = ["operation": "userInfo", "body": body]
        sendSyncData(data: data)

        if let id = id, id.isEmpty == false {
            DocsLogger.info("injectUserInfo, userId valid", component: LogComponents.docsRN)
            userValidInjectObsevable.accept(true)
        }
    }

    public func injectDriveCommonPushChannel() {
        var body = [String: Any]()
        body["list"] = ["driveCommonPushChannel"]
        let data: [String: Any] = ["operation": "commonOperationInfo", "body": body]
        sendSpaceCommonBusinessInfoToRN(data: data)
    }
}

extension RNManager: BitableBridgeDelegate {
    public func loadJSBundleFailedWithError(_ error: Error!) {
        DocsLogger.error("docs RN bridge loadJSBundleFailed", extraInfo: nil, error: error, component: nil)
        reloadCallback?(false)
    }

    public func readyToUse() {
        if isRemoteRN {
            ///RN远端调试模式下，由于RN内部会reload,这里会回调两次，触发BitableBridge内部断言。
            ///目前不想改动BitableBridge里面代码, 所以这里做些处理。
            let devSettingDic = CCMKeyValue.globalUserDefault.dictionary(forKey: "RCTDevMenu") ?? [:]
            let isRemoteDebugging = (devSettingDic["isDebuggingRemotely"] as? Bool) ?? false
            let delayTime = isRemoteDebugging ? 2.0 : 0.5
            NSObject.cancelPreviousPerformRequests(withTarget: self,
                                                   selector: #selector(handleRemoteReady),
                                                   object: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
                self.handleRemoteReady()
            }
        } else {
            handleLocalBundleReady()
        }
    }

    @objc
    private func handleRemoteReady() {
        DocsLogger.info("remote bundle is loaded", component: LogComponents.docsRN)
        setupRNEnviroment()
    }

    private func handleLocalBundleReady() {
        if let bundle = bundlesToLoad.first {
            bundlesToLoad.removeFirst()
            DocsLogger.info("\(bundle.rawValue) bundle is loaded")
        }
        if !bundlesToLoad.isEmpty {
            loadLocalBundles()
        } else {
            setupRNEnviroment()
        }
    }

    private func setupRNEnviroment() {
        let isfromReload = isReloading
        isReloading = false
        RNManager.rnMessageQueueSemaphore.signal()
        #if DEBUG
        if #available(iOS 12.0, *) {
            os_signpost(.end, log: DocsSDK.openFileLog, name: "setUpRN")
        }
        #endif
        reloadCallback?(true)
        DocsTracker.endRecordTimeConsuming(eventType: .rnLoadBundle, parameters: nil)

        hadSetupEnviroment.accept(true)

        if isfromReload {
            DocsLogger.info("setupRNEnviroment, rnReloadComplete", component: LogComponents.docsRN)
            NotificationCenter.default.post(name: Notification.Name.Docs.rnReloadComplete, object: nil)
        } else {
            DocsLogger.info("setupRNEnviroment, first Time", component: LogComponents.docsRN)
        }
        NotificationCenter.default.post(name: Notification.Name.Docs.rnSetupEnviromentComplete, object: nil)

        if checkFeatureGatingOpen() {
            DocGlobalTimer.shared.add(observer: self)
        }

        canReloadRn.accept(true)
    }

    public func didReceivedResponse(_ dataString: String!) {
        rnWorkerQueue.async {
            self.parseSyncDataString(dataString)
        }
    }

    public func didReceivedDocsResponse(_ jsonString: String!) {
        rnWorkerQueue.async {
            self.parseSpaceBusnessDataString(dataString: jsonString)
        }
    }
}

extension RNManager: RNMessageDelegate {
    public func didReceivedRNData(data: [String: Any], eventName: RNManager.RNEventName) {
        guard eventName == RNManager.RNEventName.base,
            let operation = data["operation"] as? String,
            let body = data["body"] as? [String: Any],
            let message = body["message"] as? String,
            operation == "log" else { return }
        DocsLogger.info(message)
    }
}

private extension BitableBridge {

    /// 发送文档同步信息到RN requestFromNative
    ///
    /// - Parameter str: 文档同步的消息
    func syncRequest(_ str: String) {
        request(str)
    }

    /// 发送业务消息到RN  requestFromDocs
    ///
    /// - Parameter str: 具体的业务信息
    func spaceBusnessRequest(_ str: String) {
        docsRequest(str)
    }
}

// MARK: - Enter Background Notify
extension RNManager {
    private func injectNotification() {
        let center = NotificationCenter.default

        let customData: (Bool) -> [String: Any] = { isInForeground in
            [
                "operation": "notifyProcessStatus",
                "body": [
                    "foreground": isInForeground
                ]
            ]
        }

        // RNManager is a singleton, no need to remove the notification observer.
        _ = center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] _ in
            self?.sendSpaceCommonBusinessInfoToRN(data: customData(false))
            DocsLogger.info("RN: didEnterBackgroundNotification")
        }

        _ = center.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { [weak self] _ in
            self?.sendSpaceCommonBusinessInfoToRN(data: customData(true))
            DocsLogger.info("RN: willEnterForegroundNotification")
        }
    }
}

private extension RNManager {

    var isRnWorkerQueue: Bool {
        return DispatchQueue.getSpecific(key: RNManager.rnWorkerToken) != nil
    }

    func rnQueueAsync(actionBlock: @escaping () -> Void) {
        if isRnWorkerQueue {
            actionBlock()
        } else {
            rnWorkerQueue.async {
                actionBlock()
            }
        }
    }
}

extension RNManager {
    private func transLogAppKey(_ appKey: String?) -> String? {
        let count: Int = 8
        guard let appKey1 = appKey, appKey1.count > count else {
            return appKey
        }
        let prefix = appKey1.prefix(count / 2)
        let subfix = appKey1.suffix(count / 2)
        return prefix + "***********" + subfix
    }
}

extension RNManager {
    
    public func setOpenApiSession(_ session: Any) {
        var data: [String: Any] = ["operation": "setOpenApiSession",
                                   "identifier": "{}"]
        var body: [String: Any] = ["session": session]
        data["body"] = body
        let composedData: [String: Any] = ["business": "comment",
                                           "data": data]
        
        self.sendSpaceBusnessToRN(data: composedData)
    }
}
