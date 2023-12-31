//
//  RtcAudio.swift
//  ByteViewRtcBridge
//
//  Created by kiri on 2023/5/27.
//

import Foundation
import ByteViewCommon

public final class RtcAudio {
    private let logger: Logger
    private let rtc: MeetingRtcEngine

    /// 当前麦克风（音频输入）是否关闭
    @RwAtomic
    public private(set) var isInputMuted: Bool?

    /// 当前音频输出是否关闭
    @RwAtomic
    public private(set) var isOutputMuted: Bool?

    public init(engine: MeetingRtcEngine) {
        self.rtc = engine
        self.logger = Logger.audio.withContext(engine.sessionId).withTag("[RtcAudio(\(engine.sessionId))]")
    }

    public convenience init(engine: InMeetRtcEngine) {
        self.init(engine: engine.rtc)
    }

    public func muteInput(_ isMuted: Bool) {
        // 无脑刷muteLocalAudioStream
        // pstn下，需要rtcKit.muteLocalAudioStream来同步sip的mute状态
        self.isInputMuted = isMuted
        self.rtc.execute({ rtcKit in
            self.logger.info("muteLocalAudioStream \(isMuted)")
            /**muteLocalAudioStream、disableNS、硬件静音setInputMuted建议保持当前调用时序，
             **防止出现降噪模块启动慢产生的啸叫问题
             **https://bytedance.feishu.cn/docs/doccnlfuGYNgAVRmFL6PKH6suYd
             **收益：纯音频模式下，profile CPU消耗20s采样情况下由CPU使用时长由3.39s -> 2.85s； 线下测试iPhone 11 pro CPU绝对值能下降0.5%左右&&CPU突刺减少
             **/
            rtcKit.muteLocalAudioStream(isMuted)
            rtcKit.setInputMuted(isMuted)
        })
    }

    public func muteOutput(_ isMuted: Bool, completion: (() -> Void)? = nil) {
        self.isOutputMuted = isMuted
        self.rtc.execute({ rtcKit in
            guard let shouldMuteOutput = self.isOutputMuted else { return }
            self.logger.info("muteAudioPlayback \(shouldMuteOutput)")
            rtcKit.muteAudioPlayback(shouldMuteOutput)
            completion?()
        })
    }

    /// Params:
    /// - loobBack: true 仅本地播放, false 本地远端都播放
    /// - playCount: 1 仅播一遍 -1 循环播放
    /// - return: 是否播放成功
    public func startAudioMixing(soundId: Int32, filePath: String, loopback: Bool, playCount: Int, completion: ((Bool) -> Void)?) {
        let pathDesc: String
        if let url = URL(string: filePath) {
            pathDesc = "pathExtension: \(url.pathExtension)"
        } else {
            pathDesc = "filePathEmpty: \(filePath.isEmpty)"
        }
        rtc.ensureRtc()
        rtc.execute { rtcKit in
            self.logger.info("startAudioMixing, sountId: \(soundId), \(pathDesc), loopback: \(loopback), playCount: \(playCount)")
            let result = rtcKit.startAudioMixing(soundId, filePath: filePath, loopback: loopback, playCount: playCount)
            if result != 0 {
                self.logger.info("startAudioMixing fail, result = \(result)")
                completion?(false)
            } else {
                self.logger.info("startAudioMixing success")
                completion?(true)
            }
        }
    }

    public func stopAudioMixing(soundId: Int32, completion: (() -> Void)?) {
        rtc.execute { rtcKit in
            self.logger.info("stopAudioMixing, sountId: \(soundId)")
            rtcKit.stopAudioMixing(soundId)
            completion?()
        }
    }

    public func setAudioUnitMuted(_ isMuted: Bool) {
        self.rtc.execute({ rtcKit in
            self.logger.info("setAudioUnitMuted \(isMuted)")
            rtcKit.setInputMuted(isMuted)
        })
    }

    public func setClientRole(_ role: RtcClientRole) {
        self.rtc.execute { rtcKit in
            self.logger.info("setClientRole \(role)")
            rtcKit.setClientRole(role)
        }
    }

    /// 获取rtc真实的mute状态
    /// - parameter completion: isMuteLocalAudio
    public func fetchLocalAudioMuted(completion: @escaping (Bool) -> Void) {
        self.rtc.execute({ rtcKit in
            completion(rtcKit.isMuteLocalAudio())
        })
    }

    public func startAudioCapture(scene: RtcAudioScene, completion: @escaping (Result<Void, Error>) -> Void) {
        rtc.execute { rtcKit in
            self.logger.info("startAudioCapture")
            do {
                try rtcKit.startAudioCapture(scene: scene)
                completion(.success(Void()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    public func stopAudioCapture() {
        rtc.execute { rtcKit in
            self.logger.info("stopAudioCapture")
            rtcKit.stopAudioCapture()
        }
    }
}

extension Logger {
    static let audio = getLogger("Audio")
}
