//
//  RecordTracker.swift
//  LarkAudioKit
//
//  Created by 李晨 on 2021/6/10.
//

import Foundation
import LKCommonsLogging
import LKCommonsTracker
import CoreTelephony
import AVFoundation

// swiftlint:disable line_length function_body_length

final class RecordTracker {
    static let logger = Logger.log(RecordTracker.self, category: "Module.Audio")

    /// 是否开始
    private var started = false

    /// 最终录音长度
    private var recordLength: TimeInterval = 0

    /// 开始录音时间
    private var startTime: TimeInterval = 0

    /// 最终 packet 长度
    private var packetNumber: UInt32 = 0

    /// 最终数据长度
    private var dataLength: Int = 0

    /// 最终回调次数
    private var callbackTimes: UInt32 = 0

    /// max volume
    private var maxVolume: Float32 = 0

    /// 音量数据缓存
    private var volumeBuffer: [Float32] = []

    /// 音频数据缓存
    private var audioDataBuffer: [(UInt32, Int)] = []

    func start() {
        /// 在异步线程打印当前设备相关信息
        DispatchQueue.global().async {
            let session = AVAudioSession.sharedInstance()
            Self.logger.info("record service start record start, mode \(session.mode.rawValue), category \(session.category.rawValue), options \(session.categoryOptions.rawValue), isInputAvailable \(session.isInputAvailable), isOtherAudioPlaying \(session.isOtherAudioPlaying)")
            Self.logger.info("record service start record start, routeSharingPolicy \(session.routeSharingPolicy.rawValue), availableModes \(session.availableModes.map { $0.rawValue }), preferredInput \(session.preferredInput), preferredSampleRate \(session.preferredSampleRate), preferredIOBufferDuration \(session.preferredIOBufferDuration)")
            if #available(iOS 14.0, *) {
                Self.logger.info("record service start record start, preferredInputNumberOfChannels \(session.preferredInputNumberOfChannels), preferredOutputNumberOfChannels \(session.preferredOutputNumberOfChannels), preferredInputOrientation \(session.preferredInputOrientation.rawValue), inputOrientation \(session.inputOrientation.rawValue), maximumInputNumberOfChannels \(session.maximumInputNumberOfChannels), maximumOutputNumberOfChannels \(session.maximumOutputNumberOfChannels)")
                Self.logger.info("record service start record start, inputGain \(session.inputGain), isInputGainSettable \(session.isInputGainSettable), inputDataSource \(session.inputDataSource), outputDataSource \(session.outputDataSource), inputDataSources \(session.inputDataSources), outputDataSources \(session.outputDataSources)")
                Self.logger.info("record service start record start, sampleRate \(session.sampleRate), inputNumberOfChannels \(session.inputNumberOfChannels), outputNumberOfChannels \(session.outputNumberOfChannels), inputLatency \(session.inputLatency), outputLatency \(session.outputLatency), ioBufferDuration \(session.ioBufferDuration)")
                Self.logger.info("record service start record start, secondaryAudioShouldBeSilencedHint \(session.secondaryAudioShouldBeSilencedHint), outputVolume \(session.outputVolume), promptStyle \(session.promptStyle), currentRoute \(session.currentRoute), outputLatency \(session.outputLatency), ioBufferDuration \(session.ioBufferDuration)")
            }
            Self.logger.info("record service start record start, currentRoute  \(session.currentRoute)")
        }
        self.started = true
        self.packetNumber = 0
        self.dataLength = 0
        self.callbackTimes = 0
        self.maxVolume = 0
        self.recordLength = 0
        self.startTime = Date().timeIntervalSince1970
    }

    func stop(result: Int32 = 0) {
        guard self.started else { return }
        self.started = false
        self.recordLength = Date().timeIntervalSince1970 - startTime
        self.printAudioInfoIfNeeded(isEnd: true)
        self.printVolumeIfNeeded(isEnd: true)
        self.sendRecordEvent(result: result)
        self.sendRecordErrorIfNeeded(result: result)

        Self.logger.info("record service stop record end, packetNumber \(self.packetNumber), dataLength \(self.dataLength), callbackTimes \(self.callbackTimes),maxVolume \(self.maxVolume), recordLength \(self.recordLength), result \(result)")
    }

    /// 接收音频数据
    func receiveAudio(packetNumber: UInt32, count: Int) {
        self.callbackTimes += 1
        self.audioDataBuffer.append((packetNumber, count))
        self.packetNumber += packetNumber
        self.dataLength += count
        printAudioInfoIfNeeded(isEnd: false)
    }

    /// 打印音频数据
    func printAudioInfoIfNeeded(isEnd: Bool) {
        if self.audioDataBuffer.count >= 10 || isEnd {
            RecordService.logger.info("audio info (packetNumber, dataCount) \(self.audioDataBuffer), isEnd \(isEnd)")
            self.audioDataBuffer.removeAll()
        }
    }

    /// 接收音频音量数据
    func receiveVolume(_ value: Float32) {
        self.volumeBuffer.append(value)
        self.maxVolume = max(value, self.maxVolume)
        printVolumeIfNeeded(isEnd: false)
    }

    /// 打印音频音量数据
    func printVolumeIfNeeded(isEnd: Bool) {
        if self.volumeBuffer.count >= 10 || isEnd {
            RecordService.logger.info("audio volumes \(self.volumeBuffer), isEnd \(isEnd)")
            self.volumeBuffer.removeAll()
        }
    }

    /// 发送录音数据埋点
    func sendRecordEvent(result: Int32) {
        guard self.recordLength > 0 else {
            return
        }

        let metric: [String: Any] = [
            "dataLength": self.dataLength,
            "packetNumber": self.packetNumber,
            "callbackTimes": self.callbackTimes,
            "maxVolume": self.maxVolume,
            "recordLength": self.recordLength,
            "dataLengthPerSec": Double(self.dataLength) / self.recordLength,
            "packetNumberPerSec": Double(self.packetNumber) / self.recordLength,
            "callbackTimesPerSec": Double(self.callbackTimes) / self.recordLength
        ]
        let event = SlardarEvent(
            name: "audio_record_info",
            metric: metric,
            category: ["result": "\(result)"],
            extra: [:])
        Tracker.post(event)
    }

    func sendRecordErrorIfNeeded(result: Int32) {
        // 只处理录音时长超过 5 秒的场景
        guard self.recordLength > 3 || result != 0 else {
            return
        }
        var needSend: Bool = false
        var type: String = ""
        if result != 0 {
            type = "callAPIError"
            needSend = true
        } else if self.callbackTimes == 0 {
            type = "callbackError"
            needSend = true
        } else if self.packetNumber < 2_500 {
            type = "packetError"
            needSend = true
        } else if self.dataLength < 5_000 {
            type = "dataLengthError"
            needSend = true
        } else if self.maxVolume == 0 {
            type = "volumeError"
            needSend = true
        }

        if needSend {
            let category: [String: Any] = [
                "type": type,
                "result": result
            ]
            let metric: [String: Any] = [
                "dataLength": self.dataLength,
                "packetNumber": self.packetNumber,
                "callbackTimes": self.callbackTimes,
                "maxVolume": self.maxVolume,
                "recordLength": self.recordLength
            ]
            let event = SlardarEvent(
                name: "audio_record_error",
                metric: metric,
                category: category,
                extra: [:])
            Tracker.post(event)
        }
    }

}

final class RecordUtil {
    /// 修改 pcm 音量
    static func changeVolume(data: Data, multiplier: UInt32) -> Data {
        var newData: Data = Data()
        let nsdata: NSData = data as NSData
        for i in 0..<(data.count / 2) {
            var v1: UInt8 = 0
            var v2: UInt8 = 0
            nsdata.getBytes(
                &v1,
                range: NSRange(location: MemoryLayout<UInt8>.size * (2 * i), length: MemoryLayout<UInt8>.size)
            )
            nsdata.getBytes(
                &v2,
                range: NSRange(location: MemoryLayout<UInt8>.size * (2 * i + 1), length: MemoryLayout<UInt8>.size)
            )
            var temp: UInt32 = UInt32(UInt32(v1) + (UInt32(v2) << 8)) * multiplier
            if temp > UInt16.max {
                temp = UInt32(UInt16.max)
            }
            let contents: [UInt8] = [
                UInt8(temp & 0xFF),
                UInt8((temp >> 8) & 0xFF)
            ]
            newData.append(contentsOf: contents)
        }
        return newData
    }
}

// swiftlint:enable line_length function_body_length
