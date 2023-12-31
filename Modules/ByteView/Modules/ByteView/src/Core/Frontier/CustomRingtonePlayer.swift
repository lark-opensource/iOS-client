//
//  CustomRingtonePlayer.swift
//  ByteView
//
//  Created by kiri on 2023/6/2.
//

import Foundation
import LarkMedia
import ByteViewCommon
import ByteViewMeeting

public final class CustomRingtonePlayer {
    private lazy var logDescription = metadataDescription(of: self)

    public init() {
        logger.info("init \(self.logDescription)")
    }
    deinit {
        stopPlayRingtone()
        logger.info("deinit \(self.logDescription)")
    }

    private let logger = Logger.getLogger("NotifySetting")
    public func isPlayingRingtone() -> Bool {
        return RingPlayer.shared.isPlaying
    }

    public func playRingtone(url: URL?) {
        // 有会议场景，不播放铃声
        if MeetingManager.shared.currentSession != nil {
            logger.info("has active meeting, don`t play ringtone \(url)")
            return
        }

        let result = LarkMediaManager.shared.tryLock(scene: .vcRingtoneAudition, observer: self)
        switch result {
        case .success(let resource):
            resource.audioSession.enter(.vcRingtoneAudition)
            RingPlayer.shared.play(.customizeRingtone(url)) {
                if $0 {
                    RingPlayer.shared.addListener(self)
                } else {
                    LarkMediaManager.shared.unlock(scene: .vcRingtoneAudition, options: .leaveScenarios)
                }
            }
        case .failure(let error):
            self.logger.info("MediaMutex lock err: \(error), don`t play ringtone \(url)")
        }
    }

    public func stopPlayRingtone() {
        // 有会议场景，不播放铃声
        if MeetingManager.shared.currentSession != nil {
            logger.info("has active meeting, don`t stop ringtone")
            return
        }
        RingPlayer.shared.stop()
        LarkMediaManager.shared.unlock(scene: .vcRingtoneAudition, options: .leaveScenarios)
    }
}

extension CustomRingtonePlayer: RingPlayerListener {
    func ringPlayerDidFinished() {
        RingPlayer.shared.removeListener(self)
        LarkMediaManager.shared.getMediaResource(for: .vcRingtoneAudition)?.audioSession.leave(.vcRingtoneAudition)
    }
}

extension CustomRingtonePlayer: MediaResourceInterruptionObserver {
    public func mediaResourceWasInterrupted(by scene: MediaMutexScene, type: MediaMutexType, msg: String?) {
        logger.info("media resource has interrupted, scene:\(scene), type:\(type), msg: \(msg)")
        self.stopPlayRingtone()
    }

    public func mediaResourceInterruptionEnd(from scene: MediaMutexScene, type: MediaMutexType) {
        // do nothing
    }
}

private extension AudioSessionScenario {
    static let vcRingtoneAudition = AudioSessionScenario("vcRingtoneAudition", category: .playback, mode: .default)
}
