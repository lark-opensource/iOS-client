//
//  OpusUtil.swift
//  Lark
//
//  Created by liuwanlin on 2018/8/29.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import OCOpusCodec

public protocol OpusStreamUtil {
    func encodePcmData(_ data: Data, isEnd: Bool) -> Data?
}

extension OpusStreamCodec: OpusStreamUtil {
    public func encodePcmData(_ data: Data, isEnd: Bool) -> Data? {
        self.encode_pcm_data(data, isEnd: isEnd)
    }
}

/// opus 工具类
public final class OpusUtil {
    ///  判断 data 是否是 wav 文件
    public static func isWavFormat(_ data: Data) -> Bool {
        OpusCodec.isWavFormat(data)
    }

    /// encode pcm 格式 to opus 格式
    public static func encode_wav_data(_ data: Data) -> Data? {
        OpusCodec.encode_wav_data(data)
    }

    ///  decode opus 格式 to pcm 格式
    public static func decode_opus_data(_ data: Data) -> Data? {
        OpusCodec.decode_opus_data(data)
    }

    /// 返回流式转化 pcm 格式文件的工具类
    public static func streamCodec(
        channelCount: Int32,
        sampleRate: Int32,
        bitPerSample: Int32,
        frameCountPerOggPage: Int32 = 50,
        frameDuration: Float = 0.02
    ) -> OpusStreamUtil? {
        let config = OpusConfig()

        config.channelCount = channelCount
        config.sampleRate = sampleRate
        config.bitPerSample = bitPerSample
        config.frameCountPerOggPage = frameCountPerOggPage
        config.frameDuration = frameDuration

        return OpusStreamCodec(config: config)
    }
}
