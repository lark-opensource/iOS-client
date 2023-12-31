import Foundation
@objc
public protocol KAPassportOperationProtocol: AnyObject {
    /// 登出飞书账号
    func logoutFeiShu()
}

@objcMembers
public class KAPassportOperationExternal: NSObject {
    public override init() {
        super.init()
    }
    
    public static let shared = KAPassportOperationExternal()
    public var passportOperator: KAPassportOperationProtocol?
}

