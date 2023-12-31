//
//  OPBlockGuideInfoStatusModel.swift
//  OPBlock
//
//  Created by chenziyi on 2021/10/27.
//

import Foundation
import ECOInfra
import OPBlockInterface
import UniverseDesignEmpty
import ThreadSafeDataStructure

/// 错误页插画的种类
public enum guideInfoStatusImageType {
    case no_application
    case add_application
    case default_error
    case no_access
    case no_app_disabled
    case no_wifi
    case upgrading

    var image: UIImage {
        switch self {
        case .no_application:
            return UDEmptyType.noApplication.defaultImage()
        case .add_application:
            return UIImage.dynamic(light: BundleResources.OPBlock.add_application, dark: BundleResources.OPBlock.add_application_dark)
        case .default_error:
            return UDEmptyType.error.defaultImage()
        case .no_access:
            return UDEmptyType.noAccess.defaultImage()
        case .no_app_disabled:
            return UDEmptyType.platformNoAppDisabled.defaultImage()
        case .no_wifi:
            return UDEmptyType.noWifi.defaultImage()
        case .upgrading:
            return UDEmptyType.platformUpgrading1.defaultImage()
        }
    }
}

struct Button {
    let title: String
    let schema: String
}

public struct GuideInfoStatusViewItem {
    /// 有图/无图模式
    var imageType: guideInfoStatusImageType?
    /// todo：长文本/短文本？
    var displayMsg: String
    /// buttonTitle为nil，不显示button
    var button: Button?
    /// 极简模式下为true
    var isSimple = false
}

struct GuideInfoStatusViewItems {
    /// error到错误页数据的映射
	static var dataMap: SafeDictionary<OPError, GuideInfoStatusViewItem> = [:] + .readWriteLock
}

/// 引导信息错误码  https://bytedance.feishu.cn/docs/doccnOZuc2jEGWuGi042yqsg0hf
enum OPBlockGuideInfoStatus: Int {
    /// 可用
    case usable = 1
    /// 不允许显示
    case unableDisplay = 2
    /// 无法获得用户登录态
    case notAuth = 3
    /// 不可用
    case deactive = 100
    /// 未安装，ISV可被安装
    case uninstall = 101
    /// 下线
    case offline = 102
    /// 删除
    case delete = 103
    /// 已安装，已启用，用户不在黑名单，用户不具有可用性，管理员允许申请可用性
    case noPermissions = 200
    /// isv未发布且不可安装
    case disableInstallUnpublishApp = 201
    /// 不可装：下架且未安装
    case disableInstallUnshelveApp = 202
    /// 不可装：其他租户的自建应用
    case disableInstallOtherTenantSelfbuiltApp = 203
    /// 已安装，未启用
    case installNotStart = 204
    /// 已安装，被租户停用
    case installInDeactivate = 205
    /// 已安装，处于初始化状态
    case installInInit = 206
    /// 已安装，升级未启用停用
    case installUpdateNotStart = 207
    /// 已安装，付费应用到期停用
    case installExpireStop = 208
    /// 已安装，LARK套餐到期停用
    case installLarkExpireStop = 209
    /// 已安装，已启用，用户在黑名单
    case inBlockVisible = 210
    /// 已安装，已启用，用户不在黑名单，用户不具有可用性，管理员禁止申请可用性
    case disableApplyVisible = 211
    /// 不可装：ISV应用不可装
    case disableInstallIsvApp = 212
    /// 应用能力无效
    case notSupportAbility = 300
    /// Block对应的应用不存在
    case bindAppNotExist = 302
    /// Block需要升级版本才能使用
    case needUpgradeStatus = 0

    // 错误码301不支持，因为前端不具备此能力

    // 根据后端要求，其他情况默认为异常情况按照不允许加载处理
    var error: OPError? {
        switch self {
        case .usable:
            return nil
        case .unableDisplay:
            return OPBlockitMonitorCodeMountLaunchGuideInfoServer.unableDisplay.error()
        case .deactive:
            return OPBlockitMonitorCodeMountLaunchGuideInfoServer.deactivate.error()
        case .notAuth:
            return OPBlockitMonitorCodeMountLaunchGuideInfoServer.not_auth.error()
        case .uninstall:
            return OPBlockitMonitorCodeMountLaunchGuideInfoServer.uninstall.error()
        case .offline:
            return OPBlockitMonitorCodeMountLaunchGuideInfoServer.offline.error()
        case .delete:
            return OPBlockitMonitorCodeMountLaunchGuideInfoServer.delete.error()
        case .noPermissions:
            return OPBlockitMonitorCodeMountLaunchGuideInfoServer.no_permissions.error()
        case .disableInstallUnpublishApp:
            return OPBlockitMonitorCodeMountLaunchGuideInfoServer.disable_install_unpublish_app.error()
        case .disableInstallUnshelveApp:
            return OPBlockitMonitorCodeMountLaunchGuideInfoServer.disable_install_unshelve_app.error()
        case .disableInstallOtherTenantSelfbuiltApp:
            return OPBlockitMonitorCodeMountLaunchGuideInfoServer.disable_install_other_tenant_selfbuilt_app.error()
        case .installNotStart:
            return OPBlockitMonitorCodeMountLaunchGuideInfoServer.install_not_start.error()
        case .installInDeactivate:
            return OPBlockitMonitorCodeMountLaunchGuideInfoServer.install_in_deactivate.error()
        case .installInInit:
            return OPBlockitMonitorCodeMountLaunchGuideInfoServer.install_in_init.error()
        case .installUpdateNotStart:
            return OPBlockitMonitorCodeMountLaunchGuideInfoServer.install_update_not_start.error()
        case .installExpireStop:
            return OPBlockitMonitorCodeMountLaunchGuideInfoServer.install_expire_stop.error()
        case .installLarkExpireStop:
            return OPBlockitMonitorCodeMountLaunchGuideInfoServer.install_lark_expire_stop.error()
        case .inBlockVisible:
            return OPBlockitMonitorCodeMountLaunchGuideInfoServer.in_block_visible.error()
        case .disableApplyVisible:
            return OPBlockitMonitorCodeMountLaunchGuideInfoServer.disable_apply_visible.error()
        case .disableInstallIsvApp:
            return OPBlockitMonitorCodeMountLaunchGuideInfoServer.disable_install_isv_app.error()
        case .notSupportAbility:
            return OPBlockitMonitorCodeMountLaunchGuideInfoServer.not_support_ability.error()
        case .bindAppNotExist:
            return OPBlockitMonitorCodeMountLaunchGuideInfoServer.bind_app_not_exist.error()
        case .needUpgradeStatus:
            return OPBlockitMonitorCodeMountLaunchGuideInfoServer.need_upgrade_status.error()
        }
    }

    func register(display: String, button: Button?) {
        let imageType: guideInfoStatusImageType

        guard let error = self.error else {
            return
        }

        switch self {
        case .usable:
            return
        case .offline, .deactive, .delete, .disableInstallUnpublishApp, .disableInstallUnshelveApp, .disableInstallIsvApp, .installNotStart, .installInDeactivate, .installInInit, .installUpdateNotStart, .installExpireStop, .installLarkExpireStop, .notSupportAbility, .bindAppNotExist:

            imageType = .no_application

        case .uninstall:

            imageType = .add_application

        case .noPermissions, .disableApplyVisible, .inBlockVisible, .disableInstallOtherTenantSelfbuiltApp:

            imageType = .no_access

        case .needUpgradeStatus:

            imageType = .upgrading

        case .notAuth:

            imageType = .no_app_disabled

        default:

            imageType = .default_error

        }

        guard let button = button else {
            // 无按钮
            GuideInfoStatusViewItems.dataMap[error] = GuideInfoStatusViewItem(imageType: imageType, displayMsg: display, button: nil)
            return
        }
        GuideInfoStatusViewItems.dataMap[error] = GuideInfoStatusViewItem(imageType: imageType, displayMsg: display, button: button)
    }
}
