import Foundation
@objc
public protocol KAQRCodeApiDelegate: AnyObject {
    /// 飞书扫码逻辑之前调用
    /// - Parameter result: 扫码结果
    /// - Returns: 是否承载本次扫码结果
    func interceptHandle(result: String) -> Bool
    /// 飞书扫码逻辑处理之后调用
    /// - Parameter result: 扫码结果
    /// - Returns: 是否承载本次扫码结果
    func handle(result: String) -> Bool
}

@objcMembers
public class KAQRCodeApiExternal: NSObject {
    public override init() {
        super.init()
    }
    public static let shared = KAQRCodeApiExternal()
    public var delegates: [KAQRCodeApiDelegate] = []
    public func addHandler(_ handler: KAQRCodeApiDelegate) {
        print("KA---Watch: start add handler")
        delegates.append(handler)
    }
}
