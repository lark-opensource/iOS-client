import BootManager
import AppContainer
import Swinject
import LarkLocalizations
import LarkContainer
import RunloopTools
import LKLoadable
import LarkAssembler

class LarkMainAssembly: FlowBootTask, Identifiable { // Global
    static var identify = "LarkMainAssembly"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        let assemblies: [LarkAssemblyInterface] = [
            BaseAssembly()
        ]
        _ = Assembler(assemblies: assemblies, container: BootLoader.container)
        BootLoader.assemblyLoaded = true
    }
}

func excute() {
    // 设置语言
    LanguageManager.setCurrent(language: .zh_CN, isSystem: false)

    LKLoadableManager.run(appMain)

    NewBootManager.register(LarkMainAssembly.self)
    NewBootManager.register(InitIdleLoadTask.self)

    RunloopDispatcher.enable = true

    BootLoader.shared.start(delegate: AppDelegate.self, config: .default)

}

excute()
