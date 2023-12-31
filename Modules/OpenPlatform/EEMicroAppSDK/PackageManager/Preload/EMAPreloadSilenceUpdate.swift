//
//  EMAPreloadSilenceUpdate.swift
//  EEMicroAppSDK
//
//  Created by laisanpin on 2022/8/5.
//

import Foundation
import LKCommonsLogging
import OPSDK
import OPWebApp

final class EMAGadgetSilenceUpdateManager: EMAAppSilenceUpdateManager, EMAPackagePreInfoProvider {
    public init() {
        super.init(appType: .gadget)
    }

    /// 拉取预安装配置信息
    public func fetchPreUpdateSettings() {
        let uniqueIDArray = MetaLocalAccessorBridge.getAllMetas(appType: .gadget).map {
            $0.uniqueID
        }

        self.fetchSilenceUpdateSettings(uniqueIDArray, needSorted: true) {[weak self] result in
            // 这里的任务是在workQueue中执行
            switch result {
            case .success(let infoMap):
                guard let infoMap = infoMap else {
                    Self.logger.warn("[GadgetSilence] infoMap is nil")
                    return
                }

                var preloadHandleInfoArray = [BDPPreloadHandleInfo]()
                for (appID, silenceInfo) in infoMap {
                    let uniqueID = OPAppUniqueID(appID: appID, identifier: nil, versionType: .current, appType: .gadget)
                    let info = BDPPreloadHandleInfo(uniqueID: uniqueID,
                                                    scene: BDPPreloadScene.SilenceUpdatePull,
                                                    scheduleType: .directHandle,
                                                    extra: [String.applicationVersion : silenceInfo.gadgetMobile],
                                                    injector: self)
                    preloadHandleInfoArray.append(info)
                }
                BDPPreloadHandlerManager.sharedInstance.handlePkgPreloadEvent(preloadInfoList: preloadHandleInfoArray)
            case .failure(let error):
                Self.logger.warn("[GadgetSilence]" + error.errorMsg)
            }
        }
    }

    /// 处理止血推送的数据; 数据格式["appID" : "xxxx", "extra" : "xxxx"]
    public func pushPreUpdateSettings(_ item: Any) {
        guard let pushInfo = item as? [String : Any],
              let appID = pushInfo["appID"] as? String else {
            Self.logger.warn("[GadgetSilence] appID is nil from silence push")
            return
        }

        let uniqueID = OPAppUniqueID(appID: appID, identifier: nil, versionType: .current, appType: .gadget)
        let preloadHandleInfo = BDPPreloadHandleInfo(uniqueID: uniqueID,
                                                     scene: BDPPreloadScene.SilenceUpdatePush,
                                                     scheduleType: .directHandle,
                                                     injector: self)

        BDPPreloadHandlerManager.sharedInstance.handlePkgPreloadEvent(preloadInfoList: [preloadHandleInfo])
    }

    /// 是否满足止血功能(子类重写, 因为这个方法需要区分应用形态)
    override public func canSilenceUpdate(uniqueID: OPAppUniqueID, metaAppVersion: String?) -> Bool {
        guard uniqueID.versionType != .preview else {
            Self.logger.info("[GadgetSilence] preview app not support silenceUpdate")
            return false
        }
        // 如果没有meta中没有应用版本,则认为不满足止血要求(Android/iOS双端对齐)
        guard let metaAppVersion = metaAppVersion else {
            Self.logger.warn("[GadgetSilence] metaAppVersion is nil")
            return false
        }

        // 判断应用形态是否正确
        guard uniqueID.appType == .gadget else {
            Self.logger.warn("[GadgetSilence] uniqueID appTye incorrect: \(uniqueID.appType)")
            return false
        }

        guard let updateInfo = getSilenceUpdateInfo(uniqueID) else { return false }

        return canSilenceUpdate(leastAppVersion: updateInfo.gadgetMobile, metaAppVersion: metaAppVersion)
    }
}

extension EMAGadgetSilenceUpdateManager: BDPPreloadHandleInjector {
    public func onInjectInterceptor(scene: BDPPreloadScene,  handleInfo: BDPPreloadHandleInfo) -> [BDPPreHandleInterceptor]? {
        // 无网络情况下拦截
        let networkInterceptor = EMAInterceptorUtils.networkInterceptor()

        let appVersionInterceptor = {(info: BDPPreloadHandleInfo) -> BDPInterceptorResponse in
            guard let silenceVersion = info.extra?[String.applicationVersion] as? String else {
                Self.logger.warn("[GadgetSilence] cannot get silenceVersion from extra")
                // 没有止血版本信息则直接放过
                return BDPInterceptorResponse(intercepted: false)
            }

            guard let metaManager = BDPModuleManager(of: .gadget)
                .resolveModule(with: MetaInfoModuleProtocol.self) as? MetaInfoModuleProtocol,
            let gadgetMeta = metaManager.getLocalMeta(with: MetaContext(uniqueID: info.uniqueID, token: nil)) as? GadgetMeta else {
                Self.logger.warn("[GadgetSilence] cannot get gadget meta")
                // 直接拦截
                return BDPInterceptorResponse(intercepted: false)
            }

            guard !silenceVersion.isEmpty, !gadgetMeta.appVersion.isEmpty else {
                Self.logger.warn("[GadgetSilence] applicationVersion or meta appVersion is empty")
                //如果有一个版本为空字符串, 则不拦截
                return BDPInterceptorResponse(intercepted: false)
            }

            Self.logger.info("[GadgetSilence] slienceVersion: \(silenceVersion), appVersion: \(gadgetMeta.appVersion)")
            let needIntercept = BDPVersionManager.compareVersion(silenceVersion, with: gadgetMeta.appVersion) != 1
            return BDPInterceptorResponse(intercepted: needIntercept, interceptedType: .cached)
        }

        return [networkInterceptor, appVersionInterceptor]
    }
}


final class EMAWebAppSilenceUpdateManager: EMAAppSilenceUpdateManager, EMAPackagePreInfoProvider {
    private let webAppMetaProvider = OPWebAppMetaProvider()

    public init() {
        super.init(appType: .webApp)
    }

    /// 拉取预安装配置信息
    public func fetchPreUpdateSettings() {
        let uniqueIDArray = self.webAppMetaProvider.getAllOfflineH5Metas().map {
            $0.uniqueID
        }

        self.fetchSilenceUpdateSettings(uniqueIDArray, needSorted: true) { [weak self] result in
            switch result {
            case .success(let infoMap):
                guard let infoMap = infoMap else {
                    Self.logger.warn("[WebAppSilence] infoMap is nil")
                    return
                }

                var preloadHandleInfoArray = [BDPPreloadHandleInfo]()
                for (appID, silenceInfo) in infoMap {
                    let uniqueID = OPAppUniqueID(appID: appID, identifier: nil, versionType: .current, appType: .webApp)
                    let info = BDPPreloadHandleInfo(uniqueID: uniqueID,
                                                    scene: BDPPreloadScene.SilenceUpdatePull,
                                                    scheduleType: .directHandle,
                                                    extra: [String.applicationVersion : silenceInfo.h5OfflineVersion],
                                                    injector: self)
                    preloadHandleInfoArray.append(info)
                }

                BDPPreloadHandlerManager.sharedInstance.handlePkgPreloadEvent(preloadInfoList: preloadHandleInfoArray)
            case .failure(let error):
                Self.logger.warn("[WebAppSilence]" + error.errorMsg)
            }
        }
    }

    /// 处理止血推送的数据; 数据格式["appID" : "xxxx", "extra" : "xxxx"]
    public func pushPreUpdateSettings(_ item: Any) {
        guard let pushInfo = item as? [String : Any],
              let appID = pushInfo["appID"] as? String else {
            Self.logger.warn("[WebAppSilence] appID is nil from silence push")
            return
        }

        let uniqueID = OPAppUniqueID(appID: appID, identifier: nil, versionType: .current, appType: .webApp)
        let preloadHandleInfo = BDPPreloadHandleInfo(uniqueID: uniqueID,
                                                     scene: BDPPreloadScene.SilenceUpdatePush,
                                                     scheduleType: .directHandle,
                                                     injector: self)

        BDPPreloadHandlerManager.sharedInstance.handlePkgPreloadEvent(preloadInfoList: [preloadHandleInfo])
    }

    /// 是否满足止血功能(子类重写, 因为这个方法需要区分应用形态)
    override public func canSilenceUpdate(uniqueID: OPAppUniqueID, metaAppVersion: String?) -> Bool {
        guard uniqueID.versionType != .preview else {
            Self.logger.info("[WebAppSilence] preview app not support silenceUpdate")
            return false
        }
        // 如果没有meta中没有应用版本,则认为不满足止血要求(Android/iOS双端对齐)
        guard let metaAppVersion = metaAppVersion else {
            Self.logger.warn("[WebAppSilence] metaAppVersion is nil")
            return false
        }

        // 判断应用形态是否正确
        guard uniqueID.appType == .webApp else {
            Self.logger.warn("[WebAppSilence] uniqueID appTye incorrect: \(uniqueID.appType)")
            return false
        }

        guard let updateInfo = getSilenceUpdateInfo(uniqueID) else { return false }

        return canSilenceUpdate(leastAppVersion: updateInfo.h5OfflineVersion, metaAppVersion: metaAppVersion)
    }
}

extension EMAWebAppSilenceUpdateManager: BDPPreloadHandleInjector {
    public func onInjectInterceptor(scene: BDPPreloadScene,  handleInfo: BDPPreloadHandleInfo) -> [BDPPreHandleInterceptor]? {
        // 无网络情况下拦截
        let networkInterceptor = EMAInterceptorUtils.networkInterceptor()

        let appVersionInterceptor = {[weak self] (info: BDPPreloadHandleInfo) -> BDPInterceptorResponse in
            guard let `self` = self else {
                Self.logger.error("[WebAppSilence] self is nil, donot intercept")
                return BDPInterceptorResponse(intercepted: false)
            }

            guard let silenceVersion = info.extra?[String.applicationVersion] as? String else {
                Self.logger.warn("[WebAppSilence] cannot get silenceVersion from extra")
                // 没有止血版本信息则直接放过
                return BDPInterceptorResponse(intercepted: false)
            }

            do {
                let webAppMeta = try self.webAppMetaProvider.getLocalMeta(with: info.uniqueID)
                guard !silenceVersion.isEmpty, !webAppMeta.applicationVersion.isEmpty else {
                    Self.logger.warn("[WebAppSilence] applicationVersion or meta application is empty")
                    return BDPInterceptorResponse(intercepted: false)
                }

                Self.logger.info("[WebAppSilence] slienceVersion: \(silenceVersion), appVersion: \(webAppMeta.applicationVersion)")
                let needIntercept = BDPVersionManager.compareVersion(silenceVersion, with: webAppMeta.applicationVersion) != 1
                return BDPInterceptorResponse(intercepted: needIntercept, interceptedType: .cached)
            } catch {
                Self.logger.warn("[WebAppSilence] cannot get local webAppMeta")
                return BDPInterceptorResponse(intercepted: false)
            }
        }

        return [networkInterceptor, appVersionInterceptor]
    }
}

fileprivate extension String {
    static let applicationVersion = "applicationVersion"
}
