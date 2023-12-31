//
//  ByteViewDependencies.swift
//  ByteViewDependency
//
//  Created by kiri on 2021/7/1.
//

import Foundation

/// 提供所有VC依赖的入口，没有依赖注入时可使用此入口
/// - 指定为var的是静态依赖，需要resolve的是动态依赖（一般为用户相关的依赖）
public struct Dependencies {
    private static var instance: DependenciesProtocol.Type?
    public static func setup<T: DependenciesProtocol>(_ implement: T.Type) {
        self.instance = implement
    }

    private static var unwrapped: DependenciesProtocol.Type { instance! }
    /// 全局配置
    public static var config: ConfigDependency { unwrapped.config }
    /// 获取账号信息
    public static func resolveAccount(userId: String) -> AccountInfo? { unwrapped.resolveAccount(userId: userId) }
    /// 多scene相关
    public static var scene: SceneDependency { unwrapped.scene }
    /// 浮窗相关(suspend window)
    public static var window: WindowDependency { unwrapped.window }
    /// 性能监控
    public static var monitor: MonitorDependency { unwrapped.monitor }
    /// 聊天表情
    public static var emotion: EmotionDependency { unwrapped.emotion }
    /// Lark文档
    public static var follow: FollowDependency { unwrapped.follow }
    /// 会议纪要
    public static var notes: NotesDependency { unwrapped.notes }
    /// 会议纪要-文档模板
    public static var template: TemplateDependency { unwrapped.template }
    /// 日程相关
    public static var calendar: CalendarDependency { unwrapped.calendar }

    public static var universalUserSettings: UniversalUserSettingsDependency { unwrapped.universalUserSettings }

    /// 讨论组信息
    public static var chat: ChatDependency { unwrapped.chat }
    /// Onboarding
    public static var guide: GuideDependency { unwrapped.guide }
    /// 妙记
    public static var minutes: MinutesDependency { unwrapped.minutes }
    /// 直播
    public static var live: LiveDependency { unwrapped.live }
    /// 水印
    public static var watermark: WatermarkDependency { unwrapped.watermark }
    /// push卡片
    public static var pushCard: PushCardDependency { unwrapped.pushCard }
    /// 个人设置
    public static var userSettings: UserSettingsDependency { unwrapped.userSettings }
    /// 安全状态
    public static var securityState: SecurityStateDependency { unwrapped.securityState }
    /// 通用搜索组件
    public static var picker: PickerDependency { unwrapped.picker }
    /// RVC
    public static var rvc: RVCDependency { unwrapped.rvc }
    /// 发送im消息
    public static func resolveSendMessage(userId: String) -> SendMessageDependency { unwrapped.resolveSendMessage(userId: userId) }

    /// 富文本, T只能是RichText
    public static func resolveRichText<T>(for type: T.Type) -> RichTextDependency<T>? {
        instance?.resolveRichText(for: type)
    }

    /// 路由跳转
    public static func resolveRoute(userId: String) -> RouteDependency {
        unwrapped.resolveRoute(userId: userId)
    }
}

public protocol DependenciesProtocol {
    static var config: ConfigDependency { get }
    static var scene: SceneDependency { get }
    static var window: WindowDependency { get }
    static var monitor: MonitorDependency { get }
    static var emotion: EmotionDependency { get }
    static var follow: FollowDependency { get }
    static var notes: NotesDependency { get }
    static var template: TemplateDependency { get }
    static var calendar: CalendarDependency { get }
    static var universalUserSettings: UniversalUserSettingsDependency { get }

    static var chat: ChatDependency { get }
    static var guide: GuideDependency { get }
    static var minutes: MinutesDependency { get }
    static var live: LiveDependency { get }
    static var watermark: WatermarkDependency { get }
    static var pushCard: PushCardDependency { get }
    static var userSettings: UserSettingsDependency { get }
    static var securityState: SecurityStateDependency { get }
    static var picker: PickerDependency { get }
    static var rvc: RVCDependency { get }
    static func resolveSendMessage(userId: String) -> SendMessageDependency
    static func resolveRichText<T>(for type: T.Type) -> RichTextDependency<T>?
    static func resolveRoute(userId: String) -> RouteDependency
    static func resolveAccount(userId: String) -> AccountInfo?
}

public struct DependencyHandlers {
    private static var instance: DependencyHandlersProtocol.Type?
    public static func setup<T: DependencyHandlersProtocol>(_ implement: T.Type) {
        self.instance = implement
    }

    public static var appDelegate: ByteViewAppDelegate? { instance?.appDelegate }
    public static var accountDelegate: ByteViewAccountDelegate? { instance?.accountDelegate }
    @available(iOS 13.0, *)
    public static var sceneService: SceneService.Type? { instance?.sceneService }
    public static var callKitService: ByteViewCallKitSetupDelegate? { instance?.callKitService }
}

public protocol DependencyHandlersProtocol {
    static var appDelegate: ByteViewAppDelegate? { get }
    static var accountDelegate: ByteViewAccountDelegate? { get }
    @available(iOS 13.0, *)
    static var sceneService: SceneService.Type? { get }
    static var callKitService: ByteViewCallKitSetupDelegate? { get }
}
