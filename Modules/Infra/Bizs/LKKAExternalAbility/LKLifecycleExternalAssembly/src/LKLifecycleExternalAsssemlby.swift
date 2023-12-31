import Foundation
import LarkAssembler
import LarkContainer
import LarkAccountInterface

public class LKLifecycleExternalAssembly: LarkAssemblyInterface {
    public init() {
        LKLifecycleExternal.startApp()
    }

    public func registContainer(container: Container) {
        container.register(LKLifecycleExternal.self) { _ in
            LKLifecycleExternal()
        }.inObjectScope(.container)
    }

    public func registLauncherDelegate(container: Container) {
        (LauncherDelegateFactory {
            KALifecycleExternalLauncherDelegate()
        }, LauncherDelegateRegisteryPriority.middle)
    }
}
