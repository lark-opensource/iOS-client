//
//  BaseContext.swift
//  SKBitable
//
//  Created by yinyuan on 2023/8/13.
//

import Foundation
import SKCommon
import SpaceInterface
import SKFoundation

/**
  从 base@docx 之后，一个文档可以同时出现多个 Base，这里用于承载一些广泛场景被感知的 Base 上下文，用于实现多 Base 的隔离。
  注意1：BaseContext 会被广泛持有，因此 BaseContext 内部新增的属性都需要严格检查，注意不可强引用持有大对象。
  注意2：BaseContext 是 base 级别的上下文，不可携带 table/view 级别的信息。
 */
public protocol BaseContext: AnyObject, BaseContextPermission {
    /// 注意：在某些场景下，可能为空，表示前端没有明确是哪个 base，也不需要适配多 base（例如部分 showPanle 调用无法获得 bitable 上下文因此没有传入这个参数）。
    /// 因此在使用这个属性之前，你需要自己确保你的上下文 BaseContext.init 时指定了有效的不为空的 baseToken。
    var baseToken: String { get }
    /// 宿主文档信息（这里 base@docx 情况下，这里指的是 docx 的信息，独立 base 情况下这里指的是 base 文档的信息）
    var hostDocsInfo: DocsInfo? { get }
}

public protocol BaseContextPermission: AnyObject {
    /// 权限点位对象
    var permissionObj: BasePermissionObj { get }
    /// 权限点位对应的文档类型
    var permissionDocumentType: BrowserDocumentType { get }
    /// 文档权限变化监听器（建议使用 BasePermissionHelper）
    var permissionEventNotifier: DocsPermissionEventNotifier? { get }
    
    /// 真实用来鉴权的权限服务
    /// 1. 普通文档场景下为当前文档的权限
    /// 2. base@docx 场景下，refer base 是独立 base 的权限，inline base 是 docx 的权限
    /// 3. 记录分享、记录新建场景下为记录所在文档的权限服务
    var permissionService: UserPermissionService? { get }
    /// 宿主文档权限服务（当前 Browser 加载 URL 对应的文档）
    var hostPermissionService: UserPermissionService? { get }
    
    /// 是否可以复制文本
    var copyOrCutAvailability: BTCopyPermission { get }
    /// 是否有截屏权限（单文档保护返回 false ）（这里只能获得静态值，建议使用 BasePermissionHelper 进行动态监听）
    var hasCapturePermission: Bool { get }
    /// 是否应当显示水印（这里只能获得静态值，建议使用 BasePermissionHelper 进行动态监听）
    var shouldShowWatermark: Bool { get }
    /// 是否是 Base 外记录详情场景
    var isIndRecord: Bool { get }
    /// 是否是 Base 外记录新建场景
    var isAddRecord: Bool { get }
    /// 检查是否可以复制文本（单文档保护返回 true ）（带 Toast 提示）
    func checkCopyOrCutAvailabilityWithToast(view: UIView) -> Bool
    /// 手动更新完权限后，需要通知权限 SDK 刷新下权限
    func notifyPermissionSDKToSyncPermission()
    /// 手动更新权限（记录分享和记录新建不走putong ）
    func manualUpdatePermissionData()
}
