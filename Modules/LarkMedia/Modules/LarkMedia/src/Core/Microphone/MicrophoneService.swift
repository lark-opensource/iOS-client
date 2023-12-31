//
//  MicrophoneService.swift
//  LarkMedia
//
//  Created by fakegourmet on 2023/7/4.
//

import Foundation

protocol MicrophoneService {
    func setMute(_ mute: Bool) -> Result<Void, MicrophoneMuteError>
}
