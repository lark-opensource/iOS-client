import Foundation
import LarkSetting

public class Quaterback: NSObject {

    public static let shared = Quaterback()

    override init() {
        super.init()
    }

    func configFg(fg: FeatureGatingService) {}

    // 同步的方式拉取内容，仅安全模式调用
    public func syncFetchBandages() {}

}
