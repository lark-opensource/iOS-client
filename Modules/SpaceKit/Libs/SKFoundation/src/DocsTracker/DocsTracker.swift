//  Created by Songwen Ding on 2018/1/17.

import Foundation
import CryptoSwift

public final class DocsTracker: NSObject, StatisticsServcie {

    public static let shared = DocsTracker()
    public var handler: ((_ event: String, _ parameters: [AnyHashable: Any]?, _ category: String?, _ shouldAddPrefix: Bool) -> Void)?

    public struct ForbiddenTrackerReason: OptionSet {
        public let rawValue: Int
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        public static let useSystemProxy = ForbiddenTrackerReason(rawValue: 1 << 0)
        public static let useProxyToAgent = ForbiddenTrackerReason(rawValue: 1 << 1)
        public static let none: ForbiddenTrackerReason = []
    }

    public var matchSuccHanlder: ( (String) -> Void)?
    public var deviceid: String?
    public var forbiddenTrackerReason: ForbiddenTrackerReason = .none

    static let lock = NSLock()

    /// 仅供前端/后端使用，其他模块不要使用，以后前后端不会在我们这里注册事件，只是传递字符串
    #warning ("从4.2版本开始废弃使用旧接口进行埋点，后续埋点前缀需要大家自己填写，旧逻辑还是走这里加前缀,故不能删除此处逻辑,只能加一个警告,各位同学使用的时候请注意。")
    /// 旧接口，默认会帮大家加上前缀docs_
    public class func log(event: String, parameters: [AnyHashable: Any]?, category: String? = nil, shouldAddPrefix: Bool = true) {
        log(event, parameters: parameters, category: category, shouldAddPrefix: shouldAddPrefix)
    }
    /// 新接口，并不会帮大家加上前缀
    public class func newLog(event: String, parameters: [AnyHashable: Any]?, category: String? = nil) {
        log(event, parameters: parameters, category: category, shouldAddPrefix: false)
    }

    /// 加密
    public class func encrypt(id: String) -> String {
        let md5str = "ee".md5()
        let prefix = md5str[md5str.startIndex..<md5str.index(md5str.startIndex, offsetBy: 6)]
        let subfix = md5str[md5str.index(md5str.endIndex, offsetBy: -6)..<md5str.endIndex]
        let uniqueID = (String(prefix) + (id + String(subfix)).md5()).sha1()
        return uniqueID
    }

    /// 耗时埋点记录开始
    public class func startRecordTimeConsuming(eventType: DocsTrackerEventType, parameters: [String: Any]?, subType: String = "") {
        lock.lock()
        defer { lock.unlock() }

        let eventKey = eventType.stringValue + subType
        costTime[eventKey] = getCurrentTime()
        uploadParameters[eventKey] = parameters
    }

    /// 耗时埋点记录结束
    public class func endRecordTimeConsuming(eventType: DocsTrackerEventType, parameters: [String: Any]?, subType: String = "") {
        lock.lock()
        defer { lock.unlock() }

        let eventKey = eventType.stringValue + subType
        guard let cost = self.costTime[eventKey] else {
            DocsLogger.warning("\(eventKey) endRecordTimeConsuming no costTime")
            return 
        }
        let costTime = 1000 * (getCurrentTime() - cost)

        var allParames: [String: Any] = ["cost_time": costTime]
        if let uploadParameter = self.uploadParameters[eventKey] {
            allParames.merge(other: uploadParameter)
        }
        allParames.merge(other: parameters)
        DocsTracker.log(enumEvent: eventType, parameters: allParames)
        self.costTime[eventKey] = nil
    }
}

extension DocsTracker {
    /// 埋点上报Bool值会要求转成string
    public static func toString(value: Bool?) -> String {
        return value == true ? "true" : "false"
    }
}

public extension StatisticsServcie {
    /// 使用枚举值打点
    #warning ("从4.2版本开始废弃使用旧接口进行埋点，后续埋点前缀需要大家自己填写，旧逻辑还是走这里加前缀,故不能删除此处逻辑,只能加一个警告,各位同学使用的时候请注意。")
    /// 旧接口，默认会帮大家加上前缀docs_
    static func log(enumEvent: DocsTrackerEventType, parameters: [AnyHashable: Any]?) {
        Self.log(event: enumEvent.stringValue, parameters: parameters, category: nil, shouldAddPrefix: enumEvent.shouldAddPrefix)
    }

    /// 新接口，并不会帮大家加上前缀
    static func newLog(enumEvent: DocsTrackerEventType, parameters: [AnyHashable: Any]?) {
        Self.newLog(event: enumEvent.stringValue, parameters: parameters, category: nil)
    }
}

extension DocsTracker {
    private static var costTime: Dictionary = [String: Double]()
    private static var uploadParameters = [String: [String: Any]]()

    private class func getCurrentTime() -> Double {
        return Date().timeIntervalSince1970
    }
}

// PRIVATE METHOD
extension DocsTracker {
    class var versionType: String? {
        if SKFoundationConfig.shared.isForQATest {
            return "forQA"
        } else {
            return nil
        }
    }
    /// DEBUG 环境不上报
    private class func log(_ event: String, parameters: [AnyHashable: Any]?, category: String?, shouldAddPrefix: Bool) {

        #if OpenTrackerLog
        if let params = parameters as? [String: Any] {
            DocsLogger.info(event, extraInfo: params, error: nil, component: "DOCS_TEST_TRACKER_LOG ")
        } else {
            DocsLogger.info(event, extraInfo: nil, error: nil, component: "DOCS_TEST_TRACKER_LOG ")
        }
        #endif

        #if DEBUG
        if let params = parameters as? [String: Any] {
            //如果业务带了参数params不合法，例如value是枚举，会中断言，请检查你的参数
            spaceAssert(JSONSerialization.isValidJSONObject(params))
            DocsLogger.debug(event, extraInfo: params, error: nil, component: LogComponents.tracker)
            let nonSensitiveToken = params[DocsTracker.Params.nonSensitiveToken] as? Bool ?? false
            if !nonSensitiveToken {
                SecurityInfoChecker.shared.checkTracker(params)
            }
        } else {
            DocsLogger.debug(event, extraInfo: nil, error: nil, component: LogComponents.tracker)
        }
        #else
        DocsLogger.info(event, component: LogComponents.tracker)
        #endif

        #if DEBUG
        let enableTrack = SKFoundationConfig.shared.isBeingTest
        #else
        let enableTrack = true
        #endif
        guard enableTrack else {
            return
        }
        if DocsTracker.shared.forbiddenTrackerReason != .none {
            DocsLogger.info("forbidden=\(DocsTracker.shared.forbiddenTrackerReason.rawValue)", component: LogComponents.tracker)
            return
        }
        var param = parameters
        spaceAssert(parameters?["version_type"] == nil)
        if parameters?["version_type"] != nil {
            DocsLogger.error("raw versionType is not nil!, event is \(event)")
        }
        param?["version_type"] = versionType
        param?[DocsTracker.Params.nonSensitiveToken] = nil
        DocsTracker.shared.handler?(event, param, category, shouldAddPrefix)
        errorLogIfNeeded(event, parameters: param)

    }

    private class func errorLogIfNeeded(_ event: String, parameters: [AnyHashable: Any]?) {
//        if let params = parameters as? [String: Any],
//            let deviceid = DocsTracker.shared.deviceid,
//            let matchItem = eventMatchs?.first(where: { $0.isMatch(event, params: params)}),
//            Double(arc4random_uniform(100)) / 100.0 < matchItem.probability {
//            var extraInfo = params
//            extraInfo.updateValue(deviceid, forKey: "docs_deviceid")
//            extraInfo.updateValue(matchItem.failName, forKey: "failReasion")
//            DispatchQueue.main.once {
//                DocsLogger.error("需要上报日志\(matchItem.failName)", extraInfo: extraInfo, error: nil, component: nil)
//                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 10) {
//                    DocsTracker.shared.matchSuccHanlder?(matchItem.failName)
//                }
//            }
//        }
    }
}
