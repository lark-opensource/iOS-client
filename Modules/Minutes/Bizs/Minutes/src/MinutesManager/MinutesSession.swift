//
//  MinutesSession.swift
//  Minutes
//
//  Created by 陈乐辉 on 2023/10/30.
//

import Foundation
import MinutesFoundation
import MinutesNetwork
import LarkContainer

protocol MinutesSessionListener {
    func willEnterMinutes(_ session: MinutesSession)
    func willLeaveMinutes(_ session: MinutesSession)
}

extension MinutesSessionListener {
    func willEnterMinutes(_ session: MinutesSession) {}
    func willLeaveMinutes(_ session: MinutesSession) {}
}

final class MinutesSession {
    lazy var sessionId: ObjectIdentifier = { ObjectIdentifier(self) }()
    let minutes: Minutes
    var player: MinutesVideoPlayer {
        if let player = _player {
            return player
        } else {
            let player = MinutesVideoPlayer(resolver: userResolver, minutes: minutes)
            _player = player
            return player
        }
    }
    let viewContext: MinutesViewContext
    let tracker: MinutesTracker
    let userResolver: UserResolver
    var resolver: MinutesViewModelResolver { container.resolver }
    let type: MinutesShowType

    private let container: MinutesViewModelContainer
    private var _player: MinutesVideoPlayer?

    var source: MinutesSource?
    var destination: MinutesDestination?
    var recordingSource: MinutesAudioRecordingSource?
    var topic: String = ""

    private let listeners = MulticastListener<MinutesSessionListener>()

    init(minutes: Minutes, userResolver: UserResolver, type: MinutesShowType, player: MinutesVideoPlayer?) {
        self.minutes = minutes
        self.viewContext = MinutesViewContext()
        self.container = MinutesViewModelContainer(minutes: minutes)
        self.container.resolveNonLazyObjects()
        self.userResolver = userResolver
        self._player = player
        self.tracker = MinutesTracker(minutes: minutes)
        self.type = type
    }

    deinit {
        MinutesLogger.common.info("minutes session deinit")
    }

    func addListener(_ listener: MinutesSessionListener) {
        listeners.addListener(listener)
    }

    func willEnterMinutes() {
        MinutesLogger.common.info("will enter minutes: \(minutes.objectToken), type: \(type)")
        listeners.invokeListeners { [weak self] listener in
            guard let self = self else { return }
            listener.willEnterMinutes(self)
        }
    }

    func willLeaveMinutes() {
        MinutesLogger.common.info("will leave minutes: \(minutes.objectToken), type: \(type)")
        listeners.invokeListeners { [weak self] listener in
            guard let self = self else { return }
            listener.willLeaveMinutes(self)
        }
    }
}


final class MinutesViewContext {

    init() {
    }
}
