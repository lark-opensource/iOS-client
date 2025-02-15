// DO NOT EDIT.
//
// Generated by the Swift generator for OPMonitorCode.
// Source: https://bytedance.feishu.cn/sheets/shtcnCCboz4CUWBUtZkdmZV0PLb?sheet=w8PMFS&table=tblQdWBNX4EzK5vJ&view=vew6jSbQpC
// Date:   2020/08/14 16:44
//
// For information on using the generated types, please see the documentation:
//  https://bytedance.feishu.cn/sheets/shtcnCCboz4CUWBUtZkdmZV0PLb

import Foundation
import LarkOPInterface

@objcMembers
public final class APIMonitorCodeFaceLiveness: OPMonitorCode {

    /// 录入二/三要素成功
    public static let upload_info_success = APIMonitorCodeFaceLiveness(code: 10000, level: OPMonitorLevelNormal, message: "upload_info_success")

    /// 录入二/三要素到AI Lab失败
    public static let upload_info_fail = APIMonitorCodeFaceLiveness(code: 10001, level: OPMonitorLevelError, message: "upload_info_fail")

    /// 用户已录入, 本次录入的姓名与已录入不匹配
    public static let update_info_name_mismatch = APIMonitorCodeFaceLiveness(code: 10002, level: OPMonitorLevelError, message: "update_info_name_mismatch")

    /// 用户已录入, 本次录入的身份证号与已录入不匹配
    public static let update_info_code_mismatch = APIMonitorCodeFaceLiveness(code: 10003, level: OPMonitorLevelError, message: "update_info_code_mismatch")

    /// 用户已录入, 本次录入的手机号与已录入不匹配
    public static let update_info_mobile_mismatch = APIMonitorCodeFaceLiveness(code: 10004, level: OPMonitorLevelError, message: "update_info_mobile_mismatch")

    /// 查询是否已录入成功
    public static let check_has_authed_success = APIMonitorCodeFaceLiveness(code: 10005, level: OPMonitorLevelNormal, message: "check_has_authed_success")

    /// 查询是否已录入失败-用户未录入
    public static let check_has_authed_not_auth = APIMonitorCodeFaceLiveness(code: 10006, level: OPMonitorLevelError, message: "check_has_authed_not_auth")

    /// 获取活体检测票据成功
    public static let get_user_ticket_success = APIMonitorCodeFaceLiveness(code: 10007, level: OPMonitorLevelNormal, message: "get_user_ticket_success")

    /// 获取活体检测票据请求后端参数非法
    public static let get_user_ticket_param_error = APIMonitorCodeFaceLiveness(code: 10008, level: OPMonitorLevelError, message: "get_user_ticket_param_error")

    /// 网络错误（通用错误）
    public static let network_error = APIMonitorCodeFaceLiveness(code: 10009, level: OPMonitorLevelError, message: "network_error")

    /// 内部错误（通用兜底错误）
    public static let internal_error = APIMonitorCodeFaceLiveness(code: 10010, level: OPMonitorLevelError, message: "internal_error")

    /// 活体检测成功
    public static let face_live_success = APIMonitorCodeFaceLiveness(code: 10011, level: OPMonitorLevelNormal, message: "face_live_success")

    /// 用户取消活体
    public static let face_live_user_cancel = APIMonitorCodeFaceLiveness(code: 10012, level: OPMonitorLevelWarn, message: "face_live_user_cancel")

    /// 活体检测服务端对比失败后用户点击取消
    public static let face_live_user_cancel_after_error = APIMonitorCodeFaceLiveness(code: 10013, level: OPMonitorLevelWarn, message: "face_live_user_cancel_after_error")

    /// 活体检测无相机/存储等设备权限, 在分屏模式下使用等
    public static let face_live_device_interrupt = APIMonitorCodeFaceLiveness(code: 10014, level: OPMonitorLevelWarn, message: "face_live_device_interrupt")

    /// 活体检测其他错误
    public static let face_live_internal_error = APIMonitorCodeFaceLiveness(code: 10015, level: OPMonitorLevelError, message: "face_live_internal_error")

    /// 查询是否已录入接口其他异常
    public static let check_has_authed_other_error = APIMonitorCodeFaceLiveness(code: 10016, level: OPMonitorLevelError, message: "check_has_authed_other_error")

    /// 录入要素其他异常
    public static let upload_info_other_error = APIMonitorCodeFaceLiveness(code: 10017, level: OPMonitorLevelError, message: "upload_info_other_error")

    /// 获取活体检测票据接口其他异常
    public static let get_user_ticket_error = APIMonitorCodeFaceLiveness(code: 10018, level: OPMonitorLevelError, message: "get_user_ticket_error")

    /// 录入要素请求后端参数非法
    public static let upload_info_param_error = APIMonitorCodeFaceLiveness(code: 10019, level: OPMonitorLevelError, message: "upload_info_param_error")

    /// 查询是否已认证请求后端参数非法
    public static let check_has_authed_param_error = APIMonitorCodeFaceLiveness(code: 10020, level: OPMonitorLevelError, message: "check_has_authed_param_error")

    // MARK: -------- Offline Verify - Check --------

    /// 「离线人脸比对」资源检测成功
    public static let offline_check_success = APIMonitorCodeFaceLiveness(code: 10030, level: OPMonitorLevelNormal, message: "offline_check_success")
    
    /// 「离线人脸比对」资源检测失败：其它错误
    public static let offline_check_other_error = APIMonitorCodeFaceLiveness(code: 10031, level: OPMonitorLevelError, message: "offline_check_other_error")

    /// 「离线人脸比对」资源检测失败：模型文件未下载
    public static let offline_check_not_downloaded = APIMonitorCodeFaceLiveness(code: 10032, level: OPMonitorLevelNormal, message: "offline_check_not_downloaded")
    
    /// 「离线人脸比对」资源检测失败：模型文件不完整
    public static let offline_check_no_model = APIMonitorCodeFaceLiveness(code: 10033, level: OPMonitorLevelWarn, message: "offline_check_no_model")
    
    /// 「离线人脸比对」资源检测失败：模型文件 MD5 校验失败
    public static let offline_check_md5_error = APIMonitorCodeFaceLiveness(code: 10034, level: OPMonitorLevelError, message: "offline_check_md5_error")
    
    // MARK: -------- Offline Verify - Prepare --------
    
    /// 「离线人脸比对」预处理（资源下载）成功
    public static let offline_prepare_success = APIMonitorCodeFaceLiveness(code: 10040, level: OPMonitorLevelNormal, message: "offline_prepare_success")
    
    /// 「离线人脸比对」预处理（资源下载）失败：其它错误
    public static let offline_prepare_other_error = APIMonitorCodeFaceLiveness(code: 10041, level: OPMonitorLevelError, message: "offline_prepare_other_error")
    
    /// 「离线人脸比对」预处理（资源下载）失败：下载失败
    public static let offline_prepare_download_failed = APIMonitorCodeFaceLiveness(code: 10042, level: OPMonitorLevelError, message: "offline_prepare_download_failed")
    
    /// 「离线人脸比对」预处理（资源下载）失败：无需下载
    public static let offline_prepare_not_needed = APIMonitorCodeFaceLiveness(code: 10043, level: OPMonitorLevelNormal, message: "offline_prepare_not_needed")
    
    /// 「离线人脸比对」预处理（资源下载）失败：下载超时
    public static let offline_prepare_timeout = APIMonitorCodeFaceLiveness(code: 10044, level: OPMonitorLevelWarn, message: "offline_prepare_timeout")
    
    // MARK: -------- Offline Verify - Verify --------
    
    /// 「离线人脸比对」人脸比对成功
    public static let offline_verify_success = APIMonitorCodeFaceLiveness(code: 10050, level: OPMonitorLevelNormal, message: "offline_verify_success")
    
    /// 「离线人脸比对」人脸比对失败：其它错误
    public static let offline_verify_other_error = APIMonitorCodeFaceLiveness(code: 10051, level: OPMonitorLevelNormal, message: "offline_verify_other_error")

    /// 「离线人脸比对」人脸比对失败：基准图读取失败
    public static let offline_verify_img_read_failed = APIMonitorCodeFaceLiveness(code: 10052, level: OPMonitorLevelError, message: "offline_verify_img_read_failed")

    /// 「离线人脸比对」人脸比对失败：静默活体初始化失败
    public static let offline_verify_liveness_init_error = APIMonitorCodeFaceLiveness(code: 10053, level: OPMonitorLevelError, message: "offline_verify_liveness_init_error")
    
    /// 「离线人脸比对」人脸比对失败：静默活体未通过
    public static let offline_verify_liveness_failed = APIMonitorCodeFaceLiveness(code: 10054, level: OPMonitorLevelWarn, message: "offline_verify_liveness_failed")
    
    /// 「离线人脸比对」人脸比对失败：初始化失败
    public static let offline_verify_compare_init_failed = APIMonitorCodeFaceLiveness(code: 10055, level: OPMonitorLevelError, message: "offline_verify_compare_init_failed")
    
    /// 「离线人脸比对」人脸比对失败：比对未通过
    public static let offline_verify_compare_failed = APIMonitorCodeFaceLiveness(code: 10056, level: OPMonitorLevelWarn, message: "offline_verify_compare_failed")

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: APIMonitorCodeFaceLiveness.domain, code: code, level: level, message: message)
    }

    public static let domain = "client.open_platform.api.face_liveness"
}
