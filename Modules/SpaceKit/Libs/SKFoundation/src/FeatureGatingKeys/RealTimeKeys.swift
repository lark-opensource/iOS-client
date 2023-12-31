//⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️
//仅PM有“高实时性”等特殊要求才可以使用，客户端内每次读可能都不一样，并且要保证不可以前端客户端一起使用，否则会导致前端和客户端在两个时刻取到不一样value的问题。⚠️⚠️⚠️避免误用导致线上问题。未了解real-time运行机制请不要使用 请阅读 https://bytedance.feishu.cn/docx/doxcnJ7dzCiiqRxTi7yc9Jhebxe
//⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️
import LarkSetting
public final class RealTimeFG {
    // 按研发人员名称做scope，避免每次提交代码的时候FG文件冲突导致的反复rebase
    /// yinyuan.0
    public final class YY {
    }
    
    /// wujiasheng.token
    public final class WJS {
    }
    
    /// xiongmin.super
    public final class XM {
    }
    
    /// zhangyushan.s
    public final class XYS {
    }
    
    /// zengsenyuan
    public final class ZSY {
    }
    
    /// zoujie.andy
    public final class ZJ {
    }

    /// wuwenjian.weston
    enum WWJ {
    }

    /// liujinwei
    public final class LJW {
        ///mindnote离线创建
        public static var mindnoteOfflineCreateEnable: Bool {
            fg("ccm.mobile.mindnote_offline_create_enable")
        }
    }

#if DEBUG
    // mock fg使用，仅在单元测试场景进行 mock，非单元测试请直接使用主端基建的mock界面
    static var mockValues = [String: Bool]()
#endif
}
#if DEBUG
//这里的方法请不要改public，引入SKFoundation的时候请使用 @testable import SKFoundation
extension RealTimeFG {
    // 设置mock的fg
    class func setMockFG(key: String, value: Bool) {
        mockValues[key] = value
    }
    // 移除mock的fg
    class func removeMockFG(key: String) {
        mockValues.removeValue(forKey: key)
    }
    // 移除所有mock的fg
    class func clearAllMockFG() {
        mockValues.removeAll()
    }
    fileprivate class func mockFG(key: String) -> Bool? {
        mockValues[key]
    }
}
#endif
// MARK: - 工具方法
private func fg(_ key: LarkSetting.FeatureGatingManager.Key) -> Bool {
#if DEBUG
    if let mockValue = RealTimeFG.mockFG(key: key.rawValue) {
        DocsLogger.info("RealTimeFG use mock value, key:\(key) value:\(mockValue)")
        return mockValue
    }
#endif
    return FeatureGatingManager.realTimeManager.featureGatingValue(with: key)
}
