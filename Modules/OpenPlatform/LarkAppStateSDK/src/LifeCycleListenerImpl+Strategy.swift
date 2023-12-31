//
//  LifeCycleListenerImpl+Strategy.swift
//  LarkAppStateSDK
//
//  Created by  bytedance on 2020/9/27.
//

import Foundation
import ECOProbe
import RustPB
import RxSwift
import EEMicroAppSDK
import OPSDK
import OPFoundation
import LarkFeatureGating
import LarkSetting
import Swinject
import LarkContainer
import LarkOpenWorkplace

private struct ShowDialogConfig {
    public let response: RustPB.Openplatform_V1_GetMiniAppControlInfoResponse
    public let callback: MicroAppLifeCycleBlockCallback?
    public let context: EMALifeCycleContext
    
    public init(response: RustPB.Openplatform_V1_GetMiniAppControlInfoResponse, callback: MicroAppLifeCycleBlockCallback? = nil, context: EMALifeCycleContext) {
        self.response = response
        self.callback = callback
        self.context = context
    }
}

class LifeCycleListenerImplV2: NSObject, MicroAppLifeCycleListener {
    private var dialogConfigMap: [OPAppUniqueID: ShowDialogConfig] = [:]
    private var firstAppearMap: [OPAppUniqueID: Bool] = [:]
    private var blockLoadingMap: [OPAppUniqueID: Bool] = [:]
    public var resolver: UserResolver?
    
    /// 小程序从后台切回
    func onShow(context: EMALifeCycleContext) {
        AppStateSDK.logger.info("AppStateSDK: gedget onShow,appID:\(context.uniqueID.appID)")
        /// 跳过应用机制检查
        if skipStateCheck(context: context) {
            AppStateSDK.logger.info("AppStateSDK: gedget skip state check")
            return
        }

        if let container = OPApplicationService.current.getContainer(uniuqeID: context.uniqueID),
           container.containerContext.availability != .ready {
            // 新容器 ready 之前，只走 blockLoading 的拦截，不走这里
            AppStateSDK.logger.info("AppStateSDK：gedget\(context.uniqueID)onShow，not ready")
            return
        }

        let appid = context.uniqueID.appID
        /// 更新最近使用时间
        AppStateSDK.shared.updateLastUsedTimeWith(appID: appid)
        /// 从 rust 取出数据
        var request = RustPB.Openplatform_V1_GetMiniAppControlInfoRequest()
        request.appID = appid
        request.strategy = .localOnly
        var disposeBagA = DisposeBag()
        AppStateSDK.logger.info("AppStateSDK: gedget(\(appid)) onShow,start to request stateInfo with strategy local")
        let ob: Observable<RustPB.Openplatform_V1_GetMiniAppControlInfoResponse>? = AppStateSDK.shared.client?.sendAsyncRequest(request)
        ob?.observeOn(MainScheduler.instance).subscribe(onNext: { (localResponse) in
            disposeBagA = DisposeBag()
            OPMonitor(name: AppStateDefines.monitorName, code: EPMClientOpenPlatformAppStrategyCode.gadget_state_success)
                .setResultTypeSuccess()
                .addCategoryValue("appID", appid)
                .addCategoryValue("strategy", "local")
                .flush()
            request.strategy = .netOnly // 无论是否可用，都会从网络请求一次数据
            /// 如果本地有缓存且缓存可用，则认为应用可用。
            if localResponse.appInfo.hasAppID && localResponse.appInfo.status == .usable {
                AppStateSDK.logger.info("AppStateSDK:gedget get App info from local usable and request stateInfo with strategy net")
                if context.uniqueID.instanceID != "tab_gadget" {
                    self.reportRecentlyMiniApp(appID: context.uniqueID.appID, path: context.startPage ?? "")
                }
                let disposeBagB = DisposeBag()
                AppStateSDK.shared.client?.sendAsyncRequest(request).subscribe(onNext:{ _ in
                    OPMonitor(name: AppStateDefines.monitorName, code: EPMClientOpenPlatformAppStrategyCode.gadget_state_success)
                        .setResultTypeSuccess()
                        .addCategoryValue("appID", appid)
                        .addCategoryValue("strategy", "network")
                        .flush()
                }, onError: { (error) in
                    OPMonitor(name: AppStateDefines.monitorName, code: EPMClientOpenPlatformAppStrategyCode.gadget_state_fail)
                        .setResultTypeFail()
                        .addCategoryValue("appID", appid)
                        .addCategoryValue("strategy", "network")
                        .setError(error)
                        .flush()
                }).disposed(by: disposeBagB)
                return
            } else {    // 本地缓存不可用，则从网络请求数据并刷新本地缓存
                AppStateSDK.logger.info("AppStateSDK:gedget localCache for App is unAvailable, request from network")
                var disposeBagB = DisposeBag()
                let startTime = CFAbsoluteTimeGetCurrent()
                let netDataOb: Observable<RustPB.Openplatform_V1_GetMiniAppControlInfoResponse>? = AppStateSDK.shared.client?.sendAsyncRequest(request)
                netDataOb?.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (netResponse) in
                    OPMonitor(name: AppStateDefines.monitorName, code: EPMClientOpenPlatformAppStrategyCode.gadget_state_success)
                        .setResultTypeSuccess()
                        .addCategoryValue("appID", appid)
                        .addCategoryValue("strategy", "network")
                        .flush()
                    let intervalTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000  // 单位ms
                    AppStateSDK.logger.info("AppStateSDK:gedget info request from network success, time consume: \(intervalTime) ms")
                    disposeBagB = DisposeBag()
                    let VC = OPNavigatorHelper.topMostAppController(window: context.uniqueID.window)
                    self?.handleAccessForGadget(context: context, response: netResponse, webVC: VC)
                }, onError: {[weak self] (error) in
                    OPMonitor(name: AppStateDefines.monitorName, code: EPMClientOpenPlatformAppStrategyCode.gadget_state_fail)
                        .setResultTypeFail()
                        .addCategoryValue("appID", appid)
                        .addCategoryValue("strategy", "network")
                        .setError(error)
                        .flush()
                    //本地有缓存，但是没有权限，就拦截
                    if localResponse.appInfo.hasAppID && localResponse.appInfo.status != .usable {
                        let VC = OPNavigatorHelper.topMostAppController(window: context.uniqueID.window)
                        self?.handleAccessForGadget(context: context, response: localResponse, webVC: VC)
                    }
                }).disposed(by: disposeBagB)
            }
        }, onError: { (error) in
            OPMonitor(name: AppStateDefines.monitorName, code: EPMClientOpenPlatformAppStrategyCode.gadget_state_fail)
                .setResultTypeFail()
                .addCategoryValue("appID", appid)
                .addCategoryValue("strategy", "local")
                .setError(error)
                .flush()
        }).disposed(by: disposeBagA)
    }
    
    func onFirstAppear(context: EMALifeCycleContext) {
        guard self.blockLoadingMap[context.uniqueID] == true else {
            AppStateSDK.logger.info("AppStateSDK: set firstAppear true:\(context.uniqueID.appID)")
            self.firstAppearMap[context.uniqueID] = true
            return
        }
        AppStateSDK.logger.info("AppStateSDK: set blockLoading false:\(context.uniqueID.appID)")
        self.blockLoadingMap[context.uniqueID] = false
        guard let dialogConfig = self.dialogConfigMap[context.uniqueID] else {
            return
        }
        let showDialogBlock:((RustPB.Openplatform_V1_GetMiniAppControlInfoResponse, MicroAppLifeCycleBlockCallback?, EMALifeCycleContext) -> Void) = { [weak self] (response, callback, context) in
            guard let self = self else { return }
            let webVC = OPNavigatorHelper.topMostAppController(window: context.uniqueID.window)
            self.handleAccessForGadget(context: context, response: response, callback: callback, webVC: webVC)
        }
        showDialogBlock(dialogConfig.response, dialogConfig.callback, dialogConfig.context)
        self.dialogConfigMap.removeValue(forKey: context.uniqueID)
    }
    
    func onDestroy(context: EMALifeCycleContext) {
        self.blockLoadingMap.removeValue(forKey: context.uniqueID)
        self.firstAppearMap.removeValue(forKey: context.uniqueID)
        self.dialogConfigMap.removeValue(forKey: context.uniqueID)
        AppStateSDK.logger.info("AppStateSDK: onDestroy:\(context.uniqueID.appID)")
    }

    /// 小程序onMeta前提供外部block的机会
    func blockLoading(context: EMALifeCycleContext, callback: MicroAppLifeCycleBlockCallback) {
        AppStateSDK.logger.info("AppStateSDK: gedget blockLoading,appID:\(context.uniqueID.appID)")
        /// 跳过应用机制检查
        if skipStateCheck(context: context) {
            AppStateSDK.logger.info("AppStateSDK: gedget skip state check")
            return callback.continueLoading()
        }
        let appid = context.uniqueID.appID
        /// 更新最近使用时间
        AppStateSDK.shared.updateLastUsedTimeWith(appID: appid)
        /// 从 rust 取出数据
        var request = Openplatform_V1_GetMiniAppControlInfoRequest()
        request.appID = appid
        request.strategy = .localOnly
        var disposeBagA = DisposeBag()
        AppStateSDK.logger.info("AppStateSDK: gedget(\(appid)) blockLoading,start to request stateInfo  with strategy local")
        let ob: Observable<RustPB.Openplatform_V1_GetMiniAppControlInfoResponse>? = AppStateSDK.shared.client?.sendAsyncRequest(request)
        ob?.observeOn(MainScheduler.instance).subscribe(onNext: { (localResponse) in
            disposeBagA = DisposeBag()
            OPMonitor(name: AppStateDefines.monitorName, code: EPMClientOpenPlatformAppStrategyCode.gadget_state_success)
                .setResultTypeSuccess()
                .addCategoryValue("appID", appid)
                .addCategoryValue("strategy", "local")
                .flush()
            request.strategy = .netOnly // 无论是否可用，都会从网络请求一次数据
            /// 如果本地有缓存且缓存可用，则认为应用可用。
            if localResponse.appInfo.hasAppID && localResponse.appInfo.status == .usable {
                AppStateSDK.logger.info("AppStateSDK:gedget get App info from local usable and request stateInfo with strategy net")
                self.blockLoadingMap[context.uniqueID] = true
                var disposeBagB = DisposeBag()
                if context.uniqueID.instanceID != "tab_gadget" {
                    self.reportRecentlyMiniApp(appID: context.uniqueID.appID, path: context.startPage ?? "")
                }
                AppStateSDK.shared.client?.sendAsyncRequest(request).subscribe(onNext:{ _ in
                    OPMonitor(name: AppStateDefines.monitorName, code: EPMClientOpenPlatformAppStrategyCode.gadget_state_success)
                        .setResultTypeSuccess()
                        .addCategoryValue("appID", appid)
                        .addCategoryValue("strategy", "network")
                        .flush()
                }, onError: { (error) in
                    OPMonitor(name: AppStateDefines.monitorName, code: EPMClientOpenPlatformAppStrategyCode.gadget_state_fail)
                        .setResultTypeFail()
                        .addCategoryValue("appID", appid)
                        .addCategoryValue("strategy", "network")
                        .setError(error)
                        .flush()
                }).disposed(by: disposeBagB)
                return callback.continueLoading()
            } else {    // 本地缓存不可用，则从网络请求数据并刷新本地缓存
                AppStateSDK.logger.info("AppStateSDK:gedget localCache for App is unAvailable, request from network")
                var disposeBagB = DisposeBag()
                let startTime = CFAbsoluteTimeGetCurrent()
                let netDataOb: Observable<RustPB.Openplatform_V1_GetMiniAppControlInfoResponse>? = AppStateSDK.shared.client?.sendAsyncRequest(request)
                netDataOb?.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (netResponse) in
                    OPMonitor(name: AppStateDefines.monitorName, code: EPMClientOpenPlatformAppStrategyCode.gadget_state_success)
                        .setResultTypeSuccess()
                        .addCategoryValue("appID", appid)
                        .addCategoryValue("strategy", "network")
                        .flush()
                    let intervalTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000  // 单位ms
                    AppStateSDK.logger.info("AppStateSDK:gedget info request from network success, time consume: \(intervalTime) ms")
                    self?.blockLoadingMap[context.uniqueID] = true
                    disposeBagB = DisposeBag()
                    if FeatureGatingManager.realTimeManager.featureGatingValue(with: "openpaltform.app.state.dialog.opt") {
                        if (self?.firstAppearMap[context.uniqueID] == true) {
                            let VC = OPNavigatorHelper.topMostAppController(window: context.uniqueID.window)
                            self?.handleAccessForGadget(context: context, response: netResponse, callback: callback, webVC: VC)
                            AppStateSDK.logger.info("AppStateSDK: set firstAppear false:\(context.uniqueID.appID)")
                            self?.firstAppearMap[context.uniqueID] = false
                        } else {
                            AppStateSDK.logger.info("AppStateSDK: set dialogConfig:\(context.uniqueID.appID)")
                            self?.dialogConfigMap[context.uniqueID] = ShowDialogConfig(response: netResponse, callback: callback, context: context)
                        }
                    } else {
                        let VC = OPNavigatorHelper.topMostAppController(window: context.uniqueID.window)
                        self?.handleAccessForGadget(context: context, response: netResponse, callback: callback, webVC: VC)
                    }
                }, onError: { [weak self] (error) in
                    OPMonitor(name: AppStateDefines.monitorName, code: EPMClientOpenPlatformAppStrategyCode.gadget_state_fail)
                        .setResultTypeFail()
                        .addCategoryValue("appID", appid)
                        .addCategoryValue("strategy", "network")
                        .setError(error)
                        .flush()
                    self?.blockLoadingMap[context.uniqueID] = true
                    if localResponse.appInfo.hasAppID && localResponse.appInfo.status != .usable {
                        if FeatureGatingManager.realTimeManager.featureGatingValue(with: "openpaltform.app.state.dialog.opt") {
                            if (self?.firstAppearMap[context.uniqueID] == true) {
                                let VC = OPNavigatorHelper.topMostAppController(window: context.uniqueID.window)
                                self?.handleAccessForGadget(context: context, response: localResponse, callback: callback, webVC: VC)
                                AppStateSDK.logger.info("AppStateSDK: set firstAppear false:\(context.uniqueID.appID)")
                                self?.firstAppearMap[context.uniqueID] = false
                            } else {
                                AppStateSDK.logger.info("AppStateSDK: set dialogConfig:\(context.uniqueID.appID)")
                                self?.dialogConfigMap[context.uniqueID] = ShowDialogConfig(response: localResponse, callback: callback, context: context)
                            }
                        } else {
                            let VC = OPNavigatorHelper.topMostAppController(window: context.uniqueID.window)
                            self?.handleAccessForGadget(context: context, response: localResponse, callback: callback, webVC: VC)
                        }
                    } else {
                        self?.handleAccessError(callback: callback)
                    }

                }).disposed(by: disposeBagB)
            }
        }, onError: { (error) in
            OPMonitor(name: AppStateDefines.monitorName, code: EPMClientOpenPlatformAppStrategyCode.gadget_state_fail)
                .setResultTypeFail()
                .addCategoryValue("appID", appid)
                .addCategoryValue("strategy", "local")
                .setError(error)
                .flush()
            self.handleAccessError(callback: callback)
        }).disposed(by: disposeBagA)
    }
}

/// 抽离小程序生命周期之外的逻辑
extension LifeCycleListenerImplV2 {
    /// 处理小程序的可用性引导
    func handleAccessForGadget(context: EMALifeCycleContext,
                               response: RustPB.Openplatform_V1_GetMiniAppControlInfoResponse,
                               callback: MicroAppLifeCycleBlockCallback? = nil,
                               webVC: UIViewController? = nil) {
        /// 返回数据为空，上报错误
        if !response.appInfo.hasAppID {
            handleAccessError(callback: callback)
        } else if response.appInfo.hasStatus && response.appInfo.status == .usable {
            AppStateSDK.logger.info("AppStateSDK:gedget get App info from network usable")
            if context.uniqueID.instanceID != "tab_gadget" {
                self.reportRecentlyMiniApp(appID: context.uniqueID.appID, path: context.startPage ?? "")
            }
            callback?.continueLoading()
            return
        } else {    // 应用不可用，弹窗提示
            if response.hasTips {
                AppStateSDK.logger.info("AppStateSDK:gedget get App info from network unuseable,show alert")
                if let resolver = resolver {
                    GuideTipHandler(resolver: resolver).presentAlert(appId: response.appInfo.appID,
                                                   appName: response.appInfo.localName,
                                                   tip: response.tips,
                                                   webVC: webVC,
                                                   callback: callback,
                                                   appType: .microApp)
                } else {
                    AppStateSDK.logger.error("LifeCycleListenerImplV2: resolver")
                    handleAccessError(callback: callback)
                }
            } else {    // 不可用应用没有弹窗数据，异常上报
                AppStateSDK.logger.error("AppStateSDK:gedget get App info from network unuseable and no tips")
                handleAccessError(callback: callback)
            }
        }
    }
    /// 处理小程序可用性引导获取失败
    func handleAccessError(callback: MicroAppLifeCycleBlockCallback? = nil) {
        // 产品策略：应用可用性获取失败，认为无此次拦截，不阻塞小程序的加载（原则：让用户能多用一次）
        AppStateSDK.logger.info("AppStateSDK:gedget state error bug use")
        callback?.continueLoading()
    }
    /// 判断是否跳过应用机制
    func skipStateCheck(context: EMALifeCycleContext) -> Bool {
        return context.uniqueID.versionType == .preview
    }

    private func reportRecentlyMiniApp(appID: String, path: String) {
        let workplaceOpenAPI = try? self.resolver?.resolve(assert: WorkplaceOpenAPI.self)
        guard let workplaceOpenAPI = workplaceOpenAPI else {
            AppStateSDK.logger.error("AppStateSDK:workplaceOpenAPI is nil")
            return
        }
        workplaceOpenAPI.reportRecentlyMiniApp(appId: appID, path: path)
    }
}
