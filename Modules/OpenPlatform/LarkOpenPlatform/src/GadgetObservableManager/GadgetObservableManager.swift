//
//  GadgetObservableManager.swift
//  LarkMicroApp
//
//  Created by 武嘉晟 on 2020/2/25.
//

import EEMicroAppSDK
import Foundation
import LarkAccountInterface
import LarkAppLinkSDK
import LarkSDKInterface
import RxSwift
import Swinject
import OPFoundation
import LarkMicroApp
import LKCommonsLogging
import OPSDK
import LarkSetting
import LarkFeatureGating
import LarkContainer

/// gadget OB 管理对象，请在期望监听的时间段为这个对象做保活处理
class GadgetObservableManager: GadgetObservableManagerProxy {
    private let resolver: UserResolver
    private let disposeBag = DisposeBag()
    //  如果需要预防反复监听，可以在这里增加标记位
    private var assembleDone = false
    private var afterAccountLoadedDone = false
    private static let logger = Logger.log(GadgetObservableManager.self, category: "GadgetObservableManager")
    private weak var netStatusHelper: OPNetStatusHelper? {
        resolver.resolve(OPNetStatusHelper.self)
    }
    init(resolver: UserResolver) {
        self.resolver = resolver
        GadgetObservableManager.logger.info("GadgetObservableManager init")
    }
    func addObservableWhenAssemble() {
        //  避免反复监听，代码复制过来前有老BUG，监听了太多次
        if assembleDone {
            return
        }
        GadgetObservableManager.logger.info("GadgetObservableManager start assemble")
        assembleDone = true
        let pushCenter = resolver.pushCenter
        //  监听网络状态更新
        pushCenter
            .observable(for: PushDynamicNetStatus.self)
            .subscribe(onNext: { [weak self](push) in
                GadgetObservableManager.logger.info("GadgetObservableManager received network change \(push.dynamicNetStatus.rawValue)")
                self?.netStatusHelper?.updateNetStatus(netStatus: push.dynamicNetStatus)
            })
            .disposed(by: disposeBag)
    }
    func addObservableAfterAccountLoaded() {
        //  避免反复监听，代码复制过来前有老BUG，监听了太多次
        if afterAccountLoadedDone {
            return
        }
        GadgetObservableManager.logger.info("GadgetObservableManager start observe account change ")
        afterAccountLoadedDone = true
        let pushCenter = resolver.pushCenter
        //  监听 App Feed 消息
        pushCenter.observable(for: PushAppFeeds.self)
            .subscribe(onNext: { [weak self] (push) in
                guard let `self` = self else {
                    return
                }
                GadgetObservableManager.logger.info("GadgetObservableManager received app feed push")
                push.appFeeds.values.forEach { (appFeed) in
                    guard let url = appFeed.url else {
                        return
                    }
                    let sslocal = SSLocalModel(url: url)
                    guard let appID = sslocal.app_id as String? else {
                        GadgetObservableManager.logger.info("GadgetObservableManager app id is nil")
                        return
                    }
                    //1002    从会话列表的列表项打开    移动端&PC端
                    //https://open.feishu.cn/document/uYjL24iN/uQzMzUjL0MzM14CNzMTN
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "kGadgetPreRunNotificationName"),
                                                    object: nil,
                                                    userInfo: ["appid": appID,"scenes":[1002]])
                    guard let info = MicroAppInfoManager.shared.getAppInfo(appID: appID) else {
                            return
                    }
                    info.feedAppID = appFeed.appID
                    info.feedSeqID = appFeed.lastNotificationSeqID
                    GadgetObservableManager.logger.info("GadgetObservableManager received app feed appID:\(info.feedAppID) feedSeqID:\(info.feedSeqID) appHide:\(info.hide)")
                    if !info.hide,
                        let feedAppID = info.feedAppID,
                        let feedSeqID = info.feedSeqID {
                        // 来自于 feed 的唤起需要消除 Badge
                        GadgetObservableManager.logger.info("GadgetObservableManager app feed appID:\(feedAppID) feedSeqID:\(feedSeqID) clear badge")
                        self.resolver.resolve(FeedAPI.self)?.setAppNotificationRead(appID: feedAppID, seqID: feedSeqID).subscribe(onNext: { () in
                            info.feedAppID = nil
                            info.feedSeqID = nil
                            GadgetObservableManager.logger.info("GadgetObservableManager app feed clear complete")
                        }).disposed(by: self.disposeBag)
                    }
                }
            }).disposed(by: disposeBag)
        pushCenter.observable(for: PushMiniprogramPreview.self)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (push) in
                GadgetObservableManager.logger.info("GadgetObservableManager received PushMiniprogramPreview push")
                guard let timeStampStr = push.timeStamp,
                    let timeStamp = Double(timeStampStr),
                    timeStamp > Date().timeIntervalSince1970 else {
                        return
                }
                guard let url = URL(string: push.url),
                    UIApplication.shared.applicationState == .active else {
                        return
                }
                // 实时预览的场景值从URL中获取
                var scene: Int = FromScene.undefined.sceneCode()
                if let sceneStr = url.queryParameters["scene"], let sceneCode = Int(sceneStr) {
                    scene = sceneCode
                }
                EERoute.shared().openURL(byPushViewController: url, scene: scene, window: OPWindowHelper.fincMainSceneWindow())
            }).disposed(by: disposeBag)
        // 监听开发者工具push
        pushCenter.observable(for: PushDevToolCommon.self)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { (push) in
            GadgetObservableManager.logger.info("GadgetObservableManager received PushDevTool push")
            if push.type == .realDeviceDebug { // 真机调试
                if let microapp = self.resolver.resolve(MicroAppService.self) {
                    microapp.realMachineDebug(schema: push.content)
                }
            }
        }).disposed(by: disposeBag)

        //  监听小程序有更新
        pushCenter
            .observable(for: PushMiniprogramNeedUpdate.self)
            .subscribe(onNext: { (push) in
                GadgetObservableManager.logger.info("GadgetObservableManager received mini programe update push appid \(push.client_id)")
                EMAAppUpdateManager
                    .sharedInstance()
                    .onReceiveUpdatePush(
                        forAppID: push.client_id,
                        latency: push.latency,
                        extraInfo: push.extra
                    )
                if FeatureGatingManager.shared.featureGatingValue(with: "openplatform.webapp.push.load.applink.meta") {
                    H5App.handlePushCommandIfNeeded(appId: push.client_id,latency: push.latency, extra: push.extra, resolver: self.resolver)
                }
            })
            .disposed(by: disposeBag)

        // 监听产品化止血更新推送
        pushCenter.observable(for: PushOpenAppContainerCommon.self)
            .subscribe(onNext: { (push) in
                GadgetObservableManager.logger.info("GadgetObservableManager received PushOpenAppContainerCommand push appid \(push.cliID) type: \(push.command)")
                switch push.command {
                case .leastVersionUpdate:
                    EMAAppUpdateManager.sharedInstance().onReceiveSilenceUpdateAppID(push.cliID, extra: push.extra)
                @unknown default:
                    GadgetObservableManager.logger.info("GadgetObservableManager received PushOpenAppContainerCommand by default case: \(push.command)")
                }
            }).disposed(by: disposeBag)
    }
}
