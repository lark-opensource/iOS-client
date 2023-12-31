//
//  CommonMonitorCode.swift
//  Timor
//
//  Created by houjihu on 2020/5/3.
//

import Foundation
import LarkOPInterface
import OPFoundation

/// 通用 Monitor ID 定义
/// - 修改请先修改 [统一定义文档](https://bytedance.feishu.cn/sheets/shtcnCCboz4CUWBUtZkdmZV0PLb?table=tblhdeAY8y&view=vewDYgteNU#ve29xQ)

/// 小程序包加载
@objcMembers
public final class CommonMonitorCodePackage: OPMonitorCode {

    /// pkg下载不合法的参数
    static public let pkg_download_invalid_params = CommonMonitorCodePackage(code: 10000, level: OPMonitorLevelError, message: "pkg_download_invalid_params")
    /// pkg下载成功
    static public let pkg_download_success = CommonMonitorCodePackage(code: 10001, level: OPMonitorLevelNormal, message: "pkg_download_success")
    /// pkg下载失败
    static public let pkg_download_failed = CommonMonitorCodePackage(code: 10002, level: OPMonitorLevelError, message: "pkg_download_failed")
    /// pkg下载取消
    static public let pkg_download_canceled = CommonMonitorCodePackage(code: 10003, level: OPMonitorLevelWarn, message: "pkg_download_canceled")
    /// 无pkg下载URL
    static public let pkg_download_no_url = CommonMonitorCodePackage(code: 10004, level: OPMonitorLevelError, message: "pkg_download_no_url")
    /// pkgmd5检验失败
    static public let pkg_download_md5_verified_failed = CommonMonitorCodePackage(code: 10005, level: OPMonitorLevelError, message: "pkg_download_md5_verified_failed")
    /// 删除下载文件失败(包括下载完成文件和下载中的文件)
    static public let pkg_delete_file_failed = CommonMonitorCodePackage(code: 10006, level: OPMonitorLevelError, message: "pkg_delete_file_failed")
    /// 下载过程中发生写入数据异常
    static public let pkg_write_file_failed = CommonMonitorCodePackage(code: 10007, level: OPMonitorLevelError, message: "pkg_write_file_failed")
    /// 文件重命名失败
    static public let pkg_rename_failed = CommonMonitorCodePackage(code: 10008, level: OPMonitorLevelError, message: "pkg_rename_failed")
    /// 服务器端因为某种原因关闭了Connection (Android专用)
    static public let pkg_download_tcp_connection_reset = CommonMonitorCodePackage(code: 10009, level: OPMonitorLevelError, message: "pkg_download_tcp_connection_reset")
    /// pkg安装不合法的参数
    static public let pkg_install_invalid_params = CommonMonitorCodePackage(code: 10010, level: OPMonitorLevelError, message: "pkg_install_invalid_params")
    /// pkg描述标记校验失败
    static public let pkg_mask_verified_failed = CommonMonitorCodePackage(code: 10011, level: OPMonitorLevelError, message: "pkg_mask_verified_failed")
    /// pkg安装成功
    static public let pkg_install_success = CommonMonitorCodePackage(code: 10012, level: OPMonitorLevelNormal, message: "pkg_install_success")
    /// pkg安装失败
    static public let pkg_install_failed = CommonMonitorCodePackage(code: 10013, level: OPMonitorLevelError, message: "pkg_install_failed")
    /// 找不到Pkg内的指定文件(默认事件)
    static public let pkg_file_not_found = CommonMonitorCodePackage(code: 10014, level: OPMonitorLevelError, message: "pkg_file_not_found")
    /// 加载Pkg数据出错（默认事件）
    static public let pkg_read_data_failed = CommonMonitorCodePackage(code: 10015, level: OPMonitorLevelError, message: "pkg_read_data_failed")
    /// 加载Pkg数据超时(非请求超时, 而是api调用耗时过长)
    static public let pkg_read_timeout = CommonMonitorCodePackage(code: 10016, level: OPMonitorLevelError, message: "pkg_read_timeout")
    /// 创建pkg相关目录或文件失败
    static public let pkg_create_file_failed = CommonMonitorCodePackage(code: 10017, level: OPMonitorLevelError, message: "pkg_create_file_failed")
    /// pkg版本太低
    static public let pkg_version_too_old = CommonMonitorCodePackage(code: 10018, level: OPMonitorLevelError, message: "pkg_version_too_old")
    /// 安装包不存在（包括下载包和安装包）
    static public let pkg_not_found = CommonMonitorCodePackage(code: 10019, level: OPMonitorLevelError, message: "pkg_not_found")


    private init(code: Int, level:  OPMonitorLevel, message: String) {
        super.init(domain: CommonMonitorCodePackage.domain, code: code, level: level, message: message)
    }

    static public let domain = CommonMonitorCode.domain + ".package"
}


/// 通用Meta加载
@objcMembers
public final class CommonMonitorCodeMeta: OPMonitorCode {
    /// 不合法的参数
    public static let invalid_params = CommonMonitorCodeMeta(code: 10000, level: OPMonitorLevelError, message: "invalid_params")
    /// 网络请求异常
    public static let meta_request_error = CommonMonitorCodeMeta(code: 10001, level: OPMonitorLevelError, message: "meta_request_error")
    /// meta参数加解密失败
    public static let meta_encrypt_decrypt_failed = CommonMonitorCodeMeta(code: 10002, level: OPMonitorLevelError, message: "meta_encrypt_decrypt_failed")
    /// meta请求响应服务器返回error非0
    public static let meta_server_error = CommonMonitorCodeMeta(code: 10003, level: OPMonitorLevelError, message: "meta_server_error")
    /// 响应数据无法解析
    public static let meta_response_invalid = CommonMonitorCodeMeta(code: 10004, level: OPMonitorLevelError, message: "meta_response_invalid")
    /// meta请求成功
    public static let meta_request_success = CommonMonitorCodeMeta(code: 10005, level: OPMonitorLevelNormal, message: "meta_request_success")
    /// meta db错误
    public static let meta_db_error = CommonMonitorCodeMeta(code: 10007, level: OPMonitorLevelError, message: "meta_db_error")
    /// 应用Meta响应不可见，由于权限问题用户没有Meta的可见性
        public static let meta_response_invisible = CommonMonitorCodeMeta(code: 10009, level: OPMonitorLevelError, message: "meta_response_invisible")
    /// Meta不存在，应用在租户下未安装或者不存在小程序能力
    public static let meta_response_not_exist = CommonMonitorCodeMeta(code: 10010, level: OPMonitorLevelError, message: "meta_response_not_exist")
    /// 用户的session信息不正确，无法正常获取到应用Meta
    public static let meta_response_session_error = CommonMonitorCodeMeta(code: 10011, level: OPMonitorLevelError, message: "meta_response_session_error")
    /// 请求Meta信息接口服务端报错
    public static let meta_response_internal_error = CommonMonitorCodeMeta(code: 10012, level: OPMonitorLevelError, message: "meta_response_internal_error")

    private init(code: Int, level:  OPMonitorLevel, message: String) {
        super.init(domain: CommonMonitorCodeMeta.domain, code: code, level: level, message: message)
    }
    public static let domain = CommonMonitorCode.domain + ".meta"
}

/// 大组件加载
@objcMembers
public final class CommonMonitorCodeComponent: OPMonitorCode {
    /// 组件数据格式不对，无法正常解析
    public static let invalid_component_content = CommonMonitorCodeComponent(code: 10000, level: OPMonitorLevelError, message: "invalid_component_content")
    /// 移除本地组件失败
    public static let remove_component_failed = CommonMonitorCodeComponent(code: 10001, level: OPMonitorLevelError, message: "remove_component_failed")
    /// 要下载的组件信息不存在
    public static let no_component_to_download = CommonMonitorCodeComponent(code: 10002, level: OPMonitorLevelError, message: "no_component_to_download")
    /// md5 校验结果不一致
    public static let component_download_md5_verify_failed = CommonMonitorCodeComponent(code: 10003, level: OPMonitorLevelError, message: "component_download_md5_verify_failed")
    /// 组件的 meta data 写入失败
    public static let component_meta_write_failed = CommonMonitorCodeComponent(code: 10004, level: OPMonitorLevelError, message: "component_meta_write_failed")
    /// 组件的 meta data 读取失败
    public static let component_meta_read_failed = CommonMonitorCodeComponent(code: 10004, level: OPMonitorLevelError, message: "component_meta_read_failed")
    /// 组件安装失败
    public static let component_install_failed = CommonMonitorCodeComponent(code: 10005, level: OPMonitorLevelError, message: "component_install_failed")
    /// 组件安装成功
    public static let component_install_success = CommonMonitorCodeComponent(code: 10006, level: OPMonitorLevelNormal, message: "component_install_success")
    /// 组件下载失败
    public static let component_download_failed = CommonMonitorCodeComponent(code: 10007, level: OPMonitorLevelError, message: "component_download_failed")
    /// 组件下载成功
    public static let component_download_success = CommonMonitorCodeComponent(code: 10008, level: OPMonitorLevelNormal, message: "component_download_success")
    /// 组件 URL 格式不对
    public static let invalid_component_url = CommonMonitorCodeComponent(code: 10009, level: OPMonitorLevelError, message: "invalid_component_url")

    private init(code: Int, level:  OPMonitorLevel, message: String) {
        super.init(domain: CommonMonitorCodeComponent.domain, code: code, level: level, message: message)
    }
    public static let domain = CommonMonitorCode.domain + ".component"
}
