//
//  AudioAssembly.swift
//  LarkAudio
//
//  Created by 李晨 on 2019/4/16.
//

import Foundation
import LarkContainer
import RxSwift
import RxCocoa
import Swinject
import LarkModel
import LarkSDKInterface
import LarkMessengerInterface
import AppContainer
import LarkAccountInterface
import LarkRustClient
import LarkAssembler

public protocol AudioDependency {
    func byteViewIsRinging() -> Bool
    func byteViewHasCurrentModule() -> Bool
    func byteViewInRingingCannotCallVoIPText() -> String
    func byteViewIsInCallText() -> String
}

public final class AudioAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        let user = container.inObjectScope(.userV2)

        user.register(AudioPlayMediator.self) { r -> AudioPlayMediator in
            return AudioPlayMediatorImpl(userResolver: r, audioResourceService: try r.resolve(assert: AudioResourceService.self))
        }

        user.register(AudioResourceService.self) { (r) -> AudioResourceService in
            return AudioResourceManagerImpl(
                userResolver: r,
                resourceAPI: try r.resolve(assert: ResourceAPI.self),
                pushChannelMessage: try r.userPushCenter.observable(for: PushChannelMessage.self)
            )
        }

        user.register(NewAudioTracker.self) { r in
            return NewAudioTracker(userID: r.userID)
        }

        user.register(AudioRecordManager.self) { r in
            return AudioRecordManager(userResolver: r)
        }

        user.register(NewAudioRecordManager.self) { r in
            return NewAudioRecordManager(userResolver: r)
        }
    }

    public func registRustPushHandlerInUserSpace(container: Container) {
        (Command.pushDynamicNetStatus, NetStatusPushHandler.init(resolver:))
    }
}
