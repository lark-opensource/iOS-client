//
//  ByteViewPreload.swift
//  ByteViewMod
//
//  Created by kiri on 2022/1/6.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import ByteViewTracker
import LarkRustClient
import ByteView
import ByteViewUI
import LarkContainer
import LarkMedia
import ByteViewSetting
#if HybridMod
import ByteViewHybrid
#endif

@objc(LarkByteViewPreloader)
final class LarkByteViewPreloader: NSObject {

    static let launchTime = Date()

    @objc static func didFinishLaunch() {
        #if DEBUG
        // swiftlint:disable inert_defer
        let startTime = CACurrentMediaTime()
        defer {
            let duration = round((CACurrentMediaTime() - startTime) * 1e6) / 1e3
            Logger.monitor.info("LarkByteViewPreloader(didFinishLaunch) duration: \(duration)ms")
        }
        // swiftlint:enable inert_defer
        #endif
        _ = launchTime
        HttpClient.setupDependency(NetworkDependencyImpl())
        VCTracker.setupDependency(TrackDependencyImpl())
        UIDependencyManager.setupDependency(LarkUIDependency.shared)
        #if HybridMod
        LynxManager.setDependency {
            try? Container.shared.getUserResolver(userID: $0).resolve(assert: LynxDependency.self)
        }
        #endif
    }

    @objc static func afterFirstRender() {
        #if DEBUG
        // swiftlint:disable inert_defer
        let startTime = CACurrentMediaTime()
        defer {
            let duration = round((CACurrentMediaTime() - startTime) * 1e6) / 1e3
            Logger.monitor.info("LarkByteViewPreloader(afterFirstRender) duration: \(duration)ms")
        }
        // swiftlint:enable inert_defer
        #endif
        LarkAudioSession.setup {
            LarkAudioSession.shared.hookAudioSession()
            LarkAudioSession.activateNotification()
            LarkAudioSession.setupTrackDependency(AudioSessionTrackDependency.shared)
        }
    }
}

private class AudioSessionTrackDependency: LarkMedia.TrackDependency {
    static let shared = AudioSessionTrackDependency()
    func trackEvent(event: String, params: [AnyHashable: Any]) {
        guard let event = DevTrackEvent.Audio(rawValue: event), let p = params as? [String: Any] else { return }
        DevTracker.post(.audio(event).params(TrackParams(p)).category(.audio))
    }
}
