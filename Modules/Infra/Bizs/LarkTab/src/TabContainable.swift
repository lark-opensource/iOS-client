//
//  TabContainable.swift
//  LarkTab
//
//  Created by Hayden on 2023/5/12.
//

import UIKit
import UniverseDesignIcon
import RxCocoa

/// 服务端对自定义应用图标定义了三种格式：UD_TOKEN、URL、IMAGE_KEY、CCM_ICON
public enum CustomTabIcon {
    
    /// UDIcon 的类型名
    case iconName(UDIconType)
    /// ByteWebImage 使用的 avatar key 和 entityID
    case iconKey(String, entityID: String?)
    /// 图片的网络地址，可由网络库加载
    case urlString(String)
    /// CCM文档的iconInfo
    case iconInfo(String)

    /// 对 Icon 进行编码，方便 SDK 和服务端存储
    public func toCodable() -> TabCandidate.TabIcon {
        switch self {
        case .iconKey(let key, let entityID):
            return .byteKey(key, entityID: entityID)
        case .iconName(let iconType):
            return .udToken(iconType.figmaName ?? "")
        case .urlString(let url):
            return .webURL(url)
        case .iconInfo(let iconInfo):
            return .iconInfo(iconInfo)
        }
    }
}

/// 当前接入页面所属业务的类型，SDK 需要这个类型来拼接 uniqueId 和处理埋点等逻辑
public enum CustomBizType: Int, Codable {
    case UNKNOWN_TYPE      // 未知
    case CCM               // 文档
    case MINI_APP          // 开放平台：小程序
    case WEB_APP           // 开放平台：网页应用
    case MEEGO             // 开放平台：Meego
    case WEB               // 自定义H5网页
}

extension CustomBizType {
    public var stringValue: String {
        switch self {
        case .CCM:
            return "CCM"
        case .MINI_APP:
            return "MINI_APP"
        case .WEB_APP:
            return "WEB_APP"
        case .MEEGO:
            return "MEEGO"
        case .WEB:
            return "WEB"
        default:
            return "UNKNOWN"
        }
    }
}

/// 实现了此协议的页面，可以被配置（pin）到“底部导航（MainTabBar）” 和 “快捷导航（QuickLaunchView）” 上
public protocol TabContainable: UIViewController {

    /// 页面的唯一 ID，由页面的业务方自己实现
    ///
    /// - 同样 ID 的页面只允许收入到导航栏一次
    /// - 如果该属性被实现为 ID 恒定，SDK 在数据采集的时候会去重
    /// - 如果该属性被实现为 ID 变化（如自增），则会被 SDK 当成不同的页面采集到缓存，展现上就是在导航栏上出现多个这样的页面
    /// - 举个🌰
    /// - IM 业务：传入 ChatId 作为唯一 ID
    /// - CCM 业务：传入 objToken 作为唯一 ID
    /// - OpenPlatform（小程序 & 网页应用） 业务：传入应用的 uniqueID 作为唯一 ID
    /// - Web（网页） 业务：传入页面的 url 作为唯一 ID（为防止url过长，sdk 处理的时候会 md5 一下，业务方无感知）
    var tabID: String { get }

    /// 页面所属业务应用 ID，例如：开平网页应用和小程序的：cli_123455
    ///
    /// - 如果 BizType == WEB_APP 或者 MINI_APP 的话 SDK 会用这个 BizID 来给 app_id 赋值
    ///
    /// 目前有些业务，例如开平的网页应用（BizType == WEB_APP or BizType == MINI_APP），tabID 是传 url 来做唯一区分的
    /// 但是不同的 url 可能对应的应用 ID（BizID）是一样的，所以用这个字段来额外存储
    ///
    /// 所以这边就有一个特化逻辑：
    /// if(BizType == WEB_APP || BizType == MINI_APP ) { uniqueId = BizType + tabID, app_id = BizID}
    /// else { uniqueId = BizType+ tabID, app_id = tabID}
    var tabBizID: String { get }
    
    /// 页面所属业务类型
    ///
    /// - SDK 需要这个业务类型来拼接 uniqueId
    ///
    /// 现有类型：
    /// - CCM：文档
    /// - MINI_APP：开放平台：小程序
    /// - WEB_APP ：开放平台：网页应用
    /// - MEEGO：开放平台：Meego
    /// - WEB：自定义H5网页
    var tabBizType: CustomBizType { get }
    
    /// 文档细分类型
    /// 服务端定义的Otbject_type 跟 CCM的 docInfoType是映射关系，端上直接透传 rawValue即可
    var docInfoSubType: Int { get }

    /// 页面收入到 “底部导航（MainTabBar）” 和 “快捷导航（QuickLaunchWindow）” 上展示的图标（最近使用列表里面也使用同样的图标）
    /// - 如果后期最近使用列表里面要展示不同的图标需要新增一个协议
    var tabIcon: CustomTabIcon { get }

    /// 页面收入到 “底部导航（MainTabBar）” 和 “快捷导航（QuickLaunchWindow）” 上展示的标题（最近使用列表里面也使用同样的标题）
    var tabTitle: String { get }
    
    /// 多国语言版本：页面收入到 “底部导航（MainTabBar）” 和 “快捷导航（QuickLaunchWindow）” 上展示的标题
    /// - 如果业务方实现这个多国语言版本标题协议的话，会忽略tabTitle协议，优先使用多国语言的title
    /// - 返回一个字典：["zh_cn": "你好", "en_us": "Hello", "ja_jp": "没学过"]
    /// - 目前支持3国语言，分别是：zh_cn、en_us、ja_jp，对应的三个key，value就是各自对应的翻译语言
    var tabMultiLanguageTitle: [String: String] { get }

    /// 页面的 URL 或者 AppLink，路由系统 EENavigator 会使用该 URL 进行页面跳转
    ///
    /// - 当页面冷恢复时，EENavigator 使用该 URL 来重新构建页面
    /// - 对于Web（网页） 业务的话，这个值可能和 tabID 一样
    var tabURL: String { get }

    /// EENavigator 路由系统中的页面参数，用于恢复页面状态
    ///
    /// - 作为 EENavigator 的 push 页面时的 context 参数传入
    /// - 可用来保存恢复页面状态的必要信息，SuspendManager 只负责保存这些信息，如何使用这些信息来恢复页面状态需要接入方自己实现
    /// - *TabAnyCodable* 为 Any 类型的 Codable 简单封装
    var tabURLParams: [String: TabAnyCodable] { get }

    /// 页面是否支持热恢复
    ///
    /// - 默认值为 false
    /// - 支持热启动的 VC 会在关闭后被 SuspendManager 持有，并在 Tab 标签打开时重新 Push 打开
    /// - 当收到系统 OOM 警告，或者进程被杀死时，已持有的热启动 VC 将会被释放，再次打开将会走冷启动流程
    var isWarmStartEnabled: Bool { get }
    
    /// 埋点统计所使用的类型名称
    ///
    /// 现有类型：
    /// - private 单聊
    /// - secret 密聊
    /// - group 群聊
    /// - circle 话题群
    /// - topic 话题
    /// - bot 机器人
    /// - doc 文档
    /// - sheet 数据表格
    /// - mindnote 思维导图
    /// - slide 演示文稿
    /// - wiki 知识库
    /// - file 外部文件
    /// - web 网页
    /// - gadget 小程序
    var tabAnalyticsTypeName: String { get }

    /// 是否使用自定义NavigationItem
    ///
    /// - 默认值为true
    /// - 用于在TemporaryContainer中判断是否需要隐藏Container的NavigationItem
    var isCustomTemporaryNavigationItem: Bool { get }

    /// 在didappear加入Edge
    ///
    /// - 默认值为false
    var isAutoAddEdgeTabBar: Bool { get }

    /// 重新点击临时区域时是否强制刷新（重新从url获取vc）
    ///
    /// - 默认值为false
    var forceRefresh: Bool { get }

    /// 用于展示Navigation title
    ///
    /// - 默认值为空
    var navigationTitle: String { get }

    /// Container获取左侧NavigationItems
    ///
    /// - 默认值为空
    func getLeftBarItems() -> [TemporaryNavigationItem]

    /// Container获取右侧NavigationItems
    ///
    /// - 默认值为空
    func getRightBarItems() -> [TemporaryNavigationItem]

    // badge
    var badge: BehaviorRelay<BadgeType>? { get }
    var badgeStyle: BehaviorRelay<BadgeRemindStyle>? { get }

    func willMoveToTemporary()

    func willRemoveFromTemporary()

    func willCloseTemporary()
}

public extension TabContainable {

    var tabBizType: CustomBizType {
        return .UNKNOWN_TYPE
    }

    var docInfoSubType: Int {
        return -1
    }

    var tabURLParams: [String : TabAnyCodable] {
        return [:]
    }
    
    var tabMultiLanguageTitle: [String: String] {
        return [:]
    }
    
    var isWarmStartEnabled: Bool {
        return false
    }

    // TODO: @wanghaidong 实现某种逻辑，能够判断出该页面是从 Tab 中打开，此时才会使用 CustomNaviAnimation
    var isOpenedFromTab: Bool {
        return true
    }

    var isCustomTemporaryNavigationItem: Bool {
        return true
    }

    var isAutoAddEdgeTabBar: Bool {
        return false
    }

    var forceRefresh: Bool {
        return false
    }

    var navigationTitle: String {
        return ""
    }

    func getLeftBarItems() -> [TemporaryNavigationItem] {
        return []
    }


    func getRightBarItems() -> [TemporaryNavigationItem] {
        return []
    }

    var badge: BehaviorRelay<BadgeType>? {
        return nil
    }

    var badgeStyle: BehaviorRelay<BadgeRemindStyle>? {
        return nil
    }

    func willMoveToTemporary() {}

    func willCloseTemporary() {}

    func willRemoveFromTemporary() {}
}

// swiftlint:disable all
//
//public extension TabContainable {
//
//    func getTabCandidate() -> TabCandidate {
//        return TabCandidate(
//            id: tabBizType.rawValue + "_" + tabID,
//            icon: tabIcon.toCodable(),
//            title: tabTitle,
//            url: tabURL,
//            bizType: tabBizType,
//            appType: .webapp,
//            bizId: tabID
//        )
//    }
//}
