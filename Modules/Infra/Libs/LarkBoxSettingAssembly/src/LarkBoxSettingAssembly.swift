import Foundation
import Swinject
import BootManager
import LarkAssembler

public final class LarkBoxSettingAssembly: LarkAssemblyInterface {
    public init() {}

    public func registLaunch(container: Container) {
        NewBootManager.register(LarkBoxSettingTask.self)
    }
}