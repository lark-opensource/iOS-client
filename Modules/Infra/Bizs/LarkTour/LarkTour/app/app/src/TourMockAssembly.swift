//
//  TourMockAssembly.swift
//  AFNetworking
//
//  Created by Meng on 2020/5/21.
//

import Foundation
import Swinject
import LarkTourInterface
import LarkTour
import EENavigator
// import LarkAppLinkSDK
import LarkUIKit

open class TourMockAssembly: Assembly {
    private var dependency: (Resolver) -> TourDependency

    public init(dependency: ((Resolver) -> TourDependency)? = nil) {
        self.dependency = dependency ?? { _ in return TourMockDependency() }
    }

    public func assemble(container: Container) {
        let dependency = self.dependency
        container.register(TourDependency.self) { _ -> TourDependency in
            return dependency(container)
        }

        container.register(TourFlowAPI.self) { _ -> TourFlowAPI in
            return TourFlowMockAPI()
        }.inObjectScope(.user)

//        LarkAppLinkSDK.registerHandler(path: "/client/mini_program/open", handler: { (applink: AppLink) in
//            Navigator.shared.present(FakeGadgetControler(), wrap: LkNavigationController.self)
//        })
    }
}
