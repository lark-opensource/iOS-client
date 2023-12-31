//
//  InMeetDebugViewModel.swift
//  ByteView
//
//  Created by kiri on 2021/5/17.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

#if DEBUG
final class InMeetDebugViewModel {
    init(meeting: InMeetMeeting) {
        Self.increment()
    }

    deinit {
        Self.decrement()
    }

    private static var instanceCount: Int = 0
    private static let instanceLock = NSLock()

    static func increment() {
        Self.instanceLock.lock()
        defer {
            Self.instanceLock.unlock()
        }
        Self.instanceCount += 1

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            Self.instanceLock.lock()
            defer {
                Self.instanceLock.unlock()
            }
            assert(Self.instanceCount <= 1, "InMeetViewModel is leaked!")
        }
    }

    static func decrement() {
        Self.instanceLock.lock()
        defer {
            Self.instanceLock.unlock()
        }
        Self.instanceCount -= 1
    }
}
#endif
