//
//  ExtensionUpdateTask.swift
//  LarkBaseService
//
//  Created by KT on 2020/7/8.
//

import Foundation
import BootManager
import LarkAccountInterface
import LarkContainer

final class ExtensionUpdateTask: UserFlowBootTask, Identifiable {
    static var identify = "ExtensionUpdateTask"

    override func execute(_ context: BootContext) {
        Container.shared.resolve(ExtensionConfigDelegate.self)! // Global
            .updateShareExtension()
    }
}
