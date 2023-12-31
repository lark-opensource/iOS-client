//
//  OPBlockPreLoadService.swift
//  Blockit
//
//  Created by xiangyuanyuan on 2022/9/5.
//
import OPSDK
import TTMicroApp
import LKCommonsLogging
import OPBlockInterface
import LKCommonsLogging

extension BDPPreloadScene {
    /// 工作台block预安装
    static let workPlacePreLoad = BDPPreloadScene(priority: 0, sceneName: "workplace_pre_install")
    /// 工作台block更新
    static let workplaceUpdate = BDPPreloadScene(priority: 0, sceneName: "workplace_update")
}

class OPBlockPreLoadService: OPBlockPreUpdateProtocol {
    
    public static let log = Logger.log(OPBlockPreLoadService.self, category: "OPBlockPreLoadService")
    
    func preLoad(idList: [OPAppUniqueID]) {
        
        let blockTypeIDList = idList.map({ $0.identifier })
        OPBlockPreLoadService.log.info("preLoad blockList:\(blockTypeIDList)")

        let preloadInfoList = idList.map({BDPPreloadHandleInfo(uniqueID: $0,
                                                               scene: .workPlacePreLoad,
                                                               scheduleType: .directHandle,
                                                               listener: self)})

        BDPPreloadHandlerManager.sharedInstance.handlePkgPreloadEvent(preloadInfoList: preloadInfoList)
    }
}

extension OPBlockPreLoadService: BDPPreloadHandleListener {
    // 包回调
    public func onPackageResult(success: Bool, handleInfo: BDPPreloadHandleInfo, error: OPError?) {
        OPBlockPreLoadService.log.info("onPackageResult blockTypeID:\(handleInfo.uniqueID.identifier), success:\(success)")
    }
}

class OPBlockCheckUpdateService: OPBlockAbilityHandler {

    private let trace: OPTrace
    
    // 考虑到一个页面中存在多个相同block更新的情况，这边持有一下当前block的metaVersion
    private var localMetaVersion: String
    
    private weak var container: OPBlockContainer?
    
    private let syncLock: DispatchSemaphore = DispatchSemaphore.init(value: 1)

    init (container: OPBlockContainer, trace: OPTrace) {
        
        let blockMetaProvider = OPBlockMetaProvider(builder: OPBlockMetaBuilder(),
                                                    containerContext: container.containerContext)
        
        if let localMetaVersion = try? blockMetaProvider.getLocalMeta(with: container.containerContext.uniqueID).appVersion {
            self.localMetaVersion = localMetaVersion
        } else {
            self.localMetaVersion = ""
            trace.error("get localMetaVersion fail")
        }
        trace.info("blockCheckUpdateService init, localMetaVersion \(localMetaVersion)")
        
        self.container = container
        self.trace = trace
    }
    
    func setLocalMetaVersion(metaVersion: String) {
        syncLock.wait()
        defer {
            syncLock.signal()
        }
        self.localMetaVersion = metaVersion
        trace.info("setBlockLocalMetaVersion: \(localMetaVersion)")
    }
    
    func checkBlockUpdate() {

        guard let container = container else {
            trace.error("checkBlockUpdate fail, container is nil")
            return
        }
        
        let preloadInfo = BDPPreloadHandleInfo(uniqueID: container.containerContext.uniqueID,
                                               scene: .workplaceUpdate,
                                               scheduleType: .directHandle,
                                               listener: self)

        BDPPreloadHandlerManager.sharedInstance.handlePkgPreloadEvent(preloadInfoList: [preloadInfo])
    }
}

extension OPBlockCheckUpdateService: BDPPreloadHandleListener {

    // 包回调
    public func onPackageResult(success: Bool, handleInfo: BDPPreloadHandleInfo, error: OPError?) {

        guard success,
              let container = container,
              let remoteMeta = handleInfo.remoteMeta as? OPBlockMeta else {
            trace.error("checkBlockUpdate fail, uniqueID:\(handleInfo.uniqueID)")
            return
        }

        trace.info("checkBlockUpdate success, uniqueID:\(handleInfo.uniqueID), locMeta:\(self.localMetaVersion), remoteMeta:\(remoteMeta.appVersion)")
        
        if self.localMetaVersion != remoteMeta.appVersion {
            // 若是返回的包版本与本地不一致 发起包更新回调
            container.bundleUpdateSuccess(info: .map(updateType: remoteMeta.updateType,
                                                     updateDescription: remoteMeta.updateDescription))
            // 更新一下现在的localMeta版本
            setLocalMetaVersion(metaVersion: remoteMeta.appVersion)
        }
    }
}
