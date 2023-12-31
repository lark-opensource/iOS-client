//
//  AudioRecorder.swift
//  SpaceKit
//
//  Created by maxiao on 2019/4/16.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation
import AVFoundation
import LarkAudioKit
import SKFoundation
import LarkMedia

struct AudioRecordConfig {
    let sampleRate: Float64         // 采样率
    let channel: UInt32             // 频道
    let bitsPerChannel: UInt32      // 采样位数
    let timeLimit: TimeInterval     // 最短长按时间

    init(sampleRate: Float64 = 16_000,
         channel: UInt32 = 1,
         bitsPerChannel: UInt32 = 16,
         timeLimit: TimeInterval = 1) {
        self.sampleRate = sampleRate
        self.channel = channel
        self.bitsPerChannel = bitsPerChannel
        self.timeLimit = timeLimit
    }
}

protocol AudioRecorderDelegate: AnyObject {
    func audioRecorder(_ audioRecorder: AudioRecorder,
                       didChanged state: AudioRecorder.AudioRecordState)

    func audioRecorder(_ audioRecorder: AudioRecorder,
                       didReceived data: Data)

    func audioRecorder(_ audioRecorder: AudioRecorder,
                       didReceived powerData: Float32)
}

/////////////////////////////////////////////////////////////////////////////
class AudioRecorder: NSObject {

    enum AudioRecordState {
        case tooShort
        case prepare
        case start
        case cancel
        case failed(Error)
        case success(Data, Data, TimeInterval) // wavData、pcmData、timeinterval
    }

    static let recordAudioSessionScenario = AudioSessionScenario("ccm.audio.commentRecord", category: .playAndRecord, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP])
    static let audioQueue = DispatchQueue(label: "CommentRecordAudioSessionScenarioQueue", qos: .userInteractive)
    weak var delegate: AudioRecorderDelegate?
    private var recorder: RecordService?
    private var pcmData: Data?  // 支持pcm完整段上传和流式上传，完整上传的方式需要在pcm前段拼接wavHeader头

    var isRecording: Bool { return recorder?.isRecording ?? false }
    var currentTime: TimeInterval { return recorder?.currentTime ?? 0 }

    private var startTime: TimeInterval = 0
    private var endTime: TimeInterval = 0
    var hasFinished: Bool = true
    var hasCanceled: Bool = false
    private var isPreparing: Bool = false

    let defaultRecordConfig = AudioRecordConfig()

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAudioSessionInterrupt),
                                               name: AVAudioSession.interruptionNotification,
                                               object: AVAudioSession.sharedInstance())
    }

    /// 开始录音
    func startRecord() {
        hasCanceled = false
        hasFinished = false
        if isPreparing { return }

        startTime = CACurrentMediaTime()

        if let recorder = recorder { recorder.stopRecord() }
        recorder = RecordService(sampleRate: defaultRecordConfig.sampleRate,
                                 channel: defaultRecordConfig.channel,
                                 bitsPerChannel: defaultRecordConfig.bitsPerChannel)
        recorder?.dataCallbackInterval = 0.05
        recorder?.useAveragePower = false
        prepare()
    }

    /// 结束录制
    func stopRecord() {
        guard let recorder = recorder else {
            hasFinished = false
            hasCanceled = true
            return
        }

        endTime = CACurrentMediaTime()

        if (endTime - startTime) < defaultRecordConfig.timeLimit ||
            recorder.currentTime < defaultRecordConfig.timeLimit {
            hasFinished = false
            hasCanceled = true
        } else {
            hasFinished = true
            hasCanceled = false
        }
        stopRecordService()
    }

    /// 取消录制
    func cancelRecord() {
        hasFinished = false
        hasCanceled = true
        stopRecord()
        delegate?.audioRecorder(self, didChanged: .cancel)
    }

    func prepare() {
        delegate?.audioRecorder(self, didChanged: .prepare)
        isPreparing = true

        AudioRecorder.audioQueue.async { [weak self] in
            guard let `self` = self else { return }
            LarkMediaManager.shared.getMediaResource(for: .ccmRecord)?.audioSession.enter(AudioRecorder.recordAudioSessionScenario)
            self.setIdleTimer(disabled: true)

            DispatchQueue.main.async {
                self.isPreparing = false
                guard let recorder = self.recorder else { return }
                let success = recorder.startRecord(encoder: self)
                if !success || self.hasFinished || self.hasCanceled {
                    self.stopRecordService()
                    return
                }
                self.delegate?.audioRecorder(self, didChanged: .start)
            }
        }
    }

    private func stopRecordService() {
        guard let recorder = recorder, recorder.isRecording else { return }
        recorder.stopRecord()
        self.recorder = nil
        AudioRecorder.audioQueue.async {
            LarkMediaManager.shared.getMediaResource(for: .ccmRecord)?.audioSession.leave(AudioRecorder.recordAudioSessionScenario)
            self.setIdleTimer(disabled: false)
        }
    }

    private func setIdleTimer(disabled: Bool) {
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = disabled
        }
    }

    @objc
    private func handleAudioSessionInterrupt(_ noti: Notification) {
        if let userinfo = noti.userInfo,
            let typeValue = userinfo[AVAudioSessionInterruptionTypeKey] as? NSValue {
            var intValue: UInt = 0
            typeValue.getValue(&intValue)
            if intValue == AVAudioSession.InterruptionType.began.rawValue {
                if self.isRecording {
                    self.stopRecord()
                }
            }
        }
    }
}

extension AudioRecorder: RecordServiceDelegate {
    func recordServiceStart() {
        pcmData = Data()
    }

    func recordServiceStop() {
        if self.hasFinished {
            if let data = pcmData {
                let time = Double(data.count) * Double(Data.Element.bitWidth) / Double(defaultRecordConfig.sampleRate) / Double(defaultRecordConfig.bitsPerChannel)
                let wavHeader = WavHeader(dataSize: Int32(data.count),
                                          numChannels: Int16(defaultRecordConfig.channel),
                                          sampleRate: Int32(defaultRecordConfig.sampleRate),
                                          bitsPerSample: Int16(defaultRecordConfig.bitsPerChannel))
                var wavData = Data()
                wavData.append(wavHeader.toData())
                wavData.append(data)
                delegate?.audioRecorder(self, didChanged: .success(wavData, data, time))
            }
        }
        pcmData?.removeAll()
        self.startTime = 0
        self.endTime = 0
    }

    func onMicrophoneData(_ data: Data) {
        pcmData?.append(data)
        delegate?.audioRecorder(self, didReceived: data)
    }

    func onPowerData(power: Float32) {
        delegate?.audioRecorder(self, didReceived: power)
    }
}
