//
//  SpaceKit+Mina.swift
//  SpaceKit
//
//  Created by chenhuaguan on 2020/5/24.
//

import Foundation
import RxSwift
import SwiftyJSON
import SKBrowser
import SKFoundation
import SKCommon
import SKSpace
import SKDrive
import SKInfra

extension DocsSDK {

    public func handleRemoteConfigData() {
        self.handleMinaDataUpdate()
        self.actionAfterMinaUpdate()
        /// 拉取成功or失败都会发通知
        NotificationCenter.default.post(name: Notification.Name.minaConfigFinishRequest, object: nil)
    }

    private func handleMinaDataUpdate() {
        DocsLogger.info("handleMinaDataUpdate", component: LogComponents.minaConfig)
        self.handleNetworkTimeout()
        self.handleSpaceUserGuide()
        self.handleH5UrlPathConfig()
        self.handleOnboarding()
        self.handleFolderPermissionHelpConfig()
        self.saveDomainConfigFrom()
        self.saveMoreViewContrllerNewFeature()
        self.setNeedDelayDeallocWebview()
        self.saveEditorAddToViewTime()
        self.handleDrivePreloadConfig()
        self.handleDragAndDropEnable()
        self.handleDocsLauncherV2Enable()
        self.saveAbandonOversea()
        self.savePreloadJSModule()
        self.handleGrammarCheckEnabled()
        self.saveShareLinkToastURL()
    }

    private func handleNetworkTimeout() {
        let carrierTimeout = SettingConfig.carrierTimeout
        if let carrierTimeout = carrierTimeout {
            userResolver.docs.netConfig?.timeoutConfig.carrierTimeout = carrierTimeout
        }
        let wifiTimeout = SettingConfig.wifiTimeout
        if let wifiTimeout = wifiTimeout {
            userResolver.docs.netConfig?.timeoutConfig.wifiTimeout = wifiTimeout
        }
    }

    private func handleSpaceUserGuide() {
        if let manualOfflineConfig = SettingConfig.manualOfflineConfig {
            ManualOfflineConfig.saveConfigToLocal(manualOfflineConfig)
        }
    }
    
    // 将 SettingConfig.domainConfig 替换成 mockConfig 可以模拟 settings 域名下发调试
//    private var mockConfig: [String: Any]? {
//        JSON(parseJSON: "{\"enable\":true,\"pathlist\":[\"space\"],\"newPathEnable\":true,\"wikiDirectMap\":{\"k\":\"doc\",\"a\":\"sheet\",\"e\":\"file\",\"c\":\"mindnote\",\"d\":\"slide\",\"b\":\"bitable\"},\"h5PathPrefix\":\"\",\"productMap\":{\"bitable\":\"bitable\",\"folder\":\"folder\",\"record\":\"bitable\",\"mindnote\":\"mindnote\",\"docx\":\"docx\",\"wiki\":\"wiki\",\"isv\":\"isv\",\"sheet\":\"sheet\",\"slide\":\"slides\",\"docs\":\"doc\",\"slides\":\"slides\",\"sheets\":\"sheet\",\"base\":\"bitable\",\"file\":\"file\",\"mindnotes\":\"mindnote\",\"doc\":\"doc\",\"base/add\":\"baseAdd\"},\"blackPathList\":[\"/space/api/explorer/clone\"],\"folderPathPrefix\":\"drive\",\"lateastMap\":{\"docx\":\"docx\",\"sheet\":\"sheets\",\"folder\":\"folder\",\"doc\":\"docs\",\"slides\":\"slides\",\"bitable\":\"base\",\"wiki\":\"wiki\",\"file\":\"file\",\"mindnote\":\"mindnotes\",\"isv\":\"isv\",\"baseAdd\":\"baseAdd\"},\"productJoinWiki\":[\"doc\",\"docs\"],\"phoenixPathPrefix\":\"workspace\",\"pathMap\":{\"/shared/folders/\":\"share_root\",\"/help/\":\"help\",\"/space/native/newyearsurvey/\":\"newyear_survey\",\"/drive/home/recents/\":\"recent\",\"/drive/help/doc/\":\"help\",\"/home/recents/\":\"recent\",\"/space/home/recents/\":\"recent\",\"/space/home/share/files/\":\"share\",\"/home/star/\":\"star\",\"/space/help/\":\"help\",\"/drive/share/folders/\":\"share_root\",\"/space/bitable/\":\"bitable_home\",\"/drive/me/\":\"folder\",\"/drive/home/share/files/\":\"share\",\"/drive/help/\":\"help\",\"/space/me/\":\"folder\",\"/space/app/upgrade/\":\"upgrade\",\"/drive/template-center/\":\"template_center\",\"/space/help/doc/\":\"help\",\"/space/wiki/\":\"wiki_home\",\"/drive/\":\"recent\",\"/native/newyearsurvey/\":\"newyear_survey\",\"/drive/shared/\":\"share_root\",\"/drive/home/star/\":\"star\",\"/space/folder/\":\"folder\",\"/drive/home/\":\"recent\",\"/drive/shared/folders/\":\"share_root\",\"/wiki/\":\"wiki_home\",\"/space/home/star/\":\"star\",\"/space/shared/folders/\":\"share_root\",\"/space/home/\":\"recent\",\"/home/\":\"recent\",\"/home/share/files/\":\"share\",\"/space/shared/\":\"share_root\",\"/drive/favorites/\":\"star\",\"/drive/app/upgrade/\":\"upgrade\",\"/help/doc/\":\"help\",\"/space/\":\"recent\",\"/space/help/about-best/\":\"help\",\"/app/upgrade/\":\"upgrade\",\"/share/folders/\":\"share_root\",\"/help/about-best/\":\"help\",\"/space/share/folders/\":\"share_root\",\"/drive/template_center/\":\"template_center\",\"/drive/folder/\":\"folder\",\"/space/favorites/\":\"star\",\"/folder/\":\"folder\"},\"pathGenerator\":{\"phoenix\":\"/workspace/${type}/${token}\",\"default\":\"/${type}/${token}\",\"blank\":\"/blank/\",\"folder\":\"/drive/${type}/${token}\",\"upgrade\":\"/space/app/upgrade\",\"baseAdd\":\"/base/add/${token}\"},\"whitePathList\":[\"/workspace/\",\"/blank/\",\"/space/blank/\",\"/drive/blank/\",\"/(doc|docs|sheet|sheets|mindnote|mindnotes|slide|slides|file|folder|wiki|isv|docx)/\",\"/app/upgrade\",\"/(base|bitable)/(?!automation|feed|tools/import)\",\"/drive/(?!preview/player)\",\"/space/(?!api/box)\",\"/record/\"],\"tokenPattern\":{\"tokenReg\":\"/([\\\\w]{14,})\",\"urlReg\":\"^(/space|/drive|/workspace)?/(?<type>(doc|docs|sheet|sheets|mindnote|mindnotes|slide|slides|file|base/add|bitable|base|record|folder|wiki|isv|docx))(?<!/workspace/file)/(?<token>[^\\\\/]{14,})\",\"typeReg\":\"/(doc|docs|sheet|sheets|mindnote|mindnotes|slide|slides|file|base/add|bitable|base|record|folder|wiki|isv|docx)/\",\"androidUrlReg\":\"^(/space|/drive|/workspace)?/(doc|docs|sheet|sheets|mindnote|mindnotes|slide|slides|file|base/add|bitable|base|record|folder|wiki|isv|docx)(?<!/workspace/file)/[^\\\\/]{14,}(/)?\"}}").dictionaryObject
//    }

    private func handleH5UrlPathConfig() {
        if let h5UrlPathConfig = SettingConfig.domainConfig {
            H5UrlPathConfig.saveToLocal(h5UrlPathConfig)
        }
    }

    private func handleOnboarding() {
        if let disabledOnboardings = SettingConfig.disabledOnboardingList {
            OnboardingManager.shared.prepare(disabling: disabledOnboardings)
            CCMKeyValue.globalUserDefault.set(disabledOnboardings, forKey: UserDefaultKeys.disabledOnboardings)
        }
    }

    private func handleFolderPermissionHelpConfig() {
        /// 共享文件夹需求
        if let folderPermissionHelpConfig = SettingConfig.folderPermissionHelpConfigOri {
            CCMKeyValue.globalUserDefault.set(folderPermissionHelpConfig, forKey: UserDefaultKeys.folderPermissionHelpConfig)
        }
    }

    private func saveDomainConfigFrom() {
        let domainRawDic = SettingConfig.domainConfig ?? [:]
        let domainConfig = JSON(domainRawDic)
        ///  isNewDomain默认值改为true, 因为stage环境有些配置下发为空，用旧域名访问不了
        let isNewDomain = domainConfig["enable"].bool ?? true
        let validPaths = domainConfig["pathlist"].arrayValue
            .compactMap({ $0.string?.trimmingCharacters(in: .whitespacesAndNewlines) })
            .filter({ !$0.isEmpty && !$0.contains("/") })
        let urlMatchPatterns = domainConfig["patterns"].arrayValue.compactMap({ $0.string })
        CCMKeyValue.globalUserDefault.set(isNewDomain, forKey: UserDefaultKeys.isNewDomainSystemKey)
        CCMKeyValue.globalUserDefault.setStringArray(validPaths, forKey: UserDefaultKeys.validPathsKey)
        CCMKeyValue.globalUserDefault.setStringArray(urlMatchPatterns, forKey: UserDefaultKeys.validURLMatchKey)
        DocsLogger.info("get domainConfig \(domainConfig) from server", component: LogComponents.domain)
        DocsUrlUtil.updateConfig(domainConfig)
    }

    private func saveMoreViewContrllerNewFeature() {
        guard let moreVCFeatureConfig = SettingConfig.moreNewItems else { return }
        CCMKeyValue.globalUserDefault.setDictionary(moreVCFeatureConfig, forKey: UserDefaultKeys.moreVCNewFeature)
    }

    private func setNeedDelayDeallocWebview() {
        OpenAPI.needDelayDeallocWebview = true
        DocsLogger.info("need delay dealloc webview? true")
    }

    private func saveEditorAddToViewTime() {
        guard let timeStr = SettingConfig.editorAddViewTime?.lowercased() else {
            return
        }
        let addToViewTime = EditorAddToViewTime(rawValue: timeStr) ?? EditorAddToViewTime.default
        OpenAPI.editorAddToViewTime = addToViewTime
    }

    private func handleDrivePreloadConfig() {
        DocsContainer.shared.resolve(DrivePreloadServiceBase.self)?.update(config: DriveFeatureGate.defaultPreloadConfig)
    }
    private func handleDragAndDropEnable() {
        let ddEnable = true
        CCMKeyValue.globalUserDefault.set(ddEnable, forKey: UserDefaultKeys.dragAndDropEnable)
    }
    private func handleDocsLauncherV2Enable() {
        guard let monitorInterval = SettingConfig.launcherV2Config?.monitorInterval,
              let leisureCondition = SettingConfig.launcherV2Config?.leisureCondition,
              let leisureTimes = SettingConfig.launcherV2Config?.leisureTimes else {
            DocsLogger.error("failed to get SubLauncherV2Config")
            return
        }
        CCMKeyValue.globalUserDefault.set(monitorInterval, forKey: UserDefaultKeys.monitorInterval)
        CCMKeyValue.globalUserDefault.set(leisureCondition, forKey: UserDefaultKeys.leisureCondition)
        CCMKeyValue.globalUserDefault.set(leisureTimes, forKey: UserDefaultKeys.leisureTimes)
    }

    private func saveAbandonOversea() {
        let docsAbandonOverseaEnable = false
        CCMKeyValue.globalUserDefault.set(docsAbandonOverseaEnable, forKey: UserDefaultKeys.docsAbandonOverseaEnable)

    }

    private func savePreloadJSModule() {
        guard let preloadJSModule = SettingConfig.preloadJsmoduleConfig else {
            return
        }
        CCMKeyValue.globalUserDefault.set(preloadJSModule, forKey: UserDefaultKeys.preloadJSModuleInfo)
    }

    private func handleGrammarCheckEnabled() {
        let grammarCheckEnabled = LKFeatureGating.systemGrammarCheckOnIOSEnabled
        CCMKeyValue.globalUserDefault.set(grammarCheckEnabled, forKey: UserDefaultKeys.grammarCheckEnabled)
    }

    private func saveShareLinkToastURL() {
        guard let shareLinkToastURL = SettingConfig.policyConfig else {
            DocsLogger.error("failed to get share link toast url")
            return
        }
        let dic = [
            StructPolicyConfig.CodingKeys.serviceTermUrl.rawValue: shareLinkToastURL.serviceTermUrl,
                   StructPolicyConfig.CodingKeys.privacyUrl.rawValue: shareLinkToastURL.privacyUrl
        ]
        CCMKeyValue.globalUserDefault.setDictionary(dic, forKey: UserDefaultKeys.shareLinkToastURL)
    }
}


extension DocsSDK {

    private func actionAfterMinaUpdate() {
        DomainConfig.updateValidUrlPatternsV2()
        userResolver.docs.netConfig?.updateBaseUrl(OpenAPI.docs.baseUrl)
    }
}
