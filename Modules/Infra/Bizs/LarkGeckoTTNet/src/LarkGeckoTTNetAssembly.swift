import Foundation
import Swinject
import BootManager
import LarkAssembler
import AppContainer
import LarkSetting
import class IESGeckoKit.IESGurdTTDownloader
import IESGeckoKit.IESGeckoKit
import OpenCombine
import OpenCombineDispatch
import LarkEnv

public final class LarkGeckoTTNetAssembly:LarkAssemblyInterface {
    public init() {}

    public func registLaunch(container: Container) {
        NewBootManager.register(LarkGeckoTTNetTask.self)
    }

    public func registContainer(container: Container) {
        container.register(LarkGeckoTTNetSettingsObserver.self) { _ in
            LarkGeckoTTNetSettingsObserver()
        }.inObjectScope(.container)
    }
}

final class LarkGeckoTTNetTask: FlowBootTask, Identifiable {
    static var identify = "LarkGeckoTTNetTask"

    override func execute(_ context: BootContext) {
        guard let observer = BootLoader.container.resolve(LarkGeckoTTNetSettingsObserver.self) else {
            return
        }
        observer.start()
    }
}
private var cancelBag = Set<AnyCancellable>()
fileprivate struct LarkGeckoTTNetSettingsObserver {
    private let serialQueue = DispatchQueue(label: "com.LarkGeckoTTNetSettingsObserver.workQueue")
    func start() {
        if EnvManager.env.isStaging {
            return
        }
        update()
        FeatureGatingManager.realTimeManager.fgCombineSubjectPublisher.receive(on: serialQueue.ocombine).sink { _ in
            update()
        }.store(in: &cancelBag)
    }
    
    func update() {
        let ttnetEnable = FeatureGatingManager.realTimeManager.featureGatingValue(with: "lark.core.gecko.with.ttnet")
        IESGurdTTDownloader.setEnable(ttnetEnable)
        guard ttnetEnable else {
            IESGurdKit.networkDelegate = nil
            return
        }
        guard (IESGurdKit.networkDelegate as? LarkGeckoTTNetDelegate) == nil else {
            return
        }
        IESGurdKit.networkDelegate = LarkGeckoTTNetDelegate()
    }
}
