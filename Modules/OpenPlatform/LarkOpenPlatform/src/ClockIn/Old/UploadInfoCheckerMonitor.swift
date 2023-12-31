import LarkOPInterface
//  极速打卡埋点Key
let uploadInfoCheckerEvent = "op_terminal_info"
let triggerTypeKey = "trigger_type"
let locationSwitchKey = "location_switch"
let wifiSwitchKey = "wifi_switch"
let hasWifiKey = "has_wifi"
let hasLastWifiKey = "has_last_wifi"
let hasLocationKey = "has_location"
let inScopeKey = "in_scope"
let snapshotIdKey = "snapshot_id"
/// 极速打卡埋点Code
class MonitorCodeUploadInfoChecker: OPMonitorCode {
    /// 触发开始获取配置（网络或者缓存）
    static let trigger_start = MonitorCodeUploadInfoChecker(code: 10000, level: OPMonitorLevelNormal, message: "terminal_trigger_start")
    /// 开始拉取配置请求
    static let get_config_start = MonitorCodeUploadInfoChecker(code: 10001, level: OPMonitorLevelNormal, message: "request_settings_start")
    /// 拉取配置请求成功
    static let get_config_success = MonitorCodeUploadInfoChecker(code: 10002, level: OPMonitorLevelNormal, message: "request_settings_success")
    /// 拉取配置请求失败
    static let get_config_fail = MonitorCodeUploadInfoChecker(code: 10003, level: OPMonitorLevelError, message: "request_settings_fail")
    /// 通过配置的开关判断后，需要并开始走获取terminal info的逻辑（包括网络请求和本地cache触发入口）
    static let get_terminal_info_start = MonitorCodeUploadInfoChecker(code: 10004, level: OPMonitorLevelNormal, message: "should_upload_info")
    /// 信息获取完成后，信息埋点
    static let get_terminal_info_finish = MonitorCodeUploadInfoChecker(code: 10005, level: OPMonitorLevelNormal, message: "get_terminal_info_finish")
    /// 开始上报信息
    static let upload_info_start = MonitorCodeUploadInfoChecker(code: 10006, level: OPMonitorLevelNormal, message: "upload_info_start")
    /// 上报成功
    static let upload_info_success = MonitorCodeUploadInfoChecker(code: 10007, level: OPMonitorLevelNormal, message: "upload_terminal_info_fail")
    /// 上报失败
    static let upload_info_fail = MonitorCodeUploadInfoChecker(code: 10008, level: OPMonitorLevelError, message: "upload_info_fail")
    private init(code: Int, level:  OPMonitorLevel, message: String) { super.init(domain: MonitorCodeUploadInfoChecker.domain, code: code, level: level, message: message) }
    static let domain = "client.open_platform.gadget.terminal_info"
}
extension OPMonitor {
    func setTriggerType(_ type: TriggerType) -> OPMonitor {
        addCategoryValue(triggerTypeKey, type.rawValue)
    }
    func setLocationSwitch(_ value: Bool) -> OPMonitor {
        addCategoryValue(locationSwitchKey, value)
    }
    func setWifiSwitch(_ value: Bool) -> OPMonitor {
        addCategoryValue(wifiSwitchKey, value)
    }
    func setHasWifi(_ value: Bool) -> OPMonitor {
        addCategoryValue(hasWifiKey, value)
    }
    func setHasLastWifi(_ value: Bool) -> OPMonitor {
        addCategoryValue(hasLastWifiKey, value)
    }
    func setHasLocation(_ value: Bool) -> OPMonitor {
        addCategoryValue(hasLocationKey, value)
    }
    func setInScope(_ value: Bool) -> OPMonitor {
        addCategoryValue(inScopeKey, value)
    }
    func setSnapshotId(_ value: String?) -> OPMonitor {
        addCategoryValue(snapshotIdKey, value)
    }
}
/// 触发类型
enum TriggerType: String {
    /// 启动
    case start_up
    /// 收到push
    case push
    /// 登录
    case login
    /// 租户变化
    case account_change
    /// 网络变化
    case network_change
    /// 后台切前台
    case back_to_front
}
