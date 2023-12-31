//
//  AudioEngine.swift
//  LarkMedia
//
//  Created by fakegourmet on 2023/3/2.
//

import Foundation
import AVFAudio

class AudioEngine {

    private(set) lazy var engine = AVAudioEngine()

    private(set) lazy var player = AVAudioPlayerNode()

    private(set) lazy var recordMixer = AVAudioMixerNode()

    private lazy var format: AVAudioFormat = engine.inputNode.outputFormat(forBus: 0)

    let commonFormat = AVAudioFormat.init(commonFormat: .pcmFormatFloat32, sampleRate: 44100.0, channels: 2, interleaved: true)

    private var file: AVAudioFile?

    func addFile(url: URL? = Bundle.main.url(forResource: "vc_call_ringing", withExtension: "mp3")) {
        guard let url = url else { return }
        self.file = try? AVAudioFile(forReading: url)
    }

    func addPlayer() {
        if #available(iOS 13.0, *) {
            guard !engine.attachedNodes.contains(player) else {
                return
            }
        }
        let engine = engine
        let player = player
        let file = file
        NSExceptionCatcher.async {
            engine.attach(player)
            if let file = file {
                engine.connect(player, to: engine.mainMixerNode, format: file.processingFormat)
            }
            engine.prepare()
        }
    }

    func removePlayer() {
        if #available(iOS 13.0, *) {
            guard engine.attachedNodes.contains(player) else {
                return
            }
        }
        let engine = engine
        let player = player
        NSExceptionCatcher.async {
            engine.stop()
            engine.detach(player)
        }
    }

    func addRecorder() {
        let engine = engine
        let recordMixer = recordMixer
        let commonFormat = commonFormat
        NSExceptionCatcher.async {
            engine.attach(recordMixer)
            engine.connect(engine.inputNode, to: recordMixer, format: engine.inputNode.inputFormat(forBus: 0))
            engine.connect(recordMixer, to: engine.mainMixerNode, format: commonFormat)
            engine.prepare()
        }
    }

    func removeRecorder() {
        let engine = engine
        let recordMixer = recordMixer
        NSExceptionCatcher.async {
            engine.stop()
            engine.detach(recordMixer)
        }
    }

    func startEngine() {
        guard !engine.isRunning else { return }
        var buffer: AVAudioPCMBuffer?
        if let file = file {
            buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: UInt32(file.length))
        }
        do {
            try engine.start()
            if let buffer = buffer {
                try file?.read(into: buffer)
            }
        } catch {
            AVAudioSession.logger.error("AudioEngine start failed: \(error)")
        }
        if let buffer = buffer {
            let player = player
            NSExceptionCatcher.async {
                player.scheduleBuffer(buffer, at: nil, options: .loops)
            }
        }
    }

    func stopEngine() {
        guard engine.isRunning else { return }
        let engine = engine
        NSExceptionCatcher.async {
            engine.stop()
        }
    }

    func startPlayer() {
        guard !player.isPlaying else {
            return
        }
        let player = player
        NSExceptionCatcher.async {
            player.play()
        }
    }

    func pausePlayer() {
        guard player.isPlaying else {
            return
        }
        let player = player
        NSExceptionCatcher.async {
            player.pause()
        }
    }

    func stopPlayer() {
        guard player.isPlaying else {
            return
        }
        let player = player
        NSExceptionCatcher.async {
            player.stop()
        }
    }

    var isVPIO: Bool {
        guard #available(iOS 13.0, *) else { return false }
        return engine.inputNode.isVoiceProcessingEnabled
    }

    func setVPIO(enabled: Bool) {
        guard #available(iOS 13.0, *) else { return }
        do {
            try engine.inputNode.setVoiceProcessingEnabled(enabled)
        } catch {
            AVAudioSession.logger.error("setVoiceProcessingEnabled: \(enabled) error: \(error)")
        }
    }

    func getInputAudioUnit(id: AudioUnitPropertyID, scope: AudioUnitScope, element: AudioUnitElement) -> String? {
        guard let audioUnit = engine.inputNode.audioUnit else {
            return nil
        }
        var data: UInt32 = 0
        var size: UInt32 = UInt32(MemoryLayout<UInt32>.size)
        let result = AudioUnitGetProperty(audioUnit, id, scope, element, &data, &size)
        AVAudioSession.logger.info("AudioUnitGetProperty: \(id), result: \(result)")
        return "\(data)"
    }

    func getOutputAudioUnit(id: AudioUnitPropertyID, scope: AudioUnitScope, element: AudioUnitElement) -> String? {
        guard let audioUnit = engine.outputNode.audioUnit else {
            return nil
        }
        var data: UInt32 = 0
        var size: UInt32 = UInt32(MemoryLayout<UInt32>.size)
        let result = AudioUnitGetProperty(audioUnit, id, scope, element, &data, &size)
        AVAudioSession.logger.info("AudioUnitGetProperty: \(id), result: \(result)")
        return "\(data)"
    }

    func setInputAudioUnit(id: AudioUnitPropertyID, scope: AudioUnitScope, element: AudioUnitElement, data: UnsafeRawPointer?, size: UInt32) {
        guard let audioUnit = engine.inputNode.audioUnit else {
            return
        }
        let result = AudioUnitSetProperty(audioUnit, id, scope, element, data, size)
        AVAudioSession.logger.info("AudioUnitSetProperty: \(id), result: \(result)")
    }

    func setOutputAudioUnit(id: AudioUnitPropertyID, scope: AudioUnitScope, element: AudioUnitElement, data: UnsafeRawPointer?, size: UInt32) {
        guard let audioUnit = engine.outputNode.audioUnit else {
            return
        }
        let result = AudioUnitSetProperty(audioUnit, id, scope, element, data, size)
        AVAudioSession.logger.info("AudioUnitSetProperty: \(id), result: \(result)")
    }
}

extension NSExceptionCatcher {

    static let queue = DispatchQueue(label: "NSExceptionCatcher.execute", qos: .background, attributes: .concurrent)

    // AVAudioEngine 相关接口会存在报 NSException 的问题，此处需要 catch，否则会崩溃
    static func sync(_ closure: @escaping () -> Void, function: String = #function, line: Int = #line) {
        queue.sync {
            Self.execute(closure, function: function, line: line)
        }
    }

    static func async(_ closure: @escaping () -> Void, function: String = #function, line: Int = #line) {
        queue.async {
            Self.execute(closure, function: function, line: line)
        }
    }

    static func execute(_ closure: @escaping () -> Void, function: String, line: Int) {
        let exception = Self.tryCatch {
            closure()
        }
        if let exception = exception {
            AVAudioSession.logger.error("\(function): \(line) failed: \(exception)")
        }
    }
}
