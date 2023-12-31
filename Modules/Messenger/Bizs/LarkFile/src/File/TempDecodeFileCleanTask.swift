//
//  TempDecodeFileCleanTask.swift
//  LarkFile
//
//  Created by zc09v on 2022/6/9.
//

import Foundation
import BootManager
import LarkContainer
import LarkMessengerInterface

final class TempDecodeFileCleanTask: UserFlowBootTask, Identifiable {
    override class var compatibleMode: Bool { File.userScopeCompatibleMode }

    static var identify = "TempDecodeFileCleanTask"
    @ScopedInjectedLazy private var fileDecodeService: RustEncryptFileDecodeService?

    override var runOnlyOnceInUserScope: Bool { return false }

    override func execute(_ context: BootContext) {
        fileDecodeService?.clean(force: false)
    }
}
