//
//  EMAProtocolImpl.swift
//  Lark
//
//  Created by fanlv on 2018/7/5.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import AnimatedTabBar
import CryptoSwift
import EEMicroAppSDK
import EENavigator
import LKCommonsLogging
import LKCommonsTracker
import LarkAccountInterface
import LarkAppConfig
import LarkAppLinkSDK
import LarkAppStateSDK
import LarkContainer
import LarkCore
import LarkFeatureGating
import LarkFoundation
import LarkLocationPicker
import LarkMessengerInterface
import LarkModel
import LarkMonitor
import LarkNavigator
import LarkReleaseConfig
import LarkSetting
import LarkSDKInterface
import LarkUIKit
import RxSwift
import Swinject
import LarkTab
import OPFoundation
import LarkOPInterface
import LarkBytedCert
import SpaceInterface
import WebBrowser
import LarkWaterMark
import LarkMicroApp
import RustPB
import LarkRustClient
import TTMicroApp
import UniverseDesignToast
import UIKit
import ECOInfra
import ECOProbe
import EcosystemWeb
import LarkSetting

fileprivate extension OpenAPIChooseContactAPIExEmployeeFilterType {
    func mappedPickerUserResignFilterType() -> UserResignFilter {
        switch self {
        case .all: return .all
        case .exEmployee: return .resigned
        case .employee: return .unresigned
        }
    }
}

class EMAProtocolImpl: NSObject, EMAProtcolAppendProxy {
    
    @RealTimeFeatureGating(key: "openplatform.api.openschema.ipad.webnav.fix") private var openSchemaPadWebNavFixEnabled: Bool

    @RealTimeFeatureGatingProvider(key: "openplatform.infra.open_router_ipad_fix") private var routerPadPushFixEnabled: Bool

    @RealTimeFeatureGating(key: "openplatform.api.chat.enable_choose_chat_callback_delay")
    private static var enableChooseChatCallbackDelay: Bool
    
    @RealTimeFeatureGatingProvider(key: "openplatform.api.choose_contact_show_detail_enabled")
    private var chooseContactShowDetailEnabled: Bool

    let resolver: Resolver
    static let logger = Logger.oplog(EMAProtocolImpl.self, category: "EEMicroApp")
    let disposeBag = DisposeBag()

    @Provider private var dependency: MicroAppDependency
    @Provider private var openPlatformDependency: OpenPlatformDependency
    @Provider private var appBadgeListenerService: AppBadgeListenerService
    @Provider private var outerService: OpenPlatformOuterService

    // 该选项对应 Admin 后台配置
    var isGlobalWaterMarkShow: Bool = false

    // 是否正在显示水印
    var isWaterMarkDisplaying: Bool = false
    
    /// 开放平台反馈配置：检查是否要显示小程序版本的反馈，提供小程序 applink
    private var opFeedbackConfig: FeedbackConfig? = {
        return FeedbackConfig(config: ECOConfig.service().getDictionaryValue(for: FeedbackConfig.ConfigName) ?? [:])
    }()
    
    // 由于后面依赖了 WaterMarkService，这里的 init 时机需要足够精准，过于提前可能会无法取到 WaterMarkService
    required init(resolver: Resolver) {
        self.resolver = resolver
        super.init()
    }

    public func regist() {
        // 设置个人简介block
        EMARouteMediator.sharedInstance().enterProfileBlock = { [weak self] (userid, uniqueID, controller) in
            guard let `self` = self else {
                EMAProtocolImpl.logger.error("[EMAProtocolImpl]: can not open bot chat without chat service")
                return
            }
            let window = controller?.view.window ?? uniqueID?.window
            self.outerService.enterProfile(userId: userid, window: window)
        }

        // 设置打开聊天block
        EMARouteMediator.sharedInstance().enterChatBlock = { [weak self] (chatid, showBadge, uniqueID, controller) in
            guard let `self` = self else {
                EMAProtocolImpl.logger.error("[EMAProtocolImpl]: can not open bot chat without chat service")
                return
            }
            let window = controller?.view.window ?? uniqueID?.window
            self.outerService.enterChat(chatId: chatid, showBadge: showBadge, window: window)
        }
        //打开bot回话页
        EMARouteMediator.sharedInstance().enterBotBlock = { [weak self] (botid, uniqueID, controller) in
            guard let `self` = self else {
                EMAProtocolImpl.logger.error("[EMAProtocolImpl]: can not open bot chat without chat service")
                return
            }
            let window = controller?.view.window ?? uniqueID?.window
            self.outerService.enterBot(botId: botid, window: window)
        }

        // 选择联系人，支持头条圈评论输入框@联系人操作
        EMARouteMediator.sharedInstance().getPickChatterVCBlock = { [weak self] (multi, ignore, externalContact, enableExternalSearch, showRelatedOrganizations, enableChooseDepartment, selectedUserIDs, hasMaxNum, maxNum, limiteTips, disableIds, exEmployeeFilterType) -> UIViewController? in
            guard let `self` = self else {
                return nil
            }
            let currentAccount = AccountServiceAdapter.shared
            var body = ChatterPickerBody()
            body.title = BundleI18n.LarkOpenPlatform.Lark_Legacy_ChooseContact
            body.permissions = [.checkBlock]
            body.selectStyle = multi ? .multi : .single(style: .callback)
            body.disabledSelectedChatterIds = ignore ? [currentAccount.currentChatterId] : []
            body.targetPreview = false
            if self.chooseContactShowDetailEnabled {
                body.supportUnfoldSelected = true
            }
            if let externalSearch = enableExternalSearch as? Bool, let relatedOrg = showRelatedOrganizations as? Bool {
                // 过渡逻辑: externalSearch影响是否能搜索; externalSearch开的情况下, externalContact和showRelatedOrganizations的值才有意义
                body.showExternalContact = externalContact
                body.needSearchOuterTenant = externalSearch
                body.enableRelatedOrganizations = relatedOrg
                if externalSearch, !externalContact {
                    body.filterOuterContact = true
                }
            } else { // 老逻辑: externalContact 统一控制 外部联系人入口显隐和搜索 + 关联组织入口显隐和搜索
                body.needSearchOuterTenant = externalContact
            }
            if let selectedUserIDs = selectedUserIDs {
                body.defaultSelectedChatterIds = selectedUserIDs
            }
            if ChatAndContactSettings.isChooseContactStandardizeEnabled {
                if let tip = limiteTips, hasMaxNum {
                    body.limitInfo = SelectChatterLimitInfo(max: maxNum, warningTip: tip)
                }
            } else {
                if let tip = limiteTips, maxNum > 0 {
                    body.limitInfo = SelectChatterLimitInfo(max: maxNum, warningTip: tip)
                }
            }
            if let disbles = disableIds {
                body.forceSelectedChatterIds = disbles
            }
            body.supportSelectOrganization = enableChooseDepartment
            if let exEmployeeFilterTypeStr = exEmployeeFilterType { // 离职人员搜索配置
                body.userResignFilter = OpenAPIChooseContactAPIExEmployeeFilterType(rawValue: exEmployeeFilterTypeStr)?.mappedPickerUserResignFilterType()
            }
            body.selectedCallback = { [weak self] (vc, result) in
                // 回调回来的是chatterIds，这里需要先转成Chatter，然后再@
                guard let `self` = self, let chatterAPI = self.resolver.resolve(ChatterAPI.self), let controller = vc else {
                    if let completion = EMARouteMediator.sharedInstance().selectChatterNamesBlock?(nil, nil, nil) {
                        completion()
                    }
                    return
                }
                let selectedChatterIDs = result.chatterInfos.map { $0.ID }
                do {
                    let chatterDict = try chatterAPI.getChattersFromLocal(ids: selectedChatterIDs)
                    let departmentIds = result.departmentIds
                    if !chatterDict.isEmpty {
                        // 确保联系人顺序与选择的顺序一致
                        var names: [String] = []
                        var IDs: [String] = []
                        for chatterID in selectedChatterIDs {
                            guard let chatter = chatterDict[chatterID] else {
                                continue
                            }
                            names.append(chatter.localizedName)
                            IDs.append(chatterID)
                        }
                        controller.dismiss(animated: true, completion: {
                            let completion = EMARouteMediator.sharedInstance().selectChatterNamesBlock?(names, IDs, departmentIds)
                            completion?()
                        })
                    } else {
                       
                        controller.dismiss(animated: true, completion: {
                            let completion = EMARouteMediator.sharedInstance().selectChatterNamesBlock?(nil, nil, departmentIds)
                            completion?()
                        })
                    }
                } catch {
                    controller.dismiss(animated: true, completion: {
                        let completion = EMARouteMediator.sharedInstance().selectChatterNamesBlock?(nil, nil, nil)
                        completion?()
                    })
                   
                }
            }
            guard let nav = Navigator.shared.response(for: body).resource as? LkNavigationController, let vc = nav.viewControllers.last as? BaseUIViewController else { return nil }
            vc.closeCallback = {
                if let completion = EMARouteMediator.sharedInstance().selectChatterNamesBlock?(nil, nil, nil) {
                    completion()
                }
            }
            return nav
        }
        if let waterMarkService = resolver.resolve(WaterMarkService.self) {
            waterMarkService
            .globalWaterMarkIsShow
            .subscribe(onNext: { [weak self] (isShow) in
                self?.isGlobalWaterMarkShow = isShow
            }).disposed(by: self.disposeBag)

            waterMarkService
            .globalWaterMarkIsFirstView
            .subscribe(onNext: { [weak self] (_, isDisplaying) in
                self?.isWaterMarkDisplaying = isDisplaying
                NotificationCenter.default.post(name: .WatermarkDidChange, object: nil, userInfo: [Notification.Watermark.Key: isDisplaying])
                EMAProtocolImpl.logger.info("Watermark isDisplaying \(isDisplaying)")
            }).disposed(by: self.disposeBag)
        } else {
            EMAProtocolImpl.logger.error("waterMarkService is nil")
            assertionFailure("waterMarkService is nil")
        }
    }
}

fileprivate let domain = "com.gadget.EMAProtocolImpl"
fileprivate let noImpCode = -1
fileprivate let noImpInfo = [NSLocalizedDescriptionKey: "api imp missing"]
fileprivate let noImpErr = NSError(domain: domain, code: noImpCode, userInfo: noImpInfo)

extension EMAProtocolImpl: EMAProtocol {
    // code from zhangyushan 未进行任何逻辑改动 只是代码换一个位置
    /// 通过 avatar key 从 Rust 层同步获取 avatar URL，不要在主线程调用
    func getAvatarURL(withKey key: String) -> String {
        
        guard let service = try? resolver.resolve(assert: RustService.self) else {
            Self.logger.error("RustService is nil!")
            return ""
        }

        var request = Media_V1_GetResourceUrlsRequest()
        request.key = key

        var param = Media_V1_AvatarFsUnitParams()
        param.sizeType = .small
        request.avatarFsUnitParams = param

        do {
            let response: Media_V1_GetResourceUrlsResponse = try service.sendSyncRequest(request)
            if let str = response.urls.first {
                return str
            }
            Self.logger.error("nil avatar url! key: \(key)")
        } catch {
            Self.logger.error("avatar url fetch failed, key: \(key), err: \(error)")
        }
        return ""
    }
    
    //  只是代迁移API，未修改任何逻辑，建议API组研究一下如何合并到openshcema
    func internalCanOpen(_ url: URL) -> Bool {
        let param = Navigator.shared.response(for: url, test: true).parameters
        if param["_canOpenInDocs"] as? Bool == true {
            return true
        }
        if param["_canOpenInMicroApp"] as? Bool == true {
            return true
        }
        if param[AppLinkAssembly.KEY_CAN_OPEN_APP_LINK] as? Bool == true {
            return true
        }
        return false
    }

    func getExperimentValue(forKey key: String, withExposure: Bool) -> Any? {
        ///为什么要延时拉取，因为当前的接口在Lark启动后时间比较早，获取试验组件返回为空
        ///时序上不满足
        saveExperimentValueLater(key: key, withExposure: withExposure)
        if let value = getLocalExperimentValue(key: key) {
            return value
        }
        if key == GadgetEngineConfig.key {
            if let setting = self.resolver.resolve(UserGeneralSettings.self) {
                var datas: [String: Any] = setting.gadgetABTestConfig.preloadInfo
                datas["use"] = setting.gadgetABTestConfig.enablePreload
                return datas
            }
            return ["use": true]
        }
        return nil
    }

    func saveExperimentValueLater(key: String, withExposure: Bool) {
        let experimentKey = AccountServiceAdapter.shared.currentChatterId + key
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            if let value = Tracker.experimentValue(key: key,
                                                   shouldExposure: withExposure) {
                EMAProtocolImpl.logger.info("\(experimentKey) saveExperimentValueLater 15 \(value)")
                UserDefaults.standard.set(value, forKey: experimentKey)
            } else {
                UserDefaults.standard.set(nil, forKey: experimentKey)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            if let value = Tracker.experimentValue(key: key,
                                                   shouldExposure: withExposure) {
                EMAProtocolImpl.logger.info("\(experimentKey) saveExperimentValueLater 60 \(value)")
                UserDefaults.standard.set(value, forKey: experimentKey)
            } else {
                UserDefaults.standard.set(nil, forKey: experimentKey)
            }
        }
    }

    func getLocalExperimentValue(key: String) -> Any? {
        let experimentKey = AccountServiceAdapter.shared.currentChatterId + key
        return UserDefaults.standard.object(forKey: experimentKey)
    }

    func setHMDInjectedInfoWith(_ notification: Notification!, localLibVersionString: String!) {
        let injectedInfo: HMDInjectedInfo? = HMDInjectedInfo.default()  // 对OC代码nonnull声明不信任，强制判空
        if let appid = notification.userInfo?["mp_id"],
           let injectedInfo = injectedInfo {
            injectedInfo.setCustomContextValue(appid, forKey: "tma_app_id")
            injectedInfo.setCustomFilterValue(appid, forKey: "tma_app_id")
            injectedInfo.setCustomContextValue(localLibVersionString ?? "", forKey: "tma_jssdk_version")
            injectedInfo.setCustomFilterValue(localLibVersionString ?? "", forKey: "tma_jssdk_version")
        }
    }

    func removeHMDInjectedInfo() {
        let injectedInfo: HMDInjectedInfo? = HMDInjectedInfo.default() // 对OC代码nonnull声明不信任，强制判空
        if let injectedInfo = injectedInfo {
            injectedInfo.removeCustomFilterKey("tma_app_id")
            injectedInfo.removeCustomContextKey("tma_app_id")
            injectedInfo.removeCustomFilterKey("tma_jssdk_version")
            injectedInfo.removeCustomContextKey("tma_jssdk_version")
        }
    }

    func monitorService(_ service: String, metricsData: [AnyHashable: Any] = [:], categoriesData: [AnyHashable: Any] = [:], platform: OPMonitorReportPlatform) {
        var categoriesData = categoriesData
        if platform.contains(.slardar) {
            Tracker.post(SlardarEvent(name: service, metric: metricsData, category: categoriesData, extra: [:]))
        }
        if platform.contains(.tea) {
            var params = categoriesData
            if (!params.keys.contains("solution_id")) {
                params["solution_id"] = "none"
            }
            if (params.keys.contains("solution_id") && params["solution_id"] as? String == "") {
                params["solution_id"] = "none"
            }
            params.merge(other: metricsData)
            Tracker.post(TeaEvent(service, params: params))
        }
    }

    func getTriggerContext(
        withTriggerCode triggerCode: String,
        block: EMATriggerContextResultBlock? = nil
    ) {
        guard let op = resolver.resolve(OpenPlatformService.self) else {
            EMAProtocolImpl.logger.error("引擎胶水模块：获取OpenPlatformService失败")
            block?(["error": "get OpenPlatformService failed"])
            return
        }
        op.getTriggerContext(withTriggerCode: triggerCode, block: block)
    }

    func sendMessageCard(
        with uniqueID: OPAppUniqueID?,
        scene: String,
        triggerCode: String?,
        chatIDs: [String]?,
        cardContent: [AnyHashable : Any],
        withMessage: Bool = false,
        block: EMASendMessageCardResultBlock? = nil
    ) {
        guard let uniqueID = uniqueID else {
            EMAProtocolImpl.logger.error("uniqueID is nil")
            block?(.otherError, "uniqueID is nil", nil, nil, nil)
            return
        }
        let appID = uniqueID.appID
        EMAProtocolImpl.logger.info("start send message card \(appID)")
        guard let op = resolver.resolve(OpenPlatformService.self) else {
            EMAProtocolImpl.logger.error("引擎胶水模块：获取OpenPlatformService失败")
            block?(.otherError, "get OpenPlatformService failed", nil, nil, nil)
            return
        }
        op.sendMessageCard(appID:appID,
                           fromWindow:uniqueID.window,
                           scene: scene,
                           triggerCode: triggerCode,
                           chatIDs: chatIDs,
                           cardContent: cardContent,
                           withMessage: withMessage) { (errCode, errMsg, failedChatIDs, sendCardinfos, sendTextInfos)  in
                            EMAProtocolImpl.logger.info("start send message card \(appID) resp \(errCode) \(String(describing: errMsg))")
                            var retErrCode: EMASendMessageCardErrorCode = .noError
                            switch errCode {
                            case .noError:
                                retErrCode = .noError
                            case .cardContentFormatError:
                                retErrCode = .cardContentFormatError
                            case .sendFailed:
                                retErrCode = .sendFailed
                            case .userCancel:
                                retErrCode = .userCancel
                            case .otherError:
                                retErrCode = .otherError
                            case .sendTextError:
                                retErrCode = .sendTextError
                            @unknown default:
                                retErrCode = .sendFailed
                            }
                            block?(retErrCode, errMsg, failedChatIDs, sendCardinfos, sendTextInfos)
        }
    }
    //和上面函数保持一致，目前代码耦合严重，本期需求无空闲时间解耦，推荐owner进行重构
    func chooseSendCard(with uniqueID: OPAppUniqueID?,
                        cardContent: [AnyHashable : Any],
                        withMessage: Bool,
                        params: SendMessagecardChooseChatParams,
                        res: @escaping EMASendMessageCardResultBlock) {
        guard let uniqueID = uniqueID else {
            EMAProtocolImpl.logger.error("uniqueID is nil")
            res(.otherError, "uniqueID is nil", nil, nil, nil)
            return
        }
        let appID = uniqueID.appID
        EMAProtocolImpl.logger.info("start choose chat and send message card \(appID)")
        guard let op = resolver.resolve(OpenPlatformService.self) else {
            EMAProtocolImpl.logger.error("获取OpenPlatformService失败")
            res(.otherError, "get OpenPlatformService failed", nil, nil, nil)
            return
        }
        let model = SendMessagecardChooseChatModel(allowCreateGroup: params.allowCreateGroup, multiSelect: params.multiSelect, confirmTitle: params.confirmTitle, externalChat: params.externalChat, withText: withMessage, selectType: SelectType(rawValue: params.selectType) ?? .all, ignoreSelf: params.ignoreSelf, ignoreBot: params.ignoreBot)
        op.chooseChatAndSendMsgCard(appid: appID, cardContent: cardContent, model: model, withMessage: withMessage) { (errCode, errMsg, failedChatIDs, sendCardinfos, sendTextInfos) in
            EMAProtocolImpl.logger.info("start choose chat and send message card \(appID) resp \(errCode) \(String(describing: errMsg))")
            var retErrCode: EMASendMessageCardErrorCode = .noError
            switch errCode {
            case .noError:
                retErrCode = .noError
            case .cardContentFormatError:
                retErrCode = .cardContentFormatError
            case .sendFailed:
                retErrCode = .sendFailed
            case .userCancel:
                retErrCode = .userCancel
            case .otherError:
                retErrCode = .otherError
            case .sendTextError:
                retErrCode = .sendTextError
            @unknown default:
                retErrCode = .otherError
            }
            res(retErrCode, errMsg, failedChatIDs, sendCardinfos, sendTextInfos)
        }
    }

    func appName() -> String! {
        ReleaseConfig.isLark ? "Lark" : "Feishu"
    }

    func trackerEvent(_ event: String?, params: [AnyHashable: Any]?, option: OPMonitorReportPlatform) {
        guard let event = event, let params = params as? [String: Any] else { return }
        if (option.contains(.slardar)) {
            Tracker.post(SlardarEvent(name: event, metric: [:], category: params, extra: [:]))
        }
        if (option.contains(.tea)) {
            Tracker.post(TeaEvent(event, params: params))
        }
    }

    func shareWebUrl(_ url: String?, title: String?, content: String?) {
        guard let url = url, let title = title else { return }
        guard let visibleViewController = Navigator.shared.mainSceneWindow?.lu.visibleViewController() else { return }
        let body = ShareContentBody(title: title, content: url)
        Navigator.shared.present(
            body: body,
            from: visibleViewController,
            prepare: { $0.modalPresentationStyle = .formSheet })
    }
    func canOpen(_ url: URL!, fromScene: OpenUrlFromScene) -> Bool {
        let param = Navigator.shared.response(for: url, context: ["isFromWebviewComponent": fromScene == .webView], test: true).parameters
        
        Self.logger.info("canOpen navigator parse params: \(param)")
        
        if fromScene == .openSchemaExternalFalse {
            return param[ContextKeys.matched] as? Bool ?? false
        } else {
            return ((param["_canOpenInDocs"] as? Bool == true) || (param["_canOpenInMicroApp"] as? Bool == true) || (param[AppLinkAssembly.KEY_CAN_OPEN_APP_LINK] as? Bool == true) || (param["_canOpenInMinutes"] as? Bool == true))
        }
    }
    func open(_ url: URL!, fromScene: OpenUrlFromScene, uniqueID: OPAppUniqueID?, from: UIViewController?) {
        if canOpen(url, fromScene: fromScene) {
            let window = from?.view.window ?? uniqueID?.window
            
            // FIX Issue 👉🏻 https://meego.feishu.cn/larksuite/issue/detail/5171025
            let iPadWebAppNavigationFixEnabled = UIDevice.current.userInterfaceIdiom == .pad && openSchemaPadWebNavFixEnabled && uniqueID?.appType == .webApp && (fromScene == .openSchemaExternalFalse || fromScene == .openSchemaExternalTrue)
            let needAddDocsParams = fromScene == .openSchemaExternalFalse || fromScene == .openSchemaExternalTrue || fromScene == .document

            let navigation = OPNavigatorHelper.topMostNavigation(window: window, options: [.OpenSchemaPadWebNavFixEnabled(iPadWebAppNavigationFixEnabled)])
            if let topVC = navigation {
                var context = [String: String]()
                if let uid = uniqueID{
                    if uid.appType == .gadget {
                        context["from"] = OPScene.micro_app.rawValue
                        if needAddDocsParams {
                            context["open_doc_source"] = "micro_app"
                            context["open_doc_desc"] = ""
                            context["open_doc_app_id"] = OPUnsafeObject(uid.appID) ?? ""
                        }
                        if url.queryParameters["op_tracking"] == "appstore" {
                            context["from_scene_report"] = "appStore"
                        }
                    } else if uid.appType == .webApp {
                        context["from"] = OPScene.web_url.rawValue
                        if needAddDocsParams {
                            context["open_doc_source"] = "web_applet"
                            context["open_doc_app_id"] = OPUnsafeObject(uid.appID) ?? ""
                        }
                        if let browser  = from as? WebBrowser {
                            context["lk_web_mode"] = browser.configuration.scene.rawValue
                            if needAddDocsParams {
                                context["open_doc_desc"] = browser.browserURL?.absoluteString ?? ""
                            }
                        }
                    }
                }
                if Display.pad, routerPadPushFixEnabled { // iPad下showDetail，规避SplitVC栈异常
                    Navigator.shared.showDetail(url, context: context, from: topVC, completion: nil)
                } else {
                    Navigator.shared.push(url, context: context, from: topVC, animated: true, completion: nil)
                }
            } else {
                EMAProtocolImpl.logger.error("EMAProtocolImpl openAboutVC can not push vc because no fromViewController")
            }
        }
    }

    func openInternalWebView(_ url: URL!, uniqueID: OPAppUniqueID?, from: UIViewController?) -> Bool {
        let parameters = Navigator.shared.response(for: url, test: true).parameters
        Self.logger.info("openInternalWebView navigator parse params: \(parameters)")
        
        let canOpenInWeb = parameters["_canOpenInWeb"] as? Bool == true
        let canOpenInOPWeb = parameters["_canOpenInOPWeb"] as? Bool == true

        if !(canOpenInWeb || canOpenInOPWeb) {
            return false
        }
        let window = from?.view.window ?? uniqueID?.window
        let navigation =  OPNavigatorHelper.topmostNav(window: window)
        if let topVC = navigation?.viewControllers.last {
            Navigator.shared.push(url, context: ["from": "micro_app"], from: topVC, animated: true, completion: nil)
        } else {
            EMAProtocolImpl.logger.error("EMAProtocolImpl openAboutVC can not push vc because no fromViewController")
        }
        return true
    }

    // 获取本地附件
    func filePicker(_ maxSelectedCount: Int,
                    pickerTitle title: String?,
                    pickerComfirm comfirm: String?,
                    uniqueID: OPAppUniqueID?,
                    from: UIViewController?,
                    block: @escaping (Bool, [[AnyHashable: Any]]?) -> Void) {
        var body = LocalFileBody()
        body.maxSelectCount = maxSelectedCount
        body.title = title
        body.sendButtonTitle = comfirm
        body.cancelCallback = {
            block(true, nil)
        }
        body.chooseLocalFiles = {files -> Void in
            var result: [[AnyHashable: Any]] = [[AnyHashable: Any]]()
            for localFile in files {
                if !localFile.name.isEmpty && !localFile.fileURL.path.isEmpty {
                    let size = "\(localFile.size ?? 0)"
                    let dic: [String: String] = [kEMASDKFilePickerName: localFile.name, kEMASDKFilePickerPath: localFile.fileURL.path, kEMASDKFilePickerSize: size]
                    result.append(dic)
                }
            }
            block(false, result)
        }
        if let fromVC = from ?? uniqueID?.window?.fromViewController {
            Navigator.shared.present(body: body,
                                     naviParams: nil,
                                     context: [:],
                                     wrap: LkNavigationController.self,
                                     from: fromVC,
                                     prepare: { $0.modalPresentationStyle = .fullScreen
            }, animated: true, completion: nil)
        } else {
            EMAProtocolImpl.logger.error("EMAProtocolImpl filePicker can not present vc because no fromViewController")
        }
    }
    func docsPickerTitle(_ title: String!,
                         maxNum num: Int,
                         confirm: String!,
                         uniqueID: OPAppUniqueID?,
                         from: UIViewController?,
                         block: (([AnyHashable: Any]?, Bool) -> Void)!) {

        if let fromVC = from ?? uniqueID?.window?.fromViewController {
            dependency.presendSendDocBody(maxSelect: num,
                                          title: title,
                                          confirmText: confirm,
                                          sendDocBlock: { (didConfirm, docs) in
                                            var arr = [Any]()
                                            for doc in docs {
                                                var dict = [String: Any]()
                                                dict["filePath"] = doc.url
                                                dict["fileName"] = doc.title
                                                arr.append(dict)
                                            }
                                            block(["fileList": arr], !didConfirm)
                                          },
                                          wrap: LkNavigationController.self,
                                          from: fromVC,
                                          prepare: { $0.modalPresentationStyle = .fullScreen },
                                          animated: true)
        } else {
            EMAProtocolImpl.logger.error("EMAProtocolImpl filePicker can not present vc because no fromViewController")
        }
    }

    func handleQRCode(_ qrCode: String!,
                      uniqueID: OPAppUniqueID?,
                      from: UIViewController?) -> Bool {
        guard let url = URL(string: qrCode) else {
            return false
        }
        let window = from?.view.window ?? uniqueID?.window
        let navigation =  OPNavigatorHelper.topmostNav(window: window)
        let context = [LarkAppLinkSDK.FromSceneKey.key: LarkAppLinkSDK.FromScene.press_image_qrcode.rawValue]
        if let topVC = navigation?.viewControllers.last {
            Navigator.shared.push(url, context: context, from: topVC, animated: true, completion: nil)
        } else {
            EMAProtocolImpl.logger.error("EMAProtocolImpl handleQRCode can not push vc because no fromViewController")
        }
        return true
    }

    /// 检查宿主是否启用了全局水印（该值用来体现 Admin 后端的配置）
    func checkWatermark() -> Bool {
        return self.isGlobalWaterMarkShow
    }

    /// 检查宿主是否显示了全局水印
    func hasWatermark() -> Bool {
        return self.isWaterMarkDisplaying
    }

        /// 打开关于页面
    func openAboutVC(with uniqueID: OPAppUniqueID?, appVersion: String) {
        guard let uniqueID = uniqueID else {
            EMAProtocolImpl.logger.error("uniqueID is nil")
            return
        }
        let appID = uniqueID.appID
        let params = [
            "version": appVersion
        ]
        let appSettingBody = AppSettingBody(
            appId: appID,
            params: params,
            scene: .MiniApp
        )
        let navigation =  OPNavigatorHelper.topmostNav(window: uniqueID.window)
        if let topVC = navigation?.viewControllers.last {
            Navigator.shared.push(body: appSettingBody, naviParams: nil, context: [:], from: topVC, animated: true, completion: nil)
        } else {
            EMAProtocolImpl.logger.error("EMAProtocolImpl openAboutVC can not push vc because no fromViewController")
        }
    }

    func shareCard(
        withTitle title: String?,
        uniqueID: OPAppUniqueID?,
        imageData: Data?,
        url: String?,
        appLinkHref: String?,
        options: EMAShareOptions = [],
        callback: EMAShareResultBlock? = nil
    ) {
        guard let uniqueID = uniqueID else {
            EMAProtocolImpl.logger.error("uniqueID is nil")
            callback?(nil, false)
            return
        }
        let appID = uniqueID.appID
        guard let title = title,
            let imageData = imageData,
            let url = url else {
                EMAProtocolImpl.logger.error("消息卡片分享小程序fg关闭或者数据不齐全")
                callback?(nil, false)
                return
        }
        guard let imageAPI = try? resolver.resolve(assert: ImageAPI.self) else {
            EMAProtocolImpl.logger.error("resolve ImageAPI is nil")
            callback?(nil, false)
            return
        }
        
        imageAPI.uploadSecureImage(data: imageData, type: .normal, imageCompressedSizeKb: 300)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self]imageKey in
                OPMonitor(EPMClientOpenPlatformShareCode.share_upload_image_success)
                    .setUniqueID(uniqueID)
                    .addCategoryValue("op_tracking", "opshare_gadget_pageshare")
                    .flush()
                let shareOptions = ShareOptions(rawValue: options.rawValue)
                let window = uniqueID.window ?? Navigator.shared.mainSceneWindow
                if let fromVC = window?.fromViewController {
                    self?.dependency.shareAppPageCard(
                        appId: appID,
                        title: title,
                        iconToken: imageKey,
                        url: url,
                        appLinkHref: appLinkHref,
                        options: shareOptions,
                        fromViewController: fromVC,
                        callback: { callback?($0, $1) }
                    )
                } else {
                    EMAProtocolImpl.logger.error("EMAProtocolImpl shareAppPageCard can not present vc because no fromViewController")
                }
            }, onError: { error in
                OPMonitor(EPMClientOpenPlatformShareCode.share_upload_image_failed)
                    .setUniqueID(uniqueID)
                    .addCategoryValue("op_tracking", "opshare_gadget_pageshare")
                    .setError(error)
                    .flush()
                callback?(nil, false)
            })
            .disposed(by: disposeBag)
    }

    func passwordVerify(for uniqueID: OPAppUniqueID?, block: (([String : Any]?) -> Void)!) {
        guard let uniqueID = uniqueID else {
            EMAProtocolImpl.logger.error("uniqueID is nil")
            block(nil)
            return
        }
        let appID = uniqueID.appID
        let service = AccountServiceAdapter.shared
        service.getSecurityStatus(appId: appID) { (code, errorMessage, token) in
            var dict = [String: Any]()
            dict["errCode"] = code
            dict["errMsg"] = errorMessage
            dict["token"] = token
            block(dict)
        }
    }
    
    func openMineAboutVC(with uniqueID: OPAppUniqueID?, from: UIViewController?) {
        let window = from?.view.window ?? uniqueID?.window
        let navigation = OPNavigatorHelper.topmostNav(window: window)
        if let topVC = navigation?.viewControllers.last {
            Navigator.shared.push(body: MineAboutLarkBody(), naviParams: nil, context: [:], from: topVC, animated: true, completion: nil)
        } else {
            EMAProtocolImpl.logger.error("EMAProtocolImpl openMineAboutVC can not push vc because no fromViewController")
        }
    }
    func chooseChat(_ params: [String: Any]!,
                    title: String!,
                    selectType type: Int,
                    uniqueID: OPAppUniqueID?,
                    from: UIViewController?,
                    block: (([String: Any]?, Bool) -> Void)!) {
        let allowCreateGroup = params["allowCreateGroup"] as? Bool ?? true
        let multiSelect = params["multiSelect"] as? Bool ?? true
        let ignoreSelf = params["ignoreSelf"] as? Bool ?? false
        let ignoreBot = params["ignoreBot"] as? Bool ?? false
        let externalChat = params["externalChat"] as? Bool ?? true
        let confirmDesc = params["confirmDesc"] as? String ?? ""
        let showMessageInput = params["showMessageInput"] as? Bool ?? false
        let confirmText = params["confirmText"] as? String
        let chosenOpenIds = (params["chosenOpenIds"] as? [String])?.map{ PreSelectInfo.chatterID($0) } ?? []
        let chosenOpenChatIds = (params["chosenOpenChatIds"] as? [String])?.map{ PreSelectInfo.chatID($0) } ?? []
        let preSelectInfos = chosenOpenIds + chosenOpenChatIds
        let showRecentForward = preSelectInfos.count <= 0
        var body: ChatChooseBody
        if EMAProtocolImpl.enableChooseChatCallbackDelay {
            var res: [String: Any]? = nil
            var cancel = false
            var callbackDone = false
            var forwardVCDismissDone = false

            let dispatchGroup: DispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            dispatchGroup.enter()
            body = ChatChooseBody(allowCreateGroup: allowCreateGroup,
                                  multiSelect: multiSelect,
                                  ignoreSelf: ignoreSelf,
                                  ignoreBot: ignoreBot,
                                  needSearchOuterTenant: externalChat,
                                  includeOuterChat: externalChat,
                                  selectType: type,
                                  confirmTitle: title,
                                  confirmDesc: confirmDesc,
                                  confirmOkText: confirmText,
                                  showInputView: showMessageInput,
                                  preSelectInfos: preSelectInfos,
                                  showRecentForward: showRecentForward,
                                  callback: { resData, isCancel in
                                    guard callbackDone == false else {
                                        EMAProtocolImpl.logger.error("chooseChat callback multi")
                                        return
                                    }
                                    callbackDone = true
                                    res = resData
                                    cancel = isCancel
                                    dispatchGroup.leave()
                                    EMAProtocolImpl.logger.info("chooseChat callback")
                                },
                                  forwardVCDismissBlock:  {
                                    guard forwardVCDismissDone == false else {
                                        EMAProtocolImpl.logger.error("chooseChat forwardVCDismissBlock multi")
                                        return
                                    }
                                    forwardVCDismissDone = true
                                    dispatchGroup.leave()
                                    EMAProtocolImpl.logger.info("chooseChat forwardVCDismissBlock")
                                })
            body.permissions = [.checkBlock]
            body.targetPreview = false
            dispatchGroup.notify(queue: .main) {
                guard let realBlock = block else { return }
                realBlock(res, cancel)
            }
        } else {
            body = ChatChooseBody(allowCreateGroup: allowCreateGroup,
                                  multiSelect: multiSelect,
                                  ignoreSelf: ignoreSelf,
                                  ignoreBot: ignoreBot,
                                  needSearchOuterTenant: externalChat,
                                  includeOuterChat: externalChat,
                                  selectType: type,
                                  confirmTitle: title,
                                  confirmDesc: confirmDesc,
                                  confirmOkText: confirmText,
                                  showInputView: showMessageInput,
                                  preSelectInfos: preSelectInfos,
                                  showRecentForward: showRecentForward,
                                  callback: block)
            body.permissions = [.checkBlock]
            body.targetPreview = false
        }
        let window = uniqueID?.window ?? Navigator.shared.mainSceneWindow
        if let fromVC = window?.fromViewController {
            let modalStyle: UIModalPresentationStyle = Display.pad ? .formSheet : .fullScreen
            Navigator.shared.present(body: body,
                                     naviParams: nil,
                                     context: [:],
                                     wrap: nil,
                                     from: fromVC,
                                     prepare: { $0.modalPresentationStyle = modalStyle
            }, animated: true, completion: nil)
        } else {
            EMAProtocolImpl.logger.error("EMAProtocolImpl chooseChat can not present vc because no fromViewController")
        }
    }
    // 迁移完成后统一使用OpenPluginChat里的方法
    func getChatInfo(_ chatId: String!) -> [AnyHashable: Any]? {
        guard let chatAPI = resolver.resolve(ChatAPI.self), let chatMap = try? chatAPI.getLocalChats([chatId]), let chat = chatMap[chatId] else { return nil }
        return ["badge": chat.unreadBadge]
    }
    func getAtInfo(_ chatId: String!, block: (([AnyHashable: Any]?) -> Void)!) {
        guard let messageAPI = resolver.resolve(MessageAPI.self) else {
            block(nil)
            return
        }
        var d = [String: Any]()
        messageAPI.fetchUnreadAtMessages(chatIds: [chatId], ignoreBadged: false, needResponse: true).map({ (chatMessagesMap) -> [Message] in
            return chatMessagesMap[chatId ?? ""] ?? []
        }).subscribe(onNext: { (unreadAtMessages) in
            var arr = [Any]()
            for message in unreadAtMessages {
                d["isAtMe"] = message.isAtMe
                d["isAtAll"] = message.isAtAll
                arr.append(d)
            }
            block(["atMsgs": arr])
        }).disposed(by: disposeBag)
    }
    // 迁移完成后统一使用OpenPluginChat里的方法
    func onBadgeChange(_ chatId: String?, block: (([String: Any]?) -> Void)?) {
        guard let chatAPI = resolver.resolve(ChatAPI.self), let subCenter = resolver.resolve(SubscriptionCenter.self) else {
            EMAProtocolImpl.logger.warn("onBadgeChange ChatAPI/SubscriptionCenter resolve fail")
            return
        }
        guard let chatId = chatId else {
            EMAProtocolImpl.logger.warn("onBadgeChange chatId is nil")
            return
        }

        subCenter.increaseSubscriber(eventName: "ChatEvent_" + chatId) {
            chatAPI.asyncSubscribeChatEvent(chatIds: [chatId], subscribe: true)
        }
        let pushCenter = resolver.pushCenter
        pushCenter.observable(for: PushChat.self)
            .distinctUntilChanged({ (pushChat1, pushChat2) -> Bool in
                return pushChat1.chat.unreadBadge == pushChat2.chat.unreadBadge
            })
            .subscribe(onNext: { (pushChat) in
                block?(["badge": pushChat.chat.unreadBadge])
            }).disposed(by: disposeBag)
    }
    func offBadgeChange(_ chatId: String?) {
        guard let chatAPI = resolver.resolve(ChatAPI.self), let subCenter = resolver.resolve(SubscriptionCenter.self) else {
            EMAProtocolImpl.logger.warn("offBadgeChange ChatAPI/SubscriptionCenter resolve fail")
            return
        }
        guard let chatId = chatId else {
            EMAProtocolImpl.logger.warn("offBadgeChange chatId is nil")
            return
        }

        subCenter.decreaseSubscriber(eventName: "ChatEvent_" + chatId) {
            chatAPI.asyncSubscribeChatEvent(chatIds: [chatId], subscribe: false)
        }
    }

    func getUserInfoExSuccess(_ success: (([String: Any]?) -> Void)!, fail: (() -> Void)!) {
        if let service = resolver.resolve(OpenPlatformService.self) {
            service.getUserInfoEx(onSuccess: success, onFail: { _ in
                fail()
            })
        } else {
            fail()
        }
    }

    func hostDeviceID() -> String {
        if let service = resolver.resolve(OpenPlatformService.self) {
            return service.getOpenPlatformDeviceID()
        }
        return ""
    }

    func onServerBadgePush(_ appId: String, subAppIds: [String], completion: @escaping ((AppBadgeNode) -> Void)) {
        appBadgeListenerService.observeBadge(appId: appId, subAppIds: subAppIds, callback: completion)
    }

    func offServerBadgePush(_ appId: String, subAppIds: [String]) {
        appBadgeListenerService.removeObserver(appId: appId, subAppIds: subAppIds)
    }

    func updateAppBadge(_ appID: String!, appType: AppBadgeAppType, extra: UpdateBadgeRequestParameters?, completion: ((UpdateAppBadgeNodeResponse?, Error?) -> Void)?) {
        let appBadgeAPI = self.resolver.resolve(AppBadgeAPI.self)
        appBadgeAPI?.updateAppBadge(appID, appType: appType, extra: extra, completion: completion)
    }

    func updateAppBadge(_ appID: String!, appType: BDPType, badgeNum: Int, completion: ((UpdateAppBadgeNodeResponse?, Error?) -> Void)?) {
        let appBadgeAPI = self.resolver.resolve(AppBadgeAPI.self)
        appBadgeAPI?.updateAppBadge(appID, appType: appType, badgeNum: badgeNum, completion: completion)
    }

    func pullAppBadge(_ appID: String!, appType: AppBadgeAppType, extra: PullBadgeRequestParameters?, completion: ((PullAppBadgeNodeResponse?, Error?) -> Void)?) {
        let appBadgeAPI = self.resolver.resolve(AppBadgeAPI.self)
        appBadgeAPI?.pullAppBadge(appID, appType: appType, extra: extra, completion: completion)
    }

    func openSDKPreview(_ fileName: String, fileUrl: URL, fileType: String?, fileID: String?, showMore: Bool, from: UIViewController, thirdPartyAppID: String?, padFullScreen: Bool) {
        let driveSDK = resolver.resolve(DriveSDK.self)

        let cryptoToastAction: (UIViewController) -> Void = { vc in
            UDToast.showTips(with: BundleI18n.LarkOpenPlatform.OpenPlatform_Workplace_SafetyWarning_OpenFailed, on: vc.view)
        }
        if UIDevice.current.userInterfaceIdiom == .pad, padFullScreen { // iPad
            let file = DriveSDKLocalFileV2(fileName: fileName, fileType: fileType, fileURL: fileUrl, fileId: fileID ?? "", dependency: DefaultLocalDependencyImpl(showMore: showMore, moreAction: showMore && FSCrypto.isCryptoInterceptEnable(type: .apiOpenDocument) ? cryptoToastAction : nil))
            let config = DriveSDKNaviBarConfig(titleAlignment: .leading, fullScreenItemEnable: true)
            let body = DriveSDKLocalFileBody(files: [file], index: 0, appID: "1002", thirdPartyAppID: nil, naviBarConfig: config)
            Navigator.shared.present(body: body, naviParams: nil, context: [:], wrap: LocalPreviewFullscreenNavigationViewController.self, from: from, prepare: nil, animated: true, completion: nil)
        } else {
            let moreAction = DriveSDKLocalMoreAction.openWithOtherApp(customAction: FSCrypto.isCryptoInterceptEnable(type: .apiOpenDocument) ? cryptoToastAction : nil)
            let localFile = DriveSDK.LocalFile(
                fileName: fileName,
                fileType: fileType,
                fileURL: fileUrl,
                fileID: fileID,
                moreActions: showMore ? [moreAction] : []
            )
            driveSDK?.open(localFile: localFile, from: from, appID: "1002", thirdPartyAppID: thirdPartyAppID)
        }
    }

    func snsShare(_ controller: UIViewController, appID: String, channel: String, contentType: String, traceId: String, title: String, url: String, desc: String, imageData: Data, successHandler: (() -> Void)?, failedHandler: ((Error?) -> Void)?) {
        let shareHelper = self.resolver.resolve(SNSShareHelper.self)
        shareHelper?.snsShare(controller, appID: appID, channel: channel, contentType: contentType, traceId: traceId, title: title, url: url, desc: desc, imageData: imageData, successHandler: successHandler, failedHandler: failedHandler)
    }

    func registerWorkerInterpreters() -> [AnyHashable : Any]? {
        return ["comment_for_gadget": [OPGadgetCommentJSResource.self]]
    }
}

// 统一的未读数信息, 迁移完成后统一使用OpenPluginChat里的方法
fileprivate extension Chat {
    var unreadBadge: Int32 {
        switch chatMode {
        case .thread, .threadV2:
            return threadBadge
        @unknown default:
            return badge
        }
    }
}

class EMALiveFaceProtocolImpl: NSObject, EMALiveFaceProtocol {
    func checkFaceLiveness(_ params: [AnyHashable: Any]!, shouldShow: (() -> Bool)!, block: (([AnyHashable: Any]?, [String: Any]?) -> Void)!) {
        EMAProtocolImpl.logger.info("start check face liveness")
        let livenessDetector = LarkBytedCert()
        livenessDetector.checkFaceLivenessMessage(params: params, shouldPresent: shouldShow) { (result, errDict) in
            block(result, errDict)
        }
    }
    func checkOfflineFaceVerifyReady(_ callback: @escaping (Error?) -> Void) {
        EMAProtocolImpl.logger.info("checkOfflineFaceVerifyReady")
        let livenessDetector = LarkBytedCert()
        livenessDetector.checkOfflineFaceVerifyReady(callback: callback)
    }
    func prepareOfflineFaceVerify(callback: @escaping (Error?) -> Void) {
        EMAProtocolImpl.logger.info("prepareOfflineFaceVerify")
        let livenessDetector = LarkBytedCert()
        livenessDetector.prepareOfflineFaceVerify(callback: callback)
    }
    func startOfflineFaceVerify(_ params: [AnyHashable : Any], callback: @escaping (Error?) -> Void) {
        EMAProtocolImpl.logger.info("startOfflineFaceVerify")
        let livenessDetector = LarkBytedCert()
        livenessDetector.startOfflineFaceVerify(params, callback: callback)
    }
    
    func startFaceQualityDetect(withBeautyIntensity beautyIntensity: Int32,
                                backCamera: Bool,
                                faceAngleLimit: Int32,
                                from fromViewController: UIViewController?,
                                callback: @escaping (Error?, UIImage?, [AnyHashable : Any]?) -> Void) {
        EMAProtocolImpl.logger.info("startFaceQualityDetect")
        let livenessDetector = LarkBytedCert()
        livenessDetector.startFaceQualityDetect(withBeautyIntensity: beautyIntensity,
                                                backCamera: backCamera,
                                                faceAngleLimit: faceAngleLimit,
                                                from: fromViewController,
                                                callback: callback)
    }
    
}

// 移除OpenPlatform对SKFoundation的依赖, 保留原`merge(other:coverKey:)`方法语义
fileprivate extension Dictionary {
    /// Merges the given dictionary into this dictionary while using newer value for any duplicate keys.
    mutating func merge(other: [Key: Value]?, coverKey: String? = nil) {
        guard let mergedDic = other else {
            return
        }
        for (k, v) in mergedDic {
            /// 直接用新的 value 覆盖
            if let key = k as? String, key == coverKey {
                updateValue(v, forKey: k)
                continue
            }
            if let value = v as? [String: Any], var dic = self[k] as? [String: Any] {
                dic.merge(other: value)
                self[k] = dic as? Value
                continue
            }
            updateValue(v, forKey: k)
        }
    }
}
