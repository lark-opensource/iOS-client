import Foundation
import RxCocoa
import RxSwift
import LKCommonsLogging
import CryptoSwift

public enum AppType: String, Codable {
    // 租户配置的官方应用
    case native
    // 租户配置的小程序-适配导航栏
    case gadget
    // 租户配置的H5应用-适配导航栏
    case webapp
    // 用户手动添加或租户配置的开放平台的网页链接、小程序-可能没有适配导航栏
    case appTypeOpenApp
    // 用户手动添加或租户配置的链接类型，比如纯网页链接、云文档链接、群聊链接、多维表格链接等
    case appTypeURL
    // 租户配置的原生应用
    case appTypeCustomNative
}

public enum TabOpenMode: Int {
    /// 导航栏模式打开
    case switchMode

    /// 新容器-堆栈方式
    case pushMode
}

public enum TabIconStyle: Int {
    /// 在容器中居中，有白边背景框透出
    case AlignCenter
    /// 撑满整个容器，平铺效果
    case Tiled
}

public enum TabSource: Int, Codable {
    /// 租户来源
    case tenantSource = 1

    /// 用户来源
    case userSource = 2
}

public struct Tab: Hashable {
    public static let tabNameChangeNotification = Notification.Name("tabNameChangeNotification")

    static let logger = Logger.log(Tab.self, category: "Module.TabBar")
    
    public let disposeBag = DisposeBag()

    public let urlString: String

    public let appType: AppType
    /// The key field is used to filter the navigation configuration delivered by the server.
    /// It is defined at https://bytedance.feishu.cn/space/wiki/wikcnw7py4GELsgXaqNgiYdvTTe.
    /// If the `key` is not in the document, please contact **zhangmeng**.
    public let key: String

    /// tab 业务类型，用户自定义应用需要用这个字段
    public let bizType: CustomBizType

    /// tab 图标
    public let tabIcon: TabCandidate.TabIcon?

    /// tab 名称
    public var name: String?

    /// tab 打开方式
    public var openMode: TabOpenMode

    /// tab 图标的样式
    public var iconStyle: TabIconStyle?

    /// tab 来源
    public var source: TabSource
    
    /// tab 只能固定在主导航
    public var primaryOnly: Bool
    
    /// tab 是否可以移动：true => 不可移动（指在快捷导航和主导航之间移动）
    public var unmovable: Bool

    /// tab 是否可以删除：true => 可删除（用户自己固定的是可以删除的）
    public var erasable: Bool

    /// tab 唯一id，用户自定义应用的话和key一致，但是之前预置本地应用的话有一套自己的规则，和key不一样，详见下面文档
    /// https://bytedance.feishu.cn/space/wiki/wikcnw7py4GELsgXaqNgiYdvTTe.
    public var uniqueId: String?

    public var url: URL {
        // 这边不能强解，用户可以添加自定义应用后你不能保证传过来的 url 不为空
        if let url = URL(string: urlString) {
            return url
        } else {
            Self.logger.error("tab url is nil", additionalData: ["tab": "\(self.key)"])
            // 兜底首页消息的链接，确保强解也没问题
            return URL(string: "//client/feed/home")!
        }
    }

    public var extra: [String: Any] = [:]

    public var description: String {
        return "Key: \(key), uniqueId: \(uniqueId ?? ""), appType: \(appType), bizType: \(bizType), source: \(source), openMode: \(openMode), extra: \(extra)"
    }

    public init(url: String, appType: AppType, key: String, bizType: CustomBizType = .UNKNOWN_TYPE, name: String? = nil, tabIcon: TabCandidate.TabIcon? = nil, openMode: TabOpenMode = .switchMode, source: TabSource = .tenantSource, primaryOnly: Bool = false, unmovable: Bool = false, erasable: Bool = false, uniqueId: String? = nil) {
        self.urlString = url
        self.appType = appType
        self.key = key
        self.bizType = bizType
        self.name = name
        self.tabIcon = tabIcon
        self.openMode = openMode
        self.source = source
        self.primaryOnly = primaryOnly
        self.unmovable = unmovable
        self.erasable = erasable
        self.uniqueId = uniqueId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.urlString)
        hasher.combine(self.appType)
        hasher.combine(self.key)
    }

    // 判断是否是自定义类型的Tab（用户和租户都可以添加，不管是谁添加交互方式都一样，只是租户添加的无法删除）产品定义这么复杂的逻辑>_<
    public func isCustomType() -> Bool {
        var result = false
        if (appType == .appTypeOpenApp || appType == .appTypeURL) {
            result = true
        }
        return result
    }

    // 产品想一出是一出，自定义应用里面的开平小程序又要单独特化处理，也是醉
    public func isOpenPlatformMiniApp() -> Bool {
        var result = false
        // 用户添加的开平网页应用和小程序、租户配置的H5应用、租户配置的小程序
        if (appType == .appTypeOpenApp || appType == .webapp || appType == .gadget) {
            result = true
        }
        return result
    }
    
    // 判断是否是用户自己添加的Tab（有可能是租户添加的）产品定义这么复杂的逻辑>_<
    public func isUserPined() -> Bool {
        var result = false
        if source == .userSource {
            result = true
        }
        return result
    }
    
    public static func == (lhs: Tab, rhs: Tab) -> Bool {
        return lhs.key == rhs.key
    }

    // 本地支持的一方应用
    public static var allTabs: [Tab] = []
}

// swiftlint:disable missing_docs
public extension Tab {
    // native
    static let feed = Tab(url: "//client/feed/home", appType: .native, key: "conversation")
    static let calendar = Tab(url: "//client/calendar/home", appType: .native, key: "calendar")
    static let contact = Tab(url: "//client/contact/home", appType: .native, key: "contact")
    static let doc = Tab(url: "//client/docs/home", appType: .native, key: "space")
    static let appCenter = Tab(url: "//client/app/home", appType: .native, key: "appCenter")
    static let mail = Tab(url: "//client/mail/home", appType: .native, key: "mail")
    static let wiki = Tab(url: "//client/wiki/home", appType: .native, key: "wiki")
    static let byteview = Tab(url: "//client/byteview/home", appType: .native, key: "videochat")
    static let minutes = Tab(url: "//client/minutes/home", appType: .native, key: "videomm")
    static let todo = Tab(url: "//client/todo/home", appType: .native, key: "todo")
    static var moment = Tab(url: "//client/moment/home", appType: .native, key: "moments")
    static let base = Tab(url: "//client/base/home", appType: .native, key: "bitable")
    static let more = Tab(url: "", appType: .native, key: "more")
    static let search = Tab(url: "//client/search/home", appType: .native, key: "search") //cctodo:用native是不是不太合适
    // gadget base
    static let gadgetPrefix: String = "//client/gadget/home?key="

    // h5 base
    static let webAppPrefix: String = "//client/webApp/home?key="

    static let appTypeCustomNative: String = "//client/customNative/home?key="

    static let asKey: String = "openPlatformAS"

    /*
     const (
        NativeAppMessages  = 1  // 消息
        NativeAppCalendar  = 2  // 日历
        NativeAppWorkplace = 3  // 工作台
        NativeAppDrive     = 4  // 云文档
        NativeAppEmail     = 5  // 邮件
        NativeAppContacts  = 6  // 通讯录
        NativeAppPin       = 7  // Pin
        NativeAppWiki      = 8  // Wiki/知识库
        NativeAppGroups    = 9  // 小组
        NativeAppFavorites = 10 // 收藏
        NativeAppHub       = 11 // Hub
        NativeAppMeeting   = 12 // 会议
        NativeAppPano      = 13 // Pano
        NativeAppTodo      = 14 // 任务
        NativeAppMoments   = 15 // 公司圈
        NativeAppVideoLive = 16 // 直播
        NativeAppVideoMM   = 17 // 妙记
        NativeAppApproval  = 18 // 审批
        NativeBitable      = 19 // 多维表格
     )
     */
    static let keyToUniqueIdMap: [String: String] = [
        "conversation": "1",
        "calendar":     "2",
        "contact":      "6",
        "space":        "4",
        "appCenter":    "3",
        "mail":         "5",
        "wiki":         "8",
        "videochat":    "12",
        "videomm":      "17",
        "todo":         "14",
        "moments":      "15",
        "bitable":      "19"
    ]

    // dynamic
    static func gadget(key: String) -> Tab {
        let tab = Tab(url: gadgetPrefix + key, appType: .gadget, key: key)
        let existed = allTabs.first { (item: Tab) -> Bool in item.urlString == tab.urlString }
        return existed ?? tab
    }

    static func webApp(key: String) -> Tab {
        let tab = Tab(url: webAppPrefix + key, appType: .webapp, key: key)
        let existed = allTabs.first { $0.urlString == tab.urlString }
        return existed ?? Tab(url: webAppPrefix + key, appType: .webapp, key: key)
    }

    // 过滤了fg后，当前账户支持的应用map
    static var tabKeyDics: [String: Tab] {
        var dict: [String: Tab] = [:]
        for tab in allTabs {
            dict[tab.key] = tab
        }
        return dict
    }

    static func resetAllTabs() {
        Tab.allTabs = TabRegistry.allRegistedTabs
    }

    static var allTabURLs: [URL] {
        return allSupportTabs.map { $0.url }
    }

    // 过滤了fg后，当前账户支持的应用
    static var allSupportTabs: [Tab] {
        return Tab.allTabs.filter { Tab.tabKeyDics.values.contains($0) }
    }

    static func getTab(appType: AppType, key: String) -> Tab? {
        return Tab.allSupportTabs
            .first { $0.appType == appType && $0.key == key }
    }

    // 生成应用的唯一id
    static func generateAppUniqueId(bizType: CustomBizType, appId: String) -> String {
        // 按照SDK的格式生成每个应用的唯一id：{biz_type}_{md5(app_id)}
        let uuid = bizType.stringValue + "_" + appId.md5()
        Self.logger.info("<NAVIGATION_BAR> bizType = \(bizType), appId = \(appId), uniqueId = \(uuid)")
        return uuid
    }
}
// swiftlint:enable missing_docs
