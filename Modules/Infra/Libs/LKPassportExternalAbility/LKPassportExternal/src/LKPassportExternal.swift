import Foundation
@objc
public protocol KAPassportProtocol: AnyObject {
    /// 获取飞书设备唯一表示
    /// - Returns: device id
    func getDeviceId() -> String
    /// 检查飞书当前用户的登录状态
    /// - Parameter onSuccess: 接口调用成功，block 返回值：登录态是否有效和额外说明
    /// - Parameter onFail: 接口调用成功，block 返回值：失败原因
    func checkLarkStatus(onSuccess: @escaping (Bool, String?) -> Void, onFail: @escaping(String) -> Void)
}

@objcMembers
public class LKPassportExternal: NSObject {
    public override init() {
        super.init()
    }
    public static let shared = LKPassportExternal()
    public var passport: KAPassportProtocol?
}
