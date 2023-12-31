//
//  RTMicrophoneServiceImpl.swift
//  LarkMedia
//
//  Created by FakeGourmet on 2023/9/11.
//

import AVFoundation

@available(iOS 17.0, *)
class RTMicrophoneServiceImpl: MicrophoneService {
    func setMute(_ mute: Bool) -> Result<Void, MicrophoneMuteError> {
        do {
            try LarkAudioSession.shared.avAudioSession.setInputMuted(mute)
            return .success(Void())
        } catch {
            return .failure(.systemError(error))
        }
    }
}
