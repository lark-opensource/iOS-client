//
//  AVMicrophoneServiceImpl.swift
//  LarkMedia
//
//  Created by fakegourmet on 2023/7/4.
//

import AVFoundation

#if swift(>=5.9)
@available(iOS 17.0, *)
class AVMicrophoneServiceImpl: MicrophoneService {
    func setMute(_ mute: Bool) -> Result<Void, MicrophoneMuteError> {
        do {
            try AVAudioApplication.shared.setInputMuted(mute)
            return .success(Void())
        } catch {
            return .failure(.systemError(error))
        }
    }
}
#endif
