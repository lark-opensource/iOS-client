import Foundation

/// 设备工具类
@objcMembers
public final class BDPDeviceTool: NSObject {

    // 备注：此代码未修改任何相关逻辑，仅从原先头条代码换了个位置改成了swift版本，以确保swift那边拿到的是 optional string类型，避免crash
    /// 应用短版本
    public static let bundleShortVersion: String? = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String

}
