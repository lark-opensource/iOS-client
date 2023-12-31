//
//  OPGadgetDRPackageModule.swift
//  TTMicroApp
//
//  Created by justin on 2023/2/21.
//

import Foundation
import LKCommonsLogging
import OPSDK
import LarkCache

final class OPGadgetDRPKMModule: OPGadgetDRModule {
    
    override class func getModuleName() -> String {
        return DRModuleName.PKM.rawValue
    }
    
    override class func getPriority() -> DRModulePriority {
        return .pkm
    }
    
    override func startDRModule(config: OPGadgetDRConfig?) {
        self.config = config
        OPGadgetDRLog.logger.info("module didFinsied:\(Self.description()))")
        //开始包管理清理策略（清理Meta和PKG）
        if let config = config {
            //只清理固定的小程序
            var needCleanAppMetaList: [AppMetaProtocol] = []
            switch config.level {
            case .ALL:
                // 获取当前磁盘小程序所有的meta信息
                needCleanAppMetaList = MetaLocalAccessorBridge.getAllMetas(appType: .gadget)
                if let keepAppList = config.needRetainAppIds, keepAppList.isEmpty != true {
                    //需要保留的应用列表，其余的都清一遍
                    //移除需要保留的应用
                    needCleanAppMetaList.removeAll{ keepAppList.contains($0.uniqueID.appID) }
                }
            case .PART:
                if config.appIdList.isEmpty != true {
                    // 获取当前磁盘小程序meta信息
                    needCleanAppMetaList = config.appIdList.compactMap {
                        if let appMeta = MetaLocalAccessorBridge.getMetaWithUniqueId(uniqueID: BDPUniqueID(appID: $0, identifier: nil, versionType: .current, appType: .gadget)) {
                            return appMeta
                        }
                        return nil
                    }
                }
                if let keepAppList = config.needRetainAppIds,
                    keepAppList.isEmpty != true {
                    //需要保留的应用列表，如果在清理列表里需要删除
                    needCleanAppMetaList.removeAll { keepAppList.contains($0.uniqueID.appID) }
                }
            case .UNKNOWN:
                OPGadgetDRLog.logger.warn("unkow clean level:\(config.level)")
            }
            guard let metaModule = BDPModuleManager(of: .gadget)
                .resolveModule(with: MetaInfoModuleProtocol.self) as? MetaInfoModuleProtocol else {
                OPAssertionFailureWithLog("has no meta module manager for gadget when clean")
                //异常流程也需要告诉框架已经处理结束了
                self.moduleDidFinished(self)
                return
            }
            let startTime = Date().timeIntervalSince1970
            OPGadgetDRLog.logger.info("begin to clean with needCleanAppMetaList:\(needCleanAppMetaList)")
            //删包之前统计要删除的包大小总共有多少
            let packageSizeMap = OPGadgetCleanStrategy.packageSizeMap(metas: needCleanAppMetaList)
            needCleanAppMetaList.forEach { appMeta in
                //清理包管理meta部分
                let uniqueID = appMeta.uniqueID
                OPGadgetDRLog.logger.info("begin to clean with uniqueID:\(uniqueID)")
                let context = MetaContext(uniqueID: uniqueID, token: nil)
                //清理新数据库表
                if OPSDKFeatureGating.enableDBUpgrade() {
                    MetaLocalAccessorBridge.removeAllMetasInPKMDBWithAppID(uniqueID.appID)
                }
                //清理老数据库表
                metaModule.removeMetas(with: [context])
                //清理小程序包
                do {
                    try BDPPackageLocalManager.deleteAllLocalPackages(with: uniqueID)
                } catch  {
                    OPGadgetDRLog.logger.error("delete \(uniqueID) pacakge with error:\(error)")
                }
                OPGadgetDRLog.logger.info("finish clean with uniqueID:\(uniqueID)")
            }
            //删完了meta，开始删pkg
            let endTime = Date().timeIntervalSince1970
            // 计算耗时
            let cost = Int((endTime - startTime) * 1000)
            let taskResult = TaskResult(completed: true, costTime: cost, sizes: packageSizeMap.map {
                TaskResult.Size.bytes($0.value)
            })
            OPGadgetDRLog.logger.info("task result:\(taskResult)")
            self.config?.taskResult = taskResult
            //告诉框架已经处理结束了
            self.moduleDidFinished(self)
        }
    }
    
}
