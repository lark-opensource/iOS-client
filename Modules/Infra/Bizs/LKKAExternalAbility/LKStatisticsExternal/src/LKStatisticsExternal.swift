import Foundation
@objc
public protocol KAStatisticsProtocol: AnyObject {
    /// 配置，用于初始化统计组件
    func initConfig(appId: String, registerHost: String, appLogHost: String, commonParams: [String: AnyHashable])
    /// 埋点
    /// - Parameter name: 事件名称
    func sendEvent(name: String)
    /// 埋点
    /// - Parameters:
    ///   - name: 事件名称
    ///   - params: 事件参数
    func sendEvent(name: String, params: [String: String])
}

@objcMembers
public class KAStatisticsExternal: NSObject {
    public override init() {
        super.init()
    }
    
    public static let shared = KAStatisticsExternal()
    public var statistics: KAStatisticsProtocol?
}

