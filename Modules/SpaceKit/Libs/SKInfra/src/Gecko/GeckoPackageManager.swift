//
//  GeckoPackageManager.swift
//  SpaceKit
//
//  Created by Webster on 2018/11/14.
//  swiftlint:disable file_length


import SKFoundation
import OfflineResourceManager
import LarkAppConfig
import SSZipArchive
import LibArchiveKit
import RxSwift
import LarkReleaseConfig
import UniverseDesignToast
import EENavigator
import RxRelay
import LarkKAFeatureSwitch
import EEAtomic
import SKResource
import RunloopTools
import SpaceInterface
import LarkContainer

public final class GeckoPackageManager {
    typealias PkgInfo = (version: String, folder: SKFilePath)
    typealias FullPkgInfo = (version: String, folder: SKFilePath, isExist: Bool)
    /// singleton
    public static let shared = GeckoPackageManager()
    var geckoAgent: TTGeckoAbility?
    public var locatorMapping = ThreadSafeDictionary<GeckoChannleType, OfflineResourceLocator>()
    //ThreadSafeDictionary
    //gecko base config
    private(set) var accessKey = OpenAPI.DocsDebugEnv.geckoAccessKey
    private var channels: [DocsChannelInfo] = []
    private var deviceId: String?
    private var appVersion: String = SpaceKit.version
    private var channelMappings: [GeckoChannleType: DocsChannelInfo] = [: ]
    private var timer: Timer?
    private var disableGeckoUpdate: Bool = false
    private let lastGeckoRequestVersionKey = "com.bytedance.ee.docs.geckoPackageVersion"
    private var md5Checker: GeckoMD5Checker?
    private var lastUpdateTimeInterval: TimeInterval?
    private let unknowVersion = "unknow"
    private var syncingChannels: [String] = []
    private let unzipLock = NSLock()
    public private(set) var hasConfigured = false
    public var currentUsingAppChannel: GeckoPackageAppChannel = .unknown
    var geckoReadyChannels: [DocsChannelInfo] = []
    var disposeBagForWebInfoApply = DisposeBag()
    var curDownloadingChannel: DocsChannelInfo?
    var curDownloadingChannelForGrayscale: DocsChannelInfo?
    var disposeBagForGrayscaleApply = DisposeBag()

    let disposeBag = DisposeBag()
    let downloadZipPkgName = "docs_fe_package.zip"
    let revisionFile = "current_revision"
    private let serialQueue: DispatchQueue = DispatchQueue(label: "com.docs.GeckoPackageManager")

    public let fePkgReadyObserverble = BehaviorRelay<Bool>(value: false)

    @AtomicObject
    var pkgDownloadTasks: [PackageDownloadTask] = []

    /// 用于记录ResourceService在前端资源包中没有找到的文件名，下载好之后看看是否要保存到指定目录
    private var notFoundInLocalFileSet = ThreadSafeSet<String>()

    //请求更新的时候是否考虑热更间隔的时间， true的时候表示不用考虑热更时间，积极地请求热更资源 线上一直是关闭的 是false
    private var updateActively: Bool {
        return false
    }

    lazy var eventListeners: ObserverContainer<GeckoEventListener> = {
        return ObserverContainer<GeckoEventListener>()
    }()

    let needRecordSources: [ResourceSource] = [.fullPkg, .grayscaleFull]
    
    // 对 filePathsPlistName 这个plist文件内容的内存缓存
    private var filePathsPlistCache: [String: String]?
    
    private init() {
        listenNotification()
    }

    deinit {
        killTimer()
        removeNotification()
    }

    public func setupConfig(config: GeckoInitConfig) {
        GeckoLogger.info("setupConfig begin")
        // ka 私有化环境，关闭gecko
        if SKFoundationConfig.shared.isInDocsApp || UserScopeNoChangeFG.HYF.gurdFixEnable {
            //我们都用TTGeckoLarkImpl进行初始化, TTGeckoRawImpl是直接调用Gecko库，是备份测试用的
            geckoAgent = config.shouldSetUp ? TTGeckoRawImpl() : TTGeckoLarkImpl()
        }
        geckoAgent?.setup(by: "1944")
        channels = config.channels
        deviceId = config.deviceId
        appVersion = config.appVersion ?? SpaceKit.version

        let pkgChannel = config.channels.first { channelInfo -> Bool in
            return channelInfo.type == .webInfo
        }.map { (info) -> GeckoPackageAppChannel in
            return GeckoPackageAppChannel(rawValue: info.name) ?? .unknown
        }
        currentUsingAppChannel = pkgChannel ?? .unknown

        //init md5 checker
        let checkChannels = channels.filter { $0.type == .webInfo } //目前只针对docs资源包进行校验
        md5Checker = GeckoMD5Checker(channels: self.channels,
                                     checkChannels: checkChannels,
                                     dataSource: self,
                                     delegate: self)
        if let realDeviceId = deviceId {
            geckoAgent?.setDeviceID(realDeviceId)
        }
        //register
        channels.map { (type, name, _, _) -> GeckoBizConfig in
            return GeckoBizConfig(identifier: type.identifier(), key: accessKey, channel: name)
        }.forEach {
            geckoAgent?.registerBiz($0)
        }
        if !UserScopeNoChangeFG.HZK.fullPkgUnzipOptimize {
            //检查是否有下发清除清除资源包
            checkResourcePkgSetting()
        }
        //清除升级缓存
        cleanOldPackageIfNeed()
        //如果配置了zip资源，要把资源解压到沙箱，并保证沙箱的资源版本跟zip一样
        unzipResToSandboxIfNeed()
        //如果有需要把downloadPath里的资源更新到backupPath
        tryMoveGeckoFromOriginalToBackupIfNeedAfterSetup(allChannels: channels)
        //更新当前资源信息
        refershAllLocator()
        checkWebInfoVaild()
        hasConfigured = true
        GeckoLogger.info("setupConfig done")
    }

    public func setupDevice(device: String) {
        self.deviceId = device
        geckoAgent?.setDeviceID(device)
    }

    public func setDomain(_ domain: String) {
        // 如果accessKey国内外不变，可以直接设置
        geckoAgent?.setDomain(domain)
    }

    public func syncResourcesIfNeeded(throttle: Bool = true) {
        syncResourcesIfNeeded(throttle: throttle) { (_, _) in }
    }

    public func disableUpdate(disable: Bool) {
        disableGeckoUpdate = disable
    }

    func syncResourcesIfNeeded(throttle: Bool, completion: @escaping (Bool, String) -> Void) {
        
        //KA审核被拒，屏蔽热更包下载
        GeckoLogger.info("KA audit rejected，Forbid downloading regeng package")
        return
        
//      前面已经直接retrun屏蔽了，暂时先屏蔽掉根据账号单独屏蔽的代码
//        guard let userId = User.current.info?.userID else {
//            GeckoLogger.info("gecko will not request，userId is nill，loginout")
//            return
//        }
//
        //默认配置审核账号
//        let enable = SettingConfig.ccmRegengBlackListConfig?.enable ?? true //默认开启
//        let blackListUid = SettingConfig.ccmRegengBlackListConfig?.blackListUid ?? ["6751285087624495372"]
//
//        if enable, blackListUid.contains(userId) {
//            GeckoLogger.info("gecko blacklist enabel，and match the blacklist")
//            return
//        }
     
        guard !disableGeckoUpdate else {
            GeckoLogger.info("设置面板关闭了gecko请求")
            return
        }
        guard hasConfigured else {
            GeckoLogger.info("gecko还没配置呢")
            return
        }
        if throttle && (timeThrottleAllowReq() == false) {
            GeckoLogger.info("请求节流")
            return
        }
        GeckoLogger.info("请求更新gecko")
        if !syncingChannels.isEmpty {
            GeckoLogger.info("正在请求中")
            return
        }
        syncingChannels = channels.map({ return $0.type.identifier() })
        geckoReadyChannels.removeAll()
        killTimer()
        md5Checker?.cleanCheckResult()
        channels.forEach {
            geckoAgent?.fetchResource(by: $0.type.identifier(),
                                      resourceVersion: appVersion,
                                      customParams: nil,
                                      completed: { [weak self] (finish, result) in
                                        let cacheStatus: OfflineResourceStatus = self?.geckoAgent?.resourceStatus(for: result.config.identifier) ?? .notReady
                                        if finish, result.isSuccess, cacheStatus == .ready {
                                            GeckoLogger.info("gecko_hotfix:\(result.config.identifier) gecko接口请求完成")
                                            self?.updateReadyChannel(result.config)
                                        } else {
                                            GeckoLogger.info("gecko_hotfix:\(result.config.identifier) gecko返回:没有拉取到新资源")
                                        }
                                        self?.syncingChannels.removeAll { return $0 == result.config.identifier }
                                        self?.lastUpdateTimeInterval = Date().timeIntervalSince1970
            })
        }

        restartTimer()
    }

    private func updateReadyChannel(_ config: GeckoBizConfig) {
        let info = self.channels.first { return $0.type.identifier() == config.identifier }
        guard let readyInfo = info else { return }
        geckoReadyChannels.append(readyInfo)
        DispatchQueue.global().async {
            if self.shouldReportUpdateWhenReceiveGecko(readyInfo) {
                DispatchQueue.main.async {
                    self.tryApplyPackageProcess(item: readyInfo)
                }
            }
        }
    }

    func shouldReportUpdateWhenReceiveGecko(_ channel: DocsChannelInfo) -> Bool {
        //对比版本号，大版本再触发update
        let geckoDownloadVersion = geckoDownloadPathVersion(channel)
        let geckoBackupVersion = geckoBackUpPathVersion(channel)

        if geckoBackupVersion == nil {
            GeckoLogger.info("none gecko backup, should update, downloadVersion=\(String(describing: geckoDownloadVersion))")
            return true
        } else if geckoDownloadVersion == nil {
            GeckoLogger.info("none gecko download, no need update")
            return false
        } else if let bVersion = geckoBackupVersion, let dVersion = geckoDownloadVersion {
            let bigger = bVersion.compare(dVersion, options: .numeric) == .orderedAscending
            GeckoLogger.info("download bigger \(bigger) b: \(bVersion) d: \(dVersion)")
            return bigger
        }

        return true
    }


    private func checkWebInfoVaild() {
        //只检测docs资源的热更包
        guard let locator = locatorMapping.value(ofKey: .webInfo),
              locator.source == .hotfix,
              let channel = channels.first(where: { return $0.type == .webInfo }) else { return }
        let result = md5Checker?.checkTarget(channel: channel)
        if let result = result, !result.pass {
            //清空backup path
            let geckoBackupPath = GeckoPackageManager.Folder.geckoBackupPath(channel: channel.name)
            if geckoBackupPath.exists {
                do {
                    DocsLogger.info("delete file:\(geckoBackupPath)")
                    try geckoBackupPath.removeItem()
                } catch let error {
                    //移除热更路径失败
                    GeckoLogger.info("Failed to remove a hot path \(error)")
                }
            }
            //重新刷新locator
            logMd5BadCase(result: result, channel: channel.name, stage: "launch")
            refreshOfflineResourceLocator(channel)
            GeckoLogger.info("热更的资源启动校验不通过 \(result.failReason)")
        }
    }

    func geckoDownloadPathVersion(_ channel: DocsChannelInfo) -> String? {
        guard let agent = geckoAgent, let rootPath = agent.resourceRootFolderPath(identifier: channel.type.identifier()) else {
            GeckoLogger.info("fail to find gecko service")
            return nil
        }
        let zipInfo = OfflineResourceZipInfo.info(by: channel)
        let geckoDownloadPath = rootPath + "/" + zipInfo.channelName
        let geckoDownloadVersion = GeckoPackageManager.Folder.revision(in: SKFilePath(absPath: geckoDownloadPath))
        return geckoDownloadVersion
    }

    private func geckoBackUpPathVersion(_ channel: DocsChannelInfo) -> String? {
        let geckoBackupFolder = GeckoPackageManager.Folder.geckoBackupPath(channel: channel.name)
        guard geckoBackupFolder.exists else {
            GeckoLogger.info("fail to find geckoBackupPath")
            return nil
        }
        let zipInfo = OfflineResourceZipInfo.info(by: channel)
        let geckoBackupPath = geckoBackupFolder.appendingRelativePath(zipInfo.channelName)
        let geckoBackupVersion = GeckoPackageManager.Folder.revision(in: geckoBackupPath)
        return geckoBackupVersion
    }


    /// 是否使用指定资源包
    ///
    /// - Parameter type: channel name
    /// - Returns:
    public func isUsingSpecial(_ type: GeckoChannleType) -> Bool {
        return SpecialVersionResourceService.isUsingSpecial(type)
    }

    /// debug面板是否指定强制使用精简包，优先级低于 手动使用指定版本
    func isforceUsingSimplePkg() -> Bool {
        return SpecialVersionResourceService.isUseSimplePackage()
    }

    /// 当前版本
    ///
    /// - Parameter type: Channel类
    /// - Returns: 当前channel对应的资源包版本
    public func currentVersion(type: GeckoChannleType) -> String {
        guard let info = locatorMapping.value(ofKey: type) else { return unknowVersion }
        return info.version
    }

    public func insideBundleVersion(type: GeckoChannleType) -> String {
        guard let channel = channels.first(where: { $0.type == type }) else { return unknowVersion }
        return currentBundleInfo(channel).version
    }

    /// 资源的最终访问路径(已经考虑了使用指定离线资源包的情况)
    ///
    /// - Parameter channel: gecko channel
    /// - Returns: channel资源的最终路径
   public func filesRootPath(for channel: GeckoChannleType) -> SKFilePath? {
        guard let info = locatorMapping.value(ofKey: channel) else {
            GeckoLogger.error("locatorMapping get nil, channel=\(channel)")
            //正常不该走到这里，加个asser关注下
            spaceAssertionFailure("locatorMapping get nil, channel=\(channel), contact huangzhikai or lijuyou")
            return nil
        }
        let rootFolder = info.rootFolder
        spaceAssert(!rootFolder.pathString.isEmpty)
        return rootFolder
    }

    private func tryMoveGeckoFromOriginalToBackupIfNeedAfterSetup(allChannels: [DocsChannelInfo]) {
        
        let lauchUpdateChannels = CCMKeyValue.globalUserDefault.dictionary(forKey: UserDefaultKeys.geckoLauchUpdateChannels) ?? [:]

        GeckoLogger.info("tryMoveGeckoSetup, dic=\(lauchUpdateChannels)")
        lauchUpdateChannels.keys.forEach { (identify) in
            let updateChanels = allChannels.filter { $0.type.identifier() == identify }
            updateChanels.forEach { (channel) in
                tryMoveGeckoFromOriginalToBackup(channel: channel, lauchUpdate: true)
            }
        }
        CCMKeyValue.globalUserDefault.set(nil, forKey: UserDefaultKeys.geckoLauchUpdateChannels)
    }

    ///
    /// - Parameter channel:
    func tryMoveGeckoFromOriginalToBackup(channel: DocsChannelInfo, lauchUpdate: Bool) {
        guard let agent = geckoAgent, let rootPath = agent.resourceRootFolderPath(identifier: channel.type.identifier()) else {
            GeckoLogger.info("tryMoveGecko agent=\(String(describing: geckoAgent)), rootPath=nil")
            return
        }
        let geckoBackupPath = GeckoPackageManager.Folder.geckoBackupPath(channel: channel.name)
        let type = channel.type
        GeckoLogger.info("\(type.channelName())尝试替换gecko的资源到目标路径, lauchUpdate=\(lauchUpdate)")
        //gecko库下发的路径
        let zipInfo = OfflineResourceZipInfo.info(by: channel)
        let geckoPath = SKFilePath.init(absPath: rootPath).appendingRelativePath(zipInfo.channelName)
        //gecko的备份使用路径
        let dstPath = geckoBackupPath.appendingRelativePath(zipInfo.channelName)
        GeckoLogger.info("geckoPath=\(geckoPath.pathString), dstPath=\(dstPath.pathString), zipInfo.channelName=\(zipInfo.channelName)")
        GeckoLogger.info("geckoPathContent= \(String(describing: try? geckoPath.subpathsOfDirectory()))")
        let geckoRNPath = geckoPath.appendingRelativePath("rn")
        GeckoLogger.info("geckoRNContent= \(String())")
        let version = GeckoPackageManager.Folder.moveGeckoFileIfNeed(channel: channel, geckoPath: geckoPath, dstPath: dstPath)
        if version != nil {
            GeckoLogger.info("热更完成最终使用版本 \(String(describing: version)), lauchUpdate=\(lauchUpdate)")
        }
    }
}

// MARK: - event listener
extension GeckoPackageManager {
    public func addEventObserver(obj: GeckoEventListener) {
        self.eventListeners.add(obj)
    }

    public func removeEventObserver(obj: GeckoEventListener) {
        self.eventListeners.remove(obj)
    }
}

// MARK: - resource copy and version manager
extension GeckoPackageManager {

    class func bundle(from path: String) -> Bundle? {
        let pathBase = GeckoPathBase.pathWithString(pathInfo: path)
        if let bundleName = pathBase.bundleName,
            let url = Bundle.main.url(forResource: bundleName, withExtension: nil) {
            return Bundle(url: url)
        } else {
            spaceAssertionFailure("根据此路径无法构建资源:\(path)")
            return nil
        }
    }

}

// MARK: - 自动更新资源的策略 定时更新
extension GeckoPackageManager {
    private func listenNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterForegound),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(settingConfigFinishRequest),
                                               name: Notification.Name.minaConfigFinishRequest,
                                               object: nil)
    }
    private func removeNotification() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.minaConfigFinishRequest, object: nil)
    }

    private func timeThrottleAllowReq() -> Bool {
        //如果fg打开积极请求热更，就不节流， 返回true
        if updateActively { return true }
        if let lastTime = lastUpdateTimeInterval {
            let reqInterval = Date().timeIntervalSince1970 - lastTime
            let allow = reqInterval > OpenAPI.resouceUpdateInterval
            return allow
        } else {
            //第一次请求，允许放行
            return true
        }
    }

    @objc
    private func didEnterBackground() {
        killTimer()
    }

    @objc
    private func didEnterForegound() {
        syncResourcesIfNeeded(throttle: true)
        restartTimer()
    }

    private func restartTimer() {
        //开关，积极热更的时候才开启定时器 OpenAPI.offlineConfig.resouceUpdateInterval
        //观察热更率会不会下跌，如果没问题准备去除定时器
        guard updateActively else { return }
        killTimer()
        timer = Timer.scheduledTimer(timeInterval: 300,
                                     target: self,
                                     selector: #selector(timerToUpdateInfo),
                                     userInfo: nil,
                                     repeats: true)
    }

    private func killTimer() {
        timer?.invalidate()
        timer = nil
    }

    @objc
    private func timerToUpdateInfo() {
        syncResourcesIfNeeded(throttle: false)
    }

}


// 缓存清除逻辑
extension GeckoPackageManager {
    /// 新版本启动，先清空缓存，去除升级的影响
    private func cleanOldPackageIfNeed() {

        clearPkgDownloadPath()

        var shouldClean = shouldCleanOldPkg()
        let needClearAllFEPkg = CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.needClearAllFEPkg)
        if needClearAllFEPkg {
            shouldClean = true
        }
        //如果没有老版本的记录，或者老版本记录跟当前版本记录不一致，就执行缓存清空的动作
        guard shouldClean else {
            CCMKeyValue.globalUserDefault.set(appVersion, forKey: lastGeckoRequestVersionKey)
            return
        }
        GeckoLogger.info("检测到新版本，清空gecko缓存")

        CCMKeyValue.globalUserDefault.set(nil, forKey: UserDefaultKeys.lastUnzipEESZZipVersion)

        CCMKeyValue.globalUserDefault.set(nil, forKey: UserDefaultKeys.geckoLauchUpdateChannels)

        channels.forEach { geckoAgent?.clearCache(for: $0.type.identifier()) }

        //3.15新加的gecko缓存路径, 版本升级也要进行清除
        let folderPath = GeckoPackageManager.Folder.geckoBackupPath(channel: nil)
        removeFiles(at: folderPath, logTag: "gecko backup")

        // 清除老的精简包
        let simplePkgPath = GeckoPackageManager.Folder.simpleBundleBackupPath(channel: nil)
        removeFiles(at: simplePkgPath, logTag: "simplePkgPath backup")

        // 移除完整包
        removeFullPkgOnDisk()

        // 移除灰度包
        removeGrayscalePkgOnDisk()
        CCMKeyValue.globalUserDefault.set(appVersion, forKey: lastGeckoRequestVersionKey)

        let bundleFullPkg = GeckoPackageManager.Folder.bundleBackupPath(channel: nil)
        removeFiles(at: bundleFullPkg, logTag: "bundleFullPkg backup")

        let saviorPkgPath = GeckoPackageManager.Folder.saviorBackupPath(channel: nil)
        removeFiles(at: saviorPkgPath, logTag: "savior package clearUnuse")
        CCMKeyValue.globalUserDefault.set(false, forKey: UserDefaultKeys.needClearAllFEPkg)
        
    }

    /// 移除完整包，debug面板也用, public是为了在SpaceDemo里面也能用
    @discardableResult
    public func removeFullPkgOnDisk() -> Bool {
        let fullPkgPath = GeckoPackageManager.Folder.fullPkgBackupPath(channel: nil)
        let success1 = removeFiles(at: fullPkgPath, logTag: "fullPkgPath backup")

        let fullPkgUnzipPath = GeckoPackageManager.Folder.fullPkgUnzipPath(channel: nil)
        let success2 = removeFiles(at: fullPkgUnzipPath, logTag: "fullPkgUnzipPath backup")

        let fullPkgZipFolderPath = GeckoPackageManager.Folder.fullPkgZipDownloadPath(channel: nil)
        let success3 = removeFiles(at: fullPkgZipFolderPath, logTag: "fullPkgZipPath backup")

        let finalSuccess = success1 && success2 && success3
        GeckoLogger.info("移除本地所有的完整包资源，结果:\(finalSuccess), 详情fullPkgPath:\(success1), fullPkgUnzipPath:\(success2), fullPkgZipPath:\(success3)")
        return finalSuccess
    }

    /// 移除灰度包，debug面板也用, public是为了在SpaceDemo里面也能用
    @discardableResult
    public func removeGrayscalePkgOnDisk() -> Bool {
        let grayscalePkgPath = GeckoPackageManager.Folder.grayscalePkgBackupPath(channel: nil)
        let success1 = removeFiles(at: grayscalePkgPath, logTag: "grayscalePkgPath backup")

        let grayscalePkgUnzipPath = GeckoPackageManager.Folder.grayscalePkgUnzipPath(channel: nil)
        let success2 = removeFiles(at: grayscalePkgUnzipPath, logTag: "grayscalePkgUnzipPath backup")

        let grayscalePkgZipPath = GeckoPackageManager.Folder.grayscalePkgZipDownloadPath(channel: nil)
        let success3 = removeFiles(at: grayscalePkgZipPath, logTag: "grayscalePkgZipPath backup")

        let finalSuccess = success1 && success2 && success3
        let msg = "移除本地所有的灰度包资源，结果:\(finalSuccess), 详情grayscalePkgPath:\(success1), grayscalePkgUnzipPath:\(success2), grayscalePkgZipPath:\(success3)"
        GeckoLogger.info(msg)
        return finalSuccess
    }

    private func clearPkgDownloadPath(needClearGray: Bool = true) {
        //清空老的文件夹 - 不再用这个文件夹了 尝试删除 无法删除也没关系
        let dstPath = GeckoPackageManager.Folder.finalFolderPath(channel: nil)
        removeFiles(at: dstPath, logTag: "old final folder")

        // 内嵌精简包的完整包下载目录和解压目录fullpkgdownload
        let fullPkgDownloadPath = GeckoPackageManager.Folder.fullPkgDownloadRootPath(channel: nil)
        removeFiles(at: fullPkgDownloadPath, logTag: "fullPkgDownloadpath")

        // 灰度包下载和解压目录清除
        if needClearGray {
            let grayscalePkgDownloadPath = GeckoPackageManager.Folder.grayscalePkgDownloadRootPath(channel: nil)
            removeFiles(at: grayscalePkgDownloadPath, logTag: "grayscalePkgDownloadPath")
        }
    }

    private func shouldCleanOldPkg() -> Bool {
        var isVersionChange = true
        GeckoLogger.info("app当前版本：\(appVersion)")
        if let lastVersion = CCMKeyValue.globalUserDefault.string(forKey: lastGeckoRequestVersionKey) {
            GeckoLogger.info("app上次打开时的版本：\(lastVersion)")
            isVersionChange = lastVersion != appVersion
            GeckoLogger.info("app是否升级：\(isVersionChange)")
        }

        if isVersionChange { return true }

        let webInfoChannels = channels.filter { $0.type == .webInfo }
        webInfoChannels.forEach { (channel) in
            let zipInfo = OfflineResourceZipInfo.info(by: channel)
            guard zipInfo.usingZip, zipInfo.isVaild else {
                GeckoLogger.info("zip信息不合法 \(channel.type.identifier())")
                return
            }

            let curVersionInfo = GeckoPackageManager.Folder.getCurentVersionInfo(in: zipInfo.zipFileBaseFolder)
            // 如果是精简包，那么就判断精简包的版本号
            if curVersionInfo.isSlim {
                GeckoLogger.info("内嵌了精简包")
                let fullPkgUnzipPath = fullPkgUnZipPath()
                let simpleBundleUnzipPath = simpleResChannelUnZipPath(.webInfo)
                let fullPkgBkInfo = getCurrentRevisionInfo(in: fullPkgUnzipPath)
                let simpleBkInfo = getCurrentRevisionInfo(in: simpleBundleUnzipPath)
                GeckoLogger.info("解压后的完整包current_revision:\(fullPkgBkInfo)")
                GeckoLogger.info("解压后的精简包current_revision:\(simpleBkInfo)")

                if fullPkgBkInfo.version != unknowVersion, fullPkgBkInfo.version != curVersionInfo.fullPkgScmVersion {
                    // 原先使用完整包，app版本升级后，该完整包版本跟新内嵌精简包指定的完整包版本可能不一致
                    isVersionChange = true
                } else if simpleBkInfo.version != unknowVersion, simpleBkInfo.version != curVersionInfo.version {
                    // 原先使用精简包，app版本升级后，该精简包版本跟新内嵌精简包版本可能不一致
                    isVersionChange = true
                }
            }

            // 如果是内嵌完整包，就判断完整包的版本号
            if !curVersionInfo.isSlim {
                GeckoLogger.info("内嵌了完整包")
                let bundleUnZipPath = bundlePkgUnZipPath()
                let bundleBkInfo = getCurrentRevisionInfo(in: bundleUnZipPath)
                if bundleBkInfo.version != unknowVersion, bundleBkInfo.version != curVersionInfo.version { isVersionChange = true }
            }
        }
        return isVersionChange
    }

    @discardableResult
    func removeFiles(at path: SKFilePath?, logTag: String) -> Bool {
        guard let folderPath = path, !folderPath.pathString.isEmpty else {
            GeckoLogger.info("[\(logTag)] path is nil，no need to delete")
            return true
        }
        let pathString = folderPath.pathString
        guard folderPath.exists else {
            GeckoLogger.info("[\(logTag)] path no exist，no need to delete，path:\(pathString)")
            return true
        }
        do {
            try folderPath.removeItem()
        } catch let error {
            GeckoLogger.info("delete [\(logTag)] path failed, path:\(pathString), error:\(error)")
            return false
        }
        GeckoLogger.info("delete [\(logTag)] path success, path: \(pathString)")
        return true
    }

    private func unzipResToSandboxIfNeed() {
        channels.forEach { unzipResToSandbox($0) }
    }

    
    private func unzipResToSandbox(_ channel: DocsChannelInfo) {
        //存在多线程操作解压流程，进行加锁操作
        if !UserScopeNoChangeFG.HZK.fullPkgUnzipOptimize {
            unzipLock.lock()
        }
        
        defer {
            if !UserScopeNoChangeFG.HZK.fullPkgUnzipOptimize {
                unzipLock.unlock()
            }
        }

        let zipInfo = OfflineResourceZipInfo.info(by: channel)
        guard zipInfo.usingZip, zipInfo.isVaild else {
            GeckoLogger.info("zip信息不合法 \(channel.type.identifier())")
            return
        }
        let curVersionInfo = GeckoPackageManager.Folder.getCurentVersionInfo(in: zipInfo.zipFileBaseFolder)
        if curVersionInfo.isSlim {
            unzipSimpleResToSandbox(channel, zipInfo: zipInfo)
            return
        }

        let versionWaitingUnZip = GeckoPackageManager.Folder.revision(in: zipInfo.zipFileBaseFolder) ?? unknowVersion
        let unzipPath = channelUnZipPath(channel.type)
        let versionHasUnZip = getCurrentRevisionInfo(in: unzipPath).version
        let shouldUnZipNow = (versionHasUnZip == unknowVersion) ||
            (versionWaitingUnZip == unknowVersion) ||
            (versionWaitingUnZip != versionHasUnZip)
        GeckoLogger.info("v_zip:\(versionWaitingUnZip) v_unzip:\(versionHasUnZip) willUnZip:\(shouldUnZipNow)")
        if shouldUnZipNow == false { return }
        GeckoLogger.info("即将解压 \(zipInfo.zipFileFullPath) to \(unzipPath)")
        let channelName = channel.type.channelName()
        let firstUnzipResult = BundlePackageExtractor.unzipBundlePkg(zipFilePath: zipInfo.zipFileFullPath, to: unzipPath)
        let firstUnzipOkay: Bool
        if case .success = firstUnzipResult {
            firstUnzipOkay = true
            notifyAfterUnzipFullPkgReadey(channel)
        } else {
            firstUnzipOkay = false
        }
        
        logZipFirstUnzipStatus(firstUnzipOkay, channel: channelName)
        if !firstUnzipOkay {
            GeckoLogger.info("解压失败，删除文件:\(unzipPath)")
            do {
                try unzipPath.removeItem()
            } catch let error {
                GeckoLogger.error("删除文件失败:\(unzipPath)", error: error)
            }
            let retryTime = 3
            for i in 0..<retryTime {
                let nextUnzipFolder = radomChangeUnzipFolder(channel.type)
                let nextUnzipPath = channelUnZipPath(channel.type)
                
                let unzipResult = BundlePackageExtractor.unzipBundlePkg(zipFilePath: zipInfo.zipFileFullPath, to: nextUnzipPath)
                let finish: Bool
                if case .success = unzipResult {
                    finish = true
                } else {
                    finish = false
                }
                
                GeckoLogger.info("触发解压重试 to:\(nextUnzipFolder) success: \(finish)")
                if finish {
                    GeckoLogger.info("重新解压成功")
                    logZipRetryUnzipStatus(true, time: i, channel: channelName)
                    notifyAfterUnzipFullPkgReadey(channel)
                    break
                } else {
                    if i != retryTime - 1 {
                        do {
                            try nextUnzipPath.removeItem()
                        } catch let error {
                            GeckoLogger.error("解压失败，删除文件:\(unzipPath)", error: error)
                        }
                    } else {
                        GeckoLogger.info("重新解压失败")
                        logZipRetryUnzipStatus(false, time: i, channel: channelName)
                    }
                }
            }
        }
    }

    @discardableResult
    func unzip(zipFilePath: SKFilePath, to unzipPath: SKFilePath, retryTime: Int? = 0) -> Bool {
        
        //逻辑说明：
        //1. 解压之前先手动清理之前的unzip文件夹，但是清理成功与否并不能block住解压流程
        //2. zip函数的参数overwrite设置成true,测试了下在没有unzipPath路径的时候会自动保证路径创建并清理之前路径里的老数据
        
        let unzipResult = BundlePackageExtractor.unzipBundlePkg(zipFilePath: zipFilePath, to: unzipPath)
        switch unzipResult {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    /// 完整包解压完成后，进行刷新通知
    private func notifyAfterUnzipFullPkgReadey(_ channel: DocsChannelInfo) {
        //fg打开，才走发通知的逻辑
        guard !UserScopeNoChangeFG.HZK.fullPkgUnzipOptimize else {
            return
        }
        GeckoLogger.info("notify After Unzip FullPkg Readey：\(channel.type)")
        self.refreshOfflineResourceLocator(channel)
        self.reportDidUpdate(type: channel.type, finish: true, needReloadRN: false)
        DocsContainer.shared.resolve(SKBrowserInterface.self)?.editorPoolDrainAndPreload()
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name.feFullPackageHasReady, object: nil)
        }
    }
    
    /// 内置精简包解压失败，则下载完整包
    private func handleInnerSlimPkgUnzipRetryFailed(error: Error?) {
        
        if let error = error {
            spaceAssertionFailure("解压内置精简包失败! error:\(error.localizedDescription)")
        }
        
        let channel: DocsChannelInfo = (.webInfo,
                                        GeckoPackageManager.shared.currentUsingAppChannel.rawValue,
                                        "SKResource.framework/SKResource.bundle/eesz-zip",
                                        GeckoPackageManager.shared.bundleSlimPkgName)
        let zipInfo = OfflineResourceZipInfo.info(by: channel)
        let versionInfo = Self.Folder.getCurentVersionInfo(in: zipInfo.zipFileBaseFolder)
        let urlStr = DomainConfig.envInfo.isChinaMainland ? versionInfo.fullPkgUrlHome : versionInfo.fullPkgUrlOversea
        let version = versionInfo.fullPkgScmVersion
        
        let type: FEResourceType = .innerZip(.simple)
        let defaultPath = getDefaultPkgPath(of: type)
        let rootPath = appendDocsChannel(to: defaultPath)
        let fullPkgPath = getFullPkgPath(of: type, defaultPath: defaultPath)
        let fullPkgDocsChannelPath = appendDocsChannel(to: fullPkgPath)
        
        var slimResInfo = FEResourceInfo()
        slimResInfo.type = type
        slimResInfo.simplePkgInfo = versionInfo
        slimResInfo.hasSimplePkg = true
        slimResInfo.fullPkgRootFolder = fullPkgPath
        slimResInfo.fullPkgRootPathForLocator = fullPkgDocsChannelPath
        slimResInfo.simplePkgRootPathForLoctor = rootPath
        slimResInfo.channel = channel
        
        let fullPkgInfo = currentFullPkgInfo(channel)
        let targetFullPkgVersion = slimResInfo.simplePkgInfo.fullPkgScmVersion
        
        if fullPkgInfo.isExist && fullPkgInfo.version == targetFullPkgVersion {
            GeckoLogger.info("已经下载了精简包对应的完整包，则不再下载")
            return
        }
        
        serialQueue.async { [weak self] in
            guard let self = self else { return }
            self.downloadFullPackageWhenUnzipBundleSlimFailed(urlStr: urlStr,
                                                              version: version,
                                                              targetSource: .fullPkg,
                                                              resourceInfo: slimResInfo,
                                                              channel: channel)
        }
    }

    func channelSaviorPath() -> SKFilePath {
        let path = GeckoPackageManager.Folder.saviorBackupPath(channel: nil)
        return appendDocsChannel(to: path)
    }

    private func radomChangeUnzipFolder(_ channelType: GeckoChannleType) -> String {
        let nextFolder = channelType.identifier() + "_" + UUID().uuidString
        serializeChannelUnZipFolder(nextFolder, channelType: channelType)
        return nextFolder
    }
    // BundleBackup
    private func channelUnZipPath(_ channelType: GeckoChannleType) -> SKFilePath {
        let bundlePath = GeckoPackageManager.Folder.bundleBackupPath(channel: nil)
        return appendDocsChannel(to: bundlePath)
    }

    private func channelUnzipFolderUserDefaultKey(_ channelType: GeckoChannleType) -> String {
        return "com.bytedance.ee.docs.bundlepath" + channelType.identifier()
    }

    private func serializeChannelUnZipFolder(_ folderName: String, channelType: GeckoChannleType) {
        let key = channelUnzipFolderUserDefaultKey(channelType)
        CCMKeyValue.globalUserDefault.set(folderName, forKey: key)
    }

    private func refershAllLocator() {
        channels.forEach { refreshOfflineResourceLocator($0, canDownloadFullPkg: false) }
    }

    //综合考虑当前的所有资源包，生成一个资源定位信息
    func refreshOfflineResourceLocator(_ channel: DocsChannelInfo, canDownloadFullPkg: Bool = true) {
        let locator: OfflineResourceLocator? = judgeWhichToUseLocatorV2(for: channel, canDownloadFullPkg: canDownloadFullPkg)

        GeckoLogger.info("刷新，使用locator：\(String(describing: locator))")
        let oldLocator = locatorMapping.value(ofKey: channel.type)
        if let locator = locator {
            checkToShowSpecialPkgTips(locator: locator)
            locatorMapping.updateValue(locator, forKey: channel.type)
            let equal = oldLocator?.equalTo(another: locator) ?? false
            if !equal {
                GeckoLogger.info("更新 locator \(channel.type) \(locator.version) \(locator.source)")
            }
            if locator.channel.rawValue != GeckoChannleType.webInfo.unzipFolder() {
                GeckoPackageManager.Folder.showPkgErrorInfo(errorChannel: locator.channel.rawValue)
            }
            
            let isLocatorVersionInvalid = (locator.version.isEmpty || locator.version == "unknow")
            if locator.source == .bundleSlim, locator.channel == .unknown, isLocatorVersionInvalid {
                GeckoLogger.info("内置精简包解压失败了! 不触发fePkgReady(下载并解压完整包后会再触发)")
            } else {
                fePkgReadyObserverble.accept(true)
            }
            
            // 删除上一个locator，保留新的locator包，判断新旧locator不是相同路径
            clearUnusePackageFilesIfNeeded(newLocator: locator, oldLocator: oldLocator, channel: channel)
        }
    }

    private func checkToShowSpecialPkgTips(locator: OfflineResourceLocator) {
        if  locator.source == .specialFull || locator.source == .specialSlim {
            // 只有研发和PM能指定资源包，这么写是为了内部debug和排查问题
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_2500) {
                // 给UI初始化一些时间，不然太快了window来不及展示
                if let mainWindow = Navigator.shared.mainSceneWindow {
                    UDToast.showTips(with: "Spacekit:【指定资源包】当前正在使用【指定资源包】", on: mainWindow)
                }
            }
            GeckoLogger.info("当前正在使用【指定】前端资源包")
        }
    }

    private func clearUnusePackageFilesIfNeeded(newLocator: OfflineResourceLocator,
                                                oldLocator: OfflineResourceLocator?,
                                                channel: DocsChannelInfo) {

        if newLocator.source != .bundleFull { // 清除老代码
            let innerFullPkgBundlePath = GeckoPackageManager.Folder.bundleBackupPath(channel: nil)
            removeFiles(at: innerFullPkgBundlePath, logTag: "innerFullPkgBundlePath clearUnuse")
        }

        // 首次设置locator不执行清除任务，后续locator更新，只有目标文件变更才清除oldLocator对应的js资源
        guard let targetLocator = oldLocator, newLocator.rootFolder != targetLocator.rootFolder else {
            if newLocator.source == .fullPkg {
                let targetPath = GeckoPackageManager.Folder.simpleBundleBackupPath(channel: nil)
                clearPkgWhenFirstSettingLocator(targetPath: targetPath)
            }
            return
        }

        // 这里要判断，要删除的目标包是否有新的下载任务，有的话，就不删
        // 找到要删除的文件路径
        var targetPath: SKFilePath?
        switch targetLocator.source {
        case .bundleFull:
            targetPath = GeckoPackageManager.Folder.bundleBackupPath(channel: nil)
        case .bundleSlim:
            targetPath = GeckoPackageManager.Folder.simpleBundleBackupPath(channel: nil)
        case .fullPkg:
            let isDownloading = !pkgDownloadTasks.filter({ !$0.isGrayscale && $0.version == targetLocator.version }).isEmpty
            if !isDownloading {
                // 没有下载任务，如果有下载任务会重新走这里
                targetPath = GeckoPackageManager.Folder.fullPkgBackupPath(channel: nil)
            }
        case .grayscaleSlim, .grayscaleFull:
            let isDownloading = !pkgDownloadTasks.filter({ $0.isGrayscale && $0.version == targetLocator.version }).isEmpty
            if !isDownloading {
                // 没有下载任务，如果有下载任务会重新走这里
                targetPath = GeckoPackageManager.Folder.fullPkgBackupPath(channel: nil)
            }
        case .specialSlim, .specialFull, .hotfix:
            break
        }
        GeckoLogger.info("try to remove pkg type: \(targetLocator.source), path: \(targetPath?.pathString)")
        clearPkgAt(targetPath: targetPath)
    }

    /// 首次设置locator时，清理simpleBundleBackup
    private func clearPkgWhenFirstSettingLocator(targetPath: SKFilePath?) {
        
        guard let deletePath = targetPath, !deletePath.pathString.isEmpty else {
            return
        }
        
        let revisionInfo = getCurrentRevisionInfo(in: deletePath)
        let sandboxSlimVersion = revisionInfo.version
        
        let channel: DocsChannelInfo = (.webInfo,
                                        GeckoPackageManager.shared.currentUsingAppChannel.rawValue,
                                        "SKResource.framework/SKResource.bundle/eesz-zip",
                                        GeckoPackageManager.shared.bundleSlimPkgName)
        let zipInfo = OfflineResourceZipInfo.info(by: channel)
        let versionInfo = Self.Folder.getCurentVersionInfo(in: zipInfo.zipFileBaseFolder)
        let bundleSlimVersion = versionInfo.version
        
        if sandboxSlimVersion != bundleSlimVersion { // 该目录无效的话才被清理，避免每次都重新解压精简包
            clearPkgAt(targetPath: targetPath)
        }
    }
    
    private func clearPkgAt(targetPath: SKFilePath?) {
        guard let deletePath = targetPath, !deletePath.pathString.isEmpty else {
            GeckoLogger.info("路径为空，无需删除")
            return
        }
        // 监听rn是否在加载bundle，加载完了再删除目标
        // 这里使用了SKInfraConfig进行反向依赖，是不太合理
        let rnReloadOK = SKInfraConfig.shared.canReloadRnObserverable
        let isLoadingLocalJSFile = SKInfraConfig.shared.isReadingLocalJSFile
        let browserVCEmpty = DocsContainer.shared.resolve(SKBrowserInterface.self)?.browsersStackIsEmptyObsevable ?? BehaviorRelay<Bool>(value: true)
        let offlineSynIdle = SKInfraConfig.shared.offlineSynIdle
        let driveStackEmpty = DocsContainer.shared.resolve(DrivePreviewRecorderBase.self)?.stackEmptyStateChanged ?? Observable<Bool>.never()

        Observable.combineLatest(browserVCEmpty, offlineSynIdle, driveStackEmpty, rnReloadOK, isLoadingLocalJSFile)
            .distinctUntilChanged({ (l, r) -> Bool in return l == r })
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .default))
            .filter({ (isBrowserVCEmpty, isOfflineSynIdle, isDriveStackEmpty, isRnRelaodOK, isLoadingLocalJSFile) -> Bool in
                return isBrowserVCEmpty && isOfflineSynIdle && isDriveStackEmpty && isRnRelaodOK && !isLoadingLocalJSFile
            })
            .take(1)
            .subscribe(onNext: { [weak self] (_, _, _, _, _) in
                self?.removeFiles(at: deletePath, logTag: "\(deletePath) clearUnuse")
            }).disposed(by: self.disposeBag)
    }

    func createResourceLocator(source: ResourceSource,
                               version: String,
                               rootFolder: SKFilePath,
                               channel: GeckoPackageAppChannel) -> OfflineResourceLocator {
        var locator = OfflineResourceLocator()
        locator.source = source
        locator.version = version
        locator.rootFolder = rootFolder
        locator.channel = channel
        return locator
    }

    private func currentGeckoInfo(_ channel: DocsChannelInfo) -> (version: String, folder: SKFilePath) {
        let zipInfo = OfflineResourceZipInfo.info(by: channel)
        let geckoChannelPath = GeckoPackageManager.Folder.geckoBackupPath(channel: channel.name)
        let versionFileFolder = geckoChannelPath.appendingRelativePath(zipInfo.channelName)
        let version = GeckoPackageManager.Folder.revision(in: versionFileFolder) ?? unknowVersion
        return (version, geckoChannelPath)
    }

    /// 找到folder下面（递归遍历出来）的current_revision文件的父级路径
    private func getCurrentRevisionFileFolder(in folder: SKFilePath) -> SKFilePath? {
        guard
            folder.exists,
            var filePath = GeckoPackageManager.shared.getFullFilePath(at: folder, of: revisionFile) else {
            return nil
        }
        //这里deletingLastPathComponent，跟replacingOccurrences(of: "/\(revisionFile)", with: "")一样
        filePath = filePath.deletingLastPathComponent
        return filePath
    }

    /// 传入资源包的顶级路径（比如以fullPkgBackup结尾的）找到内部的current_revision文件的信息
    func getCurrentRevisionInfo(in folder: SKFilePath) -> OfflineResourceZipInfo.CurVersionInfo {
        guard let filePath = getCurrentRevisionFileFolder(in: folder) else {
            return OfflineResourceZipInfo.CurVersionInfo()
        }
        return GeckoPackageManager.Folder.getCurentVersionInfo(in: filePath)
    }

    public func currentFullPkgInfo(_ channel: DocsChannelInfo) -> (version: String, folder: SKFilePath, isExist: Bool) {
        let fullPkgPath = fullPkgUnZipPath()
        let info = getCurrentRevisionInfo(in: fullPkgPath)
        return (info.version, fullPkgPath, info.isExist)
    }
    public func currentGrayscalePkgInfo(_ channel: DocsChannelInfo) -> (version: String, folder: SKFilePath, isExist: Bool) {
        let grayscalePkgPath = grayscalePkgUnZipPath()
        let info = getCurrentRevisionInfo(in: grayscalePkgPath)
        return (info.version, grayscalePkgPath, info.isExist)
    }

    /// 先获取bundle内嵌包信息，判断是不是以zip包的形式存在，是则去对应的沙盒路径获取
    /// version、path返回（理论上可能未解压到沙盒，则version是unknow）；不是则直接
    /// 返回bundle里的version、path
    private func currentBundleInfo(_ channel: DocsChannelInfo) -> (version: String, folder: SKFilePath) {
        // 测试这个方法
        let zipInfo = OfflineResourceZipInfo.info(by: channel)
        if zipInfo.usingZip {
            let unzipPath = channelUnZipPath(channel.type)
            let versionHasUnZip = getCurrentRevisionInfo(in: unzipPath).version
            return (versionHasUnZip, unzipPath)
        } else {
            return (zipInfo.version, zipInfo.zipFileBaseFolder)
        }
    }

    public func currentSimpleBundleInfo(_ channel: DocsChannelInfo) -> (version: String, folder: String, fullPkgVersion: String) {
        let unzipPath = simpleResChannelUnZipPath(channel.type)
        let info = getCurrentRevisionInfo(in: unzipPath)
        let versionHasUnZip = info.version
        return (versionHasUnZip, unzipPath.pathString, info.fullPkgScmVersion)
    }
}

extension GeckoPackageManager {
    /// 单元测试用的，别随便调用
    func unitTest_updateGeckoKey(key: String) {
        accessKey = key
    }
}

extension GeckoPackageManager {

    public func downloadFullPackageIfNeeded() {
        GeckoLogger.info("打开文档时触发去下载需要的完整包")
        // 这个要改成，尝试触发下载各个类型的完整包，
        let checkChannels = self.channels.filter { $0.type == .webInfo }
        GeckoLogger.info("checkChannels:\(channels)")
        checkChannels.forEach { (channel) in
            self.judgeWhichToUseLocatorV2(for: channel)
        }
    }

    /// 将精简包解压到指定位置，单独写一个方法出来是为了不在原来的方法中涉及路径的地方写if else，另外还能防止版本回退导致的灾难性bug, 高版本精简包回退到低版本内嵌完整包，如果路径都是一样的，那就凉透了；代码冗余就冗余吧
    func unzipSimpleResToSandbox(_ channel: DocsChannelInfo, zipInfo: OfflineResourceZipInfo) {

        let curVersionInfo = GeckoPackageManager.Folder.getCurentVersionInfo(in: zipInfo.zipFileBaseFolder)
        if ReleaseConfig.isPrivateKA {
            ///可以在这里下载到前端包： https://cloud.bytedance.net/scm/detail/14237/versions，current_version文件中的full_pkg_scm_version是完整包的版本号
            /// 技术方案：https://bytedance.feishu.cn/docs/doccnga26rV9LMCPHX050whiegc?from=from_parent_docs#oVFegy
            GeckoLogger.error("v3.29新增, KA环境下不能使用精简包，找前端要对应版本的完整包，或者自己手动下载; curVersionInfo:\(curVersionInfo)")
//            spaceAssertionFailure()
        }
        let versionWaitingZip = curVersionInfo.version
        let unzipPath = simpleResChannelUnZipPath(channel.type)
        let versionHasUnZip = getCurrentRevisionInfo(in: unzipPath).version

        var shouldUnZipNow = (versionHasUnZip == unknowVersion) ||
            (versionWaitingZip == unknowVersion) ||
            (versionWaitingZip != versionHasUnZip)

        if shouldUnZipNow,
           let lastUnzipVersion = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.lastUnzipEESZZipVersion), !lastUnzipVersion.isEmpty, lastUnzipVersion == versionHasUnZip {
            shouldUnZipNow = false
        }
        GeckoLogger.info("gecko_hotfix1: 精简包 v_zip:\(versionWaitingZip) v_unzip:\(versionHasUnZip) willUnZip:\(shouldUnZipNow)")
        if shouldUnZipNow == false { return }
        //精简包即将解压
        GeckoLogger.info("gecko_hotfix1: simple package begin unzip \(zipInfo.zipFileFullPath) \(unzipPath.pathString)")
        let channelName = channel.type.channelName()
        
        let unzipStart = CACurrentMediaTime()
        let firstUnzipResult = BundlePackageExtractor.unzipBundlePkg(zipFilePath: zipInfo.zipFileFullPath, to: unzipPath)
        let unzipDuration = CACurrentMediaTime() - unzipStart
        
        let firstUnzipOkay: Bool
        if case .success = firstUnzipResult {
            firstUnzipOkay = true
        } else {
            firstUnzipOkay = false
        }
        logZipFirstUnzipStatus(firstUnzipOkay, channel: channelName)
        if firstUnzipOkay {
            CCMKeyValue.globalUserDefault.set(versionWaitingZip, forKey: UserDefaultKeys.lastUnzipEESZZipVersion)
            trackUnzipSuccessEvent(duration: unzipDuration, localPath: unzipPath.pathString)
        } else {
            do {
                GeckoLogger.error("解压失败，删除文件夹")
                try unzipPath.removeItem()
            } catch let error {
                GeckoLogger.error("删除文件夹失败:\(unzipPath)", error: error)
            }
            let retryTime = 3
            for i in 0..<retryTime {

                let unzipStart = CACurrentMediaTime()
                let unzipResult = BundlePackageExtractor.unzipBundlePkg(zipFilePath: zipInfo.zipFileFullPath, to: unzipPath)
                let unzipDuration = CACurrentMediaTime() - unzipStart
                
                let finish: Bool
                if case .success = unzipResult {
                    finish = true
                } else {
                    finish = false
                }
                GeckoLogger.info("gecko_hotfix1: 精简包触发解压重试 to:\(unzipPath) success: \(finish)")
                if finish {
                    GeckoLogger.info("gecko_hotfix1: 精简包重新解压成功")
                    logZipRetryUnzipStatus(true, time: i, channel: channelName)
                    trackUnzipSuccessEvent(duration: unzipDuration, localPath: unzipPath.pathString)
                    break
                } else {
                    if i != retryTime - 1 {
                        do {
                            GeckoLogger.error("解压失败，删除文件夹")
                            try unzipPath.removeItem()
                        } catch let error {
                            GeckoLogger.error("删除文件夹失败:\(unzipPath)", error: error)
                        }
                    } else {
                        GeckoLogger.info("gecko_hotfix1: 精简包重新解压失败")
                        logZipRetryUnzipStatus(false, time: i, channel: channelName)
                        
                        var error: Error?
                        if case .failure(let err) = unzipResult {
                            error = err
                        }
                        handleInnerSlimPkgUnzipRetryFailed(error: error)
                        trackUnzipFailureEvent(duration: unzipDuration,
                                               localPath: unzipPath.pathString,
                                               errorDesc: error?.localizedDescription)
                    }
                }
            }
        }
    }
    
    /// 获取内嵌精简包的路径，以docs_channel结尾
    private func simpleResChannelUnZipPath(_ channelType: GeckoChannleType) -> SKFilePath {
        let simpleBkupPath = GeckoPackageManager.Folder.simpleBundleBackupPath(channel: nil)
        return appendDocsChannel(to: simpleBkupPath)
    }

    /// 获取内嵌精简包指定的完整包的路径，以docs_channel结尾
    private func fullPkgUnZipPath() -> SKFilePath {
        let fullBkupPath = GeckoPackageManager.Folder.fullPkgBackupPath(channel: nil)
        return appendDocsChannel(to: fullBkupPath)
    }
    /// 获取内嵌完整包的路径，以docs_channel结尾
    private func bundlePkgUnZipPath() -> SKFilePath {
        let bundleBkupPath = GeckoPackageManager.Folder.bundleBackupPath(channel: nil)
        return appendDocsChannel(to: bundleBkupPath)
    }
    /// 获取灰度包的路径，以docs_channel结尾
    private func grayscalePkgUnZipPath() -> SKFilePath {
        let grayscaleBkupPath = GeckoPackageManager.Folder.grayscalePkgBackupPath(channel: nil)
        return appendDocsChannel(to: grayscaleBkupPath)
    }

}

public extension GeckoPackageManager {
    enum FEResourceType {
        public enum InnerPkgType {
            case simple // 内嵌精简包
            case full // 内嵌完整包
            case downloadFull // 根据内嵌精简包指定url下载的完整包
        }
        case unkown
        case special // debug面板手动指定
        case graysacle // mina 下发的灰度包信息
        case gecko  // gekco下载的热更包
        case innerZip(InnerPkgType)// 内嵌的精简包及对应的完整包信息

        func toResourceSource(isSlim: Bool) -> ResourceSource {
            switch self {
            case .special:
                return isSlim ? .specialSlim : .specialFull
            case .graysacle:
                return isSlim ? .grayscaleSlim : .grayscaleFull
            case .gecko:
                return .hotfix
            case .innerZip(let type):
                switch type {
                case .simple:
                    return .bundleSlim
                case .full:
                    return .bundleFull
                case .downloadFull:
                    return .fullPkg
                }
            case .unkown:
                return .bundleFull
            }
        }
    }

    /// FE资源包信息
    struct FEResourceInfo {
        var type: FEResourceType = .unkown
        public var fullPkgInfo = OfflineResourceZipInfo.CurVersionInfo()
        public var simplePkgInfo = OfflineResourceZipInfo.CurVersionInfo()
        public var hasSimplePkg: Bool = false
        /// 用于完整包下载并解压好后，移动到目标位置使用, 名称以Backup结尾；用于文件夹移动和RN加载bundle资源时使用
        var fullPkgRootFolder: SKFilePath = SKFilePath.absPath("")
        /// 路径以Backup/docs_channel，用来给webView加载js等资源的时候拼接路径用
        var fullPkgRootPathForLocator: SKFilePath = SKFilePath.absPath("")
        var simplePkgRootPathForLoctor: SKFilePath = SKFilePath.absPath("")
        var channel: DocsChannelInfo?
    }

    public func getFEResource(of type: FEResourceType) -> FEResourceInfo {
        var info = FEResourceInfo()
        info.type = type

        let defaultPath = getDefaultPkgPath(of: type)
        guard !defaultPath.pathString.isEmpty else {
            return info
        }
        let rootPath = appendDocsChannel(to: defaultPath)
        let versionInfo = getCurrentRevisionInfo(in: rootPath)

        if versionInfo.isSlim {
            info.simplePkgInfo = versionInfo
            /// 这里fullPkgPath只能是docs_channel的父级文件夹目录，用来存放动态下载并解压好的文件夹，一般以fullPkgBackup结尾
            let fullPkgPath = getFullPkgPath(of: type, defaultPath: defaultPath)
            let fullPkgDocsChannelPath = appendDocsChannel(to: fullPkgPath)
            info.fullPkgInfo = getCurrentRevisionInfo(in: fullPkgDocsChannelPath)
            info.hasSimplePkg = true
            info.fullPkgRootFolder = fullPkgPath
            /// 给Locator用的路径必须是eesz文件夹的父级，所以必须以docs_webinfo或者docs_channel
            info.fullPkgRootPathForLocator = fullPkgDocsChannelPath
            info.simplePkgRootPathForLoctor = rootPath

        } else {
            info.fullPkgInfo = versionInfo
            info.hasSimplePkg = false // 虽然默认值是false，还是明确写出来吧
            info.fullPkgRootPathForLocator = rootPath
        }
        return info
    }

    /// 拼接真实路径，由于后续资源包的channel会变，比如单品中就变成docs_app了，所以此处动态拼接
    func appendDocsChannel(to path: SKFilePath) -> SKFilePath {
        return path.appendingRelativePath("\(GeckoChannleType.webInfo.unzipFolder())")
    }

    /// 除了热更外，各种类型的包都有可能为精简包，或者完整包，所以，先找到默认（历史版本）文件夹下的包路径，进行判断
    func getDefaultPkgPath(of type: FEResourceType) -> SKFilePath {
        var path: SKFilePath?
        switch type {
        case .special:
            path = SpecialVersionResourceService.resPath(.webInfo)
        case .graysacle:
            path = GeckoPackageManager.Folder.grayscalePkgBackupPath(channel: nil)
        case .gecko:
            path = GeckoPackageManager.Folder.geckoBackupPath(channel: nil)
        case .innerZip(let type):
            switch type {
            case .simple:
                path = GeckoPackageManager.Folder.simpleBundleBackupPath(channel: nil)
            case .downloadFull:
                path = GeckoPackageManager.Folder.fullPkgBackupPath(channel: nil)
            case .full:
                path = GeckoPackageManager.Folder.bundleBackupPath(channel: nil)
            }
        case .unkown:
            GeckoLogger.error("未知包类型，新增了类型，需要写有关的路径方法")
            spaceAssertionFailure()
        }
        guard let pkgPath = path, !pkgPath.pathString.isEmpty else {
            GeckoLogger.error("该类型没有找到对应的默认路径，type: \(type)")
            return SKFilePath.absPath("")
        }
        return pkgPath
    }

    ///获取解压后提供使用的完整包目录
    private func getFullPkgPath(of type: FEResourceType, defaultPath: SKFilePath) -> SKFilePath {
        var path: SKFilePath?
        switch type {
        case .special, .graysacle, .gecko:
            path = defaultPath.appendingRelativePath("_fullPkg")
        case .innerZip: /// 这里是为了兼容老版本
            path = GeckoPackageManager.Folder.fullPkgBackupPath(channel: nil)
        case .unkown:
            GeckoLogger.error("未知包类型，新增了类型，需要写有关的路径方法")
            spaceAssertionFailure()
        }
        guard let targetPath = path, !targetPath.pathString.isEmpty else {
            GeckoLogger.error("该类型没有找到对应的完整包路径，type: \(type)")
            return SKFilePath.absPath("")
        }
        return targetPath
    }

    /// 获取兜底的package path, 一般不会走到这里来，兜底的包路径，优先级：内嵌完整包，内嵌包
    public func getSaviorPkgPath() -> SKFilePath {
        let fullPkgPath = fullPkgUnZipPath()
        if checkIsPackageExist(at: fullPkgPath) {
            return fullPkgPath
        }

        let simplePkgPath = simpleResChannelUnZipPath(.webInfo)
        if checkIsPackageExist(at: simplePkgPath) {
            return simplePkgPath
        }

        // KA包或者有人不小心把完整包作为内嵌包放进来了，才会走到这里来
        let innerFullPkgPath = bundlePkgUnZipPath()
        if checkIsPackageExist(at: innerFullPkgPath) {
            return innerFullPkgPath
        }
        GeckoLogger.error("can't find savoir path, check clear package logic")
        spaceAssertionFailure()
        return SKFilePath.absPath("")
    }

    func checkIsPackageExist(at path: SKFilePath) -> Bool {
        let info = getCurrentRevisionInfo(in: path)
        return info.isExist
    }

}

extension GeckoPackageManager {
    /**
     优先级：从高到底
     一、大类
     1、debug面板指定包
     2、mina下发灰度包
     3、gecko热更和内嵌包，这两个包要比较版本号大小，用大的
     二、精简包和完整包
     从一中可以知道用哪个大类包，进一步判断，如果本地是完整包，就直接用；如果是精简包，要走判断并下载对应完整包的逻辑
     */
    func judgeFEResource(for channel: DocsChannelInfo) -> FEResourceInfo {
        /// debug 面板指定资源包
        if isUsingSpecial(channel.type) {
            GeckoLogger.info("debug面板指定前端资源包")
            return getFEResource(of: .special)
        }

        /// mina下发灰度包
        let grayscalePkgInfo = currentGrayscalePkgInfo(channel)
        let useGrayscalePkg = UserScopeNoChangeFG.HZK.useGrayscalePackage

        if useGrayscalePkg, grayscalePkgInfo.isExist, let config = SettingConfig.grayscalePackageConfig, !config.isEmpty {
            GeckoLogger.info("mina配置了前端资源包，且该资源包也存在于本地")
            return getFEResource(of: .graysacle)
        }

        /// gecko热更和内嵌包，这两个包要比较版本号大小，用大的
        let geckoInfo = currentGeckoInfo(channel)
        let isGeckoPkgExist = geckoInfo.version != unknowVersion
        let fullPkgInfo = currentFullPkgInfo(channel)
        let simplePkgInfo = currentSimpleBundleInfo(channel)
        let bundleInfo = currentBundleInfo(channel)
        GeckoLogger.info("热更包信息:\(geckoInfo)")
        GeckoLogger.info("下载完整包信息:\(fullPkgInfo)")
        GeckoLogger.info("沙盒里内嵌精简包信息:\(simplePkgInfo)")
        GeckoLogger.info("Bundle里内嵌包信息:\(bundleInfo)")

        let isFullPkgExist = fullPkgInfo.isExist
        if isforceUsingSimplePkg() == false {
            let inHoursePkg = checkIfNeedHandleInHousePkgLogic(bundleInfo: bundleInfo,
                                                               fullPkgInfo: fullPkgInfo,
                                                               geckPkgInfo: geckoInfo)
            if let inHoursePkg = inHoursePkg {
                /// 只有内测包才会走到这里来，研发故意把完整包作为内嵌包来用了
                GeckoLogger.info("checkIfNeedHandleInHousePkgLogic, final use: \(inHoursePkg)")
                return inHoursePkg
            }
            switch (isFullPkgExist, isGeckoPkgExist) {
            case (false, true):
                // 没有完整包，但是有gecko包，并且gecko包版本号大，使用gecko包
                GeckoLogger.info("没有完整包，有热更包")
                var version: String = simplePkgInfo.version
                if version == unknowVersion {
                    GeckoLogger.info("沙盒没有精简包")
                    let zipInfo = OfflineResourceZipInfo.info(by: channel)
                    version = zipInfo.version
                    GeckoLogger.info("bundle的精简包version:\(version)")
                }
                if version != unknowVersion,
                   version.compare(geckoInfo.version, options: .numeric) == .orderedAscending {
                    GeckoLogger.info("可以使用热更包")
                    return getFEResource(of: .gecko)
                }
            case (true, false):
                // 有完整包，没有gecko包，使用完整包
                GeckoLogger.info("有完整包，没有热更包")
                return getInnerZipFEResource(with: .downloadFull)
            case (true, true):
                // 有完整包，也有gecko包， 比较version，用大的
                GeckoLogger.info("有完整包，也有热更包")
                let isGeckoVersionBigger = fullPkgInfo.version.compare(geckoInfo.version, options: .numeric) == .orderedAscending
                if isGeckoVersionBigger {
                    GeckoLogger.info("使用热更包")
                    return getFEResource(of: .gecko)
                } else {
                    GeckoLogger.info("使用下载的完整包")
                    return getInnerZipFEResource(with: .downloadFull)
                }
            case (false, false):
                GeckoLogger.info("没有完整包，没有热更包")
            }
        }

        /*
         KA环境下，内嵌包为完整包，不再是精简包, 下面写法是为了逻辑清晰，不是最简写法
         */
        if simplePkgInfo.version == unknowVersion, bundleInfo.version != unknowVersion {
            GeckoLogger.info("使用内嵌完整包")
            return getInnerZipFEResource(with: .full)
        } else if simplePkgInfo.version != unknowVersion {
            GeckoLogger.info("使用内嵌精简包")
            return getInnerZipFEResource(with: .simple)
        } else {
            // 什么包都没有，解压内嵌包
            CCMKeyValue.globalUserDefault.removeObject(forKey: UserDefaultKeys.lastUnzipEESZZipVersion)
            spaceAssert(!Thread.current.isMainThread, "不能在主线程执行zip包的解压操作，容易卡顿，检查调用")
            if !UserScopeNoChangeFG.HZK.fullPkgUnzipOptimize {
                DispatchQueue.global().async {
                    self.unzipResToSandbox(channel)
                }
            } else {
                unzipResToSandbox(channel)
            }
            
            GeckoLogger.error("本地找不到任何可以用的资源包，被误删除了")
            logBadCase(code: .notHaveAnyPkg, msg: "bundle找不到任何可用的资源包")
        }

        return getInnerZipFEResource(with: .simple)
    }
    
    /// 处理内嵌完整包时，研发打包用于内测的情况。不是这种情况就直接返回nil
    private func checkIfNeedHandleInHousePkgLogic(bundleInfo: PkgInfo,
                                                  fullPkgInfo: FullPkgInfo,
                                                  geckPkgInfo: PkgInfo
                                                  ) -> FEResourceInfo? {
        guard bundleInfo.version != unknowVersion, !ReleaseConfig.isPrivateKA else { return nil }
        GeckoLogger.info("checkIfNeedHandleInHousePkgLogic, RD put a full fe pkg into as inner pkg, version: \(bundleInfo.version)")
        // 只有内测包，并且研发故意把完整包放到了工程里面了，用于内测才会走到这里
        
        /// 判断下载的完整包，内嵌完整包，热更包，哪个版本号大用哪个
        var versions: [String] = [bundleInfo.version]
        if fullPkgInfo.isExist {
            versions.append(fullPkgInfo.version)
        }
        if geckPkgInfo.version != unknowVersion {
            versions.append(geckPkgInfo.version)
        }
        
        // 降序排列，取第一个
        versions.sort { $0.compare($1, options: .numeric) == .orderedDescending }
        let largestVersion = versions[0]
        GeckoLogger.info("checkIfNeedHandleInHousePkgLogic, sorted versions: \(versions)")
        
        switch largestVersion {
        case bundleInfo.version:
            return getInnerZipFEResource(with: .full)
        case fullPkgInfo.version:
            return getInnerZipFEResource(with: .downloadFull)
        case geckPkgInfo.version:
            return getFEResource(of: .gecko)
        default:
            return getInnerZipFEResource(with: .downloadFull)
        }
    }

    private func getInnerZipFEResource(with type: FEResourceType.InnerPkgType) -> FEResourceInfo {
        return getFEResource(of: .innerZip(type))
    }

    /**
     优先级：从高到底
     一、大类
     1、debug面板指定包
     2、mina下发灰度包
     3、gecko热更和内嵌包，这两个包要比较版本号大小，用大的
     二、精简包和完整包
     从一中可以知道用哪个大类包，进一步判断，如果本地是完整包，就直接用；如果是精简包，要走判断并下载对应完整包的逻辑
     */
    @discardableResult
    func judgeWhichToUseLocatorV2(for channel: DocsChannelInfo, canDownloadFullPkg: Bool = true) -> OfflineResourceLocator? {

        // 1、先判断大类
        var resourceInfo: FEResourceInfo = judgeFEResource(for: channel)
        resourceInfo.channel = channel
        GeckoLogger.info("前端资源包大类:\(resourceInfo)")

        let fullPkgInfo = resourceInfo.fullPkgInfo
        let simplePkgInfo = resourceInfo.simplePkgInfo
        let targetFullPkgVersion = simplePkgInfo.fullPkgScmVersion
        // 2、再判断当前使用的大类是否是精简包
        guard resourceInfo.hasSimplePkg else {
            // 如果不是精简包，走这里
            GeckoLogger.info("不是精简包")
            return createResourceLocator(source: resourceInfo.type.toResourceSource(isSlim: false),
                                         version: fullPkgInfo.version,
                                         rootFolder: resourceInfo.fullPkgRootPathForLocator,
                                         channel: fullPkgInfo.channel)
        }



        if isforceUsingSimplePkg() {
            GeckoLogger.info("强制使用精简包")
            var locator = createResourceLocator(source: resourceInfo.type.toResourceSource(isSlim: true),
                                                version: simplePkgInfo.version,
                                                rootFolder: resourceInfo.simplePkgRootPathForLoctor,
                                                channel: simplePkgInfo.channel)
            locator.isSlim = true
            return locator
        }

        let source = resourceInfo.type.toResourceSource(isSlim: false)
        // 如果是精简包，还要额外判断对应的完整包是否已经下载好了，以及版本号是否能唯一对应，不然就是版本切换了，依旧要下载
        if fullPkgInfo.isExist && targetFullPkgVersion == fullPkgInfo.version {

            // 存在精简包对应的完整包，不用下载，直接用
            GeckoLogger.info("存在精简包对应的完整包")
            return createResourceLocator(source: source,
                                         version: fullPkgInfo.version,
                                         rootFolder: resourceInfo.fullPkgRootPathForLocator,
                                         channel: fullPkgInfo.channel)
        } else if canDownloadFullPkg {
            // 如果没有下载好，触发下载
            GeckoLogger.info("触发下载完整包")
            serialQueue.async { [weak self] in
                guard let self = self else { return }
                let urlStr = DomainConfig.envInfo.isChinaMainland ? simplePkgInfo.fullPkgUrlHome : simplePkgInfo.fullPkgUrlOversea

                var targetSource: ResourceSource = source
                if case .innerZip(.simple) = resourceInfo.type {
                    targetSource = .fullPkg
                }
                self.downloadFullPackage(urlStr: urlStr,
                                         version: targetFullPkgVersion,
                                         targetSource: targetSource,
                                         resourceInfo: resourceInfo,
                                         channel: channel)
            }
        }

        var locator = createResourceLocator(source: resourceInfo.type.toResourceSource(isSlim: true),
                                            version: simplePkgInfo.version,
                                            rootFolder: resourceInfo.simplePkgRootPathForLoctor,
                                            channel: simplePkgInfo.channel)
        locator.isSlim = true
        return locator

    }
    /// 下载完整包的通用方法
    func downloadFullPackage(urlStr: String,
                             version: String,
                             targetSource: ResourceSource,
                             resourceInfo: FEResourceInfo,
                             channel: DocsChannelInfo) {
        
        _downloadFullPackage(urlStr: urlStr,
                             version: version,
                             targetSource: targetSource,
                             resourceInfo: resourceInfo,
                             channel: channel,
                             isForUnzipFailed: false)
    }
    
    func downloadFullPackageWhenUnzipBundleSlimFailed(urlStr: String,
                                                      version: String,
                                                      targetSource: ResourceSource,
                                                      resourceInfo: FEResourceInfo,
                                                      channel: DocsChannelInfo) {
        
        _downloadFullPackage(urlStr: urlStr,
                             version: version,
                             targetSource: targetSource,
                             resourceInfo: resourceInfo,
                             channel: channel,
                             isForUnzipFailed: true)
    }
    
    private func _downloadFullPackage(urlStr: String,
                                     version: String,
                                     targetSource: ResourceSource,
                                     resourceInfo: FEResourceInfo,
                                     channel: DocsChannelInfo,
                                     isForUnzipFailed: Bool) {
        
        let isDownloading = !pkgDownloadTasks.filter({ !$0.isGrayscale && $0.version == version }).isEmpty
        guard !isDownloading else {
            GeckoLogger.info("version=\(version)的完整包已经在下载中了，无需重复下载")
            return
        }
        
        //KA审核被拒，屏蔽完整包下载
        GeckoLogger.info("KA audit rejected，Forbid downloading full package")
        return
        
        var task: PackageDownloadTask?
        var slimVersion: String?
        if UserScopeNoChangeFG.HZK.disableGeckoDownloadFullPkg {
            var localPath = targetSource.pkgPathInfo().downloadZipFolderPath
            guard !localPath.pathString.isEmpty else {
                GeckoLogger.error("localPath is empty")
                return
            }
            localPath = localPath.appendingRelativePath(downloadZipPkgName)
            task = PackageDownloadTaskDriveImpl(
                urlString: urlStr,
                downloadPath: localPath,
                version: version,
                delegate: self,
                resourceInfo: resourceInfo
            )
        } else {
            GeckoLogger.info("use GeckoImpl download full pkg")
            let localPath = targetSource.pkgPathInfo().tempUnzipFolderPath
            guard !localPath.pathString.isEmpty else {
                GeckoLogger.error("localPath is empty")
                return
            }
            if let geckoAgent = geckoAgent {
                task = PackageDownloadTaskGeckoImpl(
                    version: version,
                    resourceInfo: resourceInfo,
                    downloadPath: localPath,
                    agent: geckoAgent,
                    appVersion: appVersion,
                    delegate: self
                )
                slimVersion = resourceInfo.simplePkgInfo.version
            }
        }
        guard let task = task else {
            return
        }
        if isForUnzipFailed {
            task.isForUnzipBundleSlimFailed = true
        }
        pkgDownloadTasks.append(task)
        task.start()
        startTrackFullPkgDownloadResult(slimVersion: slimVersion)
        GeckoLogger.info("启动下载任务")
    }

    public func isUsingSimplePkgForWebInfo() -> Bool {
        guard let locator = locatorMapping.value(ofKey: .webInfo) else { return false }
        return locator.isSlim
    }
    
    // 是否有可用的本地资源包
    public func localPkgForWebInfoIsEmpty() -> Bool {
        if locatorMapping.value(ofKey: .webInfo) != nil {
            GeckoLogger.info("locatorMapping not Empty")
            return false
        }
        GeckoLogger.warning("locatorMapping is Empty, The full package may be unzipping")
        return true
    }
    
    public func getWebInfoChannels() -> [DocsChannelInfo] {
        return self.channels.filter { $0.type == .webInfo }
    }
    
    /// 精简包文件名，例如eesz.txz
    public var bundleSlimPkgName: String {
        BundlePackageExtractor.packageFileName
    }
}

// MARK: - 前端灰度包逻辑
extension GeckoPackageManager {

    @objc
    private func settingConfigFinishRequest() {
        RunloopDispatcher.shared.addTask(priority: .low) {
            DocsLogger.info("cpu.task: try downloadGrayscalePackageIfNeeded")
            GeckoPackageManager.shared.downloadGrayscalePackageIfNeeded()
        }.waitCPUFree().withIdentify("leisureAsyncStage-downloadGrayscalePackageIfNeeded")
    }

    private func clearGrayscalePackage() {
        DispatchQueue.global().async {
            let path = GeckoPackageManager.Folder.grayscalePkgBackupPath(channel: nil)
            GeckoLogger.info("clearGrayscalePackage at : \(String(describing: path))")
            self.removeFiles(at: path, logTag: "删除灰度包")

            let grayscalePkgTypes: [ResourceSource] = [.grayscaleFull, .grayscaleSlim]
            if let curLocator = self.locatorMapping.value(ofKey: .webInfo), grayscalePkgTypes.contains(curLocator.source) {
                let checkChannels = self.channels.filter { $0.type == .webInfo }
                checkChannels.forEach { (channel) in
                    self.refreshOfflineResourceLocator(channel)
                }
            }
        }
    }

    private func downloadGrayscalePackageIfNeeded() {
        
        //KA审核被拒，屏蔽灰度包下载
        GeckoLogger.info("KA audit rejected，Forbid downloading gray package")
        return
        
        let useGrayscale = UserScopeNoChangeFG.HZK.useGrayscalePackage
        GeckoLogger.info("need useGrayscale: \(useGrayscale)")
        guard useGrayscale else {
            clearGrayscalePackage()
            return
        }

        //读取配置，判断是否有必要下载
        guard let grayscaleConfig = SettingConfig.grayscalePackageConfig, !grayscaleConfig.isEmpty else {
            clearGrayscalePackage()
            GeckoLogger.error("can not find grayscaleConfig on local disk")
            return
        }
        GeckoLogger.info("get grayscaleConfig from local disk: \(grayscaleConfig)")

        guard let version = grayscaleConfig["version"] as? String, !version.isEmpty else {
            GeckoLogger.error("version is empty in grayscaleConfig")
            return
        }
        guard let url = grayscaleConfig["url"] as? String, !url.isEmpty else {
            clearGrayscalePackage()
            GeckoLogger.error("url is empty in grayscaleConfig")
            return
        }

        let checkChannels = self.channels.filter { $0.type == .webInfo }
        checkChannels.forEach { (channel) in
            guard shouldDownloadGrayscalePkg(for: channel, targetVersion: version) else { return }
            downloadGrayscalePackage(channel, urlStr: url, version: version)
        }
    }

    func shouldDownloadGrayscalePkg(for channel: DocsChannelInfo, targetVersion: String) -> Bool {
        let grayscalePkgInfo = currentGrayscalePkgInfo(channel)
        if !grayscalePkgInfo.isExist {
            GeckoLogger.info("本地没有灰度包，需要下载")
            return true
        }

        let shouldDownload = grayscalePkgInfo.version.compare(targetVersion, options: .numeric) != .orderedSame
        GeckoLogger.info("是否需要下载灰度包: \(shouldDownload)")
        return shouldDownload
    }
    func downloadGrayscalePackage(_ channel: DocsChannelInfo, urlStr: String, version: String) {
        let isDownloading = !pkgDownloadTasks.filter({ $0.isGrayscale }).isEmpty
        guard !isDownloading else {
            GeckoLogger.info("已经开始下载灰度包了，不再重复下载")
            return
        }
        var task: PackageDownloadTask?
        if UserScopeNoChangeFG.HZK.disableGeckoDownloadFullPkg {
            var localPath = GeckoPackageManager.Folder.grayscalePkgZipDownloadPath(channel: channel.name)
            guard !localPath.pathString.isEmpty else {
                return
            }
            localPath = localPath.appendingRelativePath(downloadZipPkgName)
            task = PackageDownloadTaskDriveImpl(
                urlString: urlStr,
                downloadPath: localPath,
                version: version,
                isGrayscale: true,
                delegate: self
            )
        } else {
            let localPath = GeckoPackageManager.Folder.grayscalePkgUnzipPath(channel: nil)
            guard !localPath.pathString.isEmpty else {
                GeckoLogger.error("localPath is empty")
                return
            }
            guard let geckoAgent = geckoAgent else {
                return
            }
            task = PackageDownloadTaskGeckoImpl(
                version: version,
                resourceInfo: nil,
                downloadPath: localPath,
                agent: geckoAgent,
                appVersion: appVersion,
                delegate: self
            )
        }
        guard let task = task else {
            return
        }
        GeckoPackageManager.shared.curDownloadingChannelForGrayscale = channel
        pkgDownloadTasks.append(task)
        task.start()
    }
}

extension GeckoPackageManager {

    private func getFEResourcePkgInfo(with type: FEResourceType) -> FEResourcePkgInfo {
        let info = getFEResource(of: type)
        let isFullPkgExist = info.fullPkgInfo.isExist
        let fullPkgVersion = isFullPkgExist ? info.fullPkgInfo.version : info.simplePkgInfo.fullPkgScmVersion
        return (info.simplePkgInfo.version, fullPkgVersion, isFullPkgExist)
    }
    public func getSpecialPkgInfo() -> FEResourcePkgInfo {
        return getFEResourcePkgInfo(with: .special)
    }

    public func getGrayscalePkgInfo() -> FEResourcePkgInfo {
        return getFEResourcePkgInfo(with: .graysacle)
    }

    public func getGeckoPkgInfo() -> FEResourcePkgInfo {
        return getFEResourcePkgInfo(with: .gecko)
    }
}

extension GeckoPackageManager {
    public func markFileNotFound(filePath: String) {
        notFoundInLocalFileSet.insert(filePath)
    }

    public func removeMarkFileNotFound(filePath: String) {
        notFoundInLocalFileSet.remove(filePath)
    }

    public func isInRemoteResourcesJson(targetFilePath: String) -> Bool {
        guard notFoundInLocalFileSet.contains(targetFilePath) else { return false }
        guard let folder = filesRootPath(for: .webInfo), !folder.pathString.isEmpty else { return false }
        guard let filePath = getFullFilePath(at: folder, of: "remote_resources.json") else { return false }
        
        if let data = try? Data.read(from: filePath),
            let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
            let fileList = dict["remote_file_list"] as? [Any] {
            return fileList.contains { (item) -> Bool in
                if let fileName = item as? String, fileName.contains(targetFilePath) {
                    return true
                }
                return false
            }
        }
        return false
    }
}

extension GeckoPackageManager {

    static let filePathsPlistName = "fe_pkg_filePaths.plist"

    /// 获取指定文件在指定文件夹下的目录，最好是传入根目录路径，比如以Backup结尾的文件夹名称
    /// 注意 needFullPath 传 false，返回的是 SKFilePath(absPath: filePath)
    /// 将public func getFilePath(at folder: SKFilePath, of fileName: String, needFullPath: Bool = true) -> SKFilePath?  拆分成下面两个方法
    ///   getRelativeFilePath(at folder: SKFilePath, of fileName: String) -> String?
    /// 和 getFullFilePath(at folder: SKFilePath, of fileName: String) -> SKFilePath?
    
    // 这里只返回相对路径
    public func getRelativeFilePath(at folder: SKFilePath, of fileName: String) -> String? {
        // 这里要求docs_channel结尾，是为了保证资源包目录文件结构中只生成一个 fe_pkg_filePaths.plist 文件
        if !folder.pathString.hasSuffix(GeckoChannleType.webInfo.unzipFolder()) {
            let msg = "fileName: \(fileName), tareget folder is illegal: \(folder)"
            GeckoLogger.error(msg)
        }
        // https://bytedance.feishu.cn/docs/doccnIQJyIefnjN8IsYrTQoOgfb#
        var dict = getFilePathsPlistContent(at: folder)
        
        //去掉这里的创建plist文件，再解压成功的地方进行创建
        if UserScopeNoChangeFG.HZK.fullPkgUnzipOptimize {
            if dict == nil {
                GeckoLogger.info("create plist")
                dict = createFilePathsPlist(at: folder)
            }
        }
        guard let filePathDict = dict, let filePath = filePathDict[fileName] else {
            GeckoLogger.error("get nil for =\(fileName), dict=\(String(describing: dict))")
            return nil
        }
        return filePath
    }
    
    // 这里返回全路径
    public func getFullFilePath(at folder: SKFilePath, of fileName: String) -> SKFilePath? {
        
        guard let relativePath = getRelativeFilePath(at: folder, of: fileName) else {
            GeckoLogger.error("get Relative path nil for =\(fileName)")
            return nil
        }
        
        return folder.appendingRelativePath(relativePath)
    }
    


    /// 创建plist文件，记录folder文件夹下，所有子孙文件/文件夹的名字与路径的映射，key是名字，value是路径
    func createFilePathsPlist(at folder: SKFilePath) -> [String: String]? {
        guard folder.exists else {
            GeckoLogger.error("create plist err, folder not exist: \(folder)")
            return nil
        }
        
        let subPaths = folder.subpaths()
        guard !subPaths.isEmpty else {
            GeckoLogger.error("create plist err, subpaths err ,folder= \(folder)")
            return nil
        }
        
        var dict = [String: String]()
        
        subPaths.forEach { (path) in
            let fileName = (path as NSString).lastPathComponent
            guard !fileName.isEmpty else { return }
            dict[fileName] = path
        }
        
        let targetPath = getFilePathsPlistPath(at: folder)
        let res = writePlist(dict: dict, to: targetPath)
        if !res {
            GeckoLogger.error("create plist fail,path:\(targetPath),dict:\(dict)")
            logBadCase(code: .filePathPlistWriteFail, msg: "路径plist文件写入失败")
        }
        return dict
    }

    /// 获取指定目录下的路径缓存文件内容，如果没有创建过就返回nil
    public func getFilePathsPlistContent(at folder: SKFilePath) -> [String: String]? {
        let targetPath = getFilePathsPlistPath(at: folder)
        return readPlist(from: targetPath)
    }
    
    private func getFilePathsPlistPath(at folder: SKFilePath) -> SKFilePath {
        return folder.appendingRelativePath(GeckoPackageManager.filePathsPlistName)
    }
    
    private func readPlist(from filePath: SKFilePath) -> [String: String]? {
        if let plistCache = filePathsPlistCache { // 优先取缓存
            return plistCache
        }
        guard filePath.exists else {
            GeckoLogger.info("plist文件不存在,filePath:\(filePath)")
            return nil
        }
        guard let data = filePath.contentsAtPath() else {
            GeckoLogger.error("plist文件内容为空,filePath:\(filePath)")
            return nil
        }
        var format = PropertyListSerialization.PropertyListFormat.xml
        do {
            let content = try PropertyListSerialization.propertyList(from: data, options: .mutableContainersAndLeaves, format: &format)
            guard let dict = content as? [String: String] else {
                GeckoLogger.error("plist结构有问题, \(content)")
                return nil
            }
            let ur = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
            if let config = try? ur.resolve(assert: PowerOptimizeConfigProvider.self), config.fePkgFilePathsMapOptEnable {
                filePathsPlistCache = dict
            } else {
                filePathsPlistCache = nil
            }
            return dict
        } catch let error {
            GeckoLogger.error("解析plist失败", error: error)
        }
        return nil
    }
    
    private func writePlist(dict: [String: String], to filePath: SKFilePath) -> Bool {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        var plistData: Data
        do {
            plistData = try encoder.encode(dict)
        } catch let error {
            GeckoLogger.error("plist编码失败", error: error)
            return false
        }
        if UserScopeNoChangeFG.HZK.fullPkgUnzipOptimize { //旧逻辑，暂时不走
            do {
                try plistData.write(to: filePath, options: .atomic)
            } catch let error {
                GeckoLogger.error("plist write disk,folder:\(filePath)", error: error)
                return false
            }
        } else {
            //新逻辑，有覆盖的操作
            let isSuccess = filePath.writeFile(with: plistData, mode: .over)
            GeckoLogger.error("plist write disk，folder:\(filePath), isSuccess : \(isSuccess)")
        }
        return true
    }
}
