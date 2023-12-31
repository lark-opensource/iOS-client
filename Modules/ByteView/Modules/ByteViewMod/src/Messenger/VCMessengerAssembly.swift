//
//  VCMessengerAssembly.swift
//  ByteViewMod
//
//  Created by kiri on 2021/10/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import Swinject
import ByteView
import ByteViewMessenger
import LarkAssembler
import ByteViewInterface
import LarkContainer

final class VCMessengerAssembly: LarkAssemblyInterface {
    func getSubAssemblies() -> [LarkAssemblyInterface]? {
        ByteViewMessengerAssembly()
    }

    func registContainer(container: Container) {
        let user = container.inObjectScope(.vcUser)
        user.register(ByteViewMessengerDependency.self) {
            ByteViewMessengerDependencyImpl(resolver: $0)
        }

        container.register(CustomRingtoneService.self) { _ in
            CustomRingtonePlayer()
        }
    }
}

extension CustomRingtonePlayer: CustomRingtoneService {}
