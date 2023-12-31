//
//  TrackService.swift
//  LarkTracker
//
//  Created by 李晨 on 2019/12/4.
//

// swiftlint:disable missing_docs

import UIKit
import Foundation
import RangersAppLog
import LarkReleaseConfig
import LKCommonsLogging
import LarkDebugExtensionPoint
import LarkAppLog
import UniverseDesignTheme
import LarkCache
import LarkSetting
import LarkStorage

public final class TrackService {

    static let logger = Logger.log(TrackService.self, category: "LarkApp.TrackService")

    static var appID: String = ReleaseConfig.appIdForAligned

    static var appFullVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

    static var channel: String = ReleaseConfig.channelName

    private let isStaging: Bool
    private let isRelease: Bool

    var deviceID = ""
    private var tenantID = ""
    private var isGuest = true
    private var userID = ""
    var installID = ""
    private var platform = ""
    private var subPlatform = ""
    private var geo = ""
    private var brand = ""
    private var traceUserInterfaceIdiom: Bool
    private var hasExternal = false

    /// 监听 theme 变化 view
    private var observeThemeView: ObserveThemeView?

    public init(traceUserInterfaceIdiom: Bool, isStaging: Bool, isRelease: Bool) {
        // 未处理preRelease情况，先注释掉
        // assert(isRelease != isStaging, "staging  release")
        self.traceUserInterfaceIdiom = traceUserInterfaceIdiom
        self.isStaging = isStaging
        self.isRelease = isRelease

        /// 初始化RangersAppLog
        let appLog = LarkAppLog.shared
        PushSDKTrackerProvider.shared().tracker = PushSDKTrackerProxy(self)
        self.addObserveThemeViewIfNeeded()

        #if ALPHA
        // debug才开启ET埋点，该API直接传false会有问题，要么不传，要么传true
        if ETTrackerDebugItem.isOn {
            BDAutoTrack.setETEnable(ETTrackerDebugItem.isOn, withAppID: Self.appID)
        }
        #endif

        /// staging 环境关闭 filter
        if isStaging {
            appLog.tracker.setFilterEnable(false)
        }

        OKServiceCenter.sharedInstance().bindClass(TTReachablityCellularServcie.self, for: OKCellularService.self)

        // 注册埋点清理任务
        CleanTaskRegistry.register(cleanTask: TrackCleanTask())
    }

    deinit {
        /// 删除监听 view
        self.observeThemeView?.removeFromSuperview()

        /// 删除通知
        NotificationCenter.default.removeObserver(self)
    }

    /// 添加 view 监听系统皮肤变化
    func addObserveThemeViewIfNeeded() {
        /// 添加主线程异步延时 3 秒 添加监听
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            let observeThemeView = ObserveThemeView({ [weak self] in
                if #available(iOS 13.0, *) {
                    TrackService.logger.info("system theme change to \(UITraitCollection.current.userInterfaceStyle.rawValue)")
                }
                self?.resetTerminalInfo()
            })
            self.observeThemeView = observeThemeView
            guard let window = UIApplication.shared.windows.first else {
                return
            }
            window.addSubview(observeThemeView)
            TrackService.logger.info("add observe view in window \(window)")
        }

        /// 添加监听配置变化配置
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(handleThemeConfigChange),
                                                   name: UDThemeManager.didChangeNotification,
                                                   object: nil)

            updateHasExternal()

            /// 进入前台回调
            _ = NotificationCenter.default.addObserver(
                forName: UIScene.didActivateNotification,
                object: nil,
                queue: nil) { [weak self] _ in
                        self?.updateHasExternal()
                }

            /// 销毁清理 window rootVC
            _ = NotificationCenter.default.addObserver(
                forName: UIScene.didDisconnectNotification,
                object: nil,
                queue: nil) { [weak self] _ in
                    self?.updateHasExternal()
                }
        }
    }

    private func updateHasExternal() {
        if #available(iOS 13.0, *) {
            UIApplication.shared.connectedScenes.forEach {
                if #available(iOS 16.0, *), $0.session.role == .windowExternalDisplayNonInteractive {
                    hasExternal = true
                }
            }
        }
    }

    @objc
    func handleThemeConfigChange() {
        if #available(iOS 13.0, *) {
            TrackService.logger.info("handle theme change to \(UITraitCollection.current.userInterfaceStyle.rawValue)")
        }
        self.resetTerminalInfo()
    }

    // MARK: Common event
    public func track(event: String, userID: String? = nil, category: String? = nil, params: [String: Any] = [:]) {
        sendEvent(event, userID: userID, category: category, params: params)
    }

    private func sendEvent(
        _ event: String,
        userID: String?,
        isEndEvent: Bool = false,
        category: String?,
        params: [String: Any]
    ) {
        var theParams = params
        //机型评分
        let deviceClassify = try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "get_device_classify")) //Global
        let deviceScore = deviceClassify?["cur_device_score"] as? Double
        if let deviceScore = deviceScore {
            theParams["deviceScore"] = deviceScore
        } else if let deviceScore = KVPublic.Common.deviceScore.value() { //如果没有获取到评分(基本是由于在settings初始化之前获取),尝试从磁盘获取作为兜底
            theParams["deviceScore"] = deviceScore
        }

        if let category = category {
            theParams["category"] = category
        }

        /// https://bytedance.feishu.cn/docs/doccnGlVo2IIBaiysVSS636Wc3f
        /// _env_type 为 Lark 自定义 tag
        /// _staging_flag, _debug_flag 为数据平台默认 tag
        if self.isStaging {
            theParams["_staging_flag"] = 1
        }

        // 将下面两句存#else中移动出来，以避免因CI未覆盖release导致的可能编译失败。
        if !isRelease {
            theParams["_env_type"] = "debug"
            theParams["_debug_flag"] = 1
        }
        #if DEBUG
        theParams["_env_type"] = "debug"
        theParams["_debug_flag"] = 1

        let isValidJson = JSONSerialization.isValidJSONObject(theParams)
        if !isValidJson {
            assertionFailure("埋点 \(event) 参数 params 内部含有非法数据 请保留现场 截图发给 @lichen thanks")
            TrackService.logger.error("invalid params object", additionalData: ["key": event])
            return
        }
        #endif

        LarkAppLog.shared.serialQueue.async {
            // FIXME: 因为未来会换成隔离实例，短期这里也都是兼容模式，所以就不做检查和拦截了，仅仅是保证外部能传userID
            // if let userID = userID, self.userID != userID {
            //     let block = !userScopeCompatibleMode
            //     let exception = UserExceptionInfo(scene: "Tea", key: event, message: "",
            //                                       callerState: .ready, calleeState: block ? .ready : .compatible)
            //     UserExceptionInfo.log(exception)
            //     if block { return }
            // }

            LarkAppLog.shared.tracker.eventV3(event, params: theParams)
        }
    }

    // MARK: config
    public func setupTeaEndpointsURL(_ teaEndpointsURL: [String]) {
        LarkAppLog.shared.setupTeaEndpointsURL(teaEndpointsURL)
    }

    public func updateTeaEndpointsURL(_ teaEndpointsURL: [String]) {
        LarkAppLog.shared.updateTeaEndpointsURL(teaEndpointsURL)
    }

    // TODO: 将来尽量改造成隔离的，现在先暂时保留为切换单例
    public func config(chatterID: String, tenantID: String, isGuest: Bool, deviceID: String,
                       installID: String, platform: String = "", subPlatform: String = "",
                       geo: String, brand: String) {
        // config变化，先将之前缓存的埋点上报
        LarkAppLog.shared.flush()

        self.deviceID = deviceID
        self.installID = installID
        LarkAppLog.shared.serialQueue.async {
            self.userID = chatterID // protected in serialQueue
            self.tenantID = tenantID
            self.isGuest = isGuest
            self.platform = platform
            self.subPlatform = subPlatform
            self.geo = geo
            self.brand = brand

            self.resetTerminalInfoInLock()
        }
    }

    func resetTerminalInfo() {
        LarkAppLog.shared.serialQueue.async {
            self.resetTerminalInfoInLock()
        }
    }
    private func resetTerminalInfoInLock() {
            if TrackService.appID.isEmpty { return }
            let userId = Encrypto.encryptoId(self.userID)
            LarkAppLog.shared.tracker.setCurrentUserUniqueID(userId)
            let customHeader: [String: Any] = {
                var customParams: [String: Any] = [:]
                if !self.deviceID.isEmpty {
                    customParams["device_id"] = self.deviceID
                }
                if !self.installID.isEmpty {
                    customParams["install_id"] = self.installID
                }
                if !self.platform.isEmpty {
                    customParams["platform"] = self.platform
                }
                if !self.subPlatform.isEmpty {
                    customParams["sub_platform"] = self.subPlatform
                }
                if !self.tenantID.isEmpty {
                    customParams["tenant_id"] = Encrypto.encryptoId(self.tenantID)
                }
                if !TrackService.appFullVersion.isEmpty {
                    customParams["app_full_version"] = TrackService.appFullVersion
                }
                if self.traceUserInterfaceIdiom, UIDevice.current.userInterfaceIdiom == .pad {
                    customParams["user_interface_idiom"] = UIDevice.current.userInterfaceIdiom.rawValue
                }
                if !self.isGuest {
                    customParams["custom.user_geo"] = self.geo
                    customParams["custom.tenant_brand"] = self.brand
                }

                customParams["custom_is_has_external_screen"] = hasExternal
                customParams["is_login"] = !self.isGuest
                customParams["lark_user_id"] = userId
                customParams["is_oversea_raw"] = ReleaseConfig.isLark
                // 添加皮肤埋点
                customParams["dark_mode"] = self.getThemeConfig()

                return customParams
            }()
            LarkAppLog.shared.updateCustomHeader(customHeader: customHeader)
    }

    private func getThemeConfig() -> String {
        /*
         参数名称：dark_mode
         参数位置：header.custom
         参数取值：
           default_dark ：跟随系统，当前显示深色模式
           default_light ：跟随系统，当前显示浅色模式
           dark：深色模式
           light：浅色模式
         */
        var config: String
        if #available(iOS 13.0, *) {
            var style = UDThemeManager.getSettingUserInterfaceStyle()
            switch style {
            case .dark:
                config = "dark"
            case .light:
                config = "light"
            default:
                style = UITraitCollection.current.userInterfaceStyle
                if style == .dark {
                    config = "default_dark"
                } else {
                    config = "default_light"
                }
            }
        } else {
            config = "light"
        }
        TrackService.logger.info("set dark mode config \(config)")
        return config
    }
}

final class PushSDKTrackerProxy: NSObject, PushSDKTracker {
    weak var trackService: TrackService?

    init(_ trackService: TrackService?) {
        self.trackService = trackService
        super.init()
    }

    func deviceID() -> String {
        return trackService?.deviceID ?? ""
    }

    func installID() -> String {
        return trackService?.installID ?? ""
    }

    func event(_ event: String, params: [String: Any]) {
        // FIXME: 用户隔离: Push 入口，不确定是否能拿到用户. 串的影响应该不大. 另外好像没有调用
        trackService?.track(event: event, params: params)
    }
}

final class ObserveThemeView: UIView {

    var themeChangeBlock: () -> Void

    init(_ themeChangeBlock: @escaping () -> Void) {
        self.themeChangeBlock = themeChangeBlock
        super.init(frame: .zero)
        self.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 12.0, *) {
            if self.traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
                self.themeChangeBlock()
            }
        }
    }
}
