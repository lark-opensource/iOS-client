import Foundation
import Swinject
import BootManager
import LarkAssembler

public final class LarkQuaterbackAssembly: LarkAssemblyInterface {

    public init() { }

    public func registLaunch(container: Container) {
        NewBootManager.register(LarkQuaterbackTask.self)
        NewBootManager.register(LarkQuaterbackFGTask.self)
    }
}
