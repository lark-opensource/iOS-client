//
//  GadgetRecoveryTintInfoService.swift
//  OPGadget
//
//  Created by liuyou on 2021/5/14.
//

import Foundation
import OPSDK
import TTMicroApp
import CryptoSwift
import LarkContainer
import LarkLocalizations

// 小程序异常恢复：https://bytedance.feishu.cn/wiki/wikcn6f8Qi1ewudxcO0MB3td1Me

/// 默认的DomainCode
private let DefaultMonitorDomainCode = "00"

private let AppDisplayNameTemplate = "{{APP_DISPLAY_NAME}}"
private let ErrorCodeTemplate = "{{ERROR_CODE}}"

/// 异常恢复类型
enum RecoveryExceptionType: CaseIterable {
    /// 小程序加载时的默认错误
    case loadingDefaultError
    /// 小程序运行时的默认错误
    case runningDefaultError
    /// 网络错误
    case networkingError
    /// 应用不存在
    case appNotExist
    /// 无权限访问应用
    case appNoPermission
    /// 登录状态异常
    case sessionInvalid
    /// 内存紧张
    case memoryLack
    /// 包异常
    case appPkgInvalid
    /// 包代码运行异常
    case appCodeRunningError
    /// JSSDK文件异常
    case JSSDKInvalid
    /// JSSDK文件代码运行异常
    case JSSDKCodeRunningError
    /// 应用元信息异常
    case gadgetMetaInvalid
    /// 环境不支持
    case environmentError
    /// 磁盘剩余空间不足
    case diskSpaceLack
    /// 预览版小程序已过期
    case previewExpire
    /// 客户端版本太低
    case clientVersionToLow
}

/// 一种异常恢复的物料信息
struct RecoveryExceptionMaterials {
    let typeCode: String    // 编码
    let tipContent: String  // 提示文案
    let monitorCodes: [OPMonitorCode]   // 哪些 Code 属于此类异常
}

extension RecoveryExceptionType {
    /// 定义了各种类型的错误到提示信息的映射
    /// 具体请见Doc：https://bytedance.feishu.cn/docs/doccnNhfRnJlkj79hUF7zeACsxe#
    var materials: RecoveryExceptionMaterials {
        switch self {
        case .loadingDefaultError:
            return RecoveryExceptionMaterials(
                typeCode: "A",
                tipContent: BDPI18n.openPlatform_GadgetErr_LoadFailToast,
                monitorCodes: [
                    GDMonitorCodeLaunch.app_state_cancel,
                    CommonMonitorCodePackage.pkg_download_invalid_params,
                    OPSDKMonitorCode.cancel,
                    CommonMonitorCodePackage.pkg_download_canceled,
                    GDMonitorCode.invalid_params
                ]
            )
        case .runningDefaultError:
            return RecoveryExceptionMaterials(
                typeCode: "B",
                tipContent: BDPI18n.openPlatform_GadgetErr_AppErrToast,
                monitorCodes: [
                    GDMonitorCode.js_running_thread_force_stopped
                ]
            )
        case .networkingError:
            return RecoveryExceptionMaterials(
                typeCode: "C",
                tipContent: BDPI18n.openPlatform_GadgetErr_NetworkErrToast,
                monitorCodes: [
                    GDMonitorCodeAppLoad.url_request_error,
                    GDMonitorCodeLaunch.network_not_connected,
                    CommonMonitorCodePackage.pkg_download_failed,
                    CommonMonitorCodePackage.pkg_download_md5_verified_failed,
                    CommonMonitorCodeMeta.meta_request_error,
                    OPSDKMonitorCode.timeout,
                    GDMonitorCodeLaunch.timeout
                ]
            )
        case .appNotExist:
            return RecoveryExceptionMaterials(
                typeCode: "D",
                tipContent: BDPI18n.openPlatform_GadgetErr_AppNotExistToast,
                monitorCodes: [
                    GDMonitorCodeLaunch.offline,
                    GDMonitorCodeLaunch.service_disabled,
                    CommonMonitorCodeMeta.meta_response_not_exist
                ]
            )
        case .appNoPermission:
            return RecoveryExceptionMaterials(
                typeCode: "E",
                tipContent: BDPI18n.openPlatform_GadgetErr_NoAuthToast,
                monitorCodes: [
                    GDMonitorCodeLaunch.no_permission,
                    CommonMonitorCodeMeta.meta_response_invisible
                ]
            )
        case .sessionInvalid:
            return RecoveryExceptionMaterials(
                typeCode: "F",
                tipContent: BDPI18n.openPlatform_GadgetErr_LoginStatusToast,
                monitorCodes: [
                    CommonMonitorCodeMeta.meta_response_session_error
                ]
            )
        case .memoryLack:
            return RecoveryExceptionMaterials(
                typeCode: "G",
                tipContent: BDPI18n.openPlatform_GadgetErr_DeviceStorageToast,
                monitorCodes: [
                    GDMonitorCode.webview_crash_overload
                ]
            )
        case .appPkgInvalid:
            return RecoveryExceptionMaterials(
                typeCode: "H",
                tipContent: BDPI18n.openPlatform_GadgetErr_AppResourceFailToast,
                monitorCodes: [
                    GDMonitorCode.load_app_service_script_error,
                    GDMonitorCodeAppLoad.pkg_data_parse_failed,
                    GDMonitorCodeAppLoad.pkg_data_failed,
                    GDMonitorCodeLaunch.download_fail
                ]
            )
        case .appCodeRunningError:
            return RecoveryExceptionMaterials(
                typeCode: "I",
                tipContent: BDPI18n.openPlatform_GadgetErr_AppRunErrToast,
                monitorCodes: [
                    GDMonitorCode.load_path_frame_script_error,
                    GDMonitorCode.load_page_frame_script_error
                ]
            )
        case .JSSDKInvalid:
            return RecoveryExceptionMaterials(
                typeCode: "J",
                tipContent: BDPI18n.openPlatform_GadgetErr_ResourceFailToast,
                monitorCodes: [
                    GDMonitorCode.jssdk_file_not_exist,
                    GDMonitorCode.navigation_delegate_did_fail,
                    GDMonitorCode.navigation_delegate_did_fail_provisional
                ]
            )
        case .JSSDKCodeRunningError:
            return RecoveryExceptionMaterials(
                typeCode: "K",
                tipContent: BDPI18n.openPlatform_GadgetErr_RunErrToast,
                monitorCodes: []
            )
        case .gadgetMetaInvalid:
            return RecoveryExceptionMaterials(
                typeCode: "L",
                tipContent: BDPI18n.openPlatform_GadgetErr_AppInfoErrToast,
                monitorCodes: [
                    CommonMonitorCodeMeta.meta_response_invalid,
                    CommonMonitorCodeMeta.meta_response_internal_error
                ]
            )
        case .environmentError:
            return RecoveryExceptionMaterials(
                typeCode: "M",
                tipContent: BDPI18n.openPlatform_GadgetErr_EnvNotSupportedToast,
                monitorCodes: [
                    GDMonitorCodeLaunch.environment_invalid,
                    GDMonitorCodeLaunch.device_unavailable,
                    GDMonitorCodeLaunch.entry_control_disabled,
                    GDMonitorCodeLaunch.orientation_landscape_unsupport,
                    GDMonitorCodeLaunch.orientation_portrait_unsupport
                ]
            )
        case .diskSpaceLack:
            return RecoveryExceptionMaterials(
                typeCode: "N",
                tipContent: BDPI18n.openPlatform_GadgetErr_StorageToast,
                monitorCodes: [
                    GDMonitorCodeAppLoad.write_data_failed,
                    CommonMonitorCodePackage.pkg_create_file_failed,
                    CommonMonitorCodePackage.pkg_write_file_failed
                ]
            )
        case .previewExpire:
            return RecoveryExceptionMaterials(
                typeCode: "O",
                tipContent: BDPI18n.openPlatform_GadgetErr_PreviewExpireToast,
                monitorCodes: [
                    GDMonitorCodeLaunch.preview_expired
                ]
            )
        case .clientVersionToLow:
            return RecoveryExceptionMaterials(
                typeCode: "P",
                tipContent: BDPI18n.openPlatform_GadgetErr_ClientVerTooLow,
                monitorCodes: [
                    GDMonitorCodeLaunch.jssdk_old,
                    GDMonitorCodeLaunch.incompatible,
                    GDMonitorCodeLaunch.lark_version_old
                ]
            )
        }
    }
}

struct UnifyExceptionStyle {
    enum UnifyExceptionStyleType: String {
        case errorPage = "page" // 发生错误时,展示错误页面
        case modal = "modal" // 发生错误时,展示模态弹窗
    }
    struct UnifyExceptionActions {
        enum UnifyExceptionAction: String {
            case restart = "restart"
            case none = "none"
        }
        struct UnifyExceptionButtonAction {
            public let actionText: String
            public let clickEvent: UnifyExceptionAction
        }
        let primaryButton: UnifyExceptionButtonAction?
        let cancelButton: UnifyExceptionButtonAction?
    }
    
    public let type: UnifyExceptionStyleType
    public let image: String
    public let title: String
    public let content: String
    public let actions: UnifyExceptionActions?
}

/// 获取提示文案的服务
struct GadgetRecoveryTipInfoService {

    /// 根据RecoveryContext获取用于提示用户的内容
    static func getTipContent(context: RecoveryContext) -> String {
        let opError = context.recoveryError

        // 匹配ExceptionType
        let recoveryExceptionType: RecoveryExceptionType
        if let _recoveryExceptionType = RecoveryExceptionType.allCases.first(where: { (recoveryExceptionType) -> Bool in
            recoveryExceptionType.materials.monitorCodes.contains { (monitorCode) -> Bool in
                monitorCode.id == opError.monitorCode.id
            }
        }) {
            recoveryExceptionType = _recoveryExceptionType
        } else {
            assertionFailure("出现未知的ErrorMonitorCode:\(opError.monitorCode.id)，请及时在这里定义其归属的异常类型，参考文档 https://bytedance.feishu.cn/wiki/wikcn6f8Qi1ewudxcO0MB3td1Me")
            // 出现未覆盖到的error时，将数据上报
            OPMonitor(GDMonitorCode.recovery_unknown_error)
                .addCategoryValue("unknown_error_monitor_code", opError.monitorCode.id)
                .setUniqueID(context.uniqueID)
                .setError(context.recoveryError)
                .flush()
            recoveryExceptionType =
            context.recoveryScene?.value == RecoveryScene.gadgetFailToLoad.value
            ? .loadingDefaultError
            : .runningDefaultError
        }
        
        // 错误类型编码
        let typeCode = recoveryExceptionType.materials.typeCode
        
        // domainCode编码
        let monitorDomainCode = getDomainCode(with: opError.monitorCode.domain)

        // monitorCode后三位
        let partialMonitorCode = String(format: "%03d", opError.monitorCode.code % 1000)
        
        // 错误码
        let errorCode = "\(typeCode)\(monitorDomainCode)\(partialMonitorCode)"

        // 提示信息
        let tipContent = recoveryExceptionType.materials.tipContent
        
        // 拼接提示内容
        let tipInfo = "\(tipContent) (\(BDPI18n.openPlatform_GadgetErr_ErrorCodeDesc ?? ""):\(errorCode))"

        return tipInfo
    }
    
    /// 根据RecoveryContext获取用于提示用户的内容
    static func getErrorContent(context: RecoveryContext) -> (errcode:String,tip:UnifyExceptionStyle?) {
        let opError = context.recoveryError

        // 在新的全局错误页面下,匹配ExceptionType仅获取当前的code(错误码之后也会重新统一),其余信息不会被使用
        let recoveryExceptionType: RecoveryExceptionType
        // 下方拼接错误码逻辑沿用之前的稳定的逻辑，代码暂不作修改
        if let _recoveryExceptionType = RecoveryExceptionType.allCases.first(where: { (recoveryExceptionType) -> Bool in
            recoveryExceptionType.materials.monitorCodes.contains { (monitorCode) -> Bool in
                monitorCode.id == opError.monitorCode.id
            }
        }) {
            recoveryExceptionType = _recoveryExceptionType
        } else {
            assertionFailure("出现未知的ErrorMonitorCode:\(opError.monitorCode.id)，请及时在这里定义其归属的异常类型，参考文档 https://bytedance.feishu.cn/wiki/wikcn6f8Qi1ewudxcO0MB3td1Me")
            // 出现未覆盖到的error时，将数据上报
            OPMonitor(GDMonitorCode.recovery_unknown_error)
                .addCategoryValue("unknown_error_monitor_code", opError.monitorCode.id)
                .setUniqueID(context.uniqueID)
                .setError(context.recoveryError)
                .flush()
            recoveryExceptionType =
            context.recoveryScene?.value == RecoveryScene.gadgetFailToLoad.value
            ? .loadingDefaultError
            : .runningDefaultError
        }
    
        // 错误码拼接逻辑暂时保持一致为 类型(1个大写字母),domain(两位数数字),错误码值(3位数字，从错误码code截取后3位)
        let typeCode = recoveryExceptionType.materials.typeCode
        let monitorDomainCode = getDomainCode(with: opError.monitorCode.domain)
        let partialMonitorCode = String(format: "%03d", opError.monitorCode.code % 1000)
        
        // 错误码
        let errorCode = "\(typeCode)\(monitorDomainCode)\(partialMonitorCode)"
        
        let unifyExceptionStyle = getErrorStyle(code: errorCode)

        return (errorCode,unifyExceptionStyle)
    }
    
    
    /// 获取错误码对应的错误展示配置
    /// - Parameter code: 出错的错误码
    /// - Returns: 错误码配置样式
    static func getErrorStyle(code:String) -> UnifyExceptionStyle? {
        // 配置 https://cloud.bytedance.net/appSettings-v2/detail/config/160289/detail/whitelist-detail/62169
        // 本地终极兜底
        let localDefaultAction = UnifyExceptionStyle.UnifyExceptionActions(
            primaryButton: UnifyExceptionStyle.UnifyExceptionActions.UnifyExceptionButtonAction(actionText: BDPI18n.retry, clickEvent: .restart),
            cancelButton: UnifyExceptionStyle.UnifyExceptionActions.UnifyExceptionButtonAction(actionText: BDPI18n.cancel, clickEvent: .none))
        let localTitle = BDPI18n.littleApp_ClientErrorCode_UnknownError.templateReplace(errorCode: code)
        let localContent = BDPI18n.littleApp_ClientErrorCode_AppErrorDesc.templateReplace(errorCode: code)
        let localDefaultStyle = UnifyExceptionStyle(type: .errorPage, image: "loadError", title: localTitle, content: localContent, actions:localDefaultAction)
        
        let monitor = OPMonitor(EPMClientOpenPlatformGadgetLaunchErrorUnifyCode.error_code_unrecorded).addCategoryValue("error_code", code)
        
        guard let config = getUnifyErrorConfig() else {
            monitor.addCategoryValue("error_msg", "missing config")
                .flush()
            return localDefaultStyle
        }
        
        guard let strategy = config["strategy"] as? Array<Dictionary<String,Any>> else {
            monitor.addCategoryValue("error_msg", "missing strategy")
                .flush()
            return localDefaultStyle
        }
        
        // 配置兜底
        var style = config["default_style"] as? String
        let foundStyle = strategy.first { ele in
            if let matchCodes = ele["error_codes"] as? Array<String>,matchCodes.contains(code) {
                style = ele["style"] as? String
                return true
            }
            return false
        }
        
        if foundStyle == nil {
            OPMonitor(EPMClientOpenPlatformGadgetLaunchErrorUnifyCode.error_code_unrecorded)
                .addCategoryValue("error_code", code)
                .addCategoryValue("error_msg", "missing current code style")
                .flush()
        }
        
        guard let _style = style, _style.count > 0, let styles = config["styles"] as? [String:Any] else {
            monitor.addCategoryValue("error_msg", "missing default style")
                .flush()
            return localDefaultStyle
        }
        
        if let matchStyle = styles[_style] as? [String:Any] {
            
            var styleActions : UnifyExceptionStyle.UnifyExceptionActions?
            
            if let actions = matchStyle["actions"] as? [String:Any] {
                
                var primaryButtonAction : UnifyExceptionStyle.UnifyExceptionActions.UnifyExceptionButtonAction?
                var cancelButtonAction : UnifyExceptionStyle.UnifyExceptionActions.UnifyExceptionButtonAction?
                
                if let primaryAction = actions["primary_btn"] as? [String:Any] {
                    // 解析行动点
                    let actionText = "\(primaryAction["action_text"] as? String ?? "")".templateReplace(errorCode: code)
                    let clickAction = primaryAction["onclick"] as? String ?? ""
                    
                    primaryButtonAction = UnifyExceptionStyle.UnifyExceptionActions.UnifyExceptionButtonAction(actionText: actionText, clickEvent: UnifyExceptionStyle.UnifyExceptionActions.UnifyExceptionAction(rawValue: clickAction) ?? .restart)
                }
                
                if let cancelAction = actions["cancel_btn"] as? [String:Any] {
                    // 解析行动点
                    let actionText = "\(cancelAction["action_text"] as? String ?? "")".templateReplace(errorCode: code)
                    let clickAction = cancelAction["onclick"] as? String ?? ""
                    
                    cancelButtonAction = UnifyExceptionStyle.UnifyExceptionActions.UnifyExceptionButtonAction(actionText: actionText, clickEvent: UnifyExceptionStyle.UnifyExceptionActions.UnifyExceptionAction(rawValue: clickAction) ?? .none)
                } else {
                    // 兜底的取消按钮
                    cancelButtonAction = UnifyExceptionStyle.UnifyExceptionActions.UnifyExceptionButtonAction(actionText: BDPI18n.cancel, clickEvent: .none)
                }
                
                styleActions = UnifyExceptionStyle.UnifyExceptionActions(primaryButton:primaryButtonAction,cancelButton: cancelButtonAction)
            }
            // 解析基础信息
            let type = UnifyExceptionStyle.UnifyExceptionStyleType(rawValue: matchStyle["type"] as? String ?? "") ?? .errorPage
            let image = matchStyle["image"] as? String ?? ""
            let title = "\(matchStyle["title"] as? String ?? "")".templateReplace(errorCode: code)
            let content = "\( matchStyle["content"] as? String ?? "")".templateReplace(errorCode: code)
            return UnifyExceptionStyle(type: type, image: image, title: title, content: content, actions: styleActions)
        }
        
        monitor.addCategoryValue("error_msg", "missing matched style")
            .flush()
        
        return localDefaultStyle
    }
    
    static private func getUnifyErrorConfig() -> [String:Any]? {
        // https://cloud.bytedance.net/appSettings-v2/detail/config/160289/detail/whitelist-detail/62169
        let configService = Injected<ECOConfigService>().wrappedValue
        return configService.getDictionaryValue(for: "gadget_error_page_config")
    }
    

    /// 获取某个Domain对应的ErrorDomainCode编码
    static private func getDomainCode(with monitorDomain: String) -> String {
        return GadgetRecoveryConfigProvider.gadgetRecoveryMonitorDomainCode(with: monitorDomain) ?? DefaultMonitorDomainCode
    }
}

extension String {
    func templateReplace(errorCode:String) -> String {
        return replacingOccurrences(of: ErrorCodeTemplate, with: "\(errorCode)").replacingOccurrences(of: AppDisplayNameTemplate, with: LanguageManager.bundleDisplayName)
    }
}
