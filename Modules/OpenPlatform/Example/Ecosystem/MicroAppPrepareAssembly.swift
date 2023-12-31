//
//  MicroAppPrepareAssembly.swift
//  Ecosystem
//
//  Created by 刘洋 on 2021/4/9.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import Swinject
import LarkMicroApp
import Heimdallr
import LarkAppLinkSDK
import LKCommonsLogging
import EENavigator
import RxSwift
import LarkAccountInterface
import LarkAssembler
import LarkContainer

#if canImport(LarkWorkplace)
import LarkWorkplace
#endif

class MicroAppPrepareAssembly: LarkAssemblyInterface {
    func registLarkAppLink(container: Swinject.Container) {
        container.register(OPNetStatusHelper.self) { _ in
            return OPNetStatusHelper()
        }.inObjectScope(.container)
        MicroAppAssembly.gadgetOB = GadgetObservableManagerProxyImpl(resolver: container)
        container.register(MicroAppService.self) { _ in
            return LarkMicroApp(resolver: container) {
                app, resolver in
                app.addLifeCycleListener(listener: app)
//                EMAEngine.start(resolver: resolver, emaProtocol: EMAProtocolImpl.self)
            }
        }.inObjectScope(.container)
        assemblerAppLink(container: container)
        container.register(SNSShareHelper.self) { (r) -> SNSShareHelper in
            return SNSShareHelperImpl()
        }.inObjectScope(.user)
    }
    private func assemblerAppLink(container: Container) {
        //  注册小程序 AppLink 协议
        LarkAppLinkSDK.registerHandler(path: "/client/mini_program/open", handler: { [weak container] (applink: AppLink) in
//            guard let container = container, EMAEngine.checkEnvReady(resolver: container, emaProtocol: EMAProtocolImpl.self) else {
//                return
//            }
            MiniProgramHandler().handle(appLink: applink, container: container)
        })
    }
}

class SNSShareHelperImpl: SNSShareHelper {
    func snsShare(_ controller: UIViewController, appID: String, channel: String, contentType: String, traceId: String, title: String, url: String, desc: String, imageData: Data, successHandler: (() -> Void)?, failedHandler: ((Error?) -> Void)?) {

    }
}

class GadgetObservableManagerProxyImpl: GadgetObservableManagerProxy {
    private let resolver: Resolver
    private let disposeBag = DisposeBag()
    //  如果需要预防反复监听，可以在这里增加标记位
    private var afterAccountLoadedDone = false
    init(resolver: Resolver) {
        self.resolver = resolver
    }

    func addObservableWhenAssemble() {

    }

    func addObservableAfterAccountLoaded() {
        //  避免反复监听，代码复制过来前有老BUG，监听了太多次
        if afterAccountLoadedDone {
            return
        }
        afterAccountLoadedDone = true
        // 监听账户状态变化
        AccountServiceAdapter
            .shared
            .accountChangedObservable
            .subscribe(onNext: { [weak self] (account) in
                guard let `self` = self else {
                    return
                }
                if account != nil {
//                    EMAEngine.start(resolver: self.resolver, emaProtocol: EMAProtocolImpl.self)
                } else {
//                    EMAEngine.stop()
                }
            })
            .disposed(by: disposeBag)
        let pushCenter = resolver.pushCenter
        // 监听开发者工具push
        pushCenter.observable(for: PushDevToolCommon.self)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { (push) in
            if push.type == .realDeviceDebug { // 真机调试
                if let microapp = self.resolver.resolve(MicroAppService.self) {
                    microapp.realMachineDebug(schema: push.content)
                }
            }
        }).disposed(by: disposeBag)
    }
}

// LarkOpenPlatform 中有相同实现，加上条件编译解决 build 问题
#if !canImport(LarkOpenPlatform)

extension LarkMicroApp: MicroAppLifeCycleListener {
    public func onShow(context: EMALifeCycleContext) {
        let appid = context.uniqueID.appID
        if let auditService = resolver.resolve(OPAppAuditService.self) {
            auditService.auditEnterApp(appid)
        }
        if let info = MicroAppInfoManager.shared.getAppInfo(appID: appid) {
            info.hide = false
        }
    }

    public func onHide(context: EMALifeCycleContext) {
        let appid = context.uniqueID.appID
        if let info = MicroAppInfoManager.shared.getAppInfo(appID: appid) {
            info.hide = true
        }
    }

    public func onCancel(context: EMALifeCycleContext) {
        let appid = context.uniqueID.appID
        MicroAppInfoManager.shared.removeAppInfo(appID: appid)
    }

    public func onDestroy(context: EMALifeCycleContext) {
        let appid = context.uniqueID.appID
        MicroAppInfoManager.shared.removeAppInfo(appID: appid)
    }

}

#endif

class EMAProtocolImpl: NSObject, EMAProtcolAppendProxy {
    required init(resolver: Resolver) {
        self.resolver = resolver
        super.init()
    }
    
    static let logger = Logger.oplog(EMAProtocolImpl.self, category: "Ecosystem")

    private lazy var logDateformatter: DateFormatter = {
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return dateformatter
    }()

    let resolver: Resolver

#if canImport(LarkWorkplace)
    @Provider
    private var appBadgeListenerService: AppBadgeListenerService
#endif
    
}

extension EMAProtocolImpl {
    func trackService(service: String, metrics: [String: NSNumber], category: [AnyHashable: Any]) {
        HMDTTMonitor.defaultManager().hmdTrackService(service, metric: metrics, category: category, extra: [:])
    }
}

extension EMAProtocolImpl: EMAProtocol {
    func regist() { }
    
    func registerWorkerInterpreters() -> [AnyHashable : Any]? {
        return nil
    }
    func enterProfile(byUserID userID: String) {
    }
    func getAvatarURL(withKey key: String) -> String {
        ""
    }
    func shareLink(withLink link: String, title: String?) {
        print("share link with link:\(link) title:\(title)")
    }
    func snsShare(_ controller: UIViewController, appID: String, channel: String, contentType: String, traceId: String, title: String, url: String, desc: String, imageData: Data, successHandler: (() -> Void)?, failedHandler: ((Error?) -> Void)?) {
    }

    func openSDKPreview(_ fileName: String, fileUrl: URL, fileType: String?, fileID: String?, showMore: Bool, from: UIViewController, thirdPartyAppID: String?, padFullScreen: Bool) {
    }

    func checkOfflineFaceVerifyReady(_ callback: @escaping (Error?) -> Void) {
        callback(nil)
    }
    func prepareOfflineFaceVerify(callback: @escaping (Error?) -> Void) {
        callback(nil)
    }
    func startOfflineFaceVerify(_ params: [AnyHashable : Any], callback: @escaping (Error?) -> Void) {
        callback(nil)
    }
    func startFaceQualityDetect(withBeautyIntensity beautyIntensity: Int32,
                                backCamera: Bool,
                                from fromViewController: UIViewController?,
                                callback: @escaping (Error?, UIImage?, [AnyHashable : Any]?) -> Void) {
        callback(nil,nil,nil)
    }
    func chooseSendCard(with uniqueID: OPAppUniqueID?, cardContent: [AnyHashable : Any], withMessage: Bool, params: SendMessagecardChooseChatParams, res: @escaping EMASendMessageCardResultBlock) {
    }

    func onServerBadgePush(_ appId: String, subAppIds: [String], completion: @escaping ((AppBadgeNode) -> Void)) {
#if canImport(LarkWorkplace)
        appBadgeListenerService.observeBadge(appId: appId, subAppIds: subAppIds, callback: completion)
#endif
    }

    func offServerBadgePush(_ appId: String, subAppIds: [String]) {
#if canImport(LarkWorkplace)
        appBadgeListenerService.removeObserver(appId: appId, subAppIds: subAppIds)
#endif
    }

    func pullAppBadge(_ appID: String!, appType: AppBadgeAppType, extra: PullBadgeRequestParameters?, completion: ((PullAppBadgeNodeResponse?, Error?) -> Void)) {
    }

    func updateAppBadge(_ appID: String!, appType: AppBadgeAppType, extra: UpdateBadgeRequestParameters?, completion: ((UpdateAppBadgeNodeResponse?, Error?) -> Void)) {
    }

    func updateAppBadge(_ appID: String!, appType: BDPType, badgeNum: Int, completion: ((UpdateAppBadgeNodeResponse?, Error?) -> Void)) {

    }

    /// 此处是为了避免编译失败
    func filePicker(_ maxSelectedCount: Int, pickerTitle title: String?, pickerComfirm comfirm: String?, block: @escaping (Bool, [[AnyHashable : Any]]?) -> Void) {
    }

    // @lilun.ios 忘了提交这里了吧，build failed
    func getBlockActionSourceDetail(with uniqueID: OPAppUniqueID?, triggerCode: String?, block: EMAGetMessageDetailResultBlock? = nil) {
    }

    func hasWatermark() -> Bool {
        true
    }

    func hostDeviceID() -> String {
        ""
    }

    func getExperimentValue(forKey key: String, withExposure: Bool) -> Any? {
        nil
    }
    func setHMDInjectedInfoWith(_ notification: Notification!, localLibVersionString: String!) {}
    func removeHMDInjectedInfo() {}

    func monitorService(_ service: String, metricsData: [AnyHashable: Any], categoriesData: [AnyHashable : Any], platform: OPMonitorReportPlatform) {
        var metric: [String: NSNumber] = [:]
        metricsData.forEach({ (key,value) in
          if let value = value as? NSNumber, let key = key as? String {
              metric[key] = value
          } else {
            EMAProtocolImpl.logger.error("metrics key:value is not String:Number pair! please check monitor data!, monitor : \(service) categoriesData: \(categoriesData) metricsData: \(metricsData)")
          }
        })
        self.trackService(service: service, metrics: metric, category: categoriesData)
    }

    func sendMessageCard(with: BDPUniqueID?, scene: String, triggerCode: String?, chatIDs: [String]?, cardContent: [AnyHashable : Any], withMessage: Bool, block: EMASendMessageCardResultBlock? = nil) {
        guard let block = block else {
            return
        }
        block(.otherError, "你在使用飞书小程序demo调试此接口，宿主逻辑不予处理", nil, nil, nil)
    }
    func getTriggerContext(withTriggerCode triggerCode: String, block: EMATriggerContextResultBlock? = nil) {
        guard let block = block else {
            return
        }
        block([
            "": triggerCode,
            "success": "你在使用飞书小程序demo调试此接口，宿主逻辑不予处理"
        ])
    }
    func getUserInfoExSuccess(_ success: (([String: Any]?) -> Void)!, fail: (() -> Void)!) {
        fail()
    }
    func docsPickerTitle(_ title: String!, maxNum num: Int, confirm: String!, uniqueID: OPAppUniqueID?, from fromController: UIViewController?, block: (([AnyHashable : Any]?, Bool) -> Void)!) {
        block(["demo": "test"], true)
    }
    func getAtInfo(_ chatId: String!, block: (([AnyHashable: Any]?) -> Void)!) {}
    func getChatInfo(_ chatId: String!) -> [AnyHashable: Any]! {
        ["badge": 0]
    }
    func onBadgeChange(_ chatId: String!, block: (([String: Any]?) -> Void)!) {}
    func offBadgeChange(_ chatId: String!) {}
    func openFeedback(with: BDPUniqueID?, appName: String, appVersion: String) {}
    func appName() -> String! {
        "飞书小程序"
    }
    func checkFaceLiveness(_ params: [AnyHashable: Any]!, shouldShow: (() -> Bool)!, block: (([AnyHashable: Any]?, [String: Any]?) -> Void)!) {}
    func chooseChat(_ params: [String : Any]!, title: String!, selectType type: Int, uniqueID: OPAppUniqueID?, from controller: UIViewController?, block: (([String : Any]?, Bool) -> Void)!) {
        block(["demo": "test"], true)
    }
    func openMineAboutVC(with uniqueID: OPAppUniqueID?, from controller: UIViewController?) {}
    func passwordVerify(for: BDPUniqueID?, block: (([String : Any]?) -> Void)!) {}
    func shareCard(withTitle title: String?, uniqueID: BDPUniqueID?, imageData: Data?, url: String?, appLinkHref: String?, options: EMAShareOptions = [], callback: EMAShareResultBlock? = nil) {
        if let data = imageData,
            let image = UIImage(data: data) {
            /// 用这个可以测测图片长啥样
            print(image)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            callback?(nil, false)
        }
    }
    func openAboutVC(with: BDPUniqueID?, appVersion: String) {}
    func filePicker(_ maxSelectedCount: Int, pickerTitle title: String?, pickerComfirm comfirm: String?, uniqueID: OPAppUniqueID?, from fromController: UIViewController?, block: @escaping (Bool, [[AnyHashable : Any]]?) -> Void) {
        var result: [[AnyHashable: Any]] = [[AnyHashable: Any]]()
        for index in 0 ..< 5 {
            let dic: [String: String] = [kEMASDKFilePickerName: String(format: "name-%d", index), kEMASDKFilePickerPath: String(format: "path-%d", index)]
            result.append(dic)
        }
        block(false, result)
    }
    func trackerEvent(_ event: String?, params: [AnyHashable: Any]?, option: OPMonitorReportPlatform) {
        guard let event = event, let params = params else {
            assert(false, "Missing required parameter")
            return
        }
        if option.contains(.slardar) {
            var metric: [String: NSNumber] = [:]
            var category: [AnyHashable: Any] = [:]
            params.forEach({ (key,value) in
              if let value = value as? NSNumber, let key = key as? String {
                  metric[key] = value
              } else {
                  category[key] = value
              }
            })
            self.trackService(service: event, metrics: metric, category: category)
        }
    }
    func shareWebUrl(_ url: String?, title: String?, content: String?) {}
    func recordLogger(withType type: String?, event: String?, params: [String: String]?) {
        print("[\(String(describing: type))]\(String(describing: event)) \(String(describing: params))")
    }
    func canOpen(_ url: URL!, fromScene: OpenUrlFromScene) -> Bool {
        guard let urlScheme = url.scheme else {
            return false
        }
        if urlScheme.starts(with: "http") && url.host?.contains("applink.") != true {
            return false
        }
        return true
    }
    func open(_ url: URL!, fromScene: OpenUrlFromScene, uniqueID: OPAppUniqueID?, from: UIViewController?)  {
        let window = from?.view.window ?? uniqueID?.window
        let navigation =  OPNavigatorHelper.topmostNav(window: window)
        if let topVC = navigation {
            var context = [String: String]()
            if let uid = uniqueID, uid.appType == .gadget {
                context["from"] = OPScene.micro_app.rawValue
            }
            Navigator.shared.push(url, context: context, from: topVC, animated: true, completion: nil)
        } else {
            EMAProtocolImpl.logger.error("EMAProtocolImpl openAboutVC can not push vc because no fromViewController")
        }
    }
    func openInternalWebView(_ url: URL!, uniqueID: OPAppUniqueID?, from controller: UIViewController?) -> Bool {
        false
    }
    func log(withLevel level: Int, tag: String!, filename: String!, func_name: String!, line: Int, content: String!, logId: String!) {
        var levelStr: String
        switch level {
        case 1:
            levelStr = "DEBUG"
        case 2:
            levelStr = "INFO"
        case 3:
            levelStr = "⚠️WARN"
        case 4:
            levelStr = "❌ERROR"
        case 5:
            levelStr = "❌ERROR"
        default:
            levelStr = String(level)
        }
        print("\(logDateformatter.string(from: Date())) \(levelStr) [\(tag ?? "") \(logId ?? "")][\(filename ?? ""):\(line)] \(func_name ?? "") \(content ?? "")")
    }
    func handleQRCode(_ qrCode: String!, uniqueID: OPAppUniqueID?, from fromController: UIViewController?) -> Bool {
        false
    }
    func checkWatermark() -> Bool {
        true
    }
}

class EMALiveFaceProtocolImpl: NSObject, EMALiveFaceProtocol {

    func checkOfflineFaceVerifyReady(_ callback: @escaping (Error?) -> Void) {
        callback(nil)
    }
    func prepareOfflineFaceVerify(callback: @escaping (Error?) -> Void) {
        callback(nil)
    }
    func startOfflineFaceVerify(_ params: [AnyHashable : Any], callback: @escaping (Error?) -> Void) {
        callback(nil)
    }
    func checkFaceLiveness(_ params: [AnyHashable: Any]!, shouldShow: (() -> Bool)!, block: (([AnyHashable: Any]?, [String: Any]?) -> Void)!) {
    }
    func startFaceQualityDetect(withBeautyIntensity beautyIntensity: Int32,
                                backCamera: Bool,
                                faceAngleLimit: Int32,
                                from fromViewController: UIViewController?,
                                callback: @escaping (Error?, UIImage?, [AnyHashable : Any]?) -> Void) {
        callback(nil,nil,nil)
    }
}
