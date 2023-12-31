//
//  LarkMeegoServiceImpl.swift
//  LarkMeego
//
//  Created by shizhengyu on 2021/8/26.
//

import Foundation
import LarkModel
import LarkFlutterContainer
import ServerPB
import RustPB
import LKCommonsTracker
import LarkContainer
import LarkEmotion
import ThreadSafeDataStructure
import RxSwift
import LarkAccountInterface
import LarkMeegoInterface
import LarkMeegoNetClient
import Homeric
import LarkExtensions
import LarkAppConfig
import EENavigator
import LarkUIKit
import LarkStorage
import LarkNavigator
import meego_rust_ios
import LarkMeegoLogger
import LarkMeegoStrategy
import LarkMeegoStorage
import LarkMeegoWorkItemBiz
import LarkMeegoViewBiz
import LarkRustClient
import LarkSetting

/// Bridge 通信约定字段
/// 详细参见 https://bytedance.feishu.cn/wiki/wikcnIEEkyKO4eeZLT9BDK6Pofh#
private enum Agreement {
    enum ChatKey {
        static let chatId = "chat_id"
        static let name = "name"
        static let avatarKey = "avatar_key"
        static let isGroup = "is_group"
    }
    enum MessageKey {
        static let messages = "messages"
        static let messageId = "message_id"
    }
    enum Other {
        static let from = "from"
        static let wrappContext = "work_item_context"
    }
    enum Route {
        static let createWorkItem = "/create_work_item"
        static let openUrl = "/openByURL"
        static let createWorkItemPrefix = "create_work_item"
        static let openUrlPrefix = "openByURL"
        static let bizRouteUrl = "biz_url"
        static let fromWebBrowserCtxFlag = "LarkWebBrowser"
    }
    enum Settings {
        static let routeHosts = "hosts"
        static let routePatterns = "path_pattern_list"
        static let homePatterns = "home_pattern_list"
        static let workbenchPatterns = "workbench_pattern_list"
        static let routeQueryRequired = "query_required"
    }
    enum Trace {
        static let traceId = "trace_id"
        static let openTime = "open_time"
    }
}

private enum MeegoBizErrorCode {
    static let seatNotEnough = 1000051013
}

/// Meego Native 侧逻辑处理类
/// 负责入口鉴权、包装上下文、处理路由跳转等逻辑
// swiftlint:disable type_body_length
class LarkMeegoServiceImpl: LarkMeegoService {
    private static let supportedMessageTypes: [Basic_V1_Message.TypeEnum] = [
        .text,  // 纯文本消息
        .image, // 图片消息（单+多）
        .post,  // 富文本消息
        .audio, // 音频消息
        .media, // 视频消息
        .file   // 附件消息
    ]
    private static let ramMemorylimit: UInt64 = 1 * 1024 * 1024 * 1024   // 1GB

    private let userResolver: UserResolver
    private let dependency: MeegoNativeDependency
    private let flutterContainerService: FlutterContainerService
    private let passportService: PassportService
    private let passportUserService: PassportUserService
    private let netClient: MeegoNetClient
    private let strategyService: MeegoStrategyService
    private let settingService: SettingService
    private let flowController = FlowController(interval: 2.0)
    private let urlMatcher = MeegoURLMatcher()

    private var lastCheckResponse: MeegoEnableRequest.ResponseType?
    private lazy var destControllerInitializer: (UIViewController, FlutterDisplayType) -> Void = {
        return { [weak self] (dest, displayType) in
            switch displayType {
            case .present:
                dest.modalPresentationStyle = .fullScreen
            case .push:
                if let nav = self?.userResolver.navigator.mainSceneTopMost?.nearestNavigation,
                   !(nav.delegate is MeegoApplicationNavigationDelegate),
                   self?.navigationDelegate.animatorMatcher.hasMatch(dest) ?? false {
                    let context = ModifiedNavigationContext(navigationController: nav, lastNavigationDelegate: nav.delegate)
                    self?.navigationDelegate.update(with: context)
                    nav.delegate = self?.navigationDelegate
                }
            }
        }
    }()
    // swiftlint:disable weak_delegate
    private lazy var navigationDelegate: MeegoApplicationNavigationDelegate = {
        return MeegoApplicationNavigationDelegate(userResolver: userResolver)
    }()
    // swiftlint:enable weak_delegate

    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        dependency = try userResolver.resolve(assert: MeegoNativeDependency.self)
        flutterContainerService = try userResolver.resolve(assert: FlutterContainerService.self)
        passportService = try userResolver.resolve(assert: PassportService.self)
        passportUserService = try userResolver.resolve(assert: PassportUserService.self)
        netClient = try userResolver.resolve(assert: MeegoNetClient.self)
        strategyService = try userResolver.resolve(assert: MeegoStrategyService.self)
        settingService = try userResolver.resolve(assert: SettingService.self)
        setup()
    }

    deinit {
        navigationDelegate.rollback()
    }

    func setup() {
        // 初始化 meego db
        if let dbPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last?.path {
            let start = CACurrentMediaTime()
            rustConfigMeegoDb(path: dbPath)
            let gap = Int(round((CACurrentMediaTime() - start) * 1000 * 1000))
            MeegoLogger.debug("[Database] meego rust db path = \(dbPath), config db cost \(gap) us")
        }

        // 注册预请求执行器
        let userKvStorage = UserSharedKvStorage(associatedUserId: passportUserService.user.userID)
        strategyService.register(with: [
            WorkItemPreRequestExecutor(userResolver: userResolver, userKvStorage: userKvStorage),
            SingleViewPreRequestExecutor(userResolver: userResolver, userKvStorage: userKvStorage)
        ])
    }

    func hasAnyMeegoURL(_ urls: [String]) -> Bool {
        return urlMatcher.hasAnyMatch(urls: urls.compactMap { URL(string: $0) })
    }

    func matchedMeegoUrls(_ urls: [String]) -> [URL] {
        return urlMatcher.matchedUrls(with: urls.compactMap { URL(string: $0) })
    }

    func enableMeegoURLHook() -> Bool {
        return canTouch(for: .url, needDiagnosis: true)
    }

    func isMeegoHomeURL(_ url: String) -> Bool {
        guard let url = URL(string: url) else {
            return false
        }
        return urlMatcher.hasMatchHome(url: url)
    }

    func canDisplayCreateWorkItemEntrance(chat: Chat, messages: [Message]?, from: EntranceSource) -> Bool {
        return canTouch(for: .createWorkItem(chat: chat, messages: messages, from: from))
    }

    func canDisplayCreateWorkItemEntrance(chat: Chat, from: EntranceSource) -> Bool {
        return canDisplayCreateWorkItemEntrance(chat: chat, messages: nil, from: from)
    }

    func createWorkItem(with chat: LarkModel.Chat, messages: [LarkModel.Message]?, sourceVc: UIViewController, from: LarkMeegoInterface.EntranceSource) {
        createWorkItem(with: chat, messages: messages, sourceVc: sourceVc, from: from)
    }

    /// 点击入口，处理创建工作项流程
    /// 目前支持：
    /// 1. 长按单条消息的悬浮菜单入口(chat + message)
    /// 2. 点击键盘附件上的创单入口(chat)
    /// 3. 选择多条消息的底部菜单入口(chat + message)
    /// 4. 快捷应用 - meego 应用入口(null)
    func createWorkItem4Inner(
        with chat: Chat?,
        messages: [Message]?,
        sourceVc: UIViewController,
        from: EntranceSource,
        lifecycleEventHandler: LarkFlutterViewLifecycleEventProtocol? = nil
    ) {
        Tracker.post(TeaEvent(Homeric.LARK_TRY_CREATE_MEEGO, params: ["channel": from.rawValue]))

        // 过滤出可以作为工作项描述的消息
        let usefulMessages = messages?.filter { message in
            return Self.supportedMessageTypes.contains(message.type)
        }

        var nativeContext: [String: Any] = [Agreement.Other.from: from.rawValue]
        var nativeContextBase64 = ""

        // 采集 chat 信息
        var chatInfo: [String: Any] = [:]
        if let chat = chat {
            chatInfo = [
                Agreement.ChatKey.chatId: chat.id,
                Agreement.ChatKey.name: chat.name,
                Agreement.ChatKey.avatarKey: chat.avatarKey.isEmpty ? chat.avatar.key : chat.avatarKey,
                Agreement.ChatKey.isGroup: chat.type != .p2P
            ]
        }
        nativeContext.merge(chatInfo, uniquingKeysWith: { (first, _) in first })

        guard let convertMessages = usefulMessages else {
            do {
                // 没有携带 message 信息，直接使用通用信息打开创建工作项页
                let data = try JSONSerialization.data(withJSONObject: nativeContext, options: .prettyPrinted)
                let jsonStr = String(data: data, encoding: .utf8)
                nativeContextBase64 = jsonStr?.data(using: .utf8)?.base64EncodedString() ?? ""

                let openTime = "\(Int(round(Date().timeIntervalSince1970 * 1000)))"
                let deviceId = passportService.deviceID
                let traceId = "\(deviceId)_\(openTime)".md5()
                let resourceParameters = [
                    Agreement.Other.wrappContext: nativeContextBase64,
                    Agreement.Trace.openTime: openTime,
                    Agreement.Trace.traceId: traceId
                ]
                MeegoLogger.info("open create work item page, from = \(from.rawValue), traceId = \(traceId), openTime: \(openTime)")
                flutterContainerService.openResource(
                    entryPoint: EntryPointRegistry.meegoEntryPoint,
                    flutterRouteUrl: Agreement.Route.createWorkItem,
                    larkRouteIdentifier: "meego_\(Agreement.Route.createWorkItemPrefix)_\(traceId)",
                    parameters: resourceParameters,
                    displayType: .push,
                    destControllerInitializer: { [weak self] dest in
                        self?.destControllerInitializer(dest, .push)
                    },
                    fromScenes: from.rawValue,
                    from: sourceVc,
                    lifecycleEventHandler: lifecycleEventHandler,
                    completion: nil
                )
            } catch {
                MeegoLogger.error("json serial failed, error = \(error.localizedDescription)")
            }
            return
        }

        // 采集 messages 信息
        var messageInfos: [[String: Any]] = []
        convertMessages.forEach({ message in
            var messageInfo: [String: Any] = [:]
            switch message.type {
            case .text:
                messageInfo = getTextContext(message: message)
            case .image:
                messageInfo = getImageContext(message: message)
            case .post:
                messageInfo = getPostContext(message: message)
            case .audio:
                messageInfo = getAudioContext(message: message)
            case .media:
                messageInfo = getMediaContext(message: message)
            case .file:
                messageInfo = getFileContext(message: message)
            default: break
            }
            if !messageInfo.keys.isEmpty {
                messageInfo[Agreement.MessageKey.messageId] = message.id
                messageInfos.append(messageInfo)
            }
        })

        nativeContext[Agreement.MessageKey.messages] = messageInfos

        do {
            let data = try JSONSerialization.data(withJSONObject: nativeContext, options: .prettyPrinted)
            let jsonStr = String(data: data, encoding: .utf8)
            nativeContextBase64 = jsonStr?.data(using: .utf8)?.base64EncodedString() ?? ""
        } catch {
            MeegoLogger.error("json serial failed, error = \(error.localizedDescription)")
        }

        let openTime = "\(Int(round(Date().timeIntervalSince1970 * 1000)))"
        let deviceId = passportService.deviceID ?? ""
        let traceId = "\(deviceId)_\(openTime)".md5()
        let resourceParameters = [
            Agreement.Other.wrappContext: nativeContextBase64,
            Agreement.Trace.openTime: openTime,
            Agreement.Trace.traceId: traceId
        ]
        MeegoLogger.info("open create work item page, from = \(from.rawValue), traceId = \(traceId), openTime: \(openTime)")
        flutterContainerService.openResource(
            entryPoint: EntryPointRegistry.meegoEntryPoint,
            flutterRouteUrl: Agreement.Route.createWorkItem,
            larkRouteIdentifier: "meego_\(Agreement.Route.createWorkItemPrefix)_\(traceId)",
            parameters: resourceParameters,
            displayType: .push,
            destControllerInitializer: { [weak self] dest in
                self?.destControllerInitializer(dest, .push)
            },
            fromScenes: from.rawValue,
            from: sourceVc,
            lifecycleEventHandler: lifecycleEventHandler,
            completion: nil
        )
    }

    func handleMeegoCardExposed(message: Message) {
        func handle() {
            DispatchQueue.global(qos: .default).async {
                guard let content = message.content as? LarkModel.CardContent,
                      let opCardJsonStr = try? content.richText.jsonString()
                else { return }

                // 消息卡片中的 action button 也可能是 meego link，需要单独取出再 merge 去重
                let actionUrls = content.actions.values.map { action in
                    return action.openURL.iosURL
                }.compactMap { URL(string: $0) }
                let actionMatchedUrls = self.urlMatcher.matchedUrls(with: actionUrls)
                let richTextMatchedUrls = self.urlMatcher.matchedUrls(by: opCardJsonStr)
                let mergedUrls = (actionMatchedUrls + richTextMatchedUrls).lf_unique { $0.absoluteString }
                if mergedUrls.isEmpty {
                    return
                }

                self.handleMeegoReachPointExposed(
                    message: message,
                    chat: nil,
                    urls: mergedUrls,
                    larkScene: .messageCard
                )
            }
        }

        let id = "\(message.channel.id)_\(message.id)"
        flowController.execute(id: id, executor: handle)
    }

    func handleMeegoReachPointExposed(
        message: Message,
        chat: Chat?,
        urls: [URL],
        larkScene: LarkScene
    ) {
        guard canTouch(for: .url) else {
            return
        }

        // 用户 url 曝光数据预处理
        urls.forEach { url in
            strategyService.expose(with: url, type: .entrance(larkScene))
        }

        // 预启动引擎专属 FG
        guard FeatureGating.get(by: FeatureGating.flutterEnginePreload4MeegoEnable, userResolver: userResolver) else {
            return
        }

        MeegoLogger.info("handle meego rp exposed, meego urls = \(urls), messageId = \(message.id), chatId = \(chat?.id ?? "nil")")
        flutterContainerService.preloadEngine(with: EntryPointRegistry.meegoEntryPoint, config: EnginePreloadConfig())
    }

    func fetchMeegoEnableIfNeeded() {
        // 当前身份为小 b 用户，由于 meego 网关插件会直接报租户不合法，所以需要端上前置过滤
        guard passportUserService.user.type.isStandard else {
            MeegoLogger.info("do not fetch meego enable because current user is not standard B")
            return
        }
        MeegoLogger.info("start fetch meego enable")
        let request = MeegoEnableRequest(larkUserId: passportUserService.user.userID, tenantId: passportUserService.userTenant.tenantID)
        netClient.sendRequest(request) { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .success(let response):
                self.lastCheckResponse = response
                guard let enable = response.data?.tenantVisible else {
                    return
                }
                MeegoLogger.info("meego payCheck success, enableValue = \(enable). bizCode = \(response.code), bizMsg = \(response.msg)")
                Diagnosis.hit(apiCallResult: .success)
                let store = KVStores.Meego.user(id: self.passportUserService.user.userID)
                store[KVKeys.Meego.enablePay] = enable
            case .failure(let error):
                MeegoLogger.info("meego payCheck failed, error = \(error.localizedDescription)")
                Diagnosis.hit(apiCallResult: .failed(
                    errorCode: Int64(error.httpStatusCode),
                    errorMsg: error.errorMsg ?? error.localizedDescription
                ))
            }
        }
    }

    func registerMeegoFlutterRoutes() {
        // boe: https://cloud-boe.bytedance.net/appSettings-v2/detail/config/159156/detail/status
        // online: https://cloud.bytedance.net/appSettings-v2/detail/config/160107/detail/basic
        do {
            let routeConfig = try settingService.setting(with: .make(userKeyLiteral: "meego_link_config"))
            MeegoLogger.info("fetch meego route configs = \n\(routeConfig)")
            registerURLHooks(with: routeConfig)
        } catch {
            MeegoLogger.error("fetch meego route configs failed, error = \(error.localizedDescription)")
        }
    }

    func registerURLHooks(with configs: [String: Any]) {
        if let hosts = configs[Agreement.Settings.routeHosts] as? [String],
           let patterns = configs[Agreement.Settings.routePatterns] as? [String],
           !hosts.isEmpty, !patterns.isEmpty {
            let queryRequireds = configs[Agreement.Settings.routeQueryRequired] as? [[String: Any]] ?? []
            let homePatterns = configs[Agreement.Settings.homePatterns] as? [String] ?? []
            let workbenchPatterns = configs[Agreement.Settings.workbenchPatterns] as? [String] ?? []
            // 更新 urlMatcher
            self.urlMatcher.update(
                with: hosts,
                patterns: patterns,
                homePatterns: homePatterns + workbenchPatterns,
                queryRequireds: queryRequireds
            )

            Navigator.shared.registerRoute(match: { [weak self] url in
                guard let `self` = self, self.urlMatcher.hasMatch(url: url) else {
                    return false
                }
                return self.canTouch(for: .url, needDiagnosis: true)
            }, priority: .default) { [weak self] req in
                let currentUserId = try? req.getUserResolver().userID
                return self?.passportUserService.user.userID == currentUserId
            } _: { [weak self] (req, resp) in
                guard let `self` = self else { return }

                var fromLarkScenes = ""
                var fromScenesDescriptions: [String] = []
                if let from = req.context["from"] as? String {
                    fromScenesDescriptions.append("from=\(from)")
                }
                if let scene = req.context["scene"] as? String {
                    fromScenesDescriptions.append("scene=\(scene)")
                }
                if let location = req.context["location"] as? String {
                    fromScenesDescriptions.append("location=\(location)")
                }
                if let chatType = req.context["chat_type"] as? String {
                    fromScenesDescriptions.append("chat_type=\(chatType)")
                }
                if let chatType = req.context["url_click_type"] as? String {
                    fromScenesDescriptions.append("url_click_type=\(chatType)")
                }
                if let urlFromQuery = req.url.queryParameters["from"] as? String {
                    fromScenesDescriptions.append("url_from_query=\(urlFromQuery)")
                }
                if fromScenesDescriptions.isEmpty {
                    fromLarkScenes = "unknown"
                } else {
                    fromLarkScenes = fromScenesDescriptions.joined(separator: "&")
                }
                let openTime = "\(Int(round((CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970) * 1000)))"
                let userId = self.passportUserService.user.userID
                let deviceId = self.passportService.deviceID
                let traceId = "\(deviceId)_\(openTime)".md5()
                var bizRouteUrl = req.url.absoluteString

                let parameters: [String: String] = [
                    Agreement.Route.bizRouteUrl: bizRouteUrl,
                    Agreement.Trace.openTime: openTime,
                    Agreement.Trace.traceId: traceId
                ]

                var flutterViewLifecycleEventHandler: LarkFlutterViewLifecycleEventProtocol?

                // - MARK: Flutter 可用性，兼容性拦截
                var abilityConfig = try? SettingManager.shared.setting(with: MeegoAbilityConfig.self)
                as MeegoAbilityConfig?
                if let abilityConfig = abilityConfig, let compatibility = abilityConfig.checkCompatibility() {
                    switch compatibility {
                    case .forceUpgrade:
                        MeegoLogger.info("compatibility check result is force upgrade, end route!")
                        Diagnosis.hit(entry: .openUrl, entryResult: .failed(reason: .forceUpgrade))
                        resp.end(resource: compatibility.routeEndResource(with: req))
                        return
                    case .remindUpgrade:
                        MeegoLogger.info("compatibility check result is remind upgrade, build event handler")
                        flutterViewLifecycleEventHandler = compatibility.buildFlutterViewEventHandler(config: abilityConfig,
                                                                                                      route: bizRouteUrl,
                                                                                                      from: fromLarkScenes)
                    }
                }

                MeegoLogger.info("open meego biz url = \(req.url.absoluteString), fromLarkScenes = \(fromLarkScenes), traceId = \(traceId), openTime = \(openTime), userId = \(userId)")
                // 返回一个空路由资源终结前一个跳转请求
                resp.end(resource: EmptyResource())

                guard let rootVc = self.userResolver.navigator.mainSceneTopMost else { return }

                // 用户场景曝光统计
                self.strategyService.expose(with: req.url, type: .scene(fromLarkScenes))

                // 判断是否是快捷应用进入的创单页，需要特化处理
                /*
                 https://meego.feishu.cn/create_work_item?openAppId=cli_a1e73512e978900d&required_launch_ability=message_action&bdp_launch_query={
                   "__trigger_id__" : "c-a344aa14d86d482a74dedde62186c2d8"
                 }&meego_scene=create_work_item&meego_from=shortcut
                 */
                let routeQueryParameters = req.url.queryParameters
                let bdpLaunchQuery = routeQueryParameters[HookURLQuery.ExternalQueryKey.bdpLaunchQuery.rawValue]?.removingPercentEncoding
                let meegoScene = routeQueryParameters[HookURLQuery.ExternalQueryKey.meegoScene.rawValue]
                let meegoFrom = routeQueryParameters[HookURLQuery.ExternalQueryKey.meegoFrom.rawValue]
                if let bdpLaunchQuery = bdpLaunchQuery, let meegoFrom = meegoFrom, let meegoScene = meegoScene {
                    routerQueue.async {
                        if let data = bdpLaunchQuery.data(using: String.Encoding.utf8),
                           let bdpLaunchQueryDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject],
                           let triggerId = bdpLaunchQueryDict[HookURLQuery.ExternalQueryKey.triggerId.rawValue] as? String {
                            let chatMessageInfo = self.dependency.getChatAndMessages(by: triggerId)
                            self.createWorkItem4Inner(
                                with: chatMessageInfo?.chat,
                                messages: chatMessageInfo?.messages,
                                sourceVc: rootVc,
                                from: .shortcutMenu,
                                lifecycleEventHandler: flutterViewLifecycleEventHandler
                            )
                        } else {
                            self.createWorkItem4Inner(
                                with: nil,
                                messages: nil,
                                sourceVc: rootVc,
                                from: .shortcutMenu,
                                lifecycleEventHandler: flutterViewLifecycleEventHandler
                            )
                        }
                    }
                } else {
                    var displayType: FlutterDisplayType = .push
                    let navController = rootVc.navigationController
                    if navController == nil ||
                        (navController?.modalPresentationStyle == .formSheet || navController?.modalPresentationStyle == .popover) ||
                        (rootVc.modalPresentationStyle == .formSheet || rootVc.modalPresentationStyle == .popover) {
                        // https://meego.feishu.cn/leopard/issue/detail/5046588?parentUrl=%2Fworkbench&tab=todo
                        // 目前产品和视觉希望 meego 的所有落地页都是全屏展示的，但是目前只要满足以下几点就会打破预期：
                        // 1. 目前 lark 里的 url 点击后会在内部统一触发 innerPush（强制）
                        // 2. 前一个 vc 如果是非全屏态，则 push 出来的也会是非全屏态
                        // 所以这里需要判断前一个 vc 是否是全屏态
                        // 如果是全屏态，则走 push
                        // 如果是非全屏态（目前只限定 popover、fromSheet 两种）， 则走 fullscreen present
                        displayType = .present
                    }

                    self.flutterContainerService.openResource(
                        entryPoint: EntryPointRegistry.meegoEntryPoint,
                        flutterRouteUrl: Agreement.Route.openUrl,
                        larkRouteIdentifier: "meego_\(Agreement.Route.openUrlPrefix)_\(req.url.absoluteString.md5())",
                        parameters: parameters,
                        displayType: displayType,
                        destControllerInitializer: { self.destControllerInitializer($0, displayType) },
                        fromScenes: fromLarkScenes,
                        from: rootVc,
                        lifecycleEventHandler: flutterViewLifecycleEventHandler,
                        completion: { [weak self] dest in
                            // 判断如果为工作台，则销毁此前所有打开的 meego 页面
                            guard let `self` = self, self.urlMatcher.hasMatchHome(url: req.url) else {
                                return
                            }
                            if case .push = displayType, let navigationController = dest.navigationController {
                                let meegoStackBottom = navigationController.viewControllers.firstIndex { vc in
                                    if let vc = vc as? LarkFlutterResource, vc.larkRouteIdentifier.lowercased().contains("meego") {
                                        return true
                                    }
                                    return false
                                } ?? -1
                                // 如果没找到前序 meego 页面，则不做任何处理
                                if meegoStackBottom < 0 {
                                    return
                                }
                                let newRouteStack = navigationController.viewControllers[0..<meegoStackBottom] + [dest]
                                navigationController.setViewControllers(Array(newRouteStack), animated: false)
                            }
                        }
                    )
                }
            }
        }
    }

    // 检查租户是否开通了 Meego 功能
    func canTouch(for entry: EntryType, needDiagnosis: Bool = false) -> Bool {
        guard isNotMemoryProtectedDevice() else {
            if needDiagnosis {
                Diagnosis.hit(entry: entry.name, entryResult: .failed(reason: .memoryProtected))
            }
            return false
        }
        let payCheckRes = isPaidUser()
        guard let payCheckRes = payCheckRes, payCheckRes else {
            if needDiagnosis {
                if let remoteResp = lastCheckResponse {
                    Diagnosis.hit(entry: entry.name, entryResult: .failed(reason: .payRemoteUnavailable(
                        bizErrorCode: Int64(remoteResp.code),
                        bizMsg: remoteResp.msg
                    )))
                } else if payCheckRes == false {
                    Diagnosis.hit(entry: entry.name, entryResult: .failed(reason: .payCacheUnavailable))
                } else if payCheckRes == nil {
                    Diagnosis.hit(entry: entry.name, entryResult: .failed(reason: .payDataIsEmpty))
                }
            }
            return false
        }
        switch entry {
        case .createWorkItem(let chat, let messages, let from):
            // 目前仅支持单聊和群聊，不支持话题群
            guard chat.type == .p2P || chat.type == .group else {
                return false
            }
            // 目前不支持密聊
            if chat.isCrypto {
                return false
            }
            // FG
            guard FeatureGating.get(by: FeatureGating.createWorkItemEnable, userResolver: userResolver) else {
                if needDiagnosis {
                    Diagnosis.hit(
                        entry: entry.name,
                        entryResult: .failed(reason: .fgClosed(fgName: FeatureGating.createWorkItemEnable))
                    )
                }
                return false
            }
            // 如果是多选消息场景，还需要判断专属 FG 是否打开
            if case .mutiSelect = from, !FeatureGating.get(by: FeatureGating.multiSelectEntranceEnable, userResolver: userResolver) {
                if needDiagnosis {
                    Diagnosis.hit(
                        entry: entry.name,
                        entryResult: .failed(reason: .fgClosed(fgName: FeatureGating.multiSelectEntranceEnable))
                    )
                }
                return false
            }
            // 如果有消息数组，则判断是否有存在任意一条支持的消息格式，如果都不支持则不能展示
            if let messages = messages, !messages.isEmpty {
                guard messages.first { return Self.supportedMessageTypes.contains($0.type) } != nil else {
                    return false
                }
            }
        case .url:
            guard FeatureGating.get(by: FeatureGating.urlEntranceEnable, userResolver: userResolver) else {
                if needDiagnosis {
                    Diagnosis.hit(
                        entry: entry.name,
                        entryResult: .failed(reason: .fgClosed(fgName: FeatureGating.urlEntranceEnable))
                    )
                }
                return false
            }
        }
        if needDiagnosis {
            Diagnosis.hit(entry: entry.name, entryResult: .success)
        }
        return true
    }

    func queryLarkFeatureGatingData(keysString: String, separatorString: String, appName: String, projectKey: String, userKey: String, tenantKey: String, callBack: @escaping (String) -> Void) {
        let separator = Array(separatorString).first as? Character ?? " "
        let keys: [String] = keysString.split(separator: separator).map { String($0) }
        guard !keys.isEmpty else {
            MeegoLogger.error("get projet FeatureGating of keys failed, keys is empty! keysString = \(keysString), separatorString = \(separatorString)")
            callBack("")
            return
        }
        // 更新本地注册的FGkeys
        MeegoFeatureGatingManager.shared.updateLocalRegistedFGKeys(with: keys)
        let fgParams = FetchFeatureGatingRequestParams(keys: keys, appName: appName, meegoProjectKey: projectKey, meegoUserKey: userKey, meegoTenantKey: tenantKey)
        MeegoFeatureGatingManager.shared.fetchFeatureGating(with: fgParams, completionHandler: { result in
            switch result {
            case .success(let response):
                let fgInfos: [MGFeatureGatingKeyInfo] = response.data?.fgJsonInfos ?? []
                let data = (try? JSONEncoder().encode(fgInfos)) ?? Data()
                let jsonString = String(data: data, encoding: .utf8)!
                callBack(jsonString)
                let enabledFeatures: [String] = response.data?.enabledFeatures ?? []
                MeegoLogger.info("query FeatureGating by keys, fgInfos: \(fgInfos), enabledFeatures: \(enabledFeatures), keysString: \(keysString)")
            case .failure(let error):
                callBack("")
                MeegoLogger.error("query FeatureGating by keys, failed)")
            }
        })
    }

    func belongsToMeego(with vc: UIViewController) -> Bool {
        if let vc = vc as? LarkFlutterResource, vc.larkRouteIdentifier.lowercased().contains("meego") {
            return true
        }
        return false
    }

    // 是否不是内存受限保护的设备
    @inline(__always)
    func isNotMemoryProtectedDevice() -> Bool {
        // 由于担心在一些低端设备（RAM 1GB及以下）打开 Flutter 页面出现 OOM 情况
        // 暂时将 RAM 内存小于等于 1GB 的设备进行屏蔽
        if ProcessInfo.processInfo.physicalMemory <= Self.ramMemorylimit {
            return false
        }
        return true
    }

    @inline(__always)
    func isPaidUser() -> Bool? {
        let store = KVStores.Meego.user(id: passportUserService.user.userID)
        return store[KVKeys.Meego.enablePay]
    }
}
