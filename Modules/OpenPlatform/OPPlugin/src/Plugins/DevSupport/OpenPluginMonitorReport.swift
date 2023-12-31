//
//  OpenPluginMonitorReport.swift
//  OPPlugin
//
//  Created by  窦坚 on 2021/5/31.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import LarkOPInterface
import OPPluginManagerAdapter
import ECOProbe
import ECOInfra
import LKCommonsLogging
import LarkFeatureGating
import LarkSetting
import LarkContainer
import TTMicroApp

final class OpenPluginMonitorReport: OpenBasePlugin {
    
    private lazy var disableTraceFlush: Bool = {
        userResolver.fg.dynamicFeatureGatingValue(with: "openplatform.infra.monitorreport.trace.disable")
    }()
    
    /**
     调用方法
     ```
     const opManager = tt.opmonitor ? tt.opmonitor() : null;
     console.log(`monitorReport opManager: ${opManager}`);
     const code = {
         domain: "op_domain_1",
         code: 10000,
         level: 1,
         message: "just for opmonitor message",
     };
     if (opManager) {
         const categorys = {};
         const trace = tt.getTraceInfo();
         opManager.report("op_biz_event_trace", code, categorys, trace);
     }
     ```
     对于 reportParmas 中的参数
     如果 value为number
     进入  metrics
     否则
     进入 categories
     ```
     {
        "name": "op_biz_event", //固定的
        "metrics": {
            "monitor_code": "code.code"
        },
        "categories": {
            "biz_event_name": "op_bitable_char_envet",
            "monitor_domain": "code.domin",
            "monitor_id": "code.ID",
            "monitor_message": "code.message"
        }
     }
     ```
     
     */
    func monitorReport(params: OpenAPIMonitorReportParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        
        // H5 应用接口同时对业务暴露，增加 FG 控制保障安全
        if (gadgetContext.uniqueID.appType == OPAppType.webApp && EMAFeatureGating.boolValue(forKey: EEFeatureGatingKeyGadgetWebAppApiMonitorReport)) {
            context.apiTrace.warn("monitorReport unavailable for web app")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
            callback(.failure(error: error))
            return
        }
        
        pr_monitorReport(
            params: params,
            context: context,
            callback: callback) {
                name, metrics, categories in
                OPMonitor(name: name, metrics: metrics, categories: categories)
                    .setUniqueID(gadgetContext.uniqueID)
            }
    }
    
    func monitorReport(
        params: OpenAPIMonitorReportParams,
        context: OpenAPIContext,
        monitorReportExtension: OpenAPIMonitorReportExtension,
        callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void)
    {
        let commonExtension = monitorReportExtension.commonExtension
        guard !monitorReportExtension.apiDisable() else {
            let errMsg = "monitorReport extension unavailable"
            context.apiTrace.warn(errMsg)
            let error = OpenAPIError(errno: OpenAPICommonErrno.unable).setMonitorMessage(errMsg)
            callback(.failure(error: error))
            return
        }
        
        pr_monitorReport(
            params: params,
            context: context,
            callback: callback) {
                name, metrics, categories in
                commonExtension.monitor(name, metrics: metrics, categories: categories)
            }
    }
    
    func pr_monitorReport(
        params: OpenAPIMonitorReportParams,
        context: OpenAPIContext,
        callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void,
        monitorBlock: (String, [AnyHashable: Any]?, [AnyHashable: Any]?) -> OPMonitor)
    {
        // 遍历 flush monitorEvent
        for monitorEvent in params.monitorEvents {
            // 如果 monitorEvent 作为 dic 为空，则跳过
            if (monitorEvent.count == 0) {
                context.apiTrace.warn("invalid monitorEvent \(monitorEvent)")
                continue
            }
            // 检查 monitorEvent["name"] 参数
            if let name = monitorEvent["name"] as? String {
                // 获取参数
                let metrics = monitorEvent["metrics"] as? [AnyHashable: Any]
                let categories = monitorEvent["categories"] as? [AnyHashable: Any]
                let monitor = monitorBlock(name, metrics, categories)
                if let platform = monitorEvent["platform"] as? String {
                    switch platform {
                    case kMonitorReportPlatformSlardar:
                        monitor.setPlatform(.slardar)
                    case kMonitorReportPlatformTea:
                        monitor.setPlatform(.tea)
                    case kMonitorReportPlatformTeaSlardar:
                        monitor.setPlatform([.tea, .slardar])
                    default:
                        break
                    }
                }
                let monitorData = mergedMonitorData(metrics: metrics, categories: categories)
                // .trace 级别不上报只打印日志
                let monitorLevel = OPMonitorLevel.opMonitorReportLevel(from: monitorData)
                let logger = MonitorReportLog(monitorEventName: name,
                                              monitorData: monitorData,
                                              logger: context.apiTrace)
                logger.log()
                // level 只上报
                if monitorLevel?.rawValue == OPMonitorLevel.trace.rawValue {
                    context.apiTrace.info("trace only log")
                    if disableTraceFlush {
                        continue
                    } else {
                        monitor.setLevel(.trace)
                    }
                }
                monitor.flush()
            } else {
                // 当「monitorEvent["name"] 为 nil || monitorEvent["name"] 不为 String」时，暴露错误状况
                context.apiTrace.warn("monitorReport fail! Element[\"name\"] in params.monitorEvents is invalid!")
            }
        }
        // 调用成功
        callback(.success(data: nil))
    }
    
    func mergedMonitorData(metrics: [AnyHashable: Any]?, categories: [AnyHashable: Any]?)-> [AnyHashable: Any] {
        let metrics = metrics ?? [:]
        let categories = categories ?? [:]
        let data: [AnyHashable: Any] = (metrics).merging(categories) { $1 }
        return data
    }
    
    static let apiName = "monitorReport"
    
    @FeatureGatingValue(key: "openplatform.api.pluginmanager.extension.enable")
    var apiExtensionEnable: Bool
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        if apiExtensionEnable {
            registerAsync(for: Self.apiName, registerInfo: .init(pluginType: Self.self, paramsType: OpenAPIMonitorReportParams.self), extensionInfo: .init(type: OpenAPIMonitorReportExtension.self, defaultCanBeUsed: true)) {
                Self.monitorReport($0)
            }
        } else {
            registerInstanceAsyncHandlerGadget(
                for: Self.apiName,
                pluginType: Self.self,
                paramsType: OpenAPIMonitorReportParams.self,
                resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
                
                this.monitorReport(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
            }
        }
    }
}



enum OPMonitorReportEventKey: String {
    case monitorLevel = "monitor_level"
    case monitorFile = "monitor_file"
    case monitorFunction = "monitor_function"
    case monitorLine = "monitor_line"
}

extension OPMonitorLevel {
    
    static func opMonitorReportLevel(from data: [AnyHashable: Any]) -> OPMonitorLevel? {
        guard let levelValue = data[OPMonitorReportEventKey.monitorLevel.rawValue] as? UInt else {
            return nil
        }
        return OPMonitorLevel(rawValue: levelValue)
    }
    
    func logLevel() -> LogLevel {
        switch self.rawValue {
        case OPMonitorLevelTrace.rawValue:
            return .info
        case OPMonitorLevelNormal.rawValue:
            return .info
        case OPMonitorLevelWarn.rawValue:
            return .warn
        case OPMonitorLevelError.rawValue:
            return .error
        case OPMonitorLevelFatal.rawValue:
            return .fatal
        default:
            return .info
        }
    }
}
extension Dictionary {
    fileprivate var jsonString: String {
        let data = self;
        let result: String
        if JSONSerialization.isValidJSONObject(data) { // 判断是否能转换为JSON数据
            do {
                let data = try JSONSerialization.data(withJSONObject: data)
                result = String(data: data, encoding: .utf8) ?? ""
            } catch {
                result = ""
            }
        } else {
            result = ""
        }
        return result
    }
}
struct MonitorReportLog {
    let level: LogLevel
    let message: String
    let filePath: String
    let function: String
    let line: Int
    let logger: Log
    
    init(monitorEventName name: String,  monitorData data: [AnyHashable : Any], logger: Log) {
        let monitorLevel = OPMonitorLevel.opMonitorReportLevel(from: data ) ?? .normal
        let logLevel = monitorLevel.logLevel()
        let filePath = data[OPMonitorReportEventKey.monitorFile.rawValue] as? String ?? ""
        let funcName = data[OPMonitorReportEventKey.monitorFunction.rawValue] as? String ?? ""
        let line = data[OPMonitorReportEventKey.monitorLine.rawValue] as? Int ?? -1
        let dataJSONString: String = data.jsonString
        let logMessage = "monitorEvent:" + name + "," + "data:" + dataJSONString
        
        self.message = logMessage
        self.level = logLevel
        self.filePath = filePath
        self.function = funcName
        self.line = line
        self.logger = logger
    }
    
    func log() {
        logger.log(level: level,
                   message,
                   file: filePath,
                   function: function,
                   line: line)
    }
}
