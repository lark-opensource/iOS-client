//
//  LiveDependencyImpl.swift
//  LarkByteView
//
//  Created by kiri on 2021/7/2.
//

import Foundation
import ByteView
import ByteViewCommon
import LarkLiveInterface
import LarkContainer

final class LiveDependencyImpl: LiveDependency {
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    private var liveService: LarkLiveService? {
        do {
            return try userResolver.resolve(assert: LarkLiveService.self)
        } catch {
            Logger.dependency.error("resolve LarkLiveService failed, \(error)")
            return nil
        }
    }

    var isLiving: Bool {
        liveService?.isLiving() ?? false
    }

    func stopLive() {
        liveService?.startVoip()
    }

    func trackFloatWindow(isConfirm: Bool) {
        liveService?.trackFloatWindow(isConfirm: isConfirm)
    }
}
