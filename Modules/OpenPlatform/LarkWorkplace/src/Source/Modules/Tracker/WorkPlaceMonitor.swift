//
//  WPMonitor.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2021/3/2.
//

import LarkOPInterface
import SwiftyJSON
import OPFoundation
import LarkContainer
import Foundation
import ECOProbeMeta

/// 工作台埋点通用事件名
private let kWPMonitorName = "op_workplace_event"

enum MonitorResultType {
    case success([String: Any]? = nil)
    case fail(Error? = nil)
    case cancel
    case timeout
    case other(String)

    var value: String {
        switch self {
        case .success:
            return "success"
        case .fail:
            return "fail"
        case .cancel:
            return "cancel"
        case .timeout:
            return "timeout"
        case .other(let detail):
            return detail
        }
    }
}

/// 工作台埋点监控 - OPMonitor 上层封装
final class WPMonitor {

    private let opMonitor = OPMonitor(kWPMonitorName)

    // TODO: 网络状态后续统一迁移，不再依赖 OPNetStatusHelper
    private var netStatusService: OPNetStatusHelper {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: WorkplaceScope.userScopeCompatibleMode)
        let status = try? userResolver.resolve(assert: OPNetStatusHelper.self)
        return status ?? OPNetStatusHelper()
    }

    // MARK: - OPMonitor 逻辑封装

    init(_ code: WPMCode? = nil) {
        _ = opMonitor.setMonitorCode(code)
    }

    /// 设置 Code
    @discardableResult
    func setCode(_ code: OPMonitorCodeProtocol) -> WPMonitor {
        _ = opMonitor.setMonitorCode(code)
        return self
    }

    /// 设置 Result
    @discardableResult
    func setResult(_ type: MonitorResultType) -> WPMonitor {
        switch type {
        case .success(let info):
            _ = opMonitor.setResultTypeSuccess()
            if let info = info {
                for (key, value) in info {
                    _ = opMonitor.addCategoryValue(key, value)
                }
            }
        case .fail(let err):
            _ = opMonitor.setResultTypeFail().setError(err)
        case .cancel:
            _ = opMonitor.setResultTypeCancel()
        case .timeout:
            _ = opMonitor.setResultTypeTimeout()
        case .other(let detail):
            _ = opMonitor.setResultType(detail)
        }
        return self
    }

    /// 设置 Info
    @discardableResult
    func setInfo(_ info: [String: Any]) -> WPMonitor {
        for (key, value) in info {
            _ = opMonitor.addCategoryValue(key, value)
        }
        return self
    }

    /// 设置 Info
    @discardableResult
    func setInfo(_ value: Any?, key: String) -> WPMonitor {
        _ = opMonitor.addCategoryValue(key, value)
        return self
    }

    /// 设置 Error
    @discardableResult
    func setError(_ error: Error) -> WPMonitor {
        _ = opMonitor.setError(error)
        return self
    }

    /// 设置 Trace ( trace_id )
    @discardableResult
    func setTrace(_ trace: OPTraceProtocol?) -> WPMonitor {
        _ = opMonitor.tracing(trace)
        return self
    }

    /// 设置 Timing
    @discardableResult
    func timing() -> WPMonitor {
        _ = opMonitor.timing()
        return self
    }

    @discardableResult
    func setMetrics(_ key: String, _ value: Any?) -> WPMonitor {
        _ = opMonitor.addMetricValue(key, value)
        return self
    }

    /// 上报
    func flush(
        fileName: String = #fileID,
        functionName: String = #function,
        line: Int = #line
    ) {
        opMonitor.flush(fileName: fileName, functionName: functionName, line: line)
    }

    // MARK: - convenience funcs

    /// 获取两次 timing 之间的 duration
    var duration: Int? {
        guard let dict = opMonitor.metrics, let value = dict[OPMonitorEventKey.duration] else {
            return nil
        }
        return value as? Int
    }

    /// 设置 Error
    @discardableResult
    func setError(errMsg: String = "", error: Error? = nil) -> WPMonitor {
        if let err = error {
            setError(err)
        }
        if !errMsg.isEmpty {
            setInfo(["error_msg": errMsg])
        }
        return self
    }

    func setNetworkStatus() -> WPMonitor {
        opMonitor.addCategoryValue("net_status", netStatusService.status.rawValue)
        return self
    }

    func setTemplateResultFail(error: WorkplaceError) -> WPMonitor {
        opMonitor.addCategoryValue("error_code", error.code)
        opMonitor.addCategoryValue("http_code", error.httpCode)
        opMonitor.addCategoryValue("error_message", error.errorMessage)
        if let serverCode = error.serverCode {
            opMonitor.addCategoryValue("server_error", serverCode)
        }
        opMonitor.setResultTypeFail()
        return self
    }

    /// 上报失败埋点（若上报过，则本次不上报）
    func postFailMonitor(
        endTiming: Bool = false,
        fileName: String = #fileID,
        functionName: String = #function,
        line: Int = #line
    ) {
        if endTiming {
            timing()
        }
        setResult(.fail()).flush(fileName: fileName, functionName: functionName, line: line)
    }

    /// 上报成功埋点（若上报过，则本次不上报）
    func postSuccessMonitor(
        endTiming: Bool = false,
        fileName: String = #fileID,
        functionName: String = #function,
        line: Int = #line
    ) {
        if endTiming {
            timing()
        }
        setResult(.success()).flush(fileName: fileName, functionName: functionName, line: line)
    }
}

/// widget渲染上报属性
extension WPMonitor {
    /// 设置widget标示
    @discardableResult
    func setWidgetTag(appName: String, appId: String?, widgetVersion: String?) -> WPMonitor {
        _ = opMonitor.addCategoryValue("app_id", widgetVersion)
            .addCategoryValue("app_name", appName)
            .addCategoryValue("widget_version", widgetVersion)
        return self
    }
    /// 设置渲染时长
    @discardableResult
    func setRenderCost(costTime: Int) -> WPMonitor {
        _ = opMonitor.addCategoryValue("renderEnd", costTime)
        return self
    }
}

// 工作台 Monitor Code 全部收敛到 ECOProbeMeta
typealias WPMCode = EPMClientOpenPlatformAppCenterEventCode
typealias WPMWorkplaceCode = EPMClientOpenPlatformAppCenterWorkplaceCode
typealias WPMApplinkCode = EPMClientOpenPlatformAppCenterApplinkCode

extension OPMonitorCodeBase {
    // 变量命名不带下划线，业务考虑优化
    // swiftlint:disable identifier_name
    /// 将 OPMonitorCodeBase 转换为 OPMonitorCode，兼容一些旧逻辑
    var wp_mCode: OPMonitorCode {
        OPMonitorCode(domain: domain, code: code, level: level, message: message)
    }
    // swiftlint:enable identifier_name
}

// 工作台自用的一些 trace 埋点，未与其他端对齐
extension EPMClientOpenPlatformAppCenterEventCode {
    // swiftlint:disable identifier_name
    /// Block 相关事件埋点
    static let workplace_block_trace = OPMonitorCodeBase(
        domain: domain,
        code: -50_000,
        level: OPMonitorLevelNormal,
        message: "workplace_block_trace"
    )

    // MARK: - 工作台通用错误码（适用于尚未与各端对齐，但是需要上报的情况）

    /// 内部错误 unknown
    static let workplace_internal_error = OPMonitorCodeBase(
        domain: domain,
        code: -50_001,
        level: OPMonitorLevelError,
        message: "workplace_internal_error"
    )

    /// 客户端网络请求错误（服务端未正确响应）
    static let workplace_network_error = OPMonitorCodeBase(
        domain: domain,
        code: -50_002,
        level: OPMonitorLevelError,
        message: "workplace_network_error"
    )

    /// 服务端 code 非 0 报错
    static let workplace_server_error = OPMonitorCodeBase(
        domain: domain,
        code: -50_003,
        level: OPMonitorLevelError,
        message: "workplace_server_error"
    )

    /// JSON 编码异常
    static let workplace_json_encode_error = OPMonitorCodeBase(
        domain: domain,
        code: -50_004,
        level: OPMonitorLevelError,
        message: "workplace_json_encode_error"
    )

    /// JSON 解码异常
    static let workplace_json_decode_error = OPMonitorCodeBase(
        domain: domain,
        code: -50_005,
        level: OPMonitorLevelError,
        message: "workplace_json_decode_error"
    )
    // swiftlint:enable identifier_name
}

extension OPError {
    /// 工作台内部逻辑处理发生的一些异常错误
    static func wp_internal(
        _ msg: String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) -> OPError {
        return OPError.error(
            monitorCode: WPMCode.workplace_internal_error.wp_mCode,
            message: msg,
            filename: file,
            function: function,
            line: line
        )
    }

    /// 通过网络库返回的 Erro 创建 OPError
    static func wp_network(
        _ error: Error,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) -> OPError {
        return OPError.error(
            monitorCode: WPMCode.workplace_network_error.wp_mCode,
            message: "\(error)",
            filename: file,
            function: function,
            line: line
        )
    }

    /// 根据服务端返回 Code 返回 Error，如果 code 为 0 则返回 nil
    static func wp_serverCode(
        response: JSON,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) -> OPError? {
        if response["code"].int == 0 {
            return nil
        } else {
            return OPError.error(
                monitorCode: WPMCode.workplace_server_error.wp_mCode,
                message: "\(response)",
                filename: file,
                function: function,
                line: line
            )
        }
    }

    /// 通过 JSON Encode Error 创建 OPError
    static func wp_jsonEncode(
        _ error: Error,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) -> OPError {
        return OPError.error(
            monitorCode: WPMCode.workplace_json_encode_error.wp_mCode,
            message: "\(error)",
            filename: file,
            function: function,
            line: line
        )
    }

    /// 通过 JSON Decode Error 创建 OPError
    static func wp_jsonDecode(
        _ error: Error,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) -> OPError {
        return OPError.error(
            monitorCode: WPMCode.workplace_json_decode_error.wp_mCode,
            message: "\(error)",
            filename: file,
            function: function,
            line: line
        )
    }
}
