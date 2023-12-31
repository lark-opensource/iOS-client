import Foundation
import BootManager
import LarkSetting

final class LarkQuaterbackTask: FlowBootTask, Identifiable { // Global
    static var identify = "LarkQuaterbackTask"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        _ = Quaterback.shared
    }
}


final class LarkQuaterbackFGTask: UserFlowBootTask, Identifiable {
    static var identify = "LarkQuaterbackFGTask"

    override func execute(_ context: BootContext) {
        Quaterback.shared.configFg(fg: userResolver.fg)
    }
}
