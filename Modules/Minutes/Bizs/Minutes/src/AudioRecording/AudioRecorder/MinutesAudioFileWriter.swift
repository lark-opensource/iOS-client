//
//  MinutesAudioFileCoverter.swift
//  Minutes
//
//  Created by lvdaqian on 2021/4/22.
//

import Foundation
import MinutesFoundation
import AVFoundation
import LarkCache
import LarkStorage
import AudioToolbox
import MinutesFoundation

public final class MinutesAudioFileWriter {
    // disable-lint: magic number
    let audioFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 44100, channels: 1, interleaved: false)!
    let audioFileSetting: [String: Any] = [
        AVFormatIDKey: kAudioFormatMPEG4AAC_HE,
        AVSampleRateKey: 44100,
        AVNumberOfChannelsKey: 1
    ] as [String: Any]
    // enable-lint: magic number
    let fileURL: URL

    lazy var audioWriter: AVAudioFile? = try? AVAudioFile(forWriting: fileURL, settings: audioFileSetting, commonFormat: .pcmFormatInt16, interleaved: false)
    lazy var converter: AVAudioConverter? = {
        guard let outFormat = AVAudioFormat(settings: audioFileSetting) else { return nil }
        return AVAudioConverter(from: audioFormat, to: outFormat)
    }()

    // disable-lint: magic number
    var cachedEncodedData: Data = Data(capacity: 6_000)
    // enable-lint: magic number

    init(_ url: URL) {
        fileURL = url
    }

    func appendMedia(_ data: Data) {
        guard let pcmBuffer = AVAudioPCMBuffer(data: data, audioFormat: audioFormat) else {
            MinutesLogger.recordFile.debug("pcmBuffer is nil")
            return
        }
        do {
            // disable-lint: magic number
            MinutesLogger.recordFile.debug("\(fileURL.lastPathComponent.suffix(16)) append media data with count \(data.count)")
            // enable-lint: magic number
            // 将pcm数据写入m4a文件
            try audioWriter?.write(from: pcmBuffer)
            // 将pcm -> aac
            encode(pcmBuffer)
        } catch {
            MinutesLogger.recordFile.error("write audio file \(fileURL.lastPathComponent) error: \(error)")
        }
    }

    // 将 aac 缓存数据写入文件
    func flush(to path: IsoPath) throws {
        do {
            try cachedEncodedData.write(to: path)
            cachedEncodedData.removeAll(keepingCapacity: true)
            MinutesLogger.recordFile.info("flush audio file \(path.lastPathComponent) success.")
        } catch {
            MinutesLogger.recordFile.error("flush audio file \(path.lastPathComponent) error: \(error)")
            //if remain space is less than 1k, post a warning message
            throw error
        }
    }

    // 将pcm -> aac
    func encode(_ pcmBuffer: AVAudioPCMBuffer) {
        guard let converter = self.converter else {
            MinutesLogger.recordFile.error("create audio convert failed.")
            return
        }

        // disable-lint: magic number
        MinutesLogger.recordFile.assertWarn(pcmBuffer.frameLength < 4096, "pcmBuffer.frameLength \(pcmBuffer.frameLength)")
        // enable-lint: magic number

        let outputBuffer = AVAudioCompressedBuffer(format: converter.outputFormat,
                                                   packetCapacity: 4,
                                                   maximumPacketSize: converter.maximumOutputPacketSize)

        var hasData: Bool = true
        let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
            if hasData {
                outStatus.pointee = AVAudioConverterInputStatus.haveData
                MinutesLogger.recordFile.assertWarn(inNumPackets > pcmBuffer.frameLength, "request packets: \(inNumPackets), pcmbuffer: \(pcmBuffer.frameLength)")
                hasData = false
                return pcmBuffer
            } else {
                outStatus.pointee = AVAudioConverterInputStatus.noDataNow
                MinutesLogger.recordFile.debug("request packets: \(inNumPackets), noDataNow")
                return nil
            }
        }

        var error: NSError?
        let status = converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)
        if let err = error {
            MinutesLogger.recordFile.error("convert error \(err), with status: \(status.rawValue)")
        } else {
            MinutesLogger.recordFile.debug("convert success length: \(outputBuffer.byteLength), with status: \(status.rawValue)")
            if outputBuffer.byteLength > 0 {
                let frame = outputBuffer.toADTSFrame()
                cachedEncodedData.append(frame)
            }
        }

    }

    func endEncode() {
        guard let converter = self.converter else {
            MinutesLogger.recordFile.error("create audio convert failed.")
            return
        }

        let outputBuffer = AVAudioCompressedBuffer(format: converter.outputFormat,
                                                   packetCapacity: 4,
                                                   maximumPacketSize: converter.maximumOutputPacketSize)

        let inputBlock: AVAudioConverterInputBlock = {
            inNumPackets, outStatus in
            outStatus.pointee = AVAudioConverterInputStatus.endOfStream
            MinutesLogger.recordFile.debug("request packets: \(inNumPackets), endOfStream")
            return nil
        }

        var error: NSError?
        let status = converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)
        if let err = error {
            MinutesLogger.recordFile.error("convert error \(err), with status: \(status.rawValue)")
        } else {
            MinutesLogger.recordFile.debug("convert success length: \(outputBuffer.byteLength), packet count: \(outputBuffer.packetCount), with status: \(status.rawValue)")
            if outputBuffer.byteLength > 0 {
                let frame = outputBuffer.toADTSFrame()
                cachedEncodedData.append(frame)
            }
        }
    }
}

extension AVAudioCompressedBuffer {
    func toADTSFrame() -> Data {

        guard packetCount > 0 else {
            return Data()
        }

        MinutesLogger.recordFile.assertWarn(packetCount <= 4, "packetCount \(packetCount) is greater than 4.")

        let profile: UInt8 = 2 // LC
        let numChannels: UInt8 = 1
        let sampleRateIndex: UInt8 = 7 // 44.1k for he
        let lenWithoutHeader = Int(byteLength)
        let adtsLength: Int = 7
        let packetsNumber = packetCount > 4 ? 4 : packetCount
        var packet: [UInt8] = [UInt8](repeating: 0x00, count: adtsLength)

        let fullLength = lenWithoutHeader + adtsLength

        packet[0] = 0b1111_1111
        packet[1] = 0b1111_1001
        packet[2] = ((profile - 1) << 6) | (sampleRateIndex << 2) | (numChannels >> 2)
        packet[3] = ((numChannels & 0x03) << 6) | UInt8((fullLength >> 11) & 0x03)
        packet[4] = UInt8((fullLength >> 3) & 0xFF)
        packet[5] = UInt8((fullLength & 0x07) << 5) | 0b0001_1111
        packet[6] = 0b1111_1100 | UInt8(packetsNumber - 1)

        var frame = Data(capacity: fullLength)
        frame.append(contentsOf: packet)
        let audioData = Data(bytes: data, count: lenWithoutHeader)
        frame.append(audioData)
        return frame
    }
}

extension AVAudioPCMBuffer {
    convenience init?(data: Data, audioFormat: AVAudioFormat) {
        let streamDesc = audioFormat.streamDescription.pointee
        let frameCapacity = UInt32(data.count) / streamDesc.mBytesPerFrame
        self.init(pcmFormat: audioFormat, frameCapacity: frameCapacity)

        self.frameLength = self.frameCapacity
        let audioBuffer = self.audioBufferList.pointee.mBuffers

        data.withUnsafeBytes { (bufferPointer) in
            guard let addr = bufferPointer.baseAddress else { return }
            audioBuffer.mData?.copyMemory(from: addr, byteCount: Int(audioBuffer.mDataByteSize))
        }

    }
}
