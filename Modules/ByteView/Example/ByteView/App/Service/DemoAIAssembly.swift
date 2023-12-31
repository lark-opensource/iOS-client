//
//  DemoAIAssembly.swift
//  ByteView_Example
//
//  Created by kiri on 2023/11/21.
//

#if canImport(LarkAIInfra) && !canImport(LarkAI)
import Foundation
import LarkAssembler
import Swinject
import LarkContainer
import LarkAIInfra
import RxRelay
import EENavigator

final class DemoAIAssembly: LarkAssemblyInterface {
    init() {}

    func registContainer(container: Container) {
        let user = container.inObjectScope(.userV2)
        user.register(DemoMyAIService.self) { _ in
            DemoMyAIService()
        }
        user.register(MyAIInfoService.self) {
            try $0.resolve(assert: DemoMyAIService.self)
        }
        user.register(MyAIExtensionService.self) {
            try $0.resolve(assert: DemoMyAIService.self)
        }
    }
}

private final class DemoMyAIService: MyAIInfoService, MyAIExtensionService {
    var canOpenOthersAIProfile: Bool = false
    var enable: BehaviorRelay<Bool> = .init(value: false)
    var info: BehaviorRelay<MyAIInfo> = .init(value: .init(id: "", name: "myai", avatarKey: "", avatarImage: nil))
    var defaultResource: LarkAIInfra.MyAIResource = .init(name: "myai", iconSmall: UIImage(), iconLarge: UIImage())
    func openMyAIProfile(from: NavigatorFrom) {
    }

    var selectedExtension: BehaviorRelay<MyAIExtensionCallBackInfo> = .init(value: .default)
}

#endif
