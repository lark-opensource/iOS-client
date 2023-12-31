//
//  CustomRingtongService.swift
//  ByteViewMessenger
//
//  Created by kiri on 2023/6/17.
//

import Foundation

public protocol CustomRingtoneService {
    func isPlayingRingtone() -> Bool
    func playRingtone(url: URL?)
    func stopPlayRingtone()
}
