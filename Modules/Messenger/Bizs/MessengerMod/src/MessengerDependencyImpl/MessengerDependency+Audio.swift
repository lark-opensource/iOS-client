//
//  MessengerMockDependency+Audio.swift
//  LarkMessenger
//
//  Created by 李晨 on 2021/7/29.
//

import Foundation
import LarkAudio
import Swinject
import LarkContainer
#if ByteViewMod
import ByteViewInterface
#endif

public final class AudioDependencyImpl: AudioDependency {

    private let resolver: UserResolver

    public init(resolver: UserResolver) {
        self.resolver = resolver
    }

    public func byteViewIsRinging() -> Bool {
        #if ByteViewMod
        (try? resolver.resolve(assert: MeetingService.self))?.currentMeeting?.state == .ringing
        #else
        false
        #endif
    }

    public func byteViewHasCurrentModule() -> Bool {
        #if ByteViewMod
        (try? resolver.resolve(assert: MeetingService.self))?.currentMeeting?.isActive == true
        #else
        false
        #endif
    }

    public func byteViewInRingingCannotCallVoIPText() -> String {
        #if ByteViewMod
        (try? resolver.resolve(assert: MeetingService.self))?.resources.inRingingCannotCallVoIP ?? ""
        #else
        ""
        #endif
    }

    public func byteViewIsInCallText() -> String {
        #if ByteViewMod
        (try? resolver.resolve(assert: MeetingService.self))?.resources.isInCallText ?? ""
        #else
        ""
        #endif
    }
}
