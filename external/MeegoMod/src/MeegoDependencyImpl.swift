//
//  MeegoDependencyImpl.swift
//  MeegoMod
//
//  Created by shizhengyu on 2022/2/23.
//

import Foundation
import EENavigator
import LarkMeego
import LarkAccountInterface
import LarkLocalizations
import LarkEnv
import LarkContainer
import LarkFlutterContainer
import RustPB
import LarkUIKit
import RxSwift
import Swinject
import LarkFoundation
import LarkFeatureGating
import TangramService
import ByteWebImage
import LarkSetting
import LarkMeegoInterface
import LarkFlutterContainer
import LarkModel
import LarkMeegoLogger
import LarkMeegoStrategy
import LarkMeegoStorage
#if MessengerMod
import LarkMessengerInterface
import LarkSDKInterface
#endif
#if CCMMod
import SpaceInterface
#endif
#if LarkOpenPlatform
import LarkOPInterface
#endif
import LarkQuickLaunchInterface
import CoreMotion
import LarkSensitivityControl

final class MeegoDependencyImpl {
    private let userResolver: UserResolver
    private let passportService: PassportService
    private let passportUserService: PassportUserService
    private let quickLaunchService: QuickLaunchService
    private let featureGatingService: FeatureGatingService
    private let urlPreviewAPI: URLPreviewAPI
    private let openPlatformService: OpenPlatformService
    // 避免 MeegoServiceImpl 和 MeegoDependencyImpl 构造循环依赖
    private var meegoService: LarkMeegoService? {
        return try? userResolver.resolve(assert: LarkMeegoService.self)
    }
    private lazy var userKvStorage: UserSharedKvStorage = {
        return UserSharedKvStorage(associatedUserId: self.passportUserService.user.userID)
    }()
#if MessengerMod
    private let chatAPI: ChatAPI
    private let messageAPI: MessageAPI
    // 避免获取时机过早导致飞书启动额外耗时
    private var userGeneralSettings: UserGeneralSettings? {
        return try? userResolver.resolve(assert: UserGeneralSettings.self)
    }
#endif

    private lazy var canDebug: Bool = {
#if DEBUG || ALPHA
        return true
#else
        let suffix = Utils.appVersion.lf.matchingStrings(regex: "[a-zA-Z]+(\\d+)?").first?.first
        return suffix != nil
#endif
    }()

    init(resolver: UserResolver) throws {
        userResolver = resolver
        passportService = try resolver.resolve(assert: PassportService.self)
        passportUserService = try resolver.resolve(assert: PassportUserService.self)
        featureGatingService = try resolver.resolve(assert: FeatureGatingService.self)
        urlPreviewAPI = try resolver.resolve(assert: URLPreviewAPI.self)
#if MessengerMod
        chatAPI = try resolver.resolve(assert: ChatAPI.self)
        messageAPI = try resolver.resolve(assert: MessageAPI.self)
#endif
        openPlatformService = try userResolver.resolve(assert: OpenPlatformService.self)
        quickLaunchService = try resolver.resolve(assert: QuickLaunchService.self)

    }
}

extension MeegoDependencyImpl: MeegoNativeDependency {
    func getChatAndMessages(by triggerId: String) -> ChatMessageInfo? {
#if LarkOpenPlatform && MessengerMod
        if let messageIds = openPlatformService.getTriggerMessageIds(triggerCode: triggerId),
           let messagesMap = try? messageAPI.getMessagesMap(ids: messageIds) {
            let messages: [Message] = Array(messagesMap.values)
            guard !messages.isEmpty, messages.first!.channel.type == .chat else {
                return nil
            }
            let chatId = messages.first!.channel.id
            // chat 为现在的
            let chat = chatAPI.getLocalChat(by: chatId)
            return ChatMessageInfo(chat: chat, messages: messages)
        }
#endif
        return nil
    }
}

extension MeegoDependencyImpl: MeegoFlutterDependency {
    var isBoe: Bool {
        return canDebug ? EnvManager.env.isStaging : false
    }

    var isPPE: Bool {
#if ALPHA
        if canDebug && (MeegoEnv.get(.usePPE) == "1" || MeegoEnv.get(.usePPE) == "true") {
            return true
        }
        return false
#else
        return false
#endif
    }

    var currentUserId: String {
        return passportUserService.user.userID
    }

    var currentDeviceId: String {
        return passportService.deviceID
    }

    var currentSession: String {
        return passportUserService.user.sessionKey ?? ""
    }

    var currentTenantId: String {
        return passportUserService.userTenant.tenantID
    }

    var currentNetProxy: String {
#if ALPHA
        return canDebug ? MeegoEnv.get(.netProxy) : ""
#else
        return ""
#endif
    }

    var currentTTEnv: String {
#if ALPHA
        return canDebug ? MeegoEnv.get(.ttEnv) : ""
#else
        return ""
#endif
    }

    var currentDomainType: String {
#if ALPHA
        guard canDebug else {
            return ""
        }
        var switchValue = MeegoEnv.get(.domainType)
        guard !switchValue.isEmpty else {
            return ""
        }
        return switchValue == "1" ? "project" : "bytedance"
#else
        return ""
#endif
    }

    var currentRpcPersistDyecpFd: String {
        return ""
    }

    var currentLanguage: String {
        return LanguageManager.currentLanguage.identifier
    }

    func openWebUrl(rootVc: UIViewController, url: URL) {
        var context: [String: Any] = [:]
        if url.urlParameters?["force_webview"]?.toBool() ?? false,
            !featureGatingService.dynamicFeatureGatingValue(with: .init(stringLiteral: "lark.meego.forceWebview.context.inject.disable")) {
            context["notUseUniteRoute"] = true
        }
        if rootVc.navigationController != nil {
            userResolver.navigator.push(url, context: context, from: rootVc)
        } else {
            let style: UIModalPresentationStyle = Display.pad ? .formSheet : .fullScreen
            userResolver.navigator.present(
                url,
                context: context,
                wrap: LkNavigationController.self,
                from: rootVc,
                prepare: { (vc) in
                    vc.modalPresentationStyle = style
                },
                animated: true
            )
        }
    }

    // DomainSetting
    func getDomainSetting(domainKey: String) -> String {
        guard let projectDomainKey = DomainKey(rawValue: domainKey) else {
            MeegoLogger.error("get domain setting:\"\" for domainKey is invalid. DomianKey rawValue:\(domainKey).")
            return ""
        }

        let domainSetting = DomainSettingManager.shared.currentSetting[projectDomainKey]?.first ?? ""

        MeegoLogger.info("get domain setting:\(domainSetting) with domianKey:\(domainKey)")
        return domainSetting
    }

    func getTenantBrand() -> String {
        // 飞书环境返回PassportUserService中获取的TenantBrand: 国内 => "feishu"  海外 => "lark"
        return passportUserService.userTenantBrand.rawValue
    }

    // FeatureGating
    func isFeatureGatingEnabled(key: String) -> Bool {
        guard !key.isEmpty else {
            MeegoLogger.error("get lark FeatureGating failed, key is empty, key: \(key)")
            return false
        }
        let enabled = featureGatingService.dynamicFeatureGatingValue(with: .init(stringLiteral: key))
        MeegoLogger.debug("get lark FeatureGating, key: \(key), enabled: \(enabled)")
        return enabled
    }

    func getSettings(keysString: String, separatorString: String) -> [String: Any] {
        let separator = Array(separatorString).first ?? " "
        let keys: [String] = keysString.split(separator: separator).map { String($0) }
        guard !keys.isEmpty else {
            MeegoLogger.error("get lark settings of keys failed, keys is empty! keysString = \(keysString), separatorString = \(separatorString)")
            return [:]
        }
        let valueMap: [String: Any] = MeegoSettingManager.shared.getLarkSettings(with: keys)
        return valueMap
    }

    /// FG Post接口： 批量定制查询FG数据
    /// - Parameter keysString: 查询的FGkey拼接字符串
    /// - Parameter separatorString: keysString的分割符号
    /// - Parameter projectKey: 空间
    /// - Parameter userKey: 用户key
    /// - Parameter tenantKey: 租户key
    /// - Parameter callBack: 数据回调，接口返回的FG数据json字符串
    func queryLarkFeatureGatingData(
        keysString: String,
        separatorString: String,
        appName: String,
        projectKey: String,
        userKey: String,
        tenantKey: String,
        callBack: @escaping (String) -> Void
    ) {
        meegoService?.queryLarkFeatureGatingData(
            keysString: keysString,
            separatorString: separatorString,
            appName: appName,
            projectKey: projectKey,
            userKey: userKey,
            tenantKey: tenantKey,
            callBack: callBack
        )
    }

    func presentBingdingGroupPage(
        rootVc: UIViewController,
        selectHandler: @escaping (UIViewController, GroupSelectResult) -> Void,
        dismissHandler: @escaping () -> Void
    ) {
#if MessengerMod
        let body = GroupsViewControllerBody(newGroupBtnHidden: true, chooseGroupHandler: { (viewController, group, _) in
            let result = GroupSelectResult(id: group.id, name: group.name)
            selectHandler(viewController, result)
        }, dismissHandler: dismissHandler)

        let style: UIModalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        userResolver.navigator.present(
            body: body,
            wrap: LkNavigationController.self,
            from: rootVc,
            prepare: { (vc) in
                vc.modalPresentationStyle = style
            },
            animated: true
        )
#endif
    }

    func openProfile(larkUserId: String, rootVc: UIViewController) -> Bool {
#if MessengerMod
        let body = PersonCardBody(chatterId: larkUserId, chatId: "", fromWhere: .none, senderID: "", sender: "",
                                  sourceID: "", sourceName: "", source: .vc)
        if rootVc.navigationController != nil {
            userResolver.navigator.push(body: body, from: rootVc)
        } else {
            let style: UIModalPresentationStyle = Display.pad ? .formSheet : .fullScreen
            userResolver.navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: rootVc,
                prepare: { (vc) in
                    vc.modalPresentationStyle = style
                },
                animated: true
            )
        }
#endif
        return true
    }

    func shareTextToChat(with content: String) -> Bool {
#if MessengerMod
        if let root = userResolver.navigator.mainSceneTopMost {
            let body = ForwardTextBody(text: content) { _, _  in
                MeegoLogger.info("share text to chat success!")
            }
            let style: UIModalPresentationStyle = Display.pad ? .formSheet : .pageSheet
            userResolver.navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: root,
                prepare: { (vc) in
                    vc.modalPresentationStyle = style
                },
                animated: true
            )
            return true
        }
        return false
#endif
        return true
    }

    func openLocalFilePreview(fileName: String, fileUrl: String) -> Bool {
#if CCMMod
        if let root = userResolver.navigator.mainSceneTopMost as? UIViewController {
            let dependency = MGDriveSDKLocalPreviewDependency()

            let fileURL = URL(fileURLWithPath: fileUrl)
            let localFile = DriveSDKLocalFile(
                fileName: fileName,
                fileType: nil,
                fileURL: fileURL,
                fileId: nil,
                dependency: dependency
            )

            if let previewVC = (try? userResolver.resolve(assert: DriveSDK.self))?.localPreviewController(
                for: localFile,
                appID: "1004", /// Meego在CCM分配的业务ID
                thirdPartyAppID: nil,
                naviBarConfig: DriveSDKNaviBarConfig(titleAlignment: .center, fullScreenItemEnable: true)
            ) {
                let style: UIModalPresentationStyle = Display.pad ? .formSheet : .fullScreen
                userResolver.navigator.present(
                    previewVC,
                    wrap: LkNavigationController.self,
                    from: root,
                    prepare: { (vc) in
                        vc.modalPresentationStyle = style
                    },
                    animated: true
                )
                return true
            }
        }
        return false
#endif
        return true
    }

    func generateUrlPreview(urlString: String) -> Observable<String?> {
        return self.urlPreviewAPI.generateUrlPreviewEntity(url: urlString)
            .flatMap { (inlineEntity, _) -> Observable<[String: Any]> in
                let entity = inlineEntity
                var valueMap: [String: Any] = ["url": urlString]
                if let title = entity?.title {
                    valueMap["title"] = title
                }
                if let iconKey = entity?.iconKey {
                    valueMap["iconKey"] = iconKey
                    valueMap["iconPath"] = self.getIconPath(iconKey: iconKey)
                }
                return .just(valueMap)
            }
            .take(1)
            .flatMap { previewMap -> Observable<String?> in
                var urlPreviewMap: [String: Any] = ["url": urlString]
                if let title: String = previewMap["title"] as? String {
                    urlPreviewMap["title"] = title
                } else {
                    MeegoLogger.error("get title failed")
                }
                if let path  = previewMap["iconPath"] as? Observable<String?> {
                    return path.take(1).map { res in
                        if let path = res, path != nil {
                            urlPreviewMap["iconPath"] = path
                        }
                        let data = try? JSONSerialization.data(withJSONObject: urlPreviewMap, options: [.prettyPrinted, .sortedKeys, .fragmentsAllowed])
                        if let urlPreviewStr = String(data: data ?? .init(), encoding: .utf8) {
                            return urlPreviewStr
                        } else {
                            MeegoLogger.error("JSONSerialization failed")
                            return nil
                        }
                        return nil
                    }
                } else {
                    MeegoLogger.error("get iconPath failed")
                    let data = try? JSONSerialization.data(withJSONObject: urlPreviewMap, options: [.prettyPrinted, .sortedKeys, .fragmentsAllowed])
                    if let urlPreviewStr = String(data: data ?? .init(), encoding: .utf8) {
                        return .just(urlPreviewStr)
                    } else {
                        MeegoLogger.error("JSONSerialization failed")
                        return .just(nil)
                    }
                }
            }.catchError { error in
                MeegoLogger.error("generate UrlPreviewMap failed, error: \(error.localizedDescription)")
                return .just(nil)
            }
    }

    func getIconPath(iconKey: String) -> Observable<String?> {
        return Observable.create { observable in
            LarkImageService.shared.setImage(with: .default(key: iconKey), options: [.ignoreImage, .needCachePath], completion: { imageRequestResult in
                switch imageRequestResult {
                case .success(let imageResult):
                    guard let imagePath = imageResult.savePath else { return }
                    observable.on(.next(imagePath))
                case .failure(let error):
                    MeegoLogger.error("get image fail, error = \(error.localizedDescription)")
                    observable.on(.error(error))
                }
            })
            return Disposables.create()
        }
    }

    func addToLarkPinArea(vc: LarkFlutterContainer.MeegoViewController) -> Observable<Settings_V1_PinNavigationAppResponse> {
        return quickLaunchService.pinToQuickLaunchWindow(vc: vc)
    }

    func removeFromLarkPinArea(vc: LarkFlutterContainer.MeegoViewController) -> Observable<Settings_V1_UnPinNavigationAppResponse> {
        return quickLaunchService.unPinFromQuickLaunchWindow(vc: vc)
    }

    func isCurrentPagePinned(vc: LarkFlutterContainer.MeegoViewController) -> Observable<Bool> {
        return quickLaunchService.findInQuickLaunchWindow(vc: vc)
    }

    func addLarkVisitRecord(vc: LarkFlutterContainer.MeegoViewController) {
        quickLaunchService.addRecentRecords(vc: vc)
    }

    func canPresentFeedback() -> Bool {
        // BaseFlutterViewController is child of LarkFlutterWrapperController
        if let featureGatingService = try? userResolver.resolve(assert: FeatureGatingService.self),
           featureGatingService.dynamicFeatureGatingValue(with: .init(stringLiteral: "lark.meego.screenshot.feedback.enable")),
           let topVc = userResolver.navigator.mainSceneTopMost?.parent {
            return meegoService?.belongsToMeego(with: topVc) ?? false
        }
        return false
    }

    func startDeviceMotionUpdates(
        with manager: CMMotionManager,
        to queue: OperationQueue,
        handler: @escaping CMDeviceMotionHandler
    ) throws {
        // 敏感api管控 https://bytedance.feishu.cn/wiki/wikcn0fkA8nvpAIjjz4VXE6GC4f
        // BOE和正式环境下该token一致
        let tokenString = "LARK-PSDA-meego_measurement_gravity_monitor"
        let token = Token(tokenString, type: .deviceInfo)

        try DeviceInfoEntry.startDeviceMotionUpdates(
            forToken: token,
            manager: manager,
            to: queue,
            withHandler: handler
        )
    }
}

extension MeegoDependencyImpl: FlutterDockDependency {
    var hasSafeArea: Bool {
        return true
    }

    var currentAppVersion: String {
        return Utils.appVersion
    }

    var currentVersionCode: Int64 {
        return Int64(currentAppVersion.iosVerion2Int())
    }

    func exitHostWebview() {
        if let topMost = userResolver.navigator.mainSceneTopMost {
            userResolver.navigator.pop(from: topMost, animated: true)
        }
    }

    func getJsonStrFromRustKv(dbType: LarkFlutterContainer.DbType, key: String) -> String {
        switch dbType {
        case .global:
            return (try? GlobalSharedKvStorage.shared.getString(with: key)) ?? ""
        case .user:
            return (try? userKvStorage.getString(with: key)) ?? ""
        }
    }

    func setJsonStrToRustKvAsync(dbType: LarkFlutterContainer.DbType, key: String, value: String, expiredMillis: Int64) {
        switch dbType {
        case .global:
            GlobalSharedKvStorage.shared.setStringAsync(key: key, with: value, expiredMillis: expiredMillis)
        case .user:
            userKvStorage.setStringAsync(key: key, with: value, expiredMillis: expiredMillis)
        }
    }
}

extension MeegoDependencyImpl: MeegoStrategyServiceDependency {
    var currentDeviceClassify: MeegoDeviceClassify {
#if MessengerMod
        guard let userGeneralSettings = userGeneralSettings else {
            return .unclassify
        }
        switch userGeneralSettings.deviceClassifyConfig.mobileClassify {
        case .highMobile: return .high
        case .midMobile: return .middle
        case .lowMobile: return .low
        case .unClassifyMobile: return .unclassify
        }
#else
        return .unclassify
#endif
    }
}

#if CCMMod
// MARK: DrivesSDK 本地预览
class MGDriveSDKLocalPreviewDependency: DriveSDKLocalPreviewDependency {
    let moreDependency: DriveSDKLocalMoreDependency
    let actionDependency: DriveSDKActionDependency

    init() {
        moreDependency = DriveSDKLocalMoreDependencyImpl()
        actionDependency = DriveSDKActionDependencyImpl()
    }
}

final class DriveSDKLocalMoreDependencyImpl: DriveSDKLocalMoreDependency {
    var moreMenuVisable: Observable<Bool> { .just(true) }
    var moreMenuEnable: Observable<Bool> { .just(true) }
    var actions: [DriveSDKLocalMoreAction] { [.openWithOtherApp(customAction: nil)] }
}

final class DriveSDKActionDependencyImpl: DriveSDKActionDependency {
    var stopPreviewSignal: Observable<Reason> { .never() }
    var closePreviewSignal: Observable<Void> { .never() }
    init() {}
}
#endif

private extension String {
    func toBool() -> Bool? {
        if ["true", "1", "yes"].contains(self.lowercased()) {
            return true
        }
        if ["false", "0", "no"].contains(self.lowercased()) {
            return false
        }
        return nil
    }

    func iosVerion2Int() -> Int {
        var parts = self.components(separatedBy: ".")
        if parts.count == 3 {
            parts.append("0")
        }
        if parts.count != 4 {
            return -1
        }
        var iversion = 0
        var ratio = 1
        for (index, value) in parts.enumerated().reversed() {
            let partInt = Int(value) ?? 0
            iversion += ratio * partInt
            ratio = ratio * 100
        }
        return iversion
    }
}

private extension URL {
    var urlParameters: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
        let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }
}
