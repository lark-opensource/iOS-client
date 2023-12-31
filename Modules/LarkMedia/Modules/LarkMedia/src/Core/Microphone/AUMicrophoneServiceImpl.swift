//
//  AUMicrophoneServiceImpl.swift
//  LarkMedia
//
//  Created by fakegourmet on 2023/7/4.
//

import Foundation
import AudioUnit

class AUMicrophoneServiceImpl: MicrophoneService {

    private func createAudioUnit() -> (AudioUnit?, OSStatus) {
        var desc = AudioComponentDescription(componentType: kAudioUnitType_Output,
                                             componentSubType: kAudioUnitSubType_VoiceProcessingIO,
                                             componentManufacturer: kAudioUnitManufacturer_Apple,
                                             componentFlags: 0,
                                             componentFlagsMask: 0)
        guard let component = AudioComponentFindNext(nil, &desc) else {
            return (nil, -1)
        }
        var audioUnit: AudioUnit?
        let result = AudioComponentInstanceNew(component, &audioUnit)
        return (audioUnit, result)
    }

    func setMute(_ mute: Bool) -> Result<Void, MicrophoneMuteError> {
        guard !mute else {
            // AU 方式只支持关闭硬件静音
            return .failure(MicrophoneMuteError.operationNotAllowed)
        }

        let (audioUnit, result) = createAudioUnit()
        guard result == noErr, let audioUnit = audioUnit else {
            return .failure(MicrophoneMuteError.osError(result))
        }

        defer {
            AudioComponentInstanceDispose(audioUnit)
        }

        var mute: UInt32 = mute ? 1 : 0
        let error = AudioUnitSetProperty(audioUnit,
                                         kAUVoiceIOProperty_MuteOutput,
                                         kAudioUnitScope_Input,
                                         0,
                                         &mute,
                                         UInt32(MemoryLayout<UInt32>.size))

        if error == noErr {
            return .success(Void())
        } else {
            return .failure(MicrophoneMuteError.osError(error))
        }
    }
}
