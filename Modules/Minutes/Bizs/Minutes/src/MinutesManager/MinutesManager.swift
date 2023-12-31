//
//  MinutesManager.swift
//  Minutes
//
//  Created by 陈乐辉 on 2023/10/30.
//

import Foundation
import MinutesNetwork

final class MinutesManager {
    static let shared = MinutesManager()

    private init() {
    }

    var sessions: [ObjectIdentifier: MinutesSession] = [:]

    func enterDetailOrPodcast(with params: MinutesShowParams, forceToPodcast: Bool = false) -> UIViewController {
        var minutes = params.minutes
        var player = MinutesPodcastSuspendable.currentPlayer()
        if let podcastMinutes = MinutesPodcast.shared.minutes, podcastMinutes.baseURL == minutes.baseURL {
            minutes = podcastMinutes
        }
        if player?.minutes !== minutes {
            player = nil
        }
        let type: MinutesShowType = (MinutesPodcast.shared.isInPodcast || forceToPodcast) ? .podcast : .detail
        let newParams = MinutesShowParams(minutes: minutes, userResolver: params.userResolver, player: player, source: params.source, destination: params.destination)
        return startMinutes(with: type, params: newParams)
    }

    func startMinutes(with type: MinutesShowType, params: MinutesShowParams) -> UIViewController {
        let viewController: UIViewController
        let session = createSession(with: params, type: type)
        switch type {
            case .detail, .clip:
                viewController = createDetailController(with: session)
            case .podcast:
                viewController = createPodcastController(with: session)
            case .record:
                viewController = createRecordController(with: session)
            case .preview:
                viewController = createAudioPreviewControler(with: session)
        }
        return viewController
    }

    private func createSession(with params: MinutesShowParams, type: MinutesShowType) -> MinutesSession {
        let session = MinutesSession(minutes: params.minutes, userResolver: params.userResolver, type: type, player: params.player)
        session.source = params.source
        session.destination = params.destination
        session.recordingSource = params.recordingSource
        session.topic = params.topic
        sessions[session.sessionId] = session
        session.addListener(self)
        session.willEnterMinutes()
        return session
    }

    private func createDetailController(with session: MinutesSession) -> UIViewController {
        MinutesDetailReciableTracker.shared.startEnterDetail()
        let viewController = MinutesContainerViewController(session: session)
        viewController.hidesBottomBarWhenPushed = true
        MinutesDetailReciableTracker.shared.finishPreProcess()
        return viewController
    }

    private func createPodcastController(with session: MinutesSession) -> UIViewController {
        MinutesPodcastReciableTracker.shared.startEnterPodcast()
        MinutesPodcast.shared.startPodcast(for: session.minutes, player: session.player, resolver: session.userResolver)
        let viewController = MinutesPodcastViewController(session: session)
        viewController.hidesBottomBarWhenPushed = true
        MinutesPodcastReciableTracker.shared.finishPreProcess()
        return viewController
    }

    private func createRecordController(with session: MinutesSession) -> UIViewController {
        let viewController = MinutesAudioRecordingController(session: session)
        return viewController
    }

    private func createAudioPreviewControler(with session: MinutesSession) -> UIViewController {
        let viewController = MinutesAudioPreviewController(session: session)
        return viewController
    }

}

extension MinutesManager: MinutesSessionListener {

    func willLeaveMinutes(_ session: MinutesSession) {
        let key = session.sessionId
        sessions.removeValue(forKey: key)
    }
}
