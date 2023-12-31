//
//  OPBlockitMountMonitorCode.swift
//  OPBlockInterface
//
//  Created by lixiaorui on 2022/4/12.
//

import Foundation
import LarkOPInterface

public extension String {
    public enum OPBlockitMonitorKey {
        // 统一定义blockit内部埋点的eventName
        public static let eventName = "op_blockit_event"

        public static let loadDurationParam = "from_app_load_duration"

        public static let traceLinkEventName = "op_blockit_trace_link"

        public static let traceLinkParam = "link_trace_id"
    }
}

// code 方案设计见https://bytedance.feishu.cn/docx/doxcnITCJv9CS3lpSMokIR3AVac
public final class OPBlockitMonitorCodeMountEntity: OPMonitorCode {

    /** Block挂载成功 */
    public static let success = OPBlockitMonitorCodeMountEntity(code: 0, level: OPMonitorLevelNormal, message: "success")

    /** Block挂载失败-内部错误 */
    public static let internal_error = OPBlockitMonitorCodeMountEntity(code: -10000, level: OPMonitorLevelError, message: "internal_error")

    /** Block挂载失败-入参错误 */
    public static let param_invalid = OPBlockitMonitorCodeMountEntity(code: -10001, level: OPMonitorLevelError, message: "param_invalid")

    /** Block挂载失败-拉取应用机制网络请求失败 */
    public static let fetch_block_entity_network_error = OPBlockitMonitorCodeMountEntity(code: -10002, level: OPMonitorLevelError, message: "fetch_block_entity_network_error")

    /** Block挂载失败-拉取应用机制请求业务错误 */
    public static let fetch_block_entity_biz_error = OPBlockitMonitorCodeMountEntity(code: -10003, level: OPMonitorLevelError, message: "fetch_block_entity_biz_error")

    /** 卸载block： blockit收到unMount触发*/
    public static let unmount_block = OPBlockitMonitorCodeMountEntity(code: 10000, level: OPMonitorLevelNormal, message: "unmount_block")

    /** 开始挂载block： blockit收到mount触发*/
    public static let start_mount_block = OPBlockitMonitorCodeMountEntity(code: 10001, level: OPMonitorLevelNormal, message: "start_mount_block")

    /** 开始entity流程*/
    public static let start_block_entity = OPBlockitMonitorCodeMountEntity(code: 10002, level: OPMonitorLevelNormal, message: "start_block_entity")

    /** 开启请求entity*/
    public static let start_fetch_block_entity = OPBlockitMonitorCodeMountEntity(code: 10003, level: OPMonitorLevelNormal, message: "start_fetch_block_entity")

    /** 请求entity成功*/
    public static let fetch_block_entity_success = OPBlockitMonitorCodeMountEntity(code: 10004, level: OPMonitorLevelNormal, message: "fetch_block_entity_success")

    /** entity流程结束*/
    public static let block_entity_result = OPBlockitMonitorCodeMountEntity(code: 10005, level: OPMonitorLevelNormal, message: "block_entity_result")

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: OPBlockitMonitorCodeMountEntity.domain, code: code, level: level, message: message)
    }

    static public let domain = "client.open_platform.blockit.mount.entity"
}

public final class OPBlockitMonitorCodeMountLaunch: OPMonitorCode {

    /** Block启动成功 */
    public static let success = OPBlockitMonitorCodeMountLaunch(code: 0, level: OPMonitorLevelNormal, message: "success")

    /** Block启动失败-内部错误 */
    public static let internal_error = OPBlockitMonitorCodeMountLaunch(code: -10000, level: OPMonitorLevelError, message: "internal_error")

    /** Block开始luanch流程 */
    public static let start_launch_block = OPBlockitMonitorCodeMountLaunch(code: 10000, level: OPMonitorLevelNormal, message: "start_launch_block")

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: OPBlockitMonitorCodeMountLaunch.domain, code: code, level: level, message: message)
    }

    static public let domain = "client.open_platform.blockit.mount.launch"
}

public final class OPBlockitMonitorCodeMountLaunchMeta: OPMonitorCode {

    /** Block启动失败-加载meta加载 */
    public static let load_meta_fail = OPBlockitMonitorCodeMountLaunchMeta(code: -10004, level: OPMonitorLevelError, message: "load_meta_fail")

    /** Block开始meta&pkg流程 */
    public static let start_load_meta_pkg = OPBlockitMonitorCodeMountLaunchMeta(code: 10000, level: OPMonitorLevelNormal, message: "start_load_meta_pkg")

    /** Block 成功完成meta&pkg流程 */
    public static let load_meta_pkg_success = OPBlockitMonitorCodeMountLaunchMeta(code: 10001, level: OPMonitorLevelNormal, message: "load_meta_pkg_success")

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: OPBlockitMonitorCodeMountLaunchMeta.domain, code: code, level: level, message: message)
    }

    static public let domain = OPBlockitMonitorCodeMountLaunch.domain + ".meta"
}

public final class OPBlockitMonitorCodeMountLaunchPackage: OPMonitorCode {

    /** Block启动失败-加载package失败 */
    public static let load_package_fail = OPBlockitMonitorCodeMountLaunchPackage(code: -10005, level: OPMonitorLevelError, message: "load_package_fail")

    /** Block开始解析pkg */
    public static let start_parse_pkg = OPBlockitMonitorCodeMountLaunchPackage(code: 10000, level: OPMonitorLevelNormal, message: "start_parse_pkg")

    /** Block解析pkg完成 */
    public static let parse_pkg_result = OPBlockitMonitorCodeMountLaunchPackage(code: 10001, level: OPMonitorLevelNormal, message: "parse_pkg_result")

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: OPBlockitMonitorCodeMountLaunchPackage.domain, code: code, level: level, message: message)
    }

    static public let domain = OPBlockitMonitorCodeMountLaunch.domain + ".package"
}

public final class OPBlockitMonitorCodeMountLaunchComponent: OPMonitorCode {

    /** Block启动失败-加载component失败 */
    public static let component_fail = OPBlockitMonitorCodeMountLaunchComponent(code: -10006, level: OPMonitorLevelError, message: "component_fail")

    /** Block启动失败-加载component失败 */
    public static let start_compoennt = OPBlockitMonitorCodeMountLaunchComponent(code: 10000, level: OPMonitorLevelNormal, message: "start_compoennt")

    /** Block启动失败-加载component失败 */
    public static let component_success = OPBlockitMonitorCodeMountLaunchComponent(code: 10001, level: OPMonitorLevelNormal, message: "component_success")

    /** Block启动失败-加载component失败 */
    public static let start_render_page = OPBlockitMonitorCodeMountLaunchComponent(code: 10002, level: OPMonitorLevelNormal, message: "start_render_page")

    /** Block启动失败-加载component失败 */
    public static let render_page_result = OPBlockitMonitorCodeMountLaunchComponent(code: 10003, level: OPMonitorLevelNormal, message: "render_page_result")

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: OPBlockitMonitorCodeMountLaunchComponent.domain, code: code, level: level, message: message)
    }

    static public let domain = OPBlockitMonitorCodeMountLaunch.domain + ".component"
}

public final class OPBlockitMonitorCodeMountLaunchGuideInfo: OPMonitorCode {

    /** Block启动失败-应用机制请求网络失败 */
    public static let fetch_guide_info_network_error = OPBlockitMonitorCodeMountLaunchGuideInfo(code: -10001, level: OPMonitorLevelError, message: "fetch_guide_info_network_error")

    /** Block启动失败-应用机制请求业务错误 */
    public static let fetch_guide_info_biz_error = OPBlockitMonitorCodeMountLaunchGuideInfo(code: -10002, level: OPMonitorLevelError, message: "fetch_guide_info_biz_error")

    /** Block启动失败-应用机制检查失败 */
    public static let check_guide_info_unknown = OPBlockitMonitorCodeMountLaunchGuideInfo(code: -10003, level: OPMonitorLevelError, message: "check_guide_info_unknown")

    /** Block开始guideinfo流程 */
    public static let start_guide_info = OPBlockitMonitorCodeMountLaunchGuideInfo(code: 10000, level: OPMonitorLevelNormal, message: "start_guide_info")

    /** Block开始请求guideinfo */
    public static let start_fetch_guide_info = OPBlockitMonitorCodeMountLaunchGuideInfo(code: 10001, level: OPMonitorLevelNormal, message: "start_fetch_guide_info")

    /** Block请求guideinfo成功 */
    public static let fetch_guide_info_success = OPBlockitMonitorCodeMountLaunchGuideInfo(code: 10002, level: OPMonitorLevelNormal, message: "fetch_guide_info_success")

    /** Block完成guideinfo流程：成功 */
    public static let guide_info_success = OPBlockitMonitorCodeMountLaunchGuideInfo(code: 10003, level: OPMonitorLevelNormal, message: "guide_info_success")

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: OPBlockitMonitorCodeMountLaunchGuideInfo.domain, code: code, level: level, message: message)
    }

    static public let domain = OPBlockitMonitorCodeMountLaunch.domain + ".guide_info"
}

public final class OPBlockitMonitorCodeMountLaunchGuideInfoServer: OPMonitorCode {

    /// 可用
    public static let usable = OPBlockitMonitorCodeMountLaunchGuideInfoServer(code: 1, level: OPMonitorLevelNormal, message: "usable")

    /// 不可用
    public static let deactivate = OPBlockitMonitorCodeMountLaunchGuideInfoServer(code: 100, level: OPMonitorLevelError, message: "deactivate")

    /// 不允许显示
    public static let unableDisplay = OPBlockitMonitorCodeMountLaunchGuideInfoServer(code: 2, level: OPMonitorLevelError, message: "unableDisplay")

    /// 应用能力无效
    public static let not_support_ability = OPBlockitMonitorCodeMountLaunchGuideInfoServer(code: 300, level: OPMonitorLevelError, message: "not_support_ability")

    /// Block对应的应用不存在
    public static let bind_app_not_exist = OPBlockitMonitorCodeMountLaunchGuideInfoServer(code: 302, level: OPMonitorLevelError, message: "bind_app_not_exist")

    /// Block需要升级版本才能使用
    public static let need_upgrade_status = OPBlockitMonitorCodeMountLaunchGuideInfoServer(code: 0, level: OPMonitorLevelError, message: "need_upgrade_status")

    /// 下线
    public static let offline = OPBlockitMonitorCodeMountLaunchGuideInfoServer(code: 102, level: OPMonitorLevelError, message: "offline")

    /// 删除
    public static let delete = OPBlockitMonitorCodeMountLaunchGuideInfoServer(code: 103, level: OPMonitorLevelError, message: "delete")

    /// isv未发布且不可安装
    public static let disable_install_unpublish_app = OPBlockitMonitorCodeMountLaunchGuideInfoServer(code: 201, level: OPMonitorLevelError, message: "disable_install_unpublish_app")

    /// 不可装：下架且未安装
    public static let disable_install_unshelve_app = OPBlockitMonitorCodeMountLaunchGuideInfoServer(code: 202, level: OPMonitorLevelError, message: "disable_install_unshelve_app")
    /// 不可装：其他租户的自建应用
    public static let disable_install_other_tenant_selfbuilt_app = OPBlockitMonitorCodeMountLaunchGuideInfoServer(code: 203, level: OPMonitorLevelError, message: "disable_install_other_tenant_selfbuilt_app")
    
    /// 不可装：isv应用不可装
    public static let disable_install_isv_app = OPBlockitMonitorCodeMountLaunchGuideInfoServer(code: 212, level: OPMonitorLevelError, message: "disable_install_isv_app")
    /// 未安装，isv可被安装
    public static let uninstall = OPBlockitMonitorCodeMountLaunchGuideInfoServer(code: 101, level: OPMonitorLevelError, message: "uninstall")

    /// 已安装，未启用
    public static let install_not_start = OPBlockitMonitorCodeMountLaunchGuideInfoServer(code: 204, level: OPMonitorLevelError, message: "install_not_start")

    /// 已安装，被租户停用
    public static let install_in_deactivate = OPBlockitMonitorCodeMountLaunchGuideInfoServer(code: 205, level: OPMonitorLevelError, message: "install_in_deactivate")

    /// 已安装，处于初始化状态
    public static let install_in_init = OPBlockitMonitorCodeMountLaunchGuideInfoServer(code: 206, level: OPMonitorLevelError, message: "install_in_init")

    /// 已安装，升级未启用停用
    public static let install_update_not_start = OPBlockitMonitorCodeMountLaunchGuideInfoServer(code: 207, level: OPMonitorLevelError, message: "install_update_not_start")

    /// 已安装，付费应用到期停用
    public static let install_expire_stop = OPBlockitMonitorCodeMountLaunchGuideInfoServer(code: 208, level: OPMonitorLevelError, message: "install_expire_stop")

    /// 已安装，lark套餐到期停用
    public static let install_lark_expire_stop = OPBlockitMonitorCodeMountLaunchGuideInfoServer(code: 209, level: OPMonitorLevelError, message: "install_lark_expire_stop")

    /// 已安装，已启用，用户在黑名单
    public static let in_block_visible = OPBlockitMonitorCodeMountLaunchGuideInfoServer(code: 210, level: OPMonitorLevelError, message: "in_block_visible")

    /// 已安装，已启用，用户不在黑名单，用户不具有可用性，管理员禁止申请可用性
    public static let disable_apply_visible = OPBlockitMonitorCodeMountLaunchGuideInfoServer(code: 211, level: OPMonitorLevelError, message: "disable_apply_visible")

    /// - 已安装，已启用，用户不在黑名单，用户不具有可用性，管理员允许申请可用性
    public static let no_permissions = OPBlockitMonitorCodeMountLaunchGuideInfoServer(code: 200, level: OPMonitorLevelError, message: "no_permissions")

    /// - 无权限
    public static let not_auth = OPBlockitMonitorCodeMountLaunchGuideInfoServer(code: 3, level: OPMonitorLevelError, message: "not_auth")

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: OPBlockitMonitorCodeMountLaunchGuideInfoServer.domain, code: code, level: level, message: message)
    }

    static public let domain = OPBlockitMonitorCodeMountLaunchGuideInfo.domain + ".server"
}
