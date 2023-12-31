//
//  MessageCardStyleManager.swift
//  LarkOpenPlatform
//
//  Created by lilun.ios on 2021/5/27.
//

import Foundation
import SwiftyJSON
import LKCommonsLogging
import OPSDK
import LarkCache
import RxSwift
import LarkSDKInterface
import Swinject
import LarkAccountInterface
import RunloopTools
import LarkAppConfig
import LarkEnv
import UniverseDesignColor
import LarkFeatureGating
import NewLarkDynamic
import ECOProbe
import SSZipArchive
import ECOInfra
import LarkStorage
import LarkSetting
import LarkContainer

struct KeyStyle {
    static let keyNarrow = "narrow"
    static let keyWide = "wide"
    static let keyStyle = "style"
    static let keyStyleZip = "style_zip"
    static let keyVersion = "version"
    static let KeySetting = "messagecard_style"
    static let KeyGrayName = "gray"
}

/// 默认配置存储
final class MessageCardStyleConfig {
    public static let KeyMessageCardStyle = "KeyMessageCardStyle"
    public static let KeyMessageCardStyleGraySuffix = "_Gray"
    public static var envType: Env.TypeEnum = .release
    public static func setup(resolver: Resolver) {
        MessageCardStyleConfig.envType = EnvManager.env.type
        OPLogger.info("MessageCardStyleConfig set env type \(EnvManager.env.type)")
    }
    public static func key() -> String {
        "\(Self.envType)_\(Self.KeyMessageCardStyle)"
    }
    public static func grayKey() -> String {
        MessageCardStyleConfig.key() + MessageCardStyleConfig.KeyMessageCardStyleGraySuffix
    }
    public static func OPMap() -> [String : Any] {
        return ["ConfigEnv": key()]
    }
}
/// 不公平锁，自旋等待
final class UnfairLock: NSLocking {
    private var unfairLock = os_unfair_lock_s()
    func lock() {
        os_unfair_lock_lock(&unfairLock)
    }
    func unlock() {
        os_unfair_lock_unlock(&unfairLock)
    }
    @discardableResult
    func action<T>(_ closure: () -> T) -> T {
        lock(); defer { unlock() }
        return closure()
    }
}

typealias SPCode = EPMClientOpenPlatformCardCode

final class MessageCardStyleManager {
    /// 单例
    public static let shared = MessageCardStyleManager()
    /// settingConfig
    private var settingConfig: [String: Any]?
    /// 外部使用解析好的最终样式
    private var resultStyle: [String: Any]?
    /// 本地打包的样式
    private var bundleStyle: [String: Any]?
    /// 锁，保证给外部样式的线程安全
    private var styleLock = UnfairLock()
    private var disposeBag = DisposeBag()
    private let queue = DispatchQueue(label: "messagecard.style.parse")
    
    private static var service: ECONetworkService {
        Injected<ECONetworkService>().wrappedValue
    }
    
    init() {
        OPLogger.info("init")
        loadSettings()
        loadStyle()
        /// 初始化时机不确定，这个时候颜色表可能还没有初始化完成
        loadUDColor()
        /// 上报初始化
        OPMonitor(SPCode.messagecard_style_manage)
            .setLevel(OPMonitorLevelNormal)
            .addMap(MessageCardStyleConfig.OPMap())
            .flush()
    }
    
    /// 加载颜色
    func loadUDColor() {
        OPLogger.info("loadUDColor")
        if UDColor.current.getCurrentStore().isEmpty {
            OPLogger.info("loadUDColor registerToken")
            UDColor.registerToken()
        }
    }
    
    /// 从缓存加载
    func loadCacheStyle(isGray: Bool = false) -> [String: Any]? {
        OPLogger.info("loadCacheStyle isGray \(isGray)")
        /// 区分一下不同环境
        return styleLock.action { () -> [String: Any]? in
            let key = isGray ? MessageCardStyleConfig.grayKey() : MessageCardStyleConfig.key()
            if let cacheStyle: NSCoding = OPMessageCardStyleCache().object(forKey: key),
               let cacheDictionary = cacheStyle as? [String: Any] {
                OPLogger.info("loadCacheStyle return cacheDictionary isGray \(isGray)")
                return cacheDictionary
            }
            OPLogger.info("loadCacheStyle no cache style isGray \(isGray)")
            return nil
        }
    }
    
    struct ZipStylePath {
        /// app version
        let buildVersion: String
        let zipName: String
        let unzipName: String
        let cardJsonName: String
        
        let zipPath: URL
        let unzipPath: URL
        let unzipJsonPath: URL
        
        let zipIso: IsoPath
        let unzipIso: IsoPath
        let unzipJsonIso: IsoPath
        
        
        // 文件读写接入 LarkStorage FG
        static let lkStorageEnable: Bool = {
            @FeatureGatingValue(key: "messagecard.lkstorage.enable")
            var featureGating: Bool
            return featureGating
        }()
        
        init() {
            /// 临时tmp目录
            let tmp = FileManager.default.temporaryDirectory
            buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
            zipName = buildVersion.md5() + "_jsonAsset.zip"
            unzipName = buildVersion.md5() + "_jsonAssetUnzip"
            cardJsonName = "card.json"
            zipPath = tmp.appendingPathComponent(zipName, isDirectory: false)
            unzipPath = tmp.appendingPathComponent(unzipName, isDirectory: false)
            unzipJsonPath = unzipPath.appendingPathComponent(cardJsonName, isDirectory: false)
            
            // LarkStorage 安全管控逻辑
            let isoPath = IsoPath
                .in(space: .global, domain: Domain.biz.openPlatform)
                .build(.temporary)
            try? isoPath.createDirectoryIfNeeded()
            zipIso = isoPath.appendingRelativePath(zipName)
            unzipIso = isoPath.appendingRelativePath(unzipName)
            unzipJsonIso = unzipIso.appendingRelativePath(cardJsonName)
        }
        
        func unzip() {
            OPLogger.info("card zip bundle unzip start process")
            guard let jsonAsset = NSDataAsset(name: KeyStyle.keyStyleZip, bundle: BundleConfig.LarkOpenPlatformBundle) else {
                OPLogger.error("jsonAsset not exist")
                return
            }
            do {
                if Self.lkStorageEnable {
                    try jsonAsset.data.write(to: zipIso, atomically: true)
                    try unzipIso.unzipFile(fromPath: AbsPath(zipIso.absoluteString), overwrite: true)
                } else {
                    try jsonAsset.data.write(to: zipPath, options: .atomic)
                    try SSZipArchive.unzipFile(atPath: zipPath.path ,
                                               toDestination: unzipPath.path ,
                                               overwrite: true,
                                               password: nil)
                }
            } catch {
                OPLogger.error("card zip bundle unzip failed", tag: "", additionalData: nil, error: error)
                let code = SPCode.messagecard_style_use_cache
                OPMonitor(code)
                    .setLevel(OPMonitorLevelError)
                    .addMap(MessageCardStyleConfig.OPMap())
                    .setError(error)
                    .flush()
                return
            }
        }
        
        func readZipStyle() -> String? {
            if Self.lkStorageEnable && unzipJsonIso.exists,
               let data = try? Data.read(from: unzipJsonIso) {
                let jsonString = String(data: data, encoding: .utf8)
                OPLogger.info("card zip load bundle style to string success use absPath")
                return jsonString
            } else if FileManager.default.fileExists(atPath: unzipJsonPath.path),
                let jsonString = try? String(data: Data(contentsOf: unzipJsonPath), encoding: .utf8) {
                OPLogger.info("card zip load bundle style to string success")
                return jsonString
            } else {
                OPLogger.error("card zip load bundle style to string fail")
                return nil
            }
        }
    }
    /// 从包中加载
    func loadBundleStyle() -> [String: Any]? {
        return styleLock.action { () -> [String: Any]? in
            if let cachedBundleStyle = bundleStyle {
                OPLogger.info("card bundle cached")
                return cachedBundleStyle
            }
            /// load zip style
            let zipStyle = ZipStylePath()
            let loadZipStyleBlock: (() -> [String: Any]?) = { [weak self] in
                if let jsonString = zipStyle.readZipStyle(),
                   let style = self?.parseStyle(styleJSONString: jsonString) {
                    OPLogger.info("card zip bundle style to string success")
                    self?.bundleStyle = style
                    return self?.bundleStyle
                }
                OPLogger.info("card bundle style to string failed")
                return nil
            }
            zipStyle.unzip()
            return loadZipStyleBlock()
        }
    }
    /// 样式实体内容
    struct StyleContent {
        let style: [String: Any]
        var narrow: [String: Any]? {
            (style[KeyStyle.keyNarrow] as? [String: Any])
        }
        var wide: [String: Any]? {
            (style[KeyStyle.keyWide] as? [String: Any])
        }
        var narrowVersion: Int {
            (narrow?[KeyStyle.keyVersion] as? Int) ?? 0
        }
        var wideVersion: Int {
            (wide?[KeyStyle.keyVersion] as? Int) ?? 0
        }
    }
    /// 样式来源
    enum StyleSource: String {
        case bundle
        case bundleCompareCache
        case cacheCompareBundle
        case onlyCache
        case remoteRelease
        case remoteGray
        case localGray
    }
    
    /// 加载style
    func loadStyle() {
        OPLogger.info("loadStyle start")
        /// 如果允许灰度, 那么使用本地保存的灰度样式
        if shoudGrayStyle(), let cacheGrayStyle = loadCacheStyle(isGray: true) {
            OPLogger.info("loadStyle merge cache gray style")
            mergeSyle(style: cacheGrayStyle, source: .localGray)
            return
        }
        let _bundleStyle = loadBundleStyle()
        let _cacheStyle = loadCacheStyle()
        if let bundleStyle = _bundleStyle, _cacheStyle == nil {
            OPLogger.info("loadStyle merge bundle style, no cache style")
            mergeSyle(style: bundleStyle, source: .bundle)
            return
        }
        if let cacheStyle = _cacheStyle, _bundleStyle == nil {
            OPLogger.info("loadStyle merge cache style, no bundle style")
            mergeSyle(style: cacheStyle, source: .onlyCache)
            return
        }
        if let bundleStyle = _bundleStyle, let cacheStyle = _cacheStyle {
            /// 两个style都不为空，判断哪个是最新的
            let bundle = StyleContent(style: bundleStyle)
            let cache = StyleContent(style: cacheStyle)
            OPLogger.info("bundleVersionNarrow: \(bundle.narrowVersion), bundleVersionWide: \(bundle.wideVersion), cacheVersionNarrow: \(cache.narrowVersion), cacheVersionWide: \(cache.wideVersion)")
            if cache.narrowVersion >= bundle.narrowVersion || cache.wideVersion >= bundle.wideVersion {
                OPLogger.info("use cache version")
                mergeSyle(style: cacheStyle, source: .cacheCompareBundle)
            } else {
                OPLogger.info("use bundle version")
                mergeSyle(style: bundleStyle, source: .bundleCompareCache)
            }
            return
        }
        OPLogger.info("can not load style")
    }
    /// 更新style
    private func mergeSyle(style: [String: Any], source: StyleSource) {
        /// 覆盖修改本地样式
        let updateStyle = LocalStyleUpdater().filter(content: StyleContent(style: style))
        styleLock.action {
            resultStyle = updateStyle.style
            OPLogger.info("mergeSyle versionNarrow \(updateStyle.narrowVersion) versionWide \(updateStyle.wideVersion) \(source)")
            clearStyleCache()
        }
        /// 上报
        let code = (source == .bundle || source == .bundleCompareCache) ? SPCode.messagecard_style_use_bundle : SPCode.messagecard_style_use_cache
        OPMonitor(code)
            .setLevel(OPMonitorLevelNormal)
            .addMap(MessageCardStyleConfig.OPMap())
            .addCategoryValue("versionNarrow", "\(updateStyle.narrowVersion)")
            .addCategoryValue("versionWide", "\(updateStyle.wideVersion)")
            .addCategoryValue("source", source.rawValue)
            .flush()
    }
    /// 返回的style
    public func messageCardStyle() -> [String: Any]? {
        return styleLock.action { () -> [String: Any]? in
            let result = resultStyle
            return result
        }
    }
    
    /// 解析json string
    private func parseStyle(styleJSONString: String) -> [String: Any]? {
        let json = JSON(parseJSON: styleJSONString)
        let code = json["code"].intValue
        guard code == 0 else {
            OPLogger.error("Parse message card style error")
            OPMonitor(SPCode.messagecard_style_parse)
                .setLevel(OPMonitorLevelError)
                .addMap(MessageCardStyleConfig.OPMap())
                .setErrorMessage("styleJSONString code not 0 \(json["code"].intValue)")
                .flush()
            return nil
        }
        guard let _ = json[KeyStyle.keyNarrow].dictionary,
              let _ = json[KeyStyle.keyWide].dictionary else {
            OPLogger.error("Parse message card style error, formate wrong")
            OPMonitor(SPCode.messagecard_style_parse)
                .setLevel(OPMonitorLevelError)
                .addMap(MessageCardStyleConfig.OPMap())
                .setErrorMessage("styleJSONString not valid, narrow or wide not dictionary")
                .flush()
            return nil
        }
        
        func parseCSSStyle(css: String) -> [String: Any]? {
            var result: [String: Any] = [:]
            let splits = css.components(separatedBy: ";")
            for element in splits {
                if element.contains(":") {
                    let items = element.components(separatedBy: ":")
                    if items.count == 2 {
                        let key = items[0]
                        let value = items[1]
                        result[key] = value
                    }
                } else {
                    if !element.isEmpty {
                        OPLogger.error("Parse Wrong Style \(element) in \(splits)")
                        OPMonitor(SPCode.messagecard_style_parse)
                            .setLevel(OPMonitorLevelError)
                            .addMap(MessageCardStyleConfig.OPMap())
                            .setErrorMessage("styleJSONString element not valid \(splits)")
                            .flush()
                    }
                }
            }
            return result.isEmpty ? nil : result
        }
        
        func parseSubStyle(json: JSON) -> [String: Any] {
            var result: [String: Any] = [:]
            var _tempResult: [String: Any] = [:]
            result[KeyStyle.keyVersion] = json[KeyStyle.keyVersion].int ?? 0
            if let styleDictionary = json[KeyStyle.keyStyle].dictionary {
                for styleKey in styleDictionary.keys {
                    guard let css = styleDictionary[styleKey]?.string else {
                        OPLogger.error("Parse Wrong Style Item \(styleKey) is Empty")
                        OPMonitor(SPCode.messagecard_style_parse)
                            .setLevel(OPMonitorLevelError)
                            .addMap(MessageCardStyleConfig.OPMap())
                            .setErrorMessage("styleJSONString Item is nil \(styleKey)")
                            .flush()
                        continue
                    }
                    guard let cssStyle = parseCSSStyle(css: css) else {
                        OPLogger.warn("Parse Wrong Style CSS \(css)")
                        OPMonitor(SPCode.messagecard_style_parse)
                            .setLevel(OPMonitorLevelError)
                            .addMap(MessageCardStyleConfig.OPMap())
                            .setErrorMessage("styleJSONString css is wrong \(css)")
                            .flush()
                        continue
                    }
                    _tempResult[styleKey] = cssStyle
                }
                result[KeyStyle.keyStyle] = _tempResult
            }
            return result
        }
        
        var result: [String: Any] = [:]
        result[KeyStyle.keyNarrow] = parseSubStyle(json: json[KeyStyle.keyNarrow])
        result[KeyStyle.keyWide] = parseSubStyle(json: json[KeyStyle.keyWide])
        return result
    }
    /// 更新远端的style
    private func fetchRemoteStyle(resolver: UserResolver,
                                  source: StyleSource = .remoteRelease,
                                  api: OpenPlatformAPI) {
        
        OPLogger.info("start fetch remote style \(source)")
        let client = try? resolver.resolve(assert: OpenPlatformHttpClient.self)
        client?.request(api: api)
            .subscribe(onNext: { [weak self] (result: GetMessageCardStyleResponse) in
                guard let self = self else {
                    return
                }
                let validCode = (source == .remoteRelease) ? (result.code == 0) : (result.code == nil)
                if validCode,
                   let _ = result.narrow,
                   let _ = result.wide {
                    OPLogger.info("fetch remote style finish \(source) \(result.narrow?[KeyStyle.keyVersion].int ?? 0) \(result.wide?[KeyStyle.keyVersion].int ?? 0)")
                    self.queue.async {
                        self.handleRemoteStyle(styleJSON: result.json, source: source)
                    }
                    return
                }
                let errorMsg = "fetch remote style error code \(source) \(String(describing: result.code)) \(result.narrow == nil) \(result.wide == nil)"
                OPLogger.error(errorMsg)
                OPMonitor(SPCode.messagecard_style_update)
                    .setLevel(OPMonitorLevelError)
                    .addMap(MessageCardStyleConfig.OPMap())
                    .setErrorMessage(errorMsg)
                    .flush()
            }, onError: { (error) in
                OPLogger.error("fetch remote style error \(source) \(error.localizedDescription)")
                OPMonitor(SPCode.messagecard_style_update)
                    .setLevel(OPMonitorLevelError)
                    .addMap(MessageCardStyleConfig.OPMap())
                    .setErrorMessage(error.localizedDescription)
                    .flush()
            }).disposed(by: disposeBag)
    }
    /// 处理结果
    private func handleRemoteStyle(styleJSON: JSON, source: StyleSource = .remoteRelease) {
        OPLogger.info("handleRemoteStyle wide:\(styleJSON[KeyStyle.keyWide][KeyStyle.keyVersion]) narrow:\(styleJSON[KeyStyle.keyNarrow][KeyStyle.keyVersion]) \(source)")
        if Self.enableDetailLog() {
            OPLogger.info("handleRemoteStyle handle response \(styleJSON) \(source)")
        }
        if let rawString = styleJSON.rawString(),
           let style = self.parseStyle(styleJSONString: rawString) {
            let codingObject: NSCoding = style as NSCoding
            OPLogger.info("handleRemoteStyle save style \(source)")
            styleLock.action {
                let key = (source == .remoteRelease) ? MessageCardStyleConfig.key() : MessageCardStyleConfig.grayKey()
                OPMessageCardStyleCache().set(object: codingObject,
                                              forKey: key)
            }
            loadStyle()
            OPMonitor(SPCode.messagecard_style_update)
                .setLevel(OPMonitorLevelNormal)
                .addMap(MessageCardStyleConfig.OPMap())
                .addCategoryValue("handleRemoteStyle", "success")
                .addCategoryValue("source", "\(source)")
                .flush()
        } else {
            OPLogger.error("handleRemoteStyle error, parse error \(source)")
            OPMonitor(SPCode.messagecard_style_update)
                .setLevel(OPMonitorLevelError)
                .addMap(MessageCardStyleConfig.OPMap())
                .addCategoryValue("source", "\(source)")
                .setErrorMessage("handleRemoteStyle style not valid")
                .flush()
        }
    }
    /// 设置更新任务
    private var lastChangedUserID: TempObject<String>?
    public func setupLoadTask(resolver: UserResolver) {
        OPLogger.info("setupLoadTask")
        MessageCardStyleConfig.setup(resolver: resolver)
        loadSettings()
        AccountServiceAdapter
            .shared
            .currentAccountObservable
            .subscribe(onNext: { [weak self] (account) in
                guard let `self` = self else {
                    return
                }
                if self.lastChangedUserID?.value == account.userID {
                    OPLogger.info("setupLoadTask not start for changed \(account.userID)")
                    return
                }
                /// 12h 失效，可以再请求一次
                self.lastChangedUserID = TempObject<String>(value: account.userID,
                                                            expireInteval: 12 * 60 * 60)
                OPLogger.info("setupLoadTask start for changed \(account.userID)")
                OPMonitor(SPCode.messagecard_style_update)
                    .setLevel(OPMonitorLevelNormal)
                    .addMap(MessageCardStyleConfig.OPMap())
                    .flush()
                RunloopDispatcher.shared.addTask {
                    if self.shoudGrayStyle(),
                       let url = self.settingConfig?[KeyStyle.KeyGrayName] as? String {
                        if OPNetworkUtil.cardUseECONetworkEnabled() {
                            self.fetchRemoteGrayStyleService(resolver, url: url)
                        } else {
                            self.fetchRemoteGrayStyle(resolver: resolver, url: url)
                        }
                    } else {
                        if OPNetworkUtil.cardUseECONetworkEnabled() {
                            self.fetchRemoteMsgCardStyleService(resolver)
                        } else {
                            let api: OpenPlatformAPI = OpenPlatformAPI.getMessageCardStyleAPI(resolver: resolver)
                            self.fetchRemoteStyle(resolver: resolver, api: api)
                        }
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func fetchRemoteGrayStyleService(_ resolver: UserResolver, url: String) {
        fetchRemoteStyleService(resolver, get: true, url: url, use: false, source: .remoteGray)
    }
    
    private func fetchRemoteMsgCardStyleService(_ resolver: UserResolver) {
        guard let url = OPNetworkUtil.getCardStyleURL() else {
            OPLogger.error("get message card style url is not exist")
            return
        }
        fetchRemoteStyleService(resolver, get: false, url: url, use: true, source: .remoteRelease)
    }
    
    private func fetchRemoteStyleService(_ resolver: UserResolver, get method: Bool, url: String, use session: Bool, source: StyleSource) {
        var header: [String: String] = [APIHeaderKey.Content_Type.rawValue: "application/json"]
        if session == true {
            header[APIHeaderKey.X_Session_ID.rawValue] = self.sessionKey(resolver)
        }
        let context = OpenECONetworkContext(trace: OPTraceService.default().generateTrace(), source: .other)
        let completionHandler: (ECOInfra.ECONetworkResponse<[String: Any]>?, ECOInfra.ECONetworkError?) -> Void = { [weak self] response, error in
            let path: String = response?.request.url?.path ?? ""
            guard let self = self else {
                OPLogger.error("fetch remote style \(path) failed because self is nil")
                return
            }
            if let error = error {
                OPLogger.error("fetch remote style \(path) failed source:\(source), error:\(error.localizedDescription)")
                OPMonitor(SPCode.messagecard_style_update)
                    .setLevel(OPMonitorLevelError)
                    .addMap(MessageCardStyleConfig.OPMap())
                    .setErrorMessage(error.localizedDescription)
                    .flush()
                return
            }
            guard let response = response,
                  let result = response.result else {
                OPLogger.error("fetch remote style \(path) failed because response or result is nil")
                return
            }
            OPNetworkUtil.reportLog(OPLogger, response: response)
            
            let json = JSON(result)
            if let code = json["code"].int, code == 0,
               let narrow = json["narrow"].dictionary,
               let wide = json["wide"].dictionary {
                OPLogger.info("fetch remote style finish \(source) \(narrow[KeyStyle.keyVersion]?.int ?? 0) \(wide[KeyStyle.keyVersion]?.int ?? 0)")
                self.queue.async {
                    self.handleRemoteStyle(styleJSON: json, source: source)
                }
                return
            }
            
            let errorMsg = "fetch remote style error code \(source) \(json["code"].int ?? -1) \(json["narrow"].dictionary == nil) \(json["wide"].dictionary == nil)"
            OPLogger.error(errorMsg)
            OPMonitor(SPCode.messagecard_style_update)
                .setLevel(OPMonitorLevelError)
                .addMap(MessageCardStyleConfig.OPMap())
                .setErrorMessage(errorMsg)
                .flush()
        }
        var serviceTask: ECOInfra.ECONetworkServiceTask<[String : Any]>? = nil
        if method == true {
            serviceTask = Self.service.get(url: url, header: header, params: [:], context: context, requestCompletionHandler: completionHandler)
        } else {
            serviceTask = Self.service.post(url: url, header: header, params: [:], context: context, requestCompletionHandler: completionHandler)
        }
        if let task = serviceTask {
            Self.service.resume(task: task)
        } else {
            OPLogger.error("fetch remote style url econetwork task failed")
        }
    }
    
    private func sessionKey(_ resolver: UserResolver) -> String? {
        guard let userService = try? resolver.resolve(assert: PassportUserService.self) else {
            OPLogger.error("MessageCardStyleManager PassportUserService impl is nil")
            return nil
        }
        return userService.user.sessionKey
    }
}
/// FG 是否使用端上样式
extension MessageCardStyleManager {
    public static func enableDetailLog() -> Bool {
        #if DEBUG
        return true
        #endif
        let fgKey = FeatureGatingKey.messageCardDetailLog
        return LarkFeatureGating.shared.getFeatureBoolValue(for: fgKey, defaultValue: false)
    }
    public static func enableGrayStyle() -> Bool {
        #if DEBUG
        return true
        #endif
        let fgKey = FeatureGatingKey.messageCardEnableGrayStyle
        return LarkFeatureGating.shared.getFeatureBoolValue(for: fgKey, defaultValue: false)
    }
}
/// 样式缓存
extension MessageCardStyleManager: StyleCache {
    static var cache = NSCache<NSString, StructWrapper<[String: String]>>()
    public func cacheStyle(key: String, style: [String: String]) {
        Self.cache.setObject(StructWrapper<[String : String]>(style),
                             forKey: key as NSString)
    }
    public func styleForKey(key: String) -> [String: String]? {
        let value = Self.cache.object(forKey: key as NSString)
        return value?.content
    }
    func clearStyleCache() {
        Self.cache.removeAllObjects()
        OPLogger.info("mergeSyle then clear style cache")
        OPMonitor(SPCode.messagecard_style_manage)
            .setLevel(OPMonitorLevelNormal)
            .addMap(MessageCardStyleConfig.OPMap())
            .addCategoryValue("event", "clearStyleCache")
            .flush()
    }
}

/// 灰度样式
extension MessageCardStyleManager {
    private func fetchRemoteGrayStyle(resolver: UserResolver, url: String) {
        OPLogger.info("fetch remote gray style \(url)")
        let api = OpenPlatformAPICustomURL(path: .empty, customUrl: url, resolver: resolver).setMethod(.get)
        let _ = self.fetchRemoteStyle(resolver: resolver, source: .remoteGray, api: api)
    }
    
    private func shoudGrayStyle() -> Bool {
        guard MessageCardStyleManager.enableGrayStyle() else {
            return false
        }
        guard let config = settingConfig,
              let _ = config[KeyStyle.KeyGrayName] else {
            return false
        }
        return true
    }
    private func loadSettings() {
        let grayConfig = ECOConfig.service().getDictionaryValue(for: "messagecard_style")
        OPLogger.info("grayConfig \(String(describing: grayConfig))")
        self.settingConfig = grayConfig
    }
}
typealias StyleObj = MessageCardStyleManager.StyleContent
class LocalStyleUpdater {
    var hardStyle: [String: [String: String]] {
        /// 按钮文字改为regular
        let normalFont: [String: String] = ["fontWeight": "normal"]
        /// image圆角改为8
        let imgRadius: [String: String] = ["borderRadius": "8"]
        return ["block_button_txt_default": normalFont,
                "block_button_txt_primary": normalFont,
                "block_button_txt_danger": normalFont,
                "block_button_txt_default_disable": normalFont,
                "block_button_txt_primary_disable": normalFont,
                "block_button_txt_danger_disable": normalFont,
                "md_img": imgRadius,
                "block_div_ext_image": imgRadius,
                "block_image": imgRadius,
                "block_image_fit": imgRadius]
    }
    
    func applyLocalStyle(inputStyle: [String: Any]?) -> [String: Any]? {
        guard !hardStyle.isEmpty,
              let inputStyleDic = inputStyle?[KeyStyle.keyStyle] as? [String: Any] else {
            return inputStyle
        }
        var resultStyleDic = [String: Any]()
        _ = inputStyleDic.map({
            if let itemDic = $0.value as? [String: String],
               let updateDic = hardStyle[$0.key] {
                resultStyleDic[$0.key] = itemDic.merging(updateDic, uniquingKeysWith: { _, new in
                    return new
                })
            } else {
                resultStyleDic[$0.key] = $0.value
            }
        })
        var resultStyle = inputStyle
        resultStyle?[KeyStyle.keyStyle] = resultStyleDic
        return resultStyleDic.isEmpty ? inputStyle : resultStyle
    }
    func filter(content: StyleObj) -> StyleObj {
        let narrowStyle = applyLocalStyle(inputStyle: content.narrow)
        let wide = applyLocalStyle(inputStyle: content.wide)
        var styleDic = content.style
        styleDic[KeyStyle.keyNarrow] = narrowStyle
        styleDic[KeyStyle.keyWide] = wide
        return StyleObj(style: styleDic)
    }
}

class TempObject<T> {
    var boxvalue: T?
    var value: T? {
        set {
            boxvalue = newValue
            updateDate = Date()
        }
        get {
            let timeoff = Date().timeIntervalSince(updateDate)
            if timeoff >= expireInteval {
                return nil
            }
            return boxvalue
        }
    }
    private var updateDate: Date
    private let expireInteval: TimeInterval
    
    init(value: T,
         expireInteval: TimeInterval) {
        self.expireInteval = expireInteval
        self.updateDate = Date()
        self.value = value
    }
}
