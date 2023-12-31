//
//  VCCalendarAssembly.swift
//  ByteViewMod
//
//  Created by kiri on 2023/6/21.
//

import Foundation
import Swinject
import LarkAssembler
import ByteViewCalendar
import LarkContainer

final class VCCalendarAssembly: LarkAssemblyInterface {
    func registContainer(container: Container) {
        let user = container.inObjectScope(.vcUser)
        user.register(ByteViewCalendarDependency.self) {
            ByteViewCalendarDependencyImpl(userResolver: $0)
        }
    }

    func getSubAssemblies() -> [LarkAssemblyInterface]? {
        ByteViewCalendarAssembly()
    }
}
