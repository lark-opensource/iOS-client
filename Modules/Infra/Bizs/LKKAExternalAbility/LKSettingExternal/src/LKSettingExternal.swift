import Foundation
@objc
public protocol KASettingProtocol: AnyObject {
  /// 获取 config
  /// - Parameters:
  ///   - key: isv key
  ///   - space: isv space
  /// - Returns: 远端配置
  func getConfig(space: String, key: String) -> [String: Any]
}

@objcMembers
public class KASettingExternal: NSObject {
    public override init() {
        super.init()
    }
    
    public static let shared = KASettingExternal()
    public var settings: KASettingProtocol?
}

