//
//  RecordService.swift
//  Lark
//
//  Created by lichen on 2017/5/21.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import AudioToolbox
import AVFoundation
import LKCommonsLogging
import LKCommonsTracker
import libkern
import LarkSensitivityControl

// swiftlint:disable line_length function_body_length

/// audio record service
public final class RecordService: RecordServiceProtocol {

    static let logger = Logger.log(RecordService.self, category: "Module.Audio")

    /// 用于标记 record 唯一 id
    public let uuid: UUID = UUID()

    /// 初始化方法
    public init(sampleRate: Float64, channel: UInt32, bitsPerChannel: UInt32) {
        var formatFlags = AudioFormatFlags()
        formatFlags |= kLinearPCMFormatFlagIsSignedInteger
        formatFlags |= kLinearPCMFormatFlagIsPacked
        format = AudioStreamBasicDescription(
            mSampleRate: sampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: formatFlags,
            mBytesPerPacket: UInt32(1 * MemoryLayout<Int16>.stride),
            mFramesPerPacket: 1,
            mBytesPerFrame: UInt32(1 * MemoryLayout<Int16>.stride),
            mChannelsPerFrame: channel,
            mBitsPerChannel: bitsPerChannel,
            mReserved: 0
        )
        RecordService.logger.info("record service init, uuid \(self.uuid.uuidString) sampleRate \(sampleRate) channel \(channel) bitsPerChannel \(bitsPerChannel)")
    }

    deinit {
        RecordService.logger.info("record service deinit, uuid \(self.uuid.uuidString)")
    }

    /// 为 true 的时候 使用系统分贝
    /// 为 false 则使用 pcm 动态计算分贝 目前只支持 16位采样 单声道
    public var useAveragePower: Bool = true

    /// 系统分贝回调间隔
    public var averagePowerCallbackInterval: TimeInterval = 0.1

    /// 数据回调间隔
    public var dataCallbackInterval: Float64 = 0.5

    /// 开始录音的时间
    public fileprivate(set) var startTime: TimeInterval = 0

    /// 最终录音长度
    public fileprivate(set) var recordLength: TimeInterval = 0

    let tracker: RecordTracker = RecordTracker()

    ///录音过程中，录音长度
    public var currentTime: TimeInterval {
        if startTime == 0 {
            return 0
        }

        if recordLength == 0 {
            return Date().timeIntervalSince1970 - startTime
        }

        return recordLength
    }

    fileprivate var lock: NSLock = NSLock()

    fileprivate(set) var queue: AudioQueueRef?
    fileprivate(set) var format = AudioStreamBasicDescription()
    fileprivate var powerTimer: Timer?

    /// 录音数据 delegate
    public weak var delegate: RecordServiceDelegate?

    /// 开始录音
    ///
    /// Token: 需要申请 AudioQueueStart
    public func startRecord(token: Token, encoder: RecordServiceDelegate) -> Bool {
        var result: OSStatus = 0
        return startRecord(token: token, encoder: encoder, result: &result)
    }

    @available(*, deprecated, message: "use startRecord(token:encoder:) for security reason.")
    public func startRecord(encoder: RecordServiceDelegate) -> Bool {
        var result: OSStatus = 0
        return startRecord(encoder: encoder, result: &result)
    }

    /// 开始录音, 可以获取 result
    ///
    /// Token: 需要申请 AudioQueueStart
    public func startRecord(token: Token, encoder: RecordServiceDelegate, result: inout OSStatus) -> Bool {
        do {
            try SensitivityManager.shared.checkToken(token, context: Context([AtomicInfo.AudioRecord.AudioQueueStart.rawValue]))
        } catch {
            Self.logger.error("record service start failed: \(error)")
            return false
        }
        return startRecord(encoder: encoder, result: &result)
    }

    private func startRecord(encoder: RecordServiceDelegate, result: inout OSStatus) -> Bool {
        RecordService.logger.info("record service start record start , uuid \(self.uuid.uuidString), useAveragePower \(useAveragePower), averagePowerCallbackInterval \(averagePowerCallbackInterval), dataCallbackInterval \(dataCallbackInterval)")
        lock.lock()
        defer {
            lock.unlock()
        }
        guard !isRecording else {
            RecordService.logger.warn("record service is recording, uuid \(self.uuid.uuidString)")
            return false
        }
        self.setPreferredInput(active: true)
        self.delegate = encoder
        self.tracker.start()
        self.delegate?.recordServiceStart()
        self.prepareToRecord()
        self.isRecording = true
        guard let queue = queue else {
            RecordService.logger.error("queue is not init, uuid \(self.uuid.uuidString)")
            self.setPreferredInput(active: false)
            self.tracker.stop(result: -1)
            return false
        }
        result = call("AudioQueueStart", AudioQueueStart(queue, nil))
        /// 尝试恢复
        if result != noErr {
            let session = AVAudioSession.sharedInstance()
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: [])
                try AVAudioSession.sharedInstance().setActive(true)
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [])
            } catch {
                RecordService.logger.error("reset aduiosession active error \(error)")
            }
            result = call("AudioQueueStart", AudioQueueStart(queue, nil))
            if result != noErr {
                /// 尝试沉睡 0.1 s
                usleep(100000)
                RecordService.logger.error("audio record sleep 0.1s")
                Self.logger.info("record service record retry, mode \(session.mode.rawValue), category \(session.category.rawValue), options \(session.categoryOptions.rawValue), isInputAvailable \(session.isInputAvailable), isOtherAudioPlaying \(session.isOtherAudioPlaying)")
                result = call("AudioQueueStart", AudioQueueStart(queue, nil))
            }
        }

        self.prepareAveragePower()
        self.startTime = Date().timeIntervalSince1970
        self.recordLength = 0
        RecordService.logger.info("record service start record end, uuid \(self.uuid.uuidString)")
        if result != noErr {
            RecordService.logger.error("audio start failed result \(result), uuid \(self.uuid.uuidString)")
            self.setPreferredInput(active: false)
            self.tracker.stop(result: result)
            return false
        }
        return true
    }

    /// 结束录音
    public func stopRecord() {
        RecordService.logger.info("record service stop record start, uuid \(self.uuid.uuidString)")
        lock.lock()
        defer {
            lock.unlock()
        }
        guard isRecording else {
            RecordService.logger.warn("record service is not recoring, uuid \(self.uuid.uuidString)")
            return
        }
        guard let queue = queue else {
            RecordService.logger.error("queue is not init, uuid \(self.uuid.uuidString)")
            return
        }
        powerTimer?.invalidate()
        isRecording = false
        call("AudioQueueFlush", AudioQueueFlush(queue))
        call("AudioQueueStop", AudioQueueStop(queue, true))
        call("AudioQueueDispose", AudioQueueDispose(queue, false))
        self.delegate?.recordServiceStop()
        self.delegate = nil
        self.recordLength = Date().timeIntervalSince1970 - startTime
        self.startTime = 0
        self.setPreferredInput(active: false)
        self.tracker.stop()
    }

    /// 判断是否正在录音
    public fileprivate(set) var isRecording: Bool = false

    private let callback: AudioQueueInputCallback = {
        userData, queue, bufferRef, startTimeRef, numPackets, packetDescriptions in

        guard let userData = userData else { return }
        let audioRecorder = Unmanaged<RecordService>.fromOpaque(userData).takeUnretainedValue()

        let buffer = bufferRef.pointee
        let startTime = startTimeRef.pointee

        var numPackets = numPackets
        if numPackets == 0 && audioRecorder.format.mBytesPerPacket != 0 {
            numPackets = buffer.mAudioDataByteSize / audioRecorder.format.mBytesPerPacket
        }
        autoreleasepool {
            let pcm: Data = Data(bytes: buffer.mAudioData, count: Int(buffer.mAudioDataByteSize))
            audioRecorder.delegate?.onMicrophoneData(pcm)
            audioRecorder.tracker.receiveAudio(packetNumber: numPackets, count: pcm.count)
            if !audioRecorder.useAveragePower {
                audioRecorder.parseBufferPower(data: pcm)
            }
        }

        guard audioRecorder.isRecording else {
            return
        }

        if let queue = audioRecorder.queue {
            AudioQueueEnqueueBuffer(queue, bufferRef, 0, nil)
        } else {
            RecordService.logger.error("queue is null in callback, uuid \(audioRecorder.uuid.uuidString)")
        }
    }

    private func prepareToRecord() {
        let pointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        call(
            "AudioQueueNewInput",
            AudioQueueNewInput(
                &format,
                callback,
                pointer,
                CFRunLoopGetCurrent(),
                CFRunLoopMode.commonModes.rawValue,
                0,
                &queue
            )
        )
        guard let queue = queue else {
            assertionFailure()
            RecordService.logger.error("queue is not create, uuid \(self.uuid.uuidString)")
            return
        }
        var formatSize = UInt32(MemoryLayout<AudioStreamBasicDescription>.stride)
        call("AudioQueueGetProperty", AudioQueueGetProperty(queue, kAudioQueueProperty_StreamDescription, &format, &formatSize))

        let numBuffers = 5
        let bufferSize = deriveBufferSize(seconds: self.dataCallbackInterval)
        for _ in 0..<numBuffers {
            let bufferRef = UnsafeMutablePointer<AudioQueueBufferRef?>.allocate(capacity: 1)
            defer {
                bufferRef.deallocate()
            }
            call(
                "AudioQueueAllocateBuffer",
                AudioQueueAllocateBuffer(queue, bufferSize, bufferRef)
            )
            if let buffer = bufferRef.pointee {
                call(
                    "AudioQueueEnqueueBuffer",
                     AudioQueueEnqueueBuffer(queue, buffer, 0, nil)
                )
            } else {
                RecordService.logger.error("queue buffer is not create, uuid \(self.uuid.uuidString)")
            }
        }
    }

    /// 准备获取系统分贝信息，由于调用顺序问题，需要放到 AudioQueueStart 后面
    private func prepareAveragePower() {
        if self.useAveragePower {
            guard let queue = queue else {
                assertionFailure()
                return
            }
            var metering: UInt32 = 1
            let meteringSize = UInt32(MemoryLayout<UInt32>.stride)
            let meteringProperty = kAudioQueueProperty_EnableLevelMetering
            AudioQueueSetProperty(queue, meteringProperty, &metering, meteringSize)

            powerTimer = Timer(
                timeInterval: self.averagePowerCallbackInterval,
                target: self,
                selector: #selector(samplePower),
                userInfo: nil,
                repeats: true
            )
            RunLoop.current.add(powerTimer!, forMode: .common)
        }
    }

    private func deriveBufferSize(seconds: Float64) -> UInt32 {
        guard let queue = queue else { return 0 }
        let maxBufferSize = UInt32(0x50000)
        var maxPacketSize = format.mBytesPerPacket
        if maxPacketSize == 0 {
            var maxVBRPacketSize = UInt32(MemoryLayout<UInt32>.stride)
            call(
                "AudioQueueGetProperty",
                AudioQueueGetProperty(
                    queue,
                    kAudioQueueProperty_MaximumOutputPacketSize,
                    &maxPacketSize,
                    &maxVBRPacketSize
                )
            )
        }
        let numBytesForTime = UInt32(format.mSampleRate * Float64(maxPacketSize) * seconds)
        let bufferSize = (numBytesForTime < maxBufferSize ? numBytesForTime : maxBufferSize)
        RecordService.logger.info("deriveBufferSize seconds \(seconds), bufferSize \(bufferSize)")
        return bufferSize
    }

    @objc
    private func samplePower() {
        guard let queue = queue else { return }
        var meters: [AudioQueueLevelMeterState] = [AudioQueueLevelMeterState(mAveragePower: 0, mPeakPower: 0)]
        var metersSize = UInt32(meters.count * MemoryLayout<AudioQueueLevelMeterState>.stride)
        let meteringProperty = kAudioQueueProperty_CurrentLevelMeterDB
        let meterStatus = AudioQueueGetProperty(queue, meteringProperty, &meters, &metersSize)
        guard meterStatus == 0 else {
            RecordService.logger.error("samplePower error meterStatus \(meterStatus)")
            return
        }
        if !meters[0].mAveragePower.isNaN {
            let power = meters[0].mAveragePower + 80
            self.delegate?.onPowerData(power: power)
            self.tracker.receiveVolume(power)
        } else {
            RecordService.logger.error("samplePower error meters[0].mAveragePower \(meters[0].mAveragePower)")
        }
    }

    private func setPreferredInput(active: Bool) {
        do {
            if active {
                let availableInputs = AVAudioSession.sharedInstance().availableInputs ?? []
                let hasCarAudio = availableInputs.contains(where: { desc in
                    return desc.portType == .carAudio
                })
                if hasCarAudio, let defaultMic = availableInputs.first(where: { desc in
                    return desc.portType == .builtInMic
                }) {
                    RecordService.logger.info("audio record set setPreferredInput default")
                    try AVAudioSession.sharedInstance().setPreferredInput(defaultMic)
                }
            } else {
                if AVAudioSession.sharedInstance().preferredInput != nil {
                    RecordService.logger.info("audio record set setPreferredInput nil")
                    try AVAudioSession.sharedInstance().setPreferredInput(nil)
                }
            }
        } catch {
            RecordService.logger.error("audio record set setPreferredInput active \(active) \(error) ")
        }
    }

    /// 解析音频数据
    private func parseBufferPower(data: Data) {
        if data.isEmpty {
            RecordService.logger.info("audio data buffer is empty")
            return
        }

        var sumVolume: Float32 = 0
        var avgVolume: Float32 = 0
        let nsdata: NSData = data as NSData

        for i in 0..<(data.count / 2) {
            var v1: Int8 = 0
            var v2: Int8 = 0
            nsdata.getBytes(
                &v1,
                range: NSRange(location: MemoryLayout<Int8>.size * (2 * i), length: MemoryLayout<Int8>.size)
            )
            nsdata.getBytes(
                &v2,
                range: NSRange(location: MemoryLayout<Int8>.size * (2 * i + 1), length: MemoryLayout<Int8>.size)
            )
            var temp: Int32 = Int32(Int32(v1) + (Int32(v2) << 8))
            if temp >= 0x8000 {
                temp = 0xffff - temp
            }
            sumVolume += Float32(abs(temp))
        }
        avgVolume = sumVolume / Float32(data.count) / 2
        let volume = log(avgVolume + 1) * 10
        if !volume.isNaN {
            self.delegate?.onPowerData(power: volume)
            self.tracker.receiveVolume(volume)
        } else {
            RecordService.logger.error("parseBufferPower error sumVolume \(sumVolume) avgVolume \(avgVolume) data \(data.count) volume \(volume)")
        }
    }

    @discardableResult
    private func call(
        _ name: String,
        _ block:@autoclosure () -> OSStatus,
        function: String = #function,
        line: Int = #line
    ) -> OSStatus {
        let status = block()
        let message: String
        switch status {
        case noErr:
            message = "noError"
        case kAudioQueueErr_InvalidBuffer:
            message = "kAudioQueueErr_InvalidBuffer"
        case kAudioQueueErr_BufferEmpty:
            message = "kAudioQueueErr_BufferEmpty"
        case kAudioQueueErr_DisposalPending:
            message = "kAudioQueueErr_DisposalPending"
        case kAudioQueueErr_InvalidProperty:
            message = "kAudioQueueErr_InvalidProperty"
        case kAudioQueueErr_InvalidPropertySize:
            message = "kAudioQueueErr_InvalidPropertySize"
        case kAudioQueueErr_InvalidParameter:
            message = "kAudioQueueErr_InvalidParameter"
        case kAudioQueueErr_CannotStart:
            message = "kAudioQueueErr_CannotStart"
        case kAudioQueueErr_InvalidDevice:
            message = "kAudioQueueErr_InvalidDevice"
        case kAudioQueueErr_BufferInQueue:
            message = "kAudioQueueErr_BufferInQueue"
        case kAudioQueueErr_InvalidRunState:
            message = "kAudioQueueErr_InvalidRunState"
        case kAudioQueueErr_InvalidQueueType:
            message = "kAudioQueueErr_InvalidQueueType"
        case kAudioQueueErr_Permissions:
            message = "kAudioQueueErr_Permissions"
        case kAudioQueueErr_InvalidPropertyValue:
            message = "kAudioQueueErr_InvalidPropertyValue"
        case kAudioQueueErr_PrimeTimedOut:
            message = "kAudioQueueErr_PrimeTimedOut"
        case kAudioQueueErr_CodecNotFound:
            message = "kAudioQueueErr_CodecNotFound"
        case kAudioQueueErr_InvalidCodecAccess:
            message = "kAudioQueueErr_InvalidCodecAccess"
        case kAudioQueueErr_QueueInvalidated:
            message = "kAudioQueueErr_QueueInvalidated"
        case kAudioQueueErr_TooManyTaps:
            message = "kAudioQueueErr_TooManyTaps"
        case kAudioQueueErr_InvalidTapContext:
            message = "kAudioQueueErr_InvalidTapContext"
        case kAudioQueueErr_RecordUnderrun:
            message = "kAudioQueueErr_RecordUnderrun"
        case kAudioQueueErr_InvalidTapType:
            message = "kAudioQueueErr_InvalidTapType"
        case kAudioQueueErr_BufferEnqueuedTwice:
            message = "kAudioQueueErr_BufferEnqueuedTwice"
        case kAudioQueueErr_CannotStartYet:
            message = "kAudioQueueErr_CannotStartYet"
        case kAudioQueueErr_EnqueueDuringReset:
            message = "kAudioQueueErr_EnqueueDuringReset"
        case kAudioQueueErr_InvalidOfflineMode:
            message = "kAudioQueueErr_InvalidOfflineMode"
        default:
            message = "unknow status \(status)"
        }
        if status == noErr {
            RecordService.logger.info("call audio func \(name) result \(message), function \(function) line \(line)")
        } else {
            RecordService.logger.error("call audio func \(name) result \(message), function \(function) line \(line)")
        }
        return status
    }
}

// swiftlint:enable line_length function_body_length
