//
//  ViewControllerSuspendable.swift
//  LarkSuspendable
//
//  Created by bytedance on 2021/1/5.
//

import LarkUIKit
import LarkTab

public enum SuspendGroup: UInt8, Codable {
    case chat = 0
    case thread
    case document
    case gadget
    case web
    case moment
    case other

    /// 分组在列表中的排序优先级，数值小的排在上面
    var priority: UInt8 {
        return rawValue
    }

    var name: String {
        switch self {
        case .chat:     return BundleI18n.LarkSuspendable.Lark_Floating_Chats
        case .thread:   return BundleI18n.LarkSuspendable.Lark_Floating_Topics
        case .document: return BundleI18n.LarkSuspendable.Lark_Floating_Docs
        case .gadget:   return BundleI18n.LarkSuspendable.Lark_Floating_Apps
        case .web:      return BundleI18n.LarkSuspendable.Lark_Floating_Links
        case .moment:   return BundleI18n.LarkSuspendable.Lark_Floating_Moments
        case .other:    return BundleI18n.LarkSuspendable.Lark_Floating_Other
        }
    }

    var cellType: DockCell.Type {
        switch self {
        case .chat, .thread:
            return ChatDockCell.self
        default:
            return BaseDockCell.self
        }
    }
}

public protocol ViewControllerSuspendable: UIViewController, CustomNaviAnimation {

    /// 页面的唯一 ID，由页面自己实现
    ///
    /// - 同样 ID 的页面只允许收入到浮窗一次，如果该属性被实现为 ID 恒定，则不可重复收入浮窗，
    /// 如果该属性被实现为 ID 变化（如自增），则可以重复收入多个相同页面。
    var suspendID: String { get }

    /// 页面来源（区分页面打开自正常路径还是多任务浮窗）
    ///
    /// - 正常路径打开每次产生新的 Source ID，从多任务浮窗打开则复用存入的 Source ID
    var suspendSourceID: String { get }

    /// 多任务列表中显示的图标
    ///
    /// 默认值为 nil，使用默认图标
    var suspendIcon: UIImage? { get }

    /// 悬浮窗展开现实的图标（通用 URL 形式）
    var suspendIconURL: String? { get }

    /// 悬浮窗展开现实的图标（ByteWebImage Key 形式）
    var suspendIconKey: String? { get }

    /// 通过 ByteWebImage Key 设置头像需要传入 entityID，一般是 chatID 或 chatterID
    var suspendIconEntityID: String? { get }

    /// 多任务列表中的页面标题
    var suspendTitle: String { get }

    /// EENavigator 路由系统中的 URL
    ///
    /// 当页面冷恢复时，EENavigator 使用该 URL 来重新构建页面。
    var suspendURL: String { get }

    /// EENavigator 路由系统中的页面参数，用于恢复页面状态
    ///
    /// - 作为 EENavigator 的 push 页面时的 context 参数传入。
    /// - 可用来保存恢复页面状态的必要信息，SuspendManager 只负责保存这些信息，如何使用这些信息来恢复页面状态需要接入方自己实现。
    /// - *AnyCodable* 为 Any 类型的 Codable 简单封装。
    var suspendParams: [String: AnyCodable] { get }
    
    /// 透传给 EENavigator 的参数，支持重复打开相同的页面，默认 nil
    var prefersForcePush: Bool? { get }

    /// 多任务列表分组
    var suspendGroup: SuspendGroup { get }

    /// 页面是否支持手势侧划添加（默认为 true）
    ///
    /// - 默认值为 true。
    /// - 如果仅用了手势侧划添加，则该页面在侧划关闭时右下角不会出现篮筐，只能通过调用
    /// SuspendManager,shared.addSuspend(::) 方法来添加。
    var isInteractive: Bool { get }

    /// 页面是否支持热恢复
    ///
    /// - 默认值为 false。
    /// - 支持热启动的 VC 会在关闭后被 SuspendManager 持有，并在多任务列表中打开时重新 push 打开。
    /// - 当收到系统 OOM 警告，或者进程被杀死时，已持有的热启动 VC 将会被释放，再次打开将会走冷启动流程。
    var isWarmStartEnabled: Bool { get }

    /// 是否页面关闭后可重用
    ///
    /// - 默认值为 true。
    /// - 在浮窗已满的情况下，侧划关闭的页面会被重新弹回，如果 VC 不支持关闭后立刻弹回
    /// （如文档页面的 DocView 已被回收），需要该变量返回 false，此时会使用 EENavigator
    /// 重新构建 VC 并弹回。
    var isViewControllerRecoverable: Bool { get }

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
    var analyticsTypeName: String { get }
}

public extension ViewControllerSuspendable {

    /// 页面来源（区分页面打开自正常路径还是多任务浮窗）
    var suspendSourceID: String {
        return suspendID
    }
    
    /// 透传给 EENavigator 的参数，支持重复打开相同的页面，默认 nil
    var prefersForcePush: Bool? {
        return nil
    }
    
    /// 悬浮窗展开显示的图标（UIImage 形式）
    var suspendIcon: UIImage? {
        return nil
    }

    /// 悬浮窗展开现实的图标（URL 形式）
    var suspendIconURL: String? {
        return nil
    }

    /// 悬浮窗展开现实的图标（ByteWebImage Key 形式）
    var suspendIconKey: String? {
        return nil
    }

    /// 通过 ByteWebImage Key 设置头像需要传入 entityID
    var suspendIconEntityID: String? {
        return nil
    }

    /// 页面是否支持手势侧划添加（默认为 true）
    var isInteractive: Bool {
        return true
    }

    /// 多任务列表分组
    var suspendGroup: SuspendGroup {
        return .other
    }

    /// 埋点统计所使用的类型名称
    var analyticsTypeName: String {
        return "unknown"
    }

    /// 是否页面关闭后可重用（默认 true）
    var isViewControllerRecoverable: Bool {
        return true
    }

    /// 获取页面的基本信息，用于持久化
    internal func getPatch() -> SuspendPatch {
        var params = suspendParams
        params[SuspendManager.sourceIDKey] = AnyCodable(suspendSourceID)
        return SuspendPatch(
            id: suspendID,
            source: suspendSourceID,
            icon: iconWrapper,
            iconURL: suspendIconURL,
            iconKey: suspendIconKey,
            iconEntityID: suspendIconEntityID,
            title: suspendTitle,
            url: suspendURL,
            params: params,
            forcePush: prefersForcePush,
            group: suspendGroup,
            analytics: analyticsTypeName
        )
    }

    /// 获取图标的 Codable 封装
    private var iconWrapper: ImageWrapper? {
        if let icon = suspendIcon {
            return ImageWrapper(image: icon)
        }
        return nil
    }

    /// Call this function manually after suspendID changed.
    ///
    /// 当在一个 VC 内部进行了跳转时（如文档页面内点击了目录跳转，或网页内点击了超链接），
    /// 虽然 VC 没有变化，但是跳转前后被认为是两个不同页面，此时需要手动调用该方法，
    /// 替换原有的项目。
    func suspendIdentifierDidChange(from prevId: String) {
        SuspendManager.shared.replaceSuspend(byId: prevId, patch: getPatch())
    }

    private func transformSuspendID(_ id: Int) -> String {
        return String(id)
    }
}

// swiftlint:disable all

/// 实现默认的 CustomNaviAnimation 协议方法，处理 Suspendable 页面的动画
public extension ViewControllerSuspendable {

    func pushAnimationController(for controller: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard SuspendManager.shared.suspendWindow != nil,
              let suspendToVC = controller as? ViewControllerSuspendable,
              SuspendManager.shared.isFromSuspend(sourceID: suspendToVC.suspendSourceID) else {
            return nil
        }
        return SuspendTransition(type: .push)
    }

    func pushAnimationController(from: UIViewController, to: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return pushAnimationController(for: to)
    }

    func selfPushAnimationController(from: UIViewController, to: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return pushAnimationController(for: to)
    }

    func popAnimationController(for controller: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard SuspendManager.shared.suspendWindow != nil,
              let suspendFromVC = controller as? ViewControllerSuspendable,
              SuspendManager.shared.isFromSuspend(sourceID: suspendFromVC.suspendSourceID) else {
            return nil
        }
        return SuspendTransition(type: .pop)
    }

    func popAnimationController(from: UIViewController, to: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return popAnimationController(for: from)
    }

    func selfPopAnimationController(from: UIViewController, to: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return popAnimationController(for: from)
    }

    var animationProxy: CustomNaviAnimation? {
        return SuspendManager.isSuspendEnabled ? self : nil
    }
}

// swiftlint:enable all
