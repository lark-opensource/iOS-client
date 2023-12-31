//
//  AVAudioSession+Device.swift
//  AudioSessionScenario
//
//  Created by fakegourmet on 2022/2/21.
//

import AVFoundation

extension AVAudioSession.Port {
    private static let bluetoothPorts: Set<AVAudioSession.Port> = [.bluetoothA2DP, .bluetoothLE, .bluetoothHFP]
    private static let headsetPorts: Set<AVAudioSession.Port> = bluetoothPorts.union([.headphones, .headsetMic])

    public var isBluetooth: Bool { Self.bluetoothPorts.contains(self) }
    public var isHeadset: Bool { Self.headsetPorts.contains(self) }
}
