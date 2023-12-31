//
//  SpaceKit+Gecko.swift
//  SKCommon
//
//  Created by lijuyou on 2020/6/11.
//  


import SKFoundation
import SKInfra

extension DocsSDK {
    public typealias OfflineResourceDebugInfo = (isSlim: Bool,
                                                version: String,
                                                simplePkgVersion: String,
                                                name: String,
                                                fullPkgVersion: String,
                                                fullPkgIsReady: Bool,
                                                isGrayscaleExist: Bool,
                                                grayscaleVersion: String,
                                                specialVersion: String)

    public func setupGecko(config: GeckoInitConfig?) {
        guard let geckoConfig = config else { return }
        GeckoPackageManager.shared.disableUpdate(disable: !OpenAPI.offlineConfig.geckoFetchEnable)
        GeckoPackageManager.shared.setupConfig(config: geckoConfig)
        GeckoPackageManager.shared.addEventObserver(obj: self)
        GeckoPackageManager.shared.syncResourcesIfNeeded()
    }

    public class func offlineResourceVersion(_ channel: GeckoChannleType = .webInfo) -> String? {
        switch channel {
        case .webInfo:
            return GeckoPackageManager.shared.currentVersion(type: channel)
        default:
            return GeckoPackageManager.shared.currentVersion(type: channel)
        }
    }

//    public class func offlineResourcePath(_ channel: GeckoChannleType = .webInfo) -> String {
//        return GeckoPackageManager.shared.filesRootPath(for: channel) ?? ""
//    }

//    // 更新离线资源包
//    public func updateOfflineResource() {
//        GeckoPackageManager.shared.syncResourcesIfNeeded()
//    }

    public class func getCurUsingPkgInfo() -> OfflineResourceDebugInfo {
        guard let locator = GeckoPackageManager.shared.locatorMapping.value(ofKey: .webInfo) else {
            return (false, "no locator", "no locator", "no locator", "no locator", false, false, "no locator", "no locator")
        }
        let channel: DocsChannelInfo = (.webInfo, GeckoPackageManager.shared.currentUsingAppChannel.rawValue,
                                        "SKResource.framework/SKResource.bundle/eesz-zip",
                                        GeckoPackageManager.shared.bundleSlimPkgName)
        let fullPkgInfo = GeckoPackageManager.shared.currentFullPkgInfo(channel)
        var simplePkgInfo = GeckoPackageManager.shared.currentSimpleBundleInfo(channel)
        if simplePkgInfo.version == "unknow" {

            let zipInfo = OfflineResourceZipInfo.info(by: channel)
            let versionFolder = zipInfo.zipFileBaseFolder
            let verInfo = GeckoPackageManager.Folder.getCurentVersionInfo(in: versionFolder)
            simplePkgInfo = (verInfo.version, "not found", verInfo.fullPkgScmVersion)
        }

        let grayscalePkgInfo = GeckoPackageManager.shared.currentGrayscalePkgInfo(channel)
        let specialPkgInfo = GeckoPackageManager.shared.getFEResource(of: .special)
        let spPkgVersion = specialPkgInfo.hasSimplePkg ? specialPkgInfo.simplePkgInfo.version : specialPkgInfo.fullPkgInfo.version
        return (locator.isSlim,
                locator.version,
                simplePkgInfo.version,
                locator.source.name,
                simplePkgInfo.fullPkgVersion,
                fullPkgInfo.isExist,
                grayscalePkgInfo.isExist,
                grayscalePkgInfo.version,
                spPkgVersion)
    }

    private class func generatePkgInfoToString(_ info: FEResourcePkgInfo) -> String {
        let msg =  """
        精简包：\(info.simpleVersion)
        完整包：\(info.fullPkgVersion)
        完整包是否ready：\(info.isFullPkgReady)
        """
        return msg
    }
    public class func getSpecialPkgInfo() -> String {
        return generatePkgInfoToString(GeckoPackageManager.shared.getSpecialPkgInfo())
    }
    public class func getGrayscalePkgInfo() -> String {
        return generatePkgInfoToString(GeckoPackageManager.shared.getGrayscalePkgInfo())
    }
    public class func getGeckoPkgInfo() -> String {
        return generatePkgInfoToString(GeckoPackageManager.shared.getGeckoPkgInfo())
    }
}

// MARK: - GeckoEventListener
extension DocsSDK: GeckoEventListener {
    public func packageWillUpdate(_ gecko: GeckoPackageManager?, in channel: GeckoChannleType) {
    }

    public func packageDidUpdate(_ gecko: GeckoPackageManager?, in channel: GeckoChannleType, isSuccess: Bool, needReloadRN: Bool) {
        switch channel {
        case .webInfo:
            DocsLogger.info("gecko_hotfix: webInfo packageDidUpdate, tryTo preload and reload RN ", component: LogComponents.editorPool)
            if User.current.info != nil {
                NotificationCenter.default.post(name: Notification.Name.Docs.geckoPackageDidUpdate, object: nil, userInfo: nil)
            }
            if needReloadRN {
                RNManager.manager.reloadBundleAfterGeckoPacageUpdate()
            }
        case .bitable: DocsLogger.info("gecko_hotfix: bitable channel did updated")
        default: DocsLogger.warning("gecko_hotfix: unsupport channel updated")
        }
    }
}
