//
//  UnitRecordService.swift
//  LarkAudioKit
//
//  Created by 李晨 on 2021/6/22.
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
public final class UnitRecordService: RecordServiceProtocol {

    static let logger = Logger.log(UnitRecordService.self, category: "Module.Audio")

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
        Self.logger.info("record service init, uuid \(self.uuid.uuidString) sampleRate \(sampleRate) channel \(channel) bitsPerChannel \(bitsPerChannel)")
    }

    deinit {
        Self.logger.info("record service deinit, uuid \(self.uuid.uuidString)")
    }

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

    fileprivate(set) var unit: AudioUnit?
    fileprivate(set) var format = AudioStreamBasicDescription()

    /// 录音数据 delegate
    public weak var delegate: RecordServiceDelegate?

    /// 开始录音
    ///
    /// Token: 需要申请 audioOutputUnitStart
    public func startRecord(token: Token, encoder: RecordServiceDelegate) -> Bool {
        var result: OSStatus = 0
        return startRecord(token: token, encoder: encoder, result: &result)
    }

    /// 开始录音, 可以获取 result
    ///
    /// Token: 需要申请 audioOutputUnitStart
    public func startRecord(token: Token, encoder: RecordServiceDelegate, result: inout OSStatus) -> Bool {
        do {
            try SensitivityManager.shared.checkToken(token, context: Context([AtomicInfo.AudioRecord.audioOutputUnitStart.rawValue]))
        } catch {
            Self.logger.error("record service start failed: \(error)")
            return false
        }
        Self.logger.info("record service start record start , uuid \(self.uuid.uuidString), \(Date().timeIntervalSince1970)")
        lock.lock()
        defer {
            lock.unlock()
        }
        guard !isRecording else {
            Self.logger.warn("record service is recording, uuid \(self.uuid.uuidString)")
            return false
        }
        self.delegate = encoder
        self.tracker.start()
        self.delegate?.recordServiceStart()
        self.prepareToRecord()
        Self.logger.info("record service start record start , uuid \(self.uuid.uuidString), \(Date().timeIntervalSince1970)")
        self.isRecording = true
        guard let unit = self.unit else {
            Self.logger.error("unit is not init, uuid \(self.uuid.uuidString)")
            self.tracker.stop(result: -1)
            return false
        }
        result = call("AudioOutputUnitStart", AudioOutputUnitStart(unit))
        /// 尝试恢复
        if result != noErr {
            let session = AVAudioSession.sharedInstance()
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: [])
                try AVAudioSession.sharedInstance().setActive(true)
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [])
            } catch {
                UnitRecordService.logger.error("reset aduiosession active error \(error)")
            }
            result = call("AudioOutputUnitStart", AudioOutputUnitStart(unit))
            if result != noErr {
                /// 尝试沉睡 0.1 s
                usleep(100000)
                UnitRecordService.logger.error("audio record sleep 0.1s")
                Self.logger.info("record service record retry, mode \(session.mode.rawValue), category \(session.category.rawValue), options \(session.categoryOptions.rawValue), isInputAvailable \(session.isInputAvailable), isOtherAudioPlaying \(session.isOtherAudioPlaying)")
                result = call("AudioOutputUnitStart", AudioOutputUnitStart(unit))
            }
        }
        self.startTime = Date().timeIntervalSince1970
        self.recordLength = 0
        Self.logger.info("record service start record end, uuid \(self.uuid.uuidString), \(Date().timeIntervalSince1970)")
        if result != noErr {
            Self.logger.error("audio start failed result \(result), uuid \(self.uuid.uuidString)")
            self.tracker.stop(result: result)
            return false
        }
        return true
    }

    /// 结束录音
    public func stopRecord() {
        Self.logger.info("record service stop record start, uuid \(self.uuid.uuidString)")
        lock.lock()
        defer {
            lock.unlock()
        }
        guard isRecording else {
            Self.logger.warn("record service is not recoring, uuid \(self.uuid.uuidString)")
            return
        }
        guard let unit = unit else {
            Self.logger.error("unit is not init, uuid \(self.uuid.uuidString)")
            return
        }
        isRecording = false
        call("AudioOutputUnitStop", AudioOutputUnitStop(unit))
        call("AudioComponentInstanceDispose", AudioComponentInstanceDispose(unit))
        self.delegate?.recordServiceStop()
        self.delegate = nil
        self.recordLength = Date().timeIntervalSince1970 - startTime
        self.startTime = 0
        self.tracker.stop()
    }

    /// 判断是否正在录音
    public fileprivate(set) var isRecording: Bool = false
    private let callback: AURenderCallback = {
        (userData, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData) -> OSStatus in
        let audioRecorder = Unmanaged<UnitRecordService>.fromOpaque(userData).takeUnretainedValue()
        guard let unit = audioRecorder.unit else {
            return noErr
        }

        autoreleasepool {
            var bufferList = AudioBufferList()
            bufferList.mNumberBuffers = 1
            AudioUnitRender(
                unit, ioActionFlags, inTimeStamp, 1, inNumberFrames, &bufferList)
            guard let mData = bufferList.mBuffers.mData else {
                return
            }
            let pcm: Data = Data(bytes: mData, count: Int(bufferList.mBuffers.mDataByteSize))
            audioRecorder.delegate?.onMicrophoneData(pcm)
            audioRecorder.tracker.receiveAudio(packetNumber: 1, count: pcm.count)
            audioRecorder.parseBufferPower(data: pcm)
        }
        return noErr
    }

    private func prepareToRecord() {
        if unit != nil {
            return
        }

        var inputDesc = AudioComponentDescription()
        inputDesc.componentType = kAudioUnitType_Output
        inputDesc.componentSubType = kAudioUnitSubType_RemoteIO
        inputDesc.componentManufacturer = kAudioUnitManufacturer_Apple
        inputDesc.componentFlags = 0
        inputDesc.componentFlagsMask = 0

        guard let inputComponent = AudioComponentFindNext(nil, &inputDesc) else {
            return
        }
        call(
            "AudioComponentInstanceNew",
            AudioComponentInstanceNew(inputComponent, &self.unit)
        )
        guard let unit = unit else {
            assertionFailure()
            Self.logger.error("unit is not create, uuid \(self.uuid.uuidString)")
            return
        }
        let formatSize = UInt32(MemoryLayout<AudioStreamBasicDescription>.stride)

        call(
            "AudioUnitSetProperty",
            AudioUnitSetProperty(
                unit,
                kAudioUnitProperty_StreamFormat,
                kAudioUnitScope_Output,
                1,
                &format,
                formatSize
            )
        )

        //麦克风输入设置为1（yes）
        var inputEnable: UInt32 = 1
        let inputEnableSize = UInt32(MemoryLayout<UInt32>.stride)
        call(
            "AudioUnitSetProperty",
            AudioUnitSetProperty(
                unit,
                kAudioOutputUnitProperty_EnableIO,
                kAudioUnitScope_Input,
                1,
                &inputEnable,
                inputEnableSize
            )
        )

        // 设置回调
        var inputCallBackStruce = AURenderCallbackStruct()
        inputCallBackStruce.inputProc = self.callback
        let pointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        inputCallBackStruce.inputProcRefCon = pointer
        let callBackStruceSize = UInt32(MemoryLayout<AURenderCallbackStruct>.stride)
        call(
            "AudioUnitSetProperty",
            AudioUnitSetProperty(
                unit,
                kAudioOutputUnitProperty_SetInputCallback,
                kAudioUnitScope_Output,
                1,
                &inputCallBackStruce,
                callBackStruceSize
            )
        )
    }

    /// 解析音频数据
    private func parseBufferPower(data: Data) {
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
            Self.logger.error("parseBufferPower error sumVolume \(sumVolume) avgVolume \(avgVolume) data \(data.count) volume \(volume)")
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
        default:
            message = "error status \(status)"
        }
        if status == noErr {
            Self.logger.info("call audio func \(name) result \(message), function \(function) line \(line)")
        } else {
            Self.logger.error("call audio func \(name) result \(message), function \(function) line \(line)")
        }
        return status
    }
}

// swiftlint:enable line_length function_body_length
