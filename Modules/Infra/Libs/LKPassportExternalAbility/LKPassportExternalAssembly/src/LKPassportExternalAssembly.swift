import Foundation
import LarkAssembler
import LarkContainer
import LKPassportExternal
import AppContainer
import BootManager

public class LKPassportExternalAssembly: LarkAssemblyInterface {
    public init() {
      
    }
    
    public func registLaunch(container: Container) {
      NewBootManager.register(SetupPassportTask.self)
    }
}

final class SetupPassportTask: UserFlowBootTask, Identifiable {
    static var identify: TaskIdentify {
        "SetupPassportTask"
    }

    override var runOnlyOnce: Bool {
        true
    }

    override func execute(_ context: BootContext) {        
        LKPassportExternal.shared.passport = try? userResolver.resolve(type: KAPassportProtocol.self)
    }
}


