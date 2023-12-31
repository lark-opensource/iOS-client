//
//  MinutesAudioFileReader.swift
//  Minutes
//
//  Created by lvdaqian on 2021/4/25.
//

import Foundation
import MinutesFoundation
import AVFoundation
import LarkCache
import AudioToolbox

public final class MinutesAudioFileReader {
    // disable-lint: magic number
    let audioFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 44100, channels: 1, interleaved: false)!
    let audioFileSetting: [String: Any] = [
        AVFormatIDKey: kAudioFormatMPEG4AAC_HE,
        AVSampleRateKey: 44100,
        AVNumberOfChannelsKey: 1
    ] as [String: Any]
    // enable-lint: magic number
    let fileURL: URL

    lazy var audioReader: AVAudioFile? = try? AVAudioFile(forReading: fileURL, commonFormat: .pcmFormatInt16, interleaved: false)

    public init(_ url: URL) {
        fileURL = url
    }

    private func toRawData(pcm buffer: AVAudioPCMBuffer) -> Data? {
        let audioBuffer = buffer.audioBufferList.pointee.mBuffers
        guard let dataBuffer = audioBuffer.mData else {
            return nil
        }
        return Data(bytes: dataBuffer, count: Int(audioBuffer.mDataByteSize))
    }

    public func read() -> Data? {
        guard let reader = audioReader else { return nil }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: reader.processingFormat, frameCapacity: AVAudioFrameCount(reader.length)) else { return nil }

        do {
            MinutesLogger.recordFile.debug("read audio data with count \(reader.length)")
            try reader.read(into: buffer)
            MinutesLogger.recordFile.debug("read status: \(reader.framePosition) \(reader.length)")
            return toRawData(pcm: buffer)
        } catch {
            MinutesLogger.recordFile.error("read audio file \(fileURL.lastPathComponent) error: \(error)")
            return nil
        }
    }
}
