//
//  DKMainViewController+Suspendable.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/8/24.
//

import Foundation
import LarkSuspendable
import LarkTab
import SKCommon
import SKFoundation
import UniverseDesignIcon
import SKResource
import RxRelay
import RxSwift
import SpaceInterface

// MARK: - 悬浮窗 ViewControllerSuspendable
extension DKMainViewController: ViewControllerSuspendable {

    private var suspendCanView: Bool {
        guard let host = viewModel.hostModule else { return false }
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            return host.permissionService.validate(operation: .view).allow
        } else {
            return host.permissionRelay.value.isReadable
        }
    }

    /// 页面的唯一 ID，由页面自己实现
    ///
    /// - 同样 ID 的页面只允许收入到浮窗一次，如果该属性被实现为 ID 恒定，则不可重复收入浮窗，
    /// 如果该属性被实现为 ID 变化（如自增），则可以重复收入多个相同页面。
    public var suspendID: String {
        guard let host = viewModel.hostModule else {
            DocsLogger.driveInfo("cur main vc not support suspendable")
            return ""
        }
        return host.fileInfoRelay.value.fileToken
    }
    /// 悬浮窗展开显示的图标
    public var suspendIcon: UIImage? {
        guard let host = viewModel.hostModule else {
            DocsLogger.driveInfo("cur main vc not support suspendable")
            return nil
        }
        let docsInfo = host.docsInfoRelay.value
        return docsInfo.iconForSuspendable
    }
    /// 悬浮窗展开显示的标题
    public var suspendTitle: String {
        guard let host = viewModel.hostModule else {
            DocsLogger.driveInfo("cur main vc not support suspendable")
            return ""
        }
        if host.fileInfoRelay.value.name.count > 0 {
            return host.fileInfoRelay.value.name
        }

        if !suspendCanView {
            return BundleI18n.SKResource.LarkCCM_Workspace_ConAccess_NoPerm_Title
        }
        return host.docsInfoRelay.value.type.untitledString
    }
    /// EENavigator 路由系统中的 URL
    ///
    /// 当页面冷恢复时，EENavigator 使用该 URL 来重新构建页面。
    public var suspendURL: String {
        guard let host = viewModel.hostModule else {
            DocsLogger.driveInfo("cur main vc not support suspendable")
            return ""
        }
        let docsInfo = host.docsInfoRelay.value
        return docsInfo.urlForSuspendable()
    }
    /// EENavigator 路由系统中的页面参数，用于恢复页面状态
    /// 注意1. 记得添加from参数，由于目前只有CCM这边用到这个参数就没收敛到多任务框架中👀
    /// 注意2. 如果需要添加其他参数记得使用 ["infos":  Any]，因为胶水层只会放回参数里面的infos
    public var suspendParams: [String: AnyCodable] {
        let associatedFiles = viewModel.associatedFiles
        return ["from": "tasklist", "infos": ["associatedFiles": associatedFiles]]
    }
    /// 多任务列表分组
    public var suspendGroup: SuspendGroup {
        return .document
    }
    /// 页面是否支持手势侧划添加进入悬浮窗
    public var isInteractive: Bool {
        guard let host = viewModel.hostModule else {
            return false
        }
        return host.commonContext.previewFrom.isSuspendable
    }
    /// 页面是否支持热恢复，ps：暂时只需要冷恢复，后续会支持热恢复
    public var isWarmStartEnabled: Bool {
        return false
    }
    /// 埋点统计所使用的类型名称
    public var analyticsTypeName: String {
        guard let host = viewModel.hostModule else {
            DocsLogger.driveInfo("cur main vc not support suspendable")
            return ""
        }
        let docsInfo = host.docsInfoRelay.value
        return docsInfo.type.fileTypeForSta
    }
}

/// 接入 `TabContainable` 协议后，该页面可由用户手动添加至“底部导航” 和 “快捷导航” 上
extension DKMainViewController: TabContainable {

    /// 页面的唯一 ID，由页面的业务方自己实现
    ///
    /// - 同样 ID 的页面只允许收入到导航栏一次
    /// - 如果该属性被实现为 ID 恒定，SDK 在数据采集的时候会去重
    /// - 如果该属性被实现为 ID 变化（如自增），则会被 SDK 当成不同的页面采集到缓存，展现上就是在导航栏上出现多个这样的页面
    /// - 举个🌰
    /// - IM 业务：传入 ChatId 作为唯一 ID
    /// - CCM 业务：传入 objToken 作为唯一 ID
    /// - OpenPlatform（小程序 & 网页应用） 业务：传入应用的 uniqueID 作为唯一 ID
    /// - Web（网页） 业务：传入页面的 url 作为唯一 ID（为防止url过长，sdk 处理的时候会 md5 一下，业务方无感知
    public var tabID: String {
        guard let hostModule = viewModel.hostModule else {
            DocsLogger.debug("cur main vc not have hostModule")
            return ""
        }
        // Wiki场景跳过，由WikiContainerVC处理，避免重复添加到最近记录
        if hostModule.docsInfoRelay.value.isFromWiki == true {
            DocsLogger.debug("cur main vc is fromWiki")
            return ""
        }
        // 需要进行二跳场景时，避免重复添加最近记录（e.g. Space移动到Wiki，从Space链接打开后会跳转到Wiki页面）
        if shouldRedirect {
            return ""
        }
        DocsLogger.debug("cur main vc scene is \(hostModule.scene)")
        // 跳过附件场景，避免文档内附件添加到最近记录
        return hostModule.scene == .space ? suspendID : ""
    }

    /// 页面所属业务应用 ID，例如：网页应用的：cli_123455
    ///
    /// - 如果 BizType == WEB_APP 的话 SDK 会用这个 BizID 来给 app_id 赋值
    ///
    /// 目前有些业务，例如开平的网页应用（BizType == WEB_APP），tabID 是传 url 来做唯一区分的
    /// 但是不同的 url 可能对应的应用 ID（BizID）是一样的，所以用这个字段来额外存储
    ///
    /// 所以这边就有一个特化逻辑：
    /// if(BizType == WEB_APP) { uniqueId = BizType + tabID, app_id = BizID}
    /// else { uniqueId = BizType+ tabID, app_id = tabID}
    public var tabBizID: String {
        return ""
    }
    
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
    public var tabBizType: CustomBizType {
        return .CCM
    }

    public var docInfoSubType: Int {
        return DocsType.file.rawValue
    }

    /// 页面收入到 “底部导航（MainTabBar）” 和 “快捷导航（QuickLaunchWindow）” 上展示的图标（最近使用列表里面也使用同样的图标）
    /// - 如果后期最近使用列表里面要展示不同的图标需要新增一个协议
    public var tabIcon: CustomTabIcon {
        guard let host = viewModel.hostModule else {
            DocsLogger.info("cur main vc not support suspendable")
            return .iconName(.fileUnknowColorful)
        }
        if !suspendCanView {
            return .iconName(.fileUnknowColorful)
        }
        let docsInfo = host.docsInfoRelay.value
        // 新的自定义icon信息
        if let iconInfo = docsInfo.iconInfo {
            return .iconInfo(iconInfo)
        }
        return .iconName(docsInfo.iconTypeForTabContainable)
    }

    /// 页面收入到 “底部导航（MainTabBar）” 和 “快捷导航（QuickLaunchWindow）” 上展示的标题（最近使用列表里面也使用同样的标题）
    public var tabTitle: String {
        suspendTitle
    }

    /// 页面的 URL 或者 AppLink，路由系统 EENavigator 会使用该 URL 进行页面跳转
    ///
    /// - 当页面冷恢复时，EENavigator 使用该 URL 来重新构建页面
    /// - 对于Web（网页） 业务的话，这个值可能和 tabID 一样
    public var tabURL: String {
        suspendURL
    }
    
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
    /// - drive 文件
    public var tabAnalyticsTypeName: String {
        return "drive"
    }
    
    /// 重新点击临时区域时是否强制刷新（重新从url获取vc）
    ///
    /// - 默认值为false
    public var forceRefresh: Bool {
        true
    }
}
